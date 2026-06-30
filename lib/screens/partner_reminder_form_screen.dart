import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/custom_reminder.dart';
import '../models/partner_reminder.dart';
import '../providers/partner_reminder_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_time_picker.dart';
import '../widgets/content_card.dart';
import '../widgets/sub_screen_header.dart';

/// Add / edit form for a single partner reminder (full-screen push route).
///
/// Pass [existing] to edit (only the author reaches this), null to create. On
/// success pops `true` so the list can surface a saved/deleted snackbar.
class PartnerReminderFormScreen extends StatefulWidget {
  const PartnerReminderFormScreen({super.key, this.existing});

  final PartnerReminder? existing;

  bool get isEditing => existing != null;

  @override
  State<PartnerReminderFormScreen> createState() =>
      _PartnerReminderFormScreenState();
}

class _PartnerReminderFormScreenState extends State<PartnerReminderFormScreen> {
  late final TextEditingController _textController;

  late DateTime _date;
  late TimeOfDay _time;
  late ReminderRecurrence _recurrence;

  bool _showTextError = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _textController = TextEditingController(text: existing?.text ?? '')
      ..addListener(_onTextChanged);
    if (existing != null) {
      _date = existing.date;
      _time = TimeOfDay(hour: existing.hour, minute: existing.minute);
      _recurrence = existing.recurrence;
    } else {
      final now = DateTime.now();
      var defaultWhen = DateTime(now.year, now.month, now.day, 20);
      if (!defaultWhen.isAfter(now)) {
        defaultWhen = defaultWhen.add(const Duration(days: 1));
      }
      _date = defaultWhen;
      _time = TimeOfDay(hour: defaultWhen.hour, minute: defaultWhen.minute);
      // Daily is the natural default for "remind my person" (medicine, sleep…).
      _recurrence = ReminderRecurrence.daily;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final nowValid = _textController.text.trim().isNotEmpty;
    if (_showTextError && nowValid) {
      setState(() => _showTextError = false);
    } else {
      setState(() {});
    }
  }

  bool get _textIsEmpty => _textController.text.trim().isEmpty;

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

  bool get _canSave => !_textIsEmpty && !_isPastOnce;

  int get _minuteOfDay => _time.hour * 60 + _time.minute;

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
    if (_textIsEmpty) {
      setState(() => _showTextError = true);
      return;
    }
    if (_isPastOnce) {
      return;
    }
    final provider = context.read<PartnerReminderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final text = _textController.text.trim();

    if (widget.isEditing) {
      await provider.updateReminder(
        widget.existing!.copyWith(
          text: text,
          minuteOfDay: _minuteOfDay,
          recurrence: _recurrence,
          date: _date,
        ),
      );
    } else {
      await provider.addReminder(
        text: text,
        minuteOfDay: _minuteOfDay,
        recurrence: _recurrence,
        date: _date,
      );
    }
    if (!mounted) {
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.partnerReminderSavedToast)));
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final provider = context.read<PartnerReminderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final deletedMsg = context.l10n.partnerReminderDeletedToast;
    await provider.deleteReminder(widget.existing!.id);
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SubScreenHeader(
                  badge: l10n.partnerReminderFormBadge,
                  badgeIcon: IconsaxPlusLinear.notification_bing,
                  title: widget.isEditing
                      ? l10n.partnerReminderFormEditTitle
                      : l10n.partnerReminderFormAddTitle,
                  trailing: Opacity(
                    opacity: _canSave ? 1 : 0.4,
                    child: TextButton(
                      onPressed: _canSave ? _save : null,
                      child: Text(
                        l10n.customRemindersSave,
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
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(
                      IconsaxPlusLinear.trash,
                      color: AppColors.error,
                    ),
                    label: Text(
                      l10n.partnerReminderDeleteButton,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(
      AppLocalizations l10n, String dateLabel, String timeLabel) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(l10n.partnerReminderTextLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: l10n.partnerReminderTextHint,
              counterText: '',
              prefixIcon: const Icon(
                IconsaxPlusBold.heart,
                color: AppColors.accentRose,
              ),
              errorText:
                  _showTextError ? l10n.partnerReminderTextError : null,
            ),
          ),
          const SizedBox(height: 16),
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
              partnerReminderRecurrenceLabel(recurrence, l10n),
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
}

/// Shared recurrence → localized label (reuses the custom-reminder strings).
String partnerReminderRecurrenceLabel(
    ReminderRecurrence recurrence, AppLocalizations l10n) {
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
