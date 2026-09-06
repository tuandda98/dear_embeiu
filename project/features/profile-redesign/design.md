# Profile Redesign — Design spec (Designer)

> Redesign nửa dưới màn Hồ sơ (tab 4). User: "design lại layout Profile sao cho friendly + độc đáo, đặc biệt phần Tủ kỷ niệm". **Hướng đã chốt: Concept B — "Hành trình & Huy hiệu" (gamified)** (user chọn qua preview 2026-06-14).

## Vấn đề (audit)
1. **"Bức tranh hành trình"** = 4 ô (Năm / Tháng / Tổng ngày / Tổng giờ) thực ra là **CÙNG 1 con số** (738 ngày) đổi 4 đơn vị → data redundancy, tốn khu vực, không thêm thông tin.
2. **"Tủ kỷ niệm"** = 2 list-tile phẳng (icon + tên + chevron) → không xứng cái tên, không khoe được gì về mối quan hệ.

## Giải pháp (Concept B)
Giữ: header chip + Hero card + invite tile (khi chờ partner). **Thay nửa dưới:**

### Block 1 — "Hành trình của chúng mình" (milestone trail)
- ContentCard (icon `map` rose + title 16 w800).
- **Dải cột mốc ngang** (`MilestoneTrail`, widget mới): các mốc curated `[100, 365, 520, 1000, 1314, 1825, 3650]` (520≈"anh yêu em", 1314≈"yêu trọn đời", còn lại tròn/kỷ niệm năm).
  - Mốc ĐÃ qua: chấm hồng đặc (accentLove) + ✓ + shadow; nhãn rose w800.
  - Mốc TỚI (đầu tiên > totalDays): vòng rỗng viền rose 3px + icon `flag`; nhãn rose w800.
  - Mốc XA: chấm rỗng xám mờ; nhãn textTertiary.
  - Đường nối: rose tới mốc hiện tại, xám sau đó. Cuộn ngang.
- Caption dưới: `🚩 Còn {N} ngày tới {label}` + thanh progress mảnh (tiến độ trong đoạn hiện tại). Khi qua hết mốc → "đã chinh phục mọi cột mốc 🎉".
- **Số "738 ngày" KHÔNG lặp** ở đây — nó đã có ở Hero card.

### Block 2 — "Huy hiệu của chúng mình" (achievements grid)
- `SectionHeader` + **lưới 2×2 thẻ huy hiệu bấm được, hiện SỐ THẬT đa dạng**:
  | Huy hiệu | Icon | Số | Bấm → |
  |---|---|---|---|
  | Chuỗi kết nối | flame (accentLove) | `streak.currentStreak` | StreakSheet |
  | Kỷ lục | trophy (lavender) | `streak.longestStreak` | StreakSheet |
  | Kỷ niệm | image (coral) | `photoCount` (aggregate) | tab Gallery (`onRequestTab(2)`) |
  | Nhật ký | bookOpen (rose) | — (mũi tên `→`) | JournalScreen |
- Thẻ: nền tint .10 + viền .12 + đĩa icon trắng .82 r15 + số 24 w800 (hoặc `→` cho nhật ký) + nhãn 13 w600. InkWell ripple tint.
- **Giữ nguyên 2 entry cũ** (Journal + Streak) + thêm jump Gallery.

## Token
Nền dawnBlush (từ Home shell) · ContentCard trắng r24 · thẻ huy hiệu tint .10/r22 · trail dot 34, connector 3px, progress 6px. Không animation (static, an toàn Reduce Motion).

## Copy (vi/en)
`journeyTrailTitle` (Hành trình của chúng mình / Our journey) · `milestoneTrailNext({days},{label})` · `milestoneTrailAllDone` · `profileAchievementsTitle` (Huy hiệu của chúng mình / Your badges) · `badgeStreakLabel` (ngày chuỗi) · `badgeRecordLabel` (kỷ lục) · `badgeMemoriesLabel` (kỷ niệm) · `badgeJournalLabel` (nhật ký). Nhãn năm tái dùng `milestoneYearsOne/Many`.

## Redesign v2 (2026-06-18) — mỗi huy hiệu bấm ra chi tiết
User: "ngày chuỗi bấm xem chi tiết · kỷ lục xem có kỷ lục gì · kỷ niệm xem kỷ niệm gì · sao nhật ký là icon >?". Nguyên tắc: **4 huy hiệu = 4 con số liếc-là-thấy, mỗi ô bấm → 1 chi tiết đúng chủ đề; đồng bộ tuyệt đối** (bỏ ">" lệch).
- **Đồng bộ:** cả 4 ô = CON SỐ + chevron nhỏ mờ góc trên-phải (tín hiệu "bấm xem thêm" thống nhất); Nhật-ký nay có số (count query). Chi tiết = **bottom sheet** `cardSurface` blur (đồng bộ StreakSheet).
- **Ngày chuỗi**→StreakSheet (đã có). **Kỷ lục**→`RecordsSheet` "Tủ kỷ lục" (5 record: chuỗi dài nhất / ngày bên nhau / tổng kỷ niệm / câu hỏi đã trả lời / mốc chuỗi đạt). **Kỷ niệm**→`MemoriesSheet` (thumbnail gần đây + "+N" + chips mốc ảnh có ✓ + "Còn X tới mốc Y" + Xem-tất-cả→tab Gallery). **Nhật ký**→JournalScreen.
- **User chốt (AskUserQuestion):** Kỷ lục = Tủ kỷ lục · Kỷ niệm = sheet+mốc.

## Nợ / mở rộng
- ✅ [DONE 2026-06-18] Nhật ký count() query — đã hiện số thật.
- Có thể thêm huy hiệu "khoá" (chưa đạt → mờ) cho gamification sâu hơn.
- Trail: có thể thêm celebrate animation khi vừa đạt mốc.
- RecordsSheet: có thể thêm record "nhiều ảnh nhất 1 ngày", "trả lời sớm nhất"… nếu muốn phong phú.

---

## Design Spec v2 — Badge Grid Visual Redesign (2026-06-18)

> Vấn đề: card nền tint alpha .10 trùng màu nền dawnBlush → chìm mất, không điểm nhấn. Spec này thay toàn bộ visual `_badgeCard`, không đổi logic onTap.

### 1. Concept & Rationale

Nền `dawnBlush` là gradient hồng phủ toàn app — card nền tint alpha .10 cùng họ hồng hoà tan vào nền, không tạo được điểm nhấn. Chuyển sang nền trắng đặc (`ContentCard` style, chuẩn đã có cho TodayRitualCard / Settings / Gallery feed) giúp 4 badge nổi lên như 4 "thẻ bài" riêng biệt, nhất quán với ngôn ngữ hình thức toàn app. Mỗi badge có accent element màu tint riêng (dải ngang 4px ở đáy card) để duy trì color identity per-card mà không phá vỡ nền trắng. Số liệu dùng màu tint của badge (thay vì textPrimary đen đồng đều) tạo cảm giác gamified — mỗi con số mang "màu sắc" riêng của nó.

### 2. Card Anatomy

#### Container

| Property | Giá trị |
|---|---|
| Background | `AppColors.white` (#FFFFFF) đặc, không alpha |
| Border radius | `24` (đồng bộ ContentCard, thay r22 hiện tại) |
| Shadow | `black .06` blur `16` offset `(0, 8)` — chuẩn ContentCard |
| Border | Không có — nền trắng đặc đủ tách khỏi dawnBlush |
| Clip | `ClipRRect r24` bắt buộc (accent strip không tràn góc) |

#### Icon Area

| Property | Giá trị |
|---|---|
| Container kích thước | 52×52 (tăng từ 44) |
| Container radius | `16` (squircle token standard) |
| Container background | `tint.withValues(alpha: 0.12)` |
| Icon | `IconsaxPlusBold.*` (giữ Bold weight) |
| Icon size | 26px (tăng từ 22) |
| Icon color | `tint` màu đặc |

#### Value (số liệu)

| Property | Giá trị |
|---|---|
| Font size | 26px (type scale chuẩn) |
| Font weight | `w800` |
| Color | **`tint` của card đó** — thay textPrimary đen |
| Letter spacing | `-0.5` |

#### Label

| Property | Giá trị |
|---|---|
| Font size | 14px (tăng từ 13 vào type scale chuẩn) |
| Font weight | `w600` |
| Color | `AppColors.textSecondary` (#6B6B7B) |

#### Accent Element (dải đáy)

| Property | Giá trị |
|---|---|
| Vị trí | `Positioned(bottom: 0, left: 0, right: 0)` |
| Chiều cao | 4px |
| Màu | LinearGradient ngang: `[tint @ .0, tint @ .60, tint @ .0]` — fade 2 đầu |

#### Tap Affordance

| Property | Giá trị |
|---|---|
| Widget | `Material(transparent) → InkWell → ClipRRect → Stack` |
| Splash | `tint.withValues(alpha: 0.10)` |
| Highlight | `tint.withValues(alpha: 0.06)` |
| Border radius InkWell | `r24` |

Bỏ `arrow_right_3 tint .50` hiện tại — thay bằng `IconsaxPlusLinear.info_circle` 14px `tint .40` góc trên phải (hoặc bỏ hẳn nếu PO muốn tối giản — ripple đủ là affordance).

#### Padding trong card

`EdgeInsets.fromLTRB(14, 16, 14, 20)` — bottom 20 nhường chỗ cho accent strip 4px.

#### Thứ tự layout trong card (top → bottom)

```
Column(crossAxisAlignment: .start) [
  Row [
    IconContainer(52×52 r16),
    Spacer(),
    Icon(info_circle, 14, tint .40),
  ],
  SizedBox(8),
  Text(value, 26 w800, tint),
  SizedBox(2),
  Text(label, 14 w600, textSecondary),
]
```

### 3. Per-card Color Mapping

> Thực tế từ `app_colors.dart`: `accentCoral = sunset2 = #FF8FA3`. `accentRose` là alias của `accentLove` — hai badge Chuỗi và Nhật ký cùng màu tint; phân biệt bằng icon (flash vs book_1). Không bịa token mới.

| Badge | Tint token | Hex | Icon container bg | Accent strip peak | Số màu |
|---|---|---|---|---|---|
| Chuỗi | `accentLove` | #FF4D6D | #FF4D6D @.12 | #FF4D6D @.60 | #FF4D6D |
| Kỷ lục | `accentLavender` | #A78BFA | #A78BFA @.12 | #A78BFA @.60 | #A78BFA |
| Kỷ niệm | `accentCoral` | #FF8FA3 | #FF8FA3 @.12 | #FF8FA3 @.60 | #FF8FA3 |
| Nhật ký | `accentRose` | #FF4D6D | #FF4D6D @.12 | #FF4D6D @.60 | #FF4D6D |

### 4. Layout & Spacing

| Vị trí | Giá trị |
|---|---|
| Gap giữa 2 card trong hàng | 12 |
| Gap giữa 2 hàng | 12 |
| Padding trong card | `fromLTRB(14, 16, 14, 20)` |
| Chiều cao tối thiểu | Không ép cứng — `Expanded` trong Row tự làm 2 card cùng hàng bằng nhau |

### 5. States

#### Loading (journal count)

Khi `value == null`: thay số bằng `ShimmerSkeleton(width: 48, height: 20, borderRadius: 6)`.
Bỏ `Container(tint .18, r7)` tự chế hiện tại — đồng bộ pattern toàn app.

#### Zero state

Số "0" hiển thị bình thường bằng tint màu card — ổn, không cần xử lý đặc biệt. Màu tint làm "0" trông nhẹ nhàng, không cảm giác bị phạt. Empty-state cho Nhật ký (icon mờ + "Chưa có") là nợ tương lai nếu muốn gamification sâu hơn.

### 6. Interaction

| Trigger | Behavior | Duration |
|---|---|---|
| Tap | `HapticFeedback.selectionClick()` → InkWell ripple → onTap | ripple 200ms easeOutCubic |
| Ripple shape | `tint .10` splash, `tint .06` highlight, r24 |  |

Không animation nào trên card — Reduce Motion safe.

### 7. Localization (vi/en)

Keys giữ nguyên từ spec v1:

| Key | VI | EN |
|---|---|---|
| `profileAchievementsTitle` | Huy hiệu của chúng mình | Your badges |
| `badgeStreakLabel` | ngày chuỗi | day streak |
| `badgeRecordLabel` | kỷ lục | records |
| `badgeMemoriesLabel` | kỷ niệm | memories |
| `badgeJournalLabel` | nhật ký | journal entries |

### 8. Flutter Dev Notes

**Không đổi logic — chỉ đổi visual `_badgeCard`.**

1. **Stack structure mới:**
   - `Material(transparent) → InkWell(r24, tint.10) → ClipRRect(r24) → Stack`
   - Layer 0: `Container(white, BoxDecoration shadow black.06 blur16 offset(0,8))` — toàn card
   - Layer 1: `Padding(14,16,14,20)` → `Column` nội dung
   - Layer 2: `Positioned(bottom:0, left:0, right:0, height:4)` → `DecoratedBox(LinearGradient ngang [tint.0, tint.60, tint.0])`

2. **InkWell NGOÀI ClipRRect** — không trong (ripple bị clip mất lan).

3. **Icon:** `44→52`, `r15→r16`, `white.82→tint.12`, `size 22→26`. Giữ IconsaxPlusBold.

4. **Số:** `color: textPrimary → tint`, `fontSize: 24→26`, giữ w800.

5. **Label:** `fontSize: 13→14`, giữ w600 textSecondary.

6. **Shimmer:** `value == null` → `ShimmerSkeleton(width:48, height:20, borderRadius:6)` thay Container.

7. **Arrow:** đổi `arrow_right_3, 18, tint.5` → `info_circle, 14, tint.40`.

8. **Border radius tổng:** r22 → r24 (InkWell + Container + ClipRRect).

9. **Giữ nguyên:** SectionHeader · gap 12 · HapticFeedback · 4 onTap destinations · _loadJournalCount · NumberFormat · shimmer skeleton toàn màn (height 232 r24 vẫn đúng).

### 9. Acceptance Criteria

- [ ] 4 badge nền trắng đặc, nổi trên dawnBlush hồng
- [ ] Shadow ContentCard chuẩn: black .06 blur 16 offset(0,8)
- [ ] Icon 52×52 r16, nền tint .12, icon 26px Bold màu tint
- [ ] Số 26px w800 màu tint (không phải textPrimary đen)
- [ ] Accent strip 4px đáy, gradient fade 2 đầu, không tràn góc bo
- [ ] Label 14px w600 #6B6B7B
- [ ] Tap ripple tint .10 đúng shape r24
- [ ] Journal loading: ShimmerSkeleton 48×20 r6
- [ ] Zero state ("0"): hiển thị bình thường màu tint, không crash
- [ ] Không animation trên grid (Reduce Motion safe)
- [ ] 4 onTap giữ nguyên: StreakSheet / RecordsSheet / MemoriesSheet / JournalScreen
- [ ] `flutter analyze` sạch

### Changelog
- [2026-06-18] [Designer] Design spec v2 badge grid: nền trắng đặc, icon 52px tint, số màu tint, accent strip 4px, shimmer chuẩn, r24 đồng bộ ContentCard.
- [2026-06-18] [Dev/Lead v3] Nâng badge grid thành **medal**: icon-phẳng → **medallion gradient 54px + quầng sáng màu** (`accent .34` blur14) làm điểm nhấn; bỏ accent-strip đáy + ClipRRect (dùng `Ink`); icon trắng trên medallion; số hero 28px màu accent; 4 màu **phân biệt** qua class `_MedalPalette` (streak love · record lavenderDeep · memories coral #FF5C7A · journal berry #D44A85) — sửa luôn lỗi cũ 2 badge trùng #FF4D6D. Call-site đổi `tint:` → `medalGradient:`+`accent:`. analyze sạch.
