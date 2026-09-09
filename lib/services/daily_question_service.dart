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
  ) =>
      _dailyAnswers(coupleId).doc(dateKey).collection('responses');

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

    // Write a parent marker doc so the journal can list the days that have any
    // answers (the responses subcollection alone leaves the parent "phantom" —
    // un-listable). The question text is snapshotted HERE, from the bank, at the
    // exact day it was answered (PO decision A: never re-derive — the bank may
    // shift later). Best-effort: a marker failure must not fail answering.
    final parsedDate = _dateFromKey(dateKey);
    var markerWritten = true;
    try {
      await _dailyAnswers(coupleId).doc(dateKey).set({
        'date': dateKey,
        'questionVi': questionTextForCouple(parsedDate, coupleId, 'vi'),
        'questionEn': questionTextForCouple(parsedDate, coupleId, 'en'),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Ignore — the answer itself is already saved; the marker is auxiliary.
      markerWritten = false;
    }

    // Streak flag (feature streak, D-PO-2): once BOTH members have answered
    // today, stamp `bothAnswered`/`revealedAt` on the marker so StreakProvider
    // can list revealed days cheaply (filter client-side, no responses fan-out).
    // Best-effort: a failure must never fail answering — and it no longer loses
    // the day for good either, [ensureRevealMarker]/[healRevealMarkers] re-run
    // the same check later (see the self-heal note there).
    await ensureRevealMarker(
      coupleId: coupleId,
      dateKey: dateKey,
      // Marker just written → its fields are known; passing them skips a read
      // AND keeps the day's question snapshot untouched. If that write failed,
      // pass nothing so the marker is re-read (and re-created if need be).
      markerData: markerWritten
          ? {
              'date': dateKey,
              'questionVi': questionTextForCouple(parsedDate, coupleId, 'vi'),
              'questionEn': questionTextForCouple(parsedDate, coupleId, 'en'),
            }
          : null,
    );
  }

  // ── Streak marker self-heal ───────────────────────────────────────────────
  // The `bothAnswered` flag used to be written exactly ONCE — by whoever
  // answered second, in the same call that saved their answer. Any hiccup at
  // that instant (app killed, connection dropped, the `responses` read served
  // from an offline cache that hadn't seen the partner's answer yet) left the
  // day flagless FOREVER: both partners had answered, but the streak skipped
  // the day and the chain broke. Nothing ever re-checked. These two methods are
  // that missing re-check — the flag is derived data, so we recompute it from
  // the responses (the source of truth) whenever we look at a day again.

  /// Makes sure [dateKey]'s marker carries `bothAnswered` when both members
  /// really did answer. Returns true when it repaired the marker.
  ///
  /// Pass [markerData] when the caller already holds the marker's fields (from
  /// a query snapshot or a write it just made) to skip a read — importantly,
  /// that also preserves the marker's ORIGINAL `questionVi`/`questionEn`
  /// snapshot (decision A: never re-derive a past day's question). The bank is
  /// consulted only when the marker is missing those fields entirely, since the
  /// security rule requires them on every marker write.
  ///
  /// Fail-soft: returns false on any error — a repair is never worth breaking a
  /// caller over.
  Future<bool> ensureRevealMarker({
    required String coupleId,
    required String dateKey,
    Map<String, dynamic>? markerData,
  }) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty || dateKey.trim().isEmpty) {
      return false;
    }

    try {
      var data = markerData;
      if (data == null) {
        final marker = await _dailyAnswers(coupleId).doc(dateKey).get();
        data = marker.data();
      }
      if (data != null && data['bothAnswered'] == true) {
        return false; // Already revealed — nothing to heal.
      }

      final responses = await _responses(coupleId, dateKey).get();
      final answered = responses.docs.where((doc) {
        final text = doc.data()['text'] as String?;
        return text != null && text.trim().isNotEmpty;
      }).length;
      // At most two docs (one per member). Both present → the day is revealed.
      if (answered < 2) {
        return false;
      }

      await _dailyAnswers(coupleId)
          .doc(dateKey)
          .set(_revealPayload(coupleId, dateKey, data), SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Re-checks recent marker docs and repairs every day that both members
  /// answered but that never got flagged — i.e. mends a streak broken by a lost
  /// flag rather than by a missed day.
  ///
  /// Scans the newest [scanLimit] markers, considers only the last
  /// [withinDays] days (an older gap is history, not the live chain) and
  /// follows at most [maxChecks] flagless days into their `responses`, so the
  /// scan can never fan out into an unbounded pile of reads. Already-flagged
  /// days cost nothing extra — they're read as part of the marker page.
  ///
  /// Returns how many days it healed. Fail-soft: 0 on any error.
  Future<int> healRevealMarkers({
    required String coupleId,
    int withinDays = 90,
    int scanLimit = 120,
    int maxChecks = 25,
  }) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return 0;
    }

    try {
      final snapshot = await _dailyAnswers(coupleId)
          .orderBy('date', descending: true)
          .limit(scanLimit)
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final cutoff = today.subtract(Duration(days: withinDays));

      var checked = 0;
      var healed = 0;
      for (final marker in snapshot.docs) {
        if (checked >= maxChecks) {
          break;
        }
        final data = marker.data();
        if (data['bothAnswered'] == true) {
          continue;
        }
        final key = (data['date'] as String?)?.trim();
        final dateKey = (key != null && key.isNotEmpty) ? key : marker.id;
        final parsed = DateTime.tryParse(dateKey);
        if (parsed == null) {
          continue;
        }
        if (DateTime(parsed.year, parsed.month, parsed.day).isBefore(cutoff)) {
          // Markers come back newest-first → everything after this is older too.
          break;
        }
        checked++;
        if (await ensureRevealMarker(
          coupleId: coupleId,
          dateKey: dateKey,
          markerData: data,
        )) {
          healed++;
        }
      }
      return healed;
    } catch (_) {
      return 0;
    }
  }

  /// The marker fields to write when flagging a day revealed. Keeps the day's
  /// existing question snapshot when it has one; only a marker missing those
  /// fields gets them re-derived from the bank, because the security rule
  /// requires `date`/`questionVi`/`questionEn` to be present on every write.
  Map<String, dynamic> _revealPayload(
    String coupleId,
    String dateKey,
    Map<String, dynamic>? existing,
  ) {
    final payload = <String, dynamic>{
      'bothAnswered': true,
      'revealedAt': FieldValue.serverTimestamp(),
    };

    bool hasText(String field) =>
        (existing?[field] as String?)?.trim().isNotEmpty == true;

    if (!hasText('date') || !hasText('questionVi') || !hasText('questionEn')) {
      final parsedDate = _dateFromKey(dateKey);
      payload['date'] = dateKey;
      payload['questionVi'] = hasText('questionVi')
          ? existing!['questionVi']
          : questionTextForCouple(parsedDate, coupleId, 'vi');
      payload['questionEn'] = hasText('questionEn')
          ? existing!['questionEn']
          : questionTextForCouple(parsedDate, coupleId, 'en');
    }

    return payload;
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
    if (!isUsingFirebase ||
        coupleId.trim().isEmpty ||
        myUid.trim().isEmpty) {
      return const JournalPage(days: [], lastDoc: null, hasMore: false);
    }

    Query<Map<String, dynamic>> query =
        _dailyAnswers(coupleId).orderBy('date', descending: true).limit(limit);
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
      final responsesSnap =
          await _responses(coupleId, marker.id).get();
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
