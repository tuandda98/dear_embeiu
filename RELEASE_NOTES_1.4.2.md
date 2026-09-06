# What's New — Dear Embeiu 1.4.2 (build 17)

> Copy vào **CẢ HAI**: App Store Connect → 1.4.2 → "What's New" · Google Play → "Có gì mới".
> ⚠️ KHÔNG nêu chi tiết kỹ thuật nội bộ / gate account riêng — chỉ nêu thay đổi CÔNG KHAI.
> ℹ️ 1.4.2 = bản sửa lỗi (PATCH): nhắc câu hỏi hằng ngày thông minh hơn.

## 🇻🇳 Tiếng Việt (primary)
```
Nhắc đúng lúc, không nhắc thừa 💕

🔔 Lời nhắc câu hỏi hằng ngày nay hiểu chuyện hơn: khi cả hai đã trả lời, mọi lời nhắc trong ngày tự tắt — không còn nhắc "người ấy chưa trả lời" khi người ấy đã trả lời rồi.
🌙 Lời nhắc cuối ngày bớt lặp lại và đúng trạng thái của hai bạn hơn; đặt nhiều giờ nhắc cũng không còn nhận trùng một nội dung.
📅 Quên mở app? Lời nhắc vẫn đến đúng giờ bạn đã đặt trong những ngày kế tiếp.
💌 Chạm vào thông báo của một ngày trước đó sẽ mở đúng trang nhật ký của ngày ấy.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
Reminders that know when to stay quiet 💕

🔔 Daily-question reminders are smarter now: once you've both answered, the rest of the day's reminders turn themselves off — no more "your partner hasn't answered" after they already did.
🌙 End-of-day reminders repeat less and match where you both actually are; multiple reminder times no longer send the same message twice.
📅 Forgot to open the app? Your reminders still arrive at your chosen times on the following days.
💌 Tapping a notification from a previous day now opens that day's journal page.

Thanks for keeping your memories together with us 🌷
```

---

## Ghi chú nội bộ — 1.4.2 (build 17)
- **Lý do bump:** thuần bug-fix thông báo daily-question (audit 39 case, 10 bug + 2 vấn đề copy — 2026-08-09) → SEMVER **patch** (1.4.1 → 1.4.2). Build 17 > 16 (live cả 2 store từ 2026-07-07).
- **Công khai (vào notes):**
  - **BUG-1** — người trả lời TRƯỚC không còn nhận noti sai cả ngày: push "cả hai đã trả lời" nay huỷ lịch nhắc local ngay cả khi app đóng (iOS `content-available`; Android data-only companion vì notification-payload push ở background không chạy `onBackgroundMessage`); + khi mình đã trả lời thì bỏ hẳn 2 cảnh báo mất chuỗi 22h/23h.
  - **BUG-2** — dải backstop 1020–1033: one-shot rolling 7 ngày tới (từ MAI), top-up mỗi lần mở app → không mở app vẫn được nhắc đúng giờ đã đặt.
  - **BUG-3/V3/V4** — copy 23h riêng (leo thang thật), title "Chỉ còn người ấy nữa thôi 💌" khi mình đã xong, 3 biến thể body xoay vòng, bỏ giờ trùng 21/22/23h.
  - **BUG-7 (backend)** — CF tự stamp `bothAnswered` marker (Admin SDK) → hết mất ngày khỏi streak/journal khi 2 người gửi cùng lúc.
  - **D12** — tap noti ngày cũ → mở đúng ngày trong Journal.
- **KHÔNG công khai:** gate `coupleActive` (BUG-5), ẩn tile account gated (BUG-10), hint Settings (BUG-8), 6 câu bank đổi giọng (BUG-9), midnight rollover (D7), fallback tên theo lang (D13), copy inbox "cả hai" (D14).
- **⚠️ BACKEND:** CF `notifyDailyAnswer` (wakeClients + companion + stamp marker + fallback tên + inbox `bothAnswered`) — **✅ ĐÃ DEPLOY PROD 2026-08-09** (additive, KHÔNG đụng rules; rules-test 197 · trace tự ghi). An toàn với client cũ (companion không title/body → 1.4.1 return sớm).
- **Artifacts (verify xong 2026-08-09):** AAB `build/app/outputs/bundle/release/app-release.aab` **56.5MB** ký upload key `FF:EF:1E:27:C0:5F…` versionCode 17 · IPA `build/ios/ipa/dear_embeiu.ipa` **50.2MB** v1.4.2(17) com.tony.dearembeiu ký `Apple Distribution 4UBR69C227` — **42/42 framework arm64 `platform IOS`, 0 slice simulator/x86_64** (an toàn Transporter).
- **Force-update:** `minBuildNumber` giữ **15**; chỉ nâng lên 17 SAU khi cả 2 store live build 17 (tránh lock-out — CLAUDE.md §13).
- **Chưa smoke-test 2 máy thật** (analyze 0 · test 24/24 · rules-test 197). Nên kiểm 1 lượt A↔B sau khi live: A trả lời sáng → đóng app → B trả lời → verify A KHÔNG nhận nhắc sai 20/21/22/23h (cả iOS lẫn Android), và 1 ngày không mở app vẫn nhận backstop.
