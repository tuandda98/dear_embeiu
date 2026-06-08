# Notifications — Design

> File Designer sở hữu. Theo design-system "Sunset Romance" ([`../../design-system.md`](../../design-system.md)).

## Bell (header Home)
- Đặt cạnh icon tim ở góc phải header (Row: chuông · 10px · tim). Style glass giống tim hiện có (nền trắng alpha 0.16, radius 18, viền trắng alpha 0.18), icon `Icons.notifications_none_rounded` trắng.
- Badge: pill `accentLoveDeep`, viền trắng 1.5, text trắng w800 size 10, số chưa đọc (>99 → "99+"), góc trên-phải. Ẩn khi unread = 0.
- Tap → push `NotificationCenterScreen` (MaterialPageRoute, haptic selectionClick).

## NotificationCenterScreen
- Scaffold nền `bgLight`, AppBar phẳng (theme) tiêu đề "Thông báo". Action: popup `⋯` → "Đánh dấu đã đọc" (khi có chưa đọc) + "Xoá tất cả" (đỏ, có dialog confirm).
- List newest-first, divider indent 76 (thẳng hàng sau avatar).
- **Item:** avatar tròn-vuông 44 (radius 14) nền màu-theo-type alpha 0.12 + icon Material theo type:
  - photo_posted `photo_outlined` (accentLove) · photo_reaction `favorite_rounded` (accentLoveDeep) · partner_joined `link_rounded` (lavender) · partner_left `link_off_rounded` (textSecondary) · love_note `mail_outline_rounded` (accentLove) · daily_question `chat_bubble_outline_rounded` (lavender) · unknown `notifications_none_rounded`.
  - Title 1 dòng (chưa đọc → w700 + nền item accentLove alpha 0.06; đã đọc → w500 nền trong suốt).
  - Subtitle (love_note: excerpt; photo_posted: caption) tối đa 2 dòng.
  - Thời gian tương đối (tái dùng chuỗi loveNote*).
  - Chấm tròn `accentLove` 9px bên phải khi chưa đọc.
- **Vuốt** trái→phải end (endToStart): nền đỏ nhạt + icon thùng rác → xoá.
- **Empty state:** vòng tròn accentLove alpha 0.10 + chuông 44, tiêu đề + mô tả căn giữa.

## Copy (vi/en) — keys `notif*` trong ARB
Title render theo type với `{name}` (+ `{emoji}` cho reaction). Xem `app_vi.arb`/`app_en.arb`.
