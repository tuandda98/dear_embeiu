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

  /// Session-liveness listener (feature auth — #3). Subscribes once to the
  /// service's session-presence stream; drives [sessionRevoked].
  StreamSubscription<bool>? _sessionSub;

  /// Single-session enforcement: watches `users/{uid}.sessionToken` in
  /// Firestore so we detect when another device mints a new token (new login).
  StreamSubscription<String?>? _tokenSub;

  /// The session token we minted on this device's last sign-in / cold-start.
  /// If the Firestore copy drifts from this, the session is displaced.
  String? _localToken;

  /// True while WE are intentionally ending the session (sign-out / successful
  /// delete) so the resulting `false` emit on [sessionActiveChanges] is NOT
  /// mistaken for an external revocation. Stays `true` until the next sign-in
  /// resets it — this deliberately swallows the trailing emit that arrives
  /// asynchronously after sign-out completes (avoids a double-navigation race).
  bool _intentionalAuthClear = false;

  /// Set when the session ended WITHOUT the user asking (token revoked, account
  /// deleted elsewhere, password changed). The app shell watches this and
  /// re-routes through the auth gate. One-shot: read then
  /// [acknowledgeSessionRevoked].
  bool _sessionRevoked = false;

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

  /// True when the session died on its own (external revocation) — see
  /// [_sessionRevoked]. The app shell consumes this to bounce the user back to
  /// the auth gate, then calls [acknowledgeSessionRevoked].
  bool get sessionRevoked => _sessionRevoked;

  /// Clears the one-shot [sessionRevoked] flag after the shell has navigated.
  void acknowledgeSessionRevoked() => _sessionRevoked = false;

  /// Subscribes once to the session-presence stream (#3). A `false` emit means
  /// the session ended; we treat it as an EXTERNAL revocation only when we
  /// weren't authenticated-by-our-own-doing about to end it. Intentional
  /// sign-out / delete set [_intentionalAuthClear] so their trailing emit is
  /// ignored. Emits while unauthenticated (e.g. the synchronous initial `false`
  /// on a guest cold start) are ignored too via the status guard.
  void _startSessionListener() {
    if (_sessionSub != null || !isUsingFirebase) {
      return;
    }
    _sessionSub = _authService.sessionActiveChanges().listen((active) {
      if (active) {
        return;
      }
      if (_intentionalAuthClear) {
        return;
      }
      if (_status != AuthStatus.authenticated) {
        return;
      }
      // Session was pulled out from under us — clear local state and flag the
      // shell to re-route. Analytics: drop the user id like a sign-out.
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _sessionRevoked = true;
      unawaited(AnalyticsService.instance.setUserId(null));
      AnalyticsService.instance.setIsGuest(true);
      notifyListeners();
    });
  }

  /// Mints a fresh session token (writes to Firestore + local storage) then
  /// starts watching for displacement by another device. Fire-and-forget safe.
  Future<void> _mintAndWatchSessionToken(String uid) async {
    _tokenSub?.cancel();
    _tokenSub = null;
    _localToken = null;
    if (!_authService.isUsingFirebase) return;
    try {
      _localToken = await _authService.mintSessionToken(uid);
    } catch (_) {
      return; // Best-effort — never block the sign-in path.
    }
    _tokenSub = _authService.watchSessionToken(uid).listen((remoteToken) {
      if (_localToken == null || remoteToken == null) return;
      if (remoteToken == _localToken) return;
      if (_intentionalAuthClear) return;
      if (_status != AuthStatus.authenticated) return;
      // Another device took over — clear state and re-route to auth gate.
      _intentionalAuthClear = true; // Prevent _sessionSub from double-firing.
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _sessionRevoked = true;
      unawaited(AnalyticsService.instance.setUserId(null));
      AnalyticsService.instance.setIsGuest(true);
      _tokenSub?.cancel();
      _tokenSub = null;
      _localToken = null;
      unawaited(_authService.signOut());
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _tokenSub?.cancel();
    super.dispose();
  }

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
      // Single-session: cold-start counts as "taking over" the session.
      // Fire-and-forget so Firestore latency never blocks route resolution.
      if (_currentUser != null) {
        unawaited(_mintAndWatchSessionToken(_currentUser!.id));
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Could not initialize session: $e';
    } finally {
      _isInitialized = true;
      // Start watching session liveness once the initial state is settled (#3).
      _startSessionListener();
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
    // A fresh session is beginning — re-arm external-revocation detection.
    _intentionalAuthClear = false;

    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _isInitialized = true;
      await PushNotificationService.instance.syncForUser(_currentUser);
      // Single-session: mint a new token — kicks any other active session.
      if (_currentUser != null) {
        await _mintAndWatchSessionToken(_currentUser!.id);
      }
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
    // A fresh session is beginning — re-arm external-revocation detection.
    _intentionalAuthClear = false;

    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _status = AuthStatus.authenticated;
      _isInitialized = true;
      await PushNotificationService.instance.syncForUser(_currentUser);
      // Single-session: mint a new token — kicks any other active session.
      if (_currentUser != null) {
        await _mintAndWatchSessionToken(_currentUser!.id);
      }
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

    // We're intentionally ending the session — swallow the resulting `false`
    // emit on the liveness stream so it isn't read as an external revocation
    // (#3). Stays armed until the next sign-in.
    _intentionalAuthClear = true;
    _tokenSub?.cancel();
    _tokenSub = null;
    _localToken = null;
    unawaited(_authService.clearLocalSessionToken());
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
      // Sign-out failed — the session is still alive, so re-arm detection.
      _intentionalAuthClear = false;
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
      // A successful delete ends the session server-side; swallow the liveness
      // stream's trailing `false` emit so it isn't read as a revocation (#3).
      _intentionalAuthClear = true;
      _tokenSub?.cancel();
      _tokenSub = null;
      _localToken = null;
      await _authService.deleteAccount(currentUser: user);
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      // Analytics — success path only; log then clear the user id (D2).
      AnalyticsService.instance.logAccountDeleted();
      unawaited(AnalyticsService.instance.setUserId(null));
      return null;
    } on AuthException catch (e) {
      // Deletion did NOT happen — the session is still alive, so re-arm
      // external-revocation detection (#3).
      _intentionalAuthClear = false;
      if (e.message == 'requires-recent-login') {
        return 'requires-recent-login';
      }
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      _intentionalAuthClear = false;
      _errorMessage = 'Delete account failed: $e';
      return _errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  /// Re-auth recovery for the delete-account dead-end (#2). When [deleteAccount]
  /// returns `'requires-recent-login'` (the callable saw a stale/expired token),
  /// the UI collects the password and calls this: it re-authenticates to mint a
  /// fresh token, then retries the deletion. Returns `null` on success, or an
  /// error string — notably `'session-gone'` when there's no local session left
  /// to re-auth (the UI must then send the user through a full re-login).
  Future<String?> reauthenticateAndDeleteAccount(String password) async {
    _setLoading(true);
    _clearError(notify: false);
    try {
      await _authService.reauthenticateWithPassword(password);
    } on AuthException catch (e) {
      _setLoading(false);
      return e.message;
    } catch (e) {
      _setLoading(false);
      return 'Reauth failed: $e';
    }
    _setLoading(false);
    // Token is fresh now — retry the authoritative server-side delete.
    return deleteAccount();
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

