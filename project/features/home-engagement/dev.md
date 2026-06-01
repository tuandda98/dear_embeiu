# 💻 Dev — Home engagement (Phase 1: đẩy đăng ảnh từ Home)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** xong / chờ test
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:*
  - Thay **cụm 2 quick-action** (`Row` 2 card trắng) bằng **1 CTA chính rose full-width** `_buildAddMemoryCta(l10n, isLoading)` mở thẳng luồng đăng ảnh single-pick. Bỏ hẳn card "Hồ sơ→Cập nhật thông tin".
  - Giữ lối vào Gallery (HE3) bằng cách thêm `actionLabel: l10n.viewAllPhotos` + `onActionTap: () => setState(() => _selectedIndex = 1)` vào `_buildSectionTitle` của cụm CTA (tái dùng sẵn) + đổi `subtitle` sang `l10n.addPhotosPrompt`.
  - Empty-state recent photos: thêm `FilledButton.icon` rose "Đăng ảnh đầu tiên" — **copy đúng pattern** Gallery `:1452–1464` (bg accentRose, fg white, padding 20/14, r18, icon `add_photo_alternate_rounded`, label `postFirstPhotoBtn`).
  - **Luồng đăng ảnh: copy nguyên `_pickAndAddPhoto()` + `_showCaptionDialog()` từ Gallery vào `home_screen.dart`** (KHÔNG tách helper dùng chung — tránh refactor lan rộng, Phase 1 ship gọn theo Dev note design §174). Hành vi giống hệt Gallery: picker single → caption dialog (Cancel → no-op) → `PhotoProvider.addPhoto` → snackbar success/error. Kế thừa hành vi cả nhánh Firebase lẫn local fallback.
  - **Loading = phương án (a):** truyền `photoProvider.isLoading` từ `Consumer2` (build site `:187`) xuống `_buildHomeTab(..., bool isUploadingPhoto, ...)`; CTA `onTap: null` + `Opacity(0.6)` khi loading; nút empty `onPressed: isLoading ? null : _pickAndAddPhoto`. KHÔNG bọc `BlockingLoadingOverlay`.
- *File/hàm đụng tới:*
  - `lib/screens/home_screen.dart`:
    - import thêm `image_picker` + `providers/auth_provider.dart`.
    - `_buildHomeTab(...)` thêm tham số `bool isUploadingPhoto`; call site `Consumer2` truyền `photoProvider.isLoading`.
    - Cụm CTA: thay `_buildSectionTitle` + `Row(2 card)` bằng `_buildSectionTitle(... actionLabel/onActionTap ...)` + `_buildAddMemoryCta(l10n, isUploadingPhoto)`.
    - `_buildRecentPhotosSection(List<Photo>, bool isLoading, AppLocalizations)` — thêm tham số loading + nút empty-state.
    - **XÓA** `_buildQuickActionCard` (mồ côi sau khi bỏ cụm 2 card — đã verify không còn reference).
    - THÊM `_buildAddMemoryCta`, `_showCaptionDialog`, `_pickAndAddPhoto`.
  - `lib/l10n/app_en.arb` + `app_vi.arb`: thêm 2 key `addMemoryCta` + `addMemoryCtaSubtitle`.
- *Thay đổi model / Firestore / Cloud Function / native config:* KHÔNG.
- *Cần deploy?* Không.

## L10n
- 2 key MỚI thêm vào CẢ 2 ARB rồi `fvm flutter gen-l10n` (KHÔNG hand-edit Dart — theo OVERRIDE PO + CLAUDE.md mục 7):
  - `addMemoryCta`: VI "Thêm kỷ niệm" / EN "Add a memory"
  - `addMemoryCtaSubtitle`: VI "Đăng một tấm ảnh mới cho cả hai cùng xem" / EN "Post a new photo for you both to keep"
- Tái dùng: `quickMomentsTitle`, `addPhotosPrompt`, `viewAllPhotos`, `postFirstPhotoBtn`, `addPhotosEmpty`, `photoAddedSuccess`, `photoAddError`, `addCaptionOptionalTitle`, `addCaptionOptionalHint`, `cancel`, `save`.
- 3 key cũ giờ KHÔNG còn dùng trong `lib/` (`memoriesCardTitle`, `profileCardTitle`, `updateInfo`) — giữ trong ARB (getter sinh ra vô hại), không xóa để tránh đụng generated.

## Edge case kỹ thuật cần xử lý
- Hủy picker (`pickedFile == null`) hoặc Cancel caption (`caption == null`) → `return` no-op, không toast, không crash (kế thừa từ pattern Gallery).
- `currentUser == null` → return sớm (không crash).
- `waiting_partner` (1 người): CTA không gate theo `couple.status` → chính chủ đăng được.
- Double-pick: CTA + nút empty disable khi `isLoading`.
- `mounted` guard sau mỗi await async (giữ nguyên từ pattern Gallery).

## Checklist implement
- [x] CTA chính rose "Thêm kỷ niệm" full-width thay cụm 2 quick-action
- [x] Bỏ card "Hồ sơ→Cập nhật thông tin"
- [x] Action link "Xem tất cả ảnh" ở section title → tab Gallery (HE3)
- [x] Subtitle cụm CTA = `addPhotosPrompt`
- [x] Nút "Đăng ảnh đầu tiên" ở empty-state (pattern Gallery)
- [x] Loading disable CTA + nút empty qua `photoProvider.isLoading` (phương án a)
- [x] Single-pick, ở lại Home sau đăng (HE4), recent rebuild qua stream
- [x] Xóa `_buildQuickActionCard` (analyze sạch)
- [x] 2 key l10n mới qua ARB + gen-l10n
- [x] `flutter analyze` sạch (No issues found!)
- [x] Không hardcode chuỗi/ngôn ngữ (qua l10n)

## Nhật ký implement
- [2026-06-01] [Dev] Implement Phase 1 home-engagement: thay cụm 2 quick-action bằng CTA chính rose full-width "Thêm kỷ niệm" (`_buildAddMemoryCta`, nền accentRose r20 pad16 shadow rose .28, icon tile glass trắng add_a_photo_rounded, title white w700 + subtitle white .85 + chevron) mở luồng `_pickAndAddPhoto` (copy từ Gallery, single-pick). Giữ lối vào Gallery qua action link "Xem tất cả ảnh" ở section title; subtitle đổi `addPhotosPrompt`. Thêm nút rose "Đăng ảnh đầu tiên" (FilledButton.icon, pattern Gallery) vào empty-state recent. Loading disable cả 2 qua `photoProvider.isLoading` (phương án a, không BlockingLoadingOverlay). Xóa `_buildQuickActionCard` mồ côi. Thêm 2 key `addMemoryCta`/`addMemoryCtaSubtitle` vào ARB + `fvm flutter gen-l10n`. `fvm flutter analyze` sạch (No issues found!).
