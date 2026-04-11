import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/photo.dart';
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
  String? _errorMessage;

  List<Photo> get photos => _photos;
  List<Photo> get sortedPhotos => [..._photos]..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
  bool get isLoading => _isLoading;
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

    _setLoading(true);
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
    _setLoading(true);
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

    _setLoading(true);
    _clearError(notify: false);

    try {
      await _photoService.deletePhoto(currentUser: currentUser, photo: photo);

      if (!_photoService.isUsingFirebase || !currentUser.hasCouple) {
        _photos.removeWhere((p) => p.id == photoId);
        await StorageService.savePhotos(_photos);
        notifyListeners();
      }
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

    _setLoading(true);
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

  Future<void> clearForSignOut() async {
    await _photoSubscription?.cancel();
    _photoSubscription = null;
    _currentUser = null;
    _photos = [];
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

  void _setLoading(bool value, {bool notify = true}) {
    _isLoading = value;
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

