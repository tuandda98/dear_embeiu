import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
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
///  * `setPhoto(Uint8List? png)` — the CounterCard background photo, already
///    downscaled; native writes it next to the snapshot (null = remove, the
///    widget falls back to the brand gradient) and redraws.
///  * `consumeLaunch()` → `'small' | 'medium' | null` — which widget opened the
///    app since the last call; native clears the flag.
abstract final class HomeWidgetBridge {
  static const MethodChannel _channel = MethodChannel('dear_embeiu/widget');
  static Map<String, String>? _lastSent;
  static bool _bound = false;
  static String? _photoKey;

  /// Longest edge of the photo sent to the widget. The medium widget is
  /// 338×158pt (≈1014px @3x); 720px keeps the PNG under ~1MB on the channel.
  static const int photoMaxEdge = 720;

  /// Wire once from the app root. Re-sends whenever the couple or the language
  /// changes. No push at bind time: `couple` is null until SessionResolver's
  /// loadCoupleForUser answers, and that first notification is what tells us
  /// whether this session really has no couple.
  static void bind(CoupleProvider couples, LocaleProvider locales) {
    if (_bound || kIsWeb) return;
    _bound = true;
    void onChange() {
      // Still fetching: the couple is unknown, not absent.
      if (couples.isLoading) return;
      // Fetch failed (offline, sync error): keep what the widget shows now.
      if (couples.couple == null && couples.errorMessage != null) return;
      _afterFrame(() => push(couples.couple));
    }
    couples.addListener(onChange);
    locales.addListener(onChange);
  }

  /// Tests only: lets a test bind its own fake providers.
  @visibleForTesting
  static void resetForTest() {
    _bound = false;
    _lastSent = null;
    _photoKey = null;
  }

  /// MaterialApp re-resolves the locale (AppL10n.setLocale) in the frame that
  /// follows a LocaleProvider change, so read the strings after that frame.
  /// scheduleFrame() guarantees a frame even when nothing else repaints.
  static void _afterFrame(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) => fn());
    SchedulerBinding.instance.scheduleFrame();
  }

  static Future<void> push(Couple? couple) async {
    Map<String, String>? snapshot;
    try {
      // build() formats dates with intl — main.dart ran initializeDateFormatting()
      // before runApp, and a widget refresh must never take the app down anyway.
      snapshot = HomeWidgetSnapshot.build(couple: couple, l10n: AppL10n.strings);
      if (mapEquals(snapshot, _lastSent)) return;
      await _channel.invokeMethod<void>('update', snapshot);
      _lastSent = snapshot; // only a delivered snapshot counts as sent
      // Signed out / left the couple: the photo must not outlive the couple.
      if (couple == null) unawaited(pushPhoto(key: null));
    } on MissingPluginException {
      _lastSent = snapshot; // no native side (web, tests): nothing to retry
    } catch (e) {
      // Left unsent on purpose: the next change retries the same snapshot.
      debugPrint('HomeWidgetBridge.update failed: $e');
    }
  }

  /// Mirrors the CounterCard background (the photo the couple swiped to) onto
  /// the widget. `key` is the candidate key from HomeScreen ('couple' or a
  /// photo id); null clears the photo. Deduped by key, so Home may call this
  /// on every build.
  static Future<void> pushPhoto({
    required String? key,
    String? local,
    String? remote,
  }) async {
    if (kIsWeb || key == _photoKey) return;
    _photoKey = key;
    try {
      Uint8List? png;
      if (key != null) {
        png = await _encodePhoto(local, remote);
        if (_photoKey != key) return; // a newer swipe superseded this one
      }
      await _channel.invokeMethod<void>('setPhoto', png);
    } on MissingPluginException {
      // No native side.
    } catch (e) {
      _photoKey = null; // retry on the next change
      debugPrint('HomeWidgetBridge.setPhoto failed: $e');
    }
  }

  /// Local file first (instant/offline), else the cached network image —
  /// the same order the CounterCard uses. Null when neither resolves.
  static Future<Uint8List?> _encodePhoto(String? local, String? remote) async {
    ImageProvider? base;
    final l = local?.trim();
    if (l != null && l.isNotEmpty && File(l).existsSync()) {
      base = FileImage(File(l));
    } else if (remote != null && remote.trim().isNotEmpty) {
      base = CachedNetworkImageProvider(remote.trim());
    }
    if (base == null) return null;
    final provider = ResizeImage(
      base,
      width: photoMaxEdge,
      height: photoMaxEdge,
      policy: ResizeImagePolicy.fit,
    );
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, _) {
        if (!completer.isCompleted) completer.completeError(error);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    try {
      final image = await completer.future;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('HomeWidgetBridge: photo decode failed: $e');
      return null;
    }
  }

  /// Logs `widget_tap` when the app was opened from the widget.
  static Future<void> consumeLaunch() async {
    if (kIsWeb) return;
    try {
      final family = await _channel.invokeMethod<String>('consumeLaunch');
      if (family == null || family.isEmpty) return;
      // URL/intent extra can come from another app — accept only the 2 real families.
      if (family != 'small' && family != 'medium') return;
      debugPrint('HomeWidgetBridge: opened from the $family widget');
      AnalyticsService.instance.logWidgetTap(family);
    } on MissingPluginException {
      // No native side.
    } catch (e) {
      debugPrint('HomeWidgetBridge.consumeLaunch failed: $e');
    }
  }
}
