import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/services/install_state_service.dart';

import 'dart:io';

void main() {
  final authService = AuthService();

  setUp(() async {
    await authService.clearLocalAuthData();
  });

  test('signUp assigns a personal invite code to each account', () async {
    final user = await authService.signUp(
      email: 'test@example.com',
      password: '123456',
      displayName: 'Bé Iu',
    );

    expect(user.inviteCode, hasLength(6));
    expect(user.inviteCode, equals(user.inviteCode.toUpperCase()));
    expect(user.hasInviteCode, isTrue);
  });

  test('purgePersistedSession clears restored local session', () async {
    await authService.signUp(
      email: 'persisted@example.com',
      password: '123456',
      displayName: 'Persisted User',
    );

    expect(await authService.getCurrentUser(), isNotNull);

    await authService.purgePersistedSession(clearDeviceCache: false);

    expect(await authService.getCurrentUser(), isNull);
  });

  test('AppUser.copyWith can clear nullable coupleId', () {
    final now = DateTime(2026, 4, 10);
    final original = AppUser(
      id: 'user-1',
      email: 'test@example.com',
      displayName: 'Tony',
      coupleId: 'couple-1',
      inviteCode: 'ABC123',
      status: 'in_couple',
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
    );

    final cleared = original.copyWith(coupleId: null, status: 'single');

    expect(cleared.coupleId, isNull);
    expect(cleared.status, 'single');
    expect(cleared.inviteCode, 'ABC123');
  });

  test('InstallStateService only triggers fresh-install cleanup once', () async {
    final markerDir = await Directory.systemTemp.createTemp('install_state_test');
    addTearDown(() async {
      if (await markerDir.exists()) {
        await markerDir.delete(recursive: true);
      }
    });

    final service = InstallStateService(
      markerDirectoryProvider: () async => markerDir,
    );

    var freshInstallCount = 0;
    final firstLaunch = await service.handleFreshInstall(
      onFreshInstall: () async {
        freshInstallCount++;
      },
    );
    final secondLaunch = await service.handleFreshInstall(
      onFreshInstall: () async {
        freshInstallCount++;
      },
    );

    expect(firstLaunch, isTrue);
    expect(secondLaunch, isFalse);
    expect(freshInstallCount, 1);
  });
}

