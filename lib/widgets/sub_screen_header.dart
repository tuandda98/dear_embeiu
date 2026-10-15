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
    this.onBackground = false,
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

  /// When the header floats over a dark/photo backdrop (e.g. the Love Tree's
  /// full-bleed night sky) the bare navy back glyph can vanish — set this so it
  /// rides the same frosted white disc as the [EyebrowChip]/trailing actions.
  /// The centered chip is already a white pill, so it stays legible either way.
  final bool onBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      // As AppBar does: back, chip and trailing stay separate semantics nodes.
      // Without it a header that is a list item (Lời nhắc, Những ngày đặc biệt)
      // merged into the item's node: "Quay lại LỜI NHẮC" read as one button.
      child: Semantics(
        explicitChildNodes: true,
        // NavigationToolbar (AppBar's own layout): the chip stays centred while
        // it fits; with large text it is held 6px clear of the back arrow and
        // of a trailing action of any width (x/20 counter, "Lưu") instead of
        // sliding under them (audit R2-c follow-up). 6, not 8: the chip only
        // reacts to a long-press, and 8 would cut "ROCK PAPER SCISSORS" at
        // 320dp ×1.0.
        child: NavigationToolbar(
          middleSpacing: 6,
          // Back arrow at the left gutter, on the same row. The 44 touch
          // target hangs 10px into the gutter so its centred glyph lands on
          // the gutter, not indented; the slot is only the 34px that stays
          // inside the row, so the chip isn't pushed away by space the button
          // doesn't occupy.
          leading: SizedBox(
            width: 34,
            child: OverflowBox(
              maxWidth: 44,
              alignment: Alignment.centerRight,
              child: HeaderIconButton(
                icon: IconsaxPlusLinear.arrow_left,
                semanticsLabel: context.l10n.back,
                backed: onBackground,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          // Centered eyebrow chip — the screen's sole title now, so screen
          // readers get it as a heading, like an AppBar title.
          middle: Semantics(
            header: true,
            child: EyebrowChip(label: badge, icon: badgeIcon),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}
