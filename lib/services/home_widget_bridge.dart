import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../l10n/app_l10n.dart';
import '../models/couple.dart';
import '../providers/couple_provider.dart';
import '../providers/locale_provider.dart';
import 'analytics_service.dart';
import 'home_widget_snapshot.dart';

/// Keeps the native home-screen widget in sync (feature home-widget, D3/D8).
///
/// Channel `dear_embeiu/widget` — iOS `HomeWidgetChannel` (AppDelegate.swift),
/// Android `MainActivity.kt`:
///  * `update(Map<String,String>)` — native stores the snapshot in the shared
///    store and redraws every widget.
///  * `consumeLaunch()` → `'small' | 'medium' | null` — which widget opened the
///    app since the last call; native clears the flag.
abstract final class HomeWidgetBridge {
  static const MethodChannel _channel = MethodChannel('dear_embeiu/widget');
  static Map<String, String>? _lastSent;
  static bool _bound = false;

  /// Wire once from the app root. Re-sends whenever the couple or the language
  /// changes; the first push runs after the first frame.
  static void bind(CoupleProvider couples, LocaleProvider locales) {
    if (_bound || kIsWeb) return;
    _bound = true;
    void onChange() => _afterFrame(() => push(couples.couple));
    couples.addListener(onChange);
    locales.addListener(onChange);
    onChange();
  }

  /// MaterialApp re-resolves the locale (AppL10n.setLocale) in the frame that
  /// follows a LocaleProvider change, so read the strings after that frame.
  /// scheduleFrame() guarantees a frame even when nothing else repaints.
  static void _afterFrame(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) => fn());
    SchedulerBinding.instance.scheduleFrame();
  }

  static Future<void> push(Couple? couple) async {
    try {
      // build() formats dates with intl — main.dart ran initializeDateFormatting()
      // before runApp, and a widget refresh must never take the app down anyway.
      final snapshot =
          HomeWidgetSnapshot.build(couple: couple, l10n: AppL10n.strings);
      if (mapEquals(snapshot, _lastSent)) return;
      _lastSent = snapshot;
      await _channel.invokeMethod<void>('update', snapshot);
    } on MissingPluginException {
      // No native side (tests) — nothing to update.
    } catch (e) {
      debugPrint('HomeWidgetBridge.update failed: $e');
    }
  }

  /// Logs `widget_tap` when the app was opened from the widget.
  static Future<void> consumeLaunch() async {
    if (kIsWeb) return;
    try {
      final family = await _channel.invokeMethod<String>('consumeLaunch');
      if (family == null || family.isEmpty) return;
      debugPrint('HomeWidgetBridge: opened from the $family widget');
      AnalyticsService.instance.logWidgetTap(family);
    } on MissingPluginException {
      // No native side.
    } catch (e) {
      debugPrint('HomeWidgetBridge.consumeLaunch failed: $e');
    }
  }
}
