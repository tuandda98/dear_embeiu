import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../l10n/app_l10n.dart';
import '../models/caro_game.dart';
import 'firebase_bootstrap_service.dart';

/// What `caroAction` answered (overview §6.2). Business refusals come back as
/// `{ok:false, reason}`; [network] / [failed] are client-side.
enum CaroActionStatus {
  ok,
  notPlaying,
  notYourTurn,

  /// The board moved on since my screen (wrong `moveNo`, a second stone
  /// already there for `cancel`, my turn now for `nudge`).
  stale,
  occupied,
  outOfRange,

  /// `start` while a game is open — [CaroActionResult.gameId] is that game.
  alreadyOpen,
  cooldown,

  /// `expire` before 7 days without a move.
  tooEarly,
  notPlayer,
  noPartner,

  /// Offline / timeout — nothing was decided, the same call can be retried.
  network,

  /// Auth, bad input, server error.
  failed,
}

class CaroActionResult {
  const CaroActionResult(
    this.status, {
    this.gameId,
    this.gameStatus,
    this.cellsLength,
    this.retryAfter,
  });

  final CaroActionStatus status;
  final String? gameId;
  final CaroGameStatus? gameStatus;
  final int? cellsLength;

  /// `cooldown` / `tooEarly`: how long until the server allows it.
  final Duration? retryAfter;

  bool get isOk => status == CaroActionStatus.ok;

  /// The server refused because my view is out of date (UI: "Bàn vừa đổi").
  bool get isStaleBoard =>
      status == CaroActionStatus.stale ||
      status == CaroActionStatus.notYourTurn ||
      status == CaroActionStatus.occupied;

  static const Map<String, CaroActionStatus> _reasons =
      <String, CaroActionStatus>{
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
      };

  /// Maps the callable payload.
  static CaroActionResult fromResponse(dynamic data) {
    if (data is! Map) {
      return const CaroActionResult(CaroActionStatus.failed);
    }
    final id = '${data['gameId'] ?? ''}'.trim();
    final rawRetry = data['retryAfterMs'];
    final retryMs = rawRetry is num ? rawRetry.round() : null;
    final status = data['ok'] == true
        ? CaroActionStatus.ok
        : (_reasons['${data['reason'] ?? ''}'.trim()] ??
              CaroActionStatus.failed);
    final length = data['cellsLength'];
    return CaroActionResult(
      status,
      gameId: id.isEmpty ? null : id,
      gameStatus: data['status'] == null
          ? null
          : CaroGameStatus.fromKey(data['status']),
      cellsLength: length is num ? length.toInt() : null,
      retryAfter: retryMs == null || retryMs <= 0
          ? null
          : Duration(milliseconds: retryMs),
    );
  }
}

/// One page of finished games (history screen), cursor like rps.
class CaroHistoryPage {
  const CaroHistoryPage({
    required this.items,
    this.lastDoc,
    this.hasMore = false,
    this.failed = false,
  });

  const CaroHistoryPage.empty({this.failed = false})
    : items = const <CaroGame>[],
      lastDoc = null,
      hasMore = false;

  final List<CaroGame> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  /// The query failed (UI: "Chưa tải thêm được ván cũ." + retry).
  final bool failed;
}

/// Firestore + callable access for caro (feature caro-game): games live in
/// `couples/{coupleId}/games` with `type == 'caro'`, the pointer + score in
/// `couples/{coupleId}/caroState/main`. Every change goes through the
/// `caroAction` callable — the rules let the client write only its own
/// `presence` key. Fail-soft like [RpsGameService]: off Firebase streams are
/// empty and writes return false / [CaroActionStatus.failed].
class CaroGameService {
  CaroGameService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore,
      _functions = functions;

  static const String _region = 'us-central1';
  static const String _callable = 'caroAction';

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

  static bool _blank(String s) => s.trim().isEmpty;

  static CaroGame? _parse(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (!snap.exists || data == null || data['type'] != CaroGame.typeKey) {
      return null;
    }
    return CaroGame.fromFirestore(snap.id, data);
  }

  /// Streams `caroState/main` ([CaroState.empty] while the doc is absent).
  Stream<CaroState> watchState(String coupleId) {
    if (_blank(coupleId) || !isUsingFirebase) {
      return Stream<CaroState>.value(CaroState.empty);
    }
    return _db
        .collection('couples')
        .doc(coupleId.trim())
        .collection('caroState')
        .doc('main')
        .snapshots()
        .map((snap) {
          final data = snap.data();
          return (snap.exists && data != null)
              ? CaroState.fromFirestore(data)
              : CaroState.empty;
        })
        // Logged AND passed on: Home shows "Thử lại" when nothing loaded.
        .transform(
          StreamTransformer<CaroState, CaroState>.fromHandlers(
            handleError: (e, st, sink) {
              debugPrint('CaroGameService.watchState error: $e');
              sink.addError(e, st);
            },
          ),
        );
  }

  /// Streams one caro game (null when missing / not caro / unreadable).
  Stream<CaroGame?> watchGame(String coupleId, String gameId) {
    if (_blank(coupleId) || _blank(gameId) || !isUsingFirebase) {
      return Stream<CaroGame?>.value(null);
    }
    return _game(
      coupleId.trim(),
      gameId.trim(),
    ).snapshots().map(_parse).handleError((Object e) {
      debugPrint('CaroGameService.watchGame error: $e');
    });
  }

  Future<CaroGame?> fetchGame(String coupleId, String gameId) async {
    if (_blank(coupleId) || _blank(gameId) || !isUsingFirebase) {
      return null;
    }
    try {
      return _parse(await _game(coupleId.trim(), gameId.trim()).get());
    } catch (e) {
      debugPrint('CaroGameService.fetchGame failed: $e');
      return null;
    }
  }

  /// `presence.{uid} = serverTimestamp` — the only client write the rules
  /// allow on a caro game. Fire-and-forget safe.
  Future<bool> heartbeat(String coupleId, String gameId, String uid) =>
      _presence(coupleId, gameId, uid, FieldValue.serverTimestamp());

  /// Drops my presence key (left the screen / app in the background), so the
  /// partner's next move pushes me right away instead of after 45s.
  Future<bool> clearPresence(String coupleId, String gameId, String uid) =>
      _presence(coupleId, gameId, uid, FieldValue.delete());

  Future<bool> _presence(
    String coupleId,
    String gameId,
    String uid,
    FieldValue value,
  ) async {
    if (_blank(coupleId) || _blank(gameId) || _blank(uid) || !isUsingFirebase) {
      return false;
    }
    try {
      await _game(
        coupleId.trim(),
        gameId.trim(),
      ).update(<String, dynamic>{'presence.${uid.trim()}': value});
      return true;
    } catch (e) {
      debugPrint('CaroGameService.presence failed: $e');
      return false;
    }
  }

  /// Calls `caroAction` (`op` = start · move · resign · cancel · expire ·
  /// nudge). Sends the app's language as `lang` so a server error message
  /// reads in it.
  Future<CaroActionResult> action({
    required String coupleId,
    required String op,
    String? gameId,
    int? cell,
    int? moveNo,
    CaroRule? rule,
    String? rematchOf,
  }) async {
    if (_blank(coupleId) || !isUsingFirebase) {
      return const CaroActionResult(CaroActionStatus.failed);
    }
    try {
      final response = await _fns
          .httpsCallable(
            _callable,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
          )
          .call<dynamic>(<String, dynamic>{
            'coupleId': coupleId.trim(),
            'op': op,
            if (gameId != null && !_blank(gameId)) 'gameId': gameId.trim(),
            'cell': ?cell,
            'moveNo': ?moveNo,
            if (rule != null) 'rule': rule.key,
            if (rematchOf != null && !_blank(rematchOf))
              'rematchOf': rematchOf.trim(),
            'lang': _lang,
          });
      final result = CaroActionResult.fromResponse(response.data);
      if (!result.isOk) {
        debugPrint('CaroGameService.$op declined: ${result.status}');
      }
      return result;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('CaroGameService.$op ${e.code}: ${e.message}');
      return CaroActionResult(
        e.code == 'unavailable' || e.code == 'deadline-exceeded'
            ? CaroActionStatus.network
            : CaroActionStatus.failed,
      );
    } on TimeoutException {
      return const CaroActionResult(CaroActionStatus.network);
    } catch (e) {
      debugPrint('CaroGameService.$op failed: $e');
      return const CaroActionResult(CaroActionStatus.failed);
    }
  }

  static String get _lang {
    final code = AppL10n.strings.localeName
        .split(RegExp('[_-]'))
        .first
        .trim()
        .toLowerCase();
    return code == 'en' ? 'en' : 'vi';
  }

  /// One page of finished games, newest first — the rps index
  /// `(type ASC, status ASC, finishedAt DESC)` covers it.
  Future<CaroHistoryPage> fetchHistoryPage({
    required String coupleId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (_blank(coupleId) || !isUsingFirebase) {
      return const CaroHistoryPage.empty();
    }
    try {
      Query<Map<String, dynamic>> query = _games(coupleId.trim())
          .where('type', isEqualTo: CaroGame.typeKey)
          .where('status', isEqualTo: CaroGameStatus.finished.key)
          .orderBy('finishedAt', descending: true);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.limit(limit).get();
      final docs = snapshot.docs;
      return CaroHistoryPage(
        items: docs
            .map((doc) => CaroGame.fromFirestore(doc.id, doc.data()))
            .toList(growable: false),
        lastDoc: docs.isEmpty ? null : docs.last,
        hasMore: docs.length >= limit,
      );
    } catch (e) {
      debugPrint('CaroGameService.fetchHistoryPage failed: $e');
      return const CaroHistoryPage.empty(failed: true);
    }
  }
}
