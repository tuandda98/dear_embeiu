import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../l10n/l10n.dart';
import '../providers/reminder_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import 'invite_qr_sheet.dart';

/// Reusable "Copy | Share | QR code" action cluster shown next to the invite
/// code on the Setup card and the Profile invite tile (the Home waiting card
/// has its own full-width share CTA + tonal pills). Feature: invite-sharing
/// (Phase 1), QR pill added by pairing-funnel (PF7).
///
/// A [Wrap], so the three pills drop to a second line on narrow columns (the
/// Profile tile on a 375pt phone) instead of overflowing.
///
/// Two background variants (token-identical, only alpha/colour differs):
/// - [onDark] `true` (default, unused today): glass/dark surfaces -> white pills.
/// - [onDark] `false` (Setup, Profile): light surface -> rose pills, navy label.
///
/// [iconOnly] renders compact icon-only pills whose tooltip is also the screen
/// reader label.
///
/// Every action counts as "invite sent" for the follow-up nudges (PF10).
class InviteActionButtons extends StatelessWidget {
  const InviteActionButtons({
    super.key,
    required this.code,
    this.onDark = true,
    this.iconOnly = false,
  });

  /// The invite code to copy / embed in the share message.
  final String code;

  /// Background variant: glass/dark (true) vs light/rose (false).
  final bool onDark;

  /// Render compact icon-only pills (with tooltip) instead of icon + label.
  final bool iconOnly;

  void _handleCopy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    // Analytics — `invite_shared` (the code value itself is NEVER logged).
    AnalyticsService.instance.logInviteShared('copy');
    context.read<ReminderProvider>().markInviteShared(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.inviteCodeCopiedMsg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    final message = context.l10n.inviteShareMessage(code);
    // iPad/macOS require a popover origin or the share sheet crashes.
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? (box.localToGlobal(Offset.zero) & box.size)
        : null;
    // Analytics — `invite_shared` via the OS share sheet (no code logged).
    AnalyticsService.instance.logInviteShared('share_sheet');
    context.read<ReminderProvider>().markInviteShared(code);
    try {
      await SharePlus.instance.share(
        ShareParams(text: message, sharePositionOrigin: origin),
      );
    } catch (_) {
      // Share sheet failures are rare and OS-driven; stay silent (no error
      // toast) to avoid noise, per design.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconColor =
        onDark ? AppColors.white.withValues(alpha: 0.90) : AppColors.accentRose;
    // Navy label on the light variant: rose on rose .12 was only 2.8:1.
    final labelColor =
        onDark ? AppColors.white.withValues(alpha: 0.90) : AppColors.textPrimary;
    final pillColor = onDark
        ? AppColors.white.withValues(alpha: 0.18)
        : AppColors.accentRose.withValues(alpha: 0.12);
    final rippleColor = onDark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.accentRose.withValues(alpha: 0.08);

    Widget pill(IconData icon, String label, VoidCallback onTap) => _Pill(
          icon: icon,
          label: label,
          iconOnly: iconOnly,
          iconColor: iconColor,
          labelColor: labelColor,
          pillColor: pillColor,
          rippleColor: rippleColor,
          fontWeight: onDark ? FontWeight.w600 : FontWeight.w700,
          onTap: onTap,
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        pill(IconsaxPlusLinear.copy, l10n.copyBtn, () => _handleCopy(context)),
        pill(
          IconsaxPlusLinear.share,
          l10n.shareBtn,
          () => _handleShare(context),
        ),
        pill(
          IconsaxPlusLinear.scan_barcode,
          l10n.inviteQrBtn,
          () => InviteQrSheet.show(context, code: code),
        ),
      ],
    );
  }
}

/// One pill: a 36-high rounded shape inside a 48×48 tap target
/// (`MaterialTapTargetSize.padded`), with the button role screen readers need.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.iconOnly,
    required this.iconColor,
    required this.labelColor,
    required this.pillColor,
    required this.rippleColor,
    required this.fontWeight,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool iconOnly;
  final Color iconColor;
  final Color labelColor;
  final Color pillColor;
  final Color rippleColor;
  final FontWeight fontWeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final ripple = WidgetStatePropertyAll<Color>(rippleColor);
    final glyph = Icon(icon, size: 14, color: iconColor);

    if (iconOnly) {
      return IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: glyph,
        style: IconButton.styleFrom(
          backgroundColor: pillColor,
          fixedSize: const Size(36, 36),
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          shape: shape,
          tapTargetSize: MaterialTapTargetSize.padded,
        ).copyWith(overlayColor: ripple),
      );
    }

    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: pillColor,
        foregroundColor: labelColor,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: shape,
        tapTargetSize: MaterialTapTargetSize.padded,
      ).copyWith(overlayColor: ripple),
      icon: glyph,
      label: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
