# 🎨 Design — Couple Streak (Chuỗi ngày kết nối)

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`../../design-system.md`). CHỈ thiết kế, không code.

- **Trạng thái design:** xong (v1 spec)
- **Người/role:** Designer
- **Ngày:** 2026-06-04

---

## 1. Mục tiêu thiết kế

Đưa "chuỗi ngày kết nối" lên Home như một đòn bẩy giữ chân **shame-free**: ăn mừng tiến độ, đệm 1 ngày khi lỡ, không doạ "sắp mất", không confirmshaming. Streak phải gắn vào nghi thức CHUNG sẵn có (Daily Question reveal) để có ý nghĩa cảm xúc — không phải con số khô khan.

Nguyên tắc cảm xúc xuyên suốt (đóng khung mọi copy & state):
- **Tiến bộ > hoàn hảo.** Mọi mốc đều được mừng; lỡ 1 ngày không phải thất bại.
- **"Chúng mình", không "bạn".** Streak là thành tựu của CẢ HAI — copy luôn nói "chúng mình / hai đứa", không quy lỗi cá nhân ("bạn quên trả lời").
- **Nudge mời gọi, không cảnh báo.** Trạng thái chưa-xong/at-risk dùng giọng ấm, lời mời — không icon cảnh báo đỏ, không đếm ngược doạ.

---

## 2. Định nghĩa streak (PO ĐÃ CHỐT — thiết kế bám đúng)

- **1 ngày tính vào streak = CẢ HAI đã trả lời câu hỏi hôm đó** (đúng khoảnh khắc "reveal" của Daily Question). Đây là `hasRevealed` đã có ở `DailyQuestionProvider`.
- **Streak = số ngày LIÊN TIẾP** (đếm lùi từ hôm nay) mà cả hai cùng trả lời.
- Hôm nay là ngày "đang tiếp diễn": nếu hôm nay chưa reveal, streak vẫn = số ngày liên tiếp kết thúc ở **hôm qua** (KHÔNG trừ, KHÔNG báo mất).
- **Grace/đệm = 1 ngày.** Lỡ đúng 1 ngày (hôm qua không reveal nhưng hôm kia có) → streak chuyển trạng thái **at-risk**, giữ nguyên con số, mời quay lại. Trả lời trong "hôm nay" để cứu chuỗi → nối tiếp. Vượt quá đệm (≥2 ngày liên tiếp không reveal) → reset về 0 nhưng **đóng khung tích cực** ("bắt đầu chuỗi mới").
- "Ngày" = lịch local máy (như Daily Question). LDR lệch múi giờ chấp nhận v1.

---

## 3. Vị trí & hình hài trên Home

### Quyết định: streak là một **chip pill gắn vào CounterCard hero**, KHÔNG phải card riêng

Lý do:
- Home đã dài (hero glass → CounterCard → CTA ảnh → milestone → Love Note → Daily Question → On-this-day → recent photos). Thêm một full-width card nữa = lặp nhịp, đẩy Daily Question xuống sâu.
- Streak và "đếm ngày yêu" là 2 con số "đời sống couple" cùng họ → đặt cạnh nhau tạo cụm "sức khoẻ tình cảm" mạch lạc. CounterCard là HERO gradient sunsetRomance — streak chip nổi ngay đó được "ăn theo" độ nổi bật mà không tốn 1 block dọc.
- Chip nhỏ → không cướp spotlight con số serif 76px của CounterCard; chỉ là "huy hiệu sống động" phía dưới.

**Vị trí chính xác:** một **StreakChip** đặt ở chân CounterCard (bên trong card hero, dưới dòng footer "Còn N ngày tới kỷ niệm"), căn giữa. Dev gắn qua slot mới `footerExtra` của CounterCard (xem Dev notes — KHÔNG phá API cũ).

**Tap chip → mở StreakSheet** (bottom sheet giải thích chuỗi + nudge hành động), không phải route mới. Sheet là nơi kể "luật chơi" mềm mại + nút dẫn xuống Daily Question card.

**Liên kết với Daily Question card:** khi hôm nay CHƯA reveal, Daily Question card đã là nơi hành động. Tap "Trả lời ngay" trong StreakSheet → cuộn Home tới Daily Question card (Dev: dùng `Scrollable.ensureVisible` lên key card). KHÔNG mở input riêng cho streak — streak không có hành động riêng, nó phản chiếu Daily Question.

### Có hiện ở màn Nhật ký (Journal) không?

**Có — một dòng tóm tắt nhẹ ở đầu JournalScreen**, không phải chip tương tác. Journal là nơi xem lại các ngày cả hai đã reveal → rất tự nhiên để hiển thị "🌸 Chuỗi hiện tại: 12 ngày · Dài nhất: 30 ngày" như một thống kê đầu trang (read-only, không tap). Tái dùng cùng provider, không thêm widget phức tạp. Đây là chỗ DUY NHẤT hiện "longest streak" (kỷ lục) vì Home cần gọn.

### Wireframe ASCII — Home (cụm hero + streak)

```
┌─────────────────────────────────────────────┐
│  ✦ TÌNH YÊU                          ♥        │  ← header eyebrow (cũ)
│  Trang chủ                                    │
│  Chào buổi sáng, hai đứa nhé                  │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│  ☀  Chào  An  ♥  Bình                         │  ← hero glass (cũ)
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐  ← CounterCard HERO
│   gradient sunsetRomance                      │     (sunsetRomance, r28)
│                                               │
│            1   năm   2   tháng   5  ngày      │  ← số serif 76px (cũ)
│                                               │
│        Bắt đầu từ 12 thg 4, 2024              │  ← subtitle (cũ)
│        Còn 38 ngày tới kỷ niệm 💞             │  ← footer (cũ)
│                                               │
│      ┌───────────────────────────────┐        │  ← StreakChip (MỚI)
│      │  🌸  12 ngày kết nối  ·  hôm   │ tap →  │     footerExtra slot
│      │      nay sáng rồi  ✨          │        │
│      └───────────────────────────────┘        │
└─────────────────────────────────────────────┘
            ↑ chip pill r999, nền trắng .18 glass, viền trắng .30
┌─────────────────────────────────────────────┐
│  📷  Thêm kỷ niệm                       ›     │  ← CTA ảnh (cũ)
└─────────────────────────────────────────────┘
        … milestone progress · Love Note …
┌─────────────────────────────────────────────┐
│  ❓ Câu hỏi hôm nay                            │  ← Daily Question (cũ)
│  "Điều gì khiến em cười hôm nay?"             │     ← streak hành động Ở ĐÂY
│  [ ô nhập … ]                  [Gửi]          │
└─────────────────────────────────────────────┘
```

### Wireframe ASCII — StreakSheet (tap chip)

```
        ╭──────────────────────────────╮
        │           ▁▁▁▁               │  ← grab handle
        │                              │
        │            🌸                │  ← biểu tượng lớn (state-tuỳ)
        │                              │
        │           12                 │  ← số serif 56px gradient
        │     ngày kết nối liên tiếp   │
        │                              │
        │  Hai đứa cùng trả lời câu     │  ← giải thích mềm
        │  hỏi mỗi ngày — giữ ngọn lửa │
        │  nhỏ này cháy nhé 💞          │
        │                              │
        │  ┌──────────────────────┐    │  ← progress tới mốc kế (3/7/30…)
        │  │ ▓▓▓▓▓▓▓░░░  12 → 30   │    │
        │  └──────────────────────┘    │
        │  Còn 18 ngày tới mốc 30 🎉    │
        │                              │
        │   ┌────────────────────┐     │  ← CTA (chỉ khi hôm nay chưa xong)
        │   │   Trả lời ngay  →  │     │     → cuộn tới Daily Question
        │   └────────────────────┘     │
        ╰──────────────────────────────╯
```

### Wireframe ASCII — Journal header (1 dòng)

```
┌─────────────────────────────────────────────┐
│  ✦ NHẬT KÝ                                    │
│  Nhật ký của chúng mình                       │
│  🌸 Chuỗi hiện tại 12 ngày · Dài nhất 30      │  ← MỚI, read-only
└─────────────────────────────────────────────┘
   … danh sách ngày đã reveal (cũ) …
```

---

## 4. Biểu tượng streak — đề xuất & lý do

**Quyết định: KHÔNG dùng lửa cam 🔥. Dùng motif "đốm lửa hồng" = trái tim/hoa phát sáng theo độ mạnh chuỗi.** Cụ thể:

- **Icon chủ đạo: `LucideIcons.flame` nhưng tô màu brand hồng** (`accentRose #FF4D6D`), KHÔNG để màu lửa cam mặc định. "Ngọn lửa hồng" giữ ẩn dụ "streak = ngọn lửa cần giữ cháy" (quen thuộc, dễ hiểu ngay) nhưng nhuộm về "Sunset Romance" để không lạc tông warning/cam.
- **Emoji trong copy: 🌸 (hoa) cho trạng thái thường, 🔥 CHỈ ở mốc lớn** (xem bảng celebration). Trong thân copy hằng ngày ưu tiên 🌸/✨/💞 — ấm, nữ tính, hợp brand hơn 🔥 cam.
- **Cường độ theo streak** (glow + màu icon tăng dần, tạo cảm giác "lớn lên"):
  - 0 ngày: icon outline `flame` màu `textTertiary #A0A0B0`, không glow ("chưa thắp").
  - 1–6 ngày: `flame` fill `accentCoral #FF8FA3`, glow nhẹ.
  - 7–29 ngày: `flame` fill `accentRose #FF4D6D`, glow vừa.
  - 30+ ngày: `flame` fill `accentLoveDeep #E63956` + viền gradient sunsetRomance quanh chip, glow mạnh.
- Lý do không thuần trái tim: app đã dùng `Icons.favorite` dày đặc (nav, hero, reactions) → trái tim nữa sẽ "chìm". Ngọn lửa hồng tạo motif RIÊNG cho streak, vẫn brand-consistent qua màu.

> Đề xuất bổ sung design system (nhỏ): thêm token semantic `streakFlame` = alias `accentRose` để Dev dùng nhất quán; KHÔNG thêm màu mới (toàn bộ dùng accent đã có).

---

## 5. States — đầy đủ + cơ chế shame-free từng cái

Tất cả states render trong **StreakChip** (Home) và mở rộng trong **StreakSheet**. Trạng thái do `StreakProvider` cung cấp một enum (gợi ý Dev): `noStreak`, `activeToday`, `inProgress`, `atRisk`, `milestone`, `hidden`.

### 5.0 `hidden` — Couple chưa active (chưa có partner)
- **Khi:** `couple.isWaitingForPartner == true`.
- **Hành vi:** StreakChip **không hiển thị** (streak cần hành động của CẢ HAI → vô nghĩa khi một mình). Tránh empty-state buồn ngay hero.
- **Thay thế (tuỳ chọn, nhẹ):** không thêm gì ở chip; banner "chờ partner" đã có sẵn phía trên CounterCard làm nhiệm vụ mời. → giữ Home sạch.
- **Shame-free:** không có gì để "lỡ" → không hiển thị = đúng.

### 5.1 `noStreak` — Đã ghép đôi nhưng chưa có ngày nào cả hai cùng reveal
- **Khi:** couple active, `currentStreak == 0`, chưa từng reveal ngày nào (hoặc vừa reset — xem 5.4b).
- **Chip:** icon `flame` outline `textTertiary`, text **"Bắt đầu chuỗi cùng nhau"** (vi) — giọng mời, không "0 ngày" trơ trọi.
- **Sheet:** số lớn ẩn (hoặc hiện "0" mờ), tiêu đề "Thắp ngọn lửa đầu tiên", body giải thích nghi thức + CTA "Trả lời ngay" (nếu hôm nay chưa trả lời).
- **Shame-free:** đóng khung "khởi đầu", không "bạn chưa có chuỗi nào".

### 5.2 `activeToday` — Đang có chuỗi, HÔM NAY đã reveal (cả hai trả lời) — "rực rỡ"
- **Khi:** `currentStreak >= 1` và hôm nay đã reveal.
- **Chip:** icon `flame` fill (màu theo cường độ §4), glow rõ, text **"N ngày kết nối · hôm nay xong rồi ✨"**. Đây là trạng thái "đầy đủ, mãn nguyện".
- **Vi chỉnh động:** khi `activeToday` vừa xảy ra (reveal mới trong phiên) → chip **pulse 1 lần** (scale 1.0→1.06→1.0, 420ms easeOutCubic) + glow nhấp nháy nhẹ. Confetti chính đã do Daily Question card lo (không double confetti).
- **Sheet:** số lớn rạng rỡ, body "Hôm nay hai đứa đã giữ lửa rồi 💞 Hẹn gặp ở câu hỏi ngày mai!". KHÔNG CTA hành động (đã xong) — chỉ progress tới mốc kế.
- **Shame-free:** đây là phần thưởng — celebration vi mô mỗi ngày.

### 5.3 `inProgress` — Đang có chuỗi, HÔM NAY chưa reveal — "đang tiếp diễn" + nudge nhẹ
- **Khi:** `currentStreak >= 1` (kết thúc ở hôm qua), hôm nay CHƯA reveal (một hoặc cả hai chưa trả lời).
- **Chip:** icon `flame` fill nhưng **glow dịu hơn** (alpha thấp, như "lửa đang chờ thêm củi"), text **"N ngày kết nối · tới lượt hôm nay 🌸"**. KHÔNG chữ "sắp mất", KHÔNG đếm ngược, KHÔNG đỏ.
- **Sheet:** số lớn vẫn hiện đầy đủ (N ngày — chuỗi CHƯA mất), body ấm "Chuỗi vẫn đang cháy nhé. Trả lời câu hỏi hôm nay để hai đứa cùng nối tiếp 💞", **CTA "Trả lời ngay →"** cuộn tới Daily Question.
- **Shame-free:** "chưa xong ≠ mất chuỗi". Con số hôm qua vẫn hiển thị nguyên. Nudge là lời mời tích cực.

### 5.4a `atRisk` — Lỡ đúng 1 ngày, còn đệm (grace)
- **Khi:** hôm qua KHÔNG reveal, nhưng hôm kia có (`currentStreak` tính tới hôm kia ≥ 1) → đang dùng đệm 1 ngày. Trả lời trong "hôm nay" → cứu chuỗi (nối tiếp, streak +1 từ giá trị cũ); KHÔNG trả lời hôm nay nữa → ngày mai chuyển `noStreak`/reset (5.4b).
- **Chip:** icon `flame` fill màu `accentCoral` (ấm, không đỏ cảnh báo) + **icon phụ nhỏ `LucideIcons.sparkles`** thay vì cảnh báo, text **"Chuỗi N ngày đang chờ hai đứa 🫶"**. Tuyệt đối không "⚠️ sắp mất chuỗi".
- **Sheet:** số lớn vẫn hiện N (chưa mất!), body **"Hôm qua hai đứa lỡ một nhịp — không sao cả 🫶 Trả lời hôm nay là chuỗi N ngày lại tiếp tục liền!"**, CTA "Giữ chuỗi nhé →" cuộn tới Daily Question. Có thể thêm 1 dòng micro mô tả đệm: "Chúng mình có một ngày đệm — dùng nó hôm nay nha."
- **Shame-free (CỐT LÕI):** đây là điểm dễ confirmshame nhất. Giọng = bạn thân an ủi ("không sao cả"), nhấn cơ hội cứu, KHÔNG nhấn mất mát. Không dùng màu error đỏ, không icon cảnh báo.

### 5.4b `reset` → quay về `noStreak` với khung tích cực
- **Khi:** đã vượt đệm (≥2 ngày liên tiếp không reveal) → `currentStreak` về 0.
- **Hành vi:** hiển thị như `noStreak` (5.1) NHƯNG nếu couple từng có chuỗi, dùng copy biến thể "khởi động lại": **"Cùng bắt đầu chuỗi mới nhé 🌱"** (không bao giờ "Bạn đã mất X ngày").
- **Sheet:** nếu có `longestStreak > 0`, hiện nhẹ "Kỷ lục của hai đứa: M ngày 🌟 — phá nó nào!" như động lực, KHÔNG như trách móc.
- **Shame-free (CỐT LÕI):** tuyệt đối KHÔNG hiển thị con số đã mất, KHÔNG "reset về 0" như hình phạt. Frame = "mầm mới / cơ hội mới".

### 5.5 `milestone` — Vừa đạt mốc (3 / 7 / 30 / 100 / 365)
- **Khi:** `activeToday` VÀ `currentStreak` vừa chạm đúng một mốc trong {3,7,30,100,365} lần đầu (Dev: guard one-shot per mốc, lưu mốc đã mừng để không lặp).
- **Hành vi:** xem §6 (celebration). Sau khi đóng celebration, chip về `activeToday` với badge mốc.
- **Shame-free:** thuần ăn mừng.

#### Bảng tóm tắt loading/error
| State kỹ thuật | Chip | Ghi chú |
|---|---|---|
| **Loading** (provider đang đọc marker lần đầu) | Chip render dạng ShimmerSkeleton pill (w140 h32 r999) trong footerExtra | Tái dùng `ShimmerSkeleton`; KHÔNG spinner |
| **Error** (đọc marker fail) | Chip **ẩn hoàn toàn** (fail-soft) | Streak là "nice-to-have"; lỗi không được phá hero. Không hiện toast lỗi. |
| **Disabled** | Không có khái niệm disabled riêng — `hidden` (chưa partner) đã bao trùm | — |

---

## 6. Celebration mốc (3 / 7 / 30 / 100 / 365)

Tái dùng `confetti` (đã import sẵn ở home_screen) + `LoveLottie` slot (đã có hạ tầng, fallback SizedBox khi thiếu asset) + `HapticFeedback`.

### Khoảnh khắc
Khi reveal hôm nay đẩy streak chạm mốc:
1. **Daily Question card** vẫn bắn confetti reveal như cũ (không đổi).
2. **Ngay sau** (delay 400ms cho confetti reveal lắng), **StreakSheet tự bật lên** ở chế độ "milestone celebration" (auto-show 1 lần — Dev guard per mốc). Đây là khoảnh khắc đỉnh, không chỉ một con số đổi.
3. Trong sheet: số mốc **count-up** từ (mốc−vài) → mốc bằng serif gradient (AppMotion.slow 320ms), confetti riêng của sheet bắn từ đỉnh (cùng config 14 particles, màu rose/lavender/coral/white như Daily card), `HapticFeedback.mediumImpact()`, icon flame phóng to + glow gradient.
4. Badge mốc xuất hiện trên chip sau khi đóng sheet (pill nhỏ "🔥 30" cạnh số ngày — chỉ ở mốc ≥30 để badge không nhiễu).

### Phân cấp cường độ (mốc càng lớn càng "đã")
| Mốc | Emoji headline | Confetti | Đặc biệt |
|---|---|---|---|
| **3 ngày** | 🌸 | nhẹ (14 particles) | "khởi đầu đẹp" — mừng nhỏ, khích lệ |
| **7 ngày** | ✨ | vừa (18) | "vượt tuần đầu" — nhấn cột mốc loss-aversion 2.3× |
| **30 ngày** | 🔥 | mạnh (24) | badge "🔥 30" trên chip từ đây |
| **100 ngày** | 💯 | mạnh + lottie | "trăm ngày" — câu copy đặc biệt long-form |
| **365 ngày** | 👑 | mạnh nhất (30) + lottie | "một năm" — celebration lớn nhất, gợi chia sẻ |

- **Animation:** số count-up 320ms easeOutCubic; sheet trượt lên 280ms easeOutCubic; icon flame scale 0.6→1.0 elasticOut 500ms; confetti 600ms one-shot.
- **Tần suất an toàn:** mỗi mốc celebrate đúng 1 lần đời chuỗi đó (Dev lưu `celebratedMilestones` per couple). Nếu reset rồi đạt lại mốc cũ → được mừng lại (chuỗi mới = thành tựu mới) — đây là tích cực, không phải bug.

---

## 7. Spec chi tiết (token chính xác)

### StreakChip (trong CounterCard footerExtra)
- **Hình:** pill `Container`, `borderRadius: 999`.
- **Nền:** `AppColors.white.withValues(alpha: 0.18)` (glass nhẹ trên gradient hero), viền `white .30` width 1.0. (Cùng ngôn ngữ với invite-code chip trên banner chờ partner.)
- **Padding:** horizontal 14, vertical 8.
- **Layout:** `Row(mainAxisSize.min)` → [icon flame 16px] · gap 8 · [Text]. Căn giữa trong card (`Center`).
- **Icon:** `LucideIcons.flame` size 16, màu theo cường độ §4 (trên nền hero gradient ưu tiên `AppColors.white` cho text; flame giữ màu accent để nổi đốm lửa — coral/rose/loveDeep).
- **Text:** `fontSize 13, w700, color white, letterSpacing -0.1`. Một dòng, `maxLines 1, ellipsis`.
- **Glow (state activeToday/milestone):** `BoxShadow(color: accentRose.withAlpha(.35), blurRadius 16, offset (0,4))`. inProgress: alpha .18. atRisk: dùng accentCoral .25. noStreak: không shadow.
- **Badge mốc (≥30):** pill con bên phải số ngày: nền `accentLoveDeep`, text trắng 10px w800, vd "🔥 30".
- **Tap target:** bọc `Material + InkWell` r999, splash white .15, `HapticFeedback.selectionClick()` khi mở sheet.

### StreakSheet (bottom sheet)
- **Khung:** giống `_LoveNoteSheet` — `ClipRRect` top radius 28 + `BackdropFilter blur 20`, nền `AppColors.cardSurface #FFFFFF`, padding `(20,12,20,24)`, grab handle 40×4 `textTertiary .4` r999.
- **Số lớn:** `AppTheme.displaySerif(size: 56, weight w600)` màu — KHÔNG để trắng (sheet nền trắng): dùng `ShaderMask` gradient `sunsetRomance` cho số, hoặc đặc `accentLoveDeep`. → đề xuất ShaderMask sunsetRomance cho cảm giác "rực".
- **Label dưới số:** "ngày kết nối liên tiếp" — `textSecondary #6B6B7B`, 14px w600.
- **Body giải thích:** `textSecondary`, 14px, height 1.5.
- **Progress bar tới mốc kế:** tái dùng pattern `LinearProgressIndicator` của milestone (minHeight 10, r999, track `surfaceLight`, value `accentRose`). Label "Còn X ngày tới mốc Y 🎉" `textSecondary` 13px.
- **CTA "Trả lời ngay":** `ElevatedButton` height 52 nền navy (`textPrimary`) bo pill — chuẩn nút chính design system. Icon `LucideIcons.arrowRight`.
- **Icon flame lớn (đỉnh sheet):** size 56, màu theo cường độ + glow.

### Journal header dòng streak
- Một `Row`: icon flame 14 (accentRose) · gap 6 · `Text` "Chuỗi hiện tại N ngày · Dài nhất M" — `fontSize 13, w600, color` theo nền header (header journal nền dawnBlush → text `textPrimary` hoặc trắng tuỳ nền hiện tại; bám màu eyebrow/subtitle đang dùng ở JournalScreen). Read-only, không InkWell.

### Spacing & nhịp
- Chip cách footer CounterCard: `SizedBox(height: 14)` phía trên chip (trong card).
- Sheet: số → label 6px; label → body 16px; body → progress 20px; progress → CTA 20px.

---

## 8. Interaction & animation (duration + curve)

| Tương tác | Animation | Duration | Curve |
|---|---|---|---|
| Reveal mới hôm nay → chip vào `activeToday` | scale pulse 1.0→1.06→1.0 + glow fade-in | 420ms | easeOutCubic |
| Tap chip → mở sheet | bottom-sheet slide up (mặc định) + `selectionClick` haptic | 280ms | easeOutCubic |
| Mốc → số count-up trong sheet | tween int | 320ms | easeOutCubic |
| Mốc → icon flame phóng to | scale 0.6→1.0 | 500ms | elasticOut |
| Mốc → confetti | one-shot | 600ms | — |
| Mốc → sheet auto-show | delay sau confetti reveal | 400ms delay | — |
| Chip xuất hiện lần đầu (entrance Home) | nằm trong CounterCard → đi theo `_entrance(3)` đã có | 360ms | easeOutCubic |
| atRisk/inProgress | KHÔNG animation doạ (không nhấp nháy đỏ, không rung) | — | — |

- **Haptic:** `selectionClick` khi mở sheet; `mediumImpact` ở khoảnh khắc mốc. KHÔNG haptic cho atRisk (tránh cảm giác cảnh báo).
- **Reduce motion:** nếu sau này hỗ trợ — count-up & pulse fallback về set tức thì; confetti vẫn cho phép (nhẹ). v1 không bắt buộc.

---

## 9. Copy song ngữ (vi + en) — TẤT CẢ shame-free

> Quy ước key: prefix `streak*`. Tái dùng/đổi 2 stub có sẵn: `dayStreakLabel` → đổi thành nhãn chung; `dayStreakValue` → bỏ hoặc map vào `streakChipActive`. Dev thêm vào CẢ `app_vi.arb` + `app_en.arb` rồi `gen-l10n`. `{n}` = số ngày, `{m}` = mốc kế / kỷ lục, `{name}` = không dùng (streak là "chúng mình").

### 9.1 Chip (Home)
| Key | VI | EN |
|---|---|---|
| `streakChipNoStreak` | Bắt đầu chuỗi cùng nhau | Start a streak together |
| `streakChipRestart` | Cùng bắt đầu chuỗi mới nhé 🌱 | Let's start a new streak 🌱 |
| `streakChipActiveToday` | {n} ngày kết nối · hôm nay xong rồi ✨ | {n}-day streak · done for today ✨ |
| `streakChipInProgress` | {n} ngày kết nối · tới lượt hôm nay 🌸 | {n}-day streak · today's your turn 🌸 |
| `streakChipAtRisk` | Chuỗi {n} ngày đang chờ hai đứa 🫶 | Your {n}-day streak is waiting 🫶 |

### 9.2 Sheet — tiêu đề & body theo state
| Key | VI | EN |
|---|---|---|
| `streakSheetUnit` | ngày kết nối liên tiếp | days connected in a row |
| `streakSheetNoStreakTitle` | Thắp ngọn lửa đầu tiên | Light your first spark |
| `streakSheetNoStreakBody` | Mỗi ngày hai đứa cùng trả lời câu hỏi là chuỗi lại dài thêm. Cùng bắt đầu nhé 💞 | Each day you both answer the question, your streak grows. Let's begin 💞 |
| `streakSheetActiveTitle` | Hai đứa đang giữ lửa 💞 | You're keeping the spark alive 💞 |
| `streakSheetActiveBody` | Hôm nay xong rồi đó! Hẹn gặp ở câu hỏi ngày mai nha. | All done today! See you at tomorrow's question. |
| `streakSheetInProgressTitle` | Chuỗi vẫn đang cháy 🌸 | Your streak's still glowing 🌸 |
| `streakSheetInProgressBody` | Trả lời câu hỏi hôm nay để hai đứa cùng nối tiếp chuỗi {n} ngày nhé 💞 | Answer today's question to keep your {n}-day streak going 💞 |
| `streakSheetAtRiskTitle` | Còn một nhịp đệm thôi 🫶 | One soft day left 🫶 |
| `streakSheetAtRiskBody` | Hôm qua hai đứa lỡ một nhịp — không sao cả! Trả lời hôm nay là chuỗi {n} ngày tiếp tục liền. | You missed a beat yesterday — totally okay! Answer today and your {n}-day streak picks right back up. |
| `streakSheetRestartBody` | Chuỗi cũ khép lại rồi, nhưng mỗi ngày mới là một khởi đầu. Cùng thắp lại nào 🌱 | The old streak wrapped up, but every new day's a fresh start. Let's light it again 🌱 |
| `streakSheetRecord` | Kỷ lục của hai đứa: {m} ngày 🌟 | Your record: {m} days 🌟 |

### 9.3 Sheet — progress & CTA
| Key | VI | EN |
|---|---|---|
| `streakNextMilestone` | Còn {n} ngày tới mốc {m} 🎉 | {n} days to your {m}-day milestone 🎉 |
| `streakCtaAnswerNow` | Trả lời ngay | Answer now |
| `streakCtaKeepGoing` | Giữ chuỗi nhé | Keep it going |

### 9.4 Celebration theo mốc
| Key | VI | EN |
|---|---|---|
| `streakMilestone3Title` | 3 ngày rồi đó! 🌸 | 3 days already! 🌸 |
| `streakMilestone3Body` | Khởi đầu thật đáng yêu. Hai đứa đang làm tốt lắm 💞 | What a sweet start. You two are doing great 💞 |
| `streakMilestone7Title` | Trọn một tuần! ✨ | A whole week! ✨ |
| `streakMilestone7Body` | 7 ngày liền hai đứa không lỡ nhịp nào. Tự hào ghê! | 7 days without missing a beat. So proud of you both! |
| `streakMilestone30Title` | 30 ngày bên nhau mỗi ngày! 🔥 | 30 days, every single day! 🔥 |
| `streakMilestone30Body` | Một tháng giữ lửa — đây là thói quen của hai đứa rồi đấy 💞 | A month of keeping it lit — this is your ritual now 💞 |
| `streakMilestone100Title` | 100 ngày! 💯 | 100 days! 💯 |
| `streakMilestone100Body` | Trăm ngày cùng nhau trả lời, cùng nhau lớn lên. Hiếm cặp nào làm được như hai đứa 🌟 | A hundred days answering together, growing together. Few couples make it this far 🌟 |
| `streakMilestone365Title` | Tròn một năm! 👑 | A full year! 👑 |
| `streakMilestone365Body` | 365 ngày không lỡ một nhịp kết nối. Đây là chuyện tình của riêng hai đứa 💞👑 | 365 days of never missing your connection. This is your love story 💞👑 |

### 9.5 Journal header
| Key | VI | EN |
|---|---|---|
| `streakJournalSummary` | Chuỗi hiện tại {n} ngày · Dài nhất {m} | {n}-day streak · longest {m} |
| `streakJournalSummaryNone` | Cùng trả lời mỗi ngày để bắt đầu chuỗi nhé 🌸 | Answer together each day to start a streak 🌸 |

> ⚠️ Lưu ý ICU: các chuỗi có 🌸/💞/🔥 là emoji thường, KHÔNG phải placeholder — an toàn. Tránh dấu `{` `}` ngoài `{n}/{m}`. Khai báo `@key` với placeholder kiểu `int` cho n/m.

---

## 10. Assets
- **Không cần asset mới bắt buộc.** Icon dùng `LucideIcons.flame`, `sparkles`, `arrowRight`, `bookOpen` (đã có trong bộ lucide). Confetti dùng package sẵn. Emoji là Unicode.
- **Tuỳ chọn (Đợt sau, không chặn):** `LoveLottie` slot mới `streakMilestone` cho mốc 100/365 (đã có hạ tầng `LoveLottie` + fallback SizedBox khi thiếu file → an toàn build mà chưa có asset). Nếu PO muốn, thêm slot vào enum `LoveLottieSlot` (Dev việc) — KHÔNG bắt buộc v1.

---

## 11. Phụ thuộc kỹ thuật (ghi nhận cho Dev — Designer KHÔNG giải)

1. **Marker cần thêm cờ.** `dailyAnswers/{date}` hiện = `{date, questionVi, questionEn, updatedAt}` (`daily_question_service.dart` `submitAnswer`). Để StreakProvider biết "ngày nào CẢ HAI đã trả lời" mà không phải đọc hết `responses` mỗi ngày, Dev set thêm khi người thứ 2 trả lời:
   - `bothAnswered: true` (hoặc `revealedAt: serverTimestamp`).
   - Cách rẻ: trong `submitAnswer`, sau khi ghi response, đọc count responses (≤2); nếu =2 → merge `bothAnswered:true, revealedAt:...` vào marker. Hoặc làm ở CF `notifyDailyAnswer` (đã onCreate response — biết khi nào đủ 2). → Dev chọn, ghi rõ trong dev.md.
   - **Rules:** marker rule hiện chỉ yêu cầu `date/questionVi/questionEn` có mặt cho member ghi → thêm field `bothAnswered/revealedAt` KHÔNG phá validate (additive). KHÔNG cần rule/CF MỚI bắt buộc; nếu set ở CF thì CF dùng admin (bỏ qua rules).
2. **StreakProvider (mới).** Đọc `dailyAnswers` orderBy date desc (giới hạn vd 60 doc đủ cho mọi mốc thường gặp + grace), lọc `bothAnswered==true`, đếm ngày LIÊN TIẾP lùi từ hôm nay theo lịch local:
   - Nếu hôm nay revealed → `activeToday`, streak = chuỗi liên tiếp gồm hôm nay.
   - Nếu hôm nay chưa nhưng hôm qua revealed → `inProgress`, streak = chuỗi tới hôm qua.
   - Nếu hôm nay & hôm qua chưa nhưng hôm kia revealed → `atRisk`, streak = chuỗi tới hôm kia (đang dùng đệm).
   - Nếu ≥2 ngày liên tiếp gần nhất không revealed → `noStreak` (0), giữ cờ "đã-từng-có-chuỗi" để chọn copy `restart` vs `noStreak`.
   - Wire watch ở `session_resolver` khi couple active, clear khi sign-out/no-couple (giống daily_question/love_note).
3. **`longestStreak` (kỷ lục) lưu ở đâu:**
   - **Khuyến nghị:** lưu trên `couples/{coupleId}` field `longestStreak: int` (+ `lastStreakDate` để chống ghi đè lùi), cập nhật khi `currentStreak > longestStreak` (client ghi qua existing couple update path; rules couple cho member update). Lý do: suy "longest" từ history đòi đọc toàn bộ marker mỗi lần (đắt) — lưu sẵn rẻ & hiện ngay ở Journal/sheet.
   - Nếu PO không muốn đụng couple doc/rules → fallback v1: suy longest từ trang marker đã tải (chấp nhận chỉ tính trong cửa sổ ~60 ngày). Designer KHUYẾN NGHỊ lưu trên couple doc.
4. **One-shot guards:** (a) chip pulse khi reveal mới — chỉ trong phiên (giống `_confettiPlayed` của Daily card). (b) celebration mốc — lưu `celebratedMilestones` (set per couple, Hive cục bộ hoặc field couple) để không bật lại sheet mỗi lần mở Home. Reset chuỗi → cho phép mừng lại mốc cũ (đúng ý đồ).
5. **CounterCard `footerExtra` slot:** Dev thêm optional `Widget? footerExtra` vào `CounterCard` (render dưới footer, center). Giữ default null → không phá mọi call-site khác. Đây là điểm tích hợp chip — KHÔNG sửa layout số serif.
6. **Cuộn tới Daily Question từ sheet:** CTA "Trả lời ngay" pop sheet rồi `Scrollable.ensureVisible` lên `GlobalKey` của Daily Question card (Dev gắn key). Hoặc đơn giản pop sheet + để user thấy card (nếu ensureVisible phức tạp, v1 chỉ cần pop sheet — card ở ngay dưới).
7. **"Ngày" = local calendar** (tái dùng `DailyQuestionService.dateKey`). LDR lệch giờ: chấp nhận v1 (PO đã chốt cho daily-question).

---

## 12. Handoff / Dev notes (gọn)
- Streak = view phái sinh từ marker `dailyAnswers` — KHÔNG tạo collection mới, KHÔNG đổi schema response.
- Fail-soft tuyệt đối: lỗi đọc streak → ẩn chip, không toast, không phá hero.
- KHÔNG double-confetti: mốc dùng confetti của StreakSheet; reveal thường vẫn dùng confetti của Daily card.
- Toàn bộ màu lấy từ `AppColors` hiện có (accentRose/Coral/LoveDeep/textTertiary, sunsetRomance). KHÔNG thêm màu mới; chỉ đề xuất alias semantic `streakFlame=accentRose` (tuỳ Dev).
- i18n: thêm CẢ `app_vi.arb` + `app_en.arb`, placeholder `n/m` kiểu int, rồi `fvm flutter gen-l10n`. Cân nhắc dọn 2 stub cũ `dayStreakLabel/dayStreakValue` (chưa dùng).

## 13. Acceptance (design)
- [x] Mọi state có mô tả + cơ chế shame-free riêng (hidden/noStreak/activeToday/inProgress/atRisk/reset/milestone + loading/error).
- [x] Wireframe Home + StreakSheet + Journal header.
- [x] Token cụ thể (màu hex, radius, padding, typography, shadow, animation duration+curve).
- [x] Copy đủ VI+EN mọi state + 5 mốc, tất cả shame-free, không confirmshaming.
- [x] Mục "Phụ thuộc kỹ thuật" cho Dev (marker flag, StreakProvider, longestStreak, guards, footerExtra slot).
- [x] Dev dựng được không cần hỏi lại (trừ các "quyết định mở" gửi PO bên dưới).

## Nhật ký design
- [2026-06-04] [Designer] Thiết kế Couple Streak shame-free: StreakChip gắn footer CounterCard + StreakSheet + Journal summary. 7 state (hidden/noStreak/activeToday/inProgress/atRisk/reset/milestone) mỗi cái có cơ chế chống-shame. Biểu tượng "ngọn lửa hồng" (lucide flame nhuộm accent, KHÔNG cam). Celebration 5 mốc (3/7/30/100/365) dùng confetti sẵn. Copy đầy đủ vi+en. Ghi phụ thuộc kỹ thuật (marker bothAnswered, StreakProvider, longestStreak trên couple doc, footerExtra slot).
