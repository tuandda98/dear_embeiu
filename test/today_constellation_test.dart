import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/models/chat_message.dart';
import 'package:dear_embeiu/models/couple.dart';
import 'package:dear_embeiu/models/daily_answer.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/chat_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/providers/daily_question_provider.dart';
import 'package:dear_embeiu/providers/mood_provider.dart';
import 'package:dear_embeiu/providers/photo_provider.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/providers/streak_provider.dart';
import 'package:dear_embeiu/screens/love_tree_screen.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/widgets/today_constellation.dart';

final _epoch = DateTime(2026, 1, 1);

class _Auth extends AuthProvider {
  _Auth() : super(authService: AuthService());

  @override
  AppUser? get currentUser => AppUser(
    id: 'me',
    email: 'me@test.dev',
    displayName: 'Anh',
    inviteCode: 'ABC123',
    status: 'in_couple',
    createdAt: _epoch,
    updatedAt: _epoch,
  );
}

class _Couple extends CoupleProvider {
  _Couple(String partnerName)
    : _couple = Couple(
        id: 'c1',
        person1Name: partnerName,
        person2Name: 'Anh',
        anniversaryDate: DateTime.now().subtract(const Duration(days: 10)),
        inviteCode: 'ABC123',
        memberIds: const ['other', 'me'],
        memberCount: 2,
        createdByUserId: 'other',
        status: 'active',
        createdAt: _epoch,
        updatedAt: _epoch,
      );

  final Couple _couple;

  @override
  Couple? get couple => _couple;
}

/// Empty providers: every star unlit, "Làm ngay" on all of my rows — the
/// widest layout.
Widget _app(
  Widget home, {
  String partner = 'Minh Anh',
  String lang = 'vi',
  GlobalKey<NavigatorState>? navigatorKey,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => _Auth()),
    ChangeNotifierProvider<CoupleProvider>(create: (_) => _Couple(partner)),
    ChangeNotifierProvider(create: (_) => PhotoProvider()),
    ChangeNotifierProvider(create: (_) => StreakProvider()),
    ChangeNotifierProvider(create: (_) => DailyQuestionProvider()),
    ChangeNotifierProvider(create: (_) => MoodProvider()),
    ChangeNotifierProvider(create: (_) => ChatProvider()),
    ChangeNotifierProvider(create: (_) => SleepProvider()),
  ],
  child: MaterialApp(
    navigatorKey: navigatorKey,
    theme: AppTheme.lightTheme,
    locale: Locale(lang),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Widget _section() => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TodayConstellationSection(
      partnerName: 'Minh Anh',
      onAct: (_) {},
      onNudge: () {},
    ),
  ),
);

/// A [width]dp phone with text at [scale]; Reduce Motion on so screens settle.
void _phone(WidgetTester tester, double width, {double scale = 1}) {
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

/// Real glyph widths: the overflow bugs only show with the app's font.
Future<void> _loadQuicksand() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Quicksand-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadQuicksand();
    // The Love Tree keeps its "seen" marker in this box.
    Hive.init(Directory.systemTemp.createTempSync('love_tree_test').path);
    await Hive.openBox<String>('app_settings');
  });

  test('segments: all 64 combinations', () {
    for (var mask = 0; mask < 64; mask++) {
      // Bits 0–2: my question/mood/message; bits 3–5: my partner's.
      bool on(int bit) => (mask >> bit) & 1 == 1;
      final sky = TodayConstellation(
        mine: {for (final t in CareTask.values) t: CareStar(lit: on(t.index))},
        partner: {
          for (final t in CareTask.values) t: CareStar(lit: on(3 + t.index)),
        },
      );
      final top = on(0) && on(3); // both answered
      final bottom = on(2) && on(5); // both messaged
      expect(sky.segments, [
        top,
        on(0) && on(1),
        on(1) && on(2),
        bottom,
        bottom,
        on(5) && on(4),
        on(4) && on(3),
        top,
      ], reason: 'mask $mask');
      expect(sky.litCount, List.generate(6, on).where((b) => b).length);
      expect(sky.isFull, mask == 63);
      expect(sky.segments.every((s) => s), mask == 63, reason: 'mask $mask');
    }
  });

  group('TodayConstellation.from', () {
    final now = DateTime(2026, 10, 11, 0, 5);
    final lastNight = DateTime(2026, 10, 10, 23, 59);

    TodayConstellation sky({
      required String questionDay,
      String myText = 'hi',
      List<ChatMessage> messages = const [],
    }) => TodayConstellation.from(
      myUid: 'me',
      now: now,
      questionDay: questionDay,
      myAnswer: DailyAnswer(authorUserId: 'me', text: myText),
      partnerAnswer: const DailyAnswer(authorUserId: 'other', text: 'hey'),
      messages: messages,
    );

    test('question stars only count answers of today', () {
      final today = sky(questionDay: '2026-10-11');
      expect(today.lit(true, CareTask.question), isTrue);
      expect(today.lit(false, CareTask.question), isTrue);

      // Past 0:00 the provider may still hold yesterday's answers.
      final stale = sky(questionDay: '2026-10-10');
      expect(stale.lit(true, CareTask.question), isFalse);
      expect(stale.lit(false, CareTask.question), isFalse);
      expect(sky(questionDay: '').litCount, 0);
    });

    test('a blank answer does not light my star', () {
      final s = sky(questionDay: '2026-10-11', myText: '   ');
      expect(s.lit(true, CareTask.question), isFalse);
      expect(s.lit(false, CareTask.question), isTrue);
    });

    test('message stars count today only; a pending one is "now"', () {
      final s = sky(
        questionDay: '2026-10-11',
        messages: [
          const ChatMessage(authorUserId: 'me', text: 'x', isPending: true),
          ChatMessage(authorUserId: 'other', text: 'y', createdAt: lastNight),
        ],
      );
      expect(s.star(true, CareTask.message).at, now);
      expect(s.lit(false, CareTask.message), isFalse);
    });
  });

  testWidgets('MidnightBuilder rebuilds at midnight and on resume', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      MidnightBuilder(
        builder: (_) {
          builds++;
          return const SizedBox();
        },
      ),
    );
    expect(builds, 1);

    await tester.pump(const Duration(hours: 24));
    expect(builds, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(builds, 3);
  });

  group('star labels stay on screen and off the stars', () {
    for (final lang in ['vi', 'en']) {
      for (final width in [320.0, 360.0]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets('$lang @${width}dp ×$scale', (tester) async {
            _phone(tester, width, scale: scale);
            await tester.pumpWidget(_app(_section(), lang: lang));
            await tester.pump();

            final box = tester.getRect(
              find.byWidgetPredicate(
                (w) => w is SizedBox && w.width == 260 && w.height == 216,
              ),
            );
            // A lit star is 26px across.
            final stars = [
              for (final e
                  in find
                      .byWidgetPredicate(
                        (w) => w is Semantics && w.properties.selected != null,
                      )
                      .evaluate())
                Rect.fromCenter(
                  center: tester.getCenter(find.byWidget(e.widget)),
                  width: 26,
                  height: 26,
                ),
            ];
            expect(stars, hasLength(6));

            final names = lang == 'vi'
                ? ['Câu hỏi', 'Tâm trạng', 'Nhắn tin']
                : ['Question', 'Mood', 'Message'];
            for (final name in names) {
              for (var i = 0; i < 2; i++) {
                final r = tester.getRect(find.text(name).at(i));
                expect(r.left, greaterThanOrEqualTo(0), reason: name);
                expect(r.right, lessThanOrEqualTo(width), reason: name);
                if (name == names[1]) {
                  expect(r.left, greaterThanOrEqualTo(box.left), reason: name);
                  expect(r.right, lessThanOrEqualTo(box.right), reason: name);
                }
                for (final star in stars) {
                  expect(r.overlaps(star), isFalse, reason: '$name on a star');
                }
              }
            }
          });
        }
      }
    }
  });

  group('Việc nhỏ hôm nay with a 23-letter partner name', () {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('@${width}dp ×$scale', (tester) async {
          _phone(tester, width, scale: scale);
          await tester.pumpWidget(
            _app(const LoveTreeScreen(), partner: 'Nguyễn Hoàng Phương Anh'),
          );
          await tester.pump(const Duration(seconds: 2));
          expect(tester.takeException(), isNull);
          expect(find.textContaining('· chưa'), findsWidgets);
        });
      }
    }
  });

  testWidgets('screen readers can open a star, close it and open the tree', (
    tester,
  ) async {
    _phone(tester, 390);
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ConstellationPill(onTap: () => opened++),
                TodayConstellationSection(
                  partnerName: 'Minh Anh',
                  onAct: (_) {},
                  onNudge: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    tester.semantics.tap(find.semantics.byLabel(RegExp('^Bạn · Chia sẻ')));
    await tester.pumpAndSettle();
    expect(find.text('Chia sẻ ngay'), findsOneWidget);

    tester.semantics.tap(find.semantics.byLabel('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Chia sẻ ngay'), findsNothing);

    tester.semantics.tap(
      find.semantics.byLabel(RegExp('^Chòm sao hôm nay: 0')),
    );
    expect(opened, 1);
    semantics.dispose();
  });

  testWidgets('the sky stops animating once it scrolls away', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const LoveTreeScreen()));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'twinkling');

    // Settles only if nothing keeps ticking once the sky is gone.
    final page = find.byType(SingleChildScrollView);
    await tester.drag(page, const Offset(0, -3000));
    await tester.pumpAndSettle();

    await tester.drag(page, const Offset(0, 3000));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'sky back');
  });

  testWidgets('status-bar icons: light over the sky, dark otherwise', (
    tester,
  ) async {
    _phone(tester, 390);
    final nav = GlobalKey<NavigatorState>();
    Brightness? icons() => SystemChrome.latestStyle?.statusBarIconBrightness;
    await tester.pumpWidget(_app(const Scaffold(), navigatorKey: nav));

    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const LoveTreeScreen()),
    );
    await tester.pumpAndSettle();
    expect(icons(), Brightness.light);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    expect(icons(), Brightness.dark, reason: 'scrolled past the sky');

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    expect(icons(), Brightness.light);

    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    expect(icons(), Brightness.dark, reason: 'covered');

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(icons(), Brightness.light);

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(icons(), Brightness.dark, reason: 'closed');
  });
}
