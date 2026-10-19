# 🧪 Test — Widget "Hôm nay"

## Nghiệm thu code-level vòng 1 — 2026-10-19 (Tester, commit 21c75ca, nhánh feature/daily-open)

**Kết luận: PASS code-level** (0 critical · 0 major · 7 minor). Các mục [CẦN TEST runtime] chờ máy thật.

### Lệnh đã chạy
- `flutter analyze` → No issues found
- `flutter test` → 627 pass, 3 skip, 0 fail
- `scripts/check-widget-daymath.sh` → OK, 32 checks
- `./gradlew :app:testDebugUnitTest` → BUILD SUCCESSFUL
- `scripts/test-firebase-rules.sh` → rules 390 passing + functions 18 pass

### Bảng tiêu chí §5
| # | Tiêu chí | Kết quả |
|---|---|---|
| 1 | Nền, không mở app → widget ≤60s | Code PASS · CẦN TEST số đo iOS (DEV thiếu APNs). Android Dev đo ≈8s |
| 2 | Câu mới đè câu cũ, đúng copy/ngôn ngữ | PASS (minor B1, B3) |
| 3 | Mở app → khớp Home ≤2s | Code PASS · CẦN TEST (B6 nháy) |
| 4 | Qua 0:00 tự ẩn | Code PASS · CẦN TEST |
| 5 | Chạm đúng chỗ + 1 event `widget_tap` | Code PASS · CẦN TEST |
| 6 | Chờ người ấy / đăng xuất / rời → không dòng | PASS (minor B5) |
| 7 | Tinted, AX, tên dài | CẦN TEST |
| 8 | App 1.10.1 + push mới không vỡ | Code PASS · CẦN TEST |
| 9 | analyze/test/DayMath/JUnit/rules | PASS |
| 10 | CF DEV có vết, PROD chưa | PARTIAL (B7) |
| 11 | Tài liệu cập nhật | FAIL minor (B4) |

### Bug (minor)
- **B1** — Đổi ngôn ngữ trong app thì dòng trạng thái giữ ngôn ngữ cũ (`_pushWidgetStatus` không nghe `LocaleProvider`, `home_screen.dart:538`).
- **B2** — iOS: push chat/ảnh của hôm qua có thể thành "vừa nhắn" hôm nay (chat/ảnh không mang `date`; iOS `sentTime` thường null). Gợi ý: CF gửi `sentAt`.
- **B3** — Push nền decision hiện kết quả theo ngôn ngữ người quay (data thiếu `resultId`).
- **B4** — Tài liệu lệch code (trạng thái, TODO tích hợp, D6 `meal` vs `decision`).
- **B5** — Người ấy rời couple lúc app tắt → dòng cũ còn tới 0:00 (handler nền không xử lý `partner_left`).
- **B6** — Mở app lạnh có thể nháy câu cũ hơn (không chờ Chat/Photo/Decision nạp xong).
- **B7** — DEV chưa chạy code gộp; vết deploy nằm ở checkout chính, sai HEAD.

### Rủi ro ghi nhận
- Android 2×2 cỡ chữ 200%: ô 16dp vs autosize min 10sp → nghi cắt mép dọc.
- iOS hạn mức push nền / `reloadAllTimelines` khi chat dày.
- Receiver exported (bắt buộc): app khác chỉ làm widget vẽ lại; URL/intent giả chỉ mở tab whitelist.

### Smoke tay trên máy thật (DEV, cặp test3/test4)
1. Android: A tắt hẳn app, B trả lời câu hỏi → bấm giờ tới khi widget A hiện "B đã trả lời, đến lượt mình".
2. Lặp với tâm trạng, nhắn, ảnh, chốt món; cả vi lẫn en.
3. iPhone (không force-quit) lặp bước 1, ghi số giây (cần APNs key DEV).
4. Mở app A: widget khớp Home ≤2s, để ý nháy.
5. Đổi ngôn ngữ trong Cài đặt → dòng trạng thái đổi theo.
6. Chạm widget ở từng loại câu → đúng tab/thẻ, 1 event `widget_tap`.
7. Chỉnh giờ 23:59 → qua 0:00 app tắt: iOS mất dòng đúng 0:00, Android ≤30'.
8. Đăng xuất / rời couple / B rời lúc A tắt app → không còn dòng.
9. Tinted + AX5 (iOS), cỡ chữ 200% (Android), tên 12 ký tự + "hôm nay: căng thẳng".
10. Android không có dòng: so pixel với 1.9.1.
11. Máy cài 1.10.1 nhận đủ 5 loại push: không crash, không banner thừa.

## Vòng 2 — 2026-10-20 (Tester, `c7f2a01`, vá ở `f0096a3`) + review toàn nhánh

**Kết luận: PASS code-level** — 0 critical · 0 major · 1 minor mới. analyze 0 · flutter test 632 / 3 skip · rules 392 + CF 19/19 · DayMath 32 · JUnit ✓ · apk debug ✓ (plugin local build được).

- B1, B2, B3, B5, B6, B7: **FIXED**. B2 xác nhận: bỏ push iOS thiếu `sentAt` chỉ ảnh hưởng trước khi PROD deploy CF (CF chat/ảnh trên PROD chưa wake nên iOS vốn không chạy handler nền). B4: phần Dev xong, phần PO xong ở vòng này.
- **WT-R2-1 (minor)** — `partner_left` không mang mốc thời gian: push tới trễ/đảo thứ tự có thể xoá dòng của couple mới, hoặc để push chat cũ của người đã rời hiện lại. Gợi ý: CF gửi `sentAt`, client xoá chỉ khi dòng đang lưu cũ hơn mốc đó.
- Review toàn nhánh: không regression; kênh widget Android trong plugin đăng ký cả engine chính lẫn engine nền, đủ 4 method, prefs khớp `WidgetStore`.
- Smoke thêm: (12) đổi ngôn ngữ khi Home mở → dòng đổi ≤1s; (13) B rời lúc app A tắt → dòng mất, số ngày còn; (14) iOS push chat CF mới → ghi `sentTime` có null không.

### Vòng 3 — re-review 3 bản vá (2026-10-20, HEAD `c4d91de`) — **PASS**
- flutter analyze 0 · flutter test 638 pass / 3 skip · rules 394 passing + CF 21/21. Không deploy.
- DW-R2-1 FIXED: `decisionTextSize` (UTF-16) khớp rules `size()` (đo trên emulator: `size()` đếm đơn vị UTF-16); formatter cắt theo grapheme, không phá IME; `_addOption` báo lỗi; câu hỏi kiểm trước khi chốt.
- DW-R2-2 FIXED: cooldown gửi push im lặng (`silent`: data-only, iOS background priority 5), không ghi `lastPushAt`; caller khác không đổi. CẦN TEST iOS thật nhận background wake.
- WT-R2-1 FIXED: `clearIfOlder` + `clearedAt` nhất quán Dart / iOS / Android; `state=empty` xoá cả hai. Rủi ro minor chấp nhận: lệch đồng hồ máy có thể chặn nhầm 1 push thật vài phút, tự hết khi mở app. CẦN TEST: B rời → ghép C → C nhắn → widget A hiện C.
- Bug mới: không. **Kết luận chung: PASS code-level, chờ smoke máy thật.**
