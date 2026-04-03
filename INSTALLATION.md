# 📦 Hướng Dẫn Cài Đặt và Sử Dụng

## 🔧 Yêu Cầu Hệ Thống

### Trước Khi Cài Đặt
- **macOS**: Xcode 13+
- **Windows**: Visual Studio Build Tools
- **Linux**: build-essential

### Flutter & Dart
- Flutter SDK: 3.11.4 trở lên
- Dart: bundled với Flutter
- Java Development Kit (JDK) 11+

### Android Development (Android)
- Android SDK 21+ (Android 5.0)
- Android NDK (tự động với Flutter)
- Emulator hoặc thiết bị thực

### iOS Development (iOS)
- Xcode 13+
- CocoaPods
- iOS 11+

---

## 💻 Cài Đặt Flutter (Nếu chưa có)

### macOS
```bash
# Tải Flutter
git clone https://github.com/flutter/flutter.git -b stable ~/flutter

# Thêm vào PATH
export PATH="$PATH:$HOME/flutter/bin"

# Hoặc viết vào .zshrc/.bash_profile
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# Kiểm tra cài đặt
flutter --version
flutter doctor
```

### Windows
1. Tải Flutter SDK từ [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Giải nén vào `C:\src\flutter`
3. Thêm `C:\src\flutter\bin` vào PATH
4. Chạy `flutter doctor` trong PowerShell

### Linux
```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor
```

---

## 🎯 Clone và Cài Đặt Project

### 1. Clone Repository
```bash
git clone https://github.com/tuandda98/dear_embeiu.git
cd dear_embeiu
```

### 2. Lấy Dependencies
```bash
flutter pub get
```

Lệnh này sẽ:
- ✅ Tải tất cả packages từ pub.dev
- ✅ Cài đặt packages Android/iOS
- ✅ Tạo lock file

### 3. Kiểm tra Thiết Lập
```bash
flutter doctor
```

Output mong muốn:
```
✓ Flutter
✓ Android toolchain
✓ Xcode (cho iOS)
✓ Android Studio
✓ VS Code (nếu dùng)
✓ Connected devices
```

---

## 🚀 Chạy Ứng Dụng

### Chạy Trên Emulator Android

#### 1. Khởi động Android Emulator
```bash
# Xem danh sách emulator
flutter emulators

# Khởi động emulator
flutter emulators --launch Pixel_5_API_31

# Hoặc mở Android Studio → Virtual Device Manager
```

#### 2. Chạy App
```bash
flutter run

# Hoặc chạy trên emulator cụ thể
flutter run -d emulator-5554
```

### Chạy Trên Thiết Bị Android Thực

#### 1. Kích Hoạt USB Debugging
1. Vào `Settings` → `About Phone`
2. Tap "Build Number" 7 lần
3. Quay lại, vào `Developer Options`
4. Bật "USB Debugging"
5. Kết nối thiết bị qua USB
6. Cho phép "Trust this computer"

#### 2. Chạy App
```bash
# Kiểm tra thiết bị được phát hiện
flutter devices

# Chạy
flutter run

# Hoặc trên thiết bị cụ thể
flutter run -d <device-id>
```

### Chạy Trên Simulator iOS (macOS only)

```bash
# Khởi động simulator
open -a Simulator

# Chạy app
flutter run

# Hoặc chỉ định iOS version
flutter run -t lib/main.dart
```

### Chạy Trên Thiết Bị iOS Thực

```bash
# Cần Apple Developer Account
flutter run -d <device-id>

# Hoặc qua Xcode
open ios/Runner.xcworkspace
# Chọn device → Run
```

---

## 🔨 Build APK/IPA

### Android APK

#### Debug APK
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Split APKs (per architecture)
```bash
flutter build apk --split-per-abi
```

### iOS IPA

```bash
# Build framework
flutter build ios --release

# Mở Xcode để archive
open ios/Runner.xcworkspace

# Hoặc dùng CLI
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -derivedDataPath build \
  -archivePath build/Runner.xcarchive \
  archive
```

---

## 📱 Lần Đầu Sử Dụng

### Thiết Lập Cặp Đôi
1. **Mở App** → Splash Screen
2. **Setup Screen** xuất hiện
3. **Nhập thông tin**:
   - Tên người 1
   - Tên người 2
   - Ngày yêu nhau (date picker)
   - Ảnh đôi (optional)
4. **Tap "Bắt Đầu Nào"**
5. **Home Screen** hiện với đếm ngày

### Thêm Ảnh Vào Gallery
1. Tap tab **"Thư viện"** (Gallery)
2. Tap nút **"+"** (thêm ảnh đơn)
   - Chọn ảnh từ thư viện
   - Thêm chú thích (optional)
   - Tap "Lưu"
3. Hoặc tap **"Thêm Nhiều"** (multiple images)

### Chỉnh Sửa Thông Tin
1. Tap tab **"Hồ sơ"** (Profile)
2. Tap **"Chỉnh Sửa Thông Tin"**
3. Sửa thông tin → **"Bắt Đầu Nào"**

---

## 🐛 Troubleshooting

### Lỗi: "flutter: command not found"
```bash
# Kiểm tra PATH
echo $PATH | grep flutter

# Thêm vào ~/.zshrc hoặc ~/.bash_profile
export PATH="$PATH:$HOME/flutter/bin"

# Reload shell
source ~/.zshrc
```

### Lỗi: "Android SDK not found"
```bash
# Thiết lập Android SDK path
flutter config --android-sdk /path/to/android/sdk

# Hoặc tải SDK Manager từ Android Studio
```

### Lỗi: "Podfile" (iOS)
```bash
cd ios
rm Podfile.lock
pod install
cd ..
flutter run
```

### Lỗi: Build APK
```bash
# Clean build
flutter clean

# Get dependencies lại
flutter pub get

# Build lại
flutter build apk --release
```

### Lỗi: "Gradle task assembleDebug failed"
```bash
# Xóa build files
rm -rf build/

# Rebuild NDK
flutter clean

# Rebuild
flutter run
```

---

## 🔄 Update Dependencies

### Check cho updates
```bash
flutter pub outdated
```

### Update packages
```bash
# Update semver compatible
flutter pub upgrade

# Update semver + major versions
flutter pub upgrade --major-versions

# Update package cụ thể
flutter pub add provider@latest
```

---

## 📊 Kiểm Tra Hiệu Năng

### Analyze Code
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

### Build Size Analysis
```bash
flutter build apk --analyze-size
```

---

## 🆘 Support & Resources

### Tài Liệu Chính Thức
- [Flutter Docs](https://docs.flutter.dev/)
- [Flutter API Reference](https://api.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)

### Community
- [Flutter GitHub](https://github.com/flutter/flutter)
- [Stack Overflow - Flutter Tag](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Subreddit](https://www.reddit.com/r/FlutterDev/)

### Issues
- Check existing issues trên project
- Tạo issue chi tiết với:
  - Flutter version
  - Device/Emulator info
  - Error messages
  - Steps to reproduce

---

## 🔐 Bảo Mật

### Mật Khẩu & Keys
- Không commit `.env` files
- Sử dụng environment variables
- Keep API keys private

### Cập Nhật Bảo Mật
```bash
# Check CVEs
flutter pub outdated

# Update packages
flutter pub upgrade
```

---

## 📝 Ghi Chú Thêm

### File quan trọng
- `pubspec.yaml` - Dependencies
- `pubspec.lock` - Version lock (commit)
- `.gitignore` - Exclude files
- `analysis_options.yaml` - Lint rules

### Git Workflow
```bash
# Feature branch
git checkout -b feature/new-feature
# ... code ...
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# Pull request → merge → pull
git checkout main
git pull origin main
```

---

Made with 💕 by Flutter Community

