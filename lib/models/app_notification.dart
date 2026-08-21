/// A single entry in the in-app notification center.
///
/// These docs are written ONLY by Cloud Functions (one per push, into
/// `users/{uid}/notifications`). They are stored as STRUCTURED data (type +
/// actor + ids) rather than a pre-rendered sentence, so the UI renders the
/// human text in the user's CURRENT app language — the list is never frozen in
/// the language the push was sent in.
enum AppNotificationType {
  photoPosted,
  photoReaction,
  partnerJoined,
  partnerLeft,
  loveNote,
  dailyQuestion,

  /// Partner reacted to your daily-question answer (feature: daily-question
  /// reactions). Carries `date` + `emoji`; routes like [dailyQuestion].
  dailyAnswerReaction,
  chatMessage,

  /// A type this app build doesn't recognise (forward-compat: a newer backend
  /// could send a new type). Rendered with a generic fallback, routes to Home.
  unknown,
}

AppNotificationType appNotificationTypeFromString(String? raw) {
  switch ((raw ?? '').trim()) {
    case 'photo_posted':
      return AppNotificationType.photoPosted;
    case 'photo_reaction':
      return AppNotificationType.photoReaction;
    case 'partner_joined':
      return AppNotificationType.partnerJoined;
    case 'partner_left':
      return AppNotificationType.partnerLeft;
    case 'love_note':
      return AppNotificationType.loveNote;
    case 'daily_question':
      return AppNotificationType.dailyQuestion;
    case 'daily_answer_reaction':
      return AppNotificationType.dailyAnswerReaction;
    case 'chat_message':
      return AppNotificationType.chatMessage;
    default:
      return AppNotificationType.unknown;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.rawType,
    required this.coupleId,
    required this.actorUserId,
    required this.actorName,
    required this.read,
    this.photoId,
    this.emoji,
    this.noteExcerpt,
    this.caption,
    this.date,
    this.createdAt,
    this.bothAnswered = false,
  });

  final String id;
  final AppNotificationType type;

  /// The raw `type` string from Firestore (kept for forward-compat / analytics).
  final String rawType;
  final String coupleId;
  final String actorUserId;
  final String actorName;
  final bool read;

  // Type-specific optional fields (only some are present per type).
  final String? photoId; // photo_posted, photo_reaction
  final String? emoji; // photo_reaction
  final String? noteExcerpt; // love_note
  final String? caption; // photo_posted
  final String? date; // daily_question (yyyy-mm-dd key)
  final DateTime? createdAt;

  /// daily_question only: this answer COMPLETED the pair, so the title can say
  /// "you both answered" instead of naming only the partner (2026-08-09, matches
  /// the push copy). Absent on docs written by older backends → false.
  final bool bothAnswered;

  /// Which Home bottom-nav tab this notification should open when tapped.
  /// Photo-related → Gallery (2); chat → Chat (1); everything else → Home (0).
  /// ⚠️ Indices shifted when the chat tab landed at 1 (feature chat,
  /// 2026-06-11) — keep in sync with HomeScreen._navigationItems and the push
  /// deep-link map in push_notification_service.dart. This is also the single
  /// source of truth that gives `partner_left` a destination.
  int get targetHomeTab {
    switch (type) {
      case AppNotificationType.photoPosted:
      case AppNotificationType.photoReaction:
        return 2; // Gallery
      case AppNotificationType.chatMessage:
      case AppNotificationType.loveNote:
        // Chat. Love notes were retired + auto-migrated into chat (2026-06-14),
        // so a legacy love-note tap must land where the message now lives —
        // matches the 'love_note' branch in push_notification_service.dart.
        return 1; // Chat
      case AppNotificationType.partnerJoined:
      case AppNotificationType.partnerLeft:
      case AppNotificationType.dailyQuestion:
      // A reaction always lands on an already-revealed answer, so the tap
      // handler in notification_center_screen sends it straight to that day in
      // the Journal; Home is the cold-start fallback.
      case AppNotificationType.dailyAnswerReaction:
      case AppNotificationType.unknown:
        return 0; // Home
    }
  }

  factory AppNotification.fromDoc(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      rawType: (data['type'] as String?)?.trim() ?? '',
      type: appNotificationTypeFromString(data['type'] as String?),
      coupleId: (data['coupleId'] as String?)?.trim() ?? '',
      actorUserId: (data['actorUserId'] as String?)?.trim() ?? '',
      actorName: (data['actorName'] as String?)?.trim() ?? '',
      photoId: _nullableString(data['photoId']),
      emoji: _nullableString(data['emoji']),
      noteExcerpt: _nullableString(data['noteExcerpt']),
      caption: _nullableString(data['caption']),
      date: _nullableString(data['date']),
      createdAt: _parseTimestamp(data['createdAt']),
      read: data['read'] == true,
      bothAnswered: data['bothAnswered'] == true,
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      rawType: rawType,
      coupleId: coupleId,
      actorUserId: actorUserId,
      actorName: actorName,
      read: read ?? this.read,
      photoId: photoId,
      emoji: emoji,
      noteExcerpt: noteExcerpt,
      caption: caption,
      date: date,
      createdAt: createdAt,
      bothAnswered: bothAnswered,
    );
  }

  static String? _nullableString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  // Accepts a Firestore Timestamp (duck-typed via toDate()), a DateTime, or an
  // ISO string — without importing cloud_firestore into the model layer.
  static DateTime? _parseTimestamp(dynamic value) {
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
