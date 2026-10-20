import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/weather.dart';
import 'package:dear_embeiu/providers/weather_provider.dart';
import 'package:dear_embeiu/services/weather_service.dart';
import 'package:dear_embeiu/utils/weather_logic.dart';

/// In-memory stand-in: choices come from [choices], forecasts from [server]
/// (null = the callable throws, offline), the Hive copy from [hive].
class FakeWeatherService extends WeatherService {
  final StreamController<Map<String, WeatherChoice>> choices =
      StreamController<Map<String, WeatherChoice>>.broadcast();
  Map<String, CityForecast>? server = <String, CityForecast>{};
  final Map<String, CityForecast> hive = <String, CityForecast>{};
  final List<List<String>> calls = <List<String>>[];
  final List<String> writes = <String>[];
  bool refuseWrites = false;
  bool cacheCleared = false;

  @override
  bool get isUsingFirebase => true;

  @override
  Stream<Map<String, WeatherChoice>> watchChoices(String coupleId) =>
      choices.stream;

  @override
  Future<void> setCity({
    required String coupleId,
    required String ownerUid,
    required String myUid,
    required String cityId,
  }) async {
    if (refuseWrites) {
      throw Exception('permission-denied');
    }
    writes.add('$ownerUid=$cityId by $myUid');
  }

  @override
  Future<Map<String, CityForecast>> fetchForecasts(
    List<String> cityIds, {
    required String languageCode,
    DateTime? now,
  }) async {
    calls.add(List<String>.of(cityIds));
    final s = server;
    if (s == null) {
      throw Exception('unavailable');
    }
    return {
      for (final id in cityIds)
        if (s[id] case final f?)
          id: CityForecast(
            fetchedAt: f.fetchedAt,
            checkedAt: now!,
            hours: f.hours,
          ),
    };
  }

  @override
  Future<Map<String, CityForecast>> loadCached(
    Iterable<String> cityIds,
  ) async => {for (final id in cityIds) id: ?hive[id]};

  @override
  Future<void> saveCached(Map<String, CityForecast> forecasts) async =>
      hive.addAll(forecasts);

  @override
  Future<void> clearCache() async => cacheCleared = true;
}

// 08:10 Vietnam time on 20/10/2026.
final DateTime t0 = DateTime.utc(2026, 10, 20, 1, 10);

CityForecast forecast(
  DateTime fetchedAt, {
  String symbol = 'cloudy',
  double rain = 0,
  double temp = 25,
}) => CityForecast(
  fetchedAt: fetchedAt,
  checkedAt: fetchedAt,
  hours: [
    for (var i = 0; i < 20; i++)
      WeatherHour(
        t: DateTime.utc(2026, 10, 20, 1 + i),
        temp: temp,
        symbol: i == 6 ? symbol : 'cloudy',
        rain: i == 6 ? rain : 0,
      ),
  ],
);

WeatherChoice choice(String uid, String city, [String? by]) =>
    WeatherChoice(uid: uid, cityId: city, setBy: by ?? uid);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeWeatherService svc;
  late DateTime now;
  late WeatherProvider p;

  setUp(() {
    svc = FakeWeatherService();
    now = t0;
    p = WeatherProvider(service: svc, clock: () => now);
  });

  tearDown(() => p.dispose());

  test(
    'both cities fetched in ONE call, then not again for 30 minutes',
    () async {
      svc.server = {
        'vn-ha-noi': forecast(t0),
        'vn-tp-hcm': forecast(t0, symbol: 'rain', rain: 2),
      };
      p.watchForCouple('c1', 'me', 'her');
      svc.choices.add({
        'me': choice('me', 'vn-ha-noi'),
        'her': choice('her', 'vn-tp-hcm'),
      });
      await settle();
      await settle();
      expect(svc.calls, [
        ['vn-ha-noi', 'vn-tp-hcm'],
      ]);
      expect(p.myPlace!.condition!.kind, WeatherConditionKind.sky);
      expect(p.partnerPlace!.condition!.cta, WeatherCta.umbrella);
      expect(p.sharedRow, WeatherSharedRow.cta);

      now = t0.add(const Duration(minutes: 10));
      await p.refresh();
      expect(
        svc.calls.length,
        1,
        reason: 'Home opened again within 30 minutes',
      );
      now = t0.add(const Duration(minutes: 31));
      await p.refresh();
      expect(svc.calls.length, 2);
      await p.refresh(force: true);
      expect(svc.calls.length, 3, reason: '"Thử lại" bypasses the throttle');
    },
  );

  test('offline start: the Hive copy shows, graded by its age (D16)', () async {
    svc.server = null; // offline
    svc.hive['vn-ha-noi'] = forecast(t0.subtract(const Duration(hours: 10)));
    p.watchForCouple('c1', 'me', '');
    svc.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    await settle();
    expect(p.myPlace!.freshness, WeatherFreshness.stale);
    expect(p.lastRefreshFailed, isTrue);
    expect(p.isPaired, isFalse);
    expect(p.sharedRow, WeatherSharedRow.none);
    now = t0.add(const Duration(hours: 20));
    expect(p.myPlace!.freshness, WeatherFreshness.none);
  });

  test('waiting couple: the other member doc is ignored', () async {
    p.watchForCouple('c1', 'me', '');
    svc.choices.add({
      'me': choice('me', 'vn-hue'),
      'ex': choice('ex', 'vn-tp-hcm'),
    });
    await settle();
    expect(p.partnerChoice, isNull);
    expect(p.canPickForPartner, isFalse);
    expect(svc.calls.single, ['vn-hue']);
  });

  test('pick for the partner only until they pick themselves (D6)', () async {
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({});
    await settle();
    expect(p.nothingPicked, isTrue);
    expect(p.canPickForPartner, isTrue);
    expect(await p.setPartnerCity('vn-tp-hcm'), isTrue);
    expect(svc.writes, ['her=vn-tp-hcm by me']);
    expect(p.partnerChoice!.setBySelf, isFalse);
    expect(p.canPickForPartner, isTrue, reason: 'still mine to change');

    svc.choices.add({'her': choice('her', 'vn-da-lat')});
    await settle();
    expect(p.canPickForPartner, isFalse);
    expect(await p.setPartnerCity('vn-hue'), isFalse);
    expect(svc.writes.length, 1);
  });

  test('a refused write rolls back; unknown ids are never written', () async {
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({'me': choice('me', 'vn-hue')});
    await settle();
    svc.refuseWrites = true;
    expect(await p.setMyCity('vn-da-lat'), isFalse);
    expect(p.myChoice!.cityId, 'vn-hue');
    expect(await p.setMyCity('vn-atlantis'), isFalse);
  });

  test('a city id this build does not know reads as "not picked"', () async {
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({'me': choice('me', 'vn-new-city')});
    await settle();
    expect(p.myChoice, isNotNull);
    expect(p.myCity, isNull);
    expect(svc.calls, isEmpty);
  });

  test('same city for both → one id in the call', () async {
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({
      'me': choice('me', 'vn-ha-noi'),
      'her': choice('her', 'vn-ha-noi'),
    });
    await settle();
    expect(svc.calls.single, ['vn-ha-noi']);
  });

  test('sign-out clears state and the Hive cache', () async {
    svc.server = {'vn-ha-noi': forecast(t0)};
    p.watchForCouple('c1', 'me', '');
    svc.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    expect(p.myPlace, isNotNull);
    p.clear(signedOut: true);
    expect(p.myChoice, isNull);
    expect(p.forecastFor('vn-ha-noi'), isNull);
    expect(svc.cacheCleared, isTrue);
  });

  test('only one of two cities answered → lastRefreshFailed', () async {
    svc.server = {'vn-ha-noi': forecast(t0)};
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({
      'me': choice('me', 'vn-ha-noi'),
      'her': choice('her', 'vn-tp-hcm'),
    });
    await settle();
    await settle();
    expect(p.lastRefreshFailed, isTrue);
    expect(p.myPlace!.usable, isTrue);
    expect(p.partnerPlace!.freshness, WeatherFreshness.none);
  });

  test('after an error: no new call for 3 minutes unless forced', () async {
    svc.server = null;
    p.watchForCouple('c1', 'me', '');
    svc.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    await settle();
    expect(svc.calls.length, 1);
    now = t0.add(const Duration(minutes: 1));
    await p.onResume();
    await p.refresh();
    expect(svc.calls.length, 1, reason: 'backing off');
    await p.refresh(force: true);
    expect(svc.calls.length, 2, reason: '"Thử lại" still asks');
    svc.server = {'vn-ha-noi': forecast(now)};
    now = now.add(const Duration(minutes: 4));
    await p.refresh();
    expect(svc.calls.length, 3);
    expect(p.lastRefreshFailed, isFalse);
  });

  test('"Thử lại" while a call is running runs once more afterwards', () async {
    final gate = Completer<void>();
    final slow = _SlowService(gate)..server = {'vn-ha-noi': forecast(t0)};
    final q = WeatherProvider(service: slow, clock: () => now);
    q.watchForCouple('c1', 'me', '');
    slow.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    await settle();
    expect(q.isRefreshing, isTrue);
    unawaited(q.refresh(force: true));
    gate.complete();
    await settle();
    await settle();
    await settle();
    expect(slow.calls.length, 2);
    q.dispose();
  });
}

class _SlowService extends FakeWeatherService {
  _SlowService(this.gate);

  final Completer<void> gate;

  @override
  Future<Map<String, CityForecast>> fetchForecasts(
    List<String> cityIds, {
    required String languageCode,
    DateTime? now,
  }) async {
    if (calls.isEmpty) {
      calls.add(List<String>.of(cityIds));
      await gate.future;
      return {};
    }
    return super.fetchForecasts(cityIds, languageCode: languageCode, now: now);
  }
}
