# 🧪 Test — pairing-funnel

> Tester sở hữu. CHỈ test, không sửa code. Nguồn: `overview.md` (PF1–PF13), `design.md`, `dev.md` (Phần A + B), diff `086f1e0..509e46f`.
> Agent Tester chỉ có quyền đọc nên Lead dán nguyên văn kết quả vào file này (2026-10-11).

- **Trạng thái test:** PASS có điều kiện (code-level vòng 3 + chạy máy ảo M1–M24, 2026-10-11) — đợt 1: vá xong BUG-1..7; đợt 2: 0 P0/P1/P2 · 3 P3 (BUG-10 đã vá `439ab91`, BUG-8/9 đang vá) · P1 xoá tài khoản khi chưa ghép đôi đã vá `2356e7b` · chặn phát hành: Apple PROD, Google PROD + SHA-1 Android PROD, khoá .p8, CF `notifyPartnerJoined` PROD, get.html sau khi live
- **Người/role:** Master Tester
- **Nhánh/commit:** `feature/pairing-funnel` @ `509e46f`

## Phạm vi & pre-flight
- Apple (PF1–PF6, PF11), QR (PF7), trang get (PF8, PF12), bộ nhớ tạm (PF9, PF12, PF13), lời nhắc mời (PF10), l10n, bảo mật/riêng tư.
- `flutter analyze` 0 · `flutter test` 241/241 (Lead chạy). Tester chạy lại 4 file liên quan: 29/29 (`invite_clipboard_test`, `invite_follow_up_slots_test`, `apple_display_name_test`, `auth_flow_hardening_test`).
- ARB: 19 key mới đủ vi + en, 0 key lệch giữa 2 file, chỉ `inviteQrSemantics` có `{code}` (placeholder hợp lệ).
- Build `Debug-iphoneos` (sau khi sửa `AppDelegate.swift`) biên dịch được, có chuỗi kênh `dear_embeiu/clipboard`. Deployment target iOS 15.0 → `detectPatterns(for: [\.probableWebURL])` hợp lệ.
- Probe Dart ngoài repo: bản sao regex PF9 với 25 chuỗi + bản sao `inviteFollowUpSlots` với 11 mốc (biên 22:00/08:00, cuối tháng, cuối năm, DST New York).
- Nhánh runtime: Apple chỉ chạy khi `isUsingFirebase` (local fallback: nút ẩn, `signInWithApple` ném lỗi, `confirmAppleDeletionIfNeeded` no-op — có test). Bộ nhớ tạm + lời nhắc chạy như nhau ở 2 nhánh.

## Test case

| ID | Mô tả | Kết quả | Bằng chứng |
|---|---|---|---|
| A1 | Nút Apple chỉ hiện trên iOS + Firebase sẵn sàng; Android/local không render, không chừa khoảng | PASS | `apple_sign_in_button.dart:35-36`; `guest_counter_screen.dart:485`; `login_screen.dart:368`; `register_screen.dart:269` |
| A2 | Huỷ sheet Apple → im lặng, không lỗi đỏ, không haptic | PASS | `auth_service.dart:822-826` → `auth_provider.dart:279-282` → `apple_sign_in_button.dart:55-58` |
| A3 | PF6: câu PF6 5s; landing/Đăng ký có action "Đăng nhập"; màn Đăng nhập điền sẵn email + focus mật khẩu | PASS | `auth_service.dart:366-372`; `auth_provider.dart:274-278`; `apple_sign_in_button.dart:60-77`; `login_screen.dart:47-50` |
| A4 | Mất mạng → `authNetworkError`; lỗi khác → `appleSignInFailed`, chữ tiếng Anh chỉ vào log | PASS | `auth_service.dart:827-834` |
| A5 | Email rỗng sau Apple → signOut + báo lỗi | PASS | `auth_service.dart:344-348` |
| A6 | Cờ bận riêng: Apple chạy → nút email khoá, không spinner; email chạy → nút Apple mờ .5, không spinner | PASS | `auth_provider.dart:250,289` (không đụng `isLoading`); `apple_sign_in_button.dart:85-98`; `login_screen.dart:337,347`; `register_screen.dart:508,517`; `guest_counter_screen.dart:495,509` |
| A7 | PF3: Apple không qua cổng xác thực; tài khoản mật khẩu post-cutoff vẫn bị gate (không hồi quy D-auth2) | PASS | `auth_service.dart:443-459` (chỉ thêm nhánh "không có provider password" ở `:451-453`); `session_resolver.dart:172` |
| A8 | Hồ sơ Apple mới hợp lệ với rules `users/{uid}`: đủ 9 key, email/displayName/inviteCode không rỗng, không key lạ | PASS | `auth_service.dart:363-365,781-796`; `app_user.dart:44-54`; `firestore.rules:36-97`. Cùng payload với `signUp` email đang chạy PROD |
| A9 | Người cũ đăng nhập lại: giữ email cũ (rules cấm đổi), ghi merge | PASS | `auth_service.dart:352-360,957-977`; `firestore.rules:99-108` |
| A10 | PF4: tên Apple → phần trước @ (bỏ relay) → `defaultDisplayName`; Firebase nhận fullName Apple ở lần đầu | PASS | `auth_service.dart:803-816` + 4 test; plugin `FLTFirebaseAuthPlugin.m:444-447`; Pods `VerifyAssertionRequest.swift:163-170` |
| A11 | Session token + push sync + analytics giống `signIn` (method `apple`) | PASS | `auth_provider.dart:257-272` so với `:216-230` |
| A12 | Dòng đồng ý → `dearembeiu.com/privacy-policy.html` (live 200), vùng chạm 44 | PASS | `apple_sign_in_button.dart:158-218`; `app_urls.dart:2` |
| A13 | Huỷ xoá tài khoản → đăng xuất → "Tiếp tục với Apple" trong cùng phiên | FAIL (BUG-1) | xem BUG-1 |
| B1 | Xác nhận Apple chạy TRƯỚC gỡ push / tắt single-session / `_intentionalAuthClear` | PASS | `auth_provider.dart:399` trước `:403-416`; test PF5 trong `auth_flow_hardening_test.dart` |
| B2 | Huỷ sheet khi xoá → không xoá, không SnackBar, session watch còn sống | PASS | `auth_provider.dart:423-432`; `settings_screen.dart:1060-1061,1137-1141`; test PF5 |
| B3 | Thu hồi token lỗi → log, vẫn xoá | PASS | `auth_service.dart:667-675` |
| B4 | `requires-recent-login` bản Apple: không ô mật khẩu, bấm → sheet Apple; lần 2 lỗi → `deleteAccountSessionExpiredMsg` + authGate | PASS | `settings_screen.dart:1062-1065,1111-1125,1145-1160,1188-1189` |
| B5 | Tài khoản mật khẩu: hành vi xoá không đổi | PASS | `auth_service.dart:660-662`; `settings_screen.dart:1123-1125,1171-1177` |
| B6 | Local fallback: xác nhận Apple không chạm FirebaseAuth | PASS | `auth_service.dart:656-658`; test "no-op without Firebase" |
| C1 | QR chứa đúng `https://dearembeiu.com/get?code=<MÃ IN HOA>`, ECC M, nền trắng, vùng trắng đủ | PASS | `invite_qr_sheet.dart:72-86`; `app_urls.dart:16-19`; ContentCard padding 20 + sheet `cardSurface` #FFFFFF |
| C2 | Nút QR theo guard sẵn có: Setup `showInviteActions`, Home khi có mã, Profile khi `isWaitingForPartner` | PASS | `setup_screen.dart:876,914-917`; `home_screen.dart:2145,2162,2224-2228`; `profile_screen.dart:127-139` |
| C3 | QR ở Profile (mã cá nhân) vẫn ghép được qua `invite_codes` | PASS | `couple_service.dart:384-408,436-443`; pointer `coupleId` đồng bộ khi tạo couple `user_service.dart:168-177,276-298` |
| C4 | Mở QR = log `invite_shared('qr')` (không log mã) + huỷ mốc 2h | PASS | `invite_qr_sheet.dart:24-32` |
| D1 | Chỉ kiểm khi đã đăng nhập + chưa couple + không sửa + Setup là route trên cùng + không loading | PASS | `setup_screen.dart:85-96` |
| D2 | Không hiện sheet cho mã của chính mình (mã cá nhân + coupleCode) | PASS | `setup_screen.dart:103-107`; tầng 2 `couple_service.dart:353-355`. Hộp hệ thống vẫn có thể hiện vì phải đọc mới biết (PF13) |
| D3 | Mỗi mã hỏi 1 lần, đánh dấu TRƯỚC khi hiện sheet | PASS | `setup_screen.dart:108`; `invite_clipboard.dart:66,76-87` |
| D4 | iOS: chỉ đọc khi `detectPatterns` có URL VÀ `changeCount` mới; lưu `changeCount` trước khi đọc | PASS | `invite_clipboard.dart:49-60` |
| D5 | iOS resume không chồng 2 sheet; Android chỉ kiểm lúc mở Setup | PASS | `setup_screen.dart:54,62-80,86,94,97,133-135` |
| D6 | Regex: 7 ký tự, `notdearembeiu.com`, `dearembeiu.com.evil.com`, subdomain, `code=` trong fragment, `mycode=`, url-encoded → null; chữ thường → in hoa; tham số khác trước/sau `code` → có | PASS | `invite_clipboard.dart:28-39`; probe 25 chuỗi. Ngoại lệ: link lồng trong URL khác vẫn khớp (BUG-5) |
| D7 | Dán cả link hoặc cả tin nhắn mời vào ô mã → tách mã, hiện lại trong ô, ghép được | PASS | `setup_screen.dart:358-365`; ô mã không có maxLength/formatter `:1245-1252`; test "whole invite message" |
| D8 | Swift `InviteClipboardChannel`: API iOS 15 (target 15.0), trả kết quả trên main queue; thiếu kênh/lỗi → null | PASS | `AppDelegate.swift:57-80` (`DispatchQueue.main.async` `:75`); `invite_clipboard.dart:70-72` |
| E1 | Lịch +2h/+20h/+72h; 22:00–07:59 dời 08:30; mốc đã qua bỏ; couple 8 ngày → không gì | PASS | `reminder_service.dart:776-801` + 7 test + probe |
| E2 | Bỏ hẳn "đã qua hết thì now + 24h"; refresh đầu sau nâng cấp huỷ cả band rồi lập lại | PASS | `reminder_service.dart:807-833` (cancel `:816`) |
| E3 | `markInviteShared` ở MỌI nút Gửi/Sao chép/QR (Setup, Home, Profile) | PASS | `invite_action_buttons.dart:50,68,120`; `invite_qr_sheet.dart:26`; `home_screen.dart:2433,2446`. Dialog mã sau khi tạo couple không có nút chia sẻ |
| E4 | Band 1180–1189 (dùng 1180/1181/1182) không đè band nào | PASS | `reminder_service.dart:31-40,66-168`; push foreground dùng id ngẫu nhiên 31-bit `push_notification_service.dart:623-625` |
| E5 | DST/đổi múi giờ không vỡ; +20h/+72h là giờ trôi thật (lệch 1h đồng hồ khi qua DST); 08:30 dựng theo giờ địa phương | PASS | probe `TZ=America/New_York` |
| E6 | Đăng xuất / rời couple / xoá tài khoản khi đang chờ → huỷ nhắc mời | FAIL (BUG-2) | xem BUG-2 |
| F1 | Có mã: bấm App Store / Google Play / "Mở Dear Embeiu" → chép link dựng từ mã đã kiểm, ngay trong click, không `preventDefault` | PASS (code) · ⏳ máy thật | `docs/get.html:321-339` |
| F2 | Mã sai → không gắn handler, không chép, giữ luồng tự chuyển store | PASS | `docs/get.html:315-316,321,387-401` |
| F3 | Điện thoại có mã → chỉ nút store đúng nền tảng; `copyHint` → `copyHintDone`/`copyHintFail` | PASS | `docs/get.html:327-336,343-347` |
| F4 | XSS: mã chỉ vào `textContent`, `innerHTML` chỉ nhận chuỗi tĩnh | PASS | `docs/get.html:318,350` |
| F5 | Tương thích app ≤ 1.8.0 khi trang mới đã lên | FAIL nếu đẩy sớm (BUG-3) | xem BUG-3 |
| G1 | 19 key mới đủ vi + en; đổi `homeWaitingStep1Desc`, `guestCtaSignIn`; không ngoặc nhọn sai chỗ | PASS | `app_vi.arb:73,88-106,845-851,959`; `app_en.arb:73,91-119,998-1025,1480` |
| G2 | Văn phong: không cụm sáo rỗng, không "hai đứa", dấu kiểu mới (xoá, Huỷ) | PASS | grep diff ARB + `get.html` |
| H1 | Không log nội dung bộ nhớ tạm / mã mời; analytics không có mã; không lộ email trên UI | PASS | `invite_clipboard.dart` (không debugPrint); `setup_screen.dart:85-136`; `analytics_service.dart:277-280` |
| H2 | Entitlement `com.apple.developer.applesignin = [Default]`, cả 3 cấu hình build trỏ đúng file | PASS | `ios/Runner/Runner.entitlements`; `project.pbxproj:555,741,767` |

## Bug report

### BUG-1 — Huỷ sheet Apple khi xoá tài khoản thì lần "Tiếp tục với Apple" sau đó treo vĩnh viễn
- **Mức:** P2 (major, đường ít gặp, phải tắt app mới thoát)
- **Nơi:** `lib/services/auth_service.dart:664-665` (reauth) + `:331-335` (sign-in). Plugin `firebase_auth` 6.5.3 iOS: `FLTFirebaseAuthPlugin.m:2064` bật `isReauthenticatingWithApple`; `:495-511` (`didCompleteWithError`) không tắt lại; `:449-458` nhánh reauth gọi `[[FIRAuth.auth currentUser] reauthenticate…]`, currentUser nil sau khi đăng xuất nên completion không bao giờ chạy. Bản 6.7.0 (Swift) y hệt `FLTFirebaseAuthPlugin.swift:472-476`. UI khoá theo cờ: `apple_sign_in_button.dart:85,98`, `guest_counter_screen.dart:495,509`.
- **Expected:** Đăng nhập Apple bình thường → Setup/Home.
- **Actual (đọc code, chưa chạy máy):** `signInWithProvider` không trả về → `isAppleSigningIn` kẹt true → nút Apple quay mãi, "Đăng nhập bằng email"/"Đăng ký" bị khoá → kẹt ở landing tới khi kill app. Lần bấm Apple sau native báo `operation-not-allowed`.
- **Repro (iOS, Firebase):** (1) Đăng nhập tài khoản chỉ có Apple. (2) Cài đặt → Xoá tài khoản → Xoá vĩnh viễn → sheet Apple → Huỷ (hoặc Face ID lỗi). (3) Không tắt app: Cài đặt → Đăng xuất (hoặc bị máy khác đá ra do single-session). (4) Landing → "Tiếp tục với Apple" → xác nhận.
- **Gợi ý:** (a) bọc `signInWithProvider` bằng timeout dài (≥ 120s) để nhả cờ bận; (b) fork/patch plugin đặt lại `isReauthenticatingWithApple = NO` trong `didCompleteWithError` và báo upstream FlutterFire.

### BUG-2 — Nhắc mời vẫn nổ sau khi đăng xuất / rời không gian / xoá tài khoản
- **Mức:** P2 (có từ onboarding 2026-09-05; mốc +2h của PF10 làm dễ gặp hơn)
- **Nơi:** `session_resolver.dart:163,185,291` chỉ gọi `cancelDailyQuestionSchedule()` (`reminder_provider.dart:1497-1519`), không đụng band 1180–1189. Band chỉ bị huỷ trong `refreshInviteFollowUps(waiting:false)` (`reminder_provider.dart:1394-1405`), mà hàm này chỉ chạy từ Home có couple (`home_screen.dart:1049`). Mục #10 ở `onboarding/test.md` ghi "đã vá" nhưng chỉ phủ đường quay lại Home với couple đã active.
- **Expected:** Không còn couple đang chờ hoặc không còn đăng nhập → không còn nhắc "Gửi lời mời cho người ấy nhé" / "Người ấy chưa vào nè".
- **Actual:** Lịch 1180/1181/1182 vẫn nằm trong OS, nổ tối đa 3 lần trong 72 giờ, kể cả với tài khoản đã xoá.
- **Repro:** (1) Tạo couple lúc T (đang chờ). (2) Trong 2 giờ: Đăng xuất, hoặc Rời không gian, hoặc Xoá tài khoản. (3) Chờ T+2h / T+20h / T+72h.
- **Gợi ý:** huỷ band 1180–1189 ngay trong `cancelDailyQuestionSchedule()`, chỗ dọn chung mà cả 3 nhánh "không couple" đều đi qua.

### BUG-3 — Đẩy `docs/get.html` trước khi bản mới live: người dùng app ≤ 1.8.0 dán link vào ô mã và bị báo lỗi sai hướng
- **Mức:** P2 (điều kiện phát hành, không phải lỗi code của bản mới)
- **Nơi:** `docs/get.html:326-339` chép cả link. Ở 1.8.0: `couple_service.dart:348` chỉ `trim().toUpperCase()` → `user_service.dart:54/95` `doc('HTTPS://DEAREMBEIU.COM/GET?CODE=…')` → đường 4 đoạn → rules không khớp → `permission-denied` → `coupleJoinPermissionDenied` ("…nhờ người ấy tạo lại mã mời…").
- **Expected:** Người được mời luôn ghép được, hoặc ít nhất biết phải gõ 6 ký tự.
- **Actual:** Trang bảo đã chép sẵn, app cũ không tự hỏi, người dùng dán link → báo lỗi như thể mã hỏng.
- **Gợi ý:** chỉ đẩy get.html SAU khi bản mới live cả 2 store. Ghi vào checklist release.

### BUG-4 — Action "Đăng nhập" trên SnackBar PF6 ở landing có thể mở Login lần 2
- **Mức:** P3
- **Nơi:** `guest_counter_screen.dart:87-92` (`mounted` vẫn true vì landing nằm dưới Login); SnackBar sống qua đổi route `apple_sign_in_button.dart:66-77`.
- **Repro:** landing → Apple với Apple ID trùng email tài khoản mật khẩu → SnackBar PF6 → tự bấm "Đăng nhập bằng email" → trong 5 giây bấm "Đăng nhập" trên SnackBar → 2 màn Login chồng nhau.
- **Gợi ý:** `_openSignIn` kiểm thêm `ModalRoute.of(context)?.isCurrent`.

### BUG-5 — Regex nhận cả link mời lồng trong URL khác
- **Mức:** P3 (người dùng vẫn phải xác nhận và thấy rõ mã)
- **Nơi:** `invite_clipboard.dart:28-33`. Lookbehind chỉ chặn `[a-z0-9.-]`, nên `https://evil.com/?u=https://dearembeiu.com/get?code=XXXXXX` và `https://evil.com/dearembeiu.com/get?code=XXXXXX` đều ra mã.
- **Gợi ý:** chấp nhận, hoặc đòi đầu chuỗi/khoảng trắng trước scheme/host.

### BUG-6 — Lỗi xác nhận Apple khi xoá tài khoản hiện câu "Chưa đăng nhập được với Apple"
- **Mức:** P3 (copy)
- **Nơi:** `auth_service.dart:677-679` → `auth_provider.dart:433-434` → `settings_screen.dart:1066-1069`.
- **Expected:** câu nói về việc xoá (vd `deleteAccountFailed`). **Actual:** câu đăng nhập trong ngữ cảnh xoá.

### Ghi chú (không tính bug)
- Nửa đăng nhập: Apple xong ở Firebase Auth nhưng hồ sơ Firestore lỗi → app báo lỗi, Firebase vẫn giữ phiên, lần mở sau tự vào. Giống `signIn` email, không phải hồi quy.
- Profile dùng mã cá nhân, Home/Setup dùng coupleCode: có từ trước, cả 2 đều ghép được (C3).
- QR ở Setup trước khi tạo couple mang mã cá nhân chưa gắn không gian: quét và ghép ngay sẽ gặp `couplePartnerHasNoSpace` tới khi A tạo không gian. Đúng design §4a.
- Người ấy vào khi app A đang tắt: +20h/+72h vẫn nổ tới khi A mở Home (có từ onboarding). Có thể huỷ band trong handler push `partner_joined` ở isolate nền như đã làm với `bothAnswered`.
- Chính sách quyền riêng tư chưa nhắc "Đăng nhập với Apple" (không bắt buộc).

## Điều kiện phát hành (ngoài code)
1. PROD bật provider Apple cho `com.tony.dearembeiu` TRƯỚC khi lên store. Thiếu → mọi lượt bấm nút đen ở landing báo `appleSignInFailed`.
2. Nhập khoá Sign in with Apple (.p8 + Team ID + Key ID) vào Firebase DEV + PROD. Thiếu → thu hồi token lỗi im lặng, không đạt Guideline 5.1.1(v).
3. App ID `com.tony.dearembeiu` + `.dev` có capability Sign in with Apple.
4. Đẩy `docs/get.html` lên `phase3` chỉ SAU khi bản mới live cả 2 store (BUG-3).
5. PO cập nhật hợp đồng analytics: `invite_shared.method` thêm `qr`.

## Cần chạy trên máy thật (⏳)
1. R1 — iPhone thật, DEV: Apple người mới (chia sẻ tên) → Setup thẳng, không qua màn xác thực; hồ sơ có tên + mã mời. Lặp với "Ẩn email" + xoá tên → "Người dùng mới".
2. R2 — Quét QR bằng Camera → Safari mở đúng trang có mã → "Tải trên App Store" → App Store mở VÀ bộ nhớ tạm có link (dán thử vào Ghi chú); quay lại thấy `copyHintDone`.
3. R3 — Trang get trong trình duyệt nhúng Zalo/Messenger (iOS + Android): chép được không, nút store mở được không.
4. R4 — Cài mới (TestFlight) → intro → Apple → Setup: "Cho phép dán" → sheet → "Ghép đôi ngay" → overlay → Lottie → Home. Thử "Không cho phép" (không hỏi lại) và "Bỏ qua" (mã nằm sẵn ở tab Tham gia).
5. R5 — Bộ nhớ tạm chỉ có chữ → KHÔNG có hộp "Cho phép dán"; có link Shopee → hỏi đúng 1 lần, resume không hỏi lại.
6. R6 — `detectPatterns` với cả tin nhắn mời nhiều dòng copy từ Zalo.
7. R7 — PF12: app đã cài, đang ở Setup → mở link → "Mở Dear Embeiu" → app lên → hỏi mã.
8. R8 — Tái hiện BUG-1.
9. R9 — Xoá tài khoản Apple: câu báo trước → sheet → log `Apple token revoke failed` (chưa có .p8) → vẫn xoá → landing. Huỷ sheet → nhờ người ấy gửi tin → vẫn nhận push.
10. R10 — PF6 thật: tài khoản mật khẩu đã xác thực (gmail) trùng email Apple → SnackBar + điền sẵn email.
11. R11 — Tài khoản mật khẩu CHƯA xác thực, email @icloud.com, bấm Apple → vào tài khoản cũ hay báo PF6; còn kẹt cổng xác thực không.
12. R12 — Lời nhắc: tạo couple → pending có 1180 (+2h), 1181 (+20h), 1182 (+72h); bấm QR/Sao chép → mất 1180; tạo lúc 21:00 → 08:30; người ấy vào → hết; nâng cấp từ 1.8.0 có lịch "now+24h" cũ → hết sau lần vào Home đầu.
13. R13 — Android 13+: toast "đã dán" mỗi lần mở Setup; sheet chạy; cùng mã không hỏi lại.
14. R14 — Nút Apple so với nút hệ thống (logo thấp?), cỡ chữ lớn nhất, VoiceOver đọc "Tiếp tục với Apple".
15. R15 — Cụm 3 pill ở tile Profile máy 375pt xuống dòng, vùng chạm 48.
16. R16 — Sheet QR cỡ chữ lớn nhất trên máy cao 667pt cuộn tới "Xong"; camera đọc ở 20–40 cm.
17. R17 — (nghi) `changeCount` sau khi khởi động lại máy trùng số cũ → bỏ sót 1 link mời; chỉ cần nhập tay.

## Vòng 2 — soát bản vá `7b900d1` (2026-10-11)

- **Trạng thái:** PASS có điều kiện (code-level) — BUG-1/2/4/6 đã vá · BUG-5 vá nhưng sinh hồi quy P3 (BUG-7) · 0 P0/P1/P2 mới · BUG-3 vẫn là điều kiện phát hành.
- **Đã chạy:** `flutter test` 5 file liên quan 35/35 · `flutter analyze` 10 file của commit: 0 issue · probe 63 chuỗi gọi thẳng `InviteClipboard.parseInviteCode`, so với regex vòng 1.

| Bug | Kết quả | Bằng chứng |
|---|---|---|
| BUG-1 | ĐÃ VÁ · ⏳ R8/R9 | `auth_service.dart:672` dùng `signInWithProvider`. Plugin 6.5.3: chỉ `reauthenticateWithProviderApp` bật `isReauthenticatingWithApple` (`FLTFirebaseAuthPlugin.m:2064`); huỷ sheet ở nhánh sign-in reset `appleCompletion` + `appleSignInRequestInFlight` (`:495-500`); `signInWithAppleAuth` còn sót nhưng bị ghi đè mỗi lần gọi (`:1707`) → vô hại. Cùng Apple ID: SDK trả user cũ (`Auth.swift:2101`); listener auth-state chỉ bắn khi đổi uid (`Auth.swift:1353-1363`) → `_startSessionListener` không tưởng bị thu hồi. Khác uid: `signOut` + `session-gone` trước bước thu hồi (`auth_service.dart:674-679`). Settings xử lý `session-gone` ở dialog đầu (`settings_screen.dart:1062-1074`) và dialog xác minh lại (`:1158-1173`). `lib/` không còn gọi `reauthenticateWithProvider`. |
| BUG-6 | ĐÃ VÁ | `auth_service.dart:692-694` truyền `fallback: deleteAccountFailed`; đăng nhập Apple vẫn `appleSignInFailed` (`:373`). |
| BUG-2 | ĐÃ VÁ · ⏳ R12 | `reminder_provider.dart:1519-1525`. 3 nơi gọi đều ở `session_resolver.dart` (`:163`, `:185`, `:291`). Đăng xuất/rời/xoá/bị đá phiên đều qua authGate. Couple đang chờ bình thường đi nhánh `hasCoupleData` → không bị huỷ; signature null ⇒ Home sau lập lại. |
| BUG-4 | ĐÃ VÁ | `guest_counter_screen.dart:89` thêm `ModalRoute.of(context)?.isCurrent != true`. |
| BUG-5 | VÁ NHƯNG CÓ VẤN ĐỀ → BUG-7 | Ca lồng (query, path) nay ra null; ngoặc, nháy, xuống dòng, emoji, "tại: " vẫn ra mã. Link dính liền ký tự đứng trước bị loại (BUG-7). |

### BUG-7 — Regex mới bỏ cả link dính liền ký tự đứng trước (hồi quy do vá BUG-5)
- **Mức:** P3
- **Nơi:** `lib/services/invite_clipboard.dart:31` (lookbehind chặn cả `: , ; ! * _ ~ + @ - .`).
- **Expected:** `tại:https://dearembeiu.com/get?code=ABC234`, `em ơi,https://…`, `nhé.https://…`, `*https://…*` ra `ABC234` như regex vòng 1.
- **Actual:** 13/63 probe ra null. Tin mời app sinh ra (": " có khoảng trắng), link trang get chép và QR KHÔNG bị ảnh hưởng.
- **Gợi ý (đã probe 35/35):** tách nhánh — có scheme chỉ chặn `[a-z0-9/=?&#%]`, không scheme giữ class chặt.

### Ghi chú vòng 2 (không tính bug)
- Nhánh `session-gone` (máy đã đổi Apple ID, rất hiếm): thoát theo đường "phiên bị thu hồi", máy không được gỡ khỏi `users/{uid cũ}/devices` nên vẫn nhận push của tài khoản cũ; Firebase để lại 1 user Auth mồ côi cho Apple ID mới. Tuỳ chọn sau: `FirebaseMessaging.instance.deleteToken()` ở nhánh này + câu riêng.
- BUG-2, ca hẹp có từ trước: resolver chạy nền sau mốc 8 giây rơi vào `:291` khi Home đã hiện → band mời (và band câu hỏi, như cũ) bị huỷ; Home không gọi lại vì khoá `_lastReminderKey` tới khi đổi ngày/ảnh/ngôn ngữ.

### Cần máy thật (bổ sung)
- R8: tái hiện BUG-1 — giờ phải vào được Setup/Home.
- R9: xoá tài khoản Apple → sheet → cùng uid → log thu hồi → xoá xong; huỷ sheet → không xoá, vẫn nhận push.
- R12: thêm bước Đăng xuất / Rời không gian / Xoá tài khoản khi couple đang chờ → pending không còn 1180–1182.

## Chạy thật trên máy ảo (Lead, 2026-10-11 tối)

Môi trường: iPhone 17 simulator iOS 26.3 trong Device Hub (Xcode 27) + Android `Pixel_10` (Android 37, Google Play, 2 tài khoản Google). App bản debug → Firebase DEV. Tài khoản thử: `node scripts/dev-seed-pairing-funnel.js`. Thao tác iOS bằng `cliclick` + ảnh `simctl io screenshot`; Android bằng `adb` + `uiautomator dump`.

| ID | Kịch bản | Kết quả | Ghi chú |
|---|---|---|---|
| M1 | iOS landing: nút Apple đen + nút Google trắng (logo G 4 màu) + 1 dòng đồng ý chung | ✅ | Đúng design, chữ không tràn |
| M2 | iOS bấm Apple khi simulator chưa đăng nhập Apple ID → iOS hỏi mở Cài đặt → Đóng | ✅ bận đúng · ⚠️ hiện câu "Chưa đăng nhập được với Apple" | Mã `unknown` (1000), chấp nhận: cùng mã với lỗi thật, máy thật gần như luôn có iCloud |
| M3 | iOS bấm Google → hộp hệ thống "muốn sử dụng google.com" → Huỷ | ✅ im lặng | Hộp hiện tên "dear_embeiu" → đã sửa `CFBundleName` (`439ab91`), cần build lại để thấy "Dear Embeiu Dev" |
| M4 | iOS màn Đăng nhập: Apple + Google DƯỚI form, có "hoặc" | ✅ | |
| M5 | iOS đăng nhập email → Setup: cụm Sao chép / Chia sẻ / Mã QR một hàng | ✅ | |
| M6 | Sheet QR (iOS + Android): giải mã ảnh chụp bằng CIDetector | ✅ `https://dearembeiu.com/get?code=RBZU3P` | |
| M7 | Tạo couple (iOS) → Home thẻ chờ có mô tả nhắc QR + pill "Mã QR" | ✅ | |
| M8 | Android Chrome mở `get.html?code=5AJXAZ` (server nội bộ, `adb reverse`) → chỉ hiện nút Google Play + câu chép sẵn | ✅ | |
| M9 | Bấm "Get it on Google Play" → Play Store mở + hệ thống báo đã chép `https://dearembeiu.com/get?code=5AJXAZ` | ✅ | |
| M10 | Android app mới cài → đăng nhập → Setup tự hiện "Use the code from your invite? 5AJXAZ" (+ toast "pasted from your clipboard") | ✅ | |
| M11 | "Pair up now" → ghép đôi; iPhone người tạo tự chuyển sang couple active | ✅ | |
| M12 | Lịch nhắc mời (Android `dumpsys alarm`): tạo 20:38 → 08:30 hôm sau (dời giờ đêm) · 16:38 (+20h) · 20:38 ngày 14 (+72h) | ✅ | |
| M13 | Mở "QR code" ở thẻ chờ → mốc 08:30 bị huỷ, còn 2 mốc | ✅ | |
| M14 | PF19 app còn sống ở nền: người ấy vào (iPhone) → FCM tới Android (2 broadcast: alert + data-only) → band 1180–1189 hết | ✅ | |
| M15 | **PF19 app bị kill (không force-stop):** người ấy vào → Android tự mở process, `FLTFireBGExecutor` tạo background engine, `FlutterFirebaseMessagingBackgroundService started` → 3 mốc nhắc mời bị huỷ, không mở UI | ✅ | Join giả lập bằng Admin SDK (đúng chuyển đổi memberIds 1→2 + `active` mà CF lắng nghe) |
| M16 | iOS Setup khi bộ nhớ tạm trống → KHÔNG hiện hộp "Cho phép dán" | ✅ | PF13 nhánh âm |
| M17 | Android landing: chỉ "Continue with Google" (không Apple) + dòng đồng ý | ✅ | |
| M18 | Android Google → bảng "Choose an account … Dear Embeiu Dev" → Cancel | ✅ im lặng | |
| M19 | Android Google → chọn `tuanexness01` → consent → vào thẳng Setup (không màn xác thực email) | ✅ | User DEV: provider `google.com`, emailVerified, hồ sơ có mã mời `ASQD2L` (user cho phép cấp quyền qua remote control) |
| M20 | Đăng xuất → bấm Google lại → bảng chọn tài khoản hiện lại; chọn lại → vào đúng hồ sơ cũ (mã `ASQD2L`) | ✅ | |
| M21 | Màn Cài đặt cuộn tới Đăng xuất (Android) | ✅ | Trên iOS thao tác kéo giả lập chập chờn, đã xác nhận trang vẫn cuộn tới đáy — không phải lỗi app |
| M22 | Setup (chưa ghép đôi) → bánh răng → Cài đặt rút gọn (Tài khoản · Xoá tài khoản · Đăng xuất · phiên bản) | ✅ | Sau vá P1 `2356e7b` |
| M23 | Xoá tài khoản Google-only từ Cài đặt rút gọn → dialog (không câu Apple) → "Delete permanently" → về landing; Firebase DEV không còn user | ✅ | Dọn luôn user thử `tuanexness01` |
| M24 | iOS hộp "… muốn sử dụng google.com để đăng nhập" hiện **"Dear Embeiu Dev"** (trước là "dear_embeiu") | ✅ | Bản cài có `CFBundleName` = "Dear Embeiu Dev" + 2 URL scheme Google |

**Phát hiện khi chạy máy ảo:**
- **P1 (có từ trước) — ✅ ĐÃ VÁ `2356e7b`, kiểm M22–M23:** người đã đăng nhập nhưng chưa ghép đôi không có lối xoá tài khoản trong app (Cài đặt trống khi chưa có couple, Setup chỉ có Đăng xuất) — rủi ro App Review 5.1.1(v) và Google Play, tăng mạnh vì đăng ký Apple/Google chỉ 2 chạm.
- P3: tên "dear_embeiu" trong hộp đăng nhập Google của iOS → đã vá (`CFBundleName = $(APP_DISPLAY_NAME)`), kéo theo đổi tên file IPA → đã sửa script upload lấy `.ipa` mới nhất.

**Không thử được trên máy ảo (cần máy thật):** đăng nhập Apple tới cùng (simulator không có Apple ID), hộp "Cho phép dán" + gợi ý mã trên iOS (Xcode 27 `simctl pbcopy` và Safari đều không ghi được bộ nhớ tạm của simulator), push trên iOS (DEV chưa có APNs key), quét QR bằng camera, trang get trong trình duyệt nhúng Zalo/Messenger.

## Vòng 3 — đợt 2 (Google, PF18, PF19)

- **Trạng thái:** PASS có điều kiện (code-level, 2026-10-11) — 0 P0/P1/P2 · 3 P3 mới (BUG-8/9/10) · chặn phát hành: Google PROD + SHA-1 Android PROD + CF `notifyPartnerJoined` PROD.
- **Phạm vi:** diff `69f856b..83da599`: Google sign-in PF14–PF17, PF18, PF19, Podfile.lock, plist, l10n.
- **Đã chạy:** `flutter test` 261/261 · `flutter analyze` 14 file đợt 2: 0 issue · `node --check functions/index.js` OK · `plutil -lint` Info.plist + 2 GoogleService-Info OK. Đọc source: `google_sign_in` 7.2.0, `_android` 7.2.11, `_ios` 6.3.6, `firebase_auth` 6.5.3 + 6.7.0, FirebaseAuth 12.15 (Pods), AAR `credentials-play-services-auth` 1.6.0.

| ID | Mô tả | Kết quả |
|---|---|---|
| G1–G5 | `initialize` 1 lần; `authenticate` chỉ Android/iOS; idToken null → lỗi; huỷ → `social-canceled` im lặng; lỗi SDK/thiếu URL scheme → `googleSignInFailed`, chữ tiếng Anh chỉ vào log | PASS |
| G6 | Credential chỉ idToken an toàn ở 6.5.3 / 6.7.0 | PASS (code) · iOS cần 1 lượt Google thành công trên máy thật |
| G7–G8 | iOS `clientId` từ `iosClientId`; Android `default_web_client_id`: DEV đủ type 1 + 3; PROD chỉ type 3 | PASS (DEV) · chặn phát hành (PROD) |
| G9 | PF17: iOS ẩn khi thiếu CLIENT_ID; Android luôn hiện (không kiểm được lúc chạy) | PASS có điều kiện |
| G10–G16 | Cờ bận theo nhà cung cấp; hồ sơ dùng chung Apple; PF3; Google signOut nền khi đăng xuất; xoá Google-only (token 5s + disconnect); dialog không mật khẩu; logo/màu Google | PASS |
| G17 | R8 bản release giữ class Credential Manager (consumer rule trong AAR) | PASS (đọc AAR) · cần build AAB release |
| S1–S2 | Không còn `apple-canceled` hay tên cũ | PASS |
| P18-1..6 | Chỉ xoá user mồ côi khi `isNewUser`; best-effort; `apple-id-mismatch`/`session-gone`; Settings hiện câu riêng; `onError` stream sessionToken; token mới không ghi lại được cho A | PASS · P18-4 FAIL nhánh Apple ID mới (BUG-8) |
| P19-1..6 | CF `wakeClients`; handler nền + foreground huỷ band; bỏ chốt init an toàn với cả 4 nơi gọi; `isPartnerJoinedPush`; Android app bị kill vẫn huỷ (Lead chạy thật) | PASS |
| C1–C2 | URL scheme khớp; Podfile.lock GTMSessionFetcher 3.5.0 thoả mọi pod | PASS · smoke Storage/callable iOS |
| L1–L2 | 5 key mới đủ vi+en, xoá `appleConsentPrefix` sạch, văn phong | PASS |
| B1–B2 | Không log idToken/email/bộ nhớ tạm; không lộ credential | PASS |

**BUG-8 (P3)** — PF18 nhánh Apple ID mới tinh: `user.delete()` phát `null` → shell đẩy authGate trước khi Settings hiện SnackBar `deleteAccountAppleIdMismatch`. Gợi ý: lấy `ScaffoldMessenger` trước `await`. → đang vá.
**BUG-9 (P3, nghi)** — PF18 xoá user mồ côi nhưng không thu hồi quyền Apple của Apple ID lạ ⇒ lần cấp quyền đầu không xin email, Apple ID đó có thể đăng nhập Apple lỗi về sau. Gợi ý: revoke bằng `authorizationCode` của B trước `user.delete()`. → đang vá.
**BUG-10 (P3)** — câu PF6 giả định có mật khẩu → ✅ đã vá `439ab91` ("Đăng nhập bằng cách bạn đã dùng lần trước nhé").

**Ghi chú vòng 3:** máy Android không có Google Play Services vẫn thấy nút Google (bấm báo lỗi); tài khoản có cả Apple + Google xoá trên Android sẽ gọi nhầm sheet Apple (→ đang vá: ưu tiên Google trên Android); `getIdToken(true)` nhánh Apple thiếu timeout (→ đang vá); máy còn device doc cũ của tài khoản khác có thể huỷ nhầm band nhắc mời (rất hiếm, để sau); thiếu test tự động cho đường xoá Google-only + Google signOut.

**Cần máy thật (bổ sung):** RG1 Google iOS người mới/cũ · RG3 đăng xuất rồi chọn lại tài khoản (iOS) · RG4 xoá Google-only + trang "Ứng dụng bên thứ ba" · RG5 PF6 với gmail có/không mật khẩu · RG6 PF18 cần 2 Apple ID · RG7 PF19 iOS (cần APNs key DEV hoặc TestFlight) · RG8 smoke iOS sau khi hạ GTMSessionFetcher (đăng ảnh, callable, đăng nhập email).

## Nhật ký test
- [2026-10-11] [Tester] Nghiệm thu code-level `feature/pairing-funnel`@509e46f (diff 086f1e0..509e46f): luồng Apple (service/provider/widget/3 màn/Settings), plugin `firebase_auth` 6.5.3 + 6.7.0 iOS, rules `users/{uid}`, join bằng mã trong `couple_service`, bộ nhớ tạm ở Setup + kênh Swift, lịch nhắc mời, `get.html`, ARB. Chạy lại 4 file test liên quan 29/29; probe regex 25 chuỗi + lịch nhắc 11 mốc (gồm DST). Kết quả: PASS có điều kiện — 0 P0/P1, 3 P2 (BUG-1 treo Apple sau khi huỷ xoá, BUG-2 nhắc mời còn nổ sau đăng xuất/rời/xoá, BUG-3 thứ tự đẩy get.html), 3 P3; 17 case cần máy thật.
- [2026-10-11] [Tester] Vòng 2 soát `7b900d1`: BUG-1/2/4/6 đã vá (đọc plugin firebase_auth 6.5.3, FirebaseAuth 12.15 trong Pods), BUG-5 vá nhưng sinh BUG-7 (P3, regex bỏ link dính liền ký tự đứng trước). Test 5 file 35/35, analyze 10 file 0 issue, probe 63 chuỗi với hàm thật. PASS có điều kiện, chờ R8/R9/R12. (Lead dán hộ — agent Tester chỉ đọc.)
- [2026-10-11] [Lead] BUG-7 vá ở `49c8bba` (regex tách nhánh có/không scheme như Tester đề xuất, +1 test 5 ca); PO verify analyze 0 · 248/248. Không chạy Tester vòng 3 vì bản vá đúng nguyên văn regex Tester đã probe 35/35.
- [2026-10-11] [Lead] Chạy thật trên iPhone simulator + Android emulator: 21 kịch bản (M1–M21) — Google sign-in Android tới cùng, luồng get → bộ nhớ tạm → gợi ý mã → ghép đôi, lịch nhắc + huỷ mốc 2h, PF19 với app bị kill. Phát hiện P1 có từ trước: chưa ghép đôi thì không xoá được tài khoản.
- [2026-10-11] [Tester] Vòng 3 soát đợt 2 (`69f856b..83da599`): Google sign-in, PF18, PF19, Podfile.lock, plist, l10n. Test 261/261, analyze 0. PASS có điều kiện: 0 P0/P1/P2, 3 P3 (BUG-8/9/10). (Lead dán hộ — agent Tester chỉ đọc.)
