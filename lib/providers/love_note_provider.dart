import 'dart:async';

import 'package:flutter/material.dart';

import '../models/love_note.dart';
import '../services/love_note_service.dart';

/// State for the "Love note" Home card: streams both members' notes for the
/// active couple and exposes the partner's note (shown to the user) plus the
/// user's own note (prefilled when editing).
class LoveNoteProvider extends ChangeNotifier {
  LoveNoteProvider({LoveNoteService? service})
      : _service = service ?? LoveNoteService();

  final LoveNoteService _service;

  StreamSubscription<List<LoveNote>>? _subscription;
  String? _coupleId;
  String? _myUid;
  List<LoveNote> _notes = const <LoveNote>[];
  bool _isLoading = false;

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

    await _service.setMyNote(coupleId: coupleId, uid: uid, text: text);
    return true;
  }

  /// Stops watching and resets state (e.g. on sign-out or leaving a couple).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _coupleId = null;
    _myUid = null;
    _notes = const <LoveNote>[];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
