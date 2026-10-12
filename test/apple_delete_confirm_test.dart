import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/services/auth_service.dart';

/// Pairing-funnel Tester round 1. BUG-1: the Apple delete confirmation signs
/// in again (never `reauthenticateWithProvider` — the fake user throws if it
/// is called) and refuses another Apple ID without deleting anything of the
/// account. BUG-6: its errors talk about deleting, not signing in. PF18: on
/// another Apple ID it removes the user the sheet just created (never an
/// existing one), drops the FCM token, signs out, says `apple-id-mismatch`.
/// Round 3: BUG-9 revokes that new user's Apple grant before deleting it;
/// Apple + Google linked re-authenticates with Google on Android; a failed
/// token refresh is only logged.
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

  test('another Apple ID that the sheet just created: revoke its grant, '
      'delete it, drop the FCM token, sign out, apple-id-mismatch', () async {
    final auth = _FakeAuth(signInUser: _FakeUser('u2'), isNewUser: true);
    final service = _FirebaseAuthService(auth);

    expect(await mismatch(auth, service), 'apple-id-mismatch');
    expect(auth.revokedCode, 'fresh-code');
    expect(auth.revokedAfterDelete, isFalse, reason: 'revoke needs the user');
    expect(auth.signInUser!.deleted, isTrue);
    expect(service.messagingTokenDeleted, isTrue);
    expect(auth.signedOut, isTrue);
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

  test('a failed revoke, orphan delete or token drop still signs out',
      () async {
    final auth = _FakeAuth(
      signInUser: _FakeUser('u2', deleteFails: true),
      isNewUser: true,
      revokeFails: true,
    );
    final service = _FirebaseAuthService(auth, tokenDeleteFails: true);

    expect(await mismatch(auth, service), 'apple-id-mismatch');
    expect(auth.signedOut, isTrue);
  });

  test('a failed token refresh is only logged: the callable decides', () async {
    final auth = _FakeAuth(signInUser: _FakeUser('u1', tokenFails: true));

    await _FirebaseAuthService(auth).confirmAppleDeletionIfNeeded();

    expect(auth.revokedCode, 'fresh-code');
  });

  test('Apple + Google linked: the Apple sheet on iOS, Google on Android',
      () async {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    _FakeAuth linked() => _FakeAuth(
      signInUser: _FakeUser('u1'),
      current: _FakeUser('u1', providers: const ['apple.com', 'google.com']),
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final android = linked();
    final onAndroid = _FirebaseAuthService(android);
    await onAndroid.confirmAppleDeletionIfNeeded();
    expect(android.sheetShown, isFalse);
    expect(onAndroid.isGoogleOnlyAccount, isTrue);
    expect(onAndroid.isAppleOnlyAccount, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final ios = linked();
    final onIos = _FirebaseAuthService(ios);
    await onIos.confirmAppleDeletionIfNeeded();
    expect(ios.sheetShown, isTrue);
    expect(onIos.isAppleOnlyAccount, isTrue);
    expect(onIos.isGoogleOnlyAccount, isFalse);
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

/// Signed in as [current] (default: Apple-only `u1`); the Apple sheet returns
/// [signInUser] (a brand-new Firebase user when [isNewUser]) or throws
/// [error].
class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth({
    this.signInUser,
    this.error,
    this.isNewUser = false,
    this.revokeFails = false,
    _FakeUser? current,
  }) : _current = current ?? _FakeUser('u1');

  final _FakeUser? signInUser;
  final FirebaseAuthException? error;
  final bool isNewUser;
  final bool revokeFails;
  final _FakeUser _current;
  bool sheetShown = false;
  String? revokedCode;
  bool revokedAfterDelete = false;
  bool signedOut = false;

  @override
  User? get currentUser => _current;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    sheetShown = true;
    final e = error;
    if (e != null) {
      throw e;
    }
    return _FakeCredential(signInUser, isNewUser: isNewUser);
  }

  @override
  Future<void> revokeTokenWithAuthorizationCode(String code) async {
    revokedCode = code;
    revokedAfterDelete = signInUser?.deleted ?? false;
    if (revokeFails) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _FakeUser extends Fake implements User {
  _FakeUser(
    this.uid, {
    this.deleteFails = false,
    this.tokenFails = false,
    this.providers = const ['apple.com'],
  });

  @override
  final String uid;

  final bool deleteFails;
  final bool tokenFails;
  final List<String> providers;
  bool tokenRefreshed = false;
  bool deleted = false;

  @override
  List<UserInfo> get providerData => [for (final id in providers) _Provider(id)];

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (tokenFails) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
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

class _Provider extends Fake implements UserInfo {
  _Provider(this.providerId);

  @override
  final String providerId;
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
