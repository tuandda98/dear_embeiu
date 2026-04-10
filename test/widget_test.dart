import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/providers/auth_provider.dart';
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
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: AuthService()),
          child: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsOneWidget);
  });
}
