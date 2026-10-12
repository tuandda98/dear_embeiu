import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart' as app;
import 'package:dear_embeiu/services/auth_service.dart';

/// Pairing-funnel PF14/PF16: Google sign-in errors, and one cancel sentinel
/// (`social-canceled`) for both the Apple sheet and the Google picker.
void main() {
  final l10n = AppL10n.strings;

  Future<Object> errorOf(Future<Object?> Function() run) async {
    try {
      await run();
    } catch (e) {
      return e;
    }
    fail('expected an error');
  }

  group('cancel sentinel', () {
    test('closing the Google picker → social-canceled', () async {
      final service = _GoogleService(
        pickError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      );

      final e = await errorOf(service.signInWithGoogle);
      expect(e, isA<AuthException>()
          .having((e) => e.message, 'message', 'social-canceled'));
      expect(service.auth.credential, isNull, reason: 'Firebase never called');
    });

    test('closing the Apple sheet → social-canceled', () async {
      final service = _GoogleService(
        firebaseError: FirebaseAuthException(code: 'canceled'),
      );

      final e = await errorOf(service.signInWithApple);
      expect(e, isA<AuthException>()
          .having((e) => e.message, 'message', 'social-canceled'));
    });

    test('provider stays silent on either cancel', () async {
      for (final provider in app.SocialSignIn.values) {
        final auth = app.AuthProvider(
          authService: _ProviderFake(const AuthException('social-canceled')),
        );

        expect(await auth.signInWithSocial(provider), isFalse);
        expect(auth.errorMessage, isNull, reason: provider.name);
        expect(auth.isSocialSigningIn, isFalse);
      }
    });
  });

  group('Google errors', () {
    test('SDK and platform failures → googleSignInFailed', () async {
      for (final error in <Object>[
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.interrupted,
        ),
        PlatformException(code: 'google_sign_in'),
      ]) {
        final e = await errorOf(_GoogleService(pickError: error).signInWithGoogle);
        expect(e, isA<AuthException>()
            .having((e) => e.message, 'message', l10n.googleSignInFailed));
      }
    });

    test('no ID token → googleSignInFailed, Firebase never called', () async {
      final service = _GoogleService(idToken: null);

      final e = await errorOf(service.signInWithGoogle);
      expect(e, isA<AuthException>()
          .having((e) => e.message, 'message', l10n.googleSignInFailed));
      expect(service.auth.credential, isNull);
    });

    test('ID token goes to Firebase; email with a password → PF6', () async {
      final service = _GoogleService(
        firebaseError: FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          email: 'a@b.com',
        ),
      );

      final e = await errorOf(service.signInWithGoogle);
      expect(e, isA<EmailHasPasswordAccountException>()
          .having((e) => e.email, 'email', 'a@b.com')
          .having((e) => e.message, 'message', l10n.appleEmailHasPasswordAccount));
      final credential = service.auth.credential as OAuthCredential;
      expect(credential.providerId, 'google.com');
      expect(credential.idToken, 'google-id-token');
    });

    test('Firebase errors: network → authNetworkError, else googleSignInFailed',
        () async {
      Future<String> messageFor(String code) async {
        final service = _GoogleService(
          firebaseError: FirebaseAuthException(code: code),
        );
        final e = await errorOf(service.signInWithGoogle);
        return (e as AuthException).message;
      }

      expect(await messageFor('network-request-failed'), l10n.authNetworkError);
      expect(await messageFor('invalid-credential'), l10n.googleSignInFailed);
    });
  });

  test('only the running provider is busy; cleared when it ends', () async {
    final gate = Completer<void>();
    final auth = app.AuthProvider(
      authService: _ProviderFake(
        const AuthException('social-canceled'),
        gate: gate.future,
      ),
    );

    final pending = auth.signInWithSocial(app.SocialSignIn.google);
    expect(auth.socialSignIn, app.SocialSignIn.google);
    expect(auth.isSocialSigningIn, isTrue);
    expect(auth.isLoading, isFalse, reason: 'the email button must not spin');

    gate.complete();
    await pending;
    expect(auth.socialSignIn, isNull);
  });

  test('provider: PF6 keeps the conflict email, other errors show copy',
      () async {
    final conflict = app.AuthProvider(
      authService: _ProviderFake(
        const EmailHasPasswordAccountException('pf6', email: 'a@b.com'),
      ),
    );
    expect(await conflict.signInWithSocial(app.SocialSignIn.google), isFalse);
    expect(conflict.emailConflict?.email, 'a@b.com');
    expect(conflict.errorMessage, 'pf6');

    final crash = app.AuthProvider(authService: _ProviderFake(StateError('x')));
    expect(await crash.signInWithSocial(app.SocialSignIn.google), isFalse);
    expect(crash.errorMessage, l10n.googleSignInFailed);
    expect(crash.emailConflict, isNull);
  });
}

/// Real [AuthService] in Firebase mode: the Google picker returns [idToken] or
/// throws [pickError]; Firebase sign-in (Apple sheet or Google credential)
/// throws [firebaseError].
class _GoogleService extends AuthService {
  factory _GoogleService({
    Object? pickError,
    String? idToken = 'google-id-token',
    FirebaseAuthException? firebaseError,
  }) => _GoogleService._(_FakeAuth(firebaseError), pickError, idToken);

  _GoogleService._(this.auth, this.pickError, this.idToken)
    : super(firebaseAuth: auth);

  final _FakeAuth auth;
  final Object? pickError;
  final String? idToken;

  @override
  bool get isUsingFirebase => true;

  @override
  Future<String?> googleIdToken() async {
    final e = pickError;
    if (e != null) {
      throw e;
    }
    return idToken;
  }
}

class _FakeAuth extends Fake implements FirebaseAuth {
  _FakeAuth(this.error);

  final FirebaseAuthException? error;
  AuthCredential? credential;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    this.credential = credential;
    throw error ?? FirebaseAuthException(code: 'unexpected');
  }

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) {
    throw error ?? FirebaseAuthException(code: 'unexpected');
  }
}

/// Provider-level fake: both social sign-ins throw [error] (after [gate]).
class _ProviderFake extends AuthService {
  _ProviderFake(this.error, {this.gate});

  final Object error;
  final Future<void>? gate;

  Future<({AppUser user, bool isNewUser})> _fail() async {
    await gate;
    throw error;
  }

  @override
  Future<({AppUser user, bool isNewUser})> signInWithApple() => _fail();

  @override
  Future<({AppUser user, bool isNewUser})> signInWithGoogle() => _fail();
}
