import '../models/money.dart';
import 'money_math.dart';

// ── expenses (đợt 2) ── stage 3B: pure helpers behind the fund screen, the
// settle-up sheet, the decision-wheel "Ghi chi" button and the evening
// reminder. Kept apart from MoneyMath so the two stage-3 branches don't
// touch the same file; every number still comes from MoneyMath.

/// The fund card (design §3.10): how full, what is left, what to save a
/// month until the deadline.
class MoneyGoalView {
  const MoneyGoalView({
    required this.balance,
    required this.target,
    required this.percent,
    required this.left,
    required this.perMonth,
    this.deadline,
  });

  factory MoneyGoalView.of(MoneyWallet w, int balance, String today) {
    final target = w.goalTarget ?? 0;
    final left = target - balance;
    final deadline = w.goalDeadline;
    return MoneyGoalView(
      balance: balance,
      target: target,
      percent: MoneyMath.goalPercent(balance, target),
      left: left < 0 ? 0 : left,
      perMonth: deadline == null || target <= 0
          ? 0
          : MoneyMath.perMonthNeeded(left, today, deadline),
      deadline: deadline,
    );
  }

  final int balance;
  final int target;
  final int percent;
  final int left;
  final int perMonth;
  final String? deadline;

  bool get reached => target > 0 && balance >= target;
}

/// "Đủ rồi. Lên lịch đi Đà Lạt thôi": the fund's name without the "Quỹ" /
/// "Fund" word in front ("Quỹ Đà Lạt" → "Đà Lạt").
String moneyTripName(String walletName) {
  final n = walletName.trim();
  final m = RegExp(
    r'^(quỹ|qũy|quy|fund)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(n);
  if (m != null) return m.group(2)!;
  final t = RegExp(r'^(.+?)\s+fund$', caseSensitive: false).firstMatch(n);
  return t?.group(1) ?? n;
}

/// Entries of one wallet: the server read (all time, may be null when it
/// failed) overlaid with the live window (newer copies win), newest first,
/// minus what is in its undo window.
List<MoneyTx> moneyWalletHistory({
  required String walletId,
  required Iterable<MoneyTx>? fetched,
  required Iterable<MoneyTx> live,
  bool Function(String txId)? deleting,
}) {
  final byId = <String, MoneyTx>{
    for (final t in fetched ?? const <MoneyTx>[]) t.id: t,
    for (final t in live)
      if (t.inWalletId == walletId || t.outWalletId == walletId) t.id: t,
  };
  return [
    for (final t in byId.values)
      if (deleting == null || !deleting(t.id)) t,
  ]..sort((a, b) => b.date.compareTo(a.date));
}

/// "Một nửa · 179.500 ₫": the payer rounds up (like [MoneyMath.
/// payerShareFor]).
int moneySettleHalf(int owed) => (owed + 1) ~/ 2;

/// One line of "Vì sao là 359.000 ₫": + I covered the partner, − they
/// covered me (exactly [MoneyMath.coupleBalance] term by term).
typedef MoneySettlePart = ({MoneyTx tx, int signed});

/// The entries behind the couple balance among [txs] (the live window),
/// oldest first; treats and shared-wallet payments add nothing so they are
/// left out.
List<MoneySettlePart> moneySettleParts(Iterable<MoneyTx> txs, String me) {
  final out = <MoneySettlePart>[];
  for (final t in txs) {
    final v = MoneyMath.coupleBalance([t], me);
    if (v != 0) out.add((tx: t, signed: v));
  }
  out.sort((a, b) => a.tx.date.compareTo(b.tx.date));
  return out;
}

/// "2 khoản “mời” … không tính".
int moneyTreatCount(Iterable<MoneyTx> txs) => txs
    .where(
      (t) =>
          t.type == MoneyTxType.expense && t.splitMode == MoneySplitMode.treat,
    )
    .length;

/// Where "Ghi chi" from a decision-wheel pick lands (D20): an active couple
/// logs it in the shared book, a waiting couple in their own; food → Ăn
/// ngoài, a place → Đi chơi.
({MoneyBookKind book, String categoryId}) moneyDecisionPrefill({
  required bool eat,
  required bool coupleActive,
  required bool hasShared,
}) => (
  book: coupleActive && hasShared ? MoneyBookKind.shared : MoneyBookKind.own,
  categoryId: eat ? 'food_out' : 'date_out',
);

/// Did [uid] log anything dated [today] in [txs] (either book)? Drives the
/// evening reminder (D18: today's slot goes once something is written).
// ponytail: "logged today" = an entry dated today by me; a late entry for
// yesterday written tonight doesn't count. Use createdAt if that matters.
bool moneyLoggedToday(Iterable<MoneyTx> txs, String uid, String today) =>
    txs.any((t) => t.date == today && t.createdBy == uid);
