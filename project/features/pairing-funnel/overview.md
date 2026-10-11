# Pairing funnel — Bớt rơi rụng từ lúc đăng ký tới lúc ghép đôi

> File PO sở hữu. Designer/Dev/Tester đọc trước. Gộp 3 việc chạm vào `auth`, `invite-sharing`, `onboarding`.

- **Feature:** pairing-funnel
- **Ưu tiên:** P0 (North Star cần cả hai người trong couple)
- **Trạng thái:** 💻 Dev (2026-10-11) — Design xong
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
- **Đăng nhập với Google.** Android chỉ 5% người dùng, mà Google cần bật provider trên DEV, đăng ký SHA-1 cho 3 khoá ký, tải lại `google-services.json` + `GoogleService-Info.plist` cho cả DEV/PROD. Làm khi Apple cho kết quả hoặc khi Android tăng. (PROD đã bật sẵn provider google.com, DEV chưa.)
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
- ⏳ Khoá Sign in with Apple (.p8) trên Apple Developer → nhập Team ID + Key ID + private key vào Firebase (Apple provider → OAuth code flow) cho DEV + PROD. Thiếu bước này thì thu hồi token lỗi (vẫn xoá được tài khoản).
- ⏳ PROD: bật provider Apple cho `com.tony.dearembeiu` — đi cùng lệnh deploy prod của release.
- ⏳ Đẩy `docs/get.html` lên nhánh `phase3` (GitHub Pages).

## 6. Changelog
- [2026-10-11] [PO] Tạo feature từ phân tích phễu ghép đôi. Chốt PF1–PF10. Google + đề xuất 4 để sau. Bật provider Apple trên DEV.
- [2026-10-11] [PO] Gate Design PASS (đối chiếu key/hàm trên đĩa). Chốt PF11–PF13 cho 3 câu Designer hỏi. Chuyển sang Dev: 2 agent song song trên 2 worktree (Apple · QR + bộ nhớ tạm + lời nhắc).
