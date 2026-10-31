# 🎨 Design — Giấc ngủ của chúng mình (Sleep)

> Designer sở hữu. ⚠️ `overview.md` (PO) **chưa viết** — đầu vào lấy thẳng từ user (2026-10-10), ghi ở mục "Đầu vào" dưới đây. PO cần chốt lại phạm vi + rủi ro chính sách store trước khi Dev làm.
> Bám [`../../design-system.md`](../../design-system.md) (Design Unify 2026-06-11 + rule header 2026-06-14). Tái dùng `ContentCard`, `SubScreenHeader`, `IconBadge`, `EyebrowChip`, `showAppTimePicker`, lưới lịch của `lunar_calendar_screen.dart`. **Không thêm token màu mới.**

- **Trạng thái design:** xong v1.1 — đã chốt luật sửa minh bạch (chờ PO chốt overview → Dev)
- **Người/role:** Designer

## Đầu vào (user chốt 2026-10-10)
1. **Nguồn dữ liệu = app tự tính**, "chỉ cần máy không hoạt động trong 1 thời gian dài trong 1 ngày" → không bắt user tự nhập mỗi ngày. Ghi tay chỉ là đường dự phòng + sửa.
2. **Người ấy chỉ thấy khi mình BẬT chia sẻ** (mặc định riêng tư).
3. **Lối vào = card nhỏ ở Home** (nhóm "Hôm nay của chúng mình", dưới `MoodCard`) → tap mở màn lịch.
4. Thống kê **dạng lịch tháng**, hiện cả giấc ngủ của người còn lại.

## Kiểm tra khả thi (research 2026-10-10 — quyết định cách UI nói về dữ liệu)
| Nền tảng | Cách tự nhận | Hệ quả cho UI |
|---|---|---|
| **Android 9+ (API 28)** | `UsageStatsManager.queryEvents` có sự kiện `SCREEN_NON_INTERACTIVE` / `SCREEN_INTERACTIVE` → dựng lại **dòng thời gian tắt/bật màn hình đã qua**, tính được cả khi app không chạy lúc đêm. Cần quyền đặc biệt **"Quyền truy cập dữ liệu sử dụng"** (user tự bật trong Cài đặt hệ thống, không phải popup). | Có màn hướng dẫn cấp quyền + trạng thái "mất quyền". Lưu ý: `NON_INTERACTIVE` gồm cả màn hình chờ (AOD) → vẫn coi là "không dùng máy", ổn cho mục đích này. |
| **Android < 9** | Không có sự kiện màn hình | Chỉ ghi tay. |
| **iOS** | Apple **không cho** app đọc lịch sử khoá/mở màn hình (Apple DTS: không có API hỗ trợ). Đường thực tế duy nhất = **HealthKit `sleepAnalysis`** — iPhone tự ghi khi user bật *Lịch ngủ* + *Theo dõi giấc ngủ bằng iPhone* (chính nó dựa vào việc không dùng máy ban đêm), hoặc Apple Watch. | iOS: xin quyền Apple Health (chỉ đọc giấc ngủ). Không có dữ liệu Health → nhắc bật Lịch ngủ trong app Sức khoẻ, hoặc ghi tay. |

⇒ **UI luôn gọi đây là "ước tính"** (màn hình tắt ≠ chắc chắn đang ngủ) và cho sửa có giới hạn (xem mục Quyết định ngay dưới). Đêm tự ghi (điện thoại / Apple Health) **không gắn nhãn** trên dòng — nguồn xem ở hàng "Nguồn" trong cài đặt. Đêm *Đã sửa* / *Ghi tay* **luôn gắn nhãn**, ai xem cũng thấy.

## Quyết định: cho sửa nhưng minh bạch (user chốt 2026-10-10)
Câu hỏi của user: "cho sửa thì user có thể nói xạo". Trả lời: khoá việc sửa cũng không chặn được nói dối (úp máy rồi thức, tắt chia sẻ, iOS vốn ghi tay), mà còn biến tính năng thành công cụ soi nhau — trái tinh thần app và gần ranh giới chính sách stalkerware của Google Play (cấm theo dõi người trưởng thành khác khi họ không đồng ý). Nên thiết kế cho **minh bạch**, không cho **bắt lỗi**:
- **R1 — Nhãn công khai:** đêm đã sửa hoặc ghi tay hiện nhãn `✎ Đã sửa` / `✎ Ghi tay` ở MỌI chỗ hiện con số của đêm đó (card Home, dòng chi tiết đêm), cho CẢ người ấy. Ô lịch quá nhỏ nên không gắn nhãn, nhưng `Semantics` của ô có thêm "(đã sửa)".
- **R2 — Không lộ số gốc:** người ấy KHÔNG thấy giờ app ghi ban đầu (không có "app ghi 01:50 → sửa thành 23:30"). Bản chia sẻ chỉ gồm giờ cuối + nguồn.
- **R3 — Chỉ 7 đêm gần nhất:** sửa / ghi tay / xoá chỉ được cho đêm có ngày thức dậy trong 7 ngày gần nhất (hôm nay + 6 ngày trước). Đêm cũ hơn: ẩn nút ✎, hiện dòng `sleepEditLocked`.
- **R4 — Báo trước người sửa:** sheet sửa ghi rõ người ấy sẽ thấy nhãn "Đã sửa" (`sleepEditNote`).
- **Xoá đêm:** đêm thành trống (phía người ấy hiện "Chưa có dữ liệu"), app ghi nhớ đã xoá để lần quét sau không tự tạo lại.
- **Cố ý KHÔNG làm:** chống client bị chỉnh sửa, lưu lịch sử sửa, so sánh số gốc. Mục tiêu là trung thực với người dùng bình thường, không phải máy phát hiện nói dối.

**Luật tính đề xuất (Dev/PO xác nhận; thiết kế dựa trên nó):** một "đêm" gắn với **ngày thức dậy**. Cửa sổ quét 18:00 hôm trước → 14:00 ngày đó. Gộp các lần bật máy ngắn ≤ 5 phút vào giấc (đếm là *thức giấc*). Lấy đoạn tắt máy dài nhất ≥ 3 giờ = giấc ngủ. Không có đoạn nào ≥ 3 giờ → đêm đó "không có dữ liệu" (không bịa).

## Mục tiêu thiết kế
- **Một cái nhìn là biết "đêm qua người ấy ngủ có ngon không"** — giá trị cảm xúc (quan tâm), không phải app y tế.
- **Không phán xét (shame-free, giống Streak):** không tô đỏ đêm ngủ ít, không chấm điểm. Màu chỉ để phân biệt *ai*, chiều cao cột thể hiện *bao lâu*.
- Góc riêng của cặp đôi: **"ngủ cùng lúc"** (phần chồng nhau của 2 giấc) + "ai ngủ trước" — thứ app sức khoẻ thường không có.
- Riêng tư rõ ràng: lúc nào cũng thấy công tắc chia sẻ và biết người ấy đang thấy gì.

## Phạm vi màn hình
| # | Thành phần | Loại | Ghi chú |
|---|---|---|---|
| A | `SleepCard` "Đêm qua" | Card Home | Dưới `MoodCard`, khoảng cách trong nhóm 12 |
| B | `SleepScreen` "Giấc ngủ" | Màn con (push) | Lịch tháng + chi tiết đêm + thống kê tháng + cài đặt chia sẻ |
| C | `SleepSetupSheet` | Bottom sheet 2 bước | Cấp quyền → hỏi chia sẻ |
| D | `SleepEditSheet` | Bottom sheet | Sửa / ghi tay giờ ngủ–dậy của MÌNH |
| E | `SleepHowItWorksSheet` | Bottom sheet thông tin | "App tính giấc ngủ thế nào?" |

### Màu riêng của mỗi người (user chốt 2026-10-10: "cho user chọn màu")
Mỗi người **tự chọn 1 màu** cho giấc ngủ của mình. Màu đó dùng ở MỌI chỗ hiện dữ liệu của người đó (chấm, làn dòng thời gian, thanh card Home, nền ô lịch khi xem riêng, ô thống kê), và **người ấy thấy đúng màu bạn chọn**. Mặc định: người bật trước = Hồng, người sau = Tím (hoặc màu hợp lệ đầu tiên).

Bộ 8 màu `personPalette` (đều ≥ 3:1 trên trắng, trong dải sáng L 0.43–0.77, chroma ≥ 0.1 — đã chạy `validate_palette.js`):
| id | VI | EN | Hex |
|---|---|---|---|
| rose | Hồng | Pink | `#FF4D6D` (= accentLove) |
| purple | Tím | Purple | `#7C5CD6` (= accentLavenderDeep) |
| blue | Xanh dương | Blue | `#1C7ED6` |
| teal | Ngọc | Teal | `#0E9384` |
| orange | Cam | Orange | `#E8590C` |
| green | Xanh lá | Green | `#2F9E44` |
| magenta | Hồng sen | Magenta | `#C2255C` |
| amber | Vàng nghệ | Amber | `#B7791F` |

**Cặp bị khoá** (mỗi lúc chỉ có 2 màu cùng hiện nên chỉ cần kiểm từng cặp; khoá khi người bình thường khó phân biệt ΔE < 15 hoặc người mù màu ΔE < 6):
| Cặp | Lý do (ΔE OKLab×100) |
|---|---|
| Hồng ↔ Cam | mắt thường 10.3 |
| Hồng ↔ Hồng sen | mắt thường 14.4 |
| Tím ↔ Xanh dương | mù màu lục 1.9 · mắt thường 12.0 |
| Ngọc ↔ Xanh lá | mắt thường 10.1 |
| Cam ↔ Vàng nghệ | mù màu lục 2.9 · mắt thường 10.3 |
| Xanh lá ↔ Vàng nghệ | mù màu lục 4.3 |

Các cặp 6–8 (Hồng↔Ngọc, Hồng↔Xanh lá, Ngọc↔Hồng sen, Cam↔Xanh lá, Hồng↔Vàng nghệ) vẫn cho chọn, vì luôn có mã phụ: tên người cạnh chấm, và vị trí cố định (dòng trên = bạn, dòng dưới = người ấy). ⇒ Người ấy dùng màu nào thì màu đó + các màu bị khoá với nó **mờ đi không bấm được**. Mỗi người luôn còn ≥ 5 màu.

Luật dùng màu:
- **Màu người chỉ cho dữ liệu của người đó.** Trạng thái giao diện (ô đang chọn, hôm nay, nút chính, công tắc bật) = navy `textPrimary`, để không lẫn với màu ai đó chọn.
- **Chữ không bao giờ dùng màu người.** Tên người = chữ `textSecondary` + **chấm 8px màu của người đó** đứng trước. Con số = `textPrimary`.
- Nền rãnh thanh = `surfaceLight` #F5F0F5. Vùng "ngủ cùng lúc" = **trung tính** `textPrimary` α .07 (không dùng màu ai) + tim `accentLove`.
- **Luật chữ:** chữ mang thông tin dùng `textPrimary`/`textSecondary`. `textTertiary` #A0A0B0 (2.5:1) chỉ cho trang trí/disabled: ngày tương lai, chevron, chấm "không có dữ liệu".
- **Nút chính:** nền navy `textPrimary`, chữ trắng, kể cả "Bật theo dõi" và "Chia sẻ với người ấy" (chữ trắng trên rose chỉ 3.2:1). Muốn ấm thì thêm icon tim hồng trong nút.

**Mockup tương tác (5 artboard):** https://claude.ai/artifact/9Gmj2jJViF5DPeBCNSmsvF — Home · màn Giấc ngủ (bấm ngày / đổi chế độ / đổi tháng / bật-tắt chia sẻ; tweak `partnerShares`) · các trạng thái card · sheet bật theo dõi 2 bước (tweak `platform` android/ios) · sheet sửa giờ. Mockup và spec lệch nhau thì spec này thắng.

## User flow
```
Home ─ SleepCard
  ├─ (chưa bật) "Bật theo dõi" ─► SleepSetupSheet
  │       B1 Cấp quyền ─► Android: Cài đặt "Quyền truy cập dữ liệu sử dụng"
  │                      iOS: popup Apple Health (chỉ đọc Giấc ngủ)
  │          └─ quay lại app (resume) ─► tự kiểm quyền ─► B2
  │       B1' "Mình sẽ tự ghi" ─► chế độ ghi tay ─► B2
  │       B2 "Chia sẻ với người ấy?" [Chia sẻ] / [Để sau]  (mặc định TẮT)
  │          └─ đóng sheet ─► app quét ngay 14 đêm gần nhất ─► card có số liệu
  ├─ (đã bật) tap card ─► SleepScreen (chọn sẵn đêm qua)
  │       ├─ đổi chế độ xem: Cả hai / Bạn / Người ấy
  │       ├─ ‹ › đổi tháng · tap 1 ngày ─► card Chi tiết đêm cập nhật
  │       ├─ ✎ trên dòng của mình ─► SleepEditSheet ─► Lưu (nhãn nguồn = "Đã sửa")
  │       ├─ công tắc "Chia sẻ với người ấy"
  │       └─ "App tính thế nào?" ─► SleepHowItWorksSheet
  └─ "Ẩn" (chưa bật) ─► card ẩn 30 ngày rồi hiện lại 1 lần (Home là lối vào duy nhất nên không ẩn vĩnh viễn — States A1)
```

## Wireframe

### A. `SleepCard` (Home) — đã bật, cả hai chia sẻ
```
┌──────────────────────────────────────────────┐  ContentCard r24, pad 16
│ (☾)  Đêm qua                              ›  │  IconBadge moon lavender · 16 w800
│                                              │
│  BẠN                 │  MINH ANH             │  chấm màu + micro-caps 11 w700 textSecondary
│  7g 15p              │  6g 50p               │  số 22 w800 + đơn vị 13 textSecondary
│  23:40 – 06:55       │  00:05 – 06:55        │  12 w500 textSecondary
│  ▬▬▬▬▬▬▬▬▬░░░        │  ▬▬▬▬▬▬▬▬░░░░         │  thanh 6px r999, max = 10 giờ
│ ─────────────────────────────────────────── │  hairline textSecondary .10
│  ♥ Ngủ cùng lúc 6g 50p · Bạn ngủ trước 25p   │  12 w600 textSecondary, ♥ accentLove 12
└──────────────────────────────────────────────┘
```

### B. `SleepScreen`
```
 ←            ( ☾ GIẤC NGỦ )                    SubScreenHeader (chip giữa, không title)
 ┌───────────────────────────────────────────┐
 │ [ Cả hai ]  [ ●Bạn ]  [ ●Minh Anh ]       │  pill chọn = navy; chấm = màu người
 └───────────────────────────────────────────┘
 ┌ ContentCard ──────────────────────────────┐
 │  ‹          Tháng 10, 2026           ›    │  16 w800, mũi tên _NavArrow
 │  T2    T3    T4    T5    T6    T7    CN   │  11 w700 textSecondary
 │                    1     2     3     4    │  số ngày 12 w600
 │                   ◐◑    ◔◑   ◌◑    ◕●♥    │  CARD BẦU TRỜI ĐÊM; mỗi ô 2 trăng
 │                                           │  trái = BẠN · phải = người ấy · ♥ = cùng lúc ≥7g
 │   8     9   ┏10┓   11 ...                 │  ô chọn = viền 2px navy
 │  ...                                      │
 │  ◔ ◑ ◕ ● legend · "Trăng càng tròn…"     │  chú thích trắng trên nền đêm
 └───────────────────────────────────────────┘
   (xem riêng 1 người: mỗi ô 1 trăng 22px; chú thích: 5 trăng mẫu + "Trăng càng tròn, ngủ càng tròn giấc")
 ┌ ContentCard — Đêm 9 → sáng 10/10 ─────────┐
 │  18h     21h     0h      3h      6h   12h │  vạch giờ 10 textSecondary
 │  Bạn    ░░░░░░██████████╳█████░░░░░░░░    │  lane 10px, ╳ = thức giấc
 │  M.Anh  ░░░░░░░░███████████████░░░░░░░    │
 │         ░░░░░░░░[▓▓▓▓▓▓▓▓▓▓▓▓]░░░░░░░    │  dải chồng = navy α .07 (trung tính) sau 2 làn
 │ ────────────────────────────────────────  │
 │  Bạn      23:40 → 06:55   7g 15p     ✎    │  15 w700 · nhãn nguồn "Tự ghi nhận"
 │           Thức giấc 1 lần                 │  12 textSecondary
 │  Minh Anh 00:05 → 06:55   6g 50p          │  không ✎
 │  ♥ Ngủ cùng lúc 6g 50p                    │
 └───────────────────────────────────────────┘
   THÁNG NÀY                                     SectionHeader
 ┌ ContentCard ──────────────────────────────┐
 │  ┌ Bạn ───────────┐  ┌ Minh Anh ───────┐  │  2 ô tint .10 (rose / lavender) r16
 │  │ 7g 02p TB/đêm  │  │ 6g 41p TB/đêm   │  │  20 w800
 │  │ Ngủ ~23:50     │  │ Ngủ ~00:20      │  │  12 w600
 │  │ Dậy ~06:50     │  │ Dậy ~07:05      │  │
 │  │ 21 đêm         │  │ 18 đêm          │  │  11 textSecondary
 │  └────────────────┘  └─────────────────┘  │
 │  ♥ TB ngủ cùng lúc 5g 48p mỗi đêm         │  13 w700
 └───────────────────────────────────────────┘
 ┌ ContentCard ──────────────────────────────┐
 │ (👥) Chia sẻ với người ấy           [ ◯ ] │  15 w700 + switch bật = navy
 │      Tắt thì chỉ mình bạn xem được.       │  12 textSecondary
 │ ──────────────────────────────────────────│
 │ (🎨) Màu của bạn                          │  15 w700
 │      Minh Anh đang dùng màu Tím. Màu quá  │  12 textSecondary
 │      giống (Xanh dương) sẽ bị khoá.       │
 │   (✓)    ( )     (/)     ( )              │  tròn 32 + tên 11; ✓ = đang chọn
 │   Hồng  của M.A  X.dương  Ngọc            │  mờ = người ấy dùng · gạch = quá giống
 │   ( )    ( )     ( )     ( )              │
 │   Cam   Xanh lá Hồng sen Vàng nghệ        │
 │ ──────────────────────────────────────────│
 │ (📱) Nguồn: Điện thoại (tự động)       ›  │  → sửa nguồn / cấp lại quyền
 │ (ⓘ) App tính giấc ngủ thế nào?         ›  │  → E
 └───────────────────────────────────────────┘
```

### C. `SleepSetupSheet`
```
 ── handle ──
 (☾ lớn 56, đĩa lavender .12)
 Để điện thoại tự ghi giấc ngủ                     20 w800 center
 Mỗi sáng, app xem đêm qua điện thoại nghỉ
 lâu nhất từ lúc nào — không đọc tin nhắn,
 ảnh hay bất cứ nội dung nào.                       14 textSecondary center
 ✓ Không cần làm gì mỗi ngày                        3 dòng check 13 w600
 ✓ Sửa được nếu app đoán sai
 ✓ Chỉ chia sẻ khi bạn muốn
 [        Cấp quyền        ]   pill h52 navy
     Mình sẽ tự ghi            text button textSecondary
 ── bước 2 (thay nội dung, AnimatedSwitcher) ──
 (👥) Cho Minh Anh xem giấc ngủ của bạn?
 Người ấy sẽ thấy giờ ngủ, giờ dậy của bạn.
 Bạn tắt lúc nào cũng được.
 [ ♥ Chia sẻ với người ấy  ]  pill h52 navy + tim hồng (trắng-trên-rose không đủ tương phản)
       Để sau                  text button
```

### D. `SleepEditSheet`
```
 Đêm 9 → sáng 10/10                                 16 w800
 ┌ (lamp_slash) Đi ngủ        23:40  › ┐           InkTile r22 → showAppTimePicker
 ┌ (sun_fog)    Thức dậy      06:55  › ┐
 Tổng: 7 giờ 15 phút                                 15 w700 (cập nhật live)
 [          Lưu          ]   pill h52 navy
   Xoá đêm này               text button màu error (chỉ khi đêm đã có dữ liệu)
```

## Spec chi tiết (token)

> Cỡ chữ nhỏ nhất của feature này = **11** (micro-caps, nhãn giờ, thứ); chữ dữ liệu và chú thích = **12** — theo `impeccable detect` (chữ chức năng dưới 11px khó đọc). Ngoại lệ: `EyebrowChip` 11 sẵn có của app.

### A. `SleepCard`
- `ContentCard` (trắng đặc r24, shadow black .06 blur 16 y10), padding 16.
- Header Row `crossAxisAlignment.center`: `IconBadge(IconsaxPlusLinear.moon, tint: accentLavenderDeep)` (squircle 44 r16, nền α .12) · gap 12 · "Đêm qua" 16 w800 textPrimary · Spacer · chevron `arrow_right_3` 18 textTertiary (trang trí). Cả card = `InkWell` r24 splash rose .08.
- Thân: 2 cột `Expanded`, cột trái pad phải 14 + vạch dọc 1px textSecondary α .10, cột phải pad trái 14. Mỗi cột:
  - nhãn: chấm 8 màu người + gap 6 + tên micro-caps 11 w700 ls 1.0 uppercase `textSecondary`; tên người ấy lấy như `MoodCard._partnerName` (fallback `reactionPartnerFallback`).
  - gap 6 · thời lượng: **số 22 w800 textPrimary + đơn vị "g"/"p" 13 w700 textSecondary** (`RichText`).
  - gap 2 · khoảng giờ 12 w500 textSecondary `DateFormat.Hm(locale)` (D3). **R1:** đêm Đã sửa / Ghi tay → hàng này thành Row [khoảng giờ · gap 6 · nhãn nguồn] (nhãn = pill chuẩn ở mục B, chi tiết đêm).
  - **Trăng 30px** (màu người, đúng pha như lịch trăng, có đĩa mờ α .16) đứng TRÁI khối [thời lượng + khoảng giờ], gap 10 — thay thanh ngang cũ (đồng bộ ngôn ngữ trăng toàn feature).
- Footer (chỉ khi CẢ HAI có số đêm qua): gap 14 · hairline · gap 12 · Row tim `IconsaxPlusBold.heart` 12 accentLove + text 12 w600 textSecondary. Ưu tiên câu: "Ngủ cùng lúc X" (+ " · A ngủ trước Yp" nếu lệch ≥ 10 phút). Chồng nhau = 0 → "Đêm qua hai giấc không trùng nhau" (không dùng "hai đứa").

### B. `SleepScreen`
- Nền: trong suốt trên `dawnBlush` (giống `LunarCalendarScreen`: Container dawnBlush → Scaffold transparent → SafeArea → `SingleChildScrollView` pad `16,16,16,24`).
- Header: `SubScreenHeader(badge: sleepBadge, badgeIcon: IconsaxPlusLinear.moon)`. gap 20.
- **Segmented** (chỉ hiện khi người ấy ĐANG chia sẻ; không thì ẩn hẳn, xem "Bạn"): Row 3 pill, gap 8, mỗi pill cao 44, pad ngang 16, r999, chữ 13 w700; chọn = **nền navy `textPrimary` + chữ trắng** (khác chip Lịch âm vì trắng-trên-rose không đạt 4.5:1); chưa chọn = nền textSecondary α .06 + viền α .18 + chữ textPrimary. Mặc định = "Cả hai". gap 16.
- **Lịch tháng = "LỊCH TRĂNG"** (v3, 2026-10-10 — user: "ghi thẳng số giờ hơi nhàm chán", dùng skill UI UX Pro Max + đọc source).
  - **Ý tưởng:** mỗi đêm là một vầng trăng — **trăng càng tròn = ngủ càng tròn giấc** (chơi chữ thành ngữ "ngủ tròn giấc"; gần văn hoá lịch âm mà app đã có). Nguồn: UI UX Pro Max (`--domain product` "Sleep Tracker" → *deep midnight blue + stars/moon accent*; "Couple app" → *Aurora + Soft UI*; `--domain chart` heatmap lịch → *phải có ký hiệu trong ô, không chỉ màu*) + code thật: bảng màu đêm & cách vẽ trăng của `SkyBackdropPainter` trong `love_tree_screen.dart` (`#2E2A52`, trăng kem `#FFF6D6` có quầng mềm, sao trắng).
  - **Card bầu trời đêm** (khác `ContentCard`, cố ý — đây là "lịch các đêm"): gradient dọc `#2E2A52` 0% → `#3A3160` 55% → `#45396C` 100% (đáy tối hơn bản Cây Tình Yêu để trăng & chữ đạt tương phản), r24, shadow `rgba(46,42,82,.28)` blur 24 y12, pad `12,12,12,16`. 16 ngôi sao tĩnh 1–2px trắng α .25–.55 rải ngẫu nhiên cố định (có thể twinkle chậm như Cây Tình Yêu; **Reduce Motion → tĩnh**). Cấu trúc tháng/thứ/lưới copy `_MonthCalendarCard` (hàng tháng 16 w800 **trắng**, mũi tên trắng, thứ 11 w700 trắng α .66, `GridView 7 cột`, `childAspectRatio 0.70`). Không cho sang tháng tương lai.
  - **Ô ngày** (margin 2, r12, cao 68): số ngày 12 w600 trắng α .92 (tương lai α .34 = disabled) · hôm nay: w700 + gạch chân 2px trắng · **ô đang chọn: nền trắng α .12 + viền 1.5px trắng α .85**.
  - **Trăng trong ô:** "Cả hai" = **2 trăng 14px cạnh nhau (trái = BẠN, phải = người ấy, cách 4)**; xem riêng = 1 trăng 22px. Pha theo độ dài giấc: **<5g lưỡi liềm (sáng 20%) · 5–6g trăng non (36%) · 6–7g bán nguyệt (50%) · 7–8g gần tròn (72%) · ≥8g tròn (100%)**. Phần sáng = màu người pha trắng 42%; **luôn vẽ cả đĩa mờ** cùng màu α .22 (cho thấy "trăng đầy" là bao nhiêu — đây là thước đo mà bản cột thiếu); quầng `drop-shadow` 3px màu người α .9. Đêm chưa có dữ liệu = vòng tròn nét đứt 1px trắng α .55 (2-2). Ngày tương lai: không vẽ.
  - **Tim "đồng điệu"**: góc trên-phải ô, tim 10px `#FF8FA3`, CHỈ khi hai người **ngủ cùng lúc ≥ 7 tiếng** (hiếm ⇒ có giá trị; ngưỡng 6 tiếng thử rồi — gần đêm nào cũng có tim, mất ý nghĩa).
  - **Chú thích** (trong card, kẻ hairline trắng α .14 phía trên): hàng 5 trăng mẫu 18px kem `#FFF6D6` + nhãn 11 w700 trắng α .82 (`dưới 5g · 5–6g · 6–7g · 7–8g · 8g trở lên`) → câu 13 w700 trắng "Trăng càng tròn, ngủ càng tròn giấc" → (chỉ chế độ Cả hai) dòng 12 w600 trắng α .80: chấm màu "Trăng trái: Bạn" · chấm màu "Trăng phải: <tên>" · tim "Ngủ cùng lúc từ 7 tiếng".
  - **Phương án B (giữ làm dự phòng, tweak `cellVariant` trong mockup):** ghi thẳng số giờ (2 dòng `●7,3` chữ trắng) — dùng nếu test với user thấy trăng khó hiểu.
  - Tương phản đã tính trên nền tối: trăng 8 màu ≥ 3,74:1 (thấp nhất Hồng sen ở đáy card), vòng nét đứt ≥ 4,34:1, chữ trắng α .80 ≥ 7,2:1, α .66 (chỉ ở hàng thứ, gần đỉnh card) 6,8:1.
  - Segmented: pill "Bạn" và "<tên>" có chấm 8px màu người (viền trắng 2px; viền navy khi đang chọn) để nối màu với người ngay từ đầu.
- **Chi tiết đêm** (gap 16): ContentCard pad 16.
  - Tiêu đề 15 w800: `sleepNightTitle` ("Đêm 9 → sáng 10/10").
  - Trục thời gian 18:00 → 12:00 hôm sau (18 giờ = 100% bề rộng). Nhãn 18h·21h·0h·3h·6h·9h·12h, 11 w600 textSecondary, canh theo cột làn (lùi 64 + 8).
  - Làn: mỗi hàng cao 16, thanh cao 10 r999 ở giữa, rãnh `surfaceLight`, đoạn ngủ = màu người; mỗi lần thức giấc = khe 2px nền trắng. Hàng cách nhau 6. Nhãn làn trái 12 w700 textPrimary, rộng cố định 64, ellipsis.
  - Dải "ngủ cùng lúc": nằm SAU 2 làn, phủ khoảng chồng, tràn trên/dưới 4px, nền **`textPrimary` α .07** (trung tính, hợp mọi cặp màu), r8. Chỉ ở chế độ "Cả hai".
  - gap 16 · hairline → mỗi người 1 hàng cao ≥ 44: **trăng 18px màu người (đúng pha của đêm đó; thiếu dữ liệu = vòng nét đứt `textTertiary`)** · tên 15 w700 rộng 64 · "23:40 → 06:55" 15 w600 · Spacer · thời lượng 15 w800. Hàng dưới (lùi 16) 12 w500 textSecondary: "Thức giấc N lần" hoặc "Ngủ một mạch" + " · <tên pha trăng>" + **nhãn nguồn — CHỈ khi Đã sửa / Ghi tay** (pill pad 8×3, r999, nền textSecondary α .08, icon `edit_2` 10 + chữ 11 w700 textSecondary; đêm tự ghi không có pill). Hàng của MÌNH có `HeaderIconButton(edit_2)` 44 ở cuối → D. **R3:** đêm quá 7 ngày → bỏ nút ✎ (giữ khoảng trống 34 cho thẳng cột thời lượng) + thêm dòng 12 w600 textSecondary `sleepEditLocked` dưới hàng phụ.
  - Footer: hộp r16 pad 10×12 nền **`surfaceLight`**, tim 14 accentLove + chữ 13 w700 textPrimary. Không trùng nhau → `sleepNoOverlapNight`.
- **Tháng này**: `SectionHeader(sleepMonthSection)` → ContentCard pad 16 → Row 2 ô (gap 12) r16 pad 14, nền màu người α .10; số TB 20 w800 textPrimary + "/đêm" 12 w600 textSecondary; "Ngủ ~hh:mm" / "Dậy ~hh:mm" 12 w600 textSecondary; "Ngủ ~hh:mm · Dậy ~hh:mm" 1 dòng; **"● N đêm tròn giấc"** 12 w700 textPrimary (chấm tròn đặc màu người = trăng tròn, đếm đêm ≥ 8 tiếng) + "trên M đêm" 12 w600 textSecondary. Nhãn ô = chấm 8 + tên micro-caps như card. Dưới: dòng ♥ 13 w700 textPrimary "N đêm ngủ cùng lúc từ 7 tiếng · TB Xg Yp" (chỉ khi người ấy chia sẻ). Giờ ngủ TB tính theo vòng tròn (23:50 & 00:10 → 00:00, không phải 12:00) — xem Dev notes.
- **Cài đặt**: ContentCard pad 0, 4 hàng, hairline indent 74. `IconBadge` 44: `profile_2user` (rose), `mobile`/`health`/`edit` theo nguồn (lavender), `info_circle` (lavender). Switch bật = **navy** (màu trạng thái, không dùng rose vì rose có thể là màu của ai đó).
  - Hàng **"Màu trăng của bạn"** (thứ 2, sau công tắc chia sẻ): đĩa 44 r16 nền màu của bạn α .22 + icon bảng màu 20 navy · tiêu đề 15 w700 · phụ đề 12 w500 textSecondary `sleepMyColorSub` (nói rõ người ấy dùng màu gì + màu nào bị khoá). Dưới đó **lưới 4 cột × 2 hàng** (gap 6×8), mỗi ô là 1 nút cao ≥ 60: hình tròn 32 màu + tên màu 12 dưới.
    - Đang chọn: vòng trắng 2px + vòng navy 2px bên ngoài + dấu ✓ trắng 16; tên 12 w700 textPrimary.
    - Màu người ấy đang dùng: tròn α .30, không bấm được, tên đổi thành "<tên>".
    - Màu quá giống màu người ấy: tròn α .30 + gạch chéo navy 2px, không bấm được; `Semantics` "quá giống màu của <tên>".
    - Chọn xong áp ngay mọi nơi (lịch, làn, thống kê, card Home của cả 2 máy), haptic selectionClick.

### C/D/E. Sheets
- Khung chung = sheet blur kiểu `MoodPicker`/`StreakSheet` (`cardSurface`, r28 góc trên, handle 36×4 textTertiary α .4, pad 24, SafeArea bottom).
- C: trên cùng 2 chấm bước (đang ở = 16×6 rose, còn lại 6×6 textTertiary α .5). Bước 1: đĩa 56 nền accentLavenderDeep α .12, icon moon 28 `accentLavenderDeep`; tiêu đề 20 w800 center; mô tả 14 w500 textSecondary center height 1.45 (khác nhau theo nền tảng); 3 dòng ✓ (`tick_circle` 18 success) 13 w600 textPrimary, cách 10; **hộp gợi ý** r16 nền surfaceLight pad 10×12, icon `info_circle` 16 + 12 w500 textSecondary (`sleepSetupHintAndroid` / `sleepSetupHintIos`); nút "Cấp quyền" pill h52 navy; "Mình sẽ tự ghi" text 14 w600 textSecondary cao 44. Bước 2: đĩa 56 nền rose α .12, icon `profile_2user` 28 accentLove; tiêu đề + mô tả như trên; micro-caps "MINH ANH SẼ THẤY" 11 w700 textSecondary → **hộp xem trước** r16 nền surfaceLight pad 14 (chấm · "Bạn" 14 w700 · giờ 13 w600 textSecondary · thời lượng 14 w700) → 12 w500 textSecondary `sleepShareAskOnly`; nút "Chia sẻ với người ấy" pill h52 **navy + icon tim 16 sunset1 #FF6B9D**; "Để sau" text 14 w600; "Quay lại bước 1" text 13 w600 gạch chân.
- D: tiêu đề 20 w800 + phụ đề 13 w500 textSecondary `sleepEditSubtitle`; 2 tile cao 64 r22 **nền `surfaceLight`** (white .72 của `InkTile` sẽ chìm trên sheet trắng), đĩa icon 40 r14 rose α .12 icon `lamp_slash` / `sun_fog` 20 accentLove, nhãn 15 w700, giá trị 16 w800 bên phải, chevron → `showAppTimePicker(title: sleepEditBedTitle / sleepEditWakeTitle)`. Tổng: icon moon 18 lavenderDeep + 15 w700. Ghi chú 12 w500 textSecondary `sleepEditNote`. Lỗi validate = text 12 `error` dưới tổng, nút Lưu disabled. "Xoá đêm này" = chữ textPrimary 14 w700 + icon `trash` 16 `error` (chữ đỏ #EF5350 chỉ 3.5:1).
- E: tiêu đề 20 w800 + 4 đoạn 14 textSecondary (copy ở bảng), nút "Đã hiểu" pill navy.

## States
| Mã | Ở đâu | Điều kiện | Hiển thị |
|---|---|---|---|
| A0 | Card | Couple `waiting_partner` | Chỉ cột "Bạn" full-width (không cột người ấy, không footer). |
| A1 | Card | Chưa bật theo dõi | Thân thay bằng: 14 w500 textSecondary "Để điện thoại tự ghi giấc ngủ, sáng nào cũng biết đêm qua người ấy ngủ ra sao." + Row [pill h44 **navy** + icon moon trắng "Bật theo dõi" → C] [TextButton "Ẩn" 14 w600 textSecondary]. Không có chevron. "Ẩn" = ẩn card **30 ngày** (Hive `sleep_card_hidden_until`), sau đó hiện lại 1 lần. |
| A2 | Card/Màn | Android: mất quyền dữ liệu sử dụng / iOS: Health bị từ chối | Cột Bạn: icon `warning_2` 16 warning (trang trí, chữ mang nghĩa) + "Cần cấp lại quyền" 13 w700 textPrimary + link gạch chân 12 w700 textPrimary "Mở cài đặt". Cột người ấy vẫn hiện bình thường. Màn: banner ContentCard viền warning α .45 trên lịch. Dữ liệu cũ vẫn hiện. |
| A3 | Card cột Bạn | Đã bật nhưng đêm qua không có giấc ≥ 3 giờ | "Chưa ghi nhận" 15 w700 textSecondary + link gạch chân 12 w700 textPrimary "Ghi tay" → D. |
| A4 | Card cột người ấy | Người ấy TẮT chia sẻ | Icon `lock` 18 textSecondary + "Chưa chia sẻ" 13 w600 textSecondary. Không nút rủ (Phase 2). |
| A5 | Card cột người ấy | Có chia sẻ, đêm qua trống | "Chưa có dữ liệu" 13 w600 textSecondary. |
| L | Card + lịch | Đang tải lần đầu | `ShimmerSkeleton`: card 2 khối 64; lịch: lưới ô r12 shimmer. Không spinner. |
| E | Màn | Lỗi đọc dữ liệu người ấy | Vẫn vẽ dữ liệu của mình; cột người ấy = A5 + SnackBar floating navy `sleepLoadFailed`. Lỗi lưu (D) = giữ sheet, SnackBar `sleepSaveFailed`. |
| S | Màn | Lưu sửa thành công | Đóng sheet, ô ngày + chi tiết cập nhật, nhãn nguồn "Đã sửa", haptic lightImpact. |
| M | Màn | iOS không có dữ liệu Health / Android < 9 | Nguồn = "Ghi tay"; banner nhẹ (InkTile) "Bật *Lịch ngủ* trong app Sức khoẻ để iPhone tự ghi" (chỉ iOS, có ✕ ẩn). |
| P | Màn | Người ấy không chia sẻ | Ẩn segmented; lịch chế độ "Bạn"; card chi tiết có hàng người ấy = 🔒 "<tên> chưa chia sẻ giấc ngủ". Thống kê chỉ 1 ô full-width. |
| F | Lịch | Ngày tương lai | Số ngày textTertiary, không cột, không bấm. |
| D0 | Sheet D | Giờ dậy = giờ ngủ, hoặc tổng < 1 giờ / > 16 giờ | Lỗi `sleepEditInvalid`, Lưu disabled. Giờ dậy < giờ ngủ = tự hiểu là qua nửa đêm (không báo lỗi). |
| R | Card + chi tiết | Đêm Đã sửa / Ghi tay (của mình HOẶC người ấy) | Pill `✎ Đã sửa` / `✎ Ghi tay` cạnh giờ (card) hoặc ở hàng phụ (chi tiết). Hai bên thấy như nhau. |
| K | Chi tiết đêm | Đêm của mình quá 7 ngày | Không có nút ✎ (kể cả khi "Chưa ghi nhận"), dòng `sleepEditLocked`. |
| C1 | Bộ chọn màu | Người ấy đổi sang màu trùng / quá giống màu mình | Máy nào cũng dùng 1 luật như nhau: người có `uid` xếp sau tự hiển thị bằng màu hợp lệ đầu tiên trong bộ (không ghi đè lựa chọn đã lưu). Phụ đề hàng "Màu của bạn" báo `sleepColorAutoChanged`. |

## Interaction & animation (AppMotion: 200–320ms, easeOutCubic)
- Ô lịch: số + nền bậc màu crossfade 200ms easeOutCubic khi đổi tháng / chế độ / màu; **Reduce Motion → đổi ngay** (`AppMotion.reduceMotion`).
- Đổi màu: vòng chọn chuyển sang ô mới bằng `AnimatedContainer` 200ms; mọi chỗ dùng màu đó đổi cùng lúc (không chạy từng phần).
- Đổi tháng: `AnimatedSwitcher` 200ms fade + trượt ngang 8px theo hướng ‹/›. Vuốt ngang trên lưới = đổi tháng (giống thao tác lịch hệ thống).
- Đổi segmented: pill `AnimatedContainer` 200ms + `HapticFeedback.selectionClick`.
- Tap ngày: ô chọn đổi nền 160ms; card chi tiết `AnimatedSize` 220ms; lane vẽ từ trái sang 320ms (Reduce Motion → tĩnh).
- Setup bước 1 → 2: `AnimatedSwitcher` 260ms.
- Card Home: `EntranceReveal` như các card khác trong nhóm.
- A11y: mỗi ô ngày bọc `Semantics(label: sleepDaySemantics)` — vd "Ngày 10: bạn ngủ 7 giờ 15 phút, Minh Anh ngủ 6 giờ 50 phút". Màu không phải tín hiệu duy nhất (luôn có chú thích + chữ trong chi tiết). Vùng chạm ô ngày ≥ 44 (ô ~48×68 trên máy 360pt).

## Copy (song ngữ — xưng "bạn / người ấy / chúng mình", KHÔNG "hai đứa")
| Key | VI | EN |
|---|---|---|
| sleepCardTitle | Đêm qua | Last night |
| sleepBadge | GIẤC NGỦ | SLEEP |
| sleepYou | Bạn | You |
| sleepDurationShort | {h}g {m}p | {h}h {m}m |
| sleepDurationLong | {h} giờ {m} phút | {h} hr {m} min |
| sleepTogether | Ngủ cùng lúc {duration} | Asleep together {duration} |
| sleepWentFirst | {name} ngủ trước {minutes}p | {name} fell asleep {minutes}m earlier |
| sleepNoOverlap | Đêm qua hai giấc không trùng nhau | Your sleep didn't overlap last night |
| sleepSetupPitch | Để điện thoại tự ghi giấc ngủ, sáng nào cũng biết đêm qua người ấy ngủ ra sao. | Let your phone log your sleep, and see how your person slept each morning. |
| sleepEnableCta | Bật theo dõi | Turn on |
| sleepHide | Ẩn | Hide |
| sleepNotRecorded | Chưa ghi nhận | Not recorded |
| sleepLogManually | Ghi tay | Log manually |
| sleepPartnerNotShared | Chưa chia sẻ | Not shared |
| sleepPartnerNotSharedLong | {name} chưa chia sẻ giấc ngủ | {name} isn't sharing sleep |
| sleepNoData | Chưa có dữ liệu | No data yet |
| sleepNeedsPermission | Cần cấp lại quyền | Permission needed |
| sleepOpenSettings | Mở cài đặt | Open settings |
| sleepViewBoth | Cả hai | Both |
| ~~sleepLegendHint~~ | ~~Cột cao = ngủ lâu~~ (bỏ cùng cột đôi — dùng `sleepLegendNumbers`) | — |
| sleepNightTitle | Đêm {d1} → sáng {d2} | Night of {d1} → {d2} |
| sleepAwakenings | Thức giấc {count} lần | Woke up {count} times |
| sleepSourceAuto | Tự ghi nhận | Auto |
| sleepSourceHealth | Apple Health | Apple Health |
| sleepSourceEdited | Đã sửa | Edited |
| sleepSourceManual | Ghi tay | Manual |
| sleepMonthSection | Tháng này | This month |
| sleepPerNight | /đêm | /night |
| sleepAvgBed | Ngủ ~{time} | Bed ~{time} |
| sleepAvgWake | Dậy ~{time} | Up ~{time} |
| sleepNightsCount | {count} đêm | {count} nights |
| sleepAvgTogether | TB ngủ cùng lúc {duration} mỗi đêm | Avg. {duration} asleep together per night |
| sleepShareToggle | Chia sẻ với người ấy | Share with your person |
| sleepShareToggleSub | Tắt thì chỉ mình bạn xem được. | When off, only you can see it. |
| sleepSourceRow | Nguồn: {source} | Source: {source} |
| sleepSourcePhone | Điện thoại (tự động) | Phone (automatic) |
| sleepHowItWorks | App tính giấc ngủ thế nào? | How is sleep calculated? |
| sleepSetupTitle | Để điện thoại tự ghi giấc ngủ | Let your phone log your sleep |
| sleepSetupBodyAndroid | Mỗi sáng, app xem đêm qua điện thoại nghỉ lâu nhất từ lúc nào — không đọc tin nhắn, ảnh hay bất cứ nội dung nào. | Each morning the app checks when your phone rested longest overnight — it never reads messages, photos or any content. |
| sleepSetupBodyIos | App đọc giấc ngủ mà iPhone hoặc Apple Watch đã ghi trong app Sức khoẻ — chỉ đọc, không ghi gì. | The app reads the sleep your iPhone or Apple Watch saved in Health — read only, nothing is written. |
| sleepSetupPoint1 | Không cần làm gì mỗi ngày | Nothing to do each day |
| sleepSetupPoint2 | Sửa được nếu app đoán sai | Fix it if the app guesses wrong |
| sleepSetupPoint3 | Chỉ chia sẻ khi bạn muốn | Shared only if you want |
| sleepGrantCta | Cấp quyền | Allow access |
| sleepManualCta | Mình sẽ tự ghi | I'll log it myself |
| sleepShareAskTitle | Cho {name} xem giấc ngủ của bạn? | Let {name} see your sleep? |
| sleepShareAskBody | Người ấy sẽ thấy giờ ngủ, giờ dậy của bạn. Bạn tắt lúc nào cũng được. | They'll see when you sleep and wake. You can turn this off anytime. |
| sleepShareAskCta | Chia sẻ với người ấy | Share with them |
| sleepLater | Để sau | Later |
| sleepEditBedTitle | Đi ngủ | Bedtime |
| sleepEditWakeTitle | Thức dậy | Wake up |
| sleepEditTotal | Tổng: {duration} | Total: {duration} |
| sleepEditInvalid | Giấc ngủ cần dài từ 1 đến 16 giờ | Sleep must be 1 to 16 hours |
| sleepSave | Lưu | Save |
| sleepDeleteNight | Xoá đêm này | Delete this night |
| sleepSaveFailed | Chưa lưu được, thử lại nhé | Couldn't save, please try again |
| sleepLoadFailed | Chưa tải được giấc ngủ của người ấy | Couldn't load your person's sleep |
| sleepIosHealthHint | Bật *Lịch ngủ* trong app Sức khoẻ để iPhone tự ghi giấc ngủ | Turn on *Sleep Schedule* in Health so your iPhone logs sleep |
| sleepHowBody1 | App coi khoảng điện thoại nghỉ lâu nhất trong đêm (từ 18h đến 14h hôm sau, ít nhất 3 tiếng) là giấc ngủ. | The app treats your phone's longest rest overnight (6 pm to 2 pm, at least 3 hours) as sleep. |
| sleepHowBody2 | Mở máy dưới 5 phút giữa đêm được tính là thức giấc, không làm đứt giấc. | Picking up your phone for under 5 minutes counts as waking up, not ending your sleep. |
| sleepHowBody3 | Đây là ước tính: nằm xem phim hay quên máy ở xa cũng có thể làm số lệch. Bạn sửa được trong 7 ngày, và người ấy sẽ thấy nhãn “Đã sửa”. | It's an estimate: watching a movie in bed or leaving your phone elsewhere can skew it. You can fix it within 7 days, and your person will see an “Edited” label. |
| sleepHowBody4 | App không đọc nội dung nào trên máy, chỉ biết lúc màn hình bật hay tắt. | The app reads no content, only when your screen turns on or off. |
| sleepGotIt | Đã hiểu | Got it |
| sleepDaySemantics | Ngày {day}: {summary} | {day}: {summary} |
| sleepNoAwakenings | Ngủ một mạch | Slept straight through |
| sleepNoOverlapNight | Hai giấc đêm này không trùng nhau | Your sleep didn't overlap this night |
| sleepManualHint | Bấm nút sửa để ghi tay | Tap edit to log it yourself |
| sleepPartnerNightEmpty | Đêm này chưa có giấc ngủ nào được ghi | No sleep logged for this night |
| sleepSetupHintAndroid | Bạn sẽ được đưa tới Cài đặt → Quyền truy cập dữ liệu sử dụng → bật Dear Embeiu, rồi quay lại app. | You'll go to Settings → Usage access → turn on Dear Embeiu, then come back. |
| sleepSetupHintIos | iPhone sẽ hỏi quyền đọc mục Giấc ngủ trong Sức khoẻ. Chưa có dữ liệu thì bật Lịch ngủ trong app Sức khoẻ. | Your iPhone will ask to read Sleep in Health. No data yet? Turn on Sleep Schedule in Health. |
| sleepShareAskPreview | {name} SẼ THẤY | {name} WILL SEE |
| sleepShareAskOnly | Chỉ giờ ngủ, giờ dậy và những lần thức giấc trong đêm, theo giờ nơi bạn ngủ. Đêm nào bạn sửa hoặc ghi tay sẽ có thêm nhãn. *(đổi 2026-10-12, audit: câu cũ "Không có gì khác ngoài giờ ngủ và giờ dậy" sai vì app gửi cả lần thức giấc, múi giờ, nhãn)* | Only when you fell asleep, woke up and any times you woke in the night, in the time zone you slept in. Nights you edit or log by hand get a label. |
| sleepBackToStep1 | Quay lại bước 1 | Back to step 1 |
| sleepEditSubtitle | Sửa lại nếu app đoán chưa đúng. | Fix it if the app got it wrong. |
| sleepEditNote | Sau khi lưu, đêm này hiện nhãn “Đã sửa” — người ấy cũng thấy — và app không tự ghi đè nữa. | Once saved, this night shows an “Edited” label — your person sees it too — and the app won't overwrite it. |
| sleepEditLocked | Quá 7 ngày nên không sửa được nữa | Older than 7 days, can't be edited |
| sleepLegendNumbers | Số = giờ ngủ | Number = hours slept |
| sleepMoonTagline | Trăng càng tròn, ngủ càng tròn giấc | The fuller the moon, the fuller the sleep |
| sleepMoonLeft | Trăng trái: Bạn | Left moon: You |
| sleepMoonRight | Trăng phải: {name} | Right moon: {name} |
| sleepMoonTogether | Ngủ cùng lúc từ 7 tiếng | Asleep together 7h+ |
| sleepPhase0 | Trăng lưỡi liềm | Thin crescent |
| sleepPhase1 | Trăng non | Crescent |
| sleepPhase2 | Trăng bán nguyệt | Half moon |
| sleepPhase3 | Trăng gần tròn | Gibbous |
| sleepPhase4 | Trăng tròn | Full moon |
| sleepLegend0 | dưới 5g | under 5h |
| sleepLegend1 | 5–6g | 5–6h |
| sleepLegend2 | 6–7g | 6–7h |
| sleepLegend3 | 7–8g | 7–8h |
| sleepLegend4 | 8g trở lên | 8h+ |
| sleepFullNights | {count} đêm tròn giấc | {count} full nights |
| sleepOfNights | trên {count} đêm | of {count} nights |
| sleepTogetherNights | {count} đêm ngủ cùng lúc từ 7 tiếng · TB {duration} | {count} nights asleep together 7h+ · avg {duration} |
| sleepLegendLess | Ít | Less |
| sleepLegendMore | Nhiều | More |
| sleepMyColor | Màu trăng của bạn | Your moon color |
| sleepMyColorSub | {name} đang dùng màu {color}. Màu quá giống ({blocked}) sẽ bị khoá. | {name} uses {color}. Colors too similar ({blocked}) are locked. |
| sleepMyColorSubNoBlock | {name} đang dùng màu {color}. | {name} uses {color}. |
| sleepColorTakenBy | {name} | {name} |
| sleepColorTooClose | Quá giống màu của {name} | Too similar to {name}'s color |
| sleepColorAutoChanged | Màu của bạn trùng với người ấy nên tạm hiện màu {color}. | Your color matched your person's, so {color} is shown for now. |
| sleepColorRose | Hồng | Pink |
| sleepColorPurple | Tím | Purple |
| sleepColorBlue | Xanh dương | Blue |
| sleepColorTeal | Ngọc | Teal |
| sleepColorOrange | Cam | Orange |
| sleepColorGreen | Xanh lá | Green |
| sleepColorMagenta | Hồng sen | Magenta |
| sleepColorAmber | Vàng nghệ | Amber |
| sleepEditedSemantics | (đã sửa) | (edited) |

ICU: chuỗi có `*…*` là chữ in đậm do code render, không phải placeholder; tránh `{…}` ngoài placeholder (dùng `<…>` nếu cần — luật §7).

## Assets
- Không cần ảnh/Lottie mới. Icon `iconsax_plus` (đã kiểm có trong 1.0.0): `moon`, `lamp_slash`, `sun_fog`, `profile_2user`, `mobile`, `health`, `edit_2`, `info_circle`, `lock`, `warning_2`, `tick_circle`, `arrow_right_3`; tim `IconsaxPlusBold.heart`.

## Handoff / Dev notes
1. **Tái dùng, đừng chế:** lưới lịch copy từ `lunar_calendar_screen.dart` (`_MonthCalendarCard`/`_DayCell`/`_NavArrow`) — nếu Dev thấy lặp nhiều thì tách widget chung, còn không thì copy cũng được. Cột người ấy theo cách lấy tên của `MoodCard`.
2. **Một "đêm" = ngày thức dậy** (`'YYYY-MM-DD'`). Lưu bedAt/wakeAt dạng epoch + `awakenings` + `source` (`auto|health|manual|edited`). Bản đã sửa tay KHÔNG bị lần quét tự động sau ghi đè. Đêm bị xoá lưu dấu `deleted` (local) để lần quét sau không tạo lại.
10. **Màu riêng:** lưu `sleepColor` (id trong `personPalette`, KHÔNG lưu hex — đổi hex sau này không phải migrate) theo từng người, đọc được bởi người ấy (cùng chỗ với cờ chia sẻ). Bảng cặp khoá + 8 hex đặt 1 chỗ (vd `lib/theme/person_palette.dart`), Card Home / lịch / làn / thống kê đều lấy từ đó. Luật C1 (trùng màu do 2 người đổi cùng lúc) tính ở client, không ghi đè lựa chọn đã lưu. Muốn thêm màu: chạy lại `validate_palette.js` cho từng cặp mới rồi cập nhật bảng khoá. Ô lịch "Cả hai" giữ dòng trên = bạn, dòng dưới = người ấy (đây là mã phụ cho các cặp ΔE 6–8).
9. **Minh bạch (R1–R4):** bản chia sẻ lên Firestore chỉ có giờ cuối + `source` — KHÔNG có field giờ gốc (R2). Kiểm 7 ngày ở client (ẩn ✎) **và** ở rules: create/update/delete của doc đêm chỉ cho khi `wakeAt` ≥ `request.time` − 8 ngày (dư 1 ngày cho lệch múi giờ). Không cố chặn client bị chỉnh sửa ghi `source: auto` giả — ngoài mục tiêu (xem mục Quyết định).
3. **Riêng tư theo thiết kế:** khi chia sẻ TẮT, dữ liệu chỉ nên ở máy (Hive); bật thì mới đẩy lên Firestore cho người ấy đọc; tắt lại thì xoá bản trên Firestore. (Đề xuất — PO/Dev chốt; rules phải chặn người ấy đọc khi cờ chia sẻ tắt, không chỉ ẩn ở UI.)
4. **Khi nào quét:** mỗi lần app mở/resume, quét lại 14 đêm gần nhất (Android giữ lịch sử sự kiện có hạn — quét sớm để không mất). Không cần chạy nền.
5. **Giờ ngủ trung bình** tính theo vòng tròn (đổi phút → góc, lấy trung bình vector) — trung bình cộng thường sẽ ra 12:00 cho 23:50 & 00:10.
6. **Quyền Android:** `PACKAGE_USAGE_STATS` mở bằng `Settings.ACTION_USAGE_ACCESS_SETTINGS`; kiểm lại quyền ở `didChangeAppLifecycleState(resumed)`. ⚠️ PO kiểm chính sách Play cho quyền này (phải có lời giải thích trong app = sheet C) + cập nhật khai báo An toàn dữ liệu & privacy policy. iOS: thêm HealthKit capability + `NSHealthShareUsageDescription` (text VI), chỉ xin đọc `sleepAnalysis`; cập nhật App Privacy trên ASC.
7. Cần plugin/kênh native cho UsageStats + HealthKit — Dev chọn (tránh thêm dep nếu viết kênh nhỏ được).
8. Nhóm Home "Hôm nay của chúng mình": thứ tự TodayRitual → Mood → **Sleep** → (phần còn lại giữ nguyên).

## Acceptance (design)
- [x] Mọi state có mô tả (A0–A5, L, E, S, M, P, F, D0)
- [x] Copy đủ VI + EN, xưng hô "bạn/người ấy"
- [x] Token sẵn có + bộ `personPalette` 8 màu mới (đã validate, ghi vào `design-system.md`), cỡ chữ trong type scale
- [x] Ô lịch đọc được không cần giải mã: ghi thẳng số giờ, có chú thích
- [x] Mỗi người tự chọn màu; cặp màu khó phân biệt bị khoá
- [x] Header màn con theo `SubScreenHeader` (chip giữa, không title)
- [x] Không phán xét: không tô màu cảnh báo cho đêm ngủ ít
- [x] Minh bạch khi sửa: nhãn "Đã sửa"/"Ghi tay" hai bên đều thấy, không lộ số gốc, chỉ sửa 7 đêm gần nhất (R1–R4)
- [ ] PO chốt overview (phạm vi Phase 1, chính sách store, privacy) trước khi Dev làm

## Ngoài phạm vi v1 (Phase 2 gợi ý)
- Push "Minh Anh vừa dậy ☀️" · nút "Rủ người ấy chia sẻ" · widget màn hình chính · lịch ngủ mục tiêu · đọc Health Connect trên Android.

## Nhật ký design
- [2026-10-10] [Designer] v3 **LỊCH TRĂNG** (user: số giờ "nhàm chán"; cài + dùng skill UI UX Pro Max, đọc `love_tree_screen.dart`/`mood_card.dart`): card bầu trời đêm lấy bảng màu + cách vẽ trăng của Cây Tình Yêu; mỗi đêm = trăng, pha theo số giờ (tròn = ngủ tròn giấc); 2 trăng/ô cho Cả hai; tim khi ngủ cùng lúc ≥ 7 tiếng; card Home + dòng chi tiết dùng trăng thay thanh/chấm; thống kê "đêm tròn giấc". Đã tính lại tương phản trên nền tối (đáy card tối hơn bản Cây Tình Yêu). Bản số giờ giữ làm phương án B.
- [2026-10-10] [Designer] User: "2 cây nến khiến tôi không hiểu" + "cho user chọn màu". Bỏ cột đôi trong ô lịch → **ghi thẳng số giờ** (Cả hai = 2 dòng có chấm màu; xem riêng = 1 số + nền tô 5 bậc). **Màu riêng mỗi người**: bộ 8 màu đã chạy validator, khoá 6 cặp khó phân biệt, màu người ấy + màu khoá mờ đi. Trạng thái giao diện (ô chọn, hôm nay, công tắc) chuyển sang navy; vùng "ngủ cùng lúc" + footer sang trung tính. Thêm state C1, 18 key copy, dev note 10, bộ màu vào `design-system.md`. Mockup: màn Giấc ngủ bấm đổi màu được, tweak `partnerColor`.
- [2026-10-10] [Designer] User chốt "cho sửa nhưng minh bạch": thêm mục Quyết định R1–R4 (nhãn Đã sửa/Ghi tay công khai cho cả người ấy · không lộ giờ gốc · chỉ sửa 7 đêm gần nhất · báo trước trong sheet sửa), bỏ nhãn cho đêm tự ghi, thêm state R + K, 2 key copy, dev note rules 8 ngày. Mockup cập nhật theo.
- [2026-10-10] [Designer] Dựng mockup tương tác 5 artboard (link ở đầu file) + vá độ tương phản theo mockup: thanh/làn người ấy đổi sang `accentLavenderDeep`; tên người = chữ `textSecondary` + chấm màu; segmented chọn = navy; mọi nút chính = navy (tim hồng trong nút); chữ thông tin bỏ `textTertiary`. Thêm 11 key copy (hộp gợi ý cấp quyền, xem trước khi chia sẻ, ghi chú sửa…).
- [2026-10-10] [Designer] Spec v1: card Home "Đêm qua" + màn lịch tháng 2 cột/ô (bạn rose · người ấy lavender, cao = thời lượng, shame-free) + chi tiết đêm dạng dòng thời gian 2 lane có dải "ngủ cùng lúc" + thống kê tháng + công tắc chia sẻ (mặc định tắt) + sheet cấp quyền/ghi tay/giải thích. Research khả thi: Android tự tính từ sự kiện màn hình (UsageStats, API 28+); iOS không có lịch sử khoá máy → đọc Apple Health. Toàn bộ token tái dùng, không thêm màu mới.

## [2026-10-12] [Lead] Điều chỉnh sau audit (thay Designer, chờ Designer soát lại)
- §B chi tiết đêm: giờ "23:45 → 6:55" xuống dòng riêng dưới tên (lùi 28), tên chiếm phần còn lại thay vì rộng cố định 64 — bố cục một hàng cũ cắt chữ từ 320dp@100%.
- Thẻ "Đêm qua": pill "Đã sửa"/"Giờ bên ấy" ra hàng riêng dưới trăng, rộng hết cột, tự thu nhỏ (tối thiểu ×0,75 — vi 320dp chữ 200% đo được ×0,78, chữ vẫn đọc đủ; Tester vòng 9 N2b) khi cột quá hẹp.
- Trục làn 18:00 → 14:00 (trước dừng 12:00 trong khi cửa sổ tính đêm tới 14:00).
- Đêm hiện theo đồng hồ nơi nó diễn ra; đêm người ấy ở múi khác có pill "Giờ bên ấy" (D2).

## Giờ thức giấc sau icon `!` (2026-10-31)
Hàng người: `tên · thời lượng · (!) · ✎`. Icon chỉ hiện khi đêm có lần thức. Bấm mở sheet: "Thức giấc 2 lần" · "3:10 · 5:40" · "Số giờ ngủ gồm cả những lần thức này." · nút Đã hiểu. Không thêm chữ giải thích trên màn chính.
