import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/sleep_night.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';

SleepNight night(String date) {
  final wake = DateTime.parse(date).add(const Duration(hours: 7));
  return SleepNight(
    date: date,
    bedAt: wake.subtract(const Duration(hours: 8)),
    wakeAt: wake,
    source: SleepSource.auto,
  );
}

void main() {
  const cutoff = '2026-10-04';
  final recent = night('2026-10-10');
  final old = night('2026-09-20');

  test('a recent night is pushed until its fingerprint matches', () {
    expect(SleepProvider.planSync({recent.date: recent}, {}, cutoff).pushes, [
      recent,
    ]);
    expect(
      SleepProvider.planSync(
        {recent.date: recent},
        {recent.date: recent.fingerprint},
        cutoff,
      ).pushes,
      isEmpty,
    );
  });

  test(
    'an upload still on its way is retried, and a delete still goes out',
    () {
      final pushing = {recent.date: 'pushing'};
      expect(
        SleepProvider.planSync({recent.date: recent}, pushing, cutoff).pushes,
        [recent],
      );
      // Tester N1: deleted before the ack → the delete must not be skipped.
      final plan = SleepProvider.planSync({recent.date: null}, pushing, cutoff);
      expect(plan.deletes, [recent.date]);
      expect(plan.pushes, isEmpty);
    },
  );

  test('a deleted night that never went up sends nothing', () {
    final plan = SleepProvider.planSync({recent.date: null}, {}, cutoff);
    expect(plan.deletes, isEmpty);
    expect(plan.pushes, isEmpty);
  });

  group('merging a scan (audit SL2, SL7)', () {
    // Absolute times, so the cases don't depend on this machine's zone.
    SleepNight at(String date, DateTime bed, DateTime wake, int tz) =>
        SleepNight(
          date: date,
          bedAt: bed,
          wakeAt: wake,
          source: SleepSource.auto,
          tz: tz,
        );
    String key(int day) => '2026-10-${day.toString().padLeft(2, '0')}';

    test('a flight Vietnam → Los Angeles rewrites no night', () {
      // 14 nights slept in Vietnam (UTC+7): 22:20 → 07:00 on the wake date.
      final local = <String, SleepNight?>{
        for (var d = 3; d <= 16; d++)
          key(d): at(
            key(d),
            DateTime.utc(2026, 10, d - 1, 15, 20),
            DateTime.utc(2026, 10, d),
            420,
          ),
      };
      final before = Map.of(local);
      // The same screen events scanned in Los Angeles (UTC−7): each sleep
      // lands one date earlier, clipped at 14:00 there (5h40).
      final scanned = <String, SleepNight?>{
        for (var d = 2; d <= 15; d++)
          key(d): at(
            key(d),
            DateTime.utc(2026, 10, d, 15, 20),
            DateTime.utc(2026, 10, d, 21),
            -420,
          ),
      };
      final changed = SleepProvider.mergeComputed(
        local,
        scanned,
        now: DateTime(2026, 10, 15, 22), // fields = the clock in LA
      );
      expect(changed, isFalse);
      expect(local, before);
      // The first night really slept in LA goes in as usual.
      final firstThere = at(
        key(17),
        DateTime.utc(2026, 10, 17, 6),
        DateTime.utc(2026, 10, 17, 14),
        -420,
      );
      expect(
        SleepProvider.mergeComputed(local, {
          firstThere.date: firstThere,
        }, now: DateTime(2026, 10, 17, 9)),
        isTrue,
      );
      expect(local[firstThere.date], firstThere);
    });

    // This machine's clock at [t], and one 2 hours east of it (a trip), so
    // the cases hold in any zone the tests run in.
    int here(DateTime t) => t.timeZoneOffset.inMinutes;
    int away(DateTime t) => here(t) + 120;

    test('a night on this clock is measured again, even days later', () {
      // Opened the app at 05:00 still in bed, then not for 3 days (Tester
      // round 8: was settled as the 6-hour partial).
      final bed = DateTime(2026, 10, 8, 23);
      final partial = at(key(9), bed, DateTime(2026, 10, 9, 5), here(bed));
      final full = partial.copyWith(
        wakeAt: DateTime(2026, 10, 9, 7, 30),
        wakeUps: [360],
      );
      final local = <String, SleepNight?>{partial.date: partial};
      expect(
        SleepProvider.mergeComputed(local, {
          full.date: full,
        }, now: DateTime(2026, 10, 12, 9)),
        isTrue,
      );
      expect(local[full.date]!.sameAs(full), isTrue);
    });

    test('older than yesterday: a trip night or one saved before 1.9.1 is '
        'settled', () {
      final bed = DateTime(2026, 10, 8, 23);
      final wake = DateTime(2026, 10, 9, 5);
      final trip = at(key(9), bed, wake, away(bed));
      final legacy = SleepNight(
        date: key(9),
        bedAt: bed,
        wakeAt: wake,
        source: SleepSource.auto,
      );
      final longer = trip.copyWith(
        wakeAt: DateTime(2026, 10, 9, 7),
        tz: here(bed),
      );
      for (final stored in [trip, legacy]) {
        final local = <String, SleepNight?>{stored.date: stored};
        expect(
          SleepProvider.mergeComputed(local, {
            longer.date: longer,
          }, now: DateTime(2026, 10, 12, 9)),
          isFalse,
        );
        expect(local[stored.date], same(stored));
      }
      // Yesterday's night from 1.8.0 is still measured again.
      final yesterday = <String, SleepNight?>{legacy.date: legacy};
      expect(
        SleepProvider.mergeComputed(yesterday, {
          longer.date: longer,
        }, now: DateTime(2026, 10, 10, 9)),
        isTrue,
      );
      expect(yesterday[legacy.date]!.sameAs(longer), isTrue);
    });

    test('L1: the night before a flight is not swapped for the sleep on '
        'board', () {
      // Slept 23:00 → 07:00 back home (another clock now), then 13 h with the
      // screen off on the plane: that block lands in the same wake date here.
      final now = DateTime(2026, 10, 16, 10);
      final homeBed = DateTime(2026, 10, 15, 9);
      final home = at(
        key(16),
        homeBed,
        homeBed.add(const Duration(hours: 8)),
        away(homeBed),
      );
      final planeBed = DateTime(2026, 10, 15, 20);
      final plane = at(
        key(16),
        planeBed,
        DateTime(2026, 10, 16, 9),
        here(planeBed),
      );
      final local = <String, SleepNight?>{home.date: home};
      expect(
        SleepProvider.mergeComputed(local, {plane.date: plane}, now: now),
        isFalse,
      );
      expect(local[home.date], same(home));
      // The same sleep scanned again (it ran longer) still updates, on the
      // clock it was slept on.
      final longer = home.copyWith(
        wakeAt: home.wakeAt.add(const Duration(minutes: 40)),
        tz: here(homeBed),
      );
      expect(
        SleepProvider.mergeComputed(local, {longer.date: longer}, now: now),
        isTrue,
      );
      expect(local[home.date]!.wakeAt, longer.wakeAt);
      expect(local[home.date]!.tz, away(homeBed));
      // Same times again, only the zone differs: nothing to change.
      expect(
        SleepProvider.mergeComputed(local, {longer.date: longer}, now: now),
        isFalse,
      );
    });

    test('N-L1: a night from another clock is not cut at the edge of the '
        'window here', () {
      final now = DateTime(2026, 10, 16, 18);
      // Vietnam → Berlin: slept 22:00 → 07:00 at home, 5 h east of here.
      // Here the window opens at 18:00 = 23:00 there: the same sleep comes
      // back an hour short.
      final bed = DateTime(2026, 10, 15, 17); // 22:00 at home
      final home = at(key(16), bed, DateTime(2026, 10, 16, 2), here(bed) + 300);
      final cutStart = at(
        key(16),
        DateTime(2026, 10, 15, 18),
        home.wakeAt,
        here(bed),
      );
      // The other way (home 5 h west): 03:00 → 11:00 there ends at 16:00
      // here, past the window's 14:00 end.
      final lateBed = DateTime(2026, 10, 16, 8); // 03:00 at home
      final west = at(
        key(16),
        lateBed,
        DateTime(2026, 10, 16, 16),
        here(lateBed) - 300,
      );
      final cutEnd = at(
        key(16),
        lateBed,
        DateTime(2026, 10, 16, 14),
        here(lateBed),
      );
      for (final (stored, scanned) in [(home, cutStart), (west, cutEnd)]) {
        final local = <String, SleepNight?>{stored.date: stored};
        expect(
          SleepProvider.mergeComputed(local, {scanned.date: scanned}, now: now),
          isFalse,
        );
        expect(local[stored.date], same(stored));
      }
    });

    test('a phone taken over from another account: older nights are '
        'theirs', () {
      final takeover = DateTime.utc(2026, 10, 9, 13); // 20:00 in Vietnam
      final mine = at(
        key(8),
        DateTime.utc(2026, 10, 7, 16),
        DateTime.utc(2026, 10, 8),
        420,
      );
      final theirs = at(
        key(9),
        DateTime.utc(2026, 10, 8, 16),
        DateTime.utc(2026, 10, 9),
        420,
      );
      final tonight = at(
        key(10),
        DateTime.utc(2026, 10, 9, 16),
        DateTime.utc(2026, 10, 10),
        420,
      );
      final local = <String, SleepNight?>{mine.date: mine};
      expect(
        SleepProvider.mergeComputed(
          local,
          {theirs.date: theirs, tonight.date: tonight},
          now: DateTime(2026, 10, 10, 9),
          notMine: [(from: DateTime.utc(1970), until: takeover)],
        ),
        isTrue,
      );
      expect(local.keys, unorderedEquals([mine.date, tonight.date]));
    });

    test('L3: lending the phone only gives away the nights it was lent', () {
      // Lent from 09:00 to 09:05 on the 10th; B kept it overnight the week
      // before (8th 20:00 → 9th 20:00).
      final notMine = [
        (from: DateTime(2026, 10, 8, 20), until: DateTime(2026, 10, 9, 20)),
        (from: DateTime(2026, 10, 10, 9), until: DateTime(2026, 10, 10, 9, 5)),
      ];
      SleepNight wakingAt(DateTime wake) => SleepNight(
        date: sleepDateKey(wake),
        bedAt: wake.subtract(const Duration(hours: 8)),
        wakeAt: wake,
        source: SleepSource.auto,
      );
      final mineBefore = wakingAt(DateTime(2026, 10, 8, 7));
      final theirs = wakingAt(DateTime(2026, 10, 9, 7));
      final mineLastNight = wakingAt(DateTime(2026, 10, 10, 7));
      final local = <String, SleepNight?>{};
      SleepProvider.mergeComputed(
        local,
        {
          for (final n in [mineBefore, theirs, mineLastNight]) n.date: n,
        },
        now: DateTime(2026, 10, 10, 9, 6),
        notMine: notMine,
      );
      expect(
        local.keys,
        unorderedEquals([mineBefore.date, mineLastNight.date]),
      );
    });
  });

  test('an old night goes up once, then stays frozen', () {
    // Tester N5: sharing on, app killed before the full upload.
    expect(SleepProvider.planSync({old.date: old}, {}, cutoff).pushes, [old]);
    for (final mark in ['pushing', old.fingerprint, 'stale']) {
      expect(
        SleepProvider.planSync(
          {old.date: old},
          {old.date: mark},
          cutoff,
        ).pushes,
        isEmpty,
      );
    }
    expect(
      SleepProvider.planSync({old.date: null}, {old.date: 'x'}, cutoff).deletes,
      isEmpty,
    );
  });
}
