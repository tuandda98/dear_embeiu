# 💻 Dev — Gallery

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md).

- **Trạng thái dev:** ✅ Đã implement (baseline)

## Đã implement
- `photo_service.dart` (CRUD + watch Firestore stream + upload Storage + captions), `photo_provider.dart` (watch/sync/add/delete/updateCaption), `storage_service.dart` (cache local). Feed UI + fullscreen viewer ở `gallery_screen.dart`. CF push partner-photo.

## Việc cần làm tiếp (từ nợ kỹ thuật)
- [ ] Push đa ngôn ngữ (gap B — chung feature [language](../language/dev.md)).
- [ ] Ngày feed locale-aware (gap A).
- [ ] Rules: chỉ author được xoá ảnh của mình (hoặc cả 2 đồng ý).
- [ ] Re-validate ảnh thực (magic bytes) thay vì tin contentType client.
- [ ] Re-upload ảnh offline khi online lại; check `existsSync` cache path; rollback optimistic khi server fail.
- [ ] Giới hạn size/số ảnh batch + giới hạn ký tự caption.
- [ ] Xoá dead code `MasonryGallery` nếu chắc không dùng.

## Nhật ký implement
- [2026-05-30] [PO] Khởi tạo doc; liệt kê việc cần Dev.
- [2026-06-01] [Dev] Notification tap deep-link: chạm push mở đúng tab. `push_notification_service.dart` thêm `NotificationTapRouter` (`ValueNotifier<int> pendingHomeTab`, -1=không có) + `_handleNotificationTap(RemoteMessage)` map `type` → tab (photo_posted→Gallery 1, partner_joined→Home 0, type khác/thiếu→bỏ qua). `initialize()`: `onMessageOpenedApp.listen(_handleNotificationTap)` (warm) + `getInitialMessage()` (cold). `home_screen.dart`: initState đọc pending (cold-start, set trước khi mount) + listen notifier (warm → addPostFrameCallback + guard mounted), consume sau khi áp dụng. Không thêm package, không navigatorKey. `flutter analyze` sạch.
- [2026-06-05] [Dev/Lead] **Fix "không đăng được hình".** `photo_service.dart` `addPhoto`: `putFile` giờ truyền `SettableMetadata(contentType: _contentTypeForExtension(ext))` thay vì để SDK tự suy. Storage rule bắt buộc `contentType.matches('image/.*')`; ảnh có đuôi lạ/thiếu (HEIC, file temp cache-dir) có thể bị SDK gán `application/octet-stream` → upload bị từ chối. Thêm helper map ext→image/* (png/gif/webp/heic/bmp/jpeg, default jpeg). analyze sạch, không đổi rules/native. (Phụ: dev project thiếu function — đã deploy đủ parity, xem coupling/dev.md.)
