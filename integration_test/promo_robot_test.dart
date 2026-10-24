// Robot quay màn hình cho video quảng cáo (feature promo-video, 2026-10-15).
// Chạy trên simulator đã đăng nhập tài khoản Thảo (test4@gmail.com, DEV) SAU
// `scripts/dev-seed-promo.js`. Thu hình bằng `xcrun simctl io <udid> recordVideo`
// song song (scripts/promo-record.sh). Không phải test nghiệm thu: không assert,
// chỉ bấm theo kịch bản và in mốc thời gian `[robot] <mốc> <epoch ms>` để cắt.
//
//   flutter test integration_test/promo_robot_test.dart -d <udid>

import 'dart:async';

import 'package:dear_embeiu/main.dart' as app;
import 'package:dear_embeiu/screens/sleep_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void mark(String label) {
  // ignore: avoid_print
  print('[robot] $label ${DateTime.now().millisecondsSinceEpoch}');
}

/// Gửi sự kiện chạm theo nguồn "device" để LiveTestWidgetsFlutterBinding KHÔNG
/// vẽ dấu chữ thập con trỏ lên màn hình (nó chỉ vẽ cho nguồn "test").
int _pointerId = 40;
void _send(PointerEvent e) {
  final b = IntegrationTestWidgetsFlutterBinding.instance;
  b.shouldPropagateDevicePointerEvents = true;
  // ignore: invalid_use_of_protected_member
  b.withPointerEventSource(TestBindingEventSource.device, () => b.handlePointerEvent(e));
}

Future<void> deviceTapAt(Offset p) async {
  final id = _pointerId++;
  _send(PointerDownEvent(pointer: id, position: p, kind: PointerDeviceKind.touch));
  await wait(70);
  _send(PointerUpEvent(pointer: id, position: p, kind: PointerDeviceKind.touch));
}

Future<void> deviceDrag(Offset from, Offset to, int ms, {int steps = 24}) async {
  final id = _pointerId++;
  _send(PointerDownEvent(pointer: id, position: from, kind: PointerDeviceKind.touch));
  await wait(40);
  var prev = from;
  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    final e = 1 - (1 - t) * (1 - t); // ease-out
    final p = Offset.lerp(from, to, e)!;
    // DragGestureRecognizer cộng dồn `delta`, không so vị trí — delta 0 = không cuộn.
    _send(PointerMoveEvent(pointer: id, position: p, delta: p - prev, kind: PointerDeviceKind.touch));
    prev = p;
    await wait(ms ~/ steps);
  }
  _send(PointerUpEvent(pointer: id, position: to, kind: PointerDeviceKind.touch));
}

Future<void> settleTap(WidgetTester tester, Finder finder, {int after = 600}) async {
  final target = finder.evaluate().isEmpty ? null : tester.getCenter(finder.first);
  if (target == null) {
    mark('MISSING ${finder.describeMatch(Plurality.one)}');
    return;
  }
  await deviceTapAt(target);
  await tester.pump();
  await wait(after);
}

/// Kéo chậm, tự nhiên (không fling) để thu hình mượt.
Future<void> scrollHome(WidgetTester tester, double dy, {int ms = 700}) async {
  final scroll = find.byType(SingleChildScrollView).first;
  final c = tester.getCenter(scroll);
  await deviceDrag(Offset(c.dx, c.dy + dy / 2), Offset(c.dx, c.dy - dy / 2), ms);
  await tester.pump();
  await wait(500);
}

/// Kéo tới khi [target] hiện ra (tối đa [maxSteps] lần kéo).
Future<bool> scrollUntil(WidgetTester tester, Finder target, {int maxSteps = 8}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pump();
      await wait(400);
      return true;
    }
    await scrollHome(tester, 420);
  }
  return target.evaluate().isNotEmpty;
}

Future<void> typeSlowly(WidgetTester tester, Finder field, String text) async {
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(field, text.substring(0, i));
    await tester.pump();
    await wait(i % 7 == 0 ? 140 : 55);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('promo robot', (tester) async {
    // Lỗi async của app (Firestore/mạng) không được lọt vào zone của test —
    // LiveTestWidgetsFlutterBinding sẽ assert và treo test tới timeout.
    runZonedGuarded(() => app.main(), (e, st) => mark('app-error $e'));
    await wait(6000);

    // ── 0a. Cài mới (flutter test gỡ app sau mỗi lần chạy): bỏ qua intro, đăng nhập Thảo.
    final skip = find.text('Bỏ qua');
    if (skip.evaluate().isNotEmpty) {
      mark('prep-intro');
      await settleTap(tester, skip, after: 1500);
    }
    final signInEmail = find.text('Đăng nhập bằng email');
    if (signInEmail.evaluate().isNotEmpty) {
      mark('prep-login');
      await settleTap(tester, signInEmail, after: 1500);
      await tester.enterText(find.byType(TextFormField).at(0), 'test4@gmail.com');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(1), '12345678');
      await tester.pump();
      await wait(300);
      await settleTap(tester, find.text('Đăng nhập').last, after: 1000);
    }

    // Đợi Home có thẻ câu hỏi (tối đa 60 s).
    Finder dqPill() {
      final a = find.textContaining('Trả lời để mở khoá', findRichText: true);
      return a.evaluate().isNotEmpty ? a : find.textContaining('Chạm để trả lời', findRichText: true);
    }
    for (var i = 0; i < 120 && dqPill().evaluate().isEmpty; i++) {
      await wait(500);
    }
    await wait(2500);
    mark('home-ready ${dqPill().evaluate().isEmpty ? "NO-DQ-PILL" : "ok"}');

    // ── 0b. Thẻ Giấc ngủ chưa bật trên máy này → bật ghi tay + chia sẻ (không quay).
    final enableSleep = find.text('Bật theo dõi');
    if (await scrollUntil(tester, enableSleep, maxSteps: 6)) {
      mark('prep-sleep');
      try {
        await settleTap(tester, enableSleep, after: 1500);
        await settleTap(tester, find.text('Mình sẽ tự ghi').last, after: 1500);
        final shareCta = find.text('Chia sẻ với người ấy');
        if (shareCta.evaluate().isNotEmpty) await settleTap(tester, shareCta.last, after: 1500);
      } catch (e) {
        mark('ERR prep-sleep $e');
      }
      await wait(1500);
    }
    // Cuộn về đầu trang.
    final top = tester.getCenter(find.byType(SingleChildScrollView).first);
    await deviceDrag(Offset(top.dx, top.dy - 500), Offset(top.dx, top.dy + 500), 500);
    await deviceDrag(Offset(top.dx, top.dy - 500), Offset(top.dx, top.dy + 500), 500);
    await deviceDrag(Offset(top.dx, top.dy - 500), Offset(top.dx, top.dy + 500), 500);
    await wait(2000);
    mark('home-top');

    // (Đoạn Home đứng yên đã quay ở lần 1 — không quay lại.)

    // ── 2. Câu hỏi hôm nay: chạm trả lời → gõ → Gửi → mở cả hai (cảnh 5).
    // Tuấn đã trả lời nên pill ghi "Trả lời để mở khoá câu trả lời của người ấy".
    final tapToAnswer = dqPill();
    // Canh thẻ câu hỏi lên đầu khung nhìn (cuộn xuống trước rồi ensureVisible
    // kéo mép trên thẻ về mép trên viewport) để reveal + confetti nằm trong khung.
    await scrollHome(tester, 900, ms: 500);
    await scrollHome(tester, 900, ms: 500);
    await tester.ensureVisible(find.text('Hôm nay của chúng mình').first);
    await tester.pump();
    await wait(1200);
    mark('dq-start');
    try {
      await settleTap(tester, tapToAnswer, after: 900);
      final field = find.byType(TextField).last;
      await typeSlowly(tester, field, 'Anh luôn nhắn "về chưa" dù biết em về rồi');
      await wait(500);
      await settleTap(tester, find.text('Gửi').last, after: 300);
      mark('dq-sent');
      await wait(5500);
    } catch (e) {
      mark('ERR dq $e');
    }
    mark('dq-end');

    // ── 3. Tâm trạng: Chia sẻ → chọn Nhớ → Lưu → cùng tâm trạng (cảnh 3).
    final share = find.text('Chia sẻ tâm trạng');
    await scrollUntil(tester, share);
    await tester.ensureVisible(find.text('Tâm trạng hôm nay').first);
    await tester.pump();
    await wait(1200);
    mark('mood-start');
    await wait(700);
    try {
      await settleTap(tester, share, after: 900);
      final sheet = find.byType(BottomSheet);
      await settleTap(tester, find.descendant(of: sheet, matching: find.text('Nhớ')), after: 700);
      await settleTap(tester, find.descendant(of: sheet, matching: find.text('Lưu tâm trạng')), after: 300);
      mark('mood-saved');
      await wait(4000);
    } catch (e) {
      mark('ERR mood $e');
    }
    mark('mood-end');

    // ── 4. Giấc ngủ: thẻ Đêm qua → màn Giấc ngủ → kéo tới chi tiết (cảnh 4).
    final sleepCard = find.text('Đêm qua').first;
    await scrollUntil(tester, sleepCard);
    await tester.ensureVisible(sleepCard);
    await tester.pump();
    await wait(1200);
    mark('sleep-start');
    await wait(700);
    try {
      await settleTap(tester, sleepCard, after: 2200);
      mark('sleep-screen');
      final sleepScroll = find.descendant(of: find.byType(SleepScreen), matching: find.byType(Scrollable)).first;
      final sc = tester.getCenter(sleepScroll);
      await deviceDrag(Offset(sc.dx, sc.dy + 300), Offset(sc.dx, sc.dy - 420), 1000);
      await tester.pump();
      await wait(3600);
    } catch (e) {
      mark('ERR sleep $e');
    }
    mark('sleep-end');

    await wait(800);
    mark('done');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
