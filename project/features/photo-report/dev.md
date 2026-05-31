# 💻 Dev — Photo report

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** chờ test
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* Thêm action "Báo cáo ảnh" tại 2 điểm vào trong `gallery_screen.dart` (menu ⋮ feed + icon-row fullscreen). Tap entry → mở bottom-sheet chọn lý do (tap lý do = gửi luôn). Ghi report qua service layer (PhotoService → PhotoProvider) vào Firestore `reports/{autoId}` create-only. Best-effort: local fallback / lỗi không crash, không lộ lỗi, vẫn báo thành công.
- *File/hàm đụng tới:*
  - `lib/l10n/app_en.arb` + `lib/l10n/app_vi.arb` — thêm 8 key prefix `report*` (sau `deletePhotoAction`). Chạy `flutter gen-l10n` → regenerate `lib/l10n/app_localizations*.dart`.
  - `lib/services/photo_service.dart` — thêm `reportPhoto({reporterUid, coupleId, photoId, authorUserId, reason})` (sau `deletePhoto`, trước `_guessFileExtension`). Ghi `_db.collection('reports').add({...})` với `createdAt: FieldValue.serverTimestamp()`. No-op khi `!isUsingFirebase` hoặc `reporterUid` rỗng; nuốt `FirebaseException`.
  - `lib/providers/photo_provider.dart` — thêm `reportPhoto({photo, reporterUid, reason})` (trước `clearForSignOut`). Không đổi loading/error state (nhẹ, lạc quan). Đọc `coupleId`/`authorUserId` từ `photo` (fallback `''`).
  - `lib/screens/gallery_screen.dart`:
    - enum `_PhotoFeedAction` (~1368) thêm value `report`.
    - PopupMenu feed (~1043): `onSelected` thêm nhánh `report` → `_reportPhoto(photo)`; `itemBuilder` thêm `PopupMenuItem` cuối danh sách (icon `flag_outlined` 18px accentRose + label, luôn hiện, không gate đăng nhập).
    - `_reportPhoto(Photo)` + `_showReportReasonSheet()` (trả mã reason hoặc null) + `_buildReportReasonTile(...)` — thêm sau `_deletePhoto`.
    - `_openPhotoPreview` (~326): truyền `onReport: _reportPhoto` vào `_FullscreenPhotoPreview`.
    - `_FullscreenPhotoPreview` (~1581): thêm field `onReport`; icon-row top-right thêm `IconButton.filledTonal` flag_outlined làm phần tử ĐẦU (style giống edit/close, nền black@0.28, fg white) + `SizedBox(width:8)`, `onPressed` gọi `widget.onReport!(currentPhoto)` (KHÔNG pop preview — sheet mở chồng lên).
  - `firestore.rules` — thêm `match /reports/{reportId}` create-only.
- *Thay đổi model / Firestore / Cloud Function / native config:* KHÔNG đổi model. Firestore: collection mới `reports` (create-only). KHÔNG Cloud Function, KHÔNG native config.
- *Cần deploy?* **rules** — `firebase deploy --only firestore:rules`. **Dev KHÔNG deploy** (R5, việc user duyệt). Tính năng chỉ chạy thật sau khi rules được deploy.

## Field report ghi (R1)
`reports/{autoId}`:
- `reporterUid` (string) — `AuthProvider.currentUser.id` hiện tại
- `coupleId` (string) — `photo.coupleId`
- `photoId` (string) — `photo.id`
- `authorUserId` (string) — `photo.authorUserId` (tác giả ảnh bị báo cáo)
- `reason` (string) — **mã ổn định** `inappropriate` / `spam` / `other` (KHÔNG ghi chuỗi đã dịch; label hiển thị lấy từ ARB)
- `createdAt` — `FieldValue.serverTimestamp()`

## Đoạn rules đã thêm (firestore.rules, cuối block documents)
```
match /reports/{reportId} {
  allow create: if request.auth != null;
  allow read, update, delete: if false;
}
```
KHÔNG nới lỏng rule khác (users/invite_codes/couples/photos giữ nguyên).

## Edge case kỹ thuật đã xử lý
- **Local fallback / chưa Firebase** (`isUsingFirebase=false`): `PhotoService.reportPhoto` no-op ngay (không ghi, không crash); UI vẫn hiện snackbar `reportSentConfirm`. Không lộ lỗi (R5 risk overview 🟡).
- **Lỗi ghi Firestore** (`FirebaseException`, vd permission/unavailable khi chưa deploy rules): nuốt lỗi trong service → UI báo lạc quan.
- **reporterUid rỗng** (chưa auth): service no-op (rules cũng cấm vì cần auth). Không crash.
- **Huỷ / dismiss sheet:** trả `null` → `_reportPhoto` return sớm, KHÔNG ghi, KHÔNG snackbar.
- **mounted guard:** kiểm `mounted` sau await sheet và sau await report trước khi đụng context/snackbar.
- **R4:** KHÔNG ẩn ảnh sau report — chỉ snackbar.
- **Tự báo cáo ảnh mình:** vẫn cho (không phân biệt — app 2 người, theo design).

## Checklist implement
- [x] Action "Báo cáo ảnh" ở menu ⋮ feed (mục cuối, icon flag_outlined accentRose, luôn hiện)
- [x] Nút 🚩 ở fullscreen icon-row (phần tử đầu, style filledTonal giống edit/close, tooltip reportPhotoAction)
- [x] Bottom-sheet 3 lý do (bo 28, cardSurface, tile surfaceLight bo 18, tap = gửi) + nút Huỷ full-width
- [x] reason lưu mã ổn định inappropriate/spam/other
- [x] Service `reportPhoto` ghi reports/{autoId} đúng field + serverTimestamp
- [x] Snackbar xác nhận `reportSentConfirm` (R4), KHÔNG ẩn ảnh
- [x] Huỷ/dismiss → không ghi gì
- [x] firestore.rules reports create-only; KHÔNG nới rule khác
- [x] i18n 8 key vi+en, `flutter gen-l10n`
- [x] Local fallback / lỗi không crash, báo lạc quan
- [x] `flutter analyze` sạch
- [x] Không hardcode chuỗi (qua l10n)
- [ ] (Ngoài code) deploy rules — chờ user duyệt (R5)

## flutter analyze
`flutter analyze lib/` → **No issues found!** (ran in 1.7s) — SẠCH.

## Điểm Tester chú ý
- Verify 2 điểm vào (menu ⋮ feed + nút 🚩 fullscreen) đều mở đúng sheet.
- Verify doc `reports` ghi đúng 6 field (đặc biệt `reason` là **mã** chứ không phải chuỗi dịch; `coupleId/photoId/authorUserId` đúng ảnh được báo cáo).
- Verify rules: client KHÔNG đọc/sửa/xoá `reports`; create cần auth. Cần Firebase emulator (chưa cấu hình) — hoặc đọc rules tĩnh.
- Local fallback (`isUsingFirebase=false`): report không crash, vẫn snackbar.
- Huỷ/dismiss sheet → không ghi.
- Regression gallery: xem/đăng/xoá/sửa caption/preview/push — chỉ THÊM action, không đụng logic cũ.
- Tính năng chỉ ghi thật khi rules đã deploy (R5) — trước đó write sẽ permission-denied nhưng được nuốt (UI vẫn báo thành công).

## Nhật ký implement
- [2026-05-31] [Dev] Implement photo-report: thêm action "Báo cáo ảnh" 2 điểm vào (menu ⋮ feed + nút 🚩 fullscreen), bottom-sheet 3 lý do (tap=gửi), service `PhotoService.reportPhoto` + `PhotoProvider.reportPhoto` ghi `reports/{autoId}` create-only (reason = mã ổn định), 8 key i18n vi+en, firestore.rules `reports` create-only (KHÔNG deploy — R5). Local fallback/lỗi best-effort không lộ lỗi. `flutter analyze` sạch. Trạng thái → chờ test.
