import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/services/home_widget_bridge.dart';

/// Feature home-widget (2026-10-12): the CounterCard photo goes to the widget
/// as a PNG no larger than [HomeWidgetBridge.photoMaxEdge], once per key, and
/// a null key removes it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dear_embeiu/widget');
  final sent = <Uint8List?>[];

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'setPhoto') sent.add(call.arguments as Uint8List?);
          return null;
        });
  });

  Future<File> fakePhoto(Directory dir) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 1600, 900),
      ui.Paint()..color = const ui.Color(0xFFFF6B9D),
    );
    final image = await recorder.endRecording().toImage(1600, 900);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${dir.path}/photo.png');
    await file.writeAsBytes(data!.buffer.asUint8List());
    return file;
  }

  testWidgets('downscales to 720px, dedupes by key, null clears', (
    tester,
  ) async {
    await tester.runAsync(() async {
      HomeWidgetBridge.resetForTest();
      sent.clear();
      final dir = await Directory.systemTemp.createTemp('widget_photo');
      final file = await fakePhoto(dir);

      await HomeWidgetBridge.pushPhoto(key: 'p1', local: file.path);
      expect(sent.length, 1);
      final png = sent.single!;
      expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: 'PNG magic');
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, HomeWidgetBridge.photoMaxEdge);
      expect(
        frame.image.height,
        405,
        reason: 'aspect kept (1600×900 → 720×405)',
      );

      await HomeWidgetBridge.pushPhoto(key: 'p1', local: file.path);
      expect(sent.length, 1, reason: 'same key is not re-sent');

      await HomeWidgetBridge.pushPhoto(
        key: 'missing',
        local: '${dir.path}/nope.jpg',
      );
      expect(sent.length, 2);
      expect(
        sent.last,
        isNull,
        reason: 'unresolvable photo → widget falls back to the gradient',
      );

      await HomeWidgetBridge.pushPhoto(key: null);
      expect(sent.length, 3);
      expect(sent.last, isNull);
      await dir.delete(recursive: true);
    });
  });
}
