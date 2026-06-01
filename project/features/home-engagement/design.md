# 🎨 Design — Home engagement (Phase 1: đẩy đăng ảnh từ Home)

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`../../../CLAUDE.md` mục 8). CHỈ thiết kế, không code.

- **Trạng thái design:** xong
- **Người/role:** Designer

## Mục tiêu thiết kế
Biến Home từ "bảng trạng thái để ngắm" thành màn có **cú hích đăng ảnh** — đòn bẩy trực tiếp Metric Bắc Đẩu ("cặp active đăng ảnh hằng tuần").
1. Thay cụm 2 quick-action ("Xem ảnh→Gallery" + "Cập nhật thông tin→Profile" trùng nav) bằng **1 CTA chính rose "Thêm kỷ niệm"** mở thẳng luồng đăng ảnh, + **1 link phụ "Xem tất cả ảnh"** vào Gallery (giữ HE3).
2. Empty-state recent photos: thêm **nút rose "Đăng ảnh đầu tiên"** ngay trong card rỗng.

Tinh thần: tái dùng tối đa token + pattern nút từ Gallery composer (`gallery_screen.dart:789–827`, `:1452–1464`), không bịa token mới.

## User flow
```
Home (tab 0)
  │
  ├─ [CTA "Thêm kỷ niệm"]  ──tap──►  ImagePicker (single)  ──chọn ảnh──►  dialog caption (optional)
  │                                       │                                   │
  │                                   (hủy → no-op)                    (Cancel → no-op)
  │                                                                           │
  │                                                          PhotoProvider.addPhoto() ──► snackbar "Thêm ảnh thành công!"
  │                                                                           │
  │                                                          Ở LẠI Home; recent photos tự cập nhật qua stream (HE4)
  │
  ├─ [link "Xem tất cả ảnh"] ──tap──►  chuyển tab Gallery (_selectedIndex = 1)   (giữ HE3, không đổi)
  │
  └─ recent photos rỗng → card empty-state có nút [Đăng ảnh đầu tiên] ──tap──► cùng luồng "Thêm kỷ niệm" ở trên
```
Tái dùng nguyên `_pickAndAddPhoto()` (Gallery `:71–123`): picker single → caption dialog → addPhoto → snackbar. Không dựng luồng mới (HE2).

## Wireframe (ASCII)

### A. Cụm CTA — TRƯỚC (hiện tại, `home_screen.dart:511–538`)
```
┌─ "Khoảnh khắc nhanh" ─────────────────────────────┐   ← _buildSectionTitle
│   Lối tắt để xem lại câu chuyện của hai bạn        │
└────────────────────────────────────────────────────┘
┌───────────────────────┐  ┌───────────────────────┐
│ [🖼]                   │  │ [👤]                   │
│ Kỷ niệm                │  │ Hồ sơ                  │   ← 2 card trắng r20
│ Xem tất cả ảnh   →tab1 │  │ Cập nhật thông tin →2  │      (card phải TRÙNG nav)
└───────────────────────┘  └───────────────────────┘
```

### B. Cụm CTA — SAU (đề xuất)
```
┌─ "Khoảnh khắc nhanh" ──────────────────  Xem tất cả ảnh › ┐  ← title + action link phụ (vào Gallery)
│   Lưu lại một kỷ niệm mới của hai bạn                      │     subtitle đổi sang câu mời đăng ảnh
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│  ╭──────╮                                                    │
│  │  📷+ │   Thêm kỷ niệm                              ›      │  ← CTA chính: card ROSE đặc, full-width
│  ╰──────╯   Đăng một tấm ảnh mới cho cả hai cùng xem         │     icon tile glass trắng + 2 dòng chữ trắng
└────────────────────────────────────────────────────────────┘
```
- Bỏ hẳn card "Hồ sơ → Cập nhật thông tin" (trùng bottom nav tab 2).
- "Xem tất cả ảnh" chuyển thành **action link ở header section** (tái dùng `actionLabel`/`onActionTap` có sẵn của `_buildSectionTitle:720–755`) — gọn, vẫn giữ lối vào Gallery (HE3).

### C. Empty-state recent photos — TRƯỚC (`:996–1031`)
```
┌────────────────────────────────────────────┐
│                  🖼 (icon mờ 42px)           │
│   Thêm vài ảnh để bắt đầu lấp đầy bức thư    │   ← card trắng r24, chỉ icon + chữ, KHÔNG nút
│   tình này.                                  │
└────────────────────────────────────────────┘
```

### D. Empty-state recent photos — SAU
```
┌────────────────────────────────────────────┐
│                  🖼 (icon mờ 42px)           │
│   Thêm vài ảnh để bắt đầu lấp đầy bức thư    │
│   tình này.                                  │
│                                              │
│           ╭───────────────────────╮          │
│           │ 📷  Đăng ảnh đầu tiên  │          │   ← FilledButton.icon rose r18 (pattern Gallery :1452)
│           ╰───────────────────────╯          │
└────────────────────────────────────────────┘
```

## Spec chi tiết (token chính xác)

### 1. CTA chính "Thêm kỷ niệm" (card rose full-width)
Đây là điểm nhấn duy nhất → dùng **nền rose đặc** (khác với 2 card trắng cũ) để nó "pop".

| Thuộc tính | Giá trị |
|---|---|
| Layout | `Container` full-width (`width: double.infinity`), `Row` |
| Nền | `AppColors.accentRose` (#FF4D6D) đặc — KHÔNG gradient (giữ CTA "phẳng & dứt khoát") |
| Radius | `20` (khớp radius card quick-action cũ `_buildQuickActionCard:771`) |
| Padding | `EdgeInsets.all(16)` |
| Shadow | `BoxShadow(color: AppColors.accentRose.withValues(alpha: 0.28), blurRadius: 18, offset: Offset(0, 10))` — bóng hue-matched (cùng tinh thần `AppColors.softCardShadow`, nhưng theo rose vì nền rose) |
| Icon tile | `Container` padding `12`, `BoxColor: white .18`, radius `14`; `Icon(Icons.add_a_photo_rounded, color: white, size: 22)` (khớp icon nút đăng Gallery `:804`) |
| Gap icon→text | `SizedBox(width: 14)` |
| Title | "Thêm kỷ niệm" — `color: white, fontSize: 16, fontWeight: w700, letterSpacing: -0.2` |
| Gap title→sub | `SizedBox(height: 3)` |
| Subtitle | "Đăng một tấm ảnh mới cho cả hai cùng xem" — `color: white.withValues(alpha: 0.85), fontSize: 12, height: 1.35` |
| Chevron | `Icon(Icons.chevron_right_rounded, color: white.withValues(alpha: 0.7), size: 22)` cuối Row (affordance "mở luồng") |
| Tap target | bọc `GestureDetector`/`InkWell` toàn card → `_pickAndAddPhoto` |

### 2. Section title của cụm CTA (tái dùng `_buildSectionTitle`)
- `title`: giữ `l10n.quickMomentsTitle` ("Khoảnh khắc nhanh").
- `subtitle`: **đổi** sang `l10n.addPhotosPrompt` ("Thêm vài ảnh để bắt đầu thư tình của hai bạn") — đã có sẵn, hợp ngữ cảnh đăng ảnh hơn `quickMomentsSubtitle` ("Lối tắt để xem lại..."). *(Tùy chọn nhẹ — nếu Dev muốn tránh đụng key, giữ nguyên `quickMomentsSubtitle` cũng chấp nhận; ưu tiên `addPhotosPrompt`.)*
- `actionLabel`: `l10n.viewAllPhotos` ("Xem tất cả ảnh").
- `onActionTap`: `() => setState(() => _selectedIndex = 1)` (vào Gallery — HE3).
- Style action link: tái dùng nguyên TextButton trắng có sẵn (`_buildSectionTitle:745–753`, `foregroundColor: white`) → khớp nền gradient Home.

### 3. Nút "Đăng ảnh đầu tiên" trong empty-state
Tái dùng **đúng pattern** `FilledButton.icon` ở Gallery empty-state (`:1452–1464`):

| Thuộc tính | Giá trị |
|---|---|
| Widget | `FilledButton.icon` |
| `backgroundColor` | `AppColors.accentRose` |
| `foregroundColor` | `AppColors.white` |
| Padding | `EdgeInsets.symmetric(horizontal: 20, vertical: 14)` |
| Shape | `RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))` |
| Icon | `Icon(Icons.add_photo_alternate_rounded)` (khớp Gallery `:1462`) |
| Label | `l10n.postFirstPhotoBtn` ("Đăng ảnh đầu tiên") |
| `onPressed` | `isLoading ? null : _pickAndAddPhoto` (xem States) |
| Vị trí | thêm vào cuối `Column` của card empty (`home_screen.dart:1011–1028`), trên cùng cách chữ `SizedBox(height: 18)` |

Card empty giữ nguyên: nền white, radius 24, shadow (`black .06`, blur 16, offset (0,10)), icon mờ 42px, chữ `addPhotosEmpty`.

## States

| State | CTA chính "Thêm kỷ niệm" | Nút empty-state | Ghi chú |
|---|---|---|---|
| **Idle** | rose đặc, tap được | rose, tap được | mặc định |
| **Loading** (đang upload) | **disable** — `onPressed: null`, giảm cảm giác bấm; theo Gallery dùng `context.watch<PhotoProvider>().isLoading` | **disable** tương tự (`isLoading ? null : ...`) | tránh double-pick (rủi ro 🟡 overview §6). `BlockingLoadingOverlay` của Gallery KHÔNG có ở Home — nên disable nút là cơ chế chính. Khi disable, `FilledButton`/card mờ đi theo Material default; với card GestureDetector custom: khi `isLoading` set `onTap: null` + `Opacity(0.6)` bọc card. |
| **Empty** (chưa có ảnh) | vẫn hiện CTA chính như bình thường | card empty hiện (thay danh sách ảnh ngang) | CTA chính LUÔN hiện bất kể có ảnh hay chưa |
| **Sau-đăng (success)** | trở về Idle | — (đã có ảnh → card empty biến mất, list ngang hiện) | ở lại Home (HE4); snackbar `photoAddedSuccess`; recent tự cập nhật qua `PhotoProvider` stream → `Consumer`/`context.watch` rebuild |
| **Error** | trở về Idle | trở về Idle | snackbar `photoAddError` (tái dùng nguyên try/catch của `_pickAndAddPhoto`) |
| **Hủy picker / Cancel caption** | no-op, không toast, không crash | no-op | đã xử lý sẵn trong `_pickAndAddPhoto` (`pickedFile == null` / `caption == null` → return) |

> **Lưu ý về loading visual:** Home không bọc `BlockingLoadingOverlay` (Gallery có). Để nhất quán & cho user feedback khi upload, Dev có 2 lựa chọn (PO/Dev chốt — không đổi design):
> (a) **đủ dùng:** chỉ disable nút (như Gallery composer làm với nút trong header), upload nhanh nên không cần overlay; HOẶC
> (b) **nicer:** bọc nhánh Home content bằng `BlockingLoadingOverlay(isVisible: photoProvider.isLoading, ...)` giống Gallery để có spinner toàn màn. Khuyến nghị (a) cho Phase 1 (gọn, ít regression).

## Interaction & animation
- Tap CTA chính / nút empty → mở `ImagePicker` **single** (`ImageSource.gallery`) — tái dùng `_pickAndAddPhoto`. **Không** thêm nút "nhiều ảnh" ở Home (giữ Home gọn, 1 hành động chính; multi-add vẫn có đầy đủ ở Gallery composer). *Quyết định: single-pick ở Home — ít lựa chọn = chuyển đổi cao hơn cho CTA chính.*
- Press feedback: `FilledButton` có ripple Material mặc định (nút empty). Card CTA custom (GestureDetector) — không bắt buộc animation; nếu muốn thêm, dùng `InkWell` (ripple trắng `.12`) hoặc `AnimatedScale 0.97` 120ms — **tùy chọn, không bắt buộc Phase 1**, theo dải design system (200–320ms easeOutCubic nếu thêm).
- Không có animation mới bắt buộc. Snackbar dùng theme sẵn (navy floating r20).

## Copy (song ngữ — bắt buộc)

### Tái dùng key sẵn có (KHÔNG tạo mới)
| Key | VI | EN | Dùng ở |
|---|---|---|---|
| `quickMomentsTitle` | Khoảnh khắc nhanh | Quick moments | title cụm CTA |
| `addPhotosPrompt` | Thêm vài ảnh để bắt đầu thư tình của hai bạn | Add a few photos to start your love letter | subtitle cụm CTA (thay `quickMomentsSubtitle`) |
| `viewAllPhotos` | Xem tất cả ảnh | View all photos | action link phụ → Gallery |
| `postFirstPhotoBtn` | Đăng ảnh đầu tiên | Post first photo | nút empty-state |
| `addPhotosEmpty` | Thêm vài ảnh để bắt đầu lấp đầy bức thư tình này. | Add a few photos to start filling this love letter. | chữ empty-state (giữ nguyên) |
| `photoAddedSuccess` | Thêm ảnh thành công! | Photo added successfully! | snackbar (kế thừa từ `_pickAndAddPhoto`) |
| `photoAddError` | (đã có) | (đã có) | snackbar lỗi (kế thừa) |

### Key MỚI cần thêm (1 nhóm — CTA chính)
| Key | VI | EN |
|---|---|---|
| `addMemoryCta` | Thêm kỷ niệm | Add a memory |
| `addMemoryCtaSubtitle` | Đăng một tấm ảnh mới cho cả hai cùng xem | Post a new photo for you both to keep |

> Không tái dùng được `postNewPhotoBtn` ("Đăng ảnh mới") cho CTA chính vì copy CTA muốn "Thêm kỷ niệm" (hướng cảm xúc/giá trị, không phải tên thao tác kỹ thuật). Subtitle cần 1 dòng mô tả riêng → key mới. Nếu PO/Dev muốn TỐI THIỂU key mới: có thể dùng `addMemoryCta` cho title + bỏ subtitle (chỉ 1 dòng) → khi đó CTA chỉ cần **1 key mới**. Designer khuyến nghị giữ subtitle (rõ ràng giá trị "cả hai cùng xem"); để PO quyết.

## Handoff / Dev notes
- **⚠️ L10n [PO sửa 2026-06-01]:** Chỉ dẫn "hand-maintained" ở trên SAI (memory cũ đã stale; ghi chú lịch sử ở `language/`/`custom-reminders/` mô tả bug TRƯỚC bản fix 2026-05-31). **Cách ĐÚNG (CLAUDE.md mục 7):** thêm key vào CẢ `lib/l10n/app_en.arb` + `app_vi.arb` rồi chạy **`fvm flutter gen-l10n`** để sinh getter trong `app_localizations*.dart`. KHÔNG hand-edit file generated. Project có `l10n.yaml` + `generate:true`; PO đã verify gen-l10n an toàn.
- **Vị trí sửa code:**
  - Thay cụm quick-action: `home_screen.dart:516–538` (Row 2 card) → 1 widget CTA chính full-width. `_buildQuickActionCard` (`:758–813`) có thể **xóa hoặc giữ** (nếu không còn chỗ gọi thì xóa để analyze sạch — kiểm tra không còn reference).
  - Section title cụm CTA: `:511–514` đổi `subtitle` + thêm `actionLabel: l10n.viewAllPhotos` + `onActionTap`.
  - Empty-state: `:1011–1028` thêm `SizedBox(height: 18)` + `FilledButton.icon`.
- **Luồng đăng ảnh:** Home `home_screen.dart` cần có hàm tương đương `_pickAndAddPhoto` (copy pattern từ Gallery `:71–123`). `PhotoProvider`, `AuthProvider`, `ImagePicker`, `_showCaptionDialog` đều dùng được ở Home (PhotoProvider là top-level provider — overview §2). Dev cân nhắc tách helper dùng chung nếu muốn, nhưng KHÔNG bắt buộc (tránh refactor lan rộng — Phase 1 ship gọn).
- **`isLoading`:** đọc qua `context.watch<PhotoProvider>().isLoading` để disable cả CTA chính lẫn nút empty (giống Gallery). Nếu Home build trong `Consumer` rồi thì dùng giá trị từ đó.
- **HE4 (ở lại Home):** KHÔNG navigate sang Gallery sau khi đăng. Recent photos rebuild tự động vì PhotoProvider notify.
- **Không đổi:** counter/milestone/quote/hero/banner-chờ-partner/bottom-nav/Gallery composer — giữ nguyên (acceptance §5, §7 overview).
- **`waiting_partner`:** CTA vẫn hiển thị & đăng được khi couple chỉ 1 người (chính chủ đăng) — không gate theo `couple.status` (rủi ro 🟡 overview §6).

## Acceptance (design)
- [x] Mọi state có hình/mô tả (idle/loading/empty/success/error/hủy)
- [x] Copy đủ VI+EN (tái dùng 7 key + 2 key mới, có phương án 1-key)
- [x] Dev dựng được không cần hỏi lại (token chính xác, vị trí code, lưu ý l10n hand-maintained)

## Nhật ký design
- [2026-06-01] [Designer] Thiết kế Phase 1 home-engagement: (1) thay cụm 2 quick-action bằng 1 CTA chính rose full-width "Thêm kỷ niệm" (nền accentRose, r20, icon tile glass trắng, title+subtitle trắng, chevron) mở thẳng luồng `_pickAndAddPhoto` (single-pick) + giữ lối vào Gallery qua action link "Xem tất cả ảnh" ở header section (HE3); bỏ card "Hồ sơ→Cập nhật thông tin" trùng nav. (2) Thêm nút rose "Đăng ảnh đầu tiên" (FilledButton.icon, pattern Gallery :1452) vào empty-state recent photos. States idle/loading(disable theo PhotoProvider.isLoading)/empty/success(ở lại Home, stream rebuild — HE4)/error/hủy. Copy tái dùng 7 key sẵn có + đề xuất 2 key mới (`addMemoryCta`/`addMemoryCtaSubtitle`, kèm phương án tối thiểu 1 key). Lưu ý Dev: l10n hand-maintained (không gen-l10n). Bám design system, không bịa token mới.
