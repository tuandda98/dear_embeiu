import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart' as app;
import 'package:dear_embeiu/services/auth_service.dart';

/// Pairing-funnel Tester round 1. BUG-1: the Apple delete confirmation signs
/// in again (never `reauthenticateWithProvider` — the fake user throws if it
/// is called) and refuses another Apple ID without deleting anything of the
/// account. BUG-6: its errors talk about deleting, not signing in. PF18: on
/// another Apple ID it removes the user the sheet just created (never an
/// existing one), drops the FCM token, signs out, says `apple-id-mismatch`.
/// Round 3: BUG-9 revokes that new user's Apple grant before deleting it;
/// Apple + Google linked re-authenticates with Google on Android; a failed
/// token refresh is only logged. Audit 2026-10-12: AU3 an Apple account with a
/// password still goes through the sheet on iOS, a linked Google grant is
/// dropped after the delete; AU6 a sheet that can't run doesn't block it.
/// BUG-24: the delete callable never runs on a session that isn't the
/// account's (the sheet switched it, and signing that one out failed).
/// BUG-25: Apple + password goes through the sheet only when iOS says the
/// iPhone's Apple ID is the account's. BUG-26: iOS is asked once, for the
/// delete dialog; the deletion gets that answer and never asks again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'same Apple ID: revoke with the fresh code, refresh the token',
    () async {
      final auth = _FakeAuth(signInUser: _FakeUser('u1'));
      final service = _FirebaseAuthService(auth);

      await service.confirmAppleDeletionIfNeeded(appleSheet: true);

      expect(auth.revokedCode, 'fresh-code');
      expect(auth.signInUser!.tokenRefreshed, isTrue);
      expect(auth.signedOut, isFalse);
      expect(service.messagingTokenDeleted, isFalse);
    },
  );

  Future<String> mismatch(_FakeAuth auth, _FirebaseAuthService service) async {
    try {
      await service.confirmAppleDeletionIfNeeded(appleSheet: true);
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

  test(
    'a failed revoke, orphan delete or token drop still signs out',
    () async {
      final auth = _FakeAuth(
        signInUser: _FakeUser('u2', deleteFails: true),
        isNewUser: true,
        revokeFails: true,
      );
      final service = _FirebaseAuthService(auth, tokenDeleteFails: true);

      expect(await mismatch(auth, service), 'apple-id-mismatch');
      expect(auth.signedOut, isTrue);
    },
  );

  test('a failed token refresh is only logged: the callable decides', () async {
    final auth = _FakeAuth(signInUser: _FakeUser('u1', tokenFails: true));

    await _FirebaseAuthService(
      auth,
    ).confirmAppleDeletionIfNeeded(appleSheet: true);

    expect(auth.revokedCode, 'fresh-code');
  });

  test(
    'Apple + Google linked: the Apple sheet on iOS, Google on Android',
    () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      _FakeAuth linked() => _FakeAuth(
        signInUser: _FakeUser('u1'),
        current: _FakeUser('u1', providers: const ['apple.com', 'google.com']),
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = linked();
      final onAndroid = _FirebaseAuthService(android);
      // Even told "the sheet", Android has none to show.
      await onAndroid.confirmAppleDeletionIfNeeded(appleSheet: true);
      expect(android.sheetShown, isFalse);
      expect(onAndroid.reauthWithGoogle, isTrue);
      expect(onAndroid.reauthWithApple, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ios = linked();
      final onIos = _FirebaseAuthService(ios);
      await onIos.confirmAppleDeletionIfNeeded(appleSheet: true);
      expect(ios.sheetShown, isTrue);
      expect(onIos.reauthWithApple, isTrue);
      expect(onIos.reauthWithGoogle, isFalse);
    },
  );

  test(
    'AU3 Apple + password: the sheet and its revocation on iOS when the '
    "account's Apple ID is signed in there, the password on Android",
    () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final asked = _mockAppleIdState(() => 'authorized');
      _FakeAuth withPassword() => _FakeAuth(
        signInUser: _FakeUser('u1'),
        current: _FakeUser('u1', providers: const ['apple.com', 'password']),
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ios = withPassword();
      final onIos = _FirebaseAuthService(ios);
      expect(onIos.reauthWithApple, isTrue);
      expect(await onIos.passwordInsteadOfAppleSheet(), isFalse);
      await onIos.confirmAppleDeletionIfNeeded(appleSheet: true);
      expect(ios.sheetShown, isTrue);
      expect(ios.revokedCode, 'fresh-code');
      // The account's Apple user id (providerData → apple.com → uid), once:
      // the deletion goes by the dialog's answer (BUG-26).
      expect(asked, ['apple-sub-u1']);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      asked.clear();
      final android = withPassword();
      final onAndroid = _FirebaseAuthService(android);
      expect(await onAndroid.passwordInsteadOfAppleSheet(), isFalse);
      await onAndroid.confirmAppleDeletionIfNeeded(appleSheet: true);
      expect(android.sheetShown, isFalse);
      expect(onAndroid.reauthWithApple, isFalse);
      expect(onAndroid.reauthWithGoogle, isFalse, reason: 'password dialog');
      expect(asked, isEmpty, reason: 'Android never asks iOS');
    },
  );

  group('BUG-25 Apple + password on iOS, another Apple ID on the iPhone', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    // The sheet would sign this iPhone's Apple ID in: someone else.
    _FakeAuth withPassword({String? appleSub}) => _FakeAuth(
      signInUser: _FakeUser('u2'),
      switchesSession: true,
      current: _FakeUser(
        'u1',
        providers: const ['apple.com', 'password'],
        appleSub: appleSub,
      ),
    );

    for (final (name, answer) in <(String, Object? Function())>[
      ('notFound', () => 'notFound'),
      ('revoked', () => 'revoked'),
      ('the channel failing', () => throw PlatformException(code: 'x')),
    ]) {
      test('$name: no sheet, nothing revoked, the deletion goes on', () async {
        final asked = _mockAppleIdState(answer);
        final auth = withPassword();
        final service = _FirebaseAuthService(auth);

        expect(await service.passwordInsteadOfAppleSheet(), isTrue);
        await service.confirmAppleDeletionIfNeeded(appleSheet: false);
        expect(auth.sheetShown, isFalse);
        expect(auth.revokedCode, isNull);
        expect(auth.currentUser?.uid, 'u1', reason: 'still signed in');
        expect(asked, ['apple-sub-u1']);
      });
    }

    test('no channel at all: the password too', () async {
      expect(
        await _FirebaseAuthService(
          withPassword(),
        ).passwordInsteadOfAppleSheet(),
        isTrue,
      );
    });

    test('iOS never answers: the password once its 2 seconds are up', () async {
      _mockAppleIdState(() => Completer<String>().future);
      final service = _FirebaseAuthService(withPassword());

      // Without the cap this never ends: the test times out instead.
      expect(
        await service.passwordInsteadOfAppleSheet().timeout(
          const Duration(seconds: 5),
        ),
        isTrue,
      );
    });

    test(
      'no Apple user id on the account: the password, iOS never asked',
      () async {
        final asked = _mockAppleIdState(() => 'authorized');
        final service = _FirebaseAuthService(withPassword(appleSub: ''));

        expect(await service.passwordInsteadOfAppleSheet(), isTrue);
        expect(asked, isEmpty);
      },
    );

    test('through the provider: the dialog skips the Apple note, the '
        'account is deleted (it was signed out instead before)', () async {
      final asked = _mockAppleIdState(() => 'notFound');
      final auth = withPassword();
      final service = _FirebaseAuthService(auth);
      final provider = app.AuthProvider(authService: service);
      await provider.initialize();

      expect(provider.reauthWithApple, isTrue, reason: 'Apple is linked');
      final sheet = await provider.deletesWithAppleSheet();
      expect(sheet, isFalse);
      expect(await provider.deleteAccount(appleSheet: sheet), isNull);
      expect(service.events, ['delete', 'wipe']);
      expect(auth.sheetShown, isFalse);
      expect(asked, hasLength(1));
    });

    for (final first in ['authorized', 'notFound']) {
      test('BUG-26 iOS answers $first for the dialog, then otherwise: the '
          'deletion keeps to the first answer, iOS asked once', () async {
        // The second answer used to decide: "Apple will ask" and no sheet,
        // or the other way round. 'authorized' then never answers again.
        final asked = <String>[];
        _mockAppleIdState(() {
          asked.add('ask');
          if (asked.length == 1) {
            return first;
          }
          return first == 'authorized'
              ? Completer<String>().future
              : 'authorized';
        });
        final auth = _FakeAuth(
          signInUser: _FakeUser('u1'),
          current: _FakeUser('u1', providers: const ['apple.com', 'password']),
        );
        final service = _FirebaseAuthService(auth);
        final provider = app.AuthProvider(authService: service);
        await provider.initialize();

        final sheet = await provider.deletesWithAppleSheet();
        expect(sheet, first == 'authorized');
        expect(await provider.deleteAccount(appleSheet: sheet), isNull);
        expect(auth.sheetShown, sheet);
        expect(auth.revokedCode, sheet ? 'fresh-code' : isNull);
        expect(service.events, ['delete', 'wipe']);
        expect(asked, hasLength(1));
      });
    }

    test(
      'Apple only: iOS is never asked, the sheet as before (PF18)',
      () async {
        final asked = _mockAppleIdState(() => 'notFound');
        final auth = _FakeAuth(signInUser: _FakeUser('u1'));
        final service = _FirebaseAuthService(auth);

        expect(await service.passwordInsteadOfAppleSheet(), isFalse);
        await service.confirmAppleDeletionIfNeeded(appleSheet: true);
        expect(auth.sheetShown, isTrue);
        expect(asked, isEmpty);
      },
    );
  });

  group('BUG-24 the delete callable only runs on the account itself', () {
    test('another Apple ID whose sign-out fails (iOS keychain-error): '
        'apple-id-mismatch all the same, nothing deleted', () async {
      final auth = _FakeAuth(
        signInUser: _FakeUser('u2'),
        switchesSession: true,
        signOutError: FirebaseAuthException(code: 'keychain-error'),
      );
      final service = _FirebaseAuthService(auth);
      final provider = app.AuthProvider(authService: service);
      await provider.initialize();

      expect(
        await provider.deleteAccount(appleSheet: true),
        'apple-id-mismatch',
      );
      expect(service.events, isEmpty, reason: 'no callable, no wipe');
      expect(auth.currentUser?.uid, 'u2', reason: 'the sign-out did fail');
      expect(provider.isAuthenticated, isFalse, reason: 'not routed back in');
    });

    test('a sheet error after it switched the session: session-gone, AU6 '
        'only goes on for the account itself', () async {
      final me = _FakeUser('u1');
      final auth = _FakeAuth(
        current: me,
        signInUser: _FakeUser('u2'),
        switchesSession: true,
        error: FirebaseAuthException(code: 'unknown'),
      );
      final service = _FirebaseAuthService(auth);

      expect(
        await _messageOf(
          () => service.confirmAppleDeletionIfNeeded(appleSheet: true),
        ),
        'session-gone',
      );
      expect(me.tokenRefreshed, isFalse);
      expect(auth.signedOut, isTrue);
      expect(service.messagingTokenDeleted, isTrue);
    });

    test('deleteAccount on another session: never calls', () async {
      final service = _FirebaseAuthService(_FakeAuth(current: _FakeUser('u2')));

      expect(
        await _messageOf(() => service.deleteAccount(currentUser: _appUser)),
        'session-gone',
      );
      expect(service.events, isEmpty);
    });

    test(
      'the session switching during the token refresh: never calls',
      () async {
        late final _FakeAuth auth;
        auth = _FakeAuth(
          current: _FakeUser(
            'u1',
            providers: const ['google.com'],
            onTokenRefresh: () => auth._current = _FakeUser('u2'),
          ),
        );
        final service = _FirebaseAuthService(auth);

        expect(
          await _messageOf(() => service.deleteAccount(currentUser: _appUser)),
          'session-gone',
        );
        expect(service.events, isEmpty);
      },
    );
  });

  group('AU3 deleteAccount: a linked Google grant goes after the delete', () {
    Future<_FirebaseAuthService> delete(
      List<String> providers, {
      Object? callableError,
    }) async {
      final service = _FirebaseAuthService(
        _FakeAuth(current: _FakeUser('u1', providers: providers)),
        callableError: callableError,
      );
      try {
        await service.deleteAccount(currentUser: _appUser);
      } on AuthException {
        // Read through `events`.
      }
      return service;
    }

    test('Google + password: delete, then disconnect', () async {
      final service = await delete(['google.com', 'password']);
      expect(service.events, ['delete', 'disconnect']);
    });

    test('Google only: fresh token, delete, then disconnect', () async {
      final service = await delete(['google.com']);
      expect(service.events, ['delete', 'disconnect']);
      expect((service.auth.currentUser! as _FakeUser).tokenRefreshed, isTrue);
    });

    test('Apple + password: nothing to disconnect', () async {
      final service = await delete(['apple.com', 'password']);
      expect(service.events, ['delete']);
    });

    test('a failed delete keeps the Google grant', () async {
      final service = await delete(
        ['google.com', 'password'],
        callableError: FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'Unauthenticated',
        ),
      );
      expect(service.events, ['delete']);
    });
  });

  test('errors: cancel stays silent, network stops; any other sheet error '
      'skips the revocation and lets the deletion go on (AU6)', () async {
    // Null = no error: the caller goes on to delete.
    Future<String?> messageFor(String code) async {
      final auth = _FakeAuth(error: FirebaseAuthException(code: code));
      try {
        await _FirebaseAuthService(
          auth,
        ).confirmAppleDeletionIfNeeded(appleSheet: true);
      } on AuthException catch (e) {
        return e.message;
      }
      expect(auth.revokedCode, isNull, reason: code);
      expect(auth._current!.tokenRefreshed, isTrue, reason: code);
      return null;
    }

    final l10n = AppL10n.strings;
    expect(await messageFor('canceled'), 'social-canceled');
    expect(await messageFor('web-context-canceled'), 'social-canceled');
    expect(await messageFor('network-request-failed'), l10n.authNetworkError);
    // `unknown` = no Apple ID signed in on the iPhone.
    for (final code in [
      'unknown',
      'failed',
      'not-handled',
      'invalid-response',
      'invalid-credential',
    ]) {
      expect(await messageFor(code), isNull, reason: code);
    }
  });
}

/// The [AuthException] message [run] throws; null when it completes.
Future<String?> _messageOf(Future<void> Function() run) async {
  try {
    await run();
  } on AuthException catch (e) {
    return e.message;
  }
  return null;
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

final _appUser = AppUser(
  id: 'u1',
  email: 'a@b.com',
  displayName: 'A',
  inviteCode: 'ABC123',
  status: 'single',
  createdAt: DateTime(2026, 10, 12),
  updatedAt: DateTime(2026, 10, 12),
);

class _FirebaseAuthService extends AuthService {
  _FirebaseAuthService(
    this.auth, {
    this.tokenDeleteFails = false,
    this.callableError,
  }) : super(firebaseAuth: auth);

  final FirebaseAuth auth;
  final bool tokenDeleteFails;
  final Object? callableError;
  bool messagingTokenDeleted = false;

  /// The delete callable, the Google disconnect and the local wipe, in call
  /// order.
  final events = <String>[];

  @override
  bool get isUsingFirebase => true;

  // Signed in as [_appUser] for the AuthProvider tests.
  @override
  Future<AppUser?> getCurrentUser() async => _appUser;

  @override
  Future<String> mintSessionToken(String uid) async => 'session';

  @override
  Stream<String?> watchSessionToken(String uid) => const Stream.empty();

  @override
  Stream<bool> sessionActiveChanges() => const Stream.empty();

  @override
  Future<void> deleteMessagingToken() async {
    messagingTokenDeleted = true;
    if (tokenDeleteFails) {
      throw Exception('no FCM');
    }
  }

  @override
  Future<void> callDeleteAccount() async {
    events.add('delete');
    if (callableError case final error?) {
      throw error;
    }
  }

  @override
  Future<void> disconnectGoogle() async => events.add('disconnect');

  @override
  Future<void> wipeLocalUserData(String uid) async => events.add('wipe');
}

/// Signed in as [current] (default: Apple-only `u1`); the Apple sheet returns
/// [signInUser] (a brand-new Firebase user when [isNewUser]) or throws
/// [error] — signing [signInUser] in first when [switchesSession], as the
/// plugin does before it answers.
class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth({
    this.signInUser,
    this.error,
    this.isNewUser = false,
    this.revokeFails = false,
    this.switchesSession = false,
    this.signOutError,
    _FakeUser? current,
  }) : _current = current ?? _FakeUser('u1');

  final _FakeUser? signInUser;
  final FirebaseAuthException? error;
  final bool isNewUser;
  final bool revokeFails;
  final bool switchesSession;

  /// iOS keychain-error: the sign-out throws and the session stays.
  final FirebaseAuthException? signOutError;
  _FakeUser? _current;
  bool sheetShown = false;
  String? revokedCode;
  bool revokedAfterDelete = false;
  bool signedOut = false;

  @override
  User? get currentUser => _current;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    sheetShown = true;
    if (switchesSession) {
      _current = signInUser;
    }
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
    if (signOutError case final error?) {
      throw error;
    }
  }
}

/// [appleSub]: the Apple user id on `apple.com` (default `apple-sub-<uid>`).
class _FakeUser extends Fake implements User {
  _FakeUser(
    this.uid, {
    this.deleteFails = false,
    this.tokenFails = false,
    this.providers = const ['apple.com'],
    this.onTokenRefresh,
    this.appleSub,
  });

  @override
  final String uid;

  final bool deleteFails;
  final bool tokenFails;
  final List<String> providers;
  final void Function()? onTokenRefresh;
  final String? appleSub;
  bool tokenRefreshed = false;
  bool deleted = false;

  @override
  List<UserInfo> get providerData => [
    for (final id in providers)
      _Provider(
        id,
        id == 'apple.com' ? appleSub ?? 'apple-sub-$uid' : 'sub-$uid',
      ),
  ];

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (tokenFails) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
    tokenRefreshed = forceRefresh;
    onTokenRefresh?.call();
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
  _Provider(this.providerId, this.uid);

  @override
  final String providerId;

  @override
  final String uid;
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
