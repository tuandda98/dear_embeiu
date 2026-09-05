import 'dart:async';

import 'package:flutter/material.dart';

import '../data/daily_questions.dart';
import '../models/daily_answer.dart';
import '../services/analytics_service.dart';
import '../services/daily_question_service.dart';
import '../services/question_engine.dart';

/// State for the "Daily question" Home card (feature #5): streams both members'
/// answers for today's shared question and exposes the user's own answer plus
/// the partner's (revealed only once both have answered — enforced here so the
/// UI can simply read [hasRevealed]).
class DailyQuestionProvider extends ChangeNotifier {
  DailyQuestionProvider({DailyQuestionService? service, QuestionEngine? engine})
      : _service = service ?? DailyQuestionService(),
        _engine = engine ?? QuestionEngine.withDefaults();

  final DailyQuestionService _service;
  final QuestionEngine _engine;

  /// The engine backing [todayQuestion]. Exposed so the coordinator can
  /// `registerSource` extra sources ('revisit', 'ai') at startup.
  QuestionEngine get engine => _engine;

  StreamSubscription<List<DailyAnswer>>? _subscription;
  String? _coupleId;
  String? _myUid;
  String _dateKey = '';
  List<DailyAnswer> _answers = const <DailyAnswer>[];
  bool _isLoading = false;

  // ── Question engine (feature endless-questions) ─────────────────────────
  // The card shows a deterministic bank question INSTANTLY (placeholder), then
  // swaps in whatever the engine resolves for today — which is snapshotted on
  // the day marker, so both phones converge on the same prompt.
  ResolvedQuestion? _resolved;
  bool _isResolving = false;

  /// 'coupleId + dateKey' of the resolution currently held/in flight — the
  /// guard that keeps this to ONE resolve per couple per day.
  String? _resolvedKey;

  // Context fed by the coordinator (Home) via [updateContext]; safe defaults so
  // the engine works before anything is wired.
  String _partnerUid = '';
  String _languageCode = 'vi';
  DateTime? _anniversaryDate;
  int _currentStreak = 0;
  /// -1 = unknown (photo list not loaded yet) so the "no photos this week"
  /// template can never fire on a guess; Home passes a real count later.
  int _photosThisWeek = -1;

  /// Set by the first [updateContext]. Until then [_maybeResolveToday] waits:
  /// SessionResolver arms [watchForCouple] BEFORE Home mounts, and resolving
  /// with an empty context (no partner/streak/anniversary/mood) would freeze a
  /// context-blind question into the marker for both phones.
  bool _contextReady = false;
  String? _myMood;
  String? _partnerMood;

  // Analytics guard — `daily_question_revealed` must fire ONCE per (couple,
  // day) reveal, not on every stream update once both have answered. Reset
  // whenever we (re)subscribe for a new couple/uid/day.
  bool _revealLogged = false;

  /// Today's shared question text in [langCode], resolved from the device-local
  /// date and the active couple so both partners see the same prompt on the same
  /// day — while different couples get their own no-repeat ordering.
  /// Falls back to seed 0 (still deterministic, never throws) before a couple is
  /// known.
  ///
  /// Once [QuestionEngine.resolveToday] has answered for today, its text wins
  /// (it may be a template/revisit/AI question, and it matches the marker both
  /// partners read).
  String todayQuestion(String langCode) {
    final resolved = _resolved;
    if (resolved != null) {
      final text = resolved.textFor(langCode);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return questionTextForCouple(DateTime.now(), _coupleId ?? '', langCode);
  }

  /// Today's question in the language last passed to [updateContext].
  String get questionText => todayQuestion(_languageCode);

  /// 'bank' | 'template' | 'revisit' | 'ai' — null until resolved.
  String? get questionSource => _resolved?.source;

  /// Optional hint under the question (per-user, never persisted), or null.
  String? get hintText => _resolved?.hintFor(_languageCode);

  /// Same hint in an explicit language.
  String? hintFor(String langCode) => _resolved?.hintFor(langCode);

  /// True while the engine is resolving today's question in the background.
  /// The card stays usable meanwhile (it shows the bank placeholder).
  bool get isResolvingQuestion => _isResolving;

  /// Feeds the engine the live signals it may use (streak, moods, photos) plus
  /// the couple facts it needs. Every argument is optional — only the ones
  /// passed are updated. Triggers a (re)resolve when today's question hasn't
  /// been resolved yet.
  void updateContext({
    int? currentStreak,
    String? myMood,
    String? partnerMood,
    int? photosThisWeek,
    String? partnerUid,
    String? languageCode,
    DateTime? anniversaryDate,
  }) {
    _contextReady = true;
    if (currentStreak != null) {
      _currentStreak = currentStreak;
    }
    if (myMood != null) {
      _myMood = myMood;
    }
    if (partnerMood != null) {
      _partnerMood = partnerMood;
    }
    if (photosThisWeek != null) {
      _photosThisWeek = photosThisWeek;
    }
    if (partnerUid != null) {
      _partnerUid = partnerUid;
    }
    if (languageCode != null && languageCode.trim().isNotEmpty) {
      _languageCode = languageCode.trim();
    }
    if (anniversaryDate != null) {
      _anniversaryDate = anniversaryDate;
    }
    _maybeResolveToday();
  }

  /// The current user's own answer for today (author == current uid), or null.
  /// The day currently being watched, `YYYY-MM-DD`. Empty before the first
  /// `watchForCouple`. Answer reactions are addressed by (date, answer author),
  /// so the card needs this to write against the right day.
  String get dateKey => _dateKey;

  DailyAnswer? get myAnswer {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    for (final answer in _answers) {
      if (answer.authorUserId == uid) {
        return answer;
      }
    }
    return null;
  }

  /// The partner's answer for today (author != current uid), or null.
  DailyAnswer? get partnerAnswer {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    for (final answer in _answers) {
      if (answer.authorUserId != uid && answer.hasText) {
        return answer;
      }
    }
    return null;
  }

  bool get hasAnswered => myAnswer?.hasText == true;

  /// True only when BOTH members have answered today — i.e. it's safe to reveal
  /// the partner's answer.
  bool get hasRevealed => hasAnswered && partnerAnswer != null;

  bool get isLoading => _isLoading;

  /// Begins watching today's answers for [coupleId] on behalf of [myUid]. Safe
  /// to call repeatedly: it no-ops when the (couple, uid, day) tuple is
  /// unchanged and already streaming, and resubscribes when any of them change
  /// (including a day rollover while the app stays open).
  void watchForCouple(String coupleId, String myUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }

    final today = DailyQuestionService.dateKey(DateTime.now());

    if (_coupleId == coupleId &&
        _myUid == myUid &&
        _dateKey == today &&
        _subscription != null) {
      return;
    }

    _coupleId = coupleId;
    _myUid = myUid;
    _dateKey = today;
    _answers = const <DailyAnswer>[];
    _isLoading = true;
    // New couple/day window → the previously resolved question no longer
    // applies; drop it so the card falls back to the instant placeholder while
    // the engine works.
    _resolved = null;
    _resolvedKey = null;
    notifyListeners();

    _resubscribe();
    _maybeResolveToday();
  }

  /// Resolves today's question ONCE per (couple, day). Fire-and-forget: the
  /// card renders the bank placeholder until this lands.
  void _maybeResolveToday() {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null || _dateKey.isEmpty) {
      return;
    }
    if (!_contextReady) {
      return; // Home calls updateContext() first, then we resolve.
    }
    final key = '$coupleId|$_dateKey';
    if (_resolvedKey == key) {
      return;
    }
    _resolvedKey = key;
    _isResolving = true;
    notifyListeners();

    unawaited(_resolveToday(key, coupleId, uid));
  }

  Future<void> _resolveToday(String key, String coupleId, String uid) async {
    ResolvedQuestion? resolved;
    try {
      resolved = await _engine.resolveToday(
        coupleId: coupleId,
        myUid: uid,
        partnerUid: _partnerUid,
        date: DateTime.now(),
        languageCode: _languageCode,
        anniversaryDate: _anniversaryDate ?? DateTime.now(),
        currentStreak: _currentStreak,
        photosThisWeek: _photosThisWeek,
        myMoodToday: _myMood,
        partnerMoodToday: _partnerMood,
      );
    } catch (_) {
      // Fail-soft: keep the placeholder question.
      resolved = null;
    }

    // A day rollover / couple change may have happened while we awaited.
    if (_resolvedKey != key) {
      return;
    }
    _isResolving = false;
    if (resolved != null) {
      _resolved = resolved;
    } else {
      // Allow a later retry (e.g. once the network is back).
      _resolvedKey = null;
    }
    notifyListeners();
  }

  void _resubscribe() {
    final coupleId = _coupleId;
    if (coupleId == null) {
      return;
    }
    // New (couple, uid, day) window → allow the reveal event to fire once more.
    _revealLogged = false;
    _subscription?.cancel();
    _subscription = _service.watchResponses(coupleId, _dateKey).listen(
      (answers) {
        _answers = answers;
        _isLoading = false;
        // Analytics — fire `daily_question_revealed` exactly once, the first
        // time both partners have answered today (no answer content logged).
        if (!_revealLogged && hasRevealed) {
          _revealLogged = true;
          AnalyticsService.instance.logDailyQuestionRevealed();
        }
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Submits the current user's answer for today. Returns false when there is
  /// no active couple/uid to write to.
  Future<bool> submit(String text) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null) {
      return false;
    }

    // Midnight rollover guard (2026-08-09): the day bucket is only refreshed by
    // [watchForCouple], which HomeScreen calls from a post-frame callback. An app
    // left open across midnight can therefore still hold YESTERDAY's [_dateKey]
    // while the card already renders TODAY's question — answering then would file
    // the answer (and the question snapshot) under the wrong day and skip today's
    // streak. Re-align first; the resubscribe below picks up the new day's stream.
    final today = DailyQuestionService.dateKey(DateTime.now());
    if (_dateKey != today) {
      _dateKey = today;
      _answers = const <DailyAnswer>[];
      _resolved = null;
      _resolvedKey = null;
      _resubscribe();
      _maybeResolveToday();
    }

    final resolved = _resolved;
    await _service.submitAnswer(
      coupleId: coupleId,
      dateKey: _dateKey,
      uid: uid,
      text: text,
      // Snapshot the question the card actually showed (never re-derived from
      // the bank — it may have been a template/revisit/AI question).
      questionVi: resolved?.questionVi,
      questionEn: resolved?.questionEn,
      source: resolved?.source,
    );

    // Analytics — answered today (🔒 never the answer text).
    AnalyticsService.instance.logDailyQuestionAnswered();

    // The Firebase stream pushes the new doc automatically; the local fallback
    // is a one-shot future, so re-read to reflect the just-saved answer.
    if (!_service.isUsingFirebase) {
      _resubscribe();
    }
    return true;
  }

  /// Stops watching and resets state (e.g. on sign-out or leaving a couple).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _coupleId = null;
    _myUid = null;
    _dateKey = '';
    _answers = const <DailyAnswer>[];
    _isLoading = false;
    _resolved = null;
    _resolvedKey = null;
    _isResolving = false;
    // Context belongs to the couple that just left; the next couple must wait
    // for Home to feed its own (otherwise a sign-out → sign-in without a
    // restart would resolve with the previous couple's streak/anniversary).
    _contextReady = false;
    _currentStreak = 0;
    _photosThisWeek = -1;
    _myMood = null;
    _partnerMood = null;
    _partnerUid = '';
    _anniversaryDate = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
