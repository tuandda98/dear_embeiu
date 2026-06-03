/// A short "love note" one partner leaves for the other on the Home screen.
///
/// Stored at `couples/{coupleId}/notes/{authorUserId}` — exactly one document
/// per member (the doc id IS the author's uid), so each person owns and
/// overwrites their single note. The partner sees the note whose
/// [authorUserId] is not their own uid.
class LoveNote {
  final String authorUserId;
  final String text;
  final DateTime? updatedAt;

  const LoveNote({
    required this.authorUserId,
    required this.text,
    this.updatedAt,
  });

  bool get hasText => text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'authorUserId': authorUserId,
        'text': text,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory LoveNote.fromJson(Map<String, dynamic> json) => LoveNote(
        authorUserId: json['authorUserId'] as String? ?? '',
        text: json['text'] as String? ?? '',
        updatedAt: _parseDateTime(json['updatedAt']),
      );

  /// Builds a note from a Firestore document. [id] is the document id, which by
  /// convention equals the author's uid; it is used as a fallback when the
  /// stored `authorUserId` field is missing.
  factory LoveNote.fromDoc(String id, Map<String, dynamic> data) => LoveNote(
        authorUserId: (data['authorUserId'] as String?)?.trim().isNotEmpty == true
            ? data['authorUserId'] as String
            : id,
        text: data['text'] as String? ?? '',
        updatedAt: _parseDateTime(data['updatedAt']),
      );

  LoveNote copyWith({
    String? authorUserId,
    String? text,
    DateTime? updatedAt,
  }) =>
      LoveNote(
        authorUserId: authorUserId ?? this.authorUserId,
        text: text ?? this.text,
        updatedAt: updatedAt ?? this.updatedAt,
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
    final dynamic microsecondsSinceEpoch = (value as dynamic).microsecondsSinceEpoch;
    if (microsecondsSinceEpoch is int) {
      return DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
    }
    final dynamic millisecondsSinceEpoch = (value as dynamic).millisecondsSinceEpoch;
    if (millisecondsSinceEpoch is int) {
      return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    }
    return null;
  }
}
