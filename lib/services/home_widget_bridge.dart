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
import 'home_widget_status.dart';
import 'push_notification_service.dart' show NotificationTapRouter;

/// Keeps the native home-screen widget in sync (feature home-widget, D3/D8).
///
/// Channel `dear_embeiu/widget` — iOS `HomeWidgetChannel` (AppDelegate.swift),
/// Android plugin `packages/dear_embeiu_widget_channel` (widget-today D13):
///  * `update(Map<String,String>)` — native stores the snapshot in the shared
///    store and redraws every widget. `state=empty` also drops the status.
///  * `updateStatus(Map<String,String>)` — the "hôm nay" line
///    ([HomeWidgetStatus], widget-today D6), stored apart from the snapshot so
///    `update` never wipes it. With `onlyIfNewer=1` (background push) native
///    keeps a newer line of the same day.
///  * `setPhoto(Uint8List? png)` — the CounterCard background photo, already
///    downscaled; native writes it next to the snapshot (null = remove, the
///    widget falls back to the brand gradient) and redraws.
///  * `consumeLaunch()` → `{family, target, focus, kind}` | null — which widget
///    opened the app since the last call and where its line pointed (D7);
///    native clears the flag. (1.9.x native returned the family string.)
abstract final class HomeWidgetBridge {
  static const MethodChannel _channel = MethodChannel('dear_embeiu/widget');
  static Map<String, String>? _lastSent;
  static bool _bound = false;
  static String? _photoKey;
  static Map<String, String>? _lastStatus;
  static Map<String, String>? _pendingStatus;
  static Timer? _statusTimer;

  /// Providers fire in bursts (a snapshot lands on three streams at once);
  /// only the last state of a burst is sent.
  static const Duration statusDebounce = Duration(milliseconds: 400);

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
    _lastStatus = null;
    _pendingStatus = null;
    _statusTimer?.cancel();
    _statusTimer = null;
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
      // Native dropped the status with `empty` too, so the next one is new.
      if (couple == null) {
        _lastStatus = null;
        unawaited(pushPhoto(key: null));
      }
    } on MissingPluginException {
      _lastSent = snapshot; // no native side (web, tests): nothing to retry
    } catch (e) {
      // Left unsent on purpose: the next change retries the same snapshot.
      debugPrint('HomeWidgetBridge.update failed: $e');
    }
  }

  /// The app's own view of today (from HomeScreen's providers, D5a).
  /// Debounced, and an unchanged line is not re-sent.
  static void pushStatus(Map<String, String> status) {
    if (kIsWeb) return;
    _pendingStatus = status;
    _statusTimer?.cancel();
    _statusTimer = Timer(statusDebounce, () async {
      final next = _pendingStatus;
      _pendingStatus = null;
      if (next == null || mapEquals(next, _lastStatus)) return;
      if (await sendStatus(next)) _lastStatus = next;
    });
  }

  /// Raw `updateStatus`, also used by the background push handler (its own
  /// isolate has none of the state above). False = not delivered, retry later.
  static Future<bool> sendStatus(Map<String, String> status) async {
    try {
      await _channel.invokeMethod<void>('updateStatus', status);
      return true;
    } on MissingPluginException {
      return true; // no native side (web, tests): nothing to retry
    } catch (e) {
      debugPrint('HomeWidgetBridge.updateStatus failed: $e');
      return false;
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
    debugPrint('HomeWidgetBridge: photo → ${key ?? 'none'}');
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

  /// When the app was opened from the widget: logs `widget_tap` and sends the
  /// user where the line on screen pointed (D7) through the same router a
  /// push tap uses.
  static Future<void> consumeLaunch() async {
    if (kIsWeb) return;
    try {
      final raw = await _channel.invokeMethod<Object>('consumeLaunch');
      final launch = parseLaunch(raw);
      if (launch == null) return;
      debugPrint('HomeWidgetBridge: opened from the widget $launch');
      AnalyticsService.instance.logWidgetTap(
        launch.family,
        target: launch.target,
        statusKind: launch.kind,
      );
      final tab = HomeWidgetStatus.targetTabs[launch.target];
      if (tab != null) {
        NotificationTapRouter.pendingHomeTab.value = tab;
        if (launch.focus.isNotEmpty) {
          NotificationTapRouter.pendingHomeFocus.value = launch.focus;
        }
      }
    } on MissingPluginException {
      // No native side.
    } catch (e) {
      debugPrint('HomeWidgetBridge.consumeLaunch failed: $e');
    }
  }

  /// What native recorded for a widget tap. The URL / intent extra can come
  /// from another app, so only known values pass; anything else is dropped
  /// (an unknown family = no tap, an unknown target = Home as before).
  @visibleForTesting
  static WidgetLaunch? parseLaunch(Object? raw) {
    final map = raw is Map
        ? raw.map((k, v) => MapEntry('$k', '${v ?? ''}'))
        : {'family': '${raw ?? ''}'}; // 1.9.x native: just the family
    final family = map['family'] ?? '';
    if (family != 'small' && family != 'medium') return null;
    final target = map['target'] ?? '';
    if (!HomeWidgetStatus.targetTabs.containsKey(target)) {
      return WidgetLaunch(family: family);
    }
    final focus = map['focus'] ?? '';
    final kind = map['kind'] ?? '';
    return WidgetLaunch(
      family: family,
      target: target,
      focus: HomeWidgetStatus.focuses.contains(focus) ? focus : '',
      kind: HomeWidgetStatus.kinds.contains(kind) ? kind : '',
    );
  }
}

/// A widget tap, as [HomeWidgetBridge.parseLaunch] accepted it.
class WidgetLaunch {
  const WidgetLaunch({
    required this.family,
    this.target = '',
    this.focus = '',
    this.kind = '',
  });

  final String family;

  /// `home` · `chat` · `gallery`; empty = the widget showed no line.
  final String target;
  final String focus;
  final String kind;

  @override
  String toString() => '$family → ${target.isEmpty ? '-' : target}'
      '${focus.isEmpty ? '' : '/$focus'}';
}
