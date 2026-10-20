import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_notification.dart';

// ── expenses (đợt 2) ── stage 3B: inbox lines of the three Sổ tiền types,
// the same sentences as the `notifyMoney` push (overview §5), never an
// amount. null = not a money type.
({String title, String? subtitle})? moneyInboxText(
  AppNotification n,
  AppLocalizations l10n,
) {
  final wallet = [?n.walletEmoji, ?n.walletName].join(' ');
  switch (n.type) {
    case AppNotificationType.moneyGoal:
      return (
        title: l10n.moneyNotifGoal(
          n.actorName.isNotEmpty ? n.actorName : l10n.reactionPartnerFallback,
          '${n.percent ?? 0}',
        ),
        subtitle: wallet.isEmpty ? null : wallet,
      );
    case AppNotificationType.moneyGoalReached:
      return (
        title: l10n.moneyNotifGoalReached(
          wallet.isEmpty ? l10n.moneyGoals : wallet,
        ),
        subtitle: l10n.moneyNotifGoalReachedSub,
      );
    case AppNotificationType.moneyBudget:
      final month = n.month;
      return (
        title: (n.level ?? 80) >= 100
            ? l10n.moneyNotifBudget100
            : l10n.moneyNotifBudget80,
        subtitle: month == null
            ? null
            : l10n.moneyNotifBudgetSub(_monthLabel(month, l10n.localeName)),
      );
    default:
      return null;
  }
}

/// "10/2026" / "October 2026" from 'YYYY-MM'.
String _monthLabel(String month, String locale) {
  final y = int.tryParse(month.length >= 4 ? month.substring(0, 4) : '');
  final m = int.tryParse(month.length >= 7 ? month.substring(5, 7) : '');
  if (y == null || m == null) return month;
  return locale.startsWith('vi')
      ? '$m/$y'
      : DateFormat('MMMM y', locale).format(DateTime(y, m));
}
