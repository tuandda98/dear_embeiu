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
- `daily_reveal.json` — **💕 hai trái tim** (Noto Animated Emoji 1f495, CC BY 4.0) — thay file `ic_fav` cũ trông như "ngôi sao" không hợp app tình yêu (user 2026-06-19). Chạy 1 lần phủ trên confetti khi cả 2 trả lời câu hỏi. Swap dễ: thả file Noto heart khác (💖 1f496 / 💞 1f49e) cùng tên.
- `couple_joined.json` — LottieFiles id 17297 "fireworks" (Lottie Simple License) qua mirror `xvrh/lottie-flutter`.
- `empty_gallery.json` — LottieFiles "camera" (Lottie Simple License) qua `airbnb/lottie-android` snapshot assets.
- `milestone.json` — **chưa có**: cần chốt **trigger in-app** trước (hiện milestone chỉ là notification), rồi mới thả file ăn mừng.

> ⚠️ Giữ ≤ vài file & KHÔNG đặt animation trong list/grid (perf máy tầm trung). Ưu tiên tông hồng "Sunset Romance".

## Mood — mặt cảm xúc động (feature mood, 2026-06-19)

8 file `mood_<key>.json` = 8 mood trong `lib/models/mood.dart` (`MoodOption.lottie`). Render bởi `lib/widgets/mood_glyph.dart` (`MoodGlyph`), tự fallback về emoji tĩnh nếu thiếu/hỏng.

| File | Mood | Emoji | Biểu cảm |
|---|---|---|---|
| `mood_happy.json` | happy | 😄 | cười tươi, mắt cong |
| `mood_loved.json` | loved | 🥰 | cười + tim bay |
| `mood_missing.json` | missing | 🥹 | mắt long lanh chực khóc |
| `mood_calm.json` | calm | 😌 | thanh thản, mắt khẽ nhắm |
| `mood_meh.json` | meh | 😐 | phẳng lì, chớp mắt |
| `mood_tired.json` | tired | 😪 | buồn ngủ, giọt mồ hôi |
| `mood_sad.json` | sad | 😢 | 1 giọt nước mắt rơi |
| `mood_stressed.json` | stressed | 😣 | nhăn mặt, nheo mắt |

### ⚖️ Attribution (BẮT BUỘC giữ)
Nguồn: **Noto Animated Emoji** của Google — `https://fonts.gstatic.com/s/e/notoemoji/latest/<codepoint>/lottie.json`.
License: **CC BY 4.0** (https://creativecommons.org/licenses/by/4.0/) — dùng thương mại OK, **phải ghi công**.
→ TODO user-visible: thêm 1 dòng "Animated emoji by Google (Noto Emoji, CC BY 4.0)" vào màn Giấy phép/About (app hiện chưa có `showLicensePage`).
