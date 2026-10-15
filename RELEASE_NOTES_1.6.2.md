# What's New — Dear Embeiu 1.6.2 (build 22)

> Copy vào **CẢ HAI**: App Store Connect → 1.6.2 → "What's New" · Google Play → "Có gì mới".
> ℹ️ 1.6.2 = **PATCH** bug-fix cụm câu hỏi hằng ngày (10 finding `/code-review max` 2026-09-12). ĐỤNG backend (rules + 2 CF) — deploy PROD cùng đợt.
> ⚠️ CHỈ nêu thay đổi CÔNG KHAI — KHÔNG nêu gate riêng tài khoản (band 1100–1159) hay chi tiết bảo mật.

## 🇻🇳 Tiếng Việt (primary)
```
Sửa lỗi câu hỏi hằng ngày 🌷

• Gửi câu trả lời ổn định hơn: nếu gặp lỗi mạng, app báo ngay để bạn thử lại thay vì quay vòng mãi.
• Nhắc trả lời câu hỏi đúng ngày hơn, không còn bị tắt nhầm khi thông báo hôm trước tới muộn.
• Để app mở qua đêm vẫn nhận đúng câu hỏi và chuỗi ngày của hôm nay.
• Sửa vài lỗi nhỏ khác để app chạy mượt hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
Daily question fixes 🌷

• Sending an answer is more reliable: on a network error the app tells you right away so you can retry.
• Daily-question reminders now stay on the right day and are no longer cancelled by a late notification from yesterday.
• Keeping the app open overnight now shows the correct question and streak for the new day.
• A few smaller fixes for a smoother experience.

Thanks for keeping your memories together with us 🌷
```

> 🍎 **App Store:** localization **Vietnamese** duy nhất → chỉ cần bản tiếng Việt.
> ⚠️ **ASC TỪ CHỐI EMOJI + có thể từ chối bullet "•"** trong "What's New" → dùng bản KHÔNG emoji dưới đây cho App Store. Google Play dùng bản có emoji bình thường.

### Bản dán cho App Store (không emoji)
```
Sửa lỗi câu hỏi hằng ngày

- Gửi câu trả lời ổn định hơn: nếu gặp lỗi mạng, app báo ngay để bạn thử lại thay vì quay vòng mãi.
- Nhắc trả lời câu hỏi đúng ngày hơn, không còn bị tắt nhầm khi thông báo hôm trước tới muộn.
- Để app mở qua đêm vẫn nhận đúng câu hỏi và chuỗi ngày của hôm nay.
- Sửa vài lỗi nhỏ khác để app chạy mượt hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm.
```

---

## Ghi chú nội bộ — 1.6.2 (build 22)

### Nội dung (10 finding code-review + 2 nhỏ — chi tiết `project/features/daily-question/dev.md` 2026-09-12)
1. 🔒 Rules `answerReactions` pin `answerAuthorUid ∈ memberIds` + CF `notifyDailyAnswerReaction` kiểm tra membership fail-closed (KHÔNG công khai).
2. `DailyQuestionProvider.submit`: snapshot câu đã hiện trước guard nửa đêm, engine chạy sau khi answer land.
3. Engine: `_publish` fail set cờ thật; `ResolvedQuestion.published` + retry throttle 60s; bên thua race có hint revisit.
4. Push `bothAnswered` kèm `date`; client chỉ huỷ band khi đúng hôm nay; resume invalidate + re-arm.
5. Sheet trả lời try/catch → SnackBar, hết kẹt spinner.
6. `updateContext(signalsReady)` đợi streak/mood có snapshot; listener mood.
7. Bank cạn → cycle mới no-repeat; id ngoài range không tính.
8. Sign-out huỷ band personal 1100–1159 (KHÔNG công khai).
9. `StreakProvider.recomputeIfDayChanged()`.
10. Copy "hai đứa" → "chúng mình"; comment band.

### Backend
**ĐỤNG backend** — `firestore:rules` (siết có chủ đích: author segment phải là member) + `functions:notifyDailyAnswerReaction` + `functions:notifyDailyAnswer` (thêm `date` vào data). Rules-test 244. DEV deployed 2026-09-12. PROD: xem release log CLAUDE.md.

### Pre-flight
- Flutter **3.41.6** (worktree `~/development/flutter-3.41.6`) · `flutter analyze` 0 · `flutter test` 83/83 · rules-test 244.

### Feature tour
KHÔNG thêm entry `sinceBuild: 22` — bug-fix, không có tính năng công khai mới.

### Force-update
Theo quyết định 2026-09-07: KHÔNG nâng `config/app.minBuildNumber` (autoStoreForce đã lo).
