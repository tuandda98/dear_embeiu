# Đánh giá app · Góp ý · Báo lỗi

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.

- **Feature:** feedback
- **Ưu tiên:** P1
- **Trạng thái:** 🏗️ Đang làm
- **Tạo ngày:** 2026-10-29
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị

- *Vấn đề:* app có 165 user (PROD 2026-10-19) mà gần như không có đánh giá trên store, và không có kênh nào để user báo lỗi. Lỗi chỉ được biết khi Crashlytics bắt được hoặc khi người quen nhắn riêng.
- *Giả thuyết:* hỏi sao đúng lúc vui (vừa mở khoá câu trả lời của nhau, vừa đăng ảnh) thì người thích app sang store chấm 5 sao; người chưa thích thì nói lý do cho mình thay vì chấm 1 sao trên store.
- *Đo bằng gì:* số đánh giá store mỗi tháng · điểm trung bình store · số góp ý/báo lỗi nhận được mỗi tuần.

## 2. Quyết định (user chốt 2026-10-29)

- **D1 — Hỏi sao trước rồi chia nhánh.** Thẻ trong app hỏi 1–5 sao. 4–5 sao → hộp đánh giá gốc của store (package `in_app_review`; không hiện được thì mở trang store). 1–3 sao → form góp ý, điền sẵn số sao.
- **D2 — Tự mời sau khoảnh khắc vui.** Lúc cả hai vừa mở khoá câu trả lời hôm nay, hoặc vừa đăng ảnh xong. Điều kiện: cài ≥ 7 ngày, mở app ≥ 5 lần, lần mời trước cách ≥ 90 ngày, chưa từng chấm 4–5 sao. Bấm "Để sau" cũng tính là đã mời (đợi 90 ngày).
- **D3 — Góp ý & báo lỗi lưu Firestore + email.** Collection `feedback` (chỉ tạo, app không đọc lại). Mỗi tin: loại (góp ý / lỗi / đánh giá thấp), nội dung, số sao nếu có, tuỳ chọn 1 ảnh chụp màn hình, phiên bản + build, nền tảng + phiên bản hệ điều hành, đời máy, ngôn ngữ. Cloud Function gửi email về `thesavior9820@gmail.com` qua Resend (secret `RESEND_API_KEY` đã có).
- **D4 — Lối vào.** Cài đặt có 2 mục: "Đánh giá Dear Embeiu" và "Góp ý & báo lỗi". Cả bản Cài đặt rút gọn (chưa ghép đôi) cũng có "Góp ý & báo lỗi".

## 3. Acceptance criteria

1. Cài đặt → "Đánh giá Dear Embeiu" mở thẻ 5 sao. Chấm 5 → hộp đánh giá của store hiện (máy thật, bản store); chấm 2 → form góp ý mở, đã ghi "2 sao".
2. Thẻ tự hiện ≤ 1 lần/90 ngày, chỉ sau mở khoá câu trả lời hoặc đăng ảnh, chỉ khi đủ 7 ngày + 5 lần mở. Đã chấm 4–5 sao thì không bao giờ tự hiện nữa.
3. Gửi góp ý 1 dòng chữ + 1 ảnh → trong 1 phút có doc ở `feedback` và email tới hộp thư trên, email có nội dung, thông tin máy, link ảnh.
4. Mất mạng lúc gửi → báo lỗi rõ ràng, nội dung đang gõ không mất.
5. Người chưa đăng nhập không gửi được (rules chặn). Nội dung ≤ 2000 ký tự, ảnh ≤ 10 MB và phải là ảnh.
6. vi + en đầy đủ; copy xưng "chúng mình".

## 4. Ngoài phạm vi

- Màn xem lại góp ý đã gửi, trả lời user trong app.
- Lắc máy để báo lỗi.
