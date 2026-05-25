import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _continueToApp();
  }

  Future<void> _continueToApp() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.authGate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
        child: Center(
          child: Column(
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
          ),
        ),
      ),
    );
  }
}
