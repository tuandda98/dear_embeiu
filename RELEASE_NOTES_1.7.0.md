# What's New — Dear Embeiu 1.7.0 (build 23)

> Copy vào **CẢ HAI**: App Store Connect → 1.7.0 → "What's New" · Google Play → "Có gì mới".
> ℹ️ 1.7.0 = **MINOR** — tính năng mới **Oẳn tù tì** (feature `rps-game`) + gồm toàn bộ bản sửa lỗi của 1.6.2. ĐỤNG backend (rules + 2 index + 3 CF rps) — deploy PROD cùng đợt.
> ⚠️ CHỈ nêu thay đổi CÔNG KHAI.

## 🇻🇳 Tiếng Việt (primary) — ≤500 ký tự (giới hạn Play)
```
Oẳn tù tì cùng người ấy ✊✋✌️

• Rủ người ấy một ván: người ấy nhận thông báo, cả hai cùng vào là đếm "oẳn tù tì" rồi ra tay.
• Không có bỏ lượt: ván chờ tới khi cả hai ra, người chưa ra sẽ được nhắc.
• Kết quả lộ cùng lúc, pháo giấy cho người thắng.
• Lịch sử các ván và tỉ số ở Trang cá nhân.
• Câu hỏi hằng ngày ổn định hơn, nhắc đúng ngày.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English — ≤500 ký tự
```
Rock-paper-scissors with your person ✊✋✌️

• Challenge your person: they get a notification, and once you're both in, count and throw.
• No forfeits: the round waits until you've both thrown, with a gentle "your turn" reminder.
• Results reveal at the same moment, with confetti for the winner.
• Game history and your score in Profile.
• Daily question is more reliable, with reminders on the right day.

Thanks for keeping your memories together with us 🌷
```

### Bản dán cho App Store (không emoji, gạch "-")
```
Oẳn tù tì cùng người ấy

- Rủ người ấy một ván: người ấy nhận thông báo, cả hai cùng vào là đếm "oẳn tù tì" rồi ra tay.
- Không có bỏ lượt: ván chờ tới khi cả hai ra, người chưa ra sẽ được nhắc.
- Kết quả lộ cùng lúc, pháo giấy cho người thắng.
- Lịch sử các ván và tỉ số ở Trang cá nhân.
- Câu hỏi hằng ngày ổn định hơn, nhắc đúng ngày.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm.
```

---

## Ghi chú nội bộ — 1.7.0 (build 23)
- Nội dung: feature `rps-game` (spec/design/dev/test ở `project/features/rps-game/`) + mọi thay đổi của 1.6.2+22.
- Backend PROD: `firestore:rules,firestore:indexes,functions:notifyRpsInvite,functions:resolveRpsGame,functions:nudgeRpsPlayer` (additive, app cũ không ảnh hưởng). KHÔNG deploy `finishRpsGame`/`notifyRpsResult` (đã gỡ).
- Feature tour: entry `sinceBuild: 23` (Oẳn tù tì).
- Mixed-version: người ấy còn 1.6.x vẫn nhận push rủ nhưng không có màn chơi → autoStoreForce ép cập nhật khi 1.7.0 live.
- Force-update: không nâng `minBuildNumber` (quyết định 2026-09-07).
