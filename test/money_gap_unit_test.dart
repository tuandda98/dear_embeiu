import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dear_embeiu/data/money_categories.dart';
import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/money.dart';
import 'package:dear_embeiu/providers/money_provider.dart';
import 'package:dear_embeiu/services/analytics_service.dart';
import 'package:dear_embeiu/services/money_analytics.dart';
import 'package:dear_embeiu/services/money_service.dart';
import 'package:dear_embeiu/utils/money_flows.dart';
import 'package:dear_embeiu/utils/money_math.dart';
import 'package:dear_embeiu/utils/money_views.dart';
import 'package:dear_embeiu/widgets/money/add_transaction_sheet.dart';

// Sổ tiền: pure / near-pure gap cases of
// project/features/expenses/test-cases.md (CAT-10..13, WAL-10..15, I18N-01,
// I18N-06, GOAL-05/13, MON-06, ED-19, BUD-18, AM-13/15, AN-01..07).

// ── Firestore stand-ins (only `collection().doc()` paths are touched) ──────

// ignore: subtype_of_sealed_class
class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Col();
}

// ignore: subtype_of_sealed_class
class _Col extends Fake implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Doc();
}

class _Db extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Col();
}

MoneyBookState _book() =>
    MoneyBookState(MoneyService.own('me', firestore: _Db()));

AppLocalizations _l(String lang) => lookupAppLocalizations(Locale(lang));

MoneyWallet _w(
  String id,
  String name, [
  MoneyWalletType t = MoneyWalletType.cash,
]) => MoneyWallet(id: id, name: name, type: t);

/// Captures what an extension method sends to `logEvent`.
class _Capture extends Fake implements AnalyticsService {
  final List<({String name, Map<String, Object?> params})> events = [];
  @override
  void logEvent(String name, {Map<String, Object?>? params}) =>
      events.add((name: name, params: params ?? const {}));
}

String get _src => 'lib';
String _read(String path) => File('$_src/$path').readAsStringSync();

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('money_gap_unit_hive');
    Hive.init(dir.path);
    await Hive.openBox<String>('app_settings');
  });
  setUp(() => AppL10n.setLocale(const Locale('vi')));

  group('categories follow the language (b7e0e88)', () {
    test('CAT-10 / I18N-06: a table built while AppL10n was English is '
        'rebuilt in Vietnamese after setLocale(vi)', () {
      AppL10n.setLocale(const Locale('en')); // MaterialApp not resolved yet
      final s = _book();
      expect(s.categories.of('food_coffee').name, _l('en').moneyCatFoodCoffee);
      expect(s.categories.of('food_coffee').name, isNot('Cà phê, trà sữa'));

      AppL10n.setLocale(const Locale('vi'));
      expect(s.categories.of('food_coffee').name, 'Cà phê, trà sữa');
      expect(s.categories.of('other').name, 'Khác');

      AppL10n.setLocale(const Locale('en'));
      expect(s.categories.of('other').name, 'Other');
    });

    test('CAT-10: same language + same meta = the cached index; new meta '
        'rebuilds it', () {
      final s = _book();
      final a = s.categories;
      expect(identical(s.categories, a), isTrue);
      s.meta = const MoneyMeta(hiddenCategoryIds: {'food_snack'});
      final b = s.categories;
      expect(identical(b, a), isFalse);
      expect(b.of('food_snack').isHidden, isTrue);
    });

    test('CAT-11: a category the user typed is never translated', () {
      final meta = MoneyMeta(
        customCategories: const [
          MoneyCustomCategory(
            id: 'c1',
            kind: MoneyTxType.expense,
            name: 'Cầu lông',
            parentId: 'health',
            emoji: '🏸',
          ),
        ],
      );
      for (final lang in ['vi', 'en']) {
        final idx = MoneyCategoryIndex(resolveMoneyCategories(meta, _l(lang)));
        final c = idx.of('c1');
        expect(c.name, 'Cầu lông', reason: lang);
        expect(c.isCustom, isTrue);
      }
    });

    test('CAT-12: a renamed default keeps the user\'s name in both languages; '
        'the original follows the language', () {
      const meta = MoneyMeta(
        overrides: {'food_coffee': (name: 'Cafe Highlands', emoji: '')},
      );
      final vi = MoneyCategoryIndex(
        resolveMoneyCategories(meta, _l('vi')),
      ).of('food_coffee');
      final en = MoneyCategoryIndex(
        resolveMoneyCategories(meta, _l('en')),
      ).of('food_coffee');
      expect(vi.name, 'Cafe Highlands');
      expect(en.name, 'Cafe Highlands');
      expect(vi.originalName, 'Cà phê, trà sữa');
      expect(en.originalName, _l('en').moneyCatFoodCoffee);
      // An override with a blank name does not blank the category.
      const blank = MoneyMeta(
        overrides: {'food_coffee': (name: '  ', emoji: '☕')},
      );
      final b = MoneyCategoryIndex(
        resolveMoneyCategories(blank, _l('vi')),
      ).of('food_coffee');
      expect(b.name, 'Cà phê, trà sữa');
      expect(b.originalName, isNull);
    });

    test('CAT-13 / CAT-06: an unknown or deleted id shows "Khác"', () {
      final idx = MoneyCategoryIndex(
        resolveMoneyCategories(MoneyMeta.empty, _l('vi')),
      );
      expect(idx.of('nope').name, 'Khác');
      expect(idx.groupOf('nope'), kMoneyCategoryOther);
      // A custom category that was deleted: same fallback.
      final withC = MoneyCategoryIndex(
        resolveMoneyCategories(
          const MoneyMeta(
            customCategories: [
              MoneyCustomCategory(
                id: 'c9',
                kind: MoneyTxType.expense,
                name: 'Tạm',
              ),
            ],
          ),
          _l('vi'),
        ),
      );
      expect(withC.of('c9').name, 'Tạm');
      expect(idx.of('c9').name, 'Khác');
    });

    test('BUD-18: a budget follows the category id, not its name', () {
      const budget = MoneyBudget(
        id: 'food',
        categoryId: 'food',
        amount: 1000000,
      );
      final txs = [
        const MoneyTx(
          id: 'a',
          type: MoneyTxType.expense,
          amount: 400000,
          date: '2026-10-05',
          outWalletId: 'cash',
          categoryId: 'food_out',
        ),
      ];
      List<(MoneyBudget, MoneyBudgetStatus)> rows(MoneyMeta meta) {
        final idx = MoneyCategoryIndex(resolveMoneyCategories(meta, _l('vi')));
        return MoneyViews.categoryBudgets(
          [budget],
          txs,
          '2026-10',
          groupOf: idx.groupOf,
        );
      }

      final before = rows(MoneyMeta.empty).single.$2;
      final after = rows(
        const MoneyMeta(
          overrides: {'food': (name: 'Ăn ngoài + nhà', emoji: '🍱')},
          hiddenCategoryIds: {'food_snack'},
        ),
      ).single.$2;
      expect(before.percent, 40);
      expect(after.percent, 40);
      expect(after.spent, before.spent);
    });
  });

  group('wallets follow the language (b7e0e88)', () {
    test(
      'WAL-10: wallets the user named keep their name in every language',
      () {
        final s = _book()
          ..wallets = [
            _w('a', 'Techcombank', MoneyWalletType.bank),
            _w('b', 'Cash của Tuấn'),
          ];
        for (final lang in ['en', 'vi']) {
          AppL10n.setLocale(Locale(lang));
          expect(s.wallets.map((w) => w.name), [
            'Techcombank',
            'Cash của Tuấn',
          ]);
        }
      },
    );

    test('WAL-11: a starter wallet shows translated but the stored list is '
        'untouched', () {
      final raw = [_w('cash', 'Cash')];
      final s = _book()..wallets = raw;
      AppL10n.setLocale(const Locale('vi'));
      expect(s.wallets.single.name, 'Tiền mặt');
      AppL10n.setLocale(const Locale('en'));
      expect(s.wallets.single.name, 'Cash');
      // What would be written back / read by the sums is still the source.
      expect(raw.single.name, 'Cash');
      expect(s.wallets.single.id, 'cash');
      // Vietnamese-made starter wallet in an English phone.
      s.wallets = [_w('cash', 'Tiền mặt'), _w('j', 'Ví chung')];
      expect(s.wallets.map((w) => w.name), ['Cash', 'Shared wallet']);
    });

    test('WAL-13: a name that equals a starter name is shown in the current '
        'language (accepted behaviour)', () {
      final s = _book()..wallets = [_w('x', 'Ngân hàng', MoneyWalletType.bank)];
      AppL10n.setLocale(const Locale('en'));
      expect(s.wallets.single.name, 'Bank');
      AppL10n.setLocale(const Locale('vi'));
      expect(s.wallets.single.name, 'Ngân hàng');
      final c = _book()
        ..wallets = [_w('c', 'Credit card', MoneyWalletType.credit)];
      expect(c.wallets.single.name, 'Thẻ tín dụng');
    });

    test('WAL-14: withName keeps every other field', () {
      final w = MoneyWallet(
        id: 'g',
        name: 'Quỹ Đà Lạt',
        type: MoneyWalletType.goal,
        emoji: '🏝️',
        color: 'rose',
        openingBalance: 123,
        includeInTotal: false,
        archived: true,
        order: 7,
        goalTarget: 5000000,
        goalDeadline: '2027-01-01',
        goalReachedAt: DateTime(2026, 10, 1),
        memberUids: const ['a', 'b'],
        createdBy: 'a',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 2),
      );
      final r = w.withName('X');
      expect(r.name, 'X');
      expect(r.id, w.id);
      expect(r.type, w.type);
      expect(r.emoji, w.emoji);
      expect(r.color, w.color);
      expect(r.openingBalance, 123);
      expect(r.includeInTotal, isFalse);
      expect(r.archived, isTrue);
      expect(r.order, 7);
      expect(r.goalTarget, 5000000);
      expect(r.goalDeadline, '2027-01-01');
      expect(r.goalReachedAt, w.goalReachedAt);
      expect(r.memberUids, ['a', 'b']);
      expect(r.createdBy, 'a');
      expect(r.createdAt, w.createdAt);
      expect(r.updatedAt, w.updatedAt);
    });

    test('WAL-15: same language → same cached list; assigning or switching '
        'language rebuilds', () {
      final s = _book()..wallets = [_w('cash', 'Cash')];
      final a = s.wallets;
      expect(identical(s.wallets, a), isTrue);
      s.wallets = [_w('cash', 'Cash')];
      final b = s.wallets;
      expect(identical(b, a), isFalse);
      expect(identical(s.wallets, b), isTrue);
      AppL10n.setLocale(const Locale('en'));
      expect(identical(s.wallets, b), isFalse);
      expect(s.wallets.single.name, 'Cash');
    });

    test('WAL-12: the stored name is only changed by an edit; once the user '
        'saves a new name it is no longer translated', () {
      // The edit sheet writes the name it shows; after that the stored name
      // is the user's own and is matched by no starter name.
      final s = _book()..wallets = [_w('cash', 'Ví của Tuấn')];
      AppL10n.setLocale(const Locale('en'));
      expect(s.wallets.single.name, 'Ví của Tuấn');
      AppL10n.setLocale(const Locale('vi'));
      expect(s.wallets.single.name, 'Ví của Tuấn');
    });
  });

  group('math & goals', () {
    test('GOAL-05: "Quy Nhơn" is a place, not "Quỹ Nhơn"; the Quỹ / Fund '
        'prefix still goes', () {
      expect(moneyTripName('Quy Nhơn'), 'Quy Nhơn');
      expect(moneyTripName('Quỹ Đà Lạt'), 'Đà Lạt');
      expect(moneyTripName('quỹ  Phú Quốc'), 'Phú Quốc');
      expect(moneyTripName('Fund Sapa'), 'Sapa');
      expect(moneyTripName('Dalat fund'), 'Dalat');
      expect(moneyTripName('Quỹ'), 'Quỹ');
    });

    test('GOAL-13: a deadline in the past never gives a negative or huge '
        '"mỗi tháng"', () {
      expect(MoneyMath.monthsUntil('2026-10-23', '2026-08-01'), 1);
      expect(
        MoneyMath.perMonthNeeded(2500000, '2026-10-23', '2026-08-01'),
        2500000,
      );
      expect(MoneyMath.perMonthNeeded(1, '2026-10-23', '2020-01-01'), 1000);
      expect(MoneyMath.perMonthNeeded(0, '2026-10-23', '2026-08-01'), 0);
      expect(MoneyMath.perMonthNeeded(-5, '2026-10-23', '2026-08-01'), 0);
      final w = MoneyWallet(
        id: 'g',
        name: 'Quỹ',
        type: MoneyWalletType.goal,
        goalTarget: 5000000,
        goalDeadline: '2026-01-01',
      );
      final v = MoneyGoalView.of(w, 1000000, '2026-10-23');
      expect(v.perMonth, 4000000);
      expect(v.left, 4000000);
      expect(v.perMonth, greaterThanOrEqualTo(0));
    });

    test('MON-06: the 1st and the last day each land in their own month', () {
      MoneyTx e(String id, String d, int a) => MoneyTx(
        id: id,
        type: MoneyTxType.expense,
        amount: a,
        date: d,
        outWalletId: 'cash',
      );
      final txs = [
        e('a', '2026-09-30', 10),
        e('b', '2026-10-01', 20),
        e('c', '2026-10-31', 40),
        e('d', '2026-11-01', 80),
        e('f', '2028-02-29', 160),
      ];
      expect(MoneyMath.monthTotals(txs, '2026-09').expense, 10);
      expect(MoneyMath.monthTotals(txs, '2026-10').expense, 60);
      expect(MoneyMath.monthTotals(txs, '2026-11').expense, 80);
      expect(MoneyMath.monthTotals(txs, '2028-02').expense, 160);
      expect(MoneyMath.monthRange('2028-02'), ('2028-02-01', '2028-02-29'));
    });

    test(
      'ED-19 / TX-08: moving an entry to another month moves the totals',
      () {
        const sep = MoneyTx(
          id: 't',
          type: MoneyTxType.expense,
          amount: 300000,
          date: '2026-09-28',
          outWalletId: 'cash',
        );
        final oct = sep.copyWith(date: '2026-10-02');
        expect(MoneyMath.monthTotals([sep], '2026-09').expense, 300000);
        expect(MoneyMath.monthTotals([sep], '2026-10').expense, 0);
        expect(MoneyMath.monthTotals([oct], '2026-09').expense, 0);
        expect(MoneyMath.monthTotals([oct], '2026-10').expense, 300000);
        // The wallet balance does not care which month.
        expect(sep.deltaFor('cash'), oct.deltaFor('cash'));
      },
    );
  });

  group('MoneyAmountInput', () {
    test('AM-13: a comma is accepted once and never after a unit', () {
      final i = MoneyAmountInput();
      i.press('1');
      i.press(',');
      i.press(',');
      expect(i.raw, '1,');
      i.press('5');
      i.press(',');
      expect(i.raw, '1,5');
      i.press('tr');
      i.press(',');
      expect(i.raw, '1,5tr');
      expect(i.parsed.value, 1500000);
      // A leading comma is ignored.
      final j = MoneyAmountInput()..press(',');
      expect(j.raw, '');
    });

    test('AM-15: at most 16 characters', () {
      final i = MoneyAmountInput();
      for (var n = 0; n < 30; n++) {
        i.press('9');
      }
      expect(i.raw.length, MoneyAmountInput.maxLength);
      expect(MoneyAmountInput.maxLength, 16);
      i.press('000'); // a 3-char key that no longer fits
      expect(i.raw.length, 16);
      final k = MoneyAmountInput('12345678901234');
      k.press('000'); // 14 + 3 > 16
      expect(k.raw, '12345678901234');
      k.press('5');
      expect(k.raw, '123456789012345');
    });
  });

  group('source checks', () {
    test('LV-01: every shared read is filtered by the CURRENT pair '
        '(`_pair`), so an old pair\'s entries never show', () {
      final src = _read('services/money_service.dart');
      expect(
        src,
        contains(
          'isShared ? q.where(\'memberUids\', isEqualTo: memberUids) : q',
        ),
      );
      // Each read goes through _pair.
      for (final read in [
        'watchWallets()',
        'watchTx({',
        'fetchTx({',
        'hasAnyTx()',
        'fetchWalletTx(',
        'findByLinkId(',
        'walletNetSums(',
        'monthSpent(',
      ]) {
        final at = src.indexOf(read);
        expect(at, isNonNegative, reason: read);
        final end = src.indexOf('\n\n', at);
        expect(
          src.substring(at, end < 0 ? src.length : end),
          contains('_pair('),
          reason: '$read must filter on the pair',
        );
      }
    });

    test(
      'BK-08: the Profile tile opens Sổ tiền (and logs the entry point)',
      () {
        final src = _read('screens/profile_screen.dart');
        final at = src.indexOf('onTap: () => openMoneyScreen(');
        expect(at, isNonNegative);
        expect(src.substring(at, at + 200), contains("from: 'profile'"));
      },
    );
  });

  group('l10n', () {
    test(
      'I18N-01: every money* key is in both ARBs with the same {placeholders}',
      () {
        Map<String, dynamic> load(String f) =>
            jsonDecode(File('lib/l10n/$f').readAsStringSync())
                as Map<String, dynamic>;
        final vi = load('app_vi.arb'), en = load('app_en.arb');
        Set<String> keys(Map<String, dynamic> m) => {
          for (final k in m.keys)
            if (k.startsWith('money')) k,
        };
        expect(keys(vi).difference(keys(en)), isEmpty, reason: 'only in vi');
        expect(keys(en).difference(keys(vi)), isEmpty, reason: 'only in en');
        expect(keys(vi).length, greaterThan(400));
        final ph = RegExp(r'\{(\w+)\}');
        final bad = <String>[];
        for (final k in keys(vi)) {
          Set<String> p(Map<String, dynamic> m) => {
            for (final x in ph.allMatches(m[k] as String)) x.group(1)!,
          };
          final a = p(vi), b = p(en);
          // Word order differs between the languages — compare as sets.
          if (a.difference(b).isNotEmpty || b.difference(a).isNotEmpty) {
            bad.add(k);
          }
        }
        expect(bad, isEmpty, reason: 'placeholders differ');
      },
    );
  });

  group('analytics payloads', () {
    const tx = MoneyTx(
      id: 't',
      type: MoneyTxType.expense,
      amount: 50000,
      date: '2026-10-23',
      outWalletId: 'w1',
      categoryId: 'food_out',
      note: 'Bún chả Hàng Quạt',
      payer: 'me',
      memberUids: ['me', 'her'],
    );
    final idx = MoneyCategoryIndex(
      resolveMoneyCategories(
        const MoneyMeta(
          customCategories: [
            MoneyCustomCategory(
              id: 'c1',
              kind: MoneyTxType.expense,
              name: 'Cầu lông',
            ),
          ],
        ),
        _l('vi'),
      ),
    );

    test('AN-01: money_tx_add carries enums and bools, never an amount, a '
        'wallet name or the note', () {
      final a = _Capture();
      a.logMoneyTxAdd(
        book: MoneyBookKind.shared,
        tx: tx,
        uid: 'me',
        categories: idx,
        walletType: MoneyWalletType.bank,
        via: 'chip',
        linked: true,
      );
      final e = a.events.single;
      expect(e.name, 'money_tx_add');
      expect(e.params, {
        'book': 'shared',
        'type': 'expense',
        'category': 'food',
        'wallet_type': 'bank',
        'payer': 'me',
        'via': 'chip',
        'has_note': true,
        'linked': true,
      });
      final dump = e.params.values.join('|');
      expect(dump, isNot(contains('Bún')));
      expect(dump, isNot(contains('50000')));
      expect(dump, isNot(contains('w1')));
    });

    test('AN-01: category is "custom" for the user\'s own, "none" without; '
        'payer is me / partner / wallet / na', () {
      Map<String, Object?> of(MoneyTx t, {String uid = 'me'}) {
        final a = _Capture();
        a.logMoneyTxAdd(
          book: MoneyBookKind.own,
          tx: t,
          uid: uid,
          categories: idx,
          via: 'manual',
          linked: false,
        );
        return a.events.single.params;
      }

      expect(of(tx.copyWith(categoryId: 'c1'))['category'], 'custom');
      expect(of(tx.copyWith(categoryId: ''))['category'], 'none');
      expect(of(tx, uid: 'her')['payer'], 'partner');
      expect(of(tx.copyWith(payer: kMoneyPayerWallet))['payer'], 'wallet');
      const solo = MoneyTx(
        id: 's',
        type: MoneyTxType.expense,
        amount: 1,
        date: '2026-10-23',
        outWalletId: 'w1',
        categoryId: 'food_coffee',
      );
      expect(of(solo)['payer'], 'na');
      expect(of(solo)['wallet_type'], 'none');
      expect(of(solo)['has_note'], false);
      expect(of(solo)['category'], 'food');
    });

    test('AN-02: edit and delete events', () {
      final a = _Capture()
        ..logMoneyTxEdit(MoneyBookKind.shared)
        ..logMoneyTxDelete(MoneyBookKind.own, undone: true)
        ..logMoneyTxDelete(MoneyBookKind.own, undone: false);
      expect(a.events.map((e) => e.name), [
        'money_tx_edit',
        'money_tx_delete',
        'money_tx_delete',
      ]);
      expect(a.events[0].params, {'book': 'shared'});
      expect(a.events[1].params, {'book': 'own', 'undone': true});
      expect(a.events[2].params, {'book': 'own', 'undone': false});
    });

    test('AN-02: the call sites exist (edit in the sheet, delete in the '
        'provider on both the "undo" and the "commit" path)', () {
      expect(
        _read('widgets/money/add_transaction_sheet.dart'),
        contains('logMoneyTxEdit(kind)'),
      );
      final p = _read('providers/money_provider.dart');
      expect(p, contains('logMoneyTxDelete(pending.kind, undone: true)'));
      expect(p, contains('logMoneyTxDelete(d.kind, undone: false)'));
    });

    test('AN-03: wallet / goal / goal reached', () {
      final a = _Capture()
        ..logMoneyWalletAdd(MoneyBookKind.own, MoneyWalletType.ewallet)
        ..logMoneyGoalAdd(MoneyBookKind.shared, hasDeadline: false)
        ..logMoneyGoalReached(MoneyBookKind.shared);
      expect(a.events.map((e) => e.name), [
        'money_wallet_add',
        'money_goal_add',
        'money_goal_reached',
      ]);
      expect(a.events[0].params, {'book': 'own', 'type': 'ewallet'});
      expect(a.events[1].params, {'book': 'shared', 'has_deadline': false});
      expect(a.events[2].params, {'book': 'shared'});
      // The call sites.
      expect(
        _read('screens/money/money_wallets_screen.dart'),
        allOf(
          contains('logMoneyGoalAdd('),
          contains('logMoneyWalletAdd(widget.book, _type)'),
        ),
      );
      expect(
        _read('screens/money/money_goal_screen.dart'),
        contains('logMoneyGoalReached(widget.book)'),
      );
    });

    test('AN-04: budget / report / search events exist with fixed params '
        'and are logged from their screens', () {
      final svc = _read('services/analytics_service.dart');
      expect(svc, contains("moneyBudgetSet = 'money_budget_set'"));
      expect(svc, contains("moneyReportOpen = 'money_report_open'"));
      expect(svc, contains("moneySearch = 'money_search'"));
      expect(
        svc,
        contains(
          'void logMoneyBudgetSet({required String book, required bool total})',
        ),
      );
      expect(
        svc,
        contains(
          'void logMoneyReportOpen({required String book, required String view})',
        ),
      );
      expect(svc, contains('void logMoneySearch(int filterCount)'));
      expect(
        _read('screens/money/money_budgets_screen.dart'),
        contains('logMoneyBudgetSet('),
      );
      expect(
        _read('screens/money/money_report_screen.dart'),
        contains('logMoneyReportOpen('),
      );
      expect(
        _read('screens/money/money_search_screen.dart'),
        contains('logMoneySearch(_filterCount)'),
      );
    });

    test('AN-05: screen open carries only the entry point', () {
      final a = _Capture();
      for (final from in [
        'home',
        'profile',
        'decision',
        'push',
        'inbox',
        'reminder',
      ]) {
        a.logMoneyScreenOpen(from);
      }
      expect(a.events.map((e) => e.name).toSet(), {'money_screen_open'});
      expect(a.events.map((e) => e.params['from']), [
        'home',
        'profile',
        'decision',
        'push',
        'inbox',
        'reminder',
      ]);
      // The call sites: default 'home', Home tile → 'push' unless a target
      // says otherwise, Profile → 'profile', inbox tap → 'inbox'.
      expect(
        _read('screens/money/money_screen.dart'),
        contains("String from = 'home'"),
      );
      expect(_read('screens/profile_screen.dart'), contains("from: 'profile'"));
      expect(
        _read('screens/home_screen.dart'),
        contains("from: target?.from ?? 'push'"),
      );
      expect(
        _read('screens/notification_center_screen.dart'),
        contains("from: 'inbox'"),
      );
    });

    test('AN-06: reminder toggle', () {
      final a = _Capture()
        ..logMoneyReminderToggle(true)
        ..logMoneyReminderToggle(false);
      expect(a.events.map((e) => e.params['on']), [true, false]);
      expect(a.events.first.name, 'money_reminder_toggle');
    });

    test('AN-01..06: names and params fit GA4 (≤ 40 chars, snake_case, '
        '≤ 24 params) and no param key can hold free text', () {
      final names = [
        for (final c in [
          MoneyAnalyticsEvents.txAdd,
          MoneyAnalyticsEvents.txEdit,
          MoneyAnalyticsEvents.txDelete,
          MoneyAnalyticsEvents.walletAdd,
          MoneyAnalyticsEvents.goalAdd,
          MoneyAnalyticsEvents.goalReached,
          MoneyAnalyticsEvents.screenOpen,
          MoneyAnalyticsEvents.reminderToggle,
        ])
          c,
      ];
      for (final n in names) {
        expect(n.length, lessThanOrEqualTo(40));
        expect(n, matches(RegExp(r'^money_[a-z_]+$')));
      }
      expect(names.toSet().length, names.length);
      for (final bad in ['name', 'note', 'amount', 'text', 'title']) {
        expect([
          MoneyAnalyticsEvents.pBook,
          MoneyAnalyticsEvents.pType,
          MoneyAnalyticsEvents.pCategory,
          MoneyAnalyticsEvents.pWalletType,
          MoneyAnalyticsEvents.pPayer,
          MoneyAnalyticsEvents.pVia,
          MoneyAnalyticsEvents.pFrom,
        ], isNot(contains(bad)));
      }
    });

    test('AN-07: opt-out flips the flag, persists it, and logging stays a '
        'silent no-op (no SDK bound in tests either way)', () async {
      final a = AnalyticsService.instance;
      await a.setEnabled(false);
      expect(a.isEnabled, isFalse);
      expect(
        Hive.box<String>('app_settings').get('analytics_enabled'),
        'false',
      );
      a.logMoneyGoalReached(MoneyBookKind.own); // must not throw
      a.logMoneyTxEdit(MoneyBookKind.own);
      final src = _read('services/analytics_service.dart');
      final at = src.indexOf('void logEvent(String name');
      expect(
        src.substring(at, at + 400),
        contains('if (analytics == null || !_enabled)'),
      );
      await a.setEnabled(true);
      expect(a.isEnabled, isTrue);
    });
  });
}
