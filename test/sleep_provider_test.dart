import 'dart:async';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
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
  Future<List<({DateTime from, DateTime until})>> claimDevice(
    String uid,
  ) async => const [];
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

/// My own history comes back from the server only when [hold] completes.
class SlowRemoteSleepService extends FakeSleepService {
  final hold = Completer<void>();
  Map<String, SleepNight> remote = {};
  final savedFingerprintsOf = <String>[];

  @override
  Future<Map<String, SleepNight>> fetchNights(
    String coupleId,
    String uid,
  ) async {
    await hold.future;
    return Map.of(remote);
  }

  @override
  Future<void> saveFingerprints(
    String uid,
    String coupleId,
    Map<String, String> fingerprints,
  ) {
    savedFingerprintsOf.add('$uid:$coupleId');
    return super.saveFingerprints(uid, coupleId, fingerprints);
  }
}

/// PROD rules from before 1.9.1: a night carrying `tz` is refused.
class OldRulesSleepService extends FakeSleepService {
  bool rulesDeployed = false;

  @override
  Future<void> putNight(String coupleId, String uid, SleepNight night) async {
    if (night.tz != null && !rulesDeployed) {
      calls.add('denied ${night.date}');
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    calls.add('put ${night.date}${night.tz == null ? '' : ' tz'}');
  }
}

/// The partner shares [partner].
class PartnerFakeSleepService extends FakeSleepService {
  Map<String, SleepNight> partner = {};
  @override
  Stream<Map<String, SleepNight>> watchNights(
    String coupleId,
    String uid, {
    required String sinceKey,
  }) => Stream.value(Map.of(partner));
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

  test(
    "SL1: A's history pulled on a slow network never lands in B's data",
    () async {
      final aOld = night(40);
      final service = SlowRemoteSleepService()..remote = {aOld.date: aOld};
      final provider = SleepProvider(service: service);
      // A on a new phone, sharing: the pull of A's history starts…
      await provider.watchForCouple('cA', 'A', 'pA');
      service.profile('cA', 'A').add(const SleepProfile(share: true));
      await pumpEventQueue();
      // …A signs out and B signs in before it comes back.
      provider.clear();
      await provider.watchForCouple('cB', 'B', 'pB');
      service.hold.complete();
      await pumpEventQueue();
      expect(provider.myNights.keys, isNot(contains(aOld.date)));
      expect(service.savedFingerprintsOf, isNot(contains('A:cA')));
    },
  );

  test("SL8: a logged night keeps this phone's clock", () async {
    final (provider, _) = await start();
    final today = DateTime.now();
    final wakeAt = DateTime(today.year, today.month, today.day, 7);
    final bedAt = wakeAt.subtract(const Duration(hours: 8));
    await provider.saveNight(sleepDateKey(wakeAt), bedAt, wakeAt);
    final saved = provider.myNights[sleepDateKey(wakeAt)]!;
    expect(saved.source, SleepSource.manual);
    expect(saved.tz, bedAt.timeZoneOffset.inMinutes);
  });

  test('R2-a: an edited night from a trip keeps its own clock', () async {
    // My night in New York (UTC−4), 23:00 → 07:00 there, edited back home.
    final d = DateTime.now();
    final trip = SleepNight(
      date: sleepDateKey(d),
      bedAt: DateTime.utc(d.year, d.month, d.day, 3),
      wakeAt: DateTime.utc(d.year, d.month, d.day, 11),
      source: SleepSource.auto,
      tz: -240,
    );
    final (provider, _) = await start(nights: {trip.date: trip});
    await provider.saveNight(
      trip.date,
      trip.bedAt,
      trip.wakeAt.add(const Duration(minutes: 30)),
      tz: trip.tz,
    );
    final saved = provider.myNights[trip.date]!;
    expect(saved.source, SleepSource.edited);
    expect(saved.tz, -240);
    expect(saved.bedAt.isAtSameMomentAs(trip.bedAt), isTrue);
    expect([saved.wakeClock.hour, saved.wakeClock.minute], [7, 30]);
  });

  test('SL8: "last night" of a partner abroad is on their clock', () async {
    // Partner in New York (UTC−4), this phone in Vietnam (UTC+7).
    final away = SleepNight(
      date: '2026-10-11',
      bedAt: DateTime.utc(2026, 10, 11, 3), // 23:00 there
      wakeAt: DateTime.utc(2026, 10, 11, 11), // 07:00 there
      source: SleepSource.auto,
      tz: -240,
    );
    final service = PartnerFakeSleepService()..partner = {away.date: away};
    final provider = SleepProvider(service: service);
    await provider.watchForCouple('c', 'me', 'partner');
    service.profile('c', 'partner').add(const SleepProfile(share: true));
    await pumpEventQueue();
    expect(provider.partnerNights.keys, [away.date]);
    // 08:00 on the 12th here = 21:00 on the 11th there.
    final eightHere = DateTime.utc(2026, 10, 12, 1);
    expect(
      SleepProvider.lastNightKey(eightHere.add(const Duration(hours: 7))),
      '2026-10-12',
    );
    expect(provider.partnerLastNightKey(eightHere), '2026-10-11');
    // 03:30 there: their night isn't over yet; 04:30: it is.
    expect(
      provider.partnerLastNightKey(DateTime.utc(2026, 10, 12, 7, 30)),
      '2026-10-11',
    );
    expect(
      provider.partnerLastNightKey(DateTime.utc(2026, 10, 12, 8, 30)),
      '2026-10-12',
    );
  });

  test('1.9.1 before the PROD rules: a night refused for its tz goes up '
      'without it', () async {
    // Recorded with a clock; one recent, one 9 days old that never went up.
    final recent = night(1).copyWith(tz: 420);
    final old = night(9).copyWith(tz: 420);
    final service = OldRulesSleepService()
      ..nights = {recent.date: recent, old.date: old};
    final provider = SleepProvider(service: service);
    await provider.watchForCouple('c', 'me', 'partner');
    service.profile('c', 'me').add(const SleepProfile(share: true));
    await pumpEventQueue();
    expect(
      service.calls,
      containsAll(['put ${recent.date}', 'put ${old.date}']),
    );
    // Marked as up — the old one would otherwise stay "pushing" for good.
    expect(service.fingerprints[recent.date], recent.fingerprint);
    expect(service.fingerprints[old.date], old.fingerprint);

    // The new rules take the night as it is, in one write.
    service
      ..rulesDeployed = true
      ..calls.clear();
    await provider.saveNight(
      recent.date,
      recent.bedAt,
      recent.wakeAt.add(const Duration(minutes: 20)),
    );
    await pumpEventQueue();
    expect(service.calls, ['put ${recent.date} tz']);
  });
}
