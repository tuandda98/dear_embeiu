import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/answer_reaction.dart';
import '../services/analytics_service.dart';
import '../services/answer_reaction_service.dart';

/// State for reactions on daily-question answers (feature: daily-question
/// reactions). Streams every answer reaction of the active couple via a single
/// collection-group query (see [AnswerReactionService]) and exposes per-answer
/// lookups plus optimistic toggle/set/remove actions.
///
/// Answers are addressed by the pair (date, answerAuthorUid) — a day holds at
/// most one answer per member — collapsed into one string key via
/// [AnswerReaction.keyFor].
///
/// Lifecycle mirrors [ReactionProvider]: `watchForCouple` is wired in
/// `session_resolver` (and re-armed in HomeScreen) when a couple is active, and
/// `clear` is called on sign-out / no-couple.
class AnswerReactionProvider extends ChangeNotifier {
  AnswerReactionProvider({AnswerReactionService? service})
      : _service = service ?? AnswerReactionService();

  final AnswerReactionService _service;

  StreamSubscription<Map<String, List<AnswerReaction>>>? _subscription;
  String? _coupleId;
  String? _myUid;

  /// Reactions from the live stream (server truth), grouped by answer key.
  Map<String, List<AnswerReaction>> _serverReactions =
      const <String, List<AnswerReaction>>{};

  /// In-flight optimistic overrides keyed by answer key. Value is the user's own
  /// reaction emoji, or null to mean "user removed their reaction". Cleared once
  /// the server stream confirms (or a rollback happens).
  final Map<String, String?> _pendingMine = <String, String?>{};

  /// Answer keys whose last write failed — drives the transient error
  /// affordance.
  final Set<String> _errorKeys = <String>{};

  bool get isReady => _service.isUsingFirebase && _coupleId != null;

  /// All reactions on one answer, merged with any in-flight optimistic change to
  /// the current user's own reaction.
  List<AnswerReaction> reactionsFor(String date, String answerAuthorUid) {
    final key = AnswerReaction.keyFor(date, answerAuthorUid);
    final base = _serverReactions[key] ?? const <AnswerReaction>[];
    final uid = _myUid;

    if (uid == null || !_pendingMine.containsKey(key)) {
      return base;
    }

    final pendingEmoji = _pendingMine[key];
    final others =
        base.where((r) => r.reactorUserId != uid).toList(growable: true);
    if (pendingEmoji == null) {
      return others; // removed mine
    }
    others.add(AnswerReaction(
      reactorUserId: uid,
      answerAuthorUserId: answerAuthorUid,
      emoji: pendingEmoji,
      coupleId: _coupleId ?? '',
      date: date,
    ));
    return others;
  }

  /// The current user's own reaction emoji on one answer, or null when none.
  String? myReaction(String date, String answerAuthorUid) {
    final key = AnswerReaction.keyFor(date, answerAuthorUid);
    if (_pendingMine.containsKey(key)) {
      return _pendingMine[key];
    }
    return _serverEmojiFor(key, _myUid);
  }

  /// The partner's reaction on one answer (reactor != me), or null.
  AnswerReaction? partnerReaction(String date, String answerAuthorUid) {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    for (final r in reactionsFor(date, answerAuthorUid)) {
      if (r.reactorUserId != uid) {
        return r;
      }
    }
    return null;
  }

  bool hasError(String date, String answerAuthorUid) =>
      _errorKeys.contains(AnswerReaction.keyFor(date, answerAuthorUid));

  void clearError(String date, String answerAuthorUid) {
    if (_errorKeys.remove(AnswerReaction.keyFor(date, answerAuthorUid))) {
      notifyListeners();
    }
  }

  /// Begins watching all answer reactions for [coupleId] on behalf of [myUid].
  /// Safe to call repeatedly; no-ops when the (couple, uid) pair is unchanged
  /// and already streaming, and resubscribes when either changes.
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
    _serverReactions = const <String, List<AnswerReaction>>{};
    _pendingMine.clear();
    _errorKeys.clear();
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.watchCoupleAnswerReactions(coupleId).listen(
      (reactions) {
        _serverReactions = reactions;
        // Once the server reflects an optimistic write, drop its override so the
        // two no longer fight.
        final uid = _myUid;
        if (uid != null && _pendingMine.isNotEmpty) {
          final confirmed = <String>[];
          _pendingMine.forEach((key, expected) {
            if (_serverEmojiFor(key, uid) == expected) {
              confirmed.add(key);
            }
          });
          for (final key in confirmed) {
            _pendingMine.remove(key);
          }
        }
        notifyListeners();
      },
      onError: (_) {
        // Keep the last good data; per-action errors are handled in the write
        // path.
        notifyListeners();
      },
    );
  }

  String? _serverEmojiFor(String key, String? uid) {
    if (uid == null) {
      return null;
    }
    final base = _serverReactions[key] ?? const <AnswerReaction>[];
    for (final r in base) {
      if (r.reactorUserId == uid) {
        return r.emoji;
      }
    }
    return null;
  }

  String? _currentMineEmoji(String date, String answerAuthorUid) {
    final key = AnswerReaction.keyFor(date, answerAuthorUid);
    if (_pendingMine.containsKey(key)) {
      return _pendingMine[key];
    }
    return _serverEmojiFor(key, _myUid);
  }

  /// Taps the heart button: thaws the default ❤️ when the user has no reaction
  /// (or a different one), and removes it when ❤️ is already theirs (toggle
  /// off). Use [setReaction] for picking a specific emoji.
  Future<void> toggleHeart(String date, String answerAuthorUid) async {
    final current = _currentMineEmoji(date, answerAuthorUid);
    if (current == kDefaultReactionEmoji) {
      await remove(date, answerAuthorUid);
    } else {
      await setReaction(date, answerAuthorUid, kDefaultReactionEmoji);
    }
  }

  /// Sets the current user's reaction on one answer to [emoji] (create or
  /// change), optimistically. Rolls back and flags an error if the write fails.
  Future<void> setReaction(
    String date,
    String answerAuthorUid,
    String emoji,
  ) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null || !kReactionEmojis.contains(emoji)) {
      return;
    }

    final key = AnswerReaction.keyFor(date, answerAuthorUid);
    final previous = _currentMineEmoji(date, answerAuthorUid);
    if (previous == emoji) {
      return; // no change
    }

    // Optimistic: show the new emoji immediately.
    _pendingMine[key] = emoji;
    _errorKeys.remove(key);
    notifyListeners();

    // Analytics — `add` (first reaction) vs `change` (swapped emoji). Never logs
    // the emoji, the answer text, or whose answer it is.
    AnalyticsService.instance.logReactionSet(
      previous == null ? 'add' : 'change',
      surface: 'daily_answer',
    );

    try {
      await _service.setReaction(
        coupleId: coupleId,
        date: date,
        answerAuthorUid: answerAuthorUid,
        uid: uid,
        emoji: emoji,
      );
    } catch (_) {
      _rollback(key, previous);
    }
  }

  /// Removes the current user's reaction from one answer, optimistically.
  Future<void> remove(String date, String answerAuthorUid) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null) {
      return;
    }

    final key = AnswerReaction.keyFor(date, answerAuthorUid);
    final previous = _currentMineEmoji(date, answerAuthorUid);
    if (previous == null) {
      return; // nothing to remove
    }

    _pendingMine[key] = null; // optimistic removal
    _errorKeys.remove(key);
    notifyListeners();

    AnalyticsService.instance
        .logReactionSet('remove', surface: 'daily_answer');

    try {
      await _service.removeReaction(
        coupleId: coupleId,
        date: date,
        answerAuthorUid: answerAuthorUid,
        uid: uid,
      );
    } catch (_) {
      _rollback(key, previous);
    }
  }

  void _rollback(String key, String? previous) {
    if (previous == null) {
      _pendingMine.remove(key);
    } else {
      _pendingMine[key] = previous;
    }
    _errorKeys.add(key);
    notifyListeners();
  }

  /// Stops streaming and drops all state (sign-out / couple ended).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _coupleId = null;
    _myUid = null;
    _serverReactions = const <String, List<AnswerReaction>>{};
    _pendingMine.clear();
    _errorKeys.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
