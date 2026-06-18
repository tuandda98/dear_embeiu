# Profile Redesign — Dev log

> Implement theo [design.md](design.md) (Concept B — Hành trình & Huy hiệu).

## File
| File | Thay đổi |
|---|---|
| `lib/widgets/milestone_trail.dart` | **MỚI.** `MilestoneTrail(totalDays)` — stepper ngang cuộn được: `_Station` (reached=hồng đặc+✓ / isNext=vòng+flag / future=mờ), `_Connector` (3px, lit khi mốc trước reached), `_NextCaption` ("Còn N ngày tới X" + LinearProgressIndicator), `_AllDoneCaption`. Mốc curated `[100,365,520,1000,1314,1825,3650]`. Tự dùng `context.l10n`; static (Reduce-Motion-safe). |
| `lib/screens/profile_screen.dart` | Bỏ `_buildStatsSection` + `_buildModernStatCard` (4 ô trùng) → `_buildJourneyTrail` (ContentCard `map` + `MilestoneTrail`). Bỏ `_buildMemoryChest` + `_chestRow` + `_chestDivider` (2 menu phẳng) → `_buildAchievements` (lưới 2×2) + `_badgeCard`. Thêm param `onRequestTab` (badge Kỷ niệm → tab Gallery). Bỏ local var `years/totalMonths/totalHours` (hết dùng). Skeleton chỉnh chiều cao (320→160 trail, 188→232 badges). Import thêm `streak_provider`, `milestone_trail`. |
| `lib/screens/home_screen.dart` | Truyền `onRequestTab` vào `ProfileScreen` (setState đổi `_selectedIndex`, như Chat). |
| `lib/l10n/app_{vi,en}.arb` | +8 key (`journeyTrailTitle`, `milestoneTrailNext`(days,label), `milestoneTrailAllDone`, `profileAchievementsTitle`, `badge{Streak,Record,Memories,Journal}Label`) + gen-l10n. Nhãn năm tái dùng `milestoneYearsOne/Many`. |

## Data
- Trail: `totalDays` (= `_daysTogether(anniversary)`), so với mốc curated → reached/next/future.
- Huy hiệu: `StreakProvider.currentStreak`/`longestStreak` · `PhotoProvider.photoCount` (aggregate) · Nhật ký = entry (không số).
- l10n cũ `journeySnapshotTitle`/`yearsTogether`/`monthsRemaining`/`totalDaysLabel`/`totalHoursLabel`/`profileMemoryChestTitle`/`journalSettingsTile`/`profileStreakTile` giờ **unused ở UI** (giữ trong ARB).

## Verify
- `flutter analyze lib` → **0 issue** (đã đổi `LucideIcons.route`→`map` vì route không tồn tại trong lucide 0.257).
- App build + launch OK trên simulator (ios-sim.sh). Chờ user nghiệm thu trực quan tab Hồ sơ.
- Client-only, KHÔNG đụng backend/rules. Không deploy.

## Nhật ký
- [2026-06-18] [lead+designer+dev] **Redesign v2 lưới Huy hiệu — mỗi ô bấm ra chi tiết riêng + bỏ mũi tên ">".** User: "ngày chuỗi bấm xem chi tiết · kỷ lục xem có kỷ lục gì · kỷ niệm xem kỷ niệm gì · sao nhật ký là icon >?". Chốt 2 hướng qua AskUserQuestion (Kỷ lục="Tủ kỷ lục" · Kỷ niệm="sheet + mốc"). **Thực thi:** (1) tách `_buildAchievements`/`_badgeCard` → **`_AchievementsGrid` StatefulWidget** (cuối `profile_screen.dart`) **cache journal-count** (1 lần, tránh re-query mỗi rebuild). (2) `_badgeCard` v2: **cả 4 ô = số + chevron góc nhỏ đồng bộ** (bỏ `value:null`→arrow; Nhật-ký hiện số câu, shimmer mảnh khi count đang load). (3) Mới `DailyQuestionService.countJournalEntries` = `dailyAnswers.where('bothAnswered',true).count().get()` (aggregation, 1 read, fail→0). (4) Mới `widgets/records_sheet.dart` **RecordsSheet** "Tủ kỷ lục" (5 record, values truyền từ grid). (5) Mới `widgets/memories_sheet.dart` **MemoriesSheet** (4 thumbnail từ `photoProvider.photos` + "+N" + chips mốc ảnh [10,50,100,300,500,1000] có ✓ + "Còn X tới mốc Y" + seeAll→pop+`onRequestTab(2)`). Sheet = `cardSurface` blur giống StreakSheet. (6) +10 l10n key en+vi (profileRecords*/profileMemories*/profileJournalCountLabel); reuse `daysCountLabel`(int!)/`seeAll`. **Verify runtime Android emulator DEV:** grid 4 số (0/2/10/3)+chevron; Nhật-ký "3" hết ">"; Tủ kỷ lục đúng (2 ngày/742/10/3 câu/0-5); MemoriesSheet đúng (4 thumb+"+6", chips 10✓, "Còn 40 tới mốc 50"). analyze 0. Client-only, không deploy.
- [2026-06-14] [lead+designer+dev] Redesign nửa dưới Profile theo Concept B. Audit → chốt hướng qua preview → `MilestoneTrail` widget + achievements grid + wire onRequestTab + l10n. analyze 0.
