import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/milestone_reminder.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_time_picker.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/sub_screen_header.dart';

/// Customization screen for the curated automatic reminders (Reminders v2 + Dv8).
///
/// Lists the fixed set of 7 milestones (Dv4) with a per-milestone toggle, a
/// "Next: …" / "Passed" / "Calculated once your anniversary begins" sub-line and
/// (Dv8) a per-milestone time chip. A "Default time" tile at the top sets the
/// fallback time applied to every milestone without its own custom time.
/// Toggling a milestone schedules or cancels just that one via
/// [ReminderProvider.toggleMilestone]; the time chip sets/clears its custom time
/// via [ReminderProvider.setMilestoneTime].
///
/// Milestones auto-remind (2026-06-14: master toggle removed) — there is no more
/// dim-when-off gate. The standalone screen is kept for direct navigation, but
/// the merged [RemindersScreen] embeds [MilestoneRemindersBody] as one section.
class MilestoneRemindersScreen extends StatelessWidget {
  const MilestoneRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Header redesign 2026-06-14: no app bar — the SubScreenHeader (back →
        // chip → title → subtitle, all left-aligned at the gutter) leads the
        // list so the chip lines up vertically with the title.
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SubScreenHeader(
                  badge: l10n.milestoneBadge,
                  badgeIcon: IconsaxPlusLinear.flag,
                  title: l10n.remindersV2MilestoneScreenTitle,
                  subtitle: l10n.milestoneHeaderSubtitle,
                ),
              ),
              const MilestoneRemindersBody(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The milestone-list content (default-time tile + the fixed milestone tiles),
/// extracted so it can render both standalone ([MilestoneRemindersScreen]) and
/// as a section inside the merged [RemindersScreen]. Lays out as a non-scrolling
/// [Column] — the enclosing screen owns the scroll view.
class MilestoneRemindersBody extends StatelessWidget {
  const MilestoneRemindersBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        final order = provider.milestoneOrder;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < order.length; i++) ...[
              EntranceReveal(
                order: i,
                child: _MilestoneTile(type: order[i]),
              ),
              if (i < order.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.type});

  final MilestoneType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.read<ReminderProvider>();
    final enabled = context.select<ReminderProvider, bool>(
      (p) => p.isMilestoneEnabled(type),
    );
    // The milestone's own fire time — each picks its own now (no shared
    // default, user 2026-06-14). Rebuilds when this milestone's time changes.
    final effectiveTime = context.select<ReminderProvider, TimeOfDay>(
      (p) => p.effectiveTimeOf(type),
    );

    final next = provider.nextFireForMilestone(type);
    // Only one-shot milestones can move into the dimmed "Passed" state.
    final isPast = type.isOneShot && next.passed;

    final tile = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentRose.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentRose.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _iconFor(type),
              color: AppColors.accentRose,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(l10n, type),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _descFor(l10n, type),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                _subLine(context, l10n, next, enabled),
                // Per-milestone time chip (Dv8) — only meaningful when the
                // milestone is on, so it's hidden while it's off.
                if (enabled) ...[
                  const SizedBox(height: 6),
                  _TimeChip(type: type, time: effectiveTime),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: enabled,
            activeThumbColor: AppColors.accentRose,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              provider.toggleMilestone(type, value);
            },
          ),
        ],
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      opacity: isPast ? 0.6 : 1,
      child: tile,
    );
  }

  /// Sub-line under the description: "Next: …", "Passed", a static description
  /// (inactivity), or "Calculated once your anniversary begins" (future
  /// anniversary). Hidden styling when the milestone is off (only desc shown).
  Widget _subLine(
    BuildContext context,
    AppLocalizations l10n,
    MilestoneNextFire next,
    bool enabled,
  ) {
    // Inactivity has no concrete date — always a static reminder description.
    if (type == MilestoneType.inactivity) {
      return Text(
        l10n.milestoneInactivitySub,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      );
    }

    if (next.passed) {
      return Text(
        l10n.remindersV2MilestonePast,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        ),
      );
    }

    if (next.pending) {
      return Text(
        l10n.remindersV2MilestonePending,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        ),
      );
    }

    final dateStr = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(next.date!);
    final label = next.label;
    final text = (label != null)
        ? l10n.remindersV2MilestoneNextWithLabel(
            _formatLabel(l10n, label),
            dateStr,
          )
        : l10n.remindersV2MilestoneNext(dateStr);
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.accentRose,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Turn a raw count label into a localized "{n} days" / "{n} years" string.
  /// The yearly milestone supplies a year count; day-count milestones supply a
  /// day count.
  String _formatLabel(AppLocalizations l10n, String raw) {
    final count = int.tryParse(raw) ?? 0;
    if (type == MilestoneType.yearly) {
      return l10n.remindersV2MilestoneYearsLabel(count);
    }
    return l10n.remindersV2MilestoneDaysLabel(count);
  }

  String _titleFor(AppLocalizations l10n, MilestoneType type) {
    switch (type) {
      case MilestoneType.every100:
        return l10n.milestoneEvery100Title;
      case MilestoneType.d520:
        return l10n.milestone520Title;
      case MilestoneType.d1000:
        return l10n.milestone1000Title;
      case MilestoneType.d1314:
        return l10n.milestone1314Title;
      case MilestoneType.halfYear:
        return l10n.milestoneHalfYearTitle;
      case MilestoneType.yearly:
        return l10n.milestoneYearlyTitle;
      case MilestoneType.inactivity:
        return l10n.milestoneInactivityTitle;
    }
  }

  String _descFor(AppLocalizations l10n, MilestoneType type) {
    switch (type) {
      case MilestoneType.every100:
        return l10n.milestoneEvery100Desc;
      case MilestoneType.d520:
        return l10n.milestone520Desc;
      case MilestoneType.d1000:
        return l10n.milestone1000Desc;
      case MilestoneType.d1314:
        return l10n.milestone1314Desc;
      case MilestoneType.halfYear:
        return l10n.milestoneHalfYearDesc;
      case MilestoneType.yearly:
        return l10n.milestoneYearlyDesc;
      case MilestoneType.inactivity:
        return l10n.milestoneInactivityDesc;
    }
  }

  IconData _iconFor(MilestoneType type) {
    switch (type) {
      case MilestoneType.every100:
        return IconsaxPlusLinear.lovely;
      case MilestoneType.d520:
        return IconsaxPlusLinear.magic_star;
      case MilestoneType.d1000:
        return IconsaxPlusLinear.medal_star;
      case MilestoneType.d1314:
        return IconsaxPlusBold.heart;
      case MilestoneType.halfYear:
        return IconsaxPlusLinear.moon;
      case MilestoneType.yearly:
        return IconsaxPlusLinear.cake;
      case MilestoneType.inactivity:
        return IconsaxPlusLinear.camera;
    }
  }
}

/// Per-milestone time chip: each milestone owns its fire time (user 2026-06-14
/// — the shared "default time" tile was dropped). A bold rose "🕐 {time}" pill;
/// tap to pick this milestone's own time.
class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.type, required this.time});

  final MilestoneType type;
  final TimeOfDay time;

  Future<void> _pick(BuildContext context) async {
    final picked = await showAppTimePicker(context, initialTime: time);
    if (picked == null || !context.mounted) {
      return;
    }
    HapticFeedback.selectionClick();
    await context.read<ReminderProvider>().setMilestoneTime(type, picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentRose.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(999),
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconsaxPlusLinear.clock,
                  size: 13, color: AppColors.accentRose),
              const SizedBox(width: 6),
              Text(
                time.format(context),
                style: const TextStyle(
                  color: AppColors.accentRose,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
