# 💻 Dev — Daily Question (Câu hỏi mỗi ngày, #5)

> Dev sở hữu. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2). Mẫu: love-note (#4).

- **Trạng thái dev:** xong — chờ test (chưa deploy rules/functions; PO deploy sau)
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Mô hình:* mỗi ngày 1 câu hỏi chung cho cả 2 (chọn theo day-of-year mod length → cùng ngày = cùng câu). Mỗi người trả lời 1 doc. Reveal câu của partner **chỉ sau khi bạn đã trả lời** — enforce ở provider (`hasRevealed`), rules cho member đọc cả 2 (reveal là UI affordance, chấp nhận v1). Ngày = giờ máy local (LDR lệch múi giờ — chấp nhận v1). KHÔNG streak v1.
- *Firestore:* `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}` = `{authorUserId, text, answeredAt}`. ≤2 doc/ngày.
- *File tạo:*
  - `lib/data/daily_questions.dart` — bank **229** câu vi/en + `questionForCouple`/`questionTextForCouple` (no-repeat theo couple, seed FNV-1a + permutation, `daysSinceEpoch % N`). Hàm cũ `questionForDate`/`questionTextForDate` (dayOfYear mod length) còn lại nhưng `@Deprecated`.
  - `lib/models/daily_answer.dart` — model + fromDoc/toMap.
  - `lib/services/daily_question_service.dart` — `dateKey`, `watchResponses`, `submitAnswer`; local-fallback Hive box `daily_answers_local` (no-crash).
  - `lib/providers/daily_question_provider.dart` — `watchForCouple/todayQuestion/myAnswer/partnerAnswer/hasRevealed/isLoading/submit`; tự resubscribe khi đổi ngày (rollover) + sau submit ở fallback (stream là one-shot).
- *File sửa:*
  - `lib/main.dart` — đăng ký `DailyQuestionProvider`.
  - `lib/app/session_resolver.dart` — wire watch khi couple active / clear khi sign-out/no-couple.
  - `lib/screens/home_screen.dart` — card `_buildDailyQuestionCard` + widget `_DailyQuestionCard` (đặt **ngay sau** card Lời nhắn #4, `_entrance(6, …)`); re-arm watch trong build như love-note. Import `confetti`.
  - `lib/services/push_notification_service.dart` — `_handleNotificationTap`: `'daily_question'`→home tab 0.
  - `firestore.rules` — khối ADDITIVE `dailyAnswers/{date}/responses/{uid}` cạnh `notes` (read: member; write: own uid + authorUserId==uid + text string ≤280).
  - `functions/index.js` — `exports.notifyDailyAnswer` (onDocumentCreated) gửi FCM cho partner (copy vi/en `DAILY_QUESTION_COPY`, data `{type:'daily_question', coupleId}`); `deleteCoupleCompletely` thêm `db.recursiveDelete(coupleRef.collection('dailyAnswers'))`.
  - ARB en/vi: 10 key `dailyQuestion*` + `flutter gen-l10n`.
- *Cần deploy?* **rules + functions** (PO deploy). Nếu chưa deploy: client write bị rules cũ chặn (subcollection mới) → an toàn vì local-fallback không crash; push không gửi.

## Edge case kỹ thuật đã xử lý
- Local-fallback (`!isUsingFirebase`): Hive lưu chỉ answer của máy này; service không crash; provider resubscribe sau submit để UI cập nhật ngay.
- Day rollover khi app mở: `watchForCouple` so cả `dateKey` → resubscribe sang câu mới.
- Confetti **bắn đúng 1 lần**: flag `_confettiPlayed` init = `provider.hasRevealed` (mở lại Home đã reveal → KHÔNG bắn), chỉ bắn ở transition fresh reveal; key card theo couple+question để reset state đúng.
- Clamp text 280 cả client (service) + rules. Trim rỗng → submit no-op.
- `waiting_partner` (chưa có partner): vẫn cho trả lời, ghi chú "sẽ mở khoá khi người ấy tham gia & trả lời", không lỗi.
- recursiveDelete dọn subcollection lồng + phantom doc khi xoá hẳn couple (deleteAccount/leave sole-member).

## Checklist implement
- [x] Bank 58 câu vi/en + chọn theo day-of-year
- [x] Model + service (local-fallback) + provider
- [x] Đăng ký provider main.dart + wire session_resolver
- [x] Card Home sau card Lời nhắn (#5), 3 trạng thái + confetti 1 lần
- [x] Rules ADDITIVE dailyAnswers
- [x] CF notifyDailyAnswer + recursiveDelete trong deleteCoupleCompletely
- [x] Deep-link `daily_question`→home0
- [x] 10 key l10n vi+en + gen-l10n
- [x] `node --check functions/index.js` pass
- [x] `flutter analyze` sạch (No issues found!)
- [x] Không hardcode chuỗi (qua l10n)

## Nhật ký implement
- [2026-06-14] [lead+dev] **Bỏ dòng tiêu đề "Câu hỏi hôm nay" trong card** (user kèm ảnh: "bỏ title vẫn giữ card"). `today_ritual_card.dart` `_buildQuestionSection`: xoá `Row[Icon(heartHandshake rose) + Text(l10n.dailyQuestionLabel w800/16)]` + `SizedBox(10)` ⇒ card vào thẳng câu hỏi (serif 21) → ô "Chạm để trả lời". Chỉ UI; feature/journal/streak/reminder/l10n `dailyQuestionLabel` (giữ key) không đụng. analyze 0 issue.
- [2026-06-02] [Dev] Implement full-stack #5 Daily Question (mẫu love-note). Tạo `data/daily_questions.dart` (58 câu), `models/daily_answer.dart`, `services/daily_question_service.dart` (Firestore `dailyAnswers/{date}/responses/{uid}` + Hive fallback), `providers/daily_question_provider.dart` (reveal gate `hasRevealed`, resubscribe rollover+fallback). Wire main.dart + session_resolver. Card Home `_DailyQuestionCard` đặt sau Lời nhắn: input ≤280 + đếm ký tự + Gửi (haptic), trạng thái "đã trả lời/chờ", reveal 2 câu có nhãn + confetti 1 lần (flag init=hasRevealed). Rules ADDITIVE. CF `notifyDailyAnswer` + recursiveDelete dailyAnswers khi xoá couple. Deep-link `daily_question`→home0. 10 key l10n vi+en. node --check + analyze sạch. **Chưa deploy** (PO).
- [2026-06-04] [Dev] **Vá nền chọn câu** (no-repeat theo couple + seed ổn định). Mở rộng bank 58→**229** cặp vi/en (giữ 58 cũ verbatim; thêm theo nhóm chủ đề: kỷ niệm, biết ơn, tương lai chung, sở thích/thà-rằng, nếu/tưởng-tượng, thói quen đáng yêu, mơ ước, du lịch, đồ ăn, nhạc/phim, hài hước, "nghĩ gì về…", cảm xúc, chăm sóc, dịp đặc biệt, hồi tưởng…). Thay cơ chế chọn: `questionForCouple(local, coupleId, langCode)` + `questionTextForCouple(...)` — FNV-1a hash(coupleId) seed một permutation Fisher–Yates (LCG) của `[0..N-1]`; `index = perm[daysSinceEpoch(2020-01-01) % N]` (mod dương, chịu được ngày trước epoch). Bỏ `dayOfYear` (tránh nhảy đầu năm/nhuận); chỉ dùng phần ngày (year/month/day). Hệ quả: cùng couple+ngày → cùng câu (2 partner khớp); no-repeat trong N ngày liên tiếp; couple khác nhau order khác nhau; coupleId rỗng/whitespace → seed 0 an toàn. Hàm cũ `questionForDate`/`questionTextForDate` giữ lại, gắn `@Deprecated`. Provider `todayQuestion(langCode)` chuyển sang `questionTextForCouple(now, _coupleId ?? '', langCode)` — **public signature KHÔNG đổi** nên `home_screen.dart` không cần sửa. Thêm test `test/data/daily_questions_test.dart` (14 ca: bank ≥200, vi/en đủ, no-ICU, no-dup, determinism, time-ignore, lang fallback, consecutive khác, no-repeat 1 cycle, wrap đúng N ngày, couple khác diverge, empty/whitespace fallback, pre-epoch). `fvm flutter analyze` = No issues found!; `fvm flutter test test/data/daily_questions_test.dart` = All tests passed (14/14). KHÔNG đụng rules/functions/Firestore — chỉ logic chọn client-side. Chưa deploy/commit.

### Trade-off / giả định (vá nền 2026-06-04)
- *Append câu → lịch DỊCH:* permutation phụ thuộc N (= độ dài bank). Khi thêm/bớt câu sau này, mapping ngày→câu của mọi couple thay đổi (câu hôm nay có thể khác hôm-qua-đã-thấy). Chấp nhận v1: không lưu lịch sử "đã hỏi" theo couple ở Firestore (chi phí thấp, không gây lặp ngay vì cycle dài 229 ngày). Nếu muốn ổn định tuyệt đối khi append, cần khoá N hoặc lưu offset — out of scope.
- *Hai partner khác bank length (app version lệch):* nếu một người chưa cập nhật app (bank cũ 58) còn người kia 229 → khác câu cùng ngày. Cùng version → luôn khớp. Bank là asset bundle theo build, không sync runtime.
- *LDR lệch múi giờ:* giữ nguyên giả định v1 — "ngày" theo lịch local mỗi máy; hai người khác ngày local có thể thấy câu khác. Không đổi so với trước.

## b2 — Nhắc trả lời câu hỏi mỗi ngày (local daily reminder)
- **Trạng thái:** đã implement, sẵn sàng test (thuần local, KHÔNG deploy).
- *Mục tiêu:* cú hích buổi tối kéo cả 2 vào trả lời — local scheduled notification lặp hằng ngày, tái dùng `ReminderService`. Độc lập hoàn toàn với master toggle "Nhắc cột mốc & kỷ niệm".

### File sửa
- `lib/services/reminder_service.dart`:
  - Thêm const `_idDailyQuestion = 1004` (band auto, **KHÔNG** trong `_autoIds` → `cancelAll()` không đụng).
  - `scheduleDailyQuestion({hour, minute, title, body})` — `await initialize()` đầu hàm; `_scheduleAt(... matchDateTimeComponents: DateTimeComponents.time)` để lặp HẰNG NGÀY; helper `_nextDaily(h,m)` (hôm nay nếu chưa qua, không thì mai).
  - `cancelDailyQuestion()` — cancel id 1004, guard `_initialized`, try/catch im lặng.
- `lib/providers/reminder_provider.dart`:
  - State riêng `_dqEnabled`(default **true**)/`_dqHour`(20)/`_dqMinute`(0) + getter `dailyQuestionReminderEnabled`/`dailyQuestionReminderTime`. KHÔNG nhét vào `ReminderSettings` (giữ tách bạch master toggle).
  - Hive keys MỚI trong box `reminder_settings`: `dqReminderEnabled`/`dqReminderHour`/`dqReminderMinute` (không đụng key cũ). Load trong `load()`, persist `_persistDailyQuestion()`.
  - `setDailyQuestionReminderEnabled(bool, {l10n})`: bật → `requestPermissions()`; denied → enabled=false, persist, trả `false`; granted → persist, schedule NẾU `_lastAnniversary != null` (couple active). Tắt → persist + `cancelDailyQuestion()`. Trả `bool`.
  - `setDailyQuestionReminderTime(h, m, {l10n})`: lưu + reschedule nếu enabled & couple active.
  - `cancelDailyQuestionSchedule()` — cancel mà GIỮ pref (để re-arm qua sync).
  - **Wire vào `sync()`:** đầu hàm cache `_lastAnniversary/_lastPhotoDate/_lastL10n` LUÔN (kể cả master off) rồi nếu `_dqEnabled` → `_scheduleDailyQuestion(l10n)`; sau đó mới nhánh milestone (`_reschedule` chỉ khi `settings.enabled`). Vì `_reschedule`→`cancelAll()` chỉ đụng `_autoIds` nên schedule 1004 đã đặt trước đó SỐNG SÓT.
- `lib/app/session_resolver.dart`: import + đọc `ReminderProvider`; gọi `cancelDailyQuestionSchedule()` ở CẢ 2 nhánh không-couple (unauth → guest; authed-no-couple → setup). Pref giữ nguyên để re-arm khi couple active.
- `lib/screens/settings_screen.dart`: thêm widget `_DailyQuestionReminderTile` (switch + time row chỉ enable khi ON, mở `showTimePicker`) đặt NGAY SAU master toggle trong `_buildRemindersSection`. Permission denied → SnackBar `remindersPermissionDeniedMsg` (tái dùng). Icon `LucideIcons.messageCircle`/`clock`, white tile r22, accentRose.
- `lib/l10n/app_en.arb` + `app_vi.arb`: 5 key mới `dailyQuestionReminderTitle`/`Subtitle`/`TimeLabel`/`NotifTitle`/`NotifBody` (vi+en) → `gen-l10n`.

### Vòng đời schedule/cancel
- Schedule: `home_screen.dart:187` `reminderProvider.sync(...)` (couple active) → trong `sync` (reminder_provider.dart, nhánh `if (_dqEnabled)`) gọi `scheduleDailyQuestion`. Cũng schedule ngay khi user bật switch nếu couple đã active.
- Cancel: `session_resolver.dart` 2 nhánh no-couple → `cancelDailyQuestionSchedule()`. Tắt switch → `cancelDailyQuestion()`.
- **Độc lập master toggle:** id 1004 ngoài `_autoIds` ⇒ `cancelAll()` (master off / full reschedule) KHÔNG huỷ. Tắt "Nhắc cột mốc" vẫn nhận nhắc câu hỏi nếu bật riêng. Đã verify bằng đọc `_autoIds` (chỉ 1001,1002,1003,1005,1006,1010,1011,1012).

### Default + persist
- `dqReminderEnabled=true`, `dqReminderHour=20`, `dqReminderMinute=0` (20:00). Persist Hive box `reminder_settings` keys `dq*` (load mặc định true/20/0).

### Verify
- `fvm flutter gen-l10n` OK (getter mới sinh ra trong app_localizations.dart).
- `fvm flutter analyze` → No issues found!
- `fvm flutter test` → 22 pass; **1 fail pre-existing** `test/widget_test.dart` "renders login screen scaffold" (hardcode chuỗi login cũ "Đăng nhập để tiếp tục", copy hiện tại = "Chào mừng trở lại" — KHÔNG liên quan b2, không đụng login).

### v1 limitation / giả định
- Reminder lặp hằng ngày fire BẤT KỂ đã trả lời hay chưa (local scheduled notif không biết trạng thái Firestore). Copy trung tính, shame-free phù hợp cả 2 trường hợp — chấp nhận v1. Muốn "chỉ nhắc nếu chưa trả lời" cần CF/state-aware → out of scope.
- "Ngày"/giờ theo lịch local mỗi máy (LDR lệch múi giờ vẫn như #5).
- Schedule chỉ arm khi couple active (`_lastAnniversary != null`). Bật switch lúc chưa có partner → chỉ lưu pref, sync arm sau khi couple active. KHÔNG lỗi.
- Đổi giờ khi đang bật & couple active → reschedule (cancel+schedule qua id 1004 ổn định).

### Nhật ký
- [2026-06-04] [Dev] Implement b2 local daily-question reminder (id 1004, độc lập master toggle). Service +2 method, provider +state/setter/wire sync, session_resolver cancel 2 nhánh no-couple, settings tile switch+time, 5 key l10n vi+en. analyze sạch, test cũ giữ nguyên (1 fail pre-existing widget_test login copy). Thuần local — không deploy.
- [2026-06-05] [Dev] Fix UI: ô nhập câu trả lời ở `_DailyQuestionCard` (home_screen.dart) bị "lơ lửng" — hint nằm giữa, "0/280" rớt xuống đáy ô trống cao. Nguyên nhân: `maxLines:3 minLines:1` + `counterText` nội bộ (InputDecoration reserve hàng counter dưới field). Sửa: `isCollapsed:true` + `textAlignVertical.top` (neo hint trái-trên), `minLines:2 maxLines:4` (textarea cao chủ đích), ẩn counter nội bộ (`counterText:''`) → render char-count thành `Align.centerRight` Text riêng ngay dưới field trong `Column(mainAxisSize.min)`. Giữ glass blur cho nhất quán. analyze sạch.
- [2026-06-14] [lead+dev] Daily-Q reminder: 1 giờ → NHIỀU GIỜ + COUPLE-SHARED. ReminderService `scheduleDailyQuestionTimes(minutesOfDay)` (dải id 1040–1049, cancel cả dải + legacy 1004). ReminderProvider giữ `_dqTimes` (List<int> phút, sort/de-dup/cap 10) + `_dqEnabled`, sync qua `couples/{id}/prefs/home` (field `dqReminderTimes`+`dqReminderEnabled`, rule additive backward-compat, writes merge). `HomePrefsService.watchReminderPrefs/setReminderPrefs`; watch wire ở session_resolver (couple active), reschedule local khi remote đổi (dùng l10n cache từ HomeScreen.sync). Hive = cache offline + migrate giờ đơn cũ → list. API mới: `dailyQuestionReminderTimes`/`canAddDailyQuestionTime`/`addDailyQuestionTime`/`removeDailyQuestionTime`/`setDailyQuestionTimes`. Editor nhiều giờ (chip + nút thêm) ở settings. analyze 0, rules-test 154 pass.
- [2026-06-14 vòng 2] [lead/dev] UI daily-Q reminder rút về 1 GIỜ (user: "xoá thêm giờ nhắc"). settings_screen: thay editor nhiều-chip + nút "Thêm giờ nhắc" bằng `_DailyQuestionTimeRow` (1 hàng chạm-để-đổi → `setDailyQuestionTimes([picked])`); xoá `_DailyQuestionTimesEditor`/`_TimeChip`/`_AddTimeChip`. Provider/service/sync GIỮ nguyên infra list+couple-shared (add/remove/canAdd thành không dùng). analyze 0.
- [2026-06-19] [lead/dev] **(A) Bật lại NHIỀU GIỜ nhắc** (user đổi ý) + **(B) auto cảnh báo cuối ngày 21/22/23h**. (A) settings_screen `_DailyQuestionReminderTile`: lại render 1 `_DailyQuestionTimeRow`/giờ (giờ là primary text w800, ✕ xoá khi >1 — `removeDailyQuestionTime`; tap = sửa → replace index + `setDailyQuestionTimes`) + `_DailyQuestionAddTimeRow` ("Thêm giờ nhắc", ẩn khi `!canAddDailyQuestionTime`, default picker 21:00 → `addDailyQuestionTime`) + dòng hint `dailyQuestionReminderEndOfDayHint`. Dùng lại infra list+couple-shared có sẵn (không đổi provider/service cho phần này). (B) **End-of-day safety net** — LOCAL, ONE-SHOT/ngày, có ĐIỀU KIỆN (user chốt: local + vẫn cảnh báo khi mình đã trả lời mà người ấy chưa). `ReminderService`: class `DailyQuestionEodSlot` + dải id **1050–1052** + `scheduleDailyQuestionEndOfDay(slots)` (one-shot HÔM NAY, skip giờ đã qua, KHÔNG roll sang mai) + `cancelDailyQuestionEndOfDay`. `ReminderProvider`: `refreshDailyQuestionSafetyNet({hasRevealed,iAnswered,currentStreak,l10n})` + `_scheduleEndOfDay` (debounce signature `[enabled|hasRevealed|iAnswered|streak|dayKey]`; cancel khi off/đã reveal; copy 21h=nhắc, 22/23h=cảnh báo mất chuỗi, phân nhánh theo `iAnswered` + `streak>=1` vs `==0`). Wire vào setEnabled / watchCoupleReminderPrefs / cancelDailyQuestionSchedule. `HomeScreen`: `_dqProvider` + listener `_refreshDqSafetyNet` trên CẢ DailyQuestion+Streak provider (re-arm mỗi update + 1 lần post-frame), dispose remove. Điều kiện "chưa trả lời" = `!hasRevealed` (chưa bothAnswered) ⇒ huỷ ngay khi cả 2 xong; hạn chế local: app bị kill đúng lúc người kia vừa trả lời thì có thể báo nhầm (đã chấp nhận). 9 key l10n mới (vi+en) + gen-l10n. **Thuần local — KHÔNG đụng backend, KHÔNG deploy.** analyze lib/ 0 issue.
- [2026-06-19] [dev] **Fix bug "thêm giờ nhắc không dùng được":** getter `dailyQuestionReminderTimes` trả list `.toList(growable: false)` (fixed-length) → `addDailyQuestionTime` (`..add(time)`) và `removeDailyQuestionTime` (`removeAt`) ném exception → thêm/xoá giờ im lặng vô hiệu. Bug có sẵn từ 2026-06-14 (lúc đó UI bỏ nút thêm nên không lộ); bật lại UI multi-time hôm nay làm lộ ra. Sửa: `addDailyQuestionTime` dùng `[...dailyQuestionReminderTimes, time]`, `removeDailyQuestionTime` dùng `List.of(...)` growable trước khi `removeAt`. analyze 0.
