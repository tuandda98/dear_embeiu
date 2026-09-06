# What's New — Dear Embeiu 1.3.5 (build 14)

> Copy vào **CẢ HAI**: App Store Connect → 1.3.5 → "What's New" · Google Play → "Có gì mới".
> ⚠️ KHÔNG nêu phần gate riêng tài khoản (lời nhắc riêng, tắt nhắc cho 1 tài khoản, allowlist…) — chỉ nêu thay đổi CÔNG KHAI.
> ℹ️ 1.3.5 là bản đồng bộ phiên bản 2 nền tảng (parity) + chuẩn bị bật nhắc cập nhật. Nội dung gói trọn các cải tiến 1.3.3–1.3.4 cho người dùng đến từ mọi phiên bản cũ.

## 🇻🇳 Tiếng Việt (primary)
```
Nhắn tin & lưu kỷ niệm mượt hơn 💕

💬 Trò chuyện đẹp như iMessage: bong bóng tin nhắn bo mềm có đuôi, thấy người ấy "đang soạn…" theo thời gian thực.
🖼️ Đổi ảnh đã đăng: chọn nhầm hay muốn ảnh đẹp hơn? Thay được ảnh khác mà vẫn giữ nguyên chú thích.
✨ Bảng tuỳ chọn ảnh gọn gàng: sửa chú thích, đổi ảnh, xoá ảnh trong một chỗ rõ ràng.
🌷 Nhiều tinh chỉnh nhỏ cho mượt mà, ổn định hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
Chatting & memories, smoother than ever 💕

💬 Chat that feels like iMessage: soft rounded bubbles with tails, and see your partner "typing…" in real time.
🖼️ Replace a posted photo: picked the wrong one or found a nicer shot? Swap the image while keeping your caption.
✨ A tidy photo options sheet: edit caption, replace, and delete all in one clear place.
🌷 Many small tweaks for a smoother, more stable experience.

Thanks for keeping your memories together with us 🌷
```

---

## Ghi chú nội bộ — 1.3.5 (build 14)
- **Lý do bump:** đồng bộ phiên bản 2 nền tảng (iOS đang 1.3.4 Ready for Distribution + đã tạo 1.3.5 trên ASC; Android tụt lại sau) → đưa CẢ HAI về **1.3.5+14** từ cùng 1 pubspec. Build 14 > 13 (Apple) và > mọi versionCode đang live ở Play.
- **Code = 1.3.4+13** (không thêm tính năng mới); chỉ bump version để release parity + (tuỳ chọn) thay screenshot iOS trên trang 1.3.5.
- **Công khai (vào notes):** gói trọn chat iMessage-style + typing indicator (1.3.3) và đổi ảnh đã đăng + action sheet ảnh mới (1.3.4) — viết gộp cho người dùng đến từ mọi bản cũ.
- **KHÔNG đụng backend:** rules `typingAt` (1.3.3) đã PROD; bản này thuần client. Không deploy.
- AAB `build/app/outputs/bundle/release/app-release.aab` (56.4MB) ký `FF:EF:1E:27` versionCode 14 · IPA `build/ios/ipa/dear_embeiu.ipa` v1.3.5(14) com.tony.dearembeiu.
- **Force-update:** CHƯA bật. Chỉ set `config/app` SAU KHI cả 2 store có bản 1.3.5 live (tránh khoá chết user — xem CLAUDE.md §13).
