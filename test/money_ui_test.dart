import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/providers/money_provider.dart';
import 'package:dear_embeiu/screens/money/money_categories_screen.dart';
import 'package:dear_embeiu/screens/money/money_screen.dart';
import 'package:dear_embeiu/screens/money/money_wallets_screen.dart';
import 'package:dear_embeiu/services/money_service.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/widgets/money/add_transaction_sheet.dart';
import 'package:dear_embeiu/widgets/money/money_home_entry.dart';
import 'package:dear_embeiu/widgets/money/money_ui.dart';

/// Sổ tiền stage 2 (feature expenses): keypad + hints, chips, "khoản quen"
/// in 2 taps, smart defaults, the linked-entry lock, undo delete, the Home
/// entry states, first run (credit card stored negative).

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

class _Money extends MoneyProvider {
  final List<({MoneyBookKind kind, MoneyTx tx, String? own})> added = [];
  final List<({MoneyBookKind kind, List<MoneyWallet> extra, int start})>
  ensured = [];

  @override
  Future<MoneyWriteOutcome> addTx(
    MoneyBookKind kind,
    MoneyTx draft, {
    String? ownWalletId,
  }) async {
    added.add((kind: kind, tx: draft, own: ownWalletId));
    return MoneyWriteOutcome.saved;
  }

  // The own window never moves in a test (no Firestore to re-listen to).
  @override
  void refreshDay() {}

  @override
  Future<void> ensureDefaultWallet(
    MoneyBookKind kind, {
    List<MoneyWallet> extra = const <MoneyWallet>[],
    int starterBalance = 0,
  }) async {
    ensured.add((kind: kind, extra: extra, start: starterBalance));
  }
}

final _db = _FakeDb();
String get _today => MoneyMath.dateKey(DateTime.now());
String _daysAgo(int n) =>
    MoneyMath.dateKey(DateTime.now().subtract(Duration(days: n)));
String get _month => MoneyMath.monthKey(DateTime.now());

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
];

MoneyBookState _own({
  List<MoneyTx> txs = const [],
  List<MoneyWallet> wallets = _wallets,
  bool fromServer = true,
}) {
  final s = MoneyBookState(MoneyService.own('me', firestore: _db));
  s.wallets = wallets;
  s.walletsFromServer = fromServer;
  s.txs = txs;
  s.txLoaded = true;
  s.windowFrom = _daysAgo(60);
  s.netSumsAt = DateTime.now();
  return s;
}

MoneyBookState _shared({
  List<MoneyTx> txs = const [],
  List<MoneyBudget> budgets = const [],
  bool loaded = true,
}) {
  final s = MoneyBookState(
    MoneyService.shared('c1', const ['her', 'me'], firestore: _db),
  );
  s.wallets = const [
    MoneyWallet(
      id: 'joint',
      name: 'Ví chung',
      type: MoneyWalletType.cash,
      emoji: '👛',
      memberUids: ['her', 'me'],
    ),
  ];
  s.walletsFromServer = true;
  s.txs = txs;
  s.txLoaded = loaded;
  s.budgets = budgets;
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

MoneyTx _sharedExp(
  String id,
  int amount, {
  String payer = 'me',
  String? linkId,
  String createdBy = 'me',
}) => MoneyTx(
  id: id,
  type: MoneyTxType.expense,
  amount: amount,
  date: _today,
  categoryId: 'food_out',
  note: 'Lẩu Thái',
  payer: payer,
  splitMode: MoneySplitMode.equal,
  payerShare: (amount + 1) ~/ 2,
  memberUids: const ['her', 'me'],
  linkId: linkId,
  createdBy: createdBy,
);

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
        home: Scaffold(body: home),
      ),
    );

/// A button that opens the sheet, so the sheet gets a real route.
class _Opener extends StatelessWidget {
  const _Opener({required this.book, this.editing});

  final MoneyBookKind book;
  final MoneyTx? editing;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () =>
          AddTransactionSheet.show(context, book: book, editing: editing),
      child: const Text('open'),
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  _Money money, {
  MoneyBookKind book = MoneyBookKind.own,
  MoneyTx? editing,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(money, _Opener(book: book, editing: editing)));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _keys(WidgetTester tester, List<String> keys) async {
  for (final k in keys) {
    await tester.tap(find.text(k).last);
    await tester.pump();
  }
}

_Money _withOwn({List<MoneyTx> txs = const []}) => _Money()
  ..debugSetBooks(
    uid: 'me',
    own: _own(txs: txs),
  );

void main() {
  setUp(() => AppL10n.setLocale(const Locale('vi')));

  group('MoneyAmountInput', () {
    test('keys build "1tr2" = 1.200.000, one unit right after a digit', () {
      final i = MoneyAmountInput();
      for (final k in ['tr', '1', 'tr', 'k', '2']) {
        i.press(k);
      }
      expect(i.raw, '1tr2');
      expect(i.parsed.value, 1200000);
      expect(i.parsed.hasUnit, isTrue);
      i.backspace();
      i.backspace(); // drops the whole unit
      expect(i.raw, '1');
    });

    test('leading zeros are ignored, chips add up, a digit starts over', () {
      final i = MoneyAmountInput();
      i.press('0');
      i.press('000');
      expect(i.raw, '');
      i.addChip(50000);
      i.addChip(100000);
      expect(i.parsed.value, 150000);
      i.press('7');
      expect(i.raw, '7');
    });
  });

  group('AddTransactionSheet', () {
    testWidgets('hints: empty, "Bạn gõ “1tr2”", không hiểu, quá 10 tỷ', (
      tester,
    ) async {
      await _open(tester, _withOwn());
      expect(find.text('Gõ 50k, 1tr2 hay 1 củ đều được'), findsOneWidget);
      expect(find.text('Nhập số tiền để lưu'), findsOneWidget);

      await _keys(tester, ['1', 'tr', '2']);
      expect(find.text('Bạn gõ “1tr2”'), findsOneWidget);
      expect(find.text('Lưu 1.200.000\u00a0₫'), findsOneWidget);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.bySemanticsLabel('Xoá một ký tự'));
        await tester.pump();
      }
      await _keys(tester, ['1', ',']);
      expect(
        find.text('Chưa hiểu số này. Thử 120k hoặc 120000.'),
        findsOneWidget,
      );
      expect(find.text('Sửa số tiền để lưu'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.bySemanticsLabel('Xoá một ký tự'));
        await tester.pump();
      }
      await _keys(tester, ['2', '000', '000', '000', '0']);
      expect(
        find.text('Tối đa 10 tỷ một khoản. Kiểm tra lại số 0 nhé.'),
        findsOneWidget,
      );
    });

    testWidgets('50k then 100k adds up to 150.000\u00a0₫', (tester) async {
      await _open(tester, _withOwn());
      await tester.tap(find.text('50k'));
      await tester.pump();
      await tester.tap(find.text('100k'));
      await tester.pump();
      expect(find.text('Lưu 150.000\u00a0₫'), findsOneWidget);
    });

    testWidgets('"Ghi lại khoản quen": chip + Lưu = 2 taps', (tester) async {
      final money = _withOwn(
        txs: [
          _exp('a', 120000, note: 'Cơm trưa', date: _daysAgo(1)),
          _exp('b', 110000, note: 'Cơm trưa', date: _daysAgo(2)),
          _exp(
            'c',
            35000,
            cat: 'food_coffee',
            wallet: 'cash',
            date: _daysAgo(3),
          ),
        ],
      );
      await _open(tester, money);
      await tester.tap(find.text('Cơm trưa · 120k'));
      await tester.pump();
      await tester.tap(find.text('Lưu 120.000\u00a0₫'));
      await tester.pumpAndSettle();
      expect(money.added, hasLength(1));
      final tx = money.added.single.tx;
      expect(tx.amount, 120000);
      expect(tx.categoryId, 'food_out');
      expect(tx.outWalletId, 'momo');
      expect(tx.note, 'Cơm trưa');
      expect(find.text('Đã ghi 120.000\u00a0₫ · Ăn ngoài'), findsOneWidget);
    });

    testWidgets('defaults: most used category in 14 days + its last wallet', (
      tester,
    ) async {
      final money = _withOwn(
        txs: [
          _exp('w', 20000, cat: 'home_water', date: _today),
          for (var i = 1; i <= 3; i++)
            _exp(
              'c$i',
              35000,
              cat: 'food_coffee',
              wallet: 'cash',
              date: _daysAgo(i),
            ),
        ],
      );
      await _open(tester, money);
      await _keys(tester, ['3', '5', 'k']);
      await tester.tap(find.text('Lưu 35.000\u00a0₫'));
      await tester.pumpAndSettle();
      final tx = money.added.single.tx;
      expect(tx.categoryId, 'food_coffee');
      expect(tx.outWalletId, 'cash');
    });

    testWidgets('shared, I paid: deducts my own wallet, split in half', (
      tester,
    ) async {
      final money = _Money()
        ..debugSetBooks(uid: 'me', own: _own(), shared: _shared());
      await _open(tester, money, book: MoneyBookKind.shared);
      await _keys(tester, ['7', '5', '0', '0', '1']);
      await tester.tap(find.text('Lưu 75.001\u00a0₫'));
      await tester.pumpAndSettle();
      final r = money.added.single;
      expect(r.kind, MoneyBookKind.shared);
      expect(r.tx.payer, 'me');
      expect(r.tx.payerShare, 37501);
      expect(r.own, isNotNull);
    });

    testWidgets('linked entry made by the partner: amount + delete locked', (
      tester,
    ) async {
      final tx = _sharedExp(
        's1',
        480000,
        payer: 'her',
        linkId: 'L1',
        createdBy: 'her',
      );
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(txs: [tx]),
        );
      await _open(tester, money, book: MoneyBookKind.shared, editing: tx);
      expect(
        find.text('Chỉ Thảo sửa được số tiền vì khoản này có ở sổ của Thảo'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Xoá một ký tự'), findsNothing);
      expect(find.text('Xoá khoản'), findsNothing);
      expect(find.text('50k'), findsNothing);
    });

    testWidgets('delete waits 5 s and Hoàn tác brings the entry back', (
      tester,
    ) async {
      final tx = _exp('d1', 480000, note: 'Lẩu Thái Phố Huế');
      final money = _withOwn(txs: [tx]);
      await _open(tester, money, editing: tx);
      await tester.tap(find.text('Xoá khoản'));
      await tester.pumpAndSettle();
      expect(money.isDeleting('d1'), isTrue);
      expect(money.visibleTxs(MoneyBookKind.own), isEmpty);
      expect(
        find.text('Đã xoá Lẩu Thái Phố Huế · 480.000\u00a0₫'),
        findsOneWidget,
      );
      await tester.tap(find.text('Hoàn tác'));
      await tester.pump();
      expect(money.isDeleting('d1'), isFalse);
      expect(money.visibleTxs(MoneyBookKind.own), hasLength(1));
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('MoneyHomeEntry', () {
    MoneyHomeEntryKind kind(MoneyProvider m, {bool waiting = false}) =>
        MoneyHomeEntry.kindOf(m, waiting: waiting);
    MoneyBudget total(int amount) =>
        MoneyBudget(id: 'b', categoryId: '', amount: amount);
    MoneyProvider withShared(MoneyBookState shared, {List<MoneyTx>? own}) =>
        _Money()..debugSetBooks(
          uid: 'me',
          own: _own(txs: own ?? []),
          shared: shared,
        );

    test('states', () {
      final spend = [_sharedExp('s1', 3574000)];
      expect(
        kind(withShared(_shared(txs: spend, budgets: [total(5000000)]))),
        MoneyHomeEntryKind.normal,
      );
      expect(
        kind(withShared(_shared(txs: spend))),
        MoneyHomeEntryKind.noBudget,
      );
      expect(
        kind(
          withShared(
            _shared(txs: [_sharedExp('s', 5240000)], budgets: [total(5000000)]),
          ),
        ),
        MoneyHomeEntryKind.over,
      );
      final lastMonth = MoneyTx(
        id: 'old',
        type: MoneyTxType.expense,
        amount: 100000,
        date: '${MoneyMath.addMonths(_month, -1)}-15',
        categoryId: 'food_out',
        payer: 'me',
        splitMode: MoneySplitMode.equal,
        payerShare: 50000,
        memberUids: const ['her', 'me'],
      );
      expect(
        kind(withShared(_shared(txs: [lastMonth]))),
        MoneyHomeEntryKind.monthEmpty,
      );
      expect(
        kind(withShared(_shared(loaded: false))),
        MoneyHomeEntryKind.loading,
      );
      expect(kind(withShared(_shared())), MoneyHomeEntryKind.neverLogged);
      final waitingOwn = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(txs: [_exp('a', 1000)]),
        );
      expect(kind(waitingOwn, waiting: true), MoneyHomeEntryKind.waiting);
      final neverOwn = _Money()..debugSetBooks(uid: 'me', own: _own());
      expect(kind(neverOwn, waiting: true), MoneyHomeEntryKind.neverLogged);
    });

    testWidgets('normal row reads the shared month + budget %', (tester) async {
      final m = withShared(
        _shared(txs: [_sharedExp('s1', 3574000)], budgets: [total(5000000)]),
      );
      await tester.pumpWidget(_app(m, const MoneyHomeEntry(waiting: false)));
      await tester.pump();
      expect(
        find.textContaining('71% ngân sách', findRichText: true),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Ghi khoản'), findsOneWidget);
    });

    testWidgets('waiting couple: own book, only today\'s count', (
      tester,
    ) async {
      final m = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(
            txs: [
              _exp('a', 1000),
              _exp('b', 2000),
              _exp('c', 3000, date: _daysAgo(1)),
            ],
          ),
        );
      await tester.pumpWidget(_app(m, const MoneyHomeEntry(waiting: true)));
      await tester.pump();
      expect(find.text('Sổ tiền của mình'), findsOneWidget);
      expect(find.text('Hôm nay đã ghi 2 khoản'), findsOneWidget);
      expect(find.textContaining('₫'), findsNothing);
    });

    testWidgets('over budget shows "vượt …"', (tester) async {
      final m = withShared(
        _shared(txs: [_sharedExp('s', 5240000)], budgets: [total(5000000)]),
      );
      await tester.pumpWidget(_app(m, const MoneyHomeEntry(waiting: false)));
      await tester.pump();
      expect(
        find.textContaining('vượt 240.000\u00a0₫', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('First run', () {
    testWidgets('credit card owed 2.458.000 is stored negative', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(wallets: const []),
        );
      expect(money.needsFirstRun, isTrue);
      await tester.pumpWidget(_app(money, const MoneyScreen()));
      await tester.pump();
      expect(find.text('Tiền của mình đang nằm ở đâu?'), findsOneWidget);
      final switches = find.byType(Switch);
      await tester.tap(switches.last); // Thẻ tín dụng
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '2458000');
      await tester.pump();
      await tester.ensureVisible(find.text('Xong, vào sổ'));
      await tester.pump();
      await tester.tap(find.text('Xong, vào sổ'));
      await tester.pump();
      final call = money.ensured.single;
      expect(call.kind, MoneyBookKind.own);
      final card = call.extra.single;
      expect(card.type, MoneyWalletType.credit);
      expect(card.openingBalance, -2458000);
    });
  });

  group('Screens render', () {
    void big(WidgetTester tester) {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('own overview: month card, recent, where, wallets', (
      tester,
    ) async {
      big(tester);
      final own = _own(
        txs: [
          _exp('a', 120000, note: 'Cơm trưa với team'),
          _exp(
            'b',
            4500000,
            cat: 'home_rent',
            wallet: 'cash',
            date: _daysAgo(1),
          ),
          MoneyTx(
            id: 'i',
            type: MoneyTxType.income,
            amount: 20500000,
            date: _today,
            inWalletId: 'cash',
            categoryId: 'salary',
          ),
        ],
      );
      own.budgets = const [
        MoneyBudget(id: 't', categoryId: '', amount: 11000000),
      ];
      final money = _Money()..debugSetBooks(uid: 'me', own: own);
      await tester.pumpWidget(
        _app(money, const MoneyScreen(initialBook: MoneyBookKind.own)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Còn trong ngân sách'), findsOneWidget);
      expect(find.text('Cơm trưa với team'), findsOneWidget);
      expect(find.text('Thu trừ chi'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Tiêu vào đâu'), 200);
      expect(find.text('Tiêu vào đâu'), findsOneWidget);
    });

    testWidgets('shared overview: three lanes + who covered more', (
      tester,
    ) async {
      big(tester);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(
            txs: [
              _sharedExp('s1', 480000),
              _sharedExp('s2', 70000, payer: 'her'),
            ],
          ),
        );
      await tester.pumpWidget(
        _app(money, const MoneyScreen(initialBook: MoneyBookKind.shared)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Ai trả tháng này'), findsOneWidget);
      // 480k split → she owes 240k; 70k she paid → I owe 35k.
      expect(find.text('Mình đang ứng nhiều hơn'), findsOneWidget);
    });

    testWidgets('wallets + categories screens build', (tester) async {
      big(tester);
      final money = _Money()..debugSetBooks(uid: 'me', own: _own());
      await tester.pumpWidget(_app(money, const MoneyWalletsScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Tổng tiền đang có'), findsOneWidget);
      await tester.pumpWidget(
        _app(money, const MoneyCategoriesScreen(book: MoneyBookKind.own)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Ăn uống'), findsOneWidget);
    });
  });
}
