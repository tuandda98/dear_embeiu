import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import '../models/photo.dart';
import 'firebase_bootstrap_service.dart';
import 'storage_service.dart';

class PhotoSyncException implements Exception {
  const PhotoSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PhotoService {
  PhotoService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;
  final Uuid _uuid = const Uuid();

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _photosCollection(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('photos');

  Photo _photoFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      Photo.fromJson({
        'id': doc.id,
        ...doc.data(),
      });

  /// Streams the [limit] newest photos for the couple (the realtime "window",
  /// feature pagination D1). Older photos are fetched on demand via
  /// [fetchOlderPhotos] and accumulated by the provider.
  Stream<List<Photo>> watchCouplePhotos(String coupleId, {int limit = 30}) {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return Stream<List<Photo>>.value(const <Photo>[]);
    }

    return _photosCollection(coupleId)
        .orderBy('uploadDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_photoFromDoc).toList());
  }

  /// One-shot page of photos strictly older than [startAfter], newest first
  /// (pagination D1). `uploadDate` is written as a client DateTime → stored as
  /// a Firestore Timestamp, and read back with microsecond precision (see
  /// [Photo._parseDateTime]) — so `Timestamp.fromDate` reconstructs the exact
  /// stored cursor value.
  Future<List<Photo>> fetchOlderPhotos(
    String coupleId, {
    required DateTime startAfter,
    int limit = 30,
  }) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return const <Photo>[];
    }

    final snapshot = await _photosCollection(coupleId)
        .orderBy('uploadDate', descending: true)
        .startAfter([Timestamp.fromDate(startAfter)])
        .limit(limit)
        .get();
    return snapshot.docs.map(_photoFromDoc).toList();
  }

  /// Total number of photos via the server-side aggregate `count()` — does not
  /// download any documents (pagination D2). Returns null when Firebase is
  /// unavailable or the aggregate fails, so callers can fall back to the
  /// locally-loaded length.
  Future<int?> countPhotos(String coupleId) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return null;
    }

    try {
      final snapshot = await _photosCollection(coupleId).count().get();
      return snapshot.count;
    } catch (_) {
      return null;
    }
  }

  /// Fetches every photo taken on today's month+day in earlier years
  /// (pagination D3 — the Home "on this day" memory must not depend on the
  /// realtime window). One small range query per candidate year, from
  /// [since].year up to (but excluding) [today].year; years where the date
  /// doesn't exist (Feb 29 in a non-leap year) are skipped.
  Future<List<Photo>> fetchOnThisDay(
    String coupleId, {
    required DateTime today,
    required DateTime since,
  }) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return const <Photo>[];
    }

    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var year = since.year; year < today.year; year++) {
      final dayStart = DateTime(year, today.month, today.day);
      // Dart normalizes invalid dates (Feb 29 → Mar 1): skip those years.
      if (dayStart.month != today.month || dayStart.day != today.day) {
        continue;
      }
      queries.add(
        _photosCollection(coupleId)
            .where(
              'uploadDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
              isLessThan: Timestamp.fromDate(
                dayStart.add(const Duration(days: 1)),
              ),
            )
            .get(),
      );
    }

    if (queries.isEmpty) {
      return const <Photo>[];
    }

    final snapshots = await Future.wait(queries);
    return [
      for (final snapshot in snapshots)
        for (final doc in snapshot.docs) _photoFromDoc(doc),
    ];
  }

  Future<Photo> addPhoto({
    required AppUser currentUser,
    required String localImagePath,
    String? caption,
  }) async {
    if (!currentUser.hasCouple) {
      throw PhotoSyncException(AppL10n.strings.photoConnectCoupleFirst);
    }

    final localCopyPath = await StorageService.savePhotoFile(localImagePath);
    final uploadDate = DateTime.now();
    final photoId = _uuid.v4();

    if (!isUsingFirebase) {
      return Photo(
        id: photoId,
        path: localCopyPath ?? localImagePath,
        coupleId: currentUser.coupleId,
        authorUserId: currentUser.id,
        authorName: currentUser.displayName,
        uploadDate: uploadDate,
        caption: caption,
        updatedAt: uploadDate,
      );
    }

    final file = File(localImagePath);
    if (!await file.exists()) {
      throw PhotoSyncException(AppL10n.strings.photoNotFoundToPost);
    }

    final coupleId = currentUser.coupleId!;
    final extension = _guessFileExtension(localImagePath);
    final remoteStoragePath = 'couple_photos/$coupleId/$photoId$extension';

    try {
      // Set an explicit image content-type. The Storage rule requires
      // `request.resource.contentType.matches('image/.*')`; relying on
      // putFile's auto-detection can yield `application/octet-stream` for a
      // file with an unusual/missing extension (some HEIC / cache-dir temp
      // paths) → the upload is rejected and the user "can't post a photo".
      final uploadTask = await _bucket.ref(remoteStoragePath).putFile(
            file,
            SettableMetadata(contentType: _contentTypeForExtension(extension)),
          );
      final remoteUrl = await uploadTask.ref.getDownloadURL();

      final photo = Photo(
        id: photoId,
        path: localCopyPath ?? localImagePath,
        remoteUrl: remoteUrl,
        storagePath: remoteStoragePath,
        coupleId: coupleId,
        authorUserId: currentUser.id,
        authorName: currentUser.displayName,
        uploadDate: uploadDate,
        caption: caption,
        updatedAt: uploadDate,
      );

      await _photosCollection(coupleId).doc(photoId).set(photo.toFirestore());
      return photo;
    } on FirebaseException catch (e) {
      throw PhotoSyncException(_mapFirebaseError(e));
    }
  }

  Future<void> updateCaption({
    required AppUser currentUser,
    required Photo photo,
    required String newCaption,
  }) async {
    final updatedPhoto = photo.copyWith(
      caption: newCaption.trim().isEmpty ? null : newCaption.trim(),
      updatedAt: DateTime.now(),
    );

    if (!isUsingFirebase || !currentUser.hasCouple || updatedPhoto.coupleId == null) {
      return;
    }

    try {
      await _photosCollection(updatedPhoto.coupleId!).doc(updatedPhoto.id).set(
            updatedPhoto.toFirestoreUpdate(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      throw PhotoSyncException(_mapFirebaseError(e));
    }
  }

  /// Replaces the image FILE of an already-posted [photo] (caption/date/author
  /// stay). Uploads the new file to a fresh storage path (a per-replace
  /// uniquifier so the CDN can't serve the stale cached image), merge-updates
  /// the doc's `remoteUrl`/`storagePath`/`updatedAt`, then best-effort deletes
  /// the old storage object. The immutable `coupleId`/`authorUserId`/
  /// `uploadDate` are preserved, so the firestore.rules photo-update guard
  /// passes (only the mutable image fields change).
  Future<Photo> replacePhotoImage({
    required AppUser currentUser,
    required Photo photo,
    required String localImagePath,
  }) async {
    final localCopyPath = await StorageService.savePhotoFile(localImagePath);
    final now = DateTime.now();
    final newLocalPath = localCopyPath ?? localImagePath;

    // Local-only fallback (no Firebase / no couple): just swap the cached file.
    if (!isUsingFirebase || !currentUser.hasCouple || photo.coupleId == null) {
      if (photo.hasLocalPath && photo.path != newLocalPath) {
        await StorageService.deletePhotoFile(photo.path);
      }
      return photo.copyWith(path: newLocalPath, updatedAt: now);
    }

    final file = File(localImagePath);
    if (!await file.exists()) {
      throw PhotoSyncException(AppL10n.strings.photoNotFoundToPost);
    }

    final coupleId = photo.coupleId!;
    final extension = _guessFileExtension(localImagePath);
    // New path (id + timestamp) so the download URL changes — replacing in place
    // would let a cached old image linger behind the same URL.
    final newStoragePath =
        'couple_photos/$coupleId/${photo.id}_${now.millisecondsSinceEpoch}$extension';

    try {
      final uploadTask = await _bucket.ref(newStoragePath).putFile(
            file,
            SettableMetadata(contentType: _contentTypeForExtension(extension)),
          );
      final newRemoteUrl = await uploadTask.ref.getDownloadURL();

      final oldStoragePath = photo.storagePath?.trim();
      final updatedPhoto = photo.copyWith(
        path: newLocalPath,
        remoteUrl: newRemoteUrl,
        storagePath: newStoragePath,
        updatedAt: now,
      );

      await _photosCollection(coupleId).doc(photo.id).set(
            updatedPhoto.toFirestoreUpdate(),
            SetOptions(merge: true),
          );

      // Best-effort cleanup of the previous objects — never fail the replace if
      // the old file is already gone / can't be removed.
      if (oldStoragePath != null &&
          oldStoragePath.isNotEmpty &&
          oldStoragePath != newStoragePath) {
        try {
          await _bucket.ref(oldStoragePath).delete();
        } catch (_) {}
      }
      if (photo.hasLocalPath && photo.path != newLocalPath) {
        await StorageService.deletePhotoFile(photo.path);
      }

      return updatedPhoto;
    } on FirebaseException catch (e) {
      throw PhotoSyncException(_mapFirebaseError(e));
    }
  }

  Future<void> deletePhoto({
    required AppUser currentUser,
    required Photo photo,
  }) async {
    if (photo.hasLocalPath) {
      await StorageService.deletePhotoFile(photo.path);
    }

    if (!isUsingFirebase || !currentUser.hasCouple || photo.coupleId == null) {
      return;
    }

    try {
      await _photosCollection(photo.coupleId!).doc(photo.id).delete();
      final storagePath = photo.storagePath?.trim();
      if (storagePath != null && storagePath.isNotEmpty) {
        await _bucket.ref(storagePath).delete();
      }
    } on FirebaseException catch (e) {
      throw PhotoSyncException(_mapFirebaseError(e));
    }
  }

  /// Records a moderation report for a photo (Apple Guideline 1.2 UGC).
  /// Writes a create-only doc to the top-level `reports` collection.
  ///
  /// Best-effort by design: when Firebase is unavailable (local fallback) or
  /// the write fails, this silently no-ops so the UI can always report success
  /// without leaking errors to the user.
  Future<void> reportPhoto({
    required String reporterUid,
    required String coupleId,
    required String photoId,
    required String authorUserId,
    required String reason,
  }) async {
    if (!isUsingFirebase || reporterUid.trim().isEmpty) {
      return;
    }

    try {
      await _db.collection('reports').add({
        'reporterUid': reporterUid,
        'coupleId': coupleId,
        'photoId': photoId,
        'authorUserId': authorUserId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      // Swallow: reporting is best-effort, never surface backend errors.
      return;
    }
  }

  String _guessFileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return '.jpg';
    }

    final extension = path.substring(dotIndex).toLowerCase();
    if (extension.length > 6) {
      return '.jpg';
    }
    return extension;
  }

  /// Maps a file extension to an `image/*` content-type so the Storage rule's
  /// `contentType.matches('image/.*')` always passes. Defaults to image/jpeg
  /// (matches the `.jpg` fallback in [_guessFileExtension]).
  String _contentTypeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.bmp':
        return 'image/bmp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _mapFirebaseError(FirebaseException exception) {
    final l10n = AppL10n.strings;
    switch (exception.code) {
      case 'permission-denied':
        return l10n.photoSyncPermissionDenied;
      case 'unauthenticated':
        return l10n.photoSyncSessionExpired;
      case 'object-not-found':
        return l10n.photoFileNotFoundStorage;
      case 'unauthorized':
        return l10n.photoStorageUnauthorized;
      case 'unavailable':
        return l10n.photoFirebaseUnavailable;
      default:
        return exception.message ?? l10n.photoSyncGeneric;
    }
  }
}

