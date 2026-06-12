import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
import '../services/analytics_service.dart';
import '../services/notification_settings_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/content_card.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/icon_badge.dart';
import '../widgets/ink_tile.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/section_header.dart';
import '../widgets/sub_screen_app_bar.dart';
import 'custom_reminders_screen.dart';
import 'milestone_reminders_screen.dart';

/// The app-wide Settings screen (feature: settings — v2 redesign 2026-06-11).
///
/// Settings is the CONTROL ROOM: controls only, no content. The structure is a
/// flat grouped list (iOS-style): a bare [SectionHeader] per group, ONE
/// [ContentCard] per group, rows separated by hairline dividers — no
/// card-in-card nesting. Groups: Account (identity + sign-out) → Notifications
/// (local reminders + push types merged) → General (language / analytics /
/// privacy policy) → danger zone → version footer.
///
/// The journal entry and edit-story tile moved to the Profile tab (memory
/// chest / hero tap-to-edit — Profile v2); every remaining control keeps its
/// original logic (permission flows, force-open gate, danger dialogs).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Drives the SHARED blocking overlay during the leave-couple teardown. A local
  // flag (not a provider flag) so the overlay stays up CONTINUOUSLY across the
  // whole sequence (leaveCouple → updateCurrentUser → sync) with no dead gap.
  bool _leaving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Leave-couple teardown: show the SAME full-screen transition loader the
    // app uses while routing (SessionRouteScreen minimal — opaque gradient +
    // white spinner). It fully covers Settings (no peek-through) and matches the
    // very next screen (authGate → SessionResolver), so the handoff is seamless
    // with no flash and the loader looks identical to the rest of the app.
    if (_leaving) {
      // Lock the system back button so the teardown can't be interrupted
      // (popping mid-leave would strand the user on a stale screen).
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.secondaryGradient),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.white),
                  const SizedBox(height: 16),
                  Text(
                    l10n.leavingCouple,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Header vòng 5: Settings carries the landing-style large header
        // (EyebrowChip + pageTitle in the body below) — the bar keeps only the
        // back squircle. Behaviour (maybePop) unchanged.
        appBar: subScreenAppBar(context),
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
                      // Landing-style page header — chip + large title, no
                      // subtitle (v2: same trim as Profile).
                      EyebrowChip(
                        label: l10n.settingsBadge,
                        icon: LucideIcons.settings,
                      ),
                      const SizedBox(height: 14),
                      Text(l10n.settingsTitle,
                          style: AppTheme.pageTitleStyle()),
                      const SizedBox(height: 20),
                      // Account first: "who am I signed in as" orients every
                      // control below (standard OS-settings order).
                      EntranceReveal(
                        order: 0,
                        child: _buildAccountSection(context),
                      ),
                      const SizedBox(height: 24),
                      EntranceReveal(
                        order: 1,
                        child: _buildNotificationsSection(
                          context,
                          couple: couple,
                          lastPhotoDate: lastPhotoDate,
                        ),
                      ),
                      const SizedBox(height: 24),
                      EntranceReveal(
                        order: 2,
                        child: _buildGeneralSection(context),
                      ),
                      const SizedBox(height: 24),
                      EntranceReveal(
                        order: 3,
                        child: _buildDangerZone(
                          context,
                          isUsingFirebase: authProvider.isUsingFirebase,
                        ),
                      ),
                      // Sign-out closes the page — the universal settings
                      // convention: scan order runs frequent → rare → leave.
                      const SizedBox(height: 18),
                      EntranceReveal(
                        order: 4,
                        child: _buildSignOutButton(context),
                      ),
                      const SizedBox(height: 14),
                      EntranceReveal(order: 4, child: _buildVersionFooter()),
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
  // Shared row primitives for the flat grouped list.
  // ---------------------------------------------------------------------------

  /// Hairline between rows, indented past the icon column (same treatment the
  /// old account-info card used).
  Widget _rowDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 58),
      child: Divider(
        height: 1,
        color: AppColors.textTertiary.withValues(alpha: 0.18),
      ),
    );
  }

  /// One settings row: icon squircle + title (+subtitle), optional trailing
  /// widget (count badge…) and trailing icon. Ripples when tappable.
  Widget _navRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    IconData? trailingIcon = LucideIcons.chevronRight,
    VoidCallback? onTap,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(
              trailingIcon,
              size: trailingIcon == LucideIcons.chevronRight ? 24 : 16,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
        child: row,
      ),
    );
  }

  /// Rose pill with a count, used by the milestone / custom-reminder rows.
  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentRose.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.accentRose,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Group: Account — read-only identity card only ("who am I signed in as").
  // Sign-out is NOT here: exit actions close the page (bottom, after the
  // danger zone) per the universal settings convention (user 2026-06-11).
  // ---------------------------------------------------------------------------
  Widget _buildAccountSection(BuildContext context) {
    final l10n = context.l10n;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final name = currentUser?.displayName.trim() ?? '';
    final email = currentUser?.email.trim() ?? '';

    if (currentUser == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.settingsSectionAccount),
        const SizedBox(height: 12),
        ContentCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            children: [
              _buildAccountInfoRow(
                LucideIcons.user,
                l10n.displayNameLabel,
                name.isNotEmpty ? name : '—',
              ),
              if (email.isNotEmpty) ...[
                _rowDivider(),
                _buildAccountInfoRow(LucideIcons.mail, l10n.emailLabel, email),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Sign-out as a real BUTTON (design-unify C12/B10 token: pill r999 h52,
  /// textPrimary ink + white .72 fill so it reads on the blush gradient).
  Widget _buildSignOutButton(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showSignOutDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.60)),
          backgroundColor: AppColors.white.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
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

  /// Read-only account identity row (label over value).
  Widget _buildAccountInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconBadge(icon),
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
  // Group: Notifications — the old "Reminders" and "Notification types"
  // sections merged: users think by TOPIC ("what does this app ping me about"),
  // not by mechanism (local vs push). The push toggles sit under a micro-caps
  // sub-label inside the same card. All behaviour is unchanged: master-toggle
  // permission flow, custom lock-step (D7), milestone dim-when-off, force-open
  // gate (Dv6), per-type device-doc refresh.
  // ---------------------------------------------------------------------------
  Widget _buildNotificationsSection(
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.settingsSectionNotifications),
            const SizedBox(height: 12),
            ContentCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                children: [
                  // Master reminders toggle.
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const IconBadge(LucideIcons.bell),
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
                  _rowDivider(),
                  // Daily-question nudge (b2). Independent of the master toggle
                  // above — turning milestone reminders off does not silence it.
                  const _DailyQuestionReminderTile(),
                  _rowDivider(),
                  // Milestones & anniversaries entry (Reminders v2). Dimmed and
                  // non-interactive while the master toggle is off.
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    opacity: settings.enabled ? 1 : 0.45,
                    child: _navRow(
                      icon: LucideIcons.partyPopper,
                      title: l10n.remindersV2MilestoneEntryTitle,
                      subtitle: l10n.remindersV2MilestoneEntrySubtitle,
                      trailing: reminderProvider.enabledMilestoneCount == 0
                          ? null
                          : _countBadge(
                              l10n.remindersV2MilestoneCountBadge(
                                reminderProvider.enabledMilestoneCount,
                              ),
                            ),
                      onTap: settings.enabled
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  settings: const RouteSettings(
                                      name: 'MilestoneReminders'),
                                  builder: (_) =>
                                      const MilestoneRemindersScreen(),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                  _rowDivider(),
                  // Our reminders (custom) entry — force-open gate (Dv6).
                  Consumer<CustomRemindersProvider>(
                    builder: (context, customProvider, _) => _navRow(
                      icon: LucideIcons.calendarClock,
                      title: l10n.customRemindersEntryTitle,
                      subtitle: l10n.customRemindersEntrySubtitle,
                      trailing: customProvider.count == 0
                          ? null
                          : _countBadge('${customProvider.count}'),
                      onTap: () {
                        if (settings.enabled) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              settings:
                                  const RouteSettings(name: 'CustomReminders'),
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
                    ),
                  ),
                  // Push types (feature notifications, D-notif-4): photo /
                  // reaction / daily-question, mutable on THIS device. Love
                  // note + partner joined/left are always-on (too important)
                  // so they're not listed. Muting only silences the push — the
                  // type still logs to the notification center.
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 2),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        l10n.settingsPushGroupLabel.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const _NotificationTypeToggles(),
                ],
              ),
            ),
          ],
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
  // Group: General — language, analytics opt-out (D1c) and the privacy-policy
  // link (promoted from the old 12px footer link: a compliance touchpoint
  // should be findable, not decorative).
  // ---------------------------------------------------------------------------
  Widget _buildGeneralSection(BuildContext context) {
    final l10n = context.l10n;
    final current = currentAppLanguage(context.watch<LocaleProvider>().locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.settingsSectionGeneral),
        const SizedBox(height: 12),
        ContentCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            children: [
              // Language row — leading shows the current language code.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showLanguagePicker(context),
                  splashColor: AppColors.accentRose.withValues(alpha: 0.08),
                  highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
              ),
              _rowDivider(),
              // Usage-analytics opt-out (feature: analytics, D1c). Default ON;
              // toggling off stops collection immediately.
              const _AnalyticsToggleTile(),
              _rowDivider(),
              _navRow(
                icon: LucideIcons.shield,
                title: l10n.privacyPolicyLabel,
                trailingIcon: LucideIcons.externalLink,
                onTap: () => launchUrl(
                  Uri.parse(AppUrls.privacyPolicy),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Danger zone (unchanged — compliance-sensitive block, three severity tiers).
  // ---------------------------------------------------------------------------
  Widget _buildDangerZone(
    BuildContext context, {
    required bool isUsingFirebase,
  }) {
    final l10n = context.l10n;

    // Card surface → solid-white ContentCard (design-unify C12/B4); structure
    // and the error palette of everything inside stay as-is.
    return ContentCard(
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

  /// Quiet brand + version footer — the standard place users (and we, when
  /// debugging) look the build number up.
  Widget _buildVersionFooter() {
    return Center(
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          if (info == null) {
            return const SizedBox(height: 16);
          }
          return Text(
            'Dear Embeiu · v${info.version} (${info.buildNumber})',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          );
        },
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
            onPressed: () {
              Navigator.pop(dialogContext);
              _performLeaveCouple(screenContext);
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

  /// Runs the leave-couple teardown behind the SHARED full-screen blocking
  /// overlay ([BlockingLoadingOverlay] — same loader as sign-out / delete
  /// account, driven here by [_leaving]). The server-side teardown (callable
  /// `leaveCoupleCleanup` doing a recursive delete + a possible Cloud Function
  /// cold start) plus the session refresh can take a few seconds; the overlay
  /// covers the WHOLE sequence (leaveCouple → updateCurrentUser → photo sync)
  /// continuously so the screen never looks frozen, and failures surface a
  /// snackbar instead of being swallowed.
  Future<void> _performLeaveCouple(BuildContext screenContext) async {
    final l10n = screenContext.l10n;
    final authProvider = screenContext.read<AuthProvider>();
    final coupleProvider = screenContext.read<CoupleProvider>();
    final photoProvider = screenContext.read<PhotoProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    setState(() => _leaving = true);

    try {
      final updatedUser = await coupleProvider.leaveCouple(
        currentUser: currentUser,
      );
      // CRITICAL: refresh the in-memory session to the now-single user. Without
      // this the stale currentUser still reports `in_couple` → re-joining is
      // blocked with "This account already belongs to a couple", and the
      // resolver misroutes back to Home.
      await authProvider.updateCurrentUser(updatedUser);
      unawaited(photoProvider.syncForUser(updatedUser));
    } catch (_) {
      if (!mounted) return;
      // Drop the overlay and tell the user it failed (was silently swallowed
      // before — leaving felt like a no-op).
      setState(() => _leaving = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(coupleProvider.errorMessage ?? l10n.leaveCoupleError),
          ),
        );
      return;
    }

    if (!mounted) return;

    // Keep the overlay up through the navigation: route through the auth gate so
    // SessionResolver clears the couple + love-note / daily-question / reaction
    // / streak watchers for the now-single user (going straight to /setup left
    // them running on the old coupleId) and lands on setup. The destination
    // shows its own loader, so we hand off without a flash.
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.authGate,
      (route) => false,
    );
  }
}

/// The daily-question reminder control (b2): a switch plus a time row that is
/// only interactive while the switch is on. Independent of the milestone master
/// toggle — it drives [ReminderProvider.setDailyQuestionReminderEnabled] /
/// [setDailyQuestionReminderTime] directly. Permission denial flips the switch
/// back off and surfaces a snackbar. Renders as a bare row (Settings v2): the
/// enclosing group card owns the surface.
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              const IconBadge(LucideIcons.messageCircle),
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
              child: InkTile(
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
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      secondary: const IconBadge(LucideIcons.barChart3),
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

/// Per-type push mute switches (feature notifications, D-notif-4). Reads/writes
/// [NotificationSettingsService] (Hive) then re-registers the device doc so the
/// Cloud Functions fan-out honours the change. Default ON for all three; muting
/// only silences the PUSH — the type still logs to the notification center.
class _NotificationTypeToggles extends StatefulWidget {
  const _NotificationTypeToggles();

  @override
  State<_NotificationTypeToggles> createState() =>
      _NotificationTypeTogglesState();
}

class _NotificationTypeTogglesState extends State<_NotificationTypeToggles> {
  Map<String, bool> _prefs = {
    for (final k in NotificationSettingsService.allKeys) k: true,
  };
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await NotificationSettingsService.instance.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loaded = true;
    });
  }

  Future<void> _onChanged(String prefKey, bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _prefs = {..._prefs, prefKey: value});
    await NotificationSettingsService.instance.set(prefKey, value);
    // Mirror to the device doc so the CF stops/starts sending this type.
    await PushNotificationService.instance.refreshDeviceRegistration();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _tile(
          icon: LucideIcons.image,
          title: l10n.settingsNotifTypePhoto,
          subtitle: l10n.settingsNotifTypePhotoSubtitle,
          prefKey: NotificationSettingsService.keyPhoto,
        ),
        _tile(
          icon: LucideIcons.heart,
          title: l10n.settingsNotifTypeReaction,
          subtitle: l10n.settingsNotifTypeReactionSubtitle,
          prefKey: NotificationSettingsService.keyReaction,
        ),
        _tile(
          icon: LucideIcons.messageCircle,
          title: l10n.settingsNotifTypeDailyQuestion,
          subtitle: l10n.settingsNotifTypeDailyQuestionSubtitle,
          prefKey: NotificationSettingsService.keyDailyQuestion,
        ),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String prefKey,
  }) {
    return SwitchListTile.adaptive(
      value: _prefs[prefKey] ?? true,
      onChanged: _loaded ? (v) => _onChanged(prefKey, v) : null,
      activeThumbColor: AppColors.accentRose,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      secondary: IconBadge(icon),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
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
