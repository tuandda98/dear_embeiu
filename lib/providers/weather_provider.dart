import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_l10n.dart';
import '../models/weather.dart';
import '../services/reminder_service.dart';
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
  WeatherProvider({
    WeatherService? service,
    DateTime Function()? clock,
    WeatherNoticeScheduler? scheduleNotice,
    Future<void> Function()? cancelNotice,
  }) : _service = service ?? WeatherService(),
       _clock = clock ?? DateTime.now,
       _scheduleNotice = scheduleNotice ?? _scheduleWithReminders,
       _cancelNotice =
           cancelNotice ?? ReminderService.instance.cancelWeatherMorning {
    unawaited(_loadPrefs());
  }

  final WeatherService _service;
  final DateTime Function() _clock;
  final WeatherNoticeScheduler _scheduleNotice;
  final Future<void> Function() _cancelNotice;

  static Future<void> _scheduleWithReminders(
    WeatherMorningPlan plan,
    String title,
    String body,
    String payload,
  ) => ReminderService.instance.scheduleWeatherMorning(
    fireAt: plan.fireAt,
    title: title,
    body: body,
    payload: payload,
  );

  static const Duration refreshEvery = Duration(minutes: 30);

  /// After a failed call, wait this long before asking again on its own
  /// (opening Home / resuming / a snapshot); "Thử lại" still forces it.
  static const Duration retryAfterError = Duration(minutes: 3);

  /// A city write that hasn't been confirmed by then (offline) counts as
  /// saved: Firestore queues it, and a later refusal comes back through the
  /// stream as the old value.
  static const Duration writeWait = Duration(seconds: 4);

  StreamSubscription<Map<String, WeatherChoice>>? _sub;
  String? _coupleId;
  String? _myUid;
  String _partnerUid = '';
  Map<String, WeatherChoice> _choices = const <String, WeatherChoice>{};
  Map<String, CityForecast> _forecasts = const <String, CityForecast>{};
  bool _choicesLoaded = false;
  bool _refreshing = false;
  bool _lastRefreshFailed = false;
  DateTime? _retryNotBefore;
  bool _pendingForce = false;

  // Per-device prefs (Hive `app_settings`).
  bool _prefsLoaded = false;
  bool _cardHidden = false;
  bool _noticeEnabled = true;
  Map<String, String> _noticeLog = const <String, String>{};
  String _partnerName = '';

  /// What the armed morning notice was built from (null = re-evaluate).
  String? _noticeSignature;

  /// Bumped on every couple / account change so a late answer of the old
  /// session never lands in the new one.
  int _session = 0;

  // ── Read side ─────────────────────────────────────────────────────────────

  /// The Home card shows: Firebase on, a couple watched, not hidden ("Ẩn").
  bool get cardVisible => isUsingFirebase && _myUid != null && !_cardHidden;

  bool get cardHidden => _cardHidden;

  /// The 07:30 notice switch (Cài đặt, default on — D13).
  bool get noticeEnabled => _noticeEnabled;

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
          : weatherConditionFor(
              f.hours,
              now,
              cityUtcOffset(city, now),
              offsetAt: (t) => cityUtcOffset(city, t),
            ),
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
      unawaited(_syncNotice());
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
    _retryNotBefore = null;
    _pendingForce = false;
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
            unawaited(_syncNotice());
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
    _retryNotBefore = null;
    _pendingForce = false;
    if (signedOut) {
      unawaited(_service.clearCache());
    }
    // Signed out / no couple / left: no notice about a partner any more.
    _noticeSignature = null;
    unawaited(_cancelNotice());
    notifyListeners();
  }

  Future<void> onResume() => refresh();

  /// Fetches the cities whose copy on this phone is ≥ 30 minutes old (all of
  /// them when [force]). One callable for both cities.
  Future<void> refresh({bool force = false}) async {
    if (_myUid == null) {
      return;
    }
    if (_refreshing) {
      // "Thử lại" during an automatic call: run again once it ends.
      _pendingForce = _pendingForce || force;
      return;
    }
    final now = _clock();
    if (!force && _retryNotBefore != null && now.isBefore(_retryNotBefore!)) {
      return;
    }
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
        _retryNotBefore = failed ? _clock().add(retryAfterError) : null;
        notifyListeners();
        unawaited(_syncNotice());
      }
    }
    if (session == _session && _pendingForce) {
      _pendingForce = false;
      unawaited(refresh(force: true));
      return;
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
      final write = _service.setCity(
        coupleId: coupleId,
        ownerUid: ownerUid,
        myUid: myUid,
        cityId: cityId,
      );
      // Offline the server never answers: don't hold the picker on it.
      await write.timeout(
        writeWait,
        onTimeout: () {
          unawaited(
            write.catchError((_) {}),
          ); // refused later → the stream reverts it
        },
      );
      if (_cardHidden) {
        // Picking a city (e.g. from Cài đặt) brings the card back.
        _cardHidden = false;
        unawaited(_service.savePref(WeatherService.keyCardHidden, null));
      }
      unawaited(_syncNotice());
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

  // ── Prefs + morning notice ────────────────────────────────────────────────

  /// "Ẩn" on the invite card (Cài đặt still has the way in).
  Future<void> hideCard() async {
    _cardHidden = true;
    notifyListeners();
    await _service.savePref(WeatherService.keyCardHidden, 'true');
  }

  Future<void> setNoticeEnabled(bool value) async {
    _noticeEnabled = value;
    notifyListeners();
    await _service.savePref(
      WeatherService.keyNoticeEnabled,
      value ? 'true' : 'false',
    );
    await _syncNotice();
  }

  /// The partner's display name for the notice body (HomeScreen re-arm).
  void setPartnerName(String name) {
    if (name == _partnerName) {
      return;
    }
    _partnerName = name;
    unawaited(_syncNotice());
  }

  Future<void> _loadPrefs() async {
    final prefs = await _service.loadPrefs();
    _cardHidden = prefs.cardHidden;
    _noticeEnabled = prefs.noticeEnabled;
    _noticeLog = prefs.log;
    _prefsLoaded = true;
    notifyListeners();
    await _syncNotice();
  }

  /// Re-plans the 07:30 notice (id 1160) from what is known now and arms or
  /// drops it. Cheap when nothing changed (signature).
  Future<void> _syncNotice() async {
    if (!_prefsLoaded || _myUid == null) {
      return;
    }
    final city = partnerCity;
    final nowLocal = _clock().toLocal();
    final plan = _noticeEnabled && isPaired && city != null
        ? weatherMorningPlan(
            nowLocal: nowLocal,
            forecast: _forecasts[city.id],
            cityOffsetAt: (t) => cityUtcOffset(city, t),
            log: _noticeLog,
          )
        : null;
    final l10n = AppL10n.strings;
    final name = _partnerName.isNotEmpty
        ? _partnerName
        : l10n.reactionPartnerFallback;
    final signature = plan == null
        ? 'none|${weatherDateKey(weatherMorningFireAt(nowLocal))}'
        : '${plan.dateKey}|${plan.cta.name}|${plan.min}|${plan.max}|'
              '${city!.id}|$name|${l10n.localeName}';
    if (signature == _noticeSignature) {
      return;
    }
    _noticeSignature = signature;
    final log = weatherMorningLogAfter(
      _noticeLog,
      nowLocal: nowLocal,
      plan: plan,
    );
    if (!mapEquals(log, _noticeLog)) {
      _noticeLog = log;
      unawaited(_service.saveNoticeLog(log));
    }
    if (plan == null) {
      await _cancelNotice();
      return;
    }
    final cityName = city!.name(l10n.localeName);
    final (title, body) = switch (plan.cta) {
      WeatherCta.umbrella => (
        l10n.weatherMorningRainTitle(cityName),
        l10n.weatherMorningRainBody(name),
      ),
      WeatherCta.water => (
        l10n.weatherMorningHotTitle(cityName, plan.max),
        l10n.weatherMorningHotBody(name),
      ),
      WeatherCta.warm => (
        l10n.weatherMorningColdTitle(cityName, plan.min),
        l10n.weatherMorningColdBody(name),
      ),
    };
    await _scheduleNotice(
      plan,
      title,
      body,
      jsonEncode(<String, Object>{
        'type': ReminderService.weatherMorningType,
        'cta': plan.cta.name,
        'city': city.id,
        'min': plan.min,
        'max': plan.max,
      }),
    );
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

/// Arms the 07:30 notice (tests pass a fake; the app uses [ReminderService]).
typedef WeatherNoticeScheduler =
    Future<void> Function(
      WeatherMorningPlan plan,
      String title,
      String body,
      String payload,
    );
