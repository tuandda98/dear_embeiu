import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dear_embeiu/models/arrival.dart';
import 'package:dear_embeiu/providers/arrival_provider.dart';
import 'package:dear_embeiu/services/arrival_platform.dart';
import 'package:dear_embeiu/services/arrival_service.dart';
import 'package:dear_embeiu/services/notification_settings_service.dart';
import 'package:dear_embeiu/utils/arrival_edge_filter.dart';

/// Feature arrival, stage 1 (data layer). Hive's home is a temp folder (no
/// path_provider in unit tests); Firestore is faked by overriding the remote
/// methods.
class FakeArrivalService extends ArrivalService {
  FakeArrivalService() : super(ackTimeout: const Duration(milliseconds: 20));

  final calls = <String>[];
  final events = <ArrivalEvent>[];
  final shares = <String, StreamController<ArrivalShare?>>{};
  Object? writeError;
  Completer<void>? holdWrite;
  bool remoteAuto = true;

  StreamController<ArrivalShare?> share(String uid) =>
      shares.putIfAbsent(uid, StreamController<ArrivalShare?>.broadcast);

  Future<void> _write(String what) async {
    calls.add(what);
    await holdWrite?.future;
    if (writeError != null) throw writeError!;
  }

  @override
  Stream<ArrivalShare?> watchShare(String coupleId, String uid) =>
      share(uid).stream;

  @override
  Future<void> putEvent(
    String coupleId,
    String uid,
    ArrivalEvent event, {
    required bool auto,
  }) {
    events.add(event);
    return _write('put ${event.place} auto=$auto');
  }

  @override
  Future<void> turnOn(String coupleId, String uid, {required bool auto}) =>
      _write('on auto=$auto');

  @override
  Future<void> turnOff(String coupleId, String uid) => _write('off');

  @override
  Future<void> setAuto(String coupleId, String uid, bool auto) =>
      _write('auto=$auto');

  @override
  Future<bool> readRemoteAutoEnabled() async => remoteAuto;
}

class FakeGeofence implements ArrivalGeofence {
  bool always = false;
  final calls = <String>[];

  @override
  Future<bool> hasAlwaysPermission() async => always;

  @override
  Future<void> sync(List<ArrivalPlace> places) async =>
      calls.add('sync ${places.map((p) => p.slot).join(',')}');

  @override
  Future<void> stopAll() async => calls.add('stop');
}

class FakeBattery implements BatteryReader {
  FakeBattery(this.value);
  final int? value;
  @override
  Future<int?> level() async => value;
}

ArrivalLocation _loc([
  ArrivalLocationSource s = ArrivalLocationSource.address,
]) => ArrivalLocation(
  lat: 21.0,
  lng: 105.8,
  source: s,
  savedAt: DateTime(2026, 10, 20),
  address: '12 Nguyễn Trãi, Thanh Xuân, Hà Nội',
);

const _gym = ArrivalPlace(slot: 'p1', name: 'Phòng gym', icon: ArrivalIcon.gym);

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('arrival');
    Hive.init(home.path);
  });

  tearDown(() async {
    await Hive.close();
    home.deleteSync(recursive: true);
  });

  group('place name (D19)', () {
    test('trims, 1..24 UTF-16 units, one line', () {
      expect(normalizeArrivalName('  Công ty  '), 'Công ty');
      expect(normalizeArrivalName('a' * 24), 'a' * 24);
      expect(normalizeArrivalName('a' * 25), isNull);
      expect(normalizeArrivalName('   '), isNull);
      expect(normalizeArrivalName('Nhà\nmẹ'), isNull);
      expect(normalizeArrivalName('Nhà\rmẹ'), isNull);
      // Same unit rules `size()` counts: an emoji is 2.
      expect(normalizeArrivalName('🏋' * 12), '🏋' * 12);
      expect(normalizeArrivalName('🏋' * 13), isNull);
      expect(normalizeArrivalName('Nhà ngoại ở Thanh Xuân'), isNotNull);
    });
  });

  group('models', () {
    test('radius follows the source (D1)', () {
      expect(_loc().radius, kArrivalRadiusAddress);
      expect(_loc(ArrivalLocationSource.current).radius, kArrivalRadiusCurrent);
    });

    test('place round-trips; a custom place without a name is dropped', () {
      final p = _gym.withLocation(_loc());
      final back = ArrivalPlace.fromJson('p1', p.toJson())!;
      expect(back.name, 'Phòng gym');
      expect(back.icon, ArrivalIcon.gym);
      expect(back.location!.address, startsWith('12 Nguyễn Trãi'));
      expect(ArrivalPlace.fromJson('p1', {'icon': 'gym'}), isNull);
      expect(ArrivalPlace.fromJson('p9', {'name': 'x'}), isNull);
      expect(ArrivalPlace.fromJson('home', {'name': 'x'})!.name, isNull);
    });

    test('event map: Home has no name/icon, custom snapshots both (D23)', () {
      final at = DateTime(2026, 10, 20, 22, 58);
      Object ts(DateTime d) => d.millisecondsSinceEpoch;
      final h = ArrivalEvent.at(
        const ArrivalPlace.home(),
        type: ArrivalEventType.enter,
        at: at,
        source: ArrivalEventSource.manual,
        battery: 12,
      ).toMap(ts);
      expect(h, {
        'place': 'home',
        'type': 'enter',
        'at': at.millisecondsSinceEpoch,
        'battery': 12,
        'source': 'manual',
      });
      final g = ArrivalEvent.at(
        _gym,
        type: ArrivalEventType.enter,
        at: at,
        source: ArrivalEventSource.auto,
        bounce: true,
      ).toMap(ts);
      expect(g['name'], 'Phòng gym');
      expect(g['icon'], 'gym');
      expect(g['bounce'], true);
      expect(g.containsKey('battery'), isFalse);
      final back = ArrivalEvent.fromMap(g, (v) => at)!;
      expect(back.name, 'Phòng gym');
      expect(back.bounce, isTrue);
    });
  });

  group('edge filter (D6)', () {
    final t0 = DateTime(2026, 10, 20, 22);

    test('first event of an unknown place always counts', () {
      final d = filterArrivalEdge(
        const ArrivalEdgeState(),
        ArrivalEventType.enter,
        t0,
      );
      expect(d.send, isTrue);
      expect(d.bounce, isFalse);
      expect(d.next.inside, isTrue);
    });

    test('same state twice (iOS reboot double fire) is dropped', () {
      const inside = ArrivalEdgeState(inside: true);
      expect(
        filterArrivalEdge(inside, ArrivalEventType.enter, t0).send,
        isFalse,
      );
      const outside = ArrivalEdgeState(inside: false);
      expect(
        filterArrivalEdge(outside, ArrivalEventType.exit, t0).send,
        isFalse,
      );
    });

    test(
      'back within 10 minutes of leaving = bounce, later = real arrival',
      () {
        final out = filterArrivalEdge(
          const ArrivalEdgeState(inside: true),
          ArrivalEventType.exit,
          t0,
        );
        expect(out.send, isTrue);
        expect(out.next.exitAt, t0);
        final quick = filterArrivalEdge(
          out.next,
          ArrivalEventType.enter,
          t0.add(const Duration(minutes: 9)),
        );
        expect(quick.send, isTrue);
        expect(quick.bounce, isTrue);
        final late = filterArrivalEdge(
          out.next,
          ArrivalEventType.enter,
          t0.add(const Duration(minutes: 10)),
        );
        expect(late.bounce, isFalse);
      },
    );

    test('state survives a Hive round trip', () {
      final s = ArrivalEdgeState(inside: false, exitAt: t0);
      final back = ArrivalEdgeState.fromJson(s.toJson());
      expect(back.inside, isFalse);
      expect(back.exitAt, t0);
    });
  });

  group('ArrivalService', () {
    test('Home is always first, even with nothing stored', () async {
      final s = ArrivalService();
      expect((await s.loadPlaces('u')).single.isHome, isTrue);
      await s.savePlaces('u', [_gym, const ArrivalPlace.home()]);
      expect((await s.loadPlaces('u')).map((p) => p.slot), ['home', 'p1']);
    });

    test('auto events go through the edge filter, manual ones never', () async {
      final s = FakeArrivalService();
      await s.savePlaces('u', [ArrivalPlace.home(location: _loc())]);
      Future<ArrivalSendResult> auto(ArrivalEventType type) => s.reportEvent(
        uid: 'u',
        coupleId: 'c',
        slot: 'home',
        type: type,
        source: ArrivalEventSource.auto,
        auto: true,
      );
      expect(await auto(ArrivalEventType.enter), ArrivalSendResult.sent);
      expect(await auto(ArrivalEventType.enter), ArrivalSendResult.dropped);
      expect(await auto(ArrivalEventType.exit), ArrivalSendResult.sent);
      expect(await auto(ArrivalEventType.enter), ArrivalSendResult.sent);
      expect(s.events.last.bounce, isTrue);
      final manual = await s.reportEvent(
        uid: 'u',
        coupleId: 'c',
        slot: 'home',
        type: ArrivalEventType.enter,
        source: ArrivalEventSource.manual,
        auto: false,
      );
      expect(manual, ArrivalSendResult.sent);
      expect(s.events.last.bounce, isFalse);
      expect(s.calls.length, 4);
    });

    test('a failed / denied auto event leaves the in/out state alone', () async {
      final s = FakeArrivalService();
      await s.savePlaces('u', [ArrivalPlace.home(location: _loc())]);
      Future<ArrivalSendResult> enter() => s.reportEvent(
        uid: 'u',
        coupleId: 'c',
        slot: 'home',
        type: ArrivalEventType.enter,
        source: ArrivalEventSource.auto,
        auto: true,
      );
      s.writeError = StateError('offline-ish');
      expect(await enter(), ArrivalSendResult.failed);
      expect((await s.loadEdge('u', 'home')).inside, isNull);
      s.writeError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      expect(await enter(), ArrivalSendResult.denied);
      expect((await s.loadEdge('u', 'home')).inside, isNull);
      s.writeError = null;
      expect(await enter(), ArrivalSendResult.sent);
      expect((await s.loadEdge('u', 'home')).inside, isTrue);
      s.holdWrite = Completer<void>();
      await s.saveEdge('u', 'home', const ArrivalEdgeState(inside: false));
      expect(await enter(), ArrivalSendResult.queued);
      expect((await s.loadEdge('u', 'home')).inside, isTrue);
      s.holdWrite!.complete();
    });

    test('an unknown slot writes nothing', () async {
      final s = FakeArrivalService();
      final r = await s.reportEvent(
        uid: 'u',
        coupleId: 'c',
        slot: 'p3',
        type: ArrivalEventType.enter,
        source: ArrivalEventSource.manual,
        auto: false,
      );
      expect(r, ArrivalSendResult.dropped);
      expect(s.calls, isEmpty);
    });

    test('write outcomes: acked / not acked / denied / other error', () async {
      final s = FakeArrivalService();
      expect(await s.send(() async {}), ArrivalSendResult.sent);
      expect(
        await s.send(() => Completer<void>().future),
        ArrivalSendResult.queued,
      );
      expect(
        await s.send(
          () async => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        ArrivalSendResult.denied,
      );
      expect(
        await s.send(() async => throw StateError('x')),
        ArrivalSendResult.failed,
      );
    });

    test('account deletion wipes only that user', () async {
      final s = ArrivalService();
      await s.savePlaces('a', [_gym]);
      await s.savePlaces('b', [_gym]);
      await s.saveWantsAuto('a', true);
      await s.saveSession('a', 'c');
      await ArrivalService.wipeLocalData('a');
      expect((await s.loadPlaces('a')).length, 1);
      expect(await s.loadWantsAuto('a'), isFalse);
      expect(await s.loadSession(), isNull);
      expect((await s.loadPlaces('b')).length, 2);
    });
  });

  group('ArrivalProvider', () {
    late FakeArrivalService service;
    late FakeGeofence geofence;

    ArrivalProvider make({int? battery = 15}) => ArrivalProvider(
      service: service,
      geofence: geofence,
      battery: FakeBattery(battery),
      autoBuildAllowed: true,
    );

    setUp(() {
      service = FakeArrivalService();
      geofence = FakeGeofence();
    });

    test('hidden while the couple waits for a partner (D9)', () async {
      final p = make();
      await p.watchForCouple('c', 'me', '');
      expect(p.visible, isFalse);
      expect(await p.sendManual(), ArrivalSendResult.dropped);
      expect(service.calls, isEmpty);
      expect(await service.loadSession(), isNull);
    });

    test('"Về nhà rồi" sends Home + battery, no permission needed', () async {
      final p = make();
      await p.watchForCouple('c', 'me', 'her');
      expect(p.visible, isTrue);
      expect(await p.sendManual(), ArrivalSendResult.sent);
      final e = service.events.single;
      expect(e.place, 'home');
      expect(e.name, isNull);
      expect(e.battery, 15);
      expect(e.source, ArrivalEventSource.manual);
      expect(service.calls, ['put home auto=false']);
      expect((await service.loadSession())?.coupleId, 'c');
    });

    test('"Đến nơi rồi" snapshots the name; a rename later does not', () async {
      final p = make(battery: null);
      await p.watchForCouple('c', 'me', 'her');
      expect(await p.savePlace(_gym), isTrue);
      await p.sendManual('p1');
      expect(service.events.single.name, 'Phòng gym');
      expect(service.events.single.icon, ArrivalIcon.gym);
      expect(service.events.single.battery, isNull);
      await p.savePlace(
        const ArrivalPlace(slot: 'p1', name: 'Gym', icon: ArrivalIcon.gym),
      );
      expect(service.events.single.name, 'Phòng gym');
    });

    test('offline: reported as queued, failure → retry same place', () async {
      final p = make();
      await p.watchForCouple('c', 'me', 'her');
      await p.savePlace(_gym);
      service.holdWrite = Completer<void>();
      expect(await p.sendManual('p1'), ArrivalSendResult.queued);
      expect(p.lastResult, ArrivalSendResult.queued);
      service.holdWrite = null;
      service.writeError = StateError('boom');
      expect(await p.sendManual('p1'), ArrivalSendResult.failed);
      service.writeError = null;
      expect(await p.retry(), ArrivalSendResult.sent);
      expect(service.events.last.place, 'p1');
    });

    test('Home + at most 4 custom places; Home is never removed', () async {
      final p = make();
      await p.watchForCouple('c', 'me', 'her');
      for (final slot in ['p1', 'p2', 'p3', 'p4']) {
        expect(
          await p.savePlace(ArrivalPlace(slot: slot, name: 'Nơi $slot')),
          isTrue,
        );
      }
      expect(p.canAddPlace, isFalse);
      expect(p.nextFreeSlot, isNull);
      expect(
        await p.savePlace(const ArrivalPlace(slot: 'p1', name: ' ')),
        isFalse,
      );
      await p.savePlace(ArrivalPlace.home(location: _loc()));
      final removed = await p.deletePlace('home');
      expect(removed!.location, isNotNull);
      expect(p.home.location, isNull);
      expect(p.places.length, 5);
      await p.deletePlace('p2');
      expect(p.nextFreeSlot, 'p2');
      expect(p.customPlaces.map((x) => x.icon).toSet(), {ArrivalIcon.pin});
    });

    test(
      'auto runs only with share + Always + a located place + remote on',
      () async {
        final p = make();
        await p.watchForCouple('c', 'me', 'her');
        await p.savePlace(ArrivalPlace.home(location: _loc()));
        geofence.always = true;
        await p.setWantsAuto(true);
        expect(p.autoRunning, isFalse); // not sharing yet
        service.share('me').add(const ArrivalShare(share: true));
        await pumpEventQueue();
        expect(p.autoRunning, isTrue);
        expect(geofence.calls.last, 'sync home');
        expect(service.calls.last, 'auto=true'); // partner's card says "tự báo"

        service.remoteAuto = false; // config/app.arrivalAutoEnabled = false
        await p.onResume();
        expect(p.autoRunning, isFalse);
        expect(p.autoRemoteOff, isTrue);
        expect(geofence.calls.last, 'stop');

        service.remoteAuto = true;
        geofence.always = false; // lowered in Settings (D8)
        await p.onResume();
        expect(p.needsAlways, isTrue);
        expect(geofence.calls.last, 'stop');
      },
    );

    test(
      'sharing off: one write, geofences stop, locations optional (D11)',
      () async {
        final p = make();
        await p.watchForCouple('c', 'me', 'her');
        await p.savePlace(ArrivalPlace.home(location: _loc()));
        await p.savePlace(_gym.withLocation(_loc()));
        await p.setWantsAuto(true);
        expect(
          await p.setShare(false, deletePlaces: true),
          ArrivalSendResult.sent,
        );
        expect(service.calls.last, 'off');
        expect(geofence.calls, contains('stop'));
        expect(p.wantsAuto, isFalse);
        expect(p.placesWithLocation, isEmpty);
        expect(p.customPlaces.single.name, 'Phòng gym');
      },
    );

    test('partner event shows only while they share', () async {
      final p = make();
      await p.watchForCouple('c', 'me', 'her');
      final e = ArrivalEvent(
        place: 'home',
        type: ArrivalEventType.enter,
        at: DateTime(2026, 10, 20, 22, 58),
        source: ArrivalEventSource.auto,
      );
      service.share('her').add(ArrivalShare(share: true, auto: true, last: e));
      await pumpEventQueue();
      expect(p.partnerLast?.place, 'home');
      expect(p.partnerAuto, isTrue);
      service.share('her').add(const ArrivalShare(share: false));
      await pumpEventQueue();
      expect(p.partnerShares, isFalse);
      expect(p.partnerLast, isNull);
    });

    test('a background write denied → every geofence stops', () async {
      final p = make();
      await p.watchForCouple('c', 'me', 'her');
      service.writeError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      geofence.calls.clear();
      expect(await p.sendManual(), ArrivalSendResult.denied);
      expect(geofence.calls, ['stop']);
    });
  });

  group('pushArrival switch (D16)', () {
    final settings = NotificationSettingsService.instance;

    test('reads the stored value; legacy keys stay forced ON', () async {
      await Hive.close();
      expect(
        settings.currentOrDefault().containsKey(
          NotificationSettingsService.keyArrival,
        ),
        isFalse, // box not open: leave the device doc's value alone
      );
      await settings.ensureLoaded();
      expect(settings.currentOrDefault()['pushArrival'], isTrue);
      await settings.set(NotificationSettingsService.keyArrival, false);
      await settings.set(NotificationSettingsService.keyPhoto, false);
      final prefs = settings.currentOrDefault();
      expect(prefs['pushArrival'], isFalse);
      expect(prefs['pushPhoto'], isTrue);
      expect(prefs['pushReaction'], isTrue);
      expect(prefs['pushDailyQuestion'], isTrue);
      expect(await settings.arrivalPushEnabled(), isFalse);
    });
  });
}
