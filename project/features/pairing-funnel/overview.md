# Pairing funnel — Bớt rơi rụng từ lúc đăng ký tới lúc ghép đôi

> File PO sở hữu. Designer/Dev/Tester đọc trước. Gộp 3 việc chạm vào `auth`, `invite-sharing`, `onboarding`.

- **Feature:** pairing-funnel
- **Ưu tiên:** P0 (North Star cần cả hai người trong couple)
- **Trạng thái:** 🧪 Test (2026-10-11) — code đợt 1 + đợt 2 xong, 3 vòng Tester (PASS có điều kiện, đã vá hết P1–P3 tìm được), chạy máy ảo 24 kịch bản; PROD: Apple bật, SHA-1 Android + `google-services.json` PROD, `notifyPartnerJoined` đã deploy. Còn: khoá .p8 (cần user đăng nhập Apple Developer), thử máy thật, release
- **Nhánh:** `feature/pairing-funnel` (tách từ `release/1.8.0`@086f1e0)
- **Liên quan:** [auth](../auth/overview.md) (Đợt 2) · [invite-sharing](../invite-sharing/overview.md) (Phase 2 QR) · [onboarding](../onboarding/overview.md) (nhắc lại mời)

## 1. Dữ liệu (PROD, phân tích 2026-10-11)

- **36% người đăng ký kẹt ở xác thực email.** 48/111 người chưa từng vào couple nào, 40 người trong số đó chưa bấm link xác thực. Người được mời cũng phải qua cửa này.
- **Ghép được thì ghép ngay trong ngày.** 13 cặp có người ấy đăng ký sau khi cặp được tạo: 7 vào trong giờ đầu, 4 trong 24 giờ, 2 trong tuần đầu, sau 7 ngày không ai. Tức là hai người đang ngồi cạnh nhau hoặc đang nhắn tin.
- **Cặp đang chờ phần lớn đã nguội.** 19/31 cặp chờ hơn 30 ngày, chỉ 8 người tạo còn mở app tuần qua. Nhắc 24h/72h hiện có không kéo lại được.
- Không có cặp nào mà hai người mỗi người tự tạo một không gian riêng.
- 95% người dùng ở iPhone.

## 2. Phạm vi

**Trong (làm đợt này):**
1. **Đăng nhập với Apple** (chỉ iOS): nút ở landing, màn Đăng nhập, màn Đăng ký. Không cần mật khẩu, không cần xác thực email. Xoá tài khoản thu hồi token Apple.
2. **Ghép đôi tại chỗ:**
   - Mã QR ở mọi chỗ đang hiện mã mời (Setup, thẻ chờ ở Home, Profile). Người ấy quét bằng camera là tới trang tải app.
   - Trang `dearembeiu.com/get` chép link mời vào bộ nhớ tạm khi người ấy bấm nút tải. Mở app, tới màn Setup, app hỏi "Nhập mã ABC123 từ lời mời?".
3. **Dồn lời nhắc mời vào 24 giờ đầu:** 2 giờ sau khi tạo (chỉ khi chưa gửi mã), lần nữa trước mốc 24 giờ, giữ mốc 72 giờ, sau 7 ngày thôi nhắc.

**Ngoài (để sau):**
- ~~Đăng nhập với Google~~ → đưa vào đợt 2 (PF14–PF17) theo yêu cầu user 2026-10-11.
- **Apple trên Android** (cần Services ID + web flow).
- Đề xuất 4 "trả lời trước câu hỏi trong lúc chờ": để sau khi 1–3 có số liệu.
- Tự ghép đôi bằng universal link (`invite-sharing` Phase 3).

## 3. Quyết định đã chốt

- **PF1 — Chỉ Apple, chỉ iOS.** Nút Apple ẩn trên Android và khi Firebase chưa sẵn sàng (`isUsingFirebase == false`). Dùng `FirebaseAuth.signInWithProvider(AppleAuthProvider()..addScope('email')..addScope('name'))` có sẵn trong `firebase_auth` 6.7 (iOS chạy native `ASAuthorizationController`), KHÔNG thêm package `sign_in_with_apple`.
- **PF2 — Đặt nút ở 3 chỗ:** thẻ CTA của landing (`guest_counter_screen`), màn Đăng nhập, màn Đăng ký. Kiểu nút theo HIG của Apple: nền đen, logo Apple, chữ "Tiếp tục với Apple" / "Continue with Apple", bo pill cao 52 như nút chính. Dưới nút có 1 dòng đồng ý ngầm: "Tiếp tục nghĩa là bạn đồng ý Điều khoản và Chính sách quyền riêng tư" (link). Màn Đăng ký vẫn giữ checkbox cho đường email.
- **PF3 — Tài khoản Apple không qua cổng xác thực email.** `requiresEmailVerification` trả false khi user không có provider `password` (đừng chỉ dựa vào `emailVerified`).
- **PF4 — Tên hiển thị.** Lấy từ tên Apple trả về lần đầu (Firebase tự gán `displayName`). Không có tên: dùng phần trước @ của email nếu không phải email ẩn `@privaterelay.appleid.com`, còn lại dùng `defaultDisplayName`. Rules bắt buộc `displayName` và `email` không rỗng, email không đổi được.
- **PF5 — Xoá tài khoản Apple:** đăng nhập lại bằng Apple (`reauthenticateWithProvider`) để lấy `authorizationCode` mới, gọi `revokeTokenWithAuthorizationCode`, rồi mới gọi callable `deleteAccount`. Người dùng huỷ sheet Apple thì dừng, không xoá. Thu hồi lỗi (chưa cấu hình khoá trên Firebase) thì ghi log và vẫn xoá. Nhánh `requires-recent-login` của tài khoản Apple không hỏi mật khẩu (họ không có), thay bằng đăng nhập lại Apple.
- **PF6 — Email đã có tài khoản mật khẩu:** lỗi `account-exists-with-different-credential` hiện câu "Email này đã có tài khoản. Đăng nhập bằng mật khẩu nhé." Không làm luồng nối tài khoản.
- **PF7 — QR chứa đúng link mời** `https://dearembeiu.com/get?code=XXXXXX` (cùng link trong tin nhắn mời). Mở từ một nút "Mã QR" cạnh Sao chép/Chia sẻ (`InviteActionButtons`) và ở thẻ chờ Home. Hiện trong bottom sheet: QR lớn, mã chữ bên dưới, câu "Đưa người ấy quét bằng camera".
- **PF8 — Trang get chép link mời khi bấm nút tải.** Chép cả link (không chỉ mã) để app phân biệt được với chuỗi 6 ký tự khác như mã OTP. Chép ngay trong sự kiện bấm, không chặn điều hướng sang store. Câu hướng dẫn trên trang đổi thành "Mã đã được chép sẵn, mở app là có".
- **PF9 — App chỉ đọc bộ nhớ tạm ở màn Setup** (đã đăng nhập, chưa có couple, không phải chế độ sửa), mỗi mã hỏi đúng một lần (nhớ trong Hive). Trên iOS, đọc bộ nhớ tạm làm hiện hộp "Cho phép dán", nên trước đó hỏi native `UIPasteboard.detectPatterns(.probableWebURL)` (không hiện hộp); không có URL thì thôi. Android: `Clipboard.hasStrings()`. Khớp regex link `dearembeiu.com/get?…code=XXXXXX`, bỏ qua mã của chính mình. Người dùng đồng ý thì chuyển tab Nhập mã, điền mã và ghép đôi luôn.
- **PF10 — Lịch nhắc mời mới** (local, band 1180–1189 giữ nguyên): +2 giờ (chỉ khi chưa bấm Gửi/Sao chép/QR), +20 giờ, +72 giờ. Không có mốc nào sau 7 ngày, bỏ luôn cơ chế "đã qua hết thì nhắc lại sau 24 giờ" (đang nhắc mãi). Mốc rơi vào 22:00–08:00 thì dời sang 08:30. Bấm Gửi/Sao chép/QR thì huỷ ngay mốc 2 giờ.

**Chốt sau Design (PO gate 2026-10-11):**
- **PF11 — Dòng đồng ý chỉ link Chính sách bảo mật.** App chưa có trang Điều khoản; checkbox màn Đăng ký cũng chỉ dẫn tới chính sách. `AppUrls.privacyPolicy` đổi sang `https://dearembeiu.com/privacy-policy.html` (khớp link đã khai trên 2 store từ 1.8.0).
- **PF12 — Người đã cài app sẵn:** nút "Mở Dear Embeiu" trên trang get cũng chép link mời. Trên iOS, Setup kiểm tra lại bộ nhớ tạm mỗi lần app quay lại foreground (đã có `changeCount` chặn hỏi lặp). Android chỉ kiểm khi mở Setup, vì Android không có `changeCount` và mỗi lần đọc đều hiện toast.
- **PF13 — Chấp nhận** hộp "Cho phép dán" hiện khi bộ nhớ tạm có link bất kỳ (chỉ ở Setup, mỗi nội dung một lần). Thêm một sheet hỏi trước sẽ làm người được mời tốn thêm 1 chạm.
- Nhận các lựa chọn của Designer: Apple nằm **dưới** form ở màn Đăng nhập (người cũ đều dùng email), nút hồng ở landing đổi nhãn "Đăng nhập bằng email", pill mời dựng lại cho vùng chạm 48 và chữ navy.

**Đợt 2 (user yêu cầu 2026-10-11 tối: "làm luôn login bằng gg, dùng máy ảo để test, sửa 2 lỗi"):**
- **PF14 — Đăng nhập với Google, cả 2 nền tảng.** iOS: Apple (trên) + Google (dưới); Android: chỉ Google. Package chính thức `google_sign_in` (Android dùng Credential Manager, iOS dùng GoogleSignIn SDK) → `GoogleAuthProvider.credential(idToken)` → `signInWithCredential`. Cùng cụm nút với Apple, một dòng đồng ý chung "Khi tiếp tục, bạn đồng ý với Chính sách bảo mật."
- **PF15 — Nút Google theo branding của Google:** nền trắng, viền 1px #747775, logo "G" 4 màu chính thức (vẽ bằng `CustomPainter` từ path SVG chính thức, không thêm package/ảnh), chữ "Tiếp tục với Google" / "Continue with Google" màu #1F1F1F, cao 52 bo pill như nút Apple; đang chạy thì spinner, các nút khác khoá.
- **PF16 — Luồng tài khoản như Apple:** tạo hồ sơ khi chưa có, bỏ cổng xác thực email (đã có luật PF3), analytics `method: google`, trùng email tài khoản mật khẩu → câu PF6. Đăng xuất gọi luôn `GoogleSignIn.signOut()` để lần sau còn chọn tài khoản khác. Xoá tài khoản Google-only: không cần sheet, `getIdToken(true)` trước callable; `requires-recent-login` → dialog không ô mật khẩu (thử lại 1 lần); xoá xong gọi `disconnect()` (lỗi bỏ qua).
- **PF17 — Chỉ hiện nút Google khi đủ cấu hình:** iOS cần `CLIENT_ID` trong GoogleService-Info.plist (`Firebase.app().options.iosClientId`); Android cần OAuth client trong google-services.json. DEV đã đủ (bật Google + SHA-1 debug 2026-10-11). PROD: iOS đã có client; Android còn thiếu SHA-1 khoá upload + khoá ký của Play → bước release.
- **PF18 — Sửa lỗi đổi Apple ID lúc xoá tài khoản:** nhánh uid khác → xoá FCM token của máy (`FirebaseMessaging.deleteToken()`) để push của tài khoản cũ thôi tới máy này; nếu Apple ID kia vừa tạo user Firebase mới (`isNewUser`) thì xoá user mồ côi đó trước khi đăng xuất (KHÔNG xoá nếu là tài khoản có sẵn); hiện câu riêng "Apple ID trên máy này khác tài khoản đang xoá…".
- **PF19 — Sửa lỗi người ấy vào lúc app tắt:** CF `notifyPartnerJoined` gửi kèm `wakeClients` (iOS content-available + Android data-only); handler nền của app nhận `type: partner_joined` thì huỷ dải nhắc mời 1180–1189. Deploy CF lên DEV; PROD đi cùng release.

## 4. Acceptance criteria

**Apple**
- [ ] iOS: landing, Đăng nhập, Đăng ký có nút "Tiếp tục với Apple"; Android không có.
- [ ] Người mới bấm Apple → hồ sơ `users/{uid}` được tạo (có mã mời) → vào thẳng Setup, không qua màn xác thực email.
- [ ] Người cũ đã dùng Apple bấm lại → vào Home nếu đã có couple.
- [ ] Huỷ sheet Apple → ở lại màn cũ, không báo lỗi đỏ.
- [ ] Email trùng tài khoản mật khẩu → câu PF6.
- [ ] Xoá tài khoản Apple → hiện sheet Apple xác nhận → thu hồi token → xoá xong về landing. Huỷ sheet → không xoá.
- [ ] Đường email/mật khẩu cũ không đổi hành vi (đăng ký vẫn phải xác thực email).

**Ghép đôi tại chỗ**
- [ ] Nút "Mã QR" có ở Setup, thẻ chờ Home, Profile (chỉ khi mã còn dùng được); quét bằng camera iPhone mở đúng trang get có mã.
- [ ] Trang get: bấm "Tải trên App Store/Google Play" → bộ nhớ tạm có link mời; điều hướng sang store vẫn chạy.
- [ ] Setup: bộ nhớ tạm có link mời của người khác → hỏi 1 lần → đồng ý thì ghép đôi; từ chối thì không hỏi lại mã đó.
- [ ] iOS không hiện hộp "Cho phép dán" khi bộ nhớ tạm không có URL.
- [ ] Mã của chính mình trong bộ nhớ tạm → không hỏi.

**Lời nhắc**
- [ ] Tạo couple lúc 14:00 thứ Hai, chưa gửi mã → có nhắc 16:00 thứ Hai, 10:00 thứ Ba, 14:00 thứ Năm.
- [ ] Bấm Gửi/Sao chép/QR trước 16:00 → không còn nhắc 16:00.
- [ ] Couple tạo 8 ngày trước → không còn nhắc nào (kể cả khi mở app).
- [ ] Mốc rơi vào đêm → dời 08:30. Người ấy vào → huỷ hết.

**Chung**
- [ ] `flutter analyze` 0 issue, `flutter test` pass, chuỗi mới đủ vi + en.

## 5. Việc ngoài code (cần làm tay / chờ lệnh)

- ✅ DEV: đã bật provider Apple cho `com.tony.dearembeiu.dev` qua Identity Toolkit API (2026-10-11).
- ⏳ App ID `com.tony.dearembeiu` + `.dev`: capability Sign in with Apple (Xcode tự bật khi archive có `-allowProvisioningUpdates` và entitlement mới, giống HealthKit ở 1.8.0).
- ⏳ Khoá Sign in with Apple (.p8) trên Apple Developer → nhập Team ID + Key ID + private key vào Firebase (Apple provider → OAuth code flow) cho DEV + PROD. Thiếu bước này thì thu hồi token lỗi (vẫn xoá được tài khoản). **2026-10-11: dừng ở bước đăng nhập Apple Developer — user cần tự đăng nhập trong Chrome (Claude không nhập mật khẩu); xong báo để Claude tạo khoá + nhập Firebase.**
- ✅ PROD: bật provider Apple cho `com.tony.dearembeiu` (2026-10-11, user cho phép làm trước release).
- ⏳ Đẩy `docs/get.html` lên nhánh `phase3` (GitHub Pages) — **CHỈ SAU KHI bản app mới (có tách mã từ link) đã live cả 2 store.** Lý do: trang mới chép cả link `https://dearembeiu.com/get?code=…` vào bộ nhớ tạm khi bấm tải. Ai cài từ store trong lúc store còn phát bản 1.8.0 sẽ nhận bản cũ; bản cũ không tách mã từ link, nên dán vào ô mã sẽ báo sai mã. Đẩy sớm là làm hỏng đúng luồng đang muốn sửa.

## 6. Changelog
- [2026-10-11] [PO] Tạo feature từ phân tích phễu ghép đôi. Chốt PF1–PF10. Google + đề xuất 4 để sau. Bật provider Apple trên DEV.
- [2026-10-11] [PO] Gate Design PASS (đối chiếu key/hàm trên đĩa). Chốt PF11–PF13 cho 3 câu Designer hỏi. Chuyển sang Dev: 2 agent song song trên 2 worktree (Apple · QR + bộ nhớ tạm + lời nhắc).
- [2026-10-11] [PO] Gộp Phần A (Apple) + Phần B (QR, bộ nhớ tạm, nhắc mời) — analyze 0, 241/241. Build iOS thiết bị `--no-codesign` OK (simulator lỗi môi trường Xcode 27). Tester vòng 1: PASS có điều kiện, 3 P2 + 3 P3. Dev-fix `7b900d1` vá BUG-1 (plugin `firebase_auth` kẹt cờ reauth ⇒ xác nhận xoá dùng `signInWithProvider` + so uid), BUG-2 (huỷ nhắc mời khi đăng xuất/rời/xoá), BUG-4/5/6; BUG-3 là thứ tự deploy `get.html` (ghi vào checklist release). PO verify: analyze 0, 247/247.
- [2026-10-11] [PO] Tester vòng 2: BUG-1/2/4/6 đã vá; BUG-5 sinh BUG-7 (regex bỏ link dính liền ký tự đứng trước) → vá `49c8bba` theo regex Tester đã thử. PO verify: analyze 0, 248/248. CHƯA Done: còn 17 case máy thật (đăng nhập Apple, quét QR, hộp "Cho phép dán", lịch nhắc) + điều kiện release. Nợ: máy đổi Apple ID giữa lúc xoá vẫn nhận push tài khoản cũ (rất hiếm); huỷ nhắc mời khi `partner_joined` lúc app tắt; Google sign-in; đề xuất 4.
- [2026-10-11] [PO] Đợt 2 theo yêu cầu user: Google sign-in (PF14–PF17) + sửa 2 lỗi hiếm (PF18–PF19) + chạy thử trên máy ảo. Đã bật Google trên Firebase DEV (Console), thêm SHA-1 khoá debug cho 2 app Android DEV (API), tải lại 5 file cấu hình (DEV đủ client iOS/Android; PROD thêm client iOS, Android PROD chờ SHA-1 lúc release).
- [2026-10-11] [PO] Chạy thật trên máy ảo (24 kịch bản, `test.md` M1–M24): Google sign-in Android tới cùng, get → bộ nhớ tạm → gợi ý mã → ghép đôi, lịch nhắc + huỷ mốc 2h, PF19 với app bị kill, xoá tài khoản Google. Phát hiện + vá P1 có từ trước: chưa ghép đôi thì không xoá được tài khoản (Setup thêm bánh răng → Cài đặt rút gọn, `2356e7b`) — rủi ro App Review 5.1.1(v) vì đăng ký Apple/Google chỉ 2 chạm. Vá thêm `CFBundleName` (hộp Google hiện đúng tên app) + câu PF6 trung tính + script upload IPA lấy file mới nhất.
- [2026-10-11] [PO] Tester vòng 3 (đợt 2): PASS có điều kiện, 3 P3 → vá hết (`439ab91` câu PF6; `604e8c4` BUG-8 SnackBar đổi Apple ID, BUG-9 thu hồi quyền Apple ID lạ, Android ưu tiên Google khi tài khoản có cả 2, timeout làm mới token, phông tab Setup). PO verify analyze 0 · 266/266. Theo lệnh user: PROD bật Apple, thêm SHA-1 khoá upload + khoá ký Play cho Android (Google sign-in) và tải lại `google-services.json`, deploy `notifyPartnerJoined` — vết ở `.firebase-deploy-log/HISTORY.md`. Đánh đổi đã biết: tài khoản nối cả Apple + Google xoá trên Android thì không thu hồi được quyền Apple (Firebase vẫn xoá đủ).
