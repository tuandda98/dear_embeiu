import '../models/money.dart';
import 'lunar_calendar.dart';
import 'money_math.dart';

/// Pure helpers of the Sổ tiền stage-3 screens (budgets, report, search —
/// design §3.7–3.9). Numbers still come from [MoneyMath]; this only shapes
/// them for a screen, so the widget tests and the screens agree.
class MoneyViews {
  const MoneyViews._();

  /// Rounded share of [part] in [total] (0 when there is no total).
  static int percentOf(int part, int total) =>
      total <= 0 ? 0 : (part * 100 / total).round();

  // ---- ngân sách -----------------------------------------------------------

  /// Category budgets of [month], the one closest to its limit first
  /// ("biết nhóm nào sắp vượt", design §15).
  static List<(MoneyBudget, MoneyBudgetStatus)> categoryBudgets(
    List<MoneyBudget> budgets,
    Iterable<MoneyTx> txs,
    String month, {
    required String Function(String id) groupOf,
  }) {
    final rows = [
      for (final b in budgets)
        if (!b.isTotal)
          (
            b,
            MoneyMath.budgetStatus(
              MoneyMath.spentIn(
                txs,
                month,
                categoryId: b.categoryId,
                groupOf: groupOf,
              ),
              b.amount,
            ),
          ),
    ];
    rows.sort((a, b) {
      final c = (b.$2.spent * a.$2.budget).compareTo(a.$2.spent * b.$2.budget);
      return c != 0 ? c : b.$2.spent.compareTo(a.$2.spent);
    });
    return rows;
  }

  /// Groups with spending in [month] but no budget of their own ("Chưa đặt
  /// ngân sách"), biggest first.
  static List<(String, int)> unbudgetedGroups(
    List<MoneyBudget> budgets,
    Iterable<MoneyTx> txs,
    String month, {
    required String Function(String id) groupOf,
  }) {
    final have = {for (final b in budgets) b.categoryId};
    return [
      for (final r in MoneyMath.byCategory(txs, month, groupOf: groupOf))
        if (!have.contains(r.$1)) r,
    ];
  }

  /// "Còn X, tức khoảng Y mỗi ngày": days after today until month end
  /// (at least 1) and the per-day amount rounded down to a thousand.
  static ({int daysLeft, int perDay}) perDayLeft(
    MoneyBudgetStatus status,
    String today,
  ) {
    final month = today.substring(0, 7);
    final total = MoneyMath.daysInMonth(month);
    final day = int.parse(today.substring(8, 10));
    final daysLeft = (total - day).clamp(1, total);
    final left = status.left < 0 ? 0 : status.left;
    return (daysLeft: daysLeft, perDay: (left ~/ daysLeft) ~/ 1000 * 1000);
  }

  // ---- báo cáo -------------------------------------------------------------

  /// Leaves of [groupId] in [month], biggest first (report drill-down).
  static List<(String, int)> childrenOf(
    Iterable<MoneyTx> txs,
    String month,
    String groupId, {
    required String Function(String id) groupOf,
  }) => [
    for (final r in MoneyMath.byCategory(txs, month))
      if (groupOf(r.$1) == groupId) r,
  ];

  /// Axis of the "Chi mỗi tháng" chart: a round step (1/2/4/5 × 10ⁿ) giving
  /// at most 4 bands, and the top line ≥ [max] (13,26tr → step 4tr, top 16tr).
  static ({int step, int top}) chartScale(int max) {
    if (max <= 0) return (step: 1000000, top: 4000000);
    var unit = 1;
    while (unit * 10 <= max / 4) {
      unit *= 10;
    }
    for (final k in const [1, 2, 4, 5, 10]) {
      final step = unit * k;
      if (step * 4 >= max) {
        return (step: step, top: (max + step - 1) ~/ step * step);
      }
    }
    return (step: unit * 10, top: (max + unit * 10 - 1) ~/ (unit * 10) * unit * 10);
  }

  /// First month of [trend] with any money in it. Earlier months are
  /// before the book existed: not drawn (no fake 0, design §3.8).
  static String? firstActiveMonth(Map<String, MoneyMonthTotals?> trend) {
    for (final e in trend.entries) {
      final t = e.value;
      if (t != null && (t.expense > 0 || t.income > 0)) return e.key;
    }
    return null;
  }

  /// Tết (lunar 1/1) falls inside [month] ("2026-02" → true).
  static bool hasTet(String month) {
    final m = int.parse(month.substring(5, 7));
    if (m > 2) return false;
    final days = MoneyMath.daysInMonth(month);
    final last = LunarCalendar.fromSolar(
      DateTime(int.parse(month.substring(0, 4)), m, days),
    );
    return last.month == 1 && !last.isLeapMonth && last.day <= days;
  }

  // ---- tìm -----------------------------------------------------------------

  /// Date bounds of "[months] tháng gần đây": the 1st of the month
  /// [months]−1 before today's, up to a year ahead (entries can be dated
  /// up to a year later, stage 2 deviation 12).
  static (String from, String to) searchRange(String today, int months) {
    final month = today.substring(0, 7);
    final from = '${MoneyMath.addMonths(month, -(months - 1))}-01';
    final to = '${MoneyMath.addMonths(month, 12)}-31';
    return (from, to);
  }

  /// The total shown next to the result count: spending when there is any,
  /// else income (transfers and adjustments never count).
  static int resultTotal(Iterable<MoneyTx> rows) {
    var spent = 0, earned = 0;
    for (final t in rows) {
      if (t.type == MoneyTxType.expense) spent += t.amount;
      if (t.type == MoneyTxType.income) earned += t.amount;
    }
    return spent > 0 ? spent : earned;
  }

  /// Where [query] matches [text] ignoring accents and case, in [text]'s
  /// own indexes (to tint that part, design §3.9). null = no match.
  static (int, int)? matchRange(String text, String query) {
    final q = MoneyMath.fold(query.trim());
    if (q.isEmpty) return null;
    final folded = StringBuffer();
    final starts = <int>[]; // folded char → index in text
    var i = 0;
    for (final r in text.runes) {
      final ch = String.fromCharCode(r);
      final f = MoneyMath.fold(ch);
      for (var k = 0; k < f.length; k++) {
        starts.add(i);
      }
      folded.write(f);
      i += ch.length;
    }
    final at = folded.toString().indexOf(q);
    if (at < 0) return null;
    final endAt = at + q.length;
    return (starts[at], endAt < starts.length ? starts[endAt] : text.length);
  }
}
