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

  Stream<List<Photo>> watchCouplePhotos(String coupleId) {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return Stream<List<Photo>>.value(const <Photo>[]);
    }

    return _photosCollection(coupleId)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Photo.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
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
      final uploadTask = await _bucket.ref(remoteStoragePath).putFile(file);
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

