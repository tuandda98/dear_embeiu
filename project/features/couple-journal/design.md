# 🎨 Design — Nhật ký của chúng mình (Couple Journal)

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`project/design-system.md`). CHỈ thiết kế, không code.

- **Trạng thái design:** xong (v1)
- **Người/role:** Designer
- **Phụ thuộc:** daily-question (#5) · love-note (#4) · home-engagement · gallery (pattern màn list/preview)

---

## Mục tiêu thiết kế

1. **Phần 1 — Màn "Nhật ký câu hỏi"** (Q&A history): biến Daily Question từ "trả lời rồi quên" thành cuốn nhật ký xem lại được. Mỗi mục = 1 ngày đã mở khoá (cả hai đã trả lời) gồm câu hỏi + 2 câu trả lời có nhãn. Đây là lõi memory-keeper, tăng giữ chân.
2. **Phần 2 — Cải Love Note card** trên Home: hiện thêm "Lời nhắn của bạn" (note của chính user) gọn dưới note partner, để card cân đối 2 chiều — user thấy được cả 2 chiều mà không phải mở sheet.
3. Giữ trọn phong cách "Sunset Romance": glass trên gradient hồng, serif Fraunces cho câu hỏi, Plus Jakarta Sans cho UI, light-mode only.

---

## User flow

### Flow A — Mở nhật ký từ Home
```
Home (tab 0)
  └─ card "Câu hỏi hôm nay" (_DailyQuestionCard)
       └─ [dòng entry "Xem lại nhật ký →" ở chân card]  ──tap──▶  JournalScreen
                                                                     │
                                                  ┌──────────────────┴───────────────────┐
                                                  ▼                                       ▼
                                          có ≥1 ngày reveal                        chưa có ngày nào
                                          → list cuộn dọc                          → empty state + CTA
                                                                                     "Trả lời câu hôm nay"
                                                                                      → pop về Home
```

### Flow B — Mở nhật ký từ Settings (entry phụ)
```
Profile → ⚙️ Cài đặt → Settings
  └─ section mới "📖 Kỷ niệm" → tile "Nhật ký câu hỏi" → JournalScreen
```

### Flow C — Love Note 2 chiều (Home, không đổi điều hướng)
```
Home → card "Lời nhắn"
  ├─ vùng trên: lời nhắn của NGƯỜI ẤY (giữ nguyên)
  ├─ [MỚI] vùng dưới gọn: "Lời nhắn của bạn" — preview note của chính user (nếu có)
  └─ nút Viết/Sửa (giữ nguyên) → bottom sheet
```

---

## Wireframe (ASCII)

### 1. Entry point trên card Daily Question (Home)
Thêm 1 dòng entry ở **chân card** `_DailyQuestionCard`, ngăn cách bằng divider mảnh. Hiện ở MỌI trạng thái của card (chưa trả lời / chờ partner / đã reveal) miễn couple `active` — vì nhật ký là kho chung, không phụ thuộc trạng thái hôm nay. Khi couple `waiting_partner` (chưa có partner) → ẩn dòng entry (chưa thể có kỷ niệm chung).

```
┌─────────────────────────────────────────────┐  GlassCard (giữ nguyên phần trên)
│  (?) Câu hỏi hôm nay                          │
│                                               │
│  "Điều nhỏ nào ở mình khiến em vui nhất?"     │  ← Fraunces 22, w600, trắng
│                                               │
│  …[body theo state hiện tại]…                 │
│  ─────────────────────────────────────────   │  ← divider: trắng alpha .14, 1px
│  🕮  Xem lại nhật ký                      →   │  ← dòng entry MỚI, tappable full-width
└─────────────────────────────────────────────┘
        icon LucideIcons.bookHeart 18, trắng .85
        label 14 w600 trắng .9 · chevron right 16 trắng .6
```

### 2. JournalScreen — danh sách (state: có dữ liệu)
```
╔═══════════════════════════════════════════════╗  nền gradient dreamyMint (galleryGradient)
║  ‹  Nhật ký câu hỏi                            ║  AppBar phẳng trong suốt, back chevron
║                                                ║  title Fraunces 20 w700 textPrimary
║  Những câu hỏi hai bạn đã cùng trả lời.        ║  ← subtitle 13 textSecondary, 1 dòng
║                                                ║
║  ┌─────────────────────────────────────────┐  ║  CARD TRẮNG ĐẶC (không glass — list cuộn)
║  │  THỨ BẢY, 31 THG 5 2026          💞      │  ║  ← eyebrow ngày: 12 w700 ls .4 accentLove
║  │                                          │  ║
║  │  "Điều nhỏ nào ở mình khiến em vui       │  ║  ← câu hỏi Fraunces 18 w600 textPrimary
║  │   nhất hôm nay?"                         │  ║
║  │                                          │  ║
║  │  ┌────────────────────────────────────┐ │  ║  ← block "của bạn": nền surfaceLight r16
║  │  │ CÂU TRẢ LỜI CỦA BẠN                │ │  ║     label 11 w700 ls .3 accentLoveDeep
║  │  │ Khi anh pha cà phê sáng cho em.    │ │  ║     text 15 w500 textPrimary h1.5
║  │  └────────────────────────────────────┘ │  ║
║  │  ┌────────────────────────────────────┐ │  ║  ← block "của partner": nền lavender tint
║  │  │ CÂU TRẢ LỜI CỦA MINH               │ │  ║     label 11 w700 ls .3 accentLavender(đậm)
║  │  │ Lúc em cười khi đọc tin nhắn anh.  │ │  ║     text 15 w500 textPrimary h1.5
║  │  └────────────────────────────────────┘ │  ║
║  └─────────────────────────────────────────┘  ║
║                                                ║  ← gap 14 giữa các card-ngày
║  ┌─────────────────────────────────────────┐  ║
║  │  THỨ SÁU, 30 THG 5 2026          💞      │  ║
║  │  …                                       │  ║
║  └─────────────────────────────────────────┘  ║
║                                                ║
║        ┌──────────────────────────┐            ║  ← nút "Xem thêm" (chỉ khi còn dữ liệu)
║        │      Xem thêm             │            ║     pill outline, ẩn khi đã hết
║        └──────────────────────────┘            ║
╚═══════════════════════════════════════════════╝
```

### 3. JournalScreen — empty state
```
╔═══════════════════════════════════════════════╗  nền gradient dreamyMint
║  ‹  Nhật ký câu hỏi                            ║
║                                                ║
║                  ◜◝                            ║
║                 🕮💞                           ║  ← icon tròn glass 88px, LucideIcons.bookHeart
║                  ◟◞                            ║     accentLove, nền trắng .5
║                                                ║
║        Chưa có kỷ niệm câu hỏi nào             ║  ← title Fraunces 20 w700 textPrimary, center
║                                                ║
║   Khi cả hai cùng trả lời câu hỏi trong ngày,  ║  ← body 14 textSecondary center h1.5, max 2 dòng
║   khoảnh khắc đó sẽ được lưu vào đây.          ║
║                                                ║
║        ┌──────────────────────────┐            ║
║        │  Trả lời câu hôm nay     │            ║  ← nút navy pill (ElevatedButton chuẩn), pop về Home
║        └──────────────────────────┘            ║
╚═══════════════════════════════════════════════╝
```

### 4. JournalScreen — loading (ShimmerSkeleton)
3 card-ngày skeleton: mỗi card = 1 dòng eyebrow ngắn (40%w) + 1 dòng câu hỏi (80%w) + 2 khối answer (toàn rộng, cao ~48). Dùng `ShimmerSkeleton` sẵn có. Card nền trắng r24.

### 5. JournalScreen — error (nhẹ, inline)
Thay list bằng cụm center: icon `LucideIcons.cloudOff` 40 textTertiary + text "Chưa tải được nhật ký" + link "Thử lại" (accentLove, tap reload). Không full-page đỏ.

### 6. Love Note card — layout 2 chiều mới (Home)
Giữ nguyên header + vùng note partner. **Thêm** dưới note partner (trước nút Viết/Sửa) một block gọn "Lời nhắn của bạn" CHỈ khi `myNote.hasText == true`.

```
┌─────────────────────────────────────────────┐  GlassCard (giữ token cũ: r24, fill .16)
│  ✉ Lời nhắn từ Minh                          │  ← header partner (giữ nguyên)
│                                               │
│  "Hôm nay nhớ em nhiều lắm."                 │  ← note partner: trắng 15 w500 h1.55
│  2 giờ trước                                  │  ← relative time: trắng .72 12 w600
│  ─────────────────────────────────────────   │  ← [MỚI] divider trắng .14, 1px
│  LỜI NHẮN CỦA BẠN                             │  ← [MỚI] label 11 w700 ls .3 trắng .65
│  "Em cũng nhớ anh." · vừa xong               │  ← [MỚI] 1 dòng: text trắng .9 14 w500 +
│                                               │      "·" + relative time trắng .6 12, ellipsis
│  ┌─────────────────────────────────────────┐ │
│  │  ✒  Sửa lời nhắn                        │ │  ← nút Viết/Sửa (giữ nguyên)
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```
Nếu user CHƯA có note → KHÔNG hiện block + divider (tránh card cao vô ích); nút vẫn là "Viết lời nhắn". Khi `waiting_partner` → giữ nguyên hành vi hiện tại (chỉ text mời + ẩn block của bạn vì chưa cần đối chiếu — nhưng nếu user đã có note thì vẫn cho hiện block của bạn để họ thấy mình đã viết gì). Quy tắc: block "của bạn" hiện **khi và chỉ khi `myNote.hasText`**, độc lập trạng thái partner.

---

## Spec chi tiết (token chính xác — bám design-system.md)

### JournalScreen — khung
| Thuộc tính | Giá trị |
|---|---|
| Nền | gradient `dreamyMint` (= galleryGradient) `[#FFD6E0, #E0D4F7, #C6E5D9]` topLeft→bottomRight — đồng bộ với gallery/milestone (khu "kỷ niệm") |
| AppBar | phẳng, trong suốt (`backgroundColor: transparent`, `elevation 0`), back = `LucideIcons.chevronLeft` 24 textPrimary |
| Title | "Nhật ký câu hỏi" — Fraunces 20 w700 `textPrimary #1A1A2E` |
| Subtitle | 13 `textSecondary #6B6B7B`, dưới appbar, padding ngang 20, top 4, bottom 16 |
| Scroll | `ListView`/`CustomScrollView` padding ngang 20, top 8, bottom 32 |
| Entrance | tái dùng `flutter_animate` staggered (fadeIn + slideY 8px), stagger 50ms cho 6 card đầu — như gallery feed |

### Card-ngày (item)
| Thuộc tính | Giá trị |
|---|---|
| Loại card | **Trắng đặc** `cardSurface #FFFFFF` (KHÔNG GlassCard — design-system cấm glass cho list cuộn dài) |
| Radius | `cardRadius` = **28** |
| Shadow | mềm: `BoxShadow(color: accentLove .08, blur 24, offset (0,8))` — như card trắng khác |
| Padding | 18 (all) |
| Gap giữa card | 14 |
| Eyebrow ngày | 12 w700 ls .4, màu `accentLove #FF4D6D`, UPPERCASE theo `_journalDateLabel` (format theo locale) + trailing 💞 (emoji, đẩy phải bằng `Spacer`) |
| Câu hỏi | `AppTheme.displaySerif` size 18 w600 `textPrimary` h1.25 ls -0.2 |
| Gap câu hỏi → answer | 14 |

### Answer block (trong card-ngày)
| | "Của bạn" | "Của partner" |
|---|---|---|
| Nền | `surfaceLight #F5F0F5` | lavender tint = `accentLavender #A78BFA` @ alpha .10 |
| Radius | 16 | 16 |
| Padding | 12 (all) | 12 (all) |
| Label | 11 w700 ls .3, `accentLoveDeep #E63956` | 11 w700 ls .3, `#7C5CD6` (lavender đậm, đọc rõ trên tint) |
| Text | 15 w500 h1.5 `textPrimary` | 15 w500 h1.5 `textPrimary` |
| Gap label→text | 4 |
| Gap giữa 2 block | 10 |

> Lý do dùng 2 nền khác nhau: phân biệt "bạn" (rose, ấm) vs "partner" (lavender) trực quan, đồng bộ palette confetti daily-question (rose + lavender).

### Nút "Xem thêm"
- Pill outline: viền `accentLove` 1.4, nền trong suốt, text `accentLove` 14 w700, height 44, bo 999, `LucideIcons.chevronDown` 16 trước label.
- Căn giữa, margin top 18. Có spinner inline khi đang tải thêm (giống nút submit).

### Empty state
- Icon tròn 88px: nền trắng .5 bo 999, `LucideIcons.bookHeart` 38 màu `accentLove`.
- Title Fraunces 20 w700 textPrimary, center.
- Body 14 textSecondary center h1.5, max ~2 dòng, padding ngang 32.
- CTA: `ElevatedButton` chuẩn (nền navy `#1A1A2E` bo pill, height 52, text trắng 16 w700), width nội dung ~ 220, pop về Home.
- Toàn cụm center theo trục dọc.

### Entry trên Daily Question card
| Thuộc tính | Giá trị |
|---|---|
| Vị trí | chân `_DailyQuestionCard`, sau `_buildBody`, trong cùng GlassCard |
| Divider | trên dòng entry: `Divider` màu trắng alpha .14, dày 1, margin dọc 14 |
| Tappable | toàn dòng (`InkWell` bo 12), ripple trắng nhạt |
| Icon | `LucideIcons.bookHeart` 18, trắng .85 |
| Label | 14 w600, trắng .9 |
| Chevron | `LucideIcons.chevronRight` 16, trắng .6, đẩy phải bằng `Spacer` |
| Padding | dọc 4 |

### Love Note — block "của bạn" mới
| Thuộc tính | Giá trị |
|---|---|
| Divider | trắng alpha .14, dày 1, margin dọc 12 (đặt sau time partner, trước block) |
| Label | "Lời nhắn của bạn" 11 w700 ls .3, trắng .65 |
| Gap label→text | 4 |
| Dòng nội dung | `RichText`/`Row` 1 dòng `ellipsis`: text note trắng .9 14 w500 + " · " + relative time trắng .6 12. Toàn dòng maxLines 1 ellipsis (card không cao thêm đáng kể). |
| Gap block → nút | 16 (giữ nguyên) |

### Settings — tile entry phụ
- Thêm 1 section card mới (kiểu `_buildSectionCard` của settings) tiêu đề "📖 Kỷ niệm" với 1 tile: leading `LucideIcons.bookHeart` (trong khung tròn tint rose .12), title "Nhật ký câu hỏi", trailing chevron. White .72 r22 như các tile settings khác. Đặt section này **trên** section "Tài khoản & dữ liệu".

---

## States

| State | Mô tả |
|---|---|
| **Loading** | 3 card-ngày `ShimmerSkeleton` (eyebrow + câu hỏi + 2 khối answer). Nền dreamyMint. |
| **Empty** | Couple active nhưng chưa ngày nào reveal → cụm icon + title + body + CTA "Trả lời câu hôm nay" (pop về Home tab 0). |
| **Empty (chưa có partner)** | `waiting_partner` → KHÔNG mở được màn này từ Home (entry ẩn). Nếu vào từ Settings: hiện empty riêng "Mời người ấy để bắt đầu viết nhật ký cùng nhau" + CTA dẫn về setup/invite. |
| **Success (có data)** | List card-ngày mới→cũ; nút "Xem thêm" nếu còn. |
| **Loading-more** | Spinner inline trong nút "Xem thêm"; list giữ nguyên. |
| **Error** | Inline center: `cloudOff` + "Chưa tải được nhật ký" + link "Thử lại". |
| **Disabled** | Nút "Xem thêm" mờ (.4) + không tap khi đang tải hoặc hết dữ liệu (ẩn hẳn khi hết). |

---

## Interaction & animation

- **Mở màn:** push route chuẩn (slide từ phải, Material). Haptic `selectionClick` khi tap entry.
- **Entrance list:** `flutter_animate` fadeIn(`AppMotion.base` 280ms) + slideY 8px, stagger 50ms cho 6 card đầu, chạy 1 lần (`_OnceEntrance`). Card sau cuộn vào hiện thẳng (không animate, tránh giật khi cuộn nhanh).
- **Tap "Xem thêm":** haptic `selectionClick`; spinner inline; card mới append fadeIn 200ms.
- **Tap CTA empty:** haptic `selectionClick`, `Navigator.pop` về Home; nếu cần focus card daily-question thì cuộn lên top (Dev tuỳ).
- **Love Note block mới:** xuất hiện/biến mất khi `myNote` đổi → `AnimatedSize` 200ms easeOutCubic để card co/giãn mượt (không nhảy).
- Không confetti ở màn nhật ký (confetti chỉ ở khoảnh khắc reveal trên Home — tránh lặp).

---

## Copy (song ngữ — bắt buộc)

> Convention: prefix `journal*` cho màn nhật ký; mở rộng `loveNote*` cho block mới. Đặt cả `app_vi.arb` + `app_en.arb` rồi `gen-l10n`. Tránh ICU `{}` cho chuỗi không phải placeholder.

| Key | VI | EN |
|-----|----|----|
| `journalEntryCta` | Xem lại nhật ký | Open journal |
| `journalScreenTitle` | Nhật ký câu hỏi | Question journal |
| `journalScreenSubtitle` | Những câu hỏi hai bạn đã cùng trả lời. | The questions you've both answered. |
| `journalSettingsTile` | Nhật ký câu hỏi | Question journal |
| `journalSettingsSection` | Kỷ niệm | Memories |
| `journalYourAnswerLabel` | CÂU TRẢ LỜI CỦA BẠN | YOUR ANSWER |
| `journalPartnerAnswerLabel` | CÂU TRẢ LỜI CỦA {name} | {name}'S ANSWER |
| `journalLoadMore` | Xem thêm | Show more |
| `journalEmptyTitle` | Chưa có kỷ niệm câu hỏi nào | No question memories yet |
| `journalEmptyBody` | Khi cả hai cùng trả lời câu hỏi trong ngày, khoảnh khắc đó sẽ được lưu vào đây. | When you both answer a daily question, that moment gets saved here. |
| `journalEmptyCta` | Trả lời câu hôm nay | Answer today's question |
| `journalEmptyNoPartnerBody` | Mời người ấy để cùng nhau bắt đầu viết nhật ký. | Invite your partner to start your journal together. |
| `journalEmptyNoPartnerCta` | Mời người ấy | Invite partner |
| `journalErrorTitle` | Chưa tải được nhật ký | Couldn't load the journal |
| `journalRetry` | Thử lại | Try again |
| `loveNoteYourNoteLabel` | LỜI NHẮN CỦA BẠN | YOUR NOTE |

> Ghi chú format ngày (eyebrow card): theo decision i18n **D3** — format ngày theo locale. VI vd "THỨ BẢY, 31 THG 5 2026"; EN vd "SAT, MAY 31 2026". Dev dùng `DateFormat` với locale hiện tại + `.toUpperCase()`. KHÔNG cần key l10n riêng cho từng phần ngày — dùng `intl` `DateFormat.yMMMMEEEEd`/`yMMMEd` rồi uppercase. Quan hệ thời gian Love Note tái dùng `loveNote*Ago`/`loveNoteJustNow` sẵn có.

---

## Phụ thuộc kỹ thuật (Dev lưu ý — Designer chỉ ghi nhận, KHÔNG giải)

> ⚠️ Phần này ảnh hưởng phạm vi/chi phí; PO + Dev cần chốt cơ chế trước khi dựng.

1. **Liệt kê lịch sử Q&A không trivial.** Response docs hiện ở `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}` = `{authorUserId, text, answeredAt}` — **không lưu `coupleId`** và doc cha `dailyAnswers/{date}` là **phantom** (chỉ tồn tại subcollection). Firestore không list được "tất cả ngày có trả lời" từ phantom parent.
   - **Đề xuất Dev (PO/Dev chốt):** ghi 1 **marker doc** tại `couples/{coupleId}/dailyAnswers/{date}` mỗi khi một người trả lời, chứa ít nhất `{date, revealedAt?, q1Answered, q2Answered}` hoặc đơn giản `{date, answeredCount}` — để query/sort `dailyAnswers` orderBy `date` desc, limit 30. Cần cập nhật **firestore.rules** cho path marker (hiện rules cho `dailyAnswers/{date}/responses/{uid}`, chưa chắc cho doc `dailyAnswers/{date}`). Cần deploy rules trước.
2. **Quy tắc "chỉ hiện ngày reveal":** UI CHỈ render ngày mà **cả hai** đã trả lời. Reveal hiện được suy ở provider `hasRevealed` (cả 2 doc tồn tại). Với list lịch sử, Dev cần đếm `responses` của mỗi ngày = 2 (hoặc marker `answeredCount==2`) mới đưa vào danh sách. Ngày chỉ 1 người trả lời → **ẩn hẳn** (PO chốt: chưa thành kỷ niệm chung). Không hiển thị placeholder "đang chờ".
3. **Phân trang/hiệu năng:** tải 30 ngày gần nhất (orderBy date desc, limit 30); "Xem thêm" tải tiếp 30. Mỗi ngày cần đọc 2 response docs → cân nhắc đọc batch theo `collectionGroup` hoặc theo từng date sau khi có marker. Tránh đọc toàn bộ lịch sử 1 lần.
4. **Nội dung câu hỏi theo ngày:** câu hỏi suy từ bank `lib/data/daily_questions.dart` theo day-of-year của `date` đã lưu (giống logic Home). Lưu ý đổi ngôn ngữ runtime → câu hỏi hiển thị theo locale hiện tại, nhưng **câu trả lời giữ nguyên** ngôn ngữ user đã gõ. Không dịch câu trả lời.
5. **Love Note block "của bạn":** dữ liệu đã có sẵn ở provider (`loveNoteProvider.myNote`) — KHÔNG cần thêm query/rules. Chỉ thêm UI + `AnimatedSize`. Đây là phần rẻ, có thể ship độc lập trước Phần 1 nếu muốn.
6. **i18n:** thêm 16 key mới (bảng trên) vào CẢ `app_en.arb` + `app_vi.arb` rồi `flutter gen-l10n`. `journalPartnerAnswerLabel` có placeholder `{name}`.

---

## Handoff / Dev notes

- **Tái dùng tối đa:** `GlassCard` (entry chỉ thêm dòng trong card có sẵn), `ShimmerSkeleton`, `AppMotion`, `flutter_animate` `_OnceEntrance`, `ElevatedButton` theme navy pill, pattern AppBar phẳng + nền gradient của `gallery_screen`/`settings_screen`.
- **Card-ngày dùng card trắng đặc, KHÔNG GlassCard** (cấm glass cho list cuộn — hiệu năng + design-system).
- **Màu lavender đậm cho label partner** `#7C5CD6`: token mới đề xuất bổ sung design system (đặt tên gợi ý `accentLavenderDeep`) để dùng nhất quán; nếu không thêm token thì hardcode hex này.
- **Entry trên Daily Question card** không phá layout state hiện có — chỉ thêm divider + dòng dưới `_buildBody`. Ẩn khi `couple.isWaitingForPartner`.
- **Love Note:** wrap phần thân (note partner + block bạn) trong `AnimatedSize` để card co giãn mượt khi note đổi/biến mất.
- **Settings tile:** đặt section "Kỷ niệm" trên "Tài khoản & dữ liệu"; tile dẫn `Navigator.push(JournalScreen)`.
- **Route:** thêm route mới (vd `/journal`) ở `app_routes.dart` hoặc push trực tiếp — Dev tuỳ pattern hiện có.

### Đề xuất bổ sung design system
- Token màu mới: `accentLavenderDeep #7C5CD6` (label partner trên nền lavender tint .10) — nếu duyệt, Dev thêm vào `app_colors.dart` và cập nhật `project/design-system.md`.

---

## Acceptance (design)

- [x] Mọi state có hình/mô tả (loading/empty/empty-no-partner/success/load-more/error/disabled)
- [x] Copy đủ VI+EN (16 key + ghi chú format ngày theo locale)
- [x] Wireframe rõ từng vùng + token hex/radius/spacing/font cụ thể
- [x] Phụ thuộc kỹ thuật ghi rõ để PO/Dev tính chi phí (marker doc + rules + phân trang)
- [x] Phần 2 (Love Note 2 chiều) có layout + token + điều kiện hiển thị
- [ ] Dev dựng được không cần hỏi lại (PO/Dev xác nhận sau khi đọc)

## Nhật ký design
- [2026-06-04] [Designer] Thiết kế v1: màn Nhật ký câu hỏi (entry trên Daily Question card + tile Settings, list card-ngày trắng đặc trên dreamyMint, 6 state, nút Xem thêm, empty/error). Cải Love Note card 2 chiều (block "Lời nhắn của bạn" gọn + AnimatedSize). 16 copy vi/en. Ghi nhận phụ thuộc kỹ thuật (marker doc index ngày + rules + phân trang 30). Đề xuất token accentLavenderDeep #7C5CD6.
