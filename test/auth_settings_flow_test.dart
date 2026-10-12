import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/app/app_routes.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/screens/settings_screen.dart';
import 'package:dear_embeiu/services/auth_service.dart';

const _relay = 'xyz@privaterelay.appleid.com';

/// Signed in with Apple, no couple yet: the reduced Settings.
class _Auth extends AuthProvider {
  _Auth() : super(authService: AuthService());

  bool canSet = true;
  bool loading = false;
  bool apple = true;

  /// What [setPassword] answers next; null = success.
  String? setResult;
  final passwords = <String>[];

  /// Runs inside [deleteAccount] / [reauthenticateAndDeleteAccount].
  Future<String?> Function()? onDelete;
  Future<String?> Function()? onReauthDelete;

  @override
  AppUser? get currentUser => AppUser(
    id: 'me',
    email: _relay,
    displayName: 'Reviewer',
    inviteCode: 'ABC123',
    status: 'single',
    createdAt: DateTime(2026, 10, 12),
    updatedAt: DateTime(2026, 10, 12),
  );

  @override
  String? get currentEmail => _relay;

  @override
  bool get canSetPassword => canSet;

  @override
  bool get reauthWithApple => apple;

  /// BUG-25: what iOS says right before the delete dialog; null = [apple].
  bool? appleSheet;

  /// BUG-26: iOS slow to answer — completes the ask when set.
  Completer<bool>? slowAnswer;
  var asks = 0;

  /// The `appleSheet` every [deleteAccount] got, in order.
  final deleteSheets = <bool>[];

  @override
  Future<bool> deletesWithAppleSheet() async {
    asks++;
    return slowAnswer?.future ?? appleSheet ?? apple;
  }

  @override
  bool get isLoading => loading;

  void setLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  @override
  Future<String?> setPassword(String password) async {
    passwords.add(password);
    final result = setResult;
    if (result == null) {
      canSet = false;
    }
    notifyListeners();
    return result;
  }

  @override
  Future<String?> deleteAccount({required bool appleSheet}) {
    deleteSheets.add(appleSheet);
    return onDelete!();
  }

  @override
  Future<String?> reauthenticateAndDeleteAccount(String password) =>
      onReauthDelete!();
}

/// Settings pushed over a base screen (so Back has somewhere to go).
Widget _app(_Auth auth, GlobalKey<NavigatorState> navigator) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider(create: (_) => CoupleProvider()),
    ],
    child: MaterialApp(
      navigatorKey: navigator,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        AppRoutes.authGate: (_) => const Scaffold(body: Text('gate')),
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            child: const Text('base'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('base'));
  await tester.pumpAndSettle();
}

/// Lets a pop transition run to its end while a spinner keeps animating
/// (pumpAndSettle would never settle).
Future<void> _pumpThrough(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  group('AU1 set a password', () {
    Future<void> openDialog(WidgetTester tester, _Auth auth) async {
      await tester.pumpWidget(_app(auth, GlobalKey<NavigatorState>()));
      await _openSettings(tester);
      await tester.tap(find.text(l10n.setPasswordTitle));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      // Says which email signs in, and that Apple may ask first.
      expect(find.text(l10n.setPasswordBody(_relay)), findsOneWidget);
      expect(find.text(l10n.setPasswordConfirmNote('Apple')), findsOneWidget);
    }

    Future<void> submit(WidgetTester tester, String first, String second) async {
      await tester.enterText(find.byType(TextFormField).at(0), first);
      await tester.enterText(find.byType(TextFormField).at(1), second);
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
    }

    testWidgets('sign-up rules, then the email in a SnackBar with Copy, and '
        'the row goes away', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      final auth = _Auth();
      await openDialog(tester, auth);

      await submit(tester, '12345', '12345');
      expect(find.text(l10n.passwordTooShort), findsOneWidget);
      await submit(tester, 'secret1', 'secret2');
      expect(find.text(l10n.passwordsMismatch), findsOneWidget);
      expect(auth.passwords, isEmpty);

      await submit(tester, 'secret1', 'secret1');
      expect(auth.passwords, ['secret1']);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(l10n.setPasswordDone(_relay)), findsOneWidget);
      expect(find.text(l10n.setPasswordTitle), findsNothing);

      await tester.tap(find.text(l10n.copyBtn));
      await tester.pump();
      expect(copied, _relay);
    });

    testWidgets('closing the Apple sheet keeps the dialog, quietly', (
      tester,
    ) async {
      final auth = _Auth()..setResult = 'social-canceled';
      await openDialog(tester, auth);

      await submit(tester, 'secret1', 'secret1');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('social-canceled'), findsNothing, reason: 'sentinel');
      // Ready for another try.
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, l10n.save))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('errors show in the dialog: weak password under its field', (
      tester,
    ) async {
      final auth = _Auth()..setResult = l10n.authWeakPassword;
      await openDialog(tester, auth);

      Finder inPasswordField(String text) => find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.text(text),
      );

      await submit(tester, 'secret1', 'secret1');
      expect(inPasswordField(l10n.authWeakPassword), findsOneWidget);

      auth.setResult = l10n.setPasswordEmailTaken;
      await submit(tester, 'secret1', 'secret1');
      expect(find.text(l10n.setPasswordEmailTaken), findsOneWidget);
      expect(inPasswordField(l10n.setPasswordEmailTaken), findsNothing);
      expect(find.text(l10n.authWeakPassword), findsNothing);
    });

    testWidgets('another Apple ID in the sheet: signed out, to authGate', (
      tester,
    ) async {
      final auth = _Auth()..setResult = 'apple-id-mismatch';
      await openDialog(tester, auth);

      await submit(tester, 'secret1', 'secret1');
      expect(find.text('gate'), findsOneWidget);
      expect(find.text(l10n.setPasswordAppleIdMismatch), findsOneWidget);
    });

    testWidgets('no row for an account that already has a password', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_Auth()..canSet = false, GlobalKey<NavigatorState>()),
      );
      await _openSettings(tester);
      expect(find.text(l10n.setPasswordTitle), findsNothing);
    });
  });

  group('AU2 deleting can not be backed out of', () {
    testWidgets('system back is ignored while an auth op runs', (
      tester,
    ) async {
      final auth = _Auth();
      await tester.pumpWidget(_app(auth, GlobalKey<NavigatorState>()));
      await _openSettings(tester);

      auth.setLoading(true);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await _pumpThrough(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);

      auth.setLoading(false);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets('deleted while Settings is gone: still sent to authGate', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      final deleted = Completer<String?>();
      final auth = _Auth()
        ..onDelete = () {
          // What an edge swipe did before the lock: Settings leaves while the
          // server is still deleting.
          navigator.currentState!.pop();
          return deleted.future;
        };
      await tester.pumpWidget(_app(auth, navigator));
      await _openSettings(tester);

      final delete = find.text(l10n.deleteAccountBtn);
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);

      deleted.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('gate'), findsOneWidget);
      expect(find.text('base'), findsNothing);
    });

    for (final sheet in [true, false]) {
      testWidgets('BUG-25 Apple + password, ${sheet ? 'its' : 'another'} '
          'Apple ID on the iPhone: ${sheet ? 'the Apple note' : 'no Apple '
          'note, the re-auth asks for the password'}', (tester) async {
        final auth = _Auth()
          ..appleSheet = sheet
          ..onDelete = (() async => 'requires-recent-login');
        await tester.pumpWidget(_app(auth, GlobalKey<NavigatorState>()));
        await _openSettings(tester);

        final delete = find.text(l10n.deleteAccountBtn);
        await tester.ensureVisible(delete);
        await tester.tap(delete);
        await tester.pumpAndSettle();
        expect(find.text(l10n.deleteAccountDialogTitle), findsOneWidget);
        expect(
          find.text(l10n.deleteAccountAppleNote),
          sheet ? findsOneWidget : findsNothing,
        );

        await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
        await tester.pumpAndSettle();
        expect(find.text(l10n.deleteAccountReauthTitle), findsOneWidget);
        expect(
          find.byType(TextFormField),
          sheet ? findsNothing : findsOneWidget,
        );
        // BUG-26: the deletion got the dialog's answer, iOS asked once.
        expect(auth.deleteSheets, [sheet]);
        if (sheet) {
          // The re-auth retry keeps that answer: the sheet again.
          await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
          await tester.pumpAndSettle();
          expect(auth.deleteSheets, [true, true]);
        }
        expect(auth.asks, 1);
      });
    }

    testWidgets('BUG-26 iOS slow to answer: Delete spins and ignores a second '
        'tap — one dialog, one deletion, on that answer', (tester) async {
      final deleted = Completer<String?>();
      final auth = _Auth()
        ..slowAnswer = Completer<bool>()
        ..onDelete = (() => deleted.future);
      await tester.pumpWidget(_app(auth, GlobalKey<NavigatorState>()));
      await _openSettings(tester);

      final delete = find.text(l10n.deleteAccountBtn);
      await tester.ensureVisible(delete);
      // Two taps in one frame: the button hasn't rebuilt disabled yet.
      await tester.tap(delete);
      await tester.tap(delete);
      expect(auth.asks, 1);
      await tester.pump();
      final button = find.ancestor(
        of: delete,
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(
        find.descendant(
          of: button,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(delete, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 800));
      expect(auth.asks, 1);
      expect(find.byType(AlertDialog), findsNothing);

      auth.slowAnswer!.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(l10n.deleteAccountAppleNote), findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

      await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
      await tester.pump();
      expect(auth.deleteSheets, [true]);
      deleted.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('gate'), findsOneWidget);
    });

    testWidgets('BUG-26 a deletion already running: this confirm says '
        'nothing, stays put', (tester) async {
      final auth = _Auth()..onDelete = (() async => 'delete-in-progress');
      await tester.pumpWidget(_app(auth, GlobalKey<NavigatorState>()));
      await _openSettings(tester);

      final delete = find.text(l10n.deleteAccountBtn);
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('re-auth dialog: back ignored mid-delete, then authGate', (
      tester,
    ) async {
      final release = Completer<String?>();
      final auth = _Auth()
        ..apple = false
        ..onDelete = (() async => 'requires-recent-login')
        ..onReauthDelete = (() => release.future);
      await tester.pumpWidget(_app(auth, GlobalKey<NavigatorState>()));
      await _openSettings(tester);

      final delete = find.text(l10n.deleteAccountBtn);
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
      await tester.pumpAndSettle();
      expect(find.text(l10n.deleteAccountReauthTitle), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'secret1');
      await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await _pumpThrough(tester);
      expect(find.text(l10n.deleteAccountReauthTitle), findsOneWidget);

      release.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('gate'), findsOneWidget);
    });
  });
}
