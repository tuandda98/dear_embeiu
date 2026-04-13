# 💕 Kỷ Niệm Của Chúng Mình

Một ứng dụng Flutter hiện đại để đếm ngày yêu nhau của các cặp đôi, quản lý và hiển thị ảnh theo kiểu Pinterest.

## 📱 Tính Năng

### 🎯 Trang Chủ (Home)
- **Đếm Ngày Yêu Nhau**: Hiển thị số năm, tháng, ngày đã bên nhau với giao diện hiệp hạn
- **Thẻ Thông Tin Đôi**: Hiển thị tên hai người và ảnh đôi
- **Thống Kê**: Tổng ngày đã bên nhau và trạng thái

### 📸 Thư Viện Ảnh (Gallery)
- **Gallery Kiểu Pinterest**: Bố cục masonry tự động tối ưu hóa
- **Thêm Ảnh Đơn**: Tải ảnh từ thư viện với chú thích tùy chọn
- **Thêm Nhiều Ảnh**: Tải multiple ảnh cùng một lúc
- **Xóa Ảnh**: Xóa ảnh không muốn với nút delete nhanh
- **Chú Thích**: Thêm mô tả cho mỗi ảnh

### 👤 Hồ Sơ (Profile)
- **Thông Tin Cặp Đôi**: Xem tên, ngày yêu nhau
- **Thống Kê**: Số năm, tháng, số lượng ảnh
- **Chỉnh Sửa**: Cập nhật thông tin cặp đôi
- **Đặt Lại**: Xóa tất cả dữ liệu

### 🔐 Tài Khoản & Mã Mời
- **Đăng nhập riêng biệt**: Mỗi người dùng một tài khoản riêng
- **Mã mời cá nhân**: Mỗi tài khoản có một mã mời gắn cố định với account
- **Kết nối cặp đôi**: Một người tạo không gian couple, người còn lại nhập mã mời để kết nối

### ☁️ Sync 2 Máy Sau Khi Ghép Cặp
- **Ảnh & bài post dùng chung**: Ảnh đăng từ một máy sẽ hiện trên máy còn lại
- **Đồng bộ thời gian thực**: Feed ảnh được lắng nghe từ Firebase theo `coupleId`
- **Hiển thị người đăng**: Mỗi bài trong thư viện cho biết ai là người post

## 🎨 Thiết Kế UI/UX

### Màu Sắc Hiện Đại
- **Gradient Chính**: Hồng nhẹ → Màu hoa cà (Primary)
- **Gradient Phụ**: Hồng → Lavender (Secondary)
- **Accent Colors**: 
  - 🌹 Hot Pink (Rose Gold)
  - 🍊 Coral
  - ✨ Gold

### Thành Phần
- Rounded corners (12-24px)
- Gradient backgrounds
- Shadow effects
- Smooth transitions
- Modern typography

## 🛠️ Công Nghệ

- **Framework**: Flutter 3.11.4+
- **State Management**: Provider
- **Auth & Cloud**: Firebase Auth + Cloud Firestore
- **Storage**: Local file system (JSON) + Firestore sync cho dữ liệu người dùng/couple
- **Image Picking**: image_picker
- **Gallery Layout**: flutter_staggered_grid_view
- **UUID**: uuid package

### Key Dependencies
```yaml
provider: ^6.1.0
image_picker: ^1.1.0
flutter_staggered_grid_view: ^0.7.0
path_provider: ^2.1.1
uuid: ^4.0.0
intl: ^0.19.0
```

## 📁 Cấu Trúc Dự Án

```
lib/
├── main.dart              # Điểm vào ứng dụng
├── theme/
│   ├── app_colors.dart    # Định nghĩa màu sắc
│   └── app_theme.dart     # Chủ đề Material
├── models/
│   ├── couple.dart        # Model cặp đôi
│   ├── photo.dart         # Model ảnh
│   └── counter_data.dart  # Model đếm ngày
├── providers/
│   ├── couple_provider.dart   # State quản lý thông tin cặp đôi
│   └── photo_provider.dart    # State quản lý ảnh
├── screens/
│   ├── home_screen.dart      # Trang chủ
│   ├── gallery_screen.dart   # Thư viện ảnh
│   ├── profile_screen.dart   # Hồ sơ
│   └── setup_screen.dart     # Thiết lập ban đầu
├── widgets/
│   ├── counter_card.dart       # Card đếm ngày
│   ├── couple_info_card.dart   # Card thông tin đôi
│   ├── photo_item.dart         # Mục ảnh
│   └── masonry_gallery.dart    # Gallery masonry
└── services/
    └── storage_service.dart    # Lưu trữ dữ liệu
```

## 🚀 Cách Chạy

### Yêu Cầu
- Flutter SDK (3.11.4+)
- Dart SDK (bundled with Flutter)
- Android SDK hoặc Xcode (tùy theo nền tảng)

### Cài Đặt
```bash
# Clone repository
git clone https://github.com/tuandda98/dear_embeiu.git
cd dear_embeiu

# Lấy dependencies
flutter pub get

# Deploy Firestore + Storage rules (cần Firebase CLI và đã login)
npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu

# Run app
flutter run
```

### Firebase CLI
Nếu máy chưa có Firebase CLI hoặc chưa đăng nhập:

```bash
npx firebase-tools login
npx firebase-tools deploy --only firestore:rules,storage --project tonyembeiu
```

Project Firebase mặc định hiện đang map tới `tonyembeiu` trong `.firebaserc`, trùng với `android/app/google-services.json` và `ios/Runner/GoogleService-Info.plist`.
Storage rules nằm trong file `storage.rules`.

### Build
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## 💾 Lưu Trữ Dữ Liệu

Ứng dụng hiện dùng cả local storage và Firebase:

- Firestore `users/{uid}`: hồ sơ người dùng, `inviteCode`, trạng thái couple
- Firestore `invite_codes/{code}`: ánh xạ mã mời → tài khoản
- Firestore `couples/{coupleId}`: không gian chung của 2 người
- Firestore `couples/{coupleId}/photos/{photoId}`: feed ảnh/bài post dùng chung của cặp đôi
- Firebase Storage `couple_photos/{coupleId}/{photoId}`: file ảnh gốc dùng để sync giữa 2 máy

Dữ liệu cục bộ vẫn được lưu trong thư mục `Documents` của ứng dụng:
- `couple_data.json`: Thông tin cặp đôi
- `photos_data.json`: Metadata ảnh
- `couple_photos/`: Thư mục chứa ảnh

## ✨ Tính Năng Tương Lai

- [ ] Cloud sync (Firebase)
- [ ] Shared memories with notifications
- [ ] Anniversary reminders
- [ ] Photo filters and editing
- [ ] Favorites/bookmarks
- [ ] Export memories as album
- [ ] Dark mode
- [ ] Multiple language support

## 📝 Ghi Chú

- Ảnh được lưu cục bộ trên thiết bị
- Đăng nhập dùng Firebase Auth nếu Firebase được cấu hình đầy đủ
- Để flow mã mời và sync ảnh hoạt động, cần deploy đúng cả `firestore.rules` và `storage.rules` lên project Firebase
- Tất cả dữ liệu local được lưu trong thư mục riêng tư của ứng dụng

---

Made with 💕 for couples
