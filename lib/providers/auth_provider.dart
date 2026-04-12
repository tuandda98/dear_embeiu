import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/auth_status.dart';
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
      await PushNotificationService.instance.syncForUser(_currentUser);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Không thể khởi tạo phiên đăng nhập: $e';
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
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Đăng nhập thất bại: $e';
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
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Tạo tài khoản thất bại: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError(notify: false);

    try {
      final previousUser = _currentUser;
      await PushNotificationService.instance.unregisterForUser(previousUser);
      await _authService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Đăng xuất thất bại: $e';
    } finally {
      _setLoading(false);
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

