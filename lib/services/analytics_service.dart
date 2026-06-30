import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app/app_routes.dart';
import 'firebase_bootstrap_service.dart';

/// Stable event names + parameter keys (snake_case) — the analytics CONTRACT.
///
/// Kept as constants so call sites can't typo an event name or param key (a
/// typo would silently split a funnel in GA4). Mirrors
/// `project/features/analytics/overview.md` section 5; do not rename without
/// updating that contract + the GA4 dashboard.
///
/// 🔒 Privacy: param VALUES are only ever fixed enums, bools or counts/buckets.
/// Never free text — no email/name/note/answer/caption/invite code/photo URL.
class AnalyticsEvents {
  AnalyticsEvents._();

  // --- Activation funnel ---
  static const String signUp = 'sign_up';
  static const String login = 'login';
  static const String coupleCreated = 'couple_created';
  static const String inviteShared = 'invite_shared';
  static const String coupleJoinAttempt = 'couple_join_attempt';
  static const String coupleJoined = 'couple_joined';
  static const String photoPosted = 'photo_posted';
  static const String photoDeleted = 'photo_deleted';

  // --- Engagement loop ---
  static const String loveNoteSet = 'love_note_set';
  static const String reactionSet = 'reaction_set';
  static const String dailyQuestionAnswered = 'daily_question_answered';
  static const String dailyQuestionRevealed = 'daily_question_revealed';
  static const String reminderCreated = 'reminder_created';
  static const String partnerNudgeSent = 'partner_nudge_sent';
  static const String partnerReminderCreated = 'partner_reminder_created';
  static const String notificationOpened = 'notification_opened';
  static const String languageChanged = 'language_changed';
  static const String counterBgSwiped = 'counter_bg_swiped';
  static const String memoryCinemaOpened = 'memory_cinema_opened';
  static const String loveNoteEnvelopeOpened = 'love_note_envelope_opened';
  static const String accountDeleted = 'account_deleted';

  // --- Param keys ---
  static const String pMethod = 'method'; // sign_up/login/invite_shared
  static const String pResult = 'result'; // couple_join_attempt
  static const String pIsFirst = 'is_first'; // photo_posted
  static const String pAction = 'action'; // love_note_set / reaction_set
  static const String pRepeat = 'repeat'; // reminder_created / partner_reminder
  static const String pSource = 'source'; // partner_nudge_sent (chip/custom)
  static const String pType = 'type'; // notification_opened
  static const String pLocale = 'locale'; // language_changed

  // --- User property names ---
  static const String upCoupleStatus = 'couple_status';
  static const String upHasPostedPhoto = 'has_posted_photo';
  static const String upAppLocale = 'app_locale';
  static const String upIsGuest = 'is_guest';
}

/// Stable values for `couple_join_attempt`'s `result` param.
class AnalyticsJoinResult {
  AnalyticsJoinResult._();

  static const String success = 'success';
  static const String invalidCode = 'invalid_code';
  static const String alreadyInCouple = 'already_in_couple';
  static const String error = 'error';
}

/// No-context analytics facade (mirrors the [AppL10n]/[ReminderService]
/// singleton style so providers/services can log without a [BuildContext]).
///
/// Design:
/// - Wraps Firebase Analytics, but stays a safe NO-OP whenever Firebase isn't
///   ready (local fallback build) OR the user opted out — every log path is
///   guarded by `_analytics == null || !_enabled`.
/// - The opt-out toggle is persisted in the shared `app_settings` Hive box
///   (key `analytics_enabled`, default true) — the same box [LocaleProvider]
///   uses; we reuse the open instance via [Hive.box] and fall back to
///   [Hive.openBox] only if it isn't open yet.
/// - 🔒 No method here accepts free text (email / name / note / answer /
///   caption / invite code / URL). Only fixed enums, bools and counts.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const String _boxName = 'app_settings';
  static const String _enabledKey = 'analytics_enabled';

  FirebaseAnalytics? _analytics;
  bool _enabled = true;

  /// Whether usage analytics is currently being collected (reflects the
  /// opt-out toggle). Read by the Settings switch.
  bool get isEnabled => _enabled;

  /// Initialise after Firebase. Binds the SDK only when Firebase is ready, then
  /// applies the persisted opt-out preference. Never throws — analytics must
  /// not block launch.
  Future<void> init() async {
    try {
      _enabled = _readEnabled();

      if (FirebaseBootstrapService.isFirebaseReady) {
        final analytics = FirebaseAnalytics.instance;
        _analytics = analytics;
        await analytics.setAnalyticsCollectionEnabled(_enabled);
        // D1(b) — no ad personalization / Google signals. There is no
        // pure-Dart "default" setting beyond consent mode, so we explicitly
        // deny the ad-personalization signal here (the iOS Info.plist default
        // covers the cold-start window before this runs).
        await analytics.setConsent(
          adPersonalizationSignalsConsentGranted: false,
        );
      }
    } catch (e) {
      // A failure here must never crash the app — degrade to no-op.
      _analytics = null;
      debugPrint('AnalyticsService init skipped: $e');
    }
  }

  bool _readEnabled() {
    try {
      // The `app_settings` box is opened as `Box<String>` by main() /
      // LocaleProvider (it stores the locale code), so the opt-out flag is
      // persisted as a string ('true'/'false') to stay type-compatible.
      final box = _openSettingsBoxSync();
      final raw = box?.get(_enabledKey);
      if (raw != null) {
        return raw == 'true';
      }
    } catch (_) {
      // Fall through to the safe default.
    }
    return true; // Default ON (D1c).
  }

  Box<String>? _openSettingsBoxSync() {
    if (!Hive.isBoxOpen(_boxName)) {
      return null;
    }
    return Hive.box<String>(_boxName);
  }

  /// A [NavigatorObserver] that auto-logs `screen_view` with a human-readable
  /// [screenName] for route transitions (mapped via [_screenNameFor]), or null
  /// when analytics is unavailable. Wired into MaterialApp's
  /// `navigatorObservers`. Tab screens inside Home (Gallery/Profile) aren't
  /// routes, so they call [logScreenView] directly on tab change.
  NavigatorObserver? get observer => _analytics == null
      ? null
      : FirebaseAnalyticsObserver(
          analytics: _analytics!,
          nameExtractor: (settings) => _screenNameFor(settings.name),
        );

  /// Maps a route name to a friendly, GA4-standard screen label so DebugView /
  /// reports read clearly instead of raw paths like `/auth-gate`. Returns null
  /// to SKIP logging (the transient AuthGate resolver). Pushed screens that set
  /// their own `RouteSettings(name: 'Settings')` fall through and are used as-is.
  String? _screenNameFor(String? routeName) {
    switch (routeName) {
      case AppRoutes.splash:
        return 'Splash';
      case AppRoutes.guest:
        return 'GuestCounter';
      case AppRoutes.login:
        return 'Login';
      case AppRoutes.register:
        return 'Register';
      case AppRoutes.setup:
        return 'CoupleSetup';
      case AppRoutes.home:
        return 'Home';
      case AppRoutes.authGate:
        return null; // transient redirect — don't clutter the funnel
      default:
        return routeName; // pushed routes already carry a friendly name
    }
  }

  /// Logs a `screen_view` for screens that aren't separate routes (e.g. the
  /// Home bottom-nav tabs Home/Gallery/Profile). No-op when unavailable/opt-out.
  Future<void> logScreenView(String screenName) async {
    if (_analytics == null || !_enabled) {
      return;
    }
    try {
      await _analytics!.logScreenView(screenName: screenName);
    } catch (_) {
      // Fire-and-forget; never block UI on analytics.
    }
  }

  /// Persist + apply the opt-out toggle. When turned off, the SDK stops
  /// collecting immediately (`setAnalyticsCollectionEnabled(false)`) and every
  /// [logEvent] below short-circuits.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box<String>(_boxName)
          : await Hive.openBox<String>(_boxName);
      await box.put(_enabledKey, value ? 'true' : 'false');
    } catch (e) {
      debugPrint('AnalyticsService persist failed: $e');
    }
    try {
      await _analytics?.setAnalyticsCollectionEnabled(value);
    } catch (_) {
      // Ignore — the in-memory guard already enforces opt-out.
    }
  }

  // ---------------------------------------------------------------------------
  // Low-level logging — all helpers funnel through here.
  // ---------------------------------------------------------------------------

  /// Logs [name] with [params]. No-op when the SDK isn't bound or the user
  /// opted out. Strips null param values and (defensively) drops any value
  /// that isn't an allowed scalar type so a stray object can't leak through.
  void logEvent(String name, {Map<String, Object?>? params}) {
    final analytics = _analytics;
    if (analytics == null || !_enabled) {
      return;
    }
    Map<String, Object>? clean;
    if (params != null && params.isNotEmpty) {
      clean = <String, Object>{};
      params.forEach((key, value) {
        if (value == null) return;
        if (value is String || value is num || value is bool) {
          clean![key] = value;
        }
      });
      if (clean.isEmpty) {
        clean = null;
      }
    }
    // Fire-and-forget; analytics latency must never block the caller.
    analytics.logEvent(name: name, parameters: clean);
  }

  // ---------------------------------------------------------------------------
  // Typed event helpers (one per contract event). 🔒 None take free text.
  // ---------------------------------------------------------------------------

  void logSignUp({String method = 'email'}) =>
      logEvent(AnalyticsEvents.signUp, params: {AnalyticsEvents.pMethod: method});

  void logLogin({String method = 'email'}) =>
      logEvent(AnalyticsEvents.login, params: {AnalyticsEvents.pMethod: method});

  void logCoupleCreated() => logEvent(AnalyticsEvents.coupleCreated);

  void logInviteShared(String method) => logEvent(
        AnalyticsEvents.inviteShared,
        params: {AnalyticsEvents.pMethod: method},
      );

  /// [result] must be one of [AnalyticsJoinResult].
  void logCoupleJoinAttempt(String result) => logEvent(
        AnalyticsEvents.coupleJoinAttempt,
        params: {AnalyticsEvents.pResult: result},
      );

  void logCoupleJoined() => logEvent(AnalyticsEvents.coupleJoined);

  void logPhotoPosted({required bool isFirst}) => logEvent(
        AnalyticsEvents.photoPosted,
        params: {AnalyticsEvents.pIsFirst: isFirst},
      );

  void logPhotoDeleted() => logEvent(AnalyticsEvents.photoDeleted);

  /// [action] is `create` or `update` (NOT the note text).
  void logLoveNoteSet(String action) => logEvent(
        AnalyticsEvents.loveNoteSet,
        params: {AnalyticsEvents.pAction: action},
      );

  /// [action] is `add` / `change` / `remove` (NOT which emoji or whose photo).
  void logReactionSet(String action) => logEvent(
        AnalyticsEvents.reactionSet,
        params: {AnalyticsEvents.pAction: action},
      );

  void logDailyQuestionAnswered() =>
      logEvent(AnalyticsEvents.dailyQuestionAnswered);

  void logDailyQuestionRevealed() =>
      logEvent(AnalyticsEvents.dailyQuestionRevealed);

  /// [repeat] is the recurrence enum name (once/daily/weekly/monthly/yearly).
  void logReminderCreated(String repeat) => logEvent(
        AnalyticsEvents.reminderCreated,
        params: {AnalyticsEvents.pRepeat: repeat},
      );

  /// Sent a nudge to the partner (feature partner-nudge). [source] is `chip`
  /// or `custom` — never the nudge text itself.
  void logNudgeSent(String source) => logEvent(
        AnalyticsEvents.partnerNudgeSent,
        params: {AnalyticsEvents.pSource: source},
      );

  /// Scheduled a reminder for the partner (feature partner-nudge). [repeat] is
  /// the recurrence kind only.
  void logPartnerReminderCreated(String repeat) => logEvent(
        AnalyticsEvents.partnerReminderCreated,
        params: {AnalyticsEvents.pRepeat: repeat},
      );

  /// [type] is the normalised push type
  /// (photo_posted/partner_joined/love_note/daily_question).
  void logNotificationOpened(String type) => logEvent(
        AnalyticsEvents.notificationOpened,
        params: {AnalyticsEvents.pType: type},
      );

  /// [locale] is `en`, `vi` or `system`.
  /// Swiped the home counter-card background photo (feature home).
  void logCounterBgSwiped() => logEvent(AnalyticsEvents.counterBgSwiped);

  /// Opened the Memory Cinema viewer on Home (feature home).
  void logMemoryCinemaOpened() =>
      logEvent(AnalyticsEvents.memoryCinemaOpened);

  /// Opened (unsealed) an unread love-note envelope on Home (feature home).
  void logLoveNoteEnvelopeOpened() =>
      logEvent(AnalyticsEvents.loveNoteEnvelopeOpened);

  void logLanguageChanged(String locale) => logEvent(
        AnalyticsEvents.languageChanged,
        params: {AnalyticsEvents.pLocale: locale},
      );

  void logAccountDeleted() => logEvent(AnalyticsEvents.accountDeleted);

  // ---------------------------------------------------------------------------
  // User id + properties. D2 — user_id = Firebase uid while authed (an id, not
  // PII content); cleared on sign-out.
  // ---------------------------------------------------------------------------

  Future<void> setUserId(String? uid) async {
    if (_analytics == null || !_enabled) {
      return;
    }
    try {
      await _analytics!.setUserId(id: uid);
    } catch (_) {
      // Ignore.
    }
  }

  void setCoupleStatus(String status) =>
      _setUserProperty(AnalyticsEvents.upCoupleStatus, status);

  void setHasPostedPhoto(bool value) =>
      _setUserProperty(AnalyticsEvents.upHasPostedPhoto, value.toString());

  void setAppLocale(String locale) =>
      _setUserProperty(AnalyticsEvents.upAppLocale, locale);

  void setIsGuest(bool value) =>
      _setUserProperty(AnalyticsEvents.upIsGuest, value.toString());

  void _setUserProperty(String name, String value) {
    final analytics = _analytics;
    if (analytics == null || !_enabled) {
      return;
    }
    // Fire-and-forget.
    analytics.setUserProperty(name: name, value: value);
  }
}
