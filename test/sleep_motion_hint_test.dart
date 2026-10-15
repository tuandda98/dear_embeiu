import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/services/sleep_platform.dart';
import 'package:dear_embeiu/services/sleep_service.dart';

import 'sleep_provider_test.dart' show FakeSleepService;

class _Service extends FakeSleepService {
  _Service(this.settings);
  SleepSettings settings;
  @override
  Future<SleepSettings> loadSettings(String uid) async => settings;
  @override
  Future<void> saveSettings(String uid, SleepSettings s) async => settings = s;
}

/// `showMotionHint` (vòng vá 1, P2-6): offered once to people who set sleep up
/// before the motion fallback existed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dear_embeiu/sleep');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<SleepProvider> provider({
    bool enabled = true,
    SleepMode mode = SleepMode.auto,
    bool dismissed = false,
    String permission = 'notDetermined',
    bool supported = true,
  }) async {
    SleepPlatform.debugAndroid = true;
    messenger.setMockMethodCallHandler(channel, (c) async {
      switch (c.method) {
        case 'motionPermission':
          return permission;
        case 'motionSupported':
          return supported;
        case 'motionStillSpans':
        case 'screenEvents':
        case 'sleepSamples':
          return <int>[];
        default:
          return false;
      }
    });
    final p = SleepProvider(
      service: _Service(
        SleepSettings(
          enabled: enabled,
          mode: mode,
          motionHintDismissed: dismissed,
        ),
      ),
    );
    await p.watchForCouple('c', 'me', 'partner');
    return p;
  }

  tearDown(() {
    SleepPlatform.debugAndroid = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'shown: enabled + not manual + notDetermined + supported + not dismissed',
    () async {
      expect((await provider()).showMotionHint, isTrue);
      expect((await provider(mode: SleepMode.health)).showMotionHint, isTrue);
    },
  );

  test('hidden when dismissed', () async {
    expect((await provider(dismissed: true)).showMotionHint, isFalse);
  });

  test('hidden when granted or denied', () async {
    expect((await provider(permission: 'granted')).showMotionHint, isFalse);
    expect((await provider(permission: 'denied')).showMotionHint, isFalse);
  });

  test('hidden when unsupported, manual or not set up', () async {
    expect((await provider(supported: false)).showMotionHint, isFalse);
    expect((await provider(mode: SleepMode.manual)).showMotionHint, isFalse);
    expect((await provider(enabled: false)).showMotionHint, isFalse);
  });

  test('dismissMotionHint hides it and is saved', () async {
    final p = await provider();
    await p.dismissMotionHint();
    expect(p.showMotionHint, isFalse);
  });
}
