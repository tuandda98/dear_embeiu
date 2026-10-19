# 💻 Dev — Chọn giúp chúng mình (decision-wheel)

> Dev sở hữu. Đọc `overview.md` (D1–D20) + `design.md` trước.

- **Trạng thái dev:** xong, chờ test
- **Người/role:** Dev
- **Nhánh:** `feature/decision-wheel` (worktree `dear_embeiu-decision-wheel`, tách từ `feature/daily-open`)

## Cách làm

- **Ngân hàng:** `lib/data/dish_bank.dart` (117) + `lib/data/activity_bank.dart` (64) SINH từ 2 bảng md bằng `python3 scripts/gen-decision-banks.py`. Không sửa tay file .dart; thêm món = sửa md rồi chạy lại. Mỗi mục là `DecisionBankItem(id, vi, en, emoji, tags)`, `tags` gom mọi giá trị cột (dish: bữa/nơi/công; activity: nơi/tiền/lúc).
- **Logic quay thuần:** `lib/utils/decision_suggester.dart` (`DecisionSuggester.pool/next/reelFiller` + `validateCustomOptions`). Test: `test/decision_suggester_test.dart` (18 test).
- **Dữ liệu:** `lib/models/decision.dart` (model + hằng giới hạn khớp rules + `decisionDocId` + `normalizeDecisionName`), `lib/services/decision_service.dart`, `lib/providers/decision_provider.dart`.
  - Hôm nay = MỘT listener `where('date' == hôm nay)` (≤12 doc, index đơn) thay vì 2 get + 1 query.
  - 90 ngày = 1 lần `createdAt >= now−90d orderBy createdAt` mỗi phiên (cache trong provider) → loại 7/14 ngày, món tự thêm, top 5.
  - Chốt eat/go và quay lại custom = `runTransaction` (get → set hoặc update `spins+1`), timeout 10s. Custom mới = `set` id tự sinh; quá 10s coi như Firestore xếp hàng offline → SnackBar "Đang mất mạng…" (D19).
  - Wire: `main.dart` MultiProvider, `session_resolver` (named-param `decisionProvider` ở signature + call site; watch khi có couple, clear ở 3 nhánh sign-out/verify/no-couple), Home re-arm mỗi build + `refreshDay()` khi resume / qua 0:00.
- **UI:**
  - `lib/widgets/decision_card.dart` — thẻ Home 3 dòng, bọc `MidnightBuilder`, shimmer khi tải, `AnimatedSwitcher` 280ms.
  - `lib/widgets/decision_parts.dart` — helper hiển thị (tên theo ngôn ngữ người xem, emoji, tag, meta "Mình quay · 17:02", caption Chụp lại), 2 nút pill h52 dùng chung, link h44, `openDecisionWheel` (SnackBar sau chốt), `openDecisionHistory`, `openDecisionPhoto`, sheet kết quả (live theo provider).
  - `lib/screens/decision_wheel_screen.dart` — thanh 3 chế độ trượt 260ms, chip lọc Wrap, slot dọc 14 ô (13 ngẫu nhiên + kết quả) 900ms easeOutCubic, chạm khi đang quay = nhảy tới kết quả, Reduce Motion hiện ngay, scale 0.97→1 khi dừng, live region đọc kết quả 1 lần, dải lỗi + "Thử lại", sheet Nhập tay, form Tự nhập (placeholder xoay 3s, preset Ai làm?/Cái nào? có Hoàn tác, chip lựa chọn sửa/xoá, chặn trùng 2,5s, trần 12, cap 10 custom/ngày).
  - `lib/screens/decision_history_screen.dart` — 2 khối top 5 (xếp dọc khi chữ >1.3 hoặc màn <360), nhóm theo `date` của doc, 30/trang `startAfter`, loading/empty/error.
  - Home: thẻ chèn sau `MoodCard`, trước `SleepCard`, entrance index: Decision 5 · Sleep 6 · Rps 7 · tiêu đề Kỷ niệm 7 · ảnh 8.
- **Chụp lại (D8):** tách luồng camera của Gallery thành hàm dùng chung `captureAndPostPhoto` / `composeAndPostPhotos` (top-level trong `gallery_screen.dart`, Gallery gọi lại y như cũ). `CreatePostScreen` thêm `initialCaption` (caption điền sẵn chưa sửa thì đóng không hỏi). Khi bấm Đăng, Home chuyển sang tab Gallery để thấy overlay tải lên.
- **Nhắc (D10):** `ReminderService.scheduleDecisionReminder` (one-shot hôm nay, id 1200, bỏ nếu giờ đã qua) + `cancelDecisionReminder` (không cần initialize). `ReminderProvider.refreshDecisionReminder({coupleActive, decidedToday, l10n})` debounce theo ngày/giờ/locale, Hive `reminder_settings` khoá `decisionReminderEnabled` (mặc định true) + `decisionReminderMinute` (990 = 16:30), 5 câu xoay theo ngày. Home gọi khi DecisionProvider đổi, khi sync nhắc, khi resume. `cancelDailyQuestionSchedule` (đăng xuất/không couple) huỷ luôn 1200. Tile "Nhắc chọn món" trong Cài đặt → Thông báo, sau tile câu hỏi, ẩn khi chờ người ấy.
- **Push / inbox:** `NotificationTapRouter.focusDecision` + case `'decision'` (Home + cuộn tới thẻ). `AppNotificationType.decision` + field `decisionKind/result/resultId/question/respin`; Notification Center render đúng câu D5/D18 (món ngân hàng theo ngôn ngữ người xem), icon shuffle, tap → Home + focus. Handler nền: thêm đúng 1 hàm `_cancelMealReminderIfDecided` (`isTodayMealDecisionPush`: type decision + kind eat + date hôm nay).
- **Analytics (D12):** `decision_spin{kind,filter}` · `decision_commit{kind,spins,via,preset?}` · `decision_respin{kind}` · `decision_photo_cta{kind}` · `decision_history_open`. Không log result/question.
- **i18n:** 117 key mới cả `app_en.arb` + `app_vi.arb` (copy đúng design §10 + 4 key inbox `notifDecisionEat/Go/Custom/Respin`), `flutter gen-l10n`.

## Backend

- **`firestore.rules`** (additive): khối `match /decisions/{decisionId}` trong `couples/{coupleId}` + 2 hàm `isValidDecisionCreate` / `isValidDecisionRespin`.
  - Create: `hasOnly` 12 khoá (không có `lastPushAt`), bắt buộc kind/date/result/spins/byUserId/createdBy/createdAt; `createdBy == byUserId == auth.uid`; `createdAt == request.time`; `updatedAt` nếu có `== request.time`; date `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`; result 1..40; question ≤60; filter ≤20; resultId ≤40; `spins == 1`; eat/go: `id == date + '_' + kind` và options rỗng; custom: 2..12 options, `join('')` ≤480, `result in options`.
  - Update: chỉ `result/resultId/spins/byUserId/updatedAt`, `byUserId == auth.uid`, `spins == cũ + 1`, `updatedAt == request.time`, result 1..40, custom thì result phải thuộc options cũ. `lastPushAt` chỉ CF ghi được. Không delete.
- **Rules test:** `firebase_rules_test/test/firestore.decisions.test.js` 32 case. `scripts/test-firebase-rules.sh` → **390 passing**, 0 fail.
- **CF `notifyDecision`** (onWrite `couples/{coupleId}/decisions/{decisionId}`), lõi là `processDecisionWrite` (top-level, có unit test):
  - Xoá → bỏ. Update mà `result` không đổi → bỏ (gồm chính lần CF ghi `lastPushAt`).
  - Người nhận = memberIds trừ `byUserId`. Inbox luôn ghi `{type:'decision', kind, question, result, resultId, date, respin, decisionId, actorName}`.
  - Push giành chỗ bằng transaction trên `lastPushAt`: create luôn push (và đóng dấu), update trong 10 phút kể từ lần push trước → chỉ inbox. Push `wakeClients: true`, `data` = `type, coupleId, decisionId, kind, result, question, date, actorName` (đúng hợp đồng với widget-today; `data.lang` để Dev widget-today thêm trong `sendToRecipientDevices`).
  - Copy vi/en: create eat "{name} quay ra: hôm nay ăn {result}" / "{name} spun: {result} today"; go "{name} quay ra: {result}" / "{name} spun: let's {result}"; custom "{name} quay \"{q}\": {result}"; quay lại "{name} quay lại: {result}" / "{name} re-spun: {result}". Tiêu đề (tự chốt, spec không nói): eat "Hôm nay ăn gì?" / "What to eat?", go "Hôm nay đi đâu?" / "Where to go?", custom "Chọn giúp chúng mình" / "Decide for us".
  - Tái dùng `rpsLoadMemberIds`, `rpsLoadDisplayName`, `rpsToMillis`.
- **D11:** `deleteCoupleCompletely` liệt kê từng subcollection (không xoá đệ quy cả couple) → thêm `recursiveDelete(decisions)`. Ảnh hưởng `deleteAccount` + `leaveCoupleCleanup` (người cuối rời). Người rời còn người kia → giữ lịch sử.
- **Unit test CF:** 6 test mới trong `functions/test/index.test.js` (create push+inbox chỉ cho người kia + wake + data đúng; bob tạo → alice nhận; quay lại trong cooldown chỉ inbox; quá cooldown push câu "quay lại"; update không đổi result không làm gì; copy go/custom). `npm test` 18/18.

## Deploy

- ✅ **DEV** 2026-10-19 16:22 UTC: `deploy --project tonyembeiu-dev --only firestore:rules,functions:notifyDecision,functions:deleteAccount,functions:leaveCoupleCleanup` (chạy trong worktree, HEAD `1794e09`). notifyDecision tạo mới, 2 hàm kia update. Vết: `project/.firebase-deploy-log/20261019T162238Z-decision-wheel/` + dòng HISTORY. ⚠️ Hook tự ghi thêm 1 dòng cùng giờ ở **checkout chính** (snapshot rules của `f45f423`, không phải bản đã deploy) — dòng đó không dùng để restore.
- ⏳ **PROD chưa deploy** (chờ lệnh user, đi cùng 1.11.0): `deploy --project prod --only firestore:rules,functions:notifyDecision,functions:deleteAccount,functions:leaveCoupleCleanup`. Rules PROD phải lên trước khi 1.11.0 live.

## Kết quả lệnh

- `flutter analyze` → No issues found.
- `flutter test` → 610 pass (gồm 18 test mới), 3 skip có sẵn.
- `scripts/test-firebase-rules.sh` → CF unit 18/18 + rules 390 passing.
- `flutter build apk --debug` ✓ · `flutter build ios --debug --no-codesign` ✓ (pbxproj bị build sửa đã checkout lại).
- **Smoke Android emulator (Pixel 10, DEV, tài khoản Tuấn = test3, máy tiếng Anh):** thẻ nằm đúng sau thẻ tâm trạng, trước "Last night" · Spin ăn → chốt → doc `2026-10-19_eat` (spins 1, `lastPushAt` CF đóng dấu) + inbox ở máy Thảo · mở sheet → Quay lại → chốt → cùng doc spins 2, `lastPushAt` giữ nguyên (cooldown, chỉ inbox) · Tự nhập "Who does the dishes?" + preset Who does it? điền Tuấn/Thảo → quay → chốt → doc custom · Đi đâu → "play pool" lưu chữ thường, hiện "Play pool" · lịch sử: 2 khối top 5 + nhóm TODAY + badge ×2 · Cài đặt có tile "Dinner pick reminder" 4:30 PM bật. Ảnh ở scratchpad (không commit).
- Sửa sau smoke: SnackBar có action mặc định không tự tắt (Flutter mới) che nút của màn quay → `persist: false` + ẩn SnackBar khi mở màn quay; link chữ thiếu font Quicksand; thêm khoảng 12 dưới "Gần đây".

## Quyết định tự chốt (spec không nói / phải chọn)

1. **Tự nhập không áp luật "không lặp trong phiên"**: với 2 lựa chọn luật đó biến "Ai rửa bát?" thành A, B, A, B cố định. Chỉ eat/go không lặp.
2. **"Giờ < 10:00 thêm món sang"** hiểu là món `sang` ×2 (đối xứng với `toi` ×2 từ 14:00), không loại món sáng ở giờ khác.
3. **Món/chỗ tự thêm** chỉ vào pool của chip "Tuỳ" và chip mà nó được chốt (`filter` của doc), vì không có tag.
4. **Loại 7/14 ngày** so cả `resultId` lẫn tên chuẩn hoá (vi + en) → đổi ngôn ngữ vẫn không ra lại món vừa ăn.
5. `result` lưu tên ngân hàng **theo ngôn ngữ người quay** (en hoạt động giữ chữ thường để push "let's grab coffee"); app hiển thị lại theo ngôn ngữ người xem nhờ `resultId`.
6. Rules chặt hơn spec ở 3 chỗ: create `spins == 1`; custom `result in options` (cả create lẫn quay lại); `updatedAt == request.time`.
7. Cooldown đếm từ lần push gần nhất, **kể cả create** (quay lại ngay sau khi chốt chỉ vào inbox).
8. Không fallback Hive khi chưa có Firebase (thẻ chỉ có ở Home, cần couple) — chốt báo lỗi.
9. Đổi lựa chọn khi đang quay lại một custom cũ → chốt thành câu MỚI (rules ghim `options` khi update).
10. Placeholder câu hỏi đổi chữ mỗi 3s nhưng không crossfade (TextField không animate hint).

## Chưa kiểm được / rủi ro cho Tester

- **Push thật tới máy người ấy:** emulator không nhận FCM, iOS DEV thiếu APNs → chưa thấy banner/handler nền huỷ 1200 trên máy thật. Inbox đã kiểm bằng Firestore.
- **`pendingNotificationRequests` id 1200:** chưa kiểm (smoke lúc 23:29, 16:30 đã qua nên đúng là không arm). Cần chỉnh giờ máy trước 16:30.
- **Hai máy chốt eat cùng lúc**, **offline** (transaction timeout 10s → "Thử lại"; nếu mạng về đúng lúc, transaction cũ có thể vẫn chạy xong và "Thử lại" thành 1 lần quay lại thêm), **qua 0:00**, **Reduce Motion**, **chữ to**, **VoiceOver/TalkBack**: chưa chạy tay.
- "Chụp lại" chưa thử trên máy có camera (emulator có camera ảo nhưng chưa bấm).
- `deleteCoupleCompletely` vốn KHÔNG xoá `messages`, `moods`, `careMessages`, `games`, `receipts`… (nợ cũ, ngoài phạm vi) — chỉ thêm `decisions`.
- Mixed version (D13): app cũ hiện inbox `decision` bằng câu chung `notifGeneric`, push tap rơi về Home — đúng như spec chấp nhận, chưa thử máy 1.10.x.

## Chỗ sẽ đụng khi gộp với widget-today

- `lib/l10n/app_en.arb` + `app_vi.arb` + 3 file generated: cả hai nhánh cùng nối key vào cuối file → conflict dạng "cả hai thêm" ở dòng `}` cuối; gộp tay rồi `flutter gen-l10n`.
- `functions/index.js`: CF mới nằm trước khối "Oẳn tù tì"; sửa `deleteCoupleCompletely`. Không đụng `sendToRecipientDevices` / 4 CF cũ.
- `lib/services/push_notification_service.dart`: handler nền thêm 1 dòng `await _cancelMealReminderIfDecided(message);` cuối `firebaseMessagingBackgroundHandler` + hàm mới ngay dưới; thêm `focusDecision` + case `'decision'` trong `_applyRoute`.
- `lib/main.dart` (1 provider), `session_resolver.dart`, `home_screen.dart` (thẻ + entrance index + listener nhắc), `settings_screen.dart`, `reminder_service.dart` / `reminder_provider.dart`, `gallery_screen.dart` (tách hàm chụp).

## Nhật ký implement
- [2026-10-19] [Dev] Ngân hàng + suggester + service/provider + thẻ/màn quay/sheet/lịch sử + nhắc 1200 + tile + push/inbox + analytics + ARB (`fea6737`). Rules + 32 test + CF `notifyDecision` + 6 unit test + D11 (`1794e09`). Deploy DEV rules + 3 CF. Smoke Android emulator, sửa SnackBar che nút + font link.
