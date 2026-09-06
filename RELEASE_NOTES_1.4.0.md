# What's New — Dear Embeiu 1.4.0 (build 15)

> Copy vào **CẢ HAI**: App Store Connect → 1.4.0 → "What's New" · Google Play → "Có gì mới".
> ⚠️ KHÔNG nêu phần gate riêng tài khoản (lời nhắc riêng, tắt nhắc cho 1 tài khoản, allowlist…) — chỉ nêu thay đổi CÔNG KHAI.
> ℹ️ 1.4.0 = tính năng mới "Nhắc người ấy" (toggle trong lời nhắc) + sửa lỗi đồng bộ ghép đôi.

## 🇻🇳 Tiếng Việt (primary)
```
Nhắc nhau yêu thương 💕

🔔 Nhắc người ấy: khi tạo một lời nhắc của hai bạn, bật "Cũng nhắc người ấy" để người ấy cũng nhận đúng lời nhắc đó vào đúng giờ — nhắc uống nước, ngủ sớm, uống thuốc, hay bất cứ điều gì hai bạn quan tâm.
🩹 Sửa lỗi & ổn định: đồng bộ trạng thái mượt hơn ngay sau khi hai bạn ghép đôi, cùng vài tinh chỉnh nhỏ.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
Little reminders, big love 💕

🔔 Remind your partner: when you create one of your reminders, turn on "Also remind my partner" so they get the same reminder at the right time — drink water, sleep early, take meds, or anything you two care about.
🩹 Fixes & stability: smoother status sync right after you pair up, plus small polish.

Thanks for keeping your memories together with us 🌷
```

---

## Ghi chú nội bộ — 1.4.0 (build 15)
- **Lý do bump:** tính năng mới partner-nudge → SEMVER **minor** (1.3.5 → 1.4.0). Build 15 > 14 (live ở cả 2 store).
- **Công khai (vào notes):**
  - **Nhắc người ấy** (feature partner-nudge): toggle "Cũng nhắc người ấy" trong form Lời nhắc (Cài đặt → Lời nhắc của chúng mình). Bật → lời nhắc mirror sang người ấy (LIÊN KẾT: sửa/xoá/bật-tắt đồng bộ), người ấy nhận thông báo LOCAL đúng giờ + 1 push xác nhận khi đặt. Chỉ hiện khi đã ghép đôi.
  - **Fix coupling:** tự chữa `status` creator → `in_couple` ngay khi người ấy ghép đôi (trước kẹt `waiting_partner`).
- **⚠️ ĐỤNG BACKEND — ĐÃ DEPLOY PROD:** `firestore:rules` (thêm `partnerReminders` author-owned) + CF `notifyPartnerReminderSet`. rules-test 197 pass. Deploy PROD `--project prod` (auto-trace). KHÔNG có instant nudge/`nudges` (đã gỡ; bản thử chỉ còn mồ côi trên DEV).
- **Artifacts:** AAB `build/app/outputs/bundle/release/app-release.aab` ký upload key `FF:EF:1E:27` versionCode 15 · IPA `build/ios/ipa/dear_embeiu.ipa` v1.4.0(15) com.tony.dearembeiu (verify không slice simulator).
- **Force-update:** CHƯA bật. `config/app` vẫn 404 → auto-store-force ngủ. Chỉ set SAU KHI cả 2 store live 1.4.0 (tránh lock-out — CLAUDE.md §13).
- **Chưa smoke-test 2 máy thật** cho partner-nudge (analyze 0 + rules-test 197 + DEV chạy được). Nên kiểm 1 lượt A↔B sau khi live.
