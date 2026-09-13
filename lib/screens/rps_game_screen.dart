import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../app/route_observers.dart';
import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/rps_game.dart';
import '../providers/couple_provider.dart';
import '../providers/rps_game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/rps_choice_tile.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';
import 'rps_history_screen.dart';

/// Opens the rock-paper-scissors game screen (feature rps-game).
///
/// [gameId] null = join the couple's open game or create a fresh invite;
/// otherwise attach to that game (a tapped `rps_invite` push / inbox item —
/// the screen shows expired/cancelled/result itself when the game is closed).
/// One route name for every entry point (Home card, Profile badge, push tap),
/// same shape as [openCareMessageScreen].
///
/// Never stacks a second game screen (Tester RPS-13): when one is already
/// mounted anywhere in the stack (e.g. game → history → tapped push), pop
/// back down to it and hand it [gameId] instead — two game screens used to
/// fight over the one provider and the lower one was left on a skeleton.
void openRpsGame(BuildContext context, {String? gameId}) {
  HapticFeedback.selectionClick();
  final navigator = Navigator.of(context);
  final existing = _RpsGameScreenState._topMounted;
  if (existing != null) {
    navigator.popUntil(
      (route) =>
          route.settings.name == RpsGameScreen.routeName || route.isFirst,
    );
    if (gameId != null && gameId.trim().isNotEmpty) {
      existing._switchTo(gameId.trim());
    }
    return;
  }
  navigator.push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: RpsGameScreen.routeName),
      builder: (_) => RpsGameScreen(gameId: gameId),
    ),
  );
}

/// Display name of [uid] inside the couple (creator = person1), or [fallback].
String rpsMemberName(Couple? couple, String? uid, String fallback) {
  if (couple == null || uid == null || uid.isEmpty) {
    return fallback;
  }
  final name =
      (uid == couple.createdByUserId ? couple.person1Name : couple.person2Name)
          .trim();
  return name.isNotEmpty ? name : fallback;
}

/// "Oẳn tù tì" — one round of rock-paper-scissors with the partner
/// (overview §4, design §4.3). Renders [RpsGameProvider.phase]:
/// waiting → countdown → chosenWaiting/resolving → result, plus the
/// expired / cancelled / error dead-ends. All game logic (heartbeat,
/// auto-start, ticker, auto-finish) lives in the provider; this screen only
/// choreographs (ring, "1·2·3!" reveal, confetti, haptics) and calls
/// `choose` / `rematch` / `cancel` / `renewInvite`.
class RpsGameScreen extends StatefulWidget {
  const RpsGameScreen({super.key, this.gameId});

  final String? gameId;

  /// `RouteSettings.name` of the game route (analytics + stack guards).
  static const String routeName = 'RpsGame';

  /// How many game screens are mounted right now. Home listens to it to hold
  /// the "Có gì mới" sheet / catch-up gate while a round may be running
  /// (Tester RPS-7) and to retry them once the game closes. Listeners may be
  /// notified mid-build/dispose — defer any UI work.
  static final ValueNotifier<int> mountedCount = ValueNotifier<int>(0);

  /// A game screen is somewhere in the navigator stack.
  static bool get isOpen => mountedCount.value > 0;

  @override
  State<RpsGameScreen> createState() => _RpsGameScreenState();
}

class _RpsGameScreenState extends State<RpsGameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin, RouteAware {
  /// Mounted game screens, bottom → top (see [openRpsGame]).
  static final List<_RpsGameScreenState> _mountedStates =
      <_RpsGameScreenState>[];

  static _RpsGameScreenState? get _topMounted =>
      _mountedStates.isEmpty ? null : _mountedStates.last;

  /// "Nhắc lại" is allowed once per minute after an invite was sent
  /// (design D7 — the CF pushes on every create).
  static const Duration _nudgeCooldown = Duration(seconds: 60);

  /// Settling normally takes ≤2–5s; past this the UI admits it's slow.
  static const Duration _slowResolve = Duration(seconds: 6);

  late final RpsGameProvider _provider;

  /// Drives per-frame ring repaints while the clock runs (the remaining time
  /// itself is read from the game's server `startedAt`, so no drift).
  late final AnimationController _ringTicker;
  late final ConfettiController _confetti;

  bool _initFailed = false;
  bool _reduceMotion = false;
  bool _offline = false;

  RpsPhase? _lastPhase;
  int? _lastSeconds;

  /// A live phase (waiting/countdown/chosen) was seen on THIS screen, so a
  /// result that arrives afterwards gets the full "1·2·3!" reveal. Opening a
  /// finished game from the inbox shows the result statically.
  bool _seenLivePhase = false;

  /// 0 = nothing · 1..3 = digits · 4 = cards popped · 5 = title shown.
  int _revealStep = 0;
  final List<Timer> _revealTimers = <Timer>[];

  Timer? _cooldownTimer;
  Timer? _slowTimer;
  bool _resolvingSlow = false;

  /// Last seen [RpsGameProvider.isSettling] — arms [_slowTimer].
  bool _settling = false;
  String? _followedRematchId;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Presence heartbeat gating (Tester RPS-3): the app must be in the
  /// foreground AND this page uncovered for me to count as "on the screen".
  bool _appActive = true;
  bool _routeCovered = false;
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    _mountedStates.add(this);
    RpsGameScreen.mountedCount.value = _mountedStates.length;
    _provider = context.read<RpsGameProvider>();
    _provider.attach(this);
    _provider.addListener(_onProviderChanged);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appActive = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    if (lifecycle != null && !_appActive) {
      _provider.pauseHeartbeat(
        owner: this,
        transient:
            rpsPresenceActionFor(lifecycle) == RpsPresenceAction.pauseTransient,
      );
    }
    _ringTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _confetti = ConfettiController(
      duration: const Duration(milliseconds: 2500),
    );
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _offline) {
        setState(() => _offline = offline);
      }
    }, onError: (_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduceMotion(context);
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && !identical(route, _subscribedRoute)) {
      if (_subscribedRoute != null) {
        appPageRouteObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      appPageRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _mountedStates.remove(this);
    RpsGameScreen.mountedCount.value = _mountedStates.length;
    appPageRouteObserver.unsubscribe(this);
    _provider.removeListener(_onProviderChanged);
    WidgetsBinding.instance.removeObserver(this);
    // Not a blanket `leave()`: if another game screen sits below this one it
    // gets its game back (Tester RPS-13).
    _provider.detach(this);
    _clearRevealTimers();
    _cooldownTimer?.cancel();
    _slowTimer?.cancel();
    _connectivitySub?.cancel();
    _ringTicker.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The ring reads server time on every frame, so pausing/resuming the
    // ticker can't drift — it just saves frames while backgrounded.
    final action = rpsPresenceActionFor(state);
    if (action == RpsPresenceAction.beat) {
      _appActive = true;
      _syncRingTicker(_provider.phase);
      if (!_routeCovered) {
        // Beats immediately — the partner sees me back within one RTT.
        _provider.resumeHeartbeat(owner: this);
      }
      return;
    }
    // inactive / hidden / paused / detached: not looking at the round any
    // more (Tester RPS-3 — Android kept beating from the background, so the
    // partner started a round I lost without seeing, and the CF thought I was
    // still watching and skipped my result push). The provider also deletes
    // my presence stamp (RPS-19/RPS-20) — after a short grace for `inactive`,
    // at once when really backgrounded.
    _appActive = false;
    if (state == AppLifecycleState.paused) {
      _ringTicker.stop();
    }
    _provider.pauseHeartbeat(
      owner: this,
      transient: action == RpsPresenceAction.pauseTransient,
    );
  }

  // RouteAware — another PAGE (history…) covering the game screen means I'm
  // not on it; dialogs/sheets don't count (observer is typed on PageRoute).
  // A deliberate navigation, so presence is dropped right away (RPS-20).
  @override
  void didPushNext() {
    _routeCovered = true;
    _provider.pauseHeartbeat(owner: this);
  }

  @override
  void didPopNext() {
    _routeCovered = false;
    if (_appActive) {
      _provider.resumeHeartbeat(owner: this);
    }
  }

  /// Show [gameId] on this (already mounted) screen — a tapped push / inbox
  /// item while the game screen is somewhere in the stack ([openRpsGame]).
  void _switchTo(String gameId) {
    if (!mounted || gameId == _provider.currentGameId) {
      return;
    }
    setState(() {
      _initFailed = false;
      _seenLivePhase = false;
      _followedRematchId = null;
    });
    _provider.enter(gameId, owner: this);
  }

  // ------------------------------------------------------------- lifecycle

  Future<void> _start() async {
    if (!mounted) {
      return;
    }
    if (!_provider.isReady) {
      setState(() => _initFailed = true);
      return;
    }
    setState(() => _initFailed = false);
    final id = widget.gameId;
    if (id != null && id.trim().isNotEmpty) {
      _provider.enter(id, owner: this);
      return;
    }
    final created = await _provider.invite();
    if (mounted && created == null) {
      setState(() => _initFailed = true);
    }
  }

  void _onProviderChanged() {
    if (!mounted) {
      return;
    }
    final phase = _provider.phase;
    var changed = false;

    if (phase != _lastPhase) {
      changed = true;
      _onPhaseChanged(_lastPhase, phase);
      _lastPhase = phase;
    }

    // "Kết nối chậm… / Tải lại" after 6s of settling — `resolving` AND a
    // picked hand whose clock ran out (Tester RPS-22: the latter doesn't
    // change the phase, so it used to never arm and an offline player who
    // had picked sat on "Đang mở kết quả…" forever).
    final settling = _provider.isSettling;
    if (settling != _settling) {
      changed = true;
      _settling = settling;
      _slowTimer?.cancel();
      _slowTimer = null;
      _resolvingSlow = false;
      if (settling) {
        _slowTimer = Timer(_slowResolve, () {
          if (mounted) {
            setState(() => _resolvingSlow = true);
          }
        });
      }
    }

    // Per-second haptics while the clock runs (design §5.1).
    if (phase == RpsPhase.countdown || phase == RpsPhase.chosenWaiting) {
      final secs = _provider.countdownSeconds;
      if (secs != _lastSeconds) {
        if (_lastSeconds != null) {
          if (secs == 0) {
            HapticFeedback.heavyImpact();
          } else {
            HapticFeedback.selectionClick();
          }
        }
        _lastSeconds = secs;
      }
    }

    // Partner's rematch / newer invite → follow it. The decision lives in
    // [RpsGame.shouldFollow] (Tester RPS-1/RPS-2): from a closed game only to
    // its own rematch or something newer — never back to an older dead doc;
    // while waiting, to the partner's twin rematch / newer invite so two
    // racing "Chơi lại" taps converge on one game.
    final target = _provider.followTarget;
    if (target != null && _followedRematchId != target.id) {
      _followedRematchId = target.id;
      final fromClosed =
          phase == RpsPhase.result ||
          phase == RpsPhase.expired ||
          phase == RpsPhase.cancelled;
      unawaited(_provider.followOpenGame(target));
      if (fromClosed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.rpsRematchToast)));
      }
    }

    if (changed) {
      setState(() {});
    }
  }

  void _onPhaseChanged(RpsPhase? from, RpsPhase to) {
    _syncRingTicker(to);

    if (to == RpsPhase.waiting ||
        to == RpsPhase.countdown ||
        to == RpsPhase.chosenWaiting) {
      _seenLivePhase = true;
    }
    if (to == RpsPhase.countdown && from != RpsPhase.chosenWaiting) {
      // "Bắt đầu!" — one heavy tap as the ring appears.
      HapticFeedback.heavyImpact();
      _lastSeconds = null;
    }

    // Cooldown label ticks only while waiting as the creator.
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    if (to == RpsPhase.waiting) {
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    if (to == RpsPhase.result) {
      _startReveal(animated: _seenLivePhase && !_reduceMotion);
    } else {
      _clearRevealTimers();
      _revealStep = 0;
      _confetti.stop();
    }
  }

  void _syncRingTicker(RpsPhase phase) {
    final running =
        phase == RpsPhase.countdown ||
        phase == RpsPhase.chosenWaiting ||
        phase == RpsPhase.resolving;
    if (running && !_reduceMotion) {
      if (!_ringTicker.isAnimating) {
        _ringTicker.repeat();
      }
    } else {
      _ringTicker.stop();
    }
  }

  // ---------------------------------------------------------------- reveal

  void _clearRevealTimers() {
    for (final t in _revealTimers) {
      t.cancel();
    }
    _revealTimers.clear();
  }

  /// "1 · 2 · 3!" at 300ms beats, cards pop at 900ms, title 200ms later
  /// (design §7). Non-animated = straight to the final frame, no confetti.
  void _startReveal({required bool animated}) {
    _clearRevealTimers();
    if (!animated) {
      _revealStep = 5;
      if (_seenLivePhase) {
        _celebrate(confetti: false);
      }
      return;
    }
    _revealStep = 1;
    void at(int ms, VoidCallback fn) {
      _revealTimers.add(
        Timer(Duration(milliseconds: ms), () {
          if (mounted) {
            setState(fn);
          }
        }),
      );
    }

    at(300, () => _revealStep = 2);
    at(600, () {
      _revealStep = 3;
      HapticFeedback.mediumImpact();
    });
    at(900, () => _revealStep = 4);
    at(1100, () {
      _revealStep = 5;
      _celebrate(confetti: true);
    });
  }

  void _celebrate({required bool confetti}) {
    final outcome = _provider.myOutcome;
    if (outcome == RpsOutcome.win) {
      HapticFeedback.heavyImpact();
      if (confetti && !_reduceMotion) {
        _confetti.play();
      }
    } else if (outcome != null) {
      HapticFeedback.lightImpact();
    }
  }

  // --------------------------------------------------------------- actions

  Duration _nudgeRemaining() {
    final created = _provider.currentGame?.createdAt;
    if (created == null) {
      return Duration.zero;
    }
    final left = _nudgeCooldown - _provider.serverNow.difference(created);
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> _nudge() async {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final id = await _provider.renewInvite();
    if (!mounted) {
      return;
    }
    if (id != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.rpsNudgeSentToast)));
    }
  }

  Future<void> _cancel() async {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    final ok = await _provider.cancel();
    if (!mounted) {
      return;
    }
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.rpsCancelledToast)));
      navigator.maybePop();
    }
  }

  Future<void> _rematch() async {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final id = await _provider.rematch();
    if (!mounted || id != null) {
      return;
    }
    final error = _provider.lastActionError;
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error == RpsActionError.needCouple
                ? l10n.rpsNeedCouple
                : l10n.rpsErrorBody,
          ),
        ),
      );
    }
  }

  Future<void> _inviteAgain() async {
    HapticFeedback.selectionClick();
    final id = await _provider.invite();
    if (mounted && id == null) {
      setState(() => _initFailed = true);
    }
  }

  void _reload() {
    HapticFeedback.selectionClick();
    final id = _provider.currentGameId;
    if (id == null) {
      return;
    }
    _provider.leave();
    _provider.enter(id, owner: this);
    setState(() => _resolvingSlow = false);
  }

  void _close() {
    HapticFeedback.selectionClick();
    Navigator.of(context).maybePop();
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<RpsGameProvider>();
    final couple = context.watch<CoupleProvider>().couple;
    final myUid = provider.myUid;
    final partnerUid = provider.partnerUid;
    final myName = rpsMemberName(couple, myUid, l10n.rpsMeLabel);
    final partnerName = rpsMemberName(
      couple,
      partnerUid,
      l10n.reactionPartnerFallback,
    );

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: SubScreenHeader(
                      badge: l10n.rpsGameBadge,
                      badgeIcon: IconsaxPlusBold.game,
                      trailing: HeaderIconButton(
                        icon: IconsaxPlusLinear.clock,
                        semanticsLabel: l10n.rpsHistoryCta,
                        onTap: () => openRpsHistory(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _reduceMotion
                        ? _buildBody(
                            l10n,
                            provider,
                            myName,
                            partnerName,
                            myUid,
                            partnerUid,
                          )
                        : AnimatedSwitcher(
                            duration: AppMotion.base,
                            switchInCurve: AppMotion.curve,
                            switchOutCurve: AppMotion.curve,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.96,
                                  end: 1,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: _buildBody(
                              l10n,
                              provider,
                              myName,
                              partnerName,
                              myUid,
                              partnerUid,
                            ),
                          ),
                  ),
                ],
              ),
              // Confetti only ever plays on a WIN (design D6) — anchored just
              // under the header like the Love Tree sparkle.
              Align(
                alignment: const Alignment(0, -0.75),
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 24,
                  gravity: 0.25,
                  shouldLoop: false,
                  colors: const [
                    AppColors.sunset1,
                    AppColors.accentLove,
                    AppColors.accentLavender,
                    AppColors.white,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    RpsGameProvider provider,
    String myName,
    String partnerName,
    String? myUid,
    String? partnerUid,
  ) {
    if (_initFailed) {
      return _ClosedView(
        key: const ValueKey('error'),
        icon: IconsaxPlusLinear.cloud_cross,
        title: l10n.rpsErrorTitle,
        body:
            provider.lastActionError == RpsActionError.needCouple ||
                (provider.isReady && !provider.hasPartner)
            ? l10n.rpsNeedCouple
            : l10n.rpsErrorBody,
        ctaLabel: l10n.journalRetry,
        onCta: provider.isBusy ? null : _start,
        closeLabel: l10n.rpsCloseCta,
        onClose: _close,
      );
    }

    switch (provider.phase) {
      case RpsPhase.idle:
      case RpsPhase.loading:
        if (provider.isCurrentLoaded && provider.currentGame == null) {
          return _ClosedView(
            key: const ValueKey('missing'),
            icon: IconsaxPlusLinear.cloud_cross,
            title: l10n.rpsErrorTitle,
            body: l10n.rpsErrorBody,
            ctaLabel: l10n.rpsInviteAgainCta,
            onCta: provider.isBusy ? null : _inviteAgain,
            closeLabel: l10n.rpsCloseCta,
            onClose: _close,
          );
        }
        return const _ConnectingSkeleton(key: ValueKey('connecting'));

      case RpsPhase.waiting:
        final game = provider.currentGame;
        final isCreator = myUid != null && (game?.isCreatedBy(myUid) ?? false);
        return _WaitingView(
          key: const ValueKey('waiting'),
          myName: myName,
          partnerName: partnerName,
          isCreator: isCreator,
          partnerPresent: provider.isPartnerPresent,
          nudgeRemaining: _nudgeRemaining(),
          busy: provider.isBusy,
          reduceMotion: _reduceMotion,
          onNudge: _nudge,
          onCancel: _cancel,
          onClose: _close,
        );

      case RpsPhase.countdown:
      case RpsPhase.chosenWaiting:
      case RpsPhase.resolving:
        return _PlayView(
          key: const ValueKey('play'),
          provider: provider,
          ticker: _ringTicker,
          reduceMotion: _reduceMotion,
          offline: _offline,
          resolvingSlow: _resolvingSlow,
          onReload: _reload,
        );

      case RpsPhase.result:
        return _ResultView(
          key: ValueKey('result-${provider.currentGameId}'),
          provider: provider,
          myName: myName,
          partnerName: partnerName,
          myUid: myUid ?? '',
          partnerUid: partnerUid ?? '',
          step: _revealStep,
          reduceMotion: _reduceMotion,
          onRematch: provider.isBusy ? null : _rematch,
          onHistory: () => openRpsHistory(context),
          onClose: _close,
        );

      case RpsPhase.expired:
        return _ClosedView(
          key: const ValueKey('expired'),
          icon: IconsaxPlusLinear.timer_pause,
          title: l10n.rpsExpired,
          body: l10n.rpsExpiredBody,
          ctaLabel: l10n.rpsInviteAgainCta,
          onCta: provider.isBusy ? null : _inviteAgain,
          closeLabel: l10n.rpsCloseCta,
          onClose: _close,
        );

      case RpsPhase.cancelled:
        return _ClosedView(
          key: const ValueKey('cancelled'),
          icon: IconsaxPlusLinear.close_circle,
          title: l10n.rpsCancelled,
          body: l10n.rpsCancelledBody,
          ctaLabel: l10n.rpsInviteAgainCta,
          onCta: provider.isBusy ? null : _inviteAgain,
          closeLabel: l10n.rpsCloseCta,
          onClose: _close,
        );
    }
  }
}

// ── Shared buttons (design §5.1) ─────────────────────────────────────────────

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.textPrimary.withValues(
            alpha: 0.28,
          ),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SecondaryPill extends StatelessWidget {
  const _SecondaryPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.textPrimary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _TertiaryButton extends StatelessWidget {
  const _TertiaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        minimumSize: const Size(44, 44),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Connecting skeleton ──────────────────────────────────────────────────────

class _ConnectingSkeleton extends StatelessWidget {
  const _ConnectingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const ClipOval(
            child: SizedBox(
              width: 168,
              height: 168,
              child: ShimmerSkeleton.fill(),
            ),
          ),
          const SizedBox(height: 44),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                const Expanded(
                  child: ShimmerSkeleton(height: 120, borderRadius: 24),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Waiting ──────────────────────────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  const _WaitingView({
    super.key,
    required this.myName,
    required this.partnerName,
    required this.isCreator,
    required this.partnerPresent,
    required this.nudgeRemaining,
    required this.busy,
    required this.reduceMotion,
    required this.onNudge,
    required this.onCancel,
    required this.onClose,
  });

  final String myName;
  final String partnerName;
  final bool isCreator;
  final bool partnerPresent;
  final Duration nudgeRemaining;
  final bool busy;
  final bool reduceMotion;
  final VoidCallback onNudge;
  final VoidCallback onCancel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cooling = nudgeRemaining > Duration.zero;
    final nudgeLabel = cooling
        ? l10n.rpsNudgeCooldown(nudgeRemaining.inSeconds.toString())
        : l10n.rpsNudgeCta;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayerAvatar(
                name: myName,
                label: l10n.rpsMeLabel,
                isMe: true,
                present: true,
                reduceMotion: reduceMotion,
              ),
              const SizedBox(width: 20),
              _VsPill(label: l10n.rpsVs),
              const SizedBox(width: 20),
              _PlayerAvatar(
                name: partnerName,
                label: l10n.rpsPartnerLabel,
                isMe: false,
                present: partnerPresent,
                reduceMotion: reduceMotion,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  l10n.rpsWaitingPartner.replaceAll('…', ''),
                  textAlign: TextAlign.center,
                  style: AppTheme.displaySerif(
                    size: 20,
                    weight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _BlinkingDots(reduceMotion: reduceMotion),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isCreator ? l10n.rpsWaitingBody : l10n.rpsWaitingBodyInvitee,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (isCreator) ...[
            _PrimaryPill(
              icon: IconsaxPlusLinear.notification,
              label: nudgeLabel,
              onTap: (cooling || busy) ? null : onNudge,
            ),
            const SizedBox(height: 8),
            _TertiaryButton(
              label: l10n.rpsCancelCta,
              onTap: busy ? null : onCancel,
            ),
          ] else
            _TertiaryButton(label: l10n.rpsCloseCta, onTap: onClose),
        ],
      ),
    );
  }
}

/// 72pt initials avatar: mine on the hero gradient, the partner's on
/// lavender. A partner who isn't on the screen yet is faded + dashed; the
/// switch to solid is a 280ms tween (design §7).
class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({
    required this.name,
    required this.label,
    required this.isMe,
    required this.present,
    required this.reduceMotion,
  });

  final String name;
  final String label;
  final bool isMe;
  final bool present;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    final duration = reduceMotion ? Duration.zero : AppMotion.base;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: duration,
          curve: AppMotion.curve,
          opacity: present ? 1 : 0.55,
          child: CustomPaint(
            painter: present
                ? null
                : _DashedRingPainter(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
            child: Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.all(3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isMe
                    ? AppColors.primaryGradient
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accentLavender,
                          AppColors.accentLavenderDeep,
                        ],
                      ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isMe
                                ? AppColors.accentRose
                                : AppColors.accentLavenderDeep)
                            .withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 96,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 1;
    const dashes = 18;
    const gapRatio = 0.45;
    final step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * step,
        step * (1 - gapRatio),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

class _VsPill extends StatelessWidget {
  const _VsPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}

/// Three dots fading in turn after "Đang chờ người ấy". Static "…" under
/// Reduce Motion.
class _BlinkingDots extends StatefulWidget {
  const _BlinkingDots({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_BlinkingDots> createState() => _BlinkingDotsState();
}

class _BlinkingDotsState extends State<_BlinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _BlinkingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.displaySerif(
      size: 20,
      weight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.2,
    );
    if (widget.reduceMotion) {
      return Text('…', style: style);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Opacity(
                opacity: (t >= i && t < i + 1.5) ? 1 : 0.3,
                child: Text('.', style: style),
              ),
          ],
        );
      },
    );
  }
}

// ── Countdown / chosen / resolving ───────────────────────────────────────────

class _PlayView extends StatelessWidget {
  const _PlayView({
    super.key,
    required this.provider,
    required this.ticker,
    required this.reduceMotion,
    required this.offline,
    required this.resolvingSlow,
    required this.onReload,
  });

  final RpsGameProvider provider;
  final Animation<double> ticker;
  final bool reduceMotion;
  final bool offline;
  final bool resolvingSlow;
  final VoidCallback onReload;

  RpsChoiceTileState _tileState(RpsChoice choice) {
    if (provider.hasChosen) {
      return provider.myChoice == choice
          ? RpsChoiceTileState.selected
          : RpsChoiceTileState.dimmed;
    }
    return provider.canChoose
        ? RpsChoiceTileState.idle
        : RpsChoiceTileState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // "Đang mở kết quả…" also once MY hand is in and the clock hit 0 — the
    // provider keeps `chosenWaiting` there, but there's nothing left to wait
    // for except the server ([RpsGameProvider.isSettling]).
    final resolving = provider.isSettling;
    final compact = MediaQuery.sizeOf(context).width <= 360;

    final Widget caption;
    if (resolving) {
      caption = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resolvingSlow ? l10n.rpsResolvingSlow : l10n.rpsResolving,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (resolvingSlow) ...[
            const SizedBox(height: 4),
            _TertiaryButton(label: l10n.rpsReloadCta, onTap: onReload),
          ],
        ],
      );
    } else if (provider.hasChosen) {
      caption = _ChosenCaption(text: l10n.rpsChosenWaiting);
    } else {
      caption = Text(
        l10n.rpsCountdownPrompt,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: ticker,
            builder: (context, _) {
              final game = provider.currentGame;
              final remaining =
                  game?.countdownRemaining(now: provider.serverNow) ??
                  Duration.zero;
              final secs = (remaining.inMilliseconds + 999) ~/ 1000;
              final total = RpsTiming.countdown.inMilliseconds;
              final fraction = reduceMotion
                  ? secs / RpsTiming.countdown.inSeconds
                  : remaining.inMilliseconds / total;
              return _CountdownRing(
                fraction: fraction.clamp(0.0, 1.0),
                seconds: secs,
                resolving: resolving,
                reduceMotion: reduceMotion,
                unit: l10n.rpsCountdownUnit,
                semantics: l10n.rpsCountdownSemantics(secs.toString()),
              );
            },
          ),
          const SizedBox(height: 16),
          caption,
          const SizedBox(height: 24),
          if (offline) ...[
            _OfflineStrip(text: l10n.rpsOfflineHint),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              for (var i = 0; i < RpsChoice.hands.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: RpsChoiceTile(
                    choice: RpsChoice.hands[i],
                    state: _tileState(RpsChoice.hands[i]),
                    compact: compact,
                    onTap: () => provider.choose(RpsChoice.hands[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.rpsRulesHint,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// "Đã chọn ✓ · Chờ người ấy…" with the check in deep rose.
class _ChosenCaption extends StatelessWidget {
  const _ChosenCaption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    final idx = text.indexOf('✓');
    if (idx < 0) {
      return Text(text, textAlign: TextAlign.center, style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, idx)),
          const TextSpan(
            text: '✓',
            style: TextStyle(color: AppColors.accentLoveDeep),
          ),
          TextSpan(text: text.substring(idx + 1)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.wifi_square,
            size: 16,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 168pt ring (design §5.4): white .55 track, sunsetRomance sweep that
/// shrinks counter-clockwise as time runs out (solid deep rose in the final
/// second), the whole-seconds number in the middle (56 w800, switching with a
/// 200ms scale-pop) and "GIÂY" underneath. While resolving the number gives
/// way to three blinking dots.
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.fraction,
    required this.seconds,
    required this.resolving,
    required this.reduceMotion,
    required this.unit,
    required this.semantics,
  });

  final double fraction;
  final int seconds;
  final bool resolving;
  final bool reduceMotion;
  final String unit;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final urgent = !resolving && seconds <= 1;
    final numberColor = urgent
        ? AppColors.accentLoveDeep
        : AppColors.textPrimary;
    final Widget center = resolving
        ? _BlinkingDots(reduceMotion: reduceMotion)
        : Text(
            '$seconds',
            key: ValueKey<int>(seconds),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
              color: numberColor,
            ),
          );

    return Semantics(
      liveRegion: true,
      label: semantics,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 168,
          height: 168,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: resolving ? 0 : fraction,
              urgent: urgent,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: reduceMotion
                          ? center
                          : AnimatedSwitcher(
                              duration: AppMotion.fast,
                              switchInCurve: AppMotion.curve,
                              switchOutCurve: AppMotion.curve,
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                    opacity: anim,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 1.15,
                                        end: 1,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                              child: center,
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textPrimary.withValues(alpha: 0.55),
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

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.urgent});

  final double fraction;
  final bool urgent;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = AppColors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    if (fraction <= 0) {
      return;
    }
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (urgent) {
      progress.color = AppColors.accentLoveDeep;
    } else {
      progress.shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [AppColors.sunset3, AppColors.sunset2, AppColors.sunset1],
      ).createShader(rect);
    }
    // Sweep counter-clockwise from 12 o'clock so the arc "unwinds".
    canvas.drawArc(
      rect,
      -math.pi / 2,
      -2 * math.pi * fraction,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.urgent != urgent;
}

// ── Result ───────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.provider,
    required this.myName,
    required this.partnerName,
    required this.myUid,
    required this.partnerUid,
    required this.step,
    required this.reduceMotion,
    required this.onRematch,
    required this.onHistory,
    required this.onClose,
  });

  final RpsGameProvider provider;
  final String myName;
  final String partnerName;
  final String myUid;
  final String partnerUid;

  /// Reveal step from the screen state (1..3 digits, 4 cards, 5 title).
  final int step;
  final bool reduceMotion;
  final VoidCallback? onRematch;
  final VoidCallback onHistory;
  final VoidCallback onClose;

  String _ruleLine(AppLocalizations l10n, RpsChoice a, RpsChoice b) {
    final winner = RpsResult.compare(a, b) >= 0 ? a : b;
    switch (winner) {
      case RpsChoice.scissors:
        return l10n.rpsRuleScissorsPaper;
      case RpsChoice.paper:
        return l10n.rpsRulePaperRock;
      case RpsChoice.rock:
        return l10n.rpsRuleRockScissors;
      case RpsChoice.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = provider.result;
    final outcome = provider.myOutcome;
    final mine = result?.choiceOf(myUid) ?? RpsChoice.none;
    // Partner uid may be unknown on a legacy doc — take the other key.
    final theirsUid = partnerUid.isNotEmpty
        ? partnerUid
        : (result?.choices.keys.firstWhere(
                (k) => k != myUid,
                orElse: () => '',
              ) ??
              '');
    final theirs = result?.choiceOf(theirsUid) ?? RpsChoice.none;

    final String title;
    switch (outcome) {
      case RpsOutcome.win:
        title = l10n.rpsResultWin;
      case RpsOutcome.lose:
        title = l10n.rpsResultLose;
      case RpsOutcome.draw:
      case null:
        title = l10n.rpsResultDraw;
    }

    final String subtitle;
    if (!mine.isHand && !theirs.isHand) {
      subtitle = l10n.rpsResultTimeoutBoth;
    } else if (!mine.isHand) {
      subtitle = l10n.rpsResultTimeoutMe;
    } else if (!theirs.isHand) {
      subtitle = l10n.rpsResultTimeoutPartner;
    } else if (mine == theirs) {
      subtitle = l10n.rpsResultDrawSub(rpsChoiceLabel(l10n, mine));
    } else {
      subtitle = _ruleLine(l10n, mine, theirs);
    }

    final showCards = step >= 4;
    final showTitle = step >= 5;
    final win = outcome == RpsOutcome.win;
    final lose = outcome == RpsOutcome.lose;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Semantics(
            label: l10n.rpsResultSemantics(
              title,
              rpsChoiceLabel(l10n, mine),
              rpsChoiceLabel(l10n, theirs),
            ),
            child: ExcludeSemantics(
              child: Column(
                children: [
                  // Title block keeps its height so the cards don't jump when it
                  // fades in after them.
                  AnimatedOpacity(
                    duration: reduceMotion ? Duration.zero : AppMotion.fast,
                    opacity: showTitle ? 1 : 0,
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTheme.displaySerif(
                            size: 26,
                            weight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (win && reduceMotion) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '🎉 🎊 🎉',
                            style: TextStyle(fontSize: 22, height: 1),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 172,
                    child: showCards
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _PopIn(
                                enabled: !reduceMotion,
                                child: _ResultCard(
                                  choice: mine,
                                  name: myName,
                                  label: l10n.rpsMeLabel,
                                  isMe: true,
                                  winner: win,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Text(
                                  l10n.rpsVs,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                              ),
                              _PopIn(
                                enabled: !reduceMotion,
                                child: _ResultCard(
                                  choice: theirs,
                                  name: partnerName,
                                  label: l10n.rpsPartnerLabel,
                                  isMe: false,
                                  winner: lose,
                                ),
                              ),
                            ],
                          )
                        : _CountIn(step: step),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          AnimatedOpacity(
            duration: reduceMotion ? Duration.zero : AppMotion.fast,
            opacity: showTitle ? 1 : 0,
            child: IgnorePointer(
              ignoring: !showTitle,
              child: Column(
                children: [
                  _PrimaryPill(
                    icon: IconsaxPlusLinear.refresh,
                    label: l10n.rpsRematchCta,
                    onTap: onRematch,
                  ),
                  const SizedBox(height: 10),
                  _SecondaryPill(
                    label: l10n.rpsHistoryCta,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onHistory();
                    },
                  ),
                  const SizedBox(height: 4),
                  _TertiaryButton(label: l10n.rpsCloseCta, onTap: onClose),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "1 · 2 · 3!" — each digit pops (scale 1.3→1 + fade) as [step] advances.
class _CountIn extends StatelessWidget {
  const _CountIn({required this.step});

  final int step;

  static const List<String> _digits = <String>['1', '2', '3!'];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _digits.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '·',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary.withValues(alpha: 0.35),
                  ),
                ),
              ),
            _DigitPop(
              visible: step >= i + 1,
              child: Text(
                _digits[i],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DigitPop extends StatelessWidget {
  const _DigitPop({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      opacity: visible ? 1 : 0,
      child: AnimatedScale(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        scale: visible ? 1 : 1.3,
        child: child,
      ),
    );
  }
}

/// One-shot pop (scale .6→1 + fade, 320ms `easeOutBack` — the deliberate
/// curve exception for the cards, design D6). Static when [enabled] is false.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: child,
    );
  }
}

/// 140×164 "card" showing one player's hand. The winner's card wears the
/// sunsetRomance 2px border + rose glow; a skipped hand shows ⏳ faded.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.choice,
    required this.name,
    required this.label,
    required this.isMe,
    required this.winner,
  });

  final RpsChoice choice;
  final String name;
  final String label;
  final bool isMe;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final skipped = !choice.isHand;
    final accent = isMe ? AppColors.accentLove : AppColors.accentLavenderDeep;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();

    final inner = Container(
      width: 140,
      height: 164,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(winner ? 22 : 24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: skipped ? 0.6 : 1,
            child: Text(
              rpsChoiceGlyph(choice),
              style: const TextStyle(fontSize: 64, height: 1),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            rpsChoiceLabel(l10n, choice),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: skipped ? AppColors.textTertiary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 84),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.all(winner ? 2 : 0),
      decoration: BoxDecoration(
        gradient: winner ? AppColors.sunsetRomance : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: winner
                ? AppColors.accentRose.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: Offset(0, winner ? 8 : 10),
          ),
        ],
      ),
      child: inner,
    );
  }
}

// ── Expired / cancelled / error ──────────────────────────────────────────────

/// Centered dead-end state (same shape as care_timeline's `_TimelineMessage`):
/// 88pt disc + title 20 + body 14 + pill CTA + tertiary close.
class _ClosedView extends StatelessWidget {
  const _ClosedView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    required this.closeLabel,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback? onCta;
  final String closeLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 38, color: AppColors.accentLove),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTheme.displaySerif(
                      size: 20,
                      weight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _PrimaryPill(
                    label: ctaLabel,
                    onTap: onCta == null
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            onCta!();
                          },
                  ),
                  const SizedBox(height: 6),
                  _TertiaryButton(label: closeLabel, onTap: onClose),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
