import 'dart:async';
import 'dart:ui' show AppLifecycleState;

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

  /// `playing`, inside the 5s "oẳn tù tì" beat, nobody has thrown yet.
  countdown,

  /// `playing`, the 5s beat is over, nobody has thrown yet. NOT a timeout
  /// (2026-09-14 no-skip rule): the round waits — the ring switches to its
  /// "open" mode and the hands stay tappable.
  yourTurn,

  /// `playing`, the partner has thrown (CF `moved` stamp), I haven't — at any
  /// time, even inside the 5s beat (the ring keeps counting, see
  /// [RpsGameProvider.isCountingDown]). The screen shows "Người ấy đã ra rồi".
  partnerMovedYourTurn,

  /// `playing`, my hand is in, the partner's isn't — "Nhắc người ấy" is
  /// available once the beat is over ([RpsGameProvider.nudge]).
  chosenWaiting,

  /// `playing`, BOTH hands are in, waiting for the CF (`resolveRpsGame`) to
  /// flip the game to `finished`. Buttons stay locked.
  resolving,

  /// `finished` — `result` is available.
  result,
  expired,
  cancelled,
}

/// How the game screen's presence reacts to an app lifecycle change (Tester
/// RPS-3 / RPS-19 / RPS-20) — see [rpsPresenceActionFor].
enum RpsPresenceAction {
  /// Foreground again: beat right away, then every 3s.
  beat,

  /// Maybe just a glance away (notification shade, control centre, a system
  /// prompt): stop beating now, but only drop my presence if it lasts past a
  /// short grace — so a flicker doesn't cost two writes.
  pauseTransient,

  /// Really gone (backgrounded / closing): stop beating and drop my presence
  /// right away, while the OS still lets the write out.
  pauseAndClear,
}

/// `resumed` → beat · `inactive` → [RpsPresenceAction.pauseTransient] ·
/// `hidden`/`paused`/`detached` → [RpsPresenceAction.pauseAndClear]. Both
/// platforms pass through `inactive` → `hidden` → `paused` on the way to the
/// background within milliseconds, so a real leave is escalated at once.
RpsPresenceAction rpsPresenceActionFor(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      return RpsPresenceAction.beat;
    case AppLifecycleState.inactive:
      return RpsPresenceAction.pauseTransient;
    case AppLifecycleState.hidden:
    case AppLifecycleState.paused:
    case AppLifecycleState.detached:
      return RpsPresenceAction.pauseAndClear;
  }
}

/// The couple's open game from MY side, for the Home card / Profile dot
/// (design addendum 2026-09-14 §B). Declared in the card's priority order —
/// [RpsGameProvider.openState] returns the first that applies.
enum RpsOpenState {
  /// A started round where the partner has thrown and I haven't (rose
  /// outline + dot).
  myTurn,

  /// The partner's `invited` game I haven't joined (rose outline + dot).
  invitedByPartner,

  /// A started round where nobody has thrown yet (both left during the beat).
  unplayed,

  /// A started round where my hand is in and the partner's isn't.
  awaitingPartner,

  /// My own `invited` game, still waiting for the partner to come in.
  myInvitePending,

  /// No live open game.
  none,
}

/// State for rock-paper-scissors (feature rps-game, 2026-09-13).
///
/// Two independent layers:
/// 1. **Couple-wide** — `watchForCouple` (wired in `session_resolver` while a
///    couple is active, `clear` on sign-out/no-couple) streams the single
///    OPEN game so Home/Profile can badge a pending invite without the screen
///    being open.
/// 2. **In-screen** — `enter(gameId)` / `leave()` drive one game: heartbeat
///    (3s), auto-start when both are present, the 100ms ticker during the 5s
///    beat, and auto-expire of a stale invite. The screen only calls
///    `choose`, `nudge`, `rematch`, `cancel`.
///
///    No-skip rule (2026-09-14): a `playing` round ends ONLY when both hands
///    are in (CF `resolveRpsGame`) — there is no deadline, no client-side
///    finish, and a round is never "dead" on the clock. Either player may leave
///    and come back to throw later; the CF stamps `moved.{uid}` so the other
///    side sees "Người ấy đã ra rồi" (+ push/inbox `rps_moved` when away).
///
///    Game screens register as OWNERS (`attach`/`detach`, Tester RPS-13): only
///    the top-most one drives the game; when it goes away the one below gets
///    its game back instead of being left on an idle provider. The top screen
///    also pauses/resumes the heartbeat with the app lifecycle and when a page
///    covers it (Tester RPS-3) so a phone in the pocket isn't "present" —
///    and DELETES my presence stamp when it pauses or goes away (Tester
///    RPS-19/RPS-20), instead of letting the last beat look fresh for 10s
///    (start) / 30s (CF rematch push skip).
///
/// Every write is fail-soft (see [RpsGameService]); the provider never throws
/// into the UI — a refused move simply unlocks the buttons again.
class RpsGameProvider extends ChangeNotifier {
  RpsGameProvider({RpsGameService? service})
    : _service = service ?? RpsGameService();

  final RpsGameService _service;

  /// Ticker cadence while the countdown runs.
  static const Duration _tick = Duration(milliseconds: 100);

  /// Heartbeat round-trips slower than this don't feed the clock offset (the
  /// estimate's error is RTT/2, and a slow ack could straddle the next beat).
  static const Duration _maxClockSampleRtt = Duration(seconds: 2);

  /// A failed all-time score load isn't retried before this (Tester RPS-6 —
  /// the Profile badge used to re-fire three `count()` reads on every build
  /// while offline).
  static const Duration _totalScoreRetryAfter = Duration(seconds: 30);

  /// Spacing between clean-up attempts (expire) on the same stale invite
  /// from the couple-wide stream.
  static const Duration _deadCleanupEvery = Duration(seconds: 60);

  /// How long [choose] WAITS for the server to acknowledge a move. There is
  /// no deadline any more, so this is only about not hanging the caller: past
  /// it an offline write stays queued (and locked in on screen — "lựa chọn
  /// của bạn sẽ được gửi khi có mạng lại") and settles whenever it lands.
  static const Duration _moveNetworkTimeout = Duration(seconds: 10);

  /// An `inactive` pause shorter than this doesn't drop my presence (see
  /// [RpsPresenceAction.pauseTransient]).
  static const Duration _transientPauseGrace = Duration(milliseconds: 1500);

  /// A server-clock hint from the open-games stream (Tester RPS-23) claiming
  /// more than this is discarded: device clocks are NTP-synced to well under
  /// that, so such a sample is far more likely a stamp we received late
  /// (app suspended, listener reconnecting) than real skew.
  static const Duration _maxSnapshotOffset = Duration(minutes: 1);

  // ---- couple-wide ----
  String? _coupleId;
  String? _myUid;
  String? _partnerUid;
  StreamSubscription<RpsOpenGamesSnapshot>? _openSub;

  /// Newest-first open games from the stream — [openGame] picks the first
  /// LIVE one against server time on every read (so an invite that ages past
  /// its TTL drops out without a new snapshot).
  List<RpsGame> _openCandidates = const <RpsGame>[];
  final Map<String, DateTime> _deadCleanupAt = <String, DateTime>{};

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
  String? _loggedFinishedGameId;

  /// Whether the partner had thrown in the previous snapshot of the current
  /// game (null before the first one) — to spot the live "just threw" edge.
  bool? _partnerMovedSeen;

  /// Bumped on every live not-thrown → thrown edge of the partner on the
  /// current game (never for the first snapshot = a reopened round). The
  /// screen rings `lightImpact` once per bump (design addendum A2/A6).
  int _partnerMovedEdges = 0;

  /// "Nhắc người ấy" callable in flight.
  bool _nudgeInFlight = false;

  /// Local cooldown floor (SERVER time) until `lastNudgeAt` echoes back —
  /// set from an `ok` (now + 60s) or a `cooldown` answer (now + retryAfter).
  DateTime? _nudgeLocalUntil;
  bool _actionBusy = false;

  /// A move write is in flight — guards a double tap WITHOUT the global
  /// [isBusy] (Tester RPS-8: an offline pick used to disable "Chơi lại").
  bool _moveInFlight = false;

  /// Game screens currently mounted, bottom → top; the last one drives.
  final List<_RpsOwner> _owners = <_RpsOwner>[];

  /// Heartbeat suspended by the top screen (app in background / a page on
  /// top). While paused the provider also never flips `invited → playing`.
  bool _heartbeatPaused = false;

  /// Delayed presence delete after a transient (`inactive`) pause.
  Timer? _presenceClearTimer;

  /// My presence on the current game was already deleted in this pause.
  bool _presenceCleared = false;

  /// Why the last [invite]/[rematch]/[renewInvite] returned null.
  RpsActionError? _lastActionError;

  // ---- history ----
  List<RpsGame> _history = const <RpsGame>[];
  DocumentSnapshot<Map<String, dynamic>>? _historyCursor;
  bool _historyHasMore = false;
  bool _historyLoading = false;
  bool _historyLoaded = false;

  // ---- all-time score (Profile badge / history scoreboard) ----
  RpsScore? _totalScore;
  bool _totalScoreLoading = false;
  bool _totalScoreDirty = false;
  DateTime? _totalScoreFailedAt;

  /// Finished games already folded into history/score (screen snapshot and
  /// open-games stream may both report the same finish).
  final Set<String> _finishedHandled = <String>{};

  // ---- server clock ----
  /// server − device clock, from the best (lowest-RTT) heartbeat sample. Every
  /// deadline in a game (`startedAt`, `createdAt`) is a SERVER timestamp, so
  /// comparing it with the raw device clock breaks on a phone whose clock is
  /// off: smoke-test 2026-09-13 — an emulator 13s behind sat on "5" for 13s
  /// while the partner's round had already timed out. Kept across games
  /// (a device property); the sample quality resets on each [enter].
  Duration _clockOffset = Duration.zero;
  Duration? _clockSampleRtt;

  /// A heartbeat sample (error ≤ RTT/2) has set [_clockOffset] — from then
  /// on the coarser open-games hints are ignored.
  bool _offsetFromHeartbeat = false;

  /// Best (largest) lower bound of the offset seen on the open-games stream
  /// before any heartbeat sample (Tester RPS-23).
  Duration? _snapshotOffset;

  /// The previous open-games event came from the server (not the cache), so
  /// the next server event's diff shows writes that JUST happened.
  bool _openLive = false;

  // ------------------------------------------------------------------ getters

  bool get isReady => _coupleId != null && _myUid != null;

  /// Best estimate of the server's "now" — use this (not `DateTime.now()`)
  /// against any game timestamp (countdown, grace, invite TTL, nudge cooldown).
  DateTime get serverNow => DateTime.now().add(_clockOffset);

  /// Current server − device clock estimate (diagnostics / tests).
  Duration get clockOffset => _clockOffset;
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
    return _currentGame?.partnerOf(me) ?? openGame?.partnerOf(me);
  }

  /// True when the couple has a second member (session_resolver / Home pass
  /// '' while the couple is still `waiting_partner`). No partner → no game
  /// (Tester RPS-12).
  bool get hasPartner => _partnerUid != null && _partnerUid!.isNotEmpty;

  /// Why the last invite/rematch/renew attempt produced nothing (null after a
  /// success) — lets the screen say "cần có người ấy" vs "kiểm tra mạng".
  RpsActionError? get lastActionError => _lastActionError;

  /// The couple's CURRENT open game — couple-wide. The newest `invited` /
  /// `playing` doc that can still be played: stale invites and rounds past
  /// their grace are skipped (Tester RPS-2), judged against [serverNow].
  RpsGame? get openGame => RpsGame.pickOpen(_openCandidates, now: serverNow);

  /// The open game the screen should switch to right now (partner's rematch /
  /// newer invite — see [RpsGame.shouldFollow]), or null.
  RpsGame? get followTarget {
    final current = _currentGame;
    final open = openGame;
    final me = _myUid;
    if (current == null || open == null || me == null) {
      return null;
    }
    return RpsGame.shouldFollow(current: current, open: open, myUid: me)
        ? open
        : null;
  }

  /// An `invited` game the PARTNER created that I haven't joined yet — drives
  /// the badge on the Home/Profile entry points. A stale (>10') invite no
  /// longer counts: nobody may have flipped it to `expired` yet (only a client
  /// on the game screen does), and badging it just leads to "Lời mời đã hết
  /// hạn" (smoke-test 2026-09-13).
  bool get hasPendingInvite {
    final g = openGame;
    final me = _myUid;
    return g != null &&
        me != null &&
        g.isInvited &&
        !g.isCreatedBy(me) &&
        !g.isInviteStale(now: serverNow);
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

  /// My hand is in: my own move (doc / optimistic) or the CF's `moved` stamp
  /// for me (a reopened round before my move doc streamed in).
  bool get iHaveMoved {
    final me = _myUid;
    final g = _currentGame;
    return hasChosen || (me != null && g != null && g.hasMoved(me));
  }

  /// The partner's hand is in (CF `moved` stamp) — never WHICH hand.
  bool get partnerHasMoved {
    final me = _myUid;
    final g = _currentGame;
    return me != null && g != null && g.isPlaying && g.partnerMoved(me);
  }

  /// Live not-thrown → thrown edges of the partner seen on the current game
  /// (see [_partnerMovedEdges]); 0 for a round opened already in that state.
  int get partnerMovedEdges => _partnerMovedEdges;

  /// True while an action (invite/rematch/cancel/choose) is being written —
  /// lets the screen disable its buttons.
  bool get isBusy => _actionBusy;

  /// Time left of the 5s beat (0..5s). [Duration.zero] once it's over or the
  /// game isn't `playing` — which ends NOTHING (no-skip rule).
  /// A round whose `startedAt` hasn't echoed back yet has just begun → the
  /// full beat.
  Duration get countdownRemaining {
    final g = _currentGame;
    if (g == null || !g.isPlaying) {
      return Duration.zero;
    }
    if (g.startedAt == null) {
      return RpsTiming.countdown;
    }
    return g.countdownRemaining(now: serverNow) ?? Duration.zero;
  }

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

  /// `playing` and still inside the 5s beat (or `startedAt` not echoed yet —
  /// the round has just begun). False = the ring's "open" mode.
  bool get isCountingDown => countdownRemaining > Duration.zero;

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
        final mine = iHaveMoved;
        final theirs = partnerHasMoved;
        if (mine && theirs) {
          return RpsPhase.resolving;
        }
        if (mine) {
          return RpsPhase.chosenWaiting;
        }
        if (theirs) {
          return RpsPhase.partnerMovedYourTurn;
        }
        return isCountingDown ? RpsPhase.countdown : RpsPhase.yourTurn;
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

  /// The hands are tappable while the round is `playing` and my hand isn't
  /// in — with no time limit (no-skip rule), once.
  bool get canChoose {
    final g = _currentGame;
    return g != null && g.isPlaying && !iHaveMoved && !_moveInFlight;
  }

  /// Both hands are in and only the server's verdict is missing — the screen
  /// shows "Đang mở kết quả…" and, past 6s, "Kết nối chậm / Tải lại" (Tester
  /// RPS-22). Since the no-skip rule this is exactly [RpsPhase.resolving]:
  /// a clock running out no longer means anything is being settled.
  bool get isSettling => phase == RpsPhase.resolving;

  /// "Nhắc người ấy" callable in flight.
  bool get isNudging => _nudgeInFlight;

  /// Time left before "Nhắc người ấy" is allowed again: the server's
  /// `lastNudgeAt` (+60s) — shared by both phones and survives a reopen — or,
  /// until that echoes back, the local floor from the callable's answer.
  Duration get nudgeCooldownRemaining {
    final now = serverNow;
    final fromServer =
        _currentGame?.nudgeCooldownRemaining(now: now) ?? Duration.zero;
    final until = _nudgeLocalUntil;
    final local = until == null ? Duration.zero : until.difference(now);
    final best = local > fromServer ? local : fromServer;
    return best.isNegative ? Duration.zero : best;
  }

  /// "Nhắc người ấy" can be tapped right now.
  bool get canNudge =>
      phase == RpsPhase.chosenWaiting &&
      !_nudgeInFlight &&
      nudgeCooldownRemaining == Duration.zero;

  /// The couple's open game from my side (Home card / Profile dot) — the
  /// first matching [RpsOpenState] in priority order.
  RpsOpenState get openState {
    final g = openGame;
    final me = _myUid;
    if (g == null || me == null) {
      return RpsOpenState.none;
    }
    if (g.isPlaying) {
      final mine = g.hasMoved(me) || (g.id == _currentGameId && hasChosen);
      final theirs = g.partnerMoved(me);
      if (theirs && !mine) {
        return RpsOpenState.myTurn;
      }
      if (mine && !theirs) {
        return RpsOpenState.awaitingPartner;
      }
      if (!mine && !theirs) {
        return RpsOpenState.unplayed;
      }
      // Both in → resolving; the CF flips it to `finished` within seconds.
      return RpsOpenState.awaitingPartner;
    }
    if (hasPendingInvite) {
      return RpsOpenState.invitedByPartner;
    }
    if (g.isInvited && g.isCreatedBy(me) && !g.isInviteStale(now: serverNow)) {
      return RpsOpenState.myInvitePending;
    }
    return RpsOpenState.none;
  }

  /// A started round is waiting on MY hand (the partner has thrown) — the
  /// Profile / Home dot, alongside [hasPendingInvite].
  bool get isMyTurn => openState == RpsOpenState.myTurn;

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

  /// A load failed less than 30s ago — callers shouldn't retry yet.
  bool get isTotalScoreBackingOff {
    final failed = _totalScoreFailedAt;
    return failed != null &&
        DateTime.now().difference(failed) < _totalScoreRetryAfter;
  }

  /// Whether a screen may lazily kick [loadTotalScore] from its build: not
  /// loaded, not loading, not in the post-failure backoff.
  bool get shouldAutoLoadTotalScore =>
      isReady &&
      _totalScore == null &&
      !_totalScoreLoading &&
      !isTotalScoreBackingOff;

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
    final partner = partnerUid.trim().isEmpty ? null : partnerUid.trim();
    final partnerChanged = partner != _partnerUid;
    _partnerUid = partner;
    if (samePair && _openSub != null) {
      // Home re-arms this on every build: the partner joining while the app
      // stays open lands here (Tester RPS-12 — invite is gated on it).
      if (partnerChanged) {
        notifyListeners();
      }
      return;
    }
    if (!samePair) {
      _leaveInternal();
      _resetHistory();
      _resetTotalScore();
      _openCandidates = const <RpsGame>[];
      _deadCleanupAt.clear();
      _finishedHandled.clear();
    }
    _coupleId = coupleId;
    _myUid = myUid;
    _openSub?.cancel();
    _openLive = false;
    _openSub = _service
        .watchOpenGameSnapshots(coupleId)
        .listen(_onOpenGames, onError: (_) {});
    notifyListeners();
  }

  void _onOpenGames(RpsOpenGamesSnapshot snapshot) {
    final receivedAt = DateTime.now();
    final coupleId = _coupleId;
    final previous = _openCandidates;
    final games = snapshot.games;
    // RPS-23: estimate the server clock before any game is entered, from
    // stamps written just now (diff of two consecutive live events).
    if (_openLive && !snapshot.fromCache) {
      _sampleClockFromStamps(
        rpsFreshServerStamps(
          previous: previous,
          current: games,
          windowLimit: rpsOpenGamesWindow,
        ),
        receivedAt,
      );
    }
    _openLive = !snapshot.fromCache;
    _openCandidates = games;
    if (coupleId != null) {
      // A round that was `playing` and left the open set can only have
      // FINISHED (no other transition out of `playing`) — fold it into the
      // score/history even when no game screen watched it (Tester RPS-18).
      final stillOpen = games.map((g) => g.id).toSet();
      for (final gone in previous) {
        if (gone.isPlaying &&
            !stillOpen.contains(gone.id) &&
            gone.id != _currentGameId) {
          unawaited(_recordFinishedOffScreen(coupleId, gone.id));
        }
      }
      _cleanUpDeadOpenGames(coupleId, games);
    }
    notifyListeners();
  }

  /// Best-effort server clean-up of dead open docs (stale invite → `expired`)
  /// so they stop shadowing the couple's real state. Rate-limited per game;
  /// the on-screen game is left to its own snapshot handler. A `playing`
  /// round is never dead (no-skip rule) and is never touched here.
  void _cleanUpDeadOpenGames(String coupleId, List<RpsGame> games) {
    final now = serverNow;
    final wall = DateTime.now();
    for (final game in games) {
      if (game.id == _currentGameId || !game.isDeadOpen(now: now)) {
        continue;
      }
      final last = _deadCleanupAt[game.id];
      if (last != null && wall.difference(last) < _deadCleanupEvery) {
        continue;
      }
      _deadCleanupAt[game.id] = wall;
      unawaited(
        _service.expireIfStale(coupleId: coupleId, gameId: game.id, now: now),
      );
    }
  }

  Future<void> _recordFinishedOffScreen(String coupleId, String gameId) async {
    final me = _myUid;
    if (me == null || _finishedHandled.contains(gameId)) {
      return;
    }
    final game = await _service.fetchGame(coupleId, gameId);
    if (game == null || !game.isFinished || _coupleId != coupleId) {
      return;
    }
    _recordFinished(game, me);
    notifyListeners();
  }

  /// Stop everything (sign-out / no-couple).
  void clear() {
    _openSub?.cancel();
    _openSub = null;
    _openLive = false;
    _openCandidates = const <RpsGame>[];
    _deadCleanupAt.clear();
    _finishedHandled.clear();
    _coupleId = null;
    _myUid = null;
    _partnerUid = null;
    _lastActionError = null;
    _leaveInternal();
    _resetHistory();
    _resetTotalScore();
    notifyListeners();
  }

  // ---------------------------------------------------------------- actions

  /// "Oẳn tù tì" tapped: joins the couple's open game if there is one (one
  /// open game at a time — overview §4.5), otherwise creates a fresh invite
  /// (the CF pushes the partner). Returns the gameId entered, or null when
  /// nothing could be written ([lastActionError] says why).
  ///
  /// Only a LIVE open game is joined ([openGame] skips stale invites —
  /// Tester RPS-2; a `playing` round of any age IS live and is re-entered,
  /// no-skip rule); dead invites are flipped to `expired` before the new one
  /// is created so they stop shadowing it.
  Future<String?> invite() async {
    final coupleId = _coupleId;
    final me = _myUid;
    if (coupleId == null || me == null || _actionBusy) {
      return null;
    }
    _lastActionError = null;
    if (!hasPartner) {
      _lastActionError = RpsActionError.needCouple;
      notifyListeners();
      return null;
    }
    final open = openGame;
    if (open != null) {
      enter(open.id);
      return open.id;
    }
    _setBusy(true);
    try {
      await _expireDeadInvites(coupleId);
      final id = await _service.createGame(coupleId: coupleId, uid: me);
      if (id == null) {
        _lastActionError = RpsActionError.failed;
        return null;
      }
      _lastActionError = null;
      AnalyticsService.instance.logRpsInviteSent();
      enter(id);
      return id;
    } finally {
      _setBusy(false);
    }
  }

  /// Flips every stale invite in the open set to `expired` (bounded wait —
  /// a slow clean-up must not hold the new invite hostage).
  Future<void> _expireDeadInvites(String coupleId) async {
    final now = serverNow;
    final pending = <Future<bool>>[];
    for (final game in _openCandidates) {
      if (!game.isDeadOpen(now: now) || game.id == _currentGameId) {
        continue;
      }
      _deadCleanupAt[game.id] = DateTime.now();
      pending.add(
        _service.expireIfStale(coupleId: coupleId, gameId: game.id, now: now),
      );
    }
    if (pending.isEmpty) {
      return;
    }
    try {
      await Future.wait(pending).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Best-effort; the stream skips them either way.
    }
  }

  /// "Chơi lại" from the result screen: a new invite linked to this game so
  /// the CF can skip the push while the partner is still on the same screen.
  ///
  /// Tester RPS-1: the rematch lives at the deterministic id
  /// [rpsRematchGameId] (get-or-create in a transaction), so both phones
  /// tapping "Chơi lại" at the same moment land in ONE game instead of each
  /// waiting in its own. If the partner's rematch / a newer invite is already
  /// the open game, just follow it.
  Future<String?> rematch() async {
    final coupleId = _coupleId;
    final me = _myUid;
    final previous = _currentGame;
    if (coupleId == null || me == null || _actionBusy) {
      return null;
    }
    _lastActionError = null;
    if (!hasPartner) {
      _lastActionError = RpsActionError.needCouple;
      notifyListeners();
      return null;
    }
    if (previous == null) {
      return invite();
    }
    final target = followTarget;
    if (target != null) {
      await followOpenGame(target);
      return target.id;
    }
    _setBusy(true);
    try {
      final outcome = await _service.createGameWithId(
        coupleId: coupleId,
        uid: me,
        gameId: rpsRematchGameId(previous.id),
        rematchOf: previous.id,
      );
      if (outcome == null) {
        _lastActionError = RpsActionError.failed;
        return null;
      }
      final existing = outcome.existing;
      if (!outcome.created &&
          existing != null &&
          (!existing.isOpen || existing.isDeadOpen(now: serverNow))) {
        // That round's rematch was already played (re-opened an old result
        // from the inbox) or died unanswered → a fresh game, still linked.
        final id = await _service.createGame(
          coupleId: coupleId,
          uid: me,
          rematchOf: previous.id,
        );
        if (id == null) {
          _lastActionError = RpsActionError.failed;
          return null;
        }
        _lastActionError = null;
        AnalyticsService.instance.logRpsInviteSent(rematch: true);
        enter(id);
        return id;
      }
      _lastActionError = null;
      if (outcome.created) {
        AnalyticsService.instance.logRpsInviteSent(rematch: true);
      }
      enter(outcome.id);
      return outcome.id;
    } finally {
      _setBusy(false);
    }
  }

  /// Switches the screen to [target] (a [followTarget]). Leaving my OWN
  /// unanswered invite for the partner's game withdraws mine, so it doesn't
  /// linger as a second open game.
  Future<void> followOpenGame(RpsGame target) async {
    final coupleId = _coupleId;
    final me = _myUid;
    final current = _currentGame;
    if (coupleId == null || me == null || target.id == _currentGameId) {
      return;
    }
    if (current != null && current.isInvited && current.isCreatedBy(me)) {
      unawaited(
        _service.cancel(coupleId: coupleId, gameId: current.id, uid: me),
      );
    }
    enter(target.id);
  }

  /// "Nhắc lại" on the waiting screen (design D7): withdraw the current
  /// invite and create a fresh one so `notifyRpsInvite` pushes the partner
  /// again. Bypasses [invite]'s "join the open game" shortcut on purpose —
  /// the open-game stream may still echo the game we just cancelled. Returns
  /// the new gameId, or null when nothing was written.
  ///
  /// Tester RPS-9: a new invite is created ONLY when the cancel went through.
  /// If it didn't (the partner joined a split second ago → the game is
  /// `playing`; or offline), stay on the current game instead of abandoning
  /// the partner in it.
  Future<String?> renewInvite() async {
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentGameId;
    if (coupleId == null || me == null || gameId == null || _actionBusy) {
      return null;
    }
    _lastActionError = null;
    if (!hasPartner) {
      _lastActionError = RpsActionError.needCouple;
      notifyListeners();
      return null;
    }
    _setBusy(true);
    try {
      final cancelled =
          canCancel &&
          await _service.cancel(coupleId: coupleId, gameId: gameId, uid: me);
      if (!cancelled) {
        enter(gameId); // no-op when still attached — just never abandon it
        return null;
      }
      final id = await _service.createGame(coupleId: coupleId, uid: me);
      if (id == null) {
        _lastActionError = RpsActionError.failed;
        return null;
      }
      _lastActionError = null;
      AnalyticsService.instance.logRpsInviteSent();
      enter(id);
      return id;
    } finally {
      _setBusy(false);
    }
  }

  /// Lock in my hand — any time while the round is `playing` (no-skip rule,
  /// no deadline). Returns false when refused (not playing / already thrown)
  /// — the optimistic lock is rolled back in that case.
  ///
  /// Offline (Tester RPS-8 + no-skip rule): the caller waits at most
  /// [_moveNetworkTimeout]; after that the write stays QUEUED and my hand
  /// stays locked in (it will count whenever the network returns). Only if
  /// that queued write is finally refused is the lock rolled back. It never
  /// holds the global [isBusy], so an offline pick can't disable "Chơi lại".
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
    _moveInFlight = true;
    notifyListeners();
    final write = _service.submitMove(
      coupleId: coupleId,
      gameId: gameId,
      uid: me,
      choice: choice,
    );
    bool? ok;
    try {
      ok = await write.timeout(_moveNetworkTimeout);
    } on TimeoutException {
      ok = null; // still queued — see below
    }
    if (_disposed) {
      return ok ?? true;
    }
    if (_currentGameId == gameId) {
      _moveInFlight = false;
      if (ok == false) {
        _pendingChoice = null;
      }
    }
    if (ok == null) {
      // Offline: keep the lock; roll back only if the queued write is refused
      // once it finally reaches the server.
      unawaited(
        write.then((sent) {
          if (!sent &&
              !_disposed &&
              _currentGameId == gameId &&
              _myMove == null &&
              _pendingChoice == choice) {
            _pendingChoice = null;
            notifyListeners();
          }
        }),
      );
    }
    notifyListeners();
    return ok ?? true;
  }

  /// "Nhắc người ấy" (design addendum A3): my hand is in, the partner's isn't
  /// → the `nudgeRpsPlayer` callable pushes + inboxes `rps_moved` to them.
  /// The server enforces the 60s cooldown from `lastNudgeAt`; a `sent` /
  /// `cooldown` answer also sets a local floor so the button counts down
  /// before that field echoes back. Never throws.
  Future<RpsNudgeResult> nudge() async {
    final coupleId = _coupleId;
    final gameId = _currentGameId;
    if (coupleId == null ||
        gameId == null ||
        _nudgeInFlight ||
        phase != RpsPhase.chosenWaiting) {
      return const RpsNudgeResult(RpsNudgeStatus.notPlaying);
    }
    final left = nudgeCooldownRemaining;
    if (left > Duration.zero) {
      return RpsNudgeResult(RpsNudgeStatus.cooldown, retryAfter: left);
    }
    _nudgeInFlight = true;
    notifyListeners();
    final result = await _service.nudgePartner(
      coupleId: coupleId,
      gameId: gameId,
    );
    if (_disposed) {
      return result;
    }
    _nudgeInFlight = false;
    if (_currentGameId == gameId) {
      switch (result.status) {
        case RpsNudgeStatus.sent:
          _nudgeLocalUntil = serverNow.add(RpsTiming.nudgeCooldown);
        case RpsNudgeStatus.cooldown:
          _nudgeLocalUntil = serverNow.add(
            result.retryAfter ?? RpsTiming.nudgeCooldown,
          );
        case RpsNudgeStatus.partnerMoved:
        case RpsNudgeStatus.resolved:
        case RpsNudgeStatus.notPlaying:
        case RpsNudgeStatus.notMoved:
        case RpsNudgeStatus.failed:
          break;
      }
    }
    notifyListeners();
    return result;
  }

  /// "Tải lại" on the resolving screen (Tester RPS-25): both hands are in but
  /// no verdict came. Asks `nudgeRpsPlayer`, which closes a round whose
  /// resolve trigger failed (answer `resolved`). It can't push the partner
  /// from here: [RpsPhase.resolving] means their hand is in (server stamp),
  /// so the callable only ever answers `resolved` / `partner_moved` /
  /// `not_playing` / `not_moved`. Never throws; the game stream brings the
  /// result.
  Future<RpsNudgeStatus> resolveStuck() async {
    final coupleId = _coupleId;
    final gameId = _currentGameId;
    if (coupleId == null || gameId == null || phase != RpsPhase.resolving) {
      return RpsNudgeStatus.notPlaying;
    }
    final result = await _service.nudgePartner(
      coupleId: coupleId,
      gameId: gameId,
    );
    return result.status;
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

  /// A game screen mounted (Tester RPS-13): it becomes the top owner and the
  /// one that drives [enter]/[leave]/heartbeat. Call from initState, before
  /// [enter]/[invite].
  void attach(Object owner) {
    _owners.removeWhere((o) => identical(o.key, owner));
    _owners.add(_RpsOwner(owner));
    // A freshly pushed screen is visible by definition.
    _heartbeatPaused = false;
  }

  /// The screen [owner] is going away. If it was driving, the game is left
  /// and the screen underneath (if any) gets ITS game back — instead of the
  /// old behaviour where a second game screen's `leave()` left the first one
  /// stuck on a skeleton.
  void detach(Object owner) {
    final index = _owners.indexWhere((o) => identical(o.key, owner));
    if (index < 0) {
      return;
    }
    final wasTop = index == _owners.length - 1;
    _owners.removeAt(index);
    if (!wasTop) {
      return;
    }
    // Off the game screen → my stamp must not stay "fresh" (RPS-19/RPS-20).
    // Issued BEFORE a screen underneath re-enters and beats, and writes from
    // one device apply in order, so that beat still wins.
    _leaveInternal(clearPresence: true);
    // Called from `State.dispose`: the widget tree is locked there, so a
    // synchronous notifyListeners() throws "markNeedsBuild() called when
    // widget tree was locked" (seen on the emulator 2026-09-14 — the old
    // leave()-in-dispose had the same problem). Settle on the next microtask,
    // after the frame has finalized.
    scheduleMicrotask(() {
      if (_disposed) {
        return;
      }
      final below = _owners.isEmpty ? null : _owners.last.gameId;
      if (below != null && _currentGameId == null) {
        enter(below);
      } else {
        notifyListeners();
      }
    });
  }

  bool _isTopOwner(Object? owner) =>
      owner == null ||
      (_owners.isNotEmpty && identical(_owners.last.key, owner));

  /// Attach to [gameId]: stream it + my move, start the heartbeat. Call from
  /// the game screen's initState (or right after [invite]/[rematch]).
  /// [owner] = the calling screen (default: the top one); a screen that isn't
  /// on top only records its game and never steals the live one.
  void enter(String gameId, {Object? owner}) {
    final coupleId = _coupleId;
    final me = _myUid;
    if (coupleId == null || me == null || gameId.trim().isEmpty) {
      return;
    }
    if (_owners.isNotEmpty) {
      final record = owner == null
          ? _owners.last
          : _owners.firstWhere(
              (o) => identical(o.key, owner),
              orElse: () => _owners.last,
            );
      record.gameId = gameId;
      if (!identical(record, _owners.last)) {
        return;
      }
    }
    if (_currentGameId == gameId && _gameSub != null) {
      return;
    }
    // Switching games (rematch / follow / renew): I'm no longer on the old
    // one — its presence goes too, so e.g. the CF's rematch check on it
    // doesn't see me "still watching" (RPS-19). EXCEPT when the old game is
    // FINISHED (result screen → its rematch / the partner's new game, still on
    // the game screen — Tester RPS-24): deleting that stamp is exactly what
    // made `notifyRpsInvite` push + inbox me a rematch I was already looking
    // at. A finished game's stamp gates nothing else (its result push is
    // already out) and just ages out; really leaving the screen / going to
    // the background still clears the CURRENT game (detach / pauseHeartbeat).
    final old = _currentGame;
    final oldFinished =
        old != null && old.id == _currentGameId && old.isFinished;
    _leaveInternal(clearPresence: !oldFinished);
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
    // CF knows I'm still looking and doesn't push me the result. Each beat is
    // also a clock probe (fresh estimate per game — see [_clockOffset]).
    _clockSampleRtt = null;
    if (!_heartbeatPaused) {
      _startHeartbeat(coupleId, gameId, me);
    }
  }

  void _startHeartbeat(String coupleId, String gameId, String me) {
    _heartbeatTimer?.cancel();
    _presenceClearTimer?.cancel();
    _presenceClearTimer = null;
    _presenceCleared = false;
    _beat(coupleId, gameId, me);
    _heartbeatTimer = Timer.periodic(RpsTiming.heartbeat, (_) {
      _beat(coupleId, gameId, me);
    });
  }

  /// Stop announcing presence (Tester RPS-3): the app went to the background
  /// / the screen got covered. No-op unless [owner] is the driving screen.
  ///
  /// Tester RPS-19/RPS-20: just stopping the beats left my last stamp
  /// "fresh" for up to 10s (the partner could start a round I can't see —
  /// I then lost it as "Bỏ lượt") and 30s for the CF's rematch check (the
  /// partner's "Chơi lại" skipped my push + inbox). So my `presence` key is
  /// deleted as well: right away by default, or — [transient] (`inactive`,
  /// maybe just the notification shade) — only if the pause outlives a short
  /// grace. It goes regardless of the round's state: a locked move is already
  /// written, presence only gates the start and the pushes. Dialogs / sheets
  /// never get here (the route observer only sees pages).
  void pauseHeartbeat({Object? owner, bool transient = false}) {
    if (!_isTopOwner(owner)) {
      return;
    }
    if (!_heartbeatPaused) {
      _heartbeatPaused = true;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    }
    if (_presenceCleared) {
      return;
    }
    if (transient) {
      _presenceClearTimer ??= Timer(_transientPauseGrace, () {
        _presenceClearTimer = null;
        if (_heartbeatPaused && !_disposed) {
          _clearMyPresence();
        }
      });
      return;
    }
    // `inactive` escalating to `hidden`/`paused`: don't wait out the grace.
    _clearMyPresence();
  }

  /// Back on the screen: beat immediately, then every 3s again (a pending
  /// transient clear is dropped — nothing was deleted yet).
  void resumeHeartbeat({Object? owner}) {
    if (!_isTopOwner(owner)) {
      return;
    }
    _presenceClearTimer?.cancel();
    _presenceClearTimer = null;
    final wasPaused = _heartbeatPaused;
    _heartbeatPaused = false;
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentGameId;
    if (coupleId == null || me == null || gameId == null) {
      return;
    }
    if (wasPaused || _heartbeatTimer == null) {
      _startHeartbeat(coupleId, gameId, me);
    }
  }

  /// Deletes my stamp on the current game, once per pause. Guarded on the
  /// ids: after [clear] (sign-out / no couple) there is nothing to touch.
  void _clearMyPresence() {
    _presenceClearTimer?.cancel();
    _presenceClearTimer = null;
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentGameId;
    if (coupleId == null || me == null || gameId == null) {
      return;
    }
    _presenceCleared = true;
    unawaited(_service.clearPresence(coupleId, gameId, me));
  }

  /// True while the driving screen has paused the heartbeat.
  bool get isHeartbeatPaused => _heartbeatPaused;

  void _beat(String coupleId, String gameId, String me) {
    unawaited(_service.heartbeat(coupleId, gameId, me).then(_onClockSample));
  }

  /// Keeps the lowest-RTT sample (NTP-style): its offset error is ≤ RTT/2.
  void _onClockSample(RpsClockSample? sample) {
    if (sample == null) {
      return;
    }
    final rtt = sample.rtt;
    if (rtt.isNegative || rtt > _maxClockSampleRtt) {
      return;
    }
    final best = _clockSampleRtt;
    if (best != null && rtt > best) {
      return;
    }
    _clockSampleRtt = rtt;
    _offsetFromHeartbeat = true;
    final previous = _clockOffset;
    _clockOffset = sample.offset;
    if ((_clockOffset - previous).abs() > const Duration(milliseconds: 250)) {
      debugPrint(
        'RpsGameProvider: server clock offset ${_clockOffset.inMilliseconds}ms '
        '(rtt ${rtt.inMilliseconds}ms)',
      );
      notifyListeners();
    }
  }

  /// Tester RPS-23: the offset used to stay 0 until the first heartbeat, i.e.
  /// until a game screen was open — the Home card and the dead-game clean-up
  /// judged invite TTL / round grace on the raw device clock. [stamps] were
  /// committed just before [receivedAt] ([rpsFreshServerStamps]), so each
  /// `stamp − receivedAt` UNDER-estimates the true offset by the delivery
  /// latency; the maximum seen is the best estimate. Used only until a
  /// heartbeat sample exists; no sample → old behaviour (device clock).
  void _sampleClockFromStamps(List<DateTime> stamps, DateTime receivedAt) {
    if (stamps.isEmpty || _offsetFromHeartbeat) {
      return;
    }
    var newest = stamps.first;
    for (final t in stamps) {
      if (t.isAfter(newest)) {
        newest = t;
      }
    }
    final sample = newest.difference(receivedAt);
    if (sample.abs() > _maxSnapshotOffset) {
      return;
    }
    final best = _snapshotOffset;
    if (best != null && sample <= best) {
      return;
    }
    _snapshotOffset = sample;
    _clockOffset = sample;
  }

  /// Detach from the current game (keeps the owner records — see [detach]
  /// for a screen going away). The couple-wide open game watch keeps running.
  void leave() {
    _leaveInternal();
    notifyListeners();
  }

  void _leaveInternal({bool clearPresence = false}) {
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentGameId;
    if (clearPresence &&
        !_presenceCleared &&
        coupleId != null &&
        me != null &&
        gameId != null) {
      unawaited(_service.clearPresence(coupleId, gameId, me));
    }
    _presenceClearTimer?.cancel();
    _presenceClearTimer = null;
    _presenceCleared = false;
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
    _moveInFlight = false;
    _startInFlight = false;
    _expireInFlight = false;
    _partnerMovedSeen = null;
    _partnerMovedEdges = 0;
    _nudgeInFlight = false;
    _nudgeLocalUntil = null;
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

    // "Người ấy vừa ra" edge — only between two snapshots of this game, so a
    // round reopened already in that state (tap on `rps_moved`) doesn't ring.
    final partnerMoved = game.isPlaying && game.partnerMoved(me);
    if (_partnerMovedSeen == false && partnerMoved) {
      _partnerMovedEdges++;
    }
    _partnerMovedSeen = partnerMoved;

    switch (game.status) {
      case RpsGameStatus.invited:
        _stopTicker();
        if (game.isInviteStale(now: serverNow)) {
          _maybeExpire(coupleId, gameId);
        } else {
          _maybeStart(coupleId, gameId, me, game);
        }
      case RpsGameStatus.playing:
        // The ticker only drives the 5s beat; afterwards nothing is timed —
        // the round waits for both hands (no-skip rule).
        if (isCountingDown) {
          _startTicker();
        } else {
          _stopTicker();
        }
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
    // Backgrounded / covered: never start a round I can't see (RPS-3).
    if (_startInFlight || _heartbeatPaused) {
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
          .expireIfStale(coupleId: coupleId, gameId: gameId, now: serverNow)
          .whenComplete(() => _expireInFlight = false),
    );
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
    _recordFinished(game, me);
  }

  /// Folds a finished game into the loaded history + the all-time score, ONCE
  /// per game (the screen snapshot and the open-games stream may both report
  /// it). The score is re-read from the server rather than bumped locally
  /// (Tester RPS-18): the old local +1 only happened when the history page was
  /// loaded, and could double-count against an in-flight reload.
  void _recordFinished(RpsGame game, String me) {
    if (!_finishedHandled.add(game.id)) {
      return;
    }
    if (_historyLoaded && !_history.any((g) => g.id == game.id)) {
      _history = <RpsGame>[game, ..._history];
    }
    if (_totalScore != null) {
      unawaited(_fetchTotalScore());
    }
  }

  void _startTicker() {
    if (_tickTimer != null) {
      return;
    }
    _tickTimer = Timer.periodic(_tick, (_) {
      final game = _currentGame;
      if (game == null || !game.isPlaying || !isCountingDown) {
        // The beat is over (or the round moved on): one last notify flips
        // `countdown` → `yourTurn`, then nothing is timed any more.
        _stopTicker();
        notifyListeners();
        return;
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
  /// call on every build — no-op while in flight, already loaded, or within
  /// 30s of a failed attempt (Tester RPS-6). [force] (pull-to-refresh) skips
  /// the cache and the backoff.
  Future<void> loadTotalScore({bool force = false}) async {
    if (!force && (_totalScore != null || isTotalScoreBackingOff)) {
      return;
    }
    await _fetchTotalScore();
  }

  Future<void> _fetchTotalScore() async {
    final coupleId = _coupleId;
    final me = _myUid;
    if (coupleId == null || me == null) {
      return;
    }
    if (_totalScoreLoading) {
      // A game finished mid-load: read again once this one lands.
      _totalScoreDirty = true;
      return;
    }
    _totalScoreLoading = true;
    _totalScoreDirty = false;
    notifyListeners();
    final score = await _service.countScore(coupleId: coupleId, myUid: me);
    if (_coupleId != coupleId) {
      return; // couple changed mid-flight (state already reset)
    }
    _totalScoreLoading = false;
    if (score != null) {
      _totalScore = score;
      _totalScoreFailedAt = null;
    } else {
      _totalScoreFailedAt = DateTime.now();
    }
    notifyListeners();
    if (_totalScoreDirty && score != null) {
      _totalScoreDirty = false;
      unawaited(_fetchTotalScore());
    }
  }

  void _resetTotalScore() {
    _totalScore = null;
    _totalScoreLoading = false;
    _totalScoreDirty = false;
    _totalScoreFailedAt = null;
  }

  void _resetHistory() {
    _history = const <RpsGame>[];
    _historyCursor = null;
    _historyHasMore = false;
    _historyLoading = false;
    _historyLoaded = false;
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _openSub?.cancel();
    _leaveInternal();
    super.dispose();
  }
}

/// Why an invite / rematch / renew produced no game.
enum RpsActionError {
  /// The couple has no second member yet (`waiting_partner`).
  needCouple,

  /// Nothing could be written (offline / rule denied / no Firebase).
  failed,
}

/// One mounted game screen and the game it last drove.
class _RpsOwner {
  _RpsOwner(this.key);

  final Object key;
  String? gameId;
}
