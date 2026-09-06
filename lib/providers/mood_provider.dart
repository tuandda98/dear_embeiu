import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/mood.dart';
import '../services/mood_service.dart';

/// State for the "Tâm trạng hôm nay" Home card (feature mood): streams both
/// members' mood docs and exposes my mood + the partner's, scoped to TODAY (a
/// mood older than today reads as "not shared today" so the ritual resets each
/// day — the daily hook).
///
/// Lifecycle mirrors [DailyQuestionProvider]/[ReactionProvider]: `watchForCouple`
/// is wired in `session_resolver` (re-armed from HomeScreen) when a couple is
/// active, and `clear` is called on sign-out / no-couple.
class MoodProvider extends ChangeNotifier {
  MoodProvider({MoodService? service}) : _service = service ?? MoodService();

  final MoodService _service;

  StreamSubscription<Map<String, Mood>>? _subscription;
  String? _coupleId;
  String? _myUid;
  Map<String, Mood> _moods = const <String, Mood>{};

  bool get isReady => _coupleId != null && _myUid != null;
  bool get isUsingFirebase => _service.isUsingFirebase;

  /// Local-date key 'YYYY-MM-DD' for today (matches what we write).
  static String todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  /// Returns [m] only when it belongs to today; otherwise null (yesterday's
  /// mood doesn't count for the daily ritual).
  Mood? _todayOnly(Mood? m) {
    if (m == null || m.date != todayKey()) {
      return null;
    }
    return m;
  }

  /// My mood for today, or null when I haven't shared yet.
  Mood? get myMood {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    return _todayOnly(_moods[uid]);
  }

  /// The partner's mood for today (any author != me), or null.
  Mood? get partnerMood {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    for (final entry in _moods.entries) {
      if (entry.key != uid) {
        return _todayOnly(entry.value);
      }
    }
    return null;
  }

  bool get hasSharedToday => myMood != null;

  /// Begins watching the couple's moods. Safe to call repeatedly; no-ops when the
  /// (couple, uid) pair is unchanged and already streaming.
  void watchForCouple(String coupleId, String myUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }
    if (_coupleId == coupleId && _myUid == myUid && _subscription != null) {
      return;
    }
    _coupleId = coupleId;
    _myUid = myUid;
    _moods = const <String, Mood>{};
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.watchMoods(coupleId).listen(
      (moods) {
        _moods = moods;
        notifyListeners();
      },
      onError: (_) {
        // Keep last good data; nothing global to surface.
        notifyListeners();
      },
    );
  }

  /// Sets my mood for today (create or change). [note] is optional.
  Future<void> setMood(String moodKey, {String note = ''}) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null || moodOptionFor(moodKey) == null) {
      return;
    }

    // Optimistic: reflect my pick immediately so the card responds instantly.
    final optimistic = Mood(
      authorUserId: uid,
      mood: moodKey,
      note: note.trim(),
      date: todayKey(),
      updatedAt: DateTime.now(),
    );
    _moods = {..._moods, uid: optimistic};
    notifyListeners();

    await _service.setMood(
      coupleId: coupleId,
      uid: uid,
      mood: moodKey,
      note: note,
      dateKey: todayKey(),
    );

    // Local fallback has no stream — re-read to confirm (Firebase pushes itself).
    if (!_service.isUsingFirebase) {
      _moods = await _service.watchMoods(coupleId).first;
      notifyListeners();
    }
  }

  /// Stops watching and resets state (sign-out / leaving a couple).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _coupleId = null;
    _myUid = null;
    _moods = const <String, Mood>{};
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
