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
