import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import '../models/photo.dart';
import '../services/analytics_service.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';

/// Photo state for the couple gallery (feature pagination, D1–D3):
///
/// - Photos live in an id-keyed ACCUMULATING map. The realtime Firestore
///   stream only watches the newest [_pageSize] docs (the "window"); older
///   pages are fetched once via [loadMorePhotos] and merged in. A photo never
///   disappears just because it slipped out of the window.
/// - Deletions: this client's own deletes remove from the map directly. A
///   partner's delete is detected from window emissions — a doc that vanished
///   from the window while being NEWER than the window's oldest item cannot
///   have merely slipped past the limit, so it was deleted (D4: deletes of
///   photos already outside the window stay stale until the next cold load —
///   accepted trade-off).
/// - [photoCount] reads the server-side aggregate `count()` so Profile stats
///   and the composer chip show the TRUE total, not just what's loaded (D2).
/// - [onThisDayPhotos] comes from a dedicated per-year range query (D3) so the
///   Home memory-cinema works even when the matching photo is ancient.
class PhotoProvider extends ChangeNotifier {
  PhotoProvider({PhotoService? photoService})
      : _photoService = photoService ?? PhotoService();

  /// Realtime window size AND "load more" page size (pagination D1).
  static const int _pageSize = 30;

  final PhotoService _photoService;
  final Map<String, Photo> _photosById = <String, Photo>{};
  StreamSubscription<List<Photo>>? _photoSubscription;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _loadingMessage;
  String? _errorMessage;

  // ── Pagination state (feature pagination) ────────────────────────────────
  /// Ids the realtime window contained on its previous emission — used to
  /// tell "deleted" apart from "slipped out of the window".
  Set<String> _lastWindowIds = <String>{};

  /// Oldest `uploadDate` of the CONTIGUOUS loaded prefix (window + fetched
  /// pages). Deliberately tracked apart from the map: on-this-day photos are
  /// also upserted into the map but must NOT drag the cursor into the past
  /// (that would skip everything in between).
  DateTime? _paginationCursor;
  bool _hasMorePhotos = false;
  bool _isLoadingMore = false;

  /// Server-side aggregate total (D2); null → fall back to loaded length.
  int? _totalCount;

  /// Set per [syncForUser] call so the first window emission of each couple
  /// session refreshes [_totalCount] exactly once.
  bool _countRefreshPending = false;

  List<Photo> _onThisDayPhotos = const <Photo>[];

  /// Dedup guard for [refreshOnThisDay] — one fetch per (couple, day).
  String? _onThisDayFetchKey;

  List<Photo> get photos => sortedPhotos;
  List<Photo> get sortedPhotos => _photosById.values.toList()
    ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

  /// Photos for the gallery FEED: only the CONTIGUOUS newest→cursor prefix.
  /// On-this-day extras (D3) are merged into [sortedPhotos] for the Home
  /// cinema/preview, but would render as a confusing chronological "hole" at
  /// the bottom of the feed until pagination catches up — so anything older
  /// than the pagination cursor is excluded here.
  List<Photo> get feedPhotos {
    final cursor = _paginationCursor;
    final all = sortedPhotos;
    if (cursor == null || !_photoService.isUsingFirebase) {
      return all;
    }
    return all.where((p) => !p.uploadDate.isBefore(cursor)).toList();
  }
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;
  bool get hasMorePhotos => _hasMorePhotos;
  bool get isLoadingMore => _isLoadingMore;

  /// Photos taken on today's month+day in earlier years (newest first).
  List<Photo> get onThisDayPhotos => _onThisDayPhotos;

  /// Total photos of the couple. Backed by the aggregate `count()` when
  /// available; otherwise (local mode / aggregate failed) the loaded length.
  int get photoCount => _totalCount ?? _photosById.length;

  /// Merges [photo] into the map, preserving a known-good local file path when
  /// the incoming (Firestore) copy doesn't carry one — same semantics as the
  /// old list-based merge.
  void _upsert(Photo photo) {
    final existing = _photosById[photo.id];
    if (existing != null && !photo.hasLocalPath && existing.hasLocalPath) {
      _photosById[photo.id] = photo.copyWith(path: existing.path);
    } else {
      _photosById[photo.id] = photo;
    }
  }

  void _replaceAll(Iterable<Photo> photos) {
    _photosById.clear();
    for (final photo in photos) {
      _photosById[photo.id] = photo;
    }
  }

  void _resetPaginationState() {
    _lastWindowIds = <String>{};
    _paginationCursor = null;
    _hasMorePhotos = false;
    _isLoadingMore = false;
    _totalCount = null;
    _countRefreshPending = false;
    _onThisDayPhotos = const <Photo>[];
    _onThisDayFetchKey = null;
  }

  Future<void> loadPhotos({AppUser? currentUser}) async {
    _currentUser = currentUser ?? _currentUser;

    if (_currentUser?.hasCouple == true) {
      await syncForUser(_currentUser);
      return;
    }

    _replaceAll(await StorageService.loadPhotos());
    notifyListeners();
  }

  Future<void> syncForUser(AppUser? currentUser) async {
    final previousCoupleId = _currentUser?.coupleId;
    _currentUser = currentUser;
    await _photoSubscription?.cancel();
    _photoSubscription = null;

    if (currentUser == null || !currentUser.hasCouple) {
      _photosById.clear();
      _resetPaginationState();
      await StorageService.clearPhotos();
      notifyListeners();
      return;
    }

    // Couple changed (e.g. left + re-paired): drop the previous couple's
    // accumulated pages. Re-syncing the SAME couple (pull-to-refresh) keeps
    // the map so the feed doesn't blank out while resubscribing.
    if (previousCoupleId != currentUser.coupleId) {
      _photosById.clear();
      _resetPaginationState();
    }

    if (!_photoService.isUsingFirebase) {
      // Local mode: everything lives in one JSON cache — load it all, no
      // pagination (hasMore stays false).
      _replaceAll(await StorageService.loadPhotos());
      notifyListeners();
      return;
    }

    _setLoading(true, message: AppL10n.strings.syncingLibrary);
    _clearError(notify: false);
    _countRefreshPending = true;

    _photoSubscription = _photoService
        .watchCouplePhotos(currentUser.coupleId!, limit: _pageSize)
        .listen(
      (windowPhotos) async {
        final membershipChanged = _applyWindowEmission(windowPhotos);

        if (_countRefreshPending) {
          _countRefreshPending = false;
          unawaited(_refreshTotalCount());
        } else if (membershipChanged) {
          // A partner add/delete reached us through the window: refresh the
          // aggregate so Profile's total tracks realtime changes. Skipped
          // whenever the emission didn't change the id set (caption edits,
          // path-only merges, …) — cheap debounce against per-emission reads.
          unawaited(_refreshTotalCount());
        }

        await StorageService.savePhotos(sortedPhotos);
        _setLoading(false, notify: false);
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = '$error';
        _setLoading(false, notify: false);
        notifyListeners();
      },
    );
  }

  /// Merges one realtime window emission into the accumulated map and updates
  /// the pagination cursor / in-window delete detection (see class doc).
  ///
  /// Returns true when the emission changed the ID MEMBERSHIP of the loaded
  /// set (a never-seen photo appeared, or an in-window delete was detected) —
  /// the caller uses that to refresh the aggregate count so Profile's total
  /// tracks partner adds/deletes in realtime.
  bool _applyWindowEmission(List<Photo> windowPhotos) {
    final newIds = windowPhotos.map((p) => p.id).toSet();
    final windowOldest =
        windowPhotos.isEmpty ? null : windowPhotos.last.uploadDate;
    final windowFull = windowPhotos.length >= _pageSize;

    // Discontinuous re-sync detection. INVARIANT: [feedPhotos] must always be
    // a CONTIGUOUS newest→cursor prefix of the timeline — no hidden holes.
    // When the stream re-syncs (app resume / reconnect / cache→server) after
    // MORE than a full page of new photos arrived, the new window shares no
    // doc with the prefix we accumulated; merging it as-is would leave an
    // invisible gap between the window's oldest doc and the old prefix, and
    // loadMore (which only digs BELOW the cursor) could never fill it. So we
    // restart pagination from this window: the cursor jumps to its oldest doc
    // and the previously accumulated pages drop OUT of [feedPhotos] (they stay
    // in the map, like the on-this-day extras, and get re-merged page by page
    // as the user scrolls — loadMore upserts by id, so no duplicates).
    final cursor = _paginationCursor;
    if (cursor != null &&
        windowFull &&
        windowOldest != null &&
        windowOldest.isAfter(cursor)) {
      final prefixIds = _photosById.values
          .where((p) => !p.uploadDate.isBefore(cursor))
          .map((p) => p.id)
          .toSet();
      if (prefixIds.isNotEmpty && newIds.intersection(prefixIds).isEmpty) {
        _paginationCursor = windowOldest;
        _hasMorePhotos = true;
      }
    }

    var membershipChanged = false;

    // Partner-delete detection: ids gone from the window that could not have
    // slipped past the limit (window not full, or the photo is newer than the
    // window's oldest doc) were deleted server-side → drop them here too.
    for (final id in _lastWindowIds) {
      if (newIds.contains(id)) {
        continue;
      }
      final gone = _photosById[id];
      if (gone == null) {
        continue;
      }
      if (!windowFull ||
          windowOldest == null ||
          gone.uploadDate.isAfter(windowOldest)) {
        _photosById.remove(id);
        membershipChanged = true;
      }
    }
    _lastWindowIds = newIds;

    for (final photo in windowPhotos) {
      if (!_photosById.containsKey(photo.id)) {
        membershipChanged = true;
      }
      _upsert(photo);
    }

    // First emission of this couple session initializes the cursor + hasMore;
    // afterwards the cursor only moves deeper via loadMore — or jumps forward
    // on a discontinuous re-sync (handled above).
    if (_paginationCursor == null) {
      _paginationCursor = windowOldest;
      _hasMorePhotos = windowFull;
    }

    return membershipChanged;
  }

  /// Fetches the next (older) page and merges it in. Safe to spam from scroll
  /// callbacks: re-entrancy guarded and a no-op when nothing more remains.
  Future<void> loadMorePhotos() async {
    final coupleId = _currentUser?.coupleId;
    final cursor = _paginationCursor;
    if (_isLoadingMore ||
        !_hasMorePhotos ||
        cursor == null ||
        coupleId == null ||
        !_photoService.isUsingFirebase) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final older = await _photoService.fetchOlderPhotos(
        coupleId,
        startAfter: cursor,
        limit: _pageSize,
      );
      // Re-check the couple AFTER the await (same guard as
      // [_refreshTotalCount]/[refreshOnThisDay]): a sign-out or couple switch
      // while the fetch was in flight must not contaminate the new session's
      // map nor the on-disk JSON cache — drop the stale page entirely.
      if (coupleId == _currentUser?.coupleId) {
        for (final photo in older) {
          _upsert(photo);
        }
        if (older.isNotEmpty) {
          _paginationCursor = older.last.uploadDate;
        }
        _hasMorePhotos = older.length >= _pageSize;
        await StorageService.savePhotos(sortedPhotos);
      }
    } catch (_) {
      // Keep hasMore as-is so the next scroll retries.
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Refreshes the aggregate total (D2). Null result (local / failure) keeps
  /// the loaded-length fallback.
  Future<void> _refreshTotalCount() async {
    final coupleId = _currentUser?.coupleId;
    if (coupleId == null || !_photoService.isUsingFirebase) {
      return;
    }

    final count = await _photoService.countPhotos(coupleId);
    if (count != null && coupleId == _currentUser?.coupleId) {
      _totalCount = count;
      notifyListeners();
    }
  }

  /// Loads the "on this day" memories via dedicated range queries (D3) and
  /// merges them into the map so the cinema/preview share the same objects.
  /// Deduped per (couple, calendar day) — cheap to re-call from Home builds.
  Future<void> refreshOnThisDay({required DateTime anniversary}) async {
    final coupleId = _currentUser?.coupleId;
    if (coupleId == null) {
      return;
    }

    final now = DateTime.now();

    // Dedup BEFORE branching on mode — the key doesn't depend on Firebase.
    // Home re-calls this from a post-frame callback on EVERY build, so each
    // (couple, day) must resolve to at most one recompute; an unconditional
    // notify here would schedule another build → another call → rebuild loop.
    final key = '$coupleId|${now.year}-${now.month}-${now.day}'
        '|${anniversary.year}';
    if (_onThisDayFetchKey == key) {
      return;
    }

    if (!_photoService.isUsingFirebase) {
      // Local mode holds the full library already — filter in memory, and
      // only notify when the result actually changed so repeated calls stay
      // idempotent (no notify → no extra build).
      _onThisDayFetchKey = key;
      final matches = sortedPhotos
          .where((p) =>
              p.uploadDate.month == now.month &&
              p.uploadDate.day == now.day &&
              p.uploadDate.year < now.year)
          .toList();
      if (!_samePhotoIds(matches, _onThisDayPhotos)) {
        _onThisDayPhotos = matches;
        notifyListeners();
      }
      return;
    }

    _onThisDayFetchKey = key;

    try {
      final matches = await _photoService.fetchOnThisDay(
        coupleId,
        today: now,
        since: anniversary,
      );
      if (coupleId != _currentUser?.coupleId) {
        return; // Couple changed while fetching.
      }
      for (final photo in matches) {
        _upsert(photo);
      }
      _onThisDayPhotos = matches
        ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      notifyListeners();
    } catch (_) {
      _onThisDayFetchKey = null; // Allow a retry on the next call.
    }
  }

  /// True when [a] and [b] hold the same photo ids in the same order — used
  /// to keep the local-mode on-this-day recompute notify-free when nothing
  /// changed (both lists are newest-first, so order is deterministic).
  bool _samePhotoIds(List<Photo> a, List<Photo> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }

  Future<void> addPhoto(
    String imagePath, {
    required AppUser currentUser,
    String? caption,
  }) async {
    // Capture whether this couple had any photos BEFORE the upload, so we can
    // report `is_first` to analytics (no caption / no PII is ever logged).
    final wasFirstPhoto = _photosById.isEmpty;

    _setLoading(true, message: AppL10n.strings.uploadingPhoto);
    _clearError(notify: false);

    try {
      final photo = await _photoService.addPhoto(
        currentUser: currentUser,
        localImagePath: imagePath,
        caption: caption,
      );

      if (!_photoService.isUsingFirebase || !currentUser.hasCouple) {
        _upsert(photo);
        await StorageService.savePhotos(sortedPhotos);
        notifyListeners();
      } else {
        unawaited(_refreshTotalCount());
      }

      // Analytics — success path (⭐⭐ North Star). Mark the user as having
      // posted at least one photo.
      AnalyticsService.instance
        ..logPhotoPosted(isFirst: wasFirstPhoto)
        ..setHasPostedPhoto(true);
    } on PhotoSyncException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Uploads a batch of photos under a single blocking overlay (no per-photo
  /// on/off flicker). The overlay message advances "Uploading i/total" via
  /// [progress] as each upload starts. A failed upload does NOT abort the batch
  /// — it's skipped and counted, so the rest still go through. Returns the
  /// number of successful uploads (caller can derive the failure count).
  ///
  /// Unlike [addPhoto], this owns the loading lifecycle for the whole batch and
  /// never rethrows; surface the aggregate result to the user instead.
  Future<int> addPhotosBatch(
    List<String> imagePaths, {
    required AppUser currentUser,
    required String Function(int current, int total) progress,
  }) async {
    if (imagePaths.isEmpty) {
      return 0;
    }

    final total = imagePaths.length;
    final wasFirstPhoto = _photosById.isEmpty;
    var successCount = 0;

    _setLoading(true, message: progress(1, total));
    _clearError(notify: false);

    try {
      for (var i = 0; i < total; i++) {
        // Keep the overlay visible; just advance its label per item.
        _loadingMessage = progress(i + 1, total);
        notifyListeners();

        try {
          final photo = await _photoService.addPhoto(
            currentUser: currentUser,
            localImagePath: imagePaths[i],
          );

          if (!_photoService.isUsingFirebase || !currentUser.hasCouple) {
            _upsert(photo);
            await StorageService.savePhotos(sortedPhotos);
            notifyListeners();
          }

          successCount++;
        } on PhotoSyncException catch (e) {
          // Remember the last failure reason but keep going through the batch.
          _errorMessage = e.message;
        }
      }

      if (successCount > 0) {
        AnalyticsService.instance
          ..logPhotoPosted(isFirst: wasFirstPhoto)
          ..setHasPostedPhoto(true);
        if (_photoService.isUsingFirebase && currentUser.hasCouple) {
          unawaited(_refreshTotalCount());
        }
      }
    } finally {
      _setLoading(false);
    }

    return successCount;
  }

  Future<void> deletePhoto(
    String photoId, {
    required AppUser currentUser,
  }) async {
    final photo = _photosById[photoId];
    if (photo == null) {
      return;
    }

    _setLoading(true, message: AppL10n.strings.deletingPhoto);
    _clearError(notify: false);

    try {
      await _photoService.deletePhoto(currentUser: currentUser, photo: photo);

      // This client's own delete: drop it from the accumulated map right away
      // (D4 — the realtime window only covers the newest page, so waiting for
      // an emission would leave older deleted photos behind).
      _photosById.remove(photoId);
      _lastWindowIds.remove(photoId);
      _onThisDayPhotos =
          _onThisDayPhotos.where((p) => p.id != photoId).toList();
      await StorageService.savePhotos(sortedPhotos);
      if (_photoService.isUsingFirebase && currentUser.hasCouple) {
        unawaited(_refreshTotalCount());
      }
      notifyListeners();

      // Analytics — success path.
      AnalyticsService.instance.logPhotoDeleted();
    } on PhotoSyncException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePhotoCaption(
    String photoId,
    String newCaption, {
    required AppUser currentUser,
  }) async {
    final photo = _photosById[photoId];
    if (photo == null) {
      return;
    }

    _setLoading(true, message: AppL10n.strings.updatingCaption);
    _clearError(notify: false);

    try {
      final updatedPhoto = photo.copyWith(
        caption: newCaption.trim().isEmpty ? null : newCaption.trim(),
        updatedAt: DateTime.now(),
      );

      await _photoService.updateCaption(
        currentUser: currentUser,
        photo: updatedPhoto,
        newCaption: newCaption,
      );

      // Reflect immediately; photos outside the realtime window get no
      // emission, so the map is the source of truth for them.
      _photosById[photoId] = updatedPhoto;
      if (!_photoService.isUsingFirebase || !currentUser.hasCouple) {
        await StorageService.savePhotos(sortedPhotos);
      }

      notifyListeners();
    } on PhotoSyncException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Records a moderation report for [photo] (Apple Guideline 1.2 UGC).
  /// Best-effort: never throws or surfaces errors to the UI (see service).
  Future<void> reportPhoto({
    required Photo photo,
    required String reporterUid,
    required String reason,
  }) async {
    await _photoService.reportPhoto(
      reporterUid: reporterUid,
      coupleId: photo.coupleId ?? '',
      photoId: photo.id,
      authorUserId: photo.authorUserId ?? '',
      reason: reason,
    );
  }

  Future<void> clearForSignOut() async {
    await _photoSubscription?.cancel();
    _photoSubscription = null;
    _currentUser = null;
    _photosById.clear();
    _resetPaginationState();
    await StorageService.clearPhotos();
    notifyListeners();
  }

  Future<void> clearLocalCache() async {
    await StorageService.clearPhotos();
    notifyListeners();
  }

  void _clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  void _setLoading(bool value, {bool notify = true, String? message}) {
    _isLoading = value;
    _loadingMessage = value ? (message ?? _loadingMessage) : null;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _photoSubscription?.cancel();
    super.dispose();
  }
}
