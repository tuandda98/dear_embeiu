# Cây tình yêu (Love Tree) — design spec (Designer)

> Handoff cho Dev. Bám brand "Sunset Romance", nền dawnBlush, light mode, Lucide icons. **KHÔNG asset art ngoài** — cây + hoa dựng 100% bằng `CustomPaint` (path/shape) + widget Flutter compose. Tôn trọng `AppMotion.reduceMotion`.
>
> Nguồn: PO scope `overview.md` + `design-system.md` + primitive thật (`SubScreenHeader`/`EyebrowChip`/`ContentCard`/`InkTile`).

---

## 0. Quyết định thẩm mỹ (giải thích ngắn)

- **Cây = ẩn dụ tích luỹ, không "tươi tốt thật".** Tránh hiện thực hoá (làm 1 cây bonsai pixel-art). Thay vào đó: thân + tán **blob mềm bo tròn** (gọi là "tán mây") theo ngôn ngữ minimalism của app — vẽ bằng path bezier mượt, đổ gradient lá. Đẹp ở mọi stage mà KHÔNG cần asset.
- **Hoa = ngôi sao của màn.** Mỗi bông là 1 "huy hiệu cột mốc" — cánh hoa shape mềm + **nhuỵ = đĩa tròn chứa 1 Lucide icon** (đây là yêu cầu lõi của user). Nhuỵ icon làm hoa "đọc được" (loại mốc nào) chứ không chỉ trang trí.
- **Nền tách lớp:** nền màn dawnBlush (lo bởi nền chung / hoặc tự vẽ vì đây là màn CON push riêng — xem §1). Cây mọc từ một **"gò đất" cong** ở đáy → cảm giác vững, có gốc. Bầu trời phía sau cây = vài đốm sáng mờ (bokeh) tĩnh, rất nhẹ, để không nhiễu.
- **Tông cảm xúc:** ấm, dịu, shame-free (giống streak). 0 hoa KHÔNG "trống rỗng buồn" mà là "hạt mầm chờ hai bạn vun" — lời mời, không phán xét.

---

## 1. Layout tổng màn (`LoveTreeScreen`)

Màn CON push từ StreakChip → **không phải tab**, theo rule màn con. Nhưng `SubScreenHeader` thật (đã đọc code) = **1 hàng pinned: back ← + chip giữa + trailing optional**, KHÔNG render title/subtitle. Vậy:

- **Header (pinned, không cuộn):** `SubScreenHeader(badge: l10n.loveTreeBadge, badgeIcon: LucideIcons.flower2)`. Không trailing. Nền màn này tự vẽ (vì push riêng, không nằm trong shell 4-tab) → bọc toàn màn trong `Container(gradient: AppColors.dawnBlush)` + `SafeArea`.
- **Body (cuộn dọc — `SingleChildScrollView`):**
  1. **Khu cây** (hero, chiếm ~52% chiều cao khả dụng, min 360 / max 460): `CustomPaint` cây mọc từ gò đất đáy, hoa rải trên tán. Đây là điểm nhìn chính.
  2. **Khối tiêu đề trạng thái** (ngay dưới cây, căn giữa): tên stage hiện tại (size 22 w800 navy) + dòng phụ "X bông hoa đã nở" (14 textSecondary). + banner nở-hoa khi có hoa mới (§4).
  3. **`ContentCard` "Cùng vun đắp"** (§5): 2–3 `InkTile` hành động.
  4. **`ContentCard` "Cột mốc"** (§6): list mốc đã mở + mốc kế.
  5. Padding đáy 32.

### Wireframe ASCII

```
┌─────────────────────────────────────────────┐
│ ←            ✿ CÂY TÌNH YÊU                  │  SubScreenHeader (pinned)
│                                              │  nền dawnBlush toàn màn
│              · ·     ✿        · (bokeh mờ)   │
│                  ✿      ✿                    │
│                ╱▔▔▔▔▔▔╲    ✿                 │
│              (   tán mây   )  ← hoa rải trên │  KHU CÂY (CustomPaint)
│               ╲▁▁▁▁▁▁╱                       │  ~52% cao, min360/max460
│                  ┃┃ ┃                        │  thân + nhánh
│                  ┃┃                          │
│            ▁▁▁▁▁╱┃┃╲▁▁▁▁▁  ← gò đất cong     │
│ ─────────────────────────────────────────── │
│                                              │
│               🌳 Cây xanh                    │  stage title 22 w800
│             7 bông hoa đã nở                 │  14 textSecondary
│                                              │
│   ┌─ banner (chỉ khi có hoa mới) ─────────┐  │
│   │ 🌸 Cây vừa nở 2 bông mới              │  │  banner rose tint
│   └──────────────────────────────────────┘  │
│                                              │
│  ┌── Cùng vun đắp ────────────────────────┐  │  ContentCard
│  │ [🔥] Giữ chuỗi mỗi ngày        →        │  │  InkTile ×3
│  │ [📷] Thêm một kỷ niệm          →        │  │
│  │ [💞] Trả lời câu hỏi hôm nay   →        │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ┌── Cột mốc ─────────────────────────────┐  │  ContentCard
│  │ ●💞 100 ngày bên nhau         ✓ đã nở   │  │  mốc ĐÃ mở
│  │ ●🔥 Chuỗi 7 ngày              ✓ đã nở   │  │
│  │ ○📷 25 ảnh kỷ niệm   còn 6 ảnh nữa      │  │  mốc KẾ (mờ)
│  └────────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

---

## 2. Năm (5) stage cây — hình dáng + cách dựng

Tất cả vẽ trong 1 `CustomPainter` (`LoveTreePainter`) trên canvas vùng cây. Toạ độ chuẩn hoá theo `size` (vẽ theo tỉ lệ, không hardcode px) để co theo màn. Gốc cây neo đáy giữa: `base = Offset(w*0.5, h*0.92)`.

**Bảng đất + bầu trời (mọi stage):**
- Gò đất: path cong (quadratic bezier) trải ngang đáy, cao ~`h*0.08`, fill gradient dọc `#E8B4D8`(accentGold) .55 → `#C8A8E9` .30. Mép trên gò có 1 đường sáng mảnh trắng .25.
- Bokeh trời: 5–7 đĩa tròn mờ (radius 3–7px) rải nửa trên canvas, màu trắng .14–.22 — **vị trí cố định theo seed**, KHÔNG random mỗi build (xem §3 thuật toán jitter).

| Stage | Số hoa | Tên | Hình dáng + cách dựng | Màu |
|---|---|---|---|---|
| **S0 Hạt mầm** | 0 | Hạt mầm | Chỉ 1 **mầm cong** nhú từ gò: 1 path thân ngắn cao `h*0.12`, cong nhẹ chữ S, đầu ngọn có **2 lá mầm** đối xứng (mỗi lá = 1 oval xoay ±35°, dài `h*0.10`). KHÔNG tán. | thân `#7BA86A`(xanh lá non) · lá mầm gradient `#8FCB7A→#66A85C` |
| **S1–2 Mầm non** | 1–2 | Mầm non | Thân cao `h*0.28`, thẳng hơn, hơi mập ở gốc (path có bề rộng 5→3px thuôn). Tán = **1 blob nhỏ** (path bezier ~`w*0.30` rộng) ở ngọn + 4–5 lá nhỏ quanh viền. | thân `#9B7B5A`(nâu nhạt) · tán/lá gradient `#A8D88F→#7CB86A` |
| **S3–5 Cây non** | 3–5 | Cây non | Thân cao `h*0.42` + **1 nhánh phụ** rẽ (path Y nhẹ). Tán = **1 blob vừa** (`w*0.50` rộng, bo mềm 3 bướu) + lá viền 8–10. | thân `#8B6B4A`(nâu) · tán gradient `#9FD47F→#6FAF5C` |
| **S6–9 Cây xanh** | 6–9 | Cây xanh | Thân cao `h*0.48` mập + **2 nhánh** rẽ 2 bên. Tán = **blob lớn 5 bướu** (`w*0.68` rộng) phủ trên + 12–14 lá. Có **bóng tán** (path tối .06 lệch trái-dưới) tạo khối. | thân `#7A5A3C`(nâu đậm) · tán gradient `#92CF72→#5FA84F` + bóng `#3D6B33` .12 |
| **S10+ Nở rộ** | 10+ | Nở rộ | Như S6–9 nhưng tán **to nhất** (`w*0.80`, 6 bướu) + thân vững nhất + thêm **vài cánh hoa rơi** (3–4 cánh nhỏ rơi quanh gốc, tĩnh) + viền tán có **glow hồng rất nhẹ** (radial rose .10 sau tán). Cảm giác "tràn đầy". | thân `#6E5236` · tán gradient `#8FCF6E→#57A347` + glow `accentRose` .10 |

**Quy tắc dựng tán (blob mây):** path = chuỗi cubic bezier nối các điểm trên 1 ellipse cơ sở, mỗi điểm đẩy ra/vào theo "bướu" cố định (mảng offset hằng số theo số bướu) → đường viền lượn sóng mềm. Fill = `LinearGradient` dọc (sáng trên → đậm dưới). KHÔNG đổ shadow Flutter trên path (vẽ bóng = path thứ 2 màu tối, blur qua `MaskFilter.blur(BlurStyle.normal, 8)`).

**Lá:** mỗi lá = 1 path hình giọt (2 quadratic bezier khép) xoay theo góc cố định trên viền tán, fill cùng gradient tán đậm hơn 1 nấc + gân lá = 1 line trắng .20.

**Chuyển stage:** khi `flowerCount` đổi đủ để qua stage, cây render thẳng stage mới (không cần animate biến hình thân — quá phức tạp). Chỉ **hoa mới** được animate nở (§4). Stage title đổi tức thì.

---

## 3. Hoa — hình + nhuỵ + cách rải

### 3.1 Hình bông hoa (`FlowerPainter` / widget compose)

Mỗi bông render bằng **widget `_LoveFlower`** (Stack) chứ không vẽ trong painter cây (để dễ animate từng bông + đặt icon Lucide thật làm nhuỵ):

- **Cánh:** 5 cánh, mỗi cánh = `CustomPaint` path giọt mềm (rộng `petalW`, dài `petalW*1.25`), xoay đều 72° quanh tâm (`Transform.rotate`). Fill = `RadialGradient` từ tâm: sáng `#FFD6E0`(dreamyMint hồng) → mép `roseEdge` theo loại mốc (xem bảng). Viền cánh trắng .35 1px.
- **Kích thước cánh:** `petalW = 13` (đường kính bông ≈ 34px). Hoa cluster nhỏ ở mép tán có thể scale 0.82.
- **Nhuỵ (CỐT LÕI):** đĩa tròn đường kính **20px**, fill = `discFill` theo loại (bảng), viền trắng .60 1.2px, shadow nhẹ (màu loại .30 blur 6). Trong đĩa = **1 Lucide icon size 12 màu trắng** (`heart` filled dùng `Icons.favorite` vì Lucide không có filled heart — quy ước app; `flame`/`image` dùng Lucide).

### 3.2 Ba loại nhuỵ (theo nguồn cột mốc)

| Loại | Nguồn data | Icon nhuỵ | `discFill` (đĩa nhuỵ) | `roseEdge` (mép cánh) |
|---|---|---|---|---|
| **Ngày bên nhau** | `couple.anniversaryDate`→days; mốc 30·100·200·365·520·730·1000·1314 | `Icons.favorite` (heart filled) | `accentLove` #FF4D6D | #FF8FA3 (accentCoral) |
| **Streak dài nhất** | `StreakProvider.longestStreak`; mốc 3·7·30·100·365 | `LucideIcons.flame` | gradient cam-hồng = `#FF8FA3`→`accentLoveDeep #E63956` (đĩa đổ gradient chéo) | #FFB6C1 |
| **Số ảnh** | `PhotoProvider.photoCount`; mốc 1·10·25·50·100 | `LucideIcons.image` | `accentLavender` #A78BFA | #C8A8E9 (lavender nhạt) |

→ Cánh hoa mỗi loại hơi khác tông (hồng / cam-hồng / tím) để nhìn lướt biết "vườn hoa" gồm những loại mốc nào. Nhuỵ icon xác nhận chắc chắn.

### 3.3 Rải hoa lên tán — thuật toán xác định (KHÔNG random mỗi build)

Mỗi hoa có **index ổn định** = thứ tự mốc đã vượt (sort cố định: gộp cả 3 nguồn rồi sort theo `(loại, giá trị mốc)` — VD ngày-30, ngày-100, streak-3, streak-7, ảnh-1, ảnh-10…). Index này KHÔNG đổi khi rebuild → vị trí hoa ổn định.

Vị trí trên tán theo công thức (canvas-relative, tâm tán `Cx,Cy`, bán kính tán `R`):
```
// Phân bố trên đĩa tán theo vòng xoáy (phyllotaxis nhẹ) — dàn đều, không chồng:
angle = index * 137.5°          // golden angle → không bao giờ trùng tia
radius = R * sqrt((index+0.5) / capacity)   // dồn từ trong ra, đều mật độ
// jitter CỐ ĐỊNH theo index (không random runtime):
jx = (hash(index) % 7 - 3)      // -3..+3 px, hash = index*2654435761 >> shift
jy = (hash(index*31) % 7 - 3)
pos = Offset(Cx + radius*cos(angle) + jx, Cy*0.92 + radius*sin(angle)*0.7 + jy)
```
- `capacity` = số hoa tối đa kỳ vọng cho stage hiện tại (VD 14) — chỉ để chuẩn hoá bán kính; hoa quá `capacity` vẫn vẽ (bám viền).
- Nhân `sin*0.7` để tán dẹt theo trục ngang (hoa không tràn xuống thân).
- Hoa vẽ **sau** tán (đè lên), sort vẽ theo y tăng dần (hoa dưới vẽ trước → hoa trên đè, tạo lớp).
- Khi 0 hoa: không vẽ hoa nào (S0 chỉ có mầm).

**Lưu ý Dev:** dùng `index` (không phải milestone value) cho hash để vị trí ổn định khi list mốc dài thêm. Hoa cũ giữ nguyên chỗ, hoa mới rơi vào slot kế tiếp.

---

## 4. Animation NỞ HOA (khi mở màn có hoa mới)

**Trigger:** `flowerCount > lastSeenFlowerCount` (Hive `love_tree_seen_<coupleId>`). Số bông mới `newCount = flowerCount - lastSeen` (clamp ≥0). Các bông mới = các index từ `lastSeen` đến `flowerCount-1`.

**Diễn hoạt từng bông mới (stagger):**
1. Cánh: `scale 0.0→1.0` + `fade 0→1`, **duration 420ms**, curve `easeOutBack` (hơi nảy — cảm giác "bung nở").
2. Nhuỵ pop: đĩa nhuỵ `scale 0.0→1.0` **trễ 120ms** so với cánh, duration 300ms `easeOutBack` (pop sau khi cánh mở).
3. Sparkle: 3 hạt `✨`/đốm trắng nhỏ (4px) bắn ra từ tâm bông, fade-out 500ms — chỉ cho bông mới, dùng `confetti` đã có (`ConfettiController`, numberOfParticles nhỏ 6, màu `[accentRose, accentLavender, white]`) HOẶC vẽ 3 đốm scale+fade thủ công nếu muốn nhẹ hơn. **Đề xuất: dùng confetti có sẵn** (đã wire ở streak_sheet) để đỡ code.
4. **Stagger giữa các bông mới:** 140ms/bông (nếu nhiều bông mới cùng lúc, nở lần lượt như chuỗi pháo hoa). Cap hiển thị stagger ở 6 bông; >6 thì 6 bông đầu stagger, phần còn lại nở đồng loạt ở mốc cuối (tránh chờ lâu).

**Banner "Cây vừa nở X bông mới 🌸":**
- Vị trí: ngay dưới stage title, trên khối "Cùng vun đắp".
- Style: pill bo r16 (KHÔNG 999 — đây là banner, không phải chip nhỏ), fill `accentRose` .10, viền `accentRose` .30 1px, padding 14×12. Icon 🌸 (emoji) hoặc `LucideIcons.flower2` 16 `accentLoveDeep` + text 14 w700 `textPrimary`.
- Xuất hiện: `EntranceReveal` (fade + slideY 8px) sau khi cây vẽ xong (~delay 200ms). Tự ẩn không cần (giữ tới khi rời màn — nhẹ nhàng, không auto-dismiss gây giật).
- Sau khi animation chạy xong + user đã thấy → cập nhật `lastSeen = flowerCount` (ghi Hive). Lần mở sau không animate lại (banner biến mất, hoa hiện tĩnh).

**reduceMotion (`AppMotion.reduceMotion(context) == true`):**
- KHÔNG scale-in/sparkle/stagger. Tất cả hoa (kể cả mới) hiện **thẳng, đầy đủ** ngay frame đầu.
- Banner vẫn hiện (tĩnh, không slide) để vẫn báo "có X bông mới".
- Vẫn cập nhật `lastSeen`.

**Glow tán S10+ "thở":** chỉ animate khi !reduceMotion (giống aurora CounterCard); reduceMotion → frame tĩnh.

---

## 5. Khối "Cùng vun đắp"

`ContentCard` (trắng r24). Trong: `SectionHeader`/tiêu đề nhỏ "Cùng vun đắp" (16 w800 navy + icon `LucideIcons.sprout` rose 18) → 3 `InkTile` (white .72 r22, indent icon-squircle 44).

Mỗi tile = `IconBadge` (squircle tint .12 màu loại) + tiêu đề 15 w700 navy + dòng phụ 12 textSecondary + chevron `LucideIcons.chevronRight` 18 tertiary phải. Tap → điều hướng:

| Tile | Icon badge | Tiêu đề (vi) | Phụ (vi) | Hành động (Dev) |
|---|---|---|---|---|
| Giữ chuỗi | `flame` cam-hồng | Giữ chuỗi mỗi ngày | Trả lời câu hỏi để chuỗi không đứt | `pop()` về Home (về tab 0) — daily question card ở Home |
| Thêm kỷ niệm | `image` lavender | Thêm một kỷ niệm | Mỗi tấm ảnh là một bông hoa mới | `pop()` rồi chuyển tab Gallery (2) |
| Trả lời câu hỏi | `heart`/`messageCircle` rose | Cùng trò chuyện hôm nay | Những khoảnh khắc nhỏ nuôi cây lớn | `pop()` về Home (0) hoặc Chat (1) |

> **Dev note điều hướng:** màn này push trên Home shell. Cách đơn giản nhất = `Navigator.pop(context)` trả về 1 enum/int "tab muốn mở", Home đọc kết quả và `setState` đổi tab. Nếu phức tạp, v1 chỉ cần `pop()` về Home là đủ (3 tile đều có lối ở Home). Chốt với Dev: **v1 pop về Home cho cả 3** (không cần đổi tab) — đơn giản, an toàn watcher; đổi-tab là nice-to-have.

Hiển thị động (gợi ý, không bắt buộc v1): nếu streak đang at-risk → đẩy tile "Giữ chuỗi" lên đầu + đổi phụ thành "Chuỗi sắp đứt — trả lời ngay nhé". v1 có thể bỏ qua, để thứ tự cố định.

---

## 6. Danh sách cột mốc

`ContentCard` trắng r24. Tiêu đề "Cột mốc" (16 w800 + `LucideIcons.flag` rose 18). List hàng ngăn hairline (`textTertiary` .12, indent 56).

**Hai trạng thái hàng:**
- **ĐÃ mở (có hoa):** đĩa nhuỵ thu nhỏ (16px, `discFill` theo loại, icon 10 trắng) + label "{N} ngày bên nhau" / "Chuỗi {N} ngày" / "{N} ảnh kỷ niệm" 14 w600 navy + chip phải "✓ đã nở" (12 w700 `success` #66BB6A trên tint .12).
- **KẾ TIẾP (chưa, mờ — chỉ hiện MỐC GẦN NHẤT mỗi loại):** đĩa outline (viền `textTertiary`, icon tertiary) + label 14 w600 `textTertiary` + phải = "còn {N} ngày" / "còn {N} ngày chuỗi" / "còn {N} ảnh" (12 w600 `textSecondary`). Cả hàng opacity .65.

**Quy tắc hiển thị (v1, gọn):**
- Hiện **tất cả mốc đã mở** (đã nở), nhóm theo loại hoặc trộn theo thứ tự đạt — v1 trộn theo loại: Ngày → Streak → Ảnh, trong mỗi loại tăng dần.
- Sau mỗi loại, hiện **1 mốc kế tiếp chưa đạt** của loại đó (mờ + "còn N…"). Nếu loại đó đã đạt mốc cuối (1314 / 365 / 100) → không hiện hàng "kế", thay bằng chip "🌟 đã đủ" optional (v1 có thể ẩn).
- Nếu chưa mở mốc nào (0 hoa): card này hiện 3 hàng "kế tiếp" của 3 loại (mục tiêu đầu tiên: 30 ngày / chuỗi 3 / 1 ảnh) → cho user thấy "đích gần nhất".

"còn N" tính: ngày = `mốc - daysTogether`; streak = `mốc - longestStreak`; ảnh = `mốc - photoCount`. Clamp ≥1 hiển thị (đã đạt thì thành hàng "đã nở").

---

## 7. States

| State | Điều kiện | Render |
|---|---|---|
| **0 hoa (mầm)** | `flowerCount == 0` | Cây S0 (mầm + 2 lá mầm). Stage title "Hạt mầm" + phụ "Hành trình của hai bạn bắt đầu từ đây 🌱". KHÔNG banner. "Cùng vun đắp" hiện đủ 3 tile (lời mời). Cột mốc hiện 3 mốc đầu mỗi loại (mờ). Tông: ấm, mời gọi — KHÔNG empty buồn. |
| **Có hoa mới** | `flowerCount > lastSeen` | Animation nở (§4) + banner "Cây vừa nở X bông mới 🌸". Sau xem → cập nhật lastSeen. |
| **Nở rộ (10+)** | `flowerCount >= 10` | Cây S10+ (tán to nhất + glow rose nhẹ + cánh rơi). Stage title "Nở rộ". Phụ "Cây của hai bạn đang rực rỡ ✨". |
| **Loading** | data provider đang tải lần đầu | Cây vẽ skeleton: thân + tán **xám nhạt** (`surfaceLight`) tĩnh (KHÔNG hoa); 2 `ShimmerSkeleton` pill cho stage title + 1 card. Khi data về → fade sang cây thật 280ms. Tránh nhảy số. |
| **Error đọc data** | provider error (1 trong 3 nguồn fail) | Fail-soft: dùng các nguồn đọc được, nguồn lỗi coi như 0 mốc (không chặn cả màn). Nếu CẢ couple null → state no-couple. |
| **No-couple / waiting** | chưa có couple, hoặc `waiting_partner` (chưa ghép) | Màn vẫn mở được nhưng KHÔNG vẽ vườn hoa. Hiện cây S0 + thông điệp đặc thù: **waiting** → "Cây sẽ lớn khi cả hai cùng có mặt. Mời người ấy tham gia nhé 💌" + 1 nút pill rose "Mời người ấy" → pop về setup/invite. **no-couple** (lỡ vào): "Hãy kết nối với người ấy để bắt đầu trồng cây 🌱". Ẩn "Cùng vun đắp" + "Cột mốc". (StreakChip vốn ẩn khi waiting → thực tế ít khi vào được lúc waiting, nhưng phòng thủ.) |

---

## 8. Token cụ thể (Dev khỏi đoán)

**Màu (AppColors, hex tham chiếu):**
- Nền màn: `dawnBlush` = [#FFC1CC, #E8B4D8, #C8A8E9].
- Thân cây theo stage: #7BA86A → #9B7B5A → #8B6B4A → #7A5A3C → #6E5236 (xem bảng §2). Lá/tán gradient mỗi stage (§2).
- Gò đất: `accentGold #E8B4D8` .55 → `accentLavender #A78BFA`/#C8A8E9 .30.
- Hoa cánh: tâm `dreamyMint hồng #FFD6E0` → mép theo loại (#FF8FA3 / #FFB6C1 / #C8A8E9).
- Nhuỵ đĩa: ngày `accentLove #FF4D6D` · streak gradient #FF8FA3→#E63956 · ảnh `accentLavender #A78BFA`. Icon nhuỵ trắng `#FFFFFF`.
- Banner: fill `accentRose #FF4D6D` .10, viền .30; text `textPrimary #1A1A2E`; icon `accentLoveDeep #E63956`.
- Chip "đã nở": `success #66BB6A` tint .12, chữ #66BB6A.
- Text: title navy #1A1A2E; phụ `textSecondary #6B6B7B`; mờ `textTertiary #A0A0B0`.

**Size / radius / spacing:**
- Khu cây: chiều cao = `(viewportHeight - header - 56).clamp(360, 460)`; rộng full.
- Hoa: đường kính ≈34px (`petalW 13`), nhuỵ đĩa 20px, icon nhuỵ 12. Hoa nhỏ mép tán scale 0.82.
- Nhuỵ list cột mốc: đĩa 16, icon 10.
- `ContentCard`: r24, padding 20, shadow black .06 blur16 off(0,10) (mặc định widget).
- `InkTile`: r22, white .72, splash rose .08. IconBadge 44 r16 tint .12.
- Banner: r16, padding 14×12.
- Nút "Mời người ấy" (waiting): pill r999 h52 fill `accentRose`, chữ trắng 15 w600.
- Spacing dọc body: cây → stage title 16 · title → phụ 4 · phụ → banner 16 · banner → card 20 · card → card 16 · đáy 32. Gutter ngang 16.

**Typography (Quicksand toàn app):** stage title 22 w800 · phụ 14 w500 · section header card 16 w800 · tile title 15 w700 · tile phụ 12 w500 · banner 14 w700 · milestone label 14 w600 · "còn N" 12 w600 · chip "đã nở" 12 w700. Eyebrow chip dùng `pageEyebrowStyle` (11 w700 ls1.4 navy .70) — lo bởi `EyebrowChip`.

**Shadow:** card = chuẩn ContentCard. Nhuỵ hoa = màu loại .30 blur 6. Bóng tán (S6+) = path tối .12 blur 8. Glow S10+ = radial rose .10.

---

## 9. Copy vi + en (key đề xuất + value)

> Thêm vào `app_vi.arb` + `app_en.arb` rồi `flutter gen-l10n`. Tránh ICU `{}` ngoài placeholder. `{count}` là placeholder số (khai báo plural hoặc đơn giản — đề xuất dùng `{count}` int, format thường).

| Key | vi | en |
|---|---|---|
| `loveTreeBadge` | CÂY TÌNH YÊU | LOVE TREE |
| `loveTreeStage0` | Hạt mầm | Tiny seed |
| `loveTreeStage1` | Mầm non | Sprout |
| `loveTreeStage2` | Cây non | Young tree |
| `loveTreeStage3` | Cây xanh | Flourishing tree |
| `loveTreeStage4` | Nở rộ | In full bloom |
| `loveTreeFlowerCount` | `{count} bông hoa đã nở` | `{count} flowers bloomed` |
| `loveTreeFlowerCountZero` | Chưa có bông nào — hãy cùng vun đắp | No flowers yet — let's grow it together |
| `loveTreeSeedSubtitle` | Hành trình của hai bạn bắt đầu từ đây 🌱 | Your journey starts right here 🌱 |
| `loveTreeBloomSubtitle` | Cây của hai bạn đang rực rỡ ✨ | Your tree is in full bloom ✨ |
| `loveTreeNewBloomBanner` | `Cây vừa nở {count} bông mới 🌸` | `Your tree just bloomed {count} new flowers 🌸` |
| `loveTreeNnewBloomBannerOne` | Cây vừa nở một bông mới 🌸 | Your tree just bloomed a new flower 🌸 |
| `loveTreeNurtureTitle` | Cùng vun đắp | Grow it together |
| `loveTreeNurtureStreakTitle` | Giữ chuỗi mỗi ngày | Keep your daily streak |
| `loveTreeNurtureStreakBody` | Trả lời câu hỏi để chuỗi không đứt | Answer daily so your streak lives on |
| `loveTreeNurturePhotoTitle` | Thêm một kỷ niệm | Add a memory |
| `loveTreeNurturePhotoBody` | Mỗi tấm ảnh là một bông hoa mới | Every photo is a new flower |
| `loveTreeNurtureTalkTitle` | Cùng trò chuyện hôm nay | Talk together today |
| `loveTreeNurtureTalkBody` | Những khoảnh khắc nhỏ nuôi cây lớn | Small moments grow the tree |
| `loveTreeMilestonesTitle` | Cột mốc | Milestones |
| `loveTreeMilestoneDays` | `{count} ngày bên nhau` | `{count} days together` |
| `loveTreeMilestoneStreak` | `Chuỗi {count} ngày` | `{count}-day streak` |
| `loveTreeMilestonePhotos` | `{count} ảnh kỷ niệm` | `{count} memories` |
| `loveTreeMilestoneBloomed` | đã nở | bloomed |
| `loveTreeMilestoneDaysLeft` | `còn {count} ngày` | `{count} days to go` |
| `loveTreeMilestoneStreakLeft` | `còn {count} ngày chuỗi` | `{count} streak days to go` |
| `loveTreeMilestonePhotosLeft` | `còn {count} ảnh` | `{count} photos to go` |
| `loveTreeMilestoneAllDone` | đã đủ 🌟 | all done 🌟 |
| `loveTreeWaitingTitle` | Cây đang chờ cả hai | Waiting for both of you |
| `loveTreeWaitingBody` | Cây sẽ lớn khi cả hai cùng có mặt. Mời người ấy tham gia nhé 💌 | The tree grows when you're both here. Invite your partner 💌 |
| `loveTreeWaitingCta` | Mời người ấy | Invite partner |
| `loveTreeNoCoupleBody` | Hãy kết nối với người ấy để bắt đầu trồng cây 🌱 | Connect with your partner to start growing 🌱 |

> Lưu ý copy: xưng "hai bạn"/"cả hai" (KHÔNG "hai đứa" — quy ước voice). Title sentence-case. Stage title vi giữ ngắn.

**StreakChip badge "có hoa chưa xem" (entry point — Dev nối ở `streak_chip.dart`, NHƯNG đó là file Dev sửa, Designer chỉ spec):** khi `flowerCount > lastSeen`, thêm 1 **chấm glow** 8px `accentLoveDeep` neo top-right chip (giống badge số chưa đọc nhưng không số) + (optional) đổi emoji ✨→🌸. Mục đích dụ user vào xem. Copy chip giữ nguyên.

---

## 10. Acceptance criteria (cho Tester)

1. **Vào màn từ StreakChip:** tap StreakChip (Home) → push `LoveTreeScreen`, header `SubScreenHeader` chip "CÂY TÌNH YÊU" + back ← hoạt động (pop về Home).
2. **Số hoa đúng = số mốc đã vượt** qua 3 nguồn (ngày/streak-dài-nhất/ảnh). Đổi data (thêm ảnh, qua mốc ngày) → mở lại thấy số hoa tăng tương ứng. Hoa KHÔNG bao giờ giảm (monotonic) dù currentStreak reset (phải dùng `longestStreak`).
3. **Stage cây đúng ngưỡng:** 0→Hạt mầm, 1–2→Mầm non, 3–5→Cây non, 6–9→Cây xanh, ≥10→Nở rộ. Cây + stage title khớp.
4. **Vị trí hoa ổn định:** rebuild / xoay máy / mở lại → hoa cũ KHÔNG nhảy chỗ (jitter theo index cố định, không random runtime). Hoa không chồng đè khó đọc nhuỵ.
5. **Nhuỵ đúng loại:** hoa từ mốc ngày = đĩa rose + heart; streak = cam-hồng + flame; ảnh = lavender + image. Đối chiếu list cột mốc.
6. **Animation nở hoa:** khi `flowerCount > lastSeen`, mở màn → bông MỚI nở (scale-in cánh + nhuỵ pop + sparkle, stagger), banner "Cây vừa nở X bông mới". Sau đó `lastSeen` cập nhật (mở lại KHÔNG animate, banner mất).
7. **reduceMotion:** bật OS Reduce Motion → KHÔNG scale/sparkle/stagger/glow-thở; hoa (kể cả mới) hiện thẳng; banner vẫn hiện tĩnh; `lastSeen` vẫn cập nhật.
8. **Badge entry:** khi có hoa chưa xem → StreakChip có chấm glow dụ vào; sau khi xem (lastSeen update) → chấm mất.
9. **States biên:** 0 hoa → mầm + lời mời (không buồn, không banner); waiting/no-couple → không vẽ vườn, hiện thông điệp + (waiting) nút "Mời người ấy"; loading → skeleton cây xám + shimmer, không nhảy số; 1 nguồn data lỗi → fail-soft (các nguồn khác vẫn ra hoa).
10. **Cùng vun đắp + Cột mốc:** 3 tile hành động ripple + điều hướng (v1: pop về Home); list cột mốc hiện đúng mốc đã nở (✓) + 1 mốc kế mỗi loại với "còn N…" đúng số; ở mốc cuối loại không hiện "còn N".
11. **Token brand:** nền dawnBlush, card ContentCard trắng r24 shadow chuẩn, không màu `Colors.*` trần ngoài bảng, font Quicksand, cây/hoa 100% vẽ shape (KHÔNG có file ảnh asset cây/hoa trong `assets/`).
12. **i18n:** đủ key vi + en, không hardcode chuỗi; `{count}` plural/format đúng cả 2 ngôn ngữ; không vỡ dấu tiếng Việt.

---

## 11. Assets

- **KHÔNG asset ảnh.** Toàn bộ cây + hoa + gò đất + bokeh dựng bằng `CustomPaint`/path/shape + widget. Icon = Lucide (`flame`/`image`/`flower2`/`sprout`/`chevronRight`/`flag`) + Material `Icons.favorite` (heart filled, quy ước app). Emoji 🌱🌸✨💌🌟 dùng trong text (đã có trên iOS/Android).
- Confetti: package `confetti` đã có (tái dùng controller như `streak_sheet.dart`).
- Hive: 1 key mới `love_tree_seen_<coupleId>` (int) trong box `app_settings` — Dev tự thêm, không cần migration.

---

## 12. Dev notes (tóm tắt thực thi)

- Màn này **push riêng** (không trong shell 4-tab) → tự bọc nền `dawnBlush` + `SafeArea`; `SubScreenHeader` chỉ render chip+back (title/subtitle deprecated, cứ truyền cho compat hoặc bỏ).
- Tách 2 painter: `LoveTreePainter` (thân/tán/lá/gò/bokeh, repaint khi stage đổi) + hoa là **widget overlay** `_LoveFlower` (Positioned theo §3.3) để animate riêng + đặt Lucide icon thật làm nhuỵ. KHÔNG vẽ icon trong painter (khó). Dùng `Stack`: painter nền + các `Positioned(_LoveFlower)`.
- `shouldRepaint`: chỉ true khi stage/size đổi (hoa nằm ngoài painter nên thêm hoa không repaint cây).
- Data: đọc `context.watch` 3 provider (Couple/Streak/Photo). Tính `flowerCount` = đếm mốc vượt. Đặt list mốc là `const` trong màn (không backend). `daysTogether` từ `anniversaryDate` (dùng đúng helper counter sẵn có, date-only).
- `lastSeen`: đọc Hive 1 lần ở initState; so sánh để quyết animate; ghi lại sau khi build xong (postFrame). Tránh ghi trước khi animate (mất hiệu ứng).
- Performance: cap số hoa vẽ hợp lý (mốc tối đa 8+5+5 = 18 hoa) → nhẹ. Sparkle/confetti chỉ chạy cho bông mới.
- Điều hướng "Cùng vun đắp": v1 `Navigator.pop()` về Home (đủ vì 3 lối đều ở Home). Đổi-tab = optional sau.

---

# Design Spec v2 — "Cây sống & kể chuyện" (2026-06-18)

> Bổ sung 3 lớp lên `LoveTreeScreen` v1 (KHÔNG đập đi xây lại). Nguồn chân lý: `overview.md` phần "# v2". Bám Design Unify (light mode, dawnBlush, Iconsax, Quicksand, radius card 24 / pill 999 / sheet top 28). Mọi copy vi+en. **KHÔNG asset art ngoài**, **KHÔNG backend mới** — mọi thứ derive từ 3 provider đã sync (Couple/Streak/Photo) + `LoveTreeService`.
>
> 🔒 **Dev cần GIỮ NGUYÊN (không đổi):** milestone math trong `LoveTreeService` (thresholds, `buildMilestones`, `stageForFlowers`, `flowerCount`, `daysTogether`) · thứ tự `reached` (days→streak→photos ascending, là thứ tự bông trên cây) · layout rải hoa phyllotaxis (`_bloomPositions`) · cơ chế `lastSeen`/bloom-once · `canopyGeometry`. v2 chỉ THÊM tương tác + lớp vẽ + thẻ share.

## v2.0 — Mục lục
- **#1** Bottom sheet "Khoảnh khắc này" (bấm hoa) → §A
- **#2** Cây sống động (lớp trời + mùa + hạt động) → §B
- **#3** Thẻ "Khoe cây" (share card) → §C
- States · Interaction/animation · Localization · Assets · Dev notes · Acceptance → §D–§I

---

## §A — #1 Bottom sheet "Khoảnh khắc này" (bấm hoa)

### A.1 Mục tiêu & trigger
Mỗi bông **đã nở** trở nên bấm được ở **2 chỗ**:
1. Trên cây: `_LoveFlower` (overlay `_TreeHero`) — bọc `InkWell`/`GestureDetector` quanh widget hoa (vùng chạm tối thiểu **44×44** — nếu `diameter` < 44 thì mở rộng hit-test bằng `behavior: HitTestBehavior.opaque` + padding trong suốt, KHÔNG phóng to hoa).
2. Trong card mốc: `_MilestoneRow` (dòng `reached: true`) — bọc bằng `InkTile`/`InkWell` ripple rose .08.

Tap → `HapticFeedback.selectionClick()` → mở `MomentSheet.show(...)` (widget mới `lib/widgets/moment_sheet.dart`). Truyền vào: `kind`, `value`, + (cho `photos`) ảnh đã resolve hoặc null + ngày, + (cho `days`) ngày nở đã tính.

**Bông CHƯA nở** (dòng `_MilestoneRow` `reached:false`): cũng bấm được → mở SHEET LOCKED (cùng widget, nhánh locked). Hoa locked KHÔNG tồn tại trên cây (chỉ bông đã nở mới vẽ) ⇒ chỉ bấm được từ card.

### A.2 Anatomy sheet (đồng nhất với `StreakSheet`/`MemoriesSheet`)
Tái dùng **đúng** khung sheet chuẩn của app:
```
ClipRRect top r28
 └ BackdropFilter blur(20,20)
   └ Container( color: cardSurface #FFFFFF, top r28, padding (20,12,20,28) )
      Column(mainAxisSize.min):
      ── grab handle: 40×4, textTertiary .40, r999, căn giữa
      ── SizedBox 20
      ── [HERO NHUỴ]  đĩa tròn 72×72  (xem A.3)
      ── SizedBox 14
      ── [TITLE]      ý nghĩa mốc — AppTheme.displaySerif(20, w700, textPrimary, ls -0.2), center
      ── SizedBox 4
      ── [DÒNG-NGÀY]  theo kind (xem A.4) — 14 w600 textSecondary, center
      ── (chỉ photos) SizedBox 18 + [THUMBNAIL] (xem A.5)
      ── SizedBox 14
      ── [CÂU COPY ẤM]  13, height 1.5, textSecondary, center  (xem A.7)
      ── (chỉ photos có ảnh) SizedBox 22 + [CTA "Xem trong Thư viện"]  (xem A.6)
      ── (locked) thay khối trên = nhánh locked (xem A.8)
```
- `isScrollControlled: true`, `backgroundColor: Colors.transparent`, bo cạnh dưới ăn `viewInsets.bottom` (giống StreakSheet) — dù sheet này không có input, vẫn pad an toàn.
- Sheet **không cuộn** trong điều kiện thường (nội dung ngắn). Nếu màn rất thấp → bọc nội dung trong `SingleChildScrollView` phòng tràn.

### A.3 Hero nhuỵ (72×72) — màu/icon theo kind
Đĩa tròn lớn, tái dùng token nhuỵ thật từ `LoveTreeService`:
- Kích thước **72×72**, `BoxShape.circle`.
- Nền = `LoveTreeService.nucleusColor(kind).withValues(alpha: 0.12)`.
- `boxShadow`: `nucleusColor(kind) .30, blurRadius 20` (glow mềm — giống `StreakSheet._buildIcon`).
- Icon ở giữa = `LoveTreeService.nucleusIcon(kind)`, **size 34**, màu = `nucleusColor(kind)` (đặc, KHÔNG trắng — vì nền đĩa nhạt; khác nhuỵ-trên-cây dùng icon trắng trên đĩa đặc).
  - `days` → `IconsaxPlusBold.heart`, màu accentLove #FF4D6D.
  - `streak` → `IconsaxPlusLinear.flash`, màu accentLoveDeep #E63956 (giữ flat; gradient sunset2→loveDeep chỉ dùng trên cây — sheet để flat cho rõ).
  - `photos` → `IconsaxPlusLinear.gallery`, màu accentLavender #A78BFA.
- Locked: cùng đĩa nhưng nền `textTertiary .10`, icon `IconsaxPlusLinear.lock` (hoặc `lock_1`) size 30 màu textTertiary #A0A0B0, KHÔNG glow.

### A.4 Title + dòng-ngày theo kind (DỮ LIỆU KHÁC NHAU — đọc kỹ)

**kind = days** (mốc ngày bên nhau, vd value=100):
- Title: l10n `loveTreeMomentDaysTitle(value)` → vi "100 ngày bên nhau" · en "100 days together".
- Dòng-ngày: `loveTreeMomentBloomedOn(date)` → vi "Nở ngày {date}" · en "Bloomed on {date}".
  - `date` = `anniversaryDate + value ngày` (tính: `couple.anniversaryDate.add(Duration(days: value))`), format `DateFormat.yMMMMd(localeString).format(date)` (vi "11 tháng 9, 2024" / en "September 11, 2024"). Luôn quá khứ (chỉ bông đã nở).

**kind = photos** (mốc ảnh, vd value=25):
- Title: `loveTreeMomentPhotosTitle(value)` → vi "Kỷ niệm thứ 25" · en "Memory #25".
- Dòng-ngày: ngày của tấm ảnh thứ `value` nếu resolve được → `loveTreeMomentPhotoTakenOn(date)` → vi "Đăng ngày {date}" · en "Added on {date}" (format yMMMMd theo locale). Nếu KHÔNG resolve được ảnh (xem A.5) → ẩn dòng-ngày, chỉ giữ title + câu copy.

**kind = streak** (mốc kỷ lục chuỗi, vd value=30):
- Title: `loveTreeMomentStreakTitle(value)` → vi "Kỷ lục chuỗi 30 ngày" · en "30-day streak record".
- **KHÔNG có dòng-ngày** (StreakProvider chỉ lưu số `longestStreak`, không lưu ngày đạt). Thay dòng-ngày = 1 dòng khích lệ (gộp vào câu copy A.7).

### A.5 Thumbnail ảnh (CHỈ kind = photos)
Resolve ảnh thứ `value`: list `photoProvider.sortedPhotos` xếp mới→cũ (xem `PhotoProvider.sortedPhotos`). Ảnh "thứ value" tính từ cũ nhất ⇒ index = `sortedPhotos.length - value`.
- **Guard tràn:** `photoCount` đọc server-aggregate (`_totalCount`) ⇒ có thể > số ảnh đã load. Nếu `sortedPhotos.length < value` (index âm) → **KHÔNG có thumbnail** → ẩn cả khối ảnh + ẩn CTA "Xem trong Thư viện" (chỉ còn title + câu copy). KHÔNG crash, KHÔNG dòng-ngày.
- Nếu resolve được `Photo`:
  - Khung: `AspectRatio 4:5` (đồng nhất tỉ lệ ảnh gallery), rộng full content width (≈ màn - 40), `ClipRRect r20`.
  - Nguồn ảnh theo thứ tự (giống `MemoriesSheet._thumb`): `hasRemoteUrl` → `CachedNetworkImage(fit: cover, placeholder = surfaceLight, errorWidget = fallback)`; else `hasLocalPath && File.existsSync` → `Image.file(fit: cover)`; else fallback.
  - Fallback (ảnh hỏng/offline chưa cache): `Container surfaceLight` + `IconsaxPlusBold.gallery` 28 textTertiary giữa khung — vẫn hiện CTA (mở Gallery xem được).
  - Scrim đáy nhẹ (optional): để ngày-trên-ảnh đọc được nếu sau này overlay; v2 ngày nằm Ở TRÊN ảnh (dòng-ngày A.4) nên ảnh không cần text overlay.

### A.6 CTA "Xem trong Thư viện" (CHỈ photos, có thumbnail)
- Nút primary đầy đủ chuẩn app: `SizedBox(height: 52)` + `ElevatedButton` (ăn theme navy pill r999) — giống `MemoriesSheet`. Label `loveTreeMomentViewInGallery` + `IconsaxPlusLinear.arrow_right_3` size 18, cách 8.
- Tap: `HapticFeedback.selectionClick()` → đóng sheet (`maybePop`) → đóng luôn `LoveTreeScreen` (pop về Home) → route sang Gallery qua bridge `NotificationTapRouter` (CÙNG pattern `_NurtureCard._goToAddMemory`):
  - `NotificationTapRouter.pendingHomeTab.value = 2;` (tab Gallery)
  - **Deep-link ảnh nếu khả thi:** nếu resolve được `photo.id`, set `NotificationTapRouter.pendingPhotoId.value = photo.id` (nếu router có field này — Dev xác nhận; map deep-link ảnh đã tồn tại cho `photo_posted`/`photo_reaction`). Nếu không có field → chỉ mở tab Gallery (chấp nhận, AC#2 chỉ yêu cầu "chuyển sang tab Gallery").
  - `Navigator.of(context).maybePop()` (đóng LoveTree) — vì LoveTree push trên Home, pop để Home apply router.
- Locked CTA & các kind khác: xem A.6b / A.8.

### A.6b CTA cho days / streak (KHÔNG có nút mở Gallery)
- `days`: KHÔNG nút (mốc ngày không có đích điều hướng) — sheet kết thúc ở câu copy. (Optional nhẹ: 1 text-link "Xem đồng hồ ngày yêu" nếu muốn, nhưng v2 BỎ cho gọn.)
- `streak`: KHÔNG nút mặc định. (Câu copy đã khích lệ; nếu muốn dẫn về giữ chuỗi thì dùng cùng bridge `pendingHomeFocus='daily_question'` — OPTIONAL, không bắt buộc v2.)

### A.7 Câu copy ấm áp theo kind (1 dòng, 13 / textSecondary / center)
- `days`: `loveTreeMomentDaysCopy` → vi "Mỗi ngày bên nhau là một cánh hoa nở 🌸" · en "Every day together is one more petal in bloom 🌸".
- `photos`: `loveTreeMomentPhotosCopy` → vi "Một khoảnh khắc hai đứa đã cùng lưu giữ 💞" · en "A moment the two of you chose to keep 💞".
- `streak`: `loveTreeMomentStreakCopy` → vi "Kỷ lục các bạn từng cùng nhau giữ. Bắt đầu chuỗi mới để vượt nó nhé 🔥" · en "The record you two once kept together. Start a new streak to beat it 🔥". (Đây cũng đóng vai dòng-thay-cho-ngày của streak.)

### A.8 Nhánh LOCKED (bông chưa nở, bấm từ card)
Dịu dàng, KHÔNG báo lỗi, KHÔNG ép:
- Hero nhuỵ kiểu locked (A.3 — đĩa xám + icon `lock`).
- Title = ý nghĩa mốc CHƯA đạt: dùng cùng title từng kind (vd "100 ngày bên nhau" / "Kỷ niệm thứ 25" / "Kỷ lục chuỗi 30 ngày").
- Dòng dưới = hint còn-bao-nhiêu: `loveTreeMomentLockedHint(n, unit)` — n = `value - progress` clamp ≥1; unit theo kind:
  - days: vi "Còn {n} ngày nữa để nở 🌱" · en "{n} days to go before this blooms 🌱".
  - photos: vi "Còn {n} kỷ niệm nữa để nở 🌱" · en "{n} memories to go before this blooms 🌱".
  - streak: vi "Còn {n} ngày chuỗi nữa để nở 🌱" · en "{n} streak days to go before this blooms 🌱".
  - (3 key riêng: `loveTreeLockedDays/Photos/Streak` — tránh ICU phức tạp.)
- CTA về tab tương ứng (chuẩn primary pill h52, label theo kind):
  - days → KHÔNG CTA (ngày tự trôi) — hoặc text nhẹ "Hãy cứ ở bên nhau 💞" (BỎ nút).
  - photos → CTA "Thêm kỷ niệm" (`loveTreeLockedPhotosCta`) → bridge `pendingHomeTab=2` + `pendingCompose=true` (mở composer Gallery).
  - streak → CTA "Trả lời hôm nay" (`loveTreeLockedStreakCta`) → bridge `pendingHomeTab=0` + `pendingHomeFocus='daily_question'`.
- Sau tap CTA: đóng sheet + pop LoveTree (như A.6).

### A.9 States sheet (tóm)
| Kind / TH | Hero | Title | Dòng giữa | Thumbnail | CTA |
|---|---|---|---|---|---|
| days nở | heart rose glow | "{v} ngày bên nhau" | "Nở ngày {date}" | — | — |
| photos nở + có ảnh | gallery lavender glow | "Kỷ niệm thứ {v}" | "Đăng ngày {date}" | ảnh 4:5 r20 | Xem trong Thư viện |
| photos nở + KHÔNG ảnh (len<v) | gallery lavender glow | "Kỷ niệm thứ {v}" | (ẩn) | (ẩn) | (ẩn) — chỉ câu copy |
| streak nở | flash loveDeep glow | "Kỷ lục chuỗi {v} ngày" | (không ngày) | — | — (câu copy khích lệ) |
| locked days | lock xám | "{v} ngày bên nhau" | "Còn {n} ngày…" | — | — |
| locked photos | lock xám | "Kỷ niệm thứ {v}" | "Còn {n} kỷ niệm…" | — | Thêm kỷ niệm |
| locked streak | lock xám | "Kỷ lục chuỗi {v} ngày" | "Còn {n} ngày chuỗi…" | — | Trả lời hôm nay |

---

## §B — #2 Cây sống động (lớp nền + mùa + hạt động trên LoveTreePainter)

> Thêm các lớp vẽ vào `_TreeHero` (CustomPaint stack). **Thứ tự vẽ từ sau ra trước:** (1) lớp TRỜI nền → (2) sao tĩnh / hạt nền theo khung → (3) cây `LoveTreePainter` (giữ nguyên) → (4) hoa overlay (giữ nguyên) → (5) hạt động (đom đóm/bướm/cánh rơi). Lớp trời + sao = painter mới `SkyBackdropPainter` vẽ DƯỚI cây; hạt động = widget overlay animate riêng (giống hoa) để không repaint cây.

### B.0 Khung "giờ" + "mùa" tính 1 lần khi mở màn
- `final hour = DateTime.now().hour;` → `SkyPhase` ∈ {dawn, day, dusk, night}.
- `final month = DateTime.now().month;` → `Season` ∈ {spring, summer, autumn, winter}.
- Tính ở `_TreeHero` (hoặc state cha) — **KHÔNG** cập nhật realtime mỗi giây (mở màn chốt 1 lần là đủ; tránh tick tốn pin). Truyền `phase`/`season` xuống painter + widget hạt.

### B.1 — Trời theo GIỜ (gradient nền lớp dưới cùng)
Vẽ 1 `Rect.fromLTWH(0,0,w,h)` với `LinearGradient(topCenter→bottomCenter)`. 4 khung, gradient mượt (đây là lớp NỀN trong vùng cây ~360–460px cao, NẰM TRÊN nền dawnBlush của màn — nên cho alpha vừa phải để hoà với blush, KHÔNG đục hẳn).

| Phase | Giờ | Gradient (top → bottom), hex | Ghi chú |
|---|---|---|---|
| **dawn** (bình minh) | 5–9 | `#FFE3C9` (0.55) → `#FFC9D8` (0.45) → trong suốt | hồng-cam nhạt, ấm; alpha thấp để blush lộ |
| **day** (ngày) | 9–16 | `#CFE9FF` (0.40) → `#FFE0EC` (0.30) → trong suốt | xanh trời sáng pha blush; nhẹ nhất |
| **dusk** (hoàng hôn) | 16–19 | `#FF9E7D` (0.55) → `#FF6B9D` (0.42) → `#C8A8E9` (0.30) | sunsetRomance + lavender đáy — đậm & lãng mạn nhất |
| **night** (đêm) | 19–5 | `#2E2A52` (0.78) → `#4A3D6B` (0.62) → `#6B5A8C` (0.40) | tím-navy; ĐÂY là lớp đậm nhất (cần nền tối cho sao/đom đóm nổi) |

- Top-fade: lớp trời chỉ phủ ~70% trên của vùng cây (đỉnh đậm, xuống gò đất nhạt dần về 0) để gò đất + bokeh cũ của painter không bị đè.
- Đêm: vì nền tối, **chữ stage-title/subtitle bên DƯỚI vùng cây vẫn navy trên dawnBlush** (không nằm trong vùng tối) → không cần đổi mực. Chỉ vùng cây tối.

### B.2 — Sao tĩnh + đom đóm (CHỈ phase = night)
**Sao tĩnh** (vẽ trong painter, KHÔNG động — giữ cả khi Reduce Motion):
- Số lượng: **14 sao**, vị trí cố định theo fraction (như bảng bokeh cũ — deterministic, không jitter). Phân bố nửa trên vùng cây (y 0.05–0.45), tránh tâm tán cây.
- Mỗi sao = chấm tròn 1.0–2.2px, màu `#FFFFFF` alpha 0.55–0.90 (sao to alpha cao). Vài sao (3–4) thêm "+" cross 4px alpha .7 cho lấp lánh tĩnh.
- Gợi ý bảng (fraction x, y, r, alpha): `[0.12,0.10,2.0,.85][0.22,0.20,1.2,.55][0.34,0.08,1.6,.7][0.46,0.15,1.0,.5][0.58,0.07,2.2,.9][0.68,0.18,1.4,.65][0.78,0.10,1.8,.8][0.86,0.22,1.1,.55][0.16,0.32,1.3,.6][0.40,0.30,1.0,.5][0.62,0.34,1.5,.7][0.74,0.40,1.2,.55][0.30,0.42,1.4,.6][0.88,0.36,1.0,.5]`.

**Đom đóm** (widget overlay động — TẮT khi Reduce Motion):
- Số lượng: **5 con** (giới hạn pin). Mỗi con = chấm tròn 3px lõi `#FFF6C8` + glow blur (`maskFilter` blur 4) màu `#FFE066` alpha .6.
- Chuyển động: mỗi con bay theo quỹ đạo elip CHẬM (Lissajous nhẹ): biên độ ±(10–18px), chu kỳ **5–8s**, lệch pha per-index. Đồng thời alpha lập loè (breathe) **1.4–2.2s** lệch pha, alpha 0.25↔0.95 (easeInOut).
- Phân bố quanh tán + dưới tán (y 0.15–0.55). Dùng 1 `AnimationController` chung (repeat) + tính vị trí/alpha per-index để rẻ.

### B.3 — Mùa theo THÁNG (lớp lá + accent rơi)
Phân biệt rõ 4 mùa. **KHÔNG đổi `_StageSpec` gốc** (giữ stage math) — chỉ TINT thêm lớp phủ lên tán + thêm/đổi màu hạt rơi:

| Season | Tháng | Khác biệt thị giác | Token |
|---|---|---|---|
| **spring** (xuân) | 2–4 | tán xanh non + **cánh hoa hồng rơi nhẹ** (động) | cánh rơi `#FFD6E0`→`#FF8FA3`; tint tán +5% sáng |
| **summer** (hè) | 5–7 | tán **xanh đậm bão hoà** (lá sum suê) | overlay tán `#3E8E41` alpha .12 (đậm hơn); KHÔNG hạt rơi |
| **autumn** (thu) | 8–10 | **vài lá vàng/cam** xen trong tán + lá vàng rơi | lá vàng `#E8A33D` / `#D9822B`; 3–4 lá rơi |
| **winter** (đông) | 11–1 | tông **mát/xanh-xám**, tán trầm, không hạt | overlay tán `#5A7A8C` alpha .10 (desaturate nhẹ); KHÔNG hạt |

- **Cánh/lá rơi** (spring + autumn) = widget overlay động (TẮT khi Reduce Motion): **4 hạt**, mỗi hạt là teardrop nhỏ (8–12px) rơi từ tán xuống gò, đường rơi đung đưa (sin ngang), chu kỳ **6–10s**, lệch pha, rơi xong loop về đỉnh. Spring = cánh hoa hồng; autumn = lá vàng (xoay nhẹ khi rơi).
- Mùa hè/đông KHÔNG hạt rơi → chỉ tint tán (lớp `Color overlay` vẽ đè canopy với blend, hoặc `_paintTree` đã có sẵn lá — Dev tint bằng cách phủ 1 path canopy mờ màu mùa).
- **Lưu ý:** "cánh rơi mùa xuân" trùng concept với "fallen petals" bloom-stage cũ (`_paintTree` vẽ 4 cánh tĩnh ở gò khi stage=bloom). Giữ cái cũ (tĩnh ở gò); cánh-rơi-mùa là lớp ĐỘNG riêng. Không xung đột.

### B.4 — Vi-động idle (sway hoa/lá)
- **Sway hoa:** mỗi `_LoveFlower` đung đưa rất nhẹ — `Transform.rotate` biên độ **±0.035 rad (~±2°)** quanh gốc dưới hoa, chu kỳ **3.0–4.0s** (easeInOut), **lệch pha theo index** (vd phase = `index * 0.6`). Hoặc dịch ngang ±1.5px. Tinh tế, không lắc loạn.
- Áp cho hoa ĐÃ ổn định (không phải bông đang bloom-in — bông mới chạy animation nở trước, xong mới vào sway). Dùng 1 controller chung `repeat(reverse:true)`, mỗi hoa đọc `controller.value` + offset pha → KHÔNG tạo N controller.
- **Bướm** (tuỳ chọn, gộp vào B.2/B.3 budget): thi thoảng (mỗi ~12–18s) 1 con bướm bay ngang qua tán theo cung bezier 2.5–3.5s rồi biến mất; size 14px, 2 cánh teardrop `#FF8FA3`/`#A78BFA` vỗ nhẹ. Day/dusk dùng bướm; night dùng đom đóm (đã có B.2) — KHÔNG chạy cả hai cùng lúc để tiết kiệm.

### B.5 — Reduce Motion matrix (CHÍNH XÁC — bắt buộc đủ, AC#6)
`final reduceMotion = AppMotion.reduceMotion(context);` (đã có sẵn). Khi `true`:

| Hiệu ứng | Reduce Motion ON |
|---|---|
| Lớp trời (gradient giờ) | **GIỮ** (tĩnh — đẹp, không động) |
| Sao tĩnh (night) | **GIỮ** (vốn đã tĩnh) |
| Đom đóm (vị trí + lập loè) | **TẮT** → vẽ tĩnh: 5 chấm `#FFE066` alpha .7 ở vị trí pha=0 (vẫn thấy "có đom đóm", không động) |
| Bướm | **TẮT hẳn** (không vẽ — không có trạng thái tĩnh ý nghĩa) |
| Cánh/lá rơi (spring/autumn) | **TẮT động** → vẽ 3–4 cánh/lá TĨNH rải ở gò đất (giống fallen-petals cũ) |
| Tint mùa lên tán | **GIỮ** (tĩnh) |
| Sway hoa | **TẮT** → hoa đứng yên (rotate=0) |
| Bloom-in bông mới (đã có v1) | **TẮT** (v1 đã xử lý — bông hiện ngay) |
| Confetti bông mới (đã có v1) | **TẮT** (v1 đã xử lý) |

→ Nguyên tắc: Reduce Motion = bức tranh TĨNH vẫn giàu (trời + sao + tint mùa + cánh tĩnh ở gò), chỉ bỏ chuyển động. KHÔNG được để màn trống trơn.

### B.6 — Ngân sách hiệu năng (pin)
- Tổng hạt động đồng thời ≤ **9** (5 đom đóm HOẶC 4 cánh rơi + 1 bướm thưa) — KHÔNG chạy đom đóm + cánh + bướm cùng lúc. Quy tắc: night → 5 đom đóm; day/dusk + spring/autumn → 4 cánh + bướm thưa; còn lại → chỉ sway.
- 1 `AnimationController` chung cho hạt + 1 cho sway (đọc `.value` per-index). KHÔNG mỗi hạt 1 controller.
- `SkyBackdropPainter.shouldRepaint` = chỉ true khi `phase`/`season` đổi (≈ không bao giờ trong 1 phiên) → trời + sao vẽ 1 lần.
- Hạt động bọc `TickerMode`/check `AppMotion.reduceMotion` — màn này là route push (không trong IndexedStack) nên không cần TickerMode tab, nhưng vẫn dừng khi Reduce Motion.

---

## §C — #3 Thẻ "Khoe cây" (share card)

### C.1 Entry points (2 chỗ)
1. **Header trailing** của `SubScreenHeader` (param `trailing`): nút icon `HeaderIconButton`-style — đĩa/ô vuông bo r16 vùng chạm 44, icon `IconsaxPlusLinear.share` 22 màu `accentLoveDeep` (đè trên dawnBlush sáng → loveDeep ok cho icon ≥20px; nếu cần contrast hơn thì đĩa nền white .72 r16 + icon loveDeep, giống bell Home). LUÔN hiện (kể cả 0 hoa — vẫn khoe được "cây mầm + N ngày").
2. **Trong `_BloomBanner`** (chỉ khi vừa nở hoa mới): thêm 1 hàng dưới text banner = text-button/pill nhỏ "Khoe cây 🌸" — pill fill `accentRose .12`, label `accentLoveDeep` 13 w700, icon `share` 14, r999, padding (12,7). Tap = cùng action header. (Khoảnh khắc nở = lúc muốn khoe nhất → growth loop.)

Tap (cả 2): `HapticFeedback.selectionClick()` → render thẻ off-screen → share. Trong lúc render hiện overlay loading nhẹ (BlockingLoadingOverlay hoặc spinner trên nút) ~vài trăm ms.

### C.2 Kỹ thuật dựng thẻ (off-screen → PNG → share)
- Thẻ là 1 widget `LoveTreeShareCard` (mới) bọc `RepaintBoundary(key: _cardKey)`, render **off-screen** (đặt trong `Offstage`/`Overlay` hoặc render qua `OffscreenCanvas`-style: build widget với `MediaQuery` cố định) ở **logic size 1080×1350** (tỉ lệ 4:5). Pattern: `RepaintBoundary.toImage(pixelRatio: 1080/cardLogicalWidth)` → `ui.Image` → `toByteData(png)` → ghi file temp (`path_provider` `getTemporaryDirectory()/love_tree_<ts>.png`) → `XFile` → `SharePlus.instance.share(ShareParams(files:[xfile], text: <l10n>, sharePositionOrigin: origin))`.
- `sharePositionOrigin` từ render box của nút bấm (iPad popover — bắt buộc, xem `invite_action_buttons.dart:56`).
- Thẻ **tự chứa** — KHÔNG phụ thuộc layout màn (tự build cây + nền + text với kích thước cố định).

### C.3 Layout thẻ 4:5 (1080×1350 logic — mô tả theo tỉ lệ, Dev scale)
```
┌────────────────────────────────────┐ 1080×1350, nền gradient (C.4)
│            (padding top ~10%)        │
│        ✦  Dear Embeiu  (eyebrow)     │ ~y8%: chip/eyebrow nhỏ trên cùng (optional, mờ)
│                                      │
│            ╭─────────╮               │
│            │  CÂY     │  vùng cây     │ y18–62%: cây (stage + số hoa hiện tại)
│            │ (stage+  │  ~52% chiều   │   vẽ bằng CHÍNH LoveTreePainter + hoa overlay
│            │  hoa)    │  cao thẻ      │   (tái dùng — KHÔNG vẽ lại)
│            ╰─────────╯               │
│                                      │
│         An ♥ Bình   (tên cặp)        │ y70%: AnimatedCoupleName TĨNH (pulseHeart:false)
│                                      │       28→ scale: ~36px trên thẻ, w800 trắng
│      365 ngày bên nhau · 7 bông hoa  │ y78%: dòng số — 22px w600 trắng .92
│                                      │
│   "Cây tình yêu của chúng mình"      │ y86%: tagline — 18px w500 italic trắng .85
│                                      │
│              Dear Embeiu             │ y95%: watermark mờ — 14 w700 ls2 trắng .55
└────────────────────────────────────┘
```
Chi tiết (đơn vị = px trên thẻ 1080 rộng; Dev quy đổi từ logic width):
- **Margin ngang:** 96px (≈9%).
- **Eyebrow trên (optional):** "✦ DEAR EMBEIU" hoặc bỏ — ưu tiên BỎ ở trên, chỉ giữ watermark đáy (tránh lặp). Nếu giữ: 24px w700 ls3 trắng .5.
- **Vùng cây:** chiếm y 16%→62% (≈620px cao), căn giữa ngang. Dùng `LoveTreePainter(stage: stage)` + overlay hoa (`_bloomPositions` cùng thuật toán) — số hoa = `flowerCount` hiện tại, stage = `stageForFlowers`. KHÔNG animation (thẻ tĩnh). Có thể thêm glow tán nhẹ.
- **Tên cặp:** `AnimatedCoupleName(name1, name2, pulseHeart: false)` (tĩnh) — render ở ~36px w800, màu trắng + bóng tối black .28 blur 10 (chữ trắng trên gradient — luật shadow brand). Tim ở giữa `accentLove`/trắng.
- **Dòng số:** `loveTreeShareStats(days, flowers)` → vi "{days} ngày bên nhau · {flowers} bông hoa" · en "{days} days together · {flowers} flowers in bloom". 22px w600 trắng .92, center, format số theo locale (`NumberFormat.decimalPattern`).
- **Tagline:** `loveTreeShareTagline` → vi "Cây tình yêu của chúng mình 🌳" · en "The tree we grew together 🌳". 18px w500, trắng .85, center. (Italic optional — Quicksand không có italic dựng sẵn; dùng w500 thường.)
- **Watermark:** "Dear Embeiu" 14px w700 ls2, trắng .55, center, sát đáy (y ~95%). Đây là kênh acquisition — luôn có.
- **Spacing dọc:** dùng tỉ lệ % ở sơ đồ; giữa các block ≥ 32px.

### C.4 Nền + màu thẻ
- **Nền gradient:** `sunsetRomance` (#FF6B9D→#FF8FA3→#FFB6C1), hướng topLeft→bottomRight — đây là gradient HERO brand, hợp "khoe". (Thay vì dawnBlush — thẻ cần đậm/nổi bật trên feed mạng xã hội.)
- Phủ thêm: vài bokeh trắng mờ (như painter cũ) + glow tán quanh cây để chiều sâu. Optional: 1 lớp `RadialGradient` trắng .12 sau cây.
- **Toàn bộ chữ = TRẮNG** (đủ alpha như trên) + bóng tối mềm (black .25–.30 blur 8–10) cho chữ chính — KHÔNG halo trắng (luật brand).
- KHÔNG dùng ảnh couple làm nền thẻ (privacy + đơn giản; cây là nhân vật chính). Backlog nếu user muốn sau.

### C.5 Text đi kèm khi share (caption OS)
- `loveTreeShareMessage` → vi "Cây tình yêu của chúng mình đã nở {flowers} bông hoa sau {days} ngày 🌳💞 — vun cây cùng người ấy trên Dear Embeiu." · en "Our love tree has bloomed {flowers} flowers after {days} days 🌳💞 — grow yours together on Dear Embeiu."
- (Không kèm link store v2 — giữ đơn giản; có thể thêm sau khi có universal link.)

### C.6 States thẻ
- **0 hoa (hạt mầm):** thẻ vẫn dựng — cây stage seed, dòng số "{days} ngày bên nhau · 0 bông hoa", tagline "Cây vừa gieo mầm 🌱" (`loveTreeShareTaglineSeed`). Vẫn khoe được (mới yêu, khoe mầm cũng dễ thương).
- **Render lỗi / share lỗi:** im lặng (no error toast) như `invite_action_buttons._handleShare`; nếu render `ui.Image` fail → log + bỏ qua (không crash). Optional snackbar `loveTreeShareFailed` (vi "Không tạo được thẻ, thử lại nhé" / en "Couldn't create the card, please try again") — nhẹ, không chặn.
- **No-couple / waiting:** ẩn nút "Khoe cây" (không có dữ liệu cặp đôi/ngày) — header trailing = null trong 2 state này.

---

## §D — Interaction / animation tổng hợp (v2)
| Tương tác | Duration / Curve | Ghi chú |
|---|---|---|
| Mở MomentSheet | sheet trượt lên mặc định Material (~250ms) | `showModalBottomSheet` chuẩn |
| Tap hoa/row → haptic | — | `selectionClick` |
| Đom đóm Lissajous | 5–8s/chu kỳ, easeInOut, lệch pha | TẮT khi reduceMotion |
| Đom đóm lập loè | 1.4–2.2s, easeInOut | TẮT khi reduceMotion |
| Cánh/lá rơi | 6–10s loop, lệch pha | TẮT khi reduceMotion (→ tĩnh ở gò) |
| Sway hoa | 3–4s easeInOut, ±2° | TẮT khi reduceMotion |
| Bướm bay ngang | mỗi 12–18s, 2.5–3.5s/lượt bezier | TẮT khi reduceMotion; không cùng lúc đom đóm |
| Render thẻ share | vài trăm ms (off-screen) | spinner/overlay trong lúc render |

## §E — Localization (vi + en) — key MỚI v2
Sửa CẢ `app_en.arb` + `app_vi.arb` → `fvm flutter gen-l10n`. Tránh ICU `{}` ngoài placeholder.

| Key | vi | en |
|---|---|---|
| `loveTreeMomentDaysTitle(v)` | "{v} ngày bên nhau" | "{v} days together" |
| `loveTreeMomentPhotosTitle(v)` | "Kỷ niệm thứ {v}" | "Memory #{v}" |
| `loveTreeMomentStreakTitle(v)` | "Kỷ lục chuỗi {v} ngày" | "{v}-day streak record" |
| `loveTreeMomentBloomedOn(date)` | "Nở ngày {date}" | "Bloomed on {date}" |
| `loveTreeMomentPhotoTakenOn(date)` | "Đăng ngày {date}" | "Added on {date}" |
| `loveTreeMomentDaysCopy` | "Mỗi ngày bên nhau là một cánh hoa nở 🌸" | "Every day together is one more petal in bloom 🌸" |
| `loveTreeMomentPhotosCopy` | "Một khoảnh khắc hai đứa đã cùng lưu giữ 💞" | "A moment the two of you chose to keep 💞" |
| `loveTreeMomentStreakCopy` | "Kỷ lục các bạn từng cùng nhau giữ. Bắt đầu chuỗi mới để vượt nó nhé 🔥" | "The record you two once kept together. Start a new streak to beat it 🔥" |
| `loveTreeMomentViewInGallery` | "Xem trong Thư viện" | "View in Gallery" |
| `loveTreeLockedDays(n)` | "Còn {n} ngày nữa để nở 🌱" | "{n} days to go before this blooms 🌱" |
| `loveTreeLockedPhotos(n)` | "Còn {n} kỷ niệm nữa để nở 🌱" | "{n} memories to go before this blooms 🌱" |
| `loveTreeLockedStreak(n)` | "Còn {n} ngày chuỗi nữa để nở 🌱" | "{n} streak days to go before this blooms 🌱" |
| `loveTreeLockedPhotosCta` | "Thêm kỷ niệm" | "Add a memory" |
| `loveTreeLockedStreakCta` | "Trả lời hôm nay" | "Answer today" |
| `loveTreeShareButton` | "Khoe cây" | "Share our tree" |
| `loveTreeShareStats(days, flowers)` | "{days} ngày bên nhau · {flowers} bông hoa" | "{days} days together · {flowers} flowers in bloom" |
| `loveTreeShareTagline` | "Cây tình yêu của chúng mình 🌳" | "The tree we grew together 🌳" |
| `loveTreeShareTaglineSeed` | "Cây vừa gieo mầm 🌱" | "Our tree just sprouted 🌱" |
| `loveTreeShareMessage(flowers, days)` | "Cây tình yêu của chúng mình đã nở {flowers} bông hoa sau {days} ngày 🌳💞 — vun cây cùng người ấy trên Dear Embeiu." | "Our love tree has bloomed {flowers} flowers after {days} days 🌳💞 — grow yours together on Dear Embeiu." |
| `loveTreeShareFailed` (optional) | "Không tạo được thẻ, thử lại nhé" | "Couldn't create the card, please try again" |

> Số nhiều: dùng dạng đơn giản (không ICU plural) để khớp convention app + tránh `{}` lỗi gen. "{v} days" chấp nhận "1 days" theo style hiện hành của app (các key cũ `loveTreeMilestoneDays` cũng vậy).

## §F — Assets
- **KHÔNG asset art mới.** Cây/hoa/trời/sao/đom đóm/cánh rơi/bướm/thẻ = 100% `CustomPaint` + shape + widget compose.
- Icon: Iconsax (`IconsaxPlusBold.heart` / `IconsaxPlusLinear.flash` / `gallery` / `lock` / `share` / `arrow_right_3`). Emoji 🌸💞🔥🌱🌳🌟 trong text (đã hỗ trợ iOS/Android).
- Package đã có: `confetti` (v1), `share_plus` ^11 (invite), `path_provider`, `cached_network_image`, `intl`. KHÔNG thêm dependency.
- Hive: KHÔNG key mới (chỉ tái dùng `love_tree_seen_<coupleId>` của v1).

## §G — Dev cần GIỮ LOGIC (nhắc lại — quan trọng)
1. **KHÔNG đổi milestone math** (`LoveTreeService` thresholds/buildMilestones/stageForFlowers/daysTogether) — sheet + thẻ đọc ra, không tính lại khác.
2. **Thứ tự `reached`** (days→streak→photos ascending) = thứ tự bông; sheet phải map đúng `kind`+`value` của bông được bấm.
3. **Deep-link Gallery** dùng bridge `NotificationTapRouter` (`pendingHomeTab=2`, `pendingCompose`, `pendingPhotoId` nếu có) + `Navigator.maybePop()` — KHÔNG `pushNamed('/home')` thẳng (vỡ watcher, xem CLAUDE.md §2).
4. **Photo resolve guard:** `sortedPhotos.length < value` → ẩn thumbnail/CTA, KHÔNG crash (server-aggregate `photoCount` có thể > ảnh đã load).
5. **Reduce Motion** (`AppMotion.reduceMotion`) — vá đủ theo bảng B.5; v1 đã vá bloom/confetti, v2 thêm sky/sao(giữ tĩnh)/đom đóm/cánh/sway/bướm.
6. **`shouldRepaint`** cây + trời chỉ true khi stage/phase/season/size đổi → không repaint khi thêm hoa/hạt động.
7. **Thẻ share** render off-screen, tự chứa size 1080×1350; `sharePositionOrigin` cho iPad; lỗi im lặng.

## §H — States toàn màn (v2 bổ sung lên v1)
- **0 hoa:** cây mầm + trời/mùa vẫn vẽ; nút "Khoe cây" vẫn hiện (thẻ stage seed). Không có bông để bấm.
- **Có hoa, không bông mới:** sway idle + hạt động theo giờ/mùa; bấm bông → sheet.
- **Bông mới (hasNewBlooms):** v1 bloom + confetti chạy TRƯỚC, xong mới vào sway; banner có nút "Khoe cây 🌸".
- **Loading streak (skeleton v1):** giữ nguyên — chưa vẽ lớp sống động cho tới khi có data (tránh nhấp nháy). Nút share ẩn lúc loading.
- **No-couple / waiting:** giữ `_StateMessage` v1; ẩn nút "Khoe cây" (trailing=null); KHÔNG lớp sống động (chỉ seed tĩnh).
- **Reduce Motion ON:** bức tranh tĩnh giàu (trời + sao + tint mùa + cánh tĩnh ở gò), 0 chuyển động; sheet/thẻ hoạt động bình thường.

## §I — Acceptance criteria (v2 — khớp PO + bổ sung design)
1. Bấm 1 bông đã nở (trên cây HOẶC trong card) → `MomentSheet` hiện đúng ý nghĩa + đúng dòng-ngày theo kind (days="Nở ngày…", photos="Đăng ngày…"+thumbnail, streak=không-ngày+khích lệ).
2. photos có ảnh → thumbnail 4:5 r20 + CTA "Xem trong Thư viện" → đóng sheet + sang tab Gallery (deep-link ảnh nếu router hỗ trợ). photos thiếu ảnh (len<value) → ẩn thumbnail+CTA, chỉ title+copy, KHÔNG crash.
3. Bấm bông chưa nở (card) → sheet locked: hero lock + "Còn {n}…" + CTA về tab tương ứng (photos→composer, streak→daily question), KHÔNG lỗi.
4. Nền trời đổi theo 4 khung giờ (đổi giờ máy test); đêm có sao tĩnh + đom đóm lập loè.
5. Lá/mùa phân biệt được 4 mùa (đổi tháng máy test); xuân/thu có cánh/lá rơi.
6. Reduce Motion ON → 0 chuyển động (đom đóm/cánh/sway/bướm tắt → tĩnh), trời+sao+tint+cánh-gò vẫn đẹp.
7. "Khoe cây" (header + banner) → share sheet OS với 1 PNG 4:5 đẹp: cây(stage+hoa) + tên cặp + "{days} ngày · {flowers} bông" + tagline + watermark "Dear Embeiu".
8. Sheet/sao/đom đóm/thẻ dùng token brand (cardSurface, nucleusColor, sunsetRomance, Quicksand, r28 sheet/r20 thumb/r999 pill); InkWell ripple ở mọi phần tử bấm.
9. `fvm flutter analyze` sạch; i18n đủ vi+en (sửa CẢ 2 ARB → gen-l10n).
10. Hiệu năng: ≤9 hạt động cùng lúc, 1–2 controller chung, painter không repaint khi thêm hoa.

## §J — Câu hỏi cho PO/Dev (nếu vướng)
- **Deep-link ảnh cụ thể:** `NotificationTapRouter` đã có field `pendingPhotoId` (dùng cho `photo_posted`/`photo_reaction`) chưa, hay chỉ `pendingHomeTab`? Nếu CHƯA có field cho ảnh từ ngoài luồng push → CTA "Xem trong Thư viện" chỉ mở tab Gallery (vẫn đạt AC#2). Dev xác nhận để chốt mức deep-link.
- (Còn lại đã đủ trong PO spec; không có blocker.)

---

# Design Spec v2.1 — Vẽ lại cây/hoa đẹp hơn + coach mark bấm hoa (2026-06-18)

> Bổ sung lên v1/v2 (KHÔNG đập). Nguồn chân lý: `overview.md` §"# v2.1". Hai khối: **(A)** nâng cấp render cây + hoa (vẫn 100% CustomPaint, KHÔNG asset/dependency mới) + tách ranh giới render để v3 drop asset; **(B)** coach mark 1-lần + caption thường trực hướng dẫn bấm hoa.
>
> 🔒 **Dev GIỮ NGUYÊN tuyệt đối (v2.1 chỉ đổi *cách vẽ*, KHÔNG đổi *vẽ ở đâu / bao nhiêu*):**
> - **Milestone math** (`LoveTreeService`: thresholds, `buildMilestones`, `stageForFlowers`, `flowerCount`, `daysTogether`, `nucleusIcon/nucleusColor/petalEdge`) — KHÔNG đụng.
> - **`canopyGeometry(stage, size)`** (tâm tán + bán kính) và **`bloomPositions()`** (golden-angle + `_bloomHash` jitter, `capacity=14`, flatten 0.7) — KHÔNG đổi công thức ⇒ hoa cũ KHÔNG nhảy chỗ. Nếu chi tiết vẽ tán mới làm "mép tán" hơi khác, vẫn neo theo `canopyGeometry` cũ (xem A.1.4).
> - **Stage thresholds** + `_StageSpec.trunkHeight/canopyR/branchDirs/bumps count` — GIỮ (chỉ làm đẹp đường nét + lớp lá + bóng, KHÔNG đổi kích thước khung kẻo lệch `bloomPositions`).
> - **Lớp trời theo giờ (`SkyBackdropPainter`)** + **mùa (`_paintSeasonTint`, `_AmbientParticles`)** từ v2 — GIỮ. v2.1 chỉ nâng cấp cây/hoa nằm GIỮA 2 lớp đó.
> - **Bấm hoa → `MomentSheet`** (#1), **thẻ "Khoe cây"** (#3), **bloom animation + confetti + `lastSeen`/bloom-once**, **Reduce-Motion matrix v2 §B.5** — GIỮ.

## v2.1 — Mục lục
- **A.0** Triết lý nâng cấp (vì sao đẹp hơn mà không phá layout)
- **A.1** Cây từng stage — thân/cành bézier thuôn + tán đa lớp + bóng
- **A.2** Hoa — cánh đa lớp + nhuỵ disc nâng cấp
- **A.3** Tách layer render (`TreeRenderer` strategy cho v3)
- **B.1** Coach mark 1-lần (ripple + tooltip)
- **B.2** Caption thường trực dưới cây
- **C** Token tổng hợp · **D** States · **E** Localization · **F** Acceptance · **G** Dev notes / giữ-logic

---

## A.0 — Triết lý nâng cấp (giữ ngôn ngữ minimalism, chỉ "tinh tế hơn")

Mục tiêu **KHÔNG** phải vẽ cây tả-thực (bonsai). Vẫn là "tán mây mềm" của brand, nhưng:
1. **Thân/cành có nhịp cong tự nhiên** (bézier 2 đoạn, độ dày thuôn dần từ gốc → ngọn) thay vì hình thang quadratic phẳng hiện tại.
2. **Tán nhiều lớp** (back → mid → front, 3 sắc xanh) cho chiều sâu, thay vì 1 blob 1 gradient.
3. **Bóng đổ mềm hơn + highlight ánh sáng trên-trái** → khối tròn trịa.
4. **Hoa = ngôi sao**: 6 cánh 2 lớp (lớp sau xoay 30° + đậm hơn) + nhuỵ disc có viền sáng + bóng trong (inner shadow giả) → bông "căng" và đọc rõ icon nhuỵ.

Nguyên tắc bất di: **mọi nâng cấp neo theo `canopyGeometry`/`_StageSpec` cũ** để `bloomPositions` (vị trí hoa) không đổi. "Đẹp hơn" = thêm lớp + đường nét, KHÔNG phóng to/thu nhỏ khung cây.

---

## A.1 — Cây từng stage (nâng cấp `LoveTreePainter`)

### A.1.1 Thân + cành — bézier cong, độ dày thuôn dần
Hiện `_paintTree` vẽ thân bằng 1 path quadratic đối xứng (rộng `trunkBase` → `trunkTop`). Nâng cấp:

- **Thân = "ruy-băng" 2 mép cong lệch pha nhẹ** (không đối xứng cứng) → nhịp tự nhiên. Mỗi mép = **cubic bézier** từ `base ± trunkBase` lên `trunkTop ± trunkTop`, với 2 control point tạo độ ưỡn nhẹ:
  - Mép trái: control1 `(base.dx - trunkBase*0.55, base.dy - H*tH*0.35)`, control2 `(base.dx - trunkTop*1.4, base.dy - H*tH*0.72)`.
  - Mép phải đối xứng nhưng **control2 đẩy ngang +1.5px** (lệch pha → thân hơi nghiêng sống động, không robot).
  - `H = canvasHeight`, `tH = spec.trunkHeight` (GIỮ nguyên giá trị).
- **Độ dày thuôn:** bề rộng thân giảm tuyến tính theo chiều cao (gốc `trunkBase*2` → ngọn `trunkTop*2`) — đã có sẵn qua `trunkBase/trunkTop`, chỉ làm mép cong hơn.
- **Gradient thân (mới, thay fill phẳng):** `LinearGradient` ngang (trái→phải) = `lighten(trunkColor, 0.06)` → `trunkColor` → `darken(trunkColor, 0.10)` (sáng mép trái, tối mép phải) ⇒ thân tròn khối. Dùng helper `_darken` đã có + thêm `_lighten` đối xứng.
- **Vân thân (stage young+):** 1–2 đường cong mảnh `darken(trunkColor,0.12)` alpha .35 strokeWidth 1, chạy dọc thân (cong theo thân) — gợi vỏ cây. Bỏ ở seed/sprout (thân mảnh).
- **Cành (`branchDirs`):** GIỮ số cành + hướng. Nâng cấp: stroke gradient cùng tông thân + **độ dày thuôn** (vẽ cành = path FILL hình thoi dài thay vì stroke đều — gốc cành `branchWidth`, đầu cành `branchWidth*0.4`). Đầu cành bo tròn (`StrokeCap.round` nếu vẫn stroke, hoặc path khép). Cong tự nhiên hơn bằng cubic (thêm 1 control để cành võng nhẹ xuống rồi vểnh lên).

### A.1.2 Tán lá đa lớp (back / mid / front)
Thay 1 blob 1 gradient bằng **3 blob chồng** dùng CÙNG `_blobPath(center, radius, bumps)` (giữ thuật toán) nhưng lệch tâm + lệch bán kính + sắc độ khác → chiều sâu:

| Lớp | Tâm (lệch từ `canopyCenter`) | Bán kính | Fill | Ghi chú |
|---|---|---|---|---|
| **Back** (xa, tối) | `(+R*0.10, +R*0.06)` | `R*1.02` | đặc `darken(canopyDark, 0.10)` alpha .92, **blur 4** (MaskFilter) | viền mềm, làm nền sâu |
| **Mid** (chính) | `canopyCenter` | `R*0.96` | `LinearGradient` dọc `canopyLight → canopyDark` (GIỮ như hiện tại) | lớp đọc chính, hoa nằm trên đây |
| **Front** (highlight) | `(-R*0.12, -R*0.10)` | `R*0.64` | `RadialGradient` `lighten(canopyLight,0.10) .55 → transparent` | đốm sáng trên-trái = nguồn sáng, cho khối |

- **`bumps` mỗi lớp:** mid + back dùng `spec.bumps` (GIỮ — quyết định hình tán). Front dùng `spec.bumps` đảo nhẹ (hoặc cùng) — không quan trọng vì chỉ là highlight mờ. **KHÔNG đổi `spec.bumps` của mid** (đó là "chữ ký hình tán" + ảnh hưởng cảm giác mép, dù `bloomPositions` neo theo `canopyR` chứ không theo bump).
- **Bóng đổ tán (`hasShadow` stage green+):** GIỮ path bóng cũ (`_blobPath(center+(−6,+8))`) nhưng đổi alpha .12 → **.10** + blur 8 → **10** (mềm hơn). Vẽ DƯỚI cả 3 lớp tán.
- **Lá viền:** GIỮ `leafCount` + vòng phân bố. Nâng cấp từng lá: gradient lá hiện `[canopyDark, darken]` → đổi thành **3 stop** `[lighten(canopyDark,0.06), canopyDark, darken(canopyDark,0.10)]` (lá có khối) + gân lá GIỮ. Lá vẽ TRÊN lớp mid, DƯỚI hoa. Autumn golden-leaf logic GIỮ.

### A.1.3 Seed / Sprout nâng cấp (stage nhỏ vẫn phải đẹp)
- **Seed (S0):** thân mầm GIỮ S-cong. Nâng: 2 lá mầm hiện là 2 oval `_paintLeaf` đối xứng cứng → đổi **góc ±32°** + thêm 1 **giọt sương** (chấm trắng .7 đường kính 2.5px) trên 1 lá + gradient lá 3-stop như A.1.2. Gốc mầm thêm **bóng nhỏ ellipse** `darken .10` alpha .10 blur 4 ngay dưới điểm chạm gò (mầm "đứng" có gốc).
- **Sprout (S1–2):** tán blob nhỏ → áp công thức 3 lớp A.1.2 (back+mid+front) ở quy mô nhỏ. Vẫn 1 blob mid + 1 highlight front (bỏ back nếu `canopyR<70` cho nhẹ). Thân thuôn + gradient ngang.

### A.1.4 Ràng buộc neo hoa (QUAN TRỌNG — không lệch `bloomPositions`)
- `bloomPositions` gọi `canopyGeometry(stage, size)` → trả `(center, canopyR)`. **GIỮ y nguyên hàm này.** Tán mới (back/mid/front) phải có **lớp mid trùng `canopyCenter` + `canopyR`** như cũ (hoa rải trên 0.78·canopyR — đã đúng). Back/front chỉ trang trí, KHÔNG dùng để neo hoa.
- ⇒ Hoa cũ giữ chính xác vị trí; bài test "xoay máy / rebuild hoa không nhảy" (AC v1 #4) vẫn đạt.

---

## A.2 — Hoa nâng cấp (`_FlowerPetalsPainter` + `_Nucleus`)

### A.2.1 Cánh hoa — 6 cánh, 2 lớp
Hiện: 5 cánh teardrop, 1 lớp, radial gradient `#FFD6E0 → petalEdge`. Nâng cấp:

- **Số cánh: 6** (chẵn, đối xứng đẹp hơn; vòng 60°). (Nếu Dev muốn giữ 5 cho khác biệt hữu cơ cũng chấp nhận — **đề xuất 6**.)
- **2 lớp cánh:**
  - **Lớp sau (under-petals):** 6 cánh, **xoay lệch +30°** so lớp trước (chèn giữa khe), scale **0.86**, fill đậm hơn = `petalEdge` đặc alpha .85 (không gradient) → tạo cảm giác cánh xếp lớp.
  - **Lớp trước (top-petals):** 6 cánh chính, `RadialGradient` **3 stop** từ tâm: `#FFF0F4 (0.0) → #FFD6E0 (0.45) → petalEdge (1.0)` — tâm sáng hơn (gần trắng-hồng) cho cánh "căng sáng".
- **Hình cánh:** giữ teardrop quadratic nhưng **bầu hơn ở giữa** (đẩy control point `petalW` rộng ra `petalW*1.08`) + **đầu cánh hơi nhọn cong** (thêm 1 điểm uốn nhẹ ở đỉnh thay vì nhọn cứng). Mép cánh: viền trắng .35 1px (GIỮ) → đổi **gradient stroke** trắng .40 ở gốc → trắng .12 ở đỉnh (viền mờ dần, tinh tế hơn).
- **Bóng dưới hoa (lên tán):** trước khi vẽ cánh, vẽ 1 ellipse `darken(petalEdge,0.15)` alpha .10 blur 3 ngay dưới tâm bông (offset +0,+2) → hoa "nổi" trên tán. (Nhẹ — không bật khi diameter<30.)

### A.2.2 Nhuỵ disc — nâng cấp (`_Nucleus`)
Hiện: disc tròn fill màu loại (streak = gradient chéo) + viền trắng .60 + boxShadow màu .30 blur 6 + icon trắng. Nâng cấp:

- **Nền disc:** thêm **highlight gradient bên trong** — `RadialGradient(center: Alignment(-0.3,-0.3), radius 1.0)` từ `lighten(nucleusColor,0.14) → nucleusColor → darken(nucleusColor,0.10)` (đĩa tròn khối, có "đỉnh sáng" trên-trái). Streak GIỮ gradient chéo nhưng cũng thêm lighten ở đầu.
- **Viền:** 2 lớp — viền trắng ngoài .65 1.4px (GIỮ, hơi dày hơn) + **vòng sáng trong** (inner ring) trắng .30 0.8px ngay sát mép trong → cảm giác men sứ.
- **Bóng:** GIỮ boxShadow màu loại .30 blur 6 + thêm **offset (0, 1.5)** (bóng đổ xuống nhẹ) → disc nổi khỏi cánh.
- **Icon nhuỵ:** GIỮ `nucleusIcon(kind)` trắng size `diameter*0.6`. Thêm **shadow icon** mảnh `nucleusColor darken .2` alpha .35 blur 1.5 (icon "in chìm", tách khỏi nền sáng).
- **Kích thước:** GIỮ `nucleusD = diameter*0.59` (≈20px / hoa 34px). KHÔNG đổi (animation pop nhuỵ v1 dựa vào tỉ lệ này).

### A.2.3 Token kích thước hoa (GIỮ, ghi lại để rõ)
- Đường kính hoa base **34px**, hoa mép tán scale **0.82** (`_flowerDiameter` — GIỮ).
- Hit-target ≥44 (`_flowerHitPad` — GIỮ).
- Petal len/width tính theo `size` trong painter (GIỮ tỉ lệ; chỉ đổi gradient + lớp + độ bầu).

---

## A.3 — Tách layer render (chuẩn bị v3 drop SVG/Lottie)

> User muốn v3 thay phần vẽ cây/hoa bằng asset mà KHÔNG đập logic mốc/stage/tap. Designer đề xuất ranh giới (Dev hiện thực; đây là **thiết kế kiến trúc**, không phải code).

**Nguyên tắc:** tách phần *"vẽ trông thế nào"* khỏi phần *"vẽ cái gì, ở đâu, bao nhiêu"*.

- **Phần GIỮ ở screen/service (KHÔNG thuộc renderer):** milestone math, `stage`, danh sách `reached` (kind+value+index), `bloomPositions`, `canopyGeometry`, tap → `MomentSheet`, `lastSeen`, share data.
- **Phần TÁCH thành "TreeRenderer" (cái có thể thay bằng asset ở v3):**
  - `TreeRenderer.paintTree(canvas, size, stage, season, {skeleton})` — vẽ thân/cành/tán/lá/gò (hiện = `LoveTreePainter`). v3 = renderer khác đọc SVG theo stage.
  - `TreeRenderer.flowerWidget(kind, diameter, ...)` — dựng 1 bông (hiện = `_LoveFlower` + `_FlowerPetalsPainter` + `_Nucleus`). v3 = `SvgPicture`/`Lottie` theo kind.
  - **Hợp đồng (contract) renderer phải tôn trọng:**
    1. `paintTree` nhận `canopyGeometry(stage,size)` làm SỰ THẬT về tâm+bán kính tán (renderer asset phải canh tán khớp tâm/bán kính này, vì screen rải hoa theo đó).
    2. `flowerWidget` vẽ trong hộp `diameter×diameter`, **tâm bông ở giữa hộp**, nhuỵ ở tâm (để hit-pad + animation pop của screen vẫn đúng).
    3. Renderer KHÔNG đọc provider, KHÔNG tự tính mốc — chỉ nhận `stage/kind/diameter/season` + cờ motion.
- **Cách thực thi gợi ý (v2.1, vẫn CustomPaint):** gom các painter cây/hoa hiện tại sau 1 lớp mỏng `LoveTreeRenderer` (abstract hoặc 1 class `PaintTreeRenderer implements LoveTreeRenderer`), screen gọi qua interface. v2.1 chỉ có 1 implementation (CustomPaint). v3 thêm `AssetTreeRenderer` + 1 switch. **KHÔNG thêm dependency/asset ở v2.1** — chỉ dựng ranh giới + ghi `dev.md`.
- **Ranh giới này chỉ là refactor nội bộ** — KHÔNG đổi hành vi/visual ngoài việc nâng cấp A.1/A.2. Tester nghiệm thu visual + no-regression, không nghiệm thu kiến trúc (Dev tự ghi `dev.md` theo AC#6 PO).

---

## B.1 — Coach mark 1-lần (hướng dẫn bấm hoa)

### B.1.1 Điều kiện hiện / ẩn
- **Hiện khi:** mở `LoveTreeScreen` + có **≥1 hoa đã nở** (`reached.isNotEmpty`) + **cờ Hive chưa set** (key mới `love_tree_coach_<coupleId>` trong box `app_settings`, kiểu String "1").
- **KHÔNG hiện khi:** 0 hoa (S0 — chưa có bông để bấm) · no-couple/waiting · loading · đã set cờ.
- **Đợi bloom xong rồi mới hiện:** nếu lần mở này có bông MỚI đang chạy animation nở (v1) → coach mark **delay tới sau khi bloom + confetti xong** (~`540ms + stagger`; đề xuất delay cố định **1200ms** sau frame đầu để đơn giản). Tránh chồng 2 hiệu ứng cùng lúc.
- **Ẩn khi:** user chạm **bất kỳ đâu trên màn** (kể cả chạm đúng bông → vừa mở sheet vừa ẩn coach + set cờ) HOẶC tự động sau **4000ms** kể từ lúc hiện. Cả 2 đường đều **set cờ Hive ngay** (best-effort, postFrame) → KHÔNG hiện lại lần sau, kể cả nếu user không bấm hoa.
- **Một lần / cặp đôi** (theo `coupleId`), không phải per-device-vĩnh-viễn theo user — khớp pattern `lastSeen`.

### B.1.2 Bông được trỏ (target)
- **Trỏ vào bông NỔI BẬT NHẤT về thị giác = bông ở GẦN ĐỈNH tán** (dễ thấy, không bị che). Quy tắc chọn deterministic: trong `positions` (đã tính), chọn bông có **`dy` nhỏ nhất** (cao nhất trên màn) trong nửa số bông; nếu hoà → lấy `dx` gần tâm nhất. (Tránh chọn bông sát mép dễ bị tooltip tràn.)
  - Lý do không chọn "bông mới nhất": bông mới nhất có thể rơi vào mép/đáy tán (theo phyllotaxis index cao → bán kính lớn) → khó thấy. Bông gần đỉnh luôn nổi.
- Toạ độ target = `positions[targetIndex]` (canvas-relative trong `_TreeHero`) → coach overlay phải nằm trong cùng hệ toạ độ Stack của `_TreeHero` (đặt coach là 1 `Positioned` trong Stack đó, sau lớp hoa).

### B.1.3 Anatomy (3 phần: ripple + ngón tay + tooltip)
Vẽ overlay trên bông target (KHÔNG che nội dung khác — `IgnorePointer` cho phần vẽ, bắt chạm bằng 1 lớp `GestureDetector` trong suốt phủ toàn `_TreeHero` để "chạm bất kỳ → ẩn"):

1. **Ripple (gợn sóng) — quanh bông target:**
   - 2–3 vòng tròn đồng tâm `accentLoveDeep` stroke 1.5px, alpha giảm dần ra ngoài (.45 → 0), **scale 0.6→1.8** + fade-out, loop **1400ms** (lệch pha giữa các vòng 0.33). Tâm = tâm bông target, bán kính cơ sở = `diameter*0.7`.
   - Curve `easeOut`. Cảm giác "có cái gì đó nhấp nháy mời chạm".
2. **Ngón tay (tap indicator):**
   - Icon `IconsaxPlusBold.finger_cricle` HOẶC (nếu không có glyph hợp) 1 chấm tròn "tap dot": vòng trắng .9 đường kính 18 + viền `accentLoveDeep` 2px, đặt hơi LỆCH dưới-phải bông target (offset `+10,+14`) để không che nhuỵ.
   - **Nhịp "tap":** scale 1.0→0.82→1.0 (như nhấn), chu kỳ **1000ms** easeInOut, đồng bộ với 1 nhịp ripple. (Nếu dùng icon finger: dịch chéo xuống 3px khi "nhấn".)
   - ⚠️ Iconsax có thể không có icon ngón tay đẹp → **đề xuất dùng "tap dot"** (chấm + ripple) cho chắc, không phụ thuộc glyph. Dev kiểm `IconsaxPlusBold.finger_cricle`/`finger_scan`; không có thì dùng tap-dot.
3. **Tooltip bubble:**
   - Vị trí: **phía trên bông target** (mặc định), mũi nhọn chỉ XUỐNG vào bông. Nếu bông quá gần đỉnh canvas (`dy < tooltipHeight + 16`) → lật xuống DƯỚI bông, mũi nhọn chỉ LÊN. Canh ngang theo bông nhưng **clamp trong [16, w-16]** để không tràn mép; mũi nhọn vẫn trỏ đúng bông (offset mũi theo chênh lệch).
   - Hình: bubble bo **r14**, nền **`textPrimary` #1A1A2E alpha .92** (tooltip tối — nổi trên cả nền sáng lẫn ảnh tán), chữ **trắng** 13 w700, padding **(14, 9)**. Mũi nhọn = tam giác 10×7 cùng màu nền.
   - Shadow bubble: black .20 blur 12 offset (0,4) → nổi.
   - Nội dung: text `loveTreeCoachTooltip` ("Chạm để xem khoảnh khắc 🌸"). 1 dòng (emoji ở cuối). Không icon riêng (emoji 🌸 đủ).
   - Tooltip **bám theo bông khi hoa sway** không cần thiết — vì coach hiện ở trạng thái tĩnh tương đối; để đơn giản, target tính 1 lần lúc hiện (bông sway ±2° biên độ nhỏ, lệch không đáng kể). Đề xuất: **tạm dừng sway của riêng bông target** trong lúc coach hiện (hoặc chấp nhận lệch — nhẹ).

### B.1.4 Animation timing
| Thành phần | Duration / Curve | Ghi chú |
|---|---|---|
| Fade-in cả cụm coach | 280ms easeOut | sau delay 1200ms (hoặc sau bloom) |
| Ripple vòng | 1400ms loop, easeOut, scale .6→1.8 + fade | 2–3 vòng lệch pha .33 |
| Tap dot/finger nhịp | 1000ms easeInOut, scale 1→.82→1 | đồng bộ ripple |
| Tự ẩn | sau 4000ms (kể từ fade-in xong) | fade-out 240ms |
| Ẩn do chạm | fade-out 200ms | set cờ ngay |

Dùng **1 AnimationController repeat** cho ripple + tap (tái dùng `_ambient` không hợp vì chu kỳ khác → tạo 1 controller riêng `_coachController` 1400ms repeat, dispose khi ẩn). Acceptable: thêm 1 controller ngắn-hạn (chỉ sống khi coach hiện).

### B.1.5 Reduce Motion (AC PO #4)
`AppMotion.reduceMotion(context) == true`:
- **TẮT ripple động + nhịp tap.** Vẽ **TĨNH**: 1 vòng tròn `accentLoveDeep` stroke 1.5 alpha .40 quanh bông (bán kính `diameter*1.1`) + tap-dot tĩnh (không nhấp) + tooltip (fade-in tĩnh hoặc hiện ngay).
- **Vẫn auto-ẩn sau 4000ms** + ẩn khi chạm. Vẫn set cờ Hive.
- ⇒ Reduce Motion: coach = "1 vòng khuyên + chấm + tooltip", tĩnh nhưng vẫn dạy được hành vi.

---

## B.2 — Caption thường trực dưới cây

Affordance luôn-hiện (kể cả sau khi coach mark biến mất / lần mở thứ 2+).

- **Vị trí:** ngay **DƯỚI khu cây (`_TreeHero`), TRÊN stage-title** — tức chèn giữa item 1 (cây) và item 2 (stage title) trong body Column. (Đặt dưới cây để gắn nghĩa với "mỗi bông trên cây bấm được".)
  - Spacing: cây → caption **10** · caption → stage title **14**. (Điều chỉnh từ "cây→title 16" hiện tại; tổng chiều cao chèn caption gọn.)
- **Điều kiện hiện:** chỉ khi **có ≥1 hoa** (`reached.isNotEmpty`). 0 hoa / no-couple / waiting / loading → **ẩn** (chưa có gì để bấm).
- **Hình:** dòng text căn giữa + icon nhỏ dẫn:
  - Icon `IconsaxPlusLinear.finger_cricle` (hoặc `IconsaxPlusLinear.magic_star` nếu thiếu) size **14**, màu `accentRose` (#FF4D6D), cách text 6.
  - Text `loveTreeTapHint` ("Chạm vào mỗi bông để xem kỷ niệm") — **12.5 w600**, màu `textSecondary` #6B6B7B, 1 dòng (wrap 2 dòng nếu hẹp, center).
  - **KHÔNG nền/pill** (giữ nhẹ, là caption không phải chip) — chỉ icon + chữ trên nền dawnBlush. Nếu Dev thấy chìm trên blush, cho phép bọc 1 pill rất nhẹ: `white .55` r999 padding (12,5) — **optional**, mặc định không nền.
- **Tĩnh** (không animation riêng; theo `EntranceReveal` chung của body nếu muốn, order 0 — nhưng đề xuất để tĩnh, không reveal, vì là affordance nền).
- **Không tự ẩn** — luôn ở đó như dòng chú thích.

---

## C — Token tổng hợp v2.1 (Dev khỏi đoán)

**Màu (đều có trong `AppColors`, hex tham chiếu):**
- Thân/tán/lá: GIỮ palette `_StageSpec` (#7BA86A…#6E5236 thân; canopyLight/Dark mỗi stage). Helper mới: `_lighten(c, amt)` (đối xứng `_darken` đã có — `HSLColor.withLightness(l+amt)`).
- Cánh hoa lớp trước: tâm `#FFF0F4` → `#FFD6E0` (mint1) → `petalEdge(kind)`. Lớp sau: `petalEdge` đặc .85.
- Nhuỵ: `nucleusColor(kind)` + `_lighten(.14)` đỉnh sáng / `_darken(.10)` đáy. Viền trắng .65 + inner ring trắng .30.
- Coach ripple/tap viền: `accentLoveDeep` #E63956. Tap-dot lõi: trắng .9.
- Coach tooltip nền: `textPrimary` #1A1A2E **alpha .92**, chữ trắng #FFFFFF.
- Caption: icon `accentRose` #FF4D6D, chữ `textSecondary` #6B6B7B; (optional pill white .55).

**Size / radius / spacing:**
- Hoa Ø 34 (mép 0.82·34≈28), nhuỵ Ø ≈20 (0.59·d), icon nhuỵ 0.6·nhuỵ — **GIỮ HẾT**.
- 6 cánh (vòng 60°); lớp sau xoay +30° scale 0.86.
- Tán 3 lớp: back R·1.02 / mid R·0.96 / front R·0.64 (R = `canopyR` cũ).
- Coach tooltip: r14, padding (14,9), mũi 10×7, chữ 13 w700, shadow black .20 blur 12 off(0,4). Ripple base R = Ø·0.7, max scale 1.8. Tap-dot Ø 18 viền 2.
- Caption: icon 14, chữ 12.5 w600, cách 6; cây→caption 10, caption→title 14.

**Shadow/blur:**
- Tán back blur 4; bóng tán green+ alpha .10 blur 10; front highlight radial (no blur, là gradient).
- Bóng hoa dưới tán: `darken(petalEdge,.15)` .10 blur 3 (tắt nếu d<30).
- Nhuỵ shadow: màu loại .30 blur 6 off(0,1.5). Icon shadow .35 blur 1.5.

**Duration/curve:** xem B.1.4. Sway/bloom/sky/season GIỮ v1/v2.

---

## D — States (v2.1 bổ sung)

| State | Coach mark | Caption | Cây/Hoa nâng cấp |
|---|---|---|---|
| **0 hoa (seed)** | KHÔNG (chưa có bông) | ẨN | Seed nâng cấp (A.1.3): mầm + 2 lá ±32° + giọt sương + bóng gốc |
| **≥1 hoa, lần đầu/cặp (cờ chưa set)** | HIỆN (sau bloom nếu có), ripple + tooltip trỏ bông đỉnh tán, ẩn khi chạm/4s, set cờ | HIỆN | Cây + hoa nâng cấp đầy đủ |
| **≥1 hoa, đã xem coach (cờ set)** | KHÔNG | HIỆN | Như trên |
| **Có bông mới + coach chưa xem** | bloom+confetti chạy TRƯỚC → coach delay ~1200ms rồi hiện | HIỆN | bông mới nở (v1) trên cây nâng cấp |
| **Loading** | KHÔNG | ẨN | skeleton xám (GIỮ v1) — KHÔNG vẽ tán đa lớp màu (giữ phẳng xám) |
| **No-couple / waiting** | KHÔNG | ẨN | seed nâng cấp tĩnh; nút "Mời người ấy" (waiting) GIỮ |
| **Reduce Motion ON** | coach TĨNH (vòng+chấm+tooltip), vẫn auto-ẩn + set cờ | HIỆN (vốn tĩnh) | cây/hoa nâng cấp vẽ tĩnh (gradient/lớp là tĩnh — vẫn đẹp) |

> Skeleton (loading) **KHÔNG** áp tán 3 lớp màu (giữ silhouette xám phẳng v1) để không "nhá" màu trước khi có data.

---

## E — Localization (vi + en) — key MỚI v2.1

Sửa CẢ `app_en.arb` + `app_vi.arb` → `fvm flutter gen-l10n`. Không placeholder (2 chuỗi tĩnh).

| Key | vi | en |
|---|---|---|
| `loveTreeCoachTooltip` | Chạm để xem khoảnh khắc 🌸 | Tap to see this moment 🌸 |
| `loveTreeTapHint` | Chạm vào mỗi bông để xem kỷ niệm | Tap a flower to relive a memory |

> Voice: "mỗi bông"/"kỷ niệm" — giữ ấm, không mệnh lệnh cứng. Emoji 🌸 chỉ ở tooltip (caption không emoji, gọn). Cả 2 đã hỗ trợ glyph TV (Quicksand) + emoji iOS/Android.

---

## F — Acceptance criteria (v2.1 — khớp PO + bổ sung design)

1. **Cây đẹp hơn rõ ở mọi stage** (seed→bloom): thân cong thuôn + gradient ngang, tán 3 lớp (sâu), lá có khối, bóng mềm. So mắt với v1 thấy tinh tế hơn. KHÔNG vỡ layout, KHÔNG tụt FPS.
2. **Hoa đẹp hơn:** 6 cánh 2 lớp + tâm sáng + nhuỵ disc có highlight/viền trong/bóng; icon nhuỵ đúng kind (`heart`/`flash`/`gallery`) GIỮ.
3. **Hoa KHÔNG nhảy chỗ:** vị trí hoa khớp hệt v1 (xoay máy / rebuild / mở lại) — `bloomPositions`/`canopyGeometry` không đổi.
4. **No-regression v2:** bấm hoa → `MomentSheet` đúng kind; bloom animation + confetti; thẻ "Khoe cây"; lớp trời theo giờ; mùa theo tháng — tất cả chạy như v2.
5. **Coach mark đúng 1 lần/cặp:** lần đầu (≥1 hoa, cờ chưa set) → ripple + tooltip "Chạm để xem khoảnh khắc 🌸" trỏ bông gần đỉnh tán; ẩn khi chạm bất kỳ HOẶC sau 4s; set cờ Hive → **mở lại KHÔNG hiện**. 0 hoa → KHÔNG hiện.
6. **Caption thường trực:** khi có ≥1 hoa, dòng "Chạm vào mỗi bông để xem kỷ niệm" luôn hiện dưới cây (kể cả sau khi coach biến mất). 0 hoa / no-couple → ẩn.
7. **Reduce Motion ON:** coach mark tĩnh (vòng + chấm + tooltip, không ripple/nhịp), vẫn auto-ẩn + set cờ; cây/hoa nâng cấp vẽ tĩnh vẫn đẹp; sway/bloom/đom đóm theo matrix v2 GIỮ.
8. **Render layer tách rõ:** Dev refactor phần vẽ cây/hoa sau ranh giới `LoveTreeRenderer` (hoặc tương đương) + ghi `dev.md` mô tả contract để v3 thay asset không đập logic mốc/stage/tap.
9. **Token brand:** màu/Quicksand/Iconsax đúng bảng C; 100% CustomPaint, KHÔNG asset/dependency mới. Coach tooltip nền navy .92 + chữ trắng (đọc rõ trên cả nền sáng/tối).
10. **i18n:** 2 key mới đủ vi+en; không hardcode; không vỡ dấu TV. `fvm flutter analyze` sạch.

---

## G — Dev notes / giữ-logic (nhắc lại — quan trọng)

1. **KHÔNG đổi** `LoveTreeService` (math/token kind) · `canopyGeometry` · `bloomPositions`/`_bloomHash` · stage thresholds · `_StageSpec.trunkHeight/canopyR/branchDirs` (đổi sẽ lệch vị trí hoa). Tán mới phải có **lớp mid trùng `canopyCenter`+`canopyR` cũ**.
2. **Nâng cấp cây** = sửa trong `_paintTree`/`_paintSeedling`/`_paintLeaf` + thêm helper `_lighten`. Tách (nếu refactor) thành `LoveTreeRenderer` — interface giữ chữ ký theo A.3.
3. **Nâng cấp hoa** = sửa `_FlowerPetalsPainter` (6 cánh 2 lớp + gradient 3 stop + bóng) + `_Nucleus` (highlight gradient + inner ring + icon shadow). GIỮ `nucleusD`/`diameter` tỉ lệ (animation pop dựa vào).
4. **Coach mark:** widget mới (vd `_TapCoachMark`) đặt là `Positioned` trong Stack của `_TreeHero`, trỏ `positions[targetIndex]` (target = bông `dy` nhỏ nhất trong nửa đầu). Cờ Hive `love_tree_coach_<coupleId>` (box `app_settings`, String "1"); đọc 1 lần initState, set ngay khi ẩn (postFrame, best-effort). 1 `AnimationController` riêng 1400ms repeat, dispose khi ẩn. Lớp bắt-chạm-bất-kỳ = `GestureDetector` trong suốt phủ `_TreeHero` (chạm → ẩn + nếu trúng bông vẫn mở sheet: cho coach overlay `IgnorePointer` phần vẽ, lớp chạm riêng `behavior: translucent` để tap vẫn xuống được hoa — hoặc đơn giản: chạm coach-layer = chỉ ẩn coach, lần chạm sau mới mở sheet; **đề xuất bản đơn giản** — chạm 1 lần ẩn coach, không bắt buộc cùng lúc mở sheet).
5. **Caption:** chèn 1 widget dưới `_TreeHero`, trên stage-title, chỉ khi `reached.isNotEmpty`. Tĩnh.
6. **Reduce Motion:** coach + cây/hoa phải có nhánh tĩnh (B.1.5 + D). Reuse `AppMotion.reduceMotion(context)`.
7. **Iconsax glyph:** xác nhận `IconsaxPlusBold.finger_cricle`/`IconsaxPlusLinear.finger_cricle` có trong package; thiếu → coach dùng "tap-dot" (chấm tròn), caption dùng `magic_star`. KHÔNG để build vỡ vì thiếu glyph.
8. **`shouldRepaint`:** cây vẫn chỉ repaint khi stage/season/skeleton đổi; coach controller chỉ repaint vùng coach (`RepaintBoundary` quanh coach overlay nếu cần). Không repaint cây khi coach nhấp nháy.
9. **Câu hỏi cho Dev (không blocker):** package `iconsax_plus` có icon ngón tay phù hợp không? Nếu không → dùng tap-dot (đã có phương án). Đây là chi tiết nhỏ, không cản nghiệm thu.

---

# Design Spec v2.2 — CÀNH HOA ANH ĐÀO (Sakura Branch) (2026-06-18)

> **Pivot visual.** User chê cây hiện tại "xấu quá" (tán blob xanh-lá-mạ = clip-art, lệch tông hồng). Đổi metaphor: bỏ thân-Y + tán-blob-xanh → **1 cành hoa anh đào nghiêng cong**, blossom đính dọc cành = mốc. Thanh thoát, organic, hợp tông hồng romantic. Nguồn chân lý: `overview.md` §"# v2.2".
>
> 🔒 **GIỮ NGUYÊN TUYỆT ĐỐI (v2.2 chỉ đổi *trông thế nào*, KHÔNG đổi *vẽ cái gì / ở đâu logic / bao nhiêu*):**
> - **Milestone math** (`LoveTreeService`: thresholds days/streak/photos, `buildMilestones`, `flowerCount`, `daysTogether`, `nucleusIcon/nucleusColor/petalEdge`, `stageForFlowers` 0→seed/1-2→sprout/3-5→young/6-9→green/10+→bloom) — KHÔNG đụng.
> - **Thứ tự `reached`** (days→streak→photos ascending = thứ tự blossom dọc cành, oldest first) — GIỮ.
> - **Tap blossom → `MomentSheet`** (#1 v2 §A) · **thẻ "Khoe cây"** (#3 v2 §C, đổi minh hoạ sang cành) · **bloom animation + confetti + `lastSeen`/bloom-once** (v1 §4) · **coach mark 1-lần + caption** (v2.1 §B) · **deep-link** · **Reduce-Motion matrix** (v2 §B.5 + v2.1 B.1.5) — GIỮ hành vi, chỉ đổi đối tượng vẽ.
> - **Sky theo giờ (`SkyBackdropPainter`, 4 phase) + mùa (`Season`, 4)** — GIỮ; chỉ nghiêng tông sang sakura (xuân/hồng chủ đạo) — xem §C.5.
> - **Ranh giới renderer `LoveTreeRenderer`** (abstract: `treePainter` + `flowerWidget`, contract neo `canopyGeometry`/hộp diameter) — GIỮ NGUYÊN INTERFACE; Dev thêm impl mới `SakuraBranchRenderer implements LoveTreeRenderer` (thay `kTreeRenderer = const SakuraBranchRenderer()`), giữ `PaintTreeRenderer` cũ để rollback.
> - ⚠️ **`bloomPositions`/`canopyGeometry` ĐƯỢC THAY** (cây→cành đổi layout) NHƯNG output PHẢI **deterministic per-index** (cùng `_bloomHash`) → blossom cũ KHÔNG nhảy chỗ giữa các lần vẽ (AC v1 #4 vẫn đạt).

## v2.2 — Mục lục
- **§0** Triết lý pivot (vì sao cành đẹp hơn cây)
- **§A** Hình học CÀNH — bézier thân chính + nhánh phụ + 5 stage (THAY `_StageSpec`→`_BranchSpec`, `_paintTree`→`paintBranch`)
- **§B** Anchor blossom dọc cành — thuật toán deterministic (THAY `bloomPositions`/`canopyGeometry`)
- **§C** BLOSSOM vẽ lại — 5 cánh khía + nhuỵ vàng-kem + glow (THAY `_FlowerPetalsPainter`/`_Nucleus`) · lá sakura · sky/mùa nghiêng-sakura · ambient cánh rơi
- **§D** Tích hợp & ranh giới `SakuraBranchRenderer`
- **§E** States · **§F** Token tổng hợp · **§G** Copy vi+en · **§H** Assets · **§I** Dev notes / giữ-logic · **§J** Acceptance

---

## §0 — Triết lý pivot (cành > cây cho app này)

Cây-tán-blob phải "đầy lá mới đẹp" và xanh-lá-mạ chọi với nền hồng → dễ ra clip-art. **Cành hoa anh đào** thắng vì:
1. **Negative space là bạn:** 1 nét cành mảnh + vài bông hoa = thanh thoát, sang. Không cần "lấp đầy" → ít hoa vẫn đẹp (giải bài "0–2 mốc trông trống").
2. **Tông hồng tự nhiên:** blossom hồng-trắng + thân nâu ấm = đúng "Sunset Romance", không còn mảng xanh chọi nền.
3. **Blossom = ngôi sao:** cành chỉ là "giá đỡ" mảnh → mắt dồn vào hoa (chính là mốc tình yêu). Đúng ý đồ sản phẩm.
4. **Organic, không robot:** đường cong bézier + blossom lệch 2 bên cành (không đối xứng cứng) → mềm mại, "vẽ tay".

**Nguyên tắc bất di:** mọi nét phải **mềm/organic/hợp hồng** — KHÔNG đường thẳng cứng, KHÔNG mảng màu phẳng to, KHÔNG viền cứng. Thà ÍT chi tiết mà tinh tế còn hơn nhiều mà rối. "Đừng để lại clip-art."

---

## §A — Hình học CÀNH (THAY canopy blob)

> Đổi: bỏ `_paintTree` (thân-ribbon + tán 3-lớp + lá viền + gò). Thay = **cành sakura nghiêng**. `_StageSpec`→ tái dụng tên hoặc đổi `_BranchSpec` (Dev tự chọn) — bảng tham số ở §A.4. Vẫn 100% CustomPaint.

### A.1 — Cành chính (main branch) — bézier cong thuôn

Toạ độ chuẩn hoá theo `size` (w,h), neo gốc ở **đáy-trái** (cành mọc từ góc dưới-trái vươn lên-phải — bố cục cổ điển tranh sakura, để negative space trên-trái cho sky/blossom thở):

- **Gốc cành** `P0 = (w*0.16, h*0.96)` (sát đáy, lệch trái).
- **Ngọn cành** `P3 = (w*0.74, h*0.20)` (vươn lên phải, không chạm mép trên để blossom đỉnh còn chỗ).
- **Đường tâm cành = 1 cubic bézier:**
  - control1 `C1 = (w*0.30, h*0.66)`
  - control2 `C2 = (w*0.42, h*0.30)`
  - ⇒ cành cong chữ-S thoải: ưỡn nhẹ sang phải ở 1/3 dưới, vươn thẳng dần ở ngọn. Tự nhiên, không cong gắt.
- **Độ dày thuôn (gốc→ngọn):** `wBase` → `wTip`, giảm theo tham số `t` dọc bézier (xem bảng A.4 cho px mỗi stage). **Vẽ cành = path FILL outline** (KHÔNG stroke đều — stroke đều = robot). Cách dựng:
  - Lấy ~14 điểm mẫu `Pi` trên bézier (t = 0..1), tại mỗi điểm tính pháp tuyến (vuông góc tiếp tuyến) → đẩy ra 2 bên `±halfWidth(t)` với `halfWidth(t) = lerp(wBase/2, wTip/2, easeIn(t))` (thuôn nhanh hơn về ngọn → ngọn mảnh thanh).
  - Nối 2 mép bằng path khép, fill. Ngọn bo tròn (drawCircle bán kính `wTip/2` tại P3).
- **Gradient thân (khối tròn, KHÔNG phẳng):** `LinearGradient` vuông góc trục cành (cạnh sáng→cạnh tối): `_lighten(barkColor, 0.07)` → `barkColor` → `_darken(barkColor, 0.12)`. (Dùng helper `_lighten`/`_darken` đã có.)
- **Màu thân nâu ấm** `barkColor = #8A5A44` (nâu hồng ấm, KHÔNG nâu-đất xám — phải hợp hồng). Stage nhỏ nhạt hơn, stage lớn đậm hơn (bảng A.4). KHÔNG xanh-lá.
- **Vân thân (young+):** 1 đường cong mảnh `_darken(barkColor, 0.14)` alpha .30 strokeWidth 1 chạy dọc 1/2 dưới cành (gợi vỏ). Bỏ ở seed/sprout (cành mảnh).

### A.2 — Nhánh phụ (side branches) — rẽ từ cành chính

Số nhánh tăng theo stage (bảng A.4). Mỗi nhánh = **1 cubic bézier ngắn** rẽ từ 1 điểm trên cành chính (tham số `tBranch` ∈ [0,1] dọc cành), vươn ra-lên:

- **Điểm rẽ** = `branchPointAt(tBranch)` (điểm trên bézier cành chính).
- **Nhánh 1** (xuất hiện stage young+): rẽ ở `tBranch=0.42`, hướng **lên-trái**, dài ≈ `0.26 * chiều-dài-cành-chính`, cong nhẹ vểnh lên. Ngọn ở khoảng `(w*0.30, h*0.40)`.
- **Nhánh 2** (xuất hiện stage green+): rẽ ở `tBranch=0.66`, hướng **lên-phải**, dài ≈ `0.22 * cành chính`. Ngọn ≈ `(w*0.90, h*0.34)`.
- **Nhánh 3** (chỉ bloom — phụ nhỏ): rẽ ở `tBranch=0.30`, hướng phải-ngang ngắn, dài ≈ `0.16`. Ngọn ≈ `(w*0.50, h*0.58)`.
- Dày: gốc nhánh = `0.5 × halfWidth(tBranch)` của cành chính tại điểm rẽ, thuôn về `wTip*0.7`. Cùng cách dựng FILL-outline + gradient + ngọn bo tròn như A.1. Đầu nhánh ăn liền vào cành (vẽ nhánh TRƯỚC khi vẽ cành chính, hoặc overlap chỗ rẽ để liền mạch — không hở khe).
- **Nhánh phải nghiêng cùng "khí" với cành chính** (đều vươn lên) — đừng rẽ ngang/xuống gắt (gãy thẩm mỹ).

### A.3 — 5 stage cành (theo `stageForFlowers`, GIỮ thresholds)

Khác biệt mỗi stage = **độ vươn của ngọn (tEnd) + số nhánh phụ + mật độ blossom**. Cành "dài/đầy" dần theo số mốc:

| Stage | flowerCount | Tên (l10n GIỮ) | Cành chính | Nhánh phụ | Blossom / nụ | Lá sakura |
|---|---|---|---|---|---|---|
| **seed** | 0 | Hạt mầm | Cành NGẮN trơ: bézier chỉ vẽ tới `tEnd=0.34` (đoạn gốc), ngọn cụt ở ≈`(w*0.36, h*0.66)`. Mảnh nhất. | 0 | **1–2 NỤ KÍN** (bud — chấm tròn hồng nhạt bọc đài xanh, chưa nở) ở ngọn cành. KHÔNG blossom nở. | 0 |
| **sprout** | 1–2 | Mầm non | Cành tới `tEnd=0.52`, ngọn ≈`(w*0.50, h*0.50)`. | 0 | vài blossom (= số mốc) ở 1/2 trên đoạn cành + 1 nụ ở ngọn | 0 |
| **young** | 3–5 | Cây non | Cành tới `tEnd=0.74` + **nhánh 1**. | 1 (lên-trái) | nhiều blossom dọc cành + nhánh; 1–2 nụ xen | 0 |
| **green** | 6–9 | Cây xanh | Cành tới `tEnd=0.90` + **nhánh 1+2**. | 2 | cành + 2 nhánh đầy blossom | **lá điểm xuyết RẤT ÍT (2–3)** ở chỗ trống gần gốc nhánh |
| **bloom** | 10+ | Nở rộ | Cành FULL `tEnd=1.0` + **nhánh 1+2+3** + ngọn vểnh. | 3 | NỞ RỘ: blossom dày + **cánh rơi nhiều** (ambient §C.4) + glow hồng rất nhẹ sau cụm blossom đỉnh | **3–4 lá** điểm xuyết |

**Quan trọng — "trơ" không buồn:** seed/sprout cành mảnh + nụ kín = "sắp nở", gợi chờ đợi ấm áp (KHÔNG khẳng khiu lạnh). Nụ kín hồng nhạt là điểm nhấn dễ thương cho stage 0 (thay 2 lá-mầm cũ).

### A.4 — Bảng tham số `_BranchSpec` (Dev khỏi đoán)

> Thay `_StageSpec`. `tEnd` = vẽ bézier cành chính tới tham số này (clip đoạn). `wBase/wTip` px @ canvas chuẩn (sẽ scale theo h thực; dùng tỉ lệ `h*k` nếu muốn co — đề xuất scale theo `min(w,h)`). Số dưới @ canvas ~ 360–460px cao.

| Stage | tEnd | wBase | wTip | barkColor | nhánh (tBranch, hướng, lenFrac) | budCount | leafCount |
|---|---|---|---|---|---|---|---|
| seed | 0.34 | 5 | 2.5 | `#A8755C` (nâu nhạt ấm) | — | 2 (nụ kín ở ngọn) | 0 |
| sprout | 0.52 | 7 | 3 | `#9C6A50` | — | 1 | 0 |
| young | 0.74 | 9 | 3.5 | `#8A5A44` | [(0.42, lên-trái, 0.26)] | 1 | 0 |
| green | 0.90 | 11 | 4 | `#7E5039` | [(0.42, lên-trái, 0.26), (0.66, lên-phải, 0.22)] | 1 | 2 |
| bloom | 1.00 | 13 | 4.5 | `#724631` | [(0.42, lên-trái, 0.26), (0.66, lên-phải, 0.22), (0.30, phải, 0.16)] | 1 | 3 |

> barkColor đậm dần + ấm (sắc cam-hồng trong nâu) → KHÔNG xám/lạnh. `wTip` luôn mảnh (≤4.5) → cành "thanh", không chunky.

---

## §B — Anchor blossom DỌC CÀNH (THAY `bloomPositions`/`canopyGeometry`)

> Đây là thứ thay "scatter golden-angle trong tán". Blossom đính dọc đường cong cành, lệch vuông góc 2 bên. PHẢI **deterministic per-index** (dùng `_bloomHash` cho t và độ lệch) → blossom cũ không nhảy.

### B.1 — Thuật toán `bloomPositions(stage, size, count)` mới

Trả `List<Offset>` (length = count), Offset[i] = tâm blossom thứ `i` (canvas-relative trong `_TreeHero`). Index `i` ổn định (= rank trong `reached`, oldest→newest).

```
// 1. Gom các "segment" mang blossom theo stage:
//    - cành chính: bézier(P0,C1,C2,P3) clip tới tEnd
//    - + mỗi nhánh phụ: bézier ngắn (theo bảng A.4)
//    Mỗi segment có hàm pointAt(t)∈[0,1] + normalAt(t) (pháp tuyến đơn vị).
//
// 2. Phân bổ count blossom vào segments theo TRỌNG SỐ độ dài segment
//    (cành chính dài → nhiều blossom hơn nhánh). Dồn từ NGỌN xuống cho mỗi
//    segment để bông mới (index cao) rơi về phía ngọn (cảm giác "vừa nở ở đầu cành").
//
// 3. Với mỗi blossom index i đã gán vào segment s ở "slot" j/Nseg:
//    base_t = lerp(tLo, tHi, (j + 0.5) / Nseg)     // dàn đều dọc segment, chừa 2 đầu
//    // jitter t CỐ ĐỊNH theo index (không random runtime):
//    t = clamp(base_t + (_bloomHash(i) % 9 - 4) / 100.0, 0.06, 0.96)  // ±0.04
//    P = segment.pointAt(t)
//    N = segment.normalAt(t)                         // vuông góc cành
//    // lệch 2 bên cành, deterministic + so le trái/phải:
//    sideSign = (_bloomHash(i*7+3) & 1) == 0 ? 1 : -1
//    offsetMag = wHalf(t) + flowerR*0.55 + (_bloomHash(i*31+5) % 6)   // ngồi sát mép cành + jitter 0..5px
//    pos = P + N * (sideSign * offsetMag)
//    out[i] = pos
```

- `wHalf(t)` = nửa-bề-rộng cành tại `t` (để blossom "đậu" ngay mép cành, cuống ăn vào cành — không lơ lửng giữa không trung).
- `flowerR` = bán kính blossom của index đó (`_flowerDiameter(i,count)/2`).
- **so le 2 bên** (sideSign theo hash) → blossom không xếp 1 hàng cứng; nhưng deterministic.
- **Dồn về ngọn:** trong mỗi segment, slot có `j` cao (gần ngọn) ưu tiên cho blossom index cao → bông mới ở đầu cành. (Hoặc đơn giản: gán theo thứ tự index tăng = chạy dọc segment từ gốc→ngọn; cả 2 đều deterministic — Dev chọn, miễn ỔN ĐỊNH.)
- **Clamp trong canvas:** nếu `pos` tràn mép (x<flowerR hoặc >w-flowerR, y tương tự) → clamp vào trong + 4px margin. Blossom KHÔNG được clip ra ngoài khu cây (AC #2).
- **count==0** → return `const []` (seed: chỉ vẽ nụ kín trong painter cành, không qua đây).

### B.2 — `canopyGeometry` thay = "anchor cụm đỉnh cành"

`canopyGeometry(stage, size)` vẫn còn được gọi bởi `_coachTargetIndex` (gián tiếp qua positions) + share card. Với cành, giữ chữ ký `(Offset center, double radius)` nhưng nghĩa đổi:
- `center` = **điểm ngọn cành chính** `pointAt(tEnd)` (cụm blossom đỉnh — nơi coach trỏ + tâm cảm xúc).
- `radius` = `min(w,h) * 0.30` (notional — chỉ dùng cho glow bloom-stage + fallback; KHÔNG còn neo blossom vì blossom giờ neo dọc cành qua §B.1).
- ⚠️ `_coachTargetIndex(positions)` GIỮ NGUYÊN (chọn blossom `dy` nhỏ nhất = cao nhất = gần ngọn cành) → tự nhiên trỏ đúng cụm đỉnh. Không cần đổi.

### B.3 — Vì sao vẫn deterministic (đáp AC v1 #4)
- Mọi nguồn ngẫu nhiên đều từ `_bloomHash(index)` (đã có, thuần index) — KHÔNG `Random()`, KHÔNG thời gian. Cùng `(stage, size, count)` + cùng index → cùng Offset mọi lần vẽ. Xoay máy đổi `size` → vị trí scale theo nhưng tỉ lệ ổn định, blossom KHÔNG "nhảy ngẫu nhiên".
- Hoa cũ (index thấp) giữ slot; hoa mới (index cao) rơi vào slot kế (về phía ngọn). Khớp cơ chế `newFromIndexInReached` của `_TreeHero` (bông `i >= newFrom` mới animate nở).

---

## §C — BLOSSOM vẽ lại + lá + sky/mùa + ambient

### C.1 — Hình BÔNG sakura (THAY `_FlowerPetalsPainter`)

Bông render qua `_LoveFlower` (GIỮ widget + chữ ký + hit-pad + bloom-anim) → bên trong đổi painter cánh + nhuỵ. Giữ `diameter` 34px base / 0.82 mép (`_flowerDiameter`), nhuỵ `diameter*0.59`, hit ≥44 (`_flowerHitPad`).

- **5 cánh** (đặc trưng sakura, vòng 72°). **Bỏ lớp-sau-6-cánh** (v2.1) → sakura cổ điển 5 cánh 1 lớp rõ ràng đẹp hơn.
- **Cánh có KHÍA (notch) ở đầu** — chữ ký sakura. Hình cánh (pointing up, −y, tâm gốc):
  ```
  // cánh rộng petalW, dài petalLen; khía chữ V nông ở ĐỈNH cánh:
  baseY = -size.height*0.04           // cuống cánh hơi tụt vào tâm
  notchDepth = petalLen*0.16          // độ sâu khía
  // mép trái lên đỉnh-trái:
  moveTo(0, baseY)
  cubicTo(-petalW, -petalLen*0.42,  -petalW*0.62, -petalLen*0.86,  -petalW*0.30, -petalLen)   // tới vai-trái đỉnh
  quadraticBezierTo(0, -petalLen + notchDepth,  petalW*0.30, -petalLen)   // ↓ KHÍA chữ V vào giữa rồi ↑ vai-phải
  cubicTo(petalW*0.62, -petalLen*0.86,  petalW, -petalLen*0.42,  0, baseY) // mép phải về cuống
  close()
  ```
  - `petalLen = size.height*0.46`, `petalW = size.width*0.32`. Cánh **bầu ở giữa, hơi loe**, khía V nông ở đỉnh → đọc ra "sakura" ngay.
- **Gradient cánh 3-stop** (tâm trắng → mép màu kind), `RadialGradient` từ tâm bông (Offset.zero) bán kính `petalLen`:
  - stop 0.0 = `#FFFFFF` (hoặc `#FFF0F4` cho ấm hơn — **đề xuất `#FFF0F4`** để không trắng-gắt)
  - stop 0.50 = `#FFD6E0` (mint1)
  - stop 1.0 = `petalEdge(kind)` (days `#FF8FA3` / streak `#FFB6C1` / photos `#C8A8E9` — GIỮ service)
- **Viền cánh:** GIỮ kiểu mờ-dần — trắng .40 ở gốc → trắng .10 ở đỉnh (gradient stroke 1px). Mềm, không cứng.
- **Bóng dưới blossom (lift):** trước khi vẽ cánh, 1 ellipse `_shadeFlowerColor(petalEdge, -0.15)` alpha **.08** blur 3 ngay dưới tâm (offset 0,+2) → bông "nổi" trên cành. Tắt nếu `size.width < 30`.
- **(Tuỳ chọn) lớp sau rất mờ:** nếu Dev muốn chiều sâu, 5 cánh-sau xoay +36° scale 0.80 fill `petalEdge` alpha **.30** (rất nhạt — KHÔNG đậm .85 như v2.1, kẻo nặng). **Mặc định BỎ** (5 cánh 1 lớp đã đẹp & nhẹ); chỉ thêm nếu bloom-stage thấy mỏng.

### C.2 — Nhuỵ sakura (THAY `_Nucleus`)

Đặc trưng sakura = **chùm nhuỵ vàng-kem toả từ tâm**. Nhuỵ ở đây gánh 2 việc: (a) đặc trưng hoa anh đào, (b) GIỮ icon kind (heart/flash/gallery) để "đọc được" loại mốc. **BỎ viền chip cứng → glow mềm.**

Dựng (đường kính nhuỵ `nucleusD = diameter*0.59 ≈20px` — GIỮ tỉ lệ cho bloom-pop anim):
1. **Glow nền** (thay viền chip): radial `nucleusColor(kind)` alpha **.22** → transparent, bán kính `nucleusD*1.4` — quầng sáng mềm quanh tâm. (KHÔNG `boxShadow` viền cứng.)
2. **Chấm nhuỵ vàng-kem (stamens) — đặc trưng:** **6–7 chấm tròn** đường kính `nucleusD*0.10` (≈2px) màu **`#FFE6A8`** (vàng-kem) rải trên 1 vòng bán kính `nucleusD*0.32` quanh tâm (góc đều + lệch cố định theo hash để organic), mỗi chấm có 1 đầu sáng `#FFF4D6` nhỏ hơn. Đây là "tua nhuỵ" — RẤT đặc trưng anh đào.
3. **Đĩa tâm nhỏ:** disc `nucleusD*0.5` (≈10px) gradient radial `_shade(nucleusColor,+0.12)` → `nucleusColor` → `_shade(nucleusColor,-0.08)` (khối mềm). KHÔNG viền trắng dày; chỉ 1 vòng sáng trong trắng .25 0.6px (men sứ nhẹ, optional).
4. **Icon kind NHỎ ở tâm:** `nucleusIcon(kind)` size `nucleusD*0.34` (≈7px — NHỎ, vì giờ chia chỗ với tua nhuỵ) màu **trắng** trên đĩa tâm. Shadow icon mảnh `_shade(nucleusColor,-0.2)` .35 blur 1 (tách nền). Icon GIỮ per kind (heart/flash/gallery).

> Tỉ lệ chỗ: glow (nền) → tua vàng-kem (vòng giữa) → đĩa tâm + icon (lõi). Mắt thấy "hoa anh đào có nhuỵ vàng", nhìn kỹ thấy icon kind ở lõi. Cân bằng đặc-trưng-hoa vs đọc-được-mốc.

### C.3 — Nụ kín (bud) — cho seed/sprout/xen kẽ

Nụ chưa nở = chấm dễ thương ở ngọn cành (stage seed dùng thay blossom). Vẽ trong painter cành (KHÔNG phải `_LoveFlower` — nụ không bấm được, không phải mốc):
- Bầu nụ: oval đứng `~8×11px` gradient `#FFD6E0` → `#FF8FA3` (hồng nhạt→đậm), đầu hơi nhọn.
- Đài (calyx): 2–3 lá đài nhỏ `#9FBF7A` (xanh-ngả-vàng mềm, KHÔNG xanh-lá-mạ gắt) ôm gốc nụ.
- Cuống nụ: 1 line ngắn `barkColor` nối nụ vào cành.
- Đặt ở ngọn cành (`tEnd`) lệch nhẹ. seed: 2 nụ chụm; sprout+: 1 nụ ở ngọn xen blossom.

### C.4 — Lá sakura (điểm xuyết — RẤT ít)

CHỈ green (2–3 lá) + bloom (3–4 lá). Lá non sakura **xanh-ngả-hồng** (không xanh-lá-mạ):
- Hình giọt răng cưa nhẹ (hoặc giọt trơn đơn giản — đủ), dùng `_paintLeaf` style nhưng đổi palette.
- Màu lá 3-stop: `#B8CBA0` (xanh nhạt ngả vàng) → `#9FBF7A` → `#C9A8B0` (mép ngả hồng-nâu — lá non sakura có sắc đồng-hồng). Gân lá trắng .18.
- Kích thước nhỏ (`len ≈ canvas h*0.05`), đặt ở chỗ TRỐNG gần gốc nhánh (không đè blossom). RẤT thưa — lá là gia vị, KHÔNG phải khối.

### C.5 — Sky theo giờ + mùa (GIỮ `SkyBackdropPainter`, nghiêng sakura)

- **4 phase giờ GIỮ NGUYÊN** (dawn/day/dusk/night + sao + đom đóm) — `SkyBackdropPainter` không đổi logic.
- **4 mùa GIỮ** nhưng tông nghiêng sakura: **xuân (2–4) là "mùa nhà"** của sakura → cánh rơi hồng nhiều hơn (ambient §C.6), tint nền hơi hồng-trắng. Hè/thu/đông vẫn phân biệt được (hè: tint xanh-mát rất nhẹ trên blossom; thu: vài lá ngả vàng-cam hơn; đông: tông mát, blossom thưa cảm giác) — nhưng **blossom luôn hồng** (sakura), KHÔNG đổi blossom theo mùa.
- `_paintSeasonTint`: vì không còn canopy-path để clip, đổi thành **wash rất nhẹ toàn canvas** (alpha ≤.06) hoặc bỏ (sky đã mang mùa). **Đề xuất:** mùa thể hiện chủ yếu qua ambient (cánh/lá rơi) + sky, bỏ tint-canopy cũ.

### C.6 — Ambient: CÁNH SAKURA RƠI (THAY lá rơi — đẹp hơn)

`_AmbientParticles`/`_ParticlesPainter` GIỮ khung (fireflies đêm + falling xuân/thu + Reduce-Motion static), đổi hạt "falling":
- **Hạt rơi = CÁNH HOA sakura** (không phải teardrop lá): vẽ 1 cánh sakura nhỏ (path cánh khía C.1 thu nhỏ `~10px`) màu `#FFD6E0`→`#FF8FA3` (gradient hoặc đặc hồng nhạt), **xoay + lắc lư** khi rơi (rot + swayX sin — đã có trong `_paintFalling`, chỉ đổi shape + màu).
- Xuân: cánh hồng nhiều (count giữ ~4–5). Thu: vài cánh ngả vàng-cam `#F0B95A` (lá thu) — giữ phân biệt mùa. Đêm: đom đóm GIỮ.
- bloom-stage: thêm 1–2 cánh rơi ngay cả ngoài mùa xuân (flourish "nở rộ"). Cap tổng ≤6 hạt (hiệu năng).
- **Reduce-Motion static GIỮ:** cánh rải tĩnh trên/quanh gốc cành (như cánh đã rụng) — frame tĩnh đẹp.

---

## §D — Tích hợp & ranh giới `SakuraBranchRenderer`

> GIỮ interface `LoveTreeRenderer` (abstract: `treePainter` + `flowerWidget`). Dev thêm impl mới, đổi `kTreeRenderer`. Đây là điểm để v3 drop illustration/Lottie cành thật.

- **`SakuraBranchRenderer implements LoveTreeRenderer`:**
  - `treePainter(stage, season, skeleton)` → trả `SakuraBranchPainter` (thay `LoveTreePainter`): vẽ **cành chính + nhánh phụ + nụ + lá điểm xuyết** (§A + C.3 + C.4). KHÔNG vẽ blossom (blossom là overlay widget). `skeleton=true` → cành xám phẳng (`surfaceLight`), không nụ/lá màu — GIỮ cơ chế skeleton.
  - `flowerWidget(kind, diameter, isNew, bloomOrder, reduceMotion, swayPhase, ambient, onTap)` → trả `_LoveFlower` (GIỮ widget) với painter cánh + nhuỵ MỚI (§C.1/C.2). Chữ ký KHÔNG đổi.
- **Contract renderer cành phải tôn trọng (đáp ranh giới v3):**
  1. `treePainter` vẽ cành sao cho **đường tâm cành + `tEnd` + nhánh khớp đúng các segment mà `bloomPositions` dùng để neo blossom** (vì blossom đính DỌC cành — nếu painter vẽ cành lệch segment thì blossom "đậu hụt"). ⇒ **Cành geometry (bézier P0..P3, control, tEnd, nhánh) phải là 1 nguồn chung** dùng bởi cả painter (vẽ) lẫn `bloomPositions` (neo). Đề xuất: tách `SakuraBranchGeometry(stage, size)` trả các segment (`pointAt`/`normalAt`/`wHalf`) — painter và bloomPositions cùng gọi. Đây là điểm neo TƯƠNG ĐƯƠNG `canopyGeometry` cũ.
  2. `flowerWidget` vẽ blossom trong hộp `diameter×diameter`, **tâm bông + nhuỵ ở giữa hộp** (để hit-pad + bloom-pop anim của screen đúng) — GIỮ như v2.1.
  3. Renderer KHÔNG đọc provider, KHÔNG tính mốc — chỉ nhận `stage/kind/diameter/season/motion`.
- **`_TreeHero` build:** thứ tự Stack GIỮ (sky → cành painter → blossoms Positioned → ambient → confetti → coach). Đổi: `bloomPositions` mới (§B.1) + painter cành mới. `_coachTargetIndex` GIỮ.
- **Thẻ "Khoe cây" (`_LoveTreeShareCard`/`_ShareTree`):** GIỮ layout 4:5 + tên cặp + "{days} ngày · {flowers} bông" + watermark; chỉ đổi minh hoạ từ cây→cành (gọi cùng `SakuraBranchPainter` + `bloomPositions`). Cành trên thẻ nên đặt cân giữa-dưới, blossom đỉnh hướng lên — kiểm clamp để không tràn thẻ.

---

## §E — States (v2.2 — cập nhật từ v1/v2/v2.1)

| State | Cành / Blossom | Coach | Caption | Ambient |
|---|---|---|---|---|
| **0 hoa (seed)** | Cành ngắn trơ + **1–2 nụ kín** ở ngọn (C.3). KHÔNG blossom. Stage title "Hạt mầm" + phụ "Hành trình của hai bạn bắt đầu từ đây 🌱". | KHÔNG (chưa có bông) | ẨN | sky theo giờ; cánh rơi nếu xuân (nhẹ) |
| **1–2 hoa (sprout)** | Cành ngắn + 1–2 blossom + 1 nụ ngọn. | nếu cờ chưa set → hiện trỏ blossom đỉnh | HIỆN | theo mùa |
| **3–5 (young)** | + nhánh 1, nhiều blossom. | như trên | HIỆN | theo mùa |
| **6–9 (green)** | + nhánh 2, blossom dày + 2–3 lá điểm. | như trên | HIỆN | theo mùa |
| **10+ (bloom)** | Cành full 3 nhánh, blossom nở rộ + cánh rơi nhiều + glow đỉnh nhẹ. Title "Nở rộ" + phụ "Cây của hai bạn đang rực rỡ ✨". | như trên | HIỆN | cánh rơi cả ngoài xuân |
| **Có bông mới** | bloom-anim §v1 cho blossom mới (index ≥ newFrom) + confetti + banner "Cây vừa nở X bông mới 🌸"; coach delay sau bloom. | delay rồi hiện | HIỆN | — |
| **Loading** | Cành **xám phẳng** (skeleton, không nụ/lá/blossom màu) + shimmer pill title. | KHÔNG | ẨN | KHÔNG |
| **No-couple / waiting** | Cành seed tĩnh + thông điệp `_StateMessage` (waiting: nút "Mời người ấy"); KHÔNG blossom/ambient động. | KHÔNG | ẨN | tĩnh |
| **Reduce Motion ON** | Cành + blossom + nụ + lá vẽ TĨNH (gradient/glow là tĩnh — vẫn đẹp); cánh rơi → rải tĩnh quanh gốc; sao tĩnh; sway/đom-đóm/bloom-anim TẮT. Banner tĩnh. Coach tĩnh (vòng+chấm+tooltip). | tĩnh, auto-ẩn, set cờ | HIỆN | static |

---

## §F — Token tổng hợp v2.2 (Dev khỏi đoán)

**Màu (đều `AppColors` hoặc hex literal — KHÔNG `Colors.*` trần):**
- **Thân/nhánh (bark):** seed `#A8755C` · sprout `#9C6A50` · young `#8A5A44` · green `#7E5039` · bloom `#724631`. Gradient mỗi cành: `_lighten(bark,.07)` → bark → `_darken(bark,.12)`. Vân thân `_darken(bark,.14)` .30. (Nâu ấm sắc hồng — KHÔNG xám.)
- **Cánh blossom 3-stop:** `#FFF0F4` (0.0) → `#FFD6E0` mint1 (0.50) → `petalEdge(kind)` (1.0): days `#FF8FA3` / streak `#FFB6C1` / photos `#C8A8E9`. Viền cánh trắng .40→.10. Bóng dưới hoa `_shade(petalEdge,-.15)` .08 blur 3.
- **Nhuỵ:** glow `nucleusColor(kind)` .22→transparent (R `nucleusD*1.4`). Tua nhuỵ `#FFE6A8` (đầu sáng `#FFF4D6`), 6–7 chấm Ø `nucleusD*0.10` trên vòng R `nucleusD*0.32`. Đĩa tâm `_shade(nucleusColor,±)` Ø `nucleusD*0.5`, vòng trong trắng .25. Icon trắng Ø `nucleusD*0.34` + shadow `_shade(nucleusColor,-.2)` .35 blur 1. `nucleusColor`: days `#FF4D6D` / streak `#E63956` (gradient từ `#FF8FA3`) / photos `#A78BFA` — GIỮ service.
- **Nụ kín:** bầu `#FFD6E0`→`#FF8FA3`; đài `#9FBF7A`; cuống bark.
- **Lá sakura:** `#B8CBA0` → `#9FBF7A` → mép `#C9A8B0`; gân trắng .18.
- **Cánh rơi ambient:** `#FFD6E0`/`#FF8FA3` (xuân/bloom); thu pha `#F0B95A`. Đom đóm GIỮ `#FFF6C8`/`#FFE066`.
- **Glow đỉnh bloom:** radial `accentRose #FF4D6D` .10 → 0, R `min(w,h)*0.30` quanh ngọn cành.
- Nền màn/banner/chip/text/sheet/share: **GIỮ y v1/v2/v2.1** (dawnBlush; banner accentRose .10 viền .30; chip "đã nở" success .12; sheet cardSurface r28; share 4:5; navy/secondary/tertiary text; Quicksand; Iconsax).

**Size / radius / spacing:**
- Blossom Ø 34 base / 0.82 mép (`_flowerDiameter` GIỮ); nhuỵ `diameter*0.59`; hit ≥44 (`_flowerHitPad` GIỮ).
- 5 cánh (vòng 72°); khía đỉnh sâu `petalLen*0.16`; petalLen `h*0.46`, petalW `w*0.32`.
- Cành: `wBase 5→13`, `wTip 2.5→4.5` theo stage (bảng A.4). bézier P0`(.16,.96)` C1`(.30,.66)` C2`(.42,.30)` P3`(.74,.20)` (fraction của w,h khu cây).
- Khu cây: chiều cao `(usable*0.52).clamp(360,460)` — GIỮ.
- ContentCard r24 / pill r999 / sheet r28 / thumb r20 — GIỮ.

**Shadow/blur/duration:** bóng hoa blur 3; glow nhuỵ/đỉnh = gradient (no blur); cành ngọn bo `drawCircle`. Bloom-anim 540ms easeOutBack + nhuỵ-pop delay 0.22 + stagger 140ms/bông cap 6 — **GIỮ v1**. Sway ±2° 3–4s — GIỮ. Sky/season/coach timing — GIỮ v2/v2.1.

**Typography:** GIỮ toàn bộ (Quicksand): stage title 22 w800 · phụ 14 · section 16 w800 · tile 15 w700 · banner 14 w700 · milestone 14 w600 · coach tooltip 13 w700 · caption 12.5 w600. EyebrowChip `pageEyebrowStyle`.

---

## §G — Copy vi + en

**TÁI DÙNG toàn bộ key cũ** (v1 30 key + v2 ~14 + v2.1 2 = đã có): `loveTreeBadge`, `loveTreeStage0..4`, `loveTreeFlowerCount(Zero)`, `loveTreeSeedSubtitle`, `loveTreeBloomSubtitle`, `loveTreeNewBloomBanner(One)`, nurture/milestone/waiting/no-couple, MomentSheet keys, share keys, `loveTreeCoachTooltip`, `loveTreeTapHint`. **Pivot KHÔNG đổi copy** — "cây/bông hoa" vẫn dùng được cho cành sakura (cành cũng "nở hoa", vẫn gọi "cây tình yêu" như metaphor tổng).

> Quyết định voice: KHÔNG đổi badge/title sang "Cành hoa anh đào" — giữ "CÂY TÌNH YÊU" / "LOVE TREE" (metaphor cảm xúc tổng; user vẫn gọi là "cây"). "Bông hoa"/"nở" khớp blossom sakura. ⇒ **0 key mới ở v2.2.**

(Nếu sau này muốn nhấn "anh đào" trong copy thẩm mỹ — backlog, không làm v2.2.)

---

## §H — Assets
- **KHÔNG asset ảnh** (vẫn 100% CustomPaint). KHÔNG dependency mới (confetti/iconsax/share_plus đã có).
- Icon nhuỵ: `IconsaxPlusBold.heart` / `IconsaxPlusLinear.flash` / `IconsaxPlusLinear.gallery` (GIỮ `nucleusIcon`). Coach/caption icon GIỮ v2.1. Header `flower2` (hoặc tương đương Iconsax) — GIỮ.
- Hive: KHÔNG key mới (`love_tree_seen_*` + `love_tree_coach_*` GIỮ).

---

## §I — Dev notes / giữ-logic (quan trọng)

1. **KHÔNG đổi** `LoveTreeService` (math + `nucleusIcon/nucleusColor/petalEdge` + thresholds + `stageForFlowers`). v2.2 chỉ đổi RENDER.
2. **Thay nhưng giữ deterministic:** `bloomPositions` (§B.1 — anchor dọc cành, jitter qua `_bloomHash`, KHÔNG `Random`) + `canopyGeometry` (§B.2 — center=ngọn cành, radius notional). `_coachTargetIndex` GIỮ NGUYÊN.
3. **1 nguồn geometry cành chung** (`SakuraBranchGeometry(stage,size)` đề xuất): trả các segment (cành chính clip `tEnd` + nhánh) với `pointAt(t)`/`normalAt(t)`/`wHalf(t)`. **Cả painter (vẽ cành) lẫn `bloomPositions` (neo blossom) PHẢI gọi nguồn này** → blossom đậu đúng mép cành, không lệch. Đây là điểm thay tương đương `canopyGeometry`/`_StageSpec` cũ.
4. **Renderer:** thêm `SakuraBranchPainter` (cành+nụ+lá) + đổi painter cánh/nhuỵ trong `_LoveFlower`; gói sau `SakuraBranchRenderer implements LoveTreeRenderer`; `kTreeRenderer = const SakuraBranchRenderer()`. GIỮ `PaintTreeRenderer`/`LoveTreePainter` cũ trong file (rollback 1 hằng) — KHÔNG xoá.
5. **Hit-area ≥44:** GIỮ `_flowerHitPad` + `GestureDetector(HitTestBehavior.opaque)` quanh blossom (Positioned đã offset theo pad). Blossom mép cành so le 2 bên có thể gần nhau → đảm bảo hit-box không chồng gây tap nhầm: nếu 2 blossom quá sát (khoảng cách tâm < 36px) thì offsetMag (§B.1) đẩy thêm để giãn — nhưng vẫn deterministic.
6. **`shouldRepaint` cành:** chỉ true khi `stage/season/skeleton` đổi (như `LoveTreePainter` cũ). Blossom overlay ngoài painter → thêm blossom KHÔNG repaint cành.
7. **Reduce Motion:** mọi nhánh tĩnh phải còn (cành/blossom/nụ/lá gradient tĩnh + cánh rơi tĩnh + coach tĩnh + banner tĩnh). Reuse `AppMotion.reduceMotion(context)`.
8. **No-regression:** sau pivot, kiểm lại bấm blossom → `MomentSheet` đúng kind (#1), thẻ Khoe cây (#3), sky 4 giờ + 4 mùa (#2), coach 1-lần + caption, deep-link, bloom-anim + lastSeen. Đổi giờ/tháng máy để test sky/mùa.
9. **Clamp tràn:** blossom + cành phải nằm gọn trong khu cây (không clip mép) ở mọi stage + mọi tỉ lệ màn (test máy nhỏ + xoay). `Stack(clipBehavior: Clip.none)` giữ cho hit-box, nhưng vị trí blossom phải clamp (§B.1) để KHÔNG bông nào nằm ngoài.

---

## §J — Acceptance criteria (v2.2 — khớp PO + bổ sung design)

1. **Nhìn ra ngay là cành hoa anh đào** đẹp/thanh thoát, hợp tông hồng — KHÔNG còn blob xanh-lá clip-art, KHÔNG thân-Y chunky. Cành nâu ấm mảnh + blossom hồng-trắng + nhuỵ vàng-kem.
2. **Blossom đính gọn DỌC cành** (sát mép cành, so le 2 bên), KHÔNG lơ lửng/clip ra ngoài khu cây ở mọi stage + tỉ lệ màn. Số blossom = số mốc (flowerCount).
3. **Blossom deterministic:** rebuild / xoay máy / mở lại → blossom cũ KHÔNG nhảy chỗ (`_bloomHash` per-index, không `Random`). Blossom mới rơi về phía ngọn cành.
4. **5 cánh khía sakura + gradient tâm-trắng→edge(kind)** + nhuỵ vàng-kem + icon kind nhỏ ở tâm (heart/flash/gallery, GIỮ), **KHÔNG viền chip cứng** (glow mềm). 3 kind phân biệt tông cánh (hồng/coral/lavender).
5. **5 stage phân biệt:** seed cành-trơ-2-nụ-kín → sprout cành-ngắn-vài-blossom → young +nhánh → green +nhánh-blossom-dày-lá-điểm → bloom nở-rộ-cánh-rơi. Cành dài/đầy + số nhánh tăng theo flowerCount.
6. **No-regression:** bấm blossom → `MomentSheet` đúng kind (#1); thẻ "Khoe cây" (vẽ cành) (#3); sky 4 giờ + đêm sao/đom-đóm; 4 mùa phân biệt (cánh rơi xuân/bloom); coach 1-lần trỏ blossom đỉnh cành + caption thường trực; deep-link; bloom-anim + confetti + `lastSeen` bloom-once.
7. **Hit-area ≥44** mỗi blossom (kể cả blossom mép scale 0.82); tap không nhầm bông kế.
8. **Reduce Motion ON:** 0 chuyển động (sway/cánh-rơi-động/đom-đóm/bloom-anim/coach-ripple tắt) → cành + blossom + nụ + lá + cánh-rơi-tĩnh + sao tĩnh đẹp; coach tĩnh; banner tĩnh. Vẫn set cờ/lastSeen.
9. **Token brand:** nền dawnBlush; bark nâu-ấm-không-xám; cánh/nhuỵ/nụ/lá theo bảng §F; 100% CustomPaint, KHÔNG asset/dependency mới. Renderer tách sau `SakuraBranchRenderer implements LoveTreeRenderer` (giữ `PaintTreeRenderer` rollback); cành-geometry là 1 nguồn chung cho painter + bloomPositions (Dev ghi `dev.md`).
10. **i18n:** 0 key mới (tái dùng key cũ); `fvm flutter analyze` sạch; không hardcode chuỗi; không vỡ dấu TV.

---

## Changelog
- [2026-06-14] [Designer] Tạo design spec đầy đủ LoveTreeScreen: layout + wireframe, 5 stage cây (path/shape, hex thân/lá từng stage), hoa 5-cánh + nhuỵ-đĩa-Lucide 3 loại (ngày/streak/ảnh), thuật toán rải hoa xác định (golden-angle + jitter theo index), animation nở hoa (scale/pop/sparkle stagger + reduceMotion), "Cùng vun đắp" 3 InkTile, list cột mốc đã-nở/kế-tiếp, 6 states (0 hoa/hoa mới/nở rộ/loading/error/waiting-no-couple), token hex/size đầy đủ, copy vi+en (30 key), 12 acceptance criteria. Xác nhận dựng 100% bằng CustomPaint/shape — KHÔNG cần asset art.
- [2026-06-18] [Designer] Thêm "## Design Spec v2" (3 cải tiến: #1 bottom sheet "Khoảnh khắc này" bấm hoa = bản đồ ký ức 4 biến thể days/photos/streak/locked tái dùng pattern sheet chuẩn; #2 cây sống động = 4 lớp trời theo giờ + 4 mùa theo tháng + sao/đom đóm/bướm/sway idle với token hex + Reduce Motion matrix chính xác; #3 thẻ "Khoe cây" 4:5 off-screen RepaintBoundary→PNG→share_plus với layout/gradient/typography tự chứa + 2 entry point). Token hex/size đầy đủ, copy vi+en (~14 key mới), edge cases, Dev notes giữ-logic. KHÔNG sửa milestone math / data source.
- [2026-06-18] [Designer] Thêm "# Design Spec v2.1" (A nâng cấp CustomPaint + B coach mark). **(A)** Cây: thân/cành bézier cong + gradient ngang tạo khối + vân thân; tán 3 lớp back/mid/front (đa sắc xanh, mid GIỮ `canopyCenter`/`canopyR` cũ → hoa không lệch) + bóng mềm + lá 3-stop; seed/sprout nâng cấp (lá ±32°, giọt sương, bóng gốc). Hoa: 6 cánh 2 lớp (lớp sau xoay +30° scale .86) + gradient cánh 3-stop tâm sáng + bóng dưới hoa; nhuỵ disc highlight radial + viền trong + icon shadow (GIỮ `nucleusD`/icon kind). Đề xuất ranh giới `LoveTreeRenderer` (paintTree + flowerWidget, contract neo `canopyGeometry`/hộp diameter) cho v3 drop SVG/Lottie. **(B)** Coach mark 1-lần/cặp (Hive `love_tree_coach_<coupleId>`): ripple `accentLoveDeep` + tap-dot + tooltip navy .92 chữ trắng trỏ bông gần ĐỈNH tán (dy nhỏ nhất), delay sau bloom, ẩn khi chạm/4s, Reduce-Motion → tĩnh; caption thường trực dưới cây "Chạm vào mỗi bông…" khi ≥1 hoa. Token hex/size/duration đầy đủ; 2 key l10n vi+en (`loveTreeCoachTooltip`/`loveTreeTapHint`); 10 AC; Dev notes 9 mục giữ-logic. GIỮ NGUYÊN: milestone math, bloom positions, stage thresholds, sky/season, MomentSheet, share, lastSeen.
- [2026-06-18] [Designer] Thêm "# Design Spec v2.2 — CÀNH HOA ANH ĐÀO" (pivot visual: bỏ cây-tán-blob-xanh → cành sakura nghiêng). **§A Hình học cành:** cành chính 1 cubic bézier mọc đáy-trái P0(.16,.96)→ngọn P3(.74,.20) cong chữ-S, dày thuôn gốc→ngọn (FILL-outline + gradient vuông góc tạo khối, KHÔNG stroke đều), bark nâu ấm `#A8755C→#724631` (không xám); nhánh phụ bézier rẽ tại tBranch (young 1 / green 2 / bloom 3 nhánh); 5 stage = tEnd 0.34→1.0 + số nhánh + mật độ blossom (bảng `_BranchSpec` tEnd/wBase/wTip/bark/nhánh/bud/leaf). seed=cành trơ + 1–2 NỤ KÍN (thay 2 lá-mầm). **§B Anchor blossom DỌC cành** (thay scatter golden-angle): phân bổ blossom vào segments theo độ dài, base_t dàn đều + jitter t/độ-lệch CỐ ĐỊNH qua `_bloomHash` (deterministic, không Random), lệch vuông góc ±(wHalf+r) so le 2 bên + clamp trong canvas; `canopyGeometry` đổi nghĩa center=ngọn cành/radius notional, `_coachTargetIndex` GIỮ. **§C Blossom vẽ lại:** 5 cánh sakura có KHÍA chữ-V đỉnh + gradient 3-stop `#FFF0F4→#FFD6E0→petalEdge(kind)` + bóng dưới hoa; nhuỵ = glow mềm (BỎ viền chip) + 6–7 chấm tua vàng-kem `#FFE6A8` (đặc trưng sakura) + đĩa tâm + icon kind NHỎ trắng ở tâm (GIỮ nucleusIcon/Color); nụ kín; lá sakura xanh-ngả-hồng RẤT ít (green/bloom); ambient = CÁNH sakura rơi (thay lá); sky 4 giờ + 4 mùa GIỮ, nghiêng tông sakura/xuân. **§D Ranh giới `SakuraBranchRenderer implements LoveTreeRenderer`** (giữ interface, đổi `kTreeRenderer`, giữ PaintTreeRenderer rollback); contract: 1 nguồn `SakuraBranchGeometry` chung cho painter + bloomPositions (blossom đậu đúng mép cành). Token §F hex đầy đủ; **0 key l10n mới** (tái dùng key cũ — metaphor "cây/nở hoa" vẫn dùng cho sakura); 10 AC; Dev notes 9 mục. GIỮ NGUYÊN: milestone math, thresholds, tap→MomentSheet, share, sky/season, coach/caption, deep-link, bloom-anim/lastSeen, hit≥44, Reduce-Motion.
