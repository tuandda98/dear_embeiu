# Feature: UI/UX Revamp (modern · icon xịn · mượt)

> PO directive 2026-06-02. Mục tiêu chủ sở hữu: app **nhìn hiện đại, icon xịn, hiệu ứng thật mượt**. Nâng cấp hệ "Sunset Romance" hiện có, KHÔNG đập đi.
> Nguồn: audit 3 Designer subagent (đọc code thật) — 3 bên đồng thuận 5 đòn bẩy nền.

## 1. PO chốt (tự quyết)
- Làm **Đợt 1 — Nền tảng** ngay (user duyệt option 1 + giao tự quyết, 2026-06-02).
- **KHÔNG đụng build đang Apple review (1.0 build 3):** revamp chỉ code + verify local, không rebuild/submit/commit. Phát hành thành **1.1** sau khi 1.0 được duyệt.
- Duyệt 5 package: `google_fonts`, `flutter_animate`, `shimmer`, `lucide_icons`, `confetti`.

## 2. Đợt 1 — Nền tảng (5 đòn bẩy đồng thuận)
1. **Typography:** system `serif` (lệch iOS/Android) → google_fonts **Fraunces** (hero) + **Plus Jakarta Sans** (UI). Test dấu tiếng Việt.
2. **Iconography:** Material `Icons.*` → **lucide_icons** (nét mảnh đều) + chuẩn hoá size token 16/20/24.
3. **Motion + chạm:** `flutter_animate` staggered entrance + đổi tile `GestureDetector`→`InkWell` + `HapticFeedback` (đổi tab/đăng ảnh/submit) + token motion 200/280/320ms easeOutCubic.
4. **Glass thật:** thêm `BackdropFilter` blur (hiện "glass giả" thiếu blur, trừ nav home) → widget dùng chung `GlassCard` + token alpha/blur.
5. **Loader:** `CircularProgressIndicator` khắp nơi → `ShimmerSkeleton` (package `shimmer`).

## 3. Đợt 2 (sau) — Wow moments
Splash sống động (heart pulse + gradient thở + cross-fade) · Hero counter count-up + pulse glow · **Invite-code reveal "ăn mừng"** (confetti + staggered + tap-copy + haptic) · Gallery shimmer + staggered feed.

## 4. Đợt 3 (sau) — Polish
Per-screen entrance · empty-state Lottie · app-icon glyph (couple thay heart chung) · page transitions (shared-axis).

## 5. GIỮ NGUYÊN (đã premium)
App icon SVG · Gallery header co giãn handoff · Fullscreen preview (pinch+drag-dismiss+Hero arc) · Profile hero card · palette/gradient + kỷ luật token.

## 6. Nợ dọn kèm
`_buildSectionCard` copy-paste `profile_screen` ↔ `settings_screen` → tách widget chung.

## 7. Changelog
- [2026-06-02] [PO] Audit 3 Designer + tổng hợp directive. Chốt Đợt 1, giữ build review nguyên, phát hành 1.1.
- [2026-06-02] [PO orchestrate] Đợt 1 HOÀN TẤT (autonomous, 5 Dev task tuần tự + PO gate analyze mỗi chặng):
  - T1 nền: +5 package, typography Fraunces+Plus Jakarta (app_theme), token AppMotion, widget GlassCard + ShimmerSkeleton. + FIX bug nút back đè "Tạo tài khoản" (register+login, SizedBox 52).
  - T2 loaders: CircularProgressIndicator → ShimmerSkeleton (ảnh/nội dung/home/profile/custom-reminders); giữ spinner nút submit + splash.
  - T3 feel: HapticFeedback (đổi tab/đăng ảnh/submit/đổi ngày/toggle) + InkWell ripple tiles + staggered entrance flutter_animate (home/settings/gallery-feed6/reminders, chạy 1 lần).
  - T4 icons: Material → Lucide toàn app (17 file); giữ Material heart brand (11 file).
  - T5 glass: GlassCard thật cho auth/setup/invite/guest/home-hero (6 file); KHÔNG áp feed gallery/settings/profile (hiệu năng/đã đặc).
  - Verify: flutter analyze sạch sau từng task. Smoke-test simulator (guest landing) PASS — Fraunces + Lucide + glass render đúng, không crash/overflow.
  - CHƯA commit/submit. Build 1.0(3) vẫn đang Apple review — không đụng. Revamp sẽ ra 1.1.
  - Hạn chế verify: chỉ auto-screenshot được màn guest (không tap được vào login/register/home/gallery/settings qua simctl) — các màn đó compile-clean, cần mắt người xem lúc tap-through.
