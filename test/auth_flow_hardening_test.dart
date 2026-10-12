import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/services/auth_service.dart';

/// Tests for the 2026-06-05 auth flow-hardening:
///   #2 re-auth-then-delete recovery, and
///   #3 the continuous session-liveness listener + intentional-clear guard,
/// plus the pairing-funnel PF5 rule that the Apple delete confirmation runs
/// before any teardown.
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

  group('PF5 Apple delete confirmation', () {
    test('closing the Apple sheet leaves the session fully intact', () async {
      final fake = _FakeAuthService()
        ..userToReturn = buildUser()
        ..appleConfirmError = const AuthException('social-canceled');
      final provider = AuthProvider(authService: fake);
      await provider.initialize();
      await _settle(); // session token minted + watched

      final result = await provider.deleteAccount(appleSheet: true);

      expect(result, 'social-canceled');
      expect(fake.deleteCalled, isFalse);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.errorMessage, isNull);

      // The single-session watch must still be alive: another device taking
      // over is still caught. Tearing down before the sheet used to cancel it.
      fake.emitRemoteToken('another-device');
      await _settle();
      expect(provider.sessionRevoked, isTrue);
    });

    test('another Apple ID in the sheet: apple-id-mismatch, nothing deleted',
        () async {
      final fake = _FakeAuthService()
        ..userToReturn = buildUser()
        ..appleConfirmError = const AuthException('apple-id-mismatch');
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      final result = await provider.deleteAccount(appleSheet: true);

      expect(result, 'apple-id-mismatch');
      expect(fake.deleteCalled, isFalse);
      expect(provider.errorMessage, isNull, reason: 'sentinel, never text');
    });
  });

  group('BUG-26 one deletion, on the dialog\'s answer', () {
    test('a second call while one runs returns at once and leaves it alone',
        () async {
      final fake = _FakeAuthService()
        ..userToReturn = buildUser()
        ..deleteGate = Completer<void>();
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      final first = provider.deleteAccount(appleSheet: true);
      await _settle();
      expect(provider.isLoading, isTrue);

      expect(
        await provider
            .deleteAccount(appleSheet: true)
            .timeout(const Duration(seconds: 1)),
        'delete-in-progress',
      );
      expect(fake.events, ['confirm', 'delete'], reason: 'one deletion');
      expect(provider.isLoading, isTrue, reason: 'the first still runs');

      fake.deleteGate!.complete();
      expect(await first, isNull);
      expect(fake.events, ['confirm', 'delete', 'wipe:u1']);
      expect(provider.isLoading, isFalse);
    });

    test('the sheet closed: Delete again runs again', () async {
      final fake = _FakeAuthService()
        ..userToReturn = buildUser()
        ..appleConfirmError = const AuthException('social-canceled');
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      expect(await provider.deleteAccount(appleSheet: true), 'social-canceled');
      expect(await provider.deleteAccount(appleSheet: true), 'social-canceled');
      expect(fake.events, ['confirm', 'confirm']);
    });

    test('the answer reaches the Apple confirmation; a password re-auth '
        'never shows the sheet', () async {
      final fake = _FakeAuthService()..userToReturn = buildUser();
      final provider = AuthProvider(authService: fake);
      await provider.initialize();
      await provider.deleteAccount(appleSheet: false);

      final again = _FakeAuthService()..userToReturn = buildUser();
      final reauth = AuthProvider(authService: again);
      await reauth.initialize();
      await reauth.reauthenticateAndDeleteAccount('pw');

      expect(fake.sheets, [false]);
      expect(again.sheets, [false]);
    });
  });

  group('AU8 sleep data kept only on this phone', () {
    test('wiped after the server delete, never before the Apple sheet',
        () async {
      final fake = _FakeAuthService()..userToReturn = buildUser();
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      expect(await provider.deleteAccount(appleSheet: true), isNull);
      expect(fake.events, ['confirm', 'delete', 'wipe:u1']);
    });

    test('kept when nothing was deleted (sheet closed)', () async {
      final fake = _FakeAuthService()
        ..userToReturn = buildUser()
        ..appleConfirmError = const AuthException('social-canceled');
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      expect(await provider.deleteAccount(appleSheet: true), 'social-canceled');
      expect(fake.events, ['confirm']);
    });

    test('a failed wipe never fails the deletion', () async {
      final fake = _FakeAuthService()
        ..userToReturn = buildUser()
        ..wipeError = StateError('box');
      final provider = AuthProvider(authService: fake);
      await provider.initialize();

      expect(await provider.deleteAccount(appleSheet: true), isNull);
      expect(provider.isAuthenticated, isFalse);
      expect(fake.events.last, 'wipe:u1');
    });
  });

  group('real AuthService local-fallback contract', () {
    final real = AuthService();

    test('confirmAppleDeletionIfNeeded is a no-op without Firebase', () async {
      // Must complete without throwing (never touches FirebaseAuth).
      await real.confirmAppleDeletionIfNeeded(appleSheet: true);
    });

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
  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();

  AppUser? userToReturn;
  AuthException? reauthError;
  AuthException? appleConfirmError;
  Object? wipeError;
  bool signOutCalled = false;
  bool reauthCalled = false;
  bool deleteCalled = false;

  /// Apple confirmation, server delete and local wipe, in call order.
  final events = <String>[];

  /// The `appleSheet` each Apple confirmation got.
  final sheets = <bool>[];

  /// Holds the server delete until completed (BUG-26).
  Completer<void>? deleteGate;

  void emitSession({required bool active}) => _sessionController.add(active);

  /// Simulates another device minting its own session token.
  void emitRemoteToken(String token) => _tokenController.add(token);

  @override
  Future<String> mintSessionToken(String uid) async => 'local-token';

  @override
  Stream<String?> watchSessionToken(String uid) => _tokenController.stream;

  @override
  Future<void> confirmAppleDeletionIfNeeded({required bool appleSheet}) async {
    events.add('confirm');
    sheets.add(appleSheet);
    final err = appleConfirmError;
    if (err != null) {
      throw err;
    }
  }

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
    events.add('delete');
    await deleteGate?.future;
  }

  @override
  Future<void> wipeLocalUserData(String uid) async {
    events.add('wipe:$uid');
    final err = wipeError;
    if (err != null) {
      throw err;
    }
  }
}
