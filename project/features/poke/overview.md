# Chọc 1 chạm — chạm tim là người ấy biết mình đang nhớ

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Xây trên nền [widget-today](../widget-today/overview.md) (kênh `dear_embeiu/widget`, `updateStatus`, handler push nền, `wakeClients`) và [home-widget](../home-widget/overview.md). Quyết định bên đó giữ nguyên, trừ chỗ ghi rõ dưới đây.

- **Feature:** poke
- **Ưu tiên:** P0 (đợt "mở app mỗi ngày" lần 2, user chọn 2026-10-20)
- **Trạng thái:** 📋 Spec
- **Tạo ngày:** 2026-10-20
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · [`../widget-today/`](../widget-today/overview.md) · [`../care-message/`](../care-message/overview.md) · lịch sử [`../partner-nudge/`](../partner-nudge/overview.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md)
- **Tên trong app:** người dùng không thấy chữ "chọc". Hành động là **chạm tim**, kết quả hiện là **"nhớ"** ("Tuấn nhớ bạn 5 lần rồi"). "Poke"/"chọc" chỉ là tên nội bộ.

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:* 14:30, Thảo đang họp, chợt nhớ Tuấn. Muốn báo thì phải mở khoá, mở app, vào Chat, nghĩ xem gõ gì. Gõ "nhớ anh" giữa giờ làm thấy sến, nên thôi. Cái nhớ đó trôi đi, không ai biết.
- *Số liệu PROD 2026-10-19:* 28 cặp đã ghép, mỗi ngày 7–16 cặp có người mở app, chỉ 3–5 cặp cả hai trả lời câu hỏi. 8 cặp cả hai cùng mở app mà không ai trả lời: họ có vào, nhưng việc nào trong app cũng đòi viết.
- *Giả thuyết giá trị:* có một việc rẻ nhất có thể, 1 chạm, không chữ, làm được ngay trên màn hình chính, thì số lần "chạm vào nhau" mỗi ngày tăng mà không ai phải nghĩ. Mỗi lần chạm là một push tới người kia; người kia chạm lại là xong vòng, và lúc mở app thì thẻ câu hỏi đã nằm sẵn ở Home. Câu "hôm nay nhớ nhau 7 lần" là con số đổi liên tục trong ngày, lý do để liếc widget.
- *Khác care-message và "instant nudge" cũ:*
  - `care-message` (Quan tâm): có tiêu đề + nội dung, phải mở app, phải viết. Dành cho lúc muốn nói điều gì đó. Giữ nguyên.
  - "Instant nudge" (2026-06-29, gỡ 2026-06-30, xem `partner-nudge`): là nút "thúc" có chữ nằm trong một màn riêng "Nhắc người ấy". Gỡ vì trùng với lời nhắc và phải vào sâu mới dùng được.
  - Poke: không chữ, không màn riêng, 1 chạm, **gửi được ngay từ widget không cần mở app**, đếm theo ngày, thông báo gộp thành một dòng.
- *Đối tượng:* chỉ cặp **đã ghép** (`active`). Cặp còn chờ người ấy không thấy tim (không có ai để nhận).
- *Metric:* xem §9.

## 2. Bối cảnh / nghiên cứu

- Between có "Thumbkiss" (hai người cùng đặt ngón tay lên màn hình thì máy rung), Locket có widget ảnh, Widgetable/"Bump" có nút chạm trên widget gửi rung. Điểm chung: hành động 1 chạm, không chữ, có mặt ngay ở màn hình chính. App VN cùng niche (Been Love Memory, Been Together) chưa có.
- iOS 17 cho widget có nút thật (`Button(intent:)` chạy `AppIntent` trong tiến trình widget, không mở app). iOS 15–16 widget nhỏ chỉ có một vùng chạm (`widgetURL`), không có `Link` riêng.
- Android: `RemoteViews.setOnClickPendingIntent` trên từng view, broadcast tới `BroadcastReceiver` của app (minSdk 24, chạy mọi bản).
- Extension iOS và receiver Android **không có Firebase SDK**, nên không ghi Firestore được. Phải gọi một endpoint HTTPS của mình.
- Hạ tầng có sẵn: `sendToRecipientDevices(..., {wakeClients})`, `firebaseMessagingBackgroundHandler` → `HomeWidgetStatus.fromPush` → `HomeWidgetBridge.sendStatus` (widget-today), plugin `packages/dear_embeiu_widget_channel` (chạy được trong engine nền Android), `WidgetStore` Android, App Group iOS.

## 3. Phạm vi (scope)

- **Trong phạm vi (v1):**
  - **Tim ở Home** (cặp `active`): chạm = gửi 1 lần nhớ, có rung nhẹ + tim nảy. Cạnh tim là số đếm hôm nay.
  - **Nút tim trên widget** iOS 17+ (cả 2 cỡ) và Android (cả 2 provider `DayCounterWidget` 2×2 + `DayCounterWidgetMedium` 4×2): chạm là gửi, không mở app, widget phản hồi ngay.
  - **Người nhận:** push gộp 1 dòng (cập nhật số lần thay vì chồng thông báo) · dòng trạng thái widget-today loại mới `poke` · số đếm trên Home cập nhật realtime · đang mở app thì rung + tim bay, không hiện banner.
  - **1 mục inbox gộp mỗi ngày mỗi người gửi.**
  - **Công tắc** "Báo khi người ấy chạm tim" ở Cài đặt → Thông báo (mặc định bật).
  - Cloud Functions: 1 endpoint HTTPS + 1 callable quản lý token. Rules additive.
  - Analytics, vi + en.
- **Ngoài phạm vi (ghi roadmap):** "Chạm tay cùng lúc" (Phase 2) · nhiều loại chạm (ôm, hôn, vỗ vai) · biểu đồ "tuần này nhớ nhau 52 lần" · widget màn khoá iPhone / Apple Watch / Live Activity / ô Cài đặt nhanh Android · giờ im lặng (user chốt: đêm vẫn báo) · nút tim trên widget iOS 15–16 · App Check cho endpoint.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý. D1–D2 là user chốt; còn lại PO chốt.

- **D1 — Gửi được từ Home và từ nút tim trên widget; chạm widget là gửi thẳng, không mở app** (user chốt 2026-10-20). *Lý do:* "1 chạm" chỉ đúng khi không phải mở app.

- **D2 — Đêm vẫn báo bình thường, không có giờ im lặng** (user chốt 2026-10-20). *Lý do:* người nhận tự tắt bằng công tắc D11 hoặc chế độ Tập trung của máy.

- **D3 — Mỗi chạm đều đếm; một doc đếm theo ngày, không phải doc mỗi lần chạm.**
  ```
  couples/{coupleId}/pokes/{YYYY-MM-DD}      // ngày theo giờ máy NGƯỜI GỬI
    date: 'YYYY-MM-DD'
    counts:   { <uid>: int }        // số lần mỗi người chạm trong ngày (FieldValue.increment)
    lastAt:   { <uid>: timestamp }  // lần chạm cuối của mỗi người
    viaWidget:{ <uid>: int }        // số lần đến từ widget (đo metric, không phải analytics)
    requests: { <uid>: int }        // số request trong ngày (rate limit D9)
    pushAt:   { <uid>: timestamp }  // lần cuối CF gửi push cho người nhận của uid này (cooldown)
    pushes:   { <uid>: int }        // số push đã gửi thay uid trong ngày (trần D9)
    wakeAt:   { <recipientUid>: timestamp } // lần cuối đánh thức máy người nhận (D7)
    updatedAt: timestamp
  ```
  CHỈ Cloud Function ghi (Admin SDK). *Lý do:* chạm 30 lần/ngày thành 30 doc là phí đọc khi Home cần mỗi con số; 1 doc/ngày đọc bằng 1 `get`/listener, không cần index, dễ đếm metric. Không cần lịch sử từng lần chạm.

- **D4 — Mọi lần gửi đi qua MỘT endpoint HTTPS `pokePartner`, kể cả từ app.** App, widget iOS, widget Android cùng gọi `POST` với `Authorization: Bearer <pokeToken>` và body `{"taps": 1..20, "date": "YYYY-MM-DD"}`. Trả `200 {"ok":true,"mine":N,"partner":M}` hoặc mã lỗi chung (D10). *Lý do:* một đường duy nhất cho đếm, rate limit, push; app không cần đường ghi Firestore riêng ⇒ rules chỉ có `read`, không có rule ghi phải test.

- **D5 — Token bí mật theo thiết bị (`pokeToken`), Firestore chỉ lưu hash.**
  - Callable `managePokeToken({action: 'register'|'revoke', installId})`: `register` sinh 32 byte ngẫu nhiên (base64url), lưu `pokeTokens/{sha256hex}` = `{uid, installId, createdAt, lastUsedAt}`, xoá token cũ cùng `uid + installId`, giữ tối đa 5 token/uid (xoá cũ nhất), trả bản rõ **một lần**. `revoke` xoá token của `uid + installId`.
  - `installId` = UUID sinh 1 lần/lần cài, lưu cạnh token.
  - Bản rõ nằm ở: iOS App Group `UserDefaults` (khoá `poke_token`, cả app lẫn widget đọc); Android SharedPreferences riêng `dear_embeiu_poke` (loại khỏi backup trong `backup_rules.xml` + `data_extraction_rules.xml`). Flutter đọc/ghi qua kênh `dear_embeiu/widget` (method mới `setPokeToken`/`getPokeToken`).
  - App gọi `register` khi: couple `active` mà máy chưa có token, sau mỗi lần đăng nhập, và khi endpoint trả `401`.
  - Endpoint kiểm ở **mỗi request**: token tồn tại → `users/{uid}.coupleId` → couple `status == 'active'`, `uid in memberIds`, `memberCount == 2`. Rời couple ⇒ token tự vô dụng, ghép lại thì dùng được ngay (vẫn là người đó, máy đó).
  - *Lý do:* extension/receiver không có Firebase Auth; để refresh token Firebase trong App Group là trao chìa khoá cả tài khoản cho widget. Token này chỉ làm được đúng một việc: gửi tim cho người ấy.

- **D6 — Thông báo gộp thành một dòng.** Push alert có `apns-collapse-id: "poke"` (iOS) và `android.notification.tag: "poke"` + kênh Android mới `pokes` (rung bật, importance high). Push sau thay push trước, số trong câu tăng dần. `sendToRecipientDevices` thêm `options.collapseId` + `options.channelId` (mặc định giữ như cũ ⇒ caller cũ không đổi hành vi).
  Copy push (gửi cho người kia; `{name}` = tên người gửi, `{n}` = số lần người gửi chạm hôm nay, `{total}` = tổng cả hai):

  | | vi | en |
  |---|---|---|
  | title, n = 1 | `{name} vừa nhớ bạn 💗` | `{name} is thinking of you 💗` |
  | body, n = 1 | `Chạm tim để gửi lại một cái nhé.` | `Tap the heart to send one back.` |
  | title, n ≥ 2 | `{name} nhớ bạn {n} lần rồi 💗` | `{name} thought of you {n} times 💗` |
  | body, n ≥ 2 | `Hôm nay chúng mình nhớ nhau {total} lần.` | `{total} hearts between you two today.` |

  `data`: `type:'poke'`, `actorName`, `date`, `count` (= n), `total`, `sentAt` (ms), cộng `lang` (đã có). Tap push → Home (tab 0), không cuộn.
  *Lý do:* chạm 5 lần mà 5 thông báo chồng nhau là spam; một dòng tự cập nhật vẫn cho người nhận biết "đang được nhớ nhiều".

- **D7 — Đánh thức máy người nhận có ngưỡng: tối đa 1 lần/15 phút/người nhận.** CF chỉ thêm `wakeClients: true` khi `now − wakeAt[recipient] ≥ 15 phút`, rồi ghi `wakeAt`. Ngoài khoảng đó vẫn gửi alert bình thường (banner + rung), chỉ không đánh thức app. Hệ quả: lần chạm đầu của một đợt làm widget người nhận đổi ngay ("Tuấn vừa nhớ mình"); các lần sau trong 15 phút có thể làm số trên widget trễ tới lần đánh thức kế hoặc lần mở app.
  *Ước lượng:* cặp bình thường 5–20 lần chạm/ngày, dồn thành vài đợt ⇒ ~3–8 lần đánh thức/ngày, ≤4/giờ. Cùng chung "ngân sách vài lần/giờ" của iOS với 5 loại push widget-today; vẫn trong ngưỡng.
  *Lý do:* iOS chỉ cho đánh thức app ở nền vài lần/giờ; đốt hết vào tim thì push câu hỏi/tâm trạng sau đó không cập nhật được widget.

- **D8 — Người nhận thấy gì:**
  - **Widget-today, loại trạng thái mới `poke`** (đi theo luật D3 widget-today "mới nhất thắng", không có ngoại lệ): `statusTarget = home`, `statusFocus = ''`.

    | | vi | en |
    |---|---|---|
    | `statusText`, n = 1 | `{name} vừa nhớ mình` | `{name} is thinking of you` |
    | `statusText`, n ≥ 2 | `{name} nhớ mình {n} lần hôm nay` | `{name} thought of you {n} times today` |
    | `statusTextShort`, n = 1 | `{name} nhớ mình` | `{name} misses you` |
    | `statusTextShort`, n ≥ 2 | `{name} nhớ mình {n} lần` | `{name} misses you ×{n}` |

    Đánh đổi chấp nhận: lần chạm sau có thể đè "Tuấn đã trả lời, đến lượt mình". Chạm widget vẫn về Home, nơi thẻ câu hỏi nằm sẵn.
  - **Số đếm cạnh nút tim trên widget** (khoá riêng, không phải dòng trạng thái): `pokeDate`, `pokeMine`, `pokePartner`. Widget hiện tổng hôm nay nếu > 0, so ngày như D4.1 widget-today (qua 0:00 về 0). Method kênh mới `updatePoke(Map<String,String>)`; `update` với `state=empty` xoá luôn các khoá này.
  - **Home:** listener `couples/{id}/pokes/{hôm nay}` → số đếm realtime. Số của người ấy tăng khi app đang mở → rung (`HapticFeedback`) + tim bay ngắn ≤1 giây (Reduce Motion: chỉ đổi số), **không** hiện banner hệ thống (`_handleForegroundMessage` bỏ qua type `poke`).
  - **Inbox:** 1 doc/ngày/người gửi, id cố định `poke_{date}_{senderUid}` trong `users/{recipient}/notifications`, CF upsert `{type:'poke', actorName, count, date, read:false, createdAt: now}` mỗi lần có push. Hiển thị: `{name} nhớ bạn {count} lần hôm nay` / `{name} thought of you {count} times today`. Tap → Home.
  *Lý do inbox 1 mục/ngày:* mỗi lần một mục là spam; không có mục nào thì người tắt push không biết đã được nhớ.

- **D9 — Chống lạm dụng (endpoint):**
  - `taps` mỗi request 1..20 (app gộp các chạm trong 1,5 giây thành 1 request; widget mỗi chạm 1 request).
  - Trần request: 300 request/ngày/người gửi (`requests.{uid}`); quá trần → `429`, không đếm.
  - Push: cooldown **10 giây**/người gửi (`pushAt`) và trần **60 push/ngày**/người gửi (`pushes`). Trong cooldown hoặc quá trần vẫn đếm, vẫn upsert inbox, chỉ không push.
  - `date` phải lệch ≤ 1 ngày so với ngày UTC của server, sai → `400`.
  - Function chạy `maxInstances: 5`, `concurrency` mặc định; ghi doc ngày bằng transaction.
  *Lý do:* chặn script bắn liên tục làm tốn tiền và làm máy người kia kêu không dứt, mà người dùng bình thường không bao giờ chạm tới trần.

- **D10 — Endpoint không lộ gì.** URL không chứa uid/coupleId. Lỗi chỉ trả `{"ok":false}` kèm mã HTTP: `401` (token sai/thu hồi) · `403` (chưa ghép/couple không active) · `429` (rate limit) · `400` (body sai). Không log bản rõ token, không log body. Chỉ nhận `POST` + `Content-Type: application/json`. *Lý do:* endpoint public trên internet; không cho dò uid hay biết token nào đang sống ngoài 401.

- **D11 — Công tắc "Báo khi người ấy chạm tim"** ở Cài đặt → Thông báo, mặc định bật, lưu theo thiết bị: field `pushPoke` (bool, optional) trong `users/{uid}/devices/{id}`, map `poke: "pushPoke"` vào `PUSH_TYPE_PREF_FIELD`. Tắt ⇒ CF bỏ qua thiết bị đó (không alert, không đánh thức); vẫn đếm, inbox vẫn có, Home/widget cập nhật khi mở app. `NotificationSettingsService.currentOrDefault` đọc giá trị thật cho riêng `pushPoke` (3 khoá cũ vẫn ép bật như quyết định 2026-06-14).
  *Lý do:* tim là loại push duy nhất mà tần suất do người kia quyết; không có công tắc thì người thấy phiền sẽ tắt hết thông báo của app ở cài đặt hệ thống, mất luôn push câu hỏi hằng ngày. *(Đi ngược một phần quyết định 2026-06-14 "không có công tắc từng loại" — xem câu hỏi Q1.)*

- **D12 — Nút tim trên widget:**
  - **iOS 17+**: `Button(intent: SendPokeIntent())` trên cả `systemSmall` và `systemMedium` (khối `if #available(iOSApplicationExtension 17.0, *)`). `perform()`: tăng `pokeMine` + ghi `poke_pending` trong App Group trước, rồi gọi endpoint (timeout 8 giây); thành công thì ghi `mine/partner` server trả về và xoá pending. Chạm không làm mở app. Vùng chạm ≥ 44×44 pt.
  - **iOS 15–16**: **không có nút tim**, widget giữ bố cục hiện tại. *Lý do:* widget nhỏ iOS < 17 chỉ có một vùng chạm (đang dùng để mở app theo trạng thái); "chạm tim mở app rồi mới gửi" không còn là 1 chạm. Máy kẹt ở iOS < 17 (iPhone 8/X) còn rất ít.
  - **Android** (cả 2 provider): view tim riêng, `setOnClickPendingIntent` → `PendingIntent.getBroadcast` (`FLAG_IMMUTABLE`) tới receiver mới `PokeReceiver` (`exported=false`). Receiver: tăng `pokeMine` + pending trong prefs, `DayCounterWidget.updateAll` ngay, rồi `goAsync()` + `HttpsURLConnection` (timeout 8 giây). ⚠️ `applyStyle` phải đặt đủ thuộc tính tim ở mọi nhánh (bài học launcher reapply). Vùng chạm ≥ 48dp.
  - **Phản hồi:** số tăng + tim đổi trạng thái trong ≤1 giây kể cả mạng chậm (lạc quan). Mất mạng → giữ `poke_pending {date, taps}`; lần chạm kế hoặc lần mở app gửi bù (app đọc pending qua kênh). Pending của ngày cũ: vẫn gửi với `date` cũ nếu còn trong ngưỡng D9, quá thì bỏ.
  - Widget chỉ hiện tim khi snapshot có `pokeEnabled = '1'` (couple `active` + có token). Chưa ghép, đăng xuất, gallery preview → không có tim.
  - Bố cục/vị trí do Designer chốt (D16). Dev làm spike trước: iOS 17 `Button(intent:)` gọi mạng trong extension xong timeline có vẽ lại kịp không; Android receiver gọi mạng khi app đã bị kill.

- **D13 — Thu hồi token:** đăng xuất → app xoá bản rõ ở máy (luôn chạy được, kể cả offline) + gọi `revoke` (cố gắng, lỗi thì bỏ qua) + `updatePoke` rỗng. Xoá tài khoản → `deleteAccount` xoá mọi `pokeTokens` có `uid` đó. Rời couple → không cần thu hồi (endpoint kiểm membership mỗi lần, D5). Token không dùng 60 ngày → CF dọn (để Phase 2 nếu chưa kịp; endpoint vẫn kiểm membership nên token cũ không gây hại).

- **D14 — Rules (CHỈ ADDITIVE):**
  ```
  match /couples/{coupleId}/pokes/{date} {
    allow read: if isCoupleMember(coupleId);
    allow write: if false;            // chỉ Cloud Functions
  }
  match /pokeTokens/{hash} {
    allow read, write: if false;      // chỉ Cloud Functions
  }
  // isValidDeviceDocument: thêm 'pushPoke' vào hasOnly
  //   && data.get('pushPoke', true) is bool
  ```
  App 1.10.x/1.11.0 không gửi `pushPoke` ⇒ `.get(..., true)` vẫn hợp lệ. Không đổi rule nào đang có.

- **D15 — Mixed version:** app cũ nhận push `poke` → hệ thống tự hiện banner (FCM alert), chạm mở Home: chấp nhận được, người dùng bản cũ vẫn biết mình được nhớ. Inbox type lạ: `AppNotificationType.unknown` → tab Home; Dev kiểm cách bản 1.11.0 vẽ item `unknown`, nếu vỡ/trống thì ghi nợ (không chặn release). App cũ không có tim nên không gửi được.

- **D16 — Thiết kế do Designer chốt chung cả đợt** (Home đã dày: CounterCard, thẻ câu hỏi, tâm trạng, "Phân vân gì không?", giấc ngủ, chòm sao). Đề xuất của PO, Designer được đổi:
  - Home: tim + số nằm trên `CounterCard` (cạnh tên hai người), không thêm thẻ mới.
  - Widget: tim ở góc dưới phải; số tổng nhỏ cạnh tim. Bản nhỏ không được đẩy lệch số ngày; khi có dòng trạng thái thì tim nhường chỗ ra sao do Designer quyết.
  - Bắt buộc: tra UI UX Pro Max (luật 8), vùng chạm ≥44pt/48dp, nhãn trợ năng `Gửi nhớ thương tới {name}` / `Send {name} a heart`, chế độ tinted iOS 18, cỡ chữ AX, Reduce Motion.

- **D17 — Phát hành:** đợt "mở app mỗi ngày" lần 2 (cùng 4 feature còn lại). DEV: `scripts/test-firebase-rules.sh` → deploy rules + `functions:pokePartner,functions:managePokeToken` + các hàm đổi (`deleteAccount`). PROD: deploy đích danh khi phát hành, **chờ lệnh user**; rules + CF PROD phải lên trước khi bản mới live.

## 5. Mô tả kỹ thuật cho Dev (điểm cắm)

- **Flutter:**
  - `PokeService` (gọi endpoint bằng `http`/`HttpClient` có sẵn, gộp chạm 1,5 giây, đọc/ghi pending, đăng ký token qua callable) + `PokeProvider` (listener doc ngày hôm nay, số `mine/partner`, phát hiện số người ấy tăng). Wire ở `session_resolver` khi couple active, clear khi sign-out/no-couple (nhớ named-param `_resolve`). Tự đổi ngày bằng `MidnightBuilder`/timer như các thẻ khác.
  - `HomeWidgetStatus`: thêm kind `poke` vào `kinds`, nhánh `case 'poke'` trong `fromPush` (dùng `count`), nhánh trong `build` từ provider (so `lastAt[partner]` với các mốc khác theo D3 widget-today).
  - `HomeWidgetBridge`: thêm `updatePoke`, `setPokeToken`/`getPokeToken`/`takePokePending`; snapshot thêm `pokeEnabled`.
  - `push_notification_service`: `_handleForegroundMessage` bỏ banner cho `poke`; handler nền gọi `updateStatus` (đã có qua `fromPush`) + `updatePoke` (partner = `count`, mine giữ nguyên).
  - Settings: công tắc D11. Analytics D18. ARB vi + en + `gen-l10n`.
- **iOS** (`ios/DearEmbeiuWidget/`): `SendPokeIntent: AppIntent` (file mới, chỉ biên dịch iOS 17), `PokeStore` đọc/ghi App Group (token, pending, counts), nút tim trong `SmallCounter`/`MediumCounter` (`DayCounterView.swift`). `DayEntry` thêm `poke` (counts theo ngày). Kênh `HomeWidgetChannel` (`AppDelegate.swift`) thêm 4 method trên. Endpoint URL (DEV/PROD khác nhau) đặt qua build setting → Info.plist như `APP_GROUP_ID`.
- **Android** (`android/app/src/main/kotlin/com/tony/dearembeiu/widget/`): `PokeReceiver` (file mới) + khai báo manifest; `WidgetStore` thêm đọc/ghi poke; layout `widget_day_small.xml`/`widget_day_medium.xml` thêm view tim; `applyStyle` đặt đủ thuộc tính tim. Plugin `packages/dear_embeiu_widget_channel` (`WidgetChannelPlugin.java`) thêm 4 method để chạy được trong engine nền. Endpoint URL theo flavor/build type (DEV khi debug, PROD khi release).
- **Cloud Functions** (`functions/index.js`): `exports.pokePartner = onRequest({maxInstances: 5}, …)` · `exports.managePokeToken = onCall(…)` · `sendToRecipientDevices` thêm `options.collapseId`/`options.channelId` · `PUSH_TYPE_PREF_FIELD.poke = "pushPoke"` · `POKE_COPY` vi/en · upsert inbox id cố định (helper riêng, không đổi `writeInboxNotifications`) · `deleteAccount` xoá `pokeTokens` theo uid; kiểm `deleteAccount`/`leaveCoupleCleanup` liệt kê subcollection hay xoá đệ quy, liệt kê thì thêm `pokes`.
- **Tần suất ước lượng (CF):** cặp bình thường ~10–40 request/ngày/cặp, ~5–15 push/ngày/cặp, ~3–8 lần đánh thức/ngày/người nhận. Trần cứng/người gửi/ngày: 300 request, 60 push; đánh thức ≤ 4/giờ/người nhận.

## 6. Acceptance criteria (xong khi…)
> Kiểm trên 2 máy với cặp DEV `test3`/`test4` (1 iPhone iOS 17+ thật hoặc simulator, 1 Android 14/16). Ghi số đo thật vào `test.md`.

- [ ] **Home gửi:** A chạm tim 1 lần → máy B (app nền) nhận push "A vừa nhớ bạn 💗" trong ≤10 giây; số trên Home A tăng ngay khi chạm (≤300ms, kể cả mất mạng).
- [ ] **Gộp thông báo:** A chạm thêm 4 lần cách nhau >10 giây → B chỉ thấy **1** thông báo trong trung tâm thông báo hệ thống, nội dung cuối "A nhớ bạn 5 lần rồi 💗"; inbox của B có đúng 1 mục hôm nay ghi 5 lần.
- [ ] **Cooldown:** A chạm 10 lần trong 5 giây → Firestore đếm đúng 10, B nhận ≤ 2 push.
- [ ] **Widget iOS 17+:** chạm tim trên widget nhỏ và vừa → app **không** mở; số trên widget tăng ≤1 giây; B nhận push ≤10 giây.
- [ ] **Widget Android:** như trên với cả 2×2 và 4×2, kể cả khi app A đã bị vuốt tắt khỏi Recents.
- [ ] **Offline:** tắt mạng máy A, chạm widget 3 lần → widget A hiện +3; bật mạng rồi chạm 1 lần (hoặc mở app) → Firestore đếm đủ 4, không mất, không đếm trùng.
- [ ] **Widget người nhận:** B để app nền, A chạm lần đầu trong đợt → dòng trạng thái widget B đổi thành "A vừa nhớ mình" trong ≤60 giây (iOS được trễ khi hệ thống hoãn, ghi rõ). Mở app B → widget khớp số Home trong ≤2 giây.
- [ ] **Đánh thức có ngưỡng:** A chạm 20 lần trong 15 phút → log CF cho thấy đúng 1 push có `wakeClients` tới B.
- [ ] **Foreground:** B đang mở Home, A chạm → B rung + tim bay, số tăng ≤3 giây, **không** có banner.
- [ ] **Công tắc:** B tắt "Báo khi người ấy chạm tim" → A chạm, B không có push; mở app B vẫn thấy số đúng + inbox có mục. Bật lại → có push.
- [ ] **Không ghép / thu hồi:** cặp `waiting_partner` không thấy tim ở Home lẫn widget. A đăng xuất → widget A mất tim; gọi endpoint bằng token cũ → `401`. A rời couple → token cũ trả `403`. Xoá tài khoản → không còn doc `pokeTokens` nào của uid đó.
- [ ] **Bảo mật endpoint:** token rác → `401` `{"ok":false}`; `GET` → bị từ chối; `taps` = 0 hoặc 21 → `400`; `date` lệch 3 ngày → `400`; request thứ 301 trong ngày → `429`. Response và log không chứa uid/coupleId/token.
- [ ] **Qua 0:00:** chỉnh giờ qua nửa đêm → số trên Home và widget về 0 (iOS đúng 0:00, Android ≤30 phút), dòng trạng thái `poke` biến mất.
- [ ] **Chạm widget có trạng thái `poke`** → mở Home; `widget_tap` log `status_kind: poke`.
- [ ] **Mixed version:** máy B chạy 1.11.0 → vẫn nhận banner push, không crash; mở inbox không crash.
- [ ] **Rules:** `scripts/test-firebase-rules.sh` PASS với case mới: thành viên đọc được `pokes`, người ngoài bị chặn; client ghi `pokes` bị chặn; mọi đọc/ghi `pokeTokens` bị chặn; device doc có/không có `pushPoke` đều hợp lệ, `pushPoke: "x"` bị chặn.
- [ ] **CF:** test emulator cho `pokePartner` (đếm, cooldown, trần, đánh thức 15 phút, membership, lỗi chung) và `managePokeToken` (register thay token cũ cùng installId, giữ ≤5, revoke). Deploy DEV có vết; PROD chưa deploy.
- [ ] i18n vi + en đủ (Home, widget, push, inbox, Cài đặt, nhãn trợ năng); `flutter analyze` 0; test Dart cho `fromPush` loại `poke` và gộp chạm 1,5 giây; `scripts/check-widget-daymath.sh` + JUnit Android vẫn PASS.
- [ ] Không regression: widget 1.11.0 (dòng trạng thái 9 loại cũ, chạm mở đúng chỗ), Home, Cài đặt thông báo.

## 7. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)

- 🎨 **Designer:** chốt vị trí tim + số trên Home (đề xuất: trên `CounterCard`) chung với 4 feature cùng đợt; nút tim + số trên 4 bố cục widget (iOS nhỏ/vừa, Android 2×2/4×2) × nền trời đêm / nền ảnh × có/không dòng trạng thái; trạng thái đã gửi/đang chờ mạng; hiệu ứng nhận khi đang mở app; công tắc Cài đặt. Tra UI UX Pro Max. → *expect:* `design.md` + mock bấm thử.
- 💻 **Dev:** spike D12 trước (iOS 17 intent gọi mạng · Android receiver khi app bị kill) rồi làm theo §5; rules + test; CF + test emulator; deploy DEV. → *expect:* nhánh feature, analyze 0, rules-test PASS, smoke 2 máy DEV.
- 🧪 **Tester:** 19 tiêu chí §6; soi endpoint như kẻ tấn công (dò token, replay, `date` giả, flood); offline/pending; qua ngày; mixed version. → *expect:* bảng PASS/FAIL + số đo trong `test.md`.

## 8. Nợ kỹ thuật / rủi ro (Tester soi)

- 🔴 **iOS force-quit:** máy người nhận bị vuốt tắt thì không được đánh thức; banner vẫn tới nhưng widget đứng số cũ tới khi mở app (giống widget-today).
- 🟡 **Ngân sách đánh thức iOS** chia chung với 5 loại push widget-today; ngưỡng 15 phút giảm rủi ro nhưng không loại bỏ.
- 🟡 **Token nằm trong App Group / SharedPreferences:** máy đã root/jailbreak hoặc bản sao lưu iCloud (App Group không loại khỏi backup được) lấy được token ⇒ chỉ gửi được tim cho người ấy của chủ máy, trong trần D9. Chấp nhận.
- 🟡 **Endpoint chưa có App Check** (extension khó lấy token App Attest). Rate limit + `maxInstances` giới hạn chi phí khi bị flood bằng token rác (mỗi request rác tốn 1 lần đọc Firestore).
- 🟡 **Cặp yêu xa lệch múi giờ:** doc ngày theo giờ máy người gửi; người nhận ở múi khác có thể thấy số "hôm nay" thiếu/thừa quanh nửa đêm. Giống câu hỏi hằng ngày, chấp nhận.
- 🟡 **Dòng trạng thái `poke` đè trạng thái quan trọng hơn** (vd "đến lượt mình trả lời") vì luật "mới nhất thắng". Theo dõi `widget_tap` theo `status_kind`; nếu tỉ lệ cặp trả lời câu hỏi giảm sau khi có poke thì cân nhắc xếp `poke` ưu tiên thấp.
- 🟡 **Đếm trùng khi mất phản hồi:** request tới server thành công nhưng máy không nhận được trả lời (timeout) thì pending vẫn giữ và lần sau gửi lại ⇒ đếm dư vài lần. Chấp nhận ở v1 (không ai thiệt); nếu thấy lệch nhiều thì thêm `nonce` cho mỗi đợt pending để CF bỏ qua bản lặp.
- 🟡 **Android hãng Trung Quốc** chặn mạng của receiver khi app bị giết ⇒ chạm tim vào pending, gửi bù khi mở app.
- 🟢 **Riêng tư:** màn hình chính chỉ lộ "nhớ mình N lần", không có chữ người dùng viết.

## 9. Metric thành công

- **Chính:** % cặp active có ≥1 lần chạm tim mỗi ngày (đếm doc `pokes/{date}` bằng script đọc-only kiểu `scripts/prod-retention-stats.js`). Mục tiêu 30 ngày sau phát hành: ≥50%.
- **Vòng qua lại:** % ngày-cặp mà **cả hai** cùng chạm (`counts` có 2 uid > 0). Mục tiêu: ≥30%.
- **Widget có tác dụng:** `viaWidget / counts` ≥ 40% (người ta thật sự chạm ngay ở màn hình chính).
- **Kéo về app:** số cặp có người mở app mỗi ngày (nền 7–16/28) và số cặp cả hai trả lời câu hỏi (nền 3–5), so 2 tuần trước/sau.
- **Bảo vệ:** tỉ lệ tắt công tắc D11 < 10% thiết bị; không tăng số user tắt thông báo hệ thống (`notificationsEnabled == false`).

## 10. Analytics (không gửi nội dung riêng tư: không tên, không uid người ấy, không token)

- `poke_send{source: 'home', taps}` — app gửi (sau gộp).
- `poke_pending_flush{taps, age_hours}` — app gửi bù pending từ widget.
- `poke_receive_foreground{}` — nhận khi đang mở app.
- `poke_push_open{}` — mở app từ push `poke` (thêm vào đường tap push đang có).
- `poke_setting_toggle{enabled}`.
- Chạm tim trên widget không log được ở native (không có Firebase SDK) ⇒ đo bằng `viaWidget` trong Firestore. `widget_tap` đã có, thêm giá trị `status_kind: 'poke'`.

## 11. Câu hỏi cho user

- **Q1 — Công tắc tắt thông báo tim (D11).** Ngày 2026-06-14 app đã bỏ hết công tắc tắt từng loại thông báo ("cặp đôi luôn nhận mọi push"). PO đề xuất thêm lại MỘT công tắc riêng cho tim, mặc định bật, vì tim là loại duy nhất mà số lượng do người kia quyết (có thể 30 cái/ngày, cả ban đêm). Đồng ý thêm, hay giữ nguyên "không công tắc"?
- **Q2 — iOS 15–16 không có nút tim trên widget (D12).** PO bỏ vì widget nhỏ iOS dưới 17 chỉ có một vùng chạm và "mở app rồi gửi" không còn là 1 chạm. Những máy này vẫn chạm tim được trong app. Chấp nhận không?

## 12. Changelog feature
- [2026-10-20] [PO] Tạo feature `poke` trong đợt "mở app mỗi ngày" lần 2 (user chọn 5 hướng: poke · caro-game · weather · arrival · expenses). User chốt D1 (gửi từ Home + widget, không mở app) và D2 (đêm vẫn báo). PO chốt D3–D17: doc đếm theo ngày + endpoint HTTPS duy nhất bằng token thiết bị lưu hash; push gộp `collapse-id`/`tag`; đánh thức ≤1 lần/15 phút/người nhận; loại trạng thái widget `poke` theo luật "mới nhất thắng"; inbox 1 mục/ngày/người gửi; iOS 15–16 không có tim trên widget. Mở 2 câu hỏi Q1 (công tắc) + Q2 (iOS < 17). Chờ user duyệt spec.
