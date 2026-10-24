import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../data/money_categories.dart';
import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../screens/money/money_categories_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/money_analytics.dart';
import '../../services/money_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../utils/money_currency.dart';
import '../../utils/money_input.dart';
import '../../utils/money_math.dart';
import '../segmented_pill.dart';
import '../../screens/money/money_wallets_screen.dart';
import 'money_ui.dart';

/// The amount typed on the sheet's own keypad (design §3.3, §15): keys go
/// into a string the shared parser reads ("1tr2" → 1.200.000). A 50k chip
/// fills the field; the next chip adds to it; a digit after a chip starts
/// over.
class MoneyAmountInput {
  MoneyAmountInput([this.raw = '']);

  String raw;

  /// The value came from a chip / "khoản quen": a digit replaces it.
  bool chipMode = false;

  /// The book's money (D31). The sheet sets it with [lang] on every build.
  MoneyCurrency currency = MoneyCurrency.vnd;

  /// App language: Vietnamese + VND keeps the "k · tr · củ" keys.
  String lang = 'vi';

  /// Vietnamese slang keys, only for a Vietnamese user counting đồng.
  static const List<String> viUnits = <String>['k', 'tr', 'củ'];

  /// Everyone else: thousand / million / billion.
  static const List<String> enUnits = <String>['K', 'M', 'B'];

  /// Every unit key any keypad shows (styling, tests).
  static const List<String> allUnits = <String>[...viUnits, ...enUnits];

  /// Kept for older call sites: the Vietnamese set.
  static const List<String> units = viUnits;
  static const int maxLength = 16;

  bool get _vi => lang == 'vi';

  /// The 3 unit keys this keypad shows.
  List<String> get keypadUnits => _vi && currency.isVnd ? viUnits : enUnits;

  /// "," in Vietnamese, "." in English.
  String get decimalKey => _vi ? ',' : '.';

  /// "000" for đồng / yen, "00" when the currency has cents.
  String get zerosKey => currency.decimals > 0 ? '00' : '000';

  String? get _unit {
    for (final u in allUnits) {
      if (raw.contains(u)) return u;
    }
    return null;
  }

  String? get _mark {
    for (final m in const [',', '.']) {
      if (raw.contains(m)) return m;
    }
    return null;
  }

  VndParseResult get parsed => parseMoneyInput(raw, currency: currency);

  void press(String key) {
    if (allUnits.contains(key)) {
      // One unit, right after a digit ("50k", "1tr2").
      if (chipMode || raw.isEmpty || _unit != null) return;
      if (!RegExp(r'\d$').hasMatch(raw)) return;
      raw += key;
      return;
    }
    if (chipMode) {
      raw = '';
      chipMode = false;
    }
    final isMark = key == ',' || key == '.';
    if (raw.isEmpty && (key == '0' || key == '000' || key == '00' || isMark)) {
      return;
    }
    if (isMark && (_mark != null || _unit != null)) return;
    // At most 2 digits after the mark ("1,25tr", "12.50").
    final mark = _mark;
    if (!isMark && mark != null && _unit == null) {
      final after = raw.length - raw.indexOf(mark) - 1;
      if (after + key.length > 2) return;
    }
    if (raw.length + key.length > maxLength) return;
    raw += key;
  }

  void backspace() {
    chipMode = false;
    if (raw.isEmpty) return;
    final unit = _unit;
    if (unit != null && raw.endsWith(unit)) {
      raw = raw.substring(0, raw.length - unit.length);
    } else {
      raw = raw.substring(0, raw.length - 1);
    }
  }

  /// 50k / 100k … chip ([value] in smallest units): fill, then add up on
  /// the next tap.
  void addChip(int value) {
    final current = parsed;
    final base = chipMode && current.ok ? current.value! : 0;
    raw = moneyInputText(base + value, currency);
    chipMode = true;
  }

  void setValue(int value) {
    raw = moneyInputText(value, currency);
    chipMode = true;
  }
}

/// What the sheet hands back to the screen that opened it (snackbar).
class _SheetResult {
  const _SheetResult(this.message, {this.detail, this.undo, this.duration});

  final String message;
  final String? detail;
  final VoidCallback? undo;
  final Duration? duration;
}

/// "Ghi khoản" / "Sửa khoản" (design §3.3 + §15): one sheet for both
/// books. Top row Đóng · Chi/Thu/Chuyển · book switch; amount + own keypad;
/// 50k chips; "Ghi lại khoản quen"; categories; wallet chips; a summary row
/// that opens who-paid / split / date / note; Save pinned at the bottom.
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    required this.book,
    this.editing,
    this.type = MoneyTxType.expense,
    this.walletId,
    this.categoryId,
    this.note,
    this.source,
  });

  final MoneyBookKind book;
  final MoneyTx? editing;
  final MoneyTxType type;

  /// Pre-selected wallet (wallet detail → "Chuyển tiền" = from-wallet).
  final String? walletId;

  /// Pre-selected category (first-entry chips).
  final String? categoryId;

  // ── expenses (đợt 2) ── stage 3B
  /// Pre-filled note (decision-wheel "Ghi chi": the pick, D20).
  final String? note;

  /// `source` of the new entry ('decision' from the wheel; null = manual).
  final String? source;

  static Future<void> show(
    BuildContext context, {
    required MoneyBookKind book,
    MoneyTx? editing,
    MoneyTxType type = MoneyTxType.expense,
    String? walletId,
    String? categoryId,
    String? note,
    String? source,
  }) async {
    final money = context.read<MoneyProvider>();
    var kind = book;
    if (kind == MoneyBookKind.shared && !money.hasShared) {
      kind = MoneyBookKind.own;
    }
    if (money.book(kind) == null) return;
    _ensureStarterWallets(money, kind);
    final result = await showMoneySheet<_SheetResult>(
      context,
      name: 'AddTransactionSheet',
      enableDrag: false,
      builder: (_) => AddTransactionSheet(
        book: kind,
        editing: editing,
        type: editing?.type ?? type,
        walletId: walletId,
        categoryId: categoryId,
        note: note,
        source: source,
      ),
    );
    if (result == null || !context.mounted) return;
    showMoneySnack(
      context,
      message: result.message,
      detail: result.detail,
      actionLabel: result.undo == null ? null : context.l10n.moneyUndo,
      onAction: result.undo,
      duration: result.duration ?? const Duration(seconds: 4),
    );
  }

  /// A book with no wallet at all (server-confirmed) gets its starter
  /// wallet before the first entry (D8; Home "+" before ever opening Sổ
  /// tiền).
  static void _ensureStarterWallets(MoneyProvider money, MoneyBookKind kind) {
    for (final k in {kind, MoneyBookKind.own}) {
      final b = money.book(k);
      if (b == null || !b.walletsFromServer) continue;
      final id = money.defaultWalletId(k);
      if (!b.wallets.any((w) => w.id == id) &&
          (k == MoneyBookKind.shared || b.wallets.isEmpty)) {
        unawaited(money.ensureDefaultWallet(k));
      }
    }
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

enum _Payer { me, partner, wallet }

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  static const String _prefsBox = 'app_settings';
  static const String _payerKey = 'money_last_payer';
  static const List<String> _expenseFill = <String>[
    'food_out',
    'food_coffee',
    'food_market',
    'move_fuel',
    'move_grab',
  ];

  late MoneyBookKind _book = widget.book;
  late MoneyTxType _type = widget.type;
  final MoneyAmountInput _input = MoneyAmountInput();
  String _categoryId = '';
  String? _walletId; // own book: the wallet the money leaves
  String? _fromId; // own book "Góp quỹ": from this wallet …
  String? _toId; // … into this goal
  _Payer _payer = _Payer.me;
  String? _deductId; // shared, my money: own wallet ('' = none yet)
  String? _sharedWalletId; // shared: paid from / into a shared wallet
  late String _date;
  final TextEditingController _note = TextEditingController();
  bool _detail = false;
  bool _saving = false;
  // ── expenses (đợt 2) ── stage 3B: filled from "Ghi lại khoản quen".
  bool _viaRepeat = false;

  MoneyTx? get _editing => widget.editing;
  bool get _isEdit => _editing != null;
  bool get _shared => _book == MoneyBookKind.shared;
  bool get _sharedExpense => _shared && _type == MoneyTxType.expense;

  /// "Góp quỹ" (D34): a contribution in the shared book, a transfer into a
  /// goal in the own book.
  MoneyTxType get _saveType =>
      _shared ? MoneyTxType.contribution : MoneyTxType.transfer;

  /// Money that leaves one of MY wallets alongside the shared entry:
  /// shared spending with my own money, or my contribution to a fund.
  bool get _fromMyMoney =>
      _shared &&
      ((_type == MoneyTxType.expense && _payer == _Payer.me) ||
          _type == MoneyTxType.contribution);

  /// Editing anything but spending: amount, date and note only.
  bool get _simpleEdit => _isEdit && _type != MoneyTxType.expense;

  MoneyProvider get _money => context.read<MoneyProvider>();

  /// A shared entry also in its creator's own book: only they change the
  /// money side (D13).
  bool get _locked {
    final e = _editing;
    return e != null &&
        e.memberUids.isNotEmpty &&
        e.linkId != null &&
        e.createdBy != _money.uid;
  }

  /// Any shared entry with an own-book half, mine included: "Ai trả" and
  /// the wallet stay as written, else the money leaves twice (shared
  /// wallet + my wallet). Amount / split / date / note stay editable.
  bool get _payerLocked {
    final e = _editing;
    return e != null && e.memberUids.isNotEmpty && e.linkId != null;
  }

  @override
  void initState() {
    super.initState();
    final money = context.read<MoneyProvider>();
    _date = money.today;
    _input.currency = money.currencyOf(_book);
    final e = _editing;
    if (e != null) {
      _loadEdit(e, money);
    } else {
      _restoreLast();
      _categoryId = widget.categoryId ?? '';
      if (widget.walletId != null) {
        if (_type == MoneyTxType.transfer) {
          _fromId = widget.walletId;
        } else {
          _walletId = widget.walletId;
          _sharedWalletId = widget.walletId;
          // ── expenses (đợt 2) ── stage 3B: spending from a shared wallet
          // ("Chi từ quỹ") ⇒ the wallet pays, not a person.
          if (_shared && _type == MoneyTxType.expense) _payer = _Payer.wallet;
        }
      }
      // ── expenses (đợt 2) ── stage 3B
      if (widget.note != null) _note.text = widget.note!;
      _fillDefaults(money);
    }
  }

  void _loadEdit(MoneyTx e, MoneyProvider money) {
    // Like a selected field: the first digit typed replaces the amount.
    _input.setValue(e.amount);
    _categoryId = e.categoryId;
    _date = e.date;
    _note.text = e.note;
    if (e.type == MoneyTxType.transfer) {
      _fromId = e.outWalletId;
      _toId = e.inWalletId;
    }
    if (_shared) {
      _payer = e.payer == kMoneyPayerWallet
          ? _Payer.wallet
          : e.payer == money.uid
          ? _Payer.me
          : _Payer.partner;
      _sharedWalletId = e.outWalletId.isNotEmpty ? e.outWalletId : e.inWalletId;
      _deductId = '';
    } else {
      _walletId = e.outWalletId;
    }
  }

  void _restoreLast() {
    if (!Hive.isBoxOpen(_prefsBox)) return;
    try {
      final box = Hive.box<String>(_prefsBox);
      // Only "Quỹ chung" / "Tiền riêng" are offered (D34).
      _payer = box.get(_payerKey) == _Payer.wallet.name
          ? _Payer.wallet
          : _Payer.me;
    } catch (_) {}
  }

  void _rememberLast() {
    if (!_sharedExpense || !Hive.isBoxOpen(_prefsBox)) return;
    try {
      final box = Hive.box<String>(_prefsBox);
      box.put(_payerKey, _payer.name);
    } catch (_) {}
  }

  List<MoneyWallet> _wallets(MoneyBookKind kind, {bool goals = false}) => [
    for (final w in _money.book(kind)?.wallets ?? const <MoneyWallet>[])
      if (!w.archived && (goals || !w.isGoal)) w,
  ];

  /// Fills what is still empty from the smart defaults (§15 #2): category =
  /// most used over 14 days, wallet = last used with that category.
  void _fillDefaults(MoneyProvider money) {
    if (_type == MoneyTxType.expense && _categoryId.isEmpty) {
      _categoryId = money.defaultCategory(_book, _type);
    }
    switch (_type) {
      case MoneyTxType.transfer:
        // Own "Góp quỹ": from my usual wallet into my first goal.
        _fromId ??= money.defaultWallet(_book, '');
        _toId ??= _goals(_book).firstOrNull?.id;
      case MoneyTxType.contribution:
        _sharedWalletId ??= _wallets(_book, goals: true).firstOrNull?.id;
        _deductId ??= _ownDeductFor('');
      default:
        if (_shared) {
          _sharedWalletId ??=
              money.defaultWallet(_book, _categoryId) ??
              _wallets(_book).firstOrNull?.id ??
              money.defaultWalletId(MoneyBookKind.shared);
          _deductId ??= _ownDeductFor(_categoryId);
        } else {
          _walletId ??= money.defaultWallet(_book, _categoryId);
        }
    }
  }

  List<MoneyWallet> _goals(MoneyBookKind kind) => [
    for (final w in _money.book(kind)?.wallets ?? const <MoneyWallet>[])
      if (!w.archived && w.isGoal) w,
  ];

  void _resetFor({MoneyTxType? type, MoneyBookKind? book}) {
    setState(() {
      if (type != null) _type = type;
      if (book != null && book != _book) {
        _book = book;
        // "Góp quỹ" is a contribution in one book, a transfer in the other.
        if (_type != MoneyTxType.expense) _type = _saveType;
        // "50k" typed for one book means nothing in another currency.
        final c = _money.currencyOf(book);
        if (c != _input.currency) {
          _input.currency = c;
          _input.raw = '';
        }
      }
      _categoryId = '';
      _walletId = null;
      _fromId = null;
      _toId = null;
      _deductId = null;
      _sharedWalletId = null;
      _fillDefaults(_money);
    });
  }

  void _pickCategory(String id) {
    setState(() {
      _categoryId = id;
      // The wallet follows the category ("cà phê → Tiền mặt").
      if (_shared) {
        if (_sharedExpense) _deductId = _ownDeductFor(id);
      } else {
        _walletId = _money.defaultWallet(_book, id);
      }
    });
  }

  void _useRepeat(MoneyTx t) {
    setState(() {
      _viaRepeat = true;
      _input.setValue(t.amount);
      _categoryId = t.categoryId;
      _note.text = t.note;
      if (_shared) {
        _payer = t.payer == kMoneyPayerWallet ? _Payer.wallet : _Payer.me;
        if (t.outWalletId.isNotEmpty) _sharedWalletId = t.outWalletId;
        final mine = t.linkId == null
            ? null
            : _money.own?.txs.where((o) => o.linkId == t.linkId).firstOrNull;
        _deductId = mine?.outWalletId ?? _ownDeductFor(t.categoryId);
      } else {
        _walletId = t.outWalletId.isEmpty ? _walletId : t.outWalletId;
      }
    });
  }

  // ── derived ──────────────────────────────────────────────────────────

  int? get _amount => _input.parsed.ok ? _input.parsed.value : null;

  String _payerUid() => switch (_payer) {
    _Payer.me => _money.uid ?? '',
    _Payer.partner => _money.partnerUid,
    _Payer.wallet => kMoneyPayerWallet,
  };

  /// The entry as it would be written (null = not valid yet).
  MoneyTx? _draft() {
    final amount = _amount;
    if (amount == null) return null;
    final uid = _money.uid ?? '';
    final base = MoneyTx(
      id: _editing?.id ?? '',
      type: _type,
      amount: amount,
      date: _date,
      note: _note.text.trim(),
      categoryId: _type == MoneyTxType.expense ? _categoryId : '',
      memberUids: _shared
          ? (_money.book(_book)?.service.memberUids ?? const <String>[])
          : const <String>[],
    );
    MoneyTx tx;
    switch (_type) {
      case MoneyTxType.transfer when !_isEdit:
        // Own "Góp quỹ": a normal wallet → a goal.
        if (_fromId == null || _toId == null || _fromId == _toId) return null;
        tx = base.copyWith(outWalletId: _fromId, inWalletId: _toId);
      case MoneyTxType.contribution when !_isEdit:
        final into = _sharedWalletId;
        if (into == null || into.isEmpty) return null;
        tx = base.copyWith(inWalletId: into, payer: uid);
      case MoneyTxType.expense:
        if (_shared) {
          final fromJoint = _payer == _Payer.wallet;
          if (fromJoint &&
              (_sharedWalletId == null || _sharedWalletId!.isEmpty)) {
            return null;
          }
          tx = base.copyWith(
            outWalletId: fromJoint ? _sharedWalletId : '',
            payer: _payerUid(),
          );
        } else {
          if (_walletId == null || _walletId!.isEmpty) return null;
          tx = base.copyWith(outWalletId: _walletId);
        }
      default:
        // Editing anything but spending: keep its wallets, change amount /
        // date / note only.
        final e = _editing;
        if (e == null) return null;
        tx = e.copyWith(amount: amount, date: _date, note: _note.text.trim());
    }
    if (_editing != null && _type == MoneyTxType.expense) {
      tx = _editing!.copyWith(
        amount: tx.amount,
        date: tx.date,
        note: tx.note,
        categoryId: tx.categoryId,
        outWalletId: tx.outWalletId,
        inWalletId: tx.inWalletId,
        payer: tx.payer,
      );
    }
    return tx.isWellFormed ? tx : null;
  }

  /// The own wallet a shared expense I paid comes out of: the usual one
  /// for [categoryId], else the first; '' only while I have none.
  String _ownDeductFor(String categoryId) =>
      _money.defaultWallet(MoneyBookKind.own, categoryId) ??
      _wallets(MoneyBookKind.own).firstOrNull?.id ??
      '';

  String? get _ownDeduct =>
      _fromMyMoney && (_deductId ?? '').isNotEmpty && _money.booksLinkable
      ? _deductId
      : null;

  bool _overCap(MoneyTx tx) {
    if (_money.exceedsWalletCap(_book, tx)) return true;
    final own = _ownDeduct;
    return own != null &&
        _money.exceedsWalletCap(
          MoneyBookKind.own,
          MoneyTx(
            id: '',
            type: MoneyTxType.expense,
            amount: tx.amount,
            date: tx.date,
            outWalletId: own,
          ),
        );
  }

  bool get _dirty => !_isEdit && _input.raw.isNotEmpty && !_saving;

  // ── actions ──────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: moneyParseDate(_date),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null && mounted) {
      setState(() => _date = MoneyMath.dateKey(picked));
    }
  }

  Future<void> _openPicker() async {
    final id = await MoneyCategoryPicker.show(
      context,
      book: _book,
      kind: _type,
      selected: _categoryId,
    );
    if (id != null && mounted) _pickCategory(id);
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    final amount = _amount;
    final cat = _money.book(_book)?.categories.of(_categoryId);
    final ok = await showMoneyConfirm(
      context,
      title: l10n.moneyDiscardTitle,
      body: l10n.moneyDiscardBody(
        vnd(context, amount ?? 0, book: _book),
        _type == MoneyTxType.expense ? (cat?.name ?? '') : l10n.moneyTypeSave,
      ),
      confirm: l10n.moneyDiscard,
      cancel: l10n.moneyKeepEditing,
      destructive: true,
    );
    return ok == true;
  }

  /// One line for the snackbar when this entry crosses 80 / 100 % of a
  /// budget (D17, in-app only).
  String? _budgetLine(MoneyTx tx) {
    if (tx.type != MoneyTxType.expense) return null;
    final money = _money;
    final book = money.book(_book);
    final month = tx.month;
    final txs = money.txsForMonth(_book, month);
    if (book == null || txs == null) return null;
    final idx = book.categories;
    final group = idx.groupOf(tx.categoryId);
    final l10n = context.l10n;
    for (final catId in [group, '']) {
      final budget = money.budgetFor(_book, catId);
      if (budget == null) continue;
      final before = MoneyMath.spentIn(
        txs,
        month,
        categoryId: catId,
        groupOf: idx.groupOf,
      );
      final after = before + tx.amount;
      final level = MoneyMath.crossedLevel(before, after, budget.amount);
      if (level == null) continue;
      final over = vnd(context, after - budget.amount, book: _book);
      final pct = '${MoneyMath.budgetStatus(after, budget.amount).percent}';
      if (catId.isEmpty) {
        return level >= 100
            ? l10n.moneyOverTotalToast(over)
            : l10n.moneyNearTotalToast(pct);
      }
      final name = idx.of(group).name;
      if (_shared) {
        return level >= 100
            ? l10n.moneyOverBudgetToast(name, over)
            : l10n.moneyNearBudgetToast(name, pct);
      }
      return level >= 100
          ? l10n.moneyOverBudgetToastMine(name, over)
          : l10n.moneyNearBudgetToastMine(name, pct);
    }
    return null;
  }

  Future<void> _save() async {
    final draft = _draft();
    if (draft == null || _saving || _overCap(draft)) return;
    final money = _money;
    final l10n = context.l10n;
    final kind = _book;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final old = _editing!;
        var alsoLinked = false;
        if (old.linkId != null && !_locked) {
          final linked = await money.linkedOf(kind, old);
          if (linked != null) {
            alsoLinked = true;
            if (kind == MoneyBookKind.shared && old.amount != draft.amount) {
              if (!mounted) return;
              final wallet = MoneyRowContext.of(
                context,
                money,
                MoneyBookKind.own,
                listen: false,
              ).walletName(linked.outWalletId);
              final both = await showMoneyConfirm(
                context,
                title: l10n.moneyLinkedAskTitle,
                body: l10n.moneyLinkedAskBody(
                  old.note.isEmpty
                      ? money.book(kind)!.categories.of(old.categoryId).name
                      : old.note,
                  vnd(context, linked.amount, book: _book),
                  wallet,
                  vnd(context, draft.amount, book: _book),
                ),
                confirm: l10n.moneyLinkedBoth,
                cancel: l10n.moneyLinkedSharedOnly,
              );
              alsoLinked = both == true;
            } else if (kind == MoneyBookKind.own) {
              // The own half never rewrites the shared money side.
              alsoLinked = false;
            }
          }
        }
        await money.updateTx(kind, old, draft, alsoLinked: alsoLinked);
        AnalyticsService.instance.logMoneyTxEdit(kind);
        HapticFeedback.lightImpact();
        if (!mounted) return;
        Navigator.of(context).pop(_SheetResult(l10n.moneySavedEdit));
        return;
      }
      final id = money.book(kind)!.service.newTxId();
      final tx = MoneyTx(
        id: id,
        type: draft.type,
        amount: draft.amount,
        date: draft.date,
        outWalletId: draft.outWalletId,
        inWalletId: draft.inWalletId,
        categoryId: draft.categoryId,
        note: draft.note,
        payer: draft.payer,
        memberUids: draft.memberUids,
        source: widget.source,
      );
      final budgetLine = _budgetLine(tx);
      final outcome = await money.addTx(kind, tx, ownWalletId: _ownDeduct);
      // ── expenses (đợt 2) ── stage 3B: analytics D27 (no amount / note).
      _logAdd(money, kind, tx);
      _rememberLast();
      HapticFeedback.lightImpact();
      if (!mounted) return;
      final cat = money.book(kind)!.categories.of(tx.categoryId);
      final message = tx.type == MoneyTxType.expense
          ? l10n.moneySaved(vnd(context, tx.amount, book: _book), cat.name)
          : l10n.moneySavedContribution(
              vnd(context, tx.amount, book: _book),
              money
                      .book(kind)!
                      .wallets
                      .where((w) => w.id == tx.inWalletId)
                      .firstOrNull
                      ?.name ??
                  '',
            );
      final offline = outcome == MoneyWriteOutcome.queued
          ? (kind == MoneyBookKind.shared
                ? l10n.moneySavedOffline
                : l10n.moneySavedOfflineMine)
          : null;
      final detail = [?offline, ?budgetLine].join('\n');
      Navigator.of(context).pop(
        _SheetResult(
          message,
          detail: detail.isEmpty ? null : detail,
          undo: () => _undoSave(money, kind, tx),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final people = MoneyPeople.of(context, listen: false);
      if (e.code == 'permission-denied') {
        Navigator.of(context).pop(
          _SheetResult(
            l10n.moneyConflictTitle(people.partnerName),
            detail: l10n.moneyConflictBody,
          ),
        );
      } else {
        showMoneySnack(context, message: l10n.moneyWriteFailed);
      }
    } catch (e) {
      debugPrint('money: save failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showMoneySnack(context, message: l10n.moneyWriteFailed);
    }
  }

  // ── expenses (đợt 2) ── stage 3B
  void _logAdd(MoneyProvider money, MoneyBookKind kind, MoneyTx tx) {
    final walletId = tx.outWalletId.isNotEmpty
        ? tx.outWalletId
        : tx.inWalletId.isNotEmpty
        ? tx.inWalletId
        : (_ownDeduct ?? '');
    final wallet = [
      ...?money.book(kind)?.wallets,
      ...?money.own?.wallets,
    ].where((w) => w.id == walletId).firstOrNull;
    AnalyticsService.instance.logMoneyTxAdd(
      book: kind,
      tx: tx,
      uid: money.uid ?? '',
      categories: money.book(kind)!.categories,
      walletType: wallet?.type,
      via: tx.source == 'decision'
          ? 'decision'
          : _viaRepeat
          ? 'chip'
          : 'manual',
      linked: _ownDeduct != null,
    );
  }

  /// "Hoàn tác" right after Save (§15 #8): the new entry (and its own-book
  /// half) leave at once and the delete goes out after the undo window.
  static Future<void> _undoSave(
    MoneyProvider money,
    MoneyBookKind kind,
    MoneyTx draft,
  ) async {
    final stored =
        money.book(kind)?.txs.where((t) => t.id == draft.id).firstOrNull ??
        draft;
    final linked = await money.linkedOf(kind, stored);
    money.scheduleDelete(kind, stored, alsoLinked: linked);
  }

  Future<void> _delete() async {
    final e = _editing;
    if (e == null) return;
    final money = _money;
    final l10n = context.l10n;
    final kind = _book;
    MoneyTx? alsoLinked;
    if (kind == MoneyBookKind.shared && e.linkId != null) {
      final linked = await money.linkedOf(kind, e);
      if (!mounted) return;
      if (linked != null) {
        final wallet =
            MoneyRowContext.of(
              context,
              money,
              MoneyBookKind.own,
              listen: false,
            ).walletName(
              linked.outWalletId.isNotEmpty
                  ? linked.outWalletId
                  : linked.inWalletId,
            );
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Text(
              l10n.moneyDeleteBothTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            content: Text(
              l10n.moneyDeleteBothBody(
                _titleOf(e),
                vnd(context, e.amount, book: _book),
                wallet,
              ),
              style: const TextStyle(fontSize: 15),
            ),
            actionsOverflowDirection: VerticalDirection.down,
            actionsOverflowButtonSpacing: 4,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('both'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.moneyNegative,
                ),
                child: Text(
                  l10n.moneyDeleteBoth,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('shared'),
                child: Text(l10n.moneyDeleteSharedOnly),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.moneyCancel),
              ),
            ],
          ),
        );
        if (choice == null || !mounted) return;
        if (choice == 'both') alsoLinked = linked;
      }
    }
    money.scheduleDelete(kind, e, alsoLinked: alsoLinked, byUser: true);
    if (!mounted) return;
    Navigator.of(context).pop(
      _SheetResult(
        l10n.moneyDeleted(_titleOf(e), vnd(context, e.amount, book: _book)),
        undo: () => money.undoDelete(e.id),
        duration: MoneyProvider.deleteDelay,
      ),
    );
  }

  String _titleOf(MoneyTx t) {
    if (t.note.trim().isNotEmpty) return t.note.trim();
    if (t.type == MoneyTxType.transfer) return context.l10n.moneyTypeTransfer;
    return _money.book(_book)?.categories.of(t.categoryId).name ?? '';
  }

  // ── build ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    _input
      ..currency = money.currencyOf(_book)
      ..lang = moneyLang(context);
    final media = MediaQuery.of(context);
    final draft = _draft();
    final overCap = draft != null && _overCap(draft);
    final keyboardUp = media.viewInsets.bottom > 0;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _input.raw = '';
          Navigator.of(context).pop();
        }
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.94),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: _isEdit ? l10n.moneyEditTx : l10n.moneyAddTx,
              child: const SizedBox.shrink(),
            ),
            _topRow(l10n, money),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _amountBlock(l10n, overCap),
                    if (!_locked) ...[const SizedBox(height: 4), _chips()],
                    ..._quickRow(l10n, money),
                    if (_type != MoneyTxType.transfer && !_simpleEdit)
                      ..._categoryRow(l10n, money),
                    if (!_simpleEdit) ..._walletRows(l10n, money),
                    const SizedBox(height: 8),
                    _summary(l10n),
                    AnimatedSize(
                      duration: AppMotion.reduceMotion(context)
                          ? Duration.zero
                          : AppMotion.base,
                      curve: AppMotion.curve,
                      alignment: Alignment.topCenter,
                      child: _detail || _locked
                          ? _detailPanel(l10n)
                          : (keyboardUp
                                ? const SizedBox.shrink()
                                : _keypad(l10n)),
                    ),
                    if (_isEdit && !_locked) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: _delete,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.moneyNegative,
                            minimumSize: const Size(44, 44),
                          ),
                          icon: const Icon(IconsaxPlusLinear.trash, size: 18),
                          label: Text(
                            l10n.moneyDeleteTx,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: MoneyPrimaryButton(
                label: _saveLabel(l10n, draft, overCap),
                busy: _saving,
                onPressed: draft == null || overCap ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _saveLabel(AppLocalizations l10n, MoneyTx? draft, bool overCap) {
    final p = _input.parsed;
    if (_input.raw.isEmpty) return l10n.moneySaveNeedAmount;
    if (!p.ok || overCap) return l10n.moneySaveFixAmount;
    if (draft == null) return l10n.moneySaveNeedWallet;
    return l10n.moneySaveAmount(vnd(context, draft.amount, book: _book));
  }

  Widget _topRow(AppLocalizations l10n, MoneyProvider money) {
    final canSwitchBook = !_isEdit && money.hasShared;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.moneyClose,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              IconsaxPlusLinear.close_circle,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: _isEdit
                ? Text(
                    l10n.moneyEditTx,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  )
                : SegmentedPill<MoneyTxType>(
                    height: 44,
                    onSurface: true,
                    values: [MoneyTxType.expense, _saveType],
                    selected: _type,
                    labelOf: (t) => t == MoneyTxType.expense
                        ? l10n.moneyTypeExpense
                        : l10n.moneyTypeSave,
                    onChanged: (t) => _resetFor(type: t),
                  ),
          ),
          const SizedBox(width: 8),
          if (canSwitchBook)
            Semantics(
              button: true,
              label: l10n.moneySwitchBook(
                _shared ? l10n.moneyBookShared : l10n.moneyTabMine,
              ),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _resetFor(
                  book: _shared ? MoneyBookKind.own : MoneyBookKind.shared,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _shared ? l10n.moneyBookShared : l10n.moneyTabMine,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          IconsaxPlusLinear.arrow_down_1,
                          size: 14,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _amountBlock(AppLocalizations l10n, bool overCap) {
    final p = _input.parsed;
    final value = p.value ?? 0;
    final tooBig = p.error == VndParseError.tooBig;
    final String hint;
    var bad = false;
    if (_locked) {
      final people = MoneyPeople.of(context);
      hint = l10n.moneyLinkedLocked(people.partnerName);
    } else if (_input.raw.isEmpty) {
      hint = moneyAmountHintText(context, book: _book);
    } else if (tooBig) {
      hint = moneyTooBigText(context, kMoneyTxMax, book: _book);
      bad = true;
    } else if (p.error == VndParseError.invalid) {
      hint = l10n.moneyAmountInvalid;
      bad = true;
    } else if (overCap) {
      hint = l10n.moneyWalletCapHit;
      bad = true;
    } else if (p.ok && p.hasUnit) {
      hint = l10n.moneyAmountEcho(_input.raw);
    } else {
      hint = '';
    }
    return Semantics(
      label: l10n.moneyAmountLabel,
      value: p.ok ? vndSpoken(context, value, book: _book) : _input.raw,
      liveRegion: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _detail = false;
          FocusScope.of(context).unfocus();
        }),
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MoneyAmountText(
                    value,
                    book: _book,
                    size: tooBig ? 30 : 40,
                    color: tooBig || overCap
                        ? AppColors.moneyNegative
                        : value == 0
                        ? AppColors.textPrimary.withValues(alpha: 0.35)
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 20,
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: bad ? FontWeight.w600 : FontWeight.w500,
                    color: bad
                        ? AppColors.moneyNegative
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chips() {
    final c = _input.currency;
    final lang = moneyLang(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final major in c.quickAmounts)
          MoneyChip(
            // "50k" in Vietnamese đồng, "50K" / "$5" otherwise.
            label: c.isVnd && lang == 'vi'
                ? '${major ~/ 1000}k'
                : formatMoneyShort(major * c.minor, c, locale: lang),
            onTap: () => setState(() => _input.addChip(major * c.minor)),
          ),
      ],
    );
  }

  List<Widget> _quickRow(AppLocalizations l10n, MoneyProvider money) {
    if (_isEdit || _type != MoneyTxType.expense || _input.raw.isNotEmpty) {
      return const [];
    }
    final repeats = money.quickRepeats(_book);
    if (repeats.isEmpty) return const [];
    final idx = money.book(_book)!.categories;
    return [
      _label(l10n.moneyQuickRepeat),
      MoneyChipRow(
        children: [
          for (final t in repeats)
            MoneyChip(
              emoji: idx.of(t.categoryId).emoji,
              label:
                  '${t.note.isEmpty ? idx.of(t.categoryId).name : t.note} · ${vndShort(context, t.amount, book: _book)}',
              onTap: () => _useRepeat(t),
            ),
        ],
      ),
    ];
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );

  /// 5 categories used most recently in this book (+ the selected one),
  /// topped up with common ones, then "Tất cả".
  List<String> _recentCategories(MoneyProvider money) {
    final idx = money.book(_book)!.categories;
    final pickable = {for (final c in idx.pickable(_type)) c.id};
    final out = <String>[];
    void add(String id) {
      if (id.isNotEmpty && pickable.contains(id) && !out.contains(id)) {
        out.add(id);
      }
    }

    add(_categoryId);
    final list = money.visibleTxs(_book).where((t) => t.type == _type).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final t in list) {
      if (out.length >= 5) break;
      add(t.categoryId);
    }
    for (final id in _expenseFill) {
      if (out.length >= 5) break;
      add(id);
    }
    return out;
  }

  List<Widget> _categoryRow(AppLocalizations l10n, MoneyProvider money) {
    final idx = money.book(_book)!.categories;
    return [
      _label(l10n.moneyCategory),
      MoneyChipRow(
        children: [
          for (final id in _recentCategories(money))
            MoneyChip(
              radio: true,
              emoji: idx.of(id).emoji,
              label: idx.of(id).name,
              selected: id == _categoryId,
              onTap: () => _pickCategory(id),
            ),
          MoneyChip(
            icon: IconsaxPlusLinear.category_2,
            label: l10n.moneyAllCategories,
            onTap: _openPicker,
          ),
        ],
      ),
    ];
  }

  Widget _walletChips(
    List<MoneyWallet> wallets,
    String? selected,
    ValueChanged<String> onPick, {
    MoneyBookKind? addTo,
    bool addGoal = false,
  }) {
    final l10n = context.l10n;
    final locked = _locked || (_shared && _payerLocked);
    return MoneyChipRow(
      children: [
        for (final w in wallets)
          MoneyChip(
            radio: true,
            emoji: w.emoji,
            label: w.name,
            selected: w.id == selected,
            onTap: locked ? null : () => onPick(w.id),
          ),
        if (addTo != null && !locked)
          MoneyChip(
            icon: IconsaxPlusLinear.add,
            label: l10n.moneyAddSource,
            onTap: () => _addSource(addTo, onPick),
          ),
        if (addGoal && !locked)
          MoneyChip(
            icon: IconsaxPlusLinear.add,
            label: l10n.moneyNewGoal,
            onTap: () => _addSource(_book, onPick, goal: true),
          ),
      ],
    );
  }

  /// "+ Thêm nguồn": the user names a new wallet (Ví's own sheet, no
  /// goal type) and it is picked right away.
  Future<void> _addSource(
    MoneyBookKind kind,
    ValueChanged<String> onPick, {
    bool goal = false,
  }) async {
    String? created;
    await showMoneySheet<String>(
      context,
      name: goal ? 'MoneyAddGoalSheet' : 'MoneyAddSourceSheet',
      builder: (_) => MoneyWalletSheet(
        book: kind,
        allowGoal: goal,
        goalOnly: goal,
        onCreated: (id) => created = id,
      ),
    );
    final id = created;
    if (id != null && mounted) setState(() => onPick(id));
  }

  List<Widget> _walletRows(AppLocalizations l10n, MoneyProvider money) {
    final people = MoneyPeople.of(context);
    // "Tiền riêng": which of MY wallets the money leaves.
    List<Widget> mine(String label) => [
      if (money.own != null && !_isEdit && money.booksLinkable) ...[
        _label(label),
        _walletChips(
          _wallets(MoneyBookKind.own),
          _deductId,
          (id) => setState(() => _deductId = id),
          addTo: MoneyBookKind.own,
        ),
      ],
    ];
    switch (_type) {
      case MoneyTxType.transfer:
        return [
          _label(l10n.moneySaveInto),
          _walletChips(
            _goals(_book),
            _toId,
            (id) => setState(() => _toId = id),
            addGoal: true,
          ),
          _label(l10n.moneyFromWallet),
          _walletChips(
            _wallets(_book),
            _fromId,
            (id) => setState(() => _fromId = id),
            addTo: _book,
          ),
        ];
      case MoneyTxType.contribution:
        return [
          _label(l10n.moneySaveInto),
          _walletChips(
            _wallets(_book, goals: true),
            _sharedWalletId,
            (id) => setState(() => _sharedWalletId = id),
            addGoal: true,
          ),
          ...mine(l10n.moneyFromWallet),
        ];
      default:
        break;
    }
    if (_shared) {
      final locked = _locked || _payerLocked;
      return [
        _label(l10n.moneyPaidFrom),
        MoneyChipRow(
          children: [
            for (final w in _wallets(_book))
              MoneyChip(
                radio: true,
                emoji: w.emoji,
                label: w.name,
                selected: _payer == _Payer.wallet && w.id == _sharedWalletId,
                onTap: locked
                    ? null
                    : () => setState(() {
                        _payer = _Payer.wallet;
                        _sharedWalletId = w.id;
                      }),
              ),
            if (_payer == _Payer.partner)
              MoneyChip(
                radio: true,
                label: l10n.moneyPaidByNoSplit(people.partnerName),
                selected: true,
              )
            else
              MoneyChip(
                radio: true,
                label: l10n.moneyMyMoney,
                selected: _payer == _Payer.me,
                onTap: locked
                    ? null
                    : () => setState(() {
                        _payer = _Payer.me;
                        _deductId ??= _ownDeductFor(_categoryId);
                      }),
              ),
          ],
        ),
        if (_payer == _Payer.me) ...mine(l10n.moneyDeductMine),
      ];
    }
    return [
      _label(l10n.moneyWallet),
      _walletChips(
        // ── expenses (đợt 2) ── stage 3B: "Chi từ quỹ" keeps the fund chip.
        _wallets(
          _book,
          goals:
              _wallets(
                _book,
                goals: true,
              ).where((w) => w.id == _walletId).firstOrNull?.isGoal ??
              false,
        ),
        _walletId,
        (id) => setState(() => _walletId = id),
        addTo: _book,
      ),
    ];
  }

  String _dateShort() => _date == _money.today
      ? context.l10n.moneyToday
      : moneyShortDate(context, _date);

  Widget _summary(AppLocalizations l10n) {
    final note = _note.text.trim();
    final text = '${_dateShort()} · ${note.isEmpty ? l10n.moneyAddNote : note}';
    return Semantics(
      button: true,
      expanded: _detail,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() {
          _detail = !_detail;
          if (!_detail) FocusScope.of(context).unfocus();
        }),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                _detail
                    ? IconsaxPlusLinear.keyboard
                    : IconsaxPlusLinear.arrow_down_1,
                size: 18,
                color: AppColors.textSecondary,
                semanticLabel: _detail ? l10n.moneyShowKeypad : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailPanel(AppLocalizations l10n) {
    final children = <Widget>[];
    if (_payerLocked && !_locked) {
      children.add(_shareLine(l10n.moneyLinkedPayerLocked));
    }
    children
      ..add(const SizedBox(height: 8))
      ..add(
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _pickDate,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Text(
                  l10n.moneyDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  moneyDayLabel(context, _date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      )
      ..add(const SizedBox(height: 4))
      ..add(
        TextField(
          controller: _note,
          maxLength: kMoneyNoteMax,
          onChanged: (_) => setState(() {}),
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.moneyNote,
            hintText: l10n.moneyNoteHint,
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _shareLine(String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _keypad(AppLocalizations l10n) {
    // Vietnamese + đồng: k · tr · củ. Anything else: K · M · B.
    final u = _input.keypadUnits;
    final keys = <String>[
      '1', '2', '3', '⌫', //
      '4', '5', '6', u[0],
      '7', '8', '9', u[1],
      _input.decimalKey, '0', _input.zerosKey, u[2],
    ];
    String? spoken(String k) => switch (k) {
      '⌫' => l10n.moneyKeyDelete,
      'k' || 'K' => l10n.moneyKeyThousand,
      'tr' || 'M' => l10n.moneyKeyMillion,
      'củ' => l10n.moneyKeyCu,
      'B' => l10n.moneyKeyBillion,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 8.0;
          final w = (c.maxWidth - gap * 3) / 4;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final k in keys)
                SizedBox(
                  width: w,
                  height: 48,
                  child: Semantics(
                    button: true,
                    label: spoken(k) ?? k,
                    excludeSemantics: true,
                    child: Material(
                      color: MoneyAmountInput.allUnits.contains(k)
                          ? AppColors.textPrimary.withValues(alpha: 0.08)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (k == '⌫') {
                              _input.backspace();
                            } else {
                              _input.press(k);
                            }
                          });
                        },
                        child: Center(
                          child: k == '⌫'
                              ? const Icon(
                                  IconsaxPlusLinear.arrow_square_left,
                                  size: 24,
                                  color: AppColors.textPrimary,
                                )
                              : Text(
                                  k,
                                  style: TextStyle(
                                    fontSize:
                                        MoneyAmountInput.allUnits.contains(k)
                                        ? 16
                                        : 22,
                                    fontWeight:
                                        MoneyAmountInput.allUnits.contains(k)
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Two-level category picker (design §3.3): search without accents, each
/// group row selectable + its children as wrapping chips; "Sửa" opens the
/// category screen.
class MoneyCategoryPicker extends StatefulWidget {
  const MoneyCategoryPicker({
    super.key,
    required this.book,
    required this.kind,
    required this.selected,
  });

  final MoneyBookKind book;
  final MoneyTxType kind;
  final String selected;

  static Future<String?> show(
    BuildContext context, {
    required MoneyBookKind book,
    required MoneyTxType kind,
    required String selected,
  }) => showMoneySheet<String>(
    context,
    builder: (_) =>
        MoneyCategoryPicker(book: book, kind: kind, selected: selected),
  );

  @override
  State<MoneyCategoryPicker> createState() => _MoneyCategoryPickerState();
}

class _MoneyCategoryPickerState extends State<MoneyCategoryPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final idx = money.book(widget.book)?.categories;
    if (idx == null) return const SizedBox.shrink();
    final all = idx.pickable(widget.kind);
    final q = MoneyMath.fold(_query.trim());
    bool hit(MoneyCategory c) =>
        q.isEmpty || MoneyMath.fold(c.name).contains(q);
    final groups = [
      for (final g in all)
        if (g.isGroup) g,
    ];
    final children = <String, List<MoneyCategory>>{};
    for (final c in all) {
      if (!c.isGroup) (children[c.parentId] ??= <MoneyCategory>[]).add(c);
    }
    final shown = [
      for (final g in groups)
        if (hit(g) || (children[g.id] ?? const []).any(hit)) g,
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(IconsaxPlusLinear.arrow_left, size: 24),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.moneyPickCategory,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: 'MoneyCategories'),
                        builder: (_) =>
                            MoneyCategoriesScreen(book: widget.book),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: Text(
                    l10n.moneyEditCategoriesShort,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  IconsaxPlusLinear.search_normal_1,
                  size: 20,
                ),
                hintText: l10n.moneyCategorySearchHint,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Flexible(
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.moneyCategoryNoMatch,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final g = shown[i];
                      final kids = [
                        for (final c
                            in children[g.id] ?? const <MoneyCategory>[])
                          if (hit(c) || hit(g)) c,
                      ];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pop(g.id),
                            child: SizedBox(
                              height: 44,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      g.emoji,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      g.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (g.id == widget.selected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: AppColors.textPrimary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (kids.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 38),
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  for (final c in kids)
                                    MoneyChip(
                                      radio: true,
                                      emoji: c.emoji,
                                      label: c.name,
                                      selected: c.id == widget.selected,
                                      onTap: () =>
                                          Navigator.of(context).pop(c.id),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
