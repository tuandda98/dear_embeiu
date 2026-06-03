# 💻 Dev — Daily Question (Câu hỏi mỗi ngày, #5)

> Dev sở hữu. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2). Mẫu: love-note (#4).

- **Trạng thái dev:** xong — chờ test (chưa deploy rules/functions; PO deploy sau)
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Mô hình:* mỗi ngày 1 câu hỏi chung cho cả 2 (chọn theo day-of-year mod length → cùng ngày = cùng câu). Mỗi người trả lời 1 doc. Reveal câu của partner **chỉ sau khi bạn đã trả lời** — enforce ở provider (`hasRevealed`), rules cho member đọc cả 2 (reveal là UI affordance, chấp nhận v1). Ngày = giờ máy local (LDR lệch múi giờ — chấp nhận v1). KHÔNG streak v1.
- *Firestore:* `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}` = `{authorUserId, text, answeredAt}`. ≤2 doc/ngày.
- *File tạo:*
  - `lib/data/daily_questions.dart` — bank 58 câu vi/en + `questionForDate`/`questionTextForDate` (dayOfYear mod length).
  - `lib/models/daily_answer.dart` — model + fromDoc/toMap.
  - `lib/services/daily_question_service.dart` — `dateKey`, `watchResponses`, `submitAnswer`; local-fallback Hive box `daily_answers_local` (no-crash).
  - `lib/providers/daily_question_provider.dart` — `watchForCouple/todayQuestion/myAnswer/partnerAnswer/hasRevealed/isLoading/submit`; tự resubscribe khi đổi ngày (rollover) + sau submit ở fallback (stream là one-shot).
- *File sửa:*
  - `lib/main.dart` — đăng ký `DailyQuestionProvider`.
  - `lib/app/session_resolver.dart` — wire watch khi couple active / clear khi sign-out/no-couple.
  - `lib/screens/home_screen.dart` — card `_buildDailyQuestionCard` + widget `_DailyQuestionCard` (đặt **ngay sau** card Lời nhắn #4, `_entrance(6, …)`); re-arm watch trong build như love-note. Import `confetti`.
  - `lib/services/push_notification_service.dart` — `_handleNotificationTap`: `'daily_question'`→home tab 0.
  - `firestore.rules` — khối ADDITIVE `dailyAnswers/{date}/responses/{uid}` cạnh `notes` (read: member; write: own uid + authorUserId==uid + text string ≤280).
  - `functions/index.js` — `exports.notifyDailyAnswer` (onDocumentCreated) gửi FCM cho partner (copy vi/en `DAILY_QUESTION_COPY`, data `{type:'daily_question', coupleId}`); `deleteCoupleCompletely` thêm `db.recursiveDelete(coupleRef.collection('dailyAnswers'))`.
  - ARB en/vi: 10 key `dailyQuestion*` + `flutter gen-l10n`.
- *Cần deploy?* **rules + functions** (PO deploy). Nếu chưa deploy: client write bị rules cũ chặn (subcollection mới) → an toàn vì local-fallback không crash; push không gửi.

## Edge case kỹ thuật đã xử lý
- Local-fallback (`!isUsingFirebase`): Hive lưu chỉ answer của máy này; service không crash; provider resubscribe sau submit để UI cập nhật ngay.
- Day rollover khi app mở: `watchForCouple` so cả `dateKey` → resubscribe sang câu mới.
- Confetti **bắn đúng 1 lần**: flag `_confettiPlayed` init = `provider.hasRevealed` (mở lại Home đã reveal → KHÔNG bắn), chỉ bắn ở transition fresh reveal; key card theo couple+question để reset state đúng.
- Clamp text 280 cả client (service) + rules. Trim rỗng → submit no-op.
- `waiting_partner` (chưa có partner): vẫn cho trả lời, ghi chú "sẽ mở khoá khi người ấy tham gia & trả lời", không lỗi.
- recursiveDelete dọn subcollection lồng + phantom doc khi xoá hẳn couple (deleteAccount/leave sole-member).

## Checklist implement
- [x] Bank 58 câu vi/en + chọn theo day-of-year
- [x] Model + service (local-fallback) + provider
- [x] Đăng ký provider main.dart + wire session_resolver
- [x] Card Home sau card Lời nhắn (#5), 3 trạng thái + confetti 1 lần
- [x] Rules ADDITIVE dailyAnswers
- [x] CF notifyDailyAnswer + recursiveDelete trong deleteCoupleCompletely
- [x] Deep-link `daily_question`→home0
- [x] 10 key l10n vi+en + gen-l10n
- [x] `node --check functions/index.js` pass
- [x] `flutter analyze` sạch (No issues found!)
- [x] Không hardcode chuỗi (qua l10n)

## Nhật ký implement
- [2026-06-02] [Dev] Implement full-stack #5 Daily Question (mẫu love-note). Tạo `data/daily_questions.dart` (58 câu), `models/daily_answer.dart`, `services/daily_question_service.dart` (Firestore `dailyAnswers/{date}/responses/{uid}` + Hive fallback), `providers/daily_question_provider.dart` (reveal gate `hasRevealed`, resubscribe rollover+fallback). Wire main.dart + session_resolver. Card Home `_DailyQuestionCard` đặt sau Lời nhắn: input ≤280 + đếm ký tự + Gửi (haptic), trạng thái "đã trả lời/chờ", reveal 2 câu có nhãn + confetti 1 lần (flag init=hasRevealed). Rules ADDITIVE. CF `notifyDailyAnswer` + recursiveDelete dailyAnswers khi xoá couple. Deep-link `daily_question`→home0. 10 key l10n vi+en. node --check + analyze sạch. **Chưa deploy** (PO).
