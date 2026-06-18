# Lịch âm + Nhắc mồng 1 / rằm — dev log

## [2026-06-19] [dev] v2 — Cho chỉnh giờ/ngày + màn lịch âm grid đầy đủ
- **Chỉnh được:** ngày âm nhắc (tập con 1..30, mặc định {1,15}) + giờ nhắc (list ≤6, mặc định 7/8/9). Bỏ hằng cứng `_lunarHours`.
  - `LunarCalendar.nextLunarDays(from, Set<int> days, count)` (tổng quát); `nextOneAndFifteen` giờ delegate nó.
  - `ReminderProvider`: state `_lunarTimes`(minutes)/`_lunarDays`(1..30) + getters `lunarTimes`/`lunarDays`/`canAddLunarTime`; persist keys `lunar_reminder_times`/`lunar_reminder_days`; `_normalizeLunarTimes`(sort/dedup/clamp/cap6)/`_normalizeLunarDays`(1..30); setters `setLunarTimes`/`setLunarDays`; `refreshLunar` build copy theo ngày (1→mồng-một, 15→rằm, khác→`lunarOtherDayNotif*({day})`), **cap tổng ≤24 one-shot** (iOS 64 pending), window 8. Band service `_idLunarBase 1060.._maxLunar 40`.
- **Màn mới `lib/screens/lunar_calendar_screen.dart`:** grid tháng (GridView 7 cột, mỗi ô dương to + âm nhỏ, mồng-1 hiện "1/<tháng âm>", hôm nay ring rose, ngày-nhắc nhuỵ đậm), nav prev/next tháng (`DateFormat.yMMMM`), header tuần `DateFormat.E` Monday-first. Config card: toggle + Wrap 30 chip ngày (chạm toggle `setLunarDays`) + chip giờ (chạm sửa / X xoá / "Thêm giờ" qua `showAppTimePicker`, `setLunarTimes`).
- **Settings card:** thêm `_navRow` "Mở lịch âm" → push `LunarCalendarScreen`. Toggle subtitle đổi generic ("Vào ngày & giờ bạn chọn") vì giờ không cứng 7/8/9 nữa.
- **l10n +7 key** (en+vi): `lunarOtherDayNotifTitle/Body({day})`, `lunarCalendarBadge`, `lunarOpenCalendar`, `lunarRemindDaysLabel`, `lunarRemindTimesLabel`, `lunarAddTime`; sửa text `lunarReminderToggle`/`Sub`. gen-l10n OK.
- **Verify:** full `flutter analyze` sạch · 7 test âm lịch pass. CHƯA smoke-test runtime. CHƯA commit.

## [2026-06-19] [dev] Implement full (account-gated)

### File MỚI
| File | Nội dung |
|---|---|
| `lib/utils/lunar_calendar.dart` | Thuật toán âm lịch VN (Hồ Ngọc Đức, UTC+7), thuần Dart. `LunarDate fromSolar(DateTime)`, `String canChiYear(int)`, `List<LunarEvent> nextOneAndFifteen(from, count)` (typedef `LunarEvent = ({DateTime date, bool isFirstDay})` — iterate ≤420 ngày). Private: `_jdFromDate/_getNewMoonDay/_getSunLongitude/_getLunarMonth11/_getLeapMonthOffset/_convertSolar2Lunar`. |
| `test/lunar_calendar_test.dart` | 7 test verify ngày đã biết (Tết Giáp Thìn 10/2/2024=1/1 · Đoan Ngọ 10/6/2024=5/5 · Trung Thu 17/9/2024=15/8 · Tết Ất Tỵ 29/1/2025=1/1 · canChiYear · nextOneAndFifteen flags). **PASS 7/7.** |

### File SỬA
| File | Thay đổi |
|---|---|
| `lib/services/reminder_service.dart` | Band lunar `_idLunarBase=1060`, `_maxLunar=40` (ngoài `_autoIds`). `scheduleLunarReminders(List<({DateTime when,String title,String body})>)` — cancel band trước, schedule one-shot từng item nếu `when.isAfter(now)`. `cancelLunar()`. Dùng lại `_scheduleAt`. |
| `lib/providers/reminder_provider.dart` | Key `_lunarEnabledKey='lunar_reminder_enabled'`, `_lunarHours=[7,8,9]`, `_lunarWindow=6`. State `_lunarEnabled`+getter `lunarEnabled`. `load()` đọc flag. `_persistLunar()`. `setLunarEnabled(bool,{l10n})`. `refreshLunar(l10n)` — build items (next 6 mồng1/rằm × 3 giờ, copy theo isFirstDay) → `scheduleLunarReminders`; self-gate (cancel khi off/l10n null). Hook `refreshLunar(l10n)` ở cuối `sync()` (top-up mỗi app open). import `lunar_calendar.dart`. |
| `lib/screens/settings_screen.dart` | Set `_lunarCalendarEmails={dodaoanhtuan@gmail.com}`; `showLunar` trong build; chèn `_buildLunarSection` (gated) sau Notifications. Section = ContentCard: hàng info (IconBadge moon + "Hôm nay: <ngày âm> · <can-chi>" + "Mồng 1 tới / Ngày rằm tới: d/M") + divider + `SwitchListTile.adaptive` bind `ReminderProvider.lunarEnabled`/`setLunarEnabled`. import `lunar_calendar.dart`. |
| `lib/l10n/app_en.arb` + `app_vi.arb` | +12 key: `lunarSectionTitle`, `lunarDateLabel({month}{day})`, `lunarTodayLabel`, `lunarNextNewMoon`, `lunarNextFullMoon`, `lunarReminderToggle`, `lunarReminderToggleSub`, `lunarNewMoonNotifTitle/Body`, `lunarFullMoonNotifTitle/Body`. gen-l10n OK. |

### Verify
- `flutter analyze` (cả project): sạch (chỉ 1 lint **pre-existing** `mood.dart` dangling doc — không liên quan).
- `flutter test test/lunar_calendar_test.dart`: **7 pass**.
- ⏳ CHƯA smoke-test runtime (bật toggle account dodaoanhtuan → kiểm OS scheduled notifications mồng1/rằm 7/8/9h). CHƯA commit. Thuần local, không backend.

### Lưu ý / nợ
- iOS cap 64 pending: lunar 18 + milestones ~8 + dailyQ ≤10 + EOD ≤3 + custom ≤20 → worst ~59. OK nhưng sát; window giữ nhỏ + top-up mỗi app open.
- Flag Hive drive scheduling kể cả account khác trên cùng máy (UI ẩn) — chấp nhận; muốn chặt thì gate scheduling theo email luôn.
