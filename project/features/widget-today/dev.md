# 💻 Dev — Widget "Hôm nay" (dòng trạng thái "người ấy vừa…")

> Dev sở hữu. Đọc `overview.md` (D1–D15) + `design.md` trước. Nền tảng: [`../home-widget/dev.md`](../home-widget/dev.md).

- **Trạng thái dev:** đã vá bug Tester vòng 1 (B1–B3, B5–B7), chờ Tester vòng 2. Code đã gộp vào `feature/daily-open` (worktree `dear_embeiu-daily`).
- **Người/role:** Dev
- **Deploy:** DEV chạy code gộp từ 2026-10-19T16:57Z (HEAD `f0096a3`, xem Vết deploy). PROD chưa (D11, chờ lệnh phát hành 1.11.0).

## Cách làm từng phần

### 1. Hàm thuần `HomeWidgetStatus` — `lib/services/home_widget_status.dart` (mới)
- `build(today: TodayConstellation, l10n, now, active, partnerName, questionReady, partnerPhotoAt?, decision?)`: tái dùng **`TodayConstellation.from`** (không viết lại logic "hôm nay"). Ứng viên:
  - câu hỏi: người ấy + mình đã trả lời → `question_both` (giờ = câu trả lời muộn hơn) · chỉ người ấy → `question_partner` · không ai và `questionReady` → `question_mine` với giờ = 0:00 hôm nay (việc thật nào trong ngày cũng đè nó) · chỉ mình → không có gì (D4.2, không nói "người ấy chưa…").
  - tâm trạng người ấy (`moodKey` → `moodLabel` viết thường), tin nhắn mới nhất của người ấy, ảnh người ấy hôm nay (`latestPartnerPhotoAt`), quyết định (`WidgetDecision`, tuỳ chọn).
  - **Mới nhất thắng** (D3): `statusAt` lớn nhất; hoà thì giữ mục đứng trước.
  - `active=false` (chờ người ấy) → `none()` = 7 khoá rỗng, widget trùng 1.9.1.
- `fromPush(data, l10n, now, sentAt)`: map `daily_question` (`bothAnswered`), `partner_mood` (`mood`), `chat_message`, `photo_posted`, `decision` (`kind` eat/go/custom) → 9 loại trừ `question_mine` (chỉ app mới biết). Bỏ qua khi `data.date` ≠ hôm nay; push không có `date` (chat/ảnh) thì so `RemoteMessage.sentTime`. Gắn `onlyIfNewer=1`.
- `pushLang(data, Platform.localeName)`: `data.lang` vi/en, thiếu thì theo máy. Tên rỗng → `reactionPartnerFallback` ("Người ấy"/"Your partner").
- Khoá `updateStatus` (D6): `todayDate, statusKind, statusText, statusTextShort, statusAt, statusTarget (home|chat|gallery), statusFocus (daily_question|mood|decision|'')` (+ `onlyIfNewer` chỉ từ push nền, native gỡ trước khi lưu).
- `decision_custom` mà thiếu câu hỏi → dùng câu của `decision_go` ("Hôm nay: …") thay vì ": Anh".

### 2. Đường app mở (D5a) — `lib/screens/home_screen.dart`
- `_pushWidgetStatus()` lắng nghe DailyQuestion + Mood + Chat + Photo + Couple provider (cùng kiểu `_refreshDqSafetyNet`, gỡ ở dispose) + 1 lần post-frame.
- Chờ provider sẵn sàng: `dq.dateKey` rỗng / `dq.isLoading` / `!mood.isReady` / `mood.isLoading` → không gửi (tránh xoá dòng mà push nền vừa ghi lúc khởi động lạnh).
- Tên người ấy = cùng luật `MoodCard` (người tạo couple → `person2Name`, ngược lại `person1Name`).
- `HomeWidgetBridge.pushStatus` debounce 400ms + bỏ trùng (`mapEquals`). Đăng xuất / rời couple: đường `push(null)` → `state=empty` → native xoá cả status (D6); bridge reset `_lastStatus`.

### 3. Đường app ở nền (D5b, D9) — `lib/services/push_notification_service.dart`
- `firebaseMessagingBackgroundHandler` gọi thêm `_updateWidgetStatus`: `fromPush` + `lookupAppLocalizations(Locale(lang))` → `HomeWidgetBridge.sendStatus`. Không đọc Firestore. `_cancelStaleDailyQuestionNudges` giữ nguyên (vẫn chỉ huỷ khi `bothAnswered=='true'`).

### 4. Android — D13 đạt bằng **local plugin**
- `packages/dear_embeiu_widget_channel/` (Java, `path:` dependency): `WidgetChannelPlugin implements FlutterPlugin`, xử lý `update` / `updateStatus` / `setPhoto` / `consumeLaunch` trên kênh `dear_embeiu/widget`. Vì `GeneratedPluginRegistrant` nạp nó vào **mọi** FlutterEngine, engine nền của firebase_messaging (16.4.0 lock: `new FlutterEngine(ctx)` → tự đăng ký plugin) có kênh.
- Plugin không thấy class của app → ghi đúng 3 file SharedPreferences mà `WidgetStore` đọc (`dear_embeiu_widget`, `dear_embeiu_widget_status` mới, `dear_embeiu_widget_launch`) + `filesDir/widget_photo.png`, rồi gửi **broadcast tường minh** `com.tony.dearembeiu.widget.REFRESH` tới `com.tony.dearembeiu.widget.DayCounterWidget`; `DayCounterWidget.onReceive` gọi `updateAll` (vẽ cả 2 cỡ + preview bộ chọn y như trước). Ghi bằng `commit()` vì isolate nền có thể bị huỷ ngay sau.
- `MainActivity`: gỡ toàn bộ kênh widget (tránh 2 handler cùng tên trên engine chính — cái đăng ký sau thắng). Chỉ còn ghi cờ chạm: `widget_family` + `widget_target/focus/kind`.
- `WidgetStore`: bỏ `save/savePhoto/consumeLaunch` (chuyển sang plugin), thêm `loadStatus`, `recordLaunch` 4 khoá.
- `DayCounterWidget`: `todayStatus()` (todayDate == `LocalDate.now()` + có chữ); `applyStyle(status, fontScale)` đặt đủ cả 2 nhánh mỗi lần vẽ (bài học reapply): `widget_status` VISIBLE/GONE, chữ (bản nhỏ `statusTextShort`, vừa `statusText`), chấm blush/trắng theo nền, bản nhỏ `widget_caption` maxLines 1/2, bản vừa `widget_since` GONE/VISIBLE + status maxLines 1 khi `fontScale ≥ 1.3`. Preview bộ chọn luôn `status=null`. `openApp` luôn đặt 3 extra (`""` khi không có dòng).
- Layout `widget_day_small.xml` / `widget_day_medium.xml` thêm khối `widget_status` (`gone` mặc định = trùng 1.9.1) theo design §5.4/§5.5; drawable `widget_status_dot.xml` (#FF8FA3) + `widget_status_dot_light.xml` (#FFFFFF).
- Mô tả bộ chọn (D15): `values/strings.xml`, `values-vi/strings.xml`.

### 5. iOS
- `AppDelegate.swift` `HomeWidgetChannel`: `updateStatus` lưu `widget_status` trong App Group (bỏ qua khi `onlyIfNewer=1`, cùng ngày, `statusAt` cũ hơn bản đang lưu); `update` với `state=empty` xoá status; `consumeLaunch` trả dict `{family,target,focus,kind}`; `recordLaunch` đọc 4 query item (khoá UserDefaults mới `widget_launch`, khoá cũ `widget_launch_family` bỏ). SceneDelegate không đổi; deep linking Flutter vẫn tắt.
- Extension: `WidgetStatus` (trong `WidgetSnapshot.swift`, không thêm file → không đụng pbxproj); `DayEntry.status` tính **theo từng entry** (`shown(on: entry.date)`) ⇒ entry 0:00 tự trống (D4.1); preview/placeholder không có status. `DayMath.dateKey` (Gregorian, giờ máy — khớp Dart).
- `DayCounterView.swift`: `StatusLine` = 1 `Text` ghép (chấm `circle.fill` 6pt + " " + câu), Quicksand Bold 12 (co 0.84) / 14 (co 0.857), `.accentable()`, `.dynamicTypeSize(...xxxLarge)`, `accessibilityLabel(text)`. `SmallCounter` dùng `if let status` (không opacity/Text rỗng): có dòng thì số `layoutPriority(1)`, caption 1 dòng co 0.85 + chặn xxxLarge. `MediumCounter`: cột trái không nhận status; cột phải `if/else` thay đúng chỗ `sinceText`. `widgetURL` thêm `target/focus/kind` khi có dòng.
- `en.lproj`/`vi.lproj` `widget_description` (D15).

### 6. Chạm widget (D7) — `HomeWidgetBridge.consumeLaunch`
- Native trả map (1.9.x trả chuỗi family → vẫn đọc được). `parseLaunch` whitelist: family small/medium, target home/chat/gallery, focus daily_question/mood/meal, kind 9 loại; sai → bỏ. Đặt `NotificationTapRouter.pendingHomeTab` (+ `pendingHomeFocus`) — cùng đường push tap.
- `HomeScreen._applyPendingFocus`: thêm `'mood'` → cuộn `MoodCard` (GlobalKey mới `_moodCardKey`); `'decision'` → cuộn thẻ "Phân vân gì không?" (`NotificationTapRouter.focusDecision`, nối lúc gộp).
- Analytics `widget_tap{family, target, status_kind}` (`none` khi không có dòng) — `AnalyticsEvents.pTarget`, `pStatusKind`.

### 7. Cloud Functions (D8) — `functions/index.js`
- `sendToRecipientDevices`: helper `langData(device)` → `data.lang` = `languageCode` của từng thiết bị (cả push chính lẫn companion Android); thiếu thì không ghi.
- `notifyDailyAnswer`: `wakeClients: true` luôn; thêm `actorName` (đã thô sẵn). `notifyPartnerMood`: + `mood`, `date`, `actorName`, `wakeClients`. `sendPartnerPhotoNotification`: + `actorName` thô, `wakeClients`. `notifyChatMessage`: + `actorName` thô, `wakeClients` (vẫn bỏ qua người đang xem chat). Copy push, inbox, companion: không đổi.

### 8. i18n
- 18 key ARB vi+en: `widgetStatus{QuestionPartner,QuestionBoth,QuestionMine,Mood,Message,Photo,DecisionEat,DecisionGo,DecisionCustom}` (copy D2) + `widgetStatusShort…` (D14). `widgetStatusShortDecisionGo` = `{result}` cả 2 ngôn ngữ (D14 chốt cho vi; en dùng chung lý do "mục ngân hàng mở đầu bằng động từ"). `flutter gen-l10n` đã chạy.

## Kết quả lệnh (2026-10-19)
- `flutter analyze` → **No issues found**.
- `flutter test` → **609 pass, 3 skip, 0 fail** (mới: `test/home_widget_status_test.dart` 17 test — build so với TodayConstellation, mới nhất thắng, 9 loại push, bỏ push ngày khác, fallback tên/ngôn ngữ, câu rút gọn, parseLaunch whitelist, consumeLaunch → router, debounce/dedupe pushStatus).
- `scripts/test-firebase-rules.sh` → **358 passing** + functions test 12 pass, exit 0.
- `scripts/check-widget-daymath.sh` → **OK DayMath — 32 checks** (thêm 2 check `dateKey`, cả dưới th_TH).
- `cd android && ./gradlew :app:testDebugUnitTest` → PASS (DayMathTest 5, MotionSpansTest 6).
- `flutter build apk --debug` ✓ · `flutter build ios --debug --no-codesign` ✓ (Runner.app có `DearEmbeiuWidget.appex`). `pod install` đảo thứ tự build phase trong `project.pbxproj` → đã `git checkout`, không commit.

## Smoke Android emulator (Pixel_10, Android 17, Play image, DEV, `test3`)
- **Spike D13 PASS:** app bị `am kill` (tiến trình chết) → gửi push data-only giống companion Android (`type: chat_message`, `actorName`, `lang: vi`) bằng firebase-admin → log `FLTFireBGExecutor: Creating background FlutterEngine instance` → `dear_embeiu_widget_status.xml` có `message / "Thảo vừa nhắn cho mình"`, không `MissingPluginException`.
- Widget 2×2 thêm lên màn hình chính: nền ảnh (P3), dòng "● Thảo vừa nhắn" (bản rút gọn), số ngày không dịch ngang. Push `partner_mood` (`stressed`, `lang: en`) khi app chết → widget đổi "● Thảo: stressed" **≈8 giây** từ lúc gửi (gồm khởi động engine nền lạnh).
- Push `daily_question` `date` hôm qua → bị bỏ qua (status giữ nguyên).
- Chạm widget đang hiện "Thảo: stressed" → app mở Home, cuộn tới thẻ "Today's mood"; log `opened from the widget small → home/mood`.
- App mở → dòng được tính lại từ provider (`question_mine` "Today's question is waiting for you") — đúng: app là nguồn sự thật, push giả không có dữ liệu thật đằng sau.
- Bộ chọn widget: không có dòng trạng thái, mô tả mới hiện đúng.
- Ảnh chụp ở scratchpad (không commit).
- **E2E qua CF thật chưa kiểm được trên máy:** sau deploy DEV, ghi tin chat của `test4` → log CF `Processed chat-message notification … successCount 2` (push chính + companion), nhưng lúc đó emulator đã bị Dev decision-wheel cài bản của nhánh họ đè lên (cùng package `.dev`) nên handler mới không chạy. Tôi dừng dùng emulator để không phá phiên của họ. Đã để lại dữ liệu thử DEV: 1 tin chat "widget test" của test4 trong `widget_couple_dev`.

## Vết deploy DEV
- 2026-10-19T16:22Z–16:23:47Z, `deploy --project tonyembeiu-dev --only functions:notifyDailyAnswer,functions:notifyPartnerMood,functions:sendPartnerPhotoNotification,functions:notifyChatMessage`, git HEAD worktree **`988dacff`** (nhánh `feature/widget-today`). 4/4 "Successful update operation".
- ⚠️ Hook `trace-firebase-deploy.sh` ghi vết vào checkout chính (`20261019T162347Z`) với `head=f45f423 (feature/launch-film)` — sai HEAD vì hook đọc repo chính, không phải worktree. HEAD đúng là `988dacff`. Restore: `git checkout 83d18a0 -- functions` trong worktree rồi redeploy 4 hàm.
- Cùng lúc (16:22:38Z) Dev decision-wheel deploy DEV `firestore:rules,notifyDecision,deleteAccount,leaveCoupleCleanup` từ worktree của họ — không trùng hàm với đợt này.

## TODO tích hợp (khi gộp với decision-wheel) — đã xong ở merge `21c75ca`
- [x] `HomeScreen._pushWidgetStatus`: truyền `decision: WidgetDecision(kind, result, question, at)` từ `DecisionProvider` (chỉ quyết định hôm nay) + thêm provider đó vào danh sách lắng nghe/gỡ.
- [x] `HomeScreen._applyPendingFocus`: case `'meal'` → cuộn thẻ "Phân vân gì không?" (cần GlobalKey của thẻ đó).
- [x] CF `notifyDecision` phải gửi `type:'decision'`, `kind`, `result`, `question`, `date`, `actorName`, `wakeClients` (đã có test payload giả trong `home_widget_status_test.dart`).
- [x] `functions/index.js` cả 2 nhánh đều sửa → gộp tay; `sendToRecipientDevices` + `langData` ở nhánh này.

### Vết deploy DEV — vá vòng 1 (B7)
- 2026-10-19T16:55:53Z–16:57:28Z, worktree `dear_embeiu-daily`, HEAD **`f0096a3`** (`feature/daily-open`, code sạch). `deploy --project tonyembeiu-dev --only firestore:rules,functions:notifyDecision,functions:notifyDailyAnswer,functions:notifyPartnerMood,functions:sendPartnerPhotoNotification,functions:notifyChatMessage,functions:notifyPartnerLeft` → rules released + 6/6 "Successful update operation". Vết tay: `project/.firebase-deploy-log/20261019T165553Z-daily-open/` + dòng HISTORY. (Hook lại ghi nhầm ở checkout chính `20261019T165728Z`, HEAD sai — bỏ qua.)

## Điểm chưa kiểm / rủi ro (Tester soi)
- iOS chưa chạy trên máy/simulator (chỉ biên dịch). Cần soi: timeline entry 0:00 tự mất dòng, tinted, AX5, URL `target/focus` qua SceneDelegate, push nền iOS thật (DEV thiếu APNs key → iOS DEV không nhận push, xem CLAUDE.md §5).
- Push loại bị user tắt trên thiết bị (`pushPhoto=false`…) → CF bỏ cả thiết bị đó ⇒ widget không đổi khi app tắt cho loại đó (chỉ đổi khi mở app).
- Tên trên widget: đường nền dùng `displayName` (từ CF), đường app mở dùng tên trong couple (`person1/2Name`). Hai tên khác nhau thì widget đổi qua lại theo đường cập nhật.
- `data.lang` = ngôn ngữ thiết bị đăng ký lúc lưu token; người đổi ngôn ngữ trong app mà chưa đăng ký lại → câu nền có thể sai ngôn ngữ tới lần mở app.
- Mood/answer có `updatedAt/answeredAt` null (hiếm) → giờ = `now` mỗi lần tính ⇒ debounce vẫn chặn, nhưng mục đó luôn "mới nhất".
- Android: chưa so pixel 1.9.1 vs bản mới khi không có dòng (design §9.1) — XML mặc định `gone` nên kỳ vọng trùng, cần Tester chụp so.
- Android 4×2 chưa đặt lên màn hình chính để nhìn (chỉ thấy preview bộ chọn).
- Commit đầu `2744fb6c` (native) đổi `consumeLaunch` trả map trước commit Dart → build ở riêng commit đó thì chạm widget chỉ log lỗi, không crash.

## Nhật ký implement
- [2026-10-19] [Dev] Spike D13 (local plugin + broadcast) PASS trên emulator với app đã chết. Implement HomeWidgetStatus + bridge + handler nền + chạm widget + analytics; iOS/Android native; 4 CF (D8) + `data.lang`; 18 chuỗi ARB; test 17 mới. analyze 0 · test 609 pass · rules 358 pass · DayMath 32 · JUnit pass · apk + ios debug build ✓. Deploy DEV 4 CF (HEAD `988dacff`). Commit `2744fb6c`, `5ddfc630`, `988dacff` + commit docs này.
- [2026-10-19] [Dev] Vá Tester vòng 1 (commit `f0096a3`, nhánh `feature/daily-open`):
  - **B1** `home_screen.dart` `initState`/`dispose`: nghe `LocaleProvider` → `_onLocaleChangedForWidget` gửi lại dòng ở frame sau (lúc `context.l10n` đã sang ngôn ngữ mới).
  - **B2** CF `notifyChatMessage` + `sendPartnerPhotoNotification` gửi `data.sentAt` (epoch ms, chuỗi). `HomeWidgetStatus.fromPush`: `data.sentAt` thắng `RemoteMessage.sentTime`; push không có `date` lẫn giờ gửi → bỏ qua (không chứng minh được là hôm nay). Push từ CF cũ (PROD trước 1.11.0) trên iOS không có `sentTime` ⇒ bị bỏ qua, widget đổi khi mở app.
  - **B3** `fromPush` `decision`: có `resultId` → `decisionDisplayName` theo ngôn ngữ máy nhận. Hàm này chuyển từ `widgets/decision_parts.dart` sang `utils/decision_suggester.dart` (thuần, không kéo widget vào isolate nền); `decision_parts` re-export nên chỗ gọi cũ giữ nguyên. CF `notifyDecision` có `data.resultId` (commit decision-wheel).
  - **B5** CF `notifyPartnerLeft` thêm `{wakeClients: true}`. `fromPush('partner_left')` trả `HomeWidgetStatus.none()` không kèm `onlyIfNewer` → `updateStatus` ghi đè dòng rỗng (native iOS/Android đều ẩn khi `statusText` rỗng), số ngày giữ nguyên. **Không thêm `clearStatus`**: `updateStatus` không `onlyIfNewer` đã là cách xoá riêng dòng ⇒ không đụng native/plugin.
  - **B6** `_pushWidgetStatus` chờ thêm `ChatProvider.isLoading` + `DecisionProvider.isLoading`. Ảnh (PhotoProvider) không chờ — PO không yêu cầu.
  - **B7** deploy DEV từ HEAD gộp (vết ở trên). **B4** (tài liệu) — sửa trạng thái, `statusFocus`, TODO tích hợp trong file này; `overview.md` là của PO.
  - Test mới trong `test/home_widget_status_test.dart`: sentAt (B2), resultId 2 chiều ngôn ngữ (B3), partner_left (B5).
  - Kết quả: `flutter analyze` 0 · `flutter test` 632 pass / 3 skip · `scripts/test-firebase-rules.sh` rules 392 passing + CF 19/19. Không đụng native ⇒ không build lại apk/ios.
  - Tester soi: B1 trên máy thật (đổi ngôn ngữ ở Cài đặt khi Home đang mở); B5 trên máy Android thật (người ấy rời lúc app tắt → companion data-only `partner_left` → dòng biến mất, số ngày còn).
