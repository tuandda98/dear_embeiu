import 'dart:async';

import 'package:flutter/material.dart';

import '../data/daily_questions.dart';
import '../models/daily_answer.dart';
import '../services/analytics_service.dart';
import '../services/daily_question_service.dart';

/// State for the "Daily question" Home card (feature #5): streams both members'
/// answers for today's shared question and exposes the user's own answer plus
/// the partner's (revealed only once both have answered — enforced here so the
/// UI can simply read [hasRevealed]).
class DailyQuestionProvider extends ChangeNotifier {
  DailyQuestionProvider({DailyQuestionService? service})
      : _service = service ?? DailyQuestionService();

  final DailyQuestionService _service;

  StreamSubscription<List<DailyAnswer>>? _subscription;
  String? _coupleId;
  String? _myUid;
  String _dateKey = '';
  List<DailyAnswer> _answers = const <DailyAnswer>[];
  bool _isLoading = false;

  // Analytics guard — `daily_question_revealed` must fire ONCE per (couple,
  // day) reveal, not on every stream update once both have answered. Reset
  // whenever we (re)subscribe for a new couple/uid/day.
  bool _revealLogged = false;

  /// Today's shared question text in [langCode], resolved from the device-local
  /// date and the active couple so both partners see the same prompt on the same
  /// day — while different couples get their own no-repeat ordering.
  /// Falls back to seed 0 (still deterministic, never throws) before a couple is
  /// known.
  String todayQuestion(String langCode) =>
      questionTextForCouple(DateTime.now(), _coupleId ?? '', langCode);

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
    notifyListeners();

    _resubscribe();
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
      _resubscribe();
    }

    await _service.submitAnswer(
      coupleId: coupleId,
      dateKey: _dateKey,
      uid: uid,
      text: text,
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
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
