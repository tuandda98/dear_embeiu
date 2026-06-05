# Auth — Tài khoản & đăng nhập

> File PO sở hữu. Nguồn sự thật chung. Designer/Dev/Tester đọc trước.

- **Feature:** auth
- **Ưu tiên:** P0 (nền tảng)
- **Trạng thái:** ✅ Shipped (v1.0.0) · 🧪 **Đợt 1 (quên-mật-khẩu + verify-email): code DONE, PASS code-level — chờ smoke-test runtime** · ⏳ Đợt 2 (Google/Apple) chờ user setup Console
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 2,12,13

## 1. Mô tả
Mỗi người dùng có tài khoản riêng (email/password). Đăng ký → đăng nhập → tạo/join couple. Có **xoá tài khoản** (bắt buộc theo App Store 5.1.1(v) & Google Play). Có **local fallback** (FlutterSecureStorage) khi Firebase chưa sẵn sàng — quyết định bằng `AuthService.isUsingFirebase`.

## 2. Phạm vi
- **Trong (v1.0):** register (displayName + email + password + tick điều khoản), login, logout, persist session, fresh-install purge, deleteAccount (callable), refresh FCM khi resume.
- **Trong (Đợt 1 — 2026-06-05, đang làm):** **Quên mật khẩu** (Firebase `sendPasswordResetEmail`, không backend) + **Xác thực email bắt buộc khi đăng ký** (link-based, Firebase `sendEmailVerification`; hard-gate có grandfather user cũ).
- **Đợt 2 (đã chốt, chờ user setup Console/Xcode):** social login **Google** (`google_sign_in`) + **Apple** (`sign_in_with_apple`). Apple bắt buộc đi kèm Google trên iOS (App Store Guideline 4.8).
- **Ngoài:** 2FA, OTP/mã-số qua email (đã cân nhắc & loại — xem D-auth1).

## 2b. Decision log (Đợt 1)
- **D-auth1 — Xác thực bằng LINK, không phải mã số (OTP):** Firebase Auth chỉ có sẵn verify bằng link; "gửi mã 6 số" phải tự dựng Cloud Function + email provider (SendGrid/Resend) + setup 2× dev/prod + có phí. Về chống spam **link ≡ mã số** (đều chứng minh sở hữu hộp mail). → Chọn link: miễn phí, 0 backend, ít điểm hỏng. (User chốt 2026-06-05.)
- **D-auth2 — Hard-gate khi đăng ký, CÓ grandfather:** Bắt buộc verify mới vào app (chặn cả register lẫn login để spammer không né bằng tắt/mở app). ⚠️ App đang LIVE (v1.0) → **grandfather theo `User.metadata.creationTime`**: chỉ bắt buộc với tài khoản tạo SAU ngày ra mắt (`kEmailVerificationCutoff`); user cũ + provider Google/Apple (đã verified) **không bị chặn** → tránh khóa cứng user thật hiện có.
- **D-auth3 — Chỉ áp khi `isUsingFirebase`:** Nhánh local-fallback không có hạ tầng email → bỏ qua verify; Quên-mật-khẩu ở local hiện thông báo "cần kết nối".
- **D-auth4 — Chống email-enumeration:** Quên mật khẩu hiển thị thông báo "đã gửi" kể cả khi email không tồn tại (không lộ email nào đã đăng ký).

## 3. Code liên quan
- `lib/services/auth_service.dart` (~548 dòng), `lib/providers/auth_provider.dart`
- `lib/screens/login_screen.dart`, `register_screen.dart`, `auth_gate_screen.dart`, `splash_screen.dart`
- `lib/app/session_resolver.dart` (gate route theo trạng thái auth/couple)
- Backend: `functions/index.js` → `deleteAccount`; rules `users/{uid}` (delete:false, email/inviteCode immutable)

## 4. Acceptance (đã đạt khi ship)
- [x] Đăng ký/đăng nhập/đăng xuất hoạt động (Firebase + local fallback)
- [x] Xoá tài khoản teardown đầy đủ (couple/photos/Storage/devices/invite_code/user/auth)
- [x] Session persist + purge khi reinstall

## 4b. Acceptance (Đợt 1 — ✅ PASS code-level, chờ smoke-test runtime)
- [x] Login có link "Quên mật khẩu?" → màn nhập email → gửi reset, prefill email đang gõ, thông báo trung lập (D-auth4).
- [x] Đăng ký mới → tự gửi email verify → điều hướng vào màn "Kiểm tra hộp thư" (register Firebase đẩy thẳng `/verify-email` — deterministic, fix F1; không vào setup/home).
- [x] Màn verify: hiện email, nút "Tôi đã xác thực" (reload+check), "Gửi lại" (cooldown ~60s sống qua resume), "Đăng xuất" (escape hatch), auto-poll + re-check khi resume, `PopScope(canPop:false)`.
- [x] User cũ (pre-cutoff) + Google/Apple login **KHÔNG** bị chặn (grandfather) — resolver fail-open giữ nguyên. ⚠️ smoke-test runtime bắt buộc.
- [x] Local-fallback: không crash, verify bị skip, quên-mật-khẩu báo cần kết nối.
- [x] l10n đủ vi+en (21 key); `fvm flutter analyze` sạch (0 issue).
- ⏳ **Chờ:** 6 smoke-test trên thiết bị thật (xem `test.md`) — đặc biệt #1 (signup mới bị đẩy verify) + #2 (user cũ không bị khóa).

## 5. Nợ kỹ thuật / rủi ro (cần Tester + Dev xử lý)
- 🔴 **Local fallback lưu password PLAINTEXT** trong FlutterSecureStorage (`auth_service.dart` ~188, ~365) — không hash.
- 🟡 Validation yếu: email chỉ `contains('@')` (qua `a@b@c`); password chỉ `length>=6`; không reject emoji/unicode/độ dài cực lớn.
- 🟡 `_ensureFirebaseSessionReady` (`auth_service.dart:464`) không timeout → có thể treo nếu auth state không emit đúng uid.
- 🟡 Signup cleanup: tạo user xong mà save profile fail → xoá user; nếu delete cũng fail → account "limbo".
- 🟡 Firebase vs local khác hành xử: email normalize (Firebase trim, local trim+lowercase), duplicate-email case-sensitivity, userId (UID vs UUID v4).

## 6. Changelog
- [2026-05-30] [PO] Tài liệu hoá feature đã ship; ghi nhận nợ kỹ thuật từ catalog security/logic (CLAUDE.md mục 12,13).
- [2026-06-05] [PO] Spec Đợt 1: Quên mật khẩu + Xác thực email bắt buộc (link, grandfather). Chốt 4 decision D-auth1..4. Đợt 2 (Google/Apple) chờ user setup Console. Bật pipeline Designer→Dev→Tester.
- [2026-06-05] [Dev] **Custom verification email (Cách B)** — đổi từ mail Firebase mặc định sang **email HTML branded gửi qua Resend** (chống spam + nút "Xác thực" đẹp). Callable `sendCustomVerificationEmail` (Admin SDK `generateEmailVerificationLink` + Resend API, secret `RESEND_API_KEY`); template `functions/emails/verification_email.js` (vi/en, bulletproof button, sunset brand); client `signUp`/`resend` gọi callable. Gửi từ `noreply@dearembeiu.com` (domain riêng, SPF/DKIM). analyze sạch, node -c OK. **CHƯA deploy** — chờ user verify domain Resend + set secret. Build-config: dev=`.dev` bundle id (cài cạnh App Store), DEV đã Blaze.
