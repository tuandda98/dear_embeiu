/// Feature sleep ("Giấc ngủ của chúng mình", 2026-10-10). One night = one
/// sleep block, keyed by the WAKE-UP date ('YYYY-MM-DD', local). Stored on the
/// device (Hive) always; mirrored to `couples/{c}/sleep/{uid}/nights/{date}`
/// only while sharing is on. The shared copy holds the final times + [source]
/// and nothing else — never the originally detected times (rule R2).
library;

/// Where a night came from. `manual`/`edited` nights carry a public label
/// (R1) and are never overwritten by a later automatic scan.
enum SleepSource { auto, health, manual, edited }

SleepSource sleepSourceFromName(String? name) {
  for (final s in SleepSource.values) {
    if (s.name == name) {
      return s;
    }
  }
  return SleepSource.manual;
}

/// Phase thresholds (minutes): <5h · 5–6h · 6–7h · 7–8h · ≥8h. Index 4 is the
/// "full moon" — a full night (đêm tròn giấc).
int sleepPhaseFor(int minutes) {
  if (minutes < 300) return 0;
  if (minutes < 360) return 1;
  if (minutes < 420) return 2;
  if (minutes < 480) return 3;
  return 4;
}

/// Lit fraction of the moon per phase (design spec v3).
const List<double> kSleepPhaseFractions = [0.2, 0.36, 0.5, 0.72, 1.0];

/// "Asleep together" this long or more earns the heart in a calendar cell.
const int kSleepTogetherHeartMinutes = 7 * 60;

/// Edits / manual logs / deletes are allowed for nights whose wake date is
/// today or one of the 6 days before (R3). The Firestore rule allows 8 days
/// (timezone slack).
const int kSleepEditableDays = 7;

/// Local-date key 'YYYY-MM-DD'.
String sleepDateKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// Parses a 'YYYY-MM-DD' key into a local midnight, or null.
DateTime? sleepDateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    return null;
  }
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) {
    return null;
  }
  return DateTime(y, m, d);
}

/// Whether the night woken up on [dateKey] may still be edited (R3).
bool sleepNightEditable(String dateKey, {DateTime? now}) {
  final date = sleepDateFromKey(dateKey);
  if (date == null) {
    return false;
  }
  final n = now ?? DateTime.now();
  // Calendar days, counted in UTC: local midnights a DST change apart are 167
  // or 169 hours apart, and `inDays` would call a 7-day-old night 6 days old.
  final age = DateTime.utc(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
  return age >= 0 && age < kSleepEditableDays;
}

class SleepNight {
  const SleepNight({
    required this.date,
    required this.bedAt,
    required this.wakeAt,
    this.wakeUps = const <int>[],
    required this.source,
    this.tz,
  });

  /// Wake-up date key 'YYYY-MM-DD'.
  final String date;
  final DateTime bedAt;
  final DateTime wakeAt;

  /// Each awakening as minutes after [bedAt] (drawn as a gap on the lane).
  final List<int> wakeUps;
  final SleepSource source;

  /// Minutes east of UTC on the owner's clock when the night was recorded
  /// (null for nights saved before 1.9.1). A night is shown on the clock where
  /// it happened (audit D2), so a trip or a partner abroad doesn't shift it.
  final int? tz;

  /// [bedAt] / [wakeAt] on the night's own clock. Read the fields only (hour,
  /// minute, day…): with a [tz] the value may be UTC-flagged on purpose, so
  /// never compare it with a plain local DateTime.
  DateTime get bedClock => _onOwnClock(bedAt);
  DateTime get wakeClock => _onOwnClock(wakeAt);

  /// A phone still on the night's clock (same offset at [bedAt]) reads it in
  /// local time: one [tz] can't hold both ends of a night across a DST change
  /// (23:00 PST → 07:00 PDT would show 06:00). Elsewhere the fixed offset.
  DateTime _onOwnClock(DateTime t) =>
      tz == null || bedAt.toLocal().timeZoneOffset.inMinutes == tz
      ? t.toLocal()
      : t.toUtc().add(Duration(minutes: tz!));

  int get minutes => wakeAt.difference(bedAt).inMinutes;
  int get phase => sleepPhaseFor(minutes);
  bool get isFull => phase == 4;

  /// R1: edited / manual nights wear a label everywhere their numbers show.
  bool get isLabeled =>
      source == SleepSource.manual || source == SleepSource.edited;

  /// Overlap with [other] in minutes (0 when the two blocks don't meet).
  int overlapWith(SleepNight other) {
    final start = bedAt.isAfter(other.bedAt) ? bedAt : other.bedAt;
    final end = wakeAt.isBefore(other.wakeAt) ? wakeAt : other.wakeAt;
    final m = end.difference(start).inMinutes;
    return m > 0 ? m : 0;
  }

  bool sameAs(SleepNight other) =>
      date == other.date &&
      bedAt == other.bedAt &&
      wakeAt == other.wakeAt &&
      source == other.source &&
      tz == other.tz &&
      _sameList(wakeUps, other.wakeUps);

  /// Stable string used to skip re-uploading an unchanged night.
  String get fingerprint =>
      '${bedAt.millisecondsSinceEpoch}|${wakeAt.millisecondsSinceEpoch}|'
      '${source.name}|${wakeUps.join(',')}${tz == null ? '' : '|$tz'}';

  SleepNight copyWith({
    DateTime? bedAt,
    DateTime? wakeAt,
    List<int>? wakeUps,
    SleepSource? source,
    int? tz,
  }) => SleepNight(
    date: date,
    bedAt: bedAt ?? this.bedAt,
    wakeAt: wakeAt ?? this.wakeAt,
    wakeUps: wakeUps ?? this.wakeUps,
    source: source ?? this.source,
    tz: tz ?? this.tz,
  );

  /// Hive form (epoch millis).
  Map<String, dynamic> toJson() => {
    'date': date,
    'bedAt': bedAt.millisecondsSinceEpoch,
    'wakeAt': wakeAt.millisecondsSinceEpoch,
    'wakeUps': wakeUps,
    'source': source.name,
    if (tz != null) 'tz': tz,
  };

  /// Parses the Hive form or a Firestore doc (Timestamps). Returns null for a
  /// malformed entry instead of throwing.
  static SleepNight? fromMap(Map<dynamic, dynamic> map) {
    final date = map['date'];
    final bed = _parseTime(map['bedAt']);
    final wake = _parseTime(map['wakeAt']);
    if (date is! String || bed == null || wake == null || !wake.isAfter(bed)) {
      return null;
    }
    final rawWakeUps = map['wakeUps'];
    return SleepNight(
      date: date,
      bedAt: bed,
      wakeAt: wake,
      wakeUps: rawWakeUps is List
          ? [
              for (final v in rawWakeUps)
                if (v is num) v.toInt(),
            ]
          : const <int>[],
      source: sleepSourceFromName(map['source'] as String?),
      tz: map['tz'] is num ? (map['tz'] as num).toInt() : null,
    );
  }

  static DateTime? _parseTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is DateTime) {
      return value;
    }
    // Firestore Timestamp (kept dynamic so the model has no Firebase import).
    try {
      final dt = (value as dynamic).toDate();
      if (dt is DateTime) {
        return dt;
      }
    } catch (_) {
      // not a timestamp
    }
    return null;
  }

  static bool _sameList(List<int> a, List<int> b) {
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
}
