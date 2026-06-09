import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sets the iOS app-icon badge to the live unread count (feature notifications,
/// D-notif-2) so it tracks the in-app bell instead of staying stuck at the last
/// push's value. iOS-only via a tiny MethodChannel (see `AppDelegate.swift`);
/// a no-op on every other platform. Best-effort — failures are swallowed.
class AppBadge {
  AppBadge._();

  static const MethodChannel _channel = MethodChannel('app/badge');

  /// Sets the app-icon badge to [count] (clamped to ≥ 0). Pass 0 to clear it.
  static Future<void> set(int count) async {
    if (kIsWeb || !Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setBadge', {
        'count': count < 0 ? 0 : count,
      });
    } catch (_) {
      // Never break the UI over a badge update.
    }
  }
}
