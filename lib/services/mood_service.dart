import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/mood.dart';
import 'firebase_bootstrap_service.dart';

/// Reads/writes the couple's daily moods (feature mood):
/// `couples/{coupleId}/moods/{authorUserId}` — one doc per member, overwritten
/// each day. Both members read each other's so the Home card can show "how is
/// your person feeling today".
///
/// Local fallback (no Firebase / guest): only MY mood lives in a Hive box on
/// this device (there is no partner to sync with), so the card stays usable
/// instead of dead — same recipe as ChatService's local history.
class MoodService {
  MoodService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _localBoxName = 'moods_local';

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _moodsCollection(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('moods');

  /// Streams every mood doc of the couple (≤ 2), keyed by author uid. Local
  /// fallback emits this device's stored mood once.
  Stream<Map<String, Mood>> watchMoods(String coupleId) {
    if (coupleId.trim().isEmpty) {
      return Stream<Map<String, Mood>>.value(const <String, Mood>{});
    }
    if (!isUsingFirebase) {
      return Stream<Map<String, Mood>>.fromFuture(_loadLocal(coupleId));
    }
    return _moodsCollection(coupleId).snapshots().map((snapshot) {
      final byUid = <String, Mood>{};
      for (final doc in snapshot.docs) {
        final mood = Mood.fromDoc(doc.id, doc.data());
        if (mood.mood.isNotEmpty) {
          byUid[mood.authorUserId] = mood;
        }
      }
      return byUid;
    });
  }

  /// Sets MY mood for [dateKey] (doc id == [uid]). No-ops on invalid input.
  Future<void> setMood({
    required String coupleId,
    required String uid,
    required String mood,
    required String note,
    required String dateKey,
  }) async {
    if (coupleId.trim().isEmpty ||
        uid.trim().isEmpty ||
        moodOptionFor(mood) == null) {
      return;
    }
    final trimmedNote = note.trim();
    final clampedNote = trimmedNote.length > kMoodNoteMaxLength
        ? trimmedNote.substring(0, kMoodNoteMaxLength)
        : trimmedNote;

    if (!isUsingFirebase) {
      await _saveLocal(coupleId, uid, mood, clampedNote, dateKey);
      return;
    }

    await _moodsCollection(coupleId).doc(uid).set(
      {
        'authorUserId': uid,
        'mood': mood,
        'note': clampedNote,
        'date': dateKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── Local fallback (Hive) ──────────────────────────────────────────────────
  Future<Box<dynamic>> _openLocalBox() => Hive.openBox<dynamic>(_localBoxName);

  Future<void> _saveLocal(
    String coupleId,
    String uid,
    String mood,
    String note,
    String dateKey,
  ) async {
    try {
      final box = await _openLocalBox();
      await box.put('$coupleId:$uid', {
        'authorUserId': uid,
        'mood': mood,
        'note': note,
        'date': dateKey,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Best-effort: ignore local persistence failures.
    }
  }

  Future<Map<String, Mood>> _loadLocal(String coupleId) async {
    try {
      final box = await _openLocalBox();
      final byUid = <String, Mood>{};
      for (final key in box.keys) {
        if (key is String && key.startsWith('$coupleId:')) {
          final raw = box.get(key);
          if (raw is Map) {
            final mood = Mood.fromJson(Map<String, dynamic>.from(raw));
            if (mood.mood.isNotEmpty) {
              byUid[mood.authorUserId] = mood;
            }
          }
        }
      }
      return byUid;
    } catch (_) {
      return const <String, Mood>{};
    }
  }
}
