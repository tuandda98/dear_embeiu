# What's New — Dear Embeiu 1.3.3 (build 12)

> Copy vào **CẢ HAI**: App Store Connect → 1.3.3 → "What's New" · Google Play → "Có gì mới".
> ⚠️ KHÔNG nêu phần gate riêng tài khoản (lời nhắc riêng "anh By → embe", tắt nhắc cho 1 tài khoản, allowlist…) — chỉ nêu thay đổi CÔNG KHAI.

## 🇻🇳 Tiếng Việt (primary)
```
Bản cập nhật cho khung chat mượt mà hơn 💕

💬 Trò chuyện gọn gàng hơn: bong bóng tin nhắn mới, nền ảnh tràn viền, cuộn mượt hơn.
✍️ Hiện "đang soạn tin…" khi người ấy đang nhắn cho bạn.
🔔 Lời nhắc câu hỏi hằng ngày thông minh hơn: thôi nhắc khi cả hai đã trả lời.
✨ Vài tinh chỉnh nhỏ & sửa lỗi cho trải nghiệm nhẹ nhàng hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
A smoother chat experience 💕

💬 A tidier chat: refreshed message bubbles, full-bleed photo background, smoother scrolling.
✍️ A "typing…" hint when your partner is messaging you.
🔔 Smarter daily question reminders: they stop once you've both answered.
✨ Minor tweaks and bug fixes for a gentler experience.

Thanks for keeping your memories together with us 🌷
```

---

## Ghi chú nội bộ — delta 1.3.3 (so với 1.3.0 live)
- **Công khai (vào notes):** chat redesign (bubble navy/xám, nền ảnh full-bleed, header trong suốt, cuộn full-top) + **typing indicator "đang soạn…"** + nhắc câu hỏi answer-aware.
- **Gate riêng — KHÔNG vào notes:** fix race nhắc hourly "anh By → embe"; tắt nhắc câu-hỏi-chung + cuối-ngày RIÊNG máy `thaohathao14@gmail.com`.
- **⚠️ ĐỤNG BACKEND:** rules thêm `receipts.typingAt` (additive, fail-soft). Deploy DEV xong; **PROD cần deploy trước/khi release để typing chạy ở prod** (chưa deploy → app không crash, chỉ không có typing).
- AAB + IPA build 1.3.3+12 từ cùng pubspec, ký đúng, parity 2 nền tảng.
