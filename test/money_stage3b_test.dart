import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_notification.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/providers/money_provider.dart';
import 'package:dear_embeiu/providers/reminder_provider.dart';
import 'package:dear_embeiu/screens/money/money_goal_screen.dart';
import 'package:dear_embeiu/screens/money/money_screen.dart';
import 'package:dear_embeiu/services/money_service.dart';
import 'package:dear_embeiu/services/push_notification_service.dart';
import 'package:dear_embeiu/services/reminder_service.dart';
import 'package:dear_embeiu/utils/money_flows.dart';
import 'package:dear_embeiu/utils/money_input.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/widgets/money/add_transaction_sheet.dart';
import 'package:dear_embeiu/widgets/money/money_notification_text.dart';
import 'package:dear_embeiu/widgets/money/money_ui.dart';
import 'package:dear_embeiu/widgets/money/settle_sheet.dart';

/// Sổ tiền stage 3B (feature expenses): fund screen + "Góp vào quỹ",
/// settle-up, decision-wheel "Ghi chi", the evening reminder 1210–1211 and
/// the money_* push / inbox routes.

// ── Firestore stand-ins (only `collection().doc()`; queries throw) ─────────

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
  final List<String> deleted = [];

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
  void scheduleDelete(
    MoneyBookKind kind,
    MoneyTx tx, {
    MoneyTx? alsoLinked,
    bool byUser = false,
  }) => deleted.add(tx.id);

  /// What the server says when the settle sheet re-checks; unset = the
  /// number the sheet opened with. `null` inside = offline.
  ({int? balance})? fresh;
  int rechecks = 0;

  @override
  Future<int?> refreshCoupleBalance() async {
    rechecks++;
    final f = fresh;
    return f == null ? coupleBalance() : f.balance;
  }

  @override
  void refreshDay() {}

  @override
  Future<void> ensureDefaultWallet(
    MoneyBookKind kind, {
    List<MoneyWallet> extra = const <MoneyWallet>[],
    int starterBalance = 0,
  }) async {}
}

final _db = _FakeDb();
String get _today => MoneyMath.dateKey(DateTime.now());

const _ownWallets = <MoneyWallet>[
  MoneyWallet(id: 'cash', name: 'Tiền mặt', type: MoneyWalletType.cash),
  MoneyWallet(
    id: 'tcb',
    name: 'Techcombank',
    type: MoneyWalletType.bank,
    order: 1,
  ),
];

MoneyBookState _own() {
  final s = MoneyBookState(MoneyService.own('me', firestore: _db));
  s.wallets = _ownWallets;
  s.walletsFromServer = true;
  s.txLoaded = true;
  s.everLogged = true;
  s.netSumsAt = DateTime.now();
  return s;
}

MoneyWallet _dalat({String? deadline}) => MoneyWallet(
  id: 'v_dalat',
  name: 'Quỹ Đà Lạt',
  type: MoneyWalletType.goal,
  emoji: '🏔️',
  goalTarget: 5000000,
  goalDeadline: deadline,
  memberUids: const ['her', 'me'],
);

MoneyBookState _shared({
  List<MoneyTx> txs = const [],
  int coupleNet = 0,
  int fund = 0,
  String? deadline,
}) {
  final s = MoneyBookState(
    MoneyService.shared('c1', const ['her', 'me'], firestore: _db),
  );
  s.wallets = [_dalat(deadline: deadline)];
  s.walletsFromServer = true;
  s.txs = txs;
  s.txLoaded = true;
  s.everLogged = true;
  s.windowFrom = MoneyMath.dateKey(
    DateTime.now().subtract(const Duration(days: 45)),
  );
  s.netSums = {'v_dalat': fund};
  s.coupleNet = coupleNet;
  s.netSumsAt = DateTime.now();
  return s;
}

MoneyTx _contrib(String id, int amount, String payer) => MoneyTx(
  id: id,
  type: MoneyTxType.contribution,
  amount: amount,
  date: _today,
  inWalletId: 'v_dalat',
  payer: payer,
  splitMode: MoneySplitMode.none,
  memberUids: const ['her', 'me'],
);

MoneyTx _sx(
  String id,
  int amount,
  String payer,
  MoneySplitMode split, {
  MoneyTxType type = MoneyTxType.expense,
  String out = '',
}) => MoneyTx(
  id: id,
  type: type,
  amount: amount,
  date: _today,
  categoryId: type == MoneyTxType.expense ? 'food_out' : '',
  outWalletId: out,
  payer: payer,
  splitMode: split,
  payerShare: type == MoneyTxType.settle
      ? 0
      : MoneyMath.payerShareFor(split, amount),
  memberUids: const ['her', 'me'],
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

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class _Opener extends StatelessWidget {
  const _Opener(this.onTap);

  final void Function(BuildContext) onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => onTap(context),
      child: const Text('open'),
    ),
  );
}

/// The OS side of the evening band.
class _FakeReminders extends Fake implements ReminderService {
  final List<List<({int id, DateTime when, String title, String body})>>
  scheduled = [];
  int cancels = 0;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleMoneyEvening(
    List<({int id, DateTime when, String title, String body})> slots,
  ) async => scheduled.add(slots);

  @override
  Future<void> cancelMoneyEvening() async => cancels++;
}

String _v(int amount) => formatVnd(amount, locale: 'vi');

void main() {
  setUp(() => AppL10n.setLocale(const Locale('vi')));
  final l10n = lookupAppLocalizations(const Locale('vi'));

  group('Quỹ (fund)', () {
    test('40% · còn 3.000.000 · ~1.000.000 a month for 3 months', () {
      final v = MoneyGoalView.of(
        _dalat(deadline: '2027-01-31'),
        2000000,
        '2026-10-20',
      );
      expect(v.percent, 40);
      expect(v.left, 3000000);
      expect(v.perMonth, 1000000);
      expect(v.reached, isFalse);
    });

    test('full at 100% (and past it): nothing left, nothing a month', () {
      for (final balance in [5000000, 6000000]) {
        final v = MoneyGoalView.of(
          _dalat(deadline: '2027-01-31'),
          balance,
          '2026-10-20',
        );
        expect(v.reached, isTrue);
        expect(v.left, 0);
        expect(v.perMonth, 0);
      }
    });

    test('no deadline → no per-month number; trip name drops "Quỹ"', () {
      expect(MoneyGoalView.of(_dalat(), 1, '2026-10-20').perMonth, 0);
      expect(moneyTripName('Quỹ Đà Lạt'), 'Đà Lạt');
      expect(moneyTripName('Da Lat fund'), 'Da Lat');
      expect(moneyTripName('Laptop mới'), 'Laptop mới');
      // "Quy Nhơn" is a city, not "Quỹ Nhơn" (Tester Low).
      expect(moneyTripName('Quy Nhơn'), 'Quy Nhơn');
      expect(moneyTripName('Quỹ Quy Nhơn'), 'Quy Nhơn');
      expect(moneyTripName('quỹ Quy Nhơn'), 'Quy Nhơn');
    });

    test('history: server rows + live window, newest first, minus undo', () {
      final old = _contrib('a', 100, 'me').copyWith(date: '2026-01-01');
      final rows = moneyWalletHistory(
        walletId: 'v_dalat',
        fetched: [old, _contrib('b', 1, 'her')],
        live: [_contrib('b', 2, 'her'), _contrib('c', 3, 'me')],
        deleting: (id) => id == 'c',
      );
      expect(rows.map((t) => t.id), ['b', 'a']);
      expect(rows.first.amount, 2); // the live copy wins
    });

    testWidgets('screen: 40%, lanes Thảo | Mình, per-month line', (
      tester,
    ) async {
      _phone(tester);
      final deadline = MoneyMath.dateKey(
        DateTime(DateTime.now().year, DateTime.now().month + 3, 28),
      );
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(
            fund: 2000000,
            deadline: deadline,
            txs: [_contrib('c1', 1200000, 'me'), _contrib('c2', 800000, 'her')],
          ),
        );
      await tester.pumpWidget(
        _app(
          money,
          const MoneyGoalScreen(
            book: MoneyBookKind.shared,
            walletId: 'v_dalat',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Mỗi người góp'), findsOneWidget);
      final per = MoneyMath.perMonthNeeded(3000000, _today, deadline);
      expect(find.textContaining(_v(per)), findsOneWidget);
      expect(find.textContaining('Để kịp'), findsOneWidget);
      expect(find.text('Góp vào quỹ'), findsOneWidget);
      expect(find.text('Chi từ quỹ'), findsOneWidget);
    });

    testWidgets('screen at 100%: "Đủ rồi. Lên lịch đi Đà Lạt thôi…"', (
      tester,
    ) async {
      _phone(tester);
      final money = _Money()
        ..debugSetBooks(uid: 'me', own: _own(), shared: _shared(fund: 5000000));
      await tester.pumpWidget(
        _app(
          money,
          const MoneyGoalScreen(
            book: MoneyBookKind.shared,
            walletId: 'v_dalat',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
      expect(find.textContaining('Lên lịch đi Đà Lạt thôi'), findsOneWidget);
    });

    testWidgets('Góp vào quỹ: my 500k into the fund, out of my wallet', (
      tester,
    ) async {
      _phone(tester);
      final money = _Money()
        ..debugSetBooks(uid: 'me', own: _own(), shared: _shared());
      await tester.pumpWidget(
        _app(
          money,
          _Opener(
            (c) => MoneyContributeSheet.show(
              c,
              book: MoneyBookKind.shared,
              wallet: _dalat(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '500k');
      await tester.pump();
      await tester.tap(find.text('Góp ${_v(500000)}'));
      await tester.pumpAndSettle();
      final r = money.added.single;
      expect(r.kind, MoneyBookKind.shared);
      expect(r.tx.type, MoneyTxType.contribution);
      expect(r.tx.inWalletId, 'v_dalat');
      expect(r.tx.payer, 'me');
      expect(r.tx.amount, 500000);
      expect(r.own, 'cash');
      expect(find.text('Đã góp ${_v(500000)} vào Quỹ Đà Lạt'), findsOneWidget);
    });
  });

  group('Thanh toán (settle)', () {
    test('parts add up to the balance; treats + the wallet left out', () {
      final txs = [
        _sx('a', 480000, 'me', MoneySplitMode.equal), // +240.000
        _sx('b', 70000, 'her', MoneySplitMode.forPartner), // −70.000
        _sx('c', 200000, 'me', MoneySplitMode.treat), // 0
        _sx('d', 90000, 'wallet', MoneySplitMode.none, out: 'joint'), // 0
        _sx('e', 50000, 'her', MoneySplitMode.none, type: MoneyTxType.settle),
      ];
      final parts = moneySettleParts(txs, 'me');
      expect(parts.map((p) => p.tx.id), ['a', 'b', 'e']);
      expect(
        parts.fold<int>(0, (s, p) => s + p.signed),
        MoneyMath.coupleBalance(txs, 'me'),
      );
      expect(moneyTreatCount(txs), 1);
      expect(moneySettleHalf(359000), 179500);
      expect(moneySettleHalf(359001), 179501);
    });

    Future<_Money> openSettle(WidgetTester tester, {int net = 359000}) async {
      _phone(tester);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(coupleNet: net),
        );
      await tester.pumpWidget(_app(money, _Opener(SettleSheet.show)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return money;
    }

    testWidgets('Trả hết: Thảo pays 359.000 back into my wallet', (
      tester,
    ) async {
      AppL10n.setLocale(const Locale('vi'));
      final money = await openSettle(tester);
      expect(find.text('Thảo trả lại cho mình'), findsOneWidget);
      expect(find.text('Vì sao là ${_v(359000)}'), findsOneWidget);
      // The field groups thousands like the rest of the screen (smoke).
      expect(find.widgetWithText(TextField, '359.000'), findsOneWidget);
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      final r = money.added.single;
      expect(r.tx.type, MoneyTxType.settle);
      expect(r.tx.payer, 'her');
      expect(r.tx.amount, 359000);
      expect(r.own, 'cash');
      expect(find.text('Đã ghi Thảo trả lại ${_v(359000)}'), findsOneWidget);
      // Hoàn tác → the settle (and its own half) are deleted.
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(money.deleted, [r.tx.id]);
    });

    testWidgets('Một nửa → 179.500; switch off → nothing in my book', (
      tester,
    ) async {
      final money = await openSettle(tester);
      await tester.tap(find.text('Một nửa · ${_v(179500)}'));
      await tester.pump();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      expect(money.added.single.tx.amount, 179500);
      expect(money.added.single.own, isNull);
    });

    testWidgets('number changed on the server: sheet updates, no write', (
      tester,
    ) async {
      final money = await openSettle(tester);
      // The partner settled 159.000 on her phone meanwhile.
      money.fresh = (balance: 200000);
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      expect(money.added, isEmpty);
      expect(
        find.text(
          'Số cần trả vừa đổi thành ${_v(200000)}. Xem lại rồi bấm lần nữa nhé.',
        ),
        findsOneWidget,
      );
      expect(find.text('Vì sao là ${_v(200000)}'), findsOneWidget);
      // Second tap: same number on the server → written, the new amount.
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      expect(money.added.single.tx.amount, 200000);
      expect(money.added.single.tx.payer, 'her');
      expect(money.rechecks, 2);
    });

    testWidgets('the sign flipped / already even / offline: nothing written', (
      tester,
    ) async {
      final money = await openSettle(tester);
      // Both phones "Trả hết": the other one went first → even now.
      money.fresh = (balance: 0);
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      expect(money.added, isEmpty);
      expect(find.byType(SettleSheet), findsNothing);
      expect(
        find.text('Sổ chung đã cân bằng rồi, không cần thanh toán nữa.'),
        findsOneWidget,
      );

      // Reopen; the server can't be reached → no write, a note.
      await tester.pump(const Duration(seconds: 5));
      money.fresh = null;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      money.fresh = (balance: null);
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      expect(money.added, isEmpty);
      expect(
        find.text('Chưa lấy được số mới nhất. Có mạng rồi thử lại nhé.'),
        findsOneWidget,
      );

      // Flipped: now I owe her → shown, not written.
      money.fresh = (balance: -50000);
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      expect(money.added, isEmpty);
      expect(find.text('Mình trả lại cho Thảo'), findsOneWidget);
    });

    testWidgets('cached sums (stale): Save only fetches, never writes', (
      tester,
    ) async {
      _phone(tester);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(coupleNet: 359000)..netSumsStale = true,
        );
      await tester.pumpWidget(_app(money, _Opener(SettleSheet.show)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Đánh dấu đã thanh toán'), findsNothing);
      await tester.tap(find.text('Tải số mới nhất'));
      await tester.pumpAndSettle();
      expect(money.added, isEmpty);
      expect(money.rechecks, greaterThanOrEqualTo(1));
    });

    testWidgets('a typed part 100k; more than owed is refused', (tester) async {
      final money = await openSettle(tester, net: -170000);
      expect(find.text('Mình trả lại cho Thảo'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '200k');
      await tester.pump();
      expect(find.text('Tối đa ${_v(170000)}'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '100k');
      await tester.pump();
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      final r = money.added.single;
      expect(r.tx.amount, 100000);
      expect(r.tx.payer, 'me');
    });
    testWidgets('names from CoupleProvider (no scope): saving still writes', (
      tester,
    ) async {
      // Real app path: MoneyPeople.of reads CoupleProvider. Called from the
      // save tap it must not subscribe (provider asserts outside build and the
      // settle was silently never written — smoke 2026-10-22).
      _phone(tester);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(coupleNet: 359000),
        );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MoneyProvider>.value(value: money),
            ChangeNotifierProvider<CoupleProvider>(
              create: (_) => CoupleProvider(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: _Opener(SettleSheet.show)),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đánh dấu đã thanh toán'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(money.added.single.tx.amount, 359000);
    });
  });

  group('MoneyScreen entry points', () {
    testWidgets('shared: "Thanh toán" while uneven, "Góp vào quỹ" link', (
      tester,
    ) async {
      _phone(tester);
      final money = _Money()
        ..debugSetBooks(
          uid: 'me',
          own: _own(),
          shared: _shared(coupleNet: 359000, fund: 2000000),
        );
      await tester.pumpWidget(
        _app(money, const MoneyScreen(initialBook: MoneyBookKind.shared)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Thanh toán'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Góp vào quỹ'), 200);
      expect(find.text('Góp vào quỹ'), findsOneWidget);
    });

    testWidgets('even → no "Thanh toán"', (tester) async {
      _phone(tester);
      final money = _Money()
        ..debugSetBooks(uid: 'me', own: _own(), shared: _shared());
      await tester.pumpWidget(
        _app(money, const MoneyScreen(initialBook: MoneyBookKind.shared)),
      );
      await tester.pump();
      expect(find.text('Hai bên đang ngang nhau'), findsOneWidget);
      expect(find.text('Thanh toán'), findsNothing);
    });
  });

  group('Decision-wheel "Ghi chi" (D20)', () {
    test('active couple → shared, waiting → own; eat / go categories', () {
      expect(
        moneyDecisionPrefill(eat: true, coupleActive: true, hasShared: true),
        (book: MoneyBookKind.shared, categoryId: 'food_out'),
      );
      expect(
        moneyDecisionPrefill(eat: false, coupleActive: false, hasShared: false),
        (book: MoneyBookKind.own, categoryId: 'date_out'),
      );
      expect(
        moneyDecisionPrefill(
          eat: true,
          coupleActive: true,
          hasShared: false,
        ).book,
        MoneyBookKind.own,
      );
    });

    testWidgets('sheet prefilled: Ăn ngoài, note = the pick, source decision', (
      tester,
    ) async {
      _phone(tester);
      final money = _Money()
        ..debugSetBooks(uid: 'me', own: _own(), shared: _shared());
      await tester.pumpWidget(
        _app(
          money,
          _Opener(
            (c) => AddTransactionSheet.show(
              c,
              book: MoneyBookKind.shared,
              categoryId: 'food_out',
              note: 'Bún chả',
              source: 'decision',
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      for (final k in ['1', '2', '0', 'k']) {
        await tester.tap(find.text(k).last);
        await tester.pump();
      }
      await tester.tap(find.text('Lưu ${_v(120000)}'));
      await tester.pumpAndSettle();
      final r = money.added.single;
      expect(r.kind, MoneyBookKind.shared);
      expect(r.tx.categoryId, 'food_out');
      expect(r.tx.note, 'Bún chả');
      expect(r.tx.source, 'decision');
      expect(r.tx.date, _today);
    });
  });

  group('Nhắc tối 1210–1211 (D18)', () {
    test('slots: today + tomorrow; logged / too late → tomorrow only', () {
      final morning = DateTime(2026, 10, 20, 10);
      final both = ReminderService.moneyEveningSlots(
        now: morning,
        minuteOfDay: 21 * 60 + 30,
        loggedToday: false,
      );
      expect(both.map((s) => s.id), [1210, 1211]);
      expect(both.first.when, DateTime(2026, 10, 20, 21, 30));
      expect(both.last.when, DateTime(2026, 10, 21, 21, 30));
      expect(
        ReminderService.moneyEveningSlots(
          now: morning,
          minuteOfDay: 21 * 60 + 30,
          loggedToday: true,
        ).map((s) => s.id),
        [1211],
      );
      expect(
        ReminderService.moneyEveningSlots(
          now: DateTime(2026, 10, 20, 22),
          minuteOfDay: 21 * 60 + 30,
          loggedToday: false,
        ).map((s) => s.id),
        [1211],
      );
      // Three days in a row → all three lines.
      expect(
        {
          for (var d = 0; d < 3; d++)
            ReminderService.moneyEveningVariant(DateTime(2026, 10, 20 + d)),
        },
        {0, 1, 2},
      );
    });

    test('logged today in either book = an entry dated today by me', () {
      final mine = _contrib('a', 1, 'me').copyWith();
      expect(moneyLoggedToday([mine], 'me', _today), isFalse); // createdBy ''
      final t = MoneyTx(
        id: 'x',
        type: MoneyTxType.expense,
        amount: 1,
        date: _today,
        outWalletId: 'cash',
        createdBy: 'me',
      );
      expect(moneyLoggedToday([t], 'me', _today), isTrue);
      expect(moneyLoggedToday([t], 'her', _today), isFalse);
    });

    group('provider', () {
      setUpAll(() {
        Hive.init(Directory.systemTemp.createTempSync('money_evening').path);
      });

      test(
        'off by default; on → armed; logging drops 1210; off → gone',
        () async {
          final os = _FakeReminders();
          final p = ReminderProvider(service: os);
          expect(p.moneyEveningEnabled, isFalse);
          expect(p.moneyEveningTime, const TimeOfDay(hour: 21, minute: 30));

          await p.refreshMoneyEvening(loggedToday: false, l10n: l10n);
          expect(os.scheduled, isEmpty);
          expect(os.cancels, 1);

          await p.setMoneyEveningEnabled(true);
          final expected = ReminderService.moneyEveningSlots(
            now: DateTime.now(),
            minuteOfDay: 21 * 60 + 30,
            loggedToday: false,
          );
          final armed = os.scheduled.last;
          expect(armed.map((s) => s.id), expected.map((s) => s.id));
          final bodies = [
            l10n.moneyReminderBody1,
            l10n.moneyReminderBody2,
            l10n.moneyReminderBody3,
          ];
          for (var i = 0; i < armed.length; i++) {
            expect(armed[i].title, l10n.moneyTitle);
            expect(armed[i].body, bodies[expected[i].variant]);
          }

          await p.refreshMoneyEvening(loggedToday: true, l10n: l10n);
          expect(os.scheduled.last.map((s) => s.id), [1211]);

          // Same inputs again → debounced, no new call.
          final calls = os.scheduled.length;
          await p.refreshMoneyEvening(loggedToday: true, l10n: l10n);
          expect(os.scheduled.length, calls);

          final cancels = os.cancels;
          await p.setMoneyEveningEnabled(false);
          expect(os.cancels, cancels + 1);
          expect(os.scheduled.length, calls);
        },
      );
    });
  });

  group('money_* push + inbox → Sổ tiền, shared book', () {
    tearDown(() {
      NotificationTapRouter.consumeHomeTabRequest();
      NotificationTapRouter.consumeHomeFocusRequest();
      NotificationTapRouter.consumeMoneyRequest();
    });

    test('push route: Home + money focus (+ the fund for money_goal*)', () {
      for (final type in ['money_goal', 'money_goal_reached']) {
        expect(
          NotificationTapRouter.routeMoney(
            type,
            walletId: 'v_dalat',
            from: 'push',
          ),
          isTrue,
        );
        expect(NotificationTapRouter.pendingHomeTab.value, 0);
        expect(
          NotificationTapRouter.pendingHomeFocus.value,
          NotificationTapRouter.focusMoney,
        );
        expect(NotificationTapRouter.pendingMoney.value?.walletId, 'v_dalat');
      }
      NotificationTapRouter.routeMoney(
        'money_budget',
        walletId: 'ignored',
        from: 'inbox',
      );
      expect(NotificationTapRouter.pendingMoney.value?.walletId, isNull);
      expect(NotificationTapRouter.pendingMoney.value?.from, 'inbox');
      NotificationTapRouter.consumeMoneyRequest();
      expect(
        NotificationTapRouter.routeMoney('decision', from: 'push'),
        isFalse,
      );
      expect(NotificationTapRouter.pendingMoney.value, isNull);
    });

    test('inbox: the 3 types parse, open Home (0) and read like the push', () {
      final goal = AppNotification.fromDoc('n1', {
        'type': 'money_goal',
        'actorName': 'Thảo',
        'walletId': 'v_dalat',
        'percent': 40,
        'walletName': 'Quỹ Đà Lạt',
        'walletEmoji': '🏔️',
      });
      expect(goal.type, AppNotificationType.moneyGoal);
      expect(goal.targetHomeTab, 0);
      expect(goal.walletId, 'v_dalat');
      final g = moneyInboxText(goal, l10n)!;
      expect(g.title, 'Thảo vừa góp vào quỹ, giờ được 40%');
      expect(g.subtitle, '🏔️ Quỹ Đà Lạt');

      final full = AppNotification.fromDoc('n2', {
        'type': 'money_goal_reached',
        'walletName': 'Quỹ Đà Lạt',
        'walletEmoji': '🏔️',
      });
      expect(full.type, AppNotificationType.moneyGoalReached);
      expect(full.targetHomeTab, 0);
      expect(moneyInboxText(full, l10n)!.title, '🏔️ Quỹ Đà Lạt đủ rồi!');

      final budget = AppNotification.fromDoc('n3', {
        'type': 'money_budget',
        'month': '2026-10',
        'level': 100,
      });
      expect(budget.type, AppNotificationType.moneyBudget);
      expect(budget.targetHomeTab, 0);
      final b = moneyInboxText(budget, l10n)!;
      expect(b.title, 'Tháng này chúng mình tiêu hết ngân sách rồi');
      expect(b.subtitle, 'Sổ chung · 10/2026');
      // level arrives as a string in push data; the inbox doc has an int.
      expect(
        AppNotification.fromDoc('n4', {
          'type': 'money_budget',
          'level': '80',
        }).level,
        80,
      );
      // Not a money type → no money text.
      expect(
        moneyInboxText(
          AppNotification.fromDoc('n5', {'type': 'decision'}),
          l10n,
        ),
        isNull,
      );
    });
  });
}
