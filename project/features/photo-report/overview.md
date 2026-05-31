# Photo report — Báo cáo ảnh (UGC compliance, Apple 1.2)

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** photo-report
- **Ưu tiên:** P1 (compliance — giảm rủi ro reject App Store Guideline 1.2)
- **Trạng thái:** ✅ Done (2026-05-31) — Tester PASS 17/17; **rules đã deploy** lên `tonyembeiu` (report ghi thật được). Còn (ngoài code): điền tài khoản demo vào App Review notes khi submit.
- **Tạo ngày:** 2026-05-31
- **Liên quan:** mở rộng [gallery](../gallery/overview.md) · [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 5 (Firestore/rules)

## 1. Vấn đề & giá trị
- *Vấn đề:* App có **user-generated content** (ảnh chung). Apple **Guideline 1.2** yêu cầu app có UGC phải có: (a) cơ chế **báo cáo** nội dung không phù hợp, (b) cách **chặn** người lạm dụng, (c) act on reports. Hiện app chưa có nút báo cáo → rủi ro reject.
- *Giá trị:* Thêm "Báo cáo ảnh" nhẹ → đủ điều kiện 1.2, submit App Store an toàn hơn. (App vốn riêng tư 2 người nên rủi ro thấp, nhưng reviewer thích thấy cơ chế này.)
- *Đối tượng:* mọi user.

## 2. Phạm vi (scope)
- **Trong:**
  - Thêm hành động **"Báo cáo ảnh"** vào ảnh trong gallery: ở **menu ⋮ feed** và **panel fullscreen preview**.
  - Tap → chọn lý do ngắn (nội dung không phù hợp / spam / khác) → xác nhận → ghi report + thông báo "Đã gửi báo cáo".
  - Lưu report lên Firestore (collection `reports`, **create-only** với user đã đăng nhập) — admin xem qua Console.
  - **Chặn = tái dùng "Rời couple"** đã có (không code mới) — nêu trong submission notes.
- **Ngoài:**
  - KHÔNG làm dashboard xử lý report / Cloud Function tự động (admin xem Console — đủ cho compliance MVP).
  - KHÔNG ẩn ảnh tự động phía partner (chỉ capture report).
  - KHÔNG đụng logic gallery khác.

## 3. Quyết định đã chốt (decision log)
- **R1 — Report lưu Firestore `reports/{autoId}`** field: reporterUid, coupleId, photoId, authorUserId (của ảnh), reason, createdAt. **Rules: create-only** (allow create if `request.auth != null`; read/update/delete = false). *Lý do:* nhẹ, không cần Cloud Function; admin review qua Console. Đủ cho 1.2 MVP.
- **R2 — "Chặn" = tái dùng "Rời couple"** (đã có ở Settings → Tài khoản). Không thêm block riêng (app chỉ 2 người, rời couple = cắt liên kết). Nêu trong App Review notes.
- **R3 — Điểm vào:** menu ⋮ ở feed item + panel info ở fullscreen preview (2 chỗ user xem ảnh).
- **R4 — Sau report:** chỉ thông báo "Đã gửi báo cáo, cảm ơn bạn" (snackbar) — KHÔNG ẩn ảnh (tránh phức tạp đồng bộ). Có thể thêm ẩn-local sau.
- **R5 — Cần DEPLOY rules** (`firebase deploy --only firestore:rules`) trước khi tính năng chạy thật — việc user/PO duyệt (publish backend). Dev KHÔNG tự deploy.

## 4. Acceptance criteria
- [ ] Có "Báo cáo ảnh" ở menu ⋮ feed + panel fullscreen.
- [ ] Tap → chọn lý do → xác nhận → ghi doc vào `reports` (đúng field) → snackbar xác nhận.
- [ ] Huỷ giữa chừng → không ghi gì.
- [ ] firestore.rules: `reports` **create-only** (member đã đăng nhập tạo được; KHÔNG read/update/delete client). Không nới lỏng rule khác.
- [ ] Không regression gallery (xem/đăng/xoá/caption ảnh, push) — chỉ thêm action.
- [ ] i18n vi+en cho mọi chuỗi mới; không hardcode.
- [ ] `flutter analyze` sạch.
- [ ] (Ngoài code) rules deploy + App Review notes cập nhật cơ chế report/block.

## 5. Nợ kỹ thuật / rủi ro (Tester soi)
- 🟡 Rules `reports` phải đúng create-only — verify KHÔNG cho đọc/sửa/xoá từ client; không ảnh hưởng rule `couples`/`photos`/`users` hiện có.
- 🟡 Local fallback (chưa Firebase / `isUsingFirebase=false`): report nên không crash — ghi local hoặc bỏ qua + vẫn báo thành công UI (đừng lộ lỗi).
- 🟡 Đảm bảo report dùng đúng coupleId/photoId/author của ảnh được báo cáo.

## 6. Giao việc 3 vai
- 🎨 **Designer:** thiết kế action "Báo cáo ảnh" (vị trí menu feed + panel fullscreen), bottom-sheet/dialog chọn lý do, confirmation. Đồng nhất design system. Copy vi+en. → `design.md`.
- 💻 **Dev:** thêm action + dialog lý do + ghi `reports` (service), firestore.rules `reports` create-only, ARB, analyze sạch. KHÔNG deploy. → `dev.md`.
- 🧪 **Tester:** verify action 2 chỗ, ghi report đúng field, huỷ không ghi, rules create-only (đọc rules), local fallback không crash, không regression gallery, i18n. → `test.md`.

## 7. Changelog
- [2026-05-31] [PO] Tạo feature photo-report (Apple 1.2 UGC compliance): nút báo cáo ảnh nhẹ + reports create-only + chặn=rời couple. Khởi động pipeline.
- [2026-05-31] [Designer→Dev→Tester→PO] Pipeline xong: Designer (2 điểm vào + sheet lý do), Dev (`PhotoService.reportPhoto`, 2 entry gallery, rules `reports` create-only, 8 key `report*`), Tester PASS 17/17 (0 bug, không regression, rules an toàn). analyze sạch. **Còn: deploy `firestore.rules` (user duyệt) + App Review notes (đã có sẵn trong APP_STORE_CONTENT.md).**
