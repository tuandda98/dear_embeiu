import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/milestone_reminder.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/sub_screen_app_bar.dart';

/// Customization screen for the curated automatic reminders (Reminders v2 + Dv8).
///
/// Lists the fixed set of 7 milestones (Dv4) with a per-milestone toggle, a
/// "Next: …" / "Passed" / "Calculated once your anniversary begins" sub-line and
/// (Dv8) a per-milestone time chip. A "Default time" tile at the top sets the
/// fallback time applied to every milestone without its own custom time.
/// Toggling a milestone schedules or cancels just that one via
/// [ReminderProvider.toggleMilestone]; the time chip sets/clears its custom time
/// via [ReminderProvider.setMilestoneTime]. The list is reached only while the
/// master reminders toggle is on (entry tile is dimmed when off).
class MilestoneRemindersScreen extends StatelessWidget {
  const MilestoneRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Header vòng 5c (2026-06-11): the bar keeps only the back squircle —
        // the landing-style large header (EyebrowChip + pageTitle + subtitle)
        // is the first list item and scrolls with the content, like Settings.
        appBar: subScreenAppBar(context),
        body: SafeArea(
          top: false,
          child: Consumer<ReminderProvider>(
            builder: (context, provider, _) {
              final order = provider.milestoneOrder;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EyebrowChip(
                        label: l10n.milestoneBadge,
                        icon: LucideIcons.flag,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.remindersV2MilestoneScreenTitle,
                        style: AppTheme.pageTitleStyle(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.milestoneHeaderSubtitle,
                        style: AppTheme.pageSubtitleStyle(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  const _DefaultTimeTile(),
                  const SizedBox(height: 12),
                  for (var i = 0; i < order.length; i++) ...[
                    EntranceReveal(
                      order: i,
                      child: _MilestoneTile(type: order[i]),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Default reminder time tile (Dv8). Tapping opens the native time picker and
/// updates [ReminderProvider.setTime], which reschedules every milestone that
/// follows the default (i.e. has no custom time of its own).
class _DefaultTimeTile extends StatelessWidget {
  const _DefaultTimeTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.select<ReminderProvider, ReminderSettings>(
      (p) => p.settings,
    );
    final time = TimeOfDay(hour: settings.hour, minute: settings.minute);

    Future<void> pick() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: time,
      );
      if (picked == null || !context.mounted) {
        return;
      }
      HapticFeedback.selectionClick();
      // The provider reschedules using the couple inputs cached by the last
      // sync (reminders are on to reach this screen), so no couple data is
      // needed here.
      await context.read<ReminderProvider>().setTime(picked.hour, picked.minute);
    }

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.accentLavender.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentLavender.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.clock,
                color: AppColors.accentLavender,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsDefaultTimeLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.settingsDefaultTimeSubtitle,
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
            Text(
              time.format(context),
              style: const TextStyle(
                color: AppColors.accentRose,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: pick,
              borderRadius: BorderRadius.circular(22),
              splashColor: AppColors.accentRose.withValues(alpha: 0.08),
              highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
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
    // Rebuild the chip when this milestone's custom time changes.
    final customTime = context.select<ReminderProvider, TimeOfDay?>(
      (p) => p.milestoneTimeOf(type),
    );
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
                  _TimeChip(
                    type: type,
                    customTime: customTime,
                    effectiveTime: effectiveTime,
                  ),
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
        return LucideIcons.infinity;
      case MilestoneType.d520:
        return LucideIcons.sparkles;
      case MilestoneType.d1000:
        return LucideIcons.award;
      case MilestoneType.d1314:
        return Icons.favorite_rounded;
      case MilestoneType.halfYear:
        return LucideIcons.moon;
      case MilestoneType.yearly:
        return LucideIcons.cake;
      case MilestoneType.inactivity:
        return LucideIcons.camera;
    }
  }
}

/// Per-milestone time chip (Dv8).
///
/// - Following the default ([customTime] == null): a muted "Default · {time}"
///   chip; tapping opens the time picker (seeded with the default) to set a
///   custom time.
/// - Custom time set ([customTime] != null): a bold rose "{time} ✕" chip;
///   tapping the time changes it, tapping ✕ clears it back to the default.
class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.type,
    required this.customTime,
    required this.effectiveTime,
  });

  final MilestoneType type;
  final TimeOfDay? customTime;
  final TimeOfDay effectiveTime;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: effectiveTime,
    );
    if (picked == null || !context.mounted) {
      return;
    }
    await context.read<ReminderProvider>().setMilestoneTime(type, picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasCustom = customTime != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.accentRose
            .withValues(alpha: hasCustom ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Material(
        color: Colors.transparent,
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
                Icon(
                  LucideIcons.clock,
                  size: 13,
                  color:
                      hasCustom ? AppColors.accentRose : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                if (hasCustom) ...[
                  Text(
                    customTime!.format(context),
                    style: const TextStyle(
                      color: AppColors.accentRose,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Reset-to-default control. Larger hit area for tap comfort.
                  Semantics(
                    button: true,
                    label: l10n.settingsMilestoneCustomTimeReset,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      splashColor:
                          AppColors.accentRose.withValues(alpha: 0.08),
                      onTap: () => context
                          .read<ReminderProvider>()
                          .setMilestoneTime(type, null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Icon(
                          LucideIcons.x,
                          size: 14,
                          color: AppColors.accentRose.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ] else
                  Text(
                    l10n.settingsMilestoneUsesDefault(
                        effectiveTime.format(context)),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
