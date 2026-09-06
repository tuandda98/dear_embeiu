import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/daily_questions.dart';
import '../models/daily_answer.dart';
import '../models/journal_day.dart';
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

  CollectionReference<Map<String, dynamic>> _dailyAnswers(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('dailyAnswers');

  CollectionReference<Map<String, dynamic>> _responses(
    String coupleId,
    String dateKey,
  ) => _dailyAnswers(coupleId).doc(dateKey).collection('responses');

  /// Counts revealed journal days (marker docs flagged `bothAnswered: true`) via
  /// a cheap server-side `count()` aggregation — one billed read, no documents
  /// downloaded. Used by the Profile "Nhật ký" badge so it can show a real
  /// number instead of an arrow. Returns 0 on the local fallback or on any
  /// error (missing index / offline) so the badge degrades gracefully.
  Future<int> countJournalEntries(String coupleId) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return 0;
    }
    try {
      final agg = await _dailyAnswers(
        coupleId,
      ).where('bothAnswered', isEqualTo: true).count().get();
      return agg.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Parses a 'YYYY-MM-DD' [dateKey] back to a date-only [DateTime] (local).
  /// Falls back to "now" when the key is malformed so a marker still gets a
  /// sensible question snapshot.
  static DateTime _dateFromKey(String dateKey) =>
      DateTime.tryParse(dateKey) ?? DateTime.now();

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
  ///
  /// [questionVi]/[questionEn]/[source] carry the question the card ACTUALLY
  /// showed (resolved by `QuestionEngine`, feature endless-questions). They are
  /// only used when the marker doesn't already hold a question — the marker is
  /// the source of truth and is never re-derived from the bank once written.
  /// Omitting them falls back to the legacy bank derivation.
  Future<void> submitAnswer({
    required String coupleId,
    required String dateKey,
    required String uid,
    required String text,
    String? questionVi,

    /// True when answering a PAST day from the catch-up gate. Persisted on the
    /// response so `notifyDailyAnswer` stamps the marker but skips the push/
    /// inbox/wake (copy says "hôm nay" and the wake would cancel the
    /// partner's nudges for the wrong day).
    bool backfill = false,
    String? questionEn,
    String? source,
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
      if (backfill) 'backfill': true,
    });

    // Write a parent marker doc so the journal can list the days that have any
    // answers (the responses subcollection alone leaves the parent "phantom" —
    // un-listable). The question text is snapshotted HERE, at the exact day it
    // was answered (PO decision A: never re-derive — the bank may shift later).
    //
    // ⚠️ Since the question engine (feature endless-questions) the marker is the
    // SOURCE OF TRUTH for what was asked: if it already carries a question we
    // must NOT overwrite it (the other phone may have resolved a template/AI
    // question that has no bank equivalent). We only fill it in when it's still
    // empty, preferring the text the card actually rendered.
    try {
      final markerRef = _dailyAnswers(coupleId).doc(dateKey);
      // Transaction (not get-then-set): an offline phone's queued write must
      // not overwrite the question the other phone published meanwhile — the
      // rule now rejects a changed questionVi/En anyway, and a rejected merge
      // would also drop the harmless `updatedAt` refresh.
      await markerRef.firestore.runTransaction<void>((tx) async {
        final existing = await tx.get(markerRef);
        final data = existing.data();
        final hasQuestion =
            (data?['questionVi'] as String?)?.trim().isNotEmpty == true &&
            (data?['questionEn'] as String?)?.trim().isNotEmpty == true;

        final payload = <String, Object?>{
          'date': dateKey,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (!hasQuestion) {
          final parsedDate = _dateFromKey(dateKey);
          final vi = questionVi?.trim();
          final en = questionEn?.trim();
          payload['questionVi'] = (vi != null && vi.isNotEmpty)
              ? vi
              : questionTextForCouple(parsedDate, coupleId, 'vi');
          payload['questionEn'] = (en != null && en.isNotEmpty)
              ? en
              : questionTextForCouple(parsedDate, coupleId, 'en');
          final src = source?.trim();
          payload['source'] = (src != null && src.isNotEmpty) ? src : 'bank';
        }
        tx.set(markerRef, payload, SetOptions(merge: true));
      });
    } catch (_) {
      // Transactions have no offline mutation queue: they fail immediately
      // without a network. Fall back to a queued merge so the marker (with
      // `date`, which the streak/journal queries need) still lands when the
      // phone is back online. The rule keeps this safe: if the other phone
      // published a different question meanwhile, the merge is simply denied.
      try {
        final parsedDate = _dateFromKey(dateKey);
        final vi = questionVi?.trim();
        final en = questionEn?.trim();
        final src = source?.trim();
        await _dailyAnswers(coupleId).doc(dateKey).set(<String, Object?>{
          'date': dateKey,
          'questionVi': (vi != null && vi.isNotEmpty)
              ? vi
              : questionTextForCouple(parsedDate, coupleId, 'vi'),
          'questionEn': (en != null && en.isNotEmpty)
              ? en
              : questionTextForCouple(parsedDate, coupleId, 'en'),
          'source': (src != null && src.isNotEmpty) ? src : 'bank',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Ignore — the answer itself is already saved; the marker is auxiliary.
      }
    }

    // Streak flag (feature streak, D-PO-2): once BOTH members have answered
    // today, stamp `bothAnswered`/`revealedAt` on the marker so StreakProvider
    // can list revealed days cheaply (filter client-side, no responses fan-out).
    //
    // ⚠️ This client-side write is now only a FAST PATH. The authoritative stamp
    // lives in the `notifyDailyAnswer` Cloud Function (2026-08-09), because this
    // one silently loses the day in two cases: both partners submitting at the
    // same moment (each client reads only its own doc, so neither sets the flag)
    // and a marker doc that doesn't exist yet (the member-write rule demands
    // date/questionVi/questionEn, so a merge carrying only `bothAnswered` is
    // DENIED). The CF uses the Admin SDK, which bypasses rules and reads after
    // both docs exist. Kept here so the streak still updates instantly in-app.
    // Best-effort: a failure must never fail answering.
    try {
      final responses = await _responses(coupleId, dateKey).get();
      // `responses` holds at most two docs (one per member). Both present →
      // today is revealed.
      if (responses.docs.length >= 2) {
        await _dailyAnswers(coupleId).doc(dateKey).set({
          'bothAnswered': true,
          'revealedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Ignore — the streak flag is auxiliary; the answer is already saved.
    }
  }

  /// Loads a page of revealed journal days for [coupleId], newest first.
  ///
  /// Lists `dailyAnswers` marker docs ordered by `date` desc (paged with
  /// [startAfter]/[limit]); for each marker reads its ≤2 `responses` and keeps
  /// ONLY days where BOTH members answered (= revealed). Returns the kept days
  /// plus a cursor ([JournalPage.lastDoc]) for the next page and whether more
  /// marker docs may remain ([JournalPage.hasMore]).
  ///
  /// Local fallback (no Firebase): journal is empty (markers are Firestore-only;
  /// PO-accepted for v1).
  Future<JournalPage> loadJournal({
    required String coupleId,
    required String myUid,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 30,
  }) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      return const JournalPage(days: [], lastDoc: null, hasMore: false);
    }

    Query<Map<String, dynamic>> query = _dailyAnswers(
      coupleId,
    ).orderBy('date', descending: true).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final markers = snapshot.docs;
    // hasMore is page-level: if this page filled the limit, another page MAY
    // exist (some markers may be filtered out, but there could still be more).
    final hasMore = markers.length == limit;

    // Read each day's responses in parallel (≤2 docs each).
    final futures = markers.map((marker) async {
      final data = marker.data();
      final responsesSnap = await _responses(coupleId, marker.id).get();
      final answers = responsesSnap.docs
          .map((d) => DailyAnswer.fromDoc(d.id, d.data()))
          .where((a) => a.hasText)
          .toList();

      // Only fully-revealed days (both members answered) become journal entries.
      DailyAnswer? mine;
      DailyAnswer? theirs;
      for (final a in answers) {
        if (a.authorUserId == myUid) {
          mine = a;
        } else {
          theirs = a;
        }
      }
      if (mine == null || theirs == null) {
        return null;
      }

      return JournalDay(
        date: (data['date'] as String?)?.trim().isNotEmpty == true
            ? data['date'] as String
            : marker.id,
        questionVi: data['questionVi'] as String? ?? '',
        questionEn: data['questionEn'] as String? ?? '',
        myAnswer: mine.text,
        partnerAnswer: theirs.text,
        partnerUid: theirs.authorUserId,
      );
    }).toList();

    final resolved = await Future.wait(futures);
    final days = resolved.whereType<JournalDay>().toList();

    return JournalPage(
      days: days,
      lastDoc: markers.isEmpty ? null : markers.last,
      hasMore: hasMore,
    );
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

/// One page of journal results from [DailyQuestionService.loadJournal].
class JournalPage {
  /// Revealed days in this page (newest first).
  final List<JournalDay> days;

  /// Cursor for the next page — pass as `startAfter`. Null when no markers were
  /// read (end of list).
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  /// Whether another page of marker docs may exist (this page filled `limit`).
  final bool hasMore;

  const JournalPage({
    required this.days,
    required this.lastDoc,
    required this.hasMore,
  });
}
