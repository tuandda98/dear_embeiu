import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/services/sleep_platform.dart';

/// Motion half of the `dear_embeiu/sleep` bridge (motion-contract 2026-10-13).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dear_embeiu/sleep');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall) handler) =>
      messenger.setMockMethodCallHandler(channel, (c) async => handler(c));

  setUp(() => SleepPlatform.debugAndroid = true);
  tearDown(() {
    SleepPlatform.debugAndroid = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  final from = DateTime(2026, 10, 1);
  final to = DateTime(2026, 10, 2);

  test('motionStillSpans: flat start/end pairs become RestSpans', () async {
    answer((_) => [1000, 2000, 3000, 4000]);
    final spans = await SleepPlatform.motionStillSpans(from, to);
    expect(spans, hasLength(2));
    expect(spans[0].start.millisecondsSinceEpoch, 1000);
    expect(spans[0].end.millisecondsSinceEpoch, 2000);
    expect(spans[1].start.millisecondsSinceEpoch, 3000);
    expect(spans[1].end.millisecondsSinceEpoch, 4000);
  });

  test('motionStillSpans: the call carries from/to in ms', () async {
    MethodCall? seen;
    answer((c) {
      seen = c;
      return <int>[];
    });
    await SleepPlatform.motionStillSpans(from, to);
    expect(seen!.method, 'motionStillSpans');
    expect(seen!.arguments, {
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
    });
  });

  test('motionStillSpans: an odd trailing element is dropped', () async {
    answer((_) => [1000, 2000, 3000]);
    expect(await SleepPlatform.motionStillSpans(from, to), hasLength(1));
  });

  test('motionStillSpans: channel error → empty', () async {
    answer((_) => throw PlatformException(code: 'boom'));
    expect(await SleepPlatform.motionStillSpans(from, to), isEmpty);
  });

  test('motionStillSpans: null answer → empty', () async {
    answer((_) => null);
    expect(await SleepPlatform.motionStillSpans(from, to), isEmpty);
  });

  test('motionPermission: the three values pass through', () async {
    for (final v in ['granted', 'denied', 'notDetermined']) {
      answer((_) => v);
      expect(await SleepPlatform.motionPermission(), v);
    }
  });

  test('motionPermission: null or error reads as denied', () async {
    answer((_) => null);
    expect(await SleepPlatform.motionPermission(), 'denied');
    answer((_) => throw PlatformException(code: 'boom'));
    expect(await SleepPlatform.motionPermission(), 'denied');
  });

  test('motionCoverageStart: 0 → null, ms → DateTime, error → null', () async {
    answer((_) => 0);
    expect(await SleepPlatform.motionCoverageStart(), isNull);
    answer((_) => 5000);
    expect(
      (await SleepPlatform.motionCoverageStart())!.millisecondsSinceEpoch,
      5000,
    );
    answer((_) => throw PlatformException(code: 'boom'));
    expect(await SleepPlatform.motionCoverageStart(), isNull);
  });

  test(
    'off Android/iOS everything reads empty without touching the channel',
    () async {
      SleepPlatform.debugAndroid = null; // host = macOS test runner
      var called = false;
      answer((_) {
        called = true;
        return 'granted';
      });
      expect(await SleepPlatform.motionPermission(), 'denied');
      expect(await SleepPlatform.motionStillSpans(from, to), isEmpty);
      expect(called, isFalse);
    },
  );
}
