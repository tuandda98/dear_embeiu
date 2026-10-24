import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_notification.dart';
import 'package:dear_embeiu/models/caro_game.dart';
import 'package:dear_embeiu/providers/caro_game_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/screens/caro_game_screen.dart';
import 'package:dear_embeiu/screens/caro_history_screen.dart';
import 'package:dear_embeiu/widgets/shimmer_skeleton.dart';
import 'package:dear_embeiu/services/caro_game_service.dart';
import 'package:dear_embeiu/services/home_widget_status.dart';
import 'package:dear_embeiu/services/push_notification_service.dart';
import 'package:dear_embeiu/widgets/caro/caro_board.dart';
import 'package:dear_embeiu/widgets/caro/caro_common.dart';
import 'package:dear_embeiu/widgets/caro/caro_new_game_sheet.dart';
import 'package:dear_embeiu/widgets/play_together_card.dart';
import 'package:dear_embeiu/widgets/today_constellation.dart';

import 'sleep_provider_test.dart' show FakeSleepService;

/// Feature caro-game stage 2: the UI logic around the board, Home card,
/// push / inbox routing and the widget line.
final DateTime now = DateTime(2026, 10, 20, 15, 0);

CaroGame g({
  String id = 'g1',
  List<int> cells = const [112],
  String status = 'playing',
  String turn = 'me',
  String createdBy = 'bob',
  String x = 'bob',
  String o = 'me',
  DateTime? lastMoveAt,
  String? lastMoveBy,
  DateTime? createdAt,
  DateTime? finishedAt,
  Map<String, Object?>? result,
  Map<String, Object?> presence = const {},
  String? rematchOf,
}) => CaroGame.fromFirestore(id, <String, dynamic>{
  'type': 'caro',
  'rule': 'vn',
  'createdBy': createdBy,
  'players': {'x': x, 'o': o},
  'status': status,
  'cells': cells,
  'turnUid': turn,
  'lastMoveAt': lastMoveAt ?? now.subtract(const Duration(minutes: 5)),
  'lastMoveBy': ?lastMoveBy,
  'createdAt': createdAt ?? now.subtract(const Duration(hours: 1)),
  'finishedAt': ?finishedAt,
  'result': ?result,
  'presence': presence,
  'rematchOf': ?rematchOf,
});

class _FakeService extends CaroGameService {
  final state = StreamController<CaroState>.broadcast();
  final games = <String, StreamController<CaroGame?>>{};
  final calls = <Map<String, Object?>>[];
  CaroActionResult reply = const CaroActionResult(CaroActionStatus.failed);
  CaroHistoryPage page = const CaroHistoryPage.empty();

  StreamController<CaroGame?> stream(String id) =>
      games.putIfAbsent(id, () => StreamController<CaroGame?>.broadcast());

  @override
  bool get isUsingFirebase => true;

  @override
  Stream<CaroState> watchState(String coupleId) => state.stream;

  @override
  Stream<CaroGame?> watchGame(String coupleId, String gameId) =>
      stream(gameId).stream;

  @override
  Future<bool> heartbeat(String coupleId, String gameId, String uid) async =>
      true;

  @override
  Future<bool> clearPresence(String c, String gameId, String uid) async => true;

  @override
  Future<CaroActionResult> action({
    required String coupleId,
    required String op,
    String? gameId,
    int? cell,
    int? moveNo,
    CaroRule? rule,
    String? rematchOf,
  }) async {
    calls.add({'op': op, 'rule': rule?.key, 'cell': cell});
    return reply;
  }

  @override
  Future<CaroHistoryPage> fetchHistoryPage({
    required String coupleId,
    int limit = 30,
    dynamic startAfter,
  }) async => page;
}

Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));

  group('two-step tap (design C5)', () {
    final t0 = DateTime(2026, 10, 20, 10);
    test('tap 1 selects, tap 2 on the same square plays after 400 ms', () {
      final s = CaroTapSelector();
      expect(s.tap(10, t0), CaroTapResult.selected);
      expect(s.selected, 10);
      expect(
        s.tap(10, t0.add(const Duration(milliseconds: 399))),
        CaroTapResult.ignored,
      );
      expect(
        s.tap(10, t0.add(const Duration(milliseconds: 400))),
        CaroTapResult.play,
      );
    });

    test('another square moves the selection and restarts the delay', () {
      final s = CaroTapSelector();
      s.tap(10, t0);
      expect(
        s.tap(11, t0.add(const Duration(seconds: 1))),
        CaroTapResult.selected,
      );
      expect(s.selected, 11);
      expect(
        s.tap(11, t0.add(const Duration(milliseconds: 1100))),
        CaroTapResult.ignored,
      );
      s.clear();
      expect(s.selected, isNull);
    });

    test('zoom matrix centres the last move and stays inside the board', () {
      final m = caroZoomMatrix(300, 1.6, CaroBoard.indexOf(7, 7));
      expect(m.getMaxScaleOnAxis(), closeTo(1.6, 1e-9));
      final corner = caroZoomMatrix(300, 1.6, 0);
      expect(corner.getTranslation().x, 0); // clamped at the top-left edge
      expect(caroZoomMatrix(300, 1, 5), Matrix4.identity());
    });
  });

  group('rule remembered (design §3.2)', () {
    late Directory dir;
    setUp(() async {
      dir = Directory.systemTemp.createTempSync('caro_prefs');
      Hive.init(dir.path);
      await Hive.openBox<String>(CaroPrefs.box);
    });
    tearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('null until a game was started, then the last rule', () async {
      expect(await CaroPrefs.lastRule(), isNull);
      await CaroPrefs.setLastRule(CaroRule.free);
      expect(await CaroPrefs.lastRule(), CaroRule.free);
      await CaroPrefs.setLastRule(CaroRule.vn);
      expect(await CaroPrefs.lastRule(), CaroRule.vn);
    });

    test('tap-again hint counts only the first 5 moves', () async {
      for (var i = 0; i < 7; i++) {
        await CaroPrefs.countMove();
      }
      expect(await CaroPrefs.movesPlayed(), CaroPrefs.hintMoves);
    });
  });

  testWidgets(
    'sheet pre-selects last time’s rule, tagged, and starts with it',
    (tester) async {
      final service = _FakeService();
      final caro = CaroGameProvider(service: service)
        ..watchForCouple('c', 'me', 'bob');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CaroGameProvider>.value(value: caro),
            ChangeNotifierProvider(create: (_) => CoupleProvider()),
            ChangeNotifierProvider(
              create: (_) => SleepProvider(service: FakeSleepService()),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: CaroNewGameSheet(
                  lastRule: CaroRule.free,
                  hostContext: context,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('lần trước'), findsOneWidget);
      await tester.tap(find.text('Rủ Người ấy chơi'));
      await tester.pump();
      expect(service.calls.single, {
        'op': 'start',
        'rule': 'free',
        'cell': 112,
      });
      // Failure keeps the sheet open with the reason.
      expect(find.text(vi.caroSendError), findsOneWidget);
    },
  );

  group('push + inbox routing (both places)', () {
    tearDown(() {
      NotificationTapRouter.consumeCaroGameRequest();
      NotificationTapRouter.consumeHomeFocusRequest();
      NotificationTapRouter.consumeHomeTabRequest();
      NotificationTapRouter.caroGameOnScreen = null;
    });

    for (final type in [
      'caro_invite',
      'caro_turn',
      'caro_nudge',
      'caro_result',
    ]) {
      test('$type push opens that game on Home', () {
        PushNotificationService.instance.routeTapForTest({
          'type': type,
          'gameId': 'g7',
        });
        expect(NotificationTapRouter.pendingHomeTab.value, 0);
        expect(NotificationTapRouter.pendingCaroGameId.value, 'g7');
        expect(
          NotificationTapRouter.pendingHomeFocus.value,
          NotificationTapRouter.focusCaroGame,
        );
        expect(NotificationTapRouter.pendingCaroSource, 'push');
        NotificationTapRouter.consumeCaroGameRequest();
        NotificationTapRouter.consumeHomeFocusRequest();
        NotificationTapRouter.consumeHomeTabRequest();
      });
    }

    test('inbox caro_invite: own type, Home tab, carries the game id', () {
      final n = AppNotification.fromDoc('n1', {
        'type': 'caro_invite',
        'coupleId': 'c',
        'gameId': 'g7',
        'actorUserId': 'bob',
        'actorName': 'Thảo',
      });
      expect(n.type, AppNotificationType.caroInvite);
      expect(n.targetHomeTab, 0);
      expect(n.gameId, 'g7');
      expect(vi.caroNotifInvite('Thảo'), 'Thảo rủ bạn chơi cờ caro');
    });

    test('no in-app banner for a push about the game on screen', () {
      NotificationTapRouter.caroGameOnScreen = 'g7';
      expect(
        isCaroPushForVisibleGame({'type': 'caro_turn', 'gameId': 'g7'}),
        true,
      );
      expect(
        isCaroPushForVisibleGame({'type': 'caro_turn', 'gameId': 'g8'}),
        false,
      );
      expect(
        isCaroPushForVisibleGame({'type': 'chat_message', 'gameId': 'g7'}),
        false,
      );
    });
  });

  group('widget-today caro_turn', () {
    final quiet = TodayConstellation.from(
      myUid: 'me',
      now: now,
      questionDay: '2026-10-20',
      messages: const [],
    );

    test('app path: the partner just moved → caro_turn line, focus caro', () {
      final open = g(lastMoveBy: 'bob', lastMoveAt: DateTime(2026, 10, 20, 14));
      final at = HomeWidgetStatus.caroTurnAt(open, 'me');
      expect(at, DateTime(2026, 10, 20, 14));
      final s = HomeWidgetStatus.build(
        today: quiet,
        l10n: vi,
        now: now,
        active: true,
        partnerName: 'Thảo',
        questionReady: false,
        caroTurnAt: at,
      );
      expect(s['statusKind'], 'caro_turn');
      expect(s['statusText'], 'Thảo đã đi caro, đến lượt mình');
      expect(s['statusTextShort'], 'Lượt mình đi caro');
      expect(s['statusFocus'], 'caro');
      expect(HomeWidgetStatus.focuses, contains('caro'));
      expect(HomeWidgetStatus.kinds, contains('caro_turn'));
    });

    test('no line when it is the partner’s turn or my own last move', () {
      expect(HomeWidgetStatus.caroTurnAt(g(turn: 'bob'), 'me'), isNull);
      expect(HomeWidgetStatus.caroTurnAt(g(lastMoveBy: 'me'), 'me'), isNull);
      expect(HomeWidgetStatus.caroTurnAt(null, 'me'), isNull);
    });

    test('background push: caro_turn / caro_invite with no date = today', () {
      for (final type in ['caro_turn', 'caro_invite']) {
        final s = HomeWidgetStatus.fromPush(
          {'type': type, 'gameId': 'g', 'moveNo': '14', 'actorName': 'Thảo'},
          l10n: vi,
          now: now,
        );
        expect(s?['statusKind'], 'caro_turn', reason: type);
        expect(s?['statusText'], 'Thảo đã đi caro, đến lượt mình');
        expect(s?['onlyIfNewer'], '1');
      }
      // CARO-T4: a game the partner ended clears the line if it is older.
      for (final type in ['caro_result', 'caro_ended']) {
        final end = HomeWidgetStatus.fromPush(
          {'type': type, 'gameId': 'g', 'sentAt': '1760000000000'},
          l10n: vi,
          now: now,
        );
        expect(end?['statusKind'], '', reason: type);
        expect(end?['statusText'], '', reason: type);
        expect(end?['statusAt'], '1760000000000', reason: type);
        expect(end?['onlyIfKind'], HomeWidgetStatus.caroTurn, reason: type);
        expect(end?['onlyIfNewer'], '1', reason: type);
        expect(end?['todayDate'], '2026-10-20', reason: type);
      }
      final noTime = HomeWidgetStatus.fromPush(
        {'type': 'caro_ended'},
        l10n: vi,
        now: now,
      );
      expect(noTime?['statusAt'], '${now.millisecondsSinceEpoch}');
      expect(
        HomeWidgetStatus.fromPush(
          {'type': 'caro_turn', 'actorName': 'Thảo'},
          l10n: vi,
          now: now,
          sentAt: now.subtract(const Duration(days: 1)),
        ),
        isNull,
      );
    });
  });

  group('Home "Chơi cùng nhau" caro line (design §3.1)', () {
    CaroEntryKind kind({
      bool loaded = true,
      CaroGame? open,
      CaroGame? last,
      int total = 0,
    }) => caroEntryKindFor(
      loaded: loaded,
      open: open,
      last: last,
      myUid: 'me',
      partnerUid: 'bob',
      total: total,
      now: now,
    );
    CaroGame done(String? winner, {Duration ago = const Duration(hours: 2)}) =>
        g(
          status: 'finished',
          finishedAt: now.subtract(ago),
          result: {
            'winnerUid': winner ?? '',
            'reason': winner == null ? 'full' : 'five',
            'line': const <int>[],
          },
        );

    test('every state in priority order', () {
      expect(kind(loaded: false), CaroEntryKind.loading);
      expect(kind(open: g()), CaroEntryKind.invited);
      expect(
        kind(
          open: g(cells: [112, 113, 114], createdBy: 'bob'),
        ),
        CaroEntryKind.myTurn,
      );
      expect(
        kind(
          open: g(createdBy: 'me', turn: 'bob', x: 'me', o: 'bob'),
        ),
        CaroEntryKind.waiting,
      );
      expect(
        kind(
          open: g(
            turn: 'bob',
            presence: {'bob': now.subtract(const Duration(seconds: 10))},
          ),
        ),
        CaroEntryKind.watching,
      );
      expect(
        kind(
          open: g(
            turn: 'bob',
            lastMoveAt: now.subtract(const Duration(days: 8)),
          ),
        ),
        CaroEntryKind.stale,
      );
      expect(kind(last: done('bob')), CaroEntryKind.justLost);
      expect(kind(last: done('me')), CaroEntryKind.justWon);
      expect(kind(last: done(null)), CaroEntryKind.justDraw);
      expect(
        kind(last: done('me', ago: const Duration(days: 2)), total: 3),
        CaroEntryKind.idle,
      );
      expect(kind(), CaroEntryKind.first);
    });

    test('solid CTA + dot only while the partner waits on me (C6)', () {
      CaroEntryView view(CaroEntryKind k) => caroEntryView(
        vi,
        k,
        partnerName: 'Thảo',
        score: 'Tuấn 12 – 9 Thảo',
        moves: '14',
        time: '10:12',
        staleDays: '8',
      );
      expect(view(CaroEntryKind.myTurn).urgent, true);
      expect(view(CaroEntryKind.invited).urgent, true);
      expect(
        view(CaroEntryKind.myTurn).subtitle,
        'Đến lượt bạn. Thảo vừa đi nước 14.',
      );
      expect(view(CaroEntryKind.myTurn).cta, 'Đi tiếp');
      for (final k in [
        CaroEntryKind.waiting,
        CaroEntryKind.watching,
        CaroEntryKind.stale,
        CaroEntryKind.justLost,
        CaroEntryKind.idle,
        CaroEntryKind.first,
      ]) {
        expect(view(k).urgent, false, reason: '$k');
      }
      expect(view(CaroEntryKind.justLost).cta, 'Chơi');
      expect(
        view(CaroEntryKind.idle).subtitle,
        'Tuấn 12 – 9 Thảo. Rủ Thảo một ván?',
      );
    });

    testWidgets('a line renders copy + CTA and is one tap target', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaroEntryRow(
              view: const CaroEntryView(
                title: 'Cờ caro',
                subtitle: 'Đến lượt bạn. Thảo vừa đi nước 14.',
                cta: 'Đi tiếp',
                urgent: true,
              ),
              badge: const CaroGlyph(
                mine: Colors.pink,
                partner: Colors.teal,
                showDot: true,
              ),
              onTap: () => taps++,
            ),
          ),
        ),
      );
      expect(find.text('Đi tiếp'), findsOneWidget);
      await tester.tap(find.text('Cờ caro'));
      expect(taps, 1);
    });
  });

  group('game screen mode + ended result', () {
    test('modes from the game', () {
      CaroScreenMode m(
        CaroGame? game, {
        bool loaded = true,
        bool draft = false,
      }) => caroScreenModeFor(
        game: game,
        loaded: loaded,
        myUid: 'me',
        draft: draft,
        now: now,
      );
      expect(m(null, draft: true), CaroScreenMode.draft);
      expect(m(null, loaded: false), CaroScreenMode.loading);
      expect(m(null), CaroScreenMode.expired);
      expect(m(g()), CaroScreenMode.invited);
      expect(m(g(cells: [1, 2, 3])), CaroScreenMode.myTurn);
      expect(m(g(turn: 'bob')), CaroScreenMode.waiting);
      expect(m(g(status: 'cancelled')), CaroScreenMode.cancelled);
      expect(m(g(status: 'finished')), CaroScreenMode.finished);
    });

    test('caro_game_ended result from my side', () {
      CaroGame fin(String winner, String reason) => g(
        status: 'finished',
        result: {'winnerUid': winner, 'reason': reason, 'line': const <int>[]},
      );
      expect(caroEndedResult(fin('me', 'five'), 'me'), 'win');
      expect(caroEndedResult(fin('bob', 'five'), 'me'), 'lose');
      expect(caroEndedResult(fin('me', 'resign'), 'me'), 'resign_partner');
      expect(caroEndedResult(fin('bob', 'resign'), 'me'), 'resign_me');
      expect(caroEndedResult(fin('', 'full'), 'me'), 'draw');
      expect(caroEndedResult(g(status: 'cancelled'), 'me'), 'cancel');
      expect(caroEndedResult(g(status: 'expired'), 'me'), 'expired');
    });
  });

  testWidgets('game screen: one tap on a square sends the move', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final service = _FakeService();
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CaroGameProvider>.value(value: caro),
          ChangeNotifierProvider(create: (_) => CoupleProvider()),
          ChangeNotifierProvider(
            create: (_) => SleepProvider(service: FakeSleepService()),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CaroGameScreen(gameId: 'g1'),
        ),
      ),
    );
    await tester.pump(); // post-frame enter()
    service.stream('g1').add(g(lastMoveAt: DateTime.now()));
    await tester.pump();
    await tester.pump(); // initial zoom lands post-frame
    await tester.pump();
    expect(find.text(vi.caroInvitedTitle('Người ấy')), findsOneWidget);
    expect(find.text(vi.caroLater), findsOneWidget); // ≤1 stone: "Để sau"

    // Opened at 1.6× around the last move (7,7): (7,8) sits 1.6 cells right.
    final rect = tester.getRect(find.byType(InteractiveViewer));
    final cell = rect.width / CaroBoard.size;
    final target = rect.center + Offset(cell * 1.6, 0);
    await tester.tapAt(target);
    await tester.pump();
    await tester.pump();
    expect(service.calls.single, {'op': 'move', 'rule': null, 'cell': 113});
    // The fake refuses → the square stays selected, the reason shows.
    expect(find.text(vi.caroSendError), findsOneWidget);
    expect(find.text(vi.caroCtaRetry), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  Widget app(CaroGameProvider caro, Widget home) => MultiProvider(
    providers: [
      ChangeNotifierProvider<CaroGameProvider>.value(value: caro),
      ChangeNotifierProvider(create: (_) => CoupleProvider()),
      ChangeNotifierProvider(
        create: (_) => SleepProvider(service: FakeSleepService()),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  testWidgets('Home "Chơi": one tap sends the invite, no rule sheet', (
    tester,
  ) async {
    final service = _FakeService();
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(
      app(
        caro,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => quickStartCaroGame(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump();
    // No saved rule here → "Chặn hai đầu", first stone in the centre.
    expect(service.calls.single, {'op': 'start', 'rule': 'vn', 'cell': 112});
    expect(find.byType(CaroNewGameSheet), findsNothing);
    // The fake refuses → a snackbar says why.
    expect(find.text(vi.caroSendError), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  testWidgets('360×640, text ×1.3: waiting screen lays out without overflow', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final service = _FakeService();
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(app(caro, const CaroGameScreen(gameId: 'g1')));
    await tester.pump();
    service
        .stream('g1')
        .add(
          g(
            turn: 'bob',
            cells: [112, 113],
            x: 'bob',
            o: 'me',
            lastMoveBy: 'me',
          ),
        );
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(vi.caroWaiting('Người ấy')), findsOneWidget);
    expect(find.text(vi.caroResign), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  testWidgets('result + history screens render (empty history)', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
    final service = _FakeService();
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(app(caro, const CaroGameScreen(gameId: 'g1')));
    await tester.pump();
    service
        .stream('g1')
        .add(
          g(
            status: 'finished',
            cells: [112, 0, 113, 1, 114, 2, 115, 3, 116],
            x: 'me',
            o: 'bob',
            createdBy: 'me',
            finishedAt: now,
            result: {
              'winnerUid': 'me',
              'reason': 'five',
              'line': [112, 113, 114, 115, 116],
            },
          ),
        );
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroYouWon), findsOneWidget);
    expect(find.text(vi.caroCtaNewGame), findsOneWidget);
    expect(find.text(vi.caroLanePlusOne), findsOneWidget);

    await tester.tap(find.text(vi.caroSeeHistory));
    await tester.pumpAndSettle();
    expect(find.text(vi.caroHistoryEmpty), findsOneWidget);
    expect(find.text(vi.caroStartWith('Người ấy')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  // ---- review UI 2026-10-20 ------------------------------------------------

  void mockNet(WidgetTester tester) =>
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
        MockStreamHandler.inline(onListen: (_, _) {}),
      );

  void small(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<(CaroGameProvider, _FakeService)> openGame(
    WidgetTester tester,
    CaroGame game, {
    bool smallScreen = false,
  }) async {
    mockNet(tester);
    if (smallScreen) small(tester);
    final service = _FakeService();
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(app(caro, CaroGameScreen(gameId: game.id)));
    await tester.pump();
    service.stream(game.id).add(game);
    await tester.pump();
    await tester.pump();
    return (caro, service);
  }

  testWidgets('#1 open then pop the game screen: no locked-tree notify', (
    tester,
  ) async {
    mockNet(tester);
    final service = _FakeService();
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(
      app(
        caro,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CaroGameScreen(gameId: 'g1'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // route in
    service.stream('g1').add(g());
    await tester.pump();
    expect(caro.currentGameId, 'g1');
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // route out + dispose
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(caro.currentGameId, isNull);
    caro.dispose();
  });

  testWidgets('#2 new-game sheet scrolls on 360×640 ×1.3', (tester) async {
    small(tester);
    final caro = CaroGameProvider(service: _FakeService())
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(
      app(
        caro,
        Builder(
          builder: (context) => Scaffold(
            body: CaroNewGameSheet(lastRule: null, hostContext: context),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  for (final (name, game) in <(String, CaroGame)>[
    ('invited', g()),
    (
      'stale, my turn',
      g(
        cells: [112, 113],
        turn: 'me',
        lastMoveAt: now.subtract(const Duration(days: 9)),
      ),
    ),
    (
      'finished',
      g(
        status: 'finished',
        cells: [112, 0, 113, 1, 114, 2, 115, 3, 116],
        finishedAt: now,
        result: {
          'winnerUid': 'bob',
          'reason': 'five',
          'line': [112, 113, 114, 115, 116],
        },
      ),
    ),
  ]) {
    testWidgets('#3 360×640 ×1.3 $name: no overflow', (tester) async {
      final (caro, _) = await openGame(tester, game, smallScreen: true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      caro.dispose();
    });
  }

  testWidgets('#4 a refused resign says why instead of closing silently', (
    tester,
  ) async {
    final (caro, service) = await openGame(
      tester,
      g(cells: [112, 113, 114], turn: 'bob'),
    );
    await tester.tap(find.text(vi.caroResign));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, vi.caroResign));
    await tester.pumpAndSettle();
    expect(service.calls.last['op'], 'resign');
    expect(find.text(vi.caroActionError), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  testWidgets('#4 nudge cooldown from the server shows the wait', (
    tester,
  ) async {
    final (caro, service) = await openGame(
      tester,
      g(
        cells: [112, 113, 114],
        turn: 'bob',
        lastMoveAt: now.subtract(const Duration(hours: 2)),
      ),
    );
    service.reply = const CaroActionResult(
      CaroActionStatus.cooldown,
      retryAfter: Duration(minutes: 12),
    );
    await tester.tap(find.text(vi.caroNudge('Người ấy')));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroNudgeIn(12)), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  testWidgets('#13 offline while moving → offline note, not the send error', (
    tester,
  ) async {
    final (caro, service) = await openGame(
      tester,
      g(lastMoveAt: DateTime.now()),
    );
    service.reply = const CaroActionResult(CaroActionStatus.network);
    final rect = tester.getRect(find.byType(InteractiveViewer));
    final target = rect.center + Offset(rect.width / CaroBoard.size * 1.6, 0);
    await tester.tapAt(target);
    await tester.pump();
    await tester.tap(find.text(vi.caroPlayHere));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroOffline), findsOneWidget);
    expect(find.text(vi.caroSendError), findsNothing);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  testWidgets('CARO-T1 a move that landed despite the error clears the note', (
    tester,
  ) async {
    final (caro, service) = await openGame(
      tester,
      g(lastMoveAt: DateTime.now()),
    );
    service.reply = const CaroActionResult(CaroActionStatus.network);
    final rect = tester.getRect(find.byType(InteractiveViewer));
    final target = rect.center + Offset(rect.width / CaroBoard.size * 1.6, 0);
    await tester.tapAt(target);
    await tester.pump();
    await tester.tap(find.text(vi.caroPlayHere));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroOffline), findsOneWidget);
    // The callable timed out but the server wrote the move.
    service
        .stream('g1')
        .add(
          g(
            cells: const [112, 113],
            turn: 'bob',
            lastMoveBy: 'me',
            lastMoveAt: DateTime.now(),
          ),
        );
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroOffline), findsNothing);
    expect(find.text(vi.caroSendError), findsNothing);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  testWidgets('CARO-T1 the game ending clears an action note', (tester) async {
    final (caro, service) = await openGame(
      tester,
      g(lastMoveAt: DateTime.now()),
    );
    service.reply = const CaroActionResult(CaroActionStatus.network);
    final rect = tester.getRect(find.byType(InteractiveViewer));
    final target = rect.center + Offset(rect.width / CaroBoard.size * 1.6, 0);
    await tester.tapAt(target);
    await tester.pump();
    await tester.tap(find.text(vi.caroPlayHere));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroOffline), findsOneWidget);
    service.stream('g1').add(g(status: 'cancelled'));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroOffline), findsNothing);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  test('CARO-T2 foreground banners: one id per caro game', () {
    final a = foregroundBannerId(
      {'type': 'caro_turn', 'gameId': 'g1'},
      'm1',
      1,
    );
    final b = foregroundBannerId(
      {'type': 'caro_nudge', 'gameId': 'g1'},
      'm2',
      2,
    );
    final c = foregroundBannerId(
      {'type': 'caro_turn', 'gameId': 'g2'},
      'm1',
      1,
    );
    expect(a, b);
    expect(a, isNot(c));
    expect(a, inInclusiveRange(0, 0x7FFFFFFF));
    expect(
      foregroundBannerId({'type': 'chat_message'}, 'm1', 1),
      isNot(foregroundBannerId({'type': 'chat_message'}, 'm1', 2)),
    );
  });

  test('CARO-T5 caro_game_ended comes from the phone that ended the game', () {
    CaroGame ended(
      String status, {
      String? endedBy,
      String? by,
      Map<String, Object?>? result,
    }) => CaroGame.fromFirestore('g', <String, dynamic>{
      'type': 'caro',
      'players': {'x': 'bob', 'o': 'me'},
      'status': status,
      'cells': const [1, 2],
      'endedBy': ?endedBy,
      'lastMoveBy': ?by,
      'result': ?result,
    });
    final five = {'winnerUid': 'me', 'reason': 'five', 'line': <int>[]};
    expect(caroEndedBy(ended('finished', by: 'me', result: five)), 'me');
    expect(
      caroEndedBy(ended('finished', endedBy: 'bob', by: 'me', result: five)),
      'bob',
    );
    expect(caroEndedBy(ended('cancelled', endedBy: 'bob', by: 'bob')), 'bob');
    expect(caroEndedBy(ended('expired', endedBy: 'me', by: 'bob')), 'me');
    // Expired by the server (a partner left): nobody logs it.
    expect(caroEndedBy(ended('expired', by: 'bob')), isNull);
  });

  testWidgets('#5 an invite 3 days old says its date, not "hôm qua"', (
    tester,
  ) async {
    final created = DateTime.now().subtract(const Duration(days: 3));
    final (caro, _) = await openGame(
      tester,
      g(
        createdBy: 'me',
        x: 'me',
        o: 'bob',
        turn: 'bob',
        createdAt: created,
        lastMoveAt: created,
      ),
    );
    final day =
        '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')}';
    expect(find.textContaining('ngày $day'), findsOneWidget);
    expect(find.textContaining('hôm qua'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  test('#8 semantics rebuild only when tappability changes', () {
    CaroBoardPainter p(bool canPlace) => CaroBoardPainter(
      board: CaroBoard(const [112]),
      colorX: Colors.pink,
      colorO: Colors.teal,
      semanticsLabelOf: (i) => '$i',
      semanticsTapOf: (i) => canPlace ? () {} : null,
      semanticsCanPlace: canPlace,
    );
    expect(p(true).shouldRebuildSemantics(p(true)), false);
    expect(p(true).shouldRebuildSemantics(p(false)), true);
  });

  test('#9 English plurals for hours / minutes', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.caroSpanHours(1), '1 hour');
    expect(en.caroSpanHours(3), '3 hours');
    expect(en.caroSpanMinutes(1), '1 minute');
    expect(en.caroNudgeIn(1), 'You can nudge in 1 minute');
    expect(en.caroWaitedMin('4', '10:00', 2), contains('2 minutes ago'));
    expect(vi.caroSpanHours(1), '1 giờ');
  });

  testWidgets('#11 first page fails → only the error card', (tester) async {
    mockNet(tester);
    final service = _FakeService()
      ..page = const CaroHistoryPage.empty(failed: true);
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(app(caro, const CaroHistoryScreen()));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroHistoryPageError), findsOneWidget);
    expect(find.text(vi.caroHistoryEmpty), findsNothing);
    expect(find.byType(ShimmerSkeleton), findsNothing);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });

  test('#6 state stream error → Home "Thử lại", retry re-subscribes', () async {
    final service = _FakeService();
    final p = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    service.state.addError(Exception('permission-denied'));
    await tick();
    expect(p.stateFailed, true);
    expect(
      caroEntryKindFor(
        loaded: p.isStateLoaded,
        failed: p.stateFailed,
        open: null,
        last: null,
        myUid: 'me',
        partnerUid: 'bob',
        total: 0,
        now: now,
      ),
      CaroEntryKind.error,
    );
    p.retryState();
    expect(p.stateFailed, false);
    service.state.add(CaroState.empty);
    await tick();
    expect(p.isStateLoaded, true);
    p.dispose();
  });

  test('#7 enter() before the couple is wired waits, then enters', () async {
    final p = CaroGameProvider(service: _FakeService());
    p.enter('g9');
    expect(p.currentGameId, isNull);
    p.watchForCouple('c', 'me', 'bob');
    expect(p.currentGameId, 'g9');
    p.dispose();
  });

  group('provider follow-ups (review 2026-10-20)', () {
    test(
      'on the result of G1, the partner’s rematch opens by itself',
      () async {
        final service = _FakeService();
        final p = CaroGameProvider(service: service)
          ..watchForCouple('c', 'me', 'bob');
        p.enter('g1');
        await tick();
        service
            .stream('g1')
            .add(
              g(
                status: 'finished',
                result: {
                  'winnerUid': 'me',
                  'reason': 'five',
                  'line': const <int>[],
                },
              ),
            );
        await tick();
        service.state.add(const CaroState(openGameId: 'g2'));
        await tick();
        service.stream('g2').add(g(id: 'g2', rematchOf: 'g1'));
        await tick();
        expect(p.currentGameId, 'g2');
        p.dispose();
      },
    );

    test('clear() resets a paused heartbeat', () {
      final p = CaroGameProvider(service: _FakeService())
        ..watchForCouple('c', 'me', 'bob');
      p.pauseHeartbeat();
      expect(p.isHeartbeatPaused, true);
      p.clear();
      expect(p.isHeartbeatPaused, false);
      p.dispose();
    });
  });
}
