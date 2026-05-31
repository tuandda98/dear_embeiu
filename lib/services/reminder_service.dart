import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/custom_reminder.dart';
import '../models/milestone_reminder.dart';

/// Local, on-device infrastructure for the retention "love reminders" feature.
///
/// This owns the [FlutterLocalNotificationsPlugin] instance, the timezone
/// database and the notification channel. It exposes a small scheduling API
/// that [ReminderProvider] drives — the provider decides *what* to schedule
/// from couple data, this service knows *how* to schedule it.
///
/// All scheduling is local: nothing here talks to Firebase or the network.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const String _channelId = 'love_reminders';
  static const String _channelName = 'Love reminders';
  static const String _channelDescription =
      'Gentle daily and milestone reminders for your relationship.';

  // Stable notification ids so re-scheduling replaces the previous entry
  // instead of stacking duplicates. Auto reminders live in the 1001–1099 band
  // (custom reminders use 2000–2999 and are never touched here).
  //
  // 1001 (legacy daily nudge) is retired in v2 — `cancelAll` still cancels it so
  // any schedule left over from a previous version is cleared on the next run.
  static const int _idLegacyDaily = 1001;
  static const int _idAnniversary = 1002; // yearly milestone
  static const int _idMilestoneEvery100 = 1003;
  static const int _idInactivity = 1005;
  static const int _idMilestoneHalfYear = 1006;
  static const int _idMilestone520 = 1010;
  static const int _idMilestone1000 = 1011;
  static const int _idMilestone1314 = 1012;

  /// Every auto-reminder id this service may own, used by [cancelAll].
  static const List<int> _autoIds = <int>[
    _idLegacyDaily,
    _idAnniversary,
    _idMilestoneEvery100,
    _idInactivity,
    _idMilestoneHalfYear,
    _idMilestone520,
    _idMilestone1000,
    _idMilestone1314,
  ];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Prepare the timezone database and the notification plugin. Safe to call
  /// more than once; the heavy work runs only on the first call. Never throws
  /// to the caller — a device without notification support must not block app
  /// start-up.
  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      tz_data.initializeTimeZones();
      try {
        final localName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localName));
      } catch (_) {
        // Fall back to UTC if the platform can't report its timezone.
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (error, stack) {
      // Don't let a misconfigured device crash launch; reminders simply stay
      // unavailable until the next run.
      debugPrint('ReminderService.initialize failed: $error\n$stack');
    }
  }

  /// Ask the OS for permission to post notifications. Returns whether it is
  /// granted. On platforms that grant implicitly this resolves to `true`.
  Future<bool> requestPermissions() async {
    await initialize();
    if (!_initialized) {
      return false;
    }
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        final granted = await macos.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (error) {
      debugPrint('ReminderService.requestPermissions failed: $error');
    }
    return true;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

  /// Cancel every reminder this service owns. Used when the user turns the
  /// feature off or before a full re-schedule.
  Future<void> cancelAll() async {
    if (!_initialized) {
      return;
    }
    for (final id in _autoIds) {
      try {
        await _plugin.cancel(id);
      } catch (_) {
        // Ignore — a missing notification is already in the desired state.
      }
    }
  }

  /// Cancel a single auto reminder by its [MilestoneType]. Used when the user
  /// turns one milestone off in the customization screen.
  Future<void> cancelMilestone(MilestoneType type) async {
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(_idForMilestone(type));
    } catch (_) {
      // Already in the desired state.
    }
  }

  int _idForMilestone(MilestoneType type) {
    switch (type) {
      case MilestoneType.every100:
        return _idMilestoneEvery100;
      case MilestoneType.d520:
        return _idMilestone520;
      case MilestoneType.d1000:
        return _idMilestone1000;
      case MilestoneType.d1314:
        return _idMilestone1314;
      case MilestoneType.halfYear:
        return _idMilestoneHalfYear;
      case MilestoneType.yearly:
        return _idAnniversary;
      case MilestoneType.inactivity:
        return _idInactivity;
    }
  }

  /// Schedule the next yearly anniversary reminder at [hour]:[minute].
  Future<void> scheduleAnniversary({
    required DateTime anniversaryDate,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final next = _nextAnniversary(anniversaryDate, hour, minute);
    await _scheduleAt(
      id: _idAnniversary,
      when: next,
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// Schedule a one-shot day-count or half-year milestone for [type] on a
  /// specific calendar [date] at [hour]:[minute] (v2). The caller decides the
  /// date and only calls this when that date is still in the future.
  Future<void> scheduleMilestoneOneShot({
    required MilestoneType type,
    required DateTime date,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleAt(
      id: _idForMilestone(type),
      when: _at(date, hour, minute),
      title: title,
      body: body,
    );
  }

  /// Schedule a one-off nudge when the couple hasn't added a photo in a while.
  Future<void> scheduleInactivity({
    required DateTime fireDate,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleAt(
      id: _idInactivity,
      when: _at(fireDate, hour, minute),
      title: title,
      body: body,
    );
  }

  Future<void> cancelInactivity() async {
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(_idInactivity);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Custom reminders (user-created, local-only). Notification ids live in the
  // reserved 2000–2999 band (D6) and are owned by CustomRemindersProvider.
  // ---------------------------------------------------------------------------

  /// Schedule a single user-created reminder.
  ///
  /// Returns whether anything was actually scheduled. A `once` reminder whose
  /// next fire time is in the past is intentionally not scheduled (the caller
  /// decides how to surface that). Repeating reminders always schedule because
  /// they advance to the next valid cycle.
  Future<bool> scheduleCustom({
    required int id,
    required CustomReminder reminder,
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_initialized) {
      return false;
    }
    final when = nextFireFor(reminder);
    if (when == null) {
      // `once` in the past — nothing to schedule.
      await cancelCustom(id);
      return false;
    }
    await _scheduleAt(
      id: id,
      when: when,
      title: title,
      body: body,
      matchDateTimeComponents: _matchComponentsFor(reminder.recurrence),
    );
    return true;
  }

  /// Cancel a single custom reminder by id. Safe to call for an id that isn't
  /// currently scheduled.
  Future<void> cancelCustom(int id) async {
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(id);
    } catch (_) {
      // Already in the desired state.
    }
  }

  DateTimeComponents? _matchComponentsFor(ReminderRecurrence recurrence) {
    switch (recurrence) {
      case ReminderRecurrence.once:
        return null;
      case ReminderRecurrence.daily:
        return DateTimeComponents.time;
      case ReminderRecurrence.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case ReminderRecurrence.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case ReminderRecurrence.yearly:
        return DateTimeComponents.dateAndTime;
    }
  }

  /// Compute the next time [reminder] will fire, applying the D8 day clamp for
  /// monthly/yearly cycles. Shared by scheduling and the "Next: …" list label.
  ///
  /// Returns `null` only for a `once` reminder whose moment has already passed.
  tz.TZDateTime? nextFireFor(CustomReminder reminder) {
    final now = tz.TZDateTime.now(tz.local);
    final h = reminder.hour;
    final m = reminder.minute;
    final date = reminder.date;

    switch (reminder.recurrence) {
      case ReminderRecurrence.once:
        final when =
            tz.TZDateTime(tz.local, date.year, date.month, date.day, h, m);
        return when.isAfter(now) ? when : null;

      case ReminderRecurrence.daily:
        var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
        if (!when.isAfter(now)) {
          when = when.add(const Duration(days: 1));
        }
        return when;

      case ReminderRecurrence.weekly:
        // Same weekday as the anchor date, at or after now.
        final targetWeekday = date.weekday; // 1=Mon..7=Sun
        var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
        var delta = (targetWeekday - when.weekday) % 7;
        if (delta < 0) {
          delta += 7;
        }
        when = when.add(Duration(days: delta));
        if (!when.isAfter(now)) {
          when = when.add(const Duration(days: 7));
        }
        return when;

      case ReminderRecurrence.monthly:
        // Same day-of-month as the anchor, clamped to each month's length (D8).
        var year = now.year;
        var month = now.month;
        var when = _clampedDate(year, month, date.day, h, m);
        if (!when.isAfter(now)) {
          month += 1;
          if (month > 12) {
            month = 1;
            year += 1;
          }
          when = _clampedDate(year, month, date.day, h, m);
        }
        return when;

      case ReminderRecurrence.yearly:
        // Same day/month as the anchor, clamping Feb 29 → Feb 28 in non-leap
        // years (D8).
        var year = now.year;
        var when = _clampedDate(year, date.month, date.day, h, m);
        if (!when.isAfter(now)) {
          when = _clampedDate(year + 1, date.month, date.day, h, m);
        }
        return when;
    }
  }

  /// Build a [tz.TZDateTime] for [year]/[month]/[day], clamping [day] to the
  /// last valid day of that month (e.g. 31 → 30, or 29 Feb → 28 in a non-leap
  /// year). Implements decision D8 so a cycle is never silently skipped.
  tz.TZDateTime _clampedDate(int year, int month, int day, int hour, int minute) {
    final lastDay = _daysInMonth(year, month);
    final safeDay = day > lastDay ? lastDay : day;
    return tz.TZDateTime(tz.local, year, month, safeDay, hour, minute);
  }

  int _daysInMonth(int year, int month) {
    // The 0th day of the next month is the last day of this month.
    final firstOfNextMonth =
        month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  Future<void> _scheduleAt({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (error) {
      debugPrint('ReminderService schedule($id) failed: $error');
    }
  }

  tz.TZDateTime _nextAnniversary(DateTime anniversary, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      anniversary.month,
      anniversary.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        tz.local,
        now.year + 1,
        anniversary.month,
        anniversary.day,
        hour,
        minute,
      );
    }
    return next;
  }

  tz.TZDateTime _at(DateTime date, int hour, int minute) {
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }
}
