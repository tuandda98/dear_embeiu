# 💻 Dev — Onboarding

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** xong (O4 — intro 3 slide), chờ test
- **Người/role:** Dev

## Kế hoạch kỹ thuật (O4 — intro lần đầu mở app)
- *Cách tiếp cận:* màn intro KHÔNG có route riêng. `SessionRouteScreen` (nơi duy nhất gọi `SessionResolver.resolveStartRoute`) sau khi resolve xong: **chỉ khi** route == `AppRoutes.guest` VÀ `!IntroScreen.hasSeen()` thì `setState(_pendingIntroRoute = route)` → build trả `IntroScreen` thay cho loader; `onDone` → `markSeen()` → `pushReplacementNamed(guest)` như luồng cũ. Mọi route khác (`forceUpdate`, `verifyEmail`, `setup`, `home`) navigate ngay, không đổi hành vi — force-update vẫn chạy trước mọi thứ vì gate nằm trong resolver, intro chỉ xét SAU khi resolver trả `guest`.
- *File/hàm đụng tới:*
  - `lib/screens/intro_screen.dart` (MỚI) — `IntroScreen({required onDone})`, static `hasSeen()` / `markSeen()`, `_IntroSlide`, `_Halo`, `_CounterIllustration`, `_MemoriesIllustration`, `_TwoPhonesIllustration`, `_PhoneFrame`, `_MiniGlyph`, `_StoreChips`, `_StoreChip`, `_Dots`.
  - `lib/screens/session_route_screen.dart` — thêm field `_pendingIntroRoute`, nhánh intro trong `_resolveRoute()`, hàm `_finishIntro()`, early-return trong `build()`; import `app_routes.dart` + `intro_screen.dart`.
  - `lib/l10n/app_en.arb` + `app_vi.arb` — 12 key `intro*` (chèn sau `@@locale`), chạy `flutter gen-l10n`.
- *Thay đổi model / Firestore / CF / native:* KHÔNG. Cờ đã-xem lưu local: Hive box `app_settings` (box dùng chung với `LocaleProvider`, mở an toàn nếu chưa mở) key `onboarding_seen_v1` (bool).
- *Cần deploy?* Không (client-only).

## UI
- Nền `AppColors.dawnBlush`, 3 slide `PageView` + dots (dot active dài 22 accentLove), "Bỏ qua" góc trên phải (ẩn ở slide cuối, giữ chỗ 48px để trang không nhảy), nút pill h52 r999 `accentLove` "Tiếp"/"Bắt đầu".
- Minh hoạ vẽ bằng icon Iconsax + đĩa tròn mềm (`_Halo` 2 lớp trắng), KHÔNG thêm asset ảnh. Slide 3 = 2 khung điện thoại `Container` bo 14 + tim ở giữa + 2 chip "App Store"/"Google Play" (chỉ minh hoạ, không link).
- Entrance dùng `EntranceReveal` (order 0–4) ⇒ tự no-op khi Reduce Motion; chuyển trang dùng `jumpToPage` khi `AppMotion.reduceMotion(context)`.
- Text style bám `AppTheme.pageTitleStyle/pageSubtitleStyle/pageEyebrowStyle` + `EyebrowChip`.

## Edge case kỹ thuật đã xử lý
- Hive lỗi / box chưa mở: `hasSeen()` **fail-soft trả `true`** (thà bỏ qua intro còn hơn chặn launch); `markSeen()` nuốt lỗi.
- Không đụng `pushNamed('/home')`; watcher realtime vẫn wire nguyên trong resolver.
- `!mounted` check trước và sau `await hasSeen()` / `markSeen()`.
- Intro hiện đúng 1 lần/thiết bị; user đã đăng nhập (setup/home) hoặc bị force-update KHÔNG bao giờ thấy intro.

## Checklist implement
- [x] `IntroScreen` 3 slide + dots + skip + CTA
- [x] Cờ `onboarding_seen_v1` fail-soft
- [x] Wire tại `SessionRouteScreen` (chỉ nhánh guest)
- [x] l10n 2 ARB + `flutter gen-l10n`
- [x] `flutter analyze` sạch (0 issue thuộc file của O4) + `flutter test` 24/24 pass
- [x] Không hardcode chuỗi (trừ brand name "App Store"/"Google Play")

## Nhật ký implement
- [2026-09-05] [Dev] O3 — **Feature tour "Có gì mới" theo phiên bản** (§2.4 overview). MỚI `lib/data/feature_tour_entries.dart` (`FeatureTourEntry{sinceBuild, icon, title(l10n), body(l10n), targetTab}` + `final List<FeatureTourEntry> featureTourEntries` — 3 entry build **20**: Gửi quan tâm `message_favorite` targetTab 0 · Câu hỏi mỗi ngày mới hơn `message_question` · Mời người ấy dễ hơn `user_add`; release sau chỉ cần append entry với `sinceBuild` mới). MỚI `lib/widgets/feature_tour_sheet.dart`: `class FeatureTour` — `static Future<void> maybeShow(BuildContext context, {void Function(int tab)? onOpenTab})` + `static Future<void> showAll(BuildContext context, {void Function(int tab)? onOpenTab})`, sheet `_FeatureTourSheet` (r28 trắng `cardSurface`, handle, `EyebrowChip` "CÓ GÌ MỚI", tiêu đề `Phiên bản <x.y.z>`, mỗi entry = `IconBadge` lavender + title + body trong `EntranceReveal` ⇒ tự no-op khi Reduce Motion, nút pill "Đã hiểu"; entry có `targetTab` → tappable, pop rồi `onOpenTab?.call(tab)`). Cờ Hive `app_settings` key **`feature_tour_seen_build`** lưu dạng String (box mở kiểu `Box<String>`); **key chưa có = vừa cài → chỉ ghi build hiện tại, KHÔNG hiện** (tránh chồng intro O4); chỉ hiện entry `seen < sinceBuild <= current`; fail-soft mọi lỗi Hive/package_info. `settings_screen.dart`: thêm 1 tile "Có gì mới" (`magic_star`) ngay dưới hàng Chính sách bảo mật trong nhóm General → `FeatureTour.showAll(context)` (chỉ chèn, không refactor). 11 key l10n `featureTour*` vào CẢ 2 ARB + `flutter gen-l10n`. KHÔNG đụng `home_screen.dart` (điều phối gọi `FeatureTour.maybeShow` post-frame). Client-only, không đụng model/Firestore/CF/native, không deploy. `flutter analyze` → 0 issue thuộc file O3 (còn 1 info của `home_screen.dart` — agent khác); `flutter test` 24/24. Không commit.
- [2026-09-05] [Dev] O4 — thêm `lib/screens/intro_screen.dart` (intro 3 slide: đếm ngày yêu / kỷ niệm + câu hỏi mỗi ngày / cần cả hai + 2 khung điện thoại + chip store), cờ Hive `app_settings.onboarding_seen_v1`, wire ở `session_route_screen.dart` chỉ cho nhánh guest chưa xem. Thêm 12 key l10n `intro*` vào 2 ARB + gen-l10n. `flutter analyze` → chỉ còn 2 issue của `home_screen.dart` (agent khác), file O4 sạch; `flutter test` 24/24. Không commit, không deploy.

---

## O2 — Màn chờ partner thành checklist + nhắc lại 24h/72h (2026-09-05)

### File đụng
- `lib/screens/home_screen.dart`
  - Viết lại `_buildWaitingForPartnerBanner(Couple couple)`: từ banner 1 dòng → `ContentCard` r24 p18 với `EyebrowChip("CHỜ NGƯỜI ẤY", icon timer_1)` + 3 bước đánh số (đĩa tròn rose + đường nối hairline) + khối "Trong lúc chờ, bạn vẫn có thể" (3 gạch đầu dòng tim + footer italic).
  - Bước 1 chứa mã mời to (24px w900 ls4) + **nút primary pill h52 r999** "Gửi cho người ấy 💌" (share sheet) + nút phụ rose pill "Sao chép mã".
  - Thêm helper `_buildWaitingStep(...)`, `_shareInviteCode(String)`, `_copyInviteCode(String)`. Share/copy tái dùng ĐÚNG logic của `InviteActionButtons` (`l10n.inviteShareMessage(code)` + `SharePlus.instance.share` có `sharePositionOrigin` cho iPad + `AnalyticsService.logInviteShared('share_sheet'|'copy')`) — không sửa `invite_action_buttons.dart` (widget cluster compact không cho CTA full-width).
  - Mã hiển thị: `couple.coupleCode ?? couple.inviteCode` (khớp quy tắc màn Setup; trước đây banner Home dùng thẳng `inviteCode` — có thể là mã cá nhân sai khi couple có `coupleCode`).
  - `_syncReminders`: thêm `final coupleCreatedAt = couple.createdAt;` + gọi `reminderProvider.refreshInviteFollowUps(waiting: !coupleActive, coupleCreatedAt:, l10n:)` ngay sau `sync(...)` trong post-frame (key debounce đã có `coupleActive` nên partner join là re-trigger).
  - Import: +`share_plus`, +`widgets/content_card.dart`; −`widgets/icon_badge.dart`, −`widgets/invite_action_buttons.dart` (hết dùng trong file). KHÔNG đụng `_maybeRunCatchup` / `_buildCareButton`.
- `lib/screens/setup_screen.dart` — trong `_buildInviteCard` nhánh `isWaitingForPartner`: chèn 3 bước text-only (dùng chung key l10n với Home) trước khối rejoin hint; helper mới `_buildWaitingStepLine(...)`. Không đổi luồng create/join.
- `lib/services/reminder_service.dart` — band MỚI **1180–1189** (`_idInviteFollowUpBase = 1180`, `_maxInviteFollowUps = 10`), ngoài `_autoIds`:
  - `scheduleInviteFollowUps({anchor, title, bodies})` — 2 one-shot tại `anchor+24h` / `anchor+72h`, bỏ mốc đã qua; **cả 2 đã qua → arm 1 cái tại now+24h** (couple chờ nhiều ngày mới mở app vẫn được nhắc). `bodies` xoay vòng. Cancel band trước khi arm.
  - `cancelInviteFollowUps()`.
  - KHÔNG đụng band khác (1001–1099 auto, 1020–1052 daily-question, 1060–1099 lunar, 1100–1159 personal, 2000–2999 custom, 3000–3049 partner).
- `lib/providers/reminder_provider.dart` — `refreshInviteFollowUps({required bool waiting, DateTime? coupleCreatedAt, required AppLocalizations l10n})`: `waiting=false` → cancel (no-op nếu chưa từng arm); `waiting=true` → schedule với anchor `coupleCreatedAt ?? now`. Debounce field `_inviteFollowUpSignature` = `waiting|anchorMs|localeName` (đổi ngôn ngữ cũng re-arm để copy đúng tiếng).
- `lib/l10n/app_en.arb` + `app_vi.arb` (+ `flutter gen-l10n`).

### Key l10n mới (17, cả 2 ARB)
`homeWaitingBadge` · `homeWaitingStep1Title` · `homeWaitingStep1Desc` · `homeWaitingStep1Cta` · `homeWaitingStep1Copy` · `homeWaitingStep2Title` · `homeWaitingStep2Desc` · `homeWaitingStep3Title` · `homeWaitingStep3Desc` · `homeWaitingMeanwhileTitle` · `homeWaitingMeanwhileItem1/2/3` · `homeWaitingMeanwhileFooter` · `inviteFollowUpTitle` · `inviteFollowUpBody24h` · `inviteFollowUpBody72h`.
(`homeWaitingPartnerTitle/Subtitle` cũ giữ nguyên trong ARB nhưng KHÔNG còn được dùng ở Home — chưa xoá để tránh đụng agent khác.)

### Backend
KHÔNG đụng Firestore rules / Cloud Functions / native. Nhắc lại 24h/72h là **local notification thuần** → không cần deploy.

### Verify
`flutter analyze` → **No issues found** · `flutter test` → **24/24 pass**. Chưa smoke-test máy thật (cần Tester: notification 24h/72h thực tế, share sheet iPad, mã hiển thị khi couple có `coupleCode`).

### Nhật ký
- [2026-09-05] [Dev] O2 — banner chờ partner → checklist 3 bước có CTA share + khối "trong lúc chờ"; Setup thêm 3 bước rút gọn; band nhắc lại 1180–1189 (24h/72h) + `refreshInviteFollowUps` wire ở HomeScreen. 17 key l10n mới 2 ARB + gen-l10n. analyze 0, test 24/24. Không commit, không deploy.
- [2026-09-05] [Dev] **Vá theo Tester vòng 1 (test.md):** `InstallStateService.isFreshInstallLaunch` (main set) → feature tour phân biệt cài mới (im lặng) vs nâng cấp (`seen=0` ⇒ HIỆN ở chính bản debut 20); `showAll` lọc `sinceBuild <= current`; `FeatureTourEntry.onOpen` (care → `openCareMessageScreen` qua host context) thay chevron chết; bỏ đệm đáy đôi. Nhắc mời 1180–1189: cancel 1 lần/process khi couple không-waiting (`_inviteFollowUpCleared`) ⇒ hết nổ sau khi ghép/sign-out. Intro: route authed → `markSeen()` ngầm (user cũ đăng xuất không thấy intro), guard double-tap, canh giữa bằng `LayoutBuilder`+`ConstrainedBox`. Landing `get.html`: có `?code=` → KHÔNG auto-redirect store (đã publish `phase3`, verify live). `pubspec` bump **1.6.0+20**. ⏳ Nợ: popover share iPad neo toàn màn (P2).
