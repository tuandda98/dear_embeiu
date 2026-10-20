// Sổ tiền (feature expenses) — parser, formatter, MoneyMath, categories.
// Sample figures are the Designer's reference book (docs/design/expenses/
// data.js): balance 359.000, shared wallet 948.000, split 75.001 → 37.501…
import 'package:dear_embeiu/data/money_categories.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/utils/money_input.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const me = 'tuan', partner = 'thao';
const members = [me, partner];

MoneyTx tx(
  String id,
  String date,
  MoneyTxType type,
  int amount, {
  String out = '',
  String into = '',
  String cat = '',
  String note = '',
  String? payer,
  MoneySplitMode? split,
  int share = 0,
  bool shared = false,
  bool pending = false,
  String? linkId,
}) => MoneyTx(
  id: id,
  type: type,
  amount: amount,
  date: date,
  outWalletId: out,
  inWalletId: into,
  categoryId: cat,
  note: note,
  payer: payer,
  splitMode: split,
  payerShare: share,
  memberUids: shared ? members : const [],
  pending: pending,
  linkId: linkId,
);

const e = MoneyTxType.expense;
const eq = MoneySplitMode.equal;

// data.js `sharedTx`.
final sharedTx = <MoneyTx>[
  tx(
    'c1',
    '2026-10-01',
    MoneyTxType.contribution,
    1000000,
    into: 'v_chung',
    payer: me,
    split: MoneySplitMode.none,
    shared: true,
  ),
  tx(
    'c2',
    '2026-10-01',
    MoneyTxType.contribution,
    1000000,
    into: 'v_chung',
    payer: partner,
    split: MoneySplitMode.none,
    shared: true,
  ),
  tx(
    's1',
    '2026-10-03',
    e,
    480000,
    cat: 'food_out',
    payer: me,
    split: eq,
    share: 240000,
    shared: true,
  ),
  tx(
    's2',
    '2026-10-04',
    e,
    70000,
    cat: 'move_fuel',
    payer: partner,
    split: MoneySplitMode.forPartner,
    shared: true,
  ),
  tx(
    's3',
    '2026-10-06',
    e,
    200000,
    cat: 'date_movie',
    payer: me,
    split: MoneySplitMode.treat,
    share: 200000,
    shared: true,
  ),
  tx(
    's4',
    '2026-10-08',
    e,
    640000,
    out: 'v_chung',
    cat: 'food_market',
    payer: kMoneyPayerWallet,
    split: MoneySplitMode.none,
    shared: true,
  ),
  tx(
    's5',
    '2026-10-10',
    e,
    90000,
    cat: 'food_coffee',
    payer: partner,
    split: eq,
    share: 45000,
    shared: true,
  ),
  tx(
    's6',
    '2026-10-11',
    e,
    150000,
    cat: 'food_out',
    payer: me,
    split: eq,
    share: 75000,
    shared: true,
  ),
  tx(
    'c3',
    '2026-10-12',
    MoneyTxType.contribution,
    1200000,
    into: 'v_dalat',
    payer: me,
    split: MoneySplitMode.none,
    shared: true,
  ),
  tx(
    's7',
    '2026-10-13',
    e,
    86000,
    cat: 'move_grab',
    payer: partner,
    split: eq,
    share: 43000,
    shared: true,
  ),
  tx(
    'c4',
    '2026-10-14',
    MoneyTxType.contribution,
    800000,
    into: 'v_dalat',
    payer: partner,
    split: MoneySplitMode.none,
    shared: true,
  ),
  tx(
    's9',
    '2026-10-15',
    e,
    1180000,
    cat: 'home_power',
    payer: me,
    split: eq,
    share: 590000,
    shared: true,
  ),
  tx(
    's8',
    '2026-10-16',
    MoneyTxType.settle,
    400000,
    payer: partner,
    split: MoneySplitMode.none,
    shared: true,
  ),
  tx(
    's10',
    '2026-10-17',
    e,
    412000,
    out: 'v_chung',
    cat: 'food_market',
    payer: kMoneyPayerWallet,
    split: MoneySplitMode.none,
    shared: true,
  ),
  tx(
    's12',
    '2026-10-18',
    e,
    60000,
    cat: 'food_snack',
    payer: partner,
    split: MoneySplitMode.treat,
    share: 60000,
    shared: true,
  ),
  tx(
    's11',
    '2026-10-19',
    e,
    110000,
    cat: 'food_coffee',
    payer: me,
    split: MoneySplitMode.custom,
    share: 50000,
    shared: true,
  ),
  tx(
    's13',
    '2026-10-20',
    e,
    96000,
    cat: 'home_water',
    payer: partner,
    split: eq,
    share: 48000,
    shared: true,
  ),
];

const wallet = MoneyWallet.new;

void main() {
  group('parseVndInput', () {
    const ok = <String, int>{
      '50k': 50000,
      '1tr': 1000000,
      '1tr2': 1200000,
      '1.5tr': 1500000,
      '1,5tr': 1500000,
      '2 triệu': 2000000,
      '1 củ': 1000000,
      '1 Củ': 1000000,
      '1 tỏi': 1000000000,
      '120000': 120000,
      '120.000': 120000,
      '1.200.000': 1200000,
      '1,200,000': 1200000,
      '50 nghìn': 50000,
      '2tr05': 2050000,
      '75001': 75001,
      '  120k ': 120000,
      '120.000 ₫': 120000,
      '10000000000': kMoneyTxMax,
      // Review stage 1, #1: a mark before three digits groups thousands.
      '1.500k': 1500000,
      '2.000k': 2000000,
      '1,500k': 1500000,
      '1.200tr': 1200000000,
      '1.25tr': 1250000,
      '0.5tr': 500000,
    };
    ok.forEach((input, value) {
      test('"$input" → $value', () {
        final r = parseVndInput(input);
        expect(r.ok, isTrue, reason: '$r');
        expect(r.value, value);
      });
    });

    test('units are echoed, plain numbers are not', () {
      expect(parseVndInput('1tr2').hasUnit, isTrue);
      expect(parseVndInput('120000').hasUnit, isFalse);
    });

    test('empty / invalid / zero lock Save, each with its own reason', () {
      expect(parseVndInput('').error, VndParseError.empty);
      expect(parseVndInput(null).error, VndParseError.empty);
      expect(parseVndInput('   ').error, VndParseError.empty);
      for (final s in [
        'abc',
        '1.2.3tr',
        '12x',
        '1,5',
        'k50',
        '1tr2tr',
        '1.5000tr',
        '1.5tr2',
        '1.500k2',
      ]) {
        expect(parseVndInput(s).error, VndParseError.invalid, reason: s);
      }
      expect(parseVndInput('0').error, VndParseError.zero);
      expect(parseVndInput('0k').error, VndParseError.zero);
    });

    test('over 10 tỷ is tooBig (not "invalid") and keeps the value', () {
      final r = parseVndInput('10000000001');
      expect(r.error, VndParseError.tooBig);
      expect(r.value, 10000000001);
      expect(parseVndInput('11 tỷ').error, VndParseError.tooBig);
      expect(
        parseVndInput('99999999999999999999999').error,
        VndParseError.tooBig,
      );
    });

    test('a huge number with a unit says tooBig instead of throwing', () {
      final long = '1${'0' * 400}';
      for (final s in ['${long}k', '$long tỷ', '${long}tr5', long]) {
        final r = parseVndInput(s);
        expect(r.error, VndParseError.tooBig, reason: s);
        expect(r.value, kMoneyTxMax + 1);
      }
    });

    test('wallet balances allow up to 100 tỷ', () {
      expect(parseVndInput('50 tỷ').error, VndParseError.tooBig);
      expect(parseVndInput('50 tỷ', max: kMoneyWalletMax).value, 50000000000);
    });
  });

  group('formatVnd', () {
    test('vi / en / negative', () {
      expect(formatVnd(1250000, locale: 'vi'), '1.250.000 ₫');
      expect(formatVnd(1250000, locale: 'en'), '₫1,250,000');
      expect(formatVnd(-320000, locale: 'vi'), '−320.000 ₫');
      expect(formatVnd(0, locale: 'vi'), '0 ₫');
    });

    test('short form', () {
      expect(formatVndShort(1200000, locale: 'vi'), '1,2tr');
      expect(formatVndShort(1200000, locale: 'en'), '1.2M');
      expect(formatVndShort(50000, locale: 'vi'), '50k');
      expect(formatVndShort(50000, locale: 'en'), '50K');
      expect(formatVndShort(3500000000, locale: 'vi'), '3,5 tỷ');
      expect(formatVndShort(3500000000, locale: 'en'), '3.5B');
      expect(formatVndShort(9552000, locale: 'vi'), '9,6tr');
      expect(formatVndShort(999950, locale: 'vi'), '1tr');
      expect(formatVndShort(500, locale: 'vi'), '500');
      expect(formatVndShort(-240000, locale: 'vi'), '−240k');
    });
  });

  group('MoneyMath — own book', () {
    final wallets = [
      wallet(
        id: 'cash',
        name: 'Tiền mặt',
        type: MoneyWalletType.cash,
        openingBalance: 500000,
      ),
      wallet(
        id: 'momo',
        name: 'MoMo',
        type: MoneyWalletType.ewallet,
        openingBalance: 1500000,
      ),
      wallet(id: 'tcb', name: 'Techcombank', type: MoneyWalletType.bank),
      wallet(
        id: 'vib',
        name: 'Thẻ VIB',
        type: MoneyWalletType.credit,
        openingBalance: -2000000,
      ),
      wallet(
        id: 'hold',
        name: 'Giữ hộ',
        type: MoneyWalletType.cash,
        openingBalance: 300000,
        includeInTotal: false,
      ),
      wallet(
        id: 'goal',
        name: 'Laptop',
        type: MoneyWalletType.goal,
        openingBalance: 6000000,
        includeInTotal: false,
      ),
    ];
    // Acceptance §6: spend 120k from MoMo, salary 15tr into Techcombank,
    // move 500k Techcombank → cash, adjust MoMo down to 1.000.000.
    final txs = [
      tx('a', '2026-10-20', e, 120000, out: 'momo', cat: 'food_out'),
      tx(
        'b',
        '2026-10-05',
        MoneyTxType.income,
        15000000,
        into: 'tcb',
        cat: 'salary',
      ),
      tx(
        'c',
        '2026-10-10',
        MoneyTxType.transfer,
        500000,
        out: 'tcb',
        into: 'cash',
      ),
      tx('d', '2026-10-19', MoneyTxType.adjust, 380000, out: 'momo'),
      tx('old', '2026-09-30', e, 99000, out: 'cash', cat: 'food_snack'),
    ];

    test('balances for all 4 entry types', () {
      final b = MoneyMath.balancesFrom(wallets, txs);
      expect(b['momo'], 1000000);
      expect(b['tcb'], 14500000);
      expect(b['cash'], 500000 + 500000 - 99000);
      expect(b['vib'], -2000000);
      expect(
        MoneyMath.walletBalance(wallets[1], sumIn: 0, sumOut: 500000),
        1000000,
      );
    });

    test('transfers / adjustments never count as spending or income', () {
      final t = MoneyMath.monthTotals(txs, '2026-10');
      expect(t.expense, 120000);
      expect(t.income, 15000000);
      expect(t.left, 15000000 - 120000);
      expect(MoneyMath.monthTotals(txs, '2026-09').expense, 99000);
    });

    test(
      'total excludes goals, switched-off and archived wallets; credit lowers it',
      () {
        final b = MoneyMath.balancesFrom(wallets, txs);
        expect(
          MoneyMath.totalAssets(wallets, b),
          b['cash']! + 1000000 + 14500000 - 2000000,
        );
        final archived = [
          ...wallets,
          wallet(
            id: 'z',
            name: 'Cũ',
            type: MoneyWalletType.cash,
            openingBalance: 9,
            archived: true,
          ),
        ];
        expect(
          MoneyMath.totalAssets(archived, b),
          MoneyMath.totalAssets(wallets, b),
        );
      },
    );

    test('pending entries add on top of a cached aggregate', () {
      final p = [
        tx('p1', '2026-10-20', e, 35000, out: 'momo', pending: true),
        tx(
          'p2',
          '2026-10-20',
          MoneyTxType.transfer,
          10000,
          out: 'tcb',
          into: 'momo',
          pending: true,
        ),
        tx('p3', '2026-10-20', e, 1, out: 'momo'),
      ];
      expect(MoneyMath.pendingDelta(p, 'momo'), -25000);
      expect(MoneyMath.pendingDelta(p, 'tcb'), -10000);
    });

    test('wallet cap ±100 tỷ', () {
      expect(MoneyMath.walletWithinCap(kMoneyWalletMax), isTrue);
      expect(MoneyMath.walletWithinCap(kMoneyWalletMax + 1), isFalse);
      expect(MoneyMath.walletWithinCap(-kMoneyWalletMax - 1), isFalse);
    });

    test('by category (level 1 via groupOf) adds up to the month', () {
      final idx = MoneyCategoryIndex(
        resolveMoneyCategories(
          MoneyMeta.empty,
          lookupAppLocalizations(const Locale('vi')),
        ),
      );
      final rows = [
        tx('1', '2026-10-01', e, 4500000, out: 'tcb', cat: 'home_rent'),
        tx('2', '2026-10-02', e, 300000, out: 'tcb', cat: 'food_out'),
        tx('3', '2026-10-03', e, 200000, out: 'cash', cat: 'food_coffee'),
        tx('4', '2026-10-04', e, 100000, out: 'cash', cat: 'gone_custom'),
      ];
      final groups = MoneyMath.byCategory(
        rows,
        '2026-10',
        groupOf: idx.groupOf,
      );
      expect(groups, [('home', 4500000), ('food', 500000), ('other', 100000)]);
      expect(
        groups.fold<int>(0, (s, g) => s + g.$2),
        MoneyMath.monthTotals(rows, '2026-10').expense,
      );
      expect(MoneyMath.byCategory(rows, '2026-10').first, (
        'home_rent',
        4500000,
      ));
      expect(MoneyMath.byWallet(rows, '2026-10'), [
        ('tcb', 4800000),
        ('cash', 300000),
      ]);
      expect(
        MoneyMath.spentIn(
          rows,
          '2026-10',
          categoryId: 'food',
          groupOf: idx.groupOf,
        ),
        500000,
      );
      expect(MoneyMath.spentIn(rows, '2026-10'), 5100000);
    });
  });

  group('MoneyMath — budgets', () {
    test('80 / 100 % levels (Ăn uống 2tr)', () {
      expect(MoneyMath.budgetStatus(1590000, 2000000).level, 0);
      expect(MoneyMath.budgetStatus(1600000, 2000000).level, 80);
      expect(MoneyMath.budgetStatus(1600000, 2000000).percent, 80);
      expect(MoneyMath.budgetStatus(2000000, 2000000).level, 100);
      expect(MoneyMath.budgetStatus(2062000, 2000000).left, -62000);
      expect(MoneyMath.budgetStatus(1999999, 2000000).percent, 99);
      expect(MoneyMath.budgetStatus(10, 0).level, 0);
    });

    test('crossing a line is reported once, a new month starts at 0', () {
      expect(MoneyMath.crossedLevel(1500000, 1600000, 2000000), 80);
      expect(MoneyMath.crossedLevel(1600000, 1700000, 2000000), isNull);
      expect(MoneyMath.crossedLevel(1500000, 2100000, 2000000), 100);
      final rows = [
        tx('1', '2026-10-31', e, 1900000, out: 'w', cat: 'food_out'),
      ];
      expect(MoneyMath.spentIn(rows, '2026-11'), 0);
    });
  });

  group('MoneyMath — shared book', () {
    test('balance of the reference book = 359.000 (I covered more)', () {
      expect(MoneyMath.coupleBalance(sharedTx, me), 359000);
      expect(MoneyMath.coupleBalance(sharedTx, partner), -359000);
      expect(MoneyMath.settlementFor(359000, me: me, partner: partner), (
        payer: partner,
        amount: 359000,
      ));
      expect(MoneyMath.settlementFor(0, me: me, partner: partner), isNull);
    });

    test('acceptance §6 scenario, step by step', () {
      final rows = <MoneyTx>[
        tx(
          '1',
          '2026-10-01',
          e,
          480000,
          payer: me,
          split: eq,
          share: 240000,
          shared: true,
        ),
      ];
      expect(MoneyMath.coupleBalance(rows, me), 240000);
      rows.add(
        tx(
          '2',
          '2026-10-01',
          e,
          70000,
          payer: partner,
          split: MoneySplitMode.forPartner,
          shared: true,
        ),
      );
      expect(MoneyMath.coupleBalance(rows, me), 170000);
      rows.add(
        tx(
          '3',
          '2026-10-01',
          e,
          200000,
          payer: me,
          split: MoneySplitMode.treat,
          share: MoneyMath.payerShareFor(MoneySplitMode.treat, 200000),
          shared: true,
        ),
      );
      expect(MoneyMath.coupleBalance(rows, me), 170000);
      // Partial settlement: the partner pays back 100k of 170k.
      rows.add(
        tx(
          'p',
          '2026-10-01',
          MoneyTxType.settle,
          100000,
          payer: partner,
          split: MoneySplitMode.none,
          shared: true,
        ),
      );
      expect(MoneyMath.coupleBalance(rows, me), 70000);
      // "Tuỳ 300k, A chịu 100k" → B owes 200k more.
      rows.add(
        tx(
          '4',
          '2026-10-01',
          e,
          300000,
          payer: me,
          split: MoneySplitMode.custom,
          share: 100000,
          shared: true,
        ),
      );
      expect(MoneyMath.coupleBalance(rows, me), 270000);
      final settle = MoneyMath.settlementFor(
        MoneyMath.coupleBalance(rows, me),
        me: me,
        partner: partner,
      )!;
      expect(settle, (payer: partner, amount: 270000));
      rows.add(
        tx(
          '5',
          '2026-10-02',
          MoneyTxType.settle,
          settle.amount,
          payer: settle.payer,
          split: MoneySplitMode.none,
          shared: true,
        ),
      );
      expect(MoneyMath.coupleBalance(rows, me), 0);
      expect(MoneyMath.monthTotals(rows, '2026-10').expense, 1050000);
    });

    test(
      'payerShare for the 4 splits (odd amounts round up for the payer)',
      () {
        expect(MoneyMath.payerShareFor(eq, 75001), 37501);
        expect(MoneyMath.payerShareFor(eq, 480000), 240000);
        expect(MoneyMath.payerShareFor(MoneySplitMode.treat, 200000), 200000);
        expect(MoneyMath.payerShareFor(MoneySplitMode.forPartner, 70000), 0);
        expect(
          MoneyMath.payerShareFor(
            MoneySplitMode.custom,
            300000,
            custom: 100000,
          ),
          100000,
        );
        expect(
          MoneyMath.payerShareFor(
            MoneySplitMode.custom,
            300000,
            custom: 999999,
          ),
          300000,
        );
        expect(MoneyMath.payerShareFor(MoneySplitMode.none, 1), 0);
      },
    );

    test('three lanes add up to the month; shared wallet = in − out', () {
      final paid = MoneyMath.paidBy(sharedTx, '2026-10');
      expect(paid, {me: 2120000, partner: 402000, kMoneyPayerWallet: 1052000});
      expect(
        paid.values.fold<int>(0, (s, v) => s + v),
        MoneyMath.monthTotals(sharedTx, '2026-10').expense,
      );
      final wallets = [
        wallet(id: 'v_chung', name: 'Ví chung', type: MoneyWalletType.cash),
        wallet(
          id: 'v_dalat',
          name: 'Quỹ Đà Lạt',
          type: MoneyWalletType.goal,
          goalTarget: 5000000,
        ),
      ];
      final b = MoneyMath.balancesFrom(wallets, sharedTx);
      expect(b['v_chung'], 2000000 - 1052000);
      expect(b['v_dalat'], 2000000);
      expect(MoneyMath.contributionsBy(sharedTx, walletId: 'v_dalat'), {
        me: 1200000,
        partner: 800000,
      });
      expect(
        MoneyMath.contributionsBy(sharedTx, month: '2026-10')[partner],
        1800000,
      );
    });

    test('goal progress + per month needed (Quỹ Đà Lạt)', () {
      expect(MoneyMath.goalPercent(2000000, 5000000), 40);
      expect(MoneyMath.goalPercent(-5, 5000000), 0);
      expect(MoneyMath.goalPercent(5200000, 5000000), 104);
      expect(MoneyMath.monthsUntil('2026-10-20', '2027-01-31'), 3);
      expect(
        MoneyMath.perMonthNeeded(3000000, '2026-10-20', '2027-01-31'),
        1000000,
      );
      expect(
        MoneyMath.perMonthNeeded(1000001, '2026-10-20', '2027-01-31'),
        334000,
      );
      expect(
        MoneyMath.perMonthNeeded(500000, '2026-10-20', '2026-10-25'),
        500000,
      );
      expect(MoneyMath.perMonthNeeded(0, '2026-10-20', '2027-01-31'), 0);
    });

    test('a linked own entry drifts when the shared amount changed', () {
      final own = tx('o', '2026-10-03', e, 480000, out: 'tcb', linkId: 'L2');
      final shared = tx(
        's',
        '2026-10-03',
        e,
        520000,
        payer: me,
        split: eq,
        share: 260000,
        shared: true,
        linkId: 'L2',
      );
      expect(MoneyMath.linkedDrift(own, shared), 520000);
      expect(
        MoneyMath.linkedDrift(own, shared.copyWith(amount: 480000)),
        isNull,
      );
      expect(MoneyMath.linkedDrift(own, null), isNull);
    });
  });

  group('MoneyMath — defaults', () {
    final now = DateTime(2026, 10, 20, 12);
    test('category = most used over 14 days, tie → most recent', () {
      final rows = [
        tx('1', '2026-10-19', e, 1, cat: 'home_water'),
        tx('2', '2026-10-18', e, 1, cat: 'food_coffee'),
        tx('3', '2026-10-17', e, 1, cat: 'food_coffee'),
        tx('4', '2026-10-01', e, 1, cat: 'home_rent'),
        tx('5', '2026-10-01', e, 1, cat: 'home_rent'),
        tx('6', '2026-10-01', e, 1, cat: 'home_rent'),
      ];
      expect(
        MoneyMath.defaultCategory(rows, e, now: now, fallback: 'food_out'),
        'food_coffee',
      );
      rows.add(tx('7', '2026-10-20', e, 1, cat: 'home_water'));
      expect(
        MoneyMath.defaultCategory(rows, e, now: now, fallback: 'food_out'),
        'home_water',
      );
      expect(
        MoneyMath.defaultCategory(
          rows,
          e,
          now: now,
          fallback: 'food_out',
          isPickable: (id) => id != 'home_water',
        ),
        'food_coffee',
      );
      expect(
        MoneyMath.defaultCategory(
          [tx('x', '2026-08-01', e, 1, cat: 'shop_tech')],
          e,
          now: now,
          fallback: 'food_out',
        ),
        'shop_tech',
      );
      expect(
        MoneyMath.defaultCategory(const [], e, now: now, fallback: 'food_out'),
        'food_out',
      );
      expect(
        MoneyMath.defaultCategory(
          rows,
          MoneyTxType.income,
          now: now,
          fallback: 'salary',
        ),
        'salary',
      );
    });

    test('wallet = the one last used with that category', () {
      final wallets = [
        wallet(
          id: 'cash',
          name: 'Tiền mặt',
          type: MoneyWalletType.cash,
          order: 1,
        ),
        wallet(
          id: 'momo',
          name: 'MoMo',
          type: MoneyWalletType.ewallet,
          order: 0,
        ),
        wallet(
          id: 'old',
          name: 'Cũ',
          type: MoneyWalletType.bank,
          archived: true,
        ),
      ];
      final rows = [
        tx('1', '2026-10-19', e, 1, out: 'cash', cat: 'food_coffee'),
        tx('2', '2026-10-18', e, 1, out: 'momo', cat: 'food_out'),
        tx('3', '2026-10-20', e, 1, out: 'old', cat: 'food_out'),
      ];
      expect(
        MoneyMath.defaultWallet(rows, wallets, categoryId: 'food_coffee'),
        'cash',
      );
      expect(
        MoneyMath.defaultWallet(rows, wallets, categoryId: 'food_out'),
        'momo',
      );
      expect(
        MoneyMath.defaultWallet(
          rows,
          wallets,
          categoryId: 'shop',
          preferred: 'cash',
        ),
        'cash',
      );
      expect(
        MoneyMath.defaultWallet(rows, wallets, categoryId: 'shop'),
        'momo',
      );
      expect(
        MoneyMath.defaultWallet(rows, const [], categoryId: 'shop'),
        isNull,
      );
    });

    test('quick repeats = latest of the 3 most used expense categories', () {
      final rows = [
        tx(
          '1',
          '2026-10-20',
          e,
          35000,
          cat: 'food_coffee',
          note: 'Cà phê sáng',
        ),
        tx('2', '2026-10-19', e, 30000, cat: 'food_coffee'),
        tx('3', '2026-10-19', e, 5000, cat: 'move_parking', note: 'Gửi xe'),
        tx('4', '2026-10-18', e, 5000, cat: 'move_parking'),
        tx('5', '2026-10-17', e, 5000, cat: 'move_parking'),
        tx('6', '2026-10-17', e, 50000, cat: 'food_out'),
        tx('7', '2026-10-16', e, 9, cat: 'shop'),
        tx('8', '2026-10-16', MoneyTxType.income, 9, cat: 'salary'),
      ];
      expect(MoneyMath.quickRepeats(rows).map((t) => t.id), ['3', '1', '6']);
    });
  });

  group('search', () {
    final rows = [
      tx(
        '1',
        '2026-10-11',
        e,
        150000,
        out: 'momo',
        cat: 'food_out',
        note: 'Bún chả Hàng Mành',
      ),
      tx(
        '2',
        '2026-09-21',
        e,
        140000,
        out: 'momo',
        cat: 'food_out',
        note: 'Bún chả Đắc Kim',
      ),
      tx(
        '3',
        '2026-08-30',
        e,
        120000,
        out: 'cash',
        cat: 'food_out',
        note: 'BÚN CHẢ que tre',
      ),
      tx(
        '4',
        '2026-08-12',
        e,
        65000,
        out: 'cash',
        cat: 'food_out',
        note: 'Bún bò Huế',
      ),
      tx('5', '2026-08-12', e, 65000, out: 'cash', cat: 'food_coffee'),
    ];
    test('accents and case do not matter', () {
      expect(MoneyMath.fold('Bún chả Đắc Kim'), 'bun cha dac kim');
      expect(MoneyMath.fold('Bún'), 'bun'); // NFD
      expect(MoneyMath.search(rows, query: 'bun cha').map((t) => t.id), [
        '1',
        '2',
        '3',
      ]);
      expect(MoneyMath.search(rows, query: 'lau de'), isEmpty);
    });

    test('category name, wallet and amount filters', () {
      expect(
        MoneyMath.search(
          rows,
          query: 'tra sua',
          categoryName: (id) =>
              id == 'food_coffee' ? 'Cà phê, trà sữa' : 'Ăn ngoài',
        ).map((t) => t.id),
        ['5'],
      );
      expect(
        MoneyMath.search(
          rows,
          walletIds: {'momo'},
          minAmount: 100000,
          maxAmount: 500000,
        ).map((t) => t.id),
        ['1', '2'],
      );
      expect(
        MoneyMath.search(
          rows,
          categoryIds: {'food'},
          groupOf: (_) => 'food',
        ).length,
        5,
      );
    });

    test('every accented letter folds', () {
      expect(
        MoneyMath.fold(
          'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ',
        ),
        '${'a' * 17}${'e' * 11}${'i' * 5}${'o' * 17}${'u' * 11}${'y' * 5}d',
      );
    });
  });

  group('months', () {
    test('ranges and trend windows', () {
      expect(MoneyMath.monthRange('2026-02'), ('2026-02-01', '2026-02-28'));
      expect(MoneyMath.monthRange('2028-02'), ('2028-02-01', '2028-02-29'));
      expect(MoneyMath.addMonths('2026-01', -1), '2025-12');
      expect(MoneyMath.trendMonths('2026-10', 6), [
        '2026-05',
        '2026-06',
        '2026-07',
        '2026-08',
        '2026-09',
        '2026-10',
      ]);
      expect(MoneyMath.trendMonths('2026-10', 12).first, '2025-11');
      expect(MoneyMath.dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('categories', () {
    for (final lang in ['vi', 'en']) {
      test(
        '12 expense groups + children and 6 income groups, all named ($lang)',
        () {
          final l = lookupAppLocalizations(Locale(lang));
          final idx = MoneyCategoryIndex(
            resolveMoneyCategories(MoneyMeta.empty, l),
          );
          final expenseGroups = idx
              .pickable(MoneyTxType.expense)
              .where((c) => c.isGroup);
          final incomeGroups = idx
              .pickable(MoneyTxType.income)
              .where((c) => c.isGroup);
          expect(expenseGroups.length, 12);
          expect(incomeGroups.length, 6);
          expect(kMoneyDefaultCategories.length, 53);
          final names = <String>{};
          for (final c in kMoneyDefaultCategories) {
            final name = moneyDefaultCategoryName(l, c.id);
            expect(name, isNotEmpty);
            // Only "other" may fall back to the "other" name.
            if (c.id != kMoneyCategoryOther) {
              expect(name == l.moneyCatOther, isFalse, reason: c.id);
            }
            names.add('${c.parentId}/$name');
            expect(
              c.emoji.length,
              lessThanOrEqualTo(kMoneyEmojiMax),
              reason: c.id,
            );
            expect(c.id.length, lessThanOrEqualTo(kMoneyIdMax));
            if (c.parentId.isNotEmpty) {
              expect(idx.of(c.parentId).isGroup, isTrue, reason: c.id);
            }
          }
          expect(
            idx.of('food_coffee').name,
            lang == 'vi' ? 'Cà phê, trà sữa' : 'Coffee & bubble tea',
          );
        },
      );
    }

    test('add / rename / hide per book; old entries keep the name', () {
      final l = lookupAppLocalizations(const Locale('vi'));
      final meta = MoneyMeta.fromDoc({
        'customCategories': [
          {
            'id': 'c_badminton',
            'kind': 'expense',
            'parentId': 'health',
            'name': 'Cầu lông',
            'emoji': '🏸',
          },
          {'id': 'broken'},
        ],
        'overrides': {
          'food_coffee': {'name': 'Trà sữa', 'emoji': ''},
        },
        'hiddenCategoryIds': ['edu'],
      });
      final idx = MoneyCategoryIndex(resolveMoneyCategories(meta, l));
      expect(idx.of('c_badminton').name, 'Cầu lông');
      expect(idx.of('c_badminton').isCustom, isTrue);
      expect(idx.groupOf('c_badminton'), 'health');
      expect(idx.of('food_coffee').name, 'Trà sữa');
      expect(idx.of('food_coffee').originalName, 'Cà phê, trà sữa');
      expect(idx.of('food_coffee').emoji, '☕');
      expect(
        idx.pickable(MoneyTxType.expense).any((c) => c.id == 'edu'),
        isFalse,
      );
      expect(idx.of('edu').name, 'Học tập');
      expect(idx.of('deleted_custom').id, kMoneyCategoryOther);
      expect(
        idx.of('deleted_custom', kind: MoneyTxType.income).id,
        kMoneyCategoryIncomeOther,
      );
    });
  });

  group('MoneyTx.isWellFormed mirrors the rules', () {
    test('own book', () {
      expect(tx('1', '2026-10-20', e, 1, out: 'w').isWellFormed, isTrue);
      expect(tx('1', '2026-10-20', e, 0, out: 'w').isWellFormed, isFalse);
      expect(
        tx('1', '2026-10-20', e, kMoneyTxMax + 1, out: 'w').isWellFormed,
        isFalse,
      );
      expect(tx('1', '2026-10-20', e, 1).isWellFormed, isFalse);
      expect(tx('1', '20261020', e, 1, out: 'w').isWellFormed, isFalse);
      expect(
        tx(
          '1',
          '2026-10-20',
          MoneyTxType.transfer,
          1,
          out: 'w',
          into: 'w',
        ).isWellFormed,
        isFalse,
      );
      expect(
        tx(
          '1',
          '2026-10-20',
          MoneyTxType.adjust,
          1,
          out: 'w',
          into: 'v',
        ).isWellFormed,
        isFalse,
      );
      expect(
        tx('1', '2026-10-20', MoneyTxType.settle, 1).isWellFormed,
        isFalse,
      );
      expect(
        tx('1', '2026-10-20', e, 1, out: 'w', payer: me).isWellFormed,
        isFalse,
      );
      expect(
        tx('1', '2026-10-20', e, 1, out: 'w', note: 'x' * 201).isWellFormed,
        isFalse,
      );
    });

    test('shared book', () {
      for (final t in sharedTx) {
        expect(t.isWellFormed, isTrue, reason: t.id);
      }
      // Review stage 1, #3: a person paid AND the shared wallet paid.
      expect(
        tx(
          '1',
          '2026-10-20',
          e,
          120000,
          out: 'joint',
          payer: me,
          share: 60000,
          shared: true,
        ).isWellFormed,
        isFalse,
      );
      expect(
        tx(
          '1',
          '2026-10-20',
          e,
          1,
          payer: 'mallory',
          shared: true,
        ).isWellFormed,
        isFalse,
      );
      expect(
        tx(
          '1',
          '2026-10-20',
          e,
          1,
          payer: kMoneyPayerWallet,
          shared: true,
        ).isWellFormed,
        isFalse,
      );
      expect(
        tx(
          '1',
          '2026-10-20',
          e,
          10,
          payer: me,
          share: 11,
          shared: true,
        ).isWellFormed,
        isFalse,
      );
      expect(
        tx(
          '1',
          '2026-10-20',
          MoneyTxType.settle,
          10,
          payer: me,
          share: 1,
          shared: true,
        ).isWellFormed,
        isFalse,
      );
    });
  });
}
