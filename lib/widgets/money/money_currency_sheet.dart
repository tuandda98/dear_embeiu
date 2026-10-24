import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/money.dart';
import '../../providers/money_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_currency.dart';
import 'money_ui.dart';

/// "Tiền tệ" (D31): pick the currency [book] counts in. Only an empty book
/// may switch (nothing is converted); otherwise the list is read-only with
/// a line saying why.
Future<void> showMoneyCurrencySheet(
  BuildContext context, {
  required MoneyBookKind book,
}) {
  return showMoneySheet<void>(
    context,
    name: 'MoneyCurrencySheet',
    builder: (sheet) => _CurrencySheet(book: book),
  );
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _CurrencySheet extends StatefulWidget {
  const _CurrencySheet({required this.book});

  final MoneyBookKind book;

  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  bool _busy = false;

  Future<void> _pick(MoneyProvider money, MoneyCurrency c) async {
    setState(() => _busy = true);
    try {
      await money.setCurrency(widget.book, c.code);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('money: set currency failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      showMoneySnack(context, message: context.l10n.moneyWriteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.watch<MoneyProvider>();
    final current = money.currencyOf(widget.book);
    final canChange = money.canChangeCurrency(widget.book);
    final vi = moneyLang(context) == 'vi';
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(
              l10n.moneyCurrencyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              children: [
                for (final c in MoneyCurrency.all)
                  ListTile(
                    minTileHeight: 52,
                    enabled: (canChange && !_busy) || c == current,
                    leading: SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          c.symbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            // Greyed like the title when the book is locked.
                            color: canChange || c == current
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(c.code),
                    subtitle: Text(_cap(vi ? c.viName : c.enName)),
                    trailing: c == current
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.textPrimary,
                          )
                        : null,
                    selected: c == current,
                    selectedColor: AppColors.textPrimary,
                    onTap: !canChange || _busy || c == current
                        ? null
                        : () => _pick(money, c),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
