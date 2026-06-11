import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
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
import '../providers/notification_inbox_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/reaction_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/streak_provider.dart';
import '../services/analytics_service.dart';
import '../services/home_prefs_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/counter_card.dart';
import '../widgets/invite_action_buttons.dart';
import '../widgets/memory_cinema_card.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/streak_chip.dart';
import '../widgets/today_ritual_card.dart';
import '../widgets/streak_sheet.dart';
import 'profile_screen.dart';
import 'gallery_screen.dart';
import 'notification_center_screen.dart';


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

  /// Counter-card background selection (swipe ←/→ on the hero card cycles
  /// through the couple photo + recent gallery photos). Persisted per couple
  /// in the `app_settings` Hive box, keyed by photo id so the choice survives
  /// new uploads shifting the list.
  String? _counterBgKey;
  String? _counterBgCouple;

  /// One-time "swipe to change photo" coach-mark over the counter card.
  bool _showBgHint = false;
  Timer? _bgHintTimer;

  /// Direction of the last background swipe (+1 next / -1 previous) — drives
  /// the slide-in side of the photo transition.
  int _bgSwipeDirection = 1;

  /// Couple-shared background selection (couples/{id}/prefs/home): a swipe on
  /// either phone moves BOTH cards. Hive stays as the offline/local cache.
  final HomePrefsService _homePrefs = HomePrefsService();
  StreamSubscription<String?>? _bgSyncSub;

  void _ensureCounterBgLoaded(String coupleId) {
    if (_counterBgCouple == coupleId) {
      return;
    }
    _counterBgCouple = coupleId;
    try {
      final box = Hive.box<String>('app_settings');
      _counterBgKey = box.get('counter_bg_$coupleId');
      _showBgHint = box.get('counter_bg_hint_done') == null;
    } catch (_) {
      _counterBgKey = null; // Box unavailable → session-only selection.
      _showBgHint = false;
    }
    // Follow the couple-shared selection (fires for the partner's swipes —
    // and echoes ours, which the equality guard ignores).
    _bgSyncSub?.cancel();
    _bgSyncSub = _homePrefs.watchCounterBg(coupleId).listen((remoteKey) {
      if (remoteKey == null || remoteKey == _counterBgKey || !mounted) {
        return;
      }
      setState(() {
        _bgSwipeDirection = 1;
        _counterBgKey = remoteKey;
      });
      try {
        Hive.box<String>('app_settings').put('counter_bg_$coupleId', remoteKey);
      } catch (_) {
        // Cache only — the in-memory value is already set.
      }
    });
  }

  void _dismissBgHint() {
    _bgHintTimer?.cancel();
    _bgHintTimer = null;
    if (_showBgHint && mounted) {
      setState(() => _showBgHint = false);
    } else {
      _showBgHint = false;
    }
    try {
      Hive.box<String>('app_settings').put('counter_bg_hint_done', '1');
    } catch (_) {
      // Best-effort persistence only.
    }
  }

  List<({String key, String? local, String? remote})> _counterBgCandidates(
    Couple couple,
    List<Photo> photos,
  ) {
    return [
      if ((couple.couplePhotoUrl?.trim().isNotEmpty ?? false) ||
          (couple.couplePhotoPath?.trim().isNotEmpty ?? false))
        (
          key: 'couple',
          local: couple.couplePhotoPath,
          remote: couple.couplePhotoUrl,
        ),
      for (final p in photos.take(12))
        if (p.hasLocalPath || p.hasRemoteUrl)
          (key: p.id, local: p.path, remote: p.remoteUrl),
    ];
  }

  void _swipeCounterBg(
    int delta,
    List<({String key, String? local, String? remote})> candidates,
    String coupleId,
  ) {
    if (candidates.length < 2) {
      return;
    }
    var index = candidates.indexWhere((c) => c.key == _counterBgKey);
    if (index < 0) {
      index = 0;
    }
    final next = (index + delta + candidates.length) % candidates.length;
    HapticFeedback.selectionClick();
    _dismissBgHint();
    AnalyticsService.instance.logCounterBgSwiped();
    setState(() {
      _bgSwipeDirection = delta;
      _counterBgKey = candidates[next].key;
    });
    try {
      Hive.box<String>('app_settings')
          .put('counter_bg_$coupleId', candidates[next].key);
    } catch (_) {
      // Best-effort persistence only.
    }
    // Share with the partner (fail-soft inside the service).
    unawaited(_homePrefs.setCounterBg(coupleId, candidates[next].key));
  }

  /// Anchor for the daily-question card so a tapped `daily_question`
  /// notification can scroll it into view (deep-link within Home).
  final GlobalKey _dailyQuestionKey = GlobalKey();

  // Streak milestone celebration (feature streak): listen for a freshly-reached
  // milestone and auto-show the StreakSheet in celebration mode, once. The
  // provider's per-couple Hive guard prevents re-firing across launches; this
  // session flag avoids re-entrancy while a celebration sheet is already up.
  StreakProvider? _streakProvider;
  bool _celebratingMilestone = false;

  /// Standard 16px page gutter, applied PER BLOCK (the scroll view itself has
  /// no horizontal padding) so the memory cinema can run full-bleed.
  Widget _gutter(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  /// Wraps a Home-tab block with the shared fade+slide entrance, staggered by
  /// [order].
  Widget _entrance(int order, Widget child) {
    // Reduce Motion: no entrance choreography — content just appears.
    if (AppMotion.reduceMotion(context)) {
      return child;
    }
    // ALWAYS wrap with `.animate()` using CONSTANT params — never branch on a
    // "played" flag. flutter_animate's `_AnimateState.didUpdateWidget` only
    // re-inits the controller / replays when controller/duration/target/value
    // change (animate.dart:294); with constant params a plain Home rebuild
    // (e.g. the keyboard opening for the love-note sheet shifts MediaQuery →
    // HomeScreen.build → whole tab rebuilds) is a no-op, so the entrance does
    // NOT replay. Two earlier variants both crashed: returning the bare child
    // once played changed the element-tree structure (→ `_dependents.isEmpty`),
    // and swapping the duration to zero re-inited the controller and left a
    // transition listening to a disposed animation (→ ChangeNotifier used after
    // dispose). Keeping the wrapper + params stable avoids both.
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

    // Cold-start / warm deep-link to a specific Home card (e.g. daily question).
    _applyPendingFocus(NotificationTapRouter.pendingHomeFocus.value);
    NotificationTapRouter.consumeHomeFocusRequest();
    NotificationTapRouter.pendingHomeFocus.addListener(_onNotificationFocusRequest);

    // Watch for a freshly-reached streak milestone to auto-celebrate.
    _streakProvider = context.read<StreakProvider>();
    _streakProvider!.addListener(_onStreakChanged);
  }

  @override
  void dispose() {
    NotificationTapRouter.pendingHomeTab
        .removeListener(_onNotificationTapRequest);
    NotificationTapRouter.pendingHomeFocus
        .removeListener(_onNotificationFocusRequest);
    _streakProvider?.removeListener(_onStreakChanged);
    _bgHintTimer?.cancel();
    _bgSyncSub?.cancel();
    super.dispose();
  }

  /// Reacts to a streak update: when a milestone was just reached for the first
  /// time, auto-show the StreakSheet in celebration mode after a short delay so
  /// it doesn't collide with the Daily Question card's reveal confetti (§6).
  void _onStreakChanged() {
    final provider = _streakProvider;
    if (provider == null || _celebratingMilestone) {
      return;
    }
    final milestone = provider.justReachedMilestone;
    if (milestone == null) {
      return;
    }
    // Consume immediately so a rebuild can't queue a second celebration.
    provider.consumeJustReachedMilestone();
    _celebratingMilestone = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted) {
        _celebratingMilestone = false;
        return;
      }
      await StreakSheet.showMilestone(context, milestone);
      if (mounted) {
        _celebratingMilestone = false;
      }
    });
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
        _logTabScreenView(requested);
      }
    });
  }

  /// Sets the initial tab from a pending request during initState (no setState
  /// needed — the first build hasn't happened yet). Ignores -1 (no request)
  /// and any out-of-range value, keeping the default Home tab.
  void _applyPendingTab(int requested) {
    if (requested >= 0 && requested < _navigationItems.length) {
      _selectedIndex = requested;
      // Cold-start deep-link straight to a tab: the '/home' route observer logs
      // 'Home', so only emit the extra screen_view for Gallery/Profile.
      if (requested > 0) {
        _logTabScreenView(requested);
      }
    }
  }

  /// Reacts to a warm focus request (app already running) — e.g. a tapped
  /// daily-question notification wants its card scrolled into view.
  void _onNotificationFocusRequest() {
    final focus = NotificationTapRouter.pendingHomeFocus.value;
    if (focus == null) {
      return;
    }
    NotificationTapRouter.consumeHomeFocusRequest();
    _applyPendingFocus(focus);
  }

  /// Routes a Home-focus request to the matching card. Currently only the
  /// daily-question card; add more `case`s as other Home cards get deep-links.
  void _applyPendingFocus(String? focus) {
    if (focus == 'daily_question') {
      _scrollToCard(_dailyQuestionKey);
    }
  }

  /// Smoothly scrolls the Home tab so the [key]'d card is in view. Deferred so
  /// the tab has switched to Home and the card is laid out first; safe no-op if
  /// the card isn't mounted (e.g. guest/waiting-partner states hide it).
  void _scrollToCard(GlobalKey key) {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      final ctx = key.currentContext;
      if (ctx == null || !ctx.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    });
  }

  /// Logs a `screen_view` for the Home bottom-nav tabs (0=Home, 1=Gallery,
  /// 2=Profile) — these are IndexedStack children, not routes, so the navigator
  /// observer can't see them. (feature analytics)
  void _logTabScreenView(int index) {
    const names = ['Home', 'Gallery', 'Profile'];
    if (index >= 0 && index < names.length) {
      AnalyticsService.instance.logScreenView(names[index]);
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
      // Gutter per block (matches the live layout) — the memory cinema
      // skeleton runs full-bleed like the real card.
      padding: EdgeInsets.fromLTRB(0, topPadding + 20, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: calendar leaf (boxless number + stacked lines) + bell.
          _gutter(
            Row(
              children: const [
                ShimmerSkeleton(width: 48, height: 40, borderRadius: 10),
                SizedBox(width: 12),
                ShimmerSkeleton(width: 110, height: 32, borderRadius: 8),
                Spacer(),
                ShimmerSkeleton(width: 45, height: 45, borderRadius: 999),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Hero counter card (photo bg + clock line + milestone + streak).
          _gutter(const ShimmerSkeleton(height: 380, borderRadius: 28)),
          const SizedBox(height: 28),
          _gutter(
            const ShimmerSkeleton(width: 190, height: 22, borderRadius: 8),
          ),
          const SizedBox(height: 12),
          // Merged "today ritual" card (question + love note).
          _gutter(const ShimmerSkeleton(height: 230, borderRadius: 24)),
          const SizedBox(height: 28),
          _gutter(
            const ShimmerSkeleton(width: 170, height: 22, borderRadius: 8),
          ),
          const SizedBox(height: 12),
          // Memory cinema card (full-bleed, square).
          const ShimmerSkeleton(height: 240, borderRadius: 0),
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

    // Auto-read: landing on a tab "consumes" the activity surfaced there, so
    // mark its unread inbox notifications read (keeps the bell badge honest).
    // Watching here means it also fires when items stream in while we're already
    // on the tab. Gated + idempotent (markReadForTab no-ops once nothing matches)
    // so it converges in one frame and never loops.
    final inbox = context.watch<NotificationInboxProvider>();
    if (inbox.unreadForTab(_selectedIndex) > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NotificationInboxProvider>().markReadForTab(_selectedIndex);
        }
      });
    }

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
                    // TickerMode: IndexedStack keeps every tab alive, but the
                    // hidden tabs must not keep animating (aurora, Ken Burns,
                    // pulses) or ticking their timers — battery + jank.
                    children: [
                      TickerMode(
                        enabled: _selectedIndex == 0,
                        child: _buildHomeTab(
                          couple,
                          counterData,
                          photoProvider.sortedPhotos,
                          photoProvider.isLoading,
                          bottomInset,
                        ),
                      ),
                      TickerMode(
                        enabled: _selectedIndex == 1,
                        child: GalleryScreen(bottomInset: bottomInset),
                      ),
                      TickerMode(
                        enabled: _selectedIndex == 2,
                        child: ProfileScreen(bottomInset: bottomInset),
                      ),
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
            _logTabScreenView(index);
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
                        // .75, not .55 — unselected icons on the light glass
                        // were dropping out of sight (design H6/A5).
                        color: isSelected
                            ? AppColors.white
                            : AppColors.white.withValues(alpha: 0.75),
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
                                fontSize: 11,
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
    _ensureCounterBgLoaded(couple.id);
    final bgCandidates = _counterBgCandidates(couple, photos);
    var bgIndex = bgCandidates.indexWhere((c) => c.key == _counterBgKey);
    if (bgIndex < 0) {
      bgIndex = 0;
    }
    final counterBg = bgCandidates.isEmpty ? null : bgCandidates[bgIndex];
    if (_showBgHint && bgCandidates.length >= 2 && _bgHintTimer == null) {
      _bgHintTimer = Timer(const Duration(milliseconds: 4500), _dismissBgHint);
    }
    final totalDays = _getTotalDays(couple.anniversaryDate);
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
          context.read<ReactionProvider>().watchForCouple(couple.id, myUid);
          // Re-arm the streak too — it must flip from hidden→active the moment
          // the partner joins while Home stays open. watchForCouple no-ops when
          // (couple, active) is unchanged.
          context.read<StreakProvider>().watchForCouple(
                couple.id,
                coupleActive: !couple.isWaitingForPartner,
              );
          // Notification center stream — re-arm so the bell badge stays live
          // even if the couple finished loading after Home mounted.
          context
              .read<NotificationInboxProvider>()
              .watchForCouple(couple.id, myUid);
        }
      });
    }

    return RefreshIndicator(
      onRefresh: _refreshHome,
      color: AppColors.accentRose,
      // White disc so the rose spinner stays visible on the pink gradient.
      backgroundColor: AppColors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        // Horizontal gutter moved DOWN onto each block (`_gutter`) so the
        // memory cinema can run full-bleed edge to edge (user 2026-06-10).
        padding: EdgeInsets.fromLTRB(0, 16, 0, bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _gutter(_entrance(
            0,
            // Slim header: badge chip + bell only — the greeting was dropped
            // and the couple name moved INTO the CounterCard (user 2026-06-10).
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // "Calendar leaf" date (redesign user 2026-06-10, third take):
                // a big airy day number + stacked weekday/month behind a
                // glowing vertical hairline — the bloc-calendar page that
                // mirrors the day count in the hero card below. Quietly
                // unconventional: no chip, no label, just today as an object.
                Expanded(child: _buildCalendarLeaf()),
                const SizedBox(width: 12),
                _buildNotificationBell(),
              ],
            ),
          )),
          const SizedBox(height: 20),
          _gutter(_entrance(
            1,
            GestureDetector(
              // Swipe ←/→ on the hero card cycles its background photo
              // (couple photo + recent gallery). Horizontal-only, so vertical
              // page scrolling and the chip's tap are untouched.
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 150) {
                  return;
                }
                _swipeCounterBg(velocity < 0 ? 1 : -1, bgCandidates, couple.id);
              },
              child: Stack(
                children: [
                  CounterCard(
              // Days-only hero + live hh:mm:ss clock (user 2026-06-10):
              // the years/months breakdown is gone — one big day count.
              totalDays: totalDays,
              liveSince: couple.anniversaryDate,
              // Swipeable card background (falls back to the couple photo).
              photoLocalPath: counterBg?.local,
              photoRemoteUrl: counterBg?.remote,
              photoSwipeDirection: _bgSwipeDirection,
              // Couple name lives inside the hero card (user 2026-06-10).
              headerExtra: AnimatedCoupleName(
                person1Name: couple.person1Name,
                person2Name: couple.person2Name,
                creatorUserId: couple.createdByUserId,
                alignment: WrapAlignment.center,
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
              // No "started from {date}" subtitle on Home (design 3.7/L1):
              // static info already on the Profile hero — every line trimmed
              // here pulls the "today" ritual card closer to the fold.
              // No anniversary-countdown pill (user 2026-06-10): it doubled
              // the milestone countdown right below. Milestone progress +
              // streak chip close the card, with the chip at the very bottom.
              progressFooter: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInlineMilestoneProgress(
                    totalDays: totalDays,
                    nextMilestone: nextMilestone,
                    progress: progressToMilestone.clamp(0, 1),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 14),
                  // Couple streak chip (feature streak) — hides itself while
                  // waiting for a partner / on error (fail-soft).
                  const Center(child: StreakChip()),
                ],
              ),
              ),
                  // …plus a one-time coach-mark (auto-hides, never returns).
                  if (_showBgHint && bgCandidates.length >= 2)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.chevronLeft,
                                    size: 14, color: AppColors.white),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.counterBgSwipeHint,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(LucideIcons.chevronRight,
                                    size: 14, color: AppColors.white),
                              ],
                            ),
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 400),
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )),
          if (couple.isWaitingForPartner) ...[
            const SizedBox(height: 16),
            _gutter(_entrance(2, _buildWaitingForPartnerBanner(couple))),
          ],
          // ── Nhóm 1: Hôm nay của hai đứa — daily actions first (habit loop).
          const SizedBox(height: 28),
          _gutter(_entrance(
            3,
            _buildSectionTitle(title: l10n.homeTodaySectionTitle),
          )),
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _dailyQuestionKey,
            // Merged "today ritual" card: question + love note in ONE card
            // (tap-to-compose, blur teaser, collapsing done-state, envelope).
            child: _gutter(_entrance(3, _buildTodayRitualCard(couple))),
          ),
          // ── Nhóm 2: Kỷ niệm — create + browse.
          const SizedBox(height: 28),
          _gutter(_entrance(
            5,
            _buildSectionTitle(
              title: l10n.recentMemoriesTitle,
              subtitle: photos.isEmpty ? l10n.addPhotosPrompt : null,
              actionLabel: photos.isEmpty ? null : l10n.seeAll,
              onActionTap: photos.isEmpty
                  ? null
                  : () => setState(() => _selectedIndex = 1),
            ),
          )),
          const SizedBox(height: 12),
          // Full-bleed: the memory cinema escapes the gutter on purpose —
          // the add pill / empty state re-pad themselves inside.
          _entrance(
            6,
            _buildRecentPhotosSection(
              recentPhotos,
              isUploadingPhoto,
              couple,
              l10n,
              onThisDay: onThisDayPhoto,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _refreshHome() async {
    // Manual recovery when the photo stream stalls: re-arm the Firestore feed.
    // The counter/couple data is local-first and always current, so nothing
    // else needs forcing here.
    final currentUser = context.read<AuthProvider>().currentUser;
    await context.read<PhotoProvider>().syncForUser(currentUser);
  }

  /// Header bell that opens the notification center, with an unread-count badge
  /// (feature notifications). The count comes from the live Firestore-backed
  /// inbox stream, so it updates even when a push arrives while the app is open.
  void _openNotificationCenter() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'NotificationCenter'),
        builder: (_) => const NotificationCenterScreen(),
      ),
    );
  }

  /// Header "calendar leaf": today's day number, airy and light, with the
  /// weekday/month stacked behind a glowing vertical hairline. Echoes the
  /// big day count in the CounterCard — today's page in the couple's story.
  Widget _buildCalendarLeaf() {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    return Row(
      children: [
        Text(
          '${now.day}',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 40,
            fontWeight: FontWeight.w600,
            height: 1,
            // Soft DARK shadow, not a white halo: white-on-blush measures
            // ~1.5:1 on its own, and a light glow around light glyphs only
            // sinks them further. A dark drop is the standard treatment for
            // white type on a light ground (same as captions on photos).
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Vertical hairline, fading at both ends — the "torn edge".
        Container(
          width: 1.2,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white.withValues(alpha: 0.0),
                AppColors.white.withValues(alpha: 0.65),
                AppColors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.EEEE(locale).format(now).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Color(0x47000000), // black .28 — see day number
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                DateFormat.MMMM(locale).format(now).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  height: 1,
                  shadows: const [
                    Shadow(
                      color: Color(0x47000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    final unread = context.watch<NotificationInboxProvider>().unreadCount;
    // excludeSemantics: the badge digit carries no meaning on its own — the
    // label already announces the unread count, and onTap on the Semantics
    // node keeps double-tap activation working.
    return Semantics(
      label: context.l10n.notificationBellLabel(unread),
      button: true,
      excludeSemantics: true,
      onTap: _openNotificationCenter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Solid white disc + rose bell (redesign user 2026-06-10): the one
          // tappable thing in the header gets the one solid surface — light
          // surface → rose ink, per the design-system rule. The soft rose
          // shadow lifts it off the gradient without shouting.
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.92),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentLove.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: AppColors.accentRose.withValues(alpha: 0.12),
                onTap: _openNotificationCenter,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    LucideIcons.bell,
                    size: 21,
                    color: AppColors.accentLoveDeep,
                  ),
                ),
              ),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.accentLoveDeep,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingForPartnerBanner(Couple couple) {
    // Light card + dark ink — the white-on-white glass version washed out on
    // the blush gradient (contrast-debt cleanup, 2026-06-10).
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentLove.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.link,
              color: AppColors.accentLove,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeWaitingPartnerTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.homeWaitingPartnerSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
                          color: AppColors.accentLove.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          couple.inviteCode,
                          style: const TextStyle(
                            color: AppColors.accentLoveDeep,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      InviteActionButtons(
                        code: couple.inviteCode,
                        onDark: false,
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
    String? subtitle,
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
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.sectionSubtitleStyle(),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              // Real ink: even accentLoveDeep only reaches ~2.7:1 on the blush
              // gradient — 14px text needs textPrimary. Weight keeps the
              // link affordance.
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionLabel),
          ),
      ],
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
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
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

  /// Compact milestone progress rendered INSIDE the hero CounterCard
  /// (white-on-gradient, via [CounterCard.progressFooter]) — replaces the old
  /// standalone white "Cột mốc" card at the bottom of the tab.
  Widget _buildInlineMilestoneProgress({
    required int totalDays,
    required int nextMilestone,
    required double progress,
    required AppLocalizations l10n,
  }) {
    final daysLeft = nextMilestone - totalDays;

    // Two rows, human copy: "Cột mốc 1 tháng ... còn 26 ngày" + the bar.
    // (The old version said the same thing three times — "Tiếp:", "13% rồi"
    // and a trailing sentence — in label-speak.)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.flag,
              size: 15,
              color: AppColors.white.withValues(alpha: 0.92),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.milestoneNextLabel(_milestoneLabel(nextMilestone, l10n)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              daysLeft <= 0
                  ? l10n.milestoneTodayLabel
                  : l10n.milestoneDaysLeft(daysLeft),
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        ),
      ],
    );
  }

  /// The merged "Hôm nay của hai đứa" ritual card (question + love note).
  /// Keyed by couple + today's question so its one-shot state (confetti,
  /// collapsed reveal, envelope) resets cleanly on a couple/day change.
  Widget _buildTodayRitualCard(Couple couple) {
    final langCode = Localizations.localeOf(context).languageCode;
    final question =
        context.read<DailyQuestionProvider>().todayQuestion(langCode);
    return TodayRitualCard(
      key: ValueKey('today-${couple.id}-$question'),
      couple: couple,
    );
  }

  /// Leading tile of the polaroid strip — a blank polaroid waiting to be
  /// filled (the add-photo CTA living inside the content it creates).
  Widget _buildAddMemoryTile(AppLocalizations l10n, bool isLoading) {
    final tile = Container(
      width: 140,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _pickAndAddPhoto,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.accentLove.withValues(alpha: 0.07),
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentRose,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accentRose.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    l10n.addMemoryCta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.accentLoveDeep,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return isLoading ? Opacity(opacity: 0.6, child: tile) : tile;
  }

  Widget _buildRecentPhotosSection(
    List<Photo> photos,
    bool isLoading,
    Couple couple,
    AppLocalizations l10n, {
    Photo? onThisDay,
  }) {
    if (photos.isEmpty) {
      // One blank polaroid waiting for the first photo — same scrapbook
      // language as the filled strip (the old white card + button read as a
      // generic form).
      return _gutter(
        Column(
          children: [
            Text(
              l10n.addPhotosEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: Transform.rotate(
                angle: -0.02,
                child: _buildAddMemoryTile(l10n, isLoading),
              ),
            ),
          ],
        ),
      );
    }

    // "Memory cinema" (user 2026-06-10, replaces the polaroid strip): slides
    // lead with the "on this day" memory, then recents (deduped). The photo
    // currently serving as the CounterCard background is skipped so one
    // screen never shows the same memory twice — unless it's all we have.
    final slides = <Photo>[
      ?onThisDay,
      for (final p in photos)
        if (p.id != onThisDay?.id && p.id != _counterBgKey) p,
    ];
    if (slides.isEmpty) {
      slides.addAll(photos);
    }

    // No add-CTA here anymore (user 2026-06-10) — posting lives in the
    // Gallery tab composer + the quiet camera in the section header; Home
    // only *plays* the memories.
    return MemoryCinemaCard(
      photos: slides,
      onThisDayId: onThisDay?.id,
      onPhotoTap: (index) {
        AnalyticsService.instance.logMemoryCinemaOpened();
        return GalleryScreen.openPreview(
          context,
          photos: slides,
          heroTags: [for (final p in slides) 'cinema-photo-${p.id}'],
          initialIndex: index,
          couple: couple,
        );
      },
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
