/// "Nhìn lại tháng" (D34 §5): only true, good news about last month, at
/// most 3 lines, in this order. Never a comparison that went worse, never
/// one person against the other.
enum MoneyRecapKind { keptBudget, spentLess, saved, challenges, logged }

typedef MoneyRecapLine = ({MoneyRecapKind kind, int value, int of});

List<MoneyRecapLine> moneyRecapLines({
  required int spent,
  int? budget,
  int? prevSpent,
  required int saved,
  required int challengesWon,
  required int loggedDays,
  required int daysInMonth,
}) {
  final out = <MoneyRecapLine>[
    if (budget != null && budget > 0 && spent <= budget)
      (kind: MoneyRecapKind.keptBudget, value: budget - spent, of: budget),
    if (prevSpent != null && prevSpent > spent && spent > 0)
      (kind: MoneyRecapKind.spentLess, value: prevSpent - spent, of: prevSpent),
    if (saved > 0) (kind: MoneyRecapKind.saved, value: saved, of: 0),
    if (challengesWon > 0)
      (kind: MoneyRecapKind.challenges, value: challengesWon, of: 0),
    if (loggedDays * 2 >= daysInMonth)
      (kind: MoneyRecapKind.logged, value: loggedDays, of: daysInMonth),
  ];
  return out.take(3).toList();
}
