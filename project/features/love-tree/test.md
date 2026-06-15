# Cây tình yêu (Love Tree) — test log (Tester)

## [2026-06-14] [Tester] Nghiệm thu v1 ở mức CODE (read-only) — VERDICT: PASS (SHIP code-level)

`flutter analyze lib/` = **No issues found**. Phạm vi: `love_tree_service.dart`, `love_tree_screen.dart`, `streak_chip.dart`, `app_vi/en.arb`. KHÔNG đụng backend/native.

### Acceptance criteria (design.md §10) — 12/12 PASS [VERIFIED code]
1. Vào màn từ StreakChip + header/back — PASS (streak_chip.dart:79; sub_screen_header.dart:70).
2. Số hoa = mốc vượt 3 nguồn, monotonic, dùng `longestStreak` — PASS (love_tree_service.dart:91-108). Mốc: ngày 30/100/200/365/520/730/1000/1314; streak 3/7/30/100/365; ảnh 1/10/25/50/100.
3. Stage 0/1-2/3-5/6-9/≥10 — PASS (service.dart:112-118).
4. Vị trí hoa ổn định (golden-angle 137.5° + sqrt + jitter Knuth-hash theo index, KHÔNG Random/DateTime.now) — PASS (screen.dart:393-423).
5. Nhuỵ đúng loại (ngày=heart/rose, streak=flash/cam-hồng, ảnh=gallery/lavender) — PASS (service.dart:145-180).
6. Animation nở + banner + lastSeen postFrame, chống re-fire — PASS logic (screen.dart:62-92, 182-188).
7. reduceMotion tắt sạch (animate/confetti gate, banner tĩnh, lastSeen vẫn ghi) — PASS (screen.dart:188, 960).
8. Badge entry mất sau khi xem — PASS (streak_chip.dart:167-183 + _commitSeen).
9. States biên (0 hoa/waiting/no-couple/loading/fail-soft) — PASS (screen.dart:143-170).
10. Cùng vun đắp (3 InkTile, v1 pop về Home) + Cột mốc (đã nở + mốc kế "còn N" clamp≥1) — PASS.
11. Token brand (dawnBlush, ContentCard r24, Quicksand, cây/hoa 100% CustomPaint, KHÔNG asset) — PASS.
12. i18n vi=en 31 key, không hardcode, `{count}` int đúng — PASS.

### Bug — KHÔNG có critical/major
An toàn: không chia-0, mounted check sau await, dispose đủ (confetti/controller/timer), box app_settings <String> mở trước runApp → readLastSeen không ném.

### Minor (không chặn ship)
- [minor] `Future.delayed` _LoveFlower không cancel-able nhưng có mounted guard → không leak.
- [minor] 2 ARB key thừa: `loveTreeFlowerCountZero`, `loveTreeMilestoneAllDone` (dead copy, giữ cho v-sau).

### Lệch spec — chấp nhận
- Icon IconsaxPlus thay Lucide (nhất quán app); heart=IconsaxPlusBold.heart.
- Canopy anchor hoa theo stage thật (cải tiến).

### [CẦN TEST runtime — 1 thiết bị]
R1 animation nở mượt + đúng tập bông mới · R2 confetti emit canopy không bị clip · R3 stage đông hoa (6-18) nhuỵ không chồng che · R4 thoát trước postFrame → animate lại (hiếm) · R5 badge StreakChip mất sau pop về Home · R6 thẩm mỹ 5 stage + glow/gradient trên GPU thật.

### Kết luận: PASS code-level — SHIP được. Smoke-test runtime R1-R6 trước khi gộp release.
