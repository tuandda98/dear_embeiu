# Counter — Đếm ngày yêu & milestone

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** counter
- **Ưu tiên:** P0 (tính năng signature của app)
- **Trạng thái:** ✅ Shipped (v1.0.0) — ⚠️ ảnh hưởng bởi gap i18n (xem feature [language](../language/overview.md))
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 8,13

## 1. Mô tả
Tính & hiển thị số năm/tháng/ngày couple đã bên nhau từ `anniversaryDate` (model `CounterData`). Home có **thanh tiến độ milestone** (mốc 30/50/100/180/365/500/730/1000/1500/2000/3000 ngày) + carousel "kỷ niệm gần đây" + love note quote nội suy theo tổng số ngày.

## 2. Phạm vi
- **Trong:** đếm ngày/tháng/năm, đếm ngược tới kỷ niệm/milestone kế, hero counter card, love quote.
- **Ngoài:** đếm ngược sự kiện tuỳ chỉnh (→ feature shared-calendar tương lai), nhiều mốc do user tự đặt.

## 3. Code liên quan
- `lib/models/counter_data.dart` (months ≈ 30 ngày), `lib/widgets/counter_card.dart` (hero gradient sunsetRomance)
- `lib/screens/home_screen.dart` (milestone bar, recent carousel, quote)
- Ngày hiển thị: `home_screen.dart:1068`, `profile_screen.dart:1294` (⚠️ DateFormat hardcode — gap A của [language])

## 4. Acceptance (đã đạt)
- [x] Hiển thị đúng năm/tháng/ngày từ anniversary
- [x] Milestone progress + đếm ngược mốc kế
- [x] "Hôm nay là kỷ niệm" / "còn X ngày tới kỷ niệm"

## 5. Nợ kỹ thuật / rủi ro
- 🔴 **Ngày hiển thị không đổi theo ngôn ngữ** (gap A — thuộc feature [language], nhưng biểu hiện ở counter/Home/Profile).
- 🟡 **Anniversary tương lai → daysTogether<0 → bỏ schedule milestone im lặng** (`reminder_provider` ~213) — đồng thời ảnh hưởng counter logic.
- 🟡 months ≈ 30 ngày là xấp xỉ → mốc có thể lệch nhẹ so với lịch thực; cần xác nhận có chấp nhận được.
- 🟡 [CẦN TEST] múi giờ, năm nhuận, đúng hôm nay (0 ngày).

## 6. Changelog
- [2026-05-30] [PO] Tài liệu hoá feature; nối gap ngày tháng sang feature language.
