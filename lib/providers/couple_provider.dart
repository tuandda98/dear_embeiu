import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import '../models/couple.dart';
import '../services/analytics_service.dart';
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

    _setLoading(true, message: AppL10n.strings.loadingCoupleInfo);
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
            _errorMessage = AppL10n.strings.coupleSyncError('$error');
            notifyListeners();
          },
        );
      }
    } catch (e) {
      _couple = null;
      final msg = '$e'.toLowerCase();
      if (msg.contains('permission-denied') || msg.contains('permission_denied')) {
        // Stale coupleId — user is no longer a member of that couple (partner
        // left, couple was deleted, or cross-device Hive/session mismatch).
        // Auto-heal: clear the stale ref so the user lands on Setup cleanly
        // instead of seeing a cryptic error every time the app starts.
        try {
          await _coupleService.clearStaleCoupleRef(currentUser);
        } catch (_) {
          // Best-effort — even if Firestore write fails, _couple=null is
          // enough for the session resolver to route to Setup.
        }
        // No error banner — the user just sees Setup, which is correct.
      } else {
        _errorMessage = AppL10n.strings.coupleLoadError('$e');
      }
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
    _setLoading(true, message: AppL10n.strings.savingCoupleSpace);
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
      // Analytics — A created a couple (now waiting for a partner).
      AnalyticsService.instance
        ..logCoupleCreated()
        ..setCoupleStatus('waiting_partner');
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
    _setLoading(true, message: AppL10n.strings.connectingCouple);
    _clearError(notify: false);

    try {
      final result = await _coupleService.joinCoupleByCode(
        currentUser: currentUser,
        inviteCode: inviteCode,
      );
      _couple = result.couple;
      notifyListeners();
      // Analytics — B joined successfully (⭐ activation). Log the attempt
      // result + the join event + new couple status.
      AnalyticsService.instance
        ..logCoupleJoinAttempt(AnalyticsJoinResult.success)
        ..logCoupleJoined()
        ..setCoupleStatus('in_couple');
      return result;
    } on CoupleException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      // Analytics — failed attempt, bucketed by stable code (never PII).
      AnalyticsService.instance.logCoupleJoinAttempt(_joinResultFor(e.code));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Maps a [CoupleErrorCode] from a failed join to the analytics `result`
  /// bucket (contract: success | invalid_code | already_in_couple | error).
  String _joinResultFor(CoupleErrorCode? code) {
    switch (code) {
      case CoupleErrorCode.inviteNotFound:
        return AnalyticsJoinResult.invalidCode;
      case CoupleErrorCode.alreadyHasCouple:
      case CoupleErrorCode.alreadyInThis:
        return AnalyticsJoinResult.alreadyInCouple;
      default:
        return AnalyticsJoinResult.error;
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
      throw CoupleException(AppL10n.strings.coupleNoDataToUpdate);
    }

    _setLoading(true, message: AppL10n.strings.updatingCoupleInfo);
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
    _setLoading(true, message: AppL10n.strings.leavingCouple);
    _clearError(notify: false);

    try {
      final updatedUser = await _coupleService.leaveCouple(currentUser: currentUser);
      await _coupleSubscription?.cancel();
      _coupleSubscription = null;
      _couple = null;
      notifyListeners();
      // Analytics — back to single after leaving the couple.
      AnalyticsService.instance.setCoupleStatus('single');
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

