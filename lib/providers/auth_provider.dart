import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/auth_status.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isUsingFirebase => _authService.isUsingFirebase;
  String get authSourceLabel => _authService.authSourceLabel;
  String? get bootstrapMessage => _authService.bootstrapMessage;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;

  /// Email-verification gate (feature auth, Đợt 1). True only for post-cutoff
  /// Firebase accounts that haven't verified yet — drives the SessionResolver
  /// redirect to the verify screen and the gate UI. False for local-fallback,
  /// grandfathered, and Google/Apple users.
  bool get requiresEmailVerification => _authService.requiresEmailVerification;

  /// Email of the signed-in Firebase user (for the verify-email gate copy).
  String? get currentEmail => _authService.currentEmail;

  /// Re-register the current user's FCM token. Safe to call repeatedly — used
  /// on every app resume so the token never goes stale while the user stays
  /// logged in (previously it was only synced on login / token refresh, which
  /// let partner devices end up with 0 valid tokens after a token rotation).
  Future<void> refreshPushRegistration() async {
    if (!isAuthenticated) {
      return;
    }
    await PushNotificationService.instance.syncForUser(_currentUser);
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _setLoading(true, notify: false);
    _clearError(notify: false);

    try {
      _currentUser = await _authService.getCurrentUser();
      _status = _currentUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      // Robustness (app-robustness A3): registering the FCM token / device doc
      // is push plumbing, not part of deciding the start route. Awaiting it
      // (permission prompt + getToken + Firestore writes) on cold start is a
      // primary freeze source, so fire-and-forget — it completes off the
      // critical path and is re-run on every app resume anyway.
      unawaited(PushNotificationService.instance.syncForUser(_currentUser));
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Could not initialize session: $e';
    } finally {
      _isInitialized = true;
      _setLoading(false, notify: false);
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError(notify: false);

    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _isInitialized = true;
      await PushNotificationService.instance.syncForUser(_currentUser);
      // Analytics — success path only. Don't block the success return on the
      // analytics user-id write (app-robustness D); fire-and-forget.
      unawaited(AnalyticsService.instance.setUserId(_currentUser?.id));
      AnalyticsService.instance
        ..setIsGuest(false)
        ..logLogin();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Sign in failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError(notify: false);

    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _status = AuthStatus.authenticated;
      _isInitialized = true;
      await PushNotificationService.instance.syncForUser(_currentUser);
      // Analytics — success path only. Don't block the success return on the
      // analytics user-id write (app-robustness D); fire-and-forget.
      unawaited(AnalyticsService.instance.setUserId(_currentUser?.id));
      AnalyticsService.instance
        ..setIsGuest(false)
        ..logSignUp();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Account creation failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs the current user out. Returns `true` when the auth session was
  /// cleared, `false` only when the actual Firebase/local sign-out failed.
  ///
  /// Robustness (app-robustness B): leaving the partner's device list tidy
  /// (unregisterForUser → a Firestore delete) is cleanup, not part of exiting
  /// the session. It is bounded to 5s and, on failure/timeout, swallowed so a
  /// flaky network can never trap the user in a half-logged-out state. The
  /// device doc is also pruned server-side (pruneDeadDevices) as a backstop.
  Future<bool> signOut() async {
    _setLoading(true);
    _clearError(notify: false);

    final previousUser = _currentUser;
    try {
      await PushNotificationService.instance
          .unregisterForUser(previousUser)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort cleanup — never block the sign-out on it.
    }

    try {
      await _authService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _isInitialized = true;
      // Analytics — clear the user id (D2) and mark guest again. Fire-and-forget
      // so the analytics write can't delay returning to the auth gate.
      unawaited(AnalyticsService.instance.setUserId(null));
      AnalyticsService.instance.setIsGuest(true);
      return true;
    } catch (e) {
      _errorMessage = 'Sign out failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> deleteAccount() async {
    final user = _currentUser;
    if (user == null) return null;

    _setLoading(true);
    _clearError(notify: false);

    try {
      // Robustness (app-robustness B/C): unregistering this device is cleanup
      // (the server-side deleteAccount also removes all device docs), so bound
      // it to 5s and never let it block the deletion itself.
      try {
        await PushNotificationService.instance
            .unregisterForUser(user)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best-effort — proceed to the authoritative server-side delete.
      }
      await _authService.deleteAccount(currentUser: user);
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      // Analytics — success path only; log then clear the user id (D2).
      AnalyticsService.instance.logAccountDeleted();
      unawaited(AnalyticsService.instance.setUserId(null));
      return null;
    } on AuthException catch (e) {
      if (e.message == 'requires-recent-login') {
        return 'requires-recent-login';
      }
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      _errorMessage = 'Delete account failed: $e';
      return _errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  /// Sends a password-reset email (feature auth, Đợt 1). Returns true on
  /// success (incl. the D-auth4 anti-enumeration "unknown email → success"
  /// case); on failure sets [errorMessage] and returns false.
  Future<bool> requestPasswordReset(String email) async {
    _clearError(notify: false);
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Password reset failed: $e';
      return false;
    }
  }

  /// Re-sends the verification email to the current user (feature auth, Đợt 1).
  /// Returns true on success; on failure sets [errorMessage] and returns false.
  Future<bool> resendVerificationEmail() async {
    _clearError(notify: false);
    try {
      await _authService.resendEmailVerification();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Resend verification failed: $e';
      return false;
    }
  }

  /// Reloads the Firebase user and reports whether the email is now verified
  /// (feature auth, Đợt 1 — verify-email gate poll + manual check).
  Future<bool> reloadAndCheckEmailVerified() async {
    try {
      return await _authService.reloadAndCheckEmailVerified();
    } catch (_) {
      // Treat a failed reload (offline) as "not verified yet" — the gate stays
      // and the user can retry.
      return false;
    }
  }

  Future<void> updateCurrentUser(AppUser user) async {
    _currentUser = user;
    await _authService.updateCurrentUser(user);
    await PushNotificationService.instance.syncForUser(_currentUser);
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

  void _setLoading(bool value, {bool notify = true}) {
    _isLoading = value;
    if (notify) {
      notifyListeners();
    }
  }
}

