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
