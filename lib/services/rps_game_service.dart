import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/rps_game.dart';
import 'firebase_bootstrap_service.dart';

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
/// may only carry MY uid. `finishedAt`/`result` are Admin-SDK-only.
class RpsGameService {
  RpsGameService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore,
      _functions = functions;

  static const String _region = 'us-central1';
  static const String _finishCallable = 'finishRpsGame';

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
  /// doc — an invite past its TTL nobody flipped to `expired`, a round nobody
  /// settled — and the provider picks the first LIVE one with
  /// [RpsGame.pickOpen] against server time. Needs the composite index
  /// `(type ASC, status ASC, createdAt DESC)`.
  Stream<List<RpsGame>> watchOpenGames(String coupleId, {int limit = 5}) {
    if (_blank(coupleId) || !isUsingFirebase) {
      return Stream<List<RpsGame>>.value(const <RpsGame>[]);
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
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => RpsGame.fromFirestore(doc.id, doc.data()))
              .toList(growable: false),
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
  /// a second attempt is denied by the rules, as is one after the deadline).
  /// Returns false when the write was refused, so the UI can un-lock.
  ///
  /// [timeout] (Tester RPS-8): offline, a Firestore write never completes
  /// until the network returns, which used to leave the caller hanging. Past
  /// the round's deadline the answer can only be "refused" anyway, so give up
  /// after [timeout] and report false. The queued write may still reach the
  /// server later — the rules then reject it (`request.time` past 7s).
  Future<bool> submitMove({
    required String coupleId,
    required String gameId,
    required String uid,
    required RpsChoice choice,
    Duration? timeout,
  }) async {
    if (_blank(coupleId) ||
        _blank(gameId) ||
        _blank(uid) ||
        !choice.isHand ||
        !isUsingFirebase) {
      return false;
    }
    try {
      final write = _move(coupleId.trim(), gameId.trim(), uid.trim()).set(
        <String, dynamic>{
          'choice': choice.key,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      await (timeout == null ? write : write.timeout(timeout));
      return true;
    } on TimeoutException {
      debugPrint('RpsGameService.submitMove timed out after $timeout');
      return false;
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

  /// Asks the `finishRpsGame` callable to settle a `playing` game whose
  /// deadline (+grace) has passed with a hand missing. Idempotent server-side;
  /// both phones may call it. Fail-soft: false on any error (the watcher will
  /// still see `finished` if the other phone got through).
  Future<bool> finishViaCallable({
    required String coupleId,
    required String gameId,
  }) async {
    if (_blank(coupleId) || _blank(gameId) || !isUsingFirebase) {
      return false;
    }
    try {
      final response = await _fns.httpsCallable(_finishCallable).call<dynamic>(
        <String, dynamic>{'coupleId': coupleId.trim(), 'gameId': gameId.trim()},
      );
      // The callable answers `{ok:false, reason:'too_early'|'not_playing'}`
      // instead of throwing when it declines — surface that as false so the
      // provider's retry cadence (3s) keeps polling until the server agrees.
      final data = response.data;
      if (data is Map && data['ok'] == false) {
        debugPrint(
          'RpsGameService.finishViaCallable declined: ${data['reason']}',
        );
        return false;
      }
      return true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('RpsGameService.finishViaCallable ${e.code}: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('RpsGameService.finishViaCallable failed: $e');
      return false;
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
