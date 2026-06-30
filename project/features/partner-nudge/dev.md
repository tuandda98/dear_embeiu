# Dev log: Nhắc người ấy (partner-nudge)

- [2026-06-29] [dev] Implement trọn feature (plan duyệt trước). `flutter analyze` 0, rules-test emulator **206 pass** (thêm ~19 case nudges + partnerReminders).

## Backend
- **`firestore.rules`** (trong `match /couples/{coupleId}`): thêm 2 collection ADDITIVE create-only/author-owned:
  - `nudges/{id}` — create-only (`hasOnly[authorUserId,text,createdAt]`, author==uid, text 1..200, createdAt==request.time), no update/delete.
  - `partnerReminders/{id}` — create (author pinned, text 1..200, minuteOfDay 0..1439, recurrence string, enabled bool, createdAt==request.time); update/delete **chỉ author** (`resource.data.authorUserId==auth.uid`, author immutable on update); read = member.
- **`functions/index.js`**:
  - `notifyPartnerNudge` (onCreate `nudges/{id}`): template `notifyChatMessage` nhưng **BỎ presence-suppress** + **body chứa text** (`buildPartnerNudgeText`, pattern love-note) + ghi inbox `{type:'partner_nudge', messageText}`.
  - `notifyPartnerReminderSet` (onCreate `partnerReminders/{id}`): push xác nhận "Người ấy đặt nhắc bạn: <text> lúc HH:MM" (`buildPartnerReminderSetText` + `formatMinuteOfDay`), **KHÔNG inbox** (transient).
  - Copy: `PARTNER_NUDGE_COPY`, `PARTNER_REMINDER_SET_COPY` (vi/en). KHÔNG thêm `PUSH_TYPE_PREF_FIELD` (always-on như love-note).
- **Test** `firebase_rules_test/test/firestore.couples-sub.test.js`: 2 describe block mới (nudges immutable/spoof/oversize/createdAt; partnerReminders author-only update/delete, minuteOfDay range, partner read OK).

## Client
- **`models/partner_reminder.dart`** — mirror `custom_reminder.dart`, tái dùng enum `ReminderRecurrence`; `minuteOfDay`+`toScheduleReminder()` (→ CustomReminder để dùng lại scheduling math).
- **`models/app_notification.dart`** — thêm `AppNotificationType.partnerNudge` + field `messageText` + tap-route → Home(0).
- **`services/partner_reminder_service.dart`** — Firestore (style `home_prefs_service`, fail-soft): `sendNudge`, `watchPartnerReminders`, `create/update/deleteReminder`.
- **`services/reminder_service.dart`** — band **3000–3049** (`_idPartnerReminderBase`, max 50) + `schedulePartnerReminders` (dùng lại `scheduleCustom`/`nextFireFor`) + `cancelPartnerReminders`.
- **`providers/partner_reminder_provider.dart`** — watch couple reminders → arm local doc do **partner** tạo; CRUD lịch của mình; `sendNudge`+cooldown 30s; `clear()` cancel band. Analytics `logNudgeSent`/`logPartnerReminderCreated`.
- **Wiring**: `main.dart` MultiProvider; `app/session_resolver.dart` 5 chỗ (read + signature `_resolve` + call site + `watchPartnerReminders` nhánh hasCoupleData + `clear()` ×3 nhánh thoát).
- **Tap-map 2 chỗ (đồng bộ)**: `push_notification_service._handleNotificationTap` (`partner_nudge`+`partner_reminder_set`→Home) + `AppNotification.targetHomeTab`. Notification center: `_titleFor`/`_subtitleFor`/`_iconFor` thêm case partnerNudge (`notifPartnerNudge` ICU).
- **UI**: `screens/nudge_partner_screen.dart` (TabBar 2 tab: Thúc ngay = chip 1-chạm gửi + ô tự gõ; Đặt lịch = list lịch mình + FAB) · `screens/partner_reminder_form_screen.dart` (mô phỏng custom form). Entry: **HeaderIconButton ở header Profile** (cạnh settings).
- **l10n**: thêm key partnerNudge*/partnerReminder*/notifPartnerNudge vào CẢ `app_en.arb`+`app_vi.arb` → `flutter gen-l10n`. Tái dùng nhãn recurrence `customRemindersRepeat*` + `customRemindersTimeLabel/Save`.

## [2026-06-30] CHỐT: chỉ còn TOGGLE, XOÁ màn riêng + instant nudge
User làm rõ (qua ảnh form Lời nhắc riêng): muốn tính năng nhắc người ấy **nằm ngay trong form custom reminder** (1 toggle), và **xoá hẳn màn "Nhắc người ấy" riêng** + instant nudge.
**A) Khôi phục toggle:** `CustomReminder.notifyPartner`+`partnerReminderId`; `CustomRemindersProvider.setCouple`/`canNotifyPartner`/`_syncPartner`/`_removePartner` reconcile mirror trong add/update/delete/toggle/restore (dùng `PartnerReminderService` trực tiếp); form switch `_buildNotifyPartnerCard` (gate canNotifyPartner); session_resolver `setCouple` wire (read+sig+call site+hasCoupleData+clear×3); l10n `customRemindersNotifyPartnerLabel/Subtitle`.
**B) Xoá instant nudge / màn riêng:**
- Xoá file `screens/nudge_partner_screen.dart` + `screens/partner_reminder_form_screen.dart`; gỡ entry HeaderIconButton + `_openNudge` ở `profile_screen`.
- `PartnerReminderProvider` rút gọn còn CHỈ phần nhận (watch `partnerReminders` → arm local doc của partner) + clear; bỏ sendNudge/cooldown/mine/CRUD.
- `PartnerReminderService`: bỏ `sendNudge` + `_nudges` (giữ watch/create/update/delete cho toggle).
- `app_notification`: bỏ type `partnerNudge` + field `messageText`. `notification_center`: bỏ 3 case. `push_notification_service`: bỏ tap `partner_nudge` (giữ `partner_reminder_set`). `analytics`: bỏ `logNudgeSent`/`logPartnerReminderCreated`+consts.
- **functions/index.js**: xoá CF `notifyPartnerNudge` + `PARTNER_NUDGE_COPY` + `buildPartnerNudgeText` (giữ `notifyPartnerReminderSet`). **firestore.rules**: xoá block `nudges` (giữ `partnerReminders`). **test**: xoá describe `nudges`.
- l10n: xoá hết key `partnerNudge*`/`notifPartnerNudge` + key màn/form riêng; GIỮ `partnerReminderNotifBody`.
- analyze 0; rules-test **197 pass**; node -c functions OK.
- ⚠️ DEV vẫn còn rule `nudges` + CF `notifyPartnerNudge` MỒ CÔI từ bản thử (deploy 2026-06-29) — vô hại (không client nào ghi `nudges`); dọn ở lần deploy DEV sau (redeploy rules + `firebase functions:delete notifyPartnerNudge`).

## Còn lại
- ⏳ Deploy DEV: `firestore:rules` + `functions:notifyPartnerNudge,notifyPartnerReminderSet` (default project = tonyembeiu-dev). PROD chờ lệnh user.
- ⏳ Smoke-test 2 thiết bị (A nudge → B push có nội dung; A đặt lịch → B confirm + đến giờ kêu local; sign-out B → band cancel).
- 🔜 Fast-follow (chưa làm): CF cron backstop cho lịch khi B lâu không mở app.
