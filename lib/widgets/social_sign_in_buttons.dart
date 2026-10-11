import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_routes.dart';
import '../app/app_urls.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

/// "Continue with Apple" + "Continue with Google" (feature pairing-funnel,
/// PF1/PF2, PF14/PF15) and one implied-consent line under them. iOS shows
/// Apple then Google, Android only Google. Shared by the landing card, Sign in
/// and Sign up, and runs the sign-in itself so the three stay in sync. Callers
/// check [isAvailable] before adding it (and its spacing) to the tree.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({
    super.key,
    this.onSignInInstead,
    this.onExistingEmail,
  });

  /// PF6 SnackBar action → the Sign in screen (landing, Sign up). Leave null on
  /// Sign in itself, which prefills the email instead.
  final VoidCallback? onSignInInstead;

  /// PF6 on the Sign in screen: the email the provider returned, to prefill
  /// the form.
  final ValueChanged<String>? onExistingEmail;

  /// Apple sign-in only runs natively on iOS (PF1).
  static bool get _apple => !kIsWeb && Platform.isIOS;

  /// Google needs its OAuth client (PF17): on iOS the CLIENT_ID of
  /// GoogleService-Info.plist; Android's comes from google-services.json.
  static bool get _google {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid ||
        (Platform.isIOS &&
            Firebase.apps.isNotEmpty &&
            Firebase.app().options.iosClientId != null);
  }

  /// Both providers sign in through Firebase only.
  static bool isAvailable(AuthProvider auth) =>
      auth.isUsingFirebase && (_apple || _google);

  Future<void> _signIn(BuildContext context, SocialSignIn provider) async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();
    final l10n = context.l10n;

    final didSignIn = await auth.signInWithSocial(provider);
    if (!context.mounted) {
      return;
    }
    if (didSignIn) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
      return;
    }

    final message = auth.errorMessage;
    if (message == null) {
      return; // The user closed the sheet / picker — stay put, say nothing.
    }
    HapticFeedback.heavyImpact();
    final conflict = auth.emailConflict;
    final email = conflict?.email;
    if (email != null && email.isNotEmpty) {
      onExistingEmail?.call(email);
    }
    final signInInstead = conflict == null ? null : onSignInInstead;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: conflict == null ? 4 : 5),
          // An action would keep the bar up until tapped; PF6 wants 5s.
          persist: false,
          action: signInInstead == null
              ? null
              : SnackBarAction(label: l10n.signIn, onPressed: signInInstead),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final running = auth.socialSignIn;
    // Something else on the screen is running (email form or the other
    // provider): dim, don't spin.
    bool lockedFor(SocialSignIn provider) =>
        auth.isLoading || (running != null && running != provider);
    VoidCallback? onPressedFor(SocialSignIn provider) =>
        auth.isLoading || running != null
        ? null
        : () => _signIn(context, provider);
    final google = _google;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_apple) ...[
          _SocialButton(
            label: l10n.continueWithApple,
            // Pure black, not navy: HIG only allows black / white / outlined
            // Apple buttons.
            background: AppColors.appleBlack,
            foreground: AppColors.white,
            logo: const Icon(Icons.apple, size: 24, color: AppColors.white),
            busy: running == SocialSignIn.apple,
            locked: lockedFor(SocialSignIn.apple),
            onPressed: onPressedFor(SocialSignIn.apple),
          ),
          if (google) const SizedBox(height: 12),
        ],
        if (google)
          _SocialButton(
            label: l10n.continueWithGoogle,
            // Google branding: white, 1px #747775 outline, #1F1F1F text.
            background: AppColors.white,
            foreground: AppColors.googleText,
            border: const BorderSide(color: AppColors.googleBorder),
            logo: const CustomPaint(
              size: Size.square(22),
              painter: _GoogleLogoPainter(),
            ),
            busy: running == SocialSignIn.google,
            locked: lockedFor(SocialSignIn.google),
            onPressed: onPressedFor(SocialSignIn.google),
          ),
        const SizedBox(height: 10),
        const _ConsentLine(),
      ],
    );
  }
}

/// Pill h52, logo + label centered. While its sign-in runs the content becomes
/// a spinner; while something else runs the whole button dims. The pressed
/// overlay follows [foreground] (white on Apple, light grey on Google).
/// Every provider gets the same label style so none looks louder — HIG only
/// asks that Apple's button is no smaller than the others.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.logo,
    required this.busy,
    required this.locked,
    required this.onPressed,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final BorderSide? border;
  final Widget logo;
  final bool busy;
  final bool locked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background,
            disabledForegroundColor: foreground,
            side: border,
            shape: const StadiumBorder(),
          ),
          // One label in every state: the logo is decoration and the spinner
          // adds nothing for a screen reader.
          child: Semantics(
            label: label,
            excludeSemantics: true,
            child: busy
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: foreground,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        logo,
                        const SizedBox(width: 10),
                        Text(
                          label,
                          // iOS: Apple's HIG puts a custom button's title at
                          // 43% of its height (52 → 22) and Google matches it.
                          // Android has only Google, at its own 14/40 ratio
                          // (52 → 18). The brands use the system font; the
                          // rest of the app stays Quicksand.
                          style: TextStyle(
                            fontFamily: Platform.isIOS
                                ? 'CupertinoSystemDisplay'
                                : 'Roboto',
                            fontSize: Platform.isIOS ? 22 : 18,
                            fontWeight: FontWeight.w500,
                            color: foreground,
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

/// The official 4-colour Google "G", drawn from its 48×48 SVG paths (PF15 —
/// no package, no image asset).
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static final List<(Color, Path)> _parts = [
    (
      const Color(0xFFEA4335),
      Path()
        ..moveTo(24, 9.5)
        ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
        ..lineTo(40.06, 6.25)
        ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
        ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
        ..lineTo(10.54, 19.41)
        ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
        ..close(),
    ),
    (
      const Color(0xFF4285F4),
      Path()
        ..moveTo(46.98, 24.55)
        ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
        ..lineTo(24, 20)
        ..lineTo(24, 29.02)
        ..lineTo(36.94, 29.02)
        ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
        ..lineTo(39.89, 42.2)
        ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
        ..close(),
    ),
    (
      const Color(0xFFFBBC05),
      Path()
        ..moveTo(10.53, 28.59)
        ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24)
        ..cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41)
        ..lineTo(2.55, 13.22)
        ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
        ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
        ..lineTo(10.53, 28.59)
        ..close(),
    ),
    (
      const Color(0xFF34A853),
      Path()
        ..moveTo(24, 48)
        ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
        ..lineTo(32.16, 36.19)
        ..cubicTo(30.01, 37.64, 27.24, 38.49, 24, 38.49)
        ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
        ..lineTo(2.55, 34.77)
        ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
        ..close(),
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint();
    for (final (color, path) in _parts) {
      canvas.drawPath(path, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}

/// "By continuing, you agree to our Privacy Policy." The whole line is one
/// ≥44pt tap target opening the policy (PF11: no Terms page yet).
class _ConsentLine extends StatelessWidget {
  const _ConsentLine();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      container: true,
      link: true,
      label: '${l10n.socialConsentPrefix} ${l10n.privacyPolicyLabel}.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => launchUrl(
            Uri.parse(AppUrls.privacyPolicy),
            mode: LaunchMode.externalApplication,
          ),
          borderRadius: BorderRadius.circular(8),
          splashColor: AppColors.accentRose.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              child: ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    text: '${l10n.socialConsentPrefix} ',
                    children: [
                      TextSpan(
                        text: l10n.privacyPolicyLabel,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textPrimary.withValues(
                            alpha: 0.40,
                          ),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  // Navy .80: textSecondary / rose fail 4.5:1 on the darkest
                  // spot of the dawn glass (design §1).
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.80),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "or" divider between the email form and the social buttons (Sign in /
/// Sign up only — the landing card is short enough without one).
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.textPrimary.withValues(alpha: 0.10),
      ),
    );

    return Row(
      children: [
        line,
        const SizedBox(width: 12),
        Text(
          context.l10n.authOrDivider,
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.80),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        line,
      ],
    );
  }
}
