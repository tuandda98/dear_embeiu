import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// B3 — Header action icon (design-unify 2026-06-11; bare-icon redesign the
/// same day).
///
/// Renders the BARE glyph in a 44×44 touch target with a rounded ripple. The
/// original frosted white squircle (gradient fill + hairline border + rose
/// shadow) was dropped app-wide per user 2026-06-11 ("để hình cái bánh răng
/// thôi, bỏ cái badge màu trắng đi") — headers now carry just dark ink on the
/// gradient, same as the page titles.
///
/// Rules:
/// - This is the standard back button (`IconsaxPlusLinear.arrow_left`) + header
///   action for every screen.
/// - Icon-on-PHOTO overlays (e.g. the Profile hero pencil) keep their backing
///   disc — bare ink has no guaranteed contrast on user images.
/// - When used as an `AppBar.leading`, set `leadingWidth: 60` so the 44px
///   target isn't squeezed (see [subScreenAppBar]).
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.semanticsLabel,
    this.size = 44,
    this.radius = 16,
    this.iconSize = 24,
    this.iconColor = AppColors.textPrimary,
    this.backed = false,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Accessibility label (e.g. `l10n.back`). The icon itself is excluded from
  /// semantics so screen readers announce only this.
  final String? semanticsLabel;

  /// Touch-target side (unchanged at 44 — only the visual box was removed).
  final double size;
  final double radius;
  final double iconSize;
  final Color iconColor;

  /// Icon-on-PHOTO mode: bare ink has no guaranteed contrast over user images
  /// (a dark photo swallows navy ink), so the glyph rides the SAME frosted
  /// light disc as [EyebrowChip] — white .72 fill + white .65 hairline + rose
  /// lift. Reads on both dark and light photos. Off by default (gradient
  /// headers stay bare ink, per the 2026-06-11 redesign).
  final bool backed;

  @override
  Widget build(BuildContext context) {
    final core = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: backed ? const CircleBorder() : null,
        clipBehavior: backed ? Clip.antiAlias : Clip.none,
        child: InkWell(
          borderRadius: backed ? null : BorderRadius.circular(radius),
          customBorder: backed ? const CircleBorder() : null,
          splashColor: AppColors.accentRose.withValues(alpha: 0.08),
          highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticsLabel,
      button: true,
      excludeSemantics: semanticsLabel != null,
      onTap: onTap,
      child: backed
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.72),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.white.withValues(alpha: 0.65)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentRose.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: core,
            )
          : core,
    );
  }
}
