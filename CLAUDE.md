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
- Version: **1.3.1+10** (dev — chuẩn bị release). **[2026-06-20] CẢ Apple + Google Play ĐANG LIVE `1.3.0 (build 9)`** (Apple: iTunes API + user xác nhận; Play: scrape softwareVersion=1.3.0 — ghi chú cũ "Apple 1.1.0 / Play 1.2.0" ĐỀU LỖI THỜI; bản cũ hơn: 1.0/1.1.0/1.2.0). **[2026-06-20] CHỐT PARITY 2 NỀN TẢNG: đưa CẢ Apple + Android về cùng `1.3.1+10`**. 2 store đã PARITY sẵn ở **1.3.0(9)** → cùng lên **1.3.1(10)** (build 10 > 9, không trùng). **App Store ID = `6775165592`** → iosStoreUrl `https://apps.apple.com/app/id6775165592`. Từ đây mọi release submit đồng thời 2 store cùng version+build (xem §13 RULE PARITY)). 1.2.0 = REVAMP icon/profile/chat. **1.3.0 = + Cây Tình Yêu (bầu trời 4 buổi) + Tâm trạng hôm nay + nền/trạng thái chat + daily-Q reminder nhiều giờ.** **✅ BACKEND PROD sync ĐỦ cho 1.3.0 (deploy 2026-06-19, snapshot `20260619T174154Z-PROD/`): `deploy --only firestore:rules,functions:notifyPartnerMood,functions:notifyChatMessage --project prod` — rules additive (moods/receipts/prefs.chatBgPhotoId + cả counterBgPhotoIds vì deploy nguyên file), CREATE notifyPartnerMood, UPDATE notifyChatMessage (presence). Verify functions:list prod LIVE. CÒN NỢ riêng: doc `config/app` cho force-update (tạo tay ở Console — chưa làm).** Flutter SDK env `^3.11.4` (dev: Flutter 3.41.6 stable)
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

Services: auth (~548 dòng, Firebase+local fallback) · user · couple (~726 dòng, transaction join) · photo · storage (local JSON cache) · reminder · push_notification · firebase_bootstrap · install_state · **app_update (force-update gate 2026-06-14 — đọc `config/app`, so build number toàn cục, FAIL-OPEN)**.

Providers: auth · couple · photo · chat · reminder · custom_reminders · locale · daily_question · **mood (2026-06-19)** · journal · reaction · streak · notification_inbox. (**love_note GỠ 2026-06-14** — feature Love Note retired, thay bằng Chat.) chat+daily_question+**mood**+reaction+streak+notification_inbox **wire watch ở `session_resolver` khi couple active, clear khi sign-out/no-couple.** ⚠️ session_resolver: providers truyền vào `_resolve` qua **named-param** (không phải biến chung) — thêm provider mới nhớ thêm CẢ param signature + call site.

Models: app_user · couple · photo · account_invite · counter_data · auth_status.
Screens: session_route · login/register/forgot_password/verify_email · setup (prefill ngày từ guest) · home (**nav 4 tab từ 2026-06-11**: Home/Chat/Gallery/Profile) · **chat (tab 1 — feature chat; 2026-06-17 đổi thành FULL-SCREEN DRILL-IN: vào tab Chat → ẩn hẳn floating nav + header có ← back về tab vừa rời; vẫn là IndexedStack child (không pushed route), back qua `_selectTab(_previousIndex)` + `PopScope` cho back hệ thống Android); **[2026-06-18] ẢNH NỀN CHAT tuỳ chọn (feature `chat-background`): render FULL-BLEED ở shell HomeScreen (Positioned.fill sau SafeArea, tràn cả status bar) — ChatScreen giữ trong suốt; nguồn = ảnh gallery couple, picker lọc ảnh dọc+đủ-nét, sync 2 máy qua `prefs/home.chatBgPhotoId`** · gallery · **profile (redesign nửa dưới 2026-06-14, Concept B "Hành trình & Huy hiệu": bỏ 4 ô stat trùng → `MilestoneTrail` (dải cột mốc ngang curated [100,365,520,1000,1314,1825,3650]); bỏ "Tủ kỷ niệm" 2 menu phẳng → lưới 2×2 huy hiệu `_AchievementsGrid` (StatefulWidget cache count). **[redesign v2 2026-06-18] CẢ 4 ô hiện CON SỐ + chevron góc nhỏ đồng bộ (bỏ mũi tên ">" to lệch ở Nhật-ký — nay hiện số câu qua `DailyQuestionService.countJournalEntries` aggregation count()); mỗi ô bấm → chi tiết riêng: Chuỗi→StreakSheet · Kỷ-lục→`RecordsSheet` "Tủ kỷ lục" (chuỗi dài nhất/ngày bên nhau/tổng kỷ niệm/câu hỏi đã trả lời/mốc chuỗi đạt) · Kỷ-niệm→`MemoriesSheet` (thumbnail gần đây + "+N" + chips mốc ảnh + "Còn X tới mốc Y" + Xem-tất-cả→tab Gallery) · Nhật-ký→Journal. Sheet dùng `cardSurface` blur giống StreakSheet)** · **create_post (2026-06-14: "Tạo kỷ niệm" full-screen kiểu FB/IG — compose preview + caption chung; dùng cho CẢ "Chụp hình" 1 ảnh lẫn "Thêm hình" N ảnh, camera không đăng thẳng nữa)** · profile · settings · **counter_bg (2026-06-14: lưới chọn ảnh được phép làm nền CounterCard — whitelist `counterBgPhotoIds`, mở từ Settings→General)** · **reminders (gộp 2026-06-14: 1 màn 2 mục = cột mốc + lời nhắc riêng; `milestone_reminders`/`custom_reminders` thành Body nhúng, file giữ orphan)** · journal · (~~love_note_history~~ **XOÁ 2026-06-14** — feature Love Note retired, thay bằng tab Chat; lịch sử cũ auto-migrate sang Chat) · **love_tree (2026-06-14: màn "Cây tình yêu" — cây CustomPaint nở hoa theo cột mốc DERIVE monotonic [ngày-bên-nhau + `longestStreak` + `photoCount`], nhuỵ hoa = icon theo loại; số hoa=mốc đã vượt, stage cây theo số hoa; "vào app thấy nở hoa" qua Hive `love_tree_seen_<coupleId>` + animation khi flowerCount>lastSeen; vào từ tap StreakChip + badge chấm khi có hoa chưa xem; svc `love_tree_service.dart`)** · notification_center · **force_update (2026-06-14: màn chặn full-screen `PopScope canPop:false` khi build < `config/app.minBuildNumber`; route `forceUpdate` do `SessionResolver` trả ở đầu `_resolve` trước cả auth → chặn cả guest; nút mở store)** · guest_counter (landing unauth, root — không có nút back).
Localization: `AppL10n.strings` (no BuildContext). Sửa ARB → `flutter gen-l10n`. Tránh ICU `{...}` trong chuỗi không phải placeholder (dùng `<...>`).

---

## 3. Tech stack

Dart SDK env `^3.11.4` (pubspec.yaml đầy đủ, khỏi grep)

- Firebase/cloud: firebase_core ^4.1.1, firebase_auth ^6.0.2, cloud_firestore ^6.0.1, cloud_functions ^6.0.1, firebase_storage ^13.0.1, firebase_messaging ^16.0.2, firebase_crashlytics ^5.2.2, firebase_analytics ^12.4.2 (feature analytics — `AnalyticsService` no-context, no-op khi Firebase chưa sẵn/opt-out; posture no-tracking; toggle opt-out ở Settings).
- State mgmt: provider ^6.1.0 (+ flutter_localizations từ SDK).
- Local storage: hive ^2.2.3, hive_flutter ^1.1.0 (cần code-gen), flutter_secure_storage ^9.2.4 (session/local auth fallback), path_provider ^2.1.1.
- Notifications: flutter_local_notifications ^19.4.0, timezone ^0.10.1, flutter_timezone ^4.1.1.
- Media/UI: image_picker ^1.1.0, cached_network_image ^3.3.1, flutter_staggered_grid_view ^0.7.0 (masonry), cupertino_icons ^1.0.8.
- Misc: intl ^0.20.2, uuid ^4.0.0, connectivity_plus ^6.1.4, url_launcher ^6.3.1, package_info_plus ^9.0.1 (footer version ở Settings v2, 2026-06-11).
- UI revamp (Đợt 1, 2026-06-02): flutter_animate ^4.5.2 (staggered entrance), shimmer ^3.0.0 (skeleton loaders), **iconsax_plus ^1.0.0 (BỘ ICON CHÍNH 2026-06-14, user "re-design toàn icon" — đã thay HẾT Lucide; `lucide_icons` GỠ HẲN. 3 weight Linear/Bold/Broken; policy: `IconsaxPlusLinear` mặc định, `IconsaxPlusBold` cho nav-selected + accent/badge + UI heart. Ngoại lệ: `session_route_screen` giữ `Icons.favorite` (tim loader), `Icons.check_rounded` giữ (glyph chung). 199 usage/33 file đã đổi, analyze 0 — xem `features/icon-redesign/`)**, confetti ^0.8.0 (**chưa dùng** — dành Đợt 2 invite reveal). **Font: QUICKSAND bundled ở `assets/fonts/` (static 300–700, w800 map Bold — đổi 2026-06-10, "mịn màng nhẹ nhàng"); Be Vietnam Pro giữ bundle làm rollback; ĐÃ GỠ `google_fonts` 2026-06-06.**
- Dev deps: flutter_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.14.3, flutter_native_splash ^2.4.3, hive_generator ^2.0.1, build_runner ^2.4.9.
- Branding assets: flutter_launcher_icons (màu #FF6B9D, web theme #FF4D6D, iOS flatten remove-alpha) + flutter_native_splash (nền hồng #FF6B9D, heart trắng). **Typography (2026-06-10): TOÀN APP dùng 1 phông QUICKSAND bundled (rounded — "mịn màng nhẹ nhàng", user chốt; static 300–700, w800 khai báo trỏ file Bold; đủ glyph dấu TV — verify fontTools). Be Vietnam Pro GIỮ bundle làm rollback (đổi 1 hằng `AppTheme.fontFamily`). Bundled offline = không nháy font/vỡ dấu (bài học google_fonts 2026-06-06). Hero/số đếm w700/800, body w400/500; `ThemeData.fontFamily` + mọi helper ở `app_theme.dart`.**

---

## 4. Native config (iOS/Android)

App id chung: `com.tony.dearembeiu`.

Android (`android/app/build.gradle.kts`):
- applicationId + namespace = `com.tony.dearembeiu`
- compileSdk 36, targetSdk 35, minSdk = `flutter.minSdkVersion`; NDK `28.2.13676358`
- Java/Kotlin 17, coreLibraryDesugaring bật (cần cho flutter_local_notifications API cũ)
- Release: ProGuard/minify bật; signing đọc từ `android/key.properties` nếu có, không thì fallback debug. key.properties + keystore KHÔNG commit.
- Firebase: `android/app/google-services.json` (project `tonyembeiu`).
- **Deep-link scheme `dearembeiu://` (2026-06-20):** intent-filter VIEW/BROWSABLE **scheme-only** trên `MainActivity` (singleTop) → trang web action handler `docs/auth-action.html` foreground app sau khi xác thực email/đổi mật khẩu (xem mục 5/auth). App KHÔNG parse URL — chỉ cần lên foreground để `VerifyEmailScreen` auto-poll on-resume tự advance.

iOS (`ios/Runner/Info.plist`):
- Bundle id qua `$(PRODUCT_BUNDLE_IDENTIFIER)`; display name "Dear Embeiu".
- **Deep-link scheme `dearembeiu://` (2026-06-20):** `CFBundleURLTypes` (URLName `com.tony.dearembeiu`). `FlutterSceneDelegate` chuẩn → mở scheme foreground app, không cần sửa Swift. Đôi với Android dùng chung mục đích (xem trên + mục 5/auth). **Deep-link chỉ chạy từ bản app CÓ scheme = 1.3.0+** (bản live cũ vẫn dựa auto-poll khi user tự quay lại app).
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
- `couples/{coupleId}/photos/{photoId}/reactions/{uid}` — 6 emoji; collectionGroup index deployed. ⚠️ **[2026-06-17] FIX bug "A thả tim B không thấy":** rule chỉ có nested `match .../reactions/{uid}` → KHÔNG cấp quyền cho `collectionGroup('reactions')` query app dùng (bẫy Firestore) → stream B `permission-denied`, reaction CHƯA TỪNG sync cross-device. Thêm rule recursive `match /{path=**}/reactions/{reactionId} { allow read: if isCoupleMember(resource.data.coupleId); }` (additive, read-only). Verify emulator 170 pass (test mới `firestore.reactions.test.js`). ✅ **DEV + PROD deployed 2026-06-18** (verify runtime Android emulator: anh tuan giờ thấy reaction của em — chip "❤️ em"; diff vs prod 06-15 sạch CHỈ khối reactions; trace restore `20260617T173946Z-PROD/`). Cùng đợt: redesign reaction bar 4 trạng thái (xem `features/reactions/`).
- `couples/{coupleId}/notes/{uid}` — Love Note, text ≤140.
- `couples/{coupleId}/prefs/home` — prefs chung của couple (2026-06-10): `counterBgPhotoId` ≤200 (ảnh CounterCard ĐANG hiện, sync 2 máy) + (**2026-06-14**) `counterBgPhotoIds` (list ≤60 — **whitelist ảnh ĐƯỢC PHÉP làm nền**, rỗng/absent = hiện hết; Settings → "Ảnh nền thẻ đếm") + (**2026-06-18**) `chatBgPhotoId` ≤200 (**ảnh nền tab Chat**, ''=xoá về gradient; Settings → "Ảnh nền đoạn chat"; feature `chat-background` — picker lọc ảnh DỌC+đủ-nét decode kích thước thật, nền render full-bleed ở shell HomeScreen sau SafeArea. ✅ rules deployed **DEV** 2026-06-18 + **PROD 2026-06-19**) + `dqReminderEnabled` (bool) + `dqReminderTimes` (list phút-từ-nửa-đêm ≤10) cho **daily-Q reminder couple-shared** (2 máy nhắc cùng giờ). Member read/write, **mọi field OPTIONAL (writes MERGE — `setCounterBg`/`setCounterBgIds` merge), additive backward-compat**. ✅ rules+test (163 pass); **DEV + PROD deployed 2026-06-19** (deploy nguyên file rules → gồm cả `counterBgPhotoIds` + `chatBgPhotoId`).
- `couples/{coupleId}/moods/{uid}` — **Mood "Tâm trạng hôm nay" (2026-06-19, daily hook)**: 1 doc/member (id=uid) `mood`(key≤20)+`note?`(≤100)+`date`('YYYY-MM-DD')+`updatedAt`; member read cả 2, write own (`hasOnly` 5 field), no delete. CF `notifyPartnerMood` push (content-free) khi mood/date đổi. ✅ **DEV + PROD deployed 2026-06-19** (rules + CF notifyPartnerMood CREATE).
- `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}` — Daily Question, text ≤280. Marker doc cha: `bothAnswered` (streak) + `questionVi/En` (journal permanent).
- `users/{uid}/devices/{...}` — FCM tokens + `languageCode`. ⚠️ `hasOnly` rule phải liệt kê đủ field (push hỏng âm thầm nếu thiếu).
- `users/{uid}/notifications/{autoId}` — Notification center; CHỈ CF ghi, client read/mark-read/delete. ✅ DEV; **prod chờ lệnh**.
- `couples/{coupleId}/messages/{autoId}` — **Chat tab (2026-06-11)**: authorUserId+text(≤1000)+createdAt, create-only (update/delete=false), member read; CF `notifyChatMessage` push không lộ nội dung. ✅ DEV deployed; **prod chờ lệnh**. **[2026-06-19] presence suppression:** `notifyChatMessage` BỎ QUA người nhận đang trong chat (đọc `receipts/{uid}.chatActiveAt`, tươi trong **45s** = đang xem → skip cả inbox+push; fail-open). Client set `chatActiveAt`=serverTimestamp qua heartbeat **20s** ở `home_screen` khi tab Chat active (`ChatProvider.pingPresence`) **+ CLEAR (FieldValue.delete) ngay khi rời tab/background** (`leavePresence`, lifecycle observer) → hết bug lingering. **⚠️ KHÔNG dùng `readAt` làm presence** (readAt = đọc cuối, còn tươi cả sau khi rời → over-suppress, đã sửa). ✅ DEV + **PROD deployed 2026-06-19** (CF notifyChatMessage UPDATE).
- `couples/{coupleId}/receipts/{uid}` — **Chat read/delivery (2026-06-18)**: `deliveredAt`/`readAt` + **`chatActiveAt` (presence 2026-06-19)** — rule `hasOnly(['deliveredAt','readAt','chatActiveAt'])` (đều optional, timestamp), member read, own write, no delete. readAt=đã-đọc; chatActiveAt=đang-mở-chat (heartbeat 20s, xoá khi rời) cho `notifyChatMessage`.
- `couples/{coupleId}/receipts/{uid}` — **trạng thái tin nhắn (feature chat-status, 2026-06-18)**: `deliveredAt`/`readAt` serverTimestamp, doc id==uid (mỗi người ghi doc của mình, cả 2 đọc nhau). Suy ra đang gửi/đã gửi/đã nhận/đã đọc hiển thị dưới tin cuối cùng mình gửi. Rules additive (hasOnly+is timestamp, no delete), emulator 178 pass. ✅ **DEV deployed 2026-06-18; PROD deployed 2026-06-19**.
- `reports/{autoId}` — UGC reports, create-only.
- `config/{document}` (doc `config/app`) — **force-update gate (2026-06-14)**: `minBuildNumber`/`iosStoreUrl`/`androidStoreUrl`. **`read: if true` (PUBLIC — gate chạy trước login, guest cũng đọc)**, `write: if false` (chỉ admin Console). Client đọc fail-open. ✅ rules **ĐÃ deploy prod 06-19** (gồm trong full rules deploy). ❌ **doc `config/app` CHƯA tạo** (verify prod+dev NOT_FOUND 2026-06-20) → fail-open → hiện KHÔNG ai bị ép update. **Chủ ý HOÃN bật** (user 2026-06-20): đợi 1.3.1 live trên Play rồi mới set `minBuildNumber` (khuyến nghị =10). Gate chỉ chặn được user ≥1.2.0 (Android)/≥1.3.0 (iOS — vì Apple đang ở 1.1.0, gate mới có từ 1.3.0); **build number GLOBAL** nên 1 `minBuildNumber` áp cả 2 store → đừng set cao hơn build mới nhất đang live ở MỖI store kẻo kẹt user. `iosStoreUrl` = `https://apps.apple.com/app/id6775165592` (App Store ID `6775165592`, lấy qua iTunes lookup 2026-06-20; androidStoreUrl có fallback trong code). Xem `features/force-update/`.

**Storage:** `couple_photos/{coupleId}/{file}` — members only, <10MB.

**Email action handler on-brand (2026-06-20, feature auth):** link xác thực email / đổi mật khẩu trong mail trỏ tới trang web tuỳ biến `docs/auth-action.html` (Sunset Romance, vi/en theo `?lang`, tự áp `oobCode` qua REST identitytoolkit — `accounts:update` cho verify/recover, `accounts:resetPassword` 2 bước cho reset; có nút "Mở Dear Embeiu" deep-link `dearembeiu://`) thay vì trang mặc định xấu của Firebase. Trang lo CẢ verify + reset + recover. **Host: GitHub Pages `https://dearembeiu.com/auth-action.html` — ✅ LIVE 2026-06-20** (commit `525ee3f` trên `phase3`; đổi nguồn Pages `main`→`phase3` `/docs` qua `gh api` PUT, cname `dearembeiu.com` GIỮ NGUYÊN nhờ `docs/CNAME`; phải `POST pages/builds` kích hoạt build). **⚠️ KHÔNG dùng Console "Customize action URL"** (set báo "An error occurred updating..." dù đã thêm `dearembeiu.com` vào Authorized domains — nghi Identity Platform legacy lỗi). **THAY BẰNG: CF tự viết lại link** — `functions/index.js` helper `rewriteActionLink(firebaseLink, lang)` đổi host/path link Firebase-generated sang trang trên, giữ query (mode/oobCode/apiKey/continueUrl) + ép `lang`; fail-open (thiếu oobCode|apiKey → link gốc). Áp ở `sendCustomVerificationEmail`+`sendCustomPasswordResetEmail`. `apiKey` trong query → 1 trang chạy cả dev+prod. ✅ **Deploy DEV 2026-06-20** (trace `20260620T063607Z`); **PROD chờ lệnh** (`deploy --only functions:sendCustomVerificationEmail,functions:sendCustomPasswordResetEmail --project prod`). Chi tiết: `features/auth/dev.md` (log 2026-06-20).

**Cloud Functions** (`functions/index.js`, v2): `pruneDeadDevices` · `sendPartnerPhotoNotification` · `notifyPartnerJoined` · `notifyPartnerLeft` · `notifyLoveNote` · `notifyDailyAnswer` · `notifyPhotoReaction` · `notifyChatMessage` · **`notifyPartnerMood`** (2026-06-19, onWrite `moods/{uid}`, push-only content-free khi mood/date đổi — KHÔNG inbox; ✅ DEV + PROD 2026-06-19) · `deleteAccount` (callable) · `leaveCoupleCleanup` (callable, dọn rác mồ côi khi sole-member rời — ⚠️ **prod chờ lệnh**) · **`mirrorNoteHistoryToChat`** (trigger onCreate `noteHistory` → tạo `messages/lovenote_<id>` field `migratedFromNote:true`; mirror love note realtime sang Chat cho couple lệch phiên bản) · **`migrateLoveNotesToChat`** (callable member-auth, backfill toàn bộ noteHistory cũ → Chat, idempotent, set flag `couples.loveNotesMigratedToChat`; client gọi lazy khi mở Chat). 2 hàm migrate ✅ **DEV deployed 2026-06-14; prod chờ lệnh.** `notifyChatMessage` SKIP message `migratedFromNote` (tránh double-push/spam) **+ [2026-06-19] SKIP người nhận đang trong chat** (receipts/{uid}.`chatActiveAt` tươi <45s → bỏ cả inbox+push; fail-open; clear-on-leave nên không lingering). Tất cả dùng `writeInboxNotifications` (inbox) + `sendToRecipientDevices` (localize vi/en theo `languageCode`).

**Deploy:** `npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu` | `--only functions`. **Trước deploy rules: `scripts/test-firebase-rules.sh`.**

---

## 6. Tính năng: Reminders & Push

> ➡️ Chi tiết: [`project/features/reminders/`](project/features/reminders/overview.md) (local), [`project/features/gallery/`](project/features/gallery/overview.md) (push). Mục này chỉ ghi nền tảng ít đổi.

Hai loại notification, đừng nhầm:
- Love reminders — local only (không network): `reminder_provider.dart` (what — Hive `reminder_settings`) + `reminder_service.dart` (how — channel `love_reminders`, id auto 1001–1099, text từ `AppL10n.strings`). v2 (2026-05-31): bỏ daily nudge; 7 mốc curated user tự bật/tắt (`models/milestone_reminder.dart` enum `MilestoneType`: every100/d520/d1000/d1314/halfYear/yearly/inactivity; default Dv4 lưu Hive `milestone_<name>`) ở `screens/milestone_reminders_screen.dart` (màn Cột mốc, badge số mốc bật, dim khi master off). Mốc bật → schedule đúng ngày (bỏ "nhắc trước 3 ngày"); one-shot đã-qua/anniversary tương lai → không schedule, không crash. Gate "Lời nhắc của chúng mình" (custom) khi master off → force-open dialog (Dv6). Dv8 giờ-theo-mốc: "Giờ nhắc" = giờ mặc định (`ReminderSettings.hour/minute`); mỗi mốc có giờ riêng tuỳ chọn lưu Hive `milestone_<name>_hour/_minute` (absent=mặc định); provider `milestoneTimeOf`/`effectiveTimeOf`/`setMilestoneTime`; schedule dùng `effectiveTimeOf` ⇒ đổi giờ mặc định chỉ reschedule mốc chưa-đặt-riêng. **[2026-06-14] BỎ master toggle → cột mốc LUÔN auto nhắc (gỡ gate `_settings.enabled`, bỏ `setEnabled`); màn Cột mốc tách `MilestoneRemindersBody` gộp vào `RemindersScreen` (cùng custom). [vòng 2] BỎ tile "Giờ mặc định" → MỖI mốc có giờ RIÊNG user tự chọn (`_TimeChip` luôn hiện `effectiveTimeOf`, chạm để `setMilestoneTime`; bỏ reset-về-mặc-định; `setTime`/`milestoneTimeOf` thôi dùng ở UI).**
- Custom reminders — local only (feature mới, → [`project/features/custom-reminders/`](project/features/custom-reminders/overview.md)): user tự tạo reminder riêng (tên+ghi chú+ngày+giờ+kiểu lặp once/daily/weekly/monthly/yearly), `custom_reminders_provider.dart` + `ReminderService.scheduleCustom/nextFireFor` (clamp ngày 31/29-02), notif id 2000–2999, cap 20. Lưu Hive `custom_reminders`, không Firestore/push. **[2026-06-14] BỎ lock-step/force-open theo master (master đã bỏ); tách `CustomRemindersBody` gộp vào `RemindersScreen`.**
- Daily question reminder — **NHIỀU GIỜ + COUPLE-SHARED (revamp 2026-06-14)**: nhắc cả 2 trả lời câu hỏi mỗi ngày, **đặt nhiều giờ** (cap 10), **đồng bộ 2 máy** qua `prefs/home` (`dqReminderTimes`+`dqReminderEnabled`). Notification vẫn LOCAL mỗi máy: `ReminderService.scheduleDailyQuestionTimes(minutesOfDay)` — **dải id 1040–1049** (cancel cả dải + legacy 1004), lặp `DateTimeComponents.time`, ngoài `_autoIds`. `ReminderProvider`: `_dqTimes` (List<int> phút) + `_dqEnabled` sync qua `HomePrefsService.watchReminderPrefs/setReminderPrefs`; watch wire ở `session_resolver` (couple active) → remote đổi thì reschedule local (dùng l10n cache từ `HomeScreen.sync`); Hive = cache offline + migrate giờ-đơn cũ. API: `dailyQuestionReminderTimes`/`setDailyQuestionTimes`/`addDailyQuestionTime`/`removeDailyQuestionTime`/`canAddDailyQuestionTime`. ⟪[2026-06-14 vòng 2] từng rút UI về 1 giờ — ĐÃ HOÀN TÁC 2026-06-19⟫ **[2026-06-19] UI lại NHIỀU GIỜ (user đổi ý):** Settings hiện 1 `_DailyQuestionTimeRow`/giờ (giờ=primary, ✕ xoá khi >1, tap=sửa) + `_DailyQuestionAddTimeRow` ("Thêm giờ nhắc", ẩn ở cap 10) + dòng hint `dailyQuestionReminderEndOfDayHint`. Rules deployed DEV. **[2026-06-19] AUTO CẢNH BÁO CUỐI NGÀY (end-of-day safety net) — LOCAL, ONE-SHOT/ngày, ĐIỀU KIỆN:** thêm 3 nhắc cố định **21h (nhắc) · 22h+23h (cảnh báo MẤT CHUỖI)** khi cuối ngày couple **chưa hoàn thành** câu hỏi (`!hasRevealed` = chưa bothAnswered). `ReminderService`: `DailyQuestionEodSlot` + **dải id 1050–1052** + `scheduleDailyQuestionEndOfDay(slots)` (one-shot HÔM NAY, skip giờ đã qua, không roll sang mai) + `cancelDailyQuestionEndOfDay`. `ReminderProvider.refreshDailyQuestionSafetyNet({hasRevealed,iAnswered,currentStreak,l10n})` + `_scheduleEndOfDay` (debounce signature, cancel khi off/đã reveal; copy phân nhánh `iAnswered` + `streak>=1`/`==0`); wire vào setEnabled/watchCoupleReminderPrefs/cancelDailyQuestionSchedule. `HomeScreen` re-arm qua listener `_refreshDqSafetyNet` trên DailyQuestion+Streak provider (+1 lần post-frame). User chốt **local + vẫn cảnh báo khi mình đã trả lời mà người ấy chưa** (chuỗi chỉ tính khi CẢ HAI xong); hạn chế local: app kill đúng lúc người kia vừa trả lời → có thể báo nhầm (chấp nhận). Thuần local, KHÔNG deploy.
- Push partner-photo / partner-joined — FCM qua CF `sendPartnerPhotoNotification` / `notifyPartnerJoined` (mục 5) khi partner đăng ảnh / khi B ghép cặp báo A (vá hở vòng lặp kích hoạt couple, 2026-06-01).
- Deep-link tap (2026-06-01): chạm push mở đúng tab Home — `NotificationTapRouter` (ValueNotifier ở `push_notification_service.dart`, không navigatorKey/package) + `getInitialMessage`(cold)/`onMessageOpenedApp`(warm); `HomeScreen` consume ở initState + listener. Map (**đổi 2026-06-11 khi thêm tab Chat — nav 4 tab: Home 0 · Chat 1 · Gallery 2 · Profile 3**): `photo_posted`/`photo_reaction`→Gallery(**2**) + deep-link đúng ảnh (photoId), `chat_message`/`love_note`→Chat(**1**) (**`love_note`→Chat vì notes đã migrate vào Chat 2026-06-14**), `partner_joined`/`partner_left`/`daily_question`→Home(0) (**`partner_left` vá 2026-06-06** — trước thiếu nhánh tap → rơi default no-op). ⚠️ **2 chỗ map type→tab phải đồng bộ:** push tap (`push_notification_service.dart._handleNotificationTap`) + Notification Center tap (`AppNotification.targetHomeTab` — dùng bởi `notification_center_screen`). **Vá 2026-06-14:** `targetHomeTab` cho `loveNote` còn trả Home(0) trong khi push đã trả Chat(1) → tap "lời nhắn" trong Notification Center đi sai chỗ; đã sửa khớp Chat(1). **Deep-link `daily_question` (2026-06-14):** câu hỏi chỉ vào lịch sử (JournalScreen) khi CẢ HAI đã trả lời (`bothAnswered`). Notification Center tap `daily_question`: nếu hôm nay đã reveal (`DailyQuestionProvider.hasRevealed`) → `pushReplacement(JournalScreen(focusDate))` (scroll+highlight đúng ngày, Back về Home); nếu chưa reveal (mình chưa trả lời) → Home(0) + scroll card để trả lời. Push tap `daily_question` vẫn Home+scroll card (cold-start không đọc được provider — chấp nhận, Home vẫn show câu hỏi).
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
- **Design Unify (2026-06-11):** TOÀN APP đồng bộ theo ngôn ngữ Home v3 (greeting header + bell squircle). 9 primitives chung mới ở `lib/widgets/` (`ContentCard` trắng đặc r24 black .06 · `subScreenAppBar`+`HeaderIconButton` back-squircle 44 r16 cho 100% màn con (**[2026-06-18] thêm param `backed`: icon-TRÊN-ẢNH thì cưỡi đĩa frosted giống `EyebrowChip` (trắng .72+viền+bóng rose, ink navy) để đọc được trên ảnh tối/sáng — mặc định false, header gradient vẫn bare-ink; dùng ở nút back tab Chat khi có ảnh nền)** · `IconBadge`/`InkTile`/`SectionHeader`/`ComposePill`/`EntranceReveal`); **header ink = NAVY `textPrimary` mặc định trong `pageTitle/Eyebrow/SubtitleStyle`** (vòng 4 cùng ngày — trắng trên blush fail ~1.7:1; trắng+bóng-tối chỉ còn trên scrim tối/ảnh, helper tự bật shadow khi truyền `color: white`); mọi phần tử bấm = InkWell ripple (rose .08 sáng / trắng .12 đậm); GlassCard chỉ còn form auth/setup/guest + nav + overlay; nút primary pill r999 h52; Reduce Motion vá đủ (aurora/cinema/marquee/entrance); Journal nền mint→blush. **Màn/widget MỚI bắt buộc dùng primitives này.** **🔒 RULE header (cập nhật 2026-06-14):** **(a) Màn CON (redesign v2 2026-06-14 "chip xích trái, cùng hướng dọc title")** = widget chung **`SubScreenHeader`** (`lib/widgets/sub_screen_header.dart`): **(v2.1 2026-06-14: chip badge Ở GIỮA + ngang hàng back, XOÁ title/subtitle toàn bộ màn con — user "research các trang có back, chip ở giữa ngang icon, xoá header text")** 1 HÀNG: **`←` back (trái) · `EyebrowChip` (GIỮA, Stack center) · `trailing` tuỳ chọn (phải)** — chip alone names the screen, KHÔNG còn `pageTitle`/`subtitle` (param `title`/`subtitle` GIỮ ở widget cho call-site cũ nhưng KHÔNG render); đổi 1 widget = 10 màn con cùng đổi. ⟪cũ: 1 cột back → chip → pageTitle(28) → subtitle⟫, param `trailing` (Save/counter/overflow). **`title` + `subtitle` OPTIONAL (2026-06-14):** bỏ cả 2 → header **chip-only** (back + chip) — Journal dùng kiểu này (user "xoá dòng Nhật ký câu hỏi + subtitle, chỉ giữ chip"; chip đổi `journalBadge`="NHẬT KÝ CÂU HỎI"/"QUESTION JOURNAL"). KHÔNG `appBar` nữa (SafeArea bỏ `top:false`); header = item đầu body scroll, hoặc fixed trên list (notif-center/custom-reminders). Title màn con=28, landing/auth hero=32. ⚠️ Bản v1 "chip cạnh back trên app bar" ĐÃ BỎ (chip thụt phải, lệch cột). **Auth login/register/forgot: REVERT về gốc** — chip trong form column (`_buildHeader`, thẳng cột title), back = `Positioned` overlay góc. Quy tắc: chip LUÔN thẳng cột với title; back ở trên (đầu cột màn con / overlay góc auth). verify_email/guest_counter/setup-create giữ chip hero. **(b) 4 TAB top-level (Home/Chat/Gallery/Profile) = CHIP-ONLY** (user "xoá title, chỉ để chip, đồng bộ cả 4 màn"): mỗi tab chỉ 1 hàng = chip trái + action icon phải (Home=bell+lời-chào-theo-giờ-trong-chip, Profile=settings, Chat=tên cặp đôi dynamic + **← back bên trái chip từ 2026-06-17 (drill-in)**, Gallery=không icon), gutter 16 / top 16; **⚠️ NGOẠI LỆ Chat (2026-06-17):** Chat KHÔNG còn là tab peer "nav luôn hiện" — vào Chat thì **floating nav ẩn hẳn** (`hideNav = keyboard || _selectedIndex==chatTab`), header = chip + ← back (drill-in). Các tab Home/Gallery/Profile vẫn giữ nav. bỏ hết pageTitle/subtitle to (Gallery collapse height 340→296). **Header PHẢI PINNED ngoài vùng scroll (sync 2026-06-14):** chip + action icon đứng yên khi cuộn, KHÔNG trôi mất — Chat/Gallery/Profile vốn đã pinned (`Column[header, Expanded(scroll)]` / SliverPersistentHeader pinned), riêng Home trước để header là item đầu của `SingleChildScrollView` ⇒ chuông trôi mất khi cuộn (lệch 3 tab kia). Vá: tách `_buildHomeScrollBody`, `_buildHomeTab` trả `Column[Padding(header pinned), Expanded(RefreshIndicator>scroll)]`. **Header Row PHẢI `crossAxisAlignment.start`** (icon 44/48 cao hơn chip ~27 → `center` mặc định đẩy chip xuống ⇒ tab có-icon lệch thấp ~22–28px; top-align ⇒ chip đều 16pt cả 4 tab, verify pixel spread 0). **NỀN đồng bộ:** dawnBlush vẽ 1 lần bởi Home shell, cả 4 tab trong suốt. Token sheet chuẩn ở đầu [`project/design-system.md`](project/design-system.md); spec từng màn [`project/features/design-unify/`](project/features/design-unify/overview.md).

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

🔒 **RULE PARITY 2 NỀN TẢNG (user 2026-06-20): App Store + Google Play LUÔN CÙNG 1 version + build.** Mỗi release build CẢ HAI từ **cùng 1 `pubspec.yaml`** (`flutter build appbundle --release` + `flutter build ipa --release`, không đổi `version:` giữa 2 lần build) và **submit đồng thời** lên cả 2 store. KHÔNG skip version theo nền tảng nữa (lịch sử cũ Apple bỏ 1.2.0 → lệch; từ 1.3.x không tái diễn). Hệ quả: (a) force-update dùng 1 `minBuildNumber` chung an toàn; (b) build number toàn cục giữ đúng vai (1 số = 1 bản, trên cả 2 store). **HỘI TỤ HIỆN TẠI:** Apple đang 1.1.0, Android 1.2.0 → đưa **CẢ HAI** về **1.3.1+10** (Apple nhảy 1.1.0→1.3.1, bỏ 1.3.0; Android 1.2.0→1.3.1) → từ đó song hành. iOS 1.3.1 IPA build từ pubspec hiện tại (1.3.1+10), gồm hotfix chat/hide-card/personal-reminder (đều chạy cross-platform).

🔔 **RULE AUTO-SUGGEST RELEASE (user 2026-06-20): mỗi khi user yêu cầu "release / phát hành bản này / bản mới", Claude TỰ ĐỘNG xuất checklist song hành 2 nền tảng** (không chờ user hỏi từng bước), đánh dấu rõ ✅ đã xong / ❌ còn thiếu cho TỪNG store. **HIỂU NGẦM (bất biến): "release bản X" = LUÔN cả Apple + Google Play, TUYỆT ĐỐI KHÔNG hỏi lại "nền tảng nào".** Claude TỰ làm phần code (bump `pubspec` 1 version → analyze/rules-test → build CẢ `appbundle` + `ipa` → verify ký → cập nhật release log + USER_HISTORY), rồi GIAO lại cho user phần ngoài tầm (upload AAB lên Play + IPA lên App Store + git commit/tag — Claude không tự làm). Checklist:
> 1. **Version** — bump `pubspec.yaml` → `X.Y.Z+N` (N = build TOÀN CỤC +1; 1 số dùng chung CẢ 2 store; build mới phải > build đang live ở mỗi store).
> 2. **Pre-flight** — `flutter analyze` sạch (toolchain đúng máy) + `scripts/test-firebase-rules.sh` nếu đụng backend.
> 3. **Build CẢ HAI** từ cùng pubspec — `flutter build appbundle --release` (Android) + `flutter build ipa --release` (iOS, cần signing distribution).
> 4. **Verify ký** — AAB: SHA1 upload key `FF:EF:1E:27`; IPA: cert distribution + Strip-Invalid-Arch (Transporter).
> 5. **🤖 Google Play** — upload AAB → track → submit (versionCode > bản live).
> 6. **🍎 App Store** — upload IPA (Transporter/Xcode) → App Store Connect → submit review.
> 7. **Backend** — deploy prod rules/functions nếu đổi (rules-test + auto-trace).
> 8. **Force-update** (nếu muốn ép) — SAU KHI cả 2 live → set `config/app.minBuildNumber` (≤ build mới nhất live ở MỖI store; iosStoreUrl `id6775165592`).
> 9. **Ghi** — release log bảng dưới + `project/USER_HISTORY.md`. Git commit/tag = user tự làm (Claude không tự commit).
> Luôn nhắc: build CẢ 2 từ CÙNG pubspec, submit ĐỒNG THỜI (RULE PARITY trên).

**Release log:**
| Version | Build | Branch | Trạng thái | Nội dung |
|---|---|---|---|---|
| 1.0.0 | 1 | — | ✅ Live | Bản đầu: counter + gallery + coupling + reminders + auth |
| 1.1.0 | 5 | — | ✅ Ready for Distribution (2026-06-06) | reactions/streak/journal/daily-question/love-note 2 chiều |
| 1.1.1 | 6 | `release/1.1.1` | ⏭️ Gộp vào 1.2.0 (chưa submit riêng) | fix login/logout/email-verify/xoá tài khoản + backward-compat + CF leaveCoupleCleanup |
| 1.2.0 | 7 | `release/1.1.6` | ⏭️ Từng live Google Play (đã bị 1.3.0 thay 2026-06-20; KHÔNG submit Apple) | **icon redesign toàn app (Iconsax)** + Profile redesign (hành trình & huy hiệu) + chọn ảnh nền thẻ đếm + chat auto-load + deep-link thông báo + force-update gate + header gọn + (gồm cả 1.1.1 auth fixes). Release notes: `RELEASE_NOTES_1.2.0.md`. |
| 1.3.0 | 9 | `phase3` (branch hiện tại) | ✅ **LIVE CẢ 2 STORE (Apple + Google Play) — verify 2026-06-20** | Apple nhảy 1.1.0→1.3.0 (gộp delta 1.2.0+1.3.0). MỚI: **Cây Tình Yêu bầu trời 4 buổi** (mặt trời/trăng vẽ mềm) + **Tâm trạng hôm nay** + ảnh nền chat + trạng thái tin nhắn + presence + daily-Q reminder nhiều giờ/cảnh báo cuối ngày + reactions redesign & fix. Release notes: `RELEASE_NOTES_1.3.0.md`. **Pre-flight: analyze 0, rules-test 187. ✅ PROD rules/CF (moods/receipts/chatBg + notifyPartnerMood/notifyChatMessage) ĐÃ deploy 2026-06-19 (snapshot `20260619T174154Z-PROD/`). AAB 1.3.0+9 đã rebuild ký đúng upload key trên máy nhà 2026-06-19. CÒN: tạo doc `config/app` (force-update) ở Console nếu muốn bật gate.** |
| 1.3.1 | 10 | `phase3` | 🚀 **Hotfix CẢ 2 NỀN TẢNG (parity) — AAB Android built 2026-06-20; iOS IPA CHƯA build; chờ submit đồng thời 2 store** | PATCH trên 1.3.0. Hotfix client-only: (1) chat chạm/cuộn vùng tin nhắn → thu bàn phím (`chat_screen.dart`); (2) ẩn card "Quản lý dữ liệu" cho `dodaoanhtuan@gmail.com` + `thaohathao14@gmail.com` (`settings_screen.dart`); (3) **lời nhắc riêng "anh By → embe"** account-gated `thaohathao14@gmail.com` — uống thuốc 9:59/10:10/10:30 daily + nhắc trả lời câu hỏi mỗi giờ 7h–22h (dừng khi đã trả lời); local notification (`reminder_service`/`reminder_provider`/`home_screen`, id band 1100–1139). analyze 0. AAB `build/app/outputs/bundle/release/app-release.aab` ký đúng upload key (SHA1 FF:EF:1E:27), versionCode 10. KHÔNG đụng backend (không deploy). |

---

## Quy ước làm việc với Claude

- Ngôn ngữ: trả lời tiếng Việt.
- Tự cập nhật context: mỗi khi user yêu cầu THAY ĐỔI bất cứ thứ gì (code, thiết kế, hành vi, quyết định sản phẩm, quy ước), xong tự cập nhật file này cho khớp — không cần nhắc, không hỏi xin phép từng lần. Chỉ lưu cái không suy ra được từ code/git (quyết định, lý do, trạng thái, preference).
- Quản lý theo feature (`project/`): mọi việc liên quan một feature → tự cập nhật file tương ứng trong `project/features/<ten-feature>/` (role nào làm ghi vào file role đó: overview=PO, design=Designer, dev=Dev, test=Tester) + dòng trạng thái trong `project/ROADMAP.md`. Feature MỚI chưa có folder → tự tạo `features/<ten-feature>/` (tên theo chủ đề, không tiền tố số) từ `project/_templates/` rồi mới làm. Nhật ký format `- [YYYY-MM-DD] [role] <việc>`. Luật đầy đủ: [`project/README.md`](project/README.md).
- Mô hình 4 vai (mục 9): tôn trọng ranh giới mỗi role. PO/Designer/Tester KHÔNG sửa code sản phẩm; chỉ Dev implement.
- Decision log đã chốt (đừng lật lại trừ khi user đổi ý): i18n D2 (bỏ cờ, dùng letter chip) + D3 (format ngày theo locale) — mục 7.
- File này hợp nhất từ memory cá nhân; nếu chạy Claude ở máy có memory riêng, hai nguồn có thể bổ sung cho nhau.
