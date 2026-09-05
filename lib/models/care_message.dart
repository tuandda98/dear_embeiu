/// One "care note" (feature care-message): a short title + body one member
/// wrote FOR their partner, delivered as a push whose notification text is the
/// message itself (no content-free placeholder — the whole point is that the
/// partner reads the words on their lock screen).
///
/// Backed by `couples/{coupleId}/careMessages/{autoId}`, which the Firestore
/// rules pin to EXACTLY four fields — keep [toCreateMap] in sync with them.
class CareMessage {
  const CareMessage({
    required this.id,
    required this.authorUserId,
    required this.title,
    required this.body,
    this.createdAt,
  });

  /// Firestore rule limits — clamp locally so a long paste is trimmed instead
  /// of rejected server-side.
  static const int maxTitleLength = 60;
  static const int maxBodyLength = 200;

  final String id;
  final String authorUserId;
  final String title;
  final String body;

  /// Null for the brief moment before the server timestamp resolves (local
  /// echo of a pending write).
  final DateTime? createdAt;

  bool isMine(String uid) => uid.isNotEmpty && authorUserId == uid;

  factory CareMessage.fromDoc(String id, Map<String, dynamic> data) {
    return CareMessage(
      id: id,
      authorUserId: (data['authorUserId'] as String?)?.trim() ?? '',
      title: (data['title'] as String?)?.trim() ?? '',
      body: (data['body'] as String?)?.trim() ?? '',
      createdAt: parseTimestamp(data['createdAt']),
    );
  }

  /// Accepts a Firestore Timestamp (duck-typed via toDate()), a DateTime or an
  /// ISO string, without importing cloud_firestore into the model layer.
  static DateTime? parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic d = (value as dynamic).toDate();
      return d is DateTime ? d : null;
    } catch (_) {
      return null;
    }
  }
}
