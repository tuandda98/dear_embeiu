import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/custom_reminder.dart';
import '../providers/custom_reminders_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_time_picker.dart';
import '../widgets/content_card.dart';
import '../widgets/sub_screen_header.dart';

/// Add / edit form for a single custom reminder (full screen, push route).
///
/// Pass [existing] to edit; null to create. On success the screen pops `true`
/// so the list can surface a saved/deleted snackbar.
class CustomReminderFormScreen extends StatefulWidget {
  const CustomReminderFormScreen({super.key, this.existing});

  final CustomReminder? existing;

  bool get isEditing => existing != null;

  @override
  State<CustomReminderFormScreen> createState() =>
      _CustomReminderFormScreenState();
}

class _CustomReminderFormScreenState extends State<CustomReminderFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  late DateTime _date;
  late TimeOfDay _time;
  late ReminderRecurrence _recurrence;

  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '')
      ..addListener(_onNameChanged);
    _noteController = TextEditingController(text: existing?.note ?? '');
    if (existing != null) {
      _date = existing.date;
      _time = TimeOfDay(hour: existing.hour, minute: existing.minute);
    } else {
      // ADD mode: default to a clearly-valid near-future moment so the form
      // never opens in the "past date" error state. Today at 20:00 if that is
      // still in the future, otherwise tomorrow at 20:00.
      final now = DateTime.now();
      var defaultWhen = DateTime(now.year, now.month, now.day, 20);
      if (!defaultWhen.isAfter(now)) {
        defaultWhen = defaultWhen.add(const Duration(days: 1));
      }
      _date = defaultWhen;
      _time = TimeOfDay(hour: defaultWhen.hour, minute: defaultWhen.minute);
    }
    _recurrence = existing?.recurrence ?? ReminderRecurrence.once;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final nowValid = _nameController.text.trim().isNotEmpty;
    // Clear the error as soon as a name is typed; rebuild to refresh Save state.
    if (_showNameError && nowValid) {
      setState(() => _showNameError = false);
    } else {
      setState(() {});
    }
  }

  bool get _nameIsEmpty => _nameController.text.trim().isEmpty;

  /// A `once` reminder whose moment is already in the past.
  bool get _isPastOnce {
    if (_recurrence != ReminderRecurrence.once) {
      return false;
    }
    final when = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    return !when.isAfter(DateTime.now());
  }

  bool get _canSave => !_nameIsEmpty && !_isPastOnce;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year - 1)) ? now : _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showAppTimePicker(context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (_nameIsEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    if (_isPastOnce) {
      // Warning already visible under the date tile; block silently.
      return;
    }
    final provider = context.read<CustomRemindersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    if (widget.isEditing) {
      final updated = widget.existing!.copyWith(
        name: _nameController.text.trim(),
        note: _noteController.text.trim(),
        clearNote: _noteController.text.trim().isEmpty,
        date: _date,
        hour: _time.hour,
        minute: _time.minute,
        recurrence: _recurrence,
      );
      await provider.update(updated);
    } else {
      await provider.add(
        name: _nameController.text.trim(),
        note: _noteController.text.trim(),
        date: _date,
        hour: _time.hour,
        minute: _time.minute,
        recurrence: _recurrence,
      );
    }
    if (!mounted) {
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.customRemindersSavedMsg)));
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete() async {
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
          l10n.customRemindersDeleteDialogBody(widget.existing!.name),
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
    if (confirmed != true || !mounted) {
      return;
    }
    final provider = context.read<CustomRemindersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final deletedMsg = context.l10n.customRemindersDeletedMsg;
    await provider.delete(widget.existing!.id);
    if (!mounted) {
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(deletedMsg)));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateLabel =
        DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(_date);
    final timeLabel = _time.format(context);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Header redesign 2026-06-14: no app bar — the SubScreenHeader (back →
        // chip → dynamic title, all left-aligned at the gutter, + the Save
        // action) leads the form. No subtitle, to save room for the keyboard.
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SubScreenHeader(
                  badge: l10n.customReminderFormBadge,
                  badgeIcon: IconsaxPlusLinear.notification_bing,
                  title: widget.isEditing
                      ? l10n.customRemindersEditTitle
                      : l10n.customRemindersAddTitle,
                  trailing: Opacity(
                    opacity: _canSave ? 1 : 0.4,
                    child: TextButton(
                      onPressed: _canSave ? _save : null,
                      child: Text(
                        l10n.customRemindersSave,
                        // Header ink vòng 4 (2026-06-11): navy textPrimary, no
                        // shadow — white-on-blush failed contrast on real shots.
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFormCard(l10n, dateLabel, timeLabel),
                if (widget.isEditing) ...[
                  const SizedBox(height: 24),
                  _buildDeleteSection(l10n),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(AppLocalizations l10n, String dateLabel,
      String timeLabel) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name (required)
          _fieldLabel(
            '${l10n.customRemindersNameLabel} ${l10n.customRemindersNameRequiredMark}',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            maxLength: 40,
            decoration: InputDecoration(
              hintText: l10n.customRemindersNameHint,
              counterText: '',
              prefixIcon: const Icon(
                IconsaxPlusBold.heart,
                color: AppColors.accentRose,
              ),
              errorText:
                  _showNameError ? l10n.customRemindersNameError : null,
            ),
          ),
          const SizedBox(height: 16),

          // Note (optional)
          _fieldLabel(l10n.customRemindersNoteLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLength: 120,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.customRemindersNoteHint,
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),

          // Date + time tiles
          Row(
            children: [
              Expanded(
                child: _pickerTile(
                  icon: IconsaxPlusLinear.calendar,
                  label: l10n.customRemindersDateLabel,
                  value: dateLabel,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pickerTile(
                  icon: IconsaxPlusLinear.clock,
                  label: l10n.customRemindersTimeLabel,
                  value: timeLabel,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          if (_isPastOnce) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.warning_2,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.customRemindersPastDateWarning,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Repeat chips
          _fieldLabel(l10n.customRemindersRepeatLabel),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final recurrence in ReminderRecurrence.values) ...[
                  _repeatChip(recurrence, l10n),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSection(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppColors.textTertiary.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.customRemindersDeleteSectionHint,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppColors.textTertiary.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _confirmDelete,
          icon: const Icon(
            IconsaxPlusLinear.trash,
            color: AppColors.error,
          ),
          label: Text(
            l10n.customRemindersDeleteButton,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.accentRose,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentRose.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.accentRose, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.accentRose,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _repeatChip(ReminderRecurrence recurrence, AppLocalizations l10n) {
    final selected = _recurrence == recurrence;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected ? AppColors.sunsetRomance : null,
        color: selected ? null : AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : AppColors.accentRose.withValues(alpha: 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _recurrence = recurrence),
          borderRadius: BorderRadius.circular(999),
          splashColor: selected
              ? AppColors.white.withValues(alpha: 0.12)
              : AppColors.accentRose.withValues(alpha: 0.08),
          highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              _recurrenceLabel(recurrence, l10n),
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _recurrenceLabel(ReminderRecurrence recurrence, AppLocalizations l10n) {
    switch (recurrence) {
      case ReminderRecurrence.once:
        return l10n.customRemindersRepeatOnce;
      case ReminderRecurrence.daily:
        return l10n.customRemindersRepeatDaily;
      case ReminderRecurrence.weekly:
        return l10n.customRemindersRepeatWeekly;
      case ReminderRecurrence.monthly:
        return l10n.customRemindersRepeatMonthly;
      case ReminderRecurrence.yearly:
        return l10n.customRemindersRepeatYearly;
    }
  }
}
