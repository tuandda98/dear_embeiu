import 'dart:async';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/rps_game.dart';
import 'package:dear_embeiu/providers/rps_game_provider.dart';
import 'package:dear_embeiu/services/rps_game_service.dart';

/// Records presence writes; streams are driven by the test.
class _FakeRpsService extends RpsGameService {
  final open = StreamController<RpsOpenGamesSnapshot>.broadcast();
  final game = StreamController<RpsGame?>.broadcast();
  final move = StreamController<RpsMove?>.broadcast();

  final List<String> beats = <String>[];
  final List<String> clears = <String>[];

  /// Ordered log of presence writes: `beat:g1` / `clear:g1`.
  final List<String> log = <String>[];

  @override
  bool get isUsingFirebase => true;

  @override
  Stream<RpsOpenGamesSnapshot> watchOpenGameSnapshots(
    String coupleId, {
    int limit = rpsOpenGamesWindow,
  }) => open.stream;

  @override
  Stream<RpsGame?> watchGame(String coupleId, String gameId) => game.stream;

  @override
  Stream<RpsMove?> watchMyMove(String coupleId, String gameId, String uid) =>
      move.stream;

  @override
  Future<RpsClockSample?> heartbeat(
    String coupleId,
    String gameId,
    String uid,
  ) async {
    beats.add(gameId);
    log.add('beat:$gameId');
    return null;
  }

  @override
  Future<bool> clearPresence(String coupleId, String gameId, String uid) async {
    clears.add(gameId);
    log.add('clear:$gameId');
    return true;
  }

  @override
  Future<bool> startIfBothPresent({
    required String coupleId,
    required String gameId,
    required String myUid,
    required String partnerUid,
  }) async => false;

  @override
  Future<bool> expireIfStale({
    required String coupleId,
    required String gameId,
    DateTime? now,
  }) async => false;

  @override
  Future<bool> finishViaCallable({
    required String coupleId,
    required String gameId,
  }) async => false;

  Future<void> close() async {
    await open.close();
    await game.close();
    await move.close();
  }
}

void main() {
  group('rpsPresenceActionFor (Tester RPS-19/RPS-20)', () {
    test('resumed beats · inactive is transient · the rest clear at once', () {
      expect(
        rpsPresenceActionFor(AppLifecycleState.resumed),
        RpsPresenceAction.beat,
      );
      expect(
        rpsPresenceActionFor(AppLifecycleState.inactive),
        RpsPresenceAction.pauseTransient,
      );
      for (final s in <AppLifecycleState>[
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
      ]) {
        expect(rpsPresenceActionFor(s), RpsPresenceAction.pauseAndClear);
      }
    });
  });

  group('RpsGameProvider presence clear (Tester RPS-19/RPS-20)', () {
    late _FakeRpsService service;
    late RpsGameProvider provider;
    final screen = Object();

    /// `testWidgets` with the provider + fake built INSIDE its fake-async
    /// zone (so the heartbeat timers are fake too) and disposed before the
    /// zone's "no pending timers" check — setUp/tearDown run outside it.
    void providerTest(String name, Future<void> Function(WidgetTester) body) {
      testWidgets(name, (tester) async {
        service = _FakeRpsService();
        provider = RpsGameProvider(service: service);
        provider.watchForCouple('c1', 'me', 'you');
        provider.attach(screen);
        provider.enter('g1', owner: screen);
        try {
          await body(tester);
        } finally {
          provider.dispose();
          await service.close();
        }
      });
    }

    providerTest('pause clears my presence once; resume beats again', (
      tester,
    ) async {
      await tester.pump();
      expect(service.beats, <String>['g1']);

      provider.pauseHeartbeat(owner: screen);
      await tester.pump();
      expect(service.clears, <String>['g1']);
      expect(provider.isHeartbeatPaused, isTrue);

      // A second pause signal (inactive → hidden → paused) doesn't re-clear.
      provider.pauseHeartbeat(owner: screen);
      provider.pauseHeartbeat(owner: screen, transient: true);
      await tester.pump(const Duration(seconds: 5));
      expect(service.clears, <String>['g1']);
      expect(service.beats, <String>['g1'], reason: 'no beats while paused');

      provider.resumeHeartbeat(owner: screen);
      await tester.pump();
      expect(service.log, <String>['beat:g1', 'clear:g1', 'beat:g1']);

      // Paused again after a resume → cleared again.
      provider.pauseHeartbeat(owner: screen);
      await tester.pump();
      expect(service.clears, <String>['g1', 'g1']);
    });

    providerTest('transient pause: no write if back within the grace', (
      tester,
    ) async {
      await tester.pump();
      provider.pauseHeartbeat(owner: screen, transient: true);
      await tester.pump(const Duration(milliseconds: 800));
      provider.resumeHeartbeat(owner: screen);
      await tester.pump(const Duration(seconds: 2));
      expect(service.clears, isEmpty);
    });

    providerTest('transient pause: clears once the grace runs out', (
      tester,
    ) async {
      await tester.pump();
      provider.pauseHeartbeat(owner: screen, transient: true);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(service.clears, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(service.clears, <String>['g1']);
    });

    providerTest(
      'transient escalated to a real pause clears right away, once',
      (tester) async {
        await tester.pump();
        provider.pauseHeartbeat(owner: screen, transient: true);
        provider.pauseHeartbeat(owner: screen); // hidden / paused
        await tester.pump();
        expect(service.clears, <String>['g1']);
        await tester.pump(const Duration(seconds: 3));
        expect(service.clears, <String>['g1']);
      },
    );

    providerTest('a screen that is not on top can\'t pause / clear', (
      tester,
    ) async {
      await tester.pump();
      provider.pauseHeartbeat(owner: Object());
      await tester.pump();
      expect(service.clears, isEmpty);
      expect(provider.isHeartbeatPaused, isFalse);
    });

    providerTest('leaving the screen (detach) clears my presence', (
      tester,
    ) async {
      await tester.pump();
      provider.detach(screen);
      await tester.pump();
      expect(service.clears, <String>['g1']);
      expect(provider.currentGameId, isNull);
    });

    providerTest('detach after a pause that already cleared: no second write', (
      tester,
    ) async {
      await tester.pump();
      provider.pauseHeartbeat(owner: screen);
      provider.detach(screen);
      await tester.pump();
      expect(service.clears, <String>['g1']);
    });

    providerTest('switching games clears the old one, then beats the new', (
      tester,
    ) async {
      await tester.pump();
      provider.enter('g2', owner: screen);
      await tester.pump();
      expect(service.log, <String>['beat:g1', 'clear:g1', 'beat:g2']);
    });

    providerTest('detach of the top screen: clear BEFORE the lower one beats', (
      tester,
    ) async {
      await tester.pump();
      final top = Object();
      provider.attach(top);
      provider.enter('g2', owner: top);
      await tester.pump();
      provider.detach(top);
      await tester.pump();
      // g1 cleared when g2 took over, g2 cleared on detach, g1 back + beating.
      expect(service.log, <String>[
        'beat:g1',
        'clear:g1',
        'beat:g2',
        'clear:g2',
        'beat:g1',
      ]);
      expect(provider.currentGameId, 'g1');
    });

    providerTest('sign-out (clear) never writes, even with a pending clear', (
      tester,
    ) async {
      await tester.pump();
      provider.pauseHeartbeat(owner: screen, transient: true);
      provider.clear();
      await tester.pump(const Duration(seconds: 3));
      expect(service.clears, isEmpty);
    });
  });

  group('RpsGameProvider.isSettling (Tester RPS-22)', () {
    late _FakeRpsService service;
    late RpsGameProvider provider;
    final screen = Object();

    void providerTest(String name, Future<void> Function(WidgetTester) body) {
      testWidgets(name, (tester) async {
        service = _FakeRpsService();
        provider = RpsGameProvider(service: service);
        provider.watchForCouple('c1', 'me', 'you');
        provider.attach(screen);
        provider.enter('g1', owner: screen);
        try {
          await body(tester);
        } finally {
          provider.dispose();
          await service.close();
        }
      });
    }

    RpsGame playing(DateTime? startedAt) => RpsGame(
      id: 'g1',
      createdBy: 'you',
      status: RpsGameStatus.playing,
      createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      startedAt: startedAt,
    );

    providerTest('picked + clock over → settling (not only `resolving`)', (
      tester,
    ) async {
      await tester.pump();
      service.move.add(const RpsMove(uid: 'me', choice: RpsChoice.rock));
      service.game.add(
        playing(DateTime.now().subtract(const Duration(seconds: 2))),
      );
      await tester.pump();
      expect(provider.phase, RpsPhase.chosenWaiting);
      expect(provider.isSettling, isFalse, reason: 'clock still running');

      service.game.add(
        playing(DateTime.now().subtract(const Duration(seconds: 6))),
      );
      await tester.pump();
      expect(provider.phase, RpsPhase.chosenWaiting);
      expect(provider.isSettling, isTrue);
    });

    providerTest('no hand + clock over (`resolving`) → settling', (
      tester,
    ) async {
      await tester.pump();
      service.game.add(
        playing(DateTime.now().subtract(const Duration(seconds: 6))),
      );
      await tester.pump();
      expect(provider.phase, RpsPhase.resolving);
      expect(provider.isSettling, isTrue);
    });

    providerTest('picked before `startedAt` echoed back → not settling', (
      tester,
    ) async {
      await tester.pump();
      service.move.add(const RpsMove(uid: 'me', choice: RpsChoice.paper));
      service.game.add(playing(null));
      await tester.pump();
      expect(provider.phase, RpsPhase.chosenWaiting);
      expect(provider.isSettling, isFalse);
    });
  });

  group('rpsFreshServerStamps (Tester RPS-23)', () {
    final t0 = DateTime.utc(2026, 9, 14, 9, 0, 0);
    RpsGame g(
      String id, {
      DateTime? createdAt,
      Map<String, DateTime> presence = const <String, DateTime>{},
      DateTime? startedAt,
      RpsGameStatus status = RpsGameStatus.invited,
    }) => RpsGame(
      id: id,
      createdBy: 'you',
      status: status,
      createdAt: createdAt,
      presence: presence,
      startedAt: startedAt,
    );

    test('unchanged docs yield nothing (their age is unknown)', () {
      final a = g('a', createdAt: t0, presence: {'you': t0});
      expect(
        rpsFreshServerStamps(previous: [a], current: [a], windowLimit: 5),
        isEmpty,
      );
    });

    test('a new beat, startedAt and a confirmed createdAt are fresh', () {
      final t1 = t0.add(const Duration(seconds: 3));
      final before = [
        g('a', createdAt: t0, presence: {'you': t0}),
        g('b'), // my create, still pending (createdAt null)
      ];
      final after = [
        g(
          'a',
          createdAt: t0,
          presence: {'you': t1, 'me': t1},
          startedAt: t1,
          status: RpsGameStatus.playing,
        ),
        g('b', createdAt: t1),
      ];
      final fresh = rpsFreshServerStamps(
        previous: before,
        current: after,
        windowLimit: 5,
      );
      expect(fresh, everyElement(t1));
      expect(fresh.length, 4);
    });

    test(
      'a new doc counts; an old doc sliding into a full window does not',
      () {
        final newest = t0.add(const Duration(minutes: 1));
        final full = List<RpsGame>.generate(
          5,
          (i) => g('o$i', createdAt: t0.subtract(Duration(minutes: i))),
        );
        // Window not full → any newcomer is a genuine create.
        expect(
          rpsFreshServerStamps(
            previous: const <RpsGame>[],
            current: [g('n', createdAt: newest)],
            windowLimit: 5,
          ),
          [newest],
        );
        // Full window: one left, an OLDER doc slid in → ignored.
        final slid = g('old', createdAt: t0.subtract(const Duration(hours: 2)));
        expect(
          rpsFreshServerStamps(
            previous: full,
            current: [...full.skip(1), slid],
            windowLimit: 5,
          ),
          isEmpty,
        );
        // Full window: a doc newer than everything seen → a real create.
        expect(
          rpsFreshServerStamps(
            previous: full,
            current: [
              g('n', createdAt: newest),
              ...full.take(4),
            ],
            windowLimit: 5,
          ),
          [newest],
        );
      },
    );
  });

  group('RpsGameProvider server clock before entering a game (RPS-23)', () {
    late _FakeRpsService service;
    late RpsGameProvider provider;

    void providerTest(String name, Future<void> Function(WidgetTester) body) {
      testWidgets(name, (tester) async {
        service = _FakeRpsService();
        provider = RpsGameProvider(service: service);
        provider.watchForCouple('c1', 'me', 'you');
        try {
          await body(tester);
        } finally {
          provider.dispose();
          await service.close();
        }
      });
    }

    Future<void> emit(
      WidgetTester tester,
      List<RpsGame> games, {
      bool fromCache = false,
    }) async {
      service.open.add(
        RpsOpenGamesSnapshot(games: games, fromCache: fromCache),
      );
      await tester.pump();
    }

    RpsGame invite(String id, DateTime createdAt) => RpsGame(
      id: id,
      createdBy: 'you',
      status: RpsGameStatus.invited,
      createdAt: createdAt,
      presence: {'you': createdAt},
    );

    providerTest('partner invites while I\'m on Home → offset measured', (
      tester,
    ) async {
      // Server 13s ahead of this device (smoke-test 2026-09-13 emulator).
      await emit(tester, const <RpsGame>[]);
      expect(provider.clockOffset, Duration.zero, reason: 'initial load');
      final serverNow = DateTime.now().add(const Duration(seconds: 13));
      await emit(tester, [invite('g', serverNow)]);
      expect(
        (provider.clockOffset - const Duration(seconds: 13)).abs(),
        lessThan(const Duration(milliseconds: 500)),
      );
    });

    providerTest('the initial load alone never moves the clock', (
      tester,
    ) async {
      await emit(tester, [
        invite('g', DateTime.now().subtract(const Duration(minutes: 3))),
      ]);
      expect(provider.clockOffset, Duration.zero);
    });

    providerTest('after a cache event the next server diff is not trusted', (
      tester,
    ) async {
      await emit(tester, const <RpsGame>[]);
      await emit(tester, const <RpsGame>[], fromCache: true); // went offline
      final stale = DateTime.now().subtract(const Duration(seconds: 40));
      await emit(tester, [invite('g', stale)]); // back online
      expect(provider.clockOffset, Duration.zero);
    });

    providerTest('an implausible (>1 min) hint is discarded', (tester) async {
      await emit(tester, const <RpsGame>[]);
      await emit(tester, [
        invite('g', DateTime.now().subtract(const Duration(minutes: 15))),
      ]);
      expect(provider.clockOffset, Duration.zero);
    });

    providerTest('keeps the largest lower bound', (tester) async {
      await emit(tester, const <RpsGame>[]);
      final now = DateTime.now();
      final a = invite('a', now.add(const Duration(seconds: 10)));
      await emit(tester, [a]);
      final late = RpsGame(
        id: 'a',
        createdBy: 'you',
        status: RpsGameStatus.invited,
        createdAt: a.createdAt,
        presence: {'you': now.add(const Duration(seconds: 2))},
      );
      // A delivery that arrived late gives a smaller sample → ignored.
      await emit(tester, [late]);
      expect(provider.clockOffset.inSeconds, greaterThanOrEqualTo(9));
    });
  });
}
