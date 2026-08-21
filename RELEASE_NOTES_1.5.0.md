# What's New — Dear Embeiu 1.5.0 (build 19)

> Copy vào **CẢ HAI**: App Store Connect → 1.5.0 → "What's New" · Google Play → "Có gì mới".
> ⚠️ CHỈ nêu thay đổi CÔNG KHAI — không nêu chi tiết kỹ thuật / gate tài khoản riêng.
> ℹ️ 1.5.0 = **MINOR** (tính năng mới: thả react cho câu trả lời hằng ngày) + gồm luôn `targetSdk 36` của 1.4.3.

## 🇻🇳 Tiếng Việt (primary)
```
Thả cảm xúc cho câu trả lời của người ấy 💕

❤️ Sau khi cả hai đã trả lời câu hỏi hôm nay, bạn có thể thả cảm xúc cho câu trả lời của người ấy — chạm để thả tim, giữ để chọn trong 6 biểu tượng.
📖 Thả được cả trong Nhật ký câu hỏi, nên những ngày cũ vẫn nhận được yêu thương.
🔔 Người ấy sẽ nhận thông báo ngay khi bạn thả cảm xúc.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
React to your partner's answer 💕

❤️ Once you've both answered today's question, you can react to your partner's answer — tap for a heart, hold to pick from six reactions.
📖 It works in the Question Journal too, so older days can still get some love.
🔔 Your partner gets a notification the moment you react.

Thanks for keeping your memories together with us 🌷
```

> 🍎 **App Store:** app này Apple chỉ có localization **Vietnamese** (xác nhận ở 1.4.2) → chỉ cần dán bản tiếng Việt.

---

## Ghi chú nội bộ — 1.5.0 (build 19)

### Nội dung
1. **MỚI — thả react cho câu trả lời câu hỏi hằng ngày** (feature `daily-question reactions`).
   Chi tiết thiết kế + lý do ở `project/features/daily-question/dev.md` (log 2026-08-22).
2. **Gồm luôn `targetSdk` 35→36** (nội dung của 1.4.3+18) ⇒ **1.5.0 tự nó thoả deadline Google Play 31/8/2026.**

### ⚠️ Quan hệ với 1.4.3+18
1.4.3+18 đã build + verify xong nhưng **chưa upload store nào**. 1.5.0 nằm trên nhánh kế thừa
1.4.3 nên **đã chứa targetSdk 36** ⇒ ship 1.5.0 là đủ, **không cần ship 1.4.3 riêng**.
Artifact 1.4.3 được giữ lại làm **phương án dự phòng** ở `build/_keep_1.4.3+18/` — nếu 1.5.0
bị store từ chối hoặc phát hiện lỗi sát deadline thì nộp ngay 1.4.3 (đã verify, rủi ro gần
bằng 0 vì chỉ đổi 1 dòng gradle).

### ⚠️ BACKEND — BẮT BUỘC deploy TRƯỚC/CÙNG lúc release
```
deploy --only firestore:rules,firestore:indexes,functions:notifyDailyAnswerReaction --project prod
```
- `firestore.rules`: nested write rule + recursive collection-group read cho `answerReactions` (**ADDITIVE** — không siết gì đang chạy).
- `firestore.indexes.json`: fieldOverride `answerReactions.coupleId` scope COLLECTION_GROUP (thiếu index ⇒ query stream fail).
- `functions/index.js`: CF mới `notifyDailyAnswerReaction`.

**Chưa deploy ⇒ tính năng hỏng hẳn**: ghi react bị `permission-denied`, stream lỗi, không có push.
An toàn với client cũ: bản 1.4.x không biết `answerReactions` nên không đọc/ghi gì ở đó.

### Pre-flight (chạy thật 2026-08-22)
- `flutter analyze` → **No issues found**
- `flutter test` → **24/24 passed**
- `scripts/test-firebase-rules.sh` → **209 passing** (197 → +12 test mới, `firestore.answerReactions.test.js`)
- `flutter clean` trước cả 2 build

### ⚠️ Chưa smoke-test 2 máy thật
Nên kiểm 1 lượt A↔B sau khi deploy backend: A trả lời + B trả lời → reveal → A thả ❤️ lên
câu của B → verify (a) B thấy react realtime, (b) B nhận push đúng ngôn ngữ máy B, (c) mở
Nhật ký thấy react ngày cũ, (d) A **không** thả được react lên chính câu của A.
