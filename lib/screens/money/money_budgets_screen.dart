import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../data/money_categories.dart';
import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_input.dart';
import '../../utils/money_math.dart';
import '../../utils/money_views.dart';
import '../../widgets/header_icon_button.dart';
import '../../widgets/money/money_ui.dart';
import '../../widgets/shimmer_skeleton.dart';

/// "Ngân sách" (design §3.7): the whole-book budget of this month, the
/// category budgets closest to their limit first, the groups being spent on
/// without one, and (shared book) what the 80 % / 100 % push says.
class MoneyBudgetsScreen extends StatefulWidget {
  const MoneyBudgetsScreen({super.key, this.book = MoneyBookKind.own});

  final MoneyBookKind book;

  @override
  State<MoneyBudgetsScreen> createState() => _MoneyBudgetsScreenState();
}

class _MoneyBudgetsScreenState extends State<MoneyBudgetsScreen> {
  late MoneyBookKind _book = widget.book;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    if (_book == MoneyBookKind.shared && !money.hasShared) {
      _book = MoneyBookKind.own;
    }
    money.activeBook = _book;
    final state = money.book(_book);
    final today = money.today;
    final month = today.substring(0, 7);
    final txs = money.txsForMonth(_book, month);
    final loading = state == null || txs == null || !state.txLoaded;
    final list = txs ?? const <MoneyTx>[];
    final idx = state?.categories;
    final shared = _book == MoneyBookKind.shared;

    void edit([String? categoryId]) =>
        MoneyBudgetSheet.show(context, book: _book, categoryId: categoryId);

    final rows = loading || idx == null
        ? const <(MoneyBudget, MoneyBudgetStatus)>[]
        : MoneyViews.categoryBudgets(
            state.budgets,
            list,
            month,
            groupOf: idx.groupOf,
          );
    final unset = loading || idx == null
        ? const <(String, int)>[]
        : MoneyViews.unbudgetedGroups(
            state.budgets,
            list,
            month,
            groupOf: idx.groupOf,
          );

    return MoneyPage(
      badge: l10n.moneyBudgetsBadge,
      icon: IconsaxPlusLinear.chart_2,
      book: _book,
      onBook: (b) => setState(() => _book = b),
      trailing: state == null
          ? null
          : HeaderIconButton(
              icon: IconsaxPlusLinear.add,
              semanticsLabel: l10n.moneyAddBudget,
              onTap: edit,
            ),
      slivers: [
        moneyBlock(
          _TotalCard(
            book: _book,
            today: today,
            spent: MoneyMath.spentIn(list, month),
            loading: loading,
            onEdit: () => edit(''),
          ),
        ),
        if (!loading && idx != null) ...[
          moneyBlock(
            MoneyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MoneyCardHeader(title: l10n.moneyBudgetByCategory),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.moneyBudgetNoCategory,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.surfaceLight),
                    _BudgetRow(
                      category: idx.of(rows[i].$1.categoryId),
                      status: rows[i].$2,
                      onTap: () => edit(rows[i].$1.categoryId),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (unset.isNotEmpty)
            moneyBlock(
              MoneyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MoneyCardHeader(title: l10n.moneyBudgetNone),
                    const SizedBox(height: 4),
                    for (final (id, amount) in unset)
                      _UnsetRow(
                        category: idx.of(id),
                        spent: amount,
                        onSet: () => edit(id),
                      ),
                  ],
                ),
              ),
            ),
        ],
        if (shared)
          moneyBlock(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.moneyBudgetPushNote,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary.withValues(alpha: 0.80),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Status next to a category name: grey % below 80, warn pill from 80,
/// "Vượt 3%" pill from 100 (colour never alone, design §7).
Widget moneyBudgetBadge(BuildContext context, MoneyBudgetStatus st) {
  if (st.level >= 100) {
    return MoneyPill(
      label: context.l10n.moneyOverPercent('${st.percent - 100}'),
      negative: true,
    );
  }
  if (st.level >= 80) {
    return MoneyPill(label: '${st.percent}%', negative: false);
  }
  return Text(
    '${st.percent}%',
    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.book,
    required this.today,
    required this.spent,
    required this.loading,
    required this.onEdit,
  });

  final MoneyBookKind book;
  final String today;
  final int spent;
  final bool loading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final month = today.substring(0, 7);
    final budget = money.budgetFor(book, '');
    final monthName = moneyMonthShort(context, month);
    final title = book == MoneyBookKind.shared
        ? l10n.moneyBudgetScopeShared(monthName)
        : l10n.moneyBudgetScopeMine(monthName);
    final status = budget == null
        ? null
        : MoneyMath.budgetStatus(spent, budget.amount);
    final days = MoneyMath.daysInMonth(month);
    final day = int.parse(today.substring(8, 10));

    final header = MoneyCardHeader(
      title: title,
      trailing: status == null
          ? null
          : Text(
              l10n.moneyBudgetDaysLeft('${(days - day).clamp(0, days)}'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
    );

    if (status == null) {
      return MoneyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 8),
            Text(
              l10n.moneyBudgetUnset,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            MoneyPrimaryButton(label: l10n.moneySetBudget, onPressed: onEdit),
          ],
        ),
      );
    }

    final left = MoneyViews.perDayLeft(status, today);
    return _TapCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          if (loading)
            const ShimmerSkeleton(width: 170, height: 30)
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyAmountText(spent, size: 30),
            ),
          const SizedBox(height: 12),
          if (loading)
            const ShimmerSkeleton(height: 8, borderRadius: 999)
          else
            MoneyPlanBar(
              spent: spent,
              budget: status.budget,
              todayFrac: day / days,
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.moneyBudgetUsed('${status.percent}'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.moneyBudgetUsedOf(vnd(context, status.budget)),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (!loading) ...[
            const SizedBox(height: 12),
            Text(
              status.left < 0
                  ? l10n.moneyFindingOver(vnd(context, -status.left))
                  : l10n.moneyBudgetDailyLeft(
                      vnd(context, status.left),
                      vnd(context, left.perDay),
                    ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A whole [MoneyCard] that opens something (ripple rose .06).
class _TapCard extends StatelessWidget {
  const _TapCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MoneyCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accentRose.withValues(alpha: 0.06),
          child: child,
        ),
      ),
    );
  }
}

/// Two-level row (design §3.7): emoji · name · status · spent / 8px bar /
/// "Còn 58.000 ₫ của 2.000.000 ₫".
class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.category,
    required this.status,
    required this.onTap,
  });

  final MoneyCategory category;
  final MoneyBudgetStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final st = status;
    final note = st.left < 0
        ? l10n.moneyBudgetOverOf(
            vnd(context, -st.left),
            vnd(context, st.budget),
          )
        : l10n.moneyBudgetLeftOf(
            vnd(context, st.left),
            vnd(context, st.budget),
          );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.accentRose.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: ExcludeSemantics(
                    child: Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  // The pill drops under the name when the row is narrow
                  // (360dp, big text) instead of overflowing.
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      moneyBudgetBadge(context, st),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MoneyAmountText(st.spent, size: 15),
              ],
            ),
            const SizedBox(height: 10),
            MoneyPlanBar(spent: st.spent, budget: st.budget),
            const SizedBox(height: 6),
            Text(
              note,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsetRow extends StatelessWidget {
  const _UnsetRow({
    required this.category,
    required this.spent,
    required this.onSet,
  });

  final MoneyCategory category;
  final int spent;
  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: ExcludeSemantics(
              child: Text(
                category.emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.moneyHomeSpentNoBudget(vnd(context, spent)),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: '${l10n.moneyAddBudget}, ${category.name}',
            excludeSemantics: true,
            child: TextButton(
              onPressed: onSet,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(64, 44),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: Text(
                l10n.moneyBudgetSetLink,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Set / change / remove one budget. [categoryId] null = pick it here
/// (header "+"); '' = the whole book.
class MoneyBudgetSheet extends StatefulWidget {
  const MoneyBudgetSheet({super.key, required this.book, this.categoryId});

  final MoneyBookKind book;
  final String? categoryId;

  static Future<void> show(
    BuildContext context, {
    required MoneyBookKind book,
    String? categoryId,
  }) async {
    final done = await showMoneySheet<({String message, VoidCallback? undo})>(
      context,
      builder: (_) => MoneyBudgetSheet(book: book, categoryId: categoryId),
    );
    if (done != null && context.mounted) {
      showMoneySnack(
        context,
        message: done.message,
        actionLabel: done.undo == null ? null : context.l10n.moneyUndo,
        onAction: done.undo,
      );
    }
  }

  @override
  State<MoneyBudgetSheet> createState() => _MoneyBudgetSheetState();
}

class _MoneyBudgetSheetState extends State<MoneyBudgetSheet> {
  final TextEditingController _amount = TextEditingController();
  late String _cat = widget.categoryId ?? '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  MoneyBudget? get _existing =>
      context.read<MoneyProvider>().budgetFor(widget.book, _cat);

  void _prefill() {
    final b = _existing;
    _amount.text = b == null
        ? ''
        : moneyInputText(b.amount, moneyCurrency(context, book: widget.book));
  }

  String _nameOf(String id) {
    if (id.isEmpty) return context.l10n.moneyBudgetWholeBook;
    final idx = context.read<MoneyProvider>().book(widget.book)?.categories;
    return idx?.of(id).name ?? '';
  }

  Future<void> _save() async {
    final r = moneyParse(context, _amount.text);
    if (!r.ok) return;
    final money = context.read<MoneyProvider>();
    final l10n = context.l10n;
    final amount = r.value!;
    setState(() => _busy = true);
    try {
      await money.setBudget(widget.book, categoryId: _cat, amount: amount);
      AnalyticsService.instance.logMoneyBudgetSet(
        book: widget.book.name,
        total: _cat.isEmpty,
      );
      if (!mounted) return;
      Navigator.of(context).pop((
        message: l10n.moneyBudgetSaved(_nameOf(_cat), vnd(context, amount)),
        undo: null,
      ));
    } catch (e) {
      debugPrint('money: set budget failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showMoneySnack(context, message: l10n.moneyWriteFailed);
    }
  }

  void _remove() {
    final b = _existing;
    if (b == null) return;
    final money = context.read<MoneyProvider>();
    final l10n = context.l10n;
    final book = widget.book;
    // Deleted after the undo window, like an entry: "Hoàn tác" keeps the
    // same doc (and its `alerted` marks — no second 80/100 % push).
    money.scheduleBudgetDelete(book, b);
    Navigator.of(context).pop((
      message: l10n.moneyBudgetRemoved(_nameOf(b.categoryId)),
      undo: () => money.undoBudgetDelete(book, b.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final idx = money.book(widget.book)?.categories;
    final r = moneyParse(context, _amount.text);
    final existing = money.budgetFor(widget.book, _cat);
    final groups = [
      for (final c in idx?.pickable(MoneyTxType.expense) ?? <MoneyCategory>[])
        if (c.isGroup) c,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(
            title: widget.categoryId == null || widget.categoryId!.isEmpty
                ? l10n.moneyBudgetSheetTitle
                : _nameOf(_cat),
          ),
          if (widget.categoryId == null) ...[
            const SizedBox(height: 8),
            // Chip Collection Reflow (UI UX Pro Max): wrap, never one
            // clipped row — 13+ groups.
            Wrap(
              spacing: 8,
              children: [
                MoneyChip(
                  label: l10n.moneyBudgetWholeBook,
                  radio: true,
                  selected: _cat.isEmpty,
                  onTap: () => setState(() {
                    _cat = '';
                    _prefill();
                  }),
                ),
                for (final c in groups)
                  MoneyChip(
                    label: c.name,
                    emoji: c.emoji,
                    radio: true,
                    selected: _cat == c.id,
                    onTap: () => setState(() {
                      _cat = c.id;
                      _prefill();
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          MoneyNumberField(
            controller: _amount,
            big: true,
            autofocus: widget.categoryId != null,
            max: kMoneyTxMax,
            label: l10n.moneyBudgetAmountLabel,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.moneyBudgetAmountLabel}. ${l10n.moneyBudgetResets}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          MoneyPrimaryButton(
            label: r.ok
                ? l10n.moneyBudgetSave
                : _amount.text.trim().isEmpty
                ? l10n.moneySaveNeedAmount
                : l10n.moneySaveFixAmount,
            busy: _busy,
            onPressed: r.ok ? _save : null,
          ),
          if (existing != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _remove,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.moneyNegative,
                minimumSize: const Size(0, 44),
              ),
              child: Text(
                l10n.moneyBudgetRemove,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
