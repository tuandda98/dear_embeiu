# Design Unify — Dev log

> File Dev sở hữu. Implement theo [design.md](design.md) (Designer) + decision log D1–D3 trong [overview.md](overview.md).

## Stage A — Nền móng (2026-06-11) ✅ implement xong, chờ test

Scope stage A: A6.1 (shadow helpers) + primitives B1–B9 + vá Reduce Motion A8.1/A8.2 + C0 refactor Home/ritual + doc B11. **15 màn còn lại (C1–C15) CHƯA đụng — stage sau.**

### File sửa

| File | Thay đổi |
|---|---|
| `lib/theme/app_theme.dart` | A6.1: `pageTitleStyle`/`pageEyebrowStyle`/`pageSubtitleStyle` thêm tham số `bool shadowed = true` + bóng tối mặc định (title: black 0x52 blur 10 offset(0,1); eyebrow/subtitle: black 0x47 blur 8 offset(0,1)). **Smart default:** shadow CHỈ áp khi `shadowed && color == AppColors.white` — mọi call-site hiện tại (đã grep: verify-email/profile/gallery/login/guest/notif-center/register/forgot/setup) đều dùng màu trắng mặc định → tự ăn shadow; gọi với màu tối sẽ KHÔNG có shadow. |
| `lib/widgets/counter_card.dart` | A8.1: `_buildGlow` thêm param `animated` (= `!AppMotion.reduceMotion(context)`, đọc 1 lần trong build) — Reduce Motion → render glow tĩnh, không repeat controller. Import `app_motion.dart`. |
| `lib/widgets/memory_cinema_card.dart` | A8.2: thay khởi tạo Timer ở `initState` bằng gate `_autoPlayAllowed` set trong `didChangeDependencies` = `TickerMode.valuesOf(context).enabled && !AppMotion.reduceMotion(context)` (`TickerMode.of` deprecated trên toolchain này). Timer auto-advance giờ DỪNG khi tab ẩn + khi Reduce Motion; Ken Burns tách ra `_withKenBurns` (reduceMotion → trả ảnh tĩnh); crossfade `AnimatedSwitcher` duration → `Duration.zero` khi reduceMotion. **Swipe tay giữ nguyên.** |
| `lib/screens/home_screen.dart` | C0: `_buildSectionTitle` xoá → dùng `SectionHeader` (B5) tại 2 call-site; icon container của waiting banner → `IconBadge` (B6, size 40/r14/tintAlpha .10 — pixel-identical). Bỏ import `app_theme.dart` (hết dùng). **Bell GIỮ nguyên 48 r17 + ShaderMask; `_entrance` constant-params KHÔNG đụng.** |
| `lib/widgets/today_ritual_card.dart` | C0: outer Container trắng → `ContentCard` (B4, pixel-identical: white/r24/black .06 blur 16 offset(0,10) + padding 20); `_composePill` xoá → `ComposePill` (B8) tại 3 call-site. |
| `lib/widgets/glass_card.dart` | Doc-comment luật B11 (glass CHỈ cho form auth/setup/guest + bottom nav + overlay ảnh; CẤM list dài + card nội dung). Không đổi code. |

### File mới (primitives B1–B9, `lib/widgets/`)

| # | File | API |
|---|---|---|
| B1 | `screen_background.dart` | `ScreenBackground({Gradient gradient = AppColors.dawnBlush, required Widget child})` |
| B2 | `sub_screen_app_bar.dart` | `PreferredSizeWidget subScreenAppBar(BuildContext context, {required String title, List<Widget>? actions, VoidCallback? onBack})` — leading = HeaderIconButton arrowLeft (semantics `l10n.back`), `leadingWidth: 60`, title 18 w800 textPrimary centered, transparent |
| B3 | `header_icon_button.dart` | `HeaderIconButton({required IconData icon, required VoidCallback onTap, String? semanticsLabel, double size = 44, double radius = 16, double iconSize = 20, Color iconColor = textPrimary})` — squircle trắng .98→.92, border trắng .65, shadow rose .18 blur 14 offset(0,6), splash rose .08, KHÔNG ShaderMask |
| B4 | `content_card.dart` | `ContentCard({EdgeInsetsGeometry padding = EdgeInsets.all(20), double radius = 24, required Widget child})` — cardSurface đặc + black .06/16/(0,10) |
| B5 | `section_header.dart` | `SectionHeader({required String title, String? subtitle, String? actionLabel, VoidCallback? onActionTap})` |
| B6 | `icon_badge.dart` | `IconBadge(IconData icon, {Color tint = accentRose, double size = 44, double radius = 16, double iconSize = 20, double tintAlpha = 0.12})` (const-able) |
| B7 | `ink_tile.dart` | `InkTile({required Widget child, required VoidCallback? onTap, required double borderRadius})` — splash rose **.08** (settings cũ .12, stage sau swap), highlight love .06 |
| B8 | `compose_pill.dart` | `ComposePill({required String label, required VoidCallback onTap, IconData icon = LucideIcons.edit3, bool emphasized = false})` |
| B9 | `entrance_reveal.dart` | `EntranceReveal({required int order, required Widget child})` — `_OnceEntrance` pattern + Reduce Motion trả thẳng child. **4 bản copy `_OnceEntrance` (gallery/settings/milestone/custom) CHƯA swap — stage sau.** |

### Ghi chú / nợ cho stage sau
- B3/B1/B2/B7/B9 chưa có consumer (Home không cần) — widget public trong lib/ nên analyze không báo unused; stage C1–C15 sẽ wire.
- `settings_screen.dart` còn `_InkTile` riêng (splash .12) — stage C12 swap sang `InkTile`.
- A8.3 marquee gallery + A8.4 swap `_OnceEntrance` 4 màn: thuộc stage sau (ngoài scope stage A theo brief).
- Designer note "dọn dead-widget" (`couple_info_card.dart`, `masonry_gallery.dart`, `photo_item.dart`): ghi nợ, chưa dọn.
- `design-system.md` + tick AC overview: để PO/stage chốt sau khi apply đủ các màn.
- Behavior: 0 thay đổi ARB/providers/services/routes/rules/functions. Không deploy gì.

### Verify
- `fvm flutter analyze` → **No issues found** (2026-06-11).

## Stage B — Apply 15 màn (2026-06-11, 4 nhóm Dev song song) ✅

| Nhóm | Màn | Điểm chính |
|---|---|---|
| G1 (C1–C5) | login / register / forgot / verify / guest | Back → `HeaderIconButton`; submit FilledButton r20 → **pill r999 h52 rose**; status/local-fallback banner → card sáng white .72 mực tối (border màu status .30); hint `textPrimary w600` → `textSecondary w500`; register: privacy disclosure → InkWell + `Colors.red.shade400` ×3 → `AppColors.error`; verify: Resend outlined → r999 (giữ secondary, không ép h52); guest: CTA card hết chữ-trắng-trên-kính (title textPrimary/body textSecondary/heart rose), milestone section → `ContentCard` + `IconBadge` default (44/r16/rose .12 — chuẩn hoá từ gold .14/r14). |
| G2 (C6/C8/C12) | setup / profile / settings | Setup: sign-out pill chữ .70→.92 + bóng tối, error banner → white .72 mực tối border warning .30, mode tab → InkWell (SizedBox.expand, pill trượt không gesture riêng), invite glass GIỮ chỉ nâng alpha chữ, `_formatDate` → `DateFormat(l10n.fullDateFormat)` (D3), 2 nút submit/join → pill r999 h52. Profile: `_buildSectionCard` → `ContentCard` + header 16 w800 + icon Lucide 20 rose TRẦN (theo A2 canonical, KHÔNG squircle 44 trong header card); stat "Kỷ niệm" gold → lavender; hero r32 GIỮ. Settings: AppBar → `subScreenAppBar`; `_InkTile`/`_OnceEntrance` local XOÁ → widget chung; 9 icon-container → `IconBadge`; sign-out pill r999 h52 white .72 fg textPrimary; danger zone → `ContentCard` r24 (mất border error .14 — cue error còn qua icon/nút); privacy link → InkWell r12. |
| G3 (C7/C9–C11) | gallery / journal / love-note-history / notif-center | Gallery: `_gallerySurfaceDecoration` → **trắng đặc, bỏ border trắng**, black .06/16/(0,10); feed card 30→28, ảnh trong → 24 (luật lồng −4; spec ghi 26 — chọn 24 theo luật); month chip trắng .95 + bóng tối; RefreshIndicator bg trắng; `_MarqueeRow` reduce-motion static (+ tự chạy lại khi RM tắt giữa phiên); thumbnail today-strip → InkWell; nút r14/18 → 16; `_OnceEntrance` → `EntranceReveal`. Journal: nền mint → **dawnBlush**; AppBar → `subScreenAppBar`; day card → `ContentCard` p18. History: AppBar chuẩn; card r20→24 black .06; spinner → 3× ShimmerSkeleton h96 r24. NotifCenter: `_GlassIconButton` xoá → `HeaderIconButton`; overflow `PopupMenuButton` → `showMenu` anchor (InkWell trong HeaderIconButton nuốt tap); tile GlassCard → `ContentCard` r22 p0 + InkWell rose .08, unread = foregroundDecoration viền accentLove .45 1.2 + dot; **shadow đặt Container NGOÀI ClipRRect** (ClipRRect cần cho nền đỏ swipe); section header bóng tối; empty → ContentCard; spinner → 5× shimmer h84. |
| G4 (C13–C15/C17) | milestone / custom-reminders ×2 / language_toggle | AppBar ×3 → `subScreenAppBar`; `_TimeChip`/`_pickerTile`/`_repeatChip` GestureDetector → InkWell (chip gradient đang chọn: splash trắng .12); `_DefaultTimeTile` gold → **lavender** (splash gold → rose .08 theo luật ripple); `DateFormat` truyền locale (D3) ở custom list + form; form card → `ContentCard`; `_OnceEntrance` ×2 → `EntranceReveal`; language pill → InkWell (trắng .12 onDark / rose .08 nền sáng) + text/icon bóng tối black .28 CHỈ khi onDark. |

### Vòng fix sau Tester (Lead-Dev, 2026-06-11)
- `milestone_reminders_screen.dart:339` — `DateFormat.yMMMd()` thiếu locale ở `_subLine` (G4 flag, ngoài spec C13) → truyền `Localizations.localeOf(context)` (D3 trọn vẹn).
- `memory_cinema_card.dart` finding #5 Tester — `didChangeDependencies` restart Timer mỗi lần dependency đổi (`context.watch<ReactionProvider>` ⇒ reaction realtime reset cửa sổ 7s, slide có thể kẹt) → chỉ restart khi gate `_autoPlayAllowed` THẬT SỰ đổi (hoặc allowed mà timer null).

### Nợ kỹ thuật ghi nhận (không blocking)
- `screen_background.dart` (B1) 0 consumer — các màn vẫn inline `Container(decoration: gradient)` pixel-tương-đương; wire dần khi đụng màn nào thì dùng (tránh churn 15 file cho zero thay đổi nhìn thấy).
- GestureDetector trần còn 2 chỗ NGOÀI spec: `today_ritual_card.dart` `_textLink` (archive links) + `gallery_screen.dart` tap ảnh feed — nợ E7 toàn cục, lượt polish sau.
- NotifCenter ContentCard trong ClipRRect mang shadow riêng bị clip (cosmetic, vô hình khi tĩnh).
- Dead-widgets `couple_info_card`/`masonry_gallery`/`photo_item` chưa dọn (ngoài scope).
- `pubspec.lock` bị đổi mirror pub.dev → pub.flutter-io.cn toàn file (artifact môi trường máy, KHÔNG đổi version) — cân nhắc revert trước commit.

### Verify cuối
- `fvm flutter analyze` → **No issues found** · `fvm flutter test` → **18/18 pass** (2026-06-11, sau vòng fix).

## Vòng 4 — Header ink navy (2026-06-11) ✅

User duyệt: TOÀN BỘ chữ header đổi mực NAVY `textPrimary` (trắng+bóng vòng 2 fail contrast ~1.7:1 trên dawnBlush nhạt — screenshot thật chữ chìm; kiểu SumOne: gradient gánh brand, mực gánh đọc). Trắng CHỈ còn hợp lệ trên scrim tối/ảnh (CounterCard, hero Profile, overlay ảnh, pill gradient đậm, bottom nav) — KHÔNG đụng.

- **A `app_theme.dart`:** default 3 helper → `textPrimary` (eyebrow alpha .55, subtitle alpha .62); logic shadow giữ (chỉ shadow khi `color == white` — ai truyền trắng trên scrim tối vẫn được); doc-comment cập nhật. Dọn 6 call-site `alpha: 0.84` (login/register/forgot/verify/guest/setup) về default.
- **B `sub_screen_app_bar.dart`:** title trắng+shadow → `textPrimary` 18 w800 không shadow (ăn 6 màn con); doc sửa.
- **C `notification_center_screen.dart`:** title inline → textPrimary không shadow; section header HÔM NAY/TRƯỚC ĐÓ → textPrimary .55 không shadow; subtitle unread ăn default A.
- **D:** custom_reminders counter x/20 → textPrimary (warning giữ at-capacity), bỏ shadow; form Save → textPrimary bỏ shadow.
- **E `home_screen.dart`:** greeting 21 w800 → textPrimary không shadow; teaser 13 w500 → textPrimary .62 không shadow. Bell + CounterCard không đụng; `_entrance` không đụng.
- **F `setup_screen.dart`:** sign-out pill → fill white .72 border .65 + chữ/icon textPrimary .85; mode tab CHƯA chọn white .75 → textPrimary .60 (đang chọn giữ nguyên — pill nền TRẮNG nên label vốn đã navy, không có nhánh trắng-trên-gradient-đậm); invite card GlassCard → `ContentCard` r24 (title textPrimary 13 w700, mã code → `accentLoveDeep` 30 w900, description → textSecondary 13, rejoin hint textSecondary 12, statusColor nhánh chưa-couple white → textSecondary, divider/icon → navy nhạt); **fix lặp copy:** nhánh couple-active description = null (chỉ giữ title `inviteCodeTiedToAccount`); `InviteActionButtons` → `onDark: false` (biến thể rose nền sáng có sẵn).
- **G `gallery_screen.dart`:** month chip fill white .16 → .72, border .18 → .65, chữ → textPrimary .75 bỏ shadow; `_MarqueeRow` chips xác minh ĐÃ navy trên chip tint trong card trắng → không đổi; eyebrow/title/subtitle ăn qua A.
- **H `language_toggle_button.dart`:** biến thể onDark → pill white .72 + viền .65, chữ/icon textPrimary, bỏ text shadows, ripple rose .08 (cùng họ HeaderIconButton); biến thể nền sáng giữ.
- **I ARB:** vi `galleryTitle` → "Thư viện ảnh"; `editCoupleBadge` vi → "HỒ SƠ CẶP ĐÔI" / en → "COUPLE PROFILE"; `fvm flutter gen-l10n` chạy lại.
- **Verify:** gen-l10n OK · `fvm flutter analyze` **No issues found** · grep: không call-site nào override 3 helper bằng trắng/alpha; `Shadow(` còn lại trong các file sửa toàn `BoxShadow` container (không phải bóng chữ).

## Nhật ký
- [2026-06-11] [dev] **Header icon TRẦN toàn app (user kèm screenshot gear: "bỏ cái badge màu trắng đi, làm hết tất cả toàn app"):** (1) `header_icon_button.dart` viết lại — bỏ toàn bộ decoration squircle (gradient trắng .98→.92 + viền + shadow rose), còn icon trần `textPrimary` 24 (default 20→24) trong vùng chạm 44 + InkWell ripple r16 — mọi consumer ăn theo (back `subScreenAppBar` tất cả màn con, auth ×3, notif-center ×2, settings icon Profile); (2) bell Home: bỏ Container squircle 48 + ShaderMask gradient → icon trần navy 26 vùng chạm 48, badge đỏ neo lại right/top -4→2; (3) skeleton Profile 44r16 → 24r8. **Ngoại lệ giữ đĩa nền: icon đè trên ẢNH** (pencil hero Profile — contrast trên ảnh user không đảm bảo). Analyze toàn repo 0 issue + test 18/18. design-system.md đã sync (B3 + bell).
- [2026-06-11] [dev] Stage A xong: A6.1 shadow helpers (smart default theo màu trắng) + 9 primitives B1–B9 + vá Reduce Motion aurora/cinema (kèm TickerMode gate Timer) + C0 refactor Home/ritual không đổi pixel + doc luật B11. Analyze 0 issue. Chờ Tester.
- [2026-06-11] [dev] Stage B xong: 4 nhóm song song apply C1–C15 + C17 trên 15 màn + language_toggle (bảng trên). Analyze 0 issue từng nhóm + toàn repo.
- [2026-06-11] [dev] Vòng fix sau Tester: D3 milestone `_subLine` + finding #5 cinema timer-reset. Analyze 0 issue, test 18/18.
- [2026-06-11] [dev] **Type-scale normalize (audit Lead ~45 chỗ):** chuẩn hoá mọi fontSize lẻ về scale chính thức (10/11/12/13/14/15/16/18/20/21/22/26/30+display), CHỈ đổi số — không đụng weight/màu/spacing/layout. Files: gallery (28 — gồm helper `_galleryCardTitleStyle` default 16.5→16 + call-sites `size:` lẻ 15.3/14.5/15.6/11.1/11.5/11.7/13.1) · setup 4 · notification_center 4 (17→16) · register 2 · home 2 · profile 2 (24→22: text initials avatar placeholder, là CHỮ không phải icon) · reaction_bar 2 · verify_email 1 · forgot_password 1 · setup/counter_card/today_ritual_card/blocking_loading_overlay 1 mỗi file (9.5→10, 9→10, 13.5→13). Ngoài bảng mapping: 11.7→12 + 13.1→13 (làm tròn về giá trị scale gần nhất = default của chính helper). Dead widget `couple_info_card` còn 17 — giữ nguyên theo scope. Analyze 0 issue.
- [2026-06-11] [dev] **Vòng 4 header ink navy:** toàn bộ chữ header trắng → `textPrimary` không shadow (helpers A + 8 màn + 3 widget, bảng mục Vòng 4); invite card setup → ContentCard + fix lặp copy; ARB galleryTitle/editCoupleBadge. Analyze 0 issue.
- [2026-06-11] [dev] **Header-sync (vòng 2, user re-check):** `sub_screen_app_bar.dart` title textPrimary → TRẮNG 18 w800 + bóng tối (ăn 6 màn con — đóng "Settings màu khác"); gỡ HỘP chip eyebrow 8 màn (login/register/forgot/verify/guest/setup/profile/gallery `_buildGalleryEyebrow`) → text trần `pageEyebrowStyle`, spacing 12; NotifCenter `_Header` bỏ pageTitle 32 → 1 hàng back ‖ title 18 trắng giữa ‖ overflow (counterweight 44 khi không menu); action app-bar trắng + bóng tối (Save form, counter x/20 — warning giữ khi at-capacity). Analyze 0 issue.
- [2026-06-11] [dev] **Vòng 5 — EyebrowChip (B12):** tạo `lib/widgets/eyebrow_chip.dart` (pill white .72 + viền trắng .65 + shadow rose .14 blur 10 + icon 13 `accentLoveDeep` optional + label `pageEyebrowStyle(.70)` navy) — bản recolor bề-mặt-sáng của chip cũ theo yêu cầu user. Thay text trần ở 8 màn (login/register/forgot/verify/guest/setup/profile/gallery) với icon khôi phục: lock/userPlus/keyRound/mailCheck/sparkles/heart-pencil/sparkles/sparkles; chip→title spacing 14. Analyze 0 issue.
- [2026-06-11] [dev] **Vòng 5b — Settings header kiểu landing (user yêu cầu):** `subScreenAppBar` cho phép `title: null` (chỉ back disc); Settings bỏ title app-bar → header lớn trong body: `EyebrowChip(settingsBadge, icon: settings)` + pageTitle `settingsTitle` + subtitle mới `settingsHeaderSubtitle` (+2 key ARB vi/en, gen-l10n). Analyze 0 issue.
- [2026-06-11] [dev] **Vòng 5c — Header lớn kiểu landing cho 6 màn con còn lại:** áp pattern Settings (appBar `title: null` chỉ back + EyebrowChip → 14 → pageTitle → 8 → pageSubtitle → 20) cho notification_center (header FIXED, hàng back‖Spacer‖overflow, subtitle = dòng unread/`notifAllCaughtUp` hiện mọi state) · journal (`_JournalHeader` cuộn trong list/loading, fixed trên empty/error; streak summary dời vào header; index EntranceReveal giữ) · love_note_history (`_HistoryHeader` item 0 thay subtitle cũ) · milestone_reminders (header item đầu ListView thay caption) · custom_reminders (`_ScreenHeader` pinned trên switch 4 state, giữ counter x/20) · custom_reminder_form (chip `bellPlus` + title động, KHÔNG subtitle, giữ Save). +10 key ARB vi/en (badge×6 + headerSubtitle×4), gen-l10n OK. Analyze 0 issue.
- [2026-06-11] [dev] **Đồng hồ CounterCard = TỔNG GIỜ bên nhau (user yêu cầu):** `_LiveElapsedClock` bỏ `% 24` ở cột giờ (trước đó anchor nửa-đêm + %24 làm pill ≡ đồng hồ thời gian thực) → cột GIỜ = `elapsed.inHours` tổng, format `NumberFormat.decimalPattern(locale)` ("17.640" vi / "17,640" en), tự co giãn bề rộng; PHÚT/GIÂY giữ positional 2 chữ số width 40. Bonus: tick 1s giờ check `TickerMode.valuesOf` (luật Timer-tab-ẩn). Analyze 0 issue.
