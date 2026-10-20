import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_l10n.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../utils/weather_logic.dart';

/// State of "Thời tiết hai nơi" (feature weather): both members' cities
/// (realtime, `weather/{uid}`) + the forecast of each city (callable, kept in
/// Hive). The card / sheets read [myPlace], [partnerPlace], [sharedRow] and
/// [compact]; every rule behind them is a pure function in
/// `utils/weather_logic.dart`.
///
/// Lifecycle like [SleepProvider]: `watchForCouple` wired in
/// `session_resolver` (also while waiting for a partner — then only my city),
/// `clear` on sign-out / no couple. Home calls [refresh] on entry and
/// [onResume]; a city is asked again only when this phone's copy is older
/// than 30 minutes (D7), unless [refresh] is forced (the "Thử lại" button).
class WeatherProvider extends ChangeNotifier {
  WeatherProvider({WeatherService? service, DateTime Function()? clock})
    : _service = service ?? WeatherService(),
      _clock = clock ?? DateTime.now;

  final WeatherService _service;
  final DateTime Function() _clock;

  static const Duration refreshEvery = Duration(minutes: 30);

  StreamSubscription<Map<String, WeatherChoice>>? _sub;
  String? _coupleId;
  String? _myUid;
  String _partnerUid = '';
  Map<String, WeatherChoice> _choices = const <String, WeatherChoice>{};
  Map<String, CityForecast> _forecasts = const <String, CityForecast>{};
  bool _choicesLoaded = false;
  bool _refreshing = false;
  bool _lastRefreshFailed = false;

  /// Bumped on every couple / account change so a late answer of the old
  /// session never lands in the new one.
  int _session = 0;

  // ── Read side ─────────────────────────────────────────────────────────────

  bool get isUsingFirebase => _service.isUsingFirebase;

  /// False until the first snapshot of the choices (show the skeleton, not
  /// the invite, meanwhile).
  bool get choicesLoaded => _choicesLoaded;

  /// The couple has two members (otherwise: my lane only, no nudge, D-§6.2).
  bool get isPaired => _partnerUid.isNotEmpty;

  WeatherChoice? get myChoice => _myUid == null ? null : _choices[_myUid];

  WeatherChoice? get partnerChoice =>
      _partnerUid.isEmpty ? null : _choices[_partnerUid];

  /// Null when not picked — or picked with an id this build doesn't know
  /// (a newer app added a city): the lane then asks again.
  WeatherCity? get myCity => _cityOf(myChoice);
  WeatherCity? get partnerCity => _cityOf(partnerChoice);

  /// D6: I may pick (or change) my partner's city until they pick it
  /// themselves.
  bool get canPickForPartner =>
      isPaired && (partnerChoice == null || !partnerChoice!.setBySelf);

  /// Neither of us has a usable city yet → the card's invite state.
  bool get nothingPicked =>
      myCity == null && (!isPaired || partnerCity == null);

  CityForecast? forecastFor(String cityId) => _forecasts[cityId];

  bool get isRefreshing => _refreshing;

  /// The last callable failed (offline / server) — with no fresh copy the
  /// card shows "Chưa tải được thời tiết · Thử lại".
  bool get lastRefreshFailed => _lastRefreshFailed;

  /// First load: a city is picked but nothing is cached yet (skeleton).
  bool get isLoadingFirst =>
      _refreshing && _wantedIds().any((id) => !_forecasts.containsKey(id));

  WeatherPlace? get myPlace => placeFor(myCity);
  WeatherPlace? get partnerPlace => placeFor(partnerCity);

  WeatherSharedRow get sharedRow =>
      weatherSharedRow(paired: isPaired, mine: myPlace, partner: partnerPlace);

  /// Home C §15: fold the card into one row.
  bool get compact => weatherCardCompact(
    paired: isPaired,
    mine: myPlace,
    partner: partnerPlace,
  );

  /// [city] graded against the clock: freshness by `fetchedAt`, condition on
  /// the city's own clock.
  WeatherPlace? placeFor(WeatherCity? city) {
    if (city == null) {
      return null;
    }
    final now = _clock();
    final f = _forecasts[city.id];
    return WeatherPlace(
      cityId: city.id,
      freshness: weatherFreshness(f?.fetchedAt, now),
      condition: f == null
          ? null
          : weatherConditionFor(f.hours, now, cityUtcOffset(city, now)),
    );
  }

  /// The city's UTC offset at [now] (DST-aware via the tz database; the
  /// phone's own offset if the zone can't be loaded).
  static Duration cityUtcOffset(WeatherCity city, DateTime now) {
    try {
      return _offset(city.tz, now);
    } catch (_) {
      try {
        tz_data.initializeTimeZones();
        return _offset(city.tz, now);
      } catch (_) {
        return now.toLocal().timeZoneOffset;
      }
    }
  }

  static Duration _offset(String zone, DateTime now) =>
      tz.TZDateTime.from(now, tz.getLocation(zone)).timeZoneOffset;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Starts (or re-arms) for this couple. [partnerUid] is '' while waiting
  /// for a partner. No-ops when unchanged; a partner joining mid-session only
  /// widens what we read.
  void watchForCouple(String coupleId, String myUid, String partnerUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }
    final sameStream = _coupleId == coupleId && _myUid == myUid && _sub != null;
    if (sameStream && _partnerUid == partnerUid) {
      return;
    }
    _partnerUid = partnerUid;
    if (sameStream) {
      notifyListeners();
      unawaited(refresh());
      return;
    }
    _session++;
    final session = _session;
    _coupleId = coupleId;
    _myUid = myUid;
    _choices = const <String, WeatherChoice>{};
    _forecasts = const <String, CityForecast>{};
    _choicesLoaded = false;
    _refreshing = false;
    _lastRefreshFailed = false;
    _sub?.cancel();
    _sub = _service
        .watchChoices(coupleId)
        .listen(
          (choices) async {
            if (session != _session) {
              return;
            }
            _choices = choices;
            _choicesLoaded = true;
            await _loadCached(session);
            if (session != _session) {
              return;
            }
            notifyListeners();
            unawaited(refresh());
          },
          onError: (_) {
            // Keep the last good choices; nothing global to surface.
            if (session == _session) {
              _choicesLoaded = true;
              notifyListeners();
            }
          },
        );
    notifyListeners();
  }

  /// Sign-out / no couple. [signedOut] also forgets the cached forecasts —
  /// the cities they name are coarse location of that account.
  void clear({bool signedOut = false}) {
    _session++;
    _sub?.cancel();
    _sub = null;
    _coupleId = null;
    _myUid = null;
    _partnerUid = '';
    _choices = const <String, WeatherChoice>{};
    _forecasts = const <String, CityForecast>{};
    _choicesLoaded = false;
    _refreshing = false;
    _lastRefreshFailed = false;
    if (signedOut) {
      unawaited(_service.clearCache());
    }
    notifyListeners();
  }

  Future<void> onResume() => refresh();

  /// Fetches the cities whose copy on this phone is ≥ 30 minutes old (all of
  /// them when [force]). One callable for both cities.
  Future<void> refresh({bool force = false}) async {
    if (_refreshing || _myUid == null) {
      return;
    }
    final now = _clock();
    final due = [
      for (final id in _wantedIds())
        if (force || _isDue(_forecasts[id], now)) id,
    ];
    if (due.isEmpty) {
      return;
    }
    final session = _session;
    _refreshing = true;
    notifyListeners();
    var failed = false;
    try {
      final got = await _service.fetchForecasts(
        due,
        languageCode: AppL10n.strings.localeName,
        now: now,
      );
      if (session != _session) {
        return;
      }
      if (got.isNotEmpty) {
        _forecasts = {..._forecasts, ...got};
        unawaited(_service.saveCached(got));
      }
      failed = got.length < due.length;
    } catch (_) {
      failed = true;
    } finally {
      if (session == _session) {
        _refreshing = false;
        _lastRefreshFailed = failed;
        notifyListeners();
      }
    }
    // A city picked while that call was in flight still needs its numbers.
    if (session == _session &&
        _wantedIds().any(
          (id) => !due.contains(id) && _isDue(_forecasts[id], _clock()),
        )) {
      unawaited(refresh());
    }
  }

  // ── Write side ────────────────────────────────────────────────────────────

  /// Saves my city. Shown at once; returns false when the write was refused.
  Future<bool> setMyCity(String cityId) => _setCity(_myUid, cityId);

  /// Picks my partner's city (D6). False when they have already picked their
  /// own — locally known, or the rules refused because they just did ("Thảo
  /// vừa tự chọn chỗ của mình rồi").
  Future<bool> setPartnerCity(String cityId) {
    if (!canPickForPartner) {
      return Future<bool>.value(false);
    }
    return _setCity(_partnerUid, cityId);
  }

  Future<bool> _setCity(String? ownerUid, String cityId) async {
    final coupleId = _coupleId;
    final myUid = _myUid;
    if (coupleId == null ||
        myUid == null ||
        ownerUid == null ||
        ownerUid.isEmpty ||
        weatherCityById(cityId) == null) {
      return false;
    }
    final previous = _choices[ownerUid];
    final optimistic = WeatherChoice(
      uid: ownerUid,
      cityId: cityId,
      setBy: myUid,
    );
    _choices = {..._choices, ownerUid: optimistic};
    await _loadCached(_session);
    notifyListeners();
    unawaited(refresh());
    try {
      await _service.setCity(
        coupleId: coupleId,
        ownerUid: ownerUid,
        myUid: myUid,
        cityId: cityId,
      );
      return true;
    } catch (_) {
      // Undo unless the stream already brought the server's copy back.
      if (_coupleId == coupleId && identical(_choices[ownerUid], optimistic)) {
        _choices = {
          for (final e in _choices.entries)
            if (e.key != ownerUid) e.key: e.value,
          ownerUid: ?previous,
        };
        notifyListeners();
      }
      return false;
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  WeatherCity? _cityOf(WeatherChoice? choice) =>
      choice == null ? null : weatherCityById(choice.cityId);

  /// Known city ids of both lanes, deduped (same city = one call).
  List<String> _wantedIds() => <String>{
    if (myCity case final c?) c.id,
    if (partnerCity case final c?) c.id,
  }.toList();

  bool _isDue(CityForecast? f, DateTime now) =>
      f == null || now.difference(f.checkedAt) >= refreshEvery;

  /// Hive copies for cities not in memory yet (offline start).
  Future<void> _loadCached(int session) async {
    final missing = [
      for (final id in _wantedIds())
        if (!_forecasts.containsKey(id)) id,
    ];
    if (missing.isEmpty) {
      return;
    }
    final cached = await _service.loadCached(missing);
    if (session == _session && cached.isNotEmpty) {
      _forecasts = {...cached, ..._forecasts};
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
