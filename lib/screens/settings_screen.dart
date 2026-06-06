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
import '../models/app_user.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/custom_reminders_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/language_toggle_button.dart';
import 'custom_reminders_screen.dart';
import 'journal_screen.dart';
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
        // Robustness (app-robustness C): block the whole screen with the shared
        // overlay while an auth op (sign-out / delete account) is in flight, so
        // the user can't re-open a dialog or fire a second submit mid-delete.
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, settingsBody) {
            return BlockingLoadingOverlay(
              isVisible: authProvider.isLoading,
              child: settingsBody!,
            );
          },
          child: SafeArea(
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
                    _OnceEntrance(order: 2, child: _buildMemoriesSection(context)),
                    const SizedBox(height: 18),
                    _OnceEntrance(order: 3, child: _buildAccountSection(context)),
                    const SizedBox(height: 18),
                    _OnceEntrance(order: 4, child: _buildPrivacySection(context)),
                    const SizedBox(height: 18),
                    _OnceEntrance(
                      order: 5,
                      child: _buildDangerZone(
                        context,
                        isUsingFirebase: authProvider.isUsingFirebase,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _OnceEntrance(order: 6, child: _buildSignOutButton(context)),
                    const SizedBox(height: 12),
                    _OnceEntrance(order: 7, child: _buildPrivacyPolicyLink(context)),
                  ],
                ),
              );
            },
          ),
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
              // Daily-question nudge (b2). Independent of the master toggle
              // above — turning milestone reminders off does not silence this.
              const _DailyQuestionReminderTile(),
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
                              settings: const RouteSettings(
                                  name: 'MilestoneReminders'),
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
                        settings: const RouteSettings(name: 'CustomReminders'),
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
                    settings: const RouteSettings(name: 'CustomReminders'),
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
  // Module: Memories — the couple journal entry (feature couple-journal).
  // Placed above "Account & data" per design.
  // ---------------------------------------------------------------------------
  Widget _buildMemoriesSection(BuildContext context) {
    final l10n = context.l10n;

    return _buildSectionCard(
      title: l10n.journalSettingsSection,
      subtitle: l10n.journalScreenSubtitle,
      child: _InkTile(
        borderRadius: 22,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'Journal'),
              builder: (_) => const JournalScreen(),
            ),
          );
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
                  LucideIcons.bookOpen,
                  color: AppColors.accentRose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.journalSettingsTile,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
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
    final currentUser = context.watch<AuthProvider>().currentUser;

    return _buildSectionCard(
      title: l10n.settingsAccountModuleTitle,
      subtitle: l10n.settingsAccountModuleSubtitle,
      child: Column(
        children: [
          if (currentUser != null) ...[
            _buildAccountInfoCard(currentUser, l10n),
            const SizedBox(height: 12),
          ],
          _InkTile(
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
        ],
      ),
    );
  }

  /// Read-only account identity (display name + email) shown atop the account
  /// module so the user can always see which account they're signed in as.
  Widget _buildAccountInfoCard(AppUser user, AppLocalizations l10n) {
    final name = user.displayName.trim();
    final email = user.email.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentRose.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          _buildAccountInfoRow(
            LucideIcons.user,
            l10n.displayNameLabel,
            name.isNotEmpty ? name : '—',
          ),
          if (email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 58),
              child: Divider(
                height: 1,
                color: AppColors.textTertiary.withValues(alpha: 0.18),
              ),
            ),
          if (email.isNotEmpty)
            _buildAccountInfoRow(LucideIcons.mail, l10n.emailLabel, email),
        ],
      ),
    );
  }

  Widget _buildAccountInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentRose.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accentRose, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Module: Privacy & data — usage-analytics opt-out (feature: analytics, D1c).
  // Default ON; toggling off stops collection immediately. No new screen.
  // ---------------------------------------------------------------------------
  Widget _buildPrivacySection(BuildContext context) {
    final l10n = context.l10n;
    return _buildSectionCard(
      title: l10n.privacyPolicyLabel,
      subtitle: l10n.settingsAnalyticsSubtitle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.accentRose.withValues(alpha: 0.10),
          ),
        ),
        child: const _AnalyticsToggleTile(),
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
                // Stale-session challenge — don't dead-end. Collect the password
                // and re-auth + retry the delete in place (#2).
                _showReauthToDeleteDialog(context);
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

  /// Re-auth recovery for the delete-account dead-end (#2). When deletion hits a
  /// stale-session `requires-recent-login`, we collect the password here,
  /// re-authenticate to mint a fresh token, and retry the delete — keeping the
  /// user inside the delete flow instead of stranding them on a snackbar. If the
  /// session is fully gone (`session-gone`) we send them through the auth gate
  /// to sign in again. Uses [StatefulBuilder] for the dialog's local
  /// busy/error state.
  void _showReauthToDeleteDialog(BuildContext context) {
    final l10n = context.l10n;
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var busy = false;
    String? inlineError;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> submit() async {
              if (busy) return;
              if (!(formKey.currentState?.validate() ?? false)) return;
              FocusScope.of(ctx).unfocus();
              setLocalState(() {
                busy = true;
                inlineError = null;
              });

              final authProvider = ctx.read<AuthProvider>();
              final result = await authProvider
                  .reauthenticateAndDeleteAccount(passwordController.text);
              if (!ctx.mounted) return;

              if (result == null) {
                // Deleted — close the dialog and reset to the auth gate.
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.authGate,
                  (route) => false,
                );
                return;
              }

              if (result == 'session-gone') {
                // No local session left to re-auth — send them to sign in again.
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(l10n.deleteAccountSessionExpiredMsg),
                    ),
                  );
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.authGate,
                  (route) => false,
                );
                return;
              }

              // Wrong password / other recoverable error — keep the dialog open
              // and show the message inline under the field.
              HapticFeedback.heavyImpact();
              setLocalState(() {
                busy = false;
                inlineError = result;
              });
            }

            return AlertDialog(
              title: Text(
                l10n.deleteAccountReauthTitle,
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.deleteAccountReauthBody),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      autofocus: true,
                      enabled: !busy,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        errorText: inlineError,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? l10n.passwordRequired
                              : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.deleteAccountConfirmBtn,
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(passwordController.dispose);
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
              final messenger = ScaffoldMessenger.of(context);
              final signedOut = await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              // Robustness (app-robustness B): only navigate on a real sign-out;
              // a genuine failure shows a snackbar instead of a fake navigation.
              if (!signedOut) {
                messenger
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(content: Text(l10n.signOutFailedMsg)),
                  );
                return;
              }
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

    // When the leaving user is the SOLE remaining member (partner already left,
    // or never joined), leaving DESTROYS the couple and ALL shared data with no
    // recovery — warn explicitly. With a partner still present, the partner
    // keeps everything, so the milder copy applies.
    final couple = screenContext.read<CoupleProvider>().couple;
    final isSoleMember = couple != null && couple.memberCount <= 1;

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(isSoleMember
            ? l10n.leaveCoupleDeleteAllTitle
            : l10n.leaveCoupleDialogTitle),
        content: Text(isSoleMember
            ? l10n.leaveCoupleDeleteAllContent
            : l10n.leaveCoupleDialogContent),
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
                // CRITICAL: refresh the in-memory session to the now-single
                // user. Without this the stale currentUser still reports
                // `in_couple` → re-joining is blocked with "This account already
                // belongs to a couple", and the resolver misroutes back to Home.
                await authProvider.updateCurrentUser(updatedUser);
                unawaited(photoProvider.syncForUser(updatedUser));
              } catch (_) {
                return;
              }

              if (!screenContext.mounted) return;

              // Route through the auth gate so SessionResolver clears the couple
              // + love-note / daily-question / reaction / streak watchers for the
              // now-single user (going straight to /setup left them running on
              // the old coupleId) and lands on setup.
              Navigator.of(screenContext).pushNamedAndRemoveUntil(
                AppRoutes.authGate,
                (route) => false,
              );
            },
            child: Text(
              isSoleMember
                  ? l10n.leaveCoupleDeleteAllBtn
                  : l10n.leaveCoupleActionBtn,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// The daily-question reminder control (b2): a switch plus a time row that is
/// only interactive while the switch is on. Independent of the milestone master
/// toggle — it drives [ReminderProvider.setDailyQuestionReminderEnabled] /
/// [setDailyQuestionReminderTime] directly. Permission denial flips the switch
/// back off and surfaces a snackbar.
class _DailyQuestionReminderTile extends StatelessWidget {
  const _DailyQuestionReminderTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.read<ReminderProvider>();
    final enabled = context.select<ReminderProvider, bool>(
      (p) => p.dailyQuestionReminderEnabled,
    );
    final time = context.select<ReminderProvider, TimeOfDay>(
      (p) => p.dailyQuestionReminderTime,
    );

    Future<void> handleToggle(bool value) async {
      HapticFeedback.selectionClick();
      final messenger = ScaffoldMessenger.of(context);
      final granted =
          await provider.setDailyQuestionReminderEnabled(value, l10n: l10n);
      if (value && !granted) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.remindersPermissionDeniedMsg)),
          );
      }
    }

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: time,
      );
      if (picked == null || !context.mounted) {
        return;
      }
      HapticFeedback.selectionClick();
      await provider.setDailyQuestionReminderTime(
        picked.hour,
        picked.minute,
        l10n: l10n,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentRose.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.messageCircle,
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
                      l10n.dailyQuestionReminderTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.dailyQuestionReminderSubtitle,
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
                value: enabled,
                activeThumbColor: AppColors.accentRose,
                onChanged: handleToggle,
              ),
            ],
          ),
          // Time row — only interactive while the nudge is on.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            opacity: enabled ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _InkTile(
                borderRadius: 16,
                onTap: enabled ? pickTime : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        color: AppColors.accentRose,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.dailyQuestionReminderTimeLabel,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        time.format(context),
                        style: const TextStyle(
                          color: AppColors.accentRose,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

/// The usage-analytics opt-out switch (feature: analytics, D1c). Reads/writes
/// [AnalyticsService] directly — analytics state lives in the service (Hive),
/// not a provider, so a small local `setState` mirrors the toggle. Default ON.
class _AnalyticsToggleTile extends StatefulWidget {
  const _AnalyticsToggleTile();

  @override
  State<_AnalyticsToggleTile> createState() => _AnalyticsToggleTileState();
}

class _AnalyticsToggleTileState extends State<_AnalyticsToggleTile> {
  late bool _enabled = AnalyticsService.instance.isEnabled;

  Future<void> _onChanged(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _enabled = value);
    await AnalyticsService.instance.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SwitchListTile.adaptive(
      value: _enabled,
      onChanged: _onChanged,
      activeThumbColor: AppColors.accentRose,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.accentRose.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          LucideIcons.barChart3,
          color: AppColors.accentRose,
          size: 20,
        ),
      ),
      title: Text(
        l10n.settingsAnalyticsTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n.settingsAnalyticsSubtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
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
