import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

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
  bool remoteAuto = true;

  @override
  Future<bool> readRemoteAutoEnabled() async => remoteAuto;

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

    test(
      'reports through the edge filter, battery clamped, at = OS time',
      () async {
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
      },
    );

    test(
      'no session / auto off / permission-denied → every region stops',
      () async {
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
        expect(await denied.loadWantsAuto('u'), isFalse);
      },
    );

    test(
      'doc gone (partner changed, D10) → stop + "Tự báo" forgotten',
      () async {
        final s = await ready();
        s.error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
        );
        final g = _Geofence();
        await handleArrivalGeofenceEvent(
          slots: ['home'],
          type: ArrivalEventType.enter,
          at: DateTime.now(),
          service: s,
          battery: _Battery(),
          geofence: g,
        );
        expect(s.events.single.source, ArrivalEventSource.auto); // tried once
        expect(g.stops, 1);
        expect(await s.loadWantsAuto('u'), isFalse);
        // A failed write leaves the in/out state alone (no "already inside").
        expect((await s.loadEdge('u', 'home')).inside, isNull);
      },
    );

    test('remote switch off (D13) → stop, nothing sent', () async {
      final s = await ready()
        ..remoteAuto = false;
      final g = _Geofence();
      await handleArrivalGeofenceEvent(
        slots: ['home'],
        type: ArrivalEventType.enter,
        at: DateTime.now(),
        service: s,
        battery: _Battery(),
        geofence: g,
      );
      expect(s.events, isEmpty);
      expect(g.stops, 1);
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

  group('background bridge', () {
    final handled = <String>[];
    setUp(() {
      handled.clear();
      ArrivalBackgroundBridge.resetForTest();
      IsolateNameServer.removePortNameMapping(ArrivalBackgroundBridge.portName);
      ArrivalBackgroundBridge.handle = (slots, type, at, g) async =>
          handled.add('${slots.join(',')} ${type.name}');
    });
    tearDown(ArrivalBackgroundBridge.resetForTest);

    test('no app isolate → the background isolate handles it', () async {
      expect(
        await ArrivalBackgroundBridge.forward(
          ['home'],
          ArrivalEventType.enter,
          DateTime.now(),
        ),
        isFalse,
      );
    });

    test('live app isolate takes it, exactly once', () async {
      ArrivalBackgroundBridge.listen(_Geofence());
      expect(
        await ArrivalBackgroundBridge.forward(
          ['home'],
          ArrivalEventType.enter,
          DateTime.now(),
        ),
        isTrue,
      );
      expect(handled, ['home enter']);
    });

    test('a late message is dropped by the app isolate', () async {
      ArrivalBackgroundBridge.listen(_Geofence());
      final reply = ReceivePort();
      final got = <Object?>[];
      reply.listen(got.add);
      IsolateNameServer.lookupPortByName(
        ArrivalBackgroundBridge.portName,
      )!.send([
        ['home'],
        'enter',
        DateTime.now().millisecondsSinceEpoch,
        reply.sendPort,
        DateTime.now().millisecondsSinceEpoch - 3000, // sender gave up
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(handled, isEmpty);
      expect(got, isEmpty);
      reply.close();
    });

    test(
      'stale name: falls back after 2 s, keeps the name; resume re-claims it',
      () async {
        final dead = ReceivePort()..close();
        IsolateNameServer.registerPortWithName(
          dead.sendPort,
          ArrivalBackgroundBridge.portName,
        );
        expect(
          await ArrivalBackgroundBridge.forward(
            ['home'],
            ArrivalEventType.exit,
            DateTime.now(),
          ),
          isFalse,
        );
        expect(
          IsolateNameServer.lookupPortByName(ArrivalBackgroundBridge.portName),
          dead.sendPort,
        );
        ArrivalBackgroundBridge.listen(_Geofence());
        expect(
          await ArrivalBackgroundBridge.forward(
            ['home'],
            ArrivalEventType.exit,
            DateTime.now(),
          ),
          isTrue,
        );
        expect(handled, ['home exit']);
      },
    );
  });

  test('Android backups skip the plugin\'s region cache (lat/lng, D2)', () {
    final backup = File(
      'android/app/src/main/res/xml/backup_rules.xml',
    ).readAsStringSync();
    final extraction = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    const rule =
        '<exclude domain="sharedpref" path="native_geofence_plugin_cache.xml" />';
    expect(RegExp(RegExp.escape(rule)).allMatches(backup), hasLength(1));
    for (final block in ['cloud-backup', 'device-transfer']) {
      final body = RegExp(
        '<$block>(.*?)</$block>',
        dotAll: true,
      ).firstMatch(extraction)![1]!;
      expect(body, contains(rule), reason: block);
      expect(body, contains('app_flutter/arrival_nobackup/'), reason: block);
    }
  });
}
