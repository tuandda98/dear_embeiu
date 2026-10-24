/// Feature: mood ("Tâm trạng hôm nay") — a once-a-day emotional check-in shared
/// between the two partners. The daily hook: open the app to see how your person
/// feels today, and share yours so they can see you. Stored at
/// `couples/{coupleId}/moods/{authorUserId}` — exactly one doc per member (doc
/// id == the author's uid), overwritten each day.
library;

/// One selectable mood: a stable [key] (persisted + mirrored in firestore.rules)
/// and its [emoji]. [lottie] is the animated face for that mood (Noto Animated
/// Emoji, CC BY 4.0) — the UI renders it and falls back to the static [emoji]
/// glyph if the asset is missing. Labels are localized in the UI (see
/// `moodLabel`), never stored. Order matters — the picker renders them in this
/// order.
class MoodOption {
  const MoodOption(this.key, this.emoji, this.lottie);

  final String key;
  final String emoji;

  /// Asset path of the animated face (under `assets/lottie/`).
  final String lottie;
}

/// The curated, couple-friendly mood set (warm + a "missing you" that only makes
/// sense for two). Keep in sync with the `moodXxx` l10n keys + the rules' size
/// guard. Small on purpose so the check-in stays a 1–2 tap ritual.
const List<MoodOption> kMoodOptions = [
  MoodOption('happy', '😄', 'assets/lottie/mood_happy.json'),
  MoodOption('loved', '🥰', 'assets/lottie/mood_loved.json'),
  MoodOption('missing', '🥹', 'assets/lottie/mood_missing.json'),
  MoodOption('calm', '😌', 'assets/lottie/mood_calm.json'),
  MoodOption('meh', '😐', 'assets/lottie/mood_meh.json'),
  MoodOption('tired', '😪', 'assets/lottie/mood_tired.json'),
  MoodOption('sad', '😢', 'assets/lottie/mood_sad.json'),
  MoodOption('stressed', '😣', 'assets/lottie/mood_stressed.json'),
];

/// Looks up a [MoodOption] by [key], or null when unknown (e.g. an older/newer
/// client wrote a key this build doesn't know).
MoodOption? moodOptionFor(String key) {
  for (final o in kMoodOptions) {
    if (o.key == key) {
      return o;
    }
  }
  return null;
}

/// Max length of the optional "why" note — must match the Firestore rule.
const int kMoodNoteMaxLength = 100;

/// One member's mood for a given day.
class Mood {
  const Mood({
    required this.authorUserId,
    required this.mood,
    required this.note,
    required this.date,
    this.updatedAt,
  });

  /// The author's uid (== the document id by convention).
  final String authorUserId;

  /// The selected mood key (one of [kMoodOptions]).
  final String mood;

  /// Optional short "why" note (≤ [kMoodNoteMaxLength]); empty when none.
  final String note;

  /// The day this mood is for, as a 'YYYY-MM-DD' local-date key. Used to decide
  /// whether the mood is "today's" (the daily hook resets each day).
  final String date;

  final DateTime? updatedAt;

  /// Whether [mood] is one this build recognises.
  bool get isKnown => moodOptionFor(mood) != null;

  /// The matching option (emoji), or null when unknown.
  MoodOption? get option => moodOptionFor(mood);

  bool get hasNote => note.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'mood': mood,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        'date': date,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Mood.fromDoc(String id, Map<String, dynamic> data) => Mood(
        authorUserId: (data['authorUserId'] as String?)?.trim().isNotEmpty == true
            ? data['authorUserId'] as String
            : id,
        mood: (data['mood'] as String?)?.trim() ?? '',
        note: (data['note'] as String?)?.trim() ?? '',
        date: (data['date'] as String?)?.trim() ?? '',
        updatedAt: _parseDate(data['updatedAt']),
      );

  factory Mood.fromJson(Map<String, dynamic> json) =>
      Mood.fromDoc((json['authorUserId'] as String?) ?? '', json);

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    // Firestore Timestamp.
    try {
      final ms = (value as dynamic).millisecondsSinceEpoch;
      if (ms is int) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {
      // not a timestamp
    }
    return null;
  }
}
