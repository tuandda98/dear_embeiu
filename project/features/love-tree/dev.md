# Cây tình yêu (Love Tree) — dev log (Dev)

## Trạng thái
- [2026-06-14] [Dev] Implement xong v1 LoveTreeScreen theo `design.md` + `overview.md`. `flutter analyze` (cả project) **0 issue**. CHƯA test runtime trên thiết bị, CHƯA rebuild app. Thuần client — KHÔNG backend/Firestore/Function/native đổi.

## File tạo mới
- **`lib/services/love_tree_service.dart`** — toàn bộ milestone-math + Hive seen-marker + visual token theo loại hoa. Pure, không provider/backend (để màn cây và badge StreakChip tính `flowerCount` GIỐNG HỆT nhau). API chính:
  - `enum FlowerKind { days, streak, photos }`, `enum LoveTreeStage { seed, sprout, young, green, bloom }`.
  - `buildMilestones({days, longestStreak, photoCount})` → `List<LoveTreeMilestone>` (mỗi mốc có `index` ổn định: sort days→streak→photos, mỗi loại tăng dần; `reached` bool).
  - `flowerCount(...)` = đếm mốc `reached`. `stageForFlowers(int)` = ngưỡng PO (0→seed,1-2→sprout,3-5→young,6-9→green,10+→bloom).
  - `daysTogether(DateTime)` = date-only, clamp ≥0.
  - `readLastSeen(coupleId)` (sync, `Hive.box<String>('app_settings')`, key `love_tree_seen_<coupleId>`, fail-soft→0) + `writeLastSeen(coupleId, flowers)` (async, best-effort). Lưu int dưới dạng String (khớp box `Box<String>`).
  - `nucleusIcon/nucleusColor/petalEdge(FlowerKind)` — token màu/icon (ngày=heart `Icons.favorite` rose; streak=`IconsaxPlusLinear.flash` cam-hồng gradient; ảnh=`IconsaxPlusLinear.gallery` lavender).
  - **Icon library:** màn Love Tree dùng **IconsaxPlus** (đồng bộ với phần lớn screen khác: header badge `magic_star`, banner `magic_star`, nurture `tree/flash/gallery/messages`, chevron `arrow_right_3`, flag) — KHÔNG Lucide (spec gốc đề xuất Lucide; đã chuyển sang Iconsax cho nhất quán app). `streak_chip.dart` giữ icon cũ của nó (không thêm icon mới — badge chỉ là chấm Container + emoji 🌸/✨).
- **`lib/screens/love_tree_screen.dart`** — `LoveTreeScreen` (StatefulWidget, push thường qua MaterialPageRoute). Gồm:
  - `LoveTreeScreen`/`_LoveTreeScreenState`: đọc `context.watch` 3 provider (Couple/Streak/Photo); tính flowerCount/stage; quản lý bloom + lastSeen.
    - `_lastSeen`/`_seenAtEntry` đọc Hive 1 lần ở `initState`; `_commitSeen` ghi lastSeen=flowerCount qua `addPostFrameCallback` (animate trước, ghi sau); `_bloomCelebrated` đảm bảo confetti chỉ bắn 1 lần/lượt; `_confetti` (ConfettiController) bắn khi `hasNewBlooms && !reduceMotion`.
  - **Nền `dawnBlush` + transparent Scaffold + SafeArea** (màn con push riêng, KHÔNG trong shell 4-tab). Header = `SubScreenHeader(badge: loveTreeBadge, badgeIcon: LucideIcons.flower2)` (không title — chip là tên màn).
  - `_TreeHero`: `Stack` = `CustomPaint(LoveTreePainter)` nền + hoa là **widget overlay** `_LoveFlower` (Positioned) + `ConfettiWidget` sparkle. Rải hoa deterministic `_bloomPositions` (golden-angle 137.5° + `sqrt((i+.5)/14)` + jitter Knuth-hash theo index, anchor vào canopy thật của stage qua `LoveTreePainter.canopyGeometry`). Hoa keyed theo `kind-value` để State không bị recycle khi list dài thêm giữa lượt.
  - `_LoveFlower` (StatefulWidget): cánh = `CustomPaint(_FlowerPetalsPainter)` (5 cánh giọt radial-gradient pink→edge), nhuỵ = `_Nucleus` (Container tròn + `Icon` Lucide/Material, streak đổ gradient chéo). Animate nở: cánh scale+fade easeOutBack 540ms, nhuỵ pop trễ (Interval 0.22→1), stagger 140ms/bông (cap 6). reduceMotion → render thẳng, không controller.
  - `_BloomBanner`: pill r16 rose .10, viền .30, text `loveTreeNewBloomBanner(count)`/`...One`. EntranceReveal khi !reduceMotion.
  - `_NurtureCard` ("Cùng vun đắp") + `_NurtureTile` ×3 (giữ chuỗi/thêm kỷ niệm/trò chuyện) — **cả 3 tile `Navigator.maybePop()` về Home** (v1 chốt PO).
  - `_MilestonesCard` + `_MilestoneRow` + `_BloomedChip`: list mốc đã nở (✓ đã nở) + 1 mốc kế mỗi loại ("còn N…", opacity .65). 0 hoa → 3 mốc đầu mỗi loại.
  - `_StateMessage`: no-couple (`loveTreeNoCoupleBody`) / waiting (`loveTreeWaitingTitle/Body` + nút pill "Mời người ấy" → pop). `couple == null` / `isWaitingForPartner` → không vẽ vườn.
  - `_LoadingTree`: cây xám skeleton (`LoveTreePainter(skeleton:true)`) + 2 ShimmerSkeleton khi streak loading lần đầu.
  - `LoveTreePainter extends CustomPainter`: vẽ gò đất (quad bezier gradient gold→lavender + crest sáng), bokeh (7 đốm vị trí cố định), thân + nhánh + tán **blob mây** (`_blobPath` cubic/quad bezier theo bảng `bumps` hằng số) + lá giọt (`_paintLeaf`) + bóng tán (S6+ MaskFilter.blur) + glow rose (S10+) + cánh rơi (bloom). 5 stage qua `_StageSpec` (static `_specForStage`). `shouldRepaint` chỉ true khi stage/skeleton đổi (hoa ngoài painter). Static `canopyGeometry(stage,size)` để overlay hoa anchor đúng canopy.

## File sửa
- **`lib/widgets/streak_chip.dart`**:
  - Tap chip → **push `LoveTreeScreen`** (MaterialPageRoute) thay vì `StreakSheet.show` (PO chốt; bỏ import `streak_sheet.dart`, thêm import couple/photo provider + `LoveTreeScreen` + `LoveTreeService`).
  - Badge dụ-vào: `_hasUnseenBlooms` (tính flowerCount qua LoveTreeService, so `readLastSeen`) → khi có hoa chưa xem: chấm glow 8px `accentLoveDeep` top-right (Stack clip off) + đổi emoji ✨→🌸. Fail-soft (no-couple/waiting/error → false).
  - `StreakSheet` vẫn dùng ở `home_screen.dart`/`profile_screen.dart` + auto-celebration streak → KHÔNG dead code.
- **`lib/l10n/app_en.arb` + `app_vi.arb`**: +33 key `loveTree*` (badge/stage0-4/flowerCount/banner/nurture×7/milestones×10/states×4). Placeholder `{count}` int khai báo ở `@`-block (en). Đã chạy `flutter gen-l10n` → `app_localizations*.dart` regenerate (KHÔNG hand-edit). Voice "hai bạn/cả hai" (không "hai đứa").

## Backend / model / native
- KHÔNG đổi. Không Firestore/rules/Function/Storage/native. Hive: 1 key mới `love_tree_seen_<coupleId>` trong box `app_settings` (đã mở sẵn ở `main.dart` trước runApp) — không adapter mới, không migration, không build_runner.

## Deploy
- Không có gì để deploy (thuần client). CHƯA submit/build.

## Lệnh đã chạy
- `flutter gen-l10n` (sạch).
- `flutter analyze` (cả project) → **No issues found**.

## Lệch spec / cần Tester soi
- **Điều hướng "Cùng vun đắp"**: cả 3 tile `pop()` về Home (đúng v1 PO chốt — KHÔNG đổi tab). Backlog: đổi tab Gallery/Chat.
- **Canopy anchor cho hoa**: đã anchor hoa vào canopy THẬT theo stage (cải tiến so với spec gốc "dùng box green/bloom") để hoa không lửng ở stage nhỏ (sprout/young). Tester verify hoa nằm trên tán mọi stage, không tràn xuống thân, không chồng che nhuỵ.
- **Sparkle confetti**: bắn 1 lần/lượt khi có hoa mới + !reduceMotion (`ConfettiWidget` emit từ canopy center, 10 particle). Cần soi runtime: confetti có hiển thị trong vùng cây không (Stack clip), reduceMotion có tắt sạch không.
- **lastSeen ghi postFrame**: nếu user thoát màn NGAY trước postFrame, lastSeen có thể chưa kịp ghi → lần sau animate lại (hiếm, chấp nhận được). Tester thử mở→thoát nhanh.
- **Loading→data**: dùng `streak.isLoading && state==hidden` làm gate skeleton; nếu streak fail-soft (hasError) thì coi longestStreak=0 (không chặn cả màn). Photo/Couple không có cờ loading riêng ở đây → photoCount/daysTogether dùng giá trị hiện có. Tester verify không "nhảy số" hoa khi data về muộn.
- **Badge StreakChip**: `_hasUnseenBlooms` đọc Hive sync mỗi build — rẻ + fail-soft. Verify chấm mất sau khi vào màn cây (lastSeen update) + quay lại Home.
- Cây/hoa 100% CustomPaint/shape, KHÔNG asset ảnh. Verify thẩm mỹ từng stage (seed/sprout/young/green/bloom) + 3 loại nhuỵ đúng màu/icon trên thiết bị thật (màu gradient + blur có thể khác theo GPU).
