# 🗺️ ROADMAP (portfolio) — Index tất cả feature

> **Cấp dự án:** toàn cảnh mọi feature + pha hiện tại. Roadmap CHI TIẾT của từng feature nằm ở `features/<ten>/roadmap.md` (chia phase Now/Next/Later riêng).
> Cập nhật trạng thái ở đây mỗi khi feature đổi pha.
> Trạng thái: `📋 Spec` → `🎨 Design` → `💻 Dev` → `🧪 Test` → `✅ Done` · (`⏸️ Paused`, `❌ Dropped`)
> Ưu tiên: P0 (chặn release/giá trị cao) · P1 · P2.

## Feature đã ship (v1.0.0) — đã tài liệu hoá làm baseline

> Đã ✅ ship; còn **nợ kỹ thuật** ghi trong `overview.md` mục "Nợ kỹ thuật" của từng feature (Tester nên chạy, Dev nên siết trước/sau release Play).

| Feature | Ưu tiên | Trạng thái | Nợ kỹ thuật nổi bật | Spec / Roadmap riêng |
|---------|---------|-----------|---------------------|----------------------|
| Auth (tài khoản) | P0 | ✅ Shipped | 🔴 local password plaintext; validation yếu | [spec](features/auth/overview.md) · [roadmap](features/auth/roadmap.md) |
| Coupling (mã mời) | P0 | ✅ Shipped | 🔴 invite-code enumeration; coupleId sửa được | [spec](features/coupling/overview.md) · [roadmap](features/coupling/roadmap.md) |
| Counter (đếm ngày yêu) | P0 | ✅ Shipped | 🔴 ngày không đổi theo ngôn ngữ (gap A) | [spec](features/counter/overview.md) · [roadmap](features/counter/roadmap.md) |
| Gallery (ảnh chung + push) | P0 | ✅ Shipped | 🔴 push hardcode VI (gap B); 🟡 ai cũng xoá ảnh partner | [spec](features/gallery/overview.md) · [roadmap](features/gallery/roadmap.md) |
| Reminders (local) | P1 | ✅ Shipped | 🟡 permission fail im lặng; DST | [spec](features/reminders/overview.md) · [roadmap](features/reminders/roadmap.md) |

## Đang làm

| Feature | Ưu tiên | Trạng thái | Spec / Roadmap riêng |
|---------|---------|-----------|----------------------|
| Custom reminders (reminder tuỳ chỉnh, local) | P1 | 🧪 Test PASS (smoke on-device OK) — gate D7 đang đổi sang force-open theo Reminders v2 | [spec](features/custom-reminders/overview.md) · [roadmap](features/custom-reminders/roadmap.md) |
| Reminders v2 (bỏ nudge hằng ngày + milestone tự bật/tắt + giờ-theo-mốc Dv8) | P1 | 🧪 Test PASS — chờ smoke-test thiết bị | [spec](features/reminders/overview.md) (5b) · [roadmap](features/reminders/roadmap.md) |
| Settings (màn Cài đặt tổng, gom Profile + giờ theo mốc Dv8) | P1 | 🧪 Test PASS (29/30) — chờ user smoke-test thiết bị (2026-05-31) | [spec](features/settings/overview.md) · [roadmap](features/settings/roadmap.md) |
| Photo report (UGC compliance Apple 1.2) | P1 | ✅ Done (2026-05-31) — rules đã deploy | [spec](features/photo-report/overview.md) · [roadmap](features/photo-report/roadmap.md) |
| Guest mode (fix Apple reject 5.1.1) | P0 | 🧪 Test PASS code-level — chờ user smoke-test thiết bị (5 case runtime) (2026-06-01) | [spec](features/guest-mode/overview.md) · [roadmap](features/guest-mode/roadmap.md) |
| Invite sharing (copy/share mã mời — giảm ma sát ghép đôi) | P1 | 🧪 Test PASS code-level — chờ user smoke-test (Phase 1: copy/share cross-platform; QR=P2, link 1-chạm=P3 để sau) (2026-06-01) | [spec](features/invite-sharing/overview.md) · [roadmap](features/invite-sharing/roadmap.md) |
| Home engagement (đẩy đăng ảnh từ Home — North Star) | P0 | 🧪 Test PASS code-level — chờ user smoke-test (Phase 1: CTA "Thêm kỷ niệm" + empty-state; partner-signal/streak=P2) (2026-06-01) | [spec](features/home-engagement/overview.md) · [roadmap](features/home-engagement/roadmap.md) |

## Đã Done

| Feature | Ưu tiên | Trạng thái | Spec / Roadmap riêng |
|---------|---------|-----------|----------------------|
| Language (đa ngôn ngữ) | P0 | ✅ Done (2026-05-31) | [spec](features/language/overview.md) · [roadmap](features/language/roadmap.md) |

> Còn nợ nhỏ: Gap G (analytics `language_changed`) hoãn theo feature analytics.

## Backlog (chưa tạo folder — tạo khi bắt đầu làm)

Theo `../CLAUDE.md` mục 11 (Product roadmap):

**NOW**
- Analytics + event funnel (install→couple→ảnh đầu→D7) — *nền cho mọi quyết định, P0*
- Onboarding/tutorial (giảm rớt bước ghép đôi)
- Reactions ❤️ trên ảnh (tận dụng push) — *mở rộng feature gallery*
- Day streak (đã stubbed l10n)

**NEXT**
- Home-screen widget
- Daily question (có thể dùng AI/Claude API)
- Shared calendar + đếm ngược sự kiện
- Dark mode

**LATER**
- Premium/subscription (sau khi có analytics + retention)
- AI features (caption/lời yêu, "ngày này năm xưa")
- LDR pack / chat / wishlist chung

---

*Khi tạo feature mới: copy `_templates/` (gồm `roadmap.md`) → `features/<ten-feature>/`, thêm dòng vào bảng phù hợp, xoá khỏi Backlog. Mỗi feature tự quản phase chi tiết trong `roadmap.md` của nó.*
