# Sổ tiền — quản lý tiền của mình và của chúng mình

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Đợt "mở app mỗi ngày" lần 2 (user chọn 2026-10-20 cùng `poke`, `caro-game`, `weather`, `arrival`). Nối với [decision-wheel](../decision-wheel/overview.md) qua nút "Ghi chi" (D20).
> ⟪Lịch sử: spec đầu 2026-10-20 là "Quỹ chung" — sổ chi chung của cặp. Cùng ngày user nói "Feature Quỹ chung làm nó giống money management" → mở rộng thành app quản lý tiền đầy đủ: mỗi người một sổ riêng + một sổ chung. Tên thư mục giữ `expenses`; tên hiển thị chờ user chọn (§11).⟫

- **Feature:** expenses (tên hiển thị đề xuất: **Sổ tiền**)
- **Ưu tiên:** P1 — feature lớn nhất đợt, chia 3 mốc phát hành (§3)
- **Trạng thái:** 📋 Spec — chờ user chọn tên (§11)
- **Tạo ngày:** 2026-10-20
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · [`../decision-wheel/`](../decision-wheel/overview.md) · [`../widget-today/`](../widget-today/overview.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) · rules/CF [`../../firebase.md`](../../firebase.md)

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:*
  - Tối thứ Sáu ăn lẩu hết 480k, anh quẹt thẻ. Thứ Bảy em đổ xăng 70k bằng MoMo. Chủ nhật hai người ngồi nhớ lại ai trả gì và không ai nhớ.
  - Quỹ đi Đà Lạt nằm trong ghi chú điện thoại của một người. Người kia muốn biết còn bao nhiêu thì phải hỏi.
  - Tiền của riêng mỗi người (lương về, tiền nhà, tiền điện, tháng này còn bao nhiêu) thì đang nằm ở một app khác: Money Lover, MISA, hoặc không ở đâu cả.
- *Giả thuyết giá trị:* gộp hai thứ vào một chỗ. Sổ **của mình** dùng được như Money Lover: ví tiền mặt, Techcombank, MoMo, thẻ tín dụng; thu, chi, chuyển; ngân sách; báo cáo. Sổ **chung** thêm thứ app tài chính không có: ai trả, chia thế nào, ai đang ứng nhiều hơn, quỹ chung. Ghi một khoản mất 3 chạm ("120k" → Ăn ngoài → Lưu). Người ta ghi chi tiêu gần như mỗi ngày, nên đây là một lý do mở app không phụ thuộc vào việc người ấy có trả lời câu hỏi hay không.
- *Đối tượng:*
  - **Cặp đang chờ người ấy (52/80 cặp, PROD 2026-10-19):** sổ của mình là thứ đầu tiên trong app có giá trị trọn vẹn khi dùng một mình. Hôm nay một người vào app khi chưa có người ấy chỉ thấy đếm ngày và lời nhắc. Có sổ tiền, người đó có việc để làm mỗi ngày, và khi người ấy vào thì sổ chung mở ra ngay cạnh (CLAUDE.md §11: "single-player value trước partner join là then chốt").
  - **Cặp đã ghép (28 cặp):** sổ của mình + sổ chung.
- *Đo bằng gì:* §9.

## 2. Bối cảnh / nghiên cứu

Đối chiếu 6 app (nguồn cuối mục), lọc theo câu hỏi "người trẻ VN, đang yêu, quen MoMo/ZaloPay, cần gì":

| Tính năng | Ai có | Quyết định | Mốc |
|---|---|---|---|
| Ví/tài khoản nhiều loại, số dư đầu kỳ, số dư hiện tại | Money Lover, MISA, Wallet, Spendee (mỗi ví 1 tiền tệ) | Làm — lõi | A |
| Thu / Chi / Chuyển giữa ví / Điều chỉnh số dư | Mọi app | Làm — lõi | A |
| Danh mục thu–chi 2 cấp, icon, tự thêm/sửa/ẩn | Money Lover, MISA | Làm | A |
| Ngân sách theo tháng, tổng + theo danh mục, cảnh báo | Money Lover (tuần/tháng/quý), MISA (hạn mức theo hạng mục), Wallet, Spendee (bản free 1 ngân sách) | Làm theo tháng, không giới hạn số ngân sách | A |
| Báo cáo thu–chi, cơ cấu, xu hướng, theo ví | MISA (biểu đồ tròn/cột), Wallet (cash flow, xu hướng số dư) | Làm | A |
| Tìm kiếm + lọc | Mọi app | Làm | A |
| Mục tiêu tiết kiệm | Money Lover (Tiết kiệm), Wallet (Goals: đang chạy/tạm dừng/đã đạt, cần để dành bao nhiêu mỗi kỳ) | Làm dưới dạng ví "Mục tiêu" | A |
| Ví chia sẻ cho người khác | MISA (chia sẻ ví), Wallet (chia sẻ tài khoản), Spendee (trả phí) | Làm — là sổ chung, miễn phí | A |
| Ai trả, chia tỉ lệ, ai đang ứng, thanh toán | Splitwise | Làm — không app VN nào có | A |
| Ẩn giao dịch khỏi người kia | Honeydue | Có sẵn nhờ tách sổ riêng / sổ chung | A |
| Khoản định kỳ + nhắc hoá đơn | Wallet (planned payments), Honeydue (60% user tạo nhắc hoá đơn lúc onboarding), Money Lover | Làm | B |
| Sổ nợ (cho vay / đi vay) | Money Lover, MISA | Làm | B |
| Xuất CSV/Excel | MISA (Excel/PDF), Spendee (cả bản free) | Làm CSV | B |
| Khoá bằng Face ID / vân tay | Money Lover, MISA | Làm | B |
| Ảnh hoá đơn | Splitwise (Pro), Wallet | Làm | C |
| Đa tiền tệ | Spendee, Wallet, Splitwise (Pro) | Chừa sẵn field, làm sau | Later |
| Liên kết ngân hàng, tự kéo giao dịch | Money Lover (>25 ngân hàng VN), Wallet (3.500 ngân hàng), Honeydue (Plaid) | **Không làm** — cần đối tác, rủi ro bảo mật, chi phí | — |
| Đầu tư, chứng khoán, nhiều sổ kế toán | MISA, Wallet | Không làm — vượt niche | — |

Bài học: Splitwise khoá chia tỉ lệ và giới hạn số khoản/ngày ở bản miễn phí từ cuối 2023, bị review 1 sao nhiều. Spendee bắt trả phí mới chia sẻ ví. Mình không giới hạn gì người dùng nhìn thấy; các trần chỉ để chặn lạm dụng ở rules.

Nguồn:
- Money Lover: [FPT Shop](https://fptshop.com.vn/tin-tuc/danh-gia/money-lover-182808) · [Thế Giới Di Động](https://www.thegioididong.com/game-app/money-lover-ung-dung-quan-ly-chi-tieu-ca-nhan-gia-dinh-228454) · [TGDĐ — cách dùng (Sự kiện, Tiết kiệm)](https://www.thegioididong.com/game-app/cach-su-dung-money-lover-chi-tiet-giup-quan-ly-chi-tieu-hieu-1311173)
- MISA: [Sổ Thu Chi MISA](https://sme.misa.vn/37480/so-thu-chi-ung-dung-quan-ly-tai-chinh-ca-nhan-danh-cho-moi-nguoi/) · [App Store (chia sẻ ví)](https://apps.apple.com/vn/app/s%E1%BB%95-thu-chi-misa-qu%E1%BA%A3n-l%C3%BD-ti%E1%BB%81n/id865818973?l=vi) · [FPT Shop](https://fptshop.com.vn/tin-tuc/danh-gia/so-thu-chi-misa-185508)
- Wallet by BudgetBakers: [Beebom review](https://beebom.com/wallet-app-by-budgetbakers-review/amp/) · [APKMirror release notes](https://www.apkmirror.com/apk/budgetbakers-com/wallet-budget-tracker/wallet-budget-expense-tracker-9-2-15-release/)
- Spendee: [Support (chia sẻ ví)](https://www.spendee.com/support) · [Premium](https://www.spendee.com/premium) · [App Store](https://apps.apple.com/app/id635861140)
- Splitwise: [App Store](https://apps.apple.com/app/splitwise-bill-splitter/id458023433) · [Yellow Slice review](https://www.yellowslice.in/blog/splitwise-app-review-ux-ui-improvements) · [Trustpilot](https://pt.trustpilot.com/review/splitwise.com?page=2)
- Honeydue: [Experian](https://www.experian.com/blogs/ask-experian/honeydue-app-review/) · [TechCrunch](https://techcrunch.com/2017/08/07/honeydue-is-a-money-management-app-for-couples/)

Hạ tầng tái dùng: `isCoupleMember` · `writeInboxNotifications` + `sendToRecipientDevices` · `handleCoupleOnAccountDeletion` / `deleteCoupleCompletely` / `deleteAccount` · aggregate `count()` (đã dùng) nay thêm `sum()` · `share_plus` (đã có trong pubspec, dùng cho CSV) · `SubScreenHeader`, `ContentCard`, `InkTile`, `SectionHeader` · `MidnightBuilder` · `intl` `NumberFormat`.

## 3. Phạm vi — 3 mốc phát hành

Feature quá lớn cho một bản. Mỗi mốc là một bản phát hành MINOR riêng, mốc A tự đứng được.

- **Mốc A — "Dùng thay Money Lover được" (bản phát hành đầu):**
  1. **Hai sổ:** "Của mình" (mọi tài khoản) và "Chung" (chỉ khi couple `active`). Cặp đang chờ chỉ thấy sổ của mình, đầy đủ tính năng.
  2. **Ví:** Tiền mặt · Ngân hàng · Ví điện tử · Thẻ tín dụng · Mục tiêu. Số dư đầu kỳ, số dư hiện tại tính từ giao dịch, ẩn/lưu trữ ví, "không tính vào tổng".
  3. **Giao dịch:** Chi · Thu · Chuyển giữa ví · Điều chỉnh số dư. Ô số nhanh (chip, gõ tắt), danh mục, ghi chú, ngày, ví.
  4. **Danh mục 2 cấp** thu và chi, icon emoji, thêm/sửa/ẩn (mỗi sổ một bộ).
  5. **Ngân sách tháng:** tổng + theo danh mục, cảnh báo 80%/100%.
  6. **Báo cáo:** thu–chi–còn lại theo tháng · cơ cấu chi theo danh mục · xu hướng 6 và 12 tháng · theo ví · (sổ chung) theo người.
  7. **Tìm kiếm + lọc:** khoảng ngày, danh mục, ví, người (sổ chung), khoảng tiền, chữ trong ghi chú.
  8. **Mục tiêu tiết kiệm** = ví loại Mục tiêu, có mục tiêu + hạn; "Quỹ Đà Lạt" là ví Mục tiêu trong sổ chung.
  9. **Phần cặp đôi:** ai trả · 4 cách chia · ai đang ứng nhiều hơn · đánh dấu đã thanh toán · góp từ ví của mình vào ví chung · "trừ luôn vào ví của mình" khi trả khoản chung.
  10. Nút "Ghi chi" ở decision-wheel · nhắc tối opt-in · push sổ chung (góp quỹ, đủ quỹ, ngân sách) · rules + CF + dọn dữ liệu · vi + en · analytics không lộ tiền.
- **Mốc B — "Tiền chạy đều mỗi tháng":** khoản định kỳ (lương, tiền nhà, điện nước, Netflix) tự sinh hoặc chỉ nhắc + nhắc hoá đơn · sổ nợ (cho vay/đi vay với người ngoài) · xuất CSV · khoá Face ID/vân tay cho Sổ tiền.
- **Mốc C — "Bằng chứng & tiện ích":** ảnh hoá đơn · lịch sử sửa từng lần · "Sổ cũ" (khoản chung với người ấy cũ sau khi rời) · chuyển khoản riêng sang sổ chung.
- **Later:** đa tiền tệ · nhập từ Money Lover/MISA (CSV) · recap tháng dạng thẻ chia sẻ.
- **Không bao giờ:** liên kết ngân hàng, kéo giao dịch tự động, quét SMS biến động số dư, đầu tư, AI phân loại trả phí.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý. *(PO tự chốt)* = user lật được trước khi Dev bắt đầu.

- **D1 — Hai sổ cùng một cấu trúc dữ liệu, khác chỗ ở.** Sổ riêng ở `users/{uid}/…`, sổ chung ở `couples/{coupleId}/…`. Tên collection và schema giống hệt; service nhận "gốc sổ" làm tham số. *Lý do:* (a) Lead chốt: tiền riêng là của người dùng, không gắn với couple, rời couple không mất; (b) một bộ màn hình, một bộ hàm tính, hai đường dẫn — giảm gần một nửa công sức so với hai mô hình.

- **D2 — Sổ riêng sống theo tài khoản.** Chỉ chủ đọc/ghi. Rời couple, ghép couple mới: sổ riêng giữ nguyên. Xoá tài khoản: CF `deleteAccount` xoá sạch. *Lý do:* Lead chốt; cũng là cách duy nhất để 52 cặp đang chờ dùng sổ mà không phải di trú dữ liệu khi người ấy vào.

- **D3 — Sổ chung: quyền xem theo `memberUids` chụp lúc tạo.** Mọi doc sổ chung mang `memberUids` = `couple.memberIds` tại thời điểm tạo (đúng 2 người, đúng thứ tự). Đọc khi là thành viên **và** có tên trong `memberUids`. *Lý do:* người ấy rời, người mới ghép vào cùng `coupleId` không đọc được tiền của cặp cũ, rules chặn chứ không chỉ UI giấu. Hệ quả: truy vấn sổ chung luôn có `where('memberUids', isEqualTo: couple.memberIds)` (đủ để rules chứng minh và lọc luôn khoản với người cũ).

- **D4 — Rời couple, xoá tài khoản** (user chốt 2026-10-20: "người ở lại giữ sổ chung"):
  - Người ấy rời: sổ chung **giữ nguyên trong DB**, người ở lại vẫn đọc được. Mốc A: UI chỉ hiện doc có `memberUids` khớp couple hiện tại, nên sổ chung trông trống sau khi người ấy rời; mốc C thêm "Sổ cũ". Sổ riêng của cả hai không đổi.
  - Người mới ghép vào couple của người ở lại: không đọc được gì của cặp cũ (D3), bắt đầu sổ chung mới.
  - Xoá tài khoản: `deleteAccount` `recursiveDelete` 7 collection sổ riêng của người đó (D6). Khoản chung giữ cho người ở lại.
  - Couple bị xoá hẳn (`deleteCoupleCompletely`): `recursiveDelete` 7 collection sổ chung (thêm vào danh sách tường minh cạnh `decisions`, `sleep`).
  - `notifyPartnerLeft` **không** xoá gì của feature này.

- **D5 — Cặp đang chờ thấy đúng một sổ.** Tab "Chung" ẩn, thay bằng một thẻ nhỏ cuối sổ: "Khi người ấy vào, chúng mình sẽ có thêm sổ chung: ai trả, chia đôi, quỹ đi chơi." (một dòng, không che sổ). *Lý do:* sổ riêng phải dùng trọn vẹn một mình; thẻ nhỏ nhắc thêm một lý do để mời người ấy mà không biến sổ thành quảng cáo mời.

- **D6 — Mô hình dữ liệu.** `{book}` = `users/{uid}` (riêng) hoặc `couples/{coupleId}` (chung). Khoá đánh dấu **[chung]** chỉ có ở sổ chung.

```
{book}/moneyWallets/{autoId}
  name: string 1..30              // "Techcombank", "MoMo", "Quỹ Đà Lạt"
  type: 'cash'|'bank'|'ewallet'|'credit'|'goal'
  emoji: string ≤8                color: string ≤12 (id màu trong bảng Designer)
  currency?: 'VND'                // optional, thiếu = VND (để dành đa tiền tệ)
  openingBalance: int             // -10_000_000_000..100_000_000_000 (thẻ tín dụng có thể âm)
  includeInTotal: bool            archived: bool       order: int
  goalTarget?: int 1..100_000_000_000   goalDeadline?: 'YYYY-MM-DD'   // chỉ type goal
  goalReachedAt?: timestamp       // CHỈ CF ghi (sổ chung) / client ghi (sổ riêng)
  memberUids [chung]: list<uid>   // bất biến
  createdBy: uid  createdAt: == request.time   // bất biến
  updatedAt?: == request.time

{book}/moneyTx/{autoId | 'rec_<recId>_<YYYY-MM-DD>'}
  type: 'expense'|'income'|'transfer'|'adjust'|'contribution'|'settle'
  amount: int 1..10_000_000_000   // luôn dương; hướng tiền nằm ở 2 khoá dưới
  outWalletId: string ≤40         // ví bị trừ; '' nếu không trừ ví nào trong sổ này
  inWalletId: string ≤40          // ví được cộng; '' nếu không
  date: 'YYYY-MM-DD'              // ngày phát sinh, người dùng chọn
  categoryId: string ≤40          // expense/income; còn lại ''
  note: string ≤200
  linkId?: string ≤40             // nối 2 doc ở 2 sổ (D11); bất biến
  recurringId?: string ≤40        // doc do khoản định kỳ sinh ra (mốc B)
  source?: 'manual'|'decision'|'recurring'
  payer [chung]: uid | 'wallet'   // 'wallet' = trả từ ví chung, không tạo nợ
  splitMode [chung]: 'equal'|'treat'|'for_partner'|'custom'|'none'
  payerShare [chung]: int 0..amount   // phần người trả tự chịu
  memberUids [chung]: list<uid>   // bất biến
  createdBy: uid  createdAt: == request.time    // bất biến
  updatedBy?: uid  updatedAt?: == request.time  editCount?: int

{book}/moneyBudgets/{autoId}
  categoryId: string ≤40          // '' = ngân sách tổng
  amount: int 1..10_000_000_000   // mỗi tháng, áp tới khi sửa/xoá
  createdBy, createdAt, updatedAt?
  alerted [chung]?: map<'YYYY-MM', 80|100>   // CHỈ CF ghi

{book}/moneyMeta/main
  customCategories?: list<map{id, kind: expense|income, parentId ('' = cấp 1), name ≤24, emoji ≤8}>  // ≤80
  overrides?: map<categoryId, map{name ≤24, emoji ≤8}>   // sửa tên/icon danh mục mặc định
  hiddenCategoryIds?: list<string>  // ≤120
  defaultWalletId?: string ≤40     // nhắc tối KHÔNG lưu ở đây — lưu Hive (D18)
  updatedAt?

// Mốc B
{book}/moneyRecurring/{autoId}    // khoản định kỳ: mẫu giao dịch + lịch
  template: map (type, amount, outWalletId, inWalletId, categoryId, note, payer/splitMode/payerShare [chung])
  freq: 'daily'|'weekly'|'monthly'|'yearly'   interval: int 1..12   dayOfMonth?: 1..31
  startDate, endDate?: 'YYYY-MM-DD'   nextDate: 'YYYY-MM-DD'
  mode: 'auto'|'remind'           // tự sinh giao dịch hay chỉ nhắc
  remindDaysBefore: 0..7          paused: bool
  memberUids [chung], createdBy, createdAt, updatedAt?
users/{uid}/moneyDebts/{autoId}   // CHỈ sổ riêng (D14)
  direction: 'lend'|'borrow'   person: string 1..40   amount: int 1..10_000_000_000
  paid: int 0..amount   dueDate?: 'YYYY-MM-DD'   note ≤200   status: 'open'|'closed'
  createdAt, updatedAt?
```

  *Lý do chọn `outWalletId`/`inWalletId` thay vì số có dấu:* số dư ví = `openingBalance + Σ amount (inWalletId == ví) − Σ amount (outWalletId == ví)`, đúng 2 truy vấn aggregate `sum()` mỗi ví, đúng cho cả chuyển ví lẫn điều chỉnh, và rules vẫn ép `amount > 0`. Chi = trừ ví, Thu = cộng ví, Chuyển = trừ ví này cộng ví kia, Điều chỉnh = một trong hai.

- **D7 — Quy ước tính** (Dev viết hàm thuần `MoneyMath` có test):
  - **Chi/thu tháng** = Σ `expense` / Σ `income` theo `date` trong tháng. `transfer`, `adjust`, `contribution`, `settle` không vào thu–chi (chỉ đổi số dư). Ví `includeInTotal == false` và ví Mục tiêu không vào "Tổng tài sản".
  - **Còn lại** = thu − chi của tháng.
  - **Cân bằng sổ chung** = với mọi `expense`/`settle` có `payer` là một người: người kia "đang được ứng" `amount − payerShare`. Cộng dồn từ đầu, không reset theo tháng. `payer == 'wallet'` và `contribution` không tạo nợ.
  - **Thanh toán** = `settle`, `payer` = người ứng ít hơn (người đang phải trả lại), `payerShare = 0`, `amount` = số lệch (sửa được khi trả một phần), không trừ ví nào. Không vào chi.
  - **Góp vào ví chung** = `contribution` ở sổ chung (`inWalletId` = ví chung, `payer` = người góp). Góp của mỗi người = Σ theo `payer` (em ghi hộ "anh góp 1 triệu" được).
  - **Chia đôi số lẻ:** `payerShare = ceil(amount / 2)`.
  - **Tiến độ mục tiêu** = số dư ví Mục tiêu / `goalTarget`; còn `goalDeadline` thì hiện "cần để dành ~X mỗi tháng" (như Wallet).

- **D8 — Ví mặc định khi tạo sổ:** sổ riêng tạo sẵn 1 ví "Tiền mặt" số dư 0 lần đầu mở; người dùng thêm ví khác trong onboarding 1 màn (chọn nhanh: Tiền mặt · Ngân hàng · MoMo · ZaloPay · Thẻ tín dụng, nhập số dư hiện tại hoặc bỏ qua). Sổ chung tạo sẵn 1 ví "Ví chung" khi couple `active` lần đầu mở tab Chung. *Lý do:* giao dịch nào cũng cần một ví; bắt người mới tạo ví trước khi ghi khoản đầu tiên làm rơi người dùng ở bước 1. Gợi ý MoMo/ZaloPay vì đó là ví người trẻ VN dùng thật; chỉ là tên + emoji, không liên kết.

- **D9 — Danh mục 2 cấp, mặc định chung cho cả hai sổ** (id cố định, tên theo ARB; Designer được đổi emoji, Dev không tự đổi tên):
  - **Chi:** 🍜 Ăn uống (Ăn ngoài · Đi chợ, siêu thị · Cà phê, trà sữa · Ăn vặt) · 💕 Hẹn hò (Xem phim · Đi chơi · Quà cho người ấy) · 🛵 Đi lại (Xăng xe · Gửi xe · Grab, taxi · Sửa xe) · 🏠 Nhà cửa (Tiền nhà · Điện · Nước · Internet · Đồ dùng nhà) · 📱 Hoá đơn & gói (Điện thoại · Xem phim, nghe nhạc · Phần mềm) · 🛍️ Mua sắm (Quần áo · Mỹ phẩm · Đồ điện tử) · 💊 Sức khoẻ (Thuốc · Khám bệnh · Thể thao) · 📚 Học tập (Học phí · Sách, khoá học) · 🎁 Quà & hiếu hỉ (Quà tặng · Đám cưới, đám hiếu · Lì xì) · 👨‍👩‍👧 Gia đình (Biếu bố mẹ · Thú cưng) · ✈️ Du lịch (Vé · Chỗ ở · Ăn chơi) · 📦 Khác.
  - **Thu:** 💼 Lương · 🎉 Thưởng · 🧑‍💻 Làm thêm · 🧧 Được cho, tặng · 📈 Lãi, đầu tư · 💰 Thu khác.
  - Mỗi sổ tự thêm (≤80), sửa tên/icon (cả mặc định, qua `overrides`), ẩn (`hiddenCategoryIds`) độc lập. Danh mục bị ẩn vẫn hiện đúng trên khoản cũ. Xoá danh mục tự thêm → khoản cũ hiện "Khác" (map không thấy id thì rơi `other`).
  - Khoản mới mặc định danh mục dùng gần nhất trong sổ đó.
  *Lý do:* 12 nhóm chi gọn hơn Money Lover/MISA, thêm "Hẹn hò" và "Quà cho người ấy" cho đúng app cặp đôi; bỏ "Đầu tư/Vay" vì không làm.

- **D10 — Nhập và hiển thị tiền:**
  - Đầy đủ: `1.250.000 ₫` (vi) / `₫1,250,000` (en) qua `NumberFormat.currency(locale, symbol: '₫', decimalDigits: 0)`. Số âm: `−320.000 ₫`.
  - Gọn (chip, trục biểu đồ, dòng cân bằng): `50k`, `1,2tr`, `3,5 tỷ` (vi) / `50K`, `1.2M`, `3.5B` (en). Không dùng dạng gọn ở số dư ví và tổng tháng.
  - Ô nhập: bàn phím số, ngăn cách hàng nghìn khi gõ, nút `000`, 4 chip **50k · 100k · 200k · 500k** (chạm = điền, chạm tiếp = cộng dồn); hiểu "50k", "1tr", "1tr2", "1.5tr", "2 triệu", "1 củ", "1 tỏi" → parser thuần `parseVndInput` có test. 0, trống, sai → khoá Lưu. Vượt trần → báo ngay ở ô.
  *Lý do:* người VN nói "50k", "1 củ"; ăn xong mà phải gõ 6 số 0 thì không ai ghi.

- **D11 — Hai sổ nối nhau bằng cặp doc cùng `linkId`** (ghi bằng 1 batch):
  - **Góp vào ví chung từ ví của mình:** sổ riêng `contribution` (`outWalletId` = ví mình) + sổ chung `contribution` (`inWalletId` = ví chung, `payer` = mình).
  - **Trả khoản chung bằng tiền của mình:** form khoản chung có công tắc "Trừ vào ví của mình: [Techcombank ▾]" (mặc định bật khi `payer` = mình và sổ riêng có ví) → thêm doc `expense` cùng `linkId` ở sổ riêng, cùng số tiền, cùng danh mục.
  - Sửa/xoá phía mình → app hỏi "Sửa luôn bên sổ của mình?" và ghi cả hai trong 1 batch. Người ấy sửa phía sổ chung → sổ riêng của mình **không** tự đổi (người ấy không ghi được vào sổ riêng của mình); khoản riêng hiện dấu "Khoản chung đã đổi thành 520k · Cập nhật?" để mình chạm đồng bộ.
  *Lý do:* tiền trong sổ riêng phải khớp tài khoản thật; người ta trả lẩu bằng thẻ của mình thì thẻ của mình phải bị trừ. Không cho người ấy chạm sổ riêng (D2), nên chỉ có thể đồng bộ một chiều có xác nhận.

- **D12 — Sổ chung: ai trả, cách chia** *(PO tự chốt)*: **Ai trả** = mình · người ấy · ví chung. **Cách chia** (ẩn khi trả từ ví chung): **Chia đôi** (`equal`) · **Mình mời / người ấy mời** (`treat`) · **Trả hộ** (`for_partner`, người kia chịu hết) · **Tuỳ** (`custom`, nhập phần người trả chịu, hoặc kéo tỉ lệ 10% một nấc). Lần đầu mặc định Chia đôi, sau đó nhớ lựa chọn gần nhất trên máy. Câu chữ tránh "nợ": "Anh đang ứng nhiều hơn 340k". *Lý do:* có cặp chia sòng phẳng, có cặp "anh mời" là chính; nhớ lựa chọn thì mỗi cặp tự dừng ở thói quen của mình mà không cần màn cài đặt.

- **D13 — Sửa/xoá:** sổ riêng: chủ. Sổ chung: **cả hai** sửa/xoá mọi khoản; mỗi lần sửa ghi `updatedBy`, `updatedAt`, `editCount + 1`, dòng khoản hiện "Em sửa · 21:02". Ngoại lệ: khoản chung có `linkId` chỉ người tạo sửa được số tiền và ví (người kia sửa được danh mục, ghi chú, ngày) — tránh lệch sổ riêng âm thầm. Xoá là xoá cứng, snackbar "Hoàn tác" 5 giây (client đợi 5 giây rồi mới gửi lệnh). Lịch sử từng lần sửa để mốc C. *Lý do:* sổ chung giấy cũng ai cầm bút thì sửa; người ghi nhầm "480k" thành "48k" thường là người kia phát hiện.

- **D14 — Sổ nợ chỉ ở sổ riêng (mốc B).** Cho vay/đi vay với người ngoài: tên người (chỉ chữ, không đọc danh bạ), số tiền, đã trả, hạn, ghi chú. Ghi trả nợ có thể kèm giao dịch vào ví (chọn ví, danh mục hệ thống "Cho vay / Thu nợ / Đi vay / Trả nợ", không vào thu–chi). Chuyện "ai đang ứng" giữa hai người vẫn là cân bằng sổ chung (D7), không nằm ở sổ nợ. *Lý do:* nợ với bạn bè là việc của từng người; hai sổ nợ cho hai người trong cặp sẽ trùng với cân bằng.

- **D15 — Khoản định kỳ (mốc B).** Hai chế độ: **Tự ghi** (đến ngày, app tạo giao dịch — hợp lương, tiền nhà) và **Chỉ nhắc** (hợp tiền điện, số tiền đổi mỗi tháng; chạm thông báo mở form điền sẵn). Sinh giao dịch ở client lúc mở app, cho mọi kỳ đã tới hạn từ `nextDate` tới hôm nay, id `rec_<recId>_<date>` qua transaction `get` rồi `set` ⇒ hai máy cùng sinh không bị trùng. Nhắc local: mỗi khoản 1 lịch cho kỳ gần nhất trong 14 ngày tới, dải id **1212–1219** (tối đa 8 slot; quá 8 khoản thì chỉ arm 8 kỳ gần nhất). Ngày 31 ở tháng ngắn → ngày cuối tháng. *Lý do:* không có cron server cho từng user (đỡ CF chạy định kỳ tốn tiền); app tắt cả tháng thì lần mở sau bù đủ; iOS 64 thông báo → trần 8.

- **D16 — Khoá Face ID / vân tay (mốc B), tắt sẵn, miễn phí.** Bật ở cài đặt Sổ tiền; mỗi lần vào Sổ tiền sau khi app ra nền >1 phút phải mở khoá; thất bại thì dùng mật khẩu máy. Cần package `local_auth` mới; Android phải đổi `MainActivity : FlutterActivity()` sang `FlutterFragmentActivity` — Dev spike trước vì `MainActivity.kt` đang giữ kênh widget, sleep, clipboard. *Lý do:* sổ tiền riêng nằm trong app mà người ấy hay cầm máy của nhau; Money Lover, MISA đều có. Ghi chú: `strategy.md` liệt app-lock là ứng viên premium — khoá **riêng Sổ tiền** vẫn miễn phí; khoá cả app vẫn để dành cho premium.

- **D17 — Push: KHÔNG push từng khoản, chỉ sổ chung, không số tiền trên màn khoá.** Qua 1 CF `notifyMoney` (§5): có người góp vào ví Mục tiêu chung · ví Mục tiêu chung đạt 100% · tổng chi chung tháng vượt 80% rồi 100% ngân sách tổng. Sổ riêng không có push (cảnh báo ngân sách hiện trong app lúc mình ghi). Không `wakeClients`, không trạng thái widget. *Lý do:* 3–5 khoản/ngày mà push thì là spam; ba trường hợp trên mới là tin. Lead chốt: push chỉ hiện %, không hiện số tiền. Widget nằm trên màn hình chính ai cũng thấy, chuyện tiền không lên đó.

- **D18 — Nhắc tối, opt-in, mặc định TẮT, 21:30** (đổi giờ được; lưu Hive như các lời nhắc local khác). Arm one-shot **hôm nay + ngày mai** (dải **1210–1211**) mỗi lần mở app; slot hôm nay huỷ khi mình ghi khoản đầu tiên trong ngày ở bất kỳ sổ nào. Copy xoay 3 câu: "Hôm nay có khoản nào chưa ghi không?" · "Ghi nốt chi tiêu hôm nay, mất chưa tới một phút" · "Tối rồi, xem hôm nay mình tiêu bao nhiêu nhé". *Lý do:* nhắc tiền mỗi tối dễ thành cằn nhằn nên để người dùng tự bật; không dùng repeat `DateTimeComponents.time` (bẫy iOS — CLAUDE.md §6); 2 slot để ngày không mở app vẫn được nhắc.

- **D19 — Báo cáo, tìm kiếm — cách lấy dữ liệu:**
  - Tháng đang xem: listener `moneyTx` theo `date` trong tháng (sổ chung thêm `memberUids ==`). Báo cáo tháng, ngân sách, danh sách đều từ tập này.
  - Số dư ví: 2 aggregate `sum()` mỗi ví, làm lại khi có thay đổi trên listener; cache Hive để mở app hiện ngay. Offline: hiện số đã cache + cộng/trừ các khoản đang chờ gửi.
  - Xu hướng 6/12 tháng: aggregate `sum()` theo tháng × (chi, thu); tháng đã qua cache, chỉ làm lại tháng vừa có khoản sửa.
  - Tìm kiếm: lọc ngày/danh mục/ví ở truy vấn; khoảng tiền + chữ trong ghi chú lọc ở client trên khoảng ngày đã chọn (mặc định 3 tháng, tối đa 12, ≤2.000 dòng) — Firestore không tìm theo chữ. Chữ so không dấu, không phân biệt hoa thường ("bun cha" ra "Bún chả").
  *Lý do:* rẻ (aggregate tính 1 lượt đọc / 1.000 doc), không cần CF giữ số tổng, không cần dịch vụ tìm kiếm ngoài.

- **D20 — Nối decision-wheel:** sheet kết quả kind `eat` / `go` thêm nút phụ **"Ghi chi"** → form chi, danh mục Ăn ngoài (eat) / Đi chơi (go), ghi chú = `result`, ngày hôm nay, `source: 'decision'`; cặp `active` mặc định vào sổ chung, cặp đang chờ vào sổ riêng.

- **D21 — Offline:** cache + hàng đợi ghi sẵn của Firestore. Khoản ghi lúc mất mạng hiện ngay kèm dấu "đang chờ mạng" (`hasPendingWrites`). Riêng sinh khoản định kỳ (transaction) cần mạng → để lần mở app có mạng. *Lý do:* ghi chi tiêu hay xảy ra ở quán sóng yếu; hai máy ghi cùng lúc tạo hai doc khác nhau, không đè nhau.

- **D22 — Xuất CSV (mốc B):** mỗi sổ một file, chọn khoảng ngày, cột: ngày · loại · số tiền · ví · danh mục · danh mục con · ghi chú · (sổ chung) người trả · cách chia · phần người trả chịu. UTF-8 có BOM để Excel đọc đúng tiếng Việt. Chia sẻ qua `share_plus` (đã có). Không lưu file lên server.

- **D23 — Ảnh hoá đơn (mốc C):** tối đa 1 ảnh/khoản, nén ≤1600px, Storage `money_receipts/{uid}/…` (riêng) và `money_receipts_couple/{coupleId}/…` (chung), rules như ảnh couple. Để mốc C vì thêm Storage rules + chi phí lưu trữ mà không làm người ta ghi nhiều hơn.

- **D24 — Đa tiền tệ: Later.** Field `currency` đã chừa ở ví; rules mốc A ép `== 'VND'`. *Lý do:* ít cặp cần (yêu xa nước ngoài), mà làm đúng cần tỉ giá + quy đổi ở báo cáo.

- **D25 — Điểm vào UI (đề xuất; Designer chốt chung cả đợt vì Home đã dày):**
  - **Màn `MoneyScreen`** (màn con, chip theo tên chốt ở §11): đầu màn chuyển sổ **Của mình · Chung** (Chung ẩn khi đang chờ) · thẻ tháng (chi, thu, còn lại, ngân sách) · ví (cuộn ngang, có tổng tài sản) · dải cân bằng (sổ chung, ẩn khi lệch 0) · danh sách theo ngày · nút thêm nổi. Các tab con hoặc màn con: Báo cáo · Ngân sách · Ví & mục tiêu · Tìm kiếm · Cài đặt sổ (danh mục, nhắc, khoá, xuất).
  - **Lối vào chính ở Home:** một ô gọn, không lộ số dư. Đề xuất nội dung: "Hôm nay: đã chi 600k" hoặc "+ Ghi khoản chi". Chạm ô → `MoneyScreen`; chạm "+" → form thêm luôn.
  - **Lối phụ:** tile Profile · nút "Ghi chi" ở decision-wheel · tap push/inbox `money_*` · thông báo nhắc.
  - Form thêm giao dịch là sheet cao hoặc màn: tab Chi · Thu · Chuyển; ô số to ở trên; danh mục lưới; ví; ngày; ghi chú; (sổ chung) ai trả + cách chia + "trừ vào ví của mình".

- **D26 — Trạng thái phải thiết kế:** lần đầu mở (onboarding ví 1 màn) · sổ/tháng rỗng · đang chờ người ấy (D5) · offline / đang chờ mạng · ghi bị từ chối · ngân sách chưa đặt / 80% / 100% / vượt · ví âm (thẻ tín dụng là bình thường; ví khác hiện cảnh báo nhẹ) · mục tiêu chưa có hạn / đạt 100% · khoản riêng nối với khoản chung đã bị người ấy sửa (D11) · khoá Sổ tiền (mốc B) · khoản định kỳ chờ xác nhận (mốc B).

- **D27 — Analytics** (qua `AnalyticsService`; **không** gửi số tiền, số dư, tên ví, ghi chú, tên danh mục tự thêm, tên người trong sổ nợ):
  - `money_tx_add{book: own|shared, type, category: <id mặc định cấp 1>|custom|none, wallet_type, payer: me|partner|wallet|na, split, via: manual|chip|decision|recurring, has_note, linked: bool}`
  - `money_tx_edit{book}` · `money_tx_delete{book, undone}` · `money_wallet_add{type, book}` · `money_goal_add{book, has_deadline}` · `money_goal_reached{book}` · `money_budget_set{book, scope: total|category}` · `money_settle{}` · `money_report_open{book, view: month|trend|wallet|person}` · `money_search{filter_count}` · `money_screen_open{from: home|profile|decision|push|inbox|reminder}` · `money_reminder_toggle{on}` · mốc B: `money_recurring_add{mode, freq}` · `money_debt_add{direction}` · `money_export{book}` · `money_lock_toggle{on}`.

- **D28 — Mixed version:** app 1.10.x/1.11.0 không đọc collection mới. Push/inbox `money_goal` · `money_goal_reached` · `money_budget` tới bản cũ: tap rơi về Home, inbox type lạ — Dev kiểm cách render type lạ như D13 decision-wheel. Rules chỉ thêm match mới.

- **D29 — Không AI, không liên kết ngân hàng, không đọc SMS/thông báo ngân hàng.** *Lý do:* luật đợt (không AI trả phí); đọc SMS/thông báo cần quyền nhạy cảm Play rất khó duyệt; liên kết ngân hàng cần đối tác.

- **D30 — Khai báo store: user đã duyệt 2026-10-20.** Thêm "Financial info → Other financial info" (Apple App Privacy) / "Thông tin tài chính → Thông tin tài chính khác" (Play An toàn dữ liệu), mục đích "Tính năng của ứng dụng", không chia sẻ bên thứ ba; sửa privacy policy `docs/` (dữ liệu tiền lưu ở Firebase, sổ riêng chỉ chủ đọc, sổ chung hai người đọc, xoá khi xoá tài khoản). Làm trước khi gửi duyệt mốc A.

## 5. Rules (chỉ ADDITIVE) + Cloud Functions

**Rules — match mới, không đụng match cũ:**
- **Sổ riêng** `users/{uid}/{coll}/{id}` với `coll in ['moneyWallets','moneyTx','moneyBudgets','moneyMeta','moneyRecurring','moneyDebts']`: đọc/ghi khi `request.auth.uid == uid` (viết thành 6 match riêng cho rõ). Kiểm giá trị như sổ chung, bỏ các khoá **[chung]**. Ví/khoản riêng KHÔNG có `memberUids`, `payer`, `splitMode`, `payerShare` (`hasOnly` chặn).
- **Sổ chung** `couples/{coupleId}/{coll}/{id}` với `coll in ['moneyWallets','moneyTx','moneyBudgets','moneyMeta','moneyRecurring']`:
  - **read:** `isCoupleMember(coupleId) && request.auth.uid in resource.data.memberUids` (`moneyMeta`, `moneyBudgets`: chỉ cần `isCoupleMember` — chỉ là tên danh mục và hạn mức).
  - **create:** `hasOnly` đúng bộ khoá D6 + `hasAll` khoá bắt buộc; `createdBy == auth.uid`; `createdAt == request.time`; `memberUids == get(/couples/$(coupleId)).data.memberIds && memberUids.size() == 2`.
  - **update:** người gọi là thành viên + có tên trong `memberUids`; bất biến `type, memberUids, createdBy, createdAt, linkId` (`!diff().affectedKeys().hasAny([...])`); `updatedBy == auth.uid`; `updatedAt == request.time`; `editCount == resource.data.get('editCount', 0) + 1`; doc có `linkId` mà người gọi ≠ `createdBy` thì không được đổi `amount, outWalletId, inWalletId, payer, payerShare, splitMode` (D13); client không ghi `alerted` (budget), không ghi `goalReachedAt` (ví chung).
  - **delete:** thành viên + có tên trong `memberUids`; doc có `linkId` chỉ `createdBy` xoá. Ví: không delete, chỉ `archived: true` (giữ lịch sử giao dịch).
- **Ràng buộc giá trị (cả hai sổ):** `amount is int && 1 <= amount <= 10000000000` (10 tỷ — đủ cho lương, tiền đặt cọc nhà; xem §11 nếu cần cao hơn) · `openingBalance is int && -10000000000 <= x <= 100000000000` · `goalTarget` 1..100 tỷ · budget `amount` 1..10 tỷ · `payerShare is int && 0 <= payerShare <= amount` · `date`, `goalDeadline` khớp `^\d{4}-\d{2}-\d{2}$` · `name` 1..30 · `note` ≤200 · id chuỗi ≤40 · emoji ≤8 · `type`/`splitMode`/wallet `type` trong danh sách · `data.get('currency','VND') == 'VND'` · `expense` cần `outWalletId != ''` hoặc (sổ chung) `payer` là người · `income` cần `inWalletId != ''` · `transfer` cần cả hai và khác nhau · `adjust` đúng một trong hai · `settle` chỉ sổ chung, `payerShare == 0`, không ví · `payer == 'wallet'` cần `outWalletId != ''` · `customCategories.size() <= 80` · `hiddenCategoryIds.size() <= 120` · `moneyDebts.paid <= amount`.
- **Index composite:** `moneyTx` (`memberUids` ==, `date` desc) · (`memberUids` ==, `outWalletId`) · (`memberUids` ==, `inWalletId`) · (`memberUids` ==, `type`, `date`) — sổ riêng dùng index đơn mặc định cho `date`; (`outWalletId`/`inWalletId`) đơn cũng đủ.

**`notifyMoney`** — `onDocumentWritten` `couples/{coupleId}/moneyTx/{id}`, us-central1, Node 22. Gửi qua `writeInboxNotifications` + `sendToRecipientDevices` (vi/en theo `languageCode`), **không `wakeClients`**, **không số tiền**.

| Trường hợp | Gửi cho | vi | en | Inbox |
|---|---|---|---|---|
| Create `contribution` vào ví `goal` | người không phải `payer` | `{emoji} {walletName}` · `{name} vừa góp vào quỹ, giờ được {percent}%` | `{emoji} {walletName}` · `{name} just chipped in, the fund is at {percent}%` | `money_goal` `{walletId, actorName}` |
| Ví `goal` vừa chạm 100% (CF ghi `goalReachedAt` lần đầu) | cả hai | `{emoji} {walletName} đủ rồi!` · `Chúng mình góp đủ mục tiêu rồi. Lên lịch đi thôi.` | `{emoji} {walletName} is full!` · `We hit the goal together. Time to plan it.` | `money_goal_reached` `{walletId}` |
| Tổng chi chung tháng vượt 80% / 100% ngân sách tổng (aggregate `sum('amount')` trên `type == 'expense'`, `memberUids == couple.memberIds`, `date` trong tháng; mỗi mốc 1 lần/tháng qua `alerted`) | người không phải `updatedBy ?? createdBy` | 80%: `Tháng này chúng mình đã tiêu 80% ngân sách` · `Mở sổ chung xem còn lại bao nhiêu nhé.` — 100%: `Tháng này chúng mình tiêu hết ngân sách rồi` · `Chậm lại chút nhé, còn {daysLeft} ngày nữa mới sang tháng.` | 80%: `We've used 80% of this month's budget` · `Open our shared book to see what's left.` — 100%: `We've used up this month's budget` · `Let's slow down a little. {daysLeft} days to go this month.` | `money_budget` `{month, level}` |

- Tần suất ước lượng mỗi cặp: góp quỹ 2–8 lần/tháng · đạt mục tiêu ≤1 lần/quỹ · ngân sách ≤2 lần/tháng ⇒ < 0,5 push/ngày. Không cooldown riêng. Sửa/xoá không push (trừ khi sửa làm vượt mốc ngân sách). Ngân sách theo danh mục chỉ cảnh báo trong app.
- Chi phí: khoản `expense` chung khi có ngân sách tổng → 1 đọc budget + 1 aggregate. Không có ngân sách → 1 đọc rồi dừng.
- Tap push/inbox → `MoneyScreen` sổ chung (`money_goal*` kèm `focusWalletId`); thêm nhánh ở cả `push_notification_service._handleNotificationTap` lẫn `AppNotification.targetHomeTab` (2 chỗ phải khớp — CLAUDE.md §6).
- **Sửa 2 hàm dọn có sẵn:** `deleteAccount` (`recursiveDelete` 6 collection sổ riêng của uid) · `deleteCoupleCompletely` (`recursiveDelete` 5 collection sổ chung). `notifyPartnerLeft` không đổi.
- PROD deploy đích danh khi phát hành mốc A: `firestore:rules,firestore:indexes,functions:notifyMoney,functions:deleteAccount,functions:leaveCoupleCleanup` — **chờ lệnh user**; rules PROD lên trước khi bản có feature live.

## 6. Acceptance criteria — mốc A (xong khi…)

Máy DEV: A = `test3`, B = `test4` (cặp đã ghép), C = `test1` (đang chờ).

**Sổ của mình**
- [ ] Lần đầu mở: có ví "Tiền mặt" + onboarding 1 màn; thêm MoMo số dư 1.500.000 → tổng tài sản 1.500.000 ₫.
- [ ] Chi 120k từ MoMo (gõ "120k", chọn Ăn ngoài, Lưu, ≤3 chạm sau khi nhập số) → MoMo 1.380.000. Thu lương 15tr vào Techcombank → Techcombank +15tr, tháng "Thu 15.000.000". Chuyển 500k Techcombank → Tiền mặt → hai ví đổi, thu–chi tháng không đổi. Điều chỉnh MoMo về 1.000.000 → tạo `adjust` 380k ra, chi tháng không đổi.
- [ ] Thẻ tín dụng số dư đầu −2tr hiện `−2.000.000 ₫`; ví "không tính vào tổng" không vào tổng tài sản.
- [ ] B không đọc được bất kỳ doc nào trong `users/A/money*` (rules test).
- [ ] **Parser** "50k", "1tr", "1tr2", "1.5tr", "2 triệu", "1 củ", "1 tỏi" ra đúng; "abc", "0", "" khoá Lưu; > 10 tỷ báo lỗi tại ô. Test Dart PASS.
- [ ] **Hiển thị** vi `1.250.000 ₫`, en `₫1,250,000`; gọn `1,2tr` / `1.2M`.

**Danh mục, ngân sách, báo cáo, tìm kiếm**
- [ ] Đủ 12 nhóm chi + con, 6 nhóm thu, vi + en. Thêm "Cầu lông" dưới Sức khoẻ; đổi tên "Cà phê, trà sữa" thành "Trà sữa"; ẩn "Học tập" → không còn trong lưới chọn, khoản cũ vẫn hiện đúng tên.
- [ ] Ngân sách tổng 5tr + Ăn uống 2tr: ghi tới 1,6tr Ăn uống → cảnh báo 80% Ăn uống trong app; vượt 2tr → 100%; sang tháng mới reset.
- [ ] Báo cáo tháng (seed 120 khoản 12 tháng): thu, chi, còn lại, cơ cấu theo danh mục cấp 1 (chạm mở cấp 2), theo ví, xu hướng 6 và 12 tháng — khớp `MoneyMath` test. Tháng rỗng có empty-state.
- [ ] Tìm "bun cha" ra khoản ghi chú "Bún chả"; lọc Ví = MoMo + 100k–500k + 3 tháng trả đúng tập; 0 kết quả có empty-state.

**Sổ chung**
- [ ] C (đang chờ) không thấy tab Chung, thấy thẻ D5. A, B thấy tab Chung với "Ví chung" tự tạo.
- [ ] A trả 480k chia đôi, bật "Trừ vào ví của mình: Techcombank" → sổ chung có khoản, Techcombank của A −480k, cân bằng hai máy "Anh đang ứng nhiều hơn 240k" ≤3 giây, B không nhận push.
- [ ] B trả 70k "Trả hộ" → lệch 170k; A "Mình mời" 200k → lệch không đổi; Tuỳ 300k A chịu 100k → B lệch thêm 200k; 75.001 chia đôi → người trả chịu 37.501.
- [ ] B "Đánh dấu đã thanh toán" → `settle` 170k, lệch về 0 hai máy, không vào chi tháng; trả một phần 100k → còn 70k.
- [ ] B sửa ghi chú khoản của A → A thấy "Em sửa · hh:mm"; B sửa số tiền khoản có `linkId` của A → bị chặn (UI khoá ô + rules test). A sửa số tiền → app hỏi sửa luôn bên sổ riêng.
- [ ] Xoá + "Hoàn tác" trong 5 giây → không có lệnh xoá nào lên Firestore.
- [ ] Ví Mục tiêu chung "Quỹ Đà Lạt" 🏔️ 5tr hạn 2027-01-31: A góp 2tr từ MoMo → MoMo −2tr, quỹ 40%, B nhận push "Anh vừa góp vào quỹ, giờ được 40%" (không có số tiền) + inbox; B góp 3tr → cả hai nhận push "đủ rồi" đúng 1 lần; chi 1,2tr từ quỹ (`payer: wallet`) → không đổi cân bằng, vào chi tháng.
- [ ] Ngân sách tổng sổ chung 5tr: vượt 4tr → người không ghi khoản đó nhận push 80% (chỉ %), ghi tiếp không lặp; vượt 5tr → push 100% 1 lần; client ghi `alerted` → rules từ chối.

**Rời / xoá / offline / tích hợp**
- [ ] B rời couple → A vẫn đọc doc chung cũ (rules), UI sổ chung trống; sổ riêng A, B nguyên vẹn. Tài khoản D ghép vào couple của A đọc doc chung cũ → `permission-denied`.
- [ ] Xoá tài khoản B → toàn bộ `users/B/money*` biến mất; khoản chung còn cho A. Người cuối xoá → mọi `couples/{id}/money*` biến mất.
- [ ] Tắt mạng ghi 2 khoản → hiện ngay có dấu chờ mạng, số dư ví cập nhật tạm; bật mạng → lên máy kia.
- [ ] decision-wheel chốt "Bún chả" → "Ghi chi" → form Ăn ngoài + ghi chú "Bún chả" + hôm nay, sổ chung (A) / sổ riêng (C); `via = decision`.
- [ ] Nhắc tối mặc định tắt; bật → id 1210 + 1211; ghi 1 khoản → 1210 huỷ; tắt → hết.

**Kỹ thuật**
- [ ] `scripts/test-firebase-rules.sh` PASS, ≥45 case mới: người ngoài / người ấy đọc sổ riêng · người ghép mới đọc sổ chung cũ · amount 0 / âm / 10.000.000.001 / số thực / chuỗi · openingBalance ngoài khoảng · payerShare âm / > amount · note 201 · name 31 · date sai · `createdAt != request.time` · giả `createdBy` / `updatedBy` · `memberUids` sai / 1 người / 3 người · khoá sổ chung lọt vào sổ riêng · `transfer` cùng ví · `adjust` cả hai ví · `settle` trong sổ riêng · đổi `type`/`memberUids`/`createdBy`/`createdAt`/`linkId` · `editCount` nhảy 2 · sửa tiền khoản có `linkId` của người khác · xoá ví · client ghi `alerted`/`goalReachedAt` · currency 'USD' · doc thiếu khoá optional vẫn tạo được.
- [ ] CF emulator: 3 trường hợp push, không push khoản thường, mỗi mốc ngân sách 1 lần/tháng, không gửi cho người ghi, dọn khi xoá tài khoản/couple; deploy DEV có vết; PROD chưa deploy.
- [ ] Analytics: DebugView đủ event D27; payload không có số tiền, tên ví, ghi chú.
- [ ] `flutter analyze` 0; test Dart `parseVndInput`, formatter, `MoneyMath` (thu–chi, số dư 4 loại giao dịch + contribution, cân bằng 4 cách chia + settle, mục tiêu, ngân sách 80/100, lọc `memberUids`), tìm không dấu.
- [ ] Không regression Home, decision-wheel, notification center, dọn `sleep`/`decisions` khi rời/xoá.

Mốc B, C: PO viết acceptance riêng khi mở mốc (xem `roadmap.md`).

## 7. Giao việc 3 vai — mốc A

- 🎨 **Designer:** lối vào Home (chốt chung với 4 feature cùng đợt) · `MoneyScreen` 2 sổ · form giao dịch (Chi/Thu/Chuyển, ô số + chip + gõ tắt, lưới danh mục 2 cấp, ví, phần cặp đôi) · onboarding ví · ví & mục tiêu · ngân sách · báo cáo (tháng, cơ cấu, xu hướng, theo ví, theo người) · tìm kiếm + lọc · cài đặt sổ · cân bằng + thanh toán · mọi trạng thái D26. Copy vi/en "chúng mình". Tra UI UX Pro Max (luật 8), đối chiếu `design-system.md`. → *expect:* `design.md` + mock bấm thử.
- 💻 **Dev:** (1) `parseVndInput`, formatter, `MoneyMath`, danh mục mặc định + test; (2) `MoneyService(bookRef)` + `MoneyProvider` cho 2 sổ (sổ riêng wire lúc đăng nhập, sổ chung khi couple active — `session_resolver` named-param, clear khi sign-out/no-couple); (3) UI; (4) nút decision-wheel; (5) nhắc 1210–1211; (6) rules + index + test + CF `notifyMoney` + sửa `deleteAccount`/`deleteCoupleCompletely` + tap push/inbox 2 chỗ; (7) analytics; (8) ARB + `gen-l10n`; (9) deploy DEV. Đụng rules/functions → `effort: high`. → *expect:* nhánh feature, analyze 0, rules test PASS, smoke 2 máy DEV.
- 🧪 **Tester:** §6 trên `test3`/`test4`/`test1`; soi rules (sổ riêng, người ghép mới, `linkId`, số biên); hai máy cùng sửa một khoản; hai máy cùng sinh khoản định kỳ (mốc B); đổi múi giờ; bản 1.11.0 nhận push mới. → *expect:* bảng PASS/FAIL `test.md`.

## 8. Nợ kỹ thuật / rủi ro (Tester soi)

- 🔴 **Khối lượng:** mốc A riêng đã là feature lớn nhất từ trước tới nay của app (ước ~12–15 màn/sheet). Rủi ro trễ cả đợt → Lead nên cho mốc A đi bản riêng, không gói chung với 4 feature nhỏ (§10).
- 🟡 **Hai người sửa cùng khoản chung:** rules `editCount == cũ + 1` từ chối bản thứ hai; client bắt lỗi, báo "Người ấy vừa sửa khoản này", hiện bản mới.
- 🟡 **Sổ riêng lệch sổ chung** khi người ấy sửa khoản có `linkId` ở phần được phép (ngày/danh mục) — không ảnh hưởng tiền; tiền thì rules khoá (D13).
- 🟡 **Số dư cần mạng để tính lại** (aggregate không chạy offline) → hiện số cache + chênh tạm; mất mạng lâu thì số dư có thể lệch tới khi có mạng.
- 🟡 **Cân bằng tính từ toàn bộ khoản chung** → cặp ghi lâu năm tải nặng. Mốc A chấp nhận; sau này đổi sang aggregate `sum` theo `payer` hoặc CF giữ tổng.
- 🟡 **Ngày theo máy người ghi** (lệch múi giờ cặp yêu xa) — như câu hỏi hằng ngày.
- 🟡 **iOS 64 thông báo chờ:** +2 slot (mốc A) +≤8 slot (mốc B). Lead cộng band cả đợt.
- 🟡 **`FlutterFragmentActivity` (mốc B)** có thể ảnh hưởng kênh native trong `MainActivity.kt` → spike trước.
- 🟢 Riêng tư: push không có số tiền, ghi chú; widget không hiện gì về tiền; sổ riêng chỉ chủ đọc ở rules.

## 9. Metric đo thành công (30 ngày sau mốc A)

- **Cặp đang chờ:** % trong nhóm đang chờ có ≥5 khoản trong 7 ngày đầu. Mục tiêu ≥20% (≈10/52). Phụ: tỉ lệ ghép đôi 30 ngày, nhóm dùng sổ so với nhóm không.
- **Tất cả người dùng:** số ngày/tuần có ghi khoản (bất kỳ sổ nào), trung vị ở người đang dùng ≥4 ngày/tuần.
- **Cặp đã ghép:** % có ≥1 khoản chung mỗi tuần, mục tiêu ≥35% (≈10/28).
- **Ngày mở app nhờ sổ:** % ngày-người có `money_tx_add` mà không có hoạt động khác (câu hỏi, tâm trạng, chat, ảnh). Tăng = sổ đang kéo thêm ngày mở app, đúng mục tiêu đợt.
- **Độ sâu:** % người dùng có ≥2 ví; % có ngân sách; số ví Mục tiêu chung có góp từ cả hai người.

## 10. Phụ thuộc / đụng chạm với feature cùng đợt

- **decision-wheel** (1.11.0): thêm nút ở sheet kết quả (D20) → sửa file feature đó, báo PO decision-wheel cập nhật changelog.
- **poke, caro-game, weather, arrival:** cùng sửa `functions/index.js`, `firestore.rules`, `firestore.indexes.json`, ARB, `session_resolver`, `AnalyticsEvents`, `NotificationTapRouter` + `AppNotification.targetHomeTab` → Lead xếp thứ tự merge. Dải id local xin **1210–1219** (1210–1211 nhắc tối, 1212–1219 định kỳ) — Lead đối chiếu cả đợt. Lối vào Home: Designer chốt một lần cho cả 5.
- **Đề xuất cho Lead:** 4 feature kia nhỏ hơn nhiều; nên phát hành chúng trước, sổ tiền mốc A đi bản kế tiếp (hoặc cùng bản nếu kịp), để feature lớn không giữ chân cả đợt.
- **widget-today:** không thêm loại trạng thái (D17).

## 11. Câu hỏi cho user

- ✅ [2026-10-20] Tên hiển thị: user chọn **"Sổ tiền"**, hai tab "Của mình" · "Chung" (thư mục vẫn là `expenses`). Cách trình bày tên trên màn do Designer chốt theo nhận diện v2 (tasteskill cấm chip nhỏ đặt trên tiêu đề).
- ✅ [2026-10-20] Trần 10 tỷ/giao dịch, 100 tỷ/ví: Lead chốt giữ nguyên (số lớn hơn thường là gõ thừa số 0). User lật được.
- ✅ [2026-10-20] Rời couple: user chọn người ở lại giữ sổ chung; Lead chốt sổ riêng gắn với user, không mất khi rời.
- ✅ [2026-10-20] Push ngân sách chỉ hiện %, không hiện số tiền (Lead chốt, đã báo user). Privacy policy + khai "Thông tin tài chính khác": user đồng ý.

## 12. Changelog feature
- [2026-10-20] [PO] Tạo feature "Quỹ chung" (sổ chi chung, D1–D21). User + Lead chốt cùng ngày: bỏ số tiền khỏi push ngân sách; người ở lại giữ sổ chung; duyệt khai báo store + privacy policy.
- [2026-10-20] [PO] User: "Feature Quỹ chung làm nó giống money management" → viết lại toàn bộ thành app quản lý tiền: sổ riêng ở `users/{uid}` (không mất khi rời couple, chỉ xoá khi xoá tài khoản — Lead chốt) + sổ chung ở `couples/{coupleId}` (quyền theo `memberUids` chụp lúc tạo). Research thêm Wallet by BudgetBakers, Spendee. Chốt D1–D30: ví 5 loại, giao dịch 6 loại với `outWalletId`/`inWalletId`, danh mục 2 cấp 12 nhóm chi + 6 nhóm thu, ngân sách tổng + theo danh mục, báo cáo + xu hướng bằng aggregate `sum()`, tìm không dấu, mục tiêu = ví loại Mục tiêu, 2 sổ nối bằng `linkId`, CF `notifyMoney` chỉ sổ chung, chỉ %, không `wakeClients`. Chia 3 mốc: A (bản phát hành đầu) · B (định kỳ, sổ nợ, CSV, Face ID) · C (ảnh hoá đơn, lịch sử sửa, sổ cũ). 2 câu hỏi cho user ở §11 (tên, trần số tiền).
- [2026-10-20] [Lead] User chọn tên "Sổ tiền"; Lead chốt trần 10 tỷ. Spec mở rộng thành app quản lý tiền (sổ riêng + sổ chung, mốc A/B/C) theo yêu cầu "làm nó giống money management".
- [2026-10-20] [Lead] Chốt câu hỏi Designer: thêm công tắc "Ghi tiền về ví của mình" (mặc định bật) trong sheet Thanh toán để số dư ví riêng không lệch khi người ấy trả lại; lối vào Home dùng `IconBadge` như `SleepCard` (thống nhất cả 5 lối vào); chấp nhận số chỉ căn phải vì Quicksand không có số đều bề rộng; nhận token tiền `moneyPositive #247B50` / `moneyNegative #C4242A` / `moneyWarn #B65A00`.
- [2026-10-20] [Lead] Sau vòng soát dễ dùng: nhận luật danh mục chọn sẵn mới (dùng nhiều nhất 14 ngày qua, hoà thì gần nhất; thay D9 "dùng gần nhất") và ví chọn sẵn = ví dùng lần trước với chính danh mục đó; nhận "Ghi lại khoản quen" (2 chạm cho khoản lặp lại); xoá khoản thường chỉ hoàn tác 5 giây, xoá khoản có ở cả hai sổ mới hỏi trước.
