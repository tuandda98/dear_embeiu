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
`feature/daily-open-2`: analyze 0 · caro 59/59 + liên quan 81/81 · functions 99/99 · rules-test (Lead) 513 pass. Không có High; chống gian lận, race start, guard rps cho app cũ, dọn khi rời couple, i18n 142 key đều đạt.
- CARO-T1 [Low] `caro_game_screen.dart:411` — lỗi network/send/action không tự tắt khi nước đi đã vào bàn.
- CARO-T2 [Low] `push_notification_service.dart:869` — banner trong app id ngẫu nhiên, không gộp theo ván.
- CARO-T3 [Low] `functions/index.js:3134-3194,3281` — start→cancel lặp lại spam push/inbox/wake người ấy.
- CARO-T4 [Low] `home_widget_status.dart:343` — xin thua/huỷ/hết hạn không đánh thức → widget còn "đến lượt mình".
- CARO-T5 [Low] `caro_game_screen.dart:425-433` — `caro_game_ended` chỉ log ở máy đang mở màn ván → metric lệch.
- CARO-T6 [Low, tài liệu] `overview.md:114` D18 — lệnh deploy PROD thiếu `functions:leaveCoupleCleanup,functions:deleteAccount`.
- CARO-T7 [Low] `functions/index.js:3172-3174,3381-3388` — `lastWakeAt` ghi cả khi lời mời gửi không đánh thức.
- CARO-T8 [nghi ngờ] ghép lại đúng couple cũ → tỉ số 0–0 nhưng lịch sử còn ván cũ.
Cần smoke: 2 máy cùng "Ván mới" · realtime ≤2s · gộp thông báo 1/ván · widget đánh thức · presence iOS xuống nền · app 1.11.0 song song · rời couple giữa ván · a11y · mất mạng giữa nước đi.
- [2026-10-22] [Lead] Smoke 2 máy (Android emulator Pixel_10 = test3 Tuấn · iOS sim iPhone 17 Pro = test4 Thảo, DEV, nhánh `feature/daily-open-2`): mời → iOS thấy "Tuấn rủ bạn một ván và đã đi nước đầu" realtime; presence "đang xem" 2 chiều; nước 2 đồng bộ ≤2s; xin thua → cả 2 máy hiện kết quả, tỉ số 0–1, thẻ Home "Ván mới"/"Rematch"; inbox `caro_invite` ghi + tự đánh dấu đã đọc khi vào ván. PASS. Chưa thử push (DEV thiếu APNs, emulator không FCM) + widget.

- [2026-10-24] [tester] Smoke 2 máy ảo bằng Maestro (`maestro/caro-game/`): 18/18 flow PASS (ván đầy đủ, mất mạng, thắng, lịch sử, phục thù, huỷ, xin thua). Flow 02 bỏ vì nút Home "Chơi" giờ gửi lời mời luôn (29f73da); 03/14 viết lại theo luồng mới. Unit bù 50/52 case (`test/caro_gap_test.dart`, `functions/test/caro_gap.test.js`). Bảng case: `test-cases.md`.
