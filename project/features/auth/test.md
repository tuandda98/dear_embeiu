# 🧪 Test — Auth

> Tester sở hữu. Đọc cả 3 file kia. CHỈ test, KHÔNG sửa code. Output PASS/FAIL.

- **Trạng thái test:** ⬜ v1.0 chưa test hệ thống · 🧪 **Đợt 1 (quên-mật-khẩu + verify-email): PASS code-level** — chờ 6 smoke-test runtime (xem cuối file)

## Test case ưu tiên
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Đăng ký → đăng nhập → đăng xuất (Firebase) | Hoạt động, session persist | ⬜ |
| 2 | happy | Tương tự ở **local fallback** (Firebase off) | Hoạt động, KHÁC nhánh | ⬜ |
| 3 | negative | Email `a@b@c.com`, `@x.com`, `test@` | Nên reject (hiện chỉ check `@`) | ⬜ |
| 4 | negative | Password `123456`, displayName 10K ký tự + emoji | Nên reject/giới hạn | ⬜ |
| 5 | security | Đọc/sửa doc user khác | Rules chặn | ⬜ |
| 6 | security | Local fallback: password lưu plaintext? | Xác nhận lỗ hổng | ⬜ |
| 7 | edge | Reinstall → purge session | Không còn session cũ | ⬜ |
| 8 | edge | deleteAccount khi đang trong couple | Demote partner đúng, không xoá nhầm | ⬜ |
| 9 | edge | deleteAccount chưa auth / account khác | Chặn (dựa request.auth.uid) | ⬜ |
| 10 | edge | Resume app → refresh FCM token | Token cập nhật | ⬜ |

## 🧪 Test — Đợt 1 (Quên mật khẩu + Xác thực email) — 2026-06-05

**Tester verdict: PASS-with-notes** (code-level). `fvm flutter analyze` → No issues found! · gen-l10n idempotent (generated khớp ARB) · ARB parity 0 key lệch · 0 hardcode chuỗi vi/en.

### Acceptance 4b
| # | Acceptance | Verdict | Bằng chứng |
|---|---|---|---|
| 1 | Login link "Quên mật khẩu?" → /forgot-password prefill email | ✅ PASS | login_screen.dart:319-344; forgot_password_screen.dart:48-54 |
| 2 | Đăng ký mới → sendEmailVerification + gate /verify-email | ✅ PASS · smoke-test | auth_service.dart:183-187; **register_screen.dart:84-88 (deterministic, fix F1)** |
| 3 | Màn verify đủ chức năng (poll/resume/cooldown/PopScope/signOut) | ✅ PASS | verify_email_screen.dart:55,67-73,77-102,177-189,196 |
| 4 | Grandfather D-auth2 false cho pre-cutoff/Google-Apple/local/null | ✅ PASS · smoke-test | auth_service.dart:324-337 |
| 5 | Local-fallback D-auth3: gate false + reset l10n + UI disable | ✅ PASS | auth_service.dart:325,345-347; forgot_password_screen.dart:219,272 |
| 6 | Anti-enumeration D-auth4: user-not-found → sent | ✅ PASS · smoke-test | auth_service.dart:351-357 |
| 7 | l10n 21 key vi+en, placeholder đúng, không lệch, không hardcode | ✅ PASS | {email}/{time} khai báo 2 ARB, generated khớp |

### Findings
- 🟡→✅ **F1 (đã siết)** `creationTime == null` fail-OPEN ở resolver. **Fix:** register Firebase điều hướng THẲNG `/verify-email` (register_screen.dart:84-88), không phụ thuộc creationTime/SDK timing. Resolver giữ fail-open chủ ý (bảo vệ grandfather pre-cutoff). Vẫn cần smoke-test #1 xác nhận.
- 🟢 F2 (đã xử) `verifyEmailSuccess` được wire làm SnackBar success trước điều hướng (verify_email_screen). Hết dead key.
- 🟢 F3 (chấp nhận) Label cooldown trễ ≤1s sau resume (anchor wall-clock nên không âm/treo).
- 🟢 F4 (không-bug) D-auth4 phụ thuộc server (Firebase thường tự success email không tồn tại); code phòng thủ đúng.

### Catalog rủi ro — đã kiểm, KHÔNG thành lỗi
- Né gate bằng login lại: chặn (resolver chạy mọi cold-start/login, session_resolver.dart:115).
- Timer leak: không (dispose huỷ poll+cooldown+observer; huỷ khi verified).
- reloadAndCheckEmailVerified khi currentUser==null: return false, không crash; provider catch.
- Điều hướng sau verify: pushNamedAndRemoveUntil(authGate) → resolver re-check (cùng FirebaseAuth.instance) → gate=false → setup/home.
- signOut sạch: escape hatch → authGate → unauthenticated → /guest + clear watcher.

### ⚠️ BẮT BUỘC smoke-test runtime (2 nhánh Firebase/local) TRƯỚC khi ship
1. Signup mới thật (Firebase) → phải vào `/verify-email`, email xác thực thực sự gửi.
2. Grandfather: login account pre-cutoff (tạo trước 2026-06-05 UTC) chưa verify → KHÔNG bị gate.
3. Verify happy-path: bấm link mail (máy khác) → quay lại app → auto-advance; + nút "Tôi đã xác thực".
4. D-auth4: reset email KHÔNG tồn tại → ra state sent, không lộ "không tồn tại".
5. Cooldown qua resume: background ~90s → countdown đúng/không âm.
6. Local-fallback (!isUsingFirebase): banner warning + form disabled; verify skip; không crash.

## Nhật ký test
- [2026-05-30] [PO] Tạo bộ case từ catalog logic/security; chờ Tester chạy.
- [2026-06-05] [Tester] Nghiệm thu code-level Đợt 1: 7/7 acceptance PASS. analyze sạch, gen-l10n idempotent, ARB parity OK. F1 (creationTime null fail-open) → Dev siết bằng register-direct-nav; F2 wire toast. Verdict PASS-with-notes — chờ 6 smoke-test runtime trước ship.
