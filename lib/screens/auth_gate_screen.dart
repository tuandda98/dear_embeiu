import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
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
    final authProvider = context.read<AuthProvider>();
    final coupleProvider = context.read<CoupleProvider>();
    final photoProvider = context.read<PhotoProvider>();
    final navigator = Navigator.of(context);

    if (!authProvider.isInitialized) {
      await authProvider.initialize();
    }

    if (!mounted) {
      return;
    }

    if (!authProvider.isAuthenticated) {
      await photoProvider.clearForSignOut();
      navigator.pushReplacementNamed(AppRoutes.login);
      return;
    }

    final currentUser = authProvider.currentUser;
    await coupleProvider.loadCoupleForUser(currentUser);
    final hasCoupleData = currentUser?.hasCouple == true && coupleProvider.hasCoupleData;

    if (hasCoupleData) {
      await photoProvider.syncForUser(currentUser);
    } else {
      await photoProvider.clearForSignOut();
    }

    if (!mounted) {
      return;
    }

    navigator.pushReplacementNamed(
      hasCoupleData ? AppRoutes.home : AppRoutes.setup,
    );
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

