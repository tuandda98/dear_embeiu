# Design system — Dear Embeiu

> Trích nguyên văn từ CLAUDE.md (Mục 8) trong đợt tái cấu trúc 2026-06-03 để giữ CLAUDE.md gọn. Nội dung KHÔNG đổi. Designer/Dev đọc file này khi cần chi tiết; CLAUDE.md chỉ giữ tóm tắt + link về đây.

## 8. Design system

Brand "Sunset Romance" — romantic minimalism, soft gradient hồng, glassmorphism, serif cho số hero, trái tim là motif chính. Style ở `lib/theme/app_colors.dart` + `app_theme.dart`; chỉ light mode, Material 3.

Màu (AppColors) — 3 gradient chủ đạo (topLeft→bottomRight):
- `sunsetRomance` = [#FF6B9D, #FF8FA3, #FFB6C1] — hero (counter card). Alias `primaryGradient`/`counterGradient`.
- `dawnBlush` = [#FFC1CC, #E8B4D8, #C8A8E9] — nền app & auth/main screen. Alias `secondaryGradient`.
- `dreamyMint` = [#FFD6E0, #E0D4F7, #C6E5D9] — gallery/milestone. Alias `galleryGradient`.

Accent: accentLove #FF4D6D (=accentRose), accentLoveDeep #E63956, accentLavender #A78BFA, accentLavenderDeep #7C5CD6 (label câu trả lời partner trên nền lavender tint .10 — feature couple-journal), accentCoral #FF8FA3, accentGold #E8B4D8.
Surface: bgLight #FAFAFC, surfaceLight #F5F0F5, cardSurface #FFFFFF.
Text: textPrimary #1A1A2E (cũng là nút chính), textSecondary #6B6B7B, textTertiary #A0A0B0, textOnGradient #FFFFFF.
Status: success #66BB6A, error #EF5350, warning #FFA726, info #A78BFA.

Typography (revamp Đợt 1): display/hero = Fraunces (`GoogleFonts.fraunces`, hỗ trợ VN), body/UI = Plus Jakarta Sans (`GoogleFonts.plusJakartaSansTextTheme`). Wired tập trung ở `app_theme.dart` (`_displayBase/_bodyBase`); giữ nguyên size/weight/ls/glow cũ. Hero serif: displayLarge 72/Medium 56/Small 40; `dayCountStyle()` = 76px w500 ls -2.4 + glow trắng. Sans UI: title 20/16/14, body 16/15/13, label 14/12/11. Quy ước letter-spacing: số serif âm, label/caps dương.

Revamp Đợt 1 — hạ tầng mới (2026-06-02, → [`project/features/ui-revamp/`](project/features/ui-revamp/overview.md)):
- Iconography: Material `Icons.*` → Lucide (`lucide_icons`) toàn app; giữ Material `favorite` cho heart (Lucide không có filled heart).
- GlassCard (`lib/widgets/glass_card.dart`): glass THẬT (ClipRRect+BackdropFilter blur 18+fill .16+viền highlight) — thay "glass giả" ở auth/setup/guest/home-hero. KHÔNG dùng cho list cuộn dài (hiệu năng) hay card trắng đặc (settings/profile/gallery feed).
- ShimmerSkeleton (`lib/widgets/shimmer_skeleton.dart`, package `shimmer`): thay `CircularProgressIndicator` ở loader ảnh/nội dung; giữ spinner inline trong nút submit + splash.
- Motion: `AppMotion` (`lib/theme/app_motion.dart`) token fast 200/base 280/slow 320/entrance 360/stagger 50ms, curve easeOutCubic. `flutter_animate` staggered entrance (fadeIn+slideY 8px) cho home/settings/gallery-feed(6 đầu)/reminders — chạy 1 lần (`_OnceEntrance`). `HapticFeedback` ở đổi tab/đăng ảnh/submit/đổi ngày/toggle. Tile bấm → `InkWell` ripple thay `GestureDetector`.
- Trạng thái: dev xong + analyze sạch + smoke-test simulator (guest landing) OK. CHƯA submit/commit (build 1.0(3) đang Apple review — phát hành revamp = 1.1 sau khi 1.0 duyệt). Đợt 2 (splash/counter count-up/invite reveal/gallery shimmer-stagger) chưa làm.

Tokens: radius card lớn = 28 (`cardRadius`); pill = 999; input/nút phụ = 20; tile = 22-24; profile hero = 32. Spacing: 4 · 6-8 · 12-16 · 18-24 · 20. Nút: height 52, ElevatedButton nền navy bo pill. Input: filled surfaceLight bo 20, focus viền accentLove 1.4. AppBar phẳng. FAB tròn accentLove. SnackBar floating navy bo 20.

Components tái dùng (lib/widgets): counter_card (HERO gradient sunsetRomance bo 28), animated_couple_name ("P1 ♥ P2" heart pulse 820ms), shared_couple_photo_view/shared_photo_view (loader local→network→fallback), blocking_loading_overlay, language_toggle_button, invite_action_buttons (cụm "Copy | Share" mã mời — feature invite-sharing P1; 2 biến thể onDark/sáng-rose + iconOnly; share_plus), photo_item + masonry_gallery (⚠️ MasonryGallery KHÔNG dùng — gallery là feed dọc), auth_background (không dùng).

Animation durations chuẩn: heart pulse 820ms · nav pill 320ms easeOutCubic · mode selector 260ms · header snap 250ms · dismiss 220ms · switcher 200ms. → animation mới theo 200-320ms easeOutCubic.

Layout từng screen (luồng: splash `/` → auth_gate → login/register → setup → home):
- splash / auth_gate — nền secondaryGradient, tim trắng 80px, spinner trắng; không animation, chỉ resolve route.
- login / register — nền gradient, header badge eyebrow + pageTitle, form card glass (white alpha .22 bo 28). Field label rose w700, input bo 20 prefix icon rose, nút submit rose. Register thêm: policy disclosure clickable, checkbox điều khoản (bắt buộc tick), link privacy. LanguageToggle góc trên phải.
- setup_screen — tạo/join couple. Mode selector pill trượt (AnimatedPositioned 260ms easeInOutCubic). Invite-code card (code 30px w900 ls4 + nút copy). Form card glass, date picker + photo picker (ImagePicker quality 92, preview tròn 118px). FilledButton.icon, BlockingLoadingOverlay bọc.
- home_screen — IndexedStack 3 tab + custom floating bottom nav (không dùng BottomNavigationBar): cao 84, margin 16, bo 28, BackdropFilter blur 24, gradient trắng .28→.14, viền trắng .35, 2 shadow. Pill chọn gradient sunset→accentLoveDeep trượt 320ms, icon scale 1.12. 3 tab: favorite/photo_library/person. Tab Home cuộn dọc: header → hero glass (greeting + animated name) → banner chờ partner → CounterCard → CTA "Thêm kỷ niệm" (card rose full-width mở thẳng đăng ảnh — feature home-engagement P1; thay 2 quick-action cũ + link "Xem tất cả ảnh") → milestone progress bar → quote card → recent photos ngang (140×176; empty-state nút "Đăng ảnh đầu tiên"). extendBody, nav ẩn khi bàn phím hiện.
- gallery_screen — feed dọc, KHÔNG grid. CustomScrollView: SliverPersistentHeader co giãn (expanded 340/compact 122, snap 250ms) chứa composer card (avatar gradient + nút thêm 1/nhiều ảnh + marquee chip 45px/s) → CTA "hôm nay" → feed card (avatar+tên+time+menu, ảnh Hero 4:5 bo 26, caption) theo tháng. Fullscreen preview: PageView swipe, InteractiveViewer pinch zoom (max 4×), drag-to-dismiss dọc (nền fade .94→.2, threshold 140px), panel info + nút edit/close.
- profile_screen (feature settings) — chỉ danh tính couple: header eyebrow + hero card couple (bo 32, ảnh nền blur/gradient + initials 56px, badge glass đếm ngày tới kỷ niệm, avatar 72px viền gradient, tên 30px serif w800) + Stats 2×2 (years/months còn lại/total days/memories) + Info tiles (start date, milestone, invite code) + tile đơn "⚙️ Cài đặt" (white .72 r22 → push SettingsScreen). Reminders/ngôn ngữ/danger/edit-story/đăng xuất/privacy CHUYỂN sang Settings.
- settings_screen (feature settings, 2026-05-31) — nền dawnBlush + AppBar phẳng, `SingleChildScrollView` 3 module section card (`_buildSectionCard`): 🔔 Nhắc nhở (master toggle + tile "Cột mốc & kỷ niệm" dim khi off → milestone screen + tile "Lời nhắc của chúng mình" gate force-open Dv6; bỏ tile "Giờ nhắc" độc lập) · 🌐 Ngôn ngữ (tile → `showLanguagePicker`) · 👤 Tài khoản & dữ liệu (tile "Chỉnh sửa câu chuyện" → setup) + danger card tách biệt (clear cache/leave/delete) + nút Đăng xuất + link privacy. Bê nguyên hành vi từ profile, đổi vị trí + title module (`settings*`).
- milestone_reminders_screen — Cột mốc & kỷ niệm: tile "Giờ mặc định" (accentGold, tap → time picker → `setTime`) + 7 mốc (toggle + next-fire) + chip-giờ mỗi mốc (giờ-theo-mốc Dv8): mờ "Theo mặc định · {giờ}" khi chưa đặt riêng → tap đặt riêng; đậm rose "{giờ} ✕" khi đã đặt → ✕ về mặc định; ẩn khi mốc tắt.
