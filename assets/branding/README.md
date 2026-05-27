# Dear Embeiu — Branding

Bộ nhận diện đồng bộ quanh **một biểu tượng duy nhất**: trái tim trắng trên
gradient *Sunset Romance*. Palette khoá theo `lib/theme/app_colors.dart`.

## Palette

| Token            | Hex       | Dùng cho                         |
|------------------|-----------|----------------------------------|
| sunset1          | `#FF6B9D` | Gradient nền (đầu)               |
| sunset2          | `#FF8FA3` | Gradient nền (cuối)              |
| sunset3          | `#FFB6C1` | Highlight / light source         |
| accentLove       | `#FF4D6D` | Accent chính, link, "Em"         |
| accentLoveDeep   | `#E63956` | Đổ bóng tim                      |
| accentLavender   | `#A78BFA` | Accent phụ (chiều sâu, người 2)  |
| textPrimary      | `#1A1A2E` | Chữ trên nền sáng                |

## Files (master = SVG, PNG sinh ra từ SVG)

| File                         | Kích thước | Vai trò                                   |
|------------------------------|-----------|-------------------------------------------|
| `app_icon.svg` / `.png`      | 1024²     | Icon master (tile bo góc) — nguồn launcher |
| `store_icon.svg` / `_512x512.png` | 512²  | Icon cho store listing                    |
| `adaptive_bg.svg` / `.png`   | 1024²     | Android adaptive — lớp nền (full-bleed)   |
| `adaptive_fg.svg` / `.png`   | 1024²     | Android adaptive — lớp tim (safe zone)    |
| `feature_graphic.svg` / `_1024x500.png` | 1024×500 | Play Store feature graphic        |

`app_icon_v2.svg` là thiết kế cũ (đã thay), giữ lại để tham khảo.
`_backup_selfie_app_icon.jpg` là ảnh đặt nhầm chỗ trước đây (không phải icon).

## Sinh lại PNG từ SVG

Cần `rsvg-convert` (`brew install librsvg`):

```zsh
cd "/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu/assets/branding"
rsvg-convert -w 1024 -h 1024 app_icon.svg      -o app_icon.png
rsvg-convert -w 512  -h 512  store_icon.svg    -o store_icon_512x512.png
rsvg-convert -w 1024 -h 1024 adaptive_bg.svg   -o adaptive_bg.png
rsvg-convert -w 1024 -h 1024 adaptive_fg.svg   -o adaptive_fg.png
rsvg-convert -w 1024 -h 500  feature_graphic.svg -o feature_graphic_1024x500.png
```

## Áp icon cho Android / iOS / Web

Cấu hình ở `pubspec.yaml` (mục `flutter_launcher_icons`) đã trỏ sẵn vào các file trên.

```zsh
cd "/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu"
flutter pub get
dart run flutter_launcher_icons
```
