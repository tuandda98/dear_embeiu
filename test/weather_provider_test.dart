import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/weather.dart';
import 'package:dear_embeiu/providers/weather_provider.dart';
import 'package:dear_embeiu/services/weather_service.dart';
import 'package:dear_embeiu/utils/weather_logic.dart';

import 'weather_fakes.dart';

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
  final armed = <String>[];
  var cancels = 0;

  setUp(() {
    armed.clear();
    cancels = 0;
    svc = FakeWeatherService();
    now = t0;
    p = WeatherProvider(
      service: svc,
      clock: () => now,
      scheduleNotice: (plan, title, body, payload) async =>
          armed.add('$title|$body'),
      cancelNotice: () async => cancels++,
    );
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
    expect(svc.prefs.containsKey(WeatherService.keyNoticeLog), isTrue);
    expect(svc.prefs[WeatherService.keyNoticeLog], isNull);
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
    final q = WeatherProvider(
      service: slow,
      clock: () => now,
      scheduleNotice: (_, _, _, _) async {},
      cancelNotice: () async {},
    );
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

  // ── Morning notice (D13) ────────────────────────────────────────────────

  CityForecast rainAtFire({String symbol = 'rain'}) {
    final fire = weatherMorningFireAt(now.toLocal()).toUtc();
    return CityForecast(
      fetchedAt: now,
      checkedAt: now,
      hours: [
        for (var i = 0; i < 36; i++)
          WeatherHour(
            t: DateTime.utc(2026, 10, 20, 1 + i),
            temp: 27,
            symbol:
                DateTime.utc(2026, 10, 20, 1 + i) ==
                    DateTime.utc(fire.year, fire.month, fire.day, fire.hour + 2)
                ? symbol
                : 'cloudy',
            rain: 0,
          ),
      ],
    );
  }

  test('rain ahead at the partner\'s place → one notice armed', () async {
    // 20:10 in Vietnam: tomorrow's 07:30 is ~11 h away (≤ 18 h, D13).
    now = DateTime.utc(2026, 10, 20, 13, 10);
    svc.server = {'vn-ha-noi': forecast(now), 'vn-tp-hcm': rainAtFire()};
    p.watchForCouple('c1', 'me', 'her');
    p.setPartnerName('Thảo');
    svc.choices.add({
      'me': choice('me', 'vn-ha-noi'),
      'her': choice('her', 'vn-tp-hcm'),
    });
    await settle();
    await settle();
    expect(armed, hasLength(1));
    expect(armed.single, contains('Thảo'));
    expect(svc.noticeLog.values, ['umbrella']);

    await p.setNoticeEnabled(false);
    expect(cancels, greaterThan(0));
    expect(armed, hasLength(1));
    expect(svc.noticeLog, isEmpty, reason: 'the coming morning is forgotten');
    expect(svc.prefs[WeatherService.keyNoticeEnabled], 'false');
  });

  test('waiting couple or no partner city → nothing armed', () async {
    svc.server = {'vn-ha-noi': rainAtFire()};
    p.watchForCouple('c1', 'me', '');
    svc.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    await settle();
    expect(armed, isEmpty);
  });

  test('hide the card; picking a city brings it back', () async {
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({});
    await settle();
    expect(p.cardVisible, isTrue);
    await p.hideCard();
    expect(p.cardVisible, isFalse);
    expect(svc.prefs[WeatherService.keyCardHidden], 'true');
    await p.setMyCity('vn-hue');
    expect(p.cardVisible, isTrue);
    expect(svc.prefs[WeatherService.keyCardHidden], isNull);
  });

  test(
    'cardVisible waits for the Hive prefs (no flash of a hidden card)',
    () async {
      svc.prefs[WeatherService.keyCardHidden] = 'true';
      final q = WeatherProvider(
        service: svc,
        clock: () => now,
        scheduleNotice: (_, _, _, _) async {},
        cancelNotice: () async {},
      )..watchForCouple('c1', 'me', 'her');
      expect(q.cardVisible, isFalse, reason: 'prefs not read yet');
      await settle();
      expect(q.cardVisible, isFalse, reason: 'hidden');
      q.dispose();
    },
  );

  test(
    'notice syncs run in order: a slow arm never lands after a cancel',
    () async {
      final events = <String>[];
      final q = WeatherProvider(
        service: svc,
        clock: () => now,
        scheduleNotice: (_, _, _, _) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          events.add('arm');
        },
        cancelNotice: () async => events.add('cancel'),
      );
      now = DateTime.utc(2026, 10, 20, 13, 10);
      svc.server = {'vn-ha-noi': forecast(now), 'vn-tp-hcm': rainAtFire()};
      q.watchForCouple('c1', 'me', 'her');
      svc.choices.add({
        'me': choice('me', 'vn-ha-noi'),
        'her': choice('her', 'vn-tp-hcm'),
      });
      await settle();
      await settle();
      await q.setNoticeEnabled(false);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(events.last, 'cancel');
      expect(events.indexOf('arm'), lessThan(events.lastIndexOf('cancel')));
      q.dispose();
    },
  );
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
