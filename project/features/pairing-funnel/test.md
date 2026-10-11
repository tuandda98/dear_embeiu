# 🧪 Test — pairing-funnel

> Tester sở hữu. CHỈ test, không sửa code. Nguồn: `overview.md` (PF1–PF13), `design.md`, `dev.md` (Phần A + B), diff `086f1e0..509e46f`.
> Agent Tester chỉ có quyền đọc nên Lead dán nguyên văn kết quả vào file này (2026-10-11).

- **Trạng thái test:** PASS có điều kiện (code-level, 2026-10-11) — 0 P0/P1 · 3 P2 · 3 P3 · 17 case ⏳ máy thật
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

## Nhật ký test
- [2026-10-11] [Tester] Nghiệm thu code-level `feature/pairing-funnel`@509e46f (diff 086f1e0..509e46f): luồng Apple (service/provider/widget/3 màn/Settings), plugin `firebase_auth` 6.5.3 + 6.7.0 iOS, rules `users/{uid}`, join bằng mã trong `couple_service`, bộ nhớ tạm ở Setup + kênh Swift, lịch nhắc mời, `get.html`, ARB. Chạy lại 4 file test liên quan 29/29; probe regex 25 chuỗi + lịch nhắc 11 mốc (gồm DST). Kết quả: PASS có điều kiện — 0 P0/P1, 3 P2 (BUG-1 treo Apple sau khi huỷ xoá, BUG-2 nhắc mời còn nổ sau đăng xuất/rời/xoá, BUG-3 thứ tự đẩy get.html), 3 P3; 17 case cần máy thật.
