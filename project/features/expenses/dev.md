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
| `lib/utils/money_math.dart` | `MoneyMath` (thuần, mọi số trên màn đi qua đây): ngày/tháng (`dateKey`, `monthKey`, `monthRange`, `addMonths`, `trendMonths`), `monthTotals`, `spentIn`, `byCategory` (truyền `groupOf` để gộp cấp 1), `byWallet`, `walletBalance`, `balancesFrom`, `localCorrection`, `totalAssets`, `walletWithinCap`, `budgetStatus` (percent làm tròn xuống, level 0/80/100), `crossedLevel`, `goalPercent`, `monthsUntil`, `perMonthNeeded` (làm tròn lên nghìn), `payerShareFor` (chia đôi lẻ → người trả chịu phần lên), `coupleBalance` (dương = mình ứng nhiều hơn), `coupleBalanceFromSums`, `settlementFor`, `paidBy` (3 làn), `contributionsBy`, `linkedHalf`, `linkedDrift`, `defaultCategory` (nhiều nhất 14 ngày, hoà → gần nhất, không có → gần nhất từ trước, không có nữa → fallback), `defaultWallet` (ví dùng lần trước với danh mục đó → `meta.defaultWalletId` → ví đầu theo `order`), `quickRepeats`, `fold` (bỏ dấu), `search` |
| `lib/models/money.dart` | `MoneyBookKind`, `MoneyWallet`, `MoneyTx`, `MoneyBudget`, `MoneyMeta`, `MoneyCustomCategory`, enum loại ví / loại khoản / `MoneySplitMode` (wire `for_partner`), `kMoneyPayerWallet = 'wallet'`. `isWellFormed` của ví và khoản bắt chước rules để lệnh ghi offline không nằm hàng đợi rồi bị từ chối sau |
| `lib/data/money_categories.dart` | 53 danh mục mặc định (12 nhóm chi + 35 con, 6 nhóm thu; id + emoji theo `docs/design/expenses/data.js`, Gia đình 👪 theo Designer) · `moneyDefaultCategoryName(l, id)` · `resolveMoneyCategories(meta, l)` (áp `overrides`, `hiddenCategoryIds`, danh mục tự thêm) · `MoneyCategoryIndex` (`of(id)` rơi về `other`/`income_other`, `groupOf`, `pickable(kind)`) |
| `lib/services/money_service.dart` | `MoneyService.own(uid)` / `.shared(coupleId, memberUids)`: `watchWallets` (kèm `fromServer`), `watchTx({from,to})` (kèm cờ `pending` từng khoản), `fetchTx`, `findByLinkId`, `watchBudgets`, `watchMeta`, `walletNetSums` (2 aggregate/ví), `paidSums` (cân bằng sổ chung), `monthSums`, `commit(ops)` (1 batch, trả `saved`/`queued` sau 4 giây, lỗi đến muộn gọi `onLateError`), `createTxOp`/`updateTxOp`/`deleteTxOp`, `createWallets`, `updateWallet`, `setBudget`, `deleteBudget`, `setMeta` |
| `lib/providers/money_provider.dart` | `MoneyProvider` + `MoneyBookState`. API ở mục dưới |
| `lib/main.dart` (khối `// ── expenses (đợt 2) ──`) | `ChangeNotifierProvider(create: (_) => MoneyProvider())` |
| `lib/app/session_resolver.dart` (các khối đánh dấu) | named-param `moneyProvider` (signature + call site); `watchOwn(uid)` ngay sau `loadCoupleForUser` khi đã đăng nhập; `watchShared(coupleId, couple.memberIds, uid)` khi có người ấy (cùng điều kiện `rpsPartnerUid`), không thì `clearShared()`; `clear(signedOut: true)` ở nhánh chưa đăng nhập + chờ xác thực email |
| ARB `app_en.arb` / `app_vi.arb` | 53 key `moneyCat…` + `moneyWalletCash` (Tiền mặt / Cash) + `moneyJointWallet` (Ví chung / Shared wallet), một khối liền cuối file. Copy UI khác của design §6 **chưa thêm** (stage 2–3 thêm khi dùng) |
| `firestore.rules` (khối `// ── expenses (đợt 2) ──` … `// ── hết expenses (đợt 2) ──`, trước `reports`) | xem mục Rules |
| `firestore.indexes.json` | 5 index `moneyTx` (cuối mảng `indexes`) |
| `functions/index.js` | khối cuối file: `notifyMoney` + helper; 2 chỗ chèn có đánh dấu trong `deleteAccount` (bước 2c) và `deleteCoupleCompletely` |
| Test | `test/money_test.dart` (61 sau review) · `firebase_rules_test/test/firestore.money.test.js` (50) · `functions/test/index.test.js` khối `notifyMoney` (11) |

### API `MoneyProvider` (cho stage 2–3)

- Vòng đời: `watchOwn(uid)` · `watchShared(coupleId, memberIds, uid)` · `clearShared()` · `clear({signedOut})` · `refreshDay()` (gọi lúc qua 0:00 / resume để dời cửa sổ 45 ngày của sổ riêng).
- Sổ: `own`, `shared`, `book(kind)`, `hasShared`, `uid`, `partnerUid`, `today`. `MoneyBookState`: `wallets`, `walletsFromServer`, `txs`, `txLoaded`, `budgets`, `meta`, `categories` (index theo ngôn ngữ app), `lastSyncAt` (dòng "số lúc 11:58"), `loadError`, `netSumsStale` (đang hiện số cache).
- Số dư: `balances(kind)` (aggregate hoặc bản cache + lệnh ghi của máy này mà aggregate chưa tính − khoản đang trong 5 giây hoàn tác), `balancesReady(kind)`, `totalAssets(kind)`, `exceedsWalletCap(kind, draft)`. **Cân bằng sổ chung: `coupleBalance()`** (int?, null = chưa có số; thêm khi sửa review #4 — UI KHÔNG tự tính `MoneyMath.coupleBalance` trên `txs` nữa vì `txs` chỉ còn 45 ngày).
- Phiên kết thúc: `MoneyProvider.flushPendingDeletes([kind])` (static) — AuthProvider.signOut / CoupleProvider.leaveCouple đã gọi sẵn.
- Lần đầu: `needsFirstRun` (server xác nhận sổ riêng chưa có ví nào) · `ensureDefaultWallet(kind, extra: [...])` tạo "Tiền mặt" id `cash` / "Ví chung" id `joint_<8 ký tự uid A>_<8 ký tự uid B>` + các ví chọn ở màn lần đầu · `createWallet`, `updateWallet`, `archiveWallet`.
- Khoản: `addTx(kind, draft, {ownWalletId})` (sổ chung + `ownWalletId` → ghi thêm khoản ở sổ riêng cùng `linkId`, 1 batch) · `contribute(...)` · `settle(...)` · `updateTx(kind, old, updated, {alsoLinked})` ("Sửa cả hai") · `linkedOf(kind, tx)` · `linkedDrift(ownTx)` + `syncLinkedAmount` ("Thảo đã đổi khoản chung thành 520k · Cập nhật") · `scheduleDelete(kind, tx, {alsoLinked})` / `undoDelete(id)` / `isDeleting(id)` · `lastWriteError` + `acknowledgeWriteError()`.
- Mặc định: `defaultCategory(kind, type)`, `defaultWallet(kind, categoryId, {type})`, `quickRepeats(kind)`.
- Tháng / báo cáo: `txsForMonth(kind, month)` (null = chưa nạp → gọi `viewMonth`; từ review #4 áp cho CẢ sổ chung) · `viewMonth(kind, month)` · `budgetFor`, `budgetStatus(kind, categoryId, {month})`, `setBudget`, `deleteBudget`, `setMeta` · `trend(kind, n)` (tháng nào không nạp được là null — không vẽ cột 0 giả) · `search(kind, from, to, …)` → `(rows, capped)`.

### Thay đổi Firestore / CF

**Schema** đúng overview D6 (khoá `[chung]` chỉ ở sổ chung). Field client không ghi: `alerted` (budget chung), `goalReachedAt` (ví chung).

**Rules** (additive, collection mới, app ≤1.11.0 không đụng):
- Sổ riêng `users/{uid}/moneyWallets|moneyTx|moneyBudgets|moneyMeta`: chỉ chủ; khoá sổ chung bị `hasOnly` chặn; `settle` bị chặn.
- Sổ chung `couples/{id}/…`: ví + khoản đọc khi `isCoupleMember && uid in resource.data.memberUids`; tạo khi `memberUids == couple.memberIds` và đủ 2. Ngân sách + meta: thành viên đọc; ghi khi couple đủ 2 người. Truy vấn `where('memberUids', ==, cặp)` được rules chứng minh (đã có test).
- Chung hai sổ: amount int 1..10 tỷ · openingBalance −10..100 tỷ · goalTarget 1..100 tỷ, chỉ ví goal · `currency` thiếu hoặc `VND` · name 1..30 · note ≤200 · id ≤40 · emoji ≤8 · date `YYYY-MM-DD` · hình dạng từng loại khoản (§5) · `createdAt == request.time`, `createdBy == uid` · sửa: `updatedBy == uid`, `updatedAt == request.time`, `editCount == cũ + 1`, bất biến `type, memberUids, createdBy, createdAt, linkId` · khoản chung có `linkId`: người khác người tạo không đổi `amount, outWalletId, inWalletId, payer, payerShare, splitMode`, không xoá · ví không xoá (lưu trữ) · meta chỉ doc `main`, ≤80 danh mục tự thêm, ≤120 ẩn, ≤140 override.

**Index** (`moneyTx`, COLLECTION): `(memberUids, date↓)` danh sách sổ chung · `(memberUids, inWalletId)` + `(memberUids, outWalletId)` aggregate số dư ví sổ chung + góp quỹ của CF · `(memberUids, type, date)` aggregate ngân sách của CF + xu hướng sổ chung · `(type, date)` xu hướng sổ riêng · `(memberUids, payer, type)` aggregate cân bằng sổ chung (review #4; truy vấn chỉ có so bằng / `in` nên có thể không cần, thêm cho chắc). Emulator không kiểm index: Lead deploy DEV xong cần chạy thử xu hướng + CF một lần.

**CF `notifyMoney`** (`onDocumentWritten couples/{coupleId}/moneyTx/{txId}`, us-central1): bỏ qua khoản xoá, khoản không thuộc cặp hiện tại (người ấy đã rời / người mới vào). (a) Góp vào ví goal (chỉ lúc tạo): người không phải `payer` nhận push `{emoji} {tên quỹ}` · "{tên} vừa góp vào quỹ, giờ được 40%" + inbox `money_goal {coupleId, walletId, actorName, percent, walletName, walletEmoji}`. (b) Ví goal chạm 100%: transaction ghi `goalReachedAt` lần đầu → cả hai nhận "đủ rồi" + inbox `money_goal_reached` (lần đó không gửi push góp). (c) Khoản chi tháng hiện tại (giờ Việt Nam) đẩy tổng chi chung qua 80%/100% ngân sách tổng → transaction ghi `alerted.{YYYY-MM}`, người không phải `updatedBy ?? createdBy` nhận push + inbox `money_budget {coupleId, month, level}`. Push không số tiền, không `wakeClients`, data `{type, coupleId, walletId | month+level}`.

**Dọn dữ liệu:** `deleteAccount` bước 2c `recursiveDelete` 6 collection sổ riêng (`moneyWallets, moneyTx, moneyBudgets, moneyMeta, moneyRecurring, moneyDebts`). `deleteCoupleCompletely` thêm 5 collection sổ chung. Rời couple (`handleCoupleOnAccountDeletion` khi còn người ở lại, `notifyPartnerLeft`) không đụng gì → người ở lại giữ sổ chung (D4). Viết thẳng trong 2 hàm (chỉ dùng `db` + `logger`) để test cũ của 2 hàm này chạy được mà không phải sửa.

**Cần deploy (Lead, DEV trước):** `firestore:rules,firestore:indexes,functions:notifyMoney,functions:deleteAccount,functions:leaveCoupleCleanup`. PROD chờ lệnh user, rules PROD lên trước khi bản có feature live.

## Chỗ lệch spec (có lý do)

1. ~~Sổ chung nạp toàn bộ lịch sử~~ — **bỏ theo review #4**: sổ chung giờ giống sổ riêng (nghe 45 ngày, số dư ví + cân bằng bằng aggregate `sum()`, cache Hive). Tìm kiếm / xu hướng sổ chung cần mạng như sổ riêng.
2. **Tìm kiếm lọc danh mục / ví ở máy**, server chỉ lọc khoảng ngày (+ cặp). Lọc trên server cần thêm 4–6 index ghép cho mỗi tổ hợp; tập đã giới hạn 2.000 dòng nên lọc ở máy vẫn nhanh.
3. **"Ghi tiền về ví của mình" khi thanh toán** (design §15.11) ở sổ riêng là khoản `adjust` có `linkId` (vào ví khi người ấy trả mình, ra ví khi mình trả). Rules cấm `settle` ở sổ riêng (§5, acceptance), và `adjust` không tính thu nhập, đúng ý "không tính là thu nhập".
4. **`editCount + 1` áp cả sổ riêng** (spec chỉ ghi cho sổ chung). Một hàm rules dùng chung, sửa offline nối tiếp trên cùng máy vẫn qua vì cache local đã có bản trước.
5. **Rules `moneyRecurring` / `moneyDebts` để mốc B** (giờ mặc định bị chặn hết). Danh sách dọn khi xoá tài khoản / couple đã gồm cả hai để dữ liệu mốc B không bao giờ sót.
6. **Cảnh báo ngân sách của CF chỉ cho tháng hiện tại theo giờ Việt Nam.** Ghi bù khoản của tháng trước thì không push "còn N ngày" vô nghĩa. Cặp yêu xa ở múi giờ khác lệch tối đa vài giờ quanh nửa đêm cuối tháng.
7. **Lần đầu mở không dùng cờ Hive:** `needsFirstRun` = server xác nhận sổ riêng chưa có ví. Đổi máy không bị hỏi lại, và Home bấm "+" trước khi mở Sổ tiền chỉ cần `ensureDefaultWallet`.
8. **Inbox `money_goal` thêm `percent`, `walletName`, `walletEmoji`, `coupleId`** để trung tâm thông báo vẽ được câu mà không phải đọc ví (spec chỉ ghi `walletId, actorName`). Không có số tiền.

## Edge case kỹ thuật / rủi ro cho Tester

- 🟡 Số dư khi mất mạng = cache aggregate + mọi lệnh tạo / sửa / xoá máy này ghi trong lần chạy app hiện tại (review #2). **Tắt app khi còn lệnh chờ mạng rồi mở lại lúc vẫn mất mạng:** các lệnh đó chưa được tính tạm tới khi có mạng (provider không biết bản cũ server đang tính).
- 🟡 Sổ chung chỉ nghe 45 ngày: người ấy sửa một khoản cũ hơn cửa sổ thì số dư / cân bằng trên máy mình đứng yên tới lần `refreshDay()` (resume, qua 0:00) hoặc snapshot kế tiếp.
- 🟡 Sổ chung lần đầu mở trên máy mới mà mất mạng: chưa có cache → `balancesReady(shared)` false, không có số dư / cân bằng (trước đây tính được từ cache toàn lịch sử).
- 🟡 Xoá đang chờ 5 giây lúc đăng xuất / rời couple: gửi đi trước (`flushPendingDeletes`, chờ tối đa ~5 giây). Mất mạng thì lệnh nằm hàng đợi của tài khoản đó, gửi khi đăng nhập lại. Xoá tài khoản chưa gọi flush (sổ riêng bị CF xoá hết; chỉ sót khoản sổ chung vừa xoá trong 5 giây).
- 🟡 Hai máy cùng tạo ví mặc định: máy sau bị rules từ chối (sửa `createdAt`), lỗi bị nuốt — đúng ý.
- 🟡 Trigger Firestore chạy ít nhất 1 lần: lần lặp lại của sự kiện tạo khoản góp có thể gửi push góp quỹ 2 lần (push "đủ rồi" và ngân sách thì có transaction nên chỉ 1 lần).
- 🟡 Người ấy rời rồi người cũ quay lại cùng couple với thứ tự `memberIds` khác → `memberUids` cũ không khớp, sổ chung cũ trông trống (đúng D3/D4, "Sổ cũ" để mốc C).
- 🟢 `MoneyProvider` / `MoneyService` chưa có unit test với Firestore (repo không có fake Firestore); logic đã nằm hết trong `MoneyMath` có test. Phần ghi nhận lệnh ghi / gỡ khi aggregate mới về (review #2) và aggregate cân bằng (review #4) chỉ kiểm được ở smoke 2 máy DEV: ghi offline 100k → sửa 120k → ví phải −120k (không −220k); xoá offline; xoá rồi Hoàn tác khoản vừa ghi lúc offline.
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

## Sửa theo review stage 1 (nhánh `feature/expenses-fix`, 2026-10-20)

| # | Mức | Đã sửa thế nào | Test |
|---|---|---|---|
| 1 | High | `parseVndInput`: dấu chấm/phẩy trước ĐÚNG 3 chữ số là ngăn cách hàng nghìn ("1.500k" = 1.500.000, "1.200tr" = 1,2 tỷ); 1–2 chữ số mới là thập phân ("1.5tr", "1,25tr"); 4 chữ số sau dấu, hoặc "1.5tr2" = không hiểu | `money_test` parseVndInput (+6 ca đúng, +3 ca sai) |
| 2 | Medium | Bỏ `MoneyMath.pendingDelta` (đếm doc có `hasPendingWrites`). Provider ghi lại mỗi lệnh tạo / sửa / xoá của máy này (`_LocalWrite`: bản server đang tính → bản trên máy) và cộng `MoneyMath.localCorrection` lên aggregate: sửa 100k → 120k chỉ −20k, xoá trả lại số server còn tính, khoản mới bị xoá trong 5 giây không trừ 2 lần. Gỡ khỏi danh sách khi server xác nhận VÀ một aggregate chạy sau lúc xác nhận đã về (`MoneyService.commit` thêm `onDone`) | `money_test` "local writes correct a cached aggregate" |
| 3 | Medium | Rules + `isWellFormed`: sổ chung, `payer` là người ⇒ không có `outWalletId`; muốn trừ ví chung phải `payer: 'wallet'`. Áp mọi loại khoản (chuyển, điều chỉnh ra ví chung cũng phải `payer: wallet`) | rules "a person paid ⇒ no shared wallet pays too" · `money_test` isWellFormed shared |
| 4 | Medium | Sổ chung nghe 45 ngày như sổ riêng (`_windowFrom` chung); số dư ví = `walletNetSums` (2 aggregate/ví), cân bằng = `MoneyService.paidSums(payer)` (1 aggregate `sum(amount)` + `sum(payerShare)`, `type in [expense, settle]`, mỗi người 1 truy vấn) → `MoneyMath.coupleBalanceFromSums`; cache Hive theo sổ + cặp. `txsForMonth` / `viewMonth` / `trend` / `search` của sổ chung đi đường server như sổ riêng. Thêm index `(memberUids, payer, type)`. API mới `coupleBalance()` | `money_test` "balance of the reference book" (từ tổng theo người = 359.000) · rules "the balance sums … work for the pair only" |
| 5 | Medium | `notifyMoney` xét quỹ đủ cho mọi khoản có `inWalletId` (chuyển từ Ví chung, điều chỉnh, góp); push "vừa góp" vẫn chỉ cho `contribution` tạo mới | functions "a transfer or adjustment that fills a goal…" |
| 6 | Low | Ngân sách id cố định `MoneyBudget.idFor`: `total` / `categoryId`; rules kiểm id + `categoryId` bất biến khi sửa; CF đọc thẳng `moneyBudgets/total`. Hai máy cùng tạo: máy sau bị rules từ chối (sửa `createdAt`) → `lastWriteError` | rules "budget id is fixed" + sửa test cũ · functions "a budget not at the fixed id `total`…" |
| 7 | Low | `MoneyMath.linkedHalf` (cùng `linkId` VÀ `createdBy == mình`) dùng cho `linkedOf` + `linkedDrift`; `linkedDrift` thuần cũng so `createdBy`; `findByLinkId(linkId, createdBy:)` lọc trên server | `money_test` "a linked half is only one I wrote" |
| 8 | Low | `parseVndInput` tính bằng `BigInt` thay `double` → "1" + 400 số 0 + "k" ra `tooBig` (value = max + 1), không ném | `money_test` "a huge number with a unit says tooBig" |
| 9 | Low | `MoneyProvider.flushPendingDeletes([kind])` (static, chờ ≤ 5 giây) gọi trong `AuthProvider.signOut` (trước `_authService.signOut`) và `CoupleProvider.leaveCouple` (trước khi rời, chỉ sổ chung). Lỗi về muộn của sổ đã đóng bị bỏ (`_lateErrorFor` so sổ hiện tại). CF: hết ngân sách ngày cuối tháng → "hôm nay là ngày cuối tháng rồi" (en "Today is the last day of the month"; tiện sửa luôn "1 days") | `money_test` "MoneyProvider — deletes before the session ends" · functions "the last day of the month gets its own line" |

**Chữ ký đổi:** `MoneyService.findByLinkId(linkId, {required createdBy})` (chỉ provider gọi) · `MoneyService.commit(..., onDone:)` thêm tham số tuỳ chọn · `MoneyMath.pendingDelta` bị xoá (thay bằng `localCorrection`) · `MoneyMath.linkedDrift` thêm điều kiện cùng người tạo. API `MoneyProvider` cũ giữ nguyên; thêm `coupleBalance()` và static `flushPendingDeletes`. `balances(shared)` / `balancesReady(shared)` giờ dựa aggregate, không còn tính từ `txs`.

**Cần biết khi gộp với stage 2:** UI cân bằng gọi `provider.coupleBalance()` thay vì `MoneyMath.coupleBalance(txs…)`. Test widget nhét sẵn `MoneyBookState` (`debugSetBooks`) muốn có số dư sổ chung thì đặt `netSums` / `coupleNet` / `netSumsAt`, không chỉ `txs`. Sheet chuyển / điều chỉnh ở sổ chung đặt `payer: kMoneyPayerWallet` khi có `outWalletId`.

**Deploy (Lead, DEV):** như cũ + `firestore:indexes` có thêm 1 index. Chưa deploy gì.

## Nhật ký implement
- [2026-10-20] [Dev] Stage 1: hàm thuần `parseVndInput` / `formatVnd` / `formatVndShort` / `MoneyMath` + 53 danh mục vi/en (ARB `moneyCat…`) + model; `test/money_test.dart` 51 test (số mẫu `data.js`: cân bằng 359.000, ví chung 948.000, ba làn cộng đúng chi tháng, chia đôi 75.001 → 37.501, tìm "bun cha" ra 3 khoản). Commit `c4d2fdb`.
- [2026-10-20] [Dev] Rules sổ riêng + sổ chung (additive), 5 index `moneyTx`, CF `notifyMoney` (góp quỹ %, đủ quỹ 1 lần, ngân sách 80/100% 1 lần/mốc/tháng, không số tiền, không wakeClients), dọn 6 + 5 collection khi xoá tài khoản / couple. Rules-test 441 pass (47 mới), CF 29 pass (8 mới). Commit `7f74106`.
- [2026-10-20] [Dev] `MoneyService` + `MoneyProvider`, wire `main.dart` + `session_resolver.dart` (khối đánh dấu). `flutter analyze` 0, `flutter test` 689 pass. Commit `91b00a6`. Chưa deploy.
- [2026-10-20] [Dev] Sửa 9 finding review stage 1 trên `feature/expenses-fix` (bảng trên). `flutter analyze` 0, `flutter test` 699 pass, rules-test 444 pass, functions 32 pass. Chưa deploy.
