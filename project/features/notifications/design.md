# Notifications — Design

> File Designer sở hữu. Theo design-system "Sunset Romance" ([`../../design-system.md`](../../design-system.md)).

## Bell (header Home)
- **2026-06-08:** gỡ nút trái tim cạnh chuông (shortcut sang Profile — trùng tab Profile ở thanh dưới); header phải giờ **chỉ còn chuông**.
- Pill glass góc phải header (nền trắng alpha 0.16, radius 18, viền trắng alpha 0.18). Glyph chuông = **Lottie** `assets/lottie/notification_bell.json` (lắc/ring khi `unread > 0`, đứng yên khi 0), **fallback** `Icons.notifications_none_rounded` nếu thiếu/hỏng file (không crash), ép trắng bằng `ColorFiltered(srcATop)` cho khớp chrome. Thả file khác vào đúng path để đổi animation, không đụng code.
- Badge: pill `accentLoveDeep`, viền trắng 1.5, text trắng w800 size 10, số chưa đọc (>99 → "99+"), góc trên-phải. Ẩn khi unread = 0.
- Tap → push `NotificationCenterScreen` (MaterialPageRoute, haptic selectionClick).

## NotificationCenterScreen — Redesign v2 (2026-06-08, "brand glass")
> User yêu cầu thiết kế lại: bản v1 (dưới) là Material phẳng `bgLight` → **lạc tông** so với Home/Gallery (gradient + glass). Chốt hướng **"Glass trên nền gradient"**.
- **Nền:** `Container(gradient: secondaryGradient = dawnBlush)` + `SafeArea(bottom:false)` — y hệt Home (không Scaffold trắng, không AppBar mặc định).
- **Header custom** (kiểu Home, không AppBar): Row[ nút back glass `LucideIcons.arrowLeft` (pill trắng alpha 0.16, viền 0.18, icon trắng — khớp bell/tim Home) · Spacer · `⋯` glass `LucideIcons.moreHorizontal` (PopupMenu mark-all-read/clear-all, chỉ khi có item) ]. Dưới: tiêu đề `AppTheme.pageTitleStyle()` (trắng, khớp "Home") + subtitle `pageSubtitleStyle()` = "{n} chưa đọc" / "Hai bạn đã xem hết rồi 💛".
- **Gom nhóm thời gian:** section "HÔM NAY" / "TRƯỚC ĐÓ" (`notifGroupToday/Earlier`, uppercase trắng alpha 0.92, w800 letter-spacing) — chia theo calendar-day của `createdAt`.
- **Tile = `GlassCard`** (blur 14, radius 22, `padding:zero` + `InkWell` bên trong để có ripple). Chưa đọc: `fillAlpha 0.30` + `borderColor accentLove` `borderAlpha 0.75` (viền hồng) + title w700 + chấm `accentLove` 9px. Đã đọc: `fillAlpha 0.18`, viền trắng 0.30, title w600. Chữ trong tile dùng `textPrimary` (navy) + alpha 0.70 (subtitle) / 0.50 (time) cho tương phản trên glass (theo fix "navy text on cards").
- **Avatar tròn 44** (`shape: circle`, nền màu-type alpha 0.18) + **Lucide** theo type: `image` (photo) · `heart` (reaction) · `heartHandshake` (joined) · `heartCrack` (left) · `mail` (note) · `messageCircle` (daily-q) · `bell` (unknown).
- **Vuốt xoá** (endToStart): `ClipRRect(22)` bọc Dismissible → nền đỏ bo tròn + `LucideIcons.trash2`.
- **Empty state:** đặt trong `GlassCard` (radius 28) căn giữa — vòng tròn accentLove + `LucideIcons.bellOff` + tiêu đề/mô tả navy.
- **GlassCard** thêm param optional `borderColor` (default trắng, backward-compat) để tile chưa-đọc ring hồng.

## NotificationCenterScreen — v1 (đã thay 2026-06-08, giữ tham khảo)
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
