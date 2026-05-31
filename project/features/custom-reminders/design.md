# 🎨 Design — Custom reminders

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`../../../CLAUDE.md` mục 8). CHỈ thiết kế, không code.

- **Trạng thái design:** xong
- **Người/role:** Designer

## Mục tiêu thiết kế
Cho couple **tự tạo / sửa / xoá / bật-tắt nhiều reminder riêng lẻ** (tên + ghi chú + ngày + giờ + kiểu lặp) từ một màn hình quản lý mở ra từ mục Reminders trong Profile. Trải nghiệm phải:
- **Khớp 100% brand "Sunset Romance"** — tái dùng đúng token tile của profile (white .72, radius 22, viền accentRose .10, icon tile 44px radius 16), section card (white .84 radius 28), nền màn hình `dawnBlush` (secondaryGradient) như mọi main screen.
- **Tự nhiên, ấm áp, không-kỹ-thuật** — ngôn từ tình cảm ("Lời nhắc của chúng mình"), không dùng từ "schedule/recurrence".
- **Không im lặng fail** (D7): nếu reminders chưa bật/chưa cấp quyền → màn hình hướng dẫn bật trước, không cho tạo reminder vô hiệu.
- **Đủ rõ để Dev dựng không hỏi lại**: mọi state + token + copy vi/en + control cụ thể.

### Quyết định UX chính (Designer chốt, có căn cứ design system)
1. **Điểm vào:** thêm **1 row "Lời nhắc của chúng mình"** vào *cuối* `_buildRemindersSection` trong profile (dưới time-picker tile hiện có), kiểu tile y hệt language-picker row (white .72, radius 22, icon tile trái + chevron phải) → push **màn hình riêng** (full screen), KHÔNG bottom sheet. *Lý do:* danh sách có thể tới 20 item + cần AppBar/FAB + empty illustration → screen hợp hơn sheet.
2. **Form thêm/sửa = màn hình riêng** (push), KHÔNG bottom sheet. *Lý do:* form có 5 field (tên, ghi chú, ngày, giờ, kiểu lặp) + validation + (khi sửa) nút xoá → quá cao cho sheet trên máy nhỏ, bàn phím che. Screen cho không gian thở + scroll an toàn, đồng nhất với setup_screen (cũng là form full screen). *Đánh đổi:* thêm 1 lần điều hướng so với sheet — chấp nhận để form thoáng.
3. **Chọn kiểu lặp = hàng chips (ChoiceChip/segmented pill)** cuộn ngang, KHÔNG dropdown. *Lý do:* chỉ 5 lựa chọn cố định, chips hiển thị hết, 1-chạm, bám "letter-chip / pill" đã dùng ở language picker (D2) & mode selector setup. Pill bo `pillRadius` (999), chọn → nền gradient sunset, chữ trắng.
4. **Xoá trong list = swipe-to-delete (Dismissible) + xác nhận dialog**; menu "⋮" mỗi item cũng có Sửa/Xoá để máy không quen swipe vẫn dùng được. *Lý do:* swipe nhanh cho power user, menu cho khám phá.

---

## User flow

```
Profile › section "Reminders"
   └─ tile "Lời nhắc của chúng mình"  ── tap ──▶  [Màn hình DANH SÁCH]
                                                      │
        ┌─────────────────────────────────────────────┤
        │ (reminders OS chưa bật)  ──▶ State DISABLED: card hướng dẫn + nút "Bật lời nhắc"
        │                                  └─ tap ──▶ quay lại Profile để bật toggle gốc
        │
        │ (chưa có reminder nào)   ──▶ State EMPTY: minh hoạ + CTA "Tạo lời nhắc đầu tiên"
        │
        │ (có reminder)            ──▶ State LIST: list item + đếm "x/20" + FAB "+"
        │      ├─ tap item / menu "Sửa"  ──▶ [Form SỬA] (prefill) ── Lưu ──▶ về list
        │      ├─ toggle item            ──▶ bật/tắt tại chỗ (reschedule/cancel)
        │      ├─ swipe / menu "Xoá"     ──▶ dialog xác nhận ── Xoá ──▶ về list
        │      └─ FAB "+"                ──▶ [Form THÊM] (trống)
        │             (nếu đã 20)        ──▶ FAB mờ + snackbar "đã đạt giới hạn 20"
        │
   [Form THÊM/SỬA]:
        Tên* → Ghi chú → Ngày (date picker) → Giờ (time picker) → Kiểu lặp (chips)
        ├─ Tên trống  ──▶ field error đỏ, chặn Lưu
        ├─ Kiểu "một lần" + ngày quá khứ ──▶ warning vàng dưới date field, vẫn chặn Lưu
        └─ Lưu hợp lệ ──▶ snackbar "Đã lưu lời nhắc 💌" ──▶ về list
```

---

## Wireframe (ASCII)

### A. Điểm vào — trong Profile › section Reminders (thêm tile mới ở cuối)

```
┌──────────────────────────────────────────────┐  ← _buildSectionCard (white .84, r28)
│ Reminders                                      │   title 18/w800
│ Đừng bỏ lỡ những khoảnh khắc yêu thương        │   subtitle 12/textSecondary
│                                                │
│ ┌────────────────────────────────────────────┐│  ← tile toggle (ĐÃ CÓ)
│ │ [🔔] Nhắc nhớ yêu thương      [====O ]      ││
│ │      Bật để nhận lời nhắc...                 ││
│ └────────────────────────────────────────────┘│
│ ┌────────────────────────────────────────────┐│  ← tile giờ (ĐÃ CÓ)
│ │ [🕐] Giờ nhắc              20:00   ›         ││
│ └────────────────────────────────────────────┘│
│ ┌────────────────────────────────────────────┐│  ← ✨ TILE MỚI
│ │ [📅] Lời nhắc của chúng mình   3   ›         ││   badge đếm + chevron
│ │      Tự tạo mốc riêng của hai bạn            ││
│ └────────────────────────────────────────────┘│
└──────────────────────────────────────────────┘
```

### B. Màn hình DANH SÁCH — "Lời nhắc của chúng mình"

```
╔══════════════════════════════════════════════╗  nền dawnBlush (secondaryGradient)
║  ‹   Lời nhắc của chúng mình            3/20   ║  AppBar phẳng, back rose, đếm w700
╟──────────────────────────────────────────────╢
║                                                ║
║  ┌──────────────────────────────────────────┐ ║  ← item card (white .72, r22, viền rose .10)
║  │ [💖] Kỷ niệm theo tháng          [==O]  ⋮ │ ║   icon tile 44 + tên 15/w700 + toggle + menu
║  │      Hằng tháng · ngày 14 · 20:00          │ ║   meta 12/textSecondary
║  │      Sắp tới: 14/06/2026                    │ ║   next-fire 12/accentRose w600
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║
║  │ [🎂] Sinh nhật em                [==O]  ⋮ │ ║
║  │      Hằng năm · 02/09 · 08:00              │ ║
║  │      Sắp tới: 02/09/2026                    │ ║
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║   (item TẮT → opacity .55, toggle off)
║  │ [📌] Đi xem phim                 [O==]  ⋮ │ ║
║  │      Một lần · 20/06/2026 · 19:30          │ ║
║  │      Đã tắt                                 │ ║
║  └──────────────────────────────────────────┘ ║
║                                                ║
║                                       ( + )    ║  ← FAB tròn accentLove
╚══════════════════════════════════════════════╝
```

### B-empty. DANH SÁCH — State EMPTY

```
╔══════════════════════════════════════════════╗
║  ‹   Lời nhắc của chúng mình            0/20   ║
╟──────────────────────────────────────────────╢
║                                                ║
║                    ( 💌 )                       ║  vòng tròn gradient dreamyMint 96px + icon 40
║                                                ║
║         Chưa có lời nhắc nào                    ║  title 18/w800 center
║   Tạo mốc riêng của hai bạn: sinh nhật,        ║  body 14/textSecondary center
║   monthsary, ngày đặc biệt…                     ║
║                                                ║
║        ┌────────────────────────────┐          ║  CTA FilledButton.icon rose, h52, pill
║        │  +  Tạo lời nhắc đầu tiên   │          ║
║        └────────────────────────────┘          ║
╚══════════════════════════════════════════════╝
```

### B-disabled. DANH SÁCH — State CHƯA CẤP QUYỀN (D7)

```
╔══════════════════════════════════════════════╗
║  ‹   Lời nhắc của chúng mình                   ║  (ẩn badge đếm)
╟──────────────────────────────────────────────╢
║  ┌──────────────────────────────────────────┐ ║  card warning (white .72, viền warning .25)
║  │            ( 🔕 )                          │ ║  icon tile warning .12
║  │   Lời nhắc đang tắt                        │ ║  title 16/w800
║  │   Hãy bật "Nhắc nhớ yêu thương" ở trang    │ ║  body 13/textSecondary
║  │   Hồ sơ để các lời nhắc có hiệu lực.       │ ║
║  │   ┌──────────────────────────────┐         │ ║  nút FilledButton rose h52 pill
║  │   │      Bật lời nhắc             │         │ ║  → pop về Profile
║  │   └──────────────────────────────┘         │ ║
║  └──────────────────────────────────────────┘ ║
╚══════════════════════════════════════════════╝
   (FAB ẩn; nếu user đã có reminder cũ → vẫn hiện list bên dưới card cảnh báo,
    item dimmed opacity .55, không cho thêm mới tới khi bật)
```

### C. Form THÊM / SỬA — "Lời nhắc mới" / "Sửa lời nhắc"

```
╔══════════════════════════════════════════════╗  nền dawnBlush
║  ‹   Lời nhắc mới                       Lưu    ║  AppBar; action "Lưu" rose w800 (disable khi tên trống)
╟──────────────────────────────────────────────╢
║  ┌──────────────────────────────────────────┐ ║  ← form card glass (white .84, r28)
║  │ Tên lời nhắc *                             │ ║  label rose 13/w700
║  │ ┌────────────────────────────────────────┐ │ ║  TextField filled surfaceLight r20
║  │ │ vd: Sinh nhật em                        │ │ ║  prefix icon favorite rose
║  │ └────────────────────────────────────────┘ │ ║
║  │ ⚠ Hãy đặt tên cho lời nhắc                 │ ║  (error đỏ, chỉ khi trống lúc Lưu)
║  │                                            │ ║
║  │ Ghi chú (tuỳ chọn)                         │ ║
║  │ ┌────────────────────────────────────────┐ │ ║  TextField maxLines 3
║  │ │ Lời yêu thương kèm theo…                │ │ ║
║  │ └────────────────────────────────────────┘ │ ║
║  │                                            │ ║
║  │ ┌─────────────────┐ ┌──────────────────┐  │ ║  2 tile cạnh nhau (white .72 r20)
║  │ │ [📅] Ngày        │ │ [🕐] Giờ          │  │ ║
║  │ │ 14/06/2026   ›  │ │ 20:00         ›  │  │ ║  giá trị rose w800
║  │ └─────────────────┘ └──────────────────┘  │ ║
║  │ ⚠ Ngày đã qua rồi — chọn ngày khác         │ ║  (warning vàng, chỉ khi "một lần" + quá khứ)
║  │                                            │ ║
║  │ Lặp lại                                    │ ║  label rose 13/w700
║  │ (Một lần)(Hằng ngày)(Hằng tuần)(H.tháng)…  │ ║  ChoiceChip pill cuộn ngang, chọn=gradient sunset
║  └──────────────────────────────────────────┘ ║
║                                                ║
║   ─────────  (chỉ ở chế độ SỬA) ─────────      ║
║        ┌────────────────────────────┐          ║  nút text "Xoá lời nhắc" error, icon delete
║        │   🗑  Xoá lời nhắc           │          ║
║        └────────────────────────────┘          ║
╚══════════════════════════════════════════════╝
```

---

## Spec chi tiết (token chính xác — bám design system)

### Nền & khung chung
- **Nền cả 2 màn hình mới:** `AppColors.dawnBlush` (alias `secondaryGradient`) — đồng nhất mọi main/auth screen.
- **AppBar:** phẳng, trong suốt (`backgroundColor: Colors.transparent`, `elevation: 0`), back `Icons.arrow_back_ios_new_rounded` màu `accentRose`. Title 18/w800 `textPrimary`.
- **Section/form card:** `white` alpha **.84**, radius **28** (`cardRadius`), viền `white` .82, shadow `Colors.black` alpha **.045** blur 18 offset (0,10) — đúng `_buildSectionCard`.
- **Spacing dọc giữa card/section:** 16; padding card 20; padding tile 16.

### Tile item (list + tile điểm vào + tile ngày/giờ trong form)
- Nền `white` alpha **.72**, radius **22**, viền `accentRose` alpha **.10** (tile xanh-giờ dùng `accentGold` .12 như hiện có — item mới mặc định rose).
- **Icon tile trái:** 44×44, radius **16**, nền `accentRose` alpha **.12**, icon size 20 màu `accentRose`. (Item card list dùng icon tình cảm; xem mapping dưới.)
- **Khoảng cách icon→nội dung:** 14.
- Tên item: 15/**w700** `textPrimary`. Meta (kiểu lặp · ngày · giờ): 12 `textSecondary`, height 1.4. Dòng "Sắp tới": 12/**w600** `accentRose`. Dòng "Đã tắt": 12 `textTertiary`.
- **Toggle:** `Switch.adaptive`, `activeThumbColor: accentRose`.
- **Menu ⋮:** `IconButton` `Icons.more_vert_rounded` `textSecondary` → `showModalBottomSheet` hoặc `PopupMenu` (Sửa / Xoá). Item TẮT: bọc `Opacity .55` (trừ toggle giữ rõ).

### FAB
- `FloatingActionButton`, nền `accentLove` (`#FF4D6D`), icon `Icons.add_rounded` `white` size 26, tròn (mặc định). Khi đạt 20 → `backgroundColor: accentLove.withValues(alpha:.45)` (mờ) + onPressed hiện snackbar giới hạn (không mở form).

### Badge đếm "x/20" (AppBar list + tile điểm vào)
- AppBar list: text "{n}/20", 14/**w700**, `n<20`→`accentRose`, `n==20`→`warning`.
- Tile điểm vào (profile): badge tròn nhỏ — `Container` padding (10,4), nền `accentRose` .12, radius pill, text "{n}" 13/w800 `accentRose` (ẩn nếu 0).

### Empty state
- Vòng tròn 96×96 radius 999 nền gradient `dreamyMint` (`galleryGradient`), icon `Icons.mark_email_unread_rounded` (💌) size 40 `white`.
- Title 18/w800 center `textPrimary`; body 14 center `textSecondary` height 1.5 (padding ngang 32).
- CTA: `FilledButton.icon` nền `accentLove`, chữ `white` w700, **height 52**, bo pill (999), icon `add_rounded`.

### Disabled state (D7)
- Card cảnh báo: `white` .72, radius 28, viền `warning` (`#FFA726`) alpha **.25**.
- Icon tile 56×56 radius 18 nền `warning` .12, icon `Icons.notifications_off_rounded` size 24 `warning`.
- Title 16/w800; body 13 `textSecondary` height 1.5.
- Nút "Bật lời nhắc": `FilledButton` nền `accentLove`, height 52, pill → `Navigator.pop` về Profile.

### Form fields
- **Field tên / ghi chú:** `TextField` filled `surfaceLight` (`#F5F0F5`) radius **20**, focus viền `accentLove` width **1.4** (đúng theme input). Prefix icon tên = `Icons.favorite_rounded` `accentRose`; ghi chú maxLines 3 không prefix. Label trên field: 13/**w700** `accentRose`, margin-bottom 8.
- **Counter:** tên `maxLength 40` (counter ẩn, chỉ chặn), ghi chú `maxLength 120`.
- **Tile Ngày / Giờ:** 2 tile ngang chia đôi (gap 12), white .72 r20 padding 14. Icon `Icons.calendar_today_rounded` / `Icons.schedule_rounded` `accentRose` size 18 + label nhỏ 11 `textSecondary` + giá trị 15/**w800** `accentRose`. Tap → `showDatePicker` / `showTimePicker` (locale-aware, format ngày theo decision i18n D3).
- **Chips kiểu lặp:** `Wrap`/`SingleChildScrollView` ngang. Mỗi chip: `ChoiceChip` bo **pill (999)**, padding (16,10). Chưa chọn: nền `white` .72, chữ 13/w600 `textSecondary`, viền `accentRose` .12. Đã chọn: nền gradient `sunsetRomance` (dùng `Container` + `DecoratedBox` bo pill vì ChoiceChip không nhận gradient → Dev wrap), chữ `white` 13/**w700**. Khoảng cách chip 8.
- **Nút Xoá (chế độ sửa):** `TextButton.icon` icon `Icons.delete_outline_rounded` chữ `error` (`#EF5350`) w700, đặt dưới card, có divider mảnh `textTertiary .2` + nhãn nhỏ phía trên (xem copy). Tap → dialog xác nhận.
- **Action "Lưu" trên AppBar:** `TextButton` chữ `accentRose` 16/**w800**; disable (opacity .4, không tap) khi tên rỗng.

### Dialog xác nhận xoá
- `AlertDialog` radius 28, nền `cardSurface`. Title 18/w800; content 14 `textSecondary`. Nút huỷ `TextButton` `textSecondary`; nút xoá `TextButton` chữ `error` w800.

### Mapping icon gợi ý theo kiểu lặp (item list — Dev chọn theo recurrence, không bắt buộc tuyệt đối)
- một lần → `Icons.push_pin_rounded` · hằng ngày → `Icons.wb_sunny_rounded` · hằng tuần → `Icons.event_repeat_rounded` · hằng tháng → `Icons.calendar_month_rounded` · hằng năm → `Icons.cake_rounded`. Tất cả màu `accentRose` trong tile .12. *(Mặc định an toàn: tất cả dùng `Icons.favorite_rounded` nếu Dev muốn đơn giản.)*

---

## States

| State | Khi nào | Mô tả hình |
|-------|---------|-----------|
| **Empty** | reminders ĐÃ bật + 0 reminder tuỳ chỉnh | Minh hoạ 💌 (vòng dreamyMint) + tiêu đề "Chưa có lời nhắc nào" + body gợi ý + CTA "Tạo lời nhắc đầu tiên". FAB ẩn (CTA thay thế) hoặc vẫn hiện — Dev chọn; khuyến nghị ẩn FAB ở empty để tránh trùng. |
| **List** | có ≥1 reminder | List item cuộn dọc, badge "x/20" ở AppBar, FAB "+" góc dưới phải. Mỗi item: icon + tên + meta + next-fire + toggle + menu. |
| **Loading** | đang đọc Hive (hiếm, rất nhanh) | Center `CircularProgressIndicator` màu `accentRose` strokeWidth 2.5 trên nền dawnBlush. Nếu Hive sync (gần như tức thì) thì có thể bỏ qua loading — Dev quyết, nhưng phải có fallback. |
| **Disabled (D7)** | reminders OS off / chưa cấp quyền | Card cảnh báo warning (xem wireframe B-disabled) + nút "Bật lời nhắc" → về Profile. FAB ẩn, không cho thêm mới. List cũ (nếu có) hiện mờ opacity .55 bên dưới. |
| **Đạt giới hạn 20** | n == 20 | FAB mờ (.45). Tap FAB / CTA → KHÔNG mở form, hiện snackbar "Tối đa 20 lời nhắc…". Badge "20/20" màu warning. |
| **Form — tên trống** | bấm Lưu khi tên rỗng | Field tên viền `error`, dòng lỗi đỏ "Hãy đặt tên cho lời nhắc" dưới field; action Lưu vốn đã disable → đồng thời hiện lỗi nếu user cố submit qua keyboard. |
| **Form — "một lần" + ngày quá khứ** | recurrence=một lần & ngày<bây giờ | Warning vàng (`warning`) dưới tile Ngày: "Ngày đã qua rồi — chọn ngày khác". Chặn Lưu tới khi sửa. (Các kiểu lặp khác KHÔNG cảnh báo — chúng tự bắn chu kỳ kế.) |
| **Form — success** | Lưu hợp lệ | Snackbar floating navy r20 (theme) "Đã lưu lời nhắc 💌", pop về list, item mới xuất hiện. |

---

## Interaction & animation
- **Push màn hình list & form:** `MaterialPageRoute` mặc định (đồng nhất app). Không custom transition.
- **Chip kiểu lặp chọn:** đổi nền gradient + scale nhẹ — `AnimatedContainer` **260ms easeOutCubic** (đúng chuẩn mode-selector 260ms).
- **Toggle item bật/tắt:** `Switch.adaptive` mặc định + item card đổi opacity `AnimatedOpacity` **200ms easeOutCubic** (chuẩn switcher 200ms).
- **Swipe-to-delete:** `Dismissible` ngưỡng .4, nền đỏ `error` .9 bo 22 + icon trắng `delete_rounded`; dismiss **220ms** (chuẩn dismiss). Thả → dialog xác nhận; huỷ → item bật lại.
- **FAB:** scale-in khi vào màn hình (Hero/standard), không bắt buộc; nhấn → ripple mặc định.
- **Xoá khỏi list sau xác nhận:** `AnimatedList`/implicit — item collapse **220ms easeOutCubic**.
- **Empty ↔ List chuyển:** `AnimatedSwitcher` **200ms** khi thêm reminder đầu tiên.
- **Date/Time picker:** dùng native `showDatePicker`/`showTimePicker` (đã locale-aware trong app) — không tự dựng.

---

## Copy (song ngữ — bắt buộc; Dev bê thẳng vào ARB)

> Đề xuất prefix key ARB: `customReminders*`. Đặt tên rõ để khỏi đụng key `reminders*` cũ.

### Điểm vào (Profile)
| Key | VI | EN |
|-----|----|----|
| customRemindersEntryTitle | Lời nhắc của chúng mình | Our reminders |
| customRemindersEntrySubtitle | Tự tạo mốc riêng của hai bạn | Create your own special dates |

### Màn hình danh sách
| Key | VI | EN |
|-----|----|----|
| customRemindersScreenTitle | Lời nhắc của chúng mình | Our reminders |
| customRemindersCount | {count}/20 | {count}/20 |
| customRemindersNextFire | Sắp tới: {date} | Next: {date} |
| customRemindersDisabledLabel | Đã tắt | Off |
| customRemindersFabTooltip | Thêm lời nhắc | Add reminder |
| customRemindersItemMenuEdit | Sửa | Edit |
| customRemindersItemMenuDelete | Xoá | Delete |

### Empty state
| Key | VI | EN |
|-----|----|----|
| customRemindersEmptyTitle | Chưa có lời nhắc nào | No reminders yet |
| customRemindersEmptyBody | Tạo mốc riêng của hai bạn: sinh nhật, monthsary, ngày đặc biệt… | Create your own moments: birthdays, monthsaries, special days… |
| customRemindersEmptyCta | Tạo lời nhắc đầu tiên | Create your first reminder |

### Disabled / chưa cấp quyền (D7)
| Key | VI | EN |
|-----|----|----|
| customRemindersOffTitle | Lời nhắc đang tắt | Reminders are off |
| customRemindersOffBody | Hãy bật "Nhắc nhớ yêu thương" ở trang Hồ sơ để các lời nhắc có hiệu lực. | Turn on "Love reminders" in Profile so your reminders can work. |
| customRemindersOffCta | Bật lời nhắc | Turn on reminders |

### Giới hạn
| Key | VI | EN |
|-----|----|----|
| customRemindersLimitMsg | Bạn đã đạt tối đa 20 lời nhắc. Hãy xoá bớt để thêm mới. | You've reached the max of 20 reminders. Delete one to add more. |

### Form thêm/sửa — tiêu đề & action
| Key | VI | EN |
|-----|----|----|
| customRemindersAddTitle | Lời nhắc mới | New reminder |
| customRemindersEditTitle | Sửa lời nhắc | Edit reminder |
| customRemindersSave | Lưu | Save |
| customRemindersCancel | Huỷ | Cancel |
| customRemindersSavedMsg | Đã lưu lời nhắc 💌 | Reminder saved 💌 |

### Form — labels & placeholders
| Key | VI | EN |
|-----|----|----|
| customRemindersNameLabel | Tên lời nhắc | Reminder name |
| customRemindersNameRequiredMark | * | * |
| customRemindersNameHint | vd: Sinh nhật em | e.g. My love's birthday |
| customRemindersNoteLabel | Ghi chú (tuỳ chọn) | Note (optional) |
| customRemindersNoteHint | Lời yêu thương kèm theo… | Add a sweet note… |
| customRemindersDateLabel | Ngày | Date |
| customRemindersTimeLabel | Giờ | Time |
| customRemindersRepeatLabel | Lặp lại | Repeat |

### Nhãn 5 kiểu lặp
| Key | VI | EN |
|-----|----|----|
| customRemindersRepeatOnce | Một lần | Once |
| customRemindersRepeatDaily | Hằng ngày | Daily |
| customRemindersRepeatWeekly | Hằng tuần | Weekly |
| customRemindersRepeatMonthly | Hằng tháng | Monthly |
| customRemindersRepeatYearly | Hằng năm | Yearly |

### Meta dòng phụ item (kiểu lặp · chi tiết) — gợi ý ghép
| Key | VI | EN |
|-----|----|----|
| customRemindersMetaOnce | Một lần · {date} · {time} | Once · {date} · {time} |
| customRemindersMetaDaily | Hằng ngày · {time} | Daily · {time} |
| customRemindersMetaWeekly | Hằng tuần · {weekday} · {time} | Weekly · {weekday} · {time} |
| customRemindersMetaMonthly | Hằng tháng · ngày {day} · {time} | Monthly · day {day} · {time} |
| customRemindersMetaYearly | Hằng năm · {dayMonth} · {time} | Yearly · {dayMonth} · {time} |

### Validation & cảnh báo
| Key | VI | EN |
|-----|----|----|
| customRemindersNameError | Hãy đặt tên cho lời nhắc | Please name your reminder |
| customRemindersPastDateWarning | Ngày đã qua rồi — chọn ngày khác | That date has passed — pick another |

### Xoá — nhãn vùng & dialog
| Key | VI | EN |
|-----|----|----|
| customRemindersDeleteSectionHint | Không thể hoàn tác | Can't be undone |
| customRemindersDeleteButton | Xoá lời nhắc | Delete reminder |
| customRemindersDeleteDialogTitle | Xoá lời nhắc này? | Delete this reminder? |
| customRemindersDeleteDialogBody | "{name}" sẽ bị xoá và không nhắc bạn nữa. | "{name}" will be removed and won't remind you anymore. |
| customRemindersDeleteConfirm | Xoá | Delete |
| customRemindersDeletedMsg | Đã xoá lời nhắc | Reminder deleted |

> **Lưu ý notification body fallback** (D4): khi ghi chú trống, body notification dùng tên reminder hoặc câu mặc định. Đề xuất key tái dùng/ thêm:
| Key | VI | EN |
|-----|----|----|
| customRemindersNotifBodyFallback | Một mốc đáng nhớ của hai bạn 💞 | A special moment for the two of you 💞 |

---

## Handoff / Dev notes
- **Điểm vào:** chèn tile mới vào *cuối* `Column` trong `_buildRemindersSection` (`lib/screens/profile_screen.dart` ~line 728, sau tile time-picker). Tái dùng đúng kiểu tile language-picker row (white .72, r22, icon tile 44 r16, chevron). Badge đếm bên phải trước chevron. `onTap` → `Navigator.push` màn hình list mới. **Designer KHÔNG sửa file này — Dev thực hiện.**
- **Màn hình mới:** tạo 2 screen mới (vd `lib/screens/custom_reminders_screen.dart` + `custom_reminder_form_screen.dart`). Scaffold nền `dawnBlush` (bọc `Container(decoration: BoxDecoration(gradient: AppColors.dawnBlush))` + `Scaffold(backgroundColor: Colors.transparent)`), giống các main screen.
- **Tái dùng:**
  - `BlockingLoadingOverlay` nếu thao tác lưu/xoá có async chờ (thường nhanh, có thể bỏ).
  - Snackbar floating navy r20 → đã là theme mặc định, chỉ `ScaffoldMessenger.showSnackBar`.
  - `Switch.adaptive` activeThumbColor accentRose (copy từ reminders section).
  - Date/Time picker native (đã locale-aware — xem i18n D3 format ngày).
- **Chip gradient:** `ChoiceChip` không nhận `LinearGradient` cho selected. Dev wrap bằng `GestureDetector` + `AnimatedContainer` bo pill (decoration gradient `sunsetRomance` khi chọn), KHÔNG cần widget Chip thật. Hàng chips `SingleChildScrollView(scrollDirection: horizontal)`.
- **Format ngày/giờ:** theo decision i18n D3 (locale-aware). Dùng `intl DateFormat` theo `AppL10n`/current locale; `{time}` = `TimeOfDay.format(context)`.
- **next-fire ("Sắp tới: {date}"):** Dev tính ngày bắn kế tiếp theo recurrence + clamp D8; nếu item tắt → hiện "Đã tắt" thay vì next-fire.
- **D7 gate:** đọc `ReminderProvider.settings.enabled` (+ trạng thái quyền). Nếu off → render Disabled state thay list; nút "Bật lời nhắc" `Navigator.pop` về Profile (KHÔNG tự bật — để user bật ở toggle gốc, đúng luồng quyền hiện có).
- **Cap 20 (D5):** đọc số reminder từ provider; ≥20 → FAB mờ + snackbar limit, không mở form.
- **Toàn bộ chuỗi qua ARB** (`customReminders*`), gen-l10n; KHÔNG hardcode. Placeholder `{count}`, `{date}`, `{time}`, `{weekday}`, `{day}`, `{dayMonth}`, `{name}` khai báo trong ARB.
- **Không token mới:** mọi màu/radius/spacing ở trên đều từ `AppColors`/theme hiện có. Không thêm hằng số màu mới.

---

## Acceptance (design)
- [x] Mọi state có mô tả: Empty / List / Loading / Disabled(D7) / Đạt-giới-hạn-20 / Form-tên-trống / Form-ngày-quá-khứ / Form-success.
- [x] Wireframe ASCII cho cả 3: điểm vào (profile), danh sách, form thêm/sửa.
- [x] Token chính xác (hex màu, gradient alias, radius, spacing, typography, shadow) bám design system, không bịa token mới.
- [x] Copy đủ VI+EN: toàn bộ chuỗi UI + 5 nhãn kiểu lặp + label form + lỗi/giới hạn + empty + dialog xoá + meta + fallback body.
- [x] Interaction & animation theo chuẩn 200–320ms easeOutCubic.
- [x] Dev dựng được không cần hỏi lại (handoff nêu file điểm vào, screen mới, widget tái dùng, gate D5/D7, format ngày D3).

## Nhật ký design
- [2026-05-31] [Designer] Thiết kế đầy đủ feature custom-reminders: điểm vào từ profile (tile + badge đếm), màn hình danh sách (list/empty/disabled-D7/limit-20), form thêm/sửa (screen riêng, chips kiểu lặp gradient, validation tên + ngày quá khứ, nút xoá + dialog). Chốt UX: form & list là screen riêng (không sheet); chọn kiểu lặp bằng pill-chips cuộn ngang; xoá = swipe + menu + dialog xác nhận; điểm vào dạng tile cuối section Reminders. Token bám design system (dawnBlush nền, tile white .72 r22, card white .84 r28, accentRose, FAB accentLove). Copy song ngữ đầy đủ (prefix `customReminders*`). Tất cả token tái dùng từ AppColors/theme — không tạo token mới.
