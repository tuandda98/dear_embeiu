import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// Reusable "Copy | Share" action cluster shown next to the invite code in all
/// three places it appears (Setup card / Home waiting-partner banner / Profile
/// detail tile). Feature: invite-sharing (Phase 1).
///
/// Two background variants (token-identical, only alpha/colour differs):
/// - [onDark] `true` (default): glass/dark surfaces (Setup, Home) -> white pills.
/// - [onDark] `false`: light surface (Profile) -> rose-tinted pills.
///
/// [iconOnly] renders compact icon-only pills with a tooltip label (used in the
/// narrow Home banner).
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

  Color get _fgColor =>
      onDark ? AppColors.white.withValues(alpha: 0.90) : AppColors.accentRose;

  Color get _pillColor => onDark
      ? AppColors.white.withValues(alpha: 0.18)
      : AppColors.accentRose.withValues(alpha: 0.12);

  void _handleCopy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(
          icon: LucideIcons.copy,
          label: l10n.copyBtn,
          iconOnly: iconOnly,
          fgColor: _fgColor,
          pillColor: _pillColor,
          fontWeight: onDark ? FontWeight.w600 : FontWeight.w700,
          onTap: () => _handleCopy(context),
        ),
        const SizedBox(width: 8),
        _Pill(
          icon: LucideIcons.share2,
          label: l10n.shareBtn,
          iconOnly: iconOnly,
          fgColor: _fgColor,
          pillColor: _pillColor,
          fontWeight: onDark ? FontWeight.w600 : FontWeight.w700,
          onTap: () => _handleShare(context),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.iconOnly,
    required this.fgColor,
    required this.pillColor,
    required this.fontWeight,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool iconOnly;
  final Color fgColor;
  final Color pillColor;
  final FontWeight fontWeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: pillColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: iconOnly
              ? const EdgeInsets.all(8)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fgColor),
              if (!iconOnly) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 12,
                    fontWeight: fontWeight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return iconOnly ? Tooltip(message: label, child: pill) : pill;
  }
}
