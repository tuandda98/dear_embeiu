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
- [2026-06-14] [lead+designer+dev] Redesign nửa dưới Profile theo Concept B. Audit → chốt hướng qua preview → `MilestoneTrail` widget + achievements grid + wire onRequestTab + l10n. analyze 0.
