import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/couple.dart';
import '../models/photo.dart';
import 'dart:convert';

class StorageService {
  static const String _coupleFileName = 'couple_data.json';
  static const String _photosFileName = 'photos_data.json';
  static const String _photosDir = 'couple_photos';

  // Get app documents directory
  static Future<Directory> get _appDir async {
    return await getApplicationDocumentsDirectory();
  }

  // Get photos directory
  static Future<Directory> get _photoDir async {
    final appDir = await _appDir;
    final photoDir = Directory('${appDir.path}/$_photosDir');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  // Save couple data
  static Future<void> saveCouple(Couple couple) async {
    try {
      final appDir = await _appDir;
      final file = File('${appDir.path}/$_coupleFileName');
      await file.writeAsString(jsonEncode(couple.toJson()));
    } catch (e) {
      print('Error saving couple data: $e');
    }
  }

  // Load couple data
  static Future<Couple?> loadCouple() async {
    try {
      final appDir = await _appDir;
      final file = File('${appDir.path}/$_coupleFileName');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents);
        return Couple.fromJson(json);
      }
    } catch (e) {
      print('Error loading couple data: $e');
    }
    return null;
  }

  static Future<void> clearCouple() async {
    try {
      final appDir = await _appDir;
      final file = File('${appDir.path}/$_coupleFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing couple data: $e');
    }
  }

  // Save photos list
  static Future<void> savePhotos(List<Photo> photos) async {
    try {
      final appDir = await _appDir;
      final file = File('${appDir.path}/$_photosFileName');
      final jsonList = photos.map((p) => p.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving photos data: $e');
    }
  }

  // Load photos list
  static Future<List<Photo>> loadPhotos() async {
    try {
      final appDir = await _appDir;
      final file = File('${appDir.path}/$_photosFileName');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final jsonList = jsonDecode(contents) as List;
        return jsonList.map((json) => Photo.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading photos data: $e');
    }
    return [];
  }

  // Save photo file
  static Future<String?> savePhotoFile(String sourcePath) async {
    try {
      final photoDir = await _photoDir;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destFile = File('${photoDir.path}/$fileName');
      await File(sourcePath).copy(destFile.path);
      return destFile.path;
    } catch (e) {
      print('Error saving photo file: $e');
    }
    return null;
  }

  // Delete photo file
  static Future<bool> deletePhotoFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting photo file: $e');
    }
    return false;
  }

  // Check if couple data exists
  static Future<bool> hasCoupleData() async {
    try {
      final appDir = await _appDir;
      final file = File('${appDir.path}/$_coupleFileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}

