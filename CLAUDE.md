# Dear Embeiu — Project Context cho Claude

> File này là **bộ nhớ dự án hợp nhất**, commit vào repo để Claude trên bất kỳ máy nào cũng hiểu ngay những gì đã và đang làm — không phải dò lại từ đầu.
> Nguồn: hợp nhất từ memory cá nhân (`~/.claude/.../memory/`). Khi code/quyết định thay đổi, **cập nhật lại file này** (xem mục [Quy ước làm việc](#quy-ước-làm-việc-với-claude)).
> Ngôn ngữ làm việc với user: **tiếng Việt**. User: thesavior9820.
>
> 📁 **Quản lý theo feature ở [`project/`](project/README.md):** mỗi feature 1 folder (`project/features/<ten-feature>/`, đặt tên theo chủ đề, không tiền tố số — vd `language`, `analytics`) gồm `overview.md` (PO) + `design.md` (Designer) + `dev.md` (Dev) + `test.md` (Tester) — dùng chung, mỗi role tự ghi việc đã làm. `CLAUDE.md` = bối cảnh *toàn dự án*; `project/` = chi tiết *từng feature*. Xem [`project/README.md`](project/README.md) cho luật & lifecycle.

## Mục lục
1. [Tổng quan sản phẩm](#1-tổng-quan-sản-phẩm)
2. [Kiến trúc code](#2-kiến-trúc-code)
3. [Tech stack](#3-tech-stack)
4. [Native config (iOS/Android)](#4-native-config-iosandroid)
5. [Firebase backend](#5-firebase-backend)
6. [Notifications (reminders + push) — nền tảng](#6-tính-năng-reminders--push)
7. [i18n — nền tảng](#7-tính-năng-đa-ngôn-ngữ-i18n)
8. [Design system](#8-design-system)
9. [Mô hình 4 vai (PO / Designer / Dev / Tester)](#9-mô-hình-4-vai)
10. [Product strategy](#10-product-strategy)
11. [Product roadmap (→ project/)](#11-product-roadmap)
12. [Tester: bản đồ rủi ro (→ project/)](#12-tester-catalog-rủi-ro-security--logicedge)
13. [Build & run](#13-build--run)
14. [Quy ước làm việc với Claude](#quy-ước-làm-việc-với-claude)

> Chi tiết theo-feature (roadmap, gap, test case, quyết định, trạng thái) nằm ở [`project/`](project/README.md). CLAUDE.md chỉ giữ nền tảng toàn dự án.

---

## 1. Tổng quan sản phẩm

**Dear Embeiu** (tựa tiếng Việt: "Kỷ Niệm Của Chúng Mình") — Flutter app cho các cặp đôi.
pubspec description: "Dear Embeiu — lưu giữ kỷ niệm và đếm ngày yêu cùng người ấy."

**Ba tính năng cốt lõi:**
1. **Đếm ngày yêu** — couple lưu `anniversaryDate`; app tính số năm/tháng/ngày (model `CounterData`, hiển thị ở HomeScreen).
2. **Thư viện ảnh dùng chung** — 2 người cùng đăng ảnh vào album couple, layout masonry kiểu Pinterest; đồng bộ realtime qua Firestore theo `coupleId`; mỗi ảnh ghi người đăng.
3. **Love reminders** — local scheduled notifications (mục 6).

Ghép đôi qua **mã mời (invite code)**: A tạo couple → nhận mã 6 ký tự (`invite_codes/{code}`) → chia sẻ cho B → B nhập mã để join.

**Identity:**
- App id (Android & iOS): `com.tony.dearembeiu`
- Firebase project: `tonyembeiu` (.firebaserc default, region us-central1)
- Version: 1.0.0+1; Flutter SDK env `^3.11.4` (máy dev đang Flutter 3.41.6 stable)
- Ngôn ngữ: vi + en (supportedLocales). ARB ở `lib/l10n/app_en.arb`, `app_vi.arb`. Mặc định theo system locale.
- GitHub: github.com/tuandda98/dear_embeiu; privacy policy host GitHub Pages (`docs/` qua Firebase Hosting).
- Brand: "Sunset Romance", màu hồng #FF6B9D, **chỉ light mode** (`AppTheme.lightTheme`).
- Đang chuẩn bị phát hành Google Play (có `PLAY_STORE_RELEASE.md`, `PLAY_CONSOLE_CONTENT.md`).

---

## 2. Kiến trúc code

**Pattern: Provider (ChangeNotifier) + service layer.** UI (screens/widgets) ← providers (state/ViewModel) ← services (data I/O, Firebase + local).

**Entry `lib/main.dart`:** `Hive.initFlutter()` → `FirebaseBootstrapService.initialize()` → (mobile) FCM background handler + `PushNotificationService.initialize()` → `ReminderService.initialize()` → `InstallStateService.handleFreshInstall` (purge session khi reinstall) → Crashlytics hook → `runApp`. MultiProvider: AuthProvider, CoupleProvider, PhotoProvider, LocaleProvider, ReminderProvider. `home: SplashScreen`. Routes ở `lib/app/app_routes.dart`: splash `/`, authGate, login, register, home, setup.

**Navigation gate:** `lib/app/session_resolver.dart` `SessionResolver.resolveStartRoute()` → **guest (đếm ngày local) nếu chưa auth** (đổi từ login để qua Apple 5.1.1(v) — app mở thẳng vào tính năng không cần tài khoản); setup nếu authed nhưng chưa có couple; home nếu có couple. Mọi luồng (cold-start, sign-out, login/register success) đều qua authGate→resolver nên nhất quán.

**Services (`lib/services/`):**
- `auth_service.dart` (~548 dòng) — Firebase Auth + Firestore, có **local fallback** (FlutterSecureStorage mock store) khi Firebase chưa sẵn. Tạo invite code, sign up/in/out, persist session, gọi callable `deleteAccount`. `isUsingFirebase` quyết định nhánh. Còn comment "Sprint 1 local scaffold".
- `user_service.dart` — Firestore user profiles + device registrations; sync invite code sang `invite_codes`.
- `couple_service.dart` (~726 dòng) — tạo/join (transaction)/leave couple; upload ảnh đại diện couple lên Storage; merge local+remote.
- `photo_service.dart` — CRUD ảnh couple, watch Firestore stream, upload Storage, captions.
- `storage_service.dart` — local JSON persistence (couple_data.json, photos_data.json + thư mục couple_photos) làm cache/offline.
- `reminder_service.dart` — local notifications (mục 6).
- `push_notification_service.dart` — FCM: xin quyền, lưu/refresh token ở `users/{uid}/devices`, unregister khi sign-out.
- `firebase_bootstrap_service.dart` — init Firebase 1 lần, tắt Crashlytics ở debug, expose `isFirebaseReady`.
- `install_state_service.dart` — phát hiện fresh install qua marker file.

**Providers (`lib/providers/`):** auth_provider (status unknown/unauthenticated/authenticated; signIn/Up/Out/deleteAccount/refreshPushRegistration), couple_provider (create/join/update/leave + Firestore stream), photo_provider (watch + sync, addPhoto/deletePhoto/updateCaption), reminder_provider, custom_reminders_provider (CRUD reminder tuỳ chỉnh local — Hive box `custom_reminders`, cap 20, notif id 2000–2999), locale_provider (Hive, null=system locale).

**Models (`lib/models/`):** app_user (id,email,displayName,coupleId?,inviteCode,status single/waiting_partner/in_couple), couple (person1/2Name,anniversaryDate,couplePhoto local/url/storagePath,inviteCode,memberIds[1-2],status waiting_partner/active,createdByUserId), photo (path,remoteUrl,storagePath,coupleId,authorUserId,authorName,caption), account_invite, counter_data, auth_status (enum).

**Screens (`lib/screens/`):** splash, auth_gate, login, register, setup, home, gallery, profile, **settings** (màn Cài đặt tổng — gom reminders/ngôn ngữ/tài khoản+danger; vào từ tile "⚙️ Cài đặt" ở Profile), milestone_reminders (Cột mốc & kỷ niệm + giờ-theo-mốc), custom_reminders + custom_reminder_form (reminder tuỳ chỉnh — vào từ Settings), **guest_counter** (fix Apple 5.1.1(v) — **MÀN LANDING khi chưa đăng nhập**: SessionResolver unauth→`/guest`; màn đếm ngày yêu thuần local, Hive box `guest_settings`, tái dùng CounterCard/CounterData; là root nên KHÔNG có nút back; "Đăng nhập"→pushNamed(login), "Đăng ký"→pushNamed(register). Login đã BỎ nút guest thừa, login-success dùng `pushNamedAndRemoveUntil(authGate,false)` clear stack. **login+register có nút back (mũi tên góc trái) → `maybePop()` về guest** vì giờ chúng được push trên guest). Widgets ở `lib/widgets/`. Theme ở `lib/theme/`.

**Localization (`lib/l10n/`):** ARB-generated AppLocalizations (en/vi). `app_l10n.dart` (`AppL10n`) là **lớp truy cập l10n không cần BuildContext** — services/providers/background isolate dùng `AppL10n.strings`. MyApp giữ đồng bộ qua `localeResolutionCallback` → `AppL10n.setLocale()`, fallback English. MyApp observe `AppLifecycleState.resumed` → `refreshPushRegistration()`.

---

## 3. Tech stack

Dart SDK env `^3.11.4`. (pubspec.yaml — đầy đủ để khỏi grep lại)

- **Firebase/cloud:** firebase_core ^4.1.1, firebase_auth ^6.0.2, cloud_firestore ^6.0.1, cloud_functions ^6.0.1, firebase_storage ^13.0.1, firebase_messaging ^16.0.2, firebase_crashlytics ^5.2.2.
- **State mgmt:** provider ^6.1.0 (+ flutter_localizations từ SDK).
- **Local storage:** hive ^2.2.3, hive_flutter ^1.1.0 (cần code-gen), flutter_secure_storage ^9.2.4 (session/local auth fallback), path_provider ^2.1.1.
- **Notifications:** flutter_local_notifications ^19.4.0, timezone ^0.10.1, flutter_timezone ^4.1.1.
- **Media/UI:** image_picker ^1.1.0, cached_network_image ^3.3.1, flutter_staggered_grid_view ^0.7.0 (masonry), cupertino_icons ^1.0.8.
- **Misc:** intl ^0.20.2, uuid ^4.0.0, connectivity_plus ^6.1.4, url_launcher ^6.3.1.
- **Dev deps:** flutter_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.14.3, flutter_native_splash ^2.4.3, hive_generator ^2.0.1, build_runner ^2.4.9.
- **Branding assets:** flutter_launcher_icons (màu #FF6B9D, web theme #FF4D6D, iOS flatten remove-alpha) + flutter_native_splash (nền hồng #FF6B9D, heart trắng). **google_fonts CHƯA có** (typography = system serif/sans, là việc nâng cấp tiềm năng).

---

## 4. Native config (iOS/Android)

App id chung: `com.tony.dearembeiu`.

**Android** (`android/app/build.gradle.kts`):
- applicationId + namespace = `com.tony.dearembeiu`
- compileSdk 36, targetSdk 35, minSdk = `flutter.minSdkVersion`; NDK `28.2.13676358`
- Java/Kotlin 17, **coreLibraryDesugaring bật** (cần cho flutter_local_notifications API cũ)
- Release: ProGuard/minify bật; signing đọc từ `android/key.properties` nếu có, không thì fallback debug. **key.properties + keystore KHÔNG commit.**
- Firebase: `android/app/google-services.json` (project `tonyembeiu`).

**iOS** (`ios/Runner/Info.plist`):
- Bundle id qua `$(PRODUCT_BUNDLE_IDENTIFIER)`; display name "Dear Embeiu".
- `UIBackgroundModes: remote-notification`; `NSPhotoLibraryUsageDescription` (text VI); `ITSAppUsesNonExemptEncryption: false`.
- Scene-based lifecycle. Phone portrait; iPad mọi hướng.
- `ios/Runner/GoogleService-Info.plist` (project `tonyembeiu`); `PrivacyInfo.xcprivacy` có khai báo.
- **Build-phase "Strip Invalid Architectures"** (thêm vào target Runner qua `ios/Podfile` post_install bằng Xcodeproj, 2026-06-01): lipo remove `i386/x86_64` khỏi mọi embedded framework + re-sign. **Bắt buộc** vì `objective_c.framework` (transitive của native FFI) ship fat binary có slice simulator → Transporter báo *Validation failed (409) Invalid executable … x86_64 slice*. Idempotent, sống qua `pod install`.
- ⚠️ Thiếu `CFBundleLocalizations`/`CFBundleAllowMixedLocalizations` (gap i18n — mục 7).

---

## 5. Firebase backend

Firebase project `tonyembeiu` (us-central1). `firebase.json`: functions ở `functions/`, rules `firestore.rules` + `storage.rules`, hosting public=`docs/`.

**Firestore data model:**
- `users/{uid}` — profile, `inviteCode`, `coupleId`, status. Rules: tạo own (schema chặt), email immutable, inviteCode immutable khi đã set; `allow delete: if false`.
- `invite_codes/{code}` — map mã mời → account (userId, displayName, coupleId). `createdAt`/`userId` immutable; `allow delete: if false`.
- `couples/{coupleId}` — không gian chung; tạo solo (memberIds=1, status `waiting_partner`); join → memberIds=2, status `active`; leave → demote về waiting_partner; xoá chỉ khi còn 1 member. inviteCode + creator immutable.
- `couples/{coupleId}/photos/{photoId}` — feed ảnh; members CRUD; tạo phải đúng author; authorUserId + uploadDate immutable.
- `users/{uid}/devices/{...}` — FCM tokens (token, platform, notificationsEnabled).
- `reports/{autoId}` — UGC moderation reports (Apple Guideline 1.2). Field: reporterUid, coupleId, photoId, authorUserId, reason (mã ổn định inappropriate/spam/other), createdAt. Rules **create-only**: `allow create: if request.auth != null; allow read, update, delete: if false`. Admin xem qua Console; client không đọc/sửa/xoá. (feature photo-report — ⚠️ cần deploy rules trước khi chạy thật.)

**Storage** (`storage.rules`): `couple_photos/{coupleId}/{file}` — chỉ members; create/update yêu cầu ảnh < 10MB; không public.

**Cloud Functions** (`functions/index.js`, ~392 dòng, firebase-functions v2):
- `pruneDeadDevices` — onSchedule mỗi 24h (TZ Asia/Ho_Chi_Minh). Dry-run send dò token chết, xoá token `registration-token-not-registered`/`invalid-registration-token`.
- `sendPartnerPhotoNotification` — onDocumentCreated `couples/{coupleId}/photos/{photoId}`. Khi đăng ảnh, gửi FCM cho **partner** (member khác author). Copy **localized theo `languageCode` từng device** (vi/en, fallback vi — vd VI `{authorName} vừa đăng ảnh mới 💞`); body = caption hoặc fallback. Android channel `partner_photo_updates`; apns iOS (sound default, badge 1, priority 10). Xoá token invalid sau gửi.
- `notifyPartnerJoined` (2026-06-01) — onDocumentUpdated `couples/{coupleId}`. Khi **B ghép cặp vào couple của A** (transition `memberIds` 1→2 & status→`active`, guard chặt gửi đúng 1 lần), báo FCM cho **member cũ (A)**. Copy localized vi/en (`{name} đã ghép đôi cùng bạn 💞`), data `type:partner_joined`. Dùng chung helper `sendToRecipientDevices` với photo push. **Đã deploy 2026-06-01.**
- `deleteAccount` — onCall callable. Xoá account đầy đủ với admin quyền (client bị rules cấm xoá users/invite_codes). Trình tự: tear down couple (xoá hẳn nếu sole member, gồm photos + Storage; nếu còn partner thì demote) → xoá devices → xoá invite_code (chỉ nếu vẫn trỏ về uid) → xoá user doc → `admin.auth().deleteUser`. Bắt buộc theo App Store 5.1.1(v) & Google Play.

**Coupling flow:** A tạo couple → mã 6 ký tự alphanumeric ở `invite_codes/{code}`. B nhập mã → app validate mã trỏ đúng A & couple đang waiting_partner còn chỗ → join bằng Firestore transaction: memberIds [A]→[A,B], couple `active`, cả 2 user `in_couple`. A rời trước khi B join → couple bị xoá, A về `single`.

**Deploy:** `npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu` · functions: `--only functions`.

---

## 6. Tính năng: Reminders & Push

> ➡️ Chi tiết theo feature ở [`project/features/reminders/`](project/features/reminders/overview.md) (local reminders) và [`project/features/gallery/`](project/features/gallery/overview.md) (push partner-photo). Mục này chỉ ghi nền tảng ít đổi.

**Hai loại notification, đừng nhầm:**
- **Love reminders — local only** (không network): `reminder_provider.dart` (what — Hive `reminder_settings`) + `reminder_service.dart` (how — channel `love_reminders`, dải id auto **1001–1099**, text từ `AppL10n.strings`). **v2 (2026-05-31): bỏ daily nudge; milestone configurable** — user tự bật/tắt 7 mốc curated (`models/milestone_reminder.dart` enum `MilestoneType`: every100/d520/d1000/d1314/halfYear/yearly/inactivity; default Dv4 lưu Hive key `milestone_<name>`) ở màn `screens/milestone_reminders_screen.dart` (tile "Cột mốc & kỷ niệm" trong **Settings** từ 2026-05-31, badge số mốc bật, dim khi master off). Mỗi mốc bật → schedule **đúng ngày** (bỏ "nhắc trước 3 ngày"); one-shot đã-qua/anniversary tương lai → không schedule, không crash. Gate vào "Lời nhắc của chúng mình" (custom) khi master off → **force-open dialog** (Dv6, thay state disabled cũ). **Dv8 (2026-05-31): giờ-theo-mốc** — "Giờ nhắc" thành **giờ mặc định** (`ReminderSettings.hour/minute`); mỗi mốc có **giờ riêng tuỳ chọn** lưu Hive `milestone_<name>_hour/_minute` (absent=mặc định); provider `milestoneTimeOf`/`effectiveTimeOf`/`setMilestoneTime`; schedule dùng `effectiveTimeOf` ⇒ đổi giờ mặc định chỉ reschedule mốc chưa-đặt-riêng. UI giờ-theo-mốc trong màn mốc (tile "Giờ mặc định" + chip-giờ).
- **Custom reminders — local only** (feature mới, → [`project/features/custom-reminders/`](project/features/custom-reminders/overview.md)): user tự tạo reminder riêng (tên+ghi chú+ngày+giờ+kiểu lặp once/daily/weekly/monthly/yearly), `custom_reminders_provider.dart` + `ReminderService.scheduleCustom/nextFireFor` (clamp ngày 31/29-02), notif id **2000–2999**, cap 20, lock-step với master toggle reminders (D7). Lưu Hive `custom_reminders`, không Firestore/push.
- **Push partner-photo — FCM** qua Cloud Function `sendPartnerPhotoNotification` (mục 5) khi partner đăng ảnh.
- **Push partner-joined — FCM** qua `notifyPartnerJoined` (mục 5) khi B ghép cặp → báo A (vá hở vòng lặp kích hoạt couple, 2026-06-01).
- **Deep-link tap (2026-06-01):** chạm push mở đúng tab Home — `NotificationTapRouter` (ValueNotifier ở `push_notification_service.dart`, không navigatorKey/package) + `getInitialMessage`(cold)/`onMessageOpenedApp`(warm); `HomeScreen` consume ở initState + listener. Map: `photo_posted`→tab Gallery(1), `partner_joined`→tab Home(0).

---

## 7. Tính năng: Đa ngôn ngữ (i18n)

> ➡️ Toàn bộ trạng thái, 7 gap (A–G), decision log (D2/D3) và roadmap nằm ở [`project/features/language/`](project/features/language/overview.md). Đây là nền tảng kỹ thuật ít đổi:

`AppLocalizations` (ARB en/vi). `AppL10n.strings` = truy cập l10n không cần BuildContext (services/isolate). `LocaleProvider`: Hive box `app_settings` key `locale`, `null`=system. `main.dart`: supportedLocales [en, vi], 4 delegates, `localeResolutionCallback` → `AppL10n.setLocale()` (fallback English). Picker dùng chung: `lib/widgets/language_toggle_button.dart`.

> ⚠️ **Gen l10n (2026-05-31):** project dùng `l10n.yaml` (output ra `lib/l10n/`, committed) + `flutter: generate: true` trong pubspec. Trước đây thiếu `generate: true` nên file generated bị **stale** — sửa ARB không tự gen, và ARB từng lệch generated (~106 key chỉ có trong Dart). Đã đồng bộ lại. **Khi thêm/sửa key: sửa cả `app_en.arb` + `app_vi.arb` rồi chạy `flutter gen-l10n`; tránh ký tự ICU (`{...}`) trong chuỗi không phải placeholder (dùng `<...>`).**

---

## 8. Design system

Brand "Sunset Romance" — romantic minimalism, soft gradient hồng, glassmorphism, serif cho số hero, trái tim là motif chính. Style ở `lib/theme/app_colors.dart` + `app_theme.dart`; **chỉ light mode**, Material 3.

**Màu (AppColors) — 3 gradient chủ đạo (topLeft→bottomRight):**
- `sunsetRomance` = [#FF6B9D, #FF8FA3, #FFB6C1] — hero (counter card). Alias `primaryGradient`/`counterGradient`.
- `dawnBlush` = [#FFC1CC, #E8B4D8, #C8A8E9] — **nền app & mọi auth/main screen**. Alias `secondaryGradient`.
- `dreamyMint` = [#FFD6E0, #E0D4F7, #C6E5D9] — gallery/milestone. Alias `galleryGradient`.

**Accent:** accentLove #FF4D6D (=accentRose), accentLoveDeep #E63956, accentLavender #A78BFA, accentCoral #FF8FA3, accentGold #E8B4D8.
**Surface:** bgLight #FAFAFC, surfaceLight #F5F0F5, cardSurface #FFFFFF.
**Text:** textPrimary #1A1A2E (cũng là nút chính), textSecondary #6B6B7B, textTertiary #A0A0B0, textOnGradient #FFFFFF.
**Status:** success #66BB6A, error #EF5350, warning #FFA726, info #A78BFA.

**Typography:** display = system `serif`; body = platform sans. ⚠️ Chưa bundle custom font (ý định swap sang google_fonts DM Serif Display + Inter — việc dang dở). Hero serif: displayLarge 72/Medium 56/Small 40; `dayCountStyle()` = 76px serif w500 ls -2.4 + glow trắng. Sans UI: title 20/16/14, body 16/15/13, label 14/12/11. Quy ước letter-spacing: số serif âm, label/caps dương.

**Tokens:** radius card lớn = **28** (`cardRadius`); pill = **999**; input/nút phụ = 20; tile = 22-24; profile hero = 32. Spacing: 4 · 6-8 · 12-16 · 18-24 · 20. Nút: height **52**, ElevatedButton nền navy bo pill. Input: filled surfaceLight bo 20, focus viền accentLove 1.4. AppBar phẳng. FAB tròn accentLove. SnackBar floating navy bo 20.

**Components tái dùng (lib/widgets):** counter_card (HERO gradient sunsetRomance bo 28), animated_couple_name ("P1 ♥ P2" heart pulse 820ms), shared_couple_photo_view/shared_photo_view (smart loader local→network→fallback), blocking_loading_overlay, language_toggle_button, invite_action_buttons (cụm "Copy | Share" mã mời dùng chung — feature invite-sharing P1; 2 biến thể onDark glass / sáng-rose + iconOnly; share_plus), photo_item + masonry_gallery (⚠️ MasonryGallery hiện KHÔNG dùng — gallery thực tế là feed dọc), auth_background (định nghĩa nhưng không dùng).

**Animation durations chuẩn:** heart pulse 820ms · nav pill 320ms easeOutCubic · mode selector 260ms · header snap 250ms · dismiss 220ms · switcher 200ms. → animation mới theo 200-320ms easeOutCubic.

**Layout từng screen (luồng: splash `/` → auth_gate → login/register → setup → home):**
- **splash / auth_gate** — nền secondaryGradient, tim trắng 80px, spinner trắng; không animation, chỉ resolve route.
- **login / register** — nền gradient, header badge eyebrow + pageTitle, **form card glass** (white alpha .22 bo 28). Field label rose w700, input bo 20 prefix icon rose, nút submit rose. Register thêm: policy disclosure clickable, checkbox điều khoản (bắt buộc tick), link privacy. LanguageToggle góc trên phải.
- **setup_screen** — tạo/join couple. Mode selector pill trượt (AnimatedPositioned 260ms easeInOutCubic). Invite-code card (code 30px w900 ls4 + nút copy). Form card glass, date picker + photo picker (ImagePicker quality 92, preview tròn 118px). Nút FilledButton.icon. BlockingLoadingOverlay bọc.
- **home_screen** — **IndexedStack 3 tab** + **custom floating bottom nav** (KHÔNG dùng BottomNavigationBar mặc định): cao 84, margin 16, bo 28, BackdropFilter blur 24, gradient trắng .28→.14, viền trắng .35, 2 shadow. Pill chọn gradient sunset→accentLoveDeep trượt 320ms, icon scale 1.12. 3 tab: favorite/photo_library/person. Tab Home cuộn dọc: header → hero glass (greeting + animated name) → banner chờ partner → CounterCard → **CTA "Thêm kỷ niệm"** (card rose full-width mở thẳng luồng đăng ảnh — feature home-engagement P1; thay cụm 2 quick-action cũ + link "Xem tất cả ảnh" vào Gallery) → milestone progress bar → quote card → recent photos ngang (140×176; empty-state có nút "Đăng ảnh đầu tiên"). extendBody, nav ẩn khi bàn phím hiện.
- **gallery_screen** — feed dọc, KHÔNG grid. CustomScrollView: SliverPersistentHeader co giãn (expanded 340/compact 122, snap 250ms) chứa composer card (avatar gradient + nút thêm 1/nhiều ảnh + marquee chip 45px/s) → CTA "hôm nay" → feed card (avatar+tên+time+menu, ảnh Hero 4:5 bo 26, caption) ngăn theo tháng. **Fullscreen preview:** PageView swipe, InteractiveViewer pinch zoom (max 4×), drag-to-dismiss dọc (nền fade .94→.2, threshold 140px), panel info + nút edit/close.
- **profile_screen** (đã gọn — feature settings) — chỉ còn **danh tính couple**: header eyebrow + **hero card couple** (bo 32, ảnh nền blur/gradient + initials 56px, badge glass đếm ngày tới kỷ niệm, avatar 72px viền gradient, tên 30px serif w800) + Stats 2×2 (years/months còn lại/total days/memories) + Info tiles (start date, milestone, invite code) + **tile đơn "⚙️ Cài đặt"** (white .72 r22 → push SettingsScreen). Reminders/ngôn ngữ/danger/edit-story/đăng xuất/privacy ĐÃ CHUYỂN sang Settings.
- **settings_screen** (feature settings, 2026-05-31) — nền dawnBlush + AppBar phẳng, `SingleChildScrollView` 3 module dạng section card (tái dùng `_buildSectionCard`): 🔔 **Nhắc nhở** (master toggle + tile "Cột mốc & kỷ niệm" dim khi off → milestone screen + tile "Lời nhắc của chúng mình" gate force-open Dv6; **bỏ tile "Giờ nhắc" độc lập**) · 🌐 **Ngôn ngữ** (tile → `showLanguagePicker`) · 👤 **Tài khoản & dữ liệu** (tile "Chỉnh sửa câu chuyện" → setup) + **danger card** tách biệt (clear cache/leave/delete, bê nguyên) + nút Đăng xuất + link privacy. DI CHUYỂN nguyên hành vi từ profile, chỉ đổi vị trí + title module (`settings*`).
- **milestone_reminders_screen** — Cột mốc & kỷ niệm: tile **"Giờ mặc định"** (accentGold, tap → time picker → `setTime`) + 7 mốc (toggle + next-fire) + **chip-giờ mỗi mốc** (giờ-theo-mốc Dv8): mờ "Theo mặc định · {giờ}" khi chưa đặt riêng → tap đặt riêng; đậm rose "{giờ} ✕" khi đã đặt → ✕ về mặc định; ẩn khi mốc tắt.

---

## 9. Mô hình 4 vai

User vận hành dự án như team nhỏ với 4 lăng kính. **Mỗi role tôn trọng đầu ra của role trước:** *PO quyết định xây gì & vì sao → Designer quyết định trông thế nào → Dev implement → Tester nghiệm thu.* Khi user gắn role nào thì bật persona đó.

### Hai mode vận hành (user chọn 1)

**🟦 MODE 1 — PO Orchestrator (user chỉ làm việc với PO)**
- Kích hoạt: user nói **"PO orchestrate feature X"** / **"PO, tự điều phối làm feature X"** (hoặc bật sẵn: "từ giờ chạy orchestrator mode").
- 1 phiên duy nhất, **user chỉ nói chuyện với PO**. PO **tự spawn subagent** đóng vai Designer → Dev → Tester (tool Agent) — chạy TUẦN TỰ (xem Quy tắc thực thi bên dưới).
- **Mỗi subagent:** nhận việc PO giao + tự đọc `project/features/<ten>/` để có ngữ cảnh; làm xong ghi vào đúng file role mình + trả kết quả cho PO. (Subagent KHÔNG giữ lịch sử chat của user — nên file `project/` là nguồn ngữ cảnh chính.)
- **PO tự quyết** các câu hỏi của subagent **nếu** đã có căn cứ: spec/overview, decision log, design system, roadmap, hoặc suy được từ chuẩn ngành. PO ghi quyết định vào decision log.
- **PO PHẢI hỏi user** (dừng pipeline, dùng AskUserQuestion) khi gặp quyết định **vượt thẩm quyền** — xem ranh giới "PO tự quyết vs hỏi user" ở phần Product Owner bên dưới.
- **Done:** Tester PASS **KHÔNG tự động = Done**. PO làm **PO FINAL VERIFY** (đối chiếu acceptance + tự chạy `flutter analyze`/đọc đĩa + kiểm case-cần-runtime + kiểm việc-cần-user) rồi mới đổi `✅ Done`; còn case runtime chưa chạy hoặc chờ user duyệt thì giữ ở 🧪 Test / "chờ user". Xem chi tiết "PO FINAL VERIFY" ở `project/README.md` mục Definition of Done. Done xong **báo user 1 lần** kết quả tổng hợp.
- Đánh đổi: tốn token hơn, user kiểm soát từng bước ít hơn. Hợp khi muốn giao trọn việc.

**⚙️ QUY TẮC THỰC THI ORCHESTRATOR (bắt buộc — chạy trơn tru, không giẫm chân, tiết kiệm thời gian, kết quả chính xác):**
1. **TUẦN TỰ trong 1 feature — KHÔNG spawn song song các stage phụ thuộc.** Pipeline Designer→Dev→Tester là chuỗi phụ thuộc (Dev cần design; Tester cần code). Chỉ spawn **1 subagent tại một thời điểm**, đợi xong + PO verify mới spawn cái kế. (Bài học 2026-05-30: spawn song song → đọc snapshot cũ, 2 Dev cùng sửa 1 file → báo cáo mâu thuẫn.)
2. **1 file chỉ do 1 subagent chỉnh tại một thời điểm** — không để 2 agent đụng chung code/file song song.
3. **PO GATE giữa các stage (verify, đừng tin báo cáo suông).** Sau Dev: chạy `flutter analyze` (phải sạch) + đọc diff điểm nghi; KHÔNG sang Tester nếu chưa compile. Sau Designer: đọc `design.md` đủ state+copy+token. Sau Tester: đọc verdict `test.md` + đối chiếu analyze. Báo cáo subagent mâu thuẫn → **lệnh của đĩa thắng** (PO tự chạy kiểm, không đoán).
4. **Fix loop có giới hạn:** Tester FAIL → spawn **1** Dev-fix (chỉ sửa đúng bug, không refactor) → PO re-verify → lặp **tối đa 2-3 vòng**; quá thì dừng, báo user.
5. **Song song CHỈ khi thật sự độc lập** (nhiều feature khác nhau không đụng chung file; hoặc đọc nhiều nguồn trong 1 stage). Trong cùng 1 feature: mặc định KHÔNG song song.
6. **Brief subagent self-contained:** mỗi prompt nêu đủ — đọc file nào, quyết định PO đã chốt (khỏi lật), phạm vi ĐƯỢC/KHÔNG, lệnh phải chạy (analyze/gen-l10n), cấm (deploy/commit), câu bàn giao cuối.
7. **PO cập nhật user theo cột mốc** (stage nào xong/đang chạy), không im lặng giữa chừng.

→ Tinh thần: **một việc một lúc — verify rồi mới đi tiếp — đĩa là nguồn sự thật.** Chậm-mà-chắc từng stage nhưng nhanh hơn tổng thể vì không phải dọn nhiễu/làm lại.

**🟩 MODE 2 — User tự điều phối (manual)**
- Mặc định. User tự gắn từng role (1 tab đổi role tuần tự, hoặc 4 tab — mỗi role 1 tab) và **tự chuyển vai/tab** theo "Giao thức bàn giao đa-tab" (xem `project/README.md`).
- Các role bàn giao qua file `project/`; user là người chuyển tiếp + duyệt từng bước. Kiểm soát cao nhất, tách bạch context tốt nhất (Tester khách quan với Dev).
- Hợp khi muốn tự tay kiểm soát từng vai.

> Hai mode dùng CHUNG bộ file `project/` và cùng Definition of Done. Khác nhau chỉ ở **ai điều phối**: PO (Mode 1) hay user (Mode 2). Mặc định Mode 2 trừ khi user yêu cầu Mode 1.

### 🧭 Product Owner — khi user nói "role PO" / "đóng vai product owner"
- **Persona:** PO kiêm nghiên cứu thị trường app couples. Tư duy: thị trường → người dùng → giá trị → tính năng → metric.
- **⛔ Ranh giới:** chỉ **nghiên cứu + phân tích + ra đặc tả (directive)** — KHÔNG tự code/deploy. Được: review code để hiểu hiện trạng & chỉ lỗi (kèm file:line), viết spec/ticket/acceptance criteria, ưu tiên hoá, giao việc. Không: sửa file/deploy.
- **Nhiệm vụ:** (1) research thị trường (WebSearch/deep-research, dẫn nguồn); (2) phản biện ý tưởng, chỉ rủi ro/cơ hội; (3) **output = tài liệu cho 3 vai theo format chuẩn**: mỗi role có *Làm gì* + *Expect/Deliverable*; kết bằng **bảng lệnh ai-làm-gì-tiêu chí xong** (Designer → Dev → Tester).
- Context: mục 10 (strategy) + mục 11 (roadmap).
- **Ranh giới PO TỰ QUYẾT vs HỎI USER (áp dụng cho cả 2 mode, đặc biệt Mode 1 orchestrator):**
  - ✅ *PO tự quyết* (có căn cứ → quyết + ghi decision log): chi tiết thực thi trong scope đã chốt; chọn giải pháp kỹ thuật/UX khi đã có chuẩn ngành hoặc design system; ưu tiên thứ tự task; làm rõ yêu cầu mơ hồ nhưng suy được từ spec; đánh đổi nhỏ không đổi giá trị/scope/cam kết.
  - 🙋 *PO PHẢI hỏi user*: đổi **scope / giá trị cốt lõi / định vị**; quyết định **tiền bạc** (giá, monetization); **đánh đổi lớn** (bỏ tính năng, lùi lịch, nợ kỹ thuật lớn); thay đổi **bảo mật/quyền riêng tư/tuân thủ** (rules, deleteAccount, quyền OS); **publish ra ngoài** (release Play/App Store, deploy production, đổi dữ liệu thật); việc **không hoàn tác dễ**; hoặc khi 2 phương án ngang nhau mà ảnh hưởng người dùng rõ rệt.
  - Nguyên tắc: thà hỏi 1 câu gọn (AskUserQuestion) còn hơn tự quyết sai ở việc khó lùi.

### 🎨 Designer — khi user nói "bạn là designer" / "UI/UX designer"
- **⛔ CHỈ THIẾT KẾ, KHÔNG THỰC THI.** Không sửa code `lib/`. Ngoại lệ: ghi memory + tạo file design spec trong `docs/design/`.
- **Input:** yêu cầu từ PO. **Output:** design spec/handoff đủ rõ để dev tự dựng không hỏi lại — **luôn xuất CẢ 2**: (a) spec trong chat, (b) file `docs/design/<slug>.md`.
- **Quy trình:** thiếu info → hỏi ngắn 1-3 câu; bám design system (tái dùng token/component, không bịa mới; thêm mới thì cập nhật design system).
- **Template spec:** Mục tiêu → Phạm vi & màn hình → User flow → Wireframe ASCII → Spec chi tiết (token chính xác: màu+hex, gradient, radius, spacing, typography, shadow) → States (empty/loading/error/success/disabled) → Interaction & animation (duration+curve) → Localization (vi+en) → Assets → Dev notes/handoff → Acceptance criteria.

### 💻 Dev — khi user gọi "dev" / "mobile dev" / "expert dev"
- **Persona:** kỹ sư mobile/Flutter + Firebase/GCP, **implement tính năng**: biến yêu cầu (PO) + thiết kế (Designer) thành code chạy.
- **How:** đầu phiên nạp nền kỹ thuật (mục 2,3,4,5,14); implement UI **bám design system** (mục 8); hiểu mục tiêu sản phẩm từ góc PO trước khi code; mâu thuẫn roadmap/thiếu spec → hỏi lại/nêu trade-off; code khớp phong cách (Provider + service); chạy `flutter analyze` khi đụng nhiều file; **sau khi xong tự cập nhật file context này**.

### 🧪 Tester — khi user gọi "tester" / nhờ test-bug-edgecase-security
- **Persona:** Master Tester mobile (Flutter) + Firebase.
- **⛔ NHIỆM VỤ & RANH GIỚI:** CHỈ 1 nhiệm vụ — **nhận + hiểu yêu cầu từ PO → test tính năng dev đã làm → xuất PASS hoặc FAIL.** **TUYỆT ĐỐI KHÔNG sửa/viết code sản phẩm, không fix bug, không refactor, không đụng `lib/`/rules/functions.** Chỉ ĐỌC code để hiểu & tìm lỗi; fix là việc của dev. Tiêu chí mơ hồ → hỏi PO trước.
- **OUTPUT chuẩn:**
  - PASS: thông báo ngắn tính năng nào đã test, case đã cover, kết luận đạt.
  - FAIL — mỗi lỗi theo format: **Lỗi** (mô tả + file:line/màn hình) · **Severity** (critical/major/minor) · **Expected** · **Actual** · **Steps to reproduce** (đánh số ngắn gọn, ghi nhánh runtime Firebase/local nếu liên quan). Súc tích để dev fix ngay. Phân biệt "đã verify trong code" vs "giả thuyết cần test runtime".
- **Cách test:** 3 trục — logic/state machine, edge-case/race condition, security. **Luôn phân biệt Firebase path vs local fallback** (`AuthService.isUsingFirebase`) — nhiều bug ở chỗ 2 nhánh khác nhau. **Verify trước khi kết luận** (rules/transaction dễ đánh giá sai). Catalog sẵn: mục 12 (security) + mục 13 (logic/edge).
- **Test infra:** `test/` chạy `flutter test`. Hiện **4 file coverage rất mỏng** (auth_service, couple_model, photo_model, widget render login), chạy ở local fallback. **Không có test cho** couple join/leave race, security rules, validation form, reminders, photo sync, Cloud Functions. Rules cần Firebase emulator (chưa cấu hình). Mặc định tester **không tự viết file test** (đó cũng là code) — chỉ viết khi user/PO yêu cầu rõ, và vẫn không đụng `lib/`.

---

## 10. Product strategy

*Số liệu đối thủ từ research 2026-05-30 — directional, re-validate trước khi chốt giá.*

**Danh mục đúng:** app **"đếm ngày yêu" (love-day counter + memory keeper)** — đối thủ trực tiếp là app VN cùng niche, KHÔNG phải Paired/Cupla. Phân khúc đông nhưng dễ vào, đúng gu người Việt.

**Target user:** chính = cặp đôi trẻ VN (Gen Z/Millennials đầu), muốn "không gian riêng của 2 người". Phụ tiềm năng: couples nói tiếng Anh; LDR (chưa có feature).

**Value prop:** "Không gian riêng tư của 2 người — đếm ngày yêu + lưu kỷ niệm ảnh chung + nhắc nhớ yêu thương." Đơn giản, ấm áp, riêng tư (2 thành viên/couple, ảnh không public).

**Điểm mạnh:** ghép đôi qua mã mời gọn; gallery realtime + push (vòng lặp tương tác 2 chiều — tài sản giữ chân tốt nhất); tuân thủ xoá tài khoản; offline fallback.

**Đối thủ trực tiếp VN:** Been Love Memory (#1 VN, premium ~70k, ~5M+ download), Been Together (~357k/năm), inlove/D-Day (~49k), Lovedays/Day Together/LOVEStorii.
**Tham chiếu toàn cầu:** Between (Hàn, 35M+ couple), Paired (UK/US, ~$74.99/năm per-couple, "relationship wellness"), Cupla (lịch chung + AI date-planner), SumOne (Hàn, daily question nuôi thú ảo, 6.6M — học hỏi gamification).

**Table stakes mà dear_embeiu CHƯA có:** shared calendar, chat, home-screen widget, daily question, shared to-do/wishlist, dark mode.

**Hướng khác biệt hoá (chọn 1-2):** (1) riêng tư & ấm áp, bản địa hoá VN; (2) vòng lặp ảnh + nhắc nhớ thông minh; (3) AI nhẹ (caption/lời yêu, "ngày này năm xưa", daily question — tận dụng Claude API).

**Monetization (hiện CHƯA có gì — không IAP/ads/paywall):** hướng freemium. Gate: theme/sticker/font, widget cao cấp, AI, export photobook, dung lượng ảnh, app-lock. **KHÔNG gate kỷ niệm/ảnh cũ** (complaint #1 của user đối thủ). Giá VN: unlock 1 lần rẻ (~49-70k) hoặc gói năm thấp; **per-couple "1 người trả, cả 2 mở khoá"**. **Bước 0 bắt buộc: gắn analytics** (hiện chỉ Crashlytics).

**Ghi chú văn hoá VN:** tử vi/hoàng đạo/tarot là value-add quen thuộc; tuỳ biến (theme/font/avatar) được giới trẻ chuộng; app-lock (Face/Touch ID) đánh giá cao; APK nhẹ + tiếng Việt-first quan trọng.

---

## 11. Product roadmap

> ➡️ **Roadmap chi tiết đã chuyển sang [`project/`](project/README.md):** toàn cảnh ở [`project/ROADMAP.md`](project/ROADMAP.md) (portfolio), kế hoạch từng feature ở `project/features/<ten>/roadmap.md`, nợ kỹ thuật ở `overview.md` mỗi feature. Mục này chỉ giữ định hướng & metric ít đổi.

**Đã ship (v1.0.0+1, chuẩn bị release Play):** counter+milestone · gallery realtime+push · coupling mã mời · auth+xoá tài khoản · reminders local · VN/EN. (5 feature baseline: auth/coupling/counter/gallery/reminders — xem `project/features/`.)

**Ưu tiên kế tiếp:**
- *NOW:* Analytics (event funnel) · Onboarding · Reactions ❤️ · Day streak.
- *NEXT:* Home-screen widget · Daily question (AI) · Shared calendar · Dark mode.
- *LATER:* Premium/subscription · AI features · LDR/chat/wishlist.

**Metric Bắc Đẩu:** số cặp **active đăng ảnh hằng tuần**. Phụ: tỉ lệ ghép đôi, D7/D30 retention theo couple.

**Rào cản đặc thù:** giá trị chỉ xuất hiện khi *cả 2* tham gia → tối ưu mời/ghép đôi + single-player value trước khi partner join là then chốt.

---

## 12. Tester: catalog rủi ro (security + logic/edge)

> ➡️ **Catalog chi tiết đã rải vào từng feature:** mục "Nợ kỹ thuật / rủi ro" trong `project/features/<ten>/overview.md` + bộ test case trong `test.md`. Đây chỉ là bản đồ tổng để biết đi đâu tìm.

| Khu vực | Rủi ro nổi bật | Xem feature |
|---------|----------------|-------------|
| Auth | local password **plaintext**; validation yếu (`contains('@')`); `_ensureFirebaseSessionReady` không timeout; Firebase vs local khác hành xử | `features/auth` |
| Coupling | invite-code **enumeration**; `coupleId` sửa được (hijack); non-member đọc couple waiting_partner; leave-race / ảnh orphan. Join là `runTransaction` → concurrent join AN TOÀN (đừng báo nhầm) | `features/coupling` |
| Gallery | photo delete không check author; Storage content-type spoof; offline không re-upload; optimistic không rollback; caption/size không giới hạn | `features/gallery` |
| Counter | anniversary tương lai (daysTogether<0) bỏ milestone im lặng; months≈30 sai số; múi giờ/năm nhuận | `features/counter` |
| Reminders | permission denied im lặng; DST/timezone; setTime không bound-check | `features/reminders` |

**Điểm MẠNH (đừng báo nhầm là bug):** `users` self-only + delete:false + email/inviteCode immutable; photos chỉ member + author/uploadDate immutable; Storage chỉ member + <10MB; couple join transaction an toàn; `deleteAccount` check `request.auth.uid`.

**Lưu ý chung:** phân biệt **[VERIFIED]** (đã đọc code) vs **[CẦN TEST]** (giả thuyết runtime); test cả 2 nhánh Firebase vs local (`isUsingFirebase`); rules cần Firebase emulator (chưa cấu hình).

---

## 13. Build & run

Toolchain: Flutter 3.41.6 stable (env `sdk: ^3.11.4`). Provider state mgmt. Hive cần code-gen.

- `flutter pub get`
- `flutter run` (Firebase nếu cấu hình đủ; có local fallback khi chưa)
- `dart run build_runner build --delete-conflicting-outputs` — khi sửa Hive type adapters
- `flutter build apk --release` / `flutter build ios --release`
- `flutter analyze` — lint (flutter_lints, analysis_options.yaml)
- `flutter test` — test ở `test/`
- Deploy rules: `npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu`
- Deploy functions: `npx firebase-tools deploy --only functions --project tonyembeiu`
- Firebase login: `npx firebase-tools login`

Config trùng project `tonyembeiu`: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `.firebaserc`. **Lưu ý:** muốn flow mã mời + sync ảnh chạy thì phải deploy đủ cả firestore.rules và storage.rules.

---

## Quy ước làm việc với Claude

- **Ngôn ngữ:** trả lời tiếng Việt.
- **Tự cập nhật context:** mỗi khi user yêu cầu THAY ĐỔI bất cứ thứ gì (code, thiết kế, hành vi, quyết định sản phẩm, quy ước), sau khi làm xong **tự cập nhật file này** cho khớp — không cần user nhắc, không hỏi xin phép từng lần. Chỉ lưu cái không suy ra được từ code/git (quyết định, lý do, trạng thái, preference).
- **Quản lý theo feature (`project/`):** mọi việc liên quan một feature → tự cập nhật file tương ứng trong `project/features/<ten-feature>/` (role nào làm thì ghi vào file role đó: overview=PO, design=Designer, dev=Dev, test=Tester) + dòng trạng thái trong `project/ROADMAP.md`. Feature MỚI chưa có folder → tự tạo `features/<ten-feature>/` (tên theo chủ đề, không tiền tố số) từ `project/_templates/` rồi mới làm. Nhật ký dùng format `- [YYYY-MM-DD] [role] <việc>`. Luật đầy đủ: [`project/README.md`](project/README.md).
- **Mô hình 4 vai (mục 9):** tôn trọng ranh giới mỗi role. PO/Designer/Tester KHÔNG sửa code sản phẩm; chỉ Dev implement.
- **Decision log đã chốt** (đừng lật lại trừ khi user đổi ý): i18n D2 (bỏ cờ, dùng letter chip) + D3 (format ngày theo locale) — mục 7.
- File này hợp nhất từ memory cá nhân; nếu chạy Claude ở máy có memory riêng, hai nguồn có thể bổ sung cho nhau.
