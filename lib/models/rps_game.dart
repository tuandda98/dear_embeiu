/// Rock-paper-scissors (feature rps-game, 2026-09-13) — pure data layer.
///
/// Mirrors the CHỐT data contract in `project/features/rps-game/overview.md`
/// §3: `couples/{coupleId}/games/{gameId}` (+ `moves/{uid}`). No
/// cloud_firestore import on purpose (same duck-typed timestamp parsing as
/// [AppNotification]) so the judge + parsers are unit-testable without Firebase.
library;

/// Game-wide timing constants — single source of truth shared by the provider
/// (countdown/heartbeat), the service (transactions) and, later, the screens.
/// The backend (rules + CF) hardcodes the same numbers; keep them in sync.
class RpsTiming {
  RpsTiming._();

  /// How long both players have to pick once the game is `playing`.
  static const Duration countdown = Duration(seconds: 5);

  /// Network grace AFTER the countdown: the rules still accept a move until
  /// `startedAt + countdown + grace`; the callable finisher refuses before it.
  static const Duration grace = Duration(seconds: 2);

  /// Presence heartbeat interval while on the game screen.
  static const Duration heartbeat = Duration(seconds: 3);

  /// A presence stamp older than this means "not on the screen any more".
  static const Duration presenceFresh = Duration(seconds: 10);

  /// An `invited` game older than this can be flipped to `expired` by either
  /// member (client-side; rules check the same age).
  static const Duration inviteTtl = Duration(minutes: 10);
}

/// The three hands + [none] (= no pick before the deadline; only ever appears
/// inside a finished game's `result.choices`, never in a `moves` doc).
enum RpsChoice {
  rock,
  paper,
  scissors,
  none;

  /// Firestore string (`'rock' | 'paper' | 'scissors' | 'none'`).
  String get key => name;

  String get emoji {
    switch (this) {
      case RpsChoice.rock:
        return '✊';
      case RpsChoice.paper:
        return '✋';
      case RpsChoice.scissors:
        return '✌️';
      case RpsChoice.none:
        return '⏱️';
    }
  }

  /// A real hand (something the player actually threw).
  bool get isHand => this != RpsChoice.none;

  /// Parses a Firestore value; anything unknown/absent reads as [none] so a
  /// corrupt doc degrades to "no pick" instead of throwing.
  static RpsChoice fromKey(dynamic raw) {
    switch ((raw is String ? raw : '').trim()) {
      case 'rock':
        return RpsChoice.rock;
      case 'paper':
        return RpsChoice.paper;
      case 'scissors':
        return RpsChoice.scissors;
      default:
        return RpsChoice.none;
    }
  }

  /// The hands a player may actually throw (excludes [none]).
  static const List<RpsChoice> hands = <RpsChoice>[
    RpsChoice.rock,
    RpsChoice.paper,
    RpsChoice.scissors,
  ];
}

/// `games/{id}.status` — see overview §4 for the transitions. [unknown] keeps
/// forward-compat with a status this build doesn't know.
enum RpsGameStatus {
  invited,
  playing,
  finished,
  cancelled,
  expired,
  unknown;

  String get key => name;

  /// A game the couple is still "in" (shown as the current game; blocks
  /// creating another one).
  bool get isOpen => this == RpsGameStatus.invited || this == RpsGameStatus.playing;

  static RpsGameStatus fromKey(dynamic raw) {
    switch ((raw is String ? raw : '').trim()) {
      case 'invited':
        return RpsGameStatus.invited;
      case 'playing':
        return RpsGameStatus.playing;
      case 'finished':
        return RpsGameStatus.finished;
      case 'cancelled':
        return RpsGameStatus.cancelled;
      case 'expired':
        return RpsGameStatus.expired;
      default:
        return RpsGameStatus.unknown;
    }
  }
}

/// Why a game ended: both hands thrown ([normal]) or the deadline hit with at
/// least one missing hand ([timeout]).
enum RpsResultReason {
  normal,
  timeout;

  String get key => name;

  static RpsResultReason fromKey(dynamic raw) =>
      (raw is String && raw.trim() == 'timeout')
          ? RpsResultReason.timeout
          : RpsResultReason.normal;
}

/// A finished game seen from ONE player's side.
enum RpsOutcome { win, lose, draw }

/// `games/{id}.result` — written ONLY by Cloud Functions (`resolveRpsGame` /
/// `finishRpsGame`); the client merely reads it. [judge] re-implements the
/// same law locally (optimistic reveal + unit tests + history score).
class RpsResult {
  const RpsResult({
    required this.winnerUid,
    required this.choices,
    required this.reason,
  });

  /// null = draw.
  final String? winnerUid;

  /// `{uid: choice}` for BOTH members (missing hand = [RpsChoice.none]).
  final Map<String, RpsChoice> choices;
  final RpsResultReason reason;

  bool get isDraw => winnerUid == null || winnerUid!.isEmpty;

  /// The hand [uid] threw ([RpsChoice.none] when unknown / not thrown).
  RpsChoice choiceOf(String uid) => choices[uid] ?? RpsChoice.none;

  /// Outcome from [uid]'s point of view.
  RpsOutcome outcomeFor(String uid) {
    if (isDraw) {
      return RpsOutcome.draw;
    }
    return winnerUid == uid ? RpsOutcome.win : RpsOutcome.lose;
  }

  /// The law: rock > scissors > paper > rock. Returns 1 when [a] beats [b],
  /// -1 when [b] beats [a], 0 for a draw. [RpsChoice.none] loses to any real
  /// hand and draws with another [none] ("both skipped").
  static int compare(RpsChoice a, RpsChoice b) {
    if (a == b) {
      return 0;
    }
    if (a == RpsChoice.none) {
      return -1;
    }
    if (b == RpsChoice.none) {
      return 1;
    }
    final aWins = (a == RpsChoice.rock && b == RpsChoice.scissors) ||
        (a == RpsChoice.scissors && b == RpsChoice.paper) ||
        (a == RpsChoice.paper && b == RpsChoice.rock);
    return aWins ? 1 : -1;
  }

  /// Judges one game. [reason] defaults to `timeout` whenever a hand is
  /// missing, `normal` otherwise — exactly what the CF writes.
  static RpsResult judge({
    required String uidA,
    required RpsChoice a,
    required String uidB,
    required RpsChoice b,
    RpsResultReason? reason,
  }) {
    final cmp = compare(a, b);
    final String? winner;
    if (cmp > 0) {
      winner = uidA;
    } else if (cmp < 0) {
      winner = uidB;
    } else {
      winner = null;
    }
    return RpsResult(
      winnerUid: winner,
      choices: <String, RpsChoice>{uidA: a, uidB: b},
      reason: reason ??
          ((a.isHand && b.isHand)
              ? RpsResultReason.normal
              : RpsResultReason.timeout),
    );
  }

  static RpsResult? fromMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final rawChoices = raw['choices'];
    final choices = <String, RpsChoice>{};
    if (rawChoices is Map) {
      for (final entry in rawChoices.entries) {
        final uid = entry.key.toString().trim();
        if (uid.isNotEmpty) {
          choices[uid] = RpsChoice.fromKey(entry.value);
        }
      }
    }
    final winner = raw['winnerUid'];
    return RpsResult(
      winnerUid:
          (winner is String && winner.trim().isNotEmpty) ? winner.trim() : null,
      choices: choices,
      reason: RpsResultReason.fromKey(raw['reason']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'winnerUid': winnerUid,
        'choices': choices.map((uid, c) => MapEntry(uid, c.key)),
        'reason': reason.key,
      };
}

/// `games/{id}/moves/{uid}` — create-only, one per player. Readable by the
/// other player ONLY once the parent is `finished` (rules), so a live game
/// never leaks the partner's hand.
class RpsMove {
  const RpsMove({
    required this.uid,
    required this.choice,
    this.createdAt,
  });

  final String uid;
  final RpsChoice choice;
  final DateTime? createdAt;

  factory RpsMove.fromDoc(String uid, Map<String, dynamic> data) => RpsMove(
        uid: uid,
        choice: RpsChoice.fromKey(data['choice']),
        createdAt: rpsParseTimestamp(data['createdAt']),
      );
}

/// One `games/{gameId}` doc.
class RpsGame {
  const RpsGame({
    required this.id,
    required this.createdBy,
    required this.status,
    this.type = RpsGame.typeKey,
    this.createdAt,
    this.presence = const <String, DateTime>{},
    this.startedAt,
    this.rematchOf,
    this.finishedAt,
    this.result,
    this.cancelledBy,
    this.updatedAt,
  });

  static const String typeKey = 'rps';

  final String id;
  final String type;
  final String createdBy;
  final RpsGameStatus status;
  final DateTime? createdAt;

  /// `{uid: last heartbeat}` — server timestamps.
  final Map<String, DateTime> presence;
  final DateTime? startedAt;
  final String? rematchOf;
  final DateTime? finishedAt;
  final RpsResult? result;
  final String? cancelledBy;
  final DateTime? updatedAt;

  bool get isInvited => status == RpsGameStatus.invited;
  bool get isPlaying => status == RpsGameStatus.playing;
  bool get isFinished => status == RpsGameStatus.finished;
  bool get isOpen => status.isOpen;

  /// Whether [uid] created this game (the only one allowed to cancel it).
  bool isCreatedBy(String uid) => createdBy == uid;

  /// The other member's uid as far as this doc knows it (from presence /
  /// result); null until the partner has touched the game.
  String? partnerOf(String uid) {
    for (final key in presence.keys) {
      if (key != uid) {
        return key;
      }
    }
    final choices = result?.choices;
    if (choices != null) {
      for (final key in choices.keys) {
        if (key != uid) {
          return key;
        }
      }
    }
    return null;
  }

  /// True when [uid]'s heartbeat is within [within] of [reference]
  /// (default: now). Compare against your OWN server-stamped presence to stay
  /// immune to client clock skew.
  bool isPresenceFresh(
    String uid, {
    DateTime? reference,
    Duration within = RpsTiming.presenceFresh,
  }) {
    final stamp = presence[uid];
    if (stamp == null) {
      return false;
    }
    final ref = reference ?? DateTime.now();
    return ref.difference(stamp).abs() <= within;
  }

  /// `invited` for longer than [RpsTiming.inviteTtl] (relative to [now]).
  bool isInviteStale({DateTime? now}) {
    final created = createdAt;
    if (!isInvited || created == null) {
      return false;
    }
    return (now ?? DateTime.now()).difference(created) >= RpsTiming.inviteTtl;
  }

  /// Time left to pick, clamped to `0..countdown`. Null when not `playing` or
  /// `startedAt` hasn't come back from the server yet.
  Duration? countdownRemaining({DateTime? now}) {
    final started = startedAt;
    if (!isPlaying || started == null) {
      return null;
    }
    final elapsed = (now ?? DateTime.now()).difference(started);
    final left = RpsTiming.countdown - elapsed;
    if (left.isNegative) {
      return Duration.zero;
    }
    return left > RpsTiming.countdown ? RpsTiming.countdown : left;
  }

  /// Past `startedAt + countdown + grace` — the server will accept a finish.
  bool isPastGrace({DateTime? now}) {
    final started = startedAt;
    if (!isPlaying || started == null) {
      return false;
    }
    return (now ?? DateTime.now()).difference(started) >=
        RpsTiming.countdown + RpsTiming.grace;
  }

  factory RpsGame.fromFirestore(String id, Map<String, dynamic> data) {
    final rawPresence = data['presence'];
    final presence = <String, DateTime>{};
    if (rawPresence is Map) {
      for (final entry in rawPresence.entries) {
        final stamp = rpsParseTimestamp(entry.value);
        final uid = entry.key.toString().trim();
        if (stamp != null && uid.isNotEmpty) {
          presence[uid] = stamp;
        }
      }
    }
    return RpsGame(
      id: id,
      type: (data['type'] as String?)?.trim() ?? typeKey,
      createdBy: (data['createdBy'] as String?)?.trim() ?? '',
      status: RpsGameStatus.fromKey(data['status']),
      createdAt: rpsParseTimestamp(data['createdAt']),
      presence: presence,
      startedAt: rpsParseTimestamp(data['startedAt']),
      rematchOf: _nullableString(data['rematchOf']),
      finishedAt: rpsParseTimestamp(data['finishedAt']),
      result: RpsResult.fromMap(data['result']),
      cancelledBy: _nullableString(data['cancelledBy']),
      updatedAt: rpsParseTimestamp(data['updatedAt']),
    );
  }

  /// Plain-value snapshot (timestamps as ISO strings). NOT the create payload —
  /// the service builds that with `FieldValue.serverTimestamp()` because the
  /// rules require `createdAt == request.time`.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type,
        'createdBy': createdBy,
        'status': status.key,
        'createdAt': createdAt?.toIso8601String(),
        'presence': presence.map((uid, t) => MapEntry(uid, t.toIso8601String())),
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (rematchOf != null) 'rematchOf': rematchOf,
        if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
        if (result != null) 'result': result!.toMap(),
        if (cancelledBy != null) 'cancelledBy': cancelledBy,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  static String? _nullableString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }
}

/// Win/loss/draw tally from MY side, computed from a list of finished games.
class RpsScore {
  const RpsScore({this.wins = 0, this.losses = 0, this.draws = 0});

  final int wins;
  final int losses;
  final int draws;

  int get total => wins + losses + draws;

  static RpsScore tally(Iterable<RpsGame> games, String myUid) {
    var w = 0;
    var l = 0;
    var d = 0;
    for (final game in games) {
      final result = game.result;
      if (!game.isFinished || result == null) {
        continue;
      }
      switch (result.outcomeFor(myUid)) {
        case RpsOutcome.win:
          w++;
        case RpsOutcome.lose:
          l++;
        case RpsOutcome.draw:
          d++;
      }
    }
    return RpsScore(wins: w, losses: l, draws: d);
  }
}

/// Accepts a Firestore Timestamp (duck-typed via `toDate()`), a [DateTime], an
/// ISO string or epoch millis — without importing cloud_firestore here.
DateTime? rpsParseTimestamp(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  try {
    final dynamic d = (value as dynamic).toDate();
    return d is DateTime ? d : null;
  } catch (_) {
    return null;
  }
}
