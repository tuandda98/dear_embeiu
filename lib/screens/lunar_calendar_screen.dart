import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_colors.dart';
import '../utils/lunar_calendar.dart';
import '../widgets/app_time_picker.dart';
import '../widgets/content_card.dart';
import '../widgets/section_header.dart';
import '../widgets/sub_screen_header.dart';

/// Full lunar-calendar screen (account-gated, 2026-06-19): a month grid showing
/// each day's solar + lunar date, plus the editable reminder config — which
/// lunar days to remind on and at what times. Reached from the Settings "Lịch
/// âm" card. Pure local; reads/writes [ReminderProvider].
class LunarCalendarScreen extends StatefulWidget {
  const LunarCalendarScreen({super.key});

  @override
  State<LunarCalendarScreen> createState() => _LunarCalendarScreenState();
}

class _LunarCalendarScreenState extends State<LunarCalendarScreen> {
  late DateTime _month; // first day of the displayed month

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubScreenHeader(
                  badge: l10n.lunarCalendarBadge,
                  badgeIcon: IconsaxPlusLinear.moon,
                ),
                const SizedBox(height: 20),
                _MonthCalendarCard(
                  month: _month,
                  onPrev: () => _shiftMonth(-1),
                  onNext: () => _shiftMonth(1),
                ),
                const SizedBox(height: 24),
                const _LunarReminderConfigCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The month grid: weekday header + day cells (solar big, lunar small). Today is
/// ringed; days that match a chosen reminder day get a rose dot.
class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final reminderDays = context.watch<ReminderProvider>().lunarDays.toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first grid (VN convention): weekday Mon=1..Sun=7 → 0..6.
    final leading = DateTime(month.year, month.month, 1).weekday - 1;

    // Localized short weekday names, Monday-first (2024-01-01 was a Monday).
    final weekdays = List<String>.generate(
      7,
      (i) => DateFormat.E(locale).format(DateTime(2024, 1, 1 + i)),
    );

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final lunar = LunarCalendar.fromSolar(date);
      cells.add(
        _DayCell(
          solarDay: d,
          lunarDay: lunar.day,
          lunarMonth: lunar.month,
          isToday: date == today,
          isReminderDay: reminderDays.contains(lunar.day),
        ),
      );
    }

    return ContentCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        children: [
          // Month nav row.
          Row(
            children: [
              _NavArrow(icon: IconsaxPlusLinear.arrow_left_2, onTap: onPrev),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _NavArrow(icon: IconsaxPlusLinear.arrow_right_3, onTap: onNext),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: weekdays
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.78,
            children: cells,
          ),
          const SizedBox(height: 10),
          // Legend.
          Text(
            l10n.lunarReminderToggleSub,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.solarDay,
    required this.lunarDay,
    required this.lunarMonth,
    required this.isToday,
    required this.isReminderDay,
  });

  final int solarDay;
  final int lunarDay;
  final int lunarMonth;
  final bool isToday;
  final bool isReminderDay;

  @override
  Widget build(BuildContext context) {
    // Lunar label: show the day; on a lunar day-1 also show the month ("1/6")
    // so month boundaries read clearly.
    final lunarLabel = lunarDay == 1 ? '$lunarDay/$lunarMonth' : '$lunarDay';

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.accentLove.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: AppColors.accentLove.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$solarDay',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            lunarLabel,
            style: TextStyle(
              color: isReminderDay
                  ? AppColors.accentLoveDeep
                  : AppColors.textTertiary,
              fontSize: 9,
              fontWeight: isReminderDay ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Editable config: enable toggle + which lunar days (1..30 chips) + which times.
class _LunarReminderConfigCard extends StatelessWidget {
  const _LunarReminderConfigCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reminder = context.watch<ReminderProvider>();
    final days = reminder.lunarDays.toSet();
    final times = reminder.lunarTimes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.lunarSectionTitle),
        const SizedBox(height: 12),
        ContentCard(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                value: reminder.lunarEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  context.read<ReminderProvider>().setLunarEnabled(
                    v,
                    l10n: l10n,
                  );
                },
                activeThumbColor: AppColors.accentRose,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.lunarReminderToggle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.lunarReminderToggleSub,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const Divider(height: 20),

              // ── Reminder days (lunar 1..30) ──────────────────────────────
              Text(
                l10n.lunarRemindDaysLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List<Widget>.generate(30, (i) {
                  final day = i + 1;
                  final selected = days.contains(day);
                  return _DayChoiceChip(
                    label: '$day',
                    selected: selected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final next = Set<int>.of(days);
                      if (selected) {
                        next.remove(day);
                      } else {
                        next.add(day);
                      }
                      context.read<ReminderProvider>().setLunarDays(
                        next,
                        l10n: l10n,
                      );
                    },
                  );
                }),
              ),
              const Divider(height: 28),

              // ── Reminder times ───────────────────────────────────────────
              Text(
                l10n.lunarRemindTimesLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < times.length; i++)
                    _TimeChip(
                      label: times[i].format(context),
                      onEdit: () => _editTime(context, i),
                      onRemove: times.length > 1
                          ? () => _removeTime(context, i)
                          : null,
                    ),
                  if (reminder.canAddLunarTime)
                    _AddTimeChip(onTap: () => _addTime(context)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addTime(BuildContext context) async {
    HapticFeedback.selectionClick();
    final picked = await _showPicker(
      context,
      const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    final provider = context.read<ReminderProvider>();
    final mins = provider.lunarTimes.map((t) => t.hour * 60 + t.minute).toList()
      ..add(picked.hour * 60 + picked.minute);
    await provider.setLunarTimes(mins, l10n: context.l10n);
  }

  Future<void> _editTime(BuildContext context, int index) async {
    final provider = context.read<ReminderProvider>();
    final current = provider.lunarTimes[index];
    final picked = await _showPicker(context, current);
    if (picked == null || !context.mounted) {
      return;
    }
    final mins = provider.lunarTimes
        .map((t) => t.hour * 60 + t.minute)
        .toList();
    mins[index] = picked.hour * 60 + picked.minute;
    await provider.setLunarTimes(mins, l10n: context.l10n);
  }

  Future<void> _removeTime(BuildContext context, int index) async {
    HapticFeedback.selectionClick();
    final provider = context.read<ReminderProvider>();
    final mins = provider.lunarTimes.map((t) => t.hour * 60 + t.minute).toList()
      ..removeAt(index);
    await provider.setLunarTimes(mins, l10n: context.l10n);
  }

  Future<TimeOfDay?> _showPicker(BuildContext context, TimeOfDay initial) {
    return showAppTimePicker(context, initialTime: initial);
  }
}

class _DayChoiceChip extends StatelessWidget {
  const _DayChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentLove
                : AppColors.textSecondary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? AppColors.accentLove
                  : AppColors.textSecondary.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onEdit, this.onRemove});

  final String label;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.accentLove.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.accentLove.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.accentLoveDeep,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(
                    IconsaxPlusLinear.close_circle,
                    size: 16,
                    color: AppColors.accentLoveDeep,
                  ),
                )
              else
                const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTimeChip extends StatelessWidget {
  const _AddTimeChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IconsaxPlusLinear.add,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.lunarAddTime,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
