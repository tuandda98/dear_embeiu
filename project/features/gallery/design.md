# 🎨 Design — Gallery

> Designer sở hữu. Đọc [overview.md](overview.md). Bám design system (`../../../CLAUDE.md` mục 8).

- **Trạng thái design:** ✅ Đã có (baseline)

## Hiện trạng UI (đã ship)
- **Feed dọc** (KHÔNG grid). CustomScrollView: SliverPersistentHeader co giãn (expanded 340/compact 122, snap 250ms) chứa composer card (avatar gradient + nút thêm 1/nhiều ảnh + marquee chip) → CTA "hôm nay" → feed card (avatar+tên+time+menu, ảnh Hero 4:5 bo 26, caption) ngăn theo tháng.
- **Fullscreen preview:** PageView swipe, InteractiveViewer pinch zoom (max 4×), drag-to-dismiss dọc (nền fade .94→.2, threshold 140px), panel info + nút edit/close.

## Đề xuất cải thiện (bàn PO — gắn retention)
- **Reactions ❤️ trên ảnh** (roadmap NOW) — thiết kế nút thả tim + hiển thị + push.
- Thiết kế giới hạn/nén ảnh (UX khi ảnh quá lớn) + trạng thái offline rõ ("chưa đồng bộ").
- Empty state đẹp khi chưa có ảnh.

## Copy (song ngữ)
Key gallery (upload/caption/delete…) đã có VI+EN.

---

# 🆕 CreatePostScreen — màn "Tạo kỷ niệm" full-screen (redesign 2026-06-14)

> Thay thế `_GalleryDraftSheet` (bottom sheet tạm bợ) bằng **1 màn full-screen pushed route** phong cách "create post" của Facebook/Instagram, áp cho CẢ 2 luồng đăng ảnh: **(a) Thêm hình** (chọn nhiều ảnh từ thư viện) và **(b) Chụp hình** (chụp 1 ảnh từ camera). Sau redesign này, **camera KHÔNG còn đăng thẳng** — cả 2 luồng đều dừng ở màn compose để xem trước + nhập caption rồi mới đăng.
>
> ⚠️ Designer-only spec. Dev đọc + dựng. Bám 100% token Design Unify 2026-06-11 (`design-system.md` mục ⭐).

## 1. Mục tiêu
- Biến bước đăng ảnh thành 1 màn "soạn bài" tươm tất, có chủ ý — giống IG/FB "create post" — để cảm giác đăng kỷ niệm có nghi thức, đẹp, riêng tư.
- 1 màn DUY NHẤT (`CreatePostScreen`) phục vụ cả entry camera (1 ảnh) lẫn entry thư viện (N ảnh). Khác biệt 2 luồng chỉ ở **dữ liệu đầu vào** (1 vs nhiều ảnh) và **layout khu ảnh** (ảnh lớn vs lưới), KHÔNG phải 2 màn riêng.
- Caption CHUNG cho cả batch (model hiện tại chỉ có 1 caption/batch — `addPhotosBatch(..., caption)`), KHÔNG caption-per-ảnh (out of scope, ghi ở Dev notes).

## 2. Phạm vi / màn hình
- **MỚI:** `lib/screens/create_post_screen.dart` → `CreatePostScreen` (StatefulWidget, full-screen route).
- **SỬA luồng gọi (gallery_screen.dart):**
  - `_pickMultiplePhotos()` → sau `pickMultiImage`, **push `CreatePostScreen`** (entry = library, ảnh = N file) thay vì `showModalBottomSheet(_GalleryDraftSheet)`.
  - `_pickAndAddPhoto()` (camera) → sau `pickImage(camera)`, **push `CreatePostScreen`** (entry = camera, ảnh = 1 file) thay vì gọi thẳng `addPhoto`.
  - **GỠ** `_GalleryDraftSheet` + `_GalleryDraftResult` (cuối file ~2664–2879).
- Composer card trong header gallery (`_buildComposerCard`) GIỮ NGUYÊN — vẫn là 2 nút "Chụp hình" + "Thêm hình" kích hoạt 2 luồng trên. (Chỉ đổi cái mở ra sau khi pick.)
- Out of scope màn này: edit caption ảnh đã đăng (giữ flow cũ), reactions, preview fullscreen.

## 3. User flow

```
GALLERY composer card
 ├─ [Chụp hình] → camera (pickImage) ──┐
 │                                     ├─→ push CreatePostScreen(files, entry)
 └─ [Thêm hình] → thư viện (pickMulti)─┘
                                          │
              ┌───────────────────────────┴───────────────────────────┐
              │ CreatePostScreen                                        │
              │  - xem trước ảnh (gỡ ảnh, thêm ảnh từ thư viện)         │
              │  - nhập caption chung (tuỳ chọn)                        │
              │  - nhấn "Đăng"                                          │
              └───────────────────────────┬───────────────────────────┘
                                           │ pop(CreatePostResult{files, caption})
                                           ▼
        gallery gọi addPhotosBatch(paths, caption, progress)  ← LUÔN dùng batch
        (1 ảnh camera cũng đi qua batch để thống nhất overlay "Đang đăng x/N")
                                           │
                          ┌────────────────┴───────────────┐
                          │ thành công → snackbar + haptic   │
                          │ 1 phần lỗi → snackbar partial     │
                          └──────────────────────────────────┘
```

**Quy ước trả về (giống `_GalleryDraftResult` cũ):** `pop(null)` hoặc `pop` với `files` rỗng = HUỶ, không đăng gì. `pop(CreatePostResult)` với `files.isNotEmpty` = đăng.

**Quyết định luồng camera:** camera vẫn chỉ chụp 1 ảnh/lần (`pickImage`), nhưng sau khi vào màn compose user CÓ THỂ bấm "Thêm ảnh" để bổ sung từ thư viện → biến thành nhiều ảnh. Vì vậy cùng 1 màn, cùng 1 đường ra `addPhotosBatch`. (Lý do dùng batch cho cả 1 ảnh: 1 overlay "Đang đăng 1/1" thống nhất, không nhánh code riêng.)

## 4. Quyết định thẩm mỹ (giải thích ngắn)
| Quyết định | Chọn | Lý do |
|---|---|---|
| Kiểu màn | **Full-screen pushed route** (`Navigator.push`, `MaterialPageRoute` hoặc `PageRouteBuilder` slide-up) | User chê bottom sheet tạm bợ; IG/FB create-post là full-screen → có không gian cho ảnh lớn + caption + thêm ảnh. |
| Nền | **dawnBlush** (gradient nền chung toàn app) | Design Unify: "nền mọi màn = dawnBlush". IG/FB nền trắng vì app trắng; app này nền hồng là bản sắc "Sunset Romance" — giữ nền hồng, nội dung đặt trên **ContentCard trắng đặc** để đọc rõ (đúng quy tắc card nội dung). Nền trắng phẳng sẽ lạc tông toàn app. |
| Caption đặt đâu | **TRÊN khu ảnh** (kiểu FB: author row → caption to → ảnh) | App couples nặng cảm xúc — lời nhắn đi trước, ảnh minh hoạ theo sau, giống 1 dòng nhật ký. IG đặt caption cạnh thumbnail nhỏ vì IG là ảnh-first; ở đây "kỷ niệm" = ảnh + lời, lời lên trên thân thiện hơn. |
| Khu nhiều ảnh | **Lưới (grid) IG-style**, KHÔNG carousel | Grid cho thấy TOÀN BỘ ảnh đã chọn cùng lúc → dễ soát/gỡ; carousel giấu ảnh sau, khó kiểm. |
| Khu 1 ảnh (camera) | **1 ảnh LỚN ratio 4:5** | 4:5 = đúng ratio feed gallery hiện tại (ảnh Hero 4:5 bo 26) → preview khớp kết quả thật. |
| Nút Đăng | **Pill rose ở app bar phải** (không full-width đáy) | FB/IG để "Post/Share" ở góc trên phải; quen tay, giải phóng đáy cho ảnh. Rose = "hành động tình cảm" theo token. |

## 5. Wireframe ASCII

### (a) Màn NHIỀU ảnh (entry = thư viện)
```
┌─────────────────────────────────────────────┐  ← nền dawnBlush (gradient)
│ ╳                              ┌──────────┐  │  SafeArea top, pad H16 top14
│ (close 44)                     │  Đăng    │  │  app-bar row: X trái · pill rose phải
│                                └──────────┘  │
│                                               │
│ ┌───────────────────────────────────────────┐│  ← ContentCard trắng r24, mH16
│ │ (◯)  em ♥ anh tuan                         ││  author row: avatar 44 + tên
│ │ 44   Đăng bởi em · Hôm nay                 ││  + "Đăng bởi em · <ngày>"
│ │                                             ││
│ │ ┌─────────────────────────────────────────┐││  caption — không viền cứng
│ │ │ Hôm nay của hai bạn có gì?…              │││  multiline auto-grow
│ │ │                                         │││  (placeholder textTertiary)
│ │ └─────────────────────────────────────────┘││
│ │ ─────────────────────────────────────────  ││  hairline divider .06
│ │ ┌────────┐ ┌────────┐ ┌────────┐           ││  GRID ảnh 3 cột, r14
│ │ │ img ╳  │ │ img ╳  │ │ img ╳  │           ││  mỗi ô vuông, nút ╳ góc phải
│ │ ├────────┤ ├────────┤ ├────────┤           ││
│ │ │ img ╳  │ │ img ╳  │ │  ＋     │           ││  ô cuối = "+ Thêm ảnh"
│ │ └────────┘ └────────┘ └ Thêm ─┘           ││
│ │           "5 ảnh"                          ││  đếm số ảnh micro-caps
│ └───────────────────────────────────────────┘│
│                                               │  (cuộn được nếu nhiều ảnh)
└─────────────────────────────────────────────┘
```

### (b) Màn 1 ảnh (entry = camera)
```
┌─────────────────────────────────────────────┐  ← nền dawnBlush
│ ╳                              ┌──────────┐  │
│ (close)                        │  Đăng    │  │
│                                └──────────┘  │
│ ┌───────────────────────────────────────────┐│  ContentCard r24
│ │ (◯)  em ♥ anh tuan                         ││
│ │ 44   Đăng bởi em · Hôm nay                 ││
│ │ ┌─────────────────────────────────────────┐││
│ │ │ Viết gì đó cho khoảnh khắc này…         │││  caption
│ │ └─────────────────────────────────────────┘││
│ │ ──────────────────────────────────────────  │
│ │ ┌─────────────────────────────────────────┐││  ẢNH LỚN 4:5, r16
│ │ │                                  ╳      │││  nút ╳ góc phải trên
│ │ │            (ảnh vừa chụp)               │││
│ │ │                                         │││
│ │ │                                         │││
│ │ └─────────────────────────────────────────┘││
│ │ ┌─────────────────────────────────────────┐││  hàng "+ Thêm ảnh" full-width
│ │ │  ＋  Thêm ảnh từ thư viện                │││  dashed/tint rose r16
│ │ └─────────────────────────────────────────┘││
│ └───────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```
> Khi entry=camera mà user bấm "Thêm ảnh" → có ≥2 ảnh → layout TỰ chuyển sang grid (a). Ngưỡng: `files.length == 1` → ảnh lớn; `>= 2` → grid. Đây là quy tắc layout DUY NHẤT phân biệt 2 trạng thái, không phụ thuộc entry.

## 6. Spec chi tiết từng vùng

### 6.1 Scaffold + nền
- `Scaffold` `backgroundColor: Colors.transparent`, body bọc `Container(decoration: BoxDecoration(gradient: AppColors.dawnBlush))` full-screen (KHÔNG dùng nền chung tab — đây là route riêng, tự vẽ nền).
- `extendBodyBehindAppBar: false`. Dùng `SafeArea` (top + bottom).
- Route: `MaterialPageRoute(fullscreenDialog: true)` → iOS cho transition slide-up + cử chỉ đóng quen thuộc của "modal page". (Hoặc `PageRouteBuilder` slide-from-bottom 280ms easeOutCubic nếu muốn khớp `AppMotion`.) **Chốt: `fullscreenDialog: true`** (semantic đúng "tạo mới").
- Resize theo bàn phím: dùng `resizeToAvoidBottomInset: true` + thân là `SingleChildScrollView` để caption không bị che.

### 6.2 App bar (custom, KHÔNG `subScreenAppBar` — đây là màn tạo-mới chứ không phải sub-screen điều hướng)
- 1 `Row` trong padding `EdgeInsets.fromLTRB(16, 14, 16, 8)`:
  - **Trái — nút đóng:** `HeaderIconButton(icon: LucideIcons.x, semanticsLabel: l10n.cancel, onTap: _onClose)`. 44×44, icon 24 navy `textPrimary`, ripple r16.
  - **Spacer**.
  - **Phải — nút Đăng (primary pill):** pill r999, height **40** (gọn hơn 52 của full-width vì nằm app bar), padding `EdgeInsets.symmetric(horizontal: 20)`.
    - Nền `accentLove` (#FF4D6D); chữ trắng 15 w700; icon `LucideIcons.send` 16 đứng trước label (gap 7).
    - **Disabled** (khi `files.isEmpty`): nền `accentLove .40`, chữ trắng .9, không tap. (Thực tế files rỗng hiếm khi xảy ra vì gỡ hết ảnh sẽ tự đóng — xem States.)
    - Đang đăng: nút KHÔNG hiện spinner ở đây (overlay toàn màn lo) — nhưng disable trong lúc đang pop+upload để tránh double-tap.
- KHÔNG có title ở giữa app bar (IG/FB create-post cũng không). Tên màn truyền tải qua author row + caption hint. *(Nếu muốn 1 nhãn nhỏ: đặt `l10n.createPostTitle` ở giữa app bar 16 w700 navy `textPrimary` — TUỲ CHỌN, mặc định BỎ cho thoáng.)*

### 6.3 ContentCard bao nội dung
- `ContentCard` (trắng đặc r24, shadow black .06 blur 16 offset(0,10)) — widget chung `lib/widgets/content_card.dart`. Margin ngoài `EdgeInsets.symmetric(horizontal: 16)`, padding trong `EdgeInsets.all(16)`.
- Bên trong xếp dọc: author row → (gap 14) caption → (gap 14) divider hairline → (gap 14) khu ảnh → (gap 12) hàng đếm/thêm.

### 6.4 Author row (header 1 post)
- `Row(crossAxisAlignment: start)`:
  - **Avatar:** tái dùng `_buildCoupleAvatar(couple, size: 44)` (tròn, gradient `primaryGradient` / ảnh couple, viền trắng .9 2px, fallback initials w800). Dev: tách `_buildCoupleAvatar` ra widget dùng chung hoặc copy logic (`SharedCouplePhotoView` + initials).
  - gap **10**.
  - **Cột phải (Expanded):**
    - Dòng 1: `AnimatedCoupleName(person1Name, person2Name, creatorUserId, heartSize: 14, heartColor: accentRose)` style `textPrimary` 15 w700 ls-0.15 height1.2. (KHÔNG kèm "hôm nay có gì mới?" — đây là tên thuần như header post FB.)
    - gap **3**.
    - Dòng 2 (meta): `l10n.createPostAuthorMeta(authorName, dateLabel)` → "Đăng bởi {name} · {ngày}". Style `textSecondary` 12 w500 height1.4. `{name}` = `currentUser.displayName` (chính là "em" — tên user đang đăng). `{ngày}` = `DateFormat.yMMMMd(locale).format(now)` (D3 — truyền locale), hoặc rút gọn `l10n.today` nếu là hôm nay. **Chốt:** hiện "Hôm nay" (`l10n.today`) cho gần gũi, vì ảnh luôn đăng ở thời điểm hiện tại.
  - **KHÔNG** có icon "quyền riêng tư" kiểu FB (couple luôn private) — bỏ cho gọn.

### 6.5 Caption (ô nhập lớn, không viền cứng)
- `TextField` đặt TRÊN ảnh, trong ContentCard.
- **Không viền** (`border: InputBorder.none`, không nền fill — khác draft sheet cũ có nền rose-tint). Caption "tràn" như đang viết trực tiếp lên card (kiểu FB status). Lý do bỏ nền tint: caption là nhân vật chính, viền/nền làm nó thành "1 ô input" nhỏ bé.
- `minLines: 1`, `maxLines: 6` (auto-grow), `maxLength: 280`, `counterText: ''` (ẩn đếm — chỉ chặn ngầm), `textInputAction: TextInputAction.newline`.
- Style chữ nhập: `textPrimary` **16** w500 height1.45 (to hơn draft cũ 15 — caption là content chính). Hint: `textTertiary` (#A0A0B0) 16 w400.
- `contentPadding: EdgeInsets.zero` (sát author row, không thụt).
- **Hint copy** (xem §8): "Hôm nay của hai bạn có gì?…". Autofocus = **false** (đừng bật bàn phím ngay — để user ngắm ảnh trước; FB cũng vậy với create-post từ ảnh).

### 6.6 Divider
- Sau caption: `Divider(height: 1, thickness: 1, color: textPrimary .06)` ngăn vùng "lời" và "ảnh". Bao trên/dưới gap 14.

### 6.7 Khu ảnh — NHIỀU ảnh (≥2 file) → GRID
- `GridView` shrink-wrapped (`shrinkWrap: true`, `physics: NeverScrollableScrollPhysics` — toàn màn đã cuộn ngoài):
  - `crossAxisCount: 3`, `crossAxisSpacing: 8`, `mainAxisSpacing: 8`, `childAspectRatio: 1` (ô vuông).
  - **2 cột nếu ≤ 2 ảnh?** Không — giữ 3 cột cố định cho nhịp đều; 1–2 ảnh nằm cột đầu, phần còn lại là ô "+ Thêm ảnh". (Đơn giản, đỡ tính toán responsive.)
  - **Số ô = files.length + 1** (ô cuối luôn là "+ Thêm ảnh").
- **Mỗi ô ảnh:**
  - `ClipRRect(r14)` + `Image.file(File(path), fit: BoxFit.cover)`.
  - **Nút gỡ ╳:** `Positioned(top: 4, right: 4)` → đĩa tròn 24, nền `black .55`, icon `LucideIcons.x` 14 trắng, viền trắng 1.5. Vùng chạm thực ≥ 28 (bọc `GestureDetector`/`InkWell` padding). Tap → gỡ ảnh đó (`setState` removeAt). Haptic `selectionClick`.
  - (Tuỳ chọn nhẹ) overlay scrim `black .04` để ╳ luôn đọc được trên ảnh sáng — KHÔNG bắt buộc.
- **Ô "+ Thêm ảnh"** (ô cuối grid): nền `accentRose .06`, viền `accentRose .24` (dashed nếu Dev có sẵn, không thì solid), r14, giữa: icon `LucideIcons.plus` 22 `accentLoveDeep` + label 11 w700 `accentLoveDeep` "Thêm ảnh" (`l10n.createPostAddMore`). Tap → `pickMultiImage` lần nữa, **append** vào danh sách (dedup theo path), không thay thế.
- **Dưới grid:** dòng đếm `l10n.createPostPhotoCount(n)` → "{n} ảnh" style micro-caps `textSecondary` 11 w700 ls0.4 (gap trên 12). Giúp xác nhận số ảnh sẽ đăng.

### 6.8 Khu ảnh — 1 ảnh (camera, files.length == 1) → ẢNH LỚN
- `ClipRRect(r16)` + `AspectRatio(4/5)` + `Image.file(fit: BoxFit.cover)`, full width của card.
- **Nút gỡ ╳:** `Positioned(top: 8, right: 8)`, đĩa 30, nền `black .55`, icon `LucideIcons.x` 16 trắng, viền trắng 1.5. Tap → gỡ → files rỗng → (xem States: đóng màn).
- **Dưới ảnh** (gap 12): hàng "+ Thêm ảnh" full-width:
  - `InkWell` r16, height 48, nền `accentRose .06`, viền `accentRose .24`, giữa Row: icon `LucideIcons.imagePlus` 18 `accentLoveDeep` + gap 8 + label 14 w600 `accentLoveDeep` `l10n.createPostAddFromLibrary` ("Thêm ảnh từ thư viện"). Tap → `pickMultiImage` append → nếu thành ≥2 ảnh, vùng ảnh tự render grid.

## 7. States

| State | Hành vi |
|---|---|
| **Có ≥1 ảnh** | Nút "Đăng" bật (rose đặc). Bình thường. |
| **0 ảnh (gỡ hết)** | Khi gỡ ảnh cuối cùng → **tự `Navigator.pop(null)`** (giống `_GalleryDraftSheet._removeAt` cũ: gỡ hết = huỷ, không đăng gì). Nhờ vậy nút Đăng disabled gần như không bao giờ thấy được — nhưng vẫn để disabled-state phòng race. |
| **Caption rỗng** | HỢP LỆ — vẫn cho đăng (caption tuỳ chọn). `pop` với `caption: null`. |
| **Đang đăng (sau khi pop)** | Overlay diễn ra ở GALLERY (provider `isLoading` + `loadingMessage`), KHÔNG ở màn compose (màn đã pop). `BlockingLoadingOverlay` của gallery hiện "Đang đăng {x}/{N}…" (`uploadingPhotoProgress` — đã có). Màn compose chỉ trả kết quả rồi biến mất. |
| **Lỗi đăng** | `addPhotosBatch` không throw; gallery hiện snackbar partial/full-fail như hiện tại (`multiPhotosResultPartial` / `photoAddError`). Không liên quan màn compose. |
| **Đóng giữa chừng (nút ╳ / back / vuốt-xuống) khi có ảnh + caption** | Hiện `showDialog` xác nhận bỏ (`l10n.createPostDiscardTitle` / `…Message` / nút `discard`+`keepEditing`) — TRÁNH mất công soạn do chạm nhầm (chuẩn FB/IG). Nếu caption rỗng VÀ chưa gỡ ảnh nào → đóng thẳng không hỏi. **Chốt:** chỉ hỏi khi `caption.isNotEmpty` (đã đầu tư công viết); gỡ ảnh không tính. |
| **Camera-entry vs library-entry** | Khác DUY NHẤT: dữ liệu vào (1 vs N ảnh). UI tự suy ra layout theo `files.length` (1 → ảnh lớn; ≥2 → grid). Author row, caption, app bar GIỐNG HỆT. |
| **Đang pick thêm ảnh** | Khi gọi `pickMultiImage` để "Thêm ảnh", màn compose vẫn hiển thị (system picker che lên). Trả về → append + `setState`. Không cần loading riêng. |
| **Reduce Motion** | Màn này gần như tĩnh; nếu thêm entrance (fade/slide ảnh) thì bọc `EntranceReveal` (tự tắt khi Reduce Motion). Transition route slide-up GIỮ (transition điều hướng, không phải trang trí — được phép). |

## 8. Localization (vi + en) — key đề xuất

> Tái dùng key cũ khi có thể; key MỚI thêm CẢ `app_vi.arb` + `app_en.arb` rồi `flutter gen-l10n`. Sau redesign, `galleryDraftTitle/galleryDraftCaptionHint/galleryDraftPostBtn` THÀNH ORPHAN (giữ trong ARB hay xoá — Dev quyết; khuyến nghị giữ tạm).

| Key | VI | EN | Ghi chú |
|---|---|---|---|
| `createPostTitle` | `Kỷ niệm mới` | `New memory` | (tuỳ chọn) nhãn giữa app bar nếu dùng. |
| `createPostAuthorMeta` | `Đăng bởi {name} · {when}` | `Posted by {name} · {when}` | placeholder name=String, when=String. |
| `today` | `Hôm nay` | `Today` | kiểm tra đã tồn tại chưa; nếu chưa → thêm. Dùng cho `{when}`. |
| `createPostCaptionHint` | `Hôm nay của hai bạn có gì?…` | `What's happening with you two today?…` | hint caption (nhiều/1 ảnh dùng chung). |
| `createPostAddMore` | `Thêm ảnh` | `Add` | label ô "+ Thêm" trong grid (ngắn). |
| `createPostAddFromLibrary` | `Thêm ảnh từ thư viện` | `Add from library` | hàng full-width ở màn 1 ảnh. |
| `createPostPhotoCount` | `{count} ảnh` | `{count, plural, one{{count} photo} other{{count} photos}}` | đếm dưới grid; VI không chia số nhiều. |
| `createPostBtn` | `Đăng` | `Post` | nút app bar phải. |
| `createPostRemovePhoto` | `Gỡ ảnh` | `Remove photo` | semantics nút ╳. |
| `createPostDiscardTitle` | `Bỏ kỷ niệm này?` | `Discard this memory?` | dialog xác nhận đóng. |
| `createPostDiscardMessage` | `Phần chú thích chúng mình vừa viết sẽ không được lưu.` | `The caption you just wrote won't be saved.` | xưng "chúng mình" theo voice. |
| `createPostDiscardConfirm` | `Bỏ` | `Discard` | nút phá (error color). |
| `createPostDiscardKeep` | `Tiếp tục soạn` | `Keep editing` | nút giữ. |

**Tái dùng (không tạo mới):** `cancel` (semantics nút ╳ đóng nếu muốn) · `uploadingPhotoProgress` (overlay đăng) · `multiplePhotosAdded` / `multiPhotosResultPartial` / `photoAddedSuccess` (snackbar kết quả) · `cameraUnavailable` / `galleryNeedsCoupleToUpload` (guard ở gallery, không ở màn compose).

## 9. Token cụ thể (để Dev khỏi đoán)

**Màu (AppColors):**
- Nền màn: `dawnBlush` = [#FFC1CC, #E8B4D8, #C8A8E9].
- Card: `cardSurface` #FFFFFF (qua `ContentCard`), shadow `black .06`.
- Nút Đăng / ô thêm-ảnh accent: `accentLove` #FF4D6D (nút), `accentLoveDeep` #E63956 (icon/label ô thêm), tint nền ô thêm = `accentRose .06`, viền `accentRose .24` (accentRose = accentLove).
- Chữ: tên couple + caption nhập = `textPrimary` #1A1A2E; meta "Đăng bởi…" + đếm ảnh = `textSecondary` #6B6B7B; hint caption = `textTertiary` #A0A0B0.
- Nút ╳ trên ảnh: nền `black .55`, icon + viền `white`.
- Divider: `textPrimary .06`.

**Radius:** card 24 · ảnh lớn 16 · ô ảnh grid 14 · nút Đăng pill 999 · nút ╳ tròn (circle) · ô "+ thêm" 14/16 · close button ripple 16.

**Spacing:** margin card ngang 16 · padding card 16 · avatar↔text 10 · author row→caption 14 · caption→divider 14 · divider→ảnh 14 · grid spacing 8 · ảnh→hàng-thêm (màn 1 ảnh) 12 · grid→đếm 12 · app bar pad (16,14,16,8).

**Typography (size/weight, font = Quicksand toàn app):**
- Tên couple: 15 w700 ls-0.15 h1.2.
- Meta "Đăng bởi": 12 w500 h1.4.
- Caption nhập: 16 w500 h1.45 · hint 16 w400.
- Đếm ảnh: 11 w700 ls0.4 (micro-caps, có thể `.toUpperCase()`).
- Nút Đăng: 15 w700.
- Label ô "+ thêm" (grid): 11 w700; (full-width màn 1 ảnh): 14 w600.

**Shadow:** chỉ shadow ContentCard chuẩn (`black .06 blur 16 offset(0,10)`). Ảnh trong card KHÔNG cần shadow riêng (đã bo + nằm trên card).

**Icon (Lucide):** đóng `x` · đăng `send` · gỡ ảnh `x` · thêm (grid) `plus` · thêm (full-width) `imagePlus`.

## 10. Interaction / animation
- **Mở màn:** route `fullscreenDialog: true` → slide-up mặc định iOS (~350ms). (Android: fade-through mặc định.) Không cần custom.
- **Gỡ ảnh:** `setState` → grid reflow. Bọc ô ảnh trong `AnimatedSwitcher`/`AnimatedSize` 200ms easeOutCubic nếu muốn reflow mượt (TUỲ CHỌN, tắt khi Reduce Motion). Haptic `selectionClick` mỗi lần gỡ.
- **Nhấn Đăng:** haptic `mediumImpact` → pop. (Snackbar + haptic kết quả do gallery lo, giữ nguyên.)
- **Thêm ảnh:** mở system picker (không animation tự dựng).
- **Caption focus:** không autofocus; khi focus, bàn phím đẩy nội dung, `SingleChildScrollView` cuộn để caption không bị che.
- Mọi phần tử bấm = `InkWell`/`HeaderIconButton` (ripple rose .08) — không `GestureDetector` trần (trừ nút ╳ trên ảnh tối, ripple khó thấy → dùng `InkResponse` hoặc scale-tap nhẹ).

## 11. Assets
- Không cần asset mới. Tái dùng: avatar couple (`SharedCouplePhotoView`), icon Lucide (đã có), `Image.file` cho preview.

## 12. Dev notes
- **Đường ra LUÔN là `addPhotosBatch`** (kể cả 1 ảnh) — bỏ nhánh `addPhoto` đơn trong `_pickAndAddPhoto`. Caption chung truyền vào `caption:`. Overlay + snackbar kết quả GIỮ NGUYÊN logic gallery hiện tại.
- **`CreatePostResult`** = class nhỏ `{ List<XFile> files; String? caption; }` (thay `_GalleryDraftResult`). `CreatePostScreen` nhận `{ required List<XFile> initialFiles }` (entry không cần truyền — layout tự suy từ số ảnh).
- **Gỡ `_GalleryDraftSheet` + `_GalleryDraftResult`** khỏi gallery_screen.dart (~2664–2879).
- **1 caption/batch** là giới hạn model hiện tại (`addPhotosBatch(caption)`); caption-per-ảnh nằm ngoài phạm vi (cần đổi `Photo`/service/rules). Nếu PO muốn sau này → feature riêng.
- **Dedup khi "Thêm ảnh":** append file mới, loại path trùng (`Set` theo `XFile.path`).
- **`fullscreenDialog: true`** cho semantic + transition đúng; back-gesture iOS = vuốt xuống đóng → phải đi qua `_onClose` (intercept bằng `PopScope`/`WillPopScope` để hỏi discard khi caption không rỗng).
- **`couple` + `currentUser`**: lấy từ `CoupleProvider`/`AuthProvider` như gallery. Nếu `couple == null` (chưa ghép) — màn này không bao giờ mở (guard `galleryNeedsCoupleToUpload` đã chặn ở gallery trước khi pick).
- **D3:** mọi `DateFormat` truyền `locale` (nếu hiển thị ngày thật thay vì "Hôm nay").

## 13. Acceptance criteria
1. Bấm "Thêm hình" → chọn N ảnh → **mở full-screen `CreatePostScreen`** (KHÔNG bottom sheet), nền dawnBlush, ContentCard trắng.
2. Bấm "Chụp hình" → chụp 1 ảnh → **mở cùng màn** với 1 ảnh lớn 4:5 (không đăng thẳng nữa).
3. Author row hiện avatar couple + "em ♥ anh tuan" + "Đăng bởi em · Hôm nay".
4. Caption nhập được multiline, auto-grow, hint đúng 2 ngôn ngữ, không viền cứng, maxLength 280, cho phép rỗng.
5. Nhiều ảnh → grid 3 cột r14; mỗi ảnh có nút ╳ gỡ; có ô "+ Thêm ảnh" thêm được từ thư viện; có dòng đếm "{n} ảnh".
6. 1 ảnh → ảnh lớn 4:5 r16 + nút ╳ + hàng "Thêm ảnh từ thư viện"; thêm thành ≥2 ảnh thì tự chuyển grid.
7. Gỡ ảnh cuối → màn tự đóng, không đăng gì.
8. Nút "Đăng" disabled khi 0 ảnh; rose đặc khi có ảnh; bấm → đóng màn → gallery hiện overlay "Đang đăng x/N" → snackbar kết quả.
9. Đóng màn khi caption không rỗng → dialog xác nhận bỏ (2 ngôn ngữ); caption rỗng → đóng thẳng.
10. Toàn bộ token (màu/radius/spacing/type) khớp §9; Reduce Motion không vỡ; `flutter analyze` sạch.

## Nhật ký design
- [2026-05-30] [PO] Ghi nhận hiện trạng UI từ CLAUDE.md mục 8.
- [2026-06-14] [Designer] Spec **CreatePostScreen** — màn "Tạo kỷ niệm" full-screen kiểu FB/IG create-post thay `_GalleryDraftSheet`; áp cho cả luồng "Thêm hình" (N ảnh, grid 3 cột) lẫn "Chụp hình" (1 ảnh lớn 4:5, camera KHÔNG đăng thẳng nữa). Nền dawnBlush + ContentCard trắng, author row (avatar+tên couple+"Đăng bởi em · Hôm nay"), caption multiline không viền trên ảnh, nút "+ Thêm ảnh", nút Đăng pill rose ở app bar. Full token + states + 13 key l10n vi/en + wireframe 2 layout + acceptance criteria. Đường ra thống nhất `addPhotosBatch`.
