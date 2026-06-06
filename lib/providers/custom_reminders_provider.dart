import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/app_l10n.dart';
import '../models/custom_reminder.dart';
import '../services/analytics_service.dart';
import '../services/reminder_service.dart';

/// CRUD + persistence + scheduling for user-created custom reminders (D1–D9).
///
/// Local-only: reminders live in the `custom_reminders` Hive box (keyed by the
/// reminder id) and each is scheduled through [ReminderService] using the
/// 2000–2999 notification id band. The provider decides *what* to schedule and
/// when; the service knows *how*.
class CustomRemindersProvider extends ChangeNotifier {
  static const String _boxName = 'custom_reminders';

  /// Reserved notification-id band for custom reminders (D6).
  static const int _idMin = 2000;
  static const int _idMax = 2999;

  /// Maximum number of custom reminders per device (D5).
  static const int maxReminders = 20;

  final ReminderService _service = ReminderService.instance;

  final List<CustomReminder> _reminders = <CustomReminder>[];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Reminders sorted by their next fire time (soonest first); reminders with
  /// no upcoming fire (past `once`) sink to the bottom.
  List<CustomReminder> get reminders {
    final list = List<CustomReminder>.from(_reminders);
    list.sort((a, b) {
      final aNext = _service.nextFireFor(a);
      final bNext = _service.nextFireFor(b);
      if (aNext == null && bNext == null) return 0;
      if (aNext == null) return 1;
      if (bNext == null) return -1;
      return aNext.compareTo(bNext);
    });
    return list;
  }

  int get count => _reminders.length;

  bool get isAtCapacity => _reminders.length >= maxReminders;

  /// Load persisted reminders from Hive. Never throws to the caller — a Hive
  /// read failure must not block app launch.
  Future<void> load() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      _reminders
        ..clear()
        ..addAll(
          box.values
              .whereType<Map<dynamic, dynamic>>()
              .map(CustomReminder.fromMap),
        );
      _loaded = true;
      notifyListeners();
    } catch (error) {
      debugPrint('CustomRemindersProvider.load failed: $error');
      _loaded = true;
    }
  }

  /// Re-schedule every enabled reminder. Call once at startup (after
  /// [ReminderService.initialize] + [load]) so cold-start restores the OS
  /// schedule, and whenever the global reminders toggle is turned back on.
  Future<void> rescheduleAllEnabled() async {
    for (final reminder in _reminders) {
      if (reminder.enabled) {
        await _schedule(reminder);
      } else {
        await _service.cancelCustom(reminder.id);
      }
    }
  }

  /// Cancel every custom reminder's OS schedule without deleting the stored
  /// data. Used when the global reminders feature is turned off (D7).
  Future<void> cancelAllSchedules() async {
    for (final reminder in _reminders) {
      await _service.cancelCustom(reminder.id);
    }
  }

  /// Create a new reminder. Returns the created reminder, or `null` when at
  /// capacity (D5) so the caller can show the limit message.
  Future<CustomReminder?> add({
    required String name,
    String? note,
    required DateTime date,
    required int hour,
    required int minute,
    required ReminderRecurrence recurrence,
  }) async {
    if (isAtCapacity) {
      return null;
    }
    final id = _allocateId();
    if (id == null) {
      return null;
    }
    final reminder = CustomReminder(
      id: id,
      name: name.trim(),
      note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      date: date,
      hour: hour,
      minute: minute,
      recurrence: recurrence,
      enabled: true,
    );
    _reminders.add(reminder);
    await _persist(reminder);
    await _schedule(reminder);
    notifyListeners();
    // Analytics — a custom reminder was created (only the recurrence kind, no
    // name/note is ever logged).
    AnalyticsService.instance.logReminderCreated(recurrence.name);
    return reminder;
  }

  /// Update an existing reminder in place (id preserved). Cancels the old
  /// schedule and re-schedules with the new values.
  Future<void> update(CustomReminder updated) async {
    final index = _reminders.indexWhere((r) => r.id == updated.id);
    if (index == -1) {
      return;
    }
    _reminders[index] = updated;
    await _persist(updated);
    // Cancel + reschedule (same id) so changed time/recurrence takes effect.
    await _service.cancelCustom(updated.id);
    if (updated.enabled) {
      await _schedule(updated);
    }
    notifyListeners();
  }

  /// Delete a reminder and cancel its schedule.
  Future<void> delete(int id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _service.cancelCustom(id);
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      await box.delete(id);
    } catch (error) {
      debugPrint('CustomRemindersProvider.delete failed: $error');
    }
    notifyListeners();
  }

  /// Toggle a reminder on/off → reschedule or cancel accordingly.
  Future<void> toggle(int id, bool enabled) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) {
      return;
    }
    final updated = _reminders[index].copyWith(enabled: enabled);
    _reminders[index] = updated;
    await _persist(updated);
    if (enabled) {
      await _schedule(updated);
    } else {
      await _service.cancelCustom(id);
    }
    notifyListeners();
  }

  /// Next fire time for a reminder, exposed for the "Next: …" list label.
  /// Returns null for a past one-off.
  DateTime? nextFireDateTime(CustomReminder reminder) {
    final next = _service.nextFireFor(reminder);
    if (next == null) {
      return null;
    }
    // Convert the timezone-aware value to a plain DateTime for formatting.
    return DateTime(
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
    );
  }

  Future<void> _schedule(CustomReminder reminder) async {
    final body = (reminder.note != null && reminder.note!.isNotEmpty)
        ? reminder.note!
        : AppL10n.strings.customRemindersNotifBodyFallback;
    await _service.scheduleCustom(
      id: reminder.id,
      reminder: reminder,
      title: reminder.name,
      body: body,
    );
  }

  Future<void> _persist(CustomReminder reminder) async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      await box.put(reminder.id, reminder.toMap());
    } catch (error) {
      debugPrint('CustomRemindersProvider._persist failed: $error');
    }
  }

  /// Smallest free id in the 2000–2999 band, or null if the band is full
  /// (cannot happen under the 20-item cap but kept defensive).
  int? _allocateId() {
    final used = _reminders.map((r) => r.id).toSet();
    for (var id = _idMin; id <= _idMax; id++) {
      if (!used.contains(id)) {
        return id;
      }
    }
    return null;
  }
}
