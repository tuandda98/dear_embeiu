# 🎨 Design — Widget "Hôm nay" (dòng trạng thái "người ấy vừa…")

> Designer sở hữu. Đọc [`overview.md`](overview.md) trước (D1–D12 đã chốt). Xây trên widget 1.9.1: token, nền M2/P3, chip, số ngày lấy nguyên từ [`../home-widget/design.md`](../home-widget/design.md). CHỈ thiết kế, không code.

- **Trạng thái design:** xong, chờ PO duyệt (2 câu hỏi cuối file)
- **Người/role:** Designer
- **Mockup bấm thử:** [`docs/design/widget-today-mockup.html`](../../../docs/design/widget-today-mockup.html). Mở thẳng file bằng trình duyệt, không cần mạng. Có đủ 4 bố cục và các nút đổi cỡ, nền, ngôn ngữ, tên ngắn/dài, 9 loại trạng thái, phiên (có couple / chờ người ấy / trống), tinted/Clear, cỡ chữ, thu phóng 1×/2×. Bảng dưới mockup ghi cỡ chữ thực dùng và dòng nào bị cắt "…". Gửi đúng cảnh bằng query, vd `widget-today-mockup.html?bg=photoBright&kind=mood&name=long&tint=tinted` (khoá: size, bg, lang, name, session, kind, mood, tint, ax, copy, zoom).

## 1. Mục tiêu thiết kế

Liếc màn hình chính 1 giây là thấy hai thứ, theo đúng thứ tự: **1.247 ngày** rồi tới **"Thảo đã trả lời, đến lượt mình"**. Dòng trạng thái phải nổi hơn mọi chữ phụ khác (chú thích, cột mốc, "Bắt đầu từ…") nhưng không được tranh với số ngày.

Không có gì mới thì widget phải y hệt 1.9.1, từng pixel. Người chưa bao giờ nhận trạng thái sẽ không thấy gì thay đổi.

## 2. Phạm vi

| Bố cục | Khung | Vùng nội dung | Dòng trạng thái nằm ở | Số dòng |
|---|---|---|---|---|
| iOS nhỏ | 158×158pt | 126×126 (lề hệ thống 16, iOS 17+) · 130×130 (iOS 15–16, lề 14) | dưới chú thích "ngày bên nhau" | 1 |
| iOS vừa | 338×158pt | cột trái 150 · vạch 1 + lề 2×14 · cột phải 127 | đáy cột phải, **thay chỗ** "Bắt đầu từ…" | ≤2 |
| Android 2×2 | ≈152×152dp | 120×120 (padding 16) | dưới chú thích | 1 |
| Android 4×2 | ≈328×152dp | 2 cột weight 1 ≈133dp mỗi cột | đáy cột phải, thay chỗ "Bắt đầu từ…" | ≤2 |

× 2 nền: **M2 trời đêm** (mặc định, chưa có ảnh) và **P3 ảnh + scrim** (có ảnh thẻ đếm). Không đụng bố cục trống (`widget_day_empty.xml` / `EmptyState`).

Ngoài phạm vi thiết kế: icon riêng cho từng loại trạng thái (lý do ở §6.4), animation, vùng chạm riêng (D7 giữ một vùng).

## 3. Soát UX (UI UX Pro Max)

Skill bản 2.13.0, `scripts/search.py` (không `-I`), chạy 2026-10-19. Soát chung 5 thành phần đứng cạnh nhau: chip tên · số ngày · chú thích · cột mốc · dòng trạng thái.

| Truy vấn | Kết quả khớp | Áp dụng |
|---|---|---|
| `"text over image contrast scrim" --domain ux` · `"image text overlay readability" --domain ux` | *Color Contrast* (High): chữ thường tối thiểu 4,5:1 · *Contrast Readability* | Dòng trạng thái trắng 100% + bóng tối `.30`, không dùng màu hồng cho chữ trên nền ảnh (blush trên ảnh sáng chỉ ≈1,9:1). Số đo §5.4. |
| `"small text contrast dark background" --domain color` | bảng "Digital Signage" / "Photography": nền tối + chữ trắng, accent tách riêng | Nền trời đêm giữ chữ trắng; accent blush chỉ dùng cho chấm nhỏ, không cho chữ. |
| `"dark mode contrast" --domain ux` | *Color Contrast*, *Contrast Readability* (cùng kết quả trên) | Kiểm lại trên M2: trắng trên `#241F45` ≈ 15:1. |
| `"truncation ellipsis line clamp" --domain ux` | *Truncation* (Medium): cắt bằng "…" và có cách xem đủ · *Compact Label Overflow* (High): giữ nhãn ngắn trên một dòng, nói rõ khi bị cắt | Bản nhỏ 1 dòng cắt "…" ở cuối; bản vừa 2 dòng. Chữ đầy đủ vẫn tới được người dùng qua VoiceOver/TalkBack (đọc cả câu) và chạm mở đúng thẻ (D7). |
| `"badge chip label wraps" --domain ux` | *Compact Label Overflow*: "use nowrap with a shrinkable label" | Bản nhỏ cho co 12 → 10 trước khi cắt; chip tên giữ nguyên luật 1.9.1 (1 dòng). |
| `"visual hierarchy primary secondary" --domain ux` · `"glanceable status notification line" --domain ux` | không có mục khớp (ra Hover, Breadcrumbs, Line Height) | Không có dữ liệu xác minh → phân cấp chốt theo type scale sẵn có (*Font Size Scale*: dùng thang cố định) + nguyên tắc nền tảng: số 40 > trạng thái 12–14 Bold trắng 100% > chú thích 12 SemiBold .92 > chip 10. |
| `"font size scale hierarchy" --domain typography` | *Font Size Scale*: "Use consistent modular scale, don't random font sizes" | Chỉ dùng 10/11/12/14 trong bộ của home-widget. Co chữ dừng ở 10 (cỡ chip), không xuống 9. |
| `"dynamic type" --stack swiftui` | "Respect text size preferences — scalable fonts and layouts" | Dòng trạng thái vẫn lớn theo Dynamic Type, nhưng chặn ở `xxxLarge` để không đè số ngày (§7.2). |
| `"monochrome tinted icon mode" --domain ux` | **0 kết quả**, thử lại `"emoji as icon" --domain ux` cũng 0 | Không có dữ liệu → theo Apple WidgetKit (`widgetAccentable`, rendering mode `.accented`) và số đo tinted đã có ở home-widget. Ghi rõ là fallback. |
| quick-reference `no-emoji-icons` · `"decorative icon aria hidden" --domain icons` | *no-emoji-icons*: dùng icon vector, không emoji · *icon-context-accessibility*: icon trang trí cạnh chữ thì ẩn khỏi trình đọc màn hình | Không emoji; chấm trạng thái là hình vector (iOS SF Symbol, Android shape), ẩn khỏi VoiceOver/TalkBack. |
| `"color only information" --domain ux` | *Color Only* (High): không truyền thông tin chỉ bằng màu | Chấm màu chỉ để trang trí, thông tin nằm hết trong chữ. |
| `"live badge count screen reader" --domain ux` | *Contextual Live Badge Updates*: một câu trạng thái trọn nghĩa, không đọc con số trơ | Trình đọc màn hình đọc nguyên `statusText` ("Thảo đã trả lời, đến lượt mình"), không đọc "chấm tròn". |

Kết luận soát chung: chip (10) và chú thích (12 SemiBold .92) giữ nguyên. Dòng trạng thái tách khỏi chú thích bằng 3 tín hiệu cùng lúc (đậm hơn, trắng đặc hơn, có chấm đầu dòng) nên không bị đọc liền thành "ngày bên nhau Thảo đã trả lời". Cột mốc bản vừa (12 Bold) đứng dưới trạng thái (14 Bold) về độ nổi.

## 4. Wireframe

Ký hiệu: `●` chấm trạng thái · `✦` sao / chòm sao trái tim (chỉ M2) · `░` scrim ảnh (chỉ P3).

### 4.1 iOS nhỏ 158×158pt

```
M2 TRỜI ĐÊM                              P3 ẢNH
┌──────────────────────────┐            ┌──────────────────────────┐
│ (TUẤN ♥ THẢO)     ✦──✦   │ y16 chip20 │ [TUẤN ♥ THẢO]  ░░░░░░░░░ │ chip trắng .84, mực navy
│               ✦  ✦  ✦    │ chòm sao   │ ░░░ ảnh center-crop ░░░░ │
│      ✦          ✦        │ 52×48      │ ░░░░░░ scrim .18→.60 ░░░ │
│ 1.247                    │ 40 Bold    │ 1.247                    │
│ ngày bên nhau            │ 12 Semi .92│ ngày bên nhau            │ (1 dòng khi có trạng thái)
│ ● Thảo đã trả lời, đến…  │ 12→10 Bold │ ● Thảo đã trả lời, đến…  │ chấm blush (M2) / trắng (P3)
└──────────────────────────┘ y142       └──────────────────────────┘
```

Có trạng thái thì số + chú thích dịch lên 21pt (6 khoảng cách + 15 dòng). Không có trạng thái: không có dòng cuối, số nằm đúng chỗ cũ.

### 4.2 iOS vừa 338×158pt

```
M2 TRỜI ĐÊM
┌───────────────────┬──────────────────────────────┐
│ (TUẤN ♥ THẢO)     │ Cột mốc 1.500       ✦──✦     │ 12 Bold, chừa phải 48 (giữ như 1.9.1)
│                   │ ngày             ✦  ✦  ✦     │
│                   │ ━━━━━━━━━━━━━━━━━░░░░        │ thanh 6, đầy lavender
│ 1.247             │ còn 253 ngày                 │ 12 Semi .92
│ ngày bên nhau     │ ● Thảo hôm nay:              │ 14→12 Bold, ≤2 dòng
│                   │   căng thẳng                 │ (chỗ của "Bắt đầu từ…")
└───────────────────┴──────────────────────────────┘
 cột trái 150 KHÔNG đổi       cột phải 127

P3 ẢNH — y hệt trên, trừ: chip trắng .84 mực navy, không sao/chòm sao, thanh tiến độ trắng,
cột mốc không chừa 48, chấm trạng thái trắng.
```

### 4.3 Android 2×2 ≈152dp

```
┌──────────────────────────┐
│ (TUẤN ♥ THẢO)     ✦──✦   │ padding 16, chip 20, mỗi tên maxWidth 48dp
│               ✦  ✦  ✦    │
│ 1.247                    │ TextView 46dp, autosize 24–40sp, Roboto bold
│ ngày bên nhau            │ 12sp medium, maxLines 1 khi có trạng thái (2 khi không)
│ ● Thảo đã trả lời, đến…  │ 16dp, autosize 10–12sp, bold, maxLines 1
└──────────────────────────┘
 P3: như iOS nhỏ P3.
```

### 4.4 Android 4×2 ≈328dp

```
┌────────────────────┬────────────────────────────┐
│ (TUẤN ♥ THẢO)      │ Cột mốc 1.500     ✦──✦     │ paddingEnd 48dp (M2) / 0 (P3), như 1.9.1
│                    │ ngày                       │
│                    │ ━━━━━━━━━━━━━━━━░░░        │
│ 1.247              │ còn 253 ngày               │
│ ngày bên nhau      │ ● Thảo hôm nay:            │ 14sp bold, maxLines 2 (1 khi chữ ≥130%)
│                    │   căng thẳng               │ thay widget_since
└────────────────────┴────────────────────────────┘
```

## 5. Spec chi tiết

### 5.1 Token (tái dùng, không thêm token mới)

| Phần tử | Token / giá trị | Nguồn |
|---|---|---|
| Chữ trạng thái | trắng `#FFFFFF` 100% | như số ngày |
| Bóng chữ trạng thái | iOS `inkShadow()` mặc định = black .30 radius 4 y1 · Android `shadowColor #4D000000`, `shadowDy 1`, `shadowRadius 8` | y hệt `widget_days` / `DayNumber` |
| Chấm trên M2 | blush `#FF8FA3` | tim chip trên nền đêm (`blush` trong `DayCounterView.swift`, `widget_heart_light`) |
| Chấm trên P3 | trắng `#FFFFFF` | trùng màu chữ |
| Chấm khi tinted/Clear | màu tint của hệ thống (accentable) | |
| Font iOS | `Quicksand-Bold` (`Font.quicksand("Bold", …)`) | |
| Font Android | `sans-serif` + `textStyle="bold"` (Roboto, D11 home-widget) | |
| Cỡ | nhỏ 12 (co tới 10) · vừa 14 (iOS co tới 12; Android cố định 14) | bộ 10/11/12/14 |

Không có nền/pill sau dòng trạng thái. Lý do: (1) pill là fill, mà ở chế độ tinted hệ thống tô fill trùng màu chữ, đúng lỗi 1,05:1 home-widget từng gặp; (2) pill tốn thêm 16pt ngang (padding 8 hai bên) trên một dòng vốn đã chật.

### 5.2 iOS nhỏ (`SmallCounter`)

Thứ tự VStack (spacing 0, như 1.9.1):

1. `NamesChip`: không đổi.
2. `Spacer(minLength: 4)`: không đổi.
3. `DayNumber`: không đổi; thêm `.layoutPriority(1)` **chỉ khi có trạng thái**, để thiếu chỗ thì dòng trạng thái nhường, số không co.
4. `Caption`: `padding(.top, 6)` như cũ. Có trạng thái thì `lineLimit(1)` + `minimumScaleFactor(0.85)`; không có thì `lineLimit(2)` như cũ.
5. **`StatusLine`** (mới, chỉ render khi có trạng thái): `padding(.top, 6)`.
   - Một `Text` ghép: `Text(Image(systemName: "circle.fill")).font(.system(size: 6, weight: .bold)).foregroundColor(dotColor) + Text(" ") + Text(statusText)`.
   - `.font(.quicksand("Bold", 12))`, `.foregroundColor(.white)`, `.lineLimit(1)`, `.truncationMode(.tail)`, `.minimumScaleFactor(0.84)` (12 → 10), `.inkShadow()`, `.accentable()`.
   - `.accessibilityLabel(statusText)` (để VoiceOver không đọc "circle").
   - Chấm 6pt nằm trên baseline, tâm ≈3pt trên baseline, trùng tâm x-height Quicksand 12 (x-height 0,503em ⇒ 6pt / 2 = 3pt). Khoảng cách chấm–chữ = 1 dấu cách ≈3pt.

Ngân sách dọc (nội dung 126pt): chip 20 + spacer ≥4 + số 50 (Quicksand 1,25em) + 6 + chú thích 15 + 6 + trạng thái 15 = **116** ⇒ còn 10pt dư.

### 5.3 iOS vừa (`MediumCounter`)

- Cột trái `SmallCounter(...).frame(width: 150)` **không nhận trạng thái** (truyền `status: nil`), nên không dịch pixel nào.
- Cột phải VStack spacing 8 giữ nguyên các con: cột mốc · thanh · "còn…" · `Spacer(minLength: 0)` · **phần tử cuối**:
  - không có trạng thái: `Text(model.sinceText)` y hệt 1.9.1;
  - có trạng thái: `StatusLine` cỡ **14**, `lineLimit(2)`, `minimumScaleFactor(0.857)` (14 → 12), cùng chấm 6pt (tâm 3pt trên baseline; x-height 14 là 7pt ⇒ lệch 0,5pt, chấp nhận).
- Dùng `if/else` trong cùng một vị trí con ⇒ số con của VStack không đổi ⇒ spacing 8 không thêm/bớt.
- Ngân sách dọc cột phải: cột mốc 2 dòng 30 + 8 + thanh 6 + 8 + "còn…" 15 + trạng thái 2 dòng 35 = **102** ≤ 126.

### 5.4 Android 2×2 (`widget_day_small.xml`)

Thêm sau `widget_caption`:

```
LinearLayout  @+id/widget_status   match_parent × wrap_content, horizontal,
              layout_marginTop 6dp, gravity top, visibility gone
├─ ImageView  @+id/widget_status_dot   wrap_content × wrap_content,
│             src @drawable/widget_status_dot, paddingTop 5dp, marginEnd 4dp,
│             importantForAccessibility no
└─ TextView   @+id/widget_status_text  0dp(weight 1) × 16dp,
              sans-serif + bold, textColor #FFFFFF, includeFontPadding false,
              autoSizeTextType uniform, autoSizeMin 10sp, autoSizeMax 12sp,
              maxLines 1, ellipsize end, gravity center_vertical|start,
              shadowColor #4D000000, shadowDy 1, shadowRadius 8
```

- `paddingTop 5dp` = tâm x-height Roboto 12sp tính từ đỉnh dòng (ascent 0,928 − x-height/2 0,264 = 0,664em ≈ 8dp) trừ bán kính chấm 3dp.
- Chiều cao cố định 16dp cho autosize co chữ theo bề ngang (12 → 10 trước khi cắt, giống `minimumScaleFactor` iOS). Nó cũng chặn chữ lớn lên quá một dòng khi người dùng phóng cỡ chữ hệ thống (§7.2).
- `widget_caption`: `setInt("setMaxLines", 1)` khi có trạng thái, `2` khi không.

Ngân sách dọc (≈120dp): chip 20 + số 46 + 6 + chú thích ≈16 + 6 + trạng thái 16 = **110**.

### 5.5 Android 4×2 (`widget_day_medium.xml`)

- Cột trái giữ nguyên, kể cả `widget_caption` maxLines 2.
- Cột phải: thêm khối `widget_status` (cấu trúc như §5.4) **ngay sau `widget_since`**, khác ở chỗ:
  - TextView `wrap_content` chiều cao, `textSize 14sp` cố định (không autosize: autosize cần chiều cao cố định, mà dòng đơn thì phải nằm sát đáy cột), `maxLines 2`, `ellipsize end`.
  - Dot `paddingTop 6dp` (0,664 × 14 − 3 ≈ 6,3).
  - `widget_since` = `GONE` khi có trạng thái, `VISIBLE` khi không.
- Chữ hệ thống ≥130% (`context.resources.configuration.fontScale >= 1.3f`) thì `maxLines` của status = 1, nếu không cột phải tràn đáy.

### 5.6 Độ tương phản (đã tính)

| Trường hợp | Chữ trạng thái | Chấm |
|---|---|---|
| M2, nền `#241F45` → `#352A5E` | 15,5 → 12,8:1 | blush 7,2:1 |
| M2, giữa vệt hồng góc dưới trái (`#FF6B9D` .28 trên navy ≈ `#61345E`) | 9,7:1 | 4,5:1 |
| P3, ảnh trung bình | ≫ 4,5:1 | trắng, như chữ |
| **P3 xấu nhất: ảnh trắng tinh**, dải đáy (t = 0,80 → 0,90, scrim .52 → .56) | 4,2 → 4,6:1 **trước** bóng chữ; bóng .30 kéo nền sát nét chữ tối thêm | trắng 4,2:1 |

Dải đáy bản nhỏ là đúng chỗ chú thích 1.9.1 đang nằm (đã qua review). Không đậm scrim lên khi có trạng thái: ảnh sẽ tối đi mỗi lần có tin mới, nhìn như lỗi.

### 5.7 Chuỗi dài nhất (đo bằng bảng advance thật của Quicksand-Bold.ttf và Roboto-Bold.ttf, chưa tính kerning ±3%)

Bề rộng chữ có được: iOS nhỏ 117pt (126 − chấm + dấu cách 9) · Android nhỏ 110dp (120 − 10) · iOS vừa 118pt (iPhone 393–402pt) hoặc 101pt (iPhone SE/8, widget vừa 321pt) · Android vừa 124dp.

| Loại | Chuỗi (tên 12 ký tự) | Bề rộng ở 12 | Nhỏ iOS (1 dòng) | Nhỏ Android | Vừa iOS 338 (≤2 dòng) | Vừa Android |
|---|---|---|---|---|---|---|
| question_partner vi | Nguyễn Hoàng đã trả lời, đến lượt mình | 229pt | "Nguyễn Hoàng đã trả l…" | "Nguyễn Hoàng đã trả l…" | cắt ở dòng 2 | cắt ở dòng 2 (cần 13) |
| question_partner en | Nguyễn Hoàng answered — your turn | 218 | "Nguyễn Hoàng answe…" | "…" | cắt ở dòng 2 | cắt ở dòng 2 (cần 12) |
| question_both vi/en | Cả hai đã trả lời hôm nay / You both answered today | 146 / 150 | cắt ("…hôm n…") | vi đủ ở 10 | đủ ở 14 | đủ ở 14 |
| question_mine vi/en | Câu hỏi hôm nay đang chờ mình / Today's question is waiting for you | 186 / 202 | "Câu hỏi hôm nay đang…" | "…" | đủ ở 14 | đủ ở 14 |
| mood vi | Nguyễn Hoàng hôm nay: bình thường (dài nhất của 8 nhãn) | 216 | **"Nguyễn Hoàng hôm n…"** (mất tâm trạng) | "…hôm na…" | đủ ở 12 | cắt ở dòng 2 (cần 13) |
| mood vi (ví dụ PO) | Nguyễn Hoàng hôm nay: căng thẳng | 214 | "Nguyễn Hoàng hôm n…" | "…hôm na…" | đủ ở 12 | cắt ở dòng 2 (cần 13) |
| mood en | Nguyễn Hoàng today: missing you | 199 | "…" | "…" | đủ ở 12 | đủ ở 14 |
| message vi/en | Nguyễn Hoàng vừa nhắn cho mình / … just messaged you | 199 | "…" | "…" | đủ ở 12–13 | đủ ở 14 |
| photo vi/en | Nguyễn Hoàng vừa đăng ảnh mới / … just added a photo | 194 / 200 | "…" | "…" | đủ ở 12–13 | đủ ở 14 |
| decision_eat (kết quả dài) | Hôm nay ăn: Bún chả Hàng Mành | 192 | "Hôm nay ăn: Bún chả…" | "…" | đủ ở 14 | đủ ở 14 |
| decision_go | Hôm nay đi: Đà Lạt | 111 | đủ ở 12 | đủ ở 12 | đủ | đủ |
| decision_custom | Ai rửa bát?: Anh | 92 | đủ ở 12 | đủ ở 12 | đủ | đủ |

Với tên ngắn ("Thảo"): bản vừa đủ chữ ở mọi loại, cả iPhone SE. Bản nhỏ vẫn cắt gần hết (vd "Thảo đã trả lời, đến lư…", "Thảo vừa nhắn cho mì…"). Đây là giới hạn của "1 dòng" + copy D2, xem câu hỏi 1.

**Không tràn, không lệch số:** dòng trạng thái là phần tử riêng, `lineLimit`/`maxLines` cứng nên chỉ cắt ngang, không đẩy gì sang bên. Tên người ấy dài cỡ nào cũng chỉ làm câu cắt sớm hơn. Bản vừa đặt trạng thái ở cột phải nên cột số không đổi một pixel. Bản nhỏ đặt dưới cùng, số chỉ dịch lên theo chiều dọc (21pt) và đứng yên dù câu dài hay ngắn.

## 6. States

| State | Hiển thị |
|---|---|
| **Không trạng thái** (couple active, hôm nay người ấy chưa làm gì; hoặc `todayDate` ≠ ngày đang vẽ; hoặc `statusText` rỗng) | Trùng pixel 1.9.1 (§9.1). |
| **9 loại trạng thái** | Cùng một kiểu dòng, chỉ khác chữ (copy D2). `question_mine` (về mình) cũng có chấm: nó là lời nhắc đang chờ, cùng vai "có việc mới". |
| **Trống** (guest, chưa couple, đăng xuất, rời couple) | Bố cục trống 1.9.1, không có dòng trạng thái kể cả khi kho native còn trạng thái cũ (D6: `state=empty` xoá cả hai). Android: không gọi id `widget_status*` trên layout trống (layout đó không có id này; một action sai id làm hỏng cả widget). |
| **Chờ người ấy** | Bố cục đếm ngày, không có dòng trạng thái (Flutter không gửi; native cũng chỉ hiện khi đủ điều kiện ở dòng đầu). |
| **Qua 0:00** | iOS: entry 0:00 trở đi tự về "Không trạng thái". Android: trễ ≤30 phút (D7 home-widget). |
| **Preview trong bộ chọn widget** | Không bao giờ có trạng thái: iOS `context.isPreview` / placeholder bỏ qua status; Android `updatePickerPreviews` ép `widget_status` GONE. Lý do: bộ chọn là ảnh mẫu, hiện "Thảo vừa nhắn cho mình" ở đó vừa cũ vừa lộ chuyện riêng. |

### 6.4 Vì sao chỉ một chấm, không icon theo loại

- Câu nào cũng mở bằng tên hoặc chủ đề ("Thảo đã trả lời", "Hôm nay ăn"), nên chữ đã nói loại rồi.
- Bản nhỏ chật: icon 12 + khoảng 4 ăn mất 16pt, tức thêm khoảng 2–3 ký tự bị cắt trên một dòng vốn đã thiếu chỗ.
- 9 icon × 2 nền tảng = 18 asset, cộng phải soát tinted cho từng cái. Chấm thì 1 SF Symbol + 1 drawable.
- Chấm đủ làm hai việc: tách dòng trạng thái khỏi chú thích, và báo "có cái mới" giống chấm chưa đọc mà ai cũng quen.

## 7. Tinted / Clear / cỡ chữ lớn

### 7.1 iOS 18 Tinted, iOS 26 Tinted + Clear

- Toàn bộ `StatusLine` là **một `Text`** gắn `.accentable()`: chữ + chấm đều nhận màu tint. Không có fill phía sau ⇒ không dính lỗi pill 1,05:1.
- Độ đọc được bằng đúng số ngày và chú thích (hệ thống chọn màu cho cả nhóm accent): tint mặc định iOS 18 đo được 5,47:1; tint đậm, iOS 26 Tinted và Clear 1,6–4,0:1 là giới hạn nền tảng đã ghi ở home-widget. Feature này không làm tệ hơn.
- Bản vừa: cột phải đã `.accentable()` cả khối như 1.9.1, `StatusLine` nằm trong đó.

### 7.2 Cỡ chữ lớn

- **iOS:** `Font.custom` lớn theo Dynamic Type. Khi có trạng thái, gắn `.dynamicTypeSize(...DynamicTypeSize.xxxLarge)` cho `StatusLine` **và** `Caption` (bản nhỏ), cho `StatusLine` (bản vừa). Ở `xxxLarge` chữ 12 thành ≈16, 14 thành ≈19. Ngân sách bản nhỏ lúc đó: 20 + 4 + 50 + 6 + 20 + 6 + 20 = 126, vừa khít. Lớn hơn nữa (AX1–AX5) thì hai dòng này đứng yên ở `xxxLarge`, số ngày vẫn theo luật 1.9.1. Không có trạng thái thì không chặn gì: AX giữ nguyên hành vi 1.9.1 (smoke AX5 đã PASS).
- **Android:** `widget_status_text` bản nhỏ cao cố định 16dp + autosize 10–12sp ⇒ phóng cỡ chữ không làm dòng cao thêm. Bản vừa: `fontScale ≥ 1.3` ⇒ 1 dòng. Chú thích bản nhỏ 1 dòng khi có trạng thái. Ở 200% bố cục 1.9.1 vốn đã chật (chú thích 2 dòng), feature này không làm tệ hơn.
- Chấm Android có `paddingTop` cố định theo 12/14sp; ở cỡ chữ ≥130% chấm lệch khỏi tâm dòng tối đa ≈3dp. Chấp nhận (trang trí).

## 8. Localization

Copy 9 loại trạng thái **giữ nguyên D2**, Designer không đổi lời. `{mood}` = `moodLabel` viết thường: vi `vui · hạnh phúc · nhớ · bình yên · bình thường · mệt · buồn · căng thẳng`; en `happy · loved · missing you · calm · meh · tired · sad · stressed`.

Thiết kế này **không cần chuỗi mới**. Chấm không có chữ; trình đọc màn hình đọc nguyên `statusText`.

Chuỗi đề xuất (chỉ làm khi PO duyệt câu hỏi 1 và 2):

| Key đề xuất | VI | EN | Dùng cho |
|---|---|---|---|
| `widgetStatusShortQuestionPartner` | {name} đã trả lời | {name} answered | bản nhỏ |
| `widgetStatusShortQuestionBoth` | Cả hai đã trả lời | You both answered | bản nhỏ |
| `widgetStatusShortQuestionMine` | Câu hỏi đang chờ mình | Your question is waiting | bản nhỏ |
| `widgetStatusShortMood` | {name}: {mood} | {name}: {mood} | bản nhỏ |
| `widgetStatusShortMessage` | {name} vừa nhắn | {name} messaged you | bản nhỏ |
| `widgetStatusShortPhoto` | {name} đăng ảnh mới | {name} added a photo | bản nhỏ |
| `widgetStatusShortDecisionEat` | Ăn: {result} | Eat: {result} | bản nhỏ |
| `widgetStatusShortDecisionGo` | Đi: {result} | Go: {result} | bản nhỏ |
| (custom) | dùng lại `{question}: {result}` | | bản nhỏ |
| `widget_description` (native, sửa) | Số ngày bên nhau và việc người ấy vừa làm hôm nay. | Your days together, and what your partner just did today. | bộ chọn widget |

Đo bản rút gọn ở bản nhỏ iOS (117pt): "Thảo đã trả lời" 86pt (đủ ở 12), "Thảo: căng thẳng" 102pt (đủ ở 12), "Nguyễn Hoàng đã trả lời" 119pt ở 10 (cắt 1 ký tự), "Nguyễn Hoàng: căng thẳng" 133pt ở 10 (vẫn cắt, nhưng giữ được "căng th…" thay vì mất hẳn).

## 9. Dev notes

### 9.1 Trùng pixel khi không có trạng thái (D12)

- **iOS:** điều kiện hiện = `snapshot.isCounter && status.todayDate == ngày của entry && !statusText.isEmpty && !context.isPreview`. Sai ⇒ `status = nil` ⇒ `SmallCounter` không render `StatusLine` (dùng `if let`, **không** `.opacity(0)`, không `Text("")`), `Caption` giữ `lineLimit(2)`, `DayNumber` không có `layoutPriority`. Bản vừa: nhánh `else` là đúng `Text(model.sinceText)` với modifier 1.9.1. Không thêm `padding`/`spacing` nào ngoài `if`.
- **Android:** XML mặc định `widget_status` = `gone`, `widget_since` = visible, caption maxLines 2 ⇒ inflate mới y hệt 1.9.1. Nhưng launcher **reapply** RemoteViews khi layout id không đổi (bài học 1.9.1), nên mỗi lần `render` phải đặt đủ cả hai nhánh: `widget_status` VISIBLE/GONE · `widget_status_text` text (kể cả `""`) · `widget_status_dot` `setImageViewResource` theo nền · `widget_caption` `setMaxLines` 1/2 · (vừa) `widget_since` GONE/VISIBLE + `setMaxLines` status theo fontScale. View `GONE` không chiếm chỗ và margin của nó cũng bỏ ⇒ không có khoảng trống.
- **Kiểm:** chụp widget build 1.9.1 và build mới cùng dữ liệu, không trạng thái, so pixel = 0 khác biệt, cả 4 bố cục × 2 nền.

### 9.2 Assets

| Nền tảng | Asset | Chi tiết |
|---|---|---|
| iOS | SF Symbol `circle.fill` | inline trong `Text`, `.font(.system(size: 6, weight: .bold))`, màu `blush` (M2) / `.white` (P3), tinted thì theo tint |
| Android | `res/drawable/widget_status_dot.xml` (mới) | `<shape android:shape="oval">` `<size 6dp×6dp/>` `<solid #FF8FA3/>` |
| Android | `res/drawable/widget_status_dot_light.xml` (mới) | như trên, `<solid #FFFFFF/>` cho P3 (RemoteViews không đổi tint drawable được ở API thấp, nên 2 file như cặp `widget_heart`/`widget_heart_light`) |

Không emoji, không ảnh bitmap.

### 9.3 Thứ tự z

Không đổi lớp nền: `widget_bg` → ảnh → scrim → sao → chòm sao → nội dung. Dòng trạng thái nằm trong lớp nội dung (cùng LinearLayout/VStack với chú thích), trên cùng, không có lớp riêng.

### 9.4 Padding theo bố cục

| Bố cục | Lề ngoài | Khoảng trên dòng trạng thái | Chấm → chữ |
|---|---|---|---|
| iOS nhỏ | lề hệ thống (16; iOS 15–16: 14) | 6 | 1 dấu cách ≈3pt |
| iOS vừa | như trên | spacing 8 của VStack (sẵn có) | ≈3pt |
| Android 2×2 | 16dp | marginTop 6dp | marginEnd 4dp |
| Android 4×2 | 16dp | sau spacer weight 1 (sát đáy) | marginEnd 4dp |

### 9.5 Lưu ý khác

- Không thêm animation. iOS 17+ tự chuyển mềm khi timeline đổi, để mặc định.
- Câu `statusText` đến từ Flutter đã dịch sẵn (D5). Native không ghép chuỗi, không viết hoa/thường lại.
- Kerning chưa tính trong bảng §5.7. Khác biệt ±3% chỉ dời điểm cắt "…" một ký tự.

## 10. Acceptance (design)

- [ ] Không trạng thái: 4 bố cục × 2 nền trùng pixel 1.9.1 (diff ảnh = 0).
- [ ] Có trạng thái: bản nhỏ 1 dòng dưới chú thích, bản vừa ≤2 dòng ở đáy cột phải, "Bắt đầu từ…" ẩn; cột trái bản vừa không đổi pixel.
- [ ] Cỡ: nhỏ 12 Bold (co tới 10), vừa 14 Bold (iOS co tới 12); không cỡ nào ngoài 10/11/12/14.
- [ ] Chấm 6pt/6dp: blush trên trời đêm, trắng trên ảnh, theo tint khi tinted; VoiceOver/TalkBack không đọc chấm.
- [ ] Tên 12 ký tự + câu dài nhất: cắt "…" đúng chỗ, không xuống dòng thừa, số ngày không dịch ngang.
- [ ] iOS AX5 có trạng thái: dòng trạng thái + chú thích dừng ở `xxxLarge`, không đè số, không tràn đáy. Android 200%: không tràn đáy.
- [ ] iOS 18 tinted: chữ + chấm cùng màu tint, đọc được như số ngày.
- [ ] Trống / chờ người ấy / preview bộ chọn: không có dòng trạng thái.
- [ ] Ảnh trắng tinh làm nền: chữ trạng thái vẫn đọc được (≥4,2:1 + bóng).

## 11. Câu hỏi cho PO

1. **Bản nhỏ cắt mất phần quan trọng.** Với copy D2, widget nhỏ chỉ chứa ≈17–20 ký tự, nên "Nguyễn Hoàng hôm nay: căng thẳng" thành "Nguyễn Hoàng hôm n…" (mất tâm trạng), còn "Thảo đã trả lời, đến lượt mình" thành "Thảo đã trả lời, đến lư…". Có duyệt thêm bộ chữ rút gọn cho bản nhỏ (bảng §8) không? Nếu duyệt thì D6 phải có thêm khoá `statusTextShort`. Nếu không thì thiết kế vẫn chạy được: cắt "…" như trên, chạm vào vẫn mở đúng thẻ.
2. **Mô tả trong bộ chọn widget** đang là "Số ngày chúng mình bên nhau, cập nhật mỗi ngày.". Đổi thành "Số ngày bên nhau và việc người ấy vừa làm hôm nay." để người dùng biết widget có thêm phần này không? Chỉ sửa 4 file chuỗi native, không đụng ARB.

## Changelog

- [2026-10-19] [Designer] Thiết kế dòng trạng thái cho 4 bố cục × 2 nền. Bản nhỏ đặt dưới chú thích (1 dòng, 12 co tới 10); bản vừa thay chỗ "Bắt đầu từ…" ở đáy cột phải (≤2 dòng, 14), nên cột số giữ nguyên pixel. Một chấm 6pt (blush/trắng/tint) thay cho icon theo loại. Chặn Dynamic Type ở `xxxLarge` cho dòng trạng thái, Android autosize 16dp + 1 dòng khi chữ ≥130%. Đo bề rộng chữ dài nhất bằng font thật (Quicksand/Roboto Bold), tính contrast cả ảnh trắng tinh. Tra UI UX Pro Max 13 truy vấn; tinted/monochrome không có dữ liệu nên theo WidgetKit (fallback). Mockup bấm thử `docs/design/widget-today-mockup.html`. 2 câu hỏi cho PO: bộ chữ rút gọn cho bản nhỏ, mô tả widget.
