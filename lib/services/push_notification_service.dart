import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';
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

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const String _deviceIdStorageKey = 'push_notification_installation_id';
  static const String _photoChannelId = 'partner_photo_updates';
  static const AndroidNotificationChannel _photoChannel = AndroidNotificationChannel(
    _photoChannelId,
    'Partner photo updates',
    description: 'Thông báo khi người ấy đăng ảnh mới.',
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
      FirebaseMessaging.onMessageOpenedApp.listen((_) {});

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

    await _localNotifications.show(
      message.messageId.hashCode ^ DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _photoChannelId,
          'Partner photo updates',
          channelDescription: 'Thông báo khi người ấy đăng ảnh mới.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

