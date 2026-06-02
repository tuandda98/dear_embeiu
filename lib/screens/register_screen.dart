import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:url_launcher/url_launcher.dart';

import '../app/app_routes.dart';
import '../app/app_urls.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/language_toggle_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _showTermsError = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    if (!_agreedToTerms) {
      HapticFeedback.heavyImpact();
      setState(() => _showTermsError = true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final didSignUp = await authProvider.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text,
    );

    if (!mounted) {
      return;
    }

    if (didSignUp) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.authGate,
        (route) => false,
      );
      return;
    }

    HapticFeedback.heavyImpact();
    final l10n = context.l10n;
    final message = authProvider.errorMessage ?? l10n.createAccountBtn;
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
                        // Clear the top-bar (back button + language toggle)
                        // so a tall form never pushes the header under them.
                        const SizedBox(height: 52),
                        _buildHeader(authProvider),
                        const SizedBox(height: 24),
                        _buildFormCard(authProvider),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    LucideIcons.arrowLeft,
                    color: AppColors.white,
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

  Widget _buildHeader(AuthProvider authProvider) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.userPlus,
                size: 14,
                color: AppColors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.createAccountBadge,
                style: AppTheme.pageEyebrowStyle(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.registerTitle,
          style: AppTheme.pageTitleStyle(),
        ),
        const SizedBox(height: 10),
        Text(
          authProvider.isUsingFirebase
              ? l10n.registerSubtitle
              : l10n.registerLocalFallback,
          style: AppTheme.pageSubtitleStyle(alpha: 0.84),
        ),
        if (authProvider.bootstrapMessage != null) ...[
          const SizedBox(height: 14),
          _buildStatusBanner(
            label: authProvider.authSourceLabel,
            message: authProvider.bootstrapMessage!,
            icon: authProvider.isUsingFirebase
                ? LucideIcons.cloud
                : LucideIcons.cloudOff,
            color: authProvider.isUsingFirebase
                ? AppColors.success
                : AppColors.warning,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBanner({
    required String label,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AuthProvider authProvider) {
    final l10n = context.l10n;

    return GlassCard(
      borderRadius: 28,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.displayNameLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _buildFieldBlock(
              label: l10n.displayNameLabel,
              child: TextFormField(
                controller: _displayNameController,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  hint: l10n.displayNameHint,
                  icon: LucideIcons.user,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return l10n.displayNameRequired;
                  }
                  if (text.length < 2) {
                    return l10n.displayNameTooShort;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _buildFieldBlock(
              label: l10n.emailLabel,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  hint: l10n.emailHint,
                  icon: LucideIcons.mail,
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
            const SizedBox(height: 14),
            _buildFieldBlock(
              label: l10n.passwordLabel,
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: _buildInputDecoration(
                  hint: l10n.passwordHint,
                  icon: LucideIcons.lock,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? LucideIcons.eye
                          : LucideIcons.eyeOff,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return l10n.passwordRequired;
                  }
                  if (text.length < 6) {
                    return l10n.passwordTooShort;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _buildFieldBlock(
              label: l10n.confirmPasswordLabel,
              child: TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: _buildInputDecoration(
                  hint: l10n.confirmPasswordHint,
                  icon: LucideIcons.shieldCheck,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? LucideIcons.eye
                          : LucideIcons.eyeOff,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return l10n.confirmPasswordRequired;
                  }
                  if (text != _passwordController.text.trim()) {
                    return l10n.passwordsMismatch;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(AppUrls.privacyPolicy),
                mode: LaunchMode.externalApplication,
              ),
              child: GlassCard(
                borderRadius: 14,
                blur: 14,
                fillAlpha: 0.12,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.privacyDisclosure,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.externalLink,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() {
                _agreedToTerms = !_agreedToTerms;
                if (_agreedToTerms) _showTermsError = false;
              }),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() {
                        _agreedToTerms = v ?? false;
                        if (_agreedToTerms) _showTermsError = false;
                      }),
                      activeColor: AppColors.accentRose,
                      checkColor: AppColors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      side: BorderSide(
                        color: _showTermsError
                            ? Colors.red.shade400
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.agreeToPrivacyPolicy,
                        style: TextStyle(
                          color: _showTermsError
                              ? Colors.red.shade400
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showTermsError) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text(
                  l10n.mustAgreeToPrivacyPolicy,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: authProvider.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        l10n.createAccountBtn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    l10n.alreadyWithUs,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.backToSignIn),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldBlock({
    required String label,
    required Widget child,
  }) {
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
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
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
