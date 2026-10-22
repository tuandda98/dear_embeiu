# last-seen — `users/{uid}.lastSeenAt` đúng lần mở app gần nhất

**Trạng thái:** 💻 Dev xong + kiểm trên app thật (2026-10-15) · đi theo đợt release kế tiếp, không phát hành riêng.

## Vấn đề

Trước đây `lastSeenAt` chỉ được ghi khi khởi động lại app hoặc đăng nhập (`auth_service.dart`, nhánh `existingProfile != null`). Người mở app từ nền mỗi ngày vẫn mang `lastSeenAt` cũ nhiều ngày.

Trang thống kê người dùng bên Zoey platform dựa vào trường này để tính "cặp còn dùng", "cặp lệch 1 người", "sắp rời". Số sai thì ba nhóm này sai theo.

## Quyết định đã chốt (Lead, 2026-10-15)

- App quay lại tiền cảnh (`AppLifecycleState.resumed`) và đã đăng nhập → ghi `lastSeenAt = serverTimestamp()`.
- Tối đa 1 lần ghi mỗi giờ mỗi máy. Mốc giữ trong bộ nhớ, mở lại app từ đầu thì đếm lại.
- Chỉ ghi đúng 1 khoá `lastSeenAt`. Không đụng `updatedAt` (trường đó nghĩa là hồ sơ thay đổi), không ghi lại cả hồ sơ.
- Fire-and-forget, nuốt lỗi: không chặn UI hay điều hướng.
- Không sửa `firestore.rules` (`onlyAllowedUserFieldsChanged` đã có `lastSeenAt`), không thêm trường, không đụng `analytics_service` hay Cloud Functions.

## Tiêu chí nghiệm thu

- Đưa app xuống nền rồi mở lại sau hơn 1 giờ → `lastSeenAt` trên Firestore đổi, `updatedAt` giữ nguyên.
- Chuyển app qua lại nhiều lần trong 1 giờ → chỉ 1 lần ghi.

Chi tiết: [dev.md](dev.md) · [test.md](test.md)
