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

## [2026-09-05] Mở rộng: Quan tâm vào DÒNG THỜI GIAN (Nhật ký) — 📋 Brainstorm, chờ user chốt
- **Yêu cầu:** lời quan tâm được lưu và xem lại theo dòng thời gian như câu hỏi hằng ngày.
- **Hiện trạng:** Nhật ký chỉ liệt kê ngày có cả 2 câu trả lời (`JournalDay`), phân trang theo marker `dailyAnswers`. Lời quan tâm đã nằm vĩnh viễn ở `careMessages` (createdAt), chỉ chưa có chỗ xem lại ngoài "Đã gửi gần đây" (20 tin) và Trung tâm thông báo.
- **Đề xuất (client-only, không đổi rules):**
  1. Nhật ký thành **timeline theo ngày**: mỗi thẻ ngày = câu hỏi + 2 câu trả lời (nếu có) **+ dải "Quan tâm"** liệt kê lời nhắn 2 chiều trong ngày (avatar chữ cái người gửi + title, chạm mở body; >3 tin hiện "+k"). Ngày **chỉ có quan tâm** vẫn hiện (thẻ nhẹ hơn, không câu hỏi).
  2. Tải: query `careMessages orderBy createdAt desc` theo cửa sổ ngày của trang Nhật ký đang xem, gộp client-side vào `JournalDay` (thêm `careNotes: List<CareMessage>`). Ngày không có marker nhưng có note → tạo thẻ "chỉ note".
  3. Trung tâm thông báo: tap `care_message` → mở **Nhật ký đúng ngày** (thay vì về Home) — tái dùng cơ chế `focusDate` của daily_question.
  4. Profile: ô "Nhật ký" giữ số câu hỏi; thêm dòng phụ "+N lời quan tâm" (tuỳ chọn).
  5. Lọc nhanh trên Nhật ký: chip "Tất cả · Câu hỏi · Quan tâm" (P2, làm sau nếu cần).
- **Edge:** couple gửi nhiều tin/ngày → gom + "+k"; múi giờ 2 máy khác nhau → ngày tính theo giờ máy đang xem (chấp nhận, giống mood); tin do mình gửi hiện "Mình", của người ấy hiện tên.
- **Ước lượng:** 0.5–1 ngày Dev, không deploy.
