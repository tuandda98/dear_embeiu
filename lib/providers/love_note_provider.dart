import 'dart:async';

import 'package:flutter/material.dart';

import '../models/love_note.dart';
import '../services/analytics_service.dart';
import '../services/love_note_service.dart';

/// State for the "Love note" Home card: streams both members' notes for the
/// active couple and exposes the partner's note (shown to the user) plus the
/// user's own note (prefilled when editing).
class LoveNoteProvider extends ChangeNotifier {
  LoveNoteProvider({LoveNoteService? service})
      : _service = service ?? LoveNoteService();

  final LoveNoteService _service;

  /// Realtime window size AND "show more" page size for the note history
  /// archive (feature pagination D5).
  static const int _historyPageSize = 50;

  StreamSubscription<List<LoveNote>>? _subscription;
  String? _coupleId;
  String? _myUid;
  List<LoveNote> _notes = const <LoveNote>[];
  bool _isLoading = false;

  // ── History archive state (pagination D5) ────────────────────────────────
  // Active only while the history screen is open ([startHistory] /
  // [stopHistory]). Firebase mode: the realtime stream watches the newest 50
  // entries; older pages are fetched once and ACCUMULATED in an id-keyed map
  // (history is append-only, so entries never need removing). Local mode: the
  // Hive archive is loaded whole (small data, no doc ids) — no pagination.
  StreamSubscription<List<LoveNote>>? _historySubscription;
  final Map<String, LoveNote> _historyById = <String, LoveNote>{};
  List<LoveNote> _localHistoryEntries = const <LoveNote>[];
  bool _historyLoading = false;
  bool _historyHasMore = false;
  bool _historyLoadingMore = false;

  /// Oldest `createdAt` of the contiguous loaded prefix (window + pages).
  DateTime? _historyCursor;

  /// The partner's note (author != current uid), or null when none exists yet.
  LoveNote? get partnerNote {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    for (final note in _notes) {
      if (note.authorUserId != uid && note.hasText) {
        return note;
      }
    }
    return null;
  }

  /// The current user's own note (author == current uid), or null.
  LoveNote? get myNote {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    for (final note in _notes) {
      if (note.authorUserId == uid) {
        return note;
      }
    }
    return null;
  }

  bool get isLoading => _isLoading;

  /// Begins watching the notes for [coupleId] on behalf of [myUid]. Safe to
  /// call repeatedly; it no-ops when the (couple, uid) pair is unchanged and
  /// already streaming, and resubscribes when either changes.
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
    _notes = const <LoveNote>[];
    _isLoading = true;
    // Couple (or uid) changed: any open history stream belongs to the old
    // couple — drop it. The archive screen re-arms via startHistory if open.
    _historySubscription?.cancel();
    _historySubscription = null;
    _resetHistoryState();
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.watchNotes(coupleId).listen(
      (notes) {
        _notes = notes;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Saves (overwrites) the current user's note. Returns false when there is no
  /// active couple/uid to write to.
  Future<bool> setMyNote(String text) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null) {
      return false;
    }

    // Decide create vs update BEFORE saving — based only on whether a note
    // already existed, never on its text (🔒 no content is logged).
    final action = myNote == null ? 'create' : 'update';

    await _service.setMyNote(coupleId: coupleId, uid: uid, text: text);

    // Append every non-empty send to the immutable history timeline —
    // INCLUDING repeats ("yêu em" ×2 is a real chat message; user 2026-06-11,
    // after the chat composer landed). The old same-text dedupe predates the
    // chat — and the Home ritual sheet still gates identical re-saves itself
    // (pops false) before ever calling here, so its flow stays duplicate-free.
    // BEST-EFFORT: a history failure (e.g. offline, or rules not yet deployed)
    // must never break the core note save above.
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      try {
        await _service.appendHistory(coupleId: coupleId, uid: uid, text: text);
      } catch (_) {
        // Swallow — the note itself is already saved; the archive is additive.
      }
    }

    // Analytics — success path only.
    AnalyticsService.instance.logLoveNoteSet(action);
    return true;
  }

  // ── History archive (pagination D5) ──────────────────────────────────────

  /// Merged history entries, newest first.
  List<LoveNote> get historyEntries {
    if (!_service.isUsingFirebase) {
      return _localHistoryEntries;
    }
    return _historyById.values.toList()
      ..sort((a, b) => (b.updatedAt ?? DateTime(0))
          .compareTo(a.updatedAt ?? DateTime(0)));
  }

  /// True while the FIRST history page is loading (skeleton state).
  bool get historyLoading => _historyLoading;
  bool get historyHasMore => _historyHasMore;
  bool get historyLoadingMore => _historyLoadingMore;

  /// Starts streaming the newest history page for the archive screen. Safe to
  /// call from `initState` — it never notifies synchronously (the stream
  /// callbacks do). No-ops when already streaming or without an active couple.
  void startHistory() {
    final coupleId = _coupleId;
    if (coupleId == null || coupleId.trim().isEmpty) {
      return;
    }
    if (_historySubscription != null) {
      return;
    }

    _historyLoading = _historyById.isEmpty && _localHistoryEntries.isEmpty;
    _historySubscription = _service.watchHistory(coupleId).listen(
      (entries) {
        if (!_service.isUsingFirebase) {
          // Local archive arrives whole — nothing more to page in.
          _localHistoryEntries = entries;
          _historyHasMore = false;
        } else {
          for (final note in entries) {
            final id = note.id;
            if (id != null) {
              _historyById[id] = note;
            }
          }
          // First emission initializes the cursor + hasMore; later emissions
          // only carry NEWER entries (the window), so the cursor stays put.
          if (_historyCursor == null && entries.isNotEmpty) {
            _historyCursor = entries.last.updatedAt;
            _historyHasMore = entries.length >= _historyPageSize;
          }
        }
        _historyLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _historyLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stops the history stream and frees the archive state (screen closed).
  void stopHistory() {
    _historySubscription?.cancel();
    _historySubscription = null;
    _resetHistoryState();
  }

  /// Fetches the next (older) history page. Re-entrancy guarded; no-op when
  /// nothing more remains.
  Future<void> loadMoreHistory() async {
    final coupleId = _coupleId;
    final cursor = _historyCursor;
    if (_historyLoadingMore ||
        !_historyHasMore ||
        coupleId == null ||
        cursor == null) {
      return;
    }

    _historyLoadingMore = true;
    notifyListeners();

    try {
      final older = await _service.fetchOlderHistory(
        coupleId,
        startAfterCreatedAt: cursor,
        limit: _historyPageSize,
      );
      // Re-check the couple AFTER the await (same race as
      // PhotoProvider.loadMorePhotos): a sign-out or couple switch while the
      // fetch was in flight must not leak the previous couple's notes into
      // the new session's archive — drop the stale page entirely.
      if (coupleId == _coupleId) {
        for (final note in older) {
          final id = note.id;
          if (id != null) {
            _historyById[id] = note;
          }
        }
        final oldest = older.isEmpty ? null : older.last.updatedAt;
        if (oldest != null) {
          _historyCursor = oldest;
        }
        _historyHasMore = older.length >= _historyPageSize;
      }
    } catch (_) {
      // Keep hasMore so the "show more" button stays available for a retry.
    }

    _historyLoadingMore = false;
    notifyListeners();
  }

  void _resetHistoryState() {
    _historyById.clear();
    _localHistoryEntries = const <LoveNote>[];
    _historyLoading = false;
    _historyHasMore = false;
    _historyLoadingMore = false;
    _historyCursor = null;
  }

  /// Stops watching and resets state (e.g. on sign-out or leaving a couple).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _historySubscription?.cancel();
    _historySubscription = null;
    _resetHistoryState();
    _coupleId = null;
    _myUid = null;
    _notes = const <LoveNote>[];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}
