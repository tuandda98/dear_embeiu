# 🧪 Test — Auth

> Tester sở hữu. Đọc cả 3 file kia. CHỈ test, KHÔNG sửa code. Output PASS/FAIL.

- **Trạng thái test:** ⬜ Chưa test có hệ thống (mới có 1 test render login + auth_service unit mỏng)

## Test case ưu tiên
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Đăng ký → đăng nhập → đăng xuất (Firebase) | Hoạt động, session persist | ⬜ |
| 2 | happy | Tương tự ở **local fallback** (Firebase off) | Hoạt động, KHÁC nhánh | ⬜ |
| 3 | negative | Email `a@b@c.com`, `@x.com`, `test@` | Nên reject (hiện chỉ check `@`) | ⬜ |
| 4 | negative | Password `123456`, displayName 10K ký tự + emoji | Nên reject/giới hạn | ⬜ |
| 5 | security | Đọc/sửa doc user khác | Rules chặn | ⬜ |
| 6 | security | Local fallback: password lưu plaintext? | Xác nhận lỗ hổng | ⬜ |
| 7 | edge | Reinstall → purge session | Không còn session cũ | ⬜ |
| 8 | edge | deleteAccount khi đang trong couple | Demote partner đúng, không xoá nhầm | ⬜ |
| 9 | edge | deleteAccount chưa auth / account khác | Chặn (dựa request.auth.uid) | ⬜ |
| 10 | edge | Resume app → refresh FCM token | Token cập nhật | ⬜ |

## Nhật ký test
- [2026-05-30] [PO] Tạo bộ case từ catalog logic/security; chờ Tester chạy.
