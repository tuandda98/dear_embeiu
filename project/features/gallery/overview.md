# Gallery — Thư viện ảnh chung + push

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** gallery
- **Ưu tiên:** P0 (vòng lặp giá trị 2 chiều — tài sản giữ chân tốt nhất)
- **Trạng thái:** ✅ Shipped (v1.0.0)
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 5,8,13

## 1. Mô tả
2 người cùng đăng ảnh vào album couple, đồng bộ **realtime** qua Firestore theo `coupleId`. Mỗi ảnh ghi người đăng + caption. Khi một người đăng → **push FCM cho partner** (Cloud Function `sendPartnerPhotoNotification`). Có cache/offline local (JSON + thư mục `couple_photos/`).

## 2. Phạm vi
- **Trong:** đăng ảnh đơn + nhiều ảnh, caption (thêm/sửa), xoá ảnh, feed realtime, fullscreen viewer (zoom/swipe/drag-dismiss), push khi partner đăng.
- **Ngoài:** reactions/comments/likes (→ feature roadmap), albums/phân loại, filter/edit ảnh, photobook/export.

## 3. Code liên quan
- `lib/services/photo_service.dart`, `storage_service.dart`, `lib/providers/photo_provider.dart`
- `lib/screens/gallery_screen.dart`, `lib/widgets/masonry_gallery.dart` (⚠️ KHÔNG dùng — gallery thực tế là feed dọc), `photo_item.dart`, `shared_photo_view.dart`
- Ngày feed: `gallery_screen.dart:275,1652` (⚠️ hardcode "thg" — gap A của [language])
- Backend: rules `couples/{coupleId}/photos`, Storage `couple_photos/{coupleId}`, CF `sendPartnerPhotoNotification`

## 4. Acceptance (đã đạt)
- [x] Đăng ảnh (đơn/nhiều) đồng bộ realtime giữa 2 máy
- [x] Caption thêm/sửa; xoá ảnh; người đăng hiển thị
- [x] Push tới partner khi đăng ảnh
- [x] Push khi partner ghép cặp (`notifyPartnerJoined`, 2026-06-01)
- [x] Tap push deep-link vào đúng tab (photo→Gallery, joined→Home, 2026-06-01)

## 5. Nợ kỹ thuật / rủi ro
- ✅ ~~Push hardcode tiếng Việt~~ — ĐÃ localized vi/en theo `languageCode` device (2026-06-01, deployed).
- 🔴 **Ngày feed hardcode "thg"** (gap A — [language]).
- 🟢 **Permission push xin quá sớm** (trong `syncForUser` ngay lúc login/register, không priming) → opt-in thấp; cân nhắc màn priming. (Push #4)
- 🟢 **`badge:1` hardcode** ở apns, không phản ánh unread thật & không clear → badge "1" dai dẳng. (Push #5)
- 🟢 **Không analytics push** (delivery/open rate) — gắn cùng đợt Analytics toàn app. (Push #6)
- 🟡 **Photo delete không check author** (rules ~374) → member nào cũng xoá ảnh partner (harassment).
- 🟡 **Storage content-type spoof** — rule tin `contentType` client gửi; non-image gắn `image/png` vẫn qua.
- 🟡 **Offline photo không tự re-upload** khi online lại (local-only mãi); cache path không `existsSync` → ảnh vỡ; optimistic delete/caption không rollback khi server fail.
- 🟡 Caption không giới hạn ký tự; không giới hạn size ảnh/số ảnh batch → spam push + chi phí Storage.
- 🟡 `MasonryGallery` widget tồn tại nhưng không dùng → cân nhắc xoá (dead code).

## 6. Changelog
- [2026-05-30] [PO] Tài liệu hoá feature; nối gap A,B sang feature language.
- [2026-06-01] [PO] Phân tích lại push notification (verify đĩa). Phát hiện: chỉ có 1 push (partner-photo); hở vòng lặp lõi (B join → A không nhận gì); tap push không deep-link. Chốt vá 3 việc.
- [2026-06-01] [Dev] #2 `notifyPartnerJoined` (server, onDocumentUpdated couple, guard transition 1→2). #3 deep-link tap (`NotificationTapRouter` + HomeScreen). Refactor helper chung `sendToRecipientDevices` (photo push giữ nguyên hành vi). `node --check` OK, `flutter analyze` sạch.
- [2026-06-01] [PO] Gate PASS + redeploy functions production (4 fn live, gồm notifyPartnerJoined mới + photo localized + apns iOS chắc chắn live).
