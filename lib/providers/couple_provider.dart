import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/couple.dart';
import '../services/couple_service.dart';
import '../services/storage_service.dart';

class CoupleProvider extends ChangeNotifier {
  CoupleProvider({CoupleService? coupleService})
      : _coupleService = coupleService ?? CoupleService();

  final CoupleService _coupleService;
  Couple? _couple;
  StreamSubscription<Couple?>? _coupleSubscription;
  bool _isLoading = false;
  String? _loadingMessage;
  String? _errorMessage;

  Couple? get couple => _couple;
  bool get hasCoupleData => _couple != null;
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadCoupleForUser(AppUser? currentUser) async {
    await _coupleSubscription?.cancel();
    _coupleSubscription = null;

    if (currentUser == null || !currentUser.hasCouple) {
      _couple = null;
      notifyListeners();
      return;
    }

    _setLoading(true, message: 'Đang tải thông tin cặp đôi...');
    _clearError(notify: false);

    try {
      _couple = await _coupleService.fetchCouple(currentUser.coupleId!);

      if (_coupleService.isUsingFirebase) {
        _coupleSubscription = _coupleService.watchCouple(currentUser.coupleId!).listen(
          (couple) {
            _couple = couple;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Không thể đồng bộ thông tin cặp đôi: $error';
            notifyListeners();
          },
        );
      }
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
    _setLoading(true, message: 'Đang lưu không gian cặp đôi...');
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
    _setLoading(true, message: 'Đang kết nối cặp đôi...');
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
      throw const CoupleException('No couple data to update.');
    }

    _setLoading(true, message: 'Đang cập nhật thông tin cặp đôi...');
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

  Future<AppUser> leaveCouple({required AppUser currentUser}) async {
    _setLoading(true, message: 'Đang rời cặp đôi...');
    _clearError(notify: false);

    try {
      final updatedUser = await _coupleService.leaveCouple(currentUser: currentUser);
      await _coupleSubscription?.cancel();
      _coupleSubscription = null;
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

  Future<void> clearLocalCache() async {
    await StorageService.clearCouple();
    notifyListeners();
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

  void _setLoading(bool value, {String? message}) {
    _isLoading = value;
    _loadingMessage = value ? (message ?? _loadingMessage) : null;
    notifyListeners();
  }

  @override
  void dispose() {
    _coupleSubscription?.cancel();
    super.dispose();
  }
}

