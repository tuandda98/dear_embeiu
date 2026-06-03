import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/counter_data.dart';
import '../models/photo.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/daily_question_provider.dart';
import '../providers/love_note_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/counter_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/invite_action_buttons.dart';
import '../widgets/shared_photo_view.dart';
import '../widgets/shimmer_skeleton.dart';
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
      icon: LucideIcons.image,
      selectedIcon: LucideIcons.image,
      color: AppColors.accentRose,
    ),
    _NavigationItem(
      icon: LucideIcons.user,
      selectedIcon: LucideIcons.user,
      color: AppColors.accentRose,
    ),
  ];

  int _selectedIndex = 0;
  String? _lastReminderKey;

  // Staggered entrance for the Home tab should play once per screen lifetime,
  // not on every provider rebuild/scroll. We mark it played after the first
  // build that has real couple data, then build plain (un-animated) children.
  bool _homeEntrancePlayed = false;

  /// Wraps a Home-tab block with the shared fade+slide entrance, staggered by
  /// [order]. Returns the child unchanged once the entrance has already played
  /// so rebuilds don't re-run it.
  Widget _entrance(int order, Widget child) {
    if (_homeEntrancePlayed) {
      return child;
    }
    return child
        .animate()
        .fadeIn(duration: AppMotion.entrance, curve: AppMotion.curve)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppMotion.entrance,
          curve: AppMotion.curve,
          delay: AppMotion.stagger * order,
        );
  }

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

  /// Content-shaped shimmer shown while the couple data is still loading,
  /// mirroring the real Home layout (header, hero counter, quick actions).
  Widget _buildHomeLoadingSkeleton(double topPadding) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header line.
          const ShimmerSkeleton(width: 160, height: 22, borderRadius: 8),
          const SizedBox(height: 24),
          // Hero counter card (matches CounterCard radius 28).
          const ShimmerSkeleton(height: 220, borderRadius: 28),
          const SizedBox(height: 24),
          // Quick-action cards row.
          Row(
            children: const [
              Expanded(child: ShimmerSkeleton(height: 96, borderRadius: 22)),
              SizedBox(width: 14),
              Expanded(child: ShimmerSkeleton(height: 96, borderRadius: 22)),
            ],
          ),
          const SizedBox(height: 24),
          // Quote / banner block.
          const ShimmerSkeleton(height: 120, borderRadius: 24),
        ],
      ),
    );
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
            return _buildHomeLoadingSkeleton(mediaQuery.padding.top);
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
                        photoProvider.isLoading,
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
            HapticFeedback.selectionClick();
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
    bool isUploadingPhoto,
    double bottomInset,
  ) {
    final l10n = context.l10n;
    final totalDays = _getTotalDays(couple.anniversaryDate);
    final nextAnniversary = _getNextAnniversary(couple.anniversaryDate);
    final daysUntilAnniversary = _daysUntil(nextAnniversary);
    final nextMilestone = _getNextMilestone(totalDays);
    final progressToMilestone = totalDays / nextMilestone;
    final recentPhotos = photos.take(5).toList();
    final onThisDayPhoto = _onThisDayPhoto(photos);

    // Ensure the love-note stream is watching this couple. SessionResolver
    // already starts it, but the couple may finish loading after Home mounts
    // (or change), so re-arm here. watchForCouple no-ops when unchanged.
    final myUid = context.read<AuthProvider>().currentUser?.id;
    if (myUid != null && couple.id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<LoveNoteProvider>().watchForCouple(couple.id, myUid);
          context
              .read<DailyQuestionProvider>()
              .watchForCouple(couple.id, myUid);
        }
      });
    }

    // After the first frame with real data, lock the entrance so future
    // rebuilds (provider updates, tab switches) don't replay it.
    if (!_homeEntrancePlayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _homeEntrancePlayed = true;
        }
      });
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _entrance(
            0,
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
                              LucideIcons.sparkles,
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
          ),
          const SizedBox(height: 20),
          _entrance(1, _buildHeroSection(couple: couple, l10n: l10n)),
          if (couple.isWaitingForPartner) ...[
            const SizedBox(height: 16),
            _entrance(2, _buildWaitingForPartnerBanner(couple)),
          ],
          const SizedBox(height: 20),
          _entrance(
            3,
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
          ),
          const SizedBox(height: 20),
          _entrance(
            4,
            _buildSectionTitle(
              title: l10n.quickMomentsTitle,
              subtitle: l10n.addPhotosPrompt,
              actionLabel: l10n.viewAllPhotos,
              onActionTap: () => setState(() => _selectedIndex = 1),
            ),
          ),
          const SizedBox(height: 12),
          _entrance(4, _buildAddMemoryCta(l10n, isUploadingPhoto)),
          const SizedBox(height: 20),
          _entrance(
            5,
            _buildSectionTitle(
              title: l10n.milestoneProgressTitle,
              subtitle: l10n.milestoneProgressSubtitle,
            ),
          ),
          const SizedBox(height: 12),
          _entrance(
            5,
            _buildMilestoneSection(
              totalDays: totalDays,
              nextMilestone: nextMilestone,
              progress: progressToMilestone.clamp(0, 1),
              l10n: l10n,
            ),
          ),
          const SizedBox(height: 20),
          _entrance(6, _buildLoveNoteCard(couple, l10n)),
          const SizedBox(height: 20),
          _entrance(6, _buildDailyQuestionCard(couple, l10n)),
          if (onThisDayPhoto != null) ...[
            const SizedBox(height: 20),
            _entrance(6, _buildOnThisDayCard(onThisDayPhoto, couple, l10n)),
          ],
          const SizedBox(height: 20),
          _entrance(
            7,
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
          ),
          const SizedBox(height: 12),
          _entrance(
            7,
            _buildRecentPhotosSection(recentPhotos, isUploadingPhoto, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection({
    required Couple couple,
    required AppLocalizations l10n,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        borderRadius: 28,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(LucideIcons.sun, color: AppColors.white),
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
            child: const Icon(LucideIcons.link, color: AppColors.white, size: 20),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                      InviteActionButtons(
                        code: couple.inviteCode,
                        onDark: true,
                        iconOnly: true,
                      ),
                    ],
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

  Widget _buildAddMemoryCta(AppLocalizations l10n, bool isLoading) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentRose,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.camera,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addMemoryCta,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.addMemoryCtaSubtitle,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: AppColors.white.withValues(alpha: 0.7),
            size: 22,
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: isLoading ? null : _pickAndAddPhoto,
      child: isLoading ? Opacity(opacity: 0.6, child: card) : card,
    );
  }

  Future<String?> _showCaptionDialog({
    required String title,
    required String hint,
  }) async {
    final l10n = context.l10n;
    final captionController = TextEditingController(text: '');

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: captionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, captionController.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndAddPhoto() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      return;
    }

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null || !mounted) {
      return;
    }

    final l10n = context.l10n;
    final caption = await _showCaptionDialog(
      title: l10n.addCaptionOptionalTitle,
      hint: l10n.addCaptionOptionalHint,
    );

    // null = user pressed Cancel (dismiss dialog) = cancel entire upload
    if (caption == null || !mounted) {
      return;
    }

    try {
      await context.read<PhotoProvider>().addPhoto(
            pickedFile.path,
            currentUser: currentUser,
            caption: caption.isNotEmpty ? caption : null,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PhotoProvider>().errorMessage ??
                context.l10n.photoAddError,
          ),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.photoAddedSuccess)),
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
                  LucideIcons.award,
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

  /// Resolves the partner's display name from the couple, given the partner's
  /// uid. The couple creator is person1; everyone else maps to person2.
  String _partnerName(Couple couple, String? partnerUid, AppLocalizations l10n) {
    String name;
    if (partnerUid != null && partnerUid == couple.createdByUserId) {
      name = couple.person1Name;
    } else {
      name = couple.person2Name;
    }
    return name.trim().isNotEmpty ? name.trim() : l10n.posterNameFallback;
  }

  /// Localized "x minutes/hours/days ago" for a love note's [updatedAt].
  String _relativeTime(DateTime? when, AppLocalizations l10n) {
    if (when == null) {
      return l10n.loveNoteJustNow;
    }
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) {
      return l10n.loveNoteJustNow;
    }
    if (diff.inMinutes < 60) {
      return l10n.loveNoteMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.loveNoteHoursAgo(diff.inHours);
    }
    return l10n.loveNoteDaysAgo(diff.inDays);
  }

  /// "Lời nhắn của người ấy" (feature #4). Shows the note the partner left for
  /// the current user, plus a CTA to write/edit the user's own note.
  Widget _buildLoveNoteCard(Couple couple, AppLocalizations l10n) {
    return Consumer<LoveNoteProvider>(
      builder: (context, loveNoteProvider, _) {
        final partnerNote = loveNoteProvider.partnerNote;
        final partnerName = _partnerName(couple, partnerNote?.authorUserId, l10n);
        final hasNote = partnerNote != null && partnerNote.hasText;
        final isWaiting = couple.isWaitingForPartner;
        final hasMyNote = loveNoteProvider.myNote?.hasText == true;

        return GlassCard(
          borderRadius: 24,
          fillAlpha: 0.16,
          borderAlpha: 0.18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.mailOpen, color: AppColors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasNote
                          ? l10n.loveNoteFromPartner(partnerName)
                          : l10n.loveNoteLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isWaiting)
                Text(
                  l10n.loveNoteWaitingPartner,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                )
              else if (hasNote) ...[
                Text(
                  partnerNote.text,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _relativeTime(partnerNote.updatedAt, l10n),
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                Text(
                  l10n.loveNoteEmptyFromPartner(partnerName),
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              if (!isWaiting) ...[
                const SizedBox(height: 16),
                _buildWriteNoteButton(
                  label: hasMyNote ? l10n.loveNoteEditCta : l10n.loveNoteWriteCta,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWriteNoteButton({required String label}) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.30)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openLoveNoteSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.feather, color: AppColors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLoveNoteSheet() async {
    final l10n = context.l10n;
    final loveNoteProvider = context.read<LoveNoteProvider>();
    final controller =
        TextEditingController(text: loveNoteProvider.myNote?.text ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LoveNoteSheet(
        controller: controller,
        l10n: l10n,
      ),
    );

    controller.dispose();

    if (saved != true || !mounted) {
      return;
    }

    HapticFeedback.mediumImpact();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.loveNoteSaved)),
    );
  }

  /// "Câu hỏi hôm nay" (feature #5). One shared question per day; each partner
  /// answers, and the partner's answer is revealed only once both have answered.
  Widget _buildDailyQuestionCard(Couple couple, AppLocalizations l10n) {
    final langCode = Localizations.localeOf(context).languageCode;
    return Consumer<DailyQuestionProvider>(
      builder: (context, provider, _) {
        final partnerUid = provider.partnerAnswer?.authorUserId;
        final partnerName = _partnerName(couple, partnerUid, l10n);
        return _DailyQuestionCard(
          // Key by couple + question text so the card's internal state (the
          // one-shot confetti flag) resets cleanly on a couple/day change.
          key: ValueKey('daily-${couple.id}-${provider.todayQuestion(langCode)}'),
          provider: provider,
          l10n: l10n,
          question: provider.todayQuestion(langCode),
          partnerName: partnerName,
          isWaitingPartner: couple.isWaitingForPartner,
        );
      },
    );
  }

  /// Nostalgia card surfaced only when an "On this day" memory exists.
  /// Tapping opens the shared fullscreen preview (reused from the gallery).
  Widget _buildOnThisDayCard(
    Photo photo,
    Couple couple,
    AppLocalizations l10n,
  ) {
    final yearsAgo = DateTime.now().year - photo.uploadDate.year;
    const heroTag = 'on-this-day-preview';
    final caption = photo.caption?.trim();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        GalleryScreen.openPreview(
          context,
          photos: [photo],
          heroTags: const [heroTag],
          initialIndex: 0,
          couple: couple,
        );
      },
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Hero(
              tag: heroTag,
              createRectTween: (begin, end) =>
                  MaterialRectCenterArcTween(begin: begin, end: end),
              transitionOnUserGestures: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 80,
                  child: SharedPhotoView(
                    photo: photo,
                    fit: BoxFit.cover,
                    placeholder: Container(color: AppColors.surfaceLight),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendarHeart,
                        size: 16,
                        color: AppColors.white.withValues(alpha: 0.92),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.onThisDayTitle(yearsAgo),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    caption?.isNotEmpty == true
                        ? caption!
                        : l10n.onThisDaySubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.82),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              color: AppColors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPhotosSection(
    List<Photo> photos,
    bool isLoading,
    AppLocalizations l10n,
  ) {
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
              LucideIcons.image,
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
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isLoading ? null : _pickAndAddPhoto,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(LucideIcons.imagePlus),
              label: Text(l10n.postFirstPhotoBtn),
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

  /// Finds the "On this day" memory: a photo taken on the same month+day as
  /// today but in an earlier year. When several match, returns the oldest one
  /// (most years ago) so the "{n} years ago" headline is most striking.
  /// Returns null when nothing matches — the card is then hidden entirely.
  Photo? _onThisDayPhoto(List<Photo> photos) {
    final now = DateTime.now();
    Photo? best;
    for (final photo in photos) {
      final d = photo.uploadDate;
      if (d.month == now.month && d.day == now.day && d.year < now.year) {
        if (best == null || d.year < best.uploadDate.year) {
          best = photo;
        }
      }
    }
    return best;
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

/// Bottom sheet for composing/editing the current user's love note (feature #4).
/// Pops `true` after a successful save so the caller can confirm + haptic.
class _LoveNoteSheet extends StatefulWidget {
  const _LoveNoteSheet({
    required this.controller,
    required this.l10n,
  });

  final TextEditingController controller;
  final AppLocalizations l10n;

  @override
  State<_LoveNoteSheet> createState() => _LoveNoteSheetState();
}

class _LoveNoteSheetState extends State<_LoveNoteSheet> {
  static const int _maxChars = 140;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final saved =
        await context.read<LoveNoteProvider>().setMyNote(widget.controller.text);
    if (!mounted) {
      return;
    }
    navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(LucideIcons.heart,
                        color: AppColors.accentRose, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.loveNoteSheetTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: widget.controller,
                  maxLength: _maxChars,
                  maxLines: 4,
                  minLines: 2,
                  autofocus: true,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.loveNoteSheetHint,
                    counterText: l10n.loveNoteCharCount(
                      widget.controller.text.characters.length,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          )
                        : Text(l10n.save),
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

/// Home card for the shared "daily question" (feature #5). Owns its own state
/// because it has (a) a text controller for the answer, (b) a confetti
/// controller that fires once on reveal, and (c) a guard flag so the confetti
/// never re-fires on rebuilds.
class _DailyQuestionCard extends StatefulWidget {
  const _DailyQuestionCard({
    super.key,
    required this.provider,
    required this.l10n,
    required this.question,
    required this.partnerName,
    required this.isWaitingPartner,
  });

  final DailyQuestionProvider provider;
  final AppLocalizations l10n;
  final String question;
  final String partnerName;
  final bool isWaitingPartner;

  @override
  State<_DailyQuestionCard> createState() => _DailyQuestionCardState();
}

class _DailyQuestionCardState extends State<_DailyQuestionCard> {
  static const int _maxChars = 280;

  final TextEditingController _controller = TextEditingController();
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 600));
  bool _submitting = false;
  // One-shot guard: the reveal confetti plays at most once per card lifetime.
  bool _confettiPlayed = false;

  @override
  void initState() {
    super.initState();
    // If the card is built already in the revealed state (e.g. reopening Home
    // after both answered), don't surprise the user with confetti — only
    // celebrate a fresh reveal that happens while watching.
    _confettiPlayed = widget.provider.hasRevealed;
  }

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    final l10n = widget.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await widget.provider.submit(text);
    HapticFeedback.mediumImpact();
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.dailyQuestionSent)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final provider = widget.provider;
    final hasAnswered = provider.hasAnswered;
    final hasRevealed = provider.hasRevealed;

    // Fire confetti exactly once, the first build where we reach the revealed
    // state (and weren't already revealed on init).
    if (hasRevealed && !_confettiPlayed) {
      _confettiPlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confetti.play();
        }
      });
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        GlassCard(
          borderRadius: 24,
          fillAlpha: 0.16,
          borderAlpha: 0.18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.helpCircle,
                      color: AppColors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.dailyQuestionLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.question,
                style: AppTheme.displaySerif(
                  size: 22,
                  weight: FontWeight.w600,
                  color: AppColors.white,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildBody(l10n, provider, hasAnswered, hasRevealed),
            ],
          ),
        ),
        // Gentle one-shot celebration, centered above the card.
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 14,
          maxBlastForce: 14,
          minBlastForce: 6,
          emissionFrequency: 0.0,
          gravity: 0.25,
          shouldLoop: false,
          colors: const [
            AppColors.accentRose,
            AppColors.accentLavender,
            AppColors.accentCoral,
            AppColors.white,
          ],
        ),
      ],
    );
  }

  List<Widget> _buildBody(
    AppLocalizations l10n,
    DailyQuestionProvider provider,
    bool hasAnswered,
    bool hasRevealed,
  ) {
    // Reveal: both answered — show both answers, labelled.
    if (hasRevealed) {
      final mine = provider.myAnswer?.text.trim() ?? '';
      final theirs = provider.partnerAnswer?.text.trim() ?? '';
      return [
        Text(
          l10n.dailyQuestionRevealHint,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.82),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _answerBlock(l10n.dailyQuestionYourAnswerLabel, mine),
        const SizedBox(height: 12),
        _answerBlock(
          l10n.dailyQuestionPartnerAnswerLabel(widget.partnerName),
          theirs,
        ),
      ];
    }

    // Answered, waiting for partner.
    if (hasAnswered) {
      final mine = provider.myAnswer?.text.trim() ?? '';
      final waitingFor = widget.isWaitingPartner
          ? l10n.dailyQuestionWaitingPartner
          : l10n.dailyQuestionAnsweredWaiting(widget.partnerName);
      return [
        _answerBlock(l10n.dailyQuestionYourAnswerLabel, mine),
        const SizedBox(height: 12),
        Text(
          waitingFor,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.78),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ];
    }

    // Not answered yet — input + send.
    return [
      if (widget.isWaitingPartner) ...[
        Text(
          l10n.dailyQuestionWaitingPartner,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.78),
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
      ],
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.white.withValues(alpha: 0.22)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _controller,
                maxLength: _maxChars,
                maxLines: 3,
                minLines: 1,
                cursorColor: AppColors.white,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: l10n.dailyQuestionHint,
                  hintStyle: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  counterText: l10n.dailyQuestionCharCount(
                    _controller.text.characters.length,
                  ),
                  counterStyle: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.30)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: (_submitting || _controller.text.trim().isEmpty)
                  ? null
                  : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_submitting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    else ...[
                      const Icon(LucideIcons.send,
                          color: AppColors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dailyQuestionSend,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _answerBlock(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
