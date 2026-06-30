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
  // True only while leaveCouple() is tearing down. The live couple stream loses
  // read access the instant this user is removed from memberIds, firing a
  // permission-denied; we suppress that self-inflicted stream error so it can't
  // leave a stale "Couldn't sync couple info" banner on the Setup screen.
  bool _isLeaving = false;
  // One-shot latch per couple load: guards re-entry so the live couple stream
  // (which can emit many times) heals the creator's stale status at most once.
  bool _statusHealAttempted = false;

  /// Wired by [SessionResolver]: pushes a self-healed user (status flipped to
  /// 'in_couple' once the partner joins) back into AuthProvider so the
  /// in-memory session matches Firestore. See
  /// [CoupleService.reconcileActiveStatus].
  Future<void> Function(AppUser healed)? onMemberStatusHealed;

  Couple? get couple => _couple;
  bool get hasCoupleData => _couple != null;
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadCoupleForUser(AppUser? currentUser) async {
    await _coupleSubscription?.cancel();
    _coupleSubscription = null;
    _statusHealAttempted = false;

    if (currentUser == null || !currentUser.hasCouple) {
      _couple = null;
      // Wipe any stale couple error (e.g. a permission-denied left by a couple
      // stream that errored during a leave/demote) so the now-single user lands
      // on Setup cleanly instead of seeing a leftover sync-error banner.
      _clearError(notify: false);
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
            // Self-heal: when the partner joins and this couple goes active, the
            // join transaction only updated the JOINER's user doc — the creator
            // (this user, A) is still 'waiting_partner'. Flip A's own status to
            // 'in_couple' so both members are consistent. Fire-and-forget.
            unawaited(_maybeHealActiveStatus(currentUser, couple));
          },
          onError: (error) {
            // Ignore the permission-denied this stream throws while we're
            // leaving the couple ourselves — it's expected, not a real sync
            // failure, and would otherwise surface on Setup after leaving.
            if (_isLeaving) return;
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

  /// Heals the creator's stale `status` to 'in_couple' once the couple is
  /// active (partner joined). One attempt per load — guarded by
  /// [_statusHealAttempted] so the live stream's repeat emissions don't refire
  /// the write. Best-effort: on success the healed user is pushed back into
  /// AuthProvider via [onMemberStatusHealed]; on failure the
  /// `notifyPartnerJoined` CF and the next app launch reconcile it anyway.
  Future<void> _maybeHealActiveStatus(AppUser currentUser, Couple? couple) async {
    if (_statusHealAttempted || couple == null) return;
    if (currentUser.status == 'in_couple') return;
    final isActive = couple.status == 'active' || couple.memberCount >= 2;
    if (!isActive) return;
    _statusHealAttempted = true;
    try {
      final healed = await _coupleService.reconcileActiveStatus(
        currentUser: currentUser,
        couple: couple,
      );
      if (healed != null) {
        await onMemberStatusHealed?.call(healed);
      }
    } catch (_) {
      // Best-effort — the couple already shows active in the UI; A's status is
      // also reconciled server-side by notifyPartnerJoined and on next launch.
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
    // Suppress the stream's self-inflicted permission-denied during teardown
    // (see [_isLeaving]). We deliberately tear the subscription down only AFTER
    // a successful leave so a failure (e.g. network) keeps the couple + live
    // stream intact and the Settings UI doesn't go blank.
    _isLeaving = true;

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
      _isLeaving = false;
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

