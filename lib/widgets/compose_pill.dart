import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';

/// B8 — Tap-to-compose pill (design-unify, 2026-06-11).
///
/// Extracted from the TodayRitualCard's `_composePill`: looks like a quiet
/// input, opens a composer (bottom sheet) on tap.
///
/// Tokens:
/// - Radius 16 (the in-card control radius), padding 14×13, icon 17 rose,
///   InkWell splash rose .08.
/// - Quiet variant: [AppColors.surfaceLight] fill + rose .25 border +
///   textSecondary w500 label.
/// - [emphasized] (the unlock CTA): rose .10 fill + rose .30 border +
///   accentLoveDeep w700 label.
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

  /// Rose-tinted call-to-action variant (e.g. "answer to reveal").
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final fill = emphasized
        ? AppColors.accentLove.withValues(alpha: 0.10)
        : AppColors.surfaceLight;
    final border =
        AppColors.accentRose.withValues(alpha: emphasized ? 0.30 : 0.25);
    final textColor =
        emphasized ? AppColors.accentLoveDeep : AppColors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accentRose.withValues(alpha: 0.08),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AppColors.accentRose),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight:
                          emphasized ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
