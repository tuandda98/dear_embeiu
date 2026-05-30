# 🧪 Test — Coupling

> Tester sở hữu. CHỈ test, KHÔNG sửa code.

- **Trạng thái test:** ⬜ Chưa test có hệ thống (có couple_model unit mỏng)

## Test case ưu tiên
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | A tạo couple → B nhập mã → ghép | active, cả 2 in_couple | ⬜ |
| 2 | race | 2 người nhập cùng 1 mã đồng thời | Chỉ 1 thắng (transaction) | ⬜ |
| 3 | edge | A leave trước khi B join | Mã invalid, A về single | ⬜ |
| 4 | edge | Nhập mã của chính mình | Bị chặn | ⬜ |
| 5 | edge | Cả 2 cùng leave | Không state lạ, không ảnh orphan | ⬜ |
| 6 | security | User thường đọc toàn bộ `invite_codes` | Nên chặn (hiện đọc được) | ⬜ |
| 7 | security | Owner sửa `invite_codes.coupleId` | Nên chặn (hiện sửa được) | ⬜ |
| 8 | security | Non-member đọc couple waiting_partner (đoán coupleId) | Nên chặn | ⬜ |
| 9 | negative | Invite `"  abc 123  "` / 1000 ký tự | Normalize/reject đúng | ⬜ |
| 10 | edge | Join couple đã đủ 2 người | Reject | ⬜ |

*Rules cần Firebase emulator (chưa cấu hình).*

## Nhật ký test
- [2026-05-30] [PO] Tạo bộ case từ catalog; chờ Tester chạy.
