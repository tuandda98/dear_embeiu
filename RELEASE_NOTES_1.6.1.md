# What's New — Dear Embeiu 1.6.1 (build 21)

> Copy vào **CẢ HAI**: App Store Connect → 1.6.1 → "What's New" · Google Play → "Có gì mới".
> ⚠️ CHỈ nêu thay đổi CÔNG KHAI — bản này thay đổi duy nhất nằm trong phần lời nhắc **gate riêng một tài khoản**, KHÔNG được nêu ra store.
> ℹ️ 1.6.1 = **PATCH** bảo trì: đổi nội dung lời nhắc riêng (không công khai) + cải thiện nhỏ. KHÔNG đụng backend.

## 🇻🇳 Tiếng Việt (primary)
```
Cải thiện nhỏ 🌷

Tinh chỉnh lời nhắc hằng ngày cho ấm áp và tự nhiên hơn.
Sửa vài lỗi nhỏ để app chạy mượt hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English
```
Small improvements 🌷

Warmer, more natural daily reminders.
Minor fixes for a smoother experience.

Thanks for keeping your memories together with us 🌷
```

> 🍎 **App Store:** app này Apple chỉ có localization **Vietnamese** → chỉ cần bản tiếng Việt.
> ⚠️ **ASC TỪ CHỐI EMOJI trong "What's New"** (lỗi dính tới khi F5) → dùng bản KHÔNG emoji dưới đây cho App Store. Google Play thì emoji dùng bình thường.

### Bản dán cho App Store (không emoji)
```
Cải thiện nhỏ

Tinh chỉnh lời nhắc hằng ngày cho ấm áp và tự nhiên hơn.
Sửa vài lỗi nhỏ để app chạy mượt hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm.
```

---

## Ghi chú nội bộ — 1.6.1 (build 21)

### Nội dung
1. **Lời nhắc riêng "Anh By → embe"** (band 1100–1109, ACCOUNT-GATED `thaohathao14@gmail.com` — **KHÔNG công khai**): bỏ hẳn nhắc uống thuốc 9:59/10:10/10:30, thay bằng 3 lời hỏi thăm **7:45** (nhắc ăn sáng) · **13:30** (hôm nay thế nào / đang làm gì) · **20:30** (có nhớ anh không). Mỗi khung 1 pool 15 câu, xoay theo ngày bằng bước 7 (nguyên tố cùng 15) ⇒ duyệt hết pool rồi mới lặp, 3 buổi lệch pha.
2. Đổi tên API cho khớp ngữ nghĩa: `schedulePersonalMedicineDaily` → `schedulePersonalCareDaily`, `cancelPersonalMedicine` → `cancelPersonalCare`.

### Backend
**KHÔNG đụng backend** — client-only, không deploy rules/functions/indexes. Toàn bộ backend của 1.6.0 đã deploy PROD ngày 2026-09-05 (trace `20260905T150112Z`).

### Pre-flight
- `flutter analyze` → 0 issue · `flutter test` → 81/81.
- KHÔNG chạy rules-test (không đụng `firestore.rules`/`storage.rules`/`functions/index.js`).

### Feature tour
KHÔNG thêm entry `sinceBuild: 21` — bản này không có tính năng công khai mới; `FeatureTour.maybeShow` với danh sách rỗng sẽ không hiện gì (chỉ ghi nhận build đã xem).

### Force-update
`config/app.minBuildNumber` PROD đang **15**. Sau khi 1.6.1/build 21 live CẢ 2 store mới cân nhắc nâng (nâng sớm = lockout).
