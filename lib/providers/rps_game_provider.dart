import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/foundation.dart';

import '../models/rps_game.dart';
import '../services/analytics_service.dart';
import '../services/rps_game_service.dart';

/// What the game screen should render right now (feature rps-game, overview
/// §4). Derived from the current game doc + my move + the clock; the screen
/// never has to reason about status/startedAt itself.
enum RpsPhase {
  /// No game entered ([RpsGameProvider.enter] not called / after `leave`).
  idle,

  /// Entered a game but the first snapshot hasn't landed yet.
  loading,

  /// `invited` — one of us is on the screen, waiting for the other.
  waiting,

  /// `playing`, clock running, I haven't picked.
  countdown,

  /// `playing`, I've locked a hand, waiting for the partner / the clock.
  chosenWaiting,

  /// `playing` but the clock hit 0 without my hand — the server (callable /
  /// CF) is settling the game. Buttons stay locked.
  resolving,

  /// `finished` — `result` is available.
  result,
  expired,
  cancelled,
}

/// State for rock-paper-scissors (feature rps-game, 2026-09-13).
///
/// Two independent layers:
/// 1. **Couple-wide** — `watchForCouple` (wired in `session_resolver` while a
///    couple is active, `clear` on sign-out/no-couple) streams the single
///    OPEN game so Home/Profile can badge a pending invite without the screen
///    being open.
/// 2. **In-screen** — `enter(gameId)` / `leave()` drive one game: heartbeat
///    (3s), auto-start when both are present, the 100ms countdown ticker,
///    auto-finish via the callable once the deadline + grace passed, and
///    auto-expire of a stale invite. The screen only calls `choose`,
///    `rematch`, `cancel`.
///
/// Every write is fail-soft (see [RpsGameService]); the provider never throws
/// into the UI — a refused move simply unlocks the buttons again.
class RpsGameProvider extends ChangeNotifier {
  RpsGameProvider({RpsGameService? service})
    : _service = service ?? RpsGameService();

  final RpsGameService _service;

  /// Ticker cadence while the countdown runs.
  static const Duration _tick = Duration(milliseconds: 100);

  /// Minimum spacing between `finishRpsGame` attempts for one game (the
  /// callable is idempotent, but don't hammer it while offline).
  static const Duration _finishRetryEvery = Duration(seconds: 3);

  // ---- couple-wide ----
  String? _coupleId;
  String? _myUid;
  String? _partnerUid;
  StreamSubscription<RpsGame?>? _openSub;
  RpsGame? _openGame;

  // ---- in-screen ----
  String? _currentGameId;
  RpsGame? _currentGame;
  bool _currentLoaded = false;
  StreamSubscription<RpsGame?>? _gameSub;
  StreamSubscription<RpsMove?>? _moveSub;
  RpsMove? _myMove;
  RpsChoice? _pendingChoice;
  Timer? _heartbeatTimer;
  Timer? _tickTimer;
  bool _startInFlight = false;
  bool _expireInFlight = false;
  DateTime? _lastFinishAttempt;
  String? _loggedFinishedGameId;
  bool _actionBusy = false;

  // ---- history ----
  List<RpsGame> _history = const <RpsGame>[];
  DocumentSnapshot<Map<String, dynamic>>? _historyCursor;
  bool _historyHasMore = false;
  bool _historyLoading = false;
  bool _historyLoaded = false;

  // ---- all-time score (Profile badge / history scoreboard) ----
  RpsScore? _totalScore;
  bool _totalScoreLoading = false;

  // ------------------------------------------------------------------ getters

  bool get isReady => _coupleId != null && _myUid != null;
  bool get isUsingFirebase => _service.isUsingFirebase;
  String? get myUid => _myUid;

  /// The partner's uid: from the couple (session_resolver) or, failing that,
  /// whoever else has touched the current/open game.
  String? get partnerUid {
    final fromCouple = _partnerUid;
    if (fromCouple != null && fromCouple.isNotEmpty) {
      return fromCouple;
    }
    final me = _myUid;
    if (me == null) {
      return null;
    }
    return _currentGame?.partnerOf(me) ?? _openGame?.partnerOf(me);
  }

  /// The couple's open (`invited`/`playing`) game, if any — couple-wide.
  RpsGame? get openGame => _openGame;

  /// An `invited` game the PARTNER created that I haven't joined yet — drives
  /// the badge on the Home/Profile entry points.
  bool get hasPendingInvite {
    final g = _openGame;
    final me = _myUid;
    return g != null && me != null && g.isInvited && !g.isCreatedBy(me);
  }

  /// The game the screen is currently in (null when idle).
  RpsGame? get currentGame => _currentGame;
  String? get currentGameId => _currentGameId;

  /// True once the first snapshot of the entered game has landed (a null
  /// [currentGame] after this means the doc doesn't exist / can't be read).
  bool get isCurrentLoaded => _currentLoaded;

  /// My locked-in hand (optimistic while the write is in flight); null = none.
  RpsChoice? get myChoice {
    final move = _myMove;
    if (move != null && move.choice.isHand) {
      return move.choice;
    }
    return _pendingChoice;
  }

  bool get hasChosen => myChoice != null;

  /// True while an action (invite/rematch/cancel/choose) is being written —
  /// lets the screen disable its buttons.
  bool get isBusy => _actionBusy;

  /// Time left to pick (0..5s). [Duration.zero] when the clock ran out or the
  /// game isn't `playing`.
  Duration get countdownRemaining =>
      _currentGame?.countdownRemaining() ?? Duration.zero;

  /// Whole seconds left, rounded UP (5,4,3,2,1,0) — what the big number shows.
  int get countdownSeconds {
    final ms = countdownRemaining.inMilliseconds;
    return (ms + 999) ~/ 1000;
  }

  /// Fraction of the window still left (1.0 → 0.0) for a ring/bar.
  double get countdownProgress {
    final total = RpsTiming.countdown.inMilliseconds;
    return total == 0 ? 0 : countdownRemaining.inMilliseconds / total;
  }

  RpsPhase get phase {
    if (_currentGameId == null) {
      return RpsPhase.idle;
    }
    final game = _currentGame;
    if (game == null) {
      // Not loaded yet, or the doc vanished — treat as loading until `leave`.
      return RpsPhase.loading;
    }
    switch (game.status) {
      case RpsGameStatus.invited:
        return RpsPhase.waiting;
      case RpsGameStatus.playing:
        if (hasChosen) {
          return RpsPhase.chosenWaiting;
        }
        if (game.startedAt == null) {
          // Transitioned locally; server timestamp not echoed yet.
          return RpsPhase.countdown;
        }
        return countdownRemaining > Duration.zero
            ? RpsPhase.countdown
            : RpsPhase.resolving;
      case RpsGameStatus.finished:
        return RpsPhase.result;
      case RpsGameStatus.expired:
        return RpsPhase.expired;
      case RpsGameStatus.cancelled:
        return RpsPhase.cancelled;
      case RpsGameStatus.unknown:
        return RpsPhase.loading;
    }
  }

  /// Buttons are tappable only during the live countdown, once.
  bool get canChoose => phase == RpsPhase.countdown && !_actionBusy;

  /// Only the creator can cancel, and only while still waiting.
  bool get canCancel {
    final g = _currentGame;
    final me = _myUid;
    return g != null && me != null && g.isInvited && g.isCreatedBy(me);
  }

  /// The partner is on the screen right now (fresh heartbeat).
  bool get isPartnerPresent {
    final g = _currentGame;
    final partner = partnerUid;
    if (g == null || partner == null) {
      return false;
    }
    return g.isPresenceFresh(partner, reference: g.presence[_myUid ?? '']);
  }

  /// Result of the current game (null until finished).
  RpsResult? get result => _currentGame?.result;

  /// Outcome of the current game from MY side (null until finished).
  RpsOutcome? get myOutcome {
    final r = result;
    final me = _myUid;
    return (r == null || me == null) ? null : r.outcomeFor(me);
  }

  // ---- history ----
  List<RpsGame> get history => _history;
  bool get hasMoreHistory => _historyHasMore;
  bool get isLoadingHistory => _historyLoading;
  bool get isHistoryLoaded => _historyLoaded;

  /// Win/loss/draw tally over the games LOADED so far (paged — call
  /// [loadMoreHistory] until [hasMoreHistory] is false for the full record).
  RpsScore get score {
    final me = _myUid;
    return me == null ? const RpsScore() : RpsScore.tally(_history, me);
  }

  /// All-time tally from the server (`count()` aggregations) — null until
  /// [loadTotalScore] resolved once. Kept in sync locally when a game the
  /// screen is in finishes, so the Profile badge bumps without a refetch.
  RpsScore? get totalScore => _totalScore;
  bool get isTotalScoreLoading => _totalScoreLoading;

  /// Tally of the games LOADED so far that finished since Monday 00:00 local
  /// (Home card "Tuần này …"). Newest-first paging means the first page
  /// covers the week unless the couple played 30+ rounds this week.
  RpsScore get weekScore {
    final me = _myUid;
    if (me == null) {
      return const RpsScore();
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return RpsScore.tally(
      _history.where((g) {
        final at = g.finishedAt;
        return at != null && !at.isBefore(monday);
      }),
      me,
    );
  }

  /// My current win streak over the loaded history (newest first): how many
  /// of the most recent games I won in a row. 0 when the latest wasn't a win.
  int get currentWinStreak {
    final me = _myUid;
    if (me == null) {
      return 0;
    }
    var streak = 0;
    for (final g in _history) {
      final r = g.result;
      if (!g.isFinished || r == null) {
        continue;
      }
      if (r.outcomeFor(me) != RpsOutcome.win) {
        break;
      }
      streak++;
    }
    return streak;
  }

  // ------------------------------------------------------------- couple-wide

  /// Follow the couple's open game. Idempotent for the same (couple, uid).
  /// [partnerUid] may be empty while still waiting for a partner.
  void watchForCouple(String coupleId, String myUid, String partnerUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }
    final samePair = _coupleId == coupleId && _myUid == myUid;
    _partnerUid = partnerUid.trim().isEmpty ? null : partnerUid.trim();
    if (samePair && _openSub != null) {
      return;
    }
    if (!samePair) {
      _leaveInternal();
      _resetHistory();
      _totalScore = null;
      _totalScoreLoading = false;
    }
    _coupleId = coupleId;
    _myUid = myUid;
    _openSub?.cancel();
    _openSub = _service.watchOpenGame(coupleId).listen((game) {
      _openGame = game;
      notifyListeners();
    }, onError: (_) {});
    notifyListeners();
  }

  /// Stop everything (sign-out / no-couple).
  void clear() {
    _openSub?.cancel();
    _openSub = null;
    _openGame = null;
    _coupleId = null;
    _myUid = null;
    _partnerUid = null;
    _leaveInternal();
    _resetHistory();
    _totalScore = null;
    _totalScoreLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------- actions

  /// "Oẳn tù tì" tapped: joins the couple's open game if there is one (one
  /// open game at a time — overview §4.5), otherwise creates a fresh invite
  /// (the CF pushes the partner). Returns the gameId entered, or null when
  /// nothing could be written.
  Future<String?> invite() async {
    final coupleId = _coupleId;
    final me = _myUid;
    if (coupleId == null || me == null || _actionBusy) {
      return null;
    }
    final open = _openGame;
    if (open != null && open.isOpen && !open.isInviteStale()) {
      enter(open.id);
      return open.id;
    }
    _setBusy(true);
    try {
      final id = await _service.createGame(coupleId: coupleId, uid: me);
      if (id == null) {
        return null;
      }
      AnalyticsService.instance.logRpsInviteSent();
      enter(id);
      return id;
    } finally {
      _setBusy(false);
    }
  }

  /// "Chơi lại" from the result screen: new invite linked to this game so the
  /// CF can skip the push while the partner is still on the same screen.
  Future<String?> rematch() async {
    final coupleId = _coupleId;
    final me = _myUid;
    final previous = _currentGame;
    if (coupleId == null || me == null || _actionBusy) {
      return null;
    }
    // Partner may already have created the rematch — just follow it.
    final open = _openGame;
    if (open != null && open.isOpen && open.id != _currentGameId) {
      enter(open.id);
      return open.id;
    }
    _setBusy(true);
    try {
      final id = await _service.createGame(
        coupleId: coupleId,
        uid: me,
        rematchOf: previous?.id,
      );
      if (id == null) {
        return null;
      }
      AnalyticsService.instance.logRpsInviteSent(rematch: true);
      enter(id);
      return id;
    } finally {
      _setBusy(false);
    }
  }

  /// "Nhắc lại" on the waiting screen (design D7): withdraw the current
  /// invite and create a fresh one so `notifyRpsInvite` pushes the partner
  /// again. Bypasses [invite]'s "join the open game" shortcut on purpose —
  /// the open-game stream may still echo the game we just cancelled. Returns
  /// the new gameId, or null when nothing was written.
  Future<String?> renewInvite() async {
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentGameId;
    if (coupleId == null || me == null || gameId == null || _actionBusy) {
      return null;
    }
    _setBusy(true);
    try {
      if (canCancel) {
        await _service.cancel(coupleId: coupleId, gameId: gameId, uid: me);
      }
      final id = await _service.createGame(coupleId: coupleId, uid: me);
      if (id == null) {
        return null;
      }
      AnalyticsService.instance.logRpsInviteSent();
      enter(id);
      return id;
    } finally {
      _setBusy(false);
    }
  }

  /// Lock in my hand. Returns false when refused (too late / not playing /
  /// already chosen) — the optimistic lock is rolled back in that case.
  Future<bool> choose(RpsChoice choice) async {
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentGameId;
    if (coupleId == null ||
        me == null ||
        gameId == null ||
        !choice.isHand ||
        !canChoose) {
      return false;
    }
    _pendingChoice = choice;
    _setBusy(true);
    final ok = await _service.submitMove(
      coupleId: coupleId,
      gameId: gameId,
      uid: me,
      choice: choice,
    );
    if (!ok && _currentGameId == gameId) {
      _pendingChoice = null;
    }
    _setBusy(false);
    return ok;
  }

  /// Creator withdraws a pending invite.
  Future<bool> cancel() async {
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentGameId;
    if (coupleId == null || me == null || gameId == null || !canCancel) {
      return false;
    }
    _setBusy(true);
    try {
      return await _service.cancel(coupleId: coupleId, gameId: gameId, uid: me);
    } finally {
      _setBusy(false);
    }
  }

  // ------------------------------------------------------------ enter/leave

  /// Attach to [gameId]: stream it + my move, start the heartbeat. Call from
  /// the game screen's initState (or right after [invite]/[rematch]).
  void enter(String gameId) {
    final coupleId = _coupleId;
    final me = _myUid;
    if (coupleId == null || me == null || gameId.trim().isEmpty) {
      return;
    }
    if (_currentGameId == gameId && _gameSub != null) {
      return;
    }
    _leaveInternal();
    _currentGameId = gameId;
    _currentLoaded = false;
    notifyListeners();

    _gameSub = _service
        .watchGame(coupleId, gameId)
        .listen(_onGameSnapshot, onError: (_) {});
    _moveSub = _service.watchMyMove(coupleId, gameId, me).listen((move) {
      _myMove = move;
      if (move != null) {
        _pendingChoice = null;
      }
      notifyListeners();
    }, onError: (_) {});
    // Heartbeat now + every 3s; keeps running on the result screen too, so the
    // CF knows I'm still looking and doesn't push me the result.
    unawaited(_service.heartbeat(coupleId, gameId, me));
    _heartbeatTimer = Timer.periodic(RpsTiming.heartbeat, (_) {
      unawaited(_service.heartbeat(coupleId, gameId, me));
    });
  }

  /// Detach from the current game (screen disposed). The couple-wide open
  /// game watch keeps running.
  void leave() {
    _leaveInternal();
    notifyListeners();
  }

  void _leaveInternal() {
    _gameSub?.cancel();
    _gameSub = null;
    _moveSub?.cancel();
    _moveSub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _stopTicker();
    _currentGameId = null;
    _currentGame = null;
    _currentLoaded = false;
    _myMove = null;
    _pendingChoice = null;
    _startInFlight = false;
    _expireInFlight = false;
    _lastFinishAttempt = null;
  }

  void _onGameSnapshot(RpsGame? game) {
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentGameId;
    if (coupleId == null || me == null || gameId == null) {
      return;
    }
    _currentGame = game;
    _currentLoaded = true;
    if (game == null) {
      _stopTicker();
      notifyListeners();
      return;
    }

    switch (game.status) {
      case RpsGameStatus.invited:
        _stopTicker();
        if (game.isInviteStale()) {
          _maybeExpire(coupleId, gameId);
        } else {
          _maybeStart(coupleId, gameId, me, game);
        }
      case RpsGameStatus.playing:
        _startTicker();
        _maybeFinish(coupleId, gameId, game);
      case RpsGameStatus.finished:
        _stopTicker();
        _onFinished(game, me);
      case RpsGameStatus.cancelled:
      case RpsGameStatus.expired:
      case RpsGameStatus.unknown:
        _stopTicker();
    }
    notifyListeners();
  }

  /// Flip `invited → playing` when the partner's heartbeat is fresh. Guarded
  /// so overlapping snapshots don't stack transactions; the transaction itself
  /// re-checks, so losing the race to the other phone is harmless.
  void _maybeStart(String coupleId, String gameId, String me, RpsGame game) {
    if (_startInFlight) {
      return;
    }
    final partner = _partnerUid ?? game.partnerOf(me);
    if (partner == null) {
      return;
    }
    if (!game.isPresenceFresh(partner, reference: game.presence[me])) {
      return;
    }
    _startInFlight = true;
    unawaited(
      _service
          .startIfBothPresent(
            coupleId: coupleId,
            gameId: gameId,
            myUid: me,
            partnerUid: partner,
          )
          .whenComplete(() => _startInFlight = false),
    );
  }

  void _maybeExpire(String coupleId, String gameId) {
    if (_expireInFlight) {
      return;
    }
    _expireInFlight = true;
    unawaited(
      _service
          .expireIfStale(coupleId: coupleId, gameId: gameId)
          .whenComplete(() => _expireInFlight = false),
    );
  }

  /// Past deadline + grace and still `playing` → ask the callable to settle
  /// (rate-limited; both phones may call, server writes once).
  void _maybeFinish(String coupleId, String gameId, RpsGame game) {
    if (!game.isPastGrace()) {
      return;
    }
    final last = _lastFinishAttempt;
    final now = DateTime.now();
    if (last != null && now.difference(last) < _finishRetryEvery) {
      return;
    }
    _lastFinishAttempt = now;
    unawaited(_service.finishViaCallable(coupleId: coupleId, gameId: gameId));
  }

  void _onFinished(RpsGame game, String me) {
    // Analytics once per game (no content — just the outcome enum).
    if (_loggedFinishedGameId != game.id) {
      _loggedFinishedGameId = game.id;
      final outcome = game.result?.outcomeFor(me);
      if (outcome != null) {
        AnalyticsService.instance.logRpsGameFinished(outcome.name);
      }
    }
    // Keep a loaded history in sync without a refetch.
    if (_historyLoaded && !_history.any((g) => g.id == game.id)) {
      _history = <RpsGame>[game, ..._history];
      final total = _totalScore;
      final outcome = game.result?.outcomeFor(me);
      if (total != null && outcome != null) {
        _totalScore = RpsScore(
          wins: total.wins + (outcome == RpsOutcome.win ? 1 : 0),
          losses: total.losses + (outcome == RpsOutcome.lose ? 1 : 0),
          draws: total.draws + (outcome == RpsOutcome.draw ? 1 : 0),
        );
      }
    }
  }

  void _startTicker() {
    if (_tickTimer != null) {
      return;
    }
    _tickTimer = Timer.periodic(_tick, (_) {
      final game = _currentGame;
      if (game == null || !game.isPlaying) {
        _stopTicker();
        return;
      }
      final coupleId = _coupleId;
      final gameId = _currentGameId;
      if (coupleId != null && gameId != null) {
        _maybeFinish(coupleId, gameId, game);
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _setBusy(bool value) {
    if (_actionBusy == value) {
      return;
    }
    _actionBusy = value;
    notifyListeners();
  }

  // ----------------------------------------------------------------- history

  /// (Re)loads the first page of finished games. Safe to call on screen open.
  Future<void> loadHistory() async {
    final coupleId = _coupleId;
    if (coupleId == null || _historyLoading) {
      return;
    }
    _historyLoading = true;
    notifyListeners();
    final page = await _service.fetchHistoryPage(coupleId: coupleId);
    if (_coupleId != coupleId) {
      return; // couple changed mid-flight
    }
    _history = page.items;
    _historyCursor = page.lastDoc;
    _historyHasMore = page.hasMore;
    _historyLoaded = true;
    _historyLoading = false;
    notifyListeners();
  }

  /// Appends the next page (no-op when there is none / already loading).
  Future<void> loadMoreHistory() async {
    final coupleId = _coupleId;
    final cursor = _historyCursor;
    if (coupleId == null || _historyLoading || !_historyHasMore) {
      return;
    }
    _historyLoading = true;
    notifyListeners();
    final page = await _service.fetchHistoryPage(
      coupleId: coupleId,
      startAfter: cursor,
    );
    if (_coupleId != coupleId) {
      return;
    }
    final seen = _history.map((g) => g.id).toSet();
    _history = <RpsGame>[
      ..._history,
      ...page.items.where((g) => !seen.contains(g.id)),
    ];
    _historyCursor = page.lastDoc ?? cursor;
    _historyHasMore = page.hasMore;
    _historyLoading = false;
    notifyListeners();
  }

  /// Fetches the all-time tally once (Profile badge / scoreboard). Safe to
  /// call on every build — no-op while in flight or already loaded unless
  /// [force].
  Future<void> loadTotalScore({bool force = false}) async {
    final coupleId = _coupleId;
    final me = _myUid;
    if (coupleId == null || me == null || _totalScoreLoading) {
      return;
    }
    if (_totalScore != null && !force) {
      return;
    }
    _totalScoreLoading = true;
    notifyListeners();
    final score = await _service.countScore(coupleId: coupleId, myUid: me);
    if (_coupleId != coupleId) {
      return;
    }
    if (score != null) {
      _totalScore = score;
    }
    _totalScoreLoading = false;
    notifyListeners();
  }

  void _resetHistory() {
    _history = const <RpsGame>[];
    _historyCursor = null;
    _historyHasMore = false;
    _historyLoading = false;
    _historyLoaded = false;
  }

  @override
  void dispose() {
    _openSub?.cancel();
    _leaveInternal();
    super.dispose();
  }
}
