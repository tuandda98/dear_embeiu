# 🎨 Design — Chạm tim (poke)

> Designer sở hữu. Đọc [`overview.md`](overview.md) trước (D1–D17). Bám design system hiện tại của app ([`../../design-system.md`](../../design-system.md), `lib/theme/`, primitives `lib/widgets/`): user chốt 2026-10-20 "không làm lại app, follow theo system design hiện tại", "giữ đồng hồ chạy", "giữ navy làm ngoại lệ". CHỈ thiết kế, không code.

- **Trạng thái design:** xong, chờ PO duyệt (câu hỏi ở §13)
- **Người/role:** Designer
- **Mockup bấm thử** (mở thẳng file, không cần mạng; thêm `?lang=en` để xem bản tiếng Anh, `?zoom=3` để soi chi tiết):
  - [`docs/design/poke/home.html`](../../../docs/design/poke/home.html): lối vào Home, 11 trạng thái
  - [`docs/design/poke/widget.html`](../../../docs/design/poke/widget.html): 4 bố cục × 2 nền + trạng thái
  - [`docs/design/poke/push.html`](../../../docs/design/poke/push.html): khay thông báo iOS + Android
  - [`docs/design/poke/settings.html`](../../../docs/design/poke/settings.html): công tắc bật/tắt
  - Dữ liệu mẫu [`data.js`](../../../docs/design/poke/data.js) (có `console.assert`, 0 lỗi) · token [`poke.css`](../../../docs/design/poke/poke.css) · thành phần [`ui.js`](../../../docs/design/poke/ui.js)
- **Quy trình:** tasteskill v2 chạy trọn run màn app (§2.1–2.8 của `references/app-screens.md`) với sheet chung của đợt `docs/design/daily-open-2/sheet.raw.md` (editorial-greeting, seed 1822703143, `--keep palette,type`) + UI UX Pro Max 2.13.0.

## 1. Màn và luồng

| # | Màn / thành phần | Ai thấy | Ghi chú |
|---|---|---|---|
| 1 | **Hàng tên + tim trên CounterCard** (`PokeCoupleRow`, mới) | cặp `active` | Thay `AnimatedCoupleName` trong slot `headerExtra`. Không thêm thẻ mới. |
| 2 | **Nút tim trên widget** iOS 17+ nhỏ/vừa, Android 2×2/4×2 | cặp `active` + có token (`pokeEnabled = '1'`) | Nằm cạnh số ngày. Dòng trạng thái loại `poke` đi theo widget-today. |
| 3 | **Thông báo đẩy gộp 1 dòng** | người nhận, công tắc bật | iOS `apns-collapse-id: poke`, Android tag `poke` + kênh `pokes`. |
| 4 | **Công tắc "Báo khi người ấy chạm tim"** | Cài đặt → Thông báo | Mặc định bật. |

Luồng chính (Tuấn gửi, Thảo nhận):

```
Tuấn chạm tim (Home hoặc widget)
  → tim nảy + rung nhẹ, số của Tuấn +1 NGAY (lạc quan, không chờ mạng)
  → app gộp các chạm trong 1,5 giây thành 1 request / widget gửi mỗi chạm
       ├─ mất mạng → xếp hàng, Home ghi "Mất mạng. 3 lần chạm sẽ tự gửi khi có sóng", widget viền đĩa nét đứt
       └─ OK → server trả mine/partner
Máy Thảo
  ├─ app đang mở Home → rung + 3 tim nhỏ bay lên từ nút, câu đổi "Tuấn vừa nhớ mình" 4 giây, KHÔNG banner
  ├─ app nền / tắt → 1 dòng thông báo, lần sau thay lần trước ("Tuấn nhớ bạn 5 lần rồi 💗")
  │     └─ chạm → Home (tab 0)
  └─ widget → dòng trạng thái "Tuấn nhớ mình 5 lần" + số dưới tim (đánh thức ≤ 1 lần/15 phút, D7)
Thảo chạm tim gửi lại → vòng lặp xong.
```

## 2. Kiểm kê dữ liệu và việc (§2.1)

- **Đối tượng:** doc ngày `pokes/{YYYY-MM-DD}`: `counts{uid}`, `lastAt{uid}`. Hiển thị: số của mình (m), của người ấy (p), tổng (m+p), giờ chạm cuối của người ấy.
- **Độ lớn thật:** cặp bình thường 5–20 chạm/ngày, dồn thành vài đợt; sáng sớm là 0. Trần 300 request/ngày (gần như không ai chạm tới). Mẫu: Tuấn 7, Thảo 5, tổng 12 lúc 14:32; push cuối 14:30 ghi tổng 11 vì lúc đó Tuấn mới chạm 6 lần (assert trong `data.js`).
- **Người dùng:** cặp đôi trẻ Việt, điện thoại, liếc vài giây nhiều lần trong ngày; widget là chỗ liếc nhiều nhất.
- **Việc hay làm nhất:** chạm tim (gửi). Việc thứ hai: biết người ấy vừa nhớ mình.
- **Đồ riêng của sản phẩm:** tên hai người, trái tim vốn đã đập giữa hai tên trên thẻ đếm, số ngày 1.255, đồng hồ tổng giờ, trời đêm có chòm sao trái tim trên widget, màu người (`person_palette.dart`).

## 3. Câu hỏi, phát hiện, việc chính của từng màn (§2.2)

| Màn | Câu hỏi một dòng | Phát hiện (one finding) đặt ở đâu | Việc chính, một chạm |
|---|---|---|---|
| Home | Hôm nay người ấy có nhớ mình không? | Câu dưới hàng tên: "Hôm nay nhớ nhau 12 lần: mình 7, Thảo 5" / "Thảo nhớ mình 3 lần hôm nay" | Nút tim giữa hai tên |
| Widget | Hôm nay người ấy có nhớ mình không? | Dòng trạng thái `poke` "Thảo nhớ mình 5 lần" + số tổng dưới tim | Nút tim cạnh số ngày, không mở app |
| Thông báo | Ai vừa nhớ mình, mấy lần rồi? | Tiêu đề thông báo (đếm tăng dần trên cùng 1 dòng) | Chạm mở Home để gửi lại |
| Cài đặt | Tắt cái này thì mất gì? | Dòng phụ cho xem trước thông báo: "Kiểu “Thảo nhớ bạn 5 lần rồi”" | Công tắc |

Khối lớn nhất của Home vẫn là số ngày 1.255 (76px) đúng như app hiện tại: user giữ thẻ đếm làm câu trả lời chính của Home. Tim là nút duy nhất có nền trắng đặc trên thẻ nên vẫn được nhìn thấy ngay sau tên.

## 4. Gương mặt (face) và chữ ký (§2.3)

- **Face (chọn từ sheet):** *"cặp đôi là ba làn: người này · chung · người kia".* Hàng tên trên CounterCard thành ba làn: tên trái · tim (phần chung) · tên phải. Câu dưới liệt kê số theo đúng thứ tự làn (máy người bên trái: "mình 7, Thảo 5"; máy người bên phải: "Tuấn 7, mình 5").
- **Chữ ký (chỉ sản phẩm này có):** *trái tim vốn đã đập giữa "Tuấn ♥ Thảo" giờ là cái nút.* Không thêm thẻ, không thêm màn; chỗ quen nhất trên Home được thêm việc. Thử với đối thủ: Between có "Thumbkiss" ở màn riêng, Locket/Widgetable có nút trên widget, không app nào đặt nút giữa tên hai người trên bộ đếm ngày.
- **Trên widget:** tim nằm ngay sau số ngày ("1.255 ♥"), số tổng dưới tim. Ngày bên nhau và lần nhớ hôm nay đọc liền một cụm.
- **Màu người** (`personPalette`) KHÔNG dùng ở đây: trên thẻ hồng và widget đêm, luật app là chữ trắng; làn phân biệt bằng vị trí + tên, không bằng màu.

## 5. Map sang widget Flutter / native

| Phần | Dùng lại | Mới |
|---|---|---|
| Thẻ đếm | `lib/widgets/counter_card.dart` (giữ nguyên, kể cả đồng hồ `_LiveElapsedClock`, aurora, nền ảnh) | — |
| Hàng tên + tim | thay `AnimatedCoupleName` trong `headerExtra` ở `home_screen.dart` (~dòng 1955) | **`lib/widgets/poke_couple_row.dart`**: `PokeCoupleRow` + `PokeHeartButton` |
| Cặp chờ người ấy | `AnimatedCoupleName` như hiện tại | — |
| Widget iOS | `SmallCounter`, `MediumCounter`, `NamesChip`/`ChipPill` (màu đĩa), `StatusLine`, `AccentedReader` trong `DayCounterView.swift` | **`PokeButton`** (iOS 17, `Button(intent: SendPokeIntent())`) |
| Widget Android | `widget_day_small.xml`, `widget_day_medium.xml`, `widget_chip_bg_dark`/chip trắng làm nền đĩa | **`widget_poke_col`** (LinearLayout dọc: `ImageView` đĩa + `TextView` số), drawable `widget_poke_disc_dark`, `_dark_sent`, `_light`, `_pending` (nét đứt) |
| Cài đặt | `SwitchListTile.adaptive` + `IconBadge` + `_rowDivider()` y như `_AnalyticsToggleTile` / hàng âm lịch trong `settings_screen.dart` | **`_PokePushToggleTile`** |
| Thông báo | kênh/handler có sẵn (`push_notification_service.dart`) | kênh Android `pokes` (tên hiển thị trong Cài đặt máy: "Chạm tim" / "Hearts") |

## 6. Spec chi tiết

### 6.1 Home — `PokeCoupleRow` (thay `AnimatedCoupleName` trong `headerExtra`)

```
┌──────────────── CounterCard (r28, sunsetRomance, padding 28/24/26) ───────────────┐
│          Tuấn  ( ♥ )  Thảo                ← tên 20 w700 trắng · đĩa 44 trắng .92    │
│   Hôm nay nhớ nhau 12 lần: mình 7, Thảo 5  ← 13 w700 trắng, cách hàng tên 8         │
│        ── HAI BẠN ĐÃ BÊN NHAU ──           ← cách câu 14 (cũ: cách tên 12)          │
│                  1.255                      ← không đổi                             │
│                  NGÀY                                                               │
│         ( 30.134 : 32 : 05 )                ← đồng hồ giữ nguyên, vẫn chạy          │
│   ⚑ Cột mốc 1.500 ngày         còn 245 ngày                                        │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━░░░░░░                                              │
│        (★ 92 ngày kết nối · hôm nay xong rồi)                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

| Phần tử | Token |
|---|---|
| Hàng | `Row`: `Expanded(Text name1, textAlign: right, ellipsis)` · `SizedBox(12)` · nút 44 · `SizedBox(12)` · `Expanded(Text name2, textAlign: left, ellipsis)`. Thứ tự tên giữ như `AnimatedCoupleName` (người tạo couple bên trái) để cả hai máy thấy giống nhau. |
| Tên | 20 w700 `AppColors.white`, như `textStyle` đang truyền vào `AnimatedCoupleName` |
| Nút tim | Đĩa 44×44 `white .92` (cùng họ "đĩa trắng .92 + mực loveDeep" của đĩa bút chì hero Profile), không viền, không bóng. Icon 22 `accentLoveDeep`: `IconsaxPlusLinear.heart` khi m = 0, `IconsaxPlusBold.heart` khi m > 0 (hình đổi, không chỉ màu đổi). `InkWell` `customBorder: CircleBorder()`, splash `accentLoveDeep .12`. |
| Câu dưới | 13 w700 trắng 100%, bóng `black .28 blur 8 offset(0,1)` (luật chữ trắng trên nền sáng), căn giữa, `maxLines: 2`, cách hàng 8. Cùng cỡ/độ đậm với dòng cột mốc trong thẻ. |
| Khoảng cách | headerExtra → eyebrow: 14 (thay 12) |
| Chiều cao thêm | ≈ +42px so với hiện tại (26 → 44 hàng, +8+18 câu). |

**Câu dưới theo số** (viewer = người xem; "bên trái" = viewer là người tạo couple):

| Điều kiện | VI | EN |
|---|---|---|
| m = 0, p = 0 | Chạm tim để {name} biết mình đang nhớ | Tap the heart to let {name} know you're thinking of them |
| m = 0, p > 0 | {name} nhớ mình {p} lần hôm nay | {name} thought of you {p, plural, =1{once} other{{p} times}} today |
| m > 0, p = 0 | Mình đã nhớ {name} {m} lần hôm nay | You thought of {name} {m, plural, =1{once} other{{m} times}} today |
| cả hai > 0, viewer bên trái | Hôm nay nhớ nhau {t} lần: mình {m}, {name} {p} | {t} hearts today: you {m}, {name} {p} |
| cả hai > 0, viewer bên phải | Hôm nay nhớ nhau {t} lần: {name} {p}, mình {m} | {t} hearts today: {name} {p}, you {m} |

### 6.2 Widget — tim cạnh số ngày

Vị trí: **bên phải số ngày**, số tổng nằm dưới tim ngang hàng chú thích "ngày bên nhau". Lý do chọn chỗ này (đã đo trên mock, không đoán):
- Góc trên phải: chip "TUẤN ♥ THẢO" đã rộng ≈95pt trong vùng nội dung 126pt (iOS nhỏ) / 120dp (Android 2×2), không còn chỗ cho vùng chạm 44/48. Tên 5+ chữ (PHƯƠNG, TRANG) sẽ bị cắt.
- Góc dưới phải: dòng trạng thái widget-today cần cả chiều ngang để không cắt câu.
- Cạnh số: không đẩy số ngày lệch chỗ, không đụng dòng trạng thái, chòm sao vẫn ở góc trên phải như 1.9.1.

```
iOS nhỏ 158×158pt (nội dung 126)        iOS vừa 338×158pt
┌──────────────────────────┐            ┌────────────────────┬──────────────────────┐
│ (TUẤN ♥ THẢO)    ✦──✦    │            │ (TUẤN ♥ THẢO)      │ Cột mốc 1.500   ✦──✦ │
│                ✦  ✦  ✦   │            │                    │ ━━━━━━━━━━━━━░░      │
│ 1.255  (♥)               │ ← số co    │ 1.255 (♥)          │ còn 245 ngày         │
│ ngày bên nhau  12        │   ≤ 0,95   │ ngày bên nhau  12  │ ● Thảo nhớ mình 5    │
│ ● Thảo nhớ mình 5 lần    │            │                    │   lần hôm nay        │
└──────────────────────────┘            └────────────────────┴──────────────────────┘

Android 2×2 ≈152dp                       Android 4×2 ≈328dp: như iOS vừa, cột tim 48dp
┌──────────────────────────┐
│ (TUẤN ♥ THẢO)    ✦──✦    │ paddingEnd nội dung 16 → 8dp (setViewPadding) khi có tim
│ 1.255 [ (♥) ]            │ số autosize 24–40sp → ≈33sp ở 4 chữ số
│ ngày bên nhau [ 12 ]     │ [ ] = cột 48dp bấm được, cao ≈68dp
│ ● Thảo nhớ mình 5 lần    │
└──────────────────────────┘
```

| Phần tử | iOS | Android |
|---|---|---|
| Đĩa | 30pt, căn giữa dọc với dòng số (cách đỉnh cột 8) | 32dp trong cột 48dp (cách đỉnh 7) |
| Vùng chạm | `Button` frame 44×44pt (tràn 7pt ra hai bên đĩa, phủ cả nửa trên số "12"); các vùng khác giữ `widgetURL` mở app | Cả cột 48×68dp `setOnClickPendingIntent` → `PokeReceiver` |
| Khoảng cách số ↔ đĩa | 6pt (nhỏ) · 8pt (vừa, tim ôm sát số) | 8dp (do cột 48 căn giữa đĩa 32) |
| Số ngày | `DayNumber` thêm trailing chừa 36pt; `minimumScaleFactor .6` sẵn có lo co (1.255 → ≈38pt ở nhỏ, 40 ở vừa) | Nhỏ: `widget_days` weight 1 autosize (≈33sp). Vừa: đủ chỗ, giữ 40sp |
| Đĩa, trời đêm (M2), m = 0 | `ChipPill(dark:)`: trắng .14 + viền trắng .22; tim viền `#FF8FA3` (blush) 16 | `widget_poke_disc_dark` cùng giá trị |
| Đĩa, trời đêm, đã chạm hôm nay | trắng .92, tim đặc `#E63956` | `widget_poke_disc_dark_sent` |
| Đĩa, nền ảnh (P3) | trắng .84 (như chip tên trên ảnh), tim `#E63956`: viền khi m = 0, đặc khi m > 0 | `widget_poke_disc_light` |
| Đang chờ mạng | Viền nét đứt 1,5pt (dash 3/3) trắng .75 trên đêm / `#E63956` trên ảnh, bỏ nền viền thường | `widget_poke_disc_pending` (`<stroke android:dashWidth="3dp" android:dashGap="3dp">`) |
| Số tổng | 12 Bold trắng, `inkShadow()`, căn giữa dưới đĩa, chỉ hiện khi tổng > 0, `>99` hiện `99+` | 12sp bold, bóng `#4D000000` dy1 r8 |
| Tinted / Clear (iOS 18/26) | đĩa trắng .22 không viền khi `.accented`; tim + số `widgetAccentable()`; trạng thái đã gửi đọc bằng hình tim đặc | — |
| Cỡ chữ AX | số tổng chặn `...xxxLarge` như `StatusLine` | `textSize` sp, maxLines 1 |

- **Dòng trạng thái `poke`:** đúng spec widget-today (chấm + câu, nhỏ 12 co tới 10 rồi mới "…", vừa 14 tối đa 2 dòng). Copy ở §9.
- **Không có tim** (iOS 15–16, chờ người ấy, chưa đăng nhập, gallery preview, chưa có token): bố cục y hệt widget-today hiện tại, từng pixel. Android trả `paddingEnd` về 16dp.
- **Bản nhỏ có tim + có trạng thái** vẫn vừa: 20 chip + ≥4 + 46 số + 21 chú thích + 21 trạng thái = 112 ≤ 126.

### 6.3 Thông báo đẩy

Không vẽ gì riêng: thông báo hệ thống dùng icon app, copy theo spec D6 (§9). Mock [`push.html`](../../../docs/design/poke/push.html) cho thấy 08:05 (lần đầu) và 14:30 (lần 5, thay đúng dòng cũ). Android: small icon giữ `@mipmap/ic_launcher` như các kênh khác; kênh `pokes` tên "Chạm tim" / "Hearts", mô tả "Khi người ấy chạm tim nhớ bạn" / "When your partner sends you a heart".

### 6.4 Cài đặt

- Vị trí: nhóm **Thông báo**, sau `_DecisionReminderTile`, trước hàng "Lời nhắc". Nếu feature `arrival` thêm công tắc `pushArrival` thì hai công tắc "từ người ấy" đứng liền nhau (poke trước), cùng kiểu hàng.
- Hiện khi couple `active` (giống `_DecisionReminderTile`).
- `SwitchListTile.adaptive` · `activeThumbColor: AppColors.accentRose` · `contentPadding: EdgeInsets.symmetric(vertical: 4)` · `secondary: IconBadge(IconsaxPlusBold.heart)` khi bật / `IconsaxPlusLinear.heart` khi tắt · title 15 w700 `textPrimary` · subtitle 12 `textSecondary` height 1.4, cách title 4. Tiêu đề được xuống 2 dòng trên máy hẹp (đo ở 390: "Báo khi người ấy / chạm tim").
- Dòng phụ đổi theo trạng thái và dùng tên người ấy thật (§9) = "cho xem trước thứ mình bật".
- Lưu ngay khi gạt (như mọi công tắc Cài đặt), `HapticFeedback.selectionClick()`.

## 7. Trạng thái

### Home
| Trạng thái | Nút | Câu dưới |
|---|---|---|
| 0 lần (sáng sớm) | tim viền, thở nhẹ | "Chạm tim để Thảo biết mình đang nhớ" (không in 0) |
| Người ấy nhớ trước | tim viền | "Thảo nhớ mình 3 lần hôm nay" |
| Đã chạm | tim đặc | câu theo bảng §6.1 |
| Vừa chạm | nảy 1,18 lần, rung nhẹ | số của mình +1 ngay |
| Vừa nhận (app đang mở) | 3 tim nhỏ bay lên, rung vừa | "Thảo vừa nhớ mình" 4 giây rồi về câu tổng; KHÔNG banner |
| Mất mạng | bấm được | "Mất mạng. {q} lần chạm sẽ tự gửi khi có sóng" tới khi hàng đợi rỗng |
| Đang tải lần đầu | bấm được (xếp hàng nếu chưa có token) | thanh phẳng 176×12 trắng .30 r999, không shimmer (shimmer xám lạc nền hồng) |
| Lỗi đọc doc ngày | bấm được | "Chưa xem được số hôm nay. **Thử lại**" (nút chữ gạch chân, vùng chạm 44) |
| Chạm quá trần (429) | mờ .55, `onPressed: null` tới 0:00 | "Hôm nay chạm nhiều lắm rồi, mai chạm tiếp nhé" |
| 401 (token hỏng) | không đổi giao diện | app tự `register` lại rồi gửi; người dùng không thấy gì |
| Nền ảnh CounterCard | như trên, đĩa trắng .92 | chữ trắng + bóng tối như số ngày |
| Chờ người ấy / 403 | không có tim, `AnimatedCoupleName` như cũ | không có câu |
| Qua 0:00 | về trạng thái 0 lần (`MidnightBuilder`) | |

### Widget
0 lần (đĩa trong, tim viền, không số) · đã chạm (đĩa trắng, tim đặc, số tổng) · vừa chạm (iOS: `.contentTransition(.numericText())` cho số + `.transition(.scale)` khi tim đổi; Android đổi ngay) · mất mạng (viền nét đứt, số đã cộng) · tinted · không có tim. Sau 0:00 số mất, tim về viền (so ngày như widget-today D4.1).

### Cài đặt
Bật (mặc định) · tắt. Không có loading (đọc từ device doc đã có sẵn khi vào màn). Lỗi lưu: hoàn công tắc về giá trị cũ + SnackBar lỗi chung đang dùng ở Cài đặt.

## 8. Chuyển động, rung, trợ năng

- **Thở (idle):** giữ nhịp tim đập 820ms của `AnimatedCoupleName` (scale icon 1 → 1,08, repeat reverse) — chỉ icon, không phải đĩa. Reduce Motion: tĩnh.
- **Nhấn:** `AnimatedScale` 0,92 trong 100ms easeOutCubic.
- **Thả / gửi:** nảy 1 → 1,18 → 1 trong 280ms easeOutCubic (`AppMotion.base`), `HapticFeedback.lightImpact()`. Đổi icon viền → đặc bằng `AnimatedSwitcher` 200ms. Reduce Motion: chỉ đổi icon + số, rung giữ (rung không phải chuyển động).
- **Nhận khi đang mở:** 3 tim `IconsaxPlusBold.heart` 14 trắng, xuất phát từ tâm đĩa lệch (−30,−18) (−7,−30) (+16,−16), bay lên 28px + mờ 1 → 0 trong 900ms easeOutCubic, lệch nhau 80ms; `HapticFeedback.mediumImpact()`; câu `AnimatedSwitcher` 200ms. Nhiều lần nhận dồn trong 4 giây: chỉ phát 1 đợt tim/4 giây. Reduce Motion: không bay, chỉ đổi câu + rung. Tab ẩn (`TickerMode` off): không chạy.
- **Semantics:**
  - Nút: `Semantics(button: true, label: 'Gửi nhớ thương tới {name}', value: <câu dưới>)`; trạng thái 429 `enabled: false` + hint câu trần.
  - Nhận: `SemanticsService.announce('Thảo vừa nhớ mình', TextDirection.ltr)` tối đa 1 lần/15 giây (không đọc con số trơ, theo *Contextual Live Badge Updates*).
  - Câu dưới không phải live region riêng (tránh đọc mỗi lần số đổi).
  - Widget iOS: `.accessibilityLabel("Gửi nhớ thương tới Thảo. Hôm nay nhớ nhau 12 lần")`, thêm ". Đang chờ mạng để gửi" khi pending; số tổng `accessibilityHidden`. Android: `setContentDescription` trên cột tim cùng câu.
- **Vùng chạm:** Home 44 · iOS widget 44×44pt · Android widget 48×68dp · nút "Thử lại" cao 44. Khoảng cách tim ↔ tên 12 (≥8, *Touch Spacing*).
- **Dynamic Type:** hàng tên giữ 1 dòng (ellipsis), câu dưới tối đa 2 dòng.

## 9. Copy deck vi / en

Chuỗi push (D6), trạng thái widget (D8), inbox (D8) là **copy PO chốt, giữ nguyên văn**. Còn lại là Designer đề xuất. Đã soát theo humanizer (không "không phải X mà là Y", không câu kết kịch, chủ ngữ rõ) và bản EN theo avoid-ai-writing. Dấu kiểu mới; xưng "mình"/"bạn" như spec, không "hai đứa".

| Key (đề xuất) | VI | EN |
|---|---|---|
| `pokeHeartLabel` | Gửi nhớ thương tới {name} | Send {name} a heart |
| `pokeCaptionIdle` | Chạm tim để {name} biết mình đang nhớ | Tap the heart to let {name} know you're thinking of them |
| `pokeCaptionPartner` | {name} nhớ mình {count} lần hôm nay | {name} thought of you {count, plural, =1{once} other{{count} times}} today |
| `pokeCaptionMine` | Mình đã nhớ {name} {count} lần hôm nay | You thought of {name} {count, plural, =1{once} other{{count} times}} today |
| `pokeCaptionBothMeFirst` | Hôm nay nhớ nhau {total} lần: mình {mine}, {name} {partner} | {total} hearts today: you {mine}, {name} {partner} |
| `pokeCaptionBothPartnerFirst` | Hôm nay nhớ nhau {total} lần: {name} {partner}, mình {mine} | {total} hearts today: {name} {partner}, you {mine} |
| `pokeJustNow` | {name} vừa nhớ mình | {name} is thinking of you |
| `pokeQueued` | Mất mạng. {count} lần chạm sẽ tự gửi khi có sóng | Offline. {count} taps will send when you're back |
| `pokeLimit` | Hôm nay chạm nhiều lắm rồi, mai chạm tiếp nhé | That's a lot of hearts for one day. More tomorrow. |
| `pokeLoadError` | Chưa xem được số hôm nay. | Couldn't load today's count. |
| (có sẵn — Dev kiểm key "Thử lại") | Thử lại | Retry |
| `pokeWidgetLabel` | Gửi nhớ thương tới {name}. Hôm nay nhớ nhau {total} lần | Send {name} a heart. {total} hearts today |
| `pokeWidgetPending` | Đang chờ mạng để gửi | Waiting for a connection |
| `settingsPokeTitle` | Báo khi người ấy chạm tim | When your partner taps the heart |
| `settingsPokeOn` | Kiểu “{name} nhớ bạn 5 lần rồi”. Chạm nhiều vẫn chỉ một thông báo. | Like “{name} thought of you 5 times”. Many taps, one notification. |
| `settingsPokeOff` | Đang tắt. Máy im, mở app vẫn thấy {name} nhớ mình mấy lần. | Off. Your phone stays quiet; the app still shows the count. |
| kênh Android `pokes` (native) | Chạm tim · Khi người ấy chạm tim nhớ bạn | Hearts · When your partner sends you a heart |
| **PO D6** push title n=1 / n≥2 | {name} vừa nhớ bạn 💗 / {name} nhớ bạn {n} lần rồi 💗 | {name} is thinking of you 💗 / {name} thought of you {n} times 💗 |
| **PO D6** push body n=1 / n≥2 | Chạm tim để gửi lại một cái nhé. / Hôm nay chúng mình nhớ nhau {total} lần. | Tap the heart to send one back. / {total} hearts between you two today. |
| **PO D8** widget `statusText` | {name} vừa nhớ mình / {name} nhớ mình {n} lần hôm nay | {name} is thinking of you / {name} thought of you {n} times today |
| **PO D8** widget `statusTextShort` | {name} nhớ mình / {name} nhớ mình {n} lần | {name} misses you / {name} misses you ×{n} |
| **PO D8** inbox | {name} nhớ bạn {count} lần hôm nay | {name} thought of you {count} times today |

Đề xuất nhỏ cho PO (không tự đổi): inbox EN với count = 1 thành "{name} thought of you once today" (ICU plural) thay vì "1 times".

## 10. Thiết bị của brand giữ lại (`--allow`) và lý do

Theo mục "An existing brand or design system" của tasteskill: giữ thiết bị design system bắt buộc, chỉ allow đúng rule đó.

| Rule | Trang | Vì sao giữ |
|---|---|---|
| `gradient` | home, widget, settings | Nền `dawnBlush`, thẻ `sunsetRomance`, trời đêm navy M2 (user: "giữ navy làm ngoại lệ"), scrim ảnh. |
| `micro-label` | home, widget, settings | `EyebrowChip` (11 w700 ls1.4 IN HOA), eyebrow "HAI BẠN ĐÃ BÊN NHAU", nhãn đồng hồ GIỜ/PHÚT/GIÂY, chip tên widget. Thành phần MỚI không thêm nhãn in hoa nào. |
| `tiny-text` | home, widget | Nhãn đồng hồ 10 và chip widget 10 là bậc `10 micro-caps` của type scale. Thành phần mới nhỏ nhất 12. |
| `text-shadow` | home, widget | Luật app: chữ trắng trên nền sáng/ảnh dùng bóng TỐI mềm. |
| `heavy-shadow` | home, settings | Bóng CounterCard (rose .36 + lavender .18) và `ContentCard` (black .06 blur 16) có sẵn. Nút tim mới không có bóng. |
| `emoji` | push | 💗 nằm trong copy push PO chốt (D6). |
| `font-count` | push | Khay thông báo dùng phông hệ thống (SF / Roboto), không phải phông app. |
| lint `taste-skill-ignore` | poke.css, ui.js, data.js | Cùng các lý do trên (lavender `#A78BFA` là `accentLavender`, glass chỉ ở thẻ thông báo iOS mô phỏng hệ thống). |

WARN còn lại, có lý do: `colour-sprawl` 43% (Home) và `kpi-size` 76px — CounterCard là hero duy nhất của app, user giữ nguyên · `icon-tiles` (widget) — đĩa quanh tim là nút bấm được, không phải hộp trang trí · `icon-chips` (Cài đặt) — `IconBadge` là chuẩn mọi hàng Cài đặt · lint `numbering` — `padStart` cho phút/giây đồng hồ · lint `shadow` 2 chỗ — `inset` 1px thay viền của chip/đĩa trên nền đêm.

## 11. Soát UX (UI UX Pro Max 2.13.0)

Chạy `scripts/search.py` (không `-I`), 2026-10-20. Soát chung 4 thành phần đứng cạnh nhau trên thẻ: tên trái · nút tim · tên phải · câu dưới; và trên widget: số ngày · đĩa tim · số tổng · dòng trạng thái.

| Truy vấn | Kết quả | Áp dụng |
|---|---|---|
| `"touch target size small button" --domain ux` | *Touch Target Size* (High): 44pt iOS, 48dp Android | Home 44; widget iOS 44×44pt (đĩa 30 nhìn thấy, vùng chạm tràn); Android cột 48dp. |
| `"touch spacing adjacent targets" --domain ux` | *Touch Spacing*: ≥8px giữa vùng chạm | Tim ↔ tên 12. Widget: vùng chạm tim chiếm số "12" phía dưới, không có nút nào khác cạnh. |
| `"haptic" --domain ux` | *Haptic Feedback*: dùng cho xác nhận, đừng lạm dụng | Rung nhẹ khi gửi, rung vừa khi nhận; dồn nhận 4 giây chỉ rung 1 lần. |
| `"success feedback animation confirm" --domain ux` | *Success Feedback* / *Submit Feedback* | Gửi thành công thấy ngay: tim nảy + số +1, không toast. |
| `"optimistic update offline queue" --domain ux` | *Content Jumping* (High): giữ chỗ ổn định cho số/badge | Số tổng widget nằm ô cố định dưới tim; câu Home có `min-height` 1 dòng; loading là thanh đúng cỡ dòng chữ. |
| `"loading button state" --domain ux` | *Loading Indicators*: đừng chớp spinner cho việc gần như tức thì | Không spinner trên nút tim (gửi lạc quan). |
| `"reduce motion" --domain ux` · `"animations" --stack flutter` | *Reduced Motion*, *Excessive Motion* (1–2 phần tử chuyển động/màn) · *Use implicit animations* | Chỉ tim chuyển động; `AnimatedScale`/`AnimatedSwitcher`; Reduce Motion tắt thở + tim bay. |
| `"badge counter update" --domain ux` | *Contextual Live Badge Updates*: thông báo một câu có nghĩa, không đọc số trơ | `announce('Thảo vừa nhớ mình')`, nhãn widget đọc cả câu. |
| `"color only information" --domain ux` | *Color Only* (High) | Đã chạm / chưa chạm = tim đặc / tim viền; chờ mạng = viền nét đứt + câu chữ. |
| `"icon button accessibility label" --domain ux` · `"accessibility label button" --stack swiftui` · `"content description touch target" --stack jetpack-compose` · `"screen reader announce update" --stack flutter` | *Compact Label Overflow*; `.accessibilityLabel`; `contentDescription`; `Semantics(label:)` | Nhãn cho nút tim ở cả 3 nền tảng (§8). |
| `"dark background contrast small text" --domain ux` · `"text contrast gradient background" --domain color` | *Color Contrast* 4,5:1 | Chữ widget trên nền đêm ≈15:1. Câu Home trên thẻ hồng: trắng ≈2,5:1 trước bóng — xem §13 Q2 (nợ cũ của cả thẻ, không phải do feature). |
| `"font size scale" --domain typography` · `"rounded friendly font" --domain typography` | không khớp quy tắc cỡ chữ (ra cặp phông); "Soft Rounded" xác nhận hướng phông tròn | Chỉ dùng 12/13/14/15/20/22 trong type scale app; giữ Quicksand. |
| `"romantic pink couple app" --domain color` | "Couple & Relationship App": rose + love red | Khớp brand; không thêm màu mới. |
| `"haptic feedback tap button"`, `"switch toggle settings"`, `"gesture tap feedback"`, `"reduced motion animation"` `--stack flutter` · `"widget home screen glanceable" --stack swiftui` · `"notification spam frequency"`, `"tabular figures numbers"` | **0 kết quả** | Fallback: guideline Apple WidgetKit (Button(intent:) iOS 17, `widgetAccentable`), Android App Widgets, HIG notifications; số dùng figures mặc định của Quicksand (không có tabular). |

## 12. Kết quả tasteskill

**Style:** sheet chung đợt 2 `editorial-greeting` (seed 1822703143, `--keep palette,type`). Không redraw. Phần "move" của sheet (lời chào là h1, cột 12) không áp vào feature này vì đây là thành phần trên Home có sẵn; thứ lấy từ sheet là face "ba làn" và luật trạng thái (0 thật, gạch cho thiếu, lỗi trong khối, loading đúng cỡ).

**Gate cuối (chỉ đo 390px — app chỉ có trên điện thoại):**

| Trang | lint `--app` | inspect `--app --widths 390` | allow |
|---|---|---|---|
| home | 0 FAIL | 0 FAIL, 2 WARN | micro-label, gradient, text-shadow, heavy-shadow, tiny-text |
| widget | 0 FAIL | 0 FAIL, 1 WARN | micro-label, gradient, text-shadow, tiny-text |
| push | 0 FAIL | 0 FAIL, 0 WARN | emoji, font-count |
| settings | 0 FAIL | 0 FAIL, 1 WARN | gradient, heavy-shadow, micro-label |

lint cả thư mục: 0 FAIL, 3 WARN (đã giải thích §10). Ảnh chụp: `.taste-skill/poke/<trang>-final/` (+ r0, r1, r2).

**3 vòng nhìn và sửa** (đã mở mọi ảnh chụp, kèm ảnh phóng 3× bằng `?zoom=3`):

- **Vòng 1** (r0): (1) Android 2×2 số "1.255" đè lên đĩa tim vì mock chưa co chữ như autosize → thêm giả lập `minimumScaleFactor`/autosize, đo được số co còn 33sp; (2) iOS nhỏ số sát đĩa 2px → khe 6pt; (3) câu dưới tên trắng .92 w600 chìm trên hồng → 13 w700 trắng 100% + bóng tối; bỏ ký tự ♥ trong chữ tài liệu.
- **Vòng 2** (r1): (1) bản vừa tim trôi sát vạch chia, cách số 25px, số "12" lơ lửng → tim ôm sát số (8pt); (2) dòng trạng thái bản nhỏ bị cắt "Thảo nhớ mình 5 l…" vì mock chưa co 12→10 theo spec widget-today → co trước khi cắt, giờ hiện đủ; (3) câu Home "Thảo 5, mình 7" đọc ngược thứ tự làn (Tuấn trái, Thảo phải) → liệt kê theo thứ tự hàng tên.
- **Vòng 3** (r2 → final): (1) dòng phụ công tắc Cài đặt dài 3 dòng → rút còn 2–3 dòng ngắn hơn ("Kiểu “Thảo nhớ bạn 5 lần rồi”. Chạm nhiều vẫn chỉ một thông báo."); (2)–(3) thông báo và widget không còn lỗi nặng; ghi lại chỗ còn yếu bên dưới.

**7 câu §2.7 (vòng cuối):**
1. *Câu hỏi có được thứ lớn nhất trả lời không?* Trên Home thứ lớn nhất vẫn là số ngày (theo quyết định giữ thẻ đếm); câu hỏi của feature được trả lời ngay dưới hàng tên, trước cả eyebrow, và tim trắng là điểm sáng nhất sau số. Trên widget, câu trả lời nằm ở dòng trạng thái + số dưới tim. Chấp nhận, ghi ở Q1.
2. *Mép chung, dải chết?* Hàng tên căn giữa thẻ, câu căn giữa, không tạo mép mới. Widget: cột tim thẳng mép phải nội dung (Android nhờ `paddingEnd` 8 + cột 48). Không có ô mồ côi.
3. *Màu chỉ cho dữ liệu/trạng thái/nút chính?* Màu duy nhất mới là `accentLoveDeep` trên tim, đúng là nút chính. Face (ba làn) thấy ngay ở ảnh đầu.
4. *Số có cộng đúng?* 7 + 5 = 12 ở Home, widget (12), mô tả; push 14:30 ghi 11 vì tính tới lúc đó (assert). 1.255 ngày, 30.134 giờ, còn 245 ngày tới 1.500 khớp nhau.
5. *Số 0 là 0, thiếu là gạch?* Ngày mới: không in "0" cạnh nút mà dùng câu mời; widget không hiện số khi tổng 0 (theo spec D8). Không có giá trị "thiếu" nào cần gạch: lỗi đọc nói rõ bằng câu.
6. *Chú thích/legend khớp?* Không có biểu đồ. Số "12" dưới tim không có nhãn chữ trên widget nhỏ — xem điểm yếu.
7. *Trên điện thoại khối còn trả lời câu hỏi?* Có, mock chỉ có bề 390.

**Còn yếu sau vòng 3:**
- Số tổng "12" dưới tim ở widget nhỏ đứng ngang hàng "ngày bên nhau", người mới nhìn có thể đọc như một phần chú thích. Đỡ được nhờ căn đúng trục tim và nhãn đọc màn hình; không có chỗ cho chữ "lần".
- Câu chữ trắng 13 trên thẻ hồng không nền ảnh dưới 4,5:1 (cả thẻ đang vậy, §13 Q2).
- Thẻ đếm cao thêm ≈42px, đẩy "Hôm nay của chúng mình" xuống (Q1).
- Mock Android dùng Helvetica thay Roboto (máy Mac không có Roboto), số co thật có thể lệch ±1sp.

## 13. Câu hỏi cho PO / user

1. **Home cao thêm ≈42px** vì câu dưới hàng tên. Designer ghép Home có thể đổi: chỉ hiện câu khi có số (ẩn câu mời lúc 0 lần) để tiết kiệm 26px buổi sáng. Đề xuất giữ câu luôn hiện (đó là "phát hiện" của khối); PO/Designer ghép Home chốt.
2. **Tương phản chữ trắng trên CounterCard không ảnh:** `design-system.md` ghi "không ảnh → scrim đen .10→.28" nhưng code `counter_card.dart` hiện không có lớp này; tên, eyebrow, cột mốc và câu mới đều < 4,5:1. Có muốn thêm lại scrim (đổi cả thẻ, ngoài phạm vi poke) không?
3. **Widget Android 2×2: số ngày co từ 40 xuống ≈33sp** khi có tim (iOS chỉ co ≈5%). Chấp nhận, hay muốn bản 2×2 Android đặt tim ở chỗ khác và chịu cắt tên dài trong chip?

## 14. Handoff / Dev notes

- Kích cỡ, màu, chuyển động: §6–§8. Copy: §9 (ICU plural cho EN; nhớ sửa cả `app_en.arb` + `app_vi.arb` rồi `gen-l10n`).
- `PokeCoupleRow` nhận `mine`, `partner`, `state` (idle/sending/queued/received/loading/error/limited) từ `PokeProvider`; tự quyết câu theo bảng §6.1 và vị trí làn (`creatorUserId == myUid` ⇒ mình bên trái).
- Widget iOS: `PokeButton` trong `if #available(iOSApplicationExtension 17.0, *)`, đặt trong `HStack` cùng `DayNumber`/`Caption`; ngoài khối đó giữ nguyên code 15–16. Vùng chạm 44×44 dùng `.frame(width: 44, height: 44).contentShape(Rectangle())` rồi offset để đĩa 30 thẳng mép nội dung.
- Widget Android: `applyStyle` phải đặt đủ mọi thuộc tính cột tim ở cả hai nhánh có/không tim (visibility, drawable, text, contentDescription, `setViewPadding` của khung nội dung) — bài học launcher reapply.
- Không thêm token màu mới. Mọi giá trị nằm trong `AppColors` hoặc đã có trong `DayCounterView.swift` / drawable widget.

## Nhật ký design
- [2026-10-20] [Designer] Thiết kế feature poke theo tasteskill (sheet chung editorial-greeting seed 1822703143, `--keep palette,type`) + UI UX Pro Max 2.13.0, bám design system hiện tại theo quyết định user. Chốt: tim thành nút ngay giữa hai tên trên CounterCard (face "ba làn"), đồng hồ giữ nguyên; widget đặt tim cạnh số ngày + số tổng dưới tim (đo: góc trên phải không đủ chỗ cho vùng chạm), đĩa đổi trạng thái bằng hình (viền/đặc/nét đứt); công tắc Cài đặt có dòng phụ xem trước thông báo. Dựng 4 trang mock + `data.js` (assert 0 lỗi), lint 0 FAIL, inspect 390px 0 FAIL cả 4 trang (allow rule của brand, ghi lý do), 3 vòng critique. Mở 3 câu hỏi cho PO.
