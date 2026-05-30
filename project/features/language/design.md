# 🎨 Design — Language v2

> Designer sở hữu. Đọc [overview.md](overview.md) trước. Bám design system (`../../../CLAUDE.md` mục 8). CHỈ thiết kế, không code.

- **Trạng thái design:** xong
- **Người/role:** Designer

## Mục tiêu thiết kế
Thay cờ quốc gia trong language picker & pill bằng **"letter chip"** (EN/VI), và chuẩn hoá hiển thị **"System default"** bằng globe 🌐 + mã ngôn ngữ đang resolve. KHÔNG đổi kiểu bottom sheet single-select (đã đạt, chỉ thay phần icon/leading của mỗi dòng + leading của pill auth). Decision của PO đã chốt: **D2** (overview mục 4) — đừng lật lại.

## Phạm vi & màn hình
- **Picker bottom sheet** (`_LanguageSheet` + `_LanguageTile`) — dùng chung cho 2 nơi gọi: pill auth + card Profile.
- **Pill auth** (`LanguageToggleButton`) — góc trên phải màn login/register.
- **Profile language row** — tap để mở cùng bottom sheet (không đổi layout row, chỉ ảnh hưởng nội dung sheet).
- Ngoài phạm vi: kiểu sheet, grabber, search field, animation mở sheet — giữ nguyên.

## User flow
- Profile → tap card "Ngôn ngữ" → bottom sheet hiện list → tap 1 dòng → áp dụng tức thì + đóng sheet.
- Màn auth (login/register) → pill góc trên phải → mở cùng bottom sheet → tap 1 dòng → áp dụng + đóng.

## Wireframe — dòng trong picker (ASCII)

3 dòng, thứ tự hiển thị giữ như `kAppLanguages` hiện tại (System → EN → VI). Mỗi dòng = chip 44×44 (leading) + endonym (dòng chính) + tên phụ tiếng Anh (dòng phụ, xám nhỏ) + ✓ khi đang chọn.

### State 1 — đang chọn EN
```
┌──────────────────────────────────────────────────┐
│  ┌────┐                                           │
│  │🌐  │   Theo hệ thống                            │   ← System: globe, chưa chọn
│  └────┘   Theo ngôn ngữ thiết bị                   │     (dòng phụ = languageSystemDesc)
│                                                    │
│  ┌────┐                                       ┌─┐  │
│  │ EN │   English                             │✓│  │   ← ĐANG CHỌN: nền+viền rose, ✓
│  └────┘   English                             └─┘  │
│                                                    │
│  ┌────┐                                           │
│  │ VI │   Tiếng Việt                              │   ← chưa chọn
│  └────┘   Vietnamese                              │
└──────────────────────────────────────────────────┘
```

### State 2 — đang chọn VI
```
┌──────────────────────────────────────────────────┐
│  ┌────┐                                           │
│  │🌐  │   Theo hệ thống                            │   ← chưa chọn
│  └────┘   Theo ngôn ngữ thiết bị                   │
│                                                    │
│  ┌────┐                                           │
│  │ EN │   English                                 │   ← chưa chọn
│  └────┘   English                                 │
│                                                    │
│  ┌────┐                                       ┌─┐  │
│  │ VI │   Tiếng Việt                          │✓│  │   ← ĐANG CHỌN: nền+viền rose, ✓
│  └────┘   Vietnamese                          └─┘  │
└──────────────────────────────────────────────────┘
```

### State 3 — System default
```
┌──────────────────────────────────────────────────┐
│  ┌────┐                                       ┌─┐  │
│  │🌐  │   Theo hệ thống                       │✓│  │   ← ĐANG CHỌN: nền+viền rose, ✓
│  └────┘   Theo ngôn ngữ thiết bị              └─┘  │
│                                                    │
│  ┌────┐                                           │
│  │ EN │   English                                 │   ← chưa chọn
│  └────┘   English                                 │
│                                                    │
│  ┌────┐                                           │
│  │ VI │   Tiếng Việt                              │   ← chưa chọn
│  └────┘   Vietnamese                              │
└──────────────────────────────────────────────────┘
```

## Wireframe — pill auth (ASCII)

Pill bo 999 (giữ nguyên container/màu hiện tại), leading thay flag bằng **mini letter chip** (text 2 ký tự). Dạng `[chip] [mã] ⌄`.

```
State 1 (EN):              State 2 (VI):              State 3 (System default):
┌──────────────┐          ┌──────────────┐           ┌─────────────────┐
│ ⟦EN⟧ EN  ⌄  │          │ ⟦VI⟧ VI  ⌄  │           │  🌐  VI    ⌄    │
└──────────────┘          └──────────────┘           └─────────────────┘
                                                       (🌐 + mã đang resolve,
                                                        thay cho "—" cũ)
```
- State 1: chip `EN` + label `EN`.
- State 2: chip `VI` + label `VI`.
- State 3 (System): **bỏ chip chữ**, hiện globe `🌐` + mã ngôn ngữ thực tế đang resolve (vd thiết bị tiếng Việt → `🌐 VI`; tiếng Anh → `🌐 EN`). KHÔNG hiện `—`.

> Lưu ý dev: ở State 3 mã hiển thị là **locale đang resolve thực tế** (ngôn ngữ thiết bị đã map về supported), không phải `null`. Lấy từ `Localizations.localeOf(context)` / locale đang active của `MaterialApp`, không phải từ `provider.locale` (vốn là `null` khi system).

## Spec chi tiết (token chính xác — bám design system mục 8)

### Letter chip trong picker (leading mỗi dòng)
| Token | Giá trị |
|-------|---------|
| Kích thước | 44 × 44 |
| Radius | 14 |
| Nền | `AppColors.accentRose` alpha **0.10** |
| Chữ (EN/VI) | in HOA, `FontWeight.w800`, màu `AppColors.accentLove` (= `#FF4D6D` = `accentRose`) |
| Font size chữ chip | 15 (cân giữa, letter-spacing 0.5) |
| Căn nội dung | center cả trục |
| Globe 🌐 (dòng System) | emoji, fontSize 22, đặt giữa chip (chip vẫn 44×44 nền rose .10 để đồng nhất khung) |

### Dòng picker (`_LanguageTile`) — giữ token hiện có
| Token | Giá trị |
|-------|---------|
| Margin | horizontal 12, vertical 4 |
| Padding | horizontal 16, vertical 14 (giữ) |
| Radius tile | 16 (giữ) |
| Nền khi chọn | `accentRose` alpha **0.08** (giữ) |
| Viền khi chọn | `accentRose` alpha **0.22** (giữ) |
| Nền/viền khi KHÔNG chọn | transparent (giữ) |
| Gap chip → text | 14 |
| Endonym (dòng chính) | `textPrimary` #1A1A2E, fontSize 15, w700 khi chọn / w500 khi không (giữ) |
| Tên phụ tiếng Anh (dòng phụ) | `textTertiary` #A0A0B0, fontSize 12, w500; spacing trên 2px |
| ✓ | `Icons.check_circle_rounded`, `accentRose`, 20px (giữ) |

### Pill auth (`LanguageToggleButton`) — giữ container, đổi leading
| Token | Giá trị |
|-------|---------|
| Padding | horizontal 11, vertical 7 (giữ) |
| Radius | 999 (giữ) |
| Nền/viền | giữ nguyên (onDark: white .14 / .22; onLight: textPrimary .07 / .12) |
| Mini chip leading (state EN/VI) | text 2 ký tự in HOA, fontSize 12, w800, ls 0.5, màu **theo `fgColor`** (white khi onDark, textPrimary khi onLight) — KHÔNG dùng accentLove ở đây để giữ tương phản trên nền gradient tối. Không cần ô vuông nền (tiết kiệm chỗ); nếu muốn ô: 18×18 radius 6 nền `white .18` (chỉ onDark). *Mặc định: chỉ text, không ô.* |
| Globe leading (state System) | emoji 🌐 fontSize 14 |
| Mã ngôn ngữ (label) | fontSize 12, w700, ls 0.5, màu `fgColor` (giữ) |
| Chevron | `Icons.expand_more_rounded` 14, `fgColor` alpha 0.7 (giữ) |
| Gap chip→label | 5; gap label→chevron | 3 (giữ) |

### Sheet container — giữ nguyên 100%
Radius 28, margin 12 + viewInsets, maxHeight 0.7×screen, grabber 36×4 `textTertiary .4` radius 999, header icon `Icons.language_rounded` 18 `accentRose` + `languageTitle` 16 w800, search field chỉ hiện khi >6 ngôn ngữ.

## States (tổng hợp 3 state — cả picker row LẪN pill)
| State | Picker row | Pill auth |
|-------|------------|-----------|
| 1. Đang chọn **EN** | chip `EN` + endonym "English" + ✓ ở dòng English; nền/viền rose | `[EN]` + `EN` |
| 2. Đang chọn **VI** | chip `VI` + endonym "Tiếng Việt" + ✓ ở dòng Tiếng Việt; nền/viền rose | `[VI]` + `VI` |
| 3. **System default** | chip 🌐 + "Theo hệ thống" + ✓ ở dòng System; nền/viền rose | `🌐` + `{mã đang resolve}` (vd `🌐 VI`) |

Các state phụ:
- **Loading/error:** không có — đổi locale là local & tức thì, không gọi mạng.
- **Disabled:** không có dòng nào disabled.
- **>6 ngôn ngữ (tương lai):** search field tự hiện (giữ logic `_kSearchThreshold`); chip chữ scale tốt vì chỉ là 2 ký tự mã.

## Interaction & animation
- Tap dòng → `Navigator.pop` đóng sheet → áp dụng locale (giữ flow hiện tại). Không thêm animation mới.
- Pill: tap mở sheet (giữ). Đổi locale → pill rebuild tức thì (Provider). Không animation riêng.

## Copy (song ngữ — TÁI DÙNG key ARB có sẵn, không thêm key mới)
| Key | VI | EN | Dùng ở |
|-----|----|----|--------|
| `languageTitle` | Ngôn ngữ | Language | Header sheet |
| `languageSubtitle` | Chọn ngôn ngữ hiển thị của ứng dụng | Choose the app display language | (subtitle nếu hiển thị; hiện sheet chưa render — xem Dev notes) |
| `languageSystem` | Theo hệ thống | System default | Dòng chính mục System |
| `languageSystemDesc` | Theo ngôn ngữ thiết bị | Follow device language | **Dòng phụ mục System** (tái dùng key chết) |
| (endonym VI — literal trong `kAppLanguages`) | Tiếng Việt | Tiếng Việt | Dòng chính mục VI |
| (tên phụ VI — literal) | Vietnamese | Vietnamese | Dòng phụ mục VI |
| (endonym EN — literal) | English | English | Dòng chính mục EN |
| (tên phụ EN — literal) | English | English | Dòng phụ mục EN |

> Endonym & tên phụ là **literal cố định** (không đổi theo ngôn ngữ app) — đúng best-practice endonym (overview mục 2). Không cần ARB cho chúng. Tên phụ tiếng Anh của EN trùng endonym ("English") → có thể ẩn dòng phụ cho riêng mục EN để khỏi lặp (tuỳ chọn, xem Dev notes).

## Assets
- Không cần asset ảnh/flag mới. Bỏ toàn bộ emoji cờ (`🇺🇸`, `🇻🇳`) khỏi `kAppLanguages`.
- Chữ chip = text thuần (mã ngôn ngữ in hoa). Globe = emoji `🌐` (đã có sẵn trong list cho mục system).

## Dev notes / handoff
- **Tái dùng key chết `languageSystemDesc`** làm dòng phụ mục System default (thay vì xoá — gỡ 1 phần gap E). 2 key chết còn lại (`languageEnglish`, `languageVietnamese`) vẫn dư vì ta dùng endonym literal → Dev có thể xoá 2 key đó (gap E), giữ `languageSystemDesc`.
- `kAppLanguages` hiện có field `flag` (emoji cờ). Giả định Dev sẽ: bỏ field `flag` cờ, thay bằng render letter chip từ `code` (in hoa) cho EN/VI và globe cho `code == null`. (Designer không sửa code — đây là gợi ý thực thi.)
- **Dòng phụ tiếng Anh dưới endonym là tuỳ chọn**: nếu chật ngang (locale VI nhãn dài) có thể bỏ dòng phụ; ưu tiên giữ chip + endonym. Với mục EN dòng phụ trùng endonym → nên ẩn để khỏi lặp.
- **Pill state System:** mã hiển thị = locale **đang resolve thực tế** (`Localizations.localeOf` / locale active), KHÔNG phải `provider.locale` (đang `null`). Đây là khác biệt then chốt so với code cũ (gap F: hiện ra `—`).
- `currentAppLanguage()` hiện trả về entry system (code null) khi `provider.locale == null` → pill cần nhánh riêng: nếu là system thì lấy mã resolve để hiện `🌐 {mã}`.
- `languageSubtitle` hiện chưa được render trong sheet (header chỉ có title). Không bắt buộc thêm; nếu Dev muốn dùng thì đặt dưới title, `textSecondary` #6B6B7B fontSize 13. (Giữ key trong bảng copy để sẵn.)
- Màu chip trong **picker** dùng `accentLove` (#FF4D6D) trên nền rose .10 (tương phản tốt trên card trắng). Màu chip trong **pill auth** dùng `fgColor` (trắng trên gradient tối) — KHÔNG dùng accentLove vì nền pill tối, accentLove sẽ chìm. Đây là chủ ý, không phải mâu thuẫn token.

## Acceptance (design)
- [x] 3 state vẽ rõ cho cả picker row và pill auth (wireframe ASCII riêng từng state).
- [x] Token chính xác: chip 44×44 r14 nền accentRose .10, chữ w800 accentLove; tile giữ token rose .08/.22; pill giữ container, đổi leading.
- [x] Copy đủ VI+EN, tái dùng key có sẵn (`languageTitle/languageSubtitle/languageSystem/languageSystemDesc`), không bịa key.
- [x] Không còn cờ quốc gia (bỏ `flag` emoji cờ).
- [x] System default: picker globe + endonym "Theo hệ thống" + dòng phụ; pill `🌐 {mã resolve}` thay `—`.
- [x] Ghi rõ giả định (literal endonym, bỏ field flag, mã resolve cho pill) để Dev dựng không hỏi lại.

## Giả định đã ghi (không phải quyết định sản phẩm — Dev/PO xem lại nếu cần)
- Màu chip pill auth = `fgColor` (không accentLove) để tương phản trên nền gradient tối — *giả định UX*, có thể đổi nếu PO muốn đồng nhất màu chip 2 nơi.
- Ẩn dòng phụ tiếng Anh cho riêng mục EN (vì trùng endonym) — *giả định gọn gàng*, không bắt buộc.
- `languageSubtitle` không render trong sheet (giữ như hiện trạng) — *giả định giữ nguyên scope*.

## Nhật ký design
- [2026-05-30] [PO→Designer] PO đã chốt hướng (D2) + bàn giao spec nháp này; chờ Designer hoàn thiện handoff/mockup.
- [2026-05-30] [Designer] Hoàn thiện handoff chip chữ 3 state (Mode 1 orchestrator).
