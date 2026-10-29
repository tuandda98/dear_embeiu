import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui' show DartPluginRegistrant, IsolateNameServer;

import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:native_geofence/native_geofence.dart';

import '../models/arrival.dart';
import '../utils/arrival_place_query.dart';
import 'arrival_platform.dart';
import 'arrival_service.dart';
import 'firebase_bootstrap_service.dart';

// Feature arrival, stage 2: the OS pieces behind `arrival_platform.dart`.
//  • Geofences: plugin `native_geofence` (spike §6.1–6.6).
//  • Battery: plugin `battery_plus` (also registered in the geofence engine).
//  • Location permission, one fix, address search: the app channel
//    `dear_embeiu/arrival` (AppDelegate `ArrivalChannel` / Kotlin
//    `arrival/ArrivalChannel`). Main engine only — the background callback
//    never needs it.

const MethodChannel _channel = MethodChannel('dear_embeiu/arrival');

/// Android only: the system's own words for "Allow all the time"
/// (`getBackgroundPermissionOptionLabel`, API 30+) for the D12 screen 2 copy.
/// Null elsewhere / on failure — the UI then uses its own string.
Future<String?> arrivalBackgroundOptionLabel() async {
  if (!Platform.isAndroid) return null;
  try {
    final label = await _channel.invokeMethod<String>('backgroundLabel');
    return (label == null || label.trim().isEmpty) ? null : label;
  } catch (_) {
    return null;
  }
}

ArrivalPermissionState _permissionFrom(Object? raw) {
  if (raw is! Map) {
    return const ArrivalPermissionState(ArrivalPermissionLevel.notDetermined);
  }
  final level = ArrivalPermissionLevel.values.firstWhere(
    (l) => l.name == raw['level'],
    orElse: () => ArrivalPermissionLevel.notDetermined,
  );
  return ArrivalPermissionState(level, precise: raw['precise'] != false);
}

class NativeArrivalPermissions implements ArrivalPermissions {
  const NativeArrivalPermissions();

  Future<ArrivalPermissionState> _call(String method) async {
    try {
      return _permissionFrom(await _channel.invokeMethod<Object?>(method));
    } catch (e) {
      debugPrint('arrival permission $method failed: $e');
      return const ArrivalPermissionState(ArrivalPermissionLevel.denied);
    }
  }

  @override
  Future<ArrivalPermissionState> status() => _call('permission');

  @override
  Future<ArrivalPermissionState> requestWhenInUse() =>
      _call('requestWhenInUse');

  @override
  Future<ArrivalPermissionState> requestAlways() => _call('requestAlways');

  @override
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } catch (_) {}
  }
}

class NativeCurrentLocationReader implements CurrentLocationReader {
  const NativeCurrentLocationReader();

  @override
  Future<CurrentFix?> current({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final raw = await _channel
          .invokeMethod<Object?>('currentFix', {
            'timeoutMs': timeout.inMilliseconds,
          })
          // Native stops at the same deadline; this only guards a lost reply.
          .timeout(timeout + const Duration(seconds: 2));
      if (raw is! Map) return null;
      final lat = raw['lat'];
      final lng = raw['lng'];
      final acc = raw['accuracy'];
      if (lat is! num || lng is! num) return null;
      return CurrentFix(
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        accuracyM: acc is num ? acc.toDouble() : 0,
      );
    } catch (e) {
      debugPrint('arrival current fix failed: $e');
      return null;
    }
  }
}

/// iOS: ONE `MKLocalSearch` per query (native waits 500 ms, cancels the
/// previous one, caches per text; Apple throttling → [PlaceSearchUnavailable]).
/// Android: `Geocoder.getFromLocationName` (≤5, Vietnam box). Both get the
/// shortened query and lose results in another province (D20 as re-decided
/// after the spike).
class NativePlaceSearch implements PlaceSearch {
  const NativePlaceSearch();

  /// iOS native waits 500 ms + its own 10 s; past this the UI falls back to
  /// "Dùng vị trí hiện tại".
  static const Duration searchTimeout = Duration(seconds: 12);

  @override
  bool get suggestsWhileTyping => Platform.isIOS;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('searchAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<PlaceSearchResult>> search(String query) async {
    final q = shortenArrivalPlaceQuery(query);
    if (q.text.isEmpty) return const [];
    final List<Object?> raw;
    try {
      raw =
          await _channel
              .invokeListMethod<Object?>('search', {'query': q.text})
              // Android 33+ GeocodeListener may never call back.
              .timeout(searchTimeout) ??
          const [];
    } on TimeoutException {
      throw const PlaceSearchUnavailable();
    } on PlatformException catch (e) {
      if (e.code == 'offline') throw const PlaceSearchOffline();
      if (e.code == 'unavailable') throw const PlaceSearchUnavailable();
      rethrow;
    }
    return arrivalSearchResults(raw, q);
  }
}

/// Android's address line repeats the street the title already has
/// ("45 Đường Lê Văn Sỹ" over "45 Đ. Lê Văn Sỹ, Phú Nhuận, Hồ Chí Minh"):
/// drop that first part when it is the same street (same house number, or
/// the same words once "Đường"/"Đ." is set aside). iOS subtitles never
/// start with the street, so they pass through.
@visibleForTesting
String arrivalDedupeSubtitle(String title, String subtitle) {
  final parts = subtitle.split(',');
  String norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'(^|\s)(đường|đ\.)\s*'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  String? number(String s) => RegExp(r'^\d[\w/]*').stringMatch(s.trim());
  final head = parts.first;
  final n = number(title);
  final same = norm(head) == norm(title) || (n != null && number(head) == n);
  if (!same) return subtitle;
  return parts.skip(1).join(',').trim();
}

/// Native maps → results, province filter, alley flag, ≤ 5.
@visibleForTesting
List<PlaceSearchResult> arrivalSearchResults(
  List<Object?> raw,
  ArrivalPlaceQuery q,
) {
  final out = <PlaceSearchResult>[];
  for (final r in raw) {
    if (r is! Map) continue;
    final lat = r['lat'];
    final lng = r['lng'];
    final title = '${r['title'] ?? ''}'.trim();
    if (lat is! num || lng is! num || title.isEmpty) continue;
    final subtitle = arrivalDedupeSubtitle(
      title,
      '${r['subtitle'] ?? ''}'.trim(),
    );
    final full = '$title, $subtitle, ${r['address'] ?? ''}';
    if (!arrivalResultInProvince(full, q.province)) continue;
    out.add(
      PlaceSearchResult(
        title: title,
        subtitle: subtitle,
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        hasHouseNumber: r['hasNumber'] == true,
        approximate: q.alley,
      ),
    );
    if (out.length == 5) break;
  }
  return out;
}

class PluginBatteryReader implements BatteryReader {
  const PluginBatteryReader();

  @override
  Future<int?> level() async {
    try {
      final v = await Battery().batteryLevel;
      return v < 0 || v > 100 ? null : v; // simulator: -1
    } catch (_) {
      return null;
    }
  }
}

/// Real geofences. Ids = slots; radius from the place (150/250 m, D1). No
/// "initial trigger" on either platform: registering while at Home must not
/// read as "đã về đến nhà" (D6). Android reports DWELL (2' inside, D6) as the
/// arrival; iOS has no dwell, so ENTER.
class NativeArrivalGeofence implements ArrivalGeofence {
  NativeArrivalGeofence({
    this.permissions = const NativeArrivalPermissions(),
    bool listenForBackground = true,
  }) {
    if (listenForBackground) ArrivalBackgroundBridge.listen(this);
  }

  final ArrivalPermissions permissions;
  Future<void>? _init;

  /// [sync] re-created the Android regions in this process already.
  static bool _reCreated = false;

  static const Duration androidDwell = Duration(minutes: 2);

  Future<void> _ready() => _init ??= NativeGeofenceManager.instance
      .initialize()
      .catchError((Object e) {
        _init = null;
        throw e;
      });

  /// Called on every resume (provider `onResume`): also re-claims the
  /// background bridge name if a background isolate left it pointing at
  /// nothing.
  @override
  Future<bool> hasAlwaysPermission() async {
    ArrivalBackgroundBridge.listen(this);
    return (await permissions.status()).canAuto;
  }

  @override
  Future<void> sync(List<ArrivalPlace> places) async {
    try {
      await _ready();
      final manager = NativeGeofenceManager.instance;
      final wanted = {
        for (final p in places)
          if (p.location != null) p.slot: p.location!,
      };
      final active = {
        for (final g in await manager.getRegisteredGeofences()) g.id: g,
      };
      for (final g in active.values) {
        final want = wanted[g.id];
        if (want == null || !_same(g, want)) {
          // Android may say "not found" for one already gone: carry on.
          await manager.removeGeofenceById(g.id).catchError((_) {});
        }
      }
      for (final e in wanted.entries) {
        final g = active[e.key];
        if (g != null && _same(g, e.value)) continue;
        await manager.createGeofence(
          arrivalFence(e.key, e.value, ios: Platform.isIOS),
          arrivalGeofenceTriggered,
        );
      }
      // Android answers `getRegisteredGeofences` from the plugin's prefs, not
      // from Play services: Force stop, clearing Play services data or
      // turning location off drops the regions while the prefs still list
      // them. Re-adding every region with the same id replaces it (no
      // duplicate) and, with no initial trigger, fires nothing. Once per
      // process (cold start): re-adding also restarts a pending 2' DWELL, so
      // doing it on every resume lost the "đã về" of someone who opened the
      // app right at the door (BUG-1).
      if (Platform.isAndroid && wanted.isNotEmpty && !_reCreated) {
        await manager.reCreateAfterReboot();
        _reCreated = true;
      }
    } catch (e) {
      // Permission lowered meanwhile, plugin error: the provider re-checks
      // on the next resume; the manual button still works.
      debugPrint('arrival geofence sync failed: $e');
    }
  }

  static bool _same(ActiveGeofence g, ArrivalLocation l) =>
      (g.location.latitude - l.lat).abs() < 1e-6 &&
      (g.location.longitude - l.lng).abs() < 1e-6 &&
      (g.radiusMeters - l.radius).abs() < 0.5;

  @override
  Future<void> stopAll() async {
    try {
      await NativeGeofenceManager.instance.removeAllGeofences();
    } catch (e) {
      debugPrint('arrival geofence stop failed: $e');
    }
  }
}

@visibleForTesting
Geofence arrivalFence(String slot, ArrivalLocation l, {required bool ios}) =>
    Geofence(
      id: slot,
      location: Location(latitude: l.lat, longitude: l.lng),
      radiusMeters: l.radius.toDouble(),
      triggers: ios
          ? const {GeofenceEvent.enter, GeofenceEvent.exit}
          : const {GeofenceEvent.dwell, GeofenceEvent.exit},
      iosSettings: const IosGeofenceSettings(initialTrigger: false),
      androidSettings: const AndroidGeofenceSettings(
        initialTriggers: {},
        loiteringDelay: NativeArrivalGeofence.androidDwell,
      ),
    );

/// The OS calls this in a fresh isolate (Android: the plugin's own engine;
/// iOS: a headless engine), also when the app was killed. The plugin gives no
/// event time, so "now" is the time the system woke us (spike §6.4).
@pragma('vm:entry-point')
Future<void> arrivalGeofenceTriggered(GeofenceCallbackParams params) async {
  final at = DateTime.now();
  final type = params.event == GeofenceEvent.exit
      ? ArrivalEventType.exit
      : ArrivalEventType.enter;
  final slots = {
    for (final g in params.geofences)
      if (kArrivalSlots.contains(g.id)) g.id,
  }.toList();
  if (slots.isEmpty) return;
  // App alive in this process → its isolate does the work, so only one
  // isolate ever writes the Hive box (Hive is not multi-isolate safe).
  if (await ArrivalBackgroundBridge.forward(slots, type, at)) return;
  try {
    DartPluginRegistrant.ensureInitialized();
    await Hive.initFlutter();
    // Same as the app: Firebase + App Check (once Firestore enforces App
    // Check, a write without a token would read as "left the couple").
    await FirebaseBootstrapService.initialize();
    if (Firebase.apps.isEmpty) return;
  } catch (e) {
    debugPrint('arrival background init failed: $e');
    return;
  }
  await handleArrivalGeofenceEvent(
    slots: slots,
    type: type,
    at: at,
    service: ArrivalService(),
    battery: const PluginBatteryReader(),
    geofence: NativeArrivalGeofence(listenForBackground: false),
  );
}

/// One geofence report → `ArrivalService.reportEvent` (edge filter D6 inside)
/// per slot. No session / auto switched off / remote switch
/// `config/app.arrivalAutoEnabled` false (D13) → regions shouldn't exist:
/// stop them. `permission-denied` or `not-found` (left the couple, signed
/// out, partner changed so the doc is gone — D10) → stop AND forget "Tự báo"
/// so a new partner never gets events without the user turning it on again.
Future<void> handleArrivalGeofenceEvent({
  required List<String> slots,
  required ArrivalEventType type,
  required DateTime at,
  required ArrivalService service,
  required BatteryReader battery,
  required ArrivalGeofence geofence,
}) async {
  try {
    final session = await service.loadSession();
    if (session == null ||
        !await service.loadWantsAuto(session.uid) ||
        !await service.readRemoteAutoEnabled()) {
      await geofence.stopAll();
      return;
    }
    int? level;
    try {
      level = (await battery.level())?.clamp(0, 100);
    } catch (_) {}
    for (final slot in slots) {
      final r = await service.reportEvent(
        uid: session.uid,
        coupleId: session.coupleId,
        slot: slot,
        type: type,
        source: ArrivalEventSource.auto,
        auto: true,
        at: at,
        battery: level,
      );
      if (r == ArrivalSendResult.denied) {
        await geofence.stopAll();
        await service.saveWantsAuto(session.uid, false);
        return;
      }
    }
  } catch (e) {
    debugPrint('arrival geofence event failed: $e');
  }
}

/// Hands a geofence event from the plugin's isolate to the app's main isolate
/// when the app is alive in the same process (IsolateNameServer is per
/// process), so only one isolate writes the Hive box. A main isolate that
/// died leaves a stale name: no "accepted" within [acceptWithin] → the
/// background isolate does it itself. The name is NOT removed then (a slow
/// but live main isolate keeps it); instead the main isolate drops any
/// message older than [lateAfter] — the sender has given up on it by then —
/// and re-claims the name on every resume.
class ArrivalBackgroundBridge {
  static const String portName = 'dear_embeiu.arrival.events';
  static const Duration acceptWithin = Duration(seconds: 2);
  static const Duration lateAfter = Duration(milliseconds: 1500);
  static ReceivePort? _port;

  /// Test hook: what the main isolate runs for one event.
  @visibleForTesting
  static Future<void> Function(
    List<String> slots,
    ArrivalEventType type,
    DateTime at,
    ArrivalGeofence geofence,
  )
  handle = _handle;

  static Future<void> _handle(
    List<String> slots,
    ArrivalEventType type,
    DateTime at,
    ArrivalGeofence geofence,
  ) => handleArrivalGeofenceEvent(
    slots: slots,
    type: type,
    at: at,
    service: ArrivalService(),
    battery: const PluginBatteryReader(),
    geofence: geofence,
  );

  static void listen(ArrivalGeofence geofence) {
    final existing = _port;
    if (existing != null) {
      if (IsolateNameServer.lookupPortByName(portName) != existing.sendPort) {
        IsolateNameServer.removePortNameMapping(portName);
        IsolateNameServer.registerPortWithName(existing.sendPort, portName);
      }
      return;
    }
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(portName);
    if (!IsolateNameServer.registerPortWithName(port.sendPort, portName)) {
      port.close();
      return;
    }
    _port = port;
    port.listen((msg) async {
      if (msg is! List || msg.length != 5 || msg[3] is! SendPort) return;
      final sentAt = msg[4];
      if (sentAt is! int ||
          DateTime.now().millisecondsSinceEpoch - sentAt >
              lateAfter.inMilliseconds) {
        return; // the background isolate handles it itself
      }
      final reply = msg[3] as SendPort;
      reply.send('accepted');
      try {
        await handle(
          [for (final s in msg[0] as List) '$s'],
          msg[1] == 'exit' ? ArrivalEventType.exit : ArrivalEventType.enter,
          DateTime.fromMillisecondsSinceEpoch(msg[2] as int),
          geofence,
        );
      } finally {
        reply.send('done');
      }
    });
  }

  /// Test hook: forget the listening port (as if the main isolate died).
  @visibleForTesting
  static void resetForTest() {
    _port?.close();
    _port = null;
  }

  static Future<bool> forward(
    List<String> slots,
    ArrivalEventType type,
    DateTime at,
  ) async {
    final target = IsolateNameServer.lookupPortByName(portName);
    if (target == null) return false;
    final reply = ReceivePort();
    final replies = reply.asBroadcastStream();
    try {
      target.send([
        slots,
        type.name,
        at.millisecondsSinceEpoch,
        reply.sendPort,
        DateTime.now().millisecondsSinceEpoch,
      ]);
      await replies.firstWhere((m) => m == 'accepted').timeout(acceptWithin);
    } catch (_) {
      reply.close();
      return false;
    }
    // Keep the plugin's callback (and so the OS wake) alive until it's sent.
    try {
      await replies
          .firstWhere((m) => m == 'done')
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // Slow write: it stays queued in Firestore.
    } finally {
      reply.close();
    }
    return true;
  }
}
