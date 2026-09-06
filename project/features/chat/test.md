# Chat — Test report

> Tester sở hữu file này (PO dán hộ — tester read-only). Chỉ PASS/FAIL + bug, không fix.

## [2026-06-11] [tester] Nghiệm thu code-level D1–D9 / AC1–8 — **PASS-có-điều-kiện**

### Verify đã chạy (máy cty, fvm)
- `fvm flutter analyze` → No issues found ✅ · `fvm flutter test` → 18/18 ✅ · `./scripts/test-firebase-rules.sh` → 154 passing (gồm 10 case `messages` mới) ✅
- `git diff` backend: `firestore.rules` +18/-0, `functions/index.js` +131/-0 — **thuần additive** ✅
- DEV deploy có vết: `project/.firebase-deploy-log/20260611T113157Z` (rules, snapshot khớp working tree) + `20260611T113415Z` (`functions:notifyChatMessage`). PROD chưa deploy (đúng lệnh) ✅

### Bảng AC
| AC | Kết quả |
|---|---|
| 1. Nav 4 tab + deep-link cold/warm + regression type cũ | **PASS [VERIFIED]** — map đủ 3 đường (push tap hằng số 0/1/2, cold `_applyPendingTab`, warm listener, notif-center `targetHomeTab`); grep 0 index hardcode lệch; `_entrance` nguyên vẹn; TickerMode đủ 4 tab |
| 2. Realtime + offline queue + optimistic không dup | PASS code-level (latency-compensation cùng doc-id, `ValueKey` ổn định) — [CẦN TEST runtime 2 máy] |
| 3. Rules DENY đúng D3 | **PASS [VERIFIED]** — đối chiếu từng vế + 10 case test pass |
| 4. Push partner / không self / inbox / privacy | PASS code-level (pattern = notifyLoveNote, KHÔNG leak nội dung tin) — [CẦN TEST runtime] |
| 5. Phân trang 50+50 + teardown 3 nhánh resolver | **PASS [VERIFIED]** (edge bug #2) |
| 6. Unread dot theo marker seen | **PASS [VERIFIED]** (chỉ tin partner; race Hive-load đã guard) |
| 7. Ritual giữ / tile gỡ / history qua header chat | **PASS [VERIFIED]** |
| 8. l10n 13 key vi+en / analyze / test | **PASS [VERIFIED]** |

### Bug list (đều minor, không blocker)
1. **Send fail nuốt im lặng** · `chat_service.dart:114-123` + `chat_provider.dart:178-197` — `.catchError((_){})` nuốt rules-DENY thật (vd bị leave-couple khi tin nằm offline-queue) → bubble pending biến mất im lặng + haptic thành công. Đề xuất: cờ lỗi provider → SnackBar `chatSendFailed`.
2. **`hasMore`/cursor chốt từ emission đầu có thể là CACHE partial** · `chat_provider.dart:157-162` — snapshot đầu từ cache <50 doc → hasMore=false khoá session / gap tin. Fix: chỉ init từ snapshot `!metadata.isFromCache`.
3. **Cap 1000 đo 3 đơn vị** (grapheme UI / UTF-16 service / rules size) · `chat_screen.dart:248` vs `chat_service.dart:96-98` — 1000 emoji bị chém ~nửa im lặng, `substring` có thể cắt giữa surrogate pair. Fix: clamp bằng `characters` hoặc bỏ clamp service.
4. History animate entrance 1 lượt khi seed sớm · `chat_screen.dart:120-128` — cosmetic.
5. Thiếu case rules-test unauthenticated cho messages — coverage.
6. Semantics đĩa gửi không khai disabled khi ghost · `chat_screen.dart:284-286` — a11y.
7. Local-fallback Hive không cap size — nợ nhánh local.

Perf-note: `context.watch<ChatProvider>` ở HomeScreen → rebuild 4 tab mỗi emission; an toàn (entrance constant) nhưng tốn CPU nhẹ.

### [CẦN TEST runtime — 2 thiết bị, build debug → DEV]
1. **Deep-link regression số 1:** push `photo_posted`/`photo_reaction` cold+warm → tab 2 + đúng ảnh; `chat_message` → tab 1; 4 type cũ → tab 0; tap từng type từ notif-center.
2. Gửi 2 máy ≤1s; offline → pending mờ+clock → online tự rõ không duplicate.
3. Dot: bật khi partner gửi (đang ở tab khác) / tắt khi vào tab / persist sau kill / tin mình không bật.
4. Composer vs bàn phím iOS home-indicator + Android; nav ẩn/hiện 260ms.
5. Couple >50 tin → Xem thêm; waiting→active realtime; auto-read inbox theo tab mới.
6. Lock screen KHÔNG hiện nội dung tin; vi/en theo languageCode.

### Kết luận
**PASS-có-điều-kiện**: 8/8 AC code-level; điều kiện = checklist runtime trước khi deploy PROD. Đề nghị PO đưa #1/#2/#3 vào fix ngay hoặc nợ v1.1.

## [2026-06-11] [po-gate] Quyết định sau nghiệm thu
- Fix NGAY trong vòng này: #1 (mất tin im lặng — UX nguy hiểm), #2 (cache partial), #3 (emoji clamp), #6 (a11y 1 dòng). Ghi nợ: #4 (cosmetic), #5 (coverage), #7 (local cap) + perf-note.

## [2026-06-12] [po-gate] Vòng fix 4 bug — XONG, re-verify PASS
- **#1:** `ChatService.send` thêm `onServerReject` (catchError không nuốt nữa — chỉ bắn khi server TỪ CHỐI thật, offline thuần vẫn im lặng đúng thiết kế); `ChatProvider.sendRejections` counter (guard đúng couple); `ChatScreen` listener → haptic + SnackBar `chatSendFailed` (key sẵn có, không thêm ARB). Draft không khôi phục (user có thể đã gõ tiếp) — ghi nhận.
- **#2:** service emit `ChatWindow{messages, isFromCache}`; provider chỉ init cursor/hasMore từ snapshot `!isFromCache` (cache vẫn render tin, chỉ hoãn chốt phân trang).
- **#3:** BỎ clamp `substring` ở service (UI maxLength chặn đầu vào, rules là chốt cuối; tin quá dài bị reject sẽ nổi qua #1) — hết cắt emoji giữa surrogate pair.
- **#6:** Semantics nút gửi thêm `enabled: canSend`.
- `fvm flutter analyze` 0 issue · `fvm flutter test` 18/18. Nợ còn lại: #4/#5/#7 + perf-note. Chờ smoke-test runtime (danh sách trên) trước khi deploy PROD.
