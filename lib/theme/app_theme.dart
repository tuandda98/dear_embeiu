import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.accentRose,
      secondary: AppColors.accentCoral,
      surface: AppColors.bgLight,
      background: AppColors.bgLight,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentRose,
      foregroundColor: AppColors.white,
    ),
    textTheme: _buildTextTheme(),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.accentRose,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }

  static TextStyle pageEyebrowStyle({Color color = AppColors.white, double alpha = 0.9}) {
    return TextStyle(
      color: color.withValues(alpha: alpha),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      height: 1,
    );
  }

  static TextStyle pageTitleStyle({Color color = AppColors.white}) {
    return TextStyle(
      color: color,
      fontSize: 31,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1.02,
      shadows: color == AppColors.white
          ? [
              Shadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }

  static TextStyle pageSubtitleStyle({Color color = AppColors.white, double alpha = 0.8}) {
    return TextStyle(
      color: color.withValues(alpha: alpha),
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.55,
      letterSpacing: 0.02,
    );
  }

  static TextStyle sectionTitleStyle({Color color = AppColors.white}) {
    return TextStyle(
      color: color,
      fontSize: 19,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.38,
      height: 1.08,
    );
  }

  static TextStyle sectionSubtitleStyle({Color color = AppColors.white, double alpha = 0.8}) {
    return TextStyle(
      color: color.withValues(alpha: alpha),
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.48,
      letterSpacing: 0.02,
    );
  }
}

