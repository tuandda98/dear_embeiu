import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/sleep_night.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/services/sleep_service.dart';

/// Records every remote write; the tests drive the profile streams. Adapted
/// from the Tester's round-3 harness.
class FakeSleepService extends SleepService {
  final calls = <String>[];
  final _profiles = <String, StreamController<SleepProfile?>>{};
  Map<String, SleepNight?> nights = {};
  Map<String, String> fingerprints = {};
  Completer<void>? holdFlag; // the flag write is never acked (offline)
  Completer<void>? holdPut;
  Completer<void>? holdSave; // a slow Hive write of the fingerprints
  Completer<void>? holdDeleteAll;

  StreamController<SleepProfile?> profile(String coupleId, String uid) =>
      _profiles.putIfAbsent(
        '$coupleId/$uid',
        StreamController<SleepProfile?>.broadcast,
      );

  @override
  bool get isUsingFirebase => true;
  @override
  Future<SleepSettings> loadSettings(String uid) async =>
      const SleepSettings(enabled: true, mode: SleepMode.manual);
  @override
  Future<void> saveSettings(String uid, SleepSettings settings) async {}
  @override
  Future<Map<String, SleepNight?>> loadNights(String uid) async =>
      Map.of(nights);
  @override
  Future<void> saveNights(String uid, Map<String, SleepNight?> nights) async {}
  @override
  Future<Map<String, String>> loadFingerprints(
    String uid,
    String coupleId,
  ) async => Map.of(fingerprints);
  @override
  Future<void> saveFingerprints(
    String uid,
    String coupleId,
    Map<String, String> fingerprints,
  ) async {
    await holdSave?.future;
    this.fingerprints = Map.of(fingerprints);
  }

  @override
  Stream<SleepProfile?> watchProfile(String coupleId, String uid) =>
      profile(coupleId, uid).stream;
  @override
  Stream<Map<String, SleepNight>> watchNights(
    String coupleId,
    String uid, {
    required String sinceKey,
  }) => const Stream.empty();
  @override
  Future<Map<String, SleepNight>> fetchNights(
    String coupleId,
    String uid,
  ) async => {};
  @override
  Future<void> setProfile(
    String coupleId,
    String uid, {
    bool? share,
    String? color,
  }) async {
    calls.add('flag $coupleId share=$share');
    await holdFlag?.future;
  }

  @override
  Future<void> putNight(String coupleId, String uid, SleepNight night) async {
    calls.add('put ${night.date}');
    await holdPut?.future;
  }

  @override
  Future<void> deleteNight(String coupleId, String uid, String date) async =>
      calls.add('delete $date');
  @override
  Future<void> deleteAllNights(String coupleId, String uid) async {
    calls.add('deleteAll');
    await holdDeleteAll?.future;
  }
}

/// Also returns my own shared nights from the server (a new phone).
class RemoteFakeSleepService extends FakeSleepService {
  Map<String, SleepNight> remote = {};
  @override
  Future<Map<String, SleepNight>> fetchNights(
    String coupleId,
    String uid,
  ) async => Map.of(remote);
}

SleepNight night(int daysAgo) {
  final d = DateTime.now().subtract(Duration(days: daysAgo));
  final wake = DateTime(d.year, d.month, d.day, 7);
  return SleepNight(
    date: sleepDateKey(wake),
    bedAt: wake.subtract(const Duration(hours: 8)),
    wakeAt: wake,
    source: SleepSource.auto,
  );
}

Future<(SleepProvider, FakeSleepService)> start({
  Map<String, SleepNight?> nights = const {},
  Map<String, String> fingerprints = const {},
  bool? share,
}) async {
  final service = FakeSleepService()
    ..nights = Map.of(nights)
    ..fingerprints = Map.of(fingerprints);
  final provider = SleepProvider(service: service);
  await provider.watchForCouple('c', 'me', 'partner');
  if (share != null) {
    service.profile('c', 'me').add(SleepProfile(share: share, color: 'rose'));
    await pumpEventQueue();
  }
  return (provider, service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'N8: "off" right after a pending "on" goes to Firestore at once',
    () async {
      final (provider, service) = await start(share: false);
      service.holdFlag = Completer<void>(); // offline: no ack
      await provider.setShare(true);
      await provider.setShare(false);
      await pumpEventQueue();
      // Both flags sit in Firestore's own (persisted) queue, in tap order.
      expect(service.calls, ['flag c share=true', 'flag c share=false']);
      expect(provider.myShare, isFalse);
    },
  );

  test(
    'N9: not shared on the server but nights marked up → delete them',
    () async {
      final n = night(1);
      final (_, service) = await start(
        nights: {n.date: n},
        fingerprints: {n.date: n.fingerprint},
        share: false,
      );
      await pumpEventQueue();
      expect(service.calls, contains('deleteAll'));
      expect(service.fingerprints, isEmpty);
    },
  );

  test('N14: nothing is pushed until my "on" has landed', () async {
    final n = night(1);
    final (provider, service) = await start(nights: {n.date: n}, share: false);
    service.holdFlag = Completer<void>();
    await provider.setShare(true);
    // The SDK shows my pending write at once.
    service.profile('c', 'me').add(const SleepProfile(share: true));
    await pumpEventQueue();
    expect(service.calls.where((c) => c.startsWith('put')), isEmpty);
    service.holdFlag!.complete();
    await pumpEventQueue();
    expect(service.calls.where((c) => c == 'put ${n.date}'), hasLength(1));
  });

  test(
    'N15: a wipe cut short, then "on" again → the nights go back up',
    () async {
      final n = night(1);
      final (first, service) = await start(
        nights: {n.date: n},
        fingerprints: {n.date: n.fingerprint},
        share: true,
      );
      service.holdDeleteAll = Completer<void>(); // the wipe never finishes
      await first.setShare(false);
      await first.setShare(true);
      await pumpEventQueue();
      first.clear(); // the app is killed
      service.calls.clear();
      // Firestore replays [off, deletes…, on]; the upload of the "on" is gone.
      final second = SleepProvider(service: service);
      await second.watchForCouple('c', 'me', 'partner');
      service.profile('c', 'me').add(const SleepProfile(share: true));
      await pumpEventQueue();
      expect(service.calls, contains('put ${n.date}'));
    },
  );

  test(
    'N14b: a resume or an edit while my "on" is pending pushes nothing',
    () async {
      final n = night(1);
      final (provider, service) = await start(
        nights: {n.date: n},
        share: false,
      );
      service.holdFlag = Completer<void>();
      await provider.setShare(true);
      await provider.onResume();
      await provider.saveNight(
        n.date,
        n.bedAt.add(const Duration(minutes: 10)),
        n.wakeAt,
      );
      await pumpEventQueue();
      expect(service.calls.where((c) => c.startsWith('put')), isEmpty);
      service.holdFlag!.complete();
      await pumpEventQueue();
      expect(service.calls.where((c) => c == 'put ${n.date}'), hasLength(1));
    },
  );

  test(
    'N19: new phone, "on" tapped before my profile loaded → history back',
    () async {
      final old = night(30);
      final service = RemoteFakeSleepService()..remote = {old.date: old};
      final provider = SleepProvider(service: service);
      await provider.watchForCouple('c', 'me', 'partner');
      service.holdFlag = Completer<void>();
      await provider.setShare(true);
      service.profile('c', 'me').add(const SleepProfile(share: true));
      await pumpEventQueue();
      service.holdFlag!.complete();
      await pumpEventQueue();
      expect(provider.myNights.keys, contains(old.date));
    },
  );

  test('N1: deleting a night still on its way up sends the delete', () async {
    final n = night(1);
    final (provider, service) = await start(nights: {n.date: n});
    service.holdPut = Completer<void>(); // the put never lands
    service.profile('c', 'me').add(const SleepProfile(share: true));
    await pumpEventQueue();
    expect(service.calls, contains('put ${n.date}'));
    await provider.deleteNight(n.date);
    await pumpEventQueue();
    expect(service.calls, contains('delete ${n.date}'));
  });

  test(
    'N12: a night deleted while its marker is saved is not pushed',
    () async {
      final n = night(1);
      final (provider, service) = await start(
        nights: {n.date: n},
        fingerprints: {n.date: 'old'},
      );
      service.holdSave = Completer<void>();
      service.profile('c', 'me').add(const SleepProfile(share: true));
      await pumpEventQueue();
      final deleting = provider.deleteNight(n.date);
      await pumpEventQueue();
      service.holdSave!.complete();
      await deleting;
      await pumpEventQueue();
      expect(service.calls, contains('delete ${n.date}'));
      expect(service.calls, isNot(contains('put ${n.date}')));
    },
  );

  test('N13: moving to another couple drops the old sharing state', () async {
    final (provider, service) = await start(share: true);
    expect(provider.myShare, isTrue);
    await provider.watchForCouple('other', 'me', 'someone');
    expect(provider.myShare, isFalse);
    expect(service.calls.where((c) => c.startsWith('put')), isEmpty);
  });
}
