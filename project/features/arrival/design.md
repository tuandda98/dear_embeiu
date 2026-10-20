# 🎨 Design — Về đến nhà chưa? (arrival)

> Designer sở hữu. Đọc `overview.md` (PO) trước. Bám `project/design-system.md` + code thật `lib/theme/`, `lib/widgets/`. CHỈ thiết kế, không code.

- **Trạng thái design:** bản 2 xong (nơi tự đặt + tìm địa chỉ), chờ PO duyệt. Bản 1 (3 nơi cố định) đã thay hết.
- **Người/role:** Designer
- **Mock bấm thử (mở thẳng bằng trình duyệt):** [`docs/design/arrival/`](../../../docs/design/arrival/)
  - `home-card.html` — thẻ Home, 17 trạng thái + sheet "Đến nơi rồi"
  - `place.html` — **mới:** thêm nơi (tên + biểu tượng), tìm địa chỉ iPhone/Android, không thấy, mất mạng, máy không tìm được địa chỉ, dùng vị trí hiện tại, 3 kiểu xác nhận, sửa nơi, sửa Nhà, hỏi lại khi xoá (16 khung)
  - `setup.html` — bật tự báo: chưa có nơi nào có vị trí → giải thích Play → hộp hệ thống → Luôn luôn iOS/Android → xong/dừng giữa chừng (7 khung)
  - `manage.html` — màn quản lý + 5 trạng thái/hộp thoại
  - `notify.html` — push Nhà/nơi tự đặt (vi, en), widget nhỏ/vừa, 2 dòng Cài đặt
  - `data.js` (dữ liệu mẫu + 18 `console.assert`), `ui.js` (icon), `card.js` (render thẻ), `app.css` (token lấy từ code)
- **Ảnh chụp inspector:** `.taste-skill/arrival/{home-card,place,setup,manage,notify}/`

## Đầu vào

- Spec PO `overview.md` bản sửa 2026-10-20: D1 (≤5 nơi, 150 m vị trí hiện tại / 250 m địa chỉ), D2 (địa chỉ chỉ trên máy), D7 (nút chính "Về nhà rồi" + phụ "Đến nơi rồi"), D8 (lưu bằng địa chỉ không cần quyền, "Luôn luôn" chỉ khi bật tự báo), D19 (Nhà cố định + 4 nơi tự đặt, tên 1–24, 7 biểu tượng), D20 (geocoder hệ điều hành), D21 (xác nhận bằng chữ, không bản đồ), D23 (`last` mang tên + biểu tượng). Copy chốt: D12, §7, §8.
- User 2026-10-20: "cho setting việc đi đâu, không cố định chỗ làm hay nhà, nhưng mặc định để về nhà, cho khách nhập địa chỉ… xin phép khách sử dụng vị trí hiện tại nếu khách không tìm thấy địa chỉ"; "dùng UI-UX promax thiết kế, … phù hợp với người dùng và UI tiện lợi dễ sử dụng"; trước đó: tasteskill trọn run, "follow theo system design hiện tại của app".
- Lead chốt: thẻ hai người, **Bạn trái · người ấy phải**, nhãn "Bạn"; thẻ **đứng riêng** trên Home ("mọi thứ một thẻ riêng"); có biến thể gọn nếu Home quá dài; người chưa bật giấc ngủ dùng màu mặc định như sleep; một đường tắt (công tắc + ô "xoá luôn").
- Style: sheet chung `docs/design/daily-open-2/sheet.raw.md` (editorial-greeting, seed 1822703143, `--keep palette,type`). Không draw lại.

---

## 1. Run tasteskill (app-screens §2.1–2.4)

### 2.1 Kiểm kê dữ liệu và việc

- **Đối tượng:** trên máy chủ một doc mỗi người `arrival/{uid}` = `share` · `auto` · `last {place: home|p1..p4, name?, icon?, type, at, battery?, source, bounce?}`. Danh sách nơi, địa chỉ, toạ độ chỉ ở Hive trên máy.
- **Độ lớn thật:** 1–5 nơi mỗi người (Nhà luôn có); 1–3 lần đến/ngày; ≤6 push/ngày; tên nơi 1–24 ký tự người dùng tự gõ (vd "Nhà ngoại ở Thanh Xuân" = 22); địa chỉ VN kiểu mới không còn quận ("54 Liễu Giai, Phường Ngọc Hà, Hà Nội").
- **Người và lúc dùng:** cặp đôi trẻ, một tay, lướt nhanh. Thêm nơi: vài lần trong đời app, lúc rảnh. Bấm "Về nhà rồi": tối, vừa dắt xe vào nhà. Liếc thẻ: lúc chờ người kia về.
- **Việc, theo tần suất:** liếc xem người ấy về chưa → bấm "Về nhà rồi" → gửi "Hỏi thăm" → "Đến nơi rồi" cho nơi khác → thêm/sửa nơi → bật/tắt.
- **Thứ chỉ app này có:** tên hai người, màu riêng mỗi người (`personPalette`), **tên nơi do chính người ấy đặt** ("Phòng gym", "Nhà bố mẹ") + biểu tượng, pin lúc đến.
- **Dữ liệu mẫu** (`data.js`): Thảo rời nhà 07:20 (96%) → Công ty 07:58 (91%) → rời 17:32 (24%) → Phòng gym 17:50 (22%) → rời 18:30 (15%) → về nhà 18:42 (12%). Tuấn đến Công ty 08:05 (64%). Nơi của Tuấn: Nhà (Ngõ 72 Nguyễn Trãi, Phường Thanh Xuân, Hà Nội), Công ty (54 Liễu Giai, Phường Ngọc Hà, Hà Nội), Phòng gym (lưu bằng vị trí hiện tại). Assert: 3 lần đến = 3 push (07:58, 17:50, 18:42); push Nhà "Thảo đã về đến nhà / Pin còn 12%"; push gym "Thảo đã đến Phòng gym / Nhắn một câu hỏi thăm nhé" (22% > 20); widget = tiêu đề push; ≤5 nơi, Nhà luôn đầu; tên 1–24 + icon hợp lệ; bán kính khớp nguồn (150/250); đi đổ rác 6 phút không sinh push; 1.255 ngày bên nhau. Địa chỉ là **mẫu**, Dev đo lại khi spike geocoder (§6.8 PO).

### 2.2 Câu hỏi · finding · việc chính từng màn

| Màn | Câu hỏi | Finding đọc trước | Việc chính |
|---|---|---|---|
| Thẻ Home | Thảo về đến nơi chưa? | "Đã về đến nhà · 18:42 · Pin còn 12%" | "Về nhà rồi" (1 chạm) · "Hỏi thăm" (1 chạm) |
| Thêm nơi | Chỗ này tên gì, người ấy thấy chữ gì? | Xem trước "Thảo sẽ thấy: Tuấn đã đến Phòng gym" | chạm chip gợi ý → Tiếp tục |
| Tìm địa chỉ | Chỗ đó ở đâu? | Dòng gợi ý đúng số nhà + phường | chạm một dòng kết quả |
| Xác nhận | Đúng chỗ chưa? | Địa chỉ đầy đủ + "báo khi vào trong khoảng 250 m" (+ cảnh báo thiếu số nhà) | Lưu |
| Bật tự báo | Bật thì người ấy thấy gì? | Người ấy chỉ thấy tên nơi, giờ, pin | Đồng ý, tiếp tục |
| Quản lý | Mình đang chia sẻ gì, ở những nơi nào? | "Thảo đang thấy: Đã đến Công ty · 08:05" | công tắc "Báo cho Thảo" · chạm một nơi để sửa |
| Push/widget | Tin đến tay người ấy trông thế nào? | "Thảo đã đến Phòng gym" | chạm → Home |

### 2.3 Style · face · signature

- **Map vai trò:** ground = `dawnBlush` · surface = `ContentCard` trắng · panel tông = tint màu người α .10 / `surfaceLight` · rule = #F0F0F2 · control = navy α .18 · text = `textPrimary` · muted = `textSecondary` (chỉ trên trắng) · primary = navy · accent = `accentLove` · warning = `warning` α .18 + `#8A4B00` (token mới).
- **Face: "cặp đôi là các làn".** Hai làn cạnh nhau, mỗi làn tô màu riêng của người đó α .10 (Tuấn hồng nhạt, Thảo ngọc nhạt) — đúng gợi ý của sheet "mỗi người một hue nhạt trên làn của mình". Bạn trái, người ấy phải (Lead), khớp thứ tự thẻ "Đêm qua".
- **Signature: "dòng đến nơi"** = câu ("Đã đến Phòng gym") + biểu tượng nơi người ấy tự chọn + giờ + pin (vàng đất khi ≤ 20%).
- Sheet viết cho Home desktop (greeting, lưới 12 cột) — không áp cho một thẻ trên điện thoại; giữ ý "con số weight thường trên panel tông".

### 2.4 Shell

Chỉ điện thoại ⇒ inspector chỉ 390. Shell sẵn của app: Home (chip header + nav nổi) cho thẻ; `SubScreenHeader` (← + `EyebrowChip` "VỀ ĐẾN NHÀ") cho mọi màn con; nền `dawnBlush` vẽ một lần. Lưới: gutter 16, card pad 16, hai làn mỗi làn (358 − 32 − 8)/2 = 159 dp.

---

## 2. Màn và luồng

```
Home (cặp active)                         waiting_partner → không thẻ, không dòng Cài đặt (D9)
 └─ Thẻ "Về đến nhà chưa?" (đứng riêng)
     ├─ [Về nhà rồi] (nút chính) ─► ghi last(home, manual) ─► push Thảo. Không cần quyền, không cần địa chỉ.
     ├─ [Đến nơi rồi ▾] ─► sheet "Bạn vừa đến đâu?" (các nơi ngoài Nhà) ─► chạm 1 nơi = gửi  · [+ Thêm nơi]
     ├─ [Hỏi thăm] (làn Thảo) ─► CareMessageScreen, gợi ý sẵn "Về tới nơi rồi thì nghỉ ngơi nhé"
     ├─ [Bật báo về nhà] (khi chưa bật) ─► BẬT TỰ BÁO
     └─ chạm tiêu đề / dòng "Tự báo: …" ─► QUẢN LÝ

THÊM NƠI (màn con)                        không hỏi quyền nào nếu tìm được địa chỉ
 Tên + biểu tượng ─[Tiếp tục]─► Tìm địa chỉ ─chạm kết quả─► Xác nhận ─[Lưu]─► Quản lý (hoặc về chỗ gọi)
   chip gợi ý tự điền tên + tự chọn biểu tượng       │
                                                     ├─ không thấy / mất mạng / máy không tìm được
                                                     │     └─[Dùng vị trí hiện tại]─► giải thích ngắn ─[Đọc vị trí]─► hộp hệ thống
                                                     │           (khi dùng app + chính xác) ─► Đang đọc ─► Xác nhận 150 m
                                                     │           từ chối ⇒ quay lại ô địa chỉ, không hỏi lại tự động
                                                     └─ dòng cuối danh sách luôn là "Không thấy địa chỉ? Dùng vị trí hiện tại"
 Nhà: bỏ bước tên/biểu tượng, vào thẳng Tìm địa chỉ.
SỬA NƠI: tên · biểu tượng · dòng Vị trí (chạm → Tìm địa chỉ) · "Xoá nơi này" (thẻ riêng, hỏi lại) · [Lưu]
SỬA NHÀ: dòng Vị trí · "Xoá địa chỉ" (hỏi lại). Không đổi tên, không xoá Nhà.

BẬT TỰ BÁO (công tắc ở Quản lý hoặc nút trên thẻ)
 chưa có nơi nào có vị trí ─► "Trước hết, nhà bạn ở đâu?" [Đặt địa chỉ Nhà] ─► THÊM NƠI (Nhà)
 1 Giải thích Play (D12) ─[Đồng ý, tiếp tục]─► hộp hệ thống "khi dùng app" (bỏ qua nếu đã có)
 2 "Chọn “Luôn luôn”" / "Chọn “Cho phép mọi lúc”" ─► hộp/trang hệ thống ─► Xong | Dừng giữa chừng (bấm tay)

QUẢN LÝ: "Thảo đang thấy" · [Báo cho Thảo] · [Tự báo khi mình đến nơi] · Nơi báo (Nhà + ≤4, + Thêm nơi) · Quyền vị trí
 Tắt "Báo cho Thảo" ─► hộp "Tắt báo về nhà?" (+ ô "Xoá luôn địa chỉ đã lưu") ─► xoá last, không báo Thảo
```

---

## 3. Thẻ Home — `ArrivalCard` (thành phần lối vào Home)

**Cho người ghép Home:** một `ContentCard` đứng riêng (không gộp với "Đêm qua", theo user). Cao ~300 dp đầy đủ (2 làn + hàng nút), ~190 dp lần đầu, ~330 dp khi tên nơi dài nhất kéo câu thành 3 dòng. Ẩn với cặp đang chờ. Biến thể gọn (Lead cho phép): bỏ làn Bạn, chỉ còn làn Thảo + hàng nút → ~230 dp.

### 3.1 Cấu trúc (390 dp)

```
┌ ContentCard r24, pad 16 ─────────────────────────────────────────┐
│ [IconBadge home_2 44]  Về đến nhà chưa?  16 w800             ›   │ chạm 44 → Quản lý
│ gap 12                                                           │
│ ┌ làn Bạn: r16 pad 12, tint Tuấn α.10 ┐ ┌ làn Thảo: tint Thảo α.10 ┐│ gap 8, cao bằng nhau
│ │ ● BẠN            11 w700 ls1.0       │ │ ● THẢO                    ││
│ │ Đã đến Công ty   18 w700, ≤3 dòng    │ │ Đã về đến nhà             ││
│ │ [▢] 08:05  ▭ 64%  14 w700 · 13 w600  │ │ [⌂] 18:42                 ││
│ │                                      │ │ [▭ Pin còn 12%] pill 24   ││
│ │ (⌖) Tự báo: Nhà và 2 nơi khác  12w600│ │ (♡) Hỏi thăm   chữ 14 w700││ neo đáy làn
│ └──────────────────────────────────────┘ └───────────────────────────┘│
│ gap 12                                                           │
│ [⌂ Về nhà rồi]  [⌖ Đến nơi rồi ⌄]   cả hai viền navy .18, h44, gap 8 │
└──────────────────────────────────────────────────────────────────┘
```

### 3.2 Map sang widget Flutter

| Phần | Dùng | Ghi chú |
|---|---|---|
| Khung | `ContentCard(padding: EdgeInsets.all(16))` (`lib/widgets/content_card.dart`) | |
| Tiêu đề | `IconBadge(IconsaxPlusLinear.home_2)` + `Text` 16 w800 + chevron `arrow_right_3` 18 `textTertiary`, cả hàng `InkWell` r16 | |
| Hai làn | `Row(crossAxisAlignment: stretch)` trong `IntrinsicHeight`, 2 × `Expanded`, gap 8 | **mới** `_Lane`: `Container` r16 pad 12, `PersonPalette.colorOf(id).withValues(alpha: .10)`; chưa bật = `surfaceLight` |
| Nhãn người | `PersonLabel` — tách từ `lib/widgets/sleep/sleep_card.dart` ra `lib/widgets/person_label.dart` | nhãn mình = "Bạn" (`sleepYou` hoặc key mới `arrivalYou`) |
| Câu | `Text` 18 w700 `textPrimary`, `maxLines: 3`, ellipsis | `{place}` là tên người dùng gõ, không dịch |
| Dòng meta | `Wrap(spacing 6)`: icon nơi 16 navy · giờ 14 w700 tabular `DateFormat.Hm(locale)` · pin | icon theo khoá (bảng §4.2) |
| Pin thường | `battery_3full` 14 + "64%" 13 w600 `textSecondary` | |
| Pin ≤ 20% | **mới** `_BatteryLowPill` h24 r999, nền `warning` α .18, icon `battery_empty` 14 + "Pin còn 12%" 12 w700 `warningInk #8A4B00` | |
| "bấm tay" | 13 w600 `textSecondary` dưới meta | chỉ `source == manual` |
| Hỏi thăm | `TextButton.icon` cao 44, icon `message_favorite` 16 `accentLoveDeep`, chữ 14 w700 navy, neo đáy làn | |
| Dòng trạng thái của bạn | **mới** `_MineStatus`: `InkWell` minHeight 44, icon 14 navy (`location`/`location_slash`) + 12 w600 navy, neo đáy làn | 1–2 nơi: liệt kê tên; ≥ 3: "Nhà và N nơi khác" |
| Link trong làn | `TextButton` 13 w700 gạch chân ("Mở Cài đặt", "Đặt địa chỉ") | |
| Nút chính | `OutlinedButton.icon` viền navy α .18 1.5, pill h44, icon `home_2` 16, "Về nhà rồi" — **viền, không đặc** (Lead 2026-10-20: Home đã có nút đặc của câu hỏi + caro, ba nút đặc thì mắt không biết việc nào chính). Đứng đầu hàng = vai chính | luôn có (D7) |
| Nút phụ | `OutlinedButton.icon` viền navy α .18, icon `location` 16 + chevron `arrow_down_1` 16, "Đến nơi rồi" | chỉ khi có ≥ 1 nơi ngoài Nhà |
| Sheet "Đến nơi rồi" | `showModalBottomSheet` khung sheet chuẩn (r28 trên, handle 36×4) — tiêu đề 20 w700 "Bạn vừa đến đâu?", danh sách nơi (IconBadge navy α .06 + tên 15 w700, hàng 64), `TextButton` "+ Thêm nơi", câu 12 "Bấm là Thảo nhận … ngay, không cần quyền vị trí" | chạm 1 dòng = gửi + đóng sheet |
| Dải offline/lỗi | **mới** `_InlineStrip` r16 nền `surfaceLight` | |
| Đang tải | `ShimmerSkeleton` đúng kích thước hai làn + hai nút | |

### 3.3 Trạng thái thẻ (`home-card.html`)

| Khung | Làn Bạn | Làn Thảo | Hàng nút |
|---|---|---|---|
| Mặc định | Đã đến Công ty · 08:05 · 64% · "Tự báo: Nhà và 2 nơi khác" | Đã về đến nhà · 18:42 · Pin còn 12% · Hỏi thăm | Về nhà rồi · Đến nơi rồi |
| Thảo đến nơi tự đặt | | Đã đến Phòng gym · [tạ] 17:50 · 22% | |
| Tên dài nhất | | "Đã đến Nhà ngoại ở Thanh Xuân" 3 dòng | |
| Thảo rời (không push) | | Đã rời Công ty · 17:32 · 24% | |
| Tin hôm qua, bấm tay | | hôm qua 22:58 · 40% · bấm tay | |
| Thảo bật, 3 ngày không tin | | "Đang bật báo về nhà" + "Khi Thảo đến nơi, tin sẽ hiện ở đây." | |
| Thảo chưa bật / đã tắt | | nền `surfaceLight`, "Chưa bật báo về nhà", không nút | |
| Lần đầu cả hai chưa bật | — một câu mời — | | Bật báo về nhà (đặc, chỉ lúc chưa bật) · Về nhà rồi (viền) |
| Bạn chưa bật | "Chưa bật báo về nhà" | (tin của Thảo) | Bật báo về nhà · Về nhà rồi |
| Vừa lưu nơi bằng địa chỉ (D21) | Đã đến Phòng gym 18:05 + "✓ App đã nhận ra Phòng gym" | | |
| Thiếu Luôn luôn | "Chưa tự báo được: cần quyền vị trí Luôn luôn" + link Mở Cài đặt | | |
| Chưa đặt địa chỉ nơi nào | "Chưa có tin hôm nay" + "Chưa đặt địa chỉ Nhà" + link Đặt địa chỉ | | chỉ "Về nhà rồi" |
| Tắt từ xa | "Tạm thời chỉ báo bằng tay" | | |
| Vừa bấm Về nhà rồi | Đã về đến nhà 19:05 · bấm tay + "✓ Đã báo Thảo" (live region) | | nút viền giữ nhãn + bề rộng, nền navy α .06, icon thành tick 4 s |
| Mất mạng | | | nút icon `cloud_cross` + dải "Sẽ báo khi có mạng. Quá 30 phút thì Thảo chỉ thấy trên thẻ, không nhận thông báo." |
| Lỗi ghi | | | dải "Chưa gửi được tin “Về nhà rồi”." + Thử lại |
| Đang tải | skeleton | skeleton | skeleton |

Tin cũ hơn 3 ngày ⇒ "Đang bật báo về nhà". 2–3 ngày: "18/10 22:58".

---

## 4. Thêm / sửa nơi (`place.html`) — màn con mới

Khung chung: `SubScreenHeader(badge: arrivalBadge, badgeIcon: home_2)`, tiêu đề 26 w700, **nút chính neo đáy** (`bottomNavigationBar`/`SafeArea` pad 16, đi lên theo bàn phím bằng `MediaQuery.viewInsets`), nội dung cuộn phía trên. Ô nhập: nền trắng (trên blush), r20, cao 52, chữ 16 w600, focus viền `accentLove` 1.4 (theme input), nhãn 13 w700 navy **phía trên** ô.

### 4.1 Tên + biểu tượng ("Nơi mới")
- Ô "Tên nơi", bàn phím chữ, `textCapitalization.sentences`, `maxLength 24` (bộ đếm "9/24" bên phải dòng nhắc), dòng nhắc trái: **"Người ấy sẽ thấy tên này khi bạn đến."**
- 5 chip gợi ý (`ChoiceChip`-style pill h36, nền white .72, chọn = navy chữ trắng): Công ty · Trường · Nhà bố mẹ · Phòng gym · Quán quen. **Chạm chip = điền tên + tự chọn biểu tượng** (Công ty→work, Trường→school, Nhà bố mẹ→family, Phòng gym→gym, Quán quen→cafe). Gõ tay thì biểu tượng giữ mặc định `pin`.
- Hàng 7 biểu tượng: nút 44 r16, chọn = navy icon trắng, còn lại white .72 icon navy; `Semantics` radio có nhãn (Công việc, Trường, Gia đình, Tập luyện, Quán, Mua sắm, Chỗ khác).
- Hộp xem trước (white .72 r16): "Thảo sẽ thấy: **Tuấn đã đến Phòng gym**" cập nhật theo tên (live region).
- [Tiếp tục] khoá khi tên rỗng sau khi cắt khoảng trắng; dòng 12 "Gõ tên để tiếp tục. Tối đa 24 ký tự."

### 4.2 Biểu tượng (khoá → Iconsax Linear)
`work` briefcase · `school` teacher · `family` people · `gym` weight_1 · `cafe` coffee · `shop` shop · `pin` location · Nhà: home_2.

### 4.3 Tìm địa chỉ ("Phòng gym ở đâu?")
- Câu phụ "Gõ số nhà, tên đường và phường cho chuẩn nhất." Ô tìm có icon `search_normal` 20 + nút xoá `close_circle` 18 (vùng chạm 44). Placeholder (PO): "Vd: 12 Nguyễn Trãi, Thanh Xuân, Hà Nội".
- Danh sách trong card trắng r24, hàng ≥ 56: icon `location` 18 + dòng 1 = số nhà + đường 15 w700 (iOS gạch chân phần khớp chữ đang gõ) + dòng 2 = phường, tỉnh 12 w500 `textSecondary`. **Dòng cuối luôn là** `gps` 18 + "Không thấy địa chỉ? Dùng vị trí hiện tại" (gạch chân) / "Hãy bấm khi bạn đang đứng ở đó".
- **iPhone:** gợi ý hiện ngay khi gõ (debounce 300 ms).
- **Android:** sau 800 ms ngừng gõ (hoặc bấm Tìm) hiện hàng "Đang tìm…" + spinner 16, rồi ≤ 5 kết quả; dòng 12 dưới card "Gõ xong bấm Tìm trên bàn phím nếu chưa thấy kết quả." (`TextInputAction.search`).
- **Không thấy:** câu PO trong card + nút chính neo đáy [Dùng vị trí hiện tại].
- **Mất mạng:** "Cần mạng để tìm địa chỉ. Có mạng lại thì gõ tiếp, hoặc dùng vị trí hiện tại khi bạn đang ở đó." + [Dùng vị trí hiện tại]. `role=alert`.
- **Máy không tìm được địa chỉ** (`Geocoder.isPresent()==false`): ẩn ô tìm, câu "Máy này không tìm được địa chỉ. Bạn lưu bằng vị trí hiện tại lúc đang đứng ở đó." + [Dùng vị trí hiện tại] + [Lưu tên, chỉ bấm tay].

### 4.4 Dùng vị trí hiện tại
- Khung giải thích ngắn trước hộp hệ thống: "Bạn đang ở Phòng gym?" + "App đọc vị trí một lần để lưu chỗ này. Toạ độ chỉ nằm trên máy bạn." + hộp gợi ý "Lần đầu, máy sẽ hỏi quyền vị trí. Chọn “Cho phép khi dùng ứng dụng” và để Vị trí chính xác bật." + [Đọc vị trí] / [Quay lại tìm địa chỉ].
- Đang đọc: nút khoá + spinner "Đang đọc vị trí…" (timeout 15 s → báo lại, cho thử lại). Từ chối quyền ⇒ về ô địa chỉ, không hỏi lại tự động. Chỉ cấp gần đúng ⇒ dòng "Cần bật Vị trí chính xác…" + [Mở Cài đặt] (copy giữ từ bản 1).

### 4.5 Xác nhận ("Đúng chỗ này chưa?", D21)
Card trắng pad 20: hàng IconBadge navy + tên 15 w700 + nguồn 12 ("Từ địa chỉ" / "Vị trí hiện tại của bạn, lệch khoảng 12 m") → địa chỉ đầy đủ 16 w700 tối đa 2 dòng → **"App báo khi bạn vào trong khoảng 250 m quanh đây."** (150 m khi vị trí hiện tại) → nếu thiếu số nhà: hộp vàng `warning` α .18 + icon + "Địa chỉ này chưa có số nhà, app có thể báo hơi sớm hoặc hơi muộn." (`#8A4B00` 13 w700). Nút neo đáy [Lưu] + link "Không đúng chỗ? Dùng vị trí hiện tại khi bạn đang ở đó" (vị trí hiện tại: "Đọc lại vị trí"). Lưu xong: SnackBar "Đã lưu Phòng gym" và quay về chỗ gọi.

### 4.6 Sửa nơi / sửa Nhà / xoá
- Sửa nơi: ô tên (dòng nhắc "Đổi tên chỉ áp cho lần đến sau."), hàng biểu tượng, nhãn "Vị trí" + card 1 hàng (địa chỉ rút gọn / "Lưu bằng vị trí hiện tại" + "Lưu từ địa chỉ · 13/10" ›, chạm → Tìm địa chỉ), rồi **card riêng** "Xoá nơi này" (icon `trash` màu `error`, chữ navy) tách khỏi nút Lưu, nút [Lưu] neo đáy (khoá tới khi có thay đổi).
- Sửa Nhà: "Nhà luôn có trên thẻ. Bạn chỉ đổi được chỗ của nó." + card Vị trí (chạm → Tìm địa chỉ) + card "Xoá địa chỉ" ("Nhà chỉ còn bấm tay “Về nhà rồi”."). Không nút Lưu (đổi địa chỉ lưu ở bước Xác nhận).
- Xoá: `AlertDialog` r28 "Xoá Phòng gym?" / "App thôi báo khi bạn đến đây. Tin đã gửi trước đó vẫn giữ tên cũ." [Huỷ] [Xoá]. Xoá địa chỉ Nhà: "Xoá địa chỉ Nhà?" / "Nhà vẫn còn trên thẻ, bạn bấm “Về nhà rồi” mỗi lần về." Xoá nơi cuối cùng có vị trí khi đang tự báo ⇒ công tắc "Tự báo" tắt theo.

---

## 5. Bật tự báo (`setup.html`)

- Chỉ chạy khi người dùng bật "Tự báo khi mình đến nơi" (D8.2). Lưu nơi bằng địa chỉ không đi qua đây.
- **Chưa có nơi nào có vị trí:** "Trước hết, nhà bạn ở đâu?" + "Máy cần biết Nhà ở đâu thì mới tự báo được. Gõ địa chỉ là xong, chưa cần cấp quyền gì." + card Nhà "Chưa đặt địa chỉ" + [Đặt địa chỉ Nhà] (→ §4.3) / [Để sau].
- **Bước 1 — giải thích Play** (2 chấm bước): tiêu đề "Về đến nơi, Thảo biết ngay" → **câu D12 mới nguyên văn** 15 w500 navy ngay dưới tiêu đề → nhãn "Thảo sẽ nhận được" + xem trước push "Tuấn đã đến Công ty / Nhắn một câu hỏi thăm nhé" → link Chính sách bảo mật → [Đồng ý, tiếp tục] / [Để sau] neo đáy.
- **Hộp hệ thống** khi dùng app + chính xác (bỏ qua nếu đã có từ lúc "Dùng vị trí hiện tại"), câu `NSLocationWhenInUseUsageDescription` mới.
- **Bước 2:** iOS "Chọn “Luôn luôn”" / Android "Chọn “Cho phép mọi lúc”" + câu D12 màn 2 + "Trang tiếp theo trông như thế này" (danh sách giả, dòng đích nền navy α .06 + tick) + gợi ý (iOS: đừng vuốt tắt; Android: Tự khởi động Xiaomi/Oppo/Vivo) + [Tiếp tục] / [Mở trang quyền] · [Để sau, mình bấm tay].
- **Xong:** "Đã bật báo về nhà" + câu tắt ở đâu + card "Tự báo khi đến Nhà / Thêm Công ty, phòng gym… để báo cả những chỗ đó ›" + [Về trang chủ]. **Dừng giữa chừng:** "Tạm thời bạn báo bằng tay" + "Các nơi đã lưu vẫn giữ nguyên." + [Về trang chủ].
- Video Play ≤ 30 s: thẻ Home → Bật báo về nhà → Giải thích (dừng 3 s) → hộp khi dùng app → Chọn "Cho phép mọi lúc" → trang quyền → về nền, giả lập vị trí ra/vào → push trên máy kia.

## 6. Quản lý (`manage.html`)

1. "Thảo đang thấy" → làn của bạn (tint Tuấn α .10): "● TUẤN / Đã đến Công ty / [▢] 08:05 · 64%"; tắt ⇒ `surfaceLight` "Chưa bật báo về nhà".
2. Card công tắc: "Báo cho Thảo" (bật = navy) · "Tự báo khi mình đến nơi" (phụ đề theo trạng thái: "Máy tự báo khi bạn đến Nhà, Công ty, Phòng gym." / chưa có nơi có vị trí: khoá + nút viền [Đặt địa chỉ Nhà] / thiếu Luôn luôn: khoá + [Mở Cài đặt] / tắt từ xa: khoá + "Tạm thời chỉ báo bằng tay…").
3. **"Nơi báo"** (tiêu đề 20 + câu "Nhà luôn có. Thêm tối đa 4 nơi nữa. Địa chỉ chỉ nằm trên máy này."): Nhà đầu tiên, rồi các nơi tự đặt; mỗi hàng = IconBadge navy α .06 + tên 15 w700 + phụ đề 12 (địa chỉ rút gọn / "Lưu bằng vị trí hiện tại · 18/10" / "Chưa đặt địa chỉ, chỉ bấm tay" / "Đang tạm dừng") + chevron → Sửa. Hàng cuối "Thêm nơi / Còn N chỗ" (IconBadge rose `add`), ẩn khi đủ 5.
4. Quyền vị trí (như bản 1) + gợi ý đừng vuốt tắt (iOS).
5. Tắt "Báo cho Thảo" ⇒ hộp "Tắt báo về nhà?" + ô "Xoá luôn địa chỉ đã lưu của 3 nơi trên máy này" (Nhà không mất, chỉ mất địa chỉ) + [Huỷ] [Tắt].

## 7. Push · widget · Cài đặt (`notify.html`)

- Push theo bảng §7 PO: Nhà "Thảo đã về đến nhà" · nơi tự đặt "Thảo đã đến Phòng gym" (tên nguyên văn, CF cắt 24). Body pin ≤ 20% "Pin còn 12%", còn lại "Nhắn một câu hỏi thăm nhé". Tap ⇒ Home tab 0, cuộn tới thẻ.
- Widget-today: `arrival_home` / `arrival_place` (§8 PO), dòng trạng thái có sẵn của widget-today. Widget nhỏ dùng bản rút gọn ("Thảo tới Phòng gym" 18 ký tự vừa); **tên dài hơn khoảng 9 ký tự sẽ bị cắt "…" ở widget nhỏ** — chấp nhận, chạm vẫn mở đúng thẻ.
- Cài đặt → Thông báo: `SwitchListTile.adaptive` "Khi người ấy đến nơi" / "Báo khi Thảo về nhà hoặc đến một nơi đã lưu. Tắt thì thẻ Home vẫn hiện tin." (chỉ khi đã ghép đôi; giữ `activeThumbColor` như các hàng cùng card).
- Cài đặt → Chung: `_navRow` "Về đến nhà" / "Đang báo cho Thảo: Nhà và 2 nơi khác" · "Đang tắt" · "Tạm thời chỉ báo bằng tay", đặt trước "Ảnh nền thẻ đếm".

---

## 8. Copy deck (vi + en)

Xưng "bạn" theo D12; nút là lời người dùng nói nên giữ "Mình…"; nhãn làn = "Bạn" (khớp thẻ Đêm qua). Dấu kiểu mới. Đã soát theo humanizer (bỏ "không chỉ… mà còn", bộ ba gượng, gạch ngang) và avoid-ai-writing cho EN. **Thuật ngữ đời thường:** không dùng "geofence", "bán kính" trên màn — chỉ "trong khoảng 250 m quanh đây"; "sai số" → "lệch khoảng 12 m".

| Key | VI | EN |
|---|---|---|
| `arrivalCardTitle` | Về đến nhà chưa? | Home yet? |
| `arrivalYou` | Bạn | You |
| `arrivalPitch` | Về đến nhà là máy tự báo cho {name}. Đang chạy xe thì khỏi phải nhắn. | When you get home, your phone tells {name}. No texting from the road. |
| `arrivalEnableCta` | Bật báo về nhà | Turn on arrivals |
| `arrivalManualHome` | Về nhà rồi | I'm home |
| `arrivalManualOther` | Đến nơi rồi | I've arrived |
| `arrivalEnterHome` / `arrivalExitHome` | Đã về đến nhà / Đã rời nhà | Got home / Left home |
| `arrivalEnterPlace` / `arrivalExitPlace` | Đã đến {place} / Đã rời {place} | Arrived at {place} / Left {place} |
| `arrivalYesterdayAt` | hôm qua {time} | yesterday {time} |
| `arrivalBattery` / `arrivalBatteryLow` | {pct}% / Pin còn {pct}% | {pct}% / Battery at {pct}% |
| `arrivalManualTag` | bấm tay | manual |
| `arrivalPartnerOn` / `Sub` | Đang bật báo về nhà / Khi {name} đến nơi, tin sẽ hiện ở đây. | Arrivals are on / You'll see it here when {name} arrives. |
| `arrivalPartnerOff` | Chưa bật báo về nhà | Arrivals are off |
| `arrivalCareCta` / `arrivalCareSuggestion` | Hỏi thăm / Về tới nơi rồi thì nghỉ ngơi nhé | Say hi / You made it. Get some rest |
| `arrivalNoEventToday` | Chưa có tin hôm nay | Nothing yet today |
| `arrivalMineAuto` | Tự báo: {places} | Auto: {places} |
| `arrivalPlacesMany` | Nhà và {n} nơi khác | Home and {n} more |
| `arrivalMineNeedAlways` | Chưa tự báo được: cần quyền vị trí Luôn luôn | Can't send on its own yet: needs Always location |
| `arrivalMineRemoteOff` | Tạm thời chỉ báo bằng tay | Manual only for now |
| `arrivalMineNoAddress` / `arrivalSetAddress` | Chưa đặt địa chỉ Nhà / Đặt địa chỉ | Home address not set / Set address |
| `arrivalFirstDetected` | App đã nhận ra {place} | The app recognized {place} |
| `arrivalSent` | Đã báo {name} | Sent to {name} |
| `arrivalQueued` | Sẽ báo khi có mạng. Quá 30 phút thì {name} chỉ thấy trên thẻ, không nhận thông báo. | Sends when you're back online. After 30 minutes, {name} only sees it on the card, with no notification. |
| `arrivalSendFailed` / `arrivalRetry` | Chưa gửi được tin “{what}”. / Thử lại | Couldn't send “{what}”. / Try again |
| `arrivalPickTitle` / `arrivalPickNote` | Bạn vừa đến đâu? / Bấm là {name} nhận “{me} đã đến …” ngay, không cần quyền vị trí. | Where did you just arrive? / Tap and {name} gets “{me} arrived at …” right away. No location access needed. |
| `arrivalAddPlace` / `arrivalSlotsLeft` | Thêm nơi / Còn {n} chỗ | Add a place / {n} left |
| `arrivalBadge` | VỀ ĐẾN NHÀ | ARRIVALS |
| `arrivalNewPlaceTitle` | Nơi mới | New place |
| `arrivalNameLabel` / `arrivalNameHint` | Tên nơi / Vd: Công ty, Nhà bố mẹ | Place name / e.g. Work, Mom and Dad's |
| `arrivalNameNote` | Người ấy sẽ thấy tên này khi bạn đến. | Your partner sees this name when you arrive. |
| `arrivalNameEmpty` | Gõ tên để tiếp tục. Tối đa 24 ký tự. | Type a name to continue. Up to 24 characters. |
| chip gợi ý | Công ty · Trường · Nhà bố mẹ · Phòng gym · Quán quen | Work · School · Mom and Dad's · Gym · Usual spot |
| `arrivalIconLabel` / `arrivalIconAuto` | Biểu tượng / Chọn chip gợi ý thì biểu tượng tự chọn theo, đổi được. | Icon / Picking a suggestion picks its icon too. You can change it. |
| tên 7 biểu tượng (Semantics) | Công việc · Trường · Gia đình · Tập luyện · Quán · Mua sắm · Chỗ khác | Work · School · Family · Workout · Café · Shopping · Other |
| `arrivalPreview` | {name} sẽ thấy: {me} đã đến {place} | {name} will see: {me} arrived at {place} |
| `arrivalContinue` | Tiếp tục | Continue |
| `arrivalWhereTitle` / `arrivalWhereSub` | {place} ở đâu? / Gõ số nhà, tên đường và phường cho chuẩn nhất. | Where is {place}? / Include the house number, street and ward for the best match. |
| `arrivalSearchHint` | Vd: 12 Nguyễn Trãi, Thanh Xuân, Hà Nội | e.g. 12 Nguyen Trai, Thanh Xuan, Ha Noi |
| `arrivalSearching` | Đang tìm… | Searching… |
| `arrivalSearchTip` (Android) | Gõ xong bấm Tìm trên bàn phím nếu chưa thấy kết quả. | Tap Search on the keyboard if nothing shows up. |
| `arrivalUseCurrentRow` / `Sub` | Không thấy địa chỉ? Dùng vị trí hiện tại / Hãy bấm khi bạn đang đứng ở đó | Can't find it? Use current location / Tap this while you're there |
| `arrivalNoResults` | Không tìm thấy địa chỉ này. Thử thêm tên phường hoặc tỉnh, hoặc dùng vị trí hiện tại khi bạn đang ở đó. | Couldn't find that address. Try adding the ward or province, or use your current location while you're there. |
| `arrivalSearchOffline` | Cần mạng để tìm địa chỉ. Có mạng lại thì gõ tiếp, hoặc dùng vị trí hiện tại khi bạn đang ở đó. | Finding an address needs internet. Try again when you're online, or use your current location while you're there. |
| `arrivalNoGeocoder` | Máy này không tìm được địa chỉ. Bạn lưu bằng vị trí hiện tại lúc đang đứng ở đó. | This phone can't look up addresses. Save the place with your current location while you're there. |
| `arrivalUseCurrent` / `arrivalNameOnly` | Dùng vị trí hiện tại / Lưu tên, chỉ bấm tay | Use current location / Save the name, tap manually |
| `arrivalCurrentTitle` / `Body` | Bạn đang ở {place}? / App đọc vị trí một lần để lưu chỗ này. Toạ độ chỉ nằm trên máy bạn. | Are you at {place} now? / The app reads your location once to save this spot. Coordinates stay on your phone. |
| `arrivalCurrentHint` | Lần đầu, máy sẽ hỏi quyền vị trí. Chọn “Cho phép khi dùng ứng dụng” và để Vị trí chính xác bật. | The first time, your phone asks for location access. Choose “While Using the App” and keep Precise Location on. |
| `arrivalReadLocation` / `arrivalReading` / `arrivalBackToSearch` | Đọc vị trí / Đang đọc vị trí… / Quay lại tìm địa chỉ | Read location / Reading location… / Back to search |
| `arrivalPreciseTitle` / `Body` | Cần bật Vị trí chính xác / Với vị trí gần đúng, app không biết bạn đã về tới cửa hay mới ở cách nhà vài con phố. | Turn on Precise Location / With approximate location, the app can't tell your door from a few streets away. |
| `arrivalConfirmTitle` | Đúng chỗ này chưa? | Is this the right spot? |
| `arrivalFromAddress` / `arrivalFromCurrent` | Từ địa chỉ / Vị trí hiện tại của bạn, lệch khoảng {m} m | From the address / Your current location, within about {m} m |
| `arrivalRadiusLine` | App báo khi bạn vào trong khoảng {m} m quanh đây. | The app lets them know when you're within about {m} m of here. |
| `arrivalNoHouseNumber` | Địa chỉ này chưa có số nhà, app có thể báo hơi sớm hoặc hơi muộn. | This address has no house number, so the alert may come a little early or late. |
| `arrivalSave` / `arrivalWrongSpot` / `arrivalReread` | Lưu / Không đúng chỗ? Dùng vị trí hiện tại khi bạn đang ở đó / Đọc lại vị trí | Save / Wrong spot? Use your current location while you're there / Read location again |
| `arrivalSaved` | Đã lưu {place} | {place} saved |
| `arrivalEditTitle` / `arrivalRenameNote` | Sửa {place} / Đổi tên chỉ áp cho lần đến sau. | Edit {place} / A new name applies from your next arrival. |
| `arrivalLocationLabel` / `arrivalSavedFromAddress` / `arrivalSavedFromCurrent` | Vị trí / Lưu từ địa chỉ · {date} / Lưu bằng vị trí hiện tại · {date} | Location / Saved from address · {date} / Saved from current location · {date} |
| `arrivalNoAddressManual` / `arrivalPaused` | Chưa đặt địa chỉ, chỉ bấm tay / Đang tạm dừng | No address yet, manual only / Paused |
| `arrivalDeletePlace` / `Sub` | Xoá nơi này / App hỏi lại trước khi xoá. | Delete this place / You'll be asked to confirm. |
| `arrivalDeletePlaceTitle` / `Body` | Xoá {place}? / App thôi báo khi bạn đến đây. Tin đã gửi trước đó vẫn giữ tên cũ. | Delete {place}? / You'll stop sending arrivals for it. Updates already sent keep the old name. |
| `arrivalHomeEditBody` | Nhà luôn có trên thẻ. Bạn chỉ đổi được chỗ của nó. | Home always stays on the card. You can only change where it is. |
| `arrivalDeleteHomeAddress` / `Title` / `Body` | Xoá địa chỉ / Xoá địa chỉ Nhà? / Nhà vẫn còn trên thẻ, bạn bấm “Về nhà rồi” mỗi lần về. | Remove address / Remove Home's address? / Home stays on the card. Tap “I'm home” each time you get back. |
| `arrivalDelete` / `arrivalCancel` | Xoá / Huỷ | Delete / Cancel |
| `arrivalNeedPlaceTitle` / `Body` | Trước hết, nhà bạn ở đâu? / Máy cần biết Nhà ở đâu thì mới tự báo được. Gõ địa chỉ là xong, chưa cần cấp quyền gì. | First, where's home? / Your phone needs to know where Home is to send on its own. Typing the address is enough, no permissions yet. |
| `arrivalSetHomeAddress` / `arrivalLater` | Đặt địa chỉ Nhà / Để sau | Set Home address / Not now |
| `arrivalDisclosureTitle` / `Body` | Về đến nơi, {name} biết ngay / *(D12 nguyên văn)* | {name} knows when you arrive / *(D12 verbatim)* |
| `arrivalPreviewLabel` / `arrivalAgree` / `arrivalPrivacyLink` | {name} sẽ nhận được / Đồng ý, tiếp tục / Chính sách bảo mật | {name} will get / Agree and continue / Privacy policy |
| `arrivalAlwaysTitle` / `Body` | Chọn “{label}” / *(D12 màn 2)* | Choose “{label}” / *(D12 screen 2)* |
| `arrivalNextLooksLike` | Trang tiếp theo trông như thế này | The next screen looks like this |
| `arrivalSwipeHint` / `arrivalAutostartHint` | Đừng vuốt tắt Dear Embeiu trong đa nhiệm. App bị vuốt tắt thì iPhone có thể không báo được. / Máy Xiaomi, Oppo, Vivo: bật thêm Tự khởi động cho Dear Embeiu để tin báo không bị chặn. | Don't swipe Dear Embeiu away in the app switcher, or your iPhone may not send arrivals. / On Xiaomi, Oppo or Vivo, also turn on Autostart for Dear Embeiu so arrivals aren't blocked. |
| `arrivalOpenPermission` / `arrivalLaterManual` | Mở trang quyền / Để sau, mình bấm tay | Open permissions / Later, I'll tap manually |
| `arrivalDoneTitle` / `Body` | Đã bật báo về nhà / Từ giờ về đến Nhà là {name} biết. Muốn tắt thì vào Cài đặt → Về đến nhà. Tắt là tin gần nhất bị xoá, {name} không nhận thông báo nào. | Arrivals are on / From now on, {name} knows when you get home. To turn it off, go to Settings → Arrivals. Turning it off deletes your latest update, and {name} gets no notification. |
| `arrivalDoneRow` / `Sub` | Tự báo khi đến Nhà / Thêm Công ty, phòng gym… để báo cả những chỗ đó | Sends when you reach Home / Add work, the gym… to cover those too |
| `arrivalPartialTitle` / `Body` | Tạm thời bạn báo bằng tay / Mỗi lần về, bấm “Về nhà rồi” trên thẻ Home. {name} nhận tin y như lúc máy tự báo. Các nơi đã lưu vẫn giữ nguyên. | You'll send it manually for now / Each time you get home, tap “I'm home” on the Home card. {name} gets the same message. Your saved places stay. |
| `arrivalBackHome` | Về trang chủ | Back to Home |
| `arrivalSeesLabel` | {name} đang thấy | What {name} sees |
| `arrivalShareTitle` / `Sub` / `OffSub` | Báo cho {name} / Tắt là xoá tin gần nhất trên máy chủ. {name} không nhận thông báo nào. / Bật lại để báo cho {name} mỗi khi bạn đến nơi. | Share with {name} / Turning this off deletes your latest update from the server. {name} gets no notification. / Turn it back on to let {name} know when you arrive. |
| `arrivalAutoTitle` / `arrivalAutoSub` | Tự báo khi mình đến nơi / Máy tự báo khi bạn đến {places}. | Send automatically / Your phone sends it when you reach {places}. |
| `arrivalAutoNeedPlace` | Đặt địa chỉ Nhà hoặc một nơi khác trước, rồi bật. | Set an address for Home or another place first. |
| `arrivalAutoNeedAlways` / `arrivalAutoRemoteOff` | Chưa tự báo được: cần quyền vị trí Luôn luôn. / Tạm thời chỉ báo bằng tay. Bạn vẫn bấm “Về nhà rồi” trên thẻ Home. | Can't send on its own yet: needs Always location. / Manual only for now. You can still tap “I'm home” on the Home card. |
| `arrivalPlacesTitle` / `Sub` | Nơi báo / Nhà luôn có. Thêm tối đa 4 nơi nữa. Địa chỉ chỉ nằm trên máy này. | Places / Home is always there. Add up to 4 more. Addresses stay on this phone. |
| quyền (giữ bản 1) | Vị trí: Luôn luôn · Vị trí: Khi dùng ứng dụng · Vị trí chính xác: Bật · Mở Cài đặt của máy | Location: Always · Location: While Using · Precise Location: On · Open phone Settings |
| `arrivalTurnOffTitle` / `Body` | Tắt báo về nhà? / Tin gần nhất của bạn bị xoá khỏi máy chủ ngay. {name} sẽ thấy “{me} chưa bật báo về nhà” và không nhận thông báo nào. | Turn off arrivals? / Your latest update is deleted from the server right away. {name} will see your arrivals are off and won't get a notification. |
| `arrivalTurnOffAlsoPlaces` | Xoá luôn địa chỉ đã lưu của {n} nơi trên máy này | Also delete the saved addresses of {n} places on this phone |
| `arrivalTurnOff` | Tắt | Turn off |
| `settingsArrivalPushTitle` / `Sub` | Khi người ấy đến nơi / Báo khi {name} về nhà hoặc đến một nơi đã lưu. Tắt thì thẻ Home vẫn hiện tin. | When your partner arrives / Get notified when {name} gets home or reaches a saved place. The Home card still shows it when this is off. |
| `settingsArrivalTitle` / sub | Về đến nhà / Đang báo cho {name}: {places} · Đang tắt · Tạm thời chỉ báo bằng tay | Arrivals / Sharing with {name}: {places} · Off · Manual only for now |
| Push + widget | y bảng §7, §8 PO | y bảng PO |

`{places}`: 1–2 nơi ghép bằng " · " (mỗi tên `nowrap`), ≥ 3 → `arrivalPlacesMany`. `{place}` là tên người dùng gõ, giữ nguyên chữ hoa/thường.

---

## 9. Soát dễ dùng (UI UX Pro Max) — thước đo chính theo user 2026-10-20

**Truy vấn đã chạy** (`search.py`, không `-I`):

| Truy vấn | Kết quả | Quy tắc rút ra |
|---|---|---|
| `"search autocomplete suggestions" --domain ux` | *Autocomplete*: gợi ý khi gõ, đừng bắt gõ đủ rồi Enter · *No Results*: báo không thấy kèm gợi ý, đừng màn trống | iPhone gợi ý ngay; Android "Đang tìm…" + nút Tìm; không thấy ⇒ câu gợi ý thêm phường/tỉnh + một nút làm tiếp |
| `"no results search" --domain ux` | *No Results*, *Autocomplete* (như trên) | dòng "Dùng vị trí hiện tại" luôn ở cuối danh sách, không chỉ khi rỗng |
| `"form input validation inline" --domain ux` | *Inline Validation* (báo khi rời ô, không đợi bấm gửi) · *Input Labels* (nhãn trên ô, không dùng placeholder làm nhãn) · *Input Types* | nhãn "Tên nơi" trên ô; bộ đếm 9/24 sống; nút Tiếp tục khoá + câu lý do ngay dưới; ô tìm dùng `TextInputAction.search` |
| `"smart defaults reduce input" --domain ux` | *Input Affordance* (ô trông như ô nhập) + 2 mục trên | ô trắng viền focus rõ trên blush; chip điền sẵn tên **và** biểu tượng |
| `"onboarding permission" --domain ux` | *User Freedom*: luôn có Bỏ qua và Quay lại | mọi khung xin quyền có "Để sau" / "Để sau, mình bấm tay"; ← trên mọi màn con |
| `"list item actions" --domain ux` | *Confirmation Messages*, *Success Feedback*, *Confirmation Dialogs* | SnackBar "Đã lưu …"; "✓ Đã báo Thảo"; hỏi lại trước mọi lần xoá |
| `"plain language error message" --domain ux` | *Error Messages* (đọc được bằng trình đọc màn hình), *Error Placement* (lỗi ngay dưới ô) | mất mạng/không thấy nằm ngay dưới ô tìm, `role=alert` |
| `"keyboard covers input" --domain ux` | *Mobile Keyboards* (đúng loại bàn phím) | nút chính đi lên theo bàn phím (`viewInsets`), không bị che |
| `"touch target spacing buttons" --domain ux` (bản 1) | 44 pt / 48 dp, cách ≥ 8 | mọi nút/hàng ≥ 44, Android padded 48; gap 8 |
| `"search input"`, `"text field"` `--stack flutter` | `TextEditingController`, dispose controller, const | Dev: controller cho ô tên/ô tìm, debounce bằng Timer, dispose |
| `"list view"`, `"bottom sheet"` `--stack flutter`, `"thumb zone bottom action"`, `"undo delete"`, `"progressive disclosure"`, `"character limit counter"` `--domain ux` | không có mục khớp | dùng `references/quick-reference.md`: `undo-support`, `destructive-emphasis`, `destructive-nav-separation`, `empty-states`, `confirmation-dialogs`, `search-accessible` (gợi ý sẵn) |

**Soát từng màn theo 8 câu của user:**

| Câu hỏi | Kết quả | Đã sửa trên mock |
|---|---|---|
| Việc chính xong trong 1–2 chạm? | Báo về nhà: **1 chạm**. Báo nơi khác: 2 chạm (Đến nơi rồi → chọn). Hỏi thăm: 1 chạm. Thêm nơi bằng gợi ý: chip → Tiếp tục → chạm kết quả → Lưu = 4 chạm + gõ địa chỉ. | Chip tự chọn biểu tượng (trước: phải chạm thêm hàng biểu tượng). |
| Nút chính ở nửa dưới, vùng chạm ≥ 44–48? | Bản đầu nút đi theo nội dung, nằm giữa màn. | **Neo đáy** mọi màn con (khung cao một màn trong mock), đi lên theo bàn phím; thẻ Home: hai nút ở đáy thẻ. |
| Mỗi màn một mục tiêu? | Tên / địa chỉ / xác nhận / quyền tách màn. Sửa nơi có Lưu + Xoá. | Xoá tách thành card riêng, không đứng sát nút Lưu. |
| Số bước, số ô ít nhất? | 1 ô tên + 1 ô tìm. Bỏ bước tên cho Nhà. Không hỏi quyền khi tìm được địa chỉ. "Thảo đang thấy" thay vì giải thích. | Gợi ý tên + biểu tượng; dòng "Dùng vị trí hiện tại" luôn ở cuối danh sách. |
| Rỗng / lỗi nói một việc làm tiếp? | Không thấy / mất mạng / máy không tìm được: mỗi cái một câu + một nút chính "Dùng vị trí hiện tại". Thẻ: thiếu quyền → "Mở Cài đặt"; chưa có địa chỉ → "Đặt địa chỉ". | — |
| Hỏi lại trước khi xoá / mất dữ liệu? | Xoá nơi, xoá địa chỉ Nhà, tắt chia sẻ đều có hộp hỏi lại nêu hậu quả. | Thêm hộp cho "Xoá địa chỉ Nhà". |
| Thuật ngữ khó? | Bản đầu có "Bán kính 250 m", "sai số". | Đổi: "Lưu từ địa chỉ · 13/10", "lệch khoảng 12 m"; chỉ còn "trong khoảng 250 m quanh đây" (câu PO). Không "geofence". |
| Nhất quán với app? | `SubScreenHeader`, `ContentCard`, `IconBadge`, ô input theme, nút pill navy h52/h44, sheet r28, `PersonLabel` y như app. | Thẻ đổi sang Bạn trái · Thảo phải như thẻ Đêm qua. |

**Đánh đổi còn lại:** Android không gợi ý theo từng chữ (D20) — bù bằng "Đang tìm…" + nút Tìm. Widget nhỏ cắt tên dài. Thêm nơi vẫn là 3 màn (tên → địa chỉ → xác nhận): gộp tên và địa chỉ vào một màn thì bàn phím che danh sách kết quả, nên giữ tách. Không có hoàn tác sau khi xoá (đã có hộp hỏi lại; xoá chỉ mất địa chỉ trên máy, đặt lại được).

## 10. Thiết bị của brand giữ lại + `--allow`

| Thiết bị | Rule | Lý do |
|---|---|---|
| Nền `dawnBlush` | `gradient` (lint: `taste-skill-ignore`) | nền bắt buộc của mọi màn; user "follow theo system design hiện tại" |
| Nền "Trời đêm" navy của widget | `--allow gradient` (notify) | user "Giữ navy làm ngoại lệ" |
| `IconBadge` | `--allow icon-chips` | mọi thẻ Home và hàng Cài đặt đều dùng |
| `PersonLabel`, `EyebrowChip` | `--allow micro-label` | primitive có sẵn |
| Bóng `ContentCard` | `--allow heavy-shadow` | bóng chuẩn duy nhất của card trắng |
| Chip widget 10 px | `--allow tiny-text` (notify) | widget đã phát hành |

WARN để lại có lời bào chữa: `colour-sprawl` (16–50%) — nền dawnBlush + nút navy h52 kín bề ngang; `blank-gap` (setup, place) — khoảng giữa nội dung và nút neo đáy trong khung cao một màn, chính là vùng ngón cái được chừa có chủ đích; `contrast`/`font-count` (setup, notify) — hộp thoại/thông báo **của hệ điều hành**; `radius-mix` (manage) — thang 24/16/28 của app; `tiny-text` WARN ở manage — phụ đề 12 px của hàng Cài đặt có sẵn.

## 11. Token

- Màu: `textPrimary #1A1A2E` · `textSecondary #6B6B7B` (chỉ trên trắng/tint) · `textTertiary` (chỉ chevron) · `accentLove` · `accentLoveDeep` · `surfaceLight #F5F0F5` · `warning` α .18 · `error` (chỉ icon) · màu người α .10 (Thảo teal → #E7F4F3, Tuấn rose → #FFEDF0). Chữ phụ trên blush = navy α .78 (≥ 5,25:1).
- **Đề xuất bổ sung design system:** `AppColors.warningInk = #8A4B00` (6,0:1 trên `warning` α .18) cho pin yếu và hộp "chưa có số nhà".
- Chữ (type scale): 11 nhãn người/chip · 12 phụ đề/dòng trạng thái/pill pin · 13 meta/nhãn ô · 14 giờ/nút chữ · 15 nút/tên hàng/thân · 16 tiêu đề thẻ/ô nhập/địa chỉ · 18 câu của làn · 20 tiêu đề nhóm/sheet · 26 tiêu đề màn con.
- Bo góc: card 24 · làn/hộp/nút biểu tượng 16 · ô nhập 20 · sheet/dialog 28 · nút + chip 999.
- Khoảng cách: gutter 16 · card pad 16 (thẻ), 20 (card khác) · hai làn gap 8 · làn → nút 12 · giữa nút 8 · nhãn → ô 8 · nhóm → nhóm 24.
- Cao: nút trong thẻ 44 · nút màn con 52 · ô nhập 52 · hàng kết quả ≥ 56 · nút biểu tượng 44 · chip 36 (vùng chạm 44 bằng padding).

## 12. A11y

- Làn: `MergeSemantics` đọc "Thảo đã đến Phòng gym lúc 17:50, pin 22%[, bấm tay]". "Hỏi thăm" đọc "Hỏi thăm Thảo". Dòng trạng thái của bạn: button "…, mở cài đặt Về đến nhà". "Đến nơi rồi": `aria-haspopup` → sheet có tiêu đề.
- Ô tên: nhãn + bộ đếm + dòng nhắc là `helperText` (đọc cùng ô). Hàng biểu tượng: radio group có tên từng biểu tượng. Danh sách kết quả: mỗi dòng một button đọc cả 2 dòng địa chỉ; "Đang tìm…" + kết quả mới báo bằng `liveRegion`. Xem trước "Thảo sẽ thấy…" là live region.
- Live/alert: "✓ Đã báo Thảo", "Sẽ báo khi có mạng", lỗi gửi, không thấy địa chỉ, mất mạng.
- Vùng chạm ≥ 44 (Android 48 padded), gap ≥ 8. Chữ to: câu làn tối đa 3 dòng; ≥ 1.3× thì hai làn xếp dọc (LayoutBuilder: mỗi làn < 150 dp chữ thì stack), hàng nút `Wrap`.
- Không dựa màu: pin yếu có chữ; nơi có cả biểu tượng lẫn tên. Tương phản đã tính ở §11.

## 13. Motion

`EntranceReveal` cho thẻ; tin mới của Thảo `AnimatedSwitcher` 280 ms fade + 8 px (Reduce Motion: fade 200 ms); bấm tay haptic `lightImpact` + đổi icon 200 ms; dải offline `AnimatedSize` 240 ms; kết quả tìm xuất hiện fade 200 ms (không trượt); sheet "Đến nơi rồi" chuẩn Material; chấm bước 240 ms; cuộn tới thẻ khi tap push 280 ms (Reduce Motion: jump). Không hiệu ứng lặp.

## 14. Kiểm tra: lint, inspect, vòng nhìn lại

Lệnh (gốc worktree): `node ~/.claude/skills/design-taste-frontend/scripts/lint.mjs --app docs/design/arrival` · `node …/inspect.mjs --app docs/design/arrival/<màn>.html --widths 390 --out .taste-skill/arrival/<màn> --allow micro-label,heavy-shadow,icon-chips` (notify thêm `gradient,tiny-text`). Chỉ 390 vì app chỉ có điện thoại.

| File | Kết quả cuối |
|---|---|
| lint cả thư mục | 0 FAIL · 0 WARN |
| `home-card.html` | 0 FAIL · 1 WARN (colour-sprawl) |
| `place.html` | 0 FAIL · 2 WARN (blank-gap, colour-sprawl) |
| `setup.html` | 0 FAIL · 4 WARN (blank-gap, contrast + font-count do hộp hệ thống, colour-sprawl) |
| `manage.html` | 0 FAIL · 2 WARN (colour-sprawl, tiny-text) |
| `notify.html` | 0 FAIL · 2 WARN (font-count, colour-sprawl) |

**Bản 1 (3 vòng, 2026-10-20 sáng):** giữ nhãn/bề rộng nút khi vừa gửi · bỏ lặp tên trong làn · dòng trạng thái của mình rõ là chỗ bấm · skeleton thấy được · tiêu đề bước không lặp câu D12 · tiêu đề trước xem trước push · chữ phụ trên blush → navy .78.

**Bản 2 — vòng 1:**
1. Thẻ — nút "Về nhà rồi" ở trạng thái vừa gửi/mất mạng gần như biến mất (nền navy α .06 + chữ trắng). ⇒ giữ nền navy, chỉ đổi icon.
2. Thẻ — tên 24 ký tự bị cắt "Đã đến Nhà ngoại ở Than…". ⇒ câu tối đa 3 dòng.
3. Thẻ — "Tự báo: Nhà · Công ty · Phòng gym" vỡ thành 3 dòng, "Công / ty" tách đôi. ⇒ từ 3 nơi ghi "Nhà và 2 nơi khác"; tên nơi `nowrap`.
   place — link "Không đúng chỗ?…" sát mép 10 px (FAIL edge-text) ⇒ nút chữ cho xuống dòng, canh giữa.
**Bản 2 — vòng 2 (cùng lúc soát dễ dùng):**
1. place/setup — nút chính nằm giữa màn ⇒ neo đáy.
2. Sửa nơi — "Xoá nơi này" sát nút Lưu ⇒ card riêng; Sửa Nhà bỏ nút "Đổi địa chỉ" trùng với hàng Vị trí.
3. place — ghi chú thiết kế ("Từ chối quyền thì…") lọt vào UI ⇒ chuyển thành chú thích của khung; con trỏ ô trống nằm sau placeholder ⇒ đặt trước.

**Bảy câu §2.7 (vòng cuối):** (1) câu to nhất của mỗi làn trả lời "đến đâu", đọc ngay sau nhãn tên; màn con: tiêu đề 26 là câu hỏi của màn. (2) chung mép gutter 16, hai làn cao bằng nhau, nút Hỏi thăm/dòng trạng thái neo đáy làn nên không có khoảng trống giữa làn. (3) màu người chỉ ở chấm + tint làn, vàng đất chỉ ở pin yếu và cảnh báo số nhà, một nút đặc mỗi màn/thẻ. (4) số khớp qua `data.js` (18:42/12% = push = widget; 17:50/22% gym; 08:05/64% "Thảo đang thấy"; 3 push ≤ 6). (5) không pin thì không in phần pin; không tin thì câu trạng thái. (6) không biểu đồ, không nhãn chồng. (7) chỉ khổ điện thoại, nav Home không đổi.

**Còn yếu:** thẻ cao ~300 dp; widget nhỏ cắt tên dài; địa chỉ mẫu chưa kiểm bằng geocoder thật; widget có ảnh dùng ảnh mẫu brand-v2.

## 15. Dev notes

- **Push opt-out bị ép bật toàn app** (`NotificationSettingsService.currentOrDefault()` luôn true từ 2026-06-14) ⇒ `pushArrival` phải đọc giá trị thật, nếu không công tắc "Khi người ấy đến nơi" là giả.
- Bấm tay khi chưa bật = một lần ghi `share:true, auto:false` + `last`.
- `last.name`/`icon` chụp lúc gửi (D23); thẻ hiện `last.name` nguyên văn, không tra danh sách nơi.
- Tách `PersonLabel` ra `lib/widgets/person_label.dart`. Màu người qua `PersonPalette.resolve` (chưa bật sleep = mặc định như sleep, Lead chốt).
- `openCareMessageScreen(BuildContext)` (`lib/screens/care_message_screen.dart:25`) chỉ nhận `context` ⇒ thêm tham số tuỳ chọn để đặt sẵn gợi ý.
- Nút chính màn con: `Scaffold.bottomNavigationBar` = `SafeArea` + `Padding(16)` + nút 52; `resizeToAvoidBottomInset` để nút lên theo bàn phím.
- Tìm địa chỉ: `TextEditingController` + `Timer` debounce (iOS 300 ms / Android 800 ms), huỷ request cũ khi gõ tiếp; giới hạn khung Việt Nam (D20). Chip gợi ý → map tên → biểu tượng ở §4.1.
- Xác nhận: phát hiện "chưa có số nhà" khi kết quả không có `subThoroughfare` (iOS `MKPlacemark`) / `featureName`/`subThoroughfare` rỗng (Android `Address`) — Dev xác nhận khi spike.
- Hàng "Thêm nơi" và chip "+ Thêm nơi" trong sheet ẩn khi đủ 5 nơi.
- Thời gian: hôm nay `HH:mm`; hôm qua `arrivalYesterdayAt`; 2–3 ngày `d/M HH:mm`; > 3 ngày → "Đang bật"; `MidnightBuilder` đổi lúc 0:00.

## 16. Acceptance (design)

- [x] Mọi trạng thái có hình (thẻ 17 + sheet, place 16, setup 7, manage 6, notify 6) và mô tả.
- [x] Copy vi + en đủ (§8), copy chốt PO giữ nguyên.
- [x] Map widget có sẵn / mới (§3.2, §4, §5, §6, §7).
- [x] Lint 0 FAIL, inspect 390 0 FAIL cả 5 trang, WARN có lời bào chữa, rule allow có lý do.
- [x] Tra UI UX Pro Max làm thước đo dễ dùng (§9).

## 17. Câu hỏi cho PO / user

- **Q1:** Từ 3 nơi trở lên, dòng trạng thái của làn Bạn ghi "Nhà và 2 nơi khác" (spec §8 nói "quá 3 nơi"). Lý do: làn chỉ rộng nửa thẻ, 3 tên xuống 3 dòng. Màn Quản lý vẫn liệt kê đủ. Đồng ý chứ?
- **Q2:** Gợi ý tên bản EN "Mom and Dad's", "Usual spot" — PO duyệt chữ, hoặc cho chữ khác?
- **Q3:** Xoá nơi chỉ có hộp hỏi lại, không có "Hoàn tác". Có cần thêm SnackBar hoàn tác 5 giây không (rẻ, vì địa chỉ còn trên máy)?

## Nhật ký design
- [2026-10-20] [Designer] Bản 1: tasteskill trọn run (sheet chung đợt 2), face "cặp đôi là các làn", thẻ Home 14 trạng thái, setup 3 bước, quản lý, push/widget/Cài đặt; lint 0/0, inspect 0 FAIL; 4 câu hỏi (Lead đã chốt).
- [2026-10-20] [Designer] Theo Lead: nút "Về nhà rồi" trên thẻ Home đổi sang viền (luồng thiết lập/Quản lý giữ nút đặc); dòng "Tự báo…" giữ nguyên (D11).
- [2026-10-20] [Designer] Bản 2 theo spec PO sửa (D1, D2, D7, D8, D19–D23) + Lead (Bạn trái · người ấy phải, thẻ đứng riêng): thẻ hai làn tint màu người, nút chính "Về nhà rồi" + "Đến nơi rồi" mở sheet chọn nơi; màn mới `place.html` (tên + 7 biểu tượng + chip gợi ý tự chọn biểu tượng, tìm địa chỉ iPhone/Android, không thấy, mất mạng, máy không tìm được, dùng vị trí hiện tại, 3 kiểu xác nhận, sửa nơi/Nhà, hỏi lại khi xoá); setup chỉ còn bước bật tự báo (+ khung "Trước hết, nhà bạn ở đâu?"); quản lý có danh sách nơi + Thêm nơi; push/widget cho nơi tự đặt. Dữ liệu mẫu: Nhà + Công ty + Phòng gym, địa chỉ kiểu 34 tỉnh, 18 assert. Soát dễ dùng theo UI UX Pro Max (13 truy vấn, 8 câu của user): neo nút chính đáy màn, tách nút xoá, bỏ chữ "bán kính/sai số". Lint 0/0; inspect 390 0 FAIL cả 5 trang. 3 câu hỏi.
