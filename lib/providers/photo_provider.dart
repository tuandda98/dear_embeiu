import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import '../models/photo.dart';
import '../services/analytics_service.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';

class PhotoProvider extends ChangeNotifier {
  PhotoProvider({PhotoService? photoService})
      : _photoService = photoService ?? PhotoService();

  final PhotoService _photoService;
  List<Photo> _photos = [];
  StreamSubscription<List<Photo>>? _photoSubscription;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _loadingMessage;
  String? _errorMessage;

  List<Photo> get photos => _photos;
  List<Photo> get sortedPhotos => [..._photos]..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadPhotos({AppUser? currentUser}) async {
    _currentUser = currentUser ?? _currentUser;

    if (_currentUser?.hasCouple == true) {
      await syncForUser(_currentUser);
      return;
    }

    _photos = await StorageService.loadPhotos();
    notifyListeners();
  }

  Future<void> syncForUser(AppUser? currentUser) async {
    _currentUser = currentUser;
    await _photoSubscription?.cancel();
    _photoSubscription = null;

    if (currentUser == null || !currentUser.hasCouple) {
      _photos = [];
      await StorageService.clearPhotos();
      notifyListeners();
      return;
    }

    if (!_photoService.isUsingFirebase) {
      _photos = await StorageService.loadPhotos();
      notifyListeners();
      return;
    }

    _setLoading(true, message: AppL10n.strings.syncingLibrary);
    _clearError(notify: false);

    _photoSubscription = _photoService.watchCouplePhotos(currentUser.coupleId!).listen(
      (photos) async {
        _photos = photos.map((photo) {
          final existingIndex = _photos.indexWhere((item) => item.id == photo.id);
          if (existingIndex == -1) {
            return photo;
          }

          final existing = _photos[existingIndex];
          if (photo.hasLocalPath || !existing.hasLocalPath) {
            return photo;
          }

          return photo.copyWith(path: existing.path);
        }).toList();
        await StorageService.savePhotos(_photos);
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

  Future<void> addPhoto(
    String imagePath, {
    required AppUser currentUser,
    String? caption,
  }) async {
    // Capture whether this couple had any photos BEFORE the upload, so we can
    // report `is_first` to analytics (no caption / no PII is ever logged).
    final wasFirstPhoto = _photos.isEmpty;

    _setLoading(true, message: AppL10n.strings.uploadingPhoto);
    _clearError(notify: false);

    try {
      final photo = await _photoService.addPhoto(
        currentUser: currentUser,
        localImagePath: imagePath,
        caption: caption,
      );

      if (!_photoService.isUsingFirebase || !currentUser.hasCouple) {
        _photos.add(photo);
        await StorageService.savePhotos(_photos);
        notifyListeners();
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

  Future<void> deletePhoto(
    String photoId, {
    required AppUser currentUser,
  }) async {
    final photo = _photos.firstWhere((p) => p.id == photoId);

    _setLoading(true, message: AppL10n.strings.deletingPhoto);
    _clearError(notify: false);

    try {
      await _photoService.deletePhoto(currentUser: currentUser, photo: photo);

      if (!_photoService.isUsingFirebase || !currentUser.hasCouple) {
        _photos.removeWhere((p) => p.id == photoId);
        await StorageService.savePhotos(_photos);
        notifyListeners();
      }

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
    final index = _photos.indexWhere((p) => p.id == photoId);
    if (index == -1) {
      return;
    }

    _setLoading(true, message: AppL10n.strings.updatingCaption);
    _clearError(notify: false);

    try {
      final updatedPhoto = _photos[index].copyWith(
        caption: newCaption.trim().isEmpty ? null : newCaption.trim(),
        updatedAt: DateTime.now(),
      );

      await _photoService.updateCaption(
        currentUser: currentUser,
        photo: updatedPhoto,
        newCaption: newCaption,
      );

      if (!_photoService.isUsingFirebase || !currentUser.hasCouple) {
        _photos[index] = updatedPhoto;
        await StorageService.savePhotos(_photos);
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
    _photos = [];
    await StorageService.clearPhotos();
    notifyListeners();
  }

  Future<void> clearLocalCache() async {
    await StorageService.clearPhotos();
    notifyListeners();
  }

  int get photoCount => _photos.length;

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

