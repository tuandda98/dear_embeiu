import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// B7 — Rounded ripple overlay for decorated tiles (design-unify, 2026-06-11).
///
/// Extracted from settings' private `_InkTile`: the tile keeps its own
/// background/border (passed as [child]); this overlays a transparent
/// [Material] + [InkWell] clipped to [borderRadius] so the ripple renders
/// above the fill colour and stays inside the rounded corners. A null [onTap]
/// disables interaction (and the ripple) without changing layout.
///
/// Tokens (A8 ripple rule): splash rose .08 on light surfaces (the old
/// settings copy used .12 — .08 is the unified value), highlight love .06.
/// Every tappable tile must ripple — no bare GestureDetectors.
class InkTile extends StatelessWidget {
  const InkTile({
    super.key,
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              splashColor: AppColors.accentRose.withValues(alpha: 0.08),
              highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}
