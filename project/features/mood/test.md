# 🧪 Test — Tâm trạng hôm nay (mood)

> Tester sở hữu. CHỈ test, KHÔNG sửa code. Agent Tester chỉ đọc được file, nên Lead chép kết quả vào đây.

## Audit UI · 2026-10-12 (Tester UI, Lead xác nhận) — 2 P3, có từ 1.3.0

| # | Mức | Chỗ | Kịch bản → hậu quả | Expected | Vá |
|---|---|---|---|---|---|
| U10 | P3 | `lib/widgets/mood_card.dart:518-528` → `lib/providers/mood_provider.dart:126` | Offline/mạng chậm: bấm Lưu thì `await set()` chờ server → sheet không đóng, không spinner, bấm thêm là thêm lệnh ghi; lỗi rules không bắt → sheet kẹt. | Đóng ngay sau cập nhật lạc quan | SU9 |
| U11 | P3 | `lib/services/mood_service.dart:67-70` | Ô ghi chú đếm 100 grapheme, service cắt 100 UTF-16 bằng `substring` → emoji bị cắt không báo, cắt giữa cặp surrogate ra "�". | Không mất chữ | SU10 |

- Đạt: bộ chọn tâm trạng sau `187a1fd` không tràn ở 320×568, 360×640, 844×390 × chữ 100–200% kể cả khi bàn phím mở; sheet dừng dưới status bar; chọn lại đúng tâm trạng cũ thì CF không push (`functions/index.js:877`).
- Kế hoạch vá: [`../../AUDIT-2026-10-12.md`](../../AUDIT-2026-10-12.md).

## Nhật ký test
- [2026-10-12] [Tester] Audit UI 1.8.0/1.9.0: U10, U11 (P3, có từ 1.3.0).
