import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'header_icon_button.dart';

/// B2 — Standard sub-screen AppBar (design-unify, 2026-06-11).
///
/// One header pattern for every pushed screen (journal, history, settings,
/// notification center, milestone/custom reminders…), replacing the three
/// back-button variants (rose chevron / bare chevron / glass GestureDetector):
/// - transparent + flat (the [ScreenBackground] gradient shows through),
/// - leading = [HeaderIconButton] with `IconsaxPlusLinear.arrow_left` 20 textPrimary
///   in the 44 r16 white squircle, semantics `l10n.back`,
/// - centered title 18 w800 NAVY [AppColors.textPrimary], no shadow — header
///   ink final (vòng 4, 2026-06-11): the white+shadow round failed contrast
///   on real screenshots (~1.7:1 on the bright end of dawnBlush); the pink
///   gradient carries the brand, dark ink carries the reading,
/// - `leadingWidth: 60` so the 44px disc isn't squeezed (16 gutter + 44).
///
/// [onBack] defaults to `Navigator.maybePop`. Pass [actions] for trailing
/// header buttons (prefer [HeaderIconButton] there too).
///
/// Header redesign 2026-06-14 (user "back ngang chip + title gọn"): pass [chip]
/// (an [EyebrowChip]) to render the screen's eyebrow LEFT-aligned right next to
/// the back squircle on the same fixed bar — the page title + subtitle then sit
/// just below it in the body (`AppTheme.pageTitleStyle(fontSize: 28)`). This
/// replaces the old "back alone on the bar + chip/title floating in the body
/// with a gap" layout and makes every sub-screen header identical.
///
/// [title] (legacy centered text) is still supported for any bar that wants a
/// plain centred title; [chip] takes precedence and is left-aligned. With
/// neither, the bar is just the back squircle (+ actions).
PreferredSizeWidget subScreenAppBar(
  BuildContext context, {
  String? title,
  Widget? chip,
  List<Widget>? actions,
  VoidCallback? onBack,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    leadingWidth: 60,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Center(
        child: HeaderIconButton(
          icon: IconsaxPlusLinear.arrow_left,
          semanticsLabel: context.l10n.back,
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
    ),
    // chip → left-aligned & hugging the back button (titleSpacing 0); else the
    // legacy centred text title.
    centerTitle: chip == null,
    titleSpacing: chip == null ? null : 0,
    title: chip ??
        (title == null
            ? null
            : Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              )),
    actions: actions,
  );
}
