# 🗺️ Roadmap riêng — Reminders

> Kế hoạch nội bộ feature. Toàn cảnh: [`../../ROADMAP.md`](../../ROADMAP.md). Spec: [overview.md](overview.md).

- **Trạng thái feature:** ✅ Shipped (v1.0.0)

## Phân phase

### 🟢 Phase 1 — Sửa fail im lặng (P1) — chưa bắt đầu
- [ ] Trạng thái permission rõ + nút "Mở cài đặt" khi bị từ chối
- [ ] Fix coerce `requestNotificationsPermission()` null→true (Android)
- [ ] Xử lý anniversary tương lai (không bỏ milestone im lặng)
- [ ] Bound-check hour/minute ở `setTime`
- *Xong khi:* Tester pass case 3/4/10.

### 🟡 Phase 2 — Độ tin cậy lịch (P2) — chưa bắt đầu
- [ ] Xử lý DST/timezone (reschedule khi đổi tz)

### ⚪ Phase 3 (Later)
- [ ] Cho user chọn loại reminder muốn nhận (hiện bật là cả 4)
- [ ] Preview nội dung reminder
- [ ] Reminder tuỳ chỉnh do user tạo (gắn shared-calendar tương lai)

## Mốc đã đạt
- [v1.0.0] 4 loại reminder local (daily/anniversary/milestone/inactivity), text đa ngôn ngữ.

## Ghi chú phụ thuộc
- Reminder tuỳ chỉnh phụ thuộc feature **shared-calendar** (backlog NEXT).
