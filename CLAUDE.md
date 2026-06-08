# Dear Embeiu — Project Context cho Claude

> Bộ nhớ dự án hợp nhất, commit vào repo để Claude ở mọi máy hiểu ngay hiện trạng — không phải dò lại. Nguồn: memory cá nhân (`~/.claude/.../memory/`). Code/quyết định đổi → cập nhật file này (xem [Quy ước làm việc](#quy-ước-làm-việc-với-claude)). Ngôn ngữ với user: tiếng Việt. User: thesavior9820.
>
> 📁 Quản lý theo feature ở [`project/`](project/README.md): mỗi feature 1 folder (`project/features/<ten-feature>/`, tên theo chủ đề không tiền tố số — vd `language`, `analytics`) gồm `overview.md` (PO) + `design.md` (Designer) + `dev.md` (Dev) + `test.md` (Tester); mỗi role tự ghi việc đã làm. `CLAUDE.md` = *toàn dự án*; `project/` = *từng feature*. Luật & lifecycle: [`project/README.md`](project/README.md).
>
> 📚 **Tài liệu chi tiết (tách khỏi CLAUDE.md cho gọn — ĐỌC khi làm việc liên quan, file dưới KHÔNG tự nạp vào phiên):** Design system (token/màu/layout từng screen) → [`project/design-system.md`](project/design-system.md) · Mô hình 4 vai + orchestrator + catalog rủi ro Tester → [`project/roles.md`](project/roles.md) · Product strategy (đối thủ/monetization) → [`project/strategy.md`](project/strategy.md) · **Kiến trúc chi tiết** (services/providers/models/screens/nav gotchas) → [`project/architecture.md`](project/architecture.md) · **Firebase chi tiết** (Firestore rules/CF/Dev-Prod/backward-compat) → [`project/firebase.md`](project/firebase.md) · **Build gotchas** (iOS IPA/simulator/hooks) → [`project/build-guide.md`](project/build-guide.md). Các mục 2/5/8/9/10/12/13 dưới đây chỉ là tóm tắt — cần chi tiết thì mở đúng file.

## 0. Operating rules (ĐỌC TRƯỚC — 6 luật bất biến)

> Chi tiết & lý do ở [Quy ước làm việc](#quy-ước-làm-việc-với-claude) (cuối file) + `project/roles.md`. Đây là bản rút gọn front-load để bám sát mọi phiên.

1. **Ngôn ngữ:** trả lời user bằng **tiếng Việt**.
2. **Toolchain Flutter — TÙY MÁY:** dùng đúng toolchain của máy hiện tại. Máy nào bare `flutter`/`dart` sai version (vd **máy cty = 3.5.4 → FAIL**) thì dùng `fvm flutter`/`fvm dart` (máy đó có hook **local-only** ở `.claude/settings.local.json` ép — KHÔNG commit nên không ảnh hưởng máy khác). Máy nào bare flutter đúng version (vd **máy nhà**) thì dùng trực tiếp. i18n: luôn sửa CẢ `app_en.arb` + `app_vi.arb` rồi chạy `gen-l10n` (qua toolchain đúng của máy).
3. **Ranh giới role:** chỉ **Dev** sửa `lib/`/rules/functions. PO/Designer/Tester KHÔNG (mục 9). Mỗi role chỉ ghi file của mình trong `project/features/<ten>/`.
4. **Đĩa là nguồn sự thật:** verify bằng đọc file + `flutter analyze` (qua toolchain đúng của máy — xem #2), KHÔNG tin báo cáo suông. Mâu thuẫn → đĩa thắng. **Đụng `firestore.rules`/`storage.rules`/`functions/index.js` → chạy `scripts/test-firebase-rules.sh` trước khi coi là xong (có Stop hook tự enforce — xem §13).**
5. **Tự cập nhật context:** thay đổi gì xong → tự cập nhật `project/features/<ten>/` + `project/ROADMAP.md` (+ file này nếu đụng toàn dự án), không cần nhắc. **Git commit/push:** KHÔNG tự làm — chờ user (có hook chặn). **Deploy Firebase:** ĐƯỢC phép chạy không cần hỏi khi task cần (rules/storage/functions); mỗi deploy TỰ GHI VẾT để restore vào `project/.firebase-deploy-log/` (hook `trace-firebase-deploy.sh`: snapshot rules + git HEAD + thời điểm; cách restore ở đầu `HISTORY.md`).
6. **Slash command nhanh** (`.claude/commands/`): **`/lead`** = 1 đầu mối mặc định (tự chọn lăng kính theo câu, bật pipeline khi xây feature) · `/po` `/designer` `/dev` `/tester` `/feature-new` `/roadmap` `/done`. **Mode mặc định = Mode 1 (PO Orchestrate):** xây feature thì user chỉ nói với Lead/PO, PO tự spawn subagent `.claude/agents/` (`dev`/`designer`/`tester`/`po`) — tester read-only (không sửa được code). Việc nhỏ / hỏi nhanh → nói thẳng, khỏi nghi thức.

---

## 1. Tổng quan sản phẩm

Dear Embeiu (tựa tiếng Việt: "Kỷ Niệm Của Chúng Mình") — Flutter app cho các cặp đôi.
pubspec description: "Dear Embeiu — lưu giữ kỷ niệm và đếm ngày yêu cùng người ấy."

Ba tính năng cốt lõi:
1. Đếm ngày yêu — couple lưu `anniversaryDate`; app tính số năm/tháng/ngày (model `CounterData`, hiển thị ở HomeScreen).
2. Thư viện ảnh dùng chung — 2 người cùng đăng ảnh vào album couple, layout masonry kiểu Pinterest; đồng bộ realtime qua Firestore theo `coupleId`; mỗi ảnh ghi người đăng.
3. Love reminders — local scheduled notifications (mục 6).

Ghép đôi qua mã mời (invite code): A tạo couple → nhận mã 6 ký tự (`invite_codes/{code}`) → chia sẻ cho B → B nhập mã để join.

Identity:
- App id (Android & iOS): `com.tony.dearembeiu`
- Firebase project: `tonyembeiu` (.firebaserc default, region us-central1)
- Version: 1.1.1+6 (1.0 + 1.1.0 đã live App Store; **1.1.0 = reactions/streak/journal/daily-question/love-note 2 chiều — đã duyệt "Ready for Distribution" 2026-06-06**; **1.1.1+6 = bản patch đang chuẩn bị submit: fix login/logout/email-verify/xoá tài khoản + backend backward-compat**); Flutter SDK env `^3.11.4` (dev: Flutter 3.41.6 stable)
- Ngôn ngữ: vi + en (supportedLocales). ARB ở `lib/l10n/app_en.arb`, `app_vi.arb`. Mặc định system locale.
- GitHub: github.com/tuandda98/dear_embeiu; privacy policy host GitHub Pages (`docs/` qua Firebase Hosting).
- Brand: "Sunset Romance", màu hồng #FF6B9D, chỉ light mode (`AppTheme.lightTheme`).
- Chuẩn bị phát hành Google Play (`PLAY_STORE_RELEASE.md`, `PLAY_CONSOLE_CONTENT.md`).

---

## 2. Kiến trúc code

> ➡️ Chi tiết services/providers/models/screens + navigation gotchas: [`project/architecture.md`](project/architecture.md).

Pattern: Provider (ChangeNotifier) + service layer. UI ← providers ← services (Firebase + local).

Entry `lib/main.dart`: Hive → Firebase → FCM+Push → Reminder → InstallState → Crashlytics → `runApp`. MultiProvider: Auth/Couple/Photo/Locale/ReminderProvider. `home: SessionRouteScreen(branded:true)`. Routes: `lib/app/app_routes.dart`. **`MaterialApp.navigatorKey`** (2026-06-05): session-revocation listener ngoài widget-tree.

Navigation: `SessionResolver.resolveStartRoute()` → guest (chưa auth) / setup (authed, chưa couple) / home (có couple). ⚠️ **Mọi luồng đặt user vào Home PHẢI qua authGate→resolver** — KHÔNG `pushNamed('/home')` thẳng (watcher couple/note/question/reaction/streak/notification chỉ được wire trong SessionResolver; push thẳng → watcher không chạy → realtime sync vỡ).

Services: auth (~548 dòng, Firebase+local fallback) · user · couple (~726 dòng, transaction join) · photo · storage (local JSON cache) · reminder · push_notification · firebase_bootstrap · install_state.

Providers: auth · couple · photo · reminder · custom_reminders · locale · love_note · daily_question · journal · reaction · streak · notification_inbox. love_note+daily_question+reaction+streak+notification_inbox **wire watch ở `session_resolver` khi couple active, clear khi sign-out/no-couple.**

Models: app_user · couple · photo · account_invite · counter_data · auth_status.
Screens: session_route · login/register/forgot_password/verify_email · setup (prefill ngày từ guest) · home · gallery · profile · settings · milestone_reminders · custom_reminders · guest_counter (landing unauth, root — không có nút back).
Localization: `AppL10n.strings` (no BuildContext). Sửa ARB → `flutter gen-l10n`. Tránh ICU `{...}` trong chuỗi không phải placeholder (dùng `<...>`).

---

## 3. Tech stack

Dart SDK env `^3.11.4` (pubspec.yaml đầy đủ, khỏi grep)

- Firebase/cloud: firebase_core ^4.1.1, firebase_auth ^6.0.2, cloud_firestore ^6.0.1, cloud_functions ^6.0.1, firebase_storage ^13.0.1, firebase_messaging ^16.0.2, firebase_crashlytics ^5.2.2, firebase_analytics ^12.4.2 (feature analytics — `AnalyticsService` no-context, no-op khi Firebase chưa sẵn/opt-out; posture no-tracking; toggle opt-out ở Settings).
- State mgmt: provider ^6.1.0 (+ flutter_localizations từ SDK).
- Local storage: hive ^2.2.3, hive_flutter ^1.1.0 (cần code-gen), flutter_secure_storage ^9.2.4 (session/local auth fallback), path_provider ^2.1.1.
- Notifications: flutter_local_notifications ^19.4.0, timezone ^0.10.1, flutter_timezone ^4.1.1.
- Media/UI: image_picker ^1.1.0, cached_network_image ^3.3.1, flutter_staggered_grid_view ^0.7.0 (masonry), cupertino_icons ^1.0.8.
- Misc: intl ^0.20.2, uuid ^4.0.0, connectivity_plus ^6.1.4, url_launcher ^6.3.1.
- UI revamp (Đợt 1, 2026-06-02): flutter_animate ^4.5.2 (staggered entrance), shimmer ^3.0.0 (skeleton loaders), lucide_icons ^0.257.0 (bộ icon), confetti ^0.8.0 (**chưa dùng** — dành Đợt 2 invite reveal). **Font: Be Vietnam Pro bundled ở `assets/fonts/` (weight 300–800); ĐÃ GỠ `google_fonts` 2026-06-06.**
- Dev deps: flutter_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.14.3, flutter_native_splash ^2.4.3, hive_generator ^2.0.1, build_runner ^2.4.9.
- Branding assets: flutter_launcher_icons (màu #FF6B9D, web theme #FF4D6D, iOS flatten remove-alpha) + flutter_native_splash (nền hồng #FF6B9D, heart trắng). **Typography (2026-06-06): TOÀN APP dùng 1 phông Be Vietnam Pro bundled — bỏ Fraunces + Plus Jakarta Sans + google_fonts. Lý do: google_fonts fetch runtime gây VỠ DẤU tiếng Việt + nháy font trên iOS; Be Vietnam Pro Việt-first, bundled = offline ổn + dấu chuẩn. Hero/số đếm w700/800, body w400/500; `ThemeData.fontFamily` + mọi helper ở `app_theme.dart`.**

---

## 4. Native config (iOS/Android)

App id chung: `com.tony.dearembeiu`.

Android (`android/app/build.gradle.kts`):
- applicationId + namespace = `com.tony.dearembeiu`
- compileSdk 36, targetSdk 35, minSdk = `flutter.minSdkVersion`; NDK `28.2.13676358`
- Java/Kotlin 17, coreLibraryDesugaring bật (cần cho flutter_local_notifications API cũ)
- Release: ProGuard/minify bật; signing đọc từ `android/key.properties` nếu có, không thì fallback debug. key.properties + keystore KHÔNG commit.
- Firebase: `android/app/google-services.json` (project `tonyembeiu`).

iOS (`ios/Runner/Info.plist`):
- Bundle id qua `$(PRODUCT_BUNDLE_IDENTIFIER)`; display name "Dear Embeiu".
- `UIBackgroundModes: remote-notification`; `NSPhotoLibraryUsageDescription` (text VI); `ITSAppUsesNonExemptEncryption: false`.
- Scene-based lifecycle. Phone portrait; iPad mọi hướng.
- `ios/Runner/GoogleService-Info.plist` (project `tonyembeiu`); `PrivacyInfo.xcprivacy` có khai báo.
- Build-phase "Strip Invalid Architectures" (Podfile post_install): lipo remove `i386/x86_64` khỏi frameworks + re-sign — bắt buộc cho Transporter. **⚠️ GUARD simulator:** skip strip khi `PLATFORM_NAME=iphonesimulator` (chi tiết [`project/build-guide.md`](project/build-guide.md)).
- ⚠️ Thiếu `CFBundleLocalizations`/`CFBundleAllowMixedLocalizations` (gap i18n — mục 7).

---

## 5. Firebase backend

> ➡️ Chi tiết Firestore rules mỗi collection, CF implementation, Dev/Prod setup đầy đủ: [`project/firebase.md`](project/firebase.md).

Firebase project `tonyembeiu` (us-central1). `.firebaserc`: `default`=`tonyembeiu-dev` (an toàn, bare deploy không trúng prod), alias `prod`. **Deploy prod PHẢI `--project prod`.**

**Dev/Prod split:** `--release` → PROD (`com.tony.dearembeiu`); debug/profile → DEV (`com.tony.dearembeiu.dev`). Chi tiết setup: [`DEV_PROD_SETUP.md`](DEV_PROD_SETUP.md) + [`project/firebase.md`](project/firebase.md).

⚠️ **Backward-compat (CRITICAL):** Field optional (`coupleCode`/`languageCode`/`sessionToken`) đọc bằng `data.get('field', null)` trong rules — KHÔNG `data.field` trực tiếp (app 1.0 cũ không gửi field → engine "undefined" → DENY → vỡ `permission-denied`). Sửa rules = **chỉ ADDITIVE**, không siết cái app cũ đang dùng.

**Firestore collections (tóm tắt):**
- `users/{uid}` — profile, inviteCode (immutable), coupleId, status; `allow delete: if false`.
- `invite_codes/{code}` — mã mời; createdAt+userId immutable; no delete.
- `couples/{coupleId}` — waiting_partner→active khi join; inviteCode+creator immutable.
- `couples/{coupleId}/photos/{photoId}` — authorUserId+uploadDate immutable.
- `couples/{coupleId}/photos/{photoId}/reactions/{uid}` — 6 emoji; collectionGroup index deployed.
- `couples/{coupleId}/notes/{uid}` — Love Note, text ≤140.
- `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}` — Daily Question, text ≤280. Marker doc cha: `bothAnswered` (streak) + `questionVi/En` (journal permanent).
- `users/{uid}/devices/{...}` — FCM tokens + `languageCode`. ⚠️ `hasOnly` rule phải liệt kê đủ field (push hỏng âm thầm nếu thiếu).
- `users/{uid}/notifications/{autoId}` — Notification center; CHỈ CF ghi, client read/mark-read/delete. ✅ DEV; **prod chờ lệnh**.
- `reports/{autoId}` — UGC reports, create-only.

**Storage:** `couple_photos/{coupleId}/{file}` — members only, <10MB.

**Cloud Functions** (`functions/index.js`, v2): `pruneDeadDevices` · `sendPartnerPhotoNotification` · `notifyPartnerJoined` · `notifyPartnerLeft` · `notifyLoveNote` · `notifyDailyAnswer` · `notifyPhotoReaction` · `deleteAccount` (callable) · `leaveCoupleCleanup` (callable, dọn rác mồ côi khi sole-member rời — ⚠️ **prod chờ lệnh**). Tất cả dùng `writeInboxNotifications` (inbox) + `sendToRecipientDevices` (localize vi/en theo `languageCode`).

**Deploy:** `npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu` | `--only functions`. **Trước deploy rules: `scripts/test-firebase-rules.sh`.**

---

## 6. Tính năng: Reminders & Push

> ➡️ Chi tiết: [`project/features/reminders/`](project/features/reminders/overview.md) (local), [`project/features/gallery/`](project/features/gallery/overview.md) (push). Mục này chỉ ghi nền tảng ít đổi.

Hai loại notification, đừng nhầm:
- Love reminders — local only (không network): `reminder_provider.dart` (what — Hive `reminder_settings`) + `reminder_service.dart` (how — channel `love_reminders`, id auto 1001–1099, text từ `AppL10n.strings`). v2 (2026-05-31): bỏ daily nudge; 7 mốc curated user tự bật/tắt (`models/milestone_reminder.dart` enum `MilestoneType`: every100/d520/d1000/d1314/halfYear/yearly/inactivity; default Dv4 lưu Hive `milestone_<name>`) ở `screens/milestone_reminders_screen.dart` (màn Cột mốc, badge số mốc bật, dim khi master off). Mốc bật → schedule đúng ngày (bỏ "nhắc trước 3 ngày"); one-shot đã-qua/anniversary tương lai → không schedule, không crash. Gate "Lời nhắc của chúng mình" (custom) khi master off → force-open dialog (Dv6). Dv8 giờ-theo-mốc: "Giờ nhắc" = giờ mặc định (`ReminderSettings.hour/minute`); mỗi mốc có giờ riêng tuỳ chọn lưu Hive `milestone_<name>_hour/_minute` (absent=mặc định); provider `milestoneTimeOf`/`effectiveTimeOf`/`setMilestoneTime`; schedule dùng `effectiveTimeOf` ⇒ đổi giờ mặc định chỉ reschedule mốc chưa-đặt-riêng.
- Custom reminders — local only (feature mới, → [`project/features/custom-reminders/`](project/features/custom-reminders/overview.md)): user tự tạo reminder riêng (tên+ghi chú+ngày+giờ+kiểu lặp once/daily/weekly/monthly/yearly), `custom_reminders_provider.dart` + `ReminderService.scheduleCustom/nextFireFor` (clamp ngày 31/29-02), notif id 2000–2999, cap 20, lock-step với master toggle (D7). Lưu Hive `custom_reminders`, không Firestore/push.
- Daily question reminder — local only (feature b2, 2026-06-04): nhắc trả lời câu hỏi mỗi ngày (cú hích daily-open kiểu SumOne). `ReminderService.scheduleDailyQuestion` (lặp `DateTimeComponents.time`, **notif id 1004 — ĐỘC LẬP master milestone toggle, ngoài `_autoIds`**) + state ở `ReminderProvider` (Hive keys `dqReminder*`, default ON 20:00). Tile switch+giờ ở Settings; schedule trong `sync()` TRƯỚC early-return master. Thuần local, không deploy.
- Push partner-photo / partner-joined — FCM qua CF `sendPartnerPhotoNotification` / `notifyPartnerJoined` (mục 5) khi partner đăng ảnh / khi B ghép cặp báo A (vá hở vòng lặp kích hoạt couple, 2026-06-01).
- Deep-link tap (2026-06-01): chạm push mở đúng tab Home — `NotificationTapRouter` (ValueNotifier ở `push_notification_service.dart`, không navigatorKey/package) + `getInitialMessage`(cold)/`onMessageOpenedApp`(warm); `HomeScreen` consume ở initState + listener. Map: `photo_posted`/`photo_reaction`→Gallery(1), `partner_joined`/`partner_left`/`love_note`/`daily_question`→Home(0) (**`partner_left` vá 2026-06-06** — trước thiếu nhánh tap → rơi default no-op).
- **Notification center** (feature notifications, 2026-06-06 → [`project/features/notifications/`](project/features/notifications/overview.md)): trung tâm xem lại thông báo, **Firestore-backed** (mục 5 `users/{uid}/notifications`) — KHÁC push ở chỗ KHÔNG mất khi app bị kill / tắt push. Bell+badge số chưa đọc ở header Home → `NotificationCenterScreen`; tap item tái dùng chính `NotificationTapRouter` để điều hướng tab.

---

## 7. Tính năng: Đa ngôn ngữ (i18n)

> ➡️ Trạng thái, 7 gap (A–G), decision log (D2/D3), roadmap: [`project/features/language/`](project/features/language/overview.md). Nền tảng kỹ thuật ít đổi:

`AppLocalizations` (ARB en/vi). `AppL10n.strings` = truy cập l10n không cần BuildContext (services/isolate). `LocaleProvider`: Hive box `app_settings` key `locale`, `null`=system. `main.dart`: supportedLocales [en, vi], 4 delegates, `localeResolutionCallback` → `AppL10n.setLocale()` (fallback English). Picker dùng chung: `lib/widgets/language_toggle_button.dart`.

> ⚠️ Gen l10n (2026-05-31): project dùng `l10n.yaml` (output ra `lib/l10n/`, committed) + `flutter: generate: true` trong pubspec. Khi thêm/sửa key: sửa cả `app_en.arb` + `app_vi.arb` rồi `flutter gen-l10n`; tránh ICU (`{...}`) trong chuỗi không phải placeholder (dùng `<...>`).

---

## 8. Design system

> ➡️ **Chi tiết đầy đủ (token màu/hex, typography, layout từng screen, components):** [`project/design-system.md`](project/design-system.md). Dưới đây chỉ là tóm tắt.

Brand "Sunset Romance" — romantic minimalism, gradient hồng, glassmorphism, serif cho số hero, trái tim là motif chính. Chỉ light mode, Material 3. Style ở `lib/theme/app_colors.dart` + `app_theme.dart`.
- **3 gradient chủ đạo:** `sunsetRomance` (#FF6B9D→#FFB6C1, hero/counter), `dawnBlush` (nền app & auth), `dreamyMint` (gallery/milestone).
- **Accent:** accentLove #FF4D6D, accentLoveDeep #E63956, accentLavender #A78BFA. **Text:** textPrimary #1A1A2E.
- **Typography (2026-06-06):** TOÀN APP **1 phông Be Vietnam Pro** (bundled `assets/fonts/`, weight 300–800) — Việt-first, dấu chồng (ấ ề ộ ữ) chuẩn, offline. ĐÃ BỎ Fraunces/Plus Jakarta/google_fonts. Hero/số đếm w700/800, body w400/500; wired `ThemeData.fontFamily` + helpers `app_theme.dart`.
- **Token:** radius card 28 / pill 999 / input 20; nút height 52 nền navy bo pill; AppBar phẳng; FAB tròn accentLove.
- **Revamp Đợt 1 (2026-06-02):** Lucide icons, GlassCard (blur thật), ShimmerSkeleton, AppMotion (200–320ms easeOutCubic) + flutter_animate entrance. Dev xong, CHƯA submit (chờ 1.0 duyệt → phát hành 1.1). → [`project/features/ui-revamp/`](project/features/ui-revamp/overview.md).

---

## 9. Mô hình 4 vai

> ➡️ **Chi tiết đầy đủ (ranh giới từng role, quy tắc thực thi orchestrator, ranh giới PO tự quyết vs hỏi user, catalog rủi ro Tester):** [`project/roles.md`](project/roles.md). Dưới đây chỉ là tóm tắt.

User vận hành dự án như team nhỏ với 4 lăng kính, mỗi role tôn trọng đầu ra role trước: *PO (xây gì & vì sao) → Designer (trông thế nào) → Dev (implement) → Tester (nghiệm thu).* User gắn role nào thì bật persona đó.
- **2 mode** (**mặc định Mode 1** — dùng `/lead` hoặc `/po … orchestrate`): 🟦 **Mode 1 — PO Orchestrator** (user chỉ nói với PO/Lead; PO tự spawn subagent Designer→Dev→Tester chạy TUẦN TỰ, có PO gate verify giữa mỗi stage); 🟩 **Mode 2 — User tự điều phối** (user tự gắn role, bàn giao qua file `project/`).
- **Ranh giới (bất biến):** PO / Designer / Tester **KHÔNG** sửa code `lib/`; chỉ **Dev** implement. PO ra research + spec; Designer ra design spec (`docs/design/`); Tester chỉ xuất PASS/FAIL, không fix.
- **Definition of Done, quy tắc thực thi orchestrator, ranh giới PO tự quyết vs hỏi user:** xem [`project/roles.md`](project/roles.md) + [`project/README.md`](project/README.md).

---

## 10. Product strategy

> ➡️ **Chi tiết đầy đủ (đối thủ trực tiếp/toàn cầu, monetization, ghi chú văn hoá VN):** [`project/strategy.md`](project/strategy.md). Số liệu đối thủ từ research 2026-05-30 — directional, re-validate trước khi chốt giá. Dưới đây chỉ là tóm tắt.

- **Danh mục:** app "đếm ngày yêu" + memory keeper; đối thủ trực tiếp là app VN cùng niche (Been Love Memory, Been Together…), KHÔNG phải Paired/Cupla.
- **Target:** cặp đôi trẻ VN (Gen Z/Millennials đầu). **Value prop:** "Không gian riêng tư của 2 người — đếm ngày yêu + lưu kỷ niệm ảnh chung + nhắc nhớ yêu thương."
- **Table stakes còn thiếu:** shared calendar, chat, home-screen widget, daily question, shared to-do/wishlist, dark mode.
- **Monetization:** hiện chưa có gì → hướng freemium (gate theme/sticker/font, widget, AI, app-lock; **KHÔNG** gate kỷ niệm/ảnh cũ). Bước 0 bắt buộc: gắn analytics.

---

## 11. Product roadmap

> ➡️ Roadmap chi tiết ở [`project/`](project/README.md): toàn cảnh [`project/ROADMAP.md`](project/ROADMAP.md) (portfolio), kế hoạch từng feature `project/features/<ten>/roadmap.md`, nợ kỹ thuật ở `overview.md` mỗi feature. Mục này chỉ giữ định hướng & metric ít đổi.

Đã ship (v1.0.0+1, chuẩn bị release Play): counter+milestone · gallery realtime+push · coupling mã mời · auth+xoá tài khoản · reminders local · VN/EN. (5 feature baseline: auth/coupling/counter/gallery/reminders — xem `project/features/`.)

Ưu tiên kế tiếp:
- *NOW:* ~~Analytics~~ 🧪 Test PASS code-level (event funnel + opt-out + privacy, đóng Gap G — chờ runtime GA4 + form console) · Onboarding.
- **Đợt giữ chân 2026-06-04 (đã build, 🧪 Test PASS code-level — chờ smoke-test 2 thiết bị):** ~~Reactions ❤️~~ (b1, deployed) · ~~Day streak~~ (b3 Couple Streak shame-free) · ~~Daily Q reminder~~ (b2) · ~~Couple Journal + Love Note 2 chiều~~ (a2, deployed) · ~~Daily Question vá nền 229 câu no-repeat~~ (a1). Nền tảng habit-loop (trigger→action→variable reward→investment) — xem [`project/ROADMAP.md`](project/ROADMAP.md).
- *NEXT:* Home-screen widget · "Tình yêu hôm nay" (tử vi/tarot cặp đôi) · Shared calendar · Dark mode · Daily question AI.
- *LATER:* Premium/subscription · AI features · LDR/chat/wishlist.

Metric Bắc Đẩu: số cặp active đăng ảnh hằng tuần. Phụ: tỉ lệ ghép đôi, D7/D30 retention theo couple.

Rào cản đặc thù: giá trị chỉ xuất hiện khi *cả 2* tham gia → tối ưu mời/ghép đôi + single-player value trước partner join là then chốt.

---

## 12. Tester: catalog rủi ro (security + logic/edge)

> ➡️ **Catalog đầy đủ (bảng rủi ro từng khu vực + điểm MẠNH đừng báo nhầm là bug):** [`project/roles.md`](project/roles.md) (phụ lục Tester). Chi tiết rải vào "Nợ kỹ thuật / rủi ro" trong `project/features/<ten>/overview.md` + `test.md`.

Bản đồ nhanh: **Auth** (password plaintext local, validation yếu) · **Coupling** (invite-code enumeration, coupleId hijack; join là `runTransaction` → concurrent join AN TOÀN, đừng báo nhầm) · **Gallery** (delete không check author, content-type spoof) · **Counter** (anniversary tương lai, months≈30 sai số) · **Reminders** (permission im lặng, DST). Luôn phân biệt nhánh Firebase vs local (`isUsingFirebase`); rules cần emulator (chưa cấu hình).

---

## 13. Build & run

> ➡️ iOS IPA gotchas, simulator workaround chi tiết, enforcement hook: [`project/build-guide.md`](project/build-guide.md).

Toolchain: Flutter 3.41.6 stable (env `sdk: ^3.11.4`). **Hive cần `build_runner`.**

- `flutter pub get`
- `flutter run`
- **`scripts/ios-sim.sh [device-id]`** — **DÙNG THAY `flutter run` khi chạy iOS simulator** (⚠️ native_assets bug Flutter 3.22+ — chi tiết `project/build-guide.md`). `--clean` để clean+fix+run.
- **`scripts/fix-simulator-native-assets.sh [--force]`** — Fix standalone native assets cho simulator.
- `dart run build_runner build --delete-conflicting-outputs` — khi sửa Hive type adapters.
- `flutter build apk --release` / `flutter build ios --release` / `flutter build ipa --release`
- `flutter analyze` — lint. `flutter test` — test Dart ở `test/`.
- **`scripts/test-firebase-rules.sh`** — CHẠY mỗi khi đụng `firestore.rules`/`storage.rules`/`functions/index.js`. Tự dò JDK 21+. **Stop hook tự enforce cuối lượt.**
- Deploy rules: `npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu`
- Deploy functions: `--only functions` | Firebase login: `npx firebase-tools login`

Config: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` (dynamic — nguồn thật ở `ios/config/`), `.firebaserc`.

### Release management (quy ước từ 2026-06-06)

SEMVER: PATCH=bug · MINOR=feature · MAJOR=breaking. **Build number (`+N`) đếm toàn cục, +1 mỗi lần upload, KHÔNG reset, KHÔNG gắn với patch** (Apple cấm trùng). Branch `release/<x.y.z>`; sau Apple duyệt: `git tag v<x.y.z>+<build>` + merge ngược main. Quy trình: bump pubspec → `flutter analyze` sạch + rules test (nếu đụng backend) → `flutter build ipa --release`. KHÔNG tự commit/deploy-prod (chờ user). Build `--release` tự dùng config PROD.

**Release log:**
| Version | Build | Branch | Trạng thái | Nội dung |
|---|---|---|---|---|
| 1.0.0 | 1 | — | ✅ Live | Bản đầu: counter + gallery + coupling + reminders + auth |
| 1.1.0 | 5 | — | ✅ Ready for Distribution (2026-06-06) | reactions/streak/journal/daily-question/love-note 2 chiều |
| 1.1.1 | 6 | `release/1.1.1` | 🚧 Chuẩn bị submit | fix login/logout/email-verify/xoá tài khoản + backward-compat + CF leaveCoupleCleanup |

---

## Quy ước làm việc với Claude

- Ngôn ngữ: trả lời tiếng Việt.
- Tự cập nhật context: mỗi khi user yêu cầu THAY ĐỔI bất cứ thứ gì (code, thiết kế, hành vi, quyết định sản phẩm, quy ước), xong tự cập nhật file này cho khớp — không cần nhắc, không hỏi xin phép từng lần. Chỉ lưu cái không suy ra được từ code/git (quyết định, lý do, trạng thái, preference).
- Quản lý theo feature (`project/`): mọi việc liên quan một feature → tự cập nhật file tương ứng trong `project/features/<ten-feature>/` (role nào làm ghi vào file role đó: overview=PO, design=Designer, dev=Dev, test=Tester) + dòng trạng thái trong `project/ROADMAP.md`. Feature MỚI chưa có folder → tự tạo `features/<ten-feature>/` (tên theo chủ đề, không tiền tố số) từ `project/_templates/` rồi mới làm. Nhật ký format `- [YYYY-MM-DD] [role] <việc>`. Luật đầy đủ: [`project/README.md`](project/README.md).
- Mô hình 4 vai (mục 9): tôn trọng ranh giới mỗi role. PO/Designer/Tester KHÔNG sửa code sản phẩm; chỉ Dev implement.
- Decision log đã chốt (đừng lật lại trừ khi user đổi ý): i18n D2 (bỏ cờ, dùng letter chip) + D3 (format ngày theo locale) — mục 7.
- File này hợp nhất từ memory cá nhân; nếu chạy Claude ở máy có memory riêng, hai nguồn có thể bổ sung cho nhau.
