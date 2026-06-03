# Dev log — lottie-moments

> File Dev sở hữu. Ghi việc đã code + cách hoạt động. PO spec ở [overview.md](overview.md).

## Kiến trúc
- **Package:** `lottie: ^3.3.3` (pubspec.yaml). Assets: thư mục `assets/lottie/` đăng ký trong `flutter.assets`.
- **Widget tái dùng:** `lib/widgets/love_lottie.dart`
  - `enum LoveLottieSlot` — 4 slot có path cố định: `coupleJoined`, `emptyGallery`, `milestone`, `dailyReveal` → `assets/lottie/<slot>.json`.
  - `class LoveLottie` — bọc `Lottie.asset` với `errorBuilder` → `fallback` (mặc định `SizedBox.shrink()`). **Thiếu/hỏng file = fallback, không crash.** `repeat` true=lặp (empty state), false=one-shot.
  - **Không có cờ bật/tắt** (D3): feature sống thẳng trên nhánh dev; "ngủ đông theo file".

## Điểm wire (3 moment in-app)
1. **Empty Gallery** — `lib/screens/gallery_screen.dart` (trong `_buildEmptyFeedState`, ngay trước `Text(emptyFeedContent)`):
   `const LoveLottie(slot: emptyGallery, height: 140, repeat: true)`. Thiếu file → 0px, layout y hệt cũ.
2. **Daily Question reveal** — `lib/screens/home_screen.dart` (trong `Stack` của card, sau `ConfettiWidget`):
   `if (hasRevealed) Positioned(top: -8, child: LoveLottie(slot: dailyReveal, height: 120))`. Accent thêm cạnh confetti; thiếu file → chỉ còn confetti như cũ.
3. **Couple joined** — `lib/screens/setup_screen.dart` (`_joinCouple` sau khi join thành công, trước `pushReplacementNamed(home)`):
   gọi `await _showJoinCelebration()` → dialog Center(LoveLottie coupleJoined, height 220) tự đóng sau 1.9s.
   - **Guard:** `_showJoinCelebration` thử `rootBundle.load(coupleJoined.asset)` trong try/catch — **chưa có file → return ngay, không hiện dialog trống.**
   - Bắt `NavigatorState` đồng bộ TRƯỚC `await` để né lint `use_build_context_synchronously`.

## Trạng thái asset (`assets/lottie/`)
| Slot | File | Có chưa? | Nguồn |
|------|------|----------|-------|
| dailyReveal | `daily_reveal.json` | ✅ (placeholder heart, 4.5KB) | repo MIT `spemer/lottie-animations-json` (ic_fav) |
| coupleJoined | `couple_joined.json` | ✅ (pháo hoa, 30KB, 200×200) | LottieFiles id 17297 (Lottie Simple License) qua mirror `xvrh/lottie-flutter` |
| emptyGallery | `empty_gallery.json` | ✅ (camera, 14KB, vector thuần) | LottieFiles via `airbnb/lottie-android` (Lottie Simple License) |
| milestone | `milestone.json` | ❌ chờ — **cần trigger in-app trước** (xem D4) | — |

→ Đổi animation = thả file đúng tên vào `assets/lottie/` rồi `fvm flutter pub get`. Không đụng code.

## Verify
- `fvm flutter analyze lib/widgets/love_lottie.dart lib/screens/{gallery,home,setup}_screen.dart` → **No issues found** (2026-06-03).
- ⏳ Chưa smoke-test thiết bị.

## Changelog
- [2026-06-03] [Dev] Scaffolding + `LoveLottie` + wire 3 moment + seed `daily_reveal.json`. analyze sạch.
