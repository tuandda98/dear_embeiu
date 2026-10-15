import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dear_embeiu/models/sleep_night.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/services/sleep_service.dart';

/// Local storage of feature sleep (audit 2026-10-12). No path_provider in unit
/// tests, so Hive's home is a temp folder (= app documents on a phone).
void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('sleep_storage');
    Hive.init(home.path);
  });

  tearDown(() async {
    await Hive.close();
    home.deleteSync(recursive: true);
  });

  test('SL5: the old box moves out of the backed-up folder once', () async {
    final legacy = await Hive.openBox<dynamic>('sleep_local');
    await legacy.putAll({
      'settings:u': {'enabled': true, 'mode': 'auto'},
      'nights:u': {
        '2026-10-10': {'date': '2026-10-10'},
      },
      'fp:u:c': {'2026-10-10': 'x'},
    });
    await legacy.close();
    final dir = '${home.path}/sleep_nobackup';

    final box = await SleepService.openBoxIn(dir);
    expect(box.get('settings:u'), {'enabled': true, 'mode': 'auto'});
    expect(box.get('fp:u:c'), {'2026-10-10': 'x'});
    expect(await Hive.boxExists('sleep_local'), isFalse);
    expect(File('$dir/sleep_nobackup.hive').existsSync(), isTrue);

    // The old box comes back (its delete failed last time) after newer
    // writes: those writes win, the old box goes.
    await box.put('settings:u', {'enabled': false});
    await box.close();
    final stale = await Hive.openBox<dynamic>('sleep_local');
    await stale.put('settings:u', {'enabled': true, 'mode': 'auto'});
    await stale.close();
    final again = await SleepService.openBoxIn(dir);
    expect(again.get('settings:u'), {'enabled': false});
    expect(again.get('nights:u'), isNotNull);
    expect(await Hive.boxExists('sleep_local'), isFalse);
  });

  test('SL5: a copy that fails leaves no half copy behind', () async {
    final dir = '${home.path}/sleep_nobackup';
    Hive.registerAdapter(_PoisonAdapter(), override: true);
    // 1.9.0's box, with a value the copy will fail on (disk full).
    final legacy = await Hive.openBox<dynamic>('sleep_local');
    await legacy.putAll({
      'nights:A': {
        '2026-10-10': {'date': '2026-10-10'},
      },
      'settings:A': {'enabled': true},
      'poison': _Poison(),
    });
    await legacy.close();
    // An earlier launch died half-way through the copy.
    final half = await Hive.openBox<dynamic>('sleep_nobackup', path: dir);
    await half.put('nights:A', {
      '2026-10-10': {'date': '2026-10-10'},
    });
    await half.close();

    Hive.registerAdapter(_PoisonAdapter(writable: false), override: true);
    final fallback = await SleepService.openBoxIn(dir);
    expect(fallback.name, 'sleep_local'); // this launch stays on the old box
    // A deletes their account meanwhile, and the disk frees up.
    await fallback.deleteAll(['nights:A', 'settings:A', 'poison']);
    await Hive.close();

    final box = await SleepService.openBoxIn(dir);
    expect(box.get('nights:A'), isNull); // not back from the half copy
    expect(await Hive.boxExists('sleep_local'), isFalse);
  });

  test('SL7: an account taking the phone over only gets nights from then '
      'on', () async {
    final service = SleepService();
    expect(await service.claimDevice('A'), isEmpty); // first account here
    expect(await service.claimDevice('A'), isEmpty);
    final before = DateTime.now().subtract(const Duration(seconds: 1));
    final forB = await service.claimDevice('B');
    expect(forB, hasLength(1));
    expect(forB.single.from, DateTime.fromMillisecondsSinceEpoch(0));
    expect(forB.single.until.isBefore(before), isFalse);
    expect(await service.claimDevice('B'), forB); // kept, not moved
    await service.claimDevice('A'); // B puts it down…
    await service.claimDevice('B'); // …and takes it again
    // Deleting B's account drops B's marks with the rest of B's data.
    await SleepService.wipeLocalData('B');
    final keys = Hive.box<dynamic>('sleep_local').keys;
    expect(keys.where((k) => '$k'.endsWith(':B')), isEmpty);
    expect(Hive.box<dynamic>('sleep_local').get('device:uid'), '');
    // The next account still knows the phone was someone else's.
    expect(await service.claimDevice('C'), hasLength(1));
  });

  test(
    'L3: lent for a few minutes, the owner keeps the night before',
    () async {
      final service = SleepService();
      await service.claimDevice('A'); // A's phone
      final forB = await service.claimDevice('B'); // B signs in…
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final forA = await service.claimDevice('A'); // …A is back soon after
      // Only the time B held it is B's (was: everything before A came back).
      expect(forA, hasLength(1));
      final lent = forA.single;
      expect(lent.from, forB.single.until);
      SleepNight endingAt(DateTime wake) => SleepNight(
        date: sleepDateKey(wake),
        bedAt: wake.subtract(const Duration(hours: 8)),
        wakeAt: wake,
        source: SleepSource.auto,
      );
      // A slept until this morning, before lending the phone: still A's.
      final lastNight = endingAt(lent.from.subtract(const Duration(hours: 2)));
      // A night that ended while B held the phone is B's.
      final whileLent = endingAt(lent.from);
      for (final (night, kept) in [(lastNight, true), (whileLent, false)]) {
        final local = <String, SleepNight?>{};
        SleepProvider.mergeComputed(
          local,
          {night.date: night},
          now: lent.until,
          notMine: forA,
        );
        expect(local.containsKey(night.date), kept);
      }
      // B again: still nothing from before B's first time here, and nothing
      // from while A had it back.
      final forBAgain = await service.claimDevice('B');
      expect(forBAgain, hasLength(2));
      expect(forBAgain.first, forB.single);
      expect(forBAgain.last.from, lent.until);
    },
  );
}

class _Poison {}

/// Writes nothing, reads nothing; with [writable] false every write throws,
/// like a full disk.
class _PoisonAdapter extends TypeAdapter<_Poison> {
  _PoisonAdapter({this.writable = true});

  final bool writable;

  @override
  final int typeId = 200;

  @override
  _Poison read(BinaryReader reader) => _Poison();

  @override
  void write(BinaryWriter writer, _Poison obj) {
    if (!writable) {
      throw const FileSystemException('No space left on device');
    }
  }
}
