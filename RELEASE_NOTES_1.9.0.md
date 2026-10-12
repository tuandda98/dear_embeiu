# What's New — Dear Embeiu 1.9.0 (build 26)

> Copy vào **CẢ HAI**: App Store Connect → 1.9.0 → "What's New" · Google Play → "Có gì mới".
> ℹ️ 1.9.0 = **MINOR**: phễu ghép đôi (feature `pairing-funnel`) — đăng nhập Apple (iOS) + Google (cả 2 nền tảng), mã QR mời, gợi ý mã từ link đã chép, lịch nhắc mời mới. Backend đã sẵn trên PROD từ 2026-10-11 (provider Apple/Google, `notifyPartnerJoined`), đợt này KHÔNG deploy gì.
> ⚠️ CHỈ nêu thay đổi CÔNG KHAI.

## 🇻🇳 Tiếng Việt (primary) — ≤500 ký tự (giới hạn Play)
```
Rủ người ấy vào app dễ hơn 💌

• Đăng ký, đăng nhập bằng Google chỉ với một chạm. Trên iPhone có thêm Đăng nhập với Apple.
• Mã QR mời ghép đôi: người ấy quét bằng camera là tới trang tải app, có sẵn mã mời.
• Đã chép link mời thì mở app là có gợi ý điền mã. Dán cả link vào ô nhập mã cũng được.
• Lời nhắc mời người ấy gọn hơn: tối đa 3 lần trong tuần đầu, không nhắc lúc khuya.
• Màn đăng nhập gọn và dễ nhìn hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English — ≤500 ký tự
```
Easier to bring your partner in 💌

• Sign up or sign in with Google in one tap. iPhone also gets Sign in with Apple.
• Invite QR code: your partner scans it with the camera and lands on the download page with your code.
• Copied an invite link? Open the app and it offers to fill in the code. Pasting the whole link works too.
• Fewer invite reminders: at most 3 in the first week, never late at night.
• A cleaner sign-in screen.

Thanks for keeping your memories together with us 🌷
```

### Bản dán cho App Store (không emoji, gạch "-"; iPhone có cả Apple lẫn Google)
```
Rủ người ấy vào app dễ hơn

- Đăng ký, đăng nhập bằng Apple hoặc Google chỉ với một chạm.
- Mã QR mời ghép đôi: người ấy quét bằng camera là tới trang tải app, có sẵn mã mời.
- Đã chép link mời thì mở app là có gợi ý điền mã. Dán cả link vào ô nhập mã cũng được.
- Lời nhắc mời người ấy gọn hơn: tối đa 3 lần trong tuần đầu, không nhắc lúc khuya.
- Màn đăng nhập gọn và dễ nhìn hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm.
```

---

## Ghi chú nội bộ — 1.9.0 (build 26)
- Nội dung: `feature/pairing-funnel` (tách từ `release/1.8.0`): đăng nhập Apple (iOS, `signInWithProvider`) + Google (`google_sign_in` 7.x), xoá tài khoản thu hồi token Apple / ngắt Google, mã QR (`qr_flutter`), gợi ý mã từ bộ nhớ tạm ở Setup, lịch nhắc mời +2h/+20h/+72h (dừng sau 7 ngày, né 22:00–07:59), Cài đặt rút gọn cho người chưa ghép đôi, thẻ đăng nhập landing thiết kế lại, logo Apple chính thức (Apple Design Resources, đồng ý license 2026-10-12).
- Backend PROD: không deploy đợt này. Provider `apple.com` + `google.com` đã bật, SHA-1 Android PROD đã thêm, `notifyPartnerJoined` (wakeClients) đã deploy — đều 2026-10-11.
- ⏳ Khoá Sign in with Apple (.p8) chưa nhập vào Firebase DEV + PROD ⇒ thu hồi token khi xoá tài khoản Apple lỗi im lặng (tài khoản vẫn xoá). Không chặn duyệt, nhưng cần làm sớm.
- Feature tour: 1 entry `sinceBuild: 26` ("Rủ người ấy dễ hơn", icon `scan_barcode`).
- Khai báo store: App Privacy / An toàn dữ liệu không đổi (email + tên vốn đã khai cho đăng ký email). Chính sách quyền riêng tư thêm mục đăng nhập Apple/Google (Pages `0a194ac`).
- ⚠️ `docs/get.html` bản mới (chép link vào bộ nhớ tạm) CHỈ đẩy lên `phase3` sau khi 1.9.0 live cả 2 store: bản ≤1.8.0 không tách mã từ link.
- Mixed-version: người ấy còn 1.8.0 vẫn nhập mã tay như cũ; autoStoreForce ép cập nhật khi 1.9.0 live.
- Force-update: không nâng `minBuildNumber` (quyết định 2026-09-07).
