# 🧪 Test — Chọn giúp chúng mình (decision-wheel)

## Vòng 1 — 2026-10-19 (Tester, `feature/daily-open` @ `21c75ca`)

**Kết luận: FAIL code-level** — 1 major + 7 minor + 1 nit. analyze 0 · flutter test 627 pass / 3 skip · rules 390 passing (32 case `decisions`) + CF unit 18/18. Rules DEV = rules HEAD; PROD chưa deploy.

### Bảng 14 tiêu chí §5
| # | Kết quả |
|---|---|
| 1 Thẻ đúng vị trí, có khi chờ người ấy | PASS |
| 2 Ăn gì: lọc 7 ngày, chip, giờ | PASS (unit) |
| 3 Đi đâu: lọc 14 ngày, chip | PASS (unit) |
| 4 Tự nhập: preset, 2–12 | PASS logic · push CẦN TEST |
| 5 Chốt eat → push/inbox/widget/huỷ 1200/quay lại | PASS code · CẦN TEST · BUG-1 chiều ngược |
| 6 Quay không chốt → không ghi | PASS |
| 7 Chụp lại | PASS code · camera CẦN TEST |
| 8 Lịch sử | PASS code (BUG-6) |
| 9 Nhắc 1200 | PASS code · CẦN TEST pending |
| 10 Qua 0:00 thẻ về trống | **FAIL** (BUG-2) |
| 11 Rules ≥20 case | PASS (32) · hở BUG-4, BUG-5 |
| 12 CF create/cooldown/không gửi byUserId/wake | PASS unit · BUG-1 |
| 13 i18n + test | PASS |
| 14 Không regression | PASS code · smoke CẦN TEST |

### Bug
- **BUG-1 (major)** — người ấy Quay lại trong 10' sau khi mình chốt → mình chỉ có inbox, không push/wake (`functions/index.js:1729-1745`, cooldown tính cả push của create). Trái D2 "báo ngược lại".
- **BUG-2 (minor, fail #10)** — `decision_card.dart:27` `MidnightBuilder` trả `const _DecisionCardBody()` → không rebuild lúc 0:00.
- **BUG-3** — Quay lại câu tự nhập rồi sửa câu hỏi → update doc cũ với câu cũ.
- **BUG-4** — rules cho doc `custom` chiếm id `{date}_eat|_go` → kẹt cả ngày.
- **BUG-5** — không kiểm mỗi lựa chọn ≤40 ở rules; preset tên dài không validate (`validateCustomOptions` không được dùng).
- **BUG-6** — couple khác ngôn ngữ: top 5 tách đôi (nhóm theo tên thay vì `resultId`); push lẫn tiếng.
- **BUG-7** — chốt khi listener chưa thấy doc người ấy → UI/analytics `spins` sai.
- **BUG-8** — timeout 10s rồi "Thử lại" có thể ghi 2 lần (×2, log 2 lần).
- **NIT-9** — doc comment `_DailyQuestionTimeRow` bị tách (`settings_screen.dart:2147`).

### Smoke tay (2 máy thật, DEV test3/test4, có push)
1. A chốt Ăn gì → B banner + inbox ≤10s; thẻ B ≤3s; widget B "Hôm nay ăn: …".
2. B mở app trước 16:30 → có id 1200; A chốt eat lúc app B đóng → 1200 của B biến mất.
3. B Quay lại trong 2' → A (app đóng) có banner.
4. Hai máy Chốt eat cùng lúc → 1 doc, `spins=2`, không crash.
5. Máy bay: eat → dải lỗi + Thử lại; custom → "Đang mất mạng…", có mạng thì máy kia nhận push.
6. Để Home mở qua 0:00 thật → thẻ về trống.
7. Reduce Motion → hiện ngay; chạm khi quay → nhảy kết quả.
8. Chụp lại bằng camera → caption "Bún chả 🍜", ảnh lên Gallery; nút Chụp hình Gallery vẫn chạy.
9. Máy 1.10.x nhận push `decision` → tap về Home, inbox câu chung.

## Vòng 2 — 2026-10-20 (Tester, `c7f2a01`, vá ở `41b2295`) + review toàn nhánh

**Kết luận: PASS code-level** — 0 critical · 0 major · 2 minor mới. analyze 0 · flutter test 632 / 3 skip · rules 392 + CF 19/19 · apk debug ✓.

- BUG-1…8 + NIT-9: **FIXED** (verify từng cái). BUG-1: không vòng lặp onWrite; một người quay một mình ≤1 push/10'/doc, hai người thay phiên thì mỗi lần đổi người = 1 push tới đúng người vừa bấm Chốt (chấp nhận). BUG-5: `isDecisionOption(opts, i)` i=0..11 đúng với 2..12, rỗng, không phải string. BUG-8: "Thử lại" có thể chờ ~20s mới báo lỗi (chấp nhận).
- **DW-R2-1 (minor)** — ô nhập đếm grapheme (emoji = 1), service/rules đếm khác → Nhập tay có emoji dài 40 kẹt "Thử lại"; ô lựa chọn bỏ im lặng.
- **DW-R2-2 (minor)** — quay lại trong cooldown không gửi gì kể cả wake → widget người ấy giữ kết quả cũ.
- Review toàn nhánh: không regression (session_resolver, listener, Gallery tách hàm, MainActivity/plugin, SceneDelegate, ARB, văn phong, không thêm quyền).
- Smoke thêm: (10) B quay lại sau 1' → A có banner; (11) B quay thêm trong 10' → A chỉ inbox; (12) tắt mạng lúc chốt rồi Thử lại → `spins` +1; (13) Nhập tay có emoji dài 40.

### Vòng 3 — re-review 3 bản vá (2026-10-20, HEAD `c4d91de`) — **PASS**
- flutter analyze 0 · flutter test 638 pass / 3 skip · rules 394 passing + CF 21/21. Không deploy.
- DW-R2-1 FIXED: `decisionTextSize` (UTF-16) khớp rules `size()` (đo trên emulator: `size()` đếm đơn vị UTF-16); formatter cắt theo grapheme, không phá IME; `_addOption` báo lỗi; câu hỏi kiểm trước khi chốt.
- DW-R2-2 FIXED: cooldown gửi push im lặng (`silent`: data-only, iOS background priority 5), không ghi `lastPushAt`; caller khác không đổi. CẦN TEST iOS thật nhận background wake.
- WT-R2-1 FIXED: `clearIfOlder` + `clearedAt` nhất quán Dart / iOS / Android; `state=empty` xoá cả hai. Rủi ro minor chấp nhận: lệch đồng hồ máy có thể chặn nhầm 1 push thật vài phút, tự hết khi mở app. CẦN TEST: B rời → ghép C → C nhắn → widget A hiện C.
- Bug mới: không. **Kết luận chung: PASS code-level, chờ smoke máy thật.**

## Smoke runtime 2026-10-20 (Lead, tự động Maestro + adb · DEV · Android Pixel 10 = test3 Tuấn en→vi · iPhone 17 Pro sim iOS 26.3 = test4 Thảo vi)
- ✅ (1) B chốt Ăn gì lúc app A đã kill → A nhận banner "Thảo spun: Bánh khọt today" + widget A "Today's meal: Mini savory pancakes" (tên theo ngôn ngữ người xem) ≤10s.
- ✅ Chạm widget → Home cuộn đúng thẻ "Can't decide?" (focus `decision`).
- ✅ A Quay lại → thẻ B cập nhật realtime ≤3s ("Miến gà, Tuấn quay · ×2").
- ✅ (10) B quay lại sau lượt push của A → A có banner "Thảo re-spun: …" (vá BUG-1 chạy thật).
- ✅ (11) B quay thêm trong 10' → A KHÔNG có banner mới, widget vẫn đổi "Hotpot at home" (silent wake DW-R2-2).
- ✅ Tự nhập trên iOS: câu có emoji "Tối nay ai rửa bát 🍽️🧽" + preset "Ai làm?" → A push `Thảo spun "…": Tuấn`, widget 4×2 hiện câu + kết quả, 2×2 "Spun: Tuấn".
- ✅ Đi đâu (A) → thẻ B + inbox B "Tuấn quay ra: Chơi game cùng nhau"; inbox "Tuấn quay lại: Miến gà".
- ✅ (5)(12) Máy bay: chốt eat → dải lỗi "Couldn't lock it in…" + Try again; bật mạng → Thử lại → chốt, `spins` 4→5.
- ✅ (2) Reminder 1200: xoá doc eat hôm nay → mở A có id 1200; B chốt lúc A kill → 1200 biến mất (handler nền). Push tiếng Việt theo `languageCode` mới.
- ✅ (8) Chụp lại (camera emulator) → CreatePost caption "Thịt rang cháy cạnh 🥓" → đăng lên Gallery; nút Chụp hình của Gallery vẫn chạy.
- ✅ (7) Reduce Motion (animator scale 0) → kết quả hiện ngay.
- ✅ Lịch sử: 2 khối Hay ăn/Hay đi + nhóm Hôm nay. Cài đặt có tile "Nhắc chọn món 16:30".
- ⏭️ Không chạy được: (3)(9) push tới iOS (DEV thiếu APNs) · (4) 2 máy chốt cùng lúc (đã có test transaction) · (6) qua 0:00 thật (có `decision_card_midnight_test`).
- ℹ️ Simulator iOS 26.3 vẽ MỌI emoji Text thành ô "?" (cả chat cũ) — lỗi môi trường đã biết từ 1.10.2, không phải code.
- **Kết luận: PASS runtime trên các ca chạy được.**
