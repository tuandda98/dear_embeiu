# Notification center (Trung tâm thông báo)

> File PO sở hữu. Nguồn sự thật chung cho cả feature.

- **Feature:** notifications
- **Ưu tiên:** P1
- **Trạng thái:** 🚧 Dev xong (code-level) — chờ smoke-test 2 thiết bị + GA prod
- **Tạo ngày:** 2026-06-06
- **Liên quan:** [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị
- *Vấn đề:* Push hiện tại là **ephemeral** — user bỏ lỡ/đã tắt thông báo thì mất luôn, không có chỗ xem lại. Tap push chỉ đổi tab, không có lịch sử.
- *Giá trị:* Một nơi xem lại mọi hoạt động của cặp đôi (ảnh, reaction, lời nhắn, câu hỏi ngày, ghép đôi/rời đi), tap → điều hướng tới đúng phần. Tăng quay lại app (North Star: cặp active đăng ảnh/tuần).
- *Đo bằng:* số lần mở notification center, tỉ lệ tap→điều hướng.

## 2. Bối cảnh
- SumOne/Paired đều có inbox thông báo bền vững (Firestore-backed), không phụ thuộc push delivery.

## 3. Phạm vi
- **Trong phạm vi (v1):** 6 loại sự kiện cặp đôi (photo_posted, photo_reaction, partner_joined, partner_left, love_note, daily_question). Bell + badge ở header Home. Màn list: xem lại, tap→điều hướng tab, vuốt xoá, đánh dấu đã đọc, xoá tất cả.
- **Ngoài phạm vi (v1):** nhắc nhở local (love reminders/cột mốc/custom) — thuần local, kém tin khi app kill; deep-link tới đúng ảnh cụ thể (chỉ tới tab); cài đặt bật/tắt từng loại.

## 4. Quyết định đã chốt (decision log)
- **D1 — Firestore-backed (KHÔNG local-only).** *Lý do:* push ephemeral; local-only mất thông báo khi app bị kill (iOS không chạy background handler đáng tin). CF ghi 1 doc `users/{uid}/notifications` mỗi lần gửi push; client nghe stream → bền vững qua kill/reinstall, sync đã-đọc.
- **D2 — Lưu structured data, render text theo locale hiện tại.** *Lý do:* push localize theo ngôn ngữ thiết bị lúc gửi; inbox phải khớp ngôn ngữ app hiện tại → lưu `type`+`actorName`+ids, render bằng AppLocalizations.
- **D3 — Scope stream theo `coupleId == current`.** *Lý do:* tự ẩn thông báo của couple cũ sau khi rời/đổi couple, không cần cleanup server.
- **D4 — Rules ADDITIVE, client KHÔNG create.** *Lý do:* backend prod dùng chung mọi version app; subcollection mới → app cũ bỏ qua. Chỉ CF (admin) create; client chỉ read/mark-read/delete của mình.
- **D5 — Cap 50 + index (coupleId asc, createdAt desc).** Giới hạn growth, phân trang ngầm.

## 5. Acceptance criteria (xong khi…)
- [ ] Mỗi push (6 loại) tạo 1 doc inbox cho đúng recipient (không tự-thông-báo-mình).
- [ ] Bell ở header Home hiện badge số chưa đọc; cập nhật live khi push tới lúc app mở.
- [ ] Mở center thấy list newest-first, render đúng ngôn ngữ hiện tại; tap → đổi đúng tab (ảnh→Gallery, còn lại→Home), đánh dấu đã đọc.
- [ ] Vuốt xoá 1 item; "xoá tất cả" có xác nhận; "đánh dấu đã đọc" cho tất cả.
- [ ] App cũ 1.0/1.1 KHÔNG vỡ (rules additive — đã có rules unit test).
- [ ] Xoá tài khoản → xoá luôn `users/{uid}/notifications` (Apple 5.1.1(v)).
- [ ] Tap vào nội dung đã xoá (ảnh) → về Gallery, không crash.

## 6. Nợ kỹ thuật / rủi ro
- `partner_left` trước đây thiếu nhánh tap trong push handler → đã vá.
- Notifications couple cũ còn nằm Firestore sau khi rời (ẩn bởi filter coupleId, dọn khi xoá tài khoản) — v2 có thể dọn server-side khi leave.
- Local reminders chưa vào inbox (v2).
