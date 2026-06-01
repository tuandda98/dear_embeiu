# 🎨 Design — invite-sharing (Phase 1: Copy + Share đồng bộ)

> Designer sở hữu. Đọc [`overview.md`](overview.md) trước. Bám design system (`../../../CLAUDE.md` mục 8). CHỈ thiết kế, không code.

- **Trạng thái design:** xong
- **Người/role:** Designer
- **Phase:** 1 (copy/share, không native, không QR/link)

## Mục tiêu thiết kế
Thêm **cụm hành động "Copy | Share"** thống nhất ở **cả 3 nơi** hiện mã mời (Setup card / Home banner chờ partner / Profile detail tile). Tái dùng pattern nút Copy đã có ở Setup (`setup_screen.dart:627–660`); Share là **nút anh em** ngay cạnh Copy. Giảm ma sát phễu ghép đôi: A copy/share mã 1 chạm, B đỡ gõ tay.

Nguyên tắc chủ đạo:
- **Không bịa token mới** — chỉ dùng AppColors + radius/spacing có sẵn.
- **Một "ngôn ngữ nút" duy nhất** lặp lại ở 3 chỗ, nhưng **thích nghi theo nền** (2 chỗ nền tối/glass → nút trắng-mờ; 1 chỗ nền sáng → nút tint rose) thay vì ép một style phá bố cục.
- Cụm nút chỉ là **2 pill cạnh nhau**: trái Copy, phải Share — thứ tự cố định ở cả 3 chỗ để tạo trí nhớ cơ bắp.

## User flow
1. Couple ở trạng thái `waiting_partner` → mã mời hiện ở Setup / Home banner / Profile.
2. A thấy cụm **[📋 Sao chép] [⬆️ Chia sẻ]** ngay cạnh/dưới mã.
3. **Copy** → chép mã vào clipboard → toast `inviteCodeCopiedMsg` ("Đã sao chép mã mời").
4. **Share** → mở share sheet native (`share_plus`) với **câu mời song ngữ + mã** theo locale đang dùng → A chọn iMessage/Zalo/Messenger… gửi cho B.
5. Khi B join → couple `active` → mã + cụm nút **biến mất** ở cả 3 chỗ (state-gate sẵn có giữ nguyên).

## Wireframe (ASCII) — trước / sau

### A. Setup — `_buildInviteCodeCard` (card glass tối, mã 30px)
TRƯỚC:
```
┌─ glass card (white .22, r24) ───────────────┐
│ ⓘ  Mã mời của bạn                            │
│                                              │
│  A7K9Q2                       [📋 Sao chép]   │  ← chỉ có Copy
│                                              │
│  Chia sẻ mã này cho người ấy để ghép đôi…    │
└──────────────────────────────────────────────┘
```
SAU (Copy thu lại còn icon-pill cân với Share; cả 2 xuống 1 hàng action dưới mã để mã 30px không bị bóp):
```
┌─ glass card (white .22, r24) ───────────────┐
│ ⓘ  Mã mời của bạn                            │
│                                              │
│  A7K9Q2                                       │  ← mã full-width như cũ
│                                              │
│  [📋 Sao chép]   [⬆️ Chia sẻ]                 │  ← cụm 2 pill, hàng riêng
│                                              │
│  Chia sẻ mã này cho người ấy để ghép đôi…    │
└──────────────────────────────────────────────┘
```

### B. Home banner chờ partner — `home_screen.dart:679–697` (glass tối, chip mã 15px)
TRƯỚC:
```
┌─ banner (white .18, r22) ───────────────────┐
│ 🔗 │ Chờ bạn đồng hành                        │
│    │ Chia sẻ mã mời với người ấy…             │
│    │ ┌ A7K9Q2 ┐                               │  ← chip mã, không action
└──────────────────────────────────────────────┘
```
SAU (giữ chip mã, thêm cụm nút bên phải/ dưới chip cùng hàng):
```
┌─ banner (white .18, r22) ───────────────────┐
│ 🔗 │ Chờ bạn đồng hành                        │
│    │ Chia sẻ mã mời với người ấy…             │
│    │ ┌ A7K9Q2 ┐  [📋] [⬆️]                     │  ← chip + 2 icon-pill cạnh nhau
└──────────────────────────────────────────────┘
```
(Banner hẹp → dùng **biến thể icon-only** của pill: chỉ icon, bỏ chữ, để không tràn dòng. Tooltip = nhãn.)

### C. Profile — `_buildDetailTile` mã mời (tile nền SÁNG white .72, value navy)
TRƯỚC:
```
┌─ tile (white .72, r22, border warning .10) ─┐
│ 🔑 │ Mã mời tài khoản của bạn                 │
│    │ A7K9Q2                                   │  ← value text, không action
└──────────────────────────────────────────────┘
```
SAU (thêm cụm nút **biến thể nền-sáng**: pill tint rose, nằm dưới value):
```
┌─ tile (white .72, r22, border warning .10) ─┐
│ 🔑 │ Mã mời tài khoản của bạn                 │
│    │ A7K9Q2                                   │
│    │ [📋 Sao chép]   [⬆️ Chia sẻ]              │  ← 2 pill rose, hàng dưới value
└──────────────────────────────────────────────┘
```

## Spec chi tiết (token chính xác)

### Cụm dùng chung: `InviteActionButtons` (đề xuất tên widget Dev tạo)
Một Row chứa 2 pill (Copy trái, Share phải), `mainAxisSize.min`, **khoảng cách giữa 2 pill = 8px** (`SizedBox(width: 8)`).

Mỗi pill = `Material` + `InkWell` (giữ ripple), bo `BorderRadius.circular(12)` — **bám đúng pattern Copy hiện có** (setup_screen.dart:627–660).

Có **2 biến thể nền** (truyền qua tham số `onDark`/`variant`), KHÔNG đổi token, chỉ đổi alpha/màu chữ:

| Thuộc tính | Biến thể GLASS/TỐI (Setup, Home) | Biến thể SÁNG (Profile) |
|---|---|---|
| Nền pill | `AppColors.white` alpha **0.18** | `AppColors.accentRose` alpha **0.12** |
| Bo góc | `r12` | `r12` |
| Padding (có chữ) | `EdgeInsets.symmetric(horizontal: 12, vertical: 8)` | `horizontal: 12, vertical: 8` |
| Padding (icon-only, Home) | `EdgeInsets.all(8)` | n/a |
| Icon | `AppColors.white` alpha **0.90**, size **14** | `AppColors.accentRose`, size **14** |
| Chữ | `AppColors.white` alpha **0.90**, size **12**, w600 | `AppColors.accentRose`, size **12**, w700 |
| Gap icon↔chữ | `SizedBox(width: 4)` | `SizedBox(width: 4)` |

Icon:
- **Copy:** `Icons.copy_rounded` (giữ nguyên như Setup), size 14.
- **Share:** `Icons.ios_share_rounded`, size 14. (Chọn `ios_share_rounded` vì hợp ngữ cảnh "gửi đi/chia sẻ ra" và trông gọn ở cả 2 nền; `Icons.share_rounded` là phương án thay thế nếu Dev thấy lệch.)

Nhãn chữ: Copy = `l10n.copyBtn` ("Sao chép"); Share = `l10n.shareBtn` (key MỚI — xem bảng Copy).

### A. Setup
- Cụm nút đặt **dưới mã**, là một hàng riêng (không nằm cùng dòng mã 30px để tránh bóp mã).
- Spacing: sau Row mã → `SizedBox(height: 10)` → cụm nút → `SizedBox(height: 8)` (s/dụng lại nhịp 8/10 sẵn có) → description.
- Biến thể: **GLASS/TỐI**, có chữ.

### B. Home banner
- Cụm nút đặt **cùng hàng với chip mã**: bọc chip + cụm trong `Row(mainAxisSize.min)`; sau chip → `SizedBox(width: 8)` → cụm nút.
- Biến thể: **GLASS/TỐI, icon-only** (banner hẹp). Mỗi pill `EdgeInsets.all(8)`, icon size 14, `Tooltip(message: l10n.copyBtn / l10n.shareBtn)`.
- Nếu Dev thấy hàng vẫn chật trên màn nhỏ → cho phép `Wrap` xuống dòng (spacing 8) thay vì tràn; ưu tiên không overflow.

### C. Profile tile
- `_buildDetailTile` cho mã mời thêm 1 hàng cụm nút **dưới value**: sau Text(value) → `SizedBox(height: 10)` → cụm nút.
- Vì tile dùng `Row` icon+Expanded(Column) → cụm nút nằm **trong Column bên phải**, dưới value, `crossAxisAlignment.start`.
- Biến thể: **SÁNG**, có chữ (tint rose).
- Giữ nguyên `tint: AppColors.warning` của tile (icon 🔑 + border vẫn warning); chỉ **cụm nút** dùng rose để đồng nhất với "ngôn ngữ nút" toàn app.

## States
- **waiting_partner (mã hiện):** cụm nút hiện đầy đủ. Đây là state chính.
  - Setup: card invite chỉ render khi đang tạo/đã tạo couple solo (logic sẵn có) → cụm nút theo đó.
  - Home banner: chỉ render khi `couple.inviteCode.isNotEmpty` (guard sẵn có dòng 679) → cụm nút trong cùng guard đó.
  - Profile: chỉ render khi `inviteCode != null && trim().isNotEmpty && couple.isWaitingForPartner` (guard sẵn có dòng 465) → cụm nút trong cùng guard.
- **active (đã ghép):** mã KHÔNG hiện ở cả 3 chỗ → cụm nút **không tồn tại** (không cần thêm gì, guard cũ đã loại). Không có state "nút disabled".
- **Loading/Error:** Copy/Share là thao tác đồng bộ tức thời, **không có loading**. Share sheet do OS quản; nếu `share_plus` ném lỗi (hiếm) → im lặng/no-op, KHÔNG chặn UI (Dev: bọc try-catch nhẹ, không toast lỗi để tránh nhiễu — câu này là gợi ý, không bắt buộc).
- **Empty:** không áp dụng (mã luôn có khi state waiting_partner).
- **Pressed/ripple:** InkWell ripple mặc định trong bo r12.

## Interaction & animation
- **Copy:** tap → `Clipboard.setData(ClipboardData(text: inviteCode))` → `SnackBar(content: Text(l10n.inviteCodeCopiedMsg), duration: 2s)` — **giống hệt Setup hiện tại** (setup_screen.dart:631–638). SnackBar floating navy r20 mặc định theme.
- **Share:** tap → `Share.share(l10n.inviteShareMessage(code))` mở share sheet native. KHÔNG cần subject. (Trên iPad cần `sharePositionOrigin` — Dev lưu ý, không phải việc design.)
- **Animation:** chỉ ripple InkWell mặc định; không thêm animation mới (theo design system: nút phụ không cần motion riêng). Nằm trong dải easeOutCubic 200–320ms nếu Dev muốn fade-in, nhưng **không bắt buộc**.

## Copy (song ngữ — bắt buộc)

### Key l10n MỚI cần thêm (Dev thêm vào `app_localizations_*.dart`, hand-maintained per MEMORY)

| Key | VI | EN |
|-----|----|----|
| `shareBtn` (getter) | `Chia sẻ` | `Share` |
| `inviteShareMessage(String code)` (hàm có placeholder) | xem dưới | xem dưới |

**`inviteShareMessage` — VI:**
```
Mình muốn lưu giữ kỷ niệm cùng bạn trên Dear Embeiu 💞
Nhập mã mời này để ghép đôi với mình nhé: {code}

Tải app: 
```
**`inviteShareMessage` — EN:**
```
I want to keep our memories together on Dear Embeiu 💞
Enter this invite code to pair with me: {code}

Get the app: 
```

Ghi chú soạn copy:
- **Giọng "Sunset Romance"**: ấm áp, ngôi thứ nhất ("mình"/"I"), 1 emoji 💞 (motif trái tim), không sến quá.
- **Dễ chèn link ở Phase 3:** chủ ý để dòng cuối `Tải app: ` / `Get the app: ` **bỏ ngỏ đuôi câu** (có dấu cách cuối) → Phase 3 chỉ việc nối link/Universal Link vào cuối là thành câu hoàn chỉnh, **không phải sửa lại văn**. Trước mắt Phase 1 dòng này có thể để link store công khai (Play/App Store) hoặc tạm để trống — **PO quyết link cụ thể**; Designer chỉ thiết kế chỗ chừa.
- **An toàn ICU/l10n:** chỉ duy nhất `{code}` là placeholder. Emoji 💞 và dấu xuống dòng (`\n`) hợp lệ. KHÔNG dùng dấu `{ }` nào khác trong chuỗi. Theo MEMORY: l10n hand-maintained Dart → Dev sửa trực tiếp `app_localizations_en.dart` + `app_localizations_vi.dart` + abstract getter/method ở `app_localizations.dart`, KHÔNG chạy gen-l10n.

### Key TÁI DÙNG (không tạo mới)
| Key | Dùng cho |
|-----|----------|
| `copyBtn` | nhãn nút Copy (đã có) |
| `inviteCodeCopiedMsg` | toast sau Copy (đã có) |

## Handoff / Dev notes
1. **Thêm package** `share_plus` (pubspec) — IS2: 1 bộ code Android+iOS.
2. **Tạo widget dùng chung** `InviteActionButtons` (gợi ý đặt `lib/widgets/invite_action_buttons.dart`):
   - Tham số: `required String code`, `required VoidCallback`/internal Copy+Share, `bool onDark = true`, `bool iconOnly = false`.
   - Copy: bê nguyên logic Setup (Clipboard + SnackBar `inviteCodeCopiedMsg`). Vì cần `context` cho SnackBar + l10n → widget tự lấy `context.l10n`.
   - Share: `Share.share(context.l10n.inviteShareMessage(code))`.
3. **Gắn 3 nơi (mỗi nơi 1 biến thể):**
   - **Setup** `setup_screen.dart` `_buildInviteCodeCard`: thay nút Copy đơn lẻ (dòng 627–660) bằng cụm `InviteActionButtons(code: inviteCode, onDark: true)` đặt ở **hàng riêng dưới mã** (gỡ Copy khỏi Row mã, cho mã chiếm full-width). Giữ nhịp spacing 10/8 mô tả mục A.
   - **Home** `home_screen.dart` ~dòng 679–697: trong guard `if (couple.inviteCode.isNotEmpty)`, bọc chip mã + `InviteActionButtons(code: couple.inviteCode, onDark: true, iconOnly: true)` trong Row(min). Cho phép Wrap nếu chật.
   - **Profile** `profile_screen.dart` `_buildDetailTile` (mã mời) ~dòng 467–472 / 683–692: thêm cụm dưới value với `onDark: false` (biến thể rose sáng). Vì `_buildDetailTile` dùng chung cho nhiều tile → **thêm tham số optional** `Widget? trailingBelowValue` (hoặc tạo nhánh riêng cho tile mã mời) thay vì sửa cứng, để không ảnh hưởng tile ngày/cột mốc.
4. **State gate:** KHÔNG thêm điều kiện mới — cụm nút sống/chết theo đúng guard `waiting_partner`/`inviteCode` sẵn có ở mỗi chỗ. Khi `active`, mọi guard cũ đã ẩn mã → cụm nút tự biến mất.
5. **iPad:** `Share.share` cần `sharePositionOrigin` trên iPad để tránh crash popover — Dev tính từ `box.localToGlobal` của nút Share. (Lưu ý kỹ thuật, không phải design.)
6. **i18n:** thêm `shareBtn` + `inviteShareMessage(code)` cả en+vi + abstract. Không hardcode chuỗi.
7. **Không đụng** logic join/transaction/rules/native (Phase 1 scope).

## Acceptance (design)
- [x] Mọi state có hình/mô tả (waiting_partner: hiện; active: ẩn; pressed: ripple; lỗi share: no-op).
- [x] Copy đủ VI+EN (2 key mới + 2 key tái dùng liệt kê rõ).
- [x] Token chính xác, không bịa mới (chỉ dùng AppColors.white/accentRose + r12 + size 14/12 + alpha sẵn pattern Copy).
- [x] Wireframe trước/sau cho cả 3 nơi.
- [x] Dev dựng được không cần hỏi lại (widget dùng chung + 2 biến thể + điểm gắn từng file:line).

## Nhật ký design
- [2026-06-01] [Designer] Thiết kế Phase 1 invite-sharing: cụm "Copy | Share" dùng chung (`InviteActionButtons`, 2 biến thể glass-tối + sáng-rose, tái dùng pattern nút Copy Setup, token r12/icon14/text12, không bịa token mới). Wireframe trước/sau 3 nơi (Setup hàng riêng dưới mã / Home banner icon-only cạnh chip / Profile tile rose dưới value). Soạn câu mời song ngữ `inviteShareMessage(code)` giọng "Sunset Romance" 💞 + chừa dòng cuối "Tải app:" bỏ ngỏ cho link Phase 3. Đề xuất 2 key l10n mới: `shareBtn`, `inviteShareMessage(code)`; tái dùng `copyBtn`/`inviteCodeCopiedMsg`. Trạng thái design: xong.
