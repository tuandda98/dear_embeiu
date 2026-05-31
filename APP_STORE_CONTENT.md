# App Store Connect — Nội dung & App Privacy (iOS)

> Bản cho **Apple App Store** (khác Play ở: subtitle 30 ký tự, keywords 100 ký tự, App Privacy "nutrition label", App Review notes). Nội dung mô tả kế thừa `PLAY_CONSOLE_CONTENT.md`.

## 1. App Information

| Field | Giá trị |
|-------|---------|
| **Name** (≤30) | `Dear Embeiu` |
| **Subtitle** (≤30) — VI | `Đếm ngày yêu, lưu ảnh kỷ niệm` (29) |
| **Subtitle** (≤30) — EN | `Love counter & shared memories` (30) |
| **Primary category** | Lifestyle |
| **Secondary category** | Social Networking |
| **Bundle ID** | `com.tony.dearembeiu` |
| **SKU** | `dearembeiu-ios-001` (tuỳ ý, nội bộ) |

## 2. Promotional text (≤170, đổi không cần review)
**VI:**
```
Không gian riêng của hai người: đếm ngày yêu, lưu ảnh kỷ niệm, tự đặt lời nhắc cho từng cột mốc & ngày đặc biệt của chúng mình.
```
**EN:**
```
Your private space for two: count your days together, keep shared photos, and set your own reminders for every milestone and special day.
```

## 3. Description (≤4000) — dùng bản VI từ PLAY (bổ sung reminder mới)
**VI:** (lấy nguyên Full description trong `PLAY_CONSOLE_CONTENT.md`, thêm 1 mục:)
```
🔔 Lời nhắc theo ý hai bạn
Tự bật/tắt nhắc cho từng cột mốc (100 ngày, 1000 ngày, nửa năm, kỷ niệm năm…) và tạo lời nhắc riêng cho sinh nhật, ngày đặc biệt — mỗi mốc đặt giờ tuỳ ý.
```
**EN:** (cần bản dịch EN đầy đủ — TODO nếu submit store EN; tối thiểu submit locale VI trước cho nhanh.)

## 4. Keywords (≤100 ký tự, phẩy ngăn, KHÔNG khoảng trắng thừa)
```
cặp đôi,yêu nhau,kỷ niệm,đếm ngày yêu,couple,anniversary,love,ảnh đôi,nhật ký,memories,monthsary
```
*(Đếm lại ≤100 trước khi dán. Không lặp từ trong Name/Subtitle để khỏi phí.)*

## 5. URLs
| Mục | URL |
|-----|-----|
| Support URL (bắt buộc) | `https://<project-id>.web.app/` hoặc trang GitHub Pages |
| Marketing URL (tuỳ chọn) | — |
| Privacy Policy URL (bắt buộc) | `https://<project-id>.web.app/privacy-policy.html` |

## 6. Age Rating (questionnaire)
- App có **User Generated Content** (ảnh chung) nhưng **riêng tư, chỉ 2 thành viên ghép cặp** — không feed công khai.
- Trả lời trung thực: không bạo lực/người lớn/cờ bạc. UGC riêng tư.
- Kết quả dự kiến: **12+** (do chia sẻ ảnh người dùng) — chấp nhận. Nếu muốn 4+, cân nhắc câu trả lời UGC + thêm report/block (xem mục 8).

## 7. App Privacy ("nutrition label") — App Store Connect > App Privacy
> Khai theo loại dữ liệu Apple. Tất cả **Linked to user**, **KHÔNG dùng để Tracking**.

| Apple data type | Thu? | Mục đích | Linked | Tracking |
|---|---|---|---|---|
| Contact Info — Email | ✅ | App Functionality (tài khoản) | Yes | No |
| Contact Info — Name | ✅ | App Functionality | Yes | No |
| User Content — Photos | ✅ | App Functionality (gallery couple) | Yes | No |
| User Content — Other (caption) | ✅ | App Functionality | Yes | No |
| Identifiers — Device ID (FCM token) | ✅ | App Functionality (push) | Yes | No |
| Diagnostics — Crash Data | ✅ | App Functionality (Crashlytics) | Yes | No |
| Usage Data — Product Interaction | ✅ | App Functionality | Yes | No |

- Third-party: **Firebase (Google)** — Auth/Firestore/Storage/Messaging/Crashlytics. Mã hoá khi truyền (TLS).
- **Account deletion**: ✅ in-app (Settings → Tài khoản → Xoá tài khoản) — đáp ứng Guideline 5.1.1(v).

## 8. App Review notes (QUAN TRỌNG — tránh reject vì reviewer không test được)
```
App dành cho cặp đôi, ghép cặp qua MÃ MỜI (invite code). Để test đầy đủ tính năng chung (gallery, push) cần 2 tài khoản ghép cặp.

Tài khoản demo (đã ghép sẵn 1 couple để review nhanh):
- Email: <demo1@example.com>  /  Mật khẩu: <…>
- (Tuỳ chọn) Tài khoản 2: <demo2@example.com> / <…>  — đã là partner của tài khoản 1.

Hoặc reviewer tự tạo: Đăng ký A → Setup tạo couple → nhận mã 6 ký tự → Đăng ký B → nhập mã để ghép.

Quyền riêng tư: dữ liệu chỉ chia sẻ giữa 2 thành viên đã ghép cặp, không công khai. Có chức năng xoá tài khoản trong app (Settings → Tài khoản → Xoá tài khoản).
```
> ⚠️ **Phải tạo tài khoản demo thật** trên Firebase (đã ghép couple + có vài ảnh) và điền vào đây — reviewer Apple thường reject nếu không vào được tính năng chính.

## 9. Screenshots (bắt buộc)
- **iPhone 6.7"** (1290×2796) — BẮT BUỘC, ≥3 ảnh (gợi ý: Home đếm ngày · Gallery · Lời nhắc/Settings · Profile couple).
- **iPad 12.9"** — chỉ cần NẾU giữ hỗ trợ iPad (Info.plist đang bật iPad). Cân nhắc đặt iPhone-only để bỏ.

## 10. Build & submit
1. Xcode → Runner → Signing → chọn **Team** (Automatic) — tạo distribution cert + provisioning.
2. Đảm bảo **APNs Auth Key (.p8)** đã upload vào Firebase Console (cho FCM push).
3. `flutter build ipa --release` → file `.ipa` ở `build/ios/ipa/`.
4. Upload qua **Transporter** (hoặc Xcode Organizer) → TestFlight.
5. Test qua TestFlight trên máy thật (đặc biệt: ghép cặp, đăng ảnh + push, reminders/settings, xoá tài khoản).
6. App Store Connect → điền metadata (mục 1–9) → chọn build → **Submit for Review**.

## 11. Checklist trước Submit
- [ ] Set Team ký số trong Xcode (DEVELOPMENT_TEAM hiện đang TRỐNG)
- [ ] APNs key trong Firebase (push production)
- [ ] Tài khoản demo đã ghép couple + điền vào Review notes
- [ ] Quyết định iPad hay iPhone-only
- [ ] Screenshots 6.7" (+ iPad nếu giữ)
- [ ] Privacy Policy URL host + điền
- [ ] App Privacy nutrition label (mục 7)
- [ ] Age rating questionnaire
- [ ] `flutter build ipa --release` upload → TestFlight test máy thật
- [ ] (Khuyến nghị) thêm report/block ảnh nếu muốn giảm rủi ro UGC 1.2
