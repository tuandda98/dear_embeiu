# 💻 Dev — Chọn giúp chúng mình (decision-wheel)

> Dev sở hữu. Đọc `overview.md` (D1–D20) + `design.md` trước.

- **Trạng thái dev:** đã vá 2 minor Tester vòng 2 (DW-R2-1, DW-R2-2), chờ Tester soát lại
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
7. ~~Cooldown đếm từ lần push gần nhất, kể cả create~~ → **[vá BUG-1] cooldown theo người quay** (`lastPushBy`): chỉ chặn khi cùng một người quay lại trong 10' sau lần push về họ.
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
- [2026-10-19] [Dev] Vá Tester vòng 1 (commit `41b2295`, nhánh `feature/daily-open`; deploy DEV từ HEAD `f0096a3`):
  - **BUG-1** `functions/index.js` `processDecisionWrite`: transaction đọc `lastPushAt` + `lastPushBy`, chỉ chặn push khi `!isCreate && lastPushBy == byUserId && < 10'`; mỗi lần push ghi cả 2. Rules không đổi điều kiện (2 khoá này vốn không nằm trong `hasOnly` của create lẫn `affectedKeys().hasOnly` của update ⇒ client không ghi được; thêm vào `hasOnly` sẽ MỞ cho client nên không thêm), chỉ sửa comment + test. Test CF: bỏ case "bob quay lại trong cooldown chỉ inbox" (đóng khung hành vi cũ), thêm "alice chốt → bob quay lại trong 10' → push tới alice" + "bob quay lại lần 2 trong 10' → chỉ inbox". Doc cũ chỉ có `lastPushAt` (DEV) → coi như người khác, push.
  - **BUG-2** `decision_card.dart:29`: bỏ `const` ở builder của `MidnightBuilder` (constructor giữ `const` vì lint `prefer_const_constructors_in_immutables`); body đã sẵn gọi `refreshDay()` post-frame mỗi lần build. Widget test `test/decision_card_midnight_test.dart` (pump 25h → `refreshDay` chạy lại); đã thử với code cũ → test FAIL.
  - **BUG-3** `decision_wheel_screen.dart` `onChanged` của ô câu hỏi: câu khác câu gốc → `_existingCustomId = null` (thành câu mới, giống đổi lựa chọn). Gõ lại đúng câu cũ vẫn là câu mới (chấp nhận).
  - **BUG-4** rules nhánh custom: `!decisionId.matches('^[0-9]{4}-[0-9]{2}-[0-9]{2}_(eat|go)$')` + test (id `{date}_eatx` vẫn được).
  - **BUG-5** rules: hàm `isDecisionOption(opts, i)` = `opts.size() <= i || (string, 1..40)`, gọi cho i = 0..11 (rules không có vòng lặp; `||` ngắt trước khi đọc ngoài mảng). Kiểm cả vị trí cuối của 12 lựa chọn, chuỗi rỗng, không phải chuỗi. Test 480 tổng cũ bỏ (giờ không vượt được 480 nếu từng mục ≤ 40). Client: `_canSpin`/`_spin` dùng `validateCustomOptions`; `_addOption` đi qua `validateCustomOptions` (trùng → nháy, quá số/dài → bỏ); preset "Ai làm?" cắt tên còn 40 (`_clipOption`, không cắt đôi cặp surrogate); hai tên trùng nhau → hiện dòng "trùng".
  - **BUG-6** `DecisionProvider.top` → `topOf` (static, thuần): khoá nhóm `id:<resultId>`, thiếu thì `name:<chuẩn hoá>`; dòng hiển thị vốn đã theo ngôn ngữ người xem (`decisionLine`). Push `decision` thêm `data.resultId`. Push lẫn tiếng: chấp nhận ở CF (PO chốt).
  - **BUG-7** `DecisionService.commit` trả thêm `spins` thật (transaction trả `spins+1` hoặc `1`); provider dùng nó cho bản lạc quan + `decision_commit.spins`; `decision_respin` log khi `spins > 1` (thay vì `previous != null`).
  - **BUG-8** chọn cách rẻ nhất không đụng rules: service giữ `_timedOut[docPath] = (result, Future)` khi transaction quá 10s. Lần chốt kế tiếp cùng doc chờ Future đó (thêm 10s): xong + cùng kết quả → trả luôn, không ghi lần 2; khác kết quả → ghi như quay lại; lỗi hẳn → ghi mới; vẫn treo → báo lỗi tiếp. Không dùng token vì phải thêm khoá vào rules + test. Giới hạn: lần chốt timeout rồi tự lọt, người dùng bỏ đó, lát sau quay lại ra ĐÚNG kết quả cũ → không ghi thêm (spins thiếu 1, không push) — hiếm, chấp nhận.
  - **NIT-9** `settings_screen.dart`: doc comment `_DailyQuestionTimeRow` về đúng chỗ trên class.
  - Kết quả: `flutter analyze` 0 · `flutter test` 632 pass / 3 skip (mới: midnight widget test, top 5 theo resultId) · `scripts/test-firebase-rules.sh` rules **392 passing** + CF **19/19**. Không đụng native ⇒ không build lại.
  - Deploy DEV 2026-10-19T16:55:53Z–16:57:28Z, HEAD `f0096a3`: `firestore:rules` + `notifyDecision, notifyDailyAnswer, notifyPartnerMood, sendPartnerPhotoNotification, notifyChatMessage, notifyPartnerLeft` → thành công. Vết: `project/.firebase-deploy-log/20261019T165553Z-daily-open/`. PROD chưa.
  - Tester soi: BUG-1 trên 2 máy (A chốt, B quay lại trong 2' → A có banner); BUG-8 khó tái hiện (tắt mạng lúc chốt, bật lại trong ~10–30s, bấm Thử lại → doc chỉ `spins` +1).
- [2026-10-20] [Dev] Vá Tester vòng 2 (commit `7d34e69`, nhánh `feature/daily-open`; deploy DEV từ HEAD `1895098`):
  - **Rules `size()` đếm gì** (đo trên emulator Firestore, test `firestore.decisions.test.js`): **đơn vị UTF-16**, không phải code point, không phải grapheme, không phải byte. 20 × 🍜 (40 đơn vị, 20 code point) qua `<= 40`; 21 × 🍜 (42) bị chặn; 8 × 👨‍👩‍👧 (40 code point, 64 đơn vị) bị chặn; 5 × 👨‍👩‍👧 (25 code point, 40 đơn vị) qua, thêm 1 chữ thì chặn; 40 chữ Việt có dấu (54 byte UTF-8) qua; `e` + dấu ghép rời ×21 (42) bị chặn. Tức là khớp `String.length` của Dart. (Đo trên emulator; giả định PROD cùng engine.)
  - **DW-R2-1** thước đo duy nhất `decisionTextSize` (`lib/models/decision.dart:36`, = `String.length`), dùng ở `validateCustomOptions`, `DecisionService.commit` (result + câu hỏi mới chặn > 60, `decision_service.dart:145`), formatter, counter. `DecisionLengthFormatter` (`lib/widgets/decision_parts.dart:36`) thay `maxLength` (đếm grapheme) ở 3 ô: câu hỏi (`decision_wheel_screen.dart:876`), lựa chọn (`:971`), Nhập tay (`:1505`); cắt theo ranh grapheme nên không bao giờ tách đôi emoji; đang gõ dở bằng IME (composing) thì để yên, xong mới cắt; ô đầy thì bỏ phím mới (như formatter của Flutter). Counter `decisionLengthCounter` đếm cùng thước đo (🍜 = 2), Nhập tay luôn hiện, câu hỏi hiện khi còn ≤ 10. `_addOption` không bỏ im lặng nữa: `_flash(issue)` (`:385/:396`) hiện dòng báo 2,5s như báo trùng; quá dài → key mới `decisionTextTooLong` ("Dài quá rồi, viết gọn lại chút nhé" / "Too long, try something shorter"), quá 12 → `decisionOptionsMax`. `_commit` kiểm câu hỏi trước khi gọi service (`:312`), quá dài thì báo + focus ô câu hỏi, không ghi. `_submit` Nhập tay chặn thêm theo thước đo (`:1458`). UI: chỉ thêm một dòng chữ helper cùng kiểu `_HelperLine` sẵn có, không thêm thành phần mới nên không tra lại skill.
  - **DW-R2-2** `sendToRecipientDevices` thêm `options.silent` (`functions/index.js:2590/:2671`): mỗi thiết bị một tin data-only (không `notification`, data không có title/body, không gọi `buildText`); iOS `apns-push-type: background`, `apns-priority: 5`, `aps.contentAvailable` (không alert/sound/badge); Android `priority: high`. `silent` thì bỏ companion. Caller không truyền `silent` không đổi (test "default callers unchanged"). `processDecisionWrite` (`:1777`): bị cooldown chặn → vẫn gọi với `{silent: true}`, cùng data hợp đồng (`type:'decision'`, kind, result, resultId, question, date, actorName, decisionId, coupleId + `lang` từng máy); không ghi `lastPushAt` (cooldown chạy tiếp). Client: `_handleForegroundMessage` thoát khi không có title/body ⇒ không banner foreground; handler nền đã xử lý `decision` (widget + huỷ 1200 nếu eat).
  - Test: `test/decision_length_test.dart` (6) · rules +2 test `size()` · CF: sửa test "bob quay lần 2 trong 10'" (nay có silent wake) + 2 test mới cho `sendToRecipientDevices` (silent; caller mặc định / wakeClients không đổi).
  - Kết quả: `flutter analyze` 0 · `flutter test` **638 pass / 3 skip** · `scripts/test-firebase-rules.sh` rules **394 passing** + CF **21/21**, exit 0 · `flutter build apk --debug` ✓ · `flutter build ios --debug --no-codesign` ✓ (pbxproj bị pod đảo thứ tự → `git checkout`, không commit) · `scripts/check-widget-daymath.sh` 32 checks OK.
  - Deploy DEV 2026-10-19T17:19:04Z–17:20:48Z (giờ VN 20/10 00:19), HEAD `1895098`: `functions:notifyDecision,notifyDailyAnswer,notifyPartnerMood,sendPartnerPhotoNotification,notifyChatMessage,notifyPartnerLeft` (đụng `sendToRecipientDevices` ⇒ deploy lại cả 6) → 6/6 "Successful update operation". Vết: `project/.firebase-deploy-log/20261019T171904Z-daily-open/` + dòng HISTORY. Rules không đổi ⇒ không deploy rules. PROD chưa.
  - Tester soi: (13) Nhập tay 40 🍜 → dừng ở 20, chốt được; dán chuỗi ZWJ dài; gõ Telex khi ô gần đầy. Silent wake iOS thật (DEV thiếu APNs key) — Apple có thể hoãn/bỏ background push khi máy tiết kiệm pin, khi đó widget đổi lúc mở app. Android: B quay lại trong 10' khi app A tắt → widget A đổi, không banner.
