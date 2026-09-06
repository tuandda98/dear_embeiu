# 💻 Dev — Counter

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md).

- **Trạng thái dev:** ✅ Đã implement (baseline)

## Đã implement
- `CounterData` tính days/months/years từ anniversary (months≈30 ngày). `CounterCard` hero. Milestone bar + quote + recent carousel ở `home_screen.dart`.

## Việc cần làm tiếp
- [ ] Ngày tháng locale-aware (làm chung với gap A của feature [language](../language/dev.md)).
- [ ] Xử lý anniversary = hôm nay / tương lai rõ ràng (không im lặng).
- [ ] Rà sai số mốc do months≈30 ngày (cân nhắc tính theo lịch thực).
- [ ] [CẦN TEST] múi giờ, năm nhuận.

## Nhật ký implement
- [2026-05-30] [PO] Khởi tạo doc.

- [2026-06-21] [dev/lead] **Ảnh nền CounterCard rõ nét — bỏ lớp sáng trắng + blur** (user: "card có lớp sáng trắng làm mờ background, muốn ảnh rõ nét"). 3 thủ phạm trong `counter_card.dart`: (1) **3 aurora glow** (`_buildGlow`, glow đầu mặc định `AppColors.white` .42) vẽ đè ảnh → gate `if (!_hasPhoto)` (chỉ glow trên card gradient hồng, có ảnh thì bỏ); (2) **blur theo busyness** (`_photoLayer` ImageFiltered tới 3.6 sigma) → BỎ hẳn, ảnh render sắc nét (busyness vẫn đo để tăng scrim đen cho chữ); (3) **bloom trắng sau số hero** (`_buildHeroNumber` BoxShadow trắng .55 blur 48) → gate `!_hasPhoto`, khi có ảnh số "745" dùng **Shadow đen .45 blur 18** cục bộ (đọc rõ mà không phủ trắng ảnh). Giữ scrim đen thích ứng cho text. analyze 0. Client-only. **⚠️ Thay đổi sau khi build 1.3.3 → artifact AAB/IPA hiện CHƯA có; cần rebuild nếu muốn vào 1.3.3.**
