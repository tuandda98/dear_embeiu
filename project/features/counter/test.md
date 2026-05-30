# 🧪 Test — Counter

> Tester sở hữu. CHỈ test, KHÔNG sửa code.

- **Trạng thái test:** ⬜ Chưa test có hệ thống

## Test case ưu tiên
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Anniversary 1 năm trước | Hiển thị đúng 1 năm / số ngày | ⬜ |
| 2 | edge | Anniversary = hôm nay | 0 ngày, "hôm nay là kỷ niệm" | ⬜ |
| 3 | negative | Anniversary tương lai | Xử lý rõ, không milestone im lặng | ⬜ |
| 4 | edge | Năm nhuận (29/2) | Tính đúng | ⬜ |
| 5 | edge | Đổi timezone máy | Số ngày không nhảy sai | ⬜ |
| 6 | i18n | Đổi EN | Ngày hiển thị format EN (gap A) | ⬜ |
| 7 | edge | Mốc milestone (chạm 100, 365…) | Bar + đếm ngược đúng | ⬜ |
| 8 | edge | months≈30 vs lịch thực | Sai số chấp nhận được? | ⬜ |

## Nhật ký test
- [2026-05-30] [PO] Tạo bộ case; chờ Tester chạy.
