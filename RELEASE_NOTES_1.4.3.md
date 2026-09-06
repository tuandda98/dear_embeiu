# What's New — Dear Embeiu 1.4.3 (build 18)

> Copy vào **CẢ HAI**: App Store Connect → 1.4.3 → "What's New" · Google Play → "Có gì mới".
> ⚠️ KHÔNG nêu chi tiết kỹ thuật nội bộ / gate account riêng — chỉ nêu thay đổi CÔNG KHAI.
> ℹ️ 1.4.3 = bản **bảo trì tuân thủ nền tảng** (PATCH). Không có tính năng mới, không sửa bug nào của người dùng.

## 🇻🇳 Tiếng Việt (primary)
```
Bản cập nhật bảo trì 🌷

⚙️ Nâng cấp nền tảng để tương thích với Android 16, đảm bảo ứng dụng tiếp tục hoạt động ổn định trên các máy và hệ điều hành mới nhất.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 💕
```

## 🇬🇧 English
```
Maintenance update 🌷

⚙️ Platform upgrade for Android 16 compatibility, keeping the app running smoothly on the newest devices and OS versions.

Thanks for keeping your memories together with us 💕
```

> 🍎 **App Store:** Apple chỉ có localization **Vietnamese** cho app này (xác nhận ở 1.4.2) → chỉ cần dán bản tiếng Việt.
> Vì iOS là bump parity thuần (xem dưới), bản vi cho App Store nên rút còn: *"Bản cập nhật bảo trì nhỏ. Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 💕"* — KHÔNG nhắc Android.

---

## Ghi chú nội bộ — 1.4.3 (build 18)

### Lý do bump
**Deadline chính sách Google Play: 31/8/2026.** App còn `targetSdk 35` sẽ *"không thể phát hành bản cập nhật"* sau ngày đó (cảnh báo đỏ trong Play Console, thông báo 22/7/2026). Đây là ràng buộc thời hạn, không phải yêu cầu tính năng → SEMVER **patch** (1.4.2 → 1.4.3).

### Delta duy nhất so với 1.4.2+17
- `android/app/build.gradle.kts`: `targetSdk = 35` → `36` (commit `ea7292e`)
- `pubspec.yaml`: `1.4.2+17` → `1.4.3+18`

**KHÔNG có thay đổi nào khác.** Không đụng `lib/`, không đụng rules/functions → **KHÔNG cần deploy backend**.

### ⚠️ iOS = bump parity thuần
`targetSdk` là thiết lập **chỉ của Android**. Binary iOS 1.4.3(18) **giống hệt về mặt chức năng** với 1.4.2(17) đang live — chỉ khác chuỗi version. Submit iOS chỉ để giữ **RULE PARITY** (CLAUDE.md §13: 2 store luôn cùng version + build), tiền lệ đã có ở 1.3.5+14.
→ Nếu muốn tiết kiệm một vòng review của Apple, **có thể bỏ qua iOS** và chấp nhận lệch số (Android 1.4.3 / iOS 1.4.2) — nhưng như vậy là phá RULE PARITY, và lần release sau phải hội tụ lại.

### An toàn edge-to-edge
Android 16 (target 36) **gỡ bỏ** `windowOptOutEdgeToEdgeEnforcement`. App **không dùng** cờ này (đã grep) → không có màn hình nào vỡ layout vì ép edge-to-edge.

### Pre-flight (chạy thật 2026-08-22)
- `flutter analyze` → **No issues found**
- `flutter test` → **24/24 passed**
- `scripts/test-firebase-rules.sh` → **không chạy** (không đụng rules/functions — đúng quy ước)
- `flutter clean` trước cả 2 build (chống slice simulator)

### Artifacts (verify xong)
- **AAB** `build/app/outputs/bundle/release/app-release.aab` — **54MB**, `jar verified`, versionCode **18**, **`targetSdkVersion='36'`** (đọc từ merged manifest), SHA1 `FF:EF:1E:27:C0:5F:C9:A6:36:7E:1C:2C:0B:E2:B6:FF:77:E1:02:6A` khớp upload key trong `android/key.properties`.
- **IPA** `build/ios/ipa/dear_embeiu.ipa` — **48MB**, v1.4.3(18), `com.tony.dearembeiu`, ký `Apple Distribution: Tuan Do Dao Anh (4UBR69C227)`, **42/42 framework arm64 `platform IOS`, 0 slice simulator/x86_64** (an toàn Transporter, không dính Validation 409).

### Trạng thái store trước khi nộp (verify 2026-08-22)
- **App Store**: LIVE `1.4.2`, phát hành 2026-08-09T19:58Z (iTunes lookup)
- **Google Play**: LIVE `1.4.2` (scrape) — bản 17 đã qua review, không còn "đang review"
→ build **18 > 17** ở cả hai, an toàn.

### Việc kèm theo sau khi live
- **Force-update**: cả 2 store đã live build 17 → nay ĐƯỢC PHÉP nâng `config/app.minBuildNumber` **15 → 17** (không lock-out ai). Nâng lên **18** thì phải đợi build 18 live cả 2 store. ⚠️ Là ghi prod → chờ lệnh user.
- **Xác minh nhà phát triển Android**: deadline **30/9/2026** (thông báo Play Console 7/8/2026). Việc này cần giấy tờ tuỳ thân → **user tự làm**, Claude không đụng được.
