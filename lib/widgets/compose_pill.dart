import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';

/// B8 — Tap-to-compose pill (design-unify, 2026-06-11).
///
/// Upgraded (2026-06-15): gradient border, trailing chevron affordance, subtle
/// breathing pulse on the quiet (unanswered) variant.
///
/// Variants:
/// - Default (quiet): white fill, gradient border, textSecondary label + pulse.
/// - [emphasized]: rose tint fill, stronger border, accentLoveDeep label.
class ComposePill extends StatelessWidget {
  const ComposePill({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = IconsaxPlusLinear.edit_2,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final fill = emphasized
        ? AppColors.accentLove.withValues(alpha: 0.08)
        : AppColors.cardSurface;
    final textColor =
        emphasized ? AppColors.accentLoveDeep : AppColors.textSecondary;
    final iconColor =
        emphasized ? AppColors.accentLoveDeep : AppColors.accentRose;

    Widget pill = _GradientBorder(
      emphasized: emphasized,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(14.5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.accentRose.withValues(alpha: 0.08),
          highlightColor: AppColors.accentLove.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 17, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  IconsaxPlusLinear.arrow_right_2,
                  size: 16,
                  color: emphasized
                      ? AppColors.accentLoveDeep
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Quiet state: gentle breathing pulse to invite the first tap.
    if (!emphasized) {
      pill = pill
          .animate(onPlay: (c) => c.repeat(reverse: true), delay: 600.ms)
          .scaleXY(
            end: 1.018,
            duration: 1600.ms,
            curve: Curves.easeInOut,
          );
    }

    return pill;
  }
}

// ─── Gradient border wrapper ───────────────────────────────────────────────────

class _GradientBorder extends StatelessWidget {
  const _GradientBorder({required this.child, required this.emphasized});

  final Widget child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: emphasized
              ? [
                  AppColors.accentLove.withValues(alpha: 0.70),
                  AppColors.sunset3.withValues(alpha: 0.80),
                ]
              : [
                  AppColors.sunset1.withValues(alpha: 0.45),
                  AppColors.sunset3.withValues(alpha: 0.30),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: child,
        ),
      ),
    );
  }
}
