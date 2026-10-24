import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/app/route_observers.dart';
import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/providers/photo_provider.dart';
import 'package:dear_embeiu/screens/setup_screen.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';

/// Signed in, no couple yet: the pairing landing.
class _Auth extends AuthProvider {
  _Auth(this.name) : super(authService: AuthService());

  final String name;

  @override
  AppUser? get currentUser => AppUser(
    id: 'me',
    email: 'x1y2@privaterelay.appleid.com',
    displayName: name,
    inviteCode: 'ABC234',
    status: 'single',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

Widget _app(String name, GlobalKey<NavigatorState> navigator) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => _Auth(name)),
    ChangeNotifierProvider(create: (_) => CoupleProvider()),
    ChangeNotifierProvider(create: (_) => PhotoProvider()),
  ],
  child: MaterialApp(
    navigatorKey: navigator,
    theme: AppTheme.lightTheme,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: [appPageRouteObserver],
    home: const SetupScreen(),
  ),
);

// Feature pairing-funnel, audit 2026-10-12: PA4 (what the code field shows
// after Join), PA5 (clipboard check when Setup is uncovered) and PA8 (no "New
// user" prefill).
void main() {
  setUpAll(() async {
    // InviteClipboard keeps its changeCount / asked codes in this box.
    Hive.init(Directory.systemTemp.createTempSync('pairing_setup').path);
    await Hive.openBox<String>('app_settings');
  });

  testWidgets(
    'PA5: iOS looks at the clipboard again when Setup is uncovered',
    (tester) async {
      var probes = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dear_embeiu/clipboard'),
        (call) async {
          probes++;
          return {'hasUrl': false, 'changeCount': probes};
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dear_embeiu/clipboard'),
          null,
        ),
      );
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app('Tuấn', navigator));
      await tester.pump(const Duration(milliseconds: 600));
      expect(probes, 1, reason: 'first look on open');

      // Setup → Settings, then back from Safari with a link in the clipboard:
      // Setup isn't the top route, so the resume check skips.
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 600));
      expect(probes, 1);

      // Back to Setup: it looks then.
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      expect(probes, 2);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('PA4: the field shows the cleaned code only when it is a code', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('vi'));
    for (final (typed, shown) in [
      (' abc 234 ', 'ABC234'),
      ('https://dearembeiu.com/get?code=abc234', 'ABC234'),
      ('Mã: abc234', 'Mã: abc234'), // not a code: left as typed
      ('abc 23', 'abc 23'), // too short
      ('abc 23o', 'abc 23o'), // O isn't in the alphabet
    ]) {
      await tester.pumpWidget(_app('Tuấn', GlobalKey<NavigatorState>()));
      await tester.pump(const Duration(milliseconds: 600)); // clipboard check
      await tester.tap(find.text(l10n.setupTabJoin));
      await tester.pump();
      await tester.enterText(find.byType(TextField), typed);
      await tester.ensureVisible(find.text(l10n.joinBtn));
      await tester.tap(find.text(l10n.joinBtn));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        shown,
        reason: typed,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('PA8: the "New user" placeholder is not prefilled', (
    tester,
  ) async {
    for (final (name, shown) in [
      ('Người dùng mới', false),
      ('New user', false),
      ('Tuấn Anh', true),
    ]) {
      await tester.pumpWidget(_app(name, GlobalKey<NavigatorState>()));
      await tester.pump();
      expect(
        find.text(name),
        shown ? findsOneWidget : findsNothing,
        reason: name,
      );
      // Let the delayed clipboard check run out, then a fresh tree for the
      // next name (prefill runs once per State).
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(const SizedBox());
    }
  });
}
