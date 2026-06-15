# Icon Redesign — Design spec (PO + Designer)

> User: "re-design lại TOÀN icon cho app, có thể lấy trên internet". **Chốt: đổi cả app sang bộ Iconsax** (user chọn qua AskUserQuestion 2026-06-14).

## Ràng buộc (nói thẳng với user)
AI KHÔNG tự vẽ được file icon hình ảnh (PNG/SVG) mới. Làm được: (1) đổi sang 1 bộ icon vector có sẵn dạng package — curate từng chức năng → icon phù hợp; (2) tích hợp SVG custom nếu user cấp file. User chọn (1) = **Iconsax**.

## Package
`iconsax_plus: ^1.0.0` (pub.dev) — bộ Iconsax đầy đủ, **3 weight**: `IconsaxPlusLinear` (outline), `IconsaxPlusBold` (đặc), `IconsaxPlusBroken`. Dùng: `Icon(IconsaxPlusLinear.home)`. (Giữ `lucide_icons` tới khi sweep xong toàn bộ rồi mới gỡ.)

## Weight policy (đồng nhất toàn app)
- **Linear (outline)** = mặc định: action, list tile, header action, nav-unselected, inline.
- **Bold (đặc)** = nhấn mạnh: **nav tab khi CHỌN**, icon decorative/accent (chip eyebrow), badge huy hiệu, trạng thái filled.
- Broken: dự phòng (chưa dùng).
- Checkmark trong chấm tròn (milestone): giữ `Icons.check_rounded` (Material) — Iconsax không có check trần (chỉ tick_circle có sẵn vòng).

## Kiểm kê quy mô (PO audit)
~80–100 icon distinct (80 Lucide + ~85 Material), **437 usages**, **21 màn**. Nhóm: nav 4 tab · header (back/settings/bell/chip) · actions (gửi/đăng/camera/sửa/xoá/copy/share/save) · reactions (tim/lửa/sparkles) · reminders · settings tiles · empty/error · milestone/journey. Icon thương hiệu (launcher/splash/heart) — KHÔNG đụng ở đợt này (cần asset, để sau).

## Rollout theo ĐỢT (có checkpoint user mỗi đợt)
- **Đợt 1 PILOT (xong 2026-06-14):** bottom nav 4 tab + màn Hồ sơ + `milestone_trail`. Map: heart/messages/gallery/user (Linear↔Bold nav) · magic_star (chip) · setting_2 · edit_2 · map · flash (chuỗi) · cup (kỷ lục) · gallery (kỷ niệm) · book_1 (nhật ký) · arrow_right_3 · key · flag (Bold) · magic_star. **→ chờ user duyệt vibe.**
- **Đợt 2:** chrome dùng-chung (sub_screen_header back, HeaderIconButton call-sites, bell, EyebrowChip icons mọi màn) + Home tab.
- **Đợt 3:** Chat + Gallery (45 icon — nhiều nhất) + create_post.
- **Đợt 4:** Settings (27) + Reminders/custom-reminders (26) + notification_center.
- **Đợt 5:** Auth (login/register/forgot/verify) + setup + guest + journal + còn lại.
- **Đợt cuối:** gỡ `lucide_icons` khỏi pubspec khi 0 usage còn lại; sweep `flutter analyze` toàn repo.

## Master map (concept → IconsaxPlus) — bổ sung dần mỗi đợt
| Concept (Lucide/Material) | Iconsax | Weight |
|---|---|---|
| heart / favorite | `heart` | Linear/Bold |
| messageCircle | `messages` | Linear/Bold |
| image (tab/gallery) | `gallery` | Linear/Bold |
| user | `user` | Linear/Bold |
| sparkles | `magic_star` | Bold (accent) |
| settings | `setting_2` | Linear |
| pencil/edit | `edit_2` | Linear |
| map | `map` | Linear |
| flame (streak) | `flash` | Bold |
| trophy | `cup` | Bold |
| bookOpen | `book_1` | Bold/Linear |
| arrowRight/chevronRight | `arrow_right_3` | Linear |
| arrowLeft (back) | `arrow_left` | Linear |
| keyRound | `key` | Linear |
| flag | `flag` | Bold/Linear |
| bell/bellRing | `notification` / `notification_bing` | Linear/Bold |
| trash | `trash` | Linear |
| plus/add | `add` | Linear |
| camera | `camera` | Linear |
| send | `send_2` | Bold |
| copy | `copy` | Linear |
| share2 | `share` / `export` | Linear |
| shield | `shield_tick` / `security` | Linear |
| globe | `global` | Linear |
| clock | `clock` | Linear |
| calendar | `calendar_1` | Linear |
| check (inline) | `tick_circle` | — |
| cloudOff (error) | `cloud_cross`? (verify) | Linear |
| bellOff (empty) | `notification_status`? (verify) | Linear |

> ⚠️ Mỗi đợt: GREP tên icon thật trong package `~/.pub-cache/.../iconsax_plus-1.0.0/lib/src/iconsax_plus_linear.dart` TRƯỚC khi map (nhiều tên khác Lucide; vài concept không có tương đương 1-1 → chọn gần nghĩa nhất). Verify bằng `flutter analyze`.
