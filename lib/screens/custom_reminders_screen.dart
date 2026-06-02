import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/custom_reminder.dart';
import '../providers/custom_reminders_provider.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/shimmer_skeleton.dart';
import 'custom_reminder_form_screen.dart';

/// Manage screen for user-created custom reminders (D1–D9): list / empty /
/// disabled(D7) / limit(D5) states, add via FAB, edit/toggle/swipe-delete.
class CustomRemindersScreen extends StatelessWidget {
  const CustomRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer2<CustomRemindersProvider, ReminderProvider>(
      builder: (context, customProvider, reminderProvider, _) {
        // D7: custom reminders depend on the global reminders feature being on.
        final remindersEnabled = reminderProvider.settings.enabled;
        final reminders = customProvider.reminders;
        final count = customProvider.count;
        final atCapacity = customProvider.isAtCapacity;

        final showFab = remindersEnabled && reminders.isNotEmpty;

        return Container(
          decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  LucideIcons.chevronLeft,
                  color: AppColors.accentRose,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                l10n.customRemindersScreenTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                if (remindersEnabled)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        l10n.customRemindersCount(count),
                        style: TextStyle(
                          color: atCapacity
                              ? AppColors.warning
                              : AppColors.accentRose,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: showFab
                ? FloatingActionButton(
                    tooltip: l10n.customRemindersFabTooltip,
                    backgroundColor: atCapacity
                        ? AppColors.accentLove.withValues(alpha: 0.45)
                        : AppColors.accentLove,
                    onPressed: () => _onAddPressed(context, customProvider),
                    child: const Icon(
                      LucideIcons.plus,
                      color: AppColors.white,
                      size: 26,
                    ),
                  )
                : null,
            body: SafeArea(
              top: false,
              child: _buildBody(
                context,
                customProvider: customProvider,
                remindersEnabled: remindersEnabled,
                reminders: reminders,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required CustomRemindersProvider customProvider,
    required bool remindersEnabled,
    required List<CustomReminder> reminders,
  }) {
    if (!customProvider.isLoaded) {
      // Content-shaped shimmer mirroring the reminder list rows.
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            const ShimmerSkeleton(height: 76, borderRadius: 22),
      );
    }

    if (!remindersEnabled) {
      return _DisabledState(reminders: reminders);
    }

    if (reminders.isEmpty) {
      return _EmptyState(
        onCreate: () => _onAddPressed(context, customProvider),
      );
    }

    return _ReminderList(reminders: reminders);
  }

  void _onAddPressed(
    BuildContext context,
    CustomRemindersProvider provider,
  ) {
    if (provider.isAtCapacity) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.customRemindersLimitMsg)),
        );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const CustomReminderFormScreen(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Empty state
// -----------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: AppColors.dreamyMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bellRing,
                color: AppColors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.customRemindersEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.customRemindersEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentLove,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                icon: const Icon(LucideIcons.plus),
                label: Text(
                  l10n.customRemindersEmptyCta,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Disabled state (D7) — global reminders are off
// -----------------------------------------------------------------------------

class _DisabledState extends StatelessWidget {
  const _DisabledState({required this.reminders});

  final List<CustomReminder> reminders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  LucideIcons.bellOff,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.customRemindersOffTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.customRemindersOffBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentLove,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    l10n.customRemindersOffCta,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Show any existing reminders dimmed beneath the warning (read-only).
        if (reminders.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final reminder in reminders)
            Opacity(
              opacity: 0.55,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReminderCard(reminder: reminder, interactive: false),
              ),
            ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// List state
// -----------------------------------------------------------------------------

class _ReminderList extends StatelessWidget {
  const _ReminderList({required this.reminders});

  final List<CustomReminder> reminders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: reminders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return Dismissible(
          key: ValueKey(reminder.id),
          direction: DismissDirection.endToStart,
          dismissThresholds: const {DismissDirection.endToStart: 0.4},
          movementDuration: const Duration(milliseconds: 220),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(LucideIcons.trash2, color: AppColors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, reminder),
          child: _OnceEntrance(
            order: index,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              opacity: reminder.enabled ? 1 : 0.55,
              child: _ReminderCard(reminder: reminder, interactive: true),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    CustomReminder reminder,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: Text(
          l10n.customRemindersDeleteDialogTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.customRemindersDeleteDialogBody(reminder.name),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.customRemindersCancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.customRemindersDeleteConfirm,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return false;
    }
    final provider = context.read<CustomRemindersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final deletedMsg = l10n.customRemindersDeletedMsg;
    await provider.delete(reminder.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(deletedMsg)));
    return true;
  }
}

// -----------------------------------------------------------------------------
// A single reminder card
// -----------------------------------------------------------------------------

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.interactive});

  final CustomReminder reminder;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.read<CustomRemindersProvider>();

    final timeLabel =
        TimeOfDay(hour: reminder.hour, minute: reminder.minute).format(context);

    return Material(
      color: AppColors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: interactive ? () => _openEdit(context) : null,
        splashColor: AppColors.accentRose.withValues(alpha: 0.12),
        highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                _iconFor(reminder.recurrence),
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
                    reminder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _metaLine(context, l10n, timeLabel),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _nextFireLine(context, l10n, provider),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Switch.adaptive(
                  value: reminder.enabled,
                  activeThumbColor: AppColors.accentRose,
                  onChanged: interactive
                      ? (value) => provider.toggle(reminder.id, value)
                      : null,
                ),
                if (interactive)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      LucideIcons.moreVertical,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => _openMenu(context),
                  ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _nextFireLine(
    BuildContext context,
    AppLocalizations l10n,
    CustomRemindersProvider provider,
  ) {
    if (!reminder.enabled) {
      return Text(
        l10n.customRemindersDisabledLabel,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        ),
      );
    }
    final next = provider.nextFireDateTime(reminder);
    if (next == null) {
      // Past one-off — nothing scheduled.
      return Text(
        l10n.customRemindersDisabledLabel,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        ),
      );
    }
    return Text(
      l10n.customRemindersNextFire(DateFormat.yMMMd().format(next)),
      style: const TextStyle(
        color: AppColors.accentRose,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _metaLine(
    BuildContext context,
    AppLocalizations l10n,
    String timeLabel,
  ) {
    switch (reminder.recurrence) {
      case ReminderRecurrence.once:
        return l10n.customRemindersMetaOnce(
          DateFormat.yMMMd().format(reminder.date),
          timeLabel,
        );
      case ReminderRecurrence.daily:
        return l10n.customRemindersMetaDaily(timeLabel);
      case ReminderRecurrence.weekly:
        return l10n.customRemindersMetaWeekly(
          DateFormat.EEEE().format(reminder.date),
          timeLabel,
        );
      case ReminderRecurrence.monthly:
        return l10n.customRemindersMetaMonthly(reminder.date.day, timeLabel);
      case ReminderRecurrence.yearly:
        return l10n.customRemindersMetaYearly(
          DateFormat.MMMd().format(reminder.date),
          timeLabel,
        );
    }
  }

  IconData _iconFor(ReminderRecurrence recurrence) {
    switch (recurrence) {
      case ReminderRecurrence.once:
        return LucideIcons.pin;
      case ReminderRecurrence.daily:
        return LucideIcons.sun;
      case ReminderRecurrence.weekly:
        return LucideIcons.repeat;
      case ReminderRecurrence.monthly:
        return LucideIcons.calendar;
      case ReminderRecurrence.yearly:
        return LucideIcons.cake;
    }
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => CustomReminderFormScreen(existing: reminder),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  LucideIcons.pencil,
                  color: AppColors.accentRose,
                ),
                title: Text(l10n.customRemindersItemMenuEdit),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEdit(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.error,
                ),
                title: Text(l10n.customRemindersItemMenuDelete),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _deleteFromMenu(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteFromMenu(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: Text(
          l10n.customRemindersDeleteDialogTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.customRemindersDeleteDialogBody(reminder.name),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.customRemindersCancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.customRemindersDeleteConfirm,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final provider = context.read<CustomRemindersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final deletedMsg = l10n.customRemindersDeletedMsg;
    await provider.delete(reminder.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(deletedMsg)));
  }
}

/// Plays the shared fade+slide entrance once, the first time it is mounted,
/// then renders its child statically (the list rebuilds on toggle/delete, so
/// this guard stops the entrance replaying).
class _OnceEntrance extends StatefulWidget {
  const _OnceEntrance({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  State<_OnceEntrance> createState() => _OnceEntranceState();
}

class _OnceEntranceState extends State<_OnceEntrance> {
  bool _played = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      AppMotion.entrance + AppMotion.stagger * widget.order,
      () {
        if (mounted) {
          setState(() => _played = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_played) {
      return widget.child;
    }
    return widget.child
        .animate()
        .fadeIn(duration: AppMotion.entrance, curve: AppMotion.curve)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppMotion.entrance,
          curve: AppMotion.curve,
          delay: AppMotion.stagger * widget.order,
        );
  }
}
