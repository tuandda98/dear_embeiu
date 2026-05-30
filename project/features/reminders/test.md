# 🧪 Test — Reminders

> Tester sở hữu. CHỈ test, KHÔNG sửa code.

- **Trạng thái test:** ⬜ Chưa test có hệ thống

## Test case ưu tiên
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Bật reminders + chọn giờ | Daily nudge đúng giờ | ⬜ |
| 2 | happy | Tới ngày kỷ niệm | Nhận anniversary reminder | ⬜ |
| 3 | edge | Từ chối quyền rồi bật | Có thông báo/nút mở settings (hiện im lặng) | ⬜ |
| 4 | edge | Bật quyền lại trong OS settings | Reminders hoạt động | ⬜ |
| 5 | edge | Đổi anniversary | Reschedule milestone đúng | ⬜ |
| 6 | edge | 7 ngày không đăng ảnh | Inactivity nudge | ⬜ |
| 7 | edge | Milestone (mỗi 100 ngày) + nudge trước 3 ngày | Đúng id, không chồng | ⬜ |
| 8 | edge | Đổi timezone máy rồi restart | Giờ không lệch | ⬜ |
| 9 | i18n | Đổi EN | Nội dung reminder tiếng Anh (đã localize) | ⬜ |
| 10 | negative | setTime giờ/phút ngoài range | Bound-check | ⬜ |

## Nhật ký test
- [2026-05-30] [PO] Tạo bộ case từ catalog logic; chờ Tester chạy.
