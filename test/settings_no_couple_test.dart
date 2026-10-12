import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/screens/settings_screen.dart';
import 'package:dear_embeiu/services/auth_service.dart';

/// Signed in, no couple yet — where an App Reviewer lands after "Continue
/// with Apple" (Setup → gear → Settings).
class _UnpairedAuth extends AuthProvider {
  _UnpairedAuth() : super(authService: AuthService());

  @override
  AppUser? get currentUser => AppUser(
    id: 'me',
    email: 'reviewer@privaterelay.appleid.com',
    displayName: 'Reviewer',
    inviteCode: 'ABC123',
    status: 'single',
    createdAt: DateTime(2026, 10, 11),
    updatedAt: DateTime(2026, 10, 11),
  );
}

/// BUG-8: the PF18 sheet deletes a brand-new Apple ID, the shell reads that as
/// a revocation and resets to authGate — Settings and its dialogs are gone
/// before [deleteAccount] returns. [firstAsksReauth] goes through the re-auth
/// dialog first.
class _SessionEndsMidDeleteAuth extends _UnpairedAuth {
  _SessionEndsMidDeleteAuth(this.navigator, {required this.firstAsksReauth});

  final GlobalKey<NavigatorState> navigator;
  final bool firstAsksReauth;
  final release = Completer<void>();
  var _calls = 0;

  @override
  bool get isAppleOnlyAccount => true;

  @override
  Future<String?> deleteAccount() async {
    if (firstAsksReauth && _calls++ == 0) {
      return 'requires-recent-login';
    }
    // What the shell does on sessionRevoked.
    navigator.currentState!.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('gate'))),
      (_) => false,
    );
    await release.future;
    return 'apple-id-mismatch';
  }
}

Widget _settingsApp(
  AuthProvider auth, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      // Fresh provider = couple null, as on Setup.
      ChangeNotifierProvider(create: (_) => CoupleProvider()),
    ],
    child: MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  testWidgets('no couple: Settings still offers delete account (5.1.1(v))', (
    tester,
  ) async {
    await tester.pumpWidget(_settingsApp(_UnpairedAuth()));
    await tester.pumpAndSettle();

    expect(find.text('Reviewer'), findsOneWidget); // account card
    expect(find.text('Không thể hoàn tác'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    // Couple-only controls stay hidden.
    expect(find.text('Rời cặp đôi'), findsNothing);
    expect(find.text('Xoá dữ liệu trên máy này'), findsNothing);

    // Same delete flow as the paired danger zone.
    final delete = find.text('Xoá tài khoản');
    expect(delete, findsOneWidget);
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Xoá tài khoản?'), findsOneWidget);
  });

  for (final viaReauth in [false, true]) {
    testWidgets('session ends mid-delete: the Apple ID SnackBar still shows '
        '(${viaReauth ? 're-auth' : 'first'} dialog, BUG-8)', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('vi'));
      final navigator = GlobalKey<NavigatorState>();
      final auth = _SessionEndsMidDeleteAuth(
        navigator,
        firstAsksReauth: viaReauth,
      );
      await tester.pumpWidget(_settingsApp(auth, navigatorKey: navigator));
      await tester.pumpAndSettle();

      final delete = find.text(l10n.deleteAccountBtn);
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
      await tester.pumpAndSettle();
      if (viaReauth) {
        await tester.tap(find.text(l10n.deleteAccountConfirmBtn));
        await tester.pumpAndSettle();
      }
      expect(find.byType(SettingsScreen), findsNothing);

      auth.release.complete();
      await tester.pumpAndSettle();
      expect(find.text('gate'), findsOneWidget);
      expect(find.text(l10n.deleteAccountAppleIdMismatch), findsOneWidget);
    });
  }
}
