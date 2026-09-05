import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/custom_reminder.dart';
import '../models/milestone_reminder.dart';

/// One end-of-day daily-question nudge: a fixed [hour]:[minute] for TODAY with
/// its own localized [title]/[body]. The provider picks the copy from the
/// streak + answer state (21:00 = gentle nudge, 22:00/23:00 = streak warning).
@immutable
class DailyQuestionEodSlot {
  const DailyQuestionEodSlot({
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
  });

  final int hour;
  final int minute;
  final String title;
  final String body;
}

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
  // Daily-question nudge (b2). Lives in the auto band but is intentionally NOT
  // part of [_autoIds]: it is independent of the master milestone toggle, so
  // [cancelAll] (master off / full reschedule) must never cancel it.
  static const int _idDailyQuestion = 1004;
  static const int _idInactivity = 1005;
  static const int _idMilestoneHalfYear = 1006;
  static const int _idMilestone520 = 1010;
  static const int _idMilestone1000 = 1011;
  static const int _idMilestone1314 = 1012;

  // Daily-question multi-time band (2026-06-14; one-shot TODAY since 2026-06-20):
  // one notification per configured fire time, ids 1040..1049, scheduled only for
  // today's remaining times and re-armed each day by the provider — so it can be
  // suppressed once both have answered and switch copy when only one has. Sits
  // ABOVE the milestone band and outside [_autoIds] so the master reschedule
  // never touches it. The legacy single id 1004 is still cancelled by
  // [cancelDailyQuestion] to clean up any schedule left by an older build.
  static const int _idDailyQuestionBase = 1040;
  static const int _maxDailyQuestionTimes = 10;

  // Daily-question BACKSTOP band (2026-08-09), ids 1020–1033.
  //
  // Why it exists: the band above is one-shot for TODAY and is only ever armed
  // while the app is running, so a user who doesn't open the app on a given day
  // got NO reminder at all that day — exactly the user the nudge is for.
  //
  // Shape: a ROLLING WINDOW of one-shots covering the next [_backstopDays] days
  // (never today), topped up on every app open — the same pattern as the lunar
  // band. So:
  //  • open the app every day → each re-arm rebuilds the window from tomorrow and
  //    nothing here ever fires (today's answer-aware one-shot handles today);
  //  • skip days → these fire, up to [_backstopDays] days out.
  // Because it can only fire on a day the app wasn't opened, the user provably
  // hasn't answered that day → the plain "come answer" copy is always true, which
  // is why this band needs no answer-state awareness.
  //
  // ⚠️ Deliberately NOT a repeating schedule (`DateTimeComponents.time`): on iOS
  // that becomes an hour/minute-only UNCalendarNotificationTrigger, whose next
  // match can be TODAY — firing a duplicate alongside the one-shot band in the
  // same minute. Explicit dates keep the two bands from ever colliding.
  static const int _idDailyQuestionBackstopBase = 1020;
  // Days ahead to pre-arm. Kept small on purpose: iOS caps an app at 64 PENDING
  // notifications, and this band shares that budget with milestones, the lunar
  // window and partner reminders. 7 days is plenty to catch a lapsed user before
  // their next app open.
  static const int _backstopDays = 7;
  static const int _maxDailyQuestionBackstop = 14;

  // Daily-question end-of-day safety net (2026-06-19): up to 3 ONE-SHOT nudges
  // for TODAY only (21:00 gentle nudge, 22:00 + 23:00 streak warnings), ids
  // 1050..1052. One-shot — not repeating — because both the copy and whether to
  // fire at all depend on today's answer state; the provider re-arms them each
  // day and on every habit-state change. Outside [_autoIds] like the band above.
  static const int _idDailyQuestionEodBase = 1050;
  static const int _maxDailyQuestionEod = 3;

  // Lunar reminders (account-gated, 2026-06-19): ONE-SHOT nudges on the upcoming
  // lunar day-1 / day-15 dates at the configured hours, ids 1060..1099. Lunar
  // dates don't fall on fixed Gregorian days so these can't repeat natively —
  // the provider schedules a rolling window and tops it up on each app open.
  // Outside [_autoIds] (independent of the milestone reschedule).
  static const int _idLunarBase = 1060;
  static const int _maxLunar = 40;

  // Personal "anh By → embe" nudges (account-gated, 2026-06-20). Two bands, both
  // outside [_autoIds] (owned only by the gated account's refresh):
  //   • medicine 1100–1109 — DAILY-RECURRING (uống thuốc đúng giờ), unconditional.
  //   • question 1110–1139 — ONE-SHOT for today's remaining hours (nhắc trả lời
  //     câu hỏi); cleared once she's answered, re-armed daily by the provider.
  static const int _idPersonalMedicineBase = 1100;
  static const int _maxPersonalMedicine = 10;
  static const int _idPersonalQuestionBase = 1110;
  static const int _maxPersonalQuestion = 30;
  //   • catch-up 1140–1159 — ONE-SHOT for today's remaining slots (feature
  //     `catch-up`, 2026-09-05): fires only while she still has PAST days with
  //     no answer, so the copy can name how many are waiting. Cleared as soon
  //     as the backlog hits zero.
  static const int _idPersonalCatchupBase = 1140;
  static const int _maxPersonalCatchup = 20;

  // Invite follow-ups (feature onboarding, 2026-09-05), ids 1180–1189. ONE-SHOT
  // nudges for the member who is still alone in a `waiting_partner` couple:
  // 24h + 72h after the couple was created, "your partner hasn't joined yet —
  // send the invite again". Outside [_autoIds] and every other band (personal
  // 1100–1159, daily-question 1020–1052, lunar 1060–1099) so they never collide;
  // owned solely by ReminderProvider.refreshInviteFollowUps, which cancels the
  // whole band the moment the partner joins.
  static const int _idInviteFollowUpBase = 1180;
  static const int _maxInviteFollowUps = 10;

  // Partner reminders (feature partner-nudge, 2026-06-29): scheduled reminders
  // one partner set FOR the other, synced via Firestore and armed LOCALLY on the
  // recipient's device (so they fire in the recipient's own timezone). Reserved
  // band 3000–3049, owned by PartnerReminderProvider; outside [_autoIds] and the
  // custom-reminder band (2000–2999) so they never collide.
  static const int _idPartnerReminderBase = 3000;
  static const int _maxPartnerReminders = 50;

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

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
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
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
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
  // Daily-question reminder (b2). A single repeating-daily nudge that pulls both
  // partners in to answer the day's question. Independent of the milestone
  // master toggle — it owns id 1004, which is deliberately outside [_autoIds].
  // ---------------------------------------------------------------------------

  /// (Re)schedule the daily-question nudge at each time in [minutesOfDay]
  /// (minutes since midnight, ≤10 entries; extras are dropped). ONE-SHOT for
  /// TODAY only — times already past are skipped (never rolled to tomorrow; the
  /// provider re-arms each day with the current answer state so it can suppress
  /// the nudge once both have answered and swap copy when only one has, and
  /// [scheduleDailyQuestionBackstop] covers the days the app isn't opened).
  /// Clears the whole daily-question band (and the legacy single id) first, so
  /// this is safe to call repeatedly and an empty list simply cancels everything.
  ///
  /// [bodies] rotates per fire time (`bodies[i % bodies.length]`) so a user with
  /// several times a day doesn't get the exact same sentence over and over. Pass
  /// a single-element list for one fixed body.
  Future<void> scheduleDailyQuestionTimes({
    required List<int> minutesOfDay,
    required String title,
    required List<String> bodies,
  }) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelDailyQuestion();
    if (bodies.isEmpty) {
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final times = minutesOfDay.take(_maxDailyQuestionTimes).toList();
    for (var i = 0; i < times.length; i++) {
      final clamped = times[i].clamp(0, 24 * 60 - 1);
      final hour = clamped ~/ 60;
      final minute = clamped % 60;
      final when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!when.isAfter(now)) {
        continue;
      }
      await _scheduleAt(
        id: _idDailyQuestionBase + i,
        when: when,
        title: title,
        body: bodies[i % bodies.length],
      );
    }
  }

  /// (Re)schedule the BACKSTOP nudges (ids 1020–1033) — the safety net for days
  /// the app is never opened, so the one-shot band above never gets armed. See
  /// the band's doc comment for the full rationale.
  ///
  /// Arms one-shots for each time in [minutesOfDay] on each of the next
  /// [_backstopDays] days, **starting tomorrow** (never today, so it can't double
  /// up with [scheduleDailyQuestionTimes]), capped at
  /// [_maxDailyQuestionBackstop] notifications. Dates are rebuilt field-by-field
  /// per day so a DST shift can't drag the wall-clock time. [bodies] rotates so
  /// consecutive nudges don't repeat one sentence. Clears the band first — empty
  /// times (or bodies) simply cancels it.
  Future<void> scheduleDailyQuestionBackstop({
    required List<int> minutesOfDay,
    required String title,
    required List<String> bodies,
  }) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelDailyQuestionBackstop();
    final times = minutesOfDay.take(_maxDailyQuestionTimes).toList();
    if (bodies.isEmpty || times.isEmpty) {
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    var id = _idDailyQuestionBackstopBase;
    var bodyIndex = 0;
    // Day-major so every covered day gets all of its times before we spend the
    // budget on a day further out.
    for (var dayOffset = 1; dayOffset <= _backstopDays; dayOffset++) {
      final day = now.add(Duration(days: dayOffset));
      for (final minuteOfDay in times) {
        if (id >= _idDailyQuestionBackstopBase + _maxDailyQuestionBackstop) {
          return;
        }
        final clamped = minuteOfDay.clamp(0, 24 * 60 - 1);
        final when = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          clamped ~/ 60,
          clamped % 60,
        );
        if (!when.isAfter(now)) {
          continue;
        }
        await _scheduleAt(
          id: id,
          when: when,
          title: title,
          body: bodies[bodyIndex % bodies.length],
        );
        id++;
        bodyIndex++;
      }
    }
  }

  /// Cancel the backstop band (1020–1033). Kept separate from
  /// [cancelDailyQuestion] on purpose: finishing today's question must clear
  /// TODAY's nudges while leaving the coming days' safety net armed.
  Future<void> cancelDailyQuestionBackstop() async {
    if (!_initialized) {
      return;
    }
    for (var i = 0; i < _maxDailyQuestionBackstop; i++) {
      try {
        await _plugin.cancel(_idDailyQuestionBackstopBase + i);
      } catch (_) {
        // Already in the desired state.
      }
    }
  }

  /// Cancel BOTH daily-question bands — the user-set times (plus the legacy id)
  /// AND the end-of-day safety net — WITHOUT requiring [initialize].
  ///
  /// `cancel` is a plain platform call (no timezone database, no permission
  /// setup), so unlike the other cancels here this one works from the FCM
  /// **background isolate**, where this service is a brand-new instance with
  /// `_initialized == false`. That's the whole point: when a "both answered" push
  /// arrives, today's armed nudges have become false ("người ấy chưa trả lời")
  /// and must be dropped even though no UI is alive to re-evaluate them.
  ///
  /// ⚠️ Deliberately does NOT touch the repeating backstop band (1020–1029):
  /// today being finished says nothing about tomorrow, and that band is the only
  /// reminder a user who stops opening the app will ever get.
  Future<void> cancelDailyQuestionBands() async {
    Future<void> drop(int id) async {
      try {
        await _plugin.cancel(id);
      } catch (_) {
        // Already in the desired state.
      }
    }

    await drop(_idDailyQuestion);
    for (var i = 0; i < _maxDailyQuestionTimes; i++) {
      await drop(_idDailyQuestionBase + i);
    }
    for (var i = 0; i < _maxDailyQuestionEod; i++) {
      await drop(_idDailyQuestionEodBase + i);
    }
  }

  /// Cancel every daily-question nudge: the legacy single id (older builds) and
  /// the whole multi-time band. Safe to call when nothing is scheduled.
  Future<void> cancelDailyQuestion() async {
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(_idDailyQuestion);
      for (var i = 0; i < _maxDailyQuestionTimes; i++) {
        await _plugin.cancel(_idDailyQuestionBase + i);
      }
    } catch (_) {
      // Already in the desired state.
    }
  }

  // ---------------------------------------------------------------------------
  // Lunar reminders (account-gated, 2026-06-19). [items] are pre-expanded by the
  // provider (one per occurrence × hour, each with its own title/body). Each is
  // a ONE-SHOT at a specific datetime — past ones are skipped. The whole band is
  // cleared first so this is safe to call repeatedly; an empty list = cancel.
  // ---------------------------------------------------------------------------
  Future<void> scheduleLunarReminders(
    List<({DateTime when, String title, String body})> items,
  ) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelLunar();
    final now = tz.TZDateTime.now(tz.local);
    var id = _idLunarBase;
    for (final it in items) {
      if (id >= _idLunarBase + _maxLunar) {
        break;
      }
      final when = tz.TZDateTime(
        tz.local,
        it.when.year,
        it.when.month,
        it.when.day,
        it.when.hour,
        it.when.minute,
      );
      if (!when.isAfter(now)) {
        continue;
      }
      await _scheduleAt(id: id, when: when, title: it.title, body: it.body);
      id++;
    }
  }

  Future<void> cancelLunar() async {
    if (!_initialized) {
      return;
    }
    try {
      for (var i = 0; i < _maxLunar; i++) {
        await _plugin.cancel(_idLunarBase + i);
      }
    } catch (_) {
      // Already in the desired state.
    }
  }

  // ---------------------------------------------------------------------------
  // Personal "anh By → embe" reminders (account-gated, 2026-06-20). Owned by the
  // gated account's [ReminderProvider.refreshPersonalReminders].
  // ---------------------------------------------------------------------------

  /// Daily-recurring medicine nudges — each [slot] repeats every day at its
  /// hour:minute (so it fires even without re-opening the app). Clears the band
  /// first; an empty list simply cancels everything.
  Future<void> schedulePersonalMedicineDaily(
    List<({int hour, int minute, String title, String body})> slots,
  ) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelPersonalMedicine();
    final capped = slots.take(_maxPersonalMedicine).toList();
    for (var i = 0; i < capped.length; i++) {
      final s = capped[i];
      await _scheduleAt(
        id: _idPersonalMedicineBase + i,
        when: _nextDaily(s.hour, s.minute),
        title: s.title,
        body: s.body,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelPersonalMedicine() async {
    if (!_initialized) {
      return;
    }
    for (var i = 0; i < _maxPersonalMedicine; i++) {
      try {
        await _plugin.cancel(_idPersonalMedicineBase + i);
      } catch (_) {
        // Already in the desired state.
      }
    }
  }

  /// One-shot "answer the question" nudges for TODAY only — past times are
  /// skipped (never rolled to tomorrow; the provider re-arms each day). Clears
  /// the band first, so calling with an empty list cancels everything.
  Future<void> schedulePersonalQuestionToday(
    List<({int hour, int minute, String title, String body})> slots,
  ) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelPersonalQuestion();
    final now = tz.TZDateTime.now(tz.local);
    final capped = slots.take(_maxPersonalQuestion).toList();
    for (var i = 0; i < capped.length; i++) {
      final s = capped[i];
      final when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        s.hour,
        s.minute,
      );
      if (!when.isAfter(now)) {
        continue;
      }
      await _scheduleAt(
        id: _idPersonalQuestionBase + i,
        when: when,
        title: s.title,
        body: s.body,
      );
    }
  }

  Future<void> cancelPersonalQuestion() async {
    if (!_initialized) {
      return;
    }
    for (var i = 0; i < _maxPersonalQuestion; i++) {
      try {
        await _plugin.cancel(_idPersonalQuestionBase + i);
      } catch (_) {
        // Already in the desired state.
      }
    }
  }

  /// One-shot "embe còn câu hỏi cũ chưa trả lời" nudges for TODAY only
  /// (feature `catch-up`, 2026-09-05, band 1140–1159). Same shape as
  /// [schedulePersonalQuestionToday]: past times are skipped, the band is
  /// cleared first, and an empty list simply cancels everything.
  Future<void> schedulePersonalCatchup(
    List<({int hour, int minute, String title, String body})> slots,
  ) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelPersonalCatchup();
    final now = tz.TZDateTime.now(tz.local);
    final capped = slots.take(_maxPersonalCatchup).toList();
    for (var i = 0; i < capped.length; i++) {
      final s = capped[i];
      final when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        s.hour,
        s.minute,
      );
      if (!when.isAfter(now)) {
        continue;
      }
      await _scheduleAt(
        id: _idPersonalCatchupBase + i,
        when: when,
        title: s.title,
        body: s.body,
      );
    }
  }

  Future<void> cancelPersonalCatchup() async {
    if (!_initialized) {
      return;
    }
    for (var i = 0; i < _maxPersonalCatchup; i++) {
      try {
        await _plugin.cancel(_idPersonalCatchupBase + i);
      } catch (_) {
        // Already in the desired state.
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Invite follow-ups (feature onboarding) — band 1180–1189.
  // ---------------------------------------------------------------------------

  /// (Re)arm the invite follow-up nudges: ONE-SHOTs at [anchor] + 24h and
  /// [anchor] + 72h (the couple was created at [anchor]). Slots already in the
  /// past are skipped; when BOTH are past — the couple has been waiting for days
  /// and the app just got opened — a single nudge is armed at now + 24h so a
  /// long-waiting member still gets reminded. [bodies] rotates over the armed
  /// slots. Clears the band first, so this is safe to call repeatedly.
  Future<void> scheduleInviteFollowUps({
    required DateTime anchor,
    required String title,
    required List<String> bodies,
  }) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelInviteFollowUps();
    if (bodies.isEmpty) {
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final base = tz.TZDateTime.from(anchor, tz.local);
    final candidates = <tz.TZDateTime>[
      base.add(const Duration(hours: 24)),
      base.add(const Duration(hours: 72)),
    ].where((when) => when.isAfter(now)).toList();
    if (candidates.isEmpty) {
      // Everything already elapsed → one catch-up ping a day from now.
      candidates.add(now.add(const Duration(hours: 24)));
    }
    var id = _idInviteFollowUpBase;
    for (var i = 0; i < candidates.length; i++) {
      if (id >= _idInviteFollowUpBase + _maxInviteFollowUps) {
        return;
      }
      await _scheduleAt(
        id: id,
        when: candidates[i],
        title: title,
        body: bodies[i % bodies.length],
      );
      id++;
    }
  }

  /// Cancel the invite follow-up band (1180–1189) — called as soon as the
  /// partner joins (or the member leaves the waiting state).
  Future<void> cancelInviteFollowUps() async {
    if (!_initialized) {
      return;
    }
    for (var i = 0; i < _maxInviteFollowUps; i++) {
      try {
        await _plugin.cancel(_idInviteFollowUpBase + i);
      } catch (_) {
        // Already in the desired state.
      }
    }
  }

  /// Cancel ALL personal bands — used when the signed-in account is not the
  /// gated one (or on reset).
  Future<void> cancelPersonalReminders() async {
    await cancelPersonalMedicine();
    await cancelPersonalQuestion();
    await cancelPersonalCatchup();
  }

  // ---------------------------------------------------------------------------
  // Partner reminders (feature partner-nudge). The author sets these in
  // Firestore; the RECIPIENT's device arms them locally here (band 3000–3049).
  // Each item carries a transient [CustomReminder] (only its date/time/
  // recurrence matter — id is ignored) plus the localized title/body to show.
  // ---------------------------------------------------------------------------

  /// (Re)arm the recipient-side local notifications for the partner reminders.
  /// Clears the whole band first, so calling with an empty list cancels
  /// everything. A `once` reminder already in the past is simply skipped
  /// (handled by [scheduleCustom]).
  Future<void> schedulePartnerReminders(
    List<({CustomReminder reminder, String title, String body})> items,
  ) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelPartnerReminders();
    final capped = items.take(_maxPartnerReminders).toList();
    for (var i = 0; i < capped.length; i++) {
      final item = capped[i];
      await scheduleCustom(
        id: _idPartnerReminderBase + i,
        reminder: item.reminder,
        title: item.title,
        body: item.body,
      );
    }
  }

  /// Cancel every partner-reminder local notification. Safe when nothing is set
  /// (e.g. sign-out / no couple).
  Future<void> cancelPartnerReminders() async {
    if (!_initialized) {
      return;
    }
    for (var i = 0; i < _maxPartnerReminders; i++) {
      try {
        await _plugin.cancel(_idPartnerReminderBase + i);
      } catch (_) {
        // Already in the desired state.
      }
    }
  }

  /// (Re)schedule today's end-of-day daily-question nudges. Each [slot] fires
  /// once, TODAY, at its hour:minute — but only if that moment is still in the
  /// future (past slots are skipped, never rolled to tomorrow, because tomorrow
  /// the provider re-arms with fresh state). One-shot: no repeat component.
  /// Clears the whole band first, so this is safe to call repeatedly and an
  /// empty list simply cancels everything.
  Future<void> scheduleDailyQuestionEndOfDay({
    required List<DailyQuestionEodSlot> slots,
  }) async {
    await initialize();
    if (!_initialized) {
      return;
    }
    await cancelDailyQuestionEndOfDay();
    final now = tz.TZDateTime.now(tz.local);
    final capped = slots.take(_maxDailyQuestionEod).toList();
    for (var i = 0; i < capped.length; i++) {
      final slot = capped[i];
      final when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        slot.hour,
        slot.minute,
      );
      // Already passed today — leave it unscheduled; tomorrow's re-arm covers it.
      if (!when.isAfter(now)) {
        continue;
      }
      await _scheduleAt(
        id: _idDailyQuestionEodBase + i,
        when: when,
        title: slot.title,
        body: slot.body,
      );
    }
  }

  /// Cancel every end-of-day daily-question nudge. Safe when nothing is set.
  Future<void> cancelDailyQuestionEndOfDay() async {
    if (!_initialized) {
      return;
    }
    for (var i = 0; i < _maxDailyQuestionEod; i++) {
      try {
        await _plugin.cancel(_idDailyQuestionEodBase + i);
      } catch (_) {
        // Already in the desired state.
      }
    }
  }

  /// The next [hour]:[minute] today, or tomorrow if that moment has passed.
  tz.TZDateTime _nextDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
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
        final when = tz.TZDateTime(
          tz.local,
          date.year,
          date.month,
          date.day,
          h,
          m,
        );
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
  tz.TZDateTime _clampedDate(
    int year,
    int month,
    int day,
    int hour,
    int minute,
  ) {
    final lastDay = _daysInMonth(year, month);
    final safeDay = day > lastDay ? lastDay : day;
    return tz.TZDateTime(tz.local, year, month, safeDay, hour, minute);
  }

  int _daysInMonth(int year, int month) {
    // The 0th day of the next month is the last day of this month.
    final firstOfNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
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
