# Design system v2 — Dear Embeiu ("Ba làn")

> Designer, 2026-10-20. **Trạng thái: 📋 chờ user duyệt.** Tới khi user chốt, [`design-system.md`](design-system.md) (v1 "Sunset Romance") vẫn là nguồn sự thật; Dev KHÔNG đổi `lib/theme/` theo file này trước khi có lệnh.
> Làm bằng trọn run màn app của tasteskill (`references/app-screens.md` §2) + UI UX Pro Max. User chốt 2026-10-20: dùng tasteskill + UI UX Pro Max, "làm lại cả màu và phông" (không giữ hồng `#FF6B9D`, không giữ Quicksand).
> Sheet nguyên văn + lý do chọn + redraw: [`../docs/design/brand-v2/sheet.md`](../docs/design/brand-v2/sheet.md). Mockup bấm được: `docs/design/brand-v2/mock/home.html` (mở thẳng bằng trình duyệt).

---

## 1. Kiểm kê dữ liệu và việc (§2.1)

| Đối tượng | Trường, đơn vị | Độ lớn thật (PROD 2026-10-19 + cặp mẫu) | Ai mở, bao lâu một lần | Việc kế tiếp |
|---|---|---|---|---|
| Cặp đôi | 2 tên, ngày yêu, màu riêng mỗi người | 80 cặp: 28 đã ghép, 52 chờ người ấy | Cả hai, 1–5 lần/ngày, mỗi lần 10–60 giây | Mời người ấy (cặp chờ) |
| Số ngày bên nhau | ngày (chênh lệch lịch, không +1) | 1–3.650; cặp mẫu 1.255 (14/05/2023 → 20/10/2026) | Liếc mỗi lần mở | Không, đây là danh tính |
| Cột mốc | 100 · 365 · 520 · 1.000 · 1.314 · 1.825 · 3.650 | Cặp mẫu: đã qua 4, còn 59 ngày tới 1.314 | Thỉnh thoảng | Bật nhắc mốc |
| Câu hỏi hôm nay | câu hỏi vi/en, giờ trả lời từng người | 1 câu/ngày; chỉ 3–5 cặp/ngày cả hai trả lời | Hằng ngày | **Trả lời** (việc hay làm nhất) |
| Tâm trạng | 1 từ + ghi chú ≤100, giờ | 0–1/người/ngày | Hằng ngày | Chọn tâm trạng |
| Nhắn tin | số tin hôm nay, giờ tin cuối | 0–200/ngày | Nhiều lần/ngày | Mở Chat |
| Chòm sao | 6 sao = 2 người × (Câu hỏi · Tâm trạng · Nhắn tin) | 0–6 | Liếc | Mở Cây tình yêu |
| Chọc tim (`poke`) | lần/ngày mỗi chiều | 0–30/ngày | Nhiều lần/ngày, thường từ widget | **Chạm tim** (1 chạm) |
| Giấc ngủ | giờ ngủ–dậy, thời lượng | 4g–10g | Sáng | Xem chi tiết |
| Về đến nhà | nơi (Nhà/Chỗ làm/Trường), giờ, % pin | 1–3 sự kiện/ngày | Chiều tối | Báo đã đến |
| Thời tiết hai nơi | thành phố, °C, câu tình trạng | lệch 0–15° | Sáng | Nhắc mang ô |
| Phân vân (ăn gì/đi đâu/khác) | kết quả, ai chốt, giờ | 0–3/ngày | Trưa, tối | Quay, Ghi chi |
| Sổ chung (tiền) | đồng, theo tháng | Cặp mẫu: 9 khoản tháng 10 = 3.480.000đ | Sau bữa ăn | Ghi khoản |
| Trò chơi (oẳn tù tì, caro) | trạng thái ván, lượt, nước | 0–2 ván chờ | Vài lần/tuần | Vào chơi, Đi tiếp |
| Ảnh kỷ niệm | ảnh, chú thích, người đăng | cặp mẫu 142 ảnh | Vài lần/tuần | Thêm kỷ niệm |

Dữ liệu mẫu có assert: `docs/design/brand-v2/mock/data.js` (21 `console.assert`, gồm 1.255 ngày, 5 + 7 = 12 lần nhớ, 4/6 sao, 3.480.000đ = tổng 9 khoản, 142 ảnh = 6 + 136, chuỗi 23 ngày tính từ lịch sử 404 ngày đã trả lời, mốc 1.314 rơi ngày 18/12/2026).

**Thứ riêng của sản phẩm:** tên hai người, ngày yêu, ảnh của hai người, màu riêng mỗi người (`person_palette.dart`), con số "ngày bên nhau", câu hỏi viết bằng tiếng Việt, chòm sao 6 sao.

## 2. Câu hỏi của Home, phát hiện, việc một chạm (§2.2)

- **Câu hỏi một dòng:** *"Hôm nay của chúng mình tới đâu rồi: người ấy ra sao, còn việc gì chờ mình?"*
- **Khối lớn nhất trả lời nó:** bảng "Hôm nay" ba làn (§4). Số lớn nhất màn (1.255 trong h1) trả lời câu trong h1.
- **Một phát hiện (one finding)**, đặt ngay dưới h1, sinh từ dữ liệu: "Thảo trả lời câu hỏi hôm nay từ 08:12, đang chờ mình." Thứ tự ưu tiên khi chọn câu: (1) người ấy đã trả lời, mình chưa → (2) đến lượt mình ở caro / người ấy rủ chơi → (3) người ấy vừa về đến nhà → (4) người ấy nhớ mình ≥ 3 lần → (5) không có gì: "Hôm nay chưa ai làm gì, bắt đầu bằng câu hỏi nhé."
- **Việc hay làm nhất cách một chạm:** nút "Trả lời" (nút chính duy nhất, mực đen) nằm ở hàng câu hỏi, lọt màn hình đầu ở 390×844. Việc thứ hai, chạm tim, cũng một chạm (nút tròn nhấn màu ở hàng "Nhớ nhau").

## 3. Style, mặt, chữ ký (§2.3)

- **Style:** `editorial-greeting` · seed **665763129** · kind `workspace` · light. Move: lời chào là h1; mọi con số ở weight thường; panel tông xám một lớp, không viền, không bóng.
- **Mặt (face) đã chọn:** *lời chào gọi tên cả hai và nói sự thật của hôm nay, sinh từ dữ liệu*: "Tuấn và Thảo, / 1.255 ngày bên nhau" (Newsreader 28). Không "Chào mừng trở lại", không emoji. Hai máy thấy cùng một h1.
- **Chữ ký (signature element):** **cặp đôi là ba làn** — người ấy (trái) · chúng mình (giữa) · mình (phải). Mỗi hàng là một việc trong ngày; làn giữa ghi tên việc và giữ thứ hai người làm chung (nút chạm tim, "Nhắc mang ô"). Một khối này gộp 6 thẻ cũ/mới (câu hỏi, tâm trạng, nhắn tin, chạm tim, giấc ngủ, về đến nhà, thời tiết) nên Home ngắn đi dù thêm 5 feature.
- **Hue duy nhất trên dữ liệu chính:** thanh tiến tới mốc + nút chạm tim + chấm "đến lượt mình". Đo trên ảnh chụp: dưới 2% điểm ảnh.

---

## 4. Token màu

Một nền, một mực, một nhấn. Màu nằm trên dữ liệu và một control, không trên chrome.

| Token (Flutter `AppColorsV2`) | Hex | Vai trò | Tương phản |
|---|---|---|---|
| `ground` | `#FFFFFF` | Nền mọi màn, thanh trên, thanh tab | — |
| `surface` | `#F9F9F9` | Panel (một bậc tông lệch nền) | — |
| `raised` | `#FFFFFF` | Nút phụ, ô nhập, sheet | — |
| `active` | `#EDEDEB` | Trạng thái nhấn, thanh tiến trình nền, skeleton | — |
| `border` | `#EAEAEA` | Viền thanh tab, ô nhập trên nền trắng | 1.20:1 trên trắng (đúng dải 1.1–1.3) |
| `rule` | `#ECECEA` | Kẻ hàng trong panel | — |
| `control` | `#D9D9D6` | Viền nút phụ, viền ô nhập | 1.41:1 |
| `text` | `#1F201D` | Mực chính, nút chính | 16.37:1 trắng · 15.55:1 surface |
| `muted` | `#636361` | Nhãn, dòng phụ, icon | 6.02:1 trắng · 5.72:1 surface |
| `accent` | `#1B6E66` | Nút chạm tim, tiến tới mốc, chấm "đến lượt mình", link "Nhắc mang ô", vòng focus | 6.05:1 trắng · 5.75:1 surface · chữ trắng trên accent 6.05:1 |
| `primary` / `onPrimary` | `#1F201D` / `#FFFFFF` | Nút chính (mỗi màn tối đa 1) | 16.37:1 |
| `negative` | `#B42318` | Lỗi, số đếm badge chưa đọc | 6.24:1 surface |
| `warningBg` / `warningInk` | `#FFFBEB` / `#92400E` | Dải "Đang mất mạng" | 6.84:1 |
| `pillNeutralBg` / `Ink` | `#EFEFED` / `#3D3D3A` | Nhãn trạng thái trung tính | — |
| `positive` | `= accent` | Không có xanh lá thứ hai (accent là xanh mòng két, thêm xanh lá sẽ thành 2 màu xanh) | — |

**Không còn:** mọi gradient (`sunsetRomance`, `dawnBlush`, `dreamyMint`), `accentLove #FF4D6D` làm nhấn, `accentLavender` (tím bị cấm làm nhấn), `softCardShadow`.

### 4.1 Màu riêng mỗi người (giữ `person_palette.dart`, đổi cách dùng)

Màu riêng là **danh tính, không phải dữ liệu**: chỉ lên avatar (đĩa 28, nền tint 12%, chữ = hue × 0.62) và đầu làn. Không tô cả làn, không lên chú giải biểu đồ.

| id | hue | tint (12%) | mực trên tint | tỉ lệ |
|---|---|---|---|---|
| rose | `#FF4D6D` | `#FFEAED` | `#9E3044` | 6.16 |
| purple | `#7C5CD6` | `#EFEBFA` | `#4D3985` | 8.01 |
| blue | `#1C7ED6` | `#E4F0FA` | `#114E85` | 7.40 |
| teal | `#0E9384` | `#E2F2F0` | `#095B52` | 6.92 |
| orange | `#E8590C` | `#FCEBE2` | `#903707` | 6.62 |
| green | `#2F9E44` | `#E6F3E9` | `#1D622A` | 6.48 |
| magenta | `#C2255C` | `#F8E5EB` | `#781739` | 8.79 |
| amber | `#B7791F` | `#F6EFE4` | `#714B13` | 6.76 |

Riêng màn Giấc ngủ (lịch trăng, 2 làn) vẫn dùng hue đầy đủ cho dữ liệu của từng người, như v1. Lưu ý: `teal #0E9384` gần nhấn `#1B6E66`; khi một người chọn teal, mọi chỗ nhấn đứng cạnh dữ liệu của người đó phải dùng mực `text` thay accent (xem câu hỏi Q3).

## 5. Phông

| | Hanken Grotesk (chữ) | Newsreader (chỉ lời chào h1 + câu hỏi hôm nay) |
|---|---|---|
| Nguồn | `github.com/google/fonts/ofl/hankengrotesk` (`HankenGrotesk[wght].ttf`) | `github.com/google/fonts/ofl/newsreader` (`Newsreader[opsz,wght].ttf`) |
| License | SIL OFL 1.1 (nhúng app được, kèm `OFL.txt`) | SIL OFL 1.1 |
| Tiếng Việt (fontTools, file thật) | **146/146**: ă â đ ê ô ơ ư + mọi tổ hợp dấu, cả hoa lẫn thường | **146/146** |
| Chữ số | Mặc định đều độ rộng (0–9 cùng 560) | Có `tnum` |
| Weight cần bundle | 400, 500, 600 (cắt static) | 400 (cắt static `opsz=28`) |

Bundle offline ở `assets/fonts/` (bài học 2026-06-06: tải mạng thì nháy font, vỡ dấu). Cắt static bằng `fonttools varLib.instancer` (ví dụ `HankenGrotesk[wght].ttf wght=500`) rồi chạy lại kiểm 146 ký tự trên từng file cắt ra. Instrument Sans/Serif (sheet chia) **bị loại** vì chỉ có 50/146 ký tự tiếng Việt (xem sheet.md §4).

### 5.1 Thang chữ (5 cỡ, không thêm)

| Vai trò | Cỡ / line-height (Flutter `height`) | Weight | Tracking | Phông |
|---|---|---|---|---|
| Lời chào h1, tên màn | 28 / 34 (1.214) | 400 | −0.01em (−0.28) | Newsreader |
| Số trong làn, số tiền, câu hỏi hôm nay | 20 / 24 (1.2) · câu hỏi 20 / 28 (1.4) | 400 | 0 | Hanken (số) · Newsreader (câu hỏi) |
| Chữ, tên hàng, giá trị chữ trong làn | 16 / 24 (1.5) · trong làn 16 / 22 | 400 · 500 · tiêu đề panel 600 | 0 | Hanken |
| Nhãn, nút, link, dòng phụ | 14 / 20 (1.43) | 400 · nút/link 600 | 0 | Hanken |
| Meta, giờ, nhãn tab | 12 / 16 (1.33) | 400 · tab 500/600 | 0 | Hanken |

Không dưới 12. Không chữ hoa giãn chữ. Mọi số dùng `FontFeature.tabularFigures()`. Line-height ≥ 1.2 ở mọi cỡ để dấu chồng (Ấ, Ể, Ữ) không chạm dòng trên. Hỗ trợ cỡ chữ hệ thống bằng `MediaQuery.textScalerOf` (UI UX Pro Max, flutter, High).

## 6. Lưới, lề, bo góc, viền và bóng

- **Lưới điện thoại 390:** lề 16 | nội dung 358 | panel pad 16 → trong panel 326 = làn 108 + giữa 110 + làn 108. Một khoảng cách duy nhất: **16** (giữa panel, giữa lề). Bước 4: 4 · 8 · 12 · 16 · 24.
- **Bo góc (quyết một lần, kiểu "mềm"):** panel và ảnh lớn **22** · ảnh nhỏ, ô bên trong **12** · nút, chip, ô nhập **999** (pill) · avatar tròn. Không dùng 11–12 cho panel, không dùng 28 nữa.
- **Viền hay bóng:** panel **không viền, không bóng**, tách nền bằng một bậc tông (`surface` trên `ground`). Viền 1px chỉ cho nút phụ, ô nhập, thanh tab. **Bóng chỉ cho thứ nổi:** bottom sheet, dialog, menu (`0 8 24 rgba(0,0,0,.12)`).

## 7. Component

| Component | Spec v2 |
|---|---|
| **Thanh trên** | Cao 48 dưới status bar, nền `ground`. Trái: dấu hiệu 24 + "Dear Embeiu" 14/600. Phải: tối đa 1 hành động (chuông có số chưa đọc ở Home, bánh răng ở Hồ sơ), vùng chạm 44. Màn con: nút ← 44 + tên màn 16/600 (thay `SubScreenHeader` chỉ có chip). |
| **Tiêu đề màn (title row)** | h1 Newsreader 28/400, ≤ 2 dòng (tác giả tự ngắt dòng, không để số tách khỏi danh từ của nó). Dòng phụ 14 `muted` (ngày, mốc). Dòng phát hiện 16 `text`, một câu. |
| **Thanh tab dưới** | 4 mục Trang chủ · Trò chuyện · Kỷ niệm · Hồ sơ, cao 56 + vùng an toàn, nền trắng, viền trên 1px `border`. Icon nét 20 + nhãn 12. Mục đang chọn: icon + nhãn đổi sang `text`, nhãn 600; không pill màu, không nền nổi. Số đếm đỏ chỉ trên Trò chuyện (tin chưa đọc). Bỏ thanh nổi bo pill + blur. Vào Chat vẫn ẩn thanh tab (drill-in, giữ hành vi 2026-06-17). |
| **Panel** | `surface`, r22, pad 16, không viền/bóng. Đầu panel: tiêu đề 16/600 trái, meta 14 `muted` hoặc link 14/600 phải, cùng baseline. |
| **Ba làn** (chữ ký) | Lưới `1fr 110 1fr`. Đầu làn: avatar 28 + tên 14/600 + "n sao" 14 `muted`; làn mình căn phải. Hàng cao ≥ 64, kẻ 1px `rule` giữa hàng. Làn trái căn trái, làn phải căn phải, làn giữa căn giữa: nhãn việc 14 `muted` + (nếu có) thứ làm chung. Giá trị số 20/400, giá trị chữ 16/500, dòng phụ 12 `muted`. Việc của mình còn trống → nút ở làn mình (chính: "Trả lời"; phụ: "Chọn"). Thiếu dữ liệu → "—" `muted` ở cỡ 16, không ở cỡ số. |
| **Nút** | Pill, cao 44 (nhỏ 36 trong hàng, vùng chạm vẫn 44 nhờ padding hàng). Chính: nền `text`, chữ trắng 14/600, **mỗi màn 1**. Phụ: nền trắng + viền `control`. Text action: 14/600 `text`, cao 44. Disabled: nền `active` + chữ `muted` (4.5:1) + lý do bằng chữ. Không gradient, không bóng. |
| **Nút chạm tim** | Tròn 44, nền `accent`, tim đặc trắng 20. Nhấn: scale 0.92 trong 120ms + rung nhẹ. Dưới nút: "12 lần hôm nay" 12 `muted`. |
| **Hàng danh sách** | Cao ≥ 64, tên 16/500 + dòng phụ 14 `muted`; một hành động cố định bên phải (nút nhỏ) hoặc chevron 16 `muted`. Kẻ 1px `rule` giữa hàng, không kẻ trên hàng đầu. Chấm 8 `accent` trước dòng phụ = cần mình làm. |
| **Pill / nhãn trạng thái** | Cao 22, chữ 12/500, nền tint nhạt + mực đậm cùng hue. Chỉ trong hàng, không bao giờ trên tiêu đề. Bỏ `EyebrowChip`. |
| **Ô nhập** | Nhãn 14/500 phía trên, cách 8. Ô cao 44, nền trắng, viền 1px `control`, r12 (ô nhiều dòng) hoặc 999 (một dòng trong thanh soạn chat). Lỗi: câu 14 `negative` ngay dưới ô. |
| **Bottom sheet** | Nền trắng, góc trên r22, tay nắm 36×4 `control`, bóng nổi. Tiêu đề 16/600, một nút chính ở đáy. Thay mọi sheet `cardSurface` blur. |
| **Dialog** | Trắng, r22, pad 24, tiêu đề 16/600, thân 16, 2 nút phải (phụ text, chính pill). Hành động xoá: chữ `negative`, nêu đúng tên thứ bị xoá. |
| **Trống** | Giữ khung và tiêu đề panel, một câu nói việc kế + một nút ("Chưa ghi khoản nào tháng này" · Ghi khoản). Không minh hoạ, không Lottie trong khối trống. |
| **Đang tải** | Bố cục cuối cùng, mỗi giá trị là thanh xám `active` đúng cỡ (số 20 → thanh 20), nhãn hiện ngay, **không shimmer**. Bỏ `ShimmerSkeleton` gradient. |
| **Lỗi** | Trong đúng hàng/khối hỏng: "Chưa lấy được thời tiết. Lần cuối đúng lúc 09:40." + "Thử lại". Không banner toàn màn. |
| **Mất mạng** | Dải `warningBg` trong khối: "Đang mất mạng. Số liệu lúc 11:58, có mạng sẽ tự cập nhật." Hành động xếp hàng ghi "sẽ gửi khi có mạng". |
| **Biểu đồ** | Một màu một biểu đồ; dữ liệu chính `accent`, so sánh xám. Không gradient vùng, không đường cong làm mượt, lưới 3–5 vạch `#E5E5E5`. Thanh tiến độ cao 6, hai đầu có nhãn ("mốc 1.000" · "còn 59 ngày tới mốc 1.314"), phần đầy đúng tỉ lệ thật. |
| **Icon** | Iconsax **Linear** 20 (nav, thanh trên), 16 (chevron, trong hàng), màu `muted`. Bỏ `IconsaxPlusBold` cho nav đang chọn (đổi màu là đủ). Không icon trong ô màu (`IconBadge` bỏ). Không emoji trong nhãn, nav, trống. Emoji chỉ còn là nội dung người dùng gõ (chat, chú thích). |
| **Motion (chỉ là phản hồi)** | Nhấn 120ms, mở sheet/dialog 200ms `Curves.easeOutCubic`, hàng mới xuất hiện 200ms fade. **Không** animation vào màn (bỏ `EntranceReveal`, `flutter_animate` stagger), không tim đập liên tục. Reduce Motion: chỉ đổi giá trị. |

## 8. Home v2: thứ tự khối và điểm vào của đợt mới

| # | Khối | Nội dung | Gộp gì |
|---|---|---|---|
| 0 | Thanh trên | Dấu hiệu + "Dear Embeiu" · chuông (3) | Nút 💌 Quan tâm ở header **chuyển xuống** chân khối "Hôm nay" |
| 1 | Tiêu đề | h1 "Tuấn và Thảo, / 1.255 ngày bên nhau" · "Thứ Ba, 20/10 · từ 14/05/2023 · chuỗi 23 ngày" · câu phát hiện | Lời chào theo giờ trong chip + `StreakChip` |
| 2 | Ảnh của chúng mình | Ảnh nền đã chọn, 21:9, r22, **không chữ đè lên ảnh**; dưới: thanh tiến "mốc 1.000 … còn 59 ngày tới mốc 1.314". Vuốt ←/→ đổi ảnh như cũ | `CounterCard` (aurora gradient, đồng hồ giờ/phút/giây, tim đập) |
| 3 | **Hôm nay** (ba làn) | Đầu: "4/6 sao · Cây tình yêu". Hàng: Câu hỏi hôm nay (câu hỏi Newsreader 20 + Đã trả lời / [Trả lời]) · Tâm trạng · Nhắn tin · **Nhớ nhau** (poke: 5 lần · [tim] 12 lần hôm nay · 7 lần) · Đêm qua · **Ở đâu** (arrival: "Đến chỗ làm · 08:05 · pin 64%" / "Ở nhà · Báo đã đến") · **Thời tiết** (31° TP.HCM Chiều nay mưa · "Nhắc mang ô" · 24° Hà Nội). Chân: "Gửi lời quan tâm" | `TodayRitualCard`, `MoodCard`, `SleepCard`, `ConstellationPill`, nút Quan tâm; **thẻ thời tiết, thẻ về đến nhà, tim chọc** (3 feature mới) không thành thẻ riêng |
| 4 | Chơi cùng nhau | 2 hàng: Oẳn tù tì · Cờ caro, mỗi hàng 1 câu trạng thái + 1 nút; meta "2 ván chờ mình" | `RpsInviteCard` + **caro** (đúng D15 caro-game) |
| 5 | Phân vân gì không? | 3 hàng (ăn gì · đi đâu · khác); có kết quả thì thêm nút "Ghi chi" | `DecisionCard` |
| 6 | Sổ chung tháng này | **Một hàng**: "3.480.000đ" + "hôm nay 120.000đ" + [Ghi khoản]. Chỉ số của sổ chung, không bao giờ số của sổ riêng người ấy | **Quỹ chung / quản lý tiền** (lối vào duy nhất trên Home) |
| 7 | Kỷ niệm gần đây | 3 ảnh vuông r12 + "Thêm kỷ niệm" + link "Xem cả 142 ảnh" | `MemoryCinemaCard`, ô "Thêm kỷ niệm" |
| 8 | Thanh tab | 4 tab | Thanh nổi blur |

Lý do thứ tự: khối trả lời câu hỏi của Home lên trước; khối có việc đang chờ (ván chờ lượt) đứng trước khối danh sách dài; tiền và ảnh là việc "khi cần". Đo trên mockup: **Home v2 cao ~2.9 màn** (390×844) dù có thêm 5 feature; Home v1 hiện tại (chưa có 5 feature) đã dài hơn vì mỗi thứ là một thẻ riêng.

**Quy tắc cho feature sau:** việc của *từng người trong ngày* → thêm **một hàng** vào ba làn (tối đa 9 hàng; quá thì gộp). Việc *hai người làm chung* → một hàng trong panel đã có. Không thêm thẻ mới vào Home nếu chưa qua Designer.

**Cặp đang chờ người ấy** (`mock/home-waiting.html`): h1 vẫn gọi tên cả hai + số ngày; câu phát hiện "Ngọc chưa vào app. Còn 2 bước nữa là hai máy nối với nhau."; panel "Mời Ngọc vào" 3 bước đánh số thật (1/3 đã xong, mã + Mã QR + Sao chép) thay banner checklist; ba làn còn khung, làn người ấy là "—" (meta "làn của Ngọc trống"), không có Nhớ nhau, Ở đâu, Chơi cùng nhau, Sổ chung.

**Trạng thái từng khối** (`mock/home-states.html`): đang tải, ngày mới 00:05 (số 0 in ra "0 lần", chưa có thì "—"), lỗi một nguồn trong đúng hàng, mất mạng (giữ số cũ + giờ, chạm tim "sẽ gửi khi có mạng"), chưa chọn thành phố / người ấy chưa bật báo về nhà, trò chơi trống, sổ trống, sổ lỗi.

### 8.1 Copy Home v2 (vi · en)

| Key đề xuất | vi | en |
|---|---|---|
| `homeV2Title` | {me} và {partner},⏎{days} ngày bên nhau | {me} and {partner},⏎{days} days together |
| `homeV2Sub` | {weekday}, {date} · từ {start} · chuỗi {streak} ngày | {weekday}, {date} · since {start} · {streak}-day streak |
| `homeFindingPartnerAnswered` | {partner} trả lời câu hỏi hôm nay từ {time}, đang chờ mình. | {partner} answered today's question at {time}. Your turn. |
| `homeFindingNothing` | Hôm nay chưa ai làm gì, bắt đầu bằng câu hỏi nhé. | Nothing yet today. Start with the question. |
| `homeMilestoneTrack` | mốc {prev} · còn {n} ngày tới mốc {next} | {prev} days · {n} days to {next} |
| `todayBoardTitle` | Hôm nay | Today |
| `todayStars` | {n}/6 sao · Cây tình yêu | {n}/6 stars · Love tree |
| `laneMe` | Mình | Me |
| `laneStars` | {n} sao | {n} stars |
| `rowQuestion` · `rowMood` · `rowChat` · `rowMiss` · `rowSleep` · `rowWhere` · `rowWeather` | Câu hỏi hôm nay · Tâm trạng · Nhắn tin · Nhớ nhau · Đêm qua · Ở đâu · Thời tiết | Today's question · Mood · Messages · Missing you · Last night · Where · Weather |
| `pokeTotalToday` | {n} lần hôm nay | {n} today |
| `pokeTheyMissMe` / `pokeIMiss` | nhớ mình / mình nhớ {partner} | misses you / you miss {partner} |
| `remindUmbrella` | Nhắc mang ô | Remind umbrella |
| `reportArrived` | Báo đã đến | I've arrived |
| `boardFootCare` | Muốn nói gì đó dài hơn? · Gửi lời quan tâm | Something longer to say? · Send a note |
| `gamesTitle` / `gamesWaiting` | Chơi cùng nhau / {n} ván chờ mình | Play together / {n} waiting on you |
| `moneyMonthShared` / `moneyToday` / `moneyAdd` | Sổ chung tháng này / hôm nay {amount} / Ghi khoản | Shared this month / {amount} today / Add |
| `memoriesSeeAll` | Xem cả {n} ảnh | See all {n} photos |
| `stateOffline` | Đang mất mạng. Số liệu lúc {time}, có mạng sẽ tự cập nhật. | You're offline. Showing {time}; updates when you're back. |
| `stateQueued` | sẽ gửi khi có mạng | sends when you're online |
| `stateRowError` | Chưa lấy được {thing}. Lần cuối đúng lúc {time}. · Thử lại | Couldn't load {thing}. Last updated {time}. · Retry |

(⏎ = xuống dòng do tác giả đặt, để số không tách khỏi "ngày". Copy tiếng Việt cần chạy humanizer, tiếng Anh thêm avoid-ai-writing trước khi vào ARB — việc của PO/Dev khi làm.)

## 9. Hồ sơ v2 (`mock/profile.html`)

Thanh trên (bánh răng) → h1 "Tuấn và Thảo" + "Bên nhau từ 14/05/2023 · 1.255 ngày" + hai avatar màu riêng + mã ghép đôi → panel **Cột mốc** (dải 7 trạm, vạch "hôm nay" màu nhấn nội suy giữa 1.000 và 1.314, nhãn chỉ ở 100 · 1.000 · 1.314 · 3.650 để không chồng chữ, câu "Còn 59 ngày tới mốc 1.314, ngày 18/12/2026.") → panel **Thành tích** (một khối chia 2×2 bằng kẻ 1px: chuỗi hiện tại 23 · dài nhất 62 · kỷ niệm 142 ảnh · câu hỏi 404 ngày; số 20/400 + đơn vị 14 xám; không ô màu, không icon) → panel **Của chúng mình** (5 hàng chevron: Gửi lời quan tâm · Dòng thời gian quan tâm 36 · Sổ chung · Cột mốc và lời nhắc 5 đang bật · Nhật ký câu hỏi 404).

## 10. Widget màn hình chính, icon app, splash

- **Dấu hiệu (mark):** hai vòng tròn nét mực lồng nhau, phần giao tô `accent` = "phần chung" của hai người (cùng ý ba làn). Vẽ SVG, không glyph tim.
- **Icon app:** nền trắng `#FFFFFF`, dấu hiệu mực `#1F201D` + giao `#1B6E66`, không gradient. Android adaptive: nền trắng phẳng. iOS flatten như cũ. Store icon 512 vẽ lại. (Đổi icon = người dùng thấy ngay trên màn hình chính; cần user chốt.)
- **Splash:** nền `#FFFFFF` + dấu hiệu giữa màn (thay nền `#E8B4D8` + tim trắng). ⚠️ `flutter_native_splash:create` vẫn xoá `screenOrientation` trong manifest (CLAUDE.md §3).
- **Widget:** có ảnh → giữ ảnh + scrim trung tính đen 0→55% (ngoại lệ duy nhất cho gradient: scrim dưới chữ trên ảnh) + chữ trắng. Không ảnh → **bỏ nền "trời đêm" navy M2**, dùng `surface #F9F9F9`, số ngày Hanken 400 mực `text`, dòng trạng thái widget-today 12 `muted`, nút tim tròn `accent`. Bản tối (iOS tinted/Android dark launcher) dùng nền trung tính `#111111`, không navy. Android RemoteViews không nạp được font asset ⇒ Roboto như cũ; iOS dùng Hanken.

---

## 11. Đổi từ v1 sang v2

Công sức: S ≤ ½ ngày · M 1–3 ngày · L ≥ 1 tuần (một Dev). Đếm theo `lib/` hiện tại (98.9k dòng, 33 màn).

| v1 đang dùng (tasteskill cấm/không hợp) | Đếm trong `lib/` | Thay bằng | Công | Rủi ro |
|---|---|---|---|---|
| Nền gradient `dawnBlush` (vẽ ở shell Home + mọi màn con) | 35 chỗ / 29 file | `ground #FFFFFF` phẳng | M | Thấp; cần soát chữ trắng đang đặt trên nền hồng |
| Hero `sunsetRomance` (CounterCard "aurora", nút, chip) | 21 / 11 | Ảnh 21:9 + h1 Newsreader + thanh tiến mốc | M | Trung bình: CounterCard là "mặt" app; đồng hồ giờ/phút/giây bỏ (Q2) |
| `dreamyMint` | 5 / 3 | `surface` | S | Thấp |
| `LinearGradient(` khác | 40 / 17 | Màu phẳng; chỉ giữ scrim trên ảnh | M | Thấp |
| `GlassCard` / `BackdropFilter` (blur thật, form auth, nav, overlay, sheet) | 12 / 8 · 13 / 10 | Panel `surface` hoặc sheet trắng có bóng nổi | M | Trung bình: form auth/landing cần sắp lại |
| Thanh tab nổi bo pill + blur | 1 (`home_screen`) | Thanh tab phẳng 56 + viền trên | S | Thấp; giữ logic ẩn khi vào Chat |
| `EyebrowChip` / `SubScreenHeader` chỉ có chip | 26 / 18 · 33 / 23 | Thanh trên: ← + tên màn 16/600; tab gốc: h1 Newsreader | M | Trung bình: đổi 1 widget là 23 màn đổi theo, phải soát chữ dài |
| `IconBadge` (icon trong ô màu) | 20 / 10 | Icon nét 16–20 xám không khung, hoặc bỏ | S | Thấp |
| `ContentCard` (trắng r24 + bóng đen .06) | 48 / 26 | Panel `surface` r22 không bóng | S (đổi trong widget) | Thấp |
| `BoxShadow(` / `softCardShadow` khác | 52 / 28 · 8 / 4 | Bỏ; bóng chỉ cho sheet/dialog/menu | M | Thấp |
| `accentLove #FF4D6D` làm nhấn | 242 / 52 | `accent #1B6E66` cho dữ liệu chính + 1 control; còn lại `text`/`muted` | L | **Cao**: dùng dày nhất; nhiều chỗ là tim/nút, phải quyết từng chỗ là "dữ liệu" hay "chrome" |
| `accentLavender` (tím) | 50 / 22 | `muted` hoặc màu riêng người ấy | M | Trung bình |
| Emoji trong nhãn: tâm trạng, danh mục chi, kết quả quay, 💌, "Có gì mới" | rải rác (`MoodGlyph` fallback emoji, ARB) | Chữ ("Hơi mệt", "Ăn uống"); emoji chỉ còn khi người dùng tự gõ | M | Trung bình: đụng ARB vi+en, Lottie tâm trạng có thể giữ trong màn chi tiết |
| Trời đêm navy của Cây tình yêu + widget M2 | `love_tree_screen`, `today_constellation`, widget iOS/Android | Tranh vẽ nền trung tính `#111111`, sao trắng, cành mực; widget không ảnh = `surface` | M (app) + M (widget 2 nền tảng) | Trung bình: user từng chốt M2 (2026-10-12) ⇒ cần hỏi lại (Q4) |
| `ShimmerSkeleton` (shimmer gradient) | 48 / 20 | Thanh xám tĩnh đúng cỡ | S | Thấp |
| `EntranceReveal` + `flutter_animate` stagger, tim đập liên tục | 27 / 9 | Không animation vào màn; chỉ phản hồi | S | Thấp; gỡ được package `flutter_animate`, `shimmer`, `confetti` (chưa dùng) |
| Quicksand (phông toàn app) | `AppTheme.fontFamily` | Hanken Grotesk + Newsreader (h1, câu hỏi) | S (đổi hằng + bundle) + M (soát tràn chữ) | Trung bình: Hanken rộng hơn Quicksand, nút/hàng chật có thể xuống dòng |
| Thang cỡ v1 (12/13/14/15/16/18/20/21/22/24/28/32…) | toàn `app_theme.dart` | 5 cỡ 28/20/16/14/12 | M | Trung bình: phải soát từng màn |
| Bo góc 28/24/20 trộn | nhiều | 22 · 12 · 999 | S | Thấp |
| `IconsaxPlusBold` cho nav đang chọn | `home_screen` | Linear + đổi màu | S | Thấp |
| Nút Apple/Google (pill h52, chữ 15) | `social_sign_in_buttons` | **Giữ khuôn theo guideline Apple HIG / Google branding** (màu, logo, cao 52, chữ 15); chỉ đổi phông nhãn sang Hanken. Nút Email thành nút phụ v2 | S | Thấp; không đổi màu/logo của Apple, Google |
| Icon app + splash hồng | `assets/branding/`, `flutter_launcher_icons`, `flutter_native_splash` | Dấu hiệu hai vòng trên nền trắng | M | **Cao về thương hiệu**: người dùng cũ tìm app bằng icon hồng; store listing, feature graphic, ảnh chụp store phải làm lại |

**Ước lượng cả app:** khoảng **15–20 ngày công Dev** (token + theme S/M ≈ 2 ngày; primitive dùng chung ≈ 3 ngày; Home + 4 tab ≈ 4 ngày; ~28 màn con + sheet ≈ 5–7 ngày; widget 2 nền tảng + icon + splash + ảnh store ≈ 3 ngày; soát chữ dài vi/en + Tester ≈ 2 ngày). Làm theo thứ tự: token → primitive (`ContentCard`, `SubScreenHeader`, `SectionHeader`, `InkTile`, nút) → Home → các tab → màn con → widget/icon. Có thể phát hành theo 2 đợt (đợt 1: token + primitive + Home + tab; đợt 2: màn con + icon) nhưng giữa hai đợt app sẽ trộn hai ngôn ngữ ⇒ đề xuất một bản duy nhất.

---

## 12. Soát UX (UI UX Pro Max 2.13.0)

Đã đọc `SKILL.md` + `references/pro-rules.md` (Pre-Delivery Checklist). Truy vấn và kết luận:

| Truy vấn | Kết quả | Áp vào v2 |
|---|---|---|
| `"bottom navigation tabs labels" --stack flutter` | 0 kết quả (gợi ý: tab, navigator) | Thử lại ↓ |
| `"tab navigator" --stack flutter` | GoRouter / named routes (Medium/Low) | Không đổi kiến trúc điều hướng trong đợt này; chỉ đổi giao diện thanh tab |
| `quick-reference.md` `bottom-nav-limit`, `nav-label-icon`, `bottom-nav-top-level` | ≤ 5 mục, icon **kèm nhãn**, chỉ cho màn gốc | 4 tab có nhãn 12; Chat drill-in giữ ẩn thanh |
| `"text scale accessibility" --stack flutter` | `MediaQuery.textScalerOf`, `Semantics` (High) | Thang 5 cỡ phải co giãn theo cỡ chữ hệ thống; nút chạm tim có `Semantics(label: "Chạm tim: báo Thảo là mình đang nhớ")` |
| `"theme color scheme" --stack flutter` | `ThemeData`, đọc qua `Theme.of(context)`, không hex rải rác; "Support dark mode" | Token vào `AppColorsV2` + `ThemeData`; dark mode **chưa** làm (ghi Q5) |
| `"font asset bundle"`, `"safe area padding"` --stack flutter | 0 kết quả | Rơi về `pro-rules.md`: tôn trọng vùng an toàn trên/dưới cho thanh trên và thanh tab (mockup để 47 trên, 34 dưới) |
| `"touch target size" --domain ux` | 44pt iOS / 48dp Android (High) | Mọi nút, icon, link ≥ 44 cao; trên Android dùng vùng chạm 48 (`materialTapTargetSize.padded`) |
| `"bottom navigation limit" --domain ux` | Thanh cố định không được che nội dung | `canvas` chừa đáy = 56 + vùng an toàn + 40 |
| `"color contrast text" --domain ux` | ≥ 4.5:1 chữ thường (High) | Mọi tầng chữ ≥ 5.7:1 (bảng §4); không dùng xám nhạt hơn `#636361` cho chữ |
| `"line height diacritics" --domain ux` | Body 1.5–1.75; tiêu đề ngắt dòng cân bằng, thử với nhiều locale | Body 16/24 = 1.5; h1 tác giả tự ngắt; line-height ≥ 1.2 cho dấu chồng tiếng Việt |
| `"loading skeleton state" --domain ux` | Phản hồi tải theo thời gian chờ, giữ bố cục (High) | Skeleton tĩnh đúng cỡ, không nháy với thao tác gần tức thì |
| `"reduced motion" --domain ux` | Tôn trọng giảm chuyển động; 1–2 chuyển động mỗi màn | Không animation vào màn; tim bay ≤ 1 giây chỉ khi người ấy chạm tim lúc đang mở app |
| `"vietnamese sans" --domain typography` | Be Vietnam Pro + Noto Sans | Không dùng (là nhận diện cũ, user muốn đổi); Hanken/Newsreader đã kiểm đủ 146 ký tự |
| `"couple relationship app" --domain color` | Primary `#BE185D` rose + đỏ tình yêu, nền `#FDF2F8` | **Không áp**: user đã bỏ hồng; tasteskill: đỏ/hồng-đỏ làm nhấn đọc như báo động. Ghi lại để user thấy hướng "mặc định của ngành" mà v2 cố ý tránh |
| `pro-rules.md` Pre-Delivery | Không emoji làm icon · icon một bộ một nét 1.5 · nhấn có phản hồi 80–150ms · disabled rõ ràng · vùng an toàn | Đạt trong mockup: icon nét 1.5, nhấn 120ms, disabled có lý do bằng chữ |

**Soát chung thành phần đứng cạnh nhau:** (a) 4 tab cùng một khuôn (icon 20 + nhãn 12, chọn = đổi màu); (b) các nút trong cùng hàng đều cao 36 (vùng chạm 64 của hàng), nút chính duy nhất "Trả lời"; (c) nút Apple/Google trên landing giữ guideline bên thứ ba (Apple HIG: đen/trắng/viền, logo chính thức; Google branding: viền `#747775`, chữ `#1F1F1F`), không đổi sang màu v2.

## 13. Kiểm (§2.7)

App chỉ chạy trên điện thoại ⇒ inspector chạy `--widths 390` (bề rộng 768/1440 không áp dụng).

- `lint.mjs --app docs/design/brand-v2/mock` → **0 FAIL, 3 WARN** (giữ cả 3): `padStart(2,'0')` ×2 là số phút trong "6g 50p" và ngày "18/12/2026" (đúng loại skill cho phép: giờ, ngày); `em-dash` = các "—" là **giá trị thiếu** theo §11 app-screens (một gạch xám), cộng chú thích trong `data.js`.
- `inspect.mjs --app <file> --widths 390` cho `home`, `home-waiting`, `home-states`, `profile` → **0 FAIL, 0 WARN** cả 4. Đo: h1 2 dòng 28px Newsreader; phông thật đã nạp (Hanken 94%, Newsreader 6%); 5 cỡ 12/14/16/20/28.

**Ba vòng nhìn ảnh (7 câu §2.7):**

```
ROUND 1 (home)
Thấy trong 1 giây: lời chào serif + ảnh hoàng hôn lớn.
Scores: design 6 · usability 6 · creativity 7 · content 7 → overall 6.4
Ba lỗi nặng nhất:
1. Ảnh 16:9 chiếm nửa màn đầu, nút "Trả lời" bị thanh tab cắt (mobile-fold) → ảnh 21:9.
2. h1 ngắt "1.255 / ngày bên nhau", dòng phụ rớt chữ "lời" một mình → tác giả tự ngắt, rút dòng phụ.
3. Dấu hiệu hai chấm trông như công tắc bật/tắt; "Tuấn và Thảo" lặp ở thanh trên và h1 → dấu hai vòng giao nhau, thanh trên ghi tên sản phẩm.

ROUND 2 (cả 4 file)
Scores: design 7 · usability 7 · creativity 7 · content 8 → overall 7.1
1. Dòng phụ dài xuống 2–3 dòng: sổ chung ("còn … ngân sách"), Hồ sơ ("…nguyên văn"), tiêu đề "Hôm nay của mình" 2 dòng → rút chữ.
2. "Thử lại" bị bóp thành 2 dòng ở hàng lỗi; gạch "—" cỡ số ở sổ lỗi đọc như đang tải → nowrap, bỏ gạch cỡ lớn.
3. Thời tiết làn trái xuống 2 dòng lệch làn phải → tách thành phố / tình trạng thành 2 dòng phụ cố định cả hai làn.

ROUND 3 (cả 4 file)
Scores: design 7.5 · usability 8 · creativity 7 · content 8 → overall 7.6
1. "3/3" ở đầu làn không rõ là gì, rồi "3 sao" bị xuống dòng → "3 sao" + nowrap.
2. Thanh tiến chỉ có một đầu có nghĩa, "1.255 ngày" lặp số của h1 → hai đầu là hai mốc thật (1.000 → 1.314), phần đầy đúng tỉ lệ 81%.
3. Status bar trống trông như lỗi khung → thêm giờ 12:20 khớp dữ liệu.
```

Còn yếu sau vòng 3: (a) panel tông `#F9F9F9` trên nền trắng rất nhẹ, màn hình độ sáng thấp có thể thấy "trống"; (b) ba làn ở máy 360dp còn 306 bên trong panel, giá trị chữ như "Đến chỗ làm" sát mép, cần thử thật trên máy nhỏ; (c) ảnh đứng một mình giữa tiêu đề và bảng, chưa nói gì ngoài "đẹp" (không có chú thích ai chọn, khi nào).

## 14. Câu hỏi cho user / PO

- **Q1 (user):** Đổi nhận diện đến mức này có được không: nhấn xanh mòng két `#1B6E66` thay hồng, icon app thành hai vòng giao nhau trên nền trắng, phông Hanken + Newsreader? Đây là thay đổi người dùng cũ thấy ngay (icon, store).
- **Q2 (user):** Thẻ đếm ngày v2 bỏ đồng hồ giờ/phút/giây chạy liên tục và hiệu ứng aurora, giữ số ngày ở h1 + ảnh + thanh tới mốc. Đồng ý bỏ đồng hồ?
- **Q3 (PO):** Mốc kế tiếp hiện **lệch** giữa Home (`_getNextMilestone`: …1.000, **1.500**… ⇒ "còn 245 ngày") và Hồ sơ (`MilestoneTrail`: …1.000, **1.314**… ⇒ "còn 59 ngày"). Mockup đề xuất dùng chung danh sách của Hồ sơ (có 520, 1.314 mang nghĩa tiếng Việt). Chốt?
- **Q4 (user):** Trời đêm navy của Cây tình yêu và widget M2 (user chốt 2026-10-12) bị tasteskill cấm (tối navy). Đề xuất đổi sang tối trung tính `#111111`. Đồng ý, hay giữ navy như một ngoại lệ có chủ ý?
- **Q5 (PO):** Dark mode: v2 chỉ làm light. Có muốn làm dark luôn trong đợt đổi nhận diện (token tối của sheet có sẵn: `#000/#111/#222`)?

---

## Nhật ký

- [2026-10-20] [Designer] Tạo bản v2 bằng trọn run màn app tasteskill (`editorial-greeting`, seed 665763129) + UI UX Pro Max. Phông Instrument bị loại vì thiếu tiếng Việt (50/146) → Hanken Grotesk + Newsreader (146/146, OFL). Chốt Home v2 "ba làn" gộp poke/weather/arrival vào bảng Hôm nay, caro gộp với oẳn tù tì, sổ chung 1 hàng. Mockup Home (đã ghép, chờ người ấy, trạng thái) + Hồ sơ ở `docs/design/brand-v2/mock/`. Lint 0 FAIL / inspect 0 FAIL 0 WARN ở 390. Chờ user duyệt Q1–Q5.
