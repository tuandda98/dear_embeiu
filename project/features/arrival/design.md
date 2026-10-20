# 🎨 Design — Về đến nhà chưa? (arrival)

> Designer sở hữu. Đọc `overview.md` (PO) trước. Bám `project/design-system.md` + code thật `lib/theme/`, `lib/widgets/`. CHỈ thiết kế, không code.

- **Trạng thái design:** xong vòng 1, chờ PO duyệt (câu hỏi cuối file)
- **Người/role:** Designer
- **Mock bấm thử (mở thẳng bằng trình duyệt):** [`docs/design/arrival/`](../../../docs/design/arrival/)
  - `home-card.html` — thẻ Home, 14 trạng thái + vị trí cạnh "Đêm qua" (bấm "Về nhà rồi", "Hỏi thăm")
  - `setup.html` — luồng bật lần đầu, 12 khung (bấm nút chính để đi tiếp)
  - `manage.html` — màn quản lý + 6 trạng thái/hộp thoại
  - `notify.html` — push iOS/Android, widget nhỏ/vừa (Trời đêm + có ảnh), 2 dòng Cài đặt
  - `data.js` (dữ liệu mẫu + 17 `console.assert`), `ui.js` (icon), `card.js` (render thẻ), `app.css` (token lấy từ code)
- **Ảnh chụp inspector:** `.taste-skill/arrival/{home-card,setup,manage,notify}/`

## Đầu vào

- Spec PO `overview.md` (D1–D18, §8 UI, bảng widget). Copy chốt: D12 (giải thích quyền + 2 câu InfoPlist), §7 (push), §8 (widget).
- User chốt 2026-10-20: dùng **tasteskill trọn run** + **UI UX Pro Max**; **"follow theo system design hiện tại của app"** (không làm lại app), giữ đồng hồ chạy, giữ navy trời đêm làm ngoại lệ.
- Style chung đợt: sheet `docs/design/daily-open-2/sheet.raw.md` (editorial-greeting, seed 1822703143, `--keep palette,type`). Không draw lại.

---

## 1. Run tasteskill (app-screens §2.1–2.4)

### 2.1 Kiểm kê dữ liệu và việc

- **Đối tượng:** một doc mỗi người `arrival/{uid}` = `share` · `auto` · `places` (⊂ home/work/school, ≤3) · `last {place, type enter|exit, at, battery 0–100, source auto|manual, bounce}`. Máy chủ chỉ có MỘT sự kiện mới nhất (D3).
- **Độ lớn thật:** 1–3 sự kiện đến/ngày/người; ≤6 push/ngày; pin 0–100%; giờ HH:mm; bán kính 150 m; 3 địa điểm là trần, đa số chỉ có Nhà + Chỗ làm.
- **Người:** Tuấn và Thảo, mở Home vài lần/ngày, mỗi lần liếc 3–5 giây, hay nhất là buổi tối lúc chờ người kia về. Điện thoại, một tay.
- **Việc:** (người nhận) xem người ấy về chưa → gửi một câu hỏi thăm; (người gửi) bấm "Về nhà rồi" khi máy không tự báo; bật/tắt; lưu địa điểm. **Việc hay làm nhất:** liếc xem Thảo về chưa (không bấm gì), sau đó là "Hỏi thăm".
- **Thứ chỉ app này có:** tên hai người, màu riêng mỗi người (`personPalette`, đã có từ feature sleep), tên nơi bằng tiếng nhà (Nhà, Chỗ làm, Trường), mức pin lúc đến, "chúng mình".
- **Dữ liệu mẫu** (`data.js`, mọi con số suy ra từ một nhật ký): Thảo rời nhà 07:20 (96%) → đến chỗ làm 07:58 (91%) → rời 17:32 (19%) → về nhà 18:42 (12%). Tuấn đến chỗ làm 08:05 (64%). "Bây giờ" 19:05, 20/10/2026; ngày yêu 14/05/2023 ⇒ 1.255 ngày (khớp `CounterData` `difference.inDays`). Assert: push 18:42 = "Thảo đã về đến nhà / Pin còn 12%", push 07:58 = body hỏi thăm (91% > 20), widget = tiêu đề push, 2 lần đến = 2 push ≤ 6, đi đổ rác 6 phút không sinh push thứ 3, màu hai người không nằm trong cặp khoá, còn 45 ngày tới mốc 1.300.

### 2.2 Câu hỏi · finding · việc chính của từng màn

| Màn | Câu hỏi một dòng | One finding (đặt chỗ đọc trước) | Việc chính, một chạm |
|---|---|---|---|
| Thẻ Home | Thảo về đến nơi chưa? | "Đã về đến nhà · 18:42 · Pin còn 12%" (pin yếu giải thích vì sao Thảo chưa nhắn) | "Hỏi thăm" (người nhận) · "Về nhà rồi" (người gửi) |
| Bật lần đầu | Bật cái này thì người ấy thấy gì về mình? | Người ấy chỉ thấy tên nơi, giờ, pin; toạ độ ở lại máy | "Đồng ý, tiếp tục" → hộp xin quyền |
| Quản lý | Mình đang chia sẻ gì, tắt thế nào? | Khối "Thảo đang thấy: Đã đến chỗ làm · 08:05 · pin 64%" ở đầu màn | Công tắc "Báo cho Thảo" |
| Push/widget | Tin đến tay người ấy trông thế nào? | "Thảo đã về đến nhà" + "Pin còn 12%" khi ≤ 20% | Chạm → Home, cuộn tới thẻ |

### 2.3 Style · face · signature

- **Style:** editorial-greeting của đợt (không draw lại). Map vai trò: ground = `dawnBlush` (giữ, xem §8) · surface = `ContentCard` trắng · panel tông = tint màu người α .10 / `surfaceLight #F5F0F5` · rule = textSecondary α .10 (#F0F0F2) · control = navy α .18 · text = `textPrimary #1A1A2E` · muted = `textSecondary #6B6B7B` (chỉ trên trắng) · primary = navy · accent = `accentLove #FF4D6D` (tim, icon IconBadge) · warning = `warning #FFA726` α .18 + chữ `#8A4B00` (token mới, §9).
- **Face (chọn từ sheet): "cặp đôi là các làn".** Mỗi người một làn có chấm màu riêng. Làn người ấy là khối tint màu của người ấy (α .10, r16), làn của bạn nằm trên nền trắng của card và giữ các nút. Thấy ngay trên ảnh chụp đầu tiên (`home-card` khung 1). Không có làn "chung": thứ chung duy nhất ở đây là nút "Hỏi thăm" nằm trong làn người ấy.
- **Signature element: "dòng đến nơi"** = tên nơi viết thành câu ("Đã về đến nhà") + giờ + pin. Khi pin ≤ 20% pin thành viên thuốc vàng đất "Pin còn 12%". Tin tốt (đã về) và lý do im lặng (pin yếu) đứng trên cùng một dòng.
- **Đã đổi so với sheet, có lý do:** greeting/centred 12-column của sheet là bố cục cho Home desktop, không áp cho một thẻ trong Home điện thoại. Giữ "số ở weight thường trên panel tông": giờ 14 w700 nhưng câu chính là chữ, không phải con số.

### 2.4 Shell

App chỉ có điện thoại ⇒ inspector chỉ chạy **390**. Shell = shell sẵn của app: Home (chip header + nav nổi, không đụng) cho thẻ; `SubScreenHeader` (← + `EyebrowChip` giữa) cho màn con; nền `dawnBlush` vẽ một lần. Lưới: gutter 16, card padding 16, khoảng giữa card 12 (cùng cụm) — 16 + 358 + 16 = 390.

---

## 2. Màn và luồng

```
Home (cặp active)                                  Cặp waiting_partner → KHÔNG có thẻ, KHÔNG có dòng Cài đặt (D9)
 └─ Thẻ "Về đến nhà chưa?" (dưới thẻ "Đêm qua")
     ├─ [Bật báo về nhà] ───────────► SETUP
     ├─ [Về nhà rồi] ─ ghi last(manual) ─► push Thảo (không cần quyền, không cần địa điểm)
     ├─ [Hỏi thăm] ──────────────────► CareMessageScreen (chip gợi ý "Về tới nơi rồi thì nghỉ ngơi nhé")
     └─ chạm tiêu đề / dòng "Tự báo khi đến…" ─► QUẢN LÝ (đã bật) hoặc SETUP (chưa bật)

SETUP (màn con, 3 bước, dừng ở đâu cũng dùng được)
 1 Giải thích quyền (prominent disclosure, D12) ─[Đồng ý, tiếp tục]─► hộp hệ thống "khi dùng app + chính xác"
     ├─ chỉ cấp gần đúng ─► "Cần bật Vị trí chính xác" [Mở Cài đặt] / [Dùng bấm tay]
     └─ từ chối / định vị tắt ─► "Chưa có quyền vị trí" [Mở Cài đặt] / [Dùng bấm tay]
 2 Lưu Nhà ─[Mình đang ở nhà, lưu chỗ này]─► Đang lấy vị trí… ─► (sai số > 100 m ⇒ "Vị trí chưa đủ chuẩn") ─► Đã lưu
     └─[Mình chưa ở nhà]─► Dừng giữa chừng (bấm tay; thẻ Home có nút "Lưu Nhà")
 3 Chọn "Luôn luôn" (iOS) / "Cho phép mọi lúc" (Android) ─► hộp/trang hệ thống
     ├─ cấp ─► Xong "Đã bật báo về nhà"
     └─ không cấp ─► Dừng giữa chừng (thẻ Home: "Chưa tự báo được…" + [Mở Cài đặt])

QUẢN LÝ (màn con) — vào từ thẻ Home hoặc Cài đặt → Chung → "Về đến nhà"
 "Thảo đang thấy" · [Báo cho Thảo] · [Tự báo khi đến nơi] · Địa điểm (≤3, ⋯ lưu lại / xoá) · Quyền vị trí
 Tắt "Báo cho Thảo" ─► hộp "Tắt báo về nhà?" (+ ô "Xoá luôn địa điểm") ─► xoá `last`, không báo Thảo

Push (chỉ ĐẾN) ─► Home tab 0, cuộn tới thẻ (pendingHomeFocus 'arrival')
Widget-today: dòng `arrival_*` (rút gọn ở widget nhỏ)
Cài đặt → Thông báo: công tắc "Khi người ấy đến nơi" (pushArrival)
```

---

## 3. Thẻ Home — `ArrivalCard` (lối vào Home)

**Dành cho Designer ghép Home:** một thẻ `ContentCard` cao ~300 dp ở trạng thái đầy đủ (làn Thảo + làn bạn + hàng nút), ~190 dp ở trạng thái "lần đầu", ~250 dp khi Thảo chưa bật. Đề xuất đặt **ngay dưới `SleepCard`**, cách 12, thành cụm "người ấy hôm nay": hai thẻ dùng chung chấm màu người, nhãn tên micro-caps, vạch #F0F0F2. Ẩn hẳn với cặp đang chờ. Không có nút "Ẩn thẻ" (khác SleepCard) vì nút "Về nhà rồi" phải luôn có (D7); nếu Home cần gọn, phương án dự phòng ở câu hỏi Q3.

### 3.1 Cấu trúc (390 dp, nội dung rộng 326)

```
┌ ContentCard r24, pad 16, bóng black .06 blur16 y10 ───────────────┐
│ [IconBadge home_2 rose 44/r16]  Về đến nhà chưa?  16 w800    ›     │ hàng chạm 44 → Quản lý/Setup
│ gap 12                                                             │
│ ┌ làn người ấy: r16, pad 12×14, nền màu Thảo α .10 ──────────────┐ │
│ │ ● THẢO                         11 w700 ls1.0 textSecondary     │ │ PersonLabel (có sẵn)
│ │ Đã về đến nhà      20 w700 navy          ┌──────────────────┐  │ │
│ │ 18:42  [▭ Pin còn 12%]                   │ (♡) Hỏi thăm     │  │ │ nút trắng h44 pill
│ │ 14 w700 tabular · pill vàng 24 cao       └──────────────────┘  │ │
│ └────────────────────────────────────────────────────────────────┘ │
│ gap 14                                                             │
│ ● BẠN                                                              │
│ (⌖) Tự báo khi đến Nhà · Chỗ làm      14 w600 navy            ›    │ hàng chạm ≥44 → Quản lý
│ gap 6                                                              │
│ [⌂ Về nhà rồi]  [▢ Đến chỗ làm rồi]   pill viền navy .18, h44, gap 8 (Wrap) │
└────────────────────────────────────────────────────────────────────┘
```

### 3.2 Map sang widget Flutter

| Phần | Dùng | Ghi chú |
|---|---|---|
| Khung | `ContentCard(padding: EdgeInsets.all(16))` (`lib/widgets/content_card.dart`) | như `SleepCard` |
| Icon tiêu đề | `IconBadge(IconsaxPlusLinear.home_2)` tint mặc định `accentRose` (`icon_badge.dart`) | |
| Tiêu đề | `Text` 16 w800 `textPrimary` + `IconsaxPlusLinear.arrow_right_3` 18 `textTertiary` | cả hàng bọc `InkWell` r16, splash rose .08 |
| Nhãn người | `PersonLabel(name, color)` từ `lib/widgets/sleep/sleep_card.dart` | **tách ra file chung** `lib/widgets/person_label.dart` (Dev) để arrival không import sleep |
| Màu người | `PersonPalette.resolve(...)` (`lib/theme/person_palette.dart`) | màu đọc từ hồ sơ `sleep/{uid}.color`; chưa có thì mặc định theo luật C1 (Q4) |
| Làn người ấy | **mới** `_PartnerLane`: `Container` r16, pad `12,14`, màu `colorOf(partner).withValues(alpha: .10)`; trạng thái chưa bật/không dữ liệu: `surfaceLight` | |
| Câu chính | `Text` 20 w700 `textPrimary`, 1 dòng, `ellipsis` | |
| Giờ | `Text` 14 w700 `textPrimary`, `FontFeature.tabularFigures()`, `DateFormat.Hm(locale)` (D3) | hôm qua: `arrivalYesterdayAt`; 2–3 ngày: `DateFormat.Md(locale)` + giờ |
| Pin thường | Row icon `IconsaxPlusLinear.battery_3full` 14 + "pin 64%" 13 w600 `textSecondary` | |
| Pin ≤ 20% | **mới** `_BatteryLowPill`: cao 24, pad ngang 8, r999, nền `warning` α .18, icon `battery_empty` 14 + chữ 12 w700 `warningInk #8A4B00` | 6,0:1 trên nền pill; không đỏ (spec §8) |
| "bấm tay" | 13 w600 `textSecondary` sau pin | chỉ khi `source == manual` |
| Hỏi thăm | `ElevatedButton.icon` nền trắng, chữ navy 15 w600, icon `message_favorite` 16 `accentLoveDeep`, cao 44 | mở `openCareMessageScreen(prefill: arrivalCareSuggestion)` |
| Dòng của bạn | **mới** `_MineStatusRow`: `InkWell` r12, minHeight 44, icon 18 navy (`location` / `location_slash` / `tick_circle`) + 14 w600 navy + chevron | |
| Nút bấm tay | `OutlinedButton.icon` pill, viền navy α .18 1.5, chữ 15 w600 navy, cao 44, icon 16 (`home_2` / `briefcase` / `teacher`); `Wrap(spacing 8, runSpacing 8)` | chỉ nơi đã lưu; "Về nhà rồi" luôn có |
| Nút chính trong thẻ | `ElevatedButton` navy pill cao 44 ("Bật báo về nhà", "Mở Cài đặt", "Lưu Nhà") | tối đa 1 nút đặc mỗi thẻ |
| Dải offline/lỗi | **mới** `_InlineStrip`: r16, nền `surfaceLight`, pad 10×12, icon 18 + 13 w600 navy (+ `TextButton` "Thử lại") | lỗi: icon `info_circle` màu `error`, chữ navy |
| Đang tải | `ShimmerSkeleton` (có sẵn) đúng kích thước khối thật | không nhảy bố cục khi dữ liệu về |

### 3.3 Trạng thái thẻ (mock `home-card.html`)

| # | Khi nào | Làn người ấy | Làn của bạn |
|---|---|---|---|
| A | Cả hai chưa bật (lần đầu) | — (không có làn, chỉ 1 câu mời) | `arrivalPitch` + [Bật báo về nhà] (đặc) + [Về nhà rồi] |
| B1 | Thảo đến nơi hôm nay | "Đã về đến nhà" · 18:42 · pin | tuỳ trạng thái bạn |
| B2 | Thảo rời nơi hôm nay (không push) | "Đã rời chỗ làm" · 17:32 · pin | |
| B3 | Tin hôm qua / 2–3 ngày trước | thêm "hôm qua 22:58" / "18/10 22:58"; "bấm tay" nếu manual | |
| B4 | Thảo bật nhưng không có tin trong 3 ngày | "Đang bật báo về nhà" + "Khi Thảo đến nơi, tin sẽ hiện ở đây." (không nút) | |
| B5 | Thảo chưa bật / đã tắt | nền `surfaceLight`, "Chưa bật báo về nhà" (trung tính, không nút giục, không lộ lúc tắt — D11) | |
| M1 | Bạn: tự báo ổn | | "Tự báo khi đến Nhà · Chỗ làm" › + nút bấm tay |
| M2 | Bạn chưa bật, Thảo đã bật | | "Bạn chưa bật báo về nhà" + [Bật báo về nhà] + [Về nhà rồi] |
| M3 | Thiếu quyền Luôn luôn / chỉ gần đúng | | "Chưa tự báo được: cần quyền vị trí Luôn luôn" + [Mở Cài đặt] + [Về nhà rồi] |
| M4 | Tắt từ xa (`arrivalAutoEnabled=false`) | | "Tạm thời chỉ báo bằng tay" › + nút bấm tay |
| M5 | Đã bật, chưa lưu Nhà | | "Về đến nhà thì lưu chỗ đó để máy tự báo" + [Lưu Nhà] + [Về nhà rồi] |
| M6 | Chỉ bấm tay (đã bấm tay lần đầu, chưa bật tự động) | | "Đang báo bằng tay" › + nút bấm tay |
| S1 | Vừa bấm "Về nhà rồi" | | dòng trạng thái thành "Đã báo Thảo: Về nhà rồi · 19:05" (live region) 4 giây; nút giữ nhãn + bề rộng, nền navy α .06, icon thành `tick_circle` |
| S2 | Mất mạng lúc bấm | | nút icon `cloud_cross` + dải "Sẽ báo khi có mạng. Quá 30 phút thì Thảo chỉ thấy trên thẻ, không nhận thông báo." |
| S3 | Ghi lỗi | | dải lỗi "Chưa gửi được tin “Về nhà rồi”." + [Thử lại] |
| L | Đang tải | skeleton làn | skeleton dòng + 2 nút |
| W | Cặp đang chờ người ấy | không render thẻ | |

Ghép: thẻ = 1 trạng thái làn người ấy (A/B1–B5) × 1 trạng thái làn bạn (M1–M6, S1–S3). Tin cũ hơn 3 ngày ⇒ B4.

---

## 4. Luồng bật lần đầu — `ArrivalSetupScreen` (mock `setup.html`)

- **Route màn con** (không dùng bottom sheet như sleep, vì nội dung giải thích dài và Play cần thấy rõ trong video). Nền trong suốt trên `dawnBlush`, `SubScreenHeader(badge: arrivalBadge, badgeIcon: IconsaxPlusLinear.home_2)`, `SingleChildScrollView` pad `16,16,16,24`.
- **Chấm bước** dưới header: 3 chấm, đang ở = 16×6 rose r999, còn lại 6×6 `textTertiary` α .5 (y như `SleepSetupSheet`), gap 6, cách nội dung 20. `Semantics(label: "Bước n trên 3")`.
- **Tiêu đề bước:** 26 w700 `textPrimary` (cỡ "headline" trong type scale), tối đa 2 dòng.
- **Thân chữ:** 15 w500 navy cao dòng 1.5 cho câu giải thích bắt buộc (D12, *phải đủ đậm và nằm ngay dưới tiêu đề*, không giấu trong card); 14 w500 cho câu phụ.
- **Nút:** `ElevatedButton` navy pill **cao 52 rộng hết**, nút phụ `TextButton` cao 44 chữ 15 w600 navy α .78 (textSecondary trên blush chỉ 2,5–3,4:1, không dùng).
- **Hộp gợi ý** (`hint`): r16, nền `surfaceLight`, pad 10×12, icon `info_circle` 16 navy + 12 w600 navy α .78.

| Khung | Nội dung | Nút |
|---|---|---|
| Giải thích (bước 1) | Tiêu đề `arrivalDisclosureTitle` → **câu D12 nguyên văn** → nhãn "Thảo sẽ nhận được" + xem trước push (card trắng r16: icon app 28 r7 `sunset1` tim trắng · "Tuấn đã về đến nhà" 14 w700 · "Pin còn 12%" 13 · "bây giờ") → link "Chính sách bảo mật" 14 w700 gạch chân | [Đồng ý, tiếp tục] · [Để sau] |
| Hộp hệ thống | iOS `requestWhenInUse` (câu `NSLocationWhenInUseUsageDescription` D12) · Android hộp Chính xác/Gần đúng. App không vẽ, chỉ đợi kết quả | — |
| Lưu Nhà (bước 2) | "Bạn đang ở nhà chứ?" + câu phụ + card: hình vòng tròn 96 (đĩa navy α .05 viền α .18, tâm trắng 36 + icon home 20) + "Nhà" 15 w700 + "Vòng tròn 150 m quanh chỗ bạn đứng. Vào vòng này là tính “đã về”." | [⌂ Mình đang ở nhà, lưu chỗ này] · [Mình chưa ở nhà] |
| Đang lấy vị trí | nút chính khoá, spinner trắng 16 + "Đang lấy vị trí…"; timeout 15 s ⇒ khung "Vị trí chưa đủ chuẩn" | — |
| Sai số > 100 m | "Vị trí chưa đủ chuẩn" + card "Lệch khoảng 180 m / Lưu bây giờ thì có thể báo “đã về” khi bạn mới tới đầu ngõ." + gợi ý ra gần cửa sổ | [Thử lại] · [Vẫn lưu] |
| Chỉ gần đúng | "Cần bật Vị trí chính xác" + lý do | [Mở Cài đặt] · [Dùng bấm tay] |
| Từ chối / định vị tắt | "Chưa có quyền vị trí" + "vẫn bấm tay được" + gợi ý đường dẫn Cài đặt | [Mở Cài đặt] · [Dùng bấm tay] |
| Đã lưu | "Đã lưu Nhà" + vòng tròn đổi sang rose α .10 viền α .45, icon rose + "Chỗ làm và Trường thêm sau…" | [Tiếp tục] |
| Luôn luôn (bước 3, iOS) | "Chọn “Luôn luôn”" + câu D12 màn 2 + "Trang tiếp theo trông như thế này" + danh sách giả 4 dòng (dòng "Luôn luôn" nền navy α .06 + tick) + gợi ý "Đừng vuốt tắt…" | [Tiếp tục] (gọi `requestAlwaysAuthorization`) · [Để sau, mình bấm tay] |
| Luôn luôn (Android) | "Chọn “Cho phép mọi lúc”" (nhãn lấy từ `getBackgroundPermissionOptionLabel()`), danh sách giả theo Android, gợi ý Tự khởi động cho Xiaomi/Oppo/Vivo (Dev quyết hiện theo hãng) | [Mở trang quyền] · [Để sau, mình bấm tay] |
| Xong | "Đã bật báo về nhà" + câu "Từ giờ về đến Nhà là Thảo biết…" + card hàng "Tự báo khi đến Nhà / Thêm Chỗ làm, Trường lúc bạn đang ở đó ›" (→ Quản lý) | [Về trang chủ] |
| Dừng giữa chừng | "Tạm thời bạn báo bằng tay" + giải thích | [Về trang chủ] |

- **Chia sẻ:** bấm "Đồng ý, tiếp tục" là lúc ghi `share:true` (sau khi hệ thống trả quyền, cả khi từ chối — vì bấm tay vẫn chia sẻ). "Để sau" ở bước 1 không ghi gì.
- **Video Play ≤ 30 s (gợi ý khung):** thẻ Home → [Bật báo về nhà] → khung Giải thích (dừng 3 s cho đọc) → hộp "khi dùng app" → Lưu Nhà → khung "Cho phép mọi lúc" → trang quyền chọn "Cho phép mọi lúc" → vuốt app về nền, giả lập vị trí đi ra rồi vào → push "Tuấn đã về đến nhà" trên máy kia.

---

## 5. Màn quản lý — `ArrivalScreen` (mock `manage.html`)

Màn con, cùng khung với Setup. Mỗi công tắc tự lưu ngay (một kiểu lưu cho cả màn).

1. **"Thảo đang thấy"** (nhãn 13 w700 navy trên blush) → làn giống thẻ Home nhưng là **của bạn** (tint màu bạn α .10): "● TUẤN / Đã đến chỗ làm / 08:05 · pin 64%". Tắt chia sẻ ⇒ nền `surfaceLight` "Chưa bật báo về nhà". Đây là phần "cho thấy cài đặt tạo ra gì" (app-screens §8.2) và là D11 "người chia sẻ luôn thấy mình đang chia sẻ gì".
2. **Card công tắc** (`ContentCard` pad `4,20`, hàng ngăn #F0F0F2):
   - `IconBadge(heart)` · "Báo cho Thảo" 15 w700 · phụ đề 12 w500 textSecondary · `Switch.adaptive` bật = **navy** (như sleep: rose có thể là màu của một người).
   - `IconBadge(location)` · "Tự báo khi đến nơi" · phụ đề theo trạng thái (đủ quyền / thiếu Luôn luôn + nút viền [Mở Cài đặt] cao 44 / tắt từ xa: công tắc khoá + "Tạm thời chỉ báo bằng tay…"). Ẩn khi "Báo cho Thảo" tắt.
3. **Địa điểm** (`SectionHeader` cỡ 20 + câu phụ "Tối đa 3. Toạ độ chỉ nằm trên máy này, đổi máy thì lưu lại."): 3 hàng cố định Nhà / Chỗ làm / Trường, `IconBadge` navy α .06. Đã lưu: "Bán kính 150 m · lưu 12/10" + `HeaderIconButton(more)` 44 → menu "Lưu lại bằng chỗ đang đứng" / "Xoá Nhà" (icon `trash`). Chưa lưu: nút viền [Lưu chỗ này] cao 44 → **sheet xác nhận** "Lưu chỗ đang đứng là Trường?" (tránh lưu nhầm khi đang ở quán cà phê). Xoá Nhà khi đang tự báo ⇒ công tắc "Tự báo" tắt theo. Tạm dừng/tắt ⇒ phụ đề "Đang tạm dừng".
4. **Quyền vị trí**: "Vị trí: Luôn luôn" / "Vị trí: Khi dùng ứng dụng" (icon `tick_circle` / `location_slash`) · "Vị trí chính xác: Bật/Tắt" · hàng "Mở Cài đặt của máy" › (`openAppSettings`). Dưới card: gợi ý "Đừng vuốt tắt…" (chỉ iOS) hoặc Tự khởi động (Android theo hãng).
5. **Tắt "Báo cho Thảo"** ⇒ `AlertDialog` r28: "Tắt báo về nhà?" + câu hậu quả nêu đúng điều Thảo sẽ thấy + ô "Xoá luôn 2 địa điểm đã lưu trên máy này" (mặc định bỏ trống, vùng chạm ≥44) + [Huỷ] chữ · [Tắt] navy pill. Tắt = một lần ghi `share:false` + xoá `last`, huỷ geofence; tick ô thì xoá thêm Hive.
   - **Lệch spec có chủ ý:** PO §8 có thêm nút "Tắt và xoá dữ liệu". Thiết kế gộp vào một đường: tắt công tắc = xoá dữ liệu máy chủ (đúng D11), ô tick lo phần xoá địa điểm. Hai nút làm cùng một việc sẽ làm người dùng phân vân nút nào "sạch" hơn.

---

## 6. Push · widget · Cài đặt (mock `notify.html`)

- **Push:** chữ y bảng §7 PO. App icon + tiêu đề + body; giờ do hệ thống hiện. Không thêm emoji. Tap ⇒ Home tab 0, `pendingHomeFocus = 'arrival'`, cuộn thẻ vào giữa màn (280 ms easeOutCubic; Reduce Motion ⇒ nhảy thẳng).
- **Widget-today:** dùng nguyên dòng trạng thái của widget-today (chấm 6 + chữ trắng 12 w700 nhỏ / 14 w700 vừa, 2 dòng). Widget nhỏ dùng `statusTextShort` ("Thảo về nhà rồi", 15 ký tự), widget vừa dùng `statusText` ("Thảo đã về đến nhà" — ở bản vừa xuống 2 dòng, chấp nhận theo spec widget-today). Không pin, không tin rời. Nền Trời đêm và nền ảnh đều đọc được (chụp ở `notify.html`).
- **Cài đặt → Thông báo:** thêm một hàng `SwitchListTile.adaptive` y kiểu hàng nhắc âm lịch có sẵn (IconBadge `home_2` · 15 w700 · phụ đề 12) "Khi người ấy đến nơi" — chỉ khi đã ghép đôi. Mock vẽ công tắc navy cho đồng bộ; Dev giữ đúng `activeThumbColor` của các hàng cùng card.
- **Cài đặt → Chung:** `_navRow(icon: location, title: "Về đến nhà", subtitle: trạng thái)` đặt trên dòng "Ảnh nền thẻ đếm". Phụ đề: "Đang báo cho Thảo: Nhà · Chỗ làm" / "Đang tắt" / "Tạm thời chỉ báo bằng tay". Ẩn với cặp đang chờ.

---

## 7. Copy deck (vi + en)

Xưng hô: "bạn" theo D12 (câu giải thích chốt của PO dùng "bạn"); nút là lời người dùng nói ra nên giữ "Mình…" ("Mình đang ở nhà, lưu chỗ này"). Nhãn làn của mình = "BẠN", **khớp `SleepCard` ("Bạn")** đứng ngay trên — xem Q2. Dấu kiểu mới (xoá, huỷ, tuỳ). Đã soát theo humanizer (bỏ "không chỉ… mà còn", bộ ba gượng, gạch ngang) và avoid-ai-writing cho bản EN.

| Key | VI | EN |
|---|---|---|
| `arrivalCardTitle` | Về đến nhà chưa? | Home yet? |
| `arrivalPitch` | Về đến nhà là máy tự báo cho {name}. Đang chạy xe thì khỏi phải nhắn. | When you get home, your phone tells {name}. No texting from the road. |
| `arrivalEnableCta` | Bật báo về nhà | Turn on arrivals |
| `arrivalManualHome` / `Work` / `School` | Về nhà rồi / Đến chỗ làm rồi / Đến trường rồi | I'm home / At work / At school |
| `arrivalEnterHome` / `Work` / `School` | Đã về đến nhà / Đã đến chỗ làm / Đã đến trường | Got home / Got to work / Got to school |
| `arrivalExitHome` / `Work` / `School` | Đã rời nhà / Đã rời chỗ làm / Đã rời trường | Left home / Left work / Left school |
| `arrivalYesterdayAt` | hôm qua {time} | yesterday {time} |
| `arrivalBattery` | pin {pct}% | battery {pct}% |
| `arrivalBatteryLow` | Pin còn {pct}% | Battery at {pct}% |
| `arrivalManualTag` | bấm tay | manual |
| `arrivalPartnerOn` | Đang bật báo về nhà | Arrivals are on |
| `arrivalPartnerOnSub` | Khi {name} đến nơi, tin sẽ hiện ở đây. | You'll see it here when {name} arrives. |
| `arrivalPartnerOff` | Chưa bật báo về nhà | Arrivals are off |
| `arrivalCareCta` | Hỏi thăm | Say hi |
| `arrivalCareSuggestion` | Về tới nơi rồi thì nghỉ ngơi nhé | You made it. Get some rest |
| `arrivalYou` | Bạn | You |
| `arrivalMineAuto` | Tự báo khi đến {places} | Sends on arrival: {places} |
| `arrivalMineOff` | Bạn chưa bật báo về nhà | Your arrivals are off |
| `arrivalMineNeedAlways` | Chưa tự báo được: cần quyền vị trí Luôn luôn | Can't send on its own yet: needs Always location |
| `arrivalMineRemoteOff` | Tạm thời chỉ báo bằng tay | Manual only for now |
| `arrivalMineNoHome` | Về đến nhà thì lưu chỗ đó để máy tự báo | Save Home when you're there so it sends on its own |
| `arrivalMineManual` | Đang báo bằng tay | You're sending manually |
| `arrivalSaveHomeCta` | Lưu Nhà | Save Home |
| `arrivalOpenSettings` | Mở Cài đặt | Open Settings |
| `arrivalSent` | Đã báo {name}: {what} · {time} | Sent to {name}: {what} · {time} |
| `arrivalQueued` | Sẽ báo khi có mạng. Quá 30 phút thì {name} chỉ thấy trên thẻ, không nhận thông báo. | Sends when you're back online. After 30 minutes, {name} only sees it on the card, with no notification. |
| `arrivalSendFailed` | Chưa gửi được tin “{what}”. | Couldn't send “{what}”. |
| `arrivalRetry` | Thử lại | Try again |
| `arrivalBadge` | VỀ ĐẾN NHÀ | ARRIVALS |
| `arrivalDisclosureTitle` | Về đến nơi, {name} biết ngay | {name} knows when you arrive |
| `arrivalDisclosureBody` | *(D12 nguyên văn)* | *(D12 nguyên văn)* |
| `arrivalPreviewLabel` | {name} sẽ nhận được | {name} will get |
| `arrivalAgree` / `arrivalLater` | Đồng ý, tiếp tục / Để sau | Agree and continue / Not now |
| `arrivalPrivacyLink` | Chính sách bảo mật | Privacy policy |
| `arrivalAtHomeTitle` | Bạn đang ở nhà chứ? | Are you home right now? |
| `arrivalAtHomeBody` | App lấy chỗ bạn đang đứng làm Nhà. Toạ độ chỉ nằm trên máy này, đổi máy thì lưu lại. | Your current spot becomes Home. The coordinates stay on this phone; set it again if you switch phones. |
| `arrivalRingCaption` | Vòng tròn {m} m quanh chỗ bạn đứng. Vào vòng này là tính “đã về”. | A {m} m circle around where you stand. Step inside and you're home. |
| `arrivalSaveHere` / `arrivalNotHome` | Mình đang ở nhà, lưu chỗ này / Mình chưa ở nhà | I'm home, save this spot / I'm not home yet |
| `arrivalLocating` | Đang lấy vị trí… | Finding your location… |
| `arrivalCoarseTitle` / `Body` | Vị trí chưa đủ chuẩn / Lưu bây giờ thì có thể báo “đã về” khi bạn mới tới đầu ngõ. | Location isn't precise enough / Saving now could say you're home while you're still down the street. |
| `arrivalCoarseOff` | Lệch khoảng {m} m | Off by about {m} m |
| `arrivalCoarseHint` | Ra gần cửa sổ hoặc ban công rồi thử lại. | Move near a window or balcony and try again. |
| `arrivalSaveAnyway` | Vẫn lưu | Save anyway |
| `arrivalPreciseTitle` / `Body` | Cần bật Vị trí chính xác / Với vị trí gần đúng, app không biết bạn đã về tới cửa hay mới ở cách nhà vài con phố. | Turn on Precise Location / With approximate location, the app can't tell your door from a few streets away. |
| `arrivalDeniedTitle` / `Body` | Chưa có quyền vị trí / Không có vị trí thì máy chưa tự báo được. Bạn vẫn bấm “Về nhà rồi” trên thẻ Home mỗi lần về, {name} nhận tin như nhau. | No location access / Without location, it can't send on its own. Tap “I'm home” on the Home card each time and {name} still gets the same message. |
| `arrivalServicesOffHint` | Định vị của máy đang tắt thì bật trong Cài đặt → Quyền riêng tư → Dịch vụ định vị. | If Location Services are off, turn them on in Settings → Privacy → Location Services. |
| `arrivalManualOnly` | Dùng bấm tay | Use manual only |
| `arrivalSavedTitle` / `arrivalAddLater` | Đã lưu Nhà / Chỗ làm và Trường thêm sau, lúc bạn đang ở đó, trong Cài đặt → Về đến nhà. | Home saved / Add Work and School later, while you're there, in Settings → Arrivals. |
| `arrivalAlwaysTitle` | Chọn “{label}” | Choose “{label}” |
| `arrivalAlwaysBody` | *(D12 màn 2 nguyên văn)* | *(D12 màn 2 nguyên văn)* |
| `arrivalNextLooksLike` | Trang tiếp theo trông như thế này | The next screen looks like this |
| `arrivalSwipeHint` (iOS) | Đừng vuốt tắt Dear Embeiu trong đa nhiệm. App bị vuốt tắt thì iPhone có thể không báo được. | Don't swipe Dear Embeiu away in the app switcher. If you do, your iPhone may not send arrivals. |
| `arrivalAutostartHint` (Android) | Máy Xiaomi, Oppo, Vivo: bật thêm Tự khởi động cho Dear Embeiu để tin báo không bị chặn. | On Xiaomi, Oppo or Vivo, also turn on Autostart for Dear Embeiu so arrivals aren't blocked. |
| `arrivalContinue` / `arrivalOpenPermission` / `arrivalLaterManual` | Tiếp tục / Mở trang quyền / Để sau, mình bấm tay | Continue / Open permissions / Later, I'll tap manually |
| `arrivalDoneTitle` / `Body` | Đã bật báo về nhà / Từ giờ về đến Nhà là {name} biết. Muốn tắt thì vào Cài đặt → Về đến nhà. Tắt là tin gần nhất bị xoá, {name} không nhận thông báo nào. | Arrivals are on / From now on, {name} knows when you get home. To turn it off, go to Settings → Arrivals. Turning it off deletes your latest update, and {name} gets no notification. |
| `arrivalDoneRow` / `Sub` | Tự báo khi đến Nhà / Thêm Chỗ làm, Trường lúc bạn đang ở đó | Sends when you reach Home / Add Work or School while you're there |
| `arrivalPartialTitle` / `Body` | Tạm thời bạn báo bằng tay / Mỗi lần về, bấm “Về nhà rồi” trên thẻ Home. {name} nhận tin y như lúc máy tự báo. Thẻ Home sẽ có nút để bật tiếp khi bạn sẵn sàng. | You'll send it manually for now / Each time you get home, tap “I'm home” on the Home card. {name} gets the same message. The card has a button to finish setup when you're ready. |
| `arrivalBackHome` | Về trang chủ | Back to Home |
| `arrivalSeesLabel` | {name} đang thấy | What {name} sees |
| `arrivalShareTitle` / `Sub` | Báo cho {name} / Tắt là xoá tin gần nhất trên máy chủ. {name} không nhận thông báo nào. | Share with {name} / Turning this off deletes your latest update from the server. {name} gets no notification. |
| `arrivalShareOffSub` | Bật lại để báo cho {name} mỗi khi bạn đến nơi. | Turn it back on to let {name} know when you arrive. |
| `arrivalAutoTitle` / `arrivalAutoSub` | Tự báo khi đến nơi / Máy tự báo khi bạn đến {places}. | Send automatically / Your phone sends it when you reach {places}. |
| `arrivalAutoNeedAlways` | Chưa tự báo được: cần quyền vị trí Luôn luôn. | Can't send on its own yet: needs Always location. |
| `arrivalAutoRemoteOff` | Tạm thời chỉ báo bằng tay. Bạn vẫn bấm “Về nhà rồi” trên thẻ Home. | Manual only for now. You can still tap “I'm home” on the Home card. |
| `arrivalPlacesTitle` / `Sub` | Địa điểm / Tối đa 3. Toạ độ chỉ nằm trên máy này, đổi máy thì lưu lại. | Places / Up to 3. Coordinates stay on this phone; set them again if you switch phones. |
| `arrivalPlaceSaved` | Bán kính {m} m · lưu {date} | {m} m radius · saved {date} |
| `arrivalPlaceNotSaved` / `Paused` | Chưa lưu / Đang tạm dừng | Not set / Paused |
| `arrivalSaveHereShort` | Lưu chỗ này | Save this spot |
| `arrivalResaveHere` / `arrivalDeletePlace` | Lưu lại bằng chỗ đang đứng / Xoá {place} | Reset to where I am / Delete {place} |
| `arrivalConfirmSaveTitle` / `Body` | Lưu chỗ đang đứng là {place}? / Vào vòng {m} m quanh đây là {name} nhận “{me} {enter}”. | Save this spot as {place}? / Step inside this {m} m circle and {name} gets “{me} {enter}”. |
| `arrivalConfirmSaveCta` | Lưu là {place} | Save as {place} |
| `arrivalPermTitle` | Quyền vị trí | Location access |
| `arrivalPermAlways` / `Sub` | Vị trí: Luôn luôn / Đủ để tự báo cả lúc app đang đóng. | Location: Always / Enough to send while the app is closed. |
| `arrivalPermWhenInUse` / `Sub` | Vị trí: Khi dùng ứng dụng / Cần “Luôn luôn” thì máy mới tự báo lúc app đang đóng. | Location: While Using / It needs “Always” to send while the app is closed. |
| `arrivalPermPrecise` / `Sub` | Vị trí chính xác: Bật / Để biết bạn đã tới cửa, không phải đầu ngõ. | Precise Location: On / So it knows you reached the door, not the end of the street. |
| `arrivalOpenDeviceSettings` | Mở Cài đặt của máy | Open phone Settings |
| `arrivalTurnOffTitle` / `Body` | Tắt báo về nhà? / Tin gần nhất của bạn bị xoá khỏi máy chủ ngay. {name} sẽ thấy “{me} chưa bật báo về nhà” và không nhận thông báo nào. | Turn off arrivals? / Your latest update is deleted from the server right away. {name} will see that your arrivals are off and won't get a notification. |
| `arrivalTurnOffAlsoPlaces` | Xoá luôn {n} địa điểm đã lưu trên máy này | Also delete the {n} saved places on this phone |
| `arrivalTurnOff` / `arrivalCancel` | Tắt / Huỷ | Turn off / Cancel |
| `settingsArrivalPushTitle` / `Sub` | Khi người ấy đến nơi / Báo khi {name} về đến nhà, chỗ làm, trường. Tắt thì thẻ Home vẫn hiện tin. | When your partner arrives / Get notified when {name} gets home, to work or to school. The Home card still shows it when this is off. |
| `settingsArrivalTitle` | Về đến nhà | Arrivals |
| `settingsArrivalSubOn` / `Off` / `Remote` | Đang báo cho {name}: {places} / Đang tắt / Tạm thời chỉ báo bằng tay | Sharing with {name}: {places} / Off / Manual only for now |
| Push + widget | y bảng §7 và §8 của PO | y bảng PO |

Ghi chú ICU: `{places}` là chuỗi ghép sẵn "Nhà · Chỗ làm" (dấu `·` có khoảng trắng hai bên, không ngắt dòng giữa tên nơi). `{what}` = nhãn nút bấm tay. Không dùng `{…}` ngoài placeholder.

**Đề xuất đổi copy (chờ PO):** (1) EN `arrivalCardTitle` "Home yet?" thay cho việc dịch sát; (2) nhãn làn của mình "Bạn" thay "Mình" (Q2).

---

## 8. Thiết bị của brand giữ lại (tasteskill cấm, design system bắt buộc) + `--allow`

| Thiết bị | Rule inspector/lint | Lý do giữ |
|---|---|---|
| Nền `dawnBlush` (gradient) | `gradient` (lint: chú thích `taste-skill-ignore`; inspector không đo được nền body) | Nền bắt buộc của mọi màn (design-system). User: "follow theo system design hiện tại". |
| Nền "Trời đêm" navy của widget | `--allow gradient` (notify) | User chốt "Giữ navy làm ngoại lệ"; widget M2 đã phát hành. |
| `IconBadge` (icon trong squircle tint) | `--allow icon-chips` | Mọi thẻ Home và hàng Cài đặt đều dùng; thiếu nó thẻ lạc khỏi cụm. |
| `PersonLabel` + `EyebrowChip` (chữ hoa nhỏ giãn chữ) | `--allow micro-label` | Primitive có sẵn (SleepCard, mọi header màn con). |
| Bóng `ContentCard` black .06 blur 16 y10 | `--allow heavy-shadow` | Bóng chuẩn duy nhất của card trắng trong app. |
| Chip widget 10 px | `--allow tiny-text` (notify) | Vẽ lại widget đã phát hành (widget-today), không phải chữ mới của feature này. |

WARN để lại, có lời bào chữa: `colour-sprawl` (17–42%) — gần hết là nền dawnBlush và nút navy cao 52 kín bề ngang; trong card chỉ có chấm màu người, tint α .10, pill pin, icon rose. `font-count`/`contrast` ở setup + notify — đó là hộp thoại và thông báo **của hệ điều hành** vẽ lại bằng phông hệ thống để thấy luồng, app không vẽ chúng. `radius-mix` (24/16/28) ở manage — đúng thang bo góc của app (card 24 · khối trong card 16 · sheet/dialog 28).

## 9. Token dùng (tất cả có sẵn trừ 1)

- Màu: `textPrimary #1A1A2E` · `textSecondary #6B6B7B` (chỉ trên trắng/tint, 4,6–5,2:1) · `textTertiary #A0A0B0` (chỉ chevron trang trí) · `accentLove #FF4D6D` · `accentLoveDeep #E63956` · `surfaceLight #F5F0F5` · `cardSurface #FFF` · `warning #FFA726` (α .18 nền pill) · `error #EF5350` (chỉ icon) · màu người `personPalette` α .10 (Thảo teal → #E7F4F3; navy trên đó 15:1, textSecondary 4,6:1).
- **Đề xuất bổ sung design system:** `AppColors.warningInk = #8A4B00` — chữ trên nền `warning` α .18 (6,0:1) và trên trắng (6,8:1). Lý do: không token nào hiện có vừa "cảnh báo nhẹ, không đỏ" vừa đạt 4,5:1 (`warning` 1,9:1, amber người 3,2:1, `accentLoveDeep` là đỏ). Dùng lại được cho mọi "pin yếu / sắp hết hạn" sau này.
- Chữ (đúng type scale, không cỡ lẻ): 11 (nhãn người, chip) · 12 (phụ đề Cài đặt, gợi ý, pill pin) · 13 (meta) · 14 (giờ, dòng của bạn, thân phụ) · 15 (nút, tiêu đề hàng, thân giải thích) · 16 (tiêu đề thẻ) · 20 (câu chính của làn, tiêu đề nhóm) · 26 (tiêu đề bước setup). Quicksand; w800 trong code = file Bold.
- Bo góc: card 24 · làn/dải/hint/menu 16 · dòng bấm 12 · sheet/dialog 28 · nút + pill 999 · IconBadge 16.
- Khoảng cách: gutter 16 · card pad 16 (thẻ), 20 (card Cài đặt) · tiêu đề → làn 12 · làn → làn bạn 14 · nhãn → dòng 2 · dòng → nút 6 · giữa nút 8 · giữa hai thẻ cùng cụm 12.
- Cao: nút trong thẻ 44 · nút toàn màn 52 · hàng chạm ≥ 44 · pill pin 24 · IconBadge 44.

## 10. A11y

- **Semantics:** làn người ấy `MergeSemantics` đọc một câu: "Thảo đã về đến nhà lúc 18:42, pin còn 12%[, báo bằng tay]"; câu, giờ, pin bên trong `ExcludeSemantics`. Nút "Hỏi thăm" đọc "Hỏi thăm Thảo". Dòng của bạn là `button` "Tự báo khi đến Nhà, Chỗ làm. Mở cài đặt Về đến nhà". Chấm bước setup: "Bước 2 trên 3". Công tắc: `Switch.adaptive` có nhãn. Ô tick trong hộp thoại: `CheckboxListTile`.
- **Live region:** xác nhận "Đã báo Thảo…", dải "Sẽ báo khi có mạng" (`liveRegion: true`), dải lỗi (`SemanticsService.announce` + vẫn hiện chữ). Thẻ đổi realtime khi Thảo về: không announce (tránh ngắt lời), chỉ cập nhật nhãn.
- **Vùng chạm:** mọi nút ≥ 44 (iOS) và hàng Android 48 qua `minimumSize`/`MaterialTapTargetSize.padded`; khoảng giữa nút 8.
- **Chữ to:** câu chính 1 dòng + ellipsis, giờ/pin `Wrap`. Từ `textScaler ≥ 1.3`: nút "Hỏi thăm" xuống hàng riêng dưới meta (LayoutBuilder: chiều rộng câu < 140 thì xuống). Nút bấm tay đã là `Wrap`.
- **Không dựa vào màu:** pin yếu có chữ "Pin còn 12%" + icon pin rỗng; trạng thái làn có chữ, không chỉ tint.
- **Tương phản:** đã tính — navy/teal α .10 15:1 · textSecondary/teal α .10 4,6:1 · `#8A4B00`/pill 6,0:1 · chữ phụ trên blush dùng navy α .78 (≥ 5,25:1; textSecondary trên blush chỉ 2,5–3,4:1 nên cấm).

## 11. Motion (AppMotion 200–320 ms, easeOutCubic)

- Thẻ vào màn: `EntranceReveal` có sẵn (đã tôn trọng Reduce Motion).
- Sự kiện mới của Thảo (realtime): `AnimatedSwitcher` 280 ms trên nội dung làn (fade + trượt lên 8 px). Reduce Motion ⇒ chỉ fade 200 ms.
- Bấm tay: `HapticFeedback.lightImpact` + đổi icon trong nút qua `AnimatedSwitcher` 200 ms, nền nút 200 ms; sau 4 s về lại. Ấn nút scale .97 (theme).
- Dải offline/lỗi: `AnimatedSize` 240 ms. Không có hiệu ứng lặp, không nhấp nháy pin yếu.
- Setup: đổi khung bằng route thường; chấm bước `AnimatedContainer` 240 ms. Spinner chỉ trong nút khi lấy vị trí.
- Tap push ⇒ cuộn tới thẻ 280 ms (Reduce Motion: `jumpTo`).

## 12. Soát UX (UI UX Pro Max 2.13.0)

Đã đọc `SKILL.md`; chạy `scripts/search.py` (không `-I`):

| Truy vấn | Kết quả | Áp dụng |
|---|---|---|
| `"touch target spacing buttons" --domain ux` | 44pt iOS / 48dp Android; ≥ 8 px giữa hai vùng chạm | Nút cao 44 (+ padded tap target Android), gap 8 giữa nút bấm tay và "Hỏi thăm". |
| `"toggle switch status label" --domain ux` | Submit Feedback (loading → success/error); Compact Label Overflow (pill/chip không xuống dòng, cho xem chữ đầy đủ) | Trạng thái bấm tay có đủ đang gửi/đã gửi/lỗi; pill pin `nowrap`; chip header dùng `EyebrowChip` (đã có tooltip khi cắt). |
| `"destructive action confirmation" --domain ux` | Confirm trước hành động không hoàn tác; báo thành công | Hộp "Tắt báo về nhà?" nêu hậu quả bằng lời; sheet xác nhận trước khi lưu địa điểm. |
| `"offline queued action feedback" --domain ux` | Loading feedback khớp thời gian chờ, giữ bố cục; haptic cho xác nhận quan trọng | Dải "Sẽ báo khi có mạng", nút giữ bề rộng, haptic nhẹ khi bấm tay. |
| `"error message recovery" --domain ux` | Error Recovery (có bước tiếp), lỗi phải được đọc (`role=alert`) | Dải lỗi có [Thử lại] + announce. |
| `"empty state guidance" --domain ux` | Empty state có câu + hành động | Trạng thái A có câu mời + 2 nút; B4 có câu "tin sẽ hiện ở đây". |
| `"reduced motion" --domain ux` | Tôn trọng Reduce Motion; 1–2 chuyển động mỗi view | Chỉ 2 chuyển động trên thẻ; bản Reduce Motion ở §11. |
| `"permission denied fallback settings" --domain ux` · `"location permission request rationale" --domain ux` | **Không có mục khớp** trong cơ sở dữ liệu | Theo nguyên tắc nền tảng (Android 11+ xin "khi dùng" trước rồi mới tới trang "Cho phép mọi lúc"; Play prominent disclosure; Apple 5.1.1) đã có trong spec PO; stack react-native có dòng "Handle permissions: kiểm và xin đúng lúc, không giả định đã có quyền" → app kiểm quyền mỗi lần resume. |
| `"switch toggle accessibility semantics" --stack flutter` | Dùng `Semantics`; thử TalkBack/VoiceOver; `MediaQuery.textScalerOf` | §10. |
| `"permission request runtime"`, `"touch target minimum size"`, `"connectivity offline"`, `"app settings open link"` `--stack flutter` | Không có mục khớp | Dùng quy ước sẵn của app (`openAppSettings` như sleep). |
| `"status warning color contrast" --domain color` | Chỉ trả về bảng màu sản phẩm khác, không có quy tắc cảnh báo | Tự tính tương phản (§9, §10) ⇒ đề xuất `warningInk`. |
| `"numeric time tabular figures" --domain typography` · `"line height readable body" --domain typography` | Không có mục khớp / chỉ ra cặp phông | Giữ Quicksand của app; giờ dùng `tabularFigures`; thân giải thích cao dòng 1.5. |

**Soát chung các thành phần đứng cạnh nhau:** (1) "Hỏi thăm" (trắng) cạnh câu chính — một nút duy nhất trong làn; (2) hàng nút bấm tay: cùng cao 44, cùng viền, cùng cỡ chữ 15 w600, icon 16 cùng nét; nút đặc (Bật / Mở Cài đặt / Lưu Nhà) đứng trước và chỉ một cái; (3) thẻ arrival cạnh `SleepCard`: cùng pad 16, cùng `IconBadge` 44, tiêu đề 16 w800, nhãn người 11 w700, vạch #F0F0F2 — đã đặt hai thẻ cạnh nhau trong khung đầu `home-card.html` để soi. (4) Cài đặt: hàng mới chép đúng khuôn `SwitchListTile`/`_navRow` có sẵn. Không có nút của bên thứ ba.

## 13. Kiểm tra: lint, inspect, 3 vòng nhìn lại

**Lệnh** (chạy từ gốc worktree): `node ~/.claude/skills/design-taste-frontend/scripts/lint.mjs --app docs/design/arrival` và `node …/inspect.mjs --app docs/design/arrival/<màn>.html --widths 390 --out .taste-skill/arrival/<màn> --allow <rule>`. Chỉ khổ 390 vì app chỉ chạy trên điện thoại.

**Kết quả cuối:**

| File | Lint | Inspect 390 | `--allow` |
|---|---|---|---|
| (cả thư mục) | 0 FAIL · 0 WARN | — | (chú thích `taste-skill-ignore` cho dawnBlush, bóng ContentCard, chip, núm công tắc, sheet/dialog, nền widget, scrim) |
| `home-card.html` | — | 0 FAIL · 1 WARN (colour-sprawl 17%) | micro-label, heavy-shadow, icon-chips |
| `setup.html` | — | 0 FAIL · 3 WARN (contrast + font-count do hộp hệ thống, colour-sprawl 42%) | micro-label, heavy-shadow, icon-chips |
| `manage.html` | — | 0 FAIL · 2 WARN (radius-mix, colour-sprawl 18%) | micro-label, heavy-shadow, icon-chips |
| `notify.html` | — | 0 FAIL · 2 WARN (font-count do thông báo hệ thống, colour-sprawl 29%) | micro-label, heavy-shadow, icon-chips, gradient, tiny-text |

**Vòng 1** (sau lần chụp đầu):
1. Thẻ — trạng thái "vừa bấm" và "mất mạng" đổi nhãn nút ("Đã báo Thảo · 19:05") làm nút rộng ra, "Đến chỗ làm rồi" rơi xuống dòng mới. ⇒ Giữ nhãn và bề rộng, chỉ đổi icon + nền; lời xác nhận chuyển lên dòng trạng thái.
2. Thẻ — "THẢO / Thảo chưa bật báo về nhà" lặp tên. ⇒ Câu bỏ tên ("Chưa bật báo về nhà", "Đang bật báo về nhà").
3. Thẻ — dòng "Tự báo khi đến…" 13 px xám, không giống chỗ bấm được. ⇒ 14 w600 navy + icon vị trí trước + chevron, hàng cao 44.
   Setup/Manage vòng 1: chữ phụ textSecondary trên blush (≈ 2,5–3,4:1) ⇒ navy α .78; nút "Tắt" trong hộp thoại thành hình tròn ⇒ pill rộng tối thiểu 96; menu địa điểm xuống 2 dòng + icon xoá sai nghĩa ⇒ menu rộng 272, icon `trash`; hàng ngăn đo thành viền đậm (inspector đọc màu bỏ alpha) ⇒ đổi sang màu đặc #F0F0F2 tương đương.
**Vòng 2:**
1. Thẻ — skeleton trong làn trùng màu nền làn, nhìn như làn trống. ⇒ thanh navy α .07.
2. Setup — "Tự báo cả lúc app đang đóng" (tiêu đề) lặp gần nguyên câu D12 ngay dưới. ⇒ Tiêu đề thành hành động "Chọn “Luôn luôn”" / "Chọn “Cho phép mọi lúc”".
3. Setup — khung Giải thích đặt xem trước push TRƯỚC tiêu đề, nên câu hỏi của màn không được đọc trước. ⇒ Tiêu đề → câu giải thích → xem trước. Khung "Đã lưu Nhà" lặp chữ trong card ⇒ card ghi "Nhà · đã lưu".
**Vòng 3:** tiêu đề trạng thái mock còn ghi "Mình chưa bật" lệch nhãn "BẠN" ⇒ sửa. Không còn lỗi nhìn thấy cần sửa ở khổ 390.

**Bảy câu §2.7 (vòng cuối, cả 4 file):**
1. *Câu hỏi có được trả lời bởi thứ to nhất, đọc trước?* Có. Thẻ: "Đã về đến nhà" 20 px là chữ to nhất trong thẻ, ngay dưới nhãn tên. Setup: tiêu đề 26 → câu giải thích. Quản lý: khối "Thảo đang thấy" đứng đầu.
2. *Mọi khối chung mép? Dải chết, card dừng ngắn, card kéo dài có khoảng trống?* Chung mép gutter 16; làn người ấy và hàng nút cùng mép trong 16. Không card nào bị kéo cao theo hàng xóm. Hàng nút bấm tay có thể chừa ~50 px bên phải khi chỉ có 2 nút — đó là khoảng còn lại của `Wrap`, không phải ô mồ côi.
3. *Màu chỉ trên dữ liệu, trạng thái và một hành động chính; face thấy trên màn đầu?* Màu người chỉ ở chấm + tint làn; vàng đất chỉ ở pin yếu; navy đặc một nút mỗi thẻ. Face (làn tint màu Thảo) thấy ngay khung đầu, đặt cạnh SleepCard dùng cùng chấm màu.
4. *Số có khớp?* Khớp qua `data.js`: 18:42/12% ở thẻ = push = widget; 17:32/19% ở trạng thái rời; Tuấn 08:05/64% ở "Thảo đang thấy"; 1.255 ngày, còn 45 tới 1.300; 2 push ≤ 6. Mọi giờ tương đối có mốc ("hôm qua 22:58").
5. *Số 0 và giá trị thiếu?* Không pin ⇒ không hiện phần pin (không in "—%"). Không tin trong 3 ngày ⇒ câu trạng thái, không ô trống. Không có badge đếm.
6. *Chú giải, nhãn đè nhau?* Không có biểu đồ. Không nhãn nào đè; pill pin không xuống dòng.
7. *Trên điện thoại, điều hướng gọn và mỗi khối vẫn trả lời câu hỏi?* Có, chỉ có khổ điện thoại; nav nổi của Home không đổi.

**Còn yếu (ghi thật):** thẻ đầy đủ cao ~300 dp, Home đã dày (Q3). Widget vừa xuống 2 dòng với "Thảo đã về đến nhà" (giới hạn có sẵn của widget-today). Mock dùng ảnh mẫu của brand-v2 cho widget có ảnh — không phải ảnh cặp DEV.

## 14. Dev notes

- **⚠️ Push opt-out đã bị gỡ toàn app (2026-06-14):** `NotificationSettingsService.currentOrDefault()` ép mọi khoá = `true`, Cài đặt không còn mục tắt từng loại. D16 cần `pushArrival` đọc **giá trị thật**: thêm khoá vào `allKeys` và cho riêng khoá này đọc Hive (các khoá cũ giữ ép true), rồi đăng ký lại thiết bị khi đổi. Không thì công tắc "Khi người ấy đến nơi" là công tắc giả.
- **Bấm tay khi chưa bật** (trạng thái A/M2): lần bấm đầu = ghi `share:true, auto:false` + `last` (một lần ghi). Sau đó làn của bạn ở M6 "Đang báo bằng tay". Rules hiện đòi `share==true` mới có `last` nên phải ghi chung một lần.
- **Tách `PersonLabel`** ra `lib/widgets/person_label.dart` (sleep và arrival cùng dùng). Màu người: dùng `PersonPalette.resolve` như sleep; nếu người dùng chưa từng bật sleep thì chưa có `color` ⇒ Q4.
- **Thời gian:** hôm nay → `HH:mm`; hôm qua → `arrivalYesterdayAt`; 2–3 ngày → `d/M HH:mm`; > 3 ngày (theo `at` so với đồng hồ máy người nhận) → B4. Dùng `MidnightBuilder` có sẵn để "hôm nay"/"hôm qua" tự đổi lúc 0:00.
- **Thứ tự nút bấm tay:** Nhà, Chỗ làm, Trường; chỉ nơi đã lưu; "Về nhà rồi" luôn có kể cả chưa lưu Nhà (D7).
- **Hỏi thăm:** `openCareMessageScreen(BuildContext)` (`lib/screens/care_message_screen.dart:25`) hiện chỉ nhận `context` ⇒ Dev thêm tham số tuỳ chọn để đặt sẵn chip gợi ý `arrivalCareSuggestion` (không đổi hành vi các lối vào cũ).
- **Kiểm quyền mỗi lần resume** (D8): đổi giữa M1/M3 không cần mở lại app. Mở Cài đặt: iOS `app-settings:`, Android trang quyền vị trí của app.
- **Setup — sai số:** nếu `accuracy > 100 m` hiện khung "chưa đủ chuẩn"; "Vẫn lưu" vẫn cho phép. Timeout lấy vị trí 15 s.
- **Widget:** không có chuỗi mới ngoài bảng PO; `statusFocus = 'arrival'`.
- **Cài đặt → Chung:** hàng "Về đến nhà" chèn trước "Ảnh nền thẻ đếm".

## 15. Acceptance (design)

- [x] Mọi trạng thái có hình (`home-card` 14 khung, `setup` 12, `manage` 7, `notify` 6) và mô tả (§3.3, §4, §5).
- [x] Copy đủ vi + en (§7), copy chốt của PO giữ nguyên.
- [x] Map từng phần sang widget có sẵn / widget mới (§3.2, §4, §5, §6).
- [x] Lint 0 FAIL, inspect 0 FAIL ở 390, WARN có lời bào chữa, rule allow có lý do (§8, §13).
- [x] Tra UI UX Pro Max, soát chung thành phần cạnh nhau (§12).

## 16. Câu hỏi cho PO / user

- **Q1 (user brief ↔ spec):** brief giao việc nhắc "đổi tên, bán kính", nhưng spec §3 + D1 chốt tên cố định theo loại và bán kính 150 m do Dev chỉnh sau spike. Thiết kế theo spec: không ô đổi tên, không thanh trượt bán kính. Giữ vậy chứ?
- **Q2:** nhãn làn của mình ghi "BẠN" (khớp `SleepCard` ngay trên) thay vì "Mình" như câu ví dụ trong §8 PO. Đồng ý không?
- **Q3 (cho người ghép Home):** thẻ đầy đủ cao ~300 dp. Nếu Home quá dài, phương án gọn: chỉ hiện làn người ấy + một nút "Về nhà rồi" (các nơi khác vào màn Quản lý). Có chấp nhận làm biến thể gọn không?
- **Q4:** người chưa từng bật giấc ngủ thì chưa có màu riêng. Lấy màu mặc định theo `PersonPalette.firstFreeAgainst` (như sleep) hay mở bộ chọn màu trong màn Quản lý?

## Nhật ký design
- [2026-10-20] [Designer] Đi trọn run tasteskill app-screens (§2.1–2.8) với sheet chung đợt 2 (editorial-greeting, seed 1822703143, `--keep palette,type`), face "cặp đôi là các làn" + signature "dòng đến nơi" (câu + giờ + pin vàng đất khi ≤ 20%). Thiết kế thẻ Home 17 trạng thái, luồng bật 3 bước có hộp giải thích Play, màn quản lý (khối "Thảo đang thấy", tắt = xoá + ô xoá địa điểm), push/widget/2 dòng Cài đặt. Mock 4 trang + `data.js` 17 assert ở `docs/design/arrival/`. Lint 0/0; inspect 390 0 FAIL cả 4 trang (allow micro-label, heavy-shadow, icon-chips; notify thêm gradient, tiny-text). 3 vòng nhìn lại ghi ở §13. Tra UI UX Pro Max (12 truy vấn, §12). Đề xuất token `warningInk #8A4B00`. Phát hiện cho Dev: push opt-out đang bị ép bật toàn app ⇒ `pushArrival` cần đọc giá trị thật. 4 câu hỏi PO/user.
