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

  /// Partner sent a hand-written care note (feature care-message). Unlike every
  /// other type, its text is NOT re-rendered from a template — [title]/[body]
  /// carry the partner's own words and are shown verbatim.
  careMessage,

  /// Partner challenged you to rock-paper-scissors (feature rps-game,
  /// 2026-09-13). Carries [AppNotification.gameId]; tap opens that game.
  rpsInvite,

  /// The partner has thrown their hand and it's my move (feature rps-game,
  /// no-skip rule 2026-09-14 — CF `resolveRpsGame` when I'm away, or the
  /// partner's "Nhắc người ấy"). Carries [AppNotification.gameId]; tap opens
  /// that round, exactly like [rpsInvite].
  rpsMoved,

  /// A rock-paper-scissors game finished (push-only per spec — no inbox doc is
  /// written today; parsed for forward-compat). Tap opens the history.
  rpsResult,

  /// The partner locked in (or re-spun) a pick on the decision wheel (feature
  /// decision-wheel). Carries [decisionKind]/[result]/[question]; tap → the
  /// Home card.
  decision,

  // ── caro-game (đợt 2) ──
  /// The partner started a caro game and played the first stone (CF
  /// `caroAction` start). Carries [AppNotification.gameId]; tap opens it.
  caroInvite,
  // ── expenses (đợt 2) ── Sổ tiền (CF notifyMoney): someone put money into a
  // shared fund (`percent`, `walletName`, `walletEmoji`) · a fund reached
  // its goal · the shared month crossed 80/100% of the total budget
  // (`month`, `level`). Never an amount. Tap → Sổ tiền, shared book.
  moneyGoal,
  moneyGoalReached,
  moneyBudget,

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
    case 'care_message':
      return AppNotificationType.careMessage;
    case 'rps_invite':
      return AppNotificationType.rpsInvite;
    case 'rps_moved':
      return AppNotificationType.rpsMoved;
    case 'rps_result':
      return AppNotificationType.rpsResult;
    case 'decision':
      return AppNotificationType.decision;
    // ── caro-game (đợt 2) ──
    case 'caro_invite':
      return AppNotificationType.caroInvite;
    // ── expenses (đợt 2) ──
    case 'money_goal':
      return AppNotificationType.moneyGoal;
    case 'money_goal_reached':
      return AppNotificationType.moneyGoalReached;
    case 'money_budget':
      return AppNotificationType.moneyBudget;
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
    this.title,
    this.body,
    this.careMessageId,
    this.gameId,
    this.decisionKind,
    this.result,
    this.resultId,
    this.question,
    this.respin = false,
    this.walletId,
    this.percent,
    this.walletName,
    this.walletEmoji,
    this.month,
    this.level,
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

  /// care_message only: the partner's own words, stored on the inbox doc so the
  /// center shows exactly what the push showed. Null on every other type.
  final String? title;
  final String? body;

  /// care_message only: id of the `careMessages` doc, so a tap can open the
  /// care timeline scrolled to that exact note (feature care-message,
  /// 2026-09-05). Null on notes written before the timeline shipped.
  final String? careMessageId;

  /// rps_invite / rps_moved / rps_result only: id of the `games` doc, so a tap can open
  /// that exact game (feature rps-game, 2026-09-13).
  final String? gameId;

  /// decision only: `eat` / `go` / `custom`, the pick as stored (+ bank id so
  /// the center can show it in the viewer's language), the custom question,
  /// and whether this was a re-spin of an earlier pick.
  final String? decisionKind;
  final String? result;
  final String? resultId;
  final String? question;
  final bool respin;

  // ── expenses (đợt 2) ── money_* only.
  final String? walletId; // money_goal, money_goal_reached
  final int? percent; // money_goal
  final String? walletName; // money_goal, money_goal_reached
  final String? walletEmoji; // money_goal, money_goal_reached
  final String? month; // money_budget ('YYYY-MM')
  final int? level; // money_budget (80 / 100)

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
      // The notification center opens a care note in the care TIMELINE
      // (scrolled to that note); Home is only the cold-start push fallback.
      case AppNotificationType.careMessage:
      // Rock-paper-scissors lives off Home: the center publishes a Home-focus
      // (`rps_game` + gameId / `rps_history`) alongside this tab — matches the
      // 'rps_invite'/'rps_moved'/'rps_result' branches in
      // push_notification_service.dart.
      case AppNotificationType.rpsInvite:
      case AppNotificationType.rpsMoved:
      case AppNotificationType.rpsResult:
      // Decision wheel: the center publishes the `decision` Home-focus too.
      case AppNotificationType.decision:
      // ── caro-game (đợt 2) ── the center publishes the `caro` focus + id.
      case AppNotificationType.caroInvite:
      // ── expenses (đợt 2) ── Sổ tiền is pushed on top of Home; the center
      // publishes the `money` Home-focus via NotificationTapRouter.routeMoney
      // — same helper as the 'money_*' push branch.
      case AppNotificationType.moneyGoal:
      case AppNotificationType.moneyGoalReached:
      case AppNotificationType.moneyBudget:
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
      title: _nullableString(data['title']),
      body: _nullableString(data['body']),
      careMessageId: _nullableString(data['careMessageId']),
      gameId: _nullableString(data['gameId']),
      decisionKind: _nullableString(data['kind']),
      result: _nullableString(data['result']),
      resultId: _nullableString(data['resultId']),
      question: _nullableString(data['question']),
      respin: data['respin'] == true,
      walletId: _nullableString(data['walletId']),
      percent: data['percent'] is num ? (data['percent'] as num).toInt() : null,
      walletName: _nullableString(data['walletName']),
      walletEmoji: _nullableString(data['walletEmoji']),
      month: _nullableString(data['month']),
      level: data['level'] is num
          ? (data['level'] as num).toInt()
          : int.tryParse('${data['level'] ?? ''}'),
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
      title: title,
      body: body,
      careMessageId: careMessageId,
      gameId: gameId,
      decisionKind: decisionKind,
      result: result,
      resultId: resultId,
      question: question,
      respin: respin,
      walletId: walletId,
      percent: percent,
      walletName: walletName,
      walletEmoji: walletEmoji,
      month: month,
      level: level,
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
