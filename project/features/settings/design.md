# 🎨 Design — Settings

> Designer sở hữu. Đọc [overview.md](overview.md) trước. Bám design system (`../../../CLAUDE.md` mục 8). Đồng nhất với [reminders v2](../reminders/design.md) + [custom-reminders](../custom-reminders/design.md). CHỈ thiết kế, không code.

- **Trạng thái design:** ✅ xong (2026-05-31)
- **Người/role:** Designer

## Mục tiêu thiết kế
Gom Profile rời rạc thành **1 màn "Cài đặt" có cấu trúc module → sub-module** (S1–S7). Profile chỉ còn **danh tính couple** (hero + stats) + 1 tile "⚙️ Cài đặt". Mọi cài đặt cũ (reminders, ngôn ngữ, chỉnh sửa câu chuyện, vùng nguy hiểm, đăng xuất, privacy) **DI CHUYỂN nguyên hành vi** sang Settings — chỉ đổi vị trí, KHÔNG đổi logic. Thêm phần MỚI: sub "Cột mốc & kỷ niệm" có **Giờ mặc định** + **giờ riêng từng mốc** (Dv8).

Trải nghiệm phải:
- **Khớp 100% brand "Sunset Romance"** — tái dùng đúng token đã dùng ở profile/reminders/custom: nền `dawnBlush`, section card white .84 r28 (`_buildSectionCard`), tile white .72 r22 viền rose .10, icon tile 44 r16 nền rose .12, `Switch.adaptive` activeThumbColor accentRose, danger zone white .92 r28 viền error .14.
- **Cấu trúc rõ kiểu iOS Settings:** mỗi module = 1 section card có tiêu đề + nhóm tile bên trong (tái dùng `_buildSectionCard` — KHÔNG token mới). Sub-module mở bằng push màn riêng.
- **Giữ độ "nguy hiểm" rõ** cho xoá tài khoản (compliance App Store/Play) — y nguyên danger zone hiện có.
- **Đủ rõ để Dev dựng không hỏi lại:** mọi state + token + copy vi/en + control.

---

## Quyết định UX chính (Designer chốt, có căn cứ)

1. **Module = section card (`_buildSectionCard`), KHÔNG tạo widget nhóm mới.** Mỗi module 🔔/🌐/👤 là 1 section card (white .84 r28, có title + subtitle + child) — đúng pattern profile hiện có. Sub-module (Cột mốc, Lời nhắc, Chỉnh sửa câu chuyện) = tile trong card → push màn riêng. *Lý do:* tái dùng tối đa, đồng nhất thị giác, không cần token mới; "section header + card nhóm" chính là `_buildSectionCard`. *Đánh đổi:* không phải list-group liền mạch kiểu iOS thuần, nhưng card-có-tiêu-đề là ngôn ngữ đã có của app → nhất quán hơn.

2. **Settings là màn PUSH riêng** (`SettingsScreen`, nền dawnBlush, AppBar phẳng back rose + title "Cài đặt"), vào từ tile "⚙️ Cài đặt" ở cuối Profile. *Lý do:* tách "danh tính couple" (Profile) khỏi "điều khiển" (Settings) đúng tinh thần S1/S3; push là chuẩn điều hướng đã dùng cho mọi sub-screen (custom/milestone).

3. **Control giờ-theo-mốc (Dv8) = INLINE trong mỗi mốc, KHÔNG tách màn.** Trong sub "Cột mốc & kỷ niệm": đầu màn 1 tile **"Giờ mặc định"** (tap → time picker). Mỗi mốc thêm **1 chip-giờ nhỏ bên phải toggle**: hiện giờ riêng nếu đã đặt (đậm, accentRose), ngược lại hiện giờ mặc định **dạng mờ + nhãn "Theo mặc định"**. Tap chip → time picker đặt riêng. *Lý do:* inline thấy ngay mốc nào theo mặc định vs riêng, không phải vào sâu thêm 1 cấp; chip nhỏ gọn cùng hàng toggle. *Đánh đổi:* hàng mốc giàu hơn (icon+tên+desc+next+chip-giờ+toggle) → bố trí 2 dòng control (toggle trên, chip-giờ dưới next-line) cho thoáng máy nhỏ — xem wireframe.

4. **"Về giờ mặc định" = nút xoá trong time-picker flow, KHÔNG cần long-press ẩn.** Khi mốc ĐÃ có giờ riêng, chip-giờ hiển thị giờ riêng + icon ✕ nhỏ; tap ✕ → xoá giờ riêng (về mặc định) ngay, không dialog (revert nhẹ, dễ làm lại). Khi mốc đang theo mặc định, chip chỉ là "Theo mặc định {giờ}" mờ, tap → mở time picker để ĐẶT riêng. *Lý do:* hành động rõ ràng, 1-chạm, không giấu; phân biệt thị giác "đã đặt riêng" (có ✕) vs "theo mặc định" (mờ, không ✕).

5. **Chip-giờ chỉ thao tác được khi mốc BẬT.** Mốc tắt → chip-giờ ẩn (giờ không có ý nghĩa khi không nhắc). Mốc "đã qua" (one-shot trôi) → chip-giờ vẫn hiện nhưng theo opacity .6 của item. inactivity → vẫn cho đặt giờ riêng (nhắc 7 ngày vẫn bắn theo giờ).

6. **Danger zone GIỮ NGUYÊN khối hiện có**, đặt **trong module "Tài khoản & dữ liệu"** ở DƯỚI CÙNG của Settings (sau ngôn ngữ), là card riêng viền đỏ — KHÔNG hoà vào section card thường. *Lý do:* compliance + thói quen "khu nguy hiểm tách biệt cuối trang"; bê nguyên `_buildDangerZone` (cache/leave/divider/delete) + nút đăng xuất + link privacy. Tile "Chỉnh sửa câu chuyện" (S3) là tile thường trong module Tài khoản, TRÊN danger zone (vì nó không nguy hiểm).

7. **"Chỉnh sửa câu chuyện" đổi từ nút lớn → tile** đồng nhất các tile khác trong Settings (icon + tên + chevron → push setup). *Lý do:* trong list-settings, tile nhất quán hơn nút FilledButton lớn; copy giữ key cũ `editOurStoryBtn`.

---

## User flow

```
Profile (gọn)
   ├─ Hero couple card + stats        (GIỮ nguyên)
   └─ tile "⚙️ Cài đặt"  ── tap ──▶  [Màn SETTINGS]
                                          │
   ┌──────────────────────────────────────┤
   │ 🔔 Nhắc nhở
   │   • Master toggle "Nhắc cột mốc & kỷ niệm" (+ details) — bật→xin quyền OS
   │   • tile "Cột mốc & kỷ niệm"  ─ master ON, tap ─▶ [Sub CỘT MỐC] (giờ mặc định + 7 mốc)
   │                                ─ master OFF ─▶ tile mờ .45, không tap
   │   • tile "Lời nhắc của chúng mình" ─ ON tap ─▶ [Sub custom list]
   │                                     ─ OFF tap ─▶ [Dialog force-open] (Dv6)
   │ 🌐 Ngôn ngữ
   │   • tile chọn ngôn ngữ ── tap ──▶ language picker (sheet hiện có)
   │ 👤 Tài khoản & dữ liệu
   │   • tile "Chỉnh sửa câu chuyện" ── tap ──▶ setup_screen
   │   • [Danger card] xoá cache · rời couple · ── Xoá tài khoản (đỏ)
   │   • nút Đăng xuất
   │ ── Chính sách bảo mật (footer link)

[Sub CỘT MỐC & KỶ NIỆM]:
   ┌ tile "Giờ mặc định"  20:00  ── tap ──▶ time picker (áp mốc chưa-đặt-riêng)
   └ 7 mốc — mỗi mốc: icon + tên + desc + (Sắp tới/Đã qua) + toggle + chip-giờ
        ├ mốc theo mặc định → chip "Theo mặc định · 20:00" (mờ) ── tap ─▶ time picker đặt RIÊNG
        ├ mốc đã đặt riêng  → chip "21:30 ✕" (đậm rose) ── tap chip ─▶ đổi giờ; tap ✕ ─▶ về mặc định
        └ mốc TẮT → chip-giờ ẩn
   Đổi "Giờ mặc định" → mọi mốc chưa-đặt-riêng cập nhật hiển thị + reschedule (Dev, Dv8).
```

---

## Wireframe (ASCII)

### (1) Profile sau redesign — chỉ danh tính + tile Cài đặt

```
╔══════════════════════════════════════════════╗  nền dawnBlush (secondaryGradient)
║  ( ✨ Hồ sơ tình yêu )                          ║  eyebrow badge (GIỮ)
║  Hồ sơ                                          ║  pageTitle (GIỮ)
║  Câu chuyện của hai bạn                          ║  pageSubtitle (GIỮ)
║                                                ║
║  ┌──────────────────────────────────────────┐ ║  ← HERO couple card r32 (GIỮ NGUYÊN)
║  │  ( badge: còn N ngày tới kỷ niệm )         │ ║
║  │                                            │ ║
║  │  (avatar)  P1 ♥ P2                         │ ║
║  │            Bên nhau từ 14/02/2024          │ ║
║  └──────────────────────────────────────────┘ ║
║                                                ║
║  ┌──────────────────────────────────────────┐ ║  ← Stats section card (GIỮ NGUYÊN)
║  │ Hành trình của chúng mình                  │ ║   journeySnapshotTitle
║  │ [♥ years][📅 months][📆 days][🖼 memories] │ ║   2×2 stat cards
║  └──────────────────────────────────────────┘ ║
║                                                ║
║  ┌──────────────────────────────────────────┐ ║  ← ✨ TILE MỚI "Cài đặt" (section card)
║  │ ┌────────────────────────────────────────┐│ ║   _buildSectionCard? → KHÔNG; tile đơn
║  │ │ [⚙️] Cài đặt                       ›    ││ ║   (xem ghi chú dưới: tile đơn full-width)
║  │ │      Nhắc nhở, ngôn ngữ, tài khoản       ││ ║
║  │ └────────────────────────────────────────┘│ ║
║  └──────────────────────────────────────────┘ ║
╚══════════════════════════════════════════════╝
```
> **Tile "Cài đặt" ở Profile** = tile đơn white .72 r22 viền rose .10 (KHÔNG bọc section card — đứng một mình full-width, margin trên 18 như các section). Icon tile 44 r16 nền rose .12 `Icons.settings_rounded` accentRose. Tên `settingsTitle` 15/w700 + subtitle `settingsProfileTileSubtitle` 12 textSecondary; chevron phải. Tap → push `SettingsScreen`.

### (2) Màn SETTINGS — 3 module + danger + footer

```
╔══════════════════════════════════════════════╗  nền dawnBlush, AppBar phẳng
║  ‹   Cài đặt                                   ║  back rose, title 18/w800
╟──────────────────────────────────────────────╢
║  ┌──────────────────────────────────────────┐ ║  ← MODULE 🔔 (section card white .84 r28)
║  │ Nhắc nhở                                   │ ║   settingsRemindersModuleTitle 18/w800
║  │ Cột mốc, kỷ niệm & lời nhắc riêng          │ ║   settingsRemindersModuleSubtitle 12
║  │ ┌────────────────────────────────────────┐│ ║   ← master toggle (DI CHUYỂN nguyên)
║  │ │ [🔔] Nhắc cột mốc & kỷ niệm   [===O]    ││ ║   remindersToggleLabel + Desc (đã v2)
║  │ │      Tự nhắc các cột mốc… Cần bật để…    ││ ║
║  │ └────────────────────────────────────────┘│ ║
║  │ ┌────────────────────────────────────────┐│ ║   ← tile sub Cột mốc (DI CHUYỂN; mờ khi off)
║  │ │ [🎉] Cột mốc & kỷ niệm      5 mốc  ›    ││ ║   remindersV2MilestoneEntry* + badge
║  │ │      Chọn cột mốc muốn được nhắc          ││ ║
║  │ └────────────────────────────────────────┘│ ║
║  │ ┌────────────────────────────────────────┐│ ║   ← tile sub custom (DI CHUYỂN; gate force-open)
║  │ │ [📝] Lời nhắc của chúng mình   3   ›    ││ ║   customRemindersEntry* + badge
║  │ │      Tự tạo mốc riêng của hai bạn         ││ ║
║  │ └────────────────────────────────────────┘│ ║
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║  ← MODULE 🌐 (section card)
║  │ Ngôn ngữ                                   │ ║   languageTitle 18/w800
║  │ Ngôn ngữ hiển thị của ứng dụng             │ ║   languageSubtitle 12
║  │ ┌────────────────────────────────────────┐│ ║   ← tile ngôn ngữ (DI CHUYỂN nguyên)
║  │ │ [VI] Ngôn ngữ                       ›   ││ ║   showLanguagePicker(context)
║  │ │      Tiếng Việt                          ││ ║
║  │ └────────────────────────────────────────┘│ ║
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║  ← MODULE 👤 (section card)
║  │ Tài khoản & dữ liệu                        │ ║   settingsAccountModuleTitle 18/w800
║  │ Câu chuyện, dữ liệu & tài khoản            │ ║   settingsAccountModuleSubtitle 12
║  │ ┌────────────────────────────────────────┐│ ║   ← tile Chỉnh sửa câu chuyện (DI CHUYỂN)
║  │ │ [✏️] Chỉnh sửa câu chuyện           ›   ││ ║   editOurStoryBtn → setup
║  │ │      Đổi tên, ngày yêu, ảnh đại diện      ││ ║   settingsEditStorySubtitle 12
║  │ └────────────────────────────────────────┘│ ║
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║  ← DANGER CARD (DI CHUYỂN NGUYÊN, white .92
║  │ [🧹] Quản lý dữ liệu                       │ ║   r28 viền error .14) — _buildDangerZone
║  │ ⚠ (warning context box)                    │ ║
║  │ [ Xoá dữ liệu cục bộ ]   (nếu Firebase)    │ ║
║  │ [ Rời khỏi couple ]      (outlined đỏ)      │ ║
║  │ ──────── Không thể hoàn tác ────────        │ ║   divider
║  │ [ XOÁ TÀI KHOẢN ]        (filled đỏ)        │ ║
║  └──────────────────────────────────────────┘ ║
║  [ ↩ Đăng xuất ]                                ║  ← nút đăng xuất (DI CHUYỂN nguyên)
║                                                ║
║         🛡 Chính sách bảo mật ↗                  ║  ← footer link (DI CHUYỂN nguyên)
╚══════════════════════════════════════════════╝
```
> Khoảng cách dọc giữa các module/card = **18** (đúng spacing profile hiện có). Đăng xuất cách danger 18; privacy link cách 12.

### (3) Sub CỘT MỐC & KỶ NIỆM — Giờ mặc định + giờ riêng mỗi mốc (Dv8)

```
╔══════════════════════════════════════════════╗  nền dawnBlush, AppBar phẳng
║  ‹   Cột mốc & kỷ niệm                         ║  back rose, title 18/w800
╟──────────────────────────────────────────────╢
║  Chọn cột mốc muốn được nhắc và giờ nhắc.       ║  caption 13 textSecondary (cập nhật)
║                                                ║
║  ┌──────────────────────────────────────────┐ ║  ← tile GIỜ MẶC ĐỊNH (đầu list, nổi bật)
║  │ [🕐] Giờ mặc định           20:00   ›      │ ║   accentGold tile, giá trị rose w800 + chevron
║  │      Áp dụng cho mốc chưa đặt giờ riêng     │ ║   settingsDefaultTimeSubtitle 12
║  └──────────────────────────────────────────┘ ║
║                                                ║
║  ┌──────────────────────────────────────────┐ ║  ← mốc — theo MẶC ĐỊNH
║  │ [💯] Mỗi 100 ngày                  [===O] │ ║   icon + tên 15/w700 + toggle
║  │      Ăn mừng mỗi 100 ngày bên nhau         │ ║   desc 12
║  │      Sắp tới: 700 ngày · 12/08/2026         │ ║   next 12/w600 accentRose
║  │      🕐 Theo mặc định · 20:00               │ ║   ← chip-giờ MỜ (textTertiary) tap→đặt riêng
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║  ← mốc — đã đặt GIỜ RIÊNG
║  │ [🎂] Kỷ niệm hằng năm              [===O] │ ║
║  │      Mỗi năm tròn ngày yêu nhau            │ ║
║  │      Sắp tới: 1 năm · 14/02/2027            │ ║
║  │      🕐 21:30   ✕                           │ ║   ← chip-giờ ĐẬM rose; ✕ → về mặc định
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║  ← mốc TẮT → chip-giờ ẩn
║  │ [💌] 520 ngày                      [O===] │ ║
║  │      "Anh yêu em" — mốc 520 ngày           │ ║
║  │      Sắp tới: 13/03/2026                    │ ║   (không có dòng chip-giờ)
║  └──────────────────────────────────────────┘ ║
║  ┌──────────────────────────────────────────┐ ║  ← mốc ĐÃ QUA → item opacity .6
║  │ [🏆] 1000 ngày                     [===O] │ ║
║  │      Tròn 1000 ngày yêu nhau               │ ║
║  │      Đã qua                                 │ ║   (chip-giờ vẫn hiện theo opacity item)
║  └──────────────────────────────────────────┘ ║
║   … (1314, Nửa năm, Lâu chưa đăng ảnh)         ║
╚══════════════════════════════════════════════╝
```

### (4) Chi tiết chip-giờ — đặt riêng / về mặc định

```
 Mốc THEO MẶC ĐỊNH (customHour == null):
   ┌─────────────────────────────────┐
   │ 🕐  Theo mặc định · 20:00         │   nền rose .06, chữ textTertiary 12/w600
   └─────────────────────────────────┘   tap toàn chip → showTimePicker → đặt giờ RIÊNG

 Mốc ĐÃ ĐẶT RIÊNG (customHour != null):
   ┌──────────────────┐
   │ 🕐  21:30    ✕   │   nền rose .12, "21:30" accentRose 12/w800; ✕ rose .6
   └──────────────────┘   tap "21:30" → đổi giờ riêng;  tap ✕ → setMilestoneTime(null) (về mặc định)
```

---

## Spec chi tiết (token — bám design system, KHÔNG token mới)

### Chung 2 màn mới (`SettingsScreen` + sub mốc đã có)
- **Nền:** `AppColors.dawnBlush` (secondaryGradient) — `Container(decoration: BoxDecoration(gradient:…))` + `Scaffold(backgroundColor: Colors.transparent)`.
- **AppBar:** phẳng trong suốt (`backgroundColor: Colors.transparent`, `elevation: 0`); back `Icons.arrow_back_ios_new_rounded` accentRose; title 18/w800 textPrimary; KHÔNG action.
- **SafeArea** bao body; padding ngoài `(16,16,16, bottomInset?)` — Settings dùng `(16, 4, 16, 24)`.

### (1) Tile "Cài đặt" ở Profile
- Tile đơn full-width (KHÔNG section card): white .72, r22, viền `accentRose` .10, padding 16.
- Icon tile 44×44 r16 nền accentRose .12, `Icons.settings_rounded` size 20 accentRose. Gap 14.
- Tên `settingsTitle` 15/w700 textPrimary; subtitle `settingsProfileTileSubtitle` 12 textSecondary h1.4.
- Phải: `Icons.chevron_right_rounded` textSecondary .5.
- **Vị trí:** thay thế các section cũ; đặt sau `_buildStatsSection`, margin trên 18.

### (2) Module trong Settings = `_buildSectionCard` (tái dùng)
- Card: white .84, r28, viền white .82, shadow black .045 blur 18 (0,10). Title 18/w800 textPrimary, subtitle 12 textSecondary, gap title→child 18.
- **Tile bên trong** = pattern hiện có: white .72, r22, viền accentRose .10 (riêng "Giờ mặc định" dùng accentGold .12 như tile Giờ nhắc cũ), padding 16; icon tile 44 r16; gap 14; spacing dọc giữa tile **12**.
- **Tile sub có badge** ("{n} mốc" / "{n}"): `Container` padding (10,4), nền accentRose .12, r999, text 13/w800 accentRose, ẩn khi 0 → rồi chevron.

#### Module 🔔 Nhắc nhở (DI CHUYỂN nguyên `_buildRemindersSection`)
- Master toggle tile, tile "Cột mốc & kỷ niệm" (dim .45 khi off, AnimatedOpacity 200ms), tile "Lời nhắc của chúng mình" (gate force-open) — **GIỮ NGUYÊN** code/copy/hành vi (chỉ bỏ tile "Giờ nhắc" độc lập — giờ chuyển vào sub Cột mốc làm "Giờ mặc định", xem Handoff).
- Section title/subtitle: đổi sang `settingsRemindersModuleTitle`/`Subtitle` (hoặc giữ `remindersTitle`/`remindersSubtitle` — Dev chọn 1; khuyến nghị key mới module-level cho gọn).

#### Module 🌐 Ngôn ngữ (DI CHUYỂN nguyên `_buildLanguageSection`)
- Tile ngôn ngữ y nguyên: icon tile 44 r16 nền accentRose .10 chứa mã ngôn ngữ ("VI"/"EN" 14/w800 accentLove) hoặc 🌐 (system); label `languageTitle` 12/w600 textSecondary + giá trị `appLanguageLabel` 15/w700 textPrimary; chevron. Tap → `showLanguagePicker(context)` (sheet hiện có, KHÔNG đổi).
- Section title/subtitle: `languageTitle`/`languageSubtitle` (GIỮ).

#### Module 👤 Tài khoản & dữ liệu
- **Tile "Chỉnh sửa câu chuyện"** (đổi nút→tile): white .72 r22 viền rose .10; icon tile 44 r16 nền rose .12 `Icons.edit_rounded` size 20 accentRose; tên `editOurStoryBtn` 15/w700; subtitle `settingsEditStorySubtitle` 12; chevron. Tap → push `SetupScreen` rồi `loadCoupleForUser` (GIỮ logic cũ).
- **Danger card** (`_buildDangerZone`, DI CHUYỂN NGUYÊN): white .92 r28 viền error .14; header icon 42 r14 nền error .10 `delete_sweep_rounded`; warning box error .06 viền .14; nút "Xoá dữ liệu cục bộ" OutlinedButton (chỉ Firebase) / cảnh báo local-fallback; "Rời khỏi couple" OutlinedButton error viền .30; divider "Không thể hoàn tác" error .15 + nhãn error .50; "Xoá tài khoản" FilledButton error filled. **Mọi dialog (clear/leave/delete) + hành vi GIỮ Y NGUYÊN.** Đặt là card riêng (KHÔNG bọc `_buildSectionCard`) — TÁCH BIỆT khỏi 3 module.

### (3) Sub "Cột mốc & kỷ niệm" — bổ sung Dv8
- **Tile "Giờ mặc định"** (đầu list, trước 7 mốc): tái dùng pattern tile "Giờ nhắc" cũ — white .72 r22 viền `accentGold` .12; icon tile 44 r16 nền accentGold .12 `Icons.schedule_rounded` size 20 accentGold; gap 14; tên `settingsDefaultTimeLabel` 15/w700 textPrimary + subtitle `settingsDefaultTimeSubtitle` 12 textSecondary h1.4; phải: giờ `time.format(context)` 15/w800 accentRose + chevron textSecondary .5. Tap → `showTimePicker` → `reminderProvider.setTime(...)` (logic cũ, reschedule mốc chưa-đặt-riêng). SizedBox 12 dưới trước danh sách mốc.
- **Item mốc** (mở rộng `_MilestoneTile` hiện có): GIỮ icon tile + tên + desc + toggle + dòng next/đã-qua/pending. **THÊM dòng chip-giờ** dưới dòng next-fire (chỉ khi mốc BẬT):
  - **Theo mặc định** (`customHour == null`): chip nền `accentRose` .06, r999, padding (10,5); icon `Icons.schedule_rounded` size 13 textTertiary + text `settingsMilestoneUsesDefault({time})` 12/w600 **textTertiary**. Tap chip → `showTimePicker` (initial = giờ mặc định) → `setMilestoneTime(type, picked)`.
  - **Đã đặt riêng** (`customHour != null`): chip nền `accentRose` .12, r999, padding (10,5); icon `Icons.schedule_rounded` size 13 accentRose + giờ riêng `time.format` 12/**w800 accentRose** + SizedBox 6 + `Icons.close_rounded` size 14 accentRose .6 (vùng tap ✕ ≥ 28px). Tap vùng giờ → đổi giờ; tap ✕ → `setMilestoneTime(type, null)` (về mặc định).
  - **Mốc TẮT:** ẩn dòng chip-giờ (chỉ icon+tên+desc+next).
  - **Mốc đã qua:** chip-giờ vẫn render nhưng nằm trong `Opacity .6` của item.
- Spacing: dòng chip-giờ cách dòng next-fire **6**; chip cao ~26.

### Time picker
- `showTimePicker` native (locale-aware, đã dùng trong app). Không tự dựng. `initialTime`: giờ mặc định → `TimeOfDay(settings.hour, settings.minute)`; mốc đã riêng → giờ riêng; mốc theo mặc định khi ĐẶT riêng → khởi tạo từ giờ mặc định.

---

## States

| State | Khi nào | Mô tả hình |
|-------|---------|-----------|
| **Profile gọn** | luôn | Chỉ hero + stats + tile "Cài đặt". KHÔNG còn reminders/ngôn ngữ/danger/edit rải rác. |
| **Settings — master ON** | reminders.enabled=true | Tile "Cột mốc" sáng (tap được). Tile custom tap → list. |
| **Settings — master OFF** | enabled=false | Tile "Cột mốc" mờ .45 không tap. Tile custom vẫn tap → dialog force-open (Dv6). |
| **Mốc — theo mặc định** | bật + customHour==null | chip-giờ mờ "Theo mặc định · {giờ}" (textTertiary). Tap → đặt riêng. |
| **Mốc — giờ riêng** | bật + customHour!=null | chip-giờ đậm rose "{giờ} ✕". Tap giờ→đổi; ✕→về mặc định. |
| **Mốc — tắt** | toggle off | chip-giờ ẩn; chỉ desc + (next ẩn). Item KHÔNG dim. |
| **Mốc — đã qua** | one-shot trôi | item opacity .6, dòng phụ "Đã qua", chip-giờ theo opacity. |
| **Mốc — chưa tính được** | daysTogether<0 | next ẩn → "Sẽ tính khi tới ngày kỷ niệm"; chip-giờ vẫn cho đặt (nếu bật). |
| **Đổi Giờ mặc định** | tap tile Giờ mặc định | mọi mốc theo-mặc-định cập nhật chip + reschedule (Dev). Mốc giờ-riêng KHÔNG đổi. |
| **Ngôn ngữ — selected** | locale hiện tại | tile hiện "VI/EN" + nhãn ngôn ngữ; mở picker sheet để đổi. |
| **Danger zone** | luôn | y nguyên: cache (Firebase) / cảnh báo local / rời couple / divider / xoá tài khoản đỏ filled. Mọi dialog xác nhận giữ nguyên. |
| **Force-open dialog** | master OFF + tap custom | AlertDialog mời bật (Dv6) — y nguyên reminders v2. |

> Không có state "empty/loading" cho Settings (list cấu hình cố định). Sub mốc: 7 mốc cố định, không empty.

---

## Interaction & animation
- **Push `SettingsScreen` + sub mốc:** `MaterialPageRoute` mặc định (đồng nhất app).
- **Tile "Cột mốc" dim khi master off:** `AnimatedOpacity` **200ms easeOutCubic** (GIỮ như hiện có).
- **Toggle mốc / chip-giờ xuất hiện-ẩn:** khi bật/tắt mốc, dòng chip-giờ vào/ra bằng `AnimatedSwitcher`/`AnimatedSize` **200ms easeOutCubic** (không bắt buộc, khuyến nghị cho mượt).
- **Chip-giờ đổi state (mặc định ↔ riêng):** đổi nền/chữ bằng `AnimatedContainer` **200ms easeOutCubic**.
- **Time picker:** native `showTimePicker` (transition hệ thống).
- **Dialog force-open / danger dialogs:** `showDialog` mặc định (~150ms hệ thống) — GIỮ.
- Mọi animation mới trong dải **200–320ms easeOutCubic** theo chuẩn dự án.

---

## Copy (song ngữ — bắt buộc; Dev bê thẳng vào ARB)

> Prefix MỚI `settings*`. **Tái dùng key cũ KHÔNG đổi** cho mọi mục di chuyển (xem bảng "tái dùng" dưới).

### Nhãn MỚI (prefix `settings*`)
| Key | VI | EN |
|-----|----|----|
| settingsTitle | Cài đặt | Settings |
| settingsProfileTileSubtitle | Nhắc nhở, ngôn ngữ, tài khoản | Reminders, language, account |
| settingsRemindersModuleTitle | Nhắc nhở | Reminders |
| settingsRemindersModuleSubtitle | Cột mốc, kỷ niệm & lời nhắc riêng | Milestones, anniversaries & your own reminders |
| settingsAccountModuleTitle | Tài khoản & dữ liệu | Account & data |
| settingsAccountModuleSubtitle | Câu chuyện, dữ liệu & tài khoản | Your story, data & account |
| settingsEditStorySubtitle | Đổi tên, ngày yêu, ảnh đại diện | Edit names, anniversary date, photo |
| settingsDefaultTimeLabel | Giờ mặc định | Default time |
| settingsDefaultTimeSubtitle | Áp dụng cho mốc chưa đặt giờ riêng | Used for milestones without a custom time |
| settingsMilestoneUsesDefault | Theo mặc định · {time} | Default · {time} |
| settingsMilestoneCustomTimeReset | Về giờ mặc định | Reset to default time |

> `{time}` = placeholder (String). `settingsMilestoneCustomTimeReset` dùng làm tooltip/semantics cho nút ✕ (accessibility), không hiển thị nhãn.

### Nhãn cập nhật VALUE (giữ key) — caption sub mốc thêm ý "giờ nhắc"
| Key | VI (cập nhật) | EN (cập nhật) |
|-----|----|----|
| remindersV2MilestoneScreenCaption | Chọn cột mốc muốn được nhắc và giờ nhắc. | Choose the milestones you want and when to be reminded. |

### TÁI DÙNG nguyên (KHÔNG đổi key/value) — chỉ đổi VỊ TRÍ
| Mục | Key tái dùng |
|-----|----|
| Module ngôn ngữ (title/subtitle/tile) | `languageTitle`, `languageSubtitle`, `appLanguageLabel`, picker sheet hiện có |
| Master toggle + details | `remindersToggleLabel`, `remindersToggleDesc` (đã đổi value ở v2) |
| Tile sub Cột mốc | `remindersV2MilestoneEntryTitle`, `remindersV2MilestoneEntrySubtitle`, `remindersV2MilestoneCountBadge` |
| Tile sub custom + màn | toàn bộ `customReminders*` |
| Màn mốc (tên/desc/next/đã-qua/pending) | `milestone*`, `remindersV2Milestone*` |
| Force-open dialog | `remindersV2ForceOpen*` |
| Chỉnh sửa câu chuyện | `editOurStoryBtn` |
| Đăng xuất + dialog | `signOutBtn`, `signOutDialogTitle/Content/ConfirmBtn` |
| Danger zone (toàn bộ) | `dataManagementTitle/Desc`, `clearDataNote`, `clearLocalDataBtn`, `localFallbackWarning`, `leaveCoupleBtn`, `profileDangerIrreversible`, `deleteAccountBtn` + mọi dialog clear/leave/delete |
| Privacy link | `privacyPolicyLabel` |
| Giờ (cũ "Giờ nhắc") | `remindersTimeLabel` → **không dùng nữa** ở vị trí cũ; "Giờ mặc định" dùng key MỚI `settingsDefaultTimeLabel` (xem Handoff: tile Giờ nhắc cũ bị gỡ khỏi section, thay bằng Giờ mặc định trong sub mốc). |

---

## Handoff / Dev notes

> Dev DI CHUYỂN UI, **GIỮ NGUYÊN logic** (provider/dialog/permission). Không đụng backend/rules.

1. **Profile (`lib/screens/profile_screen.dart`):**
   - GIỮ: `_buildPageHeader`, `_buildHeroCard`, `_buildStatsSection`, `_buildCoupleInfoSection` (couple info — *PO xác nhận: info card "start date/milestone/invite code" thuộc danh tính → GIỮ ở Profile cùng hero+stats; nếu PO muốn chuyển sang Settings thì báo lại*).
   - GỠ khỏi Profile + chuyển sang Settings: `_buildActionsSection` (Chỉnh sửa câu chuyện), `_buildRemindersSection` + `_showForceOpenDialog`, `_buildLanguageSection`, `_buildSignOutButton`, `_buildDangerZone` + 3 dialog (`_showClearLocalDialog`/`_showLeaveCoupleDialog`/`_showDeleteAccountDialog`), `_buildPrivacyPolicyLink`.
   - THÊM: tile "⚙️ Cài đặt" (tile đơn, spec mục (1)) → `Navigator.push(SettingsScreen)`.
2. **Màn mới `lib/screens/settings_screen.dart`:** Scaffold nền dawnBlush + AppBar phẳng title `settingsTitle`. Body `SingleChildScrollView` padding (16,4,16,24): module 🔔 (di chuyển `_buildRemindersSection`) → module 🌐 (di chuyển `_buildLanguageSection`) → module 👤 (tile Chỉnh sửa câu chuyện + danger card) → nút Đăng xuất → privacy link. Di chuyển kèm các helper/dialog tương ứng vào file này (hoặc tách widget). **Truyền `couple` + `lastPhotoDate`** vào Settings (reminders section cần) — đọc từ `CoupleProvider`/`PhotoProvider` như Profile.
3. **Per-milestone time (Dv8) — sub `milestone_reminders_screen.dart`:**
   - Thêm tile "Giờ mặc định" đầu list (spec (3)) → `showTimePicker` → `reminderProvider.setTime(...)` (Dev đảm bảo reschedule mốc chưa-đặt-riêng — model/persist ở reminders Dv8/dev.md).
   - Mở rộng `_MilestoneTile`: thêm dòng chip-giờ (chỉ khi mốc bật). Đọc giờ riêng từ provider (`milestoneCustomTime(type)` → `TimeOfDay?`, null=mặc định). Tap chip→`showTimePicker`→`setMilestoneTime(type, picked)`; tap ✕→`setMilestoneTime(type, null)`. (Tên method Dev tự chốt trong reminders dev.md — Dv8 đã spec persist Hive null=mặc định.)
4. **"Giờ nhắc" cũ:** tile độc lập trong section Reminders bị **gỡ** (logic giờ chuyển thành "Giờ mặc định" trong sub mốc). `remindersTimeLabel` không dùng ở vị trí cũ; `setTime` vẫn là API đổi giờ mặc định.
5. **Tái dùng:** `_buildSectionCard`, tile white .72 r22, `Switch.adaptive` activeThumbColor accentRose, danger card + 3 dialog, `showLanguagePicker`, AppBar/nền dawnBlush pattern. KHÔNG token mới.
6. **Force-open (Dv6), custom reminders v1, reminders v2** phải còn nguyên hành vi sau khi chuyển vào Settings — chỉ đổi nơi đặt UI.
7. **ARB:** thêm key `settings*` (placeholder `{time}` String), cập nhật value `remindersV2MilestoneScreenCaption`; gen-l10n; vi+en parity; KHÔNG hardcode.
8. **analyze sạch** sau khi di chuyển (import dọn theo file mới).

---

## Acceptance (design)
- [x] Wireframe đủ 4: Profile gọn, Settings (3 module + danger + footer), sub Cột mốc (giờ mặc định + giờ riêng), chi tiết chip-giờ (đặt riêng/về mặc định).
- [x] Spec token chính xác (hex/alias/radius/spacing/typography/shadow) bám design system; tái dùng card/tile/Switch/danger; KHÔNG token mới.
- [x] States đủ: profile gọn, master on/off, mốc theo-mặc-định/giờ-riêng/tắt/đã-qua/chưa-tính, đổi giờ mặc định, ngôn ngữ selected, danger, force-open.
- [x] Interaction & animation 200–320ms easeOutCubic; time picker native.
- [x] Copy VI+EN: nhãn `settings*` mới + caption cập nhật + bảng tái dùng key cũ rõ ràng.
- [x] Handoff nêu rõ DI CHUYỂN gì (giữ logic), file mới, widget/dialog tái dùng, control giờ-theo-mốc (Dv8), giữ force-open/custom/v2.
- [x] Giữ độ "nguy hiểm" danger zone (compliance) — bê nguyên khối.

## Nhật ký design
- [2026-05-31] [Designer] Thiết kế feature **settings**: (1) Profile gọn còn hero+stats + tile "⚙️ Cài đặt"; (2) màn `SettingsScreen` 3 module (🔔 Nhắc nhở / 🌐 Ngôn ngữ / 👤 Tài khoản & dữ liệu) dạng section card kiểu iOS + danger card tách biệt + footer privacy; (3) sub "Cột mốc & kỷ niệm" thêm **Giờ mặc định** (tile đầu) + **giờ riêng mỗi mốc** (Dv8) bằng chip-giờ inline — mờ "Theo mặc định · {giờ}" khi null, đậm "{giờ} ✕" khi đặt riêng, ✕ = về mặc định; (4) chi tiết chip-giờ. Quyết định UX: module=`_buildSectionCard` tái dùng (không widget nhóm mới); control giờ INLINE từng mốc (không tách màn); "về mặc định" = nút ✕ 1-chạm không dialog; danger zone bê NGUYÊN khối vào module Tài khoản cuối Settings (giữ compliance); "Chỉnh sửa câu chuyện" đổi nút→tile. Copy song ngữ: prefix `settings*` cho nhãn mới + bảng tái dùng key cũ cho mọi mục di chuyển (giữ nguyên hành vi). Token bám design system, KHÔNG token mới.
```
