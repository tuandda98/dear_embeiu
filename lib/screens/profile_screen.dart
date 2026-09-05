import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/streak_provider.dart';
import '../services/daily_question_service.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/content_card.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/blocking_loading_overlay.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/icon_badge.dart';
import '../widgets/ink_tile.dart';
import '../widgets/invite_action_buttons.dart';
import '../widgets/milestone_trail.dart';
import '../widgets/section_header.dart';
import '../widgets/shared_couple_photo_view.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/memories_sheet.dart';
import '../widgets/records_sheet.dart';
import '../widgets/streak_sheet.dart';
import 'care_message_screen.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

/// Profile v2 (redesign 2026-06-11): identity + memory chest + admin gateway.
/// Every number appears exactly once — the daily/live numbers live on Home;
/// this tab holds the static record (hero identity card, journey strip) and
/// the archives (journal / note history / streak) moved here from Home.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.bottomInset = 0, this.onRequestTab});

  final double bottomInset;

  /// Switches the Home shell's bottom-nav tab (e.g. a badge jumping to Gallery).
  final void Function(int index)? onRequestTab;

  @override
  Widget build(BuildContext context) {
    // No nested Scaffold (header unify 2026-06-14): Profile renders straight
    // into the Home shell's Scaffold + SafeArea like the Chat tab. It uses no
    // Scaffold services (SnackBar/FAB) and its bg is transparent, so its own
    // Scaffold was redundant.
    return Consumer2<CoupleProvider, PhotoProvider>(
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
        final totalDays = _daysTogether(couple.anniversaryDate);
        final inviteCode = currentUser?.inviteCode;

        return BlockingLoadingOverlay(
          isVisible: isBusy,
          message: busyMessage,
          // Transparent: the shared dawnBlush bg is painted ONCE by the Home
          // shell behind the tab IndexedStack (bg-unify 2026-06-14), so all 4
          // tabs read identically. A per-tab gradient Container restarted the
          // diagonal at the tab top → a ~60px colour shift vs the Home/Chat
          // tabs (which show the outer container).
          child: SafeArea(
            // Home's shell SafeArea already applied the top inset for every
            // tab, so skip top here (a no-op in portrait) — never double-pad.
            top: false,
            bottom: false,
            // Pinned chip header (header unify 2026-06-14): a fixed top row +
            // an Expanded scroll below, so the chip/settings stay put like the
            // Chat tab. NB: the actual fix that made the top padding EVEN across
            // tabs lives in _buildPageHeader — the header Row uses
            // crossAxisAlignment.start so the 44px settings icon doesn't
            // vertically-centre (and thus push down) the shorter chip.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildPageHeader(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(context, couple: couple),
                        const SizedBox(height: 18),
                        _buildJourneyTrail(context, totalDays: totalDays),
                        // Achievements need a partner (streak/journal exist
                        // only once both are present); while waiting, the
                        // invite block takes the slot.
                        if (!couple.isWaitingForPartner) ...[
                          const SizedBox(height: 24),
                          _AchievementsGrid(
                            coupleId: couple.id,
                            totalDays: totalDays,
                            onRequestTab: onRequestTab,
                          ),
                          // Care note (feature care-message): only useful once
                          // there IS a partner to notify, so it shares the
                          // paired-only slot with the achievements grid.
                          const SizedBox(height: 18),
                          _buildCareTile(context),
                        ],
                        if (inviteCode != null &&
                            inviteCode.trim().isNotEmpty &&
                            couple.isWaitingForPartner) ...[
                          const SizedBox(height: 18),
                          _buildDetailTile(
                            icon: IconsaxPlusLinear.key,
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
              ],
            ),
          ),
        );
      },
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
          const SizedBox(height: 20),
          // Couple hero card (radius 32).
          const ShimmerSkeleton(height: 220, borderRadius: 32),
          const SizedBox(height: 18),
          // "Our journey" milestone-trail card.
          const ShimmerSkeleton(height: 160, borderRadius: 24),
          const SizedBox(height: 24),
          // Achievements: section title + a 2×2 badge grid.
          const ShimmerSkeleton(width: 150, height: 22, borderRadius: 8),
          const SizedBox(height: 12),
          const ShimmerSkeleton(height: 232, borderRadius: 24),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final l10n = context.l10n;

    // Unified tab header (user 2026-06-14): every tab is now a single chip
    // row + a right-aligned action icon — the big page title was dropped so
    // all four tabs share one header height/shape. See chat/gallery/home.
    //
    // crossAxisAlignment.start (header-padding unify 2026-06-14): the settings
    // icon (44) is taller than the chip (~27), and the Row's default centre
    // alignment pushed the chip DOWN ~8pt vs the icon-less Chat/Gallery chips.
    // Top-aligning lands the chip at exactly the same Y as every other tab.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EyebrowChip(label: l10n.loveProfileBadge, icon: IconsaxPlusBold.lovely),
        const Spacer(),
        // Settings entry = ONE squircle at the page's top-right (user
        // 2026-06-11) — replaces the full-width tile that closed the page.
        HeaderIconButton(
          icon: IconsaxPlusLinear.setting_2,
          semanticsLabel: l10n.settingsTitle,
          onTap: () => _openSettings(context),
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
                        decodeWidth:
                            (MediaQuery.of(context).size.width *
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
                    pulseHeart: true, // hero header — breathes like the Home counter
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
                    IconsaxPlusLinear.edit_2,
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
  /// Journey trail (Profile redesign 2026-06-14, Concept B): a horizontal
  /// milestone stepper replacing the old 4-stat grid (which showed the same
  /// day-count in four units). The big day number lives on the hero card.
  Widget _buildJourneyTrail(BuildContext context, {required int totalDays}) {
    final l10n = context.l10n;
    return _buildSectionCard(
      icon: IconsaxPlusLinear.map,
      title: l10n.journeyTrailTitle,
      child: MilestoneTrail(totalDays: totalDays),
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

  // The "Huy hiệu của chúng mình" achievements grid lives in its own stateful
  // widget (_AchievementsGrid, end of file) so it can cache the journal-count
  // aggregation across the Profile's frequent rebuilds.


  /// Entry point for the "send a care note" composer (feature care-message) —
  /// same tile shape as [_buildDetailTile], made tappable with the shared
  /// [InkTile] ripple.
  Widget _buildCareTile(BuildContext context) {
    final l10n = context.l10n;
    return InkTile(
      borderRadius: 22,
      onTap: () => openCareMessageScreen(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.accentLove.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            const IconBadge(
              IconsaxPlusLinear.message_favorite,
              tint: AppColors.accentLove,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.careMessageEntryTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.careMessageEntrySubtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              IconsaxPlusLinear.arrow_right_3,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
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

/// The "Huy hiệu của chúng mình" 2×2 badge grid (Profile redesign 2026-06-18).
///
/// Stateful so the journal-entry count (a one-shot Firestore `count()`
/// aggregation) is fetched once and cached, instead of re-querying on every
/// Profile rebuild. Every badge shows a real number + a small corner chevron
/// ("tap for detail", uniform across all four — no bare arrow tile any more) and
/// opens a focused detail: streak sheet / records sheet / memories sheet /
/// journal screen.
class _AchievementsGrid extends StatefulWidget {
  const _AchievementsGrid({
    required this.coupleId,
    required this.totalDays,
    required this.onRequestTab,
  });

  final String coupleId;
  final int totalDays;
  final void Function(int index)? onRequestTab;

  @override
  State<_AchievementsGrid> createState() => _AchievementsGridState();
}

class _AchievementsGridState extends State<_AchievementsGrid> {
  int? _journalCount; // null while the aggregation is in flight

  @override
  void initState() {
    super.initState();
    _loadJournalCount();
  }

  Future<void> _loadJournalCount() async {
    final count =
        await DailyQuestionService().countJournalEntries(widget.coupleId);
    if (mounted) {
      setState(() => _journalCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final streak = context.watch<StreakProvider>();
    final photoProvider = context.watch<PhotoProvider>();
    final photoCount = photoProvider.photoCount;
    final nf = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );

    final milestonesReached = StreakProvider.milestones
        .where((m) => streak.longestStreak >= m)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.profileAchievementsTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _badgeCard(
                icon: IconsaxPlusBold.flash,
                medalGradient: _MedalPalette.streak.gradient,
                accent: _MedalPalette.streak.accent,
                value: nf.format(streak.currentStreak),
                label: l10n.badgeStreakLabel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  StreakSheet.show(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _badgeCard(
                icon: IconsaxPlusBold.cup,
                medalGradient: _MedalPalette.record.gradient,
                accent: _MedalPalette.record.accent,
                value: nf.format(streak.longestStreak),
                label: l10n.badgeRecordLabel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  RecordsSheet.show(
                    context,
                    longestStreak: streak.longestStreak,
                    daysTogether: widget.totalDays,
                    photoCount: photoCount,
                    journalCount: _journalCount ?? 0,
                    milestonesReached: milestonesReached,
                    milestonesTotal: StreakProvider.milestones.length,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _badgeCard(
                icon: IconsaxPlusBold.gallery,
                medalGradient: _MedalPalette.memories.gradient,
                accent: _MedalPalette.memories.accent,
                value: nf.format(photoCount),
                label: l10n.badgeMemoriesLabel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  MemoriesSheet.show(
                    context,
                    photoCount: photoCount,
                    recentPhotos: photoProvider.photos,
                    onViewAll: () => widget.onRequestTab?.call(2),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _badgeCard(
                icon: IconsaxPlusBold.book_1,
                medalGradient: _MedalPalette.journal.gradient,
                accent: _MedalPalette.journal.accent,
                // null only briefly while the count loads → slim shimmer, never
                // a bare arrow (the old inconsistency this redesign removes).
                value: _journalCount == null ? null : nf.format(_journalCount!),
                label: l10n.badgeJournalLabel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: 'Journal'),
                      builder: (_) => const JournalScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// One achievement tile rendered as a real "medal": a gradient medallion that
  /// glows with its own colored halo (the focal point), a hero number in the
  /// medal's accent color, and a label. White card lifts it off the dawnBlush
  /// background; each medal carries a distinct-but-on-brand color so the 2×2
  /// grid reads as four separate badges, not one repeated tile.
  Widget _badgeCard({
    required IconData icon,
    required List<Color> medalGradient, // light → deep, fills the medallion
    required Color accent, // hero number + halo glow (the deep end)
    required String? value,
    required String label,
    required VoidCallback onTap,
  }) {
    const br = BorderRadius.all(Radius.circular(24));

    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.10),
        highlightColor: accent.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: br,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gradient medallion with a soft colored glow — the focal
                    // point that makes each tile pop off the white card.
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: medalGradient,
                        ),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.34),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: AppColors.white, size: 27),
                    ),
                    const Spacer(),
                    // Tap-for-detail affordance.
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        IconsaxPlusLinear.arrow_right_3,
                        size: 16,
                        color: accent.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Hero value / shimmer while the journal count loads.
                value != null
                    ? Text(
                        value,
                        style: TextStyle(
                          color: accent,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      )
                    : ShimmerSkeleton(width: 48, height: 22, borderRadius: 6),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
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
}

/// Per-badge medal palette — distinct yet all within the Sunset Romance family
/// (cool red · violet · warm coral · berry rose). `gradient` fills the
/// medallion (saturated enough for a white icon); `accent` is the deep end used
/// for the hero number and the medallion's glow.
class _MedalPalette {
  const _MedalPalette(this.gradient, this.accent);
  final List<Color> gradient;
  final Color accent;

  static const streak = _MedalPalette(
    [AppColors.sunset1, AppColors.accentLove], // #FF6B9D → #FF4D6D
    AppColors.accentLove,
  );
  static const record = _MedalPalette(
    [AppColors.accentLavender, AppColors.accentLavenderDeep], // #A78BFA → #7C5CD6
    AppColors.accentLavenderDeep,
  );
  static const memories = _MedalPalette(
    [Color(0xFFFF8A6E), Color(0xFFFF5C7A)], // warm coral → pink
    Color(0xFFFF5C7A),
  );
  static const journal = _MedalPalette(
    [Color(0xFFF58BB8), Color(0xFFDB5793)], // berry rose
    Color(0xFFD44A85),
  );
}
