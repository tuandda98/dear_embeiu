import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/locale_provider.dart';
import 'package:dear_embeiu/screens/login_screen.dart';
import 'package:dear_embeiu/services/auth_service.dart';

void main() {
  setUp(() async {
    await AuthService().clearLocalAuthData();
  });

  testWidgets('renders login screen scaffold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        // Wire the real localization layer + pin to Vietnamese so the screen's
        // l10n strings resolve (without delegates `AppLocalizations.of` is null
        // and the screen can't build / falls back to the wrong language).
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthProvider(authService: AuthService()),
            ),
            // LoginScreen embeds a LanguageToggleButton that watches it.
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const LoginScreen(),
        ),
      ),
    );
    // Let the localization delegate load + entrance animations settle.
    await tester.pumpAndSettle();

    // Assert on elements that don't depend on isUsingFirebase (false in tests,
    // where the subtitle becomes the local-fallback copy). Exact-match strings.
    expect(find.text('Chào mừng trở lại'), findsOneWidget); // loginTitle
    // "Quên mật khẩu?" link added in the 2026-06-05 forgot-password flow.
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    // Register link ("Tạo tài khoản") — at least once on the login screen.
    expect(find.text('Tạo tài khoản'), findsAtLeastNWidgets(1));
  });
}
