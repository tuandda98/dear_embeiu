import 'rps_game.dart' show rpsParseTimestamp;

/// Timing contract of the caro game (feature caro-game, overview D7/D9–D11).
/// The server owns every rule; the client only uses these to decide what to
/// SHOW (nudge countdown, "đang xem ván", "Kết thúc ván").
class CaroTiming {
  CaroTiming._();

  /// Presence heartbeat while the game screen is visible (D11).
  static const Duration heartbeat = Duration(seconds: 20);

  /// A presence stamp younger than this = "đang xem ván" (D11; the CF skips
  /// the push with the same window).
  static const Duration presenceFresh = Duration(seconds: 45);

  /// "Nhắc người ấy" cooldown from the later of my move / the last nudge.
  static const Duration nudgeCooldown = Duration(minutes: 30);

  /// No move for this long → either player may end the game (`expire`).
  static const Duration staleAfter = Duration(days: 7);

  /// Invited player still hasn't moved → hint that their app may be old.
  static const Duration oldAppHintAfter = Duration(hours: 24);
}

/// Win rule chosen per game (D3), immutable once the game exists.
enum CaroRule {
  /// "Chặn hai đầu": five wins unless BOTH ends are the opponent's stones
  /// (the board edge is not a block). Default.
  vn('vn'),

  /// "Tự do": any five in a row wins.
  free('free');

  const CaroRule(this.key);

  final String key;

  static CaroRule fromKey(Object? raw) =>
      '${raw ?? ''}'.trim() == 'free' ? CaroRule.free : CaroRule.vn;
}

enum CaroGameStatus {
  playing('playing'),
  finished('finished'),
  cancelled('cancelled'),
  expired('expired'),
  unknown('');

  const CaroGameStatus(this.key);

  final String key;

  static CaroGameStatus fromKey(Object? raw) {
    final key = '${raw ?? ''}'.trim();
    for (final s in values) {
      if (s.key == key && s != unknown) {
        return s;
      }
    }
    return unknown;
  }
}

/// X (the inviter, even move indexes) or O.
enum CaroSide { x, o }

enum CaroResultReason {
  five('five'),
  resign('resign'),
  full('full');

  const CaroResultReason(this.key);

  final String key;

  static CaroResultReason fromKey(Object? raw) {
    final key = '${raw ?? ''}'.trim();
    return values.firstWhere((r) => r.key == key, orElse: () => five);
  }
}

/// How a finished game ended for one player.
enum CaroOutcome { win, lose, draw }

/// `result` map written by the `caroAction` callable.
class CaroResult {
  const CaroResult({
    required this.winnerUid,
    required this.reason,
    this.line = const <int>[],
  });

  /// null = draw (full board).
  final String? winnerUid;
  final CaroResultReason reason;

  /// Squares of the winning run (reason `five` only).
  final List<int> line;

  bool get isDraw => winnerUid == null;

  CaroOutcome outcomeFor(String uid) {
    if (winnerUid == null) {
      return CaroOutcome.draw;
    }
    return winnerUid == uid ? CaroOutcome.win : CaroOutcome.lose;
  }

  static CaroResult? fromMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final winner = '${raw['winnerUid'] ?? ''}'.trim();
    return CaroResult(
      winnerUid: winner.isEmpty ? null : winner,
      reason: CaroResultReason.fromKey(raw['reason']),
      line: caroParseCells(raw['line']),
    );
  }
}

/// `couples/{coupleId}/caroState/main` — open-game pointer + all-time score
/// (CF-only). Absent doc = no game ever, 0 – 0.
class CaroState {
  const CaroState({
    this.openGameId,
    this.wins = const <String, int>{},
    this.draws = 0,
    this.updatedAt,
  });

  static const CaroState empty = CaroState();

  final String? openGameId;
  final Map<String, int> wins;
  final int draws;
  final DateTime? updatedAt;

  int winsOf(String? uid) => uid == null ? 0 : (wins[uid] ?? 0);

  /// Finished games that count (wins of both + draws). [players] = the two
  /// CURRENT members: a stale key from an earlier partner never counts.
  int totalFor(String me, String partner) =>
      winsOf(me) + winsOf(partner) + draws;

  factory CaroState.fromFirestore(Map<String, dynamic> data) {
    final rawWins = data['wins'];
    final wins = <String, int>{};
    if (rawWins is Map) {
      rawWins.forEach((key, value) {
        if (value is num) {
          wins['$key'] = value.toInt();
        }
      });
    }
    final open = '${data['openGameId'] ?? ''}'.trim();
    final draws = data['draws'];
    return CaroState(
      openGameId: open.isEmpty ? null : open,
      wins: wins,
      draws: draws is num ? draws.toInt() : 0,
      updatedAt: rpsParseTimestamp(data['updatedAt']),
    );
  }
}

/// One caro game (`couples/{coupleId}/games/{gameId}`, `type == 'caro'`) —
/// contract in `project/features/caro-game/overview.md` §5.1.
class CaroGame {
  const CaroGame({
    required this.id,
    required this.rule,
    required this.createdBy,
    required this.playerX,
    required this.playerO,
    required this.status,
    required this.cells,
    required this.turnUid,
    this.size = CaroBoard.size,
    this.createdAt,
    this.lastMoveAt,
    this.lastMoveBy,
    this.presence = const <String, DateTime>{},
    this.result,
    this.finishedAt,
    this.endedBy,
    this.lastNudgeAt,
    this.rematchOf,
    this.updatedAt,
  });

  static const String typeKey = 'caro';

  final String id;
  final CaroRule rule;
  final int size;
  final String createdBy;
  final String playerX;
  final String playerO;
  final CaroGameStatus status;

  /// Squares `row * 15 + col` in play order; even index = X.
  final List<int> cells;

  /// Who moves next (unchanged once the game is over).
  final String turnUid;
  final DateTime? createdAt;
  final DateTime? lastMoveAt;
  final String? lastMoveBy;
  final Map<String, DateTime> presence;
  final CaroResult? result;
  final DateTime? finishedAt;
  final String? endedBy;
  final DateTime? lastNudgeAt;
  final String? rematchOf;
  final DateTime? updatedAt;

  bool get isPlaying => status == CaroGameStatus.playing;
  bool get isFinished => status == CaroGameStatus.finished;
  bool get isCancelled => status == CaroGameStatus.cancelled;
  bool get isExpired => status == CaroGameStatus.expired;

  int get moveCount => cells.length;
  int? get lastCell => cells.isEmpty ? null : cells.last;

  CaroBoard get board => CaroBoard(cells);

  bool isPlayer(String uid) => uid == playerX || uid == playerO;

  /// The other player of [uid] (null when [uid] isn't playing).
  String? opponentOf(String uid) {
    if (uid == playerX) {
      return playerO;
    }
    if (uid == playerO) {
      return playerX;
    }
    return null;
  }

  CaroSide? sideOf(String uid) {
    if (uid == playerX) {
      return CaroSide.x;
    }
    if (uid == playerO) {
      return CaroSide.o;
    }
    return null;
  }

  /// Both players are among [memberIds] (D20: a game from an earlier pair is
  /// hidden, and the server treats it as over).
  bool playersAreMembers(Iterable<String> memberIds) {
    final ids = memberIds.toSet();
    return ids.contains(playerX) && ids.contains(playerO);
  }

  bool isMyTurn(String uid) => isPlaying && turnUid == uid;

  /// Still the invite: only the inviter's first stone is on the board.
  bool get isFreshInvite => isPlaying && cells.length <= 1;

  /// "Để sau" is allowed (server: `cancel` needs ≤1 stone).
  bool get canCancel => isFreshInvite;

  bool isPresenceFresh(String uid, {DateTime? now}) {
    final at = presence[uid];
    if (at == null) {
      return false;
    }
    return (now ?? DateTime.now()).difference(at) < CaroTiming.presenceFresh;
  }

  /// Nobody moved for 7 days → "Kết thúc ván" (server re-checks).
  bool isStale({DateTime? now}) {
    final at = lastMoveAt ?? createdAt;
    if (!isPlaying || at == null) {
      return false;
    }
    return (now ?? DateTime.now()).difference(at) >= CaroTiming.staleAfter;
  }

  /// Time left before [uid] may nudge; zero = now. Only the waiting player
  /// (not [turnUid]) can nudge at all — null otherwise (D10).
  Duration? nudgeWait(String uid, {DateTime? now}) {
    if (!isPlaying || !isPlayer(uid) || turnUid == uid) {
      return null;
    }
    final since = [lastMoveAt, lastNudgeAt]
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    if (since == null) {
      return Duration.zero;
    }
    final left =
        CaroTiming.nudgeCooldown - (now ?? DateTime.now()).difference(since);
    return left.isNegative ? Duration.zero : left;
  }

  /// Hours from the first to the last stone (analytics `span_hours`).
  int get spanHours {
    final from = createdAt;
    final to = finishedAt ?? lastMoveAt;
    if (from == null || to == null || to.isBefore(from)) {
      return 0;
    }
    return (to.difference(from).inMinutes / 60).round();
  }

  factory CaroGame.fromFirestore(String id, Map<String, dynamic> data) {
    final players = data['players'];
    String player(String key) =>
        players is Map ? '${players[key] ?? ''}'.trim() : '';
    final rawPresence = data['presence'];
    final presence = <String, DateTime>{};
    if (rawPresence is Map) {
      rawPresence.forEach((key, value) {
        final at = rpsParseTimestamp(value);
        if (at != null) {
          presence['$key'] = at;
        }
      });
    }
    String? optional(String key) {
      final v = '${data[key] ?? ''}'.trim();
      return v.isEmpty ? null : v;
    }

    final size = data['size'];
    return CaroGame(
      id: id,
      rule: CaroRule.fromKey(data['rule']),
      size: size is num ? size.toInt() : CaroBoard.size,
      createdBy: '${data['createdBy'] ?? ''}'.trim(),
      playerX: player('x'),
      playerO: player('o'),
      status: CaroGameStatus.fromKey(data['status']),
      cells: caroParseCells(data['cells']),
      turnUid: '${data['turnUid'] ?? ''}'.trim(),
      createdAt: rpsParseTimestamp(data['createdAt']),
      lastMoveAt: rpsParseTimestamp(data['lastMoveAt']),
      lastMoveBy: optional('lastMoveBy'),
      presence: presence,
      result: CaroResult.fromMap(data['result']),
      finishedAt: rpsParseTimestamp(data['finishedAt']),
      endedBy: optional('endedBy'),
      lastNudgeAt: rpsParseTimestamp(data['lastNudgeAt']),
      rematchOf: optional('rematchOf'),
      updatedAt: rpsParseTimestamp(data['updatedAt']),
    );
  }
}

/// Board built from `cells` — pure, shared by the live game, the result and
/// the replay of an old game. Same win check as the CF `caroWinner`.
class CaroBoard {
  CaroBoard(List<int> cells) : cells = List<int>.unmodifiable(cells) {
    for (var i = 0; i < this.cells.length; i++) {
      _order[this.cells[i]] = i;
    }
  }

  static const int size = 15;
  static const int squares = size * size;

  final List<int> cells;
  final Map<int, int> _order = <int, int>{};

  static int indexOf(int row, int col) => row * size + col;
  static int rowOf(int index) => index ~/ size;
  static int colOf(int index) => index % size;
  static bool inside(int row, int col) =>
      row >= 0 && row < size && col >= 0 && col < size;

  /// The piece on [index], null when empty.
  CaroSide? pieceAt(int index) {
    final i = _order[index];
    if (i == null) {
      return null;
    }
    return i.isEven ? CaroSide.x : CaroSide.o;
  }

  /// 1-based move number of the stone on [index] (null when empty).
  int? moveNumberAt(int index) {
    final i = _order[index];
    return i == null ? null : i + 1;
  }

  bool isEmpty(int index) => !_order.containsKey(index);

  /// Side to play next (X when the board is empty).
  CaroSide get nextSide => cells.length.isEven ? CaroSide.x : CaroSide.o;

  bool get isFull => cells.length >= squares;

  /// Winning run through the LAST stone, or empty (rule [rule], see
  /// [CaroRule]). Mirrors `caroWinner` in functions/index.js.
  List<int> winningLine(CaroRule rule) {
    if (cells.isEmpty) {
      return const <int>[];
    }
    final last = cells.last;
    final me = pieceAt(last);
    final r0 = rowOf(last);
    final c0 = colOf(last);
    const directions = <(int, int)>[(0, 1), (1, 0), (1, 1), (1, -1)];
    for (final (dr, dc) in directions) {
      final line = <int>[last];
      var r = r0 + dr;
      var c = c0 + dc;
      while (inside(r, c) && pieceAt(indexOf(r, c)) == me) {
        line.add(indexOf(r, c));
        r += dr;
        c += dc;
      }
      final blockedA = inside(r, c) && _isOpponent(indexOf(r, c), me);
      r = r0 - dr;
      c = c0 - dc;
      while (inside(r, c) && pieceAt(indexOf(r, c)) == me) {
        line.insert(0, indexOf(r, c));
        r -= dr;
        c -= dc;
      }
      final blockedB = inside(r, c) && _isOpponent(indexOf(r, c), me);
      if (line.length >= 5 &&
          (rule == CaroRule.free || !(blockedA && blockedB))) {
        return line;
      }
    }
    return const <int>[];
  }

  bool _isOpponent(int index, CaroSide? me) {
    final p = pieceAt(index);
    return p != null && p != me;
  }
}

/// `cells` / `line` list → ints on the board (anything else dropped).
List<int> caroParseCells(Object? raw) {
  if (raw is! List) {
    return const <int>[];
  }
  final out = <int>[];
  for (final v in raw) {
    if (v is num) {
      final i = v.toInt();
      if (i >= 0 && i < CaroBoard.squares) {
        out.add(i);
      }
    }
  }
  return List<int>.unmodifiable(out);
}
