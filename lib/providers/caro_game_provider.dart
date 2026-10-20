import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/caro_game.dart';
import '../services/caro_game_service.dart';

/// State of the couple's caro games (feature caro-game) for Home, Profile,
/// the widget and the game / history screens.
///
/// Couple-wide (wired in SessionResolver while the couple is active):
/// `caroState/main` → score + the open game, streamed so Home knows whose turn
/// it is. Per screen: [enter] streams that game and beats my presence every
/// 20s; [pauseHeartbeat] / [resumeHeartbeat] follow the app lifecycle,
/// [leave] clears my presence. Every change is a `caroAction` call — the
/// board here only ever shows what the server wrote, plus [pendingCell] (my
/// stone, drawn faded until the server's doc has it — D12).
class CaroGameProvider extends ChangeNotifier {
  CaroGameProvider({CaroGameService? service})
    : _service = service ?? CaroGameService();

  final CaroGameService _service;

  /// The square the quick "Rủ … chơi" uses (D19/U1: the centre, 8-8).
  static final int centerCell = CaroBoard.indexOf(7, 7);

  static const int historyPageSize = 30;

  String? _coupleId;
  String? _myUid;
  String? _partnerUid;

  StreamSubscription<CaroState>? _stateSub;
  CaroState _state = CaroState.empty;
  bool _stateLoaded = false;

  // Couple-wide open game (Home/Profile/widget).
  String? _openId;
  StreamSubscription<CaroGame?>? _openSub;
  CaroGame? _openGame;

  /// Newest finished game (Home "vừa kết thúc" line), refreshed when the
  /// score changes.
  CaroGame? _lastFinished;
  int _lastFinishedFor = -1;

  // Game screen.
  String? _currentId;
  StreamSubscription<CaroGame?>? _currentSub;
  CaroGame? _current;
  bool _currentLoaded = false;
  Timer? _heartbeatTimer;
  bool _heartbeatPaused = false;

  int? _pendingCell;
  bool _busy = false;

  // History.
  List<CaroGame> _history = const <CaroGame>[];
  DocumentSnapshot<Map<String, dynamic>>? _historyCursor;
  bool _historyHasMore = false;
  bool _historyLoading = false;
  bool _historyLoaded = false;
  bool _historyFailed = false;

  bool _disposed = false;

  // ------------------------------------------------------------------ getters

  bool get isReady => _coupleId != null && _myUid != null;
  bool get isUsingFirebase => _service.isUsingFirebase;
  String? get myUid => _myUid;
  String? get partnerUid => _partnerUid;

  /// Caro needs both people (D14): no partner → no entry point at all.
  bool get hasPartner => _partnerUid != null;

  bool get isStateLoaded => _stateLoaded;
  CaroState get state => _state;
  int get myWins => _state.winsOf(_myUid);
  int get partnerWins => _state.winsOf(_partnerUid);
  int get draws => _state.draws;

  /// The couple's open game, only while it is `playing` between the two
  /// current members (D20).
  CaroGame? get openGame {
    final game = _openGame;
    if (game == null || !game.isPlaying || !_isOurs(game)) {
      return null;
    }
    return game;
  }

  /// My move in the open game (Home dot, Profile badge, widget).
  bool get isMyTurn {
    final me = _myUid;
    return me != null && (openGame?.isMyTurn(me) ?? false);
  }

  /// Newest finished game of the current pair (null when none / not loaded).
  CaroGame? get lastFinished => _lastFinished;

  /// What Home's caro line is about: the open game, else the last finished.
  CaroGame? get recentGame => openGame ?? _lastFinished;

  String? get currentGameId => _currentId;
  CaroGame? get currentGame => _current;
  bool get isCurrentLoaded => _currentLoaded;
  bool get isHeartbeatPaused => _heartbeatPaused;

  /// My stone waiting for the server (draw faded). Null otherwise.
  int? get pendingCell => _pendingCell;

  /// A `caroAction` call is in flight (buttons disabled).
  bool get isBusy => _busy;

  List<CaroGame> get history => _history;
  bool get hasMoreHistory => _historyHasMore;
  bool get isLoadingHistory => _historyLoading;
  bool get isHistoryLoaded => _historyLoaded;

  /// The last page request failed ("Chưa tải thêm được ván cũ.").
  bool get historyFailed => _historyFailed;

  bool _isOurs(CaroGame game) {
    final me = _myUid;
    final partner = _partnerUid;
    return me != null &&
        partner != null &&
        game.playersAreMembers(<String>[me, partner]);
  }

  // ------------------------------------------------------------- couple-wide

  /// Follow the couple's caro state. Idempotent for the same (couple, uid);
  /// HomeScreen may re-arm it with the live couple so a partner joining
  /// mid-session shows the entry point. [partnerUid] is '' while waiting.
  void watchForCouple(String coupleId, String myUid, String partnerUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }
    final partner = partnerUid.trim().isEmpty ? null : partnerUid.trim();
    final samePair = _coupleId == coupleId && _myUid == myUid;
    if (samePair && _stateSub != null) {
      if (partner != _partnerUid) {
        _partnerUid = partner;
        _resetHistory();
        _lastFinishedFor = -1;
        _refreshLastFinished();
        notifyListeners();
      }
      return;
    }
    clear(notify: false);
    _coupleId = coupleId;
    _myUid = myUid;
    _partnerUid = partner;
    _stateSub = _service.watchState(coupleId).listen(_onState, onError: (_) {});
    notifyListeners();
  }

  void _onState(CaroState next) {
    _state = next;
    _stateLoaded = true;
    _followOpen(next.openGameId);
    _refreshLastFinished();
    notifyListeners();
  }

  void _followOpen(String? gameId) {
    if (gameId == _openId) {
      return;
    }
    _openSub?.cancel();
    _openSub = null;
    _openId = gameId;
    _openGame = null;
    final coupleId = _coupleId;
    if (gameId == null || coupleId == null) {
      return;
    }
    _openSub = _service.watchGame(coupleId, gameId).listen((game) {
      _openGame = game;
      notifyListeners();
    }, onError: (_) {});
  }

  /// Re-reads the newest finished game when the number of counted games
  /// changed (a finish bumps wins or draws).
  void _refreshLastFinished() {
    final coupleId = _coupleId;
    final me = _myUid;
    final partner = _partnerUid;
    if (coupleId == null || me == null || partner == null) {
      return;
    }
    final total = _state.totalFor(me, partner);
    if (total == _lastFinishedFor) {
      return;
    }
    _lastFinishedFor = total;
    if (total == 0) {
      _lastFinished = null;
      return;
    }
    unawaited(
      _service.fetchHistoryPage(coupleId: coupleId, limit: 1).then((page) {
        if (_disposed || _coupleId != coupleId) {
          return;
        }
        final ours = page.items.where(_isOurs);
        _lastFinished = ours.isEmpty ? null : ours.first;
        if (page.failed) {
          _lastFinishedFor = -1; // retry on the next state event
        }
        notifyListeners();
      }),
    );
  }

  /// Stop everything (sign-out / no couple).
  void clear({bool notify = true}) {
    _leaveInternal(clearPresence: true);
    _stateSub?.cancel();
    _stateSub = null;
    _openSub?.cancel();
    _openSub = null;
    _openId = null;
    _openGame = null;
    _state = CaroState.empty;
    _stateLoaded = false;
    _lastFinished = null;
    _lastFinishedFor = -1;
    _coupleId = null;
    _myUid = null;
    _partnerUid = null;
    _resetHistory();
    if (notify) {
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ enter/leave

  /// The game screen opened [gameId]: stream it and beat my presence.
  void enter(String gameId) {
    final coupleId = _coupleId;
    final me = _myUid;
    if (coupleId == null || me == null || gameId.trim().isEmpty) {
      return;
    }
    if (_currentId == gameId && _currentSub != null) {
      return;
    }
    // Rematch → the new game: my stamp on the finished one only kept the CF
    // from pushing me the rematch I am looking at, it can stay to age out.
    _leaveInternal(clearPresence: !(_current?.isFinished ?? false));
    _currentId = gameId;
    _currentLoaded = false;
    _currentSub = _service
        .watchGame(coupleId, gameId)
        .listen(_onCurrent, onError: (_) {});
    if (!_heartbeatPaused) {
      _startHeartbeat();
    }
    notifyListeners();
  }

  void _onCurrent(CaroGame? game) {
    _current = game;
    _currentLoaded = true;
    final pending = _pendingCell;
    if (pending != null &&
        (game == null || !game.isPlaying || game.cells.contains(pending))) {
      _pendingCell = null;
    }
    notifyListeners();
  }

  /// The game screen went away.
  void leave() {
    _leaveInternal(clearPresence: true);
    notifyListeners();
  }

  void _leaveInternal({required bool clearPresence}) {
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentId;
    if (clearPresence && coupleId != null && me != null && gameId != null) {
      unawaited(_service.clearPresence(coupleId, gameId, me));
    }
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _currentSub?.cancel();
    _currentSub = null;
    _currentId = null;
    _current = null;
    _currentLoaded = false;
    _pendingCell = null;
  }

  /// App to the background / screen covered: stop beating and drop my stamp
  /// so the partner's next move pushes me.
  void pauseHeartbeat() {
    if (_heartbeatPaused) {
      return;
    }
    _heartbeatPaused = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentId;
    if (coupleId != null && me != null && gameId != null) {
      unawaited(_service.clearPresence(coupleId, gameId, me));
    }
  }

  void resumeHeartbeat() {
    if (!_heartbeatPaused) {
      return;
    }
    _heartbeatPaused = false;
    if (_currentId != null) {
      _startHeartbeat();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _beat();
    _heartbeatTimer = Timer.periodic(CaroTiming.heartbeat, (_) => _beat());
  }

  void _beat() {
    final coupleId = _coupleId;
    final me = _myUid;
    final gameId = _currentId;
    if (coupleId != null && me != null && gameId != null) {
      unawaited(_service.heartbeat(coupleId, gameId, me));
    }
  }

  // ---------------------------------------------------------------- actions

  /// Starts a game with my first stone on [cell] (default: the centre). On
  /// [CaroActionStatus.ok] / [CaroActionStatus.alreadyOpen] the result's
  /// `gameId` is the game to open.
  Future<CaroActionResult> start({
    CaroRule rule = CaroRule.vn,
    int? cell,
    String? rematchOf,
  }) {
    if (!hasPartner) {
      return Future.value(const CaroActionResult(CaroActionStatus.noPartner));
    }
    return _run(
      'start',
      cell: cell ?? centerCell,
      rule: rule,
      rematchOf: rematchOf,
    );
  }

  /// Plays [cell] on the current game as move `cells.length` (the server
  /// refuses a stale screen / double tap). [pendingCell] shows it until the
  /// server's doc has it; on failure it is dropped and the result says why.
  Future<CaroActionResult> move(int cell) async {
    final game = _current;
    final me = _myUid;
    if (game == null || me == null || !game.isMyTurn(me) || _busy) {
      return const CaroActionResult(CaroActionStatus.notYourTurn);
    }
    if (!game.board.isEmpty(cell)) {
      return const CaroActionResult(CaroActionStatus.occupied);
    }
    _pendingCell = cell;
    final result = await _run(
      'move',
      gameId: game.id,
      cell: cell,
      moveNo: game.cells.length,
    );
    final landed = _current?.cells.contains(cell) ?? false;
    if (!result.isOk || landed) {
      _pendingCell = null;
      notifyListeners();
    }
    return result;
  }

  Future<CaroActionResult> resign() => _onCurrentGame('resign');

  /// "Để sau" — only while just the inviter's stone is down.
  Future<CaroActionResult> cancel() => _onCurrentGame('cancel');

  /// "Kết thúc ván" after 7 days without a move.
  Future<CaroActionResult> expire() => _onCurrentGame('expire');

  /// "Nhắc người ấy" (30' cooldown, server-enforced).
  Future<CaroActionResult> nudge() => _onCurrentGame('nudge');

  Future<CaroActionResult> _onCurrentGame(String op) {
    final gameId = _currentId ?? openGame?.id;
    if (gameId == null) {
      return Future.value(const CaroActionResult(CaroActionStatus.notPlaying));
    }
    return _run(op, gameId: gameId);
  }

  Future<CaroActionResult> _run(
    String op, {
    String? gameId,
    int? cell,
    int? moveNo,
    CaroRule? rule,
    String? rematchOf,
  }) async {
    final coupleId = _coupleId;
    if (coupleId == null) {
      return const CaroActionResult(CaroActionStatus.failed);
    }
    if (_busy) {
      return const CaroActionResult(CaroActionStatus.stale);
    }
    _busy = true;
    notifyListeners();
    try {
      return await _service.action(
        coupleId: coupleId,
        op: op,
        gameId: gameId,
        cell: cell,
        moveNo: moveNo,
        rule: rule,
        rematchOf: rematchOf,
      );
    } finally {
      _busy = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------- history

  /// First page (resets).
  Future<void> loadHistory() async {
    _resetHistory();
    await loadMoreHistory();
  }

  Future<void> loadMoreHistory() async {
    final coupleId = _coupleId;
    if (coupleId == null || _historyLoading) {
      return;
    }
    if (_historyLoaded && !_historyHasMore && !_historyFailed) {
      return;
    }
    _historyLoading = true;
    _historyFailed = false;
    notifyListeners();
    final page = await _service.fetchHistoryPage(
      coupleId: coupleId,
      limit: historyPageSize,
      startAfter: _historyCursor,
    );
    if (_disposed || _coupleId != coupleId) {
      return;
    }
    _historyLoading = false;
    _historyLoaded = true;
    _historyFailed = page.failed;
    if (!page.failed) {
      // D20: a game of an earlier pair never shows.
      _history = <CaroGame>[..._history, ...page.items.where(_isOurs)];
      _historyCursor = page.lastDoc ?? _historyCursor;
      _historyHasMore = page.hasMore;
    }
    notifyListeners();
  }

  void _resetHistory() {
    _history = const <CaroGame>[];
    _historyCursor = null;
    _historyHasMore = false;
    _historyLoading = false;
    _historyLoaded = false;
    _historyFailed = false;
  }

  @override
  void dispose() {
    _disposed = true;
    clear(notify: false);
    super.dispose();
  }
}
