import 'dart:io';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:native_geofence/native_geofence.dart';

import 'package:dear_embeiu/models/arrival.dart';
import 'package:dear_embeiu/services/arrival_platform.dart';
import 'package:dear_embeiu/services/arrival_platform_native.dart';
import 'package:dear_embeiu/services/arrival_service.dart';
import 'package:dear_embeiu/utils/arrival_place_query.dart';

/// Feature arrival stage 2: the pure parts around the OS plugins.
class _Service extends ArrivalService {
  _Service() : super(ackTimeout: const Duration(milliseconds: 20));
  final events = <ArrivalEvent>[];
  Object? error;

  @override
  Future<void> putEvent(
    String coupleId,
    String uid,
    ArrivalEvent event, {
    required bool auto,
  }) async {
    events.add(event);
    if (error != null) throw error!;
  }
}

class _Geofence implements ArrivalGeofence {
  int stops = 0;
  @override
  Future<bool> hasAlwaysPermission() async => true;
  @override
  Future<void> sync(List<ArrivalPlace> places) async {}
  @override
  Future<void> stopAll() async => stops++;
}

class _Battery implements BatteryReader {
  @override
  Future<int?> level() async => 130;
}

ArrivalLocation _loc(int radius) => ArrivalLocation(
  lat: 21.0,
  lng: 105.8,
  source: ArrivalLocationSource.address,
  savedAt: DateTime(2026, 10, 20),
  radius: radius,
);

void main() {
  late Directory home;
  setUp(() {
    home = Directory.systemTemp.createTempSync('arrival_native');
    Hive.init(home.path);
  });
  tearDown(() async {
    await Hive.close();
    home.deleteSync(recursive: true);
  });

  group('geofence background event', () {
    Future<_Service> ready({bool wantsAuto = true}) async {
      final s = _Service();
      await s.saveSession('u', 'c');
      await s.saveWantsAuto('u', wantsAuto);
      await s.savePlaces('u', [ArrivalPlace.home(location: _loc(250))]);
      return s;
    }

    test('reports through the edge filter, battery clamped, at = OS time', () async {
      final s = await ready();
      final g = _Geofence();
      final at = DateTime(2026, 10, 20, 22, 58);
      await handleArrivalGeofenceEvent(
        slots: ['home', 'p9'],
        type: ArrivalEventType.enter,
        at: at,
        service: s,
        battery: _Battery(),
        geofence: g,
      );
      expect(s.events.single.source, ArrivalEventSource.auto);
      expect(s.events.single.at, at);
      expect(s.events.single.battery, 100);
      // iOS fires the first event twice after a reboot: dropped (D6).
      await handleArrivalGeofenceEvent(
        slots: ['home'],
        type: ArrivalEventType.enter,
        at: at,
        service: s,
        battery: _Battery(),
        geofence: g,
      );
      expect(s.events, hasLength(1));
      expect(g.stops, 0);
    });

    test('no session / auto off / permission-denied → every region stops', () async {
      final g = _Geofence();
      Future<void> fire(ArrivalService s) => handleArrivalGeofenceEvent(
        slots: ['home'],
        type: ArrivalEventType.enter,
        at: DateTime.now(),
        service: s,
        battery: _Battery(),
        geofence: g,
      );
      await fire(_Service());
      expect(g.stops, 1);
      await fire(await ready(wantsAuto: false));
      expect(g.stops, 2);
      final denied = await ready();
      denied.error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await fire(denied);
      expect(g.stops, 3);
    });
  });

  test('fence: id = slot, radius from the place, no initial trigger', () {
    final ios = arrivalFence('home', _loc(250), ios: true);
    expect(ios.id, 'home');
    expect(ios.radiusMeters, 250);
    expect(ios.triggers, {GeofenceEvent.enter, GeofenceEvent.exit});
    expect(ios.iosSettings.initialTrigger, isFalse);
    final android = arrivalFence('p1', _loc(150), ios: false);
    expect(android.triggers, {GeofenceEvent.dwell, GeofenceEvent.exit});
    expect(android.androidSettings.initialTriggers, isEmpty);
    expect(android.androidSettings.loiteringDelay, const Duration(minutes: 2));
  });

  test('search results: other province dropped, alley flag, ≤ 5', () {
    final q = shortenArrivalPlaceQuery('45/12 Lê Văn Sỹ, Phường 13, TP.HCM');
    final out = arrivalSearchResults([
      {
        'title': '45 Lê Văn Sỹ',
        'subtitle': 'P. Nhiêu Lộc, Thành phố Hồ Chí Minh',
        'lat': 10.79,
        'lng': 106.68,
        'hasNumber': true,
      },
      {
        'title': '45 Lê Văn Sỹ',
        'subtitle': 'Đà Lạt, Lâm Đồng',
        'lat': 11.9,
        'lng': 108.4,
        'hasNumber': true,
      },
      {'title': 'Lê Văn Sỹ', 'subtitle': '', 'lat': 10.8, 'lng': 106.7},
      {'title': '', 'lat': 1, 'lng': 1},
      'junk',
      for (var i = 0; i < 6; i++)
        {'title': 'X$i', 'subtitle': 'TP.HCM', 'lat': 10.0, 'lng': 106.0},
    ], q);
    expect(out, hasLength(5));
    expect(out.first.subtitle, contains('Nhiêu Lộc'));
    expect(out.every((r) => r.approximate), isTrue);
    expect(out[1].title, 'Lê Văn Sỹ');
    expect(out[1].hasHouseNumber, isFalse);
  });
}
