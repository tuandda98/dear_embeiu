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

## [2026-10-22] [Tester] Nghiệm thu mốc A code-level — FAIL (1 High) → High đã vá
`feature/daily-open-2`: analyze 0 · 4 file test money 119 pass · functions 99 pass · rules-test (Lead) 513 pass.
- [High ✅ vá `2b4d289`] `money_home_entry.dart:93` + `money_provider.dart:336` — Home gọi aggregate số dư ~1 vòng/giây không dừng ((2×số ví + 2) truy vấn/vòng). Lead xác nhận + sửa: `refreshDay()` chỉ dời cửa sổ khi sang ngày, resume gọi `onResume()` tính lại tổng 1 lần. Cần kiểm Firestore usage trên máy thật.
- [Med] `settle_sheet.dart:77,119,137` — 2 máy cùng "Trả hết" / số cân bằng từ cache → 2 khoản settle, cân bằng lật dấu.
- [Med] `add_transaction_sheet.dart:251-257,657-689` + `money_provider.dart:806-818` — người tạo đổi "Ai trả" khoản có `linkId` → trừ 2 lần (ví chung + ví riêng).
- [Med] `money_analytics.dart` — thiếu `money_tx_edit`, `money_tx_delete{undone}`, `money_wallet_add`, `money_goal_add`; `money_report_open.view` thiếu `wallet|person`.
- [Low] `money_budgets_screen.dart:609-614` — Bỏ ngân sách → Hoàn tác mất `alerted` → push 80/100% lặp.
- [Low] `money_math.dart:362` + `money_screen.dart:1220` — dải "{partner} đã đổi khoản chung" hiện cả khi chính mình đổi.
- [Low] `money_provider.dart:478-486,242-246` — nửa liên kết vẫn hiện 5 giây chờ xoá.
- [Low] `money_flows.dart:51` — quỹ "Quy Nhơn" → "Lên lịch đi Nhơn thôi".
- [nghi ngờ, PO quyết] parser `"1tr2500"` → 1.250.000.
Cần smoke: aggregate chỉ chạy lúc mở/resume/0:00 · index DEV ra số · 3 loại push CF · 2 máy thanh toán/sửa/offline · người mới ghép vào bị permission-denied sổ cũ · nhắc tối 1210/1211 · app 1.11.0 nhận money_*.
- [2026-10-22] [Lead] Smoke 2 máy (Android emulator Pixel_10 = test3 Tuấn · iOS sim iPhone 17 Pro = test4 Thảo, DEV, nhánh `feature/daily-open-2`): Android ghi 340k sổ chung (Tuấn trả, chia đôi) → iOS thấy "Đã chi 340.000 ₫" + "Tuấn đang ứng nhiều hơn 170.000 ₫". **Lỗi tìm ra:** bấm "Đánh dấu đã thanh toán" không ghi gì — `MoneyPeople.of` gọi `Provider.of(listen: true)` trong callback → assertion (chỉ bản debug; release không assert). Vá `451f5f1` (listen:false ở 3 chỗ gọi từ callback + test có CoupleProvider thật, fail trên code cũ). Sau vá: thanh toán → "Hai bên đang ngang nhau 0 ₫" cả 2 máy. PASS. Ghi chú nhỏ: ô số tiền trong sheet Thanh toán hiện "170000" không có dấu chấm nghìn.
