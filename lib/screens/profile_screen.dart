import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/content_card.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/icon_badge.dart';
import '../widgets/invite_action_buttons.dart';
import '../widgets/section_header.dart';
import '../widgets/shared_couple_photo_view.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/streak_sheet.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

/// Profile v2 (redesign 2026-06-11): identity + memory chest + admin gateway.
/// Every number appears exactly once — the daily/live numbers live on Home;
/// this tab holds the static record (hero identity card, journey strip) and
/// the archives (journal / note history / streak) moved here from Home.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<CoupleProvider, PhotoProvider>(
        builder: (context, coupleProvider, photoProvider, _) {
          final authProvider = context.watch<AuthProvider>();
          final currentUser = authProvider.currentUser;
          final isBusy = coupleProvider.isLoading || photoProvider.isLoading;
          final busyMessage = coupleProvider.isLoading
              ? coupleProvider.loadingMessage
              : photoProvider.loadingMessage;

          if (coupleProvider.couple == null) {
            return BlockingLoadingOverlay(
              isVisible: isBusy,
              message: busyMessage,
              child: _buildProfileLoadingSkeleton(context),
            );
          }

          final couple = coupleProvider.couple!;
          final photoCount = photoProvider.photoCount;
          final totalDays = _daysTogether(couple.anniversaryDate);
          final years = totalDays ~/ 365;
          final months = (totalDays % 365) ~/ 30;
          final inviteCode = currentUser?.inviteCode;

          return BlockingLoadingOverlay(
            isVisible: isBusy,
            message: busyMessage,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.secondaryGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(context),
                      const SizedBox(height: 20),
                      _buildHeroCard(context, couple: couple),
                      const SizedBox(height: 18),
                      _buildStatsSection(
                        context,
                        years: years,
                        months: months,
                        totalDays: totalDays,
                        photoCount: photoCount,
                      ),
                      // Memory chest — the archives need a partner to exist;
                      // while waiting, the invite block takes the slot.
                      if (!couple.isWaitingForPartner) ...[
                        const SizedBox(height: 24),
                        _buildMemoryChest(context),
                      ],
                      if (inviteCode != null &&
                          inviteCode.trim().isNotEmpty &&
                          couple.isWaitingForPartner) ...[
                        const SizedBox(height: 18),
                        _buildDetailTile(
                          icon: LucideIcons.keyRound,
                          title: context.l10n.yourInviteCodeLabel,
                          value: inviteCode,
                          tint: AppColors.warning,
                          belowValue: InviteActionButtons(
                            code: inviteCode,
                            onDark: false,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Content-shaped shimmer shown while the couple profile is loading,
  /// mirroring the real layout (header, hero, journey strip, chest tiles).
  Widget _buildProfileLoadingSkeleton(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              ShimmerSkeleton(width: 150, height: 24, borderRadius: 999),
              Spacer(),
              // Bare settings glyph (no squircle box since 2026-06-11).
              ShimmerSkeleton(width: 24, height: 24, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 14),
          const ShimmerSkeleton(width: 220, height: 32, borderRadius: 8),
          const SizedBox(height: 20),
          // Couple hero card (radius 32).
          const ShimmerSkeleton(height: 220, borderRadius: 32),
          const SizedBox(height: 18),
          // "Journey snapshot" section card (2×2 stat grid).
          const ShimmerSkeleton(height: 320, borderRadius: 24),
          const SizedBox(height: 24),
          // Memory chest: section title + one grouped card.
          const ShimmerSkeleton(width: 150, height: 22, borderRadius: 8),
          const SizedBox(height: 12),
          const ShimmerSkeleton(height: 188, borderRadius: 24),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            EyebrowChip(
              label: l10n.loveProfileBadge,
              icon: LucideIcons.sparkles,
            ),
            const Spacer(),
            // Settings entry = ONE squircle at the page's top-right (user
            // 2026-06-11) — replaces the full-width tile that closed the page.
            HeaderIconButton(
              icon: LucideIcons.settings,
              semanticsLabel: l10n.settingsTitle,
              onTap: () => _openSettings(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.profileTitle,
          style: AppTheme.pageTitleStyle(),
        ),
      ],
    );
  }

  void _openSettings(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'Settings'),
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  /// Identity hero: couple photo (or gradient + initials) with the names and
  /// since-date pinned to the bottom. The whole card opens the edit-story
  /// flow — profile is where users expect to edit their profile — with a
  /// pencil disc as the visible affordance.
  Widget _buildHeroCard(BuildContext context, {required Couple couple}) {
    final l10n = context.l10n;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.12),
            blurRadius: 42,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            (couple.couplePhotoPath?.trim().isNotEmpty == true ||
                    couple.couplePhotoUrl?.trim().isNotEmpty == true)
                ? Transform.scale(
                    scale: 1.04,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                      child: SharedCouplePhotoView(
                        localPath: couple.couplePhotoPath,
                        remoteUrl: couple.couplePhotoUrl,
                        fit: BoxFit.cover,
                        // Cover banner → cap at screen width (physical px);
                        // it's blurred so this never costs visible quality.
                        decodeWidth: (MediaQuery.of(context).size.width *
                                MediaQuery.of(context).devicePixelRatio)
                            .round(),
                      ),
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accentRose.withValues(alpha: 0.88),
                          AppColors.primaryGradientEnd.withValues(alpha: 0.94),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials(couple),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.94),
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
            // Soft top-left highlight keeps the photo from reading flat.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.62, -0.86),
                  radius: 1.05,
                  colors: [
                    AppColors.white.withValues(alpha: 0.16),
                    AppColors.accentRose.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.28, 0.78],
                ),
              ),
            ),
            // Bottom scrim so the white identity text always reads.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                  stops: const [0.0, 0.34, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ourStoryBadge,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.72),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedCoupleName(
                    person1Name: couple.person1Name,
                    person2Name: couple.person2Name,
                    creatorUserId: couple.createdByUserId,
                    spacing: 8,
                    runSpacing: 6,
                    heartSize: 26,
                    heartColor: AppColors.white,
                    textStyle: TextStyle(
                      color: AppColors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: -0.7,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.24),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.daysOfUsSince(
                      _formatDate(context, couple.anniversaryDate),
                    ),
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
            // Ripple above the content, below the pencil disc.
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  label: l10n.editOurStoryBtn,
                  child: InkWell(
                    splashColor: AppColors.white.withValues(alpha: 0.12),
                    onTap: () => _openEditStory(context),
                  ),
                ),
              ),
            ),
            // Edit affordance — same visual language as Home's bell disc.
            Positioned(
              top: 14,
              right: 14,
              child: IgnorePointer(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentRose.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.pencil,
                    size: 17,
                    color: AppColors.accentLoveDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditStory(BuildContext context) {
    HapticFeedback.selectionClick();
    final coupleProvider = context.read<CoupleProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'SetupScreen'),
            builder: (_) => const SetupScreen(),
          ),
        )
        .then((_) => coupleProvider.loadCoupleForUser(currentUser));
  }

  /// "Bức tranh hành trình" — the ORIGINAL 2×2 stat grid, restored verbatim
  /// (user 2026-06-11: revert to the pre-redesign version — the journey-strip
  /// takes, both white and tinted, were dropped).
  Widget _buildStatsSection(
    BuildContext context, {
    required int years,
    required int months,
    required int totalDays,
    required int photoCount,
  }) {
    final l10n = context.l10n;

    return _buildSectionCard(
      icon: LucideIcons.sparkles,
      title: l10n.journeySnapshotTitle,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  icon: Icons.favorite_rounded,
                  value: '$years',
                  label: l10n.yearsTogether,
                  color: AppColors.accentRose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  icon: LucideIcons.calendar,
                  value: '$months',
                  label: l10n.monthsRemaining,
                  color: AppColors.accentCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  icon: LucideIcons.calendarDays,
                  value: '$totalDays',
                  label: l10n.totalDaysLabel,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  icon: LucideIcons.image,
                  value: '$photoCount',
                  label: l10n.memoriesSavedLabel,
                  // accentGold (#E8B4D8) is near-invisible on white (~1.8:1) —
                  // lavender keeps the tint family with real contrast (C8).
                  color: AppColors.accentLavender,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section card = solid-white ContentCard (design-unify C8/B4) with the
  // canonical in-card header: Lucide icon 20 rose + title 16 w800 ls-0.2 (A2,
  // same voice as TodayRitualCard headers).
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentRose, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// "Memory chest" — the couple's archives, moved here from the Home ritual
  /// card footer. ONE grouped card with hairline rows (redesign 2026-06-11,
  /// same flat-list language as Settings v2) instead of three bordered tiles.
  Widget _buildMemoryChest(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.profileMemoryChestTitle),
        const SizedBox(height: 12),
        ContentCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            children: [
              _chestRow(
                icon: LucideIcons.bookOpen,
                title: l10n.journalSettingsTile,
                onTap: () => _push(context, const JournalScreen(), 'Journal'),
              ),
              _chestDivider(),
              // "Nhật ký lời nhắn" tile removed (feature chat, D6): the chat
              // tab replaced this entry point — the archive now opens from the
              // history icon on the chat tab's header. Screen + route kept.
              _chestRow(
                icon: LucideIcons.flame,
                title: l10n.profileStreakTile,
                onTap: () {
                  HapticFeedback.selectionClick();
                  StreakSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chestDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 58),
      child: Divider(
        height: 1,
        color: AppColors.textTertiary.withValues(alpha: 0.18),
      ),
    );
  }

  void _push(BuildContext context, Widget screen, String routeName) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => screen,
      ),
    );
  }

  Widget _chestRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        highlightColor: AppColors.accentLove.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              IconBadge(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
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

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    required Color tint,
    Widget? belowValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, tint: tint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                if (belowValue != null) ...[
                  const SizedBox(height: 10),
                  belowValue,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(Couple couple) {
    final first = couple.person1Name.trim().isNotEmpty
        ? couple.person1Name.trim().characters.first.toUpperCase()
        : 'A';
    final second = couple.person2Name.trim().isNotEmpty
        ? couple.person2Name.trim().characters.first.toUpperCase()
        : 'B';
    return '$first$second';
  }

  int _daysTogether(DateTime anniversaryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      anniversaryDate.year,
      anniversaryDate.month,
      anniversaryDate.day,
    );
    return today.difference(start).inDays;
  }

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat(context.l10n.fullDateFormat).format(date);
  }
}
