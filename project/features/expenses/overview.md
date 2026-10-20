# Quỹ chung — sổ chi tiêu của chúng mình

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Đợt "mở app mỗi ngày" lần 2 (user chọn 2026-10-20 cùng `poke`, `caro-game`, `weather`, `arrival`). Nối với [decision-wheel](../decision-wheel/overview.md) qua nút "Ghi chi" (D14).

- **Feature:** expenses
- **Ưu tiên:** P1 (feature lớn nhất đợt; Phase 1 đủ dùng hằng ngày, phần còn lại sang Phase 2)
- **Trạng thái:** 📋 Spec — chờ user duyệt
- **Tạo ngày:** 2026-10-20
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · [`../decision-wheel/`](../decision-wheel/overview.md) · [`../widget-today/`](../widget-today/overview.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) · rules/CF [`../../firebase.md`](../../firebase.md)

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:* Tối thứ Sáu ăn lẩu hết 480k, anh trả. Thứ Bảy em đổ xăng 70k, mua bỏng nước 120k. Chủ nhật hai người ngồi nhớ lại "tuần này ai trả gì" và không ai nhớ. Cặp nào góp quỹ đi Đà Lạt thì thường ghi vào ghi chú điện thoại của một người: người kia không biết quỹ còn bao nhiêu, phải hỏi.
- Money Lover, Sổ Thu Chi MISA làm tốt sổ của một người, có ví chia sẻ (MISA) nhưng không có khái niệm "ai trả, ai ứng nhiều hơn". Splitwise có đúng phần đó nhưng tiếng Anh, bản miễn phí giới hạn số khoản/ngày từ cuối 2023, và không phải chỗ cặp đôi VN đang ở.
- *Giả thuyết giá trị:* ăn xong là mở app ghi, mất 3 chạm ("120k" → Ăn uống → Lưu). Người ấy thấy ngay khoản đó trong sổ chung, cuối tháng có câu trả lời "tháng này chúng mình tiêu 6,2 triệu, ăn uống chiếm một nửa, anh đang ứng nhiều hơn 340k". Việc chi tiêu xảy ra gần như mỗi ngày, nên đây là một lý do thật, lặp lại, để mở app, kể cả ngày không ai muốn viết câu trả lời.
- *Đối tượng:*
  - **Cặp đã ghép (28 cặp):** dùng sổ chung + quỹ mục tiêu + cân bằng.
  - **Cặp đang chờ người ấy (52 cặp):** dùng như sổ chi tiêu của riêng mình. Đây là giá trị một-người hiếm hoi của app trước khi người ấy vào (CLAUDE.md §11 "single-player value trước partner join là then chốt").
- *Đo bằng gì (metric):* xem §9.

## 2. Bối cảnh / nghiên cứu

Bộ tính năng của app phổ biến (nguồn cuối mục), lọc theo câu hỏi "cặp đôi chưa cưới, quen dùng Zalo/MoMo, có cần không?":

| Tính năng | Ai có | Cặp đôi cần? | Phase |
|---|---|---|---|
| Ghi chi nhanh + danh mục có icon | Money Lover, MISA, mọi app | Cần — là lõi | 1 |
| Báo cáo tháng theo danh mục, so tháng trước | Money Lover, MISA (biểu đồ tròn/cột) | Cần — câu trả lời "tháng này tiêu gì" | 1 |
| Ngân sách / hạn mức + cảnh báo khi vượt | Money Lover (tuần/tháng/quý), MISA (theo hạng mục) | Cần, nhưng một con số tổng tháng là đủ | 1 (tổng) · 2 (theo danh mục) |
| Ai trả, chia tỉ lệ, "ai đang ứng", thanh toán | Splitwise (chia đều/%/số tiền, settle up) | Cần — thứ app VN không có | 1 |
| Quỹ / tiết kiệm theo mục tiêu, gom chi theo dịp (chuyến đi) | Money Lover (Tiết kiệm + Sự kiện), MISA (sự kiện) | Cần — "Quỹ Đà Lạt" | 1 |
| Khoản riêng / ẩn giao dịch khỏi người kia | Honeydue (ẩn từng giao dịch, vd quà bất ngờ) | Có ích, rẻ nếu mô hình dữ liệu tính sẵn | 1 (bản đơn giản) |
| Khoản định kỳ, nhắc hoá đơn | Honeydue (bill reminder; 60% user tạo ≥1 nhắc lúc onboarding) | Hợp cặp sống chung (tiền nhà) | 2 |
| Thu nhập | Money Lover, MISA | Nhạy cảm với cặp chưa cưới; ít người muốn khai | Later, tuỳ chọn |
| Xuất Excel/CSV | MISA (Excel/PDF), Splitwise Pro | Hiếm dùng | 2 |
| Đa tiền tệ | Splitwise (Pro) | Cặp yêu xa nước ngoài, ít | Later |
| Liên kết ngân hàng, quét hoá đơn | Money Lover (>25 ngân hàng), MISA, Honeydue (Plaid) | Không — tốn, rủi ro bảo mật, ngoài niche | Không làm |
| Vay nợ, nhiều ví, đầu tư | Money Lover, MISA | Không — đó là app tài chính | Không làm |

Bài học: Splitwise gate tính năng chia tỉ lệ và giới hạn số khoản/ngày ở bản miễn phí, bị review 1 sao nhiều. Bản đầu của mình không giới hạn gì người dùng thấy được (giới hạn chỉ để chặn lạm dụng ở rules).

Nguồn:
- [FPT Shop — Money Lover](https://fptshop.com.vn/tin-tuc/danh-gia/money-lover-182808) · [Thế Giới Di Động — Money Lover](https://www.thegioididong.com/game-app/money-lover-ung-dung-quan-ly-chi-tieu-ca-nhan-gia-dinh-228454) · [Thế Giới Di Động — cách dùng Money Lover (Sự kiện, Tiết kiệm)](https://www.thegioididong.com/game-app/cach-su-dung-money-lover-chi-tiet-giup-quan-ly-chi-tieu-hieu-1311173)
- [MISA — Sổ Thu Chi](https://sme.misa.vn/37480/so-thu-chi-ung-dung-quan-ly-tai-chinh-ca-nhan-danh-cho-moi-nguoi/) · [App Store — Sổ Thu Chi MISA (chia sẻ ví)](https://apps.apple.com/vn/app/s%E1%BB%95-thu-chi-misa-qu%E1%BA%A3n-l%C3%BD-ti%E1%BB%81n/id865818973?l=vi) · [FPT Shop — Sổ Thu Chi MISA](https://fptshop.com.vn/tin-tuc/danh-gia/so-thu-chi-misa-185508)
- [App Store — Splitwise](https://apps.apple.com/app/splitwise-bill-splitter/id458023433) · [Yellow Slice — review Splitwise (giới hạn bản miễn phí)](https://www.yellowslice.in/blog/splitwise-app-review-ux-ui-improvements) · [Trustpilot — Splitwise](https://pt.trustpilot.com/review/splitwise.com?page=2)
- [Experian — review Honeydue](https://www.experian.com/blogs/ask-experian/honeydue-app-review/) · [TechCrunch — Honeydue](https://techcrunch.com/2017/08/07/honeydue-is-a-money-management-app-for-couples/)

Hạ tầng tái dùng: `memberIds` + `isCoupleMember` trong rules · `writeInboxNotifications` + `sendToRecipientDevices` · `handleCoupleOnAccountDeletion` / `deleteCoupleCompletely` / `notifyPartnerLeft` (cách dọn của `sleep`) · aggregate `count()` (đã dùng ở photo/rps) nay thêm `sum()` · `SubScreenHeader`, `ContentCard`, `InkTile`, `SectionHeader` · `MidnightBuilder` · `intl` (đã có `NumberFormat`).

## 3. Phạm vi (scope)

- **Trong phạm vi Phase 1 (bản phát hành đầu):**
  1. **Ghi khoản chi** — số tiền VND (nhập nhanh + gợi ý 50k/100k/200k/500k + gõ tắt "50k", "1tr2"), danh mục có icon (8 mặc định + tự thêm), ghi chú, ngày, ai trả (mình / người ấy / một quỹ), cách chia (chia đôi / người trả mời / trả hộ người kia / tuỳ số tiền), "Chỉ mình thấy".
  2. **Sổ tháng** — danh sách theo ngày, tổng tháng, theo danh mục, theo người trả, so với tháng trước; lùi/tiến tháng.
  3. **Ngân sách tháng** — một con số tổng cho chi chung, thanh tiến độ, cảnh báo 80% và 100% (trong app cho cả hai + push cho người không ghi khoản làm vượt).
  4. **Cân bằng** — "Ai đang ứng nhiều hơn bao nhiêu" + "Đánh dấu đã thanh toán".
  5. **Quỹ mục tiêu** — tối đa 5 quỹ đang mở: tên, emoji, mục tiêu (tuỳ chọn), góp của mỗi người, tiến độ, chi từ quỹ; đóng quỹ.
  6. **Sổ một người** cho cặp đang chờ.
  7. **Nối decision-wheel:** sheet kết quả Ăn gì / Đi đâu có nút "Ghi chi".
  8. **Nhắc tối (opt-in, mặc định tắt)** 21:30 "Hôm nay có khoản nào chưa ghi?".
  9. Rules additive + 1 Cloud Function `notifyExpense` + dọn dữ liệu khi rời/xoá; vi + en; analytics không lộ số tiền.
- **Ngoài phạm vi Phase 1 (ghi roadmap):** khoản định kỳ · ngân sách theo danh mục · xuất CSV · lịch sử sửa chi tiết từng lần · "chuyển khoản cũ sang sổ chung" sau khi ghép đôi · xem sổ của người ấy cũ · thu nhập · đa tiền tệ · ảnh hoá đơn · widget · liên kết ngân hàng / quét hoá đơn / vay nợ / nhiều ví (không bao giờ) · gate premium (chưa có monetization).

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý. Mục *(PO tự chốt)* user lật được trước khi Dev bắt đầu.

- **D1 — Một sổ, ba loại dòng, một collection `expenses`.** Khoản chi (`expense`), góp quỹ (`fund_in`), thanh toán (`settle`) đều là một dòng trong `couples/{coupleId}/expenses`. *Lý do:* tổng tháng, cân bằng, số dư quỹ đều tính được từ một luồng dữ liệu; một listener, một bộ rules, một chỗ dọn. App chi tiêu nào cũng coi "giao dịch" là đơn vị gốc.

- **D2 — Quyền xem theo danh sách `memberUids` chụp lúc tạo, không theo couple hiện tại.** Khoản chung: `memberUids = [mình, người ấy]`. Khoản "Chỉ mình thấy" và mọi khoản ghi lúc đang chờ người ấy: `memberUids = [mình]`. Rules: đọc khi là thành viên couple **và** có tên trong `memberUids`. *Lý do:* (a) người ấy rời, người mới ghép vào cùng `coupleId` không đọc được sổ tiền của cặp cũ, rules chặn chứ không chỉ UI giấu (tiền nhạy cảm hơn ảnh/chat; tiền lệ `sleep`); (b) khoản riêng có sẵn mà không cần collection thứ hai; (c) cặp đang chờ dùng ngay, không di trú dữ liệu khi người ấy vào. Hệ quả: mọi truy vấn phải có `where('memberUids', arrayContains: myUid)`.

- **D3 — Sổ một người cho cặp đang chờ** *(PO tự chốt)*: cặp `waiting_partner` thấy màn đầy đủ trừ "ai trả / cách chia / cân bằng" (chỉ có mình). Mọi khoản là `memberUids: [mình]`. Khi người ấy vào, khoản cũ **vẫn là của mình**; khoản mới mặc định vào sổ chung. Một dòng giải thích ở đầu sổ: "Người ấy vào rồi thì khoản mới sẽ ghi vào sổ chung. Khoản đã ghi vẫn chỉ mình thấy." *Lý do:* không bất ngờ công khai lịch sử chi tiêu của một người. Chuyển hàng loạt sang sổ chung để Phase 2.

- **D4 — Cả hai sửa và xoá được mọi khoản chung; khoản riêng chỉ chủ.** Mỗi lần sửa ghi `updatedBy`, `updatedAt`, `editCount + 1`; dòng khoản hiện "Em sửa · 21:02". Xoá là xoá cứng, có snackbar "Hoàn tác" 5 giây (client chờ 5 giây rồi mới gửi lệnh xoá). Không lưu lịch sử từng lần sửa ở Phase 1. *Lý do:* sổ chung giấy cũng ai cầm bút thì sửa; người ghi nhầm "480k" thành "48k" thường là người kia phát hiện. Ghi "ai sửa" đủ chống "sao tự nhiên đổi". Lịch sử đầy đủ cần subcollection + UI riêng, để Phase 2 nếu có phàn nàn.

- **D5 — Mô hình dữ liệu:**

```
couples/{coupleId}/expenses/{autoId}
  type: 'expense' | 'fund_in' | 'settle'
  amount: int               // VND, 1..1_000_000_000
  currency?: 'VND'          // optional, để dành đa tiền tệ; thiếu = VND
  date: 'YYYY-MM-DD'        // ngày phát sinh, người dùng chọn (mặc định hôm nay theo máy)
  categoryId: string ≤24    // expense: 'food'|'date'|'transport'|'home'|'shopping'|'gift'|'travel'|'other' hoặc 'c_<id>' tự thêm; fund_in/settle: ''
  note: string ≤100         // có thể rỗng
  payer: uid | 'fund'       // ai bỏ tiền; 'fund' chỉ với expense
  fundId: string ≤40        // bắt buộc khi payer=='fund' hoặc type=='fund_in'; còn lại ''
  splitMode: 'equal'|'treat'|'for_partner'|'custom'|'solo'
  payerShare: int           // phần người trả tự chịu, 0..amount. Người kia "nợ" amount - payerShare
  memberUids: list<uid>     // 1 hoặc 2 phần tử, chụp lúc tạo (D2). BẤT BIẾN
  shared: bool              // == (memberUids.size() == 2). BẤT BIẾN — dùng cho aggregate sum ở CF
  createdBy: uid            createdAt: == request.time     // BẤT BIẾN
  updatedBy?: uid           updatedAt?: == request.time     editCount?: int
  source?: 'manual'|'decision'                              // optional, chỉ để thống kê

couples/{coupleId}/expenseFunds/{autoId}
  name: string 1..40   emoji: string ≤8   target: int 0..10_000_000_000 (0 = không đặt)
  memberUids: list<uid> (như D2, bất biến)   status: 'open' | 'closed'
  createdBy, createdAt (bất biến)   updatedAt?
  reached100At?: timestamp          // CHỈ CF ghi (D10)

couples/{coupleId}/expenseMeta/main
  monthlyBudget?: int 0..10_000_000_000   // 0 hoặc thiếu = chưa đặt; áp cho mọi tháng tới khi đổi
  categories?: list<map{id, name ≤20, emoji ≤8}>  // ≤20 mục tự thêm
  budgetAlerted?: map<'YYYY-MM', 80|100>  // CHỈ CF ghi
  updatedAt?
```

  Quy ước tính (Dev viết hàm thuần `ExpenseMath` có test):
  - **Tổng chi tháng (sổ chung)** = Σ `amount` của `type=='expense' && shared` trong tháng, kể cả khoản chi từ quỹ. **Sổ của mình** = Σ khoản `expense` không shared.
  - **Cân bằng** = với mọi dòng shared có `payer` là một người (expense hoặc settle): người kia nợ người trả `amount - payerShare`. Cộng dồn từ đầu (không reset theo tháng). `fund_in` và khoản `payer=='fund'` không tạo nợ.
  - **Đã thanh toán** = tạo dòng `settle`, `payer` = người đang nợ, `payerShare = 0`, `amount` = số đang lệch (sửa được nếu trả một phần). Dòng settle không vào tổng chi.
  - **Số dư quỹ** = Σ `fund_in` − Σ `expense` có `payer=='fund'`, cùng `fundId`. Góp của mỗi người = Σ `fund_in` theo `payer` (không theo `createdBy`: em có thể ghi hộ "anh góp 1 triệu").
  - Chia đôi số lẻ: `payerShare = ceil(amount / 2)` (người trả chịu phần lẻ 1đ — không ai thấy lệch).
  *Lý do:* `payerShare` một số nguyên đủ biểu diễn cả 4 cách chia và để rules kiểm được (`0 <= payerShare <= amount`); map phần chia theo uid khó kiểm ở rules.

- **D6 — Rules (chỉ ADDITIVE, 3 match mới; app 1.10.x/1.11.0 không đụng tới):**
  - `expenses/{id}`:
    - **read:** `isCoupleMember(coupleId) && request.auth.uid in resource.data.memberUids`.
    - **create:** thành viên; `keys().hasOnly([...16 khoá D5])` và `hasAll([type, amount, date, categoryId, note, payer, fundId, splitMode, payerShare, memberUids, shared, createdBy, createdAt])`; `createdBy == auth.uid`; `createdAt == request.time`; `amount is int && 1 <= amount <= 1000000000`; `payerShare is int && 0 <= payerShare <= amount`; `date` khớp `^\d{4}-\d{2}-\d{2}$`; `note.size() <= 100`; `categoryId.size() <= 24`; `fundId.size() <= 40`; `currency` (dùng `data.get('currency','VND')`) `== 'VND'`; `memberUids is list && auth.uid in memberUids && (memberUids.size() == 1 || (memberUids.size() == 2 && memberUids.hasOnly(get(couple).data.memberIds)))`; `shared == (memberUids.size() == 2)`; `payer == 'fund' ? (type == 'expense' && fundId.size() > 0) : payer in memberUids`; `type == 'fund_in'` → `fundId.size() > 0 && payerShare == amount`; `type == 'settle'` → `shared && payerShare == 0 && payer != 'fund'`; `splitMode in [...]`.
    - **update:** `auth.uid in resource.data.memberUids` và còn là thành viên; **bất biến** `type, memberUids, shared, createdBy, createdAt` (`diff().affectedKeys()` không chứa); `updatedBy == auth.uid`; `updatedAt == request.time`; `editCount == resource.data.get('editCount', 0) + 1`; mọi ràng buộc giá trị như create.
    - **delete:** `auth.uid in resource.data.memberUids` và còn là thành viên.
  - `expenseFunds/{id}`: read như trên; create `hasOnly`, `name` 1..40, `target` int 0..10 tỷ, `status == 'open'`, `createdAt == request.time`, `memberUids` như trên; update chỉ `name, emoji, target, status, updatedAt` (không chạm `reached100At`); không delete (đóng quỹ = `status: 'closed'`, giữ lịch sử). Giới hạn 5 quỹ mở chỉ ở client.
  - `expenseMeta/{doc}`: thành viên đọc/ghi, `hasOnly([monthlyBudget, categories, budgetAlerted, updatedAt])`, mọi khoá optional đọc bằng `data.get(...)`; client **không được đổi** `budgetAlerted` (`!diff().affectedKeys().hasAny(['budgetAlerted'])`); `categories.size() <= 20`; không delete.
  - Index composite: `expenses` (`memberUids` array-contains, `date` desc) cho sổ tháng · (`fundId`, `memberUids` array-contains) cho quỹ · (`type`, `shared`, `date`) cho aggregate ở CF.
  *Lý do:* chặn đúng 5 thứ lead yêu cầu (số âm, số quá lớn, chuỗi dài, sửa người tạo/thời điểm tạo, giả người tạo) + chặn người ngoài cặp và người mới ghép đọc sổ cũ.

- **D7 — Định dạng tiền và cách nhập:**
  - Hiển thị đầy đủ: `1.250.000 ₫` (vi) / `₫1,250,000` (en) qua `NumberFormat.currency(locale, symbol: '₫', decimalDigits: 0)`.
  - Hiển thị gọn (chip, biểu đồ, dòng cân bằng): `50k`, `1,2tr` (vi) / `50K`, `1.2M` (en). Không dùng gọn ở số tổng tháng.
  - Ô nhập: bàn phím số, hiện ngăn cách hàng nghìn khi gõ; nút nhanh `000`; 4 chip gợi ý **50k · 100k · 200k · 500k** (chạm = điền, chạm lần nữa = cộng dồn); nhận dán/gõ tắt "50k", "1tr", "1tr2", "1.5tr", "2 triệu", "1 củ" → parser thuần `parseVndInput` có test. Ô trống hoặc 0 → nút Lưu khoá.
  *Lý do:* người VN nói "50k", "1 củ"; ăn xong ghi phải dưới 5 giây.

- **D8 — Danh mục:** 8 mặc định, id cố định, tên + emoji theo ARB: 🍜 Ăn uống `food` · 💕 Hẹn hò `date` · 🛵 Đi lại `transport` · 🏠 Nhà cửa `home` · 🛍️ Mua sắm `shopping` · 🎁 Quà `gift` · ✈️ Du lịch `travel` · 📦 Khác `other`. Tự thêm tối đa 20 danh mục chung (tên ≤20 + chọn emoji) ở `expenseMeta/main.categories`; xoá danh mục tự thêm → khoản cũ hiện "Khác" (giữ `categoryId` cũ, map không thấy thì rơi `other`). Mặc định danh mục của khoản mới = danh mục dùng gần nhất trên máy. *Lý do:* 8 nhóm khớp gợi ý lead và nhóm của Money Lover/MISA bỏ bớt (không có "lương, đầu tư, hoá đơn điện nước riêng" vì gộp vào Nhà cửa). Icon là emoji để khỏi thêm bộ icon và để danh mục tự thêm dùng chung kiểu.

- **D9 — Cách chia, mặc định nhớ theo máy** *(PO tự chốt)*: 4 lựa chọn — **Chia đôi** (`equal`) · **Mình mời / người ấy mời** (`treat`, người trả chịu hết) · **Trả hộ** (`for_partner`, người kia chịu hết) · **Tuỳ** (`custom`, nhập phần người trả chịu, hoặc kéo tỉ lệ 10% một nấc). Mặc định lần đầu: **Chia đôi**; sau đó nhớ lựa chọn gần nhất trên máy. Khoản `memberUids` 1 người và khoản chi từ quỹ: `solo`, ẩn phần chọn. *Lý do:* có cặp chia sòng phẳng, có cặp "anh mời" là chính; nhớ lựa chọn trước thì mỗi cặp tự dừng ở thói quen của mình mà không cần màn cài đặt. Câu chữ tránh "nợ": "Anh đang ứng nhiều hơn 340k" thay vì "Em nợ anh 340k".

- **D10 — Push: KHÔNG push từng khoản chi.** Chỉ 3 trường hợp, qua 1 CF `notifyExpense` (xem §5). *Lý do:* cặp ghi 3–5 khoản/ngày, push mỗi khoản là spam; người ấy thấy khoản mới khi mở sổ. Ba trường hợp được push đều là "tin" thật: có người góp tiền, quỹ đủ, tháng vượt ngân sách.

- **D11 — Không `wakeClients`, không dòng trạng thái widget.** *Lý do:* không có lịch local hay widget nào cần đổi khi người ấy ghi khoản; widget nằm trên màn hình chính ai cũng nhìn thấy, chuyện tiền không nên lên đó (cùng lý do widget-today bỏ lời quan tâm). Đỡ tốn hạn mức đánh thức nền iOS cho 4 feature cùng đợt.

- **D12 — Nhắc tối, opt-in, mặc định TẮT, 21:30** (đổi giờ được), ở Cài đặt → Lời nhắc và trong màn Quỹ chung. Arm one-shot **hôm nay + ngày mai** (2 slot, dải id **1210–1211**, Lead xác nhận không trùng 4 feature cùng đợt) mỗi lần mở app; slot hôm nay huỷ ngay khi mình ghi khoản đầu tiên trong ngày (khoản do người ấy ghi không huỷ — lời nhắc hỏi chính mình). Copy xoay 3 câu. *Lý do:* mặc định tắt vì nhắc chuyện tiền mỗi tối dễ thành cằn nhằn; không dùng repeat `DateTimeComponents.time` (bẫy iOS nổ trùng — CLAUDE.md §6); 2 slot để ngày không mở app vẫn được nhắc mà chỉ tốn 2/64 slot iOS.

- **D13 — Rời couple, xoá tài khoản:**
  - Người ấy rời (còn mình): khoản chung **giữ nguyên**, mình vẫn đọc được (có tên trong `memberUids`); UI Phase 1 chỉ hiện khoản có `memberUids` khớp couple hiện tại + khoản riêng, khoản với người cũ ẩn (Phase 2: "Sổ cũ"). Cân bằng tính lại chỉ trên couple hiện tại. Người mới ghép vào không đọc được gì của cặp cũ (rules D2).
  - CF `notifyPartnerLeft` và `handleCoupleOnAccountDeletion`: **xoá khoản riêng của người rời** (`memberUids == [leaver]`, trong `expenses` và `expenseFunds`). Khoản chung giữ cho người ở lại.
  - Couple bị xoá hẳn (`deleteCoupleCompletely`): `recursiveDelete` `expenses`, `expenseFunds`, `expenseMeta` (thêm vào danh sách tường minh cạnh `decisions`, `sleep`).
  *Lý do:* khoản chung là lịch sử của cả hai, người ở lại có quyền giữ; khoản riêng của người rời thì không ai khác được thấy và người rời không còn tự xoá được (tiền lệ `sleep`).

- **D14 — Nối decision-wheel:** sheet kết quả kind `eat` và `go` thêm nút phụ **"Ghi chi"** → mở form thêm khoản với danh mục `food` (eat) / `date` (go), ghi chú = `result`, ngày = hôm nay, `source: 'decision'`. Kind `custom` không có nút. *Lý do:* "ăn xong là ghi" có sẵn điểm chạm ngay tại chỗ hai người vừa chốt món.

- **D15 — Offline:** dùng cache + hàng đợi ghi sẵn của Firestore. Ghi khi mất mạng vẫn lưu và hiện ngay trong sổ với dấu "đang chờ mạng" (`metadata.hasPendingWrites`); có mạng tự gửi. Không cần transaction ở đâu cả (autoId, cân bằng tính ở client). *Lý do:* ghi chi tiêu hay xảy ra ở quán có sóng yếu; khác decision-wheel (D19 bên đó) vì ở đây không có push nào phụ thuộc lúc ghi, và hai máy ghi cùng lúc tạo hai doc khác nhau, không đè nhau. Rủi ro duy nhất: ghi offline rồi người ấy rời couple trước khi có mạng → rules từ chối, client hiện "Không lưu được khoản này" (Dev bắt lỗi ở listener ghi).

- **D16 — Điểm vào UI (đề xuất, Designer chốt chung cả đợt):**
  - **Màn `ExpensesScreen`** (màn con, chip "QUỸ CHUNG" / "OUR MONEY"): đầu màn thẻ tháng (tổng chi, ngân sách còn lại, so tháng trước) · dải cân bằng (ẩn khi lệch 0 hoặc chưa ghép) · hàng quỹ đang mở (cuộn ngang) · danh sách theo ngày · nút thêm nổi.
  - **Lối vào chính:** một dòng/ô gọn ở Home (Designer gộp chung với lối vào các feature cùng đợt, vì Home đã dày). Nội dung đề xuất: "Hôm nay chúng mình chi 600k" hoặc, chưa có khoản: "+ Ghi khoản chi". Không hiện số dư quỹ hay cân bằng ở Home.
  - **Lối phụ:** tile ở Profile (dưới nhóm "Quan tâm") · nút "Ghi chi" ở sheet decision-wheel (D14) · tap push/inbox `expense_*`.
  - Màn con khác: form thêm/sửa khoản (sheet cao hoặc màn), chi tiết quỹ, tạo quỹ, báo cáo tháng (có thể là phần dưới của màn chính), cài đặt sổ (ngân sách, danh mục, nhắc).
  *Lý do:* thói quen "ăn xong ghi" cần lối vào ≤1 chạm từ Home; báo cáo thì không cần nằm ở Home.

- **D17 — Trạng thái phải thiết kế:** sổ rỗng lần đầu (giải thích 1 câu + nút ghi khoản đầu tiên) · tháng không có khoản · đang chờ người ấy (D3) · offline/đang chờ mạng (D15) · lỗi ghi bị từ chối · ngân sách chưa đặt / 80% / 100% / vượt · quỹ chưa có mục tiêu / đạt 100% / âm (chi quá số đã góp: cho phép, hiện "Quỹ đang thiếu 200k") · khoản người ấy cũ (ẩn) · khoản riêng (dấu ổ khoá "Chỉ mình thấy").

- **D18 — Analytics** (qua `AnalyticsService`, không gửi số tiền, ghi chú, tên quỹ, tên danh mục tự thêm):
  - `expense_add{type: expense|fund_in|settle, category: <id mặc định>|custom|none, payer: me|partner|fund, split: equal|treat|for_partner|custom|solo, private: bool, via: manual|chip|decision, has_note: bool}`
  - `expense_edit{field_count}` · `expense_delete{undone: bool}` · `expense_settle_open` · `fund_create{has_target: bool}` · `fund_close{reached: bool}` · `budget_set{action: set|clear}` · `expense_report_open{month_offset}` · `expense_reminder_toggle{on: bool}` · `expense_screen_open{from: home|profile|decision|push|inbox}`.

- **D19 — Mixed version:** app 1.10.x/1.11.0 không biết collection mới, không bị ảnh hưởng. Push/inbox `expense_fund` · `expense_fund_reached` · `expense_budget` tới máy bản cũ: tap rơi về Home (default), inbox type lạ — Dev kiểm cách render type lạ như D13 decision-wheel. Rules chỉ thêm match mới.

- **D20 — Không dùng AI, không liên kết ngân hàng, không OCR hoá đơn.** *Lý do:* luật đợt (không AI trả phí); liên kết ngân hàng cần đối tác + rủi ro bảo mật lớn hơn giá trị cho cặp chưa cưới.

- **D21 — Khai báo store:** dữ liệu chi tiêu là "Financial info → Other financial info" (Apple App Privacy) / "Thông tin tài chính → Thông tin tài chính khác" (Play An toàn dữ liệu) + cập nhật privacy policy `docs/`. Phải xong trước khi phát hành. *Lý do:* không khai là lý do từ chối duyệt; đây là việc ngoài code, cần user (xem §11).

## 5. Cloud Functions

**`notifyExpense`** — `onDocumentWritten` `couples/{coupleId}/expenses/{id}`, region us-central1, Node 22. Bỏ qua mọi dòng `shared == false`. Gửi qua `writeInboxNotifications` + `sendToRecipientDevices` (localize vi/en theo `languageCode`), **không `wakeClients`** (D11).

| Trường hợp | Gửi cho | vi | en | Inbox |
|---|---|---|---|---|
| Create `fund_in` | người không phải `createdBy` | Tiêu đề `{fundEmoji} {fundName}` · thân `{name} vừa góp vào quỹ, giờ được {percent}%` (không có mục tiêu: `{name} vừa góp thêm vào quỹ`) | `{fundEmoji} {fundName}` · `{name} just chipped in, the fund is at {percent}%` (no target: `{name} just added to the fund`) | `type: 'expense_fund'` `{fundId, actorName}` |
| Quỹ vừa đạt 100% mục tiêu (lần đầu: `reached100At` chưa có → CF ghi) | cả hai | `{fundEmoji} {fundName} đủ rồi!` · `Chúng mình góp đủ mục tiêu rồi. Lên lịch đi thôi.` | `{fundEmoji} {fundName} is full!` · `We hit the goal together. Time to plan it.` | `type: 'expense_fund_reached'` `{fundId}` |
| Tổng chi chung tháng `date` vượt 80% rồi 100% `monthlyBudget` (CF tính bằng aggregate `sum('amount')` trên `type=='expense' && shared && date trong tháng`; so `budgetAlerted[YYYY-MM]`, mỗi mốc 1 lần/tháng) | người **không** phải `updatedBy ?? createdBy` của dòng làm vượt | 80%: `Tháng này chúng mình đã tiêu 80% ngân sách` · `Còn {remaining} cho tới cuối tháng.` — 100%: `Tháng này mình tiêu hết ngân sách rồi` · `Đã chi {spent} trên {budget}. Chậm lại chút nhé.` | 80%: `We've used 80% of this month's budget` · `{remaining} left until the month ends.` — 100%: `We've used up this month's budget` · `{spent} of {budget} spent. Let's slow down a little.` | `type: 'expense_budget'` `{month, level}` |

- Số tiền trong push ngân sách (`{remaining}`, `{spent}`, `{budget}`) dùng dạng gọn ("1,2tr" / "1.2M"). *(PO tự chốt; user lật được: bỏ hẳn số tiền khỏi push vì hiện trên màn khoá — §11 câu 2.)* Push góp quỹ chỉ có %, không có số tiền.
- Tần suất ước lượng mỗi cặp: góp quỹ 2–8 lần/tháng · đạt mục tiêu ≤1 lần/quỹ · ngân sách ≤2 lần/tháng. Tổng < 0,5 push/ngày, không cần cooldown riêng. Không push khi sửa/xoá (trừ khi sửa làm vượt mốc ngân sách).
- Chi phí: mỗi lần ghi khoản `expense` shared có ngân sách → 1 aggregate (1 lượt đọc / 1000 doc) + 1 đọc `expenseMeta/main`. Khoản không có ngân sách: 1 đọc meta rồi dừng.
- Tap push/inbox → mở `ExpensesScreen` (`expense_fund*` thêm `focusFundId`); Dev thêm nhánh ở cả `push_notification_service._handleNotificationTap` lẫn `AppNotification` (2 chỗ map phải khớp — CLAUDE.md §6).
- Chưa có pref tắt riêng (như `care_message`); nếu Phase 2 thêm thì đi qua `PUSH_TYPE_PREF_FIELD`.
- Sửa thêm 3 hàm có sẵn theo D13: `notifyPartnerLeft`, `handleCoupleOnAccountDeletion`, `deleteCoupleCompletely`.
- PROD deploy đích danh khi phát hành: `firestore:rules,firestore:indexes,functions:notifyExpense,functions:notifyPartnerLeft,functions:deleteAccount,functions:leaveCoupleCleanup` — **chờ lệnh user**. Rules PROD phải lên trước khi bản có feature live.

## 6. Acceptance criteria (xong khi…)

Hai máy DEV: A = `test3`, B = `test4` (cặp đã ghép), C = `test1` (đang chờ).

- [ ] **Ghi nhanh:** A mở từ Home, gõ "120k" (hoặc chạm chip 100k rồi gõ thêm), chọn Ăn uống, Lưu → ≤3 chạm sau khi nhập số; khoản hiện ở sổ A ngay và ở sổ B trong ≤3 giây, B **không** nhận push.
- [ ] **Parser:** "50k"=50.000 · "1tr"=1.000.000 · "1tr2"=1.200.000 · "1.5tr"=1.500.000 · "2 triệu"=2.000.000 · "1 củ"=1.000.000 · "abc"/"0"/"" → khoá Lưu · số > 1 tỷ → báo lỗi tại ô, không gửi. Test Dart PASS.
- [ ] **Hiển thị tiền:** vi `1.250.000 ₫`, en `₫1,250,000`; chip gọn `50k`/`1,2tr` vi, `50K`/`1.2M` en.
- [ ] **Chia & cân bằng:** A trả 480k chia đôi → dải cân bằng cả hai máy "Anh đang ứng nhiều hơn 240k" (đúng tên/xưng hô từng máy). B trả 70k "Trả hộ" → lệch còn 170k. A "Mình mời" 200k → lệch không đổi. Tuỳ: A trả 300k, A chịu 100k → B lệch thêm 200k. Số lẻ 75.001 chia đôi → người trả chịu 37.501.
- [ ] **Thanh toán:** B bấm "Đánh dấu đã thanh toán" → dòng settle 170k + lệch về 0 ở cả hai; settle không vào tổng chi tháng. Trả một phần (100k) → còn 70k.
- [ ] **Sửa/xoá:** B sửa số tiền khoản A ghi → A thấy số mới + "Em sửa · hh:mm" ≤3 giây. A xoá rồi "Hoàn tác" trong 5 giây → không có lệnh xoá nào lên Firestore. A xoá, chờ 5 giây → biến mất cả hai máy.
- [ ] **Khoản riêng:** A bật "Chỉ mình thấy" ghi 90k → B không thấy (kể cả thử đọc thẳng doc bằng rules test); không vào tổng chung, không vào cân bằng; nằm ở phần "Của mình".
- [ ] **Sổ tháng:** seed 60 khoản 2 tháng → tổng tháng, % theo danh mục, theo người trả, chênh so tháng trước (+/− %) đúng với `ExpenseMath` test; lùi tháng xem được; tháng rỗng có empty-state.
- [ ] **Ngân sách:** đặt 5 triệu; ghi tới 4,1 triệu → cả hai thấy cảnh báo 80% trong app; người không ghi khoản đó nhận push 80% đúng 1 lần (ghi tiếp không lặp); vượt 5 triệu → push 100% đúng 1 lần; sang tháng mới → mốc reset. Client sửa `budgetAlerted` → rules từ chối.
- [ ] **Quỹ:** tạo "Quỹ Đà Lạt" 🏔️ mục tiêu 5 triệu; A góp 2 triệu → B nhận push "Anh vừa góp vào quỹ, giờ được 40%" + inbox (không có số tiền); B góp 3 triệu → cả hai nhận push "đủ rồi" đúng 1 lần; chi 1,2 triệu từ quỹ (payer = quỹ) → số dư 3,8 triệu, khoản đó vào tổng chi tháng, không vào cân bằng. Tạo quỹ thứ 6 khi đã có 5 quỹ mở → client chặn. Đóng quỹ → ẩn khỏi hàng quỹ, vẫn xem được trong "Quỹ đã đóng".
- [ ] **Cặp đang chờ (C):** dùng được sổ, không thấy ai trả/cách chia/cân bằng, có dòng giải thích D3. Ghép đôi C với tài khoản mới → khoản cũ vẫn chỉ C thấy, khoản mới vào sổ chung.
- [ ] **Rời couple:** B rời → A vẫn đọc khoản chung cũ ở DB, UI ẩn (D13); khoản riêng của B bị CF xoá; người mới ghép vào couple của A đọc thẳng doc cũ → `permission-denied`. Xoá tài khoản người cuối → `expenses`, `expenseFunds`, `expenseMeta` bị xoá hết.
- [ ] **Offline:** tắt mạng, ghi 2 khoản → hiện ngay với dấu chờ mạng; bật mạng → lên máy kia, dấu biến mất.
- [ ] **decision-wheel:** chốt "Bún chả" → sheet có "Ghi chi" → form mở sẵn Ăn uống + ghi chú "Bún chả" + hôm nay; `expense_add.via = decision`. Kind custom không có nút.
- [ ] **Nhắc tối:** mặc định tắt (không có id 1210/1211). Bật 21:30 → có 2 lịch (hôm nay, mai); ghi một khoản → id 1210 huỷ, 1211 còn; B ghi khoản → lịch của A không đổi; tắt → hết cả hai.
- [ ] **Rules** `scripts/test-firebase-rules.sh` PASS, ≥30 case mới: người ngoài đọc/ghi · người mới ghép đọc doc cũ · đọc khoản riêng của người kia · amount 0 / âm / 1.000.000.001 / số thực / chuỗi · payerShare âm hoặc > amount · note 101 ký tự · categoryId 25 ký tự · date sai định dạng · `createdAt != request.time` · giả `createdBy` · `memberUids` có uid lạ / thiếu mình / 3 phần tử · `shared` không khớp · payer lạ · `payer == 'fund'` không có `fundId` · settle không shared / payerShare ≠ 0 · update đổi `type`/`memberUids`/`createdBy`/`createdAt` · `editCount` nhảy 2 · `updatedBy` giả · client ghi `reached100At` / `budgetAlerted` · xoá quỹ · `categories` 21 mục · currency 'USD' · doc thiếu `currency` vẫn tạo được.
- [ ] **CF:** test emulator 3 trường hợp push + không push khoản thường + không push khoản riêng + mỗi mốc ngân sách 1 lần/tháng + dọn khi rời/xoá; deploy DEV có vết; PROD chưa deploy.
- [ ] **Analytics:** DebugView có đủ event D18; grep payload không có số tiền, ghi chú, tên quỹ.
- [ ] i18n vi + en đủ (8 danh mục, form, sổ, báo cáo, quỹ, cân bằng, nhắc, push/inbox, empty-state); `flutter analyze` 0; test Dart cho `parseVndInput`, định dạng tiền, `ExpenseMath` (tổng, theo danh mục, cân bằng 4 cách chia + settle, quỹ, lọc khoản người cũ, khoản riêng).
- [ ] Không regression Home (thứ tự thẻ, entrance), decision-wheel sheet, notification center, cleanup khi rời couple của `sleep`/`decisions`.

## 7. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)

- 🎨 **Designer:** lối vào Home (chốt chung với 4 feature cùng đợt) · màn Quỹ chung (thẻ tháng, dải cân bằng, hàng quỹ, danh sách ngày) · form thêm/sửa (ô số + chip + parser, danh mục, ai trả, cách chia, riêng tư, ngày) · báo cáo tháng (biểu đồ danh mục chọn kiểu đọc được với 8–28 danh mục) · quỹ (tạo, chi tiết, tiến độ, đóng) · thanh toán · cài đặt sổ · mọi trạng thái D17 · copy vi/en "chúng mình". Tra UI UX Pro Max (luật 8), đối chiếu `design-system.md`. → *expect:* `design.md` + mock bấm thử.
- 💻 **Dev:** (1) `parseVndInput`, formatter, `ExpenseMath` thuần + test; (2) `ExpenseService` + `ExpenseProvider` (listener tháng đang xem + quỹ + meta, wire ở `session_resolver` — nhớ named-param `_resolve`, clear khi sign-out/no-couple); (3) UI các màn; (4) nút "Ghi chi" ở sheet decision-wheel; (5) nhắc band 1210–1211; (6) rules + index + test + CF `notifyExpense` + sửa 3 hàm dọn + nhánh tap push/inbox 2 chỗ; (7) analytics; (8) ARB + `gen-l10n`; (9) deploy DEV. Đụng rules/functions → `effort: high`. → *expect:* nhánh feature, analyze 0, rules test PASS, smoke 2 máy DEV.
- 🧪 **Tester:** 18 tiêu chí §6 trên 2 máy (`test3`/`test4`) + `test1`; soi rules (người mới ghép, khoản riêng, giả tác giả, số biên); hai máy cùng sửa một khoản (last write wins, `editCount` từ chối bản thứ hai → client báo và tải lại); đổi múi giờ; bản 1.11.0 nhận push mới. → *expect:* bảng PASS/FAIL trong `test.md`.

## 8. Nợ kỹ thuật / rủi ro (Tester soi)

- 🟡 **Hai người sửa cùng một khoản cùng lúc:** rules `editCount == cũ + 1` làm bản thứ hai bị từ chối (Firestore client có thể đã hiện tạm). Client phải bắt lỗi, báo "Người ấy vừa sửa khoản này" và hiện bản mới.
- 🟡 **Ghi offline rồi couple đổi** (người ấy rời trước khi có mạng) → rules từ chối, mất khoản ghi tạm. Hiếm; client báo lỗi (D15).
- 🟡 **Cân bằng tính ở client** từ toàn bộ khoản shared từ đầu → cặp ghi lâu năm (vài nghìn dòng) tải nặng. Phase 1 chấp nhận (28 cặp); Phase 2: CF giữ số tổng trong `expenseMeta` hoặc aggregate `sum` theo người.
- 🟡 **Ngày theo máy người ghi** (lệch múi giờ cặp yêu xa) — như câu hỏi hằng ngày.
- 🟡 **iOS 64 thông báo chờ:** +2 slot (1210–1211) khi bật nhắc. Tổng các band đã sát giới hạn — Lead cộng lại cả đợt.
- 🟡 **Khoản với người ấy cũ bị ẩn ở UI** dù còn trong DB; người ở lại có thể hỏi "sổ cũ đâu". Phase 2 "Sổ cũ".
- 🟡 **Quỹ âm** được phép (chi trước góp sau); chỉ cảnh báo.
- 🟢 Riêng tư: push không có ghi chú hay số tiền khoản chi; push ngân sách có số gọn (xem §11 câu 2). Widget không hiện gì về tiền.
- 🟢 Không giới hạn số khoản người dùng thấy được; lạm dụng chỉ tốn chính quota của cặp đó.

## 9. Metric đo thành công

Đo sau 30 ngày phát hành (`AnalyticsService` + script đọc-only kiểu `scripts/prod-retention-stats.js`):
- **% cặp đã ghép có ≥1 khoản chung mỗi tuần.** Mục tiêu ≥35% (≈10/28 cặp).
- **Số ngày/tuần có ghi khoản** ở cặp đang dùng. Mục tiêu trung vị ≥3 ngày/tuần (thói quen "ăn xong ghi" thành thật).
- **Ngày mở app chỉ vì sổ:** % ngày-cặp có `expense_add` mà không có hoạt động khác (câu hỏi, tâm trạng, chat, ảnh). >0 là sổ đang kéo thêm ngày mở app, đúng mục tiêu đợt.
- **Cặp đang chờ:** % trong 52 cặp ghi ≥3 khoản trong 7 ngày đầu. Mục tiêu ≥15%; so tỉ lệ ghép đôi trong 30 ngày giữa nhóm có dùng sổ và nhóm không.
- **Phụ:** số quỹ tạo, % quỹ có ≥2 lần góp từ 2 người; `expense_add.via = decision` / tổng lượt chốt eat của decision-wheel.

## 10. Phụ thuộc / đụng chạm với feature cùng đợt

- **decision-wheel** (đã xong, chờ phát hành 1.11.0): thêm nút ở sheet kết quả (D14) — sửa file của feature đó, Dev báo PO decision-wheel cập nhật changelog.
- **poke, caro-game, weather, arrival:** cùng sửa `functions/index.js`, `firestore.rules`, `firestore.indexes.json`, ARB, `session_resolver` (named-param), `AnalyticsEvents`, `NotificationTapRouter` + `AppNotification.targetHomeTab` → Lead xếp thứ tự merge để tránh xung đột. Dải id local: feature này xin **1210–1211**; Lead đối chiếu với band 4 feature kia. Lối vào Home: Designer chốt một lần cho cả 5.
- **widget-today:** không thêm loại trạng thái (D11).

## 11. Câu hỏi cho user

1. **Rời couple — sổ chung giữ hay xoá?** PO chốt (D13): người ở lại giữ khoản chung (ẩn ở UI Phase 1), khoản riêng của người rời bị xoá, người ghép mới không đọc được sổ cũ. Nếu anh muốn "rời là xoá sạch sổ chung" như cách làm với giấc ngủ, báo để đổi trước khi Dev làm.
2. **Push ngân sách có hiện số tiền không?** PO để số gọn ("Còn 1,2tr cho tới cuối tháng") vì có số mới hành động được. Nó hiện trên màn khoá. Muốn bỏ số → copy chỉ còn "đã tiêu 80% ngân sách".
3. **Khai báo store + privacy policy (D21):** cần anh duyệt cập nhật Apple App Privacy, Play An toàn dữ liệu (thêm "Thông tin tài chính khác") và sửa privacy policy trước khi gửi duyệt bản có feature này.

## 12. Changelog feature
- [2026-10-20] [PO] Tạo feature từ lựa chọn của user trong đợt "mở app mỗi ngày" lần 2 ("có tính năng giống như app quản lý chi tiêu"). Research Money Lover, Sổ Thu Chi MISA, Splitwise, Honeydue → bảng lọc tính năng cho cặp đôi (§2). Chốt D1–D21: một collection `expenses` 3 loại dòng, quyền xem theo `memberUids` chụp lúc tạo (chặn người ghép mới đọc sổ cũ + có sẵn khoản riêng + sổ một người cho 52 cặp đang chờ), `payerShare` một số cho 4 cách chia, cả hai sửa/xoá có "ai sửa", không push từng khoản (chỉ góp quỹ / đủ quỹ / ngân sách 80–100%), không `wakeClients`, không widget, nhắc tối mặc định tắt band 1210–1211, nút "Ghi chi" ở decision-wheel. 3 câu hỏi cho user ở §11.
