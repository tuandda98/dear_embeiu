# Icon Redesign — Dev log

> Implement theo [design.md](design.md). **HOÀN TẤT TOÀN APP 2026-06-14** (user "sweep tiếp tất cả, tự quyết, tự kiểm tra").

## Kết quả
- **Lucide → Iconsax 100%:** 199 usage Lucide trên 33 file → `IconsaxPlusLinear.*` (Linear mặc định). Nav 4 tab + Profile badges = Bold (pilot). `lucide_icons` **GỠ HẲN** khỏi pubspec (0 usage).
- **UI hearts → Iconsax:** `Icons.favorite_rounded`/`favorite` → `IconsaxPlusBold.heart`, `favorite_border` → `IconsaxPlusLinear.heart` (animated_couple_name ♥, counter_card, reaction_bar, setup, guest, milestone, love_tree, couple_info, shared_couple_photo...). **NGOẠI LỆ:** `session_route_screen` giữ `Icons.favorite` (tim loader thương hiệu, ăn khớp native splash).
- **Giữ:** `Icons.check_rounded` (glyph dấu tích chung — Iconsax không có check trần).
- Package: `iconsax_plus ^1.0.0` (3 weight Linear/Bold/Broken, 896 icon/weight).

## Cách làm (an toàn, đã-verify)
1. Dump 896 tên icon trong `iconsax_plus_linear.dart`, GREP verify từng tên đích tồn tại TRƯỚC khi map (không đoán).
2. Perl map 82 concept Lucide → Iconsax (word-boundary `\b` tránh khớp tiền tố: clock/clock3, eye/eyeOff, bell/bellRing...). Swap import lucide→iconsax theo từng file.
3. `flutter analyze lib` sau mỗi mẻ → **0 issue**. pub get sau khi gỡ lucide → 0 issue.

## Map đáng chú ý (no 1:1 → chọn gần nghĩa)
| Lucide | Iconsax | Ghi chú |
|---|---|---|
| flame (streak) | `flash` ⚡ | Iconsax không có lửa → tia/năng lượng |
| sprout (love tree) | `tree` 🌳 | hợp "cây tình yêu lớn dần" |
| heartHandshake | `lovely` | tim+sparkle |
| rocket (force-update) | `magic_star` | Iconsax không có rocket → sparkle "bản mới" |
| infinity | `lovely` | "yêu mãi mãi" |
| pin | `location` | Iconsax không có push-pin |
| flower2 | `magic_star` | decorative |
| x / close | `close_circle` | |
| sun/sunrise/sunset | `sun_1` · moon → `moon` | greeting theo giờ |
| bellOff (empty) | `notification_status` | |
| cloudOff (error) | `cloud_cross` | |

> Map đầy đủ trong `/tmp/iconmap.pl` (đã chạy) + bảng [design.md](design.md).

## Verify
- `flutter analyze lib` → **0 issue** (sau full sweep + gỡ lucide).
- App build + chạy OK trên simulator (ios-sim.sh).
- Tự QA trực quan: nav + Home (xem report). Các màn khác: verify qua analyze sạch + tên icon đã-grep-tồn-tại + map theo nghĩa.
- Client-only, KHÔNG đụng backend. Icon thương hiệu (launcher/native-splash) KHÔNG đụng (cần asset, để sau nếu user muốn).

## Nhật ký
- [2026-06-14] [lead+po+designer+dev] Sweep TOÀN APP Lucide→Iconsax (199 usage/33 file) + UI hearts→Iconsax + gỡ lucide_icons. Pilot (nav+Profile) trước đó. analyze 0. Tự QA Home/nav OK.
