# Endless questions — Test (Tester sở hữu)

## [2026-09-05] [Tester] Vòng 1 code-level (commit e613e70) — ❌ FAIL → [Dev] đã vá cùng ngày → chờ vòng 2 / smoke-test 2 máy + key AI thật

Pre-flight: analyze 0 · test 81/81 · rules-test 238 · `node --check functions/index.js` OK.

### PASS (verified)
- Marker = nguồn sự thật: `_publish` transaction first-writer-wins, loser adopt; fail-soft toàn tuyến (không Firebase → bank cũ; `questionState` denied → state rỗng, không loop).
- Data: 150 câu extra + 88 template đủ vi+en, không `{}`/`<>`/"hai đứa", ≤280.
- Revisit riêng tư: câu chung chỉ trích câu hỏi cũ; hint đọc đúng `responses/{myUid}`, không vào marker; timeout 5s bao trọn.
- CF `generateDailyQuestion`: auth+member, idempotent, ẩn danh A/B, validate + chống trùng, `refusal`, không throw runtime, không `temperature`, secret `unset` → `no_api_key`.
- Rules `questionState` additive + `aiQuestionsEnabled` optional bool.

### FAIL → trạng thái sau khi Dev vá (cùng ngày)
| # | Mức | Bug | Vá |
|---|---|---|---|
| 1 | P0 | Engine resolve với context RỖNG trên cold start (`session_resolver` gọi `watchForCouple` trước Home ⇒ revisit/mốc/mood/streak hook chết; T7/CN có thể bắn câu SAI "chưa có ảnh") | ✅ `DailyQuestionProvider._contextReady`: KHÔNG resolve cho tới khi Home gọi `updateContext` (Home gọi trước `watchForCouple`). `photosThisWeek` mặc định -1 (unknown) và Home truyền -1 khi list ảnh rỗng ⇒ hook "chưa có ảnh" không bao giờ đoán. |
| 2 | P1 | Mixed-version: app 1.5.0 ghi đè `questionVi/En` engine trên marker | ✅ rules: `questionVi/En` BẤT BIẾN khi đã tồn tại (client cũ merge khác → DENY, nuốt trong try/catch; `bothAnswered` CF vẫn stamp). +3 rules-test. ⚠️ Vẫn còn: bản cũ HIỂN THỊ câu bank khác ⇒ sau khi 1.6.0 live 2 store nên nâng `config/app.minBuildNumber`=20. |
| 3 | P1 | CF nhận `date` tuỳ ý, không rate-limit ⇒ đốt tiền | ✅ chỉ nhận `date` = hôm nay ±1 (UTC); `aiAttempts` trên marker qua transaction, cap 3/cặp/ngày → `rate_limited`. App Check KHÔNG bật (app chưa tích hợp firebase_app_check — nợ). |
| 4 | P2 | `submitAnswer` marker get-then-set (offline ghi đè) | ✅ `runTransaction`. |
| 5 | P2 | Sheet trả lời lệch câu khi engine còn đang resolve; `isResolvingQuestion` không ai dùng | ✅ `_openAnswerSheet` chặn + toast `dailyQuestionPreparing` khi đang resolve. |
| 6 | P2 | EN "1 days" | ✅ post-process `1 days`→`1 day`. ⏳ copy `look_back` khi mốc đã qua chưa sửa. |
| 7 | P2 | Ghi `questionState` cả khi publish thất bại | ⏳ chưa sửa (chỉ ảnh hưởng độ đa dạng). |
| 8 | P2 | Hint revisit mất ở máy kia/sau restart | ✅ engine `_withRevisitHint` dựng lại từ `refDate` khi đọc marker. |
| 9 | P2 | Switch AI kẹt ON khi ghi bị từ chối; stream tạo mỗi build; không nói "áp dụng từ mai" | ✅ `setAiQuestionsEnabled` trả bool → revert + toast `aiQuestionsSaveFailed`; stream hoist 1 lần/couple; dialog thêm "bắt đầu từ câu hỏi ngày mai". |

### Chỉ test được runtime
2 máy cùng ngày (race publish/adopt); CF với key thật (`claude-opus-5` + `output_config.json_schema` trên SDK 0.124); PROD chưa deploy; chi phí thực; offline `get()` trên thiết bị.

## Vòng 2 — [2026-09-05] [Tester] Xác minh 9 bản vá (commit `fe53eaa`) — ✅ PASS mục tiêu, phát hiện 1 P1 mới → [Dev] đã vá cùng ngày
Pre-flight: analyze 0 · test 81/81 · rules-test 241 · `node --check` OK · 2 probe rules trên emulator (merge `{date,updatedAt}` lên marker đã có câu = ALLOW; publish lên marker `{date,aiAttempts}` = ALLOW; client cũ DENY bị nuốt; `size()` đếm ký tự).
| # | Mức | Bug mới | Vá |
|---|---|---|---|
| B5 | **P1** | CF stamp `bothAnswered` KHÔNG kèm `date`; marker do CF tạo mới bị `orderBy('date')` của streak/journal LOẠI (verified emulator); transaction client không có mutation-queue offline nên dễ rơi vào cảnh này hơn | ✅ CF stamp thêm `date`; `submitAnswer` khi transaction fail → fallback `set(merge)` xếp hàng offline (rule bất biến giữ an toàn). Deploy DEV trace `20260905T122337Z`. |
| B1 | P2 | `clear()` không reset `_contextReady`/context ⇒ đổi tài khoản không kill app resolve bằng context couple cũ | ✅ reset đủ trong `clear()`. |
| B3 | P2 | `photos.isEmpty ? -1` vô hiệu hook "chưa có ảnh" đúng với couple chưa có ảnh | ✅ dùng `PhotoProvider.isLoading`. |
| B2 | P2 | `_contextReady` chưa đảm bảo streak/mood đã emit ở frame đầu (bỏ lỡ hook, không bắn sai) | ⏳ [CẦN TEST runtime]. |
| B8 | P2 | Chặn trả lời khi resolve mà không có tín hiệu; AI tới 15s | ✅ caption "Đang chuẩn bị câu hỏi…" trên card khi resolving; AI timeout 8s. |
| B4 | P2 latent | Marker `questionVi: ''` khoá vĩnh viễn | ✅ rules coi chuỗi rỗng là chưa có (`get('questionVi','') == ''`); +2 test → **243**. |
| B6 | P3 | Hint dựng lại cắt khác bản gốc | ✅ dùng chung `truncateForQuote`. |
| B7 | P3 | Handler toggle cũ xoá `_pending` mới | ✅ `_toggleSeq`. |
| B9 | P3 | Trả lời đúng lúc qua nửa đêm ghi câu bank | ⏳ nợ (hiếm). |
| #7 v1 | P2 | Ghi `questionState` cả khi publish fail | ✅ `_publishFailed` → bỏ record. |
| #6 v1 | P2 | Copy `look_back` khi mốc đã qua | ✅ lọc `look_back` khi `offset < 1`. |
Nợ test: chưa có unit test cho `_contextReady`/`1 day`/hint rebuild (81 test không đổi).
