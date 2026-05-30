import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_l10n.dart';
import '../models/app_user.dart';
import 'firebase_bootstrap_service.dart';
import 'storage_service.dart';
import 'user_service.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

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

      final existingProfile = await _userService.fetchUserProfile(firebaseUser.uid);
      if (existingProfile != null) {
        final refreshedProfile = await _ensureInviteCode(existingProfile.copyWith(
          lastSeenAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        await _userService.updateUserProfile(refreshedProfile);
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
      await _functions.httpsCallable('deleteAccount').call<dynamic>();
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
      await _auth.authStateChanges().firstWhere(
        (user) => user?.uid == expectedUid,
      );
    }

    final activeUser = _auth.currentUser;
    if (activeUser == null || activeUser.uid != expectedUid) {
      throw AuthException(AppL10n.strings.authSessionNotReady);
    }

    await activeUser.getIdToken(true);
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

