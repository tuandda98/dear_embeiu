/// A single chat message in the couple's private conversation (feature chat).
///
/// Stored at `couples/{coupleId}/messages/{messageId}` (auto-id) with
/// `authorUserId` + `text` (≤1000) + `createdAt` (serverTimestamp). Messages
/// are immutable — no edit/delete in v1 (D3: "tin nhắn là kỷ niệm").
class ChatMessage {
  /// Firestore document id — used to dedup the realtime window against
  /// paginated older pages (pagination D5). Null for locally-built messages.
  final String? id;
  final String authorUserId;
  final String text;

  /// Null while the write is still pending locally (serverTimestamp hasn't
  /// resolved yet) — the UI renders such messages in the "sending" state.
  final DateTime? createdAt;

  /// True while Firestore reports `hasPendingWrites` for this doc (optimistic
  /// local echo, not yet confirmed by the server). Drives the .65-opacity +
  /// clock pending treatment (design §4).
  final bool isPending;

  const ChatMessage({
    this.id,
    required this.authorUserId,
    required this.text,
    this.createdAt,
    this.isPending = false,
  });

  /// Builds a message from a Firestore document.
  factory ChatMessage.fromDoc(
    String id,
    Map<String, dynamic> data, {
    bool isPending = false,
  }) =>
      ChatMessage(
        id: id,
        authorUserId: data['authorUserId'] as String? ?? '',
        text: data['text'] as String? ?? '',
        createdAt: _parseDateTime(data['createdAt']),
        isPending: isPending,
      );

  Map<String, dynamic> toJson() => {
        'authorUserId': authorUserId,
        'text': text,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        authorUserId: json['authorUserId'] as String? ?? '',
        text: json['text'] as String? ?? '',
        createdAt: _parseDateTime(json['createdAt']),
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
    // Firestore Timestamp — read with microsecond precision so the pagination
    // cursor (Timestamp.fromDate) reconstructs the exact boundary.
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
