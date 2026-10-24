import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/providers/money_provider.dart';
import 'package:dear_embeiu/services/money_service.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/widgets/money/add_transaction_sheet.dart';
import 'package:dear_embeiu/widgets/money/money_ui.dart';

// Sổ tiền: the add / edit sheet, gap cases of
// project/features/expenses/test-cases.md (BK-03, TX-13/15/16/19/21/22,
// SPL-04/06/07/08/10/11, QR-03/04/05, FR-12, CAT-08, ED-08 UI, ED-13).

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

class _Money extends MoneyProvider {
  final List<({MoneyBookKind kind, MoneyTx tx, String? own})> added = [];
  final List<({MoneyTx old, MoneyTx updated, bool both})> updated = [];
  Completer<void>? gate;
  Object? addError;
  Object? updateError;
  MoneyWriteOutcome outcome = MoneyWriteOutcome.saved;

  @override
  Future<MoneyWriteOutcome> addTx(
    MoneyBookKind kind,
    MoneyTx draft, {
    String? ownWalletId,
  }) async {
    await gate?.future;
    if (addError != null) throw addError!;
    added.add((kind: kind, tx: draft, own: ownWalletId));
    return outcome;
  }

  @override
  Future<MoneyWriteOutcome> updateTx(
    MoneyBookKind kind,
    MoneyTx old,
    MoneyTx updated, {
    bool alsoLinked = false,
  }) async {
    if (updateError != null) throw updateError!;
    this.updated.add((old: old, updated: updated, both: alsoLinked));
    return MoneyWriteOutcome.saved;
  }

  @override
  void refreshDay() {}
}

String get _today => MoneyMath.dateKey(DateTime.now());
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
];

MoneyBookState _own({
  List<MoneyTx> txs = const [],
  List<MoneyBudget> budgets = const [],
}) {
  final s = MoneyBookState(MoneyService.own('me', firestore: _db));
  s.wallets = _wallets;
  s.walletsFromServer = true;
  s.txs = txs;
  s.txLoaded = true;
  s.everLogged = txs.isNotEmpty;
  s.budgets = budgets;
  s.windowFrom = _daysAgo(60);
  s.netSumsAt = DateTime.now();
  return s;
}

MoneyBookState _shared({
  List<MoneyTx> txs = const [],
  List<MoneyWallet> extra = const [],
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
  s.netSums = const {'joint': 0};
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
  String? linkId,
}) => MoneyTx(
  id: id,
  type: MoneyTxType.expense,
  amount: amount,
  date: date ?? _today,
  outWalletId: wallet,
  categoryId: cat,
  note: note,
  linkId: linkId,
  createdBy: 'me',
);

MoneyTx _sharedExp(String id, int amount, {String? linkId}) => MoneyTx(
  id: id,
  type: MoneyTxType.expense,
  amount: amount,
  date: _today,
  categoryId: 'food_out',
  note: 'Lẩu Thái',
  payer: 'me',
  splitMode: MoneySplitMode.equal,
  payerShare: (amount + 1) ~/ 2,
  memberUids: const ['her', 'me'],
  linkId: linkId,
  createdBy: 'me',
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

class _Opener extends StatelessWidget {
  const _Opener({
    required this.book,
    this.editing,
    this.type = MoneyTxType.expense,
    this.walletId,
    this.categoryId,
  });

  final MoneyBookKind book;
  final MoneyTx? editing;
  final MoneyTxType type;
  final String? walletId;
  final String? categoryId;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => AddTransactionSheet.show(
        context,
        book: book,
        editing: editing,
        type: type,
        walletId: walletId,
        categoryId: categoryId,
      ),
      child: const Text('open'),
    ),
  );
}

Future<void> _open(
  WidgetTester t,
  _Money money, {
  MoneyBookKind book = MoneyBookKind.own,
  MoneyTx? editing,
  MoneyTxType type = MoneyTxType.expense,
  String? walletId,
  String? categoryId,
}) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    _app(
      money,
      _Opener(
        book: book,
        editing: editing,
        type: type,
        walletId: walletId,
        categoryId: categoryId,
      ),
    ),
  );
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
}

Future<void> _keys(WidgetTester t, List<String> keys) async {
  for (final k in keys) {
    await t.tap(find.text(k).last);
    await t.pump();
  }
}

/// Scrolls the sheet to [f] first (the form is taller than the test screen).
Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await t.pump();
}

/// A save that waits on a dialog keeps the button's spinner running, so
/// pumpAndSettle would never finish: pump a fixed time instead.
Future<void> _settleBusy(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _detail(WidgetTester t) async {
  // The summary row toggles the detail panel (who pays, split, date, note).
  await t.tap(find.textContaining('Hôm nay').first);
  await t.pumpAndSettle();
}

_Money _oneBook({
  List<MoneyTx> txs = const [],
  List<MoneyBudget> budgets = const [],
}) => _Money()
  ..debugSetBooks(
    uid: 'me',
    own: _own(txs: txs, budgets: budgets),
  );

_Money _pair({
  List<MoneyTx> own = const [],
  List<MoneyTx> shared = const [],
  List<MoneyWallet> fund = const [],
}) => _Money()
  ..debugSetBooks(
    uid: 'me',
    own: _own(txs: own),
    shared: _shared(txs: shared, extra: fund),
  );

MoneyPrimaryButton _save(WidgetTester t) =>
    t.widget<MoneyPrimaryButton>(find.byType(MoneyPrimaryButton));

void main() {
  setUp(() => AppL10n.setLocale(const Locale('vi')));

  final repeats = [
    _exp('a', 120000, note: 'Cơm trưa', date: _daysAgo(1)),
    _exp('b', 110000, note: 'Cơm trưa', date: _daysAgo(2)),
    _exp('c', 50000, cat: 'food_coffee', wallet: 'cash', date: _daysAgo(3)),
  ];

  group('quick row', () {
    testWidgets('QR-05: a book with no entries has no "khoản quen" row', (
      t,
    ) async {
      await _open(t, _oneBook());
      expect(find.text('Ghi lại khoản quen'), findsNothing);
    });

    testWidgets('QR-04: chip = "<note> · 120k", or "<category> · 50k" without '
        'a note', (t) async {
      await _open(t, _oneBook(txs: repeats));
      expect(find.text('Ghi lại khoản quen'), findsOneWidget);
      expect(find.text('Cơm trưa · 120k'), findsOneWidget);
      expect(find.text('Cà phê, trà sữa · 50k'), findsOneWidget);
    });

    testWidgets('QR-03: hidden after a digit, on the Thu tab, and when '
        'editing', (t) async {
      await _open(t, _oneBook(txs: repeats));
      expect(find.text('Ghi lại khoản quen'), findsOneWidget);
      await _keys(t, ['1']);
      expect(find.text('Ghi lại khoản quen'), findsNothing);
      await t.tap(find.bySemanticsLabel('Xoá một ký tự'));
      await t.pump();
      expect(find.text('Ghi lại khoản quen'), findsOneWidget);
      await t.tap(find.text('Thu').last);
      await t.pumpAndSettle();
      expect(find.text('Ghi lại khoản quen'), findsNothing);
    });

    testWidgets('QR-03: not on the edit form', (t) async {
      final money = _oneBook(txs: repeats);
      await _open(t, money, editing: repeats.first);
      expect(find.text('Ghi lại khoản quen'), findsNothing);
    });
  });

  group('save', () {
    testWidgets('TX-13: pressing Lưu twice writes ONE entry', (t) async {
      final money = _oneBook()..gate = Completer<void>();
      await _open(t, money);
      await _keys(t, ['5', '0', 'k']);
      final btn = find.byType(MoneyPrimaryButton);
      await t.tap(btn);
      await t.pump();
      await t.tap(btn, warnIfMissed: false);
      await t.pump();
      expect(_save(t).busy, isTrue);
      money.gate!.complete();
      await t.pumpAndSettle();
      expect(money.added, hasLength(1));
      expect(money.added.single.tx.amount, 50000);
    });

    testWidgets('TX-15: a refused write → snackbar, the form stays with the '
        'typed amount, Lưu usable again', (t) async {
      final money = _oneBook()
        ..addError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      await _open(t, money);
      await _keys(t, ['5', '0', 'k']);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(
        find.text('Chưa lưu được khoản này. Thử lại nhé.'),
        findsOneWidget,
      );
      expect(find.byType(AddTransactionSheet), findsOneWidget);
      expect(find.textContaining('Lưu 50.000'), findsOneWidget);
      expect(_save(t).busy, isFalse);
      expect(_save(t).onPressed, isNotNull);
      expect(money.added, isEmpty);
    });

    testWidgets('OFF-03: a write the server has not answered yet says it is '
        'waiting for the network (own book), and (shared book) too', (t) async {
      final own = _oneBook()..outcome = MoneyWriteOutcome.queued;
      await _open(t, own);
      await _keys(t, ['5', '0', 'k']);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(
        find.textContaining('Đang chờ mạng, có mạng sẽ tự gửi lên'),
        findsOneWidget,
      );
      expect(find.textContaining('sổ chung'), findsNothing);
      expect(own.added, hasLength(1));
    });

    testWidgets('OFF-03: shared book wording', (t) async {
      final m = _pair()..outcome = MoneyWriteOutcome.queued;
      await _open(t, m, book: MoneyBookKind.shared);
      await _keys(t, ['5', '0', 'k']);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(
        find.text('Đang chờ mạng, có mạng sẽ tự gửi lên sổ chung'),
        findsOneWidget,
      );
    });

    testWidgets('ED-08: the 2nd of two edits (permission-denied) closes with '
        '"Thảo vừa sửa khoản này"', (t) async {
      final tx = _sharedExp('s1', 480000);
      final money = _pair(shared: [tx])
        ..updateError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      await _open(t, money, book: MoneyBookKind.shared, editing: tx);
      await _keys(t, ['5', '0', '0', 'k']); // a new amount
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(
        find.text('Chưa lưu được: Thảo vừa sửa khoản này'),
        findsOneWidget,
      );
      expect(
        find.text('Đã hiện bản mới nhất, sửa lại nếu cần'),
        findsOneWidget,
      );
      expect(find.byType(AddTransactionSheet), findsNothing);
    });

    testWidgets('TX-16: an entry that takes a group to 80 % says so, then '
        '100 % says "đã vượt"', (t) async {
      const budget = MoneyBudget(
        id: 'food',
        categoryId: 'food',
        amount: 2000000,
      );
      // 1,0tr already spent on food + 0,6tr → 80 %.
      final m80 = _oneBook(
        txs: [_exp('a', 1000000, note: 'Siêu thị', cat: 'food_market')],
        budgets: const [budget],
      );
      await _open(t, m80);
      await t.tap(find.text('Ăn ngoài').first);
      await t.pump();
      await _keys(t, ['6', '0', '0', 'k']);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(find.text('Ăn uống đã dùng 80% ngân sách tháng'), findsOneWidget);
      expect(m80.added, hasLength(1));
    });

    testWidgets('TX-16: crossing 100 %', (t) async {
      const budget = MoneyBudget(
        id: 'food',
        categoryId: 'food',
        amount: 2000000,
      );
      final m100 = _oneBook(
        txs: [_exp('a', 1900000, note: 'Tiệc', cat: 'food_market')],
        budgets: const [budget],
      );
      await _open(t, m100);
      await t.tap(find.text('Ăn ngoài').first);
      await t.pump();
      await _keys(t, ['3', '0', '0', 'k']);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(find.textContaining('Ăn uống đã vượt ngân sách'), findsOneWidget);
    });

    testWidgets('TX-19: Android Back with an amount typed asks first; '
        '"Tiếp tục ghi" keeps it, "Bỏ khoản này" closes', (t) async {
      await _open(t, _oneBook());
      await _keys(t, ['5', '0', 'k']);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Bỏ khoản đang ghi?'), findsOneWidget);
      await t.tap(find.text('Tiếp tục ghi'));
      await t.pumpAndSettle();
      expect(find.byType(AddTransactionSheet), findsOneWidget);
      expect(find.textContaining('Lưu 50.000'), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.tap(find.text('Bỏ khoản này'));
      await t.pumpAndSettle();
      expect(find.byType(AddTransactionSheet), findsNothing);
    });

    testWidgets('TX-19: Back on an empty form just closes', (t) async {
      await _open(t, _oneBook());
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Bỏ khoản đang ghi?'), findsNothing);
      expect(find.byType(AddTransactionSheet), findsNothing);
    });
  });

  group('wallets & categories', () {
    testWidgets('TX-14: an archived wallet is not offered', (t) async {
      final own = _own();
      own.wallets = [
        ..._wallets,
        const MoneyWallet(
          id: 'old',
          name: 'Ví cũ',
          type: MoneyWalletType.bank,
          archived: true,
          order: 2,
        ),
      ];
      final money = _Money()..debugSetBooks(uid: 'me', own: own);
      await _open(t, money);
      expect(find.text('MoMo'), findsOneWidget);
      expect(find.text('Ví cũ'), findsNothing);
    });

    testWidgets('FR-12: a first-entry chip opens the form with that category '
        'picked', (t) async {
      final money = _oneBook();
      await _open(t, money, categoryId: 'food_coffee');
      await _keys(t, ['3', '0', 'k']);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(money.added.single.tx.categoryId, 'food_coffee');
    });

    testWidgets('CAT-08: the picker finds "trà sữa" typed without accents; '
        'no match says so', (t) async {
      await _open(t, _oneBook());
      await _tap(t, find.text('Tất cả'));
      await t.pumpAndSettle();
      final field = find.byType(TextField).last;
      await t.enterText(field, 'tra sua');
      await t.pumpAndSettle();
      final picker = find.byType(MoneyCategoryPicker);
      expect(
        find.descendant(of: picker, matching: find.text('Cà phê, trà sữa')),
        findsWidgets,
      );
      expect(
        find.descendant(of: picker, matching: find.text('Xăng xe')),
        findsNothing,
      );
      await t.enterText(field, 'zzzz');
      await t.pumpAndSettle();
      expect(find.text('Không có danh mục nào khớp.'), findsOneWidget);
    });

    testWidgets('BK-03: switching book resets wallets, categories and the '
        'quick row', (t) async {
      final money = _pair(own: repeats);
      await _open(t, money, book: MoneyBookKind.shared);
      // Shared: "Trừ vào ví của mình", and the shared book has no repeats.
      expect(find.text('Trừ vào ví của mình'), findsOneWidget);
      expect(find.text('Ghi lại khoản quen'), findsNothing);
      await t.tap(find.bySemanticsLabel('Đổi sổ, đang ở Sổ chung'));
      await t.pumpAndSettle();
      // Own: plain "Ví", and its quick row shows.
      expect(find.text('Trừ vào ví của mình'), findsNothing);
      expect(find.text('Ví'), findsOneWidget);
      expect(find.text('Ghi lại khoản quen'), findsOneWidget);
      expect(find.text('Cơm trưa · 120k'), findsOneWidget);
      // And back.
      await t.tap(find.bySemanticsLabel('Đổi sổ, đang ở Của mình'));
      await t.pumpAndSettle();
      expect(find.text('Trừ vào ví của mình'), findsOneWidget);
      expect(find.text('Ghi lại khoản quen'), findsNothing);
    });
  });

  group('shared book', () {
    testWidgets('TX-21: income in the shared book has no "Ai trả"; it lands '
        'in a shared wallet', (t) async {
      final money = _pair();
      await _open(
        t,
        money,
        book: MoneyBookKind.shared,
        type: MoneyTxType.income,
      );
      await _keys(t, ['2', '0', '0', 'k']);
      await _detail(t);
      expect(find.text('Ai trả'), findsNothing);
      expect(find.text('Vào ví'), findsOneWidget);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      final tx = money.added.single.tx;
      expect(tx.type, MoneyTxType.income);
      expect(tx.inWalletId, 'joint');
      expect(tx.payer, 'me');
      expect(tx.splitMode, MoneySplitMode.none);
    });

    testWidgets('TX-22 / SPL-07: "Chi từ quỹ" — the fund pays, no one owes '
        'anyone', (t) async {
      final money = _pair(
        fund: const [
          MoneyWallet(
            id: 'fund',
            name: 'Quỹ Đà Lạt',
            type: MoneyWalletType.goal,
            emoji: '🏔️',
            goalTarget: 5000000,
            memberUids: ['her', 'me'],
          ),
        ],
      );
      await _open(t, money, book: MoneyBookKind.shared, walletId: 'fund');
      await _keys(t, ['3', '0', '0', 'k']);
      await _detail(t);
      expect(
        find.text('Trả từ Ví chung nên không ai phải trả lại ai.'),
        findsOneWidget,
      );
      expect(find.text('Chia thế nào'), findsNothing);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      final tx = money.added.single.tx;
      expect(tx.payer, kMoneyPayerWallet);
      expect(tx.outWalletId, 'fund');
      expect(tx.splitMode, MoneySplitMode.none);
      expect(tx.payerShare, 0);
      expect(
        money.added.single.own,
        isNull,
        reason: 'nothing leaves my wallet',
      );
    });

    testWidgets('SPL-06: the share line follows the amount; before one it asks '
        'for it', (t) async {
      await _open(t, _pair(), book: MoneyBookKind.shared);
      await _detail(t);
      expect(
        find.text('Nhập số tiền để xem mỗi người chịu bao nhiêu'),
        findsOneWidget,
      );
      await t.tap(find.text('100k'));
      await t.pumpAndSettle();
      expect(
        find.text('Mình chịu 50.000 ₫ · Thảo chịu 50.000 ₫'),
        findsOneWidget,
      );
      await t.tap(find.text('50k'));
      await t.pumpAndSettle();
      expect(
        find.text('Mình chịu 75.000 ₫ · Thảo chịu 75.000 ₫'),
        findsOneWidget,
      );
    });

    testWidgets('SPL-04: "Tuỳ" — starts at half, the stepper moves 10 % and '
        'stays in [0, amount]', (t) async {
      final money = _pair();
      await _open(t, money, book: MoneyBookKind.shared);
      await t.tap(find.text('200k'));
      await t.tap(find.text('100k'));
      await t.pump();
      await _detail(t);
      await t.tap(find.text('Tuỳ'));
      await t.pumpAndSettle();
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.suffixText == '₫',
      );
      TextField custom() => t.widget<TextField>(field);
      expect(custom().controller!.text, '150000');
      await _tap(t, find.byTooltip('Thêm 10%'));
      expect(custom().controller!.text, '180000');
      for (var i = 0; i < 6; i++) {
        await _tap(t, find.byTooltip('Thêm 10%'));
      }
      expect(
        custom().controller!.text,
        '300000',
        reason: 'capped at the amount',
      );
      for (var i = 0; i < 10; i++) {
        await _tap(t, find.byTooltip('Bớt 10%'));
      }
      expect(custom().controller!.text, '0', reason: 'floored at 0');
      await t.enterText(field, '100000');
      await t.pump();
      expect(
        find.text('Mình chịu 100.000 ₫ · Thảo chịu 200.000 ₫'),
        findsOneWidget,
      );
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      final tx = money.added.single.tx;
      expect(tx.splitMode, MoneySplitMode.custom);
      expect(tx.payerShare, 100000);
    });

    testWidgets(
      'BUG (Low) SPL-04: "Bớt 10%" at 0 stays at 0 — today the field reads 0 '
      'as invalid (parseVndInput zero), so the stepper jumps 0 → half − 10% '
      '(add_transaction_sheet.dart _customRow.step / _payerShare)',
      (t) async {
        await _open(t, _pair(), book: MoneyBookKind.shared);
        await t.tap(find.text('200k'));
        await t.tap(find.text('100k'));
        await t.pump();
        await _detail(t);
        await t.tap(find.text('Tuỳ'));
        await t.pumpAndSettle();
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.suffixText == '₫',
        );
        await t.enterText(field, '30000');
        await _tap(t, find.byTooltip('Bớt 10%')); // 30000 → 0
        await _tap(t, find.byTooltip('Bớt 10%')); // 0 → should stay 0
        expect(t.widget<TextField>(field).controller!.text, '0');
      },
    );

    testWidgets('SPL-10: with a wallet chosen the own half is written', (
      t,
    ) async {
      final money = _pair();
      await _open(t, money, book: MoneyBookKind.shared);
      await _keys(t, ['1', '0', '0', 'k']);
      await _tap(t, find.text('MoMo'));
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(money.added.single.own, 'momo');
    });

    testWidgets('SPL-11: the partner paid → no "Trừ vào ví của mình" row', (
      t,
    ) async {
      final money = _pair();
      await _open(t, money, book: MoneyBookKind.shared);
      expect(find.text('Trừ vào ví của mình'), findsOneWidget);
      await _keys(t, ['1', '0', '0', 'k']);
      await _detail(t);
      await t.tap(find.text('Thảo').first);
      await t.pumpAndSettle();
      expect(find.text('Trừ vào ví của mình'), findsNothing);
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(money.added.single.tx.payer, 'her');
      expect(money.added.single.own, isNull);
    });
  });

  group('linked entries', () {
    testWidgets('ED-13: changing the amount of a linked shared entry asks '
        '"Sửa luôn bên sổ của mình?" — both / shared only', (t) async {
      final shared = _sharedExp('s1', 480000, linkId: 'L1');
      final mine = _exp('o1', 480000, note: 'Lẩu Thái', linkId: 'L1');
      for (final both in [true, false]) {
        final money = _pair(own: [mine], shared: [shared]);
        await _open(t, money, book: MoneyBookKind.shared, editing: shared);
        await _keys(t, ['5', '0', '0', 'k']);
        await t.tap(find.byType(MoneyPrimaryButton));
        await _settleBusy(t);
        expect(find.text('Sửa luôn bên sổ của mình?'), findsOneWidget);
        expect(find.textContaining('Đổi thành 500.000'), findsOneWidget);
        await t.tap(find.text(both ? 'Sửa cả hai' : 'Chỉ sổ chung'));
        await t.pumpAndSettle();
        expect(money.updated.single.both, both);
        expect(money.updated.single.updated.amount, 500000);
      }
    });

    testWidgets('ED-13: no question when the amount did not change', (t) async {
      final shared = _sharedExp('s1', 480000, linkId: 'L1');
      final mine = _exp('o1', 480000, note: 'Lẩu Thái', linkId: 'L1');
      final money = _pair(own: [mine], shared: [shared]);
      await _open(t, money, book: MoneyBookKind.shared, editing: shared);
      await _detail(t);
      await t.enterText(find.byType(TextField).last, 'Lẩu Thái ngon');
      await t.pump();
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(find.text('Sửa luôn bên sổ của mình?'), findsNothing);
      expect(money.updated.single.both, isTrue, reason: 'mirrored silently');
    });
  });

  group('remembered split (Hive)', () {
    testWidgets('SPL-08: first time "Chia đôi"; afterwards the last split and '
        'payer are remembered on this phone', (t) async {
      // The memory of the last split is a Hive box. Opened here only (in
      // memory, so no file IO under the fake clock) and last in the file, so
      // no other test sees it.
      await t.runAsync(
        () => Hive.openBox<String>('app_settings', bytes: Uint8List(0)),
      );
      final money = _pair();
      await _open(t, money, book: MoneyBookKind.shared);
      await _keys(t, ['2', '0', '0', 'k']);
      await _detail(t);
      // Default is half and half.
      expect(
        find.text('Mình chịu 100.000 ₫ · Thảo chịu 100.000 ₫'),
        findsOneWidget,
      );
      await t.tap(find.text('Mình mời'));
      await t.pumpAndSettle();
      await t.tap(find.byType(MoneyPrimaryButton));
      await t.pumpAndSettle();
      expect(money.added.single.tx.splitMode, MoneySplitMode.treat);
      expect(Hive.box<String>('app_settings').get('money_last_split'), 'treat');

      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await _keys(t, ['2', '0', '0', 'k']);
      await _detail(t);
      expect(find.text('Mình chịu 200.000 ₫ · Thảo chịu 0 ₫'), findsOneWidget);
    });
  });
}
