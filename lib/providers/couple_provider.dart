import 'package:flutter/material.dart';
import '../models/couple.dart';
import '../services/storage_service.dart';

class CoupleProvider extends ChangeNotifier {
  Couple? _couple;

  Couple? get couple => _couple;
  bool get hasCoupleData => _couple != null;

  // Load couple data from storage
  Future<void> loadCouple() async {
    _couple = await StorageService.loadCouple();
    notifyListeners();
  }

  // Save couple data
  Future<void> saveCouple(String person1, String person2, DateTime anniversary, {String? photoPath}) async {
    _couple = Couple(
      person1Name: person1,
      person2Name: person2,
      anniversaryDate: anniversary,
      couplePhotoPath: photoPath,
    );
    await StorageService.saveCouple(_couple!);
    notifyListeners();
  }

  // Update couple photo
  Future<void> updateCouplePhoto(String photoPath) async {
    if (_couple != null) {
      _couple = _couple!.copyWith(couplePhotoPath: photoPath);
      await StorageService.saveCouple(_couple!);
      notifyListeners();
    }
  }

  // Reset couple data
  Future<void> resetCouple() async {
    _couple = null;
    notifyListeners();
  }
}

