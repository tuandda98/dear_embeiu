import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Soft pastels with vibrant accents
  static const Color primaryGradientStart = Color(0xFFFFB6C1); // Light pink
  static const Color primaryGradientEnd = Color(0xFFDDA0DD); // Plum

  static const Color secondaryGradientStart = Color(0xFFFFC0CB); // Pink
  static const Color secondaryGradientEnd = Color(0xFFE6B3FF); // Lavender

  // Accent colors
  static const Color accentRose = Color(0xFFFF69B4); // Hot pink
  static const Color accentCoral = Color(0xFFFF7F50); // Coral
  static const Color accentGold = Color(0xFFFFD700); // Gold

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Background colors
  static const Color bgLight = Color(0xFFFAF9F7);
  static const Color bgDark = Color(0xFFFAF9F7);
  static const Color surfaceLight = Color(0xFFFFEEF5); // Light rose tint

  // Status colors
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryGradientStart, secondaryGradientEnd],
  );

  static const LinearGradient counterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentRose, accentCoral],
  );
}

