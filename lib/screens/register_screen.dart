import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

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

    if (!_formKey.currentState!.validate()) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(authProvider),
                    const SizedBox(height: 24),
                    _buildFormCard(authProvider),
                  ],
                ),
              ),
            ),
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
            color: AppColors.white.withOpacity( 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.white.withOpacity( 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 14,
                color: AppColors.white.withOpacity( 0.92),
              ),
              const SizedBox(width: 8),
              Text(
                'CREATE ACCOUNT',
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
                ? Icons.cloud_done_rounded
                : Icons.usb_off_rounded,
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
        color: AppColors.white.withOpacity( 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity( 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity( 0.16),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity( 0.22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withOpacity( 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
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
                  icon: Icons.badge_rounded,
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
                  icon: Icons.email_rounded,
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
                  icon: Icons.password_rounded,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
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
                  icon: Icons.verified_user_rounded,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
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
            const SizedBox(height: 20),
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
      fillColor: AppColors.white.withOpacity( 0.92),
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
        borderSide: BorderSide(color: AppColors.white.withOpacity( 0.9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: AppColors.accentRose.withOpacity( 0.45),
          width: 1.2,
        ),
      ),
    );
  }
}
