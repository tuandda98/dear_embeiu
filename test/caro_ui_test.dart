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
    return const CaroActionResult(CaroActionStatus.failed);
  }

  @override
  Future<CaroHistoryPage> fetchHistoryPage({
    required String coupleId,
    int limit = 30,
    dynamic startAfter,
  }) async => const CaroHistoryPage.empty();
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
      expect(vi.caroNotifInvite('Thảo'), 'Thảo rủ chơi cờ caro');
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
      expect(
        HomeWidgetStatus.fromPush(
          {'type': 'caro_result', 'actorName': 'Thảo'},
          l10n: vi,
          now: now,
        ),
        isNull,
      );
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
      expect(view(CaroEntryKind.justLost).cta, 'Phục thù');
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

  testWidgets('game screen: tap a square twice (≥400 ms) sends the move', (
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
    expect(find.text(vi.caroPickCell), findsOneWidget);
    expect(find.text(vi.caroLater), findsOneWidget); // ≤1 stone: "Để sau"

    // Opened at 1.6× around the last move (7,7): (7,8) sits 1.6 cells right.
    final rect = tester.getRect(find.byType(InteractiveViewer));
    final cell = rect.width / CaroBoard.size;
    final target = rect.center + Offset(cell * 1.6, 0);
    await tester.tapAt(target);
    await tester.pump();
    expect(find.text(vi.caroPlayHere), findsOneWidget);
    expect(service.calls, isEmpty);
    await tester.tapAt(target); // too fast: ignored
    await tester.pump();
    expect(service.calls, isEmpty);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 450)),
    );
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
    service.stream('g1').add(
      g(turn: 'bob', cells: [112, 113], x: 'bob', o: 'me', lastMoveBy: 'me'),
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
    service.stream('g1').add(
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
