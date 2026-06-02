import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../app/app_urls.dart';
import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/custom_reminders_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/language_toggle_button.dart';
import 'custom_reminders_screen.dart';
import 'milestone_reminders_screen.dart';
import 'setup_screen.dart';

/// The app-wide Settings screen (feature: settings).
///
/// Gathers the controls that previously lived scattered across the Profile
/// screen into structured modules: reminders, language and account & data.
/// The behaviour of every moved control is unchanged — only its location is —
/// so the reminders toggle/permission flow, language picker, danger zone
/// (clear cache / leave couple / delete account), edit-story, sign-out and the
/// privacy link all keep their original logic.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.chevronLeft,
              color: AppColors.accentRose,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            l10n.settingsTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Consumer2<CoupleProvider, PhotoProvider>(
            builder: (context, coupleProvider, photoProvider, _) {
              final couple = coupleProvider.couple;
              if (couple == null) {
                // No couple loaded — nothing to configure yet.
                return const SizedBox.shrink();
              }
              final authProvider = context.watch<AuthProvider>();
              final lastPhotoDate = photoProvider.sortedPhotos.isEmpty
                  ? null
                  : photoProvider.sortedPhotos.first.uploadDate;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OnceEntrance(
                      order: 0,
                      child: _buildRemindersSection(
                        context,
                        couple: couple,
                        lastPhotoDate: lastPhotoDate,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _OnceEntrance(order: 1, child: _buildLanguageSection(context)),
                    const SizedBox(height: 18),
                    _OnceEntrance(order: 2, child: _buildAccountSection(context)),
                    const SizedBox(height: 18),
                    _OnceEntrance(
                      order: 3,
                      child: _buildDangerZone(
                        context,
                        isUsingFirebase: authProvider.isUsingFirebase,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _OnceEntrance(order: 4, child: _buildSignOutButton(context)),
                    const SizedBox(height: 12),
                    _OnceEntrance(order: 5, child: _buildPrivacyPolicyLink(context)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Module: Reminders (moved from ProfileScreen, behaviour unchanged).
  // The standalone "Reminder time" tile is dropped here — the time now lives in
  // the milestone screen as the "Default time" (Dv8).
  // ---------------------------------------------------------------------------
  Widget _buildRemindersSection(
    BuildContext context, {
    required Couple couple,
    required DateTime? lastPhotoDate,
  }) {
    final l10n = context.l10n;

    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, _) {
        final settings = reminderProvider.settings;

        final customReminders = context.read<CustomRemindersProvider>();

        Future<void> handleToggle(bool value) async {
          HapticFeedback.selectionClick();
          final granted = await reminderProvider.setEnabled(
            value,
            anniversaryDate: couple.anniversaryDate,
            lastPhotoDate: lastPhotoDate,
            l10n: l10n,
          );
          // Keep custom reminders in lock-step with the global toggle (D7):
          // turning reminders off cancels every custom schedule; turning them
          // back on (permission granted) re-arms them.
          if (value && granted) {
            await customReminders.rescheduleAllEnabled();
          } else if (!value) {
            await customReminders.cancelAllSchedules();
          }
          if (!granted && context.mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(content: Text(l10n.remindersPermissionDeniedMsg)),
              );
          }
        }

        return _buildSectionCard(
          title: l10n.settingsRemindersModuleTitle,
          subtitle: l10n.settingsRemindersModuleSubtitle,
          child: Column(
            children: [
              // Master toggle.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.accentRose.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.bell,
                        color: AppColors.accentRose,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.remindersToggleLabel,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.remindersToggleDesc,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: settings.enabled,
                      activeThumbColor: AppColors.accentRose,
                      onChanged: handleToggle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Milestones & anniversaries entry (Reminders v2). Dimmed and
              // non-interactive while the master toggle is off.
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                opacity: settings.enabled ? 1 : 0.45,
                child: _InkTile(
                  borderRadius: 22,
                  onTap: settings.enabled
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MilestoneRemindersScreen(),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.accentRose.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accentRose.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            LucideIcons.partyPopper,
                            color: AppColors.accentRose,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.remindersV2MilestoneEntryTitle,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.remindersV2MilestoneEntrySubtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final count =
                                reminderProvider.enabledMilestoneCount;
                            if (count == 0) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentRose
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.remindersV2MilestoneCountBadge(count),
                                style: const TextStyle(
                                  color: AppColors.accentRose,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Our reminders (custom) entry — force-open gate (Dv6) preserved.
              _InkTile(
                borderRadius: 22,
                onTap: () {
                  if (settings.enabled) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CustomRemindersScreen(),
                      ),
                    );
                  } else {
                    _showForceOpenDialog(
                      context,
                      reminderProvider: reminderProvider,
                      customReminders: customReminders,
                      couple: couple,
                      lastPhotoDate: lastPhotoDate,
                      l10n: l10n,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.accentRose.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accentRose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          LucideIcons.calendarClock,
                          color: AppColors.accentRose,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.customRemindersEntryTitle,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.customRemindersEntrySubtitle,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer<CustomRemindersProvider>(
                        builder: (context, customProvider, _) {
                          if (customProvider.count == 0) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accentRose.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${customProvider.count}',
                              style: const TextStyle(
                                color: AppColors.accentRose,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Force-open gate (Dv6): when the master reminders toggle is off and the
  /// user taps "Our reminders", invite them to turn it on (requesting OS
  /// permission). On grant → re-arm custom schedules + open the custom list; on
  /// deny → close + snackbar; "Later" → just close.
  Future<void> _showForceOpenDialog(
    BuildContext context, {
    required ReminderProvider reminderProvider,
    required CustomRemindersProvider customReminders,
    required Couple couple,
    required DateTime? lastPhotoDate,
    required AppLocalizations l10n,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accentRose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                LucideIcons.bell,
                color: AppColors.accentRose,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.remindersV2ForceOpenTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.remindersV2ForceOpenBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.remindersV2ForceOpenLater,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentLove,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final granted = await reminderProvider.setEnabled(
                true,
                anniversaryDate: couple.anniversaryDate,
                lastPhotoDate: lastPhotoDate,
                l10n: l10n,
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (granted) {
                await customReminders.rescheduleAllEnabled();
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CustomRemindersScreen(),
                  ),
                );
              } else {
                messenger
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(l10n.remindersV2ForceOpenDeniedMsg),
                    ),
                  );
              }
            },
            child: Text(
              l10n.remindersV2ForceOpenConfirm,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Module: Language (moved from ProfileScreen, behaviour unchanged).
  // ---------------------------------------------------------------------------
  Widget _buildLanguageSection(BuildContext context) {
    final l10n = context.l10n;
    final current = currentAppLanguage(context.watch<LocaleProvider>().locale);

    return _buildSectionCard(
      title: l10n.languageTitle,
      subtitle: l10n.languageSubtitle,
      child: _InkTile(
        borderRadius: 22,
        onTap: () => showLanguagePicker(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.accentRose.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: current.code == null
                    ? const Text('🌐', style: TextStyle(fontSize: 20))
                    : Text(
                        current.code!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accentLove,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.languageTitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appLanguageLabel(current, l10n),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Module: Account & data. "Edit our story" tile (moved from the old
  // FilledButton actions section) lives above the danger zone.
  // ---------------------------------------------------------------------------
  Widget _buildAccountSection(BuildContext context) {
    final l10n = context.l10n;

    return _buildSectionCard(
      title: l10n.settingsAccountModuleTitle,
      subtitle: l10n.settingsAccountModuleSubtitle,
      child: _InkTile(
        borderRadius: 22,
        onTap: () {
          final coupleProvider = context.read<CoupleProvider>();
          final currentUser = context.read<AuthProvider>().currentUser;
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const SetupScreen()))
              .then((_) {
            coupleProvider.loadCoupleForUser(currentUser);
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.accentRose.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.pencil,
                  color: AppColors.accentRose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.editOurStoryBtn,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.settingsEditStorySubtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showSignOutDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.60)),
          backgroundColor: AppColors.white.withValues(alpha: 0.22),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const Icon(LucideIcons.logOut),
        label: Text(
          l10n.signOutBtn,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Danger zone (moved from ProfileScreen, behaviour & dialogs unchanged).
  // ---------------------------------------------------------------------------
  Widget _buildDangerZone(
    BuildContext context, {
    required bool isUsingFirebase,
  }) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.trash2, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dataManagementTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.dataManagementDesc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Warning context FIRST — user reads before acting
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.14)),
            ),
            child: Text(
              l10n.clearDataNote,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Firebase-specific: clear local cache (low severity)
          if (isUsingFirebase) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showClearLocalDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.22)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(LucideIcons.eraser, size: 18),
                label: Text(l10n.clearLocalDataBtn),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
              ),
              child: Text(
                l10n.localFallbackWarning,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.45),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Leave Couple (medium severity — outlined)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLeaveCoupleDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.30)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: Text(l10n.leaveCoupleBtn),
            ),
          ),

          // Divider separating medium vs high severity
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.error.withValues(alpha: 0.15), height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    l10n.profileDangerIrreversible,
                    style: TextStyle(
                      color: AppColors.error.withValues(alpha: 0.50),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.error.withValues(alpha: 0.15), height: 1)),
              ],
            ),
          ),

          // Delete Account (highest severity — filled red)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showDeleteAccountDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: Text(
                l10n.deleteAccountBtn,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyLink(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(AppUrls.privacyPolicy),
        mode: LaunchMode.externalApplication,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shield,
              size: 13,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.privacyPolicyLabel,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.externalLink, size: 11, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showClearLocalDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearLocalDialogTitle),
        content: Text(l10n.clearLocalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Future.wait([
                context.read<CoupleProvider>().clearLocalCache(),
                context.read<PhotoProvider>().clearLocalCache(),
              ]);

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.localDataClearedMsg),
                  ),
                );
            },
            child: Text(
              l10n.clearLocalActionBtn,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.deleteAccountDialogTitle,
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800),
        ),
        content: Text(l10n.deleteAccountDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final authProvider = context.read<AuthProvider>();
              final errorCode = await authProvider.deleteAccount();

              if (!context.mounted) return;

              if (errorCode == null) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.authGate,
                  (route) => false,
                );
              } else if (errorCode == 'requires-recent-login') {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(content: Text(l10n.deleteAccountRequiresReloginMsg)),
                  );
              } else {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(content: Text(errorCode)));
              }
            },
            child: Text(
              l10n.deleteAccountConfirmBtn,
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutDialogTitle),
        content: Text(l10n.signOutDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.authGate,
                (route) => false,
              );
            },
            child: Text(l10n.signOutConfirmBtn),
          ),
        ],
      ),
    );
  }

  void _showLeaveCoupleDialog(BuildContext screenContext) {
    final l10n = screenContext.l10n;

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.leaveCoupleDialogTitle),
        content: Text(l10n.leaveCoupleDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = screenContext.read<AuthProvider>();
              final coupleProvider = screenContext.read<CoupleProvider>();
              final photoProvider = screenContext.read<PhotoProvider>();
              final currentUser = authProvider.currentUser;

              Navigator.pop(dialogContext);

              if (currentUser == null) return;

              try {
                final updatedUser = await coupleProvider.leaveCouple(
                  currentUser: currentUser,
                );
                unawaited(photoProvider.syncForUser(updatedUser));
              } catch (_) {
                return;
              }

              if (!screenContext.mounted) return;

              Navigator.of(screenContext).pushNamedAndRemoveUntil(
                AppRoutes.setup,
                (route) => false,
              );
            },
            child: Text(
              l10n.leaveCoupleActionBtn,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tap wrapper that shows a rounded ripple on top of a decorated tile.
///
/// The tile keeps its own background/border (passed as [child]); this overlays
/// a transparent [Material] + [InkWell] clipped to [borderRadius] so the ripple
/// renders above the fill colour and stays inside the rounded corners. A null
/// [onTap] disables interaction (and the ripple) without changing layout.
class _InkTile extends StatelessWidget {
  const _InkTile({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              splashColor: AppColors.accentRose.withValues(alpha: 0.12),
              highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Plays the shared fade+slide entrance once, the first time it is mounted,
/// then keeps rendering its child statically. Because [SettingsScreen]'s body
/// rebuilds whenever its providers change (e.g. toggling reminders), wrapping
/// each section in this guard prevents the entrance from replaying on rebuild.
class _OnceEntrance extends StatefulWidget {
  const _OnceEntrance({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  State<_OnceEntrance> createState() => _OnceEntranceState();
}

class _OnceEntranceState extends State<_OnceEntrance> {
  bool _played = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Mark the entrance finished only after it has fully run (entrance window
    // + this item's stagger delay). Until then we keep the animated child so a
    // mid-animation rebuild doesn't snap it to its static form.
    _timer = Timer(
      AppMotion.entrance + AppMotion.stagger * widget.order,
      () {
        if (mounted) {
          setState(() => _played = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_played) {
      return widget.child;
    }
    return widget.child
        .animate()
        .fadeIn(duration: AppMotion.entrance, curve: AppMotion.curve)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppMotion.entrance,
          curve: AppMotion.curve,
          delay: AppMotion.stagger * widget.order,
        );
  }
}
