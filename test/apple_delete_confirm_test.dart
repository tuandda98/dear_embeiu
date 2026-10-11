import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/services/auth_service.dart';

/// Pairing-funnel Tester round 1. BUG-1: the Apple delete confirmation signs
/// in again (never `reauthenticateWithProvider` — the fake user throws if it
/// is called) and refuses another Apple ID without deleting anything of the
/// account. BUG-6: its errors talk about deleting, not signing in. PF18: on
/// another Apple ID it removes the user the sheet just created (never an
/// existing one), drops the FCM token, signs out, says `apple-id-mismatch`.
void main() {
  test('same Apple ID: revoke with the fresh code, refresh the token', () async {
    final auth = _FakeAuth(signInUser: _FakeUser('u1'));
    final service = _FirebaseAuthService(auth);

    await service.confirmAppleDeletionIfNeeded();

    expect(auth.revokedCode, 'fresh-code');
    expect(auth.signInUser!.tokenRefreshed, isTrue);
    expect(auth.signedOut, isFalse);
    expect(service.messagingTokenDeleted, isFalse);
  });

  Future<String> mismatch(_FakeAuth auth, _FirebaseAuthService service) async {
    try {
      await service.confirmAppleDeletionIfNeeded();
    } on AuthException catch (e) {
      return e.message;
    }
    fail('expected an AuthException');
  }

  test('another Apple ID that the sheet just created: delete it, drop the '
      'FCM token, sign out, apple-id-mismatch', () async {
    final auth = _FakeAuth(signInUser: _FakeUser('u2'), isNewUser: true);
    final service = _FirebaseAuthService(auth);

    expect(await mismatch(auth, service), 'apple-id-mismatch');
    expect(auth.signInUser!.deleted, isTrue);
    expect(service.messagingTokenDeleted, isTrue);
    expect(auth.signedOut, isTrue);
    expect(auth.revokedCode, isNull);
    expect(auth.signInUser!.tokenRefreshed, isFalse);
  });

  test('another Apple ID that already had an account: never deleted', () async {
    final auth = _FakeAuth(signInUser: _FakeUser('u2'), isNewUser: false);
    final service = _FirebaseAuthService(auth);

    expect(await mismatch(auth, service), 'apple-id-mismatch');
    expect(auth.signInUser!.deleted, isFalse);
    expect(service.messagingTokenDeleted, isTrue);
    expect(auth.signedOut, isTrue);
    expect(auth.revokedCode, isNull);
  });

  test('a failed orphan delete or token drop still signs out', () async {
    final auth = _FakeAuth(
      signInUser: _FakeUser('u2', deleteFails: true),
      isNewUser: true,
    );
    final service = _FirebaseAuthService(auth, tokenDeleteFails: true);

    expect(await mismatch(auth, service), 'apple-id-mismatch');
    expect(auth.signedOut, isTrue);
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
    expect(await messageFor('canceled'), 'social-canceled');
    expect(await messageFor('web-context-canceled'), 'social-canceled');
    expect(await messageFor('network-request-failed'), l10n.authNetworkError);
    expect(await messageFor('failed'), l10n.deleteAccountFailed);
    expect(await messageFor('invalid-credential'), l10n.deleteAccountFailed);
  });
}

class _FirebaseAuthService extends AuthService {
  _FirebaseAuthService(FirebaseAuth auth, {this.tokenDeleteFails = false})
    : super(firebaseAuth: auth);

  final bool tokenDeleteFails;
  bool messagingTokenDeleted = false;

  @override
  bool get isUsingFirebase => true;

  @override
  Future<void> deleteMessagingToken() async {
    messagingTokenDeleted = true;
    if (tokenDeleteFails) {
      throw Exception('no FCM');
    }
  }
}

/// Signed in as Apple-only `u1`; the Apple sheet returns [signInUser] (a
/// brand-new Firebase user when [isNewUser]) or throws [error].
class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth({this.signInUser, this.error, this.isNewUser = false});

  final _FakeUser? signInUser;
  final FirebaseAuthException? error;
  final bool isNewUser;
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
    return _FakeCredential(signInUser, isNewUser: isNewUser);
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
  _FakeUser(this.uid, {this.deleteFails = false});

  @override
  final String uid;

  final bool deleteFails;
  bool tokenRefreshed = false;
  bool deleted = false;

  @override
  List<UserInfo> get providerData => [_AppleInfo()];

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    tokenRefreshed = forceRefresh;
    return 'token';
  }

  @override
  Future<void> delete() async {
    if (deleteFails) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    deleted = true;
  }
}

class _AppleInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'apple.com';
}

class _FakeCredential extends Fake implements UserCredential {
  _FakeCredential(this.user, {required this.isNewUser});

  @override
  final User? user;

  final bool isNewUser;

  @override
  AdditionalUserInfo? get additionalUserInfo => _Info(isNewUser);
}

class _Info extends Fake implements AdditionalUserInfo {
  _Info(this.isNewUser);

  @override
  final bool isNewUser;

  @override
  String? get authorizationCode => 'fresh-code';
}
