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

## Dev-fix vòng 1–2 (theo test.md)

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
- [2026-10-11] [Dev] BUG-7 (P3, hồi quy do bản vá BUG-5): link mời dính liền ký tự đứng trước (`tại:https://…`, `em ơi,https://…`, `nhé.https://…`, `*https://…*`) không ra mã. Phần trước host tách 2 nhánh: có scheme chỉ chặn khi ký tự đứng trước là `[a-z0-9/=?&#%]` (vẫn loại `?u=https://…`, `…/https://…`); không scheme giữ class chặt `[a-z0-9._~:/?#@!$&*+,;=%-]`, nên `tại:dearembeiu.com/get?code=…` (không scheme, dính dấu câu) vẫn bị bỏ như vòng 1. `lib/services/invite_clipboard.dart:26-38` (regex :33-34) · test `test/invite_clipboard_test.dart:54` (4 ca trên → `ABC234`, thêm `https://evil.com/https://dearembeiu.com/get?code=ABC234` → null). Thử phá: trả nhánh có scheme về class chặt, hoặc bỏ `/` khỏi class → test này đỏ. analyze 0, test 248/248. Không deploy, không push.

---

## Đợt 2 — Phần D: Đăng nhập Google + PF18 (đổi Apple ID lúc xoá)

- *Trạng thái:* xong code (2026-10-11), chờ Tester. `flutter analyze` 0 · `flutter test` 259/259 · `flutter build ios --debug --no-codesign` OK (Xcode 281,7s → `Runner.app`) · thêm `flutter build apk --debug` OK (`default_web_client_id` DEV có trong resource sinh ra). Chưa chạy trên máy ảo/máy thật.
- *File:* auth_service, auth_provider, widget nút mạng xã hội, 3 màn auth, settings, `ios/Runner/Info.plist`, `pubspec.yaml`/`.lock`, ARB + l10n sinh lại, test mới.

<!-- Dev D ghi giữa 2 dòng đánh dấu này -->
### File và hàm đã đụng

| File | Thay đổi |
|---|---|
| `pubspec.yaml` / `.lock` | `google_sign_in: ^7.2.0` (lock: `google_sign_in` 7.2.0, `_android` 7.2.11, `_ios` 6.3.6). Sàn Flutter trong lock lên `>=3.41.0` (do `google_sign_in_ios` 6.3.6), khớp toolchain 3.41.6. |
| `ios/Podfile.lock` | Thêm GoogleSignIn 9.2.0, AppAuth 2.1.0, GTMAppAuth 5.0.0. **GTMSessionFetcher 5.3.0 → 3.5.0**: GoogleSignIn 9.x đòi `~> 3.3`, Firebase 12.15 nhận `>= 3.4, < 6.0`, nên 3.5.0 là bản duy nhất hợp cả hai. Giải bằng `pod update GTMSessionFetcher` (không `pod repo update`). |
| `ios/Runner/Info.plist` | `CFBundleURLTypes` thêm 1 mục `google-sign-in` với 2 scheme REVERSED_CLIENT_ID (DEV `…529060310047-u3iu…`, PROD `…478033104351-83r1…`); giữ nguyên `dearembeiu`. `plutil -lint` OK. |
| `lib/services/auth_service.dart` | `AppleEmailHasPasswordException` → **`EmailHasPasswordAccountException`**. `signInWithApple()` thu gọn, phần hồ sơ tách ra helper chung **`_signInWithSocial(signIn, failed:)`**. Mới: **`signInWithGoogle()`**, `googleIdToken()` (`@visibleForTesting`, bước chọn tài khoản), `_ensureGoogleSignIn()` (gọi `initialize` đúng 1 lần cho cả app, lỗi thì cho thử lại), `_googleSignOut({disconnect})`, `isGoogleOnlyAccount`, `_passwordlessProvider(user)` (thay `_isAppleOnly`), `deleteMessagingToken()` (`@visibleForTesting`). `_mapAppleAuthError` → `_mapSocialAuthError(e, fallback:)`. `signOut` + `purgePersistedSession` đăng xuất Google khi user có provider `google.com`. `deleteAccount`: tài khoản Google-only thì `getIdToken(true)` (giới hạn 5s, lỗi chỉ log) trước callable, xoá xong `disconnect()`. `confirmAppleDeletionIfNeeded`: nhánh PF18. |
| `lib/providers/auth_provider.dart` | `enum SocialSignIn { apple, google }`. `isAppleSigningIn` → **`socialSignIn`** (nhà cung cấp đang chạy) + `isSocialSigningIn`. `appleEmailConflict` → `emailConflict`. `signInWithApple()` → **`signInWithSocial(SocialSignIn)`** (analytics `method: provider.name` = `apple`/`google`). `isGoogleOnlyAccount`. `deleteAccount` trả nguyên sentinel `social-canceled` / `apple-id-mismatch`. Thêm `onError` cho stream `sessionToken` (xem mục khác spec). |
| `lib/widgets/social_sign_in_buttons.dart` (mới, thay `apple_sign_in_button.dart` đã xoá) | `SocialSignInButtons({onSignInInstead, onExistingEmail})` + `static isAvailable(auth)`. iOS: Apple → 12 → Google; Android: chỉ Google; 10 → một dòng đồng ý chung. `_SocialButton` dùng chung cho 2 nút (pill 52, spinner khi chạy, Opacity .5 khi khoá, Semantics = nhãn). `_GoogleLogoPainter` vẽ 4 path của `google-g-logo-paths.txt`, scale 48 → 22. `AuthOrDivider` chuyển sang đây. |
| `lib/theme/app_colors.dart` | `googleBorder` #747775, `googleText` #1F1F1F (chỉ cho nút Google). |
| `lib/screens/guest_counter_screen.dart`, `login_screen.dart`, `register_screen.dart` | Đổi sang `SocialSignInButtons`, cờ khoá `isSocialSigningIn`. Vị trí giữ như design: landing trên hàng nút cũ, Đăng ký TRÊN form, Đăng nhập DƯỚI form. `guestCtaSignIn` giữ "Đăng nhập bằng email". |
| `lib/screens/settings_screen.dart` | So `social-canceled`. Nhánh `apple-id-mismatch` (ở dialog đầu và dialog xác minh lại) → SnackBar `deleteAccountAppleIdMismatch` + authGate. `_showReauthToDeleteDialog(context, noPasswordBody:)` thay `apple:`: Apple dùng `deleteAccountReauthBodyApple`, Google dùng `deleteAccountReauthBodyGoogle`, tài khoản mật khẩu giữ ô mật khẩu. |
| ARB en + vi | 5 key mới ngay sau `deleteAccountReauthBodyApple`: `continueWithGoogle`, `googleSignInFailed`, `socialConsentPrefix`, `deleteAccountReauthBodyGoogle`, `deleteAccountAppleIdMismatch`. Xoá `appleConsentPrefix`. `@authOrDivider` sửa description. Đã `flutter gen-l10n`. |
| `test/social_sign_in_test.dart` (mới) | 9 test: huỷ picker Google / huỷ sheet Apple → `social-canceled`, provider im lặng với cả hai; lỗi SDK/PlatformException/không có ID token → `googleSignInFailed`; ID token đi đúng vào `GoogleAuthProvider`; PF6 cho Google; lỗi Firebase mạng → `authNetworkError`; chỉ nhà cung cấp đang chạy bận, `isLoading` không bật. |
| `test/apple_delete_confirm_test.dart` | PF18: user mới bị xoá + xoá FCM token + đăng xuất + `apple-id-mismatch`; tài khoản có sẵn KHÔNG bị xoá; xoá user mồ côi / xoá token lỗi vẫn đăng xuất. Sentinel huỷ → `social-canceled`. |
| `test/auth_flow_hardening_test.dart` | `apple-canceled` → `social-canceled`; ca đổi Apple ID → `apple-id-mismatch`. |

Không đụng rules, Cloud Functions, native Swift/Kotlin, Android Gradle. Không deploy.

### API `google_sign_in` 7.x (đã đọc source trong pub cache)
- Android (`google_sign_in_android` 7.2.11): `init()` gặp `serverClientId == null` thì tự đọc resource `default_web_client_id` (google-services plugin sinh từ `oauth_client` type 3) qua `getGoogleServicesJsonServerClientId()`. Không có resource đó thì `authenticate()` ném `clientConfigurationError`. `clientId` bị bỏ qua trên Android. `authenticate()` dùng luồng nút (`GetSignInWithGoogleOption`, Credential Manager), luôn hiện bảng chọn tài khoản. Huỷ → `GoogleSignInExceptionCode.canceled`.
- iOS (`google_sign_in_ios` 6.3.6, GoogleSignIn SDK 9.2): truyền `clientId: Firebase.app().options.iosClientId` (plugin cũng tự đọc `CLIENT_ID` trong GoogleService-Info.plist nếu không truyền). SDK kiểm tra scheme REVERSED_CLIENT_ID trong Info.plist; thiếu thì ném NSException → `PlatformException` → `googleSignInFailed`. Plugin đăng ký cả `addSceneDelegate`, hợp với vòng đời UIScene của app.
- `initialize()` phải gọi đúng 1 lần trước mọi lệnh khác → memo tĩnh `_googleInit`. Chỉ gọi khi bấm nút Google hoặc khi tài khoản có provider `google.com` (đăng xuất/xoá), nên người dùng email/Apple không bao giờ khởi tạo SDK Google.

### Luồng và edge case
- **Huỷ (cả 2 nhà cung cấp)** → một sentinel `social-canceled`: đăng nhập im lặng (không SnackBar, không haptic), xoá tài khoản Apple không xoá gì.
- **Lỗi khác của Google**: lỗi SDK (`interrupted`, `uiUnavailable`, `clientConfigurationError`…), `PlatformException`, ID token rỗng → `googleSignInFailed`. Lỗi Firebase `network-request-failed` → `authNetworkError`, còn lại → `googleSignInFailed`. Chữ tiếng Anh chỉ vào `debugPrint`.
- **PF6** dùng chung `EmailHasPasswordAccountException` (key ARB `appleEmailHasPasswordAccount` giữ tên).
- **Bận**: `socialSignIn` chỉ cho nút đang chạy hiện spinner; nút còn lại Opacity .5 + khoá; nút email + link khoá như trước (`isSocialSigningIn`). `isLoading` không bật.
- **PF3**: `requiresEmailVerification` đã trả false cho user không có provider `password` → Google không qua cổng xác thực (chỉ sửa comment).
- **Đăng xuất**: `GoogleSignIn.signOut()` chạy nền (`unawaited`, try/catch), chỉ khi user có `google.com`. Áp cho cả đăng xuất thường, bị máy khác đá ra (single-session) và `purgePersistedSession`.
- **Xoá tài khoản Google-only** (có `google.com`, không `password`, không `apple.com`): không sheet; `getIdToken(true)` trước callable; xoá xong `disconnect()` chạy nền. `requires-recent-login` → dialog không ô mật khẩu, body Google, bấm là thử lại 1 lần; lần hai vẫn lỗi → `deleteAccountSessionExpiredMsg` + authGate (y nhánh Apple/mật khẩu).
- **PF18** (sheet Apple trả uid khác): (a) `additionalUserInfo.isNewUser == true` → `user.delete()` (lỗi chỉ log); tài khoản có sẵn thì không bao giờ xoá; (b) `FirebaseMessaging.deleteToken()` (lỗi chỉ log); (c) `signOut`; (d) ném `apple-id-mismatch` → Settings hiện câu riêng + authGate. CF không có trigger Auth nào (đã grep `functions/index.js`), nên xoá user mồ côi không để lại dữ liệu.

### Chỗ làm khác brief (PO/Tester xem)
1. **Sheet Apple trả `user == null`** (gần như không xảy ra) vẫn ném `session-gone` như cũ, nhưng giờ cũng xoá FCM token: cùng lý do, đều là đăng xuất mà không gỡ push.
2. **`getIdToken(true)` của Google lỗi thì vẫn gọi callable**: làm mới token chỉ để bớt ca phiên cũ, callable mới là bên quyết định (thành công, hoặc `unauthenticated` → dialog thử lại). Giới hạn 5 giây để overlay không treo.
3. **Android `disconnect()` chỉ thu hồi được khi người dùng đăng nhập Google trong cùng phiên chạy app**: plugin chỉ nhớ tài khoản đã `authenticate()` trong process hiện tại. Mở lại app rồi xoá thì chỉ xoá trạng thái Credential Manager, quyền của app vẫn nằm trong trang "Ứng dụng bên thứ ba" của Google. iOS thu hồi đầy đủ. Không ảnh hưởng việc xoá tài khoản.
4. **Thêm `onError` cho stream `sessionToken`** (1 dòng, ngoài brief): ở nhánh PF18, `signInWithProvider` đổi user giữa chừng nên listener `users/{uidCũ}` bị rules từ chối. Không có `onError` thì lỗi rơi vào `PlatformDispatcher.onError` và Crashlytics ghi thành **fatal** (app không crash). Lỗi này có từ trước ở nhánh `session-gone` và khi phiên bị thu hồi từ ngoài.
5. **Ripple nút Google** = overlay mặc định của `FilledButton` theo màu chữ #1F1F1F (10% khi nhấn), không cần cấu hình thêm. Nút Google dựng chung `_SocialButton` với nút Apple (`FilledButton` nền trắng + `side` 1px).
6. **Đổi tên API provider** `signInWithApple()` → `signInWithSocial(SocialSignIn)`; service vẫn giữ `signInWithApple()` + thêm `signInWithGoogle()`.
7. **`ios/Podfile.lock` hạ GTMSessionFetcher 5.3.0 → 3.5.0** (xem bảng). Lần `flutter build ios` đầu dừng ở `pod install` ("specs repository is too out-of-date") chính vì xung đột này, không phải vì index cũ. `project.pbxproj` không đổi.

### Cần Tester / Lead chạy trên máy ảo
- **Android emulator**: image phải có Google Play và đã đăng nhập tài khoản Google (không có thì bảng chọn mời thêm tài khoản). Bản debug = app `com.tony.dearembeiu.dev` → Firebase DEV (SHA-1 debug `FB:F7:1E:29…` đã đăng ký). Chỉ thấy nút Google, không có nút Apple; dòng đồng ý "Khi tiếp tục, bạn đồng ý với Chính sách bảo mật."
- **iOS simulator**: thấy Apple (trên) + Google (dưới). Google mở trang đăng nhập qua `ASWebAuthenticationSession` (hộp "Dear Embeiu muốn dùng google.com để đăng nhập"); bấm Huỷ ở hộp đó hoặc đóng trang → im lặng.
- Người mới bấm Google → tạo `users/{uid}` có mã mời → Setup, không qua màn xác thực email. Người cũ → Home. Analytics `sign_up`/`login` `method=google`.
- Đăng xuất rồi bấm Google lại → phải hiện chọn tài khoản (không tự vào tài khoản cũ).
- **PF6 với Google, cần soát** (theo tài liệu Firebase, chưa thử thật): Firebase coi Google là nhà cung cấp tin cậy cho địa chỉ `@gmail.com`. Đăng nhập Google bằng gmail đã có tài khoản mật khẩu nhiều khả năng **không** báo PF6 mà vào thẳng tài khoản cũ (Firebase tự nối). Nếu tài khoản mật khẩu đó chưa xác thực email, Firebase gỡ luôn provider `password`, mật khẩu cũ hết dùng được. Khi đó câu PF6 chỉ hiện với email không phải gmail. Nếu email trùng một tài khoản **Apple** (không có mật khẩu) mà Firebase báo PF6, câu "Đăng nhập bằng mật khẩu nhé" sẽ sai: PO cân nhắc copy.
- Xoá tài khoản Google-only: không sheet, xoá xong về landing; Firebase Console DEV → Authentication không còn user.
- **PF18** (iOS, cần 2 Apple ID): đăng nhập Apple ID A, đổi Apple ID của máy sang B, vào Cài đặt → Xoá tài khoản → sheet hiện B → SnackBar "Apple ID trên máy này khác tài khoản bạn đang xoá…" + về landing; tài khoản A còn nguyên. B chưa từng dùng app → Console không còn user mồ côi của B; B đã có tài khoản → user B còn nguyên. Sau đó nhờ người ấy của A gửi tin → máy này không còn nhận push của A.
- **Việc trước khi release (ngoài code)**: bật provider Google trên Firebase **PROD** (Console); thêm SHA-1 của khoá upload + khoá ký Play vào app Android PROD rồi tải lại `google-services.json` (thiếu thì Android PROD bấm Google ra `googleSignInFailed`). iOS PROD đã có `CLIENT_ID` + scheme.
- `CLAUDE.md` mục 2 (dòng "Phễu ghép đôi") còn nhắc `widgets/apple_sign_in_button.dart` (đã xoá). Lead cập nhật khi merge.

### Nhật ký
- [2026-10-11] [Dev D] Worktree tạo từ `main`@1c982ea → reset về `799c5bb` (`feature/pairing-funnel`), cây sạch.
- [2026-10-11] [Dev D] Implement PF14–PF18 theo bảng trên. Thử phá 5 chỗ (xoá cả user có sẵn, bỏ xoá token, huỷ Google ra lỗi, trả sentinel cũ, bỏ sentinel `apple-id-mismatch`) → đều có test đỏ; khôi phục → xanh. Probe widget tạm (không commit): 2 nút ở bề rộng 240/253/295/400 × cỡ chữ 1.0–3.0 × vi/en đều cao 52, không tràn; semantics, spinner/khoá đúng; vẽ thử logo "G" ra PNG để soát mắt. analyze 0, test 259/259. Build iOS thiết bị lần 1 dừng ở `pod install` (xung đột GTMSessionFetcher) → `pod update GTMSessionFetcher` → build iOS OK, build APK debug OK. Không deploy, không push.

### Dev-fix đợt 2 (sau thử máy ảo)
*2026-10-11 · `flutter analyze` 0 · `flutter test` 261/261 · không build iOS, không deploy, không push.*
- **Tên app trong hộp "… muốn sử dụng google.com để đăng nhập":** hộp này đọc `CFBundleName`, trước ghi cứng `dear_embeiu`. `ios/Runner/Info.plist` đổi sang `$(APP_DISPLAY_NAME)`: Debug/Profile ra "Dear Embeiu Dev" (đúng 15 ký tự), Release ra "Dear Embeiu". `plutil -lint` OK. ⚠️ Tên IPA Xcode xuất ra có vẻ lấy từ `CFBundleName` (archive 1.8.0: app `Runner`, IPA `dear_embeiu.ipa`), nên bản sau nhiều khả năng ra `build/ios/ipa/Dear Embeiu.ipa` (chưa build để xác nhận). `scripts/store-upload/upload-ios-transporter.sh` mặc định vẫn tìm `dear_embeiu.ipa`: build sau `flutter clean` thì script báo không thấy file, còn nếu file cũ vẫn nằm đó thì script tải nhầm bản cũ. Chưa sửa script (ngoài phạm vi): lúc release truyền đường dẫn mới, hoặc PO cho sửa mặc định.
- **Câu PF6 trung tính nhà cung cấp:** key `appleEmailHasPasswordAccount` giữ tên, chữ đổi thành VI "Email này đã có tài khoản. Đăng nhập bằng cách bạn đã dùng lần trước nhé." / EN "This email already has an account. Sign in the way you did before." Description EN sửa theo, đã `flutter gen-l10n`. Màn Đăng nhập vẫn điền sẵn email và đưa con trỏ vào ô mật khẩu như cũ.
- **Nhắc mời lập lại sau khi quay lại app:** `ReminderProvider.invalidateDailyQuestionSchedule()` (Home gọi lúc resume) xoá thêm `_inviteFollowUpSignature`, vá ca ở "Giới hạn đã biết" của Phần E. Còn hở: lời gọi `refreshInviteFollowUps` ở Home nằm sau khoá `_lastReminderKey` (ngày yêu, ảnh mới nhất, ngôn ngữ, trạng thái couple, ngày). Quay lại app trong cùng ngày thì band chỉ được lập lại ở lần Home dựng lại đầu tiên của hôm sau. Muốn lập ngay: thêm `_lastReminderKey = null` ở nhánh resume (1 dòng, đổi lại `sync()` chạy lại mỗi lần resume). Chờ PO chốt.

### Lối xoá tài khoản khi chưa ghép đôi (P1)
*2026-10-11 · `flutter analyze` 0 · `flutter test` 262/262 (261 cũ + 1 mới) · không đổi ARB, rules, Functions, native · không build iOS, không deploy, không push.*

- **Vấn đề:** đăng nhập Apple/Google xong là vào Setup. Setup không có đường tới Cài đặt, còn Cài đặt thì trả trang trắng khi `couple == null`. Reviewer tạo tài khoản bằng Apple rồi đi tìm nút xoá là kẹt (Guideline 5.1.1(v), Play cũng đòi).
- **`lib/screens/settings_screen.dart`**
  - `build`: bỏ `return SizedBox.shrink()` khi chưa có couple, thay bằng cờ `hasCouple`. Chưa có couple thì trang còn: header · Tài khoản · thẻ Quản lý dữ liệu (chỉ tầng Xoá tài khoản) · Đăng xuất · dòng phiên bản. Thông báo, âm lịch và nhóm Chung (ngôn ngữ, ảnh nền, analytics, chính sách, Có gì mới) ẩn hết.
  - `_buildDangerZone(…, hasCouple:)`: chưa có couple thì ẩn câu mô tả (nói về cặp đôi), nút "Xoá dữ liệu trên máy này" hoặc cảnh báo chế độ local, nút "Rời cặp đôi". Vạch "Không thể hoàn tác" và nút đỏ "Xoá tài khoản" vẫn là một chỗ duy nhất, không chép code. `_showDeleteAccountDialog`, `_showReauthToDeleteDialog` và các nhánh `social-canceled` / `apple-id-mismatch` / `session-gone` / `requires-recent-login` giữ nguyên.
  - `_buildAccountSection` chỉ đọc `AuthProvider.currentUser`, không dính couple.
- **`lib/screens/setup_screen.dart`** (`_buildHeader`, chế độ tạo): thêm `HeaderIconButton` bánh răng (`IconsaxPlusLinear.setting_2`, semantics `settingsTitle`) bên trái pill Đăng xuất. Bấm là `Navigator.push(MaterialPageRoute)` tới `SettingsScreen`, `RouteSettings(name: 'Settings')` giống Profile. Row header đổi thành `OverflowBar`: cỡ chữ thường vẫn một hàng; chữ to thì cặp bánh răng + Đăng xuất xuống dòng dưới chip, canh trái. Chế độ sửa (`SubScreenHeader`) không đổi. Pill Đăng xuất giữ nguyên.
- **Xoá xong:** dialog vẫn gọi `pushNamedAndRemoveUntil(authGate, (_) => false)` trên navigator gốc, dọn cả Cài đặt lẫn Setup, resolver đưa về landing. Lúc sheet Apple/Google hiện, iOS báo `resumed` cho Setup; `_checkClipboardInvite` đã có chốt "Setup phải là route trên cùng" nên không bật sheet mã mời đè lên Cài đặt.
- **Đo header** (probe tạm với phông Quicksand thật, đã xoá): ở 375pt cỡ chữ 1.0, một hàng, còn dư 79,5pt (vi) / 60,9pt (en); chip, bánh răng, pill cùng tâm dọc. Nếu giữ Row, thêm bánh răng làm header tràn ở 375pt từ 1.75x (en) / 2.0x (vi), ở 320pt từ 1.15x (en) / 1.3x (vi). Với `OverflowBar`, đúng các mốc đó header xuống dòng, không tràn tới 3.0x ở cả 320 lẫn 375pt.
- **Test:** `test/settings_no_couple_test.dart` (mới). Couple null: vẫn có tên tài khoản, "Không thể hoàn tác", "Xoá tài khoản", "Đăng xuất"; không có "Rời cặp đôi", "Xoá dữ liệu trên máy này"; bấm Xoá mở dialog "Xoá tài khoản?". Trả `settings_screen.dart` về HEAD thì test đỏ (không tìm thấy tên tài khoản).

**Cần Lead/Tester xem trên máy ảo**
- Header Setup cao hơn: hàng giờ cao 44 (cũ khoảng 32) nên chip thấp xuống 6pt, tiêu đề 12pt.
- Setup → bánh răng → Cài đặt bản rút gọn → Xoá tài khoản (Apple: có sheet; Google: không sheet; mật khẩu: dialog nhập lại khi phiên cũ) → về landing, Firebase DEV → Authentication không còn user.
- 3 tài khoản trong `_hideDataManagementEmails` vẫn bị ẩn thẻ này kể cả khi chưa ghép đôi (giữ quyết định 2026-06-19), nên với họ bản rút gọn không có nút xoá. Tài khoản reviewer không bị ảnh hưởng.
- Bản rút gọn không có ngôn ngữ, chính sách bảo mật (bám danh sách trong brief). PO muốn thêm thì báo, đó là các hàng không cần couple.
- Ngoài phạm vi, không sửa: nhãn 2 tab Tạo/Tham gia ở Setup dùng `AnimatedDefaultTextStyle` không có `fontFamily` (`setup_screen.dart`, `_buildModeTabLabel`), nên trên máy hiện bằng phông hệ thống chứ không phải Quicksand.
- Android: bấm bánh răng trong 0,5 giây đầu sau khi mở Setup thì lượt dò mã mời trong bộ nhớ tạm bị bỏ qua (Setup không còn ở trên cùng, mà Android chỉ dò lúc mở). Gần như không gặp.

### Dev-fix vòng 3 (theo Tester)
*2026-10-11 · `flutter analyze` → No issues found! · `flutter test` 266/266 (262 cũ + 4 mới) · không đổi ARB, rules, Functions, native · không build iOS, không deploy, không push.*

| Mục | Sửa gì | File | Test |
|---|---|---|---|
| BUG-8 (P3) | Cả 2 dialog xoá (dialog đầu + dialog xác minh lại) lấy `ScaffoldMessenger` TRƯỚC `await deleteAccount()`. Quay lại mà Settings/dialog đã bị gỡ (shell đã đẩy authGate) thì vẫn hiện SnackBar cho `apple-id-mismatch` / `session-gone` qua messenger gốc rồi dừng, không điều hướng nữa. Còn mounted thì chạy y như cũ. Đoạn SnackBar gom vào `_showSignedOutSnack(messenger, l10n, code)`: trước chép 2 lần, nay 4 chỗ gọi. Nhánh khác không đổi. | `lib/screens/settings_screen.dart` (`_showDeleteAccountDialog`, `_showSignedOutSnack`, `_showReauthToDeleteDialog`) | `test/settings_no_couple_test.dart`, 2 test (dialog đầu / dialog xác minh lại): fake `deleteAccount()` làm y shell (thay mọi route bằng màn "gate") rồi mới trả `apple-id-mismatch` → câu `deleteAccountAppleIdMismatch` vẫn hiện. Chạy với `settings_screen.dart` bản HEAD: cả 2 đỏ. |
| BUG-9 (P3) | Nhánh `isNewUser` của PF18 thu hồi quyền Apple bằng `authorizationCode` của Apple ID lạ TRƯỚC `user.delete()`, vì thu hồi cần user đó còn đăng nhập. Lỗi chỉ `debugPrint`, vẫn xoá. Apple ID đã có tài khoản thì không thu hồi, không xoá. Đoạn thu hồi tách thành `_revokeAppleToken(credential)`, dùng chung với nhánh cùng Apple ID. | `lib/services/auth_service.dart` (`confirmAppleDeletionIfNeeded`, `_revokeAppleToken`) | `test/apple_delete_confirm_test.dart`: user mới → thu hồi bằng `fresh-code` khi user chưa bị xoá; user cũ → không thu hồi; thu hồi lỗi + xoá lỗi + xoá FCM token lỗi → vẫn đăng xuất |
| Ưu tiên Google trên Android | `_passwordlessProvider`: có cả `apple.com` lẫn `google.com` thì iOS chọn Apple như cũ, nền tảng khác chọn Google. Chỗ này quyết định cả 3 nơi: dialog Settings (không còn câu báo trước sheet Apple, body xác minh lại kiểu Google), `deleteAccount` (làm mới token + `disconnect`), `confirmAppleDeletionIfNeeded` (bỏ qua, không mở sheet). Dùng `defaultTargetPlatform`; test giả lập được bằng `debugDefaultTargetPlatformOverride` nên không tách hàm thuần. | `lib/services/auth_service.dart` (`_passwordlessProvider`) | `test/apple_delete_confirm_test.dart`: Android + 2 provider → không gọi sheet, `isGoogleOnlyAccount` true; iOS → có sheet, `isAppleOnlyAccount` true |
| Timeout làm mới token | `getIdToken(true)` nhánh Apple giới hạn 5 giây, lỗi/timeout chỉ log, để callable quyết. Gom với bản của nhánh Google thành `_refreshIdTokenBeforeDelete(user)`. Trước đây lỗi mạng ở bước này dừng việc xoá ngay với `authNetworkError`; nay đi tiếp tới callable, mất mạng thì callable trả `unavailable` → vẫn `authNetworkError`. | `lib/services/auth_service.dart` (`deleteAccount`, `confirmAppleDeletionIfNeeded`, `_refreshIdTokenBeforeDelete`) | `test/apple_delete_confirm_test.dart`: làm mới token ném `network-request-failed` → xác nhận vẫn xong, không ném lỗi |
| Phông 2 tab Tạo/Tham gia | `_buildModeTabLabel`: thêm `fontFamily: AppTheme.fontFamily` vào style của `AnimatedDefaultTextStyle`. Style này thay hẳn style kế thừa nên nhãn rơi về phông hệ thống. Mục "Ngoài phạm vi" ở trên coi như đã xử lý. | `lib/screens/setup_screen.dart` | Không có test (1 dòng giao diện), cần nhìn trên máy ảo |

Đã thử phá 5 chỗ trong `auth_service.dart`: thu hồi sau khi xoá, bỏ thu hồi, thu hồi cả Apple ID đã có tài khoản, Apple luôn thắng, `getIdToken` không bọc. Lần nào cũng đúng test tương ứng đỏ; khôi phục → xanh.

**Cần Lead/Tester xem**
- **BUG-8 trên máy thật** (iOS, 2 Apple ID, kịch bản PF18 ở trên với Apple ID B chưa từng dùng app): sau khi về landing phải thấy câu "Apple ID trên máy này khác tài khoản bạn đang xoá…". SnackBar nằm ở messenger gốc nên đi theo qua authGate → landing (cả hai màn đều có `Scaffold`).
- **Tài khoản nối cả Apple lẫn Google, xoá trên Android:** không mở sheet Apple nên không có `authorizationCode`, quyền Apple của tài khoản đó KHÔNG được thu hồi (vẫn nằm trong mục "Đăng nhập bằng Apple" của Apple ID). Google `disconnect()` trên Android cũng chỉ thu hồi được khi đã đăng nhập Google trong cùng phiên chạy app (Phần D, mục khác brief 3). Tài khoản Firebase vẫn bị xoá đầy đủ. Muốn thu hồi cả quyền Apple thì xoá trên iPhone.
- Ca mounted vẫn điều hướng 2 lần (shell + dialog cùng `pushNamedAndRemoveUntil(authGate)`), như đã ghi ở vòng 1–2.
- Phông tab Setup: 2 nhãn "Tạo mới" / "Tham gia bằng mã" phải cùng phông bo tròn với tiêu đề bên trên.
<!-- /Phần D -->

---

## Đợt 2 — Phần E: PF19 (người ấy vào lúc app tắt)

- *Trạng thái:* xong code (2026-10-11), sẵn sàng test. CF CHƯA deploy: Lead deploy DEV sau khi gộp (`functions:notifyPartnerJoined`), PROD đi cùng release.
- *File:* `functions/index.js` (chỉ `notifyPartnerJoined`), `lib/services/push_notification_service.dart`, `lib/services/reminder_service.dart` (nếu cần cho isolate nền), test mới.

<!-- Dev E ghi giữa 2 dòng đánh dấu này -->
### File và hàm đã đụng

| File | Thay đổi |
|---|---|
| `functions/index.js` | `notifyPartnerJoined` truyền tham số thứ 4 `{wakeClients: true}` cho `sendToRecipientDevices`. iOS: push alert có thêm `content-available`. Android: mỗi máy nhận thêm 1 tin data-only (`type`, `coupleId`, `joinerUserId`, không title/body). Helper giữ nguyên. |
| `lib/services/push_notification_service.dart` | Hàm thuần `isPartnerJoinedPush(data)` (`@visibleForTesting`) và `_cancelInviteFollowUpsIfPartnerJoined(message)`. Gọi ở `firebaseMessagingBackgroundHandler` (isolate nền) và `_handleForegroundMessage` (app đang mở), ngay sau `_cancelStaleDailyQuestionNudges`. |
| `lib/services/reminder_service.dart` | `cancelInviteFollowUps()` bỏ chốt `if (!_initialized) return;`. Sửa comment chủ sở hữu band 1180–1189. |
| `test/partner_joined_push_test.dart` (mới) | 2 test: push alert và tin companion Android đều kích hoạt huỷ; type khác, type rỗng, thiếu type thì không. |

Không đổi rules, model, ARB, native, provider, pubspec.

### Vì sao bỏ chốt init ở `cancelInviteFollowUps()` thay vì viết hàm mới
Ở isolate nền Android, `ReminderService.instance` là bản mới tinh, `_initialized == false`, nên hàm cũ return ngay và không huỷ gì. Lệnh `cancel` của plugin là lệnh native thuần: đã đọc source `flutter_local_notifications` 19.5.0 cả 3 tầng (Dart, Android `cancelNotification`, iOS `cancel:`), không tầng nào cần `initialize()`. `cancelDailyQuestionBands()` dựa đúng vào điều này từ 1.4.2.

Bỏ chốt ngay trong hàm này thì mọi nơi gọi đều được lợi, không riêng handler push:
- **Isolate nền Android** (handler FCM): nay huỷ được.
- **iOS bị push đánh thức khi app đã tắt** (không phải force-quit): `main()` chạy, nhưng `ReminderService.initialize()` nằm trong post-frame callback nên có thể chưa chạy lúc handler chạy.
- **Mở app lạnh:** Home gọi `refreshInviteFollowUps(waiting: false)` không chờ `sync`, có thể trước khi `initialize()` hoãn chạy xong. Khi đó hàm cũ im lặng bỏ qua, trong khi provider đã đặt `_inviteFollowUpCleared = true` nên cả phiên không thử lại. Lỗi ngầm này có thể đã xảy ra từ trước, nay hết.

`cancelInviteFollowUp(kind)` (huỷ riêng mốc 2 giờ khi bấm Gửi) vẫn giữ chốt: chỉ chạy trên isolate chính, sau khi app đã khởi động.

### Luồng sau khi sửa

| App của người tạo lúc người ấy vào | Cái gì huỷ band 1180–1189 |
|---|---|
| Đang mở | `_handleForegroundMessage`. Android nhận 2 tin (alert + companion) nên huỷ 2 lần, vô hại; banner chỉ hiện 1 lần vì companion không có title/body. Home cũng tự huỷ khi thấy couple active. |
| Nền hoặc đã tắt, Android | Tin companion data-only → `firebaseMessagingBackgroundHandler` trên isolate nền. |
| Nền hoặc đã tắt (không force-quit), iOS | Push alert có `content-available` → plugin gọi handler nền trên isolate chính. Khi app đang mở, plugin không gửi `onMessage` lần 2 cho push có alert (đã đọc `FLTFirebaseMessagingPlugin.m` 16.4.0). |
| iOS bị force-quit | Không có wake. Band được huỷ ở lần mở app sau, khi Home thấy couple active. Nhắc nào rơi vào khoảng giữa vẫn nổ. Đây là giới hạn của iOS, giống nhắc câu hỏi hằng ngày. |

`cancel` trên cả 2 nền tảng cũng gỡ nhắc đã hiện trong khay thông báo (iOS `removeDeliveredNotifications…`, Android `NotificationManager.cancel`). Một câu "người ấy chưa vào" đã nổ trước đó sẽ biến khỏi khay khi người ấy vào.

### Cần Tester soi
- **Môi trường:** push iOS trên DEV đang hỏng vì project DEV chưa có APNs key (CLAUDE.md §5). Nhánh iOS chỉ thử được sau khi thêm key, hoặc trên PROD. Android cần máy thật hoặc emulator có Google Play đã đăng nhập tài khoản Google (emulator Google APIs không đăng ký được FCM).
- **Kịch bản chính:** A tạo couple (band 1180–1182 đã lập) → vuốt app A khỏi danh sách đa nhiệm (Android) hoặc chỉ đưa về nền (iOS) → B nhập mã → máy A không còn lịch 1180–1182. Android xem bằng `adb shell dumpsys alarm | grep -B2 -A6 com.tony.dearembeiu.dev` trước và sau khi B vào. Cách chậm hơn: tạo couple lúc 21:00, A không bấm Gửi/Sao chép/QR (B gõ mã nhìn từ màn hình A), rồi xem mốc 08:30 sáng hôm sau (mốc +2 giờ bị dời) có nổ không.
- Đừng dùng *Buộc dừng* trong Cài đặt Android để "tắt app": Android chặn mọi push tới app bị buộc dừng, kịch bản sẽ fail oan.
- **App đang mở:** banner "người ấy đã vào" chỉ hiện 1 lần trên Android (không có banner rỗng từ tin companion).
- **Log CF sau khi deploy DEV:** `Processed partner-joined notification` sẽ có `successCount` lớn hơn `attemptedTokens` với máy Android. Đây không phải lỗi: `deviceCount` đếm máy, còn `successCount` đếm cả tin companion. `notifyDailyAnswer` cũng log như vậy từ 1.4.2.

### Giới hạn đã biết (ngoài ranh giới file Phần E)
- **App còn sống ở nền rồi người ấy rời ngay:** handler huỷ band qua service, nhưng chữ ký debounce `_inviteFollowUpSignature` của `ReminderProvider` (isolate chính) vẫn ghi "đã lập". Nếu người ấy vào rồi RỜI trong 72 giờ đầu mà người tạo chưa mở app lần nào, Home thấy couple chờ lại với cùng mốc tạo, chữ ký trùng nên không lập lại các mốc còn lại. Rất hiếm, hậu quả chỉ là thiếu nhắc. Muốn vá: `invalidateDailyQuestionSchedule()` (đã gọi lúc resume) đặt thêm `_inviteFollowUpSignature = null`. Một dòng trong `reminder_provider.dart`, file không thuộc Phần E.

### Kiểm tra đã chạy
- `node --check functions/index.js` → OK.
- `scripts/test-firebase-rules.sh` → **330 passing**, exit 0 (gồm bước kiểm cú pháp `functions/index.js`).
- `flutter analyze` → **No issues found!**
- `flutter test` → **250/250** (248 cũ + 2 mới).

### Nhật ký
- [2026-10-11] [Dev E] Worktree bị tạo từ `main`@1c982ea; cây sạch nên reset về `799c5bb` (`feature/pairing-funnel`) trước khi làm.
- [2026-10-11] [Dev E] PF19: CF `notifyPartnerJoined` gửi kèm `wakeClients`; handler nền và handler foreground huỷ band 1180–1189 khi `type == partner_joined`; `cancelInviteFollowUps()` chạy được khi service chưa init. Rules-test 330, analyze 0, test 250/250. Không deploy, không push.
<!-- /Phần E -->

---

## Nhật ký chung (Lead ghi khi merge)
- [2026-10-11] [Lead] Chia 2 phần A/B, chạy song song trên worktree riêng.
- [2026-10-12] [Lead] `social_sign_in_buttons.dart`: bỏ tham số `textStyle`/`gap` của `_SocialButton`, mọi nút dùng chung một kiểu chữ (iOS `CupertinoSystemDisplay` 22 w500, Android Roboto 18 w500, màu = `foreground`, cách logo 10); logo Apple 24, G 22. analyze 0 · test 266/266 · kiểm bằng ảnh simulator.
