# 🧪 Test — Widget màn hình chính — Đếm ngày yêu

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** <chưa test | đang test | PASS | FAIL>
- **Người/role:** Master Tester

## Checklist cho Tester (Dev bàn giao 2026-10-12)

> Dev chỉ liệt kê, chưa ghi kết quả. Đã chạy tay: iPhone 17 (iOS 26.3) + iPhone 16e (iOS 18.6), emulator Pixel_10 (API 37), tài khoản DEV `test1@gmail.com` / `test2@gmail.com`. Mọi mục dưới đây là phần Dev **chưa kiểm** hoặc kiểm chưa đủ. Số liệu Dev đã có: [overview.md](overview.md) mục 5 và [dev.md](dev.md) "Nhật ký implement".

**Chung**
- [ ] Qua 0:00 mà không mở app: iOS số nhảy đúng 0:00 (timeline 7 nửa đêm); Android nhảy trong ≤30 phút (`updatePeriodMillis`). Chỉnh giờ máy qua ngày rồi chỉ nhìn màn hình chính.
- [ ] Dev + prod cài chung máy: mỗi widget hiện dữ liệu của app mình (App Group `….dev` và prod tách; Android khác applicationId nên prefs tách).
- [ ] Sửa ngày yêu / tên trong Hồ sơ → widget đổi ngay. Rời couple, xoá tài khoản, đăng xuất khi mất mạng → widget về trống.
- [ ] `widget_tap{family}` có trên GA4 DebugView, đúng 1 event mỗi lần chạm (Dev mới xác nhận qua log `HomeWidgetBridge`).
- [ ] Số 10.000+, tên 12 chữ, và dòng dài nhất của bản vừa: "Bắt đầu từ 28 thg 12, 2023" (vi), "Milestone: 10,000 days" (en) — không tràn, không cắt năm.
- [ ] Trong Cài đặt, đổi từ một ngôn ngữ cụ thể sang "Theo hệ thống" (ngôn ngữ máy khác ngôn ngữ đang chọn): widget đổi chữ lúc nào? Dev biết là trễ tới lần mở app kế.
- [ ] Bản release: `flutter build ipa` có `PlugIns/DearEmbeiuWidget.appex`; `flutter build appbundle` (R8 + desugar `java.time`) — widget còn lên, còn chạm được.

**iOS**
- [ ] Entitlement App Group khi ký thật: `codesign -d --entitlements :-` trên `Runner.app` và `DearEmbeiuWidget.appex`. Simulator ký ad-hoc nên chỉ đọc được qua Mach-O (`__TEXT,__entitlements`). Lần archive đầu Xcode phải tạo App Group cho `com.tony.dearembeiu` + `.widget`.
- [ ] iOS 15 / 16 (máy mới có runtime 18.6 / 26.3 / 27.0, chưa chạy 27): đường `AccentedReader` cần iOS 16, `containerBackground` cần iOS 17.
- [ ] Tinted / Clear còn đọc được tên trong chip. Đã đo: tint mặc định iOS 18 = 5,47:1; tint khác 2,61–3,54; iOS 26 Tinted 2,38–2,90; Clear 1,61 (sáng) / 3,99 (tối). Chưa đạt AA ở mọi tint, đã chấp nhận ở bản đầu — chỉ cần xác nhận không "mất tên".
- [ ] Chữ cắt ở màn 375pt / iPhone SE; Dynamic Type lớn trên SE (Dev đã chạy AX5 trên iPhone 17 và 16e, rộng 402 / 390pt).

**Android**
- [ ] API 24–30: góc bo (hai vệt glow nằm trong `widget_bg`, API 31+ mới có `clipToOutline`) và autosize (API 24–25 không có autosize, số 5 chữ số có thể tràn). Dev mới chạy API 37.
- [ ] Launcher lưới dày / One UI: `minHeight` 110dp nhỏ hơn nội dung ≈120dp nên có thể xén 10dp đáy; widget 3 ô trên máy ô lớn (cột ≈108dp) và 4 ô trên máy nhỏ; chip cột trái ở 3 ô đang cắt "ANH TEST ♥ E…".
- [ ] Cỡ chữ hệ thống Large: "Bắt đầu từ" (tối đa 2 dòng, `wrap_content`) không xén chân chữ.
- [ ] `widget_tap` không đếm lại khi activity được khôi phục (process chết, đổi cấu hình) và khi mở từ Recents. Kẽ hẹp Dev biết: process chết trước khi lưu state → có thể thừa 1 event.
- [ ] Trạng thái trống (lần chụp duy nhất là trước khi đổi sang font hệ thống, chưa chụp lại); preview trong picker hiện trống vì layout chưa có `android:text` mẫu.

## Nợ đã biết (Dev ghi nhận, chưa vá — đừng báo trùng; PO/Dev quyết có vá không)
- Thứ tự tên trong chip là người 1 ♥ người 2, còn Home đặt người đang đăng nhập trước (bridge không biết uid). P3.
- Chip cắt tên dài giữa chữ: iOS "Em Bé Iu" (8 ký tự), Android `maxWidth` 48 / 64dp cắt "ANH TE…". Type scale của app cấm cỡ 9 nên co chữ là việc của Designer.
- Chọn "Theo hệ thống": `MaterialApp.locale = null` không chạy lại `localeResolutionCallback`, `AppL10n` giữ ngôn ngữ cũ. Gốc ở `LocaleProvider.setLocale(null)`; widget đổi chữ trễ tới cold start. Nên vá trước.
- Home in số thô ("1247", "1500 ngày"), widget nhóm hàng nghìn ("1.247") — D10, nợ PO.
- Bridge: hai guard `isLoading` / lỗi xét lúc notify nhưng state đọc lúc frame; hai post-frame cùng frame có thể gửi `update` trùng (vô hại). App nền mà couple đổi thì widget cập nhật khi quay lại foreground (chấp nhận).
- iOS: tham chiếu `Foundation.framework` cứng `iPhoneOS18.0.sdk` trong phase Frameworks của target widget (thừa, chưa gây lỗi); cấu hình Debug của target widget thiếu `-Onone`; `family` chưa lọc (small | medium | unknown). `flutter build ios` chạy `pod install` đảo thứ tự 2 phase của Runner trong `project.pbxproj` (có từ trước) — `git checkout` file đó trước khi commit.
- `android/.gitignore` loại `gradlew` + wrapper jar nên clone sạch không chạy được `./gradlew` (ngoài phạm vi feature).
- Ngoài phạm vi, thấy khi smoke iOS: `Null check operator` trong `_SwitchPainter.paint` (từ `Switch.adaptive` của tile AI, `settings_screen.dart`). Tile AI đã bị ẩn bởi `a148184` nên không hiện lại; chưa tìm gốc.

## Phạm vi test
<feature/case nào>

## Test case
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | <…> | <…> | ⬜ |
| 2 | edge | <…> | <…> | ⬜ |
| 3 | negative | <…> | <…> | ⬜ |
| 4 | đa ngôn ngữ | <…> | <…> | ⬜ |
| 5 | offline / 2 thiết bị couple | <…> | <…> | ⬜ |
| 6 | cold start | <…> | <…> | ⬜ |

*(Kết quả: ✅ pass · ❌ fail · ⬜ chưa chạy)*

## Bug report (nếu FAIL)
### BUG-1: <tiêu đề>
- **Severity:** <critical | major | minor>
- **File/màn hình:** <file:line>
- **Expected:** <…>
- **Actual:** <…>
- **Steps to reproduce:** 1) … 2) … (ghi nhánh Firebase/local nếu liên quan)

## Nhật ký test
- [<YYYY-MM-DD>] [Tester] <đã test gì / kết quả>
