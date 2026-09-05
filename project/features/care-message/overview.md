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

## [2026-09-05] Mở rộng: DÒNG THỜI GIAN QUAN TÂM riêng (như Nhật ký câu hỏi, nhưng TÁCH BIỆT) — 📋 Brainstorm, chờ user chốt
- **Yêu cầu (user chốt 2026-09-05):** lời quan tâm có dòng thời gian **riêng**, giống cách Nhật ký lưu câu hỏi hằng ngày; **KHÔNG trộn** vào Nhật ký câu hỏi theo ngày.
- **Hiện trạng:** `careMessages` lưu vĩnh viễn (createdAt), chỉ xem được 20 tin ở "Đã gửi gần đây" và trong Trung tâm thông báo.
- **Đề xuất (client-only, không đổi rules):**
  1. Màn mới **"Dòng thời gian quan tâm"** (`care_timeline_screen.dart`): header chip-only "QUAN TÂM", danh sách **gom theo ngày** (nhãn ngày kiểu Nhật ký: Hôm nay / Hôm qua / dd MMM), mỗi tin = thẻ nhỏ có avatar chữ cái người gửi (Mình / tên người ấy), title đậm + body trọn, giờ gửi. Phân trang cuộn vô hạn 30 tin/lần (`orderBy createdAt desc`, `startAfter`). Trạng thái rỗng: minh hoạ + nút "Gửi lời quan tâm đầu tiên".
  2. Điểm vào: (a) màn "Gửi quan tâm" — mục "Đã gửi gần đây" đổi thành 5 tin gần nhất + nút "Xem tất cả" → timeline; (b) Profile: tile "Gửi quan tâm" thêm dòng phụ "N lời quan tâm · Xem dòng thời gian" hoặc tile riêng "Dòng thời gian quan tâm" (chọn 1 khi design); (c) Trung tâm thông báo: tap `care_message` → mở timeline **cuộn tới đúng tin** (highlight nhẹ) thay vì về Home.
  3. Lọc nhanh (P2): chip "Tất cả · Mình gửi · Người ấy gửi".
  4. Thống kê nhỏ ở đầu màn (P2): tổng số lời quan tâm + số ngày liên tiếp có gửi (không phải chuỗi chính, chỉ trang trí).
- **Edge:** tin cùng ngày nhưng 2 máy khác múi giờ → gom theo giờ máy đang xem (giống mood); tin dài 200 ký tự hiện trọn (đã vá overflow); người dùng cũ chưa có tin → empty state.
- **Ước lượng:** ~0.5–1 ngày Dev, không deploy backend. Có thể làm chung 1 agent với việc đổi "Đã gửi gần đây" → "Xem tất cả".
