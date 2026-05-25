import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Font families — using system fallbacks; swap to google_fonts/DM Serif
  // Display + Inter after `flutter pub get` is healthy.
  static const String _displayFontFamily = 'serif';
  static const List<String> _displayFallback = <String>['serif', 'Times'];
  static const String? _bodyFontFamily = null; // platform default sans
  static const List<String> _bodyFallback = <String>[
    'Inter',
    'SF Pro Text',
    'Manrope',
    'Roboto',
  ];

  static const double cardRadius = 28;
  static const double pillRadius = 999;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _bodyFontFamily,
    fontFamilyFallback: _bodyFallback,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentLove,
      onPrimary: AppColors.white,
      secondary: AppColors.accentLavender,
      onSecondary: AppColors.white,
      surface: AppColors.bgLight,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgLight,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentLove,
      foregroundColor: AppColors.white,
      elevation: 0,
      shape: CircleBorder(),
    ),
    textTheme: _buildTextTheme(),
    cardTheme: CardThemeData(
      color: AppColors.cardSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.accentLove, width: 1.4),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textPrimary, // dark navy pill
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentLove,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.accentLove, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentLove,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceLight,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Typography helpers
  static TextStyle displaySerif({
    double size = 72,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    FontStyle style = FontStyle.normal,
    double height = 1.02,
    double letterSpacing = -1.2,
  }) {
    return TextStyle(
      fontFamily: _displayFontFamily,
      fontFamilyFallback: _displayFallback,
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Serif display — the day count is the hero
      displayLarge: displaySerif(size: 72, height: 1, letterSpacing: -1.5),
      displayMedium: displaySerif(size: 56, height: 1.02, letterSpacing: -1.2),
      displaySmall: displaySerif(size: 40, height: 1.05, letterSpacing: -0.8),

      // Serif headlines, lighter weight to feel romantic
      headlineLarge: displaySerif(
        size: 32,
        weight: FontWeight.w500,
        height: 1.15,
        letterSpacing: -0.4,
      ),
      headlineMedium: displaySerif(
        size: 26,
        weight: FontWeight.w500,
        height: 1.2,
        letterSpacing: -0.2,
      ),
      headlineSmall: displaySerif(
        size: 22,
        weight: FontWeight.w500,
        height: 1.25,
      ),

      // Sans titles for UI
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),

      // Sans body
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.45,
      ),

      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 0.6,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable text styles for screen eyebrows / titles on gradient surfaces
  static TextStyle pageEyebrowStyle({
    Color color = AppColors.white,
    double alpha = 0.92,
  }) {
    return TextStyle(
      color: color.withOpacity( alpha),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      height: 1,
    );
  }

  static TextStyle pageTitleStyle({Color color = AppColors.white}) {
    return TextStyle(
      fontFamily: _displayFontFamily,
      fontFamilyFallback: _displayFallback,
      color: color,
      fontSize: 32,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
      height: 1.05,
    );
  }

  static TextStyle pageSubtitleStyle({
    Color color = AppColors.white,
    double alpha = 0.82,
  }) {
    return TextStyle(
      color: color.withOpacity( alpha),
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.05,
    );
  }

  static TextStyle sectionTitleStyle({Color color = AppColors.textPrimary}) {
    return TextStyle(
      fontFamily: _displayFontFamily,
      fontFamilyFallback: _displayFallback,
      color: color,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.2,
      height: 1.15,
    );
  }

  static TextStyle sectionSubtitleStyle({
    Color color = AppColors.textSecondary,
    double alpha = 1.0,
  }) {
    return TextStyle(
      color: color.withOpacity( alpha),
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.03,
    );
  }

  // Hero day-count numerals — large serif, used on gradient cards.
  static TextStyle dayCountStyle({Color color = AppColors.white}) {
    return TextStyle(
      fontFamily: _displayFontFamily,
      fontFamilyFallback: _displayFallback,
      color: color,
      fontSize: 76,
      fontWeight: FontWeight.w500,
      height: 1,
      letterSpacing: -2.4,
      shadows: [
        Shadow(
          color: Colors.white.withOpacity( 0.45),
          blurRadius: 28,
        ),
      ],
    );
  }
}
