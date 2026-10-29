import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/utils/money_recap.dart';
import 'package:flutter_test/flutter_test.dart';

// D34 §4–5: saving challenges graded on the phone + "Nhìn lại tháng".
MoneyTx _e(String date, String cat, int amount) => MoneyTx(
  id: '$date$cat$amount',
  type: MoneyTxType.expense,
  amount: amount,
  date: date,
  outWalletId: 'cash',
  categoryId: cat,
);

void main() {
  String groupOf(String id) => id.startsWith('food') ? 'food' : id;

  group('challengeStatus', () {
    const coffee = MoneyChallenge(
      id: 'c',
      title: '7 ngày không cà phê',
      kind: MoneyChallengeKind.noSpend,
      categoryIds: ['food_coffee'],
      startDate: '2026-10-20',
      days: 7,
    );

    test('noSpend: clean days count, last day, running', () {
      final st = MoneyMath.challengeStatus(
        coffee,
        [
          _e('2026-10-21', 'food_out', 90000),
          _e('2026-10-19', 'food_coffee', 40000), // before the window
        ],
        '2026-10-23',
        groupOf: groupOf,
      );
      expect(st.lastDay, '2026-10-26');
      expect(st.daysPassed, 4);
      expect(st.cleanDays, 4);
      expect(st.failed, isFalse);
      expect(st.running, isTrue);
    });

    test('noSpend: one matching expense fails it at once', () {
      final st = MoneyMath.challengeStatus(coffee, [
        _e('2026-10-22', 'food_coffee', 40000),
      ], '2026-10-23');
      expect(st.failed, isTrue);
      expect(st.running, isFalse);
      expect(st.cleanDays, 3);
    });

    test('noSpend on a group covers its children', () {
      final food = MoneyChallenge(
        id: 'f',
        title: 'x',
        kind: MoneyChallengeKind.noSpend,
        categoryIds: const ['food'],
        startDate: '2026-10-20',
        days: 7,
      );
      final st = MoneyMath.challengeStatus(
        food,
        [_e('2026-10-22', 'food_snack', 20000)],
        '2026-10-23',
        groupOf: groupOf,
      );
      expect(st.failed, isTrue);
    });

    test('cap: under the limit wins once the window is over', () {
      const cap = MoneyChallenge(
        id: 'k',
        title: 'Ăn ngoài dưới 500k',
        kind: MoneyChallengeKind.cap,
        categoryIds: ['food_out'],
        limit: 500000,
        startDate: '2026-10-20',
        days: 7,
      );
      final txs = [
        _e('2026-10-20', 'food_out', 200000),
        _e('2026-10-25', 'food_out', 300000),
        _e('2026-10-27', 'food_out', 900000), // after the last day
      ];
      final during = MoneyMath.challengeStatus(cap, txs, '2026-10-25');
      expect(during.spent, 500000);
      expect(during.running, isTrue);
      final after = MoneyMath.challengeStatus(cap, txs, '2026-10-27');
      expect(after.ended, isTrue);
      expect(after.won, isTrue);
    });

    test('cap: going over loses before the end; empty categories = all', () {
      const all = MoneyChallenge(
        id: 'a',
        title: 'Tuần này chi dưới 2tr',
        kind: MoneyChallengeKind.cap,
        limit: 2000000,
        startDate: '2026-10-20',
        days: 7,
      );
      final st = MoneyMath.challengeStatus(all, [
        _e('2026-10-21', 'shop_tech', 1500000),
        _e('2026-10-22', 'food_out', 600000),
      ], '2026-10-22');
      expect(st.spent, 2100000);
      expect(st.failed, isTrue);
    });
  });

  group('moneyRecapLines', () {
    test('only good news, at most 3, in order', () {
      final lines = moneyRecapLines(
        spent: 3000000,
        budget: 4000000,
        prevSpent: 3800000,
        saved: 1500000,
        challengesWon: 2,
        loggedDays: 25,
        daysInMonth: 31,
      );
      expect(lines.map((l) => l.kind), [
        MoneyRecapKind.keptBudget,
        MoneyRecapKind.spentLess,
        MoneyRecapKind.saved,
      ]);
      expect(lines[1].value, 800000);
    });

    test('spending more / over budget / few logged days say nothing', () {
      final lines = moneyRecapLines(
        spent: 5000000,
        budget: 4000000,
        prevSpent: 3000000,
        saved: 0,
        challengesWon: 0,
        loggedDays: 10,
        daysInMonth: 31,
      );
      expect(lines, isEmpty);
    });
  });
}
