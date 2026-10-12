# 🎨 Design — Widget màn hình chính (Đếm ngày yêu)

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`../../../CLAUDE.md` mục 8 + `../../design-system.md`). CHỈ thiết kế, không code.

- **Trạng thái design:** xong (user chọn hướng A 2026-10-12)
- **Mockup bấm thử:** canvas Artifact `https://claude.ai/artifact/Rb2dk1uaXdjuUGEBwNiKD9` — 5 artboard: A (đề xuất, đã chọn) · B lá lịch blush · C trái tim · A trên Android · A soát iOS 18 tinted / 10.000 ngày / tiếng Anh. Tweaks đổi số ngày + tên để xem chữ co.
- **Đã tra UI UX Pro Max** (`search.py`, 2026-10-12): contrast chữ nhỏ/lớn, touch target 44pt/48dp, icon vector không emoji, cặp font rounded khớp Quicksand, dark mode soát riêng. DB không có mục widget → kích cỡ/bo góc/tinted lấy theo guideline Apple WidgetKit + Android App Widgets (fallback, ghi rõ).

## Mục tiêu thiết kế
Nhìn 1 giây là biết: số ngày, của ai, còn bao lâu tới mốc. Trông như CounterCard của Home thu nhỏ — người dùng nhận ra ngay, không cần học.

## User flow
1. Người dùng nhấn giữ màn hình chính → thêm widget "Đếm ngày yêu" (nhỏ hoặc vừa). Gallery hệ thống hiện tên + mô tả theo ngôn ngữ máy.
2. Đã mở app ít nhất 1 lần sau bản này → widget hiện số. Chưa → trạng thái trống "Chạm để bắt đầu đếm ngày yêu".
3. Mỗi 0:00 số tự tăng. Đổi ngày yêu / tên / ngôn ngữ trong app → widget đổi ngay khi quay ra.
4. Chạm bất kỳ đâu trên widget → mở app (Home / Setup / landing tuỳ phiên).

## Wireframe
```
NHỎ 158×158 (iOS) · 2×2 ≈152dp (Android)        VỪA 338×158 · 4×2 ≈328dp
┌──────────────────────┐                        ┌──────────────────────┬─────────────────────────┐
│ (TUẤN ♥ THẢO)        │ ← chip trắng, mực navy │ (TUẤN ♥ THẢO)        │ Cột mốc 1.500 ngày      │
│                      │                        │                      │ ━━━━━━━━━━━━━━━━░░░░ 83%│
│                      │                        │                      │ còn 253 ngày            │
│ 1.247                │ ← Quicksand Bold 40    │ 1.247                │                         │
│ ngày bên nhau        │ ← 12 w600 trắng .92    │ ngày bên nhau        │ Bắt đầu từ 14/05/2023   │
└──────────────────────┘                        └──────────────────────┴─────────────────────────┘
 nền gradient hồng → đỏ hồng + scrim đen .10→.28 + 2 vệt aurora (trắng góc trên trái, lavender góc dưới phải)
```

## Spec chi tiết (token chính xác — hướng A)
**Khung**
- iOS: nhỏ 158×158pt, vừa 338×158pt (iPhone 393pt); bo góc do hệ thống cắt (~22pt), **không tự vẽ bo**. Lề trong 14pt.
- Android: `targetCellWidth/Height` 2×2, kéo ngang tới 4×2 (`resizeMode="horizontal"`); nền bo `@android:dimen/system_app_widget_background_radius` (API 31+), fallback 28dp. Lề trong 16dp.
- Nền (3 lớp, từ dưới lên): `linear-gradient(150°, #FF5C8F 0%, #FF4D6D 55%, #E63956 100%)` → scrim `linear-gradient(180°, black .10, black .28)` → aurora: tròn trắng .26 Ø96 tâm (−28, −30) blur 18 · tròn lavender `#A78BFA` .40 Ø120 tâm góc dưới phải (+40, +46) blur 18 (bản vừa: Ø110 / Ø160). Android không có blur trong drawable → dùng radial gradient tới trong suốt, chấp nhận mép mềm ít hơn.
- iOS ≥17: nền qua `containerBackground(for: .widget)`; iOS 18 tinted: hệ thống bỏ nền, mọi thành phần `widgetAccentable()`.

**Chip tên** (góc trên trái)
- Pill cao 20, padding ngang 8, r999, nền trắng .84, chữ `#1A1A2E` **10 w700, ls 1.0, UPPERCASE**, 1 dòng, cắt "…"; giữa 2 tên là tim vector 10 `#E63956` (`aria-hidden`/decorative). Max width = full. Chỉ 1 tên (chờ người ấy) → "TUẤN" + tim.
- Lý do mực navy trên trắng: chữ 10px trắng trên hồng chỉ ~3,5:1 (fail 4,5:1); chip trắng đạt ~11:1. Đúng ngôn ngữ `EyebrowChip` của app.

**Số ngày**
- Quicksand **Bold 40** (≤5 ký tự kể cả dấu chấm) · 32 (6 ký tự) · 28 (≥7); iOS dùng 40 + `minimumScaleFactor 0.6`, Android `autoSizeTextType="uniform"` 24–40sp. **Android dùng font hệ thống (Roboto), không phải Quicksand:** RemoteViews inflate trong context restricted nên `TextView` không nạp `@font/` (phát hiện khi smoke Task 7, 2026-10-12; `overview.md` D11). Độ đậm giữ bằng `textStyle="bold"` (số, chip, cột mốc) và `sans-serif-medium` (chú thích, "còn…", "Bắt đầu từ…"). Muốn Quicksand trên Android phải vẽ chữ ra bitmap — để sau nếu user không ưng Roboto. Trắng, `letterSpacing −1`, line-height 1, bóng tối `black .30 blur 8 y1` (luật chữ-trắng-trên-nền-sáng: bóng TỐI, không halo). Định dạng theo ngôn ngữ app: vi `1.247`, en `1,247`.
- Contrast: trắng trên nền hiệu dụng vùng giữa ≈ `#E55381` → 3,6:1, qua ngưỡng chữ lớn 3:1 (≥24px).

**Chú thích** "ngày bên nhau" / "days together": 12 w600 trắng .92, bóng `black .28 blur 6`, cách số 6. Vùng đáy nền hiệu dụng ≈ `#A6293E` → 6,3:1.

**Bản vừa — cột phải** (cột trái rộng 150, vạch dọc 1pt trắng .28, lề ngang 14)
- "Cột mốc 1.500 ngày" (`milestoneNextLabel`) 12 w700 trắng.
- Thanh tiến độ cao 6, r999, nền trắng .26, phần đầy trắng .96; giá trị = `days / next`.
- "còn 253 ngày" (`milestoneDaysLeft`; ngày tới mốc = `milestoneTodayLabel`) 12 w600 trắng .92.
- Dưới cùng: "Bắt đầu từ 14 thg 5, 2023" (`guestCounterStartFrom` + `fullDateFormat` theo locale — vi `d 'thg' M, y`, en `MMM d, y` → "Since May 14, 2023"; quyết định i18n D3) 11 w500 trắng .84, **tối đa 2 dòng** (ngày 28 thg 12 dài 133pt > cột 110–127pt; review Task 4). Dòng "Cột mốc …" 12 w700 co tới ~10 (`minimumScaleFactor .85`) để "Milestone: 10,000 days" không cắt.
- Khoảng cách dọc 8. Mọi chữ có bóng tối như trên.

**Kích cỡ chữ** chỉ dùng type scale của app: 10 / 11 / 12 / 28 / 32 / 40.

## States
- **Có couple (active hoặc chờ người ấy):** như wireframe. Chờ người ấy → chip 1 tên; không thêm lời mời.
- **Trống** (guest / chưa couple / vừa đăng xuất / vừa cập nhật app chưa mở): cùng nền A; chip "DEAR EMBEIU" với tim; dòng 14 w700 trắng tối đa 3 dòng "Chạm để bắt đầu đếm ngày yêu". Bản vừa: cùng nội dung, cột phải để trống.
- **Ngày yêu tương lai:** 0 ngày, "Cột mốc 1 tháng", "còn 30 ngày".
- **Số dài** (≥10.000): co 32/28 — không bao giờ xuống dòng.
- **Chữ hệ thống to (AX):** số co theo `minimumScaleFactor`, chú thích tối đa 2 dòng, chip giữ 1 dòng cắt.
- **Chế độ tối:** không đổi (widget tự mang màu). **iOS 18 tinted:** nền hệ thống bỏ gradient; số, chú thích, chữ chip, cột mốc = nhóm accent (`widgetAccentable`, nhận màu tint); **nền chip (pill trắng .84) KHÔNG accentable** — nằm nhóm mặc định nên vẫn tách khỏi chữ (nếu bọc cả chip, nền và chữ cùng một màu tint → mất tên; phát hiện khi review Task 4). Artboard "Tinted" mô phỏng ý đồ (chip tint .22 + chữ tint) — kết quả thật tương đương: chữ tint trên pill sáng.
- Không có loading/error: dữ liệu luôn có sẵn trong kho native hoặc rơi về trạng thái trống.

## Interaction & animation
- Toàn widget là 1 vùng chạm (≥44pt/48dp). Không nút con. Không animation (nền tảng không cho); số đổi theo timeline/cập nhật, không transition.

## Copy (song ngữ — bắt buộc)
| Key | VI | EN | Ghi chú |
|-----|----|----|---------|
| `daysTogether` (có) | ngày bên nhau | days together | hạ chữ đầu khi hiện dưới số |
| `milestoneNextLabel` (có) | Cột mốc {label} | Milestone: {label} | |
| `milestoneDaysLeft` (có) | còn {count} ngày | {count} days left / 1 day left | native chọn số ít/nhiều |
| `milestoneTodayLabel` (có) | hôm nay 🎉 | today 🎉 | |
| `milestoneMonthsOne/Many`, `milestoneYearsOne/Many`, `milestoneDaysLabel` (có) | {count} tháng / {count} năm / {count} ngày | {count} month(s) / year(s) / days | |
| `guestCounterStartFrom` (có) | Bắt đầu từ {date} | Started on {date} | ngày format theo locale |
| `widgetEmptyTap` **(mới)** | Chạm để bắt đầu đếm ngày yêu | Tap to start counting your days together | trạng thái trống |
| `widgetDisplayName` **(mới, native .strings/strings.xml)** | Đếm ngày yêu | Day counter | tên trong gallery widget hệ thống |
| `widgetDescription` **(mới, native)** | Số ngày chúng mình bên nhau, cập nhật mỗi ngày. | Your days together, updated every day. | mô tả trong gallery |

Giọng "chúng mình" theo luật copy; tên app giữ "Dear Embeiu".

## Handoff / Dev notes
- Flutter gửi ảnh chụp: `state` (counter|empty), `anniversary` `YYYY-MM-DD`, `name1`, `name2`, `lang`, và các chuỗi trên đã dịch (số ít/số nhiều gửi cả hai dạng). Native: tính `days` (so ngày lịch, như `LoveTreeService.daysTogether`), `next` + nhãn (như `_getNextMilestone` + `_milestoneLabel` của Home), format số theo `lang`.
- iOS vẽ bằng SwiftUI: `ZStack { LinearGradient; LinearGradient(scrim); Circle().blur(18) ×2; VStack nội dung }`; font `Font.custom("Quicksand-Bold", size: 40)` (file TTF thêm vào target widget + `UIAppFonts`); `.widgetURL(URL(string: "dearembeiu://widget"))`.
- Android: layout XML LinearLayout; TextView `android:fontFamily="sans-serif"` + `android:textStyle="bold"` (Roboto — `@font/` không nạp trong RemoteViews), `android:shadowColor/Dx/Dy/Radius` cho bóng; 2 dòng dài cột phải autosize 10–12sp (widget 3 ô trên máy ô lớn ≈108dp/cột); ProgressBar `style="?android:attr/progressBarStyleHorizontal"` với drawable track/fill r999; nền `layer-list` (gradient + alpha gradient + 2 radial).
- Quicksand có đủ glyph dấu tiếng Việt (đã verify fontTools khi chọn font 2026-06-10).
- Không dùng emoji làm icon; tim là path SVG/Shape. `🎉` chỉ nằm trong chuỗi `milestoneTodayLabel` sẵn có.

## Acceptance (design)
- [x] Mọi state có hình/mô tả (canvas + mục States)
- [x] Copy đủ VI+EN
- [x] Dev dựng được không cần hỏi lại (token + công thức + handoff)

## Nhật ký design
- [2026-10-12] [Designer] Tra UI UX Pro Max (ux/typography/color + stack swiftui/compose/flutter — stack không có mục widget, ghi fallback). Dựng canvas 5 artboard; user chọn hướng A. Sửa mock theo công thức cột mốc thật của Home (`[30…3000]` bước 500, tiến độ `days/next`).
