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
- **Storage**: Local file system (JSON)
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

# Run app
flutter run
```

### Build
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## 💾 Lưu Trữ Dữ Liệu

Dữ liệu được lưu trữ cục bộ trong thư mục `Documents` của ứng dụng:
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
- Không có xác thực, dữ liệu lưu trữ cho người dùng hiện tại
- Tất cả dữ liệu được lưu trong thư mục riêng tư của ứng dụng

---

Made with 💕 for couples
