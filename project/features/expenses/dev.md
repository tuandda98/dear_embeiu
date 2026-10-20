# 💻 Dev — Sổ tiền (expenses)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** mốc A — stage 1/3 xong (lõi tính + lớp dữ liệu + backend). Stage 2 (UI lõi) và stage 3 (phần còn lại) chưa làm.
- **Người/role:** Dev
- **Nhánh:** `feature/expenses` (worktree `dear_embeiu-money`). Chưa deploy gì: rules, index, CF đều chờ Lead deploy DEV từ nhánh gộp.

## Kế hoạch kỹ thuật (mốc A, 3 stage)

| Stage | Nội dung | Trạng thái |
|---|---|---|
| 1 | Hàm thuần + test · model · `MoneyService` · `MoneyProvider` · wire `main` + `session_resolver` · rules + index + test · CF `notifyMoney` + dọn khi xoá | ✅ 2026-10-20 |
| 2 | UI lõi: lối vào Home, `MoneyScreen` 2 sổ, sheet ghi khoản, lần đầu mở, ví (danh sách, chi tiết, tạo, sửa số dư, chuyển), danh mục | ⏳ |
| 3 | Ngân sách, báo cáo, tìm kiếm, quỹ, thanh toán, nút decision-wheel, nhắc tối 1210–1211, analytics, push tap 2 chỗ | ⏳ |

### File stage 1

| File | Có gì |
|---|---|
| `lib/utils/money_input.dart` | `parseVndInput(raw, {max})` → `VndParseResult{value, error: empty/invalid/zero/tooBig, hasUnit}` · `formatVnd` (vi `1.250.000 ₫` với NBSP, en `₫1,250,000`, âm U+2212) · `formatVndShort` (`50k`, `1,2tr`, `3,5 tỷ` / `50K`, `1.2M`, `3.5B`) · hằng `kMoneyTxMax` 10 tỷ, `kMoneyWalletMax` 100 tỷ, `kMoneyWalletMin` −10 tỷ |
| `lib/utils/money_math.dart` | `MoneyMath` (thuần, mọi số trên màn đi qua đây): ngày/tháng (`dateKey`, `monthKey`, `monthRange`, `addMonths`, `trendMonths`), `monthTotals`, `spentIn`, `byCategory` (truyền `groupOf` để gộp cấp 1), `byWallet`, `walletBalance`, `balancesFrom`, `pendingDelta`, `totalAssets`, `walletWithinCap`, `budgetStatus` (percent làm tròn xuống, level 0/80/100), `crossedLevel`, `goalPercent`, `monthsUntil`, `perMonthNeeded` (làm tròn lên nghìn), `payerShareFor` (chia đôi lẻ → người trả chịu phần lên), `coupleBalance` (dương = mình ứng nhiều hơn), `settlementFor`, `paidBy` (3 làn), `contributionsBy`, `linkedDrift`, `defaultCategory` (nhiều nhất 14 ngày, hoà → gần nhất, không có → gần nhất từ trước, không có nữa → fallback), `defaultWallet` (ví dùng lần trước với danh mục đó → `meta.defaultWalletId` → ví đầu theo `order`), `quickRepeats`, `fold` (bỏ dấu), `search` |
| `lib/models/money.dart` | `MoneyBookKind`, `MoneyWallet`, `MoneyTx`, `MoneyBudget`, `MoneyMeta`, `MoneyCustomCategory`, enum loại ví / loại khoản / `MoneySplitMode` (wire `for_partner`), `kMoneyPayerWallet = 'wallet'`. `isWellFormed` của ví và khoản bắt chước rules để lệnh ghi offline không nằm hàng đợi rồi bị từ chối sau |
| `lib/data/money_categories.dart` | 53 danh mục mặc định (12 nhóm chi + 35 con, 6 nhóm thu; id + emoji theo `docs/design/expenses/data.js`, Gia đình 👪 theo Designer) · `moneyDefaultCategoryName(l, id)` · `resolveMoneyCategories(meta, l)` (áp `overrides`, `hiddenCategoryIds`, danh mục tự thêm) · `MoneyCategoryIndex` (`of(id)` rơi về `other`/`income_other`, `groupOf`, `pickable(kind)`) |
| `lib/services/money_service.dart` | `MoneyService.own(uid)` / `.shared(coupleId, memberUids)`: `watchWallets` (kèm `fromServer`), `watchTx({from,to})` (kèm cờ `pending` từng khoản), `fetchTx`, `findByLinkId`, `watchBudgets`, `watchMeta`, `walletNetSums` (2 aggregate/ví), `monthSums`, `commit(ops)` (1 batch, trả `saved`/`queued` sau 4 giây, lỗi đến muộn gọi `onLateError`), `createTxOp`/`updateTxOp`/`deleteTxOp`, `createWallets`, `updateWallet`, `setBudget`, `deleteBudget`, `setMeta` |
| `lib/providers/money_provider.dart` | `MoneyProvider` + `MoneyBookState`. API ở mục dưới |
| `lib/main.dart` (khối `// ── expenses (đợt 2) ──`) | `ChangeNotifierProvider(create: (_) => MoneyProvider())` |
| `lib/app/session_resolver.dart` (các khối đánh dấu) | named-param `moneyProvider` (signature + call site); `watchOwn(uid)` ngay sau `loadCoupleForUser` khi đã đăng nhập; `watchShared(coupleId, couple.memberIds, uid)` khi có người ấy (cùng điều kiện `rpsPartnerUid`), không thì `clearShared()`; `clear(signedOut: true)` ở nhánh chưa đăng nhập + chờ xác thực email |
| ARB `app_en.arb` / `app_vi.arb` | 53 key `moneyCat…` + `moneyWalletCash` (Tiền mặt / Cash) + `moneyJointWallet` (Ví chung / Shared wallet), một khối liền cuối file. Copy UI khác của design §6 **chưa thêm** (stage 2–3 thêm khi dùng) |
| `firestore.rules` (khối `// ── expenses (đợt 2) ──` … `// ── hết expenses (đợt 2) ──`, trước `reports`) | xem mục Rules |
| `firestore.indexes.json` | 5 index `moneyTx` (cuối mảng `indexes`) |
| `functions/index.js` | khối cuối file: `notifyMoney` + helper; 2 chỗ chèn có đánh dấu trong `deleteAccount` (bước 2c) và `deleteCoupleCompletely` |
| Test | `test/money_test.dart` (51) · `firebase_rules_test/test/firestore.money.test.js` (47) · `functions/test/index.test.js` khối `notifyMoney` (8) |

### API `MoneyProvider` (cho stage 2–3)

- Vòng đời: `watchOwn(uid)` · `watchShared(coupleId, memberIds, uid)` · `clearShared()` · `clear({signedOut})` · `refreshDay()` (gọi lúc qua 0:00 / resume để dời cửa sổ 45 ngày của sổ riêng).
- Sổ: `own`, `shared`, `book(kind)`, `hasShared`, `uid`, `partnerUid`, `today`. `MoneyBookState`: `wallets`, `walletsFromServer`, `txs`, `txLoaded`, `budgets`, `meta`, `categories` (index theo ngôn ngữ app), `lastSyncAt` (dòng "số lúc 11:58"), `loadError`, `netSumsStale` (đang hiện số cache).
- Số dư: `balances(kind)` (cache aggregate + khoản chờ mạng − khoản đang trong 5 giây hoàn tác), `balancesReady(kind)`, `totalAssets(kind)`, `exceedsWalletCap(kind, draft)`.
- Lần đầu: `needsFirstRun` (server xác nhận sổ riêng chưa có ví nào) · `ensureDefaultWallet(kind, extra: [...])` tạo "Tiền mặt" id `cash` / "Ví chung" id `joint_<8 ký tự uid A>_<8 ký tự uid B>` + các ví chọn ở màn lần đầu · `createWallet`, `updateWallet`, `archiveWallet`.
- Khoản: `addTx(kind, draft, {ownWalletId})` (sổ chung + `ownWalletId` → ghi thêm khoản ở sổ riêng cùng `linkId`, 1 batch) · `contribute(...)` · `settle(...)` · `updateTx(kind, old, updated, {alsoLinked})` ("Sửa cả hai") · `linkedOf(kind, tx)` · `linkedDrift(ownTx)` + `syncLinkedAmount` ("Thảo đã đổi khoản chung thành 520k · Cập nhật") · `scheduleDelete(kind, tx, {alsoLinked})` / `undoDelete(id)` / `isDeleting(id)` · `lastWriteError` + `acknowledgeWriteError()`.
- Mặc định: `defaultCategory(kind, type)`, `defaultWallet(kind, categoryId, {type})`, `quickRepeats(kind)`.
- Tháng / báo cáo: `txsForMonth(kind, month)` (null = chưa nạp → gọi `viewMonth`) · `viewMonth(kind, month)` · `budgetFor`, `budgetStatus(kind, categoryId, {month})`, `setBudget`, `deleteBudget`, `setMeta` · `trend(kind, n)` (tháng nào không nạp được là null — không vẽ cột 0 giả) · `search(kind, from, to, …)` → `(rows, capped)`.

### Thay đổi Firestore / CF

**Schema** đúng overview D6 (khoá `[chung]` chỉ ở sổ chung). Field client không ghi: `alerted` (budget chung), `goalReachedAt` (ví chung).

**Rules** (additive, collection mới, app ≤1.11.0 không đụng):
- Sổ riêng `users/{uid}/moneyWallets|moneyTx|moneyBudgets|moneyMeta`: chỉ chủ; khoá sổ chung bị `hasOnly` chặn; `settle` bị chặn.
- Sổ chung `couples/{id}/…`: ví + khoản đọc khi `isCoupleMember && uid in resource.data.memberUids`; tạo khi `memberUids == couple.memberIds` và đủ 2. Ngân sách + meta: thành viên đọc; ghi khi couple đủ 2 người. Truy vấn `where('memberUids', ==, cặp)` được rules chứng minh (đã có test).
- Chung hai sổ: amount int 1..10 tỷ · openingBalance −10..100 tỷ · goalTarget 1..100 tỷ, chỉ ví goal · `currency` thiếu hoặc `VND` · name 1..30 · note ≤200 · id ≤40 · emoji ≤8 · date `YYYY-MM-DD` · hình dạng từng loại khoản (§5) · `createdAt == request.time`, `createdBy == uid` · sửa: `updatedBy == uid`, `updatedAt == request.time`, `editCount == cũ + 1`, bất biến `type, memberUids, createdBy, createdAt, linkId` · khoản chung có `linkId`: người khác người tạo không đổi `amount, outWalletId, inWalletId, payer, payerShare, splitMode`, không xoá · ví không xoá (lưu trữ) · meta chỉ doc `main`, ≤80 danh mục tự thêm, ≤120 ẩn, ≤140 override.

**Index** (`moneyTx`, COLLECTION): `(memberUids, date↓)` danh sách sổ chung · `(memberUids, inWalletId)` + `(memberUids, outWalletId)` aggregate góp quỹ của CF · `(memberUids, type, date)` aggregate ngân sách của CF · `(type, date)` xu hướng sổ riêng. Emulator không kiểm index: Lead deploy DEV xong cần chạy thử xu hướng + CF một lần.

**CF `notifyMoney`** (`onDocumentWritten couples/{coupleId}/moneyTx/{txId}`, us-central1): bỏ qua khoản xoá, khoản không thuộc cặp hiện tại (người ấy đã rời / người mới vào). (a) Góp vào ví goal (chỉ lúc tạo): người không phải `payer` nhận push `{emoji} {tên quỹ}` · "{tên} vừa góp vào quỹ, giờ được 40%" + inbox `money_goal {coupleId, walletId, actorName, percent, walletName, walletEmoji}`. (b) Ví goal chạm 100%: transaction ghi `goalReachedAt` lần đầu → cả hai nhận "đủ rồi" + inbox `money_goal_reached` (lần đó không gửi push góp). (c) Khoản chi tháng hiện tại (giờ Việt Nam) đẩy tổng chi chung qua 80%/100% ngân sách tổng → transaction ghi `alerted.{YYYY-MM}`, người không phải `updatedBy ?? createdBy` nhận push + inbox `money_budget {coupleId, month, level}`. Push không số tiền, không `wakeClients`, data `{type, coupleId, walletId | month+level}`.

**Dọn dữ liệu:** `deleteAccount` bước 2c `recursiveDelete` 6 collection sổ riêng (`moneyWallets, moneyTx, moneyBudgets, moneyMeta, moneyRecurring, moneyDebts`). `deleteCoupleCompletely` thêm 5 collection sổ chung. Rời couple (`handleCoupleOnAccountDeletion` khi còn người ở lại, `notifyPartnerLeft`) không đụng gì → người ở lại giữ sổ chung (D4). Viết thẳng trong 2 hàm (chỉ dùng `db` + `logger`) để test cũ của 2 hàm này chạy được mà không phải sửa.

**Cần deploy (Lead, DEV trước):** `firestore:rules,firestore:indexes,functions:notifyMoney,functions:deleteAccount,functions:leaveCoupleCleanup`. PROD chờ lệnh user, rules PROD lên trước khi bản có feature live.

## Chỗ lệch spec (có lý do)

1. **Sổ chung nạp toàn bộ lịch sử của cặp**, không chỉ listener theo tháng (D19). Cân bằng phải cộng từ khoản đầu tiên (D7) nên đằng nào cũng phải đọc hết; overview §8 đã chấp nhận. Nhờ vậy số dư ví chung, xu hướng, tìm kiếm của sổ chung tính tại máy và chạy cả khi mất mạng. Aggregate `sum()` chỉ dùng cho sổ riêng (cửa sổ 45 ngày + số dư) và cho CF.
2. **Tìm kiếm lọc danh mục / ví ở máy**, server chỉ lọc khoảng ngày (+ cặp). Lọc trên server cần thêm 4–6 index ghép cho mỗi tổ hợp; tập đã giới hạn 2.000 dòng nên lọc ở máy vẫn nhanh.
3. **"Ghi tiền về ví của mình" khi thanh toán** (design §15.11) ở sổ riêng là khoản `adjust` có `linkId` (vào ví khi người ấy trả mình, ra ví khi mình trả). Rules cấm `settle` ở sổ riêng (§5, acceptance), và `adjust` không tính thu nhập, đúng ý "không tính là thu nhập".
4. **`editCount + 1` áp cả sổ riêng** (spec chỉ ghi cho sổ chung). Một hàm rules dùng chung, sửa offline nối tiếp trên cùng máy vẫn qua vì cache local đã có bản trước.
5. **Rules `moneyRecurring` / `moneyDebts` để mốc B** (giờ mặc định bị chặn hết). Danh sách dọn khi xoá tài khoản / couple đã gồm cả hai để dữ liệu mốc B không bao giờ sót.
6. **Cảnh báo ngân sách của CF chỉ cho tháng hiện tại theo giờ Việt Nam.** Ghi bù khoản của tháng trước thì không push "còn N ngày" vô nghĩa. Cặp yêu xa ở múi giờ khác lệch tối đa vài giờ quanh nửa đêm cuối tháng.
7. **Lần đầu mở không dùng cờ Hive:** `needsFirstRun` = server xác nhận sổ riêng chưa có ví. Đổi máy không bị hỏi lại, và Home bấm "+" trước khi mở Sổ tiền chỉ cần `ensureDefaultWallet`.
8. **Inbox `money_goal` thêm `percent`, `walletName`, `walletEmoji`, `coupleId`** để trung tâm thông báo vẽ được câu mà không phải đọc ví (spec chỉ ghi `walletId, actorName`). Không có số tiền.

## Edge case kỹ thuật / rủi ro cho Tester

- 🟡 Số dư sổ riêng khi mất mạng = cache aggregate + khoản **tạo** đang chờ mạng. Khoản **sửa** số tiền lúc offline chưa được tính tạm tới khi có mạng.
- 🟡 Khoản vừa ghi, aggregate chạy trước khi server nhận nhưng metadata chưa kịp đổi: có thể đếm đôi trong khoảng 1 giây rồi tự đúng khi listener báo đổi metadata.
- 🟡 Xoá đang chờ 5 giây lúc đăng xuất: provider gửi lệnh xoá ngay khi `clear`, nhưng nếu Firebase Auth đã đăng xuất trước thì lệnh bị từ chối và khoản quay lại. Ít xảy ra (phải bấm đăng xuất trong 5 giây sau khi xoá).
- 🟡 Hai máy cùng tạo ví mặc định: máy sau bị rules từ chối (sửa `createdAt`), lỗi bị nuốt — đúng ý.
- 🟡 Trigger Firestore chạy ít nhất 1 lần: lần lặp lại của sự kiện tạo khoản góp có thể gửi push góp quỹ 2 lần (push "đủ rồi" và ngân sách thì có transaction nên chỉ 1 lần).
- 🟡 Người ấy rời rồi người cũ quay lại cùng couple với thứ tự `memberIds` khác → `memberUids` cũ không khớp, sổ chung cũ trông trống (đúng D3/D4, "Sổ cũ" để mốc C).
- 🟢 `MoneyProvider` / `MoneyService` chưa có unit test (repo không có fake Firestore); logic đã nằm hết trong `MoneyMath` có test. Stage 2 smoke 2 máy DEV là chỗ kiểm thật.
- 🟢 Cache Hive `money_cache` chỉ giữ tổng in−out từng ví sổ riêng, xoá khi đăng xuất. Chưa đưa vào thư mục loại khỏi backup như `sleep_nobackup`; Firestore cache vốn cũng không loại.

## Kế hoạch stage 2 — UI lõi (agent sau làm tiếp)

Đọc design §2, §3.1–3.6, §4, §5, §7, §8, §15 (bản §15 thắng). Tra UI UX Pro Max trước khi thêm bất kỳ thứ gì design chưa phủ (luật 8).

1. **Widget chung `lib/widgets/segmented_pill.dart`** (h48 r20, thumb 260ms easeInOutCubic; Reduce Motion nhảy thẳng) — rút từ mode selector của `setup_screen.dart` / `decision_wheel_screen.dart`, chỉ dùng ở Sổ tiền (không tự sửa 2 màn kia, ghi đề xuất cho Lead).
2. **Lối vào Home `lib/widgets/money/money_home_entry.dart`** ở dòng đánh dấu `// ── Đợt 2 (Home C): MoneyHomeEntry …` trong `home_screen.dart`. Chỉ số sổ chung (`monthTotals` + `budgetStatus(shared, '')`), cặp chờ = số khoản hôm nay sổ riêng (không số tiền). 9 trạng thái ở `home-entry.html`. HomeScreen phải gọi `moneyProvider.watchShared(...)` khi couple chuyển sang active giữa phiên (như rps) và `refreshDay()` khi qua 0:00 / resume.
3. **`lib/screens/money/money_screen.dart`**: `SubScreenHeader` chip "SỔ TIỀN" + ⌕ + ⋯; segmented Của mình · Chung (ẩn khi `!hasShared`, nhớ tab cuối trong Hive `app_settings`); thẻ tháng (Đã chi · Còn trong ngân sách; dải Thu | Thu trừ chi ở sổ riêng); ba làn + cân bằng (sổ chung: `paidBy`, `coupleBalance`); Gần đây theo ngày (`MidnightBuilder`); Tiêu vào đâu; Ví (`balances`, `totalAssets`); FAB hồng ẩn khi cuộn xuống; thẻ D5 cho cặp chờ; trạng thái rỗng / tải / lỗi (`loadError`, `lastSyncAt`) / mất mạng (`netSumsStale`, khoản `pending`) / người mới (`money-new.html`).
4. **Lần đầu mở `MoneyFirstRun`** khi `needsFirstRun`: 5 hàng ví, ô số dư dùng `parseVndInput(max: kMoneyWalletMax)` + bàn phím hệ thống; thẻ tín dụng nhập dư nợ dương, lưu âm; "Xong" / "Bỏ qua" → `ensureDefaultWallet(own, extra: …)`. Sổ chung: `ensureDefaultWallet(shared)` lúc mở tab Chung lần đầu.
5. **Sheet ghi khoản `lib/widgets/money/add_transaction_sheet.dart`** theo §15: hàng đầu Đóng · Chi/Thu/Chuyển · nút sổ; ô số + bàn phím riêng 4×4 phím 48 (`1 2 3 ⌫ / 4 5 6 k / 7 8 9 tr / , 0 000 củ`) đổ vào chuỗi rồi `parseVndInput` (dòng gợi ý theo `VndParseError`, `hasUnit` → "Bạn gõ “1tr2”"); chip 50k/100k/200k/500k cộng dồn; "Ghi lại khoản quen" (`quickRepeats`, chỉ khi ô trống); danh mục (`defaultCategory`, 5 gần nhất + "Tất cả" mở bộ chọn 2 cấp, tìm bằng `MoneyMath.fold`); chip ví (`defaultWallet` theo danh mục; sổ chung khi mình trả = ví riêng để trừ + chip "Không trừ" → `ownWalletId`); hàng tóm tắt (ai trả · cách chia · ngày / ngày · ghi chú); `payerShareFor`; Lưu ghim đáy "Lưu 1.200.000 ₫"; `exceedsWalletCap`; hỏi "Bỏ khoản đang ghi?" khi đóng dở; snackbar "Đã ghi … · Hoàn tác" (+ dòng ngân sách nếu `crossedLevel`). Nhớ ai trả / cách chia lần trước trên máy (Hive). Chế độ sửa: khoá ô tiền / ai trả / chia / ví khi `linkId != null && createdBy != uid` (copy `moneyLinkedLocked`); dialog "Sửa luôn bên sổ của mình?" → `updateTx(alsoLinked:)`; Xoá → `scheduleDelete` + snackbar Hoàn tác 5 giây; khoản có ở cả hai sổ thì hỏi trước. Bắt `permission-denied` khi sửa sổ chung → snackbar `moneyConflict`; theo dõi `lastWriteError`.
6. **Ví**: `MoneyWalletsScreen` (Đang dùng / Mục tiêu / Đã lưu trữ), chi tiết ví (vào/ra tháng, khoản tháng), sheet tạo ví (5 loại, goal có đích + hạn → `perMonthNeeded`), sheet "Sửa số dư cho khớp" (tạo `adjust` chênh lệch), chuyển = sheet ghi khoản tab Chuyển. Cảnh báo ví thường âm (thẻ tín dụng không báo).
7. **Danh mục** `MoneyCategoriesScreen`: Chi | Thu, sửa tên / emoji qua `overrides`, ẩn / hiện qua `hiddenCategoryIds`, thêm mục con / nhóm qua `customCategories` (id `c_<auto>` ≤40), xoá danh mục tự thêm (khoản cũ về "Khác") — ghi bằng `setMeta`.
8. ARB: thêm key copy deck design §6 dùng tới (prefix `money`, một khối liền cuối file), `flutter gen-l10n`. Chạy humanizer cho copy mới nếu Designer chưa soát.

## Kế hoạch stage 3

1. **Ngân sách** `MoneyBudgetsScreen` (tổng + theo nhóm, `budgetStatus`, "Chưa đặt ngân sách" liệt kê nhóm đang chi mà chưa có, `setBudget`/`deleteBudget`, chú thích push sổ chung).
2. **Báo cáo** `MoneyReportScreen`: tháng (Thu | Chi | Còn lại), Theo người (sổ chung), Chi theo danh mục (`byCategory` + chạm mở cấp 2), Chi mỗi tháng 6/12 (`trend`; tháng null không vẽ; đường ngân sách đứt), Chi theo ví (`byWallet`).
3. **Tìm kiếm** `MoneySearchScreen` (`search`; mặc định 3 tháng, nút "Tìm trong 12 tháng", notice khi `capped`, tô phần khớp).
4. **Quỹ** `MoneyGoalScreen` (`goalPercent`, `perMonthNeeded`, `contributionsBy(walletId)`, lịch sử góp, "Góp vào quỹ" → `contribute`, "Chi từ quỹ" → khoản chi `payer: wallet`, trạng thái đủ 100%).
5. **Thanh toán** `SettleSheet` (`settlementFor`, trả hết / một nửa / sửa số, công tắc "Ghi tiền về ví của mình" → `settle(ownWalletId:)`, thẻ "Vì sao là 359.000 ₫", hoàn tác).
6. **Decision-wheel D20**: nút phụ "Ghi chi" ở sheet kết quả kind eat/go → sheet ghi khoản điền sẵn `food_out` / `date_out`, ghi chú = result, hôm nay, `source: 'decision'`; cặp active → sổ chung, cặp chờ → sổ riêng. Báo PO decision-wheel cập nhật changelog.
7. **Nhắc tối D18** dải **1210–1211** (`ReminderService`, one-shot hôm nay + mai, 21:30 đổi được, Hive, mặc định tắt; huỷ 1210 khi ghi khoản đầu tiên trong ngày ở bất kỳ sổ nào; copy xoay 3 câu). Lead đối chiếu band cả đợt (iOS 64).
8. **Analytics D27** qua `AnalyticsService` (không số tiền, tên ví, ghi chú, tên danh mục tự thêm).
9. **Push tap** `money_goal`, `money_goal_reached`, `money_budget` → `MoneyScreen` sổ chung (`money_goal*` kèm `focusWalletId`): sửa CẢ `push_notification_service._handleNotificationTap` lẫn `AppNotification.targetHomeTab` + render inbox 3 type mới trong `notification_center_screen` (inbox có sẵn `percent`, `walletName`, `walletEmoji`, `month`, `level`). Kiểm bản 1.11.0 gặp type lạ (D28).
10. Mục nhập Profile + lối "Sổ tiền" trong menu; khai báo store + privacy policy (D30) là việc của Lead/PO trước khi gửi duyệt.

## Checklist implement (mốc A)

- [x] `parseVndInput`, formatter, `MoneyMath`, danh mục mặc định + test
- [x] `MoneyService` + `MoneyProvider` 2 sổ, wire `main` + `session_resolver`, clear khi đăng xuất / hết couple
- [x] Rules + index + test rules + CF `notifyMoney` + dọn `deleteAccount` / `deleteCoupleCompletely`
- [ ] UI stage 2
- [ ] UI stage 3 + decision-wheel + nhắc tối + analytics + push tap
- [x] `flutter analyze` sạch (stage 1)
- [ ] Deploy DEV (Lead)

## Nhật ký implement
- [2026-10-20] [Dev] Stage 1: hàm thuần `parseVndInput` / `formatVnd` / `formatVndShort` / `MoneyMath` + 53 danh mục vi/en (ARB `moneyCat…`) + model; `test/money_test.dart` 51 test (số mẫu `data.js`: cân bằng 359.000, ví chung 948.000, ba làn cộng đúng chi tháng, chia đôi 75.001 → 37.501, tìm "bun cha" ra 3 khoản). Commit `c4d2fdb`.
- [2026-10-20] [Dev] Rules sổ riêng + sổ chung (additive), 5 index `moneyTx`, CF `notifyMoney` (góp quỹ %, đủ quỹ 1 lần, ngân sách 80/100% 1 lần/mốc/tháng, không số tiền, không wakeClients), dọn 6 + 5 collection khi xoá tài khoản / couple. Rules-test 441 pass (47 mới), CF 29 pass (8 mới). Commit `7f74106`.
- [2026-10-20] [Dev] `MoneyService` + `MoneyProvider`, wire `main.dart` + `session_resolver.dart` (khối đánh dấu). `flutter analyze` 0, `flutter test` 689 pass. Commit `91b00a6`. Chưa deploy.
