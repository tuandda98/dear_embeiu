# Test case: Sổ tiền (expenses, mốc A)

> Tester sở hữu. Soạn 2026-10-23 trên `feature/daily-open-2` (HEAD `727a349`, đã gồm `b7e0e88`: tên danh mục và ví mặc định dịch lại khi đổi ngôn ngữ). Chỉ liệt kê và đối chiếu, không sửa code.
> Nguồn: `overview.md` (D1–D30, acceptance §6), `design.md`, `dev.md`, `test.md`, code `lib/screens/money/`, `lib/widgets/money/`, `lib/providers/money_provider.dart`, `lib/services/money_*.dart`, `lib/models/money.dart`, `lib/utils/money_*.dart`, khối money trong `functions/index.js` và `firestore.rules`.

> ⚠️ **[2026-10-25] D34 làm lỗi thời** các case về Thu, Thanh toán / cân bằng (BAL-*), chia tiền (SPL-* trừ SPL-10 mới), tab Chuyển (WAL-08), "Mỗi người góp", "Theo người" ở Báo cáo. Unit test tương ứng đã xoá; flow maestro dùng các màn này (vd thanh toán) cần viết lại. Case mới: `test/money_challenge_recap_test.dart` (thử thách + tổng kết tháng), `test/money_currency_test.dart`.

## Cách đọc

- Cột **Cách kiểm** là một trong bốn dạng (một case có thể ghép nhiều dạng, cách nhau bằng dấu chấm phẩy):
  - `unit: <file>::<tên test>`: đã có test phủ. Tên test đã grep thật trong file (gồm `test/money*_test.dart`, `firebase_rules_test/test/firestore.money.test.js` cho rules, `functions/test/index.test.js` cho Cloud Functions).
  - `maestro: maestro/expenses/<flow>.yaml`: có flow chạy trên máy ảo (xem `maestro/expenses/README.md`, thứ tự chạy và mã `RUN`).
  - `chưa phủ → đề xuất unit: …`: chưa có test; phần sau dấu hai chấm là test nên viết.
  - `thủ công: …`: máy ảo không làm được, kèm lý do.
- "Có test" nghĩa là đã có test chạm đúng hành vi đó. Chưa chạy lại toàn bộ bộ test trong lượt soạn này; con số pass lấy từ `test.md` (analyze 0 · 119 test Dart money · 99 test functions · rules 513).
- Các flow Maestro soạn từ code và ARB, **chưa chạy lần nào** (hai máy ảo đang được dùng việc khác). Lần chạy đầu có thể phải chỉnh selector.

## Dữ liệu và môi trường giả định

- Backend Firebase DEV, appId `com.tony.dearembeiu.dev`, app tiếng Việt.
- Android emulator `emulator-5554`: `test3@gmail.com` (Tuấn, đã có ví Cash và vài khoản chi). iOS simulator `23B763A6-DF45-4E75-9112-F9636CCB983B`: `test4@gmail.com` (Thảo, sổ riêng còn trống). Hai người đã ghép đôi.
- `test1` / `test2` là couple đang chờ (case mục 18). Seed lại bằng `node scripts/dev-seed-widget-accounts.js`.
- Quy ước tính (D7): chi/thu tháng chỉ tính `expense`/`income`; `transfer`, `adjust`, `contribution`, `settle` chỉ đổi số dư. Chia đôi làm tròn lên cho người trả. Cân bằng cộng dồn từ đầu.

## Lỗi đã biết (từ `test.md` 2026-10-22) và case liên quan

| Mức | Lỗi | Case |
|---|---|---|
| High, đã vá `2b4d289` | Home gọi aggregate số dư ~1 vòng/giây không dừng | AGG-01 đến AGG-07 |
| Med | 2 máy cùng "Trả hết" từ số cache → 2 khoản settle, cân bằng lật dấu | BAL-15 |
| Med, đã chặn ở `updateTx` | Người tạo đổi "Ai trả" khoản có linkId → trừ 2 lần | ED-11 |
| Med | Thiếu event `money_tx_edit`, `money_tx_delete`, `money_wallet_add`, `money_goal_add`; `money_report_open.view` | AN-02 đến AN-04 |
| Low | Bỏ ngân sách → Hoàn tác mất `alerted` | ED-18 |
| Low | Dải "{tên} đã đổi khoản chung" hiện cả khi chính mình đổi | ED-16 |
| Low | Nửa liên kết vẫn hiện 5 giây chờ xoá | ED-17 |
| Low | Quỹ "Quy Nhơn" → "Lên lịch đi Nhơn thôi" | GOAL-05 |
| Nghi ngờ, PO quyết | Parser `1tr2500` → 1.250.000 | AM-06 (nên thêm 1 dòng chốt hành vi) |

## Kết quả đợt viết test lấp khoảng trống (2026-10-24)

Thêm 5 file Dart (`test/money_gap_*_test.dart`, 122 test chạy + 2 test `skip` giữ bug) và `functions/test/money_gap.test.js` (3 test). Chạy: `flutter test test/money_gap*` và `cd functions && npm test`. Không sửa `lib/`, rules, hay `functions/index.js`.

1. **Vòng lặp aggregate** (AGG-01..05, MON-04/05, OFF-09): đã phủ ở `money_gap_provider_test.dart` bằng service giả đếm số lần đọc tổng và đồng hồ giả (không thay `refreshDay()` bằng no-op). Kiểm chứng: đặt lại `refreshDay()` về bản trước `2b4d289` (bản sao ngoài repo) thì 4 test AGG-01/AGG-03 đỏ; bản hiện tại xanh. Có cả test dựng thẻ Home thật (`MoneyHomeEntry`) chạy 10 giây: 0 lần đọc.
2. **Đổi ngôn ngữ, commit `b7e0e88`** (CAT-10..13, WAL-10..15, I18N-06): đã phủ ở `money_gap_unit_test.dart` (cache theo identity của `AppL10n.strings`, ví tên lạ giữ nguyên, tên lưu không bị ghi đè, `withName` giữ đủ trường).
3. **Hai máy bấm cùng lúc** (BAL-15, ED-08): phần provider/sheet đã phủ; khe hai người bấm cùng giây vẫn là thủ công.
4. **Analytics** (AN-01..07): bắt payload qua `AnalyticsService` giả (extension gọi `logEvent` nên fake bắt được). AN-04 và AN-07 chỉ phủ một phần (xem ghi chú ở từng dòng).
5. **First-run, ghi lỗi, hộp thoại** (FR-*, TX-13/15, ED-13): widget test ở `money_gap_screens_test.dart` và `money_gap_sheet_test.dart`.
6. **Không phủ được bằng unit/widget test**, còn lại: DW-02 (cần flow Maestro của decision-wheel), OFF-06 và hai máy thật của BAL-15/ED-08 (cần 2 người), HM-09, HM-12, các case cần máy thật hoặc thông báo thật; chọn ngày bằng date picker (TX-08), việc dọn hộp Hive khi đăng xuất (BK-10), lọc `_pair` thật (LV-01) cần Firestore thật.

### Bug lộ ra khi viết test (giữ test ở dạng `skip`)

| Mức | Bug | Test | Chỗ trong code |
|---|---|---|---|
| Med | Sửa ví có số dư đầu 0 (vd MoMo vừa tạo bỏ trống số dư, hay Tiền mặt mới): ô số dư được điền sẵn "0", `parseVndInput` coi 0 là lỗi nên nút Lưu bị khoá mà không báo gì. Phải xoá trắng ô số dư mới lưu được (đổi tên, bật/tắt "Tính vào tổng") | `money_gap_pages_test.dart::BUG (Med) WAL-12 …` (đã sửa 2026-10-24, test chạy xanh) | `money_wallets_screen.dart` `_initialAmount` / `canSave` |
| Low | Chia tiền "Tuỳ": nhập hoặc bước tới 0 thì ô bị coi là không hợp lệ, nên "Bớt 10%" nhảy từ 0 lên 120.000 (nửa số tiền trừ 10%), và gõ "0" thì app tính như chia đôi | `money_gap_sheet_test.dart::BUG (Low) SPL-04 …` (đã sửa 2026-10-24, test chạy xanh) | `add_transaction_sheet.dart` `_customRow.step`, `_payerShare` |

Đã sửa trong code từ lần soạn trước, test mới xác nhận: ED-16 (`MoneyMath.linkedDrift` bỏ qua khoản chính mình sửa), GOAL-05 (`moneyTripName("Quy Nhơn")` giữ nguyên), BAL-15 (settle đọc lại số từ server), AN-02..04 (đủ event).

### 1. Lần đầu mở (first-run, ví khởi đầu)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| FR-01 | Lần đầu mở | Sổ riêng chưa có ví nào (server xác nhận) | Mở Sổ tiền, tab Của mình | Hiện màn "Tiền của mình đang nằm ở đâu?" với 5 ví (Tiền mặt có sẵn và khoá, Ngân hàng, MoMo, ZaloPay, Thẻ tín dụng); không có nút Ghi khoản | maestro: maestro/expenses/30_own_expense_ios.yaml (một lần duy nhất, chỉ khi sổ Thảo còn trống); unit: test/money_gap_screens_test.dart::FR-01: five wallets, Cash locked on, no "Ghi khoản" button |
| FR-02 | Lần đầu mở | Màn lần đầu | Bật MoMo, nhập 1tr5, bấm "Xong, vào sổ" | Có ví Tiền mặt + MoMo 1.500.000; Tổng tiền đang có 1.500.000 ₫ | unit: test/money_gap_provider_test.dart::FR-02: the starter balance goes on cash; extra wallets keep theirs and get pinned to the book; unit: test/money_gap_screens_test.dart::FR-02: MoMo 1tr5 → starter 0 + MoMo 1.500.000; the total follows |
| FR-03 | Lần đầu mở | Màn lần đầu | Bật Thẻ tín dụng, nhập nợ 2.458.000 | Số dư lưu −2.458.000 (nợ), không phải +2.458.000 | unit: test/money_ui_test.dart::credit card owed 2.458.000 is stored negative |
| FR-04 | Lần đầu mở | Màn lần đầu | Bấm "Bỏ qua" | Chỉ có ví Tiền mặt số dư 0; vào thẳng sổ | maestro: maestro/expenses/30_own_expense_ios.yaml; unit: test/money_gap_provider_test.dart::FR-04 / BK-07: skipping makes only the cash wallet, id `cash`, balance 0; unit: test/money_gap_screens_test.dart::FR-04: "Bỏ qua" → only the starter, balance 0, no extras |
| FR-05 | Lần đầu mở | Màn lần đầu, ví đã bật | Gõ "abc" vào ô số dư | Nút "Xong, vào sổ" khoá; ô báo "Chưa hiểu số này" | unit: test/money_gap_screens_test.dart::FR-05: "abc" → "Chưa hiểu số này", Xong is locked |
| FR-06 | Lần đầu mở | Màn lần đầu | Gõ số dư 101 tỷ | Báo "Tối đa 100 tỷ một ví."; nút khoá | unit: test/money_test.dart::wallet balances allow up to 100 tỷ; unit: test/money_gap_screens_test.dart::FR-06: 101 tỷ → "Tối đa 100 tỷ một ví.", Xong is locked |
| FR-07 | Lần đầu mở | Hai máy cùng một tài khoản mở lần đầu cùng lúc | Cả hai bấm "Bỏ qua" | Ví `cash` chỉ có 1 (lần ghi thứ hai bị rules từ chối vì createdAt bất biến và được nuốt, không hiện lỗi) | unit: test/money_gap_provider_test.dart::FR-07: a second phone racing (permission-denied) is swallowed |
| FR-08 | Lần đầu mở | Cặp đã ghép, tab Chung lần đầu | Mở tab Chung | Tự tạo ví "Ví chung" với id `joint_<uid8>_<uid8>`; chỉ tạo 1 lần | unit: test/money_gap_provider_test.dart::FR-08 / BK-07 / LV-07: shared starter is `joint_<8>_<8>`, made once; a new pair gets a new id |
| FR-09 | Lần đầu mở | Mở Sổ tiền khi mất mạng, cache ví rỗng | Mở Sổ tiền | KHÔNG nhảy sang màn lần đầu (chỉ nhảy khi danh sách ví rỗng do server xác nhận); hiện đang tải | unit: test/money_gap_provider_test.dart::FR-09: an empty wallet list from the cache is NOT first run |
| FR-10 | Lần đầu mở | Sổ riêng có ví nhưng chưa từng ghi khoản | Mở tab Của mình | Thẻ "Ghi khoản đầu tiên" + 4 chip (Cà phê, Ăn ngoài, Xăng xe, Đi chợ) + nút Ghi khoản; không có nút tròn hồng | unit: test/money_ui_test.dart::newcomer card only when the own book never had an entry |
| FR-11 | Lần đầu mở | Như FR-10, cặp đã ghép | Nhìn thẻ Sổ tiền ở Home | Tiêu đề "Sổ tiền", dòng phụ "Gõ 50k, chọn danh mục là xong" | unit: test/money_ui_test.dart::states |
| FR-12 | Lần đầu mở | Thẻ "Ghi khoản đầu tiên" | Chạm chip "Cà phê, trà sữa" | Mở form với danh mục đã chọn sẵn | unit: test/money_gap_sheet_test.dart::FR-12: a first-entry chip opens the form with that category picked |
| FR-13 | Lần đầu mở | Máy chạy local-only (Firebase chưa sẵn sàng) | Mở Home | Không có thẻ Sổ tiền (MoneyHomeEntry trả SizedBox khi money.own == null) | unit: test/money_gap_screens_test.dart::FR-13: local-only phone (no books) → no row at all |

### 2. Sổ "Của mình" và sổ "Chung"

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| BK-01 | Hai sổ | Cặp đã ghép, tab Chung | Từ Home bấm thẻ Sổ tiền | Vào MoneyScreen, huy hiệu SỔ TIỀN, có 2 tab Của mình / Chung; mở sẵn ở sổ Chung | maestro: maestro/expenses/01_open_menu_android.yaml |
| BK-02 | Hai sổ | Cặp đã ghép | Chuyển tab Của mình ↔ Chung | Mỗi sổ có ví, danh mục, ngân sách riêng; số liệu không lẫn | unit: test/money_test.dart::add / rename / hide per book; old entries keep the name |
| BK-03 | Hai sổ | Form Ghi khoản đang mở, cặp đã ghép | Bấm nút "Đổi sổ, đang ở …" ở góc form | Danh mục, ví, chip "Ghi lại khoản quen" đặt lại theo sổ mới | unit: test/money_gap_sheet_test.dart::BK-03: switching book resets wallets, categories and the quick row |
| BK-04 | Hai sổ | Cặp đã ghép, tab Chung | Xem đầu tab | "Chúng mình đã chi", 3 làn "Ai trả tháng này" (người ấy · Ví chung · mình) + ai ứng nhiều hơn | unit: test/money_ui_test.dart::shared overview: three lanes + who covered more; maestro: maestro/expenses/01_open_menu_android.yaml |
| BK-05 | Hai sổ | Tuấn (test3), sổ Của mình | Xem tab | Thẻ tháng "Đã chi", Gần đây, Tiêu vào đâu, Ví | unit: test/money_ui_test.dart::own overview: month card, recent, where, wallets; maestro: maestro/expenses/01_open_menu_android.yaml |
| BK-06 | Hai sổ | Cặp đã ghép, tab Chung, có khoản trả từ Ví chung | Xem làn Ví chung | Ví chung = tiền vào − tiền ra; 3 làn cộng đúng tổng tháng | unit: test/money_test.dart::three lanes add up to the month; shared wallet = in − out |
| BK-07 | Hai sổ | Sổ mới | Xem id ví mặc định | Sổ riêng = `cash`, sổ chung = `joint_…` theo cặp | unit: test/money_gap_provider_test.dart::FR-04 / BK-07: skipping makes only the cash wallet, id `cash`, balance 0; unit: test/money_gap_provider_test.dart::FR-08 / BK-07 / LV-07: shared starter is `joint_<8>_<8>`, made once; a new pair gets a new id |
| BK-08 | Hai sổ | Cặp đã ghép | Hồ sơ → dòng "Ví, chi tiêu và quỹ chung" | Mở Sổ tiền | unit: test/money_gap_unit_test.dart::BK-08: the Profile tile opens Sổ tiền (and logs the entry point); một phần: chỉ kiểm mã nguồn (tile gọi openMoneyScreen from profile), chưa có widget test ProfileScreen (màn nặng, cần nhiều provider) |
| BK-09 | Hai sổ | Đăng xuất rồi đăng nhập lại cùng tài khoản | Vào Sổ tiền | Sổ riêng còn nguyên (dữ liệu gắn tài khoản, không gắn couple) | thủ công: đăng xuất/đăng nhập trên máy ảo làm mất phiên đang dùng của người khác |
| BK-10 | Hai sổ | Đang đăng nhập | Đăng xuất | clear(signedOut) xoá cache tổng ở Hive; lần đăng nhập tài khoản khác không thấy số cũ | unit: test/money_gap_provider_test.dart::BK-10: clear(signedOut) forgets both books and the uid; một phần: kiểm clear(signedOut) bỏ sổ + uid; việc xoá hộp Hive `money_cache` chưa kiểm (Hive thật dưới đồng hồ giả bị treo) |

### 3. Nhập số và hiển thị tiền

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| AM-01 | Nhập số | Form Ghi khoản | Gõ 50k | Hiểu là 50.000 | unit: test/money_test.dart::parseVndInput; maestro: maestro/expenses/02_amount_keypad_android.yaml |
| AM-02 | Nhập số | Form | Gõ 1tr2 (và 2tr05) | 1.200.000 (và 2.050.000); echo "Bạn gõ “1tr2”" | unit: test/money_test.dart::parseVndInput; maestro: maestro/expenses/02_amount_keypad_android.yaml |
| AM-03 | Nhập số | Form | Gõ "1 củ", "1 Củ", "1 tỏi" | 1.000.000, 1.000.000, 1.000.000.000 | unit: test/money_test.dart::parseVndInput |
| AM-04 | Nhập số | Form | Gõ 1.5tr, 1,5tr, 1.500k, 1.200tr | 1.500.000, 1.500.000, 1.500.000, 1.200.000.000 (ba chữ số sau dấu chấm là hàng nghìn, 1-2 chữ số là thập phân) | unit: test/money_test.dart::parseVndInput; maestro: maestro/expenses/02_amount_keypad_android.yaml (1,5tr) |
| AM-05 | Nhập số | Form | Gõ 120000, 120.000, 1.200.000, 1,200,000, "120.000 ₫", "  120k " | Đều đọc đúng, bỏ khoảng trắng và đuôi ₫ | unit: test/money_test.dart::parseVndInput |
| AM-06 | Nhập số | Form | Gõ abc, 12x, 1.2.3tr, 1,5 (không đơn vị), k50, 1tr2tr, 1.5000tr, 1.5tr2 | Báo "Chưa hiểu số này. Thử 120k hoặc 120000.", khoá Lưu | unit: test/money_test.dart::empty / invalid / zero lock Save, each with its own reason |
| AM-07 | Nhập số | Form mới mở | Chưa gõ gì | Gợi ý "Gõ 50k, 1tr2 hay 1 củ đều được"; nút "Nhập số tiền để lưu" khoá | unit: test/money_ui_test.dart::hints: empty; maestro: maestro/expenses/02_amount_keypad_android.yaml |
| AM-08 | Nhập số | Form | Gõ 0 hoặc 0k | Khoá Lưu, không hiện lỗi đỏ | unit: test/money_test.dart::empty / invalid / zero lock Save, each with its own reason |
| AM-09 | Nhập số | Form | Gõ 10.000.000.000 rồi 10.000.000.001 | 10 tỷ được lưu; 10 tỷ + 1 báo "Tối đa 10 tỷ một khoản. Kiểm tra lại số 0 nhé.", nút "Sửa số tiền để lưu" | unit: test/money_test.dart::over 10 tỷ is tooBig (not "invalid") and keeps the value; unit: test/money_ui_test.dart::hints; maestro: maestro/expenses/02_amount_keypad_android.yaml |
| AM-10 | Nhập số | Form | Gõ số có 400 chữ số kèm đơn vị k | Báo quá 10 tỷ, không văng exception (dùng BigInt) | unit: test/money_test.dart::a huge number with a unit says tooBig instead of throwing |
| AM-11 | Nhập số | Bàn phím số của app | Chạm nghìn/triệu/củ khi ô trống, sau dấu phẩy, hoặc khi đã có đơn vị | Bị bỏ qua: đơn vị chỉ nhận ngay sau chữ số và chỉ một lần | unit: test/money_ui_test.dart::keys build "1tr2" = 1.200.000, one unit right after a digit; maestro: maestro/expenses/02_amount_keypad_android.yaml |
| AM-12 | Nhập số | Ô trống | Chạm 0, 000 | Bị bỏ qua (không có số 0 đứng đầu) | unit: test/money_ui_test.dart::leading zeros are ignored, chips add up, a digit starts over |
| AM-13 | Nhập số | Ô đã có số | Chạm dấu phẩy 2 lần, hoặc sau đơn vị | Chỉ nhận 1 dấu phẩy, không nhận sau đơn vị | unit: test/money_gap_unit_test.dart::AM-13: a comma is accepted once and never after a unit |
| AM-14 | Nhập số | Đã gõ 1tr2 | Chạm "Xoá một ký tự" 3 lần | 1tr2 → 1tr → 1 → trống (đơn vị bị xoá nguyên khối) | unit: test/money_ui_test.dart::keys build "1tr2" = 1.200.000, one unit right after a digit; maestro: maestro/expenses/02_amount_keypad_android.yaml |
| AM-15 | Nhập số | Ô đã có 16 ký tự | Chạm thêm số | Không nhận thêm (tối đa 16 ký tự) | unit: test/money_gap_unit_test.dart::AM-15: at most 16 characters |
| AM-16 | Nhập số | Form | Chạm chip 50k rồi 100k; sau đó chạm số 7 | 150.000; chạm số thì bắt đầu lại từ "7" | unit: test/money_ui_test.dart::50k then 100k adds up to 150.000; unit: test/money_ui_test.dart::leading zeros are ignored, chips add up, a digit starts over |
| AM-17 | Nhập số | Form | Gõ 120000 (không đơn vị) | KHÔNG hiện dòng "Bạn gõ …" | unit: test/money_ui_test.dart::hints: empty; maestro: maestro/expenses/02_amount_keypad_android.yaml |
| AM-18 | Nhập số | Ví gần 100 tỷ | Ghi khoản làm số dư vượt 100 tỷ | Báo "Số dư ví sẽ vượt 100 tỷ", khoá Lưu | unit: test/money_test.dart::wallet cap ±100 tỷ |
| AM-19 | Nhập số | App vi / en | Xem một số tiền | vi: 1.250.000 ₫; en: ₫1,250,000; âm dùng dấu − (U+2212): −320.000 ₫ | unit: test/money_test.dart::vi / en / negative |
| AM-20 | Nhập số | Chip, trục biểu đồ | Xem dạng gọn | 50k, 1,2tr, 3,5 tỷ (vi) / 50K, 1.2M, 3.5B (en); 999.950 → 1tr chứ không "1000k" | unit: test/money_test.dart::short form |
| AM-21 | Nhập số | Sheet Thanh toán | Mở sheet | Ô số tiền hiện có dấu chấm nghìn ("170.000"), không phải "170000" (ghi chú Lead 22/10) | unit: test/money_stage3b_test.dart::Trả hết: Thảo pays 359.000 back into my wallet |
| AM-22 | Nhập số | Ô số của ví / ngân sách (MoneyNumberField) | Gõ 5tr | Cùng parser: 5.000.000; lỗi hiện dưới ô | maestro: maestro/expenses/09_budget_android.yaml (gõ 5000000); unit: test/money_gap_pages_test.dart::AM-22: MoneyNumberField reads 5tr as 5.000.000 and shows the error under the field |

### 4. Ghi Chi / Thu / Chuyển

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| TX-01 | Chi/Thu/Chuyển | Tuấn (test3), sổ Của mình | Ghi khoản → 5, 0, nghìn → (ghi chú) → Lưu 50.000 | Sheet đóng; snackbar "Đã ghi 50.000 ₫ · <danh mục>"; dòng mới ở Gần đây có "âm 50.000 đồng"; ví bị trừ | maestro: maestro/expenses/03_expense_own_android.yaml; unit: test/money_test.dart::balances for all 4 entry types |
| TX-02 | Chi/Thu/Chuyển | Tuấn (test3), sổ Của mình | Mở form, gõ số, chọn danh mục, Lưu | Không quá 3 chạm sau khi nhập số | unit: test/money_ui_test.dart::"Ghi lại khoản quen": chip + Lưu = 2 taps |
| TX-03 | Chi/Thu/Chuyển | Sổ có lịch sử 14 ngày | Mở form mới | Danh mục mặc định = dùng nhiều nhất 14 ngày (hoà → gần nhất); ví = ví dùng gần nhất với danh mục đó | unit: test/money_ui_test.dart::defaults: most used category in 14 days + its last wallet; unit: test/money_test.dart::category = most used over 14 days, tie → most recent; unit: test/money_test.dart::wallet = the one last used with that category |
| TX-04 | Chi/Thu/Chuyển | Tuấn (test3), sổ Của mình | Tab Thu → 2 triệu → Lương → Lưu | Dòng có dấu "+2.000.000 đồng"; tính vào "Thu" của tháng; ví cộng | maestro: maestro/expenses/05_income_own_android.yaml; unit: test/money_test.dart::balances for all 4 entry types |
| TX-05 | Chi/Thu/Chuyển | Có ≥ 2 ví | Tab Chuyển → Từ ví A → Sang ví B → 10k → Lưu | A trừ, B cộng; dòng "A → B"; chi/thu tháng không đổi | maestro: maestro/expenses/08_transfer_android.yaml; unit: test/money_test.dart::transfers / adjustments never count as spending or income |
| TX-06 | Chi/Thu/Chuyển | Tab Chuyển | Chọn ví đích trùng ví nguồn | UI không cho chọn (ví đích bỏ ví nguồn); ghi thẳng bị rules từ chối | unit: firebase_rules_test/test/firestore.money.test.js::transfer into the same wallet is refused |
| TX-07 | Chi/Thu/Chuyển | Một ví | Sửa số dư cho khớp tiền thật | Sinh 1 dòng điều chỉnh bằng chênh lệch, KHÔNG tính chi hay thu; "Đã khớp" thì không cần sửa | maestro: maestro/expenses/07_wallet_create_android.yaml; unit: test/money_test.dart::transfers / adjustments never count as spending or income; unit: firebase_rules_test/test/firestore.money.test.js::adjust touching both wallets is refused |
| TX-08 | Chi/Thu/Chuyển | Form | Đổi ngày sang tháng trước rồi Lưu | Khoản nằm đúng tháng đó, tháng này không đổi | maestro không chọn được date picker ổn định; unit: test/money_gap_unit_test.dart::ED-19 / TX-08: moving an entry to another month moves the totals; một phần: phần cộng tháng đã kiểm; chọn ngày bằng date picker chưa phủ (thủ công) |
| TX-09 | Chi/Thu/Chuyển | Form | Ghi chú 200 ký tự rồi 201 | 200 lưu được; 201 bị rules từ chối | unit: firebase_rules_test/test/firestore.money.test.js::note 201 chars, bad date, long ids are refused |
| TX-10 | Chi/Thu/Chuyển | Form | Lưu khoản không ghi chú | Dòng lấy tên danh mục làm tiêu đề | unit: test/money_gap_screens_test.dart::TX-10: no note → the category name is the title |
| TX-11 | Chi/Thu/Chuyển | Ví thường (không phải thẻ) | Chi nhiều hơn số dư | Ví âm; hiện cảnh báo nhẹ "Số dư âm, có khoản nào ghi nhầm ví không?" | unit: test/money_gap_pages_test.dart::TX-11: a normal wallet below 0 warns; a credit card does not |
| TX-12 | Chi/Thu/Chuyển | Ví Thẻ tín dụng | Chi 1tr | Nợ tăng, số dư âm là bình thường; Tổng tiền đang có giảm | unit: test/money_test.dart::total excludes goals, switched-off and archived wallets; credit lowers it |
| TX-13 | Chi/Thu/Chuyển | Form | Bấm Lưu 2 lần liên tiếp | Chỉ 1 khoản (nút bận khi đang lưu) | unit: test/money_gap_sheet_test.dart::TX-13: pressing Lưu twice writes ONE entry |
| TX-14 | Chi/Thu/Chuyển | Có ví đã lưu trữ | Mở form | Ví lưu trữ không có trong chip chọn ví | unit: test/money_gap_sheet_test.dart::TX-14: an archived wallet is not offered |
| TX-15 | Chi/Thu/Chuyển | Rules từ chối ghi (vd giả mạo) | Lưu | Snackbar "Chưa lưu được khoản này. Thử lại nhé."; form giữ nguyên số đã gõ | unit: test/money_gap_provider_test.dart::TX-15: a refused write throws and is rolled back from the balances; unit: test/money_gap_provider_test.dart::TX-15: an accepted write moves the balance at once, then the server sum takes over; unit: test/money_gap_sheet_test.dart::TX-15: a refused write → snackbar, the form stays with the typed amount, Lưu usable again |
| TX-16 | Chi/Thu/Chuyển | Tuấn (test3), sổ Của mình có ngân sách Ăn uống 2tr | Ghi khoản đẩy lên 80% rồi 100% | Toast "… đã dùng 80% ngân sách tháng" rồi "… đã vượt ngân sách …" (sổ riêng không push) | unit: test/money_gap_sheet_test.dart::TX-16: an entry that takes a group to 80 % says so, then 100 % says "đã vượt"; unit: test/money_gap_sheet_test.dart::TX-16: crossing 100 % |
| TX-17 | Chi/Thu/Chuyển | Màn 360dp | Mở form và các màn ngân sách/báo cáo/tìm | Không tràn, nút Lưu ghim dưới đáy | unit: test/money_stage3a_test.dart::360dp: the three screens fit |
| TX-18 | Chi/Thu/Chuyển | Form đã gõ số | Bấm Đóng | Hỏi "Bỏ khoản đang ghi?": Tiếp tục ghi giữ nguyên, Bỏ khoản này đóng form | maestro: maestro/expenses/02_amount_keypad_android.yaml |
| TX-19 | Chi/Thu/Chuyển | Form đã gõ số, Android | Bấm Back hệ thống | Cũng hỏi "Bỏ khoản đang ghi?" (PopScope) | unit: test/money_gap_sheet_test.dart::TX-19: Android Back with an amount typed asks first; "Tiếp tục ghi" keeps it, "Bỏ khoản này" closes; unit: test/money_gap_sheet_test.dart::TX-19: Back on an empty form just closes |
| TX-20 | Chi/Thu/Chuyển | Cặp đã ghép, tab Chung, có ví | Tab Chuyển ở sổ chung | Khoản chuyển trả bằng ví (payer = ví chung) | unit: test/money_ui_test.dart::shared transfer is paid by the wallet |
| TX-21 | Chi/Thu/Chuyển | Cặp đã ghép, tab Chung | Tab Thu ở sổ chung → chọn ví nhận | Thu vào ví chung, chưa có hàng "Ai trả" | unit: test/money_gap_sheet_test.dart::TX-21: income in the shared book has no "Ai trả"; it lands in a shared wallet |
| TX-22 | Chi/Thu/Chuyển | Quỹ (ví Mục tiêu) có tiền | Mở "Chi từ quỹ" | Form chi có sẵn chip quỹ; chi từ quỹ vào chi tháng, không đổi cân bằng | unit: test/money_test.dart::acceptance §6 scenario, step by step; unit: test/money_gap_sheet_test.dart::TX-22 / SPL-07: "Chi từ quỹ" — the fund pays, no one owes anyone |
| TX-23 | Chi/Thu/Chuyển | Sau khi Lưu | Xem dòng mới ở sổ chung | Có avatar người trả, "<tên> trả · chia đôi" | maestro: maestro/expenses/20_shared_add_android.yaml; unit: test/money_ui_test.dart::shared overview: three lanes + who covered more |

### 5. Danh mục (mặc định, tự thêm, đổi tên, dịch lại)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| CAT-01 | Danh mục | App vi và en | Mở lưới danh mục | Đủ 12 nhóm chi + con và 6 nhóm thu, có tên cả vi và en | unit: test/money_test.dart::12 expense groups + children and 6 income groups, all named |
| CAT-02 | Danh mục | Tuấn (test3), sổ Của mình | Danh mục → Thêm danh mục → tên → Lưu | Danh mục tự thêm hiện trong danh sách, chọn được khi ghi khoản | maestro: maestro/expenses/12_categories_android.yaml; unit: test/money_test.dart::add / rename / hide per book; old entries keep the name |
| CAT-03 | Danh mục | Tuấn (test3), sổ Của mình | Đổi tên "Cà phê, trà sữa" thành "Trà sữa" | Chỉ đổi ở sổ này; hiện "Đã đổi tên, gốc là …"; khoản cũ đọc tên mới | unit: test/money_test.dart::add / rename / hide per book; old entries keep the name |
| CAT-04 | Danh mục | Tuấn (test3), sổ Của mình | Ẩn nhóm Học tập | Không còn trong lưới chọn khi ghi; khoản cũ vẫn hiện đúng tên | unit: test/money_test.dart::add / rename / hide per book; old entries keep the name |
| CAT-05 | Danh mục | Có danh mục ẩn | Mục "Đã ẩn" → Hiện lại | Danh mục trở lại lưới chọn | unit: test/money_gap_pages_test.dart::CAT-05: a hidden category comes back with "Hiện lại" |
| CAT-06 | Danh mục | Có danh mục tự thêm và khoản dùng nó | Xoá danh mục (nhấn giữ → Xoá danh mục → Xoá) | Danh mục biến mất; khoản cũ rơi về "Khác" | maestro: maestro/expenses/12_categories_android.yaml; unit: test/money_gap_unit_test.dart::CAT-13 / CAT-06: an unknown or deleted id shows "Khác" / "Thu khác" |
| CAT-07 | Danh mục | Đã 80 danh mục tự thêm | Thêm cái thứ 81 | Báo "Sổ này đã đủ 80 danh mục tự thêm."; rules cũng chặn > 80 và > 120 danh mục ẩn | unit: firebase_rules_test/test/firestore.money.test.js::meta: only doc `main`, ≤80 custom categories, ≤120 hidden; unit: test/money_gap_pages_test.dart::CAT-07: the 81st custom category is refused with a note |
| CAT-08 | Danh mục | Form → Tất cả | Gõ "trà sữa" vào ô tìm danh mục | Lọc đúng; không khớp thì "Không có danh mục nào khớp." | unit: test/money_gap_sheet_test.dart::CAT-08: the picker finds "trà sữa" typed without accents; no match says so |
| CAT-09 | Danh mục | Đang tiếng Việt, mở app | Đổi sang English rồi về Tiếng Việt, mở form Ghi khoản | Tên danh mục dịch lại theo ngôn ngữ đang chọn, không còn tên tiếng Anh sót lại (commit b7e0e88: bảng danh mục cache theo ngôn ngữ) | maestro: maestro/expenses/13_language_switch_android.yaml |
| CAT-10 | Danh mục | MoneyBookState đã dựng bảng danh mục khi AppL10n còn tiếng Anh | AppL10n.setLocale(vi) rồi đọc `categories` | Bảng được dựng lại (khoá theo identity của AppL10n.strings), tên tiếng Việt; meta đổi cũng dựng lại | unit: test/money_gap_unit_test.dart::CAT-10 / I18N-06: a table built while AppL10n was English is rebuilt in Vietnamese after setLocale(vi); unit: test/money_gap_unit_test.dart::CAT-10: same language + same meta = the cached index; new meta rebuilds it |
| CAT-11 | Danh mục | Có danh mục tự thêm "Cầu lông" | Đổi ngôn ngữ | Tên người dùng tự gõ KHÔNG bị dịch | unit: test/money_gap_unit_test.dart::CAT-11: a category the user typed is never translated |
| CAT-12 | Danh mục | Có danh mục mặc định đã đổi tên (override) | Đổi ngôn ngữ | Giữ tên người dùng đặt, không bị dịch đè | unit: test/money_gap_unit_test.dart::CAT-12: a renamed default keeps the user's name in both languages; the original follows the language |
| CAT-13 | Danh mục | Khoản mang categoryId không tồn tại | Xem dòng khoản | Hiện "Khác" | unit: test/money_gap_unit_test.dart::CAT-13 / CAT-06: an unknown or deleted id shows "Khác" / "Thu khác" |
| CAT-14 | Danh mục | Cây 2 cấp | Ngân sách/báo cáo gom khoản mục con vào nhóm cấp 1 | Cộng theo groupOf đúng, tổng bằng tổng tháng | unit: test/money_test.dart::by category (level 1 via groupOf) adds up to the month |
| CAT-15 | Danh mục | Danh mục tự thêm trong sổ chung | Thêm ở tab Chung | Chỉ có ở sổ chung, sổ riêng không thấy | unit: test/money_test.dart::add / rename / hide per book; old entries keep the name |

### 6. Ví (tạo, sửa, lưu trữ, dịch tên ví mặc định)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| WAL-01 | Ví | Tuấn (test3), sổ Của mình | Ví → Thêm ví → tên "MTW" → số dư → Tạo ví | Snackbar "Đã tạo MTW"; ví hiện ở "Đang dùng" | maestro: maestro/expenses/07_wallet_create_android.yaml; unit: firebase_rules_test/test/firestore.money.test.js::wallet name 31 chars, bad type, currency USD are refused |
| WAL-02 | Ví | Form tạo ví | Chọn Thẻ tín dụng, nợ 2.000.000 | Lưu −2.000.000; số dư ngoài [−10 tỷ, 100 tỷ] bị từ chối | unit: firebase_rules_test/test/firestore.money.test.js::credit card may open at −2.000.000; out of range opening is refused |
| WAL-03 | Ví | Có Mục tiêu, ví tắt "tính vào tổng", ví lưu trữ, thẻ nợ | Xem "Tổng tiền đang có" | Không cộng Mục tiêu, ví tắt, ví lưu trữ; thẻ nợ làm tổng giảm | unit: test/money_test.dart::total excludes goals, switched-off and archived wallets; credit lowers it |
| WAL-04 | Ví | Ví có số dư | Mở ví → Sửa số dư → nhập số thật | Lời giải thích đúng chiều (nhiều hơn/ít hơn) hoặc "Đã khớp"; Cập nhật ghi 1 dòng điều chỉnh; snackbar "Đã sửa số dư …" | maestro: maestro/expenses/07_wallet_create_android.yaml; unit: test/money_gap_pages_test.dart::WAL-04: "Sửa số dư" explains more / less / same and writes one adjust line |
| WAL-05 | Ví | Ví có khoản trong tháng | Mở chi tiết ví | "Số dư hiện tại", Vào/Ra tháng, danh sách khoản của ví; tháng trống "Tháng này ví chưa có khoản nào." | maestro: maestro/expenses/07_wallet_create_android.yaml; unit: test/money_gap_pages_test.dart::WAL-05: balance, in/out of the month, the wallet's entries; unit: test/money_gap_pages_test.dart::WAL-05: a wallet with nothing this month says so |
| WAL-06 | Ví | Ví không phải Tiền mặt | Sửa ví → Lưu trữ ví → xác nhận | Ví thôi hiện khi ghi khoản; lịch sử giữ; "Dùng lại ví này" đưa về | unit: firebase_rules_test/test/firestore.money.test.js::wallets are archived, never deleted; type is immutable; unit: test/money_gap_pages_test.dart::WAL-06: archive asks first, then writes archived:true; the default wallet cannot be archived; unit: test/money_gap_pages_test.dart::WAL-06: an archived wallet offers "Dùng lại ví này" with no question; unit: test/money_gap_pages_test.dart::WAL-06: no archive button for the starter wallet |
| WAL-07 | Ví | Ví cũ | Cố xoá ví / đổi loại ví | Rules từ chối cả hai (ví chỉ lưu trữ, loại bất biến) | unit: firebase_rules_test/test/firestore.money.test.js::wallets are archived, never deleted; type is immutable |
| WAL-08 | Ví | Chi tiết ví | Bấm "Chuyển tiền" | Form Chuyển mở với ví nguồn là ví đang xem | unit: test/money_gap_pages_test.dart::WAL-08: "Chuyển tiền" opens a transfer from THIS wallet |
| WAL-09 | Ví | Ví mặc định chưa đổi tên (Cash / Ví chung / Ngân hàng / Thẻ tín dụng), tạo lúc máy tiếng Anh | Đổi sang Tiếng Việt, mở form ghi, danh sách ví, chi tiết ví | Hiện Tiền mặt / Ví chung / Ngân hàng / Thẻ tín dụng; đổi lại English thì Cash / Shared wallet / Bank / Credit card (commit b7e0e88) | maestro: maestro/expenses/13_language_switch_android.yaml |
| WAL-10 | Ví | Ví đã đổi tên ("Techcombank", "Cash của Tuấn") | Đổi ngôn ngữ | Giữ nguyên tên người dùng đặt (hàm `current(name)` chỉ khớp đúng tên tiếng Anh/Việt gốc) | unit: test/money_gap_unit_test.dart::WAL-10: wallets the user named keep their name in every language |
| WAL-11 | Ví | Ví dịch từ "Cash" | Đổi ngôn ngữ rồi mở Firestore xem doc ví | Tên LƯU vẫn là "Cash"; chỉ hiển thị dịch (không ghi đè dữ liệu) | unit: test/money_gap_unit_test.dart::WAL-11: a starter wallet shows translated but the stored list is untouched |
| WAL-12 | Ví | Ví hiển thị "Tiền mặt" (gốc "Cash") | Sửa ví → đổi tên thành "Ví của Tuấn" → Lưu | Tên mới được lưu thật; từ đó không bị dịch nữa | unit: test/money_gap_pages_test.dart::WAL-12: a wallet shown as "Tiền mặt" (stored "Cash") saves the new name once the balance box is empty; unit: test/money_gap_pages_test.dart::BUG (Med) WAL-12: editing a wallet whose opening balance is 0 — the box is pre-filled with "0", which parseVndInput rejects as zero, so Lưu is locked with no message until the user empties the box (money_wallets_screen.dart _initialAmount / canSave) (đã sửa, xanh); unit: test/money_gap_unit_test.dart::WAL-12: the stored name is only changed by an edit; once the user saves a new name it is no longer translated |
| WAL-13 | Ví | Người dùng tự đặt tên ví thật là "Ngân hàng" hoặc "Cash" | Đổi ngôn ngữ | Hiện theo ngôn ngữ hiện tại (chấp nhận được, ghi nhận hành vi) | unit: test/money_gap_unit_test.dart::WAL-13: a name that equals a starter name is shown in the current language (accepted behaviour) |
| WAL-14 | Ví | MoneyWallet.withName | Gọi withName("X") | Mọi trường khác giữ nguyên (goalTarget, goalDeadline, memberUids, createdAt…) | unit: test/money_gap_unit_test.dart::WAL-14: withName keeps every other field |
| WAL-15 | Ví | Getter `wallets` | Đọc 2 lần cùng ngôn ngữ; gán `wallets = …`; đổi ngôn ngữ | Cùng ngôn ngữ trả cùng list (cache); gán mới hoặc đổi ngôn ngữ thì dựng lại | unit: test/money_gap_unit_test.dart::WAL-15: same language → same cached list; assigning or switching language rebuilds |
| WAL-16 | Ví | Mở app | Xem số dư ví ngay | Hiện số cache Hive ngay, số mới từ aggregate sau; ghi cục bộ chỉnh số cache | unit: test/money_test.dart::local writes correct a cached aggregate (review #2) |
| WAL-17 | Ví | Ví sổ chung | Tạo ví chung tên 31 ký tự / thiếu khoá chung | Bị từ chối | unit: firebase_rules_test/test/firestore.money.test.js::shared wallet: shared keys required, 31-char name refused |
| WAL-18 | Ví | Sổ riêng | Tạo ví có khoá của sổ chung | Bị từ chối | unit: firebase_rules_test/test/firestore.money.test.js::own wallets refuse shared keys |
| WAL-19 | Ví | Ví có mục tiêu sai | Tạo mục tiêu 0 đồng / 101 tỷ / gắn field mục tiêu vào ví thường | Bị từ chối (mục tiêu 1 đến 100 tỷ, chỉ ví loại Mục tiêu) | unit: firebase_rules_test/test/firestore.money.test.js::goal fields only on a goal wallet, target 1..100 tỷ |

### 7. Quỹ / mục tiêu / góp

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| GOAL-01 | Quỹ | Mục tiêu có hạn | Tạo mục tiêu 5tr hạn 3 tháng | Dòng "Cần ~X mỗi tháng" đúng; chưa hạn thì nhắc "Thêm hạn để biết…" | unit: test/money_test.dart::goal progress + per month needed (Quỹ Đà Lạt); unit: test/money_stage3b_test.dart::40% · còn 3.000.000 · ~1.000.000 a month for 3 months |
| GOAL-02 | Quỹ | Quỹ 2tr/5tr | Mở màn quỹ | 40%, làn "Thảo \| Mình", dòng cần mỗi tháng | unit: test/money_stage3b_test.dart::screen: 40%, lanes Thảo \| Mình, per-month line |
| GOAL-03 | Quỹ | Quỹ đã đủ | Mở màn quỹ | "Đủ rồi. Lên lịch đi Đà Lạt thôi…"; không còn số mỗi tháng; vượt 100% vẫn đúng | unit: test/money_stage3b_test.dart::screen at 100%: "Đủ rồi. Lên lịch đi Đà Lạt thôi…"; unit: test/money_stage3b_test.dart::full at 100% (and past it): nothing left, nothing a month |
| GOAL-04 | Quỹ | Quỹ không hạn | Mở màn quỹ | Không có số mỗi tháng; tên chuyến bỏ chữ "Quỹ" | unit: test/money_stage3b_test.dart::no deadline → no per-month number; trip name drops "Quỹ" |
| GOAL-05 | Quỹ | Quỹ tên "Quy Nhơn" | Đạt 100% | Câu hiện "Lên lịch đi Nhơn thôi" (cắt nhầm chữ "Quỹ"); phải là "Quy Nhơn" (Low, Tester 22/10) | unit: test/money_gap_unit_test.dart::GOAL-05: "Quy Nhơn" is a place, not "Quỹ Nhơn"; the Quỹ / Fund prefix still goes |
| GOAL-06 | Quỹ | Quỹ + ví cá nhân | Góp vào quỹ 500k lấy từ ví của mình | Ví mình −500k, quỹ +500k, cả hai sổ có khoản liên kết | unit: test/money_stage3b_test.dart::Góp vào quỹ: my 500k into the fund, out of my wallet |
| GOAL-07 | Quỹ | Quỹ có lịch sử | Xem "Lịch sử góp" | Gộp dòng từ server và cửa sổ live, mới nhất trước, bỏ khoản đang chờ xoá | unit: test/money_stage3b_test.dart::history: server rows + live window, newest first, minus undo |
| GOAL-08 | Quỹ | Ví mục tiêu riêng | Tự ghi goalReachedAt | Cho phép ở sổ riêng | unit: firebase_rules_test/test/firestore.money.test.js::own goal wallet may record goalReachedAt itself |
| GOAL-09 | Quỹ | Quỹ chung | Client ghi goalReachedAt / xoá ví chung | Rules từ chối; dấu do CF đóng vẫn còn sau các lần sửa khác | unit: firebase_rules_test/test/firestore.money.test.js::shared wallets: no delete, no client goalReachedAt; unit: firebase_rules_test/test/firestore.money.test.js::a CF-stamped goalReachedAt survives other edits |
| GOAL-10 | Quỹ | Cặp, quỹ 5tr | Một người góp rồi quỹ đạt 100% | Người kia nhận push "vừa góp, giờ được N%" (không có số tiền); đạt 100% cả hai nhận đúng 1 lần | unit: functions/test/index.test.js::money: a contribution pushes the other one the fund %, never the amount; unit: functions/test/index.test.js::money: reaching 100 % tells both, exactly once |
| GOAL-11 | Quỹ | Chuyển ví/điều chỉnh làm đầy quỹ | Ghi khoản chuyển vào quỹ | Báo "đủ rồi" 1 lần; chỉ khoản góp mới có push "vừa góp" | unit: functions/test/index.test.js::money: a transfer or adjustment that fills a goal tells both once |
| GOAL-12 | Quỹ | Push money_goal* | Chạm push | Mở Home + màn Sổ tiền + màn quỹ tương ứng | unit: test/money_stage3b_test.dart::push route: Home + money focus (+ the fund for money_goal*) |
| GOAL-13 | Quỹ | Mục tiêu hạn đã qua | Mở màn quỹ | Không hiện số âm hay vô cực ở "mỗi tháng" | unit: test/money_gap_unit_test.dart::GOAL-13: a deadline in the past never gives a negative or huge "mỗi tháng" |
| GOAL-14 | Quỹ | Màn quỹ | Dùng đọc màn hình | Thanh tiến độ và làn người góp có nhãn đọc được ("… góp …, còn thiếu …") | unit: test/money_gap_pages_test.dart::GOAL-14: the fund bar and the two lanes read as sentences |

### 8. "Ghi lại khoản quen"

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| QR-01 | Khoản quen | Có ≥ 3 danh mục chi | Mở form Chi, ô số trống | Hàng "Ghi lại khoản quen" = khoản mới nhất của 3 danh mục chi dùng nhiều nhất | unit: test/money_test.dart::quick repeats = latest of the 3 most used expense categories |
| QR-02 | Khoản quen | Hàng chip hiện | Chạm chip rồi Lưu | 2 chạm xong, số/danh mục/ví điền sẵn | unit: test/money_ui_test.dart::"Ghi lại khoản quen": chip + Lưu = 2 taps; maestro: maestro/expenses/06_quick_repeat_android.yaml |
| QR-03 | Khoản quen | Form | Gõ 1 chữ số, hoặc đổi sang tab Thu, hoặc mở form Sửa | Hàng chip ẩn | unit: test/money_gap_sheet_test.dart::QR-03: hidden after a digit, on the Thu tab, and when editing; unit: test/money_gap_sheet_test.dart::QR-03: not on the edit form |
| QR-04 | Khoản quen | Khoản có ghi chú "Bún chả" | Xem nhãn chip | "Bún chả · 50k"; không ghi chú thì "<tên danh mục> · 50k" | maestro: maestro/expenses/06_quick_repeat_android.yaml; unit: test/money_gap_sheet_test.dart::QR-04: chip = "<note> · 120k", or "<category> · 50k" without a note |
| QR-05 | Khoản quen | Sổ chưa có khoản nào | Mở form | Không có hàng chip | unit: test/money_gap_sheet_test.dart::QR-05: a book with no entries has no "khoản quen" row |

### 9. Sửa, xoá, khoản liên kết

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| ED-01 | Sửa/xoá | Tuấn (test3), sổ Của mình | Chạm dòng → Sửa khoản → đổi 50k thành 70k → Lưu | Snackbar "Đã lưu thay đổi"; dòng đọc 70.000; ví tính lại | maestro: maestro/expenses/04_edit_delete_own_android.yaml |
| ED-02 | Sửa/xoá | Tuấn (test3), sổ Của mình | Xoá khoản → Hoàn tác trong 5 giây | Dòng quay lại; không có lệnh xoá nào lên Firestore | unit: test/money_ui_test.dart::delete waits 5 s and Hoàn tác brings the entry back; maestro: maestro/expenses/04_edit_delete_own_android.yaml |
| ED-03 | Sửa/xoá | Đã bấm Xoá, chưa hết 5 giây | Rời couple hoặc đăng xuất | Lệnh xoá gửi đi ngay: rời couple chỉ khoản chung, đăng xuất thì tất cả | unit: test/money_test.dart::flushPendingDeletes sends the undo-window deletes of that book now |
| ED-04 | Sửa/xoá | Không có MoneyProvider sống | Gọi flushPendingDeletes | Không làm gì, không ném lỗi | unit: test/money_test.dart::no live provider: nothing to flush, never throws |
| ED-05 | Sửa/xoá | Sổ riêng của Tuấn | Người khác sửa/xoá khoản; chủ xoá khoản | Người khác bị từ chối; chủ xoá được | unit: firebase_rules_test/test/firestore.money.test.js::nobody else can write into my book; unit: firebase_rules_test/test/firestore.money.test.js::the owner deletes an entry |
| ED-06 | Sửa/xoá | Khoản có sẵn | Sửa với editCount nhảy cóc, đổi type/createdAt/linkId, giả updatedBy | Rules từ chối; hợp lệ khi editCount + 1, updatedAt = giờ server | unit: firebase_rules_test/test/firestore.money.test.js::edit: author + server time + editCount + 1; type / createdAt / linkId pinned; unit: firebase_rules_test/test/firestore.money.test.js::both members edit any entry; a forged updatedBy or a skipped editCount is refused |
| ED-07 | Sửa/xoá | Tạo khoản | Giả createdAt, createdBy, editCount | Rules từ chối | unit: firebase_rules_test/test/firestore.money.test.js::create with a forged createdAt / createdBy / editCount is refused |
| ED-08 | Sửa/xoá | Cặp đã ghép, tab Chung, cùng một khoản | Hai máy mở sửa cùng lúc rồi cùng Lưu | Bản thứ hai bị rules từ chối; app báo "Chưa lưu được: <tên> vừa sửa khoản này" và hiện bản mới nhất | unit: firebase_rules_test/test/firestore.money.test.js::two edits from the same starting point: the second is refused; thủ công: cần 2 người bấm Lưu cùng lúc, Maestro không đồng bộ được 2 máy; unit: test/money_gap_provider_test.dart::ED-08: the edit writes editCount as old+1 (absolute), so the second of two edits from one version is refused by the rules; unit: test/money_gap_sheet_test.dart::ED-08: the 2nd of two edits (permission-denied) closes with "Thảo vừa sửa khoản này"; một phần: unit editCount tuyệt đối + thông báo xung đột trong sheet; việc từ chối là của rules (đã có rules-test), hai máy thật vẫn là thủ công |
| ED-09 | Sửa/xoá | Cặp đã ghép, tab Chung | Người này sửa/xoá khoản do người kia tạo (không liên kết) | Được phép; dòng hiện "<tên> sửa hh:mm" ở máy người tạo | unit: firebase_rules_test/test/firestore.money.test.js::both members edit any entry; a forged updatedBy or a skipped editCount is refused; unit: test/money_gap_screens_test.dart::ED-09: an entry the partner edited says "Thảo sửa hh:mm" |
| ED-10 | Sửa/xoá | Khoản chung có linkId do người ấy tạo | Mở sửa | Ô số tiền và nút Xoá khoá, dòng "Chỉ Thảo sửa được số tiền, vì khoản này nằm trong sổ riêng của Thảo"; vẫn sửa được ghi chú, danh mục, ngày | unit: test/money_ui_test.dart::linked entry made by the partner: amount + delete locked; unit: firebase_rules_test/test/firestore.money.test.js::a linked entry: the partner edits note/category/date but not the money; unit: firebase_rules_test/test/firestore.money.test.js::a linked entry is deleted only by its creator; plain ones by either member |
| ED-11 | Sửa/xoá | Khoản chung liên kết do mình tạo | Mở sửa | "Ai trả" khoá + dòng giải thích; updateTx từ chối đổi người trả/ví (Med, Tester 22/10, đã chặn) | unit: test/money_ui_test.dart::my linked shared entry: "Ai trả" locked, with a line; unit: test/money_ui_test.dart::updateTx refuses a new payer / wallet on a linked entry |
| ED-12 | Sửa/xoá | Khoản chung không liên kết | Mở sửa | "Ai trả" vẫn mở | unit: test/money_ui_test.dart::a shared entry without a link: "Ai trả" stays open |
| ED-13 | Sửa/xoá | Khoản chung liên kết do mình tạo | Đổi số tiền rồi Lưu | Hỏi "Sửa luôn bên sổ của mình?" → Sửa cả hai / Chỉ sổ chung; cả hai ghi trong 1 batch | unit: test/money_gap_sheet_test.dart::ED-13: changing the amount of a linked shared entry asks "Sửa luôn bên sổ của mình?" — both / shared only; unit: test/money_gap_sheet_test.dart::ED-13: no question when the amount did not change |
| ED-14 | Sửa/xoá | Khoản chung liên kết do mình tạo | Xoá | Hỏi "Xoá ở cả hai sổ?"; xoá cả hai thì ví được cộng lại | unit: test/money_ui_test.dart::deleting both halves hides the own half and gives its money back |
| ED-15 | Sửa/xoá | Người ấy đổi số tiền khoản chung có linkId của mình | Mở sổ riêng | Khoản riêng hiện dải "<tên> đã đổi khoản chung thành X · Cập nhật"; chạm Cập nhật mới đồng bộ | unit: test/money_test.dart::a linked own entry drifts when the shared amount changed; unit: test/money_test.dart::a linked half is only one I wrote (review #7) |
| ED-16 | Sửa/xoá | Như ED-15 nhưng chính mình đổi | Mở sổ chung | Không hiện dải "<tên> đã đổi…" (đang hiện cả khi mình tự đổi — Low, Tester 22/10) | unit: test/money_test.dart::a linked own entry drifts when the shared amount changed; unit: test/money_gap_screens_test.dart::ED-09: an entry the partner edited says "Thảo sửa hh:mm" |
| ED-17 | Sửa/xoá | Khoản có nửa liên kết | Xoá khoản chung rồi nhìn sổ riêng trong 5 giây chờ | Nửa liên kết ẩn cùng lúc (đang vẫn hiện 5 giây — Low) | unit: test/money_ui_test.dart::deleting both halves hides the own half and gives its money back |
| ED-18 | Sửa/xoá | Ngân sách có alerted | Bỏ ngân sách → Hoàn tác | Ngân sách quay lại với `alerted` cũ, không bắn push 80%/100% lặp | unit: test/money_ui_test.dart::"Bỏ ngân sách" → Hoàn tác keeps the same budget (alerted) |
| ED-19 | Sửa/xoá | Khoản tháng 9 | Sửa ngày sang tháng 10 | Tổng tháng 9 giảm, tháng 10 tăng; aggregate cache tháng 9 làm lại | unit: test/money_gap_unit_test.dart::ED-19 / TX-08: moving an entry to another month moves the totals; một phần: tổng tháng đổi đã kiểm; việc làm lại aggregate cache tháng 9 sau updateTx chưa phủ |
| ED-20 | Sửa/xoá | Tuấn (test3), sổ Của mình | Xoá khoản rồi nhìn số dư ví | Ví được cộng lại ngay (chỉnh cục bộ, trước khi aggregate trả) | unit: test/money_test.dart::local writes correct a cached aggregate (review #2) |

### 10. Chia tiền sổ chung

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| SPL-01 | Chia tiền | Cặp đã ghép, tab Chung | Tuấn trả 1tr, Chia đôi | Phần người trả chịu = làm tròn lên (75.001 → 37.501); người kia chịu nửa còn lại | unit: test/money_test.dart::payerShare for the 4 splits (odd amounts round up for the payer); maestro: maestro/expenses/20_shared_add_android.yaml |
| SPL-02 | Chia tiền | Cặp đã ghép, tab Chung | Trả 200k, "Mình mời" (treat) | Người trả chịu hết, không ai nợ ai; nhãn đổi theo người trả ("<tên> mời") | unit: test/money_test.dart::payerShare for the 4 splits (odd amounts round up for the payer); unit: test/money_stage3b_test.dart::parts add up to the balance; treats + the wallet left out |
| SPL-03 | Chia tiền | Cặp đã ghép, tab Chung | Thảo trả 70k, "Trả hộ" (forPartner) | Người kia chịu hết 70k; số lệch 70k | unit: test/money_test.dart::acceptance §6 scenario, step by step; maestro: maestro/expenses/31_shared_forpartner_ios.yaml; maestro: maestro/expenses/32_shared_forpartner_seen_android.yaml |
| SPL-04 | Chia tiền | Cặp đã ghép, tab Chung | Trả 300k, "Tuỳ", người trả chịu 100k | Người kia chịu 200k; mặc định ô = nửa số tiền; nút Bớt/Thêm 10% mỗi nấc, kẹp trong [0, số tiền] | unit: test/money_test.dart::payerShare for the 4 splits (odd amounts round up for the payer); unit: test/money_gap_sheet_test.dart::SPL-04: "Tuỳ" — starts at half, the stepper moves 10 % and stays in [0, amount]; unit: test/money_gap_sheet_test.dart::BUG (Low) SPL-04: "Bớt 10%" at 0 stays at 0 — today the field reads 0 as invalid (parseVndInput zero), so the stepper jumps 0 → half − 10% (add_transaction_sheet.dart _customRow.step / _payerShare) (đã sửa, xanh) |
| SPL-05 | Chia tiền | Cặp đã ghép, tab Chung | Giả payerShare âm / lớn hơn amount / splitMode lạ | Rules từ chối | unit: firebase_rules_test/test/firestore.money.test.js::payerShare negative or above amount is refused; bad splitMode too |
| SPL-06 | Chia tiền | Cặp đã ghép, tab Chung | Xem dòng "A chịu x · B chịu y" khi đổi số tiền / chưa nhập số | Cập nhật theo số; chưa có số: "Nhập số tiền để xem mỗi người chịu bao nhiêu" | unit: test/money_gap_sheet_test.dart::SPL-06: the share line follows the amount; before one it asks for it |
| SPL-07 | Chia tiền | Cặp đã ghép, tab Chung | Ai trả = Ví chung | Ẩn "Chia thế nào", hiện "Trả từ Ví chung nên không ai phải trả lại ai."; cần ví chung | unit: firebase_rules_test/test/firestore.money.test.js::payer is a member or the shared wallet (which needs outWalletId); unit: firebase_rules_test/test/firestore.money.test.js::a person paid ⇒ no shared wallet pays too (no double count); unit: test/money_gap_sheet_test.dart::TX-22 / SPL-07: "Chi từ quỹ" — the fund pays, no one owes anyone |
| SPL-08 | Chia tiền | Lần đầu / lần sau | Mở form sổ chung | Lần đầu mặc định Chia đôi; sau đó nhớ lựa chọn gần nhất trên máy | unit: test/money_gap_sheet_test.dart::SPL-08: first time "Chia đôi"; afterwards the last split and payer are remembered on this phone |
| SPL-09 | Chia tiền | Cặp đã ghép, tab Chung, mình có ví riêng | Ai trả = Mình, Chia đôi, giữ "Trừ vào ví của mình" | Ghi khoản chung + khoản riêng liên kết trừ ĐỦ số tiền (không chỉ phần mình), cùng linkId | unit: test/money_ui_test.dart::shared, I paid: deducts my own wallet, split in half |
| SPL-10 | Chia tiền | Cặp đã ghép, tab Chung | Ai trả = Mình | Hàng "Trừ vào ví của mình" không có chip "Không trừ" (bỏ 2026-10-25, D32); luôn chọn sẵn một ví riêng, lưu thì sinh cả khoản riêng | unit: test/money_gap_sheet_test.dart::SPL-10: with a wallet chosen the own half is written |
| SPL-11 | Chia tiền | Cặp đã ghép, tab Chung | Ai trả = người ấy | Không hiện hàng "Trừ vào ví của mình" (không ghi được vào sổ riêng người kia) | unit: test/money_gap_sheet_test.dart::SPL-11: the partner paid → no "Trừ vào ví của mình" row |
| SPL-12 | Chia tiền | Cặp đã ghép, tab Chung | Hai máy cùng nhìn khoản "chia đôi" | Cùng hiển thị tên người trả, cách chia, số tiền | maestro: maestro/expenses/21_shared_see_ios.yaml |

### 11. Cân bằng và thanh toán (settle)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| BAL-01 | Cân bằng | Bộ số tham chiếu | Tính cân bằng | 359.000 (mình ứng nhiều hơn) | unit: test/money_test.dart::balance of the reference book = 359.000 |
| BAL-02 | Cân bằng | Kịch bản acceptance §6 | Từng bước: 480k chia đôi → 240k; Thảo trả hộ 70k → 170k; mời 200k không đổi; tuỳ 300k; 75.001 chia đôi | Số lệch từng bước đúng | unit: test/money_test.dart::acceptance §6 scenario, step by step |
| BAL-03 | Cân bằng | Cặp đã ghép, tab Chung, có khoản trả từ Ví chung và khoản góp quỹ | Tính cân bằng | Không tạo nợ | unit: test/money_test.dart::acceptance §6 scenario, step by step |
| BAL-04 | Cân bằng | Cặp đã ghép, tab Chung | Nhìn dòng chữ cân bằng | "Mình đang ứng nhiều hơn" / "<tên> đang ứng nhiều hơn" / "Hai bên đang ngang nhau" + dòng phụ; không dùng chữ "nợ" | unit: test/money_ui_test.dart::shared overview: three lanes + who covered more; maestro: maestro/expenses/21_shared_see_ios.yaml; maestro: maestro/expenses/23_shared_settled_android.yaml |
| BAL-05 | Cân bằng | Cặp đã ghép, tab Chung | Nút "Thanh toán" | Hiện khi lệch; ẩn khi ngang nhau | unit: test/money_stage3b_test.dart::shared: "Thanh toán" while uneven, "Góp vào quỹ" link; unit: test/money_stage3b_test.dart::even → no "Thanh toán" |
| BAL-06 | Cân bằng | Thảo nợ 500k | Sheet Thanh toán → Trả hết | Ghi `settle`, cân bằng về 0; cộng tiền vào ví của mình (nếu bật "Ghi tiền về ví") | unit: test/money_stage3b_test.dart::Trả hết: Thảo pays 359.000 back into my wallet; maestro: maestro/expenses/22_shared_settle_ios.yaml |
| BAL-07 | Cân bằng | Nợ 359.000 | Chọn "Một nửa"; tắt "Ghi tiền về ví của mình" | 179.500; sổ riêng không đổi | unit: test/money_stage3b_test.dart::Một nửa → 179.500; switch off → nothing in my book |
| BAL-08 | Cân bằng | Sheet Thanh toán đang mở | Số cần trả đổi trên server | Sheet cập nhật theo, không ghi gì | unit: test/money_stage3b_test.dart::number changed on the server: sheet updates, no write |
| BAL-09 | Cân bằng | Sheet đang mở | Số đổi dấu / đã ngang / mất mạng rồi Lưu | Không ghi gì; báo "Sổ chung đã cân bằng rồi…" hoặc "Chưa lấy được số mới nhất…" | unit: test/money_stage3b_test.dart::the sign flipped / already even / offline: nothing written |
| BAL-10 | Cân bằng | Số cache cũ (stale) | Bấm nút (đang là "Tải số mới nhất") | Chỉ tải lại, không ghi | unit: test/money_stage3b_test.dart::cached sums (stale): Save only fetches, never writes |
| BAL-11 | Cân bằng | Nợ 359.000 | Gõ phần trả 100k; gõ nhiều hơn số nợ | 100k ghi được; nhiều hơn báo "Tối đa <số nợ>" | unit: test/money_stage3b_test.dart::a typed part 100k; more than owed is refused |
| BAL-12 | Cân bằng | Tên người lấy từ CoupleProvider (không có MoneyPeopleScope) | Bấm Đánh dấu đã thanh toán | Vẫn ghi (lỗi listen:true trong callback, vá 451f5f1) | unit: test/money_stage3b_test.dart::names from CoupleProvider (no scope): saving still writes |
| BAL-13 | Cân bằng | Sổ chung | Ghi settle sai dạng (có ví, payerShare ≠ 0) hoặc ở sổ riêng | Rules từ chối | unit: firebase_rules_test/test/firestore.money.test.js::settle: a person pays, no wallet, payerShare 0; unit: firebase_rules_test/test/firestore.money.test.js::settle is shared-book only |
| BAL-14 | Cân bằng | Sau khi Thảo thanh toán | Tuấn mở tab Chung | Cả hai máy thấy ngang nhau và dòng "Thanh toán … không tính vào chi"; chi tháng không đổi | maestro: maestro/expenses/22_shared_settle_ios.yaml; maestro: maestro/expenses/23_shared_settled_android.yaml |
| BAL-15 | Cân bằng | Hai máy cùng thấy nợ từ số cache | Cùng bấm "Trả hết" gần như một lúc | Chỉ 1 khoản settle; không lật dấu cân bằng (Med, Tester 22/10: hiện có thể ghi 2 khoản) | thủ công: cần hai người bấm cùng lúc; unit: test/money_gap_provider_test.dart::BAL-15: settle re-reads the SERVER number, not the cache; unit: test/money_gap_provider_test.dart::BAL-15: offline → null, so a settle never goes out on a cached number; unit: test/money_gap_provider_test.dart::BAL-15: a number still owed is returned as the new plan; một phần: provider luôn đọc lại số từ server trước khi ghi (settle sheet dùng refreshCoupleBalance); hai máy bấm cùng giây vẫn có khe, cần thử tay |
| BAL-16 | Cân bằng | Cặp ghi lâu năm (hàng nghìn khoản chung) | Mở tab Chung | Cân bằng vẫn ra nhanh (aggregate theo payer, không tải hết khoản) | thủ công: cần seed hàng nghìn khoản trên DEV và đo thời gian |
| BAL-17 | Cân bằng | Người mới ghép vào couple cũ | Xem cân bằng | Không lẫn khoản của cặp cũ (memberUids) | unit: firebase_rules_test/test/firestore.money.test.js::someone who joins later cannot read the old pair's money; the one who stayed can |

### 12. Ngân sách

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| BUD-01 | Ngân sách | Ngân sách Ăn uống 2tr | Chi tới 79%, 80%, 100% | Dưới 80 xám; 80 cảnh báo; ≥100 vượt; mốc báo 1 lần | unit: test/money_stage3a_test.dart::levels: under 80 grey, 80 warn, 100 over; unit: test/money_test.dart::80 / 100 % levels (Ăn uống 2tr) |
| BUD-02 | Ngân sách | Qua mốc 80% | Ghi thêm rồi sang tháng mới | Mốc đã báo không báo lại; tháng mới tính từ 0 | unit: test/money_test.dart::crossing a line is reported once, a new month starts at 0 |
| BUD-03 | Ngân sách | Sổ chung, ăn uống 97% | Mở Ngân sách | Pill 97% ở đầu, nhóm chưa đặt xếp cuối kèm nút Đặt, dòng ghi chú push | unit: test/money_stage3a_test.dart::screen: 97% pill, left of, unset groups, push note; unit: test/money_stage3a_test.dart::closest to the limit comes first |
| BUD-04 | Ngân sách | Vượt 103% | Mở Ngân sách | "Vượt 3%"; dưới 80% màu xám | unit: test/money_stage3a_test.dart::screen: over 100% says "Vượt 3%", under 80% is grey |
| BUD-05 | Ngân sách | Tuấn (test3), sổ Của mình | Ngân sách → Đặt ngân sách → Cả sổ 5.000.000 → Lưu ngân sách | Snackbar "Đã đặt ngân sách Cả sổ: 5.000.000 ₫"; số hiện trên màn | maestro: maestro/expenses/09_budget_android.yaml; unit: test/money_stage3a_test.dart::set from "Đặt", remove + undo |
| BUD-06 | Ngân sách | Đã có ngân sách | Bỏ ngân sách → Hoàn tác | Quay lại đúng ngân sách cũ | unit: test/money_stage3a_test.dart::set from "Đặt", remove + undo |
| BUD-07 | Ngân sách | Rules | Ngân sách 0, 10 tỷ + 1; tự ghi `alerted`; id không phải `total` hay mã danh mục | Từ chối; 1 đến 10 tỷ hợp lệ; `alerted` chỉ CF | unit: firebase_rules_test/test/firestore.money.test.js::budgets: 1..10 tỷ, no client `alerted`; unit: firebase_rules_test/test/firestore.money.test.js::budget id is fixed: `total` for the whole book, else the category id; unit: firebase_rules_test/test/firestore.money.test.js::own budget: `alerted` cannot be added later; default wallet id ≤40 |
| BUD-08 | Ngân sách | Cặp đã ghép, tab Chung | Hai người đọc/ghi ngân sách chung | Được; `alerted` chỉ CF ghi | unit: firebase_rules_test/test/firestore.money.test.js::budgets: members read/write, `alerted` is CF-only |
| BUD-09 | Ngân sách | Ngân sách tổng sổ chung 5tr | Chi qua 4tr rồi 5tr | Người KHÔNG ghi khoản nhận push 80% (chỉ phần trăm), rồi 100%, mỗi mốc 1 lần mỗi tháng, không gửi người ghi | unit: functions/test/index.test.js::money: budget 80 % then 100 %, once each per month, never to the one who logged it |
| BUD-10 | Ngân sách | Sang tháng mới | Ghi khoản | Đếm lại từ 0; ngân sách theo danh mục và tháng cũ không push | unit: functions/test/index.test.js::money: a new month starts over; old months and category budgets stay quiet |
| BUD-11 | Ngân sách | Doc ngân sách không ở id `total` | Ghi khoản chi | Không coi là ngân sách cả sổ | unit: functions/test/index.test.js::money: a budget not at the fixed id `total` is not the whole-book budget |
| BUD-12 | Ngân sách | Ngày cuối tháng | Nhận push ngân sách | Câu riêng cho ngày cuối, không "còn 0 ngày"; tháng và số ngày theo giờ Việt Nam | unit: functions/test/index.test.js::money: the last day of the month gets its own line, not "còn 0 ngày"; unit: functions/test/index.test.js::money: month / days left follow Vietnam time |
| BUD-13 | Ngân sách | Cặp đã ghép, tab Chung | Nhìn thẻ Sổ tiền ở Home | "Đã chi X · N% ngân sách"; vượt thì "vượt Y" màu đỏ; chưa có ngân sách thì "Đã chi X tháng này" | unit: test/money_ui_test.dart::normal row reads the shared month + budget %; unit: test/money_ui_test.dart::over budget shows "vượt …" |
| BUD-14 | Ngân sách | Ngân sách trống/0 | Mở sheet, chưa nhập số | Nút "Nhập số tiền để lưu" khoá | unit: test/money_gap_pages_test.dart::BUD-14: an empty / zero budget keeps the save button locked |
| BUD-15 | Ngân sách | Ngân sách đã đặt | Mở lại sheet | Số cũ điền sẵn (nên xoá trước khi gõ số mới) | maestro: maestro/expenses/09_budget_android.yaml |
| BUD-16 | Ngân sách | Tháng mới qua vài ngày | Xem nhận xét tháng | "Tháng mới qua X/Y ngày mà đã dùng Z% … mỗi ngày chỉ còn …" | unit: test/money_gap_screens_test.dart::BUD-16: early in the month, "mới qua X/Y ngày mà đã dùng Z%" |
| BUD-17 | Ngân sách | Push money_budget | Chạm push / mục inbox | Mở Home + màn Sổ tiền sổ chung; inbox đọc giống push | unit: test/money_stage3b_test.dart::push route: Home + money focus (+ the fund for money_goal*); unit: test/money_stage3b_test.dart::inbox: the 3 types parse, open Home (0) and read like the push |
| BUD-18 | Ngân sách | Tuấn (test3), sổ Của mình có ngân sách danh mục | Bỏ danh mục khỏi ngân sách / đổi tên danh mục | Ngân sách theo id danh mục, không mất | unit: test/money_gap_unit_test.dart::BUD-18: a budget follows the category id, not its name |

### 13. Báo cáo

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| REP-01 | Báo cáo | Dữ liệu mẫu tháng riêng | Mở Báo cáo | Chi 9.552.000, nhà 59% (phần lớn là tiền nhà) | unit: test/money_stage3a_test.dart::data.js own month: 9.552.000 spent, home 59% mostly rent |
| REP-02 | Báo cáo | Dữ liệu mẫu sổ chung | Mở Báo cáo tab Chung | Ăn 54%, ai trả, đóng góp ví chung và quỹ | unit: test/money_stage3a_test.dart::data.js shared: food 54%, who paid, contributions |
| REP-03 | Báo cáo | Sổ mới có từ tháng 10 | Xem xu hướng | Trục tháng đúng, tháng trước khi có sổ để trống kèm chú thích, dấu Tết | unit: test/money_stage3a_test.dart::trend axis, book start, Tết |
| REP-04 | Báo cáo | Tuấn (test3), sổ Của mình | Mở Báo cáo | Thu \| Chi \| Còn lại + nhận xét danh mục lớn nhất | unit: test/money_stage3a_test.dart::own screen: Thu \| Chi \| Còn lại + finding; maestro: maestro/expenses/10_report_android.yaml |
| REP-05 | Báo cáo | Cặp đã ghép, tab Chung | Mở Báo cáo tab Chung | Làn theo người, đóng góp, chú thích sổ mới | unit: test/money_stage3a_test.dart::shared screen: person lanes, contributions, new book |
| REP-06 | Báo cáo | Tuấn (test3), sổ Của mình | Chạm "12 tháng" rồi "6 tháng" | Biểu đồ đổi số cột | maestro: maestro/expenses/10_report_android.yaml |
| REP-07 | Báo cáo | Tháng chưa có khoản chi | Mở Báo cáo | "Tháng X chưa có khoản chi nào." | unit: test/money_gap_pages_test.dart::REP-07: a month with income only → "chưa có khoản chi nào" |
| REP-08 | Báo cáo | Đang giữa tháng | Xem cột tháng này | "Tháng X mới tính tới ngày …"; đường đứt là ngân sách tổng | unit: test/money_stage3a_test.dart::own Thu ¦ Chi ¦ Còn lại + finding |
| REP-09 | Báo cáo | Mất mạng, vài tháng chưa tải | Xem xu hướng | Cột thiếu để trống + "Chưa tải được vài tháng…" | unit: test/money_gap_pages_test.dart::REP-09: months that could not load stay empty with a note |
| REP-10 | Báo cáo | Chi theo danh mục | Chạm một nhóm | Mở cấp 2 (mục con) | unit: test/money_stage3a_test.dart::data.js own month: 9.552.000 spent, home 59% mostly rent; unit: test/money_gap_pages_test.dart::REP-10: tapping a closed group opens its sub-categories |
| REP-11 | Báo cáo | Biểu đồ | Đọc bằng TalkBack/VoiceOver | Nhãn "Chi mỗi tháng, N tháng gần đây: …" | unit: test/money_gap_pages_test.dart::REP-11: the chart reads as "Chi mỗi tháng, N tháng gần đây" |
| REP-12 | Báo cáo | Báo cáo mở từ link "Báo cáo" ở thẻ tháng | Chạm | Mở đúng tháng đang xem | unit: test/money_gap_pages_test.dart::REP-12: the "Báo cáo" link of the month card opens that month |

### 14. Tìm kiếm

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| SRCH-01 | Tìm kiếm | Có 3 khoản "Bún chả" | Gõ "bun cha" | Ra đúng 3 khoản, tổng 410.000 ₫, mới nhất trước | unit: test/money_stage3a_test.dart::"bun cha" finds 3 entries, 410.000 ₫, newest first; unit: test/money_test.dart::accents and case do not matter |
| SRCH-02 | Tìm kiếm | Chữ có dấu kết hợp | Tô sáng phần khớp | Vùng tô giữ nguyên dấu kết hợp | unit: test/money_stage3a_test.dart::match range ignores accents, keeps combining marks |
| SRCH-03 | Tìm kiếm | Mở Tìm khoản | Xem khoảng ngày | Mặc định 3 tháng tính từ ngày 1; tối đa 12 tháng | unit: test/money_stage3a_test.dart::ranges: 3 months from the 1st, 12 months |
| SRCH-04 | Tìm kiếm | Có khoản nhiều ví | Lọc ví, nhóm, khoảng tiền | Trả đúng tập | unit: test/money_stage3a_test.dart::filters: wallet, group + amount; unit: test/money_test.dart::category name, wallet and amount filters |
| SRCH-05 | Tìm kiếm | Hơn 2.000 khoản trong khoảng | Tìm | Cắt ở 2.000 dòng và báo "Chỉ tìm trong 2.000 khoản gần nhất…" | unit: test/money_stage3a_test.dart::2.000 rows fetched = capped; unit: test/money_stage3a_test.dart::screen: capped notice |
| SRCH-06 | Tìm kiếm | Khoản cũ hơn 3 tháng | Tìm trong 3 tháng (trống) rồi bấm "Tìm trong 12 tháng" | Lần đầu trống kèm gợi ý; lần hai ra khoản | unit: test/money_stage3a_test.dart::screen: highlight, empty → 12 months finds it |
| SRCH-07 | Tìm kiếm | Tuấn (test3), sổ Của mình | Gõ chữ HOA/thường lẫn lộn | Vẫn ra; hiện "1 khoản" | maestro: maestro/expenses/11_search_android.yaml |
| SRCH-08 | Tìm kiếm | Tuấn (test3), sổ Của mình | Gõ chuỗi không khớp | "Không có khoản nào khớp “…” trong N tháng gần đây." | maestro: maestro/expenses/11_search_android.yaml |
| SRCH-09 | Tìm kiếm | Chữ có đ, ơ, ư, ê… | Gõ không dấu | Mọi chữ có dấu đều gập về không dấu | unit: test/money_test.dart::every accented letter folds |
| SRCH-10 | Tìm kiếm | Cặp đã ghép, tab Chung | Chọn bộ lọc Người | Chỉ khoản do người đó trả | unit: test/money_gap_pages_test.dart::SRCH-10: the "Người" filter keeps only what that person paid |
| SRCH-11 | Tìm kiếm | Mất mạng khi tìm | Tìm | "Chưa tìm được. Kiểm tra mạng rồi thử lại." | unit: test/money_gap_pages_test.dart::SRCH-11: offline → one clear sentence, not a crash |
| SRCH-12 | Tìm kiếm | Sổ chung đang tìm | Tìm từ khoá nằm trong sổ riêng của người kia | Không ra (rules chặn đọc sổ riêng) | maestro: maestro/expenses/24_privacy_ios.yaml |

### 15. Tháng và mốc 0:00

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| MON-01 | Tháng | Tuấn (test3), sổ Của mình | Bấm ‹ rồi › | Nhãn "Tháng 9, 2026" rồi "Tháng 10, 2026"; › khoá ở tháng hiện tại | maestro: maestro/expenses/01_open_menu_android.yaml |
| MON-02 | Tháng | Khoảng tháng | Tính cửa sổ xu hướng | Các khoảng tháng và cửa sổ 6/12 tháng đúng | unit: test/money_test.dart::ranges and trend windows |
| MON-03 | Tháng | Tháng chưa có khoản | Mở tháng đó | "Tháng X chưa có khoản nào. Bấm nút hồng ở góc dưới…" | unit: test/money_gap_screens_test.dart::MON-03: a month without entries → the hint to the pink button |
| MON-04 | Tháng | Cửa sổ live | Đọc `_windowFrom` | ≥ 44 ngày lùi và không sau mùng 1 của tháng này | unit: test/money_gap_provider_test.dart::MON-04: live window starts ≥ 44 days back and never after the 1st of this month |
| MON-05 | Tháng | Qua 0:00 | Giữ app mở qua nửa đêm | Cửa sổ dời, tổng tính lại đúng 1 lần, thẻ Home và nhắc tối vẽ lại | unit: test/money_gap_provider_test.dart::AGG-03 / MON-05: past midnight the window moves, one re-read, then quiet |
| MON-06 | Tháng | Khoản ngày 1 và ngày cuối tháng | Xem tổng hai tháng | Mỗi khoản nằm đúng tháng của nó | unit: test/money_gap_unit_test.dart::MON-06: the 1st and the last day each land in their own month |
| MON-07 | Tháng | Cặp ở hai múi giờ | Hai người ghi quanh nửa đêm | Ngày theo máy người ghi (đã chốt, như câu hỏi hằng ngày) | thủ công: đổi múi giờ máy ảo ảnh hưởng người đang dùng chung máy, làm trên máy thật |

### 16. Offline và đồng bộ 2 máy

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| OFF-01 | Offline/2 máy | Cặp đã ghép, tab Chung | Mất mạng, ghi khoản chung 20k | Hiện ngay; dòng có "chờ mạng"; banner "Đang mất mạng… cộng thêm N khoản đang chờ gửi" | maestro: maestro/expenses/25_shared_offline_android.yaml |
| OFF-02 | Offline/2 máy | Như OFF-01 | Có mạng lại | Khoản lên server, dấu "chờ mạng" biến mất; máy kia thấy | maestro: maestro/expenses/25_shared_offline_android.yaml; maestro: maestro/expenses/26_shared_offline_seen_ios.yaml |
| OFF-03 | Offline/2 máy | Sổ riêng | Mất mạng, ghi khoản | Snackbar "Đang chờ mạng, có mạng sẽ tự gửi lên"; số dư ví chỉnh tạm | unit: test/money_test.dart::local writes correct a cached aggregate (review #2); unit: test/money_gap_sheet_test.dart::OFF-03: a write the server has not answered yet says it is waiting for the network (own book), and (shared book) too; unit: test/money_gap_sheet_test.dart::OFF-03: shared book wording |
| OFF-04 | Offline/2 máy | Lỗi tải | Mở Sổ tiền | Thẻ "Chưa tải được khoản mới. Số liệu đúng lúc …" + Thử lại; Home "Chưa tải được sổ chung" + Thử lại | unit: test/money_ui_test.dart::states; unit: test/money_gap_screens_test.dart::OFF-04: load error → card with "Thử lại" that retries |
| OFF-05 | Offline/2 máy | Cặp đã ghép, tab Chung | Home khi số liệu cũ | "X · số liệu lúc hh:mm" kèm icon mây gạch | unit: test/money_ui_test.dart::states |
| OFF-06 | Offline/2 máy | Hai máy | Cùng ghi hai khoản khác nhau cùng lúc | Hai doc riêng, không đè nhau | thủ công: cần hai người ghi cùng lúc, Maestro không đồng bộ được 2 máy |
| OFF-07 | Offline/2 máy | Hai máy | Máy A ghi khoản | Máy B thấy trong ~3 giây (không push) | maestro: maestro/expenses/20_shared_add_android.yaml; maestro: maestro/expenses/21_shared_see_ios.yaml |
| OFF-08 | Offline/2 máy | Mất mạng lâu (nhiều giờ) | Mở lại app | Hiện số cache Hive ngay; số mới khi có mạng; không văng | thủ công: cần giữ máy offline nhiều giờ |
| OFF-09 | Offline/2 máy | Sổ chung, sau khi có mạng | Số dư/cân bằng | Tính lại đúng 1 lần (không vòng lặp) | unit: test/money_gap_provider_test.dart::OFF-09: after the network is back the sums are re-read once, not in a loop |

### 17. Riêng tư và rules

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| PRIV-01 | Riêng tư/rules | Sổ riêng của A | B, người ngoài, khách đọc/liệt kê ví và khoản của A | Từ chối hết; chỉ chủ đọc/ghi | unit: firebase_rules_test/test/firestore.money.test.js::the owner creates and reads a wallet; partner, outsider, guest cannot read; unit: firebase_rules_test/test/firestore.money.test.js::partner cannot read or list my entries; unit: firebase_rules_test/test/firestore.money.test.js::nobody else can write into my book |
| PRIV-02 | Riêng tư/rules | Cặp đã ghép | Mở màn Sổ tiền của Thảo sau khi Tuấn ghi khoản riêng | Khoản riêng của Tuấn không hiện ở tab nào, tìm cũng không ra | maestro: maestro/expenses/24_privacy_ios.yaml |
| PRIV-03 | Riêng tư/rules | Sổ chung | memberUids sai thứ tự / 1 người / 3 người | Từ chối; phải đúng cặp, đúng thứ tự, đúng 2 người | unit: firebase_rules_test/test/firestore.money.test.js::memberUids must be the couple, in order, exactly 2 |
| PRIV-04 | Riêng tư/rules | Cặp còn chờ | Tạo doc sổ chung | Từ chối (không có sổ chung khi chưa active) | unit: firebase_rules_test/test/firestore.money.test.js::a waiting couple has no shared book |
| PRIV-05 | Riêng tư/rules | Cặp đã ghép, tab Chung | Hai thành viên tạo và đọc; truy vấn memberUids == | Được; người ngoài không | unit: firebase_rules_test/test/firestore.money.test.js::both members create + read; outsiders cannot; unit: firebase_rules_test/test/firestore.money.test.js::the pair query (memberUids ==) works for members |
| PRIV-06 | Riêng tư/rules | Cặp đã ghép, tab Chung | aggregate sum theo payer / theo ví | Chạy được cho cặp, không cho người ngoài | unit: firebase_rules_test/test/firestore.money.test.js::the balance sums (aggregate per payer / per wallet) work for the pair only |
| PRIV-07 | Riêng tư/rules | Người ấy rời, người mới ghép cùng coupleId | Người mới đọc khoản cũ | permission-denied; người ở lại vẫn đọc được | unit: firebase_rules_test/test/firestore.money.test.js::someone who joins later cannot read the old pair's money; the one who stayed can |
| PRIV-08 | Riêng tư/rules | Khách (chưa đăng ký) | Chạm hai sổ | Từ chối | unit: firebase_rules_test/test/firestore.money.test.js::guests cannot touch either book |
| PRIV-09 | Riêng tư/rules | Collection khác | Dùng decisions bên cạnh money | Không ảnh hưởng nhau | unit: firebase_rules_test/test/firestore.money.test.js::old collections are untouched (decisions still work next to money) |
| PRIV-10 | Riêng tư/rules | Số tiền | 0, âm, 10.000.000.001, số thực, chuỗi; 10 tỷ | Từ chối bốn loại đầu; 10 tỷ hợp lệ | unit: firebase_rules_test/test/firestore.money.test.js::amount: 0, negative, 10.000.000.001, float, string are refused; 10 tỷ is fine |
| PRIV-11 | Riêng tư/rules | Sổ riêng | Khoản có payer/splitMode/payerShare/memberUids | Từ chối khoá của sổ chung | unit: firebase_rules_test/test/firestore.money.test.js::own entries refuse payer / splitMode / payerShare / memberUids |
| PRIV-12 | Riêng tư/rules | Hình dạng khoản | Chi/thu/chuyển/điều chỉnh đúng và sai (chi không ví, thu lấy từ ví, chuyển cùng ví, điều chỉnh 2 ví) | Chỉ dạng đúng được ghi | unit: firebase_rules_test/test/firestore.money.test.js::expense / income / transfer / adjust shapes; unit: firebase_rules_test/test/firestore.money.test.js::expense needs a wallet in the own book; income cannot take from one; unit: firebase_rules_test/test/firestore.money.test.js::transfer into the same wallet is refused; unit: firebase_rules_test/test/firestore.money.test.js::adjust touching both wallets is refused |
| PRIV-13 | Riêng tư/rules | Khoản chung | Thiếu khoá chung; người trả không phải thành viên/ví chung; người trả + ví chung cùng lúc | Từ chối | unit: firebase_rules_test/test/firestore.money.test.js::shared entries need their shared keys; unit: firebase_rules_test/test/firestore.money.test.js::payer is a member or the shared wallet (which needs outWalletId); unit: firebase_rules_test/test/firestore.money.test.js::a person paid ⇒ no shared wallet pays too (no double count) |
| PRIV-14 | Riêng tư/rules | Khoản góp | Góp vào ví chung | Đi VÀO ví chung, người trả là một người | unit: firebase_rules_test/test/firestore.money.test.js::contribution goes INTO a shared wallet, paid by a person |
| PRIV-15 | Riêng tư/rules | Khoản chung | Đổi memberUids / createdBy / type | Từ chối (bất biến) | unit: firebase_rules_test/test/firestore.money.test.js::memberUids / createdBy / type are immutable |
| PRIV-16 | Riêng tư/rules | Meta danh mục | Ghi doc khác `main`; sổ chung ghi `main` | Chỉ doc `main`; thành viên đọc/ghi | unit: firebase_rules_test/test/firestore.money.test.js::meta: only doc `main`, ≤80 custom categories, ≤120 hidden; unit: firebase_rules_test/test/firestore.money.test.js::meta: members read/write `main` |
| PRIV-17 | Riêng tư/rules | Client | Dựng khoản hợp lệ ở app | MoneyTx.isWellFormed khớp rules (sổ riêng và sổ chung) | unit: test/money_test.dart::MoneyTx.isWellFormed mirrors the rules |
| PRIV-18 | Riêng tư/rules | Tạo khoản | createdAt không phải giờ server; createdBy không phải mình | Từ chối | unit: firebase_rules_test/test/firestore.money.test.js::createdAt must be the server time, createdBy must be me |
| PRIV-19 | Riêng tư/rules | Khoản cũ | Ghi chú 201 ký tự, ngày sai, id dài | Từ chối | unit: firebase_rules_test/test/firestore.money.test.js::note 201 chars, bad date, long ids are refused |
| PRIV-20 | Riêng tư/rules | App 1.11.0 (không biết collection mới) | Nhận push money_* và inbox type lạ | Chạm push rơi về Home; inbox render không văng | thủ công: cần cài bản 1.11.0 cạnh bản mới trên máy ảo |

### 18. Couple đang chờ người ấy

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| WAIT-01 | Couple chờ | Couple còn waiting_partner | Xem thẻ Sổ tiền ở Home | "Sổ tiền của mình · Hôm nay đã ghi N khoản" (hoặc "chưa ghi khoản nào") | unit: test/money_ui_test.dart::waiting couple: own book, only today's count |
| WAIT-02 | Couple chờ | Như trên | Mở Sổ tiền | Không có tab Chung; cuối sổ có thẻ "Khi người ấy vào app…" + "Gửi lời mời" | unit: test/money_gap_screens_test.dart::WAIT-02: waiting couple → no shared tab; invite card at the bottom |
| WAIT-03 | Couple chờ | Như trên | Dùng ví, danh mục, ngân sách, báo cáo, tìm của sổ riêng | Dùng trọn vẹn một mình | maestro: maestro/expenses/01_open_menu_android.yaml; maestro: maestro/expenses/03_expense_own_android.yaml (chạy trên test1 thay test3 để kiểm) |
| WAIT-04 | Couple chờ | Couple chờ | Từ decision-wheel bấm "Ghi chi" | Mở form ở sổ riêng | unit: test/money_stage3b_test.dart::active couple → shared, waiting → own; eat / go categories |
| WAIT-05 | Couple chờ | Người ấy vừa ghép vào | Mở lại Sổ tiền | Tab Chung xuất hiện, Ví chung tự tạo, thẻ mời biến mất | thủ công: cần một tài khoản mới ghép vào test1; làm hỏng dữ liệu seed |

### 19. Rời couple, xoá tài khoản

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| LV-01 | Rời/xoá | Cặp đã ghép, tab Chung | Người ấy rời couple | Khoản chung giữ trong DB; UI người ở lại chỉ hiện doc có memberUids khớp couple hiện tại nên sổ chung trông trống; sổ riêng cả hai nguyên | unit: firebase_rules_test/test/firestore.money.test.js::someone who joins later cannot read the old pair's money; the one who stayed can; unit: test/money_gap_unit_test.dart::LV-01: every shared read is filtered by the CURRENT pair (`_pair`), so an old pair's entries never show; một phần: chỉ kiểm mã nguồn (mọi truy vấn sổ chung qua _pair); lọc thật cần Firestore (rules-test đã phủ phần quyền đọc) |
| LV-02 | Rời/xoá | Khoản của cặp cũ | Người mới ghép vào sửa/ghi | CF không push cho ai | unit: functions/test/index.test.js::money: an old pair's entry (partner left, someone new joined) notifies nobody |
| LV-03 | Rời/xoá | Xoá tài khoản | Gọi deleteAccount | Xoá sạch collection sổ riêng của người đó; khoản chung giữ cho người ở lại | unit: functions/test/index.test.js::money cleanup: account deletion erases the own book, couple teardown the shared one |
| LV-04 | Rời/xoá | Couple bị xoá hẳn | Dọn couple | Xoá toàn bộ collection sổ chung | unit: functions/test/index.test.js::money cleanup: account deletion erases the own book, couple teardown the shared one |
| LV-05 | Rời/xoá | Rời couple khi có khoản đang chờ xoá | Rời | Khoản chung chờ xoá được gửi đi ngay | unit: test/money_test.dart::flushPendingDeletes sends the undo-window deletes of that book now |
| LV-06 | Rời/xoá | Sau khi rời | Mở Sổ tiền | Mất tab Chung; thẻ Home về sổ riêng; clearShared dọn bộ nhớ | unit: test/money_gap_provider_test.dart::LV-06: clearShared drops the shared book, its writes and deletes |
| LV-07 | Rời/xoá | Rời rồi ghép người mới | Mở tab Chung | Ví chung mới với id `joint_` khác; sổ cũ không hiện | unit: test/money_gap_provider_test.dart::FR-08 / BK-07 / LV-07: shared starter is `joint_<8>_<8>`, made once; a new pair gets a new id |

### 20. Ngôn ngữ vi/en và định dạng tiền

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| I18N-01 | Ngôn ngữ/tiền | ARB | So khoá `money*` giữa app_vi.arb và app_en.arb | Đủ ~460 khoá ở cả hai, placeholder khớp | unit: test/money_gap_unit_test.dart::I18N-01: every money* key is in both ARBs with the same {placeholders} |
| I18N-02 | Ngôn ngữ/tiền | App en | Xem tiền | ₫1,250,000; gọn 1.2M; tháng "October 2026" | unit: test/money_test.dart::vi / en / negative; unit: test/money_test.dart::short form; unit: test/money_gap_pages_test.dart::I18N-02: English phone → "October 2026" and ₫1,250,000 |
| I18N-03 | Ngôn ngữ/tiền | App vi | Xem tháng | "Tháng 10, 2026" | maestro: maestro/expenses/01_open_menu_android.yaml |
| I18N-04 | Ngôn ngữ/tiền | Số nhiều | Thẻ couple chờ với 0 và N khoản | Chọn đúng nhánh plural =0 / other | unit: test/money_ui_test.dart::waiting couple: own book, only today's count |
| I18N-05 | Ngôn ngữ/tiền | Đang mở Sổ tiền | Đổi ngôn ngữ vi → en → vi | Danh mục + ví mặc định + tên màn dịch lại; không sót tiếng cũ (b7e0e88) | maestro: maestro/expenses/13_language_switch_android.yaml |
| I18N-06 | Ngôn ngữ/tiền | Mở app khi MaterialApp chưa kịp chọn locale | Mở Sổ tiền ngay | Bảng danh mục không bị kẹt tiếng Anh (AppL10n còn en lúc dựng lần đầu) | unit: test/money_gap_unit_test.dart::CAT-10 / I18N-06: a table built while AppL10n was English is rebuilt in Vietnamese after setLocale(vi) |
| I18N-07 | Ngôn ngữ/tiền | Form Ghi khoản đang mở | Đổi ngôn ngữ (qua thông báo hệ thống / quay lại app) | Form vẫn đúng, không văng | thủ công: đổi ngôn ngữ khi form đang mở cần can thiệp tay |
| I18N-08 | Ngôn ngữ/tiền | Push CF | Thiết bị en và vi | Câu push/inbox theo languageCode của thiết bị | unit: functions/test/money_gap.test.js::I18N-08: money push copy follows the device language (vi default, en for en*); unit: functions/test/money_gap.test.js::I18N-08: budget copy per level and language; no amount ever appears; unit: functions/test/money_gap.test.js::I18N-08: missing actor name falls back to the localized 'partner' word |
| I18N-09 | Ngôn ngữ/tiền | Câu chữ | Đọc toàn bộ copy Sổ tiền | Giọng "chúng mình", không dùng "nợ", không cụm sáo rỗng; quy ước dấu thanh kiểu mới (Xoá, Huỷ) | thủ công: rà văn phong là việc đọc của người |

### 21. Trợ năng

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| A11Y-01 | Trợ năng | Dòng khoản | Đọc bằng màn hình đọc | "tiêu đề, phụ, âm 120.000 đồng" (không đọc "₫") | unit: test/money_gap_screens_test.dart::A11Y-01: read as "title, sub, âm 120.000 đồng" — no ₫ |
| A11Y-02 | Trợ năng | Form | Đọc phím số | Phím có nhãn: nghìn, triệu, củ, "Xoá một ký tự", 0-9, 000, dấu phẩy | unit: test/money_ui_test.dart::hints: empty; maestro: maestro/expenses/02_amount_keypad_android.yaml |
| A11Y-03 | Trợ năng | Vùng chạm | Đo nút + ở thẻ Home, nút tròn, phím | ≥ 44 dp, cách chữ ≥ 8 | unit: test/money_gap_screens_test.dart::A11Y-03: the + is a 44 dp target, ≥ 8 dp from the row text |
| A11Y-04 | Trợ năng | Thanh ngân sách | Đọc | "Đã dùng X% ngân sách, còn Y" | unit: test/money_gap_pages_test.dart::A11Y-04: the budget bar reads "Đã dùng X% ngân sách, còn Y" |
| A11Y-05 | Trợ năng | Chip chọn một | Đọc | selected + nhóm loại trừ | unit: test/money_gap_pages_test.dart::A11Y-05: a radio chip announces selected and sits in an exclusive group |
| A11Y-06 | Trợ năng | Giảm chuyển động | Mở form / cuộn | AnimatedSize và FAB không chạy hiệu ứng | unit: test/money_gap_pages_test.dart::A11Y-06: with "reduce motion" the form and the FAB do not animate |
| A11Y-07 | Trợ năng | Màn 360dp | Ba màn ngân sách/báo cáo/tìm | Không tràn | unit: test/money_stage3a_test.dart::360dp: the three screens fit |
| A11Y-08 | Trợ năng | Cỡ chữ hệ thống 200% | Mở form và các màn | Không cắt chữ/nút | thủ công: đổi cỡ chữ máy ảo ảnh hưởng người dùng chung máy |
| A11Y-09 | Trợ năng | Màu số âm đỏ | Kiểm tương phản | ≥ 4,5:1 trên nền trắng | thủ công: cần công cụ đo màu trên máy thật |
| A11Y-10 | Trợ năng | TalkBack / VoiceOver | Đi hết luồng ghi khoản | Đọc được, thứ tự hợp lý | thủ công: cần bật trình đọc màn hình |

### 22. Analytics

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| AN-01 | Analytics | Ghi khoản | Xem event money_tx_add | Có book, type, category, wallet_type, payer, split, via, has_note, linked; KHÔNG có số tiền, tên ví, ghi chú | unit: test/money_gap_unit_test.dart::AN-01: money_tx_add carries enums and bools, never an amount, a wallet name or the note; unit: test/money_gap_unit_test.dart::AN-01: category is "custom" for the user's own, "none" without; payer is me / partner / wallet / na; unit: test/money_gap_unit_test.dart::AN-01..06: names and params fit GA4 (≤ 40 chars, snake_case, ≤ 24 params) and no param key can hold free text |
| AN-02 | Analytics | Sửa/xoá | Xem money_tx_edit, money_tx_delete{undone} | Có event (Med Tester 22/10: từng thiếu) | unit: test/money_gap_unit_test.dart::AN-02: edit and delete events; unit: test/money_gap_unit_test.dart::AN-02: the call sites exist (edit in the sheet, delete in the provider on both the "undo" and the "commit" path); unit: test/money_gap_unit_test.dart::AN-01..06: names and params fit GA4 (≤ 40 chars, snake_case, ≤ 24 params) and no param key can hold free text; một phần: payload bắt được qua AnalyticsService giả; nơi gọi kiểm bằng mã nguồn (SDK Firebase không gắn được trong test) |
| AN-03 | Analytics | Tạo ví/mục tiêu/settle | Xem money_wallet_add, money_goal_add{has_deadline}, money_goal_reached, money_settle | Có event, không chứa tên ví | unit: test/money_gap_unit_test.dart::AN-03: wallet / goal / settle / goal reached; unit: test/money_gap_unit_test.dart::AN-01..06: names and params fit GA4 (≤ 40 chars, snake_case, ≤ 24 params) and no param key can hold free text; một phần: payload bắt được qua AnalyticsService giả; nơi gọi kiểm bằng mã nguồn |
| AN-04 | Analytics | Ngân sách/báo cáo/tìm | Xem money_budget_set{scope}, money_report_open{view}, money_search{filter_count} (D27) | Cả 3 event có hằng số, hàm gọi và nơi gọi (đã vá, kiểm lại 2026-10-24) | unit: test/money_gap_unit_test.dart::AN-04: budget / report / search events exist with fixed params and are logged from their screens; unit: test/money_gap_unit_test.dart::AN-01..06: names and params fit GA4 (≤ 40 chars, snake_case, ≤ 24 params) and no param key can hold free text; một phần: 3 event nằm ở `AnalyticsEvents` (analytics_service.dart), không phải `MoneyAnalyticsEvents`; chỉ kiểm khai báo + nơi gọi bằng mã nguồn, chưa bắt payload (hàm là method của lớp, không dùng được fake) |
| AN-05 | Analytics | Mở màn | Xem money_screen_open{from} | from ∈ home, profile, decision, push, inbox, reminder | unit: test/money_gap_unit_test.dart::AN-05: screen open carries only the entry point; unit: test/money_gap_unit_test.dart::AN-01..06: names and params fit GA4 (≤ 40 chars, snake_case, ≤ 24 params) and no param key can hold free text |
| AN-06 | Analytics | Nhắc tối | Bật/tắt | money_reminder_toggle{on} | unit: test/money_gap_unit_test.dart::AN-06: reminder toggle; unit: test/money_gap_unit_test.dart::AN-01..06: names and params fit GA4 (≤ 40 chars, snake_case, ≤ 24 params) and no param key can hold free text |
| AN-07 | Analytics | Người dùng tắt analytics ở Cài đặt | Ghi khoản | Không event nào được gửi | unit: test/money_gap_unit_test.dart::AN-07: opt-out flips the flag, persists it, and logging stays a silent no-op (no SDK bound in tests either way); một phần: cờ tắt + Hive + hàm logEvent không ném; không chứng minh được "không event nào đi" vì `_analytics` private và SDK không gắn trong test |
| AN-08 | Analytics | DEV | Mở DebugView | Đủ event, payload không có dữ liệu tiền | thủ công: cần console Firebase DebugView |

### 23. Vòng lặp aggregate sum() (đã vá ở 2b4d289)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| AGG-01 | Aggregate | Home mở, cùng một ngày | Home build lại nhiều lần (MidnightBuilder, notify) | `refreshDay()` không làm gì (không đăng ký lại listener, không đọc lại tổng): 0 truy vấn aggregate mới | unit: test/money_gap_provider_test.dart::AGG-01: refreshDay on the same day reads nothing again; unit: test/money_gap_provider_test.dart::AGG-01: a Home-style rebuild loop stays at zero reads; unit: test/money_gap_provider_test.dart::AGG-01: the real Home row (rebuilt on every notify, calls refreshDay each build) settles at zero reads |
| AGG-02 | Aggregate | App ra nền rồi resume | Resume | `onResume()` tính lại tổng đúng 1 lần mỗi sổ (người ấy có thể sửa khoản cũ trong lúc mình đi vắng) | unit: test/money_gap_provider_test.dart::AGG-02: onResume re-reads each book exactly once |
| AGG-03 | Aggregate | Qua 0:00 | refreshDay sau khi qua ngày | Cửa sổ dời → listener bắn → tổng tính lại 1 lần, rồi yên | unit: test/money_gap_provider_test.dart::AGG-03 / MON-05: past midnight the window moves, one re-read, then quiet |
| AGG-04 | Aggregate | Nhiều thay đổi liên tiếp | Ghi 5 khoản trong 1 giây | Debounce gộp thành 1 lượt đọc tổng | unit: test/money_gap_provider_test.dart::AGG-04: five snapshots in a second are one read |
| AGG-05 | Aggregate | Lỗi tải | Bấm Thử lại | retry() đăng ký lại stream và đọc tổng đúng 1 lần | unit: test/money_gap_provider_test.dart::AGG-05: retry resubscribes and reads the sums once |
| AGG-06 | Aggregate | DEV, Home mở 10 phút không chạm | Xem Firestore usage / log truy vấn | Số đọc aggregate đứng yên (trước vá: ~(2×số ví + 2) truy vấn mỗi giây) | thủ công: cần xem usage Firebase Console hoặc log truy vấn Firestore; Lead đã ghi cần smoke |
| AGG-07 | Aggregate | DEV | Mở Sổ tiền lần đầu sau deploy index | Aggregate trả số, không `failed-precondition` (thiếu index) | thủ công: cần kiểm index composite trên DEV bằng console |

### 24. Thẻ Home, nhắc tối, push, decision-wheel, Cloud Functions

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| HM-01 | Home/nhắc/push | Thẻ Home | Duyệt các trạng thái | loading, error, waiting, neverLogged, monthEmpty, stale, over, noBudget, normal đều đúng chữ | unit: test/money_ui_test.dart::states |
| HM-02 | Home/nhắc/push | Cặp đã ghép, tab Chung | Chạm nút + tròn ở thẻ Home | Mở form Ghi khoản của sổ chung | unit: test/money_gap_screens_test.dart::HM-02: the round + opens the SHARED book's form |
| HM-03 | Home/nhắc/push | Thẻ lỗi | Chạm Thử lại | Gọi retry, không mở màn | unit: test/money_gap_screens_test.dart::HM-03: error → "Thử lại" calls onRetry and opens nothing |
| HM-04 | Home/nhắc/push | Nhắc tối | Mặc định; bật; ghi khoản; tắt | Mặc định tắt; bật → arm 1210 + 1211; ghi khoản hôm nay → huỷ 1210; tắt → hết | unit: test/money_stage3b_test.dart::off by default; on → armed; logging drops 1210; off → gone |
| HM-05 | Home/nhắc/push | Nhắc tối bật | Xem lịch | Hôm nay + ngày mai; đã ghi hôm nay hoặc quá muộn → chỉ ngày mai | unit: test/money_stage3b_test.dart::slots: today + tomorrow; logged / too late → tomorrow only |
| HM-06 | Home/nhắc/push | Khoản ghi ở bất kỳ sổ nào | Tính "đã ghi hôm nay" | Khoản ngày hôm nay do mình ghi, sổ nào cũng được | unit: test/money_stage3b_test.dart::logged today in either book = an entry dated today by me |
| HM-07 | Home/nhắc/push | Menu ⋯ | Chọn "Nhắc tối" | Mở tuỳ chọn bật/tắt và giờ | maestro: maestro/expenses/01_open_menu_android.yaml (chỉ kiểm mục menu có mặt); unit: test/money_gap_pages_test.dart::HM-07: the evening reminder tile shows its time row only while on, and its switch follows the provider |
| HM-08 | Home/nhắc/push | Nhắc tối | Ba câu copy xoay | Xoay 3 câu theo ngày | unit: test/money_stage3b_test.dart::slots: today + tomorrow; logged / too late → tomorrow only |
| HM-09 | Home/nhắc/push | Thông báo nhắc thật | Chạm | Mở Sổ tiền | thủ công: cần thông báo thật; iOS giới hạn 64 thông báo chờ (cộng band cả đợt) |
| HM-10 | Home/nhắc/push | Push money_* | Chạm push; mở inbox | Về Home(0) rồi Sổ tiền sổ chung; 3 loại type đều parse | unit: test/money_stage3b_test.dart::push route: Home + money focus (+ the fund for money_goal*); unit: test/money_stage3b_test.dart::inbox: the 3 types parse, open Home (0) and read like the push |
| HM-11 | Home/nhắc/push | CF notifyMoney | Khoản thường (không ngân sách, không mục tiêu, sửa khoản góp) | Không push | unit: functions/test/index.test.js::money: plain entries never push (no budget, not a goal, edits of a contribution) |
| HM-12 | Home/nhắc/push | Máy thật | Nhận push thật tới máy | Tới nơi, không có số tiền trên màn khoá | thủ công: DEV chưa có APNs key, emulator Android không đăng ký được FCM |
| DW-01 | Home/nhắc/push | Decision-wheel kết quả "Bún chả" | Bấm "Ghi chi" | Form điền sẵn: Ăn ngoài, ghi chú = kết quả, ngày hôm nay, source decision | unit: test/money_stage3b_test.dart::sheet prefilled: Ăn ngoài, note = the pick, source decision |
| DW-02 | Home/nhắc/push | Quay wheel trên máy ảo | Quay → Ghi chi → Lưu | Khoản có `via = decision` | chưa phủ → đề xuất maestro: maestro cho decision-wheel (chưa có flow, thuộc feature decision-wheel) |

## Tổng số case theo cách kiểm (cập nhật 2026-10-24)

| Cách kiểm | Số case |
|---|---|
| unit | 231 |
| unit + maestro | 35 |
| maestro | 20 |
| thủ công | 17 |
| unit + thủ công | 2 |
| unit + thủ công + chưa phủ | 1 |
| unit + chưa phủ | 1 |
| maestro + chưa phủ | 1 |
| **Tổng** | **308** |

Cắt theo cách khác (một case có thể rơi vào nhiều dòng):

| Tiêu chí | Số case |
|---|---|
| Có ít nhất một cách kiểm tự động (unit, rules, functions hoặc maestro) | 291 |
| Trong đó đã có test unit/widget/rules/functions chạy được ngay | 270 |
| Trong đó có flow Maestro | 56 |
| Còn thiếu test (ghi "chưa phủ", toàn bộ hoặc một phần) | 3 |
| Cần làm tay | 20 |
