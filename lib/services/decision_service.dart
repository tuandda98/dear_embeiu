import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/decision.dart';
import 'firebase_bootstrap_service.dart';

/// One page of the "Đã quay" history (newest first).
class DecisionPage {
  const DecisionPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  const DecisionPage.empty()
    : items = const <Decision>[],
      lastDoc = null,
      hasMore = false;

  final List<Decision> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

/// What happened to a "Chốt": saved by the server, or (custom only) queued by
/// Firestore offline and sent once the network is back (D19).
enum DecisionCommitOutcome { saved, queued }

/// Firestore side of the wheel (feature decision-wheel):
/// `couples/{coupleId}/decisions/{id}` — see [Decision] / `firestore.rules`.
///
/// No local (Hive) fallback: the wheel only lives on Home, which needs a
/// couple, and a pick only means something once it reaches the partner.
class DecisionService {
  DecisionService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// How long a commit may take before it counts as "offline".
  static const Duration commitTimeout = Duration(seconds: 10);

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Transactions whose caller already got a timeout (doc path → result +
  /// the still-running Future). `.timeout` does not cancel a transaction, so
  /// it may still land once the network is back; the next commit of the same
  /// doc ("Thử lại") waits for it instead of bumping `spins` a second time.
  final Map<String, ({String result, Future<int> spins})> _timedOut = {};

  CollectionReference<Map<String, dynamic>> _collection(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('decisions');

  static List<Decision> _parse(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) => [for (final doc in docs) ?Decision.fromDoc(doc.id, doc.data())];

  /// Every pick dated [dateKey] (eat + go + custom, ≤ 12 docs). One equality
  /// filter → the default single-field index, no composite index.
  Stream<List<Decision>> watchDay(String coupleId, String dateKey) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return Stream<List<Decision>>.value(const <Decision>[]);
    }
    return _collection(
      coupleId,
    ).where('date', isEqualTo: dateKey).snapshots().map((s) => _parse(s.docs));
  }

  /// Everything created in the last [days] days — feeds the pool exclusion
  /// (7/14 days), the typed-in picks (90 days) and the top 5. Capped at 1000
  /// docs (12/day worst case ≈ 1080 for 90 days, real use is a handful).
  Future<List<Decision>> fetchRecent(String coupleId, {int days = 90}) async {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return const <Decision>[];
    }
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _collection(coupleId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(1000)
        .get();
    return _parse(snap.docs);
  }

  /// One history page, newest first (care-timeline recipe). Throws so the
  /// screen can show its error state.
  Future<DecisionPage> fetchPage({
    required String coupleId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return const DecisionPage.empty();
    }
    Query<Map<String, dynamic>> query = _collection(
      coupleId,
    ).orderBy('createdAt', descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.limit(limit).get();
    return DecisionPage(
      items: _parse(snap.docs),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  /// Writes a pick.
  ///
  /// - eat/go, or a custom re-spin ([existingId] set): a transaction — create
  ///   the doc, or bump it (`spins + 1`) when it exists. Two phones locking in
  ///   at once therefore make one doc, the later one a re-spin. Transactions
  ///   don't run offline: past [commitTimeout] this throws and the screen
  ///   offers "Thử lại" (D19).
  /// - a new custom pick: a plain `set` on an auto id, which Firestore queues
  ///   offline → [DecisionCommitOutcome.queued].
  ///
  /// Returns the doc id written and the `spins` it now holds (> 1 = the
  /// transaction bumped an existing doc). Throws on failure.
  Future<(String, DecisionCommitOutcome, int)> commit({
    required String coupleId,
    required String uid,
    required DecisionKind kind,
    required String dateKey,
    required String result,
    String resultId = '',
    String filter = '',
    String question = '',
    List<String> options = const <String>[],
    String? existingId,
  }) async {
    if (coupleId.trim().isEmpty || uid.trim().isEmpty || !isUsingFirebase) {
      throw StateError('decision-unavailable');
    }
    final cleanResult = result.trim();
    if (cleanResult.isEmpty ||
        decisionTextSize(cleanResult) > kDecisionResultMax) {
      throw ArgumentError.value(result, 'result');
    }
    if (decisionTextSize(question.trim()) > kDecisionQuestionMax) {
      throw ArgumentError.value(question, 'question');
    }

    if (kind == DecisionKind.custom && existingId == null) {
      final ref = _collection(coupleId).doc();
      final write = ref.set(<String, dynamic>{
        'kind': kind.name,
        'date': dateKey,
        'question': question.trim(),
        'options': options,
        'filter': '',
        'result': cleanResult,
        'resultId': '',
        'spins': 1,
        'byUserId': uid,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      try {
        await write.timeout(commitTimeout);
        return (ref.id, DecisionCommitOutcome.saved, 1);
      } on TimeoutException {
        // Offline: the write is in Firestore's queue and goes out later.
        unawaited(write.catchError((_) {}));
        return (ref.id, DecisionCommitOutcome.queued, 1);
      }
    }

    final ref = _collection(
      coupleId,
    ).doc(existingId ?? decisionDocId(kind, dateKey));
    final earlier = _timedOut.remove(ref.path);
    if (earlier != null) {
      try {
        final spins = await earlier.spins.timeout(commitTimeout);
        // It landed: same pick → done, no second write. Another pick → a
        // real re-spin, written below.
        if (earlier.result == cleanResult) {
          return (ref.id, DecisionCommitOutcome.saved, spins);
        }
      } on TimeoutException {
        _timedOut[ref.path] = earlier; // still offline, keep waiting on it
        rethrow;
      } catch (_) {
        // The earlier one failed for good → write afresh.
      }
    }
    final transaction = _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final spins = (snap.data()?['spins'] as num?)?.toInt() ?? 1;
        tx.update(ref, <String, dynamic>{
          'result': cleanResult,
          'resultId': resultId,
          'spins': spins + 1,
          'byUserId': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return spins + 1;
      } else {
        tx.set(ref, <String, dynamic>{
          'kind': kind.name,
          'date': dateKey,
          'question': question.trim(),
          'options': options,
          'filter': filter,
          'result': cleanResult,
          'resultId': resultId,
          'spins': 1,
          'byUserId': uid,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return 1;
      }
    });
    try {
      final spins = await transaction.timeout(commitTimeout);
      return (ref.id, DecisionCommitOutcome.saved, spins);
    } on TimeoutException {
      unawaited(transaction.then((_) {}, onError: (_) {}));
      _timedOut[ref.path] = (result: cleanResult, spins: transaction);
      rethrow;
    }
  }
}
