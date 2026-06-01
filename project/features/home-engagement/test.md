# 🧪 Test — Home engagement (Phase 1: đẩy đăng ảnh từ Home)

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** PASS (static/code-level) — còn case CẦN TEST RUNTIME để user smoke-test
- **Người/role:** Master Tester

## Phạm vi test
Phase 1 home-engagement: CTA "Thêm kỷ niệm" (`_buildAddMemoryCta`) thay cụm 2 quick-action + nút "Đăng ảnh đầu tiên" ở empty-state recent photos; cả 2 mở luồng đăng ảnh copy từ Gallery (`_pickAndAddPhoto`/`_showCaptionDialog`). Verify logic/state/edge/regression/waiting_partner/i18n. Không đụng backend/model/rules.

## Test case
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | CTA "Thêm kỷ niệm" tap → picker single → caption dialog → addPhoto | `_buildAddMemoryCta` `onTap:_pickAndAddPhoto` → `ImagePicker().pickImage(gallery)` → `_showCaptionDialog` → `PhotoProvider.addPhoto`; snackbar `photoAddedSuccess`; KHÔNG `setState(_selectedIndex)` sau đăng (ở lại Home, HE4) | ✅ [VERIFIED code] / 🟨 upload+snackbar [CẦN TEST RUNTIME] |
| 2 | happy | Empty-state button "Đăng ảnh đầu tiên" | `FilledButton.icon` rose `onPressed: isLoading?null:_pickAndAddPhoto`, icon `add_photo_alternate_rounded`, label `postFirstPhotoBtn` → cùng luồng | ✅ [VERIFIED] |
| 3 | happy | Recent rebuild qua stream sau đăng | `addPhoto`→`notifyListeners`→`Consumer2` (build:168) rebuild→`photoProvider.sortedPhotos` truyền lại→empty-state biến mất, list ngang hiện | ✅ [VERIFIED code] / 🟨 stream realtime [CẦN TEST RUNTIME] |
| 4 | happy | Link "Xem tất cả ảnh" → Gallery (HE3) | `_buildSectionTitle actionLabel:viewAllPhotos onActionTap:setState(_selectedIndex=1)` → tab Gallery | ✅ [VERIFIED] |
| 5 | edge | Loading (đang upload) disable CTA + nút empty | CTA: `onTap:null`+`Opacity(0.6)` khi `isLoading`; nút empty `onPressed:isLoading?null:...`. `isLoading` từ `photoProvider.isLoading` qua Consumer2→reactive | ✅ [VERIFIED] không double-pick |
| 6 | negative | Hủy picker (không chọn ảnh) | `pickedFile==null` → `return` no-op, không snackbar, không crash | ✅ [VERIFIED] |
| 7 | negative | Cancel caption dialog | `caption==null` (nhấn Cancel/dismiss) → `return` no-op, không đăng | ✅ [VERIFIED] |
| 8 | negative | Lỗi upload | try/catch → snackbar `errorMessage ?? photoAddError`, `return` | ✅ [VERIFIED code] / 🟨 trigger lỗi thật [CẦN TEST RUNTIME] |
| 9 | negative | `currentUser==null` | `_pickAndAddPhoto` return sớm, không crash | ✅ [VERIFIED] |
| 10 | edge | waiting_partner (couple 1 người) | CTA/nút KHÔNG gate `couple.status`; `addPhoto` chỉ check `currentUser.hasCouple` (photo_service:68). `isWaitingForPartner` chỉ dùng cho banner (home:498) | ✅ [VERIFIED] đăng được |
| 11 | regression | `_buildQuickActionCard` đã xóa | 0 reference trong `lib/`; key `memoriesCardTitle/profileCardTitle/updateInfo` không còn dùng trong lib | ✅ [VERIFIED] |
| 12 | regression | counter/milestone/quote/hero/banner/bottom-nav không đổi | diff Home chỉ chạm cụm CTA + empty-state + thêm helper; các widget khác nguyên | ✅ [VERIFIED] |
| 13 | regression | Gallery composer + `_pickAndAddPhoto` gốc không đổi | `git diff -- gallery_screen.dart` TRỐNG (0 thay đổi) | ✅ [VERIFIED] |
| 14 | regression | Bản copy `_pickAndAddPhoto` Home khớp gốc Gallery | So sánh từng dòng: picker single, caption dialog, try/catch, snackbar success/error — khớp hệt. Home `_showCaptionDialog` bỏ tham số `initialValue` (chỉ dùng add, không edit) — đúng, không lệch hành vi | ✅ [VERIFIED] |
| 15 | đa ngôn ngữ | `addMemoryCta`+`addMemoryCtaSubtitle` đủ vi+en | Có trong cả `app_vi.arb`+`app_en.arb`+generated `app_localizations_vi.dart`/`_en.dart`/`app_localizations.dart`; không hardcode | ✅ [VERIFIED] |
| 16 | đa ngôn ngữ | Tái dùng key sẵn có | `addPhotosPrompt`(subtitle CTA), `viewAllPhotos`(link), `postFirstPhotoBtn`(nút empty), `addPhotosEmpty`(chữ empty) đều tồn tại vi+en | ✅ [VERIFIED] |
| 17 | static | `fvm flutter analyze` | No issues found! | ✅ [VERIFIED] (ran 6.0s) |

*(Kết quả: ✅ pass · ❌ fail · ⬜ chưa chạy · 🟨 phần cần runtime)*

## Kết luận
**PASS (code-level)** — toàn bộ acceptance Phase 1 (overview §5) đạt ở mức đọc code:
- CTA "Thêm kỷ niệm" rose full-width thay cụm 2 quick-action; card "Cập nhật thông tin→Profile" trùng nav đã bỏ. ✅
- CTA + nút empty mở luồng đăng ảnh (`_pickAndAddPhoto` copy từ Gallery, single-pick), ở lại Home (HE4 — không setState tab sau đăng). ✅
- Empty-state có nút đăng ảnh đầu. ✅
- Vào Gallery vẫn được qua link "Xem tất cả ảnh". ✅
- i18n vi+en đủ, không hardcode. ✅
- `flutter analyze` sạch; token rose đúng design (accentRose, r20, shadow rose .28). ✅
- Không regression: Gallery composer KHÔNG đổi (diff trống), counter/milestone/quote/hero/banner/nav nguyên, `_buildQuickActionCard` xóa sạch. ✅

**Nợ kỹ thuật ghi nhận (KHÔNG phải bug — PO chốt Phase 1):** `_pickAndAddPhoto`+`_showCaptionDialog` bị **copy trùng** giữa Home và Gallery (~50 dòng). Bản copy đã verify khớp hành vi gốc.

## CẦN TEST RUNTIME (user smoke-test trên thiết bị thật)
1. Tap CTA → mở picker thật → chọn ảnh → caption → đăng → **ảnh xuất hiện ở recent photos (stream)** + **snackbar "Thêm ảnh thành công!"**, **không nhảy tab** (HE4). [cả nhánh Firebase và local fallback]
2. Empty-state (couple chưa có ảnh): nút "Đăng ảnh đầu tiên" → đăng ảnh đầu → card empty biến mất, list ngang hiện.
3. Loading: trong lúc upload, CTA mờ (Opacity .6) + không bấm lại được; nút empty disable (không double-pick).
4. waiting_partner (couple 1 người, B chưa join): CTA vẫn đăng được ảnh (chính chủ).
5. Hủy picker / Cancel caption: không crash, không snackbar.
6. Lỗi mạng/upload: snackbar lỗi (`photoAddError` hoặc message từ provider).
7. Đổi ngôn ngữ vi↔en: CTA title/subtitle + nút empty + link hiển thị đúng ngữ.

## Bug report
Không có bug. (FAIL: trống)

## Nhật ký test
- [2026-06-01] [Tester] Test Phase 1 home-engagement (code-level + analyze). 17 case: CTA "Thêm kỷ niệm" thay cụm quick-action + nút empty-state đăng ảnh, đều mở `_pickAndAddPhoto` (copy từ Gallery — verify khớp gốc, diff Gallery trống). Logic ở-lại-Home (HE4), loading disable cả 2 qua `photoProvider.isLoading` (Consumer2 reactive), hủy/cancel/lỗi/currentUser-null no-op không crash. waiting_partner đăng được (không gate couple.status). i18n `addMemoryCta`/`addMemoryCtaSubtitle` đủ vi+en (ARB+generated). `_buildQuickActionCard` xóa sạch (0 ref). `fvm flutter analyze` = No issues found!. **Verdict: PASS code-level**; còn 7 nhóm case CẦN TEST RUNTIME (picker thật/upload/snackbar/stream rebuild) chuyển user smoke-test.
