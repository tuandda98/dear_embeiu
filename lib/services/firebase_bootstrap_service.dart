import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../l10n/app_l10n.dart';

class FirebaseBootstrapService {
  static bool _isInitialized = false;
  static bool _isFirebaseReady = false;

  static bool get isFirebaseReady => _isFirebaseReady;

  // Built lazily so it resolves against the locale that's active when the
  // message is actually shown (login/register screens), not the default locale
  // present during early startup when initialize() runs.
  static String? get bootstrapMessage =>
      _isFirebaseReady ? null : _buildBootstrapMessage();

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;

    try {
      await Firebase.initializeApp();
      _isFirebaseReady = true;

      await _activateAppCheck();

      if (!kIsWeb) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
      }
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint('Firebase init skipped: $e');
    }
  }

  /// App Check (chống lạm dụng) — gắn token chứng thực thiết bị vào mọi request
  /// Firestore/Storage/Functions để backend biết request đến từ app thật, không
  /// phải script/app bị mod. Debug + profile chạy trên project DEV nên dùng
  /// debug provider; chỉ bản `--release` (PROD) mới dùng chứng thực thật của
  /// nền tảng.
  ///
  /// FAIL-OPEN tuyệt đối: lỗi ở đây KHÔNG được làm Firebase "chưa sẵn sàng" —
  /// mọi API đang Unenforced nên thiếu token cũng không ai bị chặn.
  static Future<void> _activateAppCheck() async {
    if (kIsWeb) {
      return;
    }

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kReleaseMode
            ? const AndroidPlayIntegrityProvider()
            : const AndroidDebugProvider(),
        // iOS tối thiểu 15.0 nên App Attest luôn có, khỏi cần fallback
        // DeviceCheck.
        providerApple: kReleaseMode
            ? const AppleAppAttestProvider()
            : const AppleDebugProvider(),
      );
    } catch (e) {
      debugPrint('App Check activate skipped: $e');
    }
  }

  static String _buildBootstrapMessage() {
    final l10n = AppL10n.strings;
    if (kIsWeb) {
      return l10n.bootstrapWebNotConfigured;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return l10n.bootstrapAndroidNotReady;
      case TargetPlatform.iOS:
        return l10n.bootstrapIosNotConfigured;
      case TargetPlatform.macOS:
        return l10n.bootstrapMacosNotConfigured;
      case TargetPlatform.windows:
        return l10n.bootstrapWindowsNotConfigured;
      case TargetPlatform.linux:
        return l10n.bootstrapLinuxNotConfigured;
      case TargetPlatform.fuchsia:
        return l10n.bootstrapPlatformNotConfigured;
    }
  }
}

