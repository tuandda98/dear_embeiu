import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import 'analytics_service.dart';
import 'firebase_bootstrap_service.dart';
import 'notification_settings_service.dart';
import 'reminder_service.dart';
import 'user_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // A fresh background isolate starts with no plugin registrations, so the
  // local-notifications channel [_cancelStaleDailyQuestionNudges] needs would
  // throw MissingPluginException. Idempotent.
  DartPluginRegistrant.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Ignore bootstrap errors in background isolate.
    }
  }
  await _cancelStaleDailyQuestionNudges(message);
}

/// Drops today's local daily-question nudges when a push reports the pair is now
/// complete (`data.bothAnswered == 'true'`, set by the `notifyDailyAnswer` CF).
///
/// Why this can't live in the UI: the local schedule is re-evaluated only by
/// [HomeScreen] on provider updates, but the FIRST answerer normally leaves the
/// app right after answering. When their partner answers hours later nothing
/// re-evaluates anything, so the nudges armed back when only one had answered
/// still fire — saying "người ấy chưa trả lời câu hỏi hôm nay" and warning about
/// a streak that is already safe (up to 4 wrong notifications a day). Running at
/// the transport layer fixes it with no UI alive.
///
/// ⚠️ Not a total fix: an iOS app the user force-quit gets no background wake at
/// all. [ReminderProvider] therefore also keeps the end-of-day copy safe on its
/// own — it no longer arms the 22h/23h streak warnings once I've answered.
Future<void> _cancelStaleDailyQuestionNudges(RemoteMessage message) async {
  final data = message.data;
  if (data['type'] != 'daily_question' ||
      '${data['bothAnswered']}'.trim().toLowerCase() != 'true') {
    return;
  }
  await ReminderService.instance.cancelDailyQuestionBands();
}

/// Deep-link bridge for notification taps (no extra package, no navigatorKey).
///
/// [PushNotificationService] writes the home tab a tapped push should open into
/// [pendingHomeTab]; [HomeScreen] reads + listens to it. Default 0 (Home).
///
/// Cold start (terminated → tap): `getInitialMessage()` runs inside
/// [PushNotificationService.initialize] (called in main() before runApp), so it
/// sets the pending value BEFORE HomeScreen mounts — HomeScreen then consumes it
/// in initState. Warm taps (background/foreground) push a new value while
/// HomeScreen is mounted and listening.
///
/// HomeScreen calls [consumeHomeTabRequest] after applying the value so the same
/// tap isn't replayed on a later rebuild/remount.
class NotificationTapRouter {
  NotificationTapRouter._();

  /// Tab index a tapped notification wants HomeScreen to show. -1 means "no
  /// pending request"; HomeScreen ignores it and keeps its current tab.
  static final ValueNotifier<int> pendingHomeTab = ValueNotifier<int>(-1);

  /// Photo id a tapped photo/reaction notification wants the Gallery to open
  /// fullscreen (deep-link to the exact item, not just the tab). null = none.
  /// [GalleryScreen] consumes it when it builds and the photo is loaded; if the
  /// photo is gone (deleted) it's simply cleared and the user lands on the grid.
  static final ValueNotifier<String?> pendingPhotoId =
      ValueNotifier<String?>(null);

  /// Marks the current request as handled so it won't be reapplied later.
  static void consumeHomeTabRequest() {
    if (pendingHomeTab.value != -1) {
      pendingHomeTab.value = -1;
    }
  }

  /// Marks the pending photo deep-link as handled.
  static void consumePhotoRequest() {
    if (pendingPhotoId.value != null) {
      pendingPhotoId.value = null;
    }
  }

  /// A specific card on the Home tab a tapped notification wants brought into
  /// view (deep-link within Home). Carries the notification `type` string
  /// (e.g. 'daily_question'); [HomeScreen] scrolls that card into view. null =
  /// no focus request (just land on the tab).
  static final ValueNotifier<String?> pendingHomeFocus =
      ValueNotifier<String?>(null);

  /// Marks the pending Home-focus request as handled.
  static void consumeHomeFocusRequest() {
    if (pendingHomeFocus.value != null) {
      pendingHomeFocus.value = null;
    }
  }

  /// A request to open the Gallery's add-photo composer (the Love Tree
  /// "Thêm một kỷ niệm" shortcut, 2026-06-17). true = open the multi-image
  /// picker once the Gallery tab is shown; [GalleryScreen] consumes it. Only
  /// ever set while the app is running (the Love Tree is reachable in-app only).
  static final ValueNotifier<bool> pendingCompose = ValueNotifier<bool>(false);

  /// Marks the pending compose request as handled.
  static void consumeComposeRequest() {
    if (pendingCompose.value) {
      pendingCompose.value = false;
    }
  }
}

/// Home tab indices a deep-link can target (mirror HomeScreen's IndexedStack).
/// ⚠️ Feature chat (2026-06-11) inserted the chat tab at 1 — Gallery moved
/// 1→2, Profile 2→3. Keep in sync with HomeScreen._navigationItems AND
/// AppNotification.targetHomeTab (notification center taps).
const int _homeTabIndex = 0;
const int _chatTabIndex = 1;
const int _galleryTabIndex = 2;

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const String _deviceIdStorageKey = 'push_notification_installation_id';
  static const String _photoChannelId = 'partner_photo_updates';
  static AndroidNotificationChannel get _photoChannel =>
      AndroidNotificationChannel(
        _photoChannelId,
        AppL10n.strings.pushPhotoChannelName,
        description: AppL10n.strings.pushPhotoChannelDescription,
        importance: Importance.high,
      );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final UserService _userService = UserService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isInitialized = false;
  String? _activeUserId;
  String? _cachedInstallationId;

  bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get _canUseFirebaseMessaging =>
      _isSupportedPlatform &&
      FirebaseBootstrapService.isFirebaseReady &&
      Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (_isInitialized || !_canUseFirebaseMessaging) {
      return;
    }

    _isInitialized = true;

    try {
      // Open the per-type prefs box early so device registration writes the
      // user's real choices (not defaults) from the first sync (D-notif-4).
      await NotificationSettingsService.instance.ensureLoaded();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        // Tap on a banner we showed ourselves in the foreground → deep-link the
        // same way a real push tap does (reuses the type/photoId routing).
        onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_photoChannel);

      // We render the foreground banner OURSELVES via a local notification (see
      // _handleForegroundMessage) — on iOS the `flutter_local_notifications`
      // plugin owns the UNUserNotificationCenter delegate, which silently
      // disables FCM's own foreground auto-present, so relying on `alert: true`
      // here made iOS show NOTHING while the app was open. Turn alert/sound off
      // to defer entirely to our manual show (keeps a single banner on every
      // platform, no duplicates); badge stays on for the app-icon count.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Tap handling (deep-link). Warm path: app is running (foreground or
      // background) and the user taps the push.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Cold path: app was terminated and launched by tapping a push. Runs
      // before runApp, so the pending tab is set before HomeScreen mounts.
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) async {
          final userId = _activeUserId;
          if (userId == null || token.trim().isEmpty) {
            return;
          }

          await _saveDeviceToken(userId: userId, token: token.trim());
        },
      );
    } catch (e) {
      _isInitialized = false;
      debugPrint('Push notification bootstrap failed: $e');
    }
  }

  Future<void> syncForUser(AppUser? user) async {
    _activeUserId = user?.id;
    if (user == null || !_canUseFirebaseMessaging) {
      return;
    }

    try {
      await initialize();
      if (!_isInitialized) {
        return;
      }

      final permissionStatus = await _requestPermissionStatus();
      if (!_isPermissionAuthorized(permissionStatus)) {
        await _removeDeviceRegistration(user.id);
        return;
      }

      final token = await _readCurrentToken();
      if (token == null || token.isEmpty) {
        await _removeDeviceRegistration(user.id);
        return;
      }

      await _saveDeviceToken(userId: user.id, token: token);
    } catch (e) {
      debugPrint('Push notification user sync failed: $e');
    }
  }

  /// Re-writes the active user's device doc with the CURRENT per-type prefs
  /// (D-notif-4) — called right after the user toggles a notification type in
  /// Settings so the Cloud Functions fan-out sees the change. No-ops when there
  /// is no signed-in user / Firebase.
  Future<void> refreshDeviceRegistration() async {
    final userId = _activeUserId;
    if (userId == null || !_canUseFirebaseMessaging) {
      return;
    }
    try {
      final token = await _readCurrentToken();
      if (token == null || token.isEmpty) {
        return;
      }
      await _saveDeviceToken(userId: userId, token: token);
    } catch (e) {
      debugPrint('Push prefs refresh failed: $e');
    }
  }

  Future<void> unregisterForUser(AppUser? user) async {
    final userId = user?.id;
    if (userId == null || !_canUseFirebaseMessaging) {
      _activeUserId = null;
      return;
    }

    try {
      await _removeDeviceRegistration(userId);
    } catch (e) {
      debugPrint('Push notification unregister failed: $e');
    } finally {
      if (_activeUserId == userId) {
        _activeUserId = null;
      }
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _isInitialized = false;
    _activeUserId = null;
  }

  Future<NotificationSettings> _requestPermissionStatus() async {
    try {
      return await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {
      return await FirebaseMessaging.instance.getNotificationSettings();
    }
  }

  bool _isPermissionAuthorized(NotificationSettings settings) {
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> _readCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token?.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveDeviceToken({
    required String userId,
    required String token,
  }) async {
    try {
      final deviceId = await _getInstallationId();
      await _userService.saveDeviceRegistration(
        userId: userId,
        deviceId: deviceId,
        token: token,
        platform: _platformLabel,
        notificationsEnabled: true,
        languageCode: _currentLanguageCode,
        // Mirror the per-type mute prefs so the CF can honour them (D-notif-4).
        pushTypePrefs: NotificationSettingsService.instance.currentOrDefault(),
      );
      // Keep this user's device list from accumulating stale registrations.
      await _userService.pruneStaleDevices(userId: userId, keepDeviceId: deviceId);
    } catch (e) {
      debugPrint('Push token sync failed: $e');
    }
  }

  Future<void> _removeDeviceRegistration(String userId) async {
    try {
      await _userService.removeDeviceRegistration(
        userId: userId,
        deviceId: await _getInstallationId(),
      );
    } catch (e) {
      debugPrint('Push device removal failed: $e');
    }
  }

  Future<String> _getInstallationId() async {
    if (_cachedInstallationId != null && _cachedInstallationId!.isNotEmpty) {
      return _cachedInstallationId!;
    }

    try {
      final existing = await _secureStorage.read(key: _deviceIdStorageKey);
      if (existing != null && existing.trim().isNotEmpty) {
        _cachedInstallationId = existing.trim();
        return _cachedInstallationId!;
      }
    } catch (_) {
      // Fall through and regenerate the installation id.
    }

    final generated =
        'device_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    _cachedInstallationId = generated;

    try {
      await _secureStorage.write(key: _deviceIdStorageKey, value: generated);
    } catch (_) {
      // Ignore storage failures and keep the in-memory value for this session.
    }

    return generated;
  }

  String get _platformLabel {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    return 'unknown';
  }

  /// The language code currently in effect for this device (Gap B). Mirrors
  /// whatever locale MaterialApp resolved — set on `Intl.defaultLocale` by
  /// main.dart's localeResolutionCallback — so it honours both an explicit
  /// pick and "follow system". Falls back to the device locale, then 'vi'.
  String get _currentLanguageCode {
    final resolved = Intl.defaultLocale ?? Intl.getCurrentLocale();
    final code = resolved.split(RegExp('[_-]')).first.trim().toLowerCase();
    return code.isNotEmpty ? code : 'vi';
  }

  /// Maps a tapped push to the home tab it should open and publishes it via
  /// [NotificationTapRouter]. Covers all three tap states (foreground tap,
  /// background tap, cold-start) since each routes a [RemoteMessage] here.
  /// Unknown/missing types are ignored (no tab change, no error).
  void _handleNotificationTap(RemoteMessage message) {
    _applyRoute(
      message.data['type'] as String?,
      (message.data['photoId'] as String?)?.trim(),
    );
  }

  /// Tap handler for a banner WE showed in the foreground via
  /// [_localNotifications] (see [_handleForegroundMessage]). Its payload is the
  /// JSON-encoded FCM `data` map, so we route by the same type/photoId as a real
  /// push tap. Legacy/plain payloads (just the type string) are handled too.
  void _handleLocalNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _applyRoute(
        data['type'] as String?,
        (data['photoId'] as String?)?.toString().trim(),
      );
    } catch (_) {
      _applyRoute(payload, null);
    }
  }

  /// Routes a notification (push tap OR a foreground banner tap) to the home tab
  /// / deep-link target for its [type]. Unknown/absent types are ignored (no tab
  /// change, no malformed analytics event).
  void _applyRoute(String? type, String? photoId) {
    switch (type) {
      case 'photo_posted':
        NotificationTapRouter.pendingHomeTab.value = _galleryTabIndex;
        if (photoId != null && photoId.isNotEmpty) {
          NotificationTapRouter.pendingPhotoId.value = photoId;
        }
        break;
      case 'photo_reaction':
        NotificationTapRouter.pendingHomeTab.value = _galleryTabIndex;
        if (photoId != null && photoId.isNotEmpty) {
          NotificationTapRouter.pendingPhotoId.value = photoId;
        }
        break;
      case 'chat_message':
        NotificationTapRouter.pendingHomeTab.value = _chatTabIndex;
        break;
      case 'partner_joined':
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        break;
      case 'partner_left':
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        break;
      case 'love_note':
        // A not-yet-updated partner's love notes are now mirrored into chat
        // (auto-migration 2026-06-14), so route this push to the Chat tab
        // where the message actually lives.
        NotificationTapRouter.pendingHomeTab.value = _chatTabIndex;
        break;
      case 'daily_question':
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        // Deep-link within Home: scroll the daily-question card into view.
        NotificationTapRouter.pendingHomeFocus.value = 'daily_question';
        break;
      case 'partner_mood':
        // Mood card lives on Home (feature mood) — open there to see it.
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        break;
      case 'partner_reminder_set':
        // Scheduled-reminder confirmation (feature partner-nudge): A set a
        // shared reminder for B — just bring the app to Home.
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        break;
      default:
        // Unknown or absent type — leave the current tab untouched and don't
        // log a malformed `notification_opened`.
        return;
    }
    // Analytics — log only the known, normalised push type (an enum string,
    // never any notification content). `type` is non-null here (any null/unknown
    // value returned early via the default branch above).
    AnalyticsService.instance.logNotificationOpened(type!);
  }

  /// Renders an in-app banner for a push that arrives while the app is in the
  /// FOREGROUND — on BOTH Android and iOS.
  ///
  /// A foreground push is never auto-displayed by the OS: on Android the system
  /// tray only shows `notification` payloads while the app is backgrounded, and
  /// on iOS FCM's own `setForegroundNotificationPresentationOptions` is disabled
  /// the moment `flutter_local_notifications` claims the notification-center
  /// delegate (which it does in [initialize]). So for EVERY interaction type
  /// (reaction ❤️, daily-question answer, chat, mood, photo, partner reminder…)
  /// we must surface it ourselves here, or the partner sees nothing while their
  /// app is open. Covers all types uniformly because it runs at the transport
  /// layer (onMessage), not per notification kind.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!_isSupportedPlatform) {
      return;
    }

    // Same stale-nudge cleanup as the background isolate — a safety net for the
    // window where the app is foregrounded but HomeScreen isn't mounted yet
    // (it's the listener that would otherwise re-evaluate the schedule).
    await _cancelStaleDailyQuestionNudges(message);

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) {
      return;
    }

    // `flutter_local_notifications` requires the id to fit in a 32-bit int
    // (validateId). millisecondsSinceEpoch (~1.7e12) overflows that, so mask the
    // combined value down to a non-negative 31-bit int (0..2^31-1). Stays well
    // clear of the reminder id ranges (1001–1099 / 2000–2999).
    final notificationId =
        (message.messageId.hashCode ^ DateTime.now().millisecondsSinceEpoch) &
            0x7FFFFFFF;

    // Carry the full FCM data map so a tap on this foreground banner deep-links
    // exactly like a background push tap (routed in _handleLocalNotificationResponse).
    String? payload;
    try {
      payload = jsonEncode(message.data);
    } catch (_) {
      payload = message.data['type'] as String?;
    }

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _photoChannelId,
          AppL10n.strings.pushPhotoChannelName,
          channelDescription: AppL10n.strings.pushPhotoChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}

