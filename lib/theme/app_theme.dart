import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Typography — Quicksand (bundled in assets/fonts, declared in pubspec.yaml,
  // 2026-06-10). One family for the WHOLE app: rounded terminals carry the
  // soft "mịn màng nhẹ nhàng" brand feel; full Vietnamese stacked-tone
  // diacritics (ấ ề ộ ữ …). Bundled (not fetched at runtime) so there is no
  // first-launch font flash and diacritics render identically offline + on iOS.
  //   Display / hero  → heavy weights (w700; w800 resolves to the Bold file)
  //   Body / UI       → regular / medium (w400/w500)
  // (Previous family Be Vietnam Pro stays bundled for a cheap rollback.)
  static const String fontFamily = 'Quicksand';
  static TextStyle get _displayBase => const TextStyle(fontFamily: fontFamily);
  static TextStyle get _bodyBase => const TextStyle(fontFamily: fontFamily);

  static const double cardRadius = 28;
  static const double pillRadius = 999;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    textTheme: _buildTextTheme(),
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
        fontFamily: fontFamily,
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
          fontFamily: fontFamily,
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
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentLove,
        textStyle: const TextStyle(
          fontFamily: fontFamily,
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
      contentTextStyle: const TextStyle(
        fontFamily: fontFamily,
        color: AppColors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Typography helpers
  //
  // displaySerif() keeps its historical name (called across the app) but now
  // resolves to Be Vietnam Pro at a heavy display weight — the romantic "hero"
  // role is carried by weight + size + tracking rather than a serif family.
  static TextStyle displaySerif({
    double size = 72,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    FontStyle style = FontStyle.normal,
    double height = 1.02,
    double letterSpacing = -1.0,
  }) {
    return _displayBase.copyWith(
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
      // Display — the day count is the hero
      displayLarge: displaySerif(size: 72, height: 1, letterSpacing: -1.2),
      displayMedium: displaySerif(size: 56, height: 1.02, letterSpacing: -0.8),
      displaySmall: displaySerif(size: 40, height: 1.05, letterSpacing: -0.6),

      // Headlines — slightly lighter than the hero, still confident
      headlineLarge: displaySerif(
        size: 32,
        weight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.4,
      ),
      headlineMedium: displaySerif(
        size: 26,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
      ),
      headlineSmall: displaySerif(
        size: 22,
        weight: FontWeight.w600,
        height: 1.25,
      ),

      // Titles for UI
      titleLarge: _bodyBase.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
      titleMedium: _bodyBase.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: _bodyBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),

      // Body
      bodyLarge: _bodyBase.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: _bodyBase.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: _bodyBase.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.45,
      ),

      labelLarge: _bodyBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      labelMedium: _bodyBase.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      ),
      labelSmall: _bodyBase.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 0.6,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable text styles for screen eyebrows / titles on gradient surfaces.
  //
  // Header ink (design-unify vòng 4, 2026-06-11): header type is NAVY
  // [AppColors.textPrimary] by default — white-on-dawnBlush only measured
  // ~1.7:1 even with a dark drop shadow (real screenshots: text sank into the
  // bright end of the gradient). The pink gradient carries the brand; the ink
  // carries the reading (SumOne treatment). White text remains legal ONLY on
  // dark scrims/photos (CounterCard, Profile hero, photo overlays, deep
  // gradient pills, bottom nav) — those callers pass `color: AppColors.white`
  // explicitly and still get the dark drop shadow below.
  //
  // The shadow is applied only while [shadowed] is true AND the color is
  // white — the navy default never ships a shadow, so dark-on-light usages
  // stay clean.

  /// Title-sized drop shadow (≈ black .32, blur 10) — Home greeting spec.
  static const List<Shadow> _pageTitleShadows = [
    Shadow(color: Color(0x52000000), blurRadius: 10, offset: Offset(0, 1)),
  ];

  /// Small-type drop shadow (≈ black .28, blur 8) for eyebrows/subtitles.
  static const List<Shadow> _pageSmallShadows = [
    Shadow(color: Color(0x47000000), blurRadius: 8, offset: Offset(0, 1)),
  ];

  static List<Shadow>? _onGradientShadows(
    bool shadowed,
    Color color,
    List<Shadow> shadows,
  ) {
    return (shadowed && color == AppColors.white) ? shadows : null;
  }

  static TextStyle pageEyebrowStyle({
    Color color = AppColors.textPrimary,
    double alpha = 0.55,
    bool shadowed = true,
  }) {
    return _bodyBase.copyWith(
      color: color.withValues(alpha: alpha),
      // 11 matches the a11y floor used for nav labels — the Home eyebrow now
      // carries real content (today's date), not just a static label.
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      height: 1,
      shadows: _onGradientShadows(shadowed, color, _pageSmallShadows),
    );
  }

  static TextStyle pageTitleStyle({
    Color color = AppColors.textPrimary,
    bool shadowed = true,
    // Sub-screens use 28 (header redesign 2026-06-14 — back+chip moved onto the
    // app bar, the title sits just below it and reads cleaner a touch smaller);
    // landing/auth heroes keep 32.
    double fontSize = 32,
  }) {
    return _displayBase.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.05,
      shadows: _onGradientShadows(shadowed, color, _pageTitleShadows),
    );
  }

  static TextStyle pageSubtitleStyle({
    Color color = AppColors.textPrimary,
    double alpha = 0.62,
    bool shadowed = true,
  }) {
    return _bodyBase.copyWith(
      color: color.withValues(alpha: alpha),
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.05,
      shadows: _onGradientShadows(shadowed, color, _pageSmallShadows),
    );
  }

  static TextStyle sectionTitleStyle({Color color = AppColors.textPrimary}) {
    return _displayBase.copyWith(
      color: color,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.15,
    );
  }

  static TextStyle sectionSubtitleStyle({
    Color color = AppColors.textSecondary,
    double alpha = 1.0,
  }) {
    return _bodyBase.copyWith(
      color: color.withValues(alpha: alpha),
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.03,
    );
  }

  // Hero day-count numerals — large, heavy, used on gradient cards.
  static TextStyle dayCountStyle({Color color = AppColors.white}) {
    return _displayBase.copyWith(
      color: color,
      fontSize: 76,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: -1.6,
      shadows: [
        Shadow(
          color: Colors.white.withValues(alpha: 0.45),
          blurRadius: 28,
        ),
      ],
    );
  }
}
