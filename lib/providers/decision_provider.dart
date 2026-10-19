import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/foundation.dart';

import '../models/decision.dart';
import '../services/analytics_service.dart';
import '../services/daily_question_service.dart';
import '../services/decision_service.dart';

/// State for "Chọn giúp chúng mình" (feature decision-wheel): today's picks
/// (live, one `date ==` listener) + a per-session cache of the last 90 days
/// (pool exclusion, typed-in picks, top 5).
///
/// Lifecycle like [MoodProvider]: `watchForCouple` from `session_resolver`
/// (re-armed by HomeScreen), `clear` on sign-out / no couple. The Home card
/// calls [refreshDay] after midnight so "today" re-subscribes.
class DecisionProvider extends ChangeNotifier {
  DecisionProvider({DecisionService? service})
    : _service = service ?? DecisionService();

  final DecisionService _service;

  StreamSubscription<List<Decision>>? _subscription;
  String? _coupleId;
  String? _myUid;
  String? _dayKey;
  List<Decision> _today = const <Decision>[];
  bool _isLoading = false;

  List<Decision>? _recent;
  Future<List<Decision>>? _recentLoad;

  String? get coupleId => _coupleId;
  String? get myUid => _myUid;
  bool get isReady => _coupleId != null && _myUid != null;

  /// True until today's first snapshot lands (card shows its shimmer).
  bool get isLoading => _isLoading;

  static String todayKey() => DailyQuestionService.dateKey(DateTime.now());

  bool get _isStale => _dayKey != null && _dayKey != todayKey();

  Decision? _ofKind(DecisionKind kind) {
    if (_isStale) return null;
    for (final d in _today) {
      if (d.kind == kind) return d;
    }
    return null;
  }

  Decision? get todayEat => _ofKind(DecisionKind.eat);
  Decision? get todayGo => _ofKind(DecisionKind.go);

  /// Today's custom picks, newest first.
  List<Decision> get todayCustoms {
    if (_isStale) return const <Decision>[];
    final list = _today.where((d) => d.kind == DecisionKind.custom).toList();
    list.sort((a, b) {
      final at = a.pickedAt, bt = b.pickedAt;
      if (at == null || bt == null) return at == null ? -1 : 1;
      return bt.compareTo(at);
    });
    return list;
  }

  bool get customCapReached => todayCustoms.length >= kDecisionCustomDailyCap;

  /// The 90-day cache merged with today's live docs (today wins) — what the
  /// suggester and the top 5 read. Empty until [ensureRecent] finished.
  List<Decision> get history {
    final byId = <String, Decision>{
      for (final d in _recent ?? const <Decision>[]) d.id: d,
    };
    for (final d in _today) {
      byId[d.id] = d;
    }
    return byId.values.toList(growable: false);
  }

  bool get hasRecent => _recent != null;

  void watchForCouple(String coupleId, String myUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }
    final day = todayKey();
    if (_coupleId == coupleId &&
        _myUid == myUid &&
        _dayKey == day &&
        _subscription != null) {
      return;
    }
    if (_coupleId != coupleId) {
      _recent = null;
      _recentLoad = null;
    }
    _coupleId = coupleId;
    _myUid = myUid;
    _dayKey = day;
    _today = const <Decision>[];
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service
        .watchDay(coupleId, day)
        .listen(
          (list) {
            _today = list;
            _isLoading = false;
            notifyListeners();
          },
          onError: (_) {
            // Fail-soft: the card reads as empty, spinning still works.
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Re-subscribes when the local day rolled over (MidnightBuilder / resume).
  void refreshDay() {
    final coupleId = _coupleId, uid = _myUid;
    if (coupleId != null && uid != null && _isStale) {
      watchForCouple(coupleId, uid);
    }
  }

  /// Loads the 90-day window once per session (errors → empty, retried on
  /// the next call).
  Future<List<Decision>> ensureRecent() {
    final coupleId = _coupleId;
    if (coupleId == null) return Future.value(const <Decision>[]);
    final cached = _recent;
    if (cached != null) return Future.value(history);
    return _recentLoad ??= _service
        .fetchRecent(coupleId)
        .then((list) {
          if (_coupleId == coupleId) {
            _recent = list;
            notifyListeners();
          }
          return history;
        })
        .catchError((Object _) {
          _recentLoad = null;
          return history;
        });
  }

  /// Locks in a pick and returns it as written. Throws when nothing was
  /// written (the wheel shows its error strip + "Thử lại").
  Future<(Decision, DecisionCommitOutcome)> commit({
    required DecisionKind kind,
    required String result,
    String resultId = '',
    String filter = '',
    String question = '',
    List<String> options = const <String>[],
    String? existingId,
    required String via,
    String? preset,
  }) async {
    final coupleId = _coupleId, uid = _myUid;
    if (coupleId == null || uid == null) {
      throw StateError('decision-no-couple');
    }
    final previous = existingId != null
        ? _today.where((d) => d.id == existingId).firstOrNull
        : (kind == DecisionKind.custom ? null : _ofKind(kind));
    final (id, outcome, spins) = await _service.commit(
      coupleId: coupleId,
      uid: uid,
      kind: kind,
      dateKey: previous?.date ?? todayKey(),
      result: result,
      resultId: resultId,
      filter: filter,
      question: question,
      options: options,
      existingId: existingId,
    );

    // Show it at once (the listener confirms; a queued custom pick only exists
    // locally until it syncs). `spins` comes from the transaction: the
    // partner's doc may exist before our listener saw it (BUG-7).
    final now = DateTime.now();
    final written =
        previous?.copyWith(
          result: result.trim(),
          resultId: resultId,
          spins: spins,
          byUserId: uid,
          updatedAt: now,
        ) ??
        Decision(
          id: id,
          kind: kind,
          date: todayKey(),
          question: question.trim(),
          options: options,
          filter: filter,
          result: result.trim(),
          resultId: resultId,
          spins: spins,
          byUserId: uid,
          createdBy: uid,
          createdAt: now,
          updatedAt: now,
        );
    _today = [
      for (final d in _today)
        if (d.id != written.id) d,
      written,
    ];
    final recent = _recent;
    if (recent != null) {
      _recent = [
        for (final d in recent)
          if (d.id != written.id) d,
        written,
      ];
    }
    notifyListeners();

    if (spins > 1) {
      AnalyticsService.instance.logDecisionRespin(kind: kind.name);
    }
    AnalyticsService.instance.logDecisionCommit(
      kind: kind.name,
      spins: written.spins,
      via: via,
      preset: preset,
    );
    return (written, outcome);
  }

  /// Top [n] results of [kind] in the 90-day window: (latest doc, count),
  /// counted on the bank `resultId` when there is one (a vi and an en spin of
  /// the same dish are one row), else on the normalised name (D9).
  List<(Decision, int)> top(DecisionKind kind, {int n = 5}) =>
      topOf(history, kind, n: n);

  /// Pure core of [top] (unit-tested).
  static List<(Decision, int)> topOf(
    Iterable<Decision> history,
    DecisionKind kind, {
    int n = 5,
  }) {
    final groups = <String, List<Decision>>{};
    for (final d in history) {
      if (d.kind != kind) continue;
      final id = d.resultId.trim();
      final key = id.isNotEmpty
          ? 'id:$id'
          : 'name:${normalizeDecisionName(d.result)}';
      groups.putIfAbsent(key, () => []).add(d);
    }
    final rows = groups.values.map((list) {
      list.sort(
        (a, b) =>
            (b.pickedAt ?? DateTime(0)).compareTo(a.pickedAt ?? DateTime(0)),
      );
      return (list.first, list.length);
    }).toList();
    rows.sort((a, b) => b.$2.compareTo(a.$2));
    return rows.take(n).toList(growable: false);
  }

  Future<DecisionPage> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    final coupleId = _coupleId;
    if (coupleId == null) return Future.value(const DecisionPage.empty());
    return _service.fetchPage(coupleId: coupleId, startAfter: startAfter);
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _coupleId = null;
    _myUid = null;
    _dayKey = null;
    _today = const <Decision>[];
    _recent = null;
    _recentLoad = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
