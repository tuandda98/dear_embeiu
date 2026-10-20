# 💻 Dev — Sổ tiền (expenses)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** mốc A — stage 1/3 + 2/3 xong (lõi tính, dữ liệu, backend, UI lõi). Stage 3A (ngân sách, báo cáo, tìm kiếm) xong; stage 3B (quỹ, thanh toán, nhắc tối, push tap, decision-wheel, Profile) ở nhánh B.
- **Người/role:** Dev
- **Nhánh:** `feature/expenses` (worktree `dear_embeiu-money`). Chưa deploy gì: rules, index, CF đều chờ Lead deploy DEV từ nhánh gộp.

## Kế hoạch kỹ thuật (mốc A, 3 stage)

| Stage | Nội dung | Trạng thái |
|---|---|---|
| 1 | Hàm thuần + test · model · `MoneyService` · `MoneyProvider` · wire `main` + `session_resolver` · rules + index + test · CF `notifyMoney` + dọn khi xoá | ✅ 2026-10-20 |
| 2 | UI lõi: lối vào Home, `MoneyScreen` 2 sổ, sheet ghi khoản, lần đầu mở, ví (danh sách, chi tiết, tạo, sửa số dư, chuyển), danh mục | ✅ 2026-10-20 |
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

### File stage 2

| File | Có gì |
|---|---|
| `lib/widgets/segmented_pill.dart` | `SegmentedPill<T>` h48 r20 (thumb 260ms easeInOutCubic, Reduce Motion nhảy thẳng; `onSurface` cho nền trắng của sheet). Chỉ Sổ tiền dùng. **Đề xuất Lead:** cho `setup_screen` + `decision_wheel_screen` dùng lại (đang tự vẽ bản giống hệt) |
| `lib/widgets/money/money_ui.dart` | Mảnh dùng chung: `vnd` / `vndSpoken` ("120.000 đồng" cho trình đọc màn hình), nhãn tháng / ngày ("Hôm nay, 20/10", thứ tiếng Việt viết như mockup), `MoneyPeople` (tên từ couple, màu từ `SleepProvider.myColorId/partnerColorId`; `MoneyPeopleScope` để test), `MoneyAvatar`, `MoneyAmountText` (₫ nhỏ xám), `MoneyCardHeader`, `MoneyLink`, `MoneyPlanBar` (vạch "Hôm nay"), `MoneyPill`, `MoneyChip` (h40, vùng chạm 48), `MoneyChipRow`, `MoneyRowContext` + `MoneyTxRow` + `MoneyDayGroups`, `MoneyWalletRow`, `MoneyGoalBar`, `showMoneySheet`, `MoneySheetTitle`, `MoneyPrimaryButton` (tắt = nền `surfaceLight` + chữ lý do), `MoneyOutlineButton`, `showMoneySnack`, `showMoneyConfirm`, `MoneyNumberField` (bàn phím số hệ thống + parser), `pickMoneyEmoji` (lưới 32 emoji) |
| `lib/widgets/money/money_home_entry.dart` | `MoneyHomeEntry(waiting, onRetry)` + `kindOf()` thuần cho 9 trạng thái `home-entry.html`. Không Firebase → không hiện gì. Tự gọi `refreshDay()` qua `MidnightBuilder` (0:00 + resume) |
| `lib/widgets/money/add_transaction_sheet.dart` | `MoneyAmountInput` (bàn phím riêng: 1 đơn vị ngay sau số, bỏ số 0 đầu, chip cộng dồn, phím số sau chip = gõ lại, ⌫ xoá cả đơn vị) · `AddTransactionSheet.show(book, editing, type, walletId, categoryId)` · `MoneyCategoryPicker` (2 cấp, tìm không dấu, "Sửa" → Danh mục) |
| `lib/screens/money/money_screen.dart` | `openMoneyScreen(context, book)` + `MoneyScreen`: segmented 2 sổ (nhớ tab trong Hive `app_settings/money_last_tab`), notice mất mạng, thẻ tháng (‹ › đổi tháng, sổ riêng tháng cũ qua `viewMonth`), ba làn + cân bằng, Gần đây (+ dải "Thảo đã đổi khoản chung thành … · Cập nhật"), Tiêu vào đâu, Ví, thẻ D5 cặp chờ (Gửi lời mời = share sheet như Home), trạng thái người mới, FAB ẩn khi cuộn xuống, menu ⋯ (Ví · Danh mục), snackbar `lastWriteError` |
| `lib/screens/money/money_first_run.dart` | `MoneyFirstRun` (5 hàng ví, Tiền mặt khoá bật, thẻ tín dụng nhập số dương lưu âm, tổng cập nhật ngay, Xong / Bỏ qua → `ensureDefaultWallet(own, extra, starterBalance)`) |
| `lib/screens/money/money_wallets_screen.dart` | `MoneyWalletsScreen` (Tổng tiền đang có · Đang dùng · Mục tiêu · Đã lưu trữ · Thêm ví), `MoneyWalletScreen` (số dư, Vào/Ra tháng, Chuyển tiền, Sửa số dư, cảnh báo ví thường âm, khoản tháng bỏ tên ví), `MoneyWalletSheet` (tạo / sửa, 5 loại, mục tiêu có đích + hạn → `perMonthNeeded`, lưu trữ có hỏi, ví mặc định không lưu trữ được), `MoneyFixBalanceSheet` (khoản `adjust` chênh lệch) |
| `lib/screens/money/money_categories_screen.dart` | `MoneyCategoriesScreen(book, kind)`: 2 sổ · Chi/Thu, nhóm mở/đóng, sửa tên/emoji (`overrides`, đổi về tên gốc thì ghi rỗng), ẩn/hiện (`hiddenCategoryIds`), thêm nhóm / mục con (`customCategories`, id `c_<auto>`), xoá danh mục tự thêm (có hỏi), trần 80 |
| `lib/providers/money_provider.dart` (thêm) | `retry(kind)` (nút "Thử lại"), `ensureDefaultWallet(..., starterBalance)` (số dư Tiền mặt ở lần đầu), `debugSetBooks` (`@visibleForTesting`) |
| `lib/screens/home_screen.dart` (3 khối `// ── expenses (đợt 2) ──`) | import · `MoneyHomeEntry` ngay sau "Chơi cùng nhau", trước "Phân vân gì không?" (hiện cả khi chờ) · re-arm `watchOwn` + `watchShared` (người ấy vào giữa phiên) / `clearShared` trong post-frame cạnh Sleep/RPS · `refreshDay()` khi resume |
| ARB vi/en | +263 key `money…` một khối liền cuối file (đã có 55 key stage 1). Ngoài copy deck: `moneyHomeSpentOnly/OverPart` (tô đỏ riêng chữ "vượt"), `moneyHomeLoading`, `moneySettle`, `moneyNotSpending`, biến thể sổ riêng + ngân sách tổng cho dòng snackbar (`moneyOverBudgetToastMine`, `moneyNearTotalToast`…), `moneyWalletCapHit`, `moneySaveNeedWallet`, `moneyDiscardBody`, `moneyDeleteBoth*` (§15 #8), `moneyFix*` (§15 #6), `moneyFindingOver`, `moneyRecentEmpty`, `moneyFirstEntry*` (money-new), nhãn a11y phím |
| Test | `test/money_ui_test.dart` 17 test (dưới) |

**Test stage 2** (`flutter test` 706 pass, 3 skip có sẵn): `MoneyAmountInput` 2 · sheet: gợi ý trống / "Bạn gõ “1tr2”" + "Lưu 1.200.000 ₫" / "Chưa hiểu số này" / "Tối đa 10 tỷ", chip 50k+100k = 150.000, khoản quen 2 chạm (chip + Lưu, đúng số / danh mục / ví / ghi chú + snackbar), mặc định danh mục 14 ngày + ví theo danh mục, sổ chung mình trả 75.001 → mình chịu 37.501 + trừ ví riêng, khoản liên kết người ấy tạo khoá số tiền + ẩn Xoá, xoá → ẩn ngay + "Hoàn tác" trả lại · Home: `kindOf` 8 trạng thái + render bình thường / cặp chờ (không ₫) / vượt · lần đầu: thẻ tín dụng 2.458.000 → `openingBalance −2.458.000` · render MoneyScreen 2 sổ, Ví, Danh mục không tràn. Fake Firestore chỉ để dựng `MoneyService` (không đọc/ghi thật) → stream, ghi thật vẫn cần smoke 2 máy DEV.

### Tra UI UX Pro Max (stage 2, chỗ spec chưa vẽ)
- `"emoji icon picker grid selection" --domain ux` → 0; thử lại `"selection collection grid"` → *Chip Collection Reflow* (quấn dòng, không ép 1 hàng cắt) → bộ chọn emoji ví / danh mục là lưới quấn dòng 52×52 r16 trong sheet.
- `"bottom sheet dismiss unsaved changes" --domain ux` → *Cancellable State Transitions* (đặt trạng thái cuối ngay) → segmented đặt `selected` trước, thumb chạy theo; hỏi "Bỏ khoản đang ghi?" qua `PopScope`.
- `"inline error validation limit" --domain ux` → *Inline Validation* + *Error Placement* → lỗi "vượt 100 tỷ một ví" hiện ngay dưới số tiền (cùng chỗ với các lỗi số khác), nút Lưu đổi chữ "Sửa số tiền để lưu".
- `"expandable list section" --stack flutter` → 0; thử lại `"lists"` → *ListView.builder* → bộ chọn danh mục dùng `ListView.builder`; danh sách tháng còn ngắn (≤120 dòng / 3–4 ngày ở tổng quan) nên `ListView` thường, đo khi stage 3 có màn "Tất cả".
- Soát chung các thành phần đứng cạnh: hàng đầu sheet (Đóng 44 · segmented h44 · nút sổ h40/vùng chạm 48), cả họ chip (`MoneyChip` một kiểu cho 50k, khoản quen, danh mục, ví, cách chia), nút chính navy h52 + nút viền h44 ở chi tiết ví, FAB hồng chỉ trong màn tiền, nút + navy ở Home.

### Chỗ lệch thiết kế stage 2 (có lý do)
1. **Lối vào stage 3 đang ẩn** (không làm màn "Sắp có"): ⌕, "Báo cáo ›", "Ngân sách ›", "Tất cả ›", "Đặt ›" (thẻ tháng khi chưa có ngân sách chỉ ghi "Chưa đặt ngân sách"), nút "Thanh toán" + dòng "Đã trừ … ngày" ở thẻ ba làn, link "Góp vào quỹ" (thẻ ví sổ chung đang là "Quản lý ví"). Menu ⋯ mới có Ví · Danh mục. Hàng ví mục tiêu mở chi tiết ví thường (chưa có `MoneyGoalScreen`).
2. **Sheet ghi khoản tắt kéo xuống để đóng** (`enableDrag: false`, thanh handle chỉ để nhìn): Flutter đóng sheet khi kéo bằng `Navigator.pop`, bỏ qua `PopScope` → câu hỏi "Bỏ khoản đang ghi?" sẽ không bao giờ hiện. Chạm nền mờ / nút Đóng / back hệ thống vẫn đóng (có hỏi khi đang có số).
3. **Chuyển giữa ví**: 2 hàng chip "Từ ví" · "Sang ví" ngay dưới chip số tiền (cùng chỗ hàng ví của Chi/Thu, theo §15 #1) thay cho 2 dòng trong phần chi tiết của mockup. Đỡ 2 chạm.
4. **Sửa khoản liên kết**: hỏi "Sửa luôn bên sổ của mình?" chỉ khi đổi số tiền ở sổ chung; đổi ngày / ghi chú / danh mục thì sửa luôn cả hai không hỏi. Sửa từ phía sổ riêng không bao giờ ghi sang sổ chung (dải "Cập nhật" lo chiều ngược lại).
5. **Xoá khoản liên kết từ sổ riêng** chỉ xoá bên sổ riêng, không hỏi (dialog "Xoá ở cả hai sổ?" chỉ có khi xoá từ sổ chung, đúng mockup).
6. **Snackbar sau Lưu có "Hoàn tác"** (§15 #8) thay cho "Xem" (§3.3). Hoàn tác = `scheduleDelete` khoản vừa ghi (+ nửa kia), ẩn ngay, lệnh xoá đi sau 5 giây.
7. **"Mình mời" / "Tuỳ" không thành mặc định lần sau** (ai trả + chia đôi / trả hộ thì nhớ, Hive `money_last_payer` / `money_last_split`): một lần mời không nên làm mọi khoản sau thành mời.
8. **Trạng thái người mới** (`money-new.html`, Lead chốt 2026-10-20) = sổ riêng CHƯA TỪNG có khoản nào, mọi ngày: `MoneyBookState.everLogged` từ `MoneyService.hasAnyTx()` (1 truy vấn `limit(1)` mỗi sổ mỗi phiên, giữ trong bộ nhớ; listener thấy khoản nào thì thành true). Chưa biết (mất mạng) = trạng thái tháng bình thường. Lối vào Home "chưa ghi bao giờ" dùng cùng cờ cho cả 2 sổ. Segmented vẫn hiện nếu đã có sổ chung (mockup ẩn vì là cặp chờ).
9. **Ví sổ chung, dòng phụ "Mỗi người góp X tháng này"** chỉ hiện khi hai người góp bằng nhau; khác nhau thì để loại ví (câu "mỗi người góp X" sẽ sai).
10. **"Nằm trong" (đổi nhóm cha)** chỉ cho mục con tự thêm: `overrides` chỉ có tên + emoji, danh mục mặc định không dời nhóm được.
11. **Sửa ví** dùng chung sheet tạo ví (không đổi loại); "Lưu trữ ví" có hỏi; ví mặc định (Tiền mặt / Ví chung) không có nút lưu trữ.
12. **Ngày của khoản** chọn được tới 1 năm sau hôm nay (ghi trước khoản hẹn trả).

### Việc bàn giao stage 3 (thêm vào kế hoạch dưới)
- Mở lại các lối ở mục lệch 1: ⌕ trong `trailing` của header (`HeaderIconButton(search_normal_1)` trước ⋯), link "Báo cáo ›" ở hàng tháng (`_MonthCard`), "Ngân sách ›" ở `_WhereCard`, "Tất cả ›" ở `_RecentCard` (→ tìm kiếm), "Đặt ›" khi `status == null`, nút "Thanh toán" (outline h44) cạnh số cân bằng ở `_LanesCard`, "Góp vào quỹ" ở `_WalletsCard` sổ chung, mục Ngân sách · Báo cáo · Nhắc tối trong `_openMenu`, hàng ví mục tiêu → `MoneyGoalScreen`.
- Sheet ghi khoản đã nhận `categoryId` + `walletId` (dùng cho decision-wheel D20: thêm `note` + `source: 'decision'` khi mở từ kết quả).
- Dòng ngân sách trong snackbar (`_budgetLine`) đã chạy — chỉ cần có ngân sách (stage 3 tạo).

### Rủi ro / cần Tester soi (stage 2)
- 🟡 Chưa chạy trên máy: bàn phím hệ thống bật lên trong sheet (ô ghi chú / tuỳ) thì bàn phím số ẩn; cần soát iPhone SE + Android 360dp, chữ to 1.3.
- 🟡 Màu người lấy từ `SleepProvider` (màu đã chọn ở Giấc ngủ); người chưa từng mở Giấc ngủ thấy màu mặc định của provider đó.
- 🟡 Khoản thu / chuyển ở sổ chung ghi `payer = mình`, `splitMode none` (rules bắt buộc có payer); không ảnh hưởng cân bằng (chỉ tính chi + thanh toán).
- 🟡 Lỗi ghi đến muộn (`lastWriteError`) chỉ hiện khi đang mở `MoneyScreen`; ghi từ Home "+" rồi bị từ chối lúc đang ở Home thì lỗi hiện lần tới mở Sổ tiền.
- 🟢 Backend stage 1 không đổi ở stage 2 (không đụng rules / index / functions).

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

## Stage 3A — Ngân sách, Báo cáo, Tìm kiếm (nhánh A, 2026-10-20)

Làm mục 1, 2, 3 của kế hoạch stage 3 + analytics D27 cho 3 màn này. Nhánh B (quỹ, thanh toán, decision-wheel, nhắc tối, push tap, Profile) làm song song ở `dear_embeiu-moneyb`.

| File | Có gì |
|---|---|
| `lib/utils/money_views.dart` (mới) | Hàm thuần cho 3 màn: `categoryBudgets` (ngân sách nhóm, nhóm gần chạm trần lên trước), `unbudgetedGroups` (nhóm có chi mà chưa có ngân sách), `perDayLeft` (số ngày còn lại sau hôm nay, tiền mỗi ngày làm tròn xuống nghìn), `childrenOf` (mục con của 1 nhóm), `chartScale` (bước 1/2/4/5×10ⁿ, tối đa 4 khoảng: 13,26tr → bước 4tr, đỉnh 16tr), `firstActiveMonth`, `hasTet` (qua `LunarCalendar`), `searchRange` (mùng 1 của tháng thứ n−1 trước tới 12 tháng sau hôm nay), `resultTotal`, `matchRange` (vị trí khớp không dấu tính theo chỉ số chuỗi gốc, giữ cả dấu tổ hợp NFD), `percentOf` |
| `lib/screens/money/money_budgets_screen.dart` (mới) | `MoneyBudgetsScreen(book)`: thẻ tổng (số 30, thanh có vạch hôm nay, "Còn … tức khoảng … mỗi ngày", vượt thì `moneyFindingOver`; chưa đặt thì câu + nút "Đặt ngân sách tháng"), "Theo danh mục" (pill warn ≥80, pill neg "Vượt n%" ≥100, dưới 80 chữ xám), "Chưa đặt ngân sách" + nút "Đặt", chú thích push (sổ chung). `MoneyBudgetSheet.show(book, categoryId)` (null = chọn trong sheet; '' = cả sổ): ô số dùng `parseVndInput(max: 10 tỷ)`, Lưu → `setBudget`, "Bỏ ngân sách này" → `deleteBudget` + snackbar "Hoàn tác" (đặt lại số cũ). `moneyBudgetBadge()` dùng chung |
| `lib/screens/money/money_report_screen.dart` (mới) | `MoneyReportScreen(book, month)`: thẻ tháng (sổ riêng Thu · Chi · Còn lại; sổ chung số 30) + câu "chi nhiều nhất" (thêm "Phần lớn là …" khi 1 mục con ≥ 50% nhóm), "Theo người" (3 làn + %, câu góp ví chung/quỹ), "Chi theo danh mục" (thanh ngang giảm dần, nhóm lớn nhất mở sẵn, chạm mở/đóng mục con, `AnimatedSize` 280ms, Reduce Motion nhảy thẳng), "Chi mỗi tháng" 6/12 (`MoneyTrendPainter`, `CustomPaint`), "Chi theo ví". Tháng cũ hơn cửa sổ 45 ngày → `viewMonth` (1 listener); xu hướng → `provider.trend` (aggregate từng tháng) |
| `lib/screens/money/money_search_screen.dart` (mới) | `MoneySearchScreen(book)`: ô tìm h52 r20 + nút xoá 44, debounce 300ms, chip lọc cuộn ngang (khoảng ngày 1/3/6/12 tháng · Ví · Danh mục (nhóm Chi + Thu) · Khoảng tiền · Người ở sổ chung), thẻ kết quả = `DecoratedSliver` + `SliverList.builder` (tới 2.000 dòng không dựng hết một lúc), tô phần khớp, ngày đầu dòng phụ, notice khi `capped`, trạng thái rỗng + "Tìm trong 12 tháng", lỗi mạng + "Thử lại". Chạm khoản → sheet sửa, đóng sheet thì tìm lại. Không gõ gì = mọi khoản của khoảng (dùng cho "Tất cả ›") |
| `lib/widgets/money/money_ui.dart` (thêm, khối `stage 3A`) | `MoneyPage` (khung màn con: dawnBlush, `SubScreenHeader`, segmented sổ khi có sổ chung, `CustomScrollView`) + `moneyBlock()`; `MoneyTxRow` thêm `highlight` (tô rose .16) và `subPrefix` (ngày) |
| `lib/providers/money_provider.dart` (thêm, khối `stage 3A`) | `MoneyBookState.searchCache`; `search()` đọc server 1 lần mỗi khoảng ngày trong 2 phút (gõ thêm chữ chỉ lọc lại ở máy), phần nằm trong cửa sổ 45 ngày lấy từ `visibleTxs` nên khoản vừa sửa/xoá trên máy hiện đúng ngay |
| `lib/screens/money/money_screen.dart` (thêm, khối `stage 3A`) | Mở lại lối: ⌕ (trước ⋯) → Tìm · "Báo cáo ›" ở hàng tháng (truyền tháng đang xem) · "Đặt ›" dưới "Chưa đặt ngân sách" · "Tất cả ›" ở Gần đây → Tìm 3 tháng · "Ngân sách ›" ở Tiêu vào đâu · menu ⋯ thêm Ngân sách, Báo cáo. Hàng tháng đổi thành `[‹ tháng ›]` co giãn + link bên phải (để tên tháng không bị cắt) |
| `lib/services/analytics_service.dart` (khối `// ── expenses (đợt 2) ──`) | `money_budget_set{book, scope: total|category}` · `money_report_open{book, view: month|trend}` (mở màn = month, bấm 6/12 = trend) · `money_search{filter_count}` (mỗi lần tìm thật sự chạy sau khi ngừng gõ). Không số tiền, không tên ví, không chữ tìm, không tên danh mục |
| ARB vi/en | +71 key `money…` một khối liền cuối file (description "Sổ tiền (feature expenses) · stage 3A"). Copy deck §6 + vài câu mới: `moneyBudgetNoCategory`, `moneyBudgetResets`, `moneyBudgetSaved/Removed`, `moneyReportTopShared/TopChild/NewBookMine/Missing/PartialNoBudget/ChartLabel/NoSpend`, `moneySearchEmptyAll/Error/Range/Period/…` |
| Test | `test/money_stage3a_test.dart` 19 test (dưới) |

**Test stage 3A** (`flutter test` 737 pass, 3 skip có sẵn; `flutter analyze` 0): ngưỡng ngân sách 799/800/999/1000/1031 trên 1000 · data.js sổ chung: Ăn uống 1.942.000 = 97% (warn), còn 58.000, nhóm chưa đặt Nhà cửa 1.276.000 · Hẹn hò 200.000 · Đi lại 156.000, cả sổ 3.574.000 → còn 11 ngày, 129.000 ₫/ngày · nhóm gần trần lên trước · màn Ngân sách (97%, "Còn 58.000 ₫ của 2.000.000 ₫", chú thích push; vượt "Vượt 3%" + "Vượt 62.000 ₫ của 1.880.000 ₫", dưới 80% "25%") · đặt từ "Đặt" (gõ "1tr5" → `setBudget(shared, home, 1.500.000)`), bỏ + Hoàn tác · báo cáo data.js sổ riêng 9.552.000 / +20.500.000 / 10.948.000, Nhà cửa 59% phần lớn Tiền nhà 4.500.000, tổng các nhóm = chi tháng · sổ chung Ăn uống 54% phần lớn Đi chợ 1.052.000, ba làn Tuấn 2.120.000 / Thảo 402.000 / Ví chung 1.052.000, góp Thảo 1.800.000 mình 2.200.000 · trục 13,26tr → 4tr/16tr, 5tr → 2tr/6tr, tháng đầu có tiền, tháng null không tính, Tết 2026-02 và 2028-01 · màn Báo cáo 2 sổ (câu "Sổ chung mới có từ tháng 10…") · `matchRange` (NFD, hoa thường) · khoảng 3/12 tháng · "bun cha" = 3 khoản 410.000 ₫ mới nhất trước · lọc ví + nhóm + khoảng tiền · 2.000 dòng = capped · màn Tìm (27 khoản khi không gõ, tô 3 chỗ "Bún chả", rỗng "lau de" → "Tìm trong 12 tháng" ra "Lẩu dê Valentine", notice capped) · 6 màn ở 360dp không tràn + bấm 12 tháng.

### Tra UI UX Pro Max (stage 3A, chỗ spec chưa vẽ)
- `"filter chips bottom sheet multi select" --domain ux` → *Chip Collection Reflow* → sheet chọn ví / danh mục / nhóm ngân sách là `Wrap` (không ép 1 hàng). Hàng chip lọc ở màn Tìm vẫn cuộn ngang như mockup (§15 đánh đổi đã chốt).
- `"search highlight results debounce" --domain ux` → *Autocomplete* ("Debounced fetch") + *No Results* ("gợi ý thay vì chỉ 0 kết quả") → tìm khi ngừng gõ 300ms; rỗng có câu nêu khoảng ngày + nút "Tìm trong 12 tháng" (rỗng mà không gõ chữ thì câu "với bộ lọc này").
- `"bar chart trend over time" --domain chart` → biểu đồ thời gian nên có *A11y fallback: data table + trend summary* → biểu đồ đọc được bằng trình đọc màn hình: một nhãn liệt kê từng tháng + số tiền. Giữ cột (Designer đã chọn, mỗi tháng là 1 khoảng rời).
- `"expand collapse accordion" --domain ux`, `"date range picker" --domain ux`, `"custompaint chart" --stack flutter`, `"sheet form" --stack flutter` → không ra quy tắc dùng được; dùng mặc định Material (`Semantics(expanded:)` cho hàng mở mục con, chọn khoảng ngày bằng chip 1/3/6/12 tháng thay vì date picker vì spec giới hạn 12 tháng).
- `"delete destructive confirm" --domain ux` → *Confirmation Dialogs* vs §15 *undo-support* → bỏ ngân sách không hỏi, có Hoàn tác (đặt lại được, giống xoá khoản thường); nút chữ đỏ tách khỏi nút chính.
- Soát chung các thành phần đứng cạnh: ⌕ + ⋯ cùng `HeaderIconButton` 44; link "Báo cáo ›"/"Ngân sách ›"/"Tất cả ›"/"Đặt ›" cùng `MoneyLink` 14 w700; nút "Đặt" (surfaceLight h44) giống "Hiện lại" ở Danh mục; segmented 6/12 tháng dùng lại `SegmentedPill` h44 `onSurface`; chip lọc dùng `MoneyChip` `onBlush` (trắng .86, chọn navy).

### Chỗ lệch thiết kế stage 3A (có lý do)
1. **Chip khoảng ngày luôn ở trạng thái chọn** (navy), có icon lịch đứng trước thay cho mũi tên ⌄ đứng sau: `MoneyChip` chỉ có icon trước chữ; chip này luôn mang 1 giá trị nên mockup cũng vẽ nó đang chọn.
2. **Khoảng ngày: 1 / 3 / 6 / 12 tháng** (spec chỉ nói mặc định 3, tối đa 12). "3 tháng gần đây" = từ mùng 1 của tháng cách đây 2 tháng (20/10 → 01/08), tới 1 năm sau hôm nay (khoản ghi trước).
3. **Tổng tiền ở thẻ kết quả = tổng chi**; không có khoản chi thì tổng thu. Chuyển ví, sửa số dư, góp quỹ, thanh toán không cộng.
4. **"Sổ … mới có từ tháng X" dùng cho cả sổ riêng** (copy mới `moneyReportNewBookMine`): tháng trước tháng đầu tiên có tiền không vẽ cột. Tháng không tải được (mất mạng) cũng không vẽ, thêm câu `moneyReportMissing`.
5. **Không có ngân sách tổng** thì không vẽ đường đứt, câu phụ chú bỏ vế "Đường đứt là…".
6. **Tô phần khớp dùng `backgroundColor` của chữ** (không bo góc 4 như mockup — `TextSpan` không bo được; muốn bo phải dùng `WidgetSpan`, làm vỡ ellipsis).
7. **Hàng ngân sách nhóm: pill xuống dòng dưới tên khi hẹp** (`Wrap`), không đè lên số tiền.
8. **Báo cáo không có nút đổi tháng** (spec không vẽ); mở từ "Báo cáo ›" thì lấy tháng đang xem ở Sổ tiền, từ menu ⋯ cũng vậy.
9. **`MoneyPage` mới trong `money_ui.dart`** thay vì dùng `_MoneyPage` (private) của `money_wallets_screen.dart`: không dời code có sẵn để khỏi đụng nhánh B. Lead gộp xong có thể cho màn Ví dùng `MoneyPage` rồi xoá bản private.

### Rủi ro / cần Tester soi (stage 3A)
- 🟡 Chưa chạy trên máy. Test widget dùng font Ahem (rộng gấp ~2 Quicksand) nên chữ to 1.3 chưa soát được bằng test: cần soát 360dp + chữ 1.3 cho hàng ngân sách, 3 ô Thu/Chi/Còn lại, biểu đồ 12 tháng (nhãn T1–T12 cách 1).
- 🟡 Tìm kiếm cache 2 phút theo khoảng ngày: khoản NGOÀI cửa sổ 45 ngày mà người ấy sửa trong 2 phút đó chưa hiện bản mới tới khi hết 2 phút / mở lại màn.
- 🟡 Xu hướng tải 1 lần khi mở màn (aggregate mỗi tháng 2 truy vấn, tháng đã qua cache trong phiên); ghi khoản mới khi đang mở Báo cáo thì cột tháng này chưa đổi tới lần mở sau.
- 🟡 Index: xu hướng dùng `(type, date)` / `(memberUids, type, date)`, tìm dùng `(memberUids, date↓)` / `date` — đã có ở stage 1, cần chạy thật sau khi Lead deploy DEV.
- 🟡 Tháng cũ ở Báo cáo dùng chung 1 khe `viewMonth` với Sổ tiền (mở báo cáo tháng 8 rồi quay lại vẫn đúng tháng 8).
- 🟢 Không đụng rules / index / functions.

## Checklist implement (mốc A)

- [x] `parseVndInput`, formatter, `MoneyMath`, danh mục mặc định + test
- [x] `MoneyService` + `MoneyProvider` 2 sổ, wire `main` + `session_resolver`, clear khi đăng xuất / hết couple
- [x] Rules + index + test rules + CF `notifyMoney` + dọn `deleteAccount` / `deleteCoupleCompletely`
- [x] UI stage 2 (lối stage 3 ẩn)
- [x] UI stage 3A: ngân sách, báo cáo, tìm kiếm + analytics 3 màn này
- [ ] UI stage 3B (nhánh B): quỹ, thanh toán, decision-wheel, nhắc tối, push tap, Profile
- [x] `flutter analyze` sạch (stage 1, stage 2)
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
- [2026-10-20] [Dev] Stage 2 UI lõi: `SegmentedPill`, mảnh UI chung, lối vào Home (9 trạng thái), sheet ghi khoản theo §15 (bàn phím riêng, chip cộng dồn, khoản quen 2 chạm, chip ví, Lưu ghim đáy, hoàn tác, khoá khoản liên kết, hỏi sửa/xoá cả hai sổ), `MoneyScreen` 2 sổ + người mới + cặp chờ, lần đầu mở, Ví (danh sách / chi tiết / tạo / sửa số dư), Danh mục; Home wire `watchShared` giữa phiên + `refreshDay`. +263 key ARB. `flutter analyze` 0, `flutter test` 706 pass (17 mới). Commit `5dc1514`, `d084166`, `c9e7561`. Chưa deploy, chưa chạy máy.
- [2026-10-20] [Dev] Sửa 9 finding review stage 1 trên `feature/expenses-fix` (bảng trên). `flutter analyze` 0, `flutter test` 699 pass, rules-test 444 pass, functions 32 pass. Chưa deploy.
- [2026-10-20] [Dev] Khớp UI với bản vá review stage 1 (`16a2c3c`): cân bằng ở thẻ ba làn lấy `coupleBalance()` (null = skeleton), ba làn tính trên khoản của tháng; sổ chung chuyển ví / sửa số dư trừ ví đặt `payer: 'wallet'`; thẻ "Ghi khoản đầu tiên" theo cờ `everLogged` (`hasAnyTx` limit(1)). Test đặt `netSums` / `coupleNet` / `netSumsAt` / `windowFrom`; +2 test (người mới vs ngừng ghi lâu, chuyển ở sổ chung = ví trả). `flutter analyze` 0, `flutter test` 718 pass.
- [2026-10-20] [Dev] Stage 3A: `MoneyBudgetsScreen` + sheet đặt/bỏ ngân sách, `MoneyReportScreen` (biểu đồ tự vẽ `CustomPaint`, tháng cũ qua `viewMonth`, xu hướng qua aggregate), `MoneySearchScreen` (không dấu, lọc, 12 tháng, capped, tô phần khớp), mở lại lối ⌕ / Báo cáo › / Ngân sách › / Đặt › / Tất cả › + menu; analytics `money_budget_set` / `money_report_open` / `money_search`; +71 key ARB. `flutter analyze` 0, `flutter test` 737 pass (19 mới). Chưa deploy, chưa chạy máy.
