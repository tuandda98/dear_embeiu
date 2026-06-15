import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app/app_urls.dart';
import 'firebase_bootstrap_service.dart';

/// Force-update gate (feature force-update). Reads the public `config/app`
/// Firestore doc and decides whether THIS build is too old to run.
///
/// Config doc (`config/app`, public-read — written only from the Firebase
/// Console):
/// ```
/// {
///   "minBuildNumber": 12,                  // builds < this are blocked
///   "iosStoreUrl":    "https://apps.apple.com/app/idXXXXXXXXX",
///   "androidStoreUrl":"https://play.google.com/store/apps/details?id=com.tony.dearembeiu"
/// }
/// ```
///
/// Comparison is by the GLOBAL build number (`pubspec` `+N`), which the project
/// never resets — so a plain integer compare is exact and needs no SemVer parse.
///
/// **Fail-open by design:** any error, offline-with-no-cache, missing doc, or
/// missing/!int `minBuildNumber` returns `false` (don't block). A config glitch
/// must never lock the whole user base out of the app.
class AppUpdateService {
  AppUpdateService._();

  /// Shared instance — the gate runs once per cold start, and the resolved
  /// [storeUrl] is read back by the force-update screen.
  static final AppUpdateService instance = AppUpdateService._();

  /// Short ceiling on the config read so a slow network can't stall the splash;
  /// `SessionResolver` also wraps the whole resolve in its own 8s backstop.
  static const Duration _timeout = Duration(seconds: 4);

  /// Store URL for the current platform, resolved during the last check. The
  /// force-update screen launches this; null/empty falls back to [AppUrls].
  String? _storeUrl;
  String? get storeUrl => _storeUrl;

  bool get _isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  /// True only when the config doc loads AND this build is below its
  /// `minBuildNumber`. Fail-open on everything else (see class doc).
  Future<bool> isForceUpdateRequired() async {
    if (!_isUsingFirebase) {
      return false;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber.trim()) ?? 0;

      final snapshot = await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .get()
          .timeout(_timeout);

      if (!snapshot.exists) {
        return false;
      }
      final data = snapshot.data();
      // Cache the store URL even when no update is forced — harmless, and keeps
      // a single source of truth if the screen is reached another way.
      _storeUrl = _resolveStoreUrl(data);

      final minBuild = (data?['minBuildNumber'] as num?)?.toInt();
      if (minBuild == null) {
        return false;
      }
      return currentBuild < minBuild;
    } catch (_) {
      // Offline / permission / timeout / malformed doc → never block.
      return false;
    }
  }

  /// Picks the platform's store URL from the config doc, falling back to the
  /// compile-time [AppUrls] constants (empty string if neither is set).
  String _resolveStoreUrl(Map<String, dynamic>? data) {
    final key = Platform.isIOS ? 'iosStoreUrl' : 'androidStoreUrl';
    final fromConfig = (data?[key] as String?)?.trim();
    if (fromConfig != null && fromConfig.isNotEmpty) {
      return fromConfig;
    }
    return Platform.isIOS ? AppUrls.iosStore : AppUrls.androidStore;
  }
}
