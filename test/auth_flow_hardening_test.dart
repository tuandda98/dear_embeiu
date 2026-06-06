import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/services/auth_service.dart';

/// Tests for the 2026-06-05 auth flow-hardening:
///   #2 re-auth-then-delete recovery, and
///   #3 the continuous session-liveness listener + intentional-clear guard.
///
/// The interesting logic only runs when `isUsingFirebase == true` and the
/// session stream emits, so we inject a fake AuthService that lets the test
/// drive both. The real (local-fallback) AuthService is also exercised to lock
/// in the no-Firebase contract.
void main() {
  AppUser buildUser() {
    final now = DateTime(2026, 6, 5);
    return AppUser(
      id: 'u1',
      email: 'a@b.com',
      displayName: 'Bé Iu',
      inviteCode: 'ABC123',
      status: 'in_couple',
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
    );
  }

  group('#3 session-liveness listener', () {
    test('external revocation while authed flags sessionRevoked + clears state',
        () async {
      final fake = _FakeAuthService()..userToReturn = buildUser();
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      expect(provider.isAuthenticated, isTrue);
      expect(provider.sessionRevoked, isFalse);

      // Session pulled out from under us (token revoked / deleted elsewhere).
      fake.emitSession(active: false);
      await _settle();

      expect(provider.sessionRevoked, isTrue, reason: 'revocation must flag');
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);

      // One-shot: ack clears it so the shell only navigates once.
      provider.acknowledgeSessionRevoked();
      expect(provider.sessionRevoked, isFalse);
    });

    test('intentional sign-out does NOT flag a revocation', () async {
      final fake = _FakeAuthService()..userToReturn = buildUser();
      final provider = AuthProvider(authService: fake);
      await provider.initialize();
      expect(provider.isAuthenticated, isTrue);

      await provider.signOut();
      expect(fake.signOutCalled, isTrue);

      // The trailing `false` emit that Firebase would fire after sign-out must
      // be swallowed (intentional-clear guard), not read as a revocation.
      fake.emitSession(active: false);
      await _settle();

      expect(provider.sessionRevoked, isFalse);
    });

    test('emit while never-authenticated (guest) is ignored', () async {
      final fake = _FakeAuthService()..userToReturn = null; // guest
      final provider = AuthProvider(authService: fake);
      await provider.initialize();
      expect(provider.isAuthenticated, isFalse);

      fake.emitSession(active: false);
      await _settle();

      expect(provider.sessionRevoked, isFalse);
    });
  });

  group('#2 re-auth then delete', () {
    test('successful re-auth retries delete and succeeds', () async {
      final fake = _FakeAuthService()..userToReturn = buildUser();
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      final result = await provider.reauthenticateAndDeleteAccount('pw');

      expect(result, isNull, reason: 'null = deleted');
      expect(fake.reauthCalled, isTrue);
      expect(fake.deleteCalled, isTrue);
      expect(provider.isAuthenticated, isFalse);
    });

    test('session-gone surfaces and does NOT attempt delete', () async {
      final fake = _FakeAuthService()
        ..userToReturn = buildUser()
        ..reauthError = const AuthException('session-gone');
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      final result = await provider.reauthenticateAndDeleteAccount('pw');

      expect(result, 'session-gone');
      expect(fake.deleteCalled, isFalse);
    });

    test('wrong password surfaces the mapped message, keeps session', () async {
      final fake = _FakeAuthService()
        ..userToReturn = buildUser()
        ..reauthError = const AuthException('wrong-password-msg');
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      final result = await provider.reauthenticateAndDeleteAccount('pw');

      expect(result, 'wrong-password-msg');
      expect(fake.deleteCalled, isFalse);
      expect(provider.isAuthenticated, isTrue, reason: 'session still alive');
    });
  });

  group('real AuthService local-fallback contract', () {
    final real = AuthService();

    test('requiresEmailVerification is false without Firebase', () {
      expect(real.requiresEmailVerification, isFalse);
    });

    test('sessionActiveChanges is an empty stream without Firebase', () async {
      expect(await real.sessionActiveChanges().isEmpty, isTrue);
    });

    test('reauthenticateWithPassword is a no-op without Firebase', () async {
      // Must complete without throwing.
      await real.reauthenticateWithPassword('whatever');
    });
  });
}

/// Lets the microtask queue drain so a stream emit reaches the provider's
/// listener and `notifyListeners` settles.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

class _FakeAuthService extends AuthService {
  _FakeAuthService();

  final StreamController<bool> _sessionController =
      StreamController<bool>.broadcast();

  AppUser? userToReturn;
  AuthException? reauthError;
  bool signOutCalled = false;
  bool reauthCalled = false;
  bool deleteCalled = false;

  void emitSession({required bool active}) => _sessionController.add(active);

  @override
  bool get isUsingFirebase => true;

  @override
  String? get currentEmail => userToReturn?.email;

  @override
  bool get requiresEmailVerification => false;

  @override
  Future<AppUser?> getCurrentUser() async => userToReturn;

  @override
  Stream<bool> sessionActiveChanges() => _sessionController.stream;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    reauthCalled = true;
    final err = reauthError;
    if (err != null) {
      throw err;
    }
  }

  @override
  Future<void> deleteAccount({required AppUser currentUser}) async {
    deleteCalled = true;
  }
}
