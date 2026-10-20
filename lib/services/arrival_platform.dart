import 'dart:io' show Platform;

import '../models/arrival.dart';

/// Kill switches for automatic arrivals (overview D13). Manual "Về nhà rồi"
/// always works.
/// - [kArrivalAutoEnabled] false: Apple rejected the auto mode → hide it on
///   both platforms (drop `NSLocationAlways…` from Info.plist too).
/// - [kArrivalAutoAndroid] false: plan B when Play rejects background
///   location (remove the permission from the manifest with
///   `tools:node="remove"`, check `aapt2 dump permissions`).
/// The remote switch `config/app.arrivalAutoEnabled` sits on top of both.
const bool kArrivalAutoEnabled = true;
const bool kArrivalAutoAndroid = true;

bool get arrivalAutoBuildAllowed =>
    kArrivalAutoEnabled && (!Platform.isAndroid || kArrivalAutoAndroid);

// Stage 2 plugs the OS pieces in behind these three. Stage 1 ships the no-op
// versions, so the auto mode simply never turns on yet.

/// OS geofencing (iOS `CLLocationManager` regions, Android `GeofencingClient`).
/// Events come back through `ArrivalService.reportEvent` (also from the
/// background callback).
abstract class ArrivalGeofence {
  /// "Luôn luôn" + precise granted — without it the auto mode can't run (D8).
  Future<bool> hasAlwaysPermission();

  /// Monitors exactly [places] (each has a location); everything else stops.
  Future<void> sync(List<ArrivalPlace> places);

  /// Stops every region (sharing off, signed out, permission lost, remote
  /// switch off, permission-denied on a background write).
  Future<void> stopAll();
}

class NoopArrivalGeofence implements ArrivalGeofence {
  const NoopArrivalGeofence();

  @override
  Future<bool> hasAlwaysPermission() async => false;

  @override
  Future<void> sync(List<ArrivalPlace> places) async {}

  @override
  Future<void> stopAll() async {}
}

/// One OS geocoder result (D20).
class PlaceSearchResult {
  const PlaceSearchResult({
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lng,
    this.hasHouseNumber = true,
  });

  /// Bold line: house number + street / place name.
  final String title;

  /// Faint line: ward, province.
  final String subtitle;
  final double lat;
  final double lng;

  /// False → the confirm screen warns "chưa có số nhà" (D21).
  final bool hasHouseNumber;

  String get address => subtitle.isEmpty ? title : '$title, $subtitle';
}

/// iOS `MKLocalSearchCompleter`/`MKLocalSearch`, Android `Geocoder` (D20).
/// Errors: throw [PlaceSearchOffline] / [PlaceSearchUnavailable]; anything
/// else is a generic failure.
abstract class PlaceSearch {
  /// iOS suggests while typing (debounce 300 ms); Android only on pause /
  /// Search (800 ms, ≤5 results).
  bool get suggestsWhileTyping;

  /// False on phones without a geocoder (no Google Play services): the UI
  /// offers "Dùng vị trí hiện tại" only.
  Future<bool> isAvailable();

  Future<List<PlaceSearchResult>> search(String query);
}

class PlaceSearchOffline implements Exception {
  const PlaceSearchOffline();
}

class PlaceSearchUnavailable implements Exception {
  const PlaceSearchUnavailable();
}

class NoopPlaceSearch implements PlaceSearch {
  const NoopPlaceSearch();

  @override
  bool get suggestsWhileTyping => false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<PlaceSearchResult>> search(String query) async => const [];
}

/// Battery % at the moment of an event (D5). Must also work in the geofence
/// background engine (stage 2 spike §6.4). Null when unreadable.
abstract class BatteryReader {
  Future<int?> level();
}

class NoopBatteryReader implements BatteryReader {
  const NoopBatteryReader();

  @override
  Future<int?> level() async => null;
}
