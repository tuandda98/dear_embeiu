import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/milestone_reminder.dart';
import '../services/home_prefs_service.dart';
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
  // Multi-time daily-question reminder (2026-06-14): a list of minutes-since-
  // midnight. The legacy single hour/minute keys are read once for migration.
  static const String _dqTimesKey = 'dqReminderTimes';
  static const String _dqLegacyHourKey = 'dqReminderHour';
  static const String _dqLegacyMinuteKey = 'dqReminderMinute';

  /// Max number of daily-question reminder times (mirrors the Firestore-rule
  /// + ReminderService caps).
  static const int maxDailyQuestionTimes = 10;

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

  // Daily-question reminder state. Defaults: on, a single 20:00 nudge. Now
  // COUPLE-SHARED (2026-06-14): the enabled flag + the list of fire times sync
  // through couples/{id}/prefs/home so both phones nudge together; Hive is the
  // offline cache. Times are minutes-since-midnight, sorted, de-duped, ≤10.
  bool _dqEnabled = true;
  List<int> _dqTimes = <int>[20 * 60];

  final HomePrefsService _homePrefs = HomePrefsService();
  String? _dqCoupleId;
  StreamSubscription<ReminderPrefs>? _dqPrefsSub;

  /// Whether the daily-question nudge is on.
  bool get dailyQuestionReminderEnabled => _dqEnabled;

  /// The fire times of the daily-question nudge (sorted) as [TimeOfDay].
  List<TimeOfDay> get dailyQuestionReminderTimes => _dqTimes
      .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60))
      .toList(growable: false);

  /// Whether another time can still be added (cap [maxDailyQuestionTimes]).
  bool get canAddDailyQuestionTime => _dqTimes.length < maxDailyQuestionTimes;

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
        // Master toggle removed (2026-06-14): milestones auto-remind. The legacy
        // enabled flag is forced true; only hour/minute (default time) matter.
        enabled: true,
        hour: box.get(_hourKey, defaultValue: 20) as int,
        minute: box.get(_minuteKey, defaultValue: 0) as int,
      );
      // Daily-question reminder: default on at 20:00. Migrate the old single
      // hour/minute keys into the new times list on first load after upgrade.
      _dqEnabled = box.get(_dqEnabledKey, defaultValue: true) as bool;
      final storedTimes = box.get(_dqTimesKey);
      if (storedTimes is List && storedTimes.isNotEmpty) {
        _dqTimes = _normalizeTimes(
          storedTimes.whereType<num>().map((n) => n.toInt()),
        );
      } else {
        final legacyHour = box.get(_dqLegacyHourKey);
        final legacyMinute = box.get(_dqLegacyMinuteKey);
        if (legacyHour is int && legacyMinute is int) {
          _dqTimes = _normalizeTimes(<int>[legacyHour * 60 + legacyMinute]);
        }
      }
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
      await box.put(_dqTimesKey, _dqTimes);
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
    if (anniversary != null && strings != null) {
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

    final anniversary = _lastAnniversary;
    final l10n = _lastL10n;
    if (anniversary != null && l10n != null) {
      if (value) {
        await _scheduleMilestone(type, anniversary, l10n);
      } else {
        await _service.cancelMilestone(type);
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

    final anniversary = _lastAnniversary;
    final l10n = _lastL10n;
    if (anniversary != null && l10n != null && isMilestoneEnabled(type)) {
      await _scheduleMilestone(type, anniversary, l10n);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Daily-question reminder. One or more repeating-daily nudges pulling both
  // partners in to answer the day's question. COUPLE-SHARED (2026-06-14): the
  // enabled flag + the fire times sync through couples/{id}/prefs/home, so an
  // edit on either phone moves both. The notifications themselves stay LOCAL on
  // each device; Hive is the offline cache.
  // ---------------------------------------------------------------------------

  /// Follow the couple's shared daily-question reminder prefs. Wired from
  /// SessionResolver when a couple is active; a partner's edit flows in here
  /// and reschedules the local nudges. Re-subscribes when the couple changes.
  void watchCoupleReminderPrefs(String coupleId) {
    if (coupleId.trim().isEmpty) {
      return;
    }
    _dqCoupleId = coupleId;
    _dqPrefsSub?.cancel();
    _dqPrefsSub = _homePrefs.watchReminderPrefs(coupleId).listen((prefs) {
      var changed = false;
      if (prefs.enabled != null && prefs.enabled != _dqEnabled) {
        _dqEnabled = prefs.enabled!;
        changed = true;
      }
      if (prefs.times != null) {
        final normalized = _normalizeTimes(prefs.times!);
        if (!_sameTimes(normalized, _dqTimes)) {
          _dqTimes = normalized;
          changed = true;
        }
      }
      if (!changed) {
        return;
      }
      _persistDailyQuestion();
      // Reschedule with the copy cached by [sync] (from HomeScreen). If l10n
      // isn't ready yet, the next sync after Home builds arms it.
      final l10n = _lastL10n;
      if (l10n != null) {
        _scheduleDailyQuestion(l10n);
      }
      notifyListeners();
    });
  }

  /// Turn the daily-question nudge on or off (couple-shared).
  ///
  /// Enabling first requests OS notification permission. Returns whether the
  /// reminder is now on: `false` means the user denied permission. The change
  /// is published to the shared prefs so the partner's phone follows.
  Future<bool> setDailyQuestionReminderEnabled(
    bool value, {
    required AppLocalizations l10n,
  }) async {
    if (value) {
      final granted = await _service.requestPermissions();
      if (!granted) {
        _dqEnabled = false;
        await _persistDailyQuestion();
        notifyListeners();
        return false;
      }
    }
    _dqEnabled = value;
    await _persistDailyQuestion();
    await _scheduleDailyQuestion(l10n);
    _publishReminderPrefs(enabled: value);
    notifyListeners();
    return true;
  }

  /// Replace the full set of fire times (couple-shared). Times are normalized
  /// (clamped, de-duped, sorted, capped at [maxDailyQuestionTimes]).
  Future<void> setDailyQuestionTimes(
    List<TimeOfDay> times, {
    required AppLocalizations l10n,
  }) async {
    _dqTimes = _normalizeTimes(times.map((t) => t.hour * 60 + t.minute));
    await _persistDailyQuestion();
    await _scheduleDailyQuestion(l10n);
    _publishReminderPrefs(times: _dqTimes);
    notifyListeners();
  }

  /// Add one fire time (no-op past the cap or when it already exists).
  Future<void> addDailyQuestionTime(
    TimeOfDay time, {
    required AppLocalizations l10n,
  }) async {
    if (!canAddDailyQuestionTime) {
      return;
    }
    await setDailyQuestionTimes(
      dailyQuestionReminderTimes..add(time),
      l10n: l10n,
    );
  }

  /// Remove the fire time at [index] in the sorted list.
  Future<void> removeDailyQuestionTime(
    int index, {
    required AppLocalizations l10n,
  }) async {
    final next = dailyQuestionReminderTimes;
    if (index < 0 || index >= next.length) {
      return;
    }
    next.removeAt(index);
    await setDailyQuestionTimes(next, l10n: l10n);
  }

  void _publishReminderPrefs({bool? enabled, List<int>? times}) {
    final coupleId = _dqCoupleId;
    if (coupleId == null) {
      return;
    }
    // Fire-and-forget; the service swallows offline/rules errors.
    unawaited(
      _homePrefs.setReminderPrefs(coupleId, enabled: enabled, times: times),
    );
  }

  /// (Re)schedule the daily-question nudge(s) with the localized copy. Clears
  /// the previous schedule first, so safe to call repeatedly; off / no-times
  /// simply cancels everything.
  Future<void> _scheduleDailyQuestion(AppLocalizations l10n) async {
    if (!_dqEnabled || _dqTimes.isEmpty) {
      await _service.cancelDailyQuestion();
      return;
    }
    await _service.scheduleDailyQuestionTimes(
      minutesOfDay: _dqTimes,
      title: l10n.dailyQuestionReminderNotifTitle,
      body: l10n.dailyQuestionReminderNotifBody,
    );
  }

  /// Clamp each minute-of-day to 0–1439, de-dupe, sort, cap at the max.
  List<int> _normalizeTimes(Iterable<int> raw) {
    final set = <int>{for (final m in raw) m.clamp(0, 24 * 60 - 1)};
    final list = set.toList()..sort();
    return list.length > maxDailyQuestionTimes
        ? list.sublist(0, maxDailyQuestionTimes)
        : list;
  }

  bool _sameTimes(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
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

    // Daily-question nudge: self-gates on enabled/times (cancels when off).
    await _scheduleDailyQuestion(l10n);

    // Milestones auto-remind (2026-06-14: no master toggle) — always reschedule
    // the enabled milestones from the latest couple data.
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
    _dqPrefsSub?.cancel();
    _dqPrefsSub = null;
    _dqCoupleId = null;
    await _service.cancelDailyQuestion();
  }

  @override
  void dispose() {
    _dqPrefsSub?.cancel();
    super.dispose();
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
