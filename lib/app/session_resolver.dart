import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/daily_question_provider.dart';
import '../providers/notification_inbox_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/reaction_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/streak_provider.dart';
import '../services/app_update_service.dart';
import '../services/storage_service.dart';
import 'app_routes.dart';

/// Decides where a just-launched (or just-authenticated) user should land:
/// initialises auth, loads couple + photo state, then returns the target route.
///
/// Pure async work — it never touches [Navigator] or `mounted`, so the caller
/// stays in control of navigation. Providers are read synchronously up front,
/// before the first `await`, so it is safe to call across async gaps.
class SessionResolver {
  const SessionResolver._();

  /// Hard ceiling on cold-start route resolution (app-robustness A6). The inner
  /// per-call timeouts (auth/couple = 5s each) normally settle well within this,
  /// but this is the global backstop: if anything in the chain stalls past it,
  /// we resolve to a safe route from on-disk cache instead of freezing on the
  /// splash. The in-flight resolution keeps running in the background and wires
  /// up the realtime watchers; the splash navigates only once, so there is no
  /// double-navigation.
  static const Duration _globalResolveTimeout = Duration(seconds: 8);

  static Future<String> resolveStartRoute(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final coupleProvider = context.read<CoupleProvider>();
    final photoProvider = context.read<PhotoProvider>();
    final chatProvider = context.read<ChatProvider>();
    final dailyQuestionProvider = context.read<DailyQuestionProvider>();
    final reactionProvider = context.read<ReactionProvider>();
    final streakProvider = context.read<StreakProvider>();
    final notificationInboxProvider = context.read<NotificationInboxProvider>();
    final reminderProvider = context.read<ReminderProvider>();

    try {
      return await _resolve(
        authProvider: authProvider,
        coupleProvider: coupleProvider,
        photoProvider: photoProvider,
        chatProvider: chatProvider,
        dailyQuestionProvider: dailyQuestionProvider,
        reactionProvider: reactionProvider,
        streakProvider: streakProvider,
        notificationInboxProvider: notificationInboxProvider,
        reminderProvider: reminderProvider,
      ).timeout(_globalResolveTimeout);
    } catch (_) {
      // Global backstop: never hang on the splash. Pick a safe route from
      // whatever state is already known (auth status if initialize finished,
      // otherwise the on-disk couple cache).
      return _safeFallbackRoute(authProvider);
    }
  }

  /// Resolves a sensible route without depending on any pending network work.
  /// Prefers the already-resolved auth status; otherwise infers from the cached
  /// couple on disk (a coupled session → home). Defaults to guest.
  static Future<String> _safeFallbackRoute(AuthProvider authProvider) async {
    if (authProvider.isInitialized && !authProvider.isAuthenticated) {
      return AppRoutes.guest;
    }

    try {
      final cachedCouple = await StorageService.loadCouple();
      if (cachedCouple != null && cachedCouple.memberIds.isNotEmpty) {
        return AppRoutes.home;
      }
    } catch (_) {
      // Ignore cache read failures and fall through.
    }

    // Authenticated (or unknown) but no usable couple cache: setup when we know
    // there's a session, guest otherwise.
    return authProvider.isAuthenticated ? AppRoutes.setup : AppRoutes.guest;
  }

  static Future<String> _resolve({
    required AuthProvider authProvider,
    required CoupleProvider coupleProvider,
    required PhotoProvider photoProvider,
    required ChatProvider chatProvider,
    required DailyQuestionProvider dailyQuestionProvider,
    required ReactionProvider reactionProvider,
    required StreakProvider streakProvider,
    required NotificationInboxProvider notificationInboxProvider,
    required ReminderProvider reminderProvider,
  }) async {
    // Force-update gate (feature force-update): a build older than the server's
    // minimum is sealed off behind the update screen BEFORE any auth/couple
    // work — so even a guest launch is blocked. Fail-open: the check returns
    // false on any error/offline/missing-config, so a config glitch can never
    // lock everyone out (it has its own short timeout, and the whole resolve is
    // wrapped in an 8s backstop above).
    if (await AppUpdateService.instance.isForceUpdateRequired()) {
      return AppRoutes.forceUpdate;
    }

    if (!authProvider.isInitialized) {
      await authProvider.initialize();
    }

    if (!authProvider.isAuthenticated) {
      await photoProvider.clearForSignOut();
      chatProvider.clear();
      dailyQuestionProvider.clear();
      reactionProvider.clear();
      streakProvider.clear();
      notificationInboxProvider.clear();
      // No active couple: drop the daily-question nudge (b2). The on/off
      // preference is kept so it re-arms on the next sync once a couple loads.
      await reminderProvider.cancelDailyQuestionSchedule();
      return AppRoutes.guest;
    }

    // Email-verification gate (feature auth, Đợt 1 — D-auth2). A post-cutoff,
    // unverified Firebase account must verify before it can reach setup/home.
    // We return early BEFORE loading the couple or wiring any realtime watcher
    // (a brand-new account has no couple yet anyway), so the user is sealed off
    // until verified. Grandfathered / Google / Apple users return false here.
    if (authProvider.requiresEmailVerification) {
      await photoProvider.clearForSignOut();
      chatProvider.clear();
      dailyQuestionProvider.clear();
      reactionProvider.clear();
      streakProvider.clear();
      notificationInboxProvider.clear();
      await reminderProvider.cancelDailyQuestionSchedule();
      return AppRoutes.verifyEmail;
    }

    final currentUser = authProvider.currentUser;
    await coupleProvider.loadCoupleForUser(currentUser);
    final hasCoupleData =
        currentUser?.hasCouple == true && coupleProvider.hasCoupleData;

    if (hasCoupleData) {
      await photoProvider.syncForUser(currentUser);
      // "On this day" memories (pagination D3): fetched via dedicated queries
      // so the Home cinema works even when the photo predates the realtime
      // window. Fire-and-forget — never blocks route resolution.
      final anniversary = coupleProvider.couple?.anniversaryDate;
      if (anniversary != null) {
        unawaited(photoProvider.refreshOnThisDay(anniversary: anniversary));
      }
      // Chat (feature chat): the realtime window runs for the whole session so
      // the bottom-nav unread dot stays live on every tab.
      chatProvider.watchForCouple(currentUser!.coupleId!, currentUser.id);
      dailyQuestionProvider.watchForCouple(
        currentUser.coupleId!,
        currentUser.id,
      );
      reactionProvider.watchForCouple(currentUser.coupleId!, currentUser.id);
      // Streak (feature streak) — only meaningful once the couple is active
      // (both members present); hidden while still waiting for a partner.
      streakProvider.watchForCouple(
        currentUser.coupleId!,
        coupleActive: !(coupleProvider.couple?.isWaitingForPartner ?? true),
      );
      // Notification center (feature notifications) — stream this couple's
      // inbox so the AppBar bell badge + center are live.
      notificationInboxProvider.watchForCouple(
        currentUser.coupleId!,
        currentUser.id,
      );
      // Daily-question reminder (couple-shared, 2026-06-14): follow the shared
      // enabled+times so a partner's edit reschedules this device's nudges. The
      // actual (re)schedule uses the l10n cached by HomeScreen's sync().
      reminderProvider.watchCoupleReminderPrefs(currentUser.coupleId!);
    } else {
      await photoProvider.clearForSignOut();
      chatProvider.clear();
      dailyQuestionProvider.clear();
      reactionProvider.clear();
      streakProvider.clear();
      notificationInboxProvider.clear();
      // Authenticated but no couple yet — cancel the daily-question nudge (b2)
      // until a partner joins; the preference persists for re-arming via sync.
      await reminderProvider.cancelDailyQuestionSchedule();
    }

    return hasCoupleData ? AppRoutes.home : AppRoutes.setup;
  }
}
