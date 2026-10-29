import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/providers/money_provider.dart';
import 'package:dear_embeiu/services/money_service.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/widgets/money/money_home_entry.dart';
import 'package:dear_embeiu/widgets/money/money_ui.dart';

// Sổ tiền: gap cases of project/features/expenses/test-cases.md that need a
// MoneyProvider wired to a counting service (AGG-*, MON-04/05, OFF-09,
// BAL-15, ED-08, FR-07/08/09, BK-07, LV-06/07, TX-15). The service is a
// `Fake implements MoneyService`: no Firestore, every read is counted.

// ignore: subtype_of_sealed_class
class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.path);
  @override
  final String path;
}

int _ids0 = 0;

// ignore: subtype_of_sealed_class
class _RealDoc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _RealDoc(this.id);
  @override
  final String id;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _RealCol();
}

// ignore: subtype_of_sealed_class
class _RealCol extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _RealDoc(path ?? 'gen${_ids0++}');
}

class _Db extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _RealCol();
}

class _Batch extends Fake implements WriteBatch {
  final List<Map<String, dynamic>> updates = [];
  @override
  void update(DocumentReference document, Map<Object, Object?> data) =>
      updates.add({for (final e in data.entries) '${e.key}': e.value});
}

class _Svc extends Fake implements MoneyService {
  _Svc(this.kind, [this.memberUids = const <String>[]]);

  @override
  final MoneyBookKind kind;
  @override
  final List<String> memberUids;
  @override
  bool get isShared => kind == MoneyBookKind.shared;
  @override
  DocumentReference<Map<String, dynamic>> get book => _Doc('books/$kind');

  final List<StreamController<({List<MoneyWallet> wallets, bool fromServer})>>
  walletStreams = [];
  final List<StreamController<({List<MoneyTx> txs, bool fromServer})>>
  txStreams = [];
  int netSumCalls = 0;
  bool offline = false;
  Map<String, int> nextNet = const {'cash': 0};
  final List<List<MoneyWallet>> created = [];
  Object? createError;
  Object? commitError;
  Completer<void>? gate;
  int _ids = 0;

  @override
  Stream<({List<MoneyWallet> wallets, bool fromServer})> watchWallets() {
    final c = StreamController<({List<MoneyWallet> wallets, bool fromServer})>(
      sync: true,
    );
    walletStreams.add(c);
    return c.stream;
  }

  @override
  Stream<({List<MoneyTx> txs, bool fromServer})> watchTx({
    String? from,
    String? to,
  }) {
    final c = StreamController<({List<MoneyTx> txs, bool fromServer})>(
      sync: true,
    );
    txStreams.add(c);
    return c.stream;
  }

  @override
  Stream<List<MoneyBudget>> watchBudgets() => const Stream.empty();
  @override
  Stream<List<MoneyChallenge>> watchChallenges() => const Stream.empty();
  @override
  Stream<MoneyMeta> watchMeta() => const Stream.empty();
  @override
  Future<bool> hasAnyTx() async => false;

  @override
  Future<Map<String, int>> walletNetSums(Iterable<String> walletIds) async {
    netSumCalls++;
    if (offline) throw StateError('offline');
    return nextNet;
  }

  @override
  String newTxId() => 'tx${_ids++}';
  @override
  String newWalletId() => 'w${_ids++}';

  @override
  MoneyBatchOp createTxOp(MoneyTx tx, {required String uid}) => (b) {};

  @override
  Future<MoneyWriteOutcome> createWallets(
    List<MoneyWallet> wallets, {
    required String uid,
  }) async {
    created.add(wallets);
    if (createError != null) throw createError!;
    return MoneyWriteOutcome.saved;
  }

  @override
  Future<MoneyWriteOutcome> commit(
    List<MoneyBatchOp> ops, {
    required String docId,
    void Function(MoneyWriteError error)? onLateError,
    void Function(Object? error)? onDone,
  }) async {
    await gate?.future;
    final err = commitError;
    if (err != null) {
      onDone?.call(err);
      throw err;
    }
    onDone?.call(null);
    return MoneyWriteOutcome.saved;
  }

  void emitWallets(List<MoneyWallet> w, {bool fromServer = true}) {
    for (final c in walletStreams) {
      if (!c.isClosed && c.hasListener) {
        c.add((wallets: w, fromServer: fromServer));
      }
    }
  }

  /// Emits on the LATEST tx subscription only (the older ones are cancelled).
  void emitTx([List<MoneyTx> t = const []]) =>
      txStreams.last.add((txs: t, fromServer: true));
}

const _cash = MoneyWallet(
  id: 'cash',
  name: 'Tiền mặt',
  type: MoneyWalletType.cash,
  emoji: '💵',
);

MoneyBookState _state(_Svc svc, {List<MoneyWallet> wallets = const [_cash]}) {
  final s = MoneyBookState(svc)..wallets = wallets;
  s.walletsFromServer = true;
  s.everLogged = true;
  return s;
}

class _Rig {
  _Rig({bool shared = false}) {
    own = _Svc(MoneyBookKind.own);
    p = MoneyProvider(clock: () => now);
    sOwn = _state(own);
    if (shared) {
      sh = _Svc(MoneyBookKind.shared, const ['me', 'her']);
      sSh = _state(sh!, wallets: const []);
    }
    p.debugSetBooks(uid: 'me', own: sOwn, shared: sSh);
  }

  DateTime now = DateTime(2026, 10, 23, 12);
  late final _Svc own;
  _Svc? sh;
  late final MoneyProvider p;
  late final MoneyBookState sOwn;
  MoneyBookState? sSh;

  /// Attaches the (fake) listeners and lets the first reads settle, so a test
  /// counts only what happens after.
  Future<void> attach(WidgetTester t, {bool shared = false}) async {
    p.retry(MoneyBookKind.own);
    if (shared) p.retry(MoneyBookKind.shared);
    own.emitWallets(const [_cash]);
    own.emitTx();
    sh?.emitTx();
    await t.pump(const Duration(seconds: 2));
  }

  Future<void> wait(WidgetTester t, [int ms = 5000]) =>
      t.pump(Duration(milliseconds: ms));
}

void _rig(String name, Future<void> Function(WidgetTester, _Rig) body) =>
    testWidgets(name, (t) async {
      final r = _Rig();
      try {
        await body(t, r);
      } finally {
        r.p.dispose();
      }
    });

void _rigShared(String name, Future<void> Function(WidgetTester, _Rig) body) =>
    testWidgets(name, (t) async {
      final r = _Rig(shared: true);
      try {
        await body(t, r);
      } finally {
        r.p.dispose();
      }
    });

void main() {
  setUpAll(() async {
    // The sums cache lives in Hive; a real (temp) box keeps it quiet.
    final dir = Directory.systemTemp.createTempSync('money_gap_hive');
    Hive.init(dir.path);
    await Hive.openBox<String>('money_cache');
    // No Hive.close(): writes queued under a test's fake clock never finish
    // and would hang it. The temp dir goes with the OS.
  });
  setUp(() => AppL10n.setLocale(const Locale('vi')));

  group('aggregate loop (2b4d289)', () {
    _rigShared('AGG-01: refreshDay on the same day reads nothing again', (
      t,
      r,
    ) async {
      await r.attach(t, shared: true);
      final net = r.own.netSumCalls, sharedNet = r.sh!.netSumCalls;
      final subs = r.own.txStreams.length + r.sh!.txStreams.length;

      // Home calls it after EVERY build; the old code scheduled the sums
      // each time, the sums notified, Home rebuilt: ~1 loop a second.
      for (var i = 0; i < 50; i++) {
        r.p.refreshDay();
        await r.wait(t, 200);
      }
      await r.wait(t, 1000); // the debounce (600 ms) would have fired by now
      expect(r.own.netSumCalls, net, reason: 'no aggregate for the own book');
      expect(r.sh!.netSumCalls, sharedNet, reason: 'nor for the shared book');
      expect(
        r.own.txStreams.length + r.sh!.txStreams.length,
        subs,
        reason: 'no re-subscribe either',
      );
    });

    _rig('AGG-01: a Home-style rebuild loop stays at zero reads', (t, r) async {
      await r.attach(t);
      final net = r.own.netSumCalls;
      // refreshDay → (old code) sums → notify → listener → refreshDay …
      var rebuilds = 0;
      void onChange() {
        rebuilds++;
        if (rebuilds < 200) r.p.refreshDay();
      }

      r.p.addListener(onChange);
      r.p.refreshDay();
      await r.wait(t, 10000);
      r.p.removeListener(onChange);
      expect(r.own.netSumCalls, net);
      expect(rebuilds, lessThan(5), reason: 'refreshDay must not notify');
    });

    _rigShared('AGG-01: the real Home row (rebuilt on every notify, calls '
        'refreshDay each build) settles at zero reads', (t, r) async {
      await r.attach(t, shared: true);
      await t.pumpWidget(
        ChangeNotifierProvider<MoneyProvider>.value(
          value: r.p,
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MoneyPeopleScope(
              people: const MoneyPeople(myName: 'Tuấn', partnerName: 'Thảo'),
              child: child!,
            ),
            home: const Scaffold(body: MoneyHomeEntry(waiting: false)),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 2)); // first build + its reads
      final net = r.own.netSumCalls, sharedNet = r.sh!.netSumCalls;
      final subs = r.own.txStreams.length + r.sh!.txStreams.length;
      for (var i = 0; i < 100; i++) {
        await t.pump(const Duration(milliseconds: 100)); // 10 s of Home
      }
      expect(r.own.netSumCalls, net, reason: 'no balance reads while idle');
      expect(r.sh!.netSumCalls, sharedNet);
      expect(r.own.txStreams.length + r.sh!.txStreams.length, subs);
    });

    _rigShared('AGG-02: onResume re-reads each book exactly once', (
      t,
      r,
    ) async {
      await r.attach(t, shared: true);
      final net = r.own.netSumCalls, sharedNet = r.sh!.netSumCalls;

      r.p.onResume();
      r.p.onResume(); // two resumes inside the debounce → still one read
      await r.wait(t, 700);
      expect(r.own.netSumCalls, net + 1);
      expect(r.sh!.netSumCalls, sharedNet + 1, reason: 'shared book, once');
      await r.wait(t); // and then quiet
      expect(r.own.netSumCalls, net + 1);
      expect(r.sh!.netSumCalls, sharedNet + 1);
    });

    _rig('AGG-03 / MON-05: past midnight the window moves, one re-read, '
        'then quiet', (t, r) async {
      r.now = DateTime(2026, 10, 23, 23, 59);
      await r.attach(t);
      final before = r.sOwn.windowFrom;
      final net = r.own.netSumCalls, subs = r.own.txStreams.length;

      r.p.refreshDay(); // still the same day
      expect(r.own.txStreams.length, subs);

      r.now = DateTime(2026, 10, 24, 0, 1);
      r.p.refreshDay();
      expect(r.sOwn.windowFrom, isNot(before));
      expect(r.sOwn.windowFrom, '2026-09-10');
      expect(r.own.txStreams.length, subs + 1, reason: 'new window listener');
      r.own.emitTx(); // the new listener fires once
      await r.wait(t, 700);
      expect(r.own.netSumCalls, net + 1, reason: 're-read exactly once');

      for (var i = 0; i < 10; i++) {
        r.p.refreshDay();
      }
      await r.wait(t);
      expect(r.own.netSumCalls, net + 1, reason: 'and then it stays quiet');
      expect(r.own.txStreams.length, subs + 1);
    });

    _rig('AGG-04: five snapshots in a second are one read', (t, r) async {
      await r.attach(t);
      final net = r.own.netSumCalls;
      for (var i = 0; i < 5; i++) {
        r.own.emitTx();
        await t.pump(const Duration(milliseconds: 150));
      }
      await r.wait(t, 700);
      expect(r.own.netSumCalls, net + 1);
    });

    _rig('AGG-05: retry resubscribes and reads the sums once', (t, r) async {
      await r.attach(t);
      final net = r.own.netSumCalls, subs = r.own.txStreams.length;
      r.sOwn.loadError = StateError('boom');

      r.p.retry(MoneyBookKind.own);
      await t.pump();
      expect(r.sOwn.loadError, isNull);
      expect(r.own.txStreams.length, subs + 1);
      expect(r.own.netSumCalls, net + 1);
      await r.wait(t);
      expect(r.own.netSumCalls, net + 1);
    });

    _rig('OFF-09: after the network is back the sums are re-read '
        'once, not in a loop', (t, r) async {
      await r.attach(t);
      r.own.offline = true;
      r.p.onResume();
      await r.wait(t, 700);
      expect(r.sOwn.netSumsStale, isTrue, reason: 'offline keeps the cache');

      r.own.offline = false;
      r.own.nextNet = const {'cash': 5000};
      final net = r.own.netSumCalls;
      r.p.onResume();
      await r.wait(t);
      expect(r.own.netSumCalls, net + 1);
      expect(r.sOwn.netSumsStale, isFalse);
      expect(r.p.balances(MoneyBookKind.own)['cash'], 5000);
    });

    test('MON-04: live window starts ≥ 44 days back and never after '
        'the 1st of this month', () async {
      for (final day in [
        DateTime(2026, 10, 23),
        DateTime(2026, 3, 31),
        DateTime(2026, 1, 5),
        DateTime(2026, 12, 31),
        DateTime(2028, 3, 1),
      ]) {
        final r = _Rig();
        r.now = day;
        r.p.retry(MoneyBookKind.own);
        final from = r.sOwn.windowFrom!;
        await pumpEventQueue();
        final minus44 = MoneyMath.dateKey(
          day.subtract(const Duration(days: 44)),
        );
        expect(from.compareTo(minus44), lessThanOrEqualTo(0), reason: '$day');
        expect(
          from.compareTo('${MoneyMath.monthKey(day)}-01'),
          lessThanOrEqualTo(0),
          reason: '$day',
        );
        r.p.dispose();
      }
    });
  });

  group('two phones', () {
    test('ED-08: the edit writes editCount as old+1 (absolute), so the '
        'second of two edits from one version is refused by the rules', () {
      final svc = MoneyService.shared('c1', const [
        'me',
        'her',
      ], firestore: _Db());
      const old = MoneyTx(
        id: 't1',
        type: MoneyTxType.expense,
        amount: 100000,
        date: '2026-10-20',
        outWalletId: '',
        inWalletId: '',
        categoryId: 'food_out',
        payer: 'me',
        memberUids: ['me', 'her'],
        createdBy: 'me',
        editCount: 3,
      );
      final b = _Batch();
      svc.updateTxOp(old, old.copyWith(amount: 120000), uid: 'her')(b);
      expect(b.updates.single['editCount'], 4);
      expect(b.updates.single['updatedBy'], 'her');
      expect(b.updates.single['amount'], 120000);
      // Same starting version → same absolute number, never an increment.
      final b2 = _Batch();
      svc.updateTxOp(old, old.copyWith(amount: 130000), uid: 'me')(b2);
      expect(b2.updates.single['editCount'], 4);
    });
  });

  group('first run & default wallets', () {
    test('FR-04 / BK-07: skipping makes only the cash wallet, id `cash`, '
        'balance 0', () async {
      final r = _Rig();
      addTearDown(r.p.dispose);
      r.sOwn.wallets = const [];
      await r.p.ensureDefaultWallet(MoneyBookKind.own);
      final w = r.own.created.single.single;
      expect(w.id, 'cash');
      expect(w.name, 'Tiền mặt');
      expect(w.type, MoneyWalletType.cash);
      expect(w.openingBalance, 0);
      expect(r.p.defaultWalletId(MoneyBookKind.own), 'cash');
    });

    test('FR-02: the starter balance goes on cash; extra wallets keep theirs '
        'and get pinned to the book', () async {
      final r = _Rig();
      addTearDown(r.p.dispose);
      r.sOwn.wallets = const [];
      await r.p.ensureDefaultWallet(
        MoneyBookKind.own,
        starterBalance: 700000,
        extra: const [
          MoneyWallet(
            id: '',
            name: 'MoMo',
            type: MoneyWalletType.ewallet,
            openingBalance: 1500000,
          ),
        ],
      );
      final made = r.own.created.single;
      expect(made.map((w) => w.name), ['Tiền mặt', 'MoMo']);
      expect(made[0].openingBalance, 700000);
      expect(made[1].openingBalance, 1500000);
      expect(made[1].id, isNotEmpty, reason: 'service picks an id');
    });

    test('FR-08 / BK-07 / LV-07: shared starter is `joint_<8>_<8>`, made '
        'once; a new pair gets a new id', () async {
      final r = _Rig(shared: true);
      addTearDown(r.p.dispose);
      final id = r.p.defaultWalletId(MoneyBookKind.shared);
      expect(id, 'joint_me_her');
      await r.p.ensureDefaultWallet(MoneyBookKind.shared);
      final w = r.sh!.created.single.single;
      expect(w.id, id);
      expect(w.name, 'Ví chung');
      expect(w.memberUids, ['me', 'her']);

      // Now it exists: a second call writes nothing.
      r.sSh!.wallets = [w];
      await r.p.ensureDefaultWallet(MoneyBookKind.shared);
      expect(r.sh!.created, hasLength(1));

      // Long uids are cut at 8 chars; a different partner → a different id.
      final other = _Svc(MoneyBookKind.shared, const [
        'abcdefghijkl',
        'zyxwvutsrq',
      ]);
      r.p.debugSetBooks(
        uid: 'abcdefghijkl',
        own: r.sOwn,
        shared: _state(other),
      );
      expect(
        r.p.defaultWalletId(MoneyBookKind.shared),
        'joint_abcdefgh_zyxwvuts',
      );
      expect(r.p.defaultWalletId(MoneyBookKind.shared), isNot(id));
    });

    test(
      'FR-07: a second phone racing (permission-denied) is swallowed',
      () async {
        final r = _Rig();
        addTearDown(r.p.dispose);
        r.sOwn.wallets = const [];
        r.own.createError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
        await r.p.ensureDefaultWallet(MoneyBookKind.own); // must not throw
        expect(r.own.created, hasLength(1));
        expect(r.p.lastWriteError, isNull, reason: 'no error shown');
      },
    );

    test('FR-09: an empty wallet list from the cache is NOT first run', () {
      final r = _Rig();
      addTearDown(r.p.dispose);
      r.sOwn
        ..wallets = const []
        ..walletsFromServer = false;
      expect(r.p.needsFirstRun, isFalse);
      r.sOwn.walletsFromServer = true;
      expect(r.p.needsFirstRun, isTrue);
      r.sOwn.wallets = const [_cash];
      expect(r.p.needsFirstRun, isFalse);
    });
  });

  group('leaving / failing', () {
    test(
      'LV-06: clearShared drops the shared book, its writes and deletes',
      () {
        final r = _Rig(shared: true);
        addTearDown(r.p.dispose);
        expect(r.p.hasShared, isTrue);
        var notified = 0;
        r.p.addListener(() => notified++);
        r.p.clearShared();
        expect(r.p.hasShared, isFalse);
        expect(r.p.shared, isNull);
        expect(r.p.own, isNotNull, reason: 'the own book stays');
        expect(r.p.visibleTxs(MoneyBookKind.shared), isEmpty);
        expect(r.p.balances(MoneyBookKind.shared), isEmpty);
        expect(notified, 1);
      },
    );

    test('BK-10: clear(signedOut) forgets both books and the uid', () {
      final r = _Rig(shared: true);
      addTearDown(r.p.dispose);
      r.p.clear(signedOut: true);
      expect(r.p.own, isNull);
      expect(r.p.shared, isNull);
      expect(r.p.uid, isNull);
      expect(r.p.lastWriteError, isNull);
    });

    _rig('TX-15: a refused write throws and is rolled back from the '
        'balances', (t, r) async {
      r.sOwn.netSumsAt = DateTime(2026, 10, 23);
      expect(r.p.balances(MoneyBookKind.own)['cash'], 0);
      r.own.commitError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      const draft = MoneyTx(
        id: '',
        type: MoneyTxType.expense,
        amount: 50000,
        date: '2026-10-23',
        outWalletId: 'cash',
        categoryId: 'food_out',
      );
      await expectLater(
        r.p.addTx(MoneyBookKind.own, draft),
        throwsA(isA<FirebaseException>()),
      );
      await t.pump();
      expect(
        r.p.balances(MoneyBookKind.own)['cash'],
        0,
        reason: 'the refused entry must not stay in the balance',
      );
    });

    _rig('TX-15: an accepted write moves the balance at once, then the '
        'server sum takes over', (t, r) async {
      r.sOwn.netSumsAt = DateTime(2026, 10, 23);
      r.own.gate = Completer<void>();
      final f = r.p.addTx(
        MoneyBookKind.own,
        const MoneyTx(
          id: '',
          type: MoneyTxType.expense,
          amount: 50000,
          date: '2026-10-23',
          outWalletId: 'cash',
          categoryId: 'food_out',
        ),
      );
      expect(r.p.balances(MoneyBookKind.own)['cash'], -50000);
      r.own.gate!.complete();
      expect(await f, MoneyWriteOutcome.saved);
      r.own.nextNet = const {'cash': -50000};
      await r.wait(t, 700);
      expect(
        r.p.balances(MoneyBookKind.own)['cash'],
        -50000,
        reason: 'not counted twice once the sum includes it',
      );
    });
  });
}
