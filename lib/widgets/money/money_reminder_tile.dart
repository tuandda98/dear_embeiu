import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/reminder_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/money_analytics.dart';
import '../../theme/app_colors.dart';
import '../app_time_picker.dart';
import '../icon_badge.dart';

// ── expenses (đợt 2) ── stage 3B: "Nhắc ghi chi tiêu buổi tối" (D18). Same
// mold as the "Nhắc chọn món" tile it sits under in Settings (IconBadge ·
// title 15 w700 · subtitle 12 · switch, then the soft-rose time row), so the
// two read as one family; also opened from Sổ tiền ⋯ → Nhắc tối.
class MoneyReminderTile extends StatelessWidget {
  const MoneyReminderTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.read<ReminderProvider>();
    final enabled = context.select<ReminderProvider, bool>(
      (p) => p.moneyEveningEnabled,
    );
    final time = context.select<ReminderProvider, TimeOfDay>(
      (p) => p.moneyEveningTime,
    );

    Future<void> toggle(bool value) async {
      HapticFeedback.selectionClick();
      final messenger = ScaffoldMessenger.maybeOf(context);
      final granted = await provider.setMoneyEveningEnabled(value);
      AnalyticsService.instance.logMoneyReminderToggle(value && granted);
      if (value && !granted) {
        messenger
          ?..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.remindersPermissionDeniedMsg)),
          );
      }
    }

    Future<void> editTime() async {
      final picked = await showAppTimePicker(context, initialTime: time);
      if (picked == null || !context.mounted) return;
      HapticFeedback.selectionClick();
      await provider.setMoneyEveningTime(picked);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              const IconBadge(IconsaxPlusLinear.wallet_2),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.moneyReminderSettingTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.moneyReminderSettingSubtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: enabled,
                activeThumbColor: AppColors.accentRose,
                onChanged: toggle,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Material(
              color: AppColors.accentRose.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: editTime,
                borderRadius: BorderRadius.circular(16),
                splashColor: AppColors.accentRose.withValues(alpha: 0.08),
                highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.clock,
                        size: 18,
                        color: AppColors.accentRose,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          time.format(context),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
