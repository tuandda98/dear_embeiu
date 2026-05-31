# 🧪 Test — Custom reminders

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** PASS (kèm 2 ghi chú nhỏ + các case cần runtime/thiết bị)
- **Người/role:** Master Tester

## Phạm vi test
Feature **custom-reminders** (D1–D9): model `CustomReminder` + codec, `CustomRemindersProvider` (CRUD, cap 20, allocate id, schedule/cancel, sort), `ReminderService` phần custom (`scheduleCustom`/`cancelCustom`/`nextFireFor`/`_clampedDate`/`_daysInMonth`/`_matchComponentsFor`), cold-start `main.dart` (D7 gate), điểm vào + `handleToggle` ở `profile_screen.dart`, 2 screen mới, ARB vi/en. Test 3 trục logic / edge / security, bám 12 acceptance criteria.

## Kết quả công cụ
- `flutter analyze` → **No issues found!** (4.7s) ✅
- `flutter test` → **8 pass / 1 fail**. Fail duy nhất = `test/widget_test.dart` "renders login screen scaffold" — **fail SẴN ở HEAD** (test không wire localization delegate, tìm "Đăng nhập để tiếp tục" không ra). KHÔNG do feature này, ngoài scope → không tính vào verdict.

## Test case
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Tạo reminder once tương lai | `add` → reminder mới, schedule 1 lần (matchComponents=null), persist Hive | ✅ [VERIFIED in code] |
| 2 | happy | recurrence daily → `nextFireFor` | hôm nay h:m nếu còn tương lai, else +1 ngày; matcher `DateTimeComponents.time` | ✅ [VERIFIED] |
| 3 | happy | weekly → đúng thứ của anchor | delta = (targetWeekday - now.weekday)%7, nếu lệch 0 mà giờ đã qua thì +7 ngày; matcher `dayOfWeekAndTime` | ✅ [VERIFIED] |
| 4 | happy | monthly → ngày anchor, chu kỳ kế nếu đã qua | `_clampedDate(year,month,day)`; sang tháng sau khi đã qua; matcher `dayOfMonthAndTime` | ✅ [VERIFIED] |
| 5 | happy | yearly → ngày/tháng anchor, sang năm sau nếu đã qua | `_clampedDate(year,month,day)`; matcher `dateAndTime` | ✅ [VERIFIED] |
| 6 | edge D8 | monthly day 31 ở tháng 30/28 ngày | `_daysInMonth` đúng (dùng 0th của tháng kế); clamp 31→30/28, không crash | ✅ [VERIFIED] first-fire — xem GHI CHÚ 1 cho chu kỳ sau |
| 7 | edge D8 | yearly 29/02 ở năm thường | `_daysInMonth(year,2)` = 28 → clamp 29→28, không crash | ✅ [VERIFIED] first-fire — xem GHI CHÚ 1 |
| 8 | negative | once trong quá khứ | `nextFireFor`=null → `scheduleCustom` cancel + return false; list hiện "Đã tắt"; form chặn Lưu + warning | ✅ [VERIFIED] |
| 9 | edge | cap 20 (D5) | `isAtCapacity` true khi len≥20; `add` trả null; FAB mờ .45 + snackbar limit; không mở form | ✅ [VERIFIED] |
| 10 | edge | allocate id (D6) | id nhỏ nhất chưa dùng trong 2000–2999, không trùng; tách hẳn dải 1001–1005 | ✅ [VERIFIED] |
| 11 | happy | update (giữ id) | cancel id cũ + reschedule cùng id (nếu enabled); persist; sửa time/recurrence có hiệu lực | ✅ [VERIFIED] |
| 12 | happy | toggle off→cancel / on→schedule | `cancelCustom` khi off, `_schedule` khi on; persist enabled | ✅ [VERIFIED] |
| 13 | happy | delete | xoá khỏi list + `cancelCustom` + `box.delete(id)`; dialog xác nhận; snackbar | ✅ [VERIFIED] |
| 14 | D7 toggle | tắt master ở profile → `cancelAllSchedules`; bật lại (granted) → `rescheduleAllEnabled` | `handleToggle`: value&&granted→reschedule; !value→cancelAll | ✅ [VERIFIED] |
| 15 | D7 cold-start | `main.dart` chỉ reschedule khi `_readMasterRemindersEnabled()` true, else cancelAll | đọc box `reminder_settings` key `enabled` default false; load() trước | ✅ [VERIFIED] |
| 16 | D7 list | master off → state Disabled, FAB ẩn, không thêm | `showFab = remindersEnabled && reminders.isNotEmpty`; body → `_DisabledState`; list cũ dimmed .55 read-only | ✅ [VERIFIED] |
| 17 | cold start | toMap/fromMap round-trip | id/recurrence(storageKey)/dateMillis/hour/minute/note(null↔empty)/enabled khôi phục đúng; load filter `whereType<Map>` | ✅ [VERIFIED] |
| 18 | i18n | 48 key `customReminders*` đủ ở EN+VI, không lệch | EN 48 / VI 48, diff rỗng; placeholder khai báo đúng (count int, day int, date/time/weekday/dayMonth/name String) | ✅ [VERIFIED] |
| 19 | i18n | không hardcode chuỗi 2 screen | mọi text qua `l10n.customReminders*` | ✅ [VERIFIED] |
| 20 | i18n | notif body fallback D4/D9c | note trống/null → `customRemindersNotifBodyFallback` | ✅ [VERIFIED] |
| 21 | regression | 4 reminder tự động (1001–1005) | `cancelAll()` chỉ đụng 1001–1005; custom dùng `cancelCustom(id)` band 2000+; không chồng | ✅ [VERIFIED] |
| 22 | sort | list xếp theo next-fire, past-once chìm xuống | `reminders` getter sort theo `nextFireFor`, null về cuối | ✅ [VERIFIED] |
| 23 | runtime | notification thật bắn đúng title/body/time | cần thiết bị | ⏳ [CẦN TEST runtime] |
| 24 | runtime | recurrence OS lặp đúng chu kỳ qua nhiều tháng (clamp) | hành vi `matchDateTimeComponents` theo nền tảng | ⏳ [CẦN TEST runtime] — xem GHI CHÚ 1 |
| 25 | runtime | DST / đổi múi giờ | kế thừa nợ nền tảng, ngoài scope feature | ⏳ [CẦN TEST runtime] |
| 26 | runtime | iOS 64 pending limit (4 auto + ≤20 custom = 24 < 64) | cap 20 an toàn nhưng cần verify tổng pending | ⏳ [CẦN TEST runtime] |

*(✅ pass · ❌ fail · ⏳ cần runtime)*

## Ghi chú (không phải bug — giới hạn đã biết / chấp nhận được)

### GHI CHÚ 1 — Clamp D8 chỉ nhất quán ở first-fire, KHÔNG re-clamp mỗi chu kỳ (đã được Designer/PO lường trước)
- **Cơ chế:** `nextFireFor` clamp đúng cho lần bắn ĐẦU tiên. Nhưng OS lặp bằng `matchDateTimeComponents` (`dayOfMonthAndTime` cho monthly), chốt day-of-month = day của **first-fire** đã clamp.
- **Hệ quả:** reminder "ngày 31" mà first-fire rơi vào tháng 30 ngày (clamp→30) → OS khoá ngày 30 cho **mọi tháng sau**, kể cả tháng 31 ngày sẽ bắn ngày 30 (không phải 31). Tương tự yearly 29/02 nếu first-fire là năm thường (→28/02) thì các năm sau bắn 28/02 kể cả năm nhuận.
- **Đánh giá:** ĐÚNG như cảnh báo ở `overview.md` mục 7 + `design.md`. KHÔNG bỏ chu kỳ, KHÔNG crash → thoả D8 ("clamp về ngày hợp lệ, không skip im lặng"). App không re-arm mỗi lần bắn nên không thể tự sửa drift này — đây là giới hạn nền tảng, chấp nhận cho MVP. Verify số ngày bằng runtime nhiều tháng (case #24).

### GHI CHÚ 2 — Form mới mặc định cảnh báo "ngày đã qua" ngay khi mở (minor UX)
- **Vị trí:** `custom_reminder_form_screen.dart:43-47, 70-82`. Form THÊM khởi tạo `_date=DateTime.now()`, `_time=TimeOfDay.now()`, recurrence mặc định `once`.
- **Hành vi:** `_isPastOnce` dựng `DateTime(today, now.hour, now.minute)` (bỏ giây) → luôn `<= DateTime.now()` → cảnh báo vàng "Ngày đã qua rồi" hiện NGAY + nút Lưu disable trên form trống mới mở.
- **Đánh giá:** KHÔNG sai logic (once + thời điểm hiện tại/quá khứ thì đúng là không nên schedule), nhưng trải nghiệm hơi nhụt: user mở form lần đầu đã thấy cảnh báo đỏ/vàng dù chưa làm gì. User chỉ cần đẩy giờ/ngày lên tương lai là hết. Severity **minor**, không chặn release. Để PO quyết có muốn polish (vd default time = now+1h, hoặc chỉ hiện warning sau khi user chạm field) — KHÔNG bắt buộc cho acceptance.

## Đối chiếu acceptance criteria (overview mục 5)
- [x] Tạo reminder (tên+note+ngày+giờ+kiểu lặp) — VERIFIED
- [x] List hiển thị tên/next-fire/nhãn lặp/toggle — VERIFIED
- [x] Sửa + xoá (có dialog xác nhận) — VERIFIED
- [x] Toggle reschedule/cancel không chồng/sót — VERIFIED
- [x] 5 kiểu lặp schedule đúng (matcher + nextFire) — VERIFIED (#1–5)
- [x] Edge 31 / 29-02 clamp, không crash, không bỏ chu kỳ — VERIFIED first-fire (GHI CHÚ 1 cho chu kỳ sau)
- [x] once quá khứ → không schedule, không crash — VERIFIED
- [x] Cap 20 → chặn + thông báo — VERIFIED
- [x] Notification title=tên, body=note, fallback nếu trống — VERIFIED (body runtime cần #23)
- [x] UI vi+en đầy đủ, không vỡ — VERIFIED (48/48 key parity)
- [x] Persist cold start + khôi phục schedule — VERIFIED (D7 gate đúng)
- [x] D7: chưa cấp quyền → UI hướng dẫn, không im lặng fail — VERIFIED
- [x] `flutter analyze` sạch, không hardcode — VERIFIED
- [x] 4 reminder tự động không regression — VERIFIED

## Verdict
**PASS.** 22/22 case tĩnh VERIFIED in code đạt; 4 case (#23–26) ⏳ cần runtime/thiết bị (notification thật, recurrence OS nhiều chu kỳ, DST, iOS pending limit) — đúng bản chất local notification, không thể verify hết bằng đọc code. KHÔNG có bug critical/major. 2 ghi chú: (1) giới hạn clamp-chu-kỳ-sau của `matchDateTimeComponents` — đã được spec lường trước, chấp nhận MVP; (2) minor UX cảnh báo ngày-quá-khứ hiện ngay trên form mới — để PO quyết polish, không chặn.

## Nhật ký test
- [2026-05-31] [Tester] Test toàn bộ feature custom-reminders (model/provider/service/cold-start/profile/2 screen/ARB). `flutter analyze` sạch; `flutter test` 8 pass /1 fail (fail là widget_test.dart pre-existing ở HEAD, ngoài scope). Verify 22 case tĩnh ✅, 4 case ⏳ cần runtime. Phát hiện 2 ghi chú không-chặn: clamp D8 không re-clamp chu kỳ sau (giới hạn matchDateTimeComponents, đã lường trước); form mới cảnh báo ngày-quá-khứ ngay (minor UX). Verdict: **PASS**.
