import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/rps_game.dart';
import 'firebase_bootstrap_service.dart';

/// How many open games the couple-wide listener keeps (see
/// [RpsGameService.watchOpenGames]).
const int rpsOpenGamesWindow = 5;

/// One page of finished games for the history screen (same cursor shape as
/// [CareMessagePage]): pass [lastDoc] back as `startAfter` for the next page.
class RpsHistoryPage {
  const RpsHistoryPage({
    required this.items,
    this.lastDoc,
    this.hasMore = false,
  });

  const RpsHistoryPage.empty()
    : items = const <RpsGame>[],
      lastDoc = null,
      hasMore = false;

  final List<RpsGame> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

/// One heartbeat round-trip: device clock before the write ([sentAt]) and at
/// its acknowledgement ([ackAt]), plus the server-resolved stamp the write
/// produced ([serverStamp]). Feeds [RpsGameProvider]'s server-clock offset so
/// the countdown doesn't depend on the phone's own clock being right.
class RpsClockSample {
  const RpsClockSample({
    required this.sentAt,
    required this.ackAt,
    required this.serverStamp,
  });

  final DateTime sentAt;
  final DateTime ackAt;
  final DateTime serverStamp;

  Duration get rtt => ackAt.difference(sentAt);

  /// server − device, assuming the stamp was taken mid-flight.
  Duration get offset => serverStamp.difference(
    sentAt.add(Duration(microseconds: rtt.inMicroseconds ~/ 2)),
  );
}

/// One event of the couple's open-games listener: the docs plus whether the
/// SDK served them from its local cache (offline / not yet synced). Only
/// consecutive NON-cache events are trusted as "live" for the server-clock
/// estimate taken before any game is entered (Tester RPS-23).
class RpsOpenGamesSnapshot {
  const RpsOpenGamesSnapshot({required this.games, required this.fromCache});

  final List<RpsGame> games;
  final bool fromCache;
}

/// Server stamps that were written JUST NOW, judged by diffing two
/// consecutive live snapshots of the open-games query (Tester RPS-23 — a
/// server-clock hint before the first heartbeat). A stamp counts only when
/// it changed between [previous] and [current]:
/// - a `presence` beat that is new / newer than before,
/// - `startedAt` / `createdAt` going from null (pending or absent) to a value,
/// - the `createdAt` of a doc that newly entered the set, provided it can't
///   be an OLD doc sliding into the query window ([windowLimit]): either the
///   window wasn't full before, or it is newer than every doc seen before.
///
/// Every such stamp was committed before the snapshot reached the device, so
/// `stamp − receivedAt` is a LOWER bound of the server − device offset; the
/// caller keeps the maximum. Old stamps (the initial load, anything unchanged)
/// are never returned — their age is unknown.
List<DateTime> rpsFreshServerStamps({
  required List<RpsGame> previous,
  required List<RpsGame> current,
  required int windowLimit,
}) {
  final before = <String, RpsGame>{for (final g in previous) g.id: g};
  DateTime? newestBefore;
  for (final g in previous) {
    final at = g.createdAt;
    if (at != null && (newestBefore == null || at.isAfter(newestBefore))) {
      newestBefore = at;
    }
  }
  final fresh = <DateTime>[];
  for (final game in current) {
    final old = before[game.id];
    if (old == null) {
      final created = game.createdAt;
      final canBeSlideIn = previous.length >= windowLimit;
      if (created != null &&
          (!canBeSlideIn ||
              (newestBefore != null && created.isAfter(newestBefore)))) {
        fresh.add(created);
      }
      continue;
    }
    for (final entry in game.presence.entries) {
      final was = old.presence[entry.key];
      if (was == null || entry.value.isAfter(was)) {
        fresh.add(entry.value);
      }
    }
    if (old.startedAt == null && game.startedAt != null) {
      fresh.add(game.startedAt!);
    }
    if (old.createdAt == null && game.createdAt != null) {
      fresh.add(game.createdAt!);
    }
  }
  return fresh;
}

/// What the `nudgeRpsPlayer` callable answered (2026-09-14 no-skip rule —
/// "Nhắc người ấy" after I have thrown).
enum RpsNudgeStatus {
  /// Push + inbox `rps_moved` sent to the partner; the server stamped
  /// `lastNudgeAt` (cooldown 60s starts now).
  sent,

  /// Too soon after the previous nudge — see [RpsNudgeResult.retryAfter].
  cooldown,

  /// The partner has thrown in the meantime (the round is resolving).
  partnerMoved,

  /// The round isn't `playing` any more (finished / gone).
  notPlaying,

  /// The server doesn't see my hand yet (my move write still in flight).
  notMoved,

  /// Network / auth / unexpected error — nothing was sent.
  failed,
}

/// Result of [RpsGameService.nudgePartner].
class RpsNudgeResult {
  const RpsNudgeResult(this.status, {this.retryAfter});

  final RpsNudgeStatus status;

  /// [RpsNudgeStatus.cooldown] only: how long until the server allows the
  /// next nudge (`retryAfterMs`).
  final Duration? retryAfter;

  bool get isSent => status == RpsNudgeStatus.sent;

  /// Maps the callable's `{ok, reason, retryAfterMs}` payload.
  static RpsNudgeResult fromResponse(dynamic data) {
    if (data is! Map) {
      return const RpsNudgeResult(RpsNudgeStatus.failed);
    }
    if (data['ok'] == true) {
      return const RpsNudgeResult(RpsNudgeStatus.sent);
    }
    switch ((data['reason'] ?? '').toString().trim()) {
      case 'cooldown':
        final raw = data['retryAfterMs'];
        final ms = raw is num ? raw.round() : int.tryParse('$raw');
        return RpsNudgeResult(
          RpsNudgeStatus.cooldown,
          retryAfter: (ms == null || ms <= 0)
              ? RpsTiming.nudgeCooldown
              : Duration(milliseconds: ms),
        );
      case 'partner_moved':
        return const RpsNudgeResult(RpsNudgeStatus.partnerMoved);
      case 'not_playing':
        return const RpsNudgeResult(RpsNudgeStatus.notPlaying);
      case 'not_moved':
        return const RpsNudgeResult(RpsNudgeStatus.notMoved);
      default:
        return const RpsNudgeResult(RpsNudgeStatus.failed);
    }
  }
}

/// Firestore access for rock-paper-scissors (feature rps-game, 2026-09-13):
/// `couples/{coupleId}/games/{gameId}` + `moves/{uid}` — contract in
/// `project/features/rps-game/overview.md` §3.
///
/// Fail-soft like the other couple services: off Firebase every write is a
/// no-op returning false, every stream is empty, and Firestore errors
/// (permission-denied from a rule we lost the race against, offline…) are
/// swallowed + logged instead of thrown. There is NO local fallback — a game
/// needs the partner's phone.
///
/// ⚠️ Rules are `hasOnly`-strict: the create payload MUST stay exactly
/// `[type, createdBy, status, createdAt, presence, rematchOf, updatedAt]`
/// (subset), `createdAt == request.time` (serverTimestamp), and `presence`
/// may only carry MY uid. `finishedAt`/`result`/`moved`/`lastNudgeAt` are
/// Admin-SDK-only (a heartbeat merely carries them along untouched).
class RpsGameService {
  RpsGameService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore,
      _functions = functions;

  static const String _region = 'us-central1';
  static const String _nudgeCallable = 'nudgeRpsPlayer';

  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  FirebaseFunctions get _fns =>
      _functions ?? FirebaseFunctions.instanceFor(region: _region);

  CollectionReference<Map<String, dynamic>> _games(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('games');

  DocumentReference<Map<String, dynamic>> _game(
    String coupleId,
    String gameId,
  ) => _games(coupleId).doc(gameId);

  DocumentReference<Map<String, dynamic>> _move(
    String coupleId,
    String gameId,
    String uid,
  ) => _game(coupleId, gameId).collection('moves').doc(uid);

  static bool _blank(String s) => s.trim().isEmpty;

  /// Creates an `invited` game (my presence stamped so the partner sees me
  /// online the moment they open it). [rematchOf] links a "Chơi lại" game to
  /// the previous one so the CF can skip the push when the partner is still on
  /// that result screen. Returns the new gameId, or null when nothing was
  /// written (no Firebase / rule denied).
  Future<String?> createGame({
    required String coupleId,
    required String uid,
    String? rematchOf,
  }) async {
    if (_blank(coupleId) || _blank(uid) || !isUsingFirebase) {
      return null;
    }
    try {
      final ref = _games(coupleId.trim()).doc();
      await ref.set(_createPayload(uid, rematchOf));
      return ref.id;
    } catch (e) {
      debugPrint('RpsGameService.createGame failed: $e');
      return null;
    }
  }

  /// The `invited` create payload — exactly the rules' create `hasOnly` set.
  static Map<String, dynamic> _createPayload(
    String uid,
    String? rematchOf,
  ) => <String, dynamic>{
    'type': RpsGame.typeKey,
    'createdBy': uid.trim(),
    'status': RpsGameStatus.invited.key,
    'createdAt': FieldValue.serverTimestamp(),
    'presence': <String, dynamic>{uid.trim(): FieldValue.serverTimestamp()},
    if (rematchOf != null && !_blank(rematchOf)) 'rematchOf': rematchOf.trim(),
  };

  /// Get-or-create an `invited` game at a FIXED id (Tester RPS-1: the
  /// "Chơi lại" game lives at [rpsRematchGameId] so both phones tapping at
  /// once meet in ONE game). Transaction: doc already there → nothing is
  /// written and the existing game comes back (`created: false`); otherwise
  /// it is created. Two racing creates: one commits, the other's transaction
  /// retries, sees the doc and joins it. A plain `set` would not do — on an
  /// existing doc it is evaluated as an UPDATE and the rules deny it
  /// (`createdAt` is immutable).
  ///
  /// Null when nothing could be read/written (no Firebase, offline — a
  /// transaction needs the server — or a rule denied).
  Future<({String id, bool created, RpsGame? existing})?> createGameWithId({
    required String coupleId,
    required String uid,
    required String gameId,
    String? rematchOf,
  }) async {
    if (_blank(coupleId) || _blank(uid) || _blank(gameId) || !isUsingFirebase) {
      return null;
    }
    final ref = _game(coupleId.trim(), gameId.trim());
    try {
      return await _db
          .runTransaction<({String id, bool created, RpsGame? existing})>((
            tx,
          ) async {
            final snap = await tx.get(ref);
            final data = snap.data();
            if (snap.exists && data != null) {
              return (
                id: ref.id,
                created: false,
                existing: RpsGame.fromFirestore(snap.id, data),
              );
            }
            tx.set(ref, _createPayload(uid, rematchOf));
            return (id: ref.id, created: true, existing: null);
          });
    } catch (e) {
      debugPrint('RpsGameService.createGameWithId failed: $e');
      // Lost the race in a way the transaction didn't absorb → if the doc is
      // there now, join it.
      final existing = await fetchGame(coupleId, gameId);
      return existing == null
          ? null
          : (id: existing.id, created: false, existing: existing);
    }
  }

  /// One-shot read of a game (null when missing / unreadable / off Firebase).
  Future<RpsGame?> fetchGame(String coupleId, String gameId) async {
    if (_blank(coupleId) || _blank(gameId) || !isUsingFirebase) {
      return null;
    }
    try {
      final snap = await _game(coupleId.trim(), gameId.trim()).get();
      final data = snap.data();
      return (snap.exists && data != null)
          ? RpsGame.fromFirestore(snap.id, data)
          : null;
    } catch (e) {
      debugPrint('RpsGameService.fetchGame failed: $e');
      return null;
    }
  }

  /// Streams one game (null once it no longer exists / can't be read).
  Stream<RpsGame?> watchGame(String coupleId, String gameId) {
    if (_blank(coupleId) || _blank(gameId) || !isUsingFirebase) {
      return Stream<RpsGame?>.value(null);
    }
    return _game(coupleId.trim(), gameId.trim())
        .snapshots()
        .map((snap) {
          final data = snap.data();
          return (snap.exists && data != null)
              ? RpsGame.fromFirestore(snap.id, data)
              : null;
        })
        .handleError((Object e) {
          debugPrint('RpsGameService.watchGame error: $e');
        });
  }

  /// Streams the couple's newest [limit] open (`invited`/`playing`) games,
  /// newest first. Several, not one (Tester RPS-2): the newest may be a dead
  /// doc — an invite past its TTL nobody flipped to `expired` (a `playing`
  /// round is never dead: it waits for both hands) — and the provider picks
  /// the first LIVE one with [RpsGame.pickOpen] against server time. Needs
  /// the composite index `(type ASC, status ASC, createdAt DESC)`.
  Stream<List<RpsGame>> watchOpenGames(String coupleId, {int limit = 5}) =>
      watchOpenGameSnapshots(coupleId, limit: limit).map((s) => s.games);

  /// [watchOpenGames] plus the cache flag of each event. Listens WITH
  /// metadata changes so going offline surfaces as a `fromCache` event —
  /// the provider then stops treating the next server event's diff as live
  /// (it may carry stamps written while we were away — Tester RPS-23).
  Stream<RpsOpenGamesSnapshot> watchOpenGameSnapshots(
    String coupleId, {
    int limit = rpsOpenGamesWindow,
  }) {
    if (_blank(coupleId) || !isUsingFirebase) {
      return Stream<RpsOpenGamesSnapshot>.value(
        const RpsOpenGamesSnapshot(games: <RpsGame>[], fromCache: true),
      );
    }
    return _games(coupleId.trim())
        .where('type', isEqualTo: RpsGame.typeKey)
        .where(
          'status',
          whereIn: <String>[
            RpsGameStatus.invited.key,
            RpsGameStatus.playing.key,
          ],
        )
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => RpsOpenGamesSnapshot(
            games: snap.docs
                .map((doc) => RpsGame.fromFirestore(doc.id, doc.data()))
                .toList(growable: false),
            fromCache: snap.metadata.isFromCache,
          ),
        )
        .handleError((Object e) {
          debugPrint('RpsGameService.watchOpenGames error: $e');
        });
  }

  /// Streams MY move for a game (null until I've picked). The partner's move
  /// is never read directly — it arrives inside `result.choices` on finish.
  Stream<RpsMove?> watchMyMove(String coupleId, String gameId, String uid) {
    if (_blank(coupleId) || _blank(gameId) || _blank(uid) || !isUsingFirebase) {
      return Stream<RpsMove?>.value(null);
    }
    return _move(coupleId.trim(), gameId.trim(), uid.trim())
        .snapshots()
        .map((snap) {
          final data = snap.data();
          return (snap.exists && data != null)
              ? RpsMove.fromDoc(snap.id, data)
              : null;
        })
        .handleError((Object e) {
          debugPrint('RpsGameService.watchMyMove error: $e');
        });
  }

  /// Presence heartbeat: `presence.{uid} = serverTimestamp` (dot-path merge —
  /// touches only my key, as the rules require). Fire-and-forget safe.
  ///
  /// Doubles as a server-clock probe: once the write is acknowledged, the
  /// cached doc holds the server-resolved stamp of THIS beat, so
  /// `(sentAt, ackAt, serverStamp)` bounds the device↔server clock offset
  /// (error ≤ RTT/2). Returns null when the write failed or the resolved stamp
  /// can't be read back (a newer beat still pending reads as null — skipped).
  Future<RpsClockSample?> heartbeat(
    String coupleId,
    String gameId,
    String uid,
  ) async {
    if (_blank(coupleId) || _blank(gameId) || _blank(uid) || !isUsingFirebase) {
      return null;
    }
    final ref = _game(coupleId.trim(), gameId.trim());
    final key = uid.trim();
    final DateTime sentAt;
    final DateTime ackAt;
    try {
      sentAt = DateTime.now();
      await ref.update(<String, dynamic>{
        'presence.$key': FieldValue.serverTimestamp(),
      });
      ackAt = DateTime.now();
    } catch (e) {
      // Game gone / status closed by a rule — a missed beat is harmless.
      debugPrint('RpsGameService.heartbeat failed: $e');
      return null;
    }
    try {
      final snap = await ref.get(const GetOptions(source: Source.cache));
      final presence = snap.data()?['presence'];
      final stamp = presence is Map ? rpsParseTimestamp(presence[key]) : null;
      return stamp == null
          ? null
          : RpsClockSample(sentAt: sentAt, ackAt: ackAt, serverStamp: stamp);
    } catch (_) {
      return null; // cache miss — no sample this beat
    }
  }

  /// Drops `presence.{uid}` (Tester RPS-19/RPS-20): I left the game screen,
  /// a page covered it, or the app went to the background. Without this my
  /// last beat stays "fresh" for up to 10s (start rule / `startIfBothPresent`)
  /// and 30s (the CF skips a rematch push while the partner's presence on the
  /// previous game is fresh) — the partner could start a round I can't see,
  /// or send a rematch I'm never told about. The rules let me delete my OWN
  /// key only. Fail-soft and fire-and-forget safe; a later heartbeat from the
  /// same device is ordered after it, so resuming simply re-stamps.
  Future<bool> clearPresence(String coupleId, String gameId, String uid) async {
    if (_blank(coupleId) || _blank(gameId) || _blank(uid) || !isUsingFirebase) {
      return false;
    }
    try {
      await _game(coupleId.trim(), gameId.trim()).update(<String, dynamic>{
        'presence.${uid.trim()}': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      debugPrint('RpsGameService.clearPresence failed: $e');
      return false;
    }
  }

  /// `invited → playing` when BOTH members are fresh on the screen. Runs in a
  /// transaction so two phones flipping at once produce ONE `startedAt`
  /// (whoever commits first wins; the other re-reads `playing` and backs off).
  ///
  /// Freshness is judged server-time vs server-time (partner stamp against MY
  /// stamp) so client clock skew can't block/allow a start wrongly; when my
  /// stamp is missing it falls back to the device clock. Returns true only
  /// when THIS call performed the transition.
  Future<bool> startIfBothPresent({
    required String coupleId,
    required String gameId,
    required String myUid,
    required String partnerUid,
  }) async {
    if (_blank(coupleId) ||
        _blank(gameId) ||
        _blank(myUid) ||
        _blank(partnerUid) ||
        !isUsingFirebase) {
      return false;
    }
    try {
      return await _db.runTransaction<bool>((tx) async {
        final ref = _game(coupleId.trim(), gameId.trim());
        final snap = await tx.get(ref);
        final data = snap.data();
        if (!snap.exists || data == null) {
          return false;
        }
        final game = RpsGame.fromFirestore(snap.id, data);
        if (!game.isInvited) {
          return false;
        }
        final reference = game.presence[myUid.trim()];
        if (!game.isPresenceFresh(partnerUid.trim(), reference: reference)) {
          return false;
        }
        tx.update(ref, <String, dynamic>{
          'status': RpsGameStatus.playing.key,
          'startedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (e) {
      debugPrint('RpsGameService.startIfBothPresent failed: $e');
      return false;
    }
  }

  /// Locks in my hand: `moves/{uid} = {choice, createdAt}` (create-only —
  /// a second attempt is denied by the rules). Since the 2026-09-14 no-skip
  /// rule there is NO deadline: the rules accept it any time the game is
  /// `playing`. Completes true once the server acknowledged it, false when it
  /// was refused (round no longer `playing`, already thrown) or can't be sent.
  ///
  /// Offline the future only completes when the network returns (the write
  /// sits in Firestore's queue and my `moves` doc already shows it locally);
  /// the provider bounds how long it WAITS, not the write itself.
  Future<bool> submitMove({
    required String coupleId,
    required String gameId,
    required String uid,
    required RpsChoice choice,
  }) async {
    if (_blank(coupleId) ||
        _blank(gameId) ||
        _blank(uid) ||
        !choice.isHand ||
        !isUsingFirebase) {
      return false;
    }
    try {
      await _move(coupleId.trim(), gameId.trim(), uid.trim()).set(
        <String, dynamic>{
          'choice': choice.key,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('RpsGameService.submitMove failed: $e');
      return false;
    }
  }

  /// `invited → cancelled` (rules: creator only). Returns true on success.
  Future<bool> cancel({
    required String coupleId,
    required String gameId,
    required String uid,
  }) async {
    if (_blank(coupleId) || _blank(gameId) || _blank(uid) || !isUsingFirebase) {
      return false;
    }
    try {
      await _game(coupleId.trim(), gameId.trim()).update(<String, dynamic>{
        'status': RpsGameStatus.cancelled.key,
        'cancelledBy': uid.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('RpsGameService.cancel failed: $e');
      return false;
    }
  }

  /// `invited → expired` when the invite is older than [RpsTiming.inviteTtl]
  /// (transaction: re-checks status + age before writing). Either member may
  /// do it. Returns true only when THIS call expired it. [now] = best estimate
  /// of SERVER time (the rule compares `createdAt` with `request.time`).
  Future<bool> expireIfStale({
    required String coupleId,
    required String gameId,
    DateTime? now,
  }) async {
    if (_blank(coupleId) || _blank(gameId) || !isUsingFirebase) {
      return false;
    }
    try {
      return await _db.runTransaction<bool>((tx) async {
        final ref = _game(coupleId.trim(), gameId.trim());
        final snap = await tx.get(ref);
        final data = snap.data();
        if (!snap.exists || data == null) {
          return false;
        }
        final game = RpsGame.fromFirestore(snap.id, data);
        if (!game.isInviteStale(now: now)) {
          return false;
        }
        tx.update(ref, <String, dynamic>{
          'status': RpsGameStatus.expired.key,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (e) {
      debugPrint('RpsGameService.expireIfStale failed: $e');
      return false;
    }
  }

  /// "Nhắc người ấy" (2026-09-14 no-skip rule): asks the `nudgeRpsPlayer`
  /// callable to push + inbox `rps_moved` to the partner who hasn't thrown.
  /// The server owns every rule (I have thrown, the partner hasn't, 60s since
  /// `lastNudgeAt`) and answers `{ok}` or `{ok:false, reason, retryAfterMs}`
  /// instead of throwing. Fail-soft: any error → [RpsNudgeStatus.failed].
  ///
  /// (The retired `finishRpsGame` callable is gone from the backend — a round
  /// only ends when both hands are in, via the `resolveRpsGame` trigger.)
  Future<RpsNudgeResult> nudgePartner({
    required String coupleId,
    required String gameId,
  }) async {
    if (_blank(coupleId) || _blank(gameId) || !isUsingFirebase) {
      return const RpsNudgeResult(RpsNudgeStatus.failed);
    }
    try {
      final response = await _fns
          .httpsCallable(
            _nudgeCallable,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
          )
          .call<dynamic>(<String, dynamic>{
            'coupleId': coupleId.trim(),
            'gameId': gameId.trim(),
          });
      final result = RpsNudgeResult.fromResponse(response.data);
      if (!result.isSent) {
        debugPrint('RpsGameService.nudgePartner declined: ${result.status}');
      }
      return result;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('RpsGameService.nudgePartner ${e.code}: ${e.message}');
      return const RpsNudgeResult(RpsNudgeStatus.failed);
    } catch (e) {
      debugPrint('RpsGameService.nudgePartner failed: $e');
      return const RpsNudgeResult(RpsNudgeStatus.failed);
    }
  }

  /// All-time tally via three `count()` aggregations (total finished · wins
  /// · draws; losses = remainder) — the Profile badge must show the FULL
  /// record, not just the 30 games the history page has loaded. Equality-only
  /// filters, so no extra composite index. Null on any failure (caller keeps
  /// its shimmer / previous value).
  Future<RpsScore?> countScore({
    required String coupleId,
    required String myUid,
  }) async {
    if (_blank(coupleId) || _blank(myUid) || !isUsingFirebase) {
      return null;
    }
    try {
      final finished = _games(coupleId.trim())
          .where('type', isEqualTo: RpsGame.typeKey)
          .where('status', isEqualTo: RpsGameStatus.finished.key);
      final results = await Future.wait(<Future<AggregateQuerySnapshot>>[
        finished.count().get(),
        finished
            .where('result.winnerUid', isEqualTo: myUid.trim())
            .count()
            .get(),
        finished.where('result.winnerUid', isNull: true).count().get(),
      ]);
      final total = results[0].count ?? 0;
      final wins = results[1].count ?? 0;
      final draws = results[2].count ?? 0;
      final losses = total - wins - draws;
      return RpsScore(
        wins: wins,
        draws: draws,
        losses: losses < 0 ? 0 : losses,
      );
    } catch (e) {
      debugPrint('RpsGameService.countScore failed: $e');
      return null;
    }
  }

  /// One page of finished games, newest first. Needs the composite index
  /// `(type ASC, status ASC, finishedAt DESC)`. Empty page on any failure.
  Future<RpsHistoryPage> fetchHistoryPage({
    required String coupleId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (_blank(coupleId) || !isUsingFirebase) {
      return const RpsHistoryPage.empty();
    }
    try {
      Query<Map<String, dynamic>> query = _games(coupleId.trim())
          .where('type', isEqualTo: RpsGame.typeKey)
          .where('status', isEqualTo: RpsGameStatus.finished.key)
          .orderBy('finishedAt', descending: true);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.limit(limit).get();
      final docs = snapshot.docs;
      return RpsHistoryPage(
        items: docs
            .map((doc) => RpsGame.fromFirestore(doc.id, doc.data()))
            .toList(growable: false),
        lastDoc: docs.isEmpty ? null : docs.last,
        hasMore: docs.length >= limit,
      );
    } catch (e) {
      debugPrint('RpsGameService.fetchHistoryPage failed: $e');
      return const RpsHistoryPage.empty();
    }
  }
}
