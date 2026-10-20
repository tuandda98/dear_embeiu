import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
import 'package:dear_embeiu/widgets/person_label.dart';
import 'package:dear_embeiu/widgets/weather/weather_card.dart';
import 'package:dear_embeiu/widgets/weather/weather_sheets.dart';

import 'weather_fakes.dart';

/// The Home card's main states (design §5 + §14b, Home C §15) and the city
/// picker (unaccented search, the 3-tap first-time chain).

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

/// 20 hours from 08:00 VN; hour 7 (15:00) gets [symbol].
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

WeatherChoice ch(String uid, String city) =>
    WeatherChoice(uid: uid, cityId: city, setBy: uid);

Future<(FakeWeatherService, WeatherProvider)> pump(
  WidgetTester tester, {
  required Map<String, WeatherChoice> choices,
  Map<String, CityForecast> server = const {},
  Map<String, CityForecast> hive = const {},
  bool waiting = false,
  Widget? child,
}) async {
  final svc = FakeWeatherService()..server = {...server};
  svc.hive.addAll(hive);
  final w = WeatherProvider(
    service: svc,
    clock: () => t0,
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
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
  return (svc, w);
}

List<String> laneNames(WidgetTester tester) => tester
    .widgetList<PersonLabel>(find.byType(PersonLabel))
    .map((l) => l.name)
    .toList();

void main() {
  testWidgets('nobody picked: the invite with "Chọn thành phố" + "Ẩn"', (
    tester,
  ) async {
    final (_, w) = await pump(tester, choices: {});
    expect(find.text('Chọn thành phố'), findsOneWidget);
    expect(find.textContaining('chỗ Thảo'), findsOneWidget);
    await tester.tap(find.text('Ẩn'));
    await tester.pump();
    expect(w.cardVisible, isFalse);
    expect(find.text('Thời tiết hai nơi'), findsNothing);
  });

  testWidgets('nothing worth a nudge: folds into one row', (tester) async {
    await pump(
      tester,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
      server: {'vn-ha-noi': fc(temp: 24), 'vn-tp-hcm': fc(temp: 27)},
    );
    expect(find.text('Thời tiết hai nơi'), findsOneWidget);
    expect(find.byType(PersonLabel), findsNothing);
    expect(find.textContaining('Hà Nội'), findsOneWidget);
    expect(find.text('Nhiều mây'), findsOneWidget);
    expect(find.textContaining('Nhắc'), findsNothing);
  });

  testWidgets('rain at their place: two lanes (you left) + named nudge', (
    tester,
  ) async {
    await pump(
      tester,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
      server: {
        'vn-ha-noi': fc(temp: 23),
        'vn-tp-hcm': fc(symbol: 'rain', temp: 29),
      },
    );
    expect(laneNames(tester), ['Bạn', 'Thảo']);
    expect(find.text('Nhắc Thảo mang ô'), findsOneWidget);
    expect(find.text('TP.HCM · Chiều nay mưa'), findsOneWidget);
    expect(find.textContaining('Cập nhật'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Nhắc Thảo mang ô'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('≥ 5° apart, plain sky: the gap line, no nudge', (tester) async {
    await pump(
      tester,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-da-lat')},
      server: {'vn-ha-noi': fc(temp: 24), 'vn-da-lat': fc(temp: 18)},
    );
    expect(find.text('Chỗ Thảo lạnh hơn 6°'), findsOneWidget);
    expect(find.textContaining('Nhắc'), findsNothing);
  });

  testWidgets('partner not picked: "Thảo đang ở đâu?" + "Chọn giúp"', (
    tester,
  ) async {
    await pump(
      tester,
      choices: {'me': ch('me', 'vn-ha-noi')},
      server: {'vn-ha-noi': fc()},
    );
    expect(find.text('Thảo đang ở đâu?'), findsOneWidget);
    expect(find.text('Chọn giúp'), findsOneWidget);
  });

  testWidgets('old numbers (10 h): grey, "Số liệu lúc" + Thử lại, no nudge', (
    tester,
  ) async {
    final old = t0.subtract(const Duration(hours: 10));
    final (svc, _) = await pump(
      tester,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
      server: {
        'vn-ha-noi': fc(fetched: old),
        'vn-tp-hcm': fc(fetched: old, symbol: 'rain'),
      },
    );
    expect(find.text('Chưa cập nhật được'), findsOneWidget);
    expect(find.textContaining('Số liệu lúc'), findsOneWidget);
    expect(find.textContaining('Nhắc'), findsNothing);
    final before = svc.calls.length;
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(svc.calls.length, before + 1);
  });

  testWidgets('never loaded: city names + "Chưa tải được thời tiết"', (
    tester,
  ) async {
    final (svc, _) = await pump(
      tester,
      choices: {'me': ch('me', 'vn-ha-noi'), 'other': ch('other', 'vn-tp-hcm')},
    );
    svc.server = null;
    expect(find.text('Chưa tải được thời tiết'), findsOneWidget);
    expect(find.text('Hà Nội'), findsOneWidget);
    expect(find.text('TP.HCM'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('waiting for the partner: your lane only, no nudge', (
    tester,
  ) async {
    await pump(
      tester,
      waiting: true,
      choices: {'me': ch('me', 'vn-ha-noi')},
      server: {'vn-ha-noi': fc(symbol: 'rain')},
    );
    expect(laneNames(tester), ['Bạn']);
    expect(find.textContaining('Nhắc'), findsNothing);
    expect(find.text('Hà Nội · Chiều nay mưa'), findsOneWidget);
  });

  testWidgets('320 dp at 200% text: no overflow (state 21)', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(
      tester,
      choices: {
        'me': ch('me', 'vn-buon-ma-thuot'),
        'other': ch('other', 'vn-tp-hcm'),
      },
      server: {
        'vn-buon-ma-thuot': fc(temp: 23),
        'vn-tp-hcm': fc(symbol: 'rain', temp: 29),
      },
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Nhắc Thảo mang ô'), findsOneWidget);
  });

  group('city picker', () {
    Future<WeatherProvider> openPicker(WidgetTester tester) async {
      final (_, w) = await pump(
        tester,
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
      return w;
    }

    testWidgets('unaccented, no spaces, old province, nothing found', (
      tester,
    ) async {
      await openPicker(tester);
      expect(find.text('Bạn đang ở đâu?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'hanoi');
      await tester.pump();
      expect(find.text('Hà Nội'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'binh thuan');
      await tester.pump();
      expect(find.text('Tỉnh cũ: Bình Thuận'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'hcm');
      await tester.pump();
      expect(find.textContaining('TP.HCM'), findsWidgets);
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump();
      expect(
        find.text('Chưa có thành phố này. Chọn nơi gần nhất nhé.'),
        findsOneWidget,
      );
    });

    testWidgets('first time: my city, then "Còn Thảo đang ở đâu?" (3 taps)', (
      tester,
    ) async {
      final (svc, _) = await pump(
        tester,
        choices: {},
        child: const SizedBox(
          height: 700,
          child: CityPicker(
            forPartner: false,
            chain: true,
            partnerName: 'Thảo',
            entry: 'card',
          ),
        ),
      );
      await tester.tap(find.text('Hà Nội'));
      await tester.pump();
      expect(find.text('Còn Thảo đang ở đâu?'), findsOneWidget);
      expect(find.text('Để sau'), findsOneWidget);
      await tester.tap(find.text('TP.HCM'));
      await tester.pump();
      expect(svc.writes, ['me=vn-ha-noi by me', 'other=vn-tp-hcm by me']);
    });
  });
}
