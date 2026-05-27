import 'package:flutter/material.dart';

import '../app/session_resolver.dart';
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
    // Do the real session check here (no artificial delay) and route straight
    // to the destination — so cold start shows just this one branded loader.
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
      body: Container(
        // Dawn gradient — same as authGate/login/home, so this splash dissolves
        // seamlessly into the app. The launch eases sunset (icon + native splash)
        // → dawn (this splash → app); the white heart is the constant thread.
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
