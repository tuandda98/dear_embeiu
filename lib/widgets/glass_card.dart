import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A real glassmorphism surface: clips its bounds, blurs whatever sits behind
/// it ([BackdropFilter]), then layers a translucent white fill plus a soft
/// white highlight border on top.
///
/// This replaces the "fake glass" (flat translucent [Container]) used across
/// the auth/main screens — adopt it screen-by-screen in a later pass.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppTheme.cardRadius,
    this.blur = 18,
    this.fillAlpha = 0.16,
    this.borderAlpha = 0.32,
    this.borderColor,
    this.padding = const EdgeInsets.all(20),
  });

  /// Content rendered on top of the glass surface.
  final Widget child;

  /// Corner radius of the glass tile. Defaults to the design-system card radius.
  final double borderRadius;

  /// Backdrop blur sigma (both axes).
  final double blur;

  /// Opacity of the white fill layer.
  final double fillAlpha;

  /// Opacity of the highlight border.
  final double borderAlpha;

  /// Border tint. Defaults to the white highlight; pass an accent (e.g. for an
  /// "unread" emphasis) to ring the tile in that colour instead.
  final Color? borderColor;

  /// Inner padding around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: fillAlpha),
            borderRadius: radius,
            border: Border.all(
              color: (borderColor ?? AppColors.white).withValues(alpha: borderAlpha),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
