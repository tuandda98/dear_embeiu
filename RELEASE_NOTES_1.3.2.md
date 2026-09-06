# What's New — Dear Embeiu 1.3.2 (build 11)

> Copy vào CẢ HAI: App Store Connect → 1.3.2 → "What's New" · Google Play → "Có gì mới".
> 1.3.2 chủ yếu là cải thiện ngầm (auto-store update check — app tự nhắc cập nhật) → notes NGẮN, không có tính năng nhìn thấy mới.
> ⚠️ KHÔNG nêu cơ chế kỹ thuật (force-update / auto store check).

## 🇻🇳 Tiếng Việt (primary)
```
Bản cập nhật nhỏ — ổn định & mượt hơn 💕

✨ Cải thiện hiệu năng và sửa vài lỗi nhỏ.
🔄 Trải nghiệm cập nhật mượt mà hơn cho những bản sau.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
A small update — more stable and smooth 💕

✨ Performance improvements and minor bug fixes.
🔄 A smoother update experience going forward.

Thanks for keeping your memories together with us 🌷
```

---

## Ghi chú nội bộ — delta 1.3.2 (so với 1.3.1)
- **Auto-store force-update (ngầm):** app tự check store có bản mới → Android dùng Google Play In-App Updates, iOS dùng iTunes lookup; bật/tắt từ xa qua `config/app.autoStoreForce`. KHÔNG nhìn thấy với user trừ khi bị ép cập nhật.
- Không tính năng UI mới, không đụng backend (chỉ thêm field đọc `autoStoreForce`).
- Build 11. Parity: submit cả Play + App Store cùng 1.3.2+11.
