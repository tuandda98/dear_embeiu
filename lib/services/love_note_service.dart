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
  static const String _localHistoryBoxName = 'love_note_history_local';

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notesCollection(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('notes');

  CollectionReference<Map<String, dynamic>> _historyCollection(
          String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('noteHistory');

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

  /// Appends an immutable entry to the couple's note history (the timeline of
  /// every note ever sent). Additive to [setMyNote] — the latest-note surface
  /// is unchanged. Caller is expected to skip no-op/unchanged saves. Empty text
  /// is ignored (the security rule requires a non-empty string).
  Future<void> appendHistory({
    required String coupleId,
    required String uid,
    required String text,
  }) async {
    final trimmed = text.trim();
    final clamped = trimmed.length > 140 ? trimmed.substring(0, 140) : trimmed;
    if (coupleId.trim().isEmpty || uid.trim().isEmpty || clamped.isEmpty) {
      return;
    }

    if (!isUsingFirebase) {
      await _appendLocalHistory(coupleId, uid, clamped);
      return;
    }

    await _historyCollection(coupleId).add({
      'authorUserId': uid,
      'text': clamped,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams the couple's note history newest-first (capped at [limit] — the
  /// realtime "window", pagination D5; older entries are fetched on demand via
  /// [fetchOlderHistory]). Maps the `createdAt` field into [LoveNote.updatedAt]
  /// so the archive can reuse the same model + relative-time formatting as the
  /// live notes.
  Stream<List<LoveNote>> watchHistory(String coupleId, {int limit = 50}) {
    if (coupleId.trim().isEmpty) {
      return Stream<List<LoveNote>>.value(const <LoveNote>[]);
    }

    if (!isUsingFirebase) {
      return Stream<List<LoveNote>>.fromFuture(_loadLocalHistory(coupleId));
    }

    return _historyCollection(coupleId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_historyNoteFromDoc).toList(),
        );
  }

  /// One-shot page of history entries strictly older than
  /// [startAfterCreatedAt], newest first (pagination D5). `createdAt` is a
  /// server Timestamp; [LoveNote.updatedAt] reads it back with microsecond
  /// precision, so `Timestamp.fromDate` reconstructs the exact cursor.
  /// Local mode has no pagination (the archive is loaded whole) → empty.
  Future<List<LoveNote>> fetchOlderHistory(
    String coupleId, {
    required DateTime startAfterCreatedAt,
    int limit = 50,
  }) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return const <LoveNote>[];
    }

    final snapshot = await _historyCollection(coupleId)
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(startAfterCreatedAt)])
        .limit(limit)
        .get();
    return snapshot.docs.map(_historyNoteFromDoc).toList();
  }

  LoveNote _historyNoteFromDoc(
          QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      LoveNote.fromDoc(doc.id, {
        'authorUserId': doc.data()['authorUserId'],
        'text': doc.data()['text'],
        'updatedAt': doc.data()['createdAt'],
      });

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

  // ── Local fallback history ─────────────────────────────────────────────
  // Append-only list per couple, keyed "{coupleId}:{isoTimestamp}". Best-effort.

  Future<Box<dynamic>> _openLocalHistoryBox() =>
      Hive.openBox<dynamic>(_localHistoryBoxName);

  Future<void> _appendLocalHistory(
      String coupleId, String uid, String text) async {
    try {
      final box = await _openLocalHistoryBox();
      final now = DateTime.now();
      await box.put('$coupleId:${now.toIso8601String()}', {
        'authorUserId': uid,
        'text': text,
        'createdAt': now.toIso8601String(),
      });
    } catch (_) {
      // Best-effort: ignore local persistence failures.
    }
  }

  Future<List<LoveNote>> _loadLocalHistory(String coupleId) async {
    try {
      final box = await _openLocalHistoryBox();
      final entries = <LoveNote>[];
      for (final key in box.keys) {
        if (key is String && key.startsWith('$coupleId:')) {
          final raw = box.get(key);
          if (raw is Map) {
            final data = Map<String, dynamic>.from(raw);
            entries.add(LoveNote(
              authorUserId: data['authorUserId'] as String? ?? '',
              text: data['text'] as String? ?? '',
              updatedAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
            ));
          }
        }
      }
      entries.sort((a, b) => (b.updatedAt ?? DateTime(0))
          .compareTo(a.updatedAt ?? DateTime(0)));
      return entries;
    } catch (_) {
      return const <LoveNote>[];
    }
  }
}
