# assets/lottie/ — animation "khoảnh khắc" (feature lottie-moments)

Mỗi file ứng với 1 slot trong `lib/widgets/love_lottie.dart` (`enum LoveLottieSlot`).
**Tên file phải khớp đúng** thì widget mới nạp; thiếu file → tự fallback (không crash).

| File cần | Slot | Dùng ở đâu | Gợi ý nội dung |
|----------|------|------------|----------------|
| `couple_joined.json` | coupleJoined | setup → ghép đôi thành công | 2 trái tim chạm nhau / pháo hoa hồng |
| `empty_gallery.json` | emptyGallery | Gallery khi chưa có ảnh | khung ảnh/camera dễ thương (lặp êm) |
| `milestone.json` | milestone | đạt cột mốc (trigger TBD) | ăn mừng / số + tim |
| `daily_reveal.json` | dailyReveal | Home — mở khoá Daily Question | tim bung / sparkle (✅ đang có placeholder) |

## Cách đổi / thêm file
1. Tải `.json` từ LottieFiles **free** (Lottie Simple License — thương mại OK, không bắt buộc ghi nguồn): https://lottiefiles.com/page/license
2. Đặt đúng tên ở trên vào thư mục này.
3. `fvm flutter pub get` (thư mục đã đăng ký trong pubspec nên file mới tự được bundle).
4. Không cần sửa code.

## Nguồn hiện dùng (placeholder — dễ swap)
- `daily_reveal.json` — repo MIT `spemer/lottie-animations-json` (ic_fav, heart like-pop).
- `couple_joined.json` — LottieFiles id 17297 "fireworks" (Lottie Simple License) qua mirror `xvrh/lottie-flutter`.
- `empty_gallery.json` — LottieFiles "camera" (Lottie Simple License) qua `airbnb/lottie-android` snapshot assets.
- `milestone.json` — **chưa có**: cần chốt **trigger in-app** trước (hiện milestone chỉ là notification), rồi mới thả file ăn mừng.

> ⚠️ Giữ ≤ vài file & KHÔNG đặt animation trong list/grid (perf máy tầm trung). Ưu tiên tông hồng "Sunset Romance".
