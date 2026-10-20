import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_input.dart';
import '../../utils/money_math.dart';
import '../../widgets/header_icon_button.dart';
import '../../widgets/money/add_transaction_sheet.dart';
import '../../widgets/money/money_ui.dart';
import '../../widgets/segmented_pill.dart';
import '../../widgets/sub_screen_header.dart';

/// Shared scaffold of the money sub-screens: dawnBlush, chip header, list.
class _MoneyPage extends StatelessWidget {
  const _MoneyPage({
    required this.badge,
    required this.icon,
    required this.children,
    this.trailing,
    this.fab,
  });

  final String badge;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: fab,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SubScreenHeader(
                  badge: badge,
                  badgeIcon: icon,
                  trailing: trailing,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    (fab == null ? 24 : 112) +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Ví" (design §3.5): total money, wallets in use, goals, archived.
class MoneyWalletsScreen extends StatefulWidget {
  const MoneyWalletsScreen({super.key, this.book = MoneyBookKind.own});

  final MoneyBookKind book;

  @override
  State<MoneyWalletsScreen> createState() => _MoneyWalletsScreenState();
}

class _MoneyWalletsScreenState extends State<MoneyWalletsScreen> {
  late MoneyBookKind _book = widget.book;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    if (_book == MoneyBookKind.shared && !money.hasShared) {
      _book = MoneyBookKind.own;
    }
    final state = money.book(_book);
    final wallets = state?.wallets ?? const <MoneyWallet>[];
    final balances = money.balances(_book);
    final active = [
      for (final w in wallets)
        if (!w.archived && !w.isGoal) w,
    ];
    final goals = [
      for (final w in wallets)
        if (!w.archived && w.isGoal) w,
    ];
    final archived = [
      for (final w in wallets)
        if (w.archived) w,
    ];
    void open(MoneyWallet w) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MoneyWalletScreen(book: _book, walletId: w.id),
      ),
    );

    return _MoneyPage(
      badge: l10n.moneyWalletsBadge,
      icon: IconsaxPlusLinear.wallet_2,
      trailing: HeaderIconButton(
        icon: IconsaxPlusLinear.add,
        semanticsLabel: l10n.moneyAddWallet,
        onTap: () => MoneyWalletSheet.show(context, book: _book),
      ),
      children: [
        if (money.hasShared) ...[
          SegmentedPill<MoneyBookKind>(
            values: MoneyBookKind.values,
            selected: _book,
            labelOf: (b) => b == MoneyBookKind.own
                ? l10n.moneyTabMine
                : l10n.moneyTabShared,
            onChanged: (b) => setState(() => _book = b),
          ),
          const SizedBox(height: 16),
        ],
        MoneyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.moneyTotalAssets,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              MoneyAmountText(money.totalAssets(_book), size: 30),
              const SizedBox(height: 8),
              Text(
                l10n.moneyAssetsNote(
                  active.where((w) => w.includeInTotal).length,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MoneyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyCardHeader(
                title: l10n.moneyInUse,
                trailing: _meta(l10n.moneyWalletCount(active.length)),
              ),
              for (final w in active)
                MoneyWalletRow(
                  wallet: w,
                  balance: balances[w.id] ?? w.openingBalance,
                  sub: _sub(l10n, w),
                  onTap: () => open(w),
                ),
            ],
          ),
        ),
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 16),
          MoneyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyCardHeader(
                  title: l10n.moneyGoals,
                  trailing: _meta(l10n.moneyNotInTotal),
                ),
                for (final w in goals)
                  moneyGoalRow(
                    context,
                    money,
                    w,
                    balances[w.id] ?? 0,
                    () => open(w),
                  ),
              ],
            ),
          ),
        ],
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 16),
          MoneyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyCardHeader(
                  title: l10n.moneyArchivedSection,
                  trailing: _meta(l10n.moneyWalletCount(archived.length)),
                ),
                for (final w in archived)
                  MoneyWalletRow(
                    wallet: w,
                    balance: balances[w.id] ?? w.openingBalance,
                    dim: true,
                    sub: w.updatedAt == null
                        ? l10n.moneyArchivedPlain
                        : l10n.moneyArchived(
                            moneyShortDate(
                              context,
                              MoneyMath.dateKey(w.updatedAt!),
                            ),
                          ),
                    onTap: () => open(w),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        MoneyPrimaryButton(
          label: l10n.moneyAddWallet,
          icon: IconsaxPlusLinear.wallet_add,
          onPressed: () => MoneyWalletSheet.show(context, book: _book),
        ),
      ],
    );
  }

  String _sub(AppLocalizations l10n, MoneyWallet w) {
    final type = moneyWalletTypeLabel(l10n, w.type);
    if (w.type == MoneyWalletType.credit) {
      return '$type · ${l10n.moneyOwingCard}';
    }
    if (!w.includeInTotal) return '$type · ${l10n.moneyNotInTotal}';
    return type;
  }
}

Widget _meta(String text) => Text(
  text,
  style: const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  ),
);

/// Goal wallet row: 6px bar + "30% của 25.000.000 ₫" / "Cần ~X mỗi tháng".
Widget moneyGoalRow(
  BuildContext context,
  MoneyProvider money,
  MoneyWallet w,
  int balance,
  VoidCallback onTap,
) {
  final l10n = context.l10n;
  final target = w.goalTarget ?? 0;
  final pct = MoneyMath.goalPercent(balance, target);
  final deadline = w.goalDeadline;
  final perMonth = deadline == null || target <= 0
      ? 0
      : MoneyMath.perMonthNeeded(target - balance, money.today, deadline);
  final sub = perMonth > 0
      ? l10n.moneyGoalPerMonthShort(vnd(context, perMonth))
      : l10n.moneyGoalProgress('$pct', vnd(context, target));
  return MoneyWalletRow(
    wallet: w,
    balance: balance,
    sub: sub,
    onTap: onTap,
    below: MoneyGoalBar(percent: pct),
  );
}

/// One wallet (design §3.5): balance, this month in / out, Chuyển tiền ·
/// Sửa số dư, and the month's entries.
class MoneyWalletScreen extends StatelessWidget {
  const MoneyWalletScreen({
    super.key,
    required this.book,
    required this.walletId,
  });

  final MoneyBookKind book;
  final String walletId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final w = money
        .book(book)
        ?.wallets
        .where((x) => x.id == walletId)
        .firstOrNull;
    if (w == null) {
      return _MoneyPage(
        badge: l10n.moneyWalletsBadge,
        icon: IconsaxPlusLinear.wallet_2,
        children: const [],
      );
    }
    final balance = money.balances(book)[w.id] ?? w.openingBalance;
    final month = MoneyMath.monthKey(DateTime.now());
    final txs = [
      for (final t in money.txsForMonth(book, month) ?? const <MoneyTx>[])
        if (t.inWalletId == w.id || t.outWalletId == w.id) t,
    ];
    var inSum = 0, outSum = 0;
    for (final t in txs) {
      if (t.inWalletId == w.id) inSum += t.amount;
      if (t.outWalletId == w.id) outSum += t.amount;
    }
    final type = moneyWalletTypeLabel(l10n, w.type);
    final negative = balance < 0 && w.type != MoneyWalletType.credit;
    final rowCtx = MoneyRowContext.of(context, money, book, hideWalletId: w.id);
    final monthName = moneyMonthShort(context, month);

    return _MoneyPage(
      badge: w.name.toUpperCase(),
      icon: w.type == MoneyWalletType.bank || w.type == MoneyWalletType.credit
          ? IconsaxPlusLinear.card
          : w.isGoal
          ? IconsaxPlusLinear.flag
          : IconsaxPlusLinear.wallet_2,
      trailing: HeaderIconButton(
        icon: IconsaxPlusLinear.edit_2,
        semanticsLabel: l10n.moneyEditWallet,
        onTap: () => MoneyWalletSheet.show(context, book: book, editing: w),
      ),
      fab: _AddFab(
        onTap: () =>
            AddTransactionSheet.show(context, book: book, walletId: w.id),
      ),
      children: [
        MoneyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.moneyCurrentBalance,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              MoneyAmountText(balance, size: 30),
              const SizedBox(height: 4),
              Text(
                w.countsInTotal
                    ? l10n.moneyWalletInTotal(type)
                    : l10n.moneyWalletNotInTotal(type),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (negative) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    MoneyPill(label: vnd(context, balance), negative: false),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.moneyNegWallet,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _InOut(
                leftLabel: l10n.moneyInMonth(monthName),
                left: inSum,
                rightLabel: l10n.moneyOutMonth(monthName),
                right: outSum,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MoneyOutlineButton(
                      label: l10n.moneyTransferBtn,
                      icon: IconsaxPlusLinear.arrow_swap_horizontal,
                      onPressed: () => AddTransactionSheet.show(
                        context,
                        book: book,
                        type: MoneyTxType.transfer,
                        walletId: w.id,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MoneyOutlineButton(
                      label: l10n.moneyFixBalance,
                      icon: IconsaxPlusLinear.edit_2,
                      onPressed: () => MoneyFixBalanceSheet.show(
                        context,
                        book: book,
                        wallet: w,
                        balance: balance,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MoneyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyCardHeader(
                title: moneyMonthLabel(context, month),
                trailing: _meta(l10n.moneyEntryCount(txs.length)),
              ),
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.moneyWalletNoEntries,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                MoneyDayGroups(
                  txs: txs,
                  ctx: rowCtx,
                  onTapTx: (t) =>
                      AddTransactionSheet.show(context, book: book, editing: t),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InOut extends StatelessWidget {
  const _InOut({
    required this.leftLabel,
    required this.left,
    required this.rightLabel,
    required this.right,
  });

  final String leftLabel;
  final int left;
  final String rightLabel;
  final int right;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, Widget value) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            value,
          ],
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              leftLabel,
              MoneyAmountText(
                left,
                size: 16,
                prefix: left > 0 ? '+' : '',
                color: left > 0
                    ? AppColors.moneyPositive
                    : AppColors.textPrimary,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.white,
            ),
            cell(rightLabel, MoneyAmountText(-right, size: 16)),
          ],
        ),
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.moneyAddTx,
      excludeSemantics: true,
      child: Material(
        color: AppColors.accentLove,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              IconsaxPlusLinear.add,
              size: 28,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Create / edit a wallet (design §3.5): 5 types, name + emoji, balance
/// now (or target + deadline for a goal), "Tính vào tổng". Edit can't change
/// the type; wallets are archived, never deleted.
class MoneyWalletSheet extends StatefulWidget {
  const MoneyWalletSheet({super.key, required this.book, this.editing});

  final MoneyBookKind book;
  final MoneyWallet? editing;

  static Future<void> show(
    BuildContext context, {
    required MoneyBookKind book,
    MoneyWallet? editing,
  }) async {
    final message = await showMoneySheet<String>(
      context,
      builder: (_) => MoneyWalletSheet(book: book, editing: editing),
    );
    if (message != null && context.mounted) {
      showMoneySnack(context, message: message);
    }
  }

  @override
  State<MoneyWalletSheet> createState() => _MoneyWalletSheetState();
}

class _MoneyWalletSheetState extends State<MoneyWalletSheet> {
  late MoneyWalletType _type = widget.editing?.type ?? MoneyWalletType.ewallet;
  late final TextEditingController _name = TextEditingController(
    text: widget.editing?.name ?? '',
  );
  late String _emoji = widget.editing?.emoji ?? '';
  late final TextEditingController _amount = TextEditingController(
    text: _initialAmount(),
  );
  late bool _include = widget.editing?.includeInTotal ?? true;
  late String? _deadline = widget.editing?.goalDeadline;
  bool _busy = false;

  bool get _isEdit => widget.editing != null;
  bool get _goal => _type == MoneyWalletType.goal;

  String _initialAmount() {
    final e = widget.editing;
    if (e == null) return '';
    if (e.isGoal) return '${e.goalTarget ?? ''}';
    final v = e.type == MoneyWalletType.credit
        ? -e.openingBalance
        : e.openingBalance;
    return '$v';
  }

  static const Map<MoneyWalletType, String> _defaultEmoji = {
    MoneyWalletType.cash: '💵',
    MoneyWalletType.bank: '🏦',
    MoneyWalletType.ewallet: '📱',
    MoneyWalletType.credit: '💳',
    MoneyWalletType.goal: '🎯',
  };

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline == null
          ? DateTime(now.year, now.month + 3, now.day)
          : moneyParseDate(_deadline!),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null && mounted) {
      setState(() => _deadline = MoneyMath.dateKey(picked));
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final money = context.read<MoneyProvider>();
    final raw = _amount.text.trim();
    final parsed = parseVndInput(raw, max: kMoneyWalletMax);
    final value = raw.isEmpty ? 0 : (parsed.ok ? parsed.value! : null);
    if (value == null) return;
    final name = _name.text.trim();
    final opening = _goal
        ? 0
        : (_type == MoneyWalletType.credit ? -value : value);
    if (opening < kMoneyWalletMin) return;
    setState(() => _busy = true);
    try {
      final e = widget.editing;
      if (e == null) {
        final book = money.book(widget.book);
        await money.createWallet(
          widget.book,
          MoneyWallet(
            id: '',
            name: name,
            type: _type,
            emoji: _emoji.isEmpty ? _defaultEmoji[_type]! : _emoji,
            openingBalance: opening,
            includeInTotal: _goal ? false : _include,
            order: (book?.wallets.length ?? 0) + 1,
            goalTarget: _goal && value > 0 ? value : null,
            goalDeadline: _goal ? _deadline : null,
          ),
        );
        if (mounted) Navigator.of(context).pop(l10n.moneyWalletCreated(name));
      } else {
        await money.updateWallet(widget.book, e.id, {
          'name': name,
          'emoji': _emoji.isEmpty ? _defaultEmoji[_type]! : _emoji,
          if (!_goal) 'openingBalance': opening,
          if (!_goal) 'includeInTotal': _include,
          if (_goal && value > 0) 'goalTarget': value,
          if (_goal && _deadline != null) 'goalDeadline': _deadline,
        });
        if (mounted) Navigator.of(context).pop(l10n.moneySavedEdit);
      }
    } catch (e) {
      debugPrint('money: wallet save failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showMoneySnack(context, message: l10n.moneyWriteFailed);
    }
  }

  Future<void> _toggleArchive() async {
    final e = widget.editing!;
    final l10n = context.l10n;
    if (!e.archived) {
      final ok = await showMoneyConfirm(
        context,
        title: l10n.moneyArchiveAskTitle,
        body: l10n.moneyArchiveAskBody,
        confirm: l10n.moneyArchiveWallet,
      );
      if (ok != true || !mounted) return;
    }
    try {
      await context.read<MoneyProvider>().archiveWallet(
        widget.book,
        e.id,
        archived: !e.archived,
      );
      if (mounted) Navigator.of(context).pop(l10n.moneySavedEdit);
    } catch (_) {
      if (mounted) showMoneySnack(context, message: l10n.moneyWriteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.read<MoneyProvider>();
    final name = _name.text.trim();
    final raw = _amount.text.trim();
    final parsed = parseVndInput(raw, max: kMoneyWalletMax);
    final amountOk = raw.isEmpty || parsed.ok;
    final hints = {
      MoneyWalletType.cash: l10n.moneyHintCash,
      MoneyWalletType.bank: l10n.moneyHintBank,
      MoneyWalletType.ewallet: l10n.moneyHintEwallet,
      MoneyWalletType.credit: l10n.moneyHintCredit,
      MoneyWalletType.goal: l10n.moneyHintGoal,
    };
    final target = _goal && parsed.ok ? parsed.value! : 0;
    final perMonth = _goal && _deadline != null && target > 0
        ? MoneyMath.perMonthNeeded(target, money.today, _deadline!)
        : 0;
    final canSave = name.isNotEmpty && amountOk && !(_goal && target <= 0);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(
            title: _isEdit
                ? l10n.moneyEditWallet
                : (_goal ? l10n.moneyNewGoal : l10n.moneyNewWallet),
          ),
          if (!_isEdit) ...[
            const SizedBox(height: 4),
            for (final t in MoneyWalletType.values)
              Semantics(
                selected: t == _type,
                inMutuallyExclusiveGroup: true,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() {
                    _type = t;
                    _amount.clear();
                  }),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Row(
                      children: [
                        Icon(
                          t == _type
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                moneyWalletTypeLabel(l10n, t),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                hints[t]!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Semantics(
                button: true,
                label: l10n.moneyPickEmoji,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final e = await pickMoneyEmoji(
                      context,
                      _emoji.isEmpty ? _defaultEmoji[_type]! : _emoji,
                    );
                    if (e != null) setState(() => _emoji = e);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _emoji.isEmpty ? _defaultEmoji[_type]! : _emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: kMoneyNameMax,
                  onChanged: (_) => setState(() {}),
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  decoration: InputDecoration(
                    labelText: l10n.moneyName,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MoneyNumberField(
            controller: _amount,
            label: _goal
                ? l10n.moneyGoalTarget
                : _type == MoneyWalletType.credit
                ? l10n.moneyCreditOwed
                : l10n.moneyBalanceNow,
            onChanged: (_) => setState(() {}),
          ),
          if (_goal) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDeadline,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.moneyGoalDeadline,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      _deadline == null
                          ? l10n.moneyNotSet
                          : moneyShortDate(context, _deadline!),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      IconsaxPlusLinear.calendar_1,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (perMonth > 0)
              Text(
                l10n.moneyGoalPerMonth(
                  vnd(context, perMonth),
                  MoneyMath.monthsUntil(money.today, _deadline!),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
          ] else ...[
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _include,
              onChanged: (v) => setState(() => _include = v),
              title: Text(
                l10n.moneyIncludeInTotal,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.moneyIncludeInTotalSub,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          MoneyPrimaryButton(
            label: name.isEmpty
                ? l10n.moneyNameNeeded
                : _isEdit
                ? l10n.moneySave
                : (_goal ? l10n.moneyCreateGoal : l10n.moneyCreateWallet),
            busy: _busy,
            onPressed: canSave ? _save : null,
          ),
          if (_isEdit &&
              widget.editing!.id != money.defaultWalletId(widget.book))
            TextButton(
              onPressed: _toggleArchive,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(44, 44),
              ),
              child: Text(
                widget.editing!.archived
                    ? l10n.moneyUnarchiveWallet
                    : l10n.moneyArchiveWallet,
              ),
            ),
        ],
      ),
    );
  }
}

/// "Sửa số dư cho khớp" (design §3.5 / §15 #6): type what is really in the
/// wallet; the difference is written as one `adjust` line (not spending,
/// not income).
class MoneyFixBalanceSheet extends StatefulWidget {
  const MoneyFixBalanceSheet({
    super.key,
    required this.book,
    required this.wallet,
    required this.balance,
  });

  final MoneyBookKind book;
  final MoneyWallet wallet;
  final int balance;

  static Future<void> show(
    BuildContext context, {
    required MoneyBookKind book,
    required MoneyWallet wallet,
    required int balance,
  }) async {
    final message = await showMoneySheet<String>(
      context,
      builder: (_) =>
          MoneyFixBalanceSheet(book: book, wallet: wallet, balance: balance),
    );
    if (message != null && context.mounted) {
      showMoneySnack(context, message: message);
    }
  }

  @override
  State<MoneyFixBalanceSheet> createState() => _MoneyFixBalanceSheetState();
}

class _MoneyFixBalanceSheetState extends State<MoneyFixBalanceSheet> {
  final TextEditingController _real = TextEditingController();
  bool _busy = false;

  bool get _credit => widget.wallet.type == MoneyWalletType.credit;

  @override
  void dispose() {
    _real.dispose();
    super.dispose();
  }

  /// The real balance typed (credit: what is owed, stored negative).
  int? get _realValue {
    final r = parseVndInput(_real.text, max: kMoneyWalletMax);
    if (_real.text.trim() == '0') return 0;
    if (!r.ok) return null;
    return _credit ? -r.value! : r.value!;
  }

  Future<void> _save() async {
    final real = _realValue;
    if (real == null) return;
    final diff = real - widget.balance;
    if (diff == 0 || diff.abs() > kMoneyTxMax) return;
    final money = context.read<MoneyProvider>();
    final l10n = context.l10n;
    final w = widget.wallet;
    setState(() => _busy = true);
    try {
      await money.addTx(
        widget.book,
        MoneyTx(
          id: '',
          type: MoneyTxType.adjust,
          amount: diff.abs(),
          date: money.today,
          inWalletId: diff > 0 ? w.id : '',
          outWalletId: diff < 0 ? w.id : '',
          payer: widget.book == MoneyBookKind.shared ? money.uid : null,
          splitMode: widget.book == MoneyBookKind.shared
              ? MoneySplitMode.none
              : null,
        ),
      );
      if (mounted) Navigator.of(context).pop(l10n.moneyFixedToast(w.name));
    } catch (e) {
      debugPrint('money: fix balance failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showMoneySnack(context, message: l10n.moneyWriteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final real = _realValue;
    final diff = real == null ? null : real - widget.balance;
    final String? note = diff == null
        ? null
        : diff == 0
        ? l10n.moneyFixSame
        : diff < 0
        ? l10n.moneyFixMore(vnd(context, -diff))
        : l10n.moneyFixLess(vnd(context, diff));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(title: l10n.moneyFixTitle),
          Text(
            l10n.moneyFixInBook(
              widget.wallet.name,
              vnd(context, widget.balance),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          MoneyNumberField(
            controller: _real,
            big: true,
            autofocus: true,
            label: _credit ? l10n.moneyCreditOwed : l10n.moneyAdjustReal,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Text(
            _credit ? l10n.moneyCreditOwed : l10n.moneyAdjustReal,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          MoneyPrimaryButton(
            label: l10n.moneyAdjustSave,
            busy: _busy,
            onPressed: diff == null || diff == 0 || diff.abs() > kMoneyTxMax
                ? null
                : _save,
          ),
        ],
      ),
    );
  }
}
