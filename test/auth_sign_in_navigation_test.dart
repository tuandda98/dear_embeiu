import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/app/app_routes.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/locale_provider.dart';
import 'package:dear_embeiu/screens/login_screen.dart';
import 'package:dear_embeiu/screens/register_screen.dart';
import 'package:dear_embeiu/services/auth_service.dart';

/// Audit 2026-10-12 AU4: Firebase can take 1–3 s after the Apple sheet /
/// Google picker / the email form. Going back meanwhile used to leave a live,
/// session-minted user on the landing screen — the result must still go
/// through authGate.
class _Auth extends AuthProvider {
  _Auth({this.firebase = false}) : super(authService: AuthService());

  final bool firebase;
  final release = Completer<bool>();

  @override
  bool get isUsingFirebase => firebase;

  @override
  Future<bool> signIn({required String email, required String password}) =>
      release.future;

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) => release.future;

  @override
  Future<bool> signInWithSocial(SocialSignIn provider) => release.future;
}

Widget _app(_Auth auth) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ],
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.authGate: (_) => const Scaffold(body: Text('gate')),
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                child: const Text('to login'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.register),
                child: const Text('to register'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

/// Back while the sign-in is still running, then it succeeds.
Future<void> _backThenSucceed(WidgetTester tester, _Auth auth) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.text('to login'), findsOneWidget, reason: 'back on the landing');

  auth.release.complete(true);
  await tester.pumpAndSettle();
  expect(find.text('gate'), findsOneWidget);
  expect(find.text('to login'), findsNothing);
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  testWidgets('email sign-in lands after going back: still to authGate', (
    tester,
  ) async {
    final auth = _Auth();
    await tester.pumpWidget(_app(auth));
    await tester.tap(find.text('to login'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await _tap(tester, find.widgetWithText(FilledButton, l10n.signIn));

    await _backThenSucceed(tester, auth);
  });

  testWidgets('Google sign-in lands after going back: still to authGate', (
    tester,
  ) async {
    // Tests run as Android: the Google button shows once Firebase is up.
    final auth = _Auth(firebase: true);
    await tester.pumpWidget(_app(auth));
    await tester.tap(find.text('to login'));
    await tester.pumpAndSettle();

    await _tap(tester, find.text(l10n.continueWithGoogle));
    await _backThenSucceed(tester, auth);
  });

  testWidgets('sign-up lands after going back: still leaves the flow', (
    tester,
  ) async {
    final auth = _Auth();
    await tester.pumpWidget(_app(auth));
    await tester.tap(find.text('to register'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Bé Iu');
    await tester.enterText(fields.at(1), 'a@b.com');
    await tester.enterText(fields.at(2), 'secret1');
    await tester.enterText(fields.at(3), 'secret1');
    await _tap(tester, find.byType(Checkbox));
    await _tap(tester, find.widgetWithText(FilledButton, l10n.createAccountBtn));

    await _backThenSucceed(tester, auth);
  });
}
