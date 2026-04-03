# 🎯 Hướng Dẫn Chi Tiết Các Tính Năng

## 1. 🎯 Trang Chủ (Home Screen)

### Các Thành Phần

#### Counter Card - Đếm Ngày Yêu Nhau
- Hiển thị bộ đếm với 3 hàng: **Năm | Tháng | Ngày**
- Gradient màu hồng đến cam (rose → coral)
- Cập nhật tự động khi app khởi động
- Tap để xem chi tiết (tùy chọn mở rộng)

#### Couple Info Card - Thẻ Thông Tin Đôi
- Ảnh đôi tròn (80x80px) bên trái
- Tên hai người bên phải
- Gradient hồng → tím (primary)
- Tap để chỉnh sửa thông tin
- Icon nút edit ở góc phải

#### Quick Stats - Thống Kê Nhanh
- **📅 Tổng cộng**: Tổng số ngày đã bên nhau
- **❤️ Trạng thái**: "Yêu nhau 💕"

### Thiết Kế Visual
- Background gradient (pink → lavender)
- Cards với shadow elevation
- Spacing nhất quán (24px padding)
- Text hierarchy rõ ràng

---

## 2. 📸 Thư Viện Ảnh (Gallery Screen)

### Gallery Layout - Bố Cục Masonry
- **2 cột** adaptive layout
- **12px spacing** giữa các ảnh
- Tự động điều chỉnh độ cao ảnh
- Smooth scrolling

### Tính Năng Ảnh

#### Thêm Ảnh Đơn (Single Photo)
1. Tap nút "+" tròn
2. Chọn ảnh từ thư viện
3. Dialog hiện lên để nhập chú thích (optional)
4. Tap "Lưu" để thêm
5. Ảnh xuất hiện ngay trong gallery

#### Thêm Nhiều Ảnh (Multiple Photos)
1. Tap nút "Thêm Nhiều" (extended FAB)
2. Chọn nhiều ảnh cùng lúc
3. Tất cả được thêm tự động
4. Toast notification cho biết số lượng

#### Quản Lý Ảnh
- **Xóa**: Tap icon ❌ góc trên phải của ảnh
- **Chú thích**: Hiện dưới dạng overlay text tối (bottom)
- **Sort**: Ảnh được sắp xếp theo ngày upload (mới nhất trước)

#### Empty State
- Icon ảnh lớn
- Text: "Chưa có ảnh nào"
- Hướng dẫn: "Thêm ảnh để bắt đầu tạo kỷ niệm"

### UI Components
- **FAB Primary** (+): Icon add, Hot Pink, tải ảnh đơn
- **FAB Secondary** (Album): Icon photo_album, Coral, tải multiple
- Positioning: Bottom-right, 24px margin

---

## 3. 👤 Hồ Sơ (Profile Screen)

### Thông Tin Cặp Đôi
- **Tên**: Hiển thị dạng "Person1 💕 Person2"
- **Ngày Yêu Nhau**: DD/MM/YYYY format
- **Tổng Ảnh**: Số lượng ảnh hiện có

### Thống Kê Card
3 stat cards ngang nhau:
- **Năm**: Icon favorite (rose color)
- **Tháng**: Icon calendar_month (coral color)
- **Ảnh**: Icon photo (gold color)

Mỗi card hiển thị:
- Icon tô màu
- Số lượng lớn
- Nhãn bên dưới

### Nút Hành Động

#### Chỉnh Sửa Thông Tin
- Button filled rose color
- Icon: edit
- Label: "Chỉnh Sửa Thông Tin"
- Dẫn tới Setup Screen

#### Đặt Lại Dữ Liệu
- Outlined button, red foreground
- Icon: refresh
- Label: "Đặt Lại Dữ Liệu"
- Hiện dialog xác nhận
- Xóa ALL dữ liệu nếu confirm

### Layout
- White background
- Padding 20px
- Cards với shadow nhẹ
- Spacing 16-24px

---

## 4. ⚙️ Trang Thiết Lập (Setup Screen)

### Lần Đầu Lần Sử Dụng

#### Nhập Thông Tin
1. **Tên Người 1**: Text field
2. **Tên Người 2**: Text field
3. **Ngày Yêu Nhau**: Date picker (calendar icon)
4. **Ảnh Đôi**: Image picker (optional)

#### Validation
- Tên không được để trống
- Ngày bắt buộc (required)
- Ảnh tùy chọn

#### Layout
- Gradient background (pink → lavender)
- Header với icon heart lớn
- Title: "Kỷ Niệm Của Chúng Mình"
- Subtitle: "Lưu giữ những khoảnh khắc đặc biệt"
- Form fields trắng semi-transparent
- Primary button "Bắt Đầu Nào" (rose pink)

#### Visual Styling
- Text input white semi-transparent background
- Border white 30% opacity
- Icon prefix trắng
- Rounded corners 12px

---

## 5. 💾 Luồng Dữ Liệu

### Khởi Động Ứng Dụng
```
SplashScreen
    ↓
Load Couple Data từ StorageService
    ↓
Kiểm tra hasCoupleData()
    ├─ Có → LoadPhotos → HomeScreen
    └─ Không → SetupScreen
```

### Lưu Trữ
- **Couple**: `couple_data.json` (JSON)
- **Photos**: `photos_data.json` (JSON metadata + files)
- **Ảnh Files**: `couple_photos/` directory

### State Management (Provider)
- `CoupleProvider`: Quản lý couple data
- `PhotoProvider`: Quản lý photos list
- Notify listeners khi thay đổi

---

## 6. 🎨 Design System

### Color Palette
```
Primary Gradient:
- Start: #FFB6C1 (Light Pink)
- End: #DDA0DD (Plum)

Secondary Gradient:
- Start: #FFC0CB (Pink)
- End: #E6B3FF (Lavender)

Accents:
- Rose: #FF69B4
- Coral: #FF7F50
- Gold: #FFD700

Neutral:
- White: #FFFFFF
- Black: #1A1A1A
- Primary Text: #2D2D2D
- Secondary Text: #6B6B6B
```

### Typography
- **Display Large**: 32px, W700
- **Headline Large**: 24px, W600
- **Body Large**: 16px, W500
- **Body Small**: 12px, W400

### Spacing & Radius
- Padding standard: 16-24px
- Corner radius: 12-24px
- Shadow elevation: 2-8

---

## 7. ✨ Trải Nghiệm Người Dùng

### First Launch Flow
1. Splash Screen (1 giây)
2. Setup Screen
3. Nhập info + chọn ảnh
4. Tap "Bắt Đầu Nào"
5. → Home Screen

### Daily Usage
1. Mở app → Home
2. Xem đếm ngày
3. Tab Thư viện → xem/thêm ảnh
4. Tab Hồ sơ → xem stats

### Photo Management
- Browse gallery
- Tap ảnh → xem full screen (future)
- Delete → confirm dialog
- Add caption → dialog

---

## 8. 🚀 Performance Considerations

### Image Optimization
- ✅ File-based storage (no database)
- ✅ Lazy loading gallery
- ✅ Efficient masonry layout
- ⚠️ Large photo count may need pagination

### State Updates
- ✅ Provider pattern
- ✅ Only notify on changes
- ✅ Efficient rebuilds

### Memory Management
- ✅ Dispose resources properly
- ✅ Clean cached images
- ✅ Manage file handles

---

## 9. 📱 Compatibility

- **Min SDK**: Android 21+ (5.0)
- **Max SDK**: Latest
- **iOS**: 11+
- **Flutter**: 3.11.4+

---

## 10. 🔐 Privacy & Security

- ✅ Local storage only
- ✅ No cloud sync (MVP)
- ✅ Private app directory
- ✅ No personal data collection
- ✅ No analytics tracking


