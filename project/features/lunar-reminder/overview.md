# Lịch âm + Nhắc mồng 1 / ngày rằm — overview (PO)

> Feature ACCOUNT-GATED (2026-06-19, user yêu cầu). Chỉ tài khoản **`dodaoanhtuan@gmail.com`** thấy. Mode: Lead build trực tiếp.

## 1. Yêu cầu (user)
Riêng tài khoản dodaoanhtuan@gmail.com: có **lịch âm** + mục **nhắc ngày mồng 1 và ngày 15 (rằm) âm lịch hàng tháng**, nhắc lúc **7h, 8h, 9h sáng** (giờ chẵn = đúng đầu giờ :00).

## 2. PO chốt
- **Lịch âm UI = thẻ gọn trong Settings** (user chọn): hiện ngày âm HÔM NAY + can-chi năm + mồng-1/ngày-rằm SẮP TỚI (dương) + 1 toggle bật nhắc. KHÔNG làm màn lịch grid (để sau nếu cần).
- **Giờ nhắc = 3 lần: 07:00, 08:00, 09:00** mỗi ngày mồng 1 & rằm (user xác nhận "giờ chẵn" = đúng đầu giờ).
- **Gate theo email** (pattern sẵn có như `_hideDataManagementEmails`): set `_lunarCalendarEmails = {dodaoanhtuan@gmail.com}` ở `settings_screen.dart`. Card + toggle chỉ hiện cho account này.
- **LOCAL hoàn toàn** — không Firestore/CF/push. Notification local như love-reminder.

## 3. Quyết định kỹ thuật
- **Âm lịch:** chưa có package → nhúng thuật toán **Hồ Ngọc Đức** (timezone VN UTC+7), thuần Dart offline → `lib/utils/lunar_calendar.dart`. ✅ verify 7 test (Tết Giáp Thìn/Ất Tỵ, Đoan Ngọ, Trung Thu, can-chi, next-occurrences).
- **Lịch nhắc:** ngày âm KHÔNG rơi vào ngày dương cố định → không repeat native được. Giải pháp: schedule **cửa sổ cuộn** = 6 lần mồng-1/rằm sắp tới × 3 giờ = 18 one-shot; **top-up mỗi lần mở app** qua `ReminderProvider.refreshLunar` (gọi trong `sync()`). Band id 1060–1099 (riêng, ngoài `_autoIds`). Cân nhắc cap 64-pending iOS → giữ window nhỏ (18).
- **Bật/tắt:** Hive `lunar_reminder_enabled` (box `reminder_settings`); UI gate bằng email (flag Hive vẫn drive scheduling kể cả account khác trên cùng máy — chấp nhận, vì UI ẩn).

## 4. Trạng thái
- ✅ Code xong: util + service + provider + l10n (12 key en+vi) + thẻ Settings gated. analyze sạch (chỉ 1 lint pre-existing ở `mood.dart`). 7 test âm lịch pass.
- ⏳ CHƯA smoke-test runtime trên thiết bị (bật toggle → kiểm OS đã đặt lịch). CHƯA commit.

## 5. Còn có thể mở rộng (sau)
- Màn lịch âm grid đầy đủ.
- Cho user tự chọn giờ/ngày âm khác (hiện cứng 1&15, 7/8/9h).
- Nhắc các ngày âm đặc biệt (Tết, rằm tháng Giêng/Bảy…).
