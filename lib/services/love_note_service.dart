import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/love_note.dart';
import 'firebase_bootstrap_service.dart';

/// Reads/writes the per-couple "love notes" subcollection
/// (`couples/{coupleId}/notes/{authorUserId}` — one doc per member).
///
/// When Firebase isn't available (local fallback) it degrades gracefully to a
/// Hive-backed local store so writing/reading the user's own note never
/// crashes. The local store can only ever hold this device's own note (there
/// is no partner sync without Firebase), which is enough to keep the UI alive.
class LoveNoteService {
  LoveNoteService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _localBoxName = 'love_notes_local';

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notesCollection(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('notes');

  /// Streams both members' notes for [coupleId] (at most two documents).
  ///
  /// In the local fallback this emits the single locally stored note (if any)
  /// so the UI has something to render without throwing.
  Stream<List<LoveNote>> watchNotes(String coupleId) {
    if (coupleId.trim().isEmpty) {
      return Stream<List<LoveNote>>.value(const <LoveNote>[]);
    }

    if (!isUsingFirebase) {
      return Stream<List<LoveNote>>.fromFuture(_loadLocalNotes(coupleId));
    }

    return _notesCollection(coupleId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => LoveNote.fromDoc(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Creates or overwrites the current user's note (doc id == [uid]).
  /// [text] is trimmed and clamped to 140 chars to match the security rule.
  Future<void> setMyNote({
    required String coupleId,
    required String uid,
    required String text,
  }) async {
    final trimmed = text.trim();
    final clamped = trimmed.length > 140 ? trimmed.substring(0, 140) : trimmed;

    if (coupleId.trim().isEmpty || uid.trim().isEmpty) {
      return;
    }

    if (!isUsingFirebase) {
      await _saveLocalNote(coupleId, uid, clamped);
      return;
    }

    await _notesCollection(coupleId).doc(uid).set(
      {
        'authorUserId': uid,
        'text': clamped,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── Local fallback (Hive) ──────────────────────────────────────────────
  // Stores only this device's own note, keyed by "{coupleId}:{uid}". Any
  // failure is swallowed so the feature never crashes without Firebase.

  Future<Box<dynamic>> _openLocalBox() => Hive.openBox<dynamic>(_localBoxName);

  Future<List<LoveNote>> _loadLocalNotes(String coupleId) async {
    try {
      final box = await _openLocalBox();
      final notes = <LoveNote>[];
      for (final key in box.keys) {
        if (key is String && key.startsWith('$coupleId:')) {
          final raw = box.get(key);
          if (raw is Map) {
            notes.add(LoveNote.fromJson(Map<String, dynamic>.from(raw)));
          }
        }
      }
      return notes;
    } catch (_) {
      return const <LoveNote>[];
    }
  }

  Future<void> _saveLocalNote(String coupleId, String uid, String text) async {
    try {
      final box = await _openLocalBox();
      await box.put('$coupleId:$uid', {
        'authorUserId': uid,
        'text': text,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Best-effort: ignore local persistence failures.
    }
  }
}
