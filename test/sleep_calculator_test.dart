import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/sleep_night.dart';
import 'package:dear_embeiu/theme/person_palette.dart';
import 'package:dear_embeiu/utils/sleep_calculator.dart';

// Wake date used by most cases: the night of 9 → morning of 10 Oct 2026.
final DateTime wake = DateTime(2026, 10, 10);
DateTime at(int day, int h, [int m = 0, int s = 0]) =>
    DateTime(2026, 10, day, h, m, s);
ScreenEvent off(DateTime t) => ScreenEvent(t, on: false);
ScreenEvent on(DateTime t) => ScreenEvent(t, on: true);

/// Runs the screen pipeline for [wake] with coverage starting at 08:00 the day
/// before (so the window is complete) and "now" = noon on the wake day.
SleepNight? screenNight(List<ScreenEvent> events, {DateTime? now}) {
  final all = [on(at(9, 8)), ...events];
  return computeScreenNights(
    all,
    wakeDates: [wake],
    now: now ?? at(10, 12),
  )['2026-10-10'];
}

void main() {
  group('screen events → night', () {
    test('crosses midnight', () {
      final n = screenNight([off(at(9, 23, 40)), on(at(10, 6, 55))])!;
      expect(n.date, '2026-10-10');
      expect(n.bedAt, at(9, 23, 40));
      expect(n.wakeAt, at(10, 6, 55));
      expect(n.minutes, 7 * 60 + 15);
      expect(n.wakeUps, isEmpty);
      expect(n.source, SleepSource.auto);
    });

    test('a pickup ≤ 5 min stays in the sleep and counts as waking up', () {
      final n = screenNight([
        off(at(9, 23)),
        on(at(10, 2)),
        off(at(10, 2, 2)),
        on(at(10, 7)),
      ])!;
      expect(n.bedAt, at(9, 23));
      expect(n.wakeAt, at(10, 7));
      expect(n.wakeUps, [180]);
    });

    test('a screen lit for a few seconds is folded in without counting', () {
      final n = screenNight([
        off(at(9, 23)),
        on(at(10, 3)),
        off(at(10, 3, 0, 8)),
        on(at(10, 7)),
      ])!;
      expect(n.wakeUps, isEmpty);
      expect(n.minutes, 8 * 60);
    });

    test('several awakenings are all recorded', () {
      final n = screenNight([
        off(at(9, 23)),
        on(at(10, 1)),
        off(at(10, 1, 1)),
        on(at(10, 3)),
        off(at(10, 3, 4)),
        on(at(10, 5)),
        off(at(10, 5, 3)),
        on(at(10, 7)),
      ])!;
      expect(n.wakeUps, [120, 240, 360]);
      expect(n.wakeAt, at(10, 7));
    });

    test(
      'an interruption > 5 min splits the night; the longest block wins',
      () {
        final n = screenNight([
          off(at(9, 22)),
          on(at(10, 1)),
          off(at(10, 1, 30)),
          on(at(10, 7, 30)),
        ])!;
        expect(n.bedAt, at(10, 1, 30));
        expect(n.wakeAt, at(10, 7, 30));
      },
    );

    test('no block of 3 hours → no night (never invented)', () {
      final n = screenNight([
        off(at(9, 23)),
        on(at(10, 1)),
        off(at(10, 1, 30)),
        on(at(10, 3, 30)),
      ]);
      expect(n, isNull);
    });

    test('repeated "off" events (always-on display) are harmless', () {
      final n = screenNight([
        off(at(9, 23)),
        off(at(9, 23, 30)),
        on(at(10, 6)),
      ])!;
      expect(n.bedAt, at(9, 23));
      expect(n.wakeAt, at(10, 6));
    });

    test('rest is clipped to the 18:00 → 14:00 window', () {
      final n = screenNight([off(at(9, 16)), on(at(10, 7))])!;
      expect(n.bedAt, at(9, 18));
      expect(n.wakeAt, at(10, 7));
    });

    test('a night still in progress ends at "now"', () {
      final n = screenNight([off(at(9, 23))], now: at(10, 5))!;
      expect(n.wakeAt, at(10, 5));
      expect(n.minutes, 6 * 60);
    });

    test('a window older than the first event is left out (incomplete)', () {
      final result = computeScreenNights(
        [off(at(9, 23)), on(at(10, 7))],
        wakeDates: [wake],
        now: at(10, 12),
      );
      expect(result.containsKey('2026-10-10'), isFalse);
    });

    test('a complete window without sleep maps to null', () {
      final result = computeScreenNights(
        [on(at(9, 8)), off(at(9, 22)), on(at(9, 23))],
        wakeDates: [wake],
        now: at(10, 12),
      );
      expect(result.containsKey('2026-10-10'), isTrue);
      expect(result['2026-10-10'], isNull);
    });
  });

  group('edge cases (Tester round 1)', () {
    test('a phone left alone 18:00 → 14:00 is not a 20-hour night', () {
      final n = screenNight([off(at(9, 17)), on(at(10, 15))]);
      expect(n, isNull);
    });

    test('an idle evening does not beat a night cut by a 6-minute pickup', () {
      final n = screenNight([
        off(at(9, 18)),
        on(at(9, 22, 30)),
        off(at(10, 0, 30)),
        on(at(10, 3)),
        off(at(10, 3, 6)),
        on(at(10, 7)),
      ])!;
      expect(n.bedAt, at(10, 3, 6));
      expect(n.wakeAt, at(10, 7));
    });

    test('night shift (no block in 00:00–05:00) keeps the longest block', () {
      final n = screenNight([
        off(at(9, 19)),
        on(at(9, 22, 30)),
        off(at(10, 6)),
        on(at(10, 13)),
      ], now: at(10, 13, 30))!;
      expect(n.bedAt, at(10, 6));
      expect(n.wakeAt, at(10, 13));
    });

    test('Health: a short evening "asleep" falls back to "in bed"', () {
      final r = computeHealthNights(
        [
          HealthSleepSample(at(9, 19), at(9, 19, 20), 3),
          HealthSleepSample(at(9, 23), at(10, 7), 0),
        ],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(r.bedAt, at(9, 23));
      expect(r.wakeAt, at(10, 7));
    });
  });

  group('edge cases (Tester round 2)', () {
    test('night shift: a phone idle in a locker loses to the day sleep', () {
      final n = screenNight([
        off(at(9, 23)),
        on(at(10, 3, 30)),
        off(at(10, 7)),
        on(at(10, 14)),
      ], now: at(10, 14, 30))!;
      expect(n.bedAt, at(10, 7));
      expect(n.wakeAt, at(10, 14));
    });

    test('an evening ending just past midnight loses to the night after', () {
      final n = screenNight([
        off(at(9, 18, 30)),
        on(at(10, 0, 15)),
        off(at(10, 0, 40)),
        on(at(10, 6)),
      ])!;
      expect(n.bedAt, at(10, 0, 40));
      expect(n.wakeAt, at(10, 6));
    });

    test('a flat battery across the night is no night, not 15 hours', () {
      expect(screenNight([off(at(9, 16)), on(at(10, 9, 30))]), isNull);
    });

    test('a forgotten phone does not turn the late morning into a night', () {
      final n = screenNight([
        off(at(9, 18)),
        on(at(10, 10, 30)),
        off(at(10, 10, 40)),
        on(at(10, 15)),
      ], now: at(10, 15, 30));
      expect(n, isNull);
    });

    test('a phone forgotten the day before does not void tonight', () {
      final n = computeScreenNights(
        [off(at(8, 14)), on(at(9, 22)), off(at(9, 23, 30)), on(at(10, 7))],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(n.bedAt, at(9, 23, 30));
      expect(n.wakeAt, at(10, 7));
    });

    test('Health: an evening nap loses to a whole night in bed', () {
      final r = computeHealthNights(
        [
          HealthSleepSample(at(9, 19), at(9, 22, 10), 3),
          HealthSleepSample(at(9, 23), at(10, 7), 0),
        ],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(r.bedAt, at(9, 23));
      expect(r.wakeAt, at(10, 7));
    });
  });

  group('edge cases (Tester round 3)', () {
    test('a phone flat until 00:30 does not void the night after it', () {
      final n = screenNight([
        off(at(9, 8, 1)),
        on(at(10, 0, 30)),
        off(at(10, 0, 45)),
        on(at(10, 7, 30)),
      ])!;
      expect(n.bedAt, at(10, 0, 45));
      expect(n.wakeAt, at(10, 7, 30));
    });

    test('a phone left home from 05:00 keeps the night before it', () {
      final n = screenNight([
        off(at(9, 23)),
        on(at(10, 4, 30)),
        off(at(10, 4, 59)),
        on(at(10, 21, 1)),
      ], now: at(10, 21, 30))!;
      expect(n.bedAt, at(9, 23));
      expect(n.wakeAt, at(10, 4, 30));
    });

    test('idle since the afternoon + a look at 03:00 keeps the morning', () {
      final n = screenNight([
        off(at(9, 16)),
        on(at(10, 3)),
        off(at(10, 3, 2)),
        on(at(10, 7)),
      ])!;
      expect(n.bedAt, at(9, 18));
      expect(n.wakeAt, at(10, 7));
      expect(n.wakeUps, [9 * 60]);
    });

    test('idle since the afternoon + a 3-minute look is not a 13h night', () {
      final n = screenNight([
        off(at(9, 15)),
        on(at(9, 23, 20)),
        off(at(9, 23, 23)),
        on(at(10, 7)),
      ])!;
      expect(n.bedAt, at(9, 23, 23));
      expect(n.wakeAt, at(10, 7));
    });
  });

  group('Apple Health → night', () {
    test('awake gaps up to 30 min are awakenings inside one night', () {
      final r = computeHealthNights(
        [
          HealthSleepSample(at(9, 23, 10), at(10, 2), 3),
          HealthSleepSample(at(10, 2), at(10, 2, 12), 2), // awake
          HealthSleepSample(at(10, 2, 12), at(10, 6, 40), 4),
        ],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(r.bedAt, at(9, 23, 10));
      expect(r.wakeAt, at(10, 6, 40));
      expect(r.wakeUps, [170]);
      expect(r.source, SleepSource.health);
    });

    test('falls back to "in bed" when no asleep sample exists', () {
      final r = computeHealthNights(
        [HealthSleepSample(at(9, 23), at(10, 6, 30), 0)],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(r.minutes, 7 * 60 + 30);
    });

    test('overlapping samples from two sources are merged', () {
      final r = computeHealthNights(
        [
          HealthSleepSample(at(9, 23), at(10, 4), 1),
          HealthSleepSample(at(10, 3), at(10, 7), 1),
        ],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(r.bedAt, at(9, 23));
      expect(r.wakeAt, at(10, 7));
      expect(r.wakeUps, isEmpty);
    });
  });

  group('helpers', () {
    test('circular mean of bedtimes around midnight', () {
      expect(circularMeanMinute([23 * 60 + 50, 10]), 0);
      expect(circularMeanMinute([60, 120]), 90);
      expect(circularMeanMinute([23 * 60 + 30, 30]), 0);
    });

    test('moon phase thresholds', () {
      expect(sleepPhaseFor(299), 0);
      expect(sleepPhaseFor(300), 1);
      expect(sleepPhaseFor(360), 2);
      expect(sleepPhaseFor(420), 3);
      expect(sleepPhaseFor(479), 3);
      expect(sleepPhaseFor(480), 4);
    });

    test('edit window: today and the 6 days before', () {
      final now = DateTime(2026, 10, 10, 9);
      expect(sleepNightEditable('2026-10-10', now: now), isTrue);
      expect(sleepNightEditable('2026-10-04', now: now), isTrue);
      expect(sleepNightEditable('2026-10-03', now: now), isFalse);
      expect(sleepNightEditable('2026-10-11', now: now), isFalse);
    });

    test('overlap + together stats', () {
      final mine = {
        '2026-10-10': SleepNight(
          date: '2026-10-10',
          bedAt: at(9, 23),
          wakeAt: at(10, 7),
          source: SleepSource.auto,
        ),
        '2026-10-09': SleepNight(
          date: '2026-10-09',
          bedAt: at(8, 23),
          wakeAt: at(9, 6),
          source: SleepSource.auto,
        ),
      };
      final partner = {
        '2026-10-10': SleepNight(
          date: '2026-10-10',
          bedAt: at(9, 23, 30),
          wakeAt: at(10, 7, 30),
          source: SleepSource.edited,
        ),
        '2026-10-09': SleepNight(
          date: '2026-10-09',
          bedAt: at(9, 1),
          wakeAt: at(9, 8),
          source: SleepSource.auto,
        ),
      };
      expect(mine['2026-10-10']!.overlapWith(partner['2026-10-10']!), 450);
      final t = sleepTogetherStats(mine, partner, (_) => true)!;
      expect(t.heartNights, 1);
      expect(t.avgOverlap, ((450 + 300) / 2).round());
    });

    test('month stats count full nights and average around midnight', () {
      final s = sleepMonthStats([
        SleepNight(
          date: '2026-10-10',
          bedAt: at(9, 23, 50),
          wakeAt: at(10, 8),
          source: SleepSource.auto,
        ),
        SleepNight(
          date: '2026-10-11',
          bedAt: at(11, 0, 10),
          wakeAt: at(11, 6, 10),
          source: SleepSource.auto,
        ),
      ])!;
      expect(s.nights, 2);
      expect(s.fullNights, 1);
      expect(s.avgBedMinute, 0);
      expect(s.avgMinutes, ((490 + 360) / 2).round());
    });
  });

  group('audit 2026-10-12', () {
    test('SL3: asleep stretches inside one "in bed" block are one night', () {
      // Watch: asleep 23:30–03:00, awake 45 min, asleep 03:45–07:00; iPhone
      // "in bed" 23:00–07:15. Was 23:30 → 03:00, i.e. "woke up at 03:00".
      final r = computeHealthNights(
        [
          HealthSleepSample(at(9, 23, 30), at(10, 3), 3),
          HealthSleepSample(at(10, 3), at(10, 3, 45), 2),
          HealthSleepSample(at(10, 3, 45), at(10, 7), 4),
          HealthSleepSample(at(9, 23), at(10, 7, 15), 0),
        ],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(r.bedAt, at(9, 23, 30));
      expect(r.wakeAt, at(10, 7));
      expect(r.wakeUps, [210]);
    });

    test('SL3: without "in bed" a long awake gap still splits the night', () {
      final r = computeHealthNights(
        [
          HealthSleepSample(at(9, 23), at(10, 2), 3),
          HealthSleepSample(at(10, 2, 35), at(10, 5, 25), 3),
        ],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(r.bedAt, at(9, 23));
      expect(r.wakeAt, at(10, 2));
    });

    test('L2: 2.5 h awake in bed splits the night, it is no full moon', () {
      // Insomnia 02:00 → 04:30 inside "in bed" 22:45 → 07:15: was folded
      // into 23:00 → 07:00, an 8-hour full moon.
      final r = computeHealthNights(
        [
          HealthSleepSample(at(9, 22, 45), at(10, 7, 15), 0),
          HealthSleepSample(at(9, 23), at(10, 2), 3),
          HealthSleepSample(at(10, 4, 30), at(10, 7), 3),
        ],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect(r.bedAt, at(9, 23));
      expect(r.wakeAt, at(10, 2));
      expect(r.isFull, isFalse);
      // 90 minutes awake is still one night.
      final ninety = computeHealthNights(
        [
          HealthSleepSample(at(9, 22, 45), at(10, 7, 15), 0),
          HealthSleepSample(at(9, 23), at(10, 2), 3),
          HealthSleepSample(at(10, 3, 30), at(10, 7), 3),
        ],
        wakeDates: [wake],
        now: at(10, 12),
      )['2026-10-10']!;
      expect([ninety.bedAt, ninety.wakeAt], [at(9, 23), at(10, 7)]);
      expect(ninety.wakeUps, [180]);
    });

    test('L2: a day in bed (over 16 h) still finds the night', () {
      // Sick: "in bed" for 2 days, dozes never more than 80 min apart, so
      // they chain into one 17.5-hour block — the whole night was lost.
      final r = computeHealthNights(
        [
          HealthSleepSample(at(9, 12), at(11, 12), 0),
          HealthSleepSample(at(9, 18, 30), at(9, 21), 3),
          HealthSleepSample(at(9, 22), at(10, 6), 4),
          HealthSleepSample(at(10, 7, 20), at(10, 9), 3),
          HealthSleepSample(at(10, 10), at(10, 12), 3),
        ],
        wakeDates: [wake],
        now: at(10, 13),
      )['2026-10-10'];
      expect(r, isNotNull);
      expect([r!.bedAt, r.wakeAt], [at(9, 22), at(10, 6)]);
    });

    test('SL4: before 04:00 tonight is neither scanned nor published', () {
      expect(recentWakeDates(at(11, 3, 59), 2).map(sleepDateKey), [
        '2026-10-09',
        '2026-10-10',
      ]);
      expect(recentWakeDates(at(11, 4), 2).map(sleepDateKey), [
        '2026-10-10',
        '2026-10-11',
      ]);
      // Asleep from 23:00, a push opened at 02:00: no "3-hour night" today.
      final now = at(11, 2, 1);
      final r = computeScreenNights(
        [on(at(9, 8)), off(at(10, 23)), on(at(11, 2))],
        wakeDates: recentWakeDates(now, 2),
        now: now,
      );
      expect(r.containsKey('2026-10-11'), isFalse);
      expect(sleepDateKey(lastWakeDate(now)), '2026-10-10');
    });

    test('SL6: the edit window counts calendar days across DST', () {
      // US clocks spring forward on 8 Mar 2026, EU ones on 29 Mar: there,
      // 7 calendar days are 167 hours. (Bites when run in such a zone.)
      for (final (now, lastDay, tooOld) in [
        (DateTime(2026, 3, 14, 10), '2026-03-08', '2026-03-07'),
        (DateTime(2026, 4, 4, 10), '2026-03-29', '2026-03-28'),
      ]) {
        expect(sleepNightEditable(lastDay, now: now), isTrue);
        expect(sleepNightEditable(tooOld, now: now), isFalse);
      }
    });

    test('SL8: a computed night keeps the clock it happened on', () {
      final n = screenNight([off(at(9, 23)), on(at(10, 7))])!;
      expect(n.tz, at(9, 23).timeZoneOffset.inMinutes);
      expect(n.bedClock.hour, 23);
      expect(n.wakeClock.hour, 7);
    });

    test('SL8: own clock across a DST change, fixed offset abroad', () {
      final bed = DateTime(2026, 3, 7, 23);
      final night = SleepNight(
        date: '2026-03-08',
        bedAt: bed,
        wakeAt: DateTime(2026, 3, 8, 7),
        source: SleepSource.manual,
        tz: bed.timeZoneOffset.inMinutes,
      );
      // One offset can't hold 23:00 PST and 07:00 PDT: read in local time.
      expect(night.bedClock.hour, 23);
      expect(night.wakeClock.hour, 7);
      // A partner in New York (UTC−4), 23:00 → 07:00 on their clock.
      final away = SleepNight(
        date: '2026-10-11',
        bedAt: DateTime.utc(2026, 10, 11, 3),
        wakeAt: DateTime.utc(2026, 10, 11, 11),
        source: SleepSource.auto,
        tz: -240,
      );
      expect(away.bedClock.hour, 23);
      expect(away.wakeClock.hour, 7);
      expect(away.wakeClock.day, 11);
    });

    test("R2-b: month stats read bed/wake times on each night's clock", () {
      // A partner in New York (UTC−4), 22:30 → 06:30 there. A phone in
      // Vietnam said "Ngủ ~9:30 · Dậy ~17:30". (Bites outside UTC−4.)
      final s = sleepMonthStats([
        for (final day in [10, 11])
          SleepNight(
            date: '2026-10-$day',
            // Local DateTimes, as Hive and Firestore hand them back.
            bedAt: DateTime.utc(2026, 10, day, 2, 30).toLocal(),
            wakeAt: DateTime.utc(2026, 10, day, 10, 30).toLocal(),
            source: SleepSource.auto,
            tz: -240,
          ),
      ])!;
      expect(s.avgBedMinute, 22 * 60 + 30);
      expect(s.avgWakeMinute, 6 * 60 + 30);
      expect(s.avgMinutes, 8 * 60); // real time asleep
    });

    test('SL10: nobody picked yet → both phones draw the same colours', () {
      final forA = PersonPalette.resolve(
        myUid: 'a',
        myChoice: null,
        partnerUid: 'b',
        partnerChoice: null,
      );
      final forB = PersonPalette.resolve(
        myUid: 'b',
        myChoice: null,
        partnerUid: 'a',
        partnerChoice: null,
      );
      expect(forA.mine, forB.partner);
      expect(forA.partner, forB.mine);
      expect(PersonPalette.clashes(forA.mine, forA.partner), isFalse);
    });
  });

  group('person palette', () {
    test('defaults: first = rose, second = purple', () {
      final r = PersonPalette.resolve(
        myUid: 'a',
        myChoice: null,
        partnerUid: 'b',
        partnerChoice: 'rose',
      );
      expect(r.mine, 'purple');
      expect(r.partner, 'rose');
    });

    test('C1: on a clash only the uid sorting after is adjusted', () {
      final forA = PersonPalette.resolve(
        myUid: 'a',
        myChoice: 'purple',
        partnerUid: 'b',
        partnerChoice: 'blue',
      );
      final forB = PersonPalette.resolve(
        myUid: 'b',
        myChoice: 'blue',
        partnerUid: 'a',
        partnerChoice: 'purple',
      );
      // Both phones agree: A keeps purple, B shows the first free colour.
      expect(forA.mine, 'purple');
      expect(forA.partner, forB.mine);
      expect(forB.partner, 'purple');
      expect(forB.mineAdjusted, isTrue);
      expect(PersonPalette.clashes(forB.mine, 'purple'), isFalse);
    });

    test('every colour leaves at least 5 choices to the partner', () {
      for (final id in PersonPalette.ids) {
        final free = PersonPalette.ids
            .where((c) => !PersonPalette.clashes(c, id))
            .length;
        expect(free, greaterThanOrEqualTo(5), reason: id);
      }
    });
  });

  group('motion fallback → night', () {
    Map<String, SleepNight?> motion(
      List<RestSpan> still, {
      DateTime? coverage,
      DateTime? now,
    }) => computeMotionNights(
      still,
      wakeDates: [wake],
      now: now ?? at(10, 14, 30),
      coverageStart: coverage ?? at(3, 0),
    );

    test('a 5-min pickup in the night is one wake-up, source auto', () {
      final n = motion([
        RestSpan(at(9, 23, 30), at(10, 2, 10)),
        RestSpan(at(10, 2, 15), at(10, 6, 40)),
      ])['2026-10-10']!;
      expect(n.bedAt, at(9, 23, 30));
      expect(n.wakeAt, at(10, 6, 40));
      expect(n.wakeUps, [160]);
      expect(n.source, SleepSource.auto);
    });

    test('F3: night 01:00–06:00 wins over the desk 08:30–14:00', () {
      final n = motion([
        RestSpan(at(10, 1), at(10, 6)),
        RestSpan(at(10, 8, 30), at(10, 14)),
      ])['2026-10-10']!;
      expect(n.bedAt, at(10, 1));
      expect(n.wakeAt, at(10, 6));
    });

    test('F3: only the desk 08:30–14:00 is no night', () {
      expect(
        motion([RestSpan(at(10, 8, 30), at(10, 14))])['2026-10-10'],
        isNull,
      );
    });

    test('F3: a block reaching < 60 min into 00:00–06:00 is no night', () {
      expect(
        motion([RestSpan(at(9, 20), at(10, 0, 50))])['2026-10-10'],
        isNull,
      );
    });

    test('F2: morning 09:35–13:50 right after turning it on → no night', () {
      final out = motion([
        RestSpan(at(10, 9, 35), at(10, 13, 50)),
      ], coverage: at(10, 9, 30));
      expect(out['2026-10-10'], isNull);
    });

    test('R2-C: set up at 21:00, slept 23:00–06:40 → that night counts', () {
      final n = motion([
        RestSpan(at(9, 23), at(10, 6, 40)),
      ], coverage: at(9, 21))['2026-10-10']!;
      expect(n.bedAt, at(9, 23));
      expect(n.wakeAt, at(10, 6, 40));
    });

    test('R2-C: a span starting at the data edge is dropped', () {
      expect(
        motion([
          RestSpan(at(9, 21), at(10, 6, 40)),
        ], coverage: at(9, 21))['2026-10-10'],
        isNull,
      );
    });

    test('F2: no coverage (0 from the channel) → no nights at all', () {
      final out = computeMotionNights(
        [RestSpan(at(9, 23), at(10, 7))],
        wakeDates: [wake],
        now: at(10, 12),
        coverageStart: null,
      );
      expect(out, isEmpty);
    });

    test('a phone still on the desk all afternoon is not a night', () {
      expect(
        motion([RestSpan(at(9, 13), at(9, 17, 30))])['2026-10-10'],
        isNull,
      );
    });
  });
}
