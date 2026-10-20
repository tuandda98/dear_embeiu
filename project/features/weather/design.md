# 🎨 Design: Thời tiết hai nơi

> Designer sở hữu. Đọc `overview.md` trước. Bám `project/design-system.md` + code thật `lib/theme/`, `lib/widgets/`. CHỈ thiết kế, không code.

- **Trạng thái design:** xong bản 1, chờ PO duyệt 3 câu hỏi cuối file
- **Người/role:** Designer
- **Mockup bấm thử:** `docs/design/weather/` (mở `home.html` rồi bấm: thẻ → sheet chi tiết, "Nhắc mang ô" → màn Quan tâm, "Đổi thành phố" → sheet chọn). Ảnh chụp cuối ở `docs/design/weather/shots/`.
- **Nguồn style:** sheet chung của đợt `docs/design/daily-open-2/sheet.raw.md` (editorial-greeting, seed 1822703143, `--keep palette,type`). Không draw lại. Màu, phông, bo góc, khoảng cách lấy từ app hiện tại (user chốt 2026-10-20: "follow theo system design hiện tại của app").

---

## 1. Màn và luồng

| # | Màn | File mockup | Widget Flutter |
|---|---|---|---|
| 1 | Thẻ Home "Thời tiết hai nơi" (lối vào) | `home.html`, `states.html` | MỚI `lib/widgets/weather/weather_card.dart` |
| 2 | Sheet chi tiết (chạm thẻ) | `detail.html` | MỚI `showWeatherDetailSheet()` trong `lib/widgets/weather/weather_sheets.dart` |
| 3 | Sheet chọn thành phố (của mình / chọn giúp người ấy) | `picker.html`, `picker-partner.html`, `picker-empty.html` | MỚI `showCityPickerSheet(forPartner:)` cùng file |
| 4 | Màn Quan tâm điền sẵn | `care.html?c=rain\|hot\|cold` | CÓ SẴN `care_message_screen.dart`, chỉ thêm `initialTitle`/`initialBody` |
| 5 | Cài đặt, mục "Thời tiết hai nơi" | `settings.html` | THÊM section trong `settings_screen.dart` |
| 6 | Thông báo sáng 07:30 | `notification.html` | local notification id 1160 (spec D13) |

```
Home ─┬─ chạm thẻ ───────────────► Sheet chi tiết ─┬─ "Đổi thành phố" ─► Sheet chọn (của mình)
      │                                             └─ "Nhắc mang ô" ───► Màn Quan tâm điền sẵn ─ Gửi ─► về Home + snackbar
      ├─ "Nhắc mang ô" (trên thẻ) ────────────────────────────────────► Màn Quan tâm điền sẵn
      ├─ "Chọn giúp" (cột người ấy trống) ─► Sheet chọn (cho người ấy) ─ chọn ─► đóng sheet, thẻ cập nhật
      ├─ "Chọn" (cột mình trống) ─────────► Sheet chọn (của mình)
      ├─ thẻ thu gọn "Xem thời tiết chỗ người ấy" ─► Sheet chọn (của mình) ─► thẻ hiện cột mình + "Thảo đang ở đâu? Chọn giúp"
      └─ "Ẩn" ─► thẻ biến khỏi Home (cờ Hive), lối vào còn ở Cài đặt
Thông báo 07:30 ─ chạm ─► Home, cuộn tới thẻ (pendingHomeFocus = 'weather') ─► "Nhắc mang ô" ─► Quan tâm
Cài đặt ─► "Chỗ mình" / "Chỗ Thảo" (khi chưa tự chọn) ─► Sheet chọn · công tắc · Giờ báo ─► app_time_picker
```

Từ lúc mở app tới lúc gửi lời nhắc mang ô: **2 chạm** (Nhắc mang ô → Gửi).

---

## 2. Tasteskill run (app screens, `references/app-screens.md` §2.1–2.8)

### 2.1 Kiểm kê dữ liệu và việc

- **Đối tượng:** 2 nơi (mỗi người một `cityId`), mỗi nơi có nhiệt độ hiện tại (°C, số nguyên), mã trời giờ hiện tại, câu tình trạng phần còn lại trong ngày, thấp/cao từ giờ tới 23:59, 5 mốc 3 giờ một, giờ lấy số (`fetchedAt`), ai chọn (`setBy`).
- **Độ lớn thật:** nhiệt độ VN 12–38°, nước ngoài −10–40°; chênh hai nơi thường 0–10° (Hà Nội 23° với TP.HCM 29° sáng 20/10); mùa mưa Sài Gòn gần như chiều nào cũng "Chiều nay mưa". Danh sách 64 điểm VN + 50 nước ngoài.
- **Người dùng:** cặp đôi trẻ, liếc thẻ 2–5 giây lúc sáng, trên điện thoại một tay. 28 cặp đã ghép, 52 cặp đang chờ (chỉ thấy cột mình).
- **Việc hay làm nhất:** nhắc người ấy mang ô / uống nước / mặc ấm. Việc thứ hai: chọn thành phố một lần lúc đầu (cho mình, rồi chọn giúp người ấy).
- **Thứ chỉ app này có:** hai người tên thật (Thảo, Tuấn/"Mình"), màu riêng mỗi người (`PersonPalette`, mặc định Hồng #FF4D6D và Tím #7C5CD6, đã dùng ở thẻ Đêm qua), lời quan tâm gửi nguyên văn thành push (care-message), danh sách thành phố gắn tên tỉnh sau sáp nhập ("Phan Thiết · Lâm Đồng", tìm "binh thuan" vẫn ra).
- **Dữ liệu mẫu:** `docs/design/weather/data.js`, cặp DEV Tuấn ♥ Thảo, ngày yêu 14/05/2023 (1255 ngày tới 20/10/2026), bây giờ 08:10, số lấy lúc 07:12. Mọi câu trên thẻ được TÍNH từ giờ dự báo theo luật §6.2/D10/D11/D16 của spec, không gõ tay. 25 `console.assert` trong `data.js` (đều PASS, thêm 1 ở `detail.html` cho thước 22°–33°): tình trạng từng thành phố, cửa sổ nới sau 21:00, chênh 6° và 8°, 3 mức tuổi số liệu, lời điền sẵn với tên dài nhất ("Buôn Ma Thuột") lọt 60/200 ký tự, tìm "binh thuan" / "sai gon" / "seoul" / "xyz", id không trùng. Dev có thể chép các assert này thành test Dart cho hàm tính tình trạng.

### 2.2 Câu hỏi, phát hiện, việc chính của từng màn

| Màn | Câu hỏi một dòng | "One finding" (đặt chỗ đọc đầu) | Việc hay làm nhất (1 chạm) |
|---|---|---|---|
| Thẻ Home | Chỗ người ấy hôm nay có gì cần nhắc không? | Câu tình trạng cột người ấy ("Chiều nay mưa") ngay dưới nhiệt độ | Nút "Nhắc mang ô" ở hàng dưới, ngay dưới cột người ấy |
| Sheet chi tiết | Mưa lúc mấy giờ, nóng lạnh tới đâu, hai nơi chênh bao nhiêu? | Mốc giờ có mưa (icon mưa đậm hơn) + thanh nhiệt độ hai nơi trên cùng một thước | Nút gợi ý (đề xuất thêm) / "Đổi thành phố" |
| Sheet chọn | Mình (người ấy) đang ở thành phố nào trong danh sách? | Dòng khớp + "Tỉnh cũ: Bình Thuận" khi khớp nhờ tên tỉnh cũ | Chạm một dòng là lưu và đóng |
| Màn Quan tâm | Lời này gửi được chưa? | Tiêu đề + lời đã điền sẵn, có tên thành phố | Gửi |
| Cài đặt | Báo lúc nào, báo về chỗ nào? | Hàng xem trước thông báo sẽ tới | Bật/tắt |
| Thông báo | Hôm nay chỗ người ấy có gì? | Tiêu đề "Hôm nay TP.HCM có mưa" | Chạm → Home → nút gợi ý |

### 2.3 Style, face, signature

- **Style:** editorial-greeting (sheet chung). Nước đi của style ("số ở weight thường trên panel tông nhạt, một lớp mỗi panel") được giữ theo cách của app: số nhiệt độ **w600** (cùng weight với số đếm ngày ở CounterCard, nhẹ hơn w800 của DurationText bên Đêm qua), mỗi thẻ là MỘT `ContentCard` trắng, không lồng card trong card.
- **Map vai trò của sheet sang màu thương hiệu:** ground → `dawnBlush` (#FFC1CC → #E8B4D8 → #C8A8E9) · surface/panel → `cardSurface` #FFFFFF · raised (ô nhập, thanh nền) → `surfaceLight` #F5F0F5 · rule → `textSecondary` α.10 · text → `textPrimary` #1A1A2E · muted → `textSecondary` #6B6B7B (5,3:1 trên trắng) · accent (dưới 2%) → `accentLove` #FF4D6D chỉ ở icon trong `IconBadge` · nút chính → navy `textPrimary` (theme) · dữ liệu của người → `PersonPalette`.
- **Face (chọn 1 trong 3 của sheet):** "mỗi người một màu riêng trên làn của mình; cặp đôi là ba làn". Thẻ có **làn người ấy (trái) · làn mình (phải) · làn chung (hàng dưới, toàn chiều rộng)**. Làn chung chứa thứ thuộc về cả hai: nút nhắc người ấy, hoặc câu chênh lệch "Chỗ Thảo lạnh hơn 6°", hoặc "Cả hai cùng ở Hà Nội" khi trùng thành phố (một làn, hai chấm chồng nhau). Màu người chỉ nằm ở chấm 8px và thanh nhiệt độ, không tô chữ (luật `PersonPalette`).
- **Signature element:** **"hai nơi trên một thước nhiệt độ"** trong sheet chi tiết: mỗi nơi một thanh thấp–cao tô màu người đó, núm tròn ở nhiệt độ hiện tại, cả hai thanh dùng CHUNG thước (22°–33° trong dữ liệu mẫu). Nhìn là thấy thanh của Thảo nằm lệch sang phải thanh của mình, không cần đọc câu chênh lệch.

### 2.4 Shell

Không có shell mới. Thẻ nằm trong tab Home hiện có (nền dawnBlush do shell vẽ, gutter 16, khoảng cách giữa các thẻ 16, header chip lời chào + chuông, floating nav kính). Hai sheet dùng khuôn bottom sheet của app (trắng, bo trên 28, tay nắm). Màn Quan tâm giữ `SubScreenHeader`. Cài đặt thêm một section theo khuôn sẵn (`SectionHeader` + `ContentCard` padding 20/6 + hàng `IconBadge`).

---

## 3. Wireframe (390 × 844, đơn vị dp)

### 3.1 Thẻ Home, trạng thái chính (cao ≈ 246)
```
┌ ContentCard r24, pad 16 ─────────────────────────────┐
│ [IconBadge 44] Thời tiết hai nơi            16/800 › │  ← chevron 18 textTertiary
│                Cập nhật 07:12               12/500   │
│                                         (14)         │
│ ● Thảo · TP.HCM        │ ● Mình · Hà Nội     13/700+500
│ 29°  ☁                 │ 23°  ☁              30/600 + icon 24
│ Chiều nay mưa          │ Nhiều mây           14/700
│ ─────────────────────────────────────────── (14, vạch α.10)
│ [☂ Nhắc mang ô]  ← nút navy pill h44, rộng theo chữ (12)
└──────────────────────────────────────────────────────┘
```
- Hai làn chia đôi, giữa là vạch dọc 1px α.10, mỗi làn đệm 14 phía vạch (y hệt `SleepCard._LastNight`).
- Hàng chung chỉ có MỘT thứ: nút gợi ý (ưu tiên) > câu chênh lệch ≥5° > không có gì (khi đó bỏ cả vạch ngang).

### 3.2 Thẻ thu gọn (chưa ai chọn, cao ≈ 92)
```
┌──────────────────────────────────────────────────────┐
│ [IconBadge] Xem thời tiết chỗ người ấy         Ẩn    │
│             Chọn chỗ mình và chỗ Thảo, sáng nào      │
│             mở app cũng thấy.                        │
└──────────────────────────────────────────────────────┘
```

### 3.3 Sheet chi tiết
```
──── tay nắm 36×4 ────
Thời tiết hai nơi                      20/700
Cập nhật 07:12                         13 textSecondary
● Thảo                                 (bây giờ 10:10 nếu khác múi giờ)
TP.HCM · (vùng nếu có)        ✓ Thảo tự chọn | ⌖ Đổi giúp | ⌖ Đổi thành phố
29°  ☁  Chiều nay mưa                  30/600 · icon 24 · 15/700
Từ giờ tới khuya 25° – 33°             13 textSecondary
[════════●══════════] thước chung      track 6 #F5F0F5, fill màu người, núm 12 trắng viền 2
22°                              33°   12 textSecondary
[☂ Nhắc mang ô]                        (chỉ ở khối người ấy, khi có tình trạng)
09:00 12:00 15:00 18:00 21:00          12/600 · icon 22 · 15/600
──────────────── vạch α.10
● Mình  … (khối của mình, cùng khuôn)
Dữ liệu thời tiết: MET Norway          12, link đậm gạch chân
```

### 3.4 Sheet chọn thành phố (DraggableScrollableSheet ≈ 0.92)
```
──── tay nắm ────
Thảo đang ở đâu?                       20/700
Thảo vẫn tự đổi được sau.              13 textSecondary
[🔍 Tìm thành phố hoặc tỉnh       ⓧ]   h48 r20 surfaceLight
Đang chọn                              13/700 textSecondary (chỉ khi ô tìm trống và đã có chọn)
Hà Nội                           ✓
Việt Nam
TP.HCM                                 dòng ≥52, vạch α.10 giữa các dòng
Phan Thiết · Lâm Đồng                  15/600 + 13/500
Tỉnh cũ: Bình Thuận                    12 (chỉ khi khớp nhờ tên cũ)
Nước ngoài
Seoul · Hàn Quốc
…
Dữ liệu thời tiết: MET Norway
```

### 3.5 Cài đặt, section "Thời tiết hai nơi"
```
Thời tiết hai nơi                                    SectionHeader 22/700
┌ ContentCard pad 20/6 ────────────────────────────────┐
│ [⌖] Chỗ mình                                    ›    │
│     Hà Nội                                           │
│ ──── (vạch thụt 58)                                  │
│ [⌖] Chỗ Thảo                       (› nếu mình chọn giúp)
│     TP.HCM · Thảo tự chọn                            │
│ ────                                                 │
│ [🔔] Thời tiết chỗ người ấy                   (●  )  │
│      Báo lúc 07:30 khi chỗ Thảo mưa, nắng gắt hoặc   │
│      lạnh. Tối đa 3 lần một tuần.                    │
│ ────                                                 │
│ [🕒] Giờ báo                                 [07:30] │
└──────────────────────────────────────────────────────┘
Hôm nào chỗ Thảo có mưa, thông báo sẽ như thế này:    13/600
[♥  Hôm nay TP.HCM có mưa                    07:30]   xem trước, white .86 r20
[   Nhắc Thảo mang ô nhé?                         ]
Dữ liệu thời tiết: MET Norway
```

---

## 4. Spec chi tiết (token có nguồn trong code)

### 4.1 Thẻ Home `WeatherCard`

| Phần | Giá trị | Nguồn |
|---|---|---|
| Khung | `ContentCard(padding: EdgeInsets.zero)` + `Material(transparent)` + `InkWell(borderRadius 24, splash accentRose .08, highlight .04)` bọc `Padding(16)` | y hệt `sleep_card.dart` |
| Icon đầu | `IconBadge(IconsaxPlusLinear.cloud_sunny)` 44 / r16 / tint `accentRose` α.12 / icon 20 | `icon_badge.dart` |
| Tiêu đề | 16 w800 `textPrimary`, 1 dòng, ellipsis | như "Đêm qua" |
| Dòng giờ | 12 w500 `textSecondary`, cách tiêu đề 2, nằm DƯỚI tiêu đề (không cùng hàng, để tiêu đề tiếng Anh và chữ lớn không xuống dòng) | |
| Chevron | `IconsaxPlusLinear.arrow_right_3` 18 `textTertiary` | như Đêm qua |
| Header → làn | 14 | |
| Nhãn làn | chấm 8 màu người + 6 + tên 13 w700 `textSecondary` + " · " + thành phố 13 w500 `textSecondary`, 1 dòng ellipsis ở phần thành phố. **Chữ thường, không viết hoa** (khác `PersonLabel` của Sleep đang viết hoa 11 ls1.0: chữ hoa nhỏ giãn chữ là thứ tasteskill cấm, và tên thành phố viết hoa khó đọc) | MỚI `_LaneLabel` |
| Nhiệt độ | 30 w600 `textPrimary`, letterSpacing −0.5, height 1.1, `FittedBox.scaleDown` | type scale 30 |
| Icon trời | 24 `textSecondary`, cách số 8, theo bảng §7 | Iconsax Linear |
| Câu tình trạng | 14 w700 `textPrimary`, cách số 2, tối đa 2 dòng | |
| Hàng chung | vạch ngang 1px α.10, cách làn 14; nội dung cách vạch 12; cao tối thiểu 44 | `_TogetherFooter` |
| Nút gợi ý | `ElevatedButton.icon` theme navy, cao 44, padding ngang 18, icon 18, nhãn 15 w600; rộng theo chữ, căn trái (nằm dưới làn người ấy); nhãn 1 dòng `FittedBox.scaleDown` | như nút "Bật" của Sleep |
| Câu chênh lệch | 14 w600 `textPrimary`, không icon | |
| Thẻ thu gọn | `IconBadge` + cột [15 w700 tiêu đề, 13 `textSecondary` phụ] + `TextButton` "Ẩn" 14 w600 `textSecondary` min 44×44 | như `_SetupPitch` |
| Cột trống ("Thảo đang ở đâu?") | chấm + câu 14 w700 `textPrimary` thay cho nhãn làn; cách 10; nút viền `OutlinedButton.icon` pill h44, viền navy α.18, icon `location` 18, nhãn 14 w600 | nút viền kiểu "Email" ở landing |
| Thẻ đang tải | giữ header thật, dòng giờ = `ShimmerSkeleton(84×14)`; mỗi làn: nhãn thật + skeleton 58×33 (số) + tròn 24 (icon) + 96×16 (câu) | `shimmer_skeleton.dart` |
| Số cũ (6–24 giờ) | nhiệt độ + câu chuyển `textSecondary` (vẫn 5,3:1, không làm mờ bằng alpha để khỏi rớt tương phản); dòng giờ thêm icon `clock` 14 + "Số liệu lúc 21:40"; ẩn hàng chung | D16 |
| Lỗi (>24 giờ / chưa từng tải) | header không chevron; làn chỉ còn nhãn (tên + thành phố); hàng chung: "Chưa tải được thời tiết" 14 w600 `textSecondary` trái + `TextButton.icon(refresh)` "Thử lại" 14 w700 `textPrimary` phải; chạm bất kỳ đâu trên thẻ cũng thử lại | D16 |

**Chiều cao để người ghép Home tính:** chính có nút ≈ 246 · có câu chênh lệch ≈ 220 · không hàng chung ≈ 190 · một làn (chờ người ấy) ≈ 190 · thu gọn ≈ 92 · đang tải ≈ 190 · lỗi ≈ 178.

### 4.2 Sheet chi tiết

- `showModalBottomSheet(isScrollControlled: true, backgroundColor: white, shape: top 28)`, nội dung cuộn, cao theo nội dung, tối đa 0.9 màn. Padding 20 / trên 12 / dưới 32 + safe area.
- Tay nắm 36×4 r2 #E2DDE6 (giống các sheet sẵn có), cách tiêu đề 16.
- Tiêu đề 20 w700; phụ 13 `textSecondary` "Cập nhật 07:12" (hoặc "Số liệu lúc …" khi cũ).
- Mỗi khối nơi: padding dọc 20, khối sau có vạch trên 1px α.10. Nhãn người (chấm + tên 13 w700 `textSecondary`). Tên thành phố 16 w800 + vùng 13 w500 `textSecondary` (ẩn vùng với 6 thành phố trực thuộc TW, xem §9). Nút phải: "Đổi thành phố" (khối mình) / "Đổi giúp" (khối người ấy khi `setBy == mình`) là `TextButton.icon(location)` 14 w700 min 44; hoặc chữ "Thảo tự chọn" 12 w600 `textSecondary` + icon `tick_circle` 14 (không bấm được).
- Hàng lớn: số 30 w600 · icon 24 `textSecondary` · câu 15 w700.
- Thước: nhãn "Từ giờ tới khuya 25° – 33°" 13 w500 `textSecondary`; track cao 6 r3 `surfaceLight`; fill màu người từ thấp tới cao; núm 12 trắng viền 2 màu người ở nhiệt độ hiện tại; hai đầu thước 12 `textSecondary`. Thước = min(thấp hai nơi) → max(cao hai nơi); chỉ một nơi thì thước của chính nơi đó.
- 5 mốc: lưới 5 cột đều, giờ 12 w600 `textSecondary` · icon 22 (`textSecondary`, mốc có mưa thì `textPrimary`) · số 15 w600; khoảng 6 giữa các dòng.
- Nút gợi ý (đề xuất thêm, xem §12): dưới thước, cách 16, cùng khuôn nút trên thẻ, chỉ ở khối người ấy khi có tình trạng và số còn tươi.
- Dòng nguồn ở cuối (§4.6).

### 4.3 Sheet chọn thành phố

- `DraggableScrollableSheet(initial 0.92, max 0.92)`; tiêu đề 20 w700; phụ 13 `textSecondary`.
- Ô tìm: `TextField` theme input (filled `surfaceLight`, r20, viền focus `accentLove` 1.4) cao 48, prefix `search_normal_1` 20 `textSecondary`, suffix `close_circle` 20 trong vùng chạm 44 **chỉ hiện khi đã gõ**, hint 15 `textSecondary`. `textInputAction: search`, không tự bật bàn phím khi mở (danh sách thấy được ngay; người cần tìm tự chạm).
- Nhóm: tiêu đề 13 w700 `textSecondary`, cách trên 20, dưới 4. Thứ tự nhóm: "Đang chọn" (chỉ khi ô tìm trống và đã có lựa chọn, dòng đó không lặp lại ở nhóm dưới) → "Việt Nam" (6 thành phố trực thuộc TW đứng đầu: Hà Nội, TP.HCM, Hải Phòng, Đà Nẵng, Huế, Cần Thơ; còn lại A→Z theo tên đã bỏ dấu) → "Nước ngoài" (thứ tự Phụ lục A, theo nước).
- Dòng: `InkWell` cao ≥52, padding dọc 8, vạch 1px α.10 giữa các dòng (toàn chiều rộng, không thụt vì không có icon đầu). Tên 15 w600 (đang chọn: w700 + `IconsaxPlusBold.tick_circle` 20 `textPrimary` bên phải) + " · vùng" 13 w500 `textSecondary`. Khớp nhờ alias → dòng thứ hai "Tỉnh cũ: Bình Thuận" 12 `textSecondary`.
- Không tìm thấy: câu spec 14 w600 `textPrimary`, cách ô tìm 24.
- Danh sách dài 114 dòng: `ListView.builder` / `SliverList` (UI UX Pro Max, stack flutter).
- Chạm dòng: haptic `selectionClick`, ghi Firestore, đóng sheet ngay (Firestore tự xếp hàng khi offline nên không có trạng thái "đang lưu"). Bị rules chặn vì người ấy vừa tự chọn → sheet vẫn đóng + SnackBar "Thảo vừa tự chọn chỗ của mình rồi." (navy floating r20 theo theme).

### 4.4 Màn Quan tâm điền sẵn

Giữ nguyên màn (mockup `care.html` dựng lại đúng `care_message_screen.dart`). Thay đổi DUY NHẤT: `openCareMessageScreen(context, initialTitle:, initialBody:)` gán sẵn 2 controller, nút Gửi bật ngay. Không tự focus ô nhập (bàn phím sẽ che nút Gửi; người dùng muốn sửa thì chạm). Bộ đếm "48/200" của ô Lời nhắn hiện như hiện tại. Phân tích: gửi từ đây thì `care_message_sent{source: weather}`.

### 4.5 Cài đặt

Section mới **đặt ngay sau nhóm "Thông báo"**, trước "Lịch âm"/"Chung": `SectionHeader("Thời tiết hai nơi")` + 12 + `ContentCard(padding: h20 v6)`. Hàng = khuôn `_navRow` / `SwitchListTile.adaptive` hiện có (IconBadge 44, tiêu đề 15 w700, phụ 12 `textSecondary` cách 4, vạch `_rowDivider()` thụt 58, công tắc `activeThumbColor: accentRose` như `_DecisionReminderTile`).

1. "Chỗ mình" · phụ = tên thành phố hoặc "Chưa chọn" · chevron → sheet chọn (của mình).
2. "Chỗ Thảo" (ẩn khi đang chờ người ấy) · phụ = "TP.HCM · Thảo tự chọn" (không chevron, không bấm) | "Đà Lạt · mình chọn giúp" (chevron → sheet cho người ấy) | "Chưa chọn" (chevron).
3. Công tắc "Thời tiết chỗ người ấy" · phụ "Báo lúc {giờ} khi chỗ {tên} mưa, nắng gắt hoặc lạnh. Tối đa 3 lần một tuần." Đang chờ người ấy: công tắc tắt + khoá, phụ "Ghép đôi xong mới báo được." (nói vì sao khoá, không làm mờ cả hàng).
4. "Giờ báo" · trailing chip giờ (pill `surfaceLight` cao 36, 15 w700) → `app_time_picker.dart`. Chỉ hiện khi công tắc bật. **Chờ PO chốt (§13 câu 1).**

Dưới card: caption 13 w600 `textPrimary` "Hôm nào chỗ Thảo có mưa, thông báo sẽ như thế này:" + khối xem trước (white α.86 r20, icon app 38 r9 #FF6B9D + tim trắng, tiêu đề 15 w700, nội dung 15, giờ 13 `textSecondary`). Chỉ hiện khi công tắc bật và đã ghép. Rồi dòng nguồn.

### 4.6 Dòng ghi nguồn MET Norway (D2)

"Dữ liệu thời tiết: " 12 w500 `textSecondary` + "MET Norway" 12 w700 `textPrimary` gạch chân (offset 2), mở `https://api.met.no/doc/License` bằng `url_launcher` (externalApplication). Vùng chạm cả dòng ≥44 cao. Có ở: sheet chi tiết, sheet chọn, Cài đặt. Không có logo Yr.

### 4.7 Thông báo sáng

Hệ điều hành vẽ bằng phông hệ thống (mockup dùng SF/Roboto cho đúng). Tiêu đề và nội dung đúng bảng §6.7 spec, đã kiểm ≤ 40 ký tự tiêu đề nên không bị cắt trên màn khoá. Icon app là icon launcher sẵn có.

---

## 5. Trạng thái (đủ trong `states.html`)

| # | Trạng thái | Thẻ Home | Sheet chi tiết | Cài đặt |
|---|---|---|---|---|
| 1 | Cả hai đã chọn, chỗ người ấy mưa | 2 làn + nút "Nhắc mang ô" | khối người ấy có nút | đủ 4 hàng + xem trước |
| 2 | … nắng gắt ≥35° | nút "Nhắc uống nước" (icon `drop`) | như trên | |
| 3 | … lạnh ≤15° / tuyết | nút "Nhắc mặc ấm" (icon `wind`) | như trên | |
| 4 | Trời thường, lệch ≥5° | câu "Chỗ Thảo lạnh hơn 6°" | | |
| 5 | Trời thường, lệch <5° | không hàng chung, không vạch | | |
| 6 | Cùng thành phố | 1 làn "Cả hai cùng ở Hà Nội" (2 chấm chồng, chấm sau có viền trắng 1.5) + nút nếu có | 1 khối | |
| 7 | Đã ghép, người ấy chưa chọn | cột trái "Thảo đang ở đâu?" + nút viền "Chọn giúp" | khối người ấy = câu + nút | "Chỗ Thảo · Chưa chọn ›" |
| 8 | Đã ghép, mình chưa chọn | cột phải "Mình đang ở đâu?" + "Chọn"; nút gợi ý vẫn hiện theo chỗ người ấy | | "Chỗ mình · Chưa chọn ›" |
| 9 | Chưa ai chọn | thu gọn: "Xem thời tiết chỗ người ấy" + Ẩn | (không mở được) | |
| 10 | Đang chờ người ấy, đã chọn | 1 làn của mình, không hàng chung | 1 khối | chỉ hàng 1 + công tắc khoá |
| 11 | Đang chờ người ấy, chưa chọn | thu gọn: "Xem thời tiết chỗ mình" | | |
| 12 | Đang tải lần đầu | khung xương đúng cỡ, nhãn thật hiện ngay, không nhảy layout khi số về | skeleton cùng cỡ | |
| 13 | Số cũ 6–24 giờ | số xám, "⏱ Số liệu lúc 21:40", không nút | phụ "Số liệu lúc 21:40", không nút | |
| 14 | >24 giờ / chưa từng tải / lỗi | nhãn làn + "Chưa tải được thời tiết · Thử lại" | nếu đang mở: cùng câu + Thử lại trong sheet | |
| 15 | Offline, số ≤6 giờ | giống #1, chỉ có "Cập nhật 07:12" | | |
| 16 | Mã MET lạ | chỉ nhiệt độ, ẩn câu | | |
| 17 | Đang làm mới khi đã có số | giữ số cũ, không skeleton; xong thì đổi dòng giờ | | |
| 18 | Đã bấm Ẩn | Home không có thẻ | | Cài đặt vẫn đủ, chọn thành phố xong thì thẻ hiện lại (xoá cờ ẩn) |
| 19 | Qua 0:00 | câu tình trạng tự tính lại (`MidnightBuilder`), không gọi mạng | | |
| 20 | Đã tắt thông báo | thẻ không đổi | | hàng Giờ báo + xem trước ẩn |
| 21 | Chữ lớn 130%+, tên dài nhất | nhãn làn ellipsis phần thành phố, số `FittedBox`, tiêu đề 1 dòng vì giờ đã xuống dòng dưới | | |

---

## 6. Interaction và motion

- **Entrance:** thẻ dùng `_entrance(i, …)` / `EntranceReveal` của Home như các thẻ khác (360 ms, stagger 50). Không có hiệu ứng riêng.
- **Số về / số đổi:** `AnimatedSwitcher(duration: AppMotion.fast 200, curve: AppMotion.curve easeOutCubic)` cross-fade nội dung từng làn. Khung xương cùng kích thước nên không đẩy thẻ dưới.
- **Hàng chung xuất hiện/biến mất** (vd qua 6 giờ thì nút ẩn): `AnimatedSize(200, easeOutCubic)`.
- **Phản hồi chạm:** `InkWell` ripple rose .08 trên thẻ và dòng chọn thành phố; nút theme có hiệu ứng nhấn sẵn. `HapticFeedback.selectionClick` khi chạm nút gợi ý, chọn thành phố, gạt công tắc.
- **Sheet:** animation mặc định của `showModalBottomSheet` (như các sheet khác). Chọn xong đóng ngay.
- **Chạm thông báo:** về Home, `Scrollable.ensureVisible(weatherKey, duration: AppMotion.slow 320, curve: easeOutCubic, alignment: 0.1)`.
- **Reduce Motion** (`AppMotion.reduceMotion(context)`): mọi `AnimatedSwitcher`/`AnimatedSize` dùng `Duration.zero`, cuộn tới thẻ bằng `jumpTo`. Không có animation lặp nào trong feature này. Skeleton của app có ánh lấp lánh: khi Reduce Motion thì `ShimmerSkeleton` đứng yên (nếu widget chưa làm, Dev thêm).

## 7. Icon (Iconsax Plus, `IconsaxPlusLinear` trừ chỗ ghi Bold)

| Dùng cho | Icon |
|---|---|
| Đầu thẻ | `cloud_sunny` |
| Trời quang (đêm) | `sun_1` (`moon`) |
| Ít mây | `cloud_sunny` (đêm: `cloud`) |
| Nhiều mây | `cloud` |
| Sương mù | `cloud_fog` |
| Mưa nhỏ / mưa / mưa to / nút "Nhắc mang ô" | `cloud_drizzle` (bộ Iconsax không có cái ô) |
| Dông | `cloud_lightning` |
| Tuyết | `cloud_snow` |
| Nút "Nhắc uống nước" | `drop` |
| Nút "Nhắc mặc ấm" | `wind` |
| Chọn / Chọn giúp / Đổi thành phố / hàng Chỗ … ở Cài đặt | `location` |
| Thử lại | `refresh` |
| Số cũ | `clock` |
| Tìm / Xoá chữ | `search_normal_1` / `close_circle` |
| Thành phố đang chọn | `IconsaxPlusBold.tick_circle` |
| "Thảo tự chọn" | `tick_circle` 14 |
| Công tắc / Giờ báo | `notification_bing` / `clock` |

## 8. Accessibility

- **Semantics:** mỗi làn là một nút đọc gộp (`MergeSemantics` / `Semantics(label:)`): "Thảo, TP.HCM, 29 độ, chiều nay mưa". Cả thẻ: `Semantics(button: true, hint: "Mở chi tiết thời tiết")`. Nút gợi ý: label "Nhắc Thảo mang ô" (đọc đủ tên, chữ trên nút ngắn hơn). Dòng giờ: "Cập nhật lúc 7 giờ 12". Trạng thái lỗi: câu lỗi trong `Semantics(liveRegion: true)`. Thước nhiệt độ: một `Semantics(label: "Từ giờ tới khuya 25 đến 33 độ, bây giờ 29 độ")`, các phần con `excludeSemantics`. Mốc giờ: "15 giờ, 29 độ, có mưa". Sheet chọn: dòng đang chọn có `selected: true`; nút xoá chữ "Xoá chữ đã gõ".
- **Vùng chạm ≥44:** nút gợi ý 44, nút viền 44, "Ẩn" 44×44, "Thử lại" 44, dòng thành phố ≥52, xoá chữ 44×44, dòng nguồn ≥44, hàng Cài đặt ≥68. Thẻ cách nút trong thẻ ≥8.
- **Không chỉ dùng màu:** người được nhận ra bằng tên, chấm màu chỉ phụ. Mưa ở mốc giờ có icon khác chứ không chỉ đậm hơn. Số cũ có icon đồng hồ + chữ "Số liệu lúc".
- **Tương phản:** mọi chữ là `textPrimary` (16:1) hoặc `textSecondary` (5,3:1) trên trắng; chữ trên nút navy trắng 16:1. Không dùng `textTertiary` cho chữ. Số cũ đổi sang `textSecondary` thay vì giảm alpha.
- **Chữ lớn:** kiểm 130% trong `states.html` #16; Dev kiểm thêm 200% trên máy: nhãn làn ellipsis, số `FittedBox.scaleDown`, nút 1 dòng `FittedBox`, câu tình trạng tối đa 2 dòng.

## 9. Ghi chú cho Dev

1. **Widget mới:** `lib/widgets/weather/weather_card.dart` (`WeatherCard`, `_WeatherLane`, `_LaneLabel`, `_SharedRow`, `_CollapsedInvite`) và `lib/widgets/weather/weather_sheets.dart` (`showWeatherDetailSheet`, `showCityPickerSheet`, `_TempScale`, `_HourSlots`, `MetCredit`). Tái dùng: `ContentCard`, `IconBadge`, `ShimmerSkeleton`, `SectionHeader`, `app_time_picker.dart`, khuôn `_navRow`/`_rowDivider` trong Settings.
2. **Màu người:** lấy y như thẻ Đêm qua (`PersonPalette.colorOf(sleep.myColorId / partnerColorId)`, mặc định `PersonPalette.resolve`) để một người luôn cùng một màu trên mọi thẻ Home.
3. **"Từ giờ tới khuya" chứ không "cao/thấp hôm nay":** CF chỉ trả 36 giờ TỚI (D8), không có các giờ đã qua, nên số thấp/cao là của phần còn lại trong ngày. Chữ phải nói đúng như vậy.
4. **Vùng (region):** 6 thành phố trực thuộc TW để `regionVi/En` rỗng → chỉ hiện tên ("Hà Nội", không "Hà Nội · Hà Nội"). Còn lại luôn hiện "Đà Lạt · Lâm Đồng", "Seoul · Hàn Quốc".
5. **Khác múi giờ:** nếu `tz` thành phố người ấy khác máy mình, nhãn khối người ấy trong sheet chi tiết thêm " · bây giờ 10:10" và các mốc giờ là giờ bên đó. Cùng múi giờ thì không ghi gì.
6. **Tìm không dấu:** bỏ dấu bằng NFD + bỏ dấu kết hợp + `đ→d` + thường hoá, so trên tên vi/en + vùng + aliases. Hàm mẫu `fold`/`search` ở `docs/design/weather/data.js`; dòng khớp nhờ alias trả kèm alias để hiện "Tỉnh cũ: …".
7. **Thứ tự kiểm khi dựng hàng chung:** chưa ghép → không có; số cũ/lỗi → không có (lỗi có câu lỗi riêng); có tình trạng ở chỗ người ấy → nút; lệch ≥5° → câu; còn lại → bỏ cả vạch.
8. **Lối vào Home:** `KeyedSubtree(key: _weatherKey)` để `pendingHomeFocus = 'weather'` cuộn tới.
9. **Cờ Ẩn:** Hive `app_settings` (`Box<String>` → lưu `'true'`), key gợi ý `weather_card_hidden`. Chọn thành phố từ Cài đặt thì xoá cờ.

## 10. Copy deck vi / en

Tên key là gợi ý cho Dev. Copy có dấu (spec) là của PO, giữ nguyên. Đã soát bản vi theo `humanizer` (câu ngắn, không cụm sáo, xưng "chúng mình"/"mình", dấu kiểu mới) và bản en theo `avoid-ai-writing` (không từ sáo, không gạch ngang, gọi người ấy là "your love" như ARB hiện có). ICU: chỉ `{}` cho placeholder.

| Key gợi ý | vi | en |
|---|---|---|
| weatherCardTitle | Thời tiết hai nơi | Weather here and there |
| weatherUpdatedAt(time) | Cập nhật {time} (spec) | Updated {time} |
| weatherStaleAt(time) | Số liệu lúc {time} (spec) | As of {time} |
| weatherLoadFailed | Chưa tải được thời tiết (spec) | Couldn't load the weather |
| weatherRetry | Thử lại | Try again |
| weatherMe | Mình | You |
| weatherWhereAmI | Mình đang ở đâu? (spec) | Where are you? |
| weatherWhereIsPartner(name) | {name} đang ở đâu? (spec) | Where is {name}? |
| weatherChoose | Chọn | Choose |
| weatherChooseForPartner | Chọn giúp (spec) | Choose for them |
| weatherInvitePartnerTitle | Xem thời tiết chỗ người ấy (spec) | See the weather where your love is |
| weatherInvitePartnerBody(name) | Chọn chỗ mình và chỗ {name}, sáng nào mở app cũng thấy. | Pick your city and {name}'s. It'll be here every morning. |
| weatherInviteSelfTitle | Xem thời tiết chỗ mình (spec) | See the weather where you are |
| weatherInviteSelfBody | Chọn thành phố, sáng nào mở app cũng thấy. | Pick your city. It'll be here every morning. |
| weatherHide | Ẩn | Hide |
| weatherHideA11y | Ẩn thẻ thời tiết | Hide the weather card |
| weatherSameCity(city) | Cả hai cùng ở {city} (spec) | You're both in {city} |
| weatherColder(name, n) | Chỗ {name} lạnh hơn {n}° (spec) | {n}° colder where {name} is |
| weatherWarmer(name, n) | Chỗ {name} nóng hơn {n}° (spec) | {n}° warmer where {name} is |
| weatherCtaUmbrella / Water / Warm | Nhắc mang ô / Nhắc uống nước / Nhắc mặc ấm (spec) | Remind: umbrella / Remind: water / Remind: dress warm |
| weatherCtaA11y(name, action) | Nhắc {name} mang ô (…uống nước / …mặc ấm) | Remind {name} to take an umbrella (…drink water / …dress warm) |
| câu tình trạng + mô tả trời | đúng bảng §6.2 + §6.3 spec | đúng bảng spec |
| weatherDetailTitle | Thời tiết hai nơi | Weather here and there |
| weatherRestOfDay(min, max) | Từ giờ tới khuya {min}° – {max}° | Rest of today {min}° to {max}° |
| weatherPartnerSelfSet(name) | {name} tự chọn | {name} picked this |
| weatherSetByMe | mình chọn giúp | you picked this |
| weatherChangeCity | Đổi thành phố (spec) | Change city |
| weatherChangeForPartner | Đổi giúp | Change for them |
| weatherTheirTimeNow(time) | bây giờ {time} | it's {time} there |
| weatherPickerTitleSelf | Mình đang ở đâu? (spec) | Where are you? |
| weatherPickerTitlePartner(name) | {name} đang ở đâu? (spec) | Where is {name}? |
| weatherPickerSubSelf | Chỉ cần tên thành phố, app không xin vị trí. | Just the city. The app never asks for your location. |
| weatherPickerSubPartner(name) | {name} vẫn tự đổi được sau. | {name} can still change it later. |
| weatherSearchHint | Tìm thành phố hoặc tỉnh | Search a city or province |
| weatherClearSearch | Xoá chữ đã gõ | Clear search |
| weatherGroupCurrent / Vn / Intl | Đang chọn / Việt Nam / Nước ngoài | Current / Vietnam / Abroad |
| weatherOldProvince(name) | Tỉnh cũ: {name} | Formerly {name} |
| weatherNoMatch | Chưa có thành phố này. Chọn nơi gần nhất nhé. (spec) | That city isn't on the list yet. Pick the closest one. |
| weatherPartnerJustSet(name) | {name} vừa tự chọn chỗ của mình rồi. | {name} just picked their own city. |
| weatherSource | Dữ liệu thời tiết: (+ "MET Norway") (spec) | Weather data: (+ "MET Norway") |
| weatherSettingsSection | Thời tiết hai nơi | Weather here and there |
| weatherSettingsMine | Chỗ mình | Your city |
| weatherSettingsPartner(name) | Chỗ {name} | {name}'s city |
| weatherNotSet | Chưa chọn | Not set |
| weatherNotifToggle | Thời tiết chỗ người ấy (spec) | Weather where your love is |
| weatherNotifToggleSub(time, name) | Báo lúc {time} khi chỗ {name} mưa, nắng gắt hoặc lạnh. Tối đa 3 lần một tuần. | At {time}, only when it rains, gets very hot or turns cold where {name} is. Up to 3 times a week. |
| weatherNotifNeedsCouple | Ghép đôi xong mới báo được. | Available once you're paired. |
| weatherNotifTime | Giờ báo | Time |
| weatherNotifPreviewCaption(name) | Hôm nào chỗ {name} có mưa, thông báo sẽ như thế này: | On a rainy day where {name} is, you'll get this: |
| Lời quan tâm điền sẵn, thông báo sáng | đúng bảng §6.6, §6.7 spec | đúng bảng spec |

## 11. Thiết bị của design system được giữ (tasteskill cấm, chạy `--allow`)

| Rule | Thiết bị | Vì sao giữ |
|---|---|---|
| `heavy-shadow` | bóng `ContentCard` black .06 blur 16 y10 | chuẩn DUY NHẤT cho card trắng toàn app (design-unify A1); bỏ thì thẻ thời tiết khác mọi thẻ Home |
| `icon-chips` | `IconBadge` 44 r16 tint .12 ở đầu thẻ và hàng Cài đặt | primitive bắt buộc của Home/Settings (Đêm qua, Câu hỏi, Tâm trạng, mọi hàng Cài đặt đều có) |
| `micro-label` | `EyebrowChip` chữ hoa 11 ls1.4 (lời chào Home, "QUAN TÂM", "CÀI ĐẶT") | header 1 hệ toàn app (design-system §HEADER) |
| `button-fx` | pill chọn gradient của floating nav (chỉ trong `home.html` để thấy bối cảnh) | shell Home hiện có, feature không đụng |
| `emoji` | emoji trong gợi ý nhanh + nút "Gửi cho người ấy 💌" của màn Quan tâm | copy ARB hiện có (`careQuick*`, `careMessageSendCta`); feature không đổi màn này |
| `mixed-font-headline` | icon trời (phông IconsaxPlus) đứng cạnh số nhiệt độ | trong Flutter là widget `Icon`, không phải đổi phông giữa dòng |
| `tabular` | số dùng chữ số tỉ lệ | Quicksand không có tính năng `tnum` (đã kiểm bằng fontTools: chỉ có ccmp, dnom, frac, liga, locl, numr); số nhiệt độ không xếp cột so từng chữ số |
| (lint, có `taste-skill-ignore`) `gradient` | nền `dawnBlush` | nền mọi màn của app |
| WARN `colour-sprawl` (không allow, giải trình) | 19–38% màn "có màu" | toàn bộ là nền dawnBlush; trong thẻ chỉ có chấm màu người, icon tint và nút navy |
| WARN lint `shadow`, `glass` | bóng của `EyebrowChip`/card, kính của nav | như trên |

## 12. Kết quả lint / inspect và 3 vòng critique

**Lệnh:** `node ~/.claude/skills/design-taste-frontend/scripts/lint.mjs --app docs/design/weather` và `node …/inspect.mjs --app docs/design/weather/<màn>.html --widths 390 --allow heavy-shadow,icon-chips,button-fx,emoji,mixed-font-headline,micro-label,tabular --out .taste-skill/weather/<vòng>-<màn>`. **Chỉ đo 390** vì app chỉ chạy trên điện thoại dọc (khoá portrait từ audit 2026-10-12).

**Cuối cùng:** lint 0 FAIL, 11 WARN (8 bóng của card/chip/nav, 2 `padStart` cho giờ "07:30", 1 kính nav). Inspect 9 trang: **0 FAIL**; `detail`, `picker`, `picker-partner`, `picker-empty`, `notification` 0 WARN; `home`, `states`, `care`, `settings` còn 1 WARN `colour-sprawl` (nền dawnBlush, giải trình ở §11). Vòng đầu (chưa allow): home 3 FAIL, states 1 FAIL, care 2 FAIL, settings 1 FAIL, đều là thiết bị brand ở §11.

Trả lời 7 câu §2.7 (app screen, không dùng thang điểm trang):

**ROUND 1** (`.taste-skill/weather/r1-*`)
1. Câu hỏi được trả lời bởi thứ to nhất? Có: số 30 + câu tình trạng ở làn người ấy là thứ đọc đầu, nút ngay dưới.
2. Mép chung? **Không** ở Cài đặt: vạch ngăn làm bằng `margin-left` đẩy cả hàng lệch 56px, công tắc và chip giờ tràn khỏi card.
3. Màu chỉ trên dữ liệu và hành động? Có: màu người chỉ ở chấm, navy cho nút.
4. Số khớp? Có, 25 assert PASS (29 − 23 = 6°, ngưỡng 35/15, thước 22–33).
5. Zero/dash? Trạng thái lỗi vẽ "–°" thành "_°" và lặp câu lỗi hai lần.
6. Nhãn đè nhau? Không. Nhưng icon Bold dùng nhầm mã của bản Linear: dấu chọn ở sheet chọn hiện thành "≡", tim trong chip Quan tâm vỡ.
7. Trên điện thoại? Ô tìm: nút xoá hiện khi chưa gõ, gợi ý "…gõ không dấu cũng được" bị cắt; danh sách VN theo thứ tự tỉnh mới, khó dò.
Sửa 3 lỗi nặng: (1) vạch ngăn Cài đặt chuyển sang `::before` thụt 56, hàng không lệch; (2) mã icon Bold đúng (`tick_circle` 0xec30, `heart` 0xea9c); (3) ô tìm: ẩn nút xoá khi trống, gợi ý "Tìm thành phố hoặc tỉnh", VN = 6 thành phố TW trước rồi A→Z. Kèm: bỏ "–°", câu lỗi gom về hàng chung với nút Thử lại; tiêu đề thẻ tiếng Anh xuống dòng ở r0 → dời dòng giờ xuống dưới tiêu đề.

**ROUND 2** (`r2-*`)
1–4. Đạt.
5. "Hà Nội" xuất hiện hai lần trong sheet chọn (nhóm Đang chọn và nhóm Việt Nam).
6. Khối xem trước thông báo trong Cài đặt dùng phông hệ thống, sai: đó là widget của app nên vẽ bằng Quicksand (inspector báo `font-count` 3 phông).
7. Sheet chi tiết không có nút gợi ý: người mở sheet để xem mưa lúc mấy giờ phải đóng sheet mới nhắc được.
Sửa: bỏ dòng trùng ở nhóm dưới; xem trước về Quicksand (thông báo thật trên màn khoá vẫn phông máy); thêm nút gợi ý dưới thước của khối người ấy (đề xuất, §13).

**ROUND 3** (`r3-*`, `final-*`)
1. Có. 2. Mọi khối chung mép trái 32 (gutter 16 + đệm 16), không dải chết. 3. Có. 4. Có. 5. Không còn ô trống lạ; số cũ xám + đồng hồ. 6. Không đè. 7. Đạt ở 390 và chữ 130%.
Còn yếu (không sửa trong phạm vi design này):
- Bản tiếng Anh cắt "Ho Chi Minh …" trên làn (tên en dài 16 ký tự). Sheet chi tiết hiện đủ. Muốn hết thì PO thêm tên ngắn "HCMC" cho thẻ.
- Số cũ chỉ khác số tươi ở màu xám và icon đồng hồ; dòng "Số liệu lúc 21:40" gánh phần nghĩa.
- Home sẽ có 5–6 thẻ cùng khuôn `IconBadge` + tiêu đề 16 w800 xếp liền nhau. Đây là việc của người ghép Home.
Tự chấm (thang critique.md, chỉ để so vòng): design 7.5 · usability 8 · creativity 6.5 · content 8 → **7.5**.

## 13. Lệch spec / đề xuất cho PO và câu hỏi

**Đề xuất (Designer tự làm trong mockup, PO gạch được):**
- Nút gợi ý có thêm trong sheet chi tiết (khối người ấy).
- Dòng "Tỉnh cũ: Bình Thuận" khi kết quả khớp nhờ tên tỉnh cũ; nhóm "Đang chọn" đầu danh sách.
- "Từ giờ tới khuya 25° – 33°" thay "cao/thấp hôm nay" (vì CF không trả giờ đã qua, §9.3).
- Khác múi giờ: hiện "bây giờ 10:10" ở khối người ấy.
- Câu phụ thẻ thu gọn, câu phụ sheet chọn ("app không xin vị trí", "Thảo vẫn tự đổi được sau"), SnackBar khi người ấy vừa tự chọn: copy mới, ở bảng §10.
- Công tắc thông báo nằm trong section "Thời tiết hai nơi" ở Cài đặt (một chỗ cho mọi thứ về thời tiết), không tách sang nhóm Thông báo như D13 ghi.

**Câu hỏi:**
1. **Giờ báo có cho đổi không?** Spec D13 cố định 07:30; brief của Lead ghi "bật/tắt, giờ". Mockup có hàng "Giờ báo" (gợi ý giới hạn 05:00–10:00, cửa sổ 14 giờ tính từ giờ đã chọn). PO giữ cố định thì bỏ hàng này, câu phụ vẫn ghi 07:30.
2. **Thứ tự làn:** thẻ này để người ấy bên trái, mình bên phải (câu hỏi của thẻ là về người ấy, nút nhắc nằm ngay dưới cột người ấy). Thẻ Đêm qua đang để mình bên trái. Người ghép Home chốt một thứ tự chung cho mọi thẻ hai làn?
3. **Chữ "Mình" hay "Bạn":** spec dùng "Mình", thẻ Đêm qua đang hiện "Bạn" (`sleepYou`). Hai thẻ cạnh nhau nên dùng chung một chữ.

## 14. Soát UX (UI UX Pro Max 2.13.0)

Chạy `python3 …/ui-ux-pro-max/scripts/search.py "<truy vấn>" --domain|--stack …` (không `-I`). Truy vấn rỗng/lạc đề đã chạy lại 1 lần.

| Truy vấn | Kết quả dùng | Áp vào đâu |
|---|---|---|
| "search filter list diacritics" `--domain ux` | No Results: không để trang trắng, gợi ý cách khác; Autocomplete: lọc ngay khi gõ | câu "Chọn nơi gần nhất nhé"; lọc từng ký tự, không cần Enter |
| "empty state first action" `--domain ux` | Empty state = câu giúp + hành động | thẻ thu gọn có câu + chạm mở sheet; cột trống có nút Chọn giúp |
| "stale data offline indicator" `--domain ux` (lạc đề) → "offline network error retry" | lỗi phải được đọc ra (role=alert), không chỉ bằng màu | câu lỗi `liveRegion`, kèm icon/nút Thử lại |
| "skeleton loading layout shift" `--domain ux` | giữ chỗ để nội dung không nhảy khi thay skeleton | skeleton đúng cỡ số/icon/câu |
| "loading indicator feedback" `--domain ux` | skeleton ổn định, báo bận cho trình đọc | `aria-busy` → `Semantics` bận khi tải |
| "touch target size spacing" `--domain ux` | 44pt iOS / 48dp Android, cách nhau ≥8 | mọi nút ≥44, dòng chọn 52; ghi chú: Android Material mặc định 48 cho `TextButton` nên giữ `minimumSize` theme |
| "color not only meaning" `--domain ux` | không truyền tin chỉ bằng màu | tên người cạnh chấm; icon mưa khác icon mây |
| "reduced motion animation" `--domain ux` | tôn trọng Reduce Motion; 1–2 chuyển động mỗi màn | chỉ cross-fade số + `AnimatedSize`, tắt khi Reduce Motion |
| "notifications spam interrupt" `--domain ux` | (không có luật về tần suất push, chỉ về toast) | dùng trần của spec: 3 lần/7 ngày, không lặp loại hai ngày |
| "Semantics accessibility label" `--stack flutter` | `Semantics(label:)`, thử TalkBack/VoiceOver | §8 |
| "list performance ListView builder" `--stack flutter` | `ListView.builder` cho danh sách dài, `itemExtent` khi đều | sheet chọn 114 dòng (dòng không đều vì có "Tỉnh cũ" → không đặt itemExtent) |
| "showModalBottomSheet DraggableScrollableSheet" `--stack flutter` | 0 kết quả, thử "bottom sheet modal" cũng 0 | theo khuôn sheet sẵn có của app |
| "rounded friendly mobile app" `--domain typography` | gợi ý cặp phông bo tròn (Varela Round + Nunito Sans) | KHÔNG đổi: app đã chốt Quicksand (bo tròn, đủ dấu tiếng Việt) |
| "tabular figures numbers" (0) → "number alignment data" `--domain typography` | gợi ý mono cho số | KHÔNG áp: một phông duy nhất toàn app; số không xếp cột |
| "romantic couple pink" / "weather app" `--domain color` | hồng #DB2777; xanh trời #0284C7 | KHÔNG áp: palette Sunset Romance cố định; thời tiết không cần màu riêng, màu đã dành cho hai người |

Soát chung các thành phần đứng cạnh nhau: (a) nút gợi ý trên thẻ dùng đúng khuôn nút "Bật" của thẻ Đêm qua (navy h44, nhãn 15 w600) nên hai thẻ cạnh nhau không lệch cỡ; (b) nút viền "Chọn giúp" và nút navy "Nhắc mang ô" không bao giờ cùng xuất hiện trên một thẻ ở cùng cột; (c) ba nút gợi ý dùng chung một khuôn, chỉ đổi icon/nhãn; (d) dòng nguồn giống hệt ở 3 chỗ. Type scale chỉ dùng 11/12/13/14/15/16/20/22/30 (không cỡ lẻ).

## 15. Acceptance (design)

- [x] Mọi trạng thái có hình (`states.html`, 18 thẻ + 3 ghi chú) và mô tả (§5)
- [x] Copy đủ vi + en (§10), copy spec giữ nguyên
- [x] Map từng phần sang widget có sẵn / widget mới (§1, §4, §9)
- [x] Token có nguồn trong `lib/theme/` + primitives (§4)
- [x] a11y: Semantics, vùng chạm ≥44, Reduce Motion (§6, §8)
- [x] lint + inspect 0 FAIL ở 390, 3 vòng critique (§12)
- [ ] PO trả lời 3 câu §13

## Nhật ký design
- [2026-10-20] [Designer] Thiết kế bản 1 feature weather theo tasteskill (app run §2.1–2.8, sheet chung editorial-greeting seed 1822703143, `--keep palette,type`) + UI UX Pro Max. Face "ba làn": người ấy · mình · làn chung; signature "hai nơi trên một thước nhiệt độ". Mockup bấm thử 9 trang ở `docs/design/weather/` (thẻ Home 21 trạng thái, sheet chi tiết, sheet chọn có tìm không dấu chạy thật, màn Quan tâm điền sẵn, Cài đặt, thông báo), dữ liệu cặp Tuấn ♥ Thảo với 25 assert PASS. Lint 0 FAIL; inspect 0 FAIL trên 9 trang ở 390, allow 7 rule cho thiết bị của design system. 3 vòng critique, sửa: hàng Cài đặt tràn, icon Bold sai mã, ô tìm, dòng trùng, phông xem trước, thêm nút gợi ý trong sheet chi tiết. 3 câu hỏi cho PO.
- [2026-10-20] [Lead] Bỏ hàng "Giờ báo" trong mục Cài đặt (mockup `settings.html` đã sửa): giờ báo cố định 07:30 theo D13. Thẻ hai người trên Home đổi thứ tự thành bạn bên trái, người ấy bên phải, nhãn "Bạn" — Designer ghép Home áp dụng.
