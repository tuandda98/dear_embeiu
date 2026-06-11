import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_bootstrap_service.dart';

/// Shared Home preferences the couple co-owns, stored in ONE tiny doc
/// (`couples/{coupleId}/prefs/home`). Currently a single field:
/// `counterBgPhotoId` — which photo backs the hero counter card — so a swipe
/// on either phone picks the same backdrop for both.
///
/// Fail-soft by design: without Firebase (local fallback) the watch emits
/// nothing and writes are dropped — the Hive cache in HomeScreen keeps the
/// device-local behavior alive.
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
  /// Best-effort: errors (offline, rules race during un-pairing…) are
  /// swallowed — the local Hive cache already holds the selection.
  Future<void> setCounterBg(String coupleId, String photoId) async {
    if (coupleId.trim().isEmpty || photoId.isEmpty || !isUsingFirebase) {
      return;
    }
    try {
      await _doc(coupleId).set(<String, Object?>{'counterBgPhotoId': photoId});
    } catch (_) {
      // Fail-soft — sync catches up on the next successful write.
    }
  }
}
