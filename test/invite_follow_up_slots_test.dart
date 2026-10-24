import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/services/reminder_service.dart';

// PF10 (feature pairing-funnel): invite follow-ups at +2h (only while the code
// hasn't been sent), +20h and +72h; night slots move to 08:30; nothing for an
// old couple. All times are local wall-clock (no DST change in 12–16 Oct).
void main() {
  // 2026-10-12 is a Monday.
  final monday14 = DateTime(2026, 10, 12, 14);

  List<DateTime> times({
    required DateTime anchor,
    DateTime? now,
    bool shared = false,
  }) =>
      ReminderService.inviteFollowUpSlots(
        anchor: anchor,
        now: now ?? anchor,
        shared: shared,
      ).map((s) => s.when).toList();

  test('created 14:00 Monday, code not sent → 16:00 Mon, 10:00 Tue, 14:00 Thu',
      () {
    expect(monday14.weekday, DateTime.monday);
    final slots = ReminderService.inviteFollowUpSlots(
      anchor: monday14,
      now: monday14,
      shared: false,
    );
    expect(slots.map((s) => s.when).toList(), [
      DateTime(2026, 10, 12, 16),
      DateTime(2026, 10, 13, 10),
      DateTime(2026, 10, 15, 14),
    ]);
    // Fixed ids: markInviteShared cancels exactly the +2h one (1180).
    expect(slots.map((s) => s.kind.id).toList(), [1180, 1181, 1182]);
  });

  test('code already sent → no 16:00 nudge', () {
    expect(times(anchor: monday14, shared: true), [
      DateTime(2026, 10, 13, 10),
      DateTime(2026, 10, 15, 14),
    ]);
  });

  test('slots already in the past are dropped', () {
    expect(
      times(anchor: monday14, now: DateTime(2026, 10, 12, 17)),
      [DateTime(2026, 10, 13, 10), DateTime(2026, 10, 15, 14)],
    );
  });

  test('couple created 8 days ago → nothing, no catch-up ping', () {
    expect(
      times(
        anchor: monday14.subtract(const Duration(days: 8)),
        now: monday14,
      ),
      isEmpty,
    );
  });

  test('created 21:00 → the +2h slot (23:00) moves to 08:30 next morning', () {
    expect(times(anchor: DateTime(2026, 10, 12, 21)), [
      DateTime(2026, 10, 13, 8, 30),
      DateTime(2026, 10, 13, 17),
      DateTime(2026, 10, 15, 21),
    ]);
  });

  test('created 01:00 → the +2h slot (03:00) moves to 08:30 the same morning',
      () {
    expect(times(anchor: DateTime(2026, 10, 12, 1)), [
      DateTime(2026, 10, 12, 8, 30),
      DateTime(2026, 10, 12, 21),
      DateTime(2026, 10, 15, 8, 30),
    ]);
  });

  test('a night slot still pending after its raw time keeps its 08:30', () {
    // +2h was 23:00; opened at 23:30 → it now fires at 08:30, not dropped.
    expect(
      times(
        anchor: DateTime(2026, 10, 12, 21),
        now: DateTime(2026, 10, 12, 23, 30),
      ).first,
      DateTime(2026, 10, 13, 8, 30),
    );
  });
}
