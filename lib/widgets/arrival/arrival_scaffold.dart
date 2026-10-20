import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../sub_screen_header.dart';

/// Shell of every arrival sub-screen (design §4): dawnBlush, `SubScreenHeader`
/// chip "VỀ ĐẾN NHÀ", scrolling content, primary action pinned to the bottom
/// that rides up with the keyboard (body resizes, the bar is part of it).
class ArrivalScaffold extends StatelessWidget {
  const ArrivalScaffold({
    super.key,
    required this.children,
    this.title,
    this.bottom = const [],
  });

  /// 26 w700 question of the screen ("Phòng gym ở đâu?").
  final String? title;
  final List<Widget> children;

  /// Pinned actions, top to bottom (primary first).
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SubScreenHeader(
                  badge: l10n.arrivalBadge,
                  badgeIcon: IconsaxPlusLinear.home_2,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    if (title != null) ...[
                      Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ...children,
                  ],
                ),
              ),
              if (bottom.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < bottom.length; i++) ...[
                        if (i > 0) const SizedBox(height: 4),
                        bottom[i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Body copy 15 w500 navy (on blush; textSecondary fails there, §11).
class ArrivalBody extends StatelessWidget {
  const ArrivalBody(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: muted
          ? AppColors.textPrimary.withValues(alpha: 0.78)
          : AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
  );
}

/// Navy pill h52 (theme ElevatedButton), optional spinner while [busy].
class ArrivalPrimaryButton extends StatelessWidget {
  const ArrivalPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textPrimary,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 18),
          if (busy || icon != null) const SizedBox(width: 8),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// Text button 15 w700 navy, h44 (secondary pinned action / links).
class ArrivalTextButton extends StatelessWidget {
  const ArrivalTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.underline = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool underline;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 44),
      foregroundColor: AppColors.textPrimary,
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        decoration: underline ? TextDecoration.underline : null,
      ),
    ),
  );
}

/// Yellow box: no house number / alley (design §4.5).
class ArrivalWarnBox extends StatelessWidget {
  const ArrivalWarnBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          IconsaxPlusLinear.warning_2,
          size: 16,
          color: AppColors.warningInk,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.warningInk,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

/// White .72 hint box with an info icon (§4.4, §5).
class ArrivalHintBox extends StatelessWidget {
  const ArrivalHintBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          IconsaxPlusLinear.info_circle,
          size: 16,
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
