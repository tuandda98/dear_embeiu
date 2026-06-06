/// The six valid reaction emoji (feature: reactions ❤️). Order matters — the
/// long-press picker renders them left-to-right in this order and ❤️ is the
/// default one-tap reaction. UI and client-side validation share this list so
/// they can never drift; the same set is mirrored in `firestore.rules`.
const List<String> kReactionEmojis = ['❤️', '😍', '😂', '🥹', '🔥', '👍'];

/// The default one-tap reaction (the heart button thaws/removes this).
const String kDefaultReactionEmoji = '❤️';

/// A single member's reaction to a photo.
///
/// Stored at `couples/{coupleId}/photos/{photoId}/reactions/{authorUserId}` —
/// exactly one document per member per photo (the doc id IS the author's uid),
/// so each person owns and overwrites their single reaction. Removing a
/// reaction deletes the doc. [coupleId] is duplicated onto the doc so a single
/// `collectionGroup('reactions').where('coupleId', ==)` query can watch every
/// reaction of the couple at once (the photoId is recovered from the document
/// path).
class PhotoReaction {
  final String authorUserId;
  final String emoji;
  final String coupleId;
  final DateTime? reactedAt;

  const PhotoReaction({
    required this.authorUserId,
    required this.emoji,
    required this.coupleId,
    this.reactedAt,
  });

  /// Whether [emoji] is one of the six allowed reactions.
  bool get isValid => kReactionEmojis.contains(emoji);

  Map<String, dynamic> toMap() => {
        'authorUserId': authorUserId,
        'emoji': emoji,
        'coupleId': coupleId,
        'reactedAt': reactedAt?.toIso8601String(),
      };

  /// Builds a reaction from a Firestore document. [id] is the document id, which
  /// by convention equals the author's uid; it is used as a fallback when the
  /// stored `authorUserId` field is missing.
  factory PhotoReaction.fromDoc(String id, Map<String, dynamic> data) =>
      PhotoReaction(
        authorUserId:
            (data['authorUserId'] as String?)?.trim().isNotEmpty == true
                ? data['authorUserId'] as String
                : id,
        emoji: data['emoji'] as String? ?? '',
        coupleId: data['coupleId'] as String? ?? '',
        reactedAt: _parseDateTime(data['reactedAt']),
      );

  PhotoReaction copyWith({
    String? authorUserId,
    String? emoji,
    String? coupleId,
    DateTime? reactedAt,
  }) =>
      PhotoReaction(
        authorUserId: authorUserId ?? this.authorUserId,
        emoji: emoji ?? this.emoji,
        coupleId: coupleId ?? this.coupleId,
        reactedAt: reactedAt ?? this.reactedAt,
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
    final dynamic microsecondsSinceEpoch =
        (value as dynamic).microsecondsSinceEpoch;
    if (microsecondsSinceEpoch is int) {
      return DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch);
    }
    final dynamic millisecondsSinceEpoch =
        (value as dynamic).millisecondsSinceEpoch;
    if (millisecondsSinceEpoch is int) {
      return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    }
    return null;
  }
}
