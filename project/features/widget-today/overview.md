# Widget "Hôm nay" — người ấy vừa làm gì, hiện ngay trên màn hình chính

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Xây trên nền [home-widget](../home-widget/overview.md) (bridge `dear_embeiu/widget`, target WidgetKit, AppWidgetProvider). Quyết định D1–D11 bên đó vẫn giữ nguyên, trừ chỗ ghi rõ dưới đây.

- **Feature:** widget-today
- **Ưu tiên:** P0 (mục tiêu "mở app mỗi ngày", user chốt 2026-10-19)
- **Trạng thái:** 📋 Spec (chờ user duyệt rồi chạy pipeline Designer → Dev → Tester)
- **Tạo ngày:** 2026-10-19
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · nền tảng [`../home-widget/`](../home-widget/overview.md) · loại trạng thái `meal` phụ thuộc [`../what-to-eat/`](../what-to-eat/overview.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:* widget 1.9.1 chỉ hiện số ngày. Con số đổi đúng một lần lúc 0:00 và không nói gì về người ấy. Nhìn widget 10 lần một ngày thì 10 lần như nhau, không có lý do để chạm.
- *Số liệu PROD ngày 2026-10-19* (`scripts/prod-retention-stats.js`, đọc-only): 28 cặp đã ghép, mỗi ngày chỉ 7–16 cặp có người mở Home và 3–5 cặp cả hai trả lời câu hỏi. Có 8 cặp cả hai mở app mỗi ngày nhưng không ai trả lời. Nhiều cặp lệch một người: một bên trả lời 4 câu/tuần, bên kia 0.
- *Giả thuyết giá trị:* người ấy vừa làm một việc (trả lời câu hỏi, chọn tâm trạng, nhắn tin, đăng ảnh, chốt món ăn) thì widget của mình đổi câu ngay, kể cả khi app đang tắt. Mình mở khoá máy, thấy "Em đã trả lời, đến lượt mình", chạm vào là rơi đúng thẻ câu hỏi. Vòng lặp: A làm → widget B đổi → B mở app làm → widget A đổi. Đây là cách đưa người thứ hai quay lại mà không cần thêm thông báo đẩy nào.
- *Đối tượng:* cặp đã ghép đôi và đã thêm widget. Cặp còn chờ người ấy chỉ thấy số ngày như cũ.
- *Đo bằng gì (metric):*
  - Số cặp có người mở app mỗi ngày (proxy: marker `dailyAnswers/{date}` tồn tại), đo bằng `scripts/prod-retention-stats.js`. Nền 2026-10-19: 7–16/28. Mục tiêu sau 30 ngày phát hành: ≥60% cặp active mỗi ngày.
  - Số cặp cả hai trả lời câu hỏi/ngày: nền 3–5. Mục tiêu: gấp đôi.
  - `widget_tap` có thêm `target` + `status_kind`: ≥40% số lần chạm xảy ra khi widget đang hiện trạng thái (chứng tỏ câu chữ kéo người ta vào, không phải chạm vu vơ).

## 2. Bối cảnh / nghiên cứu

- Locket (ảnh người ấy lên widget) là app cặp đôi giữ chân tốt nhất mảng này nhờ đúng một cơ chế: thứ trên màn hình chính đổi khi người kia làm gì đó. User chốt 2026-10-19 **không** đổi ảnh widget (giữ ảnh nền thẻ đếm tự chọn), chỉ thêm dòng trạng thái. Lý do: ảnh nền là thứ user đã chọn có chủ đích ở 1.9.x, và dòng chữ đủ để kéo người ta vào.
- Kiểm kê của PO home-widget (2026-10-12) đã xếp "Câu hỏi hôm nay" là widget có giá trị thói quen cao nhất, và cảnh báo "Hôm nay của chúng mình" dễ hiện số cũ. Spec này giải bài số cũ bằng 3 chốt chặn (D4).
- Hạ tầng đã có, không phải dựng mới:
  - Push đánh thức app ở nền: `sendToRecipientDevices(..., {wakeClients: true})` — iOS `contentAvailable` trên chính push, Android gửi thêm bản data-only. Đang dùng cho `notifyPartnerJoined` và `notifyDailyAnswer` (chỉ khi cả hai đã trả lời).
  - Handler nền `firebaseMessagingBackgroundHandler` (`lib/services/push_notification_service.dart`) đã gọi được plugin qua `DartPluginRegistrant.ensureInitialized()` — kênh `dear_embeiu/widget` gọi được từ đây.
  - Chạm widget đã có cờ native `widget_family` → `HomeWidgetBridge.consumeLaunch()`; điều hướng tab đã có `NotificationTapRouter.pendingHomeTab` / `pendingHomeFocus`.
  - Trạng thái "hôm nay" ở client đã tính sẵn trong `TodayConstellation` (`lib/widgets/today_constellation.dart`): câu hỏi · tâm trạng · nhắn tin, mỗi người.

## 3. Phạm vi (scope)

- **Trong phạm vi:**
  - Một **dòng trạng thái "hôm nay"** trên cả 2 cỡ widget, 2 nền tảng. Nội dung = việc MỚI NHẤT người ấy làm hôm nay (bảng §4 D2). Không có gì mới → widget giống hệt 1.9.1.
  - Cập nhật **khi app mở** (từ provider) và **khi app ở nền** (từ push đánh thức). Nguồn copy duy nhất = ARB (Flutter dịch sẵn, native chỉ hiện — giữ D4 home-widget).
  - **Chạm widget mở đúng chỗ**: tab Chat / Gallery / Home + cuộn tới thẻ câu hỏi, tâm trạng hoặc món ăn.
  - Cloud Functions thêm `wakeClients` + vài khoá `data` cho 4 push đang có; **không đổi rules**.
  - Tự ẩn sau 0:00 mà không cần mở app (native so ngày).
- **Ngoài phạm vi:** đổi ảnh widget theo ảnh người ấy (user bỏ 2026-10-19) · widget màn khoá iPhone (Phase 2 home-widget) · lời quan tâm trên widget (riêng tư, màn hình chính ai cũng thấy) · nội dung tin nhắn · số tin chưa đọc · tự làm mới bằng mạng từ extension (WidgetKit/RemoteViews không có Firebase) · nút bấm riêng từng vùng trên widget.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý.

- **D1 — Giữ ảnh nền, chỉ thêm dòng trạng thái** (user chọn 2026-10-19 trong 3 hướng: ảnh người ấy vừa đăng · ảnh mới nhất của cặp · giữ ảnh nền + dòng trạng thái). *Lý do:* ảnh nền là lựa chọn có chủ đích của user ở 1.9.x; dòng chữ đã đủ kéo người ta vào.

- **D2 — Bảy loại trạng thái, copy chốt tại đây** (Designer/Dev không tự đổi lời; `{name}` = tên người ấy, `{mood}` = nhãn tâm trạng viết thường từ `moodLabel`, `{dish}` = tên món):

| `statusKind` | Khi nào | vi | en | Chạm mở |
|---|---|---|---|---|
| `question_partner` | người ấy đã trả lời hôm nay, mình chưa | `{name} đã trả lời, đến lượt mình` | `{name} answered — your turn` | Home, cuộn thẻ câu hỏi |
| `question_both` | cả hai đã trả lời hôm nay | `Cả hai đã trả lời hôm nay` | `You both answered today` | Home, cuộn thẻ câu hỏi |
| `question_mine` | mình chưa trả lời, người ấy cũng chưa (chỉ tính được khi app mở) | `Câu hỏi hôm nay đang chờ mình` | `Today's question is waiting for you` | Home, cuộn thẻ câu hỏi |
| `mood` | người ấy chọn tâm trạng hôm nay | `{name} hôm nay: {mood}` | `{name} today: {mood}` | Home, cuộn thẻ tâm trạng |
| `message` | người ấy vừa nhắn | `{name} vừa nhắn cho mình` | `{name} just messaged you` | Chat |
| `photo` | người ấy vừa đăng ảnh | `{name} vừa đăng ảnh mới` | `{name} just added a photo` | Gallery |
| `meal` | cặp vừa chốt món hôm nay (feature what-to-eat) | `Hôm nay ăn: {dish}` | `Today's meal: {dish}` | Home, cuộn thẻ "Hôm nay ăn gì" |

  *Lý do chọn 7 loại này:* đúng 3 việc của chòm sao "Hôm nay của chúng mình" (câu hỏi · tâm trạng · nhắn tin) cộng 2 việc trùng North Star (ảnh, món ăn). Lời quan tâm bỏ vì riêng tư.

- **D3 — Mới nhất thắng.** Chỉ hiện MỘT câu. Khi nhiều việc trong ngày, câu có `statusAt` lớn nhất đè câu cũ. Không xếp hạng ưu tiên giữa các loại. *Lý do:* đúng tinh thần "người ấy vừa…"; handler nền chỉ biết push vừa tới, không biết lịch sử, nên luật "mới nhất" là luật duy nhất cả hai đường cập nhật cùng thực hiện được.

- **D4 — Ba chốt chặn số cũ** (trả lời cảnh báo "dễ hiện số cũ" của home-widget):
  1. Mỗi trạng thái mang `todayDate` (YYYY-MM-DD giờ máy người nhận). Native chỉ hiện khi `todayDate` == ngày đang vẽ. iOS: từng entry trong timeline so với ngày của entry đó, nên entry 0:00 trở đi tự trống. Android: so lúc vẽ, trễ tối đa 30 phút sau 0:00 (như D7 home-widget).
  2. Về người ấy chỉ nói **việc đã xảy ra** (đã trả lời, vừa nhắn, vừa đăng). Không bao giờ nói "người ấy chưa…" vì app tắt thì không biết họ đã làm chưa.
  3. Về mình chỉ nói "đang chờ mình" (`question_mine`, `question_partner`) khi app vừa tính xong lúc mở; trả lời xong thì Home đẩy lại trạng thái ngay. Trả lời trên máy khác là trường hợp hiếm, chấp nhận.

- **D5 — Hai đường cập nhật, một nguồn chữ.** (a) App mở: `HomeWidgetBridge` lắng nghe thêm `DailyQuestionProvider` + `MoodProvider` + `ChatProvider` + `PhotoProvider` (+ `MealProvider`), tính `statusKind` y như `TodayConstellation`, dịch qua `AppLocalizations`, gọi `updateStatus`. (b) App ở nền: `firebaseMessagingBackgroundHandler` đọc `data.type` của push, dịch bằng `lookupAppLocalizations(Locale(data.lang))` (fallback `Platform.localeName`), gọi `updateStatus`. Native không có bảng dịch. *Lý do:* giữ D4 home-widget; copy chỉ nằm ở ARB, không trùng ở CF.

- **D6 — Kênh thêm method `updateStatus(Map<String,String>)`, tách khỏi `update`.** Khoá: `todayDate`, `statusKind`, `statusText`, `statusAt` (epoch ms), `statusTarget` (`home` · `chat` · `gallery`), `statusFocus` (`daily_question` · `mood` · `meal` · rỗng). Native lưu riêng, `update` (ảnh chụp đếm ngày) **không** xoá trạng thái; `state=empty` (đăng xuất, rời couple) xoá cả hai. *Lý do:* handler nền không có couple/l10n đầy đủ, chỉ cần ghi 6 khoá này; không được đẩy `empty` đè ảnh chụp tốt (bài học bridge 1.9.1).

- **D7 — Chạm widget vẫn là một vùng, đích = `statusTarget` của trạng thái đang hiện.** iOS: `widgetURL` thêm query `target` + `focus` cạnh `family`; `SceneDelegate` chỉ đọc 3 khoá này rồi ghi UserDefaults — **không** bật deep linking của Flutter (giữ D8 audit 2026-10-12). Android: extra `widget_target` + `widget_focus` cạnh `widget_family`. `consumeLaunch()` trả map; Flutter đặt `NotificationTapRouter.pendingHomeTab` (home 0 · chat 1 · gallery 2) + `pendingHomeFocus`. *Lý do:* tái dùng đúng đường đi của push tap, 0 route mới.

- **D8 — Push đánh thức thêm cho 4 CF, rules không đổi:**
  - `notifyDailyAnswer`: `wakeClients` **luôn** (hiện chỉ khi `bothAnswered`), giữ `data.date` + `data.bothAnswered` + tên người trả lời.
  - `notifyPartnerMood`: thêm `wakeClients` + `data.mood` (key) + `data.date` + tên.
  - `sendPartnerPhotoNotification`: thêm `wakeClients` + tên.
  - `notifyChatMessage`: thêm `wakeClients` + tên (vẫn bỏ qua khi người nhận đang mở chat — lúc đó app đang chạy, đường (a) lo).
  - `sendToRecipientDevices`: ghi `data.lang` = `languageCode` của từng thiết bị (một chỗ, mọi push được hưởng).
  - `notifyMealChosen` (what-to-eat) sinh ra đã có `wakeClients`.
  *Lý do:* push nền iOS bị hệ thống hạn mức "vài lần/giờ", 4 loại này mỗi ngày vài lần là vừa. Chat có thể nhiều hơn, chấp nhận ở bản đầu, theo dõi log `messaging` rồi mới thêm ngưỡng.

- **D9 — Handler nền chỉ ghi, không đọc Firestore.** Mọi thứ cần có đều nằm trong `data` của push (`type`, tên, `mood`, `date`, `lang`). Push mang `data.date` khác hôm nay thì bỏ qua (cùng guard với `_cancelStaleDailyQuestionNudges`). *Lý do:* thời gian nền iOS ~30 giây; đọc mạng làm hỏng tỉ lệ thành công và tốn pin.

- **D10 — Bản cũ không vỡ.** App 1.9.1/1.10.x nhận push có khoá `data` thừa → bỏ qua. CF cũ (chưa deploy) + app mới → widget chỉ đổi khi mở app. Widget 1.9.1 không đọc khoá trạng thái → vẫn vẽ số ngày.

- **D11 — Phát hành chung bản 1.11.0 với what-to-eat** (MINOR). DEV deploy CF trong lúc dev; PROD deploy đích danh `functions:notifyDailyAnswer,functions:notifyPartnerMood,functions:sendPartnerPhotoNotification,functions:notifyChatMessage,functions:notifyMealProposal,functions:notifyMealChosen` khi phát hành, **chờ lệnh user**.

- **D12 — Bố cục do Designer chốt, với 4 ràng buộc:** dòng trạng thái là phần tử phụ nổi nhất sau số ngày (cỡ chữ trong bộ 10/11/12/14 của home-widget); bản nhỏ 1 dòng, bản vừa tối đa 2 dòng, cắt "…" khi tràn; không emoji (tâm trạng hiện bằng chữ `{mood}`); không có trạng thái thì bố cục **trùng pixel** với 1.9.1 (không để khoảng trống). Soát với UI UX Pro Max trước khi chốt (luật 8 CLAUDE.md), gồm cả chế độ tinted iOS 18 và cỡ chữ AX.

## 5. Acceptance criteria (xong khi…)

- [ ] **Nền, không mở app:** máy A để app ở nền (iOS: không force-quit; Android: nền hoặc đã tắt). Máy B trả lời câu hỏi → widget A hiện "B đã trả lời, đến lượt mình" trong ≤60 giây (ghi số đo thật; iOS được phép trễ hơn khi hệ thống hoãn, ghi rõ trong test.md).
- [ ] B chọn tâm trạng / nhắn tin / đăng ảnh → câu mới đè câu cũ trên widget A, đúng copy D2, đúng ngôn ngữ app của A (vi và en).
- [ ] **Mở app:** A mở app → widget khớp Home trong ≤2 giây (cùng dữ liệu, cùng câu). A trả lời xong → widget A chuyển sang "Cả hai đã trả lời hôm nay" (nếu B đã trả lời) hoặc bỏ dòng "đang chờ mình".
- [ ] **Qua ngày:** chỉnh giờ máy qua 0:00 không mở app → iOS mất dòng trạng thái đúng 0:00, Android trong ≤30 phút; số ngày vẫn nhảy đúng như 1.9.1.
- [ ] **Chạm:** đang hiện "vừa nhắn" → app lên tab Chat; "đã trả lời" → Home cuộn tới thẻ câu hỏi; "hôm nay: vui" → Home cuộn thẻ tâm trạng; "vừa đăng ảnh" → Gallery; không trạng thái → Home như cũ. Mỗi lần chạm đúng 1 event `widget_tap{family, target, status_kind}`.
- [ ] Cặp còn chờ người ấy, đăng xuất, rời couple, xoá tài khoản → không có dòng trạng thái; đăng nhập lại → tính lại từ hôm nay.
- [ ] iOS 18 tinted, cỡ chữ AX lớn nhất, tên người ấy 12 ký tự, câu dài nhất ("{name} hôm nay: căng thẳng") không tràn, không đẩy lệch số ngày.
- [ ] App 1.10.1 (chưa cập nhật) nhận push mới → không crash, không hiện gì lạ. App mới + CF cũ → widget vẫn đổi khi mở app.
- [ ] `flutter analyze` 0; test Dart cho hàm map push → trạng thái (7 loại + bỏ qua ngày cũ + fallback tên/ngôn ngữ) và cho hàm tính trạng thái từ provider (so với `TodayConstellation`); `scripts/check-widget-daymath.sh` vẫn OK; JUnit Android vẫn PASS; `scripts/test-firebase-rules.sh` PASS (functions đổi).
- [ ] CF deploy DEV có vết; PROD chưa deploy cho tới lệnh phát hành.
- [ ] `project/features/widget-today/` + `ROADMAP.md` + CLAUDE.md mục 2/4/5 cập nhật.

## 6. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)

- 🎨 **Designer:** vị trí + kiểu chữ dòng trạng thái trên 4 bố cục (iOS nhỏ/vừa, Android 2×2/4×2), cả nền trời đêm (M2) lẫn nền ảnh (P3); trạng thái tinted + AX; chuỗi dài nhất vi/en; mock bấm thử. Tra UI UX Pro Max. → *expect:* `design.md` token chính xác + canvas 4 artboard.
- 💻 **Dev:** (1) `HomeWidgetStatus.build(...)` thuần + test; (2) bridge lắng nghe 4–5 provider, debounce, `updateStatus`; (3) handler nền map push → status + test; (4) iOS: lưu/đọc status trong App Group, so ngày theo entry, `widgetURL` thêm target/focus, SceneDelegate ghi cờ; (5) Android: `WidgetStore` thêm status, `applyStyle` đặt đủ cả 2 nhánh (bài học launcher reapply), intent extra; (6) `consumeLaunch` → `NotificationTapRouter`; (7) CF theo D8 + `scripts/test-firebase-rules.sh` + deploy DEV; (8) analytics. → *expect:* nhánh `feature/widget-today`, analyze 0, test PASS, smoke 2 nền tảng với 2 tài khoản DEV `test3`/`test4`.
- 🧪 **Tester:** chạy 11 tiêu chí §5 trên iPhone thật hoặc simulator iOS 18 + emulator Android 14/16 với cặp `test3`/`test4`; đo thời gian từ push tới widget đổi; thử push ngày cũ; thử app force-quit iOS (ghi hạn chế, không tính FAIL). → *expect:* bảng PASS/FAIL + số đo trong `test.md`.

## 7. Nợ kỹ thuật / rủi ro (Tester soi)

- 🔴 **iOS force-quit không được đánh thức** (hạn chế nền tảng, cùng với BUG-1 câu hỏi). Widget giữ câu cũ của hôm nay cho tới khi mở app; qua 0:00 tự ẩn nhờ D4.1 nên không sai về ngày.
- 🟡 Android hãng Trung Quốc (Xiaomi/Oppo) giết tiến trình nền → giống trên. Ghi vào hướng dẫn "Vì sao widget không đổi" nếu user hỏi.
- 🟡 Push nền iOS bị hạn mức; chat nhiều tin → có lúc widget không đổi. Theo dõi, chưa thêm ngưỡng.
- 🟡 Tên người ấy trong push là tên lúc gửi; đổi tên thì câu trên widget mang tên cũ tới lần mở app kế.
- 🟡 Ngân sách 64 notification iOS không đổi (feature này không thêm lịch local).
- 🟢 Riêng tư: màn hình chính chỉ lộ "đã trả lời / vừa nhắn / tâm trạng", không lộ nội dung.

## 8. Changelog feature
- [2026-10-19] [PO] Tạo feature từ phân tích retention PROD (28 cặp active, 7–16 cặp mở/ngày, 3–5 cặp cả hai trả lời). User chọn hướng "widget sống theo người ấy" (trong 3 hướng: widget · "Hôm nay" không cần người ấy · chọc 1 chạm) rồi chốt giữ ảnh nền, chỉ thêm trạng thái (D1). Chốt D2–D12. Chờ user duyệt spec.
