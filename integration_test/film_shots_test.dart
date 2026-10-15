// Robot chụp từng màn hình của app bản mới nhất làm tư liệu cho phim 50 s
// (videos/dear-embeiu-launch-50s, 2026-10-15). Chạy SAU `scripts/dev-seed-promo.js`
// (DEV, tài khoản Thảo test4@gmail.com). Không phải test nghiệm thu: không assert,
// chỉ đi qua từng màn và in mốc `[shot] <tên>`; scripts/film-shots.sh đọc mốc
// rồi chụp (simctl / adb) trong lúc robot đứng yên ~1,3 s.
//
//   scripts/film-shots.sh ios <udid> <thư mục>
//   scripts/film-shots.sh android <emulator-5554> <thư mục>

import 'dart:async';

import 'package:dear_embeiu/main.dart' as app;
import 'package:dear_embeiu/screens/sleep_screen.dart';
import 'package:dear_embeiu/widgets/rps_invite_card.dart';
import 'package:dear_embeiu/widgets/streak_chip.dart';
import 'package:dear_embeiu/widgets/language_toggle_button.dart';
import 'package:dear_embeiu/widgets/today_constellation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:integration_test/integration_test.dart';

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void mark(String label) {
  // ignore: avoid_print
  print('[robot] $label ${DateTime.now().millisecondsSinceEpoch}');
}

/// Đứng yên rồi in mốc chụp; script bên ngoài chụp trong 1,3 s sau mốc.
Future<void> shot(WidgetTester tester, String name, {int settle = 400}) async {
  await tester.pump();
  await wait(settle);
  // ignore: avoid_print
  print('[shot] $name ${DateTime.now().millisecondsSinceEpoch}');
  await wait(1300);
}

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
    final e = 1 - (1 - t) * (1 - t);
    final p = Offset.lerp(from, to, e)!;
    _send(PointerMoveEvent(pointer: id, position: p, delta: p - prev, kind: PointerDeviceKind.touch));
    prev = p;
    await wait(ms ~/ steps);
  }
  _send(PointerUpEvent(pointer: id, position: to, kind: PointerDeviceKind.touch));
}

/// Chạm vào [finder] nếu có; trả về false (và ghi mốc MISSING) nếu không thấy.
Future<bool> tapIf(WidgetTester tester, Finder finder, {int after = 700, String? why}) async {
  if (finder.evaluate().isEmpty) {
    mark('MISSING ${why ?? finder.describeMatch(Plurality.one)}');
    return false;
  }
  await deviceTapAt(tester.getCenter(finder.first));
  await tester.pump();
  await wait(after);
  return true;
}

/// Kéo chậm trong vùng cuộn đầu tiên của màn đang mở. Điểm kéo luôn nằm trong
/// màn hình (±300 quanh tâm): ngón tay đặt ngoài màn thì không có gì cuộn cả.
Future<void> dragScroll(WidgetTester tester, double dy, {int ms = 650, Finder? area}) async {
  final f = area ?? find.byType(Scrollable).first;
  if (f.evaluate().isEmpty) return;
  final c = tester.getCenter(f);
  final half = dy.abs() / 2 > 300 ? 300.0 : dy.abs() / 2;
  final s = dy.sign;
  await deviceDrag(Offset(c.dx, c.dy + s * half), Offset(c.dx, c.dy - s * half), ms);
  await tester.pump();
  await wait(450);
}

Future<void> scrollHome(WidgetTester tester, double dy, {int ms = 650}) =>
    dragScroll(tester, dy, ms: ms, area: find.byType(SingleChildScrollView).first);

Future<void> homeToTop(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await scrollHome(tester, -600, ms: 300);
  }
  await wait(600);
}

/// Cuộn vùng [area] (mặc định: vùng cuộn đầu tiên) tới khi thấy [target] —
/// danh sách lười chỉ dựng phần tử gần khung nhìn, finder rỗng không có nghĩa là không có.
Future<bool> scrollTo(WidgetTester tester, Finder target, {Finder? area, int maxSteps = 8, double step = 500}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pump();
      await wait(500);
      return true;
    }
    await dragScroll(tester, step, area: area);
  }
  return target.evaluate().isNotEmpty;
}

/// Cuộn Home tới khi thấy [target], rồi đưa nó vào khung nhìn.
Future<bool> scrollUntil(WidgetTester tester, Finder target, {int maxSteps = 8}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pump();
      await wait(500);
      return true;
    }
    await scrollHome(tester, 420);
  }
  return target.evaluate().isNotEmpty;
}

/// Đóng route trên cùng (màn con hoặc bottom sheet).
Future<void> pop(WidgetTester tester) async {
  final scaffolds = find.byType(Scaffold);
  final ctx = scaffolds.evaluate().isNotEmpty ? tester.element(scaffolds.last) : tester.element(find.byType(MaterialApp).first);
  await Navigator.of(ctx, rootNavigator: true).maybePop();
  await tester.pump();
  await wait(900);
}

Future<void> typeSlowly(WidgetTester tester, Finder field, String text) async {
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(field, text.substring(0, i));
    await tester.pump();
    await wait(i % 7 == 0 ? 110 : 45);
  }
}

Future<void> guarded(String what, Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    mark('ERR $what $e');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('film shots', (tester) async {
    runZonedGuarded(() => app.main(), (e, st) => mark('app-error $e'));
    await wait(6000);
    // Android khởi động Firebase chậm hơn: chờ tới 40 s cho intro / landing / Home hiện ra.
    for (var i = 0; i < 80; i++) {
      if ([find.text('Tiếp'), find.text('Skip'), find.text('Đăng nhập bằng email'), find.text('Hôm nay của chúng mình')].any((f) => f.evaluate().isNotEmpty)) break;
      await wait(500);
    }
    mark('first-screen ${find.text('Skip').evaluate().isNotEmpty ? "en" : "vi"}');

    // ── Máy đặt ngôn ngữ hệ thống là tiếng Anh (emulator Android): bỏ qua intro tiếng Anh,
    // mở nút đổi ngôn ngữ ở landing, chọn "Tiếng Việt" (LocaleProvider lưu Hive) rồi đi tiếp như thường.
    await guarded('locale', () async {
      if (find.text('Skip').evaluate().isEmpty) return;
      mark('prep-locale-en');
      await tapIf(tester, find.text('Skip'), after: 1500);
      if (!await tapIf(tester, find.byType(LanguageToggleButton), after: 1200)) return;
      await tapIf(tester, find.text('Tiếng Việt').last, after: 1500);
      await pop(tester);
      await wait(800);
    });

    // ── Intro (cài mới) → landing → đăng nhập Thảo.
    await guarded('intro', () async {
      if (find.text('Tiếp').evaluate().isEmpty) return;
      await shot(tester, 'intro-1');
      await tapIf(tester, find.text('Tiếp'), after: 900);
      await shot(tester, 'intro-2');
      await tapIf(tester, find.text('Tiếp'), after: 900);
      await shot(tester, 'intro-3');
      if (!await tapIf(tester, find.text('Bắt đầu'), after: 1500)) await tapIf(tester, find.text('Bỏ qua'), after: 1500);
    });
    await guarded('login', () async {
      final signInEmail = find.text('Đăng nhập bằng email');
      if (signInEmail.evaluate().isEmpty) return;
      await shot(tester, 'landing');
      await tapIf(tester, signInEmail, after: 1500);
      await shot(tester, 'login');
      await tester.enterText(find.byType(TextFormField).at(0), 'test4@gmail.com');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(1), '12345678');
      await tester.pump();
      await wait(300);
      await tapIf(tester, find.text('Đăng nhập').last, after: 1000);
    });

    Finder dqPill() {
      final a = find.textContaining('Trả lời để mở khoá', findRichText: true);
      return a.evaluate().isNotEmpty ? a : find.textContaining('Chạm để trả lời', findRichText: true);
    }
    for (var i = 0; i < 120 && dqPill().evaluate().isEmpty; i++) {
      await wait(500);
    }
    await wait(3000);
    mark('home-ready ${dqPill().evaluate().isEmpty ? "NO-DQ-PILL" : "ok"}');

    // ── Giấc ngủ chưa bật trên máy này → bật ghi tay + chia sẻ.
    await guarded('prep-sleep', () async {
      final enable = find.text('Bật theo dõi');
      if (!await scrollUntil(tester, enable, maxSteps: 6)) return;
      await tapIf(tester, enable, after: 1500);
      await tapIf(tester, find.text('Mình sẽ tự ghi').last, after: 1500);
      final share = find.text('Chia sẻ với người ấy');
      if (share.evaluate().isNotEmpty) await tapIf(tester, share.last, after: 1500);
      await wait(1500);
    });

    // ── Home: từng khúc.
    await homeToTop(tester);
    await shot(tester, 'home-top', settle: 1500);
    await guarded('home-sections', () async {
      await scrollUntil(tester, find.text('Hôm nay của chúng mình'));
      await shot(tester, 'home-today');
      await scrollUntil(tester, find.text('Tâm trạng hôm nay'));
      await shot(tester, 'home-mood');
      await scrollUntil(tester, find.text('Đêm qua'));
      await shot(tester, 'home-sleep');
      await scrollUntil(tester, find.byType(RpsInviteCard));
      await shot(tester, 'home-rps');
      await scrollUntil(tester, find.text('Kỷ niệm gần đây'));
      await scrollHome(tester, 500);
      await shot(tester, 'home-memories');
    });

    // ── Chuỗi + Cây tình yêu.
    await homeToTop(tester);
    await guarded('streak', () async {
      if (!await tapIf(tester, find.byType(StreakChip), after: 1200)) return;
      await shot(tester, 'streak-sheet');
      await pop(tester);
    });
    await guarded('love-tree', () async {
      await homeToTop(tester);
      await scrollUntil(tester, find.byType(ConstellationPill));
      if (!await tapIf(tester, find.byType(ConstellationPill), after: 2500)) return;
      await shot(tester, 'love-tree-top', settle: 1500);
      await dragScroll(tester, 700);
      await shot(tester, 'love-tree-flowers');
      await dragScroll(tester, 700);
      await shot(tester, 'love-tree-tasks');
      await pop(tester);
    });

    // ── Câu hỏi hôm nay: trả lời → mở cả hai.
    await guarded('dq', () async {
      await homeToTop(tester);
      await scrollHome(tester, 900, ms: 500);
      await scrollHome(tester, 900, ms: 500);
      await tester.ensureVisible(find.text('Hôm nay của chúng mình').first);
      await tester.pump();
      await wait(1000);
      if (!await tapIf(tester, dqPill(), after: 1000)) return;
      await shot(tester, 'dq-sheet');
      final field = find.byType(TextField).last;
      await typeSlowly(tester, field, 'Anh luôn nhắn "về chưa" dù biết em về rồi');
      await shot(tester, 'dq-sheet-typed');
      await tapIf(tester, find.text('Gửi').last, after: 1200);
      await shot(tester, 'dq-revealed-1', settle: 200);
      await shot(tester, 'dq-revealed-2', settle: 2500);
    });

    // ── Tâm trạng: chia sẻ → chọn Nhớ → lưu → cùng tâm trạng.
    await guarded('mood', () async {
      final share = find.text('Chia sẻ tâm trạng');
      await scrollUntil(tester, share);
      await tester.ensureVisible(find.text('Tâm trạng hôm nay').first);
      await tester.pump();
      await wait(800);
      if (!await tapIf(tester, share, after: 1000)) return;
      await shot(tester, 'mood-sheet');
      final sheet = find.byType(BottomSheet);
      await tapIf(tester, find.descendant(of: sheet, matching: find.text('Nhớ')), after: 700);
      await shot(tester, 'mood-sheet-picked');
      await tapIf(tester, find.descendant(of: sheet, matching: find.text('Lưu tâm trạng')), after: 1800);
      await tester.ensureVisible(find.text('Tâm trạng hôm nay').first);
      await tester.pump();
      await shot(tester, 'mood-matched', settle: 1200);
    });

    // ── Giấc ngủ: thẻ Đêm qua → màn Giấc ngủ.
    await guarded('sleep', () async {
      final card = find.text('Đêm qua').first;
      await scrollUntil(tester, card);
      await tester.ensureVisible(card);
      await tester.pump();
      await wait(800);
      await shot(tester, 'home-sleep-card');
      if (!await tapIf(tester, card, after: 2500)) return;
      await shot(tester, 'sleep-top', settle: 1000);
      final sc = find.descendant(of: find.byType(SleepScreen), matching: find.byType(Scrollable)).first;
      await dragScroll(tester, 720, ms: 900, area: sc);
      await shot(tester, 'sleep-detail');
      await dragScroll(tester, 720, ms: 900, area: sc);
      await shot(tester, 'sleep-month');
      await pop(tester);
    });

    // ── Oẳn tù tì: thẻ → màn ván.
    await guarded('rps', () async {
      await scrollUntil(tester, find.byType(RpsInviteCard));
      final card = find.byType(RpsInviteCard);
      if (!await tapIf(tester, card, after: 2500)) return;
      await shot(tester, 'rps-screen', settle: 1200);
      await pop(tester);
    });

    // ── Header: Gửi quan tâm, Thông báo.
    await guarded('care', () async {
      await homeToTop(tester);
      if (!await tapIf(tester, find.byIcon(IconsaxPlusLinear.message_favorite), after: 2000)) return;
      await shot(tester, 'care-screen');
      await dragScroll(tester, 600);
      await shot(tester, 'care-screen-scroll');
      await pop(tester);
    });
    await guarded('notifications', () async {
      await homeToTop(tester);
      final bell = find.byIcon(IconsaxPlusLinear.notification_bing).evaluate().isNotEmpty
          ? find.byIcon(IconsaxPlusLinear.notification_bing)
          : find.byIcon(IconsaxPlusLinear.notification);
      if (!await tapIf(tester, bell, after: 2000)) return;
      await shot(tester, 'notifications');
      await pop(tester);
    });

    // ── Tab Kỷ niệm (gallery).
    await guarded('gallery', () async {
      if (!await tapIf(tester, find.byIcon(IconsaxPlusLinear.gallery), after: 3000)) return;
      await shot(tester, 'gallery-top', settle: 1500);
      await dragScroll(tester, 700);
      await shot(tester, 'gallery-scroll');
      final img = find.byType(Image);
      if (img.evaluate().isNotEmpty) {
        await tapIf(tester, img.first, after: 2000);
        await shot(tester, 'gallery-photo');
        await pop(tester);
      }
    });

    // ── Tab Trò chuyện.
    await guarded('chat', () async {
      if (!await tapIf(tester, find.byIcon(IconsaxPlusLinear.messages), after: 3000)) return;
      await shot(tester, 'chat', settle: 1500);
      await tapIf(tester, find.byIcon(IconsaxPlusLinear.arrow_left), after: 1500);
    });

    // ── Tab Hồ sơ → Nhật ký, Kỷ lục, Cài đặt, Lời nhắc, Lịch âm.
    await guarded('profile', () async {
      if (!await tapIf(tester, find.byIcon(IconsaxPlusLinear.user), after: 3000)) return;
      await shot(tester, 'profile-top', settle: 1500);
      await dragScroll(tester, 600);
      await shot(tester, 'profile-trail');
      await scrollTo(tester, find.text('nhật ký'));
      await shot(tester, 'profile-badges');
      if (await scrollTo(tester, find.text('nhật ký')) && await tapIf(tester, find.text('nhật ký'), after: 2500)) {
        await shot(tester, 'journal', settle: 1200);
        await dragScroll(tester, 600);
        await shot(tester, 'journal-scroll');
        await pop(tester);
      }
      if (await scrollTo(tester, find.text('kỷ lục')) && await tapIf(tester, find.text('kỷ lục'), after: 1800)) {
        await shot(tester, 'records-sheet');
        await pop(tester);
      }
      if (await scrollTo(tester, find.text('kỷ niệm')) && await tapIf(tester, find.text('kỷ niệm'), after: 1800)) {
        await shot(tester, 'memories-sheet');
        await pop(tester);
      }
      for (var i = 0; i < 6; i++) {
        await dragScroll(tester, -600, ms: 300);
      }
      await wait(600);
      if (!await tapIf(tester, find.byIcon(IconsaxPlusLinear.setting_2), after: 2500)) return;
      await shot(tester, 'settings-top', settle: 1000);
      await dragScroll(tester, 700);
      await shot(tester, 'settings-scroll');
      if (await scrollSettingsTo(tester, find.text('Lời nhắc')) && await tapIf(tester, find.text('Lời nhắc').first, after: 2200)) {
        await shot(tester, 'reminders', settle: 1000);
        await dragScroll(tester, 600);
        await shot(tester, 'reminders-scroll');
        await pop(tester);
      }
      if (await scrollSettingsTo(tester, find.text('Mở lịch âm')) && await tapIf(tester, find.text('Mở lịch âm').first, after: 2200)) {
        await shot(tester, 'lunar', settle: 1000);
        await pop(tester);
      }
      if (await scrollSettingsTo(tester, find.text('Ảnh nền thẻ đếm')) && await tapIf(tester, find.text('Ảnh nền thẻ đếm').first, after: 2200)) {
        await shot(tester, 'counter-bg', settle: 1000);
        await pop(tester);
      }
      await pop(tester);
    });

    await wait(800);
    mark('done');
  }, timeout: const Timeout(Duration(minutes: 15)));
}

/// Cuộn màn Cài đặt (vùng cuộn đầu tiên) tới khi thấy [target].
Future<bool> scrollSettingsTo(WidgetTester tester, Finder target, {int maxSteps = 8}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pump();
      await wait(500);
      return true;
    }
    await dragScroll(tester, 500);
  }
  return target.evaluate().isNotEmpty;
}
