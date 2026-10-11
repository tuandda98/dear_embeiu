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

void main() {
  testWidgets('no couple: Settings still offers delete account (5.1.1(v))', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _UnpairedAuth()),
          // Fresh provider = couple null, as on Setup.
          ChangeNotifierProvider(create: (_) => CoupleProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
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
}
