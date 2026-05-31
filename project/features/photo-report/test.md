# 🧪 Test — Photo report

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** PASS
- **Người/role:** Master Tester

## Phạm vi test
Feature **photo-report** (nút Báo cáo ảnh — UGC compliance Apple 1.2): 2 điểm vào (menu ⋮ feed + nút 🚩 fullscreen), bottom-sheet lý do, ghi `reports/{autoId}` create-only, snackbar xác nhận, local fallback/lỗi, firestore.rules, i18n, regression gallery. Verify tĩnh (đọc code + rules + ARB) — emulator chưa cấu hình nên rules đánh giá tĩnh, không runtime.

## Test case
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Menu ⋮ feed có mục "Báo cáo ảnh" (mục cuối, icon flag_outlined accentRose, luôn hiện) → mở sheet | `onSelected` nhánh `report` → `_reportPhoto(photo)`; `PopupMenuItem` value `report` ở cuối itemBuilder, không gate đăng nhập | ✅ |
| 2 | happy | Nút 🚩 fullscreen icon-row (phần tử ĐẦU, trước edit/close, filledTonal black@0.28/white, tooltip) → mở sheet | `IconButton.filledTonal` flag_outlined đứng đầu Row + SizedBox(width:8); `onPressed`→`widget.onReport!(currentPhoto)`; KHÔNG pop preview (sheet chồng lên) | ✅ |
| 3 | happy | Sheet 3 lý do (tap = gửi luôn) + nút Huỷ; bo 28, cardSurface, tile surfaceLight bo 18 | `showModalBottomSheet` bo top 28, 3 `_buildReportReasonTile` tap → `pop(code)`; nút Huỷ full-width → `pop()` (null) | ✅ |
| 4 | happy | Ghi `reports/{autoId}` đủ 6 field, dùng đúng coupleId/photoId/author của ảnh | Service `add({reporterUid, coupleId, photoId, authorUserId, reason, createdAt: serverTimestamp})`; provider đọc từ `photo` | ✅ |
| 5 | logic | `reason` lưu **mã** (`inappropriate`/`spam`/`other`), KHÔNG chuỗi dịch | Tile truyền `code:` cố định; label hiển thị từ ARB tách riêng | ✅ |
| 6 | happy | Snackbar xác nhận sau gửi; KHÔNG ẩn ảnh (R4) | `ScaffoldMessenger.showSnackBar(reportSentConfirm)`; không có logic ẩn/xoá ảnh trong `_reportPhoto` | ✅ |
| 7 | negative | Huỷ / dismiss sheet → KHÔNG ghi gì, KHÔNG snackbar | `reason == null` → return sớm trước cả provider call & snackbar | ✅ |
| 8 | edge | Local fallback (`!isUsingFirebase`) → no-op, không crash, vẫn snackbar | Service return ngay; UI vẫn await xong → snackbar lạc quan | ✅ |
| 9 | edge | reporterUid rỗng (chưa auth) → no-op, không crash | Service: `reporterUid.trim().isEmpty` → return | ✅ |
| 10 | edge | FirebaseException khi ghi (vd rules chưa deploy → permission-denied) → nuốt, không lộ lỗi, vẫn snackbar | `try/catch on FirebaseException { return; }`; provider không throw; UI báo lạc quan | ✅ |
| 11 | security | firestore.rules `reports` create-only | `allow create: if request.auth != null; allow read, update, delete: if false;` (dòng 380-383) | ✅ |
| 12 | security | KHÔNG nới lỏng rule khác (users/invite_codes/couples/photos/devices) | Diff rules chỉ THÊM block `/reports` ở cuối; các match khác giữ nguyên | ✅ |
| 13 | đa ngôn ngữ | 8 key `report*` parity EN+VI, generated l10n có getter | ARB en + vi đều đủ 8 key; `app_localizations_en/vi.dart` có getter | ✅ |
| 14 | đa ngôn ngữ | Không hardcode chuỗi trong phần báo cáo | Mọi text qua `context.l10n.report*`; chỉ `reason code` là literal (đúng thiết kế) | ✅ |
| 15 | regression | Xem/đăng/xoá/sửa caption/preview/push còn nguyên | Chỉ THÊM enum value `report` + nhánh + item + nút + hàm mới; `addPhoto/deletePhoto/updateCaption/watch` không đổi | ✅ |
| 16 | build | `flutter analyze lib/` sạch | No issues found! (1.5s) | ✅ |
| 17 | build | `flutter test` không lỗi mới | 8 pass; 1 fail = `widget_test.dart "renders login screen scaffold"` (đã fail SẴN ở HEAD, không liên quan) | ✅ |

*(Kết quả: ✅ pass · ❌ fail · ⬜ chưa chạy)*

## Bug report (nếu FAIL)
Không có bug. Không phát hiện regression.

## Ghi chú verify
- **[VERIFIED in code]** toàn bộ luồng UI/service/provider/rules/i18n đọc tĩnh khớp spec R1–R5 + design.
- **[CẦN TEST runtime — sau khi deploy rules R5]:** xác nhận write thật vào `reports` thành công khi đã đăng nhập + rules deployed; xác nhận client KHÔNG đọc/sửa/xoá được (cần Firebase emulator hoặc thiết bị thật — emulator chưa cấu hình). Trước khi deploy rules, write sẽ permission-denied nhưng được nuốt (UI vẫn báo thành công — đúng thiết kế best-effort).
- Self-report (báo cáo ảnh chính mình) vẫn cho phép — đúng design (app 2 người, không phân biệt).
- Sheet anchor vào context GalleryScreen (mở chồng lên fullscreen preview khi gọi từ nút 🚩) — hợp lệ, không pop preview.

## Verdict
**PASS** — 17/17 case đạt (verify tĩnh). Không bug, không regression gallery. firestore.rules `reports` **an toàn** (create-only, không read/update/delete client, không nới rule khác). `flutter analyze` sạch; `flutter test` không lỗi mới (1 fail là pre-existing ở HEAD). Lưu ý: tính năng chỉ ghi thật sau khi **deploy rules** (R5 — việc user duyệt).

## Nhật ký test
- [2026-05-31] [Tester] Test photo-report: verify tĩnh 17 case (2 điểm vào, sheet 3 lý do tap=gửi, ghi reports/{autoId} đủ 6 field reason=mã, snackbar không ẩn ảnh, huỷ không ghi, local fallback/uid rỗng/FirebaseException không crash & không lộ lỗi, rules create-only không nới rule khác, i18n 8 key EN+VI parity, không regression gallery). `flutter analyze lib/` sạch; `flutter test` 8 pass 1 fail pre-existing. Verdict **PASS**. Còn 1 mục CẦN TEST runtime sau deploy rules (R5).
