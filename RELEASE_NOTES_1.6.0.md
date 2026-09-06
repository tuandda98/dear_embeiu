# What's New — Dear Embeiu 1.6.0 (build 20)

> Copy vào **CẢ HAI**: App Store Connect → 1.6.0 → "What's New" · Google Play → "Có gì mới".
> ⚠️ CHỈ nêu thay đổi CÔNG KHAI — không nêu chi tiết kỹ thuật / gate tài khoản riêng.
> ℹ️ 1.6.0 = **MINOR**: Gửi quan tâm + Lời quan tâm · câu hỏi mỗi ngày mới (theo tuần/tháng/tâm trạng, nhìn lại, AI tuỳ chọn) · mời người ấy dễ hơn · giới thiệu lần đầu.

## 🇻🇳 Tiếng Việt (primary)
```
Gửi một lời quan tâm, và câu hỏi mỗi ngày mới hơn 💌

💌 Gửi quan tâm: soạn một lời nhắn ngắn cho người ấy — chạm biểu tượng thư ở màn hình chính, người ấy nhận thông báo ngay. Mọi lời nhắn được giữ lại trong "Lời quan tâm" để xem lại bất cứ lúc nào.
✨ Câu hỏi mỗi ngày mới hơn: câu hỏi theo tuần, theo tháng, theo tâm trạng và các mốc của chúng mình; cuối tuần cùng nhìn lại câu trả lời cũ. Bật "Câu hỏi cá nhân hoá bằng AI" trong Cài đặt nếu muốn câu hỏi riêng cho hai bạn (tuỳ chọn, tắt mặc định).
🧭 Mời người ấy dễ hơn: link tải app kèm mã mời, hướng dẫn từng bước trong lúc chờ.
🌷 Giới thiệu nhanh khi mở app lần đầu và mục "Có gì mới" trong Cài đặt.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
Send a care note, and fresher daily questions 💌

💌 Care notes: write a short note to your partner — tap the envelope on the home screen and they get a notification right away. Every note is kept in "Care notes" to look back on anytime.
✨ Fresher daily questions: prompts that follow your week, month, mood and milestones; look back on old answers on weekends. Turn on "AI-personalised questions" in Settings if you want questions made just for the two of you (optional, off by default).
🧭 Easier to invite your partner: a download link with your invite code and step-by-step guidance while you wait.
🌷 A quick intro on first launch and a "What's new" page in Settings.

Thanks for keeping your memories together with us 🌷
```

> 🍎 **App Store:** app này Apple chỉ có localization **Vietnamese** → chỉ cần bản tiếng Việt.
> ⚠️ **ASC TỪ CHỐI EMOJI trong "What's New"** → dùng bản KHÔNG emoji dưới đây cho App Store. Google Play thì emoji dùng bình thường.

### Bản dán cho App Store (không emoji)
```
Gửi một lời quan tâm, và câu hỏi mỗi ngày mới hơn

Gửi quan tâm: soạn một lời nhắn ngắn cho người ấy bằng biểu tượng thư ở màn hình chính, người ấy nhận thông báo ngay. Mọi lời nhắn được giữ lại trong mục Lời quan tâm để xem lại bất cứ lúc nào.

Câu hỏi mỗi ngày mới hơn: câu hỏi theo tuần, theo tháng, theo tâm trạng và các mốc của chúng mình; cuối tuần cùng nhìn lại câu trả lời cũ. Bật Câu hỏi cá nhân hoá bằng AI trong Cài đặt nếu muốn câu hỏi riêng cho hai bạn (tuỳ chọn, tắt mặc định).

Mời người ấy dễ hơn: link tải app kèm mã mời, hướng dẫn từng bước trong lúc chờ.

Giới thiệu nhanh khi mở app lần đầu và mục Có gì mới trong Cài đặt.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm.
```

---

## Ghi chú nội bộ — 1.6.0 (build 20)

### Nội dung
1. **Quan tâm** (`care-message`): gửi title+nội dung → push nguyên văn + inbox; timeline riêng "Lời quan tâm" (huy hiệu thứ 5 ở Profile, "Xem tất cả" ở màn gửi, tap thông báo → đúng tin).
2. **Endless questions**: marker = nguồn sự thật; bank +150; 88 template; nhìn lại; AI opt-in (CF `generateDailyQuestion`).
3. **Onboarding**: intro 3 slide, checklist chờ partner + nhắc lại 24h/72h, feature tour theo build, tin mời có link `dearembeiu.com/get`.
4. **Gated (KHÔNG công khai)**: catch-up gate + nhắc "Anh By <3" cho 1 tài khoản.
5. Vá theo code-review + 2 vòng Tester (xem `project/features/*/test.md`).

### ⚠️ Backend PROD phải deploy TRƯỚC/CÙNG lúc phát hành (chờ lệnh user)
`npx firebase-tools deploy --only firestore:rules,functions:notifyCareMessage,functions:generateDailyQuestion,functions:notifyDailyAnswer --project prod`
- Chưa deploy ⇒ Gửi quan tâm báo lỗi quyền; `questionState` bị từ chối (fail-soft); rule bất biến câu hỏi chưa hiệu lực.
- AI cần secret `ANTHROPIC_API_KEY` (không nạp thì toggle bật nhưng luôn rơi về template).
- Sau khi 1.6.0 live CẢ 2 store: nâng `config/app.minBuildNumber` = 20.
