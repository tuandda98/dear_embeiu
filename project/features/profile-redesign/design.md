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
