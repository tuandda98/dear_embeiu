# Chọn giúp chúng mình — phân vân gì, quay là xong

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Nội dung (PO sở hữu): ngân hàng món ăn [dish-bank.md](dish-bank.md) · ngân hàng đi đâu / làm gì [activity-bank.md](activity-bank.md).
> ⟪Lịch sử: spec đầu 2026-10-19 sáng là "Hôm nay ăn gì?" (đề xuất → chốt). User mở rộng cùng ngày: "cặp đôi hay phân vân ăn gì và đi đâu; không biết ăn gì hoặc đang phân vân cái gì thì app chọn random giúp" → generalize thành feature này.⟫

- **Feature:** decision-wheel
- **Ưu tiên:** P0 (mục tiêu "mở app mỗi ngày", user chốt 2026-10-19)
- **Trạng thái:** 📋 Spec (chờ user duyệt rồi chạy pipeline Designer → Dev → Tester)
- **Tạo ngày:** 2026-10-19
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · [dish-bank.md](dish-bank.md) · [activity-bank.md](activity-bank.md) · widget hiện kết quả ở [`../widget-today/`](../widget-today/overview.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:* "Tối nay ăn gì?" — "Tuỳ em." "Cuối tuần đi đâu?" — "Tuỳ anh." "Ai rửa bát?" — im lặng. Cặp nào cũng kẹt ở những câu này mỗi ngày, cãi vặt vì nó, và chưa app nào trong niche VN đứng ra quyết hộ.
- *Giả thuyết giá trị:* app là người thứ ba công bằng: phân vân gì thì quay, kết quả ra là chốt, người ấy nhận ngay "Em quay ra: tối nay ăn Bún chả". Không ai phải nhường ai, không ai phải nghĩ. Mỗi ngày có ít nhất một lần phân vân thật nên có ít nhất một lý do thật để mở app, rẻ hơn câu hỏi hằng ngày (chỉ 2 chạm). Kết quả dẫn thẳng sang "Chụp lại" → ảnh kỷ niệm (North Star).
- *Đối tượng:* cặp đã ghép đôi (có người nhận kết quả). Cặp còn chờ người ấy vẫn quay và chốt được một mình, lịch sử giữ lại.
- *Đo bằng gì (metric):*
  - % cặp active có ≥1 quyết định (`decisions`) mỗi ngày — mục tiêu sau 30 ngày: ≥40% cặp active dùng ≥3 ngày/tuần.
  - Tỉ lệ quyết định có người ấy phản hồi (mở app trong 30 phút sau push, hoặc quay lại).
  - `decision_photo_cta` → ảnh được đăng.
  - Số cặp có người mở app mỗi ngày (`scripts/prod-retention-stats.js`, chung với widget-today).

## 2. Bối cảnh / nghiên cứu

- Số liệu PROD 2026-10-19: 28 cặp active, 7–16 cặp có người mở app mỗi ngày; 8 cặp cả hai mở hằng ngày nhưng bỏ qua câu hỏi (ngại viết). Cần một thói quen rẻ hơn viết, nhưng vẫn kéo người thứ hai.
- "Wheel of names", "Quay số định mệnh" là app/web được cặp đôi VN dùng thật để chọn quán, chọn người rửa bát — nhưng không nhớ gì, không báo cho người kia, không có lịch sử chung. Phần hơn của mình: kết quả đi tới máy người ấy, hai người cùng lịch sử, cùng ngân hàng món/chỗ đi hợp VN.
- Tái dùng từ app: `care_message` (push có nội dung + inbox), `rps-game` (cooldown `lastNudgeAt` do CF ghi, animation ngắn), `create_post` (đăng ảnh có caption), `care_timeline` (lịch sử phân trang), `MidnightBuilder`, gate `coupleActive` của nhắc câu hỏi, `SubScreenHeader`.

## 3. Phạm vi (scope)

- **Trong phạm vi (bản đầu):**
  - **Ba chế độ quay:** 🍜 **Ăn gì** (ngân hàng 117 món + lọc) · 📍 **Đi đâu / làm gì** (ngân hàng 64 hoạt động + lọc) · 🎲 **Tự nhập** (gõ câu hỏi + 2–12 lựa chọn, có preset "Ai làm?" điền sẵn tên hai người).
  - **Quay = ngẫu nhiên, local, miễn phí.** Chỉ khi bấm **Chốt** mới ghi và báo người ấy. Người ấy có thể **Quay lại** (ghi đè kết quả, báo ngược lại).
  - **Thẻ Home "Phân vân gì không?"** 3 dòng (ăn · đi · khác) hiện kết quả hôm nay hoặc nút Quay.
  - **"Chụp lại"** từ kết quả → màn đăng ảnh, caption điền sẵn.
  - **Lịch sử "Đã quay"** 90 ngày, mọi chế độ; "Hay ăn / hay đi" top 5.
  - **Nhắc local** 16:30 "Hôm nay ăn gì?" khi hôm nay chưa chốt món.
  - Rules additive + 1 Cloud Function; vi + en.
- **Ngoài phạm vi (ghi roadmap):** bản đồ/quán cụ thể gần đây · thời tiết · AI gợi ý · ngân sách · bình chọn/veto nhiều vòng · kế hoạch tuần · tách trưa/tối · gắn ảnh với quyết định · sửa/xoá quyết định đã chốt · nhiều couple dùng chung bánh xe.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý. Mục *(PO tự chốt)* user lật được trước khi Dev bắt đầu.

- **D1 — Một feature, ba chế độ, một màn quay.** Màn con `DecisionWheelScreen` (chip "CHỌN GIÚP" / "DECIDE FOR US"), thanh chọn chế độ Ăn gì · Đi đâu · Tự nhập, mỗi chế độ có chip lọc riêng. *Lý do:* user mô tả đúng một hành vi ("đang phân vân cái gì thì quay") — tách ba màn là ba thói quen phải dạy.

- **D2 — Quay là local, chốt mới ghi.** Quay bao nhiêu lần cũng không chạm mạng, không push. Bấm **Chốt** → ghi `decisions` + push người ấy một lần. *Lý do:* quay 5 lần mà push 5 lần là spam; "kết quả cuối" mới là thứ người ấy cần.

- **D3 — Mô hình dữ liệu: một collection, id theo ngày cho ăn/đi:**

```
couples/{coupleId}/decisions/{id}
  id = '{date}_eat' | '{date}_go'   (một kết quả/ngày/chế độ, quay lại = ghi đè)
     | autoId                         (custom: bao nhiêu cũng được)
  kind: 'eat' | 'go' | 'custom'
  date: 'YYYY-MM-DD'          // ngày tạo theo giờ máy người tạo (DailyQuestionService.dateKey)
  question: string ≤60        // custom: câu hỏi; eat/go: '' (client hiện theo kind)
  options: list<string>       // custom: 2..12 mục, mỗi mục ≤40; eat/go: [] (pool lớn, không lưu)
  filter: string ≤20          // chip lọc lúc quay: eat tuy|nha|ngoai|nhanh · go tuy|nha|ngoai|free · custom ''
  result: string 1..40        // kết quả hiện tại
  resultId: string ≤40        // bankId nếu từ ngân hàng, '' nếu nhập tay / custom
  spins: int ≥1               // số lần quay (tăng khi Quay lại)
  byUserId: uid               // người chốt / quay lại cuối
  createdBy: uid              createdAt: == request.time       updatedAt: timestamp
  lastPushAt?: timestamp      // CHỈ CF ghi (cooldown D5)
```
  Rules (additive): thành viên đọc. **Create** bởi thành viên: `hasOnly` 12 khoá (gồm `lastPushAt` vì sau này CF ghi vào — trừ ở create thì không có), `createdBy == byUserId == auth.uid`, `createdAt == request.time`, `kind in ['eat','go','custom']`, `date` khớp `^\d{4}-\d{2}-\d{2}$`, với `eat`/`go` thì `id == date + '_' + kind` và `options.size() == 0`, với `custom` thì `options.size() >= 2 && <= 12`, `options.join('').size() <= 480`, `result.size()` 1..40, `question.size() <= 60`, `spins >= 1`. **Update** (Quay lại) bởi thành viên: `affectedKeys().hasOnly(['result','resultId','spins','byUserId','updatedAt'])`, `byUserId == auth.uid`, `spins == resource.spins + 1`; `lastPushAt` chỉ Admin. **Không delete.** Client: với eat/go thử `create`, dính `already-exists` thì `update` (Dev dùng transaction `get` rồi set/update).
  *Lý do:* id theo ngày → đọc "hôm nay ăn gì" bằng 1 `get`, không cần composite index; lịch sử = `orderBy('createdAt', desc)` (index đơn mặc định). Bỏ mô hình đề xuất/chốt 2 subcollection của spec sáng — thừa khi "quay" đã là cách đề xuất.

- **D4 — Pool và lọc (`DecisionSuggester`, hàm thuần có test):**
  - **Ăn gì:** `dish-bank.md` (117 món) + món nhập tay trong `decisions` 90 ngày (`kind: eat`, `resultId == ''`, trọng số ×2). Loại món có `result` chuẩn hoá (bỏ dấu cách thừa, không phân biệt hoa thường) trùng kết quả eat 7 ngày gần nhất. Chip: **Tuỳ** · **Nhà nấu** (`nha`) · **Ăn ngoài** (`ngoai`) · **Nhanh gọn** (`nhanh`). Giờ máy < 10:00 thêm món `sang`; ≥ 14:00 món `toi` trọng số ×2.
  - **Đi đâu / làm gì:** `activity-bank.md` (64 mục) + mục nhập tay 90 ngày (×2). Loại mục đã chốt 14 ngày gần nhất. Chip: **Tuỳ** · **Ở nhà** (`nha`) · **Ra ngoài** (`ngoai`) · **Không tốn tiền** (`free`). Thứ 7/CN hoặc sau 17:00 ngày thường: mục `cuoi_tuan`/`toi` trọng số ×2.
  - **Tự nhập:** pool = đúng các lựa chọn đã gõ; không lọc, không trọng số.
  - Ngẫu nhiên thật (`Random()`), trong một phiên quay không lặp lại mục vừa ra cho tới khi hết pool.

- **D5 — Push + inbox qua 1 CF `notifyDecision`** (onWrite `decisions/{id}`), copy localize vi/en theo `languageCode` thiết bị, gửi cho người **không phải** `byUserId`:
  - Create: eat *"{name} quay ra: hôm nay ăn {result}"* / *"{name} spun: {result} today"* · go *"{name} quay ra: {result}"* / *"{name} spun: let's {result}"* (D18) · custom *"{name} quay \"{question}\": {result}"* / *"{name} spun \"{question}\": {result}"*.
  - Update có `result` đổi: *"{name} quay lại: {result}"* / *"{name} re-spun: {result}"*.
  - Inbox `type: 'decision'` `{kind, question, result, actorName, date}`; tap → Home cuộn thẻ. Push kèm **`wakeClients: true`** + `data.kind`, `data.result`, `data.date` để app nền cập nhật widget (widget-today) và huỷ nhắc 16:30 khi `kind == eat`.
  - **Cooldown 10 phút/tài liệu** cho update (CF ghi `lastPushAt`): quay lại liên tục chỉ ghi inbox. Create không cooldown (1 doc/ngày/chế độ; custom tối đa 10/ngày chặn ở client).
  - Không có pref tắt riêng ở bản đầu (như `care_message`).

- **D6 — Thẻ Home "Phân vân gì không?"** ngay sau `MoodCard`, trước `SleepCard`; hiện cả khi cặp `waiting_partner`. Ba dòng `InkTile`:
  1. 🍜 **Ăn gì?** — chưa có: nút **Quay** · có: "Bún chả · em quay 17:02".
  2. 📍 **Đi đâu?** — tương tự với `go`.
  3. 🎲 **Phân vân khác** — chưa có: **Nhập & quay** · có: câu hỏi + kết quả custom mới nhất hôm nay ("Ai rửa bát? → Anh").
  Chạm dòng có kết quả → sheet kết quả: kết quả to + emoji + ai quay + nút **Quay lại** · **Chụp lại** · link **Đã quay** (lịch sử). Chạm nút Quay → `DecisionWheelScreen` đúng chế độ. Thẻ tự vẽ lại lúc 0:00 (`MidnightBuilder`). Xưng hô "mình" / tên người ấy.

- **D7 — Màn quay (`DecisionWheelScreen`):** thanh 3 chế độ · chip lọc · khối quay (Designer chốt hình: slot chữ chạy hoặc bánh xe; ≤1 giây; Reduce Motion → hiện ngay) · thẻ kết quả · nút **Chốt luôn** (chính) · **Quay lại** · link **Nhập tay** (gõ kết quả ≤40 ký tự rồi chốt, không quay — thay cho "Mình đề xuất" ở spec cũ). Chế độ Tự nhập: ô câu hỏi ≤60 (placeholder xoay: "Phở hay bún?", "Đà Lạt hay Vũng Tàu?", "Ai rửa bát?") + chip lựa chọn thêm/xoá (2–12) + preset **Ai làm?** (điền 2 tên từ couple) · **Cái nào?** (2 ô trống). Tự nhập không lưu nháp; chốt mới ghi.

- **D8 — "Chụp lại"** mở `CreatePostScreen` như nút "Chụp hình" Home, caption điền sẵn `{result}` (eat: "Bún chả 🍜", go: "Đi cà phê ☕", custom: "{question} → {result}"). Không model mới.

- **D9 — Lịch sử "Đã quay"** = màn con (chip "ĐÃ QUAY" / "SPUN SO FAR"): đầu màn 2 khối "Hay ăn" + "Hay đi" top 5 trong 90 ngày (đếm `result` chuẩn hoá theo `kind`); dưới là danh sách theo ngày, 30 bản ghi/trang (`orderBy createdAt desc`, `startAfter`), mỗi dòng: icon chế độ · câu hỏi (custom) · kết quả · ai quay · số lần quay nếu >1. Đọc ≤90 ngày cho top 5, cache theo phiên trong provider.

- **D10 — Nhắc local 1 lần/ngày, band 1200–1209 (dùng 1200)**, mặc định **BẬT 16:30** cho cặp `active`, tắt/đổi giờ ở Cài đặt → Lời nhắc. Arm one-shot HÔM NAY khi mở app nếu chưa có `{date}_eat` và giờ chưa qua; huỷ khi chốt eat trên máy mình; chốt từ máy người ấy → push `wakeClients` → handler nền huỷ 1200 (cùng cơ chế `cancelDailyQuestionBands`). `waiting_partner`: không nhắc. Copy xoay 5 câu (`decisionReminderBody1..5`), ví dụ "Tối nay ăn gì? Quay một phát cho xong" · "Chưa ai chốt món hôm nay, mình quay trước nhé". *(PO tự chốt — user lật được: mặc định tắt?)* iOS 64 notification: +1 slot.

- **D11 — Dọn dữ liệu:** `decisions` nằm dưới `couples/{id}`, đi cùng cách dọn couple hiện có (`deleteAccount`, `leaveCoupleCleanup`); Dev kiểm CF liệt kê tên subcollection hay xoá đệ quy, liệt kê thì thêm `decisions`. Người rời couple (còn người kia): giữ lịch sử.

- **D12 — Analytics:** `decision_spin{kind, filter}` · `decision_commit{kind, spins, via: spin|manual, preset?}` · `decision_respin{kind}` · `decision_photo_cta{kind}` · `decision_history_open`. Không log nội dung (`result`, `question`).

- **D13 — Mixed version:** app cũ không có thẻ, không đọc `decisions`; nhận push `decision` → `NotificationTapRouter` rơi default (Home); inbox type lạ — Dev kiểm cách render type lạ hiện tại, ẩn được thì chấp nhận ẩn. Rules additive.

- **D14 — Phát hành 1.11.0 cùng widget-today.** DEV: `scripts/test-firebase-rules.sh` rồi deploy rules + CF. PROD: `deploy --project prod --only firestore:rules,functions:notifyDecision` khi phát hành, **chờ lệnh user**; rules PROD phải lên trước khi 1.11.0 live.

- **D15 — Thiết kế qua UI UX Pro Max** (luật 8): `ContentCard` + `SectionHeader` + `InkTile`, nút pill h52 cho nút chính; emoji là nội dung; animation quay ≤1 giây; Designer chốt thẻ Home, màn quay 3 chế độ, sheet kết quả, màn lịch sử, tile nhắc.

- **D16 — Câu hỏi custom được để trống** (PO duyệt câu hỏi 1 của Designer, 2026-10-19): vẫn cho quay và chốt; lúc chốt `question` = tên preset vừa dùng ("Ai làm?" / "Cái nào?") hoặc "Chọn giúp chúng mình" / "Decide for us". Giữ đúng "2 chạm".
- **D17 — Dòng lịch sử chỉ để xem** (PO duyệt câu hỏi 2): không mở sheet, không quay lại ngày cũ (sẽ ghi đè lịch sử).
- **D18 — Push `go` bỏ chữ "đi"** (PO duyệt câu hỏi 3): 35/64 mục ngân hàng bắt đầu bằng "Đi" → mẫu vi *"{name} quay ra: {result}"*. en giữ *"let's {result}"*.
- **D19 — Chốt khi mất mạng = nhánh (b) của design** (PO chốt thay Dev): giữ transaction cho eat/go; lỗi/offline → ở lại màn, giữ kết quả, dải lỗi + nút "Thử lại". *Lý do:* chốt cần push tới người ấy mới có nghĩa; ghi xếp hàng offline dễ thành create đè create khi hai máy cùng chốt lúc mất mạng (rules từ chối âm thầm). Custom (autoId, không transaction) vẫn ghi xếp hàng bình thường → dùng state "Đang mất mạng…".
- **D20 — Tự quay khi mở màn từ nút Quay / Quay lại** (Designer tự chốt, PO giữ): sau 250ms; mở bằng tay hoặc đổi chế độ thì không.

## 5. Acceptance criteria (xong khi…)

- [ ] Home cặp active và cặp chờ người ấy có thẻ "Phân vân gì không?" sau thẻ tâm trạng; guest/setup không có.
- [ ] **Ăn gì:** 10 lần quay không ra món đã chốt 7 ngày; "Nhà nấu" chỉ `nha`; "Nhanh gọn" chỉ `nhanh`; sau 14:00 ≥7/10 lần ra món `toi`; món nhập tay 90 ngày có trong pool.
- [ ] **Đi đâu:** 10 lần quay không ra mục đã chốt 14 ngày; "Không tốn tiền" chỉ `free`; "Ở nhà" chỉ `nha`.
- [ ] **Tự nhập:** gõ "Ai rửa bát?" + preset Ai làm? → 2 tên đúng từ couple; quay chỉ ra 1 trong 2; chốt → người ấy nhận push *"{name} quay "Ai rửa bát?": Anh"* ≤10 giây (DEV, máy có push) + inbox; 1 lựa chọn hoặc 13 lựa chọn → nút Chốt khoá.
- [ ] **Chốt eat:** A chốt "Bún chả" → B nhận push + inbox; thẻ B đổi realtime ≤3 giây; widget B (widget-today) hiện "Hôm nay ăn: Bún chả"; nhắc 16:30 của B bị huỷ (kiểm `pendingNotificationRequests`); A chốt lại trong ngày → cùng doc `{date}_eat`, `spins` tăng, B nhận "quay lại" (trong 10 phút chỉ inbox).
- [ ] Quay 10 lần không chốt → không có ghi Firestore, không push.
- [ ] **Chụp lại** → màn đăng ảnh caption "Bún chả 🍜"; đăng xong ảnh vào gallery; `decision_photo_cta` log.
- [ ] **Lịch sử:** seed 40 bản ghi 3 chế độ → trang đầu 30, kéo tải tiếp; top 5 "Hay ăn"/"Hay đi" đúng; empty-state tử tế.
- [ ] **Nhắc:** mặc định 16:30; đổi 19:00 → lịch đổi; tắt → không có id 1200; đã chốt eat trước giờ → không nổ.
- [ ] Qua 0:00 (chỉnh giờ) → thẻ về trống, không cần mở lại app.
- [ ] **Rules** `scripts/test-firebase-rules.sh` PASS với ≥20 case mới: người ngoài couple bị chặn đọc/ghi · id eat/go sai ngày/kind bị chặn · custom 1 hoặc 13 lựa chọn bị chặn · tổng ký tự options >480 bị chặn · `result` 0/41 ký tự · `createdAt != request.time` · giả `createdBy`/`byUserId` · update đổi `kind`/`options`/`createdBy` bị chặn · `spins` không tăng đúng 1 bị chặn · client ghi `lastPushAt` bị chặn · delete bị chặn · app cũ không gửi khoá optional vẫn tạo được.
- [ ] CF: test emulator cho onWrite (create push + inbox · update push có cooldown · không gửi cho `byUserId` · `wakeClients`); deploy DEV có vết; PROD chưa deploy.
- [ ] i18n vi + en đủ (thẻ, màn quay, sheet, lịch sử, nhắc, push/inbox, tên ngân hàng en); `flutter analyze` 0; test Dart cho `DecisionSuggester` (lọc 7/14 ngày, chip, trọng số giờ/cuối tuần, chuẩn hoá tên, không lặp trong phiên) và map eat/go id.
- [ ] Không regression Home (thứ tự thẻ, entrance index, `MidnightBuilder` chòm sao), create_post, notification center.

## 6. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)

- 🎨 **Designer:** thẻ Home 3 dòng + sheet kết quả + màn quay (3 chế độ, chip lọc, hình quay, thẻ kết quả, khối tự nhập với chip lựa chọn + preset) + màn lịch sử + tile nhắc; copy vi/en luật "chúng mình"; tra UI UX Pro Max, đối chiếu `project/design-system.md`. → *expect:* `design.md` + mock bấm thử.
- 💻 **Dev:** (1) `dish_bank.dart` + `activity_bank.dart` sinh từ 2 file md + `DecisionSuggester` thuần + test; (2) `DecisionService` (Firestore, transaction create/update eat-go) + `DecisionProvider` (watch hôm nay = 2 `get`/listen `{date}_eat`/`{date}_go` + query custom hôm nay; wire ở `session_resolver`, nhớ named-param `_resolve`, clear khi sign-out); (3) thẻ Home, màn quay, sheet, lịch sử; (4) nhắc band 1200 + tile Cài đặt; (5) handler nền huỷ 1200 khi push `decision` kind eat; (6) rules + test + CF `notifyDecision` + `writeInboxNotifications` + `NotificationTapRouter`/`AppNotification.targetHomeTab` type mới; (7) analytics; (8) ARB + `gen-l10n`; (9) deploy DEV. → *expect:* nhánh `feature/decision-wheel`, analyze 0, rules test PASS, smoke 2 máy DEV `test3`/`test4`.
- 🧪 **Tester:** 14 tiêu chí §5; soi rules (người ngoài, giả tác giả, spins nhảy cóc, custom 13 mục); hai người chốt eat cùng lúc (transaction → 1 doc, người sau thành update; kiểm không crash, push đúng người); 0:00; offline (chốt khi mất mạng → gửi sau); mixed version với 1.10.1. → *expect:* bảng PASS/FAIL trong `test.md`.

## 7. Nợ kỹ thuật / rủi ro (Tester soi)

- 🟡 Hai người chốt eat cùng lúc: transaction đảm bảo 1 doc, người sau là "quay lại" — thẻ hiện kết quả người sau. Chấp nhận, kiểm không crash.
- 🟡 Cap custom 10 quyết định/ngày và 12 lựa chọn chỉ ở client (rules chặn 12 lựa chọn, không đếm doc/ngày); spam chỉ tốn inbox (push đã cooldown ở update, create custom không cooldown → theo dõi).
- 🟡 LDR lệch múi giờ: `date` theo máy người tạo, như câu hỏi.
- 🟡 iOS 64 notification: +1 slot (band 1200).
- 🟡 Ngân hàng "đi đâu" không biết thành phố/thời tiết; mục "đi biển" ở Hà Nội mùa đông vẫn có thể ra — chip lọc là cách người dùng tự tránh. Phase 2 cân nhắc tag mùa.
- 🟢 Riêng tư: push lộ kết quả + câu hỏi tự nhập (hai người tự gõ cho nhau); inbox không lưu gì thêm.

## 8. Changelog feature
- [2026-10-19] [PO] Sáng: tạo "Hôm nay ăn gì?" (đề xuất → chốt, 2 subcollection). Chiều: user mở rộng "ăn gì, đi đâu, phân vân gì cũng quay random" → đổi tên `decision-wheel`, generalize D1–D15: 3 chế độ, quay local chốt mới ghi, 1 collection `decisions` id theo ngày cho eat/go, 1 CF `notifyDecision`, thêm `activity-bank.md`. Giữ 117 món. D10 (nhắc mặc định bật 16:30) PO tự chốt, user lật được. User duyệt spec + yêu cầu thiết kế bằng UI UX Pro Max. Designer xong (`design.md`, `docs/design/decision-wheel-mockup.html`, slot chữ chạy dọc 900ms); PO trả lời 3 câu hỏi → D16–D19, giữ D20.
