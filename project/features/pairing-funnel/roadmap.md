# 🗺️ Roadmap — pairing-funnel

> PO sở hữu. Roadmap riêng của feature. Toàn cảnh dự án ở [`../../ROADMAP.md`](../../ROADMAP.md).

## Now — đợt 2026-10-11 (đề xuất 1–3 của phân tích phễu)
- [x] Đăng nhập với Apple (iOS) + thu hồi token khi xoá tài khoản (PF1–PF6, PF11)
- [x] Mã QR ở Setup / thẻ chờ Home / Profile (PF7)
- [x] Trang get chép link mời, Setup gợi ý mã từ bộ nhớ tạm (PF8, PF9, PF12, PF13)
- [x] Lời nhắc mời dồn vào 24 giờ đầu, thôi sau 7 ngày (PF10)
- [ ] Chạy trên máy thật (17 case ⏳ trong `test.md`)
- [ ] Điều kiện release: bật Apple trên PROD, khoá .p8, capability App ID, đẩy `get.html` SAU khi bản mới live

## Next — khi đợt Now có số liệu (2–4 tuần sau release)
- Đo lại: tỉ lệ người đăng ký vào couple, % kẹt xác thực email, thời gian từ tạo couple tới ghép.
- Đăng nhập với Google (Android + tuỳ chọn trên iOS) nếu Android tăng hoặc người dùng hỏi.
- Huỷ nhắc mời ở isolate nền khi nhận push `partner_joined` (cần CF gửi kèm `wakeClients`), để người ấy vào lúc app A đang tắt thì A không còn nhận "Người ấy chưa vào nè".
- Đề xuất 4: cho người tạo trả lời trước câu hỏi hằng ngày trong lúc chờ, lời mời nói "Mình đã trả lời 3 câu hỏi về chúng mình, vào đọc nhé".

## Later
- Tự ghép đôi bằng universal link / App Link (`invite-sharing` Phase 3), bỏ hẳn bước nhập mã.
- Đăng nhập Apple trên Android (cần Services ID + web flow).
