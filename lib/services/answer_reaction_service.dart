import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/answer_reaction.dart';
import 'firebase_bootstrap_service.dart';

/// Reads/writes reactions on daily-question answers
/// (`couples/{coupleId}/dailyAnswers/{date}/responses/{answerAuthorUid}/answerReactions/{reactorUid}`
/// — one doc per reactor per answer; the doc id IS the reactor's uid).
///
/// Mirrors [ReactionService] (photo reactions) in shape and degradation: this
/// is a Firebase-only feature — it only means anything once there is a partner —
/// so on the local fallback / guest path every method is a safe no-op and the
/// watch stream emits an empty map. The UI hides the surface entirely then.
class AnswerReactionService {
  AnswerReactionService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reactionsCollection({
    required String coupleId,
    required String date,
    required String answerAuthorUid,
  }) =>
      _db
          .collection('couples')
          .doc(coupleId)
          .collection('dailyAnswers')
          .doc(date)
          .collection('responses')
          .doc(answerAuthorUid)
          .collection('answerReactions');

  /// Streams every answer reaction of the couple at once, keyed by
  /// `AnswerReaction.keyFor(date, answerAuthorUid)`.
  ///
  /// One `collectionGroup('answerReactions')` query filtered by [coupleId]
  /// (denormalised onto each doc) carries the whole couple — at most two
  /// reactions per day, so even years of history stays small, and Journal can
  /// render past days without a second query. The answer's author and the date
  /// are recovered from the document path, which cannot be spoofed by a stale
  /// field.
  Stream<Map<String, List<AnswerReaction>>> watchCoupleAnswerReactions(
    String coupleId,
  ) {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return Stream<Map<String, List<AnswerReaction>>>.value(
        const <String, List<AnswerReaction>>{},
      );
    }

    return _db
        .collectionGroup('answerReactions')
        .where('coupleId', isEqualTo: coupleId)
        .snapshots()
        .map((snapshot) {
      final byAnswer = <String, List<AnswerReaction>>{};
      for (final doc in snapshot.docs) {
        // answerReactions/{reactorUid}
        //   → parent doc responses/{answerAuthorUid}
        //     → parent doc dailyAnswers/{date}
        final answerDoc = doc.reference.parent.parent;
        final answerAuthorUid = answerDoc?.id;
        final date = answerDoc?.parent.parent?.id;
        if (answerAuthorUid == null ||
            answerAuthorUid.isEmpty ||
            date == null ||
            date.isEmpty) {
          continue;
        }
        final reaction = AnswerReaction.fromDoc(
          doc.id,
          doc.data(),
          answerAuthorUserId: answerAuthorUid,
          date: date,
        );
        if (!reaction.isValid) {
          continue;
        }
        (byAnswer[reaction.key] ??= <AnswerReaction>[]).add(reaction);
      }
      return byAnswer;
    });
  }

  /// Creates or overwrites [uid]'s reaction on one answer (doc id == [uid]).
  /// No-ops on the local fallback or when [emoji] is not one of the six valid
  /// reactions (defence in depth — the rules also enforce this).
  Future<void> setReaction({
    required String coupleId,
    required String date,
    required String answerAuthorUid,
    required String uid,
    required String emoji,
  }) async {
    if (!isUsingFirebase ||
        coupleId.trim().isEmpty ||
        date.trim().isEmpty ||
        answerAuthorUid.trim().isEmpty ||
        uid.trim().isEmpty ||
        !kReactionEmojis.contains(emoji)) {
      return;
    }

    await _reactionsCollection(
      coupleId: coupleId,
      date: date,
      answerAuthorUid: answerAuthorUid,
    ).doc(uid).set(
      {
        'reactorUserId': uid,
        'emoji': emoji,
        'coupleId': coupleId,
        'date': date,
        'reactedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes (deletes) [uid]'s reaction on one answer. No-ops on the local
  /// fallback.
  Future<void> removeReaction({
    required String coupleId,
    required String date,
    required String answerAuthorUid,
    required String uid,
  }) async {
    if (!isUsingFirebase ||
        coupleId.trim().isEmpty ||
        date.trim().isEmpty ||
        answerAuthorUid.trim().isEmpty ||
        uid.trim().isEmpty) {
      return;
    }

    await _reactionsCollection(
      coupleId: coupleId,
      date: date,
      answerAuthorUid: answerAuthorUid,
    ).doc(uid).delete();
  }
}
