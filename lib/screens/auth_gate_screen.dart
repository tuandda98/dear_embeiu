import 'package:flutter/material.dart';

import '../app/session_resolver.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    // Shared with SplashScreen — single source of truth for "where to go next".
    // Reused after login / register / logout to re-resolve the destination.
    final navigator = Navigator.of(context);
    final route = await SessionResolver.resolveStartRoute(context);

    if (!mounted) {
      return;
    }

    navigator.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
        child: Center(
          child: Column(
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
          ),
        ),
      ),
    );
  }
}

