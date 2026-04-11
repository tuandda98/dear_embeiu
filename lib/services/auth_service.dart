import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

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

  Future<AppUser?> getCurrentUser() async {
    if (isUsingFirebase) {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

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
          throw const AuthException('Không tạo được người dùng Firebase.');
        }

        await firebaseUser.updateDisplayName(displayName.trim());

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
      throw const AuthException('Email này đã được sử dụng rồi.');
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
          throw const AuthException('Không thể lấy phiên đăng nhập Firebase.');
        }

        final existingProfile = await _userService.fetchUserProfile(firebaseUser.uid);
        final user = await _ensureInviteCode((existingProfile ?? _buildFirebaseProfile(firebaseUser)).copyWith(
          updatedAt: DateTime.now(),
          lastSeenAt: DateTime.now(),
          email: firebaseUser.email ?? email.trim().toLowerCase(),
          displayName: firebaseUser.displayName?.trim().isNotEmpty == true
              ? firebaseUser.displayName!.trim()
              : (existingProfile?.displayName ?? email.trim().split('@').first),
        ));

        await _userService.updateUserProfile(user);
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
      throw const AuthException('Không tìm thấy tài khoản với email này.');
    }

    final record = users[index];
    if ((record['password'] as String?) != normalizedPassword) {
      throw const AuthException('Mật khẩu chưa đúng, bạn kiểm tra lại nhé.');
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
          : (firebaseUser.email?.split('@').first ?? 'Người dùng mới'),
      inviteCode: '',
      status: 'single',
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
    );
  }

  String _mapFirebaseAuthError(FirebaseAuthException exception) {
    final rawMessage = exception.message ?? '';

    switch (exception.code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng rồi.';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return 'Firebase Authentication chưa được cấu hình đầy đủ cho Email/Password. Bạn vào Firebase Console > Authentication > Sign-in method và bật Email/Password nhé.';
      case 'invalid-email':
        return 'Email chưa hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu còn yếu, bạn chọn mật khẩu mạnh hơn nhé.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu chưa đúng.';
      case 'too-many-requests':
        return 'Bạn thử lại sau ít phút nhé, hiện có quá nhiều yêu cầu đăng nhập.';
      case 'network-request-failed':
        return 'Không có kết nối mạng ổn định để đăng nhập Firebase.';
      default:
        if (rawMessage.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Firebase Authentication của project này chưa được bật hoặc chưa bật Email/Password. Bạn vào Firebase Console > Authentication > Sign-in method > Email/Password để bật lên.';
        }
        return exception.message ?? 'Đã có lỗi Firebase Auth xảy ra.';
    }
  }

  String _mapFirestoreError(FirebaseException exception) {
    switch (exception.code) {
      case 'invite-code-unavailable':
        return 'Không thể tạo mã mời cho tài khoản lúc này, bạn thử lại nhé.';
      case 'permission-denied':
        return 'Firestore đang chặn quyền ghi dữ liệu người dùng. Bạn vào Firebase Console > Firestore Database > Rules và cho phép user đã đăng nhập tạo/ghi `users/{uid}` của chính họ.';
      case 'unavailable':
        return 'Firestore hiện chưa khả dụng hoặc mạng không ổn định. Bạn thử lại sau ít phút nhé.';
      default:
        return exception.message ?? 'Đã có lỗi Firestore xảy ra.';
    }
  }

  Future<AppUser> _ensureInviteCode(AppUser user) async {
    if (user.hasInviteCode) {
      return user.copyWith(inviteCode: user.inviteCode.trim().toUpperCase());
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

    throw const AuthException('Không thể tạo mã mời mới, bạn thử lại sau nhé.');
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

