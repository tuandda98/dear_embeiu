import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrapService {
  static bool _isInitialized = false;
  static bool _isFirebaseReady = false;
  static String? _bootstrapMessage;

  static bool get isFirebaseReady => _isFirebaseReady;
  static String? get bootstrapMessage => _bootstrapMessage;

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;

    try {
      await Firebase.initializeApp();
      _isFirebaseReady = true;
      _bootstrapMessage = null;
    } catch (e) {
      _isFirebaseReady = false;
      _bootstrapMessage = _buildBootstrapMessage();
      debugPrint('Firebase init skipped: $e');
    }
  }

  static String _buildBootstrapMessage() {
    if (kIsWeb) {
      return 'Firebase chưa được cấu hình cho Web nên app đang chạy local fallback.';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Firebase Android chưa sẵn sàng. Kiểm tra lại `android/app/google-services.json` và package name của app.';
      case TargetPlatform.iOS:
        return 'Bạn đang chạy iOS nhưng project chưa có `GoogleService-Info.plist`, nên app đang rơi về local fallback.';
      case TargetPlatform.macOS:
        return 'Firebase cho macOS chưa được cấu hình nên app đang chạy local fallback.';
      case TargetPlatform.windows:
        return 'Firebase cho Windows chưa được cấu hình nên app đang chạy local fallback.';
      case TargetPlatform.linux:
        return 'Firebase cho Linux chưa được cấu hình nên app đang chạy local fallback.';
      case TargetPlatform.fuchsia:
        return 'Firebase chưa được cấu hình cho platform hiện tại nên app đang chạy local fallback.';
    }
  }
}

