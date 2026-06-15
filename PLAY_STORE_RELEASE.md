# Google Play release guide for `dear_embeiu`

Tài liệu này bám theo đúng cấu hình hiện tại của project Flutter tại repo này.

## 1. Kết quả rà soát nhanh

Các điểm hiện tại cần lưu ý trước khi phát hành:

- Android App Bundle build được thành công tại `build/app/outputs/bundle/release/app-release.aab`
- `applicationId` hiện tại là `com.tony.dearembeiu`
- File `android/app/google-services.json` cần luôn khớp với package `com.tony.dearembeiu` trong Firebase để bản release build được ổn định
- `version` hiện tại trong `pubspec.yaml` là `1.2.0+7` (bản revamp: chat / nhắc đồng bộ / migrate love-note — **cần backend prod đã deploy** thì mới chạy đúng)
- Tên app Android hiện tại trong `AndroidManifest.xml` là `dear embeiu`
- Project dùng các dịch vụ Firebase: Auth, Firestore, Storage, Messaging
- Vì có đăng nhập, upload ảnh và push notification nên cần chuẩn bị:
  - Privacy Policy
  - Data safety form trên Play Console
  - Khai báo App content phù hợp

## 2. Chuẩn bị package name chính thức

Trước lần publish đầu tiên, nên đổi package name sang dạng domain của bạn, ví dụ:

- `com.tony.dearembeiu`
- `vn.tuan.dearembeiu`
- `com.yourbrand.dearembeiu`

### Những chỗ phải đổi nếu đổi package name

1. `android/app/build.gradle.kts`
   - `namespace`
   - `applicationId`
2. Đổi package của `MainActivity.kt`
3. Đổi đường dẫn thư mục Kotlin tương ứng
4. Tạo lại app Android trong Firebase theo package mới
5. Tải lại file `android/app/google-services.json`

> Project này đã đổi sang `com.tony.dearembeiu`; trước khi publish, hãy chắc chắn Play Console và Firebase đều dùng đúng package này.

## 3. Tạo upload keystore

Chạy lệnh sau trong terminal:

```bash
cd "/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu/android/app"
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Sau đó tạo file thật từ mẫu:

```bash
cd "/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu/android"
cp key.properties.example key.properties
```

Điền giá trị thật vào `android/key.properties`:

```properties
storePassword=mat_khau_file_keystore
keyPassword=mat_khau_key
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Project đã được cập nhật để:

- dùng keystore release nếu `android/key.properties` tồn tại
- fallback sang debug signing nếu bạn chưa cấu hình keystore

## 4. Tăng version trước khi upload

Sửa trong `pubspec.yaml`:

```yaml
version: 1.2.0+7
```

Quy ước:

- `1.0.0` = versionName hiển thị cho người dùng
- `1` = versionCode nội bộ

Ví dụ bản tiếp theo:

```yaml
version: 1.0.1+2
```

## 5. Build Android App Bundle (.aab)

Sau khi cấu hình keystore, chạy:

```bash
cd "/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu"
flutter clean
flutter pub get
flutter build appbundle --release
```

File output:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 6. Kiểm tra Firebase trước khi publish

Vì app dùng Firebase, hãy kiểm tra các mục sau:

### Auth
- Email/password login hoạt động trên bản release
- Nếu dùng Google Sign-In về sau, cần thêm SHA-1/SHA-256 vào Firebase

### Firestore / Storage
- `firestore.rules` và `storage.rules` đã deploy bản production
- Tài khoản thật truy cập được đúng dữ liệu của couple
- Upload ảnh và đọc ảnh chạy ổn trên build release

### Firebase Messaging
- App đã xin quyền notification trên Android 13+
- Notification channel `partner_photo_updates` đã có trong app
- Test nhận push trên build release cài máy thật

## 7. Chuẩn bị nội dung Play Console

Bạn sẽ cần các mục sau:

### Store listing
- App name
- Short description
- Full description
- App icon 512x512
- Feature graphic 1024x500
- Screenshots điện thoại

### App content / policy
- Privacy Policy URL
- Data safety form
- Có/không thu thập dữ liệu cá nhân
- Có/không chia sẻ dữ liệu với bên thứ ba
- Khai báo quyền thông báo nếu được hỏi trong luồng policy tương ứng

### Phân loại ứng dụng
App này phù hợp nhóm:
- Lifestyle
- Social

## 8. Gợi ý Data safety cho app này

Dựa trên dependencies hiện có, bạn nên rà soát và khai báo tối thiểu các nhóm dữ liệu sau nếu app thực sự thu thập hoặc truyền chúng:

- Personal info
- Photos and videos
- App activity
- Device or other identifiers

> Chỉ khai báo những gì app thực sự thu thập/xử lý. Hãy đối chiếu với logic trong `lib/services/`, `lib/providers/`, Firestore schema và Firebase Console.

## 9. Checklist upload lên Google Play

- [ ] Có tài khoản Google Play Console
- [ ] App chưa trùng package name
- [ ] Đã tạo keystore upload riêng
- [ ] Đã điền `android/key.properties`
- [ ] Đã tăng `version` trong `pubspec.yaml`
- [ ] Đã test đăng nhập, ghép cặp, upload ảnh, nhận push trên bản release
- [ ] Đã có Privacy Policy URL
- [ ] Đã chuẩn bị icon, feature graphic, screenshots
- [ ] Đã hoàn tất Data safety
- [ ] Đã build `app-release.aab`
- [ ] Đã upload lên track `Internal testing` trước

## 10. Quy trình publish nên làm

1. Tạo app mới trên Play Console
2. Chọn default language + app name
3. Upload file `.aab`
4. Điền Store listing
5. Điền App content
6. Điền Data safety
7. Tạo release ở `Internal testing`
8. Cài test trên máy thật
9. Nếu ổn, promote sang `Closed testing` hoặc `Production`

## 11. Các việc tôi khuyến nghị làm ngay cho repo này

1. Chốt package name chính thức
2. Tạo upload keystore riêng
3. Tạo trang Privacy Policy
4. Tăng version lên bản phát hành đầu tiên
5. Upload bản `Internal testing` trước khi public

## 12. Lệnh nhanh

### Build bản upload
```bash
cd "/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu"
flutter build appbundle --release
```

### Kiểm tra file output
```bash
ls -lh "/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu/build/app/outputs/bundle/release/app-release.aab"
```

