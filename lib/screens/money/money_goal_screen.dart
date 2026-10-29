import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/money_analytics.dart';
import '../../services/money_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_flows.dart';
import '../../utils/money_input.dart';
import '../../widgets/header_icon_button.dart';
import '../../widgets/money/add_transaction_sheet.dart';
import '../../widgets/money/money_ui.dart';
import '../../widgets/shimmer_skeleton.dart';
import '../../widgets/sub_screen_header.dart';
import 'money_wallets_screen.dart' show MoneyWalletSheet;

// ── expenses (đợt 2) ── stage 3B: Quỹ (design §3.10) + the "Góp vào quỹ"
// sheet.

Future<void> openMoneyGoal(
  BuildContext context, {
  required MoneyBookKind book,
  required String walletId,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: 'MoneyGoal'),
    builder: (_) => MoneyGoalScreen(book: book, walletId: walletId),
  ),
);

/// "dd/MM/yyyy" / "Jan 31, 2027".
String moneyFullDate(BuildContext context, DateTime d) {
  final lang = moneyLang(context);
  return lang == 'vi'
      ? DateFormat('dd/MM/yyyy').format(d)
      : DateFormat.yMMMd(lang).format(d);
}

/// A fund ("Quỹ Đà Lạt"): how full, what to save a month, the history, and Chi từ quỹ · Góp vào quỹ pinned at the
/// bottom (thumb zone, §15 #9).
class MoneyGoalScreen extends StatefulWidget {
  const MoneyGoalScreen({
    super.key,
    required this.book,
    required this.walletId,
  });

  final MoneyBookKind book;
  final String walletId;

  @override
  State<MoneyGoalScreen> createState() => _MoneyGoalScreenState();
}

class _MoneyGoalScreenState extends State<MoneyGoalScreen> {
  /// All-time entries of this wallet from the server (null = loading).
  List<MoneyTx>? _fetched;
  bool _fetchFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<MoneyProvider>().book(widget.book)?.service;
    try {
      if (service == null || !MoneyService.isAvailable) {
        throw StateError('money-offline');
      }
      final rows = await service.fetchWalletTx(widget.walletId);
      if (mounted) setState(() => _fetched = rows);
    } catch (e) {
      debugPrint('money: fund history not loaded: $e');
      if (mounted) setState(() => _fetchFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    money.activeBook = widget.book;
    final shared = widget.book == MoneyBookKind.shared;
    final w = money
        .book(widget.book)
        ?.wallets
        .where((x) => x.id == widget.walletId)
        .firstOrNull;
    final ready = money.balancesReady(widget.book);
    final balance = w == null
        ? 0
        : money.balances(widget.book)[w.id] ?? w.openingBalance;
    final view = w == null
        ? null
        : MoneyGoalView.of(
            w,
            balance,
            money.today,
            step: money.currencyOf(widget.book).roundStep,
          );
    final history = moneyWalletHistory(
      walletId: widget.walletId,
      fetched: _fetched,
      live: money.visibleTxs(widget.book),
      deleting: money.isDeleting,
    );
    final loadingHistory = _fetched == null && !_fetchFailed;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: w == null
          ? null
          : _Actions(
              onSpend: () => AddTransactionSheet.show(
                context,
                book: widget.book,
                walletId: w.id,
              ),
              onContribute: () => MoneyContributeSheet.show(
                context,
                book: widget.book,
                wallet: w,
              ),
            ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SubScreenHeader(
                  badge: (w?.name ?? l10n.moneyGoals).toUpperCase(),
                  badgeIcon: IconsaxPlusLinear.flag,
                  trailing: w == null
                      ? null
                      : HeaderIconButton(
                          icon: IconsaxPlusLinear.edit_2,
                          semanticsLabel: l10n.moneyEditWallet,
                          onTap: () => MoneyWalletSheet.show(
                            context,
                            book: widget.book,
                            editing: w,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: w == null || view == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _GoalCard(
                            wallet: w,
                            view: view,
                            shared: shared,
                            ready: ready,
                          ),
                          const SizedBox(height: 16),
                          MoneyCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                MoneyCardHeader(
                                  title: l10n.moneyGoalHistory,
                                  trailing: loadingHistory || history.isEmpty
                                      ? null
                                      : Text(
                                          l10n.moneyGoalTimes(history.length),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                ),
                                if (_fetchFailed && history.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      l10n.moneyGoalHistoryPartial,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                if (loadingHistory)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: ShimmerSkeleton(height: 44),
                                  )
                                else if (history.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      l10n.moneyGoalHistoryEmpty,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                else
                                  MoneyDayGroups(
                                    txs: history,
                                    ctx: MoneyRowContext.of(
                                      context,
                                      money,
                                      widget.book,
                                      hideWalletId: w.id,
                                    ),
                                    onTapTx: (t) => AddTransactionSheet.show(
                                      context,
                                      book: widget.book,
                                      editing: t,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.wallet,
    required this.view,
    required this.shared,
    required this.ready,
  });

  final MoneyWallet wallet;
  final MoneyGoalView view;
  final bool shared;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reachedAt = wallet.goalReachedAt;
    final String finding;
    if (view.reached) {
      finding = l10n.moneyGoalReached(moneyTripName(wallet.name));
    } else if (view.deadline != null) {
      final date = moneyFullDate(context, moneyParseDate(view.deadline!));
      finding = shared
          ? l10n.moneyGoalLeft(
              vnd(context, view.left),
              date,
              vnd(context, view.perMonth),
            )
          : l10n.moneyGoalLeftMine(
              vnd(context, view.left),
              date,
              vnd(context, view.perMonth),
            );
    } else {
      finding =
          '${l10n.moneyGoalLeftOnly(vnd(context, view.left))} '
          '${l10n.moneyGoalNoDeadline}';
    }
    const meta = TextStyle(fontSize: 12, color: AppColors.textSecondary);
    final percent = view.reached ? 100 : view.percent;
    return MoneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            shared ? l10n.moneyGoalSaved : l10n.moneyGoalSavedMine,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ready
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MoneyAmountText(view.balance, size: 30),
                )
              : const Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerSkeleton(width: 170, height: 30),
                ),
          if (view.target > 0) ...[
            const SizedBox(height: 12),
            Semantics(
              label: l10n.moneyGoalProgress(
                '$percent',
                vndSpoken(context, view.target),
              ),
              child: MoneyGoalBar(percent: ready ? percent : 0, height: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('$percent%', style: meta),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    view.reached && reachedAt != null
                        ? l10n.moneyGoalReachedOn(
                            moneyFullDate(context, reachedAt),
                          )
                        : l10n.moneyGoalTargetOf(vnd(context, view.target)),
                    textAlign: TextAlign.right,
                    style: meta,
                  ),
                ),
              ],
            ),
            if (ready) ...[
              const SizedBox(height: 12),
              Text(
                finding,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Chi từ quỹ (outline) · Góp vào quỹ (navy), 2:3, both h52 (design §11).
class _Actions extends StatelessWidget {
  const _Actions({required this.onSpend, required this.onContribute});

  final VoidCallback onSpend;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: onSpend,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: AppColors.white.withValues(alpha: 0.86),
                  side: BorderSide(
                    color: AppColors.textPrimary.withValues(alpha: 0.18),
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  l10n.moneySpendFromFund,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: MoneyPrimaryButton(
                label: l10n.moneyContribute,
                onPressed: onContribute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "Góp vào quỹ" sheet ────────────────────────────────────────────────────

class _ContributeResult {
  const _ContributeResult(this.message, this.detail, this.undo);

  final String message;
  final String? detail;
  final VoidCallback undo;
}

/// Puts money into a fund. Shared: who put it in (me / the partner) and,
/// when it's me, which of my wallets it left (D11, "Không trừ" to skip).
/// Own book: a transfer from one of my wallets into the fund.
class MoneyContributeSheet extends StatefulWidget {
  const MoneyContributeSheet({
    super.key,
    required this.book,
    required this.wallet,
  });

  final MoneyBookKind book;
  final MoneyWallet wallet;

  static Future<void> show(
    BuildContext context, {
    required MoneyBookKind book,
    required MoneyWallet wallet,
  }) async {
    final r = await showMoneySheet<_ContributeResult>(
      context,
      builder: (_) => MoneyContributeSheet(book: book, wallet: wallet),
    );
    if (r == null || !context.mounted) return;
    showMoneySnack(
      context,
      message: r.message,
      detail: r.detail,
      actionLabel: context.l10n.moneyUndo,
      onAction: r.undo,
    );
  }

  @override
  State<MoneyContributeSheet> createState() => _MoneyContributeSheetState();
}

class _MoneyContributeSheetState extends State<MoneyContributeSheet> {
  final TextEditingController _amount = TextEditingController();
  String? _fromId; // the own wallet the money leaves
  bool _busy = false;

  bool get _shared => widget.book == MoneyBookKind.shared;

  List<MoneyWallet> _ownWallets(MoneyProvider money) => [
    for (final w in money.own?.wallets ?? const <MoneyWallet>[])
      if (!w.archived && !w.isGoal && w.id != widget.wallet.id) w,
  ];

  @override
  void initState() {
    super.initState();
    final money = context.read<MoneyProvider>();
    final list = _ownWallets(money);
    final usual = money.own?.meta.defaultWalletId;
    _fromId = list.any((w) => w.id == usual) ? usual : list.firstOrNull?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int? get _value {
    final r = moneyParse(context, _amount.text);
    return r.ok ? r.value : null;
  }

  Future<void> _save() async {
    final amount = _value;
    final money = context.read<MoneyProvider>();
    final l10n = context.l10n;
    final state = money.book(widget.book);
    if (amount == null || _busy || state == null) return;
    final w = widget.wallet;
    final before = money.balances(widget.book)[w.id] ?? w.openingBalance;
    final id = state.service.newTxId();
    setState(() => _busy = true);
    try {
      final MoneyTx tx;
      final MoneyWriteOutcome outcome;
      final ownWallet = _shared && (_fromId ?? '').isNotEmpty ? _fromId : null;
      if (_shared) {
        tx = MoneyTx(
          id: id,
          type: MoneyTxType.contribution,
          amount: amount,
          date: money.today,
          inWalletId: w.id,
          payer: money.uid,
          memberUids: state.service.memberUids,
        );
        outcome = await money.contribute(
          id: id,
          sharedWalletId: w.id,
          amount: amount,
          date: money.today,
          payer: tx.payer,
          ownWalletId: ownWallet,
        );
      } else {
        final from = _fromId;
        if (from == null || from.isEmpty) return;
        tx = MoneyTx(
          id: id,
          type: MoneyTxType.transfer,
          amount: amount,
          date: money.today,
          outWalletId: from,
          inWalletId: w.id,
        );
        outcome = await money.addTx(widget.book, tx);
      }
      HapticFeedback.lightImpact();
      final uid = money.uid ?? '';
      AnalyticsService.instance.logMoneyTxAdd(
        book: widget.book,
        tx: tx,
        uid: uid,
        categories: state.categories,
        walletType: MoneyWalletType.goal,
        via: 'manual',
        linked: ownWallet != null,
      );
      final target = w.goalTarget ?? 0;
      final full = target > 0 && before < target && before + amount >= target;
      if (full) AnalyticsService.instance.logMoneyGoalReached(widget.book);
      if (!mounted) return;
      final detail = [
        if (full) l10n.moneyContributedFull(w.name),
        if (outcome == MoneyWriteOutcome.queued)
          _shared ? l10n.moneySavedOffline : l10n.moneySavedOfflineMine,
      ].join('\n');
      Navigator.of(context).pop(
        _ContributeResult(
          l10n.moneyContributed(vnd(context, amount), w.name),
          detail.isEmpty ? null : detail,
          () => moneyUndoAdd(money, widget.book, tx),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('money: contribution failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showMoneySnack(context, message: l10n.moneyWriteFailed);
    } catch (e) {
      debugPrint('money: contribution failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showMoneySnack(context, message: l10n.moneyWriteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final amount = _value;
    final own = _ownWallets(money);
    final needsWallet = !_shared && (_fromId == null || _fromId!.isEmpty);
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        s,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(title: l10n.moneyContributeTitle(widget.wallet.name)),
          const SizedBox(height: 8),
          MoneyNumberField(
            controller: _amount,
            big: true,
            autofocus: true,
            max: kMoneyTxMax,
            label: l10n.moneyContributeHint,
            onChanged: (_) => setState(() {}),
          ),
          if (own.isNotEmpty) ...[
            label(_shared ? l10n.moneyDeductMine : l10n.moneyContributeFrom),
            MoneyChipRow(
              children: [
                for (final w in own)
                  MoneyChip(
                    label: w.name,
                    emoji: w.emoji,
                    radio: true,
                    selected: _fromId == w.id,
                    onTap: () => setState(() => _fromId = w.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          MoneyPrimaryButton(
            label: amount == null
                ? l10n.moneySaveNeedAmount
                : needsWallet
                ? l10n.moneySaveNeedWallet
                : l10n.moneyContributeSave(vnd(context, amount)),
            busy: _busy,
            onPressed: amount == null || needsWallet ? null : _save,
          ),
        ],
      ),
    );
  }
}
