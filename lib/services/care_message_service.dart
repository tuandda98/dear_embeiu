import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/care_message.dart';
import 'firebase_bootstrap_service.dart';

/// Writes/reads the couple's "care notes" (feature care-message):
/// `couples/{coupleId}/careMessages/{autoId}` — append-only (rules forbid
/// update/delete), readable by both members.
///
/// ⚠️ The Firestore rule pins the doc to EXACTLY four keys
/// (`authorUserId`, `title`, `body`, `createdAt`) and requires
/// `createdAt == request.time`, so the create MUST use
/// [FieldValue.serverTimestamp] and MUST NOT add any extra field.
///
/// Unlike chat/daily-question there is NO local (Hive) fallback: a care note's
/// whole purpose is the push it triggers on the partner's phone, which can't
/// happen without Firebase. Off Firebase, [send] is a no-op and [watchRecent]
/// is an empty stream.
class CareMessageService {
  CareMessageService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('careMessages');

  /// Sends a care note. Trims + clamps to the rule limits (60 / 200) and skips
  /// silently when either part is empty, so the caller never has to pre-check.
  /// Throws on a Firestore failure so the UI can surface a retry.
  Future<void> send({
    required String coupleId,
    required String uid,
    required String title,
    required String body,
  }) async {
    if (coupleId.trim().isEmpty || uid.trim().isEmpty || !isUsingFirebase) {
      return;
    }
    final cleanTitle = _clamp(title, CareMessage.maxTitleLength);
    final cleanBody = _clamp(body, CareMessage.maxBodyLength);
    if (cleanTitle.isEmpty || cleanBody.isEmpty) {
      return;
    }

    await _collection(coupleId.trim()).add(<String, dynamic>{
      'authorUserId': uid.trim(),
      'title': cleanTitle,
      'body': cleanBody,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams the couple's most recent care notes (both members'), newest first.
  /// Errors are swallowed — a broken history list must never break composing.
  Stream<List<CareMessage>> watchRecent(String coupleId, {int limit = 20}) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return Stream<List<CareMessage>>.value(const <CareMessage>[]);
    }
    return _collection(coupleId.trim())
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CareMessage.fromDoc(doc.id, doc.data()))
              .toList(growable: false),
        )
        .handleError((_) {});
  }

  /// Trim + hard-clamp (the rule rejects anything longer, and a rejected write
  /// is worse than a slightly shortened note).
  static String _clamp(String value, int max) {
    final trimmed = value.trim();
    return trimmed.length <= max ? trimmed : trimmed.substring(0, max).trim();
  }
}
