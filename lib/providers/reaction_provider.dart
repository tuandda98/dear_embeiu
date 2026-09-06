import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/photo_reaction.dart';
import '../services/analytics_service.dart';
import '../services/reaction_service.dart';

/// State for photo reactions (feature: reactions ❤️). Streams every reaction of
/// the active couple via a single collection-group query (see [ReactionService])
/// and exposes per-photo lookups plus optimistic toggle/set/remove actions.
///
/// Lifecycle mirrors [DailyQuestionProvider]: `watchForCouple`
/// is wired in `session_resolver` (and re-armed in HomeScreen/GalleryScreen) when
/// a couple is active, and `clear` is called on sign-out / no-couple.
class ReactionProvider extends ChangeNotifier {
  ReactionProvider({ReactionService? service})
      : _service = service ?? ReactionService();

  final ReactionService _service;

  StreamSubscription<Map<String, List<PhotoReaction>>>? _subscription;
  String? _coupleId;
  String? _myUid;

  /// Reactions from the live stream (server truth), grouped by photoId.
  Map<String, List<PhotoReaction>> _serverReactions =
      const <String, List<PhotoReaction>>{};

  /// In-flight optimistic overrides keyed by photoId. Value is the user's own
  /// reaction emoji, or null to mean "user removed their reaction". Cleared once
  /// the server stream confirms (or a rollback happens).
  final Map<String, String?> _pendingMine = <String, String?>{};

  /// PhotoIds whose last write failed — drives the transient error affordance.
  final Set<String> _errorPhotoIds = <String>{};

  bool get isReady => _service.isUsingFirebase && _coupleId != null;

  /// All reactions for [photoId] (partner + me), merged with any in-flight
  /// optimistic change to the current user's own reaction.
  List<PhotoReaction> reactionsFor(String photoId) {
    final base = _serverReactions[photoId] ?? const <PhotoReaction>[];
    final uid = _myUid;

    if (uid == null || !_pendingMine.containsKey(photoId)) {
      return base;
    }

    // Apply the optimistic override for my own reaction on top of server data.
    final pendingEmoji = _pendingMine[photoId];
    final others =
        base.where((r) => r.authorUserId != uid).toList(growable: true);
    if (pendingEmoji == null) {
      return others; // removed mine
    }
    others.add(PhotoReaction(
      authorUserId: uid,
      emoji: pendingEmoji,
      coupleId: _coupleId ?? '',
    ));
    return others;
  }

  /// The current user's own reaction emoji for [photoId], or null when none.
  String? myReaction(String photoId, String myUid) {
    if (_pendingMine.containsKey(photoId)) {
      return _pendingMine[photoId];
    }
    final base = _serverReactions[photoId] ?? const <PhotoReaction>[];
    for (final r in base) {
      if (r.authorUserId == myUid) {
        return r.emoji;
      }
    }
    return null;
  }

  /// The partner's reaction for [photoId] (author != [myUid]), or null.
  PhotoReaction? partnerReaction(String photoId, String myUid) {
    for (final r in reactionsFor(photoId)) {
      if (r.authorUserId != myUid) {
        return r;
      }
    }
    return null;
  }

  bool hasError(String photoId) => _errorPhotoIds.contains(photoId);

  void clearError(String photoId) {
    if (_errorPhotoIds.remove(photoId)) {
      notifyListeners();
    }
  }

  /// Begins watching all reactions for [coupleId] on behalf of [myUid]. Safe to
  /// call repeatedly; no-ops when the (couple, uid) pair is unchanged and already
  /// streaming, and resubscribes when either changes.
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
    _serverReactions = const <String, List<PhotoReaction>>{};
    _pendingMine.clear();
    _errorPhotoIds.clear();
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.watchCoupleReactions(coupleId).listen(
      (reactions) {
        _serverReactions = reactions;
        // Once the server reflects an optimistic write, drop its override so the
        // two no longer fight. We compare the user's own emoji per photo.
        final uid = _myUid;
        if (uid != null && _pendingMine.isNotEmpty) {
          final confirmed = <String>[];
          _pendingMine.forEach((photoId, expected) {
            final serverMine = _serverEmojiFor(photoId, uid);
            if (serverMine == expected) {
              confirmed.add(photoId);
            }
          });
          for (final photoId in confirmed) {
            _pendingMine.remove(photoId);
          }
        }
        notifyListeners();
      },
      onError: (_) {
        // Keep the last good data; surface nothing globally (per-action errors
        // are handled in the write path).
        notifyListeners();
      },
    );
  }

  String? _serverEmojiFor(String photoId, String uid) {
    final base = _serverReactions[photoId] ?? const <PhotoReaction>[];
    for (final r in base) {
      if (r.authorUserId == uid) {
        return r.emoji;
      }
    }
    return null;
  }

  /// Taps the heart button: thaws the default ❤️ when the user has no reaction
  /// (or a different one), and removes it when ❤️ is already theirs (toggle off).
  /// Use [setReaction] for picking a specific emoji.
  Future<void> toggleHeart(String photoId) async {
    final current = _currentMineEmoji(photoId);
    if (current == kDefaultReactionEmoji) {
      await remove(photoId);
    } else {
      await setReaction(photoId, kDefaultReactionEmoji);
    }
  }

  /// Sets the current user's reaction on [photoId] to [emoji] (create or change),
  /// optimistically. Rolls back and flags an error if the write fails.
  Future<void> setReaction(String photoId, String emoji) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null || !kReactionEmojis.contains(emoji)) {
      return;
    }

    final previous = _currentMineEmoji(photoId);
    if (previous == emoji) {
      return; // no change
    }

    // Optimistic: show the new emoji immediately.
    _pendingMine[photoId] = emoji;
    _errorPhotoIds.remove(photoId);
    notifyListeners();

    // Analytics — `add` (first reaction) vs `change` (swapped emoji). Never logs
    // the emoji itself or whose photo it is.
    AnalyticsService.instance
        .logReactionSet(previous == null ? 'add' : 'change');

    try {
      await _service.setReaction(
        coupleId: coupleId,
        photoId: photoId,
        uid: uid,
        emoji: emoji,
      );
    } catch (_) {
      _rollback(photoId, previous);
    }
  }

  /// Removes the current user's reaction from [photoId], optimistically.
  Future<void> remove(String photoId) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null) {
      return;
    }

    final previous = _currentMineEmoji(photoId);
    if (previous == null) {
      return; // nothing to remove
    }

    _pendingMine[photoId] = null; // optimistic removal
    _errorPhotoIds.remove(photoId);
    notifyListeners();

    AnalyticsService.instance.logReactionSet('remove');

    try {
      await _service.removeReaction(
        coupleId: coupleId,
        photoId: photoId,
        uid: uid,
      );
    } catch (_) {
      _rollback(photoId, previous);
    }
  }

  /// Resolves the user's effective current emoji (optimistic value wins).
  String? _currentMineEmoji(String photoId) {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    if (_pendingMine.containsKey(photoId)) {
      return _pendingMine[photoId];
    }
    return _serverEmojiFor(photoId, uid);
  }

  /// Reverts the optimistic override for [photoId] back to [previous] (the
  /// pre-action server value) and flags a transient error so the UI can show the
  /// retry SnackBar.
  void _rollback(String photoId, String? previous) {
    final uid = _myUid;
    // If the server already matches `previous`, no override is needed.
    if (uid != null && _serverEmojiFor(photoId, uid) == previous) {
      _pendingMine.remove(photoId);
    } else {
      _pendingMine[photoId] = previous;
    }
    _errorPhotoIds.add(photoId);
    notifyListeners();
  }

  /// Stops watching and resets state (e.g. on sign-out or leaving a couple).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _coupleId = null;
    _myUid = null;
    _serverReactions = const <String, List<PhotoReaction>>{};
    _pendingMine.clear();
    _errorPhotoIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
