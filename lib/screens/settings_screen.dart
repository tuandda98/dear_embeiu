import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../app/app_urls.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/analytics_service.dart';
import '../services/home_prefs_service.dart';
import '../theme/app_colors.dart';
import '../utils/lunar_calendar.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/content_card.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/feature_tour_sheet.dart';
import '../widgets/icon_badge.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/app_time_picker.dart';
import '../widgets/section_header.dart';
import '../widgets/sub_screen_header.dart';
import 'chat_bg_screen.dart';
import 'counter_bg_screen.dart';
import 'lunar_calendar_screen.dart';
import 'reminders_screen.dart';

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

  // Accounts that should NOT see the "Quản lý dữ liệu" (data management) card —
  // i.e. clear-local-cache / leave-couple / delete-account are hidden for them
  // (user request 2026-06-19). Matched case-insensitively against the signed-in
  // email. Add more emails here if needed.
  static const Set<String> _hideDataManagementEmails = <String>{
    'phuogthao1408@gmail.com',
    // Couple dodaoanhtuan ↔ thaohathao14 (active) — cả hai ẩn card (user
    // 2026-06-20): chủ tài khoản + người ấy đều không thấy quản-lý-dữ-liệu.
    'dodaoanhtuan@gmail.com',
    'thaohathao14@gmail.com',
  };

  // Accounts that DO see the lunar-calendar card (today's lunar date + a
  // mồng-1/ngày-rằm reminder). Account-gated per user request 2026-06-19;
  // matched case-insensitively against the signed-in email.
  static const Set<String> _lunarCalendarEmails = <String>{
    'dodaoanhtuan@gmail.com',
  };

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
            decoration: const BoxDecoration(
              gradient: AppColors.secondaryGradient,
            ),
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
        // Header redesign 2026-06-14: no app bar — SubScreenHeader (back → chip
        // → title → subtitle, all left-aligned at the gutter) leads the scroll
        // body so the chip lines up vertically with the title.
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
            child: Consumer<CoupleProvider>(
              builder: (context, coupleProvider, _) {
                final couple = coupleProvider.couple;
                if (couple == null) {
                  // No couple loaded — nothing to configure yet.
                  return const SizedBox.shrink();
                }
                final authProvider = context.watch<AuthProvider>();
                // Hide the data-management card for specific accounts.
                final email =
                    (authProvider.currentUser?.email ??
                            authProvider.currentEmail ??
                            '')
                        .trim()
                        .toLowerCase();
                final hideDataManagement = _hideDataManagementEmails.contains(
                  email,
                );
                final showLunar = _lunarCalendarEmails.contains(email);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubScreenHeader(
                        badge: l10n.settingsBadge,
                        badgeIcon: IconsaxPlusLinear.setting_2,
                        title: l10n.settingsTitle,
                        subtitle: l10n.settingsHeaderSubtitle,
                      ),
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
                        child: _buildNotificationsSection(context),
                      ),
                      if (showLunar) ...[
                        const SizedBox(height: 24),
                        EntranceReveal(
                          order: 2,
                          child: _buildLunarSection(context),
                        ),
                      ],
                      const SizedBox(height: 24),
                      EntranceReveal(
                        order: 2,
                        child: _buildGeneralSection(context),
                      ),
                      if (!hideDataManagement) ...[
                        const SizedBox(height: 24),
                        EntranceReveal(
                          order: 3,
                          child: _buildDangerZone(
                            context,
                            isUsingFirebase: authProvider.isUsingFirebase,
                          ),
                        ),
                      ],
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
    IconData? trailingIcon = IconsaxPlusLinear.arrow_right_3,
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
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(
              trailingIcon,
              size: trailingIcon == IconsaxPlusLinear.arrow_right_3 ? 24 : 16,
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
                IconsaxPlusLinear.user,
                l10n.displayNameLabel,
                name.isNotEmpty ? name : '—',
              ),
              if (email.isNotEmpty) ...[
                _rowDivider(),
                _buildAccountInfoRow(
                  IconsaxPlusLinear.sms,
                  l10n.emailLabel,
                  email,
                ),
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
        icon: const Icon(IconsaxPlusLinear.logout),
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
  // Group: Notifications — local reminders only (notifications revamp
  // 2026-06-14). Two rows:
  //   1) the daily-question nudge (toggle + multi-time editor, couple-shared);
  //   2) a single entry to the merged "Reminders" screen (milestones + custom).
  // The master reminders toggle is gone (milestones auto-remind), and the
  // per-type push opt-out section was removed (couples always get the push).
  // ---------------------------------------------------------------------------
  Widget _buildNotificationsSection(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.settingsSectionNotifications),
            const SizedBox(height: 12),
            ContentCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                children: [
                  // Daily-question nudge (b2): toggle + multi-time editor.
                  const _DailyQuestionReminderTile(),
                  _rowDivider(),
                  // AI-personalised daily questions (endless-questions,
                  // 2026-09-05): couple-shared opt-in, hidden until paired.
                  const _AiQuestionsTile(),
                  // Single entry to the merged Reminders screen (milestones +
                  // custom). Badge shows how many milestones are on.
                  _navRow(
                    icon: IconsaxPlusLinear.notification_bing,
                    title: l10n.settingsRemindersEntryTitle,
                    subtitle: l10n.settingsRemindersEntrySubtitle,
                    trailing: reminderProvider.enabledMilestoneCount == 0
                        ? null
                        : _countBadge(
                            l10n.remindersV2MilestoneCountBadge(
                              reminderProvider.enabledMilestoneCount,
                            ),
                          ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: 'Reminders'),
                          builder: (_) => const RemindersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Group: Lunar calendar (account-gated, 2026-06-19) — today's lunar date +
  // next mồng-1 / ngày-rằm (Gregorian) + a toggle that schedules the 7/8/9 AM
  // nudges on those days. Only shown for emails in [_lunarCalendarEmails].
  // ---------------------------------------------------------------------------
  Widget _buildLunarSection(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = LunarCalendar.fromSolar(now);
    final upcoming = LunarCalendar.nextOneAndFifteen(now, 4);
    DateTime? nextFirst;
    DateTime? nextFull;
    for (final e in upcoming) {
      if (e.isFirstDay) {
        nextFirst ??= e.date;
      } else {
        nextFull ??= e.date;
      }
    }
    String gdate(DateTime? d) => d == null ? '—' : '${d.day}/${d.month}';

    return Consumer<ReminderProvider>(
      builder: (context, reminder, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.lunarSectionTitle),
            const SizedBox(height: 12),
            ContentCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const IconBadge(IconsaxPlusLinear.moon),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.lunarTodayLabel}: '
                                '${l10n.lunarDateLabel(today.month, today.day)}'
                                ' · ${LunarCalendar.canChiYear(today.year)}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.lunarNextNewMoon}: ${gdate(nextFirst)}'
                                '   ·   '
                                '${l10n.lunarNextFullMoon}: ${gdate(nextFull)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _rowDivider(),
                  SwitchListTile.adaptive(
                    value: reminder.lunarEnabled,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      reminder.setLunarEnabled(v, l10n: l10n);
                    },
                    activeThumbColor: AppColors.accentRose,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    secondary: const IconBadge(
                      IconsaxPlusLinear.notification_bing,
                    ),
                    title: Text(
                      l10n.lunarReminderToggle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.lunarReminderToggleSub,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  _rowDivider(),
                  // Full calendar + day/time editor.
                  _navRow(
                    icon: IconsaxPlusLinear.calendar_1,
                    title: l10n.lunarOpenCalendar,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: 'LunarCalendar'),
                          builder: (_) => const LunarCalendarScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
                          IconsaxPlusLinear.arrow_right_3,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _rowDivider(),
              // Counter-card background picker (2026-06-14): choose which
              // photos may back the Home hero card.
              _navRow(
                icon: IconsaxPlusLinear.gallery,
                title: l10n.settingsCounterBgTitle,
                subtitle: l10n.settingsCounterBgSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: 'CounterBg'),
                      builder: (_) => const CounterBgScreen(),
                    ),
                  );
                },
              ),
              _rowDivider(),
              // Chat-tab background picker (2026-06-18): pick one valid-sized
              // photo to back the conversation instead of the gradient.
              _navRow(
                icon: IconsaxPlusLinear.message,
                title: l10n.settingsChatBgTitle,
                subtitle: l10n.settingsChatBgSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: 'ChatBg'),
                      builder: (_) => const ChatBgScreen(),
                    ),
                  );
                },
              ),
              _rowDivider(),
              // Usage-analytics opt-out (feature: analytics, D1c). Default ON;
              // toggling off stops collection immediately.
              const _AnalyticsToggleTile(),
              _rowDivider(),
              _navRow(
                icon: IconsaxPlusLinear.shield,
                title: l10n.privacyPolicyLabel,
                trailingIcon: IconsaxPlusLinear.export_1,
                onTap: () => launchUrl(
                  Uri.parse(AppUrls.privacyPolicy),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _rowDivider(),
              // "What's new" — replays the version feature tour on demand
              // (feature: onboarding, 2026-09-05).
              _navRow(
                icon: IconsaxPlusLinear.magic_star,
                title: l10n.featureTourSettingsTile,
                subtitle: l10n.featureTourSettingsTileSub,
                onTap: () => FeatureTour.showAll(context),
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
                child: const Icon(
                  IconsaxPlusLinear.trash,
                  color: AppColors.error,
                ),
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

          // Firebase-specific: clear local cache (low severity)
          if (isUsingFirebase) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showClearLocalDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.22),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(IconsaxPlusLinear.eraser, size: 18),
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
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                l10n.localFallbackWarning,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
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
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(IconsaxPlusLinear.logout, size: 18),
              label: Text(l10n.leaveCoupleBtn),
            ),
          ),

          // Divider separating medium vs high severity
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.error.withValues(alpha: 0.15),
                    height: 1,
                  ),
                ),
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
                Expanded(
                  child: Divider(
                    color: AppColors.error.withValues(alpha: 0.15),
                    height: 1,
                  ),
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(IconsaxPlusLinear.trash, size: 18),
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
                  SnackBar(content: Text(l10n.localDataClearedMsg)),
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
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
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
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
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
              final result = await authProvider.reauthenticateAndDeleteAccount(
                passwordController.text,
              );
              if (!ctx.mounted) return;

              if (result == null) {
                // Deleted — close the dialog and reset to the auth gate.
                Navigator.of(ctx).pop();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
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
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
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
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
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
        title: Text(
          isSoleMember
              ? l10n.leaveCoupleDeleteAllTitle
              : l10n.leaveCoupleDialogTitle,
        ),
        content: Text(
          isSoleMember
              ? l10n.leaveCoupleDeleteAllContent
              : l10n.leaveCoupleDialogContent,
        ),
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
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
  }
}

/// The daily-question reminder control (b2): a switch plus, when on, a
/// multi-time editor (notifications revamp 2026-06-14). Each fire time is a
/// rounded chip the user can tap to edit or ✕ to remove; an "Add a time" button
/// (hidden at the 10-time cap) opens the picker to append a new one. Couple-
/// shared: edits sync to the partner via the provider. Permission denial flips
/// the switch back off and surfaces a snackbar. Renders as a bare row (Settings
/// v2): the enclosing group card owns the surface.
class _DailyQuestionReminderTile extends StatelessWidget {
  const _DailyQuestionReminderTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.read<ReminderProvider>();
    final enabled = context.select<ReminderProvider, bool>(
      (p) => p.dailyQuestionReminderEnabled,
    );
    final times = context.select<ReminderProvider, List<TimeOfDay>>(
      (p) => p.dailyQuestionReminderTimes,
    );
    final canAddTime = context.select<ReminderProvider, bool>(
      (p) => p.canAddDailyQuestionTime,
    );
    // On the account that has its own private hourly nudge, the shared
    // daily-question reminders are suppressed entirely — showing a switch that
    // reads ON while nothing is ever scheduled is a lie, so hide the tile
    // (2026-08-09).
    final suppressed = context.select<ReminderProvider, bool>(
      (p) => p.sharedDailyQuestionRemindersSuppressed,
    );
    if (suppressed) {
      return const SizedBox.shrink();
    }
    // The fire times the user can edit (multi-time, 2026-06-19): each row is a
    // time the couple shares; tap to change, ✕ to remove (kept ≥1). On top of
    // these, the provider always fires fixed 21/22/23h end-of-day nudges while
    // today's question isn't answered — surfaced via the hint below.
    final editable = times.isNotEmpty
        ? times
        : const <TimeOfDay>[TimeOfDay(hour: 20, minute: 0)];

    Future<void> handleToggle(bool value) async {
      HapticFeedback.selectionClick();
      final messenger = ScaffoldMessenger.of(context);
      final granted = await provider.setDailyQuestionReminderEnabled(
        value,
        l10n: l10n,
      );
      if (value && !granted) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.remindersPermissionDeniedMsg)),
          );
      }
    }

    // Edit one existing time: re-pick and replace it in the shared list so the
    // provider re-normalizes (sort/de-dupe) and syncs it to the couple.
    Future<void> editTime(int index) async {
      final picked = await showAppTimePicker(
        context,
        initialTime: editable[index],
      );
      if (picked == null || !context.mounted) {
        return;
      }
      HapticFeedback.selectionClick();
      final next = List<TimeOfDay>.of(editable);
      next[index] = picked;
      await provider.setDailyQuestionTimes(next, l10n: l10n);
    }

    Future<void> removeTime(int index) async {
      HapticFeedback.selectionClick();
      await provider.removeDailyQuestionTime(index, l10n: l10n);
    }

    // Add a new time — default the picker to 21:00, a sensible evening slot.
    Future<void> addTime() async {
      final picked = await showAppTimePicker(
        context,
        initialTime: const TimeOfDay(hour: 21, minute: 0),
      );
      if (picked == null || !context.mounted) {
        return;
      }
      HapticFeedback.selectionClick();
      await provider.addDailyQuestionTime(picked, l10n: l10n);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              const IconBadge(IconsaxPlusLinear.messages),
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
          // Fire-times editor + end-of-day hint — only while the nudge is on.
          if (enabled) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < editable.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                child: _DailyQuestionTimeRow(
                  time: editable[i],
                  onTap: () => editTime(i),
                  // Keep at least one time; ✕ appears only with spares.
                  onRemove: editable.length > 1 ? () => removeTime(i) : null,
                ),
              ),
            if (canAddTime)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _DailyQuestionAddTimeRow(onTap: addTime),
              ),
            // End-of-day nudges (21/22/23h) are fixed and not separately
            // toggleable, so say so — otherwise setting one time and receiving up
            // to four notifications looks like a bug (2026-08-09).
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l10n.dailyQuestionReminderEndOfDayHint,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Couple-shared opt-in for AI-personalised daily questions (feature
/// endless-questions, 2026-09-05). The flag lives on `prefs/home` so BOTH
/// phones see the same question — hence the confirmation dialog before turning
/// it on (it changes what the partner sees too). Turning it OFF is immediate.
/// Hidden until the couple is active: with no partner there are no shared
/// answers to personalise from. Bare row — the group card owns the surface.
class _AiQuestionsTile extends StatefulWidget {
  const _AiQuestionsTile();

  @override
  State<_AiQuestionsTile> createState() => _AiQuestionsTileState();
}

class _AiQuestionsTileState extends State<_AiQuestionsTile> {
  final HomePrefsService _prefs = HomePrefsService();

  /// Optimistic value so the switch doesn't lag the round-trip; the stream
  /// (couple-shared truth) overrides it on the next emission.
  bool? _pending;
  int _toggleSeq = 0;

  Future<void> _handleToggle(String coupleId, bool value) async {
    final l10n = context.l10n;
    HapticFeedback.selectionClick();

    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            l10n.aiQuestionsDialogTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(l10n.aiQuestionsDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.aiQuestionsDialogConfirm,
                style: const TextStyle(
                  color: AppColors.accentRose,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _pending = value);
    final seq = ++_toggleSeq;
    AnalyticsService.instance.logEvent(
      'ai_questions_toggle',
      params: <String, Object?>{'enabled': value},
    );
    final ok = await _prefs.setAiQuestionsEnabled(coupleId, value);
    // A newer toggle superseded this one — its handler owns `_pending` now.
    if (seq != _toggleSeq) {
      return;
    }
    if (!ok && mounted) {
      // Rejected (rules not deployed / offline): don't lie with an ON switch.
      setState(() => _pending = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.aiQuestionsSaveFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // One stream per couple — creating it inside build would re-subscribe the
  // Firestore listener on every rebuild.
  Stream<bool>? _enabledStream;
  String? _enabledStreamCoupleId;

  Stream<bool> _streamFor(String coupleId) {
    if (_enabledStreamCoupleId != coupleId || _enabledStream == null) {
      _enabledStreamCoupleId = coupleId;
      _enabledStream = _prefs.watchAiQuestionsEnabled(coupleId);
    }
    return _enabledStream!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final couple = context.watch<CoupleProvider>().couple;
    if (couple == null || couple.isWaitingForPartner) {
      return const SizedBox.shrink();
    }
    final coupleId = couple.id;

    return StreamBuilder<bool>(
      stream: _streamFor(coupleId),
      builder: (context, snapshot) {
        // Remote wins once it lands; until then show the optimistic value.
        final remote = snapshot.data;
        if (remote != null && remote == _pending) {
          _pending = null;
        }
        final enabled = _pending ?? remote ?? false;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const IconBadge(IconsaxPlusLinear.magicpen),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aiQuestionsTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.aiQuestionsSubtitle,
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
                    onChanged: (value) => _handleToggle(coupleId, value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 58),
              child: Divider(
                height: 1,
                color: AppColors.textTertiary.withValues(alpha: 0.18),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One editable fire-time row for the daily-question nudge (multi-time,
/// 2026-06-19): tap the row to change the time, tap ✕ to remove it (shown only
/// when [onRemove] is non-null, i.e. more than one time remains). Soft rose
/// surface so it groups with the switch above.
class _DailyQuestionTimeRow extends StatelessWidget {
  const _DailyQuestionTimeRow({
    required this.time,
    required this.onTap,
    this.onRemove,
  });

  final TimeOfDay time;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentRose.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: AppColors.accentRose.withValues(alpha: 0.08),
              highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.clock,
                      size: 18,
                      color: AppColors.accentRose,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        time.format(context),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onRemove != null)
            InkResponse(
              onTap: onRemove,
              radius: 22,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(4, 14, 14, 14),
                child: Icon(
                  IconsaxPlusLinear.close_circle,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The "Add a time" row for the daily-question nudge (multi-time, 2026-06-19):
/// a soft rose tile that opens the time picker to append a new fire time.
/// Hidden by the caller once the cap is reached.
class _DailyQuestionAddTimeRow extends StatelessWidget {
  const _DailyQuestionAddTimeRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.accentRose.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const Icon(
                IconsaxPlusLinear.add_circle,
                size: 18,
                color: AppColors.accentRose,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.dailyQuestionReminderAddTime,
                style: const TextStyle(
                  color: AppColors.accentRose,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
      secondary: const IconBadge(IconsaxPlusLinear.chart_2),
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
