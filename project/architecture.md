# Kiến trúc code — Dear Embeiu

> Chi tiết tách từ `CLAUDE.md §2`. Đọc khi làm việc với services/providers/models/screens cụ thể.

## Entry flow (`lib/main.dart`)

`Hive.initFlutter()` → `FirebaseBootstrapService.initialize()` → (mobile) FCM background handler + `PushNotificationService.initialize()` → `ReminderService.initialize()` → `InstallStateService.handleFreshInstall` (purge session reinstall) → Crashlytics hook → `runApp`.

MultiProvider: AuthProvider, CoupleProvider, PhotoProvider, LocaleProvider, ReminderProvider. `home: SessionRouteScreen(branded:true)` (cold-start splash). Routes ở `lib/app/app_routes.dart`: splash `/`, authGate, login, register, forgotPassword, verifyEmail, home, setup, guest. **`MaterialApp.navigatorKey`** (2026-06-05, feature auth #3): cho listener session-revocation điều hướng ngoài widget-tree.

## Navigation gate (`lib/app/session_resolver.dart`)

`SessionResolver.resolveStartRoute()` → guest (đếm ngày local) nếu chưa auth (đổi từ login để qua Apple 5.1.1(v): mở thẳng tính năng không cần tài khoản); setup nếu authed chưa có couple; home nếu có couple. Mọi luồng (cold-start, sign-out, login/register success, **setup create/join couple — fix 2026-06-05**) đều qua authGate→resolver nên nhất quán.

⚠️ **Bài học (bug realtime sync):** realtime `watchCouple` (start ở `CoupleProvider.loadCoupleForUser`) + wiring watch love-note/daily-question/reaction/streak CHỈ chạy trong `SessionResolver`. Trước đây setup sau create/join `pushReplacementNamed(home)` THẲNG → creator vào Home không có watcher → B join không sync tới A (mã mời kẹt, không nhắn tin được) tới khi restart. **Mọi luồng đặt user vào Home PHẢI qua authGate, KHÔNG push thẳng `/home`.**

## Services (`lib/services/`)

- `auth_service.dart` (~548 dòng) — Firebase Auth + Firestore, có local fallback (FlutterSecureStorage mock store) khi Firebase chưa sẵn. Tạo invite code, sign up/in/out, persist session, gọi callable `deleteAccount`. `isUsingFirebase` quyết định nhánh. Còn comment "Sprint 1 local scaffold".
- `user_service.dart` — Firestore user profiles + device registrations; sync invite code sang `invite_codes`.
- `couple_service.dart` (~726 dòng) — tạo/join (transaction)/leave couple; upload ảnh đại diện couple lên Storage; merge local+remote.
- `photo_service.dart` — CRUD ảnh couple, watch Firestore stream, upload Storage, captions.
- `storage_service.dart` — local JSON (couple_data.json, photos_data.json + thư mục couple_photos) làm cache/offline.
- `reminder_service.dart` — local notifications (xem `CLAUDE.md §6`).
- `push_notification_service.dart` — FCM: xin quyền, lưu/refresh token ở `users/{uid}/devices`, unregister khi sign-out.
- `firebase_bootstrap_service.dart` — init Firebase 1 lần, tắt Crashlytics ở debug, expose `isFirebaseReady`.
- `install_state_service.dart` — phát hiện fresh install qua marker file.

## Providers (`lib/providers/`)

- `auth_provider` — status unknown/unauthenticated/authenticated; signIn/Up/Out/deleteAccount/refreshPushRegistration.
- `couple_provider` — create/join/update/leave + Firestore stream.
- `photo_provider` — watch + sync, addPhoto/deletePhoto/updateCaption.
- `reminder_provider` — milestone reminders (Hive `reminder_settings`).
- `custom_reminders_provider` — CRUD reminder local, Hive `custom_reminders`, cap 20, notif id 2000–2999.
- `locale_provider` — Hive box `app_settings` key `locale`, null=system locale.
- `love_note_provider` (#4) — stream `couples/{id}/notes`.
- `daily_question_provider` (#5) — stream `couples/{id}/dailyAnswers/{date}/responses`, reveal gate `hasRevealed`=cả 2 đã trả lời.
- `journal_provider` (a2) — nạp lịch sử Q&A đã reveal, phân trang.
- `reaction_provider` (b1) — optimistic+rollback, collectionGroup watch.
- `streak_provider` (b3) — suy chuỗi ngày kết nối từ marker `bothAnswered`, fail-soft, 5 state + milestone guard Hive.
- `notification_inbox_provider` (2026-06-06) — stream `users/{uid}/notifications` của couple hiện tại, `unreadCount` cho badge chuông Home, optimistic mark-read/xoá.

**love_note + daily_question + reaction + streak + notification_inbox wire watch ở `session_resolver` khi couple active, clear khi sign-out/no-couple.**

## Models (`lib/models/`)

- `app_user` — id, email, displayName, coupleId?, inviteCode, status (single/waiting_partner/in_couple).
- `couple` — person1/2Name, anniversaryDate, couplePhoto (local/url/storagePath), inviteCode, memberIds[1-2], status (waiting_partner/active), createdByUserId.
- `photo` — path, remoteUrl, storagePath, coupleId, authorUserId, authorName, caption.
- `account_invite`, `counter_data`, `auth_status` (enum).

## Screens (`lib/screens/`)

- `session_route` — gộp Splash+AuthGate (2026-06-05): `SessionRouteScreen({branded})`: cùng `resolveStartRoute`→pushReplacement, chỉ khác loader UI. `splash_screen.dart`+`auth_gate_screen.dart` đã XOÁ.
- `login`, `register`, `forgot_password`, `verify_email` — feature auth Đợt 1.
- `setup` — tạo/join couple. Tự prefill ngày yêu từ Hive `guest_settings` khi tạo couple mới (2026-06-05) — bê ngày user đã chọn ở guest sang, giảm ma sát funnel single-player→account; guard `Hive.isBoxOpen` nên cold-start thẳng vào setup không bị ảnh hưởng; không đụng luồng editing.
- `home`, `gallery`, `profile`.
- `settings` — Cài đặt tổng: gom reminders/ngôn ngữ/tài khoản+danger; vào từ tile "⚙️ Cài đặt" ở Profile.
- `milestone_reminders` — Cột mốc & kỷ niệm + giờ-theo-mốc.
- `custom_reminders` + `custom_reminder_form` — reminder tuỳ chỉnh, vào từ Settings.
- `guest_counter` — fix Apple 5.1.1(v). MÀN LANDING khi chưa đăng nhập: `SessionResolver` unauth→`/guest`; đếm ngày yêu thuần local, Hive `guest_settings`, tái dùng CounterCard/CounterData; là root KHÔNG có nút back. "Đăng nhập"→`pushNamed(login)`, "Đăng ký"→`pushNamed(register)`. Login bỏ nút guest thừa, login-success `pushNamedAndRemoveUntil(authGate,false)` clear stack. login+register có nút back → `maybePop()` về guest (được push trên guest).
  - **Link chéo login↔register dùng `pushReplacementNamed` (SWAP tại chỗ, 2026-06-05)** — stack luôn `guest→[login|register]`; "back to sign in" trên register không còn pop nhầm về guest khi mở thẳng từ guest; bấm qua lại không chồng stack.

Widgets: `lib/widgets/`. Theme: `lib/theme/`.

## Localization (`lib/l10n/`)

ARB-generated AppLocalizations (en/vi). `app_l10n.dart` (`AppL10n`) là lớp truy cập l10n không cần BuildContext — services/providers/background isolate dùng `AppL10n.strings`. MyApp đồng bộ qua `localeResolutionCallback` → `AppL10n.setLocale()`, fallback English; observe `AppLifecycleState.resumed` → `refreshPushRegistration()`.

⚠️ **Gen l10n (2026-05-31):** project dùng `l10n.yaml` (output ra `lib/l10n/`, committed) + `flutter: generate: true` trong pubspec. Trước đây thiếu `generate: true` nên file generated bị stale — sửa ARB không tự gen, và ARB từng lệch generated (~106 key chỉ có trong Dart). Đã đồng bộ lại. Khi thêm/sửa key: sửa cả `app_en.arb` + `app_vi.arb` rồi `flutter gen-l10n`; tránh ICU (`{...}`) trong chuỗi không phải placeholder (dùng `<...>`).
