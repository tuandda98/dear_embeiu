# 🎨 Design — Sổ tiền (expenses), mốc A

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`project/design-system.md`, code `lib/theme/` + `lib/widgets/`). CHỈ thiết kế, không code.

- **Trạng thái design:** xong mốc A, chờ PO duyệt (3 câu hỏi ở cuối file)
- **Người/role:** Designer
- **Mockup bấm thử:** `docs/design/expenses/index.html` (mở ở bề rộng 390). Dữ liệu mẫu + phép kiểm: `docs/design/expenses/data.js`. Ảnh chụp vòng cuối: `docs/design/expenses/shots/`.
- **Cách làm:** tasteskill (đủ run màn app §2.1–2.8) + UI UX Pro Max. User chốt 2026-10-20: "follow theo system design hiện tại của app", nên mọi màn trông như app đang có: nền dawnBlush, `SubScreenHeader` + `EyebrowChip`, `ContentCard`, nút pill navy h52, Iconsax Linear, Quicksand.

## 1. Tasteskill: style, face, dữ liệu

- **Style:** dùng chung sheet đợt `docs/design/daily-open-2/sheet.raw.md` (editorial-greeting, seed 1822703143, `--keep palette,type`). Không draw lại. Map màu thương hiệu vào vai trò của sheet:

| Vai trò (sheet) | Giá trị trong Sổ tiền | Nguồn |
|---|---|---|
| ground | `dawnBlush` #FFC1CC → #E8B4D8 → #C8A8E9 | `AppColors.dawnBlush` (giữ, xem §9) |
| surface / panel | trắng #FFFFFF r24, bóng `black .06 blur16 y10` | `ContentCard` |
| raised / nhóm trong card | `surfaceLight` #F5F0F5 r16–20 | `AppColors.surfaceLight` |
| rule | 1px #F5F0F5 | như vạch ngăn Settings |
| text / muted | #1A1A2E / #6B6B7B | `textPrimary` / `textSecondary` |
| primary control | navy #1A1A2E, pill h52 | nút chính của app |
| accent (<2%) | `accentLove` #FF4D6D: nút ghi khoản (FAB) + cột tháng hiện tại trên biểu đồ | `AppColors.accentLove` |
| person hues | màu mỗi người chọn ở `personPalette` (mẫu: Tuấn blue #1C7ED6, Thảo teal #0E9384); "Chung" = navy trung tính | `lib/theme/person_palette.dart` |
| status (đề xuất token mới) | thu `moneyPositive` #247B50 · vượt `moneyNegative` #C4242A, pill #FFEDEA/#831C1E · sắp chạm `moneyWarn` #B65A00, pill #FFF4E0/#8A4B00 | §5 |

- **Face đã chọn (ghi trước khi dựng):** "cặp đôi là ba làn": **Thảo · Ví chung · Mình**. Người ấy bên trái, chung ở giữa, mình bên phải; màu riêng của mỗi người chỉ là tint nhạt trên avatar chữ cái và trên đoạn thanh của làn đó, không vào chú thích biểu đồ. Hiện ở màn đầu tab Chung (thẻ "Ai trả tháng này"), ở báo cáo "Theo người", ở quỹ "Mỗi người góp".
- **Signature element:** thẻ "Ai trả tháng này": 3 làn số tiền + thanh 100% chia 3 đoạn (2px khe) + dòng cân bằng "Mình đang ứng nhiều hơn 359.000 ₫" ngay cạnh nút "Thanh toán". App tài chính VN không có cái này; Splitwise có cân bằng nhưng không có làn "ví chung".
- **Kiểm kê dữ liệu (§2.1):**
  - Đối tượng: ví (5 loại, số dư VND nguyên), giao dịch (6 loại, `amount` dương + `outWalletId`/`inWalletId`), danh mục 2 cấp (12 nhóm chi, 6 nhóm thu, emoji là dữ liệu), ngân sách tháng (tổng + theo nhóm), ví mục tiêu (đích + hạn), cân bằng sổ chung, thanh toán.
  - Độ lớn thật: một người trẻ ghi 3–5 khoản/ngày, 60–120 khoản/tháng; khoản thường 25.000–500.000 ₫, tiền nhà 3–6 triệu, lương 10–25 triệu; 2–6 ví; sổ chung 15–40 khoản/tháng; cân bằng thường vài trăm nghìn.
  - Người dùng: mở trên điện thoại, mỗi lần 10–30 giây (ghi 1 khoản), vài lần/tuần mở lâu hơn (xem tháng, thanh toán).
  - Việc hay làm nhất: **ghi 1 khoản** (≤3 chạm sau khi gõ số). Sau đó: xem tháng còn bao nhiêu; xem ai đang ứng; thanh toán.
  - Đồ riêng của sản phẩm: hai người có tên, màu riêng; "Ví chung"; "Quỹ Đà Lạt"; ngôn ngữ "50k", "1 củ", "mình mời".
- **Dữ liệu mẫu** (`data.js`, cặp DEV Tuấn ♥ Thảo, ngày yêu 14/05/2023, hôm nay Thứ Ba 20/10/2026): 24 khoản riêng tháng 10, 17 khoản chung, 5 ví riêng, 2 ví chung, 11 tháng aggregate. Mọi tổng tính từ dòng; `console.assert` kiểm: parser 13 ca đúng + 5 ca phải khoá Lưu + trần 10 tỷ, formatter vi/en, còn lại = thu − chi, ba làn cộng lại = chi chung, góp quỹ = số dư quỹ, **cân bằng = 359.000 ₫** (khớp kịch bản AC: 240k − 70k …), Ví chung = góp − chi từ ví, cơ cấu = chi tháng, `linkId` cùng số tiền, chia đôi 75.001 → 37.501, tìm "bun cha" ra 3 khoản. Các số chính trên màn:

| Số | Giá trị | Ở đâu |
|---|---|---|
| Mình đã chi tháng 10 | 9.552.000 ₫ / ngân sách 11.000.000 ₫ (87%), còn 1.448.000 ₫ | tổng quan Của mình |
| Thu / còn lại | +20.500.000 ₫ / 10.948.000 ₫ | tổng quan, báo cáo |
| Tổng tài sản | 18.805.000 ₫ (Thẻ VIB −2.458.000 ₫ tính vào) | Ví |
| Chung đã chi | 3.574.000 ₫ / 5.000.000 ₫ (71%); Ăn uống chung 1.942.000 / 2.000.000 ₫ (97%) | tổng quan Chung, ngân sách |
| Ba làn | Thảo 402.000 · Ví chung 1.052.000 · Mình 2.120.000 ₫ | Ai trả tháng này |
| Cân bằng | Mình đang ứng nhiều hơn 359.000 ₫ | Ai trả, Thanh toán |
| Quỹ Đà Lạt | 2.000.000 / 5.000.000 ₫ (40%), cần ~1.000.000 ₫/tháng tới 31/01/2027 | quỹ |

## 2. Màn + luồng (mốc A)

```
Home ─ hàng "Sổ chung tháng 10" ──chạm hàng──▶ MoneyScreen (tab Chung; cặp chờ: Của mình)
   └─ nút + ─────────────────────────────────▶ AddTransactionSheet (sổ chung; cặp chờ: sổ riêng)
Profile tile · decision-wheel "Ghi chi" · push/inbox money_* · nhắc tối ─▶ MoneyScreen / sheet
Lần đầu mở Sổ tiền ─▶ FirstRun (ví 1 màn) ─▶ MoneyScreen

MoneyScreen ─┬─ ⌕ ─▶ Tìm khoản
             ├─ ⋯ (sheet menu) ─▶ Ví · Danh mục · Ngân sách · Báo cáo · Nhắc tối
             ├─ "Báo cáo ›" (thẻ tháng) ─▶ Báo cáo
             ├─ "Ngân sách ›" (Tiêu vào đâu) ─▶ Ngân sách
             ├─ hàng ví / "Quản lý ví" ─▶ Ví ─▶ Chi tiết ví ─▶ sheet Chuyển / Điều chỉnh
             ├─ hàng quỹ ─▶ Quỹ (mục tiêu) ─▶ sheet Góp (= Ghi khoản, loại Góp)
             ├─ "Thanh toán" (thẻ ba làn) ─▶ sheet Thanh toán
             ├─ hàng khoản ─▶ sheet Ghi khoản ở chế độ sửa (có Xoá)
             └─ FAB + ─▶ AddTransactionSheet
```

| Màn | Câu hỏi một dòng | One finding (dữ liệu mẫu) | Việc hay làm nhất | Mockup |
|---|---|---|---|---|
| Lối vào Home | Tháng này sổ chung tiêu bao nhiêu rồi? | "Đã chi 3.574.000 ₫ · 71% ngân sách" | chạm + ghi khoản | `home-entry.html` |
| Sổ tiền · Của mình | Tháng này mình còn tiêu được bao nhiêu? | "Còn 1.448.000 ₫ cho 11 ngày cuối tháng. Tháng mới qua 20/31 ngày mà đã dùng 87% ngân sách." | ghi khoản (FAB) | `money-own.html` |
| Sổ tiền · Chung | Chung tiêu bao nhiêu, ai đang ứng nhiều hơn? | "Mình đang ứng nhiều hơn 359.000 ₫" + "Ăn uống chung đã dùng 97%, còn 58.000 ₫" | ghi khoản; Thanh toán | `money-shared.html` |
| Ghi khoản (sheet) | Khoản này bao nhiêu, vào đâu, ai trả? | dòng "Bạn gõ “1tr2”" xác nhận cách hiểu; "Mình chịu 240.000 ₫ · Thảo chịu 240.000 ₫" | gõ số → danh mục → Lưu | `add-tx.html`, `add-tx-states.html` |
| Lần đầu | Tiền của mình đang nằm ở đâu? | tổng tài sản cập nhật khi nhập (MoMo 1.500.000 → 1.500.000 ₫) | bật ví + nhập số dư | `first-run.html` |
| Ví | Mình có tất cả bao nhiêu? | "Cộng 4 ví đang dùng, kể cả dư nợ thẻ VIB" | mở 1 ví; thêm ví | `wallets.html` |
| Chi tiết ví | Ví này còn bao nhiêu, tháng này vào/ra gì? | vào +18.500.000 / ra −9.160.000 ₫ | chuyển; điều chỉnh | `wallet.html`, `wallet-sheets.html` |
| Danh mục | Danh mục của sổ này gồm gì? | (quản lý, không có finding) | sửa tên/ẩn/thêm con | `categories.html` |
| Ngân sách | Còn bao nhiêu tới hết tháng, nhóm nào sắp vượt? | Ăn uống chung 97% | đặt ngân sách nhóm chưa có | `budgets.html` |
| Báo cáo | Tháng này tiền đi đâu, so với các tháng trước? | Nhà cửa 59% chi tháng (tiền nhà 4.500.000 ₫) | đổi tháng; 6/12 tháng | `report.html`, `report-shared.html` |
| Tìm khoản | Khoản đó ghi khi nào, bao nhiêu? | 3 khoản · 410.000 ₫ cho "bun cha" | sửa bộ lọc | `search.html` |
| Quỹ Đà Lạt | Quỹ còn thiếu bao nhiêu, mỗi tháng cần góp bao nhiêu? | còn 3.000.000 ₫, ~1.000.000 ₫/tháng | Góp vào quỹ | `goal.html` |
| Thanh toán | Ai trả ai, bao nhiêu, vì sao? | "Vì sao là 359.000 ₫": 9 khoản cộng lại | Đánh dấu đã thanh toán | `settle.html` |
| Trạng thái màn phụ | | | | `more-states.html` |

## 3. Spec từng màn

Chung cho mọi màn con: nền dawnBlush (shell vẽ, màn trong suốt) · `SubScreenHeader(badge, badgeIcon, trailing)` · gutter 16 · thẻ `ContentCard` padding 20, cách nhau 16 · tiêu đề thẻ 16 w700 · link phải thẻ 14 w700 navy + chevron `arrow_right_3` 16 `textSecondary`, vùng chạm 44.

### 3.1 Lối vào Home (`MoneyHomeEntry`, widget mới `lib/widgets/money/money_home_entry.dart`)
- `ContentCard(padding: 16)`, cao 76. Hàng: `IconBadge(IconsaxPlusLinear.wallet_2)` 44 r16 rose tint .12 (Lead chốt 2026-10-20, khớp Home bản C `docs/design/home-daily-open-2/home-c.html`) · cột [tiêu đề 15 w700 · dòng phụ 13 w500 `textSecondary`, số tiền trong dòng phụ 13 w600 navy] · nút tròn 44 navy, icon `add` 22 trắng (Semantics "Ghi khoản").
- Chạm cả hàng (InkWell r24, ripple rose .06) → `MoneyScreen` tab Chung. Chạm nút → sheet ghi khoản, sổ chung. Hai vùng chạm cách nhau ≥8.
- **Chỉ hiện số của sổ chung.** Không bao giờ số dư, không sổ riêng. Cặp đang chờ: dẫn vào sổ riêng và chỉ hiện số khoản đã ghi hôm nay (không số tiền).
- Trạng thái (đủ hình trong `home-entry.html`): bình thường "Đã chi 3.574.000 ₫ · 71% ngân sách" · chưa đặt ngân sách "Đã chi … tháng này" · vượt "Đã chi 5.240.000 ₫ · vượt 240.000 ₫" (chữ "vượt …" `moneyNegative`) · đầu tháng "Đã chi 0 ₫ · chưa có khoản nào" · đang tải (tiêu đề hiện, dòng phụ là thanh xám 170×14) · mất mạng "3.574.000 ₫ · số lúc 11:58" · lỗi không có số cũ "Chưa tải được sổ chung" + nút chữ "Thử lại" thay nút + · cặp chờ "Sổ tiền của mình / Hôm nay đã ghi 3 khoản" · chưa ghi bao giờ "Sổ tiền / Gõ 50k, chọn danh mục là xong".
- **Vị trí đề xuất:** nhóm "Hôm nay của chúng mình", ngay dưới thẻ "Đêm qua" (`SleepCard`). Cặp chờ: dưới checklist mời. Designer ghép Home chốt thứ tự 5 lối vào. Home bản C đã ghép thẻ này giữa "Chơi" và "Phân vân".

### 3.2 Sổ tiền · tổng quan (`MoneyScreen`, mới `lib/screens/money_screen.dart`)
> **Cập nhật §15:** hàng đầu thẻ tháng có 2 số (Đã chi 30 · Còn trong ngân sách 20 căn phải); dải dưới là "Thu | Thu trừ chi"; thứ tự khối: tháng → (Chung: ba làn) → Gần đây → Tiêu vào đâu → Ví; "Tổng tài sản" → "Tổng tiền đang có"; người mới: `money-new.html`.
```
 ←        [▣ SỔ TIỀN]        ⌕  ⋯
 [ Của mình |  Chung  ]                      segmented h48 (ẩn khi cặp đang chờ)
 ┌ ‹ Tháng 10, 2026 ›        Báo cáo › ┐
 │ Đã chi                               │
 │ 9.552.000 ₫                (30 w600) │
 │            Hôm nay                   │
 │ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬|▬▬▬▬▬░░░░          │ thanh kế hoạch 8px, vạch "Hôm nay"
 │ Đã dùng 87%   Ngân sách 11.000.000 ₫ │
 │ Còn 1.448.000 ₫ cho 11 ngày cuối…    │ finding 14 w500
 │ [Thu +20.500.000 ₫ | Còn lại 10.948.000 ₫]  (sổ chung: bỏ dải này)
 └──────────────────────────────────────┘
 (Chung) ┌ Ai trả tháng này     Tổng 3.574.000 ₫ ┐
         │ (T)Thảo      (C)Ví chung     Mình(T) │
         │ 402.000 ₫    1.052.000 ₫  2.120.000 ₫│
         │ ▬▬▬|▬▬▬▬▬▬▬|▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬           │ teal | navy .35 | blue, khe 2px
         │ Mình đang ứng nhiều hơn               │
         │ 359.000 ₫ (20)          [Thanh toán] │
         └───────────────────────────────────────┘
 (Riêng) ┌ Tiêu vào đâu          Ngân sách › ┐  4 nhóm lớn nhất, thanh mảnh 3px
 ┌ Ví                Tổng tài sản 18.805.000 ₫ ┐  hàng 56: emoji · tên/loại · số dư
 │ … · Mua laptop ▬▬░░ 30% của 25.000.000 ₫    │  ví mục tiêu có thanh 6px
 └ Quản lý ví ›                                 ┘
 ┌ Gần đây                         Tất cả ›   ┐  3 ngày (Chung: 4), nhóm theo ngày
 │ Hôm nay, 20/10                 Chi 190.000 ₫│
 │ 🍜 Cơm trưa với team     −120.000 ₫        │
 └─────────────────────────────────────────────┘
                                         (+)  FAB 56 accentLove
```
- Header: `SubScreenHeader(badge: moneyBadge "SỔ TIỀN", badgeIcon: IconsaxPlusLinear.wallet_2, trailing: Row[HeaderIconButton(search_normal_1, "Tìm khoản"), HeaderIconButton(more, "Ví, danh mục, ngân sách")])`. Chip là tên màn (Semantics header).
- Segmented "Của mình · Chung": widget mới dùng chung `lib/widgets/segmented_pill.dart` (rút từ mode selector của `setup_screen.dart` + `decision_wheel_screen.dart`): h48 r20, nền trắng .55 viền trắng .65, thumb trắng r16 trượt 260ms easeInOutCubic; chữ 14 w600 navy .72, chọn w700 navy. Nhớ tab gần nhất trên máy.
- Thẻ tháng: chevron ‹ › 44 (tháng sau mờ `textTertiary` + disabled khi đang ở tháng hiện tại). Số lớn nhất màn = số đã chi (30 w600, "₫" 16 `textSecondary`). Thanh kế hoạch: track `surfaceLight` 8 r999, phần đã chi navy; ≥80% `moneyWarn`; ≥100% đầy track + `moneyNegative`; vạch hôm nay 2×16 navy .45, nhãn "Hôm nay" 12 phía trên. Hai đầu có nhãn. Finding là câu đầy đủ, số trong câu w700.
- Dải Thu | Còn lại: `surfaceLight` r16, 2 ô ngăn 1px trắng, nhãn 12, số 16 w600; thu có dấu "+" và `moneyPositive`; còn lại navy (âm thì "−", không tô đỏ).
- Thẻ ba làn (chỉ tab Chung): 3 cột bằng nhau (trái/giữa/phải căn theo cột), avatar 18 chữ cái trên tint .14 + viền 1.5 màu người; "Ví chung" avatar "C" xám. Thanh 8px r999 chia 3 đoạn khe 2px. Dòng cân bằng: nhãn 13 w600, số 20 w600, phụ 12 "Đã trừ 400.000 ₫ Thảo trả ngày 16/10"; nút "Thanh toán" outline pill h44. Cân bằng = 0: "Hai bên đang ngang nhau / 0 ₫", ẩn nút. Người ấy đang ứng: "Thảo đang ứng nhiều hơn 120.000 ₫", nút vẫn "Thanh toán" (mình là người trả).
- "Tiêu vào đâu" (chỉ sổ riêng): 4 nhóm cấp 1 lớn nhất; số căn phải; thanh 3px xám .22, nhóm đầu navy; nhóm có ngân sách ghi "59% ngân sách" 12 bên tên; nhóm ≥80% thành pill warn, ≥100% pill neg + thanh `moneyNegative`.
- Ví: hàng 56 (emoji 20 trong ô 28, tên 15 w600, loại 13, số dư 15 w600 căn phải). Thẻ tín dụng âm in "−2.458.000 ₫" mực navy (dư nợ là bình thường). Ví mục tiêu: thanh 6px + "30% của 25.000.000 ₫". Tab Chung: "Ví chung" phụ "Mỗi người góp 1.000.000 ₫ tháng này"; tiêu đề thẻ "Ví chung & quỹ"; link cuối "Góp vào quỹ".
- Gần đây: nhóm theo ngày ("Hôm nay, 20/10", "Hôm qua, 19/10", "Chủ nhật, 18/10"), tổng chi ngày 12 bên phải. Hàng khoản 56: emoji danh mục (ô 28) · ghi chú 15 w600 (trống → tên danh mục) · dòng phụ 13: sổ riêng "Danh mục · Ví" (+ icon `people` 14 nếu khoản có ở sổ chung); sổ chung "(avatar) Thảo trả · chia đôi" / "(C) Trả từ Ví chung". Số: chi "−120.000 ₫" navy, thu "+…" `moneyPositive`, chuyển/điều chỉnh/thanh toán xám không dấu. Sửa bởi người ấy: dòng 12 dưới số "Thảo sửa 21:02". Chờ mạng: dưới số icon `cloud_cross` 14 + "chờ mạng".
- FAB: tròn 56 `accentLove`, icon `add` 28 trắng, phải 16, đáy 24 + safe area; không bóng; ẩn khi cuộn xuống, hiện khi cuộn lên (200ms easeOutCubic). Cuối danh sách đệm 112 để FAB không che dòng cuối.
- Cặp đang chờ (D5): không segmented; cuối trang 1 thẻ "Khi người ấy vào, chúng mình sẽ có thêm sổ chung: ai trả, chia đôi, quỹ đi chơi." + link "Gửi lời mời ›" (mở luồng mời có sẵn).

### 3.3 Sheet ghi khoản (`AddTransactionSheet`, mới `lib/widgets/money/add_transaction_sheet.dart`)
> **Cập nhật sau vòng soát dễ dùng (§15), bản này thắng các dòng dưới nếu khác:** hàng đầu = Đóng · segmented Chi/Thu/Chuyển · nút sổ (tiêu đề "Ghi khoản" chỉ còn cho trình đọc màn hình) → số tiền → chip 50k… → hàng "Ghi lại khoản quen" (chỉ khi ô số trống) → Danh mục → hàng chip Ví (thay công tắc "Trừ vào ví của mình"; sổ chung có thêm chip "Không trừ") → hàng tóm tắt (sổ chung: ai trả · cách chia · ngày; sổ riêng: ngày · ghi chú) → bàn phím phím 48 → Lưu ghim đáy. Snackbar sau Lưu có "Hoàn tác".
- Modal bottom sheet trắng, bo trên 28, gần full chiều cao, handle 40×4. Hàng đầu h48: `close_circle` 24 (Đóng) · tiêu đề "Ghi khoản" 18 w700 · nút sổ "Sổ chung ⌄" (pill h36 `surfaceLight`, 13 w700) bật qua lại Của mình/Chung (cặp chờ: ẩn nút).
- Segmented Chi | Thu | Chuyển (radiogroup) h44 nền `surfaceLight`.
- Số tiền: 40 w600 căn giữa, "₫" 20 xám; số 0 navy .35; dòng gợi ý 13: trống "Gõ 50k, 1tr2 hay 1 củ đều được" · đã gõ chữ đơn vị "Bạn gõ “1tr2”" · không hiểu "Chưa hiểu số này. Thử 120k hoặc 120000." (`moneyNegative` w600) · quá 10 tỷ: số hiện 30 `moneyNegative` + "Tối đa 10 tỷ một khoản. Kiểm tra lại số 0 nhé."
- Chip 50k · 100k · 200k · 500k (h40, hit 48, `surfaceLight`): chạm = điền, chạm tiếp = cộng dồn; gõ phím số sau khi chạm chip = thay mới.
- Danh mục: nhãn 13 w700 + hàng chip cuộn ngang: 5 danh mục dùng gần nhất của sổ (mặc định chọn sẵn cái gần nhất, D9) + chip "Tất cả" (`category_2`) mở bộ chọn 2 cấp. Chọn = nền navy chữ trắng.
- Hàng tóm tắt (h52 r20 `surfaceLight`): sổ chung "(avatar) Mình trả · chia đôi · trừ Techcombank ⌄"; sổ riêng "MoMo · Hôm nay · Thêm ghi chú ⌄". Chạm → mở chi tiết, bàn phím ẩn; chạm số tiền → bàn phím mở lại.
- Bàn phím riêng 4×4, phím 52 r16 cách 8: `1 2 3 ⌫ / 4 5 6 k / 7 8 9 tr / , 0 000 củ`. Phím đơn vị nền navy .08, 16 w700; chỉ nhận 1 đơn vị, sau số. Ô số dư ở các màn khác dùng bàn phím hệ thống `TextInputType.numberWithOptions(decimal: true)` + cùng parser.
- Chi tiết (sổ chung, Chi): "Ai trả" segmented Mình | Thảo | Ví chung · "Chia thế nào" chip Chia đôi · Mình mời (Thảo trả thì "Thảo mời") · Trả hộ · Tuỳ · Tuỳ mở ô "Mình chịu" + nút −/+ 10% (44×44) · dòng kết quả 13 w600 "Mình chịu 240.000 ₫ · Thảo chịu 240.000 ₫" (chia đôi số lẻ: người trả chịu phần làm tròn lên) · công tắc "Trừ vào ví của mình / Techcombank, ghi thêm 1 khoản ở sổ của mình" (chỉ khi Mình trả, mặc định bật nếu sổ riêng có ví) · Ví chung trả: thay hai mục trên bằng "Trả từ Ví chung nên không ai ứng cho ai." Sau đó: Ví (khi không phải chia), Ngày ("Hôm nay, 20/10" → date picker app), Ghi chú (ô 52 r20, ≤200, gợi ý "Bún chả, quà sinh nhật…"). Chuyển: Từ ví · Sang ví, không có danh mục.
- Nút Lưu pill h52 navy, nhãn kèm số "Lưu 1.200.000 ₫". Chưa hợp lệ: nền `surfaceLight` chữ `textSecondary` + lý do "Nhập số tiền để lưu" / "Sửa số tiền để lưu" (không dùng mờ khó đọc). Bấm: spinner trong nút ≤ thời gian ghi cache, đóng sheet, snackbar.
- Sau Lưu: snackbar navy r20 floating 4 giây "Đã ghi 120.000 ₫ · Ăn ngoài" + nút "Xem"; nếu chạm 80/100% ngân sách nhóm/tổng thì thêm dòng 12 "Ăn uống chung vượt ngân sách tháng 62.000 ₫" (cảnh báo trong app, D17).
- Bộ chọn danh mục 2 cấp: sheet con, ← quay lại, "Sửa" (→ Danh mục), ô tìm "Tìm danh mục, vd “trà sữa”" (so không dấu), từng nhóm: hàng nhóm 44 (chọn được chính nhóm) + chip mục con quấn dòng.
- Sửa khoản: cùng sheet, tiêu đề "Sửa khoản", thêm nút chữ "Xoá khoản" `moneyNegative` cuối. Khoản chung có `linkId` mà mình không phải người tạo: ô số tiền, Ai trả, Cách chia, Ví khoá (chữ 13 "Chỉ Tuấn sửa được số tiền vì khoản này có ở sổ của Tuấn"), danh mục/ghi chú/ngày vẫn sửa được (D13).

### 3.4 Lần đầu mở (`MoneyFirstRun`, trong `MoneyScreen` khi sổ riêng chưa có cờ đã xem)
- Header như tổng quan (không ⌕ ⋯). Câu hỏi 22 w700 "Tiền của mình đang nằm ở đâu?" + 14 "Bật những ví đang dùng, nhập số dư lúc này. Bỏ qua cũng được: đã có sẵn ví Tiền mặt."
- 1 ContentCard 5 hàng: Tiền mặt (Có sẵn, công tắc khoá bật) · Ngân hàng · MoMo · ZaloPay · Thẻ tín dụng ("Dư nợ hiện tại", nhập số dương, lưu âm). Bật → hiện ô số dư (h44 r20, căn phải, parser chung). Không dùng logo MoMo/ZaloPay (chỉ tên + emoji, D8).
- Thẻ "Tổng tài sản" cập nhật ngay. Nút "Xong, vào sổ" (navy h52) + "Bỏ qua" (nút chữ).

### 3.5 Ví, chi tiết ví, tạo ví, điều chỉnh
- **Ví** (`MoneyWalletsScreen`): chip "VÍ" `wallet_2`, trailing `add`. Thẻ "Tổng tài sản" (30 w600 + câu "Cộng 4 ví đang dùng, kể cả dư nợ thẻ VIB. Ví mục tiêu để riêng bên dưới."). Thẻ "Đang dùng" (số ví bên phải), "Mục tiêu" ("không tính vào tổng"; thanh 6px; "Cần ~3.500.000 ₫ mỗi tháng"), "Đã lưu trữ" (hàng mờ .72, "Lưu trữ từ 02/08, giữ nguyên lịch sử"). Nút "Thêm ví" navy cuối.
- **Chi tiết ví**: chip = tên ví (icon theo loại: `card` ngân hàng/thẻ, `wallet_2` còn lại), trailing `edit_2`. Thẻ số dư 30 + "Ngân hàng · tính vào tổng tài sản" + dải Vào tháng 10 | Ra tháng 10 + 2 nút outline h44 "Chuyển tiền" · "Điều chỉnh" (Semantics "Điều chỉnh số dư"). Danh sách khoản tháng theo ngày, dòng phụ bỏ tên ví.
- **Tạo ví** (sheet): radiogroup 5 loại (hàng 52, mô tả 12: Tiền trong túi · Techcombank, VCB… · MoMo, ZaloPay… · Số dư âm là bình thường · Để dành cho một việc, có hạn) → Tên (nút emoji 52 r20 + ô ≤30) → Số dư lúc này → công tắc "Tính vào tổng tài sản / Tắt cho ví giữ hộ người khác" → "Tạo ví". Loại Mục tiêu: thay số dư bằng "Cần bao nhiêu" + "Hạn (không bắt buộc)" + câu "Cần để dành ~1.000.000 ₫ mỗi tháng trong 3 tháng tới." → "Tạo mục tiêu".
- **Điều chỉnh số dư** (sheet): "Tiền mặt · trong sổ đang là 475.000 ₫", ô số 40 "Số tiền thật đang có", ô giải thích `surfaceLight` "Sẽ ghi 1 khoản điều chỉnh −23.000 ₫. Khoản này đổi số dư, không tính vào chi tiêu tháng." → "Cập nhật số dư".
- **Chuyển giữa ví**: chính sheet ghi khoản, tab Chuyển.

### 3.6 Danh mục (`MoneyCategoriesScreen`)
- Chip "DANH MỤC" `category_2`, trailing `add`. Segmented Chi | Thu. Dòng phạm vi 13 trên nền blush "Sổ của mình · mỗi sổ có bộ danh mục riêng" (navy .80).
- 1 thẻ: hàng nhóm 56 (emoji · tên · "4 mục con" · chevron xoay 90° khi mở). Mở ra: hàng mục con 48 thụt 28 (icon `edit_2` 18 bên phải), mục đổi tên ghi "Đã đổi tên, gốc là “Cà phê, trà sữa”", mục tự thêm ghi "Tự thêm", cuối nhóm "+ Thêm mục con".
- Thẻ "Đã ẩn": hàng + "Khoản cũ vẫn giữ tên" + nút "Hiện lại" (`surfaceLight` h44, icon `eye`).
- Sheet sửa: Tên (emoji + ô ≤24) · "Tên gốc: … Đổi tên chỉ áp cho sổ này." · "Nằm trong" (đổi nhóm cha) · Lưu · nút chữ "Ẩn danh mục này" (`eye_slash`). Danh mục tự thêm: thêm "Xoá danh mục" (khoản cũ về "Khác").
- Emoji mặc định: theo D9 cho nhóm; mục con do Designer gán (xem `data.js`). Đổi 1 emoji của PO: Gia đình 👨‍👩‍👧 → 👪 (chuỗi ZWJ vỡ thành 3 hình trên một số máy Android/Chrome).

### 3.7 Ngân sách (`MoneyBudgetsScreen`)
- Chip "NGÂN SÁCH" `chart_2`, trailing `add`, segmented sổ. Thẻ tổng: "Tháng 10 · cả sổ chung" + "còn 11 ngày", số 30, thanh kế hoạch có vạch hôm nay, câu "Còn 1.426.000 ₫, tức khoảng 129.000 ₫ mỗi ngày tới hết tháng."
- Thẻ "Theo danh mục": hàng 2 tầng (emoji · tên · % hoặc pill · số đã chi căn phải / thanh 8px / "Còn 58.000 ₫ của 2.000.000 ₫"). Màu chỉ trên dòng ≥80% (pill warn "97%", thanh `moneyWarn`) và ≥100% (pill neg "Vượt 3%", thanh `moneyNegative`, "Vượt 62.000 ₫ của 2.000.000 ₫"). Dưới 80% xám.
- Thẻ "Chưa đặt ngân sách": nhóm đang có chi + "Đã chi 1.276.000 ₫ tháng này" + nút "Đặt" (`surfaceLight` h44).
- Chú thích cuối (sổ chung): "Chạm 80% và 100% ngân sách tổng: người không ghi khoản đó nhận thông báo chỉ có phần trăm, không có số tiền."

### 3.8 Báo cáo (`MoneyReportScreen`)
- Chip "BÁO CÁO" `chart_2`, segmented sổ. Thẻ tháng: sổ riêng 3 ô Thu | Chi | Còn lại (14 w600, nền `surfaceLight`); sổ chung số lớn 30. Finding: "Chi nhiều nhất là Nhà cửa, chiếm 59% cả tháng, phần lớn là tiền nhà 4.500.000 ₫." / "Ăn uống chiếm 54% chi chung, gần một nửa là đi chợ."
- (Chung) "Theo người": ba làn + % + "Góp vào ví chung và quỹ tháng này: Thảo 1.800.000 ₫, mình 2.200.000 ₫."
- "Chi theo danh mục": danh sách thanh xếp giảm dần (UI UX Pro Max: thanh ngang, không treemap), % của chi tháng; chạm mở mục con (thụt 30, 14 w500 xám).
- "Chi mỗi tháng": segmented nhỏ 6 tháng | 12 tháng (h38 trong khung 44). Cột vuông bo trên 3, tháng cũ navy .30, tháng hiện tại `accentLove` + nhãn giá trị "9,6tr"; 4 vạch ngang #EFE7EF, trục 0 đậm hơn; tick trái 11 dạng gọn (4tr/8tr/12tr); đường ngân sách tổng đứt 4/3 navy + nhãn "Ngân sách 11tr"; 12 tháng: nhãn T cách 1, chú "Tết" trên cột tháng 2. Tháng chưa có sổ: không vẽ cột (không vẽ 0 giả); câu "Sổ chung mới có từ tháng 10, nên các tháng trước để trống." Phụ chú "Tháng 10 mới tính tới 20/10. Đường đứt là ngân sách tổng hiện tại."
- "Chi theo ví": hàng emoji · tên · số.

### 3.9 Tìm khoản (`MoneySearchScreen`)
- Chip "TÌM KHOẢN" `search_normal_1`, segmented sổ. Ô tìm trắng h52 r20, icon trái, nút xoá `close_circle` phải (44). Hàng chip lọc cuộn ngang (nền trắng .86, chọn navy): "3 tháng gần đây ⌄" · Ví · Danh mục · Khoảng tiền · (Chung) Người.
- Thẻ kết quả: "3 khoản" trái + tổng "410.000 ₫" phải; "Gõ không dấu vẫn ra, vd “bun cha” ra “Bún chả”."; hàng khoản có ngày đầu dòng phụ, phần khớp tô nền rose .16 r4.
- Rỗng: "0 khoản · 0 ₫" + "Không có khoản nào khớp “lau de” trong 3 tháng gần đây." + nút "Tìm trong 12 tháng". Quá 2.000 dòng: notice "Chỉ tìm trong 2.000 khoản gần nhất của 12 tháng này. Thu hẹp ngày để chắc không sót."

### 3.10 Quỹ (ví Mục tiêu, `MoneyGoalScreen`)
- Chip = tên quỹ, icon `flag`, trailing `edit_2`. Thẻ đầu: "Chúng mình đã góp" (sổ riêng: "Đã để dành") 30 + thanh 12px hai đầu nhãn "40%" / "Mục tiêu 5.000.000 ₫" + câu "Còn 3.000.000 ₫. Để kịp 31/01/2027, mỗi tháng chúng mình cần để dành khoảng 1.000.000 ₫." (số tháng = tháng hạn − tháng hiện tại; làm tròn lên nghìn). Không hạn: "Chưa đặt hạn. Thêm hạn để biết mỗi tháng cần để dành bao nhiêu."
- (Chung) "Mỗi người góp": 2 làn Thảo | Mình + thanh 3 đoạn (Thảo, Mình, phần còn thiếu trống).
- "Lịch sử góp" theo ngày ("(avatar) Thảo góp", +800.000 ₫ xanh). Nút đáy: "Chi từ quỹ" outline + "Góp vào quỹ" navy (2:3).
- Đủ 100%: thẻ đầu đổi chữ "Đủ ngày 28/12/2026" + "Đủ rồi. Lên lịch đi Đà Lạt thôi, tiền chi chuyến đi ghi thẳng từ quỹ này." Không pháo hoa (push "đủ rồi" đã báo).

### 3.11 Thanh toán (sheet `SettleSheet`)
- Tiêu đề "Thanh toán". Dòng "(T) Thảo trả lại cho mình (T)" 15. Số 40 "359.000 ₫" (sửa được, "Sửa được nếu trả một phần"). Chip "Trả hết" (chọn) · "Một nửa · 179.500 ₫". Ô giải thích "Chỉ ghi lại là đã trả, app không chuyển tiền. Khoản này cân lại sổ chung và không tính vào chi tiêu tháng." → "Đánh dấu đã thanh toán".
- Thẻ "Vì sao là 359.000 ₫" (bằng chứng cạnh câu trả lời): "Dấu cộng: mình ứng cho Thảo. Dấu trừ: Thảo ứng cho mình. 2 khoản “mời” và các khoản trả từ Ví chung không tính." + 9 hàng (avatar người trả · ghi chú · "20/10 · Thảo trả · chia đôi" · ±số) + "Cộng lại +359.000 ₫".

## 4. Trạng thái (D26) — ở đâu có hình
| Trạng thái | Cách hiện | Mockup |
|---|---|---|
| Lần đầu mở | màn ví 1 màn | `first-run.html` |
| Tháng rỗng | 0 ₫ in ra là 0, thanh rỗng, câu hướng dẫn trong thẻ tháng, thẻ Gần đây giữ khung + câu | `money-empty.html` |
| Đang chờ người ấy | không segmented, thẻ D5 cuối trang | `money-waiting.html` |
| Đang tải | khung + nhãn hiện ngay, số thay bằng `ShimmerSkeleton` đúng cỡ (30 cao cho số 30), hàng giữ nhịp | `money-loading.html`, `more-states.html` |
| Lỗi | trong khối hỏng: icon `warning_2` `moneyNegative` + "Chưa tải được khoản mới. Số liệu đúng lúc 09:14." + nút "Thử lại"; khối khác giữ số cũ | `money-error.html`, `more-states.html` |
| Mất mạng / chờ mạng | notice trắng .86 trên đầu; khoản chờ hiện ngay, cộng vào mọi tổng (3.574.000 → 3.609.000 ₫, cân bằng 359.000 → 376.500 ₫), dưới số "chờ mạng" | `money-offline.html` |
| Ghi bị từ chối | snackbar "Chưa lưu được: Thảo vừa sửa khoản này / Đã hiện bản mới nhất, sửa lại nếu cần" | `add-tx-states.html` |
| Ngân sách chưa đặt / 80% / 100% / vượt | thẻ rỗng + nút; pill warn; pill neg + thanh đỏ | `budgets.html`, `more-states.html` |
| Ví thường bị âm | pill warn số âm + "Số dư âm, có khoản nào ghi nhầm ví không?" (thẻ tín dụng không báo) | `more-states.html` |
| Mục tiêu chưa có hạn / đạt 100% | câu thay; thẻ đổi chữ | `more-states.html`, `goal.html` |
| Khoản riêng nối khoản chung bị người ấy sửa | dải warn trong hàng "Thảo đã đổi khoản chung thành 520.000 ₫" + "Cập nhật" | `add-tx-states.html` |
| Hỏi sửa cả hai sổ | dialog r28 "Sửa luôn bên sổ của mình?" + "Sửa cả hai" / "Chỉ sổ chung" | `add-tx-states.html` |
| Xoá + hoàn tác | snackbar 5 giây "Đã xoá Lẩu Thái Phố Huế · 480.000 ₫" + "Hoàn tác"; lệnh xoá gửi sau 5 giây | `add-tx-states.html` |
| Đã cân bằng | "Hai bên đang ngang nhau / 0 ₫", ẩn nút | `more-states.html` |
| Người ấy đã rời | tab Chung ẩn; dữ liệu cũ giữ (mốc C "Sổ cũ") | `more-states.html` |
| Khoá Sổ tiền, khoản định kỳ chờ xác nhận | mốc B, chưa vẽ | §10 |
| Disabled | nút Lưu nền `surfaceLight` chữ `textSecondary` + lý do; công tắc ví Tiền mặt khoá ở lần đầu (opacity .55, nhãn "Có sẵn") | `add-tx.html`, `first-run.html` |

## 5. Token
- **Màu**: §1. Đề xuất bổ sung design system (chưa có trong `AppColors`): `moneyPositive #247B50`, `moneyNegative #C4242A`, `moneyWarn #B65A00`, pill neg `#FFEDEA/#831C1E`, pill warn `#FFF4E0/#8A4B00`. Lý do: `success #66BB6A` và `error #EF5350` làm chữ trên trắng chỉ ~2,3:1 và ~3,4:1; `warning #FFA726` làm thanh trên `surfaceLight` dưới 3:1. Màu người lấy từ `PersonPalette` (đã có).
- **Cỡ chữ** (đều trong type scale, không cỡ lẻ): 11 chip header · 12 meta, nhãn KPI, nhãn trục · 13 dòng phụ, nhãn ô, ghi chú phạm vi · 14 câu finding, nút nhỏ, link · 15 tên hàng, số trong hàng, nút h52 · 16 tiêu đề thẻ, số phụ · 18 tiêu đề sheet · 20 số cân bằng, tiêu đề dialog · 22 câu hỏi lần đầu, phím số · 30 số trả lời màn (đã chi, tổng tài sản, số dư ví) · 40 ô nhập số tiền. Weight: số tiền 600; tiêu đề 700; chữ 500. Kiểm đo: mỗi màn 7–10 cỡ.
- **Bo góc**: thẻ 24 · sheet/dialog 28 (trên) · ô nhập, hàng tóm tắt 20 · nhóm trong thẻ, phím 16 · chip, nút, thanh 999.
- **Khoảng cách**: gutter 16 · padding thẻ 20 (lối vào Home 16) · thẻ cách 16 · hàng 2 dòng 56 (mục con 48, hàng cài đặt 52) · chip h40 (vùng chạm 48) cách 8 · phím 52 cách 8 · nút h52 / nhỏ h44 · FAB 56.
- **Bóng**: chỉ `ContentCard` (black .06 blur 16 y10), `EyebrowChip` (rose .14 blur 10 y4), snackbar/sheet (overlay). FAB, nút, chip: không bóng.

## 6. Copy deck (vi / en)
Xưng "chúng mình"/"mình", dấu kiểu mới. Copy chốt trong spec PO giữ nguyên (đánh dấu PO). Đã soát theo humanizer (bỏ "đầy đủ", "dễ dàng", câu chốt lặp ý) và avoid-ai-writing cho EN.

| Key | VI | EN |
|---|---|---|
| moneyTitle (PO §11) | Sổ tiền | Money book |
| moneyBadge | SỔ TIỀN | MONEY BOOK |
| moneyTabMine / moneyTabShared (PO) | Của mình / Chung | Mine / Shared |
| moneyHomeShared | Sổ chung tháng {month} | Shared book · {month} |
| moneyHomeSpent | Đã chi {amount} · {percent}% ngân sách | Spent {amount} · {percent}% of budget |
| moneyHomeSpentNoBudget | Đã chi {amount} tháng này | Spent {amount} this month |
| moneyHomeOver | Đã chi {amount} · vượt {over} | Spent {amount} · {over} over |
| moneyHomeZero | Đã chi 0 ₫ · chưa có khoản nào | Spent ₫0 · nothing yet |
| moneyHomeStale | {amount} · số lúc {time} | {amount} · as of {time} |
| moneyHomeError | Chưa tải được sổ chung | Couldn't load the shared book |
| moneyHomeMine / moneyHomeTodayCount | Sổ tiền của mình / Hôm nay đã ghi {n} khoản | My money book / {n} entries today |
| moneyHomeFirst | Gõ 50k, chọn danh mục là xong | Type 50k, pick a category, done |
| moneyAddTx | Ghi khoản | Add entry |
| moneyMonthSpentMine / Shared | Đã chi / Chúng mình đã chi | Spent / We spent |
| moneyBudgetUsed | Đã dùng {percent}% | {percent}% used |
| moneyBudgetOf | Ngân sách {amount} | Budget {amount} |
| moneyToday | Hôm nay | Today |
| moneyFindingLeft | Còn {left} cho {days} ngày cuối tháng. Tháng mới qua {passed}/{total} ngày mà đã dùng {percent}% ngân sách. | {left} left for the last {days} days. The month is {passed}/{total} days in and {percent}% of the budget is gone. |
| moneyFindingCategory | {category} chung đã dùng {percent}% ngân sách, còn {left} cho {days} ngày. | Shared {category} is at {percent}% of budget, {left} left for {days} days. |
| moneyIncome / moneyLeft | Thu / Còn lại (thu − chi) | Income / Left (income − spent) |
| moneyWhoPaid | Ai trả tháng này | Who paid this month |
| moneyJointWallet | Ví chung | Shared wallet |
| moneyMe | Mình | Me |
| moneyBalanceMeAhead (PO D12) | Mình đang ứng nhiều hơn | I've covered more |
| moneyBalancePartnerAhead | {name} đang ứng nhiều hơn | {name} has covered more |
| moneyBalanceEven | Hai bên đang ngang nhau | We're even |
| moneyBalanceSince | Đã trừ {amount} {name} trả ngày {date} | After {name} paid back {amount} on {date} |
| moneySettle | Thanh toán | Settle up |
| moneyWhere | Tiêu vào đâu | Where it went |
| moneyBudgets / moneyReport / moneyWallets / moneyCategories | Ngân sách / Báo cáo / Ví / Danh mục | Budgets / Report / Wallets / Categories |
| moneyTotalAssets | Tổng tài sản | Net worth |
| moneyManageWallets / moneyContribute | Quản lý ví / Góp vào quỹ | Manage wallets / Add to fund |
| moneyJointContribEach | Mỗi người góp {amount} tháng này | Each of us put in {amount} this month |
| moneyRecent / moneySeeAll | Gần đây / Tất cả | Recent / All |
| moneyDaySpent | Chi {amount} | Spent {amount} |
| moneyPaidBy | {name} trả · {split} | {name} paid · {split} |
| moneyPaidFromJoint | Trả từ Ví chung | Paid from shared wallet |
| moneySplitEqual / Treat / ForPartner / Custom (PO D12) | chia đôi / mời / trả hộ / tuỳ | split / treat / covered / custom |
| moneyEditedBy | {name} sửa {time} | Edited by {name} {time} |
| moneyPending | chờ mạng | waiting for signal |
| moneyOffline | Đang mất mạng. Số dư tính tạm từ lúc {time} cộng {n} khoản chờ gửi. | Offline. Balances are from {time} plus {n} entries waiting to send. |
| moneyLoadError | Chưa tải được khoản mới. Số liệu đúng lúc {time}. | Couldn't load new entries. Figures are from {time}. |
| moneyRetry | Thử lại | Try again |
| moneyEmptyMonth | Tháng {month} chưa có khoản nào. Nút hồng ở góc dưới để ghi khoản đầu tiên. | Nothing in {month} yet. Use the pink button below to add the first entry. |
| moneyWaitingCard (PO D5) | Khi người ấy vào, chúng mình sẽ có thêm sổ chung: ai trả, chia đôi, quỹ đi chơi. | When they join, we'll get a shared book too: who paid, splitting, a trip fund. |
| moneySendInvite | Gửi lời mời | Send invite |
| moneyTypeExpense / Income / Transfer | Chi / Thu / Chuyển | Expense / Income / Transfer |
| moneyAmountHint | Gõ 50k, 1tr2 hay 1 củ đều được | 50k, 1.2M or 1 million all work |
| moneyAmountEcho | Bạn gõ “{raw}” | You typed “{raw}” |
| moneyAmountInvalid | Chưa hiểu số này. Thử 120k hoặc 120000. | That number didn't parse. Try 120k or 120000. |
| moneyAmountTooBig | Tối đa 10 tỷ một khoản. Kiểm tra lại số 0 nhé. | 10 billion max per entry. Check the zeros. |
| moneyCategory / moneyAllCategories | Danh mục / Tất cả | Category / All |
| moneyWhoPays / moneyHowSplit | Ai trả / Chia thế nào | Who paid / How to split |
| moneyTreatMe / moneyTreatPartner | Mình mời / {name} mời | My treat / {name}'s treat |
| moneyShares | {a} chịu {x} · {b} chịu {y} | {a} pays {x} · {b} pays {y} |
| moneyNoOneOwes | Trả từ Ví chung nên không ai ứng cho ai. | Paid from the shared wallet, so nobody owes anyone. |
| moneyDeductMine | Trừ vào ví của mình | Take it from my wallet |
| moneyDeductMineSub | {wallet}, ghi thêm 1 khoản ở sổ của mình | {wallet}, also adds an entry to my book |
| moneyWallet / moneyDate / moneyNote / moneyNoteHint | Ví / Ngày / Ghi chú / Bún chả, quà sinh nhật… | Wallet / Date / Note / Lunch, birthday gift… |
| moneySaveAmount / moneySaveNeedAmount / moneySaveFixAmount | Lưu {amount} / Nhập số tiền để lưu / Sửa số tiền để lưu | Save {amount} / Enter an amount to save / Fix the amount to save |
| moneySaved | Đã ghi {amount} · {category} | Saved {amount} · {category} |
| moneySavedOffline | Đang chờ mạng, có mạng sẽ tự gửi lên sổ chung | Waiting for signal, it'll sync to the shared book |
| moneyOverBudgetToast | {category} chung vượt ngân sách tháng {amount} | Shared {category} is {amount} over this month's budget |
| moneyNearBudgetToast | {category} chung đã dùng {percent}% ngân sách tháng | Shared {category} is at {percent}% of this month's budget |
| moneyConflict | Chưa lưu được: {name} vừa sửa khoản này / Đã hiện bản mới nhất, sửa lại nếu cần | Not saved: {name} just edited this entry / Showing the latest version, edit again if needed |
| moneyDeleted / moneyUndo | Đã xoá {note} · {amount} / Hoàn tác | Deleted {note} · {amount} / Undo |
| moneyLinkedAskTitle (PO D11) | Sửa luôn bên sổ của mình? | Change it in my book too? |
| moneyLinkedAskBody | Khoản “{note}” cũng đang trừ {old} ở {wallet}. Đổi thành {new} ở cả hai sổ? | “{note}” also takes {old} from {wallet}. Change both books to {new}? |
| moneyLinkedBoth / moneyLinkedSharedOnly | Sửa cả hai / Chỉ sổ chung | Change both / Shared book only |
| moneyLinkedChanged (PO D11) | {name} đã đổi khoản chung thành {amount} | {name} changed the shared entry to {amount} |
| moneyLinkedUpdate | Cập nhật | Update |
| moneyLinkedLocked | Chỉ {name} sửa được số tiền vì khoản này có ở sổ của {name} | Only {name} can change the amount, it's also in their own book |
| moneyFirstRunTitle | Tiền của mình đang nằm ở đâu? | Where's my money right now? |
| moneyFirstRunBody | Bật những ví đang dùng, nhập số dư lúc này. Bỏ qua cũng được: đã có sẵn ví Tiền mặt. | Turn on the wallets you use and enter today's balance. You can skip this, a Cash wallet is already set up. |
| moneyFirstRunDone / moneySkip | Xong, vào sổ / Bỏ qua | Done, open my book / Skip |
| moneyWalletCash / Bank / Ewallet / Credit / Goal | Tiền mặt / Ngân hàng / Ví điện tử / Thẻ tín dụng / Mục tiêu | Cash / Bank / E-wallet / Credit card / Goal |
| moneyWalletTypeHints | Tiền trong túi / Techcombank, VCB… / MoMo, ZaloPay… / Số dư âm là bình thường / Để dành cho một việc, có hạn | Cash on hand / Techcombank, VCB… / MoMo, ZaloPay… / A negative balance is normal / Saving for one thing, with a deadline |
| moneyCreditDebt | Dư nợ hiện tại | Current balance owed |
| moneyIncludeInTotal / Sub | Tính vào tổng tài sản / Tắt cho ví giữ hộ người khác | Count in net worth / Turn off for money you hold for someone else |
| moneyCreateWallet / moneyCreateGoal | Tạo ví / Tạo mục tiêu | Create wallet / Create goal |
| moneyGoalTarget / moneyGoalDeadline | Cần bao nhiêu / Hạn (không bắt buộc) | Target / Deadline (optional) |
| moneyGoalPerMonth | Cần để dành ~{amount} mỗi tháng trong {n} tháng tới. | Save about {amount} a month for the next {n} months. |
| moneyAdjustTitle / Body | Điều chỉnh số dư / Sẽ ghi 1 khoản điều chỉnh {amount}. Khoản này đổi số dư, không tính vào chi tiêu tháng. | Adjust balance / This adds an adjustment of {amount}. It changes the balance and doesn't count as spending. |
| moneyAdjustReal / moneyAdjustSave | Số tiền thật đang có / Cập nhật số dư | What you actually have / Update balance |
| moneyArchived | Lưu trữ từ {date}, giữ nguyên lịch sử | Archived {date}, history kept |
| moneyCategoryScope | Sổ của mình · mỗi sổ có bộ danh mục riêng | My book · each book has its own categories |
| moneySubCount / moneyAddSub | {n} mục con / Thêm mục con | {n} subcategories / Add subcategory |
| moneyRenamedFrom / moneyCustom | Đã đổi tên, gốc là “{name}” / Tự thêm | Renamed from “{name}” / Added by you |
| moneyHidden / moneyHiddenSub / moneyShowAgain / moneyHideCategory | Đã ẩn / Khoản cũ vẫn giữ tên / Hiện lại / Ẩn danh mục này | Hidden / Old entries keep the name / Show again / Hide this category |
| moneyBudgetDailyLeft | Còn {left}, tức khoảng {perDay} mỗi ngày tới hết tháng. | {left} left, about {perDay} a day until month end. |
| moneyBudgetOver / Left | Vượt {amount} của {budget} / Còn {amount} của {budget} | {amount} over {budget} / {amount} left of {budget} |
| moneyBudgetUnset / moneySetBudget | Chưa đặt ngân sách. Đặt một con số cho cả tháng, app sẽ báo khi dùng tới 80% và 100%. / Đặt ngân sách tháng | No budget yet. Set one number for the month and we'll tell you at 80% and 100%. / Set monthly budget |
| moneyBudgetPushNote | Chạm 80% và 100% ngân sách tổng: người không ghi khoản đó nhận thông báo chỉ có phần trăm, không có số tiền. | At 80% and 100% of the total budget, the other person gets a notice with the percentage only, no amounts. |
| moneyReportTopCategory | Chi nhiều nhất là {category}, chiếm {percent}% cả tháng. | {category} was the biggest spend, {percent}% of the month. |
| moneyReportByCategory / ByMonth / ByWallet / ByPerson | Chi theo danh mục / Chi mỗi tháng / Chi theo ví / Theo người | By category / Spending per month / By wallet / By person |
| moneyReport6 / moneyReport12 | 6 tháng / 12 tháng | 6 months / 12 months |
| moneyReportPartial | Tháng {month} mới tính tới {date}. Đường đứt là ngân sách tổng hiện tại. | {month} counts up to {date}. The dashed line is the current total budget. |
| moneyReportNewBook | Sổ chung mới có từ tháng {month}, nên các tháng trước để trống. | The shared book started in {month}, so earlier months are empty. |
| moneySearchHint / moneySearchAccent | Tìm trong ghi chú và danh mục / Gõ không dấu vẫn ra, vd “bun cha” ra “Bún chả”. | Search notes and categories / Accents optional: “bun cha” finds “Bún chả”. |
| moneySearchCount | {n} khoản | {n} entries |
| moneySearchEmpty / moneySearch12 | Không có khoản nào khớp “{q}” trong 3 tháng gần đây. / Tìm trong 12 tháng | Nothing matches “{q}” in the last 3 months. / Search 12 months |
| moneySearchCap | Chỉ tìm trong 2.000 khoản gần nhất của khoảng này. Thu hẹp ngày để chắc không sót. | Only the latest 2,000 entries in this range are searched. Narrow the dates to be sure. |
| moneyGoalSaved / moneyGoalSavedMine | Chúng mình đã góp / Đã để dành | We've saved / Saved |
| moneyGoalLeft | Còn {left}. Để kịp {date}, mỗi tháng chúng mình cần để dành khoảng {perMonth}. | {left} to go. To make {date}, we need about {perMonth} a month. |
| moneyGoalNoDeadline | Chưa đặt hạn. Thêm hạn để biết mỗi tháng cần để dành bao nhiêu. | No deadline yet. Add one to see how much to save each month. |
| moneyGoalEach / moneyGoalHistory | Mỗi người góp / Lịch sử góp | Who put in what / Contributions |
| moneyGoalReached | Đủ rồi. Lên lịch đi {trip} thôi, tiền chi chuyến đi ghi thẳng từ quỹ này. | Done. Time to plan {trip}, and log trip costs straight from this fund. |
| moneySpendFromFund | Chi từ quỹ | Spend from fund |
| moneySettlePays | {from} trả lại cho {to} | {from} pays {to} back |
| moneySettlePartial / moneySettleAll / moneySettleHalf | Sửa được nếu trả một phần / Trả hết / Một nửa · {amount} | Edit for a partial payment / All of it / Half · {amount} |
| moneySettleNote | Chỉ ghi lại là đã trả, app không chuyển tiền. Khoản này cân lại sổ chung và không tính vào chi tiêu tháng. | This only records the payment, no money moves. It evens out the shared book and doesn't count as spending. |
| moneySettleDo (PO) | Đánh dấu đã thanh toán | Mark as settled |
| moneySettleWhy / Legend / Sum | Vì sao là {amount} / Dấu cộng: mình ứng cho {name}. Dấu trừ: {name} ứng cho mình. {n} khoản “mời” và các khoản trả từ Ví chung không tính. / Cộng lại | Why {amount} / Plus: I covered {name}. Minus: {name} covered me. {n} treats and shared-wallet payments don't count. / Total |
| moneyNegWallet | Số dư âm, có khoản nào ghi nhầm ví không? | Negative balance. Was something logged to the wrong wallet? |
| moneyPartnerLeft | Tab Chung ẩn khi không còn ghép đôi. Các khoản chung cũ vẫn giữ trong máy chủ, chưa xem được ở bản này. | The Shared tab is hidden once you're no longer paired. Old shared entries are kept on the server but can't be viewed in this version. |

Nhắc tối (D18), push `notifyMoney` (§5 PO): giữ nguyên copy PO.

## 7. A11y
- Vùng chạm: mọi icon/nút ≥44 (iOS) và hit 48dp Android cho chip (`materialTapTargetSize: padded`); hai vùng chạm cạnh nhau cách ≥8 (lối vào Home, phím).
- Semantics: chip header `header: true` (có sẵn trong `SubScreenHeader`); FAB và nút + "Ghi khoản"; ⌕ "Tìm khoản"; ⋯ "Ví, danh mục, ngân sách"; ‹ › "Tháng trước/Tháng sau"; ⌫ "Xoá một ký tự"; phím đơn vị đọc "nghìn", "triệu", "củ"; thanh kế hoạch `Semantics(label: "Đã dùng 87% ngân sách, còn 1.448.000 đồng")`; thanh ba làn đọc đủ 3 số; số tiền đọc "120 nghìn đồng" (không đọc ký hiệu ₫). Hàng khoản gộp 1 node: "Cơm trưa với team, Ăn ngoài, MoMo, trừ 120 nghìn đồng, hôm nay".
- Ô số tiền: nhãn "Số tiền" (Semantics) + dòng gợi ý hiện; lỗi ở ngay dưới số (không chỉ ở đầu form). Segmented/chip chọn: `selected` + vai trò radio.
- Không dựa màu một mình: vượt ngân sách có chữ "Vượt 3%"; làn có tên; người trả có tên; khoản chờ có chữ "chờ mạng".
- Tương phản: chữ trên blush chỉ dùng navy ≥ .80; `textSecondary` chỉ trên trắng/surface (5,3:1 / 4,8:1); `textTertiary` không làm chữ.
- Chữ to lên (textScaler 1.3): hàng khoản cho dòng phụ xuống 2 dòng thay vì cắt; số tiền không cắt (co tên trước).

## 8. Motion
- Segmented thumb 260ms `Curves.easeInOutCubic`; chip chọn đổi nền 200ms easeOutCubic; sheet mở theo mặc định Material; mở/đóng chi tiết trong sheet `AnimatedSize` 280ms (`AppMotion.base`); FAB ẩn/hiện khi cuộn 200ms; số tiền khi gõ đổi tức thì (không đếm số).
- Không entrance cho màn tiền (app-screens: chuyển động là phản hồi). Reduce Motion (`AppMotion.reduceMotion`): thumb nhảy thẳng, FAB không trượt, sheet chi tiết không animate.
- Haptic: `selectionClick` khi bấm phím số và chọn chip; `lightImpact` khi Lưu thành công.

## 9. Thiết bị brand giữ lại (`--allow` / `taste-skill-ignore`)
| Rule tasteskill | Thiết bị | Vì sao giữ |
|---|---|---|
| `gradient` | nền `dawnBlush` | nền mọi màn của app, user chốt follow design system |
| `heavy-shadow` | bóng `ContentCard` (y10 ≥ ngưỡng 8) | card chuẩn duy nhất của app |
| `micro-label`, `small-title` | `EyebrowChip` làm tên màn (11px hoa, tracked) | header màn con của app là chip-only (`SubScreenHeader`) |
| `emoji` | emoji danh mục và ví | là dữ liệu người dùng chọn (D6/D9), không phải trang trí; không dùng emoji ở tiêu đề, nút, trạng thái rỗng |
| `icon-chips` (chỉ trang lối vào) | `IconBadge` + nút tròn, lặp 9 lần ở trang trạng thái | Lead chốt `IconBadge` cho thẻ Home; Home thật chỉ có 1 thẻ |
| `colour-sprawl` (WARN) | dawnBlush lộ ra giữa các thẻ | như trên |
- Đã thay theo luật nhà: bỏ `IconBadge` ở mọi hàng (icon trần hoặc emoji trong ô 28 không nền); thanh tiến độ không gradient; FAB và nút không bóng; vạch ngăn là 1px border, không bóng inset; số tiền căn phải.
- Ghi chú đo được: **Quicksand không có tabular figures** (GSUB chỉ có `ccmp dnom frac liga locl numr`; chữ "1" rộng 370 so với ~550 các số khác; Be Vietnam Pro cũng không có `tnum`). `FontFeature.tabularFigures()` không có tác dụng. Bù lại: mọi cột số căn phải, đơn vị "₫" cố định cuối, nên chữ số hàng đơn vị luôn thẳng cột; trong ô nhập số tăng từ phải. Muốn số thẳng tuyệt đối thì cần một phông số riêng, ngoài phạm vi (câu hỏi Q3).

## 10. Chỗ cắm mốc B / C
- Mốc B: menu ⋯ thêm "Khoản định kỳ" · "Sổ nợ" · "Xuất CSV" · "Khoá Sổ tiền"; tổng quan thêm thẻ "Sắp tới" (hoá đơn 7 ngày tới, có nút "Ghi") ngay dưới thẻ tháng; sheet ghi khoản thêm dòng "Lặp lại" trong chi tiết; khoá: màn chắn dùng lại header + nút "Mở khoá". Hàng khoản tự sinh có icon `repeat` 14 ở dòng phụ.
- Mốc C: dòng "Ảnh hoá đơn" trong chi tiết sheet (thumbnail 44 r8); "Lịch sử sửa" mở từ dòng "Thảo sửa 21:02"; "Sổ cũ" là mục cuối menu ⋯ khi có dữ liệu chung của cặp cũ.

## 11. Soát UX (UI UX Pro Max 2.13.0)
| Truy vấn | Kết quả | Áp dụng |
|---|---|---|
| `"numeric keypad amount input" --domain ux` | Input types đúng loại; label luôn hiện; ô phải trông bấm được | bàn phím riêng cho số; nhãn "Số tiền" + dòng gợi ý; ô số dư dùng bàn phím số hệ thống |
| `"bottom sheet form keyboard" --domain ux` | Submit feedback: loading → success/error | spinner trong nút Lưu, snackbar sau lưu, lỗi xung đột |
| `"undo delete snackbar"` → 0 kết quả; thử lại `"undo destructive action confirm"` | Confirm trước khi xoá | giữ hoàn tác 5 giây (D13) thay hộp xác nhận vì xoá khoản là đảo được; xoá ví không có (chỉ lưu trữ) |
| `"toast notification duration" --domain ux` | tự tắt 3–5 giây | snackbar 4 giây, hoàn tác 5 giây |
| `"touch target size spacing" --domain ux` | 44pt iOS / 48dp Android; cách ≥8px | chip h40 nhưng vùng chạm 48; phím 52 cách 8 |
| `"reduced motion" --domain ux` | tôn trọng; 1–2 chuyển động mỗi màn | §8 |
| `"color not only indicator" --domain ux` | thêm chữ/icon cạnh màu | §7 |
| `"segmented control tabs" --domain ux` | huỷ chuyển động cũ khi bấm nhanh, đặt trạng thái cuối trực tiếp | segmented đặt `selected` ngay, thumb chạy theo |
| `"offline pending sync indicator" --domain ux` | không khớp (trả về focus ring); dùng mặc định app-screens §11 | notice + "chờ mạng" trên hàng |
| `"empty state first run" --domain ux` | thông điệp + hành động | thẻ giữ khung + câu + nút |
| `"fintech finance tracker" --domain color` | navy tin cậy + 1 nhấn | khớp navy chính của app; không đổi bảng màu |
| `"spending category breakdown" --domain chart` | Treemap (rủi ro a11y cao) hoặc thanh ngang xếp giảm dần | chọn thanh ngang xếp giảm dần |
| `"trend over months" --domain chart` | Line chart | chọn cột theo tháng vì câu hỏi là "mỗi tháng bao nhiêu" (app-screens §6.1), tháng hiện tại có nhãn |
| `"budget progress over limit" --domain chart` | Waffle / line | giữ thanh kế hoạch (tỉ lệ thật, hai đầu có nhãn, phần vượt màu âm) |
| `"rounded friendly mobile vietnamese" --domain typography` | Be Vietnam Pro / Varela Round | giữ Quicksand của app (user chốt); ghi nhận thiếu `tnum` |
| `"number data font" --domain typography` | cặp có mono cho số | không dùng (mono bị cấm, app 1 phông) |
| `"number input keyboard" --stack flutter` | dùng `TextEditingController` | ô số dư + ghi chú dùng controller; bàn phím riêng ghi vào cùng controller |
| `"accessibility semantics" --stack flutter` | `Semantics` + thử TalkBack/VoiceOver | §7 |
| `"list performance" --stack flutter` | đo bằng DevTools trước khi tối ưu | danh sách tháng dùng `SliverList`, đo khi seed 120 khoản |
| `"bottom sheet modal"`, `"tabs segmented"`, `"snackbar"` `--stack flutter` → 0; thử lại `"dialog modal"` → 0 | không có dữ liệu | theo mặc định Material + quy ước app (SnackBar floating navy r20) |
- Soát chung các thành phần đứng cạnh nhau: (1) hàng đầu sheet: nút Đóng 44 · tiêu đề 18 · nút sổ h36 (nút sổ là bộ chọn, không phải hành động chính nên nhỏ hơn); (2) cả họ chip (50k, danh mục, cách chia, bộ lọc, Trả hết): cùng h40 r999, chọn = navy; (3) nút chính navy h52 + nút phụ outline h52 cùng hàng ở Quỹ (tỉ lệ 2:3); (4) FAB hồng trong Sổ tiền và nút + navy ở Home: Home vốn nhiều hồng nên nút ở Home dùng navy, trong màn tiền FAB hồng là nhấn duy nhất.
- Bên thứ ba: chỉ có tên MoMo, ZaloPay, Techcombank, VIB dưới dạng chữ người dùng gõ/gợi ý. Không dùng logo (tránh vấn đề thương hiệu và không giả vờ liên kết).

## 12. Kết quả gate + 3 vòng critique
- Lệnh (từ gốc worktree): `node ~/.claude/skills/design-taste-frontend/scripts/lint.mjs --app docs/design/expenses` → **0 FAIL, 0 WARN** (31 file; dòng emoji dữ liệu và EyebrowChip/ContentCard/dawnBlush mang `taste-skill-ignore`). `inspect.mjs --app <trang> --widths 390 --allow emoji,heavy-shadow,micro-label,small-title,gradient --out .taste-skill/expenses/<trang>` cho 23 trang → **0 FAIL** mọi trang; WARN còn lại: `colour-sprawl` (14–27%, nền blush) ở 6 trang, `icon-chips` ở `home-entry` (trang trạng thái lặp 8 nút). **Chỉ đo 390** vì app chỉ chạy trên điện thoại.
- Ảnh vòng cuối: `docs/design/expenses/shots/*.jpg` (bản gốc `.taste-skill/expenses/<trang>/`).

```
ROUND 1
Seen in one second: số "đã chi" to nhất màn, thẻ tháng có thanh + câu còn bao nhiêu; tab Chung có ba làn ngay màn đầu.
Idea: cặp đôi là ba làn (Thảo · Ví chung · Mình), cân bằng nằm cạnh nút Thanh toán.
Live thing: sheet ghi khoản gõ "1tr2" ra 1.200.000 ₫, chip cộng dồn, chia đôi tính phần mỗi người.
7 câu: (1) có, số trả lời là số lớn nhất; (2) thẻ cùng mép, không dải chết; (3) màu chỉ ở FAB, cột tháng hiện tại, dòng ≥80%; face thấy ở tab Chung; (4) phát hiện sai: trạng thái offline nói "cộng 1 khoản chờ" nhưng tổng không cộng; ví dụ rỗng "bun bo hue" lại có trong dữ liệu (Bún bò Huế 12/08); (5) 0 ₫ in ra là 0; (6) nhãn "Hôm nay" ở thanh nhóm ngân sách đè lên số tiền; (7) không có điều hướng phải gập.
Scores: design 7 · usability 7 · creativity 7 · content 7 → 7.0
Top three: 1. số liệu mâu thuẫn ở offline + search rỗng (money-offline, search). 2. chữ bị cắt/đè: "Thảo sửa 21:0…", "Điều chỉnh số dư" xuống 2 dòng, "~3.500.000 ₫/tháng tới 31/0…", nhãn "Hôm nay" đè số (money-shared, wallet, wallets, budgets). 3. trạng thái đang tải lộ số thật ở "Tiêu vào đâu" và ví mục tiêu (money-loading).

ROUND 2
Sửa: tổng/ba làn/cân bằng tính cả khoản chờ (3.609.000 ₫, 376.500 ₫); ví dụ rỗng đổi "lau de"; "Thảo sửa 21:02" xuống dưới số; nút "Điều chỉnh"; câu quỹ rút gọn; thanh nhóm bỏ nhãn; skeleton đủ.
7 câu: (4) khớp; (6) hết đè. Còn: chi tiết ví lặp tên ví ở mọi dòng phụ ("… · Techcombank"); dòng chờ mạng bị cắt "chờ mạ…"; lịch sử góp lặp "góp vào Quỹ Đà Lạt" trên chính màn quỹ.
Scores: design 7.5 · usability 8 · creativity 7 · content 7.5 → 7.6
Top three: 1. dòng phụ thừa tên ví (wallet). 2. "chờ mạng" cắt (money-offline). 3. lặp chữ ở lịch sử góp (goal).

ROUND 3
Sửa: chi tiết ví bỏ tên ví khỏi dòng phụ (giữ icon nối sổ chung); "chờ mạng" dời xuống dưới số; lịch sử góp chỉ "(avatar) Thảo góp".
7 câu: cả 7 đạt ở 390. Điểm yếu còn lại: avatar hai người cùng chữ "T" (Tuấn, Thảo) nên phân biệt dựa vào màu + tên ngay cạnh; tổng quan Của mình dài 2,2 màn; FAB che một phần thẻ ở màn đầu khi đứng yên (cuộn xuống thì ẩn, cuối trang có đệm).
Scores: design 7.5 · usability 8 · creativity 7.5 · content 8 → 7.7
```

## 13. Dev notes
- Widget mới: `MoneyScreen` + `MoneyHomeEntry` + `AddTransactionSheet` + `SettleSheet` + `MoneyWalletsScreen`/`MoneyWalletScreen` + `MoneyCategoriesScreen` + `MoneyBudgetsScreen` + `MoneyReportScreen` + `MoneySearchScreen` + `MoneyGoalScreen` (thư mục gợi ý `lib/screens/money/`, `lib/widgets/money/`). Đề xuất widget dùng chung mới `lib/widgets/segmented_pill.dart` (Lead báo designer các feature khác, decision-wheel đang tự vẽ riêng).
- Có sẵn để dùng lại: `SubScreenHeader`, `EyebrowChip`, `HeaderIconButton`, `ContentCard`, `InkTile` (cho hàng bấm được), `ShimmerSkeleton` (đang tải), `PersonPalette` (màu người), `AppMotion`, `MidnightBuilder` (đổi "Hôm nay/Hôm qua" lúc 0:00), date picker/`app_time_picker` hiện có.
- Mọi số trên màn đi qua `MoneyMath` + formatter (vi `1.250.000 ₫`, en `₫1,250,000`, âm "−" U+2212). Dạng gọn chỉ ở trục biểu đồ và nhãn cột ("9,6tr"). `data.js` là bản tham chiếu cho test Dart: parser 19 ca (13 đúng, 5 phải khoá Lưu, 1 vượt trần), cân bằng 359.000, chia đôi 75.001.
- Số "đã chi" trong offline cộng khoản `hasPendingWrites`; cân bằng/ba làn cũng vậy.
- Tháng hiện tại: "Hôm nay" là vạch ở `ngày/ngày trong tháng`; tháng cũ không có vạch.

## 15. Soát dễ dùng (UI UX Pro Max)
User 2026-10-20: "thiết kế phù hợp với người dùng và UI tiện lợi dễ sử dụng". Thước đo chính là UI UX Pro Max 2.13.0. Design system và sheet chung giữ nguyên.

**Truy vấn đã chạy** (`search.py`, không `-I`):
- `--domain ux`: "smart defaults form" · "multi step form progressive disclosure" · "numeric input keyboard mobile" · "list item swipe actions" · "onboarding first time user" · "tabs navigation mobile" · "chart labels data legibility mobile" · "delete confirmation undo" · "form validation inline error" · "thumb zone primary action bottom" (0 kết quả) → thử lại "reachable bottom action mobile" · "plain language jargon" (0) → thử lại "clear labels simple wording" · "cognitive load too much information" · "default value remember last".
- `--stack flutter`: "keyboard input form" · "touch target button" (0) → thử lại "accessibility tap target" · "listview builder" · "tab bar" · "form validation".
- Thêm: đọc `references/quick-reference.md` cho các mã quy tắc bên dưới. Hai chủ đề không có trong cơ sở dữ liệu là vùng ngón cái và từ ngữ đời thường. Hai chỗ này dùng mặc định của Apple HIG / Material, ghi rõ là mặc định, không phải kết quả tra.

**Quy tắc rút ra:**
`primary-action` (mỗi màn một nút chính) · `progressive-disclosure` (giấu tuỳ chọn khó tới khi cần) · `input-type-keyboard` / Mobile Keyboards (bàn phím đúng loại) · Input Labels (nhãn luôn hiện) · `error-placement` + Inline Validation (lỗi ngay dưới ô, báo sớm) · `touch-target-size` 44pt/48dp + `touch-spacing` 8 · `confirmation-dialogs` + `undo-support` (xác nhận trước việc không đảo được, hoàn tác cho việc đảo được) · `sheet-dismiss-confirm` (hỏi trước khi đóng sheet đang ghi dở) · `empty-states` (lời + hành động) · User Freedom (có Bỏ qua) · Submit Feedback / Success Feedback (báo đã lưu) · `destructive-emphasis` (nút xoá màu nguy hiểm, tách khỏi nút chính) · ListView.builder + itemExtent (danh sách dài) · Form + validate (Flutter).

**Ghi một khoản thường ngày, "cà phê 35k, ví MoMo"** (đếm chạm sau khi mở sheet; gõ 3, 5, k tính là 3 phím):
| | Trước | Sau |
|---|---|---|
| Khoản mới, ví đã đúng mặc định | 3 phím + danh mục + Lưu = **5** | 3 phím + danh mục + Lưu = **5**; nếu danh mục cũng đã đúng mặc định: **4** |
| Khoản mới, phải đổi ví sang MoMo | 3 phím + danh mục + mở chi tiết + hàng Ví + chọn MoMo + Lưu = **8** | 3 phím + danh mục + chip MoMo + Lưu = **6** |
| Lặp lại khoản quen (cà phê sáng, cơm trưa, gửi xe) | như khoản mới: **5–8** | chip "Ghi lại khoản quen" + Lưu = **2** |
Mục tiêu ≤3 chạm đạt cho khoản lặp lại. Với khoản mới, gõ số là bắt buộc. Phần còn lại ≤3 chạm: danh mục, ví (nếu cần) và Lưu. Đúng cách PO đếm "120k → Ăn ngoài → Lưu".

**Vấn đề và cách sửa (đã sửa thẳng trên mockup):**
1. *(nặng)* **Đổi ví mất 3 chạm** vì ví nằm trong phần chi tiết bị giấu. → Hàng chip ví hiện luôn dưới danh mục (`Ví` / `Vào ví` / sổ chung khi mình trả: `Trừ vào ví của mình` + chip "Không trừ"). Công tắc trừ ví cũ bị bỏ vì hàng chip đã làm việc đó. (`add-tx.html`)
2. *(nặng)* **Mặc định chưa thông minh**: danh mục mặc định là khoản gần nhất, nên vừa ghi tiền nước thì khoản sau mặc định "Nước". → Danh mục = dùng nhiều nhất 14 ngày qua, hoà thì cái gần nhất (đề xuất cho PO, lệch D9). Ví = **ví dùng lần trước với chính danh mục đó** (cà phê → Tiền mặt, ăn ngoài → MoMo). Sổ, người trả và cách chia nhớ theo lần trước (D12). Đổi danh mục thì ví tự đổi theo.
3. *(nặng)* **Khoản lặp lại phải gõ lại từ đầu.** → Hàng "Ghi lại khoản quen": khoản gần nhất của 3 danh mục chi dùng nhiều nhất trong sổ. Chạm là điền đủ số, danh mục, ví, ghi chú; chỉ còn Lưu. Hàng này chỉ hiện khi ô số đang trống, gõ số thì hàng ẩn.
4. *(vừa)* **Mở Sổ tiền chưa trả lời ngay "còn bao nhiêu"**: số "còn" nằm trong câu chữ. Thêm nữa, "Còn lại (thu − chi)" 10.948.000 ₫ đứng cạnh "còn 1.448.000 ₫" nên hai chữ "còn" dễ nhầm. → Hàng đầu thẻ tháng có hai số: **Đã chi 9.552.000 ₫** (30) và **Còn trong ngân sách 1.448.000 ₫** (20, căn phải). Ô dưới đổi tên thành "Thu trừ chi". Câu finding đổi sang thứ chưa có trên màn: "… tức khoảng 131.000 ₫ mỗi ngày từ giờ tới cuối tháng". Chưa đặt ngân sách thì vị trí số "còn" hiện "Chưa đặt ngân sách · Đặt ›". (`money-own.html`, `money-shared.html`)
5. *(vừa)* **Thứ tự khối**: ghi xong người ta muốn thấy khoản vừa ghi. → "Gần đây" lên ngay dưới thẻ tháng (sổ chung: dưới ba làn). "Tiêu vào đâu" và "Ví" xuống dưới.
6. *(vừa)* **Thuật ngữ tài chính**: "Điều chỉnh số dư" → "Sửa số dư" (sheet "Sửa số dư cho khớp", giải thích "Trong app đang nhiều hơn tiền thật 23.000 ₫. App ghi 1 dòng “sửa số dư” để khớp…"). "Dư nợ" → "đang nợ thẻ". "Tổng tài sản" → "Tổng tiền đang có". "Số dư âm là bình thường" → "Đang nợ thẻ thì số dư âm, vậy là đúng". "Ứng" giữ (PO D12), nhưng thêm dòng đời thường dưới số: "Thảo trả lại mình chừng này là hai bên ngang nhau". "Trả từ Ví chung nên không ai phải trả lại ai."
7. *(vừa)* **Người mới (52 cặp đang chờ) xong màn chọn ví thì gặp sổ trống**, không biết làm gì. → Trạng thái mới `money-new.html`: thẻ "Ghi khoản đầu tiên" có 4 chip danh mục hay dùng, nút chính "Ghi khoản" và câu "Ghi vài hôm, mình sẽ thấy tiền đi đâu nhiều nhất và đặt ngân sách cho tháng sau". Không bắt đặt ngân sách ngay. Ẩn FAB để chỉ còn một nút chính.
8. *(vừa)* **Xoá / đóng ngang:** đã có hoàn tác 5 giây cho xoá. → Thêm: hoàn tác ngay sau khi Lưu (snackbar "Đã ghi … · Hoàn tác") · hỏi "Bỏ khoản đang ghi?" khi đóng sheet đang có số · xoá khoản có ở cả hai sổ thì hỏi trước ("Xoá ở cả hai sổ?" nút đỏ tách riêng + "Chỉ xoá ở sổ chung" + "Huỷ") vì nó đụng số dư ví riêng · thanh toán xong có hoàn tác. (`add-tx-states.html`, `settle.html`)
9. *(vừa)* **Vùng ngón cái**: nút Lưu trước nằm cuối nội dung, có máy phải cuộn mới thấy. → Lưu ghim đáy sheet. Chi/Thu/Chuyển lên hàng đầu thay tiêu đề "Ghi khoản" (tiêu đề còn cho trình đọc màn hình), lấy lại 52px cho bàn phím. Phím 48. FAB, Lưu, Góp vào quỹ, Đánh dấu đã thanh toán đều ở 1/3 dưới màn.
10. *(nhẹ)* **Vùng chạm**: chip h40 có vùng chạm 48 (`materialTapTargetSize.padded`); nút đổi sổ h40 có vùng chạm 48; segmented 6/12 tháng ở báo cáo 38 → 44.
11. *(nhẹ)* **Thanh toán (Lead chốt):** công tắc "Ghi tiền về ví của mình" (mặc định bật) + chip ví nhận (mặc định ví mình hay dùng cho khoản chung, mẫu Techcombank), "Thêm 1 dòng ở sổ của mình, không tính là thu nhập". Câu giải thích đổi thành "App không chuyển tiền giúp. Bấm nút dưới sau khi Thảo đã chuyển khoản hoặc đưa tiền mặt."

**Mỗi màn một mục tiêu**, soát lại sau sửa: tổng quan = xem tháng + ghi khoản (FAB) · sheet = ghi 1 khoản · ví = xem tiền đang có · ngân sách = biết nhóm nào sắp vượt · báo cáo = tiền đi đâu · tìm = thấy lại 1 khoản · quỹ = góp · thanh toán = đánh dấu đã trả. Màn đông nhất vẫn là sheet sổ chung. Ở đó "Ai trả / Chia thế nào / Ngày / Ghi chú" ở sau hàng tóm tắt (`progressive-disclosure`); mặc định nhớ lần trước nên đa số khoản không cần mở.

**Đánh đổi:**
- Không đạt ≤3 chạm cho khoản mới, vì không có cách nào bỏ được bước gõ số. Đoán số theo giờ trong ngày thì sai nhiều hơn đúng.
- Bỏ hộp xác nhận cho xoá khoản thường, chỉ dùng hoàn tác. Hộp xác nhận chỉ dùng cho việc đụng hai sổ hoặc không đảo được (lưu trữ ví, xoá danh mục tự thêm). UI UX Pro Max có cả `confirmation-dialogs` lẫn `undo-support`; xoá khoản thường đảo được nên chọn `undo-support`, đỡ một chạm cho việc làm hằng ngày.
- Hàng "Ghi lại khoản quen" và hàng ví làm sheet cao thêm khoảng 90px. Bù lại bằng cách đưa Chi/Thu/Chuyển lên hàng đầu, thu gọn khoảng cách và dùng phím 48. Sheet vẫn vừa 390×844, không phải cuộn.
- Chip cuối hàng cuộn ngang bị cắt ở mép phải: inspect báo WARN `edge-text`. Giữ có chủ đích để người dùng thấy hàng còn cuộn tiếp.
- "Ứng" vẫn còn (copy PO chốt), chỉ thêm câu giải thích. Muốn bỏ hẳn thì PO đổi D12.

**Gate sau vòng này:** lint `--app docs/design/expenses` 0 FAIL 0 WARN (32 file). Inspect 390, 24 trang, 0 FAIL. WARN còn lại: `colour-sprawl` (nền blush) và `edge-text` (chip cuộn ngang) ở `add-tx`, `settle`. `home-entry` chạy thêm `--allow icon-chips` vì đã dùng `IconBadge` theo Lead.

## 14. Câu hỏi cho PO / user
- ✅ [2026-10-20] Lead chốt: sheet Thanh toán có công tắc "Ghi tiền về ví của mình", mặc định bật (§15). Lối vào Home dùng `IconBadge`. Số chỉ căn phải (không thêm phông số).
- ❓ Mới: danh mục mặc định đổi từ "dùng gần nhất" (D9) sang "dùng nhiều nhất 14 ngày qua, hoà thì gần nhất" (§15, vấn đề 2). PO duyệt?

## Nhật ký design
- [2026-10-20] [Designer] Thiết kế mốc A Sổ tiền theo tasteskill (sheet chung đợt, face "ba làn Thảo · Ví chung · Mình") + UI UX Pro Max, bám design system hiện tại (dawnBlush, SubScreenHeader/EyebrowChip, ContentCard, nút navy, Quicksand). 23 trang mockup trong `docs/design/expenses/` (lối vào Home 9 trạng thái, tổng quan 2 sổ + 5 trạng thái, sheet ghi khoản bấm thử được + 14 trạng thái, ví/chi tiết/tạo/điều chỉnh, danh mục, ngân sách, báo cáo 2 sổ, tìm kiếm, quỹ, thanh toán, trạng thái màn phụ) dựng từ `data.js` có phép kiểm. Lint 0/0, inspect 390 0 FAIL mọi trang, 3 vòng critique (7.0 → 7.6 → 7.7). Đề xuất token tiền mới, widget `segmented_pill`, đổi emoji Gia đình. 3 câu hỏi cho PO.
- [2026-10-20] [Designer] Vòng soát dễ dùng theo UI UX Pro Max (§15): ghi khoản lặp lại 5–8 → 2 chạm (chip "Ghi lại khoản quen"), đổi ví 3 chạm → 1 (hàng chip ví), mặc định danh mục/ví thông minh hơn, thẻ tháng hiện cả "Đã chi" lẫn "Còn trong ngân sách", bỏ thuật ngữ khó, thêm trạng thái người mới `money-new.html`, hoàn tác sau Lưu + hỏi khi đóng sheet dở / xoá khoản hai sổ, Lưu ghim đáy. Áp quyết định Lead: IconBadge ở lối vào Home, công tắc "Ghi tiền về ví của mình" ở Thanh toán.
