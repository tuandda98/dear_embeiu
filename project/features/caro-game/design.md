# 🎨 Design — Cờ caro theo lượt (caro-game)

> Designer sở hữu. Hành vi (luật, callable, push, dữ liệu) theo [`overview.md`](overview.md) — file này chỉ quyết *trông thế nào*. Bám [`../../design-system.md`](../../design-system.md) + code thật `lib/theme/`, `lib/widgets/`. CHỈ thiết kế, không code.

- **Trạng thái design:** xong bản đầu, chờ PO/user duyệt (2026-10-20)
- **Người/role:** Designer
- **Mockup bấm thử (mở bằng trình duyệt, phông Quicksand lấy từ `assets/fonts/`):** [`docs/design/caro-game/`](../../../docs/design/caro-game/)
  - `home-entry.html` thẻ "Chơi cùng nhau" 10 trạng thái · `sheet.html` rủ ván mới · `board.html` **màn ván, bấm được** (chạm ô → quân mờ → chạm lại/nút "Đi nước này" → chờ; nút kính lúp đổi 1×/1,6×; thêm `#loi` vào URL rồi đi để xem lỗi) · `board-states.html` 13 trạng thái + menu + hỏi lại xin thua · `result.html` kết thúc + 4 biến thể · `history.html` lịch sử + rỗng/tải/lỗi · `notify.html` push, hộp thư, dòng widget
  - Dữ liệu mẫu có kiểm: `data.js` (21 ván, tỉ số đếm từ dòng, bàn cuối dựng bằng chính hàm `caroWinner` tham khảo) · ảnh chụp 390: `docs/design/caro-game/shots/`
- **Liên quan:** [overview.md](overview.md) · [dev.md](dev.md) · [test.md](test.md) · họ hàng gần nhất [`../rps-game/design.md`](../rps-game/design.md) · widget [`../widget-today/`](../widget-today/overview.md)

---

## 0. Tóm tắt quyết định

| # | Quyết định | Lý do |
|---|---|---|
| C1 | **Mặt của feature = "cặp đôi là ba làn"**: dải làn trong thẻ trạng thái, *mình trái · luật + số nước giữa · người ấy phải*. Làn của người đang tới lượt (hoặc người thắng) phủ màu riêng của người đó α .10. | Gợi ý của sheet đợt 2. Cùng thứ tự "bạn trước, người ấy sau" của feature sleep, và đọc đúng chuỗi tỉ số PO chốt "Tuấn 12 – 9 Thảo" trên máy Tuấn. |
| C2 | **Thứ chỉ caro có = bàn ô ly 15×15 vẽ bằng màu của hai người**: X/O theo `PersonPalette` (giống sleep), nước cuối có nền màu người vừa đi, đường thắng là dải màu người thắng. Lịch sử có **bàn thu nhỏ 44px** của từng ván. | Nhìn bàn là biết ai đi đâu mà không cần chú thích; hình X/O vẫn tách được khi mù màu (D19). |
| C3 | **Màn ván không cuộn trang.** Header, thẻ trạng thái, bàn, thanh hành động xếp dọc; bàn co theo chiều cao còn lại. | Bàn phóng to kéo bằng 1 ngón. Đặt bàn trong vùng cuộn thì hai cử chỉ giành nhau (InteractiveViewer trong ScrollView). |
| C4 | **Mở ván ở 1,6× canh giữa nước cuối** (ô ≈ 37dp trên 390, ≈ 35dp trên 360). Nút kính lúp đổi qua lại "Toàn bàn 1×" ↔ 1,6×; hai ngón 1×–2,5×. Bàn trống, màn kết quả và xem lại mở ở 1×. | 1× chỉ còn 22–23dp/ô, chạm nhầm ô kế bên nhiều. Nút kính lúp là đường thay thế cho người không dùng được hai ngón (WCAG 2.5.7, tra UI UX Pro Max). |
| C5 | **Chạm 2 bước:** chạm ô trống → viền navy + quân mờ α .45, nút "Đi nước này" sáng; chạm lại đúng ô **sau ≥400ms** hoặc bấm nút → đi. Chạm ô khác thì đổi chỗ. **Không có chạm-đúp-để-phóng-to.** | Đi nhầm không có đường lui. Chặn 400ms để hai cú chạm nhanh vô tình không thành một nước. |
| C6 | **Nút đặc navy chỉ dùng cho việc người ấy đang chờ mình** (đi tiếp, vào chơi, đi nước này, rủ chơi ở bước cuối). Các nút còn lại viền navy. Thẻ Home **bỏ CTA gradient hồng** của `RpsInviteCard`. | Chữ trắng trên `sunsetRomance` chỉ ~1,7:1 ở đầu nhạt; navy 15,9:1. Một nút đặc mỗi khối nên mắt biết bấm đâu trước. |
| C7 | **Home: một thẻ "Chơi cùng nhau" thay `RpsInviteCard`**, hai dòng cố định: Cờ caro trên, Oẳn tù tì dưới. | Không thêm thẻ thứ hai vào Home (D15). Thứ tự cố định để tay quen chỗ. |
| C8 | **Xin thua / lịch sử / luật** nằm trong menu ⋯ ở header, không đặt cạnh nút "Đi". "Để sau" (huỷ khi bàn 1 quân) là nút chữ dưới thanh hành động. | Xin thua hiếm dùng và không lấy lại được; để xa nút chính, có hộp hỏi lại. |
| C9 | Kết quả **không có pháo giấy**; chỉ vẽ dải thắng 320ms và rung. | Một hiệu ứng có nghĩa là đủ (UI UX Pro Max "Excessive Motion"); pháo giấy để riêng cho oẳn tù tì. |

**Đề xuất bổ sung design system (PO duyệt, không tự thêm vào code ngoài các mục này):**
- `errorInk #C4242A` (5,9:1 trên trắng) cho chữ/nút phá huỷ cần đọc được. `AppColors.error #EF5350` chỉ đạt 3,3:1 với chữ trắng nên nút "Xin thua" đặc không dùng được nó.
- Widget mới `CaroBoard` (vẽ + chạm, dùng chung màn ván, kết quả, xem lại) và `CaroGlyph` (huy hiệu 26px: chữ thập mờ + X màu mình + O màu người ấy). Có thể rút `PlayTogetherCard` thành mẫu khi có trò thứ ba.

---

## 1. Run tasteskill (app screen) + UI UX Pro Max

### 1.1 Style và sheet
- Sheet chung của đợt: `docs/design/daily-open-2/sheet.raw.md` — **editorial-greeting, seed 1822703143, `--keep palette,type`**. Không draw lại.
- Map vai của sheet sang brand: ground = `dawnBlush` (giữ, thiết bị brand) · surface = `cardSurface #FFFFFF` · raised/tonal panel = `surfaceLight #F5F0F5` · rule = `textPrimary` α .08 · text = `#1A1A2E` · muted = `textSecondary #6B6B7B` (5,3:1 trên trắng) · primary = navy `#1A1A2E` · accent = `accentLove #FF4D6D` (chấm báo, quân của người chọn màu hồng) · status âm = `errorInk` đề xuất.
- Giữ "nước đi" của style: số ở weight thường (tỉ số 22 w500, tabular), panel tông `surfaceLight` một lớp, không khay lồng khay.
- Câu chào của style là việc của Home. Màn caro dùng h1 là **câu trả lời của màn** ("Đến lượt bạn"), không phải tên màn (tên màn nằm trong `EyebrowChip`).

### 1.2 Kiểm kê dữ liệu và việc (§2.1)
- **Vật:** ván (`rule` vn|free, `cells` 0–225 ô theo thứ tự, `turnUid`, `players{x,o}`, `status`, `result{winner, reason five|resign|full, line}`, `lastMoveAt`, `presence`, `lastNudgeAt`), `caroState{wins, draws}`.
- **Độ lớn thật:** ván thường 25–40 nước, dài nhất 225; mỗi cặp 1 ván mở; trung vị ván kéo dài ≥3 giờ (mục tiêu PO); tỉ số cặp mới 0 – 0, cặp chơi đều vài chục ván/tháng; hoà gần như không xảy ra (phải kín 225 ô).
- **Người:** 2 người, mở app 5–15 lần/ngày, mỗi lần 5–30 giây để đi 1 nước; tối có thể ngồi đi liền 6 nước. Điện thoại 360–430dp, một tay.
- **Việc hay làm nhất:** đi một nước khi tới lượt (2 chạm). Kế đó: xem bàn khi chờ, nhắc người ấy, phục thù.
- **Thứ của riêng sản phẩm:** tên hai người, màu riêng mỗi người (`person_palette.dart`), chuỗi tỉ số chung, bàn ô ly như vở cấp 2.

### 1.3 Câu hỏi · finding · việc chính · mặt — từng màn
| Màn | Câu hỏi một dòng | Finding đặt ở chỗ đọc đầu | Việc chính, cách 1 chạm | Mặt / thứ riêng |
|---|---|---|---|---|
| Thẻ Home "Chơi cùng nhau" | Có ai đang chờ mình chơi không? | "Đến lượt bạn. Thảo vừa đi nước 14." + chấm hồng | "Đi tiếp" (navy) | Huy hiệu `CaroGlyph` mang màu hai người |
| Sheet rủ ván | Chơi luật nào? | Hình 7 ô **O X X X X X O** cạnh câu "Thế này chưa thắng" / "Thế này là thắng" | "Chọn ô đầu tiên" | Hình minh hoạ luật dựng từ quân thật, không chữ giải thích dài |
| Màn ván | Tới lượt ai, người kia vừa đi đâu? | h1 "Đến lượt bạn" + "Thảo vừa đi nước 14 lúc 10:12." + ô nền màu trên bàn | Chọn ô → "Đi nước này" | Ba làn + bàn hai màu |
| Kết quả | Ai thắng, thắng thế nào? | "Thảo thắng ván này" + "Năm quân liền nhau ở nước 31, lúc 21:40. Ván kéo dài 12 giờ." + dải thắng | "Phục thù" / "Ván mới" | Làn người thắng phủ màu + "+1 ván này" |
| Lịch sử | Ai đang dẫn? | "Tuấn dẫn trước 3 ván" | Chạm dòng → bàn cuối | Bàn thu nhỏ từng ván |

### 1.4 UI UX Pro Max (skill 2.13.0, `scripts/search.py`, không `-I`)
| Truy vấn | Kết quả dùng | Áp vào |
|---|---|---|
| `"touch target size small grid cells" --domain ux` | 44pt iOS / 48dp Android; khoảng cách ≥8px giữa vùng chạm | Ô 1× chỉ 22–23dp ⇒ mở ở 1,6× + chạm 2 bước (C4, C5); nút trong dock 52, cách nhau 12 |
| `"confirm destructive action irreversible" --domain ux` | Hỏi lại trước hành động không lấy lại được; báo thành công | Hộp hỏi "Xin thua ván này?" ghi rõ tỉ số sau đó; "Để sau" và "Kết thúc ván" cũng hỏi lại |
| `"pinch zoom gesture alternative" --domain ux` | WCAG 2.2: thao tác kéo/cử chỉ phải có đường một chạm thay thế | Nút kính lúp 1× ↔ 1,6× (C4) |
| `"color not only indicator" --domain ux` | Không truyền nghĩa chỉ bằng màu; chữ 4.5:1 | X/O khác hình; lượt ghi bằng chữ ở h1; tên người là chữ navy, màu chỉ ở quân + nền làn |
| `"turn based game status indicator" --domain ux` | Phản hồi loading → thành công/lỗi; cập nhật trạng thái bằng câu có ngữ cảnh, không đọc số trần | Quân mờ → đậm / rút về + câu lỗi; h1 là `liveRegion` đọc "Đến lượt bạn. Thảo vừa đi nước 14" |
| `"reduced motion animation" --domain ux` | Tôn trọng Reduce Motion; 1–2 chuyển động chính mỗi màn | Chỉ 2 chuyển động: quân rơi + dải thắng; tắt hết khi `AppMotion.reduceMotion` |
| `"GestureDetector semantics custom paint" --stack flutter` | Bọc `Semantics` cho widget tự vẽ | Mỗi ô có nhãn (mục 7) |
| `"animation reduce motion" --stack flutter` | Dispose AnimationController | Ghi Dev notes |
| `"InteractiveViewer zoom pan"`, `"zoom gesture"`, `"bottom sheet"`, `"touch target"` `--stack flutter` | **0 kết quả** (đã thử lại bản ngắn) | Dùng mặc định của bảng ưu tiên trong SKILL.md (Touch 44/48, gesture có đường thay thế) — không phải dữ liệu tra được |
| `"rounded friendly sans vietnamese" --domain typography` | Be Vietnam Pro (dấu tiếng Việt) · Varela/Nunito tròn | Giữ Quicksand của app (đã kiểm đủ dấu), không đổi phông |
| `"romantic couple game playful pink" --domain color` | Hồng chính + tím phụ + vàng thưởng, nền hồng nhạt | Không thêm màu: hồng/tím đã có trong brand; màu người chơi lấy từ `PersonPalette` |

Thành phần đứng cạnh nhau đã soát chung: (1) hai dòng trong thẻ Home (cùng huy hiệu 44 r16, cùng CTA h40, cùng luật đặc/viền); (2) dock = nút kính lúp 52 + nút chính h52 cùng chiều cao, cùng viền 1,4; (3) hai lựa chọn luật trong sheet cùng khuôn; (4) ba làn cùng r16 cùng đệm.

---

## 2. Màn + luồng

```
Home ─ thẻ "Chơi cùng nhau" ─┬─ dòng Cờ caro ── có ván ──────────────► Màn ván (1,6×)
                             │                └ không có ván ─► Sheet chọn luật ─► Màn ván trống (1×) ─► chọn ô ─► "Rủ Thảo chơi"
                             └─ dòng Oẳn tù tì ─► RpsGameScreen (như cũ)
Push caro_invite/turn/nudge · Inbox caro_invite · Widget caro_turn ─► Màn ván của đúng gameId
Push caro_result ─► Màn ván ở trạng thái kết quả
Màn ván ── ⋯ ─► menu: Lịch sử ván · Luật của ván này · Xin thua (· Huỷ ván khi ≤1 quân)
Kết quả ─► "Phục thù"/"Ván mới" ─► Sheet chọn luật ─► ...      Kết quả ─► "Xem lịch sử ván" ─► Lịch sử ─► chạm dòng ─► Xem lại (bàn cuối)
Profile ─ huy hiệu Cờ caro ─► (đến lượt mình/được rủ) Màn ván | (còn lại) Lịch sử
```
Màn mới: `CaroGameScreen(gameId?)` (gồm cả trạng thái kết quả), `CaroHistoryScreen`, `CaroReplayScreen` (hoặc `CaroGameScreen(readOnly)`), sheet `showCaroNewGameSheet`, sheet menu. Widget mới: `PlayTogetherCard` (thay `RpsInviteCard` ở Home), `CaroBoard`, `CaroLanes`, `CaroGlyph`, `CaroThumb`.

---

## 3. Wireframe + spec từng màn (token chính xác)

### 3.0 Token dùng chung
| Thứ | Giá trị | Nguồn |
|---|---|---|
| Nền | `AppColors.dawnBlush` (#FFC1CC → #E8B4D8 → #C8A8E9), vẽ ngoài Scaffold trong suốt | design-system |
| Thẻ | `ContentCard` trắng r24, bóng black .06 blur 16 (0,10), đệm 16 | `lib/widgets/content_card.dart` |
| Ô làn / tile trong thẻ | `surfaceLight #F5F0F5` r16, đệm 10/12 | design-system (r16 = khối trong thẻ) |
| Lề ngang | 16 · khoảng giữa khối 12 · header top 16 | Home gutter 16 |
| Phông | Quicksand. Cỡ dùng: **11** chip · **12** chú thích · **13** phụ · **14** nút chữ/thân · **15** tên/tiêu đề dòng/nút · **16** tiêu đề thẻ · **20** h1 · **22** tỉ số | type scale (không cỡ lẻ) |
| Số | tỉ số, số nước, giờ: `FontFeature.tabularFigures()` | — |
| Nút chính | pill r999 h52, nền `textPrimary #1A1A2E`, chữ trắng 15 w600 | theme |
| Nút viền | pill r999 h52, nền trắng .55, viền navy 1,4, chữ navy 15 w600 | design-system "secondary outlined" |
| Nút tắt | nền trắng .55, chữ navy .70 (≥4.5:1), không viền, **nhãn nói lý do** ("Chạm một ô để chọn", "Nhắc được sau 12 phút") | tasteskill §8.1 |
| Nút chữ | 14 w700 navy, vùng chạm ≥44 | design-system |
| Màu người | `PersonPalette.resolve(...)` — mock: Tuấn rose #FF4D6D, Thảo teal #0E9384; mặc định chưa chọn là rose / purple #7C5CD6 | `lib/theme/person_palette.dart` |
| Nền làn tới lượt / thắng | màu người α .10 | mới, cùng họ sleep |
| Lỗi | nền `error` α .10 + icon `errorInk` | đề xuất `errorInk` |
| Ripple | InkWell rose .08 | design-system |

### 3.1 Thẻ Home "Chơi cùng nhau" — `PlayTogetherCard` (thay `RpsInviteCard`)
```
┌ ContentCard r24 pad 16 ─────────────────────────────┐
│ Chơi cùng nhau                         16 w700 navy  │
│ ┌──┐● Cờ caro                         ┌──────────┐   │  hàng min-h 68, đệm dọc 12
│ │XO│  Đến lượt bạn. Thảo vừa đi       │ Đi tiếp  │   │  huy hiệu 44 r16 surfaceLight + CaroGlyph 26
│ └──┘  nước 14.                        └──────────┘   │  tiêu đề 15 w700 · phụ 13 (textPrimary w600 khi tới lượt mình)
│ ─────────────────────────────────────────────────── │  1px textPrimary .08
│ ┌──┐  Oẳn tù tì                        ( Chơi )      │  IconBadge(game, rpsMedalAccent #F26D5B) · CTA viền
│ └──┘  Tuần này 3 – 1 – 2                            │
└──────────────────────────────────────────────────────┘
```
- CTA pill h40, đệm ngang 18, 14 w700. **Đặc navy** khi người ấy đang chờ mình (caro: tới lượt mình, được rủ; rps: `myTurn`, `invitedByPartner`), **viền navy** mọi trạng thái khác. Chấm 9px `accentLove` viền trắng 1,5 ở góc (−3,−3) huy hiệu, cùng điều kiện với nút đặc (giữ y hệt chấm rps hiện có).
- Bỏ viền hồng .45 bao cả thẻ của rps (thẻ giờ có 2 dòng, viền không chỉ được dòng nào).
- Cả dòng bấm được (InkWell r16 trong thẻ); `Semantics(button, label: "Cờ caro. <câu phụ>")`.
- Ẩn cả thẻ khi `couple.isWaitingForPartner` (D14).

**Trạng thái dòng caro** (thứ tự `if/else`, ưu tiên việc của mình):
| # | Điều kiện | Câu phụ | CTA |
|---|---|---|---|
| 1 | được rủ: `playing`, `cells.length == 1`, tôi không phải `createdBy` | `caroEntryInvited` | Vào chơi · đặc · chấm |
| 2 | tới lượt mình | `caroEntryMyTurn` | Đi tiếp · đặc · chấm |
| 3 | ván treo ≥7 ngày | `caroEntryStale` | Xem · viền |
| 4 | chờ người ấy, presence người ấy <45s | `caroEntryWatching` | Xem · viền |
| 5 | chờ người ấy | `caroEntryWaiting` | Xem · viền |
| 6 | không ván mở, ván xong gần nhất <24 giờ | `caroEntryJustLost` / `JustWon` / `JustDraw` | Phục thù (thua) / Ván mới · viền |
| 7 | không ván mở, đã có ván xong | `caroEntryIdle` | Rủ chơi · viền |
| 8 | chưa từng chơi | `caroEntryFirst` | Rủ chơi · viền |
| — | đang tải | khối xám đúng cỡ (`ShimmerSkeleton`, Reduce Motion đứng yên) | khối 72×40 |
| — | lỗi, không có bản lưu | `caroEntryError` | Thử lại · viền |
| — | mất mạng | hiện trạng thái từ cache Firestore như thường; không thêm chữ | — |

Dòng rps giữ logic 6 trạng thái hiện có, chỉ đổi: dòng 1 = `rpsGameTitle`; dòng 2 = tiêu đề trạng thái cũ (vd `rpsPartnerMovedTitle`) hoặc tỉ số tuần khi rảnh; CTA theo luật đặc/viền ở trên (bỏ gradient).

**Vị trí đề xuất:** đúng chỗ `_entrance(7, RpsInviteCard())` hiện nay trong `home_screen.dart` (sau `SleepCard`, trong nhóm "Hôm nay"). Designer ghép Home của đợt quyết vị trí cuối.

### 3.2 Sheet rủ ván — `showCaroNewGameSheet`
```
┌ sheet trắng, góc trên r28, đệm 8/16/24 ─────────┐
│              ▬ (36×4 #D9D3DB)                    │
│ Rủ Thảo chơi caro                    20 w700     │
│ Chọn luật cho ván này. Đổi được ở ván sau.  14   │
│ ┌ (●) Chặn hai đầu  lần trước ─────────────────┐ │  chọn: nền trắng, viền navy 1,5, r16
│ │     Năm quân liền nhau là thắng, trừ khi … 13│ │
│ │     [O|X|X|X|X|X|O]  Thế này chưa thắng  13w600│
│ └──────────────────────────────────────────────┘ │
│ ┌ ( ) Tự do ───────────────────────────────────┐ │  chưa chọn: nền surfaceLight, viền trong suốt
│ │     Cứ năm quân liền nhau là thắng, bị chặn …│ │
│ │     [O|X|X|X|X|X|O]  Thế này là thắng         │ │
│ └──────────────────────────────────────────────┘ │
│ ✕ Bạn cầm X và đi trước. Thảo nhận lời rủ…  13  │
│ [        Chọn ô đầu tiên        ]  pill navy h52 │
└──────────────────────────────────────────────────┘
```
- Radio 22, viền navy 2, chấm 10. Toàn ô là `RadioListTile`-tương đương (vùng chạm cả khối), `Semantics(inMutuallyExclusiveGroup, checked)`.
- Hình 7 ô: 140×20, ô 20, viền navy .14, quân vẽ bằng `CaroBoard` painter (đúng màu hai người). Cùng một hình ở cả hai lựa chọn, chỉ khác câu kết luận: thấy ngay khác biệt của luật.
- "lần trước" 12 w600 textSecondary, chỉ trên lựa chọn đang lưu ở Hive (`caro_last_rule`); lần đầu không hiện chữ này, chọn sẵn "Chặn hai đầu".
- Bấm "Chọn ô đầu tiên" → đóng sheet, màn ván trống ở 1×, h1 "Đặt quân đầu tiên".
- Mở từ: Home (không có ván), kết quả "Phục thù"/"Ván mới", lịch sử rỗng "Rủ Thảo một ván".

### 3.3 Màn ván — `CaroGameScreen`
```
←               [🎮 CỜ CARO]               ⋯        SubScreenHeader(badge caroBadge, icon IconsaxPlusBold.game, trailing: HeaderIconButton(IconsaxPlusLinear.more))
┌ ContentCard pad 16 ─────────────────────────────┐
│ Đến lượt bạn                          h1 20 w700│  Semantics(header, liveRegion)
│ Thảo vừa đi nước 14 lúc 10:12.        14        │  tên = textPrimary w600, còn lại textSecondary
│ ┌ ✕ Tuấn ─────┐  Chặn hai đầu  ┌──── Thảo ○ ┐   │  ba làn (C1): Row(Expanded, mid ≥84, Expanded), gap 8
│ │ 12          │    nước 14     │          9 │   │  tỉ số 22 w500 tabular · chú thích 12
│ │ thắng       │                │    thắng   │   │  làn tới lượt: nền màu người α .10; còn lại surfaceLight
│ └─────────────┘                └────────────┘   │
└─────────────────────────────────────────────────┘
┌ ContentCard r24 pad 6 ──────────────────────────┐
│ ClipRRect r18 · InteractiveViewer 1×–2,5×        │  vuông; cạnh = min(W−32, chiều cao còn lại)
│  ┼──┼──┼──┼──┼  ô ly: đường textPrimary .12 1px  │  390: 346px/15 = 23,1 ở 1× · 37 ở 1,6×
│  ┼ ○┼  ┼[✕]┼  ┼  [✕] = ô đang chọn               │  360: 316px (gutter 16 + đệm 6) / 15 = 21,1 ở 1×
│  ┼  ┼ ✕┼▒○▒┼ ○┼  ▒ = nước cuối, nền màu người đi .16
└─────────────────────────────────────────────────┘
 (🔍)  [            Đi nước này            ]          kính lúp 52 viền · pill h52 navy
        Chạm lại ô đang chọn cũng là đi. Chạm ô khác để đổi.   13, chỉ hiện ở 5 nước đầu tiên bạn từng đi (Hive)
```
**Bàn (`CaroBoard`, CustomPainter):** không vẽ đường biên ngoài (mép thẻ là biên). X: hai nét chéo, nửa cánh .26 ô, nét `max(2.2, ô×0.11)` đầu tròn. O: tròn bán kính .28 ô, cùng nét. Nước cuối: nền ô màu người đi α .16. Ô chọn: rrect r4 lùi 1,5, viền navy 2 + quân mờ α .45 (α .60 khi đang gửi). Đường thắng (sau khi kết thúc): nền các ô màu người thắng α .16 + dải nối tâm ô đầu–cuối, nét .55 ô, α .30, đầu tròn, vẽ DƯỚI quân. Đường lưới 1px vật lý (không phóng theo zoom).

**Trạng thái màn ván** (mock `board.html` + `board-states.html`):
| Trạng thái | h1 | Câu phụ | Làn sáng | Dock |
|---|---|---|---|---|
| Tới lượt, chưa chọn | Đến lượt bạn | `caroLastMove` | mình | kính lúp + nút tắt "Chạm một ô để chọn" |
| Tới lượt, đã chọn | Đến lượt bạn | như trên | mình | "Đi nước này" (đặc) + gợi ý chạm lại |
| Đang gửi | Đến lượt bạn | như trên | mình | đặc, vòng quay 16 + "Đang đi…", bàn khoá chạm |
| Gửi lỗi (CF từ chối `stale/occupied/not_your_turn` hoặc lỗi mạng) | Đến lượt bạn | như trên | mình | khối lỗi trên dock + "Thử lại"; giữ ô đã chọn. `stale`/`not_your_turn`: tải lại ván, bỏ ô chọn, câu `caroStaleBoard` |
| Mất mạng | Đến lượt bạn | như trên | mình | ghi chú `caroOffline` (icon wifi gạch) + nút tắt "Chờ có mạng" |
| Chờ người ấy | Đang chờ Thảo | `caroYouMoved` | người ấy | viền tắt "Nhắc được sau N phút" (đếm theo phút, làm tròn lên) |
| Chờ, người ấy đang xem | Đang chờ Thảo | `caroPartnerWatching` | người ấy + chấm màu + "đang xem" | như trên |
| Chờ ≥30' | Đang chờ Thảo | `caroWaitedMin` | người ấy | viền "Nhắc Thảo" |
| Vừa nhắc | Đang chờ Thảo | `caroNudged` | người ấy | viền tắt "Nhắc được sau 30 phút" + SnackBar "Đã nhắc Thảo" |
| Được rủ (máy người được rủ) | `caroInvitedTitle` | `caroInvitedSubVn/Free` | mình | như tới lượt + nút chữ "Để sau" (hỏi lại) |
| Bàn trống (sắp rủ) | Đặt quân đầu tiên | `caroFirstSub` | mình, giữa ghi "ván mới" | nút "Rủ Thảo chơi" (tắt tới khi chọn ô). Chạm chữ luật ở làn giữa → mở lại sheet |
| Ván treo ≥7 ngày | `caroStaleTitle` | `caroStaleSub` | người tới lượt | tới lượt mình: "Đi nước này"; không: viền "Nhắc Thảo". Luôn kèm nút chữ "Kết thúc ván" (hỏi lại) |
| Người được rủ chưa vào sau 24 giờ | Đang chờ Thảo | `caroInvitedYesterday` | người ấy | ghi chú `caroOldAppHint` + viền "Nhắc Thảo" |
| Đang tải | khối xám 150×24, 240×18 | — | làn khung xám | bàn có lưới, không quân; nút tắt "Đang tải ván"; khung không nhảy khi dữ liệu về |
| Ván đã huỷ / hết hạn (mở từ push cũ) | `caroCancelledTitle` / `caroExpiredTitle` | `caroCancelledSub` / `caroExpiredSub` | không | "Rủ Thảo ván mới" (đặc), không kính lúp |
| Đã kết thúc | xem 3.4 | | | |

**Menu ⋯** (sheet trắng r28, các dòng cao 52, chữ 14 w700): Lịch sử ván · Luật của ván này (mở sheet đọc-thôi: tên luật + câu + hình 7 ô) · Xin thua (chữ `errorInk`) · Huỷ ván (chỉ khi `cells.length ≤ 1`). **Hỏi lại xin thua:** `AlertDialog` trắng r24: "Xin thua ván này?" + "Thảo được tính thắng. Tỉ số thành Tuấn 12 – 10 Thảo." + [Chơi tiếp (viền)] [Xin thua (đặc `errorInk`)].

**Bố cục chiều cao (C3):** `Column[SubScreenHeader, Padding(16,0,16,0): status card, 12, Expanded(Center(AspectRatio(1, board))), 12, dock, hint?, SizedBox(16 + bottom inset)]`. Trên máy 360×640 bàn tự co còn khoảng 250–280px, vẫn phóng được 2,5×. Không đặt trong `SingleChildScrollView`.

### 3.4 Kết thúc — trạng thái kết quả của `CaroGameScreen`
```
┌ status card ─────────────────────────────────────┐
│ Thảo thắng ván này                                │
│ Năm quân liền nhau ở nước 31, lúc 21:40.          │
│ Ván kéo dài 12 giờ.                               │
│ [○ Tuấn 12 thắng]  Chặn hai đầu  [Thảo ✕ 9 +1 ván này]  ← làn người thắng nền màu α .10
└───────────────────────────────────────────────────┘
┌ bàn ở 1×, dải thắng + nền 5 ô ───────────────────┐
[              Phục thù              ]   (người thua) / "Ván mới" (người thắng, hoà)
              Xem lịch sử ván              nút chữ
```
- Cả hai máy thấy cùng dải thắng (từ `result.line`). Bàn khoá chạm, vẫn phóng/kéo được.
- Biến thể (mock `result.html`): Bạn thắng · Người kia xin thua · Mình xin thua · Hoà (thêm dòng "Tỉ số: Tuấn 12 – 9 Thảo, 1 ván hoà.").
- **Ván hết hạn 7 ngày** không có màn kết quả (không tính tỉ số): dùng trạng thái "Ván này đã kết thúc vì để lâu".
- Rung: thắng `heavyImpact`, thua/hoà `lightImpact` (như rps).

### 3.5 Lịch sử — `CaroHistoryScreen`
```
←          [🎮 LỊCH SỬ CARO]
┌ status card ──────────────────────────────────┐
│ Tuấn dẫn trước 3 ván                    h1 20  │  hoà: "Đang hoà 9 – 9"
│ 21 ván từ 23/09. Ván gần nhất Thảo thắng hôm qua.
│ [✕ Tuấn 12 thắng]   21 ván   [Thảo ○ 9 thắng] │  mid = tổng ván (không phải luật)
└────────────────────────────────────────────────┘
Tháng 10                                   14 w700 (DateFormat theo locale)
┌ ContentCard đệm 4/16, các dòng cách bằng 1px ─┐
│ [thumb] ✕ Thảo thắng                Hôm qua   │  dòng min-h 68: thumb 44 r8 · tên 15 w700 + quân màu người thắng 14
│         Năm quân liền, 31 nước                │  phụ 13 textSecondary · ngày 13 tabular phải
│ [thumb] ○ Tuấn thắng                   17/10  │
│         Thảo xin thua ở nước 22               │  luật tự do thêm ". Tự do"
└───────────────────────────────────────────────┘
```
- `CaroThumb` 44: nền `surfaceLight` r8, mỗi quân là chấm r 1,3/60 màu người, dải thắng α .35. Không chữ.
- Một `ContentCard` mỗi tháng (không thẻ riêng mỗi dòng — đỡ 21 cái bóng chồng nhau). Ngày: "Hôm nay", "Hôm qua", còn lại `dd/MM` theo locale.
- Phân trang 30 (D13), cuộn gần đáy tải thêm, khối 3 dòng xám khi tải; lỗi trang sau: thẻ nhỏ "Chưa tải thêm được ván cũ." + "Thử lại".
- Rỗng: giữ khung thẻ trạng thái, h "Chưa có ván nào xong", câu PO "Ván đầu tiên đang chờ đó." + "Tỉ số bắt đầu từ 0 – 0." và làn 0 – 0 (giữa "0 ván"); nút "Mở ván đang chơi" nếu có ván mở, không thì "Rủ Thảo một ván".
- Chạm dòng → **Xem lại**: dùng bố cục 3.4 ở chế độ chỉ xem: chip ngày "VÁN 19/10", không dock, không menu.

### 3.6 Thông báo, hộp thư, widget, Profile
- **Push:** dùng nguyên copy PO §6.3. Mock `notify.html` cho thấy khay chỉ còn 1 dòng/ván (khoá `caro_{gameId}`).
- **Trung tâm thông báo `caro_invite`:** khung dòng như các loại khác; avatar = `CaroGlyph` trên `surfaceLight` 44 r16; tiêu đề `notifCaroInvite` "{name} rủ chơi cờ caro"; dòng phụ dùng lại thân push "Nước đầu đã đi rồi, giờ đến lượt bạn." (không cần field mới). Chạm → `openCaroGame(gameId)`.
- **Widget-today `caro_turn`:** chữ đúng bảng PO §7.1; hình dòng theo design của feature widget-today. Bản vừa "Thảo đã đi caro, đến lượt mình", bản nhỏ "Lượt mình đi caro".
- **Profile (D15):** thêm ô "Cờ caro" vào `_AchievementsGrid` dùng `_badgeCard` (giá trị "12 – 9" 22 w800, gạch nối EN DASH có khoảng trắng; huy hiệu `CaroGlyph`); chấm 9px như rps khi tới lượt mình/được rủ; có chấm → mở ván, không chấm → lịch sử. Lưới thành 7 ô: xem câu hỏi Q2.

---

## 4. Motion (theo `AppMotion`)
| Chuyển động | Thời lượng / đường cong | Reduce Motion |
|---|---|---|
| Quân mờ hiện khi chọn | opacity 0→.45, `AppMotion.fast` 200ms `easeOutCubic` | hiện ngay |
| Quân đặt (của mình khi CF trả ok; của người ấy khi doc đổi lúc đang xem) | scale .6→1 + opacity, 200ms `easeOutCubic` | hiện ngay |
| Đổi zoom bằng nút | `TransformationController` tween 280ms (`AppMotion.base`) `easeOutCubic`, canh giữa nước cuối | nhảy thẳng |
| Nền làn đổi lượt | `AnimatedContainer` 280ms | 0ms |
| Dải thắng | vẽ dần từ ô đầu tới ô cuối 320ms (`AppMotion.slow`) `easeOutCubic`, trễ 200ms sau quân cuối | vẽ tĩnh |
| Sheet / dialog | mặc định Material | mặc định |
Không có hiệu ứng vào màn (entrance) trên màn ván; thẻ Home dùng `_entrance` sẵn có của Home.

---

## 5. Accessibility
- **Ô cờ:** mỗi ô một nút ảo trong `Semantics` của `CaroBoard` (dùng `CustomPainter.semanticsBuilder` trả 225 `CustomPainterSemantics`, hoặc lớp `Semantics` phủ lưới): nhãn "Hàng {r}, cột {c}, trống" / "Hàng {r}, cột {c}, quân X của Tuấn" (+ ", nước vừa đi" / ", đang chọn" / ", trong đường thắng"). Ô trống khi tới lượt mình có `onTap` = chọn; ô đang chọn có `onTap` = đi. Hàng/cột đếm từ 1.
- **h1** `Semantics(header: true, liveRegion: true)` để nước mới của người ấy được đọc: "Đến lượt bạn. Thảo vừa đi nước 14 lúc 10:12."
- **Vùng chạm:** mọi nút ≥44 (nút 52, CTA Home 40 cao nhưng cả dòng 68 bấm được). Ô cờ 1× nhỏ hơn 44 → có nút kính lúp và chạm 2 bước bù.
- **Màu:** X/O khác hình; lượt và kết quả đều có chữ; chữ phụ `textSecondary` chỉ trên nền trắng (5,3:1), không đặt chữ xám trên nền gradient. Màu người α .10 làm nền làn không mang chữ màu.
- **Kính lúp** có `tooltip` + nhãn "Xem toàn bàn" / "Phóng to quanh nước cuối".
- **Reduce Motion:** bảng mục 4. Rung tôn trọng cài đặt hệ thống (HapticFeedback tự bỏ khi tắt).
- Chữ to (textScaler 1,3): h1 và câu phụ được xuống dòng; làn giữ 3 hàng, tên ellipsis 1 dòng; dock không đổi chiều cao.

---

## 6. Copy deck (vi / en)
Xưng "bạn" với người dùng, gọi người ấy bằng tên (fallback `reactionPartnerFallback` "Người ấy"/"Your partner"), "chúng mình" khi nói về cả hai. Dấu kiểu mới. Không ICU `{}` ngoài placeholder. Đã soát theo `humanizer` (bỏ câu giải thích giao diện, bỏ chuỗi nối bằng "·") và bản EN theo `avoid-ai-writing` (câu ngắn, không từ quảng cáo).

**Home**
| Key | VI | EN |
|---|---|---|
| `playTogetherTitle` | Chơi cùng nhau | Play together |
| `caroGameTitle` | Cờ caro | Caro |
| `caroEntryInvited` | {name} rủ bạn một ván và đã đi nước đầu. | {name} started a game and made the first move. |
| `caroEntryMyTurn` | Đến lượt bạn. {name} vừa đi nước {n}. | Your turn. {name} just played move {n}. |
| `caroEntryWaiting` | Đang chờ {name}. Bạn đi nước {n} lúc {time}. | Waiting for {name}. You played move {n} at {time}. |
| `caroEntryWatching` | Đang chờ {name}. {name} đang xem ván. | Waiting for {name}, who has the game open. |
| `caroEntryStale` | Ván dừng {days} ngày rồi. Vào kết thúc để rủ ván mới. | No moves for {days} days. Open it to end the game. |
| `caroEntryJustLost` | {name} thắng ván vừa rồi. {score}. | {name} won the last game. {score}. |
| `caroEntryJustWon` | Bạn thắng ván vừa rồi. {score}. | You won the last game. {score}. |
| `caroEntryJustDraw` | Ván vừa rồi hoà. {score}. | The last game was a draw. {score}. |
| `caroEntryIdle` | {score}. Rủ {name} một ván? | {score}. Another game with {name}? |
| `caroEntryFirst` | Rủ {name} một ván, bạn đi trước. | Start a game with {name}. You go first. |
| `caroEntryError` | Chưa tải được ván. Chạm để thử lại. | Couldn't load the game. Tap to try again. |
| `caroScore` | {me} {a} – {b} {partner} | {me} {a}–{b} {partner} |
| `caroScoreDraws` | {score}, {n} ván hoà | {score}, {n} draws |
| `caroCtaJoin` / `caroCtaPlayOn` / `caroCtaOpen` | Vào chơi / Đi tiếp / Xem | Play / Your move / Open |
| `caroCtaRematch` / `caroCtaNewGame` / `caroCtaInvite` / `caroCtaRetry` | Phục thù / Ván mới / Rủ chơi / Thử lại | Rematch / New game / Start / Try again |

**Sheet rủ ván**
| Key | VI | EN |
|---|---|---|
| `caroNewTitle` | Rủ {name} chơi caro | Start a caro game with {name} |
| `caroNewSub` | Chọn luật cho ván này. Đổi được ở ván sau. | Pick the rules for this game. You can switch next time. |
| `caroRuleVn` | Chặn hai đầu | Blocked ends |
| `caroRuleVnDesc` | Năm quân liền nhau là thắng, trừ khi cả hai đầu đều bị quân người kia chặn. | Five in a row wins, unless both ends are blocked by the other player. |
| `caroRuleFree` | Tự do | Freestyle |
| `caroRuleFreeDesc` | Cứ năm quân liền nhau là thắng, bị chặn hai đầu vẫn tính. | Any five in a row wins, even with both ends blocked. |
| `caroRuleExampleNoWin` / `caroRuleExampleWin` | Thế này chưa thắng / Thế này là thắng | This doesn't win / This wins |
| `caroRuleLastUsed` | lần trước | last time |
| `caroNewFirstNote` | Bạn cầm X và đi trước. {name} nhận lời rủ khi bạn đặt quân đầu. | You play X and go first. {name} gets the invite when you place your first piece. |
| `caroNewCta` | Chọn ô đầu tiên | Choose your first square |

**Màn ván**
| Key | VI | EN |
|---|---|---|
| `caroBadge` | CỜ CARO | CARO |
| `caroMyTurn` | Đến lượt bạn | Your turn |
| `caroLastMove` | {name} vừa đi nước {n} lúc {time}. | {name} played move {n} at {time}. |
| `caroWaiting` | Đang chờ {name} | Waiting for {name} |
| `caroYouMoved` | Bạn đi nước {n} lúc {time}. Đã báo cho {name}. | You played move {n} at {time}. {name} has been notified. |
| `caroPartnerWatching` | Bạn đi nước {n} lúc {time}. {name} đang xem ván. | You played move {n} at {time}. {name} is looking at the board. |
| `caroWaitedMin` | Bạn đi nước {n} lúc {time}. Đã {m} phút rồi. | You played move {n} at {time}, {m} minutes ago. |
| `caroNudged` | Đã nhắc {name} lúc {time}. | You nudged {name} at {time}. |
| `caroLaneWins` / `caroLaneWatching` / `caroLaneMove` / `caroLaneNew` / `caroLaneGames` | thắng / đang xem / nước {n} / ván mới / {n} ván | wins / watching / move {n} / new game / {n} games |
| `caroLanePlusOne` | +1 ván này | +1 this game |
| `caroPickCell` | Chạm một ô để chọn | Tap a square |
| `caroPlayHere` | Đi nước này | Play here |
| `caroSending` | Đang đi… | Playing… |
| `caroSendError` | Chưa đi được. Mạng đang chập chờn, ô bạn chọn vẫn giữ nguyên. | That move didn't go through. Your square is still selected. |
| `caroStaleBoard` | Bàn vừa đổi, xem lại rồi đi nhé. | The board changed. Take another look before you move. |
| `caroOffline` | Đang mất mạng. Có mạng lại là đi tiếp được. | You're offline. You can move once you're back. |
| `caroWaitNetwork` | Chờ có mạng | Waiting for connection |
| `caroTapAgainHint` | Chạm lại ô đang chọn cũng là đi. Chạm ô khác để đổi. | Tap the selected square again to play it, or pick another. |
| `caroNudge` | Nhắc {name} | Nudge {name} |
| `caroNudgeIn` | Nhắc được sau {m} phút | You can nudge in {m} min |
| `caroNudgeSent` (SnackBar) | Đã nhắc {name} | Nudged {name} |
| `caroInvitedTitle` | {name} rủ bạn chơi caro | {name} wants to play caro |
| `caroInvitedSubVn` | {name} đã đi nước đầu. Luật chặn hai đầu: năm quân bị chặn cả hai đầu thì chưa thắng. | {name} made the first move. Blocked ends: a five blocked at both ends doesn't win. |
| `caroInvitedSubFree` | {name} đã đi nước đầu. Luật tự do: cứ năm quân liền nhau là thắng. | {name} made the first move. Freestyle: any five in a row wins. |
| `caroLater` | Để sau | Not now |
| `caroFirstTitle` | Đặt quân đầu tiên | Place your first piece |
| `caroFirstSub` | Bạn cầm X và đi trước. {name} nhận lời rủ khi bạn đi xong. | You play X and go first. {name} gets the invite after your move. |
| `caroInviteCta` | Rủ {name} chơi | Invite {name} |
| `caroStaleTitle` | Ván dừng {days} ngày rồi | No moves for {days} days |
| `caroStaleSub` | Không ai đi từ {date}. Nhắc {name}, hoặc kết thúc để rủ ván mới. | Nobody has moved since {date}. Nudge {name}, or end it and start over. |
| `caroEndGame` | Kết thúc ván | End game |
| `caroInvitedYesterday` | Bạn rủ {name} lúc {time} hôm qua. | You invited {name} yesterday at {time}. |
| `caroOldAppHint` | Nếu {name} chưa thấy ván, có thể app của {name} cần cập nhật. | If {name} can't see the game, their app may need an update. |
| `caroLoading` | Đang tải ván | Loading game |
| `caroCancelledTitle` / `caroCancelledSub` | Ván này đã huỷ / {name} bấm Để sau lúc {time}. Ván huỷ không tính vào tỉ số. | This game was cancelled / {name} chose Not now at {time}. Cancelled games don't count. |
| `caroExpiredTitle` / `caroExpiredSub` | Ván này đã kết thúc vì để lâu / 7 ngày không ai đi nên ván dừng ở đây, không tính tỉ số. | This game has ended / Nobody moved for 7 days, so it stopped here. It doesn't count. |
| `caroNewInviteCta` | Rủ {name} ván mới | New game with {name} |
| `caroMenuHistory` / `caroMenuRules` / `caroMenuResign` / `caroMenuCancel` | Lịch sử ván / Luật của ván này / Xin thua / Huỷ ván | Game history / Rules for this game / Resign / Cancel game |
| `caroResignTitle` / `caroResignBody` | Xin thua ván này? / {name} được tính thắng. Tỉ số thành {score}. | Resign this game? / {name} gets the win. The score becomes {score}. |
| `caroKeepPlaying` | Chơi tiếp | Keep playing |
| `caroCancelTitle` / `caroCancelBody` / `caroCancelConfirm` | Bỏ ván này? / Ván huỷ không tính tỉ số. {name} sẽ thấy ván đã huỷ. / Bỏ ván | Skip this game? / It won't count. {name} will see it was cancelled. / Skip |
| `caroEndTitle` / `caroEndBody` | Kết thúc ván này? / Ván không tính tỉ số. Xong là rủ ván mới được. | End this game? / It won't count, and you can start a new one. |
| `caroZoomIn` / `caroZoomOut` (Semantics/tooltip) | Phóng to quanh nước cuối / Xem toàn bàn | Zoom in on the last move / Show the whole board |

**Kết quả**
| Key | VI | EN |
|---|---|---|
| `caroYouWon` / `caroPartnerWon` | Bạn thắng ván này / {name} thắng ván này | You won this game / {name} won this game |
| `caroWinDetail` | Năm quân liền nhau ở nước {n}, lúc {time}. Ván kéo dài {span}. | Five in a row on move {n}, at {time}. The game took {span}. |
| `caroSpanHours` / `caroSpanMinutes` | {h} giờ / {m} phút | {h} hours / {m} minutes |
| `caroPartnerResigned` / `caroPartnerResignedSub` | {name} xin thua / Ván này bạn thắng, ở nước {n}. | {name} resigned / You win this one, on move {n}. |
| `caroYouResigned` / `caroYouResignedSub` | Bạn đã xin thua / {name} được tính thắng ván này. | You resigned / {name} gets the win. |
| `caroDraw` / `caroDrawSub` | Ván này hoà / Kín cả 225 ô mà chưa ai thắng. | This game is a draw / All 225 squares are full and nobody won. |
| `caroSeeHistory` | Xem lịch sử ván | See game history |

**Lịch sử**
| Key | VI | EN |
|---|---|---|
| `caroHistoryBadge` | LỊCH SỬ CARO | CARO HISTORY |
| `caroLeads` / `caroTied` | {name} dẫn trước {n} ván / Đang hoà {a} – {a} | {name} leads by {n} / Tied at {a}–{a} |
| `caroHistorySub` | {n} ván từ {date}. Ván gần nhất {name} thắng {when}. | {n} games since {date}. {name} won the last one {when}. |
| `caroRowWon` / `caroRowDraw` | {name} thắng / Hoà | {name} won / Draw |
| `caroRowFive` / `caroRowResign` / `caroRowFull` | Năm quân liền, {n} nước / {name} xin thua ở nước {n} / Kín bàn, 225 nước | Five in a row, {n} moves / {name} resigned on move {n} / Board full, 225 moves |
| `caroRowFreeSuffix` | . Tự do | . Freestyle |
| `caroHistoryEmpty` / `caroHistoryEmptySub` | Chưa có ván nào xong / Ván đầu tiên đang chờ đó. Tỉ số bắt đầu từ 0 – 0. | No finished games yet / Your first game is waiting. The score starts at 0–0. |
| `caroOpenCurrent` / `caroStartWith` | Mở ván đang chơi / Rủ {name} một ván | Open current game / Start a game with {name} |
| `caroHistoryPageError` | Chưa tải thêm được ván cũ. | Couldn't load older games. |

**Semantics + hộp thư + feature tour**
| Key | VI | EN |
|---|---|---|
| `caroCellEmpty` / `caroCellX` / `caroCellO` | Hàng {r}, cột {c}, trống / Hàng {r}, cột {c}, quân X của {name} / …quân O của {name} | Row {r}, column {c}, empty / Row {r}, column {c}, {name}'s X / …{name}'s O |
| `caroCellLast` / `caroCellSelected` / `caroCellWinning` | , nước vừa đi / , đang chọn / , trong đường thắng | , last move / , selected / , part of the winning line |
| `notifCaroInvite` | {name} rủ chơi cờ caro | {name} started a game of caro |
| `featureTourCaroTitle` / `featureTourCaroBody` | Cờ caro theo lượt / Mỗi người đi một nước khi rảnh, rải cả ngày cũng được. Thắng thua cộng vào tỉ số chung của chúng mình. | Turn-based caro / Take turns whenever you have a minute, all day if you like. Every win adds to your shared score. |

**Đề xuất đổi copy PO (không tự đổi):** (1) dòng Home PO viết "Đến lượt bạn · nước 14", "Đang chờ Thảo · nước 14" — đề xuất viết thành câu (bảng trên), vì chuỗi nối bằng "·" đọc như nhãn máy và VoiceOver đọc dấu chấm giữa thành khoảng lặng lạ. (2) Thêm `caroEntryInvited`, `caroEntryStale` cho 2 trạng thái PO chưa liệt kê ở thẻ Home.

---

## 7. Map sang widget Flutter
| Phần | Dùng lại | Mới |
|---|---|---|
| Nền | `Container(gradient: AppColors.dawnBlush)` ngoài Scaffold trong suốt | — |
| Header | `SubScreenHeader` + `EyebrowChip` + `HeaderIconButton(IconsaxPlusLinear.more)` | — |
| Thẻ | `ContentCard` | — |
| Ba làn | — | `CaroLanes` (stateless: me/partner, palette, wins, turnSide, mid, watching, plusOne) |
| Bàn | `InteractiveViewer` + `TransformationController` | `CaroBoard` (CustomPainter + semanticsBuilder) dùng chung chơi/kết quả/xem lại/hình 7 ô |
| Bàn thu nhỏ | — | `CaroThumb` (CustomPainter 44) |
| Huy hiệu caro | khung giống `IconBadge` (44, r16) | `CaroGlyph` (26) — `IconBadge` chỉ nhận `IconData` |
| Dòng rps | `IconBadge(IconsaxPlusBold.game, tint: rpsMedalAccent)` | — |
| Thẻ Home | logic trạng thái của `RpsInviteCard` | `PlayTogetherCard` (gộp; `RpsInviteCard` thành dòng con) |
| Nút | `FilledButton` theme (pill h52) · `OutlinedButton` viền navy | — |
| Đang tải | `ShimmerSkeleton` | — |
| Sheet/menu | `showModalBottomSheet` r28 | `CaroNewGameSheet`, `CaroMenuSheet` |
| Hỏi lại | `AlertDialog` r24 | — |
| Lịch sử | khung phân trang như `care_timeline_screen.dart` / `rps_history_screen.dart` | `CaroHistoryScreen` |
| Icon | `IconsaxPlusBold.game` (chip), `IconsaxPlusLinear.more`, `search_zoom_in`/`search_zoom_out`, `danger`/`info_circle` (lỗi), `wifi_square` (mất mạng như rps) | — |

---

## 8. Dev notes (chỉ phần UI)
1. **Không cuộn trang ở màn ván** (C3). Bàn trong `Expanded` + `AspectRatio(1)`.
2. `InteractiveViewer(minScale: 1, maxScale: 2.5, constrained: true, boundaryMargin: EdgeInsets.zero)`. Mở ván: `Matrix4` scale 1,6 tịnh tiến để nước cuối vào giữa, kẹp trong biên. Bàn trống, kết quả, xem lại: 1×.
3. Chạm: `onTapUp` → `transformationController.toScene()` → ô. Bỏ qua khi không tới lượt, ô có quân, đang gửi. Chạm lại ô đang chọn chỉ tính là "đi" nếu cách lần chọn ≥400ms. **Không** bật double-tap zoom.
4. Quân mờ hiện ngay; gọi `caroAction(move, cell, moveNo: cells.length)`; ok → bỏ trạng thái mờ (doc realtime sẽ có quân thật); lỗi → giữ ô chọn + `caroSendError`; `stale`/`not_your_turn`/`occupied` → bỏ ô chọn + `caroStaleBoard`.
5. Màu: `PersonPalette.resolve(myUid, myChoice, partnerUid, partnerChoice)` — đọc cùng nguồn màu với sleep. Chưa ai chọn thì vẫn ra cặp rose/purple theo luật C1.
6. Nhắc: đếm phút còn lại = `30 − floor((now − max(lastMoveAt của mình, lastNudgeAt)) / 60s)`, cập nhật mỗi phút (Timer dừng theo `TickerMode`).
7. Gợi ý "chạm lại" chỉ hiện ở 5 nước đầu tiên người dùng từng đi (Hive `caro_hint_count`).
8. `h1` là `liveRegion`; khi doc đổi do người ấy đi thì đổi chữ, không push SnackBar.
9. Dispose `TransformationController` + mọi `AnimationController` (tra flutter stack).
10. Thẻ Home bỏ `foregroundDecoration` viền hồng và CTA gradient của rps (C6).

---

## 9. Thiết bị brand giữ dù tasteskill cấm (`--allow` + `taste-skill-ignore`)
| Rule tasteskill | Thiết bị | Vì sao giữ |
|---|---|---|
| `heavy-shadow` (inspect) · `shadow` (lint) | Bóng `ContentCard` black .06 blur 16 (0,10) | Primitive chung toàn app; bỏ ở riêng caro là lệch Home. User chốt "follow system design hiện tại". |
| `micro-label` (inspect) · `shadow` (lint) | `EyebrowChip` 11 w700 chữ hoa giãn 1,4, bóng rose .14 | Header chuẩn mọi màn con. |
| `colour-sprawl` (inspect) · `gradient` (lint) | Nền `dawnBlush` | Nền mọi màn (design-system); 14–25% "màu mạnh" là do nền này, không phải do dữ liệu. |
| `icon-chips` (inspect) | `IconBadge` / khung huy hiệu 44 r16 trên thẻ Home + hộp thư | Primitive của app, cùng chỗ rps đang có huy hiệu. Huy hiệu caro mang thông tin (màu hai người). |
| `shadow` (lint, `sheet.html`) | Bóng sheet | Sheet nổi thật — tasteskill cho phép. |
Không cần allow: trời đêm navy (caro không dùng), kính mờ của nav (không có trên màn caro).

---

## 10. Kiểm tra tasteskill
- `node ~/.claude/skills/design-taste-frontend/scripts/lint.mjs --app docs/design/caro-game` → **0 FAIL, 0 WARN** (5 dòng thiết bị brand mang `taste-skill-ignore`).
- `inspect.mjs --app <trang> --widths 390 --out .taste-skill/caro-game/<trang> --allow heavy-shadow,micro-label,colour-sprawl,icon-chips` → **0 FAIL, 0 WARN** cả 7 trang. Chạy không allow (board, home-entry) chỉ ra đúng 4 rule trên. **Chỉ đo 390** vì app chỉ có trên điện thoại.
- `console.assert` trong `data.js`: 0 lỗi (5 ca luật PO §6.2, ván hôm nay 14 nước chưa ai thắng, chẵn lẻ nước thắng của 21 ván, tỉ số 12 – 9 đếm từ dòng, nhắc còn 12 phút, ván treo 8 ngày).

### Ba vòng nhìn ảnh (7 câu §2.7)
**Vòng 1** (sau bản dựng đầu)
1. Câu hỏi có được thứ to nhất trả lời? Bàn to nhất, h1 đọc trước — đúng. Nhưng tỉ số 26 to hơn h1 20 và không trả lời câu hỏi của màn.
2. Mép: **hỏng** — bàn 1,6× đẩy rộng cột, thẻ làn bị cắt bên phải.
3. Màu: chỉ trên quân, nền làn, nút navy. Mặt ba làn hiện ngay màn đầu.
4. Số: "nước 14" ở câu phụ và làn giữa cùng một biến. Nhưng câu phụ "Ô tô hồng là nước đó" **sai**: nước cuối là của Thảo, nền teal.
5. Không có số 0 trên màn này.
6. Ký hiệu ở làn = đúng hình quân trên bàn.
7. Điện thoại: một cột, không nav.
→ Sửa: (a) `minmax(0,1fr)` cho cột, (b) bỏ câu giải thích màu, (c) tỉ số 26 → 22.

**Vòng 2** (các trang trạng thái + Home + kết quả)
1. Thẻ Home: nút "Chơi"/"Rủ chơi"/"Phục thù" cũng đặc navy như "Đi tiếp" ⇒ không thấy việc nào gấp.
2. Máy Thảo: làn của Thảo lại phủ hồng (tô theo vai "mình", không theo người).
3. Bàn kết quả nhìn như rải ngẫu nhiên, không giống ván thật; làn người thắng không sáng.
4–7: số khớp (tỉ số trước/sau, 31 nước, 12 giờ); viền nút bằng `box-shadow` bị inspector bắt `button-fx`.
→ Sửa: (a) luật C6 nút đặc chỉ khi người ấy đang chờ mình, (b) nền làn lấy màu người, (c) bàn mọc thành cụm quanh nước đầu + làn người thắng sáng; thêm: viền thật thay bóng trong.

**Vòng 3** (lịch sử, menu, chốt)
1. Lịch sử: làn giữa ghi "Chặn hai đầu" trên màn gom nhiều luật — sai nghĩa; trạng thái rỗng 0 – 0 cũng vậy.
2. Nút "Xin thua" đỏ `#EF5350` của brand chữ trắng chỉ 3,3:1.
3. Khối lỗi dùng nền `#FFEDEA` ngoài token.
→ Sửa: (a) giữa = "21 ván"/"0 ván", (b) đề xuất `errorInk #C4242A`, (c) nền lỗi = `error` α .10. Ảnh chụp lại sau cùng: không còn lỗi thấy được.

**Còn yếu (chưa sửa, nói thẳng):** bàn thu nhỏ 44px chỉ đọc được hình đường thắng, không đọc được thế cờ; khoảng trống ~140px dưới dock trên máy 844 (cố ý: dock nằm sát bàn cho gần ngón tay; máy thấp không còn khoảng này); huy hiệu `CaroGlyph` nhỏ, X/O 13px hơi mảnh; chưa dựng hình 360dp (chỉ tính bằng số ở 3.3).

---

## 11. Dữ liệu mẫu phải thay bằng dữ liệu thật
Tất cả trong `docs/design/caro-game/data.js`: ván hôm nay 14 nước (07:58–10:12), ô đang chọn (6,8 hàng 6 cột 8 tính từ 1), 21 ván lịch sử 23/09–19/10 (giả định feature đã chạy ~4 tuần — thực tế ra mắt sau 1.11.0), tỉ số 12 – 9, giờ 21:40 + 12 giờ của ván 19/10, mốc nhắc 10:20/10:38, ván treo từ 12/10, màu Tuấn rose/Thảo teal (giả định đã chọn ở Giấc ngủ), tỉ số oẳn tù tì tuần 3 – 1 – 2.

---

## 12. Câu hỏi cho PO / user
- **Q1 (PO):** `overview.md` còn 2 chỗ trái D3: §3 "Ngoài phạm vi" vẫn ghi "luật tự do / bật-tắt luật", và bảng §5.1 ghi `rule` chỉ `'vn'`. Design đã theo D3 (`vn | free`). PO sửa giúp để Dev khỏi đọc nhầm.
- **Q2 (user/PO):** Profile thêm ô "Cờ caro" thì lưới huy hiệu thành 7 ô (lẻ). Chọn: (a) ô Cờ caro nằm full-width ở cuối, hay (b) gộp Oẳn tù tì + Cờ caro thành một ô "Chơi cùng nhau" hiện tỉ số caro?
- **Q3 (user):** Thẻ Home bỏ nút gradient hồng của oẳn tù tì để thống nhất "nút đặc navy = người ấy đang chờ bạn" (C6). Đồng ý đổi cả dòng oẳn tù tì không?

---

## Acceptance (design)
- [x] Mọi trạng thái có hình (mock) + mô tả: Home 10 + ẩn, sheet, màn ván 13 + menu + hỏi lại, kết quả 5, lịch sử 4
- [x] Copy đủ VI + EN
- [x] Token, widget, motion, a11y đủ để Dev dựng không hỏi lại
- [x] lint + inspect 0 FAIL ở 390, ba vòng nhìn ảnh có ghi

## Nhật ký design
- [2026-10-20] [Designer] Thiết kế caro-game theo tasteskill (app run đủ §2.1–2.8, sheet đợt 2 editorial-greeting seed 1822703143 `--keep palette,type`) + UI UX Pro Max, bám design system hiện tại. Mặt "ba làn" (mình · luật · người ấy) + bàn hai màu người chơi + bàn thu nhỏ ở lịch sử. Quyết C1–C9: mở ván 1,6× + nút kính lúp, chạm 2 bước chặn 400ms, màn không cuộn, nút đặc navy chỉ khi người ấy chờ mình, thẻ Home "Chơi cùng nhau" thay `RpsInviteCard`. Mock 7 trang + `data.js` có assert + ảnh 390 ở `docs/design/caro-game/`. lint 0/0, inspect 0 FAIL 0 WARN cả 7 trang (allow heavy-shadow, micro-label, colour-sprawl, icon-chips — thiết bị brand). Đề xuất token `errorInk #C4242A`. 3 câu hỏi PO/user.
