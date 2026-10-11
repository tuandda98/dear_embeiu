# 💻 Dev — pairing-funnel

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** đang làm (2026-10-11)
- **Người/role:** Dev — 2 agent song song trên 2 worktree, mỗi agent CHỈ ghi vào phần của mình bên dưới.

## Ranh giới file giữa 2 phần (để merge không đụng nhau)
- **Phần A (Apple):** `auth_service.dart`, `auth_provider.dart`, `guest_counter_screen.dart`, `login_screen.dart`, `register_screen.dart`, `settings_screen.dart`, `widgets/apple_sign_in_button.dart` (mới), `theme/app_colors.dart`, `app/app_urls.dart` (chỉ hằng `privacyPolicy`), `ios/Runner/Runner.entitlements`, ARB (chèn sau `authFirebaseAuthGeneric` + sửa `guestCtaSignIn`).
- **Phần B (QR + bộ nhớ tạm + lời nhắc):** `invite_action_buttons.dart`, `widgets/invite_qr_sheet.dart` (mới), `services/invite_clipboard.dart` (mới), `home_screen.dart`, `setup_screen.dart`, `profile_screen.dart`, `reminder_provider.dart`, `reminder_service.dart`, `app/app_urls.dart` (chỉ thêm hằng link mời ở CUỐI class), `ios/Runner/AppDelegate.swift`, `docs/get.html`, `pubspec.yaml`/`pubspec.lock`, ARB (chèn sau `inviteFollowUpBody72h` + sửa `homeWaitingStep1Desc`, metadata `inviteFollowUpBody24h`).

---

## Phần A — Đăng nhập với Apple (PF1–PF6, PF11)

- *Trạng thái:* chưa bắt đầu

<!-- Dev A ghi kế hoạch, edge case, checklist, nhật ký vào giữa 2 dòng đánh dấu này -->
<!-- /Phần A -->

---

## Phần B — Ghép đôi tại chỗ + lời nhắc mời (PF7–PF10, PF12–PF13)

- *Trạng thái:* chưa bắt đầu

<!-- Dev B ghi kế hoạch, edge case, checklist, nhật ký vào giữa 2 dòng đánh dấu này -->
<!-- /Phần B -->

---

## Nhật ký chung (Lead ghi khi merge)
- [2026-10-11] [Lead] Chia 2 phần A/B, chạy song song trên worktree riêng.
