import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/data/money_categories.dart';
import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/providers/money_provider.dart';
import 'package:dear_embeiu/screens/money/money_screen.dart';
import 'package:dear_embeiu/services/money_service.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/widgets/content_card.dart';
import 'package:dear_embeiu/widgets/money/add_transaction_sheet.dart';
import 'package:dear_embeiu/widgets/money/money_home_entry.dart';
import 'package:dear_embeiu/widgets/money/money_ui.dart';

// Sổ tiền: widget-level gap cases of project/features/expenses/test-cases.md
// (FR-*, HM-*, MON-03, OFF-04, WAIT-02, BUD-16, A11Y-*, TX-10, ED-09 …).
// Same stand-ins as money_ui_test.dart: a fake Firestore, a MoneyProvider
// subclass that records writes, books put in place with debugSetBooks.

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
  final List<({MoneyBookKind kind, List<MoneyWallet> extra, int start})>
  ensured = [];
  final List<MoneyBookKind> retried = [];
  final List<({String id, bool archived})> archived = [];

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
  void refreshDay() {}

  @override
  void retry(MoneyBookKind kind) => retried.add(kind);

  @override
  Future<void> ensureDefaultWallet(
    MoneyBookKind kind, {
    List<MoneyWallet> extra = const <MoneyWallet>[],
    int starterBalance = 0,
  }) async {
    ensured.add((kind: kind, extra: extra, start: starterBalance));
  }
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
  List<MoneyWallet> wallets = _wallets,
  bool fromServer = true,
  bool? everLogged,
  List<MoneyBudget> budgets = const [],
}) {
  final s = MoneyBookState(MoneyService.own('me', firestore: _db));
  s.wallets = wallets;
  s.walletsFromServer = fromServer;
  s.txs = txs;
  s.txLoaded = true;
  s.everLogged = everLogged ?? txs.isNotEmpty;
  s.windowFrom = _daysAgo(60);
  s.netSumsAt = DateTime.now();
  s.budgets = budgets;
  return s;
}

MoneyBookState _shared({
  List<MoneyTx> txs = const [],
  bool loaded = true,
  Object? error,
  bool? everLogged,
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
  s.loadError = error;
  s.everLogged = everLogged ?? (loaded ? txs.isNotEmpty : null);
  s.windowFrom = _daysAgo(60);
  s.netSums = const {'joint': 0};
  s.netSumsAt = loaded ? DateTime.now() : null;
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

Widget _app(
  MoneyProvider money,
  Widget home, {
  bool waiting = false,
  Locale locale = const Locale('vi'),
}) => ChangeNotifierProvider<MoneyProvider>.value(
  value: money,
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MoneyPeopleScope(
      people: MoneyPeople(
        myName: 'Tuấn',
        partnerName: 'Thảo',
        waiting: waiting,
        inviteCode: 'ABC123',
      ),
      child: child!,
    ),
    home: Scaffold(body: home),
  ),
);

void _big(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => AppL10n.setLocale(const Locale('vi')));

  group('first run', () {
    Future<_Money> open(WidgetTester t) async {
      _big(t);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(wallets: const []),
        );
      await t.pumpWidget(_app(money, const MoneyScreen()));
      await t.pump();
      return money;
    }

    testWidgets('FR-01: five wallets, Cash locked on, no "Ghi khoản" button', (
      t,
    ) async {
      await open(t);
      expect(find.text('Tiền của mình đang nằm ở đâu?'), findsOneWidget);
      for (final n in [
        'Tiền mặt',
        'Ngân hàng',
        'MoMo',
        'ZaloPay',
        'Thẻ tín dụng',
      ]) {
        expect(find.text(n), findsAtLeastNWidgets(1), reason: n);
      }
      final switches = tester0(t);
      expect(switches, hasLength(5));
      expect(switches.first.value, isTrue);
      expect(switches.first.onChanged, isNull, reason: 'Tiền mặt is locked');
      expect(
        switches.skip(1).every((s) => !s.value && s.onChanged != null),
        isTrue,
      );
      expect(find.text('Có sẵn'), findsOneWidget);
      expect(find.text('Ghi khoản'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('FR-02: MoMo 1tr5 → starter 0 + MoMo 1.500.000; the total '
        'follows', (t) async {
      final money = await open(t);
      await t.tap(find.byType(Switch).at(2));
      await t.pump();
      // Cash field first, then MoMo's.
      await t.enterText(find.byType(TextField).last, '1tr5');
      await t.pump();
      expect(
        find.textContaining('1.500.000', findRichText: true),
        findsWidgets,
      );
      await t.ensureVisible(find.text('Xong, vào sổ'));
      await t.pump();
      await t.tap(find.text('Xong, vào sổ'));
      await t.pump();
      final call = money.ensured.single;
      expect(call.start, 0);
      expect(call.extra.single.name, 'MoMo');
      expect(call.extra.single.openingBalance, 1500000);
      expect(call.extra.single.type, MoneyWalletType.ewallet);
    });

    testWidgets('FR-04: "Bỏ qua" → only the starter, balance 0, no extras', (
      t,
    ) async {
      final money = await open(t);
      await t.tap(find.byType(Switch).at(2)); // switched on, then skipped
      await t.pump();
      await t.ensureVisible(find.text('Bỏ qua'));
      await t.pump();
      await t.tap(find.text('Bỏ qua'));
      await t.pump();
      final call = money.ensured.single;
      expect(call.extra, isEmpty);
      expect(call.start, 0);
    });

    testWidgets('FR-05: "abc" → "Chưa hiểu số này", Xong is locked', (t) async {
      await open(t);
      await t.tap(find.byType(Switch).at(1));
      await t.pump();
      await t.enterText(find.byType(TextField).last, 'abc');
      await t.pump();
      expect(find.textContaining('Chưa hiểu số này'), findsOneWidget);
      expect(_primary(t).onPressed, isNull);
      await t.enterText(find.byType(TextField).last, '2tr');
      await t.pump();
      expect(find.textContaining('Chưa hiểu số này'), findsNothing);
      expect(_primary(t).onPressed, isNotNull);
    });

    testWidgets('FR-06: 101 tỷ → "Tối đa 100 tỷ một ví.", Xong is locked', (
      t,
    ) async {
      await open(t);
      await t.tap(find.byType(Switch).at(1));
      await t.pump();
      await t.enterText(find.byType(TextField).last, '101000000000');
      await t.pump();
      expect(find.text('Tối đa 100 tỷ một ví.'), findsOneWidget);
      expect(_primary(t).onPressed, isNull);
    });
  });

  group('Home row', () {
    testWidgets('FR-13: local-only phone (no books) → no row at all', (
      t,
    ) async {
      _big(t);
      final money = _Money(); // never wired
      await t.pumpWidget(_app(money, const MoneyHomeEntry(waiting: false)));
      await t.pump();
      expect(find.byType(ContentCard), findsNothing);
      expect(find.byType(MoneyHomeEntry), findsOneWidget);
    });

    testWidgets('HM-02: the round + opens the SHARED book\'s form', (t) async {
      _big(t);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(txs: [_sharedExp('s1')]),
        );
      await t.pumpWidget(_app(money, const MoneyHomeEntry(waiting: false)));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Ghi khoản'));
      await t.pumpAndSettle();
      // The form of the shared book asks who paid.
      expect(find.textContaining('Mình trả'), findsWidgets);
    });

    testWidgets('HM-03: error → "Thử lại" calls onRetry and opens nothing', (
      t,
    ) async {
      _big(t);
      var retried = 0;
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(loaded: false, error: StateError('x')),
        );
      await t.pumpWidget(
        _app(money, MoneyHomeEntry(waiting: false, onRetry: () => retried++)),
      );
      await t.pump();
      expect(find.text('Chưa tải được sổ chung'), findsOneWidget);
      await t.tap(find.text('Thử lại'));
      await t.pumpAndSettle();
      expect(retried, 1);
      expect(find.byType(MoneyScreen), findsNothing);
      expect(find.byType(AddTransactionSheet), findsNothing);
    });

    testWidgets('A11Y-03: the + is a 44 dp target, ≥ 8 dp from the row text', (
      t,
    ) async {
      _big(t);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(txs: [_sharedExp('s1')]),
        );
      await t.pumpWidget(_app(money, const MoneyHomeEntry(waiting: false)));
      await t.pump();
      final plus = find.descendant(
        of: find.bySemanticsLabel('Ghi khoản'),
        matching: find.byType(InkWell),
      );
      final size = t.getSize(plus);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      // The card keeps 68 dp on the right: 16 (gutter) + 44 + 8.
      final card = t.widget<ContentCard>(find.byType(ContentCard));
      expect((card.padding as EdgeInsets).right, greaterThanOrEqualTo(68));
    });
  });

  group('rows', () {
    MoneyRowContext ctx({MoneyBookKind kind = MoneyBookKind.own}) =>
        MoneyRowContext(
          kind: kind,
          uid: 'me',
          people: const MoneyPeople(myName: 'Tuấn', partnerName: 'Thảo'),
          categories: MoneyCategoryIndex(
            resolveMoneyCategories(
              MoneyMeta.empty,
              lookupAppLocalizations(const Locale('vi')),
            ),
          ),
          wallets: {for (final w in _wallets) w.id: w},
        );

    Future<void> row(WidgetTester t, MoneyTx tx, MoneyRowContext c) =>
        t.pumpWidget(
          MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MoneyTxRow(tx: tx, ctx: c),
            ),
          ),
        );

    testWidgets('TX-10: no note → the category name is the title', (t) async {
      await row(t, _exp('a', 50000), ctx());
      expect(find.text('Ăn ngoài'), findsOneWidget);
      await row(t, _exp('b', 50000, note: 'Bún chả'), ctx());
      expect(find.text('Bún chả'), findsOneWidget);
    });

    testWidgets('A11Y-01: read as "title, sub, âm 120.000 đồng" — no ₫', (
      t,
    ) async {
      final h = t.ensureSemantics();
      await row(t, _exp('a', 120000, note: 'Cơm trưa'), ctx());
      final label = t.getSemantics(find.byType(MoneyTxRow)).label;
      expect(label, contains('Cơm trưa'));
      expect(label, contains('Ăn ngoài · MoMo'));
      expect(label, contains('âm 120.000 đồng'));
      expect(label, isNot(contains('₫')));
      h.dispose();
    });

    testWidgets('ED-09: an entry the partner edited says "Thảo sửa hh:mm"', (
      t,
    ) async {
      final tx = _sharedExp(
        's1',
        updatedBy: 'her',
        updatedAt: DateTime(2026, 10, 23, 21, 2),
      );
      await row(t, tx, ctx(kind: MoneyBookKind.shared));
      expect(find.textContaining('Thảo sửa'), findsOneWidget);
      expect(find.textContaining('21:02'), findsOneWidget);
      // My own edit shows nothing.
      await row(
        t,
        _sharedExp(
          's1',
          updatedBy: 'me',
          updatedAt: DateTime(2026, 10, 23, 21, 2),
        ),
        ctx(kind: MoneyBookKind.shared),
      );
      expect(find.textContaining('sửa'), findsNothing);
    });
  });

  group('MoneyScreen', () {
    testWidgets('MON-03: a month without entries → the hint to the pink '
        'button', (t) async {
      _big(t);
      final money = _Money()
        ..debugSetBooks(uid: 'me', own: _own(everLogged: true));
      await t.pumpWidget(
        _app(money, const MoneyScreen(initialBook: MoneyBookKind.own)),
      );
      await t.pump();
      final m = DateTime.now().month;
      expect(
        find.text(
          'Tháng $m chưa có khoản nào. Bấm nút hồng ở góc dưới để ghi khoản đầu tiên.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('OFF-04: load error → card with "Thử lại" that retries', (
      t,
    ) async {
      _big(t);
      final own = _own(txs: [_exp('a', 50000)])..loadError = StateError('x');
      final money = _Money()..debugSetBooks(uid: 'me', own: own);
      await t.pumpWidget(
        _app(money, const MoneyScreen(initialBook: MoneyBookKind.own)),
      );
      await t.pump();
      expect(find.textContaining('Chưa tải được khoản mới.'), findsOneWidget);
      await t.tap(find.text('Thử lại'));
      await t.pump();
      expect(money.retried, [MoneyBookKind.own]);
    });

    testWidgets(
      'BUD-16: early in the month, "mới qua X/Y ngày mà đã dùng Z%"',
      (t) async {
        _big(t);
        final now = DateTime.now();
        final money = _Money()
          ..debugSetBooks(
            uid: 'me',
            own: _own(
              txs: [_exp('a', 5000000, note: 'Tiền nhà')],
              budgets: const [
                MoneyBudget(id: 'total', categoryId: '', amount: 10000000),
              ],
            ),
          );
        await t.pumpWidget(
          _app(money, const MoneyScreen(initialBook: MoneyBookKind.own)),
        );
        await t.pump();
        final total = MoneyMath.daysInMonth(MoneyMath.monthKey(now));
        expect(
          find.textContaining(
            'Tháng mới qua ${now.day}/$total ngày mà đã dùng 50% ngân sách.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('mỗi ngày chỉ còn khoảng'), findsOneWidget);
      },
    );

    testWidgets('WAIT-02: waiting couple → no shared tab; invite card at the '
        'bottom', (t) async {
      _big(t);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(txs: [_exp('a', 50000)]),
        );
      await t.pumpWidget(
        _app(
          money,
          const MoneyScreen(initialBook: MoneyBookKind.own),
          waiting: true,
        ),
      );
      await t.pump();
      expect(find.text('Chung'), findsNothing);
      // Control: with a shared book the same screen does show the tab.
      final paired = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(txs: [_exp('a', 50000)]),
          shared: _shared(txs: [_sharedExp('s1')]),
        );
      await t.pumpWidget(
        _app(paired, const MoneyScreen(initialBook: MoneyBookKind.own)),
      );
      await t.pump();
      expect(find.text('Chung'), findsOneWidget);
      await t.pumpWidget(
        _app(
          money,
          const MoneyScreen(initialBook: MoneyBookKind.own),
          waiting: true,
        ),
      );
      await t.pump();
      await t.scrollUntilVisible(
        find.textContaining('Khi người ấy vào app'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Gửi lời mời'), findsOneWidget);
    });
  });
}

MoneyTx _sharedExp(String id, {String? updatedBy, DateTime? updatedAt}) =>
    MoneyTx(
      id: id,
      type: MoneyTxType.expense,
      amount: 480000,
      date: _today,
      categoryId: 'food_out',
      note: 'Lẩu Thái',
      payer: 'me',
      splitMode: MoneySplitMode.equal,
      payerShare: 240000,
      memberUids: const ['her', 'me'],
      createdBy: 'me',
      updatedBy: updatedBy,
      updatedAt: updatedAt,
    );

List<Switch> tester0(WidgetTester t) =>
    t.widgetList<Switch>(find.byType(Switch)).toList();

MoneyPrimaryButton _primary(WidgetTester t) =>
    t.widget<MoneyPrimaryButton>(find.byType(MoneyPrimaryButton));
