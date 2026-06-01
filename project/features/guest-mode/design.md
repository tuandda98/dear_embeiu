# 🎨 Design — Guest mode

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`../../../CLAUDE.md` mục 8). CHỈ thiết kế, không code.

- **Trạng thái design:** xong
- **Người/role:** Designer

## Mục tiêu thiết kế
Thiết kế đường vào "Dùng thử không cần đăng nhập" (fix Apple 5.1.1) gồm 2 phần:
1. **Nút "Dùng thử không cần đăng nhập"** ở `login_screen` — nhẹ, không lấn át nút "Đăng nhập" rose chính.
2. **`GuestCounterScreen`** mới — màn đếm ngày yêu thuần local: chọn ngày kỷ niệm → CounterCard hero (tái dùng) + ngày bắt đầu + đếm ngược kỷ niệm kế + milestone progress + **CTA ấm áp dẫn về login/register** để ghép đôi & lưu ảnh chung.

Nguyên tắc: tái dùng 100% token/component có sẵn, KHÔNG token mới. Đồng nhất với home/login. Guest thuần local, không gallery/ghép đôi trong màn này — chỉ CTA dẫn tới login.

## User flow
```
login_screen
   │  (tap "Dùng thử không cần đăng nhập")
   ▼
GuestCounterScreen
   ├─ CHƯA chọn ngày (empty)  → tap "Chọn ngày kỷ niệm" → DatePicker (native, locale-aware)
   │                                                         │
   │                                                         ▼  (lưu Hive guest_settings)
   └─ ĐÃ chọn ngày  → CounterCard hero + ngày bắt đầu + đếm ngược kỷ niệm + milestone
                       ├─ tap "Đổi ngày" → DatePicker (sửa lại)
                       └─ CTA card "Đăng nhập để ghép đôi & lưu ảnh chung"
                                ├─ "Đăng nhập" → login (pop về login)
                                └─ "Đăng ký"   → register
   AppBar back (←) → quay lại login
```

## Wireframe (ASCII)

### (1) login_screen — thêm nút "Dùng thử" (trong form card glass, dưới nút Đăng nhập)
```
┌──────────────────────────────────────────┐  nền secondaryGradient (dawnBlush)
│  🔒 Chào mừng trở lại            [VI|EN]  │
│  Đăng nhập                                │
│  …subtitle…                               │
│ ┌── form card glass (white α.22, bo 28) ──┐│
│ │ Email     [____________________]        ││
│ │ Mật khẩu  [____________________] 👁     ││
│ │ ┌────────────────────────────────────┐ ││
│ │ │           Đăng nhập   (rose)        │ ││  ← FilledButton rose (giữ nguyên)
│ │ └────────────────────────────────────┘ ││
│ │      ─────────  hoặc  ─────────         ││  ← divider mảnh (textSecondary α.3)
│ │ ┌────────────────────────────────────┐ ││
│ │ │ 🤍  Dùng thử không cần đăng nhập    │ ││  ← TextButton.icon, foreground accentRose
│ │ └────────────────────────────────────┘ ││     (KHÔNG nền, nhẹ — không lấn nút chính)
│ │       Mới ở đây?   Đăng ký              ││  ← giữ nguyên link đăng ký
│ └────────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

### (2) GuestCounterScreen — EMPTY (chưa chọn ngày)
```
┌──────────────────────────────────────────┐  nền secondaryGradient (dawnBlush)
│ ←                               [VI|EN]   │  AppBar phẳng, back về login
│                                           │
│  ✨ Chế độ dùng thử          (eyebrow pill)│
│  Đếm ngày yêu                  (pageTitle) │
│  Nhập ngày hai bạn bắt đầu để xem đã …    │  (pageSubtitle α.84)
│                                           │
│   ┌── empty card glass (white α.22, bo 28)┐│
│   │            ♥  (heart badge 64)         ││  ← tim trắng trên vòng glass
│   │   Bắt đầu đếm ngày yêu của bạn         ││  (title 18 w700 textOnGradient)
│   │   Chọn ngày kỷ niệm để xem hai bạn     ││  (body 14 textOnGradient α.85)
│   │   đã bên nhau bao lâu rồi.             ││
│   │  ┌──────────────────────────────────┐ ││
│   │  │ 📅  Chọn ngày kỷ niệm   (rose)    │ ││  ← FilledButton.icon rose, bo 20
│   │  └──────────────────────────────────┘ ││
│   └────────────────────────────────────────┘│
│                                           │
│   ┌── CTA card (white α.16, bo 28) ───────┐│  ← luôn hiện (cả empty & có ngày)
│   │ 💞 Muốn lưu kỷ niệm cùng người ấy?     ││
│   │ Đăng nhập để ghép đôi & lưu ảnh chung. ││
│   │ [ Đăng nhập (rose) ]  [ Đăng ký (text)]││
│   └────────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

### (3) GuestCounterScreen — ĐÃ chọn ngày
```
┌──────────────────────────────────────────┐  nền secondaryGradient (dawnBlush)
│ ←                               [VI|EN]   │
│  ✨ Chế độ dùng thử                        │
│  Đếm ngày yêu                              │
│  Nhập ngày hai bạn bắt đầu …               │
│                                           │
│  ┌── CounterCard (HERO sunsetRomance bo28)┐│  ← TÁI DÙNG widget, không vẽ mới
│  │              ♥                          ││
│  │     CHÚNG MÌNH ĐÃ BÊN NHAU              ││  (title mặc định l10n)
│  │     [năm]  |  [tháng]  |  [ngày]        ││
│  │     Bắt đầu từ 14 tháng 2, 2024         ││  (subtitle = guestStartFrom + ngày)
│  │     ♥ Còn 12 ngày tới kỷ niệm           ││  (footer pill = đếm ngược/hôm nay)
│  └────────────────────────────────────────┘│
│                                           │
│  ┌── milestone card (white, bo 24) ───────┐│  ← layout giống home (tái dùng copy)
│  │ 🏅 Cột mốc kế: 1 năm                    ││
│  │ Chỉ còn 12 ngày nữa thôi                ││
│  │ ▓▓▓▓▓▓▓▓░░░░░░░  73%                    ││  (LinearProgress accentRose)
│  │ 353 ngày                          73%   ││
│  └────────────────────────────────────────┘│
│                                           │
│  ┌──────────────────────────────────────┐ ││
│  │ 📅  Đổi ngày kỷ niệm  (OutlinedButton) │ ││  ← nút phụ, viền rose α.45 bo 20
│  └──────────────────────────────────────┘ ││
│                                           │
│  ┌── CTA card (white α.16, bo 28) ───────┐│
│  │ 💞 Muốn lưu kỷ niệm cùng người ấy?     ││
│  │ Đăng nhập để ghép đôi & lưu ảnh chung. ││
│  │ [ Đăng nhập (rose) ]  [ Đăng ký (text)]││
│  └────────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

## Spec chi tiết (token chính xác — bám design system, KHÔNG token mới)

### Chung GuestCounterScreen
- **Nền:** `AppColors.secondaryGradient` (dawnBlush) — giống login/home. `Scaffold(backgroundColor: transparent)` + `Container(gradient)` + `SafeArea`.
- **Layout:** `SingleChildScrollView`, padding `EdgeInsets.all(20)` (đồng bộ login). Tối đa `maxWidth: 460` như login để đẹp trên tablet (tùy chọn).
- **AppBar:** phẳng, `backgroundColor: transparent`, `elevation: 0`, leading back arrow trắng (`AppColors.white`). `LanguageToggleButton` ở `actions` (góc phải) — đồng nhất login.
- **Header (eyebrow + title + subtitle):** tái dùng đúng pattern login/home:
  - Eyebrow pill: `white α.12` bo `999`, viền `white α.18`, icon `Icons.auto_awesome_rounded` size 14 `white α.92`, text `AppTheme.pageEyebrowStyle()`. Copy = `guestModeBadge`.
  - Title: `AppTheme.pageTitleStyle()`. Copy = `guestCounterTitle`.
  - Subtitle: `AppTheme.pageSubtitleStyle(alpha: 0.84)`. Copy = `guestCounterSubtitle`.
  - Spacing: eyebrow → 14 → title → 8/10 → subtitle → 20 → nội dung.

### CounterCard (tái dùng — KHÔNG sửa)
- Truyền `years/months/days` từ `CounterData.calculateFromAnniversary(guestDate)`.
- `subtitle:` = `l10n.guestCounterStartFrom(<ngày locale-aware>)` (đề xuất tách key riêng; nếu PO muốn tiết kiệm có thể tái dùng `homeCounterStartFrom`).
- `footer:` = `daysUntil == 0 ? l10n.todayIsAnniversary : l10n.daysUntilNextAnniversary(daysUntil)` — **tái dùng nguyên key home** (không cần key mới).
- Render mặc định breakdown (years/months/days), KHÔNG dùng `totalDays` hero-number.

### Empty card (chưa chọn ngày)
- Container `white α.22`, bo `28` (radius card lớn `cardRadius`), viền `white α.22`, shadow `black α.06` blur 24 offset (0,14) — **đồng bộ form card login**.
- Padding `EdgeInsets.all(24)`. Căn giữa (`crossAxisAlignment.center`).
- Heart badge: vòng tròn 64×64, `white α.22`, viền `white α.45`, icon `Icons.favorite_rounded` `AppColors.white` size 30 (theo mẫu badge CounterCard, phóng to). Spacing badge → 16 → title → 8 → body → 20 → nút.
- Title: `fontSize 18, w700, color textOnGradient (white)`. Copy = `guestEmptyTitle`.
- Body: `fontSize 14, w400, white α.85, height 1.45`, căn giữa. Copy = `guestEmptyBody`.
- Nút chọn ngày: `FilledButton.icon`, icon `Icons.calendar_today_rounded`, nền `accentRose`, foreground `white`, padding vertical 16, bo `20` (giống nút Đăng nhập). Copy = `guestPickDate`.

### Milestone card (đã chọn ngày)
- **Tái dùng nguyên layout `_buildMilestoneSection` của home_screen**: container `white`, bo `24`, shadow `black α.06` blur 16 offset (0,10). Icon `Icons.workspace_premium_rounded` `accentGold` trên nền `accentGold α.14` bo 14. Tiêu đề `nextMilestonePrefix`, dòng phụ `onlyDaysUntilMilestone`/`milestoneReached`. `LinearProgressIndicator` minHeight 10 `accentRose` nền `surfaceLight` bo 999. Footer 2 dòng `daysCountLabel` + `percentThere`.
- Copy 100% tái dùng key home — KHÔNG key mới.

### Nút "Đổi ngày" (đã chọn ngày)
- `OutlinedButton.icon`, icon `Icons.event_repeat_rounded`, foreground `accentRose`, viền `accentRose α.45` width 1.2, bo `20`, padding vertical 16, full-width. Copy = `guestChangeDate`.

### CTA card (chuyển đổi — G4, luôn hiện)
- Container `white α.16` (glass nhạt như status banner login), bo `28`, viền `white α.18`, padding `EdgeInsets.all(20)`.
- Dòng tiêu đề: icon 💞 `Icons.favorite_rounded` `white` + text `fontSize 16, w700, white`. Copy = `guestCtaTitle`.
- Mô tả: `fontSize 13, white α.88, height 1.45`. Copy = `guestCtaBody`.
- Hàng nút (spacing 12):
  - "Đăng nhập": `FilledButton` nền `accentRose` foreground white bo 20 padding v14 — **Expanded** (nút chính của CTA). Copy = `guestCtaSignIn`. → pop về login.
  - "Đăng ký": `TextButton` foreground white (hoặc `accentRose` nếu trên nền sáng). Copy = `guestCtaRegister`. → push register.

### Nút "Dùng thử" ở login_screen
- Vị trí: trong `_buildFormCard`, **dưới** `FilledButton` "Đăng nhập" (sau SizedBox 14), **trên** hàng "Mới ở đây? / Đăng ký".
- Divider "hoặc": Row `[Expanded(Divider color textSecondary α.3 thickness .8), Text "hoặc"/"or" (textSecondary 12 w600), Expanded(Divider)]`, padding ngang 8 quanh chữ. Spacing trên/dưới 14.
- Nút: `TextButton.icon` (KHÔNG nền — nhẹ, không lấn nút rose), icon `Icons.favorite_border_rounded` `accentRose` size 18, label `fontSize 14, w700, accentRose`. Full-width (`SizedBox(width: double.infinity)`), padding vertical 14. Copy = `guestTryWithoutLogin`. → `Navigator.pushNamed(AppRoutes.guest)`.

## States
- **Empty (chưa chọn ngày):** hiện empty card (heart + CTA chọn ngày) + CTA card chuyển đổi. KHÔNG hiện CounterCard/milestone/đổi-ngày. Không crash.
- **Có ngày (success):** CounterCard hero + milestone card + nút "Đổi ngày" + CTA card. Ẩn empty card.
- **Ngày tương lai (edge):** `CounterData` cho days/months/years; `daysUntil` của next-anniversary vẫn tính được. Đề xuất Dev: chỉ cho chọn ngày `<= now` ở DatePicker (`lastDate: DateTime.now()`) → tránh số âm khó hiểu cho user. (Counter tự xử lý nếu lỡ có ngày tương lai, nhưng chặn ở picker là sạch nhất.)
- **Loading:** không có (thuần local, đọc Hive đồng bộ — không cần spinner). Cold start đọc Hive xong render ngay.
- **Disabled:** không áp dụng.

## Interaction & animation
- **DatePicker:** `showDatePicker` native, `locale: Localizations.localeOf(context)` (locale-aware vi/en). `initialDate` = ngày đã lưu hoặc `DateTime.now()`. `firstDate` ~ `DateTime(1990)`, `lastDate: DateTime.now()`.
- **Chuyển empty ↔ có ngày:** sau khi chọn ngày, gói phần thân trong `AnimatedSwitcher(duration: 260ms, switchInCurve: Curves.easeOutCubic)` (fade) — đúng dải 200–320ms easeOutCubic của design system. (Tùy chọn; tối thiểu là `setState` rebuild.)
- **Back AppBar:** `Navigator.pop` về login (đường vào là `pushNamed` từ login).
- **Nút:** dùng hiệu ứng ripple mặc định Material; không animation tùy biến.

## Copy (song ngữ — bắt buộc). Prefix `guest*`
| Key | VI | EN |
|-----|----|----|
| `guestTryWithoutLogin` | Dùng thử không cần đăng nhập | Try without signing in |
| `guestLoginDivider` | hoặc | or |
| `guestModeBadge` | Chế độ dùng thử | Trial mode |
| `guestCounterTitle` | Đếm ngày yêu | Love day counter |
| `guestCounterSubtitle` | Nhập ngày hai bạn bắt đầu để xem đã bên nhau bao lâu. | Enter the day you started to see how long you've been together. |
| `guestEmptyTitle` | Bắt đầu đếm ngày yêu của bạn | Start counting your love days |
| `guestEmptyBody` | Chọn ngày kỷ niệm để xem hai bạn đã bên nhau bao lâu rồi. | Pick your anniversary date to see how long you've been together. |
| `guestPickDate` | Chọn ngày kỷ niệm | Pick anniversary date |
| `guestChangeDate` | Đổi ngày kỷ niệm | Change anniversary date |
| `guestCounterStartFrom` (param: date) | Bắt đầu từ {date} | Since {date} |
| `guestCtaTitle` | Muốn lưu kỷ niệm cùng người ấy? | Want to keep memories together? |
| `guestCtaBody` | Đăng nhập để ghép đôi & lưu ảnh chung. | Sign in to pair up & share photos together. |
| `guestCtaSignIn` | Đăng nhập | Sign in |
| `guestCtaRegister` | Đăng ký | Sign up |

**Tái dùng (KHÔNG tạo key mới):** `todayIsAnniversary`, `daysUntilNextAnniversary(n)` (footer CounterCard); `nextMilestonePrefix`, `onlyDaysUntilMilestone(n)`, `milestoneReached`, `daysCountLabel(n)`, `percentThere(p)` (milestone card); `fullDateFormat` + `localeName` (format ngày locale-aware như `_formatDate` home). CounterCard title mặc định dùng `youveBeenTogetherFor`.

> Ghi chú PO: `guestCounterStartFrom` có thể bỏ và tái dùng thẳng `homeCounterStartFrom("Bắt đầu từ {date}")` để tiết kiệm chuỗi — copy y hệt. Đề xuất key riêng cho rõ ngữ cảnh guest; PO chốt.

## Handoff / Dev notes
- **login_screen.dart:** thêm divider "hoặc" + `TextButton.icon` "Dùng thử không cần đăng nhập" trong `_buildFormCard`, giữa nút "Đăng nhập" và hàng "Đăng ký". → `Navigator.of(context).pushNamed(AppRoutes.guest)`.
- **Route mới:** thêm `AppRoutes.guest` (vd `/guest`) ở `app_routes.dart` → `GuestCounterScreen`. Guest KHÔNG qua `authGate`/`SessionResolver` (không cần auth).
- **GuestCounterScreen (mới, `lib/screens/guest_counter_screen.dart`):** StatefulWidget local. Đọc/ghi Hive box `guest_settings` key `anniversary` (lưu millis epoch hoặc ISO string) — G3. Đọc trong `initState`. Không Provider, không Firestore/Auth — thuần local (acceptance: guest không gọi backend).
- **Tái dùng:** `CounterData.calculateFromAnniversary(guestDate)` → `CounterCard(years, months, days, subtitle, footer)`. Milestone + next-anniversary: bê đúng các helper từ home_screen (`_getTotalDays`, `_getNextAnniversary`, `_daysUntil`, `_getNextMilestone`, `_milestoneLabel`) và layout `_buildMilestoneSection` — copy logic, không phụ thuộc couple/photo. (Có thể trích ra widget/helper dùng chung nếu muốn, nhưng tối thiểu là copy phần thuần-counter.)
- **Format ngày locale-aware:** `DateFormat(context.l10n.fullDateFormat).format(date)` như `_formatDate` home (đảm bảo `intl` init theo locale).
- **DatePicker:** `lastDate: DateTime.now()` để chặn ngày tương lai (xem States). `locale` truyền vào để vi/en đúng.
- **CTA điều hướng:** "Đăng nhập" → `Navigator.pop` (về login đang ở stack dưới) hoặc `pushReplacementNamed(login)`; "Đăng ký" → `pushNamed(register)`. Dev chọn cách giữ stack gọn (đề xuất pop cho Đăng nhập vì login là màn trước).
- **i18n:** thêm 13 key `guest*` ở `app_en.arb` + `app_vi.arb`, chạy `flutter gen-l10n`. Không hardcode.
- **KHÔNG token mới:** mọi màu/radius/spacing đều từ `AppColors`/`AppTheme`/CounterCard hiện có.

## Acceptance (design)
- [x] Mọi state có hình/mô tả (empty / có ngày / ngày tương lai / CTA / nút login)
- [x] Copy đủ VI+EN (13 key mới + danh sách key tái dùng)
- [x] Dev dựng được không cần hỏi lại (route, Hive key, tái dùng widget/helper, navigation, picker bounds)
- [x] Bám design system: nền dawnBlush, CounterCard hero bo 28, card glass bo 28, milestone bo 24, accentRose, KHÔNG token mới

## Nhật ký design
- [2026-06-01] [Designer] Thiết kế guest-mode: (1) nút "Dùng thử không cần đăng nhập" (TextButton.icon nhẹ + divider "hoặc") dưới nút Đăng nhập ở login_screen; (2) GuestCounterScreen (nền dawnBlush, header eyebrow/title/subtitle, empty card chọn ngày, CounterCard hero tái dùng + milestone card tái dùng layout home + nút Đổi ngày + CTA card chuyển đổi về login/register). 13 copy key `guest*` vi+en + danh sách key tái dùng. Bám design system, không token mới. Wireframe 3 màn + spec token + states + interaction. Đổi trạng thái design → xong.
