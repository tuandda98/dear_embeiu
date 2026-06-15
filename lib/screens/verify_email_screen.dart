import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/glass_card.dart';
import '../widgets/language_toggle_button.dart';

/// Email-verification GATE (feature auth, Đợt 1 — D-auth2). A post-cutoff,
/// unverified user is routed here by [SessionResolver] after sign-up. There is
/// no back-pop (PopScope blocks it); the only escape hatch is "Sign out". The
/// screen auto-polls every ~4s and re-checks on resume so the moment the user
/// taps the link in their mail (often on another device/tab) it advances on
/// its own.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  static const Duration _cooldown = Duration(seconds: 60);
  static const Duration _pollInterval = Duration(seconds: 4);

  Timer? _pollTimer;
  Timer? _cooldownTimer;

  bool _checking = false;
  bool _resending = false;
  bool _notVerifiedYet = false;
  bool _navigated = false;

  // Cooldown is anchored to a wall-clock end time (not a tick countdown) so it
  // survives backgrounding/resume — we recompute "seconds left" from now.
  DateTime? _cooldownEndsAt;
  int _cooldownSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Register already auto-sent one verification email, so start the resend
    // cooldown immediately to prevent an instant spam re-send.
    _startCooldown();
    // Auto-poll for verification in the background.
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkVerified());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user likely just tapped the verification link in their mail app and
      // came back — check immediately rather than waiting for the next poll.
      _checkVerified();
    }
  }

  bool get _onCooldown => _cooldownSecondsLeft > 0;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownEndsAt = DateTime.now().add(_cooldown);
    _tickCooldown();
    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickCooldown(),
    );
  }

  void _tickCooldown() {
    final endsAt = _cooldownEndsAt;
    if (endsAt == null) {
      return;
    }
    final secondsLeft = endsAt.difference(DateTime.now()).inSeconds;
    final clamped = secondsLeft > 0 ? secondsLeft : 0;
    if (clamped == 0) {
      _cooldownTimer?.cancel();
    }
    if (clamped != _cooldownSecondsLeft && mounted) {
      setState(() => _cooldownSecondsLeft = clamped);
    } else {
      _cooldownSecondsLeft = clamped;
    }
  }

  String _formatCooldown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Reloads + checks verification. On success, navigates back through the auth
  /// gate (the resolver then sends the user on to setup/home). Used by the
  /// background poll, the resume hook, and the explicit "I've verified" button.
  Future<void> _checkVerified({bool manual = false}) async {
    if (_navigated) {
      return;
    }
    final authProvider = context.read<AuthProvider>();

    if (manual) {
      setState(() => _checking = true);
    }

    final verified = await authProvider.reloadAndCheckEmailVerified();
    if (!mounted) {
      return;
    }

    if (verified) {
      _navigated = true;
      _pollTimer?.cancel();
      _cooldownTimer?.cancel();
      // Brief success toast before we hand off to the auth gate — fires for both
      // the manual "I've verified" tap and the background poll/resume path.
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.verifyEmailSuccess)),
        );
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
      return;
    }

    if (manual) {
      HapticFeedback.heavyImpact();
      setState(() {
        _checking = false;
        _notVerifiedYet = true;
      });
    }
  }

  Future<void> _resend() async {
    if (_onCooldown || _resending) {
      return;
    }
    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _resending = true;
      _notVerifiedYet = false;
    });
    final ok = await authProvider.resendVerificationEmail();
    if (!mounted) {
      return;
    }
    setState(() => _resending = false);

    if (ok) {
      _startCooldown();
    } else {
      final l10n = context.l10n;
      final message = authProvider.errorMessage ?? l10n.verifyEmailResendError;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (!mounted) {
      return;
    }
    _navigated = true;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // authProvider watched so the screen rebuilds with provider state; the
    // chip/title/subtitle (which used currentEmail) were removed in the
    // 2026-06-14 header redesign, so we no longer read the email here.
    context.watch<AuthProvider>();

    return PopScope(
      // Gate: never let a system-back drop the user into setup/home unverified.
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.secondaryGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 52),
                          _buildCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                // No back arrow — this is a gate. The eyebrow chip is centered
                // alone on the top-bar (header redesign 2026-06-14: chip lives
                // on the bar; the title + subtitle were removed). The language
                // toggle trails on the right.
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: EyebrowChip(
                          label: context.l10n.verifyEmailBadge,
                          icon: IconsaxPlusLinear.sms_tracking,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 12,
                  right: 16,
                  child: LanguageToggleButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final l10n = context.l10n;

    return GlassCard(
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                IconsaxPlusLinear.sms,
                color: AppColors.accentRose,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.verifyEmailBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          // "Not verified yet" banner (animates in/out).
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _notVerifiedYet
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildNotYetBanner(),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          // Primary: I've verified.
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _checking ? null : () => _checkVerified(manual: true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _checking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      l10n.verifyEmailCheckBtn,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary: Resend (with cooldown).
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_onCooldown || _resending) ? null : _resend,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentRose,
                disabledForegroundColor: AppColors.textTertiary,
                side: BorderSide(
                  color: _onCooldown
                      ? AppColors.textTertiary.withValues(alpha: 0.4)
                      : AppColors.accentRose.withValues(alpha: 0.55),
                  width: 1.4,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: _resending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentRose,
                      ),
                    )
                  : const Icon(IconsaxPlusLinear.refresh, size: 18),
              label: Text(
                _onCooldown
                    ? l10n.verifyEmailResendCountdown(
                        _formatCooldown(_cooldownSecondsLeft),
                      )
                    : l10n.verifyEmailResend,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Divider before the escape hatch.
          Container(
            height: 1,
            color: AppColors.textTertiary.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 4),
          // Escape hatch: Sign out (reuses signOutBtn).
          Center(
            child: TextButton(
              onPressed: _signOut,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text(l10n.signOutBtn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotYetBanner() {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            IconsaxPlusLinear.warning_2,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.verifyEmailNotYet,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
