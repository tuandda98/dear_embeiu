import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/caro_game.dart';
import 'package:dear_embeiu/providers/caro_game_provider.dart';
import 'package:dear_embeiu/services/caro_game_service.dart';

int at(int r, int c) => CaroBoard.indexOf(r, c);
List<int> row(int r, List<int> cols) => [for (final c in cols) at(r, c)];

/// X and O stones interleaved into play order (X first).
List<int> seq(List<int> xs, List<int> os) {
  final out = <int>[];
  for (var i = 0; i < xs.length || i < os.length; i++) {
    if (i < xs.length) out.add(xs[i]);
    if (i < os.length) out.add(os[i]);
  }
  return out;
}

CaroGame game({
  List<int>? cells,
  String status = 'playing',
  String turn = 'bob',
  DateTime? lastMoveAt,
  DateTime? lastNudgeAt,
  Map<String, Object?> extra = const {},
}) => CaroGame.fromFirestore('k1', <String, dynamic>{
  'type': 'caro',
  'rule': 'vn',
  'size': 15,
  'createdBy': 'alice',
  'players': {'x': 'alice', 'o': 'bob'},
  'status': status,
  'cells': cells ?? [at(7, 7)],
  'turnUid': turn,
  'lastMoveAt': ?lastMoveAt,
  'lastNudgeAt': ?lastNudgeAt,
  ...extra,
});

class _FakeCaroService extends CaroGameService {
  final state = StreamController<CaroState>.broadcast();
  final games = <String, StreamController<CaroGame?>>{};
  final log = <String>[];
  final calls = <Map<String, Object?>>[];
  Completer<CaroActionResult>? next;
  CaroHistoryPage page = const CaroHistoryPage.empty();

  StreamController<CaroGame?> gameStream(String id) =>
      games.putIfAbsent(id, () => StreamController<CaroGame?>.broadcast());

  @override
  bool get isUsingFirebase => true;

  @override
  Stream<CaroState> watchState(String coupleId) => state.stream;

  @override
  Stream<CaroGame?> watchGame(String coupleId, String gameId) =>
      gameStream(gameId).stream;

  @override
  Future<bool> heartbeat(String coupleId, String gameId, String uid) async {
    log.add('beat:$gameId');
    return true;
  }

  @override
  Future<bool> clearPresence(String coupleId, String gameId, String uid) async {
    log.add('clear:$gameId');
    return true;
  }

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
    calls.add({'op': op, 'gameId': gameId, 'cell': cell, 'moveNo': moveNo});
    next = Completer<CaroActionResult>();
    return next!.future;
  }

  @override
  Future<CaroHistoryPage> fetchHistoryPage({
    required String coupleId,
    int limit = 30,
    dynamic startAfter,
  }) async => page;
}

Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  group('CaroBoard.winningLine — same law as the CF caroWinner', () {
    List<int> line(List<int> cells, [CaroRule rule = CaroRule.vn]) =>
        CaroBoard(cells).winningLine(rule);
    final filler = row(14, [0, 2, 4, 6]);

    test('five horizontal, vertical, both diagonals', () {
      final runs = <List<int>>[
        row(7, [3, 4, 5, 6, 7]),
        [
          for (final r in [2, 3, 4, 5, 6]) at(r, 9),
        ],
        [for (var i = 0; i < 5; i++) at(3 + i, 3 + i)],
        [for (var i = 0; i < 5; i++) at(3 + i, 11 - i)],
      ];
      for (final xs in runs) {
        expect(line(seq(xs, filler)).toSet(), xs.toSet());
      }
    });

    test('four does not win', () {
      expect(line(seq(row(7, [3, 4, 5, 6]), row(9, [1, 2, 3]))), isEmpty);
    });

    test('blocked at both ends: vn no, free yes', () {
      final cells = seq(row(7, [3, 4, 5, 6, 7]), [
        ...row(7, [2, 8]),
        ...row(9, [1, 2]),
      ]);
      expect(line(cells), isEmpty);
      expect(line(cells, CaroRule.free), hasLength(5));
    });

    test('blocked at one end wins; the edge is not a block', () {
      expect(
        line(
          seq(row(7, [3, 4, 5, 6, 7]), [
            ...row(7, [2]),
            ...row(9, [1, 2, 3]),
          ]),
        ),
        hasLength(5),
      );
      expect(
        line(
          seq(row(7, [0, 1, 2, 3, 4]), [
            ...row(7, [5]),
            ...row(9, [1, 2, 3]),
          ]),
        ),
        row(7, [0, 1, 2, 3, 4]),
      );
    });

    test('six: open end wins, both ends blocked does not', () {
      expect(
        line(
          seq(row(7, [2, 3, 4, 5, 6, 7]), [
            ...row(7, [1]),
            ...row(9, [1, 3, 5, 7]),
          ]),
        ),
        hasLength(6),
      );
      expect(
        line(
          seq(row(7, [2, 3, 4, 5, 6, 7]), [
            ...row(7, [1, 8]),
            ...row(9, [1, 3, 5]),
          ]),
        ),
        isEmpty,
      );
    });

    test('only lines through the last move', () {
      final cells = [
        ...seq(row(7, [3, 4, 5, 6, 7]), row(9, [1, 3, 5, 7])),
        at(12, 12),
      ];
      expect(line(cells), isEmpty);
    });
  });

  group('CaroBoard pieces', () {
    test(
      'X on even moves, move numbers, next side, out-of-board cells dropped',
      () {
        final board = CaroBoard([at(7, 7), at(7, 8), at(8, 8)]);
        expect(board.pieceAt(at(7, 7)), CaroSide.x);
        expect(board.pieceAt(at(7, 8)), CaroSide.o);
        expect(board.pieceAt(at(0, 0)), isNull);
        expect(board.moveNumberAt(at(8, 8)), 3);
        expect(board.nextSide, CaroSide.o);
        expect(caroParseCells([3, 'x', 225, -1, 4.0]), [3, 4]);
      },
    );
  });

  group('CaroGame', () {
    final now = DateTime(2026, 10, 20, 10);

    test('parses the CF doc; turn, sides, result', () {
      final g = game(
        cells: [1, 2, 3],
        status: 'finished',
        extra: {
          'result': {
            'winnerUid': 'alice',
            'reason': 'five',
            'line': [1, 3],
          },
        },
      );
      expect(g.isFinished, isTrue);
      expect(g.isMyTurn('bob'), isFalse); // finished
      expect(g.sideOf('alice'), CaroSide.x);
      expect(g.opponentOf('bob'), 'alice');
      expect(g.result!.outcomeFor('bob'), CaroOutcome.lose);
      expect(g.result!.line, [1, 3]);
      expect(g.rule, CaroRule.vn);
      expect(game().isMyTurn('bob'), isTrue);
      expect(game().isMyTurn('alice'), isFalse);
    });

    test('nudge: only the waiting player, 30 min after the later stamp', () {
      final g = game(
        lastMoveAt: now.subtract(const Duration(minutes: 10)),
        lastNudgeAt: now.subtract(const Duration(minutes: 50)),
      );
      expect(g.nudgeWait('bob', now: now), isNull); // bob's turn
      expect(g.nudgeWait('alice', now: now), const Duration(minutes: 20));
      final later = game(lastMoveAt: now.subtract(const Duration(hours: 2)));
      expect(later.nudgeWait('alice', now: now), Duration.zero);
    });

    test('stale after 7 days; cancel only with one stone', () {
      expect(
        game(
          lastMoveAt: now.subtract(const Duration(days: 7)),
        ).isStale(now: now),
        isTrue,
      );
      expect(
        game(
          lastMoveAt: now.subtract(const Duration(days: 6)),
        ).isStale(now: now),
        isFalse,
      );
      expect(game().canCancel, isTrue);
      expect(game(cells: [1, 2]).canCancel, isFalse);
    });

    test('presence fresh under 45 s', () {
      final g = game(
        extra: {
          'presence': {'bob': now.subtract(const Duration(seconds: 44))},
        },
      );
      expect(g.isPresenceFresh('bob', now: now), isTrue);
      expect(
        g.isPresenceFresh('bob', now: now.add(const Duration(seconds: 2))),
        isFalse,
      );
      expect(g.isPresenceFresh('alice', now: now), isFalse);
    });

    test('caroState: wins per uid, draws, empty doc', () {
      final s = CaroState.fromFirestore({
        'openGameId': 'k1',
        'wins': {'alice': 12, 'bob': 9},
        'draws': 3,
      });
      expect(s.openGameId, 'k1');
      expect(s.winsOf('alice'), 12);
      expect(s.totalFor('alice', 'bob'), 24);
      expect(CaroState.fromFirestore({}).openGameId, isNull);
    });
  });

  group('CaroActionResult.fromResponse', () {
    test('ok + every reason', () {
      final ok = CaroActionResult.fromResponse({
        'ok': true,
        'gameId': 'k1',
        'status': 'finished',
        'cellsLength': 31,
      });
      expect(ok.isOk, isTrue);
      expect(ok.gameStatus, CaroGameStatus.finished);
      expect(ok.cellsLength, 31);
      final reasons = {
        'not_playing': CaroActionStatus.notPlaying,
        'not_your_turn': CaroActionStatus.notYourTurn,
        'stale': CaroActionStatus.stale,
        'occupied': CaroActionStatus.occupied,
        'out_of_range': CaroActionStatus.outOfRange,
        'already_open': CaroActionStatus.alreadyOpen,
        'cooldown': CaroActionStatus.cooldown,
        'too_early': CaroActionStatus.tooEarly,
        'not_player': CaroActionStatus.notPlayer,
        'no_partner': CaroActionStatus.noPartner,
        'whatever': CaroActionStatus.failed,
      };
      reasons.forEach((reason, status) {
        expect(
          CaroActionResult.fromResponse({'ok': false, 'reason': reason}).status,
          status,
        );
      });
      final cd = CaroActionResult.fromResponse({
        'ok': false,
        'reason': 'cooldown',
        'retryAfterMs': 60000,
      });
      expect(cd.retryAfter, const Duration(minutes: 1));
      expect(
        CaroActionResult.fromResponse(null).status,
        CaroActionStatus.failed,
      );
      expect(
        CaroActionResult.fromResponse({
          'ok': false,
          'reason': 'stale',
        }).isStaleBoard,
        isTrue,
      );
    });
  });

  group('CaroGameProvider', () {
    late _FakeCaroService service;
    late CaroGameProvider provider;

    setUp(() {
      service = _FakeCaroService();
      provider = CaroGameProvider(service: service);
      provider.watchForCouple('c1', 'bob', 'alice');
    });

    tearDown(() => provider.dispose());

    test('waiting couple: no partner, start refuses without calling', () async {
      provider.watchForCouple('c1', 'bob', '');
      expect(provider.hasPartner, isFalse);
      final r = await provider.start();
      expect(r.status, CaroActionStatus.noPartner);
      expect(service.calls, isEmpty);
    });

    test(
      'follows the open game from caroState; my-turn flag; old pair hidden',
      () async {
        service.state.add(const CaroState(openGameId: 'k1', wins: {'bob': 2}));
        await pump();
        expect(provider.myWins, 2);
        service.gameStream('k1').add(game());
        await pump();
        expect(provider.openGame?.id, 'k1');
        expect(provider.isMyTurn, isTrue);
        // A game of an earlier pair never counts as ours.
        service
            .gameStream('k1')
            .add(
              CaroGame.fromFirestore('k1', {
                'type': 'caro',
                'players': {'x': 'carol', 'o': 'bob'},
                'status': 'playing',
                'cells': [1],
                'turnUid': 'bob',
              }),
            );
        await pump();
        expect(provider.openGame, isNull);
      },
    );

    test(
      'enter beats presence; pause clears; resume beats; leave clears',
      () async {
        provider.enter('k1');
        expect(service.log, ['beat:k1']);
        provider.pauseHeartbeat();
        provider.resumeHeartbeat();
        provider.leave();
        expect(service.log, ['beat:k1', 'clear:k1', 'beat:k1', 'clear:k1']);
      },
    );

    test(
      'move: pending until the doc has the stone, moveNo = cells.length',
      () async {
        provider.enter('k1');
        service.gameStream('k1').add(game());
        await pump();
        final future = provider.move(at(7, 8));
        expect(provider.pendingCell, at(7, 8));
        expect(service.calls.single, {
          'op': 'move',
          'gameId': 'k1',
          'cell': at(7, 8),
          'moveNo': 1,
        });
        service.next!.complete(
          const CaroActionResult(CaroActionStatus.ok, gameId: 'k1'),
        );
        await future;
        expect(provider.pendingCell, at(7, 8)); // server doc not here yet
        service
            .gameStream('k1')
            .add(game(cells: [at(7, 7), at(7, 8)], turn: 'alice'));
        await pump();
        expect(provider.pendingCell, isNull);
      },
    );

    test(
      'move refused: pending dropped, result tells why; not my turn = no call',
      () async {
        provider.enter('k1');
        service.gameStream('k1').add(game());
        await pump();
        final future = provider.move(at(0, 0));
        service.next!.complete(const CaroActionResult(CaroActionStatus.stale));
        expect((await future).isStaleBoard, isTrue);
        expect(provider.pendingCell, isNull);
        expect(
          (await provider.move(at(7, 7))).status,
          CaroActionStatus.occupied,
        );
        service.gameStream('k1').add(game(turn: 'alice'));
        await pump();
        expect(
          (await provider.move(at(1, 1))).status,
          CaroActionStatus.notYourTurn,
        );
        expect(service.calls, hasLength(1));
      },
    );

    test('history keeps only games of the current pair', () async {
      service.page = CaroHistoryPage(
        items: [
          game(status: 'finished'),
          CaroGame.fromFirestore('old', {
            'type': 'caro',
            'players': {'x': 'carol', 'o': 'bob'},
            'status': 'finished',
            'cells': [1],
          }),
        ],
      );
      await provider.loadHistory();
      expect(provider.history.map((g) => g.id), ['k1']);
      expect(provider.hasMoreHistory, isFalse);
    });

    test('last finished game refreshes when the score changes', () async {
      service.page = CaroHistoryPage(items: [game(status: 'finished')]);
      service.state.add(const CaroState(wins: {'alice': 1}));
      await pump();
      await pump();
      expect(provider.lastFinished?.id, 'k1');
      expect(provider.recentGame?.id, 'k1');
    });
  });
}
