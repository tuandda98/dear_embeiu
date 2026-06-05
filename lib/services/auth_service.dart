import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import '../models/couple.dart';
import 'firebase_bootstrap_service.dart';
import 'storage_service.dart';
import 'user_service.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
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
        throw AuthException(_mapFirebaseAuthError(e));
      } on FirebaseException catch (e) {
        throw AuthException(_mapFirestoreError(e));
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
      throw AuthException(AppL10n.strings.authEmailAlreadyUsed);
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
        throw AuthException(_mapFirebaseAuthError(e));
      } on FirebaseException catch (e) {
        throw AuthException(_mapFirestoreError(e));
      }
    }

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    final users = await _loadUserRecords();
    final index = users.indexWhere(
      (user) => (user['email'] as String).toLowerCase() == normalizedEmail,
    );

    if (index == -1) {
      throw AuthException(AppL10n.strings.authAccountNotFound);
    }

    final record = users[index];
    if ((record['password'] as String?) != normalizedPassword) {
      throw AuthException(AppL10n.strings.authWrongPassword);
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

  Future<void> signOut() async {
    if (isUsingFirebase) {
      await _auth.signOut();
      return;
    }

    await _delete(_sessionStorageKey);
  }

  /// Email of the currently authenticated Firebase user (null in local mode or
  /// when signed out). Used by the verify-email gate to show where the link
  /// was sent.
  String? get currentEmail => _auth.currentUser?.email;

  /// True only when the current Firebase user is a post-cutoff account that has
  /// NOT yet verified its email (D-auth2). Local-fallback always returns false
  /// (no email infra, D-auth3); Google/Apple users are verified on creation so
  /// they return false too. Grandfathered accounts (created before the cutoff)
  /// also return false. Uses `!creationTime.isBefore(cutoff)` so the cutoff
  /// instant itself counts as in-scope.
  bool get requiresEmailVerification {
    if (!isUsingFirebase) {
      return false;
    }
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) {
      return false;
    }
    final creationTime = user.metadata.creationTime;
    if (creationTime == null) {
      return false;
    }
    return !creationTime.isBefore(kEmailVerificationCutoff);
  }

  /// Sends a password-reset email (feature auth, Đợt 1). D-auth4: to avoid
  /// leaking which emails are registered, a `user-not-found` is swallowed and
  /// reported as success — the caller shows the neutral "we sent it" state
  /// regardless. `invalid-email` is mapped to an exception (the UI validator
  /// blocks it first, but we still map defensively); network/other errors throw.
  Future<void> sendPasswordResetEmail(String email) async {
    if (!isUsingFirebase) {
      throw AuthException(AppL10n.strings.forgotPasswordLocalFallback);
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // D-auth4 anti-enumeration: treat "no such account" as success.
      if (e.code == 'user-not-found') {
        return;
      }
      throw AuthException(_mapFirebaseAuthError(e));
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
      throw AuthException(e.message ?? AppL10n.strings.authNetworkError);
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
        await (_firebaseAuth ?? FirebaseAuth.instance).signOut();
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
    // client-side FirebaseUser.delete() would hit.
    try {
      // Robustness (app-robustness C): bound the callable so the delete flow
      // can't hang forever behind a stuck network. 60s is generous on purpose —
      // the server runs recursiveDelete over the couple's subcollections + a
      // Storage purge, which can legitimately take tens of seconds — so a
      // shorter timeout would false-fail a deletion that is actually succeeding.
      await _functions
          .httpsCallable('deleteAccount')
          .call<dynamic>()
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw AuthException(AppL10n.strings.authNetworkError);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        throw AuthException('requires-recent-login');
      }
      throw AuthException(e.message ?? AppL10n.strings.deleteAccountFailed);
    }

    await purgePersistedSession();
  }

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
      displayName: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : (firebaseUser.email?.split('@').first ?? AppL10n.strings.defaultDisplayName),
      inviteCode: '',
      status: 'single',
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
    );
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
      default:
        if (rawMessage.contains('CONFIGURATION_NOT_FOUND')) {
          return l10n.authConfigNotFound;
        }
        return exception.message ?? l10n.authFirebaseAuthGeneric;
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
        return exception.message ?? l10n.authFirestoreGeneric;
    }
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
    await activeUser.getIdToken();
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

