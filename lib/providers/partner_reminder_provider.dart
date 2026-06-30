import 'dart:async';

import 'package:flutter/foundation.dart';

import '../l10n/app_l10n.dart';
import '../models/custom_reminder.dart';
import '../models/partner_reminder.dart';
import '../services/analytics_service.dart';
import '../services/partner_reminder_service.dart';
import '../services/reminder_service.dart';

/// Drives the "nhắc người ấy" feature (partner-nudge, 2026-06-29) on the client.
///
/// Two responsibilities:
///  1. INSTANT nudges — [sendNudge] writes a `nudges` doc (a Cloud Function
///     pushes it to the partner). A short client-side cooldown blocks spam.
///  2. SCHEDULED partner reminders — [watchPartnerReminders] streams the
///     couple's reminders; the ones the PARTNER set for ME are armed as LOCAL
///     notifications (band 3000–3049), while the ones I created are exposed via
///     [mine] for the management list.
///
/// Wired from SessionResolver when a couple is active; [clear] cancels the local
/// band and unsubscribes on sign-out / no-couple.
class PartnerReminderProvider extends ChangeNotifier {
  PartnerReminderProvider({
    PartnerReminderService? service,
    ReminderService? reminderService,
  })  : _service = service ?? PartnerReminderService(),
        _reminderService = reminderService ?? ReminderService.instance;

  final PartnerReminderService _service;
  final ReminderService _reminderService;

  /// Max reminders one person may set for their partner (client guard).
  static const int maxReminders = 20;

  /// Minimum gap between two nudges, to keep nudging affectionate not spammy.
  static const Duration nudgeCooldown = Duration(seconds: 30);

  String? _coupleId;
  String? _myUid;
  StreamSubscription<List<PartnerReminder>>? _sub;

  List<PartnerReminder> _all = const <PartnerReminder>[];
  DateTime? _lastNudgeAt;

  /// Reminders I created for my partner (the management list).
  List<PartnerReminder> get mine {
    final uid = _myUid;
    if (uid == null) return const <PartnerReminder>[];
    return _all.where((r) => r.authorUserId == uid).toList(growable: false);
  }

  int get mineCount => mine.length;

  bool get isAtCapacity => mineCount >= maxReminders;

  bool get canSendNudge {
    final last = _lastNudgeAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= nudgeCooldown;
  }

  /// Seconds left before another nudge may be sent (0 when ready).
  int get nudgeCooldownSecondsLeft {
    final last = _lastNudgeAt;
    if (last == null) return 0;
    final left = nudgeCooldown - DateTime.now().difference(last);
    return left.isNegative ? 0 : left.inSeconds + 1;
  }

  /// Follow the couple's partner reminders. Re-subscribes when the couple
  /// changes. Idempotent for the same (couple, uid).
  void watchPartnerReminders(String coupleId, String myUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      return;
    }
    if (_coupleId == coupleId && _myUid == myUid && _sub != null) {
      return;
    }
    _coupleId = coupleId;
    _myUid = myUid;
    _sub?.cancel();
    _sub = _service.watchPartnerReminders(coupleId).listen(
      _onReminders,
      onError: (_) {},
    );
  }

  void _onReminders(List<PartnerReminder> reminders) {
    _all = reminders;
    _armIncoming();
    notifyListeners();
  }

  /// Arm LOCAL notifications for the reminders my PARTNER set for me.
  void _armIncoming() {
    final uid = _myUid;
    if (uid == null) {
      return;
    }
    final incoming = _all.where((r) => r.authorUserId != uid && r.enabled);
    final l10n = AppL10n.strings;
    final items = incoming
        .map((r) => (
              reminder: r.toScheduleReminder(),
              title: r.text,
              body: l10n.partnerReminderNotifBody,
            ))
        .toList(growable: false);
    // Fire-and-forget; the service clears the band first so this is a full
    // re-arm of the current set.
    unawaited(_reminderService.schedulePartnerReminders(items));
  }

  // --- Nudge -----------------------------------------------------------------

  /// Send an instant nudge to the partner. Returns false when on cooldown, in
  /// the local fallback, or on a write error.
  Future<bool> sendNudge(String text) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    final body = text.trim();
    if (coupleId == null || uid == null || body.isEmpty || !canSendNudge) {
      return false;
    }
    // Optimistically start the cooldown so a double-tap can't double-send.
    _lastNudgeAt = DateTime.now();
    notifyListeners();
    final ok = await _service.sendNudge(coupleId, uid, body);
    if (!ok) {
      // Roll back the cooldown so the user can retry a failed send.
      _lastNudgeAt = null;
      notifyListeners();
    }
    return ok;
  }

  // --- Scheduled reminders ---------------------------------------------------

  /// Create a reminder for my partner. Returns the new doc id, or null when at
  /// capacity / on failure.
  Future<String?> addReminder({
    required String text,
    required int minuteOfDay,
    required ReminderRecurrence recurrence,
    required DateTime date,
  }) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null || isAtCapacity) {
      return null;
    }
    final reminder = PartnerReminder(
      id: '',
      authorUserId: uid,
      text: text.trim(),
      minuteOfDay: minuteOfDay,
      recurrence: recurrence,
      date: date,
      enabled: true,
    );
    final id = await _service.createReminder(coupleId, reminder);
    if (id != null) {
      // Analytics — only the recurrence kind, never the reminder text.
      AnalyticsService.instance.logPartnerReminderCreated(recurrence.name);
    }
    return id;
  }

  Future<void> updateReminder(PartnerReminder reminder) async {
    final coupleId = _coupleId;
    if (coupleId == null) {
      return;
    }
    await _service.updateReminder(coupleId, reminder);
  }

  Future<void> toggleReminder(PartnerReminder reminder, bool enabled) async {
    await updateReminder(reminder.copyWith(enabled: enabled));
  }

  Future<void> deleteReminder(String reminderId) async {
    final coupleId = _coupleId;
    if (coupleId == null) {
      return;
    }
    await _service.deleteReminder(coupleId, reminderId);
  }

  /// Stop watching and cancel the locally-armed band. Called on sign-out /
  /// no-couple so a stale schedule never "rings like a ghost".
  void clear() {
    _sub?.cancel();
    _sub = null;
    _coupleId = null;
    _myUid = null;
    _all = const <PartnerReminder>[];
    _lastNudgeAt = null;
    unawaited(_reminderService.cancelPartnerReminders());
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
