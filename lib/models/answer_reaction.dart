import 'photo_reaction.dart' show kReactionEmojis;

export 'photo_reaction.dart' show kReactionEmojis, kDefaultReactionEmoji;

/// A single member's reaction to their partner's daily-question answer
/// (feature: daily-question reactions).
///
/// Stored at
/// `couples/{coupleId}/dailyAnswers/{date}/responses/{answerAuthorUid}/answerReactions/{reactorUid}`
/// — one document per reactor per answer (the doc id IS the reactor's uid), so
/// each person owns and overwrites their single reaction on a given answer.
/// Removing a reaction deletes the doc.
///
/// The subcollection is deliberately NOT called `reactions`: photo reactions
/// stream through `collectionGroup('reactions').where('coupleId', ==)` filtered
/// only by coupleId, so reusing the name would leak answer reactions into the
/// photo reaction map (keyed by a uid that is no photo id). A separate group
/// keeps the two features from ever contaminating each other — and leaves
/// already-shipped clients, which never query `answerReactions`, untouched.
///
/// [coupleId] and [date] are denormalised onto the doc: coupleId so a single
/// collection-group query can watch every answer reaction of the couple, date so
/// the reaction can be grouped without walking the document path. The answer's
/// author is recovered from the path (`answerReactions` → parent `responses`
/// doc, whose id is the answer author's uid).
class AnswerReaction {
  final String reactorUserId;
  final String answerAuthorUserId;
  final String emoji;
  final String coupleId;
  final String date;
  final DateTime? reactedAt;

  const AnswerReaction({
    required this.reactorUserId,
    required this.answerAuthorUserId,
    required this.emoji,
    required this.coupleId,
    required this.date,
    this.reactedAt,
  });

  /// Whether [emoji] is one of the six allowed reactions.
  bool get isValid => kReactionEmojis.contains(emoji);

  /// Stable lookup key for one answer: the day plus whose answer it is. A day
  /// holds at most two answers (one per member), so this pair is unique.
  static String keyFor(String date, String answerAuthorUserId) =>
      '$date|$answerAuthorUserId';

  String get key => keyFor(date, answerAuthorUserId);

  Map<String, dynamic> toMap() => {
        'reactorUserId': reactorUserId,
        'emoji': emoji,
        'coupleId': coupleId,
        'date': date,
        'reactedAt': reactedAt?.toIso8601String(),
      };

  /// Builds a reaction from a Firestore document. [id] is the document id, which
  /// by convention equals the reactor's uid; it is used as a fallback when the
  /// stored `reactorUserId` field is missing. [answerAuthorUserId] and [date]
  /// come from the document path, which is authoritative.
  factory AnswerReaction.fromDoc(
    String id,
    Map<String, dynamic> data, {
    required String answerAuthorUserId,
    required String date,
  }) =>
      AnswerReaction(
        reactorUserId:
            (data['reactorUserId'] as String?)?.trim().isNotEmpty == true
                ? data['reactorUserId'] as String
                : id,
        answerAuthorUserId: answerAuthorUserId,
        emoji: data['emoji'] as String? ?? '',
        coupleId: data['coupleId'] as String? ?? '',
        date: (data['date'] as String?)?.trim().isNotEmpty == true
            ? data['date'] as String
            : date,
        reactedAt: _parseDateTime(data['reactedAt']),
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    // Firestore Timestamp — read with microsecond precision.
    final dynamic micros = (value as dynamic).microsecondsSinceEpoch;
    if (micros is int) {
      return DateTime.fromMicrosecondsSinceEpoch(micros);
    }
    final dynamic millis = (value as dynamic).millisecondsSinceEpoch;
    if (millis is int) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }
}
