import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/money_categories.dart';
import '../l10n/app_l10n.dart';
import '../models/money.dart';
import '../services/money_service.dart';
import '../utils/money_math.dart';

/// Live state of one book. Own book: entries of the last ~45 days (always
/// the whole current month) + wallet balances from aggregate `sum()`
/// (cached in Hive). Shared book: the pair's WHOLE history — the couple
/// balance adds up from the very first entry (D7), and at 15–40 entries a
/// month that is small (overview §8 accepts it for mốc A) — so its wallet
/// balances, trend and search come straight from that list, offline too.
class MoneyBookState {
  MoneyBookState(this.service);

  final MoneyService service;
  MoneyBookKind get kind => service.kind;

  List<MoneyWallet> wallets = const <MoneyWallet>[];

  /// A server snapshot of the wallets arrived (an empty cached list must not
  /// open the first-run screen).
  bool walletsFromServer = false;
  List<MoneyTx> txs = const <MoneyTx>[];
  bool txLoaded = false;

  /// Own book: first date of the live window.
  String? windowFrom;
  List<MoneyBudget> budgets = const <MoneyBudget>[];
  MoneyMeta meta = MoneyMeta.empty;

  /// Own book: Σ in − Σ out per wallet (server aggregate, or the Hive copy).
  Map<String, int> netSums = const <String, int>{};
  DateTime? netSumsAt;

  /// The last aggregate failed (offline): balances are cache + pending.
  bool netSumsStale = false;

  /// Last time the entries came from the server ("số lúc 11:58").
  DateTime? lastSyncAt;
  Object? loadError;

  /// Own book, a month older than the live window.
  String? viewMonth;
  List<MoneyTx>? viewTxs;

  final Map<String, MoneyMonthTotals> trendCache = {};
  final List<StreamSubscription<Object?>> subs = [];
  StreamSubscription<Object?>? txSub;
  StreamSubscription<Object?>? viewSub;
  Timer? sumsDebounce;
  MoneyCategoryIndex? _index;
  MoneyMeta? _indexMeta;

  bool get isShared => kind == MoneyBookKind.shared;

  /// Categories with this book's tweaks, names in the current app language.
  MoneyCategoryIndex get categories {
    if (_index == null || !identical(_indexMeta, meta)) {
      _index = MoneyCategoryIndex(
        resolveMoneyCategories(meta, AppL10n.strings),
      );
      _indexMeta = meta;
    }
    return _index!;
  }

  void dispose() {
    for (final s in subs) {
      s.cancel();
    }
    subs.clear();
    txSub?.cancel();
    viewSub?.cancel();
    sumsDebounce?.cancel();
  }
}

/// Sổ tiền (feature expenses): the own book (wired at sign-in, works with or
/// without a partner) and the shared book (only while the couple is active).
/// `session_resolver` calls [watchOwn] / [watchShared] / [clearShared] /
/// [clear]; HomeScreen re-arms [watchShared] when the partner joins
/// mid-session (stage 2).
///
/// Every number goes through [MoneyMath]. Writes go through [MoneyService]
/// in one batch (both books when an entry is linked, D11) and return as soon
/// as Firestore queued them; a later refusal lands in [lastWriteError].
class MoneyProvider extends ChangeNotifier {
  MoneyProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Undo window for a delete (D13): nothing is sent before it ends.
  static const Duration deleteDelay = Duration(seconds: 5);
  static const String _cacheBox = 'money_cache';

  String? _uid;
  MoneyBookState? _own;
  MoneyBookState? _shared;
  String? _sharedCoupleId;
  MoneyWriteError? _lastWriteError;

  final Map<
    String,
    ({MoneyBookKind kind, MoneyTx tx, MoneyTx? linked, Timer timer})
  >
  _pendingDeletes = {};

  String? get uid => _uid;
  MoneyBookState? get own => _own;
  MoneyBookState? get shared => _shared;
  bool get hasShared => _shared != null;
  MoneyBookState? book(MoneyBookKind kind) =>
      kind == MoneyBookKind.own ? _own : _shared;

  /// The partner's uid in the shared book ('' when there is none).
  String get partnerUid => _shared == null
      ? ''
      : _shared!.service.memberUids.firstWhere(
          (id) => id != _uid,
          orElse: () => '',
        );

  /// A queued write the server refused later; the UI shows it once and calls
  /// [acknowledgeWriteError].
  MoneyWriteError? get lastWriteError => _lastWriteError;

  void acknowledgeWriteError() {
    _lastWriteError = null;
  }

  void _onLateError(MoneyWriteError e) {
    _lastWriteError = e;
    notifyListeners();
  }

  /// Today's date key on this phone (default date of a new entry).
  String get today => MoneyMath.dateKey(_clock());
  String get _thisMonth => MoneyMath.monthKey(_clock());

  // ---- lifecycle -----------------------------------------------------------

  void watchOwn(String uid) {
    if (uid.trim().isEmpty || !MoneyService.isAvailable) {
      clear();
      return;
    }
    if (_uid == uid && _own != null) return;
    if (_uid != uid) clear();
    _uid = uid;
    final state = MoneyBookState(MoneyService.own(uid));
    _own = state;
    _listen(state);
    unawaited(_loadSumsCache(state));
    notifyListeners();
  }

  /// [memberIds] = the couple's `memberIds` (order kept — it is what every
  /// shared doc pins). Only call while the couple is active (2 members).
  void watchShared(String coupleId, List<String> memberIds, String uid) {
    if (coupleId.trim().isEmpty ||
        memberIds.length != 2 ||
        !memberIds.contains(uid) ||
        !MoneyService.isAvailable) {
      clearShared();
      return;
    }
    final current = _shared;
    if (current != null &&
        _sharedCoupleId == coupleId &&
        listEquals(current.service.memberUids, memberIds)) {
      return;
    }
    clearShared(notify: false);
    _sharedCoupleId = coupleId;
    final state = MoneyBookState(MoneyService.shared(coupleId, memberIds));
    _shared = state;
    _listen(state);
    notifyListeners();
  }

  void clearShared({bool notify = true}) {
    _flushDeletes(MoneyBookKind.shared);
    _shared?.dispose();
    _shared = null;
    _sharedCoupleId = null;
    if (notify) notifyListeners();
  }

  /// Sign-out / account gone: drop both books ([signedOut] also forgets the
  /// cached balances on this phone).
  void clear({bool signedOut = false}) {
    _flushDeletes(null);
    final uid = _uid;
    _own?.dispose();
    _own = null;
    clearShared(notify: false);
    _uid = null;
    _lastWriteError = null;
    if (signedOut && uid != null) unawaited(_dropSumsCache(uid));
    notifyListeners();
  }

  /// Own book: re-subscribe when the day rolled over and the window moved.
  void refreshDay() {
    final state = _own;
    if (state != null && state.windowFrom != _ownWindowFrom()) {
      _listenTx(state);
    }
  }

  /// First day of the own book's live window: ≥ 44 days back and never
  /// after the 1st of this month.
  String _ownWindowFrom() {
    final now = _clock();
    final back = MoneyMath.dateKey(now.subtract(const Duration(days: 44)));
    final monthStart = '${MoneyMath.monthKey(now)}-01';
    return back.compareTo(monthStart) < 0 ? back : monthStart;
  }

  void _listen(MoneyBookState s) {
    void fail(Object e) {
      s.loadError = e;
      notifyListeners();
    }

    s.subs.add(
      s.service.watchWallets().listen((r) {
        s.wallets = r.wallets;
        s.walletsFromServer = s.walletsFromServer || r.fromServer;
        _scheduleSums(s);
        notifyListeners();
      }, onError: fail),
    );
    s.subs.add(
      s.service.watchBudgets().listen((b) {
        s.budgets = b;
        notifyListeners();
      }, onError: fail),
    );
    s.subs.add(
      s.service.watchMeta().listen((m) {
        s.meta = m;
        notifyListeners();
      }, onError: fail),
    );
    _listenTx(s);
  }

  void _listenTx(MoneyBookState s) {
    s.txSub?.cancel();
    s.windowFrom = s.isShared ? null : _ownWindowFrom();
    s.txSub = s.service
        .watchTx(from: s.windowFrom)
        .listen(
          (r) {
            s.txs = r.txs;
            s.txLoaded = true;
            if (r.fromServer) {
              s.lastSyncAt = _clock();
              s.loadError = null;
            }
            _scheduleSums(s);
            notifyListeners();
          },
          onError: (Object e) {
            s.loadError = e;
            notifyListeners();
          },
        );
  }

  // ---- balances ------------------------------------------------------------

  void _scheduleSums(MoneyBookState s) {
    if (s.isShared) return; // computed from the full list
    s.sumsDebounce?.cancel();
    s.sumsDebounce = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_refreshSums(s)),
    );
  }

  Future<void> _refreshSums(MoneyBookState s) async {
    if (s.wallets.isEmpty) return;
    try {
      final sums = await s.service.walletNetSums(s.wallets.map((w) => w.id));
      if (!identical(_own, s)) return;
      s.netSums = sums;
      s.netSumsAt = _clock();
      s.netSumsStale = false;
      unawaited(_saveSumsCache(s));
    } catch (_) {
      if (!identical(_own, s)) return;
      s.netSumsStale = true; // offline: keep the cached sums
    }
    notifyListeners();
  }

  /// Entries of [kind] minus the ones in their undo window: a deleted entry
  /// leaves every list and total at once (design §4).
  List<MoneyTx> visibleTxs(MoneyBookKind kind) {
    final s = book(kind);
    if (s == null) return const <MoneyTx>[];
    if (_pendingDeletes.isEmpty) return s.txs;
    return [
      for (final t in s.txs)
        if (!_pendingDeletes.containsKey(t.id)) t,
    ];
  }

  /// Current balance of every wallet of [kind] (archived ones included).
  Map<String, int> balances(MoneyBookKind kind) {
    final s = book(kind);
    if (s == null) return const <String, int>{};
    final visible = visibleTxs(kind);
    if (s.isShared) return MoneyMath.balancesFrom(s.wallets, visible);
    final hidden = [
      for (final d in _pendingDeletes.values)
        if (d.kind == kind) d.tx,
    ];
    return {
      for (final w in s.wallets)
        w.id:
            w.openingBalance +
            (s.netSums[w.id] ?? 0) +
            MoneyMath.pendingDelta(visible, w.id) -
            hidden.fold<int>(0, (sum, t) => sum + t.deltaFor(w.id)),
    };
  }

  /// Own book: balances are known (server aggregate or a cached copy).
  bool balancesReady(MoneyBookKind kind) {
    final s = book(kind);
    if (s == null) return false;
    return s.isShared ? s.txLoaded : s.netSumsAt != null;
  }

  int totalAssets(MoneyBookKind kind) {
    final s = book(kind);
    return s == null ? 0 : MoneyMath.totalAssets(s.wallets, balances(kind));
  }

  /// Would [draft] push a wallet past ±100 tỷ? (rules can't see balances).
  bool exceedsWalletCap(MoneyBookKind kind, MoneyTx draft) {
    final b = balances(kind);
    for (final id in {draft.inWalletId, draft.outWalletId}) {
      if (id.isEmpty || !b.containsKey(id)) continue;
      if (!MoneyMath.walletWithinCap(b[id]! + draft.deltaFor(id))) return true;
    }
    return false;
  }

  // ---- first run / default wallets (D8) ------------------------------------

  /// The own book has never had a wallet (server-confirmed) → first run.
  bool get needsFirstRun =>
      _own != null && _own!.walletsFromServer && _own!.wallets.isEmpty;

  /// Id of the wallet every book starts with: own "Tiền mặt", shared "Ví
  /// chung" (one per pair — a new partner in the same couple gets a new one).
  String defaultWalletId(MoneyBookKind kind) {
    if (kind == MoneyBookKind.own) return 'cash';
    final pair = _shared?.service.memberUids ?? const <String>[];
    String cut(String s) => s.length > 8 ? s.substring(0, 8) : s;
    return 'joint_${pair.map(cut).join('_')}';
  }

  /// Creates the starter wallet (plus [extra] ones from the first-run
  /// screen) when the book has none yet. Two phones racing: the second
  /// write is refused by the rules (createdAt is immutable) and ignored.
  Future<void> ensureDefaultWallet(
    MoneyBookKind kind, {
    List<MoneyWallet> extra = const <MoneyWallet>[],
  }) async {
    final s = book(kind), uid = _uid;
    if (s == null || uid == null) return;
    final id = defaultWalletId(kind);
    final has = s.wallets.any((w) => w.id == id);
    final l = AppL10n.strings;
    final wallets = <MoneyWallet>[
      if (!has)
        MoneyWallet(
          id: id,
          name: kind == MoneyBookKind.own
              ? l.moneyWalletCash
              : l.moneyJointWallet,
          type: MoneyWalletType.cash,
          emoji: kind == MoneyBookKind.own ? '💵' : '👛',
          memberUids: s.service.memberUids,
        ),
      for (final w in extra) _pinned(s, w),
    ];
    if (wallets.isEmpty) return;
    try {
      await s.service.createWallets(wallets, uid: uid);
    } catch (e) {
      debugPrint('money: starter wallets not created: $e');
    }
  }

  MoneyWallet _pinned(MoneyBookState s, MoneyWallet w) => MoneyWallet(
    id: w.id.isEmpty ? s.service.newWalletId() : w.id,
    name: w.name,
    type: w.type,
    emoji: w.emoji,
    color: w.color,
    openingBalance: w.openingBalance,
    includeInTotal: w.includeInTotal,
    archived: w.archived,
    order: w.order,
    goalTarget: w.goalTarget,
    goalDeadline: w.goalDeadline,
    memberUids: s.service.memberUids,
  );

  Future<MoneyWriteOutcome> createWallet(MoneyBookKind kind, MoneyWallet w) {
    final s = book(kind), uid = _uid;
    if (s == null || uid == null) throw StateError('money-no-book');
    return s.service.createWallets([_pinned(s, w)], uid: uid);
  }

  /// Name / emoji / colour / opening balance / includeInTotal / goal / order.
  Future<MoneyWriteOutcome> updateWallet(
    MoneyBookKind kind,
    String walletId,
    Map<String, dynamic> fields,
  ) {
    final s = book(kind);
    if (s == null) throw StateError('money-no-book');
    return s.service.updateWallet(walletId, fields);
  }

  /// Wallets are never deleted: archived, history kept.
  Future<MoneyWriteOutcome> archiveWallet(
    MoneyBookKind kind,
    String walletId, {
    bool archived = true,
  }) => updateWallet(kind, walletId, {'archived': archived});

  // ---- entries -------------------------------------------------------------

  /// Writes a new entry. [draft] needs type / amount / date / wallets /
  /// category / note (+ payer, splitMode, payerShare in the shared book);
  /// id, pair and author are filled in here.
  ///
  /// Shared book + [ownWalletId] → the same money is also recorded in MY
  /// book, both docs sharing a `linkId`, in one batch (D11):
  /// - expense I paid → own expense from that wallet;
  /// - contribution I made → own contribution out of that wallet;
  /// - settle → own `adjust` into the wallet (the partner paid me back) or
  ///   out of it (I paid back) — not income, not spending (design §15.11).
  Future<MoneyWriteOutcome> addTx(
    MoneyBookKind kind,
    MoneyTx draft, {
    String? ownWalletId,
  }) {
    final s = book(kind), uid = _uid, own = _own;
    if (s == null || uid == null) throw StateError('money-no-book');
    var tx = draft.copyWith(
      id: draft.id.isEmpty ? s.service.newTxId() : draft.id,
      memberUids: s.service.memberUids,
      source: draft.source ?? 'manual',
    );
    MoneyTx? mine;
    if (s.isShared && own != null && ownWalletId != null) {
      final linkId = own.service.newTxId();
      mine = _ownSideOf(tx, ownWalletId, linkId: linkId, me: uid);
      if (mine != null) tx = tx.copyWith(linkId: linkId);
    }
    return s.service.commit(
      [
        s.service.createTxOp(tx, uid: uid),
        if (mine != null) own!.service.createTxOp(mine, uid: uid),
      ],
      docId: tx.id,
      onLateError: _onLateError,
    );
  }

  MoneyTx? _ownSideOf(
    MoneyTx sharedTx,
    String walletId, {
    required String linkId,
    required String me,
  }) {
    final base = MoneyTx(
      id: _own!.service.newTxId(),
      type: MoneyTxType.adjust,
      amount: sharedTx.amount,
      date: sharedTx.date,
      note: sharedTx.note,
      linkId: linkId,
      source: sharedTx.source,
    );
    switch (sharedTx.type) {
      case MoneyTxType.expense:
        if (sharedTx.payer != me) return null;
        return base.copyWith(
          type: MoneyTxType.expense,
          outWalletId: walletId,
          categoryId: sharedTx.categoryId,
        );
      case MoneyTxType.contribution:
        if (sharedTx.payer != me) return null;
        return base.copyWith(
          type: MoneyTxType.contribution,
          outWalletId: walletId,
        );
      case MoneyTxType.settle:
        return sharedTx.payer == me
            ? base.copyWith(outWalletId: walletId)
            : base.copyWith(inWalletId: walletId);
      case MoneyTxType.income:
      case MoneyTxType.transfer:
      case MoneyTxType.adjust:
        return null;
    }
  }

  /// "Góp vào quỹ": a contribution into a shared wallet, by me (from
  /// [ownWalletId] when given) or recorded for the partner ([payer]).
  Future<MoneyWriteOutcome> contribute({
    required String sharedWalletId,
    required int amount,
    required String date,
    String? payer,
    String? ownWalletId,
    String note = '',
  }) => addTx(
    MoneyBookKind.shared,
    MoneyTx(
      id: '',
      type: MoneyTxType.contribution,
      amount: amount,
      date: date,
      inWalletId: sharedWalletId,
      note: note,
      payer: payer ?? _uid,
      splitMode: MoneySplitMode.none,
    ),
    ownWalletId: (payer ?? _uid) == _uid ? ownWalletId : null,
  );

  /// "Đánh dấu đã thanh toán": [payer] (who covered less) pays back
  /// [amount]; never spending. [ownWalletId] = "Ghi tiền về ví của mình".
  Future<MoneyWriteOutcome> settle({
    required String payer,
    required int amount,
    required String date,
    String? ownWalletId,
    String note = '',
  }) => addTx(
    MoneyBookKind.shared,
    MoneyTx(
      id: '',
      type: MoneyTxType.settle,
      amount: amount,
      date: date,
      note: note,
      payer: payer,
      splitMode: MoneySplitMode.none,
    ),
    ownWalletId: ownWalletId,
  );

  /// The other half of a linked entry (from memory, else one query).
  Future<MoneyTx?> linkedOf(MoneyBookKind kind, MoneyTx tx) async {
    final linkId = tx.linkId;
    final other = book(
      kind == MoneyBookKind.own ? MoneyBookKind.shared : MoneyBookKind.own,
    );
    if (linkId == null || other == null) return null;
    for (final t in other.txs) {
      if (t.linkId == linkId) return t;
    }
    try {
      return await other.service.findByLinkId(linkId);
    } catch (_) {
      return null;
    }
  }

  /// The shared side of a linked own entry changed amount ("Khoản chung đã
  /// đổi thành 520k · Cập nhật?"): the new shared amount, else null. Only
  /// looks in memory (the shared book is fully loaded).
  int? linkedDrift(MoneyTx ownTx) {
    final linkId = ownTx.linkId;
    final s = _shared;
    if (linkId == null || s == null) return null;
    final match = s.txs.where((t) => t.linkId == linkId).firstOrNull;
    return MoneyMath.linkedDrift(ownTx, match);
  }

  /// Saves an edit. [alsoLinked] ("Sửa cả hai") mirrors amount / date /
  /// note (+ category of an expense) onto the linked doc in the other book,
  /// same batch. A stale edit (someone else saved first) is refused by the
  /// rules → throws, or lands in [lastWriteError] when it was queued.
  Future<MoneyWriteOutcome> updateTx(
    MoneyBookKind kind,
    MoneyTx old,
    MoneyTx updated, {
    bool alsoLinked = false,
  }) async {
    final s = book(kind), uid = _uid;
    if (s == null || uid == null) throw StateError('money-no-book');
    final linked = alsoLinked ? await linkedOf(kind, old) : null;
    final otherBook = linked == null
        ? null
        : book(
            kind == MoneyBookKind.own
                ? MoneyBookKind.shared
                : MoneyBookKind.own,
          );
    return s.service.commit(
      [
        s.service.updateTxOp(old, updated, uid: uid),
        if (linked != null && otherBook != null)
          otherBook.service.updateTxOp(
            linked,
            linked.copyWith(
              amount: updated.amount,
              date: updated.date,
              note: updated.note,
              categoryId: linked.type == MoneyTxType.expense
                  ? updated.categoryId
                  : linked.categoryId,
              payerShare: linked.memberUids.isEmpty
                  ? null
                  : _rescaledShare(linked, updated.amount),
            ),
            uid: uid,
          ),
      ],
      docId: old.id,
      onLateError: _onLateError,
    );
  }

  /// Keeps the split of a shared entry when its amount changes from the own
  /// side (equal stays half, treat stays all, custom keeps its ratio).
  int _rescaledShare(MoneyTx shared, int amount) {
    final mode = shared.splitMode ?? MoneySplitMode.none;
    if (mode != MoneySplitMode.custom) {
      return MoneyMath.payerShareFor(mode, amount);
    }
    if (shared.amount <= 0) return 0;
    return (shared.payerShare * amount / shared.amount).round().clamp(
      0,
      amount,
    );
  }

  /// "Cập nhật": copy the shared amount onto my linked own entry.
  Future<MoneyWriteOutcome> syncLinkedAmount(MoneyTx ownTx, int amount) =>
      updateTx(MoneyBookKind.own, ownTx, ownTx.copyWith(amount: amount));

  /// Hides [tx] at once and deletes it after [deleteDelay] unless
  /// [undoDelete] runs first (D13: nothing reaches Firestore within the
  /// undo window). [alsoLinked] deletes the other book's half too.
  void scheduleDelete(MoneyBookKind kind, MoneyTx tx, {MoneyTx? alsoLinked}) {
    _pendingDeletes.remove(tx.id)?.timer.cancel();
    _pendingDeletes[tx.id] = (
      kind: kind,
      tx: tx,
      linked: alsoLinked,
      timer: Timer(deleteDelay, () => _commitDelete(tx.id)),
    );
    notifyListeners();
  }

  /// Undo: true when the delete was still waiting.
  bool undoDelete(String txId) {
    final pending = _pendingDeletes.remove(txId);
    if (pending == null) return false;
    pending.timer.cancel();
    notifyListeners();
    return true;
  }

  bool isDeleting(String txId) => _pendingDeletes.containsKey(txId);

  void _commitDelete(String txId) {
    final d = _pendingDeletes.remove(txId);
    if (d == null) return;
    final s = book(d.kind);
    final linked = d.linked;
    final otherBook = linked == null
        ? null
        : book(
            d.kind == MoneyBookKind.own
                ? MoneyBookKind.shared
                : MoneyBookKind.own,
          );
    if (s != null) {
      unawaited(
        s.service
            .commit(
              [
                s.service.deleteTxOp(txId),
                if (linked != null && otherBook != null)
                  otherBook.service.deleteTxOp(linked.id),
              ],
              docId: txId,
              onLateError: _onLateError,
            )
            .catchError((Object e) {
              _onLateError(MoneyWriteError(d.kind, txId, e));
              return MoneyWriteOutcome.queued;
            }),
      );
    }
    notifyListeners();
  }

  /// Leaving a book (sign-out / partner left): send the deletes now.
  void _flushDeletes(MoneyBookKind? kind) {
    for (final id in _pendingDeletes.keys.toList()) {
      final d = _pendingDeletes[id]!;
      if (kind != null && d.kind != kind) continue;
      d.timer.cancel();
      _commitDelete(id);
    }
  }

  // ---- defaults when adding (design §15) -----------------------------------

  String defaultCategory(MoneyBookKind kind, MoneyTxType type) {
    final s = book(kind);
    final fallback = type == MoneyTxType.income ? 'salary' : 'food_out';
    if (s == null) return fallback;
    return MoneyMath.defaultCategory(
      visibleTxs(kind),
      type,
      now: _clock(),
      fallback: fallback,
      isPickable: (id) => !s.meta.hiddenCategoryIds.contains(id),
    );
  }

  String? defaultWallet(
    MoneyBookKind kind,
    String categoryId, {
    MoneyTxType type = MoneyTxType.expense,
  }) {
    final s = book(kind);
    if (s == null) return null;
    return MoneyMath.defaultWallet(
      visibleTxs(kind),
      s.wallets,
      categoryId: categoryId,
      kind: type,
      preferred: s.meta.defaultWalletId,
    );
  }

  /// "Ghi lại khoản quen" chips.
  List<MoneyTx> quickRepeats(MoneyBookKind kind) =>
      MoneyMath.quickRepeats(visibleTxs(kind));

  // ---- months, budgets, reports --------------------------------------------

  /// Entries of [month] when they are in memory, else null (call
  /// [viewMonth] to load an older own-book month).
  List<MoneyTx>? txsForMonth(MoneyBookKind kind, String month) {
    final s = book(kind);
    if (s == null) return null;
    final from = s.windowFrom;
    if (s.isShared || (from != null && '$month-01'.compareTo(from) >= 0)) {
      return [
        for (final t in visibleTxs(kind))
          if (t.month == month) t,
      ];
    }
    if (s.viewMonth == month) {
      final v = s.viewTxs;
      return v == null
          ? null
          : [
              for (final t in v)
                if (!_pendingDeletes.containsKey(t.id)) t,
            ];
    }
    return null;
  }

  /// Own book: live-load a month older than the window.
  void viewMonth(MoneyBookKind kind, String month) {
    final s = book(kind);
    if (s == null || s.isShared || s.viewMonth == month) return;
    final (from, to) = MoneyMath.monthRange(month);
    if (s.windowFrom != null && from.compareTo(s.windowFrom!) >= 0) return;
    s.viewSub?.cancel();
    s.viewMonth = month;
    s.viewTxs = null;
    s.viewSub = s.service.watchTx(from: from, to: to).listen((r) {
      s.viewTxs = r.txs;
      notifyListeners();
    }, onError: (Object e) => debugPrint('money: month view failed: $e'));
  }

  MoneyBudget? budgetFor(MoneyBookKind kind, String categoryId) =>
      book(kind)?.budgets.where((b) => b.categoryId == categoryId).firstOrNull;

  /// null = no budget set (or the month is not loaded).
  MoneyBudgetStatus? budgetStatus(
    MoneyBookKind kind,
    String categoryId, {
    String? month,
  }) {
    final s = book(kind);
    final budget = budgetFor(kind, categoryId);
    final txs = txsForMonth(kind, month ?? _thisMonth);
    if (s == null || budget == null || txs == null) return null;
    final spent = MoneyMath.spentIn(
      txs,
      month ?? _thisMonth,
      categoryId: categoryId,
      groupOf: s.categories.groupOf,
    );
    return MoneyMath.budgetStatus(spent, budget.amount);
  }

  Future<MoneyWriteOutcome> setBudget(
    MoneyBookKind kind, {
    required String categoryId,
    required int amount,
  }) {
    final s = book(kind), uid = _uid;
    if (s == null || uid == null) throw StateError('money-no-book');
    return s.service.setBudget(
      id: budgetFor(kind, categoryId)?.id,
      categoryId: categoryId,
      amount: amount,
      uid: uid,
    );
  }

  Future<MoneyWriteOutcome> deleteBudget(MoneyBookKind kind, String id) {
    final s = book(kind);
    if (s == null) throw StateError('money-no-book');
    return s.service.deleteBudget(id);
  }

  /// Merge-write category tweaks: `customCategories` (list of
  /// [MoneyCustomCategory.toMap]), `overrides`, `hiddenCategoryIds`,
  /// `defaultWalletId`.
  Future<MoneyWriteOutcome> setMeta(
    MoneyBookKind kind,
    Map<String, dynamic> fields,
  ) {
    final s = book(kind);
    if (s == null) throw StateError('money-no-book');
    return s.service.setMeta(fields);
  }

  /// Spent / earned per month for the last [n] months (oldest first). A
  /// month that could not be loaded (offline, own book) is null — the chart
  /// leaves it empty instead of drawing a fake 0.
  Future<Map<String, MoneyMonthTotals?>> trend(
    MoneyBookKind kind,
    int n,
  ) async {
    final s = book(kind);
    final months = MoneyMath.trendMonths(_thisMonth, n);
    if (s == null) return {for (final m in months) m: null};
    final out = <String, MoneyMonthTotals?>{};
    for (final m in months) {
      final local = txsForMonth(kind, m);
      if (local != null) {
        out[m] = MoneyMath.monthTotals(local, m);
        continue;
      }
      final cached = s.trendCache[m];
      if (cached != null) {
        out[m] = cached;
        continue;
      }
      try {
        final (from, to) = MoneyMath.monthRange(m);
        final (expense, income) = await s.service.monthSums(from, to);
        // Past months don't change often: keep them for the session.
        final totals = MoneyMonthTotals(expense, income);
        if (m != _thisMonth) s.trendCache[m] = totals;
        out[m] = totals;
      } catch (_) {
        out[m] = null;
      }
    }
    return out;
  }

  /// Search over [from]..[to] (default 3 months, max 12 — the screen
  /// decides): date bounds on the server (own book), everything else here.
  /// `capped` = the 2.000-row limit was hit (design §3.9 notice).
  Future<({List<MoneyTx> rows, bool capped})> search(
    MoneyBookKind kind, {
    required String from,
    required String to,
    String query = '',
    Set<String>? walletIds,
    Set<String>? categoryIds,
    String? payer,
    int? minAmount,
    int? maxAmount,
  }) async {
    final s = book(kind);
    if (s == null) return (rows: const <MoneyTx>[], capped: false);
    final source = s.isShared
        ? [
            for (final t in visibleTxs(kind))
              if (t.date.compareTo(from) >= 0 && t.date.compareTo(to) <= 0) t,
          ]
        : [
            for (final t in await s.service.fetchTx(from: from, to: to))
              if (!_pendingDeletes.containsKey(t.id)) t,
          ];
    final idx = s.categories;
    final rows = MoneyMath.search(
      source,
      query: query,
      categoryName: (id) => idx.of(id).name,
      walletIds: walletIds,
      categoryIds: categoryIds,
      groupOf: idx.groupOf,
      payer: payer,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
    return (rows: rows, capped: !s.isShared && source.length >= 2000);
  }

  // ---- Hive cache of own-book sums (D19: open the app → numbers at once) ---

  Future<Box<String>?> _box() async {
    try {
      return Hive.isBoxOpen(_cacheBox)
          ? Hive.box<String>(_cacheBox)
          : await Hive.openBox<String>(_cacheBox);
    } catch (_) {
      return null; // tests / Hive not ready: no cache, aggregates still work
    }
  }

  Future<void> _loadSumsCache(MoneyBookState s) async {
    final raw = (await _box())?.get('own_${_uid ?? ''}');
    if (raw == null || !identical(_own, s) || s.netSumsAt != null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      s.netSums = {
        for (final e in (json['sums'] as Map<String, dynamic>).entries)
          e.key: (e.value as num).toInt(),
      };
      s.netSumsAt = DateTime.fromMillisecondsSinceEpoch(json['at'] as int);
      s.netSumsStale = true;
      notifyListeners();
    } catch (_) {
      // Corrupt cache: ignore, the aggregate refills it.
    }
  }

  Future<void> _saveSumsCache(MoneyBookState s) async {
    final at = s.netSumsAt, uid = _uid;
    if (at == null || uid == null) return;
    await (await _box())?.put(
      'own_$uid',
      jsonEncode({'at': at.millisecondsSinceEpoch, 'sums': s.netSums}),
    );
  }

  Future<void> _dropSumsCache(String uid) async {
    await (await _box())?.delete('own_$uid');
  }

  @override
  void dispose() {
    for (final d in _pendingDeletes.values) {
      d.timer.cancel();
    }
    _own?.dispose();
    _shared?.dispose();
    super.dispose();
  }
}
