# Chat status (đang gửi / đã gửi / đã nhận / đã đọc)

> File PO sở hữu. Nguồn sự thật cho feature.

- **Feature:** chat-status
- **Ưu tiên:** P1 (table-stake chat)
- **Trạng thái:** 🚧 Code-level xong — DEV deployed, chờ smoke-test 2 thiết bị
- **Tạo ngày:** 2026-06-18
- **Liên quan:** [dev.md](dev.md) · feature [`../chat/`](../chat/overview.md) · [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị
- *Vấn đề:* chat không cho biết tin đã tới/đã đọc chưa → người gửi mơ hồ ("người ấy đọc chưa?").
- *Giá trị:* trạng thái tin nhắn là table-stake của mọi app chat; với couple còn tăng cảm giác kết nối ("đã đọc").

## 2. Quyết định đã chốt
- **D1 — 4 trạng thái:** Đang gửi (chưa lên server) · Đã gửi (đã lên server) · Đã nhận (máy kia đã nhận) · Đã đọc (máy kia đã mở chat). (User yêu cầu đủ 4.)
- **D2 — Hiện dưới TIN CUỐI CÙNG mình gửi** (chuẩn iMessage/Messenger), không hiện mọi tin → gọn.
- **D3 — Receipt qua subcollection `couples/{id}/receipts/{uid}`** (`deliveredAt`/`readAt` serverTimestamp), mỗi người ghi doc của mình, cả 2 đọc nhau. Không dùng `prefs/home` vì key theo uid động.
- **D4 — Không có toggle tắt "đã đọc"** (app couple, mặc định bật). Có thể thêm sau nếu cần.
- **D5 — Glyph tiến triển** clock → tick rỗng → tick đậm → tick hồng (read) để nhìn phát biết.

## 5. Acceptance criteria
- [x] Tin đang gửi (optimistic/offline) → "Đang gửi…".
- [x] Tin lên server, máy kia chưa nhận → "Đã gửi".
- [x] Máy kia online nhận được → "Đã nhận".
- [x] Máy kia mở chat → "Đã đọc".
- [x] Chỉ hiện dưới tin cuối cùng mình gửi; tin partner không có label.
- [x] Rules additive + test (178 pass); analyze sạch.
- [ ] Smoke-test 2 thiết bị (4 trạng thái chuyển đúng, độ trễ chấp nhận được).
- [ ] PROD rules (chờ user).

## 7. Changelog
- [2026-06-18] [PO/Dev] Tạo feature, code xong, DEV deployed.
