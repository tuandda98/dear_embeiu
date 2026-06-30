import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/partner_reminder.dart';
import 'firebase_bootstrap_service.dart';

/// Firestore access for the "nhắc người ấy" feature (partner-nudge, 2026-06-29):
/// - one-shot NUDGES (`couples/{id}/nudges`) → Cloud Function pushes them to the
///   partner with the text in the body;
/// - scheduled PARTNER REMINDERS (`couples/{id}/partnerReminders`) → the
///   recipient's app watches and arms a LOCAL notification.
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

  CollectionReference<Map<String, dynamic>> _nudges(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('nudges');

  CollectionReference<Map<String, dynamic>> _reminders(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('partnerReminders');

  // --- Nudge (instant) -------------------------------------------------------

  /// Write a one-shot nudge; the `notifyPartnerNudge` Cloud Function pushes it
  /// to the partner. Returns whether the write was attempted (false in the local
  /// fallback / on bad input).
  Future<bool> sendNudge(
    String coupleId,
    String authorUserId,
    String text,
  ) async {
    final body = text.trim();
    if (coupleId.trim().isEmpty ||
        authorUserId.trim().isEmpty ||
        body.isEmpty ||
        !isUsingFirebase) {
      return false;
    }
    try {
      await _nudges(coupleId).add(<String, Object?>{
        'authorUserId': authorUserId,
        'text': body.length > 200 ? body.substring(0, 200) : body,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

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
