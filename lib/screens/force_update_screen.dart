import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_urls.dart';
import '../l10n/l10n.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/eyebrow_chip.dart';

/// Full-screen "you must update" gate (feature force-update). Shown when
/// [SessionResolver] resolves to [AppRoutes.forceUpdate] because this build is
/// below the server's `minBuildNumber`.
///
/// It is a dead end on purpose: [PopScope] with `canPop: false` blocks the
/// system back gesture, and there is no other navigation — the only way out is
/// the store. The destination URL comes from [AppUpdateService.storeUrl]
/// (resolved during the gate check), falling back to the [AppUrls] constants.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _openStore() async {
    HapticFeedback.selectionClick();
    final resolved = AppUpdateService.instance.storeUrl;
    final target = (resolved != null && resolved.isNotEmpty)
        ? resolved
        : (Platform.isIOS ? AppUrls.iosStore : AppUrls.androidStore);
    if (target.isEmpty) {
      return;
    }
    await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        IconsaxPlusLinear.magic_star,
                        size: 42,
                        color: AppColors.accentLove,
                      ),
                    ),
                    const SizedBox(height: 24),
                    EyebrowChip(
                      label: l10n.forceUpdateBadge,
                      icon: IconsaxPlusLinear.arrow_circle_up,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.forceUpdateTitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.pageTitleStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.forceUpdateBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openStore,
                        child: Text(l10n.forceUpdateButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
