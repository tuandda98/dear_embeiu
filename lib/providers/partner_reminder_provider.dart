import 'dart:async';

import 'package:flutter/foundation.dart';

import '../l10n/app_l10n.dart';
import '../models/partner_reminder.dart';
import '../services/partner_reminder_service.dart';
import '../services/reminder_service.dart';

/// Receiving side of the "nhắc người ấy" toggle (feature partner-nudge,
/// 2026-06-30): streams the couple's `partnerReminders` and arms the ones MY
/// PARTNER set for me as LOCAL notifications (band 3000–3049), so a reminder my
/// partner shared rings on THIS device at the right time / timezone.
///
/// Writing partner reminders is done by [CustomRemindersProvider] (the toggle on
/// the custom-reminder form) via [PartnerReminderService] — this provider only
/// listens + arms. Wired from SessionResolver when a couple is active; [clear]
/// cancels the local band and unsubscribes on sign-out / no-couple.
class PartnerReminderProvider extends ChangeNotifier {
  PartnerReminderProvider({
    PartnerReminderService? service,
    ReminderService? reminderService,
  })  : _service = service ?? PartnerReminderService(),
        _reminderService = reminderService ?? ReminderService.instance;

  final PartnerReminderService _service;
  final ReminderService _reminderService;

  String? _myUid;
  StreamSubscription<List<PartnerReminder>>? _sub;

  String? _coupleId;

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
    final uid = _myUid;
    if (uid == null) {
      return;
    }
    // Arm LOCAL notifications only for the reminders my PARTNER set for me.
    final incoming = reminders.where((r) => r.authorUserId != uid && r.enabled);
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

  /// Stop watching and cancel the locally-armed band. Called on sign-out /
  /// no-couple so a stale schedule never "rings like a ghost".
  void clear() {
    _sub?.cancel();
    _sub = null;
    _coupleId = null;
    _myUid = null;
    unawaited(_reminderService.cancelPartnerReminders());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
