import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/glass_card.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/language_toggle_button.dart';

/// Forgot-password screen (feature auth, Đợt 1). Lets a user request a Firebase
/// password-reset email. Pushed from the Login screen with the email being
/// typed there as a route argument (String?), used to prefill the field.
///
/// D-auth3: in local-fallback mode (`!isUsingFirebase`) the form is disabled
/// behind a "needs connection" banner. D-auth4 (anti-enumeration) lives in the
/// service: an unknown email still resolves to the `sent` state here.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  bool _prefilled = false;
  bool _sending = false;
  bool _sent = false;
  // Email captured at the moment of a successful send — shown in the confirmation
  // copy so it stays correct even if the field were later edited.
  String _sentToEmail = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefill the email passed from Login (once).
    if (!_prefilled) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String && arg.isNotEmpty) {
        _emailController.text = arg;
      }
      _prefilled = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    setState(() => _sending = true);
    final ok = await authProvider.requestPasswordReset(email);
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);

    if (ok) {
      // D-auth4: success state regardless of whether the email exists.
      setState(() {
        _sentToEmail = email;
        _sent = true;
      });
      return;
    }

    HapticFeedback.heavyImpact();
    final l10n = context.l10n;
    final message =
        authProvider.errorMessage ?? l10n.forgotPasswordNetworkError;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Re-sends from the `sent` state ("Didn't get it? Resend"). Reuses the same
  /// service call; stays on the confirmation card.
  Future<void> _resend() async {
    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.requestPasswordReset(_sentToEmail);
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    final message = ok
        ? l10n.forgotPasswordSentTitle
        : (authProvider.errorMessage ?? l10n.forgotPasswordNetworkError);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
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
                        if (!authProvider.isUsingFirebase) ...[
                          _buildLocalFallbackBanner(),
                          const SizedBox(height: 24),
                        ],
                        GlassCard(
                          borderRadius: 28,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              child: _sent
                                  ? _buildSentBody(authProvider)
                                  : _buildForm(authProvider),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Header redesign (2026-06-14): the eyebrow chip is centered on
              // the top-bar, level with the back squircle (left) and language
              // toggle (right) — the page title + subtitle were removed.
              Positioned(
                top: 8,
                left: 16,
                child: HeaderIconButton(
                  icon: IconsaxPlusLinear.arrow_left,
                  onTap: () => Navigator.of(context).maybePop(),
                  semanticsLabel: context.l10n.back,
                ),
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: EyebrowChip(
                        label: context.l10n.forgotPasswordBadge,
                        icon: IconsaxPlusLinear.key,
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
    );
  }

  // The chip/title/subtitle were removed in the 2026-06-14 header redesign
  // (chip now lives centered on the top-bar). The local-fallback banner is
  // rendered inline in build() when Firebase is unavailable.
  Widget _buildLocalFallbackBanner() {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Light card + dark ink (C1.4): white-on-glass failed contrast on the
        // blush gradient — match the Home waiting-banner language instead.
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              IconsaxPlusLinear.cloud_cross,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.forgotPasswordLocalFallback,
              style: const TextStyle(
                color: AppColors.textSecondary,
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

  Widget _buildForm(AuthProvider authProvider) {
    final l10n = context.l10n;
    final enabled = authProvider.isUsingFirebase && !_sending;

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('forgot-form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forgotPasswordEmailHeading,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _buildFieldBlock(
            label: l10n.emailLabel,
            child: TextFormField(
              controller: _emailController,
              enabled: enabled,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => enabled ? _submit() : null,
              decoration: _buildInputDecoration(
                hint: l10n.emailHint,
                icon: IconsaxPlusLinear.sms,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return l10n.emailRequired;
                }
                if (!text.contains('@')) {
                  return l10n.emailInvalid;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: enabled ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      l10n.forgotPasswordSendBtn,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentRose,
              ),
              child: Text(l10n.forgotPasswordBackToLogin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentBody(AuthProvider authProvider) {
    final l10n = context.l10n;

    return Column(
      key: const ValueKey('forgot-sent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              IconsaxPlusLinear.sms_tracking,
              color: AppColors.success,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.forgotPasswordSentTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.forgotPasswordSentBody(_sentToEmail),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentRose,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              l10n.forgotPasswordBackToLogin,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: _resend,
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRose),
            child: Text(l10n.forgotPasswordResendLink),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldBlock({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.accentRose,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: Icon(icon, color: AppColors.accentRose),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.white.withValues(alpha: 0.92),
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: AppColors.accentRose.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
    );
  }
}
