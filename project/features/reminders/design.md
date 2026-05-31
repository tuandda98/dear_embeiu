# 🎨 Design — Reminders

> Designer sở hữu. Đọc [overview.md](overview.md). Bám design system (`../../../CLAUDE.md` mục 8).

- **Trạng thái design:** ✅ Baseline + ✅ **v2 (milestone customization) — xong (2026-05-31)**

## Hiện trạng UI (đã ship)
- Trong **profile_screen**: hàng reminders với `Switch.adaptive` (bật/tắt) + time picker (chọn giờ:phút).

## Đề xuất cải thiện (bàn PO)
- Khi quyền bị từ chối → hiển thị trạng thái rõ + nút "Mở cài đặt" (hiện fail im lặng).
- Cho chọn loại reminder muốn nhận (hiện bật là bật hết 4 loại).
- Preview nội dung reminder (cho user biết sẽ nhận gì).

## Copy (song ngữ)
Các key reminder* (daily/anniversary/milestone/inactivity + toggle label/desc) đã có VI+EN.

---

## Reminders v2 design — Milestone customization

> Bám spec `overview.md` mục **5b** (Dv1–Dv7) + design system CLAUDE.md mục 8. Đồng nhất ngôn ngữ thị giác với feature [custom-reminders](../custom-reminders/design.md). CHỈ thiết kế, không code.

### Mục tiêu thiết kế
Redesign mục Reminders trong Profile + thêm **màn "Cột mốc & kỷ niệm"** cho user tự bật/tắt từng mốc tự động (curated, 7 mốc theo Dv4), và **hộp thoại force-open (Dv6)** thay state "disabled" thụ động khi vào "Lời nhắc của chúng mình" lúc master OFF. Trải nghiệm phải:
- **Khớp 100% brand "Sunset Romance"** — tái dùng đúng token đã dùng ở custom-reminders & profile: nền `dawnBlush`, tile white .72 r22 viền rose .10, section/card white .84 r28, icon tile 44 r16 rose .12, `Switch.adaptive` activeThumbColor accentRose, FAB/CTA accentLove.
- **Ấm áp, không-kỹ-thuật:** "Cột mốc & kỷ niệm", "Sắp tới", "Đã qua" — tránh từ "schedule/cadence/recurrence".
- **Master toggle là trung tâm:** 1 toggle duy nhất, đổi tên + có details rõ (Dv2) — kiêm xin quyền OS + gate custom reminders.
- **Đủ rõ để Dev dựng không hỏi lại:** mọi state + token + copy vi/en + control.

### Quyết định UX chính (Designer chốt, có căn cứ)
1. **Entry "Tuỳ chỉnh mốc" đặt ngay DƯỚI tile "Giờ nhắc", TRÊN tile "Lời nhắc của chúng mình"** — thứ tự trong section Reminders: (1) master toggle, (2) Giờ nhắc, (3) **Cột mốc & kỷ niệm [MỚI]**, (4) Lời nhắc của chúng mình. *Lý do:* (2)(3) đều thuộc "nhắc tự động do app dựng sẵn" → gom cạnh nhau; (4) là nhắc do user tự tạo → tách dưới cùng. Tile (3) hiển thị **luôn**, nhưng **disable mềm** (Opacity .45, không tap) khi master OFF — đồng nhất cách tile "Giờ nhắc" đang disable khi off (profile line ~685). *Đánh đổi:* không force-open cho tile mốc (khác với custom) vì danh sách mốc chỉ là cấu hình, không cần quyền để xem — bật quyền vẫn đi qua master toggle. (Force-open Dv6 CHỈ áp cho "Lời nhắc của chúng mình".)
2. **Mốc "đã qua" KHÔNG ẩn — vẫn hiện trong list nhưng đánh dấu "Đã qua"** (one-shot đã trôi: 520/1000/1314 khi daysTogether đã vượt; halfYear khi đã qua 6 tháng). *Lý do:* ẩn đột ngột gây bối rối ("mốc 1000 đâu rồi?"); giữ lại + nhãn "Đã qua" minh bạch. Toggle vẫn cho bật/tắt (lưu ý dưới) nhưng next-fire thay bằng dòng "Đã qua" `textTertiary`; item bọc Opacity .6. Mốc recurring (every100, yearly, inactivity) KHÔNG bao giờ "đã qua". *Đánh đổi:* user có thể bật 1 mốc đã qua mà không nhắc gì — chấp nhận, vì lần yêu kế (vd couple mới) nó vẫn hữu ích; Dev chỉ không schedule khi đã qua (acceptance overview: "đã qua thì không").
3. **Dialog force-open (Dv6) = `AlertDialog`** (không bottom sheet, không full screen). *Lý do:* nội dung ngắn (1 title + 1 body + 2 nút), AlertDialog là chuẩn ngành cho "mời bật + xin quyền", nhẹ và không rời ngữ cảnh tile đang đứng. Bám token dialog xác nhận xoá đã có ở custom (r28, cardSurface).
4. **List mốc = các tile xếp dọc trong 1 màn riêng (push), KHÔNG sheet** — đồng nhất với màn custom-reminders list. 7 item cố định (không thêm/xoá/FAB) → không cần AppBar action, chỉ back + title. *Lý do:* danh sách curated cố định, mỗi item là 1 hàng toggle giàu thông tin (icon + tên + mô tả + next/đã-qua) → tile dọc đọc dễ; sheet sẽ chật khi có 7 item + mô tả.
5. **Không nhóm "đã qua" xuống cuối** — giữ thứ tự cố định theo Dv4 (every100 → 520 → 1000 → 1314 → halfYear → yearly → inactivity) để vị trí mỗi mốc ổn định, dễ tìm. Trạng thái "đã qua" chỉ đổi dòng phụ + opacity, không đổi vị trí.

---

## User flow (v2)

```
Profile › section "Reminders"  (đổi: toggle rename + details + tile mốc mới)
   │
   ├─ [Master toggle "Nhắc cột mốc & kỷ niệm"]  ── bật ──▶ xin quyền OS
   │        ├─ granted  ──▶ enabled=true; tile Giờ + Cột mốc sáng lên
   │        └─ denied   ──▶ enabled=false; snackbar "Hãy bật thông báo trong Cài đặt…"
   │
   ├─ tile "Giờ nhắc"  (giữ nguyên; disable mờ khi off)
   │
   ├─ tile "Cột mốc & kỷ niệm"
   │        ├─ master ON   ── tap ──▶  [Màn CỘT MỐC]  (list 7 mốc, toggle từng cái)
   │        └─ master OFF  ──▶ tile mờ .45, không tap (gợi bật master trước)
   │
   └─ tile "Lời nhắc của chúng mình"
            ├─ master ON   ── tap ──▶ [Màn DANH SÁCH custom] (như custom-reminders design)
            └─ master OFF  ── tap ──▶ ┌─ [Dialog FORCE-OPEN]  (Dv6 — thay state disabled cũ)
                                       │   "Bật" ──▶ bật master + xin quyền OS
                                       │        ├─ granted ──▶ vào [Màn DANH SÁCH custom]
                                       │        └─ denied  ──▶ đóng dialog + snackbar từ chối, ở lại Profile
                                       │   "Để sau" ──▶ đóng dialog, ở lại Profile (master vẫn off)
                                       └─────────────────────────────────────────────────

[Màn CỘT MỐC]:
   List 7 mốc — mỗi mốc: icon + tên + mô tả ngắn + toggle + (Sắp tới: {ngày} | Đã qua | nếu inactivity: mô tả)
        ├─ toggle bật   ──▶ schedule mốc (Dev) — dòng phụ cập nhật "Sắp tới: …"
        ├─ toggle tắt   ──▶ cancel — dòng phụ ẩn next-fire / nhạt
        └─ mốc đã qua    ──▶ dòng "Đã qua", item opacity .6 (toggle vẫn thao tác được)
```

---

## Wireframe (ASCII) — v2

### (1) Profile › section "Reminders" sau redesign

```
┌──────────────────────────────────────────────┐  ← _buildSectionCard (white .84, r28)
│ Nhắc nhở yêu thương                            │   remindersTitle 18/w800 (GIỮ)
│ Những lời nhắc nhẹ nhàng để câu chuyện…        │   remindersSubtitle 12/textSecondary (GIỮ)
│                                                │
│ ┌────────────────────────────────────────────┐│  ← master toggle (RENAME + DETAILS)
│ │ [🔔] Nhắc cột mốc & kỷ niệm     [====O ]    ││   label 15/w700
│ │      Tự nhắc các cột mốc & kỷ niệm bạn       ││   desc 12/textSecondary h1.4
│ │      chọn. Cần bật để dùng "Lời nhắc của     ││   (2 ý: nhắc gì + cần bật để dùng custom)
│ │      chúng mình".                            ││
│ └────────────────────────────────────────────┘│
│ ┌────────────────────────────────────────────┐│  ← tile Giờ nhắc (GIỮ; mờ khi off)
│ │ [🕐] Giờ nhắc              20:00   ›         ││
│ └────────────────────────────────────────────┘│
│ ┌────────────────────────────────────────────┐│  ← ✨ TILE MỚI "Cột mốc & kỷ niệm"
│ │ [🎉] Cột mốc & kỷ niệm        5 mốc  ›       ││   badge "{n} mốc" bật + chevron; mờ .45 khi off
│ │      Chọn cột mốc muốn được nhắc             ││   subtitle 12
│ └────────────────────────────────────────────┘│
│ ┌────────────────────────────────────────────┐│  ← tile custom (GIỮ; gate → force-open)
│ │ [📅] Lời nhắc của chúng mình   3   ›         ││
│ │      Tự tạo mốc riêng của hai bạn            ││
│ └────────────────────────────────────────────┘│
└──────────────────────────────────────────────┘
```

### (2) Màn hình "Cột mốc & kỷ niệm" — list 7 mốc

```
╔══════════════════════════════════════════════╗  nền dawnBlush (secondaryGradient)
║  ‹   Cột mốc & kỷ niệm                         ║  AppBar phẳng, back rose, title 18/w800
╟──────────────────────────────────────────────╢
║  Chọn những cột mốc bạn muốn được nhắc.        ║  caption 13/textSecondary, padding (20,4)
║                                                ║
║  ┌──────────────────────────────────────────┐ ║  ← item card (white .72, r22, viền rose .10)
║  │ [💯] Mỗi 100 ngày               [==O]      │ ║   icon tile 44 + tên 15/w700 + toggle
║  │      Ăn mừng mỗi 100 ngày bên nhau          │ ║   desc 12/textSecondary h1.4
║  │      Sắp tới: 700 ngày · 12/08/2026          │ ║   next 12/w600 accentRose
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║
║  │ [💌] 520 ngày                   [O==]      │ ║   (mặc định OFF → toggle off)
║  │      "Anh yêu em" — mốc 520 ngày            │ ║
║  │      Sắp tới: 13/03/2026                     │ ║
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║   (ĐÃ QUA → opacity .6)
║  │ [🏆] 1000 ngày                  [==O]      │ ║
║  │      Tròn 1000 ngày yêu nhau                │ ║
║  │      Đã qua                                  │ ║   "Đã qua" 12/textTertiary
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║
║  │ [💞] 1314 ngày                  [O==]      │ ║   (mặc định OFF)
║  │      "Yêu trọn đời" — mốc 1314 ngày         │ ║
║  │      Sắp tới: 22/01/2027                     │ ║
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║
║  │ [🌙] Nửa năm yêu nhau           [==O]      │ ║
║  │      Tròn 6 tháng bên nhau                  │ ║
║  │      Đã qua                                  │ ║
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║
║  │ [🎂] Kỷ niệm hằng năm           [==O]      │ ║
║  │      Mỗi năm tròn ngày yêu nhau             │ ║
║  │      Sắp tới: 1 năm · 14/02/2027             │ ║
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║
║  │ [📸] Lâu chưa đăng ảnh          [==O]      │ ║
║  │      Nhắc nhẹ khi 7 ngày chưa có ảnh mới    │ ║
║  │      Nhắc khi vắng ảnh 7 ngày               │ ║   (inactivity: không có ngày cụ thể →
║  └──────────────────────────────────────────┘ ║    dòng phụ là mô tả tĩnh, không "Sắp tới")
╚══════════════════════════════════════════════╝
```

### (2-empty) Trường hợp KHÔNG có anniversary hợp lệ / tương lai
*(daysTogether<0 — anniversary đặt ở tương lai)*: list vẫn hiện đủ 7 mốc + toggle, nhưng các mốc đếm-ngày/tháng/năm **ẩn dòng "Sắp tới"** (vì chưa tính được), thay bằng caption mờ "Sẽ tính khi tới ngày kỷ niệm". inactivity vẫn hiện bình thường. Không có state "list rỗng" thực sự (luôn 7 mốc cố định).

### (3) Dialog force-open (Dv6) — tap "Lời nhắc của chúng mình" khi master OFF

```
        ┌──────────────────────────────────────┐    ← AlertDialog r28, nền cardSurface
        │            ( 🔔 )                      │    icon tròn 56 r18 nền rose .12, icon 24 rose
        │                                        │
        │   Bật nhắc nhở để tiếp tục             │    title 18/w800 textPrimary, center
        │                                        │
        │   Bạn cần bật "Nhắc cột mốc & kỷ       │    body 14/textSecondary h1.5, center
        │   niệm" để tạo và nhận lời nhắc        │
        │   riêng của hai bạn.                   │
        │                                        │
        │   ┌────────────┐   ┌───────────────┐  │
        │   │  Để sau    │   │     Bật       │  │    "Để sau" TextButton textSecondary
        │   └────────────┘   └───────────────┘  │    "Bật" FilledButton accentLove pill w700
        └──────────────────────────────────────┘
```

---

## Spec chi tiết (token — bám design system, KHÔNG token mới)

### (1) Section Reminders trong Profile
- **Card section:** giữ `_buildSectionCard` (white .84, r28). Title `remindersTitle` 18/w800, subtitle `remindersSubtitle` 12 textSecondary. Spacing giữa các tile: **12** (giữ như hiện có).
- **Master toggle tile:** giữ container white .72, r22, viền `accentRose` .10; icon tile 44×44 r16 nền rose .12, icon `Icons.notifications_active_rounded` size 20 rose (GIỮ). Label đổi `remindersToggleLabel` 15/w700; desc đổi `remindersToggleDesc` 12 textSecondary h1.4 (desc nay 3-4 dòng — Column cho phép wrap tự nhiên). `Switch.adaptive` activeThumbColor accentRose (GIỮ).
- **Tile "Cột mốc & kỷ niệm" [MỚI]:** container white .72, r22, viền `accentRose` .10. Icon tile 44×44 r16 nền rose .12, icon `Icons.celebration_rounded` size 20 accentRose. Khoảng cách icon→nội dung 14. Tên `remindersV2MilestoneEntryTitle` 15/w700 textPrimary; subtitle `remindersV2MilestoneEntrySubtitle` 12 textSecondary h1.4. Bên phải: **badge đếm "{n} mốc"** (số mốc đang BẬT) — `Container` padding (10,4) nền accentRose .12 r999, text `remindersV2MilestoneCountBadge` 13/w800 accentRose (ẩn nếu 0); rồi `Icons.chevron_right_rounded` textSecondary .5.
  - **Disable khi master OFF:** bọc `Opacity` .45 + `onTap: null` (đồng nhất tile Giờ nhắc, profile ~685). Bật lại khi `settings.enabled`.
- **Tile "Lời nhắc của chúng mình":** GIỮ nguyên giao diện; chỉ đổi **hành vi onTap** (xem gate force-open ở Handoff). KHÔNG dim/disable tile này khi off (luôn tap được → để mở dialog force-open).

### (2) Màn "Cột mốc & kỷ niệm"
- **Nền:** `AppColors.dawnBlush` (secondaryGradient) bọc `Container(decoration: BoxDecoration(gradient: …))` + `Scaffold(backgroundColor: Colors.transparent)`.
- **AppBar:** phẳng trong suốt, elevation 0; back `Icons.arrow_back_ios_new_rounded` accentRose; title `remindersV2MilestoneScreenTitle` 18/w800 textPrimary. KHÔNG action.
- **Caption đầu list:** `remindersV2MilestoneScreenCaption` 13 textSecondary, padding (20, 4, 20, 12).
- **Item mốc card:** white .72, r22, viền `accentRose` .10, padding 16, khoảng cách dọc giữa item **12**. Layout = Row: [icon tile] 14 [Column: tên + desc + dòng phụ] [Switch.adaptive].
  - Icon tile: 44×44 r16 nền accentRose .12, icon size 20 accentRose (mapping dưới).
  - Tên: 15/**w700** textPrimary. Desc: 12 textSecondary h1.4. Dòng phụ: "Sắp tới: …" 12/**w600** accentRose; "Đã qua" 12 textTertiary; inactivity = mô tả tĩnh 12 textSecondary.
  - Toggle: `Switch.adaptive` activeThumbColor accentRose.
  - **Mốc đã qua (one-shot trôi):** bọc `Opacity` .6 (toàn item, kể cả toggle vẫn nhìn rõ trạng thái), dòng phụ = "Đã qua".
- **Mapping icon mốc** (gợi ý, Dev có thể đơn giản hoá về `Icons.favorite_rounded`):
  | Mốc | Icon |
  |---|---|
  | Mỗi 100 ngày | `Icons.looks_one_rounded` *(hoặc `Icons.auto_awesome_rounded`)* |
  | 520 ngày | `Icons.mark_email_read_rounded` *(💌 "anh yêu em")* |
  | 1000 ngày | `Icons.emoji_events_rounded` 🏆 |
  | 1314 ngày | `Icons.favorite_rounded` 💞 |
  | Nửa năm | `Icons.brightness_2_rounded` 🌙 *(hoặc `Icons.timelapse_rounded`)* |
  | Kỷ niệm hằng năm | `Icons.cake_rounded` 🎂 |
  | Lâu chưa đăng ảnh | `Icons.photo_camera_rounded` 📸 |
  - Tất cả màu accentRose trong tile nền rose .12.

### (3) Dialog force-open
- `showDialog` → `AlertDialog`, `shape: RoundedRectangleBorder(borderRadius: 28)`, nền `cardSurface` (#FFFFFF).
- **Icon header (trong content, trên cùng):** `Container` 56×56 r18 nền accentRose .12, icon `Icons.notifications_active_rounded` size 24 accentRose, center; SizedBox 16 dưới.
- **Title:** `remindersV2ForceOpenTitle` 18/w800 textPrimary, center.
- **Body:** `remindersV2ForceOpenBody` 14 textSecondary h1.5, center, SizedBox 8 trên.
- **Actions:** "Để sau" = `TextButton` chữ textSecondary w600 (`remindersV2ForceOpenLater`); "Bật" = `FilledButton` nền `accentLove`, chữ white w700, bo pill (999), padding (20,12) (`remindersV2ForceOpenConfirm`). Đặt 2 nút trên 1 hàng phải (mặc định actions) hoặc xếp dọc full-width nếu cần — Dev chọn; khuyến nghị hàng ngang chuẩn AlertDialog.
- **Hành vi:** "Bật" → gọi đúng luồng `reminderProvider.setEnabled(true, …)` (xin quyền OS) như master toggle → granted: đóng dialog + push màn custom list; denied: đóng dialog + snackbar `remindersV2ForceOpenDeniedMsg`. "Để sau" → chỉ đóng dialog.

### Badge "{n} mốc"
- Số mốc đang BẬT (đếm từ provider). Padding (10,4), nền accentRose .12, r999, text 13/w800 accentRose. Ẩn (`SizedBox.shrink`) khi 0.

---

## States (v2)

| State | Khi nào | Mô tả hình |
|-------|---------|-----------|
| **Master ON** | enabled=true | Tile Giờ + Cột mốc sáng (opacity 1, tap được). Tile custom tap → vào list. |
| **Master OFF** | enabled=false | Tile Giờ + Cột mốc mờ .45, không tap. Tile custom vẫn tap được → mở dialog force-open. |
| **Màn mốc — bình thường** | anniversary hợp lệ | 7 item, mỗi item toggle + "Sắp tới: {ngày}" (mốc bật & chưa qua). |
| **Màn mốc — mốc đã qua** | one-shot (520/1000/1314/halfYear) đã trôi | Item opacity .6, dòng phụ "Đã qua", toggle vẫn thao tác. KHÔNG ẩn item. |
| **Màn mốc — chưa tính được ngày** | daysTogether<0 (anniversary tương lai) | Item đếm-ngày/tháng/năm ẩn "Sắp tới", thay caption mờ "Sẽ tính khi tới ngày kỷ niệm"; inactivity vẫn hiện. Không crash. |
| **Màn mốc — inactivity** | luôn | Dòng phụ là mô tả tĩnh ("Nhắc khi vắng ảnh 7 ngày"), không có "Sắp tới". |
| **Item TẮT** | toggle off | Dòng phụ ẩn next-fire (chỉ desc); item KHÔNG dim (chỉ "đã qua" mới dim) — để dễ phân biệt tắt-thủ-công vs đã-qua. |
| **Dialog force-open** | master OFF + tap custom | AlertDialog mời bật; Bật→xin quyền (granted vào / denied snackbar); Để sau→đóng. |
| **Force-open denied** | dialog "Bật" + quyền OS từ chối | Đóng dialog + snackbar `remindersV2ForceOpenDeniedMsg`, ở lại Profile, master vẫn off. |

> **Không có state "empty"** ở màn mốc: danh sách 7 mốc cố định, luôn hiển thị.

---

## Interaction & animation (v2)
- **Push màn "Cột mốc & kỷ niệm":** `MaterialPageRoute` mặc định (đồng nhất app & custom-reminders).
- **Toggle mốc bật/tắt:** `Switch.adaptive` mặc định; nếu item đổi opacity (đã-qua) → `AnimatedOpacity` **200ms easeOutCubic** (chuẩn switcher 200ms). Dòng phụ đổi (Sắp tới ↔ ẩn) có thể `AnimatedSwitcher` **200ms** (không bắt buộc).
- **Tile "Cột mốc" dim khi master off:** `AnimatedOpacity` **200ms easeOutCubic**.
- **Dialog force-open:** `showDialog` mặc định (fade+scale ~150ms hệ thống) — không custom.
- **Tap "Bật" trong dialog:** trong lúc chờ quyền OS có thể disable nút + spinner nhỏ (tái dùng `BlockingLoadingOverlay` nếu thấy lag; thường tức thì → không bắt buộc).
- Tất cả animation mới nằm trong dải **200–320ms easeOutCubic** theo chuẩn dự án.

---

## Copy (song ngữ — bắt buộc; Dev bê thẳng vào ARB)

> Prefix mới `remindersV2*` (màn mốc + tile + force-open) — **KHÔNG đụng** key `reminders*` cũ ngoài 2 key được CẬP NHẬT giá trị dưới. Tên mốc/desc dùng prefix `milestone*`.

### Cập nhật 2 key cũ (Dv2 — đổi VALUE, giữ key)
| Key | VI (mới) | EN (mới) |
|-----|----|----|
| remindersToggleLabel | Nhắc cột mốc & kỷ niệm | Milestone & anniversary reminders |
| remindersToggleDesc | Tự nhắc các cột mốc & kỷ niệm bạn chọn. Cần bật để dùng "Lời nhắc của chúng mình". | Reminds you of the milestones & anniversaries you choose. Required to use "Our reminders". |

> `remindersTitle`/`remindersSubtitle`/`remindersTimeLabel`/`remindersPermissionDeniedMsg` GIỮ NGUYÊN.

### Tile điểm vào "Cột mốc & kỷ niệm" (Profile)
| Key | VI | EN |
|-----|----|----|
| remindersV2MilestoneEntryTitle | Cột mốc & kỷ niệm | Milestones & anniversaries |
| remindersV2MilestoneEntrySubtitle | Chọn cột mốc muốn được nhắc | Choose which milestones to be reminded of |
| remindersV2MilestoneCountBadge | {count} mốc | {count} |

> *(EN dùng badge số trần "{count}" cho gọn; VI "{count} mốc". Nếu Dev muốn 1 dạng chung, dùng số trần cho cả 2.)*

### Màn "Cột mốc & kỷ niệm"
| Key | VI | EN |
|-----|----|----|
| remindersV2MilestoneScreenTitle | Cột mốc & kỷ niệm | Milestones & anniversaries |
| remindersV2MilestoneScreenCaption | Chọn những cột mốc bạn muốn được nhắc. | Choose the milestones you want to be reminded of. |
| remindersV2MilestoneNext | Sắp tới: {date} | Next: {date} |
| remindersV2MilestoneNextWithLabel | Sắp tới: {label} · {date} | Next: {label} · {date} |
| remindersV2MilestonePast | Đã qua | Passed |
| remindersV2MilestonePending | Sẽ tính khi tới ngày kỷ niệm | Calculated once your anniversary begins |

> `{label}` dùng cho mốc có nhãn số (vd "700 ngày", "1 năm"); mốc không nhãn dùng `remindersV2MilestoneNext`. Dev ghép `{label}` từ số ngày/năm kế tiếp.

### Tên + mô tả 7 mốc (prefix `milestone*`)
| Key | VI | EN |
|-----|----|----|
| milestoneEvery100Title | Mỗi 100 ngày | Every 100 days |
| milestoneEvery100Desc | Ăn mừng mỗi 100 ngày bên nhau | Celebrate every 100 days together |
| milestone520Title | 520 ngày | 520 days |
| milestone520Desc | "Anh yêu em" — mốc 520 ngày | "I love you" — the 520-day mark |
| milestone1000Title | 1000 ngày | 1000 days |
| milestone1000Desc | Tròn 1000 ngày yêu nhau | A full 1000 days in love |
| milestone1314Title | 1314 ngày | 1314 days |
| milestone1314Desc | "Yêu trọn đời" — mốc 1314 ngày | "Forever love" — the 1314-day mark |
| milestoneHalfYearTitle | Nửa năm yêu nhau | Half a year together |
| milestoneHalfYearDesc | Tròn 6 tháng bên nhau | A full 6 months together |
| milestoneYearlyTitle | Kỷ niệm hằng năm | Yearly anniversary |
| milestoneYearlyDesc | Mỗi năm tròn ngày yêu nhau | Every year on your anniversary |
| milestoneInactivityTitle | Lâu chưa đăng ảnh | No photos for a while |
| milestoneInactivityDesc | Nhắc nhẹ khi 7 ngày chưa có ảnh mới | A gentle nudge after 7 days without a new photo |
| milestoneInactivitySub | Nhắc khi vắng ảnh 7 ngày | Reminds you after 7 photo-free days |

> Nhãn "{label}" cho next-fire (Dev tự ghép số): mốc đếm-ngày → "{n} ngày" (`remindersV2MilestoneDaysLabel`); kỷ niệm năm → "{n} năm" (`remindersV2MilestoneYearsLabel`).

| Key | VI | EN |
|-----|----|----|
| remindersV2MilestoneDaysLabel | {count} ngày | {count} days |
| remindersV2MilestoneYearsLabel | {count} năm | {count} years |

### Dialog force-open (Dv6)
| Key | VI | EN |
|-----|----|----|
| remindersV2ForceOpenTitle | Bật nhắc nhở để tiếp tục | Turn on reminders to continue |
| remindersV2ForceOpenBody | Bạn cần bật "Nhắc cột mốc & kỷ niệm" để tạo và nhận lời nhắc riêng của hai bạn. | You need to turn on "Milestone & anniversary reminders" to create and receive your own reminders. |
| remindersV2ForceOpenConfirm | Bật | Turn on |
| remindersV2ForceOpenLater | Để sau | Later |
| remindersV2ForceOpenDeniedMsg | Chưa cấp quyền thông báo. Hãy bật thông báo trong Cài đặt để tiếp tục. | Notification permission denied. Enable notifications in Settings to continue. |

---

## Handoff / Dev notes (v2)
- **File điểm vào:** `lib/screens/profile_screen.dart` › `_buildRemindersSection` (~line 565).
  1. Đổi label/desc master toggle → key `remindersToggleLabel`/`remindersToggleDesc` (chỉ đổi ARB value, không đổi key — code đã trỏ đúng).
  2. **Chèn tile "Cột mốc & kỷ niệm" MỚI** vào giữa tile Giờ nhắc (~line 740) và tile "Lời nhắc của chúng mình" (~line 742). Tái dùng đúng pattern tile (white .72 r22, icon tile 44 r16, badge + chevron). Bọc Opacity .45 + onTap null khi `!settings.enabled` (giống tile Giờ nhắc). onTap (khi on) → `Navigator.push` màn mốc mới.
  3. **Đổi gate tile "Lời nhắc của chúng mình"** (onTap ~line 743): hiện đang push thẳng `CustomRemindersScreen`. Đổi thành: nếu `settings.enabled` → push như cũ; nếu OFF → `showDialog` force-open. "Bật" trong dialog → `reminderProvider.setEnabled(true, anniversaryDate:…, lastPhotoDate:…, l10n:…)` (luồng xin quyền hiện có) → granted: `customReminders.rescheduleAllEnabled()` + đóng dialog + push màn custom; denied: đóng dialog + snackbar `remindersV2ForceOpenDeniedMsg`. **Bỏ/để chết** state "disabled" cũ trong `CustomRemindersScreen` (D7) — vì giờ chỉ vào được khi đã bật. (Designer KHÔNG sửa file — Dev thực hiện.)
- **Màn mới:** tạo `lib/screens/milestone_reminders_screen.dart` (tên gợi ý). Scaffold nền dawnBlush + AppBar phẳng (copy pattern từ `custom_reminders_screen.dart`). List 7 item từ model milestone settings (Dev dựng theo `dev.md`).
- **Tái dùng:** `Switch.adaptive` activeThumbColor accentRose; AppBar/back pattern + nền dawnBlush từ custom-reminders screens; `Container` tile white .72 r22 (đồng nhất).
- **next-fire ("Sắp tới"):** Dev tính ngày bắn kế tiếp theo từng loại mốc (every100 → mốc 100 kế; one-shot → ngày mốc nếu chưa tới, else "Đã qua"; halfYear → ngày đủ 6 tháng nếu chưa tới; yearly → kỷ niệm năm kế). Format ngày locale-aware (i18n D3, dùng `DateFormat` theo current locale). daysTogether<0 → dòng "Sẽ tính khi tới ngày kỷ niệm". inactivity → mô tả tĩnh `milestoneInactivitySub`.
- **Badge "{n} mốc":** đếm số mốc đang bật từ provider; ẩn nếu 0.
- **Toàn bộ chuỗi qua ARB** (`remindersV2*`/`milestone*` + 2 key reminders* cập nhật value), gen-l10n; KHÔNG hardcode. Placeholder `{count}`, `{date}`, `{label}` khai báo trong ARB.
- **Không token mới:** mọi màu/radius/spacing đều từ `AppColors`/theme hiện có (đã liệt kê). Không thêm hằng số mới.

---

## Acceptance (design v2)
- [x] Section Reminders redesign: master toggle rename + details 2-ý; tile "Giờ nhắc" giữ; tile "Cột mốc & kỷ niệm" mới (vị trí + badge + dim khi off); tile custom giữ (gate đổi).
- [x] Màn "Cột mốc & kỷ niệm": wireframe + token + 7 mốc (icon/tên/desc/toggle/next-fire), mặc định đúng (Dv4).
- [x] Dialog force-open (Dv6): wireframe + token + hành vi Bật/Để sau/denied.
- [x] States đủ: master on/off, mốc bình thường/đã-qua/chưa-tính-được/inactivity/tắt-thủ-công, force-open + denied. (Không có empty — list cố định 7.)
- [x] Copy đủ VI+EN: 2 key cập nhật + tile mốc + màn mốc + 7 tên/desc mốc + nhãn next + dialog force-open + denied msg.
- [x] Token chính xác bám design system, KHÔNG token mới.
- [x] Animation 200–320ms easeOutCubic.
- [x] Handoff nêu file điểm vào (profile_screen line), màn mới, widget tái dùng, gate đổi disabled→force-open.

## Nhật ký design
- [2026-05-30] [PO] Ghi nhận hiện trạng UI từ CLAUDE.md mục 6,8.
- [2026-05-31] [Designer] Thiết kế **Reminders v2 — milestone customization**: (1) redesign section Reminders trong Profile — master toggle đổi tên "Nhắc cột mốc & kỷ niệm" + details 2-ý, thêm tile "Cột mốc & kỷ niệm" (đặt giữa Giờ nhắc & custom, badge "{n} mốc", dim .45 khi master off); (2) màn mới "Cột mốc & kỷ niệm" — list 7 mốc cố định (icon+tên+desc+toggle+Sắp tới/Đã qua), mặc định theo Dv4, mốc đã-qua giữ lại + nhãn "Đã qua" opacity .6 (không ẩn); (3) dialog force-open (Dv6) thay state disabled cũ — AlertDialog mời bật, Bật→xin quyền OS (granted vào custom / denied snackbar), Để sau→đóng. Copy song ngữ đầy đủ (prefix `remindersV2*`/`milestone*` + 2 key reminders* đổi value). Token bám design system (dawnBlush, tile white .72 r22, dialog r28 cardSurface, accentRose/accentLove, Switch.adaptive). Không token mới. Đồng nhất ngôn ngữ thị giác với custom-reminders.
