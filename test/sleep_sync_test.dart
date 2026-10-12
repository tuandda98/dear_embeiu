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
