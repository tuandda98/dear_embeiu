# 🧪 Test — <Tên feature>

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** <chưa test | đang test | PASS | FAIL>
- **Người/role:** Master Tester

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

## [2026-10-22] [Tester] Nghiệm thu code-level — PASS có điều kiện
`feature/daily-open-2`: analyze 0 · test arrival 98/98 · functions 99/99 · rules-test (Lead) 513 pass. Privacy toạ độ (chỉ Hive nobackup + prefs plugin), `arrivalPush` khoá client, tắt chia sẻ xoá doc, dọn khi rời/xoá, CF chặn exit/bounce/cooldown/cap, i18n 187 key: đạt.
- [Chặn phát hành, ngoài code] Privacy policy `phase3` chưa có mục vị trí → Play từ chối form vị trí nền.
- BUG-1 [Med] `arrival_provider.dart:194-210,447-460` — mở app khi đang tự báo: snapshot cache tới trước khi đọc quyền → `stopAll()` + `auto:false` rồi mới `sync` + `auto:true`. Hậu quả: Android mở app trong 2' chờ DWELL thì mất tin "đã về"; iOS mất enter đang trễ; tắt app trong 4s thì không còn vùng. Nghi thêm `reCreateAfterReboot()` chạy mỗi resume (`arrival_platform_native.dart:271`).
- BUG-2 [Med, rủi ro duyệt] Copy xin quyền (`Info.plist:25`, `{vi,en}.lproj/InfoPlist.strings:20`, ARB `arrivalDisclosureBody`, nháp privacy) chỉ nói "nơi đến", nhưng app gửi cả sự kiện RỜI.
- BUG-3 [Low] `arrival_provider.dart:152-185` — 2 lệnh `watchForCouple` chồng nhau lúc tải Hive → D10 bị bỏ qua.
- BUG-4 [Low, nghi ngờ] `firestore.rules:758-777` — lệnh bấm tay xếp hàng offline tạo `share:true` với người ấy mới.
- BUG-5 [Low, đã chấp nhận] `home_widget_status.dart:297-301` — so ngày theo giờ VN.
- Ghi chú: `dev.md` mục Edge case ghi máy tắt `pushArrival` không bị đánh thức — code vẫn silent wake (`functions/index.js:3516`), doc cũ.
Cần smoke: Android mở app trong 2' DWELL · resume trong vùng · iOS nền/vuốt tắt · Geocoder 20 địa chỉ · "Cho phép mọi lúc" Android 11–14 · hạ quyền · `aapt2 dump permissions` · app 1.11.0 nhận push arrival.
- [2026-10-22] [Lead] Smoke 2 máy (Android emulator Pixel_10 = test3 Tuấn · iOS sim iPhone 17 Pro = test4 Thảo, DEV, nhánh `feature/daily-open-2`): bấm tay "I'm home" trên Android → iOS thấy "Tuấn đã về đến nhà · 12:33 · 100% · bấm tay" + nút Hỏi thăm. PASS. **Chưa thử được tự báo (geofence):** GPS emulator kẹt ở vị trí mặc định (`adb emu geo fix` trả OK nhưng `dumpsys location` không đổi) nên "Dùng vị trí hiện tại" báo không lấy được vị trí → BUG-1 phải kiểm trên máy thật.
