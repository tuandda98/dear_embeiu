# What's New — Dear Embeiu 1.3.4 (build 13)

> Copy vào **CẢ HAI**: App Store Connect → 1.3.4 → "What's New" · Google Play → "Có gì mới".
> ⚠️ KHÔNG nêu phần gate riêng tài khoản (lời nhắc riêng, tắt nhắc cho 1 tài khoản, allowlist…) — chỉ nêu thay đổi CÔNG KHAI.

## 🇻🇳 Tiếng Việt (primary)
```
Chăm chút kỷ niệm dễ hơn 💕

🖼️ Đổi ảnh đã đăng: chọn nhầm hay muốn ảnh đẹp hơn? Giờ thay được ảnh khác mà vẫn giữ nguyên chú thích.
✨ Bảng tuỳ chọn ảnh mới gọn gàng: sửa chú thích, đổi ảnh, xoá ảnh trong một chỗ rõ ràng.
🌷 Vài tinh chỉnh nhỏ cho mượt mà hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
Caring for your memories, made easier 💕

🖼️ Replace a posted photo: picked the wrong one or found a nicer shot? Swap the image while keeping your caption.
✨ A tidy new photo options sheet: edit caption, replace, and delete all in one clear place.
🌷 Minor tweaks for a smoother experience.

Thanks for keeping your memories together with us 🌷
```

---

## Ghi chú nội bộ — delta 1.3.4 (so với 1.3.3)
- **Công khai (vào notes):** đổi ảnh của một kỷ niệm đã đăng (giữ caption/ngày/người đăng) + redesign menu "⋯" ảnh → action sheet on-brand (sửa chú thích / đổi ảnh / xoá ảnh / báo cáo, có thumbnail + phân nhóm).
- **Không đụng backend:** rules photo-update sẵn cho phép đổi `remoteUrl`/`storagePath`; KHÔNG thay đổi `firestore.rules`/functions/storage. (typingAt của 1.3.3 đã deploy PROD 2026-06-21 — không liên quan bản này.)
- AAB + IPA build 1.3.4+13 từ cùng pubspec, ký đúng, parity 2 nền tảng.
