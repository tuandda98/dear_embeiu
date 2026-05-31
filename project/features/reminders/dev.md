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
- [2026-05-31] [Dev] **Dv8 — giờ theo mốc**: thêm `_milestoneTimes` + `milestoneTimeOf`/`effectiveTimeOf`/`setMilestoneTime` + persist Hive `milestone_<name>_hour/_minute` (null=mặc định); `_scheduleMilestone`/`nextFireForMilestone` dùng `effectiveTimeOf`; `setTime` fallback cached couple inputs. UI (tile "Giờ mặc định" + chip-giờ mỗi mốc) ở màn mốc — xem settings/dev.md. analyze sạch.
- [2026-05-30] [PO] Khởi tạo doc.
- [2026-05-31] [Dev] Fix biên: mốc one-shot/every100/halfYear rơi đúng hôm nay vẫn bắn nếu giờ nhắc chưa qua (so datetime thay vì ngày).
- [2026-05-31] [Dev] Implement **Reminders v2 — milestone customization** (Dv1–Dv7): tạo model `milestone_reminder.dart` + màn `milestone_reminders_screen.dart`; restructure `reminder_service`/`reminder_provider` (bỏ daily nudge, schedule từng mốc bật đúng ngày, id 1001–1099); profile rename toggle + tile mốc (badge + dim khi off) + gate force-open custom; ARB vi+en + gen-l10n. `flutter analyze` sạch. Trạng thái → chờ test.
