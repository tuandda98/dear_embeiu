import 'dart:io';

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

/// "Continue with Apple" (feature pairing-funnel, PF1/PF2): the black HIG
/// button plus the implied-consent line under it. Shared by the landing card,
/// Sign in and Sign up, and runs the whole Apple flow itself so the three stay
/// in sync. Callers check [isAvailable] before adding it (and its spacing) to
/// the tree — Android and the local fallback get nothing.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    this.onSignInInstead,
    this.onExistingEmail,
  });

  /// PF6 SnackBar action → the Sign in screen (landing, Sign up). Leave null on
  /// Sign in itself, which prefills the email instead.
  final VoidCallback? onSignInInstead;

  /// PF6 on the Sign in screen: the email Apple returned, to prefill the form.
  final ValueChanged<String>? onExistingEmail;

  /// Apple sign-in only runs natively on iOS, and only through Firebase (PF1).
  static bool isAvailable(AuthProvider auth) =>
      !kIsWeb && Platform.isIOS && auth.isUsingFirebase;

  Future<void> _signIn(BuildContext context) async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();
    final l10n = context.l10n;

    final didSignIn = await auth.signInWithApple();
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
      return; // The user closed the Apple sheet — stay put, say nothing.
    }
    HapticFeedback.heavyImpact();
    final conflict = auth.appleEmailConflict;
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
    final busy = auth.isAppleSigningIn;
    // The email button on the same screen is running: dim, don't spin.
    final locked = auth.isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: locked ? 0.5 : 1,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: busy || locked ? null : () => _signIn(context),
              style: FilledButton.styleFrom(
                // Pure black, not navy: HIG only allows black / white /
                // outlined Apple buttons.
                backgroundColor: AppColors.appleBlack,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.appleBlack,
                disabledForegroundColor: AppColors.white,
                shape: const StadiumBorder(),
              ),
              // One label in every state: the logo is decoration and the
              // spinner adds nothing for a screen reader.
              child: Semantics(
                label: l10n.continueWithApple,
                excludeSemantics: true,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.white,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.apple,
                              size: 24,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.continueWithApple,
                              style: const TextStyle(
                                // SF Pro Display, like Apple's own button —
                                // the rest of the app stays Quicksand.
                                fontFamily: 'CupertinoSystemDisplay',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const _ConsentLine(),
      ],
    );
  }
}

/// "By continuing with Apple, you agree to our Privacy Policy." The whole line
/// is one ≥44pt tap target opening the policy (PF11: no Terms page yet).
class _ConsentLine extends StatelessWidget {
  const _ConsentLine();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      container: true,
      link: true,
      label: '${l10n.appleConsentPrefix} ${l10n.privacyPolicyLabel}.',
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
                    text: '${l10n.appleConsentPrefix} ',
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

/// "or" divider between the email form and the Apple button (Sign in / Sign up
/// only — the landing card is short enough without one).
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
