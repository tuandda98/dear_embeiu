# Auth — Tài khoản & đăng nhập

> File PO sở hữu. Nguồn sự thật chung. Designer/Dev/Tester đọc trước.

- **Feature:** auth
- **Ưu tiên:** P0 (nền tảng)
- **Trạng thái:** ✅ Shipped (v1.0.0) — có nợ kỹ thuật cần test/siết
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 2,12,13

## 1. Mô tả
Mỗi người dùng có tài khoản riêng (email/password). Đăng ký → đăng nhập → tạo/join couple. Có **xoá tài khoản** (bắt buộc theo App Store 5.1.1(v) & Google Play). Có **local fallback** (FlutterSecureStorage) khi Firebase chưa sẵn sàng — quyết định bằng `AuthService.isUsingFirebase`.

## 2. Phạm vi
- **Trong:** register (displayName + email + password + tick điều khoản), login, logout, persist session, fresh-install purge, deleteAccount (callable), refresh FCM khi resume.
- **Ngoài:** social login (Google/Apple), quên mật khẩu/reset, email verification, 2FA.

## 3. Code liên quan
- `lib/services/auth_service.dart` (~548 dòng), `lib/providers/auth_provider.dart`
- `lib/screens/login_screen.dart`, `register_screen.dart`, `auth_gate_screen.dart`, `splash_screen.dart`
- `lib/app/session_resolver.dart` (gate route theo trạng thái auth/couple)
- Backend: `functions/index.js` → `deleteAccount`; rules `users/{uid}` (delete:false, email/inviteCode immutable)

## 4. Acceptance (đã đạt khi ship)
- [x] Đăng ký/đăng nhập/đăng xuất hoạt động (Firebase + local fallback)
- [x] Xoá tài khoản teardown đầy đủ (couple/photos/Storage/devices/invite_code/user/auth)
- [x] Session persist + purge khi reinstall

## 5. Nợ kỹ thuật / rủi ro (cần Tester + Dev xử lý)
- 🔴 **Local fallback lưu password PLAINTEXT** trong FlutterSecureStorage (`auth_service.dart` ~188, ~365) — không hash.
- 🟡 Validation yếu: email chỉ `contains('@')` (qua `a@b@c`); password chỉ `length>=6`; không reject emoji/unicode/độ dài cực lớn.
- 🟡 `_ensureFirebaseSessionReady` (`auth_service.dart:464`) không timeout → có thể treo nếu auth state không emit đúng uid.
- 🟡 Signup cleanup: tạo user xong mà save profile fail → xoá user; nếu delete cũng fail → account "limbo".
- 🟡 Firebase vs local khác hành xử: email normalize (Firebase trim, local trim+lowercase), duplicate-email case-sensitivity, userId (UID vs UUID v4).

## 6. Changelog
- [2026-05-30] [PO] Tài liệu hoá feature đã ship; ghi nhận nợ kỹ thuật từ catalog security/logic (CLAUDE.md mục 12,13).
