import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignIn, GoogleSignInException, GoogleSignInExceptionCode;
import 'package:uuid/uuid.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import '../models/couple.dart';
import 'firebase_bootstrap_service.dart';
import 'sleep_service.dart';
import 'storage_service.dart';
import 'user_service.dart';

class AuthException implements Exception {
  final String message;

  /// Stable error code (Firebase code like `wrong-password`) for analytics —
  /// never shown to the user, never PII. Null when there's no code.
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Apple or Google sign-in hit an email that already belongs to a password
/// account (pairing-funnel PF6/PF16 — no account linking). [email] lets the
/// Sign in form prefill it; null when Firebase didn't say which email.
class EmailHasPasswordAccountException extends AuthException {
  const EmailHasPasswordAccountException(super.message, {this.email});

  final String? email;
}

/// Cutoff for mandatory email verification (feature auth, Đợt 1 — D-auth2).
///
/// Only accounts created on/after this instant are hard-gated behind email
/// verification. Pre-cutoff accounts (existing v1.0 users) and providers that
/// are verified on creation (Google/Apple, Đợt 2) are grandfathered in so the
/// gate can never lock out users who already exist.
final DateTime kEmailVerificationCutoff = DateTime.utc(2026, 6, 5);

/// Sprint 1 local scaffold.
///
/// Ở Sprint 2, file này có thể được thay bằng Firebase Auth + Firestore
/// nhưng API public nên giữ gần giống để giảm công refactor.
class AuthService {
  AuthService({
    FlutterSecureStorage? secureStorage,
    FirebaseAuth? firebaseAuth,
    UserService? userService,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _firebaseAuth = firebaseAuth,
        _userService = userService ?? UserService();

  static const String _usersStorageKey = 'mock_auth_users';
  static const String _sessionStorageKey = 'mock_auth_session_user_id';

  static final Map<String, String> _memoryFallbackStore = <String, String>{};

  final FlutterSecureStorage _secureStorage;
  final FirebaseAuth? _firebaseAuth;
  final UserService _userService;
  final Uuid _uuid = const Uuid();
  final Random _random = Random.secure();

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  String get authSourceLabel => isUsingFirebase ? 'Firebase' : 'Local fallback';

  String? get bootstrapMessage => FirebaseBootstrapService.bootstrapMessage;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  // Default region (us-central1) matches the deployed `deleteAccount` callable.
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  Future<AppUser?> getCurrentUser() async {
    if (isUsingFirebase) {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      await _ensureFirebaseSessionReady(firebaseUser);

      // Robustness (app-robustness A5): bound the profile fetch so a slow/offline
      // Firestore can't freeze the cold-start route resolution. On timeout we
      // reconstruct a usable profile from the (already authenticated) Firebase
      // user plus the locally cached couple, so the user still lands on the
      // right screen (home if a cached couple includes this uid, else setup).
      AppUser? existingProfile;
      try {
        existingProfile = await _userService
            .fetchUserProfile(firebaseUser.uid)
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        return await _buildOfflineFallbackProfile(firebaseUser);
      }

      if (existingProfile != null) {
        final refreshedProfile = await _ensureInviteCode(existingProfile.copyWith(
          lastSeenAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        // Robustness (app-robustness A4): the lastSeenAt/updatedAt refresh is
        // pure housekeeping — it must not block the route. Fire-and-forget so
        // these two Firestore writes happen off the cold-start critical path.
        unawaited(_userService.updateUserProfile(refreshedProfile));
        return refreshedProfile;
      }

      final createdProfile = await _ensureInviteCode(_buildFirebaseProfile(firebaseUser));
      await _userService.saveUserProfile(createdProfile);
      return createdProfile;
    }

    final sessionUserId = await _read(_sessionStorageKey);
    if (sessionUserId == null || sessionUserId.isEmpty) {
      return null;
    }

    final users = await _loadUserRecords();
    final record = users.where((user) => user['id'] == sessionUserId).firstOrNull;

    if (record == null) {
      await _delete(_sessionStorageKey);
      return null;
    }

    final recordUser = AppUser.fromJson(record);
    final userWithInvite = await _ensureInviteCode(recordUser);
    if (userWithInvite.inviteCode != recordUser.inviteCode) {
      final index = users.indexWhere((user) => user['id'] == sessionUserId);
      if (index != -1) {
        users[index] = {
          ...userWithInvite.toJson(),
          'password': users[index]['password'],
        };
        await _saveUserRecords(users);
      }
    }

    return userWithInvite;
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (isUsingFirebase) {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw AuthException(AppL10n.strings.authFirebaseUserCreateFailed);
        }

        await firebaseUser.updateDisplayName(displayName.trim());
        await _ensureFirebaseSessionReady(firebaseUser);

        final now = DateTime.now();
        final user = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email.trim().toLowerCase(),
          displayName: displayName.trim(),
          inviteCode: await _generateUniqueInviteCode(),
          status: 'single',
          createdAt: now,
          updatedAt: now,
          lastSeenAt: now,
        );

        try {
          await _userService.saveUserProfile(user);
        } on FirebaseException catch (e) {
          await firebaseUser.delete();
          throw AuthException(_mapFirestoreError(e));
        }

        // Mandatory email verification (feature auth, Đợt 1). Send the link as
        // part of sign-up so the new user lands on the verify screen with a mail
        // already in their inbox. Custom branded email (Cách B) goes out via the
        // `sendCustomVerificationEmail` callable (Resend) instead of Firebase's
        // default template. Wrapped: a failed send must NOT break sign-up (the
        // account exists, the user can still "Resend" from the gate).
        try {
          await _sendCustomVerificationEmail();
        } catch (_) {
          // Best-effort — verify screen exposes a manual "Resend" button.
        }

        return user;
      } on FirebaseAuthException catch (e) {
        throw AuthException(_mapFirebaseAuthError(e), code: e.code);
      } on FirebaseException catch (e) {
        throw AuthException(_mapFirestoreError(e), code: e.code);
      }
    }

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedDisplayName = displayName.trim();
    final normalizedPassword = password.trim();

    final users = await _loadUserRecords();
    final emailAlreadyUsed = users.any(
      (user) => (user['email'] as String).toLowerCase() == normalizedEmail,
    );

    if (emailAlreadyUsed) {
      throw AuthException(
        AppL10n.strings.authEmailAlreadyUsed,
        code: 'email-already-in-use',
      );
    }

    final now = DateTime.now();
    final user = AppUser(
      id: _uuid.v4(),
      email: normalizedEmail,
      displayName: normalizedDisplayName,
      inviteCode: await _generateUniqueInviteCode(),
      status: 'single',
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
    );

    users.add({
      ...user.toJson(),
      'password': normalizedPassword,
    });

    await _saveUserRecords(users);
    await _write(_sessionStorageKey, user.id);

    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (isUsingFirebase) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw AuthException(AppL10n.strings.authSessionUnavailable);
        }

        await _ensureFirebaseSessionReady(firebaseUser);

        final existingProfile = await _userService.fetchUserProfile(firebaseUser.uid);
        final user = await _ensureInviteCode(_buildSignInProfile(
          firebaseUser: firebaseUser,
          fallbackEmail: email.trim().toLowerCase(),
          existingProfile: existingProfile,
        ));

        if (existingProfile == null) {
          await _userService.saveUserProfile(user);
        } else {
          await _userService.updateUserProfile(user);
        }
        return user;
      } on FirebaseAuthException catch (e) {
        throw AuthException(_mapFirebaseAuthError(e), code: e.code);
      } on FirebaseException catch (e) {
        throw AuthException(_mapFirestoreError(e), code: e.code);
      }
    }

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    final users = await _loadUserRecords();
    final index = users.indexWhere(
      (user) => (user['email'] as String).toLowerCase() == normalizedEmail,
    );

    if (index == -1) {
      throw AuthException(
        AppL10n.strings.authAccountNotFound,
        code: 'user-not-found',
      );
    }

    final record = users[index];
    if ((record['password'] as String?) != normalizedPassword) {
      throw AuthException(
        AppL10n.strings.authWrongPassword,
        code: 'wrong-password',
      );
    }

    final signedInUser = await _ensureInviteCode(AppUser.fromJson(record).copyWith(
      updatedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    ));

    users[index] = {
      ...signedInUser.toJson(),
      'password': record['password'],
    };

    await _saveUserRecords(users);
    await _write(_sessionStorageKey, signedInUser.id);

    return signedInUser;
  }

  /// Sign in with Apple (pairing-funnel PF1 — iOS only, Firebase only; the
  /// button is hidden everywhere else). Firebase drives the native Apple sheet.
  /// Profile, errors and the `'social-canceled'` sentinel: [_signInWithSocial].
  Future<({AppUser user, bool isNewUser})> signInWithApple() async {
    final failed = AppL10n.strings.appleSignInFailed;
    if (!isUsingFirebase) {
      throw AuthException(failed);
    }
    // Without both scopes Apple shares neither the email nor the name.
    return _signInWithSocial(
      () => _auth.signInWithProvider(
        AppleAuthProvider()
          ..addScope('email')
          ..addScope('name'),
      ),
      failed: failed,
    );
  }

  /// Sign in with Google (PF14 — iOS + Android, Firebase only). The Google SDK
  /// picks the account and returns an ID token that Firebase turns into a
  /// session. Closing the picker throws the `'social-canceled'` sentinel; the
  /// rest is shared with Apple ([_signInWithSocial]).
  Future<({AppUser user, bool isNewUser})> signInWithGoogle() async {
    final failed = AppL10n.strings.googleSignInFailed;
    if (!isUsingFirebase) {
      throw AuthException(failed);
    }
    final idToken = await _pickGoogleIdToken(failed);
    return _signInWithSocial(
      () => _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      ),
      failed: failed,
    );
  }

  /// The Google picker → a non-empty ID token (sign-in, and the re-auth of
  /// [setPassword]). Throws [AuthException]: the `'social-canceled'` sentinel
  /// when the picker is closed, else [failed].
  Future<String> _pickGoogleIdToken(String failed) async {
    final String? idToken;
    try {
      idToken = await googleIdToken();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('social-canceled');
      }
      // SDK text is English and technical — log it, never show it.
      debugPrint('AuthService Google sign-in error ${e.code}: ${e.description}');
      throw AuthException(failed);
    } catch (e) {
      // e.g. iOS without the REVERSED_CLIENT_ID URL scheme (PlatformException).
      debugPrint('AuthService Google sign-in error: $e');
      throw AuthException(failed);
    }
    if (idToken == null || idToken.isEmpty) {
      debugPrint('AuthService Google sign-in returned no ID token');
      throw AuthException(failed);
    }
    return idToken;
  }

  /// The account-picker step of [signInWithGoogle]: the Google ID token, or a
  /// [GoogleSignInException]. Overridden in tests.
  @visibleForTesting
  Future<String?> googleIdToken() async {
    await _ensureGoogleSignIn();
    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  }

  /// [GoogleSignIn.initialize] must run exactly once, app-wide, before any
  /// other Google call. A failed attempt is forgotten so the next one retries.
  static Future<void>? _googleInit;

  Future<void> _ensureGoogleSignIn() async {
    // iOS: the OAuth client from GoogleService-Info.plist (PF17). Android
    // ignores clientId and reads `default_web_client_id`, generated from
    // google-services.json, as its server client id.
    final pending = _googleInit ??= GoogleSignIn.instance.initialize(
      clientId: Firebase.app().options.iosClientId,
    );
    try {
      await pending;
    } catch (_) {
      _googleInit = null;
      rethrow;
    }
  }

  /// Best-effort Google sign-out (PF16) so the next Google sign-in can pick
  /// another account; [disconnect] also revokes the app's Google grant. Never
  /// throws — callers fire and forget.
  Future<void> _googleSignOut({bool disconnect = false}) async {
    try {
      await _ensureGoogleSignIn();
      final google = GoogleSignIn.instance;
      await (disconnect ? google.disconnect() : google.signOut());
    } catch (e) {
      debugPrint('AuthService Google sign-out failed: $e');
    }
  }

  static bool _hasGoogle(User? user) =>
      user?.providerData.any((info) => info.providerId == 'google.com') ??
      false;

  /// Shared tail of Apple/Google sign-in: [signIn] gets the Firebase
  /// credential. The first sign-in creates `users/{uid}` like [getCurrentUser]
  /// does, later ones refresh it like [signIn]; these accounts skip email
  /// verification (PF3). `isNewUser` = a profile was just created (analytics
  /// sign_up vs login). Throws [AuthException]: the `'social-canceled'`
  /// sentinel when the user closes the Apple sheet,
  /// [EmailHasPasswordAccountException] for PF6, otherwise localized copy
  /// ([failed] when nothing more specific fits).
  Future<({AppUser user, bool isNewUser})> _signInWithSocial(
    Future<UserCredential> Function() signIn, {
    required String failed,
  }) async {
    try {
      final credential = await signIn();

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AuthException(failed);
      }
      // Rules require a non-empty, immutable `email`. Apple (real or private
      // relay) and Google always share one, so an empty one means the profile
      // write is doomed — don't leave a half-signed-in user behind.
      final email = firebaseUser.email?.trim().toLowerCase() ?? '';
      if (email.isEmpty) {
        await _auth.signOut();
        throw AuthException(failed);
      }

      await _ensureFirebaseSessionReady(firebaseUser);

      final existingProfile = await _userService.fetchUserProfile(firebaseUser.uid);
      if (existingProfile != null) {
        final user = await _ensureInviteCode(_buildSignInProfile(
          firebaseUser: firebaseUser,
          fallbackEmail: email,
          existingProfile: existingProfile,
        ));
        await _userService.updateUserProfile(user);
        return (user: user, isNewUser: false);
      }

      final user = await _ensureInviteCode(_buildFirebaseProfile(firebaseUser));
      await _userService.saveUserProfile(user);
      return (user: user, isNewUser: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        // The copy is provider-neutral despite its `apple` key.
        throw EmailHasPasswordAccountException(
          AppL10n.strings.appleEmailHasPasswordAccount,
          email: e.email,
        );
      }
      throw AuthException(
        _mapSocialAuthError(e, fallback: failed),
        code: e.code,
      );
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirestoreError(e));
    }
  }

  Future<void> signOut() async {
    if (isUsingFirebase) {
      final hadGoogle = _hasGoogle(_auth.currentUser);
      await _auth.signOut();
      if (hadGoogle) {
        unawaited(_googleSignOut());
      }
      return;
    }

    await _delete(_sessionStorageKey);
  }

  /// Continuous session-presence stream (feature auth — session-liveness #3).
  /// Emits `true` while a Firebase user is signed in and `false` the moment the
  /// session ends — including EXTERNAL revocations the user didn't trigger here
  /// (token revoked, account deleted on another device, password changed). The
  /// [AuthProvider] subscribes once so a dead session is pushed back to the
  /// guest gate instead of stranding the user on a stale /home. In local mode
  /// there is no such stream, so we return an empty one (never emits).
  Stream<bool> sessionActiveChanges() {
    if (!isUsingFirebase) {
      return const Stream<bool>.empty();
    }
    return _auth.authStateChanges().map((user) => user != null);
  }

  /// Re-authenticates the current Firebase user with their password so a
  /// sensitive op (account deletion) can clear a stale-session
  /// `unauthenticated` challenge (#2). Minting a fresh credential repairs the
  /// ID token the callable needs. Firebase-only. Throws [AuthException]:
  /// `'session-gone'` when there is no local user/email to re-auth (must do a
  /// full re-login), otherwise a mapped message (e.g. wrong password).
  Future<void> reauthenticateWithPassword(String password) async {
    if (!isUsingFirebase) {
      return;
    }
    final user = _auth.currentUser;
    final email = user?.email?.trim();
    if (user == null || email == null || email.isEmpty) {
      throw const AuthException('session-gone');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      // Force a fresh ID token so the next deleteAccount callable carries a
      // valid auth context instead of re-hitting `unauthenticated`.
      await user.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  /// Email of the currently authenticated Firebase user (null in local mode or
  /// when signed out). Used by the verify-email gate to show where the link
  /// was sent.
  String? get currentEmail => _auth.currentUser?.email;

  /// True only when the current Firebase user is a post-cutoff account that has
  /// NOT yet verified its email (D-auth2). Local-fallback always returns false
  /// (no email infra, D-auth3). Only password accounts are gated (PF3): Apple
  /// and Google users never see the gate, whatever `emailVerified` says — also
  /// after they add a password (AU1), the provider vouched for the email.
  /// Grandfathered accounts (created before the cutoff) also return false.
  /// Uses `!creationTime.isBefore(cutoff)` so the cutoff instant itself counts
  /// as in-scope.
  bool get requiresEmailVerification {
    if (!isUsingFirebase) {
      return false;
    }
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) {
      return false;
    }
    final providers = user.providerData.map((info) => info.providerId).toSet();
    if (!providers.contains('password') ||
        providers.contains('apple.com') ||
        providers.contains('google.com')) {
      return false;
    }
    final creationTime = user.metadata.creationTime;
    if (creationTime == null) {
      return false;
    }
    return !creationTime.isBefore(kEmailVerificationCutoff);
  }

  /// The signed-in account confirms in the Apple sheet (PF5, AU1): on iOS
  /// whenever Apple is linked, a password too — only the sheet's code
  /// revokes the Apple grant (Guideline 5.1.1(v), AU3). iOS is asked first
  /// whether its Apple ID is the account's: once per deletion with a
  /// password ([passwordInsteadOfAppleSheet], BUG-25), before the sheet of
  /// [setPassword] (BUG-27).
  bool get reauthWithApple => _currentReauth == 'apple.com';

  /// The signed-in account confirms deletion with Google (PF16): no password,
  /// so its re-auth dialog has no field.
  bool get reauthWithGoogle => _currentReauth == 'google.com';

  String? get _currentReauth {
    if (!isUsingFirebase) {
      return null;
    }
    final user = _auth.currentUser;
    return user == null ? null : _reauthProvider(user);
  }

  /// What re-authenticates [user] for a deletion or [setPassword]:
  /// `'apple.com'` (the Apple sheet) on iOS whenever Apple is linked, so its
  /// grant can be revoked (AU3); else null (the password) when there is one;
  /// else `'google.com'`. Android has no native Sign in with Apple, so Apple +
  /// Google there goes with Google.
  static String? _reauthProvider(User user) {
    final providers = user.providerData.map((info) => info.providerId).toSet();
    final apple = providers.contains('apple.com');
    if (apple && defaultTargetPlatform == TargetPlatform.iOS) {
      return 'apple.com';
    }
    if (providers.contains('password')) {
      return null;
    }
    if (providers.contains('google.com')) {
      return 'google.com';
    }
    return apple ? 'apple.com' : null;
  }

  /// AU1 (D1): an Apple/Google account with an email and no password can add
  /// one, to sign in where its provider isn't offered — signed up with Apple
  /// on an iPhone, now on Android.
  bool get canSetPassword {
    final user = isUsingFirebase ? _auth.currentUser : null;
    if (user == null || (user.email?.trim() ?? '').isEmpty) {
      return false;
    }
    return !user.providerData.any((info) => info.providerId == 'password');
  }

  /// Links the account's own email (Apple's hidden relay address included)
  /// with [password] (AU1). A stale session (`requires-recent-login`)
  /// re-authenticates with the account's provider — the Apple sheet
  /// ([_appleSheetForSameUser]) or the Google picker — then links once more.
  /// Throws [AuthException]: `'social-canceled'` when the sheet or picker is
  /// closed; `'apple-id-mismatch'` / `'session-gone'` when the sheet signed in
  /// another Apple ID (already signed out, as for a deletion) or the session
  /// isn't [uid]'s — the account on screen — any more (BUG-24); otherwise
  /// copy — also when iOS says its Apple ID isn't the account's: no sheet
  /// then, still signed in (BUG-27).
  Future<void> setPassword(String password, {required String uid}) async {
    final l10n = AppL10n.strings;
    final user = isUsingFirebase ? _auth.currentUser : null;
    final email = user?.email?.trim() ?? '';
    if (user == null || email.isEmpty) {
      throw AuthException(l10n.setPasswordFailed);
    }
    // Trimmed like sign-up and sign-in, so the same typing signs in later.
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password.trim(),
    );
    try {
      try {
        await _requireSession(uid);
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') {
          rethrow;
        }
        final fresh = await _reauthenticate(user);
        await _requireSession(uid);
        await fresh.linkWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'canceled':
        case 'web-context-canceled':
          throw const AuthException('social-canceled');
        case 'weak-password':
          throw AuthException(l10n.authWeakPassword);
        case 'provider-already-linked':
          // Added on another phone meanwhile: reload so the row goes away.
          try {
            await user.reload();
          } catch (_) {
            // Best-effort — the next cold start reloads the user anyway.
          }
          throw AuthException(l10n.setPasswordAlreadySet);
        case 'email-already-in-use':
        case 'credential-already-in-use':
          throw AuthException(l10n.setPasswordEmailTaken);
        case 'user-mismatch':
          throw AuthException(l10n.setPasswordWrongGoogleAccount);
        case 'network-request-failed':
          throw AuthException(l10n.authNetworkError);
        case 'too-many-requests':
          throw AuthException(l10n.authTooManyRequests);
        case 'user-disabled':
          throw AuthException(l10n.authUserDisabled);
      }
      debugPrint('AuthService set password error ${e.code}: ${e.message}');
      throw AuthException(l10n.setPasswordFailed);
    }
  }

  /// A fresh sign-in of [user] for [setPassword]: the Apple sheet or the
  /// Google picker ([_reauthProvider]). Returns the user to retry on.
  Future<User> _reauthenticate(User user) async {
    switch (_reauthProvider(user)) {
      case 'apple.com':
        // BUG-27: the sheet would sign this iPhone's other Apple ID in and
        // this account out — maybe its only way in, no password yet.
        if (!await _appleIdIsAccounts(user)) {
          throw AuthException(AppL10n.strings.setPasswordAppleIdMismatch);
        }
        return (await _appleSheetForSameUser(user)).user!;
      case 'google.com':
        final idToken = await _pickGoogleIdToken(
          AppL10n.strings.setPasswordFailed,
        );
        final result = await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
        return result.user ?? user;
    }
    throw AuthException(AppL10n.strings.setPasswordFailed);
  }

  /// Sends a password-reset email (feature auth, Đợt 1). D-auth4: to avoid
  /// leaking which emails are registered, a `user-not-found` is swallowed and
  /// reported as success — the caller shows the neutral "we sent it" state
  /// regardless. `invalid-email` is mapped to an exception (the UI validator
  /// blocks it first, but we still map defensively); network/other errors throw.
  Future<void> sendPasswordResetEmail(String email) async {
    if (!isUsingFirebase) {
      throw AuthException(
        AppL10n.strings.forgotPasswordLocalFallback,
        code: 'local-mode',
      );
    }

    try {
      // Use custom CF so the email arrives from noreply@dearembeiu.com (Resend)
      // instead of noreply@tonyembeiu.firebaseapp.com — avoids spam folder.
      await _functions
          .httpsCallable('sendCustomPasswordResetEmail')
          .call<dynamic>(<String, dynamic>{
        'email': email.trim().toLowerCase(),
        'languageCode': _activeLanguageCode,
      });
    } on FirebaseFunctionsException catch (e) {
      // CF returns success for unknown email (anti-enumeration) so we only
      // surface real errors (network failure, Resend down, etc.).
      throw AuthException(
        mapCallableError(e, AppL10n.strings.forgotPasswordNetworkError),
        code: e.code,
      );
    }
  }

  /// Re-sends the verification email to the current user (feature auth, Đợt 1).
  /// Custom branded email (Cách B) via the `sendCustomVerificationEmail`
  /// callable; a failure throws [AuthException] so the verify screen can show
  /// its resend-error state.
  Future<void> resendEmailVerification() async {
    try {
      await _sendCustomVerificationEmail();
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        mapCallableError(e, AppL10n.strings.verifyEmailResendError),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  /// Invokes the `sendCustomVerificationEmail` callable, which generates the
  /// Firebase verification link server-side and delivers the on-brand HTML email
  /// through Resend (feature auth — Cách B). The verification MECHANISM is
  /// unchanged (same oobCode link, app still polls `reload()`); only the email
  /// delivery channel differs from `FirebaseUser.sendEmailVerification()`.
  /// Passes the active UI language so the email copy matches what the user sees.
  Future<void> _sendCustomVerificationEmail() async {
    await _functions.httpsCallable('sendCustomVerificationEmail').call<dynamic>(
      <String, dynamic>{'languageCode': _activeLanguageCode},
    );
  }

  // ── Single-session enforcement ──────────────────────────────────────────────

  static const String _sessionTokenKey = 'session_token_v2';

  /// Generates a UUID, writes it to Firestore `users/{uid}.sessionToken` and
  /// to secure local storage, then returns it. Any other device watching this
  /// field will detect the mismatch and sign itself out.
  Future<String> mintSessionToken(String uid) async {
    if (!isUsingFirebase) return '';
    final token = _uuid.v4();
    await _userService.updateSessionToken(uid, token);
    await _write(_sessionTokenKey, token);
    return token;
  }

  /// Reads the session token we wrote locally on the last sign-in / cold-start.
  Future<String?> readLocalSessionToken() async => _read(_sessionTokenKey);

  /// Streams the `sessionToken` field from Firestore so the provider can react
  /// immediately when another device mints a replacement token.
  Stream<String?> watchSessionToken(String uid) {
    if (!isUsingFirebase) return const Stream.empty();
    return _userService.watchSessionToken(uid);
  }

  /// Clears the locally-stored session token (called on explicit sign-out so
  /// a leftover token on this device can't cause false-positive kicks).
  Future<void> clearLocalSessionToken() async => _delete(_sessionTokenKey);

  // ────────────────────────────────────────────────────────────────────────────

  /// Current UI language code ('vi' | 'en') without a BuildContext. Mirrors the
  /// locale MaterialApp resolved (synced into [AppL10n] via
  /// localeResolutionCallback); falls back to 'vi'.
  String get _activeLanguageCode {
    final code =
        AppL10n.strings.localeName.split(RegExp('[_-]')).first.trim().toLowerCase();
    return code.isNotEmpty ? code : 'vi';
  }

  /// Reloads the Firebase user (so a link tapped on another device/tab is
  /// reflected) and returns whether the email is now verified.
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> purgePersistedSession({bool clearDeviceCache = true}) async {
    if (_firebaseAuth != null || Firebase.apps.isNotEmpty) {
      try {
        final auth = _firebaseAuth ?? FirebaseAuth.instance;
        final hadGoogle = _hasGoogle(auth.currentUser);
        await auth.signOut();
        if (hadGoogle) {
          unawaited(_googleSignOut());
        }
      } catch (_) {
        // Ignore Firebase sign-out failures during reinstall cleanup.
      }
    }

    _memoryFallbackStore.clear();

    try {
      await _secureStorage.deleteAll();
    } catch (_) {
      await clearLocalAuthData();
    }

    if (clearDeviceCache) {
      await StorageService.clearLocalData();
    }
  }

  Future<void> clearLocalAuthData() async {
    await _delete(_sessionStorageKey);
    await _delete(_usersStorageKey);
  }

  Future<void> deleteAccount({required AppUser currentUser}) async {
    if (!isUsingFirebase) {
      await purgePersistedSession();
      return;
    }

    // Deletion is performed server-side by the `deleteAccount` Cloud Function:
    // it runs with admin privileges so it can remove the user doc, invite_code,
    // couple data + Storage objects and the Auth user — none of which the
    // client is permitted to delete directly under the security rules. Running
    // it as admin also avoids the `requires-recent-login` challenge that a
    // client-side FirebaseUser.delete() would hit. Apple accounts have already
    // confirmed through [confirmAppleDeletionIfNeeded] by the time we get here.
    final firebaseUser = _auth.currentUser;
    // A linked Google grant goes too, whatever confirmed the deletion (AU3).
    final hasGoogle = _hasGoogle(firebaseUser);
    if (firebaseUser != null &&
        _reauthProvider(firebaseUser) == 'google.com') {
      // PF16: Google has no sheet to re-authenticate with.
      await _refreshIdTokenBeforeDelete(firebaseUser);
    }
    // BUG-24: the callable deletes whoever's token it carries.
    await _requireSession(currentUser.id);
    try {
      await callDeleteAccount();
    } on TimeoutException {
      throw AuthException(AppL10n.strings.authNetworkError);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        throw AuthException('requires-recent-login');
      }
      throw AuthException(
        mapCallableError(e, AppL10n.strings.deleteAccountFailed),
      );
    }

    if (hasGoogle) {
      // Also revoke the app's Google grant (PF16).
      unawaited(disconnectGoogle());
    }
    await purgePersistedSession();
  }

  /// The server-side `deleteAccount` callable. Robustness (app-robustness C):
  /// bounded so the delete flow can't hang forever behind a stuck network.
  /// 60s is generous on purpose — the server runs recursiveDelete over the
  /// couple's subcollections + a Storage purge, which can legitimately take
  /// tens of seconds — so a shorter timeout would false-fail a deletion that
  /// is actually succeeding. A method so tests can stub it.
  @visibleForTesting
  Future<void> callDeleteAccount() => _functions
      .httpsCallable('deleteAccount')
      // `lang` picks the language of the server's error message.
      .call<dynamic>(<String, dynamic>{'lang': _activeLanguageCode})
      .timeout(const Duration(seconds: 60));

  /// Revokes the app's Google grant after a deletion (PF16); never throws. A
  /// method so tests can see it.
  @visibleForTesting
  Future<void> disconnectGoogle() => _googleSignOut(disconnect: true);

  /// Drops what this user keeps only on this phone after a deletion: sleep
  /// nights live in Hive, never in the account (AU8). Tests stub it.
  Future<void> wipeLocalUserData(String uid) => SleepService.wipeLocalData(uid);

  /// PF5 — an account with Apple confirms deletion in the Apple sheet: on iOS
  /// whenever Apple is linked, a password too (AU3), when [appleSheet] — the
  /// delete dialog's one answer ([passwordInsteadOfAppleSheet], BUG-25).
  /// iOS is never asked again here, so the deletion does what the dialog
  /// said (BUG-26). The provider's `deleteAccount` calls this BEFORE any
  /// teardown, so closing the sheet (`'social-canceled'`) leaves push and the
  /// session watch untouched. The sheet mints a fresh credential (the
  /// callable won't hit a stale session) and a one-time `authorizationCode`
  /// (~5 min) used to revoke the app's Apple token while the user still
  /// exists (Guideline 5.1.1(v)). Throws `'apple-id-mismatch'` (after
  /// signing out) when the sheet signed in a different Apple ID — nothing of
  /// this account is deleted then (PF18). A sheet that can't confirm (no
  /// Apple ID on the iPhone…) only skips the revocation (AU6). No-op without
  /// [appleSheet], for other accounts and in local mode.
  Future<void> confirmAppleDeletionIfNeeded({required bool appleSheet}) async {
    if (!isUsingFirebase || !appleSheet) {
      return;
    }
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || _reauthProvider(firebaseUser) != 'apple.com') {
      return;
    }
    final UserCredential credential;
    try {
      credential = await _appleSheetForSameUser(firebaseUser);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'canceled':
        case 'web-context-canceled':
          throw const AuthException('social-canceled');
        case 'network-request-failed':
          throw AuthException(AppL10n.strings.authNetworkError);
      }
      // AU6: `unknown` (no Apple ID signed in on this iPhone), `failed`,
      // `not-handled`, `invalid-response`… The user confirmed in our dialog
      // already: delete without revoking, the callable decides — on this
      // account's session only (BUG-24).
      debugPrint('AuthService Apple delete sheet error ${e.code}: ${e.message}');
      await _requireSession(firebaseUser.uid);
      await _refreshIdTokenBeforeDelete(firebaseUser);
      return;
    }
    await _revokeAppleToken(credential);
    await _refreshIdTokenBeforeDelete(credential.user!);
  }

  /// BUG-25, for the delete dialog: the signed-in account has Apple and a
  /// password, and this iPhone's Apple ID isn't the account's
  /// ([_appleIdIsAccounts]). The Apple sheet would sign that other Apple ID
  /// in (PF18) and the account could never be deleted here, so the password
  /// confirms, as in 1.9.0; the Apple grant stays, only the account's own
  /// Apple ID could revoke it. Without a password the sheet stays (PF18).
  /// Ask once per deletion and pass the answer on (BUG-26).
  Future<bool> passwordInsteadOfAppleSheet() async {
    final user = isUsingFirebase ? _auth.currentUser : null;
    return user != null &&
        _reauthProvider(user) == 'apple.com' &&
        user.providerData.any((info) => info.providerId == 'password') &&
        !await _appleIdIsAccounts(user);
  }

  static const MethodChannel _appleIdChannel = MethodChannel(
    'dear_embeiu/apple_id',
  );

  /// BUG-25, BUG-27 — iOS says "authorized" for [user]'s Apple user id
  /// (`providerData` → `apple.com` → `uid`): this iPhone's Apple ID is the
  /// account's, the Apple sheet signs the account itself in. Anything else —
  /// not found, revoked, no id, the channel failing or silent for 2 seconds
  /// — is false: the sheet would sign another Apple ID in.
  Future<bool> _appleIdIsAccounts(User user) async {
    final appleUserId = user.providerData
        .where((info) => info.providerId == 'apple.com')
        .map((info) => info.uid ?? '')
        .firstOrNull;
    if (appleUserId == null || appleUserId.isEmpty) {
      return false;
    }
    try {
      final state = await _appleIdChannel
          .invokeMethod<String>('credentialState', {'userId': appleUserId})
          .timeout(const Duration(seconds: 2));
      if (state == 'authorized') {
        return true;
      }
      debugPrint('AuthService Apple ID on this iPhone: $state');
    } catch (e) {
      debugPrint('AuthService Apple credential state failed: $e');
    }
    return false;
  }

  /// The Apple sheet as a fresh sign-in of [user] (deletion PF5, [setPassword]
  /// AU1): a credential for the same uid, sheet errors let through.
  ///
  /// Not reauthenticateWithProvider: on iOS (firebase_auth 6.5.3) it sets
  /// `isReauthenticatingWithApple`, which a cancelled sheet never clears, so
  /// the next successful Apple sign-in (after a sign-out) takes the reauth
  /// branch on a nil currentUser and never completes. Signing in again with
  /// the same Apple ID returns the same uid with a fresh credential and
  /// `authorizationCode`.
  ///
  /// The device's Apple ID changed (another uid signed in): signs out and
  /// throws `'apple-id-mismatch'` (`'session-gone'` without a user). An
  /// account that already existed for that Apple ID is never deleted or
  /// revoked (PF18).
  Future<UserCredential> _appleSheetForSameUser(User user) async {
    final credential = await _auth.signInWithProvider(AppleAuthProvider());
    final signedIn = credential.user;
    if (signedIn != null && signedIn.uid == user.uid) {
      return credential;
    }
    if (signedIn != null && credential.additionalUserInfo?.isNewUser == true) {
      // The sheet just created a Firebase user for that other Apple ID: don't
      // leave it orphaned. Revoke its grant first, while it is still signed
      // in: that first grant came from a sheet asking for no email, and Apple
      // may not share one later — kept, that Apple ID's Apple sign-in would
      // keep failing here (BUG-9).
      await _revokeAppleToken(credential);
      try {
        await signedIn.delete();
      } catch (e) {
        debugPrint('AuthService orphan Apple user delete failed: $e');
      }
    }
    // The sentinel goes out even when the sign-out fails (iOS keychain-error
    // can leave that Apple ID signed in). Thrown on, that error looked like a
    // sheet error to AU6, which then deleted whoever was signed in (BUG-24).
    await _signOutQuietly();
    throw AuthException(signedIn == null ? 'session-gone' : 'apple-id-mismatch');
  }

  /// BUG-24 — the delete callable and [setPassword] act on whichever session
  /// is live, and the Apple sheet can switch it to another Apple ID. Unless
  /// it is still [uid]'s: signs that session out ([_signOutQuietly]) and
  /// throws `'session-gone'` — nothing more runs on it.
  Future<void> _requireSession(String uid) async {
    final live = _auth.currentUser;
    if (live?.uid == uid) {
      return;
    }
    if (live != null) {
      await _signOutQuietly();
    }
    throw const AuthException('session-gone');
  }

  /// Signs out a session that isn't the account's (PF18, BUG-24); never
  /// throws, the caller's sentinel must win. The device isn't unregistered
  /// first, so its FCM token goes: the account's pushes stop arriving here
  /// (Functions prune dead tokens).
  Future<void> _signOutQuietly() async {
    try {
      await deleteMessagingToken();
    } catch (e) {
      debugPrint('AuthService FCM token delete failed: $e');
    }
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthService quiet sign-out failed: $e');
    }
  }

  /// Revokes the app's Apple grant with the sheet's one-time
  /// `authorizationCode`; needs that user still signed in. Best-effort: it
  /// fails until the Sign in with Apple key is set up in Firebase, and the
  /// account must still be deletable (PF5).
  Future<void> _revokeAppleToken(UserCredential credential) async {
    final code = credential.additionalUserInfo?.authorizationCode;
    if (code == null || code.isEmpty) {
      return;
    }
    try {
      await _auth.revokeTokenWithAuthorizationCode(code);
    } catch (e) {
      debugPrint('AuthService Apple token revoke failed: $e');
    }
  }

  /// A fresh ID token spares the delete callable a stale session. Bounded so
  /// the overlay can't hang, failures only logged: the callable decides.
  static Future<void> _refreshIdTokenBeforeDelete(User user) async {
    try {
      await user.getIdToken(true).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('AuthService token refresh before delete failed: $e');
    }
  }

  /// Invalidates this device's FCM token (PF18). A method so tests can see it.
  @visibleForTesting
  Future<void> deleteMessagingToken() =>
      FirebaseMessaging.instance.deleteToken();

  Future<void> updateCurrentUser(AppUser user) async {
    if (isUsingFirebase) {
      await _userService.updateUserProfile(user.copyWith(updatedAt: DateTime.now()));
      return;
    }

    final users = await _loadUserRecords();
    final index = users.indexWhere((record) => record['id'] == user.id);
    if (index == -1) {
      return;
    }

    users[index] = {
      ...user.toJson(),
      'password': users[index]['password'],
    };

    await _saveUserRecords(users);
  }

  Future<List<Map<String, dynamic>>> _loadUserRecords() async {
    final raw = await _read(_usersStorageKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((record) => Map<String, dynamic>.from(record))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _saveUserRecords(List<Map<String, dynamic>> records) async {
    await _write(_usersStorageKey, jsonEncode(records));
  }

  Future<String?> _read(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        _memoryFallbackStore[key] = value;
      }
      return value ?? _memoryFallbackStore[key];
    } catch (_) {
      return _memoryFallbackStore[key];
    }
  }

  Future<void> _write(String key, String value) async {
    _memoryFallbackStore[key] = value;
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      // Widget tests and unsupported runtimes can safely use memory fallback.
    }
  }

  Future<void> _delete(String key) async {
    _memoryFallbackStore.remove(key);
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      // Ignore and keep fallback state consistent.
    }
  }

  /// Builds a best-effort [AppUser] when the Firestore profile fetch times out
  /// on cold start (app-robustness A5). The Firebase user is already
  /// authenticated, so identity is trusted; we enrich it with the locally
  /// cached couple (if its members include this uid) so route resolution still
  /// sends the user to home rather than setup. inviteCode is left empty (it is
  /// only needed on the setup/invite surface, which a coupled user won't see);
  /// the real profile is reconciled on the next successful fetch/resume.
  Future<AppUser> _buildOfflineFallbackProfile(User firebaseUser) async {
    final base = _buildFirebaseProfile(firebaseUser);

    Couple? cachedCouple;
    try {
      cachedCouple = await StorageService.loadCouple();
    } catch (_) {
      cachedCouple = null;
    }

    if (cachedCouple != null && cachedCouple.memberIds.contains(firebaseUser.uid)) {
      final isActive = cachedCouple.memberIds.length >= 2;
      return base.copyWith(
        coupleId: cachedCouple.id,
        status: isActive ? 'in_couple' : 'waiting_partner',
      );
    }

    return base;
  }

  AppUser _buildFirebaseProfile(User firebaseUser) {
    final now = DateTime.now();
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email?.trim().toLowerCase() ?? '',
      displayName: profileDisplayName(
        firebaseName: firebaseUser.displayName,
        email: firebaseUser.email,
      ),
      inviteCode: '',
      status: 'single',
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
    );
  }

  /// Display name for a profile built from the Firebase user (PF4). Rules
  /// reject an empty one, so this never returns ''. Order: the name Firebase
  /// has (Apple fills it on the first sign-in), else the part of the email
  /// before @ — skipped for Apple's hidden relay address, whose random local
  /// part means nothing to a partner — else [defaultDisplayName].
  @visibleForTesting
  static String profileDisplayName({String? firebaseName, String? email}) {
    final name = firebaseName?.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    final address = email?.trim() ?? '';
    final localPart = address.split('@').first;
    if (localPart.isNotEmpty &&
        !address.toLowerCase().endsWith('@privaterelay.appleid.com')) {
      return localPart;
    }
    return AppL10n.strings.defaultDisplayName;
  }

  /// Apple/Google Firebase-auth failures → l10n copy (pairing-funnel design
  /// §2). Closing the Apple sheet maps to the `'social-canceled'` sentinel so
  /// the UI stays silent. PF6 (`account-exists-with-different-credential`) is
  /// handled by the caller, which needs the email. A disabled account and
  /// throttling get the email flow's copy (AU7). [fallback] is the copy for
  /// any other error (Apple / Google sign-in failed).
  String _mapSocialAuthError(
    FirebaseAuthException exception, {
    required String fallback,
  }) {
    switch (exception.code) {
      case 'canceled':
      case 'web-context-canceled':
        return 'social-canceled';
      case 'network-request-failed':
        return AppL10n.strings.authNetworkError;
      case 'user-disabled':
        return AppL10n.strings.authUserDisabled;
      case 'too-many-requests':
        return AppL10n.strings.authTooManyRequests;
      default:
        // Plugin/Firebase text is English and technical — log it, never show it.
        debugPrint(
          'AuthService social auth error ${exception.code}: ${exception.message}',
        );
        return fallback;
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException exception) {
    final rawMessage = exception.message ?? '';

    final l10n = AppL10n.strings;
    switch (exception.code) {
      case 'email-already-in-use':
        return l10n.authEmailAlreadyUsed;
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return l10n.authEmailPasswordNotEnabled;
      case 'invalid-email':
        return l10n.authInvalidEmail;
      case 'weak-password':
        return l10n.authWeakPassword;
      case 'user-not-found':
        return l10n.authAccountNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.authInvalidCredential;
      case 'too-many-requests':
        return l10n.authTooManyRequests;
      case 'network-request-failed':
        return l10n.authNetworkError;
      case 'user-disabled':
        return l10n.authUserDisabled;
      default:
        if (rawMessage.contains('CONFIGURATION_NOT_FOUND')) {
          return l10n.authConfigNotFound;
        }
        // Firebase's own message is English and technical — log it, never show it.
        debugPrint('AuthService auth error ${exception.code}: $rawMessage');
        return l10n.authFirebaseAuthGeneric;
    }
  }

  String _mapFirestoreError(FirebaseException exception) {
    final l10n = AppL10n.strings;
    switch (exception.code) {
      case 'invite-code-unavailable':
        return l10n.authInviteCodeUnavailable;
      case 'permission-denied':
        return l10n.authFirestorePermissionDenied;
      case 'unavailable':
        return l10n.authFirestoreUnavailable;
      default:
        debugPrint('AuthService firestore error ${exception.code}: ${exception.message}');
        return l10n.authFirestoreGeneric;
    }
  }

  /// What to show for a failed callable. Our functions throw HttpsError copy
  /// already in the user's language (picked from `lang`/`languageCode` in the
  /// request), so that is shown as-is. Anything the SDK makes up itself — offline
  /// ("UNAVAILABLE" on Android, `unknown` + an OS sentence on iOS), a timeout, or a
  /// crash that only says "INTERNAL" — gets local copy instead.
  @visibleForTesting
  static String mapCallableError(
    FirebaseFunctionsException exception,
    String fallback,
  ) {
    switch (exception.code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'unknown':
        return AppL10n.strings.authNetworkError;
      // The framework rejects a stale token itself with a bare English
      // "Unauthenticated"; ours only use this code for "sign in again".
      case 'unauthenticated':
        return AppL10n.strings.authSessionNotReady;
    }
    final message = (exception.message ?? '').trim();
    // Bare status names ("INTERNAL", "NOT FOUND") come from the SDK, not from us.
    if (message.isEmpty || message == message.toUpperCase()) {
      debugPrint('AuthService callable error ${exception.code}: $message');
      return fallback;
    }
    return message;
  }

  Future<void> _ensureFirebaseSessionReady(User firebaseUser) async {
    final expectedUid = firebaseUser.uid;

    if (_auth.currentUser?.uid != expectedUid) {
      // Robustness (app-robustness A2): never block cold start indefinitely.
      // `firstWhere` on authStateChanges can hang forever if the stream never
      // emits the expected uid (e.g. a network hiccup during token bootstrap).
      // Bound it to 5s; on timeout we throw `authSessionNotReady` so the caller
      // (getCurrentUser → AuthProvider.initialize) falls back to
      // unauthenticated and routes the user to the guest screen instead of
      // freezing on the splash.
      await _auth
          .authStateChanges()
          .firstWhere((user) => user?.uid == expectedUid)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () =>
                throw AuthException(AppL10n.strings.authSessionNotReady),
          );
    }

    final activeUser = _auth.currentUser;
    if (activeUser == null || activeUser.uid != expectedUid) {
      throw AuthException(AppL10n.strings.authSessionNotReady);
    }

    // Robustness (app-robustness A1): don't force-refresh the ID token on every
    // cold start. A cached token is valid for ~1h and is enough to resolve the
    // route; forcing a refresh adds a mandatory network round-trip on launch
    // (the main freeze source). Writes that need a fresh token still
    // force-refresh on demand via their own permission-recovery paths.
    // Timeout guard: getIdToken() can make a network call when the token is
    // close to expiry; without a bound this freezes the cold-start route on iOS
    // when the simulator has degraded connectivity.
    await activeUser.getIdToken().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw AuthException(AppL10n.strings.authSessionNotReady),
    );
  }

  AppUser _buildSignInProfile({
    required User firebaseUser,
    required String fallbackEmail,
    AppUser? existingProfile,
  }) {
    final baseUser = existingProfile ?? _buildFirebaseProfile(firebaseUser);
    final firebaseEmail = firebaseUser.email?.trim();
    final preservedEmail = (existingProfile?.email.trim().isNotEmpty == true)
        ? existingProfile!.email
        : (firebaseEmail?.isNotEmpty == true ? firebaseEmail! : fallbackEmail);
    final preferredDisplayName = firebaseUser.displayName?.trim().isNotEmpty == true
        ? firebaseUser.displayName!.trim()
        : (existingProfile?.displayName ?? fallbackEmail.split('@').first);

    return baseUser.copyWith(
      email: preservedEmail,
      displayName: preferredDisplayName,
      updatedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
  }

  Future<AppUser> _ensureInviteCode(AppUser user) async {
    if (user.hasInviteCode) {
      return user;
    }

    return user.copyWith(
      inviteCode: await _generateUniqueInviteCode(),
      updatedAt: DateTime.now(),
    );
  }

  Future<String> _generateUniqueInviteCode() async {
    if (isUsingFirebase) {
      return _userService.generateUniqueInviteCode();
    }

    final users = await _loadUserRecords();
    final existingCodes = users
        .map((record) => '${record['inviteCode'] ?? ''}'.trim().toUpperCase())
        .where((code) => code.isNotEmpty)
        .toSet();

    for (var attempt = 0; attempt < 12; attempt++) {
      final candidate = _generateInviteCode();
      if (!existingCodes.contains(candidate)) {
        return candidate;
      }
    }

    throw AuthException(AppL10n.strings.authInviteCodeGenerateFailed);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}

