# 💻 Dev — Auth

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md). Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** ✅ Baseline đã implement · ✅ Đợt 1 (Quên mật khẩu + Xác thực email) implement xong, sẵn sàng test — có nợ kỹ thuật · ✅ Email xác thực custom HTML qua Resend (Cách B) code xong, **CHƯA deploy** (chờ secret `RESEND_API_KEY` + verify domain Resend)

## Đã implement
- `AuthService` (Firebase + local fallback, `isUsingFirebase`), `AuthProvider` (status unknown/unauthenticated/authenticated; signIn/Up/Out/deleteAccount/refreshPushRegistration).
- `deleteAccount` callable (admin teardown). `SessionResolver.resolveStartRoute()`.

### Đợt 1 — Quên mật khẩu + Xác thực email (2026-06-05)
- **`AuthService`** (`lib/services/auth_service.dart`):
  - `kEmailVerificationCutoff = DateTime.utc(2026,6,5)` (top-level final).
  - `String? get currentEmail` (=`_auth.currentUser?.email`).
  - `bool get requiresEmailVerification`: true CHỈ khi `isUsingFirebase` + có user + `!emailVerified` + `creationTime != null` + `!creationTime.isBefore(cutoff)` (gồm cả mốc). Local/grandfather/Google-Apple → false.
  - `sendPasswordResetEmail(email)`: Firebase `sendPasswordResetEmail`; **nuốt `user-not-found`** coi như success (D-auth4 anti-enumeration); `invalid-email`/khác → map qua `_mapFirebaseAuthError` throw; local → throw `AuthException(forgotPasswordLocalFallback)`.
  - `resendEmailVerification()`: `currentUser?.sendEmailVerification()`, map lỗi.
  - `reloadAndCheckEmailVerified()`: `user.reload()` rồi đọc `currentUser?.emailVerified ?? false`.
  - `signUp` (nhánh Firebase): sau `saveUserProfile` → `firebaseUser.sendEmailVerification()` bọc try/catch (gửi fail KHÔNG hỏng signup).
- **`AuthProvider`** (`lib/providers/auth_provider.dart`): expose `requiresEmailVerification`, `currentEmail`; thêm `requestPasswordReset()`, `resendVerificationEmail()`, `reloadAndCheckEmailVerified()` (set errorMessage khi lỗi, trả bool; reload offline → coi như chưa verify).
- **`AppRoutes`**: `forgotPassword='/forgot-password'`, `verifyEmail='/verify-email'`; đăng ký vào route table ở `lib/main.dart`.
- **`SessionResolver._resolve`**: ngay sau block unauthenticated, TRƯỚC khi load couple — `if (requiresEmailVerification)` → clear watcher/photo/note/dq/reaction/streak + cancel daily-question schedule + `return verifyEmail` (gate, không wire watcher).
- **`ForgotPasswordScreen`** (`lib/screens/forgot_password_screen.dart`): nhận prefill email qua route args (String); states idle/sending/sent(AnimatedSwitcher+AnimatedSize form⇄xác nhận)/error(SnackBar)/local-fallback(banner warning, form disabled). "Quay lại đăng nhập" → `maybePop`; "Gửi lại" ở state sent.
- **`VerifyEmailScreen`** (`lib/screens/verify_email_screen.dart`): `PopScope(canPop:false)`, KHÔNG back-arrow, có LanguageToggle. Hiện email từ `currentEmail`. "Tôi đã xác thực" → reload+check → true: `pushNamedAndRemoveUntil(authGate)`, false: banner `verifyEmailNotYet`. "Gửi lại email" OutlinedButton + **cooldown 60s** (anchor wall-clock `_cooldownEndsAt`, sống qua resume; bật ngay khi vào màn vì register đã auto-gửi). "Đăng xuất" (tái dùng `signOutBtn`) → signOut → authGate. Auto-poll Timer.periodic 4s + `WidgetsBindingObserver.resumed` check ngay; verified → điều hướng, hủy timer.
- **Login** (`lib/screens/login_screen.dart`): link "Quên mật khẩu?" (TextButton rose w700 13, align-right, giữa password field & nút submit) → `pushNamed(forgotPassword, arguments: email.trim())`.
- **l10n**: thêm **21 key** vào `app_en.arb`+`app_vi.arb` (tái dùng `signOutBtn` thay `verifyEmailSignOut`; gồm `verifyEmailSuccess` — nay đã dùng, xem fix F2 dưới); placeholders `{email}` (forgotPasswordSentBody, verifyEmailSubtitle) + `{time}` (verifyEmailResendCountdown). Chạy `fvm flutter gen-l10n`.

### Email xác thực custom HTML qua Resend — Cách B (2026-06-05)
> Cơ chế verify GIỮ NGUYÊN (vẫn oobCode Firebase, app vẫn auto-poll `reload()`). Chỉ đổi CÁCH gửi mail: thay `FirebaseUser.sendEmailVerification()` (template mặc định Firebase) bằng email HTML branded gửi qua Resend từ `Dear Embeiu <noreply@dearembeiu.com>`.

- **`functions/emails/verification_email.js`** (MỚI): export `buildVerificationEmail({name, verifyUrl, lang})` → `{subject, html}`. Layout `<table>` + inline CSS, web-safe font stack, max-width 600 card trắng trên `#F4F4F7`, header gradient sunset (`#FF6B9D→#FFB6C1` + `bgcolor="#FF6B9D"` fallback Outlook), bulletproof button table nền `#FF4D6D` chữ trắng bo 28, link fallback text + dòng giải thích, security note nền `#FFF5F8`, footer `dearembeiu.com` (KHÔNG unsubscribe — transactional). vi+en theo `lang` (fallback 'vi'); `name` HTML-escape (chống injection), rỗng → "Chào bạn,"/"Hi there,"; `verifyUrl` dùng cho cả `href` nút lẫn text fallback. Smoke-test: HTML ~6.8KB (<102KB Gmail clip), escaping OK, fallback lang OK.
- **`functions/index.js`** — callable **`sendCustomVerificationEmail`** (onCall v2, region us-central1, `secrets: [RESEND_API_KEY]`):
  - Yêu cầu auth (`request.auth`) → chưa auth throw `HttpsError('unauthenticated')`.
  - `admin.auth().getUser(uid)` → lấy email/displayName/emailVerified **từ Auth record** (không tin client). Email rỗng → `failed-precondition`. `emailVerified===true` → `return {skipped:true}` (khỏi gửi).
  - `admin.auth().generateEmailVerificationLink(email)` **KHÔNG truyền actionCodeSettings** (dùng action URL mặc định → khỏi cấu hình authorized continue-domain).
  - `lang` = `request.data.languageCode` (fallback 'vi'); `buildVerificationEmail(...)` → POST `https://api.resend.com/emails` (header `Authorization: Bearer <RESEND_API_KEY>`, body `{from, to:[email], subject, html}`) qua `fetch` (Node 20 global). Resend status !2xx HOẶC fetch throw → `HttpsError('internal')` (client biết để hiện "Gửi lại").
  - Khai báo `const RESEND_API_KEY = defineSecret('RESEND_API_KEY')` + `const VERIFICATION_EMAIL_FROM = 'Dear Embeiu <noreply@dearembeiu.com>'` ở đầu file. KHÔNG đụng function cũ.
- **`lib/services/auth_service.dart`**:
  - `signUp` (nhánh Firebase): THAY `firebaseUser.sendEmailVerification()` → `_sendCustomVerificationEmail()` (vẫn bọc try/catch nuốt lỗi — gửi fail KHÔNG hỏng signup).
  - `resendEmailVerification()`: THAY `currentUser?.sendEmailVerification()` → `_sendCustomVerificationEmail()`; bắt `FirebaseFunctionsException` (→ `AuthException(message ?? authNetworkError)`) + giữ nhánh `FirebaseAuthException` cũ.
  - `_sendCustomVerificationEmail()` (private): gọi `_functions.httpsCallable('sendCustomVerificationEmail').call({'languageCode': _activeLanguageCode})`.
  - `_activeLanguageCode` (private getter): `AppL10n.strings.localeName` → tách lấy phần 'vi'/'en', fallback 'vi' (no-context, mirror cách `push_notification_service._currentLanguageCode`).
  - KHÔNG đụng gate/resolver/verify-screen (độc lập với cách gửi mail).
- **`node -c`**: `index.js` OK + `verification_email.js` OK. **`fvm flutter analyze`** (auth_service.dart + app_l10n.dart): `No issues found!`.
- **⚠️ CHƯA DEPLOY** — cần (1) set secret `RESEND_API_KEY` + (2) verify domain `dearembeiu.com` trên Resend trước. Lệnh ở mục "Deploy / việc user cần làm" dưới.

#### Deploy / việc user (PO) cần làm trước khi test
1. **Verify domain `dearembeiu.com` trên Resend** (DNS records SPF/DKIM) — bắt buộc để gửi từ `noreply@dearembeiu.com` không bị bounce.
2. **Set secret** (mỗi project riêng — dev test trước, prod sau):
   - Dev: `npx firebase-tools functions:secrets:set RESEND_API_KEY --project dev`
   - Prod: `npx firebase-tools functions:secrets:set RESEND_API_KEY --project prod`
3. **Deploy function** (dev trước):
   - Dev: `npx firebase-tools deploy --only functions:sendCustomVerificationEmail --project dev`
   - Prod (sau khi dev OK): `npx firebase-tools deploy --only functions:sendCustomVerificationEmail --project prod`
4. (Không cần deploy rules/storage/native — chỉ thêm 1 callable + client wire.)

### Fix vòng nghiệm thu Tester — F1/F2 (2026-06-05)
- **F1 — gate đăng ký deterministic (không phụ thuộc `creationTime`):** `register_screen.dart` `_submit`, sau `didSignUp==true` → nếu `authProvider.isUsingFirebase` điều hướng THẲNG `AppRoutes.verifyEmail` (`pushNamedAndRemoveUntil`), không qua `authGate`/resolver. Nhánh local-fallback (`!isUsingFirebase`) GIỮ NGUYÊN về `authGate` (không gate verify — D-auth3). Khắc phục lỗ fail-open khi SDK trả `metadata.creationTime == null` ngay sau `createUserWithEmailAndPassword` → user mới lọt setup không bị bắt verify. **Resolver `_resolve` (gate cold-start/login-lại của user chưa verify) GIỮ NGUYÊN** — fail-open ở đó là cố ý (bảo vệ grandfather pre-cutoff khỏi bị khoá).
- **F2 — dùng dead key `verifyEmailSuccess` (option a):** `verify_email_screen.dart` `_checkVerified`, khối `verified` → hiện SnackBar nhẹ `verifyEmailSuccess` (clearSnackBars trước) NGAY trước `pushNamedAndRemoveUntil(authGate)`; phủ cả nút "Tôi đã xác thực" (manual) lẫn auto-poll/resume vì cùng đi qua nhánh này. KHÔNG xoá key, KHÔNG đụng ARB → không cần `gen-l10n`. ARB vẫn **21 key** Đợt 1, tất cả đã có nơi dùng.
- **Backend/native/ARB:** KHÔNG đổi. **Deploy:** không cần. **`fvm flutter analyze`:** `No issues found!`.
- **Backend/native:** KHÔNG đổi (dùng sẵn Firebase Auth `sendPasswordResetEmail`/`sendEmailVerification`; KHÔNG đụng rules/functions/native). **Deploy:** không cần.
- **`fvm flutter analyze`:** `No issues found!` (0 error, 0 warning).

## Việc cần làm tiếp (từ nợ kỹ thuật ở overview)
- [ ] Hash password ở local fallback (hoặc bỏ lưu password local).
- [ ] Siết validation email/password/displayName (reject emoji/độ dài cực lớn; email regex chuẩn hơn).
- [ ] Thêm timeout cho `_ensureFirebaseSessionReady` (`auth_service.dart:464`).
- [ ] Retry/transient handling cho signup cleanup (tránh account "limbo").
- [ ] (Tuỳ) thêm flow quên mật khẩu.

## Điểm cần Tester chú ý (Đợt 1)
- **Grandfather (D-auth2):** user pre-cutoff (tạo trước 2026-06-05 UTC) + chưa verified KHÔNG bị gate — regression-test bắt buộc (`requiresEmailVerification` dùng `!creationTime.isBefore(cutoff)`, mốc cutoff = in-scope). Google/Apple (Đợt 2) verified sẵn → tự false.
- **D-auth4 anti-enumeration:** email không tồn tại vẫn rơi vào state `sent` (chỉ lỗi mạng/định dạng mới báo). Cần verify thực tế trên thiết bị (server-side Firebase quyết định gửi hay không; client luôn hiện "đã gửi").
- **Local-fallback (D-auth3):** `requiresEmailVerification`=false (không gate), Quên-mật-khẩu hiện banner warning + form disabled (throw `forgotPasswordLocalFallback`). Cần chạy nhánh `!isUsingFirebase`.
- **Cooldown 60s sống qua resume:** anchor wall-clock, không phải tick thuần — background app vài chục giây rồi mở lại, countdown phải đúng số còn lại (có thể đã về 0).
- **Auto-poll/resume verify:** bấm link trên mail (thiết bị/tab khác) rồi quay lại app → màn tự advance (poll 4s + resume hook). Test cả case poll bắt được lẫn bấm "Tôi đã xác thực" thủ công.
- **Gate seal:** khi `requiresEmailVerification`, resolver clear hết watcher + KHÔNG load couple. User mới chưa có couple nên không mất dữ liệu; vẫn cần xác nhận không rò watcher.

## Nhật ký implement
- [2026-05-30] [PO] Khởi tạo doc; liệt kê nợ kỹ thuật cần Dev xử lý.
- [2026-06-05] [Dev] Đợt 1: Quên mật khẩu (`/forgot-password`) + Xác thực email bắt buộc (`/verify-email` gate, grandfather pre-cutoff). Sửa `auth_service.dart`, `auth_provider.dart`, `app_routes.dart`, `session_resolver.dart`, `login_screen.dart`, `main.dart`; tạo `forgot_password_screen.dart`, `verify_email_screen.dart`; +21 key l10n (vi+en) + gen-l10n. `flutter analyze` sạch. Không đụng backend/native, không cần deploy.
- [2026-06-05] [Dev] fix F1/F2 (vòng nghiệm thu Tester, PASS-with-notes). F1: đăng ký Firebase → vào THẲNG `/verify-email` deterministic, không phụ thuộc `creationTime` (vá fail-open khi `metadata.creationTime==null`); local-fallback giữ `authGate`; resolver y nguyên (grandfather an toàn). F2: dùng dead key `verifyEmailSuccess` — SnackBar khi verify OK (manual + auto-poll). Sửa `register_screen.dart`, `verify_email_screen.dart`. KHÔNG đụng ARB/backend/native, không cần gen-l10n/deploy. `fvm flutter analyze` sạch.
- [2026-06-05] [Dev] Email xác thực custom HTML qua Resend (Cách B). MỚI `functions/emails/verification_email.js` (`buildVerificationEmail` — HTML email-safe vi/en, bulletproof button, escape name); MỚI callable `sendCustomVerificationEmail` trong `functions/index.js` (secret `RESEND_API_KEY`, `generateEmailVerificationLink` không actionCodeSettings, gửi qua Resend HTTP API). Client: `auth_service.dart` `signUp`/`resendEmailVerification` chuyển sang `_sendCustomVerificationEmail()` (callable) + `_activeLanguageCode`. Cơ chế verify GIỮ NGUYÊN (oobCode + auto-poll). `node -c` cả 2 file OK; `fvm flutter analyze` sạch. **CHƯA deploy** — chờ verify domain Resend + set secret `RESEND_API_KEY` (xem mục Deploy). KHÔNG đụng rules/storage/native.
