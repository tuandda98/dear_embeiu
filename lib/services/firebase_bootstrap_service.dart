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

      if (!kIsWeb) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
      }
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint('Firebase init skipped: $e');
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

