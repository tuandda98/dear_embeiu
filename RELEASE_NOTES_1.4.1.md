# What's New — Dear Embeiu 1.4.1 (build 16)

> Copy vào **CẢ HAI**: App Store Connect → 1.4.1 → "What's New" · Google Play → "Có gì mới".
> ⚠️ KHÔNG nêu chi tiết kỹ thuật nội bộ — chỉ nêu thay đổi CÔNG KHAI.
> ℹ️ 1.4.1 = bản sửa lỗi (PATCH): thông báo & thẻ câu hỏi hôm nay.

## 🇻🇳 Tiếng Việt (primary)
```
Mượt hơn, không bỏ lỡ khoảnh khắc nào 💕

🔔 Nhận thông báo ngay cả khi đang mở app: người ấy thả tim ảnh, trả lời câu hỏi hay nhắn tin — bạn thấy liền, không còn bị "im lặng".
💬 Thông báo câu hỏi hôm nay khéo hơn: khi cả hai đã trả lời, thông báo mời bạn xem câu trả lời của nhau thay vì nhắc trả lời lại.
✨ Thẻ "Hôm nay của chúng mình" mượt mà hơn khi mở khoá câu trả lời — hết giật, hết nhấp nháy.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
Smoother, and you won't miss a moment 💕

🔔 Get notified even while the app is open: when your partner likes a photo, answers the question, or sends a message — you'll see it right away, no more silence.
💬 Smarter daily-question alerts: once you've both answered, the notification invites you to read each other's replies instead of nudging you to answer again.
✨ The "Today, together" card now unlocks answers smoothly — no more freeze or flicker.

Thanks for keeping your memories together with us 🌷
```

---

## Ghi chú nội bộ — 1.4.1 (build 16)
- **Lý do bump:** thuần sửa lỗi → SEMVER **patch** (1.4.0 → 1.4.1). Build 16 > 15 (live ở cả 2 store).
- **Công khai (vào notes):**
  - **Foreground push hiện được trên cả iOS** (feature notifications): trước đây `flutter_local_notifications` chiếm `UNUserNotificationCenterDelegate` → FCM foreground auto-present bị vô hiệu → iOS mở app thì mọi tương tác (reaction/daily-question/chat/mood/photo…) KHÔNG hiện noti. Fix: `_handleForegroundMessage` tự show local notification trên cả iOS + Android (tầng transport `onMessage` → phủ hết loại), `setForegroundNotificationPresentationOptions(alert:false,sound:false)` để 1 banner duy nhất; tap banner foreground cũng deep-link đúng tab/ảnh.
  - **Copy noti daily-question** (feature daily-question): khi cả 2 đã trả lời (`count() >= 2` trên `responses`) → dùng body "cả hai đã trả lời, xem câu trả lời của nhau" thay vì giục người ĐÃ trả lời trả lời lại. Fail-open về nudge cũ nếu count lỗi.
  - **Thẻ câu hỏi mượt hơn** (feature daily-question): bỏ side-effect trong `build()` → chuyển celebration sang listener provider (hết giật); thay teaser `ImageFilter.blur` chữ đen (vệt xám-nâu + nặng) bằng redaction bars lavender on-brand (hết "màu nâu", paint rẻ).
- **⚠️ ĐỤNG BACKEND:** CHỈ CF `notifyDailyAnswer` (copy) — additive, KHÔNG đụng rules. Deploy `--only functions:notifyDailyAnswer`. rules-test 197 pass. #1 và #3 là CLIENT-ONLY.
- **Artifacts:** AAB `build/app/outputs/bundle/release/app-release.aab` ký upload key `FF:EF:1E:27` versionCode 16 · IPA `build/ios/ipa/dear_embeiu.ipa` v1.4.1(16) com.tony.dearembeiu (verify `platform IOS`, không slice simulator).
- **Force-update:** CHƯA đổi. `minBuildNumber` giữ 15 tới khi cả 2 store live build 16 (tránh lock-out — CLAUDE.md §13).
- **Chưa smoke-test 2 máy thật** (analyze 0 + rules-test 197). Nên kiểm 1 lượt A↔B sau khi live: foreground noti + reveal câu hỏi.
