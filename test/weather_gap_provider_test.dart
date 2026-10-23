import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/models/weather.dart';
import 'package:dear_embeiu/providers/weather_provider.dart';
import 'package:dear_embeiu/services/push_notification_service.dart';
import 'package:dear_embeiu/services/reminder_service.dart';
import 'package:dear_embeiu/services/weather_service.dart';
import 'package:dear_embeiu/utils/weather_logic.dart';
import 'package:dear_embeiu/widgets/weather/weather_card.dart' show weatherPlaceFailed;
import 'package:flutter/material.dart';

import 'weather_fakes.dart';

/// Gap cases of project/features/weather/test-cases.md that live in
/// WeatherProvider: CH-17 CH-20 CH-22 FE-06 FE-07 FE-08 NT-13 NT-17 LV-03
/// LG-02.

// 08:10 Vietnam time on 20/10/2026.
final DateTime t0 = DateTime.utc(2026, 10, 20, 1, 10);

CityForecast forecast(DateTime fetchedAt, {String symbol = 'cloudy'}) =>
    CityForecast(
      fetchedAt: fetchedAt,
      checkedAt: fetchedAt,
      hours: [
        for (var i = 0; i < 20; i++)
          WeatherHour(
            t: DateTime.utc(2026, 10, 20, 1 + i),
            temp: 25,
            symbol: i == 6 ? symbol : 'cloudy',
            rain: 0,
          ),
      ],
    );

WeatherChoice choice(String uid, String city, [String? by]) =>
    WeatherChoice(uid: uid, cityId: city, setBy: by ?? uid);

Future<void> settle() => Future<void>.delayed(Duration.zero);

/// A write that never gets an answer (offline Firestore).
class _HangingWriteService extends FakeWeatherService {
  @override
  Future<void> setCity({
    required String coupleId,
    required String ownerUid,
    required String myUid,
    required String cityId,
  }) => Completer<void>().future;
}

/// A callable that answers only when the test lets it.
class _GateService extends FakeWeatherService {
  final Completer<void> gate = Completer<void>();

  @override
  Future<Map<String, CityForecast>> fetchForecasts(
    List<String> cityIds, {
    required String languageCode,
    DateTime? now,
  }) async {
    calls.add(List<String>.of(cityIds));
    await gate.future;
    return {for (final id in cityIds) id: forecast(now!)};
  }
}

void main() {
  late FakeWeatherService svc;
  late DateTime now;
  late WeatherProvider p;
  final armed = <String>[];
  var cancels = 0;

  WeatherProvider make(FakeWeatherService s) => WeatherProvider(
    service: s,
    clock: () => now,
    scheduleNotice: (plan, title, body, payload) async =>
        armed.add('$title|$body'),
    cancelNotice: () async => cancels++,
  );

  setUp(() {
    armed.clear();
    cancels = 0;
    now = t0;
    svc = FakeWeatherService();
    p = make(svc);
  });

  tearDown(() {
    p.dispose();
    AppL10n.setLocale(const Locale('en'));
  });

  // ── CH-17 ────────────────────────────────────────────────────────────────

  testWidgets('CH-17: offline write — returns true after 4 s, not before', (
    tester,
  ) async {
    p.dispose();
    p = make(_HangingWriteService());
    p.watchForCouple('c1', 'me', 'her');
    var done = false;
    late bool result;
    unawaited(
      p.setMyCity('vn-hue').then((v) {
        result = v;
        done = true;
      }),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(done, isFalse, reason: 'the picker is held up to 4 s');
    expect(p.myChoice!.cityId, 'vn-hue', reason: 'shown at once (optimistic)');
    await tester.pump(const Duration(seconds: 2));
    expect(done, isTrue);
    expect(result, isTrue, reason: 'queued by Firestore = saved');
    expect(p.myChoice!.cityId, 'vn-hue');
  });

  test('CH-17: the 4 s is the documented constant', () {
    expect(WeatherProvider.writeWait, const Duration(seconds: 4));
  });

  // ── CH-20 ────────────────────────────────────────────────────────────────

  test('CH-20: my hidden flag survives my partner picking for me', () async {
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({});
    await settle();
    await p.hideCard();
    expect(p.cardHidden, isTrue);

    svc.choices.add({'me': choice('me', 'vn-hue', 'her')}); // picked by her
    await settle();
    await settle();
    expect(p.myChoice!.setBySelf, isFalse);
    expect(p.cardHidden, isTrue);
    expect(p.cardVisible, isFalse);
    expect(svc.prefs[WeatherService.keyCardHidden], 'true');
  });

  // ── CH-22 ────────────────────────────────────────────────────────────────

  test('CH-22: a refused write returns false (the picker then logs nothing)', () async {
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({});
    await settle();
    svc.refuseWrites = true;
    expect(await p.setMyCity('vn-hue'), isFalse);
    expect(await p.setPartnerCity('vn-hue'), isFalse);
    expect(svc.writes, isEmpty);
  });

  // ── FE-06 ────────────────────────────────────────────────────────────────

  test('FE-06: a callable that fails (timeout included) ends in the error state', () async {
    final failing = _ThrowingService(TimeoutException('15 s'));
    p.dispose();
    p = make(failing);
    p.watchForCouple('c1', 'me', '');
    failing.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    await settle();
    expect(p.isRefreshing, isFalse);
    expect(p.lastRefreshFailed, isTrue);
    expect(weatherPlaceFailed(p.myPlace!), isTrue);
    // No hammering: next automatic call waits retryAfterError (3 min).
    now = t0.add(const Duration(minutes: 1));
    await p.refresh();
    expect(failing.calls.length, 1);
    now = t0.add(WeatherProvider.retryAfterError + const Duration(seconds: 1));
    await p.refresh();
    expect(failing.calls.length, 2);
  });

  // ── FE-07 ────────────────────────────────────────────────────────────────

  test('FE-07: an answer that arrives after clear() is dropped', () async {
    final slow = _GateService();
    p.dispose();
    p = make(slow);
    p.watchForCouple('c1', 'me', '');
    slow.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    await settle();
    expect(p.isRefreshing, isTrue);

    p.clear(signedOut: true);
    slow.gate.complete();
    await settle();
    await settle();
    expect(p.forecastFor('vn-ha-noi'), isNull);
    expect(p.isRefreshing, isFalse);
    expect(p.lastRefreshFailed, isFalse);
    expect(slow.hive, isEmpty, reason: 'nothing of the old session is cached');
  });

  test('FE-07: an answer for couple 1 never lands in couple 2', () async {
    final slow = _GateService();
    p.dispose();
    p = make(slow);
    p.watchForCouple('c1', 'me', '');
    slow.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    await settle();
    expect(p.isRefreshing, isTrue);

    p.watchForCouple('c2', 'me', ''); // another couple, no city yet
    slow.gate.complete();
    await settle();
    await settle();
    expect(p.forecastFor('vn-ha-noi'), isNull);
    expect(p.myChoice, isNull);
    expect(slow.hive, isEmpty);
  });

  // ── FE-08 ────────────────────────────────────────────────────────────────

  test('FE-08: onResume refreshes only once the copy is 30 minutes old', () async {
    svc.server = {'vn-ha-noi': forecast(t0)};
    p.watchForCouple('c1', 'me', '');
    svc.choices.add({'me': choice('me', 'vn-ha-noi')});
    await settle();
    await settle();
    expect(svc.calls.length, 1);

    now = t0.add(const Duration(minutes: 29));
    await p.onResume();
    expect(svc.calls.length, 1, reason: 'back from a short break');

    now = t0.add(const Duration(minutes: 31));
    await p.onResume();
    expect(svc.calls.length, 2, reason: 'app was in the background > 30 min');
  });

  // ── NT-17 / LV-03 ────────────────────────────────────────────────────────

  CityForecast rainAtFire() {
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
                ? 'rain'
                : 'cloudy',
            rain: 0,
          ),
      ],
    );
  }

  Future<void> armedPair() async {
    now = DateTime.utc(2026, 10, 20, 13, 10); // 20:10 in Vietnam
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
  }

  test('NT-17: the partner leaves while the app runs → 1160 cancelled, lane gone', () async {
    await armedPair();
    final before = cancels;
    p.watchForCouple('c1', 'me', ''); // memberIds shrank to me
    await settle();
    await settle();
    expect(cancels, greaterThan(before));
    expect(armed, hasLength(1), reason: 'nothing new armed');
    expect(p.isPaired, isFalse);
  });

  test('NT-17: clear() (no couple any more) cancels 1160 without wiping the cache', () async {
    await armedPair();
    final before = cancels;
    p.clear(); // left / no couple, not a sign-out
    await settle();
    expect(cancels, greaterThan(before));
    expect(svc.cacheCleared, isFalse);
  });

  test('LV-03: after the partner left the card is the waiting one (my lane only)', () async {
    now = t0;
    svc.server = {
      'vn-ha-noi': forecast(t0),
      'vn-tp-hcm': forecast(t0, symbol: 'rain'),
    };
    p.watchForCouple('c1', 'me', 'her');
    svc.choices.add({
      'me': choice('me', 'vn-ha-noi'),
      'her': choice('her', 'vn-tp-hcm'),
    });
    await settle();
    await settle();
    expect(p.isPaired, isTrue);
    expect(p.partnerPlace, isNotNull);

    p.watchForCouple('c1', 'me', '');
    svc.choices.add({'me': choice('me', 'vn-ha-noi')}); // CF deleted her doc
    await settle();
    expect(p.isPaired, isFalse);
    expect(p.partnerChoice, isNull);
    expect(p.partnerCity, isNull);
    expect(p.partnerPlace, isNull);
    expect(p.sharedRow, WeatherSharedRow.none);
    expect(p.myPlace, isNotNull, reason: 'my own lane stays');
    expect(p.canPickForPartner, isFalse);
  });

  // ── LG-02 ────────────────────────────────────────────────────────────────

  test('LG-02: the 07:30 notice is armed again in the new language', () async {
    AppL10n.setLocale(const Locale('vi'));
    await armedPair();
    expect(armed.single, contains('Hôm nay'));

    AppL10n.setLocale(const Locale('en'));
    svc.choices.add({
      'me': choice('me', 'vn-ha-noi'),
      'her': choice('her', 'vn-tp-hcm'),
    });
    await settle();
    await settle();
    expect(armed, hasLength(2));
    expect(armed.last, contains('Rain in'));
    expect(armed.last, contains('Remind Thảo'));
  });

  // ── NT-13 ────────────────────────────────────────────────────────────────

  test('NT-13: a damaged payload is still routed to Home, others are not', () {
    NotificationTapRouter.pendingHomeTab.value = -1;
    ReminderService.pendingWeatherTap.value = null;
    expect(ReminderService.routeWeatherTap(null), isFalse);
    expect(ReminderService.routeWeatherTap('{"type":"daily_question"}'), isFalse);
    expect(ReminderService.pendingWeatherTap.value, isNull);

    const broken = '{"type":"weather_morning","city":"nowhere"';
    expect(ReminderService.routeWeatherTap(broken), isTrue);
    expect(NotificationTapRouter.pendingHomeTab.value, 0);
    expect(ReminderService.pendingWeatherTap.value, broken);
    ReminderService.pendingWeatherTap.value = null;
    NotificationTapRouter.pendingHomeTab.value = -1;
  });
}

class _ThrowingService extends FakeWeatherService {
  _ThrowingService(this.error);
  final Object error;

  @override
  Future<Map<String, CityForecast>> fetchForecasts(
    List<String> cityIds, {
    required String languageCode,
    DateTime? now,
  }) async {
    calls.add(List<String>.of(cityIds));
    throw error;
  }
}
