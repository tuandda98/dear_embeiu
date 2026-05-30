# 🗺️ Roadmap riêng — Auth

> Kế hoạch nội bộ feature. Toàn cảnh: [`../../ROADMAP.md`](../../ROADMAP.md). Spec: [overview.md](overview.md).

- **Trạng thái feature:** ✅ Shipped (v1.0.0) — còn nợ kỹ thuật

## Phân phase

### 🟢 Phase 1 — Vá bảo mật/độ bền trước release (P0/P1) — chưa bắt đầu
- [ ] Hash password ở local fallback (hoặc bỏ lưu password local) 🔴
- [ ] Siết validation email/password/displayName (reject emoji/độ dài cực lớn; email regex chuẩn)
- [ ] Timeout cho `_ensureFirebaseSessionReady` (`auth_service.dart:464`)
- [ ] Retry/transient cho signup cleanup (tránh account "limbo")
- *Xong khi:* Tester pass case security 5/6, không còn account limbo, validation chặt.

### 🟡 Phase 2 — Hoàn thiện UX (P2) — chưa bắt đầu
- [ ] Flow "Quên mật khẩu" (reset qua email)
- [ ] Lỗi inline rõ theo từng field

### ⚪ Phase 3 (Later)
- [ ] Social login (Google/Apple), email verification, 2FA

## Mốc đã đạt
- [v1.0.0] Register/login/logout + deleteAccount compliant + local fallback.

## Ghi chú phụ thuộc
- Phase 1 nên xong **trước release Google Play**.
