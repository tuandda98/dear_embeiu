# 💻 Dev — Auth

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md). Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** ✅ Đã implement (baseline) — có nợ kỹ thuật

## Đã implement
- `AuthService` (Firebase + local fallback, `isUsingFirebase`), `AuthProvider` (status unknown/unauthenticated/authenticated; signIn/Up/Out/deleteAccount/refreshPushRegistration).
- `deleteAccount` callable (admin teardown). `SessionResolver.resolveStartRoute()`.

## Việc cần làm tiếp (từ nợ kỹ thuật ở overview)
- [ ] Hash password ở local fallback (hoặc bỏ lưu password local).
- [ ] Siết validation email/password/displayName (reject emoji/độ dài cực lớn; email regex chuẩn hơn).
- [ ] Thêm timeout cho `_ensureFirebaseSessionReady` (`auth_service.dart:464`).
- [ ] Retry/transient handling cho signup cleanup (tránh account "limbo").
- [ ] (Tuỳ) thêm flow quên mật khẩu.

## Nhật ký implement
- [2026-05-30] [PO] Khởi tạo doc; liệt kê nợ kỹ thuật cần Dev xử lý.
