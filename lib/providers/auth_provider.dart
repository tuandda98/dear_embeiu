import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import '../models/auth_status.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/user_service.dart';
import 'money_provider.dart';

/// Social sign-in providers (pairing-funnel PF1 Apple, PF14 Google). `name` is
/// also the analytics `method`.
enum SocialSignIn { apple, google }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService, UserService? userService})
    : _authService = authService,
      _userService = userService ?? UserService();

  final AuthService _authService;
  final UserService _userService;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  /// The social sign-in in flight has its own state (pairing-funnel design §1):
  /// driving [isLoading] would spin the email button on the same screen too.
  SocialSignIn? _socialSignIn;
  EmailHasPasswordAccountException? _emailConflict;

  /// A [deleteAccount] is running (BUG-26).
  bool _deleting = false;

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

  /// Which social sign-in is running: only its button spins, the other
  /// buttons and links on the screen lock.
  SocialSignIn? get socialSignIn => _socialSignIn;
  bool get isSocialSigningIn => _socialSignIn != null;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// PF6 — set when the last Apple/Google sign-in hit an email that already
  /// has a password account; carries the email so Sign in can prefill it.
  EmailHasPasswordAccountException? get emailConflict => _emailConflict;

  /// This account confirms through the Apple sheet (PF5, AU3) — for a
  /// deletion, ask [deletesWithAppleSheet].
  bool get reauthWithApple => _authService.reauthWithApple;

  /// Deleting this account confirms through the Apple sheet — with a
  /// password too only when this iPhone's Apple ID is the account's, which
  /// iOS is asked here (BUG-25). Ask once, right before the delete dialog,
  /// and hand the answer to [deleteAccount] (BUG-26).
  Future<bool> deletesWithAppleSheet() async =>
      reauthWithApple && !await _authService.passwordInsteadOfAppleSheet();

  /// Deleting this account confirms with Google, no password (PF16).
  bool get reauthWithGoogle => _authService.reauthWithGoogle;

  /// AU1: an Apple/Google account without a password can add one in Settings.
  bool get canSetPassword => _authService.canSetPassword;
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
    _tokenSub = _authService
        .watchSessionToken(uid)
        .listen(
          (remoteToken) {
            if (_localToken == null || remoteToken == null) return;
            if (remoteToken == _localToken) return;
            if (_intentionalAuthClear) return;
            if (_status != AuthStatus.authenticated) return;
            // Another device took over — clear state and re-route to auth gate.
            _intentionalAuthClear =
                true; // Prevent _sessionSub from double-firing.
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
          },
          onError: (Object e) {
            // The listener outlives a session that ended under it (another Apple ID
            // in the delete sheet, external revocation): rules then deny the read.
            // Not a crash — keep it out of Crashlytics' fatal handler.
            debugPrint('AuthProvider session token watch ended: $e');
          },
        );
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

  /// App back in the foreground → refresh users/{uid}.lastSeenAt (feature
  /// last-seen). Fire-and-forget; UserService throttles to 1 write/hour.
  void touchLastSeen() {
    if (!isAuthenticated) return;
    unawaited(_userService.touchLastSeen(_currentUser!.id));
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
      debugPrint('AuthProvider.initialize failed: $e');
      _errorMessage = AppL10n.strings.authSessionNotReady;
    } finally {
      _isInitialized = true;
      // Start watching session liveness once the initial state is settled (#3).
      _startSessionListener();
      _setLoading(false, notify: false);
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError(notify: false);
    // A fresh session is beginning — re-arm external-revocation detection.
    _intentionalAuthClear = false;

    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
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
        ..logLogin();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      AnalyticsService.instance.logLoginFailed(reason: _failReason(e));
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      debugPrint('AuthProvider.signIn failed: $e');
      AnalyticsService.instance.logLoginFailed(reason: 'unknown');
      _errorMessage = AppL10n.strings.authSessionUnavailable;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Apple (PF1) or Google (PF14), same success path as
  /// [signIn]. Returns false on failure; [errorMessage] stays null when the
  /// user just closed the sheet or picker, so the UI can stay silent.
  Future<bool> signInWithSocial(SocialSignIn provider) async {
    // AU5: Apple and Google tapped in the same frame both get here before the
    // buttons lock — only the first runs, the second stays silent.
    if (_socialSignIn != null) {
      return false;
    }
    _socialSignIn = provider;
    _emailConflict = null;
    _clearError();
    // A fresh session is beginning — re-arm external-revocation detection.
    _intentionalAuthClear = false;

    try {
      final result = provider == SocialSignIn.apple
          ? await _authService.signInWithApple()
          : await _authService.signInWithGoogle();
      _currentUser = result.user;
      _status = AuthStatus.authenticated;
      _isInitialized = true;
      await PushNotificationService.instance.syncForUser(_currentUser);
      // Single-session: mint a new token — kicks any other active session.
      if (_currentUser != null) {
        await _mintAndWatchSessionToken(_currentUser!.id);
      }
      unawaited(AnalyticsService.instance.setUserId(_currentUser?.id));
      AnalyticsService.instance.setIsGuest(false);
      if (result.isNewUser) {
        AnalyticsService.instance.logSignUp(method: provider.name);
      } else {
        AnalyticsService.instance.logLogin(method: provider.name);
      }
      return true;
    } on EmailHasPasswordAccountException catch (e) {
      _status = AuthStatus.unauthenticated;
      _emailConflict = e;
      _errorMessage = e.message;
      AnalyticsService.instance.logLoginFailed(
        method: provider.name,
        reason: 'email-has-password-account',
      );
      return false;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message == 'social-canceled' ? null : e.message;
      AnalyticsService.instance.logLoginFailed(
        method: provider.name,
        reason: _failReason(e),
      );
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      debugPrint('AuthProvider.signInWithSocial(${provider.name}) failed: $e');
      AnalyticsService.instance.logLoginFailed(
        method: provider.name,
        reason: 'unknown',
      );
      _errorMessage = provider == SocialSignIn.apple
          ? AppL10n.strings.appleSignInFailed
          : AppL10n.strings.googleSignInFailed;
      return false;
    } finally {
      _socialSignIn = null;
      notifyListeners();
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
      AnalyticsService.instance.logSignUpFailed(reason: _failReason(e));
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      debugPrint('AuthProvider.signUp failed: $e');
      AnalyticsService.instance.logSignUpFailed(reason: 'unknown');
      _errorMessage = AppL10n.strings.authFirebaseUserCreateFailed;
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
    // Sổ tiền: deletes still in their 5 s undo window go out while the
    // account can still write (bounded, best effort).
    await MoneyProvider.flushPendingDeletes();

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
      AnalyticsService.instance.logSignOut();
      unawaited(AnalyticsService.instance.setUserId(null));
      AnalyticsService.instance.setIsGuest(true);
      return true;
    } catch (e) {
      // Sign-out failed — the session is still alive, so re-arm detection.
      _intentionalAuthClear = false;
      debugPrint('AuthProvider.signOut failed: $e');
      _errorMessage = AppL10n.strings.signOutFailedMsg;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// [appleSheet]: the delete dialog's [deletesWithAppleSheet] answer — the
  /// Apple sheet confirms first, else nothing more does (a password, Google,
  /// a re-auth already done). iOS isn't asked again: the deletion does what
  /// the dialog said (BUG-26). While one runs, another call returns
  /// `'delete-in-progress'` at once and leaves it alone.
  Future<String?> deleteAccount({required bool appleSheet}) async {
    final user = _currentUser;
    if (user == null) return null;
    if (_deleting) return 'delete-in-progress';
    _deleting = true;

    _setLoading(true);
    _clearError(notify: false);

    try {
      // PF5: Apple accounts confirm in the Apple sheet FIRST. Closing it must
      // leave everything as it was (push registration, single-session watch),
      // so nothing below may run before this.
      await _authService.confirmAppleDeletionIfNeeded(appleSheet: appleSheet);
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
      // The dialog promised every piece of data goes (AU8): sleep nights live
      // only on this phone. Best-effort — the account is gone either way.
      try {
        await _authService
            .wipeLocalUserData(user.id)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('AuthProvider local data wipe failed: $e');
      }
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
      // Sentinels the UI branches on, never shown as text. `social-canceled` =
      // the user closed the Apple confirmation sheet (PF5) — nothing deleted.
      // `apple-id-mismatch` = the sheet signed in another Apple ID (PF18);
      // `session-gone` = no session left. Both: signed out.
      _forgetSignedOutUser(e.message);
      if (e.message == 'requires-recent-login' ||
          e.message == 'social-canceled' ||
          e.message == 'apple-id-mismatch' ||
          e.message == 'session-gone') {
        return e.message;
      }
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      _intentionalAuthClear = false;
      debugPrint('AuthProvider.deleteAccount failed: $e');
      _errorMessage = AppL10n.strings.deleteAccountFailed;
      return _errorMessage;
    } finally {
      _deleting = false;
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
      debugPrint('AuthProvider.reauthenticate failed: $e');
      return AppL10n.strings.authFirebaseAuthGeneric;
    }
    _setLoading(false);
    // Token is fresh now — retry the authoritative server-side delete. The
    // password confirmed it: no Apple sheet.
    return deleteAccount(appleSheet: false);
  }

  /// Adds a password to the signed-in Apple/Google account (AU1). Null on
  /// success — the Settings row then goes away. Otherwise a sentinel the UI
  /// branches on (`social-canceled`; `apple-id-mismatch` / `session-gone`:
  /// already signed out) or the copy to show.
  Future<String?> setPassword(String password) async {
    try {
      // BUG-24: onto the account on screen, never onto a session the Apple
      // sheet left behind.
      final uid = _currentUser?.id;
      if (uid == null) {
        return 'session-gone';
      }
      await _authService.setPassword(password, uid: uid);
      AnalyticsService.instance.logPasswordSet();
      return null;
    } on AuthException catch (e) {
      _forgetSignedOutUser(e.message);
      return e.message;
    } catch (e) {
      debugPrint('AuthProvider.setPassword failed: $e');
      return AppL10n.strings.setPasswordFailed;
    } finally {
      // [canSetPassword] reads the Firebase user, which may have changed.
      notifyListeners();
    }
  }

  /// `apple-id-mismatch` / `session-gone` mean this account's session is
  /// over — even when signing the other Apple ID out failed and no
  /// sign-out event comes (BUG-24). authGate must not route back into it.
  /// Analytics reason for a failed auth call: the error code, `canceled` for
  /// a dismissed Apple/Google sheet, else `other`. Never the message text.
  static String _failReason(AuthException e) {
    if (e.message == 'social-canceled') {
      return 'canceled';
    }
    return e.code ?? 'other';
  }

  void _forgetSignedOutUser(String code) {
    if (code == 'apple-id-mismatch' || code == 'session-gone') {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }
  }

  /// Sends a password-reset email (feature auth, Đợt 1). Returns true on
  /// success (incl. the D-auth4 anti-enumeration "unknown email → success"
  /// case); on failure sets [errorMessage] and returns false.
  Future<bool> requestPasswordReset(String email) async {
    _clearError(notify: false);
    try {
      await _authService.sendPasswordResetEmail(email);
      AnalyticsService.instance.logPasswordResetRequested();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      AnalyticsService.instance.logPasswordResetFailed(_failReason(e));
      return false;
    } catch (e) {
      debugPrint('AuthProvider.requestPasswordReset failed: $e');
      AnalyticsService.instance.logPasswordResetFailed('unknown');
      _errorMessage = AppL10n.strings.forgotPasswordNetworkError;
      return false;
    }
  }

  /// Re-sends the verification email to the current user (feature auth, Đợt 1).
  /// Returns true on success; on failure sets [errorMessage] and returns false.
  Future<bool> resendVerificationEmail() async {
    _clearError(notify: false);
    try {
      await _authService.resendEmailVerification();
      AnalyticsService.instance.logVerificationEmailResent();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('AuthProvider.resendVerificationEmail failed: $e');
      _errorMessage = AppL10n.strings.verifyEmailResendError;
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
