import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/providers/reminder_provider.dart';
import 'package:dear_embeiu/services/reminder_service.dart';

/// The OS side of band 1180–1189: which invite nudges are armed.
class _FakeReminders extends Fake implements ReminderService {
  final armed = <int>{};
  // `shared` of every scheduleInviteFollowUps call.
  final scheduled = <bool>[];
  final entered = Completer<void>();
  Completer<void>? hold;

  @override
  Future<void> scheduleInviteFollowUps({
    required DateTime anchor,
    required bool shared,
    required Map<InviteFollowUp, ({String title, String body})> copy,
  }) async {
    scheduled.add(shared);
    armed.clear();
    if (!entered.isCompleted) {
      entered.complete();
    }
    await hold?.future; // platform calls still in flight
    armed.addAll([
      for (final kind in InviteFollowUp.values)
        if (!shared || kind != InviteFollowUp.after2h) kind.id,
    ]);
  }

  @override
  Future<void> cancelInviteFollowUp(InviteFollowUp kind) async =>
      armed.remove(kind.id);

  @override
  Future<void> cancelInviteFollowUps() async => armed.clear();
}

// Feature pairing-funnel, audit 2026-10-12: PA2 (send during scheduling), PA6
// (send stamp per code), PA-N3 (1.9.0's stamp after an update), PA7 (a couple
// that was active never nudges again).
void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('invite_follow_up').path);
    await Hive.openBox<String>('app_settings');
  });
  setUp(() => Hive.box<String>('app_settings').clear());

  Future<void> refresh(
    ReminderProvider provider, {
    String coupleId = 'c1',
    bool waiting = true,
    DateTime? createdAt,
    List<String?> codes = const ['ABC234', 'PERSO1'],
  }) =>
      provider.refreshInviteFollowUps(
        coupleId: coupleId,
        waiting: waiting,
        coupleCreatedAt: createdAt ?? DateTime.now(),
        inviteCodes: codes,
        l10n: l10n,
      );

  test('PA2: send while the band is being written → no +2h nudge', () async {
    final os = _FakeReminders()..hold = Completer<void>();
    final provider = ReminderProvider(service: os);

    final scheduling = refresh(provider);
    await os.entered.future; // `shared` was false when this started
    await provider.markInviteShared('ABC234');
    os.hold!.complete();
    await scheduling;

    expect(os.scheduled, [false]);
    expect(os.armed, {1181, 1182});
  });

  test('PA6: a send for another account or couple keeps the +2h nudge',
      () async {
    final os = _FakeReminders();
    final provider = ReminderProvider(service: os);

    await provider.markInviteShared('OTHER9'); // someone else's code, just now
    await refresh(provider, codes: ['NEW234', 'PERSO1']);

    expect(os.scheduled, [false]);
    expect(os.armed, contains(1180));
  });

  test('PA6: own personal code sent < 1h before creating the couple counts',
      () async {
    final os = _FakeReminders();
    final provider = ReminderProvider(service: os);

    await provider.markInviteShared('perso1');
    await refresh(
      provider,
      createdAt: DateTime.now().add(const Duration(minutes: 30)),
    );
    expect(os.scheduled, [true]);
    expect(os.armed, {1181, 1182});

    // More than an hour before: an old send, not this couple's.
    await refresh(
      ReminderProvider(service: os),
      coupleId: 'c2',
      createdAt: DateTime.now().add(const Duration(hours: 2)),
    );
    expect(os.scheduled, [true, false]);
  });

  test('PA-N3: a send stamped by 1.9.0 (one key per device) still counts',
      () async {
    final os = _FakeReminders();
    final createdAt = DateTime.now().subtract(const Duration(minutes: 30));
    // Sent on 1.9.0 five minutes after creating the couple, then updated.
    await Hive.box<String>('app_settings').put(
      'invite_shared_at',
      '${createdAt.add(const Duration(minutes: 5)).millisecondsSinceEpoch}',
    );
    await refresh(ReminderProvider(service: os), createdAt: createdAt);
    expect(os.scheduled, [true]);
    expect(os.armed, {1181, 1182});

    // More than an hour before the couple: that send was for something else.
    await refresh(
      ReminderProvider(service: os),
      coupleId: 'c2',
      createdAt: DateTime.now().add(const Duration(hours: 2)),
    );
    expect(os.scheduled, [true, false]);
  });

  test('PA7: once active, the couple never gets invite nudges again',
      () async {
    final os = _FakeReminders()..armed.addAll([1180, 1181, 1182]);
    final provider = ReminderProvider(service: os);

    await refresh(provider, waiting: false);
    expect(os.armed, isEmpty);

    // The partner leaves 5h after the couple was created: waiting again.
    final createdAt = DateTime.now().subtract(const Duration(hours: 5));
    await refresh(provider, createdAt: createdAt);
    // Next launch (new process), same couple.
    os.armed.add(1181);
    await refresh(ReminderProvider(service: os), createdAt: createdAt);
    expect(os.scheduled, isEmpty);
    expect(os.armed, isEmpty);

    // A couple that never had both members still gets them.
    await refresh(ReminderProvider(service: os), coupleId: 'c9');
    expect(os.scheduled, [false]);
  });
}
