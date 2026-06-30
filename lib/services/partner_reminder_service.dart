import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/partner_reminder.dart';
import 'firebase_bootstrap_service.dart';

/// Firestore access for the "nhắc người ấy" toggle (partner-nudge, 2026-06-30):
/// scheduled PARTNER REMINDERS (`couples/{id}/partnerReminders`) written when the
/// custom-reminder "Cũng nhắc người ấy" toggle is on — the recipient's app
/// watches and arms a LOCAL notification.
///
/// Fail-soft by design (mirrors [HomePrefsService]): without Firebase the watch
/// emits nothing and writes are dropped.
class PartnerReminderService {
  PartnerReminderService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reminders(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('partnerReminders');

  // --- Scheduled partner reminders ------------------------------------------

  /// Streams ALL partner reminders for the couple (both directions), newest
  /// first. The caller filters by author to decide what to arm locally vs. show
  /// in the management list. Empty stream in the local fallback.
  Stream<List<PartnerReminder>> watchPartnerReminders(String coupleId) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return const Stream<List<PartnerReminder>>.empty();
    }
    return _reminders(coupleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PartnerReminder.fromMap(doc.id, doc.data()))
            .toList(growable: false))
        .handleError((_) {});
  }

  /// Create a new partner reminder (the author sets it for their partner).
  /// Returns the new doc id, or null on failure / local fallback.
  Future<String?> createReminder(
    String coupleId,
    PartnerReminder reminder,
  ) async {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return null;
    }
    try {
      final ref = await _reminders(coupleId).add(<String, Object?>{
        ...reminder.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  /// Update an existing partner reminder (author only — enforced by rules).
  /// MERGE so `createdAt` survives; `authorUserId` is re-sent unchanged so the
  /// rule's author-immutability check passes.
  Future<void> updateReminder(
    String coupleId,
    PartnerReminder reminder,
  ) async {
    if (coupleId.trim().isEmpty || reminder.id.isEmpty || !isUsingFirebase) {
      return;
    }
    try {
      await _reminders(coupleId)
          .doc(reminder.id)
          .set(reminder.toFirestore(), SetOptions(merge: true));
    } catch (_) {
      // Fail-soft — the watcher reflects the last successful write.
    }
  }

  /// Delete a partner reminder (author only — enforced by rules).
  Future<void> deleteReminder(String coupleId, String reminderId) async {
    if (coupleId.trim().isEmpty || reminderId.isEmpty || !isUsingFirebase) {
      return;
    }
    try {
      await _reminders(coupleId).doc(reminderId).delete();
    } catch (_) {
      // Fail-soft.
    }
  }
}
