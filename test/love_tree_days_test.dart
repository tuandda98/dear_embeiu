import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/services/love_tree_service.dart';

/// Days together — the count behind the Home counter, Profile, the guest
/// counter and the Love Tree (audit vòng 9): calendar days, so a DST change
/// costs no day.
void main() {
  test('counts calendar days from the anniversary, never below 0', () {
    final now = DateTime(2026, 10, 12, 0, 30);
    int days(DateTime anniversary) =>
        LoveTreeService.daysTogether(anniversary, now: now);
    expect(days(DateTime(2026, 10, 12)), 0); // the first day
    expect(days(DateTime(2026, 10, 11, 23, 59)), 1); // the hour doesn't count
    expect(days(DateTime(2025, 10, 12)), 365);
    expect(days(DateTime(2026, 10, 13)), 0); // not yet: 0, not -1
  });

  test('a DST change costs no day (run with TZ=Europe/Berlin or '
      'America/New_York)', () {
    // The first day (within a year from 2026-01-01) whose local midnight is
    // only 23 h before the next one: clocks went forward that night.
    DateTime? spring;
    for (var i = 0; i < 366 && spring == null; i++) {
      final d = DateTime(2026, 1, 1 + i);
      if (DateTime(d.year, d.month, d.day + 1).difference(d).inHours < 24) {
        spring = d;
      }
    }
    if (spring == null) {
      markTestSkipped('No DST in this time zone.');
      return;
    }
    final d = spring;
    DateTime on(int day, [int hour = 9]) =>
        DateTime(d.year, d.month, d.day + day, hour);
    // Together since the day the clocks went forward (29/3 in Berlin): the
    // next day is day 1, not "first day" again — and all summer long.
    expect(LoveTreeService.daysTogether(on(0, 0), now: on(1)), 1);
    expect(LoveTreeService.daysTogether(on(0, 0), now: on(100)), 100);
    // Together since winter, counted in summer: no day lost either.
    expect(LoveTreeService.daysTogether(on(-30, 0), now: on(1, 0)), 31);
  });
}
