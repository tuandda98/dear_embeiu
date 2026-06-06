import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/milestone_reminder.dart';
import '../services/reminder_service.dart';

/// User-facing settings for the "milestone & anniversary reminders" feature.
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

/// Describes the next time a milestone will fire, for the "Next: …" list label.
///
/// Exactly one of [date]/[pending]/[passed] is meaningful per milestone:
/// - [pending] when the anniversary is in the future (can't compute yet),
/// - [passed] when a one-shot milestone has already gone by,
/// - otherwise [date] (and optional [label]) describe the upcoming fire.
@immutable
class MilestoneNextFire {
  const MilestoneNextFire.upcoming(this.date, {this.label})
      : pending = false,
        passed = false;
  const MilestoneNextFire.passed()
      : date = null,
        label = null,
        pending = false,
        passed = true;
  const MilestoneNextFire.pending()
      : date = null,
        label = null,
        pending = true,
        passed = false;

  /// The upcoming fire date (null when pending/passed).
  final DateTime? date;

  /// Optional human label for the milestone count (e.g. "700 days", "1 year").
  final String? label;

  /// Anniversary is in the future — nothing can be computed yet.
  final bool pending;

  /// A one-shot milestone that has already gone by.
  final bool passed;
}

/// Drives the local auto-reminder schedule from couple data (v2).
///
/// The provider decides *what* to schedule — which curated milestones are on,
/// the yearly anniversary, and the inactivity nudge — and persists the user's
/// preferences; [ReminderService] knows *how* to schedule each one.
///
/// v2 removed the generic daily nudge (Dv1) and made each milestone individually
/// toggleable (Dv3/Dv4), scheduling only on the exact milestone day (Dv5).
class ReminderProvider extends ChangeNotifier {
  static const String _boxName = 'reminder_settings';
  static const String _enabledKey = 'enabled';
  static const String _hourKey = 'hour';
  static const String _minuteKey = 'minute';

  // Daily-question reminder (b2). Independent of the milestone master toggle —
  // its own Hive keys, default ON at 20:00. Lives in the same box but never
  // touches the milestone keys above.
  static const String _dqEnabledKey = 'dqReminderEnabled';
  static const String _dqHourKey = 'dqReminderHour';
  static const String _dqMinuteKey = 'dqReminderMinute';

  /// Hive key prefix for a milestone's on/off flag (suffix = enum name).
  static const String _milestoneKeyPrefix = 'milestone_';

  /// Hive key prefix for a milestone's optional custom reminder time (Dv8).
  /// `milestone_<name>_hour` / `milestone_<name>_minute`; absent = follow the
  /// default time. Both are stored together when a custom time is set and
  /// removed together when it is reset.
  static const String _milestoneTimePrefix = 'milestone_';
  static const String _milestoneHourSuffix = '_hour';
  static const String _milestoneMinuteSuffix = '_minute';

  // Day-count cadence: a fresh "every 100 days" milestone every 100 days.
  static const int _every100Step = 100;
  // Days of photo inactivity before the gentle "missing your moments" nudge.
  static const int _inactivityDays = 7;

  ReminderSettings _settings = const ReminderSettings();
  ReminderSettings get settings => _settings;

  // Daily-question reminder state (b2). Defaults: on, 20:00. Persisted under the
  // _dq* keys and scheduled/cancelled independently of [settings.enabled].
  bool _dqEnabled = true;
  int _dqHour = 20;
  int _dqMinute = 0;

  /// Whether the daily-question nudge is on.
  bool get dailyQuestionReminderEnabled => _dqEnabled;

  /// The time of day the daily-question nudge fires.
  TimeOfDay get dailyQuestionReminderTime =>
      TimeOfDay(hour: _dqHour, minute: _dqMinute);

  /// On/off state per milestone. Initialised to the Dv4 defaults and overridden
  /// by persisted values in [load].
  final Map<MilestoneType, bool> _milestones =
      Map<MilestoneType, bool>.from(kMilestoneDefaults);

  /// Optional per-milestone reminder time (Dv8). Absent = use the default time
  /// ([ReminderSettings.hour]/[minute]). Loaded from Hive in [load].
  final Map<MilestoneType, TimeOfDay> _milestoneTimes =
      <MilestoneType, TimeOfDay>{};

  final ReminderService _service = ReminderService.instance;

  // Inputs cached from the last sync/reschedule so [toggleMilestone] can
  // reschedule a single milestone without the caller re-supplying couple data.
  DateTime? _lastAnniversary;
  DateTime? _lastPhotoDate;
  AppLocalizations? _lastL10n;

  /// The fixed display order of milestones (Dv4).
  List<MilestoneType> get milestoneOrder => kMilestoneOrder;

  bool isMilestoneEnabled(MilestoneType type) =>
      _milestones[type] ?? kMilestoneDefaults[type] ?? false;

  /// Number of milestones currently turned on (for the profile badge).
  int get enabledMilestoneCount =>
      _milestones.values.where((on) => on).length;

  /// The custom reminder time set for [type], or null when it follows the
  /// default time (Dv8).
  TimeOfDay? milestoneTimeOf(MilestoneType type) => _milestoneTimes[type];

  /// The time [type] will actually fire at: its custom time if one is set,
  /// otherwise the default time (Dv8).
  TimeOfDay effectiveTimeOf(MilestoneType type) =>
      _milestoneTimes[type] ??
      TimeOfDay(hour: _settings.hour, minute: _settings.minute);

  /// Load persisted settings. Does not (re)schedule anything on its own — the
  /// schedule is refreshed by [sync] once couple data is available.
  Future<void> load() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      _settings = ReminderSettings(
        enabled: box.get(_enabledKey, defaultValue: false) as bool,
        hour: box.get(_hourKey, defaultValue: 20) as int,
        minute: box.get(_minuteKey, defaultValue: 0) as int,
      );
      // Daily-question reminder (b2): default on at 20:00.
      _dqEnabled = box.get(_dqEnabledKey, defaultValue: true) as bool;
      _dqHour = box.get(_dqHourKey, defaultValue: 20) as int;
      _dqMinute = box.get(_dqMinuteKey, defaultValue: 0) as int;
      for (final type in MilestoneType.values) {
        final stored = box.get('$_milestoneKeyPrefix${type.name}');
        if (stored is bool) {
          _milestones[type] = stored;
        }
        // Optional per-milestone custom time (Dv8): present only when the user
        // overrode the default for this milestone.
        final storedHour =
            box.get('$_milestoneTimePrefix${type.name}$_milestoneHourSuffix');
        final storedMinute = box
            .get('$_milestoneTimePrefix${type.name}$_milestoneMinuteSuffix');
        if (storedHour is int && storedMinute is int) {
          _milestoneTimes[type] =
              TimeOfDay(hour: storedHour, minute: storedMinute);
        }
      }
      notifyListeners();
    } catch (error) {
      debugPrint('ReminderProvider.load failed: $error');
    }
  }

  Future<void> _persist() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      await box.put(_enabledKey, _settings.enabled);
      await box.put(_hourKey, _settings.hour);
      await box.put(_minuteKey, _settings.minute);
    } catch (error) {
      debugPrint('ReminderProvider._persist failed: $error');
    }
  }

  Future<void> _persistDailyQuestion() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      await box.put(_dqEnabledKey, _dqEnabled);
      await box.put(_dqHourKey, _dqHour);
      await box.put(_dqMinuteKey, _dqMinute);
    } catch (error) {
      debugPrint('ReminderProvider._persistDailyQuestion failed: $error');
    }
  }

  Future<void> _persistMilestone(MilestoneType type) async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      await box.put(
        '$_milestoneKeyPrefix${type.name}',
        _milestones[type] ?? false,
      );
    } catch (error) {
      debugPrint('ReminderProvider._persistMilestone failed: $error');
    }
  }

  Future<void> _persistMilestoneTime(MilestoneType type) async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      final hourKey =
          '$_milestoneTimePrefix${type.name}$_milestoneHourSuffix';
      final minuteKey =
          '$_milestoneTimePrefix${type.name}$_milestoneMinuteSuffix';
      final time = _milestoneTimes[type];
      if (time == null) {
        await box.delete(hourKey);
        await box.delete(minuteKey);
      } else {
        await box.put(hourKey, time.hour);
        await box.put(minuteKey, time.minute);
      }
    } catch (error) {
      debugPrint('ReminderProvider._persistMilestoneTime failed: $error');
    }
  }

  /// Turn reminders on or off.
  ///
  /// Enabling first requests OS notification permission. Returns whether
  /// reminders are now active: `false` means the user denied permission, so the
  /// caller can surface that. Disabling always succeeds and clears the schedule.
  Future<bool> setEnabled(
    bool value, {
    required DateTime anniversaryDate,
    DateTime? lastPhotoDate,
    required AppLocalizations l10n,
  }) async {
    if (!value) {
      _settings = _settings.copyWith(enabled: false);
      await _persist();
      await _service.cancelAll();
      notifyListeners();
      return true;
    }

    final granted = await _service.requestPermissions();
    if (!granted) {
      _settings = _settings.copyWith(enabled: false);
      await _persist();
      notifyListeners();
      return false;
    }

    _settings = _settings.copyWith(enabled: true);
    await _persist();
    await _reschedule(
      anniversaryDate: anniversaryDate,
      lastPhotoDate: lastPhotoDate,
      l10n: l10n,
    );
    notifyListeners();
    return true;
  }

  /// Change the default time of day reminders fire and re-schedule around it.
  ///
  /// Changing the default time only moves milestones that follow it — those
  /// with their own custom time (Dv8) keep theirs, because [_reschedule] uses
  /// each milestone's effective time. Couple inputs default to the values
  /// cached by the last [sync]/[_reschedule] so callers without couple data
  /// (e.g. the milestone screen) can change the default time directly.
  Future<void> setTime(
    int hour,
    int minute, {
    DateTime? anniversaryDate,
    DateTime? lastPhotoDate,
    AppLocalizations? l10n,
  }) async {
    _settings = _settings.copyWith(hour: hour, minute: minute);
    await _persist();
    final anniversary = anniversaryDate ?? _lastAnniversary;
    final strings = l10n ?? _lastL10n;
    if (_settings.enabled && anniversary != null && strings != null) {
      await _reschedule(
        anniversaryDate: anniversary,
        lastPhotoDate: lastPhotoDate ?? _lastPhotoDate,
        l10n: strings,
      );
    }
    notifyListeners();
  }

  /// Turn a single milestone on or off. Persists and (when reminders are on)
  /// schedules or cancels just that milestone. Falls back to a full reschedule
  /// if the cached couple inputs aren't available yet.
  Future<void> toggleMilestone(MilestoneType type, bool value) async {
    _milestones[type] = value;
    await _persistMilestone(type);

    if (_settings.enabled) {
      final anniversary = _lastAnniversary;
      final l10n = _lastL10n;
      if (anniversary != null && l10n != null) {
        if (value) {
          await _scheduleMilestone(type, anniversary, l10n);
        } else {
          await _service.cancelMilestone(type);
        }
      }
    }
    notifyListeners();
  }

  /// Set or clear a milestone's custom reminder time (Dv8).
  ///
  /// Pass a [TimeOfDay] to give [type] its own fire time, or `null` to remove
  /// the override so it follows the default time again. Persists and (when
  /// reminders are on) reschedules just that milestone using its effective time.
  Future<void> setMilestoneTime(MilestoneType type, TimeOfDay? time) async {
    if (time == null) {
      _milestoneTimes.remove(type);
    } else {
      _milestoneTimes[type] = time;
    }
    await _persistMilestoneTime(type);

    if (_settings.enabled) {
      final anniversary = _lastAnniversary;
      final l10n = _lastL10n;
      if (anniversary != null && l10n != null && isMilestoneEnabled(type)) {
        await _scheduleMilestone(type, anniversary, l10n);
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Daily-question reminder (b2). A single repeating-daily nudge, independent of
  // the milestone master toggle ([settings.enabled]) and of couple state. The
  // schedule itself is armed only while a couple is active (so the nudge means
  // something), which is tracked by [_lastAnniversary] being set from [sync].
  // ---------------------------------------------------------------------------

  /// Turn the daily-question nudge on or off.
  ///
  /// Enabling first requests OS notification permission. Returns whether the
  /// reminder is now on: `false` means the user denied permission, so the caller
  /// can surface that. When on and a couple is active, schedules immediately;
  /// otherwise the preference is saved and [sync] arms it once a couple loads.
  Future<bool> setDailyQuestionReminderEnabled(
    bool value, {
    required AppLocalizations l10n,
  }) async {
    if (!value) {
      _dqEnabled = false;
      await _persistDailyQuestion();
      await _service.cancelDailyQuestion();
      notifyListeners();
      return true;
    }

    final granted = await _service.requestPermissions();
    if (!granted) {
      _dqEnabled = false;
      await _persistDailyQuestion();
      notifyListeners();
      return false;
    }

    _dqEnabled = true;
    await _persistDailyQuestion();
    // Only schedule when a couple is active (the nudge invites both partners to
    // answer). If no couple yet, the preference is stored and [sync] arms it.
    if (_lastAnniversary != null) {
      await _scheduleDailyQuestion(l10n);
    }
    notifyListeners();
    return true;
  }

  /// Change the time the daily-question nudge fires. Reschedules when it is on
  /// and a couple is active.
  Future<void> setDailyQuestionReminderTime(
    int hour,
    int minute, {
    required AppLocalizations l10n,
  }) async {
    _dqHour = hour;
    _dqMinute = minute;
    await _persistDailyQuestion();
    if (_dqEnabled && _lastAnniversary != null) {
      await _scheduleDailyQuestion(l10n);
    }
    notifyListeners();
  }

  /// (Re)schedule the daily-question nudge with the localized copy. Cancels any
  /// previous schedule via the stable id, so this is safe to call repeatedly.
  Future<void> _scheduleDailyQuestion(AppLocalizations l10n) async {
    await _service.scheduleDailyQuestion(
      hour: _dqHour,
      minute: _dqMinute,
      title: l10n.dailyQuestionReminderNotifTitle,
      body: l10n.dailyQuestionReminderNotifBody,
    );
  }

  /// Refresh the schedule from the latest couple data. Cheap and idempotent —
  /// safe to call whenever the inputs change. No-op for milestones when those
  /// reminders are off, but the daily-question nudge is handled independently.
  Future<void> sync({
    required DateTime anniversaryDate,
    DateTime? lastPhotoDate,
    required AppLocalizations l10n,
  }) async {
    // Cache inputs first so the daily-question schedule and later milestone
    // toggles both see a non-null anniversary (= a couple is active).
    _lastAnniversary = anniversaryDate;
    _lastPhotoDate = lastPhotoDate;
    _lastL10n = l10n;

    // Daily-question nudge (b2): independent of the milestone master toggle.
    if (_dqEnabled) {
      await _scheduleDailyQuestion(l10n);
    }

    if (!_settings.enabled) {
      return;
    }
    await _reschedule(
      anniversaryDate: anniversaryDate,
      lastPhotoDate: lastPhotoDate,
      l10n: l10n,
    );
  }

  /// Cancel the daily-question nudge — used when the couple goes inactive
  /// (sign-out / no couple). The user's on/off preference is kept so it re-arms
  /// on the next [sync] once a couple is active again.
  Future<void> cancelDailyQuestionSchedule() async {
    await _service.cancelDailyQuestion();
  }

  /// Next fire description for [type], used by the customization screen. Pure
  /// (no scheduling) so it can be called freely during build.
  MilestoneNextFire nextFireForMilestone(MilestoneType type) {
    final anniversary = _lastAnniversary;
    final now = DateTime.now();
    final today = _dateOnly(now);

    // Build the exact fire moment for [date] at the milestone's effective
    // reminder time (its custom time if set, otherwise the default time, Dv8).
    final effective = effectiveTimeOf(type);
    DateTime fireAt(DateTime date) => DateTime(
          date.year,
          date.month,
          date.day,
          effective.hour,
          effective.minute,
        );

    if (type == MilestoneType.inactivity) {
      // No concrete next date — the UI shows a static description instead.
      return const MilestoneNextFire.pending();
    }

    if (anniversary == null) {
      return const MilestoneNextFire.pending();
    }
    final start = _dateOnly(anniversary);
    final daysTogether = today.difference(start).inDays;
    if (daysTogether < 0) {
      // Anniversary is in the future — can't compute yet.
      return const MilestoneNextFire.pending();
    }

    switch (type) {
      case MilestoneType.every100:
        var nextCount = ((daysTogether ~/ _every100Step) + 1) * _every100Step;
        var date = start.add(Duration(days: nextCount));
        // If the next 100-day mark is today but its fire time has already
        // passed, skip ahead so we never display a past moment.
        if (!fireAt(date).isAfter(now)) {
          nextCount += _every100Step;
          date = start.add(Duration(days: nextCount));
        }
        return MilestoneNextFire.upcoming(date, label: '$nextCount');

      case MilestoneType.d520:
      case MilestoneType.d1000:
      case MilestoneType.d1314:
        final offset = type.fixedDayOffset!;
        final date = start.add(Duration(days: offset));
        // Passed only when the exact fire moment is not in the future; a mark
        // landing today still counts as upcoming until its reminder time.
        if (!fireAt(date).isAfter(now)) {
          return const MilestoneNextFire.passed();
        }
        return MilestoneNextFire.upcoming(date, label: '$offset');

      case MilestoneType.halfYear:
        final date = _addMonthsClamped(start, 6);
        if (!fireAt(date).isAfter(now)) {
          return const MilestoneNextFire.passed();
        }
        return MilestoneNextFire.upcoming(date);

      case MilestoneType.yearly:
        final years = (daysTogether ~/ 365) + 1;
        final date = _nextAnniversaryDate(start, today);
        return MilestoneNextFire.upcoming(date, label: '$years');

      case MilestoneType.inactivity:
        return const MilestoneNextFire.pending();
    }
  }

  Future<void> _reschedule({
    required DateTime anniversaryDate,
    DateTime? lastPhotoDate,
    required AppLocalizations l10n,
  }) async {
    _lastAnniversary = anniversaryDate;
    _lastPhotoDate = lastPhotoDate;
    _lastL10n = l10n;

    await _service.cancelAll();

    // Schedule each enabled milestone individually (Dv3/Dv5). Each uses its
    // effective time (custom or default), so changing the default time only
    // moves milestones that follow it (Dv8).
    for (final type in MilestoneType.values) {
      if (isMilestoneEnabled(type)) {
        await _scheduleMilestone(type, anniversaryDate, l10n);
      }
    }
  }

  /// Schedule (or skip) a single milestone. Never throws; out-of-range dates
  /// (future anniversary, already-passed one-shot) are simply not scheduled.
  Future<void> _scheduleMilestone(
    MilestoneType type,
    DateTime anniversaryDate,
    AppLocalizations l10n,
  ) async {
    // Resolve this milestone's effective fire time: its custom time if set,
    // otherwise the default reminder time (Dv8).
    final effective = effectiveTimeOf(type);
    final hour = effective.hour;
    final minute = effective.minute;
    final start = _dateOnly(anniversaryDate);
    final today = _dateOnly(DateTime.now());
    final daysTogether = today.difference(start).inDays;

    switch (type) {
      case MilestoneType.yearly:
        await _service.scheduleAnniversary(
          anniversaryDate: anniversaryDate,
          hour: hour,
          minute: minute,
          title: l10n.reminderAnniversaryTitle,
          body: l10n.reminderAnniversaryBody,
        );
        return;

      case MilestoneType.inactivity:
        final reference = _lastPhotoDate ?? DateTime.now();
        var fireDate = DateTime(
          reference.year,
          reference.month,
          reference.day,
        ).add(const Duration(days: _inactivityDays));
        if (!fireDate.isAfter(today)) {
          fireDate = today.add(const Duration(days: _inactivityDays));
        }
        await _service.scheduleInactivity(
          fireDate: fireDate,
          hour: hour,
          minute: minute,
          title: l10n.reminderInactivityTitle,
          body: l10n.reminderInactivityBody,
        );
        return;

      case MilestoneType.every100:
      case MilestoneType.d520:
      case MilestoneType.d1000:
      case MilestoneType.d1314:
      case MilestoneType.halfYear:
        // Day-count / half-year one-shots can't be computed for a future
        // anniversary and must not crash.
        if (daysTogether < 0) {
          return;
        }
        final DateTime date;
        final String milestoneLabel;
        if (type == MilestoneType.halfYear) {
          date = _addMonthsClamped(start, 6);
          milestoneLabel = l10n.milestoneHalfYearTitle;
        } else if (type == MilestoneType.every100) {
          final nextCount =
              ((daysTogether ~/ _every100Step) + 1) * _every100Step;
          date = start.add(Duration(days: nextCount));
          milestoneLabel = '$nextCount';
        } else {
          final offset = type.fixedDayOffset!;
          date = start.add(Duration(days: offset));
          milestoneLabel = '$offset';
        }
        // Only skip when the exact fire moment (date at hour:minute) is not in
        // the future. A milestone landing *today* still fires when its reminder
        // time hasn't passed yet (consistent with custom one-shots, Dv5).
        final fireDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        if (!fireDateTime.isAfter(DateTime.now())) {
          return;
        }
        await _service.scheduleMilestoneOneShot(
          type: type,
          date: date,
          hour: hour,
          minute: minute,
          title: l10n.reminderMilestoneTodayTitle,
          body: l10n.reminderMilestoneTodayBody(milestoneLabel),
        );
        return;
    }
  }

  /// Next calendar anniversary on/after [today], clamping Feb 29 → Feb 28.
  DateTime _nextAnniversaryDate(DateTime start, DateTime today) {
    var candidate = _clampDay(today.year, start.month, start.day);
    if (!candidate.isAfter(today)) {
      candidate = _clampDay(today.year + 1, start.month, start.day);
    }
    return candidate;
  }

  /// Add [months] calendar months to [date], clamping the day to the target
  /// month's length (e.g. Aug 31 + 6 → Feb 28/29).
  DateTime _addMonthsClamped(DateTime date, int months) {
    final total = date.month - 1 + months;
    final year = date.year + total ~/ 12;
    final month = total % 12 + 1;
    return _clampDay(year, month, date.day);
  }

  DateTime _clampDay(int year, int month, int day) {
    final lastDay = _daysInMonth(year, month);
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  int _daysInMonth(int year, int month) {
    final firstOfNext =
        month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstOfNext.subtract(const Duration(days: 1)).day;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
