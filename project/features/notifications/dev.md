# Notifications — Dev notes

> File Dev sở hữu. Triển khai theo [overview.md](overview.md).

## Kiến trúc
Firestore-backed inbox: CF ghi doc → client nghe stream → bell badge + center.

### Data model — `users/{uid}/notifications/{autoId}`
Ghi bởi CF (Admin SDK). Field: `type` (photo_posted|photo_reaction|partner_joined|partner_left|love_note|daily_question), `coupleId`, `actorUserId`, `actorName` (snapshot tên lúc gửi), `createdAt` (serverTimestamp), `read` (bool, default false). Optional theo type: `photoId` (photo_posted/reaction), `emoji` (reaction), `noteExcerpt` (love_note, ≤140), `caption` (photo_posted, ≤140), `date` (daily_question, yyyy-mm-dd). Field rỗng/undefined bị `sanitizeInboxPayload` loại.

### Cloud Functions (`functions/index.js`)
- Helper `writeInboxNotifications(recipientIds, payload)` + `sanitizeInboxPayload` (gần `sendToRecipientDevices`). Gọi TRƯỚC `sendToRecipientDevices` trong cả 6 sender (độc lập deviceCount → inbox vẫn ghi dù không có token/push tắt). Resilient: try/catch nuốt lỗi, không bao giờ vỡ push.
- `deleteAccount` thêm `recursiveDelete(users/{uid}/notifications)` (subcollection không cascade khi xoá user doc — Apple completeness).

### Rules (`firestore.rules`) — ADDITIVE
`users/{uid}/notifications/{id}`: read owner · update owner CHỈ field `read` (`diff().affectedKeys().hasOnly(['read'])` + `read is bool`) · delete owner · **create: if false** (chỉ admin CF). 13 unit test ở `firebase_rules_test/test/firestore.notifications.test.js` (tổng 140 passing).

### Index (`firestore.indexes.json`)
Composite COLLECTION: `notifications` (`coupleId` asc, `createdAt` desc) — cho query stream.

### Client
- `lib/models/app_notification.dart` — enum `AppNotificationType` + `fromDoc` + `copyWith` + getter `targetHomeTab` (ảnh→1 Gallery, còn lại→0 Home; cũng cấp đích cho partner_left). Parse timestamp duck-typed (không import cloud_firestore vào model).
- `lib/services/notification_inbox_service.dart` — `watch(uid, coupleId)` (where coupleId==, orderBy createdAt desc, limit 50), `markRead/markAllRead/delete/clearAll` (batch, best-effort). Dựa Firestore offline cache.
- `lib/providers/notification_inbox_provider.dart` — `items`, `unreadCount`, optimistic markRead/remove/clearAll. Wire ở `session_resolver` (watch khi có couple, clear khi sign-out/no-couple/verify-gate) + register MultiProvider `main.dart`.
- `lib/screens/notification_center_screen.dart` — list + Dismissible vuốt xoá + popup (mark all read/clear all có confirm) + empty/loading state. Render text localized theo type. Tap: `markRead` + `NotificationTapRouter.pendingHomeTab.value = targetHomeTab` + `maybePop()` (tái dùng plumbing deep-link push; Home đang mounted nghe → đổi tab).
- `lib/screens/home_screen.dart` — `_buildNotificationBell()` ở header (badge unreadCount, →NotificationCenterScreen).
- `lib/services/push_notification_service.dart` — vá thêm nhánh tap `partner_left` → Home tab.
- l10n: keys `notif*` (vi+en) — tái dùng `loveNote*` cho relative-time.

## Nhật ký
- [2026-06-06] [dev] Dựng trọn feature: model/service/provider/screen + bell, CF inbox-write 6 sender + cleanup, rules+index+13 test, l10n vi+en. `flutter analyze` sạch, rules test 140 passing. Deploy DEV.
- [2026-06-06] [dev] Vá bug `partner_left` thiếu nhánh tap trong push handler (rơi vào default no-op).
- [2026-06-08] [dev] **Header Home: gỡ tim + chuông Lottie.** Xoá nút trái tim (shortcut Profile trùng tab dưới) khỏi `home_screen.dart` header → còn mỗi chuông. `_buildNotificationBell` thêm helper `_buildBellGlyph(unread)`: `Lottie.asset('assets/lottie/notification_bell.json', repeat: unread>0)` bọc `ColorFiltered` ép trắng + `errorBuilder` fallback về `Icons.notifications_none_rounded` (thiếu file → không crash). Tự tạo file bell Lottie (chuông swing 1s, 100×100, fill trắng, 4 shape: nub/dome/rim/clapper) — thay file = đổi animation, không đụng code. Package `lottie ^3.3.3` + `assets/lottie/` đã có sẵn. analyze sạch.
- [2026-06-08] [dev] **Deep-link daily_question → cuộn tới card** (mở rộng D-notif-3): `NotificationTapRouter.pendingHomeFocus` (string type); push handler + inbox tile set `'daily_question'`; `HomeScreen` `GlobalKey _dailyQuestionKey` (bọc card bằng `KeyedSubtree`) + listener `_onNotificationFocusRequest`/`_applyPendingFocus` → `_scrollToCard` (`Scrollable.ensureVisible`, delay 350ms cho tab settle, guard `ctx.mounted`). Client-only, analyze sạch. Mở rộng được cho love_note sau (thêm 1 case).
- [2026-06-08] [dev] **Đợt cải thiện flow (review A/B) — M1–M4.** ① **Auto-read**: `NotificationInboxProvider.markReadForTab`/`unreadForTab` + hook `home_screen build` (gated post-frame). ② **Deep-link ảnh**: `NotificationTapRouter.pendingPhotoId`; push/inbox set photoId; `GalleryScreen` consume → `openPreview`. ③ **Per-type settings**: `NotificationSettingsService` (Hive) + device-doc mirror (`saveDeviceRegistration.pushTypePrefs` + `refreshDeviceRegistration`); rules `isValidDeviceDocument` +3 field (`.get(.,true)` additive); CF `PUSH_TYPE_PREF_FIELD` lọc device (mute=push-only); Settings section + l10n 8 key. ④ **Badge thật**: CF `aps.badge`=count chưa-đọc (`count()` agg) thay `badge:1`; client MethodChannel `app/badge` (AppDelegate.swift + `AppBadge`) gọi từ inbox provider. ⑤ **Dịu tone** `partner_left`. **Verify:** analyze sạch, `node --check` OK, rules-test 140 pass. **Deploy DEV** (rules+functions). HOÃN: throttle ảnh-loạt + no-repush note nhỏ (index mới/heuristic mờ). Spec: [overview.md](overview.md) §7.
- [2026-06-08] [dev] **Redesign v2 "brand glass"** (user yêu cầu — màn cũ Material phẳng lạc tông so Home/Gallery). Viết lại `notification_center_screen.dart`: nền `secondaryGradient`+`SafeArea`, header custom (back glass `arrowLeft` + `⋯` glass, tiêu đề `pageTitleStyle` trắng + subtitle unread/all-caught), gom nhóm HÔM NAY/TRƯỚC ĐÓ (`_isSameDay`), tile = `GlassCard` (blur14/radius22, unread→fill0.30+viền `accentLove`/chấm hồng, đọc rồi→fill0.18) với `InkWell` ripple, avatar tròn 44 + **Lucide** theo type, vuốt-xoá `ClipRRect`+`trash2`, empty-state trong GlassCard + `bellOff`. Thêm param optional `GlassCard.borderColor` (default trắng, backward-compat). l10n mới: `back`, `notifGroupToday/Earlier`, `notifUnreadCount(count)`, `notifAllCaughtUp` (en+vi) + gen-l10n. Logic markRead/route/clear/menu giữ nguyên. `fvm flutter analyze` sạch; build iOS sim chạy, log khởi động 0 lỗi. Design spec: [design.md](design.md) §Redesign v2.
