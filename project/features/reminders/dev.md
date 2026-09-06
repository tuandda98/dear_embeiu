# 💻 Dev — Reminders

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md).

- **Trạng thái dev:** ✅ Baseline · ✅ **v2 (milestone customization) — chờ test (2026-05-31)**

## Đã implement (baseline)
- `reminder_provider.dart`: load/setEnabled (xin quyền OS, trả false nếu từ chối)/setTime/sync; persist Hive `reminder_settings`. Hằng số: milestone mỗi 100 ngày, nudge trước 3 ngày, inactivity 7 ngày.
- `reminder_service.dart`: singleton, channel `love_reminders`, id 1001-1005, `initialize()` không throw, Android `inexactAllowWhileIdle`, text từ `AppL10n.strings`.

## Reminders v2 — milestone customization (2026-05-31)

### File tạo/sửa
- **Tạo** `lib/models/milestone_reminder.dart` — enum `MilestoneType` (7 mốc) + extension `fixedDayOffset`/`isOneShot` + `kMilestoneOrder` (thứ tự cố định) + `kMilestoneDefaults` (Dv4). Tên enum = key suffix Hive (đổi tên = breaking).
- **Tạo** `lib/screens/milestone_reminders_screen.dart` — màn "Cột mốc & kỷ niệm": nền dawnBlush + AppBar phẳng (copy pattern custom), list 7 tile (icon 44 r16 rose .12, tên 15/w700, desc 12, dòng phụ Sắp tới/Đã qua/Pending/inactivity-sub, `Switch.adaptive` accentRose). Mốc đã-qua bọc `AnimatedOpacity` .6 200ms. Dùng `context.select` cho từng tile.
- **Sửa** `lib/services/reminder_service.dart`:
  - Bỏ `scheduleDaily`/`_nextInstanceOfTime` (Dv1). Bỏ `scheduleMilestoneApproaching`/`scheduleMilestoneToday`/id 1003-1004 cũ.
  - ID mới: const `_idLegacyDaily=1001` (chỉ để `cancelAll` dọn schedule cũ), `_idAnniversary=1002` (yearly), `_idMilestoneEvery100=1003`, `_idInactivity=1005`, `_idMilestoneHalfYear=1006`, `_idMilestone520=1010`, `_idMilestone1000=1011`, `_idMilestone1314=1012`. List `_autoIds` → `cancelAll` cancel hết dải.
  - Thêm `cancelMilestone(MilestoneType)`, `_idForMilestone(type)`, `scheduleMilestoneOneShot({type,date,...})`. Giữ `scheduleAnniversary`/`scheduleInactivity`/`_nextAnniversary`/`_at`. Custom v1 (`scheduleCustom`/`cancelCustom`/`nextFireFor`/`_clampedDate`/`_daysInMonth`, id 2000-2999) GIỮ NGUYÊN.
- **Sửa** `lib/providers/reminder_provider.dart`:
  - `_milestones` map (load từ Hive key `milestone_<name>`, default Dv4). Getter `isMilestoneEnabled`/`enabledMilestoneCount`/`milestoneOrder`. `toggleMilestone(type,value)` → persist + schedule/cancel mốc đó (dùng input couple cache `_lastAnniversary/_lastPhotoDate/_lastL10n`).
  - `_reschedule` mới: cancelAll → vòng qua từng mốc BẬT → `_scheduleMilestone`. `_scheduleMilestone` switch theo type: yearly→`scheduleAnniversary`; inactivity→7 ngày như cũ; every100/520/1000/1314/halfYear→one-shot, chỉ schedule nếu `date.isAfter(today)` (đã qua/future-anniversary → skip, không throw).
  - `nextFireForMilestone(type)` → `MilestoneNextFire` (upcoming{date,label}/passed/pending) cho UI. Helper `_addMonthsClamped` (halfYear, clamp ngày), `_nextAnniversaryDate`, `_clampDay`, `_daysInMonth`.
- **Sửa** `lib/screens/profile_screen.dart`:
  - Master toggle label/desc → key `remindersToggleLabel`/`remindersToggleDesc` (chỉ đổi ARB value).
  - Chèn tile "Cột mốc & kỷ niệm" (icon `celebration_rounded`, badge `enabledMilestoneCount` mốc, chevron) giữa tile Giờ nhắc & tile custom; `AnimatedOpacity` .45 + onTap null khi master off; on → push `MilestoneRemindersScreen`.
  - Đổi gate tile custom: master on → push `CustomRemindersScreen`; master off → `_showForceOpenDialog` (AlertDialog r28 cardSurface, icon 56 r18, title/body center, "Để sau" TextButton + "Bật" FilledButton accentLove pill). "Bật" → `reminderProvider.setEnabled(true,…)` → granted: `rescheduleAllEnabled()` + đóng + push custom; denied: đóng + snackbar `remindersV2ForceOpenDeniedMsg`.
- **Sửa** `lib/l10n/app_en.arb` + `app_vi.arb`: đổi VALUE 2 key `remindersToggleLabel`/`remindersToggleDesc`; thêm `remindersV2*` (entry/screen/next/past/pending/days-years label/force-open + denied) + `milestone*` (7 tên/desc + inactivitySub). `flutter gen-l10n` OK. Key cũ `reminderDaily*` GIỮ (không dùng — không gây warning vì getter vẫn sinh).

### ID mapping cuối (dải auto 1001–1099; custom 2000–2999 không đụng)
| Mốc | id | Loại schedule |
|---|---|---|
| (legacy daily — bỏ) | 1001 | chỉ cancel để dọn |
| yearly | 1002 | recurring `dateAndTime` (`scheduleAnniversary`) |
| every100 | 1003 | one-shot mốc 100 kế |
| inactivity | 1005 | one-shot 7 ngày |
| halfYear | 1006 | one-shot 6 tháng (clamp) |
| d520 | 1010 | one-shot anniversary+520 |
| d1000 | 1011 | one-shot anniversary+1000 |
| d1314 | 1012 | one-shot anniversary+1314 |

### Cách tính next-fire từng mốc
- **every100:** `((daysTogether ~/ 100)+1)*100` ngày kể từ anniversary; label = số ngày.
- **d520/d1000/d1314:** anniversary + N ngày; `> today` → upcoming (label N ngày), else `passed`.
- **halfYear:** `_addMonthsClamped(start,6)` (Aug31+6→Feb28/29); `> today` → upcoming, else `passed`.
- **yearly:** kỷ niệm calendar năm kế (clamp Feb29→28); label = số năm = `daysTogether~/365 +1`.
- **inactivity:** không có ngày cụ thể → UI hiện mô tả tĩnh `milestoneInactivitySub`.
- **daysTogether<0** (anniversary tương lai) → tất cả mốc đếm-ngày/tháng/năm trả `pending` ("Sẽ tính khi tới ngày kỷ niệm"), không schedule, không crash.

### Lưu milestone settings
Hive box `reminder_settings` (chung với enabled/hour/minute), mỗi mốc 1 key bool `milestone_<enumName>` (vd `milestone_every100`). Lần đầu thiếu key → dùng `kMilestoneDefaults` (every100/d1000/halfYear/yearly/inactivity=ON; d520/d1314=OFF). Persist qua cold start.

### Edge đã xử lý
- Anniversary tương lai → mốc đếm-ngày/tháng/năm không schedule + UI "pending"; inactivity vẫn chạy.
- Mốc one-shot đã qua → không schedule + UI "Đã qua" (item dim .6).
- Cold start: master off → `cancelAllSchedules` custom (main.dart cũ, không đổi); master on → custom rearm (không đổi). Auto reminders re-armed khi `sync()` chạy (ReminderProvider.load + couple data). Toggle mốc khi chưa sync → fallback an toàn (cache input null → bỏ schedule, vẫn persist).
- `cancelAll` cancel cả id 1001 cũ → dọn daily nudge sót từ v1.

### Checklist
- [x] Bỏ daily nudge (Dv1).
- [x] 7 mốc model + persist Hive + default Dv4.
- [x] Schedule theo từng mốc bật, chỉ đúng ngày (Dv5), id 1001–1099.
- [x] Màn "Cột mốc & kỷ niệm" 7 tile + states (upcoming/passed/pending/inactivity).
- [x] Profile: rename toggle + tile mốc + force-open gate (Dv6).
- [x] ARB vi+en + gen-l10n; không hardcode.
- [x] Custom v1 không regression (chỉ đổi gate).

### Kết luận analyze
`flutter analyze` → **No issues found!** (sau khi gỡ `_nextInstanceOfTime` không còn dùng).

## Việc cần làm tiếp (từ rủi ro — baseline còn lại)
- [ ] Trạng thái permission rõ + nút mở OS settings; fix coerce `requestNotificationsPermission()` null→true.
- [ ] Bound-check hour/minute ở `setTime`.
- [ ] [CẦN TEST] DST/timezone — cân nhắc reschedule khi đổi tz.

## Dv8 — Giờ theo từng mốc (2026-05-31, đi cùng feature settings)
> Chi tiết UI + cách lưu/schedule ở [`../settings/dev.md`](../settings/dev.md). Tóm tắt phần reminders:
- Model provider: `Map<MilestoneType,TimeOfDay> _milestoneTimes` (absent = theo giờ mặc định). Persist Hive cùng box `reminder_settings`, key `milestone_<name>_hour` + `milestone_<name>_minute` (set/clear cả 2). Load trong `load()`.
- API: `milestoneTimeOf(type)→TimeOfDay?`, `effectiveTimeOf(type)→TimeOfDay` (riêng||mặc định), `setMilestoneTime(type, TimeOfDay?)` (null=về mặc định; persist + reschedule riêng mốc nếu master+mốc đang bật).
- Schedule: `_scheduleMilestone` bỏ tham số hour/minute, tự lấy `effectiveTimeOf(type)`. `nextFireForMilestone.fireAt` cũng dùng effective. ⇒ `setTime` (đổi giờ mặc định) full-reschedule nhưng **mốc có giờ riêng không đổi** (effective per-mốc).
- `setTime` couple inputs thành optional (fallback cached `_lastAnniversary/_lastPhotoDate/_lastL10n`) để màn mốc đổi "Giờ mặc định" không cần couple data.
- Notification id giữ nguyên (1 id/mốc). `flutter analyze` sạch.
- Acceptance Dv8: [x] giờ riêng persist null=mặc định; [x] schedule dùng đúng giờ riêng/mặc định; [x] đổi mặc định reschedule chỉ mốc chưa-đặt-riêng; [x] ✕ về mặc định. ⏳ cần thiết bị xác nhận notification bắn đúng giờ mới.

## Nhật ký implement
- [2026-06-04] [Dev] **b2 — daily-question reminder** dùng chung hạ tầng này: `ReminderService` thêm `scheduleDailyQuestion`/`cancelDailyQuestion` (id **1004**, lặp `DateTimeComponents.time`). id 1004 **ngoài `_autoIds`** ⇒ ĐỘC LẬP master toggle (`cancelAll`/`_reschedule` không đụng). State+UI ở `reminder_provider`/`settings_screen`, wire sync + cancel ở `session_resolver`. Chi tiết đầy đủ: `project/features/daily-question/dev.md` mục "b2". Thuần local, không deploy.
- [2026-05-31] [Dev] **Dv8 — giờ theo mốc**: thêm `_milestoneTimes` + `milestoneTimeOf`/`effectiveTimeOf`/`setMilestoneTime` + persist Hive `milestone_<name>_hour/_minute` (null=mặc định); `_scheduleMilestone`/`nextFireForMilestone` dùng `effectiveTimeOf`; `setTime` fallback cached couple inputs. UI (tile "Giờ mặc định" + chip-giờ mỗi mốc) ở màn mốc — xem settings/dev.md. analyze sạch.
- [2026-05-30] [PO] Khởi tạo doc.
- [2026-05-31] [Dev] Fix biên: mốc one-shot/every100/halfYear rơi đúng hôm nay vẫn bắn nếu giờ nhắc chưa qua (so datetime thay vì ngày).
- [2026-05-31] [Dev] Implement **Reminders v2 — milestone customization** (Dv1–Dv7): tạo model `milestone_reminder.dart` + màn `milestone_reminders_screen.dart`; restructure `reminder_service`/`reminder_provider` (bỏ daily nudge, schedule từng mốc bật đúng ngày, id 1001–1099); profile rename toggle + tile mốc (badge + dim khi off) + gate force-open custom; ARB vi+en + gen-l10n. `flutter analyze` sạch. Trạng thái → chờ test.
- [2026-06-14] [Dev] **Notifications-revamp UI: gộp + bỏ master toggle.** (Provider đã bỏ master `setEnabled` + đổi daily-q sang multi-time bởi Lead — chỉ dùng API mới.) ① Tách body milestone thành widget tái dùng `MilestoneRemindersBody` (default-time tile + 7 mốc, Column không scroll) ở `milestone_reminders_screen.dart`; `MilestoneRemindersScreen` giờ chỉ là header + body. ② Màn gộp MỚI `lib/screens/reminders_screen.dart` `RemindersScreen`: `subScreenAppBar`-style `SubScreenHeader` (chip "LỜI NHẮC" bellRing → pageTitle → subtitle) + 2 `SectionHeader` ("Cột mốc & kỷ niệm" / "Lời nhắc của chúng mình") nhúng `MilestoneRemindersBody` + `CustomRemindersBody`, 1 ListView, nền dawnBlush. ③ Settings entry milestone+custom → 1 entry `RemindersScreen`. l10n mới: `remindersHubBadge/Title/Subtitle`, `remindersHubMilestonesSection(+Sub)`, `remindersHubCustomSection(+Sub)`, `settingsRemindersEntryTitle/Subtitle` (vi+en). Key cũ (`remindersToggleLabel`, `remindersV2ForceOpen*`, `settingsPushGroupLabel`, `settingsNotifType*`, `dailyQuestionReminderTimeLabel`...) GIỮ trong ARB (thôi dùng). `flutter analyze` sạch. UI-only, không deploy.
- [2026-06-14] [lead+dev] REVAMP màn Thông báo (user). (1) **Bỏ master toggle "Nhắc cột mốc & kỷ niệm"** → cột mốc LUÔN auto nhắc (gỡ gate `_settings.enabled` ở ReminderProvider: sync/setTime/toggleMilestone/setMilestoneTime; bỏ `setEnabled`; enabled ép =true, chỉ giữ hour/minute mặc định). (2) **Gộp** "Cột mốc & kỷ niệm" + "Lời nhắc của chúng mình" → 1 màn mới `reminders_screen.dart` (`RemindersScreen`, 2 section, subScreenAppBar+header lớn); tách `MilestoneRemindersBody`/`CustomRemindersBody` để tái dùng; bỏ gate force-open ở custom (`settings.enabled`). Settings còn 1 entry "Lời nhắc". Màn cũ Milestone/Custom giữ file (orphan). (3) Daily-Q reminder → nhiều giờ + couple-shared (xem `../daily-question/dev.md`). (4) Bỏ "Đẩy từ người ấy" (xem `../notifications/dev.md`). analyze 0, rules-test 154 pass, rules deployed DEV. Mode 1: Lead làm backend/provider, dev subagent làm UI, Lead nghiệm thu.
- [2026-06-14 vòng 2] [lead/dev] BỎ tile "Giờ mặc định" (user: mỗi lời nhắc 1 giờ riêng). milestone_reminders_screen: xoá `_DefaultTimeTile` khỏi `MilestoneRemindersBody`; `_TimeChip` đổi sang LUÔN hiện `effectiveTimeOf(type)` (pill rose chạm-để-`setMilestoneTime`), bỏ nhánh "Theo mặc định"+reset-✕. `setTime`/`milestoneTimeOf` thôi dùng ở UI (giữ ở provider). Key l10n `settingsDefaultTimeLabel`/`settingsMilestoneUsesDefault`/`settingsMilestoneCustomTimeReset` hết dùng (giữ ARB). analyze 0.

- [2026-06-14] [dev] **Gộp cột mốc + lời nhắc thành 1 list phẳng (user "gộp hiển thị" — tất cả đều là lời nhắc, cột mốc init-sẵn):** `reminders_screen.dart` BỎ 2 `SectionHeader` ("Cột mốc & kỷ niệm" + "Lời nhắc riêng") → stack thẳng `MilestoneRemindersBody` + SizedBox(12) + `CustomRemindersBody` dưới 1 header chính "Lời nhắc của chúng mình". Cột mốc (pre-seed, toggle+giờ, ngày tự tính, KHÔNG xoá) chảy thẳng vào lời nhắc tự tạo (add/sửa/xoá). KHÔNG đổi data-model (gộp hiển thị thuần). Gỡ import `section_header` thừa. Keys `remindersHubMilestonesSection*`/`remindersHubCustomSection*` thành orphan (giữ tạm). analyze lib/ 0 issue.

- [2026-06-20] [dev/lead] **Lời nhắc riêng "anh By → embe" (account-gated `thaohathao14@gmail.com`).** User muốn riêng account em bé có nhắc local: (1) **uống thuốc** 9:59/10:10/10:30 hằng ngày; (2) **trả lời câu hỏi** mỗi giờ tròn 7h–22h, **DỪNG ngay khi em ấy đã trả lời** (`DailyQuestionProvider.hasAnswered`), copy nhẹ nhàng tình cảm. Impl theo pattern EOD/lunar:
  - `ReminderService`: id band MỚI ngoài `_autoIds` — medicine `1100–1109` (daily-recurring `matchDateTimeComponents.time`, unconditional), question `1110–1139` (one-shot HÔM NAY, skip giờ đã qua, không roll sang mai). Methods `schedulePersonalMedicineDaily`/`schedulePersonalQuestionToday`/`cancelPersonalMedicine`/`cancelPersonalQuestion`/`cancelPersonalReminders`. Slot = record `({int hour,int minute,String title,String body})`.
  - `ReminderProvider.refreshPersonalReminders({email, iAnswered})`: gate `email==thaohathao14@gmail.com` (lowercase/trim) — account khác → cancel cả 2 band. Debounce signature `isTarget|iAnswered|dayKey`. Medicine luôn đặt; question: `iAnswered` → cancel, ngược lại đặt 7..22. Copy hardcode VN (gated 1 account VN, không cần l10n): title "Anh By nhắc nè 💕"/"Tới giờ uống thuốc rồi 💊", body xoay vòng 4 câu.
  - `home_screen._refreshDqSafetyNet`: gọi thêm `refreshPersonalReminders(email, iAnswered: dq.hasAnswered)` — chung hook với EOD nên dừng-khi-trả-lời + re-arm mỗi launch/update.
  - analyze 0 (full). **Client-only, không deploy.** Cần em ấy cài app bản mới + mở 1 lần để arm lịch.
  - ⚠️ Hạn chế local (chấp nhận như EOD): question hourly là one-shot/ngày → cần mở app trong ngày để arm giờ còn lại; nếu cả ngày không mở thì giờ trước đó không nhắc. Medicine daily-recurring nên fire đều kể cả không mở. iOS cap 64 pending notif — hourly 16 + medicine 3 + reminders khác, thường dưới ngưỡng.
- [2026-06-20] [dev/lead] **FIX bug prod: nhắc trả-lời-câu-hỏi giờ tròn (7h–22h) VẪN NỔ dù em ấy đã trả lời.** Root cause = RACE lên-lịch-lại bằng trạng thái `false` tạm thời: `DailyQuestionProvider.watchForCouple` mỗi lần (re)subscribe (mở app / đổi ngày / re-wire couple) **xoá `_answers=[]` + `isLoading=true` + `notifyListeners()` TRƯỚC khi stream trả về** (daily_question_provider.dart:98–100) → tại khoảnh khắc đó `hasAnswered=false` → hook `_refreshDqSafetyNet` chạy → `refreshPersonalReminders(iAnswered:false)` → **đặt lại các nhắc 7h–22h vừa bị cancel**. Khi stream trả về thật thì cancel lại — nhưng nếu app bị nền/kill trong khe đó, các nhắc "ma" còn nguyên và nổ dù đã trả lời.
  - Fix: `refreshPersonalReminders` thêm param **`isLoading`** — chỉ chạm dải question khi trạng thái **đã settled** (`isLoading==false`); khe loading bỏ qua hoàn toàn dải question. Tách debounce: **medicine** đặt vô điều kiện 1 lần/ngày (`_personalMedicineDayKey`, chạy cả khi loading nên không phụ thuộc DQ stream); **question** debounce riêng `_personalQuestionSignature='$iAnswered|$dayKey'`. Bỏ `_personalSignature` gộp cũ. Call site `home_screen._refreshDqSafetyNet` truyền `isLoading: dq.isLoading`.
  - Sau answer: stream trả về → `isLoading=false`, `hasAnswered=true` → cancel chạy (đúng). Khe empty-notify `isLoading=true` → skip → không re-arm. Stop condition GIỮ `iAnswered` (dừng-khi-EM-ẤY-trả-lời, đúng mục đích nudge; không đổi sang `hasRevealed` vì sẽ nag em ấy cả sau khi đã trả lời tới khi anh By cũng trả lời — tệ hơn).
  - **Cùng race ở end-of-day safety net** (`refreshDailyQuestionSafetyNet`, nhắc 21h/22h/23h, hủy khi `hasRevealed`=cả 2 trả lời): chặn bằng `if (!dq.isLoading)` quanh call site trong `_refreshDqSafetyNet` (settled notify kế tiếp re-run với state thật). Không gated account → cải thiện cho mọi couple, chỉ ngăn nhắc thừa.
  - analyze 0 (2 file). **Client-only, KHÔNG deploy** (chỉ logic local). Cần em ấy cài bản mới + mở app 1 lần để áp lịch sạch.
  - ⚠️ Lưu ý điều kiện dừng: nhắc giờ tròn dừng theo **em ấy đã trả lời** (`hasAnswered`), KHÔNG phải "cả 2". Vì "cả 2 trả lời" ⊃ "em ấy trả lời" nên *cả 2 trả lời ⇒ chắc chắn hết nhắc* (thậm chí dừng sớm hơn, ngay khi mình em ấy trả lời). Nhắc **uống thuốc** 9:59/10:10/10:30 là **vô điều kiện** (vẫn nổ mỗi ngày, đúng thiết kế).
- [2026-06-20] [dev/lead] **Nhắc daily-question giờ-tự-đặt (MỌI user) → answer-aware** (user yêu cầu: "đừng khi cả 2 đã trả lời; người đã trả lời rồi thì nhắc người còn lại trả lời"). Trước đây band 1040–1049 là **lặp hằng ngày vô điều kiện** (`DateTimeComponents.time`) → trả lời xong tới giờ vẫn nhắc. Đổi:
  - `ReminderService.scheduleDailyQuestionTimes`: từ lặp-hằng-ngày → **ONE-SHOT HÔM NAY** (skip giờ đã qua, không roll sang mai), giống EOD/personal. Provider re-arm mỗi ngày.
  - `ReminderProvider._scheduleDailyQuestion`: **answer-aware** dùng chung cache `_eodHasRevealed`/`_eodIAnswered` (do `refreshDailyQuestionSafetyNet` cập nhật): `_eodHasRevealed` (cả 2 trả lời) → **cancel**; `_eodIAnswered` (mình xong, người kia chưa) → body `dqEndOfDayNudgePartnerBody` ("Người ấy chưa trả lời — nhắc một câu"); còn lại → `dailyQuestionReminderNotifBody` ("trả lời đi"). Debounce `_dqScheduleSignature='enabled|revealed|iAnswered|times|day'`. `refreshDailyQuestionSafetyNet` gọi thêm `_scheduleDailyQuestion` (re-arm cùng EOD). Reset signature ở `cancelDailyQuestionSchedule`.
  - Copy tái dùng l10n có sẵn (`dqEndOfDayNudgePartnerBody`) — KHÔNG thêm key, không cần gen-l10n. analyze 0 (3 file). **Client-only, KHÔNG deploy.**
  - ⚠️ **Đánh đổi (đã disclose user):** vì cần biết "ai đã trả lời" (app-observed) nên nhắc này giờ **chỉ nổ vào ngày app được mở ít nhất 1 lần** (one-shot, re-arm khi mở app/đổi ngày — giống EOD). Mất tính "nổ cả khi cả ngày không mở app" của bản lặp cũ. Nếu cần backstop "luôn nổ", làm hybrid (lặp "trả lời đi" + dời-sang-mai khi đã trả lời + one-shot today copy người-ấy) — chưa làm, chờ user chốt.
- [2026-06-20] [dev/lead] **Tắt nhắc daily-question (a) + EOD (b) RIÊNG cho máy em bé** (user: tránh trùng vì em bé đã có nhắc hourly "Anh By" (c) — trùng giờ 20h/21h/22h gây double-notif). Thuần LOCAL per-device, **KHÔNG đổi setting couple-shared** (anh By vẫn nhận (a)+(b) bình thường).
  - Field `ReminderProvider._suppressSharedDqReminders` (default false) = true CHỈ trên máy gated account. Set **đồng bộ trước mọi await** trong `refreshPersonalReminders` (`= isTarget`).
  - `_scheduleDailyQuestion` (a) + `_scheduleEndOfDay` (b): thêm `_suppressSharedDqReminders` vào guard (→ cancel) **và vào debounce signature** (để flag lật thì re-eval, không bị early-return giữ lịch cũ).
  - `home_screen._refreshDqSafetyNet`: **đảo thứ tự** — gọi `refreshPersonalReminders` (set flag) TRƯỚC `refreshDailyQuestionSafetyNet` (đọc flag) → trong 1 lượt hook: flag=true → (a)+(b) bị cancel ngay. Dùng `final reminders = context.read<ReminderProvider>()` cho cả 2.
  - Kết quả: máy em bé chỉ còn (c) hourly; mọi user khác giữ (a)+(b) như cũ. analyze 0 (3 file). **Client-only, KHÔNG deploy.**
- [2026-06-21] [dev/lead] **UI: bỏ HẲN chú thích nhắc cuối ngày** (user: "không cần thiết"). Trước đã thử dòng hint luôn-hiện → đổi sang icon "!" bấm-mới-hiện; nay **xoá luôn cả icon "!" + dialog**: `_DailyQuestionReminderTile` về tiêu đề trơn, không còn giải thích 21/22/23h. Xoá 2 string orphan `dailyQuestionReminderEndOfDayHint` + `commonGotIt` (vi+en) → gen-l10n. analyze 0. Client-only.
- [2026-09-07] [dev] **Đổi nội dung nhắc uống thuốc (account-gated `thaohathao14@gmail.com`, band 1100–1109)** theo yêu cầu user: bỏ title cố định `'Tới giờ uống thuốc rồi 💊'` + 3 body hardcode; thay bằng **pool 15 bộ (title, body)** `_personalMedicineMessages` trong `reminder_provider.dart` — title luôn mở đầu **"Anh By"/"Anh yêu"**, body là **lời chúc / lời thương** kèm nhắc uống thuốc (voice "chúng mình"). Giờ giữ nguyên 9:59/10:10/10:30 (tách hằng `_personalMedicineTimes`).
  - **Xoay vòng theo ngày:** `base = dayIndex % 15` (dayIndex = số ngày từ `_epoch` 2020-01-01), 3 khung giờ lấy 3 bộ liên tiếp ⇒ trong ngày 3 lời khác nhau, qua ngày lại là bộ mới, chu kỳ lặp 15 ngày.
  - ⚠️ Lịch vẫn `DateTimeComponents.time` (lặp hằng ngày) và chỉ re-arm khi app được mở trong ngày (debounce `_personalMedicineDayKey`) ⇒ ngày nào em ấy không mở app thì nội dung giữ nguyên bộ của lần arm gần nhất — vẫn nổ đủ 3 lần, chỉ là không đổi lời. Chấp nhận (đúng thiết kế cũ).
  - Client-only, KHÔNG đụng backend/rules. analyze 0 · test 81/81. **Cần build+phát hành bản mới thì máy em ấy (đang chạy bản store) mới nhận nội dung mới.**
