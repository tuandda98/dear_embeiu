# 🗺️ Roadmap riêng — Custom reminders

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu.

- **Trạng thái feature:** 🧪 Test PASS (logic verified) — chờ user smoke-test runtime để đóng ✅ Done

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — MVP reminder tuỳ chỉnh local (P1) — 📋 Spec
- [ ] Model `CustomReminder` + persist Hive
- [ ] Service schedule 5 kiểu lặp (dải ID 2000+)
- [ ] Provider CRUD + reschedule + cap 20
- [ ] Màn hình danh sách + form thêm/sửa
- [ ] ARB vi/en + gen-l10n
- *Xong khi:* mọi acceptance ở `overview.md` mục 5 đạt + Tester PASS + PO final verify.

### 🟡 Phase 2 — Nâng cấp (Next) — chưa lên lịch
- [ ] Nhắc-trước-X-ngày (lead time) cho reminder tuỳ chỉnh
- [ ] Đồng bộ shared cả couple (Firestore) nếu user đổi ý từ D1
- [ ] Gợi ý reminder mẫu (monthsary tự điền theo anniversary)

### ⚪ Phase 3 (Later) — chưa lên lịch
- [ ] Push FCM để partner cũng được nhắc
- [ ] Gate premium (số lượng reminder / theme) khi có monetization

## Mốc đã đạt
- [2026-05-31] Spec + decision log chốt; pipeline khởi động.

## Ghi chú phụ thuộc
- Kế thừa hạ tầng `ReminderService` (timezone, plugin, permission) của feature `reminders`.
- Analytics đo lường defer tới khi feature analytics có.
