import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../l10n/l10n.dart';
import 'eyebrow_chip.dart';
import 'header_icon_button.dart';

/// Unified sub-screen header (redesign 2026-06-14 vòng 2, user "chip badge ở
/// giữa và ngang hàng với icon back, xoá header text còn lại").
///
/// A single PINNED row — the eyebrow chip is CENTERED, the back arrow sits at
/// the left gutter on the SAME row, and an optional trailing action sits at the
/// right:
/// ```
/// ←            ✦ EYEBROW CHIP            (optional trailing action)
/// ```
/// The big page title + subtitle were dropped on every sub-screen — the chip
/// alone names the screen. Pin this above the scrolling body
/// (`Column[ header, Expanded(scroll) ]`) so the back never scrolls away.
///
/// [title]/[subtitle] are kept ONLY for call-site compatibility (every screen
/// still passes them) but are no longer rendered. They can be removed in a
/// later sweep once the call sites are cleaned up.
class SubScreenHeader extends StatelessWidget {
  const SubScreenHeader({
    super.key,
    required this.badge,
    required this.badgeIcon,
    this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  /// Eyebrow chip label (e.g. `l10n.settingsBadge`).
  final String badge;
  final IconData badgeIcon;

  /// Deprecated (2026-06-14): no longer rendered — kept for call-site compat.
  final String? title;

  /// Deprecated (2026-06-14): no longer rendered — kept for call-site compat.
  final String? subtitle;

  /// Optional trailing action on the right of the row (Save, x/20 counter,
  /// overflow menu…).
  final Widget? trailing;

  /// Defaults to `Navigator.maybePop`.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered eyebrow chip — the screen's sole title now.
          EyebrowChip(label: badge, icon: badgeIcon),
          // Back arrow at the left gutter, on the same row. -10 so the centred
          // glyph of the 44 touch target lands on the gutter, not indented.
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(-10, 0),
              child: HeaderIconButton(
                icon: IconsaxPlusLinear.arrow_left,
                semanticsLabel: context.l10n.back,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          if (trailing != null)
            Align(
              alignment: Alignment.centerRight,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
