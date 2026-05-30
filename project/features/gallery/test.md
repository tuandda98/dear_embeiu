# 🧪 Test — Gallery

> Tester sở hữu. CHỈ test, KHÔNG sửa code.

- **Trạng thái test:** ⬜ Chưa test có hệ thống (có photo_model unit mỏng)

## Test case ưu tiên
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Đăng ảnh đơn + caption | Hiện ở cả 2 máy realtime | ⬜ |
| 2 | happy | Đăng nhiều ảnh | Tất cả lên feed | ⬜ |
| 3 | happy | Partner đăng → push | Người kia nhận notification | ⬜ |
| 4 | edge | Đăng ảnh offline rồi online | Re-upload (hiện local-only mãi) | ⬜ |
| 5 | edge | Xoá ảnh khi máy kia đang xem | Đồng bộ, không crash | ⬜ |
| 6 | edge | 2 người đăng cùng lúc | Merge đúng | ⬜ |
| 7 | security | Member xoá ảnh của partner | Nên chặn (hiện cho phép) | ⬜ |
| 8 | security | Upload non-image gắn image/png | Nên chặn | ⬜ |
| 9 | security | Upload >10MB / người ngoài couple | Chặn | ⬜ |
| 10 | edge | Caption 100K ký tự + nhiều \n | Giới hạn/không vỡ | ⬜ |
| 11 | i18n | Ngày feed khi EN | Không còn "thg" (gap A) | ⬜ |
| 12 | i18n | Push khi người nhận EN | Tiếng Anh (gap B) | ⬜ |

## Nhật ký test
- [2026-05-30] [PO] Tạo bộ case từ catalog; chờ Tester chạy.
