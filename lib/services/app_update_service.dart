import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient, Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app/app_urls.dart';
import 'firebase_bootstrap_service.dart';

/// Force-update gate (feature force-update + auto-store-update). Decides whether
/// THIS build is too old to run, using a HYBRID of:
///   1. **Manual floor** — `config/app.minBuildNumber`: builds with a smaller
///      GLOBAL build number are blocked. You set it by hand when you want to
///      force a SPECIFIC minimum (works on both platforms).
///   2. **Auto store check** — `config/app.autoStoreForce == true` flips on an
///      automatic "is there a newer build on the store?" check, per platform:
///        • Android → Google Play **In-App Updates** (`in_app_update`): native
///          immediate (forced) update UI, downloads & installs in-app.
///        • iOS → **iTunes Lookup API**: compares the live App Store version to
///          this build; if newer, routes to the custom force screen (Apple has
///          no native in-app force-install API).
///
/// Config doc (`config/app`, public-read — written only from the Firebase
/// Console / admin):
/// ```
/// {
///   "minBuildNumber": 12,                  // builds < this are blocked (manual)
///   "autoStoreForce": true,                // auto-force when store has a newer build
///   "iosStoreUrl":    "https://apps.apple.com/app/id6775165592",
///   "androidStoreUrl":"https://play.google.com/store/apps/details?id=com.tony.dearembeiu"
/// }
/// ```
///
/// **Fail-open by design:** any error, offline, missing doc/field, a sideloaded
/// (non-Play) Android build, or a failed store lookup returns "don't block". A
/// config glitch must never lock the whole user base out of the app.
class AppUpdateService {
  AppUpdateService._();

  /// Shared instance — the gate runs once per cold start, and the resolved
  /// [storeUrl] is read back by the force-update screen.
  static final AppUpdateService instance = AppUpdateService._();

  /// Short ceiling on each network step so a slow link can't stall the splash;
  /// `SessionResolver` also wraps the whole resolve in its own 8s backstop.
  static const Duration _timeout = Duration(seconds: 4);

  /// Store URL for the current platform, resolved during the last check. The
  /// force-update screen launches this; null/empty falls back to [AppUrls].
  String? _storeUrl;
  String? get storeUrl => _storeUrl;

  bool get _isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  /// iOS gate (route-based): true when this build must be blocked behind the
  /// force screen. Android uses [maybeRunAndroidUpdate] instead (native flow).
  ///
  /// Forced when EITHER the manual floor trips (`build < minBuildNumber`) OR
  /// auto-store is on and the App Store has a newer version. Fail-open on
  /// everything else.
  Future<bool> isForceUpdateRequired() async {
    if (!_isUsingFirebase || Platform.isAndroid) {
      return false;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber.trim()) ?? 0;

      final config = await _readConfig();
      if (config == null) {
        return false;
      }
      // Cache the store URL even when no update is forced — harmless, and keeps
      // a single source of truth if the screen is reached another way.
      _storeUrl = _resolveStoreUrl(config);

      // 1) Manual floor (exact integer compare on the global build number).
      final minBuild = (config['minBuildNumber'] as num?)?.toInt();
      if (minBuild != null && currentBuild < minBuild) {
        return true;
      }

      // 2) Auto store check (iOS): ask the App Store for the live version.
      if (config['autoStoreForce'] == true) {
        return await _iosStoreHasNewerVersion(
          info.version,
          info.packageName,
        );
      }
      return false;
    } catch (_) {
      // Offline / permission / timeout / malformed doc → never block.
      return false;
    }
  }

  /// Android gate (imperative): when forcing is wanted, drive Google Play's
  /// native In-App Update flow — `performImmediateUpdate()` shows Play's own
  /// full-screen, unskippable update UI and installs in-app.
  ///
  /// Returns `true` only when the caller should fall back to the route-based
  /// [ForceUpdateScreen] instead — i.e. the manual floor demands a block but
  /// Play couldn't run the native flow (sideloaded build, no Play update yet, or
  /// the user backed out of the immediate update). Returns `false` (don't block)
  /// in every other case, including the happy path where the native UI took over.
  Future<bool> maybeRunAndroidUpdate() async {
    if (!Platform.isAndroid || !_isUsingFirebase) {
      return false;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber.trim()) ?? 0;

      final config = await _readConfig();
      if (config == null) {
        return false;
      }
      _storeUrl = _resolveStoreUrl(config);

      final minBuild = (config['minBuildNumber'] as num?)?.toInt();
      final manualForce = minBuild != null && currentBuild < minBuild;
      final autoForce = config['autoStoreForce'] == true;
      if (!manualForce && !autoForce) {
        return false;
      }

      // Ask Google Play whether an update is available. Throws on a non-Play
      // (sideloaded/emulator) install → caught below, falls back to the floor.
      final result = await InAppUpdate.checkForUpdate().timeout(_timeout);
      if (result.updateAvailability == UpdateAvailability.updateAvailable &&
          result.immediateUpdateAllowed) {
        // Native immediate update. If it succeeds the process restarts and code
        // below never runs; if the user backs out it returns here → hard-block.
        await InAppUpdate.performImmediateUpdate();
        return true;
      }
      // No Play update available (already latest, or sideloaded): only block
      // when the manual floor explicitly demands it.
      return manualForce;
    } catch (_) {
      // in_app_update unavailable / not from Play / network error: re-read just
      // the floor so a manual block still works without the native flow.
      return await _manualFloorOnly();
    }
  }

  /// Cheap re-check of ONLY the manual floor — used as the Android fallback when
  /// the native in-app-update path is unavailable.
  Future<bool> _manualFloorOnly() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber.trim()) ?? 0;
      final config = await _readConfig();
      if (config == null) {
        return false;
      }
      _storeUrl = _resolveStoreUrl(config);
      final minBuild = (config['minBuildNumber'] as num?)?.toInt();
      return minBuild != null && currentBuild < minBuild;
    } catch (_) {
      return false;
    }
  }

  /// Read `config/app` once (with the short timeout). Null on missing/!exists.
  Future<Map<String, dynamic>?> _readConfig() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('config')
        .doc('app')
        .get()
        .timeout(_timeout);
    if (!snapshot.exists) {
      return null;
    }
    return snapshot.data();
  }

  /// iTunes Lookup: fetch the live App Store version for [bundleId] and return
  /// whether it is strictly newer than [currentVersion]. Fail-closed (false) on
  /// any network/parse error so a flaky lookup never blocks the user.
  Future<bool> _iosStoreHasNewerVersion(
    String currentVersion,
    String bundleId,
  ) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$bundleId',
      );
      final request = await client.getUrl(uri).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) {
        return false;
      }
      final body =
          await response.transform(utf8.decoder).join().timeout(_timeout);
      final data = jsonDecode(body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) {
        return false;
      }
      final storeVersion = (results.first as Map)['version'] as String?;
      if (storeVersion == null || storeVersion.trim().isEmpty) {
        return false;
      }
      return _isNewerVersion(storeVersion, currentVersion);
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Dotted-version compare: true when [store] > [current] (e.g. 1.3.2 > 1.3.1).
  /// Non-numeric segments are treated as 0 so a malformed version can't force.
  bool _isNewerVersion(String store, String current) {
    final s = store.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final c =
        current.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final n = s.length > c.length ? s.length : c.length;
    for (var i = 0; i < n; i++) {
      final sv = i < s.length ? s[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (sv != cv) {
        return sv > cv;
      }
    }
    return false;
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
