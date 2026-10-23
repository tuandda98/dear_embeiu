import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/providers/money_provider.dart';
import 'package:dear_embeiu/providers/reminder_provider.dart';
import 'package:dear_embeiu/screens/money/money_budgets_screen.dart';
import 'package:dear_embeiu/screens/money/money_categories_screen.dart';
import 'package:dear_embeiu/screens/money/money_goal_screen.dart';
import 'package:dear_embeiu/screens/money/money_report_screen.dart';
import 'package:dear_embeiu/screens/money/money_screen.dart';
import 'package:dear_embeiu/screens/money/money_search_screen.dart';
import 'package:dear_embeiu/screens/money/money_wallets_screen.dart';
import 'package:dear_embeiu/services/money_service.dart';
import 'package:dear_embeiu/services/reminder_service.dart';
import 'package:dear_embeiu/utils/money_input.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/utils/money_views.dart';
import 'package:dear_embeiu/widgets/money/add_transaction_sheet.dart';
import 'package:dear_embeiu/widgets/money/money_reminder_tile.dart';
import 'package:dear_embeiu/widgets/money/money_ui.dart';

// Sổ tiền: screens, gap cases of project/features/expenses/test-cases.md
// (WAL-04/05/06/08/12, TX-11, CAT-05/07, GOAL-14, BUD-14, REP-07..12,
// SRCH-10/11, HM-07, A11Y-04/05/06, I18N-02, OFF-03, ED-16, AM-22).

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

class _Reminders extends Fake implements ReminderService {
  int scheduled = 0;
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<void> scheduleMoneyEvening(
    List<({int id, DateTime when, String title, String body})> slots,
  ) async => scheduled++;
  @override
  Future<void> cancelMoneyEvening() async {}
}

class _Money extends MoneyProvider {
  _Money({this.trendData});

  final Map<String, MoneyMonthTotals?>? trendData;
  final List<({MoneyBookKind kind, MoneyTx tx, String? own})> added = [];
  final List<({String id, Map<String, dynamic> fields})> walletWrites = [];
  final List<Map<String, dynamic>> metaWrites = [];

  @override
  Future<MoneyWriteOutcome> addTx(
    MoneyBookKind kind,
    MoneyTx draft, {
    String? ownWalletId,
  }) async {
    added.add((kind: kind, tx: draft, own: ownWalletId));
    return MoneyWriteOutcome.saved;
  }

  @override
  Future<MoneyWriteOutcome> updateWallet(
    MoneyBookKind kind,
    String walletId,
    Map<String, dynamic> fields,
  ) async {
    walletWrites.add((id: walletId, fields: fields));
    return MoneyWriteOutcome.saved;
  }

  @override
  Future<MoneyWriteOutcome> setMeta(
    MoneyBookKind kind,
    Map<String, dynamic> fields,
  ) async {
    metaWrites.add(fields);
    return MoneyWriteOutcome.saved;
  }

  @override
  Future<Map<String, MoneyMonthTotals?>> trend(
    MoneyBookKind kind,
    int n,
  ) async =>
      trendData ?? {for (final m in MoneyMath.trendMonths(_month, n)) m: null};

  @override
  void refreshDay() {}
}

String get _today => MoneyMath.dateKey(DateTime.now());
String get _month => MoneyMath.monthKey(DateTime.now());
String _daysAgo(int n) =>
    MoneyMath.dateKey(DateTime.now().subtract(Duration(days: n)));

const _wallets = <MoneyWallet>[
  MoneyWallet(
    id: 'cash',
    name: 'Tiền mặt',
    type: MoneyWalletType.cash,
    emoji: '💵',
    order: 0,
  ),
  MoneyWallet(
    id: 'momo',
    name: 'MoMo',
    type: MoneyWalletType.ewallet,
    emoji: '📱',
    order: 1,
  ),
  MoneyWallet(
    id: 'visa',
    name: 'Visa',
    type: MoneyWalletType.credit,
    emoji: '💳',
    order: 2,
  ),
];

MoneyBookState _own({
  List<MoneyTx> txs = const [],
  List<MoneyWallet> wallets = _wallets,
  Map<String, int> sums = const {},
  List<MoneyBudget> budgets = const [],
  MoneyMeta meta = MoneyMeta.empty,
  bool everLogged = true,
}) {
  final s = MoneyBookState(MoneyService.own('me', firestore: _db));
  s.wallets = wallets;
  s.walletsFromServer = true;
  s.txs = txs;
  s.txLoaded = true;
  s.everLogged = everLogged;
  s.windowFrom = _daysAgo(60);
  s.netSums = sums;
  s.netSumsAt = DateTime.now();
  s.budgets = budgets;
  s.meta = meta;
  return s;
}

MoneyBookState _shared({
  List<MoneyTx> txs = const [],
  List<MoneyWallet> extra = const [],
  Map<String, int> sums = const {'joint': 0},
}) {
  final s = MoneyBookState(
    MoneyService.shared('c1', const ['her', 'me'], firestore: _db),
  );
  s.wallets = [
    const MoneyWallet(
      id: 'joint',
      name: 'Ví chung',
      type: MoneyWalletType.cash,
      emoji: '👛',
      memberUids: ['her', 'me'],
    ),
    ...extra,
  ];
  s.walletsFromServer = true;
  s.txs = txs;
  s.txLoaded = true;
  s.everLogged = txs.isNotEmpty;
  s.windowFrom = _daysAgo(60);
  s.netSums = sums;
  s.netSumsAt = DateTime.now();
  return s;
}

MoneyTx _exp(
  String id,
  int amount, {
  String cat = 'food_out',
  String wallet = 'momo',
  String? date,
  String note = '',
}) => MoneyTx(
  id: id,
  type: MoneyTxType.expense,
  amount: amount,
  date: date ?? _today,
  outWalletId: wallet,
  categoryId: cat,
  note: note,
);

MoneyTx _sExp(String id, int amount, String payer, String note) => MoneyTx(
  id: id,
  type: MoneyTxType.expense,
  amount: amount,
  date: _today,
  categoryId: 'food_out',
  note: note,
  payer: payer,
  splitMode: MoneySplitMode.equal,
  payerShare: (amount + 1) ~/ 2,
  memberUids: const ['her', 'me'],
  createdBy: payer,
);

Widget _app(
  MoneyProvider money,
  Widget home, {
  bool reduceMotion = false,
  ReminderProvider? reminders,
}) {
  Widget app = MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: MoneyPeopleScope(
        people: const MoneyPeople(myName: 'Tuấn', partnerName: 'Thảo'),
        child: child!,
      ),
    ),
    home: home,
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MoneyProvider>.value(value: money),
      if (reminders != null)
        ChangeNotifierProvider<ReminderProvider>.value(value: reminders),
    ],
    child: app,
  );
}

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(1170, 2532 * 2);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

/// A button that opens [open], so sheets get a real route.
class _Opener extends StatelessWidget {
  const _Opener(this.open);
  final void Function(BuildContext) open;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => open(context),
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester t, MoneyProvider m, Widget w) async {
  _phone(t);
  await t.pumpWidget(_app(m, w));
  await t.pumpAndSettle();
}

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('money_gap_pages').path);
  });
  setUp(() => AppL10n.setLocale(const Locale('vi')));

  group('wallet detail', () {
    _Money withWallets({
      Map<String, int> sums = const {'momo': 1000000},
      List<MoneyTx> txs = const [],
    }) => _Money()
      ..debugSetBooks(
        uid: 'me',
        own: _own(txs: txs, sums: sums),
      );

    testWidgets('WAL-05: balance, in/out of the month, the wallet\'s entries', (
      t,
    ) async {
      final m = withWallets(
        sums: const {'momo': 780000},
        txs: [
          _exp('a', 220000, note: 'Lẩu', wallet: 'momo'),
          MoneyTx(
            id: 'i',
            type: MoneyTxType.income,
            amount: 1000000,
            date: _today,
            inWalletId: 'momo',
            categoryId: 'side',
            note: 'Freelance',
          ),
          _exp('z', 99000, note: 'Ví khác', wallet: 'cash'),
        ],
      );
      await _pump(
        t,
        m,
        const MoneyWalletScreen(book: MoneyBookKind.own, walletId: 'momo'),
      );
      expect(find.text('Số dư hiện tại'), findsOneWidget);
      expect(find.textContaining('780.000'), findsWidgets);
      expect(find.text('Vào tháng ${DateTime.now().month}'), findsOneWidget);
      expect(find.text('Ra tháng ${DateTime.now().month}'), findsOneWidget);
      expect(find.text('Lẩu'), findsOneWidget);
      expect(find.text('Freelance'), findsOneWidget);
      expect(
        find.text('Ví khác'),
        findsNothing,
        reason: 'other wallets stay out',
      );
      expect(find.text('2 khoản'), findsOneWidget);
    });

    testWidgets('WAL-05: a wallet with nothing this month says so', (t) async {
      await _pump(
        t,
        withWallets(),
        const MoneyWalletScreen(book: MoneyBookKind.own, walletId: 'momo'),
      );
      expect(find.text('Tháng này ví chưa có khoản nào.'), findsOneWidget);
    });

    testWidgets(
      'TX-11: a normal wallet below 0 warns; a credit card does not',
      (t) async {
        await _pump(
          t,
          withWallets(sums: const {'momo': -50000, 'visa': -2458000}),
          const MoneyWalletScreen(book: MoneyBookKind.own, walletId: 'momo'),
        );
        expect(
          find.text('Số dư âm, có khoản nào ghi nhầm ví không?'),
          findsOneWidget,
        );
        await _pump(
          t,
          withWallets(sums: const {'momo': -50000, 'visa': -2458000}),
          const MoneyWalletScreen(book: MoneyBookKind.own, walletId: 'visa'),
        );
        expect(
          find.text('Số dư âm, có khoản nào ghi nhầm ví không?'),
          findsNothing,
        );
      },
    );

    testWidgets('WAL-04: "Sửa số dư" explains more / less / same and writes '
        'one adjust line', (t) async {
      final m = withWallets();
      await _pump(
        t,
        m,
        const MoneyWalletScreen(book: MoneyBookKind.own, walletId: 'momo'),
      );
      await _tap(t, find.text('Sửa số dư'));
      final field = find.byType(TextField).last;
      await t.enterText(field, '800000');
      await t.pump();
      expect(
        find.textContaining('đang nhiều hơn tiền thật 200.000'),
        findsOneWidget,
      );
      await t.enterText(field, '1200000');
      await t.pump();
      expect(
        find.textContaining('đang ít hơn tiền thật 200.000'),
        findsOneWidget,
      );
      await t.enterText(field, '1000000');
      await t.pump();
      expect(
        find.text('Đã khớp với tiền thật, không cần sửa.'),
        findsOneWidget,
      );
      expect(
        t
            .widget<MoneyPrimaryButton>(find.byType(MoneyPrimaryButton).last)
            .onPressed,
        isNull,
      );
      await t.enterText(field, '800000');
      await t.pump();
      await t.tap(find.text('Cập nhật số dư'));
      await t.pumpAndSettle();
      final tx = m.added.single.tx;
      expect(tx.type, MoneyTxType.adjust);
      expect(tx.amount, 200000);
      expect(tx.outWalletId, 'momo');
      expect(tx.inWalletId, isEmpty);
      expect(find.text('Đã sửa số dư MoMo'), findsOneWidget);
    });

    testWidgets('WAL-08: "Chuyển tiền" opens a transfer from THIS wallet', (
      t,
    ) async {
      final m = withWallets();
      await _pump(
        t,
        m,
        const MoneyWalletScreen(book: MoneyBookKind.own, walletId: 'momo'),
      );
      await _tap(t, find.text('Chuyển tiền'));
      expect(find.byType(AddTransactionSheet), findsOneWidget);
      expect(find.text('Từ ví'), findsOneWidget);
      await t.tap(find.text('5').last);
      await t.tap(find.text('0').last);
      await t.tap(find.text('k').last);
      await t.pump();
      await t.tap(find.byType(MoneyPrimaryButton).last);
      await t.pumpAndSettle();
      final tx = m.added.single.tx;
      expect(tx.type, MoneyTxType.transfer);
      expect(tx.outWalletId, 'momo');
      expect(tx.inWalletId, isNot('momo'));
    });
  });

  group('wallet sheet', () {
    Future<_Money> edit(WidgetTester t, MoneyWallet w) async {
      final m = _Money()..debugSetBooks(uid: 'me', own: _own());
      _phone(t);
      await t.pumpWidget(
        _app(
          m,
          _Opener(
            (c) =>
                MoneyWalletSheet.show(c, book: MoneyBookKind.own, editing: w),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      return m;
    }

    testWidgets('WAL-06: archive asks first, then writes archived:true; the '
        'default wallet cannot be archived', (t) async {
      final m = await edit(t, _wallets[1]);
      await _tap(t, find.text('Lưu trữ ví'));
      expect(find.text('Lưu trữ ví này?'), findsOneWidget);
      await t.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Lưu trữ ví'),
        ),
      );
      await t.pumpAndSettle();
      expect(m.walletWrites.single.id, 'momo');
      expect(m.walletWrites.single.fields, {'archived': true});
    });

    testWidgets('WAL-06: an archived wallet offers "Dùng lại ví này" with no '
        'question', (t) async {
      final archived = _wallets[1].withName('MoMo');
      final m = await edit(
        t,
        MoneyWallet(
          id: archived.id,
          name: archived.name,
          type: archived.type,
          archived: true,
        ),
      );
      expect(find.text('Lưu trữ ví'), findsNothing);
      await _tap(t, find.text('Dùng lại ví này'));
      expect(find.text('Lưu trữ ví này?'), findsNothing);
      expect(m.walletWrites.single.fields, {'archived': false});
    });

    testWidgets('WAL-06: no archive button for the starter wallet', (t) async {
      await edit(t, _wallets[0]);
      expect(find.text('Lưu trữ ví'), findsNothing);
    });

    testWidgets('WAL-12: a wallet shown as "Tiền mặt" (stored "Cash") saves '
        'the new name once the balance box is empty', (t) async {
      final own = _own()
        ..wallets = const [
          MoneyWallet(id: 'cash', name: 'Cash', type: MoneyWalletType.cash),
          MoneyWallet(id: 'momo', name: 'MoMo', type: MoneyWalletType.ewallet),
        ];
      final m = _Money()..debugSetBooks(uid: 'me', own: own);
      final shown = own.wallets.firstWhere((w) => w.id == 'momo');
      _phone(t);
      await t.pumpWidget(
        _app(
          m,
          _Opener(
            (c) => MoneyWalletSheet.show(
              c,
              book: MoneyBookKind.own,
              editing: shown,
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'Ví của Tuấn');
      await t.enterText(find.byType(TextField).last, '');
      await t.pump();
      await _tap(t, find.text('Lưu'));
      expect(m.walletWrites.single.fields['name'], 'Ví của Tuấn');
    });

    testWidgets(
      'BUG (Med) WAL-12: editing a wallet whose opening balance is 0 — the '
      'box is pre-filled with "0", which parseVndInput rejects as zero, so '
      'Lưu is locked with no message until the user empties the box '
      '(money_wallets_screen.dart _initialAmount / canSave)',
      (t) async {
        final m = _Money()..debugSetBooks(uid: 'me', own: _own());
        _phone(t);
        await t.pumpWidget(
          _app(
            m,
            _Opener(
              (c) => MoneyWalletSheet.show(
                c,
                book: MoneyBookKind.own,
                editing: _wallets[1],
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField).first, 'MoMo của Tuấn');
        await t.pump();
        expect(
          t
              .widget<MoneyPrimaryButton>(find.byType(MoneyPrimaryButton).last)
              .onPressed,
          isNotNull,
        );
      },
    );
  });

  group('categories screen', () {
    testWidgets('CAT-05: a hidden category comes back with "Hiện lại"', (
      t,
    ) async {
      final m = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(meta: const MoneyMeta(hiddenCategoryIds: {'food_snack'})),
        );
      t.view.physicalSize = const Size(1800, 5000);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        _app(m, const MoneyCategoriesScreen(book: MoneyBookKind.own)),
      );
      await t.pumpAndSettle();
      expect(find.text('Đã ẩn'), findsOneWidget);
      expect(
        find.text(lookupAppLocalizations(const Locale('vi')).moneyCatFoodSnack),
        findsOneWidget,
      );
      await _tap(t, find.text('Hiện lại'));
      expect(m.metaWrites.single, {'hiddenCategoryIds': <String>[]});
    });

    testWidgets('CAT-07: the 81st custom category is refused with a note', (
      t,
    ) async {
      final m = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(
            meta: MoneyMeta(
              customCategories: [
                for (var i = 0; i < kMoneyCustomCategoriesMax; i++)
                  MoneyCustomCategory(
                    id: 'c$i',
                    kind: MoneyTxType.expense,
                    name: 'Mục $i',
                  ),
              ],
            ),
          ),
        );
      await _pump(t, m, const MoneyCategoriesScreen(book: MoneyBookKind.own));
      await t.tap(find.bySemanticsLabel('Thêm danh mục'));
      await t.pumpAndSettle();
      expect(find.text('Sổ này đã đủ 80 danh mục tự thêm.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing, reason: 'no edit sheet');
      expect(m.metaWrites, isEmpty);
    });
  });

  group('budget sheet & fields', () {
    testWidgets('BUD-14: an empty / zero budget keeps the save button locked', (
      t,
    ) async {
      final m = _Money()..debugSetBooks(uid: 'me', own: _own());
      _phone(t);
      await t.pumpWidget(
        _app(
          m,
          _Opener((c) => MoneyBudgetSheet.show(c, book: MoneyBookKind.own)),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      MoneyPrimaryButton btn() =>
          t.widget<MoneyPrimaryButton>(find.byType(MoneyPrimaryButton).last);
      expect(btn().onPressed, isNull);
      await t.enterText(find.byType(TextField).last, '0');
      await t.pump();
      expect(btn().onPressed, isNull);
      await t.enterText(find.byType(TextField).last, '5tr');
      await t.pump();
      expect(btn().onPressed, isNotNull);
    });

    testWidgets('AM-22: MoneyNumberField reads 5tr as 5.000.000 and shows the '
        'error under the field', (t) async {
      final c = TextEditingController();
      addTearDown(c.dispose);
      await t.pumpWidget(
        _app(
          _Money(),
          Scaffold(
            body: StatefulBuilder(
              builder: (context, set) => MoneyNumberField(
                controller: c,
                label: 'Số dư',
                onChanged: (_) => set(() {}),
              ),
            ),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'abc');
      await t.pump();
      expect(
        find.text('Chưa hiểu số này. Thử 120k hoặc 120000.'),
        findsOneWidget,
      );
      await t.enterText(find.byType(TextField), '5tr');
      await t.pump();
      expect(find.textContaining('Chưa hiểu'), findsNothing);
      expect(parseVndInput(c.text).value, 5000000);
    });
  });

  group('goal screen', () {
    testWidgets('GOAL-14: the fund bar and the two lanes read as sentences', (
      t,
    ) async {
      final h = t.ensureSemantics();
      const fund = MoneyWallet(
        id: 'v_dalat',
        name: 'Quỹ Đà Lạt',
        type: MoneyWalletType.goal,
        emoji: '🏔️',
        goalTarget: 5000000,
        memberUids: ['her', 'me'],
      );
      MoneyTx c(String id, int a, String who) => MoneyTx(
        id: id,
        type: MoneyTxType.contribution,
        amount: a,
        date: _today,
        inWalletId: 'v_dalat',
        payer: who,
        splitMode: MoneySplitMode.none,
        memberUids: const ['her', 'me'],
        createdBy: who,
      );
      final m = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(
            extra: const [fund],
            sums: const {'joint': 0, 'v_dalat': 2000000},
            txs: [c('a', 1200000, 'me'), c('b', 800000, 'her')],
          ),
        );
      await _pump(
        t,
        m,
        const MoneyGoalScreen(book: MoneyBookKind.shared, walletId: 'v_dalat'),
      );
      expect(
        find.bySemanticsLabel(RegExp(r'40% của 5\.000\.000 đồng')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Thảo góp 800\.000 đồng, mình góp 1\.200\.000 đồng, còn thiếu 3\.000\.000 đồng',
          ),
        ),
        findsOneWidget,
      );
      h.dispose();
    });
  });

  group('report screen', () {
    testWidgets('REP-07: a month with income only → "chưa có khoản chi nào"', (
      t,
    ) async {
      final m = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(
            txs: [
              MoneyTx(
                id: 'i',
                type: MoneyTxType.income,
                amount: 1000000,
                date: _today,
                inWalletId: 'cash',
                categoryId: 'salary',
              ),
            ],
          ),
        );
      await _pump(t, m, const MoneyReportScreen());
      expect(
        find.text('Tháng ${DateTime.now().month} chưa có khoản chi nào.'),
        findsOneWidget,
      );
      expect(find.text('Chi theo danh mục'), findsNothing);
    });

    testWidgets('REP-09: months that could not load stay empty with a note', (
      t,
    ) async {
      final months = MoneyMath.trendMonths(_month, 6);
      final m =
          _Money(
            trendData: {
              months[0]: const MoneyMonthTotals(100000, 0),
              months[1]: null,
              months[2]: const MoneyMonthTotals(200000, 0),
              months[3]: null,
              months[4]: const MoneyMonthTotals(300000, 0),
              months[5]: const MoneyMonthTotals(50000, 0),
            },
          )..debugSetBooks(
            uid: 'me',
            own: _own(txs: [_exp('a', 50000)]),
          );
      await _pump(t, m, const MoneyReportScreen());
      await t.scrollUntilVisible(
        find.textContaining('Chưa tải được vài tháng'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(
          'Chưa tải được vài tháng nên các cột đó để trống. Có mạng sẽ hiện lại.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('REP-11: the chart reads as "Chi mỗi tháng, N tháng gần đây"', (
      t,
    ) async {
      final h = t.ensureSemantics();
      final months = MoneyMath.trendMonths(_month, 6);
      final m =
          _Money(
            trendData: {
              for (final x in months) x: const MoneyMonthTotals(120000, 0),
            },
          )..debugSetBooks(
            uid: 'me',
            own: _own(txs: [_exp('a', 120000)]),
          );
      await _pump(t, m, const MoneyReportScreen());
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Chi mỗi tháng, 6 tháng gần đây: .*120\.000 đồng'),
        ),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('REP-10: tapping a closed group opens its sub-categories', (
      t,
    ) async {
      final m = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(
            txs: [
              _exp('a', 4500000, cat: 'home_rent', wallet: 'cash'),
              _exp('b', 1000000, cat: 'food_out'),
            ],
          ),
        );
      await _pump(t, m, const MoneyReportScreen());
      expect(
        find.text('Tiền nhà'),
        findsOneWidget,
        reason: 'top group is open',
      );
      expect(find.text('Ăn ngoài'), findsNothing);
      await _tap(t, find.textContaining('Ăn uống').first);
      expect(find.text('Ăn ngoài'), findsOneWidget);
    });

    testWidgets('REP-12: the "Báo cáo" link of the month card opens that '
        'month', (t) async {
      final m = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(txs: [_exp('a', 50000)]),
        );
      await _pump(t, m, const MoneyScreen(initialBook: MoneyBookKind.own));
      await _tap(t, find.text('Báo cáo'));
      final screen = t.widget<MoneyReportScreen>(
        find.byType(MoneyReportScreen),
      );
      expect(screen.month, _month);
      expect(screen.book, MoneyBookKind.own);
    });
  });

  group('search screen', () {
    testWidgets('SRCH-11: offline → one clear sentence, not a crash', (
      t,
    ) async {
      final m = _Money()..debugSetBooks(uid: 'me', own: _own());
      await _pump(t, m, const MoneySearchScreen());
      expect(
        find.text('Chưa tìm được. Kiểm tra mạng rồi thử lại.'),
        findsOneWidget,
      );
    });

    testWidgets('SRCH-10: the "Người" filter keeps only what that person '
        'paid', (t) async {
      final shared = _shared(
        txs: [
          _sExp('a', 100000, 'me', 'Tuấn trả cơm'),
          _sExp('b', 200000, 'her', 'Thảo trả phim'),
        ],
      );
      final m = _Money()..debugSetBooks(uid: 'me', own: _own(), shared: shared);
      // Fill the 2-minute search cache so no server read is needed.
      final (from, to) = MoneyViews.searchRange(m.today, 3);
      shared.searchCache['$from|$to'] = (at: DateTime.now(), rows: const []);
      await _pump(t, m, const MoneySearchScreen(book: MoneyBookKind.shared));
      expect(find.text('Tuấn trả cơm'), findsOneWidget);
      expect(find.text('Thảo trả phim'), findsOneWidget);
      await _tap(t, find.text('Người'));
      await _tap(t, find.text('Thảo').last);
      expect(find.text('Thảo trả phim'), findsOneWidget);
      expect(find.text('Tuấn trả cơm'), findsNothing);
    });
  });

  group('settings tile', () {
    testWidgets('HM-07: the evening reminder tile shows its time row only '
        'while on, and its switch follows the provider', (t) async {
      final os = _Reminders();
      final r = ReminderProvider(service: os);
      await t.pumpWidget(
        _app(_Money(), const Scaffold(body: MoneyReminderTile()), reminders: r),
      );
      expect(find.text('Nhắc ghi chi tiêu buổi tối'), findsOneWidget);
      expect(t.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.byIcon(IconsaxPlusLinear.clock), findsNothing);
      // The provider's own IO (Hive) runs in the real zone.
      await t.runAsync(() => r.setMoneyEveningEnabled(true));
      await t.pump();
      expect(t.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.byIcon(IconsaxPlusLinear.clock), findsOneWidget);
      await t.runAsync(() => r.setMoneyEveningEnabled(false));
      await t.pump();
      expect(find.byIcon(IconsaxPlusLinear.clock), findsNothing);
    });
  });

  group('accessibility & language', () {
    testWidgets('A11Y-04: the budget bar reads "Đã dùng X% ngân sách, còn Y"', (
      t,
    ) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          _Money(),
          const Scaffold(body: MoneyPlanBar(spent: 800000, budget: 1000000)),
        ),
      );
      expect(
        find.bySemanticsLabel('Đã dùng 80% ngân sách, còn 200.000 đồng'),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('A11Y-05: a radio chip announces selected and sits in an '
        'exclusive group', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          _Money(),
          const Scaffold(
            body: Row(
              children: [
                MoneyChip(label: 'Chia đôi', radio: true, selected: true),
                MoneyChip(label: 'Mình mời', radio: true),
              ],
            ),
          ),
        ),
      );
      final on = t.getSemantics(find.text('Chia đôi'));
      final off = t.getSemantics(find.text('Mình mời'));
      expect(on.flagsCollection.isSelected, Tristate.isTrue);
      expect(off.flagsCollection.isSelected, Tristate.isFalse);
      expect(on.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(off.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      h.dispose();
    });

    testWidgets('A11Y-06: with "reduce motion" the form and the FAB do not '
        'animate', (t) async {
      final m = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(txs: [_exp('a', 5)]),
        );
      _phone(t);
      await t.pumpWidget(
        _app(
          m,
          const MoneyScreen(initialBook: MoneyBookKind.own),
          reduceMotion: true,
        ),
      );
      await t.pump();
      expect(
        t.widget<AnimatedSlide>(find.byType(AnimatedSlide)).duration,
        Duration.zero,
      );
      await t.pumpWidget(
        _app(m, const MoneyScreen(initialBook: MoneyBookKind.own)),
      );
      await t.pump();
      expect(
        t.widget<AnimatedSlide>(find.byType(AnimatedSlide)).duration,
        isNot(Duration.zero),
      );
    });

    testWidgets('I18N-02: English phone → "October 2026" and ₫1,250,000', (
      t,
    ) async {
      AppL10n.setLocale(const Locale('en'));
      late BuildContext ctx;
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(moneyMonthLabel(ctx, '2026-10'), 'October 2026');
      expect(moneyMonthShort(ctx, '2026-10'), 'October');
      expect(moneyShortDate(ctx, '2026-10-20'), 'Oct 20');
      expect(vnd(ctx, 1250000), '₫1,250,000');
    });
  });
}
