import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/sleep_calculator.dart';

/// Thin bridge to the native sleep sources (feature sleep). One channel, two
/// implementations — `MainActivity.kt` (Android UsageStats screen events, API
/// 28+) and `AppDelegate.swift` (iOS HealthKit `sleepAnalysis`, read only),
/// plus the motion fallback on both (`project/features/sleep/motion-contract.md`).
/// Every call is best-effort: a missing/failed channel reads as "unsupported"
/// or "no data", never an exception.
class SleepPlatform {
  const SleepPlatform._();

  static const MethodChannel _channel = MethodChannel('dear_embeiu/sleep');

  /// Tests only: pretend to run on Android (true) / iOS (false).
  @visibleForTesting
  static bool? debugAndroid;

  static bool get isAndroid => debugAndroid ?? (!kIsWeb && Platform.isAndroid);
  static bool get isIOS =>
      debugAndroid != null ? !debugAndroid! : (!kIsWeb && Platform.isIOS);

  /// Android 9+ (screen events exist) / iOS with Health available.
  static Future<bool> isSupported() => _bool('isSupported');

  /// Android: usage access granted. iOS always true — HealthKit never tells an
  /// app whether READ access was denied (a denial just looks like no data).
  static Future<bool> hasPermission() => _bool('hasPermission');

  /// Android: opens Settings → Usage access (result arrives on resume).
  /// iOS: shows the Health permission prompt; true once it was answered.
  static Future<bool> requestPermission() => _bool('requestPermission');

  /// Android: Usage access settings · iOS: the Health app.
  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } catch (_) {
      // Nothing to open — the UI keeps its hint text.
    }
  }

  /// iOS: keeps the folder at [path] (and everything in it) out of iCloud /
  /// computer backups — sleep data stays on this phone (audit D6). Android
  /// does the same with the backup rules in `res/xml`.
  static Future<void> excludeFromBackup(String path) async {
    if (!isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('excludeFromBackup', {'path': path});
    } catch (_) {
      // Best effort: the next launch sets it again.
    }
  }

  /// Android screen on/off transitions between [from] and [to].
  static Future<List<ScreenEvent>> screenEvents(
    DateTime from,
    DateTime to,
  ) async {
    final flat = await _longs('screenEvents', from, to);
    return [
      for (var i = 0; i + 1 < flat.length; i += 2)
        ScreenEvent(
          DateTime.fromMillisecondsSinceEpoch(flat[i]),
          on: flat[i + 1] == 1,
        ),
    ];
  }

  /// iOS Health sleep samples overlapping [from]..[to].
  static Future<List<HealthSleepSample>> healthSamples(
    DateTime from,
    DateTime to,
  ) async {
    final flat = await _longs('sleepSamples', from, to);
    return [
      for (var i = 0; i + 2 < flat.length; i += 3)
        HealthSleepSample(
          DateTime.fromMillisecondsSinceEpoch(flat[i]),
          DateTime.fromMillisecondsSinceEpoch(flat[i + 1]),
          flat[i + 2],
        ),
    ];
  }

  /// Fallback source (motion contract 2026-10-13): iOS Core Motion,
  /// Android Activity Recognition.
  static Future<bool> motionSupported() => _bool('motionSupported');

  /// 'granted' · 'denied' · 'notDetermined'.
  static Future<String> motionPermission() async {
    if (!isAndroid && !isIOS) {
      return 'denied';
    }
    try {
      return await _channel.invokeMethod<String>('motionPermission') ??
          'denied';
    } catch (_) {
      return 'denied';
    }
  }

  static Future<bool> requestMotionPermission() =>
      _bool('requestMotionPermission');

  /// Android: (re)registers the STILL transitions — idempotent, called on
  /// every refresh. iOS: no-op (Core Motion keeps 7 days by itself).
  static Future<bool> startMotionTracking() => _bool('startMotionTracking');

  /// Android: unregisters and wipes the recorded transitions. iOS: no-op.
  /// Called when sleep goes manual, on sign-out / account switch and on
  /// account deletion (vòng vá 1, F1).
  static Future<bool> stopMotionTracking() => _bool('stopMotionTracking');

  /// Oldest moment motion data covers (Android: first registration, iOS:
  /// now − 7 days); null = nothing recorded yet.
  static Future<DateTime?> motionCoverageStart() async {
    if (!isAndroid && !isIOS) {
      return null;
    }
    try {
      final ms = await _channel.invokeMethod<int>('motionCoverageStart') ?? 0;
      return ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    } catch (_) {
      return null;
    }
  }

  /// Spans the phone lay still within [from]..[to], oldest first.
  static Future<List<RestSpan>> motionStillSpans(
    DateTime from,
    DateTime to,
  ) async {
    final flat = await _longs('motionStillSpans', from, to);
    return [
      for (var i = 0; i + 1 < flat.length; i += 2)
        RestSpan(
          DateTime.fromMillisecondsSinceEpoch(flat[i]),
          DateTime.fromMillisecondsSinceEpoch(flat[i + 1]),
        ),
    ];
  }

  static Future<bool> _bool(String method) async {
    if (!isAndroid && !isIOS) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Native side answers with a flat Int64 array (cheap to marshal).
  static Future<List<int>> _longs(
    String method,
    DateTime from,
    DateTime to,
  ) async {
    if (!isAndroid && !isIOS) {
      return const <int>[];
    }
    try {
      final raw = await _channel.invokeMethod<Object?>(method, {
        'from': from.millisecondsSinceEpoch,
        'to': to.millisecondsSinceEpoch,
      });
      if (raw is List) {
        return [
          for (final v in raw)
            if (v is int) v,
        ];
      }
    } catch (_) {
      // fall through
    }
    return const <int>[];
  }
}
