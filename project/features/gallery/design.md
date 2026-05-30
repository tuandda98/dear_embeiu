# 🎨 Design — Gallery

> Designer sở hữu. Đọc [overview.md](overview.md). Bám design system (`../../../CLAUDE.md` mục 8).

- **Trạng thái design:** ✅ Đã có (baseline)

## Hiện trạng UI (đã ship)
- **Feed dọc** (KHÔNG grid). CustomScrollView: SliverPersistentHeader co giãn (expanded 340/compact 122, snap 250ms) chứa composer card (avatar gradient + nút thêm 1/nhiều ảnh + marquee chip) → CTA "hôm nay" → feed card (avatar+tên+time+menu, ảnh Hero 4:5 bo 26, caption) ngăn theo tháng.
- **Fullscreen preview:** PageView swipe, InteractiveViewer pinch zoom (max 4×), drag-to-dismiss dọc (nền fade .94→.2, threshold 140px), panel info + nút edit/close.

## Đề xuất cải thiện (bàn PO — gắn retention)
- **Reactions ❤️ trên ảnh** (roadmap NOW) — thiết kế nút thả tim + hiển thị + push.
- Thiết kế giới hạn/nén ảnh (UX khi ảnh quá lớn) + trạng thái offline rõ ("chưa đồng bộ").
- Empty state đẹp khi chưa có ảnh.

## Copy (song ngữ)
Key gallery (upload/caption/delete…) đã có VI+EN.

## Nhật ký design
- [2026-05-30] [PO] Ghi nhận hiện trạng UI từ CLAUDE.md mục 8.
