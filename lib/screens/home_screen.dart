import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/counter_data.dart';
import '../models/photo.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/counter_card.dart';
import '../widgets/shared_photo_view.dart';
import 'profile_screen.dart';
import 'gallery_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _floatingNavHeight = 84;
  static const double _floatingNavMargin = 16;
  static const double _floatingNavSpacing = 18;
  static const double _floatingNavInnerPadding = 6;
  static const double _floatingNavPillInset = 5;

  static const List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
      color: AppColors.accentRose,
    ),
    _NavigationItem(
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library_rounded,
      color: AppColors.accentRose,
    ),
    _NavigationItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      color: AppColors.accentRose,
    ),
  ];

  int _selectedIndex = 0;
  String? _lastReminderKey;

  @override
  void initState() {
    super.initState();
    // Cold-start deep-link: a terminated→tap set the pending tab inside
    // PushNotificationService.initialize() (before this mounted), so apply it
    // now as the initial tab. Then listen for warm taps while mounted.
    _applyPendingTab(NotificationTapRouter.pendingHomeTab.value);
    NotificationTapRouter.consumeHomeTabRequest();
    NotificationTapRouter.pendingHomeTab.addListener(_onNotificationTapRequest);
  }

  @override
  void dispose() {
    NotificationTapRouter.pendingHomeTab
        .removeListener(_onNotificationTapRequest);
    super.dispose();
  }

  /// Reacts to a warm tap (app already running) requesting a tab switch.
  void _onNotificationTapRequest() {
    final requested = NotificationTapRouter.pendingHomeTab.value;
    if (requested == -1) {
      return;
    }
    NotificationTapRouter.consumeHomeTabRequest();
    // Never setState mid-build; defer to after the current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_selectedIndex != requested) {
        setState(() => _selectedIndex = requested);
      }
    });
  }

  /// Sets the initial tab from a pending request during initState (no setState
  /// needed — the first build hasn't happened yet). Ignores -1 (no request)
  /// and any out-of-range value, keeping the default Home tab.
  void _applyPendingTab(int requested) {
    if (requested >= 0 && requested < _navigationItems.length) {
      _selectedIndex = requested;
    }
  }

  /// (Re)schedule love reminders whenever the data that feeds them changes.
  /// Cheap to call on every build: it skips when nothing relevant changed and
  /// defers the work to after the frame so it never mutates providers mid-build.
  void _syncReminders(
    BuildContext context,
    Couple couple,
    PhotoProvider photoProvider,
  ) {
    final l10n = context.l10n;
    final photos = photoProvider.sortedPhotos;
    final lastPhotoDate = photos.isEmpty ? null : photos.first.uploadDate;
    final now = DateTime.now();
    final key = [
      couple.anniversaryDate.millisecondsSinceEpoch,
      lastPhotoDate?.millisecondsSinceEpoch ?? 0,
      l10n.localeName,
      '${now.year}-${now.month}-${now.day}',
    ].join('|');
    if (key == _lastReminderKey) {
      return;
    }
    _lastReminderKey = key;

    final reminderProvider = context.read<ReminderProvider>();
    final anniversaryDate = couple.anniversaryDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      reminderProvider.sync(
        anniversaryDate: anniversaryDate,
        lastPhotoDate: lastPhotoDate,
        l10n: l10n,
      );
    });
  }

  String _navLabel(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.navHome;
      case 1:
        return l10n.navMemories;
      case 2:
        return l10n.navProfile;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset =
        mediaQuery.padding.bottom +
        _floatingNavHeight +
        (_floatingNavMargin * 2) +
        _floatingNavSpacing;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Consumer2<CoupleProvider, PhotoProvider>(
        builder: (context, coupleProvider, photoProvider, _) {
          if (coupleProvider.couple == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final couple = coupleProvider.couple!;
          _syncReminders(context, couple, photoProvider);
          final counterData = CounterData.calculateFromAnniversary(
            couple.anniversaryDate,
          );

          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
                child: SafeArea(
                  bottom: false,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildHomeTab(
                        couple,
                        counterData,
                        photoProvider.sortedPhotos,
                        bottomInset,
                      ),
                      GalleryScreen(bottomInset: bottomInset),
                      ProfileScreen(bottomInset: bottomInset),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: _floatingNavMargin,
                right: _floatingNavMargin,
                bottom: mediaQuery.padding.bottom + _floatingNavMargin,
                child: _buildFloatingNavigationBar(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingNavigationBar() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final l10n = context.l10n;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: isKeyboardVisible ? const Offset(0, 1.2) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: isKeyboardVisible ? 0 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentLove.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: _floatingNavHeight,
                padding: const EdgeInsets.all(_floatingNavInnerPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.white.withValues(alpha: 0.28),
                      AppColors.white.withValues(alpha: 0.14),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        constraints.maxWidth / _navigationItems.length;
                    final pillLeft =
                        itemWidth * _selectedIndex + _floatingNavPillInset;
                    final pillWidth =
                        itemWidth - _floatingNavPillInset * 2;
                    final pillHeight =
                        constraints.maxHeight - _floatingNavPillInset * 2;

                    return Stack(
                      children: [
                        // ── Sliding rose-gradient pill ───────────────────
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          left: pillLeft,
                          top: _floatingNavPillInset,
                          width: pillWidth,
                          height: pillHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.sunset1,
                                  AppColors.accentLoveDeep,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentLove.withValues(alpha: 0.40),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ── Nav items ────────────────────────────────────
                        Row(
                          children: List.generate(
                            _navigationItems.length,
                            (index) {
                              final item = _navigationItems[index];
                              final isSelected = index == _selectedIndex;
                              final label = _navLabel(index, l10n);

                              return Expanded(
                                child: _buildNavigationItem(
                                  item: item,
                                  index: index,
                                  isSelected: isSelected,
                                  label: label,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required _NavigationItem item,
    required int index,
    required bool isSelected,
    required String label,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('bottom-nav-$index'),
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.white.withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          onTap: () {
            if (_selectedIndex == index) return;
            setState(() => _selectedIndex = index);
          },
          child: SizedBox.expand(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    scale: isSelected ? 1.12 : 1.0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                        key: ValueKey('icon-$index-$isSelected'),
                        size: 22,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: isSelected
                        ? Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                height: 1,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHomeTab(
    Couple couple,
    CounterData counterData,
    List<Photo> photos,
    double bottomInset,
  ) {
    final l10n = context.l10n;
    final totalDays = _getTotalDays(couple.anniversaryDate);
    final nextAnniversary = _getNextAnniversary(couple.anniversaryDate);
    final daysUntilAnniversary = _daysUntil(nextAnniversary);
    final nextMilestone = _getNextMilestone(totalDays);
    final progressToMilestone = totalDays / nextMilestone;
    final recentPhotos = photos.take(5).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: AppColors.white.withValues(alpha: 0.92),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.loveHomeBadge,
                            style: AppTheme.pageEyebrowStyle(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(l10n.navHome, style: AppTheme.pageTitleStyle()),
                    const SizedBox(height: 8),
                    Text(
                      l10n.homeSubtitle,
                      style: AppTheme.pageSubtitleStyle(),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 2),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeroSection(couple: couple, l10n: l10n),
          if (couple.isWaitingForPartner) ...[
            const SizedBox(height: 16),
            _buildWaitingForPartnerBanner(couple),
          ],
          const SizedBox(height: 20),
          CounterCard(
            years: counterData.years,
            months: counterData.months,
            days: counterData.days,
            subtitle: l10n.homeCounterStartFrom(
              _formatDate(context, couple.anniversaryDate),
            ),
            footer: daysUntilAnniversary == 0
                ? l10n.todayIsAnniversary
                : l10n.daysUntilNextAnniversary(daysUntilAnniversary),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(
            title: l10n.quickMomentsTitle,
            subtitle: l10n.quickMomentsSubtitle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.photo_library_rounded,
                  title: l10n.memoriesCardTitle,
                  subtitle: l10n.viewAllPhotos,
                  color: AppColors.accentRose,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.person_rounded,
                  title: l10n.profileCardTitle,
                  subtitle: l10n.updateInfo,
                  color: AppColors.accentCoral,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(
            title: l10n.milestoneProgressTitle,
            subtitle: l10n.milestoneProgressSubtitle,
          ),
          const SizedBox(height: 12),
          _buildMilestoneSection(
            totalDays: totalDays,
            nextMilestone: nextMilestone,
            progress: progressToMilestone.clamp(0, 1),
            l10n: l10n,
          ),
          const SizedBox(height: 20),
          _buildQuoteCard(totalDays, couple, l10n),
          const SizedBox(height: 20),
          _buildSectionTitle(
            title: l10n.recentMemoriesTitle,
            subtitle: photos.isEmpty
                ? l10n.addPhotosPrompt
                : l10n.latestMomentsSubtitle,
            actionLabel: photos.isEmpty ? null : l10n.seeAll,
            onActionTap: photos.isEmpty
                ? null
                : () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 12),
          _buildRecentPhotosSection(recentPhotos, l10n),
        ],
      ),
    );
  }

  Widget _buildHeroSection({
    required Couple couple,
    required AppLocalizations l10n,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.wb_sunny_rounded, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.helloGreeting,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AnimatedCoupleName(
                    person1Name: couple.person1Name,
                    person2Name: couple.person2Name,
                    spacing: 6,
                    runSpacing: 4,
                    heartSize: 18,
                    heartColor: AppColors.white,
                    textStyle: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingForPartnerBanner(Couple couple) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.link_rounded, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeWaitingPartnerTitle,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.homeWaitingPartnerSubtitle,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.80),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (couple.inviteCode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      couple.inviteCode,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.sectionTitleStyle(),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.sectionSubtitleStyle(),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              padding: EdgeInsets.zero,
            ),
            child: Text(actionLabel),
          ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneSection({
    required int totalDays,
    required int nextMilestone,
    required double progress,
    required AppLocalizations l10n,
  }) {
    final daysLeft = nextMilestone - totalDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.accentGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nextMilestonePrefix(_milestoneLabel(nextMilestone, l10n)),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysLeft <= 0
                          ? l10n.milestoneReached
                          : l10n.onlyDaysUntilMilestone(daysLeft),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentRose),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.daysCountLabel(totalDays),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.percentThere((progress * 100).toStringAsFixed(0)),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(int totalDays, Couple couple, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withValues(alpha: 0.24),
            AppColors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: AppColors.white),
              const SizedBox(width: 8),
              Text(
                l10n.loveNoteLabel,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.loveNoteQuote(totalDays),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '—',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedCoupleName(
                person1Name: couple.person1Name,
                person2Name: couple.person2Name,
                spacing: 5,
                runSpacing: 4,
                heartSize: 12,
                heartColor: AppColors.white,
                textStyle: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPhotosSection(List<Photo> photos, AppLocalizations l10n) {
    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addPhotosEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SharedPhotoView(
                      photo: photo,
                      fit: BoxFit.cover,
                      placeholder: Container(color: AppColors.surfaceLight),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photo.caption?.trim().isNotEmpty == true
                                ? photo.caption!
                                : l10n.momentNumberFallback(index + 1),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(context, photo.uploadDate),
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.82),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _getTotalDays(DateTime anniversaryDate) {
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

  DateTime _getNextAnniversary(DateTime anniversaryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, anniversaryDate.month, anniversaryDate.day);

    if (!next.isAfter(today)) {
      next = DateTime(now.year + 1, anniversaryDate.month, anniversaryDate.day);
    }

    return next;
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }

  int _getNextMilestone(int totalDays) {
    const milestones = [30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000];
    for (final milestone in milestones) {
      if (totalDays < milestone) {
        return milestone;
      }
    }
    return ((totalDays ~/ 500) + 1) * 500;
  }

  String _milestoneLabel(int days, AppLocalizations l10n) {
    if (days % 365 == 0) {
      final count = days ~/ 365;
      return count == 1 ? l10n.milestoneYearsOne(count) : l10n.milestoneYearsMany(count);
    }
    if (days < 365 && days % 30 == 0) {
      final count = days ~/ 30;
      return count == 1 ? l10n.milestoneMonthsOne(count) : l10n.milestoneMonthsMany(count);
    }
    return l10n.milestoneDaysLabel(days);
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.color,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final Color color;
}
