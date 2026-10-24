import 'package:flutter/foundation.dart';

import 'custom_reminder.dart';

/// A scheduled reminder one partner set FOR the other (feature partner-nudge,
/// 2026-06-29).
///
/// Stored in Firestore at `couples/{coupleId}/partnerReminders/{id}` and synced
/// to the recipient's device, which arms a LOCAL notification (band 3000–3049)
/// so it fires in the recipient's own timezone. [authorUserId] owns the doc
/// (only the author may edit/delete); the OTHER member is the one who gets
/// reminded.
///
/// [minuteOfDay] is wall-clock minutes-since-midnight (0..1439) — timezone-free
/// on purpose so each device interprets it in its own local time.
@immutable
class PartnerReminder {
  const PartnerReminder({
    required this.id,
    required this.authorUserId,
    required this.text,
    required this.minuteOfDay,
    required this.recurrence,
    required this.date,
    this.enabled = true,
  });

  /// Firestore document id. Empty for a not-yet-persisted draft.
  final String id;

  /// Uid of the member who CREATED the reminder (owns the doc).
  final String authorUserId;

  /// What to remind about — a chip preset or free text (≤200, rule-enforced).
  final String text;

  /// Wall-clock minutes since midnight (0..1439).
  final int minuteOfDay;

  final ReminderRecurrence recurrence;

  /// Anchor day (matters for once/weekly/monthly/yearly cycles).
  final DateTime date;

  final bool enabled;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;

  PartnerReminder copyWith({
    String? id,
    String? authorUserId,
    String? text,
    int? minuteOfDay,
    ReminderRecurrence? recurrence,
    DateTime? date,
    bool? enabled,
  }) {
    return PartnerReminder(
      id: id ?? this.id,
      authorUserId: authorUserId ?? this.authorUserId,
      text: text ?? this.text,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      recurrence: recurrence ?? this.recurrence,
      date: date ?? this.date,
      enabled: enabled ?? this.enabled,
    );
  }

  /// The fields written to Firestore on create/update. `createdAt` is added by
  /// the service (serverTimestamp); not included here.
  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'authorUserId': authorUserId,
      'text': text,
      'minuteOfDay': minuteOfDay,
      'recurrence': recurrence.storageKey,
      'dateMillis': date.millisecondsSinceEpoch,
      'enabled': enabled,
    };
  }

  static PartnerReminder fromMap(String id, Map<dynamic, dynamic> map) {
    final rawMinute = (map['minuteOfDay'] as num?)?.toInt() ?? 0;
    final clamped = rawMinute < 0
        ? 0
        : rawMinute > 1439
            ? 1439
            : rawMinute;
    final millis = (map['dateMillis'] as num?)?.toInt();
    return PartnerReminder(
      id: id,
      authorUserId: (map['authorUserId'] as String?)?.trim() ?? '',
      text: (map['text'] as String?) ?? '',
      minuteOfDay: clamped,
      recurrence: ReminderRecurrenceCodec.fromStorageKey(
        map['recurrence'] as String?,
      ),
      date: millis != null
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : DateTime.now(),
      enabled: (map['enabled'] as bool?) ?? true,
    );
  }

  /// A transient [CustomReminder] used purely to drive [ReminderService]'s
  /// scheduling math (next-fire + recurrence components). Its id is irrelevant
  /// — the service assigns the real band id.
  CustomReminder toScheduleReminder() {
    return CustomReminder(
      id: 0,
      name: text,
      date: date,
      hour: hour,
      minute: minute,
      recurrence: recurrence,
      enabled: enabled,
    );
  }
}
