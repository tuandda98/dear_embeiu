import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/money_categories.dart';
import '../l10n/app_l10n.dart';
import '../l10n/app_localizations.dart';
import '../models/money.dart';
import '../services/analytics_service.dart';
import '../services/money_analytics.dart';
import '../services/money_service.dart';
import '../utils/money_currency.dart';
import '../utils/money_math.dart';

/// Live state of one book, the same for both: entries of the last ~45 days
/// (always the whole current month) + wallet balances (and, shared book,
/// the couple balance) from aggregate `sum()` over the whole history,
/// cached in Hive. Review #4: the shared book no longer listens to its
/// whole history (500 entries = 500 reads per reopen).
class MoneyBookState {
  MoneyBookState(this.service);

  final MoneyService service;
  MoneyBookKind get kind => service.kind;

  List<MoneyWallet> _wallets = const <MoneyWallet>[];
  List<MoneyWallet>? _shownWallets;
  AppLocalizations? _shownStrings;

  /// Starter wallets keep the name they got in the language of the day they
  /// were made ("Cash" when the phone was in English). Shown in the current
  /// language while still unrenamed.
  List<MoneyWallet> get wallets {
    final l = AppL10n.strings;
    if (_shownWallets == null || !identical(_shownStrings, l)) {
      final en = lookupAppLocalizations(const Locale('en'));
      final vi = lookupAppLocalizations(const Locale('vi'));
      String? current(String name) {
        for (final (a, b, now) in [
          (en.moneyWalletCash, vi.moneyWalletCash, l.moneyWalletCash),
          (en.moneyJointWallet, vi.moneyJointWallet, l.moneyJointWallet),
          (en.moneyWalletBank, vi.moneyWalletBank, l.moneyWalletBank),
          (en.moneyWalletCredit, vi.moneyWalletCredit, l.moneyWalletCredit),
        ]) {
          if (name == a || name == b) return now;
        }
        return null;
      }

      _shownWallets = [
        for (final w in _wallets)
          switch (current(w.name)) {
            final n? when n != w.name => w.withName(n),
            _ => w,
          },
      ];
      _shownStrings = l;
    }
    return _shownWallets!;
  }

  set wallets(List<MoneyWallet> v) {
    _wallets = v;
    _shownWallets = null;
  }

  /// A server snapshot of the wallets arrived (an empty cached list must not
  /// open the first-run screen).
  bool walletsFromServer = false;
  List<MoneyTx> txs = const <MoneyTx>[];
  bool txLoaded = false;

  /// The book has had at least one entry, any date (one `limit(1)` read per
  /// session): false = a newcomer ("Ghi khoản đầu tiên"); null = not known
  /// yet (offline) → the normal month view.
  bool? everLogged;

  /// First date of the live window.
  String? windowFrom;
  List<MoneyBudget> budgets = const <MoneyBudget>[];
  MoneyMeta meta = MoneyMeta.empty;

  /// Σ in − Σ out per wallet (server aggregate, or the Hive copy).
  Map<String, int> netSums = const <String, int>{};

  /// Shared book: [MoneyMath.coupleBalance] of the server's history.
  int coupleNet = 0;
  DateTime? netSumsAt;

  /// The last aggregate failed (offline): balances are cache + pending.
  bool netSumsStale = false;

  /// Last time the entries came from the server ("số lúc 11:58").
  DateTime? lastSyncAt;
  Object? loadError;

  /// A month older than the live window.
  String? viewMonth;
  List<MoneyTx>? viewTxs;

  final Map<String, MoneyMonthTotals> trendCache = {};

  // ── expenses (đợt 2) · stage 3A ──
  /// Search: rows fetched per 'from|to' (typing filters them again here
  /// instead of re-reading up to 2.000 docs per keystroke).
  final Map<String, ({DateTime at, List<MoneyTx> rows})> searchCache = {};
  final List<StreamSubscription<Object?>> subs = [];
  StreamSubscription<Object?>? txSub;
  StreamSubscription<Object?>? viewSub;
  Timer? sumsDebounce;
  MoneyCategoryIndex? _index;
  MoneyMeta? _indexMeta;
  AppLocalizations? _indexStrings;

  bool get isShared => kind == MoneyBookKind.shared;

  /// Categories with this book's tweaks, names in the current app language.
  MoneyCategoryIndex get categories {
    // Keyed on the language too: the index is often first built before
    // MaterialApp resolves the locale (AppL10n is English until then), and
    // the user can switch language later — both left names in English.
    final strings = AppL10n.strings;
    if (_index == null ||
        !identical(_indexMeta, meta) ||
        !identical(_indexStrings, strings)) {
      _index = MoneyCategoryIndex(resolveMoneyCategories(meta, strings));
      _indexMeta = meta;
      _indexStrings = strings;
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

/// One entry this phone wrote ([seq] writes so far, [acked] of them
/// confirmed by the server) — kept until a server sum that started after
/// the last ack has replaced it (review #2).
class _LocalWrite {
  _LocalWrite(this.kind, this.before);

  final MoneyBookKind kind;
  final MoneyTx? before;
  MoneyTx? after;
  int seq = 0;
  int acked = 0;
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
  MoneyProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _current = this;
  }

  /// The live provider, for [flushPendingDeletes] (AuthProvider /
  /// CoupleProvider hold no BuildContext).
  static MoneyProvider? _current;

  /// Sends the deletes still in their undo window and waits for the server
  /// (≤ ~5 s) — call BEFORE signing out ([kind] null) or leaving the couple
  /// ([MoneyBookKind.shared]); after that the rules refuse them (review #9).
  /// Offline they stay in Firestore's queue for this account.
  static Future<void> flushPendingDeletes([MoneyBookKind? kind]) async {
    final p = _current;
    if (p == null) return;
    try {
      await Future.wait(
        p._flushDeletes(kind),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best effort: never block a sign-out on it.
    }
  }

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
    ({
      MoneyBookKind kind,
      MoneyTx tx,
      MoneyTx? linked,
      Timer timer,
      bool byUser,
    })
  >
  _pendingDeletes = {};

  /// '{kind}/{budgetId}' → a budget removed in its undo window (Tester Low:
  /// delete-then-recreate lost `alerted` → the 80/100 % push again).
  final Map<String, ({MoneyBudget budget, Timer timer})> _pendingBudgetDeletes =
      {};

  /// 'own/{txId}' or 'shared/{txId}' → writes the server sums may not count
  /// yet.
  final Map<String, _LocalWrite> _localWrites = {};

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

  /// Late refusals of a book that is gone (signed out, left the couple)
  /// are dropped: they belong to the previous session (review #9).
  void Function(MoneyWriteError) _lateErrorFor(MoneyBookState s) => (e) {
    if (!identical(book(s.kind), s)) return;
    _lastWriteError = e;
    notifyListeners();
  };

  /// Notes [now] (null = deleted) as the latest local version of [id], over
  /// [old] (what the server sums count; null = a new entry). Returns the
  /// write's number for [_ackFor].
  (String, int) _track(
    MoneyBookKind kind,
    String id, {
    MoneyTx? old,
    required MoneyTx? now,
  }) {
    final key = '${kind.name}/$id';
    final w = _localWrites[key] ??= _LocalWrite(kind, old);
    w.after = now;
    return (key, ++w.seq);
  }

  /// [MoneyService.commit] `onDone` for the writes in [marks].
  void Function(Object?) _ackFor(List<(String, int)> marks) => (error) {
    for (final (key, seq) in marks) {
      final w = _localWrites[key];
      if (w == null) continue;
      if (error == null) {
        if (seq > w.acked) w.acked = seq;
      } else if (w.seq == seq) {
        _localWrites.remove(key); // refused → Firestore rolled it back
      }
    }
    for (final s in [_own, _shared]) {
      if (s != null) _scheduleSums(s);
    }
    notifyListeners();
  };

  /// The local writes of [kind] (+ entries hidden in their undo window)
  /// as [MoneyLocalWrite]s for [MoneyMath.localCorrection].
  List<MoneyLocalWrite> _localWritesOf(MoneyBookKind kind) {
    final out = <MoneyLocalWrite>[];
    final hidden = _hiddenOf(kind);
    final seen = <String>{};
    for (final e in _localWrites.entries) {
      final w = e.value;
      if (w.kind != kind) continue;
      final id = e.key.substring(kind.name.length + 1);
      seen.add(id);
      out.add((
        before: w.before,
        after: hidden.containsKey(id) ? null : w.after,
      ));
    }
    for (final h in hidden.entries) {
      if (!seen.contains(h.key)) out.add((before: h.value, after: null));
    }
    return out;
  }

  /// Entries of [kind] in their undo window (id → the copy being deleted):
  /// the deleted entry itself, or the other book's half deleted with it.
  Map<String, MoneyTx> _hiddenOf(MoneyBookKind kind) => {
    for (final d in _pendingDeletes.values)
      if (d.kind == kind)
        d.tx.id: d.tx
      else if (d.linked != null)
        d.linked!.id: d.linked!,
  };

  void _dropLocalWrites(MoneyBookKind kind) =>
      _localWrites.removeWhere((_, w) => w.kind == kind);

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
    unawaited(_loadSumsCache(state));
    notifyListeners();
  }

  void clearShared({bool notify = true}) {
    _flushDeletes(MoneyBookKind.shared);
    _dropLocalWrites(MoneyBookKind.shared);
    _shared?.dispose();
    _shared = null;
    _sharedCoupleId = null;
    if (notify) notifyListeners();
  }

  /// Sign-out / account gone: drop both books ([signedOut] also forgets the
  /// cached balances on this phone).
  void clear({bool signedOut = false}) {
    _flushDeletes(null);
    _dropLocalWrites(MoneyBookKind.own);
    _own?.dispose();
    _own = null;
    clearShared(notify: false);
    _uid = null;
    _lastWriteError = null;
    if (signedOut) unawaited(_dropSumsCache());
    notifyListeners();
  }

  /// "Thử lại" after a load error: subscribe the book's streams again and
  /// re-read the sums (both books read balances from aggregates now).
  void retry(MoneyBookKind kind) {
    final s = book(kind);
    if (s == null) return;
    s.dispose();
    s.loadError = null;
    _listen(s);
    unawaited(_refreshSums(s));
    notifyListeners();
  }

  /// Day rolled over: move the live windows (the new window re-reads sums).
  /// Called after every Home build, so it must stay a no-op on the same day:
  /// re-subscribing fires the tx listener, which re-reads the sums itself.
  void refreshDay() {
    for (final s in [_own, _shared]) {
      if (s != null && s.windowFrom != _windowFrom()) _listenTx(s);
    }
  }

  /// App resumed: [refreshDay], then re-read the sums once (the partner may
  /// have edited an entry older than the window while we were away).
  void onResume() {
    refreshDay();
    for (final s in [_own, _shared]) {
      if (s != null) _scheduleSums(s);
    }
  }

  /// First day of a book's live window: ≥ 44 days back and never after the
  /// 1st of this month.
  String _windowFrom() {
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
        s.budgets = [
          for (final x in b)
            if (!_pendingBudgetDeletes.containsKey('${s.kind.name}/${x.id}')) x,
        ];
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
    if (s.everLogged == null) unawaited(_checkEverLogged(s));
  }

  Future<void> _checkEverLogged(MoneyBookState s) async {
    try {
      final any = await s.service.hasAnyTx();
      if (s.everLogged == true) return;
      s.everLogged = any;
      notifyListeners();
    } catch (e) {
      debugPrint('money: first-entry check failed: $e');
    }
  }

  void _listenTx(MoneyBookState s) {
    s.txSub?.cancel();
    s.windowFrom = _windowFrom();
    s.txSub = s.service
        .watchTx(from: s.windowFrom)
        .listen(
          (r) {
            s.txs = r.txs;
            s.txLoaded = true;
            if (r.txs.isNotEmpty) s.everLogged = true;
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
    s.sumsDebounce?.cancel();
    s.sumsDebounce = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_refreshSums(s)),
    );
  }

  Future<void> _refreshSums(MoneyBookState s) async {
    final uid = _uid;
    if (uid == null || (!s.isShared && s.wallets.isEmpty)) return;
    // Writes the server had confirmed before these sums started are in them.
    final settled = [
      for (final e in _localWrites.entries)
        if (e.value.kind == s.kind && e.value.acked == e.value.seq)
          (e.key, e.value, e.value.seq),
    ];
    try {
      final sumsF = s.service.walletNetSums(s.wallets.map((w) => w.id));
      final coupleF = s.isShared ? _coupleNet(s, uid) : Future.value(0);
      final (sums, couple) = await (sumsF, coupleF).wait;
      if (!identical(book(s.kind), s)) return;
      s.netSums = sums;
      s.coupleNet = couple;
      s.netSumsAt = _clock();
      s.netSumsStale = false;
      for (final (key, w, seq) in settled) {
        if (identical(_localWrites[key], w) && w.seq == seq) {
          _localWrites.remove(key);
        }
      }
      unawaited(_saveSumsCache(s));
    } catch (_) {
      if (!identical(book(s.kind), s)) return;
      s.netSumsStale = true; // offline: keep the cached sums
    }
    notifyListeners();
  }

  Future<int> _coupleNet(MoneyBookState s, String uid) async {
    final partner = s.service.memberUids.firstWhere(
      (id) => id != uid,
      orElse: () => '',
    );
    final (mine, theirs) = await (
      s.service.paidSums(uid),
      s.service.paidSums(partner),
    ).wait;
    return MoneyMath.coupleBalanceFromSums(
      mineAmount: mine.amount,
      mineShare: mine.share,
      partnerAmount: theirs.amount,
      partnerShare: theirs.share,
    );
  }

  /// Entries of [kind] minus the ones in their undo window: a deleted entry
  /// leaves every list and total at once (design §4).
  List<MoneyTx> visibleTxs(MoneyBookKind kind) {
    final s = book(kind);
    if (s == null) return const <MoneyTx>[];
    final hidden = _hiddenOf(kind);
    if (hidden.isEmpty) return s.txs;
    return [
      for (final t in s.txs)
        if (!hidden.containsKey(t.id)) t,
    ];
  }

  /// Current balance of every wallet of [kind] (archived ones included):
  /// server sum (or its cached copy) + this phone's writes the sum may not
  /// count yet − entries in their undo window.
  Map<String, int> balances(MoneyBookKind kind) {
    final s = book(kind);
    if (s == null) return const <String, int>{};
    final local = _localWritesOf(kind);
    return {
      for (final w in s.wallets)
        w.id:
            w.openingBalance +
            (s.netSums[w.id] ?? 0) +
            MoneyMath.localCorrection(local, (t) => t.deltaFor(w.id)),
    };
  }

  /// Shared book, all time: positive = I covered more ([MoneyMath.
  /// coupleBalance]). null until the sums (or their cached copy) are known.
  int? coupleBalance() {
    final s = _shared, uid = _uid;
    if (s == null || uid == null || s.netSumsAt == null) return null;
    return s.coupleNet +
        MoneyMath.localCorrection(
          _localWritesOf(MoneyBookKind.shared),
          (t) => MoneyMath.coupleBalance([t], uid),
        );
  }

  /// "Đánh dấu đã thanh toán" (Tester Med): re-reads the sums from the
  /// server now and returns [coupleBalance] from them — null when the read
  /// failed (offline), so a settle never goes out on a cached number.
  Future<int?> refreshCoupleBalance() async {
    final s = _shared;
    if (s == null) return null;
    s.sumsDebounce?.cancel();
    await _refreshSums(s);
    if (!identical(_shared, s) || s.netSumsStale) return null;
    return coupleBalance();
  }

  /// Balances are known (server aggregate or a cached copy).
  bool balancesReady(MoneyBookKind kind) => book(kind)?.netSumsAt != null;

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
    int starterBalance = 0,
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
          openingBalance: starterBalance,
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
    // Books in different currencies never share an amount (D31).
    if (s.isShared && own != null && ownWalletId != null && booksLinkable) {
      final linkId = own.service.newTxId();
      mine = _ownSideOf(tx, ownWalletId, linkId: linkId, me: uid);
      if (mine != null) tx = tx.copyWith(linkId: linkId);
    }
    final ops = [
      s.service.createTxOp(tx, uid: uid),
      if (mine != null) own!.service.createTxOp(mine, uid: uid),
    ];
    final marks = [
      _track(kind, tx.id, now: tx),
      if (mine != null) _track(MoneyBookKind.own, mine.id, now: mine),
    ];
    return s.service.commit(
      ops,
      docId: tx.id,
      onLateError: _lateErrorFor(s),
      onDone: _ackFor(marks),
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
    String id = '',
    required String sharedWalletId,
    required int amount,
    required String date,
    String? payer,
    String? ownWalletId,
    String note = '',
  }) => addTx(
    MoneyBookKind.shared,
    MoneyTx(
      id: id,
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
    String id = '',
    required String payer,
    required int amount,
    required String date,
    String? ownWalletId,
    String note = '',
  }) => addTx(
    MoneyBookKind.shared,
    MoneyTx(
      id: id,
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
    final linkId = tx.linkId, uid = _uid;
    final other = book(
      kind == MoneyBookKind.own ? MoneyBookKind.shared : MoneyBookKind.own,
    );
    if (linkId == null || other == null || uid == null) return null;
    final inMemory = MoneyMath.linkedHalf(other.txs, tx, uid);
    if (inMemory != null) return inMemory;
    try {
      return await other.service.findByLinkId(linkId, createdBy: uid);
    } catch (_) {
      return null;
    }
  }

  /// The shared side of a linked own entry changed amount ("Khoản chung đã
  /// đổi thành 520k · Cập nhật?"): the new shared amount, else null. Only
  /// looks in memory: both halves carry the same date, so the half of an
  /// own entry in the live window is in the shared window too.
  int? linkedDrift(MoneyTx ownTx) {
    final s = _shared, uid = _uid;
    if (s == null || uid == null) return null;
    return MoneyMath.linkedDrift(
      ownTx,
      MoneyMath.linkedHalf(s.txs, ownTx, uid),
    );
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
    // A shared entry with an own-book half (D11): who paid / which wallet
    // stay as written, else the money leaves twice (Tester Med — the sheet
    // locks these chips; this is the backstop).
    if (old.linkId != null &&
        old.memberUids.isNotEmpty &&
        (updated.payer != old.payer ||
            updated.outWalletId != old.outWalletId)) {
      throw StateError('money-linked-payer');
    }
    final linked = alsoLinked ? await linkedOf(kind, old) : null;
    final otherBook = linked == null
        ? null
        : book(
            kind == MoneyBookKind.own
                ? MoneyBookKind.shared
                : MoneyBookKind.own,
          );
    final linkedUpdated = linked == null || otherBook == null
        ? null
        : linked.copyWith(
            amount: updated.amount,
            date: updated.date,
            note: updated.note,
            categoryId: linked.type == MoneyTxType.expense
                ? updated.categoryId
                : linked.categoryId,
            payerShare: linked.memberUids.isEmpty
                ? null
                : _rescaledShare(linked, updated.amount),
          );
    final ops = [
      s.service.updateTxOp(old, updated, uid: uid),
      if (linkedUpdated != null)
        otherBook!.service.updateTxOp(linked!, linkedUpdated, uid: uid),
    ];
    final marks = [
      _track(kind, old.id, old: old, now: updated),
      if (linkedUpdated != null)
        _track(otherBook!.kind, linked!.id, old: linked, now: linkedUpdated),
    ];
    return s.service.commit(
      ops,
      docId: old.id,
      onLateError: _lateErrorFor(s),
      onDone: _ackFor(marks),
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
  /// [byUser] = the user's "Xoá" (logs `money_tx_delete`), not the undo of
  /// a save.
  void scheduleDelete(
    MoneyBookKind kind,
    MoneyTx tx, {
    MoneyTx? alsoLinked,
    bool byUser = false,
  }) {
    _pendingDeletes.remove(tx.id)?.timer.cancel();
    _pendingDeletes[tx.id] = (
      kind: kind,
      tx: tx,
      linked: alsoLinked,
      timer: Timer(deleteDelay, () => unawaited(_commitDelete(tx.id))),
      byUser: byUser,
    );
    notifyListeners();
  }

  /// Undo: true when the delete was still waiting.
  bool undoDelete(String txId) {
    final pending = _pendingDeletes.remove(txId);
    if (pending == null) return false;
    pending.timer.cancel();
    if (pending.byUser) {
      AnalyticsService.instance.logMoneyTxDelete(pending.kind, undone: true);
    }
    notifyListeners();
    return true;
  }

  bool isDeleting(String txId) => _pendingDeletes.containsKey(txId);

  Future<void> _commitDelete(String txId) async {
    final d = _pendingDeletes.remove(txId);
    if (d == null) return;
    if (d.byUser) {
      AnalyticsService.instance.logMoneyTxDelete(d.kind, undone: false);
    }
    final s = book(d.kind);
    final linked = d.linked;
    final otherBook = linked == null
        ? null
        : book(
            d.kind == MoneyBookKind.own
                ? MoneyBookKind.shared
                : MoneyBookKind.own,
          );
    if (s == null) {
      notifyListeners();
      return;
    }
    final late = _lateErrorFor(s);
    final marks = [
      _track(d.kind, txId, old: d.tx, now: null),
      if (linked != null && otherBook != null)
        _track(otherBook.kind, linked.id, old: linked, now: null),
    ];
    notifyListeners();
    try {
      await s.service.commit(
        [
          s.service.deleteTxOp(txId),
          if (linked != null && otherBook != null)
            otherBook.service.deleteTxOp(linked.id),
        ],
        docId: txId,
        onLateError: late,
        onDone: _ackFor(marks),
      );
    } catch (e) {
      late(MoneyWriteError(d.kind, txId, e));
    }
  }

  /// Leaving a book (sign-out / partner left): send the deletes now.
  List<Future<void>> _flushDeletes(MoneyBookKind? kind) {
    final sent = <Future<void>>[];
    for (final id in _pendingDeletes.keys.toList()) {
      final d = _pendingDeletes[id]!;
      if (kind != null && d.kind != kind) continue;
      d.timer.cancel();
      sent.add(_commitDelete(id));
    }
    for (final key in _pendingBudgetDeletes.keys.toList()) {
      if (kind != null && !key.startsWith('${kind.name}/')) continue;
      _pendingBudgetDeletes[key]!.timer.cancel();
      sent.add(_commitBudgetDelete(key));
    }
    return sent;
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
    if (from != null && '$month-01'.compareTo(from) >= 0) {
      return [
        for (final t in visibleTxs(kind))
          if (t.month == month) t,
      ];
    }
    if (s.viewMonth == month) {
      final v = s.viewTxs;
      final hidden = _hiddenOf(kind);
      return v == null
          ? null
          : [
              for (final t in v)
                if (!hidden.containsKey(t.id)) t,
            ];
    }
    return null;
  }

  /// Live-load a month older than the window.
  void viewMonth(MoneyBookKind kind, String month) {
    final s = book(kind);
    if (s == null || s.viewMonth == month) return;
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
    // Set again inside the undo window of its "Bỏ": keep the doc, edit it.
    final removed = _pendingBudgetDeletes.remove(
      '${kind.name}/${MoneyBudget.idFor(categoryId)}',
    );
    removed?.timer.cancel();
    return s.service.setBudget(
      id: budgetFor(kind, categoryId)?.id ?? removed?.budget.id,
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

  /// "Bỏ ngân sách": hidden at once, deleted after [deleteDelay] unless
  /// [undoBudgetDelete] runs first — the doc (and its `alerted` marks) stays
  /// as it was on undo, so the 80/100 % push doesn't fire twice.
  void scheduleBudgetDelete(MoneyBookKind kind, MoneyBudget budget) {
    final s = book(kind);
    if (s == null) return;
    final key = '${kind.name}/${budget.id}';
    _pendingBudgetDeletes.remove(key)?.timer.cancel();
    _pendingBudgetDeletes[key] = (
      budget: budget,
      timer: Timer(deleteDelay, () => unawaited(_commitBudgetDelete(key))),
    );
    s.budgets = [
      for (final b in s.budgets)
        if (b.id != budget.id) b,
    ];
    notifyListeners();
  }

  bool undoBudgetDelete(MoneyBookKind kind, String id) {
    final pending = _pendingBudgetDeletes.remove('${kind.name}/$id');
    if (pending == null) return false;
    pending.timer.cancel();
    final s = book(kind);
    if (s != null && !s.budgets.any((b) => b.id == id)) {
      s.budgets = [...s.budgets, pending.budget];
    }
    notifyListeners();
    return true;
  }

  Future<void> _commitBudgetDelete(String key) async {
    final d = _pendingBudgetDeletes.remove(key);
    if (d == null) return;
    final kind = MoneyBookKind.values.byName(key.split('/').first);
    try {
      if (book(kind) != null) await deleteBudget(kind, d.budget.id);
    } catch (e) {
      debugPrint('money: delete budget failed: $e');
    }
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

  // ── currency (D31) ──
  /// The book whose screens are on top (MoneyScreen's tab, a wallet / goal /
  /// budget screen): amounts printed without an explicit book use its
  /// currency. Set while building, never notifies.
  MoneyBookKind activeBook = MoneyBookKind.own;

  MoneyCurrency currencyOf(MoneyBookKind kind) =>
      MoneyCurrency.of(book(kind)?.meta.currency);

  /// Amounts are never converted, so only a book with nothing in it yet may
  /// switch: no entry ever, no budget, every wallet at 0 with no goal.
  bool canChangeCurrency(MoneyBookKind kind) {
    final s = book(kind);
    if (s == null || s.budgets.isNotEmpty) return false;
    // No wallet yet = nothing ever written (an entry needs a wallet or a
    // payer, and wallets are never deleted): the first-run screen.
    if (s.walletsFromServer && s.wallets.isEmpty) return true;
    if (s.everLogged != false) return false;
    return s.wallets.every(
      (w) => w.openingBalance == 0 && w.goalTarget == null,
    );
  }

  /// A shared entry can also land in my own book ("Trừ vào ví của mình",
  /// settle into my wallet) only while both books count the same money.
  bool get booksLinkable =>
      currencyOf(MoneyBookKind.own) == currencyOf(MoneyBookKind.shared);

  Future<MoneyWriteOutcome> setCurrency(MoneyBookKind kind, String code) {
    if (!canChangeCurrency(kind)) throw StateError('money-currency-locked');
    return setMeta(kind, {'currency': MoneyCurrency.of(code).code});
  }

  /// Spent / earned per month for the last [n] months (oldest first). A
  /// month that could not be loaded (offline) is null — the chart
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
  /// decides): date bounds on the server, everything else here.
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
    // ── expenses (đợt 2) · stage 3A: fetch once per range for 2 minutes;
    // the live window replaces its part of it so an entry just edited or
    // deleted on this phone shows right away.
    final key = '$from|$to';
    final hit = s.searchCache[key];
    final List<MoneyTx> fetched;
    if (hit != null && _clock().difference(hit.at).inMinutes < 2) {
      fetched = hit.rows;
    } else {
      fetched = await s.service.fetchTx(from: from, to: to);
      s.searchCache[key] = (at: _clock(), rows: fetched);
    }
    final win = s.windowFrom;
    final source = [
      for (final t in fetched)
        if ((win == null || t.date.compareTo(win) < 0) &&
            !_pendingDeletes.containsKey(t.id))
          t,
      if (win != null)
        for (final t in visibleTxs(kind))
          if (t.date.compareTo(from) >= 0 && t.date.compareTo(to) <= 0) t,
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
    return (rows: rows, capped: fetched.length >= 2000);
  }

  /// Tests: put prepared books in place (no Firestore listeners). Balances
  /// come from `netSums` / `coupleNet` / `netSumsAt` of the states.
  @visibleForTesting
  void debugSetBooks({
    required String uid,
    MoneyBookState? own,
    MoneyBookState? shared,
  }) {
    _uid = uid;
    _own = own;
    _shared = shared;
    _sharedCoupleId = shared == null ? null : 'debug';
    notifyListeners();
  }

  // ---- Hive cache of the sums (D19: open the app → numbers at once) --------

  Future<Box<String>?> _box() async {
    try {
      return Hive.isBoxOpen(_cacheBox)
          ? Hive.box<String>(_cacheBox)
          : await Hive.openBox<String>(_cacheBox);
    } catch (_) {
      return null; // tests / Hive not ready: no cache, aggregates still work
    }
  }

  /// One entry per book (and per pair for the shared book).
  static String _cacheKey(MoneyBookState s) => s.isShared
      ? '${s.service.book.path}|${s.service.memberUids.join(',')}'
      : s.service.book.path;

  Future<void> _loadSumsCache(MoneyBookState s) async {
    final raw = (await _box())?.get(_cacheKey(s));
    if (raw == null || !identical(book(s.kind), s) || s.netSumsAt != null) {
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      s.netSums = {
        for (final e in (json['sums'] as Map<String, dynamic>).entries)
          e.key: (e.value as num).toInt(),
      };
      s.coupleNet = (json['couple'] as num?)?.toInt() ?? 0;
      s.netSumsAt = DateTime.fromMillisecondsSinceEpoch(json['at'] as int);
      s.netSumsStale = true;
      notifyListeners();
    } catch (_) {
      // Corrupt cache: ignore, the aggregate refills it.
    }
  }

  Future<void> _saveSumsCache(MoneyBookState s) async {
    final at = s.netSumsAt;
    if (at == null) return;
    await (await _box())?.put(
      _cacheKey(s),
      jsonEncode({
        'at': at.millisecondsSinceEpoch,
        'sums': s.netSums,
        if (s.isShared) 'couple': s.coupleNet,
      }),
    );
  }

  /// Signed out: this phone forgets every cached money number.
  Future<void> _dropSumsCache() async {
    await (await _box())?.clear();
  }

  @override
  void dispose() {
    if (identical(_current, this)) _current = null;
    for (final d in _pendingDeletes.values) {
      d.timer.cancel();
    }
    for (final d in _pendingBudgetDeletes.values) {
      d.timer.cancel();
    }
    _own?.dispose();
    _shared?.dispose();
    super.dispose();
  }
}
