import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/journal_day.dart';
import '../services/daily_question_service.dart';

/// Loading status for the couple journal screen (feature couple-journal).
enum JournalStatus { initial, loading, ready, error }

/// State for the "Question journal" screen: loads revealed Q&A days for the
/// active couple, newest first, with cursor-based "load more" paging.
///
/// Deliberately NOT a realtime stream — the journal is history (read once +
/// paginate). It is created fresh per screen open (each [JournalScreen] owns a
/// [ChangeNotifierProvider]) so there's no global lifecycle to wire.
class JournalProvider extends ChangeNotifier {
  JournalProvider({
    required this.coupleId,
    required this.myUid,
    DailyQuestionService? service,
    this.pageSize = 30,
  }) : _service = service ?? DailyQuestionService();

  final DailyQuestionService _service;
  final String coupleId;
  final String myUid;
  final int pageSize;

  JournalStatus _status = JournalStatus.initial;
  final List<JournalDay> _days = <JournalDay>[];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = false;
  bool _loadingMore = false;

  JournalStatus get status => _status;
  List<JournalDay> get days => List.unmodifiable(_days);
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;
  bool get isEmpty => _status == JournalStatus.ready && _days.isEmpty;

  /// Loads the first page. Safe to call again to retry after an error.
  Future<void> load() async {
    _status = JournalStatus.loading;
    _days.clear();
    _cursor = null;
    _hasMore = false;
    notifyListeners();

    try {
      final page = await _service.loadJournal(
        coupleId: coupleId,
        myUid: myUid,
        limit: pageSize,
      );
      _days.addAll(page.days);
      _cursor = page.lastDoc;
      _hasMore = page.hasMore;
      _status = JournalStatus.ready;
    } catch (_) {
      _status = JournalStatus.error;
    }
    notifyListeners();
  }

  /// Loads the next page (no-op when nothing more / already loading).
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _cursor == null) {
      return;
    }
    _loadingMore = true;
    notifyListeners();

    try {
      final page = await _service.loadJournal(
        coupleId: coupleId,
        myUid: myUid,
        startAfter: _cursor,
        limit: pageSize,
      );
      _days.addAll(page.days);
      _cursor = page.lastDoc;
      _hasMore = page.hasMore;
    } catch (_) {
      // Keep what we have; "load more" simply did nothing on failure. The
      // button stays available so the user can retry.
    }
    _loadingMore = false;
    notifyListeners();
  }
}
