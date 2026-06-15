import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/custom_reminder.dart';
import '../providers/custom_reminders_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';
import 'custom_reminder_form_screen.dart';

/// Manage screen for user-created custom reminders (D1–D9): list / empty /
/// limit(D5) states, add via FAB, edit/toggle/swipe-delete.
///
/// The master-toggle dependency (D7) is gone (2026-06-14: master toggle
/// removed) — custom reminders are always usable, so the disabled state and the
/// force-open gate were dropped. The standalone screen is kept for direct
/// navigation, but the merged [RemindersScreen] embeds [CustomRemindersBody] as
/// one section.
class CustomRemindersScreen extends StatelessWidget {
  const CustomRemindersScreen({super.key});

  /// Push the "create reminder" form, guarding the D5 capacity cap first.
  static void onAddPressed(
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
        settings: const RouteSettings(name: 'CustomReminderForm'),
        builder: (_) => const CustomReminderFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<CustomRemindersProvider>(
      builder: (context, customProvider, _) {
        final reminders = customProvider.reminders;
        final count = customProvider.count;
        final atCapacity = customProvider.isAtCapacity;

        final showFab = reminders.isNotEmpty;

        return Container(
          decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: showFab
                ? FloatingActionButton(
                    tooltip: l10n.customRemindersFabTooltip,
                    backgroundColor: atCapacity
                        ? AppColors.accentLove.withValues(alpha: 0.45)
                        : AppColors.accentLove,
                    onPressed: () => onAddPressed(context, customProvider),
                    child: const Icon(
                      IconsaxPlusLinear.add,
                      color: AppColors.white,
                      size: 26,
                    ),
                  )
                : null,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _ScreenHeader(
                      trailing: _CountBadge(count: count, atCapacity: atCapacity),
                    ),
                  ),
                  Expanded(
                    child: _buildBody(
                      context,
                      customProvider: customProvider,
                      reminders: reminders,
                    ),
                  ),
                ],
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
    required List<CustomReminder> reminders,
  }) {
    if (!customProvider.isLoaded) {
      // Content-shaped shimmer mirroring the reminder list rows.
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            const ShimmerSkeleton(height: 76, borderRadius: 22),
      );
    }

    if (reminders.isEmpty) {
      return _EmptyState(
        onCreate: () => onAddPressed(context, customProvider),
      );
    }

    return _ReminderList(reminders: reminders);
  }
}

/// The custom-reminder content (loading shimmer / empty CTA / list), extracted
/// so it can render both standalone ([CustomRemindersScreen]) and as a section
/// inside the merged [RemindersScreen]. Lays out as a non-scrolling [Column]
/// (the enclosing screen owns the scroll view); the "add" affordance is an
/// inline button rather than a FAB so it sits naturally under the list.
class CustomRemindersBody extends StatelessWidget {
  const CustomRemindersBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomRemindersProvider>(
      builder: (context, customProvider, _) {
        if (!customProvider.isLoaded) {
          return Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                const ShimmerSkeleton(height: 76, borderRadius: 22),
                if (i < 2) const SizedBox(height: 12),
              ],
            ],
          );
        }

        final reminders = customProvider.reminders;
        final atCapacity = customProvider.isAtCapacity;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminders.isEmpty)
              _InlineEmptyState(
                onCreate: () =>
                    CustomRemindersScreen.onAddPressed(context, customProvider),
              )
            else ...[
              for (var i = 0; i < reminders.length; i++) ...[
                _ReminderRow(reminder: reminders[i], order: i),
                if (i < reminders.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 14),
              _AddReminderButton(
                atCapacity: atCapacity,
                onTap: () =>
                    CustomRemindersScreen.onAddPressed(context, customProvider),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A single custom-reminder row with swipe-to-delete + entrance reveal, used by
/// the embedded [CustomRemindersBody].
class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder, required this.order});

  final CustomReminder reminder;
  final int order;

  @override
  Widget build(BuildContext context) {
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
        child: const Icon(IconsaxPlusLinear.trash, color: AppColors.white),
      ),
      confirmDismiss: (_) => _confirmDeleteReminder(context, reminder),
      child: EntranceReveal(
        order: order,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          opacity: reminder.enabled ? 1 : 0.55,
          child: _ReminderCard(reminder: reminder, interactive: true),
        ),
      ),
    );
  }
}

/// Inline empty-state for the embedded body (no full-screen centring — it sits
/// inside the merged scroll view under the section header).
class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accentRose.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: AppColors.dreamyMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.notification_bing,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.customRemindersEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.customRemindersEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentLove,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(IconsaxPlusLinear.add),
              label: Text(
                l10n.customRemindersEmptyCta,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Add another reminder" button shown beneath a non-empty embedded list (the
/// embedded body has no FAB). Dims + warns at the D5 capacity cap.
class _AddReminderButton extends StatelessWidget {
  const _AddReminderButton({required this.atCapacity, required this.onTap});

  final bool atCapacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              atCapacity ? AppColors.warning : AppColors.accentLove,
          side: BorderSide(
            color: (atCapacity ? AppColors.warning : AppColors.accentLove)
                .withValues(alpha: 0.40),
          ),
          backgroundColor: AppColors.white.withValues(alpha: 0.50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: const Icon(IconsaxPlusLinear.add, size: 18),
        label: Text(
          l10n.customRemindersAddAnother,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Page header (vòng 5c)
// -----------------------------------------------------------------------------

/// Landing-style page header (header redesign 2026-06-14): the shared
/// [SubScreenHeader] (back → chip → title → subtitle), with the x/20 counter as
/// a trailing action. Pinned above the state switch so it shows in every state
/// (loading / disabled / empty / list).
class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SubScreenHeader(
        badge: l10n.customRemindersBadge,
        badgeIcon: IconsaxPlusLinear.notification_bing,
        title: l10n.customRemindersScreenTitle,
        subtitle: l10n.customRemindersHeaderSubtitle,
        trailing: trailing,
      ),
    );
  }
}

/// The x/20 reminder counter shown as the header's trailing action. Navy
/// textPrimary by default; warning when at capacity (header ink vòng 4 — white
/// on blush failed contrast; warning stays semantic at capacity).
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.atCapacity});

  final int count;
  final bool atCapacity;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.customRemindersCount(count),
      style: TextStyle(
        color: atCapacity ? AppColors.warning : AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
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
                IconsaxPlusLinear.notification_bing,
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
                icon: const Icon(IconsaxPlusLinear.add),
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
// List state
// -----------------------------------------------------------------------------

class _ReminderList extends StatelessWidget {
  const _ReminderList({required this.reminders});

  final List<CustomReminder> reminders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
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
            child: const Icon(IconsaxPlusLinear.trash, color: AppColors.white),
          ),
          confirmDismiss: (_) => _confirmDeleteReminder(context, reminder),
          child: EntranceReveal(
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
}

/// Confirm + perform a custom-reminder delete (shared by the standalone list's
/// swipe-to-delete, the embedded body row and the overflow menu). Returns
/// whether the reminder was actually removed.
Future<bool> _confirmDeleteReminder(
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
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
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
                      IconsaxPlusLinear.more_2,
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
    final locale = Localizations.localeOf(context).toString();
    return Text(
      l10n.customRemindersNextFire(DateFormat.yMMMd(locale).format(next)),
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
    final locale = Localizations.localeOf(context).toString();
    switch (reminder.recurrence) {
      case ReminderRecurrence.once:
        return l10n.customRemindersMetaOnce(
          DateFormat.yMMMd(locale).format(reminder.date),
          timeLabel,
        );
      case ReminderRecurrence.daily:
        return l10n.customRemindersMetaDaily(timeLabel);
      case ReminderRecurrence.weekly:
        return l10n.customRemindersMetaWeekly(
          DateFormat.EEEE(locale).format(reminder.date),
          timeLabel,
        );
      case ReminderRecurrence.monthly:
        return l10n.customRemindersMetaMonthly(reminder.date.day, timeLabel);
      case ReminderRecurrence.yearly:
        return l10n.customRemindersMetaYearly(
          DateFormat.MMMd(locale).format(reminder.date),
          timeLabel,
        );
    }
  }

  IconData _iconFor(ReminderRecurrence recurrence) {
    switch (recurrence) {
      case ReminderRecurrence.once:
        return IconsaxPlusLinear.location;
      case ReminderRecurrence.daily:
        return IconsaxPlusLinear.sun_1;
      case ReminderRecurrence.weekly:
        return IconsaxPlusLinear.refresh_2;
      case ReminderRecurrence.monthly:
        return IconsaxPlusLinear.calendar;
      case ReminderRecurrence.yearly:
        return IconsaxPlusLinear.cake;
    }
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(name: 'CustomReminderForm'),
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
                  IconsaxPlusLinear.edit_2,
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
                  IconsaxPlusLinear.trash,
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
    await _confirmDeleteReminder(context, reminder);
  }
}
