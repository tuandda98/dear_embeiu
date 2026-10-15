# 🧪 Test — Audit UI 2026-10-13

> Lead tự smoke (không có Tester riêng). Code-level: `flutter analyze` 0 · `flutter test` 550 pass.

## Android (Pixel API 37 emulator, tự lái adb, tài khoản test3)
- ✅ Settings cuộn sát mép: nội dung trượt dưới status bar, `StatusBarScrim` giữ chữ đồng hồ đọc được; cuối trang chừa inset.
- ✅ Home: pill n/6 cùng hàng tiêu đề "Today, together".
- ✅ Widget: picker 2 cỡ (2×2 + 4×2) với preview thật (ảnh + tên + số) trên API 35+; widget ngoài màn hình = ảnh Unsplash (test3) / trời đêm (test1, trạng thái trống).
- ✅ Login: không còn tiêu đề "Email" trùng.

## iOS (iPhone 17 simulator iOS 26.3.1, DeviceHub, tài khoản test4)
- ✅ Build + cài qua `scripts/ios-sim.sh`; widget nhỏ + vừa thêm được từ gallery, hiện ảnh + "1,248" + cột mốc (P3).
- ✅ Home (1248, ảnh, pill 1/6 cùng hàng) · Profile (badge "OUR STORY" .92 + bóng) · Journal (cuộn sát mép, scrim) · Care timeline (trạng thái trống) · Intro 3 slide · Landing (sau vá scrim) · Login (không trùng "Email", back/chip/ngôn ngữ dưới inset).
- ⚠️ Phát hiện khi smoke: landing + Setup thiếu `StatusBarScrim` → tiêu đề đè đồng hồ khi cuộn → đã vá (commit cùng đợt).
- ❌ CHƯA kiểm trên iOS (DeviceHub rớt/đảo ký tự khi gõ, không đăng nhập được tài khoản khác bằng tự động hoá): Settings edge-to-edge, Reminders, Sleep, Lịch âm, Counter/Chat background, Register/Forgot, widget trời đêm (test2), Chat/Gallery tab. Các màn này cùng mã Flutter với Android (đã kiểm Settings/Home/Login ở Android) nhưng inset notch iOS khác → **user kiểm tay 5 phút**: đăng nhập `test2@gmail.com` → Profile → ⚙️ Settings cuộn đầu/cuối → Reminders → Sleep → Lịch âm (tài khoản gated) → đăng xuất → Đăng ký / Quên mật khẩu → màn hình chính xem widget trời đêm.

## Nợ / ghi chú
- F16 rps_game: Dev chỉ đổi gutter header; vùng cuộn bên trong giữ 16 (đã sửa 3 chỗ), màn trống 32.
- F35 streak_chip: icon Iconsax `accentLove` trên hero hồng có thể kém nổi — nhìn thật rồi quyết.
- Tự động hoá iOS: chạm chỉ tin được ở cửa sổ simulator riêng (DeviceHub ">>" → Open in New Window), gõ phím qua CGEvent không tin được (helper `scratchpad/sim2.py`, không commit).
