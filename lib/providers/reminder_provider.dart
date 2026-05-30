import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/reminder_service.dart';

/// User-facing settings for the "love reminders" feature.
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

/// Drives the local reminder schedule from couple data.
///
/// The provider decides *what* to schedule (daily nudge, upcoming day-count
/// milestone, yearly anniversary, inactivity nudge) and persists the user's
/// preferences; [ReminderService] knows *how* to schedule each one.
class ReminderProvider extends ChangeNotifier {
  static const String _boxName = 'reminder_settings';
  static const String _enabledKey = 'enabled';
  static const String _hourKey = 'hour';
  static const String _minuteKey = 'minute';

  // Day-count milestones are celebrated every 100 days together.
  static const int _milestoneStepDays = 100;
  // How many days before a milestone the "approaching" nudge fires.
  static const int _approachingLeadDays = 3;
  // Days of photo inactivity before the gentle "missing your moments" nudge.
  static const int _inactivityDays = 7;

  ReminderSettings _settings = const ReminderSettings();
  ReminderSettings get settings => _settings;

  final ReminderService _service = ReminderService.instance;

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

  /// Change the time of day reminders fire and re-schedule around it.
  Future<void> setTime(
    int hour,
    int minute, {
    required DateTime anniversaryDate,
    DateTime? lastPhotoDate,
    required AppLocalizations l10n,
  }) async {
    _settings = _settings.copyWith(hour: hour, minute: minute);
    await _persist();
    if (_settings.enabled) {
      await _reschedule(
        anniversaryDate: anniversaryDate,
        lastPhotoDate: lastPhotoDate,
        l10n: l10n,
      );
    }
    notifyListeners();
  }

  /// Refresh the schedule from the latest couple data. Cheap and idempotent —
  /// safe to call whenever the inputs change. No-op when reminders are off.
  Future<void> sync({
    required DateTime anniversaryDate,
    DateTime? lastPhotoDate,
    required AppLocalizations l10n,
  }) async {
    if (!_settings.enabled) {
      return;
    }
    await _reschedule(
      anniversaryDate: anniversaryDate,
      lastPhotoDate: lastPhotoDate,
      l10n: l10n,
    );
  }

  Future<void> _reschedule({
    required DateTime anniversaryDate,
    DateTime? lastPhotoDate,
    required AppLocalizations l10n,
  }) async {
    await _service.cancelAll();

    final hour = _settings.hour;
    final minute = _settings.minute;

    // Daily nudge.
    await _service.scheduleDaily(
      hour: hour,
      minute: minute,
      title: l10n.reminderDailyTitle,
      body: l10n.reminderDailyBody,
    );

    // Yearly anniversary.
    await _service.scheduleAnniversary(
      anniversaryDate: anniversaryDate,
      hour: hour,
      minute: minute,
      title: l10n.reminderAnniversaryTitle,
      body: l10n.reminderAnniversaryBody,
    );

    // Upcoming day-count milestone (every 100 days together).
    await _scheduleMilestone(anniversaryDate, hour, minute, l10n);

    // Inactivity nudge.
    final reference = lastPhotoDate ?? DateTime.now();
    var fireDate = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).add(const Duration(days: _inactivityDays));
    final todayStart = _dateOnly(DateTime.now());
    if (!fireDate.isAfter(todayStart)) {
      fireDate = todayStart.add(const Duration(days: _inactivityDays));
    }
    await _service.scheduleInactivity(
      fireDate: fireDate,
      hour: hour,
      minute: minute,
      title: l10n.reminderInactivityTitle,
      body: l10n.reminderInactivityBody,
    );
  }

  Future<void> _scheduleMilestone(
    DateTime anniversaryDate,
    int hour,
    int minute,
    AppLocalizations l10n,
  ) async {
    final start = _dateOnly(anniversaryDate);
    final today = _dateOnly(DateTime.now());
    final daysTogether = today.difference(start).inDays;
    if (daysTogether < 0) {
      return;
    }
    final nextMilestoneCount =
        ((daysTogether ~/ _milestoneStepDays) + 1) * _milestoneStepDays;
    final milestoneDate = start.add(Duration(days: nextMilestoneCount));
    final milestoneLabel = nextMilestoneCount.toString();

    // "Approaching" nudge a few days before, if that day is still ahead.
    final approachingDate =
        milestoneDate.subtract(const Duration(days: _approachingLeadDays));
    if (approachingDate.isAfter(today)) {
      await _service.scheduleMilestoneApproaching(
        date: approachingDate,
        hour: hour,
        minute: minute,
        title: l10n.reminderMilestoneApproachingTitle,
        body: l10n.reminderMilestoneApproachingBody(
          _approachingLeadDays,
          milestoneLabel,
        ),
      );
    }

    // Celebration on the milestone day itself.
    if (milestoneDate.isAfter(today)) {
      await _service.scheduleMilestoneToday(
        date: milestoneDate,
        hour: hour,
        minute: minute,
        title: l10n.reminderMilestoneTodayTitle,
        body: l10n.reminderMilestoneTodayBody(milestoneLabel),
      );
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
