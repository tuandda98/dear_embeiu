import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app/route_observers.dart';
import '../l10n/l10n.dart';
import '../models/caro_game.dart';
import '../providers/caro_game_provider.dart';
import '../services/analytics_service.dart';
import '../services/caro_game_service.dart';
import '../services/push_notification_service.dart' show NotificationTapRouter;
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/caro/caro_board.dart';
import '../widgets/caro/caro_common.dart';
import '../widgets/caro/caro_new_game_sheet.dart';
import '../widgets/content_card.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';
import 'caro_history_screen.dart';

/// Opens the caro game (feature caro-game). [gameId] null = the couple's open
/// game, or the "Rủ … chơi" sheet when there is none. [source] feeds
/// `caro_open` (home · profile · push · inbox · widget; null = not logged).
///
/// Never stacks a second game screen: one already mounted is popped back to
/// and switched to [gameId] (same rule as rps, Tester RPS-13).
void openCaroGame(BuildContext context, {String? gameId, String? source}) {
  final provider = context.read<CaroGameProvider>();
  final id = (gameId ?? '').trim().isNotEmpty
      ? gameId!.trim()
      : provider.openGame?.id;
  if (id == null) {
    showCaroNewGameSheet(context);
    return;
  }
  if (source != null) {
    AnalyticsService.instance.logCaroOpen(source);
  }
  final navigator = Navigator.of(context);
  final existing = _CaroGameScreenState._top;
  if (existing != null) {
    navigator.popUntil(
      (route) =>
          route.settings.name == CaroGameScreen.routeName || route.isFirst,
    );
    existing._switchTo(id);
    return;
  }
  navigator.push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: CaroGameScreen.routeName),
      builder: (_) => CaroGameScreen(gameId: id),
    ),
  );
}

/// Empty board to choose the first square ("Tự chọn ô đầu tiên", §3.2).
void openCaroDraft(
  BuildContext context, {
  required CaroRule rule,
  String? rematchOf,
}) {
  final existing = _CaroGameScreenState._top;
  if (existing != null) {
    Navigator.of(context).popUntil(
      (route) =>
          route.settings.name == CaroGameScreen.routeName || route.isFirst,
    );
    existing._startDraft(rule, rematchOf);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: CaroGameScreen.routeName),
      builder: (_) => CaroGameScreen(draftRule: rule, rematchOf: rematchOf),
    ),
  );
}

/// Last board of a finished game, read-only (history row, §3.5).
void openCaroReplay(BuildContext context, String gameId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'CaroReplay'),
      builder: (_) => CaroGameScreen(gameId: gameId, readOnly: true),
    ),
  );
}

/// What the screen shows (design §3.3 table + §3.4). Pure, so the copy logic
/// is testable without Firebase.
enum CaroScreenMode {
  loading,
  draft,
  invited,
  myTurn,
  stale,
  waiting,
  finished,
  cancelled,
  expired,
}

CaroScreenMode caroScreenModeFor({
  required CaroGame? game,
  required bool loaded,
  required String myUid,
  bool draft = false,
  DateTime? now,
}) {
  if (draft) return CaroScreenMode.draft;
  if (!loaded) return CaroScreenMode.loading;
  if (game == null || game.isExpired) return CaroScreenMode.expired;
  if (game.isCancelled) return CaroScreenMode.cancelled;
  if (game.isFinished) return CaroScreenMode.finished;
  if (!game.isPlaying) return CaroScreenMode.expired;
  if (game.isStale(now: now)) return CaroScreenMode.stale;
  if (game.isMyTurn(myUid)) {
    return game.isFreshInvite && game.createdBy != myUid
        ? CaroScreenMode.invited
        : CaroScreenMode.myTurn;
  }
  return CaroScreenMode.waiting;
}

/// Who ended [game]: `endedBy` (resign / cancel / expire), else the player of
/// the last stone for a game finished by a move (five / full board). Null for
/// a game expired by the server (a partner left) — nobody logs that one.
String? caroEndedBy(CaroGame game) {
  final by = game.endedBy;
  if (by != null && by.isNotEmpty) return by;
  return game.isFinished ? game.lastMoveBy : null;
}

/// `caro_game_ended.result` from my side.
String caroEndedResult(CaroGame game, String myUid) {
  if (game.isCancelled) return 'cancel';
  if (!game.isFinished) return 'expired';
  final r = game.result;
  if (r == null || r.isDraw) return 'draw';
  if (r.reason == CaroResultReason.resign) {
    return r.winnerUid == myUid ? 'resign_partner' : 'resign_me';
  }
  return r.winnerUid == myUid ? 'win' : 'lose';
}

/// Cờ caro theo lượt — one screen for playing, waiting, the result and the
/// replay (design §3.3–3.5). No page scroll (C3): header, status card, board,
/// dock. Every change goes through [CaroGameProvider] (`caroAction`).
class CaroGameScreen extends StatefulWidget {
  const CaroGameScreen({
    super.key,
    this.gameId,
    this.draftRule,
    this.rematchOf,
    this.readOnly = false,
  });

  final String? gameId;

  /// Non-null = empty board to place the first stone with this rule.
  final CaroRule? draftRule;
  final String? rematchOf;

  /// Replay of a finished game: no dock, no presence.
  final bool readOnly;

  static const String routeName = 'CaroGame';

  /// Live game screens mounted (Home holds the "Có gì mới" sheet / catch-up
  /// gate while one is open, like rps RPS-7). May fire mid-build/dispose.
  static final ValueNotifier<int> mountedCount = ValueNotifier<int>(0);

  static bool get isOpen => mountedCount.value > 0;

  @override
  State<CaroGameScreen> createState() => _CaroGameScreenState();
}

enum _Problem { none, send, stale, network, action, cooldown }

class _CaroGameScreenState extends State<CaroGameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin, RouteAware {
  static final List<_CaroGameScreenState> _mounted = <_CaroGameScreenState>[];
  static _CaroGameScreenState? get _top =>
      _mounted.isEmpty ? null : _mounted.last;

  /// Ended games already logged on this phone (`caro_game_ended` once).
  static final Set<String> _loggedEnds = <String>{};

  static const double _zoomScale = 1.6;

  late final CaroGameProvider _provider;
  final TransformationController _zoom = TransformationController();
  final CaroTapSelector _selector = CaroTapSelector();
  late final AnimationController _zoomAnim;
  late final AnimationController _drop;
  late final AnimationController _win;
  Animation<Matrix4>? _zoomTween;

  CaroRule? _draftRule;
  String? _draftRematchOf;
  bool _draftBusy = false;

  CaroGame? _replay;
  bool _replayLoaded = false;

  _Problem _problem = _Problem.none;

  /// Minutes left for [_Problem.cooldown] (nudge refused by the server).
  int _cooldownMin = 0;
  bool _offline = false;
  bool _zoomed = false;
  double _boardSide = 0;
  String? _zoomAppliedFor;
  int _hintMoves = CaroPrefs.hintMoves;

  // Per-game trackers.
  String? _trackedId;
  int _seenCells = -1;
  bool _seenPlaying = false;
  int? _dropCell;

  bool _appActive = true;
  bool _covered = false;
  PageRoute<dynamic>? _route;
  Timer? _minuteTimer;
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  bool get _live => !widget.readOnly && _draftRule == null;

  @override
  void initState() {
    super.initState();
    _provider = context.read<CaroGameProvider>();
    _draftRule = widget.draftRule;
    _draftRematchOf = widget.rematchOf;
    if (!widget.readOnly) {
      _mounted.add(this);
      CaroGameScreen.mountedCount.value = _mounted.length;
    }
    _zoomAnim = AnimationController(vsync: this, duration: AppMotion.base)
      ..addListener(() {
        final t = _zoomTween;
        if (t != null) _zoom.value = t.value;
      });
    _drop = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      value: 1,
    );
    _win = AnimationController(vsync: this, duration: AppMotion.slow, value: 1);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appActive = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _provider.addListener(_onProvider);
    _netSub = Connectivity().onConnectivityChanged.listen((results) {
      final off =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (mounted && off != _offline) setState(() => _offline = off);
    }, onError: (_) {});
    _minuteTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled) setState(() {});
    });
    CaroPrefs.movesPlayed().then((n) {
      if (mounted) setState(() => _hintMoves = n);
    });
    if (widget.readOnly) {
      _loadReplay();
    } else if (_draftRule == null && widget.gameId != null) {
      // After the first frame: enter() notifies, which must not happen while
      // the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _provider.enter(widget.gameId!);
        if (!_appActive) _provider.pauseHeartbeat();
        _syncOnScreen();
      });
    }
  }

  Future<void> _loadReplay() async {
    final game = await _provider.fetchGame(widget.gameId ?? '');
    if (!mounted) return;
    setState(() {
      _replay = game;
      _replayLoaded = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && !identical(route, _route)) {
      if (_route != null) appPageRouteObserver.unsubscribe(this);
      _route = route;
      appPageRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    if (_mounted.remove(this)) {
      CaroGameScreen.mountedCount.value = _mounted.length;
    }
    appPageRouteObserver.unsubscribe(this);
    _provider.removeListener(_onProvider);
    WidgetsBinding.instance.removeObserver(this);
    if (!widget.readOnly) {
      // Not leave(): the tree is locked in dispose (review UI #1).
      _provider.detach();
    }
    if (NotificationTapRouter.caroGameOnScreen != null && _mounted.isEmpty) {
      NotificationTapRouter.caroGameOnScreen = null;
    }
    _minuteTimer?.cancel();
    _netSub?.cancel();
    _zoom.dispose();
    _zoomAnim.dispose();
    _drop.dispose();
    _win.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.readOnly) return;
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive && !_covered) {
      _provider.resumeHeartbeat();
    } else {
      _provider.pauseHeartbeat();
    }
    _syncOnScreen();
  }

  @override
  void didPushNext() {
    if (widget.readOnly) return;
    _covered = true;
    _provider.pauseHeartbeat();
    _syncOnScreen();
  }

  @override
  void didPopNext() {
    if (widget.readOnly) return;
    _covered = false;
    if (_appActive) _provider.resumeHeartbeat();
    _syncOnScreen();
  }

  void _syncOnScreen() {
    if (widget.readOnly) return;
    NotificationTapRouter.caroGameOnScreen = _appActive && !_covered
        ? _provider.currentGameId
        : null;
  }

  void _switchTo(String gameId) {
    if (!mounted) return;
    setState(() {
      _draftRule = null;
      _draftRematchOf = null;
      _selector.clear();
      _problem = _Problem.none;
    });
    if (gameId != _provider.currentGameId) {
      _provider.enter(gameId);
    }
    _syncOnScreen();
  }

  void _startDraft(CaroRule rule, String? rematchOf) {
    if (!mounted) return;
    _provider.leave();
    setState(() {
      _draftRule = rule;
      _draftRematchOf = rematchOf;
      _selector.clear();
      _problem = _Problem.none;
      _zoomed = false;
      _zoom.value = Matrix4.identity();
      _zoomAppliedFor = null;
    });
    _syncOnScreen();
  }

  /// Tracks the live game: stone drop, win line, haptics, `caro_game_ended`,
  /// and the presence flag when the provider switched game (rematch follow).
  void _onProvider() {
    if (!mounted || !_live) return;
    _syncOnScreen();
    final game = _provider.currentGame;
    final me = _provider.myUid;
    if (game == null || me == null) return;
    if (game.id != _trackedId) {
      _trackedId = game.id;
      _seenCells = game.cells.length;
      _seenPlaying = game.isPlaying;
      _zoomAppliedFor = null;
      _win.value = 1;
      _drop.value = 1;
      _selector.clear();
      return;
    }
    final reduce = AppMotion.reduceMotion(context);
    if (game.cells.length > _seenCells && _seenCells >= 0) {
      _dropCell = game.cells.last;
      // The board moved on: every old note (bàn vừa đổi, cooldown, and a
      // network/send error whose move landed anyway) is stale (CARO-T1).
      if (_problem != _Problem.none) {
        setState(() => _problem = _Problem.none);
      }
      if (reduce) {
        _drop.value = 1;
      } else {
        _drop.forward(from: 0);
      }
      if (_selector.selected != null &&
          !game.board.isEmpty(_selector.selected!)) {
        _selector.clear();
      }
    }
    _seenCells = game.cells.length;
    if (_seenPlaying && !game.isPlaying) {
      _seenPlaying = false;
      // The game is over: a note about a failed action no longer applies.
      if (_problem != _Problem.none) {
        setState(() => _problem = _Problem.none);
      }
      // One `caro_game_ended` per game, from the phone that ended it
      // (CARO-T5) — the partner's open screen sees the same change.
      if (caroEndedBy(game) == me && _loggedEnds.add(game.id)) {
        AnalyticsService.instance.logCaroGameEnded(
          result: caroEndedResult(game, me),
          moves: game.cells.length,
          spanHours: game.spanHours,
        );
      }
      if (game.isFinished) {
        final won = game.result?.winnerUid == me;
        won ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
        if (!reduce && (game.result?.line.isNotEmpty ?? false)) {
          _win.value = 0;
          Future<void>.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _win.forward(from: 0);
          });
        }
      }
    } else if (game.isPlaying) {
      _seenPlaying = true;
    }
  }

  // ------------------------------------------------------------- zoom

  void _applyInitialZoom(CaroGame? game) {
    final key = _draftRule != null ? 'draft' : game?.id;
    if (key == null || _zoomAppliedFor == key || _boardSide <= 0) return;
    _zoomAppliedFor = key;
    final zoom =
        _live && game != null && game.isPlaying && game.cells.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _zoomed = zoom;
      _zoom.value = zoom
          ? caroZoomMatrix(_boardSide, _zoomScale, game.lastCell)
          : Matrix4.identity();
      setState(() {});
    });
  }

  void _toggleZoom(CaroGame? game) {
    HapticFeedback.selectionClick();
    final target = _zoomed
        ? Matrix4.identity()
        : caroZoomMatrix(
            _boardSide,
            _zoomScale,
            _selector.selected ?? game?.lastCell,
          );
    setState(() => _zoomed = !_zoomed);
    if (AppMotion.reduceMotion(context)) {
      _zoom.value = target;
      return;
    }
    _zoomTween = Matrix4Tween(
      begin: _zoom.value,
      end: target,
    ).animate(CurvedAnimation(parent: _zoomAnim, curve: AppMotion.curve));
    _zoomAnim.forward(from: 0);
  }

  // ------------------------------------------------------------- actions

  bool _canPlace(CaroGame? game) {
    if (_draftRule != null) return !_draftBusy;
    final me = _provider.myUid;
    return _live &&
        game != null &&
        me != null &&
        game.isMyTurn(me) &&
        !_provider.isBusy &&
        !_offline;
  }

  void _onCellTap(int cell, CaroGame? game) {
    if (!_canPlace(game)) return;
    final board = game?.board ?? CaroBoard(const <int>[]);
    if (!board.isEmpty(cell)) return;
    // In a game one tap plays (user 2026-10-23: no confirm step). Only the
    // first move of a new invite keeps tap-to-select + the invite button.
    if (_draftRule == null) {
      _selector
        ..clear()
        ..tap(cell, DateTime.now());
      _play(game);
      return;
    }
    final r = _selector.tap(cell, DateTime.now());
    if (r == CaroTapResult.selected) {
      HapticFeedback.selectionClick();
      setState(() => _problem = _Problem.none);
    } else if (r == CaroTapResult.play) {
      _play(game);
    }
  }

  Future<void> _play(CaroGame? game) async {
    final cell = _selector.selected;
    if (cell == null) return;
    if (_draftRule != null) {
      final rule = _draftRule!;
      setState(() => _draftBusy = true);
      final result = await _provider.start(
        rule: rule,
        cell: cell,
        rematchOf: _draftRematchOf,
      );
      if (!mounted) return;
      setState(() => _draftBusy = false);
      final id = result.gameId;
      if ((result.isOk || result.status == CaroActionStatus.alreadyOpen) &&
          id != null) {
        if (result.isOk) {
          await CaroPrefs.setLastRule(rule);
          AnalyticsService.instance.logCaroGameStarted(
            rematch: _draftRematchOf != null,
            rule: rule.key,
          );
        }
        _switchTo(id);
      } else {
        setState(
          () => _problem = result.status == CaroActionStatus.network
              ? _Problem.network
              : _Problem.send,
        );
      }
      return;
    }
    if (game == null) return;
    final partnerWatching = game.isPresenceFresh(_provider.partnerUid ?? '');
    final result = await _provider.move(cell);
    if (!mounted) return;
    if (result.isOk) {
      HapticFeedback.lightImpact();
      _selector.clear();
      unawaited(CaroPrefs.countMove());
      AnalyticsService.instance.logCaroMove(
        moveNo: result.cellsLength ?? game.cells.length + 1,
        partnerWatching: partnerWatching,
      );
      setState(() {
        _problem = _Problem.none;
        _hintMoves++;
      });
    } else if (result.isStaleBoard) {
      _selector.clear();
      setState(() => _problem = _Problem.stale);
    } else if (result.status == CaroActionStatus.network) {
      setState(() => _problem = _Problem.network);
    } else {
      setState(() => _problem = _Problem.send);
    }
  }

  /// Every refused / failed action says why and what next (§13 U9).
  void _report(CaroActionResult result) {
    if (!mounted || result.isOk) return;
    setState(() {
      switch (result.status) {
        case CaroActionStatus.network:
          _problem = _Problem.network;
        case CaroActionStatus.cooldown:
        case CaroActionStatus.tooEarly:
          _problem = _Problem.cooldown;
          _cooldownMin = math.max(
            1,
            ((result.retryAfter ?? Duration.zero).inSeconds / 60).ceil(),
          );
        case CaroActionStatus.stale:
        case CaroActionStatus.notYourTurn:
        case CaroActionStatus.occupied:
        case CaroActionStatus.notPlaying:
          _problem = _Problem.stale;
        default:
          _problem = _Problem.action;
      }
    });
  }

  Future<void> _nudge(String partnerName) async {
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _provider.nudge();
    if (!mounted) return;
    if (result.isOk) {
      AnalyticsService.instance.logCaroNudgeSent();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.caroNudgeSent(partnerName)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      _report(result);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String keep,
    required String confirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.textPrimary, width: 1.4),
              shape: const StadiumBorder(),
              minimumSize: const Size(0, 48),
            ),
            child: Text(keep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorInk,
              foregroundColor: AppColors.white,
              shape: const StadiumBorder(),
              minimumSize: const Size(0, 48),
            ),
            child: Text(confirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _resign(CaroPeople people) async {
    final l10n = context.l10n;
    final ok = await _confirm(
      title: l10n.caroResignTitle,
      body: l10n.caroResignBody(
        people.partnerName,
        people.score(l10n, _provider.myWins, _provider.partnerWins + 1),
      ),
      keep: l10n.caroKeepPlaying,
      confirm: l10n.caroResign,
    );
    if (ok) _report(await _provider.resign());
  }

  Future<void> _cancel(CaroPeople people) async {
    final l10n = context.l10n;
    final ok = await _confirm(
      title: l10n.caroCancelTitle,
      body: l10n.caroCancelBody(people.partnerName),
      keep: l10n.caroKeepPlaying,
      confirm: l10n.caroCancelConfirm,
    );
    if (ok) _report(await _provider.cancel());
  }

  Future<void> _end() async {
    final l10n = context.l10n;
    final ok = await _confirm(
      title: l10n.caroEndTitle,
      body: l10n.caroEndBody,
      keep: l10n.caroEndKeep,
      confirm: l10n.caroEndConfirm,
    );
    if (ok) _report(await _provider.expire());
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<CaroGameProvider>();
    final people = CaroPeople.of(context, l10n);
    final game = widget.readOnly
        ? _replay
        : (_draftRule != null ? null : provider.currentGame);
    final loaded = widget.readOnly ? _replayLoaded : provider.isCurrentLoaded;
    final now = DateTime.now();
    final mode = caroScreenModeFor(
      game: game,
      loaded: loaded,
      myUid: people.myUid,
      draft: _draftRule != null,
      now: now,
    );
    final chip = widget.readOnly && game?.finishedAt != null
        ? l10n.caroReplayBadge(
            DateFormat(
              'dd/MM',
              Localizations.localeOf(context).toString(),
            ).format(game!.finishedAt!),
          )
        : l10n.caroBadge;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SubScreenHeader(
                  badge: chip,
                  badgeIcon: IconsaxPlusBold.game,
                  trailing: widget.readOnly
                      ? null
                      : HeaderIconButton(
                          icon: IconsaxPlusLinear.clock,
                          semanticsLabel: l10n.caroHistoryTooltip,
                          onTap: () => openCaroHistory(context),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // No page scroll (C3), so on a short phone with large text the
              // card is capped at 40% of the screen and scrolls on its own
              // (review UI #3) — the board keeps the rest.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _statusCard(l10n, people, game, mode, now),
                ),
              ),
              const SizedBox(height: 12),
              // The note floats over the board's lower edge instead of pushing
              // it: a board that resizes under the finger would turn the
              // second tap into another square (design C3, "khung không nhảy").
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _boardArea(l10n, people, game, mode),
                    ),
                    if (_noteFor(l10n, people, game, mode, now)
                        case final note?)
                      Positioned(left: 16, right: 16, bottom: 8, child: note),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _dock(l10n, people, game, mode, now),
              ),
              SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }

  String _span(AppLocalizations l10n, CaroGame game) {
    final from = game.createdAt;
    final to = game.finishedAt ?? game.lastMoveAt;
    if (from == null || to == null) return l10n.caroSpanMinutes(0);
    final minutes = to.difference(from).inMinutes;
    return minutes < 60
        ? l10n.caroSpanMinutes(minutes)
        : l10n.caroSpanHours((minutes / 60).round());
  }

  Widget _statusCard(
    AppLocalizations l10n,
    CaroPeople people,
    CaroGame? game,
    CaroScreenMode mode,
    DateTime now,
  ) {
    if (mode == CaroScreenMode.loading) {
      return ContentCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerSkeleton(width: 150, height: 24, borderRadius: 8),
            const SizedBox(height: 8),
            ShimmerSkeleton(width: 240, height: 18, borderRadius: 8),
            const SizedBox(height: 12),
            ShimmerSkeleton(
              width: double.infinity,
              height: 72,
              borderRadius: 16,
            ),
          ],
        ),
      );
    }
    final partner = people.partnerName;
    final n = '${game?.cells.length ?? 0}';
    String t(DateTime? at) => caroTime(context, at);
    final me = people.myUid;
    final partnerWatching =
        game != null &&
        game.isPlaying &&
        game.isPresenceFresh(people.partnerUid);
    late final String h1;
    late final String sub;
    switch (mode) {
      case CaroScreenMode.loading:
      case CaroScreenMode.draft:
        h1 = l10n.caroFirstTitle;
        sub = l10n.caroFirstSub(partner);
      case CaroScreenMode.invited:
        h1 = l10n.caroInvitedTitle(partner);
        sub = game!.rule == CaroRule.free
            ? l10n.caroInvitedSubFree(partner)
            : l10n.caroInvitedSubVn(partner);
      case CaroScreenMode.myTurn:
        h1 = l10n.caroMyTurn;
        sub = l10n.caroLastMove(partner, n, t(game!.lastMoveAt));
      case CaroScreenMode.stale:
        final since = game!.lastMoveAt ?? game.createdAt ?? now;
        h1 = l10n.caroStaleTitle('${now.difference(since).inDays}');
        sub = l10n.caroStaleSub(
          DateFormat(
            'dd/MM',
            Localizations.localeOf(context).toString(),
          ).format(since),
          partner,
        );
      case CaroScreenMode.waiting:
        final g = game!;
        h1 = l10n.caroWaiting(partner);
        final moved = g.lastMoveAt;
        final waited = moved == null ? 0 : now.difference(moved).inMinutes;
        final nudged = g.lastNudgeAt;
        if (_oldAppHint(g, now)) {
          sub = l10n.caroInvitedYesterday(
            partner,
            _whenDay(l10n, g.createdAt!, now),
            t(g.createdAt),
          );
        } else if (partnerWatching) {
          sub = l10n.caroPartnerWatching(n, t(moved), partner);
        } else if (nudged != null && (moved == null || nudged.isAfter(moved))) {
          sub = l10n.caroNudged(partner, t(nudged));
        } else if (waited >= 30) {
          sub = l10n.caroWaitedMin(n, t(moved), waited);
        } else {
          sub = l10n.caroYouMoved(n, t(moved), partner);
        }
      case CaroScreenMode.finished:
        final g = game!;
        final r = g.result;
        final iWon = r?.winnerUid == me;
        if (r == null || r.isDraw) {
          h1 = l10n.caroDraw;
          sub = l10n.caroDrawSub;
        } else if (r.reason == CaroResultReason.resign) {
          h1 = iWon ? l10n.caroPartnerResigned(partner) : l10n.caroYouResigned;
          sub = iWon
              ? l10n.caroPartnerResignedSub(n)
              : l10n.caroYouResignedSub(partner);
        } else {
          h1 = iWon ? l10n.caroYouWon : l10n.caroPartnerWon(partner);
          sub = l10n.caroWinDetail(n, t(g.finishedAt), _span(l10n, g));
        }
      case CaroScreenMode.cancelled:
        h1 = l10n.caroCancelledTitle;
        sub = l10n.caroCancelledSub(
          people.nameOf(game!.endedBy),
          t(game.updatedAt ?? game.lastMoveAt),
        );
      case CaroScreenMode.expired:
        h1 = l10n.caroExpiredTitle;
        sub = l10n.caroExpiredSub;
    }

    final rule = game?.rule ?? _draftRule ?? CaroRule.vn;
    final mySide = game?.sideOf(me) ?? CaroSide.x;
    final partnerSide = mySide == CaroSide.x ? CaroSide.o : CaroSide.x;
    final playing = game != null && game.isPlaying;
    final winner = game?.isFinished == true ? game!.result?.winnerUid : null;
    final litMe =
        mode == CaroScreenMode.draft ||
        (playing && game.turnUid == me) ||
        (winner != null && winner == me);
    final litPartner =
        (playing && game.turnUid == people.partnerUid) ||
        (winner != null && winner == people.partnerUid);
    final ended =
        mode == CaroScreenMode.cancelled || mode == CaroScreenMode.expired;
    return ContentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            liveRegion: true,
            label: '$h1. $sub',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!ended) ...[
            const SizedBox(height: 12),
            CaroLanes(
              people: people,
              myWins: _provider.myWins,
              partnerWins: _provider.partnerWins,
              mySide: mySide,
              partnerSide: partnerSide,
              midTop: caroRuleName(l10n, rule),
              midBottom: mode == CaroScreenMode.draft
                  ? l10n.caroLaneNew
                  : l10n.caroLaneMove(n),
              litMe: litMe,
              litPartner: litPartner,
              partnerWatching: partnerWatching,
              myCaption: winner != null && winner == me
                  ? l10n.caroLanePlusOne
                  : null,
              partnerCaption: winner != null && winner == people.partnerUid
                  ? l10n.caroLanePlusOne
                  : null,
              midSemantics: l10n.caroRuleTapHint(caroRuleName(l10n, rule)),
              onMidTap: () => showCaroRuleSheet(
                context,
                rule,
                colorX: people.colorX(game),
                colorO: people.colorO(game),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "hôm qua" / "ngày 17/10" for the invite time (review UI #5: ≥24 h
  /// isn't always yesterday).
  String _whenDay(AppLocalizations l10n, DateTime at, DateTime now) {
    final y = now.subtract(const Duration(days: 1));
    if (at.year == y.year && at.month == y.month && at.day == y.day) {
      return l10n.caroWhenYesterday;
    }
    return l10n.caroWhenOn(
      DateFormat(
        'dd/MM',
        Localizations.localeOf(context).toString(),
      ).format(at),
    );
  }

  bool _oldAppHint(CaroGame g, DateTime now) {
    final created = g.createdAt;
    return g.isFreshInvite &&
        g.createdBy == _provider.myUid &&
        created != null &&
        now.difference(created) >= CaroTiming.oldAppHintAfter;
  }

  Widget _boardArea(
    AppLocalizations l10n,
    CaroPeople people,
    CaroGame? game,
    CaroScreenMode mode,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          0.0,
          math.min(constraints.maxWidth - 32, constraints.maxHeight),
        );
        final inner = math.max(0.0, side - 12);
        if (inner != _boardSide) {
          _boardSide = inner;
        }
        if (mode != CaroScreenMode.loading) {
          _applyInitialZoom(game);
        }
        final board = game?.board ?? CaroBoard(const <int>[]);
        final canPlace = _canPlace(game);
        final pending = _provider.pendingCell;
        final selected = pending ?? _selector.selected;
        final mySide = _draftRule != null
            ? CaroSide.x
            : (game?.sideOf(people.myUid) ?? CaroSide.x);
        final winLine = game?.isFinished == true
            ? (game!.result?.line ?? const <int>[])
            : const <int>[];
        final dpr = MediaQuery.devicePixelRatioOf(context);
        String label(int i) {
          final r = '${CaroBoard.rowOf(i) + 1}';
          final c = '${CaroBoard.colOf(i) + 1}';
          final piece = board.pieceAt(i);
          var text = piece == null
              ? l10n.caroCellEmpty(r, c)
              : piece == CaroSide.x
              ? l10n.caroCellX(r, c, people.nameOf(game?.playerX))
              : l10n.caroCellO(r, c, people.nameOf(game?.playerO));
          if (piece != null && i == board.cells.last) text += l10n.caroCellLast;
          if (i == selected) text += l10n.caroCellSelected;
          if (winLine.contains(i)) text += l10n.caroCellWinning;
          return text;
        }

        return Center(
          child: SizedBox.square(
            dimension: side,
            child: ContentCard(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: InteractiveViewer(
                  transformationController: _zoom,
                  minScale: 1,
                  maxScale: 2.5,
                  boundaryMargin: EdgeInsets.zero,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      if (inner <= 0) return;
                      final cell = inner / CaroBoard.size;
                      final col = (d.localPosition.dx / cell).floor();
                      final row = (d.localPosition.dy / cell).floor();
                      if (CaroBoard.inside(row, col)) {
                        _onCellTap(CaroBoard.indexOf(row, col), game);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_zoom, _drop, _win]),
                      builder: (context, _) {
                        final scale = _zoom.value.getMaxScaleOnAxis();
                        return CustomPaint(
                          size: Size.square(inner),
                          painter: CaroBoardPainter(
                            board: board,
                            colorX: people.colorX(game),
                            colorO: people.colorO(game),
                            selected: mode == CaroScreenMode.loading
                                ? null
                                : selected,
                            selectedSide: mySide,
                            sending: pending != null || _draftBusy,
                            winLine: winLine,
                            winProgress: _win.value,
                            dropCell: _dropCell,
                            dropProgress: _drop.value,
                            lineWidth: 1 / (dpr * scale),
                            semanticsLabelOf: mode == CaroScreenMode.loading
                                ? null
                                : label,
                            semanticsCanPlace: canPlace,
                            semanticsTapOf: (i) => canPlace && board.isEmpty(i)
                                ? () => _onCellTap(i, game)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dock(
    AppLocalizations l10n,
    CaroPeople people,
    CaroGame? game,
    CaroScreenMode mode,
    DateTime now,
  ) {
    if (widget.readOnly) return const SizedBox.shrink();
    final partner = people.partnerName;
    final selected = _selector.selected;
    final children = <Widget>[];

    final zoomButton = _ZoomButton(
      zoomed: _zoomed,
      label: _zoomed ? l10n.caroZoomOut : l10n.caroZoomIn,
      onTap: () => _toggleZoom(game),
    );

    Widget primary;
    Widget? textAction;
    var showZoom = true;
    var showHint = false;
    switch (mode) {
      case CaroScreenMode.loading:
        primary = _Pill.disabled(l10n.caroLoading);
      case CaroScreenMode.draft:
        primary = _draftBusy
            ? _Pill.busy(l10n.caroSending)
            : _Pill.filled(
                l10n.caroInviteCta(partner),
                onTap: selected == null ? null : () => _play(game),
              );
        showHint = selected != null && _hintMoves < CaroPrefs.hintMoves;
      case CaroScreenMode.invited:
      case CaroScreenMode.myTurn:
      case CaroScreenMode.stale when game!.isMyTurn(people.myUid):
        if (_provider.isBusy && _provider.pendingCell != null) {
          primary = _Pill.busy(l10n.caroSending);
        } else if (_offline) {
          primary = _Pill.disabled(l10n.caroWaitNetwork);
        } else if (selected == null) {
          primary = _Pill.disabled(l10n.caroPickCell);
        } else {
          primary = _Pill.filled(
            _problem == _Problem.send ? l10n.caroCtaRetry : l10n.caroPlayHere,
            onTap: () => _play(game),
          );
        }
        textAction = _textActionFor(l10n, people, game!, mode);
      case CaroScreenMode.stale:
      case CaroScreenMode.waiting:
        final wait = game!.nudgeWait(people.myUid, now: now) ?? Duration.zero;
        primary = wait == Duration.zero
            ? _Pill.outlined(
                l10n.caroNudge(partner),
                onTap: _provider.isBusy ? null : () => _nudge(partner),
              )
            : _Pill.disabled(l10n.caroNudgeIn((wait.inSeconds / 60).ceil()));
        textAction = _textActionFor(l10n, people, game, mode);
      case CaroScreenMode.finished:
        showZoom = true;
        final lost = game!.result?.winnerUid == people.partnerUid;
        primary = _Pill.filled(
          lost ? l10n.caroCtaRematch : l10n.caroCtaNewGame,
          onTap: () => showCaroNewGameSheet(context, rematchOf: game.id),
        );
        textAction = _TextAction(
          label: l10n.caroSeeHistory,
          onTap: () => openCaroHistory(context),
        );
      case CaroScreenMode.cancelled:
      case CaroScreenMode.expired:
        showZoom = false;
        primary = _Pill.filled(
          l10n.caroNewInviteCta(partner),
          onTap: () => showCaroNewGameSheet(context),
        );
    }

    children.add(
      Row(
        children: [
          if (showZoom) ...[zoomButton, const SizedBox(width: 12)],
          Expanded(child: primary),
        ],
      ),
    );
    // The hint's line is held while it can appear in this game, so the
    // board doesn't shrink between the two taps.
    final placeTurn = mode == CaroScreenMode.draft;
    if (placeTurn && _hintMoves < CaroPrefs.hintMoves) {
      children.add(
        Visibility(
          visible: showHint,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.caroTapAgainHint,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }
    if (textAction != null) {
      children
        ..add(const SizedBox(height: 4))
        ..add(Center(child: textAction));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  /// Error / offline / old-app note over the board's lower edge.
  Widget? _noteFor(
    AppLocalizations l10n,
    CaroPeople people,
    CaroGame? game,
    CaroScreenMode mode,
    DateTime now,
  ) {
    if (widget.readOnly) return null;
    final partner = people.partnerName;
    if (_problem != _Problem.none) {
      return _Note(
        icon: IconsaxPlusLinear.danger,
        error: true,
        text: switch (_problem) {
          _Problem.stale => l10n.caroStaleBoard,
          _Problem.network => l10n.caroOffline,
          _Problem.action => l10n.caroActionError,
          _Problem.cooldown => l10n.caroNudgeIn(_cooldownMin),
          _ => l10n.caroSendError,
        },
      );
    }
    if (_offline &&
        (mode == CaroScreenMode.myTurn || mode == CaroScreenMode.invited)) {
      return _Note(icon: IconsaxPlusLinear.wifi_square, text: l10n.caroOffline);
    }
    if (mode == CaroScreenMode.waiting && _oldAppHint(game!, now)) {
      return _Note(
        icon: IconsaxPlusLinear.info_circle,
        text: l10n.caroOldAppHint(partner),
      );
    }
    return null;
  }

  Widget _textActionFor(
    AppLocalizations l10n,
    CaroPeople people,
    CaroGame game,
    CaroScreenMode mode,
  ) {
    if (mode == CaroScreenMode.stale) {
      return _TextAction(label: l10n.caroEndGame, onTap: _end);
    }
    if (game.canCancel) {
      return _TextAction(label: l10n.caroLater, onTap: () => _cancel(people));
    }
    return _TextAction(
      label: l10n.caroResign,
      color: AppColors.errorInk,
      onTap: () => _resign(people),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.error = false});

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // Opaque: it floats over the board.
        color: error
            ? Color.alphaBlend(
                AppColors.error.withValues(alpha: 0.10),
                AppColors.white,
              )
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Semantics(
        liveRegion: error,
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: error ? AppColors.errorInk : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.zoomed,
    required this.label,
    required this.onTap,
  });

  final bool zoomed;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: AppColors.white.withValues(alpha: 0.55),
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.textPrimary, width: 1.4),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 52,
              child: Icon(
                zoomed
                    ? IconsaxPlusLinear.search_zoom_out
                    : IconsaxPlusLinear.search_zoom_in,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _PillStyle { filled, outlined, disabled, busy }

/// Dock pill h52 (design §3.0): filled navy only when the partner is waiting
/// on me (C6), outlined otherwise; a disabled pill SAYS why.
class _Pill extends StatelessWidget {
  const _Pill._(this.label, this.style, this.onTap);

  factory _Pill.filled(String label, {VoidCallback? onTap}) => _Pill._(
    label,
    onTap == null ? _PillStyle.disabled : _PillStyle.filled,
    onTap,
  );
  factory _Pill.outlined(String label, {VoidCallback? onTap}) => _Pill._(
    label,
    onTap == null ? _PillStyle.disabled : _PillStyle.outlined,
    onTap,
  );
  factory _Pill.disabled(String label) =>
      _Pill._(label, _PillStyle.disabled, null);
  factory _Pill.busy(String label) => _Pill._(label, _PillStyle.busy, null);

  final String label;
  final _PillStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final filled = style == _PillStyle.filled || style == _PillStyle.busy;
    final fg = filled
        ? AppColors.white
        : style == _PillStyle.disabled
        ? AppColors.textPrimary.withValues(alpha: 0.70)
        : AppColors.textPrimary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled
            ? AppColors.textPrimary
            : AppColors.white.withValues(alpha: 0.55),
        shape: StadiumBorder(
          side: style == _PillStyle.outlined
              ? const BorderSide(color: AppColors.textPrimary, width: 1.4)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (style == _PillStyle.busy) ...[
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}
