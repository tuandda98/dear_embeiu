import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/money.dart';
import 'firebase_bootstrap_service.dart';

/// What happened to a write: confirmed by the server, or (offline / slow
/// network) sitting in Firestore's queue and sent later (D21).
enum MoneyWriteOutcome { saved, queued }

/// A queued write the server refused later (rules: someone edited the entry
/// first, the couple changed…). The provider surfaces it as a snackbar.
class MoneyWriteError {
  const MoneyWriteError(this.book, this.docId, this.error);

  final MoneyBookKind book;
  final String docId;
  final Object error;

  bool get isPermissionDenied =>
      error is FirebaseException &&
      (error as FirebaseException).code == 'permission-denied';
}

/// One write inside a [MoneyService.commit] batch.
typedef MoneyBatchOp = void Function(WriteBatch batch);

/// Firestore side of one money book (feature expenses, D1): the SAME code
/// serves the own book (`users/{uid}`) and the shared book
/// (`couples/{coupleId}`, every doc pinned to [memberUids]). No Hive
/// fallback: money lives in Firestore, offline works through its cache +
/// write queue.
class MoneyService {
  MoneyService._(this.kind, this.book, this.memberUids, this._db);

  factory MoneyService.own(String uid, {FirebaseFirestore? firestore}) {
    final db = firestore ?? FirebaseFirestore.instance;
    return MoneyService._(
      MoneyBookKind.own,
      db.collection('users').doc(uid),
      const <String>[],
      db,
    );
  }

  factory MoneyService.shared(
    String coupleId,
    List<String> memberUids, {
    FirebaseFirestore? firestore,
  }) {
    final db = firestore ?? FirebaseFirestore.instance;
    return MoneyService._(
      MoneyBookKind.shared,
      db.collection('couples').doc(coupleId),
      List<String>.unmodifiable(memberUids),
      db,
    );
  }

  final MoneyBookKind kind;

  /// `users/{uid}` or `couples/{coupleId}`.
  final DocumentReference<Map<String, dynamic>> book;

  /// The pair this shared book shows (`couple.memberIds`); empty = own book.
  final List<String> memberUids;
  final FirebaseFirestore _db;

  /// Past this a write counts as "queued" (the sheet closes either way).
  static const Duration writeTimeout = Duration(seconds: 4);

  static bool get isAvailable =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  bool get isShared => kind == MoneyBookKind.shared;

  CollectionReference<Map<String, dynamic>> get _wallets =>
      book.collection(kMoneyWallets);
  CollectionReference<Map<String, dynamic>> get _txs =>
      book.collection(kMoneyTx);
  CollectionReference<Map<String, dynamic>> get _budgets =>
      book.collection(kMoneyBudgets);
  DocumentReference<Map<String, dynamic>> get _meta =>
      book.collection(kMoneyMeta).doc(kMoneyMetaDoc);

  /// Shared reads always filter on the pair: the rules can prove access from
  /// it, and it drops a previous pair's entries in the same couple (D3).
  Query<Map<String, dynamic>> _pair(Query<Map<String, dynamic>> q) =>
      isShared ? q.where('memberUids', isEqualTo: memberUids) : q;

  String newTxId() => _txs.doc().id;
  String newWalletId() => _wallets.doc().id;

  // ---- reads ---------------------------------------------------------------

  /// Wallets + whether this list came from the server (an empty list from
  /// the cache does not mean "first run").
  Stream<({List<MoneyWallet> wallets, bool fromServer})> watchWallets() =>
      _pair(_wallets).snapshots().map(
        (s) => (
          wallets: [
            for (final d in s.docs) ?MoneyWallet.fromDoc(d.id, d.data()),
          ]..sort((a, b) => a.order.compareTo(b.order)),
          fromServer: !s.metadata.isFromCache,
        ),
      );

  /// Entries dated from [from] (inclusive, 'YYYY-MM-DD'; null = all), newest
  /// first, live, each flagged `pending` while it waits for the network.
  Stream<({List<MoneyTx> txs, bool fromServer})> watchTx({
    String? from,
    String? to,
  }) {
    Query<Map<String, dynamic>> q = _pair(_txs);
    if (from != null) q = q.where('date', isGreaterThanOrEqualTo: from);
    if (to != null) q = q.where('date', isLessThanOrEqualTo: to);
    return q
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((s) => (txs: _parseTx(s), fromServer: !s.metadata.isFromCache));
  }

  static List<MoneyTx> _parseTx(QuerySnapshot<Map<String, dynamic>> s) => [
    for (final d in s.docs)
      ?MoneyTx.fromDoc(d.id, d.data(), pending: d.metadata.hasPendingWrites),
  ];

  /// One-shot range read for search (newest first, capped at [limit]).
  Future<List<MoneyTx>> fetchTx({
    required String from,
    required String to,
    int limit = 2000,
  }) async {
    final s = await _pair(_txs)
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return _parseTx(s);
  }

  /// The other half of a linked pair when it is not in memory.
  Future<MoneyTx?> findByLinkId(String linkId) async {
    final s = await _pair(
      _txs,
    ).where('linkId', isEqualTo: linkId).limit(1).get();
    return s.docs.isEmpty ? null : _parseTx(s).firstOrNull;
  }

  Stream<List<MoneyBudget>> watchBudgets() => _budgets.snapshots().map(
    (s) => [for (final d in s.docs) ?MoneyBudget.fromDoc(d.id, d.data())],
  );

  Stream<MoneyMeta> watchMeta() =>
      _meta.snapshots().map((s) => MoneyMeta.fromDoc(s.data()));

  Future<int> _sum(Query<Map<String, dynamic>> q) async {
    final s = await q.aggregate(sum('amount')).get();
    return (s.getSum('amount') ?? 0).round();
  }

  /// Σ in − Σ out per wallet over the whole history: 2 aggregate `sum()`
  /// queries per wallet, server-only (throws offline) (D19).
  Future<Map<String, int>> walletNetSums(Iterable<String> walletIds) async {
    final ids = walletIds.toList();
    final sums = await Future.wait([
      for (final id in ids) ...[
        _sum(_pair(_txs).where('inWalletId', isEqualTo: id)),
        _sum(_pair(_txs).where('outWalletId', isEqualTo: id)),
      ],
    ]);
    return {
      for (var i = 0; i < ids.length; i++)
        ids[i]: sums[2 * i] - sums[2 * i + 1],
    };
  }

  /// Spent / earned in one month (trend chart), server-only.
  Future<(int expense, int income)> monthSums(String from, String to) async {
    Query<Map<String, dynamic>> range(String type) => _pair(_txs)
        .where('type', isEqualTo: type)
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to);
    final r = await Future.wait([
      _sum(range('expense')),
      _sum(range('income')),
    ]);
    return (r[0], r[1]);
  }

  // ---- writes --------------------------------------------------------------

  /// Commits [ops] in ONE batch (both books when a pair is linked, D11).
  /// Returns [MoneyWriteOutcome.queued] when the server did not answer
  /// within [writeTimeout]; a later refusal goes to [onLateError].
  Future<MoneyWriteOutcome> commit(
    List<MoneyBatchOp> ops, {
    required String docId,
    void Function(MoneyWriteError error)? onLateError,
  }) async {
    final batch = _db.batch();
    for (final op in ops) {
      op(batch);
    }
    final write = batch.commit();
    try {
      await write.timeout(writeTimeout);
      return MoneyWriteOutcome.saved;
    } on TimeoutException {
      unawaited(
        write.catchError(
          (Object e) => onLateError?.call(MoneyWriteError(kind, docId, e)),
        ),
      );
      return MoneyWriteOutcome.queued;
    }
  }

  MoneyBatchOp createTxOp(MoneyTx tx, {required String uid}) {
    if (!tx.isWellFormed || (tx.memberUids.isNotEmpty) != isShared) {
      throw ArgumentError.value(tx.id, 'tx', 'not a valid ${kind.name} entry');
    }
    final data = tx.toCreateMap(uid: uid);
    return (b) => b.set(_txs.doc(tx.id), data);
  }

  /// [updated] carries the new editable fields of [old]. editCount is set to
  /// the absolute `old + 1` (not an increment) so the rules refuse the second
  /// of two edits made from the same version (overview §8).
  MoneyBatchOp updateTxOp(MoneyTx old, MoneyTx updated, {required String uid}) {
    if (!updated.isWellFormed) {
      throw ArgumentError.value(updated.id, 'tx', 'not a valid entry');
    }
    final data = <String, dynamic>{
      ...updated.editableFields(),
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'editCount': old.editCount + 1,
    };
    return (b) => b.update(_txs.doc(old.id), data);
  }

  MoneyBatchOp deleteTxOp(String id) =>
      (b) => b.delete(_txs.doc(id));

  Future<MoneyWriteOutcome> createWallets(
    List<MoneyWallet> wallets, {
    required String uid,
  }) {
    for (final w in wallets) {
      if (!w.isWellFormed) throw ArgumentError.value(w.name, 'wallet');
    }
    return commit([
      for (final w in wallets)
        (b) => b.set(_wallets.doc(w.id), w.toCreateMap(uid: uid)),
    ], docId: wallets.isEmpty ? '' : wallets.first.id);
  }

  /// Name, emoji, colour, opening balance, archive flag, goal… (never type).
  Future<MoneyWriteOutcome> updateWallet(
    String id,
    Map<String, dynamic> fields,
  ) => commit([
    (b) => b.update(_wallets.doc(id), <String, dynamic>{
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  ], docId: id);

  /// One budget per category ('' = total) — [id] given = edit.
  Future<MoneyWriteOutcome> setBudget({
    String? id,
    required String categoryId,
    required int amount,
    required String uid,
  }) {
    if (amount < 1 || amount > 10000000000) {
      throw ArgumentError.value(amount, 'amount');
    }
    final ref = id == null ? _budgets.doc() : _budgets.doc(id);
    return commit([
      (b) => id == null
          ? b.set(ref, <String, dynamic>{
              'categoryId': categoryId,
              'amount': amount,
              'createdBy': uid,
              'createdAt': FieldValue.serverTimestamp(),
            })
          : b.update(ref, <String, dynamic>{
              'amount': amount,
              'updatedAt': FieldValue.serverTimestamp(),
            }),
    ], docId: ref.id);
  }

  Future<MoneyWriteOutcome> deleteBudget(String id) =>
      commit([(b) => b.delete(_budgets.doc(id))], docId: id);

  /// Merge-writes the category meta (custom list, overrides, hidden ids,
  /// default wallet).
  Future<MoneyWriteOutcome> setMeta(Map<String, dynamic> fields) => commit([
    (b) => b.set(_meta, <String, dynamic>{
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  ], docId: kMoneyMetaDoc);
}
