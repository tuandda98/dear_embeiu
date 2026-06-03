/// One partner's answer to the shared "daily question" (feature #5).
///
/// Stored at `couples/{coupleId}/dailyAnswers/{date}/responses/{authorUserId}`
/// — exactly one document per member per day (the doc id IS the author's uid).
/// Both members can read both docs; the "answer first to reveal" rule is a
/// client-side UI affordance only.
class DailyAnswer {
  final String authorUserId;
  final String text;
  final DateTime? answeredAt;

  const DailyAnswer({
    required this.authorUserId,
    required this.text,
    this.answeredAt,
  });

  bool get hasText => text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'authorUserId': authorUserId,
        'text': text,
        'answeredAt': answeredAt?.toIso8601String(),
      };

  factory DailyAnswer.fromJson(Map<String, dynamic> json) => DailyAnswer(
        authorUserId: json['authorUserId'] as String? ?? '',
        text: json['text'] as String? ?? '',
        answeredAt: _parseDateTime(json['answeredAt']),
      );

  /// Builds an answer from a Firestore document. [id] is the document id, which
  /// by convention equals the author's uid; used as a fallback when the stored
  /// `authorUserId` field is missing.
  factory DailyAnswer.fromDoc(String id, Map<String, dynamic> data) =>
      DailyAnswer(
        authorUserId:
            (data['authorUserId'] as String?)?.trim().isNotEmpty == true
                ? data['authorUserId'] as String
                : id,
        text: data['text'] as String? ?? '',
        answeredAt: _parseDateTime(data['answeredAt']),
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
