import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/couple.dart';
import '../services/couple_service.dart';

class CoupleProvider extends ChangeNotifier {
  CoupleProvider({CoupleService? coupleService})
      : _coupleService = coupleService ?? CoupleService();

  final CoupleService _coupleService;
  Couple? _couple;
  bool _isLoading = false;
  String? _errorMessage;

  Couple? get couple => _couple;
  bool get hasCoupleData => _couple != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCoupleForUser(AppUser? currentUser) async {
    if (currentUser == null || !currentUser.hasCouple) {
      _couple = null;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      _couple = await _coupleService.fetchCouple(currentUser.coupleId!);
    } catch (e) {
      _errorMessage = 'Không thể tải thông tin cặp đôi: $e';
      _couple = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<CoupleActionResult> createCouple({
    required AppUser currentUser,
    required String person1,
    required String person2,
    required DateTime anniversary,
    String? photoPath,
  }) async {
    _setLoading(true);
    _clearError(notify: false);

    try {
      final result = await _coupleService.createCouple(
        currentUser: currentUser,
        person1Name: person1,
        person2Name: person2,
        anniversaryDate: anniversary,
        photoPath: photoPath,
      );
      _couple = result.couple;
      notifyListeners();
      return result;
    } on CoupleException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<CoupleActionResult> joinCoupleByCode({
    required AppUser currentUser,
    required String inviteCode,
  }) async {
    _setLoading(true);
    _clearError(notify: false);

    try {
      final result = await _coupleService.joinCoupleByCode(
        currentUser: currentUser,
        inviteCode: inviteCode,
      );
      _couple = result.couple;
      notifyListeners();
      return result;
    } on CoupleException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<CoupleActionResult> updateCouple({
    required AppUser currentUser,
    required String person1,
    required String person2,
    required DateTime anniversary,
    String? photoPath,
  }) async {
    final existingCouple = _couple;
    if (existingCouple == null) {
      throw const CoupleException('Chưa có dữ liệu cặp đôi để cập nhật.');
    }

    _setLoading(true);
    _clearError(notify: false);

    try {
      final result = await _coupleService.updateCouple(
        currentUser: currentUser,
        existingCouple: existingCouple,
        person1Name: person1,
        person2Name: person2,
        anniversaryDate: anniversary,
        photoPath: photoPath,
      );
      _couple = result.couple;
      notifyListeners();
      return result;
    } on CoupleException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<AppUser> resetCouple({required AppUser currentUser}) async {
    _setLoading(true);
    _clearError(notify: false);

    try {
      final updatedUser = await _coupleService.resetCouple(currentUser: currentUser);
      _couple = null;
      notifyListeners();
      return updatedUser;
    } on CoupleException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
  }

  void _clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

