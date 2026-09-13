import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/rps_game.dart';

void main() {
  group('RpsResult.judge — the law rock > scissors > paper > rock', () {
    const a = 'uid-a';
    const b = 'uid-b';

    RpsResult judge(RpsChoice x, RpsChoice y) =>
        RpsResult.judge(uidA: a, a: x, uidB: b, b: y);

    test('every real-hand pairing (9) resolves correctly', () {
      // (a, b, expected winner uid or null for draw)
      final cases = <(RpsChoice, RpsChoice, String?)>[
        (RpsChoice.rock, RpsChoice.rock, null),
        (RpsChoice.rock, RpsChoice.paper, b),
        (RpsChoice.rock, RpsChoice.scissors, a),
        (RpsChoice.paper, RpsChoice.rock, a),
        (RpsChoice.paper, RpsChoice.paper, null),
        (RpsChoice.paper, RpsChoice.scissors, b),
        (RpsChoice.scissors, RpsChoice.rock, b),
        (RpsChoice.scissors, RpsChoice.paper, a),
        (RpsChoice.scissors, RpsChoice.scissors, null),
      ];
      for (final (x, y, winner) in cases) {
        final r = judge(x, y);
        expect(r.winnerUid, winner, reason: '$x vs $y');
        expect(r.reason, RpsResultReason.normal, reason: '$x vs $y');
        expect(r.choices, {a: x, b: y});
        expect(r.isDraw, winner == null);
      }
    });

    test('timeout: a missing hand loses to any real hand', () {
      for (final hand in RpsChoice.hands) {
        final r1 = judge(RpsChoice.none, hand);
        expect(r1.winnerUid, b, reason: 'none vs $hand');
        expect(r1.reason, RpsResultReason.timeout);

        final r2 = judge(hand, RpsChoice.none);
        expect(r2.winnerUid, a, reason: '$hand vs none');
        expect(r2.reason, RpsResultReason.timeout);
      }
    });

    test('timeout: both skipped is a draw with reason timeout', () {
      final r = judge(RpsChoice.none, RpsChoice.none);
      expect(r.isDraw, isTrue);
      expect(r.winnerUid, isNull);
      expect(r.reason, RpsResultReason.timeout);
      expect(r.choiceOf(a), RpsChoice.none);
    });

    test('outcomeFor is symmetric per viewer', () {
      final r = judge(RpsChoice.rock, RpsChoice.scissors);
      expect(r.outcomeFor(a), RpsOutcome.win);
      expect(r.outcomeFor(b), RpsOutcome.lose);
      expect(judge(RpsChoice.paper, RpsChoice.paper).outcomeFor(a),
          RpsOutcome.draw);
    });

    test('explicit reason overrides the inferred one', () {
      final r = RpsResult.judge(
        uidA: a,
        a: RpsChoice.rock,
        uidB: b,
        b: RpsChoice.paper,
        reason: RpsResultReason.timeout,
      );
      expect(r.reason, RpsResultReason.timeout);
    });
  });

  group('RpsChoice / RpsGameStatus parsing', () {
    test('fromKey round-trips and degrades unknown to none/unknown', () {
      for (final c in RpsChoice.values) {
        expect(RpsChoice.fromKey(c.key), c);
      }
      expect(RpsChoice.fromKey('lizard'), RpsChoice.none);
      expect(RpsChoice.fromKey(null), RpsChoice.none);
      expect(RpsChoice.fromKey(42), RpsChoice.none);
      expect(RpsChoice.hands, isNot(contains(RpsChoice.none)));

      for (final s in RpsGameStatus.values) {
        expect(RpsGameStatus.fromKey(s.key), s);
      }
      expect(RpsGameStatus.fromKey('paused'), RpsGameStatus.unknown);
      expect(RpsGameStatus.invited.isOpen, isTrue);
      expect(RpsGameStatus.playing.isOpen, isTrue);
      expect(RpsGameStatus.finished.isOpen, isFalse);
    });
  });

  group('RpsGame.fromFirestore', () {
    final created = DateTime(2026, 9, 13, 10, 0, 0);
    final started = created.add(const Duration(seconds: 12));

    test('parses a finished game incl. presence + result', () {
      final game = RpsGame.fromFirestore('g1', <String, dynamic>{
        'type': 'rps',
        'createdBy': 'uid-a',
        'status': 'finished',
        'createdAt': created.toIso8601String(),
        'presence': <String, dynamic>{
          'uid-a': created.toIso8601String(),
          'uid-b': created.add(const Duration(seconds: 2)).toIso8601String(),
        },
        'startedAt': started.toIso8601String(),
        'rematchOf': 'g0',
        'finishedAt': started.add(const Duration(seconds: 5)).toIso8601String(),
        'result': <String, dynamic>{
          'winnerUid': 'uid-b',
          'choices': <String, dynamic>{'uid-a': 'rock', 'uid-b': 'paper'},
          'reason': 'normal',
        },
      });

      expect(game.id, 'g1');
      expect(game.type, 'rps');
      expect(game.createdBy, 'uid-a');
      expect(game.status, RpsGameStatus.finished);
      expect(game.isFinished, isTrue);
      expect(game.createdAt, created);
      expect(game.presence.keys, containsAll(<String>['uid-a', 'uid-b']));
      expect(game.startedAt, started);
      expect(game.rematchOf, 'g0');
      expect(game.finishedAt, isNotNull);
      expect(game.result, isNotNull);
      expect(game.result!.winnerUid, 'uid-b');
      expect(game.result!.choiceOf('uid-a'), RpsChoice.rock);
      expect(game.result!.outcomeFor('uid-a'), RpsOutcome.lose);
      expect(game.partnerOf('uid-a'), 'uid-b');
      expect(game.isCreatedBy('uid-a'), isTrue);
    });

    test('tolerates a minimal invited doc and empty strings', () {
      final game = RpsGame.fromFirestore('g2', <String, dynamic>{
        'createdBy': 'uid-a',
        'status': 'invited',
        'rematchOf': '   ',
      });
      expect(game.type, 'rps');
      expect(game.status, RpsGameStatus.invited);
      expect(game.isOpen, isTrue);
      expect(game.presence, isEmpty);
      expect(game.rematchOf, isNull);
      expect(game.result, isNull);
      expect(game.startedAt, isNull);
      expect(game.countdownRemaining(), isNull);
      expect(game.isPastGrace(), isFalse);
      // No createdAt → can't be judged stale.
      expect(game.isInviteStale(), isFalse);
    });

    test('result with empty winnerUid is a draw; unknown choices → none', () {
      final r = RpsResult.fromMap(<String, dynamic>{
        'winnerUid': '',
        'choices': <String, dynamic>{'uid-a': 'none', 'uid-b': 'weird'},
        'reason': 'timeout',
      });
      expect(r, isNotNull);
      expect(r!.isDraw, isTrue);
      expect(r.choiceOf('uid-b'), RpsChoice.none);
      expect(r.reason, RpsResultReason.timeout);
      expect(RpsResult.fromMap('nope'), isNull);
    });

    test('toMap emits Firestore keys', () {
      final game = RpsGame(
        id: 'g3',
        createdBy: 'uid-a',
        status: RpsGameStatus.invited,
        createdAt: created,
        presence: <String, DateTime>{'uid-a': created},
        rematchOf: 'g2',
      );
      final map = game.toMap();
      expect(map['type'], 'rps');
      expect(map['status'], 'invited');
      expect(map['rematchOf'], 'g2');
      expect(map.containsKey('result'), isFalse);
      expect((map['presence'] as Map)['uid-a'], created.toIso8601String());
    });
  });

  group('RpsGame timing helpers', () {
    final started = DateTime(2026, 9, 13, 10, 0, 0);
    RpsGame playing() => RpsGame(
          id: 'g',
          createdBy: 'uid-a',
          status: RpsGameStatus.playing,
          startedAt: started,
        );

    test('countdownRemaining clamps to 0..5s', () {
      final g = playing();
      expect(g.countdownRemaining(now: started), RpsTiming.countdown);
      expect(
        g.countdownRemaining(now: started.add(const Duration(seconds: 2))),
        const Duration(seconds: 3),
      );
      expect(
        g.countdownRemaining(now: started.add(const Duration(seconds: 9))),
        Duration.zero,
      );
      // Server clock slightly ahead of device → never exceeds the full window.
      expect(
        g.countdownRemaining(
          now: started.subtract(const Duration(seconds: 1)),
        ),
        RpsTiming.countdown,
      );
    });

    test('isPastGrace flips at countdown + grace', () {
      final g = playing();
      expect(g.isPastGrace(now: started.add(const Duration(seconds: 6))), false);
      expect(g.isPastGrace(now: started.add(const Duration(seconds: 7))), true);
    });

    test('presence freshness + invite staleness', () {
      final g = RpsGame(
        id: 'g',
        createdBy: 'uid-a',
        status: RpsGameStatus.invited,
        createdAt: started,
        presence: <String, DateTime>{
          'uid-a': started,
          'uid-b': started.add(const Duration(seconds: 4)),
        },
      );
      expect(g.isPresenceFresh('uid-b', reference: started), isTrue);
      expect(
        g.isPresenceFresh(
          'uid-b',
          reference: started.add(const Duration(seconds: 30)),
        ),
        isFalse,
      );
      expect(g.isPresenceFresh('uid-c', reference: started), isFalse);
      expect(g.isInviteStale(now: started.add(const Duration(minutes: 9))),
          isFalse);
      expect(g.isInviteStale(now: started.add(const Duration(minutes: 10))),
          isTrue);
    });
  });

  group('RpsScore.tally', () {
    test('counts only finished games from my side', () {
      RpsGame finished(String winner) => RpsGame(
            id: winner,
            createdBy: 'me',
            status: RpsGameStatus.finished,
            result: RpsResult(
              winnerUid: winner.isEmpty ? null : winner,
              choices: const <String, RpsChoice>{},
              reason: RpsResultReason.normal,
            ),
          );
      final score = RpsScore.tally(
        <RpsGame>[
          finished('me'),
          finished('me'),
          finished('you'),
          finished(''),
          const RpsGame(id: 'x', createdBy: 'me', status: RpsGameStatus.invited),
        ],
        'me',
      );
      expect(score.wins, 2);
      expect(score.losses, 1);
      expect(score.draws, 1);
      expect(score.total, 4);
    });
  });
}
