import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_bootstrap_service.dart';

/// One emission of the couple-shared daily-question reminder prefs. A null
/// field means "not set in Firestore yet" — the caller keeps its current/local
/// value for that field rather than overwriting it.
typedef ReminderPrefs = ({bool? enabled, List<int>? times});

/// Shared Home preferences the couple co-owns, stored in ONE tiny doc
/// (`couples/{coupleId}/prefs/home`). Fields:
/// - `counterBgPhotoId` — which photo backs the hero counter card (a swipe on
///   either phone picks the same backdrop for both).
/// - `dqReminderEnabled` / `dqReminderTimes` — couple-shared daily-question
///   reminder (2026-06-14): both phones nudge at the same time(s); times are
///   minutes-since-midnight ints.
///
/// All writes MERGE (one field never clobbers another). Fail-soft by design:
/// without Firebase (local fallback) the watch emits nothing and writes are
/// dropped — the Hive cache keeps the device-local behavior alive.
class HomePrefsService {
  HomePrefsService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('prefs').doc('home');

  /// Streams the shared counter-background photo key (null when unset or in
  /// the local fallback).
  Stream<String?> watchCounterBg(String coupleId) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return const Stream<String?>.empty();
    }
    return _doc(coupleId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['counterBgPhotoId'] as String?)
        .handleError((_) {});
  }

  /// Publishes the chosen background so the partner's card follows along.
  /// MERGE so it never wipes the shared reminder fields. Best-effort: errors
  /// (offline, rules race during un-pairing…) are swallowed — the local Hive
  /// cache already holds the selection.
  Future<void> setCounterBg(String coupleId, String photoId) async {
    if (coupleId.trim().isEmpty || photoId.isEmpty || !isUsingFirebase) {
      return;
    }
    try {
      await _doc(coupleId).set(
        <String, Object?>{'counterBgPhotoId': photoId},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Fail-soft — sync catches up on the next successful write.
    }
  }

  /// Streams the couple-shared whitelist of photo ids allowed as the hero-card
  /// background (2026-06-14). Empty list / absent = no restriction (the card
  /// cycles through everything). Empty stream in the local fallback.
  Stream<List<String>> watchCounterBgIds(String coupleId) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return const Stream<List<String>>.empty();
    }
    return _doc(coupleId).snapshots().map((snapshot) {
      final raw = snapshot.data()?['counterBgPhotoIds'];
      return raw is List
          ? raw.whereType<String>().toList(growable: false)
          : const <String>[];
    }).handleError((_) {});
  }

  /// Publishes the background whitelist (merge, fail-soft). An empty list
  /// clears the restriction.
  Future<void> setCounterBgIds(String coupleId, List<String> photoIds) async {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return;
    }
    try {
      await _doc(coupleId).set(
        <String, Object?>{'counterBgPhotoIds': photoIds},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Fail-soft — sync catches up on the next successful write.
    }
  }

  /// Streams the couple-shared Chat-tab background photo key (2026-06-18). Null
  /// or '' means "no custom background" — the Chat tab keeps its gradient. Empty
  /// stream in the local fallback.
  Stream<String?> watchChatBg(String coupleId) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return const Stream<String?>.empty();
    }
    return _doc(coupleId).snapshots().map((snapshot) {
      final raw = snapshot.data()?['chatBgPhotoId'];
      return raw is String && raw.isNotEmpty ? raw : null;
    }).handleError((_) {});
  }

  /// Publishes the chosen Chat background so the partner's chat follows along.
  /// Pass an empty string to clear it (back to the gradient). MERGE so it never
  /// wipes the other shared fields. Best-effort — the Hive cache holds the pick.
  Future<void> setChatBg(String coupleId, String photoId) async {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return;
    }
    try {
      await _doc(coupleId).set(
        <String, Object?>{'chatBgPhotoId': photoId},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Fail-soft — sync catches up on the next successful write.
    }
  }

  /// Streams the couple-shared daily-question reminder prefs (enabled + the
  /// list of fire times as minutes-since-midnight). Either field is null when
  /// absent in Firestore. Empty stream in the local fallback.
  Stream<ReminderPrefs> watchReminderPrefs(String coupleId) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return const Stream<ReminderPrefs>.empty();
    }
    return _doc(coupleId).snapshots().map((snapshot) {
      final data = snapshot.data();
      final enabled = data?['dqReminderEnabled'];
      final rawTimes = data?['dqReminderTimes'];
      final times = rawTimes is List
          ? rawTimes.whereType<num>().map((n) => n.toInt()).toList()
          : null;
      return (
        enabled: enabled is bool ? enabled : null,
        times: times,
      );
    }).handleError((_) {});
  }

  /// Publishes the shared daily-question reminder prefs (merge). Best-effort.
  Future<void> setReminderPrefs(
    String coupleId, {
    bool? enabled,
    List<int>? times,
  }) async {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return;
    }
    final payload = <String, Object?>{
      'dqReminderEnabled': ?enabled,
      'dqReminderTimes': ?times,
    };
    if (payload.isEmpty) {
      return;
    }
    try {
      await _doc(coupleId).set(payload, SetOptions(merge: true));
    } catch (_) {
      // Fail-soft — sync catches up on the next successful write.
    }
  }
}
