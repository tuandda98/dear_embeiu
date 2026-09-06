import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_notification.dart';
import 'firebase_bootstrap_service.dart';

/// Reads the per-user notification inbox (`users/{uid}/notifications`) for the
/// in-app notification center. Docs are written ONLY by Cloud Functions; the
/// client may read its own, mark them read, and delete (dismiss) them.
///
/// The stream is scoped to the user's CURRENT couple (`coupleId ==`), so after
/// a user leaves / switches couples the previous couple's notifications are no
/// longer surfaced — without needing a server-side cleanup. Firestore's offline
/// cache backs the stream, so the list still shows the last-known items with no
/// network.
class NotificationInboxService {
  NotificationInboxService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Cap on how many notifications we keep on screen (matches the composite
  /// index `coupleId ASC, createdAt DESC`).
  static const int kLimit = 50;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  /// Streams the newest [kLimit] notifications for [uid] belonging to
  /// [coupleId], newest-first. Emits an empty list when there is no Firebase /
  /// missing ids (the feature simply shows its empty state).
  Stream<List<AppNotification>> watch(String uid, String coupleId) {
    if (uid.trim().isEmpty || coupleId.trim().isEmpty || !isUsingFirebase) {
      return Stream<List<AppNotification>>.value(const <AppNotification>[]);
    }

    return _collection(uid)
        .where('coupleId', isEqualTo: coupleId)
        .orderBy('createdAt', descending: true)
        .limit(kLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromDoc(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Marks one notification read. Best-effort (swallows failures so the UI's
  /// optimistic update is never undone by a transient error).
  Future<void> markRead(String uid, String id) async {
    if (!isUsingFirebase || uid.trim().isEmpty || id.trim().isEmpty) return;
    try {
      await _collection(uid).doc(id).update({'read': true});
    } catch (_) {
      // Best-effort.
    }
  }

  /// Marks every [ids] read in one batch (rule allows changing only `read`).
  Future<void> markAllRead(String uid, List<String> ids) async {
    if (!isUsingFirebase || uid.trim().isEmpty || ids.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final id in ids) {
        batch.update(_collection(uid).doc(id), {'read': true});
      }
      await batch.commit();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Deletes (dismisses) one notification.
  Future<void> delete(String uid, String id) async {
    if (!isUsingFirebase || uid.trim().isEmpty || id.trim().isEmpty) return;
    try {
      await _collection(uid).doc(id).delete();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Deletes every [ids] in one batch (clear all).
  Future<void> clearAll(String uid, List<String> ids) async {
    if (!isUsingFirebase || uid.trim().isEmpty || ids.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final id in ids) {
        batch.delete(_collection(uid).doc(id));
      }
      await batch.commit();
    } catch (_) {
      // Best-effort.
    }
  }
}
