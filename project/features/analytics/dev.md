# 💻 Dev — analytics

> Dev sở hữu. Contract bất biến ở `overview.md` (mục 5 taxonomy, mục 6 riêng tư BẤT BIẾN). Implement theo Provider + service layer.

- **Trạng thái dev:** xong — chờ test
- **Người/role:** Dev
- **Ngày:** 2026-06-03

## Kiến trúc
- Thêm package `firebase_analytics: ^12.4.2` (`fvm flutter pub add`).
- `lib/services/analytics_service.dart` — singleton no-context `AnalyticsService.instance` (kiểu giống `AppL10n`/`ReminderService`):
  - Giữ `FirebaseAnalytics? _analytics`, CHỈ gán khi `FirebaseBootstrapService.isFirebaseReady`. Null → mọi log là **no-op** (local fallback an toàn).
  - `bool _enabled` đọc từ Hive box `app_settings` key `analytics_enabled`, default **true** (D1c). **Lưu dưới dạng String `'true'/'false'`** vì box `app_settings` đã được `main()`/`LocaleProvider` mở là `Box<String>` (lưu bool sẽ crash type). Đọc lại bằng `Hive.box<String>` nếu đã mở.
  - `init()`: gán `_analytics`, đọc `_enabled`, gọi `setAnalyticsCollectionEnabled(_enabled)` + `setConsent(adPersonalizationSignalsConsentGranted: false)` (tắt ad personalization phía Dart; iOS có thêm Info.plist cho cold-start window).
  - `logEvent(name, {params})`: no-op nếu `_analytics==null || !_enabled`; **lọc null** + (phòng thủ) bỏ value không phải String/num/bool trước khi gửi → `Map<String,Object>`.
  - Helper có kiểu cho từng event (xem bảng dưới) + `setUserId`, user props (`setCoupleStatus/setHasPostedPhoto/setAppLocale/setIsGuest`), `setEnabled/isEnabled`, `observer` (`FirebaseAnalyticsObserver` hoặc null).
  - Class `AnalyticsEvents` (hằng tên event + param key) + `AnalyticsJoinResult` (success/invalid_code/already_in_couple/error).
  - 🔒 Không helper nào nhận email/tên/note/answer/caption/mã mời/URL.
- `lib/main.dart`: `await AnalyticsService.instance.init();` ngay sau `FirebaseBootstrapService.initialize()`; MaterialApp `navigatorObservers: [if (observer != null) observer!]`.

## Call sites đã instrument (bắn ở SUCCESS path, trong provider/service — D4)
| Event | File | Hàm | Ghi chú |
|---|---|---|---|
| `login` + setUserId(uid) + setIsGuest(false) | `lib/providers/auth_provider.dart` | `signIn` | sau syncForUser |
| `sign_up` + setUserId(uid) + setIsGuest(false) | auth_provider | `signUp` | |
| (clear) setUserId(null) + setIsGuest(true) | auth_provider | `signOut` | |
| `account_deleted` + setUserId(null) | auth_provider | `deleteAccount` | chỉ nhánh success (errorCode==null) |
| `couple_created` + setCoupleStatus('waiting_partner') | `lib/providers/couple_provider.dart` | `createCouple` | |
| `couple_join_attempt(result)` | couple_provider | `joinCoupleByCode` | bắn CẢ success lẫn lỗi; lỗi map qua `CoupleErrorCode` → bucket |
| `couple_joined` + setCoupleStatus('in_couple') | couple_provider | `joinCoupleByCode` | nhánh success |
| setCoupleStatus('single') | couple_provider | `leaveCouple` | |
| `photo_posted(is_first)` + setHasPostedPhoto(true) | `lib/providers/photo_provider.dart` | `addPhoto` | `is_first` = `_photos.isEmpty` chụp TRƯỚC upload |
| `photo_deleted` | photo_provider | `deletePhoto` | |
| `love_note_set(action)` | `lib/providers/love_note_provider.dart` | `setMyNote` | action = `myNote==null?'create':'update'` (không log text) |
| `daily_question_answered` | `lib/providers/daily_question_provider.dart` | `submit` | không log nội dung |
| `daily_question_revealed` | daily_question_provider | `_resubscribe` listener | cờ `_revealLogged` (reset mỗi resubscribe) → bắn ĐÚNG 1 lần khi `hasRevealed` lên true |
| `language_changed(locale)` + setAppLocale | `lib/providers/locale_provider.dart` | `setLocale` | locale = `null?'system':languageCode` — đóng Gap G |
| `reminder_created(repeat)` | `lib/providers/custom_reminders_provider.dart` | `add` | repeat = `ReminderRecurrence.name` (once/daily/weekly/monthly/yearly) |
| `invite_shared('copy')` | `lib/widgets/invite_action_buttons.dart` | `_handleCopy` | không log mã (widget — invite-sharing không có provider) |
| `invite_shared('share_sheet')` | invite_action_buttons | `_handleShare` | bắn trước khi mở share sheet |
| `notification_opened(type)` | `lib/services/push_notification_service.dart` | `_handleNotificationTap` | type chuẩn hoá (photo_posted/partner_joined/love_note/daily_question); type lạ → không log |

User properties set: `couple_status`, `has_posted_photo`, `app_locale`, `is_guest`. Screen view: auto qua `FirebaseAnalyticsObserver`.

## Thay đổi khác
- `lib/services/couple_service.dart`: `CoupleException` thêm field optional `CoupleErrorCode? code`; tag các throw join (`alreadyHasCouple`/`alreadyInThis`/`inviteNotFound`) để provider map `result` mà KHÔNG parse chuỗi localized. `couple_provider._joinResultFor` map code → bucket.
- Toggle opt-out: `lib/screens/settings_screen.dart` thêm section "Privacy" với `_AnalyticsToggleTile` (`SwitchListTile.adaptive`, default ON, đọc/ghi `AnalyticsService.instance`). Entrance order các section sau đó +1.
- l10n: thêm `settingsAnalyticsTitle` + `settingsAnalyticsSubtitle` (en+vi) → `fvm flutter gen-l10n` (đã chạy). Section title tái dùng `privacyPolicyLabel`.

## Screen naming (DebugView đọc dễ — refinement 2026-06-03)
> Trước đó `screen_name` = route path thô (`/`, `/auth-gate`…) khó hiểu. Đã đổi sang nhãn tiếng Anh chuẩn GA4 (user chọn).
- `AnalyticsService.observer` dùng custom `nameExtractor` → `_screenNameFor(routeName)` map: `/`→**Splash**, `/guest`→**GuestCounter**, `/login`→**Login**, `/register`→**Register**, `/setup`→**CoupleSetup**, `/home`→**Home**; `/auth-gate`→**null (skip — resolver tạm)**; route lạ → trả tên verbatim.
- `AnalyticsService.logScreenView(name)` mới — cho màn KHÔNG phải route. HomeScreen tab (IndexedStack 0/1/2) gọi `_logTabScreenView`: **Home/Gallery/Profile** ở các điểm đổi tab (nav onTap, profile shortcut, warm-notif tap, cold-notif `_applyPendingTab` chỉ khi tab>0 để khỏi trùng 'Home').
- Màn push thêm `RouteSettings(name:…)` để observer bắt: profile→**Settings**; settings→**MilestoneReminders** / **CustomReminders** (2 chỗ); custom→**CustomReminderForm** (add+edit). analyze sạch.

## Native / privacy (file in-repo)
- `ios/Runner/Info.plist`: thêm `GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS = false` (Boolean). Không link AdSupport/IDFA. (plutil OK)
- `ios/Runner/PrivacyInfo.xcprivacy`: `NSPrivacyTracking=false` (giữ); `NSPrivacyCollectedDataTypes` thêm 3 mục: ProductInteraction (Analytics), DeviceID (Analytics), CrashData (AppFunctionality) — tất cả `Linked=true, Tracking=false`. (plutil OK)
- `docs/privacy-policy.html`: thêm disclosure Firebase Analytics (mục 1 bullet, mục 2 bảng, mục 4 sharing list, **mục 10 mới** "Analytics and international data transfer" — dữ liệu ẩn danh, **xử lý trên server Google có thể ngoài VN**, **opt-out ở Settings → "Share usage data"**, không quảng cáo/tracking). Renumber 10→11, 11→12. Last updated → 3 June 2026. (file vốn English-only nên giữ English.)

## Deploy
- **KHÔNG cần deploy Firebase** (không đổi rules/functions/storage). Analytics chỉ cần `google-services.json` / `GoogleService-Info.plist` đã có (project `tonyembeiu`). GA4 sẽ tự nhận khi build chạy.
- Verify runtime cần thiết bị thật + GA4 DebugView (chưa làm trong vòng này — code-level trước, đúng nợ kỹ thuật mục 9 của overview).

## Bảng giá trị cho user điền store (Data Safety / App Privacy)
> Chỉ liệt kê phần analytics MỚI. Email/name/photos/FCM/crash đã khai trước đó (xem privacy-policy mục 2).

### Google Play — Data Safety
| Data type | Collected | Shared | Purpose | Processed ephemerally | User can request delete |
|---|---|---|---|---|---|
| App interactions (Analytics) | Yes | No (Google = processor, không tính "shared") | Analytics | No | Yes (xoá tài khoản) |
| Device or other IDs | Yes | No | Analytics | No | Yes |
- **Is data encrypted in transit?** Yes (HTTPS/TLS).
- **Tracking (dùng cho ads/3rd-party):** **No** — không IDFA/Google signals/ad personalization.
- **Account/uid linkage:** user_id = Firebase uid khi đã đăng nhập (D2) → khai "Data is linked to your identity".

### Apple — App Privacy (App Store Connect)
| Data type | Used for | Linked to user | Used for tracking |
|---|---|---|---|
| Product Interaction | Analytics | Yes | **No** |
| Device ID | Analytics | Yes | **No** |
| Crash Data | App Functionality | Yes | **No** |
- **Tracking:** No (khớp `NSPrivacyTracking=false`).
- Khớp đúng `NSPrivacyCollectedDataTypes` đã khai trong `PrivacyInfo.xcprivacy`.

## Verify
- `fvm flutter analyze` → **No issues found!**
- `plutil -lint` Info.plist + PrivacyInfo.xcprivacy → OK.
- ⚠️ Cần Tester soi: 0-PII từng event (đặc biệt love_note/daily_question/invite — đã không truyền text/mã); opt-out off → no-op; toggle persist qua restart; reveal bắn đúng 1 lần; `is_first` đúng cho ảnh đầu.

## Nhật ký implement
- [2026-06-03] [Dev] Thêm firebase_analytics + AnalyticsService/AnalyticsEvents (no-context, no-op-safe, opt-out Hive default ON), wire main + navigator observer, instrument 17 call site (provider/service/widget invite/push tap), user props, toggle Settings (l10n en+vi), Info.plist ad-perso=false, xcprivacy 3 data type (linked, tracking=false), privacy-policy mục Analytics + data transfer + opt-out. analyze sạch. Không deploy.
- [2026-06-03] [Lead/Dev] Refinement: screen_name dễ đọc — custom nameExtractor (route→nhãn EN chuẩn GA4), `logScreenView` cho Home tabs (Home/Gallery/Profile), `RouteSettings(name)` cho Settings/Milestone/CustomReminders/CustomReminderForm; skip AuthGate. Verify runtime trên iOS sim (FA 12.14.0: collection enabled, screen reporting on, ads not linked, DebugView active). analyze sạch.
- [2026-10-14] [Dev] Thêm 9 event cho feature mới: `chat_message_sent` (ChatProvider.send) · `mood_set{has_note}` (MoodProvider.setMood, không gửi giá trị mood) · `care_message_sent{queued}` (care_message_screen) · `sleep_enabled{mode}` / `sleep_share_changed{enabled}` / `sleep_night_saved{source}` (SleepProvider) · `love_tree_opened` (openLoveTree) · `intro_finished{skipped}` (IntroScreen) · `feature_tour_shown{manual}` (FeatureTour). Nhánh `feature/analytics-new-features`. analyze 0 · test 592. Không backend, không deploy. Chưa kiểm DebugView.
- [2026-10-14] [Dev] Auth: `login_failed{method,reason}` · `sign_up_failed{method,reason}` · `password_reset_requested{result}` (AuthProvider). `AuthException` thêm field `code` (mã lỗi Firebase, chỉ cho analytics, không hiện UI); `reason` = code, `canceled` khi huỷ sheet Apple/Google, `unknown` khi lỗi ngoài dự kiến. KHÔNG gửi email/thông báo lỗi. analyze 0.
- [2026-10-15] [Dev] Tách `password_reset_failed{reason}` khỏi `password_reset_requested`; thêm `couple_join_failed{reason}` + `couple_create_failed{reason}` (CoupleProvider, có cả nhánh lỗi ngoài dự kiến → `unknown`). Gắn `CoupleErrorCode` cho mọi throw khi ghép đôi (emptyInvite, ownInvite, sessionNotReady, inviteNoSpace, targetNotFound, invalidInviteLink, localFull, firestorePermissionWrite, unauthenticated, unavailable, joinGeneric) — chỉ phân loại, copy UI không đổi. `couple_join_attempt` giữ nguyên 4 bucket. GA4: tạo custom dimension `reason` + `result` (Admin → Custom definitions). analyze 0 · test 592.
- [2026-10-25] [Dev] analytics-coverage (nhánh `feature/analytics-coverage`, từ daily-open-2). (A) `AnalyticsService.observer` thêm `routeFilter: route?.settings.name != null` → sheet/dialog có tên cũng log `screen_view`; đặt `RouteSettings` cho mọi `MaterialPageRoute/PageRouteBuilder` còn thiếu (gallery viewer/CreatePost, SetupScreen ở Journal, Money sub-screens qua `_moneyRoute`, MoneyGoal/MoneyWallet, MoneyCategories) + `routeSettings` cho ~25 sheet/dialog nội dung (`showMoneySheet`/sleep `_show` nhận tham số `name`); `_screenNameFor` map thêm ForgotPassword/VerifyEmail/ForceUpdate. (B) thêm ~30 event + helper (xem overview §5): photo/chat_bg/counter_bg/reminder/milestone/dq/lunar/decision/inbox/auth/couple/rps/sleep/weather/force-update/clipboard/ai toggle + `couple_left`, `love_tree_shared`, `notification_cleared_all`. `ai_questions_toggle` chuyển từ logEvent trần sang helper. Bỏ qua có chủ ý: `profile_updated`, `money_evening_reminder_changed`, `language_changed{system}`, dialog xác nhận/time picker. analyze 0 · test 1246 pass. Không backend, không deploy. GA4: có thể cần tạo custom dimension `field`, `action`, `cleared`, `count`, `notify_partner` nếu muốn báo cáo.
