import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_bootstrap_service.dart';

/// Streams the set of "revealed" days for a couple's streak — i.e. days where
/// BOTH members answered the daily question (marked `bothAnswered == true` on
/// the `couples/{coupleId}/dailyAnswers/{date}` marker by [DailyQuestionService]).
///
/// Pure read-side, thuần client (feature streak): no schema beyond the marker
/// flag, no Cloud Function, no rules change. Fail-soft — any read error surfaces
/// as an `onError` the provider turns into a hidden chip.
class StreakService {
  StreakService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// How many marker docs to keep in the live window. Comfortably covers every
  /// milestone {3,7,30,100,365} for the CURRENT streak; the derived
  /// "longest streak" is therefore only accurate within this window (D-PO-1).
  static const int windowLimit = 180;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _dailyAnswers(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('dailyAnswers');

  /// Streams the revealed-day keys ('YYYY-MM-DD' strings, newest first) for
  /// [coupleId].
  ///
  /// Reads the newest [windowLimit] marker docs ordered by `date` desc and
  /// filters `bothAnswered == true` CLIENT-SIDE (no `where` clause → no
  /// composite index needed). Realtime via `snapshots()` so the streak updates
  /// the moment today's marker flips to revealed (the second answerer sets the
  /// flag; this stream then pushes it).
  ///
  /// Local fallback (no Firebase): emits an empty list once — streak only runs
  /// with Firebase + an active couple.
  Stream<List<String>> watchRevealedDates(String coupleId) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return Stream<List<String>>.value(const <String>[]);
    }

    return _dailyAnswers(coupleId)
        .orderBy('date', descending: true)
        .limit(windowLimit)
        .snapshots()
        .map((snapshot) {
      final dates = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['bothAnswered'] == true) {
          final date = (data['date'] as String?)?.trim();
          dates.add((date != null && date.isNotEmpty) ? date : doc.id);
        }
      }
      return dates;
    });
  }
}
