import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/daily_answer.dart';
import 'firebase_bootstrap_service.dart';

/// Reads/writes the per-couple, per-day "daily question" answers
/// (`couples/{coupleId}/dailyAnswers/{date}/responses/{authorUserId}` — at most
/// two docs per day, one per member; the doc id IS the author's uid).
///
/// When Firebase isn't available (local fallback) it degrades gracefully to a
/// Hive-backed local store so answering never crashes. The local store can only
/// hold this device's own answer (there's no partner sync without Firebase),
/// which is enough to keep the UI alive.
class DailyQuestionService {
  DailyQuestionService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _localBoxName = 'daily_answers_local';

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// 'YYYY-MM-DD' for the given device-local date — the day bucket both
  /// partners share (LDR across time zones may differ; accepted for v1).
  static String dateKey(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  CollectionReference<Map<String, dynamic>> _responses(
    String coupleId,
    String dateKey,
  ) =>
      _db
          .collection('couples')
          .doc(coupleId)
          .collection('dailyAnswers')
          .doc(dateKey)
          .collection('responses');

  /// Streams both members' answers for [coupleId] on [dateKey] (≤ 2 docs).
  ///
  /// In the local fallback this emits the single locally stored answer (if any)
  /// so the UI has something to render without throwing.
  Stream<List<DailyAnswer>> watchResponses(String coupleId, String dateKey) {
    if (coupleId.trim().isEmpty || dateKey.trim().isEmpty) {
      return Stream<List<DailyAnswer>>.value(const <DailyAnswer>[]);
    }

    if (!isUsingFirebase) {
      return Stream<List<DailyAnswer>>.fromFuture(
        _loadLocalAnswers(coupleId, dateKey),
      );
    }

    return _responses(coupleId, dateKey).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => DailyAnswer.fromDoc(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Records the current user's answer for [dateKey] (doc id == [uid]).
  /// [text] is trimmed and clamped to 280 chars to match the security rule.
  Future<void> submitAnswer({
    required String coupleId,
    required String dateKey,
    required String uid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty ||
        coupleId.trim().isEmpty ||
        dateKey.trim().isEmpty ||
        uid.trim().isEmpty) {
      return;
    }
    final clamped = trimmed.length > 280 ? trimmed.substring(0, 280) : trimmed;

    if (!isUsingFirebase) {
      await _saveLocalAnswer(coupleId, dateKey, uid, clamped);
      return;
    }

    await _responses(coupleId, dateKey).doc(uid).set({
      'authorUserId': uid,
      'text': clamped,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Local fallback (Hive) ──────────────────────────────────────────────
  // Stores only this device's own answer, keyed by "{coupleId}:{dateKey}:{uid}".
  // Any failure is swallowed so the feature never crashes without Firebase.

  Future<Box<dynamic>> _openLocalBox() => Hive.openBox<dynamic>(_localBoxName);

  Future<List<DailyAnswer>> _loadLocalAnswers(
    String coupleId,
    String dateKey,
  ) async {
    try {
      final box = await _openLocalBox();
      final prefix = '$coupleId:$dateKey:';
      final answers = <DailyAnswer>[];
      for (final key in box.keys) {
        if (key is String && key.startsWith(prefix)) {
          final raw = box.get(key);
          if (raw is Map) {
            answers.add(DailyAnswer.fromJson(Map<String, dynamic>.from(raw)));
          }
        }
      }
      return answers;
    } catch (_) {
      return const <DailyAnswer>[];
    }
  }

  Future<void> _saveLocalAnswer(
    String coupleId,
    String dateKey,
    String uid,
    String text,
  ) async {
    try {
      final box = await _openLocalBox();
      await box.put('$coupleId:$dateKey:$uid', {
        'authorUserId': uid,
        'text': text,
        'answeredAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Best-effort: ignore local persistence failures.
    }
  }
}
