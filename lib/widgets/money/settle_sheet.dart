import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_l10n.dart';
import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/money_analytics.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_flows.dart';
import '../../utils/money_input.dart';
import '../../utils/money_math.dart';
import 'money_ui.dart';

// ── expenses (đợt 2) ── stage 3B: "Thanh toán" (design §3.11 + §15 #11).

class _SettleResult {
  const _SettleResult(this.message, this.detail, this.undo);

  final String message;
  final String? detail;

  /// null = nothing was written (already even when re-checked).
  final VoidCallback? undo;
}

/// Who pays whom back and how much (all of it / half / a typed part), the
/// "Ghi tiền về ví của mình" switch (on by default, Lead) + wallet chips,
/// and the proof card "Vì sao là 359.000 ₫". Writes a `settle` (+ an own
/// `adjust` when the switch is on) — never spending.
class SettleSheet extends StatefulWidget {
  const SettleSheet({super.key});

  /// Opens the sheet when the shared book isn't even (no-op otherwise).
  static Future<void> show(BuildContext context) async {
    final money = context.read<MoneyProvider>();
    final balance = money.coupleBalance();
    if (balance == null || balance == 0 || money.uid == null) return;
    final r = await showMoneySheet<_SettleResult>(
      context,
      builder: (_) => const SettleSheet(),
    );
    if (r == null || !context.mounted) return;
    showMoneySnack(
      context,
      message: r.message,
      detail: r.detail,
      actionLabel: r.undo == null ? null : context.l10n.moneyUndo,
      onAction: r.undo,
      duration: r.undo == null
          ? const Duration(seconds: 4)
          : MoneyProvider.deleteDelay,
    );
  }

  @override
  State<SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<SettleSheet> {
  final TextEditingController _amount = TextEditingController();
  late int _balance;
  late ({String payer, int amount}) _plan;
  bool _toOwn = true;
  String? _walletId;
  bool _busy = false;

  /// Inline line above the button: the re-check found a new number, or
  /// couldn't reach the server (Tester Med — no settle on a cached number).
  String? _notice;

  MoneyProvider get _money => context.read<MoneyProvider>();
  bool get _partnerPays => _plan.payer != _money.uid;

  List<MoneyWallet> _ownWallets(MoneyProvider money) => [
    for (final w in money.own?.wallets ?? const <MoneyWallet>[])
      if (!w.archived && !w.isGoal) w,
  ];

  @override
  void initState() {
    super.initState();
    final money = _money;
    _balance = money.coupleBalance() ?? 0;
    _plan = MoneyMath.settlementFor(
      _balance,
      me: money.uid ?? '',
      partner: money.partnerUid,
    )!;
    _amount.text = _grouped(_plan.amount);
    // The wallet I usually pay shared things with, else the default one.
    final wallets = _ownWallets(money);
    final usual = (money.own?.txs ?? const <MoneyTx>[])
        .where((t) => t.linkId != null)
        .map((t) => t.outWalletId.isNotEmpty ? t.outWalletId : t.inWalletId)
        .where((id) => wallets.any((w) => w.id == id))
        .firstOrNull;
    final fallback = money.own?.meta.defaultWalletId;
    _walletId =
        usual ??
        (wallets.any((w) => w.id == fallback) ? fallback : null) ??
        wallets.firstOrNull?.id;
    _toOwn = _walletId != null;
    // Opened on a cached number: fetch the server's now, Save waits for it.
    if (money.shared?.netSumsStale ?? false) {
      unawaited(money.refreshCoupleBalance());
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// `170.000` / `170,000` in the field, like every other amount on screen
  /// (parseVndInput reads both back). AppL10n, not context: also runs in
  /// initState, where Localizations can't be looked up yet.
  String _grouped(int v) =>
      NumberFormat.decimalPattern(AppL10n.strings.localeName).format(v);

  int? get _value {
    final r = parseVndInput(_amount.text, max: kMoneyTxMax);
    return r.ok ? r.value : null;
  }

  void _set(int v) {
    HapticFeedback.selectionClick();
    setState(() => _amount.text = _grouped(v));
  }

  /// Re-reads the balance from the server. true = still [_plan]; otherwise
  /// the sheet shows the new number (or "no network") and nothing is
  /// written. Already even → closes with a note.
  Future<bool> _recheck() async {
    final money = _money;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _notice = null;
    });
    final fresh = await money.refreshCoupleBalance();
    if (!mounted) return false;
    final plan = fresh == null
        ? null
        : MoneyMath.settlementFor(
            fresh,
            me: money.uid ?? '',
            partner: money.partnerUid,
          );
    if (fresh == null) {
      setState(() {
        _busy = false;
        _notice = l10n.moneySettleOffline;
      });
      return false;
    }
    if (plan == null) {
      Navigator.of(
        context,
      ).pop(_SettleResult(l10n.moneySettleAlreadyEven, null, null));
      return false;
    }
    if (plan == _plan) return true;
    setState(() {
      _busy = false;
      _balance = fresh;
      _plan = plan;
      _amount.text = _grouped(plan.amount);
      _notice = l10n.moneySettleChanged(vnd(context, plan.amount));
    });
    return false;
  }

  /// Button while the sums are a cached copy: fetch, don't write.
  Future<void> _resync() async {
    if (_busy) return;
    if (await _recheck() && mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    final amount = _value;
    final money = _money;
    final shared = money.shared;
    if (amount == null || amount > _plan.amount || _busy || shared == null) {
      return;
    }
    final l10n = context.l10n;
    final people = MoneyPeople.of(context, listen: false);
    // Both phones may "Trả hết" from the same number, or this one may hold
    // an old one: re-read the server's sums right before writing and only
    // settle what is still owed (Tester Med).
    if (!await _recheck()) return;
    if (!mounted) return;
    final ownWallet = _toOwn ? _walletId : null;
    final id = shared.service.newTxId();
    final tx = MoneyTx(
      id: id,
      type: MoneyTxType.settle,
      amount: amount,
      date: money.today,
      payer: _plan.payer,
      splitMode: MoneySplitMode.none,
      memberUids: shared.service.memberUids,
    );
    try {
      await money.settle(
        id: id,
        payer: _plan.payer,
        amount: amount,
        date: money.today,
        ownWalletId: ownWallet,
      );
      HapticFeedback.lightImpact();
      AnalyticsService.instance.logMoneySettle();
      if (!mounted) return;
      final a = vnd(context, amount);
      final walletName = ownWallet == null
          ? null
          : MoneyRowContext.of(
              context,
              money,
              MoneyBookKind.own,
              listen: false,
            ).walletName(ownWallet);
      final detail = [
        if (walletName != null)
          _partnerPays
              ? l10n.moneySettledIn(walletName, a)
              : l10n.moneySettledOut(walletName, a),
        amount == _plan.amount
            ? l10n.moneySettledEven
            : l10n.moneySettledLeft(vnd(context, _plan.amount - amount)),
      ].join(' · ');
      Navigator.of(context).pop(
        _SettleResult(
          _partnerPays
              ? l10n.moneySettledThem(people.partnerName, a)
              : l10n.moneySettledMe(people.partnerName, a),
          detail,
          () => moneyUndoAdd(money, MoneyBookKind.shared, tx),
        ),
      );
    } catch (e) {
      debugPrint('money: settle failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showMoneySnack(context, message: l10n.moneyWriteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final people = MoneyPeople.of(context);
    final owed = _plan.amount;
    final half = moneySettleHalf(owed);
    final value = _value;
    final wallets = _ownWallets(money);
    final from = _partnerPays
        ? MoneyAvatar(letter: people.partnerName, color: people.partnerColor)
        : MoneyAvatar(letter: people.myName, color: people.meColor);
    final to = _partnerPays
        ? MoneyAvatar(letter: people.myName, color: people.meColor)
        : MoneyAvatar(letter: people.partnerName, color: people.partnerColor);
    final stale = money.shared?.netSumsStale ?? true;
    final String saveLabel;
    if (stale && !_busy) {
      saveLabel = l10n.moneySettleNeedSync;
    } else if (value == null) {
      saveLabel = l10n.moneySaveNeedAmount;
    } else if (value > owed) {
      saveLabel = l10n.moneySettleTooMuch(vnd(context, owed));
    } else {
      saveLabel = l10n.moneySettleDo;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneySheetTitle(title: l10n.moneySettle),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              from,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _partnerPays
                      ? l10n.moneySettlePaysMe(people.partnerName)
                      : l10n.moneySettlePaysPartner(people.partnerName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              to,
            ],
          ),
          const SizedBox(height: 12),
          MoneyNumberField(
            controller: _amount,
            big: true,
            max: kMoneyTxMax,
            label: l10n.moneyAmountLabel,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.moneySettlePartial,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              MoneyChip(
                label: l10n.moneySettleAll,
                radio: true,
                selected: value == owed,
                onTap: () => _set(owed),
              ),
              if (owed > 1)
                MoneyChip(
                  label: l10n.moneySettleHalf(vnd(context, half)),
                  radio: true,
                  selected: value == half,
                  onTap: () => _set(half),
                ),
            ],
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: 12),
            MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _partnerPays
                              ? l10n.moneySettleToOwn
                              : l10n.moneyDeductMine,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _partnerPays
                              ? l10n.moneySettleToOwnSub
                              : l10n.moneySettleFromOwnSub,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _toOwn,
                    activeThumbColor: AppColors.accentRose,
                    onChanged: (v) => setState(() => _toOwn = v),
                  ),
                ],
              ),
            ),
            if (_toOwn) ...[
              const SizedBox(height: 4),
              MoneyChipRow(
                children: [
                  for (final w in wallets)
                    MoneyChip(
                      label: w.name,
                      emoji: w.emoji,
                      radio: true,
                      selected: _walletId == w.id,
                      onTap: () => setState(() => _walletId = w.id),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            _partnerPays
                ? l10n.moneySettleNoteThem(people.partnerName)
                : l10n.moneySettleNoteMe(people.partnerName),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (_notice != null) ...[
            const SizedBox(height: 12),
            // Inline, next to the button it is about; read out when it shows.
            Semantics(
              liveRegion: true,
              child: Text(
                _notice!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          MoneyPrimaryButton(
            label: saveLabel,
            busy: _busy,
            onPressed: stale
                ? _resync
                : value == null || value > owed
                ? null
                : _save,
          ),
          const SizedBox(height: 20),
          _WhyCard(balance: _balance),
        ],
      ),
    );
  }
}

/// "Vì sao là 359.000 ₫": the entries behind the balance, signed from my
/// side. The live window only holds ~45 days; anything older is one line
/// "Các khoản trước …" so the lines always add up to the balance.
class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final people = MoneyPeople.of(context);
    final uid = money.uid ?? '';
    final shared = money.shared;
    final txs = money.visibleTxs(MoneyBookKind.shared);
    final parts = moneySettleParts(txs, uid);
    final sum = parts.fold<int>(0, (s, p) => s + p.signed);
    final earlier = balance - sum;
    final treats = moneyTreatCount(txs);
    final ctx = MoneyRowContext.of(context, money, MoneyBookKind.shared);

    String signed(int v) => '${v > 0 ? '+' : '−'}${vnd(context, v.abs())}';

    Widget line(Widget avatar, String title, String sub, int v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: MergeSemantics(
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              signed(v),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.moneySettleWhy(vnd(context, balance.abs())),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            treats > 0
                ? l10n.moneySettleLegend(people.partnerName, treats)
                : l10n.moneySettleLegendNoTreat(people.partnerName),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          if (earlier != 0)
            line(
              const MoneyAvatar(letter: '…'),
              l10n.moneySettleEarlier(
                moneyShortDate(context, shared?.windowFrom ?? money.today),
              ),
              '',
              earlier,
            ),
          for (final p in parts)
            line(
              ctx.avatarFor(p.tx.payer),
              p.tx.note.trim().isNotEmpty
                  ? p.tx.note.trim()
                  : p.tx.type == MoneyTxType.settle
                  ? l10n.moneySettle
                  : ctx.categories.of(p.tx.categoryId).name,
              p.tx.type == MoneyTxType.settle
                  ? l10n.moneySettleRowBack(
                      moneyShortDate(context, p.tx.date),
                      ctx.personName(context, p.tx.payer),
                    )
                  : l10n.moneySettleRowSub(
                      moneyShortDate(context, p.tx.date),
                      ctx.personName(context, p.tx.payer),
                      moneySplitLabel(l10n, p.tx.splitMode),
                    ),
              p.signed,
            ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.moneySettleSum,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                signed(balance),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Hoàn tác" right after a write (§15 #8): the entry (and its own-book
/// half) leave at once, the delete goes out after the undo window.
Future<void> moneyUndoAdd(
  MoneyProvider money,
  MoneyBookKind kind,
  MoneyTx draft,
) async {
  final stored =
      money.book(kind)?.txs.where((t) => t.id == draft.id).firstOrNull ?? draft;
  final linked = await money.linkedOf(kind, stored);
  money.scheduleDelete(kind, stored, alsoLinked: linked);
}
