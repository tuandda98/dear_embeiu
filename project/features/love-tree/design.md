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

## Changelog
- [2026-06-14] [Designer] Tạo design spec đầy đủ LoveTreeScreen: layout + wireframe, 5 stage cây (path/shape, hex thân/lá từng stage), hoa 5-cánh + nhuỵ-đĩa-Lucide 3 loại (ngày/streak/ảnh), thuật toán rải hoa xác định (golden-angle + jitter theo index), animation nở hoa (scale/pop/sparkle stagger + reduceMotion), "Cùng vun đắp" 3 InkTile, list cột mốc đã-nở/kế-tiếp, 6 states (0 hoa/hoa mới/nở rộ/loading/error/waiting-no-couple), token hex/size đầy đủ, copy vi+en (30 key), 12 acceptance criteria. Xác nhận dựng 100% bằng CustomPaint/shape — KHÔNG cần asset art.
