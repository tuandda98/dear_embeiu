import '../models/money.dart';

/// A write made on this phone that the server sums may not include yet
/// (review stage 1, #2). [before] = the version the sums count (null = the
/// entry is not on the server), [after] = the version on this phone now
/// (null = deleted, or hidden in its undo window).
typedef MoneyLocalWrite = ({MoneyTx? before, MoneyTx? after});

/// Month totals of one book (D7). [left] = income − spent ("Thu trừ chi").
class MoneyMonthTotals {
  const MoneyMonthTotals(this.expense, this.income);

  final int expense;
  final int income;

  int get left => income - expense;
}

/// Where a budget stands this month. [level]: 0, 80 (≥ 80 %) or 100 (≥ 100 %).
class MoneyBudgetStatus {
  const MoneyBudgetStatus({
    required this.spent,
    required this.budget,
    required this.percent,
    required this.level,
  });

  final int spent;
  final int budget;

  /// Rounded down, so 79.9 % reads 79 and does not light the 80 % warning.
  final int percent;
  final int level;

  /// Negative once over budget.
  int get left => budget - spent;
}

/// Pure money arithmetic for Sổ tiền (overview D7, D9, D11, D19 + design
/// §15). No Flutter, no Firestore — every number on a money screen comes from
/// here so two places showing "the same" number can never disagree.
class MoneyMath {
  const MoneyMath._();

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// 'YYYY-MM-DD' in the phone's local time.
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  /// 'YYYY-MM'.
  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}';

  static (int, int) _ym(String month) =>
      (int.parse(month.substring(0, 4)), int.parse(month.substring(5, 7)));

  static int daysInMonth(String month) {
    final (y, m) = _ym(month);
    return DateTime(y, m + 1, 0).day;
  }

  /// First and last date key of [month] (for `date` range queries).
  static (String, String) monthRange(String month) =>
      ('$month-01', '$month-${_two(daysInMonth(month))}');

  /// [month] shifted by [delta] months.
  static String addMonths(String month, int delta) {
    final (y, m) = _ym(month);
    return monthKey(DateTime(y, m + delta));
  }

  /// The last [n] months ending at [month], oldest first (trend chart).
  static List<String> trendMonths(String month, int n) => [
    for (var i = n - 1; i >= 0; i--) addMonths(month, -i),
  ];

  // ---- thu – chi -----------------------------------------------------------

  /// Spent / earned in [month]. Transfers, adjustments, contributions and
  /// settlements only move balances — they are never spending or income.
  static MoneyMonthTotals monthTotals(Iterable<MoneyTx> txs, String month) {
    var expense = 0, income = 0;
    for (final t in txs) {
      if (t.month != month) continue;
      if (t.type == MoneyTxType.expense) expense += t.amount;
      if (t.type == MoneyTxType.income) income += t.amount;
    }
    return MoneyMonthTotals(expense, income);
  }

  /// Spent in [month] on [categoryId] and its children ('' = everything).
  static int spentIn(
    Iterable<MoneyTx> txs,
    String month, {
    String categoryId = '',
    String Function(String id)? groupOf,
  }) {
    var sum = 0;
    for (final t in txs) {
      if (t.type != MoneyTxType.expense || t.month != month) continue;
      if (categoryId.isNotEmpty &&
          t.categoryId != categoryId &&
          (groupOf?.call(t.categoryId) ?? t.categoryId) != categoryId) {
        continue;
      }
      sum += t.amount;
    }
    return sum;
  }

  /// Spending of [month] per category, biggest first. [groupOf] given →
  /// grouped at level 1 (report "Chi theo danh mục"); otherwise per leaf.
  static List<(String, int)> byCategory(
    Iterable<MoneyTx> txs,
    String month, {
    String Function(String id)? groupOf,
  }) {
    final sums = <String, int>{};
    for (final t in txs) {
      if (t.type != MoneyTxType.expense || t.month != month) continue;
      final key = groupOf?.call(t.categoryId) ?? t.categoryId;
      sums[key] = (sums[key] ?? 0) + t.amount;
    }
    return _sorted(sums);
  }

  /// Spending of [month] per wallet it came out of ('' = a shared entry a
  /// person paid, no wallet of this book).
  static List<(String, int)> byWallet(Iterable<MoneyTx> txs, String month) {
    final sums = <String, int>{};
    for (final t in txs) {
      if (t.type != MoneyTxType.expense || t.month != month) continue;
      sums[t.outWalletId] = (sums[t.outWalletId] ?? 0) + t.amount;
    }
    return _sorted(sums);
  }

  static List<(String, int)> _sorted(Map<String, int> sums) =>
      sums.entries.map((e) => (e.key, e.value)).toList()
        ..sort((a, b) => b.$2.compareTo(a.$2));

  // ---- ví ------------------------------------------------------------------

  /// opening + Σ in − Σ out. [sumIn]/[sumOut] come from the two aggregate
  /// `sum()` queries per wallet (D19).
  static int walletBalance(
    MoneyWallet w, {
    required int sumIn,
    required int sumOut,
  }) => w.openingBalance + sumIn - sumOut;

  /// Balance of every wallet from a full list of entries (tests, small books,
  /// and the offline estimate on top of a cached aggregate).
  static Map<String, int> balancesFrom(
    Iterable<MoneyWallet> wallets,
    Iterable<MoneyTx> txs,
  ) {
    final out = {for (final w in wallets) w.id: w.openingBalance};
    for (final t in txs) {
      if (out.containsKey(t.inWalletId)) {
        out[t.inWalletId] = out[t.inWalletId]! + t.amount;
      }
      if (out.containsKey(t.outWalletId)) {
        out[t.outWalletId] = out[t.outWalletId]! - t.amount;
      }
    }
    return out;
  }

  /// What [writes] change on top of a server sum (D19 offline, design §4):
  /// Σ measure(after) − Σ measure(before). A new entry adds itself, an edit
  /// adds only the difference (100k → 120k = −20k, not −120k), a delete
  /// takes back what the server still counts, and a new entry deleted in
  /// its undo window changes nothing. [measure] = `t.deltaFor(walletId)` for
  /// a wallet, or the entry's part of [coupleBalance].
  static int localCorrection(
    Iterable<MoneyLocalWrite> writes,
    int Function(MoneyTx t) measure,
  ) {
    var sum = 0;
    for (final w in writes) {
      if (w.after != null) sum += measure(w.after!);
      if (w.before != null) sum -= measure(w.before!);
    }
    return sum;
  }

  /// "Tổng tiền đang có": wallets in use that count in the total (credit
  /// cards included, so their debt lowers it; goals excluded) (D7).
  static int totalAssets(
    Iterable<MoneyWallet> wallets,
    Map<String, int> balances,
  ) {
    var sum = 0;
    for (final w in wallets) {
      if (w.countsInTotal) sum += balances[w.id] ?? w.openingBalance;
    }
    return sum;
  }

  /// A wallet may never be pushed past ±[cap] (100 tỷ) by an entry.
  static bool walletWithinCap(
    int balance, {
    int cap = 100000000000,
    int floor = -100000000000,
  }) => balance <= cap && balance >= floor;

  // ---- ngân sách -----------------------------------------------------------

  static MoneyBudgetStatus budgetStatus(int spent, int budget) {
    final percent = budget <= 0 ? 0 : (spent * 100) ~/ budget;
    final level = budget <= 0
        ? 0
        : spent >= budget
        ? 100
        : spent * 100 >= budget * 80
        ? 80
        : 0;
    return MoneyBudgetStatus(
      spent: spent,
      budget: budget,
      percent: percent,
      level: level,
    );
  }

  /// The budget line a new entry crosses (80 → 100), for the in-app note
  /// after Save (D17: the own book never pushes). null = nothing new.
  static int? crossedLevel(int spentBefore, int spentAfter, int budget) {
    final before = budgetStatus(spentBefore, budget).level;
    final after = budgetStatus(spentAfter, budget).level;
    return after > before ? after : null;
  }

  // ---- mục tiêu ------------------------------------------------------------

  static int goalPercent(int balance, int target) =>
      target <= 0 || balance <= 0 ? 0 : (balance * 100) ~/ target;

  /// Months left until [deadline] counted on the calendar month (Oct → Jan
  /// = 3), at least 1.
  static int monthsUntil(String today, String deadline) {
    final (ty, tm) = _ym(today);
    final (dy, dm) = _ym(deadline);
    final n = (dy * 12 + dm) - (ty * 12 + tm);
    return n < 1 ? 1 : n;
  }

  /// "Cần để dành ~X mỗi tháng": what is left, spread over the months to the
  /// deadline, rounded UP to the thousand. 0 once reached.
  static int perMonthNeeded(int left, String today, String deadline) {
    if (left <= 0) return 0;
    final months = monthsUntil(today, deadline);
    final per = (left + months - 1) ~/ months;
    return ((per + 999) ~/ 1000) * 1000;
  }

  // ---- sổ chung ------------------------------------------------------------

  /// `payerShare` for a split (D7/D12). Odd amounts split evenly round UP
  /// for the payer (75.001 → 37.501).
  static int payerShareFor(MoneySplitMode mode, int amount, {int custom = 0}) {
    switch (mode) {
      case MoneySplitMode.equal:
        return (amount + 1) ~/ 2;
      case MoneySplitMode.treat:
        return amount;
      case MoneySplitMode.forPartner:
      case MoneySplitMode.none:
        return 0;
      case MoneySplitMode.custom:
        return custom.clamp(0, amount);
    }
  }

  /// Who has covered more, all time (D7). Positive = [me] covered more (the
  /// partner should pay back that much); negative = the partner did.
  /// Only expenses and settlements a PERSON paid count; the shared wallet
  /// and contributions never create a debt.
  static int coupleBalance(Iterable<MoneyTx> txs, String me) {
    var sum = 0;
    for (final t in txs) {
      if (t.type != MoneyTxType.expense && t.type != MoneyTxType.settle) {
        continue;
      }
      final payer = t.payer;
      if (payer == null || payer == kMoneyPayerWallet) continue;
      final owed = t.amount - t.payerShare;
      sum += payer == me ? owed : -owed;
    }
    return sum;
  }

  /// [coupleBalance] from the server's aggregate `sum()` per payer
  /// (expenses + settlements): what each of us covered for the other is
  /// amount − payerShare.
  static int coupleBalanceFromSums({
    required int mineAmount,
    required int mineShare,
    required int partnerAmount,
    required int partnerShare,
  }) => (mineAmount - mineShare) - (partnerAmount - partnerShare);

  /// The settlement that evens out [balance] (from [coupleBalance]): the
  /// person who covered less pays the difference. null when already even.
  static ({String payer, int amount})? settlementFor(
    int balance, {
    required String me,
    required String partner,
  }) {
    if (balance == 0) return null;
    return balance > 0
        ? (payer: partner, amount: balance)
        : (payer: me, amount: -balance);
  }

  /// "Ai trả tháng này": spending of [month] per payer (uid or 'wallet').
  /// The three lanes always add up to the month's shared spending.
  static Map<String, int> paidBy(Iterable<MoneyTx> txs, String month) {
    final out = <String, int>{};
    for (final t in txs) {
      if (t.type != MoneyTxType.expense || t.month != month) continue;
      final key = t.payer ?? kMoneyPayerWallet;
      out[key] = (out[key] ?? 0) + t.amount;
    }
    return out;
  }

  /// Contributions per person into [walletId] (all time), or into any wallet
  /// in [month] when [walletId] is null ("Mỗi người góp … tháng này").
  static Map<String, int> contributionsBy(
    Iterable<MoneyTx> txs, {
    String? walletId,
    String? month,
  }) {
    final out = <String, int>{};
    for (final t in txs) {
      if (t.type != MoneyTxType.contribution) continue;
      if (walletId != null && t.inWalletId != walletId) continue;
      if (month != null && t.month != month) continue;
      final key = t.payer ?? '';
      out[key] = (out[key] ?? 0) + t.amount;
    }
    return out;
  }

  /// The other half of [tx]'s link (D11) among [others] (the other book).
  /// Both halves are always written by [me] in one batch, so a shared entry
  /// the partner made with the same `linkId` is never it (review #7).
  static MoneyTx? linkedHalf(Iterable<MoneyTx> others, MoneyTx tx, String me) {
    final linkId = tx.linkId;
    if (linkId == null) return null;
    for (final t in others) {
      if (t.linkId == linkId && t.createdBy == me) return t;
    }
    return null;
  }

  /// The partner changed the shared side of a linked pair (D11): the shared
  /// amount when it no longer matches [own], else null. My own "Chỉ sổ
  /// chung" edit is not the partner's change (no banner).
  static int? linkedDrift(MoneyTx own, MoneyTx? shared) =>
      shared != null &&
          shared.linkId == own.linkId &&
          shared.createdBy == own.createdBy &&
          shared.updatedBy != own.createdBy &&
          shared.amount != own.amount
      ? shared.amount
      : null;

  // ---- mặc định khi ghi khoản (design §15, thay D9) -------------------------

  static int _byNewest(MoneyTx a, MoneyTx b) {
    final d = b.date.compareTo(a.date);
    if (d != 0) return d;
    final at = a.createdAt, bt = b.createdAt;
    if (at == null || bt == null) return at == null ? -1 : 1;
    return bt.compareTo(at);
  }

  /// Pre-selected category for a new [kind] entry: the most used one over
  /// the last 14 days, a tie going to the most recent; nothing in 14 days →
  /// the most recent ever; nothing at all → [fallback].
  static String defaultCategory(
    Iterable<MoneyTx> txs,
    MoneyTxType kind, {
    required DateTime now,
    required String fallback,
    bool Function(String id)? isPickable,
  }) {
    final since = dateKey(now.subtract(const Duration(days: 14)));
    final list = [
      for (final t in txs)
        if (t.type == kind &&
            t.categoryId.isNotEmpty &&
            (isPickable?.call(t.categoryId) ?? true))
          t,
    ]..sort(_byNewest);
    if (list.isEmpty) return fallback;
    final counts = <String, int>{};
    for (final t in list) {
      if (t.date.compareTo(since) >= 0) {
        counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return list.first.categoryId;
    final top = counts.values.reduce((a, b) => a > b ? a : b);
    // list is newest first → the first id hitting the top count wins a tie.
    return list.firstWhere((t) => counts[t.categoryId] == top).categoryId;
  }

  /// Pre-selected wallet: the one last used with [categoryId] ("cà phê →
  /// Tiền mặt, ăn ngoài → MoMo"), else [preferred] (book default), else the
  /// first usable wallet. Archived / missing wallets are skipped.
  static String? defaultWallet(
    Iterable<MoneyTx> txs,
    Iterable<MoneyWallet> wallets, {
    required String categoryId,
    MoneyTxType kind = MoneyTxType.expense,
    String? preferred,
  }) {
    final usable = {
      for (final w in wallets)
        if (!w.archived) w.id: w,
    };
    final list = txs.toList()..sort(_byNewest);
    for (final t in list) {
      if (t.type != kind || t.categoryId != categoryId) continue;
      final id = kind == MoneyTxType.income ? t.inWalletId : t.outWalletId;
      if (usable.containsKey(id)) return id;
    }
    if (preferred != null && usable.containsKey(preferred)) return preferred;
    final sorted = usable.values.where((w) => !w.isGoal).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return sorted.isEmpty ? null : sorted.first.id;
  }

  /// "Ghi lại khoản quen": the latest expense of each of the [n] most used
  /// expense categories (2 taps: chip + Save).
  static List<MoneyTx> quickRepeats(Iterable<MoneyTx> txs, {int n = 3}) {
    final list = [
      for (final t in txs)
        if (t.type == MoneyTxType.expense && t.categoryId.isNotEmpty) t,
    ]..sort(_byNewest);
    final counts = <String, int>{};
    final latest = <String, MoneyTx>{};
    for (final t in list) {
      counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
      latest.putIfAbsent(t.categoryId, () => t);
    }
    final newest = latest.keys.toList(); // newest first
    final ids = [...newest]
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : newest.indexOf(a).compareTo(newest.indexOf(b));
      });
    return [for (final id in ids.take(n)) latest[id]!];
  }

  // ---- tìm kiếm (D19) ------------------------------------------------------

  static const String _accented =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const String _plain =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

  /// Lower-case, no Vietnamese accents: "Bún chả" → "bun cha".
  static String fold(String s) {
    final lower = s.toLowerCase();
    final b = StringBuffer();
    for (final ch in lower.runes) {
      final c = String.fromCharCode(ch);
      final i = _accented.indexOf(c);
      // Combining marks (NFD input) are dropped.
      if (ch >= 0x0300 && ch <= 0x036F) continue;
      b.write(i >= 0 ? _plain[i] : c);
    }
    return b.toString();
  }

  /// Client-side part of search: the note / category name match without
  /// accents, plus the amount range and wallet / category / payer filters,
  /// over an already date-bounded list. Newest first.
  static List<MoneyTx> search(
    Iterable<MoneyTx> txs, {
    String query = '',
    String Function(String categoryId)? categoryName,
    Set<String>? walletIds,
    Set<String>? categoryIds,
    String Function(String id)? groupOf,
    String? payer,
    int? minAmount,
    int? maxAmount,
  }) {
    final q = fold(query.trim());
    final out = <MoneyTx>[];
    for (final t in txs) {
      if (minAmount != null && t.amount < minAmount) continue;
      if (maxAmount != null && t.amount > maxAmount) continue;
      if (payer != null && t.payer != payer) continue;
      if (walletIds != null &&
          !walletIds.contains(t.outWalletId) &&
          !walletIds.contains(t.inWalletId)) {
        continue;
      }
      if (categoryIds != null &&
          !categoryIds.contains(t.categoryId) &&
          !categoryIds.contains(groupOf?.call(t.categoryId))) {
        continue;
      }
      if (q.isNotEmpty) {
        final name = t.categoryId.isEmpty
            ? ''
            : (categoryName?.call(t.categoryId) ?? '');
        if (!fold('${t.note} $name').contains(q)) continue;
      }
      out.add(t);
    }
    out.sort(_byNewest);
    return out;
  }
}
