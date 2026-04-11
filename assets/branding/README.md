# App icon source

Đặt ảnh đại diện app vào file:

`assets/branding/app_icon.png`

Khuyến nghị:
- ảnh vuông
- tối thiểu 1024x1024
- chủ thể nằm giữa ảnh
- tránh chữ nhỏ, viền sát mép

Sau đó chạy:

```zsh
cd "/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu"
flutter pub get
flutter pub run flutter_launcher_icons
```

Lệnh trên sẽ cập nhật icon cho:
- Android
- iOS
- Web

