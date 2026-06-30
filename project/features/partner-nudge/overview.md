# Feature: Nhắc người ấy (partner-nudge)

> PO spec. Vai trò: A chủ động nhắc B qua thông báo — bù cho việc mọi reminder cũ đều LOCAL (người kia không nhận). Bắt đầu 2026-06-29.

## Vấn đề
Trước đây mọi lời nhắc trong app (cột mốc, lời nhắc riêng, daily-Q) đều là **local trên máy người đặt** → partner KHÔNG nhận. User muốn A nhắc được B.

## Phạm vi (đã chốt với user 2026-06-29)
1. **Thúc tức thì (nudge):** A bấm → B nhận push NGAY (kể cả app B đóng).
2. **Đặt lịch nhắc cho người ấy:** A đặt giờ + lặp (once/daily/weekly/monthly/yearly) → đến giờ B nhận thông báo (local trên máy B, đúng múi giờ B).
3. **Nội dung:** chip mẫu có sẵn (Nhớ uống nước / Về nhà thôi / Nhớ em 💕 / Ngủ sớm nha) + ô tự gõ.

Tổng quát hoá feature hardcode "anh By → embe" (uống thuốc) thành tính năng cho mọi cặp.

## Kiến trúc (chốt sau phản biện Plan agent)
- **Nudge → CF push CÓ NỘI DUNG:** A ghi `couples/{id}/nudges/{autoId}` (create-only) → CF `notifyPartnerNudge` đẩy push (body = text gốc, khác chat content-free; theo pattern love-note) + ghi inbox. KHÔNG presence-suppress (nudge luôn báo). Chống spam: cooldown 30s client.
- **Đặt lịch → LOCAL-on-B + CF confirm:** A ghi `couples/{id}/partnerReminders/{autoId}` → app B watch (session_resolver) → B schedule LOCAL notification (band 3000–3049). Lưu `minuteOfDay` (phút wall-clock) → fire theo `tz.local` của B. CF `notifyPartnerReminderSet` đẩy 1 push xác nhận khi A đặt → vừa báo B, vừa **đánh thức B mở app arm lịch** (vá điểm yếu local-on-B).
  - Quyền: author tạo/sửa/xoá lịch của mình; cả 2 member read. B chỉ arm local doc do **partner** tạo (cho mình); A không arm doc chính mình tạo.

## Nợ kỹ thuật / hạn chế đã biết
- **Độ tin cậy lịch (local-on-B):** nếu B lâu không mở app, lịch mới/đổi chưa được nạp → có thể miss (giống mọi reminder local). CF confirm-push giảm thiểu. **Fast-follow (chưa làm):** CF `onSchedule` cron backstop quét lịch đến giờ → FCM, cho ca B không mở app.
- **Đổi ngôn ngữ:** local notif của lịch incoming chỉ re-localize ở lần Firestore emit kế / restart (chưa re-arm theo locale change). Chấp nhận v1.
- **Tên người ấy trong local notif:** dùng copy chung "Người ấy nhắc bạn" (không fetch tên partner ở provider). Đủ dùng v1.
- Cap 20 lịch/người (guard client; rules không đếm subcollection).

## Trạng thái
💻 Dev XONG (2026-06-29): rules + 2 CF + test emulator 206 pass · client (model/service/provider/wiring/2 màn/2 entry tap-map/l10n vi+en/analytics) · `flutter analyze` 0. ⏳ chờ deploy DEV + smoke-test 2 thiết bị. Chi tiết: [dev.md](dev.md).
