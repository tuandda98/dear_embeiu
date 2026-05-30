# 🎨 Design — Coupling

> Designer sở hữu. Đọc [overview.md](overview.md). Bám design system (`../../../CLAUDE.md` mục 8).

- **Trạng thái design:** ✅ Đã có (baseline)

## Hiện trạng UI (đã ship)
- **setup_screen:** mode selector pill trượt (AnimatedPositioned 260ms easeInOutCubic) chuyển Create ↔ Join. Invite-code card (code 30px w900 ls4 + nút copy). Form card glass, date picker + photo picker (preview tròn 118px). Nút FilledButton.icon. BlockingLoadingOverlay khi xử lý.
- **Home banner:** khi couple chưa đủ 2 người → banner "chờ partner" kèm mã mời để chia sẻ.

## Đề xuất cải thiện (liên quan phễu — bàn với PO)
- Nút **chia sẻ mã** qua share sheet / sao chép nhanh / QR code (giảm ma sát mời).
- Onboarding ngắn giải thích bước ghép đôi (giảm rớt) — xem roadmap "Onboarding".

## Copy (song ngữ)
Các key setup/invite/create/join đã có VI+EN trong ARB.

## Nhật ký design
- [2026-05-30] [PO] Ghi nhận hiện trạng UI từ CLAUDE.md mục 8.
