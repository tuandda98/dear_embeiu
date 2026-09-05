# Quan tâm (care message)

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.

- **Feature:** care-message
- **Ưu tiên:** P1
- **Trạng thái:** 🛠 Dev (client xong, chờ test)
- **Tạo ngày:** 2026-09-05
- **Liên quan:** [dev.md](dev.md) · [test.md](test.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Mục tiêu
- Cho phép một người soạn **1 tin nhắn quan tâm** (tiêu đề + nội dung) gửi thẳng cho người ấy.
- Người ấy nhận **push hiện đúng nguyên văn** tiêu đề/nội dung (khác mọi push khác vốn content-free) + **1 item trong Notification center** đọc lại được.
- Có 6 mẫu gợi ý nhanh (nhớ / uống nước / ăn cơm / ngủ sớm / yêu / cố lên) để gửi trong 2 chạm.

## 2. Hợp đồng dữ liệu (chốt với backend)
- `couples/{coupleId}/careMessages/{autoId}` — ĐÚNG 4 field `{authorUserId, title (1..60), body (1..200), createdAt == request.time}`; update/delete cấm; member đọc được.
- Push data `{type:'care_message', coupleId, careMessageId}`; notification title/body = nguyên văn.
- Inbox `users/{uid}/notifications/{id}`: `{type:'care_message', coupleId, actorUserId, actorName, careMessageId, title, body, createdAt, read}`.

## 3. Ngoài phạm vi (v1)
- Không sửa/xoá tin đã gửi · không rate-limit phía client · không màn hình riêng khi tap push (chỉ về Home).
