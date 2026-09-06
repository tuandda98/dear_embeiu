import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// B6 — Tinted icon squircle for tile leadings (design-unify, 2026-06-11).
///
/// Canonicalizes the pattern repeated ≥20 times across settings / milestone /
/// profile tiles: a squircle filled with `tint.withValues(alpha: .12)` and a
/// 20px icon in the tint color.
///
/// Tokens (A7): default 44×44, radius 16, icon 20. Smaller in-tile chips use
/// 38–42 / r14 — pass [size]/[radius] (e.g. the Home waiting banner uses
/// 40 / r14 / tintAlpha .10 to stay pixel-identical to its original).
/// Tint rule: pick an accent with real contrast on white — accentRose /
/// accentLavender; `accentGold` (#E8B4D8) fails (~1.8:1) and is banned here.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.tint = AppColors.accentRose,
    this.size = 44,
    this.radius = 16,
    this.iconSize = 20,
    this.tintAlpha = 0.12,
  });

  final IconData icon;
  final Color tint;
  final double size;
  final double radius;
  final double iconSize;

  /// Fill opacity of the tint behind the icon.
  final double tintAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: tintAlpha),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: tint),
      ),
    );
  }
}
