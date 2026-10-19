# 🎨 Design — Chọn giúp chúng mình (decision-wheel)

> Designer sở hữu. Đọc `overview.md` trước (D1–D15 đã chốt, file này không lật). Bám `project/design-system.md` + primitives `lib/widgets/`. CHỈ thiết kế, không code.
> Mockup bấm thử: [`docs/design/decision-wheel-mockup.html`](../../../docs/design/decision-wheel-mockup.html) (mở thẳng file trong trình duyệt, có nút đổi vi/en).

- **Trạng thái design:** xong, chờ PO duyệt
- **Người/role:** Designer
- **Ngày:** 2026-10-19

## 1. Mục tiêu thiết kế

- Từ lúc "tối nay ăn gì?" tới lúc người ấy nhận kết quả: **2 chạm** (Quay trên thẻ Home → Chốt luôn). Màn quay tự quay ngay khi mở từ nút Quay.
- Quay là trò vui ngắn, không phải màn chờ: **0,9 giây**, rơi đúng vào kết quả, rung nhẹ khi dừng. Reduce Motion thì hiện kết quả ngay.
- Kết quả đọc được trong 1 giây ở Home: "🍢 Bún chả · Thảo quay · 17:02".
- Một khuôn cho cả 3 chế độ: người dùng học 1 lần (thanh chế độ → chip lọc → ô quay → nút).
- Không thêm token mới. Mọi thứ dựng từ `ContentCard`, `SubScreenHeader`, `SectionHeader`, `InkTile`, `IconBadge`, `EyebrowChip`, nút pill h52, `ShimmerSkeleton`, `MidnightBuilder`.

## 2. Phạm vi / màn hình

| # | Bề mặt | Loại | Vào từ |
|---|---|---|---|
| A | Thẻ Home "Phân vân gì không?" | widget `DecisionCard` trong Home, sau `MoodCard`, trước `SleepCard` | Home |
| B | Sheet kết quả | modal bottom sheet | chạm dòng có kết quả ở thẻ A |
| C | Màn quay `DecisionWheelScreen` (3 chế độ) | màn con, `SubScreenHeader` | nút Quay / Nhập & quay ở A, Quay lại ở B, CTA empty state ở D |
| C2 | Sheet "Nhập tay" | modal bottom sheet | link Nhập tay ở C (chế độ Ăn gì / Đi đâu) |
| D | Màn lịch sử `DecisionHistoryScreen` | màn con, `SubScreenHeader` | link "Đã quay" ở header thẻ A và ở sheet B |
| E | Tile nhắc trong Cài đặt → nhóm Thông báo | hàng trong `ContentCard` nhóm | Settings |

Ngoài phạm vi design đợt này: widget màn hình chính (thuộc `widget-today`), push/inbox (copy đã cố định ở D5).

## 3. User flow

```
A (Thảo) phân vân tối nay ăn gì
  Home ─ thẻ "Phân vân gì không?" ─ dòng "Ăn gì?" [Quay]
     │ chạm
     ▼
  DecisionWheelScreen (chế độ Ăn gì, chip Tuỳ)
     │ tự quay 0,9s ─► "🍢 Bún chả · Ăn ngoài · nhanh gọn"
     ├─ không ưng ─► [Quay lại] (local, quay bao nhiêu cũng được, không push)
     ├─ muốn món khác hẳn ─► "Nhập tay" ─► sheet gõ "Bánh xèo" ─► [Chốt luôn]
     └─ [Chốt luôn] ─► ghi decisions/{date}_eat ─► pop về Home
                         SnackBar "Đã chốt, đã báo Tuấn" [Chụp lại]
                         Dòng "Ăn gì?" đổi thành "🍢 Bún chả · Mình quay · 17:02"

B (Tuấn) nhận push "Thảo quay ra: hôm nay ăn Bún chả"
  chạm push ─► Home, cuộn tới thẻ ─► dòng "Ăn gì?" hiện "🍢 Bún chả · Thảo quay · 17:02"
     │ chạm dòng
     ▼
  Sheet kết quả: 🍢 to · "Bún chả" · "Thảo quay lúc 17:02"
     ├─ [Chụp lại] ─► CreatePostScreen, caption "Bún chả 🍢"
     ├─ link "Đã quay" ─► DecisionHistoryScreen
     └─ [Quay lại] ─► DecisionWheelScreen (Ăn gì) tự quay
              ─► "🍲 Lẩu thái" ─► [Chốt luôn] (dòng "Đang chốt: Bún chả" báo trước là sẽ đổi)
              ─► cùng doc, spins 2 ─► Thảo nhận "Tuấn quay lại: Lẩu thái"
                 Thẻ cả 2 máy: "🍲 Lẩu thái · Tuấn quay · 17:20 · ×2"

Tự nhập: dòng "Phân vân khác" [Nhập & quay] ─► màn quay chế độ Tự nhập
  gõ "Ai rửa bát?" ─► "Ai làm?" điền [Thảo] [Tuấn] ─► [Quay] ─► "Tuấn" ─► [Chốt luôn]
```

## 4. Soát UX (UI UX Pro Max)

Skill bản `2.13.0`, chạy `scripts/search.py` (không `-I`) ngày 2026-10-19. Đối chiếu thêm `references/quick-reference.md` mục 7–9.

| Truy vấn (domain) | Kết quả skill | Áp vào thiết kế |
|---|---|---|
| `segmented control tabs mode switch` (ux) | *Cancellable State Transitions*: đổi nhanh phải huỷ chuyển động cũ, đặt state cuối trực tiếp | Đổi chế độ khi đang quay: huỷ quay, ô quay về trạng thái chờ của chế độ mới. State chế độ đổi NGAY, thumb trượt theo sau (260ms) |
| `filter chips selection` (ux) | *Chip Collection Reflow*: chip phải wrap, không cắt 1 hàng; *Compact Control Semantics*: chip bấm được phải có role + trạng thái selected | Chip lọc `Wrap` (spacing 8, run 8), không cuộn ngang. Semantics `button` + `selected`. Chip lọc (chọn 1) khác hẳn chip lựa chọn (giá trị có nút xoá) về hình |
| `reduced motion animation` (ux) | Tôn trọng Reduce Motion; *Excessive Motion*: tối đa 1–2 chuyển động chính/màn; *Duration Timing*: dùng token chung | Một chuyển động chính duy nhất: ô quay. Reduce Motion → kết quả hiện ngay, không cuộn, không placeholder xoay. Các chuyển trạng thái khác dùng `AppMotion` (200/280/320 easeOutCubic) |
| `loading spinner randomize animation duration` (ux) + quick-ref `easing`, `interruptible`, `no-blocking-animation` | Đến nơi thì giảm tốc; hoạt ảnh phải ngắt được; không chặn input | Ô quay chạy `Curves.easeOutCubic` (giảm tốc khi về đích). Chạm ô quay hoặc nút Quay lại khi đang quay → nhảy thẳng tới kết quả. Không khoá màn |
| `chip input add remove tags` (ux) | Mỗi input có nhãn hiện rõ, không dùng placeholder làm nhãn | Ô câu hỏi có nhãn "Phân vân chuyện gì?"; placeholder xoay chỉ là ví dụ. Ô thêm lựa chọn có nhãn "Các lựa chọn" + bộ đếm |
| `bottom sheet modal dismiss` (ux) + quick-ref `modal-escape`, `sheet-dismiss-confirm` | Sheet phải đóng được rõ ràng, vuốt xuống để đóng; hỏi lại nếu bỏ dở dữ liệu | Sheet kết quả + sheet Nhập tay có tay nắm, vuốt xuống đóng. Sheet Nhập tay: ≤40 ký tự, mất cũng không đau → KHÔNG hỏi lại. Màn Tự nhập rời đi khi đã gõ ≥1 lựa chọn → KHÔNG hỏi (D7: không lưu nháp, quay là việc vài giây) |
| `empty state` (ux) | Có lời hướng dẫn + hành động | Lịch sử trống: icon + 1 câu + nút "Quay thử". Dòng thẻ Home trống: luôn có nút |
| `touch target spacing` (ux) | iOS 44pt / Android 48dp; khoảng cách ≥8 | Mọi vùng chạm ≥44 (chip cao 40 nhưng vùng chạm 44 qua `materialTapTargetSize`/padding); nút cạnh nhau cách 12; chip cách 8 |
| `infinite scroll pagination list` (ux) | Không có luật riêng cho cuộn vô hạn; chỉ nhắc spinner cho loader | Theo khuôn `care_timeline`: tải 30, gần đáy tải tiếp, spinner 22 ở cuối |
| `disabled button state` (ux) + quick-ref `disabled-states` | Disabled phải khác rõ (opacity .38–.5) + thuộc tính ngữ nghĩa | Nút khoá: nền navy α.28, chữ trắng α.70 (đúng khuôn nút Gửi của `care_message`), kèm dòng giải thích vì sao khoá ngay dưới |
| `romantic couple app pink` (color) | Palette "Couple & Relationship App": primary #BE185D, foreground navy | Không đổi palette (giữ Sunset Romance). Chỉ xác nhận hướng: chữ chính màu tối trên nền hồng nhạt, không chữ trắng trên hồng |
| `live region announce result screen reader` (ux) | Một thông báo trạng thái gói gọn, không đọc từng con số lẻ | Ô quay: `Semantics(liveRegion)` chỉ đọc 1 lần khi dừng ("Kết quả: Bún chả, ăn ngoài, nhanh gọn"); trong lúc quay `ExcludeSemantics` |
| `error retry offline` (ux) + quick-ref `error-recovery`, `timeout-feedback` | Lỗi nói rõ nguyên nhân + đường thoát | Chốt lỗi: giữ kết quả trên màn, dải báo lỗi ngay trên nút + nút chính đổi thành "Thử lại" |
| `--stack flutter`: `animation reduce motion`, `animation duration`, `semantics accessibility live region` | Dispose controller; implicit animation cho chuyển đơn giản; `Semantics`; hỗ trợ `TextScaler` | Ô quay dùng 1 `AnimationController` (dispose); chuyển nút/chip dùng `AnimatedSwitcher`/`AnimatedContainer`; nhãn thanh chế độ `FittedBox.scaleDown` khi chữ to |
| `--stack flutter`: `bottom sheet`, `modal sheet`, `SegmentedButton` | **Không có kết quả trong DB** (đã thử lại 2 cách viết) | Dùng khuôn có sẵn trong app: sheet của `MoodCard`, thanh chế độ trượt của `setup_screen` |

**Soát chung các nút đứng cạnh nhau (1 lượt):**

| Cụm | Vai | Hình | Vì sao |
|---|---|---|---|
| Màn quay sau khi có kết quả: **Quay lại** · **Chốt luôn** · **Nhập tay** | phụ · chính · cấp 3 | Hàng 2 nút h52 cách 12: trái = pill viền navy .18 nền trắng .72 (flex 2), phải = pill navy đặc (flex 3). Dưới: link chữ 14 w700 navy, cao 44 | Hai lựa chọn ngang hàng ý nghĩa (đổi / chốt) nên đứng cạnh nhau; chốt nặng hơn về màu và bề ngang. Nhập tay là lối thoát hiếm dùng → chữ. Cùng chiều cao 52 nên không lệch đường chữ |
| Màn quay trước khi quay: **Quay** | chính duy nhất | Pill navy h52 full-width, icon `shuffle` | Lúc này chưa có gì để chốt |
| Sheet kết quả: **Quay lại** · **Chụp lại** · **Đã quay** | phụ · chính · cấp 3 | Giống hệt cụm trên (viền / navy / link) | Cùng khuôn với màn quay để tay quen. Chụp lại là chính vì dẫn tới ảnh (North Star) |
| Thẻ Home: **Quay** (2 dòng) · **Nhập & quay** (1 dòng) | gợi ý hành động trên dòng | Cùng 1 khuôn pill nhỏ: cao 36, đệm ngang 14, nền `accentRose` α.10, chữ navy 13 w700, icon 16. KHÔNG phải vùng chạm riêng, cả dòng mới là vùng chạm | 3 dòng đặt chồng nhau → pill phải y hệt nhau, chỉ khác chữ. Không gradient hồng (chữ trắng trên `sunsetRomance` chỉ 2,68:1) |
| Sheet Nhập tay: **Chốt luôn** | chính duy nhất | Pill navy h52 full-width | |

**Màu trên dawnBlush (đo bằng công thức WCAG):** navy `#1A1A2E` đạt 8,3–11,2:1 trên 3 điểm dừng gradient; `textSecondary #6B6B7B` chỉ 2,55–3,43:1 → **CẤM** dùng cho chữ đặt thẳng trên nền blush (nhãn ngày lịch sử, câu mô tả empty state dùng navy hoặc navy α.72). Trong card trắng: `textSecondary` 5,23:1 ✓, `textTertiary #A0A0B0` 2,58:1 → chỉ cho icon trang trí, không cho chữ cần đọc. `accentLoveDeep` 4,13:1 trên trắng → không dùng cho chữ ≤14.

## 5. Wireframe

### A. Thẻ Home "Phân vân gì không?" (390 rộng, gutter 16)

```
┌──────────────────────────────────────────────┐  ContentCard r24, padding 0
│ [≋] Phân vân gì không?            Đã quay   │  header: pad 16/16/8/8
│                                              │
│ ┌──┐ Ăn gì?                       ( ⤨ Quay ) │  dòng TRỐNG, min-h 64
│ └──┘ Chưa ai quay hôm nay                    │
│ ─────────────────────────────────────────── │  hairline indent 72
│ ┌──┐ HÔM NAY MÌNH                            │  dòng CÓ KẾT QUẢ, min-h 72
│ └──┘ ☕ Đi cà phê                          ›  │
│      Tuấn quay · 17:02 · ×2                  │
│ ─────────────────────────────────────────── │
│ ┌──┐ Phân vân khác               (✎ Nhập & quay)│
│ └──┘ Ai rửa bát, xem phim gì…                │
└──────────────────────────────────────────────┘
```

Dòng "Phân vân khác" khi có kết quả:
```
│ ┌──┐ Ai rửa bát?                             │  câu hỏi custom = dòng nhãn (không uppercase)
│ └──┘ Tuấn                                  › │
│      Thảo quay · 21:40 · +2 câu khác         │
```

Đang tải (provider chưa có dữ liệu hôm nay):
```
│ ┌──┐ Ăn gì?                                  │
│ └──┘ ▒▒▒▒▒▒▒▒▒▒▒ (shimmer 120×12)            │
```

### B. Sheet kết quả

```
┌──────────────────────────────────────────────┐ r28 trên, nền trắng
│                    ▬▬▬                       │ tay nắm 40×4
│               ⊙ HÔM NAY ĂN                   │ eyebrow 11 w700 textSecondary
│                  ╭──────╮                    │
│                  │  🍢  │                    │ đĩa 96, rose α.10, emoji 56
│                  ╰──────╯                    │
│                 Bún chả                      │ 26 w700 navy, ≤2 dòng
│          Ăn ngoài · nhanh gọn                │ 13 w600 textSecondary
│        Thảo quay lúc 17:02 · quay 2 lần      │ 12 textSecondary
│                                              │
│ ( ↻ Quay lại )      [ 📷 Chụp lại        ]   │ h52, flex 2 : 3, gap 12
│                 🕘 Đã quay                    │ link 14 w700 navy, h44
└──────────────────────────────────────────────┘
```
Custom: eyebrow = câu hỏi giữ nguyên chữ người gõ ("Ai rửa bát?", 14 w700 textSecondary, không uppercase); đĩa 96 chứa icon `message_question` Bold 40 navy thay emoji; dòng tag = "1 trong 2 lựa chọn"; dưới link "Đã quay" thêm link "Phân vân câu khác" (cùng hàng, 2 link cách 24).

### C. Màn quay — chế độ Ăn gì

```
 ←              ⤨ CHỌN GIÚP                       SubScreenHeader (pinned)
┌──────────────────────────────────────────────┐
│ [▣ Ăn gì ] │  ⌖ Đi đâu  │  ⁇ Tự nhập          │ thanh chế độ h48 r20
└──────────────────────────────────────────────┘
 (Tuỳ✓) (Nhà nấu) (Ăn ngoài) (Nhanh gọn)          chip lọc, Wrap
┌──────────────────────────────────────────────┐
│                HÔM NAY ĂN                    │ ContentCard r24 pad 20
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ ← mờ dần
│                   🍢                         │ cửa sổ quay h128
│                 Bún chả                      │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ ← mờ dần
│            Ăn ngoài · nhanh gọn              │ tag 13 w600
└──────────────────────────────────────────────┘
   Đang chốt: Phở bò                              (chỉ khi hôm nay đã có) 12 navy α.72
                        ...
─────────────────────────────── (vùng nút ghim đáy, trên safe area)
 ( ↻ Quay lại )          [ ✓ Chốt luôn        ]
                  ✎ Nhập tay
```

Trước khi quay (chuyển chế độ bằng tay, hoặc chưa có kết quả):
```
│                HÔM NAY ĂN                    │
│                  ╭────╮                      │ đĩa 64 surfaceLight
│                  │ ⤨  │                      │ icon shuffle 28 navy α.40
│                  ╰────╯                      │
│        Bấm quay, app chọn món giúp           │ 15 w600 textSecondary
 ─────────────
 [ ⤨ Quay                                     ]  pill navy full-width h52
                  ✎ Nhập tay
```

Lỗi khi chốt:
```
 ┌ ⚠ Chưa chốt được. Mạng chập chờn, thử lại nhé ┐  dải r16 nền error α.08, chữ navy 13
 ( ↻ Quay lại )          [ ↻ Thử lại          ]
```

### C. Màn quay — chế độ Tự nhập

```
 ←              ⤨ CHỌN GIÚP
 [ ▣ Ăn gì ] [ ⌖ Đi đâu ] [▣ ⁇ Tự nhập ]
┌──────────────────────────────────────────────┐ ContentCard (form)
│ Phân vân chuyện gì?                          │ nhãn 13 w700 textSecondary
│ ┌──────────────────────────────────────────┐ │
│ │ Đà Lạt hay Vũng Tàu?          (xoay 3s)  │ │ ô r16 surfaceLight, ≤60
│ └──────────────────────────────────────────┘ │
│ Điền nhanh                                   │
│ (👥 Ai làm?)  (☑ Cái nào?)                    │ chip hành động
│                                              │
│ Các lựa chọn                           2/12  │
│ (Thảo  ⊗) (Tuấn  ⊗)                          │ chip giá trị, Wrap
│ ┌────────────────────────────────────┐ (+)   │ ô thêm + đĩa navy 44
│ │ Thêm lựa chọn                      │       │
│ └────────────────────────────────────┘       │
│ ⓘ Cần ít nhất 2 lựa chọn để quay             │ chỉ khi <2
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐ ContentCard (ô quay)
│                Ai rửa bát?                   │
│                   Tuấn                       │
│             1 trong 2 lựa chọn               │
└──────────────────────────────────────────────┘
 ( ↻ Quay lại )          [ ✓ Chốt luôn        ]
```
Tự nhập không có chip lọc, không có link Nhập tay. Ô quay chỉ hiện khi đã có ≥2 lựa chọn.

### C2. Sheet Nhập tay

```
┌──────────────────────────────────────────────┐
│                    ▬▬▬                       │
│              Mình muốn ăn…                   │ 22 w700 navy
│ ┌──────────────────────────────────────────┐ │
│ │ Ví dụ: Bánh xèo                    12/40 │ │ autofocus
│ └──────────────────────────────────────────┘ │
│ [ ✓ Chốt luôn                              ] │ khoá khi rỗng
└──────────────────────────────────────────────┘
```

### D. Màn lịch sử "Đã quay"

```
 ←              🕘 ĐÃ QUAY
┌─────────────────────┐ ┌─────────────────────┐  2 ContentCard, gap 12
│ ▣ Hay ăn            │ │ ⌖ Hay đi            │  16 w800 navy
│ 90 ngày qua         │ │ 90 ngày qua         │  12 textSecondary
│ 1 🍢 Bún chả     6  │ │ 1 ☕ Đi cà phê    4  │  13 w600, số 12 w700 tabular
│ 2 🍜 Phở bò      4  │ │ 2 📺 Xem phim…    3  │
│ 3 🍲 Lẩu thái    3  │ │ 3 🌳 Đi dạo…      2  │
│ 4 …                 │ │                     │
└─────────────────────┘ └─────────────────────┘
 Gần đây                                          SectionHeader 22 w700 navy
 HÔM NAY                                          12 w700 navy, ls .4
┌──────────────────────────────────────────────┐ 1 ContentCard / ngày
│ ┌──┐ 🍢 Bún chả                          ×2  │
│ └──┘ Tuấn quay · 17:20                       │
│ ─────────────────────────────────────────── │
│ ┌──┐ Ai rửa bát?                             │ câu hỏi 12 w600 textSecondary
│ └──┘ Tuấn                                    │
│      Thảo quay · 21:40                       │
└──────────────────────────────────────────────┘
 HÔM QUA
┌──────────────────────────────────────────────┐
│ …                                            │
                    ◌  (tải trang tiếp)
```

Trống:
```
 ←              🕘 ĐÃ QUAY

                  ╭──────╮
                  │  ⤨   │        đĩa 88 trắng α.5, icon 38 accentLove
                  ╰──────╯
              Chưa quay lần nào              20 w700 navy
   Lần tới phân vân ăn gì, đi đâu, ai rửa bát,   14 navy α.72
   cứ để app chọn. Chốt xong sẽ hiện ở đây.
              [ ⤨ Quay thử ]                 pill navy h52
```

### E. Tile nhắc trong Cài đặt → Thông báo

```
┌──────────────────────────────────────────────┐ ContentCard nhóm Thông báo
│ [💬] Nhắc trả lời câu hỏi              (●)  │ tile có sẵn
│ ─────────────────────────────────────────── │
│ [▣] Nhắc chọn món                      (●)  │ tile MỚI, cùng khuôn
│     Chưa ai chốt món hôm nay thì nhắc       │
│     lúc này                                  │
│  ┌ 🕓 16:30                              ┐   │ hàng giờ, rose α.06 r16
│ ─────────────────────────────────────────── │
│ [🔔] Lời nhắc                         ›     │ tile có sẵn
└──────────────────────────────────────────────┘
```

## 6. Spec chi tiết (token)

### Chung
- Nền màn C, D: `dawnBlush` (#FFC1CC → #E8B4D8 → #C8A8E9, topLeft→bottomRight), `Scaffold` trong suốt, `SafeArea(bottom:false)`.
- Header: `SubScreenHeader(badge, badgeIcon)` ghim trên, padding `16,16,16,0` (giống `care_timeline_screen`). C: `decisionBadge` + `IconsaxPlusLinear.shuffle`. D: `decisionHistoryBadge` + `IconsaxPlusLinear.clock`.
- Card trắng: `ContentCard` (#FFFFFF, r24, shadow black α.06 blur 16 offset 0,10).
- Font Quicksand, chỉ cỡ trong scale: 11 · 12 · 13 · 14 · 15 · 16 · 20 · 22 · 26.
- Ripple: rose α.08 (splash) / love α.06 (highlight) trên nền sáng.

### Màu theo chế độ (chỉ cho icon, không cho chữ)
| Chế độ | Icon Linear / Bold | Tint `IconBadge` | Tương phản icon/trắng |
|---|---|---|---|
| Ăn gì `eat` | `reserve` | `accentRose` #FF4D6D | 3,21:1 (đồ hoạ ≥3 ✓) |
| Đi đâu `go` | `location` | `accentLavenderDeep` #7C5CD6 | 4,82:1 ✓ |
| Tự nhập `custom` | `message_question` | `textPrimary` #1A1A2E | 17:1 ✓ |

### A. Thẻ Home
- `ContentCard(padding: EdgeInsets.zero)`. Khoảng cách với thẻ trên/dưới theo nhịp Home hiện có (trong nhóm 12).
- Header: padding `16,16,8,4`. `IconBadge(IconsaxPlusLinear.shuffle, tint: accentRose)` 44/r16/icon 20 → gap 12 → tiêu đề `decisionCardTitle` 16 w800 navy (giống `SleepCard`) → `TextButton` "Đã quay" 14 w700 navy, minimumSize 44×44, padding ngang 8.
- Dòng: `InkTile(borderRadius: 16)` bọc `Padding(16,12,16,12)`, min-height 64 (trống) / 72 (có kết quả).
  - Trái: `IconBadge(icon, tint, size: 40, radius: 14, iconSize: 20)`, gap 12.
  - Giữa (Expanded):
    - Trống: tiêu đề dòng 15 w700 navy · gap 2 · phụ đề 12 w500 `textSecondary`, 1 dòng ellipsis.
    - Có kết quả: nhãn 11 w700 `textSecondary` ls .8 UPPERCASE (`HÔM NAY ĂN` / `HÔM NAY MÌNH` / câu hỏi custom, câu hỏi KHÔNG uppercase, 12 w600) · gap 2 · kết quả 15 w700 navy, "emoji + khoảng trắng + tên", 1 dòng ellipsis · gap 2 · meta 12 w500 `textSecondary` ("Tuấn quay · 17:02", thêm " · ×2" khi spins>1, custom thêm " · +2 câu khác" khi hôm nay có >1 custom).
  - Phải: trống → pill gợi ý (h36, đệm ngang 14, r999, nền `accentRose` α.10, icon 16 navy + gap 6 + chữ 13 w700 navy); có kết quả → `IconsaxPlusLinear.arrow_right_3` 18 `textTertiary` (trang trí).
  - Hairline giữa các dòng: 1px `surfaceLight` #F5F0F5, indent trái 72, phải 16.
- Cuối thẻ: padding đáy 8.
- Thẻ bọc `MidnightBuilder` để 0:00 tự về trống.

### B. Sheet kết quả
- `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, backgroundColor: transparent)`; nền trắng r28 trên; padding `20,12,20,24`; nội dung `SingleChildScrollView` (chữ to không tràn). Khuôn y hệt sheet của `MoodCard`.
- Tay nắm 40×4 `textTertiary` α.4 r999 → gap 18.
- Eyebrow: 11 w700 ls 1.2 `textSecondary`, căn giữa (custom: câu hỏi nguyên văn 14 w700 `textSecondary`, tối đa 2 dòng).
- gap 16 → đĩa 96 tròn `accentRose` α.10, emoji 56 (custom: icon `IconsaxPlusBold.message_question` 40 navy; món/chỗ nhập tay không có emoji: icon Bold của chế độ 40, màu tint chế độ).
- gap 14 → kết quả 26 w700 navy, căn giữa, ≤2 dòng, letterSpacing -0.2.
- gap 6 → tag 13 w600 `textSecondary` · gap 4 → meta 12 w500 `textSecondary`.
- gap 24 → hàng nút: `Quay lại` (flex 2) · gap 12 · `Chụp lại` (flex 3).
- gap 8 → link "Đã quay" (icon `clock` 16 + chữ 14 w700 navy, minHeight 44). Custom: hàng 2 link cách 24 ("Đã quay" · "Phân vân câu khác").
- Nút viền (dùng chung toàn feature): h52 r999, nền trắng (trong sheet) / trắng α.72 (trên blush), viền 1.2 navy α.18, chữ 15 w700 navy, icon 18 navy.
- Nút chính: h52 r999 navy #1A1A2E, chữ trắng 15 w700, icon 18 trắng; disabled navy α.28 / chữ trắng α.70.

### C. Màn quay
- Body: `Column[ header, Expanded(SingleChildScrollView(padding 16,12,16,16)), _ActionBar ]`.
- **Thanh chế độ:** cao 48, r20, nền trắng α.55 + viền trắng α.65 1px. Thumb trắng đặc r16, inset 4, shadow black α.10 blur 8 offset 0,2, trượt `AnimatedPositioned` 260ms `easeInOutCubic` (khuôn `setup_screen._buildModeSelector`). Mỗi ô: icon 18 + gap 6 + nhãn 14; chọn = icon Bold + chữ w700 navy; chưa chọn = icon Linear + chữ w600 navy α.72 (≥5,79:1 trên mọi điểm của blush). Nhãn bọc `FittedBox(scaleDown)`.
- gap 14 → **chip lọc** (`Wrap` spacing 8, runSpacing 8): cao 40, đệm ngang 14, r999. Chưa chọn: nền trắng α.86, viền trắng α.65, chữ 14 w600 navy. Đã chọn: nền navy, chữ trắng 14 w700, icon `tick_circle` Bold 14 trắng bên trái. Vùng chạm 44 (thêm 2px trên/dưới vô hình). Chọn 1, mặc định "Tuỳ", nhớ theo phiên (không lưu đĩa).
- gap 16 → **thẻ quay** `ContentCard(padding 20)`:
  - Eyebrow 11 w700 ls 1.2 `textSecondary` căn giữa. Custom: câu hỏi người gõ (14 w700 `textSecondary`, không uppercase); câu hỏi rỗng → ẩn eyebrow.
  - gap 12 → **cửa sổ quay** cao 128, `ClipRect`, mép trên/dưới `ShaderMask` mờ 20px (trắng → trong suốt). Mỗi ô cao 128: emoji 40 · gap 8 · tên 22 w700 navy căn giữa ≤2 dòng (chữ to: `FittedBox.scaleDown`, không tăng chiều cao cửa sổ quá 160).
  - gap 10 → tag 13 w600 `textSecondary` (custom: "1 trong N lựa chọn").
- Dưới thẻ, khi hôm nay đã có kết quả cùng chế độ: "Đang chốt: Phở bò" 12 w600 navy α.72, căn giữa, gap 10 (để người quay lại biết là sẽ ghi đè).
- **Vùng nút** (ghim đáy): padding `16,8,16, 12 + bottomInset`; nền trong suốt; phía trên có dải mờ 24px blush → trong suốt để nội dung cuộn không đè chữ nút. Thứ tự: [dải lỗi nếu có] → hàng nút h52 → link Nhập tay h44 (chỉ eat/go).
- **Dải lỗi:** r16, nền `error` #EF5350 α.08, viền `error` α.24, padding 12, icon `cloud_cross` 18 `error` + chữ 13 w600 navy.
- **Chế độ Tự nhập**, `ContentCard(padding 20)` form:
  - Nhãn trường: 13 w700 `textSecondary` ls .2 (khuôn `_FieldLabel` của `care_message`).
  - Ô câu hỏi: filled `surfaceLight`, r16, không viền, padding 16/12, 16 w500 navy, `maxLength 60`, counter ẩn tới khi còn ≤10 ký tự (hiện "52/60" 12 `textSecondary` cuối ô).
  - "Điền nhanh" → chip hành động: cao 40, đệm 14, r999, nền `surfaceLight`, chữ 14 w600 navy, icon 16 navy (`profile_2user` / `task_square`), cách 8.
  - "Các lựa chọn" + bộ đếm "2/12" 12 w700 `textSecondary` tabular ở phải.
  - Chip giá trị: cao 40, r999, nền `accentRose` α.08, viền `accentRose` α.20, chữ 14 w600 navy (≤40 ký tự, 1 dòng, ellipsis ở 220px), nút xoá `close_circle` 18 `textSecondary` trong vùng chạm 44×40 (Semantics "Xoá Thảo"). Chạm vào chữ chip → đưa chữ về ô thêm để sửa (chip biến mất).
  - Ô thêm: như ô câu hỏi nhưng `maxLength 40`; bên phải đĩa tròn 44 navy, icon `add` 20 trắng (khoá: navy α.28). Enter/Done = thêm, giữ focus. Hint: "Thêm lựa chọn"; sau preset "Cái nào?": "Lựa chọn 1" rồi "Lựa chọn 2".
  - Dòng trợ giúp: icon `info_circle` 14 navy α.55 + chữ 12 w600 navy α.72. Hiện khi <2 ("Cần ít nhất 2 lựa chọn để quay"), khi =12 ("Đủ 12 lựa chọn rồi", ẩn ô thêm), khi trùng ("Lựa chọn này có rồi", 2,5 giây).
- **Sheet Nhập tay:** khuôn sheet B; tiêu đề 22 w700 navy; ô `maxLength 40`, counter "12/40" luôn hiện (12 `textSecondary`), autofocus, `textCapitalization.sentences`; gap 16 → nút chính "Chốt luôn" full-width, khoá khi chuỗi đã trim rỗng.

### D. Màn lịch sử
- Body: `RefreshIndicator(color: accentLove)` → `ListView` padding `16,12,16, 32+bottomInset`.
- **Hai khối top 5**: `Row` 2 `ContentCard(padding 16)` gap 12, cao bằng nhau (`IntrinsicHeight`). Khi `textScaler` >1.3 hoặc bề ngang <360 → xếp dọc. Trong khối: `IconBadge` 36/r12/icon 18 + tiêu đề 16 w800 navy · dưới 12 `textSecondary` "90 ngày qua" · gap 10 · tối đa 5 hàng cao 28: hạng 12 w700 `textSecondary` (rộng 16) · emoji 14 · tên 13 w600 navy ellipsis · số 12 w700 navy `FontFeature.tabularFigures`. Khối không có dữ liệu: "Chưa có gì" 12 `textSecondary`.
- gap 24 → `SectionHeader(title: "Gần đây")`.
- Nhãn ngày: 12 w700 **navy** ls .4 UPPERCASE ("HÔM NAY", "HÔM QUA", rồi `DateFormat.MMMEd(locale)`), padding trên 18 (0 với nhóm đầu), dưới 10. Không dùng `accentLove` như `care_timeline` (2,5:1 trên blush).
- Mỗi ngày = 1 `ContentCard(padding: 4/16)`; hàng: `IconBadge` 36/r12/icon 18 theo chế độ · gap 12 · cột (custom: câu hỏi 12 w600 `textSecondary` · kết quả 15 w700 navy "emoji tên" · meta 12 `textSecondary`) · phải: badge "×3" (cao 24, đệm 8, r999, nền `surfaceLight`, chữ 12 w700 navy) khi spins>1. Hairline 1px `surfaceLight` indent 48. Hàng KHÔNG bấm được.
- Ngày: nhóm theo `date` của bản ghi (ngày người tạo), không theo giờ máy người xem → 2 máy thấy cùng nhóm.
- Tải trang: spinner 22 stroke 2.2 `accentLove` ở cuối khi còn trang.

### E. Tile nhắc
- Chèn vào `_buildNotificationsSection`, NGAY SAU `_DailyQuestionReminderTile` + `_rowDivider()`, trước hàng "Lời nhắc".
- Khuôn y hệt `_DailyQuestionReminderTile`: padding dọc 12; `IconBadge(IconsaxPlusLinear.reserve)` (rose mặc định) · gap 14 · tiêu đề 15 w700 navy + phụ đề 12 `textSecondary` h1.4 · `Switch.adaptive(activeThumbColor: accentRose)`.
- Bật → gap 12 → 1 hàng giờ khuôn `_DailyQuestionTimeRow` (rose α.06, r16, icon `clock` 18 rose, giờ 15 w800 navy) KHÔNG có ✕, KHÔNG có "Thêm giờ". Chạm → `showAppTimePicker` (mặc định 16:30).
- Ẩn cả tile khi couple `waiting_partner` (D10 không nhắc khi chưa ghép đôi).

## 7. States

| Bề mặt | State | Hiển thị |
|---|---|---|
| A thẻ | Đang tải | Tiêu đề dòng hiện bình thường, phụ đề = `ShimmerSkeleton(width 120, height 12, r6)`, không có pill bên phải |
| A | Trống | Như wireframe; pill "Quay" / "Nhập & quay" |
| A | Có kết quả (của mình / của người ấy) | Như wireframe; meta "Mình quay" / "{tên} quay" |
| A | Chờ người ấy | Giống hệt couple active, meta luôn "Mình quay". Không thêm banner |
| A | Lỗi đọc Firestore | Fail-soft: hiện như Trống (vẫn quay + chốt được) |
| A | Qua 0:00 | `MidnightBuilder` vẽ lại → 3 dòng về Trống |
| A | Người ấy vừa chốt (realtime) | Nội dung dòng đổi bằng `AnimatedSwitcher` 280ms fade + size |
| B sheet | Hôm nay | Đủ 3 hành động |
| B | Kết quả của ngày khác (mở trễ sau 0:00) | Không xảy ra: thẻ đã về trống, sheet chỉ mở từ thẻ hôm nay |
| C màn quay | Chờ quay | Đĩa + câu mời; nút "Quay" chính |
| C | Đang quay | Cửa sổ chạy; nút giữ nguyên chỗ, "Quay lại" + "Chốt luôn" chưa hiện (vẫn là nút "Quay", chạm = nhảy tới kết quả) |
| C | Có kết quả | Tag hiện; nút "Quay lại" + "Chốt luôn" + link Nhập tay |
| C | Pool rỗng sau lọc (vd lọc "Nhà nấu" lúc 7h sáng hết món) | Không xảy ra ở ngân hàng hiện tại; nếu Dev thấy pool <1: ô quay hiện "Hết món hợp bộ lọc này, thử chip khác nhé", nút Quay khoá |
| C | Đang chốt | Nút chính hiện spinner trắng 20 stroke 2, cả 2 nút khoá, chip + thanh chế độ khoá |
| C | Chốt xong (có mạng) | `HapticFeedback.mediumImpact` → pop về Home → SnackBar 4s "Đã chốt, đã báo {tên}" + action "Chụp lại" |
| C | Chốt xong, chưa ghép đôi | SnackBar "Đã chốt, lưu vào lịch sử của chúng mình" + "Chụp lại" |
| C | Chốt lúc mất mạng, Firestore xếp hàng được | Coi như xong: pop + SnackBar "Đang mất mạng. Có mạng lại app gửi liền." Dòng thẻ hiện kết quả ngay (bản local) |
| C | Chốt lỗi (transaction không chạy được offline / lỗi khác) | Ở lại màn, kết quả giữ nguyên, dải lỗi hiện trên hàng nút, nút chính đổi chữ "Thử lại" (icon `refresh`). Đổi chế độ / quay lại → dải lỗi biến mất |
| C Tự nhập | <2 lựa chọn | Ô quay ẩn; nút "Quay" khoá + dòng trợ giúp |
| C Tự nhập | 12 lựa chọn | Ô thêm ẩn, dòng "Đủ 12 lựa chọn rồi" |
| C Tự nhập | Đã đủ 10 custom hôm nay | Nút "Chốt luôn" khoá, dòng trợ giúp "Hôm nay chốt đủ 10 câu rồi, mai quay tiếp nhé" (quay vẫn được) |
| C Tự nhập | Sửa lựa chọn sau khi đã có kết quả | Kết quả bị xoá (cũ không còn đúng) → về Chờ quay |
| C2 Nhập tay | Rỗng | Nút khoá |
| D lịch sử | Đang tải | 2 khối shimmer cao 168 + 3 shimmer 72 r24 |
| D | Trống | Như wireframe; ẩn 2 khối top |
| D | Lỗi | Khuôn `_TimelineMessage`: icon `cloud_cross`, "Chưa tải được lịch sử", nút "Thử lại" |
| D | Đang tải trang tiếp | Spinner cuối list |
| E tile | Tắt | Ẩn hàng giờ |
| E | Từ chối quyền thông báo | SnackBar `remindersPermissionDeniedMsg` (có sẵn), switch về tắt |
| E | Chờ người ấy | Ẩn tile |

## 8. Interaction & animation

**Hướng đã chọn: slot chữ chạy dọc (không dùng bánh xe).** Lý do:
1. Tên món dài ("Rau muống xào tỏi + trứng chiên", "Dọn nhà cùng nhau rồi gọi đồ ăn"). Bánh xe 117 lát không ghi được chữ, mà chỉ chữ mới cho người ta "đọc trước" lúc nó chạy.
2. Một khuôn cho cả 3 chế độ: pool 117 món, 62 hoạt động, hay 2 cái tên đều chạy y hệt. Bánh xe 2 lát trông trống, 117 lát trông như vạch.
3. Chuyển động thẳng đứng, nhỏ, nằm trong 1 cửa sổ. Bánh xe xoay toàn khối dễ gây chóng mặt hơn và chiếm nửa màn.
4. Cao cố định 128 → không xô lệch bố cục khi ra kết quả dài/ngắn.
5. Tên feature "wheel" vẫn giữ trong code, người dùng thấy chữ "Quay".

| Chuyển động | Thời lượng | Curve | Reduce Motion |
|---|---|---|---|
| Quay | **900ms**. Dải 14 ô (13 mục ngẫu nhiên lấy từ pool đã lọc + kết quả ở cuối), dịch Y từ 0 → −13×128 | `Curves.easeOutCubic` | Không cuộn: thay thẳng kết quả (Duration.zero) |
| Lúc dừng | thẻ quay scale 0.97 → 1.0, 220ms; tag fade-in 200ms | `easeOutBack` (scale), `easeOutCubic` (fade) | Bỏ scale, tag hiện ngay |
| Rung | `selectionClick` khi bấm Quay/Quay lại; `mediumImpact` khi dừng; `mediumImpact` khi chốt xong | | Giữ (rung không phải chuyển động) |
| Ngắt quay | Chạm cửa sổ quay hoặc nút Quay khi đang chạy → `controller.value = 1` (nhảy tới kết quả) | | |
| Đổi chế độ khi đang quay | Huỷ controller, xoá kết quả, state chế độ đổi ngay | | |
| Thumb thanh chế độ | 260ms | `easeInOutCubic` | Giữ (chuyển trạng thái) |
| Chip lọc đổi màu | 200ms (`AppMotion.fast`) | `easeOutCubic` | Giữ |
| Hàng nút Quay ↔ Quay lại + Chốt luôn | `AnimatedSwitcher` 200ms crossfade | `easeOutCubic` | Giữ |
| Thêm/xoá chip giá trị | `AnimatedSize` 200ms của `Wrap` + chip fade-in 160ms | `easeOutCubic` | Giữ |
| Placeholder câu hỏi xoay | đổi mỗi 3s, crossfade 200ms; dừng khi ô có focus hoặc có chữ | `easeOutCubic` | Không xoay, đứng ở ví dụ 1 |
| Dòng thẻ Home đổi kết quả | `AnimatedSwitcher` 280ms fade + `SizeTransition` | `easeOutCubic` | Giữ |
| Entrance thẻ Home | theo `EntranceReveal` hiện có của Home (index ngay sau MoodCard) | | `EntranceReveal` tự lo |
| Sheet | mặc định `showModalBottomSheet` | | |

Logic ô quay (cho Dev, không phải luật lọc): dải 13 mục đầu lấy ngẫu nhiên từ pool đã lọc, cho phép trùng nếu pool nhỏ (custom 2 lựa chọn thì dải xen kẽ A B A B…). Kết quả cuối do `DecisionSuggester` quyết TRƯỚC khi chạy; animation chỉ là trình diễn.

Tự quay khi mở: mở `DecisionWheelScreen` từ nút "Quay" (thẻ A) hoặc "Quay lại" (sheet B) → tự quay sau 250ms (đợi route transition xong). Mở bằng "Nhập & quay" hoặc đổi chế độ bằng tay → không tự quay.

"Quay lại" từ sheet B ở chế độ Tự nhập: mở màn với câu hỏi + lựa chọn của quyết định đó điền sẵn, rồi tự quay. Chốt → update đúng doc đó (spins+1).

## 9. Accessibility

- Vùng chạm ≥44: chip (40 + đệm), nút xoá chip (44×40), link (44), đĩa thêm (44), `TextButton` "Đã quay" (44×44). Nút cạnh nhau cách ≥8 (thực tế 8–12).
- Tương phản: mọi chữ đọc được ≥4,5:1 (bảng ở mục 4). Chữ trên blush chỉ dùng navy (α ≥ .72).
- Semantics:
  - Dòng thẻ Home: 1 node `button`, nhãn ghép "{Ăn gì?}. {Chưa ai quay hôm nay | Bún chả, Tuấn quay lúc 17:02}", hint "Chạm để quay" / "Chạm để xem".
  - Thanh chế độ: mỗi ô `button` + `selected` + `inMutuallyExclusiveGroup`.
  - Chip lọc: `button` + `selected`. Chip giá trị: nhãn = chữ, nút xoá riêng "Xoá {chữ}".
  - Nút Quay: nhãn theo chế độ ("Quay chọn món", "Quay chọn chỗ đi", "Quay chọn giúp").
  - Cửa sổ quay: `ExcludeSemantics` khi đang chạy; khi dừng, 1 node `liveRegion` "Kết quả: Bún chả. Ăn ngoài, nhanh gọn".
  - Emoji trong kết quả: `ExcludeSemantics` (đọc tên món là đủ).
  - Badge "×3": nhãn "quay 3 lần".
- Chữ to: thanh chế độ `FittedBox.scaleDown`; chip `Wrap`; 2 khối top 5 xếp dọc khi `textScaler > 1.3`; sheet cuộn được.

## 10. Localization (vi + en)

> Đã soát theo humanizer (không dấu gạch dài nối câu, không câu chốt kịch tính, ngoặc thẳng). Xưng "mình" / "chúng mình", không "hai đứa". `{name}` = tên người ấy theo couple, rỗng thì dùng `reactionPartnerFallback`. `{time}` = `DateFormat.Hm(locale)` cho vi, `DateFormat.jm(locale)` cho en. Tên món/hoạt động lấy từ ngân hàng (cột vi/en); cột en của activity-bank là cụm động từ thường ("grab coffee") → hiển thị **viết hoa chữ đầu** ("Grab coffee"), push giữ nguyên chữ thường theo D5.

### Thẻ Home
| Key | VI | EN |
|---|---|---|
| decisionCardTitle | Phân vân gì không? | Can't decide? |
| decisionHistoryLink | Đã quay | Past spins |
| decisionRowEatTitle | Ăn gì? | What to eat? |
| decisionRowGoTitle | Đi đâu? | Where to go? |
| decisionRowCustomTitle | Phân vân khác | Something else |
| decisionRowEmpty | Chưa ai quay hôm nay | No one has spun yet today |
| decisionRowCustomEmpty | Ai rửa bát, xem phim gì… | Dishes, movie night… |
| decisionRowEatLabel | HÔM NAY ĂN | TODAY WE EAT |
| decisionRowGoLabel | HÔM NAY MÌNH | TODAY WE'LL |
| decisionSpinCta | Quay | Spin |
| decisionCustomCta | Nhập & quay | Type & spin |
| decisionByMe | Mình quay · {time} | You spun · {time} |
| decisionByPartner | {name} quay · {time} | {name} spun · {time} |
| decisionSpinsBadge | ×{count} | ×{count} |
| decisionCustomMore | +{count} câu khác | +{count} more |
| decisionRowHintSpin | Chạm để quay | Tap to spin |
| decisionRowHintView | Chạm để xem | Tap to view |

### Sheet kết quả
| Key | VI | EN |
|---|---|---|
| decisionSheetByMe | Mình quay lúc {time} | You spun at {time} |
| decisionSheetByPartner | {name} quay lúc {time} | {name} spun at {time} |
| decisionSheetSpins | quay {count} lần | spun {count} times |
| decisionPhotoCta | Chụp lại | Take a photo |
| decisionAskAnother | Phân vân câu khác | Ask something else |

### Màn quay
| Key | VI | EN |
|---|---|---|
| decisionBadge | CHỌN GIÚP | DECIDE FOR US |
| decisionModeEat | Ăn gì | Food |
| decisionModeGo | Đi đâu | Plans |
| decisionModeCustom | Tự nhập | Custom |
| decisionFilterAny | Tuỳ | Any |
| decisionFilterHomeCooked | Nhà nấu | Home-cooked |
| decisionFilterEatOut | Ăn ngoài | Eat out |
| decisionFilterQuick | Nhanh gọn | Quick |
| decisionFilterStayIn | Ở nhà | Stay in |
| decisionFilterGoOut | Ra ngoài | Go out |
| decisionFilterFree | Không tốn tiền | Free |
| decisionReelEatLabel | HÔM NAY ĂN | TODAY WE EAT |
| decisionReelGoLabel | HÔM NAY MÌNH | TODAY WE'LL |
| decisionIdleEat | Bấm quay, app chọn món giúp | Tap spin and we'll pick a dish |
| decisionIdleGo | Bấm quay, app chọn chỗ giúp | Tap spin and we'll pick a plan |
| decisionIdleCustom | Thêm ít nhất 2 lựa chọn rồi quay | Add at least 2 options, then spin |
| decisionPoolEmpty | Hết món hợp bộ lọc này, thử chip khác nhé | Nothing matches this filter. Try another one |
| decisionTagHomeCooked | Nhà nấu | Home-cooked |
| decisionTagEatOut | Ăn ngoài | Eat out |
| decisionTagEither | Nấu hay ăn ngoài đều được | Cook or eat out |
| decisionTagQuick | nhanh gọn | quick |
| decisionTagMedium | vừa sức | easy enough |
| decisionTagFancy | cầu kỳ | takes effort |
| decisionTagStayIn | Ở nhà | Stay in |
| decisionTagGoOut | Ra ngoài | Out |
| decisionTagFree | không tốn tiền | free |
| decisionTagCheap | rẻ | cheap |
| decisionTagPricey | hơi tốn | pricey |
| decisionTagManualEat | Món chúng mình tự thêm | A dish we added |
| decisionTagManualGo | Chỗ chúng mình tự thêm | A plan we added |
| decisionTagCustomOf | 1 trong {count} lựa chọn | 1 of {count} options |
| decisionCurrent | Đang chốt: {result} | Current pick: {result} |
| decisionSpin | Quay | Spin |
| decisionSpinSemanticsEat | Quay chọn món | Spin for a dish |
| decisionSpinSemanticsGo | Quay chọn chỗ đi | Spin for a plan |
| decisionSpinSemanticsCustom | Quay chọn giúp | Spin to decide |
| decisionResultSemantics | Kết quả: {result}. {tag} | Result: {result}. {tag} |
| decisionCommit | Chốt luôn | Lock it in |
| decisionRespin | Quay lại | Spin again |
| decisionManual | Nhập tay | Type my own |
| decisionManualTitleEat | Mình muốn ăn… | I'm craving… |
| decisionManualTitleGo | Mình muốn đi… | I'd rather… |
| decisionManualHintEat | Ví dụ: Bánh xèo | e.g. Banh xeo |
| decisionManualHintGo | Ví dụ: Đi dạo Hồ Tây | e.g. Walk around West Lake |
| decisionQuestionLabel | Phân vân chuyện gì? | What are you stuck on? |
| decisionQuestionHint1 | Phở hay bún? | Pho or bun? |
| decisionQuestionHint2 | Đà Lạt hay Vũng Tàu? | Da Lat or Vung Tau? |
| decisionQuestionHint3 | Ai rửa bát? | Who does the dishes? |
| decisionPresetLabel | Điền nhanh | Quick fill |
| decisionPresetWho | Ai làm? | Who does it? |
| decisionPresetWhich | Cái nào? | Which one? |
| decisionPresetReplaced | Đã thay {count} lựa chọn | Replaced {count} options |
| decisionOptionsLabel | Các lựa chọn | Options |
| decisionOptionsCount | {count}/12 | {count}/12 |
| decisionOptionAddHint | Thêm lựa chọn | Add an option |
| decisionOptionNumberHint | Lựa chọn {n} | Option {n} |
| decisionOptionAdd | Thêm | Add |
| decisionOptionRemove | Xoá {option} | Remove {option} |
| decisionOptionsNeedTwo | Cần ít nhất 2 lựa chọn để quay | Add at least 2 options to spin |
| decisionOptionsMax | Đủ 12 lựa chọn rồi | That's the max of 12 |
| decisionOptionDuplicate | Lựa chọn này có rồi | That one's already on the list |
| decisionCustomDailyCap | Hôm nay chốt đủ 10 câu rồi, mai quay tiếp nhé | That's 10 picks for today. Spin more tomorrow |
| decisionCustomDefaultQuestion | Chọn giúp chúng mình | Pick for us |

Preset "Ai làm?" dùng tên trong couple: tên mình (`person1Name`/`person2Name` theo uid), rỗng → `decisionMeFallback` "Mình" / "Me"; tên người ấy rỗng → `reactionPartnerFallback`. Thêm key:

| Key | VI | EN |
|---|---|---|
| decisionMeFallback | Mình | Me |

Hoàn tác dùng lại `customRemindersUndoLabel` ("Hoàn tác" / "Undo").

### Chốt
| Key | VI | EN |
|---|---|---|
| decisionCommittedPaired | Đã chốt, đã báo {name} | Locked in. {name} got it |
| decisionCommittedSolo | Đã chốt, lưu vào lịch sử của chúng mình | Locked in and saved to our history |
| decisionCommittedQueued | Đang mất mạng. Có mạng lại app gửi liền. | You're offline. It'll send once you're back. |
| decisionCommitFailed | Chưa chốt được. Mạng chập chờn, thử lại nhé | Couldn't lock it in. Check your connection and try again |
| decisionRetry | Thử lại | Try again |

### Lịch sử
| Key | VI | EN |
|---|---|---|
| decisionHistoryBadge | ĐÃ QUAY | SPUN SO FAR |
| decisionTopEat | Hay ăn | Our go-to food |
| decisionTopGo | Hay đi | Our go-to plans |
| decisionTopCaption | 90 ngày qua | Last 90 days |
| decisionTopEmpty | Chưa có gì | Nothing yet |
| decisionTopCountSemantics | {count} lần | {count} times |
| decisionRecent | Gần đây | Recent |
| decisionDayToday | Hôm nay | Today |
| decisionDayYesterday | Hôm qua | Yesterday |
| decisionSpinsSemantics | quay {count} lần | spun {count} times |
| decisionHistoryEmptyTitle | Chưa quay lần nào | No spins yet |
| decisionHistoryEmptyBody | Lần tới phân vân ăn gì, đi đâu, ai rửa bát, cứ để app chọn. Chốt xong sẽ hiện ở đây. | Next time you can't agree on dinner, a plan, or who does the dishes, let the app pick. Your picks show up here. |
| decisionHistoryEmptyCta | Quay thử | Try a spin |
| decisionHistoryLoadError | Chưa tải được lịch sử | Couldn't load your history |

### Nhắc (Cài đặt + thông báo local)
| Key | VI | EN |
|---|---|---|
| decisionReminderSettingTitle | Nhắc chọn món | Dinner pick reminder |
| decisionReminderSettingSubtitle | Chưa ai chốt món hôm nay thì nhắc lúc này | Nudges you if no one has picked food today |
| decisionReminderTitle | Hôm nay ăn gì? | What's for dinner? |
| decisionReminderBody1 | Tối nay ăn gì? Quay một phát cho xong. | Dinner plans? One spin and it's settled. |
| decisionReminderBody2 | Chưa ai chốt món hôm nay, mình quay trước nhé. | No one has picked dinner yet. Want to spin first? |
| decisionReminderBody3 | Thôi "tuỳ em" với "tuỳ anh". Để app chọn giúp. | Skip the "you pick" back and forth. Let the app choose. |
| decisionReminderBody4 | Bún, phở hay cơm nhà? Quay là biết. | Noodles, pho or a home-cooked meal? Spin and see. |
| decisionReminderBody5 | Sắp tới giờ ăn rồi. Quay món rồi báo người ấy luôn. | Almost dinnertime. Spin a dish and let them know. |

Không ICU ngoài placeholder (`{name}`, `{time}`, `{count}`, `{result}`, `{tag}`, `{option}`, `{n}`). Ngoặc kép thẳng `"` trong ARB phải escape `\"`.

## 11. Assets / icon

Không asset mới. Icon `iconsax_plus` (đã kiểm tên có thật trong package 1.0.0):

| Chỗ | Icon |
|---|---|
| Ăn gì | `reserve` (Linear; Bold khi ô chế độ đang chọn) |
| Đi đâu | `location` |
| Tự nhập | `message_question` |
| Chip màn quay, header thẻ, nút Quay, empty state | `shuffle` |
| Quay lại, Thử lại | `refresh` |
| Chốt luôn | `tick_circle` |
| Nhập tay | `edit_2` |
| Chụp lại | `camera` |
| Đã quay / lịch sử | `clock` |
| Preset Ai làm? / Cái nào? | `profile_2user` / `task_square` |
| Thêm / xoá lựa chọn | `add` / `close_circle` |
| Dòng trợ giúp | `info_circle` |
| Lỗi mạng | `cloud_cross` |
| Tile nhắc | `reserve` |
| Mũi tên dòng có kết quả | `arrow_right_3` |

Emoji chỉ xuất hiện trong NỘI DUNG kết quả (cột Emoji của 2 ngân hàng). Món/chỗ nhập tay không có emoji → hiển thị chỉ tên (không chèn emoji mặc định).

## 12. Dev notes

1. **Tái dùng, không chế:** thẻ = `ContentCard` + `IconBadge` + `InkTile`; sheet = khuôn `_MoodPickerSheet`; thanh chế độ = khuôn `setup_screen._buildModeSelector` đổi màu track sang trắng α.55 (nền blush, không phải glass); empty/error lịch sử = khuôn `_TimelineMessage` của `care_timeline_screen` (sửa chữ body sang navy α.72); tile nhắc = khuôn `_DailyQuestionReminderTile` + `_DailyQuestionTimeRow` (không ✕). Có thể tách 2 nút pill (viền / navy) thành widget riêng trong feature, không cần đưa vào `lib/widgets/` chung.
2. **Ô quay:** 1 `AnimationController(900ms)` + `CurvedAnimation(easeOutCubic)` điều khiển `Transform.translate` của 1 `Column` 14 ô trong `ClipRect` cao 128. Kết quả quyết trước, đặt ở ô cuối. Reduce Motion (`AppMotion.reduceMotion`) → bỏ controller, set kết quả thẳng. Chạm khi đang chạy → `controller.value = 1`. Đổi chế độ / rời màn → `stop()`; `dispose()` trong `dispose`.
3. **Tự quay khi mở** chỉ với tham số `autoSpin: true` (nút Quay ở thẻ, Quay lại ở sheet). Đợi `ModalRoute.of(context)!.animation` hoàn tất hoặc 250ms.
4. **Chốt offline:** D3 dùng transaction cho eat/go, transaction KHÔNG chạy offline. Thiết kế có 2 nhánh: (a) Dev chọn ghi kiểu xếp hàng được (vd `set` có điều kiện ở client) → dùng state "Đang mất mạng…" và pop; (b) giữ transaction → lỗi → dải lỗi + "Thử lại", KHÔNG pop, KHÔNG mất kết quả. Dev chọn 1 và ghi vào `dev.md`; Tester test nhánh đó.
5. **`CreatePostScreen`** chưa có tham số caption sẵn → cần thêm (vd `initialCaption`). Caption theo D8: eat "Bún chả 🍢", go "Đi cà phê ☕", custom "{question} → {result}". "Chụp lại" ở SnackBar sau khi chốt và ở sheet B dùng cùng 1 hàm.
6. **Home:** thêm `DecisionCard` sau `MoodCard`, trước `SleepCard`; đẩy index `EntranceReveal` của các thẻ sau lên 1. Bọc `MidnightBuilder`. Push tap `decision` → Home + cuộn tới thẻ (giống `daily_question` cuộn card).
7. **Meta "ai quay":** so `byUserId` với uid mình → `decisionByMe`, khác → `decisionByPartner(name)`. Giờ lấy `updatedAt ?? createdAt`, định dạng theo locale (D3 luật ngày).
8. **Nhãn ngày lịch sử** theo `date` của doc, không theo `createdAt` giờ máy người xem.
9. **Top 5** đếm `result` chuẩn hoá (trim, gộp khoảng trắng, không phân biệt hoa thường) theo D9; hiển thị tên của lần chốt gần nhất + emoji từ ngân hàng nếu `resultId` khớp.
10. **Tên en của activity-bank** viết hoa chữ đầu khi hiển thị trong app (không đổi dữ liệu).
11. **Placeholder xoay:** `Timer.periodic(3s)` chỉ chạy khi ô trống + không focus + không Reduce Motion + `TickerMode` bật; huỷ trong `dispose`.
12. **Không tạo token màu mới.** Các α dùng (.06/.08/.10/.12/.18/.20/.24/.28/.55/.65/.72/.86) đều đã có tiền lệ trong code.
13. Không thêm package. Rung dùng `HapticFeedback` có sẵn.

## 13. Acceptance thiết kế

- [ ] Thẻ Home 3 dòng đúng thứ tự (Ăn gì · Đi đâu · Phân vân khác), mỗi dòng có 2 trạng thái + shimmer khi tải; nằm sau `MoodCard`, trước `SleepCard`; hiện khi chờ người ấy.
- [ ] Ba pill gợi ý trên thẻ cùng 1 khuôn (h36, rose α.10, chữ navy 13 w700); cả dòng là vùng chạm duy nhất.
- [ ] Màn quay: header `SubScreenHeader` chip "CHỌN GIÚP"/"DECIDE FOR US" icon `shuffle`; thanh 3 chế độ trượt 260ms; chip lọc đúng 4 chip/chế độ, wrap khi chữ to.
- [ ] Quay chạy 900ms easeOutCubic, dừng đúng kết quả, rung khi dừng; Reduce Motion bật → kết quả hiện ngay, không cuộn, placeholder không xoay.
- [ ] Chạm khi đang quay → nhảy tới kết quả; đổi chế độ khi đang quay → không crash, về trạng thái chờ.
- [ ] Hàng nút Quay lại (viền) · Chốt luôn (navy) cùng cao 52, cách 12; Nhập tay là link chữ cao 44; Tự nhập không có Nhập tay.
- [ ] Tự nhập: nhãn hiện rõ, placeholder xoay 3 ví dụ, preset Ai làm? điền đúng 2 tên, Cái nào? xoá hết và gợi "Lựa chọn 1/2", chip xoá được, trùng bị chặn, 12 là trần, <2 khoá Quay + có dòng giải thích.
- [ ] Sheet kết quả: emoji to, tên ≤2 dòng, ai quay + giờ + số lần; Quay lại · Chụp lại · Đã quay đúng khuôn.
- [ ] Chốt: SnackBar đúng 3 biến thể (đã ghép / chưa ghép / offline xếp hàng) hoặc dải lỗi + Thử lại; kết quả không mất khi lỗi.
- [ ] Lịch sử: 2 khối top 5, nhóm theo ngày bằng nhãn navy, "×N" khi quay lại, phân trang 30, empty + error + loading đúng.
- [ ] Tile nhắc cùng khuôn tile nhắc câu hỏi, 1 giờ, mặc định 16:30, ẩn khi chờ người ấy.
- [ ] Mọi chữ đọc được ≥4,5:1; không chữ `textSecondary`/`accentLove` đặt thẳng trên blush; mọi vùng chạm ≥44.
- [ ] Đủ copy vi + en ở mục 10, không "hai đứa", không cỡ chữ ngoài type scale.

## 14. Câu hỏi cho PO

1. **Câu hỏi custom bỏ trống:** thiết kế cho phép quay khi chưa gõ câu hỏi; lúc chốt, nếu trống thì lưu `question` = tên preset vừa dùng ("Ai làm?"/"Cái nào?") hoặc "Chọn giúp chúng mình". Push sẽ thành *Thảo quay "Chọn giúp chúng mình": Tuấn*. PO ưng, hay muốn bắt buộc gõ câu hỏi mới cho Chốt?
2. **Dòng lịch sử có bấm được không?** Bản này để chỉ xem (không mở sheet, không quay lại ngày cũ) vì doc eat/go ngày cũ mà "quay lại" thì ghi đè lịch sử. Đồng ý?
3. **Copy push "đi" bị lặp chữ (D5):** mẫu VI *"{name} quay ra: đi {result}"* ghép với ngân hàng thì ra *"Thảo quay ra: đi Đi cà phê"*, vì 35/64 mục trong `activity-bank.md` bắt đầu bằng "Đi" (số còn lại như "Xem phim ở nhà" ghép thành "đi Xem phim ở nhà" cũng gượng). Đề xuất đổi mẫu thành *"{name} quay ra: {result}"* (vd "Thảo quay ra: Đi cà phê", "Thảo quay ra: Xem phim ở nhà"). Bản EN *"let's {result}"* ổn. Thẻ Home và sheet trong app đã né bằng nhãn "HÔM NAY MÌNH" + tên mục. PO chốt giúp trước khi Dev viết CF.

Đã tự chốt (PO lật được): mở màn quay từ nút Quay / Quay lại thì **tự quay ngay** để giữ "2 chạm"; mở bằng tay hoặc đổi chế độ thì không.

## 15. Changelog

- [2026-10-19] [Designer] Thiết kế đủ feature decision-wheel: thẻ Home 3 dòng (2 trạng thái + loading), sheet kết quả, màn quay 3 chế độ (thanh chế độ, chip lọc, ô quay slot dọc 900ms, Tự nhập với chip lựa chọn + preset), sheet Nhập tay, màn lịch sử (top 5 + nhóm theo ngày + phân trang), tile nhắc trong Cài đặt; bảng states, animation, a11y, copy vi/en (~120 key + 5 câu nhắc). Chọn slot chữ chạy dọc thay bánh xe. Tra UI UX Pro Max 2.13.0 (14 truy vấn ux/color/flutter). Mockup bấm thử `docs/design/decision-wheel-mockup.html`. 3 câu hỏi cho PO ở mục 14.
