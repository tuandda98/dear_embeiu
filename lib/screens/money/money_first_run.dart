import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_currency.dart';
import '../../utils/money_input.dart';
import '../../widgets/money/money_currency_sheet.dart';
import '../../widgets/money/money_ui.dart';

/// One starter wallet the first-run screen offers.
class _Pick {
  _Pick(this.type, this.name, this.emoji, {this.fixed = false}) : on = fixed;

  final MoneyWalletType type;
  final String name;
  final String emoji;

  /// "Tiền mặt": always there (D8), its switch is locked on.
  final bool fixed;
  bool on;
  final TextEditingController raw = TextEditingController();

  /// The own book's currency (D31), set by the screen on every build.
  MoneyCurrency currency = MoneyCurrency.vnd;

  VndParseResult get parsed =>
      parseMoneyInput(raw.text, currency: currency, max: kMoneyWalletMax);

  bool get valid => raw.text.trim().isEmpty || parsed.ok;

  /// Credit card: the amount owed is typed positive and stored negative.
  int get balance {
    final v = raw.text.trim().isEmpty || !parsed.ok ? 0 : parsed.value!;
    return type == MoneyWalletType.credit ? -v : v;
  }
}

/// "Tiền của mình đang nằm ở đâu?" (design §3.4): shown once, when the own
/// book has no wallet yet (server-confirmed, D8). Turn on the wallets in
/// use + today's balance; "Bỏ qua" keeps only the starter Cash wallet.
class MoneyFirstRun extends StatefulWidget {
  const MoneyFirstRun({super.key});

  @override
  State<MoneyFirstRun> createState() => _MoneyFirstRunState();
}

class _MoneyFirstRunState extends State<MoneyFirstRun> {
  List<_Pick>? _picks;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;
    _picks ??= [
      _Pick(MoneyWalletType.cash, l10n.moneyWalletCash, '💵', fixed: true),
      _Pick(MoneyWalletType.bank, l10n.moneyWalletBank, '🏦'),
      _Pick(MoneyWalletType.ewallet, 'MoMo', '📱'),
      _Pick(MoneyWalletType.ewallet, 'ZaloPay', '💙'),
      _Pick(MoneyWalletType.credit, l10n.moneyWalletCredit, '💳'),
    ];
  }

  @override
  void dispose() {
    for (final p in _picks ?? const <_Pick>[]) {
      p.raw.dispose();
    }
    super.dispose();
  }

  Future<void> _finish({required bool skip}) async {
    final picks = _picks!;
    setState(() => _busy = true);
    final extra = <MoneyWallet>[
      if (!skip)
        for (var i = 1; i < picks.length; i++)
          if (picks[i].on)
            MoneyWallet(
              id: '',
              name: picks[i].name,
              type: picks[i].type,
              emoji: picks[i].emoji,
              openingBalance: picks[i].balance,
              order: i,
            ),
    ];
    await context.read<MoneyProvider>().ensureDefaultWallet(
      MoneyBookKind.own,
      extra: extra,
      starterBalance: skip ? 0 : picks.first.balance,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final picks = _picks!;
    final currency = context.watch<MoneyProvider>().currencyOf(
      MoneyBookKind.own,
    );
    for (final p in picks) {
      p.currency = currency;
    }
    final total = picks
        .where((p) => p.on)
        .fold<int>(0, (sum, p) => sum + p.balance);
    final valid = picks.every((p) => !p.on || p.valid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.moneyFirstRunTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.moneyFirstRunBody,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary.withValues(alpha: 0.80),
          ),
        ),
        const SizedBox(height: 16),
        // D31: the money this book counts in; only while it is still empty.
        MoneyCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _busy
                ? null
                : () =>
                      showMoneyCurrencySheet(context, book: MoneyBookKind.own),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.moneyCurrencyTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${currency.code} · ${currency.symbol}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        MoneyCard(
          child: Column(
            children: [
              for (var i = 0; i < picks.length; i++) ...[
                if (i > 0) const Divider(),
                _row(l10n, picks[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        MoneyCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.moneyTotalAssets,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              MoneyAmountText(total, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),
        MoneyPrimaryButton(
          label: l10n.moneyFirstRunDone,
          busy: _busy,
          onPressed: valid ? () => _finish(skip: false) : null,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _busy ? null : () => _finish(skip: true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(44, 48),
          ),
          child: Text(
            l10n.moneySkip,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _row(AppLocalizations l10n, _Pick p) {
    final sub = p.fixed
        ? l10n.moneyBuiltIn
        : p.type == MoneyWalletType.credit
        ? l10n.moneyCreditOwed
        : moneyWalletTypeLabel(l10n, p.type);
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: ExcludeSemantics(
                  child: Text(
                    p.emoji,
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
                      p.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: p.fixed ? 0.55 : 1,
                child: Switch.adaptive(
                  value: p.on,
                  onChanged: p.fixed || _busy
                      ? null
                      : (v) => setState(() => p.on = v),
                ),
              ),
            ],
          ),
        ),
        if (p.on)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 8),
            child: MoneyNumberField(
              controller: p.raw,
              label: p.type == MoneyWalletType.credit
                  ? l10n.moneyCreditOwed
                  : l10n.moneyBalanceOf(p.name),
              onChanged: (_) => setState(() {}),
            ),
          ),
      ],
    );
  }
}
