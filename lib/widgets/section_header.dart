import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// B5 — In-tab section header (design-unify, 2026-06-11).
///
/// Extracted from Home's `_buildSectionTitle` (`home_screen.dart`): title in
/// [AppTheme.sectionTitleStyle] (22 w700 textPrimary), optional subtitle in
/// [AppTheme.sectionSubtitleStyle] (13 textSecondary, +4 gap), optional
/// trailing action as a [TextButton].
///
/// Rules:
/// - The action link uses [AppColors.textPrimary] w700 14 — NOT
///   accentLoveDeep, which only reaches ~2.7:1 on the blush gradient.
/// - Spacing token: section title → its card = 12 (caller's responsibility).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  /// A widget on the title's row, right-aligned and vertically centred with
  /// it (e.g. Home's constellation pill). The title then stays on ONE line
  /// and scales down on narrow phones (< ~390dp with "Hôm nay của chúng
  /// mình") instead of wrapping under the widget — user asked for the two
  /// to line up (2026-10-12).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(title, style: AppTheme.sectionTitleStyle());
    return Row(
      crossAxisAlignment: trailing != null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (trailing != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: titleText,
                )
              else
                titleText,
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppTheme.sectionSubtitleStyle()),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              // Real ink: even accentLoveDeep only reaches ~2.7:1 on the blush
              // gradient — 14px text needs textPrimary. Weight keeps the
              // link affordance.
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionLabel!),
          ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
