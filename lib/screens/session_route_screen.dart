import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/session_resolver.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import 'intro_screen.dart';

/// Single source of truth for "resolve where to go next, then go there".
///
/// Mounted both as the app `home` (cold start — branded splash) and as the
/// [AppRoutes.authGate] route (re-entered after login / register / sign-out /
/// session revocation — minimal loader). Both call
/// [SessionResolver.resolveStartRoute] then `pushReplacementNamed`; they only
/// ever differed in their loader UI, so this merges the old `SplashScreen` +
/// `AuthGateScreen` into one widget (#4 cleanup — no behaviour change).
class SessionRouteScreen extends StatefulWidget {
  const SessionRouteScreen({super.key, this.branded = false});

  /// `true` shows the full branded splash (heart + tagline + subtitle), used on
  /// cold start. `false` shows a minimal "checking session" spinner, used when
  /// the gate is re-entered mid-session.
  final bool branded;

  @override
  State<SessionRouteScreen> createState() => _SessionRouteScreenState();
}

class _SessionRouteScreenState extends State<SessionRouteScreen> {
  /// First-launch intro (feature onboarding, O4): set to the resolved guest
  /// route while the 3-slide intro is on screen; `null` the rest of the time.
  /// Only ever set for [AppRoutes.guest] — force-update, verify-email, setup
  /// and home navigate immediately as before.
  String? _pendingIntroRoute;

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    // Do the real session check here (no artificial delay) and route straight
    // to the destination — so a launch shows just this one branded loader.
    final navigator = Navigator.of(context);
    final route = await SessionResolver.resolveStartRoute(context);

    if (!mounted) {
      return;
    }

    // Intro only precedes the GUEST landing (brand-new, not-signed-in user) and
    // only once per device. Everything else — the force-update gate above all —
    // keeps its exact previous behaviour. Any storage error makes hasSeen()
    // return true, so a failure simply skips the intro.
    if (route == AppRoutes.guest && !await IntroScreen.hasSeen()) {
      if (!mounted) {
        return;
      }
      setState(() => _pendingIntroRoute = route);
      return;
    }

    if (!mounted) {
      return;
    }

    navigator.pushReplacementNamed(route);
  }

  Future<void> _finishIntro() async {
    final navigator = Navigator.of(context);
    final route = _pendingIntroRoute ?? AppRoutes.guest;
    await IntroScreen.markSeen();

    if (!mounted) {
      return;
    }

    navigator.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_pendingIntroRoute != null) {
      return IntroScreen(onDone: _finishIntro);
    }

    return Scaffold(
      body: Container(
        // Dawn gradient — same as login/home, so this loader dissolves
        // seamlessly into the app. The launch eases sunset (icon + native
        // splash) → dawn (this → app); the white heart is the constant thread.
        decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
        child: Center(
          child: widget.branded ? _buildBranded(l10n) : _buildMinimal(l10n),
        ),
      ),
    );
  }

  Widget _buildBranded(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.favorite,
          size: 80,
          color: AppColors.white,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.splashTagline,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.splashSubtitle,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 40),
        const CircularProgressIndicator(
          color: AppColors.white,
        ),
      ],
    );
  }

  Widget _buildMinimal(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.white),
        const SizedBox(height: 16),
        Text(
          l10n.checkingSession,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
