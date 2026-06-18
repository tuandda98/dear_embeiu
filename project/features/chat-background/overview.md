# Chat background (ảnh nền đoạn chat)

> File PO sở hữu. Nguồn sự thật chung cho cả feature.

- **Feature:** chat-background
- **Ưu tiên:** P2 (personalization / giữ chân)
- **Trạng thái:** 🚧 Dev xong code-level — chờ smoke-test + deploy rules
- **Tạo ngày:** 2026-06-18
- **Liên quan:** [dev.md](dev.md) · feature [`../chat/`](../chat/overview.md) · [`../counter/`](../counter/overview.md) (pattern ảnh nền thẻ đếm) · [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị
- *Vấn đề:* màn Chat chỉ có gradient hồng cố định — cặp đôi muốn cá nhân hoá bằng ảnh kỷ niệm của họ.
- *Giả thuyết:* cho phép đặt ảnh nền chat → tăng cảm giác "không gian riêng của 2 người" → mở app/chat nhiều hơn.
- *Đối tượng:* cả 2 người trong couple (nền dùng chung).

## 2. Quyết định đã chốt (decision log)
- **D1 — Nền dùng CHUNG cho cả 2** (đồng bộ qua `couples/{id}/prefs/home.chatBgPhotoId`). *Lý do:* đúng tinh thần "không gian chung", tái dùng pattern `prefs/home` đã có. (User chốt 2026-06-18.)
- **D2 — Nguồn ảnh = thư viện ảnh chung của couple** (giống picker "Ảnh nền thẻ đếm"), KHÔNG mở device picker. *Lý do:* "duyệt/lọc ảnh hợp lệ" = duyệt ảnh đã có.
- **D3 — Chọn 1 ảnh** (không phải whitelist cycle như counter-bg). Có tile "Mặc định" để xoá nền về gradient.
- **D4 — "Kích thước hợp lệ" = ảnh DỌC + ĐỦ NÉT:** cao ≥ rộng (portrait/vuông) VÀ cạnh ngắn (rộng) ≥ 720px. Ảnh ngang / quá nhỏ bị ẩn khỏi picker. *Lý do:* nền phủ kín màn dọc, ảnh ngang/nhỏ sẽ bị cắt mạnh hoặc vỡ nét. (User chốt 2026-06-18.)

## 3. Phạm vi
- **Trong phạm vi:** 1 mục Settings → màn picker lọc ảnh hợp lệ + chọn 1 ảnh/Mặc định; render nền sau hội thoại; đồng bộ 2 máy; offline-cache.
- **Ngoài phạm vi:** crop/chỉnh ảnh trong app; nền riêng từng người; nền động/theme.

## 5. Acceptance criteria (xong khi…)
- [x] Settings có mục "Ảnh nền đoạn chat" mở picker.
- [x] Picker CHỈ hiện ảnh dọc + cạnh ngắn ≥ 720px (decode kích thước thật để lọc); ảnh ngang/nhỏ không xuất hiện.
- [x] Có tile "Mặc định" để về gradient.
- [x] Chọn + Save → nền chat đổi; đồng bộ sang máy kia qua `prefs/home.chatBgPhotoId`.
- [x] Có scrim đủ để bong bóng/ngày tháng đọc rõ trên ảnh.
- [x] `flutter analyze` sạch (4 file feature); rules emulator test pass (172).
- [ ] Smoke-test 2 thiết bị (đồng bộ + offline).
- [ ] Deploy rules DEV/PROD (chờ user — xem dev.md).

## 7. Changelog feature
- [2026-06-18] [PO/Dev] Tạo feature, chốt D1–D4, code xong code-level.
