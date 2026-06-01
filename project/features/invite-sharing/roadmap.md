# 🗺️ Roadmap riêng — Invite sharing

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu.

- **Trạng thái feature:** 🧪 Test PASS (code-level, Phase 1) — chờ user smoke-test thiết bị

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — Copy + Share đồng bộ (P1) — 🧪 Test PASS, chờ smoke-test
- [x] Widget dùng chung `InviteActionButtons` (2 biến thể glass-tối/sáng-rose + iconOnly)
- [x] Gắn cụm Copy/Share ở 3 nơi hiện mã (Setup / Home banner / Profile), gate `waiting_partner`
- [x] `share_plus` 11.1.0 — share sheet native câu mời song ngữ (`inviteShareMessage`), iPad-safe origin
- [x] l10n vi+en (`shareBtn`, `inviteShareMessage`); analyze sạch; cross-platform, không native
- *Xong khi:* user smoke-test runtime (share sheet iOS+Android, iPad popover, màn nhỏ, toast) OK → ✅ Done
- *Quyết định:* câu mời Phase 1 KHÔNG kèm link (app chưa live store) — link để Phase 3.

### 🟡 Phase 2 — QR code (in-person)
- [ ] A hiện QR chứa mã (qr_flutter); B quét bằng camera (mobile_scanner) → tự điền/join
- [ ] Quyền camera; chỉ hợp khi 2 người ngồi cạnh

### ⚪ Phase 3 (Later) — Universal Link / App Link 1-chạm tự-join
- [ ] A chia sẻ **link** → B chạm → app mở thẳng "Ghép đôi với [Tên]?" → 1 chạm join
- [ ] Hạ tầng: iOS Associated Domains + `apple-app-site-association` (host trên Firebase Hosting `docs/`); Android `assetlinks.json` + intent-filter; package `app_links`
- [ ] **Login bắt buộc với B** (join ghi vào tài khoản B) → nhớ mã (pending invite) + **auto-resume sau khi đăng nhập 1 lần** → màn xác nhận 1-chạm
- [ ] Ca B chưa cài app: link → store → cài → đăng nhập → fallback clipboard áp mã (deferred)
- [ ] Nối link vào cuối `inviteShareMessage` (đã chừa sẵn chỗ)
- [ ] **KHÔNG dùng Firebase Dynamic Links** (Google khai tử 2025)
- [ ] Cân nhắc siết bảo mật invite-code enumeration (nợ kế thừa coupling) khi join dễ hơn

## Mốc đã đạt
- [2026-06-01] Phase 1 Spec → Design → Dev → Test PASS code-level (PO orchestrate). Cross-platform, không native.

## Ghi chú phụ thuộc
- Mở rộng feature [coupling](../coupling/overview.md) — không đổi logic join/transaction/rules.
- Phase 3 cần cấu hình native từng nền (iOS AASA + Android assetlinks) + xử lý auth-resume.
