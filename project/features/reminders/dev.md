# 💻 Dev — Reminders

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md).

- **Trạng thái dev:** ✅ Đã implement (baseline)

## Đã implement
- `reminder_provider.dart`: load/setEnabled (xin quyền OS, trả false nếu từ chối)/setTime/sync; persist Hive `reminder_settings`. Hằng số: milestone mỗi 100 ngày, nudge trước 3 ngày, inactivity 7 ngày.
- `reminder_service.dart`: singleton, channel `love_reminders`, id 1001-1005, `initialize()` không throw, Android `inexactAllowWhileIdle`, text từ `AppL10n.strings`.

## Việc cần làm tiếp (từ rủi ro)
- [ ] Trạng thái permission rõ + nút mở OS settings; fix coerce `requestNotificationsPermission()` null→true.
- [ ] Xử lý anniversary tương lai (không bỏ milestone im lặng).
- [ ] Bound-check hour/minute ở `setTime`.
- [ ] [CẦN TEST] DST/timezone — cân nhắc reschedule khi đổi tz.

## Nhật ký implement
- [2026-05-30] [PO] Khởi tạo doc.
