# 💻 Dev — pairing-funnel

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** đang làm (2026-10-11)
- **Người/role:** Dev — 2 agent song song trên 2 worktree, mỗi agent CHỈ ghi vào phần của mình bên dưới.

## Ranh giới file giữa 2 phần (để merge không đụng nhau)
- **Phần A (Apple):** `auth_service.dart`, `auth_provider.dart`, `guest_counter_screen.dart`, `login_screen.dart`, `register_screen.dart`, `settings_screen.dart`, `widgets/apple_sign_in_button.dart` (mới), `theme/app_colors.dart`, `app/app_urls.dart` (chỉ hằng `privacyPolicy`), `ios/Runner/Runner.entitlements`, ARB (chèn sau `authFirebaseAuthGeneric` + sửa `guestCtaSignIn`).
- **Phần B (QR + bộ nhớ tạm + lời nhắc):** `invite_action_buttons.dart`, `widgets/invite_qr_sheet.dart` (mới), `services/invite_clipboard.dart` (mới), `home_screen.dart`, `setup_screen.dart`, `profile_screen.dart`, `reminder_provider.dart`, `reminder_service.dart`, `app/app_urls.dart` (chỉ thêm hằng link mời ở CUỐI class), `ios/Runner/AppDelegate.swift`, `docs/get.html`, `pubspec.yaml`/`pubspec.lock`, ARB (chèn sau `inviteFollowUpBody72h` + sửa `homeWaitingStep1Desc`, metadata `inviteFollowUpBody24h`).

---

## Phần A — Đăng nhập với Apple (PF1–PF6, PF11)

- *Trạng thái:* xong code (2026-10-11), PO gate PASS sau khi sửa thứ tự xoá tài khoản, chờ Tester. `flutter analyze` 0 issue · `flutter test` 227/227. Chưa build iOS (worktree), chưa chạy trên máy.

<!-- Dev A ghi kế hoạch, edge case, checklist, nhật ký vào giữa 2 dòng đánh dấu này -->
### File và hàm đã đụng

| File | Thay đổi |
|---|---|
| `lib/services/auth_service.dart` | Lớp mới `AppleEmailHasPasswordException` (PF6, mang `email`). `signInWithApple()` trả record `({AppUser user, bool isNewUser})`. PF3 trong `requiresEmailVerification`: không có provider `password` thì `false`. Getter `isAppleOnlyAccount` + `_isAppleOnly(User)`. `confirmAppleDeletionIfNeeded()` (public, tự lấy `currentUser`, không phải Apple-only thì return; `deleteAccount` của service không gọi nữa). Helper tĩnh `profileDisplayName` (PF4, `@visibleForTesting`), dùng trong `_buildFirebaseProfile`. `_mapAppleAuthError` |
| `lib/providers/auth_provider.dart` | Cờ riêng `isAppleSigningIn` (không bật `isLoading`), `appleEmailConflict`, `isAppleOnlyAccount`, `signInWithApple()` (sync push → mint session token → analytics `sign_up`/`login` method `apple`). `deleteAccount` gọi `confirmAppleDeletionIfNeeded()` NGAY ĐẦU, trước gỡ push và mọi teardown; trả nguyên sentinel `'apple-canceled'` |
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
| `test/auth_flow_hardening_test.dart` | Fake override `confirmAppleDeletionIfNeeded` / `mintSessionToken` / `watchSessionToken`. +1 test hồi quy PF5 (huỷ sheet → không xoá, single-session vẫn bắt được máy khác), +1 test bản local không chạm FirebaseAuth |

Không đụng Firestore rules, Cloud Functions, `pubspec`. Không deploy gì.

### Luồng và edge case đã xử lý
- **Huỷ sheet Apple** (`canceled`, `web-context-canceled`) → sentinel `'apple-canceled'`. Đăng nhập: `errorMessage` null, không SnackBar, không haptic. Xoá tài khoản: không xoá, không báo gì.
- **PF6** `account-exists-with-different-credential` → SnackBar 5 giây. Landing và Đăng ký có action "Đăng nhập". Màn Đăng nhập không có action, điền sẵn email nếu Firebase trả về. Phải đặt `persist: false`: Flutter 3.41 giữ SnackBar có action trên màn hình tới khi bấm.
- **Mất mạng** → `authNetworkError`. **Mọi lỗi khác** (`invalid-response`, `failed`, `invalid-credential`, `user-mismatch`…) → `appleSignInFailed`. Câu tiếng Anh của Firebase chỉ vào `debugPrint`.
- **Email rỗng** sau khi đăng nhập Apple (không lẽ xảy ra) → `signOut` rồi báo `appleSignInFailed`, vì rules sẽ từ chối hồ sơ không có email.
- **Tên hiển thị (PF4):** tên Firebase → phần trước @ (bỏ qua `@privaterelay.appleid.com`, không phân biệt hoa thường) → `defaultDisplayName`. Không bao giờ ra chuỗi rỗng.
- **Xoá tài khoản Apple (PF5):** `reauthenticateWithProvider(AppleAuthProvider())` → `revokeTokenWithAuthorizationCode(code)` (lỗi thì `debugPrint` và vẫn xoá) → `getIdToken(true)` → callable. Cả bước này chạy TRƯỚC khi provider gỡ push, tắt theo dõi single-session hay đặt cờ `_intentionalAuthClear`, nên huỷ sheet là mọi thứ y nguyên. Thu hồi phải chạy trước callable vì cần user còn đăng nhập.
- **`requires-recent-login` lần 2** (bản Apple) → `deleteAccountSessionExpiredMsg` + authGate, y nhánh mật khẩu. Lỗi khác ở lần 2 → đóng dialog + SnackBar (dialog Apple không có ô để hiện lỗi inline). Huỷ sheet ở lần 2 → đóng dialog, im lặng.
- **PF6 action bấm sau khi đã rời màn** → `_openSignIn` kiểm `mounted` trước khi điều hướng.

### Chỗ làm khác handoff (Tester/PO xem)
1. **Chữ ký widget khác Handoff 1.** Handoff gợi ý `AppleSignInButton({onPressed, busy})` để mỗi màn tự viết luồng. Tôi cho widget tự chạy luồng (đọc `AuthProvider`), màn chỉ truyền 2 callback PF6. Lý do: 3 màn sẽ phải chép y hệt một đoạn ~30 dòng (unfocus, haptic, điều hướng, 4 nhánh lỗi). Màn vẫn tự kiểm `AppleSignInButton.isAvailable` để bỏ luôn khoảng cách và divider trên Android.
2. **`isNewUser` = vừa tạo hồ sơ Firestore**, không dùng `additionalUserInfo.isNewUser`. Nếu lần đầu ghi hồ sơ lỗi rồi người dùng bấm lại, Firebase báo user cũ nhưng thực tế đây mới là lần tạo hồ sơ. Đo theo hồ sơ thì analytics `sign_up` đúng hơn.
3. **Ripple nút Apple** dùng overlay mặc định của `FilledButton` (trắng 10% khi nhấn) thay vì InkWell trắng .12 + highlight trong suốt. Chênh 2% không thấy bằng mắt, đổi lại nút có sẵn semantics button/enabled.
4. **`firebase_auth` thực tế là 6.5.3** (lock file), không phải 6.7.0 như brief. Đã kiểm 6.5.3 có đủ `signInWithProvider`, `reauthenticateWithProvider`, `revokeTokenWithAuthorizationCode`, `AdditionalUserInfo.authorizationCode` và mã lỗi native `canceled`. Không nâng vì lock file thuộc Phần B.

### Rủi ro / cần Tester soi trên máy thật
- **Chưa build iOS.** Cần archive/run có `-allowProvisioningUpdates` để Xcode bật capability Sign in with Apple cho App ID `.dev` (và `com.tony.dearembeiu` khi release). Simulator phải đăng nhập Apple ID.
- **Push sau khi huỷ xoá tài khoản:** đã sửa sau PO gate, huỷ sheet không còn gỡ push hay tắt single-session. Vẫn nên thử trên máy: huỷ xoá rồi nhờ người ấy gửi tin, phải nhận push ngay. Còn một hở có từ trước, áp cho mọi tài khoản: callable xoá lỗi (mạng) thì thiết bị đã bị gỡ push (tự đăng ký lại khi app `resumed`) và mất theo dõi single-session tới lần mở app sau.
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
- [x] `flutter analyze` 0 · `flutter test` 227/227 · 7 key mới đủ vi + en

### Nhật ký
- [2026-10-11] [Dev A] Worktree tạo ra đang ở `main` (1c982ea); đã đưa về `00ce671` (`feature/pairing-funnel`) trước khi làm, tree sạch.
- [2026-10-11] [Dev A] Implement Phần A (PF1–PF6, PF11) theo bảng file ở trên. analyze 0, test 225/225 (221 cũ + 4 PF4). Probe widget test 17/17 rồi gỡ khỏi repo. Không deploy, không push.
- [2026-10-11] [Dev A] Sửa lỗi PO gate: xoá tài khoản Apple từng gỡ push + tắt single-session TRƯỚC khi sheet Apple hiện, huỷ sheet là thiết bị mất cả hai tới lần mở app sau. Nay `AuthProvider.deleteAccount` gọi `confirmAppleDeletionIfNeeded()` ngay đầu, trước mọi teardown. Thêm test hồi quy (đã thử đặt lại thứ tự sai thì test hỏng đúng chỗ). analyze 0, test 227/227.
<!-- /Phần A -->

---

## Phần B — Ghép đôi tại chỗ + lời nhắc mời (PF7–PF10, PF12–PF13)

- *Trạng thái:* đã implement xong, sẵn sàng test (2026-10-11) — chưa merge, chưa đẩy `docs/get.html` lên `phase3`

<!-- Dev B ghi kế hoạch, edge case, checklist, nhật ký vào giữa 2 dòng đánh dấu này -->

### Đã làm (file → việc)

| File | Việc |
|---|---|
| `pubspec.yaml` / `.lock` | `qr_flutter: ^4.1.0` (bản 4.x mới nhất, kéo theo `qr 3.0.2`). |
| `lib/app/app_urls.dart` | Cuối class: `inviteBase = 'https://dearembeiu.com/get'` + `inviteLink(code)` (in hoa mã). Không đụng `privacyPolicy`. |
| `lib/widgets/invite_qr_sheet.dart` (mới) | `InviteQrSheet.show(context, code:)`: log `invite_shared('qr')` + `markInviteShared()` rồi mở sheet. QR 220 trong `ContentCard` rộng 260, ECC M, gapless, module + mắt `textPrimary`, nền trắng, `padding: zero` (vùng trắng = padding 20 của thẻ). Semantics `image` + `inviteQrSemantics(code)`. Kèm `InviteSheetFrame` = khung sheet chuẩn (trắng, r28, handle 40×4, cuộn trong 90% màn) dùng chung cho sheet gợi ý ở Setup. |
| `lib/widgets/invite_action_buttons.dart` | Row → `Wrap(8, 8)`. Pill dựng lại bằng `TextButton.icon` (iconOnly: `IconButton(tooltip:)`), `minimumSize` cao 36, `tapTargetSize: padded` → vùng chạm 48. Biến thể sáng: chữ `textPrimary` w700, icon rose, nền rose .12, ripple rose .08. Thêm pill "Mã QR" (`IconsaxPlusLinear.scan_barcode`). Copy/Share gọi thêm `markInviteShared()`. |
| `lib/screens/home_screen.dart` | Thẻ chờ: `Align(Sao chép mã)` → `Wrap` 2 pill tonal [Sao chép mã][Mã QR] qua `_buildWaitingPill` (stadium, cao 36/chạm 48, chữ navy 13 w700). Khoảng cách nút "Gửi cho người ấy" → hàng pill 8 → 2. `_shareInviteCode`/`_copyInviteCode` gọi `markInviteShared()`. Comment call site `refreshInviteFollowUps` theo lịch mới. |
| `lib/screens/setup_screen.dart` | `WidgetsBindingObserver`. `_checkClipboardInvite()` chạy sau frame đầu + 500ms; iOS chạy lại mỗi lần `resumed` (PF12), Android chỉ lúc mở màn. Điều kiện: đã đăng nhập, `!user.hasCouple` (tức không phải chế độ sửa), không đang loading, Setup là route trên cùng, mã khác `inviteCode`/`coupleCode` của mình. Đánh dấu "đã hỏi" TRƯỚC khi hiện sheet. Sheet `_ClipboardInviteSheet` (W9, nút chính navy). "Ghép đôi ngay" → điền mã + tab Tham gia + chờ 300ms + `_submitJoin()`; "Bỏ qua"/vuốt → vẫn điền mã, không đổi tab. `_submitJoin` tách mã khi người dùng dán cả link (và hiện lại mã trong ô). Khoảng cách quanh cụm nút: mã → cụm 10 → 4, cụm → mô tả 8 → 2. |
| `lib/screens/profile_screen.dart` | `_buildDetailTile`: value → cụm nút 10 → 4 (belowValue chỉ dùng cho cụm mời). |
| `lib/services/invite_clipboard.dart` (mới) | `parseInviteCode(text)` thuần (regex dựng từ `AppUrls.inviteBase`: host không phân biệt hoa thường, có/không `https://`/`www.`, không dính domain khác, `code` ở vị trí bất kỳ trong query, đúng 6 ký tự chữ-số) → mã IN HOA. `peekInviteCode()`: iOS kênh `dear_embeiu/clipboard` `probe` → không có URL thì thôi; `changeCount` trùng lần đọc trước (Hive) thì thôi; lưu `changeCount` rồi mới `Clipboard.getData`. Android: `hasStrings` → đọc. Mã đã hỏi → null. Mọi lỗi → null. Không log nội dung. `markAsked(code)`. |
| `lib/services/reminder_service.dart` | `enum InviteFollowUp { after2h(1180, 2h), after20h(1181, 20h), after72h(1182, 72h) }`. `@visibleForTesting static inviteFollowUpSlots({anchor, now, shared})` thuần. `scheduleInviteFollowUps({anchor, shared, copy})` (huỷ cả band rồi lập theo slot). `cancelInviteFollowUp(kind)`. BỎ cơ chế "đã qua hết thì nhắc now + 24h". |
| `lib/providers/reminder_provider.dart` | `markInviteShared()`: ghi `invite_shared_at` (epoch ms) vào Hive `app_settings` + huỷ id 1180. `_inviteSharedFor(anchor)` = `lastShared >= anchor − 1h`. `refreshInviteFollowUps` truyền copy theo mốc (2h: `inviteFollowUpTitle2h`/`Body2h`; 20h: `inviteFollowUpTitle`/`Body24h`; 72h: `inviteFollowUpTitle`/`Body72h`); chữ ký debounce thêm `shared`. |
| `ios/Runner/AppDelegate.swift` | `InviteClipboardChannel` đăng ký trong khối `registrar(forPlugin: "AppChannels")`. `UIPasteboard.general.detectPatterns(for: [\.probableWebURL])` (bản key-path iOS 15, bản `DetectionPattern` đã deprecated từ iOS 15), trả `{hasUrl, changeCount}` về main queue. |
| `docs/get.html` | CSS giữ nguyên. `COPY` vi/en theo bảng design (`msgWithCode`, `subNote` đổi; thêm `copyHint`/`copyHintDone`/`copyHintFail`/`subNoteAuto`). Nhận diện nền tảng đưa ra ngoài `routeByPlatform`. Có mã hợp lệ: bấm `#iosBtn`/`#androidBtn`/`#openApp` → chép `https://dearembeiu.com/get?code=<MÃ>` ngay trong click (`writeText` không await, lỗi thì `legacyCopy`), không `preventDefault`. Điện thoại có mã: ẩn nút store sai nền tảng, `#redirectNote` hiện `copyHint` → `copyHintDone`/`copyHintFail`, `#subNote` = `subNoteAuto`. Không mã: luồng tự chuyển store 1,2 giây như cũ. |
| `lib/l10n/app_en.arb` + `app_vi.arb` | 12 key mới ngay sau `inviteFollowUpBody72h` (`@inviteQrSemantics` có placeholder `code` String ở cả 2 file); đổi `homeWaitingStep1Desc`; en thêm `@inviteFollowUpBody24h` (mốc 20 giờ) + description cho `inviteQrBtn`/`clipboardInviteTitle`/`inviteFollowUpTitle2h`. `flutter gen-l10n` đã chạy. |
| `test/invite_clipboard_test.dart`, `test/invite_follow_up_slots_test.dart` (mới) | 7 + 7 test. |

Model/Firestore/Function/rules: **không đổi**. Không deploy gì. Native: chỉ iOS (kênh mới); Android không đổi.

### Edge case đã xử lý
- **Lịch nhắc:** mốc đêm dời TRƯỚC rồi mới lọc theo `now` ⇒ mở app lúc 23:30 khi mốc 2h (23:00) vừa qua thì nó vẫn nổ 08:30 sáng mai, không bị bỏ. Couple tạo ≥ 3 ngày (cụ thể: mọi mốc đã qua) ⇒ không lập gì, kể cả khi mở app. Bản cũ để lại id 1180 "now + 24h" ⇒ lần refresh đầu sau khi cập nhật huỷ cả band 1180–1189 rồi lập lại.
- **"Đã gửi":** sao chép mã cá nhân ở Setup trong vòng 1 giờ trước khi tạo couple vẫn tính. Lần chia sẻ cho couple cũ (trước khi rời và tạo lại) không tính.
- **Bộ nhớ tạm iOS:** không URL ⇒ không đọc ⇒ không có hộp "Cho phép dán". Một nội dung chỉ đọc một lần (`changeCount`), kể cả khi nó không phải link mời hay người dùng bấm "Không cho phép". Hộp hệ thống làm app `inactive → resumed` ⇒ cờ `_clipboardCheckBusy` chặn kiểm chồng.
- Sheet gợi ý không hiện khi đang có dialog/route khác đè lên Setup, khi đang ghép đôi, hoặc với mã của chính mình.
- Pill Wrap xuống dòng thay vì tràn ở tile Profile (cột 253pt). Sheet QR cuộn được khi chữ to.

### Checklist
- [x] `flutter analyze` → **No issues found!**
- [x] `flutter test` → **235/235 pass** (221 cũ + 14 mới)
- [x] `xcrun swiftc -parse ios/Runner/AppDelegate.swift` → OK. Thêm: type-check riêng `InviteClipboardChannel` với `Flutter.xcframework` + SDK iOS 15 → sạch, không warning.
- [x] `docs/get.html`: `node --check` OK + chạy script trong DOM giả 6 kịch bản (iPhone/Android/desktop/iPad có mã, iPhone không mã, mã 7 ký tự) → đúng spec.
- [x] Smoke test bố cục tạm (đã xoá, không commit): 3 pill trong cột 253pt mỗi nút cao 48, hình 36, không tràn; sheet QR ở cỡ chữ ×2 trên máy 375×667 không tràn, cuộn tới "Xong" được.
- [ ] Chạy thật trên máy: quét QR bằng Camera iPhone, hộp "Cho phép dán", luồng đã-cài-sẵn (PF12), toast Android.

### Khác spec / cần biết
- **Khoảng icon → chữ trong pill = 8** (khoảng cố định của `TextButton.icon`), design ghi 6 (thẻ chờ) và cụm cũ là 4. Rộng thêm 2–4pt mỗi pill; cụm 3 pill vẫn vừa 1 hàng ở Setup máy 375.
- **Ripple:** dùng `copyWith(overlayColor:)` để ra đúng rose .08 / trắng .12 (styleFrom chỉ cho .10).
- **Hợp đồng analytics:** `invite_shared` nay có thêm `method = qr` (theo design 4a). `project/features/analytics/overview.md` (file PO) vẫn ghi `copy | share_sheet` — PO cần bổ sung.
- **Hive:** `markInviteShared` / bộ nhớ tạm chỉ đọc-ghi khi box `app_settings` đã mở (main() luôn mở trước `runApp`); không gọi `openBox` dự phòng vì Hive ném lỗi bất đồng bộ ngoài try/catch khi mở thất bại.
- Mốc `anchor + 7 ngày` hiện không bao giờ chặn mốc nào (mốc xa nhất là +72h dời đêm); giữ làm chốt chặn theo PF10 cho ai thêm mốc sau này.
- **Chưa làm (việc của Lead):** đẩy `docs/get.html` lên nhánh `phase3`. Trước khi đẩy, app bản cũ (không đọc bộ nhớ tạm) vẫn chạy bình thường: trang chỉ chép thêm link.
- **Merge với Phần A:** 2 bên cùng sinh lại `lib/l10n/app_localizations*.dart` ⇒ sau khi gộp ARB, chạy lại `flutter gen-l10n` thay vì gộp tay file sinh.

### Nhật ký
- [2026-10-11] [Dev B] Worktree bị tạo từ `main`@1c982ea thay vì `00ce671` → reset nhánh worktree về `00ce671` (cây sạch, chưa có commit riêng) rồi mới làm.
- [2026-10-11] [Dev B] Implement Phần B: QR (PF7) + pill dựng lại vùng chạm 48, gợi ý mã từ bộ nhớ tạm ở Setup (PF9/PF12/PF13) + kênh iOS `dear_embeiu/clipboard`, trang get chép link mời (PF8/PF12), lịch nhắc mời +2h/+20h/+72h dời đêm 08:30, bỏ nhắc lặp (PF10). analyze 0, test 235/235.
<!-- /Phần B -->

---

## Dev-fix vòng 1 (theo test.md)

- *Trạng thái:* vá xong BUG-1/2/4/5/6 (2026-10-11), chờ Tester vòng 2. BUG-3 là điều kiện phát hành (thứ tự đẩy `get.html`), không có code để sửa.
- `flutter analyze` → **No issues found!** · `flutter test` → **247/247** (241 cũ + 6 mới). Không đổi ARB, rules, Functions, native. Không deploy.

| Bug | Sửa gì | File:dòng | Test bảo vệ |
|---|---|---|---|
| BUG-1 (P2) | `confirmAppleDeletionIfNeeded()` bỏ `reauthenticateWithProvider`, gọi `_auth.signInWithProvider(AppleAuthProvider())`. Plugin iOS 6.5.3 bật `isReauthenticatingWithApple`, sheet bị huỷ không tắt lại, nên lần đăng nhập Apple sau rơi vào nhánh reauth với currentUser nil và treo. Nhánh sign-in không có cờ đó; cùng Apple ID trả về cùng uid kèm credential + `authorizationCode` mới. Ghi uid trước khi gọi; sheet trả user khác uid (máy đã đổi Apple ID) hoặc null → `signOut()` rồi ném `'session-gone'`, không thu hồi token, không xoá gì. Thu hồi token (lỗi bỏ qua) + `getIdToken(true)` giữ nguyên, nay gọi trên user mới. Provider coi `'session-gone'` là sentinel (không gán vào `errorMessage`). Dialog xoá đầu tiên ở Settings thêm nhánh `'session-gone'` → SnackBar `deleteAccountSessionExpiredMsg` + authGate, y như dialog re-auth. | `lib/services/auth_service.dart:648-696` (gọi sign-in :672, chặn uid :674-679) · `lib/providers/auth_provider.dart:427-433` · `lib/screens/settings_screen.dart:1062-1074` | `test/apple_delete_confirm_test.dart` (mới): cùng Apple ID → thu hồi bằng code mới + làm mới token; Apple ID khác → `signOut` + `session-gone` + không thu hồi. Fake user ném lỗi nếu có ai gọi lại `reauthenticateWithProvider`. `test/auth_flow_hardening_test.dart:152`: provider trả `session-gone`, không gọi xoá, `errorMessage` null |
| BUG-6 (P3) | `_mapAppleAuthError` thêm tham số `fallback`, luồng xoá truyền `deleteAccountFailed`. Huỷ (`canceled`/`web-context-canceled`) vẫn `'apple-canceled'`, mất mạng → `authNetworkError`, còn lại → `deleteAccountFailed`. Chữ tiếng Anh của Firebase chỉ vào `debugPrint`. Đăng nhập Apple vẫn ra `appleSignInFailed` như cũ. | `lib/services/auth_service.dart:692-694` (call site), `:834-856` (mapper) | `test/apple_delete_confirm_test.dart` "errors: …" (5 mã lỗi) |
| BUG-2 (P2) | `cancelDailyQuestionSchedule()` huỷ luôn band 1180–1189 (`cancelInviteFollowUps()`), đặt `_inviteFollowUpSignature = null` + `_inviteFollowUpCleared = true`. Cả 3 nhánh "không còn couple" của `session_resolver` (chưa đăng nhập · chờ xác thực email · đăng nhập mà không có couple) đều đi qua hàm này. Signature null nên lần sau Home có couple đang chờ sẽ lập lịch lại. Sửa comment chủ sở hữu band ở `reminder_service.dart` cho khớp. | `lib/providers/reminder_provider.dart:1519-1525` · `lib/services/reminder_service.dart:157-159` | Chưa có test tự động: provider dùng thẳng `ReminderService.instance` (plugin thông báo), không tiêm fake được. Tester soi R12 trên máy: tạo couple → Đăng xuất / Rời / Xoá → pending không còn 1180–1182 |
| BUG-4 (P3) | `_openSignIn` chỉ điều hướng khi `mounted` VÀ `ModalRoute.of(context)?.isCurrent == true`. Landing là route có tên (`AppRoutes.guest`) nên luôn có `ModalRoute`; nút "Đăng nhập bằng email" bấm ngay trên landing vẫn chạy. | `lib/screens/guest_counter_screen.dart:85-93` | Chưa có test tự động (phải dựng landing + Login + SnackBar). Repro ở test.md BUG-4 |
| BUG-5 (P3) | Lookbehind của regex đổi từ `[a-z0-9.-]` sang `[a-z0-9._~:/?#@!$&*+,;=%-]` (không phân biệt hoa thường): scheme/host không được đứng sau ký tự URL, nên link mời lồng trong path/query của URL khác không ra mã. Đầu chuỗi, khoảng trắng, `( [ " '` và `“ ”` vẫn khớp. | `lib/services/invite_clipboard.dart:26-35` (lookbehind :31) | `test/invite_clipboard_test.dart:46` (2 URL lồng → null) + `:54` (ngoặc, nháy, câu mời có `abc234` → `ABC234`); 7 test cũ vẫn qua |

Đã thử phá: trả lại `reauthenticateWithProvider`, bỏ chặn uid, bỏ `fallback`, trả regex cũ → 4 test mới đỏ đúng chỗ. Khôi phục → xanh.

### Cần Tester / PO biết
- **Nơi gọi `cancelDailyQuestionSchedule()` khi couple có thể vẫn đang chờ:** nhánh cuối `session_resolver.dart:291` (đã đăng nhập, `hasCoupleData == false`). Ngoài trường hợp thật sự không có couple, nhánh này còn chạy khi user vẫn có `coupleId` nhưng `loadCoupleForUser` lỗi mà không phải timeout (vd mở app lúc offline, Firestore báo `unavailable`, không có cache). Trước giờ user đã rơi vào Setup ở ca này; nay nhắc mời cũng bị huỷ cùng nhắc câu hỏi. Lần sau Home tải được couple đang chờ thì lịch lập lại theo mốc tạo couple. Không đổi hành vi nơi này. Nhánh chờ xác thực email (`:185`) trên thực tế không có couple, vì tài khoản chưa xác thực bị chặn trước Setup.
- **Đổi Apple ID giữa chừng:** `signInWithCredential` có thể tạo một user Auth mới cho Apple ID kia (chưa có hồ sơ Firestore) trước khi app đăng xuất. Không xoá user đó, đúng yêu cầu. Người đó đăng nhập Apple sau này thì luồng thường tự tạo hồ sơ.
- **Điều hướng 2 lần ở nhánh `session-gone`:** `signOut()` làm listener phiên của `AuthProvider` bật cờ "bị thu hồi" → shell đẩy authGate, dialog Settings cũng đẩy authGate. Cả hai dùng `pushNamedAndRemoveUntil(..., false)` nên cuối cùng còn đúng 1 authGate. Giống nhánh `session-gone` có sẵn của dialog re-auth.
- Cờ kẹt vẫn nằm trong plugin. `lib/` không còn chỗ nào gọi `reauthenticateWithProvider` (grep). Sau này cần reauth Apple ở chỗ khác thì dùng cùng cách.
- Cần máy thật: R8 (tái hiện BUG-1, giờ phải đăng nhập được), R9 (xoá Apple: sheet → thu hồi → xoá; huỷ → không xoá), R12 (thêm bước đăng xuất / rời / xoá).

### Nhật ký
- [2026-10-11] [Dev] Vá BUG-1/2/4/5/6 theo Tester vòng 1. analyze 0, test 247/247. Không deploy, không push.

---

## Nhật ký chung (Lead ghi khi merge)
- [2026-10-11] [Lead] Chia 2 phần A/B, chạy song song trên worktree riêng.
