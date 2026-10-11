import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/services/auth_service.dart';

/// Pairing-funnel Tester round 1. BUG-1: the Apple delete confirmation signs
/// in again (never `reauthenticateWithProvider` — the fake user throws if it
/// is called) and refuses another Apple ID without deleting anything. BUG-6:
/// its errors talk about deleting, not signing in.
void main() {
  test('same Apple ID: revoke with the fresh code, refresh the token', () async {
    final auth = _FakeAuth(signInUser: _FakeUser('u1'));

    await _FirebaseAuthService(auth).confirmAppleDeletionIfNeeded();

    expect(auth.revokedCode, 'fresh-code');
    expect(auth.signInUser!.tokenRefreshed, isTrue);
    expect(auth.signedOut, isFalse);
  });

  test('another Apple ID: sign out, session-gone, nothing revoked', () async {
    final auth = _FakeAuth(signInUser: _FakeUser('u2'));

    await expectLater(
      _FirebaseAuthService(auth).confirmAppleDeletionIfNeeded(),
      throwsA(isA<AuthException>()
          .having((e) => e.message, 'message', 'session-gone')),
    );
    expect(auth.signedOut, isTrue);
    expect(auth.revokedCode, isNull);
  });

  test('errors: cancel stays silent, the rest speak about deleting', () async {
    Future<String> messageFor(String code) async {
      final auth = _FakeAuth(error: FirebaseAuthException(code: code));
      try {
        await _FirebaseAuthService(auth).confirmAppleDeletionIfNeeded();
      } on AuthException catch (e) {
        return e.message;
      }
      fail('expected an AuthException for $code');
    }

    final l10n = AppL10n.strings;
    expect(await messageFor('canceled'), 'apple-canceled');
    expect(await messageFor('web-context-canceled'), 'apple-canceled');
    expect(await messageFor('network-request-failed'), l10n.authNetworkError);
    expect(await messageFor('failed'), l10n.deleteAccountFailed);
    expect(await messageFor('invalid-credential'), l10n.deleteAccountFailed);
  });
}

class _FirebaseAuthService extends AuthService {
  _FirebaseAuthService(FirebaseAuth auth) : super(firebaseAuth: auth);

  @override
  bool get isUsingFirebase => true;
}

/// Signed in as Apple-only `u1`; the Apple sheet returns [signInUser] or
/// throws [error].
class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth({this.signInUser, this.error});

  final _FakeUser? signInUser;
  final FirebaseAuthException? error;
  final _FakeUser _current = _FakeUser('u1');
  String? revokedCode;
  bool signedOut = false;

  @override
  User? get currentUser => _current;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    final e = error;
    if (e != null) {
      throw e;
    }
    return _FakeCredential(signInUser);
  }

  @override
  Future<void> revokeTokenWithAuthorizationCode(String code) async {
    revokedCode = code;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  bool tokenRefreshed = false;

  @override
  List<UserInfo> get providerData => [_AppleInfo()];

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    tokenRefreshed = forceRefresh;
    return 'token';
  }
}

class _AppleInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'apple.com';
}

class _FakeCredential extends Fake implements UserCredential {
  _FakeCredential(this.user);

  @override
  final User? user;

  @override
  AdditionalUserInfo? get additionalUserInfo => _FreshCode();
}

class _FreshCode extends Fake implements AdditionalUserInfo {
  @override
  String? get authorizationCode => 'fresh-code';
}
