# Hôm nay ăn gì? — cặp đôi chốt món mỗi ngày

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Ngân hàng món ăn (nội dung, PO sở hữu): [dish-bank.md](dish-bank.md).

- **Feature:** what-to-eat
- **Ưu tiên:** P0 (mục tiêu "mở app mỗi ngày", user đề xuất 2026-10-19: "user tự đề xuất món hoặc app gợi ý món")
- **Trạng thái:** 📋 Spec (chờ user duyệt rồi chạy pipeline Designer → Dev → Tester)
- **Tạo ngày:** 2026-10-19
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · [dish-bank.md](dish-bank.md) · widget hiện "Hôm nay ăn: …" ở [`../widget-today/`](../widget-today/overview.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:* "Tối nay ăn gì?" — "Tuỳ em." — "Tuỳ anh." Câu hỏi này cặp nào cũng hỏi nhau mỗi ngày, hỏi qua Zalo rồi trôi mất, và chưa app nào trong niche VN (Been Love Memory, Been Together) đứng ra làm trọng tài.
- *Giả thuyết giá trị:* app làm nơi chốt món của hai người. Một người quay món hoặc gõ món mình thèm, người kia nhận thông báo "Anh đề xuất Bún chả, chốt không?", bấm Chốt là xong. Mỗi ngày có một lý do thật, không gượng ép, để cả hai mở app — khác với câu hỏi hằng ngày (phải nghĩ để viết), chốt món chỉ mất 2 chạm. Món đã chốt dẫn thẳng sang "Chụp bữa này" → ảnh kỷ niệm (North Star).
- *Đối tượng:* cặp đã ghép đôi (vòng lặp đủ 2 người). Cặp còn chờ người ấy vẫn quay và chốt được một mình, lịch sử giữ lại cho tới khi người ấy vào.
- *Đo bằng gì (metric):*
  - % cặp active có ít nhất một `meals/{date}` mỗi ngày — mục tiêu sau 30 ngày: ≥40% cặp active dùng ≥3 ngày/tuần.
  - Tỉ lệ đề xuất được chốt trong 30 phút (vòng lặp 2 người có chạy không).
  - `meal_photo_cta` → ảnh được đăng (bao nhiêu bữa thành kỷ niệm).
  - Số cặp có người mở app mỗi ngày (chung với widget-today, `scripts/prod-retention-stats.js`).

## 2. Bối cảnh / nghiên cứu

- Số liệu PROD 2026-10-19: 28 cặp active, 7–16 cặp có người mở app mỗi ngày; 8 cặp cả hai mở hằng ngày nhưng bỏ qua câu hỏi (ngại viết). Việc cần làm là một thói quen rẻ hơn câu hỏi, mà vẫn phải có người thứ hai.
- Thói quen đã có sẵn trong đời: cặp đôi VN quyết bữa tối gần như mỗi ngày, thường 16:00–18:30; bữa trưa với người đi làm hay ăn riêng. Nên bản đầu nhắm **bữa chính trong ngày**, không tách trưa/tối.
- Tái dùng từ app: `care_message` (push nguyên văn + inbox), `rps-game` (`nudge` có cooldown, `lastNudgeAt` do CF ghi), `create_post` (đăng ảnh có caption), `care_timeline` (lịch sử phân trang 30/ngày), `MidnightBuilder` (vẽ lại lúc 0:00), gate `coupleActive` của nhắc câu hỏi.

## 3. Phạm vi (scope)

- **Trong phạm vi (bản đầu):**
  - Thẻ **"Hôm nay ăn gì?"** trên Home (sau thẻ tâm trạng), 3 trạng thái: chưa có gì · có đề xuất · đã chốt.
  - **Quay món:** app gợi ý ngẫu nhiên từ ngân hàng ≥100 món (`dish-bank.md`) + món hai người từng tự nhập; bộ lọc Tuỳ · Nhà nấu · Ăn ngoài · Nhanh gọn; loại món đã chốt trong 7 ngày.
  - **Mình đề xuất:** gõ tên món ≤40 ký tự, có gợi ý khi gõ.
  - **Chốt:** chốt đề xuất của bất kỳ ai, hoặc "Chốt luôn" ngay từ vòng quay. Chốt lại được (ăn trưa rồi tới tối).
  - **Thông báo cho người ấy:** đề xuất → push + inbox; chốt → push + inbox + đánh thức app (widget + huỷ nhắc).
  - **"Chụp bữa này"** → màn đăng ảnh, caption điền sẵn tên món.
  - **Lịch sử "Chúng mình đã ăn"** 90 ngày + "Món hay ăn" top 5.
  - **Nhắc local** một lần/ngày khi chưa chốt (mặc định 16:30, đổi/tắt được).
  - Rules additive + 2 Cloud Functions; vi + en.
- **Ngoài phạm vi (ghi roadmap):** tách trưa/tối thành 2 lượt rõ ràng · địa điểm/quán/bản đồ · công thức, nguyên liệu · AI gợi ý theo tủ lạnh/thời tiết · ngân sách · bình chọn nhiều người · kế hoạch món cả tuần · gắn ảnh với bữa (tag) · nhắc bữa sáng · rút lại/sửa đề xuất.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý. Mục nào user chưa xác nhận ghi *(PO tự chốt)* — user lật được trước khi Dev bắt đầu.

- **W1 — Một ngày một tài liệu `meals/{YYYY-MM-DD}`**, id = ngày giờ máy người ghi (`DailyQuestionService.dateKey`, cùng luật với câu hỏi; LDR lệch múi giờ chấp nhận như câu hỏi). Nhãn thẻ cố định "Hôm nay ăn gì?", không tách trưa/tối. Chốt được nhiều lần trong ngày; lịch sử ghi "Trưa" nếu chốt trước 15:00, "Tối" nếu sau. *(PO tự chốt)* *Lý do:* bữa tối là câu hỏi đau nhất; tách 2 lượt nhân đôi push và màn hình mà chưa có số liệu.

- **W2 — Đề xuất và chốt là hai subcollection create-only**, không ghi mảng trên tài liệu cha (hai người ghi cùng lúc không đè nhau, rules pin tác giả dễ, CF trigger tự nhiên):

```
couples/{coupleId}/meals/{date}
  date: 'YYYY-MM-DD'            // == id
  latestChoiceName?: string     // ≤40, bản sao để Home/lịch sử đọc 1 doc
  latestChoiceBy?: uid
  latestChoiceAt?: timestamp
  choiceCount?: int             // số lần chốt hôm nay (client tăng)
  lastMealPushAt?: timestamp    // CHỈ CF ghi (W5 cooldown)
  updatedAt: timestamp
couples/{coupleId}/meals/{date}/proposals/{autoId}
  authorUserId: uid (== auth)   name: string 1..40   source: 'bank'|'custom'|'history'
  bankId?: string               createdAt: == request.time
couples/{coupleId}/meals/{date}/choices/{autoId}
  byUserId: uid (== auth)       name: string 1..40   proposalId?: string
  source: 'proposal'|'spin'|'custom'   createdAt: == request.time
```
  Rules: thành viên đọc cả ba; `proposals`/`choices` chỉ create (tác giả pinned, `hasOnly`, độ dài, `createdAt == request.time`); `meals/{date}` create/update bởi thành viên với `hasOnly` đúng 7 khoá trên; `lastMealPushAt` chỉ CF ghi, client không được đổi (`!request.resource.data.diff(resource.data).affectedKeys().hasAny(['lastMealPushAt'])` — phải nằm trong `hasOnly` vì `request.resource.data` là tài liệu sau khi ghi, có cả khoá CF đã ghi trước đó), `date` khớp `^\d{4}-\d{2}-\d{2}$` và == id, `latestChoiceBy == auth.uid` khi có, `latestChoiceAt == request.time` khi có; không delete. Client ghi `choices` + merge cha trong **một batch**. Mỗi người tối đa 3 đề xuất/ngày và 4 lần chốt/ngày — chặn ở client (rules không đếm subcollection; CF không bắn push quá cooldown W5 nên spam vô hại).

- **W3 — Quay món = ngẫu nhiên thật, không lặp theo ngày.** Nguồn = ngân hàng `lib/data/dish_bank.dart` (sinh từ `dish-bank.md`, ≥100 món, mỗi món `id · vi · en · bữa[sang|trua|toi] · nơi[nha|ngoai] · công[nhanh|vua|cau_ky] · emoji`) + món `source: custom` trong `choices`/`proposals` 90 ngày (ưu tiên nhẹ: nhân đôi trọng số). Loại món có cùng `name` (so không phân biệt hoa thường, bỏ dấu cách thừa) đã chốt trong 7 ngày. Bộ lọc chip: **Tuỳ** (tất cả) · **Nhà nấu** (`nha`) · **Ăn ngoài** (`ngoai`) · **Nhanh gọn** (`nhanh`). Giờ máy trước 10:00 cho thêm món `sang`; sau 14:00 ưu tiên `toi` (trọng số ×2), không loại hẳn. Kết quả quay nằm local; hai nút: **Đề xuất món này** (tạo `proposals`) · **Chốt luôn** (tạo `choices` `source: spin`, không tạo đề xuất → chỉ 1 push).

- **W4 — Mình đề xuất:** ô nhập ≤40 ký tự, gợi ý từ ngân hàng + lịch sử khi gõ ≥2 ký tự (khớp đầu từ, bỏ dấu), chọn gợi ý → `source: bank`/`history` kèm `bankId`; gõ tự do → `source: custom`. Không lọc từ ngữ (không gian riêng hai người). Tên hiện nguyên văn, không tự viết hoa.

- **W5 — Push + inbox qua 2 CF mới**, copy localize vi/en theo `languageCode` thiết bị như mọi CF khác (không content-free: tên món không riêng tư):
  - `notifyMealProposal` (onCreate `proposals/{id}`) → người kia: *"{name} đề xuất: {dish}. Chốt không?"* / *"{name} suggests {dish}. Deal?"*; inbox `type: 'meal_proposal'` `{dish, actorName, date}`; tap → Home cuộn thẻ. **Cooldown 10 phút/cặp** cho push đề xuất: CF ghi `lastMealPushAt` lên `meals/{date}` (Admin bypass rules), trong 10 phút chỉ ghi inbox, không push.
  - `notifyMealChosen` (onCreate `choices/{id}`) → người kia (không gửi cho người chốt): *"{name} chốt rồi: hôm nay ăn {dish}"* / *"{name} decided: {dish} today"*; inbox `type: 'meal_chosen'`; **`wakeClients: true`** kèm `data.dish`, `data.date` để app nền (1) cập nhật widget trạng thái `meal` (widget-today) và (2) huỷ nhắc local band 1200 (W8). Không cooldown (chốt ≤4 lần/ngày).
  - Không có pref tắt riêng loại này ở bản đầu (như `care_message`).

- **W6 — Thẻ Home đặt ngay sau `MoodCard`, trước `SleepCard`**; hiện cả khi cặp còn `waiting_partner` (quay + chốt một mình; không có người nhận push). Ba trạng thái:
  1. *Chưa có gì:* tiêu đề "Hôm nay ăn gì?" + 2 nút ngang hàng **Quay món** (nút chính) · **Mình đề xuất** (viền).
  2. *Có đề xuất:* danh sách ≤6 dòng, mỗi dòng: emoji/ảnh nhỏ nếu từ ngân hàng · tên món · "em đề xuất" hoặc "mình đề xuất" · nút **Chốt** trên mọi đề xuất, kể cả của chính mình (tự chốt được). Dưới cùng: **Quay món** · **Mình đề xuất**.
  3. *Đã chốt:* tên món cỡ lớn + emoji + dòng "em chốt lúc 17:02" (hoặc "mình chốt") + 2 nút **Chụp bữa này** (chính) · **Đổi món** (về trạng thái 2, giữ đề xuất cũ). Góc thẻ: lối vào lịch sử (icon + "đã ăn gì").
  Thẻ tự vẽ lại lúc 0:00 (`MidnightBuilder`) về trạng thái 1. Xưng hô: "mình" / tên người ấy, không "hai đứa" (luật copy).

- **W7 — "Chụp bữa này"** mở `CreatePostScreen` như nút "Chụp hình" của Home, caption điền sẵn `{dish}` (sửa được). Không tag ảnh với bữa, không model mới. *Lý do:* 1 nút, 0 backend, dẫn thẳng vào North Star.

- **W8 — Nhắc local 1 lần/ngày, band id 1200–1209 (dùng 1200)**, mặc định **BẬT 16:30** cho cặp `active`, tắt/đổi giờ ở Cài đặt → Lời nhắc (tile mới dưới nhắc câu hỏi). Arm one-shot HÔM NAY lúc mở app khi hôm nay chưa chốt và giờ chưa qua; huỷ khi chốt trên máy mình; chốt từ máy người ấy → push `wakeClients` của `notifyMealChosen` → handler nền huỷ 1200 (cùng cơ chế `cancelDailyQuestionBands`). Cặp `waiting_partner`: không nhắc. Copy xoay 5 câu (l10n `mealReminderBody1..5`), ví dụ: "Tối nay ăn gì? Quay thử một món xem" · "Người ấy chưa đề xuất gì, mình mở màn trước nhé" · "Chốt món sớm cho đỡ cãi nhau lúc đói". *(PO tự chốt — user lật được: mặc định tắt?)* Ngân sách iOS 64 notification: +1 slot, ghi vào nợ đã biết.

- **W9 — Lịch sử "Chúng mình đã ăn"** = màn con (`SubScreenHeader`, chip "ĐÃ ĂN GÌ" / "WHAT WE ATE"): đầu màn khối "Món hay ăn" top 5 trong 90 ngày (đếm `choices` theo `name` chuẩn hoá, hiện số lần); dưới là danh sách nhóm theo ngày, 30 ngày/trang (`fetchPage` kiểu `care_timeline`), mỗi dòng: Trưa/Tối · tên món · ai chốt. Đọc `meals` (tài liệu cha có `latestChoice*`) cho danh sách; top 5 đọc `collectionGroup('choices')`? **Không** — tránh index collection-group mới; đọc `choices` của ≤90 ngày có `latestChoiceName` (≤90 query nhỏ, phân trang). Dev chọn cách rẻ hơn nếu có.

- **W10 — Dọn dữ liệu:** `meals` nằm dưới `couples/{id}` nên đi cùng cách dọn couple hiện có khi xoá tài khoản / người cuối rời (`deleteAccount`, `leaveCoupleCleanup`). Dev kiểm: nếu CF liệt kê tên subcollection thì thêm `meals` (và 2 subcollection con); nếu xoá đệ quy thì không cần. Người rời couple (còn người kia): giữ lịch sử (như chat).

- **W11 — Analytics:** `meal_spin{filter}` · `meal_propose{source}` · `meal_choose{via: proposal|spin, own_proposal: bool, proposals_today: int}` · `meal_photo_cta` · `meal_history_open`. Không log tên món (nội dung người dùng).

- **W12 — Mixed version:** app cũ không có thẻ, không đọc `meals`; nhận push `meal_*` → `NotificationTapRouter` rơi default (về Home), inbox hiện tiêu đề/nội dung chung (`AppNotification` type lạ → render như `care_message`? Dev kiểm render type lạ hiện tại; nếu crash/ẩn thì chấp nhận ẩn). Rules additive, không siết gì app cũ đang dùng.

- **W13 — Phát hành 1.11.0 cùng widget-today.** DEV deploy rules + 2 CF trong lúc dev (`scripts/test-firebase-rules.sh` trước). PROD: `deploy --project prod --only firestore:rules,functions:notifyMealProposal,functions:notifyMealChosen` khi phát hành, **chờ lệnh user**. Rules PROD phải lên trước khi app 1.11.0 live (app mới ghi `meals` → `permission-denied` nếu rules cũ).

- **W14 — Thiết kế qua UI UX Pro Max** (luật 8): thẻ dùng `ContentCard` + `SectionHeader` + `InkTile`, nút pill h52 chỉ cho nút chính; vòng quay = một animation ngắn (≤600 ms, tôn trọng Reduce Motion) đổi tên món 4–6 lần rồi dừng; emoji món là nội dung, không phải icon. Designer chốt bố cục 3 trạng thái + sheet "Mình đề xuất" + màn lịch sử.

## 5. Acceptance criteria (xong khi…)

- [ ] Home cặp active có thẻ "Hôm nay ăn gì?" sau thẻ tâm trạng; cặp chờ người ấy cũng có; guest/setup không có.
- [ ] **Quay món:** 10 lần quay liên tiếp không ra món đã chốt trong 7 ngày; lọc "Nhà nấu" chỉ ra món tag `nha`; "Nhanh gọn" chỉ `nhanh`; sau 14:00 ít nhất 7/10 lần ra món `toi`; món tự nhập trong 90 ngày xuất hiện trong pool.
- [ ] **Đề xuất:** A gõ "Bún chả" → B nhận push "A đề xuất: Bún chả. Chốt không?" trong ≤10 giây (DEV, máy Android thật hoặc iOS có APNs) + inbox; B mở app thấy dòng đề xuất; A đề xuất tiếp trong 10 phút → B chỉ có inbox, không push.
- [ ] **Chốt:** B bấm Chốt → A nhận push "B chốt rồi: hôm nay ăn Bún chả" + inbox; thẻ A đổi sang "đã chốt" realtime (≤3 giây khi app mở); widget A (nếu có widget-today) hiện "Hôm nay ăn: Bún chả"; nhắc 16:30 của A bị huỷ (kiểm `pendingNotificationRequests`).
- [ ] "Chốt luôn" từ vòng quay chỉ tạo `choices`, không tạo `proposals`, người ấy nhận đúng 1 push.
- [ ] Chốt lần 2 trong ngày → lịch sử có 2 dòng Trưa/Tối đúng theo giờ; thẻ hiện món mới nhất; `choiceCount` tăng.
- [ ] **Chụp bữa này** → màn đăng ảnh có caption "Bún chả", đăng xong ảnh vào gallery như thường, `meal_photo_cta` được log.
- [ ] **Lịch sử:** 35 ngày dữ liệu seed → trang đầu 30 ngày, kéo xuống tải tiếp; "Món hay ăn" đúng top 5 theo số lần; màn trống có empty-state tử tế.
- [ ] **Nhắc:** mặc định bật 16:30, đổi 19:00 ở Cài đặt → lịch đổi; tắt → không có notification 1200; đã chốt trước 16:30 → không nổ; chốt lúc 16:35 (sau khi nổ) không lỗi.
- [ ] Qua 0:00 (chỉnh giờ) → thẻ về trạng thái trống, không cần mở lại app.
- [ ] **Rules:** `scripts/test-firebase-rules.sh` PASS với ≥18 case mới: người ngoài couple không đọc/ghi; tác giả pinned; tên 0 / 41 ký tự bị chặn; `createdAt` khác `request.time` bị chặn; update/delete `proposals`/`choices` bị chặn; `lastMealPushAt` client ghi bị chặn; `date` không khớp id bị chặn; `latestChoiceBy` giả người khác bị chặn; app cũ (không gửi khoá optional) vẫn tạo được `meals/{date}` tối thiểu.
- [ ] CF: test rules-emulator cho 2 trigger (push + inbox + cooldown + không gửi cho người chốt); deploy DEV có vết; PROD chưa deploy.
- [ ] i18n vi + en đủ (thẻ, sheet, lịch sử, nhắc, push/inbox, tên 100+ món en); `flutter analyze` 0; test Dart cho `DishSuggester` (lọc 7 ngày, chip, trọng số giờ, chuẩn hoá tên) và map Trưa/Tối.
- [ ] Không regression Home (thứ tự thẻ, entrance index, MidnightBuilder của chòm sao), create_post, notification center.

## 6. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)

- 🎨 **Designer:** 3 trạng thái thẻ Home + sheet "Quay món" (chip lọc, animation quay, 2 nút) + sheet "Mình đề xuất" (ô nhập + gợi ý) + màn lịch sử (top 5 + danh sách theo ngày) + tile nhắc trong Cài đặt; copy vi/en theo luật "chúng mình"; tra UI UX Pro Max, đối chiếu `project/design-system.md`. → *expect:* `design.md` + mock bấm thử.
- 💻 **Dev:** (1) `dish_bank.dart` sinh từ `dish-bank.md` + `DishSuggester` thuần + test; (2) `MealService` (Firestore, batch chốt) + `MealProvider` (watch hôm nay, wire ở `session_resolver`, clear khi sign-out — nhớ named-param `_resolve`); (3) thẻ Home + 2 sheet + màn lịch sử; (4) nhắc band 1200 trong `ReminderService`/`ReminderProvider` + tile Cài đặt; (5) handler nền huỷ 1200 khi push `meal_chosen`; (6) rules + test + 2 CF + `writeInboxNotifications` + `NotificationTapRouter`/`AppNotification.targetHomeTab` cho 2 type mới + `PUSH_TYPE_PREF_FIELD` không map; (7) analytics; (8) ARB vi/en + `gen-l10n`; (9) deploy DEV. → *expect:* nhánh `feature/what-to-eat`, analyze 0, rules test PASS, smoke 2 máy DEV `test3`/`test4`.
- 🧪 **Tester:** 14 tiêu chí §5; soi rules (người ngoài couple, giả tác giả, spam đề xuất), race 2 người chốt cùng lúc (2 `choices`, cha theo batch nào ghi sau — chấp nhận, kiểm không crash), 0:00, offline (đề xuất khi mất mạng → gửi sau), mixed version với app 1.10.1. → *expect:* bảng PASS/FAIL trong `test.md`.

## 7. Nợ kỹ thuật / rủi ro (Tester soi)

- 🟡 Hai người chốt cùng lúc → 2 `choices`, tài liệu cha giữ bản ghi sau; thẻ 2 máy có thể lệch vài giây tới khi stream đồng bộ. Chấp nhận.
- 🟡 Client cap 3 đề xuất/4 chốt mỗi người/ngày không có ở rules; spam chỉ tốn inbox (push đã cooldown).
- 🟡 LDR lệch múi giờ: `date` theo máy người ghi, như câu hỏi.
- 🟡 Ngân sách 64 notification iOS: +1 slot (band 1200).
- 🟡 Top 5 "món hay ăn" đọc ≤90 tài liệu cha + choices → chi phí đọc khi mở lịch sử; cache trong provider theo phiên.
- 🟢 Riêng tư: push lộ tên món (không nhạy cảm); inbox không lưu gì ngoài tên món + tên người.

## 8. Changelog feature
- [2026-10-19] [PO] Tạo feature theo yêu cầu user ("hôm nay ăn gì — user tự đề xuất hoặc app gợi ý"). Chốt W1–W14, ngân hàng 117 món ở `dish-bank.md`. W1 (một bữa/ngày) và W8 (nhắc mặc định bật 16:30) là PO tự chốt, user lật được. Chờ user duyệt spec.
