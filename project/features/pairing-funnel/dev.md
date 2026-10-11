# 💻 Dev — pairing-funnel

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** đang làm (2026-10-11)
- **Người/role:** Dev — 2 agent song song trên 2 worktree, mỗi agent CHỈ ghi vào phần của mình bên dưới.

## Ranh giới file giữa 2 phần (để merge không đụng nhau)
- **Phần A (Apple):** `auth_service.dart`, `auth_provider.dart`, `guest_counter_screen.dart`, `login_screen.dart`, `register_screen.dart`, `settings_screen.dart`, `widgets/apple_sign_in_button.dart` (mới), `theme/app_colors.dart`, `app/app_urls.dart` (chỉ hằng `privacyPolicy`), `ios/Runner/Runner.entitlements`, ARB (chèn sau `authFirebaseAuthGeneric` + sửa `guestCtaSignIn`).
- **Phần B (QR + bộ nhớ tạm + lời nhắc):** `invite_action_buttons.dart`, `widgets/invite_qr_sheet.dart` (mới), `services/invite_clipboard.dart` (mới), `home_screen.dart`, `setup_screen.dart`, `profile_screen.dart`, `reminder_provider.dart`, `reminder_service.dart`, `app/app_urls.dart` (chỉ thêm hằng link mời ở CUỐI class), `ios/Runner/AppDelegate.swift`, `docs/get.html`, `pubspec.yaml`/`pubspec.lock`, ARB (chèn sau `inviteFollowUpBody72h` + sửa `homeWaitingStep1Desc`, metadata `inviteFollowUpBody24h`).

---

## Phần A — Đăng nhập với Apple (PF1–PF6, PF11)

- *Trạng thái:* xong code (2026-10-11), chờ Tester. `flutter analyze` 0 issue · `flutter test` 225/225. Chưa build iOS (worktree), chưa chạy trên máy.

<!-- Dev A ghi kế hoạch, edge case, checklist, nhật ký vào giữa 2 dòng đánh dấu này -->
### File và hàm đã đụng

| File | Thay đổi |
|---|---|
| `lib/services/auth_service.dart` | Lớp mới `AppleEmailHasPasswordException` (PF6, mang `email`). `signInWithApple()` trả record `({AppUser user, bool isNewUser})`. PF3 trong `requiresEmailVerification`: không có provider `password` thì `false`. Getter `isAppleOnlyAccount` + `_isAppleOnly(User)`. `deleteAccount`: tài khoản Apple-only gọi `_confirmAppleDeletion` trước callable. Helper tĩnh `profileDisplayName` (PF4, `@visibleForTesting`), dùng trong `_buildFirebaseProfile`. `_mapAppleAuthError` |
| `lib/providers/auth_provider.dart` | Cờ riêng `isAppleSigningIn` (không bật `isLoading`), `appleEmailConflict`, `isAppleOnlyAccount`, `signInWithApple()` (sync push → mint session token → analytics `sign_up`/`login` method `apple`). `deleteAccount` trả nguyên sentinel `'apple-canceled'` |
| `lib/widgets/apple_sign_in_button.dart` (mới) | `AppleSignInButton({onSignInInstead, onExistingEmail})` + `static isAvailable(auth)` (`!kIsWeb && Platform.isIOS && isUsingFirebase`), dòng đồng ý `_ConsentLine`, divider `AuthOrDivider` |
| `lib/screens/guest_counter_screen.dart` | Khối Apple trong thẻ CTA, `_openSignIn` (cũng là action PF6), 2 nút cũ khoá khi Apple đang chạy, sửa comment đầu file |
| `lib/screens/login_screen.dart` | Apple DƯỚI form (18 · hoặc · 18 · nút). PF6: điền sẵn email + focus ô mật khẩu (`_passwordFocusNode`). Khoá nút Đăng nhập / Quên mật khẩu / Tạo tài khoản khi Apple chạy |
| `lib/screens/register_screen.dart` | Apple TRÊN form. `_openSignIn` (gộp code nút "Đăng nhập" cũ, cũng là action PF6, dùng `pushReplacementNamed`) |
| `lib/screens/settings_screen.dart` | Dialog xoá thêm `deleteAccountAppleNote` cho tài khoản Apple. `'apple-canceled'` thì im lặng. `_showReauthToDeleteDialog(context, apple:)`: bản Apple không có ô mật khẩu, bấm xác nhận gọi lại `deleteAccount()` một lần |
| `lib/theme/app_colors.dart` | `appleBlack = #000000` |
| `lib/app/app_urls.dart` | Chỉ đổi `privacyPolicy` → `https://dearembeiu.com/privacy-policy.html` |
| `ios/Runner/Runner.entitlements` | `com.apple.developer.applesignin = [Default]` (`plutil -lint` OK; cả 3 cấu hình build đều trỏ file này) |
| ARB en + vi | 7 key mới chèn ngay sau `authFirebaseAuthGeneric`; `guestCtaSignIn` → "Đăng nhập bằng email" / "Sign in with email". Đã `flutter gen-l10n` |
| `test/apple_display_name_test.dart` (mới) | 4 test cho PF4 |

Không đụng Firestore rules, Cloud Functions, `pubspec`. Không deploy gì.

### Luồng và edge case đã xử lý
- **Huỷ sheet Apple** (`canceled`, `web-context-canceled`) → sentinel `'apple-canceled'`. Đăng nhập: `errorMessage` null, không SnackBar, không haptic. Xoá tài khoản: không xoá, không báo gì.
- **PF6** `account-exists-with-different-credential` → SnackBar 5 giây. Landing và Đăng ký có action "Đăng nhập". Màn Đăng nhập không có action, điền sẵn email nếu Firebase trả về. Phải đặt `persist: false`: Flutter 3.41 giữ SnackBar có action trên màn hình tới khi bấm.
- **Mất mạng** → `authNetworkError`. **Mọi lỗi khác** (`invalid-response`, `failed`, `invalid-credential`, `user-mismatch`…) → `appleSignInFailed`. Câu tiếng Anh của Firebase chỉ vào `debugPrint`.
- **Email rỗng** sau khi đăng nhập Apple (không lẽ xảy ra) → `signOut` rồi báo `appleSignInFailed`, vì rules sẽ từ chối hồ sơ không có email.
- **Tên hiển thị (PF4):** tên Firebase → phần trước @ (bỏ qua `@privaterelay.appleid.com`, không phân biệt hoa thường) → `defaultDisplayName`. Không bao giờ ra chuỗi rỗng.
- **Xoá tài khoản Apple (PF5):** `reauthenticateWithProvider(AppleAuthProvider())` → `revokeTokenWithAuthorizationCode(code)` (lỗi thì `debugPrint` và vẫn xoá) → `getIdToken(true)` → callable. Thu hồi phải chạy TRƯỚC callable vì cần user còn đăng nhập.
- **`requires-recent-login` lần 2** (bản Apple) → `deleteAccountSessionExpiredMsg` + authGate, y nhánh mật khẩu. Lỗi khác ở lần 2 → đóng dialog + SnackBar (dialog Apple không có ô để hiện lỗi inline). Huỷ sheet ở lần 2 → đóng dialog, im lặng.
- **PF6 action bấm sau khi đã rời màn** → `_openSignIn` kiểm `mounted` trước khi điều hướng.

### Chỗ làm khác handoff (Tester/PO xem)
1. **Chữ ký widget khác Handoff 1.** Handoff gợi ý `AppleSignInButton({onPressed, busy})` để mỗi màn tự viết luồng. Tôi cho widget tự chạy luồng (đọc `AuthProvider`), màn chỉ truyền 2 callback PF6. Lý do: 3 màn sẽ phải chép y hệt một đoạn ~30 dòng (unfocus, haptic, điều hướng, 4 nhánh lỗi). Màn vẫn tự kiểm `AppleSignInButton.isAvailable` để bỏ luôn khoảng cách và divider trên Android.
2. **`isNewUser` = vừa tạo hồ sơ Firestore**, không dùng `additionalUserInfo.isNewUser`. Nếu lần đầu ghi hồ sơ lỗi rồi người dùng bấm lại, Firebase báo user cũ nhưng thực tế đây mới là lần tạo hồ sơ. Đo theo hồ sơ thì analytics `sign_up` đúng hơn.
3. **Ripple nút Apple** dùng overlay mặc định của `FilledButton` (trắng 10% khi nhấn) thay vì InkWell trắng .12 + highlight trong suốt. Chênh 2% không thấy bằng mắt, đổi lại nút có sẵn semantics button/enabled.
4. **`firebase_auth` thực tế là 6.5.3** (lock file), không phải 6.7.0 như brief. Đã kiểm 6.5.3 có đủ `signInWithProvider`, `reauthenticateWithProvider`, `revokeTokenWithAuthorizationCode`, `AdditionalUserInfo.authorizationCode` và mã lỗi native `canceled`. Không nâng vì lock file thuộc Phần B.

### Rủi ro / cần Tester soi trên máy thật
- **Chưa build iOS.** Cần archive/run có `-allowProvisioningUpdates` để Xcode bật capability Sign in with Apple cho App ID `.dev` (và `com.tony.dearembeiu` khi release). Simulator phải đăng nhập Apple ID.
- **Push sau khi huỷ xoá tài khoản:** `deleteAccount` của provider gỡ thiết bị khỏi push TRƯỚC khi sheet Apple hiện (thứ tự cũ, giữ nguyên). Huỷ sheet thì app `resumed` và `refreshPushRegistration` đăng ký lại. Cần thử: huỷ xoá rồi nhờ người ấy gửi tin, xem còn nhận push không.
- **Thu hồi token** sẽ lỗi tới khi nhập khoá .p8 vào Firebase (overview §5). Mong đợi: log `AuthService Apple token revoke failed`, tài khoản vẫn bị xoá.
- **Logo Apple** (`Icons.apple` 24): chưa so với nút hệ thống trên simulator. Design cho phép dịch lên 1pt nếu trông thấp.
- **Tên lần đầu:** đăng nhập Apple có chia sẻ tên → hồ sơ mang tên Apple. Chọn "Ẩn email" + không có tên → "Người dùng mới".
- Đường email/mật khẩu: đăng ký vẫn phải qua màn xác thực email (PF3 chỉ thêm nhánh `return false` cho user không có provider `password`).
- Probe widget test (17 ca, đã qua, không commit): pump thẳng nút ở bề rộng 253/295/400 × cỡ chữ 1.0–3.0, semantics, huỷ / PF6 / lỗi chung / thành công / bị khoá. File giữ ở scratchpad phiên Dev (`apple_button_probe_test.dart`) — PO muốn có trong repo thì thêm lại được ngay.

### Checklist acceptance (phần Apple)
- [x] iOS: landing, Đăng nhập, Đăng ký có nút; Android / local fallback không render (code + test host macOS không hiện nút)
- [x] Người mới → tạo `users/{uid}` có mã mời → authGate → Setup, không qua xác thực email (code; chờ chạy thật)
- [x] Người cũ → `updateUserProfile` → authGate → Home nếu có couple (code)
- [x] Huỷ sheet → ở lại, không báo lỗi (probe)
- [x] Email trùng tài khoản mật khẩu → câu PF6 (probe)
- [x] Xoá tài khoản Apple → dialog có câu báo trước → sheet → thu hồi → xoá; huỷ → không xoá (code; chờ chạy thật)
- [x] Đường email/mật khẩu không đổi hành vi
- [x] `flutter analyze` 0 · `flutter test` 225/225 · 7 key mới đủ vi + en

### Nhật ký
- [2026-10-11] [Dev A] Worktree tạo ra đang ở `main` (1c982ea); đã đưa về `00ce671` (`feature/pairing-funnel`) trước khi làm, tree sạch.
- [2026-10-11] [Dev A] Implement Phần A (PF1–PF6, PF11) theo bảng file ở trên. analyze 0, test 225/225 (221 cũ + 4 PF4). Probe widget test 17/17 rồi gỡ khỏi repo. Không deploy, không push.
<!-- /Phần A -->

---

## Phần B — Ghép đôi tại chỗ + lời nhắc mời (PF7–PF10, PF12–PF13)

- *Trạng thái:* chưa bắt đầu

<!-- Dev B ghi kế hoạch, edge case, checklist, nhật ký vào giữa 2 dòng đánh dấu này -->
<!-- /Phần B -->

---

## Nhật ký chung (Lead ghi khi merge)
- [2026-10-11] [Lead] Chia 2 phần A/B, chạy song song trên worktree riêng.
