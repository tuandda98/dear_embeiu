# Design Unify — Test log

> File Tester sở hữu. Nghiệm thu theo [overview.md](overview.md) AC 1–5 + [design.md](design.md) PHẦN E.

## Nghiệm thu code-level toàn feature (2026-06-11) — PASS-có-điều-kiện

**Môi trường:** branch `release/1.1.6`, uncommitted working tree; `fvm flutter analyze` = 0 issue; `fvm flutter test` = All tests passed (18).

### Verdict
- **AC1–AC4: PASS (code-level).** 15 màn + widgets khớp spec C0–C17; checklist E các mục kiểm-được-bằng-code đều đạt (nền dawnBlush thống nhất, back chuẩn HeaderIconButton/subScreenAppBar ở 100% màn con, chữ trắng có bóng tối qua helper AppTheme smart-default, ContentCard trắng đặc r24 đúng chỗ, GlassCard chỉ còn auth/setup/guest, hết radius 30, hết GestureDetector trần ở mọi chỗ spec nêu, 4 vá Reduce Motion [VERIFIED code] + `_OnceEntrance` 0 bản copy, DateFormat truyền locale đủ chỗ D3, skeleton thay spinner ở History/NotifCenter, RefreshIndicator nền trắng Home+Gallery).
- **AC5: FAIL tại thời điểm nghiệm thu** — `project/design-system.md` chưa được cập nhật (vẫn bản cũ calendar-leaf/bell-disc). → **PO đã đóng cùng ngày sau nghiệm thu** (xem nhật ký overview).
- Behavior bất biến [VERIFIED]: không đụng providers/services/routes/firestore.rules/functions/pubspec.yaml; ARB chỉ chứa 13 key `homeGreeting*` của phiên trước (en+vi khớp, generated đồng bộ).
- Home pixel-identical [VERIFIED]: SectionHeader/ContentCard/ComposePill copy nguyên trị; IconBadge waiting banner override đúng 40/r14/.10; `_entrance` constant-params còn nguyên.

### Findings
1. **major (doc):** AC5 — design-system.md không đổi trên đĩa. → PO đóng cùng ngày.
2. **minor (process):** dev.md chỉ log Stage A, thiếu nhật ký 4 nhóm C1–C15/A8.3/A8.4; ROADMAP chưa cập nhật. → PO đóng cùng ngày.
3. **minor:** `lib/widgets/screen_background.dart` (B1) 0 consumer — màn vẫn inline gradient; ghi nợ dev.md (wire dần, tránh churn).
4. **minor:** `pubspec.lock` đổi mirror pub.dev → pub.flutter-io.cn toàn file (không đổi version) — artifact môi trường, cân nhắc revert trước commit.
5. **minor:** `memory_cinema_card.dart` — `didChangeDependencies`→`_restartTimer()` + `context.watch<ReactionProvider>` ⇒ reaction realtime reset đồng hồ auto-advance 7s. Steps: 2 máy, máy B thả reaction liên tục <7s/lần → cinema máy A không bao giờ tự trượt. → **Dev đã fix cùng ngày** (chỉ restart khi gate đổi); cần re-test runtime case này.
6. **info:** GestureDetector trần còn ở `today_ritual_card.dart` (_textLink) + `gallery_screen.dart` (tap ảnh feed) — ngoài danh sách spec, ghi nợ E7.
7. **info:** NotifCenter ContentCard trong ClipRRect mang shadow thừa (bị clip; có thể lộ vệt khi swipe-delete) — cosmetic.

### [CẦN TEST runtime] (smoke-test thiết bị trước khi release)
1. Reduce Motion ON/OFF giữa phiên: aurora counter đứng yên · cinema không tự trượt/không Ken Burns nhưng swipe tay vẫn chạy · marquee gallery tĩnh rồi tự chạy lại khi tắt RM · entrance không chạy.
2. Tab ẩn → cinema Timer dừng; case finding #5: thả reaction liên tục xem slide có kẹt không (sau fix).
3. Contrast đo screenshot ≥4.5:1 (month chip, eyebrow, guest CTA, sign-out setup, status banners).
4. Home pixel-diff bằng mắt trước/sau refactor (ContentCard/SectionHeader/IconBadge/ComposePill).
5. Gallery header co giãn compact↔expanded với card trắng đặc — crossfade không lộ viền.
6. NotifCenter: swipe-delete (viền/shadow trên nền đỏ), unread ring + ripple, overflow menu mở đúng vị trí + mark-all-read/clear-all chạy đúng.
7. Behavior flows: login→home, join couple, đăng ảnh, reaction, reminder toggle, leave couple, deep-link notification; đổi EN xem ngày tháng (D3).

## Nhật ký
- [2026-06-11] [tester] Nghiệm thu code-level toàn feature: PASS-có-điều-kiện (AC1–4 PASS; AC5 doc chưa cập nhật lúc nghiệm thu; 7 findings — 1 major doc, 4 minor, 2 info). Analyze 0 issue, test suite 18/18 pass. Finding #5 + AC5 được Lead đóng ngay sau đó.
