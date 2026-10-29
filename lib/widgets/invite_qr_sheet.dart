import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app/app_urls.dart';
import '../l10n/l10n.dart';
import '../providers/reminder_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'content_card.dart';

/// Invite QR sheet (feature pairing-funnel, PF7): the partner points their
/// Camera at it and lands on the get page with the invite code ready. Opened
/// from the "QR code" pill next to Copy / Share ([InviteActionButtons]) and on
/// the Home waiting card. Callers only offer it when there is a code.
class InviteQrSheet extends StatelessWidget {
  const InviteQrSheet._(this.code);

  final String code;

  /// Opening the QR counts as sending the invite: logs `invite_shared` with
  /// method `qr` (never the code) and drops the +2h follow-up (PF10).
  static Future<void> show(BuildContext context, {required String code}) {
    AnalyticsService.instance.logInviteShared('qr');
    context.read<ReminderProvider>().markInviteShared(code);
    return showModalBottomSheet<void>(
      context: context,
      routeSettings: const RouteSettings(name: 'InviteQrSheet'),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteQrSheet._(code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InviteSheetFrame(
      children: [
        const SizedBox(height: 18),
        Text(
          l10n.inviteQrTitle,
          textAlign: TextAlign.center,
          style: AppTheme.displaySerif(
            size: 20,
            weight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.inviteQrBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        // 220 QR + 20 padding: the white card runs into the white sheet, so the
        // quiet zone around the code is wide enough without a border.
        Center(
          child: SizedBox(
            width: 260,
            child: ContentCard(
              child: Semantics(
                image: true,
                label: l10n.inviteQrSemantics(code),
                excludeSemantics: true,
                child: QrImageView(
                  data: AppUrls.inviteLink(code),
                  size: 220,
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.textPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          code,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.accentLoveDeep,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.inviteQrFallback,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inviteQrDone),
        ),
      ],
    );
  }
}

/// The standard bottom-sheet frame (white, top r28, 40×4 handle) shared by the
/// invite sheets: this QR sheet and the clipboard suggestion on Setup. Scrolls
/// inside 90% of the screen so the largest text size never overflows.
class InviteSheetFrame extends StatelessWidget {
  const InviteSheetFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // Bottom inset comes from the SafeArea below — don't add it twice.
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
