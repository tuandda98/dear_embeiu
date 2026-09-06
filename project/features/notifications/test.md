# Notifications — Test

> File Tester sở hữu. READ-ONLY với code. Xuất PASS/FAIL.

## Rules unit test (đã có, PASS)
`firebase_rules_test/test/firestore.notifications.test.js` — 13 ca (tổng suite 140 passing):
- create: owner / người khác / chưa auth đều DENIED (admin-only).
- read: owner PASS; người khác / chưa auth DENIED.
- update: owner đổi `read` PASS; đổi field khác DENIED; đổi `read`+field khác DENIED; `read` non-bool DENIED; người khác DENIED.
- delete: owner PASS; người khác / chưa auth DENIED.

## Smoke-test 2 thiết bị (chờ chạy — DEV)
- [ ] A đăng ảnh → B nhận push + 1 item inbox "A vừa đăng ảnh mới"; badge +1; tap → tab Gallery.
- [ ] B thả reaction ảnh A → A có item "B đã thả ❤️ vào ảnh của bạn" → tap Gallery.
- [ ] A viết lời nhắn → B item love_note (kèm excerpt) → tap Home.
- [ ] A trả lời câu hỏi ngày → B item daily_question → tap Home.
- [ ] B join couple của A → A item partner_joined → tap Home.
- [ ] B rời couple → A item partner_left → tap Home (KHÔNG còn no-op).
- [ ] Tự-thao-tác KHÔNG tạo item cho chính mình.
- [ ] Badge cập nhật live khi app đang mở (foreground).
- [ ] Đánh dấu đã đọc / vuốt xoá / xoá tất cả (có confirm) hoạt động + đồng bộ 2 máy.

## Edge cases cần soi
- [ ] App bị KILL khi push tới → mở lại vẫn thấy item (Firestore-backed).
- [ ] Tắt quyền push → inbox VẪN có item (độc lập push delivery).
- [ ] Tap item ảnh đã bị xoá → về Gallery, không crash.
- [ ] Rời/đổi couple → inbox couple cũ KHÔNG hiện (filter coupleId).
- [ ] Xoá tài khoản → `users/{uid}/notifications` bị xoá hẳn.
- [ ] Locale: đổi ngôn ngữ app → text inbox đổi theo (không freeze ngôn ngữ lúc gửi).
- [ ] App cũ 1.0/1.1 trên prod KHÔNG vỡ bởi rules mới (additive — đã có test).
- [ ] >50 thông báo: chỉ hiện 50 mới nhất.

## Font (kèm đợt này)
- [ ] iOS: dấu tiếng Việt (ấ ề ộ ữ) hiển thị đúng, không vỡ, không nháy font lần đầu (Be Vietnam Pro bundled).
- [ ] Toàn app dùng 1 phông; hero/số đếm đậm, body thường — không còn serif Fraunces.
