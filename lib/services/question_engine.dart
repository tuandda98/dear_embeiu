import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/daily_questions.dart';
import '../data/question_templates.dart';
import 'bank_question_source.dart';
import 'daily_question_service.dart';
import 'firebase_bootstrap_service.dart';
import 'question_source.dart';
import 'question_state_service.dart';
import 'template_question_source.dart';

/// The question resolved for one day — what the card renders and what the
/// journal will keep.
class ResolvedQuestion {
  const ResolvedQuestion({
    required this.questionVi,
    required this.questionEn,
    required this.source,
    this.hintVi,
    this.hintEn,
    this.refDate,
    this.templateKey,
    this.questionId,
  });

  final String questionVi;
  final String questionEn;

  /// 'bank' | 'template' | 'revisit' | 'ai'.
  final String source;

  /// Optional per-user hint (never persisted on the marker).
  final String? hintVi;
  final String? hintEn;

  /// 'YYYY-MM-DD' of the revisited day (source == 'revisit').
  final String? refDate;

  /// Template key (source == 'template').
  final String? templateKey;

  /// Bank index (source == 'bank').
  final int? questionId;

  String textFor(String langCode) =>
      langCode.trim().toLowerCase().startsWith('vi')
      ? (questionVi.isNotEmpty ? questionVi : questionEn)
      : (questionEn.isNotEmpty ? questionEn : questionVi);

  String? hintFor(String langCode) {
    final vi = hintVi?.trim();
    final en = hintEn?.trim();
    final wantVi = langCode.trim().toLowerCase().startsWith('vi');
    final picked = wantVi ? (vi ?? en) : (en ?? vi);
    return (picked == null || picked.isEmpty) ? null : picked;
  }
}

/// One entry in the resolution plan: a source key plus, for the template
/// source, the group it must draw from.
class _Step {
  const _Step(this.key, {this.group});

  final String key;
  final String? group;

  String get id => group == null ? key : '$key:$group';
}

class _Registered {
  _Registered(this.source, this.priority, this.seq);

  final QuestionSource source;
  final int priority;
  final int seq;
}

/// Resolves ONE question per couple per day and snapshots it on the day marker
/// (`couples/{coupleId}/dailyAnswers/{date}`), which is the SOURCE OF TRUTH:
/// whichever phone resolves first writes it, the other one reads it. That is
/// what lets the question depend on live data (mood, streak, photos, history)
/// while both partners still always see the exact same prompt.
///
/// Resolution order for a day:
///   1. 'ai' when the couple opted in (`prefs/home.aiQuestionsEnabled`),
///   2. any source registered with `priority > 0`, highest first,
///   3. calendar/context overrides (holidays, anniversary milestone, month
///      edges, streak milestone, photo-less weekend, partner's mood),
///   4. the weekday rotation — Mon template(week_start) · Tue bank ·
///      Wed template(feeling) · Thu bank · Fri revisit · Sat bank ·
///      Sun template(week_recap),
///   5. always [template, bank] as a final fallback.
///
/// Every step is fail-soft: an unregistered source is skipped, a source that
/// throws or returns null passes, and a marker/state write failure never blocks
/// the card.
class QuestionEngine {
  QuestionEngine({
    List<QuestionSource> sources = const <QuestionSource>[],
    FirebaseFirestore? firestore,
    QuestionStateService? stateService,
  }) : _firestore = firestore,
       _stateService =
           stateService ?? QuestionStateService(firestore: firestore) {
    for (final source in sources) {
      registerSource(source);
    }
  }

  /// The default stack used by [DailyQuestionProvider]: templates first (they
  /// only fire when the context calls for it), bank as the safety net. The
  /// coordinator registers 'revisit' / 'ai' on top.
  factory QuestionEngine.withDefaults({
    FirebaseFirestore? firestore,
    QuestionStateService? stateService,
  }) => QuestionEngine(
    sources: const <QuestionSource>[
      TemplateQuestionSource(),
      BankQuestionSource(),
    ],
    firestore: firestore,
    stateService: stateService,
  );

  final FirebaseFirestore? _firestore;
  final QuestionStateService _stateService;
  final List<_Registered> _sources = <_Registered>[];
  int _seq = 0;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Registers [s]; a higher [priority] runs earlier. Re-registering the same
  /// key replaces the previous instance.
  void registerSource(QuestionSource s, {int priority = 0}) {
    _sources.removeWhere((r) => r.source.key == s.key);
    _sources.add(_Registered(s, priority, _seq++));
  }

  /// Whether a source with [key] is registered.
  bool hasSource(String key) => _sources.any((r) => r.source.key == key);

  QuestionSource? _sourceFor(String key) {
    for (final r in _sources) {
      if (r.source.key == key) {
        return r.source;
      }
    }
    return null;
  }

  /// Resolves today's shared question. Never throws: the worst case is the
  /// legacy bank fallback.
  Future<ResolvedQuestion> resolveToday({
    required String coupleId,
    required String myUid,
    required String partnerUid,
    required DateTime date,
    required String languageCode,
    required DateTime anniversaryDate,
    required int currentStreak,
    int photosThisWeek = 0,
    String? myMoodToday,
    String? partnerMoodToday,
  }) async {
    final dateKey = DailyQuestionService.dateKey(date);

    // (a) No Firebase / no couple → legacy deterministic bank, no writes.
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return _legacyFallback(coupleId, date);
    }

    final markerRef = _db
        .collection('couples')
        .doc(coupleId)
        .collection('dailyAnswers')
        .doc(dateKey);

    // (b) Marker already carries the question → both phones use it verbatim.
    try {
      final existing = await markerRef.get();
      var resolved = _fromMarker(existing.data());
      if (resolved != null &&
          resolved.source == 'revisit' &&
          (resolved.refDate ?? '').isNotEmpty) {
        // The other phone (or a restart) only has the marker: rebuild the
        // per-user "back then you wrote…" hint from refDate.
        resolved = await _withRevisitHint(resolved, existing.reference, myUid);
      }
      if (resolved != null) {
        return resolved;
      }
    } catch (_) {
      // Offline/denied → keep going; we can still propose a question locally.
    }

    // (c) Couple memory + AI opt-in.
    final state = await _stateService.load(coupleId);
    final aiEnabled = await _readAiEnabled(coupleId);

    // (d) Build the context and walk the plan.
    final ctx = QuestionContext(
      coupleId: coupleId,
      myUid: myUid,
      partnerUid: partnerUid,
      date: DateTime(date.year, date.month, date.day),
      dateKey: dateKey,
      languageCode: languageCode,
      anniversaryDate: anniversaryDate,
      currentStreak: currentStreak,
      photosThisWeek: photosThisWeek,
      myMoodToday: myMoodToday,
      partnerMoodToday: partnerMoodToday,
      askedBankIds: state.askedBankIds,
      recentTemplateKeys: state.recentTemplateKeys,
      recentRevisitDates: state.recentRevisitDates,
      aiEnabled: aiEnabled,
    );

    QuestionCandidate? candidate;
    for (final step in _plan(ctx)) {
      candidate = await _ask(step, ctx);
      if (candidate != null) {
        break;
      }
    }
    candidate ??= BankQuestionSource.pick(
      coupleId: coupleId,
      dateKey: dateKey,
      askedBankIds: ctx.askedBankIds,
    );
    if (candidate == null) {
      return _legacyFallback(coupleId, date);
    }

    // (e) Publish on the marker — first writer wins, the loser adopts theirs.
    final winner = await _publish(markerRef, dateKey, candidate);
    if (winner != null) {
      return winner;
    }

    // (f) Remember what we used (best-effort, never blocks).
    unawaited(
      _stateService.record(
        coupleId: coupleId,
        current: state,
        bankId: candidate.source == 'bank' ? candidate.questionId : null,
        templateKey: candidate.templateKey,
        revisitDate: candidate.refDate,
      ),
    );

    return ResolvedQuestion(
      questionVi: candidate.questionVi,
      questionEn: candidate.questionEn,
      source: candidate.source,
      hintVi: candidate.hintVi,
      hintEn: candidate.hintEn,
      refDate: candidate.refDate,
      templateKey: candidate.templateKey,
      questionId: candidate.questionId,
    );
  }

  // ── Plan ─────────────────────────────────────────────────────────────────

  /// The ordered resolution plan for [ctx]. Exposed (visible for tests) so the
  /// weekday/override schedule can be asserted without touching Firestore.
  List<String> planFor(QuestionContext ctx) =>
      _plan(ctx).map((s) => s.id).toList();

  List<_Step> _plan(QuestionContext ctx) {
    final steps = <_Step>[];

    if (ctx.aiEnabled) {
      steps.add(const _Step('ai'));
    }

    final boosted = _sources.where((r) => r.priority > 0).toList()
      ..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        return byPriority != 0 ? byPriority : a.seq.compareTo(b.seq);
      });
    for (final r in boosted) {
      steps.add(_Step(r.source.key));
    }

    for (final group in TemplateQuestionSource.overrideGroupsFor(ctx)) {
      steps.add(_Step('template', group: group));
    }

    steps.add(_weekdayStep(ctx.date));
    steps.add(const _Step('template'));
    steps.add(const _Step('bank'));

    final seen = <String>{};
    return steps.where((s) => seen.add(s.id)).toList();
  }

  _Step _weekdayStep(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return const _Step('template', group: kTplGroupWeekStart);
      case DateTime.wednesday:
        return const _Step('template', group: kTplGroupFeeling);
      case DateTime.friday:
        return const _Step('revisit');
      case DateTime.sunday:
        return const _Step('template', group: kTplGroupWeekRecap);
      default:
        // Tue / Thu / Sat.
        return const _Step('bank');
    }
  }

  Future<QuestionCandidate?> _ask(_Step step, QuestionContext ctx) async {
    final source = _sourceFor(step.key);
    if (source == null) {
      return null;
    }
    try {
      if (step.group != null && source is TemplateQuestionSource) {
        return await source.proposeGroup(ctx, step.group!);
      }
      return await source.propose(ctx);
    } catch (_) {
      return null;
    }
  }

  // ── Firestore ────────────────────────────────────────────────────────────

  Future<bool> _readAiEnabled(String coupleId) async {
    try {
      final snapshot = await _db
          .collection('couples')
          .doc(coupleId)
          .collection('prefs')
          .doc('home')
          .get();
      return snapshot.data()?['aiQuestionsEnabled'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Reads MY answer of [ResolvedQuestion.refDate] and attaches it as the
  /// hint (never persisted — it is personal to this user). Fail-soft.
  Future<ResolvedQuestion> _withRevisitHint(
    ResolvedQuestion base,
    DocumentReference<Map<String, dynamic>> markerRef,
    String myUid,
  ) async {
    try {
      final snap = await markerRef.parent
          .doc(base.refDate!)
          .collection('responses')
          .doc(myUid)
          .get()
          .timeout(const Duration(seconds: 4));
      final text = (snap.data()?['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) {
        return base;
      }
      final short = text.length > 80 ? '${text.substring(0, 80)}…' : text;
      return ResolvedQuestion(
        questionVi: base.questionVi,
        questionEn: base.questionEn,
        source: base.source,
        refDate: base.refDate,
        templateKey: base.templateKey,
        questionId: base.questionId,
        hintVi: 'Hồi đó bạn viết: "$short"',
        hintEn: 'Back then you wrote: "$short"',
      );
    } catch (_) {
      return base;
    }
  }

  ResolvedQuestion? _fromMarker(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final vi = (data['questionVi'] as String?)?.trim() ?? '';
    final en = (data['questionEn'] as String?)?.trim() ?? '';
    if (vi.isEmpty || en.isEmpty) {
      return null;
    }
    final rawId = data['questionId'];
    return ResolvedQuestion(
      questionVi: vi,
      questionEn: en,
      source: (data['source'] as String?)?.trim().isNotEmpty == true
          ? data['source'] as String
          : 'bank',
      refDate: (data['refDate'] as String?)?.trim(),
      templateKey: (data['templateKey'] as String?)?.trim(),
      questionId: rawId is int ? rawId : (rawId is num ? rawId.toInt() : null),
    );
  }

  /// Writes the candidate onto the marker in a transaction. Returns the OTHER
  /// phone's question when it got there first, or null when we won (or when the
  /// write failed — the caller then just uses its own candidate locally).
  Future<ResolvedQuestion?> _publish(
    DocumentReference<Map<String, dynamic>> markerRef,
    String dateKey,
    QuestionCandidate candidate,
  ) async {
    try {
      return await _db.runTransaction<ResolvedQuestion?>((tx) async {
        final snapshot = await tx.get(markerRef);
        final theirs = _fromMarker(snapshot.data());
        if (theirs != null) {
          return theirs;
        }
        tx.set(markerRef, <String, Object?>{
          'date': dateKey,
          'questionVi': candidate.questionVi,
          'questionEn': candidate.questionEn,
          'source': candidate.source,
          ...candidate.markerExtras,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return null;
      });
    } catch (_) {
      // Offline / rules race: keep the locally chosen question. The marker will
      // be written again by `submitAnswer` when the user answers.
      return null;
    }
  }

  ResolvedQuestion _legacyFallback(String coupleId, DateTime date) {
    final entry = questionForCouple(date, coupleId, 'vi');
    return ResolvedQuestion(
      questionVi: entry['vi'] ?? '',
      questionEn: entry['en'] ?? '',
      source: 'bank',
    );
  }
}
