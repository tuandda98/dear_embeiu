# 🎨 Design — Photo report

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`../../../CLAUDE.md` mục 8). CHỈ thiết kế, không code.

- **Trạng thái design:** xong
- **Người/role:** Designer

## Mục tiêu thiết kế
Thêm hành động **"Báo cáo ảnh"** nhẹ, đủ điều kiện Apple Guideline 1.2 (UGC report), KHÔNG làm nặng UX gallery vốn ấm áp & riêng tư. Tái dùng 100% pattern/token đã có (AlertDialog xoá ảnh, popup menu ⋮, snackbar floating, icon row fullscreen). Không token mới, không component mới cầu kỳ.

**Nguyên tắc:** kín đáo (không phô trương ở feed chính), 2 chạm là xong (mở entry → chọn lý do = gửi), confirm mềm, KHÔNG ẩn ảnh (R4).

## User flow
```
[Feed item ⋮]  ──┐
                 ├──► tap "Báo cáo ảnh"  ──► [Bottom-sheet chọn lý do]
[Fullscreen 🚩] ─┘                              │
                                                ├─ tap 1 lý do (Không phù hợp / Spam / Khác) = GỬI LUÔN
                                                │       └──► ghi reports/{autoId} ──► snackbar "Đã gửi báo cáo, cảm ơn bạn."
                                                └─ tap "Huỷ" / vuốt xuống / chạm nền = đóng, KHÔNG ghi gì
```
- **2 điểm vào (R3):**
  - (a) **Menu ⋮ feed item** — thêm mục thứ 3 "Báo cáo ảnh" (sau Sửa caption / Xoá ảnh).
  - (b) **Fullscreen preview** — thêm nút 🚩 (flag/outlined) vào icon-row trên-phải, đứng TRƯỚC nút edit & close.
- **Tap lý do = gửi luôn** (không có nút Gửi riêng) — pattern gọn nhất cho compliance. Nút "Huỷ" full-width dưới cùng để đóng chủ động.
- Nếu chính người dùng là tác giả ảnh thì vẫn cho báo cáo (không phân biệt — đơn giản, app chỉ 2 người).

## Wireframe (ASCII)

### (1) Menu ⋮ feed item — thêm mục "Báo cáo ảnh"
```
            ┌───────────────────────────┐
   ⋯  ─────►│  Sửa caption              │
            ├───────────────────────────┤
            │  Xoá ảnh        (đỏ error) │  ← chỉ khi đăng nhập (giữ nguyên)
            ├───────────────────────────┤
            │  🚩  Báo cáo ảnh  (rose)   │  ← MỚI: luôn hiện
            └───────────────────────────┘
```
Mục "Báo cáo ảnh": icon `flag_outlined` 18px + label, màu `accentRose` (#FF4D6D) để phân biệt sắc thái với "Xoá" (error đỏ) nhưng vẫn là hành động "moderation". Đặt cuối danh sách.

### (2) Fullscreen preview — nút báo cáo ở icon-row trên-phải
```
  ┌──────────────────────────────────────────────┐
  │                          [🚩] [✎] [✕]  ◄── top-right row, opacity theo overlay
  │                                                │
  │              (ảnh InteractiveViewer)           │
  │                                                │
  │   ┌──────────────────────────────────────┐    │
  │   │ avatar  Tên người đăng · thời gian    │    │ ← panel info (giữ nguyên)
  │   │ caption…                              │    │
  │   └──────────────────────────────────────┘    │
  └──────────────────────────────────────────────┘
```
- Nút mới = `IconButton.filledTonal` GIỐNG HỆT nút edit/close hiện có: nền `Colors.black @0.28`, foreground `AppColors.white`, icon `Icons.flag_outlined`. Đặt **đầu hàng** (trái edit). `SizedBox(width: 8)` giữa các nút.
- Tooltip = copy `reportPhotoAction`.

### (3) Bottom-sheet chọn lý do
```
  ╭──────────────────────────────────────────╮  ← showModalBottomSheet, bo trên 28
  │            ──────  (drag handle)          │     nền cardSurface #FFFFFF
  │                                            │
  │   Báo cáo ảnh                              │  ← title 18 w700 textPrimary
  │   Cho chúng tôi biết vấn đề với ảnh này.   │  ← subtitle 13.5 textSecondary
  │                                            │
  │   ┌────────────────────────────────────┐  │
  │   │  Nội dung không phù hợp        ›    │  │  ← tile bo 18, tap = gửi
  │   ├────────────────────────────────────┤  │
  │   │  Spam hoặc lừa đảo             ›    │  │
  │   ├────────────────────────────────────┤  │
  │   │  Khác                          ›    │  │
  │   └────────────────────────────────────┘  │
  │                                            │
  │   ┌────────────────────────────────────┐  │
  │   │              Huỷ                   │  │  ← TextButton full-width, textSecondary
  │   └────────────────────────────────────┘  │
  ╰──────────────────────────────────────────╯
        (safe-area bottom padding)
```

## Spec chi tiết (token chính xác — bám design system, KHÔNG token mới)

**Mục menu ⋮ (PopupMenuItem):**
- Thêm value mới vào enum `_PhotoFeedAction` (vd `report`). Mục luôn hiện (không gate đăng nhập ở UI — dev xử báo cáo khi authed).
- Child = `Row(mainAxisSize.min)`: `Icon(Icons.flag_outlined, size: 18, color: AppColors.accentRose)` + `SizedBox(width: 10)` + `Text(reportPhotoAction, color: AppColors.accentRose)`. (Các mục cũ là Text thuần — mục báo cáo thêm icon để tách thị giác; chấp nhận được vì cùng PopupMenu.)
- Thứ tự: editCaption → delete → **report** (cuối).

**Nút fullscreen (IconButton.filledTonal):**
- `backgroundColor: Colors.black.withValues(alpha: 0.28)`, `foregroundColor: AppColors.white` — y hệt 2 nút bên cạnh.
- `icon: Icons.flag_outlined`. `tooltip: reportPhotoAction`.
- Vị trí: phần tử ĐẦU trong `Row`, theo sau là `SizedBox(width: 8)`, rồi edit (nếu có), rồi close. Chịu chung `overlayOpacity`.

**Bottom-sheet (`showModalBottomSheet`):**
- `backgroundColor: AppColors.cardSurface` (#FFFFFF); `isScrollControlled: true` (không bắt buộc nhưng cho safe-area mượt); `useSafeArea: true`.
- `shape: RoundedRectangleBorder(borderRadius: vertical(top: Radius.circular(28)))` — token card lớn 28.
- `barrierColor` mặc định (đen mờ) — đủ.
- **Padding ngoài:** `EdgeInsets.fromLTRB(20, 12, 20, 20)` + safe-area bottom.
- **Drag handle:** `Container` 40×4, `color: AppColors.textTertiary @0.4` (#A0A0B0), bo 999 (pill), căn giữa, margin dưới 16. (Tái dùng pattern handle — nếu chưa có sẵn, dựng inline đơn giản.)
- **Title:** `reportPhotoTitle` — fontSize 18, w700, `AppColors.textPrimary`. SizedBox(height 4).
- **Subtitle:** `reportPhotoSubtitle` — fontSize 13.5, w500, `AppColors.textSecondary`, height 1.45. SizedBox(height 18).
- **Reason tiles (Column, 3 cái):** mỗi tile là `InkWell` bo 18 trong `Container`:
  - height tự nhiên, padding `EdgeInsets.symmetric(horizontal: 16, vertical: 15)`.
  - nền `AppColors.surfaceLight` (#F5F0F5), bo 18 (token input/nút phụ — wait: dùng 18 cho tile gọn; design system tile 22–24, nhưng 18 đồng nhất với input bo 20; CHỌN **18** cho list chọn-nhanh, nhất quán cả 3).
  - Row: `Text(reason, fontSize 15, w600, textPrimary)` + `Spacer` + `Icon(Icons.chevron_right_rounded, 20, textTertiary)`.
  - cách nhau `SizedBox(height: 10)`.
- **Nút Huỷ:** sau tiles SizedBox(height 14); `SizedBox(width: double.infinity)` bọc `TextButton(child: Text(reportCancel, color: AppColors.textSecondary, w600))`.

**Snackbar xác nhận (R4):** dùng `ScaffoldMessenger.showSnackBar` y như các snackbar gallery hiện có (theme = floating navy bo 20). `content: Text(reportSentConfirm)`. KHÔNG action, KHÔNG ẩn ảnh.

## States
- **Sheet đóng (mặc định):** không gì trên màn — chỉ entry ⋮ + nút 🚩 fullscreen.
- **Sheet mở:** slide-up từ đáy; 3 tile + Huỷ. Không có state disabled.
- **Đang gửi:** ghi `reports` là 1 doc create rất nhanh → **KHÔNG cần loading riêng**. Pattern: đóng sheet NGAY khi tap lý do (lạc quan), rồi hiện snackbar khi xong. Nếu muốn chắc, dev có thể await trước khi đóng — nhưng để nhẹ, ưu tiên đóng-rồi-báo. (Lỗi ghi local fallback / network: theo R-rủi-ro overview, vẫn báo thành công UI, KHÔNG lộ lỗi — không có error state hiển thị.)
- **Đã gửi:** snackbar floating navy "Đã gửi báo cáo, cảm ơn bạn." ~2–3s. Ảnh KHÔNG đổi gì.
- **Huỷ / dismiss:** sheet trượt xuống, không ghi, không snackbar.

## Interaction & animation
- **Mở sheet:** `showModalBottomSheet` mặc định (~250ms ease-out, slide-up) — nằm trong dải chuẩn 200–320ms, GIỮ default, không custom.
- **Tap tile:** `InkWell` ripple nhẹ (màu ripple mặc định trên surfaceLight). Tap = đóng sheet (`Navigator.pop` trả reason) → ghi → snackbar.
- **Snackbar:** floating navy bo 20 (theo theme), tự ẩn.
- **Fullscreen nút 🚩:** opacity bám `overlayOpacity` (mờ dần khi drag-to-dismiss) — tự động vì nằm chung Row.
- KHÔNG thêm haptic/animation mới.

## Copy (song ngữ — bắt buộc) — prefix `report*`
| Key | VI | EN |
|-----|----|----|
| `reportPhotoAction` | Báo cáo ảnh | Report photo |
| `reportPhotoTitle` | Báo cáo ảnh | Report photo |
| `reportPhotoSubtitle` | Cho chúng tôi biết vấn đề với ảnh này. | Tell us what's wrong with this photo. |
| `reportReasonInappropriate` | Nội dung không phù hợp | Inappropriate content |
| `reportReasonSpam` | Spam hoặc lừa đảo | Spam or scam |
| `reportReasonOther` | Khác | Something else |
| `reportCancel` | Huỷ | Cancel |
| `reportSentConfirm` | Đã gửi báo cáo, cảm ơn bạn. | Report sent, thank you. |

> Giá trị `reason` lưu Firestore nên là **mã ổn định** (KHÔNG dịch): `inappropriate` / `spam` / `other`. Label hiển thị lấy từ ARB theo key ở trên. Dev map enum → mã khi ghi doc.

## Handoff / Dev notes
**File điểm vào (chỉ 1 file UI):** `lib/screens/gallery_screen.dart`
1. **Menu ⋮ feed** (~dòng 1043–1069, `PopupMenuButton<_PhotoFeedAction>`):
   - Thêm giá trị enum `report` vào `_PhotoFeedAction` (~dòng 1368).
   - Thêm `PopupMenuItem` "Báo cáo ảnh" (icon flag_outlined accentRose) ở CUỐI `itemBuilder` (sau delete). Luôn hiện.
   - Trong `onSelected`: nhánh `report` → gọi `_reportPhoto(photo)`.
2. **Fullscreen icon-row** (~dòng 1808–1841, `Positioned` top-right `Row`):
   - Thêm `IconButton.filledTonal` flag_outlined (style giống edit/close) làm phần tử ĐẦU + `SizedBox(width: 8)`. `onPressed`: gọi callback báo cáo (dev thêm callback `onReport`/closure tương tự `onEditCaption`, KHÔNG pop preview trước — sheet mở chồng lên preview là OK; hoặc theo lựa chọn dev miễn flow đúng).
3. **Hàm mới `_reportPhoto(Photo photo)`** (kiểu như `_editCaption`/`_deletePhoto`):
   - Mở bottom-sheet lý do (spec mục Wireframe 3 + Spec). Tile trả về mã reason.
   - Nếu user huỷ/dismiss → return, không ghi.
   - Gọi service ghi `reports/{autoId}` với field theo **R1**: `reporterUid` (currentUser.id), `coupleId`, `photoId` (photo.id), `authorUserId` (photo.authorUserId), `reason` (mã), `createdAt` (serverTimestamp). Đặt trong `PhotoProvider`/service mới (vd `report_service.dart`) — theo kiến trúc Provider+service.
   - **Local fallback / lỗi:** bọc try/catch, KHÔNG lộ lỗi; vẫn hiện snackbar `reportSentConfirm` (theo rủi ro overview 🟡). KHÔNG ẩn ảnh (R4).
   - Hiện snackbar `reportSentConfirm`.
- **firestore.rules:** `reports` create-only (`allow create: if request.auth != null; allow read, update, delete: if false;`) — KHÔNG nới rule khác. Dev KHÔNG deploy (R5).
- **i18n:** thêm 8 key vào `app_vi.arb` + `app_en.arb`, chạy gen-l10n. Dùng `context.l10n.<key>` (UI) — không cần `AppL10n.strings` (không có background path).
- **KHÔNG** dùng MasonryGallery (không liên quan). KHÔNG đụng logic add/delete/caption/push hiện có.

## Acceptance (design)
- [x] Mọi state có hình/mô tả (đóng/mở/đang gửi/đã gửi/huỷ).
- [x] Copy đủ VI+EN (8 key, prefix `report*`) + ghi chú mã reason không dịch.
- [x] Dev dựng được không cần hỏi lại (file + dòng + token + field Firestore + rule).
- [x] Token bám design system, không token mới (sheet bo 28, tile surfaceLight bo 18, accentRose cho mục báo cáo, snackbar floating navy).
- [x] 2 điểm vào đúng R3; confirm = snackbar (R4); huỷ không ghi.

## Nhật ký design
- [2026-05-31] [Designer] Thiết kế photo-report: 2 điểm vào (menu ⋮ feed thêm "Báo cáo ảnh" icon flag_outlined accentRose; fullscreen icon-row thêm nút 🚩 filledTonal trước edit/close). Bottom-sheet chọn lý do bo 28 nền cardSurface, 3 tile surfaceLight bo 18 (tap = gửi luôn) + nút Huỷ full-width. Confirm = snackbar floating navy "Đã gửi báo cáo, cảm ơn bạn", KHÔNG ẩn ảnh. Copy vi+en 8 key prefix report*, reason lưu mã ổn định (inappropriate/spam/other). Handoff: 1 file UI gallery_screen.dart + service ghi reports create-only. Trạng thái design → xong.
