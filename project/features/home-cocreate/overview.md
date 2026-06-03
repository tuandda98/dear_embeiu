# Feature: Home Co-creation Cards (Tier 2 — biến "ghi chú tình yêu" 1 chiều → vòng lặp 2 người)

> PO directive 2026-06-02 (autonomous). User chốt làm HẾT 3 hướng Tier 2, PO tự quyết mọi chi tiết. Mục tiêu: tăng "lý do mở app hằng ngày" (metric Bắc Đẩu = couple active hằng tuần).
> Ràng buộc: **KHÔNG đụng build 1.0(3) đang Apple review** — đây là tính năng **1.1**. Không commit/submit. Backend mới chỉ ADDITIVE.

## 3 sub-feature
### #6 — "Ngày này năm xưa" (On This Day) — client-only
- Card Home có điều kiện: lôi ảnh cũ cùng tháng-ngày, năm trước → "Ngày này {n} năm trước 💞" + caption + tap mở fullscreen.
- Data: KHÔNG backend — query `PhotoProvider` (ảnh đã sync) theo `uploadDate.month/day`, year<nay.
- Chỉ hiện khi có ảnh khớp; không có thì ẩn (không card rỗng).

### #4 — "Lời nhắn của người ấy" (Love Note) — primary, thay card ghi chú tĩnh
- Mỗi người viết 1 lời (≤140 ký tự) → hiện trên Home đối phương; sửa được; push khi đổi.
- Data: `couples/{coupleId}/notes/{uid}` = `{authorUserId, text, updatedAt}` (1 doc/người, ghi đè, chưa lịch sử).
- Rules (ADD): read if member; write if member && noteId==auth.uid && text ≤ 140.
- CF mới: `onDocumentWritten(notes/{noteId})` → push member kia (reuse `sendToRecipientDevices`, type `love_note`). Deep-link tap → Home (NotificationTapRouter).
- Gate khi `waiting_partner` (chưa có partner) → prompt mời.

### #5 — "Câu hỏi mỗi ngày" (Daily Question) — card riêng
- 1 câu hỏi/ngày (bộ curated vi+en, chọn theo day-of-year, **giờ máy local**). Cả 2 trả lời → reveal câu của nhau. Streak ngày liên tiếp.
- Data: `couples/{coupleId}/dailyAnswers/{YYYY-MM-DD}/responses/{uid}` = `{text, answeredAt}`.
- Rules (ADD): read if member; write if member && docId==auth.uid && text ≤ 280.
- Reveal: **client-side** (member đọc được cả 2 doc; "trả lời trước mới xem" chỉ enforce client — chấp nhận v1, couple thiện chí). Ghi rõ giới hạn này.
- CF mới: push "[tên] đã trả lời — mở khoá!" khi partner tạo response. (Daily reminder push: v1 bỏ.)
- Timezone: dùng ngày máy local (LDR khác múi giờ có thể lệch — chấp nhận v1).
- Confetti (đã cài) cho khoảnh khắc reveal.

## PO quyết định chốt
- Layout Home: thay card "Ghi chú tình yêu" tĩnh bằng **#4 Lời nhắn** (primary); thêm **#5 Câu hỏi hôm nay** (card riêng); **#6** card có điều kiện gần recent photos.
- Backend: rules ADDITIVE + 2 CF mới → deploy production (an toàn vì additive, build review không dùng tới). PO verify diff rules chỉ-thêm trước khi deploy.
- `deleteAccount` CF phải dọn `notes` + `dailyAnswers` khi xoá tài khoản.
- Verify: analyze sạch mỗi chặng + smoke test simulator (giới hạn: chỉ xem được màn guest vì không auth được qua simctl → card Home cần user tap-through sáng dậy).

## Changelog
- [2026-06-02] [PO] Chốt scope + decisions. Bắt đầu orchestrate autonomous.
