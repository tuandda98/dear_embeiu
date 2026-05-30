import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
  // instead of stacking duplicates.
  static const int _idDaily = 1001;
  static const int _idAnniversary = 1002;
  static const int _idMilestoneApproaching = 1003;
  static const int _idMilestoneToday = 1004;
  static const int _idInactivity = 1005;

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
    for (final id in const [
      _idDaily,
      _idAnniversary,
      _idMilestoneApproaching,
      _idMilestoneToday,
      _idInactivity,
    ]) {
      try {
        await _plugin.cancel(id);
      } catch (_) {
        // Ignore — a missing notification is already in the desired state.
      }
    }
  }

  /// Schedule a notification that repeats every day at [hour]:[minute].
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleAt(
      id: _idDaily,
      when: _nextInstanceOfTime(hour, minute),
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

  /// Schedule the "milestone approaching" nudge for a specific calendar day.
  Future<void> scheduleMilestoneApproaching({
    required DateTime date,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleAt(
      id: _idMilestoneApproaching,
      when: _at(date, hour, minute),
      title: title,
      body: body,
    );
  }

  /// Schedule the "milestone reached today" celebration for a specific day.
  Future<void> scheduleMilestoneToday({
    required DateTime date,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleAt(
      id: _idMilestoneToday,
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

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
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
