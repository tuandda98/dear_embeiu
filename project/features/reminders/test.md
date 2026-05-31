# 🧪 Test — Reminders

> Tester sở hữu. CHỈ test, KHÔNG sửa code.

- **Trạng thái test:** ⬜ Baseline chưa test có hệ thống · ✅ **v2 (milestone customization) — PASS (2026-05-31)**

## Test case ưu tiên
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Bật reminders + chọn giờ | Daily nudge đúng giờ | ⬜ |
| 2 | happy | Tới ngày kỷ niệm | Nhận anniversary reminder | ⬜ |
| 3 | edge | Từ chối quyền rồi bật | Có thông báo/nút mở settings (hiện im lặng) | ⬜ |
| 4 | edge | Bật quyền lại trong OS settings | Reminders hoạt động | ⬜ |
| 5 | edge | Đổi anniversary | Reschedule milestone đúng | ⬜ |
| 6 | edge | 7 ngày không đăng ảnh | Inactivity nudge | ⬜ |
| 7 | edge | Milestone (mỗi 100 ngày) + nudge trước 3 ngày | Đúng id, không chồng | ⬜ |
| 8 | edge | Đổi timezone máy rồi restart | Giờ không lệch | ⬜ |
| 9 | i18n | Đổi EN | Nội dung reminder tiếng Anh (đã localize) | ⬜ |
| 10 | negative | setTime giờ/phút ngoài range | Bound-check | ⬜ |

## Test Reminders v2 — Milestone customization (2026-05-31)

> Phạm vi: 7 mốc tự bật/tắt, bỏ daily nudge, force-open gate, không regression custom v1. Bám **acceptance v2** (overview mục 5b) + 10 trục PO giao.
> Toolchain: `flutter analyze` → **No issues found!** (sạch). `flutter test` → 8 pass / 1 fail = **`renders login screen scaffold` fail SẴN ở HEAD** (thiếu localization delegate, không do feature này) → KHÔNG tính verdict. Không có test mới cho v2 (đúng ranh giới Tester).
> Ký hiệu: ✅ pass · ⏳ cần test runtime (notification thật / DST / iOS pending-limit).

### Bảng test case

| # | Trục | Loại | Mô tả | Kỳ vọng | KQ |
|---|------|------|-------|---------|----|
| V1 | Dv1 | happy | Bỏ daily nudge | Không còn `scheduleDaily`/`_nextInstanceOfTime`/`scheduleMilestoneToday`/`Approaching` trong `lib/` (grep = none). Const `_idLegacyDaily=1001` chỉ nằm trong `_autoIds` để `cancelAll` dọn legacy | ✅ [VERIFIED] |
| V2 | Dv4 | happy | Mặc định 7 mốc | `kMilestoneDefaults`: every100/d1000/halfYear/yearly/inactivity=true; d520/d1314=false (model:79-87). `kMilestoneOrder` đúng thứ tự every100→d520→d1000→d1314→halfYear→yearly→inactivity (model:68-76) | ✅ [VERIFIED] |
| V3 | Dv5 | happy | every100 = mốc 100 kế | `((daysTogether~/100)+1)*100` ngày kể từ anniversary (provider:287,403). Day 250 → next 300; day chẵn 100 → next 200 (mốc hôm nay coi như đã qua, recurring nên đúng) | ✅ [VERIFIED] |
| V4 | Dv5 | happy | d520/1000/1314 chưa tới | anniversary+N; `date.isAfter(today)` → schedule + label N ngày (provider:292-300, 408-410) | ✅ [VERIFIED] |
| V5 | Dv5 | edge | d520/1000/1314 đã qua | `!date.isAfter(today)` → KHÔNG schedule (provider:413), UI `passed` (provider:297) → tile "Đã qua" opacity .6 | ✅ [VERIFIED] |
| V6 | Dv5 | edge | halfYear clamp ngày | `_addMonthsClamped(start,6)`: 31/8+6→28/2 (năm thường) qua `_clampDay`/`_daysInMonth` (provider:439-455). Đã qua → không schedule | ✅ [VERIFIED] |
| V7 | Dv5 | happy | yearly recurring + clamp Feb29 | `scheduleAnniversary` id 1002 `DateTimeComponents.dateAndTime`; `_nextAnniversary` lùi sang năm sau nếu đã qua (service:431-452). next-fire `_nextAnniversaryDate` clamp 29/2→28/2 (provider:429-435) | ✅ [VERIFIED] · recurrence qua nhiều năm ⏳ runtime |
| V8 | Dv5 | happy | inactivity 7 ngày | reference = lastPhotoDate ?? now; +7 ngày; nếu đã qua → today+7 (provider:368-385); id 1005 | ✅ [VERIFIED] |
| V9 | edge | edge | anniversary tương lai (daysTogether<0) | mốc đếm-ngày/halfYear: `if (daysTogether<0) return` KHÔNG schedule, KHÔNG crash (provider:394). UI `pending` "Sẽ tính khi tới ngày kỷ niệm" (provider:280). inactivity vẫn chạy. yearly vẫn schedule (anniversary tương lai → _nextAnniversary trả ngày tương lai hợp lệ) | ✅ [VERIFIED] |
| V10 | toggle | happy | Bật 1 mốc | `toggleMilestone(t,true)` → persist `milestone_<name>` + `_scheduleMilestone` đúng id (provider:219-241) | ✅ [VERIFIED] |
| V11 | toggle | happy | Tắt 1 mốc | persist false + `_service.cancelMilestone(t)` cancel đúng id (provider:235, service:169-178) | ✅ [VERIFIED] |
| V12 | toggle | edge | Toggle khi `_lastAnniversary` null (chưa sync) | persist nhưng KHÔNG schedule (provider:226 guard `anniversary!=null && l10n!=null`) → fallback an toàn, không crash | ✅ [VERIFIED] |
| V13 | id | happy | id mapping không trùng | 1002/1003/1005/1006/1010/1011/1012 phân biệt; `_idForMilestone` map đúng 7 mốc (service:180-197); custom 2000-2999 không đụng | ✅ [VERIFIED] |
| V14 | id | happy | cancelAll phủ hết | `_autoIds` gồm cả 1001 legacy + 7 id auto (service:44-53) | ✅ [VERIFIED] |
| V15 | UI | happy | next-fire thuần | `nextFireForMilestone` không gọi schedule, gọi an toàn trong build (provider:266); `_MilestoneTile` dùng `provider.nextFireForMilestone` + `context.select` cho enabled (screen:88-93) | ✅ [VERIFIED] |
| V16 | UI | edge | inactivity → mô tả tĩnh | sub-line = `milestoneInactivitySub`, không "Sắp tới" (screen:177-186; provider trả pending cho inactivity) | ✅ [VERIFIED] |
| V17 | UI | edge | next-fire phụ thuộc `_lastAnniversary` | `_lastAnniversary` nạp ở `sync()` cả khi master OFF (provider:251-255) + reschedule. Home sync `_syncReminders` chạy postFrame (home:80-91). ⚠️ Nếu user vào màn mốc TRƯỚC khi Home tab render lần đầu (deep nav) → `_lastAnniversary` null → tất cả "pending" tạm thời. Thực tế phải qua Home/Profile (đều thuộc HomeScreen IndexedStack) nên sync đã chạy → không sai. Profile dùng `couple.anniversaryDate` truyền vào setEnabled/sync nên luôn có | ✅ [VERIFIED] · ⏳ xác nhận runtime thứ tự render |
| V18 | force-open | happy | master ON tap custom | push thẳng `CustomRemindersScreen` (profile:851-857) | ✅ [VERIFIED] |
| V19 | force-open | happy | master OFF tap custom → "Bật" granted | `_showForceOpenDialog` → setEnabled(true) → granted: đóng dialog + `rescheduleAllEnabled()` + push custom (profile:1041-1056) | ✅ [VERIFIED] · ⏳ quyền OS thật |
| V20 | force-open | edge | "Bật" denied | đóng dialog + snackbar `remindersV2ForceOpenDeniedMsg` (profile:1057-1064); master vẫn off | ✅ [VERIFIED] |
| V21 | force-open | happy | "Để sau" | `Navigator.pop(dialogContext)`, master off (profile:1019-1027) | ✅ [VERIFIED] |
| V22 | force-open | edge | tile mốc dim+không tap khi master off | `AnimatedOpacity` .45 200ms + `onTap: null` khi `!settings.enabled` (profile:746-759) | ✅ [VERIFIED] |
| V23 | cold-start | happy | mốc persist qua restart | `load()` đọc `milestone_<name>` từ Hive, override default (provider:115-133) | ✅ [VERIFIED] |
| V24 | cold-start | edge | master OFF không re-arm custom | main.dart `_readMasterRemindersEnabled` false → `cancelAllSchedules()` (main:67-71). Auto reminders chỉ re-arm khi `sync()` (master on) | ✅ [VERIFIED] |
| V25 | i18n | happy | parity EN+VI | 33/33 key `remindersV2*`+`milestone*` có cả EN+VI (grep =1/1 mỗi key). 2 key cũ `remindersToggleLabel/Desc` đổi value đúng (EN "Milestone & anniversary reminders" / VI "Nhắc cột mốc & kỷ niệm") | ✅ [VERIFIED] |
| V26 | i18n | happy | placeholder khai báo | `{count}` type int (CountBadge/Days/Years), `{date}`/`{label}` String (Next/NextWithLabel) khai báo @-meta đầy đủ; gen-l10n OK | ✅ [VERIFIED] |
| V27 | i18n | edge | không hardcode màn mốc + dialog | mọi chuỗi qua `l10n.*` (screen + _showForceOpenDialog); icon/màu/radius từ AppColors | ✅ [VERIFIED] |
| V28 | regression | happy | custom v1 nguyên vẹn | `scheduleCustom`/`cancelCustom`/`nextFireFor`/`_clampedDate` id 2000-2999 GIỮ NGUYÊN (service:261-404). Chỉ đổi gate vào màn (force-open) | ✅ [VERIFIED] |
| V29 | regression | happy | gate đổi force-open, không state disabled cũ gây lỗi | tile custom luôn tap được (không dim); master off → dialog thay vì state passive | ✅ [VERIFIED] |
| V30 | edge | edge | mốc landing đúng HÔM NAY | `!date.isAfter(today)` (today=date-only) → coi như đã-qua, KHÔNG schedule + UI "Đã qua". **Nhất quán** giữa `_scheduleMilestone` (provider:413) và `nextFireForMilestone` (provider:297) → không lệch UI/schedule. *Minor:* mốc rơi đúng hôm nay sẽ không bắn dù giờ nhắc chưa tới — chấp nhận được (one-shot, biên hiếm) | ✅ [VERIFIED] minor |

### Quan sát (không phải bug — ghi nhận)
- **Boundary "hôm nay" = đã qua (V30):** mốc one-shot/halfYear/d-count rơi ĐÚNG ngày hôm nay không được schedule (`isAfter` loại bằng). Nhất quán schedule↔UI nên không gây mâu thuẫn hiển thị. Đánh đổi biên rất hiếm, không chặn release. Nếu PO muốn "nhắc cả hôm nay nếu giờ chưa tới" → cần đổi sang so sánh theo thời điểm (date+hour) — đề xuất backlog, KHÔNG phải lỗi acceptance (overview ghi rõ "đã qua thì không").
- **next-fire phụ thuộc `_lastAnniversary` (V17):** nạp qua `sync()` (cả khi master off). Vì màn mốc chỉ vào được từ Profile (cùng HomeScreen IndexedStack với Home tab đã chạy `_syncReminders`), `_lastAnniversary` luôn có giá trị trước khi mở → không rơi "pending" sai. [VERIFIED in code]; nên xác nhận runtime thứ tự render lần đầu.
- **yearly khi anniversary tương lai vẫn schedule (V9):** đúng — `scheduleAnniversary` dùng ngày/tháng calendar, `_nextAnniversary` trả lần kỷ niệm calendar kế tiếp (hợp lệ kể cả anniversary đặt tương lai). Mốc đếm-ngày/halfYear mới skip. Không mâu thuẫn acceptance ("daysTogether<0 → không nhắc" chủ yếu nhắm mốc đếm-ngày).

### Cần test runtime (ngoài tầm đọc-code)
- ⏳ Notification thật bắn đúng ngày/giờ trên Android (inexactAllowWhileIdle) + iOS.
- ⏳ yearly recurrence qua nhiều chu kỳ năm; DST/đổi timezone rồi restart (rủi ro baseline cũ, không phải v2).
- ⏳ iOS pending notification limit (64) — v2 tối đa ~7 auto + custom, an toàn dư.
- ⏳ Quyền OS thật trong force-open (granted/denied) trên thiết bị.

### Verdict v2
**PASS** — 30/30 case ✅ trong code (5 case kèm hậu-tố ⏳ cần xác nhận runtime, không chặn). 0 bug. `flutter analyze` sạch. ARB parity 33/33 + 2 key cũ đổi value đúng. Daily nudge đã bỏ hoàn toàn (Dv1). Schedule 7 mốc đúng ngày (Dv4/Dv5), id 1001–1099 không trùng/không đụng custom 2000–2999. Force-open (Dv6) đầy đủ granted/denied/để-sau. Persist cold-start + master gate đúng. Không regression custom v1. 1 quan sát biên (mốc rơi đúng hôm nay không bắn) là đánh đổi chấp nhận được, đúng acceptance — đề xuất backlog cho PO cân nhắc.

## Nhật ký test
- [2026-05-30] [PO] Tạo bộ case từ catalog logic; chờ Tester chạy.
- [2026-05-31] [Tester] Test **Reminders v2 — milestone customization**: 30 case (happy/edge/negative/i18n/force-open/cold-start/regression) → **PASS 30/30** (5 case kèm ⏳ runtime). `flutter analyze` sạch; `flutter test` 8 pass / 1 fail (login-scaffold fail SẴN ở HEAD, không do feature). ARB parity 33/33 + 2 key cũ đổi value đúng. 0 bug. Ghi nhận 1 quan sát biên (mốc rơi đúng hôm nay coi như đã-qua, nhất quán schedule↔UI) — đề xuất backlog, không chặn release.
