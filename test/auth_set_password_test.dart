import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart' as app;
import 'package:dear_embeiu/services/auth_service.dart';

/// Audit 2026-10-12 AU1 (D1): an Apple account made on an iPhone has no way
/// in on Android — "Set a password" links the account's own email with a
/// password. An old session re-authenticates with the account's provider
/// first (the Apple sheet, never `reauthenticateWithProvider`; the Google
/// picker), and the email-verification gate keeps ignoring Apple/Google
/// accounts once they have a password. BUG-24: the password only ever goes
/// onto the account on screen, never onto a session the sheet left behind.
/// BUG-27: the Apple sheet opens only when iOS says this iPhone's Apple ID is
/// the account's; otherwise the copy, and the session stays.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppL10n.strings;

  Future<String?> errorOf(Future<void> Function() run) async {
    try {
      await run();
    } on AuthException catch (e) {
      return e.message;
    }
    return null;
  }

  group('canSetPassword', () {
    test('only a Firebase account with an email and no password', () {
      bool can(_FakeUser user) => _Service(_FakeAuth(user)).canSetPassword;

      expect(can(_FakeUser(providers: ['apple.com'])), isTrue);
      expect(can(_FakeUser(providers: ['google.com'])), isTrue);
      expect(can(_FakeUser(providers: ['apple.com', 'password'])), isFalse);
      expect(can(_FakeUser(providers: ['apple.com'], email: ' ')), isFalse);
      expect(AuthService().canSetPassword, isFalse, reason: 'local fallback');
    });
  });

  group('setPassword', () {
    test('links the account email with the trimmed password', () async {
      final user = _FakeUser(providers: ['apple.com']);
      final auth = _FakeAuth(user);

      await _Service(auth).setPassword('  secret1 ', uid: 'u1');

      final linked = user.linked.single as EmailAuthCredential;
      expect(linked.email, 'xyz@privaterelay.appleid.com');
      expect(linked.password, 'secret1');
      expect(auth.sheetShown, isFalse);
    });

    test('old session, Apple: iOS says its Apple ID is the account\'s, the '
        'sheet, then links on the fresh user', () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final asked = _mockAppleIdState(() => 'authorized');
      final user = _FakeUser(
        providers: ['apple.com'],
        linkErrors: ['requires-recent-login'],
      );
      final fresh = _FakeUser(providers: ['apple.com']);
      final auth = _FakeAuth(user, sheetUser: fresh);

      await _Service(auth).setPassword('secret1', uid: 'u1');

      expect(asked, ['apple-sub-u1'], reason: 'before the sheet (BUG-27)');
      expect(auth.sheetShown, isTrue);
      expect(user.linked, hasLength(1), reason: 'the stale try');
      expect(fresh.linked, hasLength(1), reason: 'the retry');
      expect(auth.signedOut, isFalse);
    });

    test(
      'old session, Google: the picker, reauth with its ID token, link',
      () async {
        final user = _FakeUser(
          providers: ['google.com'],
          linkErrors: ['requires-recent-login'],
        );
        final auth = _FakeAuth(user);

        await _Service(auth).setPassword('secret1', uid: 'u1');

        final reauth = user.reauthenticated.single as OAuthCredential;
        expect(reauth.providerId, 'google.com');
        expect(reauth.idToken, 'google-id-token');
        expect(user.linked, hasLength(2));
        expect(auth.sheetShown, isFalse);
      },
    );

    test('closing the Apple sheet or the Google picker stays silent', () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _mockAppleIdState(() => 'authorized');
      final apple = _FakeUser(
        providers: ['apple.com'],
        linkErrors: ['requires-recent-login'],
      );
      final appleAuth = _FakeAuth(
        apple,
        sheetError: FirebaseAuthException(code: 'canceled'),
      );
      expect(
        await errorOf(
          () => _Service(appleAuth).setPassword('secret1', uid: 'u1'),
        ),
        'social-canceled',
      );
      expect(apple.linked, hasLength(1), reason: 'no retry');

      final google = _FakeUser(
        providers: ['google.com'],
        linkErrors: ['requires-recent-login'],
      );
      final picker = _Service(
        _FakeAuth(google),
        pickError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      );
      expect(
        await errorOf(() => picker.setPassword('secret1', uid: 'u1')),
        'social-canceled',
      );
      expect(google.reauthenticated, isEmpty);
    });

    test('the sheet still signs in another Apple ID: signed out, nothing '
        'linked', () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _mockAppleIdState(() => 'authorized');
      final user = _FakeUser(
        providers: ['apple.com'],
        linkErrors: ['requires-recent-login'],
      );
      final other = _FakeUser(uid: 'u2', providers: ['apple.com']);
      final auth = _FakeAuth(user, sheetUser: other);

      expect(
        await errorOf(() => _Service(auth).setPassword('secret1', uid: 'u1')),
        'apple-id-mismatch',
      );
      expect(auth.signedOut, isTrue);
      expect(other.linked, isEmpty);
    });

    test(
      'BUG-24 the sheet left another Apple ID signed in (its sign-out '
      'failed): apple-id-mismatch, and a second try links nothing either',
      () async {
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        _mockAppleIdState(() => 'authorized');
        final user = _FakeUser(
          providers: ['apple.com'],
          linkErrors: ['requires-recent-login'],
        );
        final other = _FakeUser(uid: 'u2', providers: ['apple.com']);
        final auth = _FakeAuth(
          user,
          sheetUser: other,
          switchesSession: true,
          signOutError: FirebaseAuthException(code: 'keychain-error'),
        );
        final service = _Service(auth);

        expect(
          await errorOf(() => service.setPassword('secret1', uid: 'u1')),
          'apple-id-mismatch',
        );
        expect(auth.currentUser?.uid, 'u2', reason: 'the sign-out did fail');
        expect(
          await errorOf(() => service.setPassword('secret1', uid: 'u1')),
          'session-gone',
        );
        expect(other.linked, isEmpty);
      },
    );

    test('BUG-24 a session that is not the account on screen: session-gone, '
        'signed out, nothing linked', () async {
      final other = _FakeUser(uid: 'u2', providers: ['google.com']);
      final auth = _FakeAuth(other);

      expect(
        await errorOf(() => _Service(auth).setPassword('secret1', uid: 'u1')),
        'session-gone',
      );
      expect(other.linked, isEmpty);
      expect(auth.signedOut, isTrue);
    });

    test('BUG-24 the session switching during the re-auth: session-gone, '
        'the retry links nothing', () async {
      final other = _FakeUser(uid: 'u2', providers: ['google.com']);
      late final _FakeAuth auth;
      final user = _FakeUser(
        providers: ['google.com'],
        linkErrors: ['requires-recent-login'],
        onReauth: () => auth.current = other,
      );
      auth = _FakeAuth(user);

      expect(
        await errorOf(() => _Service(auth).setPassword('secret1', uid: 'u1')),
        'session-gone',
      );
      expect(user.linked, hasLength(1), reason: 'only the stale try');
      expect(other.linked, isEmpty);
      expect(auth.signedOut, isTrue);
    });

    group('BUG-27 Apple only on iOS, another Apple ID on this iPhone', () {
      setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
      tearDown(() => debugDefaultTargetPlatformOverride = null);

      for (final (name, answer, appleSub)
          in <(String, Object? Function(), String?)>[
            ('notFound', () => 'notFound', null),
            ('revoked', () => 'revoked', null),
            (
              'the channel failing',
              () => throw PlatformException(code: 'x'),
              null,
            ),
            ('no Apple user id', () => 'authorized', ''),
          ]) {
        test('$name: no sheet, the copy, still signed in, nothing more '
            'linked', () async {
          final asked = _mockAppleIdState(answer);
          final user = _FakeUser(
            providers: ['apple.com'],
            linkErrors: ['requires-recent-login'],
            appleSub: appleSub,
          );
          // The sheet would sign this iPhone's Apple ID in: someone else.
          final auth = _FakeAuth(
            user,
            sheetUser: _FakeUser(uid: 'u2', providers: ['apple.com']),
            switchesSession: true,
          );

          expect(
            await errorOf(
              () => _Service(auth).setPassword('secret1', uid: 'u1'),
            ),
            l10n.setPasswordAppleIdMismatch,
          );
          expect(auth.sheetShown, isFalse);
          expect(auth.signedOut, isFalse);
          expect(auth.currentUser?.uid, 'u1', reason: 'still signed in');
          expect(user.linked, hasLength(1), reason: 'only the stale try');
          expect(asked, appleSub == '' ? isEmpty : ['apple-sub-u1']);
        });
      }

      test('a fresh session links without asking iOS', () async {
        final asked = _mockAppleIdState(() => 'notFound');
        final user = _FakeUser(providers: ['apple.com']);

        await _Service(_FakeAuth(user)).setPassword('secret1', uid: 'u1');

        expect(user.linked, hasLength(1));
        expect(asked, isEmpty);
      });
    });

    test('errors → copy', () async {
      Future<String?> messageFor(String code) {
        final user = _FakeUser(providers: ['google.com'], linkErrors: [code]);
        return errorOf(
          () => _Service(_FakeAuth(user)).setPassword('secret1', uid: 'u1'),
        );
      }

      expect(await messageFor('weak-password'), l10n.authWeakPassword);
      expect(
        await messageFor('provider-already-linked'),
        l10n.setPasswordAlreadySet,
      );
      expect(
        await messageFor('email-already-in-use'),
        l10n.setPasswordEmailTaken,
      );
      expect(
        await messageFor('credential-already-in-use'),
        l10n.setPasswordEmailTaken,
      );
      expect(await messageFor('network-request-failed'), l10n.authNetworkError);
      expect(await messageFor('internal-error'), l10n.setPasswordFailed);

      // Google confirmation on another Google account.
      final user = _FakeUser(
        providers: ['google.com'],
        linkErrors: ['requires-recent-login'],
        reauthError: 'user-mismatch',
      );
      expect(
        await errorOf(
          () => _Service(_FakeAuth(user)).setPassword('secret1', uid: 'u1'),
        ),
        l10n.setPasswordWrongGoogleAccount,
      );
    });

    test(
      'already set elsewhere: reloads so the Settings row goes away',
      () async {
        final user = _FakeUser(
          providers: ['apple.com'],
          linkErrors: ['provider-already-linked'],
        );
        await errorOf(
          () => _Service(_FakeAuth(user)).setPassword('secret1', uid: 'u1'),
        );
        expect(user.reloaded, isTrue);
      },
    );
  });

  group('email-verification gate', () {
    bool gated(List<String> providers) => _Service(
      _FakeAuth(_FakeUser(providers: providers, emailVerified: false)),
    ).requiresEmailVerification;

    test('Apple/Google accounts stay out of it after adding a password', () {
      expect(gated(['apple.com', 'password']), isFalse);
      expect(gated(['google.com', 'password']), isFalse);
      expect(gated(['apple.com']), isFalse);
    });

    test('a new unverified password account is still gated', () {
      expect(gated(['password']), isTrue);
    });
  });

  group('AuthProvider.setPassword', () {
    Future<app.AuthProvider> signedIn(_ProviderService service) async {
      final auth = app.AuthProvider(authService: service);
      await auth.initialize();
      return auth;
    }

    test('null on success, onto the account on screen; listeners hear '
        'about it', () async {
      final service = _ProviderService();
      final auth = await signedIn(service);
      var notified = 0;
      auth.addListener(() => notified++);

      expect(await auth.setPassword('secret1'), isNull);
      expect(service.passwords, ['secret1']);
      expect(service.uids, ['u1']);
      expect(notified, greaterThan(0), reason: 'the Settings row rebuilds');
    });

    test('sentinels and copy come back as they are; the signed-out ones '
        'drop the user (BUG-24)', () async {
      for (final message in [
        'social-canceled',
        'apple-id-mismatch',
        'session-gone',
        'msg',
      ]) {
        final auth = await signedIn(
          _ProviderService(error: AuthException(message)),
        );
        expect(await auth.setPassword('secret1'), message);
        expect(
          auth.isAuthenticated,
          message == 'social-canceled' || message == 'msg',
          reason: message,
        );
      }
      final crash = await signedIn(_ProviderService(error: StateError('x')));
      expect(await crash.setPassword('secret1'), l10n.setPasswordFailed);
    });

    test('BUG-24 no account on screen: session-gone, nothing set', () async {
      final service = _ProviderService();
      final auth = app.AuthProvider(authService: service);

      expect(await auth.setPassword('secret1'), 'session-gone');
      expect(service.passwords, isEmpty);
    });
  });
}

/// Firebase-mode [AuthService]; the Google picker returns an ID token or
/// throws [pickError].
class _Service extends AuthService {
  _Service(FirebaseAuth auth, {this.pickError}) : super(firebaseAuth: auth);

  final Object? pickError;

  @override
  bool get isUsingFirebase => true;

  @override
  Future<String?> googleIdToken() async {
    if (pickError case final error?) {
      throw error;
    }
    return 'google-id-token';
  }

  @override
  Future<void> deleteMessagingToken() async {}
}

/// Signed in as [current]. The Apple sheet returns [sheetUser] (default: the
/// same account) or throws [sheetError] — signing [sheetUser] in first when
/// [switchesSession], as the plugin does. [signOutError]: iOS keychain-error,
/// the sign-out throws and the session stays.
class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(
    _FakeUser this.current, {
    _FakeUser? sheetUser,
    this.sheetError,
    this.switchesSession = false,
    this.signOutError,
  }) : sheetUser = sheetUser ?? current;

  _FakeUser? current;
  final _FakeUser sheetUser;
  final FirebaseAuthException? sheetError;
  final bool switchesSession;
  final FirebaseAuthException? signOutError;
  bool sheetShown = false;
  bool signedOut = false;

  @override
  User? get currentUser => current;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    sheetShown = true;
    if (switchesSession) {
      current = sheetUser;
    }
    if (sheetError case final error?) {
      throw error;
    }
    return _FakeCredential(sheetUser);
  }

  @override
  Future<void> revokeTokenWithAuthorizationCode(String code) async {}

  @override
  Future<void> signOut() async {
    signedOut = true;
    if (signOutError case final error?) {
      throw error;
    }
  }
}

/// [linkErrors]: codes thrown by successive `linkWithCredential` calls, then
/// success. [appleSub]: the Apple user id (default `apple-sub-<uid>`).
/// [onReauth] runs inside `reauthenticateWithCredential`.
class _FakeUser extends Fake implements User {
  _FakeUser({
    this.uid = 'u1',
    required this.providers,
    this.email = 'xyz@privaterelay.appleid.com',
    this.emailVerified = true,
    List<String> linkErrors = const [],
    this.reauthError,
    this.appleSub,
    this.onReauth,
  }) : _linkErrors = [...linkErrors];

  @override
  final String uid;

  @override
  final String? email;

  @override
  final bool emailVerified;

  final List<String> providers;
  final List<String> _linkErrors;
  final String? reauthError;
  final String? appleSub;
  final void Function()? onReauth;
  final linked = <AuthCredential>[];
  final reauthenticated = <AuthCredential>[];
  bool reloaded = false;

  @override
  List<UserInfo> get providerData => [
    for (final id in providers)
      _Info(id, id == 'apple.com' ? appleSub ?? 'apple-sub-$uid' : 'sub-$uid'),
  ];

  @override
  UserMetadata get metadata => _Metadata();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    linked.add(credential);
    if (_linkErrors.isNotEmpty) {
      throw FirebaseAuthException(code: _linkErrors.removeAt(0));
    }
    return _FakeCredential(this);
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    reauthenticated.add(credential);
    onReauth?.call();
    if (reauthError case final code?) {
      throw FirebaseAuthException(code: code);
    }
    return _FakeCredential(this);
  }

  @override
  Future<void> reload() async => reloaded = true;
}

/// Created after the email-verification cutoff.
class _Metadata extends Fake implements UserMetadata {
  @override
  DateTime? get creationTime => DateTime.utc(2026, 10, 1);
}

class _Info extends Fake implements UserInfo {
  _Info(this.providerId, this.uid);

  @override
  final String providerId;

  @override
  final String uid;
}

/// iOS's credential state for the account's Apple user id: [answer]'s
/// value, or what it throws. Returns the user ids asked, in order.
List<String> _mockAppleIdState(Object? Function() answer) {
  const channel = MethodChannel('dear_embeiu/apple_id');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final asked = <String>[];
  messenger.setMockMethodCallHandler(channel, (call) async {
    expect(call.method, 'credentialState');
    asked.add((call.arguments as Map)['userId'] as String);
    return answer();
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  return asked;
}

class _FakeCredential extends Fake implements UserCredential {
  _FakeCredential(this.user);

  @override
  final User? user;

  @override
  AdditionalUserInfo? get additionalUserInfo => null;
}

/// Provider-level fake: signed in as `u1`; records the password and the
/// account it went to, or throws [error].
class _ProviderService extends AuthService {
  _ProviderService({this.error});

  final Object? error;
  final passwords = <String>[];
  final uids = <String>[];

  @override
  Future<AppUser?> getCurrentUser() async => AppUser(
    id: 'u1',
    email: 'xyz@privaterelay.appleid.com',
    displayName: 'A',
    inviteCode: 'ABC123',
    status: 'single',
    createdAt: DateTime(2026, 10, 12),
    updatedAt: DateTime(2026, 10, 12),
  );

  @override
  Future<void> setPassword(String password, {required String uid}) async {
    passwords.add(password);
    uids.add(uid);
    if (error case final e?) {
      throw e;
    }
  }
}
