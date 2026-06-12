# Design Unify — Spec đồng bộ toàn app theo Home v3 (2026-06-11)

> File Designer sở hữu. Audit trên **code thật trên đĩa** (Home là vua — D1): `home_screen.dart` 1.753 dòng + counter_card / today_ritual_card / memory_cinema_card / streak_chip + 15 màn còn lại + 12 widget dùng chung. Mâu thuẫn doc cũ vs code → **code Home thắng**.
>
> ⚠️ **Chốt hiện trạng Home mới nhất (code 2026-06-11, khác design-system.md cũ):**
> - Header Home KHÔNG còn "calendar leaf": là **greeting theo buổi + tên user** (trắng 21 w800 + **bóng tối** `0x52000000` blur 10 offset(0,1)) + dòng teaser 13.5 w500 trắng .95 bóng `0x47000000` (`home_screen.dart:1081–1121`).
> - Bell KHÔNG còn là đĩa tròn: là **SQUIRCLE 48×48 r17** nền gradient trắng .98→.86, viền trắng .65, shadow rose .30 blur 18 offset(0,8), icon 22 phủ ShaderMask gradient `accentLoveDeep→accentLavender`, InkWell splash rose .12, Semantics đầy đủ (`home_screen.dart:1143–1192`).
> - Đồng hồ CounterCard là **pill kính HH:MM:SS 3 cột (GIỜ/PHÚT/GIÂY)** — `counter_card.dart:450–568` (doc cũ ghi "1 dòng tổng giờ" đã stale).
> - MemoryCinema **nằm trong gutter 16, r28, CÓ shadow black .12** (`memory_cinema_card.dart:129–144`) — không còn full-bleed.
> Dev cập nhật lại `project/design-system.md` theo bản này khi implement (AC#5 của overview).

---

## PHẦN A — TOKEN SHEET CHUẨN (derive từ Home)

### A1. Màu theo VAI TRÒ (không thêm hex mới — tái dùng `AppColors`)

| Vai trò | Token | Ghi chú |
|---|---|---|
| Nền MỌI màn hình | `dawnBlush` (= `secondaryGradient`) | Home bọc cả 3 tab (`home_screen.dart:525`). **Journal đang dùng `dreamyMint` → đổi về dawnBlush** (C9). `dreamyMint` chỉ còn làm accent trang trí (vd vòng tròn empty-state). |
| Hero card duy nhất | `sunsetRomance` | Chỉ CounterCard (Home + guest). |
| Accent hành động chính | `accentLove`/`accentRose` #FF4D6D | Nút rose, icon tile, FAB. |
| Accent active/đậm | `accentLoveDeep` #E63956 | Label "của mình", link trên nền trắng. |
| Accent partner | `accentLavender` .10 nền / `accentLavenderDeep` chữ | Khối trả lời/note của partner (journal convention). |
| Mực chính / nút mặc định | `textPrimary` #1A1A2E | Link/chữ nhỏ <16px trên dawnBlush BẮT BUỘC dùng màu này (loveDeep chỉ ~2.7:1). |
| Fill input/pill nghỉ | `surfaceLight` #F5F0F5 | Compose pill, answer block "mine", track progress trên nền trắng. |
| Card nội dung | `cardSurface` #FFFFFF **đặc** | Không còn white .72–.94 translucent cho card nội dung (xem A5). |
| Trạng thái | success/warning/error/info | Giữ nguyên. |

### A2. Typography (helper `AppTheme`, 1 phông Quicksand)

| Vai trò | Style | Nguồn chuẩn |
|---|---|---|
| Số hero | `dayCountStyle()` 76 w800 + halo trắng .45 | CHỈ trên nền tối/scrim (counter). |
| Tựa trang (trên gradient) | `pageTitleStyle()` 32 w700 trắng | **BỔ SUNG bóng tối mặc định** (A6) — hiện helper KHÔNG có shadow → mọi màn auth/profile/gallery đang fail luật chữ-trắng. |
| Eyebrow trang | `pageEyebrowStyle()` 11 w700 ls1.4 | Thêm bóng tối như trên. |
| Subtitle trang | `pageSubtitleStyle()` 14 trắng .82 | Thêm bóng tối như trên. |
| Section title trong tab | `sectionTitleStyle()` 22 w700 textPrimary | `home_screen.dart:1340-1342`. |
| Section subtitle | `sectionSubtitleStyle()` 13 textSecondary | |
| Header trong card | 16 w800 textPrimary ls-0.2 + icon Lucide 20 rose | `today_ritual_card.dart:262-277` — chuẩn cho MỌI card có tiêu đề (settings/profile section đang dùng 18 w800 không icon → đổi về 16 w800 + icon). |
| Câu hỏi/nội dung nổi bật | `displaySerif(21, w600, h1.25)` | `today_ritual_card.dart:281-289`. |
| Title tile | 15 w700 textPrimary; sub 12 textSecondary h1.4 | Settings/milestone đã chuẩn. |
| Label khối trả lời | 11 w700 ls0.3 loveDeep / lavenderDeep | |
| Title AppBar màn con | 18 w800 textPrimary | settings/custom-reminders đã đúng; journal/history dùng displaySerif 20 → đổi 18 w800 cho khớp. |

### A3. Radius scale (giá trị thật Home đang dùng)

| Giá trị | Dùng cho |
|---|---|
| **28** | Hero CounterCard, MemoryCinema, floating nav, bottom-sheet top, GlassCard auth form, dialog đặc biệt. |
| **24** | **Card nội dung trắng đặc** (TodayRitualCard `today_ritual_card.dart:179`), dialog AlertDialog. |
| **22** | Tile hàng white .72 (waiting banner `home_screen.dart:1241`, settings/milestone tiles). |
| **20** | Input field (theme), date/photo picker tile setup. |
| **16** | Compose pill / nút full-width trong card / answer block / icon squircle 44 / sliding pill setup. |
| **17** | Bell squircle 48 (header action lớn). |
| **14** | Icon chip nhỏ trong tile (badge icon 38–42). |
| **12** | Ripple hàng link nhỏ (archive links), pill Copy/Share. |
| **999** | Pill: nút chính, chip, progress, badge, eyebrow chip. |

### A4. Spacing scale

- Gutter trang: **16** (per-block, scroll view không padding ngang — `home_screen.dart:206-211`).
- **Trong nhóm 12 · giữa nhóm 28**; section title → card: **12**; header → hero: **20**.
- Padding trong card nội dung: **20**; trong tile: **16**; trong pill: 14×13.
- Icon ↔ text: 8 (inline) / 14 (tile leading).
- List màn con: padding `fromLTRB(16, 8, 16, 24–32)`, separator 12–14.

### A5. Elevation / shadow (luật cứng)

| Bề mặt | Shadow |
|---|---|
| Card nội dung trắng | `black .06, blur 16, offset(0,10)` — chuẩn duy nhất (`today_ritual_card.dart:180-186`). |
| Tile white .72 | `black .05, blur 14, offset(0,8)` HOẶC không shadow + border accent .10 (settings đang dùng — giữ). |
| Hero counter | giữ bloom màu: sunset1 .36 blur 36 + lavender .18 blur 48. |
| Media card (cinema/feed ảnh) | `black .12, blur 18, offset(0,10)`. |
| Full-bleed (nếu có) | **KHÔNG shadow**. |
| Bell/disc header | rose .30 blur 18 offset(0,8). |
| **Chữ trắng trên dawnBlush** | bóng TỐI `black .28–.32 (≈0x47–0x52) blur 8–12 offset(0,1)` — **KHÔNG halo trắng**. Halo trắng chỉ hợp lệ cho số hero TRÊN scrim tối của CounterCard. |

### A6. Đề xuất bổ sung design system (token mới hợp thức hoá)

1. `AppTheme.pageTitleStyle/pageEyebrowStyle/pageSubtitleStyle` **thêm `shadows` bóng tối mặc định** (tham số `shadowed = true`) — đóng nợ chữ-trắng toàn app 1 chỗ.
2. Token "header action squircle": 48 r17 (tab) / 44 r16 (màn con) — nền trắng .92–.98, icon 20–22.
3. Token "tile" chính thức: white .72 r22 border accent .10 (đã dùng nhất quán Home banner + Settings).
4. Nút primary = **pill r999 height 52** (theme đã khai báo) — auth đang dùng r20 padding 16 → quy về pill (C1).

### A7. Icon

- Bộ Lucide; heart = Material `favorite_rounded` (giữ nguyên ngoại lệ).
- Size: 22 header action · 20 tile leading + card header · 17–18 trong pill/nút · 14–16 inline/meta.
- Icon squircle: 44×44 r16, nền `tint.withValues(.12)`, icon 20 màu tint (lặp ~20 chỗ → primitive B6).
- Back icon màn con: `LucideIcons.arrowLeft` 20 `textPrimary` trong disc trắng (thay 3 biến thể hiện tại: chevron rose / chevron textPrimary trần / glass GestureDetector trắng).

### A8. Motion

- Token `AppMotion`: fast 200 / base 280 / slow 320 / entrance 360 / stagger 50, curve easeOutCubic. Không thêm duration mới.
- Entrance = fadeIn + slideY 0.08, chạy 1 LẦN (`_OnceEntrance` pattern), chỉ 6 item đầu của list.
- **Luật Reduce Motion (WCAG 2.3.3)** — audit phát hiện 4 chỗ ĐANG VI PHẠM, phải vá trong lượt này:
  1. `counter_card.dart:400-440` `_buildGlow` aurora repeat — không check `AppMotion.reduceMotion` → render frame tĩnh khi bật.
  2. `memory_cinema_card.dart:82-88, 235-241` — Timer auto-advance + Ken Burns không check reduceMotion, và **Timer không dừng khi tab ẩn** (TickerMode chỉ tắt ticker của `.animate`, không tắt `Timer.periodic`) → check `TickerMode.of(context)` + reduceMotion: tắt auto-advance & Ken Burns, giữ swipe tay.
  3. `gallery_screen.dart:1893-1959` `_MarqueeRow` chạy vô hạn — reduceMotion → render hàng chip tĩnh.
  4. `_OnceEntrance` (4 bản copy) — reduceMotion → trả thẳng child.
- Ripple: mọi phần tử bấm được = `InkWell` (KHÔNG GestureDetector trần): **rose .08** trên nền sáng · **trắng .12–.15** trên nền đậm/ảnh; highlight transparent hoặc love .06.
- Haptic: selectionClick khi đổi tab/chọn; mediumImpact khi hành động thành công (giữ như hiện có).

---

## PHẦN B — PRIMITIVES DÙNG CHUNG (trích/chuẩn hoá để Dev không copy-paste lệch)

| # | Tên (file mới `lib/widgets/`) | API gọn | Nguồn | Dùng ở |
|---|---|---|---|---|
| B1 | `ScreenBackground` | `ScreenBackground({Gradient gradient = AppColors.dawnBlush, required Widget child})` — Container gradient bọc Scaffold transparent | **MỚI** (trích pattern `home_screen.dart:524-525`, lặp ở 14 màn) | Mọi màn. |
| B2 | `SubScreenHeader` (hoặc chuẩn AppBar) | `subScreenAppBar(context, {required String title, List<Widget>? actions})` → AppBar transparent, leading = `HeaderIconButton(arrowLeft)`, title 18 w800 textPrimary | **MỚI** — thay 3 biến thể back (journal `journal_screen.dart:60-67`, settings `settings_screen.dart:101-107`, notif `notification_center_screen.dart:396-424`) | Journal, History, NotifCenter, Settings, Milestone, CustomReminders ×2. |
| B3 | `HeaderIconButton` | `HeaderIconButton({required IconData icon, required VoidCallback onTap, String? semanticsLabel, double size = 44, double radius = 16})` — squircle trắng .92–.98, icon 20 textPrimary, InkWell rose .08, shadow rose .18 blur 14 | **TRÍCH** từ bell `home_screen.dart:1143-1192` (bỏ ShaderMask khi không phải bell) | Back các màn con + action phụ (overflow notif center). |
| B4 | `ContentCard` | `ContentCard({EdgeInsetsGeometry padding = EdgeInsets.all(20), double radius = 24, Widget child})` — trắng ĐẶC r24 + shadow black .06/16/(0,10) | **TRÍCH** `today_ritual_card.dart:174-187` | TodayRitual (refactor), section card Profile/Settings, journal card, history card, notif tile, form custom-reminder, milestone card guest. |
| B5 | `SectionHeader` | `SectionHeader({required String title, String? subtitle, String? actionLabel, VoidCallback? onActionTap})` — title `sectionTitleStyle`, action TextButton textPrimary w700 14 | **TRÍCH** `home_screen.dart:1327-1372` `_buildSectionTitle` | Home (giữ), Gallery (nếu cần), Profile. |
| B6 | `IconBadge` | `IconBadge(icon, {Color tint = accentRose, double size = 44, double radius = 16})` — squircle tint .12 + icon 20 tint | **MỚI** (pattern lặp ≥20 chỗ: settings 244-262, milestone 136-148, profile 552-564…) | Mọi tile. |
| B7 | `InkTile` | giữ API `_InkTile` hiện tại, đổi splash → rose .08 | **TRÍCH** `settings_screen.dart:1837-1869` ra widgets | Settings, Profile settings-tile, Milestone time tile, picker tiles. |
| B8 | `ComposePill` | `ComposePill({required String label, required VoidCallback onTap, IconData icon = edit3, bool emphasized = false})` | **TRÍCH** `today_ritual_card.dart:801-851` | Ritual card (giữ), bất kỳ "tap-to-compose" tương lai. |
| B9 | `EntranceReveal` | `EntranceReveal({required int order, required Widget child})` — `_OnceEntrance` + check `AppMotion.reduceMotion` | **TRÍCH** (4 bản copy: `gallery_screen.dart:2572`, `settings_screen.dart:2049`, `milestone_reminders_screen.dart:548`, `custom_reminders_screen.dart:739`) | 4 màn trên + journal (đang inline animate). |
| B10 | Quy ước nút (không cần widget) | Primary CTA = pill r999 h52 (navy theme mặc định; **rose** cho hành động tình cảm: sign-in/send/join). Nút full-width TRONG card = r16. Destructive = error r16. Spinner inline 20–22. | theme + `today_ritual_card.dart:1198-1230` | Auth ×4, guest, setup, gallery CTA. |
| B11 | Quy ước GlassCard | GlassCard CHỈ cho: form auth/setup/guest, bottom nav, overlay trên ảnh. **CẤM** list cuộn dài + card nội dung đọc nhiều. | `glass_card.dart` | NotifCenter phải bỏ (C11). |

---

## PHẦN C — SPEC TỪNG MÀN (giữ nguyên behavior/logic/navigation — chỉ UI)

### C0. Home (`home_screen.dart`) — NGUỒN CHUẨN, gần như không đụng
- Khớp 100% theo định nghĩa. Chỉ vá 2 việc:
  - Reduce-motion: aurora CounterCard + cinema Timer/KenBurns (A8.1, A8.2).
  - Refactor dùng primitives B3–B6 tại chỗ (không đổi pixel).
- `RefreshIndicator` đã có `backgroundColor: white` (dòng 825) — chuẩn cho mọi màn khác noi theo.

### C1. Login (`login_screen.dart`) — khớp khung, chỉnh 5 điểm
1. Header trắng (badge :134-156, title :158-161, subtitle :163-168) **không bóng tối** → tự khỏi khi sửa helper A6.1.
2. Back = `IconButton` arrow trắng trần (:105-115) → `HeaderIconButton` B3 (đặt `top:8,left:16`).
3. Nút submit `FilledButton` rose r20 padding 16 (:346-375) → **pill r999, height 52** (B10), giữ rose + spinner.
4. Status banner trắng-trên-kính (:186-240) → đổi sang ngôn ngữ "card sáng mực tối" như Home waiting banner: nền white .72 r20, title 13 w700 textPrimary, body 12 textSecondary (icon giữ màu status).
5. `hintStyle` đang `textPrimary w600` (:439-443) — hint trông như giá trị đã điền → đổi `textSecondary w500`.
- GIỮ: GlassCard form r28 (đúng luật B11), field label rose 13 w700, input fill white .92 r20, LanguageToggle vị trí.

### C2. Register (`register_screen.dart`) — như C1, thêm:
- Privacy disclosure `GestureDetector` + GlassCard lồng (:404-436) → `Material+InkWell` ripple rose .08 (giữ glass nhỏ r14).
- Lỗi terms dùng `Colors.red.shade400` (:464, :475, :493) → `AppColors.error` (token hoá).
- Submit pill r999 h52 như C1.3; hint như C1.5.

### C3. Forgot password (`forgot_password_screen.dart`) — như C1 (header shadow, back disc, nút pill, hint). Sent-state đã mực tối trên glass — giữ. Banner local-fallback (:227-268) đổi card sáng mực tối như C1.4.

### C4. Verify email (`verify_email_screen.dart`) — như C1 (header shadow; KHÔNG back — gate, giữ). Nút "Đã xác minh" → pill r999 h52 rose; nút Resend outlined → pill r999 (side rose .55 giữ). Banner not-yet (:426-459) đã mực tối — giữ.

### C5. Guest counter (`guest_counter_screen.dart`)
- Header (:196-235): thêm bóng tối (tự khỏi qua A6.1).
- Empty card + CTA card GlassCard: **CTA card chữ trắng trên kính** (:456-529 — `guestCtaTitle/Body` trắng .88 13px trên glass .16/blush) = vi phạm S1 → đổi mực tối: title 16 w700 textPrimary, body 13 textSecondary, icon heart `accentRose`; nút đăng ký TextButton trắng → `textPrimary` w700.
- Nút: `guestPickDate`/CTA sign-in pill r999 h52 rose; `guestChangeDate` outlined pill r999.
- Milestone section (:350-454) ĐÃ đúng ContentCard chuẩn (trắng r24 + black .06) — đổi icon tint `accentGold`→`accentRose` (accentGold là hồng nhạt #E8B4D8, icon trên trắng ~1.8:1 — fail) và dùng B4/B6.
- CounterCard giữ nguyên (dùng chung widget với Home).

### C6. Setup (`setup_screen.dart`)
- Header (:469-577): bóng tối qua A6.1; pill sign-out (:509-547) đã InkWell — nâng chữ trắng .70 → .92 + bóng tối (contrast).
- Error banner (:556-574) chữ trắng trên warning .18 → mực tối: nền white .72 r16 border warning .30, text 12.5 w600 textPrimary.
- Mode selector: tab label `GestureDetector` (:652) → `InkWell` ripple trắng .12 (pill trượt giữ nguyên).
- Invite card glass (:736-809): GIỮ glass (họ auth) nhưng title trắng .80 12.5 → trắng .95 + bóng tối; desc .65 → .85 + bóng tối; rejoin hint .50 → .75.
- `_formatDate` hardcode `dd/MM/yyyy` (:398-402) → `DateFormat(l10n.fullDateFormat)` (decision D3 — display-only, không đổi behavior).
- Nút submit/join `FilledButton.icon` r20 → pill r999 h52 rose.
- Dialog mã mời (:334-378) r24 — khớp, giữ.

### C7. Gallery (`gallery_screen.dart`) — **GIỮ layout feed/header co giãn/preview; chỉ đồng bộ token**
1. Eyebrow + title + subtitle trắng (:986-996, :742-766) → bóng tối qua A6.1 (eyebrow alpha .88 giữ).
2. `_gallerySurfaceDecoration` (:678-698) fill .84–.94 + viền trắng → **trắng ĐẶC `cardSurface`**, bỏ border trắng, shadow black .06 blur 16 offset(0,10) (composer/compact/today/error/empty); feed card (:1266-1275) shadow giữ black .05–.06.
3. Radius: feed card **30 → 28**, ảnh trong 26 (giữ tỉ lệ lồng −4); error/empty card 30 → 28.
4. Month header chip (:1508-1524): chữ trắng .82 12px trên chip kính .16/blush ~ fail → chữ trắng .95 + bóng tối black .30 blur 8 (giữ khung chip).
5. `RefreshIndicator` (:1764-1766) thêm `backgroundColor: AppColors.white`.
6. `_MarqueeRow` → reduceMotion static (A8.3).
7. Today-strip thumbnail `GestureDetector` (:1220) → `Material+InkWell` splash trắng .12 (giống cinema `memory_cinema_card.dart:170-176`).
8. Nút composer r14 + CTA r16 + retry r18: quy về **r16** cả 3 (nút-trong-card token).
9. Fullscreen preview + reaction overlay on-dark: khớp, giữ nguyên.

### C8. Profile (`profile_screen.dart`)
- Header (:147-188): GIỮ khung eyebrow chip + pageTitle (pattern tab) + bóng tối qua A6.1.
- `_buildSectionCard` (:619-664) white .84 r28 viền trắng → **ContentCard B4** (trắng đặc r24, black .06); header card 18 w800 → 16 w800 + IconBadge 20 rose (A2).
- Hero card r32 (:190-423): GIỮ nguyên (hero riêng của Profile, ảnh + scrim tối + chữ trắng có bóng — đã đúng luật). Glass pill trên ảnh giữ.
- Stat card (:666-713) tint `accentGold` → giữ nền tint .10 nhưng icon/value đậm hơn nếu tint là accentGold → đổi tile "Kỷ niệm đã lưu" sang `accentLavender` (accentGold quá nhạt trên trắng).
- Detail tile (:715-774) white .72 r22 — khớp token tile, giữ; tile Settings (:535-617) đã InkWell overlay — đổi splash rose .12 → .08.
- Skeleton (:108-145) cập nhật radius 28→24 cho section khối.

### C9. Journal (`journal_screen.dart`)
- Nền `dreamyMint` (:54) → **`dawnBlush`** (D1 — đồng nhất; mint chỉ còn accent).
- AppBar: leading chevron textPrimary trần (:60-67) → `HeaderIconButton` B3; title displaySerif 20 → 18 w800 textPrimary (A2).
- Day card (:217-230): r28 → **24**; shadow `accentLove .08 blur 24` → **black .06 blur 16 offset(0,10)** (B4). Nội dung khối trả lời ĐÃ chuẩn two-tone — giữ.
- Entrance inline (:164-175) → `EntranceReveal` B9.
- Empty/error states giữ; nút empty-CTA dùng theme ElevatedButton (đã pill navy) — giữ.

### C10. Love note history (`love_note_history_screen.dart`)
- AppBar như C9 (B3 + title 18 w800).
- Card (:140-153): r20 → **24**; shadow rose .06 → black .06 (B4 padding 16 ok).
- Loading `CircularProgressIndicator` (:65-71) → list 3 `ShimmerSkeleton(height 96, r24)` (chuẩn skeleton app).

### C11. Notification center (`notification_center_screen.dart`)
- `_GlassIconButton` GestureDetector kính (:396-424) → `HeaderIconButton` B3 (back + overflow); title trắng giữ (đang trên gradient — qua A6.1 có bóng).
- **Tile = GlassCard trong list cuộn dài (:211-217) — vi phạm B11** → `ContentCard` trắng đặc **r22** padding 0 + InkWell rose .08; unread = viền `accentLove .45` 1.2 + dot (giữ ngôn ngữ NEW của love-note `today_ritual_card.dart:629-634`); read = không viền.
- Section header "HÔM NAY/TRƯỚC ĐÓ" trắng .92 (:155-163): thêm bóng tối black .30 blur 8.
- Empty state GlassCard (:517-557) → ContentCard trắng r24, body textSecondary.
- Spinner đầu (:42-46) → ShimmerSkeleton list tile.
- Dismissible background (:183-188) giữ.

### C12. Settings (`settings_screen.dart`)
- AppBar: chevron rose (:101-107) → B3 + title đã 18 w800 (giữ).
- `_buildSectionCard` (:1217-1262) white .84 r28 viền trắng → ContentCard B4 (trắng đặc r24); header 18 w800 → 16 w800 + IconBadge.
- Tiles white .72 r22 + IconBadge 44 r16 rose .12: **ĐÃ chuẩn token tile — giữ nguyên** (chỉ thay icon-container bằng B6, splash `_InkTile` .12 → .08).
- Nút Sign-out (:1008-1031): fg `textSecondary` trên blush → `textPrimary`; nền white .22 → white .72; r20 → pill r999 h52 (nút primary ngoài card).
- Danger zone (:1036-1215): GIỮ cấu trúc + màu error; card white .92 r28 → trắng đặc r24 (B4); các nút r16 giữ (destructive token).
- Privacy link GestureDetector (:1264-1297) → InkWell ripple rose .08 r12.
- `_OnceEntrance` → B9.

### C13. Milestone reminders (`milestone_reminders_screen.dart`)
- AppBar chevron rose (:40-46) → B3; title đã 18 w800.
- Tiles (:123-205, :232-305) — chuẩn tile, giữ; `_TimeChip` GestureDetector (:477-481, :511-516) → InkWell r999 splash rose .08.
- `_DefaultTimeTile` tint `accentGold` (:131-148) → icon/giá trị fail contrast trên trắng → đổi tint `accentLavender` (giờ = "thời gian", lavender phù hợp) hoặc `accentRose`; chữ giờ accentRose 15 w800 giữ.
- `_OnceEntrance` → B9.

### C14. Custom reminders list (`custom_reminders_screen.dart`)
- AppBar → B3; FAB tròn accentLove giữ (token).
- `_ReminderCard` (:460-547) Material white .72 r22 + InkWell — chuẩn tile, đổi splash .12 → .08.
- Empty/disabled states: card white .72 r28 (:251-259) → r24; nút đã pill r999 h52 — giữ.
- `DateFormat.yMMMd()` không truyền locale (:575, :592-607) → truyền `Localizations.localeOf(context)` (D3, display-only).
- `_OnceEntrance` → B9.

### C15. Custom reminder form (`custom_reminder_form_screen.dart`)
- AppBar → B3; nút Save text rose w800 giữ.
- Form card (:293-306) white .84 r28 viền trắng → ContentCard B4.
- `_pickerTile` (:476) + `_repeatChip` (:520) GestureDetector → InkWell (ripple rose .08; chip chọn gradient sunset giữ).
- `DateFormat.yMMMd()` (:227) → truyền locale (D3).

### C16. Session route (`session_route_screen.dart`) — khớp (splash resolve, gradient + tim trắng + spinner trắng). Không đụng.

### C17. Widgets dùng chung
- `language_toggle_button.dart`: pill GestureDetector (:94) → InkWell ripple trắng .12; text/icon trắng trên blush → thêm bóng tối black .28 blur 8 cho text 12 w700. Picker sheet ĐÃ chuẩn (trắng r28 + handle) — giữ.
- `invite_action_buttons.dart`, `reaction_bar.dart`, `streak_sheet.dart`, `blocking_loading_overlay.dart`, `shimmer_skeleton.dart`, `shared_*_view`: **khớp** — không đụng.
- `couple_info_card.dart` (:86 hardcode "Our story"), `masonry_gallery.dart` + `photo_item.dart`: **KHÔNG được dùng ở màn nào** → ngoài scope, không sửa; Dev ghi nợ "dọn dead-widget" vào dev.md.
- `glass_card.dart`: giữ, thêm doc-comment luật B11.

---

## PHẦN D — COPY & L10N

**KHÔNG có key ARB mới.** Toàn bộ thay đổi là restyle; mọi chuỗi tái dùng key sẵn có (`back`, `settingsTitle`, …). Nếu Dev phát hiện thiếu key khi gắn Semantics cho `HeaderIconButton` (label "Quay lại") → dùng key `back` ĐÃ tồn tại (notif center đang dùng `l10n.back`). Không đụng 2 file ARB, không cần gen-l10n.

---

## PHẦN E — RE-CHECK CHECKLIST (Tester/PO, đo được từng màn)

Áp cho TỪNG màn: Login · Register · Forgot · Verify · Guest · Setup · Gallery · Journal · History · NotifCenter · Profile · Settings · Milestone · CustomList · CustomForm (Home = baseline đối chiếu):

1. **Nền:** màn dùng `dawnBlush`? (Journal không còn mint?) Không màn nào nền trắng phẳng/gradient lạ.
2. **Header:** màn con dùng back-squircle trắng 44 r16 icon arrowLeft textPrimary + title 18 w800? Tab (Gallery/Profile) giữ eyebrow chip + pageTitle? Không còn chevron rose / arrow trắng trần / glass GestureDetector.
3. **Chữ trắng trên blush:** soi mọi chữ trắng — có bóng TỐI (black .28–.32) chứ không halo trắng/không bóng? (đo nhanh: screenshot → chữ vẫn đọc được trên vùng sáng nhất của gradient).
4. **Card nội dung:** trắng ĐẶC #FFF r24 + shadow black .06 blur16 offset(0,10)? Không còn white .72–.94 + viền trắng cho card đọc-nhiều; tile hàng = white .72 r22 border accent .10.
5. **GlassCard:** chỉ còn ở auth/setup/guest form + bottom nav + overlay ảnh? NotifCenter list không còn glass?
6. **Nút:** primary = pill r999 h52 (rose/navy); nút trong card = r16; destructive = error r16; spinner inline khi loading; disabled mờ đúng.
7. **Ripple:** tap mọi tile/pill/chip/link → có ripple (rose .08 nền sáng, trắng .12–.15 nền đậm)? Không còn GestureDetector trần ở phần tử bấm được (trừ gesture swipe/drag).
8. **Radius đúng scale** (28/24/22/20/16/999) — không còn 30, 20-cho-card, 18-cho-nút lẫn lộn.
9. **Reduce Motion ON** (iOS Settings → Accessibility): aurora counter đứng yên; cinema không tự trượt + không Ken Burns (swipe tay vẫn được); marquee gallery đứng yên; entrance không chạy; heart không pulse. **Tab ẩn:** cinema timer không tick (kiểm bằng debug log/CPU).
10. **Contrast ≥ 4.5:1** cho chữ <18px: month-chip gallery, eyebrow, guest CTA, sign-out, time chips, status banners (đo bằng contrast checker trên screenshot).
11. **RefreshIndicator** (Home/Gallery): spinner rose trên nền đĩa TRẮNG.
12. **Skeleton:** không còn CircularProgressIndicator giữa màn (History/NotifCenter) — shimmer content-shaped, radius khớp layout thật (không nhảy hình).
13. **Behavior bất biến:** mọi flow (login→home, join, đăng ảnh, reaction, reminder toggle, leave couple, deep-link notification) hoạt động y nguyên; `fvm flutter analyze` 0 issue.
14. **i18n:** đổi máy sang EN — ngày tháng setup/custom-reminders theo locale (D3); không chuỗi cứng mới.

---

## DEV NOTES (đọc trước khi code)

1. **Thứ tự làm:** A6.1 (sửa 3 helper AppTheme — ăn ngay ~10 màn) → B1–B9 primitives → C1→C15 từng màn → vá Reduce Motion A8 → cập nhật `project/design-system.md`.
2. **Không đụng:** `firestore.rules`/functions/providers/services/routes; `_entrance` của Home giữ quy tắc constant-params (comment dòng 215-241 — đã 2 lần crash); `session_route_screen`; preview/feed layout gallery.
3. Khi thay fill translucent → trắng đặc ở gallery header co giãn: kiểm tra lại compact↔expanded crossfade không lộ viền (nền dưới là gradient, card đặc che ổn).
4. `HeaderIconButton` đặt trong `SafeArea`/AppBar leading với `leadingWidth: 60` để disc 44 không bị bóp.
5. Bell Home GIỮ nguyên 48 r17 + ShaderMask (không thay bằng B3 — B3 là biến thể 44 cho màn con).
6. Mọi shadow/alpha dùng `withValues(alpha:)` như codebase.
7. Sau khi xong: ghi dev.md + tick AC trong overview; design-system.md cập nhật cả phần "Home hiện trạng" ở đầu file này (greeting header + bell squircle + clock pill).

---

## BỔ SUNG 2026-06-11 (vòng 2) — HEADER-SYNC: 1 hệ header duy nhất

> User re-check sau vòng 1: "có màn còn chip, màn không có, màn cài đặt màu khác" → chốt thêm, GHI ĐÈ A2/B2 chỗ mâu thuẫn:
1. **Bỏ HỘP chip eyebrow toàn app** — eyebrow = text trần `pageEyebrowStyle()` (login/register/forgot/verify/guest/setup/profile/gallery). Eyebrow→title spacing 12.
2. **Title app bar màn con = TRẮNG 18 w800 + bóng tối black .30 blur 8** (sửa trong `subScreenAppBar` — ăn settings/journal/history/milestone/custom ×2), thay textPrimary cũ.
3. **NotifCenter về cùng pattern 1 hàng** (back ‖ title 18 trắng giữa ‖ overflow/counterweight 44) — bỏ pageTitle 32.
4. **Action text trong app bar màn con = trắng + bóng tối** (Save form 16 w800, counter x/20 14 w700; at-capacity giữ `warning` semantic) — thay rose (2.7:1 fail trên blush).
5. Badge/pill trong NỘI DUNG card (today-badge, streak, on-this-day) không phải header — giữ.

## BỔ SUNG 2026-06-11 (vòng 4) — HEADER INK NAVY (GHI ĐÈ vòng 2 về MÀU mực)

> User gửi 4 screenshot thật → Lead đánh giá chuyên môn: mực trắng trên dawnBlush nhạt (#FFC1CC) chỉ ~1.7:1, subtitle/app-bar-title chìm. User duyệt "tự quyết tự làm" → đảo mực:
1. **3 helper page*** default → `textPrimary` (eyebrow .55 / title 1.0 / subtitle .62), không shadow; trắng+shadow chỉ còn khi caller truyền `color: white` (scrim tối).
2. `subScreenAppBar` + NotifCenter title/section + action app-bar (Save, x/20) + Home greeting/teaser → navy, bỏ bóng.
3. Phụ kiện trên gradient → bề-mặt-sáng-mực-navy: LanguageToggle pill, sign-out setup, month chip gallery; **invite card setup GlassCard → ContentCard** (code `accentLoveDeep`).
4. **Copy:** `editCoupleBadge` "CHỈNH SỬA"→"HỒ SƠ CẶP ĐÔI" (hết lặp title); `galleryTitle` → sentence-case "Thư viện ảnh"; invite card couple-active bỏ description (đang lặp nguyên văn title).
5. Mode selector setup: tab chưa chọn navy .60; tab đang chọn trên pill gradient GIỮ trắng.

## BỔ SUNG 2026-06-11 (vòng 5) — EYEBROW CHIP TRỞ LẠI (bề mặt sáng)

> User xem bản eyebrow text trần (vòng 2-4) và yêu cầu "làm thẻ chip giống version cũ nhưng màu khác cho hợp app bây giờ":
- Primitive mới **B12 `EyebrowChip`** (`lib/widgets/eyebrow_chip.dart`): pill white .72 + viền trắng .65 + shadow rose .14 + icon 13 `accentLoveDeep` + label `pageEyebrowStyle(.70)` navy. Cùng họ HeaderIconButton/language-pill/month-chip — KHÁC bản cũ (kính trắng .12 + chữ trắng, fail ~1.7:1).
- Áp 8 màn với icon khôi phục theo bản cũ: login=lock · register=userPlus · forgot=keyRound · verify=mailCheck · guest=sparkles · setup=heart/pencil · profile=sparkles · gallery=sparkles. Chip→title spacing 14.

## Changelog

- [2026-06-11] [Designer] Audit 16 màn + 12 widget theo Home v3 (code 2026-06-11 thắng doc cũ: greeting header + bell squircle r17 + clock pill HH:MM:SS + cinema in-gutter r28). Xuất token sheet (A), 11 primitives (B), spec từng màn (C0–C17), 0 key l10n mới (D), checklist 14 mục (E). Phát hiện 4 vi phạm Reduce Motion (aurora/cinema/marquee/entrance) + 1 vi phạm GlassCard-trong-list (NotifCenter) + nợ chữ-trắng-không-bóng ở mọi page header ngoài Home → đưa vào scope. → chờ Dev.
