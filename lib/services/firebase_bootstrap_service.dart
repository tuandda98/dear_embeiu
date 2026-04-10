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
      _bootstrapMessage =
          'Firebase chưa được cấu hình hoàn chỉnh nên app đang chạy local fallback. Sau khi thêm file cấu hình Android/iOS, auth sẽ dùng Firebase tự động.';
      debugPrint('Firebase init skipped: $e');
    }
  }
}

