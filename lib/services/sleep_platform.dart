import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/sleep_calculator.dart';

/// Thin bridge to the native sleep sources (feature sleep). One channel, two
/// implementations — `MainActivity.kt` (Android UsageStats screen events, API
/// 28+) and `AppDelegate.swift` (iOS HealthKit `sleepAnalysis`, read only).
/// Every call is best-effort: a missing/failed channel reads as "unsupported"
/// or "no data", never an exception.
class SleepPlatform {
  const SleepPlatform._();

  static const MethodChannel _channel = MethodChannel('dear_embeiu/sleep');

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;

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
