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
import '../theme/app_theme.dart';

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
    this.below,
  });

  /// PF6 SnackBar action → the Sign in screen (landing, Sign up). Leave null on
  /// Sign in itself, which prefills the email instead.
  final VoidCallback? onSignInInstead;

  /// PF6 on the Sign in screen: the email the provider returned, to prefill
  /// the form.
  final ValueChanged<String>? onExistingEmail;

  /// More options under the provider buttons, above the consent line (the
  /// landing card's email button + Sign up link).
  final Widget? below;

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
          AuthPillButton(
            label: l10n.continueWithApple,
            // Pure black, not navy: HIG only allows black / white / outlined
            // Apple buttons.
            background: AppColors.appleBlack,
            foreground: AppColors.white,
            // HIG: the logo file is as tall as the button, padding and all.
            logo: const CustomPaint(
              size: Size(24 * 52 / 44, 52),
              painter: _AppleLogoPainter(),
            ),
            // The file's own ~7pt margin + 3 = the Google button's 10.
            gap: 3,
            busy: running == SocialSignIn.apple,
            locked: lockedFor(SocialSignIn.apple),
            onPressed: onPressedFor(SocialSignIn.apple),
          ),
          if (google) const SizedBox(height: 12),
        ],
        if (google)
          AuthPillButton(
            label: l10n.continueWithGoogle,
            // Google branding: white, 1px #747775 outline, #1F1F1F text.
            background: AppColors.white,
            foreground: AppColors.googleText,
            border: const BorderSide(color: AppColors.googleBorder),
            logo: const CustomPaint(
              size: Size.square(18),
              painter: _GoogleLogoPainter(),
            ),
            busy: running == SocialSignIn.google,
            locked: lockedFor(SocialSignIn.google),
            onPressed: onPressedFor(SocialSignIn.google),
          ),
        if (below case final below?) ...[const SizedBox(height: 12), below],
        const SizedBox(height: 10),
        const _ConsentLine(),
      ],
    );
  }
}

/// Pill h52, logo + label centered, for the provider buttons and the landing's
/// email option. Every option gets the same size and type so none looks
/// louder (HIG: Apple's button no smaller than the others). While its sign-in
/// runs the content becomes a spinner; while something else runs the whole
/// button dims. The pressed overlay follows [foreground].
class AuthPillButton extends StatelessWidget {
  const AuthPillButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.logo,
    required this.busy,
    required this.locked,
    required this.onPressed,
    this.border,
    this.gap = 10,
  });

  final String label;
  final Color background;
  final Color foreground;
  final BorderSide? border;
  final Widget logo;

  /// Space between [logo] and the label.
  final double gap;
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
                        SizedBox(width: gap),
                        Text(
                          label,
                          // The theme's pill type, so the brand buttons sit
                          // in the card instead of shouting over it.
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
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

/// Apple's "Left-aligned – Small" logo, path copied unchanged from the 24×44
/// SVG in Apple Design Resources (artwork licence accepted 2026-10-12). HIG:
/// never draw a custom Apple logo, never crop the file. Small matches the 18pt
/// Google "G". The file's black backdrop is the button itself, so only the
/// glyph is painted.
class _AppleLogoPainter extends CustomPainter {
  const _AppleLogoPainter();

  static final Path _glyph = Path()
    ..moveTo(12.2337427, 16.9879688)
    ..cubicTo(
      12.8896607,
      16.9879688,
      13.7118677,
      16.5445313,
      14.2014966,
      15.9532812,
    )
    ..cubicTo(
      14.6449341,
      15.4174609,
      14.968274,
      14.6691602,
      14.968274,
      13.9208594,
    )
    ..cubicTo(
      14.968274,
      13.8192383,
      14.9590357,
      13.7176172,
      14.9405591,
      13.6344727,
    )
    ..cubicTo(
      14.2107349,
      13.6621875,
      13.3330982,
      14.1241016,
      12.8065162,
      14.7430664,
    )
    ..cubicTo(
      12.3907935,
      15.2142188,
      12.012024,
      15.9532812,
      12.012024,
      16.7108203,
    )
    ..cubicTo(
      12.012024,
      16.8216797,
      12.0305005,
      16.9325391,
      12.0397388,
      16.9694922,
    )
    ..cubicTo(
      12.0859302,
      16.9787305,
      12.1598365,
      16.9879688,
      12.2337427,
      16.9879688,
    )
    ..close()
    ..moveTo(9.92417241, 28.1662891)
    ..cubicTo(
      10.8202857,
      28.1662891,
      11.2175318,
      27.5658008,
      12.3353638,
      27.5658008,
    )
    ..cubicTo(
      13.4716724,
      27.5658008,
      13.721106,
      28.1478125,
      14.7188404,
      28.1478125,
    )
    ..cubicTo(
      15.6980982,
      28.1478125,
      16.3540162,
      27.2424609,
      16.972981,
      26.3555859,
    )
    ..cubicTo(
      17.6658521,
      25.339375,
      17.9522388,
      24.3416406,
      17.9707154,
      24.2954492,
    )
    ..cubicTo(
      17.9060474,
      24.2769727,
      16.0306763,
      23.5101953,
      16.0306763,
      21.3576758,
    )
    ..cubicTo(
      16.0306763,
      19.491543,
      17.5088013,
      18.6508594,
      17.5919459,
      18.5861914,
    )
    ..cubicTo(
      16.612688,
      17.1819727,
      15.1253248,
      17.1450195,
      14.7188404,
      17.1450195,
    )
    ..cubicTo(
      13.6194849,
      17.1450195,
      12.7233716,
      17.8101758,
      12.1598365,
      17.8101758,
    )
    ..cubicTo(
      11.5501099,
      17.8101758,
      10.7463794,
      17.1819727,
      9.79483648,
      17.1819727,
    )
    ..cubicTo(
      7.98413335,
      17.1819727,
      6.14571538,
      18.6785742,
      6.14571538,
      21.5054883,
    )
    ..cubicTo(
      6.14571538,
      23.2607617,
      6.8293482,
      25.1176563,
      7.67003179,
      26.3186328,
    )
    ..cubicTo(
      8.39061773,
      27.3348438,
      9.01882085,
      28.1662891,
      9.92417241,
      28.1662891,
    )
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 44);
    canvas.drawPath(_glyph, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_AppleLogoPainter oldDelegate) => false;
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
