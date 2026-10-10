import 'dart:math' as math;

import '../models/sleep_night.dart';

/// Pure sleep maths (feature sleep, 2026-10-10) — no Flutter, no I/O, so the
/// whole thing is unit-tested in `test/sleep_calculator_test.dart`.
///
/// A night belongs to its WAKE-UP date D and is searched for inside the window
/// [D-1 18:00, D 14:00). Inside it we take the "resting" spans (Android: screen
/// off · iOS: asleep in Apple Health), fold short interruptions into the sleep
/// (each counted as an awakening) and keep the longest block of 3–16 hours.
/// A block that ends by 01:00 is an evening and only counts when nothing later
/// does. A span over 16 hours is a phone left alone; across 02:30 it voids
/// the night. Nothing found → no night (never invented).

/// One screen transition from Android UsageStats (SCREEN_INTERACTIVE = on).
class ScreenEvent {
  const ScreenEvent(this.at, {required this.on});

  final DateTime at;
  final bool on;
}

/// One Apple Health `sleepAnalysis` sample. [value]: 0 inBed · 1 asleep
/// (unspecified) · 2 awake · 3 core · 4 deep · 5 REM.
class HealthSleepSample {
  const HealthSleepSample(this.start, this.end, this.value);

  final DateTime start;
  final DateTime end;
  final int value;
}

/// A continuous resting span.
class RestSpan {
  const RestSpan(this.start, this.end);

  final DateTime start;
  final DateTime end;

  Duration get length => end.difference(start);
}

/// How interruptions are folded into a night.
class SleepRules {
  const SleepRules({
    required this.mergeGap,
    required this.minSleep,
    required this.noise,
    this.maxSleep = const Duration(hours: 16),
  });

  /// Interruptions up to this long stay inside the sleep (= awakenings).
  final Duration mergeGap;

  /// Shortest block that counts as a night.
  final Duration minSleep;

  /// Longer than this is a phone left alone (forgotten, switched off), not a
  /// night — same cap as the edit sheet and the Firestore rule.
  final Duration maxSleep;

  /// Interruptions shorter than this are folded in silently (not counted).
  final Duration noise;

  /// Screen on/off (spec: picking the phone up ≤ 5 min = waking up).
  // ponytail: 20 s noise floor filters screens lit by notifications; tune
  // after the 2-device smoke test.
  static const SleepRules screen = SleepRules(
    mergeGap: Duration(minutes: 5),
    minSleep: Duration(hours: 3),
    noise: Duration(seconds: 20),
  );

  /// Apple Health already segments sleep; its "awake" gaps run longer.
  static const SleepRules health = SleepRules(
    mergeGap: Duration(minutes: 30),
    minSleep: Duration(hours: 3),
    noise: Duration(minutes: 2),
  );
}

/// Search window for the night that ends on [wakeDate].
({DateTime start, DateTime end}) sleepWindow(DateTime wakeDate) => (
  start: DateTime(wakeDate.year, wakeDate.month, wakeDate.day - 1, 18),
  end: DateTime(wakeDate.year, wakeDate.month, wakeDate.day, 14),
);

/// The last [count] wake dates ending today (oldest first).
List<DateTime> recentWakeDates(DateTime now, int count) => [
  for (var i = count - 1; i >= 0; i--)
    DateTime(now.year, now.month, now.day - i),
];

/// Screen events → screen-off spans. A trailing "off" stays open until [now].
List<RestSpan> restSpansFromScreenEvents(
  List<ScreenEvent> events,
  DateTime now,
) {
  final sorted = [...events]..sort((a, b) => a.at.compareTo(b.at));
  final spans = <RestSpan>[];
  DateTime? offSince;
  for (final e in sorted) {
    if (!e.on) {
      offSince ??= e.at;
    } else if (offSince != null) {
      if (e.at.isAfter(offSince)) {
        spans.add(RestSpan(offSince, e.at));
      }
      offSince = null;
    }
  }
  if (offSince != null && now.isAfter(offSince)) {
    spans.add(RestSpan(offSince, now));
  }
  return spans;
}

/// Finds the night ending on [wakeDate] among [spans].
SleepNight? computeNight({
  required DateTime wakeDate,
  required List<RestSpan> spans,
  required SleepRules rules,
  required SleepSource source,
}) {
  final w = sleepWindow(wakeDate);
  final midnight = DateTime(wakeDate.year, wakeDate.month, wakeDate.day);
  final deepNight = midnight.add(const Duration(hours: 2, minutes: 30));
  final clipped = <RestSpan>[];
  DateTime? openEnd; // end of the span already running at 18:00
  for (final s in spans) {
    // Measured before clipping: a phone flat from 16:00 to 09:30 is not a
    // 15-hour night. Across 02:30 it hides the whole night; one that only
    // brushes the night (flat until 00:30) is just dropped.
    if (s.length > rules.maxSleep) {
      if (s.start.isBefore(deepNight) && s.end.isAfter(deepNight)) {
        return null;
      }
      continue;
    }
    final start = s.start.isBefore(w.start) ? w.start : s.start;
    final end = s.end.isAfter(w.end) ? w.end : s.end;
    if (end.isAfter(start)) {
      clipped.add(RestSpan(start, end));
      if (s.start.isBefore(w.start)) {
        openEnd = end;
      }
    }
  }
  if (clipped.isEmpty) {
    return null;
  }
  clipped.sort((a, b) => a.start.compareTo(b.start));

  // Fold interruptions ≤ mergeGap into one block; remember where each
  // counted awakening began.
  final blocks = <({DateTime start, DateTime end, List<DateTime> wakeUps})>[];
  var start = clipped.first.start;
  var end = clipped.first.end;
  var wakeUps = <DateTime>[];
  for (final s in clipped.skip(1)) {
    final gap = s.start.difference(end);
    // A phone idle since the afternoon (or flat) never absorbs the night
    // through a short look before bed. After 01:00 it's a look in the night:
    // merged, so the wake-up time stays right.
    if (gap <= rules.mergeGap &&
        (end != openEnd || end.isAfter(_nightStart(wakeDate)))) {
      if (gap >= rules.noise) {
        wakeUps.add(end);
      }
      if (s.end.isAfter(end)) {
        end = s.end;
      }
    } else {
      blocks.add((start: start, end: end, wakeUps: wakeUps));
      start = s.start;
      end = s.end;
      wakeUps = <DateTime>[];
    }
  }
  blocks.add((start: start, end: end, wakeUps: wakeUps));

  Duration len(({DateTime start, DateTime end, List<DateTime> wakeUps}) b) =>
      b.end.difference(b.start);
  final candidates = blocks
      .where((b) => len(b) >= rules.minSleep && len(b) <= rules.maxSleep)
      .toList();
  if (candidates.isEmpty) {
    return null;
  }
  // An evening (phone charging through a film) must not beat a real night cut
  // in two by a 6-minute pickup; a night shift still keeps its day sleep.
  final late = candidates
      .where((b) => b.end.isAfter(_nightStart(wakeDate)))
      .toList();
  final pool = late.isEmpty ? candidates : late;
  var best = pool.first;
  for (final b in pool.skip(1)) {
    // `>=` → on a tie keep the later block (the one closer to the morning).
    if (len(b) >= len(best)) {
      best = b;
    }
  }
  return SleepNight(
    date: sleepDateKey(wakeDate),
    bedAt: best.start,
    wakeAt: best.end,
    wakeUps: [for (final t in best.wakeUps) t.difference(best.start).inMinutes],
    source: source,
  );
}

/// Nights from Android screen events. A window that starts before the oldest
/// event is left OUT of the result (we can't tell the screen state at its
/// start — Android only keeps a few days of events). A complete window with no
/// block ≥ 3 h maps to null.
Map<String, SleepNight?> computeScreenNights(
  List<ScreenEvent> events, {
  required List<DateTime> wakeDates,
  required DateTime now,
}) {
  if (events.isEmpty) {
    return const <String, SleepNight?>{};
  }
  var coverageStart = events.first.at;
  for (final e in events) {
    if (e.at.isBefore(coverageStart)) {
      coverageStart = e.at;
    }
  }
  final spans = restSpansFromScreenEvents(events, now);
  final out = <String, SleepNight?>{};
  for (final d in wakeDates) {
    final w = sleepWindow(d);
    if (w.start.isBefore(coverageStart) || w.start.isAfter(now)) {
      continue;
    }
    out[sleepDateKey(d)] = computeNight(
      wakeDate: d,
      spans: spans,
      rules: SleepRules.screen,
      source: SleepSource.auto,
    );
  }
  return out;
}

const Set<int> _kHealthAsleep = {1, 3, 4, 5};
const int _kHealthInBed = 0;

/// Nights from Apple Health. Per window: asleep samples when there are any,
/// otherwise "in bed" (an iPhone without a Watch only records time in bed).
Map<String, SleepNight?> computeHealthNights(
  List<HealthSleepSample> samples, {
  required List<DateTime> wakeDates,
  required DateTime now,
}) {
  final out = <String, SleepNight?>{};
  for (final d in wakeDates) {
    final w = sleepWindow(d);
    if (w.start.isAfter(now)) {
      continue;
    }
    final inWindow = samples
        .where((s) => s.end.isAfter(w.start) && s.start.isBefore(w.end))
        .toList();
    SleepNight? from(bool Function(int value) keep) => computeNight(
      wakeDate: d,
      spans: unionSpans([
        for (final s in inWindow)
          if (keep(s.value)) RestSpan(s.start, s.end),
      ]),
      rules: SleepRules.health,
      source: SleepSource.health,
    );
    // Asleep samples first. An iPhone without a Watch only records "in bed",
    // and an evening doze must not beat a whole night in bed.
    final asleep = from(_kHealthAsleep.contains);
    final inBed = from((v) => v == _kHealthInBed);
    bool late(SleepNight? n) => n != null && n.wakeAt.isAfter(_nightStart(d));
    out[sleepDateKey(d)] = late(asleep) || !late(inBed)
        ? asleep ?? inBed
        : inBed;
  }
  return out;
}

/// Rest that ends by 01:00 of [wakeDate] is an evening, not the night.
DateTime _nightStart(DateTime wakeDate) =>
    DateTime(wakeDate.year, wakeDate.month, wakeDate.day, 1);

/// Merges overlapping / touching spans (several Health sources write the same
/// night).
List<RestSpan> unionSpans(List<RestSpan> spans) {
  final valid = spans.where((s) => s.end.isAfter(s.start)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final out = <RestSpan>[];
  for (final s in valid) {
    if (out.isNotEmpty && !s.start.isAfter(out.last.end)) {
      final last = out.removeLast();
      out.add(RestSpan(last.start, s.end.isAfter(last.end) ? s.end : last.end));
    } else {
      out.add(s);
    }
  }
  return out;
}

int minuteOfDay(DateTime t) => t.hour * 60 + t.minute;

/// Circular mean of minutes-of-day: 23:50 and 00:10 average to 00:00, not to
/// 12:00 like a plain mean would.
int circularMeanMinute(List<int> minutes) {
  if (minutes.isEmpty) {
    return 0;
  }
  var sx = 0.0;
  var sy = 0.0;
  for (final m in minutes) {
    final a = m / 1440 * 2 * math.pi;
    sx += math.cos(a);
    sy += math.sin(a);
  }
  if (sx.abs() < 1e-9 && sy.abs() < 1e-9) {
    return minutes.first;
  }
  var angle = math.atan2(sy, sx);
  if (angle < 0) {
    angle += 2 * math.pi;
  }
  return (angle / (2 * math.pi) * 1440).round() % 1440;
}

/// One person's numbers for a month.
class SleepMonthStats {
  const SleepMonthStats({
    required this.nights,
    required this.avgMinutes,
    required this.avgBedMinute,
    required this.avgWakeMinute,
    required this.fullNights,
  });

  final int nights;
  final int avgMinutes;
  final int avgBedMinute;
  final int avgWakeMinute;

  /// Nights ≥ 8 h (a full moon).
  final int fullNights;
}

/// Stats over [nights] (already filtered to one month); null when empty.
SleepMonthStats? sleepMonthStats(Iterable<SleepNight> nights) {
  final list = nights.toList();
  if (list.isEmpty) {
    return null;
  }
  final total = list.fold<int>(0, (sum, n) => sum + n.minutes);
  return SleepMonthStats(
    nights: list.length,
    avgMinutes: (total / list.length).round(),
    avgBedMinute: circularMeanMinute([
      for (final n in list) minuteOfDay(n.bedAt),
    ]),
    avgWakeMinute: circularMeanMinute([
      for (final n in list) minuteOfDay(n.wakeAt),
    ]),
    fullNights: list.where((n) => n.isFull).length,
  );
}

/// Shared nights of a month: how many reached the heart threshold and the
/// average overlap over every night both slept. Null when no night is shared.
({int heartNights, int avgOverlap})? sleepTogetherStats(
  Map<String, SleepNight> mine,
  Map<String, SleepNight> partner,
  bool Function(String dateKey) inMonth,
) {
  final overlaps = <int>[];
  for (final entry in mine.entries) {
    final other = partner[entry.key];
    if (other == null || !inMonth(entry.key)) {
      continue;
    }
    overlaps.add(entry.value.overlapWith(other));
  }
  if (overlaps.isEmpty) {
    return null;
  }
  return (
    heartNights: overlaps.where((m) => m >= kSleepTogetherHeartMinutes).length,
    avgOverlap: (overlaps.reduce((a, b) => a + b) / overlaps.length).round(),
  );
}
