import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../widgets/sub_screen_header.dart';
import 'custom_reminders_screen.dart';
import 'milestone_reminders_screen.dart';

/// Merged "Reminders" screen (notifications revamp 2026-06-14).
///
/// Replaces the two separate Settings entries ("Milestones & anniversaries" +
/// "Our reminders") with ONE screen holding both as sections:
/// - top: the curated milestone reminders ([MilestoneRemindersBody]) — the
///   fixed set of milestones with per-milestone toggles + times, plus the
///   default-time tile;
/// - bottom: the user's own custom reminders ([CustomRemindersBody]) — list,
///   add and edit/delete.
///
/// Both sections embed the reusable bodies extracted from the standalone
/// screens, so there's no behaviour drift. The master reminders toggle was
/// removed (milestones auto-remind), so neither section is gated any more.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              SubScreenHeader(
                badge: l10n.remindersHubBadge,
                badgeIcon: IconsaxPlusLinear.notification_bing,
                title: l10n.remindersHubTitle,
                subtitle: l10n.remindersHubSubtitle,
              ),
              const SizedBox(height: 20),
              // ONE flat list (user 2026-06-14 "gộp chung — tất cả đều là lời
              // nhắc"): the curated milestones (pre-seeded, toggle + time) flow
              // straight into the couple's own custom reminders, no section
              // dividers / headers. Milestones keep their auto-computed dates
              // and can't be deleted (toggle only); custom ones add/edit/delete
              // as before. "Gộp hiển thị" — không đổi data-model.
              const MilestoneRemindersBody(),
              const SizedBox(height: 12),
              const CustomRemindersBody(),
            ],
          ),
        ),
      ),
    );
  }
}
