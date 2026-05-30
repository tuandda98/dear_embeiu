# 🎨 Design — Counter

> Designer sở hữu. Đọc [overview.md](overview.md). Bám design system (`../../../CLAUDE.md` mục 8).

- **Trạng thái design:** ✅ Đã có (baseline)

## Hiện trạng UI (đã ship)
- **CounterCard:** HERO gradient `sunsetRomance` bo 28; số ngày `dayCountStyle()` = 76px serif w500 ls -2.4 + glow trắng.
- **Home Tab:** header → hero glass (greeting + animated couple name "P1 ♥ P2" heart pulse 820ms) → CounterCard → quick-action cards → **milestone progress bar** → quote card → recent photos ngang (140×176).
- Ngày dạng `dd/MM/yyyy` (Profile) — ⚠️ sẽ đổi sang locale-aware theo decision D3 của [language].

## Đề xuất cải thiện (bàn PO)
- Cho user chọn cách hiển thị (ngày / tuần / "X năm Y tháng") — tuỳ chọn.
- Hiệu ứng ăn mừng khi chạm milestone (confetti nhẹ) — gắn với retention.

## Nhật ký design
- [2026-05-30] [PO] Ghi nhận hiện trạng UI từ CLAUDE.md mục 8.
