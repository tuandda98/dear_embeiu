import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dear_embeiu/models/arrival.dart';
import 'package:dear_embeiu/providers/arrival_provider.dart';
import 'package:dear_embeiu/services/arrival_service.dart';
import 'package:dear_embeiu/utils/arrival_place_query.dart';

import 'arrival_test.dart' show FakeArrivalService, FakeGeofence, FakeBattery;

/// Feature arrival: cases of `test-cases.md` that had no test yet (provider,
/// ARB parity, plist strings, analytics privacy). Widget gaps live in
/// `arrival_gap_ui_test.dart`.
ArrivalLocation _at(double lat, double lng) => ArrivalLocation(
  lat: lat,
  lng: lng,
  source: ArrivalLocationSource.address,
  savedAt: DateTime(2026, 10, 20),
);

const _gym = ArrivalPlace(slot: 'p1', name: 'Phòng gym', icon: ArrivalIcon.gym);

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m.group(1)!).toSet();

void main() {
  late Directory home;
  late FakeArrivalService service;
  late FakeGeofence geofence;

  setUp(() {
    home = Directory.systemTemp.createTempSync('arrival_gap');
    Hive.init(home.path);
    service = FakeArrivalService();
    geofence = FakeGeofence();
  });

  tearDown(() async {
    await Hive.close();
    home.deleteSync(recursive: true);
  });

  ArrivalProvider make({bool autoAllowed = true}) => ArrivalProvider(
    service: service,
    geofence: geofence,
    battery: FakeBattery(50),
    autoBuildAllowed: autoAllowed,
  );

  group('provider', () {
    test(
      'BT-08: auto build not allowed → auto never available/running',
      () async {
        final p = make(autoAllowed: false);
        await p.watchForCouple('c', 'me', 'her');
        await p.savePlace(ArrivalPlace.home(location: _at(21, 105.8)));
        geofence.always = true;
        await p.setWantsAuto(true);
        service.share('me').add(const ArrivalShare(share: true));
        await pumpEventQueue();
        expect(p.autoAvailable, isFalse);
        expect(p.autoRunning, isFalse);
        expect(p.needsAlways, isFalse);
        expect(geofence.calls.where((c) => c.startsWith('sync')), isEmpty);
        // The manual path still works.
        expect(await p.sendManual(), ArrivalSendResult.sent);
      },
    );

    test('SK-14: 5 fast taps on "Về nhà rồi" write once', () async {
      final p = make();
      await p.watchForCouple('c', 'me', 'her');
      service.holdWrite = Completer<void>();
      final taps = [for (var i = 0; i < 5; i++) p.sendManual()];
      await pumpEventQueue();
      expect(p.sending, isTrue);
      final results = await Future.wait(taps);
      expect(service.calls.where((c) => c.startsWith('put')), hasLength(1));
      expect(
        results.where((r) => r == ArrivalSendResult.dropped),
        hasLength(4),
      );
      expect(p.sending, isFalse);
    });

    test(
      'NA-06: couple turns active mid-session → visible + watch armed',
      () async {
        final p = make();
        await p.watchForCouple('c', 'me', '');
        expect(p.visible, isFalse);
        var notified = 0;
        p.addListener(() => notified++);
        await p.watchForCouple('c', 'me', 'her');
        expect(p.visible, isTrue);
        expect(notified, greaterThan(0));
        expect(p.partnerShares, isFalse);
        service
            .share('her')
            .add(
              ArrivalShare(
                share: true,
                last: ArrivalEvent(
                  place: 'home',
                  type: ArrivalEventType.enter,
                  at: DateTime.now(),
                  source: ArrivalEventSource.manual,
                ),
              ),
            );
        await pumpEventQueue();
        expect(p.partnerShares, isTrue);
        expect(p.partnerLast?.place, 'home');
      },
    );

    test('NA-11: sign-out stops geofences; places are per uid', () async {
      final p = make();
      await p.watchForCouple('c', 'u1', 'her');
      await p.savePlace(ArrivalPlace.home(location: _at(21, 105.8)));
      await p.savePlace(_gym);
      expect(p.placesWithLocation, hasLength(1));
      p.clear(signedOut: true);
      await pumpEventQueue();
      expect(geofence.calls, contains('stop'));
      expect(p.visible, isFalse);

      await p.watchForCouple('c2', 'u2', 'him');
      expect(p.home.location, isNull);
      expect(p.customPlaces, isEmpty);
      // The first user's data is untouched in Hive.
      final back = await service.loadPlaces('u1');
      expect(back.first.location, isNotNull);
      expect(back.map((x) => x.slot), contains('p1'));
    });

    test('OF-08: guest / no couple → card hidden, nothing sent', () async {
      final p = make();
      expect(p.visible, isFalse);
      await p.watchForCouple('', '', '');
      expect(p.visible, isFalse);
      expect(await p.sendManual(), ArrivalSendResult.dropped);
      await p.onResume();
      expect(service.calls, isEmpty);
    });

    test('DD-21: two overlapping places keep separate in/out state', () async {
      final p = make();
      await p.watchForCouple('c', 'me', 'her');
      // Same coordinates: Home and a custom place on top of each other.
      await p.savePlace(ArrivalPlace.home(location: _at(21, 105.8)));
      await p.savePlace(
        ArrivalPlace(
          slot: 'p1',
          name: 'Phòng gym',
          icon: ArrivalIcon.gym,
          location: _at(21, 105.8),
        ),
      );
      geofence.always = true;
      await p.setWantsAuto(true);
      service.share('me').add(const ArrivalShare(share: true));
      await pumpEventQueue();
      expect(p.placesWithLocation.map((x) => x.slot), ['home', 'p1']);
      expect(geofence.calls, contains('sync home,p1'));

      final t = DateTime(2026, 10, 22, 9);
      Future<ArrivalSendResult> fire(
        String slot,
        ArrivalEventType type,
        DateTime at,
      ) => service.reportEvent(
        uid: 'me',
        coupleId: 'c',
        slot: slot,
        type: type,
        source: ArrivalEventSource.auto,
        auto: true,
        at: at,
      );
      expect(
        await fire('home', ArrivalEventType.enter, t),
        ArrivalSendResult.sent,
      );
      // p1 has not seen its own enter yet: Home's state doesn't leak.
      expect(
        await fire('p1', ArrivalEventType.enter, t),
        ArrivalSendResult.sent,
      );
      expect(
        await fire('home', ArrivalEventType.enter, t),
        ArrivalSendResult.dropped,
      );
      expect(
        await fire('p1', ArrivalEventType.exit, t),
        ArrivalSendResult.sent,
      );
      // Home still inside: its exit is a fresh event, p1's second exit is a dupe.
      expect(
        await fire('p1', ArrivalEventType.exit, t),
        ArrivalSendResult.dropped,
      );
      expect(
        await fire('home', ArrivalEventType.exit, t),
        ArrivalSendResult.sent,
      );
    });
  });

  group('address filter', () {
    test('DD-23: a result in another province / abroad is dropped', () {
      expect(
        arrivalResultInProvince(
          '78 Giải Phóng, Phường Phan Đình Phùng, Ninh Bình',
          'ha noi',
        ),
        isFalse,
      );
      expect(
        arrivalResultInProvince('1 Orchard Road, Singapore', 'ha noi'),
        isTrue, // no Vietnamese province named → kept by this filter (box does the rest)
      );
      expect(
        arrivalResultInProvince('12 Nguyễn Trãi, Hà Nội', 'ha noi'),
        isTrue,
      );
      expect(arrivalResultInProvince('Anywhere', null), isTrue);
    });
  });

  group('ARB + plist', () {
    Map<String, dynamic> arb(String lang) =>
        jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
            as Map<String, dynamic>;

    test(
      'NN-02: every arrival* key exists in vi and en with the same placeholders',
      () {
        final vi = arb('vi');
        final en = arb('en');
        Set<String> keys(Map<String, dynamic> m) => {
          for (final k in m.keys)
            if (k.startsWith('arrival')) k,
        };
        expect(keys(vi), isNotEmpty);
        expect(keys(vi), keys(en));
        for (final k in keys(vi)) {
          expect(vi[k], isA<String>(), reason: k);
          expect(en[k], isA<String>(), reason: k);
          expect((vi[k] as String).trim(), isNotEmpty, reason: 'vi $k');
          expect((en[k] as String).trim(), isNotEmpty, reason: 'en $k');
          expect(
            _placeholders(vi[k] as String),
            _placeholders(en[k] as String),
            reason: k,
          );
        }
      },
    );

    test(
      'NN-06: iOS location prompts exist in vi + en and say they send "leave"',
      () {
        String? value(String path, String key) {
          final m = RegExp(
            '"$key"\\s*=\\s*"((?:[^"\\\\]|\\\\.)*)";',
          ).firstMatch(File(path).readAsStringSync());
          return m?.group(1);
        }

        for (final key in [
          'NSLocationWhenInUseUsageDescription',
          'NSLocationAlwaysAndWhenInUseUsageDescription',
        ]) {
          expect(
            value('ios/Runner/vi.lproj/InfoPlist.strings', key),
            isNotNull,
            reason: 'vi $key',
          );
          expect(
            value('ios/Runner/en.lproj/InfoPlist.strings', key),
            isNotNull,
            reason: 'en $key',
          );
          expect(
            File('ios/Runner/Info.plist').readAsStringSync(),
            contains('<key>$key</key>'),
          );
        }
        const always = 'NSLocationAlwaysAndWhenInUseUsageDescription';
        expect(
          value('ios/Runner/vi.lproj/InfoPlist.strings', always)!.toLowerCase(),
          contains('rời'),
        );
        expect(
          value('ios/Runner/en.lproj/InfoPlist.strings', always)!.toLowerCase(),
          contains('leave'),
        );
      },
    );
  });

  group('analytics privacy', () {
    test(
      'RT-11: logArrival* take only enum / bool / count-like params, and call sites pass no PII',
      () {
        final src = File(
          'lib/services/analytics_service.dart',
        ).readAsStringSync();
        final methods = RegExp(
          r'void (logArrival\w+)\(([^)]*)\)',
        ).allMatches(src).toList();
        expect(methods, hasLength(8));
        // Only these names can ever be sent; none can carry a name/address/pin %.
        const allowed = {
          'from',
          'step',
          'result',
          'slot',
          'source',
          'icon',
          'hasHouseNumber',
          'platform',
          'on',
          'auto',
          'action',
        };
        for (final m in methods) {
          final params = m.group(2)!.replaceAll(RegExp(r'[{}]'), '');
          for (final part in params.split(',')) {
            final p = part.trim().replaceFirst('required ', '');
            if (p.isEmpty) continue;
            final bits = p.split(RegExp(r'\s+'));
            expect(bits, hasLength(2), reason: '${m.group(1)}: $p');
            expect(
              bits.first,
              anyOf('String', 'bool', 'int'),
              reason: '${m.group(1)}: $p',
            );
            expect(allowed, contains(bits.last), reason: '${m.group(1)}: $p');
          }
        }
        final bad = RegExp(
          r'\b(address|controller|battery|lat|lng|query|displayName|partner)\b|\.text\b',
        );
        final callRe = RegExp(r'logArrival\w+\(([\s\S]*?)\);');
        var calls = 0;
        for (final f
            in Directory('lib')
                .listSync(recursive: true)
                .whereType<File>()
                .where(
                  (f) =>
                      f.path.endsWith('.dart') &&
                      !f.path.endsWith('analytics_service.dart'),
                )) {
          for (final m in callRe.allMatches(f.readAsStringSync())) {
            calls++;
            expect(
              bad.hasMatch(m.group(1)!),
              isFalse,
              reason: '${f.path}: ${m.group(0)}',
            );
          }
        }
        expect(calls, greaterThanOrEqualTo(8));
      },
    );
  });
}
