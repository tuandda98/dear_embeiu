import 'dart:async';
import 'dart:io';
import 'dart:math';

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
import 'user_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Ignore bootstrap errors in background isolate.
    }
  }
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

  /// Marks the current request as handled so it won't be reapplied later.
  static void consumeHomeTabRequest() {
    if (pendingHomeTab.value != -1) {
      pendingHomeTab.value = -1;
    }
  }
}

/// Home tab indices a deep-link can target (mirror HomeScreen's IndexedStack).
const int _homeTabIndex = 0;
const int _galleryTabIndex = 1;

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
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_photoChannel);

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
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
    final type = message.data['type'];
    switch (type) {
      case 'photo_posted':
        NotificationTapRouter.pendingHomeTab.value = _galleryTabIndex;
        break;
      case 'photo_reaction':
        NotificationTapRouter.pendingHomeTab.value = _galleryTabIndex;
        break;
      case 'partner_joined':
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        break;
      case 'partner_left':
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        break;
      case 'love_note':
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        break;
      case 'daily_question':
        NotificationTapRouter.pendingHomeTab.value = _homeTabIndex;
        break;
      default:
        // Unknown or absent type — leave the current tab untouched and don't
        // log a malformed `notification_opened`.
        return;
    }
    // Analytics — log only the known, normalised push type (an enum string,
    // never any notification content).
    AnalyticsService.instance.logNotificationOpened(type as String);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!Platform.isAndroid) {
      return;
    }

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
      ),
    );
  }
}

