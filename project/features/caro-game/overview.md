# Cờ caro theo lượt (caro-game)

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Xây trên hạ tầng [rps-game](../rps-game/overview.md) (collection `games`, presence, cooldown do CF ghi, `NotificationTapRouter`). Đợt "mở app mỗi ngày" lần 2 (user chọn 2026-10-20), làm cùng [poke](../poke/), [weather](../weather/), [arrival](../arrival/), [expenses](../expenses/).

- **Feature:** caro-game
- **Ưu tiên:** P1 (đợt "mở app mỗi ngày" 2)
- **Trạng thái:** 📋 Spec — chờ user duyệt
- **Tạo ngày:** 2026-10-20
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · trạng thái widget ở [`../widget-today/`](../widget-today/overview.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:* số liệu PROD ngày 2026-10-19 (`scripts/prod-retention-stats.js`): 28 cặp đã ghép, mỗi ngày chỉ 7–16 cặp có người mở app, 3–5 cặp cả hai trả lời câu hỏi. 8 cặp cả hai cùng mở app mà không ai trả lời: họ có mặt nhưng không có việc gì nhẹ để làm cùng nhau. Oẳn tù tì xong trong 5 giây và cần cả hai cùng online, nên không tạo ra lý do quay lại lần hai trong ngày.
- *Tình huống thật:* 8 giờ sáng Tuấn đặt quân giữa bàn trên xe bus. 10 giờ Thảo thấy thông báo "Tuấn vừa đi một nước", chặn một đường rồi đi làm tiếp. Giờ nghỉ trưa Tuấn mở app, thấy đường chéo của Thảo sắp thành 4. Tối về hai người cùng mở, đi qua lại 6 nước liên tục, Thảo thắng ở nước 31. Một ván, 5 lần mở app, không ai phải viết câu nào.
- *Giả thuyết giá trị:* mỗi nước đi tạo ra đúng một lý do để người kia mở app. Ván caro trung bình 25–40 nước, chia đôi là 12–20 lần mở app mỗi người cho một ván kéo dài cả ngày. Khác câu hỏi hằng ngày, đi một nước chỉ tốn 2 chạm và không cần nghĩ chữ.
- *Đối tượng:* cặp đã ghép đôi. Cặp còn chờ người ấy (52/80 cặp) không thấy gì: chơi một mình không có nghĩa (D14).
- *Đo bằng gì (metric):* xem §9.

## 2. Bối cảnh / nghiên cứu

- Caro (gomoku) là trò hai người quen thuộc nhất với người Việt, chơi trên giấy ô ly từ cấp 2. Không phải dạy luật. Luật "chặn hai đầu" là luật dân gian phổ biến: năm quân liền nhưng hai đầu đều bị quân đối phương chặn thì không tính thắng.
- Mô hình "game theo lượt bất đồng bộ" (Words With Friends, cờ vua thư trên Chess.com) giữ chân bằng đúng cơ chế này: thông báo "đến lượt bạn" là lời mời quay lại có nội dung riêng, không phải nhắc nhở chung chung.
- Hạ tầng đã có (đọc code 2026-10-20): collection `couples/{id}/games` + 2 composite index (`type,status,finishedAt↓` và `type,status,createdAt↓`), hàm rules `rpsPresenceTouchesOnlyOwnKey()` (`firestore.rules:821`), mẫu callable có cooldown do CF ghi (`nudgeRpsPlayer`, `functions/index.js:2453`), mẫu push bỏ qua người đang xem màn (presence), `NotificationTapRouter.focusRpsGame` + `pendingRpsGameId`, `sendToRecipientDevices(..., {wakeClients})`.

### 2.1 Kiểm tương thích: app 1.10.x / 1.11.0 gặp doc `games` có `type: 'caro'`

| Chỗ | Hành vi hiện tại | Kết luận |
|---|---|---|
| Listener ván đang mở (`lib/services/rps_game_service.dart:388-397`) | `.where('type', isEqualTo: 'rps')` + `status in [invited, playing]` | Không thấy doc caro. Cửa sổ `limit 5` không bị doc caro chiếm chỗ. An toàn. |
| Tỉ số + lịch sử rps (`rps_game_service.dart:693-702`, `:730-733`) | lọc `type == 'rps'` | Không đếm nhầm ván caro. An toàn. |
| `RpsGame.fromFirestore` (`lib/models/rps_game.dart:479-482`) | thiếu `type` thì mặc định `'rps'` | Chỉ chạy trên kết quả query đã lọc type, hoặc `watchGame(gameId)` mở từ push/inbox loại `rps_*`. Caro dùng loại push riêng `caro_*` nên không đi vào đây. An toàn. |
| Push tap loại lạ (`lib/services/push_notification_service.dart:664`) | nhánh `default` → không làm gì | App cũ chạm push `caro_*` chỉ mở app ở tab đang đứng. Chấp nhận. |
| Inbox loại lạ (`lib/models/app_notification.dart:79` → `notification_center_screen.dart:486`) | `unknown` → "Bạn có thông báo mới" | App cũ hiện câu chung chung cho lời mời caro. Chấp nhận (có ở cả tag `v1.10.1+30`). |
| CF `notifyRpsInvite` (`functions/index.js:2197`) | `if (game.type !== "rps" ...) return;` | Bỏ qua doc caro. An toàn. |
| CF `resolveRpsGame` (`functions/index.js:2346`) | trigger `games/{gameId}/moves/{uid}`, **không** kiểm `type` | Caro **không được** dùng subcollection `moves` (D1). Thêm guard `type` (§6.2). |
| CF `nudgeRpsPlayer` (`functions/index.js:2453`) | không kiểm `type`; gọi với id ván caro → không có `moves` → trả `not_moved` | Vô hại, vẫn thêm guard `type` cho sạch. |
| Rules create `games` (`firestore.rules:891`) | bắt `type == 'rps'` | Client không tạo được doc caro. Đúng ý: chỉ CF tạo (D5). |
| Rules update `games` (`firestore.rules:900-904`) | `hasOnly` danh sách khoá rps | Doc caro có `cells`, `players`, `turnUid`… ngoài danh sách ⇒ mọi update theo nhánh rps bị từ chối. Thêm guard `type` cho rõ (§6.1). |
| Rules create `moves` (`firestore.rules:936-950`) | chỉ bắt cha `playing` + có `startedAt` | Doc caro không có `startedAt` ⇒ không tạo được move rps dưới ván caro. Thêm guard `type` cho chắc (§6.1). |
| Dọn dữ liệu (`functions/index.js:3012`) | người cuối rời couple → `recursiveDelete` cả couple | `games` + `caroState` đi theo. Không cần thêm. |

**Kết luận:** app 1.10.x/1.11.0 bỏ qua doc caro an toàn; chỗ hở duy nhất là trigger `resolveRpsGame` theo đường dẫn `moves`, đã tránh bằng D1 và guard ở CF mới.

## 3. Phạm vi (scope)

- **Trong phạm vi (bản đầu):**
  - Bàn 15×15, luật Việt Nam (5 liên tiếp, chặn hai đầu không tính), người rủ đi trước cầm X.
  - Rủ ván = đi luôn nước đầu. Người kia đi tiếp hoặc từ chối.
  - Đi theo lượt, không giới hạn thời gian mỗi nước. Chơi realtime khi cả hai cùng mở; chơi rải rác cả ngày khi không.
  - Push "đến lượt bạn", bỏ qua khi người ấy đang xem ván, gộp 1 thông báo/ván trên khay.
  - Nhắc người ấy (cooldown 30 phút), xin thua, huỷ ván chưa ai đáp, kết thúc ván treo 7 ngày.
  - Tỉ số tổng "Tuấn 12 – 9 Thảo" + lịch sử ván + xem bàn cuối của ván cũ.
  - Trạng thái `caro_turn` trên widget-today.
  - 1 callable `caroAction`, rules additive (presence + đọc `caroState`), option `collapseId` cho `sendToRecipientDevices`. vi + en.
- **Ngoài phạm vi (ghi roadmap):** tua lại từng nước của ván cũ · chơi với máy · bàn mở rộng vô hạn · luật tự do / bật-tắt luật · nhiều ván song song · đồng hồ mỗi nước · xin hoà · đi lại nước (undo) · chat trong ván · sticker/âm thanh · bảng xếp hạng.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý. Các mục PO tự chốt user lật được trước khi Dev bắt đầu.

- **D1 — Dùng chung `games` với `type: 'caro'`; cả ván nằm trong 1 doc, KHÔNG có subcollection `moves`.** Nước đi lưu thành mảng `cells` (số ô theo thứ tự). *Lý do:* tái dùng 2 index sẵn có, hàm presence của rules, đường push tap. Bàn 15×15 tối đa 225 số nguyên, doc chưa tới 3 KB. Tránh đường dẫn `moves` vì trigger `resolveRpsGame` bắt mọi doc dưới đó mà không kiểm loại (§2.1).

- **D2 — Bàn 15×15 cố định.** *Lý do:* chuẩn gomoku, đủ chỗ cho 5 liên tiếp và các thế chặn. Bàn mở rộng khiến toạ độ, lưu trữ, xem lại và kiểm hợp lệ đều phức tạp, trong khi ván cặp đôi hiếm khi tràn bàn. Màn điện thoại 360 dp chia 15 ô còn ~22 dp/ô, nhỏ hơn vùng chạm 44 pt, nên giải bằng phóng to + chạm 2 bước (D19).

- **D3 — Luật Việt Nam, một luật duy nhất ở bản đầu:** 5 quân trở lên liền nhau theo hàng ngang, dọc hoặc chéo thì thắng, **trừ khi hai đầu dãy đều là quân đối phương**. Mép bàn không tính là chặn. 6 quân trở lên vẫn thắng nếu không bị chặn hai đầu. Kín 225 ô mà chưa ai thắng thì hoà. Doc ghi `rule: 'vn'` để sau này thêm luật khác mà không phải đoán ván cũ chơi luật gì. *Lý do:* người Việt quen luật này từ giấy ô ly; nó cũng giảm lợi thế của người đi trước. Không làm công tắc bật/tắt vì mỗi lựa chọn thêm là một câu phải giải thích, và hai người phải thống nhất trước khi chơi. *(PO tự chốt — xem câu hỏi §11.)*

- **D4 — Người rủ đi trước, cầm X. Lời mời chính là nước đầu.** Không có bước "chấp nhận". Người được rủ thấy bàn có sẵn 1 quân và đi luôn, hoặc bấm "Để sau" (huỷ, D7). Ván sau ai bấm "Ván mới" thì người đó đi trước. *Lý do:* chơi bất đồng bộ thì mỗi vòng chờ là nửa ngày; bỏ bước chấp nhận cắt một vòng. Người thua thường là người muốn phục thù, nên tự nhiên được đi trước.

- **D5 — Mọi thay đổi ván đi qua 1 callable `caroAction`; client chỉ được ghi `presence` của chính mình.** CF kiểm lượt, ô trống, số thứ tự nước, tính thắng/hoà bằng hàm thuần có unit test, ghi kết quả + tỉ số trong transaction. *Lý do:* chống được cả 4 kiểu gian lận (đi hộ lượt, đặt đè ô, sửa nước cũ, tự xưng thắng) ở một chỗ duy nhất. Rules để kiểm "đúng 1 ô mới, đúng lượt, có thắng không" thì vừa dài vừa không tính nổi đường thắng. Gộp 6 thao tác vào 1 function: chung một lần khởi động lạnh, một tên khi deploy. *Đánh đổi:* mỗi nước chờ callable, ước lượng 0,3–1 giây khi đang ấm, 1–3 giây khi lạnh ⇒ client hiện quân tạm ngay khi bấm (D12).

- **D6 — Mỗi cặp 1 ván đang chơi. Con trỏ ván + tỉ số nằm ở doc `caroState/main`, chỉ CF ghi.** *Lý do:* hai người cùng bấm "Ván mới" một lúc thì transaction trên doc cố định chặn được ván thứ hai; query trong transaction không khoá được "chưa có ván nào". Tỉ số đọc 1 doc thay vì 3 lần `count()` như rps.

- **D7 — Không giới hạn thời gian mỗi nước. Ba cách kết thúc ngoài thắng/hoà:**
  - **Xin thua:** người chơi bấm bất cứ lúc nào → người kia thắng, có tính tỉ số.
  - **Huỷ ("Để sau"):** chỉ khi bàn mới có ≤1 quân (người được rủ chưa đi). Ai trong hai người cũng huỷ được. Không tính tỉ số, không vào lịch sử, không push.
  - **Kết thúc ván treo:** 7 ngày không ai đi → ai cũng bấm được "Kết thúc ván" → `expired`, không tính tỉ số, không vào lịch sử. Một trong hai người không còn trong couple → ván coi như `expired` ngay khi có người gọi `start`.
  *Lý do:* user muốn "một ván kéo dài cả ngày"; đếm giờ mỗi nước sẽ phạt đúng người bận. Nhưng nếu người ấy bỏ ngang, mình không được kẹt mãi (bài học rps: ván `playing` treo chặn rủ ván mới, Phase 2 rps chưa giải).

- **D8 — Bốn loại push, gộp 1 thông báo/ván, bỏ qua người đang xem ván:**
  - `caro_invite` (rủ + nước đầu): push **+ inbox**.
  - `caro_turn` (người kia vừa đi, chưa kết thúc): push, **không inbox**.
  - `caro_nudge` (nhắc người ấy): push, không inbox.
  - `caro_result` (thắng / xin thua / hoà): push, không inbox (giống `rps_result`; lịch sử là bản ghi).
  - Người nhận có presence < 45 giây trên doc ván → không push (họ thấy nước đi ngay trên màn).
  - Mọi push của một ván dùng chung khoá gộp `caro_{gameId}`: Android `notification.tag`, iOS header `apns-collapse-id`. Khay thông báo chỉ giữ thông báo mới nhất của ván, không chồng 15 cái "vừa đi một nước". Thêm option `collapseId` vào `sendToRecipientDevices` (caller không truyền thì như cũ).
  *Lý do:* nước đi rải rác cả ngày thì chồng thông báo là spam. Inbox chỉ giữ lời mời vì đó là thứ cần nhớ; lượt đi đã có thẻ Home + widget nói hộ.

- **D9 — `wakeClients` chỉ cho `caro_invite` + `caro_turn`, tối đa 1 lần/30 phút/người nhận/ván.** CF ghi `lastWakeAt.{uid}` trong transaction; trong 30 phút đã đánh thức thì vẫn gửi push thường, chỉ bỏ cờ đánh thức. *Lý do:* để widget hiện "Thảo đã đi caro, đến lượt mình" khi app tắt. Ước lượng: ván 30 nước, mỗi người nhận ≤15 push/ván. Push chỉ đi khi người nhận rời màn, và người nhận phải mở app mới đi được nước tiếp, nên tự nhiên không có 2 push `caro_turn` liên tiếp tới cùng một người mà họ chưa mở app. Ngưỡng 30 phút giữ số lần đánh thức ≤2/giờ, ≤~10/ngày kể cả khi hai người đi nhanh mà cứ thoát màn. Cộng với các loại khác của đợt (chat, mood, poke, arrival…) vẫn nằm trong mức iOS cho phép "vài lần/giờ"; Lead cộng tổng khi gộp đợt.

- **D10 — Nhắc người ấy: cooldown 30 phút, tính từ mốc sau cùng giữa nước mình vừa đi và lần nhắc trước.** Chỉ người **không** tới lượt mới nhắc được. *Lý do:* push `caro_turn` đã đi ngay khi mình đi nước; nhắc sau 60 giây như rps là giục. Trong 30 phút nút hiện giờ còn lại ("Nhắc được sau 12 phút").

- **D11 — Presence: heartbeat 20 giây, xoá khi rời màn hoặc app xuống nền; coi là "đang xem" khi < 45 giây.** Ghi vào `presence.{uid}` của doc ván, dùng lại hàm `rpsPresenceTouchesOnlyOwnKey()`. *Lý do:* cùng nhịp với chat (`chatActiveAt` 20 s / 45 s). Nhịp 3 giây của rps phục vụ đếm ngược 5 giây; caro không cần, 20 giây giảm ~85% số lần ghi.

- **D12 — Realtime khi cả hai cùng mở:** client nghe doc ván; nước người kia hiện ngay khi callable ghi xong (mục tiêu ≤2 giây trên DEV). Nước của mình hiện quân mờ ngay khi bấm "Đi", chuyển đậm khi CF trả `ok`, rút lại + báo lỗi khi CF từ chối hoặc mất mạng. Presence người kia tươi → dòng nhỏ "Thảo đang xem ván". *Lý do:* chờ 1–3 giây mới thấy quân của chính mình thì cảm giác như app đơ.

- **D13 — Tỉ số + lịch sử + xem bàn cuối.** Đầu màn caro và màn lịch sử hiện "Tuấn 12 – 9 Thảo" (+ "3 ván hoà" nếu có), lấy từ `caroState/main`. Lịch sử = các ván `finished`, mới nhất trước, 30 ván/trang (index `type,status,finishedAt↓` sẵn có). Mỗi dòng: ngày, ai thắng, thắng kiểu gì (5 quân / xin thua / hoà), số nước. Chạm một dòng → bàn cuối tĩnh, tô đường thắng, đánh dấu nước cuối. *Lý do:* bàn cuối dựng lại từ `cells` gần như miễn phí, và "nhìn lại ván thua đau" là chuyện cặp đôi thích kể. Tua từng nước để Phase 2.

- **D14 — Cặp đang chờ người ấy: ẩn hoàn toàn.** Không thẻ, không tile, callable trả `no_partner`. *Lý do:* caro cần đúng 2 người; nhất quán với rps (`home_screen.dart:2106` chỉ hiện `RpsInviteCard` khi `!couple.isWaitingForPartner`). Cặp chờ đã có thẻ checklist mời người ấy.

- **D15 — Điểm vào (đề xuất; Designer chốt chung cả đợt vì Home đã dày):**
  - **Home:** gộp `RpsInviteCard` hiện có thành một thẻ "Chơi cùng nhau" 2 dòng: Oẳn tù tì · Cờ caro. Dòng caro đổi theo trạng thái: chưa có ván ("Rủ người ấy một ván"), đến lượt mình (nổi bật + chấm, "Đến lượt bạn · nước 14"), chờ người ấy ("Đang chờ Thảo · nước 14"), vừa kết thúc ("Thảo thắng ván vừa rồi · Phục thù"). Không thêm thẻ thứ hai vào Home.
  - **Profile:** huy hiệu tỉ số caro cạnh huy hiệu oẳn tù tì, chấm đỏ khi đến lượt mình.
  - **Push / inbox / widget:** mở thẳng `CaroGameScreen` của ván đó.
  - Nếu Designer giữ thẻ rps riêng thì caro vào cùng vị trí đó, không lên trên khối "Hôm nay của chúng mình".

- **D16 — Widget-today thêm `statusKind: caro_turn`** khi người ấy vừa đi và đang là lượt mình (copy §7). Chạm widget → `statusTarget: home`, `statusFocus: caro` → mở ván. Chỉ báo việc đã xảy ra (đúng D4.2 widget-today). Mình đi xong thì Home đẩy lại trạng thái, dòng này biến mất.

- **D17 — Analytics không chứa nội dung riêng tư** (§8). Số nước, kết quả, nguồn mở là số/enum; không gửi toạ độ ô, tên, uid.

- **D18 — Phát hành:** bản MINOR kế sau 1.11.0 cùng đợt (Lead chốt số bản). DEV: Dev deploy rules + `caroAction` + bản cập nhật `sendToRecipientDevices`/guard rps. PROD: `deploy --project prod --only firestore:rules,functions:caroAction,functions:resolveRpsGame,functions:nudgeRpsPlayer,functions:notifyPartnerLeft` **chờ lệnh user**; rules PROD lên trước khi app live. Bản cũ chỉ thấy câu inbox chung chung (§2.1) và không chơi được tới khi cập nhật; `autoStoreForce` lo việc ép cập nhật.

- **D19 — Ràng buộc UX bàn cờ cho Designer** (Designer tự chọn hình, phải giữ hành vi): chạm 2 bước (chạm ô → quân mờ + nút "Đi" / chạm lại cùng ô; chạm ô khác thì đổi chỗ) vì đi nhầm không có đường lui · phóng to bằng hai ngón 1×–2,5×, lúc mở ván tự cuộn tới nước cuối · đánh dấu rõ nước cuối của người kia · tô đường thắng khi kết thúc · X/O mang màu riêng của mỗi người (`lib/theme/person_palette.dart`, đã dùng ở feature sleep) nhưng vẫn phân biệt được bằng hình X/O cho người mù màu · Semantics mỗi ô ("Hàng 8, cột 8, quân X của Tuấn" / "trống") · Reduce Motion tắt hiệu ứng đặt quân.

- **D20 — Rời couple:** CF `notifyPartnerLeft` xoá `caroState/main` (ván cũ của người rời không đè tỉ số của người mới ghép sau). Ván đang chơi tự `expired` khi gọi `start` (D7). Client lọc lịch sử chỉ hiện ván mà cả hai `players` là thành viên hiện tại.

## 5. Mô hình dữ liệu (CHỐT — Dev bám theo)

### 5.1 `couples/{coupleId}/games/{gameId}` với `type == 'caro'` (autoId, CHỈ CF tạo/sửa, trừ `presence`)

| field | kiểu | ghi chú |
|---|---|---|
| `type` | `'caro'` | bất biến |
| `rule` | `'vn'` | bất biến (D3) |
| `size` | `15` | bất biến |
| `createdBy` | uid | người rủ = người đi trước |
| `createdAt` | timestamp | server |
| `players` | map `{x: uid, o: uid}` | `x == createdBy` |
| `status` | `'playing' \| 'finished' \| 'cancelled' \| 'expired'` | không có `invited` (D4) |
| `cells` | list<int> | ô = `row * 15 + col` (0..224), theo thứ tự đi; chỉ số chẵn = X, lẻ = O; không trùng |
| `turnUid` | uid | người phải đi tiếp; giữ nguyên khi kết thúc |
| `lastMoveAt` / `lastMoveBy` | timestamp / uid | |
| `presence` | map `{uid: timestamp}` | **client** ghi key của mình (D11) |
| `result` | map? `{winnerUid: uid\|null, reason: 'five'\|'resign'\|'full', line: list<int>}` | `line` = các ô của đường thắng (chỉ khi `five`) |
| `finishedAt` | timestamp? | khi `finished` |
| `endedBy` | uid? | người xin thua / huỷ / kết thúc ván treo |
| `lastNudgeAt` | timestamp? | cooldown D10 |
| `lastWakeAt` | map? `{uid: timestamp}` | ngưỡng D9 |
| `rematchOf` | gameId? | ván trước (CF dùng presence ván trước để bỏ push) |
| `updatedAt` | timestamp | |

### 5.2 `couples/{coupleId}/caroState/main` (CHỈ CF ghi)
`{ openGameId: gameId | null, wins: {uid: int}, draws: int, updatedAt }`. Ván `expired`/`cancelled` không cộng gì.

### 5.3 Không đụng
Không subcollection dưới ván caro. Không thêm field vào doc `couples/{id}` (rules của couple có `hasOnly`, thêm field dễ làm app cũ ghi lỗi). Không thêm index (dùng 2 index rps sẵn có).

## 6. Rules + Cloud Functions

### 6.1 Rules (chỉ ADDITIVE; field optional đọc bằng `.get(...)`)

```
// trong match /couples/{coupleId}
match /games/{gameId} {
  // read: giữ nguyên (member) — áp cả doc caro.
  // create: giữ nguyên (chỉ 'rps') ⇒ client không tạo được ván caro.
  // update nhánh rps: thêm guard đầu  resource.data.get('type', 'rps') == 'rps'
  //   (không đổi gì với doc rps hiện có; chỉ khoá doc loại khác khỏi nhánh này)
  allow update: if isCoupleMember(coupleId)
    && resource.data.get('type', '') == 'caro'
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['presence'])
    && rpsPresenceTouchesOnlyOwnKey();
}
match /games/{gameId}/moves/{uid} {
  // create: thêm  rpsGame().get('type', 'rps') == 'rps'
}
match /caroState/{docId} {
  allow read: if isCoupleMember(coupleId);
  allow write: if false;
}
```
Hai guard `type` chỉ khoá loại doc chưa từng tồn tại, không ảnh hưởng app 1.10.x/1.11.0. Rules-test mới ≥15 case: người ngoài không đọc được ván/`caroState` · client không tạo doc `type:'caro'` · client không sửa `cells`/`turnUid`/`status`/`result`/`players`/`lastNudgeAt`/`lastWakeAt` · ghi presence của người kia bị chặn · xoá cả map presence bị chặn · presence không phải `request.time` bị chặn · tạo `moves` dưới ván caro bị chặn · ghi `caroState` bị chặn · delete ván bị chặn · toàn bộ suite rps cũ vẫn PASS.

### 6.2 Cloud Functions (`functions/index.js`, v2, us-central1)

**`caroAction`** — callable `{coupleId, op, gameId?, cell?, moveNo?, rematchOf?}`. Auth + member. Couple phải có đúng 2 `memberIds`, không thì `{ok:false, reason:'no_partner'}`. Lỗi nghiệp vụ trả `{ok:false, reason}`, không throw (giống `nudgeRpsPlayer`); lỗi hệ thống throw `HttpsError` có câu vi/en theo `lang` (quy ước 2026-10-11).

| op | Điều kiện (trong transaction trên `caroState/main` + doc ván) | Ghi | Push sau commit |
|---|---|---|---|
| `start` | `cell` 0..224. `openGameId` trỏ ván `playing` có đủ 2 player là thành viên → `{ok:false, reason:'already_open', gameId}`. Ván cũ có player không còn là thành viên → đánh `expired` | tạo ván `playing`, `cells:[cell]`, `players.x = caller`, `turnUid = partner`; `openGameId = ván mới` | `caro_invite` + inbox tới partner; bỏ qua nếu `rematchOf` có presence partner < 45 s hoặc partner đã có presence trên ván mới |
| `move` | ván `playing`; caller `== turnUid`; `moveNo == cells.length` (chống bấm 2 lần và màn cũ); ô trong bàn và chưa có | append; tính thắng (D3) / kín bàn; thắng → `finished` + `result` + `wins[caller]++` + `openGameId = null`; hoà → `draws++`; còn lại → `turnUid = partner` | đối thủ có presence ≥ 45 s hoặc vắng: `caro_turn` hoặc `caro_result` |
| `resign` | ván `playing`; caller là player | `finished`, `result{winnerUid: partner, reason:'resign'}`, `endedBy`, `wins[partner]++`, `openGameId = null` | `caro_result` (resign) tới partner nếu rời màn |
| `cancel` | ván `playing`; `cells.length <= 1`; caller là player | `cancelled`, `endedBy`, `openGameId = null` | không |
| `expire` | ván `playing`; `lastMoveAt` cũ hơn 7 ngày | `expired`, `endedBy`, `openGameId = null` | không |
| `nudge` | ván `playing`; caller **không** phải `turnUid`; `now − max(lastMoveAt, lastNudgeAt) ≥ 30'` → không thì `{reason:'cooldown', retryAfterMs}` | `lastNudgeAt` | `caro_nudge` tới `turnUid` (bất kể presence) |

Trả về: `{ok:true, gameId, status, cellsLength}` hoặc `{ok:false, reason: 'not_playing'|'not_your_turn'|'stale'|'occupied'|'out_of_range'|'already_open'|'cooldown'|'too_early'|'not_player'|'no_partner'}`.

- Hàm thuần `caroWinner(cells, size, rule) → {winner:'x'|'o'|null, line, full}` tách riêng, test bằng node (không cần emulator): 5 ngang/dọc/chéo xuôi/chéo ngược · 4 quân không thắng · 5 bị chặn 2 đầu không thắng · 5 bị chặn 1 đầu thắng · 5 sát mép (mép không tính chặn) thắng · 6 quân không bị chặn thắng · 6 quân bị chặn 2 đầu không thắng · kín bàn = hoà · chỉ xét đường qua nước vừa đi.
- **Ghép option vào `sendToRecipientDevices`:** `options.collapseId` → `android.notification.tag` + `apns.headers['apns-collapse-id']` (≤64 byte). Không truyền thì payload y như cũ.
- **Ngưỡng `wakeClients` (D9):** trong transaction của `start`/`move`, nếu `now − lastWakeAt[recipient] ≥ 30'` thì ghi `lastWakeAt.{recipient} = now` và gửi với `wakeClients: true`; không thì gửi push thường.
- Push `data`: `{type, coupleId, gameId, moveNo, actorName}`. Không gửi `date`: handler nền lấy ngày theo giờ máy lúc nhận (múi giờ CF không phải múi giờ người dùng). Tên để thô, fallback "Người ấy" / "Your partner" theo ngôn ngữ thiết bị như `rps`.
- **Guard thêm cho rps:** `resolveRpsGame` và `nudgeRpsPlayer` đọc doc cha, `type` khác `'rps'` thì bỏ qua / trả `not_playing`.
- **`notifyPartnerLeft`:** thêm xoá `caroState/main` (D20).
- Chi phí: 1 lần gọi/nước. Ván 30 nước × ~28 cặp × 1 ván/ngày ≈ 850 lần gọi/ngày, xa dưới hạn mức miễn phí 2 triệu/tháng. Không dùng `minInstances` (tốn tiền thường trực).

### 6.3 Copy push (vi / en) — `{name}` = tên người gửi, `{n}` = số nước

| type | vi title | vi body | en title | en body |
|---|---|---|---|---|
| `caro_invite` | {name} rủ chơi cờ caro | Nước đầu đã đi rồi, giờ đến lượt bạn. | {name} started a game of caro | They made the first move. Your turn. |
| `caro_turn` | {name} vừa đi một nước | Đến lượt bạn. Ván đang ở nước {n}. | {name} made a move | Your turn. The game is on move {n}. |
| `caro_nudge` | {name} đang đợi bạn đi | Ván caro dừng ở nước {n}. Vào đi một nước nhé. | {name} is waiting for your move | Your caro game is paused at move {n}. |
| `caro_result` (người nhận thua) | {name} thắng ván caro | Năm quân liền một hàng ở nước {n}. Phục thù không? | {name} won the caro game | Five in a row on move {n}. Rematch? |
| `caro_result` (người kia xin thua) | {name} xin thua ván caro | Ván này bạn thắng. Thêm ván nữa không? | {name} resigned | You win this one. Another game? |
| `caro_result` (hoà) | Ván caro hoà | Kín cả bàn mà chưa ai thắng. | The caro game is a draw | The board filled up and nobody won. |

Inbox `caro_invite`: `{type, coupleId, gameId, actorUserId, actorName?}`; dòng hiện "{name} rủ chơi cờ caro" / "{name} started a game of caro". Chưa có công tắc tắt riêng (như `care_message`, `rps_invite`); đưa vào Phase 2.

## 7. Client (tóm tắt cho Dev, Designer chốt hình)

- Model `CaroGame` (+ `CaroResult`), hàm thuần `CaroBoard` dựng bàn từ `cells` (dùng chung cho màn chơi + xem lại; có test). Service `caro_game_service.dart` (watch `caroState/main`, watch ván, heartbeat/clear presence, gọi `caroAction`, trang lịch sử). Provider `caro_game_provider.dart`, wire watch ở `session_resolver` khi couple active (nhớ thêm **cả** named-param của `_resolve` lẫn call site), clear khi đăng xuất / không còn couple.
- Màn `CaroGameScreen(gameId?)` các trạng thái: chưa có ván (bàn trống, "Đặt quân đầu tiên để rủ người ấy") · đến lượt mình · chờ người ấy (+ "Thảo đang xem ván" khi presence tươi, + nút Nhắc khi đủ 30') · đang gửi nước (quân mờ) · lỗi/mất mạng ("Chưa đi được, thử lại", giữ ô đã chọn) · đã kết thúc (kết quả, đường thắng, "Ván mới", "Lịch sử") · ván treo ≥7 ngày ("Kết thúc ván") · người ấy dùng app cũ (sau 24 giờ người được rủ chưa đi: dòng gợi ý nhỏ "Nếu người ấy chưa thấy ván, có thể app cần cập nhật"). Menu: Xin thua (hỏi lại 1 lần) · Để sau/Huỷ (chỉ khi ≤1 quân).
- Màn `CaroHistoryScreen`: tỉ số + danh sách 30/trang + empty state ("Chưa có ván nào xong. Ván đầu tiên đang chờ đó.") + chạm xem bàn cuối.
- Push tap + Notification Center tap (**sửa đủ 2 chỗ** như rps): `caro_invite`/`caro_turn`/`caro_nudge` → mở ván (`NotificationTapRouter` thêm `focusCaroGame` + `pendingCaroGameId`); `caro_result` → mở ván đó ở trạng thái kết thúc. Push tới khi đang mở đúng ván đó → không hiện banner trong app.
- Feature tour: thêm 1 mục `sinceBuild` của bản phát hành.
- i18n: mọi chuỗi vào `app_en.arb` + `app_vi.arb` rồi `gen-l10n`; xưng "chúng mình" khi nói về cả hai, không "hai đứa"; dấu kiểu mới.

### 7.1 Widget-today (feature [widget-today](../widget-today/overview.md))

| `statusKind` | Khi nào | vi | en | vi rút gọn (bản nhỏ) | en rút gọn | Chạm mở |
|---|---|---|---|---|---|---|
| `caro_turn` | người ấy vừa đi (hôm nay) và đang là lượt mình | `{name} đã đi caro, đến lượt mình` | `{name} moved in caro, your turn` | `Lượt mình đi caro` | `Your caro move` | Home → mở ván (`statusFocus: caro`) |

Đường app mở: bridge lắng nghe `CaroGameProvider`, `statusAt = lastMoveAt` (mới nhất thắng theo D3 widget-today). Đường nền: handler nền map push `caro_turn`/`caro_invite` có `wakeClients`. Không tạo trạng thái cho `caro_result` (kết quả đã nằm trong thông báo).

## 8. Analytics (snake_case, không nội dung riêng tư)

| event | params | ghi chú |
|---|---|---|
| `caro_open` | `source`: `home` · `profile` · `push` · `inbox` · `widget` | mở màn ván |
| `caro_game_started` | `rematch` (bool) | sau khi `start` ok |
| `caro_move` | `move_no` (int), `partner_watching` (bool) | sau khi `move` ok; `partner_watching` = presence người kia tươi ⇒ đo tỉ lệ chơi realtime vs rải rác |
| `caro_game_ended` | `result`: `win` · `lose` · `draw` · `resign_me` · `resign_partner` · `cancel` · `expired`; `moves` (int); `span_hours` (int, làm tròn) | log ở máy người thấy kết thúc lần đầu |
| `caro_nudge_sent` | — | |
| `caro_history_open` | — | |

Không log ô đã đi, tên, uid, gameId.

## 9. Metric thành công (đo sau 30 ngày phát hành)

- **Chính:** số cặp có ≥1 nước caro/ngày ÷ cặp active. Mục tiêu ≥25%.
- **Lần mở app:** trong các ngày có ván caro, tỉ lệ cặp mà **cả hai** cùng mở app ≥70% (nền hiện tại: 3–5/28 cặp cả hai trả lời câu hỏi). Đo bằng `caro_move` theo user + `scripts/prod-retention-stats.js` (Dev thêm đếm doc `games` type caro có `lastMoveAt` hôm nay).
- **Bất đồng bộ thật:** trung vị `span_hours` của ván xong ≥3 giờ; tỉ lệ `caro_move` có `partner_watching=false` ≥50%. Nếu gần như toàn realtime thì caro chỉ là rps thứ hai, không đạt mục tiêu "mỗi nước một lần mở app".
- **Hoàn thành ván:** `finished` ÷ (`finished` + `expired` + `cancel`) ≥60%.
- **Push kéo người về:** `caro_open{source:push|widget}` ÷ số push `caro_turn` gửi (log CF) ≥35%.

## 10. Acceptance criteria (kiểm trên 2 máy DEV, cặp `test3`/`test4`)

- [ ] Cặp `test1` (chờ người ấy): không có thẻ, tile, huy hiệu caro; gọi callable trả `no_partner`.
- [ ] Tuấn đặt quân đầu → ván tạo `playing`, Thảo nhận push `caro_invite` + 1 item inbox; chạm push mở đúng ván, bàn có 1 quân X.
- [ ] Hai người cùng bấm "Ván mới" trong 1 giây → chỉ 1 ván tồn tại; máy còn lại được mở vào ván đó.
- [ ] Đi không đúng lượt, đặt ô đã có quân, gửi `moveNo` cũ (bấm 2 lần nhanh) → CF từ chối, bàn không đổi, client rút quân mờ và báo lỗi bằng câu l10n.
- [ ] Cả hai cùng mở ván: nước của người này hiện trên máy người kia ≤2 giây; không có push nào được gửi (kiểm log CF); dòng "đang xem ván" hiện đúng.
- [ ] Thảo thoát app, Tuấn đi → Thảo nhận `caro_turn`; Tuấn đi tiếp được KHÔNG (không phải lượt); Thảo đi 3 nước rải rác trong ngày → khay thông báo của mỗi máy chỉ còn **1** thông báo cho ván đó (Android + iOS).
- [ ] Thắng 5 ngang, 5 dọc, 5 chéo đều kết thúc đúng; 5 quân bị chặn hai đầu **không** kết thúc; 5 quân sát mép kết thúc. Đường thắng được tô trên cả 2 máy; tỉ số tăng đúng người.
- [ ] Xin thua → người kia thắng, tỉ số tăng; huỷ khi bàn 1 quân → không tính tỉ số, không vào lịch sử; huỷ khi bàn 2 quân bị từ chối.
- [ ] Ván không ai đi 7 ngày (seed `lastMoveAt` cũ) → nút "Kết thúc ván" hiện, bấm → `expired`, rủ được ván mới.
- [ ] Nhắc người ấy: ngay sau khi đi bị khoá và hiện thời gian còn lại; sau 30 phút gửi được 1 push; bấm lần 2 trả `cooldown` (kiểm cả client lẫn server).
- [ ] Lịch sử: seed 35 ván → trang đầu 30, kéo tải thêm 5; chạm ván cũ ra bàn cuối đúng; ván huỷ/hết hạn không có trong danh sách; empty state đúng.
- [ ] Widget-today: Thảo để app ở nền, Tuấn đi → widget Thảo hiện "Tuấn đã đi caro, đến lượt mình" (ghi số giây thực đo); đi nước thứ 2 trong vòng 30 phút → push vẫn tới nhưng không có cờ đánh thức (log CF); chạm widget mở đúng ván.
- [ ] Rời couple khi đang có ván → người ở lại không thấy ván cũ trên Home; `caroState/main` đã bị xoá.
- [ ] App 1.11.0 cài song song nhận push `caro_*` không crash; inbox hiện "Bạn có thông báo mới"; tỉ số + lịch sử oẳn tù tì không đổi.
- [ ] Rules: `scripts/test-firebase-rules.sh` PASS, đủ ≥15 case §6.1, suite rps cũ không đổi kết quả. Test node cho `caroWinner` đủ 10 case §6.2.
- [ ] `flutter analyze` 0; test Dart cho `CaroBoard` + map push → trạng thái widget; VoiceOver/TalkBack đọc được ô; Reduce Motion tắt hiệu ứng đặt quân.
- [ ] Không gửi nội dung riêng tư vào analytics (Tester grep param).
- [ ] CF deploy DEV có vết; PROD chưa deploy cho tới lệnh phát hành.

## 11. Câu hỏi cho user

1. **Luật "chặn hai đầu" mặc định BẬT, không có công tắc** (D3). Nếu hai bạn quen chơi luật tự do (cứ 5 quân là thắng), nói để PO đổi trước khi Dev bắt đầu; đổi chỉ là một hằng trong CF.

Mọi điểm khác PO đã tự chốt kèm lý do ở §4.

## 12. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)

- 🎨 **Designer:** chốt điểm vào chung của đợt 2 (thẻ "Chơi cùng nhau" hay giữ thẻ rps), màn ván 7 trạng thái §7, bàn 15×15 theo D19, sheet kết quả, màn lịch sử + bàn cuối, huy hiệu Profile; copy vi/en trong app. Tra UI UX Pro Max (luật 8) + `project/design-system.md`. → *expect:* `design.md` + mock bấm thử.
- 💻 **Dev:** (1) `caroWinner` + `caroAction` + option `collapseId` + guard rps + `notifyPartnerLeft` + rules + rules-test + deploy DEV; (2) model/service/provider + wire `session_resolver`; (3) màn ván, lịch sử, điểm vào; (4) push tap 2 chỗ + inbox type mới; (5) widget-today `caro_turn` (bridge + handler nền); (6) analytics + feature tour. → *expect:* analyze 0, test PASS, rules-test PASS, DEV deployed.
- 🧪 **Tester:** 18 tiêu chí §10; soi gian lận qua callable (gọi thẳng bằng uid khác, `moveNo` sai, ô ngoài bàn, người ngoài couple); 2 máy cùng `start`; offline giữa lúc đi; app 1.11.0 song song. → *expect:* bảng PASS/FAIL trong `test.md`.

## 13. Nợ kỹ thuật / rủi ro

- 🟡 **Độ trễ callable** khi lạnh 1–3 giây/nước. Đã có quân mờ (D12). Nếu Tester đo thấy khó chịu khi chơi realtime, cân nhắc `minInstances: 1` (tốn tiền thường trực, phải hỏi user).
- 🟡 **Hạn mức đánh thức nền iOS** dùng chung với widget-today, poke, arrival… Ngưỡng D9 giữ caro ≤2 lần/giờ; Lead cộng tổng cả đợt.
- 🟡 **Người ấy dùng app cũ:** nhận push nhưng không chơi được tới khi cập nhật. Có dòng gợi ý sau 24 giờ; `autoStoreForce` ép cập nhật khi bản mới live.
- 🟡 **iOS force-quit / Android hãng Trung Quốc:** không đánh thức được ⇒ widget không đổi, push thường vẫn tới.
- 🟡 **Lợi thế người đi trước:** luật chặn hai đầu giảm bớt nhưng không triệt tiêu. Theo dõi tỉ lệ thắng của người rủ; >65% thì Phase 2 cân nhắc luân phiên người đi trước.
- 🟡 **iOS 64 notification:** không thêm lịch local nào.
- 🟢 **Riêng tư:** push chỉ nói "vừa đi một nước", số nước, kết quả; không có nội dung người dùng gõ.
- 🟢 **Gian lận:** client không ghi được gì ngoài presence của mình.

## 14. Changelog feature
- [2026-10-20] [PO] Tạo feature trong đợt "mở app mỗi ngày" 2 (user chọn 5 hướng cùng lúc). Đọc code rps, kết luận app 1.10.x/1.11.0 bỏ qua doc `type:'caro'` an toàn, chỗ hở duy nhất là trigger `resolveRpsGame` theo đường `moves` (§2.1) ⇒ D1 không dùng `moves`. Chốt D1–D20: bàn 15×15, luật VN chặn hai đầu, lời mời = nước đầu, 1 callable `caroAction`, `caroState/main` giữ con trỏ + tỉ số, push gộp theo ván, `wakeClients` ≤1 lần/30'/người/ván, nhắc 30', presence 20 s/45 s, trạng thái widget `caro_turn`. 1 câu hỏi cho user (luật chặn hai đầu).
