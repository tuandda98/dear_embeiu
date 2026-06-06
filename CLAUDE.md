# Dear Embeiu — Project Context cho Claude

> Bộ nhớ dự án hợp nhất, commit vào repo để Claude ở mọi máy hiểu ngay hiện trạng — không phải dò lại. Nguồn: memory cá nhân (`~/.claude/.../memory/`). Code/quyết định đổi → cập nhật file này (xem [Quy ước làm việc](#quy-ước-làm-việc-với-claude)). Ngôn ngữ với user: tiếng Việt. User: thesavior9820.
>
> 📁 Quản lý theo feature ở [`project/`](project/README.md): mỗi feature 1 folder (`project/features/<ten-feature>/`, tên theo chủ đề không tiền tố số — vd `language`, `analytics`) gồm `overview.md` (PO) + `design.md` (Designer) + `dev.md` (Dev) + `test.md` (Tester); mỗi role tự ghi việc đã làm. `CLAUDE.md` = *toàn dự án*; `project/` = *từng feature*. Luật & lifecycle: [`project/README.md`](project/README.md).
>
> 📚 **Tài liệu chi tiết (tách khỏi CLAUDE.md cho gọn — ĐỌC khi làm việc liên quan, file dưới KHÔNG tự nạp vào phiên):** Design system (token/màu/layout từng screen) → [`project/design-system.md`](project/design-system.md) · Mô hình 4 vai + quy tắc orchestrator + catalog rủi ro Tester → [`project/roles.md`](project/roles.md) · Product strategy (đối thủ/monetization) → [`project/strategy.md`](project/strategy.md). Các mục 8/9/10/12 dưới đây chỉ là tóm tắt — cần chi tiết thì mở đúng file.

## 0. Operating rules (ĐỌC TRƯỚC — 6 luật bất biến)

> Chi tiết & lý do ở [Quy ước làm việc](#quy-ước-làm-việc-với-claude) (cuối file) + `project/roles.md`. Đây là bản rút gọn front-load để bám sát mọi phiên.

1. **Ngôn ngữ:** trả lời user bằng **tiếng Việt**.
2. **Toolchain Flutter — TÙY MÁY:** dùng đúng toolchain của máy hiện tại. Máy nào bare `flutter`/`dart` sai version (vd **máy cty = 3.5.4 → FAIL**) thì dùng `fvm flutter`/`fvm dart` (máy đó có hook **local-only** ở `.claude/settings.local.json` ép — KHÔNG commit nên không ảnh hưởng máy khác). Máy nào bare flutter đúng version (vd **máy nhà**) thì dùng trực tiếp. i18n: luôn sửa CẢ `app_en.arb` + `app_vi.arb` rồi chạy `gen-l10n` (qua toolchain đúng của máy).
3. **Ranh giới role:** chỉ **Dev** sửa `lib/`/rules/functions. PO/Designer/Tester KHÔNG (mục 9). Mỗi role chỉ ghi file của mình trong `project/features/<ten>/`.
4. **Đĩa là nguồn sự thật:** verify bằng đọc file + `flutter analyze` (qua toolchain đúng của máy — xem #2), KHÔNG tin báo cáo suông. Mâu thuẫn → đĩa thắng. **Đụng `firestore.rules`/`storage.rules`/`functions/index.js` → chạy `scripts/test-firebase-rules.sh` trước khi coi là xong (có Stop hook tự enforce — xem #13).**
5. **Tự cập nhật context:** thay đổi gì xong → tự cập nhật `project/features/<ten>/` + `project/ROADMAP.md` (+ file này nếu đụng toàn dự án), không cần nhắc. **Git commit/push:** KHÔNG tự làm — chờ user (có hook chặn). **Deploy Firebase:** ĐƯỢC phép chạy không cần hỏi khi task cần (rules/storage/functions); mỗi deploy TỰ GHI VẾT để restore vào `project/.firebase-deploy-log/` (hook `trace-firebase-deploy.sh`: snapshot rules + git HEAD + thời điểm; cách restore ở đầu `HISTORY.md`).
6. **Slash command nhanh** (`.claude/commands/`): **`/lead`** = 1 đầu mối mặc định (tự chọn lăng kính theo câu, bật pipeline khi xây feature) · `/po` `/designer` `/dev` `/tester` `/feature-new` `/roadmap` `/done`. **Mode mặc định = Mode 1 (PO Orchestrate):** xây feature thì user chỉ nói với Lead/PO, PO tự spawn subagent `.claude/agents/` (`dev`/`designer`/`tester`/`po`) — tester read-only (không sửa được code). Việc nhỏ / hỏi nhanh → nói thẳng, khỏi nghi thức.

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

Pattern: Provider (ChangeNotifier) + service layer. UI (screens/widgets) ← providers (state/ViewModel) ← services (data I/O, Firebase + local).

Entry `lib/main.dart`: `Hive.initFlutter()` → `FirebaseBootstrapService.initialize()` → (mobile) FCM background handler + `PushNotificationService.initialize()` → `ReminderService.initialize()` → `InstallStateService.handleFreshInstall` (purge session reinstall) → Crashlytics hook → `runApp`. MultiProvider: AuthProvider, CoupleProvider, PhotoProvider, LocaleProvider, ReminderProvider. `home: SessionRouteScreen(branded:true)` (cold-start splash). Routes ở `lib/app/app_routes.dart`: splash `/`, authGate, login, register, forgotPassword, verifyEmail, home, setup, guest. **`MaterialApp.navigatorKey`** (2026-06-05, feature auth #3): cho listener session-revocation điều hướng ngoài widget-tree.

Navigation gate: `lib/app/session_resolver.dart` `SessionResolver.resolveStartRoute()` → guest (đếm ngày local) nếu chưa auth (đổi từ login để qua Apple 5.1.1(v): mở thẳng tính năng không cần tài khoản); setup nếu authed chưa có couple; home nếu có couple. Mọi luồng (cold-start, sign-out, login/register success, **setup create/join couple — fix 2026-06-05**) đều qua authGate→resolver nên nhất quán. ⚠️ **Bài học (bug realtime sync):** realtime `watchCouple` (start ở `CoupleProvider.loadCoupleForUser`) + wiring watch love-note/daily-question/reaction/streak CHỈ chạy trong `SessionResolver`. Trước đây setup sau create/join `pushReplacementNamed(home)` THẲNG → creator vào Home không có watcher → B join không sync tới A (mã mời kẹt, không nhắn tin được) tới khi restart. Mọi luồng đặt user vào Home PHẢI qua authGate, KHÔNG push thẳng `/home`.

Services (`lib/services/`):
- `auth_service.dart` (~548 dòng) — Firebase Auth + Firestore, có local fallback (FlutterSecureStorage mock store) khi Firebase chưa sẵn. Tạo invite code, sign up/in/out, persist session, gọi callable `deleteAccount`. `isUsingFirebase` quyết định nhánh. Còn comment "Sprint 1 local scaffold".
- `user_service.dart` — Firestore user profiles + device registrations; sync invite code sang `invite_codes`.
- `couple_service.dart` (~726 dòng) — tạo/join (transaction)/leave couple; upload ảnh đại diện couple lên Storage; merge local+remote.
- `photo_service.dart` — CRUD ảnh couple, watch Firestore stream, upload Storage, captions.
- `storage_service.dart` — local JSON (couple_data.json, photos_data.json + thư mục couple_photos) làm cache/offline.
- `reminder_service.dart` — local notifications (mục 6).
- `push_notification_service.dart` — FCM: xin quyền, lưu/refresh token ở `users/{uid}/devices`, unregister khi sign-out.
- `firebase_bootstrap_service.dart` — init Firebase 1 lần, tắt Crashlytics ở debug, expose `isFirebaseReady`.
- `install_state_service.dart` — phát hiện fresh install qua marker file.

Providers (`lib/providers/`): auth_provider (status unknown/unauthenticated/authenticated; signIn/Up/Out/deleteAccount/refreshPushRegistration), couple_provider (create/join/update/leave + Firestore stream), photo_provider (watch + sync, addPhoto/deletePhoto/updateCaption), reminder_provider, custom_reminders_provider (CRUD reminder local — Hive `custom_reminders`, cap 20, notif id 2000–2999), locale_provider (Hive, null=system locale), love_note_provider (#4 — stream `couples/{id}/notes`), daily_question_provider (#5 — stream `couples/{id}/dailyAnswers/{date}/responses`, reveal gate `hasRevealed`=cả 2 đã trả lời), journal_provider (couple-journal a2 — nạp lịch sử Q&A đã reveal, phân trang), reaction_provider (reactions b1 — optimistic+rollback, collectionGroup watch), streak_provider (streak b3 — suy chuỗi ngày kết nối từ marker `bothAnswered`, fail-soft, 5 state + milestone guard Hive). love_note + daily_question + reaction + streak wire watch ở `session_resolver` khi couple active, clear khi sign-out/no-couple.

Models (`lib/models/`): app_user (id,email,displayName,coupleId?,inviteCode,status single/waiting_partner/in_couple), couple (person1/2Name,anniversaryDate,couplePhoto local/url/storagePath,inviteCode,memberIds[1-2],status waiting_partner/active,createdByUserId), photo (path,remoteUrl,storagePath,coupleId,authorUserId,authorName,caption), account_invite, counter_data, auth_status (enum).

Screens (`lib/screens/`): session_route (gộp Splash+AuthGate 2026-06-05 — `SessionRouteScreen({branded})`: cùng `resolveStartRoute`→pushReplacement, chỉ khác loader UI; `splash_screen.dart`+`auth_gate_screen.dart` đã XOÁ), login, register, forgot_password + verify_email (feature auth Đợt 1), setup, home, gallery, profile, settings (Cài đặt tổng — gom reminders/ngôn ngữ/tài khoản+danger; vào từ tile "⚙️ Cài đặt" ở Profile), milestone_reminders (Cột mốc & kỷ niệm + giờ-theo-mốc), custom_reminders + custom_reminder_form (reminder tuỳ chỉnh — vào từ Settings), guest_counter (fix Apple 5.1.1(v) — MÀN LANDING khi chưa đăng nhập: SessionResolver unauth→`/guest`; đếm ngày yêu thuần local, Hive `guest_settings`, tái dùng CounterCard/CounterData; là root nên KHÔNG có nút back; "Đăng nhập"→pushNamed(login), "Đăng ký"→pushNamed(register). Login BỎ nút guest thừa, login-success `pushNamedAndRemoveUntil(authGate,false)` clear stack. login+register có nút back → `maybePop()` về guest (được push trên guest). **Link chéo login↔register dùng `pushReplacementNamed` (SWAP tại chỗ, 2026-06-05)** — stack luôn `guest→[login|register]`, "back to sign in" trên register không còn pop nhầm về guest khi mở thẳng từ guest, và bấm qua lại không chồng stack. **Setup tự prefill ngày yêu từ Hive `guest_settings` khi tạo couple mới (2026-06-05)** — bê ngày user đã chọn ở guest sang, giảm ma sát funnel single-player→account; guard `Hive.isBoxOpen` nên cold-start thẳng vào setup không bị ảnh hưởng; không đụng luồng editing). Widgets ở `lib/widgets/`. Theme ở `lib/theme/`.

Localization (`lib/l10n/`): ARB-generated AppLocalizations (en/vi). `app_l10n.dart` (`AppL10n`) là lớp truy cập l10n không cần BuildContext — services/providers/background isolate dùng `AppL10n.strings`. MyApp đồng bộ qua `localeResolutionCallback` → `AppL10n.setLocale()`, fallback English; observe `AppLifecycleState.resumed` → `refreshPushRegistration()`.

---

## 3. Tech stack

Dart SDK env `^3.11.4` (pubspec.yaml đầy đủ, khỏi grep)

- Firebase/cloud: firebase_core ^4.1.1, firebase_auth ^6.0.2, cloud_firestore ^6.0.1, cloud_functions ^6.0.1, firebase_storage ^13.0.1, firebase_messaging ^16.0.2, firebase_crashlytics ^5.2.2, firebase_analytics ^12.4.2 (feature analytics — `AnalyticsService` no-context, no-op khi Firebase chưa sẵn/opt-out; posture no-tracking; toggle opt-out ở Settings).
- State mgmt: provider ^6.1.0 (+ flutter_localizations từ SDK).
- Local storage: hive ^2.2.3, hive_flutter ^1.1.0 (cần code-gen), flutter_secure_storage ^9.2.4 (session/local auth fallback), path_provider ^2.1.1.
- Notifications: flutter_local_notifications ^19.4.0, timezone ^0.10.1, flutter_timezone ^4.1.1.
- Media/UI: image_picker ^1.1.0, cached_network_image ^3.3.1, flutter_staggered_grid_view ^0.7.0 (masonry), cupertino_icons ^1.0.8.
- Misc: intl ^0.20.2, uuid ^4.0.0, connectivity_plus ^6.1.4, url_launcher ^6.3.1.
- UI revamp (Đợt 1, 2026-06-02): google_fonts ^6.2.1 (Fraunces hero + Plus Jakarta Sans UI), flutter_animate ^4.5.2 (staggered entrance), shimmer ^3.0.0 (skeleton loaders), lucide_icons ^0.257.0 (bộ icon), confetti ^0.8.0 (chưa dùng — dành Đợt 2 invite reveal).
- Dev deps: flutter_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.14.3, flutter_native_splash ^2.4.3, hive_generator ^2.0.1, build_runner ^2.4.9.
- Branding assets: flutter_launcher_icons (màu #FF6B9D, web theme #FF4D6D, iOS flatten remove-alpha) + flutter_native_splash (nền hồng #FF6B9D, heart trắng). Typography đã swap sang google_fonts (Fraunces + Plus Jakarta Sans) từ 2026-06-02 — runtime fetch (chưa bundle offline; first-launch có thể nháy font, việc Đợt sau).

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
- Build-phase "Strip Invalid Architectures" (thêm vào target Runner qua `ios/Podfile` post_install bằng Xcodeproj, 2026-06-01): lipo remove `i386/x86_64` khỏi mọi embedded framework + re-sign. Bắt buộc vì `objective_c.framework` (transitive native FFI) ship fat binary có slice simulator → Transporter báo *Validation failed (409) Invalid executable … x86_64 slice*. Idempotent, sống qua `pod install`. **⚠️ GUARD simulator (2026-06-04):** script đầu phase `if [ "${PLATFORM_NAME}" = "iphonesimulator" ]; then exit 0; fi` — KHÔNG strip khi build simulator (nếu strip, slice arm64-simulator/x86_64 của `objective_c.framework` bị xoá → app crash `DOBJC_initializeApi … Failed to load dynamic library` kẹt splash trên simulator). Chỉ strip cho device/archive (`iphoneos`). Podfile dùng **find-or-update** phase (không phải add-once) nên `pod install` luôn cập nhật script.
- ⚠️ Thiếu `CFBundleLocalizations`/`CFBundleAllowMixedLocalizations` (gap i18n — mục 7).

---

## 5. Firebase backend

Firebase project `tonyembeiu` (us-central1). `firebase.json`: functions ở `functions/`, rules `firestore.rules` + `storage.rules`, hosting public=`docs/`.

**🔀 Dev/Prod split (2026-06-05):** 2 project — **PROD `tonyembeiu`** (app live) + **DEV `tonyembeiu-dev`** (sandbox). Switch theo **build-config ở tầng native, KHÔNG flavor, KHÔNG sửa `lib/`**: **chỉ `--release` → PROD; debug + `--profile` → DEV** (prod = FALLBACK an toàn, release/config lạ không bao giờ ship config dev; profiling không đụng data prod). **Bundle id tách theo môi trường (2026-06-05, để cài cạnh nhau KHÔNG đè): release=`com.tony.dearembeiu` ("Dear Embeiu") · debug/profile=`com.tony.dearembeiu.dev` ("Dear Embeiu Dev")** — bản dev là app riêng trên device, không đè bản App Store. Suffix gắn native: iOS qua Podfile post_install (`PRODUCT_BUNDLE_IDENTIFIER`+`APP_DISPLAY_NAME` theo config, Info.plist dùng `$(APP_DISPLAY_NAME)`); Android qua `applicationIdSuffix=".dev"`+label `${appName}` (`build.gradle.kts` `configureEach`). ⚠️ Config dev phải đăng ký theo id `.dev` trong project dev (3 file: `src/{debug,profile}/google-services.json` + `ios/config/dev` plist) — thiếu thì build dev FAIL "No matching client" (release/prod KHÔNG ảnh hưởng). Android: Gradle plugin tự chọn `app/src/{debug,profile}/google-services.json` (dev) vs `app/google-services.json` (prod). iOS: build-phase `Select GoogleService-Info (env)` (Podfile post_install, chạy đầu tiên) copy `ios/config/{dev|prod}/GoogleService-Info.plist` theo `$CONFIGURATION` (Debug/Profile→dev, else→prod); file động `ios/Runner/GoogleService-Info.plist` đã untrack+gitignore (nguồn thật `ios/config/`). `.firebaserc` alias: **`default`=`tonyembeiu-dev` (dev = an toàn, bare deploy không trúng prod)**, `prod`/`dev`. Deploy prod PHẢI `--project prod` (kể cả hosting). ⚠️ Dev project cần bật console 1 lần (Firestore DB + Email/Password Auth + Storage bucket; Functions cần Blaze). **✅ Functions parity (2026-06-05):** dev đã deploy ĐỦ 9 function = prod (trước đó chỉ có `sendCustomVerificationEmail` → dev không có push + `deleteAccount` hỏng). ⚠️ Lần ĐẦU deploy 2nd-gen functions lên 1 project mới: các function trigger-Firestore (Eventarc) có thể FAIL lần đầu *"Permission denied while using the Eventarc Service Agent"* — **retry sau ~2-3 phút là OK** (chờ service-agent propagate). **Chi tiết đầy đủ: [`DEV_PROD_SETUP.md`](DEV_PROD_SETUP.md).**

Firestore data model:
- `users/{uid}` — profile, `inviteCode`, `coupleId`, status. Rules: tạo own (schema chặt), email immutable, inviteCode immutable khi đã set; `allow delete: if false`.
- `invite_codes/{code}` — map mã mời → account (userId, displayName, coupleId). `createdAt`/`userId` immutable; `allow delete: if false`.
- `couples/{coupleId}` — không gian chung; tạo solo (memberIds=1, `waiting_partner`); join → memberIds=2, `active`; leave → demote về waiting_partner; xoá chỉ khi còn 1 member. inviteCode + creator immutable.
- `couples/{coupleId}/photos/{photoId}` — feed ảnh; members CRUD; tạo phải đúng author; authorUserId + uploadDate immutable.
- `couples/{coupleId}/photos/{photoId}/reactions/{uid}` — Reactions ❤️ (feature reactions b1, 2026-06-04): 1 doc/người/ảnh (id=uid), `{emoji, reactedAt, authorUserId, coupleId}`; 6 emoji hợp lệ `❤️😍😂🥹🔥👍`. Watch qua **collectionGroup('reactions').where(coupleId)** (cần collection-group index `reactions.coupleId` — đã ở `firestore.indexes.json`, đã deploy). Rules ADDITIVE (write: uid==auth.uid && authorUserId==auth.uid && emoji∈6 && coupleId khớp). CF `notifyPhotoReaction` push tác giả ảnh (skip khi tự react). 3 surface: feed bar / fullscreen on-dark / Home badge read-only. ⚠️ rules+functions+index ĐÃ deploy.
- `couples/{coupleId}/notes/{uid}` — Love Note (feature #4, 2026-06-02): 1 doc/người (doc id = author uid), `{authorUserId, text ≤140, updatedAt}`, ghi đè (chưa lịch sử). Rules ADDITIVE: read if member; write if member && noteId==auth.uid && authorUserId==auth.uid && text ≤140. Hiện trên Home đối phương (thay card tĩnh `_buildQuoteCard`); CF `notifyLoveNote` push khi đổi. ⚠️ deploy rules+functions trước.
- `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}` — Daily Question (feature #5, 2026-06-02): mỗi ngày 1 câu hỏi chung (bank `lib/data/daily_questions.dart` **229** câu vi/en — a1 2026-06-04: chọn no-repeat theo couple `questionForCouple` (FNV-1a hash coupleId + permutation Fisher–Yates, index theo `daysSinceEpoch` → cùng couple+ngày cùng câu, không lặp trong 229 ngày; bỏ day-of-year cũ); ngày=giờ máy local). 1 doc/người/ngày (doc id=author uid), `{authorUserId, text ≤280, answeredAt}`. Reveal câu partner chỉ sau khi BẠN trả lời — enforce ở provider `hasRevealed`; rules cho cả 2 member đọc (reveal là UI affordance v1). Card Home ngay sau Lời nhắn (#5), confetti nhẹ 1 lần khi mở khoá. **Marker doc cha `dailyAnswers/{date}` = `{date, questionVi, questionEn, updatedAt, bothAnswered?, revealedAt?}`** (a2: lưu thẳng text câu hỏi để Nhật ký chính xác vĩnh viễn; b3: cờ `bothAnswered` set client-side khi đủ 2 response → streak). **Couple-journal (a2)** xem lại các ngày đã reveal (màn `journal_screen`, phân trang 30); **Couple-streak (b3)** đếm chuỗi ngày cả-hai-trả-lời, shame-free. Rules ADDITIVE (write responses: uid==auth.uid && authorUserId==auth.uid && text ≤280; marker: member ghi date/questionVi/questionEn string ≤300 — đã DEPLOY). CF `notifyDailyAnswer` push partner; `deleteCoupleCompletely` dùng `recursiveDelete(dailyAnswers)`. ⚠️ deploy rules+functions trước.
- `users/{uid}/devices/{...}` — FCM tokens (token, platform, notificationsEnabled, **languageCode**, updatedAt). ⚠️ Rule `isValidDeviceDocument` dùng `hasOnly` → PHẢI liệt kê đủ field client ghi (client ghi `languageCode` cho CF localize; thiếu nó trong rule → device write `permission-denied` → "Push token sync failed", **push hỏng âm thầm**). Đã vá + deploy 2026-06-04. **Bài học: deploy `firestore:rules` GHI ĐÈ production bằng file repo — repo rules phải luôn khớp field client ghi, nếu không sẽ regression.** **⚠️ Backward-compat (2026-06-06): backend prod DÙNG CHUNG cho mọi version app đang cài (1.0 cũ + 1.1 mới). Field optional thêm sau (`coupleCode`/`languageCode`/`sessionToken`) PHẢI đọc bằng `data.get('field', null)` trong rules — KHÔNG `data.field` trực tiếp (key vắng mặt do app cũ không gửi → engine báo "undefined" → DENY → app 1.0 vỡ `permission-denied`). Đã vá 3 field này + có test `firestore.backward-compat.test.js` khoá. Sửa rules = chỉ ADDITIVE, không siết cái app cũ đang dùng.**
- `reports/{autoId}` — UGC moderation reports (Apple Guideline 1.2). Field: reporterUid, coupleId, photoId, authorUserId, reason (mã ổn định inappropriate/spam/other), createdAt. Rules create-only: `allow create: if request.auth != null; allow read, update, delete: if false`. Admin xem qua Console; client không đọc/sửa/xoá. (feature photo-report — ⚠️ deploy rules trước.)

Storage (`storage.rules`): `couple_photos/{coupleId}/{file}` — chỉ members; create/update yêu cầu ảnh < 10MB; không public.

Cloud Functions (`functions/index.js`, ~392 dòng, firebase-functions v2). Push functions dùng chung helper `sendToRecipientDevices` (copy localized vi/en theo `languageCode` từng device, fallback vi; xoá token invalid sau gửi):
- `pruneDeadDevices` — onSchedule mỗi 24h (TZ Asia/Ho_Chi_Minh). Dry-run send dò token chết, xoá `registration-token-not-registered`/`invalid-registration-token`.
- `sendPartnerPhotoNotification` — onDocumentCreated `couples/{coupleId}/photos/{photoId}`. Đăng ảnh → FCM cho partner (member khác author). VI `{authorName} vừa đăng ảnh mới 💞`; body = caption hoặc fallback. Android channel `partner_photo_updates`; apns iOS (sound default, badge 1, priority 10).
- `notifyPartnerJoined` (2026-06-01) — onDocumentUpdated `couples/{coupleId}`. B ghép cặp vào couple của A (transition `memberIds` 1→2 & status→`active`, guard chặt gửi đúng 1 lần) → FCM cho member cũ (A). `{name} đã ghép đôi cùng bạn 💞`, data `type:partner_joined`. Đã deploy 2026-06-01.
- `notifyPartnerLeft` (2026-06-05) — onDocumentUpdated `couples/{coupleId}`. Inverse của joined: guard transition `memberIds` 2→1 & status→`waiting_partner` (leave demote; sole-member leave là DELETE nên không trúng). Push cho member còn lại. `{name} đã rời khỏi không gian của hai người`, data `type:partner_left`, `leaverUserId`. Cũng fire khi A xoá tài khoản (CF `deleteAccount` demote couple admin-side). **Đã deploy dev+prod 2026-06-05.**
- `notifyLoveNote` (2026-06-02) — onDocumentWritten `couples/{coupleId}/notes/{noteId}`. 1 người viết/sửa lời nhắn (noteId = author uid; bỏ qua delete/text rỗng/không đổi) → FCM cho member kia. `LOVE_NOTE_COPY`: `{tên} vừa để lại lời nhắn 💞`, body = text truncate 120, data `type:love_note`. Tap → Home tab.
- `notifyDailyAnswer` (2026-06-02) — onDocumentCreated `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}`. 1 người trả lời câu hỏi ngày → FCM cho partner (gợi mở khoá). `DAILY_QUESTION_COPY`: `{tên} đã trả lời câu hỏi hôm nay 💞`, data `type:daily_question`. Tap → Home tab 0. `deleteCoupleCompletely` thêm `db.recursiveDelete(coupleRef.collection('dailyAnswers'))` (subcollection lồng).
- `notifyPhotoReaction` (2026-06-04, feature reactions b1) — onDocumentCreated `couples/{coupleId}/photos/{photoId}/reactions/{uid}`. 1 người thả reaction → FCM cho TÁC GIẢ ảnh (skip nếu reactor==author — D3; chỉ onCreate, không spam khi đổi emoji). Copy `{tên} đã thả {emoji} vào ảnh của bạn`, data `type:photo_reaction`. Tap → Home tab Gallery(1). `deleteCoupleCompletely` thêm `recursiveDelete(reactions)` mỗi photo. Đã DEPLOY.
- `deleteAccount` — onCall callable. Xoá account đầy đủ với admin quyền (client bị rules cấm xoá users/invite_codes). Trình tự: tear down couple (xoá hẳn nếu sole member, gồm photos + notes + Storage; còn partner thì demote) → xoá devices → xoá invite_code (chỉ nếu vẫn trỏ về uid) → xoá user doc → `admin.auth().deleteUser`. Bắt buộc App Store 5.1.1(v) & Google Play.
- `leaveCoupleCleanup` (2026-06-06) — onCall callable. Dọn couple khi **người cuối RỜI** (không phải xoá tài khoản). Auth + **membership-guard** (caller PHẢI ∈ memberIds → chống phá/demote couple lạ) → gọi `handleCoupleOnAccountDeletion(coupleId, uid)` (rỗng → `deleteCoupleCompletely`; còn người → demote). Lý do: client SDK không có `recursiveDelete`, client cleanup cũ chỉ xoá được photos+couple_codes → bỏ sót notes/noteHistory/dailyAnswers/reactions thành **rác mồ côi**. Client `leaveCouple` nhánh sole-member gọi callable này (fallback client cleanup nếu lỗi). **`deleteCoupleCompletely` (2026-06-06) vá thêm:** `recursiveDelete(noteHistory)` + xoá top-level `couple_codes/{code}` (trước đó mồ côi cả khi xoá tài khoản). UI `settings._showLeaveCoupleDialog`: `memberCount<=1` → dialog cảnh báo "Xoá vĩnh viễn, không khôi phục được" (nút "Xoá tất cả"); còn partner → copy nhẹ. ⚠️ **Deploy dev rồi — prod chờ user cho phép.**

Coupling flow: A tạo couple → mã 6 ký tự alphanumeric ở `invite_codes/{code}`. B nhập mã → app validate mã trỏ đúng A & couple đang waiting_partner còn chỗ → join bằng Firestore transaction: memberIds [A]→[A,B], couple `active`, cả 2 user `in_couple`. A rời trước khi B join → couple bị xoá, A về `single`.

Deploy: `npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu` · functions: `--only functions`. **Trước khi deploy rules: `scripts/test-firebase-rules.sh` (123 unit test rules trên emulator — `firebase_rules_test/`).**

---

## 6. Tính năng: Reminders & Push

> ➡️ Chi tiết: [`project/features/reminders/`](project/features/reminders/overview.md) (local), [`project/features/gallery/`](project/features/gallery/overview.md) (push). Mục này chỉ ghi nền tảng ít đổi.

Hai loại notification, đừng nhầm:
- Love reminders — local only (không network): `reminder_provider.dart` (what — Hive `reminder_settings`) + `reminder_service.dart` (how — channel `love_reminders`, id auto 1001–1099, text từ `AppL10n.strings`). v2 (2026-05-31): bỏ daily nudge; 7 mốc curated user tự bật/tắt (`models/milestone_reminder.dart` enum `MilestoneType`: every100/d520/d1000/d1314/halfYear/yearly/inactivity; default Dv4 lưu Hive `milestone_<name>`) ở `screens/milestone_reminders_screen.dart` (màn Cột mốc, badge số mốc bật, dim khi master off). Mốc bật → schedule đúng ngày (bỏ "nhắc trước 3 ngày"); one-shot đã-qua/anniversary tương lai → không schedule, không crash. Gate "Lời nhắc của chúng mình" (custom) khi master off → force-open dialog (Dv6). Dv8 giờ-theo-mốc: "Giờ nhắc" = giờ mặc định (`ReminderSettings.hour/minute`); mỗi mốc có giờ riêng tuỳ chọn lưu Hive `milestone_<name>_hour/_minute` (absent=mặc định); provider `milestoneTimeOf`/`effectiveTimeOf`/`setMilestoneTime`; schedule dùng `effectiveTimeOf` ⇒ đổi giờ mặc định chỉ reschedule mốc chưa-đặt-riêng.
- Custom reminders — local only (feature mới, → [`project/features/custom-reminders/`](project/features/custom-reminders/overview.md)): user tự tạo reminder riêng (tên+ghi chú+ngày+giờ+kiểu lặp once/daily/weekly/monthly/yearly), `custom_reminders_provider.dart` + `ReminderService.scheduleCustom/nextFireFor` (clamp ngày 31/29-02), notif id 2000–2999, cap 20, lock-step với master toggle (D7). Lưu Hive `custom_reminders`, không Firestore/push.
- Daily question reminder — local only (feature b2, 2026-06-04): nhắc trả lời câu hỏi mỗi ngày (cú hích daily-open kiểu SumOne). `ReminderService.scheduleDailyQuestion` (lặp `DateTimeComponents.time`, **notif id 1004 — ĐỘC LẬP master milestone toggle, ngoài `_autoIds`**) + state ở `ReminderProvider` (Hive keys `dqReminder*`, default ON 20:00). Tile switch+giờ ở Settings; schedule trong `sync()` TRƯỚC early-return master. Thuần local, không deploy.
- Push partner-photo / partner-joined — FCM qua CF `sendPartnerPhotoNotification` / `notifyPartnerJoined` (mục 5) khi partner đăng ảnh / khi B ghép cặp báo A (vá hở vòng lặp kích hoạt couple, 2026-06-01).
- Deep-link tap (2026-06-01): chạm push mở đúng tab Home — `NotificationTapRouter` (ValueNotifier ở `push_notification_service.dart`, không navigatorKey/package) + `getInitialMessage`(cold)/`onMessageOpenedApp`(warm); `HomeScreen` consume ở initState + listener. Map: `photo_posted`→Gallery(1), `partner_joined`→Home(0).

---

## 7. Tính năng: Đa ngôn ngữ (i18n)

> ➡️ Trạng thái, 7 gap (A–G), decision log (D2/D3), roadmap: [`project/features/language/`](project/features/language/overview.md). Nền tảng kỹ thuật ít đổi:

`AppLocalizations` (ARB en/vi). `AppL10n.strings` = truy cập l10n không cần BuildContext (services/isolate). `LocaleProvider`: Hive box `app_settings` key `locale`, `null`=system. `main.dart`: supportedLocales [en, vi], 4 delegates, `localeResolutionCallback` → `AppL10n.setLocale()` (fallback English). Picker dùng chung: `lib/widgets/language_toggle_button.dart`.

> ⚠️ Gen l10n (2026-05-31): project dùng `l10n.yaml` (output ra `lib/l10n/`, committed) + `flutter: generate: true` trong pubspec. Trước đây thiếu `generate: true` nên file generated bị stale — sửa ARB không tự gen, và ARB từng lệch generated (~106 key chỉ có trong Dart). Đã đồng bộ lại. Khi thêm/sửa key: sửa cả `app_en.arb` + `app_vi.arb` rồi `flutter gen-l10n`; tránh ICU (`{...}`) trong chuỗi không phải placeholder (dùng `<...>`).

---

## 8. Design system

> ➡️ **Chi tiết đầy đủ (token màu/hex, typography, layout từng screen, components):** [`project/design-system.md`](project/design-system.md). Dưới đây chỉ là tóm tắt.

Brand "Sunset Romance" — romantic minimalism, gradient hồng, glassmorphism, serif cho số hero, trái tim là motif chính. Chỉ light mode, Material 3. Style ở `lib/theme/app_colors.dart` + `app_theme.dart`.
- **3 gradient chủ đạo:** `sunsetRomance` (#FF6B9D→#FFB6C1, hero/counter), `dawnBlush` (nền app & auth), `dreamyMint` (gallery/milestone).
- **Accent:** accentLove #FF4D6D, accentLoveDeep #E63956, accentLavender #A78BFA. **Text:** textPrimary #1A1A2E.
- **Typography (revamp Đợt 1):** Fraunces (hero serif) + Plus Jakarta Sans (UI) qua google_fonts; wired ở `app_theme.dart`.
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

Toolchain: Flutter 3.41.6 stable (env `sdk: ^3.11.4`). Provider; Hive cần code-gen.

- `flutter pub get`
- `flutter run` (Firebase nếu cấu hình đủ; có local fallback khi chưa)
- `dart run build_runner build --delete-conflicting-outputs` — khi sửa Hive type adapters
- `flutter build apk --release` / `flutter build ios --release`
- `flutter analyze` — lint (flutter_lints, analysis_options.yaml)
- `flutter test` — test Dart ở `test/`
- **`scripts/test-firebase-rules.sh`** — unit test Firestore+Storage **security rules** trên emulator (123 test, `firebase_rules_test/`). Tự dò JDK 21+ (firebase-tools 15 cần Java≥21; tự dùng JBR Android Studio nếu `java` mặc định <21), bật/tắt emulator, check cú pháp `functions/index.js`. **CHẠY mỗi khi đụng `firestore.rules`/`storage.rules`/`functions/index.js`.**
- Deploy rules: `npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu`
- Deploy functions: `npx firebase-tools deploy --only functions --project tonyembeiu`
- Firebase login: `npx firebase-tools login`

> 🔒 **Enforcement tự động (2026-06-06):** Stop hook `.claude/hooks/run-firebase-rules-tests.sh` (wire ở `.claude/settings.json`, committed) băm `firestore.rules`+`storage.rules`+`functions/index.js`; khi đổi so với lần PASS gần nhất thì tự chạy lại TOÀN BỘ rules test cuối lượt, FAIL thì CHẶN. Khỏi cần nhớ. Máy thiếu JDK 21+ → bỏ qua êm. Chi tiết: [`firebase_rules_test/README.md`](firebase_rules_test/README.md).

Config trùng project `tonyembeiu`: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `.firebaserc`. Lưu ý: flow mã mời + sync ảnh cần deploy đủ firestore.rules + storage.rules.

---

## Quy ước làm việc với Claude

- Ngôn ngữ: trả lời tiếng Việt.
- Tự cập nhật context: mỗi khi user yêu cầu THAY ĐỔI bất cứ thứ gì (code, thiết kế, hành vi, quyết định sản phẩm, quy ước), xong tự cập nhật file này cho khớp — không cần nhắc, không hỏi xin phép từng lần. Chỉ lưu cái không suy ra được từ code/git (quyết định, lý do, trạng thái, preference).
- Quản lý theo feature (`project/`): mọi việc liên quan một feature → tự cập nhật file tương ứng trong `project/features/<ten-feature>/` (role nào làm ghi vào file role đó: overview=PO, design=Designer, dev=Dev, test=Tester) + dòng trạng thái trong `project/ROADMAP.md`. Feature MỚI chưa có folder → tự tạo `features/<ten-feature>/` (tên theo chủ đề, không tiền tố số) từ `project/_templates/` rồi mới làm. Nhật ký format `- [YYYY-MM-DD] [role] <việc>`. Luật đầy đủ: [`project/README.md`](project/README.md).
- Mô hình 4 vai (mục 9): tôn trọng ranh giới mỗi role. PO/Designer/Tester KHÔNG sửa code sản phẩm; chỉ Dev implement.
- Decision log đã chốt (đừng lật lại trừ khi user đổi ý): i18n D2 (bỏ cờ, dùng letter chip) + D3 (format ngày theo locale) — mục 7.
- File này hợp nhất từ memory cá nhân; nếu chạy Claude ở máy có memory riêng, hai nguồn có thể bổ sung cho nhau.
