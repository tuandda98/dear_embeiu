import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/services/sleep_service.dart' show SleepMode;
import 'package:dear_embeiu/services/sleep_platform.dart';

import 'sleep_provider_test.dart' show FakeSleepService;

/// F1 (vòng vá 1): when must the provider tell the native side to stop and
/// wipe the motion record? Records the calls on `dear_embeiu/sleep`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dear_embeiu/sleep');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> methods;

  setUp(() {
    methods = [];
    SleepPlatform.debugAndroid = true;
    messenger.setMockMethodCallHandler(channel, (c) async {
      methods.add(c.method);
      if (c.method == 'motionPermission') {
        return 'denied';
      }
      if (c.method == 'motionStillSpans' || c.method == 'screenEvents') {
        return <int>[];
      }
      return false;
    });
  });
  tearDown(() {
    SleepPlatform.debugAndroid = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  int stops() => methods.where((m) => m == 'stopMotionTracking').length;

  test('enableTracking(manual) stops motion tracking', () async {
    final p = SleepProvider(service: FakeSleepService());
    await p.watchForCouple('c', 'me', 'partner');
    methods.clear();
    await p.enableTracking(SleepMode.manual);
    await pumpEventQueue();
    expect(stops(), 1);
  });

  test('enableTracking(auto) does not', () async {
    final p = SleepProvider(service: FakeSleepService());
    await p.watchForCouple('c', 'me', 'partner');
    methods.clear();
    await p.enableTracking(SleepMode.auto);
    await pumpEventQueue();
    expect(stops(), 0);
  });

  test('clear(signedOut: true) stops it, even with no session', () async {
    final p = SleepProvider(service: FakeSleepService());
    p.clear(signedOut: true); // _uid is still null
    await pumpEventQueue();
    expect(stops(), 1);
  });

  test('clear(signedOut: true) after a session stops it once', () async {
    final p = SleepProvider(service: FakeSleepService());
    await p.watchForCouple('c', 'me', 'partner');
    methods.clear();
    p.clear(signedOut: true);
    await pumpEventQueue();
    expect(stops(), 1);
  });

  test('plain clear() leaves the motion record alone', () async {
    final p = SleepProvider(service: FakeSleepService());
    await p.watchForCouple('c', 'me', 'partner');
    methods.clear();
    p.clear();
    await pumpEventQueue();
    expect(stops(), 0);
  });

  test('another uid in watchForCouple stops it', () async {
    final p = SleepProvider(service: FakeSleepService());
    await p.watchForCouple('c', 'A', 'partner');
    methods.clear();
    await p.watchForCouple('c', 'B', 'partner');
    await pumpEventQueue();
    expect(stops(), 1);
  });

  test('first watch (no previous uid) does not stop it', () async {
    final p = SleepProvider(service: FakeSleepService());
    await p.watchForCouple('c', 'A', 'partner');
    await pumpEventQueue();
    expect(stops(), 0);
  });

  test('same uid again (refresh, new partner, new couple) does not', () async {
    final p = SleepProvider(service: FakeSleepService());
    await p.watchForCouple('c', 'A', 'partner');
    methods.clear();
    await p.watchForCouple('c', 'A', 'partner'); // unchanged no-op
    await p.watchForCouple('c', 'A', 'other'); // partner changed
    await p.watchForCouple('d', 'A', 'other'); // couple changed
    await pumpEventQueue();
    expect(stops(), 0);
  });
}
