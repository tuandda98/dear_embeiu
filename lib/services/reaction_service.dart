import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/photo_reaction.dart';
import 'firebase_bootstrap_service.dart';

/// Reads/writes per-photo reactions
/// (`couples/{coupleId}/photos/{photoId}/reactions/{authorUserId}` — one doc per
/// member per photo; the doc id IS the author's uid).
///
/// Reactions are a Firebase-only feature: they only make sense once there is a
/// partner to react with, so when Firebase isn't available (local fallback /
/// guest) every method degrades to a safe no-op and the watch stream emits an
/// empty map. The UI hides the reaction surface entirely in that case.
class ReactionService {
  ReactionService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reactionsCollection(
    String coupleId,
    String photoId,
  ) =>
      _db
          .collection('couples')
          .doc(coupleId)
          .collection('photos')
          .doc(photoId)
          .collection('reactions');

  /// Streams every reaction of the couple at once, grouped by photoId.
  ///
  /// Uses a single `collectionGroup('reactions')` query filtered by [coupleId]
  /// (denormalised onto each reaction doc) so the whole couple's reactions ride
  /// on ONE stream — couples have only two people and a modest number of photos,
  /// so this stays small. The photoId is recovered from the document path
  /// (`reactions` → parent `photo` doc). Each emitted value maps
  /// `photoId -> List<PhotoReaction>`.
  Stream<Map<String, List<PhotoReaction>>> watchCoupleReactions(
    String coupleId,
  ) {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return Stream<Map<String, List<PhotoReaction>>>.value(
        const <String, List<PhotoReaction>>{},
      );
    }

    return _db
        .collectionGroup('reactions')
        .where('coupleId', isEqualTo: coupleId)
        .snapshots()
        .map((snapshot) {
      final byPhoto = <String, List<PhotoReaction>>{};
      for (final doc in snapshot.docs) {
        // reactions/{uid} → parent is the photo doc → its id is the photoId.
        final photoId = doc.reference.parent.parent?.id;
        if (photoId == null || photoId.isEmpty) {
          continue;
        }
        final reaction = PhotoReaction.fromDoc(doc.id, doc.data());
        if (!reaction.isValid) {
          continue;
        }
        (byPhoto[photoId] ??= <PhotoReaction>[]).add(reaction);
      }
      return byPhoto;
    });
  }

  /// Creates or overwrites the current user's reaction (doc id == [uid]).
  /// No-ops on the local fallback or when [emoji] is not one of the six valid
  /// reactions (defence in depth — the rules also enforce this).
  Future<void> setReaction({
    required String coupleId,
    required String photoId,
    required String uid,
    required String emoji,
  }) async {
    if (!isUsingFirebase ||
        coupleId.trim().isEmpty ||
        photoId.trim().isEmpty ||
        uid.trim().isEmpty ||
        !kReactionEmojis.contains(emoji)) {
      return;
    }

    await _reactionsCollection(coupleId, photoId).doc(uid).set(
      {
        'authorUserId': uid,
        'emoji': emoji,
        'coupleId': coupleId,
        'reactedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes (deletes) the current user's reaction. No-ops on the local
  /// fallback.
  Future<void> removeReaction({
    required String coupleId,
    required String photoId,
    required String uid,
  }) async {
    if (!isUsingFirebase ||
        coupleId.trim().isEmpty ||
        photoId.trim().isEmpty ||
        uid.trim().isEmpty) {
      return;
    }

    await _reactionsCollection(coupleId, photoId).doc(uid).delete();
  }
}
