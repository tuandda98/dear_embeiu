import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/daily_questions.dart';
import 'daily_question_service.dart';
import 'firebase_bootstrap_service.dart';

/// One past day the gated account never answered — the payload of the catch-up
/// gate (`lib/widgets/catchup_gate.dart`).
class CatchupMissedDay {
  /// 'YYYY-MM-DD' bucket (same key space as [DailyQuestionService.dateKey]).
  final String dateKey;

  /// Date-only [DateTime] parsed from [dateKey] (for `dd/MM` formatting).
  final DateTime date;

  /// The Vietnamese question for that day — the marker's snapshot when one
  /// exists, otherwise derived from the bank exactly like `submitAnswer` does.
  final String questionVi;

  const CatchupMissedDay({
    required this.dateKey,
    required this.date,
    required this.questionVi,
  });
}

/// Finds the past days the user FORGOT to answer the daily question
/// (feature `catch-up`, 2026-09-05).
///
/// ⚠️ ACCOUNT-GATED: only [gatedEmail] ever runs this — the gate it feeds is a
/// blocking, un-dismissable modal, deliberately scoped to one account (em bé)
/// who keeps breaking the couple streak. Every other account is untouched (the
/// caller short-circuits on [isGatedEmail]).
///
/// A day counts as MISSED when its marker isn't flagged `bothAnswered` AND this
/// user has no `responses/{uid}` doc for it — i.e. the streak broke because of
/// *me*, not because the partner is late. Days with no marker at all count too
/// (nobody answered); the question is still derivable from the bank.
///
/// Everything here is fail-soft: any error (offline, permission, missing index)
/// resolves to "no missed days" so the app is never blocked by the gate.
class CatchupService {
  CatchupService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// The ONLY account this feature applies to.
  static const String gatedEmail = 'thaohathao14@gmail.com';

  /// Never look further back than this — days before it were already
  /// backfilled by hand (`scripts/prod-daily-answer.js`, 2026-08-23) and must
  /// not be dug up again.
  static const String catchupSinceDate = '2026-09-05';

  /// How many days before today to scan (yesterday → 14 days back).
  static const int windowDays = 14;

  /// Marker docs to read in the single list query. The window is 14 days, and
  /// markers only exist for days someone answered, so 20 newest markers always
  /// span the whole window.
  static const int _markerLimit = 20;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Case/whitespace-insensitive account gate.
  static bool isGatedEmail(String? email) =>
      (email ?? '').trim().toLowerCase() == gatedEmail;

  CollectionReference<Map<String, dynamic>> _dailyAnswers(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('dailyAnswers');

  /// The missed days in [windowDays] before [now] (today EXCLUDED — today's
  /// card on Home already handles it), oldest first so the gate can walk
  /// forward in time.
  /// Returns `null` when the scan could not run (offline / permission) so the
  /// caller keeps its current state instead of treating it as "no debt".
  Future<List<CatchupMissedDay>?> findMissedDays({
    required String coupleId,
    required String myUid,
    required String partnerUid,
    DateTime? now,
  }) async {
    if (!isUsingFirebase ||
        coupleId.trim().isEmpty ||
        myUid.trim().isEmpty ||
        partnerUid.trim().isEmpty) {
      return const <CatchupMissedDay>[];
    }

    final today = now ?? DateTime.now();
    // Candidate window: yesterday back to `windowDays` days ago, clamped to
    // `catchupSinceDate` (string compare is safe on ISO 'YYYY-MM-DD').
    final candidates = <String, DateTime>{};
    for (var back = 1; back <= windowDays; back++) {
      final day = DateTime(today.year, today.month, today.day - back);
      final key = DailyQuestionService.dateKey(day);
      if (key.compareTo(catchupSinceDate) < 0) {
        continue;
      }
      candidates[key] = day;
    }
    if (candidates.isEmpty) {
      return const <CatchupMissedDay>[];
    }

    try {
      // One list query knocks out every already-revealed day cheaply; only the
      // survivors cost an extra per-day read below.
      final markersSnap = await _dailyAnswers(coupleId)
          .orderBy('date', descending: true)
          .limit(_markerLimit)
          .get();
      final markers = <String, Map<String, dynamic>>{
        for (final doc in markersSnap.docs) doc.id: doc.data(),
      };

      final pending = <String>[];
      for (final key in candidates.keys) {
        final marker = markers[key];
        if (marker != null && marker['bothAnswered'] == true) {
          continue;
        }
        pending.add(key);
      }
      if (pending.isEmpty) {
        return const <CatchupMissedDay>[];
      }

      // Did I answer that day — and did the PARTNER? A day only counts as
      // missed when the partner answered and I didn't: that is the day *my*
      // catch-up can still complete (the CF stamps `bothAnswered` on the
      // backfill). A day nobody answered cannot be repaired from this side,
      // so it is skipped rather than forcing an answer that would never
      // restore the streak. (≤ 2×14 point reads, in parallel.)
      final mine = await Future.wait(
        pending.map(
          (key) => _dailyAnswers(
            coupleId,
          ).doc(key).collection('responses').doc(myUid).get(),
        ),
      );
      final theirs = await Future.wait(
        pending.map(
          (key) => _dailyAnswers(
            coupleId,
          ).doc(key).collection('responses').doc(partnerUid).get(),
        ),
      );

      final missed = <CatchupMissedDay>[];
      for (var i = 0; i < pending.length; i++) {
        if (mine[i].exists || !theirs[i].exists) {
          continue;
        }
        final key = pending[i];
        final date = candidates[key]!;
        final snapshot = (markers[key]?['questionVi'] as String?)?.trim();
        missed.add(
          CatchupMissedDay(
            dateKey: key,
            date: date,
            questionVi: snapshot != null && snapshot.isNotEmpty
                ? snapshot
                : questionTextForCouple(date, coupleId, 'vi'),
          ),
        );
      }

      missed.sort((a, b) => a.dateKey.compareTo(b.dateKey));
      return missed;
    } catch (error) {
      // Fail-soft on purpose: offline / permission-denied / missing index must
      // never block the app behind the gate.
      debugPrint('CatchupService.findMissedDays failed: $error');
      return null;
    }
  }
}
