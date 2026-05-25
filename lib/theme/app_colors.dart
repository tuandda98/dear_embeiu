import 'package:flutter/material.dart';

class AppColors {
  // ---------------------------------------------------------------------------
  // Sunset Romance — hero gradient (warm pink → soft coral)
  static const Color sunset1 = Color(0xFFFF6B9D);
  static const Color sunset2 = Color(0xFFFF8FA3);
  static const Color sunset3 = Color(0xFFFFB6C1);

  // Dawn Blush — secondary gradient (pink → lavender)
  static const Color dawn1 = Color(0xFFFFC1CC);
  static const Color dawn2 = Color(0xFFE8B4D8);
  static const Color dawn3 = Color(0xFFC8A8E9);

  // Dreamy Mint — milestone/celebration (blush → lilac → mint)
  static const Color mint1 = Color(0xFFFFD6E0);
  static const Color mint2 = Color(0xFFE0D4F7);
  static const Color mint3 = Color(0xFFC6E5D9);

  // ---------------------------------------------------------------------------
  // Accents
  static const Color accentLove = Color(0xFFFF4D6D);     // primary heart accent
  static const Color accentLoveDeep = Color(0xFFE63956); // active state
  static const Color accentLavender = Color(0xFFA78BFA); // secondary accent

  // Backwards-compat aliases (so existing screens keep compiling).
  static const Color accentRose = accentLove;
  static const Color accentCoral = sunset2;
  static const Color accentGold = Color(0xFFE8B4D8); // re-purposed to dawn pink

  // ---------------------------------------------------------------------------
  // Surfaces
  static const Color bgLight = Color(0xFFFAFAFC);     // app background
  static const Color bgDark = Color(0xFFFAFAFC);
  static const Color surfaceLight = Color(0xFFF5F0F5); // section divider tint
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color galleryBackground = Color(0xFFF5F0F5);
  static const Color galleryGradientStart = mint1;
  static const Color galleryGradientEnd = mint2;

  // Backwards-compat aliases for hero gradient stops referenced by widgets
  static const Color primaryGradientStart = sunset1;
  static const Color primaryGradientEnd = sunset3;
  static const Color secondaryGradientStart = dawn1;
  static const Color secondaryGradientEnd = dawn3;

  // ---------------------------------------------------------------------------
  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);   // deep navy-black
  static const Color textSecondary = Color(0xFF6B6B7B);
  static const Color textTertiary = Color(0xFFA0A0B0);
  static const Color textOnGradient = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Neutral / utility
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A2E);

  // ---------------------------------------------------------------------------
  // Status
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFFA78BFA); // lavender, design-aligned

  // ---------------------------------------------------------------------------
  // Gradients
  static const LinearGradient sunsetRomance = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunset1, sunset2, sunset3],
  );

  static const LinearGradient dawnBlush = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dawn1, dawn2, dawn3],
  );

  static const LinearGradient dreamyMint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mint1, mint2, mint3],
  );

  // Backwards-compat aliases used across screens
  static const LinearGradient primaryGradient = sunsetRomance;
  static const LinearGradient secondaryGradient = dawnBlush;
  static const LinearGradient counterGradient = sunsetRomance;
  static const LinearGradient galleryGradient = dreamyMint;

  // Soft pink shadow for diffused, hue-matched depth
  static BoxShadow softCardShadow({double opacity = 0.12}) => BoxShadow(
        color: sunset1.withOpacity( opacity),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );
}
