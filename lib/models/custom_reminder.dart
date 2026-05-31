import 'package:flutter/foundation.dart';

/// How a custom reminder repeats.
///
/// Each value maps to a `DateTimeComponents` matcher in [ReminderService] so
/// the OS reschedules the notification on the right cadence.
enum ReminderRecurrence { once, daily, weekly, monthly, yearly }

extension ReminderRecurrenceCodec on ReminderRecurrence {
  /// Stable string key for persistence (never depend on enum index ordering
  /// across refactors).
  String get storageKey {
    switch (this) {
      case ReminderRecurrence.once:
        return 'once';
      case ReminderRecurrence.daily:
        return 'daily';
      case ReminderRecurrence.weekly:
        return 'weekly';
      case ReminderRecurrence.monthly:
        return 'monthly';
      case ReminderRecurrence.yearly:
        return 'yearly';
    }
  }

  static ReminderRecurrence fromStorageKey(String? key) {
    switch (key) {
      case 'daily':
        return ReminderRecurrence.daily;
      case 'weekly':
        return ReminderRecurrence.weekly;
      case 'monthly':
        return ReminderRecurrence.monthly;
      case 'yearly':
        return ReminderRecurrence.yearly;
      case 'once':
      default:
        return ReminderRecurrence.once;
    }
  }
}

/// A user-created, local-only reminder (birthday, monthsary, special day…).
///
/// Persisted manually as a JSON-able map in the `custom_reminders` Hive box —
/// no Hive TypeAdapter/codegen, which keeps the launch path free of adapter
/// registration. [id] doubles as the local-notification id and stays in the
/// 2000–2999 range reserved for custom reminders (decision D6).
@immutable
class CustomReminder {
  const CustomReminder({
    required this.id,
    required this.name,
    this.note,
    required this.date,
    required this.hour,
    required this.minute,
    required this.recurrence,
    this.enabled = true,
  });

  /// Notification id in the reserved 2000–2999 band (D6).
  final int id;

  /// Title of the notification. Required (D4).
  final String name;

  /// Optional body of the notification (D4). When null/empty a localized
  /// fallback is used at schedule time.
  final String? note;

  /// The anchor day the user picked. For repeating reminders only the
  /// day/month parts may matter, but the full date is kept so an edit can
  /// re-derive everything.
  final DateTime date;

  final int hour;
  final int minute;

  final ReminderRecurrence recurrence;

  final bool enabled;

  CustomReminder copyWith({
    int? id,
    String? name,
    String? note,
    bool clearNote = false,
    DateTime? date,
    int? hour,
    int? minute,
    ReminderRecurrence? recurrence,
    bool? enabled,
  }) {
    return CustomReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      note: clearNote ? null : (note ?? this.note),
      date: date ?? this.date,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      recurrence: recurrence ?? this.recurrence,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'note': note,
      // Store as epoch millis (UTC-agnostic local wall clock day) — robust and
      // JSON-able. Only the calendar day matters; hour/minute are separate.
      'dateMillis': date.millisecondsSinceEpoch,
      'hour': hour,
      'minute': minute,
      'recurrence': recurrence.storageKey,
      'enabled': enabled,
    };
  }

  static CustomReminder fromMap(Map<dynamic, dynamic> map) {
    final rawNote = map['note'] as String?;
    return CustomReminder(
      id: (map['id'] as num).toInt(),
      name: (map['name'] as String?) ?? '',
      note: (rawNote != null && rawNote.isNotEmpty) ? rawNote : null,
      date: DateTime.fromMillisecondsSinceEpoch(
        (map['dateMillis'] as num).toInt(),
      ),
      hour: (map['hour'] as num?)?.toInt() ?? 20,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      recurrence: ReminderRecurrenceCodec.fromStorageKey(
        map['recurrence'] as String?,
      ),
      enabled: (map['enabled'] as bool?) ?? true,
    );
  }
}
