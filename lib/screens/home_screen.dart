import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/counter_data.dart';
import '../models/photo.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/daily_question_provider.dart';
import '../providers/notification_inbox_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/answer_reaction_provider.dart';
import '../providers/reaction_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/streak_provider.dart';
import '../services/analytics_service.dart';
import '../services/catchup_service.dart';
import '../services/home_prefs_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/catchup_gate.dart';
import '../widgets/feature_tour_sheet.dart';
import '../widgets/content_card.dart';
import '../widgets/counter_card.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/memory_cinema_card.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/streak_chip.dart';
import '../providers/mood_provider.dart';
import '../widgets/mood_card.dart';
import '../widgets/today_ritual_card.dart';
import '../widgets/streak_sheet.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'gallery_screen.dart';
import 'care_message_screen.dart';
import 'notification_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const double _floatingNavHeight = 84;
  static const double _floatingNavMargin = 16;
  static const double _floatingNavSpacing = 18;
  static const double _floatingNavInnerPadding = 6;
  static const double _floatingNavPillInset = 5;

  // 4 tabs (feature chat, D1): Home · Chat · Gallery · Profile. The chat tab
  // sits beside Home (thumb position); deep-link indices follow this order.
  // Icon redesign 2026-06-14 (Iconsax): outline (Linear) when unselected, solid
  // (Bold) when selected — a warmer, more modern set than the old Lucide line.
  static const List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: IconsaxPlusLinear.heart,
      selectedIcon: IconsaxPlusBold.heart,
      color: AppColors.accentRose,
    ),
    _NavigationItem(
      icon: IconsaxPlusLinear.messages,
      selectedIcon: IconsaxPlusBold.messages,
      color: AppColors.accentRose,
    ),
    _NavigationItem(
      icon: IconsaxPlusLinear.gallery,
      selectedIcon: IconsaxPlusBold.gallery,
      color: AppColors.accentRose,
    ),
    _NavigationItem(
      icon: IconsaxPlusLinear.user,
      selectedIcon: IconsaxPlusBold.user,
      color: AppColors.accentRose,
    ),
  ];

  /// IndexedStack position of the chat tab (unread dot + seen marker logic).
  static const int _chatTabIndex = 1;

  int _selectedIndex = 0;

  /// The tab to return to when leaving the chat drill-in via its back button
  /// (user 2026-06-17). Chat hides the bottom nav, so it's the only tab the
  /// user can't step away from by tapping another nav item — we remember where
  /// they came from and restore it on back. Defaults to Home.
  int _previousIndex = 0;
  String? _lastReminderKey;

  /// Switches tabs while remembering the tab we're leaving — but only when
  /// entering chat, the one full-screen drill-in (its back button needs a
  /// destination). Any other target leaves `_previousIndex` untouched.
  void _selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      if (index == _chatTabIndex) {
        _previousIndex = _selectedIndex;
      }
      _selectedIndex = index;
    });
    _logTabScreenView(index);
    // Presence heartbeat lives here (not in chat_screen) because chat sits in an
    // IndexedStack and is never disposed on tab switch — so "am I viewing chat?"
    // is the selected tab, not whether the widget is mounted.
    if (index == _chatTabIndex) {
      _startChatPresence();
    } else {
      _stopChatPresence();
    }
  }

  /// Begins the chat presence heartbeat: marks me present now, then refreshes
  /// every 20s while the chat tab stays active (window in `notifyChatMessage` is
  /// 45s, so presence survives a dropped ping). Leaving the tab or backgrounding
  /// calls [_stopChatPresence], which CLEARS presence so notifications resume
  /// immediately — the freshness window is only a crash backstop.
  void _startChatPresence() {
    _chatPresenceTimer?.cancel();
    _chatProvider?.pingPresence();
    _chatPresenceTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && _selectedIndex == _chatTabIndex) {
        _chatProvider?.pingPresence();
      }
    });
  }

  void _stopChatPresence() {
    _chatPresenceTimer?.cancel();
    _chatPresenceTimer = null;
    // Clear presence the instant we leave so the partner's next message
    // notifies us right away (no lingering suppression).
    _chatProvider?.leavePresence();
  }

  /// Counter-card background selection (swipe ←/→ on the hero card cycles
  /// through the couple photo + recent gallery photos). Persisted per couple
  /// in the `app_settings` Hive box, keyed by photo id so the choice survives
  /// new uploads shifting the list.
  String? _counterBgKey;
  String? _counterBgCouple;

  /// One-time "swipe to change photo" coach-mark over the counter card.
  bool _showBgHint = false;
  Timer? _bgHintTimer;

  /// Presence heartbeat — runs only while the chat tab is the active screen so a
  /// partner's message won't notify someone who's already reading it
  /// (presence-suppress 2026-06-19). See _startChatPresence.
  Timer? _chatPresenceTimer;

  /// Direction of the last background swipe (+1 next / -1 previous) — drives
  /// the slide-in side of the photo transition.
  int _bgSwipeDirection = 1;

  /// Couple-shared background selection (couples/{id}/prefs/home): a swipe on
  /// either phone moves BOTH cards. Hive stays as the offline/local cache.
  final HomePrefsService _homePrefs = HomePrefsService();
  StreamSubscription<String?>? _bgSyncSub;

  /// Couple-shared whitelist of photo ids allowed as the counter background
  /// (Settings → "Ảnh nền thẻ đếm", 2026-06-14). Empty = no restriction (cycle
  /// through everything, the original behaviour). Hive caches it offline.
  List<String> _counterBgIds = const <String>[];
  StreamSubscription<List<String>>? _bgIdsSyncSub;

  /// Couple-shared Chat-tab background (feature chat-background, 2026-06-18):
  /// the picked photo id (or null = gradient). Rendered FULL-BLEED at this shell
  /// level — behind the status bar — because the chat tab sits inside the shared
  /// SafeArea+IndexedStack and can't escape it on its own.
  String? _chatBgKey;
  StreamSubscription<String?>? _chatBgSub;

  void _ensureCounterBgLoaded(String coupleId) {
    if (_counterBgCouple == coupleId) {
      return;
    }
    _counterBgCouple = coupleId;
    try {
      final box = Hive.box<String>('app_settings');
      _counterBgKey = box.get('counter_bg_$coupleId');
      final cachedIds = box.get('counter_bg_ids_$coupleId');
      _counterBgIds = (cachedIds == null || cachedIds.isEmpty)
          ? const <String>[]
          : cachedIds.split('\n');
      _showBgHint = box.get('counter_bg_hint_done') == null;
      final chatBg = box.get('chat_bg_photo_$coupleId');
      _chatBgKey = (chatBg == null || chatBg.isEmpty) ? null : chatBg;
    } catch (_) {
      _counterBgKey = null; // Box unavailable → session-only selection.
      _counterBgIds = const <String>[];
      _showBgHint = false;
      _chatBgKey = null;
    }
    // Follow the couple-shared chat background (a pick in Settings on either
    // phone repaints both chats; '' clears it back to the gradient).
    _chatBgSub?.cancel();
    _chatBgSub = _homePrefs.watchChatBg(coupleId).listen((key) {
      if (!mounted || key == _chatBgKey) {
        return;
      }
      setState(() => _chatBgKey = key);
      try {
        Hive.box<String>('app_settings')
            .put('chat_bg_photo_$coupleId', key ?? '');
      } catch (_) {
        // Cache only — the in-memory value is already set.
      }
    });
    // Follow the couple-shared whitelist (a change in Settings on either phone
    // re-filters both cards).
    _bgIdsSyncSub?.cancel();
    _bgIdsSyncSub = _homePrefs.watchCounterBgIds(coupleId).listen((ids) {
      if (!mounted) {
        return;
      }
      setState(() => _counterBgIds = ids);
      try {
        Hive.box<String>(
          'app_settings',
        ).put('counter_bg_ids_$coupleId', ids.join('\n'));
      } catch (_) {
        // Cache only — the in-memory value is already set.
      }
    });
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

  /// Resolve the picked chat-background key ('couple' cover or a gallery photo
  /// id) to an image provider — local file first (instant/offline), else the
  /// network URL. Null when nothing is picked or the photo no longer exists.
  ImageProvider? _resolveChatBg(Couple couple, List<Photo> photos) {
    final id = _chatBgKey;
    if (id == null || id.isEmpty) {
      return null;
    }
    String? local;
    String? remote;
    if (id == 'couple') {
      local = couple.couplePhotoPath;
      remote = couple.couplePhotoUrl;
    } else {
      for (final p in photos) {
        if (p.id == id) {
          local = p.path;
          remote = p.remoteUrl;
          break;
        }
      }
    }
    if (local != null && local.trim().isNotEmpty) {
      final file = File(local);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    if (remote != null && remote.trim().isNotEmpty) {
      return CachedNetworkImageProvider(remote);
    }
    return null;
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
    ({String key, String? local, String? remote})? couplePhoto;
    if ((couple.couplePhotoUrl?.trim().isNotEmpty ?? false) ||
        (couple.couplePhotoPath?.trim().isNotEmpty ?? false)) {
      couplePhoto = (
        key: 'couple',
        local: couple.couplePhotoPath,
        remote: couple.couplePhotoUrl,
      );
    }

    // Whitelist mode (Settings → "Ảnh nền thẻ đếm"): keep only the picked
    // photos, scanning ALL loaded photos (not just the recent 12) so an older
    // pick still shows. Falls back to the default pool if none of the picks are
    // in the current window, so the card is never blank.
    final whitelist = _counterBgIds;
    if (whitelist.isNotEmpty) {
      final picked = <({String key, String? local, String? remote})>[
        if (couplePhoto != null && whitelist.contains('couple')) couplePhoto,
        for (final p in photos)
          if (whitelist.contains(p.id) && (p.hasLocalPath || p.hasRemoteUrl))
            (key: p.id, local: p.path, remote: p.remoteUrl),
      ];
      if (picked.isNotEmpty) {
        return picked;
      }
    }

    // Default (no whitelist): couple photo + the 12 most recent.
    return [
      ?couplePhoto,
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
      Hive.box<String>(
        'app_settings',
      ).put('counter_bg_$coupleId', candidates[next].key);
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

  // Daily-question end-of-day safety net (2026-06-19): on every daily-question /
  // streak update we re-arm the 21/22/23h local nudges from live habit state, so
  // they fire only while today's question isn't both-answered yet.
  DailyQuestionProvider? _dqProvider;

  /// Guards [FeatureTour.maybeShow] to one attempt per Home lifetime.
  bool _featureTourChecked = false;

  /// Captured in initState so the chat presence heartbeat can be cleared safely
  /// from dispose without touching a deactivated BuildContext (presence-suppress
  /// 2026-06-19).
  ChatProvider? _chatProvider;

  // Catch-up gate (feature `catch-up`, 2026-09-05) — ACCOUNT-GATED to em bé
  // ([CatchupService.gatedEmail]). Scans the last 14 days for questions she
  // never answered, blocks Home with the make-up form and keeps the
  // "Anh By <3" nudge band (1140–1159) in sync with the backlog. Every other
  // account short-circuits inside [_maybeRunCatchup] before any read.
  final CatchupService _catchupService = CatchupService();
  bool _catchupBusy = false;
  DateTime? _catchupLastCheck;
  String? _catchupLastDay;

  /// Standard 16px page gutter, applied PER BLOCK (the scroll view itself has
  /// no horizontal padding).
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
    // Chat presence (presence-suppress 2026-06-19): observe app lifecycle so we
    // can clear presence when backgrounded while on the chat tab.
    WidgetsBinding.instance.addObserver(this);
    // Cold-start deep-link: a terminated→tap set the pending tab inside
    // PushNotificationService.initialize() (before this mounted), so apply it
    // now as the initial tab. Then listen for warm taps while mounted.
    _applyPendingTab(NotificationTapRouter.pendingHomeTab.value);
    NotificationTapRouter.consumeHomeTabRequest();
    NotificationTapRouter.pendingHomeTab.addListener(_onNotificationTapRequest);

    // Cold-start / warm deep-link to a specific Home card (e.g. daily question).
    _applyPendingFocus(NotificationTapRouter.pendingHomeFocus.value);
    NotificationTapRouter.consumeHomeFocusRequest();
    NotificationTapRouter.pendingHomeFocus.addListener(
      _onNotificationFocusRequest,
    );

    // Watch for a freshly-reached streak milestone to auto-celebrate.
    _streakProvider = context.read<StreakProvider>();
    _streakProvider!.addListener(_onStreakChanged);

    // Keep the end-of-day daily-question safety net (21/22/23h) in sync with
    // live habit state. Both providers feed it; re-arm on each update + once now.
    _dqProvider = context.read<DailyQuestionProvider>();
    _chatProvider = context.read<ChatProvider>();
    _dqProvider!.addListener(_refreshDqSafetyNet);
    _streakProvider!.addListener(_refreshDqSafetyNet);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDqSafetyNet());
    // "Có gì mới" tour (feature onboarding, 2026-09-05): once per build, after
    // the first frame settles and never on top of the catch-up gate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _featureTourChecked || CatchupGate.isShowing) {
          return;
        }
        _featureTourChecked = true;
        FeatureTour.maybeShow(context, onOpenTab: _selectTab);
      });
    });
  }

  @override
  void dispose() {
    NotificationTapRouter.pendingHomeTab.removeListener(
      _onNotificationTapRequest,
    );
    NotificationTapRouter.pendingHomeFocus.removeListener(
      _onNotificationFocusRequest,
    );
    _streakProvider?.removeListener(_onStreakChanged);
    _streakProvider?.removeListener(_refreshDqSafetyNet);
    _dqProvider?.removeListener(_refreshDqSafetyNet);
    _bgHintTimer?.cancel();
    _stopChatPresence();
    WidgetsBinding.instance.removeObserver(this);
    _chatBgSub?.cancel();
    _bgSyncSub?.cancel();
    _bgIdsSyncSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Catch-up gate: re-scan the backlog on every resume (covers the day rolling
    // over in the background and answers made on the other device). No-ops for
    // every account but the gated one.
    if (state == AppLifecycleState.resumed) {
      _maybeRunCatchup(force: true);
    }
    // Chat presence (presence-suppress 2026-06-19): only meaningful while the
    // chat tab is the active screen. Backgrounding clears presence so the
    // partner's messages notify me again; resuming re-arms the heartbeat.
    if (_selectedIndex != _chatTabIndex) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _startChatPresence();
    } else {
      _stopChatPresence();
    }
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

  /// Re-arm the end-of-day daily-question nudges (21/22/23h) from the current
  /// habit state. Fired on every daily-question / streak update (and once on
  /// launch); the ReminderProvider debounces redundant reschedules and only
  /// schedules while today's question isn't both-answered yet.
  void _refreshDqSafetyNet() {
    if (!mounted) {
      return;
    }
    final dq = _dqProvider;
    final streak = _streakProvider;
    if (dq == null || streak == null) {
      return;
    }
    final reminders = context.read<ReminderProvider>();
    // Private "anh By → embe" nudges, gated to one account (2026-06-20). Evaluated
    // FIRST so the gated-account flag is set before the shared schedulers below:
    // on em bé's device her hourly nudge replaces the shared daily-question +
    // end-of-day reminders (suppressed there to avoid double notifications). The
    // hourly band stops the moment she answers and re-arms each launch/update.
    final auth = context.read<AuthProvider>();
    final email = auth.currentUser?.email ?? auth.currentEmail ?? '';
    reminders.refreshPersonalReminders(
      email: email,
      iAnswered: dq.hasAnswered,
      // Skip the hourly-question band while the DQ stream is mid-(re)subscribe
      // (answers momentarily empty → hasAnswered flickers false) so we never
      // re-arm stale nudges that fire after she's answered (bug 2026-06-20).
      isLoading: dq.isLoading,
    );
    // Skip while the DQ stream is mid-(re)subscribe: answers are momentarily
    // empty so hasRevealed/hasAnswered flicker false, which would re-arm the
    // end-of-day nudges we just cancelled (same race as the personal band).
    // The settled notify that follows re-runs this with the real state.
    if (!dq.isLoading) {
      reminders.refreshDailyQuestionSafetyNet(
        hasRevealed: dq.hasRevealed,
        iAnswered: dq.hasAnswered,
        currentStreak: streak.currentStreak,
        l10n: context.l10n,
      );
    }
  }

  /// Catch-up gate (feature `catch-up`, 2026-09-05) — ACCOUNT-GATED.
  ///
  /// Scans the last 14 days for daily questions the user never answered, keeps
  /// the "Anh By <3" nudge band in sync with that backlog and — when there IS a
  /// backlog — blocks Home with the un-dismissable make-up form. Everything is
  /// fail-soft (the service swallows read errors and returns an empty list), so
  /// a network hiccup simply means "no backlog" and the app runs as usual.
  ///
  /// Throttled to once per 5 minutes per day (a rolled-over day or [force] from
  /// a resume re-runs it immediately).
  /// Pushes the live context the question engine may condition on (streak,
  /// today's moods, photos this week, partner uid, anniversary, language).
  /// Cheap + idempotent; the provider only re-resolves on a new (couple, day).
  void _syncQuestionContext(Couple couple, String myUid) {
    if (!mounted) {
      return;
    }
    final moods = context.read<MoodProvider>();
    final photos = context.read<PhotoProvider>().photos;
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final photosThisWeek =
        photos.where((p) => !p.uploadDate.isBefore(weekStart)).length;
    final partnerUid = couple.memberIds.firstWhere(
      (m) => m != myUid,
      orElse: () => '',
    );
    context.read<DailyQuestionProvider>().updateContext(
      currentStreak: context.read<StreakProvider>().currentStreak,
      myMood: moods.myMood?.mood,
      partnerMood: moods.partnerMood?.mood,
      photosThisWeek: photosThisWeek,
      partnerUid: partnerUid,
      languageCode: Localizations.localeOf(context).languageCode,
      anniversaryDate: couple.anniversaryDate,
    );
  }

  Future<void> _maybeRunCatchup({bool force = false}) async {
    if (!mounted || _catchupBusy || CatchupGate.isShowing) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final email = auth.currentUser?.email ?? auth.currentEmail ?? '';
    if (!CatchupService.isGatedEmail(email)) {
      return;
    }
    final myUid = auth.currentUser?.id;
    final couple = context.read<CoupleProvider>().couple;
    if (myUid == null ||
        myUid.isEmpty ||
        couple == null ||
        couple.id.isEmpty ||
        // A couple still waiting for the partner can never reveal a day, so
        // there is nothing to catch up on.
        couple.isWaitingForPartner) {
      return;
    }

    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    final last = _catchupLastCheck;
    if (!force &&
        _catchupLastDay == dayKey &&
        last != null &&
        now.difference(last) < const Duration(minutes: 5)) {
      return;
    }
    _catchupBusy = true;
    _catchupLastDay = dayKey;
    _catchupLastCheck = now;

    try {
      final missed = await _catchupService.findMissedDays(
        coupleId: couple.id,
        myUid: myUid,
      );
      if (!mounted) {
        return;
      }
      await context.read<ReminderProvider>().refreshPersonalCatchupReminders(
        email: email,
        missedCount: missed.length,
      );
      if (missed.isEmpty || !mounted) {
        return;
      }
      await CatchupGate.show(
        context,
        coupleId: couple.id,
        myUid: myUid,
        days: missed,
      );
      if (!mounted) {
        return;
      }
      // The gate only closes once every missed day has been answered.
      await context.read<ReminderProvider>().refreshPersonalCatchupReminders(
        email: email,
        missedCount: 0,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xong rồi, cảm ơn embe 💕')),
      );
    } finally {
      _catchupBusy = false;
    }
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
      _selectTab(requested);
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

  /// Logs a `screen_view` for the Home bottom-nav tabs (0=Home, 1=Chat,
  /// 2=Gallery, 3=Profile) — these are IndexedStack children, not routes, so
  /// the navigator observer can't see them. (feature analytics)
  void _logTabScreenView(int index) {
    const names = ['Home', 'Chat', 'Gallery', 'Profile'];
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
    // `coupleActive` is part of the key: the daily-question nudges are gated on it
    // (a solo waiting_partner couple must not be nudged), so the partner joining
    // has to re-trigger a sync.
    final coupleActive = !couple.isWaitingForPartner;
    final key = [
      couple.anniversaryDate.millisecondsSinceEpoch,
      lastPhotoDate?.millisecondsSinceEpoch ?? 0,
      l10n.localeName,
      coupleActive,
      '${now.year}-${now.month}-${now.day}',
    ].join('|');
    if (key == _lastReminderKey) {
      return;
    }
    _lastReminderKey = key;

    final reminderProvider = context.read<ReminderProvider>();
    final anniversaryDate = couple.anniversaryDate;
    final coupleCreatedAt = couple.createdAt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      reminderProvider.sync(
        anniversaryDate: anniversaryDate,
        lastPhotoDate: lastPhotoDate,
        l10n: l10n,
        coupleActive: coupleActive,
      );
      // Invite follow-ups (feature onboarding): while the partner still hasn't
      // joined, nudge this member 24h/72h after the couple was created; the
      // provider cancels the band as soon as the couple goes active.
      reminderProvider.refreshInviteFollowUps(
        waiting: !coupleActive,
        coupleCreatedAt: coupleCreatedAt,
        l10n: l10n,
      );
    });
  }

  String _navLabel(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.navHome;
      case 1:
        return l10n.navChat;
      case 2:
        return l10n.navMemories;
      case 3:
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
      // Gutter per block (matches the live layout).
      padding: EdgeInsets.fromLTRB(0, topPadding + 16, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: greeting chip pill + bell (matches the live one-chip
          // header, header-unify 2026-06-14).
          _gutter(
            Row(
              children: const [
                ShimmerSkeleton(width: 168, height: 31, borderRadius: 999),
                Spacer(),
                ShimmerSkeleton(width: 48, height: 48, borderRadius: 17),
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
          // Memory cinema card (gutter + card radius, like every other card).
          _gutter(const ShimmerSkeleton(height: 240, borderRadius: 28)),
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
          context.read<NotificationInboxProvider>().markReadForTab(
            _selectedIndex,
          );
        }
      });
    }

    // Chat seen marker (feature chat, D7): sitting on the chat tab consumes
    // unread messages — covers landing on the tab AND a partner message
    // arriving while the tab is already open. Watching makes it re-fire on
    // every chat stream emission; markSeen is idempotent so it converges.
    final chat = context.watch<ChatProvider>();
    if (_selectedIndex == _chatTabIndex && chat.hasUnread) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ChatProvider>().markSeen();
        }
      });
    }

    return PopScope(
      // System back inside the chat drill-in returns to the previous tab rather
      // than popping the Home route (user 2026-06-17) — mirrors the header back
      // icon. Every other tab keeps the default pop (exit the app).
      canPop: _selectedIndex != _chatTabIndex,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex == _chatTabIndex) {
          _selectTab(_previousIndex == _chatTabIndex ? 0 : _previousIndex);
        }
      },
      child: Scaffold(
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

            // Wire the couple-shared backgrounds up front (idempotent per
            // couple) so the chat backdrop below resolves on the first frame.
            _ensureCounterBgLoaded(couple.id);
            final chatBg = _selectedIndex == _chatTabIndex
                ? _resolveChatBg(couple, photoProvider.sortedPhotos)
                : null;

            return Stack(
              children: [
                // Base gradient (every tab) — a full-screen layer so the chat
                // backdrop can sit between it and the content, behind the
                // status bar.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.secondaryGradient,
                    ),
                  ),
                ),
                // Full-bleed chat background (chat tab only, when picked): the
                // photo fills the entire screen, including behind the status
                // bar, with a soft scrim for bubble/date readability.
                if (chatBg != null) ...[
                  Positioned.fill(
                    child: Image(
                      image: chatBg,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x33000000),
                              Color(0x14000000),
                              Color(0x3D000000),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SafeArea(
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
                          child: ChatScreen(
                            // HomeScreen's context sits ABOVE the Scaffold, so
                            // it still sees the raw keyboard inset the Scaffold
                            // strips from its body's MediaQuery.
                            keyboardVisible: mediaQuery.viewInsets.bottom > 0,
                            // Photo backdrop active → the back arrow needs its
                            // frosted disc to stay legible over dark regions.
                            hasBackground: chatBg != null,
                            onRequestTab: (index) {
                              if (index >= 0 &&
                                  index < _navigationItems.length) {
                                _selectTab(index);
                              }
                            },
                            // Back leaves the chat drill-in for the tab the user
                            // came from (Home if none). Guard against returning to
                            // chat itself.
                            onBack: () => _selectTab(
                              _previousIndex == _chatTabIndex
                                  ? 0
                                  : _previousIndex,
                            ),
                          ),
                        ),
                        TickerMode(
                          enabled: _selectedIndex == 2,
                          child: GalleryScreen(bottomInset: bottomInset),
                        ),
                        TickerMode(
                          enabled: _selectedIndex == 3,
                          child: ProfileScreen(
                            bottomInset: bottomInset,
                            // A Profile badge (e.g. "Kỷ niệm") can jump to a tab.
                            onRequestTab: (index) {
                              if (index >= 0 &&
                                  index < _navigationItems.length) {
                                _selectTab(index);
                              }
                            },
                          ),
                        ),
                      ],
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
      ),
    );
  }

  Widget _buildFloatingNavigationBar() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final l10n = context.l10n;
    // Unread dot on the chat tab (D7) — partner messages newer than the seen
    // marker. Watched here so the dot pops/falls live with the chat stream.
    final chatHasUnread = context.watch<ChatProvider>().hasUnread;

    // The nav slides fully away both when typing AND while the chat drill-in is
    // open (user 2026-06-17): chat is a full-screen view reached/left by its own
    // back button, so the peer-tab bar must not show there.
    final hideNav = isKeyboardVisible || _selectedIndex == _chatTabIndex;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: hideNav ? const Offset(0, 1.2) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: hideNav ? 0 : 1,
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
                    final pillWidth = itemWidth - _floatingNavPillInset * 2;
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
                                  color: AppColors.accentLove.withValues(
                                    alpha: 0.40,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ── Nav items ────────────────────────────────────
                        Row(
                          children: List.generate(_navigationItems.length, (
                            index,
                          ) {
                            final item = _navigationItems[index];
                            final isSelected = index == _selectedIndex;
                            final label = _navLabel(index, l10n);

                            // Dot only when the chat tab is NOT active
                            // (landing on it marks seen immediately).
                            final showUnreadDot =
                                index == _chatTabIndex &&
                                !isSelected &&
                                chatHasUnread;

                            return Expanded(
                              child: _buildNavigationItem(
                                item: item,
                                index: index,
                                isSelected: isSelected,
                                label: label,
                                showUnreadDot: showUnreadDot,
                              ),
                            );
                          }),
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
    bool showUnreadDot = false,
  }) {
    // VoiceOver announces the waiting message alongside the tab name when the
    // dot is up (design §A).
    final semanticsLabel = showUnreadDot
        ? '$label, ${context.l10n.chatUnreadDotSemantics}'
        : label;

    return Tooltip(
      message: semanticsLabel,
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
            _selectTab(index);
          },
          child: SizedBox.expand(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        scale: isSelected ? 1.12 : 1.0,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected
                                ? (item.selectedIcon ?? item.icon)
                                : item.icon,
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
                      // Chat unread dot (D7): 10px total — 7px accentLoveDeep
                      // core + 1.5 solid white ring (separates it from the
                      // icon and the glass). Scales in/out 200ms; Reduce
                      // Motion shows/hides it instantly.
                      if (index == _chatTabIndex)
                        Positioned(
                          top: -3,
                          right: -4,
                          child: IgnorePointer(
                            child: AnimatedScale(
                              duration: AppMotion.reduceMotion(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              scale: showUnreadDot ? 1.0 : 0.0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.accentLoveDeep,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
    // Pinned header (header-sync 2026-06-14): the greeting chip + bell sit ABOVE
    // the scroll so the bell stays reachable while scrolling — the same
    // fixed-header structure Chat/Gallery/Profile already use. Only Home let its
    // header scroll away with the content, which read as "inconsistent" across
    // the four tabs (the action icon vanished here but stayed on the others).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          child: _gutter(
            // One chip + the bell, same shape/height as the other three tabs;
            // the time-of-day greeting lives INSIDE the chip. Top-aligned (Row
            // start + chip Align.topLeft) so the ~27pt chip sits at the row top
            // beside the taller 48pt bell, matching the icon-less tabs.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _buildGreetingChip(),
                  ),
                ),
                const SizedBox(width: 12),
                _buildCareButton(),
                _buildNotificationBell(),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildHomeScrollBody(
            couple,
            counterData,
            photos,
            isUploadingPhoto,
            bottomInset,
          ),
        ),
      ],
    );
  }

  /// The scrolling body of the Home tab (everything below the pinned header).
  Widget _buildHomeScrollBody(
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
    // Pagination D3: on-this-day comes from the provider's dedicated query —
    // the realtime window only holds the newest 30 photos, so filtering the
    // visible list would miss older memories.
    final onThisDayPhoto = _onThisDayPhoto(
      context.read<PhotoProvider>().onThisDayPhotos,
    );

    // Re-arm the couple's realtime streams. SessionResolver already starts
    // them, but the couple may finish loading after Home mounts (or change),
    // so re-arm here. Every watchForCouple no-ops when unchanged.
    final myUid = context.read<AuthProvider>().currentUser?.id;
    if (myUid != null && couple.id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // On-this-day memories (pagination D3) — deduped per calendar day
          // inside the provider, so this re-arm is cheap. Also covers the
          // date rolling over while the app stays open.
          context.read<PhotoProvider>().refreshOnThisDay(
            anniversary: couple.anniversaryDate,
          );
          // Feed streak/mood/photos/anniversary to the question engine BEFORE
          // the first resolve of the day — resolve runs once per (couple, day)
          // and the marker it writes is final, so context must arrive first.
          _syncQuestionContext(couple, myUid);
          context.read<DailyQuestionProvider>().watchForCouple(
            couple.id,
            myUid,
          );
          context.read<ReactionProvider>().watchForCouple(couple.id, myUid);
          context
              .read<AnswerReactionProvider>()
              .watchForCouple(couple.id, myUid);
          // Mood (feature mood) — re-arm so the card is live + resets at midnight.
          context.read<MoodProvider>().watchForCouple(couple.id, myUid);
          // Chat stream (feature chat) — must run from Home so the unread dot
          // works on every tab. watchForCouple no-ops when unchanged.
          context.read<ChatProvider>().watchForCouple(couple.id, myUid);
          // Re-arm the streak too — it must flip from hidden→active the moment
          // the partner joins while Home stays open. watchForCouple no-ops when
          // (couple, active) is unchanged.
          context.read<StreakProvider>().watchForCouple(
            couple.id,
            coupleActive: !couple.isWaitingForPartner,
          );
          // Notification center stream — re-arm so the bell badge stays live
          // even if the couple finished loading after Home mounted.
          context.read<NotificationInboxProvider>().watchForCouple(
            couple.id,
            myUid,
          );
          // Catch-up gate (account-gated): covers cold start, the couple
          // finishing its load after Home mounted, and the date rolling over
          // while the app stays open. Throttled inside.
          _maybeRunCatchup();
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
        // The greeting chip + bell are now PINNED above this scroll
        // (header-sync 2026-06-14); their old 20pt bottom gap becomes the
        // body's top padding. Horizontal gutter is applied per block (`_gutter`).
        padding: EdgeInsets.fromLTRB(0, 20, 0, bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _gutter(
              _entrance(
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
                    _swipeCounterBg(
                      velocity < 0 ? 1 : -1,
                      bgCandidates,
                      couple.id,
                    );
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
                          pulseHeart: true, // hero counter — the one heart that breathes
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
                              child:
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          IconsaxPlusLinear.arrow_left_2,
                                          size: 14,
                                          color: AppColors.white,
                                        ),
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
                                        const Icon(
                                          IconsaxPlusLinear.arrow_right_3,
                                          size: 14,
                                          color: AppColors.white,
                                        ),
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
              ),
            ),
            if (couple.isWaitingForPartner) ...[
              const SizedBox(height: 16),
              _gutter(_entrance(2, _buildWaitingForPartnerBanner(couple))),
            ],
            // ── Nhóm 1: Hôm nay của chúng mình — daily actions first (habit loop).
            const SizedBox(height: 28),
            _gutter(
              _entrance(3, SectionHeader(title: l10n.homeTodaySectionTitle)),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: _dailyQuestionKey,
              // Merged "today ritual" card: question + love note in ONE card
              // (tap-to-compose, blur teaser, collapsing done-state, envelope).
              child: _gutter(_entrance(3, _buildTodayRitualCard(couple))),
            ),
            // Daily mood check-in (feature mood) — only once the partner is in
            // (a one-sided mood card has no "how is your person" payoff).
            if (!couple.isWaitingForPartner) ...[
              const SizedBox(height: 16),
              _gutter(_entrance(4, MoodCard(couple: couple))),
            ],
            // ── Nhóm 2: Kỷ niệm — create + browse.
            const SizedBox(height: 28),
            _gutter(
              _entrance(
                5,
                SectionHeader(
                  title: l10n.recentMemoriesTitle,
                  subtitle: photos.isEmpty ? l10n.addPhotosPrompt : null,
                  actionLabel: photos.isEmpty ? null : l10n.seeAll,
                  // Gallery moved to index 2 when the chat tab landed (feature chat).
                  onActionTap: photos.isEmpty
                      ? null
                      : () => setState(() => _selectedIndex = 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Memory cinema sits in the standard gutter like every other card
            // (user 2026-06-11) — the section pads itself inside.
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

  /// Header chip: the time-of-day greeting + the user's name, rendered INSIDE
  /// the shared [EyebrowChip] so Home's header is the same one-chip shape as
  /// the other three tabs (user 2026-06-14 "để lời chào trong chip"). A
  /// time-aware leading glyph (sunrise/sun/sunset/moon) replaces the static
  /// sparkles the label chips use, and the greeting is upper-cased to read as
  /// an eyebrow like "HỒ SƠ TÌNH YÊU" / "THƯ VIỆN RIÊNG TƯ".
  Widget _buildGreetingChip() {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    final String greeting;
    final IconData icon;
    if (hour >= 5 && hour < 12) {
      greeting = l10n.homeGreetingMorning;
      icon = IconsaxPlusLinear.sun_1;
    } else if (hour >= 12 && hour < 18) {
      greeting = l10n.homeGreetingAfternoon;
      icon = IconsaxPlusLinear.sun_1;
    } else if (hour >= 18 && hour < 22) {
      greeting = l10n.homeGreetingEvening;
      icon = IconsaxPlusLinear.sun_1;
    } else {
      greeting = l10n.homeGreetingNight;
      icon = IconsaxPlusLinear.moon;
    }
    final name =
        context.read<AuthProvider>().currentUser?.displayName.trim() ?? '';
    // Greeting strings end with a comma ("Chào buổi sáng,") so the name slots
    // in naturally; with no name we drop the dangling comma instead.
    final title = name.isEmpty
        ? greeting.replaceAll(RegExp(r',\s*$'), '')
        : '$greeting $name';
    return EyebrowChip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accentLoveDeep),
          const SizedBox(width: 7),
          // Flexible + ellipsis so a long display name can't overflow the
          // chip when the Align/Expanded parent bounds it.
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.pageEyebrowStyle(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }

  /// Header "care note" button (feature care-message, 2026-09-05): opens the
  /// compose screen where the user sends a caring title + message that lands
  /// on the partner's phone as a push. Same bare 48px glyph as the bell so the
  /// Home header stays one chip + icons like the other tabs.
  Widget _buildCareButton() {
    final l10n = context.l10n;
    return Semantics(
      label: l10n.careMessageEntryTitle,
      button: true,
      excludeSemantics: true,
      onTap: () => openCareMessageScreen(context),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            splashColor: AppColors.accentRose.withValues(alpha: 0.12),
            onTap: () {
              HapticFeedback.selectionClick();
              openCareMessageScreen(context);
            },
            child: const Center(
              child: Icon(
                IconsaxPlusLinear.message_favorite,
                size: 26,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
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
          // Bare bell, dark ink (user 2026-06-11: bare header icons app-wide —
          // the frosted white squircle was dropped everywhere). 48px touch
          // target unchanged; flips to bell-ring while anything is unread.
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                splashColor: AppColors.accentRose.withValues(alpha: 0.12),
                onTap: _openNotificationCenter,
                child: Center(
                  child: Icon(
                    unread > 0
                        ? IconsaxPlusLinear.notification_bing
                        : IconsaxPlusLinear.notification,
                    size: 26,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (unread > 0)
            // Anchored to the bare glyph (was -4/-4 against the old 48 box).
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentLove, AppColors.accentLoveDeep],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentLoveDeep.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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

  /// Waiting-for-partner block (feature onboarding, 2026-09-05) — used to be a
  /// one-line banner ("share your code") that left A guessing what happens next.
  /// Now a 3-step checklist on the standard [ContentCard]: send the invite (with
  /// the code + a primary share CTA), the partner installs & signs up, they enter
  /// the code. Closes with what A can already do solo, so the wait isn't dead
  /// time. Realtime swap to the full Home when the partner joins is unchanged.
  Widget _buildWaitingForPartnerBanner(Couple couple) {
    final l10n = context.l10n;
    // Couple-level code when present (leave/rejoin flow), personal invite code
    // as the legacy fallback — same rule as the Setup card.
    final code = (couple.coupleCode?.isNotEmpty ?? false)
        ? couple.coupleCode!
        : couple.inviteCode;
    final hasCode = code.isNotEmpty;

    return ContentCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EyebrowChip(
            label: l10n.homeWaitingBadge,
            icon: IconsaxPlusLinear.timer_1,
          ),
          const SizedBox(height: 14),
          _buildWaitingStep(
            index: 1,
            title: l10n.homeWaitingStep1Title,
            description: l10n.homeWaitingStep1Desc,
            child: hasCode
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // The code stays big and selectable — it's the one thing
                      // the partner has to read out loud.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLove.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            color: AppColors.accentLoveDeep,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Primary pill (h52, r999) — the single obvious action.
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Material(
                          color: AppColors.accentLove,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => _shareInviteCode(code),
                            child: Center(
                              child: Text(
                                l10n.homeWaitingStep1Cta,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: AppColors.accentRose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => _copyInviteCode(code),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    IconsaxPlusLinear.copy,
                                    size: 14,
                                    color: AppColors.accentRose,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.homeWaitingStep1Copy,
                                    style: const TextStyle(
                                      color: AppColors.accentRose,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 14),
          _buildWaitingStep(
            index: 2,
            title: l10n.homeWaitingStep2Title,
            description: l10n.homeWaitingStep2Desc,
          ),
          const SizedBox(height: 14),
          _buildWaitingStep(
            index: 3,
            title: l10n.homeWaitingStep3Title,
            description: l10n.homeWaitingStep3Desc,
            isLast: true,
          ),
          const SizedBox(height: 16),
          Divider(
            thickness: 0.5,
            height: 0.5,
            color: AppColors.textPrimary.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.homeWaitingMeanwhileTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...<String>[
            l10n.homeWaitingMeanwhileItem1,
            l10n.homeWaitingMeanwhileItem2,
            l10n.homeWaitingMeanwhileItem3,
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      IconsaxPlusBold.heart,
                      size: 11,
                      color: AppColors.accentRose,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.homeWaitingMeanwhileFooter,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// One numbered row of the waiting checklist: rose numeral disc + title +
  /// description, with an optional [child] block under the text (step 1's code
  /// and actions). A hairline connector runs down from the disc except on the
  /// last step.
  Widget _buildWaitingStep({
    required int index,
    required String title,
    required String description,
    Widget? child,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentLove.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: AppColors.accentLoveDeep,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.accentLove.withValues(alpha: 0.14),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                ?child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Share sheet for the invite code — same message + analytics event as
  /// [InviteActionButtons] (kept in sync deliberately; the checklist needs a
  /// full-width primary CTA that the compact pill cluster can't provide).
  Future<void> _shareInviteCode(String code) async {
    final message = context.l10n.inviteShareMessage(code);
    // iPad/macOS need a popover origin or the share sheet crashes.
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? (box.localToGlobal(Offset.zero) & box.size)
        : null;
    AnalyticsService.instance.logInviteShared('share_sheet');
    try {
      await SharePlus.instance.share(
        ShareParams(text: message, sharePositionOrigin: origin),
      );
    } catch (_) {
      // OS-driven failures stay silent (no error toast), per design.
    }
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AnalyticsService.instance.logInviteShared('copy');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.inviteCodeCopiedMsg),
        duration: const Duration(seconds: 2),
      ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.photoAddedSuccess)));
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
              IconsaxPlusLinear.flag,
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

  /// The merged "Hôm nay của chúng mình" ritual card (question + love note).
  /// Keyed by couple + today's question so its one-shot state (confetti,
  /// collapsed reveal, envelope) resets cleanly on a couple/day change.
  Widget _buildTodayRitualCard(Couple couple) {
    final langCode = Localizations.localeOf(context).languageCode;
    final question = context.read<DailyQuestionProvider>().todayQuestion(
      langCode,
    );
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
                              color: AppColors.accentRose.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          IconsaxPlusLinear.camera,
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
                      fontSize: 12,
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
    return _gutter(
      MemoryCinemaCard(
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

  int _getNextMilestone(int totalDays) {
    const milestones = [
      30,
      50,
      100,
      180,
      365,
      500,
      730,
      1000,
      1500,
      2000,
      3000,
    ];
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
      return count == 1
          ? l10n.milestoneYearsOne(count)
          : l10n.milestoneYearsMany(count);
    }
    if (days < 365 && days % 30 == 0) {
      final count = days ~/ 30;
      return count == 1
          ? l10n.milestoneMonthsOne(count)
          : l10n.milestoneMonthsMany(count);
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
