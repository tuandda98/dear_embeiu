import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
/// - leading = [HeaderIconButton] with `LucideIcons.arrowLeft` 20 textPrimary
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
/// [title] is optional: pass null for screens that carry a large in-body
/// header (EyebrowChip + pageTitle, e.g. Settings) — the bar then renders
/// just the back squircle (+ actions).
PreferredSizeWidget subScreenAppBar(
  BuildContext context, {
  String? title,
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
          icon: LucideIcons.arrowLeft,
          semanticsLabel: context.l10n.back,
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
    ),
    centerTitle: true,
    title: title == null
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
          ),
    actions: actions,
  );
}
