import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class PhotoProvider extends ChangeNotifier {
  List<Photo> _photos = [];

  List<Photo> get photos => _photos;
  List<Photo> get sortedPhotos => [..._photos]..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

  // Load photos from storage
  Future<void> loadPhotos() async {
    _photos = await StorageService.loadPhotos();
    notifyListeners();
  }

  // Add new photo
  Future<void> addPhoto(String imagePath, {String? caption}) async {
    final savedPath = await StorageService.savePhotoFile(imagePath);
    if (savedPath != null) {
      const uuid = Uuid();
      final photo = Photo(
        id: uuid.v4(),
        path: savedPath,
        uploadDate: DateTime.now(),
        caption: caption,
      );
      _photos.add(photo);
      await StorageService.savePhotos(_photos);
      notifyListeners();
    }
  }

  // Delete photo
  Future<void> deletePhoto(String photoId) async {
    final photo = _photos.firstWhere((p) => p.id == photoId);
    await StorageService.deletePhotoFile(photo.path);
    _photos.removeWhere((p) => p.id == photoId);
    await StorageService.savePhotos(_photos);
    notifyListeners();
  }

  // Update photo caption
  Future<void> updatePhotoCaption(String photoId, String newCaption) async {
    final index = _photos.indexWhere((p) => p.id == photoId);
    if (index != -1) {
      _photos[index] = _photos[index].copyWith(caption: newCaption);
      await StorageService.savePhotos(_photos);
      notifyListeners();
    }
  }

  // Get photo count
  int get photoCount => _photos.length;
}

