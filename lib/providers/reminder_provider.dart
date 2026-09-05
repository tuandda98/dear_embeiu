import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/milestone_reminder.dart';
import '../services/home_prefs_service.dart';
import '../services/catchup_service.dart';
import '../services/reminder_service.dart';
import '../utils/lunar_calendar.dart';

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

  // Lunar reminder (account-gated, 2026-06-19): nudge on chosen lunar days at
  // chosen times. LOCAL only; Hive drives scheduling, UI is gated by email in
  // Settings. Days/times are user-configurable (2026-06-19 v2); defaults are
  // mồng-1 & ngày-rằm at 07:00/08:00/09:00.
  static const String _lunarEnabledKey = 'lunar_reminder_enabled';
  static const String _lunarTimesKey = 'lunar_reminder_times'; // minutes list
  static const String _lunarDaysKey = 'lunar_reminder_days'; // lunar day list
  static const List<int> _lunarDefaultTimes = <int>[7 * 60, 8 * 60, 9 * 60];
  static const List<int> _lunarDefaultDays = <int>[1, 15];
  static const int _maxLunarTimes = 6;
  // How many upcoming occurrences to schedule per refresh. Kept small (×times ≤
  // band size 40 and the iOS 64-pending cap) — topped up each app open.
  static const int _lunarWindow = 8;

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

  // Lunar reminder (account-gated). Off by default; only the gated account's
  // Settings card can flip it. Days = lunar day-of-month numbers; times =
  // minutes-since-midnight. See [_lunarEnabledKey].
  bool _lunarEnabled = false;
  List<int> _lunarTimes = List<int>.of(_lunarDefaultTimes);
  List<int> _lunarDays = List<int>.of(_lunarDefaultDays);

  /// Whether the lunar reminder is on.
  bool get lunarEnabled => _lunarEnabled;

  /// Reminder times (sorted) as [TimeOfDay].
  List<TimeOfDay> get lunarTimes => _lunarTimes
      .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60))
      .toList(growable: false);

  /// Lunar day-of-month numbers to remind on (sorted, e.g. [1, 15]).
  List<int> get lunarDays => List<int>.unmodifiable(_lunarDays);

  /// Whether another reminder time can still be added (cap [_maxLunarTimes]).
  bool get canAddLunarTime => _lunarTimes.length < _maxLunarTimes;

  // Daily-question end-of-day safety net (2026-06-19). On top of the user's
  // chosen reminder times, while the couple hasn't both answered today's
  // question we fire fixed local one-shots: 21:00 (gentle nudge) + 22:00 and
  // 23:00 (streak warnings). 2026-08-09: the two warnings are armed ONLY while I
  // still haven't answered — see [_scheduleEndOfDay]. LOCAL only — never synced;
  // the copy is derived from the latest habit state cached here so enable/disable
  // can re-arm correctly.
  static const List<int> _eodHours = <int>[21, 22, 23];
  bool _eodHasRevealed = false;
  bool _eodIAnswered = false;
  int _eodStreak = 0;
  // Whether the couple is fully formed (partner joined). A couple still in
  // `waiting_partner` can't complete a question together, so every daily-question
  // nudge is cancelled for it (2026-08-09). Defaults to true so the very first
  // schedule — which may run from session_resolver before HomeScreen's first
  // [sync] lands — behaves exactly as before for a normal, active couple.
  bool _coupleActive = true;
  // Debounce signature so the frequent provider notifications that drive
  // [refreshDailyQuestionSafetyNet] don't thrash the OS schedule.
  String? _eodSignature;
  // Same, for the user-set daily-question nudge (now answer-aware: suppressed
  // when both answered, partner-nudge copy when only I have — shares the cached
  // [_eodHasRevealed]/[_eodIAnswered] habit state).
  String? _dqScheduleSignature;
  // True only on the gated account's device (em bé): her private hourly nudge
  // ([refreshPersonalReminders]) replaces the SHARED daily-question + end-of-day
  // nudges, which are suppressed LOCALLY here to avoid double notifications. Does
  // NOT change the couple-shared on/off setting — the partner still gets them.
  bool _suppressSharedDqReminders = false;

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

  /// True on the account whose private hourly nudge replaces the shared
  /// daily-question reminders (they are suppressed there to avoid doubling up).
  /// Settings hides the tile in that case rather than showing a switch that reads
  /// ON while nothing is ever scheduled (2026-08-09).
  bool get sharedDailyQuestionRemindersSuppressed =>
      _suppressSharedDqReminders;

  /// On/off state per milestone. Initialised to the Dv4 defaults and overridden
  /// by persisted values in [load].
  final Map<MilestoneType, bool> _milestones = Map<MilestoneType, bool>.from(
    kMilestoneDefaults,
  );

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
  int get enabledMilestoneCount => _milestones.values.where((on) => on).length;

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
      _lunarEnabled = box.get(_lunarEnabledKey, defaultValue: false) as bool;
      final storedLunarTimes = box.get(_lunarTimesKey);
      if (storedLunarTimes is List && storedLunarTimes.isNotEmpty) {
        _lunarTimes = _normalizeLunarTimes(
          storedLunarTimes.whereType<num>().map((n) => n.toInt()),
        );
      }
      final storedLunarDays = box.get(_lunarDaysKey);
      if (storedLunarDays is List && storedLunarDays.isNotEmpty) {
        _lunarDays = _normalizeLunarDays(
          storedLunarDays.whereType<num>().map((n) => n.toInt()),
        );
      }
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
        final storedHour = box.get(
          '$_milestoneTimePrefix${type.name}$_milestoneHourSuffix',
        );
        final storedMinute = box.get(
          '$_milestoneTimePrefix${type.name}$_milestoneMinuteSuffix',
        );
        if (storedHour is int && storedMinute is int) {
          _milestoneTimes[type] = TimeOfDay(
            hour: storedHour,
            minute: storedMinute,
          );
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

  Future<void> _persistLunar() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      await box.put(_lunarEnabledKey, _lunarEnabled);
      await box.put(_lunarTimesKey, _lunarTimes);
      await box.put(_lunarDaysKey, _lunarDays);
    } catch (error) {
      debugPrint('ReminderProvider._persistLunar failed: $error');
    }
  }

  /// Sort + de-dup + clamp reminder times (minutes 0..1439), capped at
  /// [_maxLunarTimes]. Empty input falls back to the defaults.
  List<int> _normalizeLunarTimes(Iterable<int> minutes) {
    final set = <int>{};
    for (final m in minutes) {
      set.add(m.clamp(0, 24 * 60 - 1));
    }
    final list = set.toList()..sort();
    if (list.isEmpty) {
      return List<int>.of(_lunarDefaultTimes);
    }
    return list.take(_maxLunarTimes).toList();
  }

  /// Sort + de-dup + clamp lunar day numbers (1..30). Empty falls back to the
  /// defaults (mồng-1 & ngày-rằm).
  List<int> _normalizeLunarDays(Iterable<int> days) {
    final set = <int>{};
    for (final d in days) {
      if (d >= 1 && d <= 30) {
        set.add(d);
      }
    }
    final list = set.toList()..sort();
    return list.isEmpty ? List<int>.of(_lunarDefaultDays) : list;
  }

  /// Turn the lunar reminder on or off and (re)schedule. [l10n] supplies the
  /// notification copy; falls back to the cached locale.
  Future<void> setLunarEnabled(bool enabled, {AppLocalizations? l10n}) async {
    _lunarEnabled = enabled;
    await _persistLunar();
    await refreshLunar(l10n ?? _lastL10n);
    notifyListeners();
  }

  /// Replace the reminder times (normalized) and reschedule.
  Future<void> setLunarTimes(
    Iterable<int> minutes, {
    AppLocalizations? l10n,
  }) async {
    _lunarTimes = _normalizeLunarTimes(minutes);
    await _persistLunar();
    await refreshLunar(l10n ?? _lastL10n);
    notifyListeners();
  }

  /// Replace the lunar days (normalized) and reschedule.
  Future<void> setLunarDays(
    Iterable<int> days, {
    AppLocalizations? l10n,
  }) async {
    _lunarDays = _normalizeLunarDays(days);
    await _persistLunar();
    await refreshLunar(l10n ?? _lastL10n);
    notifyListeners();
  }

  /// (Re)compute the upcoming occurrences (for the chosen [_lunarDays]) and
  /// reschedule one-shots at each of [_lunarTimes]. No-op (cancels) when disabled
  /// or when no localized copy is available yet. Called on every change and from
  /// [sync] each app open so the rolling window stays topped up.
  Future<void> refreshLunar(AppLocalizations? l10n) async {
    if (!_lunarEnabled || l10n == null || _lunarDays.isEmpty) {
      await _service.cancelLunar();
      return;
    }
    final events = LunarCalendar.nextLunarDays(
      DateTime.now(),
      _lunarDays.toSet(),
      _lunarWindow,
    );
    final items = <({DateTime when, String title, String body})>[];
    for (final e in events) {
      final String title;
      final String body;
      if (e.lunarDay == 1) {
        title = l10n.lunarNewMoonNotifTitle;
        body = l10n.lunarNewMoonNotifBody;
      } else if (e.lunarDay == 15) {
        title = l10n.lunarFullMoonNotifTitle;
        body = l10n.lunarFullMoonNotifBody;
      } else {
        title = l10n.lunarOtherDayNotifTitle(e.lunarDay);
        body = l10n.lunarOtherDayNotifBody(e.lunarDay);
      }
      for (final m in _lunarTimes) {
        items.add((
          when: DateTime(
            e.date.year,
            e.date.month,
            e.date.day,
            m ~/ 60,
            m % 60,
          ),
          title: title,
          body: body,
        ));
      }
    }
    // Cap the total one-shots so the lunar band + the other reminder bands stay
    // well under the iOS 64-pending limit. Items are built soonest-first, so the
    // nearest occurrences are kept; the window is topped up each app open.
    const maxItems = 24;
    final capped = items.length > maxItems ? items.sublist(0, maxItems) : items;
    await _service.scheduleLunarReminders(capped);
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
      final hourKey = '$_milestoneTimePrefix${type.name}$_milestoneHourSuffix';
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
        // A remote enable/disable also flips the end-of-day net.
        _scheduleEndOfDay(l10n);
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
    // Re-arm / clear the end-of-day safety net to match (uses the last-known
    // habit state; HomeScreen refreshes it with live state right after).
    await _scheduleEndOfDay(l10n);
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
    // `dailyQuestionReminderTimes` is fixed-length — copy before appending.
    await setDailyQuestionTimes(<TimeOfDay>[
      ...dailyQuestionReminderTimes,
      time,
    ], l10n: l10n);
  }

  /// Remove the fire time at [index] in the sorted list.
  Future<void> removeDailyQuestionTime(
    int index, {
    required AppLocalizations l10n,
  }) async {
    // `dailyQuestionReminderTimes` is fixed-length — copy before removing.
    final next = List<TimeOfDay>.of(dailyQuestionReminderTimes);
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

  /// The end-of-day hours that WILL actually be armed right now — 21/22/23h
  /// normally, only 21h once I've answered (see [_scheduleEndOfDay]). Used both
  /// there and by [_scheduleDailyQuestion], which drops any user-set time landing
  /// on one of these hours so the two bands can't fire twice in the same minute.
  List<int> get _activeEodHours =>
      _eodIAnswered ? const <int>[21] : _eodHours;

  /// (Re)schedule the user-set daily-question nudge(s) with the localized copy,
  /// **answer-aware** (2026-06-20). Two bands, both driven by the habit state
  /// cached in [_eodHasRevealed]/[_eodIAnswered]:
  ///
  /// • TODAY (one-shot, ids 1040–1049) —
  ///   both answered ([_eodHasRevealed]) → cancel (nothing to nudge about today);
  ///   I answered but partner hasn't ([_eodIAnswered]) → "nhắc người ấy" copy,
  ///   with its own title (the default one says the question is waiting, which
  ///   would contradict the body once my half is done);
  ///   neither / only partner → default "trả lời đi".
  ///   Times that collide with an [_activeEodHours] slot are dropped — the
  ///   end-of-day nudge already covers that minute with more specific copy.
  /// • BACKSTOP (rolling one-shots for the next 7 days, from TOMORROW, ids
  ///   1020–1033) — untouched by today's answer state, because it can only ever
  ///   fire on a day the app was never opened (2026-08-09, fixes "no app open ⇒
  ///   no reminder at all").
  ///
  /// Debounced on enabled|revealed|iAnswered|times|coupleActive|day so the frequent
  /// provider notifications don't thrash the OS schedule. Clears each band first,
  /// so safe to call repeatedly.
  Future<void> _scheduleDailyQuestion(AppLocalizations l10n) async {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    final signature = <Object>[
      _dqEnabled,
      _suppressSharedDqReminders,
      _coupleActive,
      _eodHasRevealed,
      _eodIAnswered,
      _dqTimes.join(','),
      dayKey,
    ].join('|');
    if (signature == _dqScheduleSignature) {
      return;
    }
    _dqScheduleSignature = signature;

    // Off, suppressed for em bé (her hourly nudge covers it), no times, or no
    // partner yet → nothing to nudge about at all, today or later. A couple still
    // waiting for the partner to join can't complete a question together, so
    // nudging them (up to 4×/day) is pure noise (2026-08-09).
    if (!_dqEnabled ||
        _suppressSharedDqReminders ||
        _dqTimes.isEmpty ||
        !_coupleActive) {
      await _service.cancelDailyQuestion();
      await _service.cancelDailyQuestionBackstop();
      return;
    }

    // Rotating bodies so several times a day don't read as one sentence on
    // repeat. Only the "I'm waiting for them" case is a single fixed line.
    final bodies = _eodIAnswered
        ? <String>[l10n.dqEndOfDayNudgePartnerBody]
        : <String>[
            l10n.dailyQuestionReminderNotifBody,
            l10n.dailyQuestionReminderNotifBodyAlt1,
            l10n.dailyQuestionReminderNotifBodyAlt2,
          ];
    final title = _eodIAnswered
        ? l10n.dqPartnerOnlyNudgeTitle
        : l10n.dailyQuestionReminderNotifTitle;

    // The backstop stays armed even when today is already complete — it is about
    // the days AFTER today, and it always uses the plain "come answer" copy.
    await _service.scheduleDailyQuestionBackstop(
      minutesOfDay: _dqTimes,
      title: l10n.dailyQuestionReminderNotifTitle,
      bodies: <String>[
        l10n.dailyQuestionReminderNotifBody,
        l10n.dailyQuestionReminderNotifBodyAlt1,
        l10n.dailyQuestionReminderNotifBodyAlt2,
      ],
    );

    if (_eodHasRevealed) {
      await _service.cancelDailyQuestion();
      return;
    }

    // Drop times that an end-of-day slot already owns (no double notification in
    // the same minute).
    final eodMinutes = _activeEodHours.map((h) => h * 60).toSet();
    final times =
        _dqTimes.where((minute) => !eodMinutes.contains(minute)).toList();

    await _service.scheduleDailyQuestionTimes(
      minutesOfDay: times,
      title: title,
      bodies: bodies,
    );
  }

  /// Re-arm (or clear) today's end-of-day daily-question nudges from the latest
  /// habit state. Wired from HomeScreen on every daily-question / streak update
  /// (and once on launch). Cheap + idempotent — debounced on a signature so the
  /// frequent provider notifications don't reschedule needlessly. LOCAL only.
  ///
  /// While the couple hasn't both answered today ([hasRevealed] == false) and
  /// the reminder is on, fires one-shots for TODAY: 21:00 nudges, and — only when
  /// I haven't answered yet — 22:00 + 23:00 warn about the streak ([currentStreak]
  /// picks "keep your N-day streak" vs "start a streak"). Once [iAnswered], the
  /// 21:00 ping switches to "nudge your partner" and the two warnings are dropped
  /// (see [_scheduleEndOfDay]). Cancels everything once both have answered or the
  /// reminder is off.
  Future<void> refreshDailyQuestionSafetyNet({
    required bool hasRevealed,
    required bool iAnswered,
    required int currentStreak,
    required AppLocalizations l10n,
  }) async {
    _eodHasRevealed = hasRevealed;
    _eodIAnswered = iAnswered;
    _eodStreak = currentStreak;
    _lastL10n = l10n;
    // Re-arm the user-set nudge too: it now shares this answer state so it can
    // suppress / swap copy the moment someone answers (not just the EOD net).
    await _scheduleDailyQuestion(l10n);
    await _scheduleEndOfDay(l10n);
  }

  /// Compute and apply the end-of-day schedule from the cached habit state.
  /// Shared by [refreshDailyQuestionSafetyNet] and the enable/disable paths (so
  /// toggling re-arms with the right copy). Debounced via [_eodSignature].
  Future<void> _scheduleEndOfDay(AppLocalizations l10n) async {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    final signature = <Object>[
      _dqEnabled,
      _suppressSharedDqReminders,
      _coupleActive,
      _eodHasRevealed,
      _eodIAnswered,
      _eodStreak,
      dayKey,
    ].join('|');
    if (signature == _eodSignature) {
      return;
    }
    _eodSignature = signature;

    // Off, suppressed for em bé (her hourly nudge covers it), no partner yet, or
    // today already complete → nothing to warn about.
    if (!_dqEnabled ||
        _suppressSharedDqReminders ||
        !_coupleActive ||
        _eodHasRevealed) {
      await _service.cancelDailyQuestionEndOfDay();
      return;
    }

    // Which slots to arm (2026-08-09). Once I've answered, keep ONLY the gentle
    // 21:00 "nudge your partner" ping and drop both streak warnings:
    //  • my half is done, so warning ME about the streak twice more is noise;
    //  • these are one-shots armed hours in advance — if the partner answers
    //    while my app is closed, the "chưa trả lời" premise silently goes stale
    //    (the push-driven cancel in PushNotificationService covers most of that,
    //    but not an iOS app the user force-quit), and a false "sắp lỡ mất chuỗi"
    //    at 22h AND 23h is the worst-feeling way to be wrong.
    final hours = _activeEodHours;

    final slots = <DailyQuestionEodSlot>[];
    for (final hour in hours) {
      final String title;
      final String body;
      if (hour < 22) {
        // 21:00 — gentle nudge, still in time to act.
        title = l10n.dqEndOfDayNudgeTitle;
        body = _eodIAnswered
            ? l10n.dqEndOfDayNudgePartnerBody
            : l10n.dqEndOfDayNudgeBody;
      } else if (hour == 22) {
        // 22:00 — streak warning. No streak yet → frame it as starting one.
        title = l10n.dqStreakWarningTitle;
        body = _eodStreak >= 1
            ? l10n.dqStreakWarningBody(_eodStreak)
            : l10n.dqStreakWarningStartBody;
      } else {
        // 23:00 — last call. Its own copy: it used to reuse 22:00's title AND
        // body verbatim, so the user got the identical notification twice.
        title = l10n.dqStreakWarningFinalTitle;
        body = _eodStreak >= 1
            ? l10n.dqStreakWarningFinalBody(_eodStreak)
            : l10n.dqStreakWarningFinalStartBody;
      }
      slots.add(
        DailyQuestionEodSlot(hour: hour, minute: 0, title: title, body: body),
      );
    }
    await _service.scheduleDailyQuestionEndOfDay(slots: slots);
  }

  // ---------------------------------------------------------------------------
  // Personal "anh By → embe" reminders (account-gated, 2026-06-20). A private
  // nudge schedule for ONE account (em bé). LOCAL only; gentle/affectionate copy
  // hardcoded in Vietnamese (gated to a single VN account, so no l10n needed).
  // ---------------------------------------------------------------------------
  // Single source of truth shared with the catch-up gate (CatchupService).
  static const String _personalAccountEmail = CatchupService.gatedEmail;

  // Hourly "answer the question" nudges run 7h → 22h (but stop earlier the
  // moment she answers — see [refreshPersonalReminders]).
  static const int _personalQuestionStartHour = 7;
  static const int _personalQuestionEndHour = 22;

  static const String _personalQuestionTitle = 'Anh By nhắc nè 💕';
  static const List<String> _personalQuestionBodies = <String>[
    'Embe ơi, trả lời câu hỏi hôm nay cho anh By với nha 🥰',
    'Anh By đang đợi câu trả lời của embe nè 💗',
    'Dành chút xíu trả lời câu hỏi nha embe, anh By thương 🌷',
    'Embe trả lời rồi mình cùng xem câu của nhau nha 💞',
  ];

  static const String _personalMedicineTitle = 'Tới giờ uống thuốc rồi 💊';

  // Day the medicine band was last (re)armed; null = not the gated account.
  String? _personalMedicineDayKey;
  // Last applied "$iAnswered|$dayKey" for the hourly-question band; null = none.
  String? _personalQuestionSignature;

  /// (Re)arm or clear the private anh-By→embe nudges. Wired from HomeScreen on
  /// every daily-question update (+ once on launch). ONLY the gated account
  /// ([_personalAccountEmail]) gets them; any other signed-in account clears the
  /// bands. LOCAL only.
  ///  • medicine 9:59 / 10:10 / 10:30 — daily, ALWAYS (uống thuốc đúng giờ);
  ///    debounced on the day so it (re)arms at most once per day.
  ///  • "trả lời câu hỏi" every hour 7h–22h — today's remaining hours, but only
  ///    while she hasn't answered yet; stops the moment [iAnswered] is true.
  ///
  /// ⚠️ The hourly-question band is only touched on a SETTLED answer state
  /// ([isLoading] == false). While the daily-question stream is (re)subscribing
  /// it momentarily reports `iAnswered == false` (answers cleared to []), so
  /// acting then would re-arm the one-shots we just cancelled — and if the app
  /// backgrounds before the stream settles, those stale nudges survive and fire
  /// even after she has answered (the production bug, 2026-06-20).
  Future<void> refreshPersonalReminders({
    required String email,
    required bool iAnswered,
    required bool isLoading,
  }) async {
    final isTarget = email.trim().toLowerCase() == _personalAccountEmail;
    // Set synchronously (before any await) so the shared-reminder schedulers,
    // called right after this in HomeScreen's hook, see the right value: em bé's
    // device suppresses the shared daily-question + end-of-day nudges.
    _suppressSharedDqReminders = isTarget;

    if (!isTarget) {
      // Debounce the cleared state so a non-gated account doesn't re-cancel on
      // every provider notification.
      if (_personalMedicineDayKey == null &&
          _personalQuestionSignature == null) {
        return;
      }
      _personalMedicineDayKey = null;
      _personalQuestionSignature = null;
      // cancelPersonalReminders() also clears the catch-up band (1140–1159);
      // drop its debounce key too or a same-day re-login won't re-arm it.
      _personalCatchupSignature = null;
      await _service.cancelPersonalReminders();
      return;
    }

    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';

    // Medicine — daily-recurring, unconditional. Re-arm at most once per day
    // (the plugin keeps firing across days on its own; we only re-assert when the
    // day rolls over or this account just became the gated one). Runs even while
    // the question state is still loading, so meds aren't tied to the DQ stream.
    if (_personalMedicineDayKey != dayKey) {
      _personalMedicineDayKey = dayKey;
      await _service.schedulePersonalMedicineDaily(const [
        (
          hour: 9,
          minute: 59,
          title: _personalMedicineTitle,
          body:
              'Embe ơi, uống thuốc đúng giờ cho khỏe nha, anh By thương embe 🥰',
        ),
        (
          hour: 10,
          minute: 10,
          title: _personalMedicineTitle,
          body: 'Anh By nhắc embe uống thuốc nè, đừng quên nha 💕',
        ),
        (
          hour: 10,
          minute: 30,
          title: _personalMedicineTitle,
          body: 'Uống thuốc đúng giờ nha embe, để anh By yên tâm 💗',
        ),
      ]);
    }

    // Hourly "answer the question" nudges — act ONLY on a settled state (see the
    // doc above). A transient loading=true pass leaves the band untouched.
    if (isLoading) {
      return;
    }

    final questionSignature = '$iAnswered|$dayKey';
    if (questionSignature == _personalQuestionSignature) {
      return;
    }
    _personalQuestionSignature = questionSignature;

    // Stop the moment she's answered today; otherwise (re)arm today's remaining
    // hours.
    if (iAnswered) {
      await _service.cancelPersonalQuestion();
    } else {
      final slots = <({int hour, int minute, String title, String body})>[];
      for (
        var h = _personalQuestionStartHour;
        h <= _personalQuestionEndHour;
        h++
      ) {
        slots.add((
          hour: h,
          minute: 0,
          title: _personalQuestionTitle,
          body: _personalQuestionBodies[h % _personalQuestionBodies.length],
        ));
      }
      await _service.schedulePersonalQuestionToday(slots);
    }
  }

  // ---------------------------------------------------------------------------
  // Catch-up nudges (feature `catch-up`, 2026-09-05) — SAME gated account. Fire
  // only while she still has PAST days with no answer of hers; the copy names
  // how many are waiting so the nudge stays concrete. LOCAL only, band
  // 1140–1159, independent of the hourly-question band above (that one is about
  // TODAY, this one about the backlog).
  // ---------------------------------------------------------------------------

  /// Slots armed for today whenever there's a backlog (past hours are skipped
  /// by the service).
  static const List<({int hour, int minute})> _personalCatchupSlots =
      <({int hour, int minute})>[
        (hour: 9, minute: 30),
        (hour: 11, minute: 30),
        (hour: 13, minute: 30),
        (hour: 15, minute: 30),
        (hour: 17, minute: 30),
        (hour: 19, minute: 30),
        (hour: 21, minute: 30),
      ];

  /// Every title starts with "Anh By <3 " (user requirement).
  static const List<String> _personalCatchupTitles = <String>[
    'Anh By <3 nhớ embe nè',
    'Anh By <3 đợi embe xíu nha',
    'Anh By <3 gửi embe chút thương',
    'Anh By <3 nhắc embe nhẹ nhàng',
  ];

  // Last applied "$missedCount|$dayKey"; null = band not owned (non-gated
  // account) so the cleared state is debounced too.
  String? _personalCatchupSignature;

  /// Affectionate bodies, rotated across the day so she never sees the same
  /// line twice in a row. [missed] is the number of past days still unanswered.
  static List<String> _personalCatchupBodies(int missed) => <String>[
    'Còn $missed câu hỏi hôm trước đang đợi embe đó, trả lời cho anh By vui nha 🥰',
    'Embe ơi, mình còn $missed câu chưa trả lời nè, vào trả lời bù cho anh By nha 💗',
    'Anh By tò mò câu trả lời của embe lắm, còn $missed câu thôi à 🥺',
    'Trả lời nốt $missed câu là chuỗi của chúng mình lại đẹp liền, cố lên embe 💞',
    'Anh By thương embe nhiều, dành 1 phút cho $missed câu hỏi cũ nha 🌷',
    'Embe của anh By ơi, $missed câu hỏi đang chờ được embe trả lời nè 💕',
    'Mở app trả lời giúp anh By $missed câu nha, anh By đọc là vui cả ngày 🥰',
  ];

  /// (Re)arm or clear the catch-up nudges. Wired from HomeScreen after every
  /// backlog scan ([CatchupService.findMissedDays]). Only the gated account
  /// ([_personalAccountEmail]) owns the band; anyone else just cancels it.
  /// [missedCount] == 0 cancels as well.
  Future<void> refreshPersonalCatchupReminders({
    required String? email,
    required int missedCount,
  }) async {
    final isTarget =
        (email ?? '').trim().toLowerCase() == _personalAccountEmail;
    if (!isTarget) {
      if (_personalCatchupSignature == null) {
        return;
      }
      _personalCatchupSignature = null;
      await _service.cancelPersonalCatchup();
      return;
    }

    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    final signature = '$missedCount|$dayKey';
    if (signature == _personalCatchupSignature) {
      return;
    }
    _personalCatchupSignature = signature;

    if (missedCount <= 0) {
      await _service.cancelPersonalCatchup();
      return;
    }

    final bodies = _personalCatchupBodies(missedCount);
    final slots = <({int hour, int minute, String title, String body})>[];
    for (var i = 0; i < _personalCatchupSlots.length; i++) {
      final slot = _personalCatchupSlots[i];
      slots.add((
        hour: slot.hour,
        minute: slot.minute,
        title: _personalCatchupTitles[i % _personalCatchupTitles.length],
        body: bodies[i % bodies.length],
      ));
    }
    await _service.schedulePersonalCatchup(slots);
  }

  // ---------------------------------------------------------------------------
  // Invite follow-ups (feature onboarding, 2026-09-05) — band 1180–1189. While
  // the couple is still `waiting_partner`, nudge the lone member 24h + 72h after
  // the couple was created so a partner who never joined doesn't silently kill
  // the account. LOCAL only (the partner has no device in this couple yet).
  // ---------------------------------------------------------------------------

  String? _inviteFollowUpSignature;

  /// True once this process has cancelled band 1180–1189 while not waiting
  /// (reset whenever the band is armed again).
  bool _inviteFollowUpCleared = false;

  /// (Re)arm or clear the invite follow-ups. Wired from HomeScreen alongside the
  /// reminder sync. [waiting] false cancels the band (partner joined). [anchor]
  /// is the couple's creation time, falling back to now for legacy couples with
  /// no usable timestamp. Debounced on (waiting | anchor) so the frequent
  /// rebuilds don't thrash the OS schedule.
  Future<void> refreshInviteFollowUps({
    required bool waiting,
    DateTime? coupleCreatedAt,
    required AppLocalizations l10n,
  }) async {
    if (!waiting) {
      // The signature is per-process, but the one-shots persist in the OS: a
      // partner who joined while this app was killed must still get the band
      // cleared on the next launch. Cancel once per process (cheap), and
      // again after every re-arm.
      _inviteFollowUpSignature = null;
      if (_inviteFollowUpCleared) {
        return;
      }
      _inviteFollowUpCleared = true;
      await _service.cancelInviteFollowUps();
      return;
    }

    final anchor = coupleCreatedAt ?? DateTime.now();
    final signature =
        'waiting|${anchor.millisecondsSinceEpoch}|${l10n.localeName}';
    if (signature == _inviteFollowUpSignature) {
      return;
    }
    _inviteFollowUpSignature = signature;
    _inviteFollowUpCleared = false;

    await _service.scheduleInviteFollowUps(
      anchor: anchor,
      title: l10n.inviteFollowUpTitle,
      bodies: <String>[l10n.inviteFollowUpBody24h, l10n.inviteFollowUpBody72h],
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
    bool coupleActive = true,
  }) async {
    // Cache inputs first so the daily-question schedule and later milestone
    // toggles both see a non-null anniversary (= a couple is active).
    _lastAnniversary = anniversaryDate;
    _lastPhotoDate = lastPhotoDate;
    _lastL10n = l10n;
    // Whether the partner has actually joined — gates the daily-question nudges
    // (a solo `waiting_partner` couple can't complete a question). Milestones and
    // the counter still make sense solo, so they are NOT gated on this.
    _coupleActive = coupleActive;

    // Daily-question nudge: self-gates on enabled/times (cancels when off).
    await _scheduleDailyQuestion(l10n);

    // Milestones auto-remind (2026-06-14: no master toggle) — always reschedule
    // the enabled milestones from the latest couple data.
    await _reschedule(
      anniversaryDate: anniversaryDate,
      lastPhotoDate: lastPhotoDate,
      l10n: l10n,
    );

    // Lunar reminder: top up the rolling day-1/day-15 window each app open
    // (self-gates on enabled).
    await refreshLunar(l10n);
  }

  /// Cancel the daily-question nudge — used when the couple goes inactive
  /// (sign-out / no couple). The user's on/off preference is kept so it re-arms
  /// on the next [sync] once a couple is active again.
  Future<void> cancelDailyQuestionSchedule() async {
    _dqPrefsSub?.cancel();
    _dqPrefsSub = null;
    _dqCoupleId = null;
    _eodSignature = null;
    _dqScheduleSignature = null;
    await _service.cancelDailyQuestion();
    await _service.cancelDailyQuestionEndOfDay();
    // Also drop the repeating backstop — without a couple there is nothing to
    // answer, and this band would otherwise keep firing daily forever.
    await _service.cancelDailyQuestionBackstop();
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
    final firstOfNext = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstOfNext.subtract(const Duration(days: 1)).day;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
