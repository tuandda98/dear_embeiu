import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/providers/money_provider.dart';
import 'package:dear_embeiu/screens/money/money_budgets_screen.dart';
import 'package:dear_embeiu/screens/money/money_report_screen.dart';
import 'package:dear_embeiu/screens/money/money_search_screen.dart';
import 'package:dear_embeiu/services/money_service.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/utils/money_views.dart';
import 'package:dear_embeiu/widgets/money/money_ui.dart';

/// Sổ tiền stage 3A (feature expenses): budgets (thresholds, set / remove),
/// the report against the reference numbers of `docs/design/expenses/
/// data.js` (Tuấn = me, Thảo, today 20/10/2026), and search (no accents,
/// 2.000 cap, 12 months, filters).

// ── Firestore stand-ins: only `collection().doc()` paths are touched ───────

int _ids = 0;

// ignore: subtype_of_sealed_class
class _FakeDoc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _FakeDoc(this.id);

  @override
  final String id;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCol();
}

// ignore: subtype_of_sealed_class
class _FakeCol extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FakeDoc(path ?? 'gen${_ids++}');
}

class _FakeDb extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCol();
}

final _db = _FakeDb();
const _me = 'tuan', _her = 'thao';
const _pair = [_her, _me];
const _today = '2026-10-20';
const _m = '2026-10';

class _Money extends MoneyProvider {
  _Money({this.trendData}) : super(clock: () => DateTime(2026, 10, 20, 12));

  final Map<String, MoneyMonthTotals?>? trendData;
  final List<({MoneyBookKind kind, String cat, int amount})> set = [];
  final List<({MoneyBookKind kind, String id})> deleted = [];

  @override
  Future<MoneyWriteOutcome> setBudget(
    MoneyBookKind kind, {
    required String categoryId,
    required int amount,
  }) async {
    set.add((kind: kind, cat: categoryId, amount: amount));
    return MoneyWriteOutcome.saved;
  }

  @override
  Future<MoneyWriteOutcome> deleteBudget(MoneyBookKind kind, String id) async {
    deleted.add((kind: kind, id: id));
    return MoneyWriteOutcome.saved;
  }

  @override
  Future<Map<String, MoneyMonthTotals?>> trend(
    MoneyBookKind kind,
    int n,
  ) async =>
      trendData ?? {for (final m in MoneyMath.trendMonths(_m, n)) m: null};

  @override
  void refreshDay() {}
}

// ── data.js, sổ của mình ───────────────────────────────────────────────────

MoneyTx _o(
  String id,
  String date,
  MoneyTxType type,
  int amount,
  String out,
  String inn,
  String cat,
  String note,
) => MoneyTx(
  id: id,
  type: type,
  amount: amount,
  date: date,
  outWalletId: out,
  inWalletId: inn,
  categoryId: cat,
  note: note,
);

const _e = MoneyTxType.expense;
final _ownTx = <MoneyTx>[
  _o(
    'o1',
    '2026-10-01',
    _e,
    4500000,
    'w_tcb',
    '',
    'home_rent',
    'Tiền nhà tháng 10',
  ),
  _o(
    'o2',
    '2026-10-01',
    MoneyTxType.contribution,
    1000000,
    'w_tcb',
    '',
    '',
    'Góp vào Ví chung',
  ),
  _o(
    'o3',
    '2026-10-03',
    _e,
    480000,
    'w_tcb',
    '',
    'food_out',
    'Lẩu Thái Phố Huế',
  ),
  _o(
    'o4',
    '2026-10-05',
    MoneyTxType.adjust,
    18500000,
    '',
    'w_tcb',
    'salary',
    'Lương tháng 10',
  ),
  _o(
    'o5',
    '2026-10-05',
    _e,
    1500000,
    'w_tcb',
    '',
    'family_parents',
    'Biếu bố mẹ',
  ),
  _o(
    'o6',
    '2026-10-06',
    _e,
    200000,
    'w_momo',
    '',
    'date_movie',
    'CGV Vincom Bà Triệu',
  ),
  _o('o7', '2026-10-07', _e, 65000, 'w_cash', '', 'food_coffee', 'Cà phê sáng'),
  _o(
    'o8',
    '2026-10-08',
    _e,
    399000,
    'w_vib',
    '',
    'shop_clothes',
    'Áo phông Uniqlo',
  ),
  _o(
    'o9',
    '2026-10-09',
    _e,
    79000,
    'w_vib',
    '',
    'bill_stream',
    'YouTube Premium',
  ),
  _o(
    'o10',
    '2026-10-10',
    MoneyTxType.transfer,
    500000,
    'w_tcb',
    'w_cash',
    '',
    'Rút tiền mặt',
  ),
  _o(
    'o11',
    '2026-10-11',
    _e,
    150000,
    'w_momo',
    '',
    'food_out',
    'Bún chả Hàng Mành',
  ),
  _o(
    'o12',
    '2026-10-12',
    MoneyTxType.adjust,
    2000000,
    '',
    'w_momo',
    'side',
    'Thiết kế logo cho anh Long',
  ),
  _o(
    'o13',
    '2026-10-12',
    MoneyTxType.contribution,
    1200000,
    'w_momo',
    '',
    '',
    'Góp Quỹ Đà Lạt',
  ),
  _o('o14', '2026-10-13', _e, 30000, 'w_cash', '', 'food_snack', 'Bánh mì'),
  _o('o15', '2026-10-14', _e, 80000, 'w_cash', '', 'move_fuel', 'Đổ xăng'),
  _o(
    'o16',
    '2026-10-15',
    _e,
    1180000,
    'w_tcb',
    '',
    'home_power',
    'Tiền điện tháng 9',
  ),
  _o(
    'o17',
    '2026-10-16',
    _e,
    180000,
    'w_vib',
    '',
    'health_sport',
    'Cầu lông tháng 10',
  ),
  _o('o18', '2026-10-17', _e, 59000, 'w_cash', '', 'food_coffee', 'Highlands'),
  _o(
    'o19',
    '2026-10-18',
    _e,
    350000,
    'w_vib',
    '',
    'date_gift',
    'Hoa tặng Thảo',
  ),
  _o(
    'o20',
    '2026-10-19',
    _e,
    110000,
    'w_cash',
    '',
    'food_coffee',
    'Cà phê The Note',
  ),
  _o(
    'o21',
    '2026-10-19',
    MoneyTxType.adjust,
    23000,
    'w_cash',
    '',
    '',
    'Điều chỉnh số dư',
  ),
  _o('o22', '2026-10-20', _e, 45000, 'w_cash', '', 'food_out', 'Phở sáng'),
  _o(
    'o23',
    '2026-10-20',
    _e,
    120000,
    'w_momo',
    '',
    'food_out',
    'Cơm trưa với team',
  ),
  _o('o24', '2026-10-20', _e, 25000, 'w_cash', '', 'move_parking', 'Gửi xe'),
];
final _ownOlder = <MoneyTx>[
  _o(
    'o-s1',
    '2026-09-21',
    _e,
    140000,
    'w_momo',
    '',
    'food_out',
    'Bún chả Đắc Kim',
  ),
  _o(
    'o-a1',
    '2026-08-30',
    _e,
    120000,
    'w_cash',
    '',
    'food_out',
    'Bún chả que tre',
  ),
  _o('o-a2', '2026-08-12', _e, 65000, 'w_cash', '', 'food_out', 'Bún bò Huế'),
];
const _ownHistory = <String, int>{
  '2025-11': 7850000,
  '2025-12': 8930000,
  '2026-01': 9410000,
  '2026-02': 13260000,
  '2026-03': 8120000,
  '2026-04': 7640000,
  '2026-05': 8870000,
  '2026-06': 9050000,
  '2026-07': 8310000,
  '2026-08': 10480000,
  '2026-09': 8760000,
};

const _ownWallets = <MoneyWallet>[
  MoneyWallet(
    id: 'w_cash',
    name: 'Tiền mặt',
    type: MoneyWalletType.cash,
    emoji: '💵',
    order: 0,
  ),
  MoneyWallet(
    id: 'w_tcb',
    name: 'Techcombank',
    type: MoneyWalletType.bank,
    emoji: '🏦',
    order: 1,
  ),
  MoneyWallet(
    id: 'w_momo',
    name: 'MoMo',
    type: MoneyWalletType.ewallet,
    emoji: '📱',
    order: 2,
  ),
  MoneyWallet(
    id: 'w_vib',
    name: 'Thẻ VIB',
    type: MoneyWalletType.credit,
    emoji: '💳',
    order: 3,
  ),
];

// ── data.js, sổ chung ──────────────────────────────────────────────────────

MoneyTx _s(
  String id,
  String date,
  MoneyTxType type,
  int amount,
  String out,
  String inn,
  String cat,
  String note,
  String payer,
) => MoneyTx(
  id: id,
  type: type,
  amount: amount,
  date: date,
  outWalletId: out,
  inWalletId: inn,
  categoryId: cat,
  note: note,
  payer: payer == 'wallet' ? kMoneyPayerWallet : payer,
  memberUids: _pair,
);

const _c = MoneyTxType.contribution;
final _sharedTx = <MoneyTx>[
  _s('c1', '2026-10-01', _c, 1000000, '', 'v_chung', '', 'Góp đầu tháng', _me),
  _s('c2', '2026-10-01', _c, 1000000, '', 'v_chung', '', 'Góp đầu tháng', _her),
  _s(
    's1',
    '2026-10-03',
    _e,
    480000,
    '',
    '',
    'food_out',
    'Lẩu Thái Phố Huế',
    _me,
  ),
  _s(
    's2',
    '2026-10-04',
    _e,
    70000,
    '',
    '',
    'move_fuel',
    'Đổ xăng cho anh',
    _her,
  ),
  _s(
    's3',
    '2026-10-06',
    _e,
    200000,
    '',
    '',
    'date_movie',
    'CGV Vincom Bà Triệu',
    _me,
  ),
  _s(
    's4',
    '2026-10-08',
    _e,
    640000,
    'v_chung',
    '',
    'food_market',
    'Đi chợ cuối tuần',
    'wallet',
  ),
  _s(
    's5',
    '2026-10-10',
    _e,
    90000,
    '',
    '',
    'food_coffee',
    'Trà sữa Phúc Long',
    _her,
  ),
  _s(
    's6',
    '2026-10-11',
    _e,
    150000,
    '',
    '',
    'food_out',
    'Bún chả Hàng Mành',
    _me,
  ),
  _s('c3', '2026-10-12', _c, 1200000, '', 'v_dalat', '', 'Góp Quỹ Đà Lạt', _me),
  _s('s7', '2026-10-13', _e, 86000, '', '', 'move_grab', 'Grab về nhà', _her),
  _s('c4', '2026-10-14', _c, 800000, '', 'v_dalat', '', 'Góp Quỹ Đà Lạt', _her),
  _s(
    's9',
    '2026-10-15',
    _e,
    1180000,
    '',
    '',
    'home_power',
    'Tiền điện tháng 9',
    _me,
  ),
  _s(
    's10',
    '2026-10-17',
    _e,
    412000,
    'v_chung',
    '',
    'food_market',
    'Siêu thị Winmart',
    'wallet',
  ),
  _s(
    's12',
    '2026-10-18',
    _e,
    60000,
    '',
    '',
    'food_snack',
    'Bánh mì chảo',
    _her,
  ),
  _s(
    's11',
    '2026-10-19',
    _e,
    110000,
    '',
    '',
    'food_coffee',
    'Cà phê The Note',
    _me,
  ),
  _s('s13', '2026-10-20', _e, 96000, '', '', 'home_water', 'Tiền nước', _her),
];

const _sharedBudgets = <MoneyBudget>[
  MoneyBudget(id: 'total', categoryId: '', amount: 5000000),
  MoneyBudget(id: 'food', categoryId: 'food', amount: 2000000),
];

String _group(String id) => MoneyBookState(
  MoneyService.own(_me, firestore: _db),
).categories.groupOf(id);

MoneyBookState _ownBook({List<MoneyBudget> budgets = const []}) {
  final s = MoneyBookState(MoneyService.own(_me, firestore: _db));
  s.wallets = _ownWallets;
  s.walletsFromServer = true;
  s.txs = _ownTx;
  s.txLoaded = true;
  s.everLogged = true;
  s.windowFrom = '2026-10-01';
  s.budgets = budgets;
  s.netSumsAt = DateTime(2026, 10, 20);
  return s;
}

MoneyBookState _sharedBook({List<MoneyBudget> budgets = _sharedBudgets}) {
  final s = MoneyBookState(MoneyService.shared('c1', _pair, firestore: _db));
  s.wallets = const [
    MoneyWallet(
      id: 'v_chung',
      name: 'Ví chung',
      type: MoneyWalletType.cash,
      emoji: '👛',
      memberUids: _pair,
    ),
  ];
  s.walletsFromServer = true;
  s.txs = _sharedTx;
  s.txLoaded = true;
  s.everLogged = true;
  s.windowFrom = '2026-10-01';
  s.budgets = budgets;
  s.netSumsAt = DateTime(2026, 10, 20);
  return s;
}

const _nb = ' ';

Widget _app(MoneyProvider money, Widget home) =>
    ChangeNotifierProvider<MoneyProvider>.value(
      value: money,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MoneyPeopleScope(
          people: const MoneyPeople(myName: 'Tuấn', partnerName: 'Thảo'),
          child: child!,
        ),
        home: home,
      ),
    );

Future<void> _pump(WidgetTester tester, MoneyProvider money, Widget w) async {
  tester.view.physicalSize = const Size(1170, 2532 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(money, w));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AppL10n.setLocale(const Locale('vi')));

  group('budgets', () {
    test('levels: under 80 grey, 80 warn, 100 over', () {
      expect(MoneyMath.budgetStatus(799, 1000).level, 0);
      expect(MoneyMath.budgetStatus(800, 1000).level, 80);
      expect(MoneyMath.budgetStatus(999, 1000).level, 80);
      expect(MoneyMath.budgetStatus(1000, 1000).level, 100);
      expect(MoneyMath.budgetStatus(1031, 1000).percent - 100, 3);
    });

    test('data.js shared: food 97% first, home/date/move have none', () {
      final rows = MoneyViews.categoryBudgets(
        _sharedBudgets,
        _sharedTx,
        _m,
        groupOf: _group,
      );
      expect(rows.single.$1.categoryId, 'food');
      expect(rows.single.$2.spent, 1942000);
      expect(rows.single.$2.percent, 97);
      expect(rows.single.$2.level, 80);
      expect(rows.single.$2.left, 58000);
      expect(
        MoneyViews.unbudgetedGroups(
          _sharedBudgets,
          _sharedTx,
          _m,
          groupOf: _group,
        ),
        [('home', 1276000), ('date', 200000), ('move', 156000)],
      );
      final total = MoneyMath.budgetStatus(
        MoneyMath.spentIn(_sharedTx, _m),
        5000000,
      );
      expect(total.spent, 3574000);
      expect(MoneyViews.perDayLeft(total, _today), (
        daysLeft: 11,
        perDay: 129000,
      ));
    });

    test('closest to the limit comes first', () {
      final rows = MoneyViews.categoryBudgets(
        const [
          MoneyBudget(id: 'food', categoryId: 'food', amount: 1800000),
          MoneyBudget(id: 'date', categoryId: 'date', amount: 500000),
          MoneyBudget(id: 'shop', categoryId: 'shop', amount: 1000000),
        ],
        _ownTx,
        _m,
        groupOf: _group,
      );
      expect([for (final r in rows) r.$1.id], ['date', 'food', 'shop']);
      expect(rows.first.$2.level, 100); // 550k of 500k
      expect(rows[1].$2.percent, 58); // 1.059k of 1,8tr
    });

    testWidgets('screen: 97% pill, left of, unset groups, push note', (
      tester,
    ) async {
      final money = _Money()
        ..debugSetBooks(uid: _me, own: _ownBook(), shared: _sharedBook());
      await _pump(
        tester,
        money,
        const MoneyBudgetsScreen(book: MoneyBookKind.shared),
      );
      expect(find.text('Tháng 10 · cả sổ chung'), findsOneWidget);
      expect(find.text('còn 11 ngày'), findsOneWidget);
      expect(
        find.text(
          'Còn 1.426.000$_nb₫, tức khoảng 129.000$_nb₫ mỗi ngày tới hết tháng.',
        ),
        findsOneWidget,
      );
      expect(find.text('97%'), findsOneWidget);
      expect(find.text('Còn 58.000$_nb₫ của 2.000.000$_nb₫'), findsOneWidget);
      expect(find.text('Chưa đặt ngân sách'), findsOneWidget);
      expect(find.text('Đã chi 1.276.000$_nb₫ tháng này'), findsOneWidget);
      expect(find.textContaining('chỉ có phần trăm'), findsOneWidget);
    });

    testWidgets('screen: over 100% says "Vượt 3%", under 80% is grey', (
      tester,
    ) async {
      final money = _Money()
        ..debugSetBooks(
          uid: _me,
          own: _ownBook(),
          shared: _sharedBook(
            budgets: const [
              MoneyBudget(id: 'food', categoryId: 'food', amount: 1880000),
              MoneyBudget(id: 'date', categoryId: 'date', amount: 800000),
            ],
          ),
        );
      await _pump(
        tester,
        money,
        const MoneyBudgetsScreen(book: MoneyBookKind.shared),
      );
      expect(find.text('Vượt 3%'), findsOneWidget);
      expect(find.text('Vượt 62.000$_nb₫ của 1.880.000$_nb₫'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      // No total budget: the empty card + its button.
      expect(find.text('Đặt ngân sách tháng'), findsOneWidget);
    });

    testWidgets('set from "Đặt", remove + undo', (tester) async {
      final money = _Money()
        ..debugSetBooks(uid: _me, own: _ownBook(), shared: _sharedBook());
      await _pump(
        tester,
        money,
        const MoneyBudgetsScreen(book: MoneyBookKind.shared),
      );
      await tester.tap(find.text('Đặt').first); // Nhà cửa, biggest unset
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1tr5');
      await tester.pump();
      await tester.tap(find.text('Lưu ngân sách'));
      await tester.pumpAndSettle();
      expect(money.set.single, (
        kind: MoneyBookKind.shared,
        cat: 'home',
        amount: 1500000,
      ));
      expect(
        find.text('Đã đặt ngân sách Nhà cửa: 1.500.000$_nb₫'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ ngân sách này'));
      await tester.pumpAndSettle();
      // Hidden at once, deleted only after the undo window (Tester Low:
      // undo used to recreate the doc and lose `alerted`).
      expect(money.budgetFor(MoneyBookKind.shared, 'food'), isNull);
      expect(money.deleted, isEmpty);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pump();
      expect(money.budgetFor(MoneyBookKind.shared, 'food')?.amount, 2000000);
      expect(money.set, hasLength(1)); // no re-create
      await tester.pump(const Duration(seconds: 6));
      expect(money.deleted, isEmpty);

      // No undo: the delete goes out after 5 s.
      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ ngân sách này'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      expect(money.deleted.single, (kind: MoneyBookKind.shared, id: 'food'));
    });
  });

  group('report', () {
    test('data.js own month: 9.552.000 spent, home 59% mostly rent', () {
      final t = MoneyMath.monthTotals(_ownTx, _m);
      expect(t.expense, 9552000);
      final cats = MoneyMath.byCategory(_ownTx, _m, groupOf: _group);
      expect(cats.first, ('home', 5680000));
      expect(MoneyViews.percentOf(cats.first.$2, t.expense), 59);
      expect(MoneyViews.childrenOf(_ownTx, _m, 'home', groupOf: _group), [
        ('home_rent', 4500000),
        ('home_power', 1180000),
      ]);
      var sum = 0;
      for (final c in cats) {
        sum += c.$2;
      }
      expect(sum, t.expense);
    });

    test('data.js shared: food 54%', () {
      final t = MoneyMath.monthTotals(_sharedTx, _m);
      final cats = MoneyMath.byCategory(_sharedTx, _m, groupOf: _group);
      expect(cats.first, ('food', 1942000));
      expect(MoneyViews.percentOf(1942000, t.expense), 54);
    });

    test('trend axis, book start, Tết', () {
      expect(MoneyViews.chartScale(13260000), (step: 4000000, top: 16000000));
      expect(MoneyViews.chartScale(5000000), (step: 2000000, top: 6000000));
      final shared = {
        for (final m in MoneyMath.trendMonths(_m, 6))
          m: m == _m
              ? const MoneyMonthTotals(3574000)
              : const MoneyMonthTotals(0),
      };
      expect(MoneyViews.firstActiveMonth(shared), _m);
      final withGap = {...shared, '2026-07': null};
      expect(MoneyViews.firstActiveMonth(withGap), _m);
      expect(MoneyViews.hasTet('2026-02'), isTrue);
      expect(MoneyViews.hasTet('2026-01'), isFalse);
      expect(MoneyViews.hasTet('2028-01'), isTrue);
      expect(MoneyViews.hasTet('2026-10'), isFalse);
    });

    testWidgets('own screen: month spent + finding', (tester) async {
      final money = _Money(
        trendData: {
          for (final m in MoneyMath.trendMonths(_m, 6))
            m: m == _m
                ? MoneyMath.monthTotals(_ownTx, _m)
                : MoneyMonthTotals(_ownHistory[m]!),
        },
      )..debugSetBooks(uid: _me, own: _ownBook());
      await _pump(tester, money, const MoneyReportScreen());
      expect(find.text('9.552.000$_nb₫'), findsOneWidget);
      expect(
        find.text(
          'Chi nhiều nhất là Nhà cửa, chiếm 59% cả tháng. '
          'Phần lớn là Tiền nhà, 4.500.000$_nb₫.',
        ),
        findsOneWidget,
      );
      expect(find.text('tới 20/10'), findsOneWidget);
      // Top group open by default: its sub-categories show.
      expect(find.text('Tiền nhà'), findsOneWidget);
      expect(
        find.text('Tháng 10 mới tính tới 20/10.'),
        findsOneWidget,
      ); // no total budget
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Chi theo ví'), findsOneWidget);
    });

    testWidgets('shared screen: finding, new book', (tester) async {
      final money = _Money(
        trendData: {
          for (final m in MoneyMath.trendMonths(_m, 6))
            m: m == _m
                ? const MoneyMonthTotals(3574000)
                : const MoneyMonthTotals(0),
        },
      )..debugSetBooks(uid: _me, own: _ownBook(), shared: _sharedBook());
      await _pump(
        tester,
        money,
        const MoneyReportScreen(book: MoneyBookKind.shared),
      );
      expect(find.text('3.574.000$_nb₫'), findsOneWidget);
      expect(
        find.text(
          'Ăn uống chiếm 54% chi chung. '
          'Phần lớn là Đi chợ, siêu thị, 1.052.000$_nb₫.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Sổ chung mới có từ tháng 10, nên các tháng trước để trống.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tháng 10 mới tính tới 20/10. Đường đứt là ngân sách tổng hiện tại.',
        ),
        findsOneWidget,
      );
    });
  });

  // Ahem (test font) is ~2× wider than Quicksand, so 1.3 text here is not
  // a real check — text 1.3 stays on the device smoke list.
  testWidgets('360dp: the three screens fit', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final own = _ownBook(
      budgets: const [
        MoneyBudget(id: 'food', categoryId: 'food', amount: 1000000),
        MoneyBudget(id: 'total', categoryId: '', amount: 9000000),
      ],
    );
    final r3 = MoneyViews.searchRange(_today, 3);
    own.searchCache['${r3.$1}|${r3.$2}'] = (
      at: DateTime(2026, 10, 20, 12),
      rows: [..._ownTx, ..._ownOlder],
    );
    final money = _Money(
      trendData: {
        for (final m in MoneyMath.trendMonths(_m, 12))
          m: m == _m
              ? MoneyMath.monthTotals(_ownTx, _m)
              : MoneyMonthTotals(_ownHistory[m] ?? 0),
      },
    )..debugSetBooks(uid: _me, own: own, shared: _sharedBook());
    var n = 0;
    for (final screen in const <Widget>[
      MoneyBudgetsScreen(),
      MoneyBudgetsScreen(book: MoneyBookKind.shared),
      MoneyReportScreen(),
      MoneyReportScreen(book: MoneyBookKind.shared),
      MoneySearchScreen(),
      MoneySearchScreen(book: MoneyBookKind.shared),
    ]) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 780),
            textScaler: TextScaler.linear(1.0),
          ),
          // A new key each time: own → shared must not reuse the State.
          child: _app(money, KeyedSubtree(key: ValueKey(n++), child: screen)),
        ),
      );
      await tester.pumpAndSettle();
      // A RenderFlex overflow fails the test by itself.
    }
    // 12 months: the chart redraws with the Tết month in range.
    await tester.pumpWidget(_app(money, const MoneyReportScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('12 tháng'), 200);
    await tester.tap(find.text('12 tháng'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('search', () {
    test('match range ignores accents, keeps combining marks', () {
      expect(MoneyViews.matchRange('Bún chả Hàng Mành', 'bun cha'), (0, 7));
      expect(MoneyViews.matchRange('Bún chả Hàng Mành', 'MANH'), (13, 17));
      const nfd = 'Bún chả que';
      expect(MoneyViews.matchRange(nfd, 'bun cha'), (0, 9));
      expect(MoneyViews.matchRange('Phở', 'bun'), isNull);
      expect(MoneyViews.matchRange('Phở', '  '), isNull);
    });

    test('ranges: 3 months from the 1st, 12 months', () {
      expect(MoneyViews.searchRange(_today, 3), ('2026-08-01', '2027-10-31'));
      expect(MoneyViews.searchRange(_today, 12).$1, '2025-11-01');
    });

    MoneyProvider withCache({List<MoneyTx>? fetched, int months = 3}) {
      final own = _ownBook();
      final (from, to) = MoneyViews.searchRange(_today, months);
      own.searchCache['$from|$to'] = (
        at: DateTime(2026, 10, 20, 12),
        rows: fetched ?? [..._ownTx, ..._ownOlder],
      );
      return _Money()..debugSetBooks(uid: _me, own: own);
    }

    test('"bun cha" finds 3 entries, 410.000 ₫, newest first', () async {
      final money = withCache();
      final (from, to) = MoneyViews.searchRange(_today, 3);
      final r = await money.search(
        MoneyBookKind.own,
        from: from,
        to: to,
        query: 'bun cha',
      );
      expect([for (final t in r.rows) t.id], ['o11', 'o-s1', 'o-a1']);
      expect(MoneyViews.resultTotal(r.rows), 410000);
      expect(r.capped, isFalse);
    });

    test('filters: wallet, group + amount', () async {
      final money = withCache();
      final (from, to) = MoneyViews.searchRange(_today, 3);
      final cash = await money.search(
        MoneyBookKind.own,
        from: from,
        to: to,
        query: 'bun',
        walletIds: {'w_cash'},
      );
      expect([for (final t in cash.rows) t.id], ['o-a1', 'o-a2']);
      final food = await money.search(
        MoneyBookKind.own,
        from: from,
        to: to,
        categoryIds: {'food'},
        minAmount: 130000,
        maxAmount: 200000,
      );
      expect([for (final t in food.rows) t.id], ['o11', 'o-s1']);
    });

    test('2.000 rows fetched = capped', () async {
      final many = [
        for (var i = 0; i < 2000; i++)
          _o('x$i', '2026-08-15', _e, 1000, 'w_cash', '', 'other', 'x'),
      ];
      final money = withCache(fetched: many);
      final (from, to) = MoneyViews.searchRange(_today, 3);
      final r = await money.search(MoneyBookKind.own, from: from, to: to);
      expect(r.capped, isTrue);
    });

    testWidgets('screen: highlight, empty → 12 months finds it', (
      tester,
    ) async {
      final own = _ownBook();
      final r3 = MoneyViews.searchRange(_today, 3);
      final r12 = MoneyViews.searchRange(_today, 12);
      own.searchCache['${r3.$1}|${r3.$2}'] = (
        at: DateTime(2026, 10, 20, 12),
        rows: [..._ownTx, ..._ownOlder],
      );
      own.searchCache['${r12.$1}|${r12.$2}'] = (
        at: DateTime(2026, 10, 20, 12),
        rows: [
          ..._ownTx,
          ..._ownOlder,
          _o(
            'old',
            '2026-02-14',
            _e,
            900000,
            'w_tcb',
            '',
            'food_out',
            'Lẩu dê Valentine',
          ),
        ],
      );
      final money = _Money()..debugSetBooks(uid: _me, own: own);
      await _pump(tester, money, const MoneySearchScreen());
      // "Tất cả": everything of 3 months, newest first.
      expect(find.text('27 khoản'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'bun cha');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('3 khoản'), findsOneWidget);
      expect(find.text('410.000$_nb₫'), findsOneWidget);
      expect(find.text('Bún chả Hàng Mành'), findsOneWidget);
      expect(find.textContaining('Gõ không dấu vẫn ra'), findsOneWidget);
      bool tinted(InlineSpan span) {
        var hit = false;
        span.visitChildren((c) {
          if (c is TextSpan &&
              c.text == 'Bún chả' &&
              c.style?.backgroundColor != null) {
            hit = true;
          }
          return !hit;
        });
        return hit;
      }

      expect(
        find.byWidgetPredicate((w) => w is RichText && tinted(w.text)),
        findsNWidgets(3),
      );

      await tester.enterText(find.byType(TextField), 'lau de');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.text('Không có khoản nào khớp “lau de” trong 3 tháng gần đây.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tìm trong 12 tháng'));
      await tester.pumpAndSettle();
      expect(find.text('1 khoản'), findsOneWidget);
      expect(find.text('Lẩu dê Valentine'), findsOneWidget);
      expect(find.text('12 tháng gần đây'), findsOneWidget);
    });

    testWidgets('screen: capped notice', (tester) async {
      final own = _ownBook();
      final r3 = MoneyViews.searchRange(_today, 3);
      own.searchCache['${r3.$1}|${r3.$2}'] = (
        at: DateTime(2026, 10, 20, 12),
        rows: [
          for (var i = 0; i < 2000; i++)
            _o('x$i', '2026-08-15', _e, 1000, 'w_cash', '', 'other', 'x'),
        ],
      );
      final money = _Money()..debugSetBooks(uid: _me, own: own);
      await _pump(tester, money, const MoneySearchScreen());
      expect(find.textContaining('Chỉ tìm trong 2.000 khoản'), findsOneWidget);
    });
  });
}
