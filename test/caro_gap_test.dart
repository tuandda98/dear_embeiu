import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/data/feature_tour_entries.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/caro_game.dart';
import 'package:dear_embeiu/providers/caro_game_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/screens/caro_game_screen.dart';
import 'package:dear_embeiu/screens/caro_history_screen.dart';
import 'package:dear_embeiu/services/caro_game_service.dart';
import 'package:dear_embeiu/widgets/caro/caro_board.dart';
import 'package:dear_embeiu/widgets/caro/caro_common.dart';
import 'package:dear_embeiu/widgets/caro/caro_new_game_sheet.dart';
import 'package:dear_embeiu/widgets/play_together_card.dart';
import 'package:dear_embeiu/widgets/shimmer_skeleton.dart';

import 'sleep_provider_test.dart' show FakeSleepService;

/// Gap tests for caro-game (project/features/caro-game/test-cases.md rows that
/// were "chưa phủ → đề xuất unit"). Same fake-service idiom as caro_ui_test.

CaroGame g({
  String id = 'g1',
  List<int> cells = const [112],
  String status = 'playing',
  String turn = 'me',
  String createdBy = 'bob',
  String x = 'bob',
  String o = 'me',
  String rule = 'vn',
  DateTime? lastMoveAt,
  DateTime? createdAt,
  DateTime? finishedAt,
  Map<String, Object?>? result,
  Map<String, Object?> presence = const {},
  Map<String, Object?> extra = const {},
}) => CaroGame.fromFirestore(id, <String, dynamic>{
  'type': 'caro',
  'rule': rule,
  'createdBy': createdBy,
  'players': {'x': x, 'o': o},
  'status': status,
  'cells': cells,
  'turnUid': turn,
  'lastMoveAt': lastMoveAt ?? DateTime.now().subtract(const Duration(minutes: 5)),
  'createdAt': createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
  'finishedAt': ?finishedAt,
  'result': ?result,
  'presence': presence,
  ...extra,
});

CaroGame done(
  String? winner, {
  String reason = 'five',
  DateTime? at,
  String rule = 'vn',
  List<int> cells = const [112, 0, 113, 1, 114, 2, 115, 3, 116],
  String? endedBy,
  String id = 'h1',
}) => g(
  id: id,
  status: 'finished',
  cells: cells,
  rule: rule,
  finishedAt: at ?? DateTime.now(),
  result: {'winnerUid': winner ?? '', 'reason': reason, 'line': const <int>[]},
  extra: {'endedBy': ?endedBy},
);

class _Svc extends CaroGameService {
  final state = StreamController<CaroState>.broadcast();
  final games = <String, StreamController<CaroGame?>>{};
  final calls = <Map<String, Object?>>[];
  final pageCalls = <int>[];
  CaroActionResult reply = const CaroActionResult(CaroActionStatus.failed);
  Completer<CaroActionResult>? hold;
  final pages = <CaroHistoryPage>[];

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
  Future<bool> heartbeat(String c, String gameId, String uid) async => true;
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
  }) {
    calls.add({'op': op, 'cell': cell, 'moveNo': moveNo});
    return hold?.future ?? Future.value(reply);
  }

  @override
  Future<CaroHistoryPage> fetchHistoryPage({
    required String coupleId,
    int limit = 30,
    dynamic startAfter,
  }) async {
    // limit 1 = the provider's own "last finished game" read.
    if (limit == 1) return const CaroHistoryPage.empty();
    pageCalls.add(limit);
    return pages.isEmpty ? const CaroHistoryPage.empty() : pages.removeAt(0);
  }
}

Widget app(CaroGameProvider caro, Widget home, {Locale locale = const Locale('vi')}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CaroGameProvider>.value(value: caro),
        ChangeNotifierProvider(create: (_) => CoupleProvider()),
        ChangeNotifierProvider(
          create: (_) => SleepProvider(service: FakeSleepService()),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

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

Future<(CaroGameProvider, _Svc)> openGame(
  WidgetTester tester,
  CaroGame game, {
  bool smallScreen = false,
}) async {
  mockNet(tester);
  if (smallScreen) small(tester);
  final service = _Svc();
  final caro = CaroGameProvider(service: service)
    ..watchForCouple('c', 'me', 'bob');
  await tester.pumpWidget(app(caro, CaroGameScreen(gameId: game.id)));
  await tester.pump();
  service.stream(game.id).add(game);
  await tester.pump();
  await tester.pump();
  return (caro, service);
}

Future<void> dispose(WidgetTester tester, CaroGameProvider caro) async {
  await tester.pumpWidget(const SizedBox());
  caro.dispose();
}

Offset cellRight(WidgetTester tester) {
  final rect = tester.getRect(find.byType(InteractiveViewer));
  return rect.center + Offset(rect.width / CaroBoard.size * 1.6, 0);
}

String hm(DateTime at) => DateFormat.Hm('vi').format(at);

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));

  // ---- HOME ---------------------------------------------------------------

  test('HOME-13 score with draws appends ", N ván hoà"', () {
    final score = vi.caroScore('Tuấn', '12', '9', 'Thảo');
    final withDraws = vi.caroScoreDraws(score, '2');
    expect(withDraws, 'Tuấn 12 – 9 Thảo, 2 ván hoà');
    final view = caroEntryView(
      vi,
      CaroEntryKind.idle,
      partnerName: 'Thảo',
      score: withDraws,
      moves: '0',
      time: '',
      staleDays: '0',
    );
    expect(view.subtitle, contains(', 2 ván hoà'));
  });

  testWidgets('HOME-15 loading line: shimmer, no copy, no CTA', (tester) async {
    final view = caroEntryView(
      vi,
      CaroEntryKind.loading,
      partnerName: 'Thảo',
      score: '',
      moves: '0',
      time: '',
      staleDays: '0',
    );
    expect(view.loading, true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaroEntryRow(
            view: view,
            badge: const CaroGlyph(
              mine: Colors.pink,
              partner: Colors.teal,
              showDot: false,
            ),
            onTap: null,
          ),
        ),
      ),
    );
    expect(find.byType(ShimmerSkeleton), findsNWidgets(2));
    expect(find.text(vi.caroCtaInvite), findsNothing);
    expect(find.text(vi.caroCtaJoin), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('HOME-18 partner joins mid-session: same stream, partner arrives', () async {
    final service = _Svc();
    final p = CaroGameProvider(service: service)..watchForCouple('c', 'me', '');
    expect(p.hasPartner, false);
    expect(
      (await p.start()).status,
      CaroActionStatus.noPartner,
      reason: 'no partner yet → no CF call',
    );
    expect(service.calls, isEmpty);
    var notified = 0;
    p.addListener(() => notified++);
    p.watchForCouple('c', 'me', 'bob'); // Home's re-arm after the join
    expect(p.hasPartner, true);
    expect(p.partnerUid, 'bob');
    expect(notified, 1);
    p.watchForCouple('c', 'me', 'bob'); // unchanged → no-op
    expect(notified, 1);
    p.dispose();
  });

  testWidgets('HOME-21 360×640, text ×1.3: the longest lines do not overflow', (
    tester,
  ) async {
    small(tester);
    for (final kind in CaroEntryKind.values) {
      final view = caroEntryView(
        vi,
        kind,
        partnerName: 'Nguyễn Thị Thảo Nguyên',
        score: vi.caroScoreDraws(
          vi.caroScore('Đỗ Đào Anh Tuấn', '128', '97', 'Nguyễn Thị Thảo Nguyên'),
          '14',
        ),
        moves: '224',
        time: '10:12',
        staleDays: '30',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaroEntryRow(
              view: view,
              badge: const CaroGlyph(
                mine: Colors.pink,
                partner: Colors.teal,
                showDot: true,
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '$kind');
      expect(
        tester.getSize(find.byType(InkWell).first).height,
        greaterThanOrEqualTo(68),
        reason: '$kind',
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  // ---- NEW ----------------------------------------------------------------

  Widget sheetHost(CaroGameProvider caro) => app(
    caro,
    Builder(
      builder: (context) => Scaffold(
        body: CaroNewGameSheet(lastRule: null, hostContext: context),
      ),
    ),
  );

  testWidgets('NEW-07 offline on "Rủ": says so, the button works again', (
    tester,
  ) async {
    final service = _Svc()
      ..reply = const CaroActionResult(CaroActionStatus.network);
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(sheetHost(caro));
    await tester.pump();
    await tester.tap(find.text(vi.caroNewCta('Người ấy')));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroOffline), findsOneWidget);
    expect(find.text(vi.caroSendError), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    await tester.tap(find.text(vi.caroNewCta('Người ấy')));
    await tester.pump();
    expect(service.calls.map((c) => c['op']), ['start', 'start']);
    await dispose(tester, caro);
  });

  testWidgets('NEW-19 offline on "Rủ" in the draft: note, square kept, retry', (
    tester,
  ) async {
    mockNet(tester);
    final service = _Svc()
      ..reply = const CaroActionResult(CaroActionStatus.network);
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(
      app(caro, const CaroGameScreen(draftRule: CaroRule.vn)),
    );
    await tester.pump();
    await tester.pump();
    final rect = tester.getRect(find.byType(InteractiveViewer));
    await tester.tapAt(rect.center + const Offset(40, 40));
    await tester.pump();
    final invite = find.text(vi.caroInviteCta('Người ấy'));
    await tester.tap(invite);
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroOffline), findsOneWidget);
    // Selection kept: the invite pill is still there and works again.
    expect(invite, findsOneWidget);
    await tester.tap(invite);
    await tester.pump();
    await tester.pump();
    expect(service.calls.length, 2);
    expect(service.calls.last['cell'], service.calls.first['cell']);
    await dispose(tester, caro);
  });

  testWidgets('NEW-27 rule sheet: name, sentence and the example per rule', (
    tester,
  ) async {
    Future<void> open(CaroRule rule) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCaroRuleSheet(
                context,
                rule,
                colorX: Colors.pink,
                colorO: Colors.teal,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    await open(CaroRule.vn);
    expect(find.text(vi.caroRuleVn), findsOneWidget);
    expect(find.text(vi.caroRuleVnDesc), findsOneWidget);
    expect(find.text(vi.caroRuleExampleNoWin), findsOneWidget);
    expect(find.text(vi.caroRuleExampleWin), findsNothing);
    expect(find.byType(CaroRuleExample), findsOneWidget);
    await tester.tapAt(const Offset(5, 5)); // barrier closes the sheet
    await tester.pumpAndSettle();
    await open(CaroRule.free);
    expect(find.text(vi.caroRuleFree), findsOneWidget);
    expect(find.text(vi.caroRuleExampleWin), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  // ---- SCR ----------------------------------------------------------------

  testWidgets('SCR-02 no snapshot yet: "Đang tải ván", skeleton, no cell labels', (
    tester,
  ) async {
    mockNet(tester);
    final handle = tester.ensureSemantics();
    final service = _Svc();
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(app(caro, const CaroGameScreen(gameId: 'g1')));
    await tester.pump();
    expect(find.text(vi.caroLoading), findsOneWidget);
    expect(find.byType(ShimmerSkeleton), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('^Hàng ')), findsNothing);
    handle.dispose();
    await dispose(tester, caro);
  });

  testWidgets('SCR-07 waiting, partner watching: "… đang xem ván."', (
    tester,
  ) async {
    final moved = DateTime.now().subtract(const Duration(minutes: 3));
    final (caro, _) = await openGame(
      tester,
      g(
        cells: [112, 113],
        turn: 'bob',
        lastMoveAt: moved,
        presence: {'bob': DateTime.now()},
      ),
    );
    expect(
      find.text(vi.caroPartnerWatching('2', hm(moved), 'Người ấy')),
      findsOneWidget,
    );
    expect(find.textContaining('đang xem ván'), findsOneWidget);
    await dispose(tester, caro);
  });

  testWidgets('SCR-08 waiting long: "Đã nhắc … lúc" after a nudge, else "Đã M phút"', (
    tester,
  ) async {
    final moved = DateTime.now().subtract(const Duration(hours: 3));
    final nudged = DateTime.now().subtract(const Duration(minutes: 20));
    var (caro, _) = await openGame(
      tester,
      g(
        cells: [112, 113],
        turn: 'bob',
        lastMoveAt: moved,
        extra: {'lastNudgeAt': nudged},
      ),
    );
    expect(find.text(vi.caroNudged('Người ấy', hm(nudged))), findsOneWidget);
    await dispose(tester, caro);

    final moved2 = DateTime.now().subtract(const Duration(minutes: 45));
    (caro, _) = await openGame(
      tester,
      g(id: 'g2', cells: [112, 113], turn: 'bob', lastMoveAt: moved2),
    );
    expect(find.textContaining('phút rồi'), findsOneWidget);
    expect(find.textContaining('Đã nhắc'), findsNothing);
    await dispose(tester, caro);
  });

  testWidgets('SCR-12 + END-14 stale ≥ 7 days: Nhắc + Kết thúc ván → expire → "để lâu"', (
    tester,
  ) async {
    final (caro, service) = await openGame(
      tester,
      g(
        cells: [112, 113, 114],
        turn: 'bob',
        lastMoveAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    );
    expect(find.text(vi.caroNudge('Người ấy')), findsOneWidget);
    expect(find.text(vi.caroEndGame), findsOneWidget);
    service.reply = const CaroActionResult(CaroActionStatus.ok);
    await tester.tap(find.text(vi.caroEndGame));
    await tester.pumpAndSettle();
    expect(find.text(vi.caroEndTitle), findsOneWidget);
    expect(service.calls, isEmpty, reason: 'nothing before the confirmation');
    await tester.tap(find.widgetWithText(FilledButton, vi.caroEndConfirm));
    await tester.pumpAndSettle();
    expect(service.calls.single['op'], 'expire');
    // The server flips the game; the screen follows.
    service.stream('g1').add(g(status: 'expired'));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroExpiredTitle), findsOneWidget);
    await dispose(tester, caro);
  });

  testWidgets('SCR-15 full board: "Ván này hoà" + "Kín cả 225 ô…"', (tester) async {
    final (caro, _) = await openGame(tester, done(null, reason: 'full'));
    expect(find.text(vi.caroDraw), findsOneWidget);
    expect(find.text(vi.caroDrawSub), findsOneWidget);
    expect(find.text(vi.caroDraw), findsOneWidget);
    await dispose(tester, caro);
  });

  testWidgets('SCR-21 expired game: title + "7 ngày không ai đi…"', (tester) async {
    final (caro, _) = await openGame(tester, g(status: 'expired'));
    expect(find.text('Ván này đã kết thúc vì để lâu'), findsOneWidget);
    expect(find.textContaining('7 ngày không ai đi'), findsOneWidget);
    expect(find.text(vi.caroNewInviteCta('Người ấy')), findsOneWidget);
    await dispose(tester, caro);
  });

  testWidgets('SCR-25 held "Có gì mới"/catch-up key off CaroGameScreen.isOpen', (
    tester,
  ) async {
    // Home's own check (_rpsGameActive) is private to HomeScreen; what it
    // reads is this notifier, so the seam is covered here.
    expect(CaroGameScreen.isOpen, false);
    final (caro, _) = await openGame(tester, g());
    expect(CaroGameScreen.isOpen, true);
    await dispose(tester, caro);
    expect(CaroGameScreen.isOpen, false);
  });

  // ---- MOVE ---------------------------------------------------------------

  testWidgets('MOVE-15 + RACE-06 a move on a changed board: "Bàn vừa đổi", pick dropped', (
    tester,
  ) async {
    final (caro, service) = await openGame(tester, g(lastMoveAt: DateTime.now()));
    service.reply = const CaroActionResult(CaroActionStatus.stale);
    await tester.tapAt(cellRight(tester));
    await tester.pump();
    await tester.pump();
    expect(service.calls.single['op'], 'move');
    expect(find.text(vi.caroStaleBoard), findsOneWidget);
    expect(find.text(vi.caroSendError), findsNothing);
    expect(find.text(vi.caroPickCell), findsOneWidget); // selection cleared
    // notYourTurn / occupied read the same way.
    service.reply = const CaroActionResult(CaroActionStatus.notYourTurn);
    await tester.tapAt(cellRight(tester));
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.caroStaleBoard), findsOneWidget);
    await dispose(tester, caro);
  });

  testWidgets('MOVE-16 a second tap while the move is in flight sends nothing', (
    tester,
  ) async {
    final (caro, service) = await openGame(tester, g(lastMoveAt: DateTime.now()));
    service.hold = Completer<CaroActionResult>();
    await tester.tapAt(cellRight(tester));
    await tester.pump();
    expect(caro.isBusy, true);
    expect(find.text(vi.caroSending), findsOneWidget);
    await tester.tapAt(cellRight(tester) + const Offset(30, 30));
    await tester.pump();
    expect(service.calls.length, 1);
    service.hold!.complete(const CaroActionResult(CaroActionStatus.ok));
    await tester.pump();
    await tester.pump();
    expect(caro.isBusy, false);
    await dispose(tester, caro);
  });

  test('MOVE-16 provider: move() while busy is refused without a call', () async {
    final service = _Svc();
    final p = CaroGameProvider(service: service)..watchForCouple('c', 'me', 'bob');
    p.enter('g1');
    service.stream('g1').add(g());
    await Future<void>.delayed(Duration.zero);
    service.hold = Completer<CaroActionResult>();
    final first = p.move(113);
    final second = await p.move(114);
    expect(second.status, CaroActionStatus.notYourTurn);
    expect(service.calls.length, 1);
    service.hold!.complete(const CaroActionResult(CaroActionStatus.ok));
    await first;
    p.dispose();
  });

  test('MOVE-21 + SEC-36 caro analytics carry only counts / enums / bools', () {
    final src = File('lib/services/analytics_service.dart').readAsStringSync();
    final from = src.indexOf('void logCaroOpen');
    final to = src.indexOf('void logCaroHistoryOpen');
    expect(from, greaterThan(0));
    final block = src.substring(from, to);
    final keys = RegExp(r'AnalyticsEvents\.(p\w+)')
        .allMatches(block)
        .map((m) => m.group(1))
        .toSet();
    expect(keys, {
      'pSource',
      'pRematch',
      'pCaroRule',
      'pMoveNo',
      'pPartnerWatching',
      'pResult',
      'pMoves',
      'pSpanHours',
    });
    // Parameters of the log methods: no uid / name / cell / game id.
    final params = RegExp(r'void logCaro\w+\(([^)]*)\)')
        .allMatches(block)
        .map((m) => m.group(1)!)
        .join(',')
        .toLowerCase();
    for (final banned in ['uid', 'name', 'cell', 'gameid', 'email']) {
      expect(params, isNot(contains(banned)), reason: banned);
    }
    // The move event is fed by the count and the presence flag only.
    final screen = File('lib/screens/caro_game_screen.dart').readAsStringSync();
    final move = RegExp(r'logCaroMove\(([^)]*)\)').firstMatch(screen)!.group(1)!;
    expect(move, contains('moveNo:'));
    expect(move, contains('partnerWatching:'));
    expect(
      move.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).map((a) => a.split(':').first),
      ['moveNo', 'partnerWatching'],
    );
  });

  // ---- HIST / RS ----------------------------------------------------------

  Future<(CaroGameProvider, _Svc)> history(
    WidgetTester tester,
    List<CaroGame> items, {
    bool hasMore = false,
    CaroState? state,
    Locale locale = const Locale('vi'),
  }) async {
    mockNet(tester);
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _Svc()..pages.add(CaroHistoryPage(items: items, hasMore: hasMore));
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    service.state.add(
      state ?? CaroState(wins: {'me': items.length}, draws: 0),
    );
    await tester.pumpWidget(app(caro, const CaroHistoryScreen(), locale: locale));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return (caro, service);
  }

  testWidgets('HIST-07/08 + RS-06 rows: resign, full board, Tự do suffix', (
    tester,
  ) async {
    final (caro, _) = await history(tester, [
      done('me', reason: 'resign', endedBy: 'bob', id: 'a'),
      done(null, reason: 'full', id: 'b'),
      done('me', rule: 'free', id: 'c'),
    ]);
    expect(find.text('Mình thắng'), findsNWidgets(2));
    expect(find.text('Người ấy xin thua ở nước 9'), findsOneWidget);
    expect(find.text(vi.caroRowDraw), findsOneWidget);
    expect(find.text('Kín bàn, 225 nước'), findsOneWidget);
    expect(find.text('Năm quân liền, 9 nước. Tự do'), findsOneWidget);
    expect(find.text(vi.caroRowFive('9')), findsNothing); // the free row has the suffix
    await dispose(tester, caro);
  });

  testWidgets('HIST-12 month headers: header semantics, year only when not this year', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1, 0, 1);
    final lastYear = DateTime(now.year - 1, 5, 10, 9);
    final (caro, _) = await history(tester, [
      done('me', at: thisMonth, id: 'a'),
      done('bob', at: lastYear, id: 'b'),
    ]);
    String sentence(String s) => toBeginningOfSentenceCase(s)!;
    final cur = sentence(DateFormat.MMMM('vi').format(thisMonth));
    final old = sentence(DateFormat.yMMMM('vi').format(lastYear));
    expect(cur, isNot(contains('${now.year}')));
    expect(old, contains('${now.year - 1}'));
    for (final title in [cur, old]) {
      expect(find.text(title), findsOneWidget);
      expect(
        tester.getSemantics(find.text(title)),
        isSemantics(isHeader: true),
        reason: title,
      );
    }
    handle.dispose();
    await dispose(tester, caro);
  });

  testWidgets('HIST-13 "từ {ngày}" only once every page is in', (tester) async {
    final first = DateTime.now().subtract(const Duration(days: 5));
    final games = [
      done('me', at: DateTime.now(), id: 'a'),
      done('bob', at: first, id: 'b'),
    ];
    final st = CaroState(wins: {'me': 1, 'bob': 1});
    var (caro, _) = await history(tester, games, hasMore: true, state: st);
    expect(
      find.text(vi.caroHistorySubNoSince('2', 'Mình', vi.caroWhenToday)),
      findsOneWidget,
    );
    expect(find.textContaining(' từ '), findsNothing);
    await dispose(tester, caro);

    (caro, _) = await history(tester, games, hasMore: false, state: st);
    final since = DateFormat('dd/MM', 'vi').format(first);
    expect(
      find.text(vi.caroHistorySub('2', since, 'Mình', vi.caroWhenToday)),
      findsOneWidget,
    );
    await dispose(tester, caro);
  });

  testWidgets('HIST-14 score line: who leads, or "Đang hoà a – a"', (tester) async {
    var (caro, _) = await history(
      tester,
      const [],
      state: CaroState(wins: {'me': 3, 'bob': 1}),
    );
    expect(find.text(vi.caroLeads('Mình', '2')), findsOneWidget);
    await dispose(tester, caro);
    (caro, _) = await history(
      tester,
      const [],
      state: CaroState(wins: {'me': 2, 'bob': 2}),
    );
    expect(find.text('Đang hoà 2 – 2'), findsOneWidget);
    await dispose(tester, caro);
    expect(vi.caroLeads('Thảo', '4'), 'Thảo dẫn trước 4 ván');
    expect(en.caroTied('3'), contains('3'));
  });

  testWidgets('HIST-11 a failing next page keeps the rows and offers a retry', (
    tester,
  ) async {
    final (caro, service) = await history(
      tester,
      [done('me', id: 'a'), done('bob', id: 'b')],
      hasMore: true,
    );
    service.pages.add(const CaroHistoryPage.empty(failed: true));
    caro.loadMoreHistory();
    await tester.pump();
    await tester.pump();
    expect(caro.historyFailed, true);
    expect(caro.history.length, 2);
    expect(find.text(vi.caroHistoryPageError), findsOneWidget);
    expect(find.text(vi.caroCtaRetry), findsOneWidget);
    expect(find.text('Mình thắng'), findsOneWidget); // rows kept
    await dispose(tester, caro);
  });

  test('HIST-09 history pages are 30 long and stop when there are no more', () async {
    final service = _Svc();
    final p = CaroGameProvider(service: service)..watchForCouple('c', 'me', 'bob');
    service.pages
      ..add(CaroHistoryPage(items: [for (var i = 0; i < 30; i++) done('me', id: 'a$i')], hasMore: true))
      ..add(CaroHistoryPage(items: [done('bob', id: 'z')]));
    await p.loadHistory();
    expect(service.pageCalls, [30]);
    expect(p.history.length, 30);
    expect(p.hasMoreHistory, true);
    await p.loadMoreHistory();
    expect(service.pageCalls, [30, 30]);
    expect(p.history.length, 31);
    expect(p.hasMoreHistory, false);
    await p.loadMoreHistory(); // nothing left → no third read
    expect(service.pageCalls.length, 2);
    p.dispose();
  });

  test('HIST-17 profile value "a – b" and the spoken form names both', () {
    expect(vi.caroScorePair('12', '9'), '12 – 9');
    expect(vi.caroScore('Mình', '12', '9', 'Người ấy'), 'Mình 12 – 9 Người ấy');
  });

  testWidgets('RS-05 rule chip: vi/en name and "chạm để xem giải thích" label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    expect(caroRuleName(vi, CaroRule.vn), 'Chặn hai đầu');
    expect(caroRuleName(vi, CaroRule.free), 'Tự do');
    expect(caroRuleName(en, CaroRule.vn), isNot(caroRuleName(vi, CaroRule.vn)));
    final (caro, _) = await openGame(tester, g(rule: 'free'));
    expect(
      find.bySemanticsLabel(RegExp('Luật Tự do, chạm để xem giải thích')),
      findsWidgets,
    );
    await tester.tap(find.text('Tự do').first);
    await tester.pumpAndSettle();
    expect(find.text(vi.caroRuleExampleWin), findsOneWidget);
    handle.dispose();
    await dispose(tester, caro);
  });

  // ---- RACE / I18N --------------------------------------------------------

  testWidgets('RACE-12 my invite unseen for 24 h: "app của X cần cập nhật"', (
    tester,
  ) async {
    CaroGame invite(Duration age) => g(
      createdBy: 'me',
      x: 'me',
      o: 'bob',
      turn: 'bob',
      createdAt: DateTime.now().subtract(age),
      lastMoveAt: DateTime.now().subtract(age),
    );
    var (caro, _) = await openGame(tester, invite(const Duration(hours: 25)));
    expect(find.text(vi.caroOldAppHint('Người ấy')), findsOneWidget);
    await dispose(tester, caro);
    (caro, _) = await openGame(tester, invite(const Duration(hours: 23)));
    expect(find.text(vi.caroOldAppHint('Người ấy')), findsNothing);
    await dispose(tester, caro);
  });

  test('I18N-03 ARB parity: every caro* key in vi and en, same placeholders', () {
    Map<String, String> caroKeys(String path) {
      final out = <String, String>{};
      final re = RegExp(r'^  "(caro\w*)": "((?:[^"\\]|\\.)*)"', multiLine: true);
      for (final m in re.allMatches(File(path).readAsStringSync())) {
        out[m.group(1)!] = m.group(2)!;
      }
      return out;
    }

    final viKeys = caroKeys('lib/l10n/app_vi.arb');
    final enKeys = caroKeys('lib/l10n/app_en.arb');
    expect(viKeys.length, greaterThanOrEqualTo(138));
    expect(enKeys.keys.toSet(), viKeys.keys.toSet());
    final ph = RegExp(r'\{(\w+)\}');
    for (final k in viKeys.keys) {
      Set<String> holes(String s) => ph.allMatches(s).map((m) => m.group(1)!).toSet();
      expect(holes(enKeys[k]!), holes(viKeys[k]!), reason: k);
    }
  });

  testWidgets('I18N-05 dates read dd/MM in both locales; times are 24-hour', (
    tester,
  ) async {
    final old = DateTime.now().subtract(const Duration(days: 9));
    final label = DateFormat('dd/MM').format(old);
    for (final locale in [const Locale('vi'), const Locale('en')]) {
      final (caro, _) = await history(
        tester,
        [done('me', at: old, id: 'a')],
        locale: locale,
      );
      expect(find.text(label), findsOneWidget, reason: '$locale');
      await dispose(tester, caro);
    }
    expect(vi.caroWhenOn('17/10'), 'ngày 17/10');
    expect(en.caroWhenOn('17/10'), contains('17/10'));
    expect(DateFormat.Hm('en').format(DateTime(2026, 10, 20, 15, 5)), '15:05');
  });

  testWidgets('I18N-08 a board square tapped through semantics plays like a finger', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final (caro, service) = await openGame(tester, g(lastMoveAt: DateTime.now()));
    service.reply = const CaroActionResult(CaroActionStatus.ok);
    final empty = find.semantics.byLabel(vi.caroCellEmpty('8', '9'));
    expect(empty, findsOneWidget);
    expect(
      empty.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap),
      true,
    );
    tester.semantics.tap(empty);
    await tester.pump();
    await tester.pump();
    expect(service.calls.single, {'op': 'move', 'cell': 113, 'moveNo': 1});
    handle.dispose();
    await dispose(tester, caro);
  });

  testWidgets('I18N-13 touch targets: pill 52, zoom 52, Home line ≥ 68', (
    tester,
  ) async {
    final (caro, _) = await openGame(tester, g());
    final pill = find.ancestor(
      of: find.text(vi.caroPickCell),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(pill.first).height, 52);
    expect(tester.getSize(find.byTooltip(vi.caroZoomOut)).shortestSide, 52);
    await dispose(tester, caro);
  });

  test('I18N-14 the tour announces caro since build 33 and opens it', () {
    final entry = featureTourEntries.singleWhere(
      (e) => e.title(vi) == vi.caroTourTitle,
    );
    expect(entry.sinceBuild, 33);
    expect(entry.title(vi), 'Cờ caro theo lượt');
    expect(entry.body(en), en.caroTourBody);
    expect(entry.onOpen, isNotNull);
  });

  testWidgets('I18N-14 tapping the tour row opens the open caro game', (
    tester,
  ) async {
    mockNet(tester);
    final service = _Svc();
    final caro = CaroGameProvider(service: service)
      ..watchForCouple('c', 'me', 'bob');
    await tester.pumpWidget(
      app(
        caro,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => featureTourEntries
                .singleWhere((e) => e.title(vi) == vi.caroTourTitle)
                .onOpen!(context),
            child: const Text('tour'),
          ),
        ),
      ),
    );
    await tester.pump();
    service.state.add(const CaroState(openGameId: 'g1'));
    await tester.pump();
    service.stream('g1').add(g());
    await tester.pump();
    await tester.tap(find.text('tour'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CaroGameScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    caro.dispose();
  });
}
