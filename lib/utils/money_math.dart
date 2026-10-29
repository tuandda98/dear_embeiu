import '../models/money.dart';

/// A write made on this phone that the server sums may not include yet
/// (review stage 1, #2). [before] = the version the sums count (null = the
/// entry is not on the server), [after] = the version on this phone now
/// (null = deleted, or hidden in its undo window).
typedef MoneyLocalWrite = ({MoneyTx? before, MoneyTx? after});

/// Month totals of one book (D34: spending only, there is no income).
class MoneyMonthTotals {
  const MoneyMonthTotals(this.expense);

  final int expense;
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

/// Where a saving challenge stands (D34 §4).
class MoneyChallengeStatus {
  const MoneyChallengeStatus({
    required this.spent,
    required this.daysPassed,
    required this.cleanDays,
    required this.ended,
    required this.failed,
    required this.lastDay,
  });

  /// Matching spending inside the window so far.
  final int spent;

  /// Days of the window already started (today included), 0..days.
  final int daysPassed;

  /// noSpend: started days without a matching expense.
  final int cleanDays;

  /// The window is over (today is after [lastDay]).
  final bool ended;

  /// Already lost: a matching expense (noSpend) or past the limit (cap).
  final bool failed;

  /// 'YYYY-MM-DD' of the window's last day.
  final String lastDay;

  bool get won => ended && !failed;
  bool get running => !ended && !failed;
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

  // ---- chi ------------------------------------------------------------------

  /// Spent in [month]. Transfers, adjustments and contributions only move
  /// balances — they are never spending.
  static MoneyMonthTotals monthTotals(Iterable<MoneyTx> txs, String month) {
    var expense = 0;
    for (final t in txs) {
      if (t.month == month && t.type == MoneyTxType.expense) {
        expense += t.amount;
      }
    }
    return MoneyMonthTotals(expense);
  }

  /// Spent across all of [txs], any month.
  static int spentAll(Iterable<MoneyTx> txs) => txs
      .where((t) => t.type == MoneyTxType.expense)
      .fold(0, (sum, t) => sum + t.amount);

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
  /// its undo window changes nothing. [measure] = `t.deltaFor(walletId)`.
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
  /// deadline, rounded UP to [step] (1.000 ₫, $1 — the currency's
  /// `roundStep`). 0 once reached.
  static int perMonthNeeded(
    int left,
    String today,
    String deadline, {
    int step = 1000,
  }) {
    if (left <= 0) return 0;
    final months = monthsUntil(today, deadline);
    final per = (left + months - 1) ~/ months;
    return ((per + step - 1) ~/ step) * step;
  }

  // ---- sổ chung ------------------------------------------------------------

  // ---- thử thách (D34 §4) ---------------------------------------------------

  static DateTime _day(String key) => DateTime.utc(
    int.parse(key.substring(0, 4)),
    int.parse(key.substring(5, 7)),
    int.parse(key.substring(8, 10)),
  );

  static String _key(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// Grades [c] on [txs] (entries of its book) as of [today]. [groupOf]
  /// maps a category to its group, so "Ăn uống" also covers "Cà phê".
  static MoneyChallengeStatus challengeStatus(
    MoneyChallenge c,
    Iterable<MoneyTx> txs,
    String today, {
    String Function(String id)? groupOf,
  }) {
    final start = _day(c.startDate);
    final lastDay = _key(start.add(Duration(days: c.days - 1)));
    final ids = c.categoryIds.toSet();
    bool matches(MoneyTx t) =>
        t.type == MoneyTxType.expense &&
        t.date.compareTo(c.startDate) >= 0 &&
        t.date.compareTo(lastDay) <= 0 &&
        (ids.isEmpty ||
            ids.contains(t.categoryId) ||
            ids.contains(groupOf?.call(t.categoryId) ?? t.categoryId));
    var spent = 0;
    final spendDays = <String>{};
    for (final t in txs) {
      if (!matches(t)) continue;
      spent += t.amount;
      spendDays.add(t.date);
    }
    final elapsed = _day(today).difference(start).inDays + 1;
    final daysPassed = elapsed.clamp(0, c.days);
    final failed = switch (c.kind) {
      MoneyChallengeKind.noSpend => spent > 0,
      MoneyChallengeKind.cap => spent > c.limit,
    };
    return MoneyChallengeStatus(
      spent: spent,
      daysPassed: daysPassed,
      cleanDays: (daysPassed - spendDays.length).clamp(0, c.days),
      ended: today.compareTo(lastDay) > 0,
      failed: failed,
      lastDay: lastDay,
    );
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
      final id = t.outWalletId;
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
