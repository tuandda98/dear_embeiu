import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// B12 — Eyebrow chip (header-sync vòng 5, 2026-06-11).
///
/// The boxed eyebrow is back by user request, recolored for the navy-ink era:
/// the original chip was frosted white .12 with white text (≈1.7:1 on blush),
/// this one sits on the same "light surface + navy ink" family as
/// [HeaderIconButton] / the language pill / the gallery month chip:
/// - pill fill white .72 + white .65 hairline + soft rose lift shadow,
/// - label 11 w700 ls1.4 navy .70 (≥4.5:1 on the white surface),
/// - optional leading icon in deep rose (decorative brand pop).
///
/// One widget for every screen header so the chips can never drift apart
/// again. Used above the page title (12–14 gap), never inside content cards.
class EyebrowChip extends StatelessWidget {
  const EyebrowChip({
    super.key,
    this.label,
    this.icon,
    this.child,
    this.minHeight,
  }) : assert(
         label != null || child != null,
         'EyebrowChip needs a label or a custom child',
       );

  final String? label;
  final IconData? icon;

  /// Optional minimum pill height. When set, the pill grows to this height with
  /// its content centred (vertical padding collapses) — used by the chat header
  /// so the name chip stands exactly as tall as the 44px back disc beside it.
  final double? minHeight;

  /// Custom chip content replacing the icon+label row (same pill shell) —
  /// e.g. the chat tab's dynamic couple names with the pulsing heart. Style
  /// the content with [AppTheme.pageEyebrowStyle] yourself to stay on token.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final content =
        child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: AppColors.accentLoveDeep),
              const SizedBox(width: 7),
            ],
            Text(label!, style: AppTheme.pageEyebrowStyle(alpha: 0.70)),
          ],
        );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: minHeight != null ? 0 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // minHeight: a fixed-height pill whose WIDTH still wraps the content —
      // `Center(widthFactor: 1)` fills the height but shrinks width to the child
      // (no horizontal stretch). NO `alignment` on the Container: that would make
      // it expand to the full available width (user: "wrap content + ở giữa").
      child: minHeight != null
          ? SizedBox(
              height: minHeight,
              child: Center(widthFactor: 1, child: content),
            )
          : content,
    );
  }
}
