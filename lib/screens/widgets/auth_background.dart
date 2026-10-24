import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Soft dreamy mesh — three colored blobs blurred behind auth screens.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _blob(280, AppColors.sunset1.withValues(alpha: 0.28)),
          ),
          Positioned(
            top: 100,
            right: -120,
            child: _blob(320, AppColors.dawn3.withValues(alpha: 0.24)),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _blob(260, AppColors.mint2.withValues(alpha: 0.22)),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
