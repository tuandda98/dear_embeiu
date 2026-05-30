# Reminders — Love reminders (local notifications)

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** reminders
- **Ưu tiên:** P1 (retention)
- **Trạng thái:** ✅ Shipped (v1.0.0)
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 6,13

## 1. Mô tả
Nhắc nhở yêu thương **local-only** (không network), dùng flutter_local_notifications + timezone. 4 loại khi bật: **daily nudge** (giờ mặc định 20:00), **yearly anniversary**, **day-count milestone** (mỗi 100 ngày + nudge trước 3 ngày), **inactivity** (sau 7 ngày không đăng ảnh). Text lấy từ `AppL10n.strings` (đã localize đúng).

> Phân biệt với **push partner-photo** (FCM qua Cloud Function — thuộc feature [gallery]).

## 2. Phạm vi
- **Trong:** bật/tắt reminders (xin quyền OS), chọn giờ, 4 loại reminder, reschedule khi đổi anniversary/đăng ảnh.
- **Ngoài:** reminder tuỳ chỉnh do user tạo, reminder theo sự kiện lịch (→ shared-calendar tương lai).

## 3. Code liên quan
- `lib/providers/reminder_provider.dart` (what — Hive box `reminder_settings`), `lib/services/reminder_service.dart` (how — channel `love_reminders`, id 1001-1005)
- Toggle + time picker ở `lib/screens/profile_screen.dart`

## 4. Acceptance (đã đạt)
- [x] Bật/tắt + chọn giờ; xin quyền OS trước khi bật
- [x] 4 loại reminder schedule đúng; id cố định để reschedule thay thế (không chồng)
- [x] `initialize()` không throw (không chặn launch); text đa ngôn ngữ qua AppL10n

## 5. Nợ kỹ thuật / rủi ro
- 🟡 **Permission denied → enabled=false im lặng**, không có nút "Grant Permission" dẫn ra OS settings. Android `requestNotificationsPermission()` trả null bị coerce true → silent fail.
- 🟡 **Anniversary tương lai → bỏ schedule milestone im lặng** (`reminder_provider` ~213).
- 🟡 [CẦN TEST] DST/timezone: giờ static hour:minute, qua DST có thể lệch 1h tới khi restart; daily fallback UTC nếu lấy tz lỗi.
- 🟡 `setTime` không bound-check hour/minute.
- 🟡 Android dùng `inexactAllowWhileIdle` → reminder có thể không đúng phút tuyệt đối (chấp nhận được, nhưng cần biết).

## 6. Changelog
- [2026-05-30] [PO] Tài liệu hoá feature đã ship + rủi ro từ catalog logic.
