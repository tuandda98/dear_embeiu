import 'package:flutter/material.dart';

import '../app/app_routes.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: AppColors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Kỷ Niệm Của Chúng Mình',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

