import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/streak_service.dart';

/// The streak's UI state (feature streak). Drives the chip/sheet copy + visuals.
/// See `project/features/streak/design.md` §5.
enum StreakState {
  /// Couple not active yet (waiting for partner) → chip hidden entirely.
  hidden,

  /// Active couple, no current streak. Pair with [StreakProvider.everHadStreak]
  /// to choose the "start" vs "restart" copy.
  noStreak,

  /// Current streak >= 1 AND today is already revealed (both answered today).
  activeToday,

  /// Current streak >= 1 ending YESTERDAY; today not revealed yet.
  inProgress,

  /// Missed exactly one day (yesterday) but the day before counts → grace day.
  atRisk,
}

/// Couple "connection streak" — a view derived entirely from the
/// `dailyAnswers` markers flagged `bothAnswered` (feature streak). Thuần client,
/// fail-soft: any read error leaves the state [StreakState.hidden] so the UI can
/// simply hide the chip. Never throws, never toasts.
class StreakProvider extends ChangeNotifier {
  StreakProvider({StreakService? service})
      : _service = service ?? StreakService();

  final StreakService _service;

  /// Milestones celebrated (design §6). Ordered for `nextMilestone` lookup.
  static const List<int> milestones = [3, 7, 30, 100, 365];

  static const String _guardBoxName = 'streak_state';

  StreamSubscription<List<String>>? _subscription;
  String? _coupleId;
  bool _coupleActive = false;

  StreakState _state = StreakState.hidden;
  int _currentStreak = 0;
  int _longestStreak = 0;
  bool _everHadStreak = false;
  bool _isLoading = false;
  bool _hasError = false;

  /// A milestone the latest update just reached for the first time (one-shot;
  /// the UI reads it then calls [consumeJustReachedMilestone]). Null when none.
  int? _justReachedMilestone;

  // ── Public read API ───────────────────────────────────────────────────────

  StreakState get state => _state;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;

  /// True once the couple has ever had a streak (≥1) in the loaded window — lets
  /// the UI pick "restart" copy over "start" copy after a reset.
  bool get everHadStreak => _everHadStreak;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  /// Whether the chip should render at all (hidden while waiting for a partner
  /// or on a read error — fail-soft).
  bool get isVisible => _state != StreakState.hidden && !_hasError;

  /// Whether today still needs answering to advance/secure the streak (drives
  /// the sheet's "Answer now" CTA).
  bool get needsActionToday =>
      _state == StreakState.inProgress ||
      _state == StreakState.atRisk ||
      (_state == StreakState.noStreak && _coupleActive);

  /// Next milestone strictly greater than [currentStreak], or null when past the
  /// last one (365).
  int? get nextMilestone {
    for (final m in milestones) {
      if (_currentStreak < m) {
        return m;
      }
    }
    return null;
  }

  /// Days remaining until [nextMilestone], or null when there's no next one.
  int? get daysToNextMilestone {
    final next = nextMilestone;
    return next == null ? null : next - _currentStreak;
  }

  /// A milestone the most recent update freshly reached (for the celebration
  /// sheet). One-shot — call [consumeJustReachedMilestone] after handling.
  int? get justReachedMilestone => _justReachedMilestone;

  void consumeJustReachedMilestone() {
    _justReachedMilestone = null;
  }

  // ── Lifecycle (mirrors daily_question/love_note providers) ─────────────────

  /// Begins watching the streak for [coupleId]. [coupleActive] is false while
  /// the couple is still waiting for a partner → the streak is [StreakState.hidden]
  /// (no point counting a solo "both answered"). Safe to call repeatedly; no-ops
  /// when nothing changed and already streaming.
  void watchForCouple(String coupleId, {required bool coupleActive}) {
    if (coupleId.trim().isEmpty) {
      clear();
      return;
    }

    if (_coupleId == coupleId &&
        _coupleActive == coupleActive &&
        _subscription != null) {
      return;
    }

    _coupleId = coupleId;
    _coupleActive = coupleActive;
    _hasError = false;
    _justReachedMilestone = null;

    if (!coupleActive) {
      // Waiting for partner → hidden, but keep the couple id so we re-arm when
      // it becomes active. Cancel any prior stream.
      _subscription?.cancel();
      _subscription = null;
      _state = StreakState.hidden;
      _currentStreak = 0;
      _longestStreak = 0;
      _everHadStreak = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.watchRevealedDates(coupleId).listen(
      (dates) => _recompute(dates),
      onError: (_) {
        // Fail-soft: hide the chip, never surface the error.
        _hasError = true;
        _isLoading = false;
        _state = StreakState.hidden;
        notifyListeners();
      },
    );
  }

  /// Stops watching and resets (sign-out / leaving a couple).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _coupleId = null;
    _coupleActive = false;
    _state = StreakState.hidden;
    _currentStreak = 0;
    _longestStreak = 0;
    _everHadStreak = false;
    _isLoading = false;
    _hasError = false;
    _justReachedMilestone = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ── Streak computation ─────────────────────────────────────────────────────

  /// Recomputes the streak from the revealed-day keys ([dates], 'YYYY-MM-DD',
  /// newest first — but we re-sort defensively). All counting is by local
  /// calendar day, matching the daily question's day bucket.
  void _recompute(List<String> dates) {
    final previousStreak = _currentStreak;

    // Build a set of revealed local dates (date-only DateTimes).
    final revealed = <DateTime>{};
    for (final key in dates) {
      final d = _dateOnlyFromKey(key);
      if (d != null) {
        revealed.add(d);
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBefore = today.subtract(const Duration(days: 2));

    final todayRevealed = revealed.contains(today);
    final yesterdayRevealed = revealed.contains(yesterday);
    final dayBeforeRevealed = revealed.contains(dayBefore);

    // Anchor = the most recent day that the current streak can run back from.
    // - today revealed              → count back from today (activeToday)
    // - else yesterday revealed     → count back from yesterday (inProgress)
    // - else day-before revealed    → count back from day-before (atRisk, grace)
    // - else                        → no current streak
    DateTime? anchor;
    StreakState state;
    if (todayRevealed) {
      anchor = today;
      state = StreakState.activeToday;
    } else if (yesterdayRevealed) {
      anchor = yesterday;
      state = StreakState.inProgress;
    } else if (dayBeforeRevealed) {
      anchor = dayBefore;
      state = StreakState.atRisk;
    } else {
      anchor = null;
      state = StreakState.noStreak;
    }

    var current = 0;
    if (anchor != null) {
      var cursor = anchor;
      while (revealed.contains(cursor)) {
        current++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    // Longest run anywhere in the loaded window (D-PO-1 — only accurate within
    // StreakService.windowLimit days; recorded as a v1 limitation).
    final longest = _longestRun(revealed);

    _currentStreak = current;
    _longestStreak = longest;
    _state = state;
    if (current >= 1) {
      _everHadStreak = true;
    } else if (revealed.isNotEmpty) {
      // Reset after a real streak: any revealed day in history means a streak
      // existed → use "restart" copy.
      _everHadStreak = true;
    }
    _isLoading = false;
    _hasError = false;

    // Milestone one-shot: only when today's reveal pushed us UP onto an exact
    // milestone we haven't celebrated yet for this couple. Guarded per couple in
    // Hive so reopening Home doesn't re-fire it; cleared when the streak resets.
    _maybeFlagMilestone(
      previousStreak: previousStreak,
      newStreak: current,
      todayRevealed: todayRevealed,
    );

    notifyListeners();
  }

  /// Longest consecutive run of revealed days within the loaded set.
  int _longestRun(Set<DateTime> revealed) {
    if (revealed.isEmpty) {
      return 0;
    }
    var best = 0;
    for (final day in revealed) {
      // Only start counting from a run's beginning (previous day not revealed),
      // so each run is measured once.
      if (revealed.contains(day.subtract(const Duration(days: 1)))) {
        continue;
      }
      var run = 0;
      var cursor = day;
      while (revealed.contains(cursor)) {
        run++;
        cursor = cursor.add(const Duration(days: 1));
      }
      if (run > best) {
        best = run;
      }
    }
    return best;
  }

  /// Flags a freshly-reached milestone for the celebration sheet, with a per-
  /// couple Hive guard so it fires once. Resets the guard set when the streak
  /// drops to 0 (so re-reaching an old milestone celebrates again — by design).
  void _maybeFlagMilestone({
    required int previousStreak,
    required int newStreak,
    required bool todayRevealed,
  }) {
    final coupleId = _coupleId;
    if (coupleId == null) {
      return;
    }

    // Streak reset → forget previous celebrations so future re-reaches re-fire.
    if (newStreak == 0) {
      unawaited(_clearCelebrated(coupleId));
      return;
    }

    // Only celebrate when today's reveal actually advanced the streak onto a
    // milestone (avoids firing on first load of an already-long streak).
    if (!todayRevealed || newStreak <= previousStreak) {
      return;
    }
    if (!milestones.contains(newStreak)) {
      return;
    }

    unawaited(_celebrateIfNew(coupleId, newStreak));
  }

  Future<Box<dynamic>> _openGuardBox() => Hive.openBox<dynamic>(_guardBoxName);

  /// Marks [milestone] celebrated for [coupleId] (idempotent) and, if it was new,
  /// surfaces it via [justReachedMilestone] + notifies listeners.
  Future<void> _celebrateIfNew(String coupleId, int milestone) async {
    try {
      final box = await _openGuardBox();
      final raw = box.get(coupleId);
      final done = <int>{
        if (raw is List) ...raw.whereType<int>(),
      };
      if (done.contains(milestone)) {
        return;
      }
      done.add(milestone);
      await box.put(coupleId, done.toList());
      _justReachedMilestone = milestone;
      notifyListeners();
    } catch (_) {
      // Guard persistence is best-effort; skipping a celebration is acceptable.
    }
  }

  Future<void> _clearCelebrated(String coupleId) async {
    try {
      final box = await _openGuardBox();
      if (box.containsKey(coupleId)) {
        await box.delete(coupleId);
      }
    } catch (_) {
      // Best-effort.
    }
  }

  /// Parses a 'YYYY-MM-DD' marker key to a date-only [DateTime] (local). Returns
  /// null on a malformed key so a bad doc can't corrupt the count.
  DateTime? _dateOnlyFromKey(String key) {
    // Reuse the daily-question bucket semantics, then strip any time part.
    final parsed = DateTime.tryParse(key);
    if (parsed == null) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
