# 🍏 Hướng dẫn submit App Store — cầm tay chỉ việc

> Làm theo ĐÚNG THỨ TỰ (mỗi bước phụ thuộc bước trước). Đánh dấu [x] khi xong.
> Bundle ID: `com.tony.dearembeiu` · Firebase project: `tonyembeiu` · App: Dear Embeiu.
> Lệnh terminal: gõ `! <lệnh>` ngay trong phiên Claude để chạy + thấy output ở đây (vd các lệnh đăng nhập).

---

## BƯỚC 0 — Commit code (làm trước cùng)
- [ ] Các thay đổi mới (iPhone-only + photo-report + docs) đang uncommitted. Commit:
```
git add -A && git commit -m "feat: iPhone-only + photo report (UGC) + App Store docs"
```
(Hoặc nhờ Claude commit.)

---

## BƯỚC 1 — Apple Developer Program ($99/năm) ⏳ làm SỚM (duyệt 24–48h)
1. Vào https://developer.apple.com/programs/ → **Enroll**.
2. Đăng nhập Apple ID (nên là Apple ID bạn sẽ dùng lâu dài cho app).
3. Chọn **Individual** (cá nhân — nhanh, không cần giấy tờ DUNS) trừ khi muốn đứng tên công ty.
4. Trả phí $99 → chờ Apple duyệt (email xác nhận).
- ⚠️ Mọi bước ký số/upload bên dưới CẦN bước này xong trước.
- [ ] Đã có Developer account active.

---

## BƯỚC 2 — Ký số trong Xcode (Team + Push capability)
1. Mở **workspace** (KHÔNG phải .xcodeproj — app dùng CocoaPods):
```
open ios/Runner.xcworkspace
```
2. Khung trái: chọn project **Runner** → target **Runner** → tab **Signing & Capabilities**.
3. Tick **Automatically manage signing**.
4. **Team**: chọn team Apple Developer (vừa enroll). Xcode sẽ tự tạo App ID + provisioning profile cho `com.tony.dearembeiu`.
5. Kiểm có capability **Push Notifications** trong danh sách (app đã có `Runner.entitlements` với `aps-environment`). Nếu chưa thấy → **+ Capability** → thêm **Push Notifications**.
6. (Nếu báo lỗi bundle id đã tồn tại → đổi nhẹ hoặc dùng đúng id đã đăng ký.)
- [ ] Signing xanh (no error), Team đã chọn.

---

## BƯỚC 3 — APNs key cho push (FCM partner-photo)
**3a. Tạo key ở Apple:**
1. https://developer.apple.com/account → **Certificates, IDs & Profiles** → **Keys** → nút **+**.
2. Đặt tên (vd "Dear Embeiu APNs") → tick **Apple Push Notifications service (APNs)** → Continue → Register.
3. **Download .p8** (⚠️ chỉ tải được 1 LẦN — giữ kỹ). Ghi lại **Key ID** (10 ký tự). Ghi **Team ID** (góc trên phải account, 10 ký tự).

**3b. Nạp vào Firebase:**
4. https://console.firebase.google.com → project **tonyembeiu** → ⚙️ **Project settings** → tab **Cloud Messaging**.
5. Mục **Apple app configuration** → **APNs Authentication Key** → **Upload** → chọn file .p8 + nhập **Key ID** + **Team ID** → Upload.
- [ ] APNs key đã upload vào Firebase (push mới chạy trên TestFlight/production).

---

## BƯỚC 4 — Deploy Firestore rules (cho tính năng Báo cáo ảnh)
```
npx firebase-tools login        # nếu chưa đăng nhập
npx firebase-tools deploy --only firestore:rules --project tonyembeiu
```
- Rule `reports` (create-only) vừa thêm cần deploy thì báo cáo mới ghi thật.
- [ ] Deploy rules thành công.

---

## BƯỚC 5 — Tạo tài khoản demo cho Apple review
> Reviewer cần 1 couple đã ghép sẵn để test (app ghép qua mã mời, không có demo thì dễ bị reject).
1. Chạy app (debug trên máy thật, hoặc TestFlight sau bước 6).
2. Đăng ký tài khoản **A** (vd `demo1@dearembeiu.app` / mật khẩu mạnh) → màn Setup → **Tạo couple** → ghi lại **mã mời 6 ký tự**.
3. Đăng ký tài khoản **B** (`demo2@dearembeiu.app`) → nhập mã → ghép cặp.
4. Đăng vài tấm ảnh (để reviewer thấy gallery có nội dung).
5. Điền `demo1@…` + mật khẩu vào **APP_STORE_CONTENT.md mục 8** và sau này vào App Store Connect → App Review Information.
- [ ] Có tài khoản demo đã ghép couple + có ảnh.

---

## BƯỚC 6 — Build & upload (TestFlight)
> Lần đầu nên dùng **Xcode Archive** (dễ nhất). Tăng build number mỗi lần upload (pubspec `version: 1.0.0+1` → lần sau `+2`).

**Cách A — Xcode (khuyến nghị):**
1. Trong Xcode (đang mở workspace): thanh trên chọn device **Any iOS Device (arm64)**.
2. Menu **Product → Archive** (chờ build).
3. Cửa sổ **Organizer** mở → chọn archive → **Distribute App** → **App Store Connect** → **Upload** → Next… → Upload.

**Cách B — CLI + Transporter:**
```
flutter build ipa --release
```
→ file ở `build/ios/ipa/*.ipa` → mở app **Transporter** (tải từ Mac App Store) → kéo .ipa vào → **Deliver**.

4. Chờ Apple xử lý build (~15–60 phút) → build hiện trong App Store Connect / TestFlight.
- [ ] Build đã upload + xử lý xong.

---

## BƯỚC 7 — Screenshots 6.7"
- Cần ảnh **1290×2796** (iPhone 16 Plus / 15 Plus). Tối thiểu 3, nên 4–5 màn đẹp: Home (đếm ngày) · Gallery · Cài đặt/Cột mốc · Profile couple.
- 👉 **Claude chụp hộ được** từ simulator iPhone 16 Plus đang chạy (`xcrun simctl io … screenshot`). Nhờ Claude: *"chụp screenshots cho App Store"*.
- iPad: ĐÃ bỏ (iPhone-only) → không cần.
- [ ] Có ≥3 screenshots 1290×2796.

---

## BƯỚC 8 — App Store Connect: tạo app + metadata
1. https://appstoreconnect.com → **My Apps** → **+** → **New App**.
   - Platform **iOS**, Name **Dear Embeiu**, Primary Language **Vietnamese**, Bundle ID **com.tony.dearembeiu**, SKU `dearembeiu-ios-001`.
2. **App Information**: Category (Primary **Lifestyle**, Secondary **Social Networking**), **Privacy Policy URL** (từ APP_STORE_CONTENT.md mục 5).
3. **Pricing and Availability**: Free, chọn quốc gia.
4. **App Privacy**: điền "nutrition label" theo **APP_STORE_CONTENT.md mục 7** (Contact Info, User Content/Photos, Identifiers, Diagnostics, Usage — đều "App Functionality", "Linked", KHÔNG Tracking). Khai Firebase là 3rd-party.
5. **Version (1.0)**:
   - Screenshots 6.7" (bước 7).
   - Promotional text + Description + Keywords + Subtitle (APP_STORE_CONTENT.md mục 1–4).
   - Support URL.
   - **Build**: chọn build đã upload (bước 6).
   - **Age Rating**: làm questionnaire (UGC riêng tư → ~12+).
   - **App Review Information**: bật **Sign-In required** → điền tài khoản demo (bước 5) + Notes (APP_STORE_CONTENT.md mục 8: giải thích mã mời + cơ chế report/block).
6. **Add for Review → Submit**.
- [ ] Đã submit.

---

## Thứ tự tối ưu (tóm tắt)
`0 commit` → `1 account (chờ duyệt)` → `2 ký số` → `3 APNs` + `4 deploy rules` → `5 demo` → `6 build upload` → `7 screenshots` → `8 metadata + submit`.

## Việc Claude làm hộ được (cứ nhờ)
- Commit code · chụp screenshots từ sim · build ipa/verify · soạn/sửa metadata · chạy lệnh deploy rules (sau khi bạn `firebase login`).
## Việc CHỈ bạn làm (cần đăng nhập/thẻ/Xcode GUI)
- Enroll Developer · chọn Team ký số trong Xcode · tạo APNs key trên portal · upload .p8 lên Firebase · điền form App Store Connect · bấm Submit.
