import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/models/couple.dart';
import 'package:dear_embeiu/models/weather.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/providers/weather_provider.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/services/sleep_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/utils/weather_logic.dart';
import 'package:dear_embeiu/widgets/person_label.dart';
import 'package:dear_embeiu/widgets/weather/weather_card.dart';
import 'package:dear_embeiu/widgets/weather/weather_sheets.dart';

import 'weather_fakes.dart';

/// Gap cases of project/features/weather/test-cases.md that need widgets:
/// CH-02 CH-04 FE-16 SR-09 SR-10 CARD-07 CARD-08 SH-01..03 SH-06 ST-03 ST-06
/// LG-01 A11-03.

final _epoch = DateTime(2026, 1, 1);
// 08:10 in Vietnam on 20/10/2026.
final DateTime t0 = DateTime.utc(2026, 10, 20, 1, 10);

class _Auth extends AuthProvider {
  _Auth() : super(authService: AuthService());

  @override
  AppUser? get currentUser => AppUser(
    id: 'me',
    email: 'me@test.dev',
    displayName: 'Tuấn',
    inviteCode: 'ABC123',
    status: 'in_couple',
    createdAt: _epoch,
    updatedAt: _epoch,
  );
}

Couple _couple({bool waiting = false}) => Couple(
  id: 'c1',
  person1Name: 'Thảo',
  person2Name: 'Tuấn',
  anniversaryDate: DateTime(2025, 1, 1),
  inviteCode: 'ABC123',
  memberIds: waiting ? const ['me'] : const ['other', 'me'],
  memberCount: waiting ? 1 : 2,
  createdByUserId: 'other',
  status: waiting ? 'waiting_partner' : 'active',
  createdAt: _epoch,
  updatedAt: _epoch,
);

/// 20 hours from 08:00 VN; hour 7 (15:00 VN) gets [symbol].
CityForecast fc({
  DateTime? fetched,
  String symbol = 'cloudy',
  double temp = 25,
}) => CityForecast(
  fetchedAt: fetched ?? t0,
  checkedAt: t0,
  hours: [
    for (var i = 0; i < 20; i++)
      WeatherHour(
        t: DateTime.utc(2026, 10, 20, 1 + i),
        temp: temp,
        symbol: i == 7 ? symbol : 'cloudy',
        rain: 0,
      ),
  ],
);

/// A forecast that starts at the current real hour (the detail sheet's
/// 3-hour marks read the real clock). [rainNow] makes the first hour rain.
CityForecast live({
  required DateTime fetched,
  bool rainNow = false,
  double temp = 25,
}) {
  final n = DateTime.now().toUtc();
  final start = DateTime.utc(n.year, n.month, n.day, n.hour);
  return CityForecast(
    fetchedAt: fetched,
    checkedAt: DateTime.now().toUtc(),
    hours: [
      for (var i = 0; i < 36; i++)
        WeatherHour(
          t: start.add(Duration(hours: i)),
          temp: temp,
          symbol: i == 0 && rainNow ? 'rain' : 'cloudy',
          rain: i == 0 && rainNow ? 2 : 0,
        ),
    ],
  );
}

WeatherChoice ch(String uid, String city) =>
    WeatherChoice(uid: uid, cityId: city, setBy: uid);

/// The first forecast call waits for [gate].
class _GateService extends FakeWeatherService {
  final Completer<void> gate = Completer<void>();

  @override
  Future<Map<String, CityForecast>> fetchForecasts(
    List<String> cityIds, {
    required String languageCode,
    DateTime? now,
  }) async {
    await gate.future;
    return super.fetchForecasts(
      cityIds,
      languageCode: languageCode,
      now: now,
    );
  }
}

Future<WeatherProvider> pump(
  WidgetTester tester,
  FakeWeatherService svc, {
  required Map<String, WeatherChoice> choices,
  bool waiting = false,
  Widget? child,
  String lang = 'vi',
  DateTime Function()? clock,
  bool reduceMotion = false,
}) async {
  final w = WeatherProvider(
    service: svc,
    clock: clock ?? () => t0,
    scheduleNotice: (_, _, _, _) async {},
    cancelNotice: () async {},
  )..watchForCouple('c1', 'me', waiting ? '' : 'other');
  final couple = _couple(waiting: waiting);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => _Auth()),
        ChangeNotifierProvider<SleepProvider>(
          create: (_) => SleepProvider(service: SleepService()),
        ),
        ChangeNotifierProvider<WeatherProvider>.value(value: w),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: app!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: child ?? WeatherCard(couple: couple),
          ),
        ),
      ),
    ),
  );
  svc.choices.add(choices);
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
  addTearDown(w.dispose);
  return w;
}

Widget _openers(Couple couple) => Builder(
  builder: (context) => Column(
    children: [
      TextButton(
        key: const Key('open-chain'),
        onPressed: () => showCityPickerSheet(
          context,
          forPartner: false,
          partnerName: 'Thảo',
          entry: 'card',
          chain: true,
        ),
        child: const Text('open-chain'),
      ),
      TextButton(
        key: const Key('open-detail'),
        onPressed: () => showWeatherDetailSheet(context, couple: couple),
        child: const Text('open-detail'),
      ),
      WeatherCard(couple: couple),
    ],
  ),
);

final _vietnamese = RegExp(
  '[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
  caseSensitive: false,
);

/// Every visible string (Text, RichText, labels of tooltips are not here).
List<String> _texts(WidgetTester tester) => [
  for (final r in tester.widgetList<RichText>(find.byType(RichText)))
    r.text.toPlainText(),
];

void main() {
  // ── CH-02 ────────────────────────────────────────────────────────────────

  testWidgets('CH-02: waiting couple, nothing picked → the solo invite', (
    tester,
  ) async {
    await pump(tester, FakeWeatherService(), choices: {}, waiting: true);
    expect(
      find.text('Chọn thành phố của bạn, sáng nào mở app cũng thấy trời hôm nay.'),
      findsOneWidget,
    );
    expect(find.textContaining('Thảo'), findsNothing);
    expect(find.text('Chọn thành phố'), findsOneWidget);
  });

  // ── CH-04 ────────────────────────────────────────────────────────────────

  testWidgets('CH-04: "Để sau" closes the sheet; the card then offers "Chọn giúp"', (
    tester,
  ) async {
    final svc = FakeWeatherService()
      ..server = {'vn-ha-noi': fc()}
      ..hive.clear();
    await pump(tester, svc, choices: {}, child: _openers(_couple()));
    await tester.tap(find.byKey(const Key('open-chain')));
    await tester.pumpAndSettle();
    expect(find.byType(CityPicker), findsOneWidget);

    await tester.tap(find.text('Hà Nội'));
    await tester.pump();
    expect(find.text('Còn Thảo đang ở đâu?'), findsOneWidget);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.byType(CityPicker), findsNothing);
    expect(svc.writes, ['me=vn-ha-noi by me'], reason: 'nothing for Thảo');

    svc.choices.add({'me': ch('me', 'vn-ha-noi')}); // the server echo
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expect(find.text('Thảo đang ở đâu?'), findsOneWidget);
    expect(find.text('Chọn giúp'), findsOneWidget);
  });

  // ── FE-16 / CARD-08 ──────────────────────────────────────────────────────

  testWidgets('FE-16: before the first answer → skeleton, then the numbers', (
    tester,
  ) async {
    final svc = _GateService()
      ..server = {'vn-ha-noi': fc(), 'vn-tp-hcm': fc(symbol: 'rain')};
    final w = await pump(
      tester,
      svc,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    expect(w.isLoadingFirst, isTrue);
    expect(find.byType(Shimmer), findsWidgets);
    expect(find.textContaining('Cập nhật'), findsNothing);
    expect(find.text('Chưa tải được thời tiết'), findsNothing);

    svc.gate.complete();
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expect(find.byType(Shimmer), findsNothing);
    expect(find.text('Nhắc Thảo mang ô'), findsOneWidget);
  });

  testWidgets('CARD-08: Reduce Motion — skeleton stands still', (tester) async {
    final svc = _GateService()..server = {'vn-ha-noi': fc()};
    await pump(
      tester,
      svc,
      choices: {'me': ch('me', 'vn-ha-noi')},
      reduceMotion: true,
    );
    final shimmers = tester.widgetList<Shimmer>(find.byType(Shimmer)).toList();
    expect(shimmers, isNotEmpty);
    expect(shimmers.every((s) => !s.enabled), isTrue);
    svc.gate.complete();
    await tester.pump();
  });

  testWidgets('CARD-08: Reduce Motion — the number switcher has 0 ms', (
    tester,
  ) async {
    final svc = FakeWeatherService()
      ..server = {'vn-ha-noi': fc(), 'vn-tp-hcm': fc(symbol: 'rain')};
    await pump(
      tester,
      svc,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
      reduceMotion: true,
    );
    final switchers = tester
        .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
        .toList();
    expect(switchers, isNotEmpty);
    expect(switchers.every((s) => s.duration == Duration.zero), isTrue);
  });

  testWidgets('CARD-08: Reduce Motion off — the switcher animates', (
    tester,
  ) async {
    final svc = FakeWeatherService()
      ..server = {'vn-ha-noi': fc(), 'vn-tp-hcm': fc(symbol: 'rain')};
    await pump(
      tester,
      svc,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    final switchers = tester
        .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
        .toList();
    expect(switchers.any((s) => s.duration > Duration.zero), isTrue);
  });

  // ── CARD-07 ──────────────────────────────────────────────────────────────

  testWidgets('CARD-07: past 0:00 the card reads the condition again', (
    tester,
  ) async {
    var clockNow = t0;
    final svc = FakeWeatherService()
      ..server = {
        'vn-ha-noi': fc(fetched: t0.add(const Duration(hours: 3))),
        'vn-tp-hcm': fc(
          symbol: 'rain',
          fetched: t0.add(const Duration(hours: 3)),
        ),
      };
    await pump(
      tester,
      svc,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
      clock: () => clockNow,
    );
    expect(find.text('TP.HCM · Chiều nay mưa'), findsOneWidget);

    // 16:10 in Vietnam: the 15:00 rain is behind us. Nothing tells the
    // provider; only the midnight timer rebuilds the card.
    clockNow = t0.add(const Duration(hours: 8));
    await tester.pump();
    expect(
      find.text('TP.HCM · Chiều nay mưa'),
      findsOneWidget,
      reason: 'no rebuild before the timer fires',
    );
    await tester.pump(const Duration(hours: 25));
    expect(find.text('TP.HCM · Chiều nay mưa'), findsNothing);
  });

  // ── SR-09 / SR-10 ────────────────────────────────────────────────────────

  testWidgets('SR-09: same city → one lane "Cả hai cùng ở Hà Nội"', (
    tester,
  ) async {
    final svc = FakeWeatherService()
      ..server = {'vn-ha-noi': fc(symbol: 'rain')};
    await pump(
      tester,
      svc,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-ha-noi')},
    );
    expect(find.text('Cả hai cùng ở Hà Nội'), findsOneWidget);
    expect(find.byType(PersonLabel), findsNothing, reason: 'one lane, 2 dots');
    expect(svc.calls, hasLength(1));
    expect(svc.calls.single, ['vn-ha-noi']);
  });

  testWidgets('SR-10: English card shows the short name "HCMC"', (tester) async {
    final svc = FakeWeatherService()
      ..server = {'vn-ha-noi': fc(), 'vn-tp-hcm': fc(symbol: 'rain')};
    await pump(
      tester,
      svc,
      lang: 'en',
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    expect(find.text('HCMC · Rain this afternoon'), findsOneWidget);
    expect(find.textContaining('Ho Chi Minh'), findsNothing);
  });

  // ── SH-01 / SH-02 / SH-03 / SH-06 ────────────────────────────────────────

  Future<FakeWeatherService> openDetail(
    WidgetTester tester, {
    required Map<String, CityForecast> server,
    required Map<String, WeatherChoice> choices,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final svc = FakeWeatherService()..server = server;
    await pump(
      tester,
      svc,
      choices: choices,
      clock: () => DateTime.now().toUtc(),
      child: _openers(_couple()),
    );
    await tester.tap(find.byKey(const Key('open-detail')));
    await tester.pumpAndSettle();
    return svc;
  }

  testWidgets('SH-01: me first, one shared scale, five 3-hour marks each', (
    tester,
  ) async {
    final n = DateTime.now().toUtc();
    await openDetail(
      tester,
      server: {
        'vn-ha-noi': live(fetched: n, temp: 22),
        'vn-tp-hcm': live(fetched: n, temp: 31),
      },
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    final sheet = find.byType(SingleChildScrollView).last;
    expect(
      find.descendant(of: sheet, matching: find.text('BẠN')),
      findsOneWidget,
    );
    final meY = tester.getTopLeft(
      find.descendant(of: sheet, matching: find.text('BẠN')),
    ).dy;
    final herY = tester.getTopLeft(
      find.descendant(of: sheet, matching: find.text('THẢO')),
    ).dy;
    expect(meY, lessThan(herY));

    // The scale: both places print the same two end labels (22° … 31°).
    expect(find.textContaining('Từ giờ tới khuya'), findsNWidgets(2));
    expect(find.text('22°'), findsWidgets);
    expect(
      find.descendant(of: sheet, matching: find.text('31°')),
      findsWidgets,
    );
    // Five marks per place: 3-hour wall-clock labels.
    final marks = _texts(tester).where((t) => RegExp(r'^\d\d:00$').hasMatch(t));
    expect(marks.length, 10);
    expect(marks.every((t) => int.parse(t.substring(0, 2)) % 3 == 0), isTrue);
  });

  testWidgets('SH-02: "bên đó đang hh:mm" only where the city clock differs', (
    tester,
  ) async {
    final n = DateTime.now().toUtc();
    await openDetail(
      tester,
      server: {
        'vn-ha-noi': live(fetched: n),
        'jp-tokyo': live(fetched: n),
      },
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'jp-tokyo')},
    );
    final phone = DateTime.now().timeZoneOffset;
    final differing = [
      for (final id in ['vn-ha-noi', 'jp-tokyo'])
        if (WeatherProvider.cityUtcOffset(weatherCityById(id)!, DateTime.now()) !=
            phone)
          id,
    ];
    expect(differing, isNotEmpty, reason: 'Hà Nội +7 and Tokyo +9 differ');
    final stamps = _texts(tester).where((t) => t.contains('bên đó đang')).toList();
    expect(stamps.length, differing.length);
    expect(
      stamps.every((t) => RegExp(r'bên đó đang \d\d:\d\d').hasMatch(t)),
      isTrue,
    );
  });

  testWidgets('SH-03: old numbers (10 h) → no nudge under the scale', (
    tester,
  ) async {
    final n = DateTime.now().toUtc();
    await openDetail(
      tester,
      server: {
        'vn-ha-noi': live(fetched: n),
        'vn-tp-hcm': live(
          fetched: n.subtract(const Duration(hours: 10)),
          rainNow: true,
        ),
      },
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    expect(find.textContaining('Từ giờ tới khuya'), findsNWidgets(2));
    expect(find.text('Nhắc Thảo mang ô'), findsNothing);
    expect(find.byType(WeatherNudgeButton), findsNothing);
  });

  testWidgets('SH-03: control — the same rain with fresh numbers shows the nudge', (
    tester,
  ) async {
    final n = DateTime.now().toUtc();
    await openDetail(
      tester,
      server: {
        'vn-ha-noi': live(fetched: n),
        'vn-tp-hcm': live(fetched: n, rainNow: true),
      },
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    expect(find.byType(WeatherNudgeButton), findsWidgets);
  });

  testWidgets('SH-06: numbers older than 24 h or none → error row, no invented figures', (
    tester,
  ) async {
    final n = DateTime.now().toUtc();
    await openDetail(
      tester,
      server: {
        'vn-ha-noi': live(fetched: n),
        'vn-tp-hcm': live(fetched: n.subtract(const Duration(hours: 30))),
      },
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    expect(find.text('Chưa tải được thời tiết'), findsWidgets);
    expect(find.text('Thử lại'), findsWidgets);
    // Only my place has a scale; Thảo's block has none.
    expect(find.textContaining('Từ giờ tới khuya'), findsOneWidget);
    expect(find.byType(WeatherNudgeButton), findsNothing);
  });

  testWidgets('SH-06: a place the server has no data for → the same error row', (
    tester,
  ) async {
    final n = DateTime.now().toUtc();
    await openDetail(
      tester,
      server: {'vn-ha-noi': live(fetched: n)},
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    expect(find.text('Chưa tải được thời tiết'), findsWidgets);
    expect(find.textContaining('Từ giờ tới khuya'), findsOneWidget);
  });

  // ── ST-03 / ST-06 ────────────────────────────────────────────────────────

  testWidgets('ST-03: "Chỗ Thảo" opens the picker while she has not picked', (
    tester,
  ) async {
    final svc = FakeWeatherService()..server = {'vn-ha-noi': fc()};
    await pump(
      tester,
      svc,
      choices: {'me': ch('me', 'vn-ha-noi')},
      child: WeatherSettingsSection(couple: _couple()),
    );
    expect(find.text('Chỗ Thảo'), findsOneWidget);
    expect(find.text('Chưa chọn'), findsOneWidget);
    await tester.tap(find.text('Chỗ Thảo'));
    await tester.pumpAndSettle();
    expect(find.byType(CityPicker), findsOneWidget);
    expect(find.text('Thảo đang ở đâu?'), findsOneWidget);
    await tester.tap(find.text('TP.HCM'));
    await tester.pumpAndSettle();
    expect(svc.writes, ['other=vn-tp-hcm by me']);
  });

  testWidgets('ST-03: once Thảo picked herself the row is not tappable', (
    tester,
  ) async {
    final svc = FakeWeatherService()
      ..server = {'vn-ha-noi': fc(), 'vn-da-lat': fc()};
    await pump(
      tester,
      svc,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-da-lat')},
      child: WeatherSettingsSection(couple: _couple()),
    );
    expect(find.text('Đà Lạt · Thảo tự chọn'), findsOneWidget);
    await tester.tap(find.text('Chỗ Thảo'));
    await tester.pumpAndSettle();
    expect(find.byType(CityPicker), findsNothing);
  });

  testWidgets('ST-06: waiting couple → the switch is locked with its reason', (
    tester,
  ) async {
    await pump(
      tester,
      FakeWeatherService(),
      choices: {},
      waiting: true,
      child: WeatherSettingsSection(couple: _couple(waiting: true)),
    );
    expect(find.text('Ghép đôi xong mới báo được.'), findsOneWidget);
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.onChanged, isNull);
    expect(sw.value, isFalse);
    expect(find.text('Chỗ Thảo'), findsNothing, reason: 'no partner row yet');
  });

  // ── LG-01 ────────────────────────────────────────────────────────────────

  Future<void> expectNoVietnamese(WidgetTester tester) async {
    final all = _texts(tester).map((t) => t.replaceAll(RegExp('thảo', caseSensitive: false), '')).toList();
    final bad = all.where(_vietnamese.hasMatch).toList();
    expect(bad, isEmpty, reason: 'Vietnamese on an English screen: $bad');
  }

  testWidgets('LG-01: English — invite, lanes, stale, error, sheet, settings', (
    tester,
  ) async {
    // Invite
    await pump(tester, FakeWeatherService(), lang: 'en', choices: {});
    expect(find.text('Choose a city'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
    await expectNoVietnamese(tester);

    // Lanes with the nudge
    await pump(
      tester,
      FakeWeatherService()
        ..server = {'vn-ha-noi': fc(), 'vn-tp-hcm': fc(symbol: 'rain')},
      lang: 'en',
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    expect(find.text('Remind Thảo: umbrella'), findsOneWidget);
    expect(find.text('HCMC · Rain this afternoon'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
    await expectNoVietnamese(tester);

    // Stale
    await pump(
      tester,
      FakeWeatherService()
        ..server = {
          'vn-ha-noi': fc(fetched: t0.subtract(const Duration(hours: 10))),
        },
      lang: 'en',
      choices: {'me': ch('me', 'vn-ha-noi')},
    );
    expect(find.textContaining('As of'), findsWidgets);
    expect(find.text('Try again'), findsWidgets);
    await expectNoVietnamese(tester);

    // Error (nothing loaded)
    await pump(
      tester,
      FakeWeatherService()..server = null,
      lang: 'en',
      choices: {'me': ch('me', 'vn-ha-noi')},
    );
    expect(find.text("Couldn't load the weather"), findsWidgets);
    await expectNoVietnamese(tester);

    // Settings
    await pump(
      tester,
      FakeWeatherService()..server = {'vn-ha-noi': fc()},
      lang: 'en',
      choices: {'me': ch('me', 'vn-ha-noi')},
      child: WeatherSettingsSection(couple: _couple()),
    );
    expect(find.text('Your city'), findsOneWidget);
    expect(find.text("Thảo's city"), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    await expectNoVietnamese(tester);
  });

  testWidgets('LG-01: English picker and detail sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final n = DateTime.now().toUtc();
    final svc = FakeWeatherService()
      ..server = {
        'vn-ha-noi': live(fetched: n),
        'vn-tp-hcm': live(fetched: n, rainNow: true),
      };
    await pump(
      tester,
      svc,
      lang: 'en',
      clock: () => DateTime.now().toUtc(),
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
      child: _openers(_couple()),
    );
    await tester.tap(find.byKey(const Key('open-detail')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rest of today'), findsNWidgets(2));
    expect(find.text('Change city'), findsOneWidget);
    await expectNoVietnamese(tester);
    await tester.tapAt(const Offset(5, 5)); // scrim
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-chain')));
    await tester.pumpAndSettle();
    expect(find.text('Where are you?'), findsOneWidget);
    expect(find.text('Search a city or province'), findsOneWidget);
    expect(find.text('Vietnam'), findsOneWidget);
    await expectNoVietnamese(tester);
  });

  // ── A11-03 ───────────────────────────────────────────────────────────────

  final anyButton = find.byWidgetPredicate((w) => w is ButtonStyleButton);

  void expectTarget(WidgetTester tester, Finder f, {double min = 44}) {
    final s = tester.getSize(f.first);
    expect(s.height, greaterThanOrEqualTo(min), reason: '$f is ${s.height}');
    expect(s.width, greaterThanOrEqualTo(min), reason: '$f is ${s.width}');
  }

  testWidgets('A11-03: invite buttons are ≥ 44 dp', (tester) async {
    await pump(tester, FakeWeatherService(), choices: {});
    expectTarget(tester, find.ancestor(of: find.text('Chọn thành phố'), matching: anyButton));
    expectTarget(tester, find.ancestor(of: find.text('Ẩn'), matching: find.byType(InkWell)));
  });

  testWidgets('A11-03: nudge, "Chọn giúp" and retry are ≥ 44 dp', (tester) async {
    await pump(
      tester,
      FakeWeatherService()
        ..server = {'vn-ha-noi': fc(), 'vn-tp-hcm': fc(symbol: 'rain')},
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    expectTarget(tester, find.byType(WeatherNudgeButton));

    await pump(
      tester,
      FakeWeatherService()..server = {'vn-ha-noi': fc()},
      choices: {'me': ch('me', 'vn-ha-noi')},
    );
    expectTarget(tester, find.ancestor(of: find.text('Chọn giúp'), matching: anyButton));

    await pump(
      tester,
      FakeWeatherService()..server = null,
      choices: {'me': ch('me', 'vn-ha-noi')},
    );
    expectTarget(tester, find.ancestor(of: find.text('Thử lại'), matching: anyButton));
  });

  testWidgets('A11-03: city rows in the picker are ≥ 52 dp', (tester) async {
    await pump(
      tester,
      FakeWeatherService(),
      choices: {},
      child: const SizedBox(
        height: 700,
        child: CityPicker(
          forPartner: false,
          partnerName: 'Thảo',
          entry: 'card',
        ),
      ),
    );
    final row = find.ancestor(
      of: find.text('Hà Nội'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(row.first).height, greaterThanOrEqualTo(52));
    final clear = find.widgetWithIcon(IconButton, Icons.close);
    expect(clear, findsNothing);
  });
}
