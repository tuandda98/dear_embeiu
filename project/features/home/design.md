# Home (Trang chủ) — Design review & spec cải thiện

> File Designer sở hữu. Review bởi persona product designer 10 năm kinh nghiệm mobile (2026-06-10), trên code thật `lib/screens/home_screen.dart` (2.584 dòng) + `lib/widgets/counter_card.dart` + design system hiện hành.
> ⚠️ Folder này chưa có `overview.md` (PO) — design này là output của lượt review trực tiếp theo yêu cầu user; PO bổ sung overview khi chốt scope.

---

## PHẦN 1 — REVIEW

### 1.1 Điểm mạnh (giữ nguyên, đừng "sửa" nhầm)

- **Token hoá tốt:** màu/gradient/motion tập trung ở `app_colors.dart`/`app_theme.dart`/`app_motion.dart`; 1 phông Be Vietnam Pro toàn app — đúng hướng.
- **CounterCard là emotional anchor đúng nghĩa** — gradient + glow + heart badge, hierarchy nội bộ chuẩn.
- **Loading skeleton content-shaped** (không spinner trống) — đúng best practice.
- **Habit-loop features đã đủ nguyên liệu** (daily question, love note, streak, on-this-day) — vấn đề chỉ là *sắp xếp*, không phải thiếu.
- **Concurrency/lifecycle các animation xử lý kỹ** (entrance không replay, confetti one-shot) — không đụng vào.

### 1.2 Vấn đề cấp HỆ THỐNG (design system)

| # | Vấn đề | Mức | Chi tiết |
|---|--------|-----|----------|
| S1 | **Text-trên-glass có 2 chế độ không quy tắc** | 🔴 | Love note + daily question dùng chữ TỐI (`textPrimary`) trên GlassCard; hero greeting + on-this-day dùng chữ TRẮNG trên cùng loại GlassCard, cùng nền dawnBlush. On-this-day: trắng alpha .82, 12.5px trên glass sáng → **contrast fail WCAG AA**. Cần chốt quy tắc: *GlassCard trên nền gradient sáng → chữ tối; chữ trắng chỉ dành cho nền gradient đậm (CounterCard, nav pill)*. |
| S2 | **Tap feedback không nhất quán với quy ước revamp** ("tile bấm → InkWell ripple") | 🟡 | Home còn `GestureDetector` trần ở: bell (`_buildNotificationBell`), CTA Thêm kỷ niệm, recent photo card, on-this-day card, CounterCard. Không ripple → cảm giác "chết" khi bấm. |
| S3 | **`displaySerif` tên stale** (không còn serif từ 2026-06-06) | ⚪ P3 | Đổi tên `displayStyle` khi tiện — cosmetic, không chặn gì. |
| S4 | **Docs stale:** CLAUDE.md mục 2 + design-system.md vẫn mô tả Home có "quote card" — code đã bỏ | ⚪ | Cập nhật docs (đã sửa kèm lượt này ở design-system? — chưa, để PO/Dev sync khi implement). |
| S5 | Radius nút-trong-card = 16 (write note / send) chưa có trong bảng token (chỉ có input 20, tile 22-24) | ⚪ | Hợp thức hoá: **nút full-width trong card = 16** (đã dùng nhất quán 3 chỗ, chỉ cần ghi vào token). |

### 1.3 Vấn đề cấp TRANG CHỦ (IA / UX)

| # | Vấn đề | Mức | Chi tiết |
|---|--------|-----|----------|
| H1 | **Header trùng lặp, đốt ~160px first viewport** | 🔴 | Trang có 2 "header": (badge eyebrow + title "Trang chủ" 32px + subtitle) **và** hero glass "Hello, P1 ♥ P2". Title "Trang chủ" là thông tin chết (user biết mình đang ở đâu — đã có nav pill). Hệ quả: **CounterCard — linh hồn app — bị đẩy xuống mép/dưới fold** trên máy nhỏ (iPhone SE/13 mini). |
| H2 | **Thứ tự block ngược với habit loop** | 🔴 | Hiện tại: header → hero → counter → CTA ảnh → **milestone (tĩnh)** → love note → **daily question (lý do mở app mỗi ngày!)** → on-this-day → recent. Daily question nằm vị trí ~8/10, dưới 1 progress bar tĩnh xem 1 lần/tuần cũng được. Trigger hằng ngày phải nằm ngay sau emotional anchor. |
| H3 | **Nhịp section loạn** | 🟡 | "Khoảnh khắc"/"Cột mốc"/"Kỷ niệm gần đây" có section title NGOÀI card; love note/daily question/on-this-day thì title NẰM TRONG card; spacing 20 đều tăm tắp → không có chunking (Gestalt proximity), trang đọc như 1 chuỗi card rời. |
| H4 | **Recent photo tap → chỉ nhảy tab Gallery**, không mở đúng ảnh | 🟡 | Trong khi on-this-day đã dùng `GalleryScreen.openPreview` mở đúng ảnh — pattern CÓ SẴN. Đây là kỳ vọng cơ bản của user (tap thumbnail = xem ảnh đó). Đã ghi nợ Phase 2 home-engagement, giờ trả. |
| H5 | **Skeleton drift:** `_buildHomeLoadingSkeleton` vẫn mô phỏng layout cũ (row 2 quick-action đã xoá) | 🟡 | Skeleton phải khớp layout thật, nếu không lúc load xong bị "nhảy hình". |
| H6 | **A11y:** bell không `Semantics`/tooltip (badge unread reader không đọc được); nav label 10px + badge 10px dưới ngưỡng khuyến nghị 11; icon nav unselected trắng .55 trên glass sáng — contrast thấp | 🟡 | Sửa rẻ, nên gom vào lượt này. |
| H7 | RefreshIndicator rose trên nền hồng — spinner gần như tàng hình | ⚪ | Thêm `backgroundColor: white`. |
| H8 | Greeting tĩnh "Hello" — bỏ lỡ cơ hội "app sống" rẻ nhất | ⚪ | Greeting theo buổi (sáng/chiều/tối) — chuẩn mực category app cặp đôi. |

---

## PHẦN 2 — DESIGN SPEC CẢI THIỆN (Home v2)

### 2.1 Mục tiêu

1. CounterCard lên **above the fold** mọi máy (kể cả SE) — gộp 2 header thành 1.
2. Sắp lại block theo **habit loop**: anchor cảm xúc → hành động hằng ngày → hành động tạo nội dung → nostalgia → tĩnh.
3. Thống nhất **nhịp section** (chunking 3 nhóm) + **tap feedback** + **chữ-trên-glass**.
4. KHÔNG thêm feature mới, KHÔNG đổi backend — thuần sắp xếp + consistency + a11y.

### 2.2 Phạm vi

- `lib/screens/home_screen.dart` (tab Home + skeleton + bell), `lib/l10n/app_en.arb` + `app_vi.arb`.
- KHÔNG đụng: CounterCard nội bộ, GalleryScreen/ProfileScreen, providers, backend, bottom nav (giữ nguyên).

### 2.3 User flow (thay đổi duy nhất)

- Tap thumbnail recent photo → mở fullscreen preview **đúng ảnh đó** (`GalleryScreen.openPreview`, hero tag riêng `recent-photo-{id}`), swipe được giữa 5 ảnh recent. Nút "Xem tất cả" vẫn nhảy tab Gallery.

### 2.4 Wireframe (thứ tự block mới)

```
┌────────────────────────────────────────┐
│ ✦ KỶ NIỆM CỦA CHÚNG MÌNH        [🔔•3] │  ← badge eyebrow (giữ) + bell (giữ)
│ Chào buổi tối,                         │  ← greeting theo buổi (thay "Trang chủ")
│ Tuấn ♥ Embé                            │  ← AnimatedCoupleName (từ hero cũ)
│                                        │  (XOÁ hero glass card riêng)
│ ╭────────── CounterCard ─────────────╮ │
│ │   ♥  ĐÃ BÊN NHAU ĐƯỢC              │ │  ← giữ nguyên 100%
│ │     2    ·    3    ·    14         │ │
│ │   năm      tháng      ngày         │ │
│ │  (pill kỷ niệm + streak chip)      │ │
│ ╰────────────────────────────────────╯ │
│ [banner chờ partner — chỉ khi waiting] │
│                                        │
│ Hôm nay của hai đứa                    │  ← section title MỚI (nhóm 1)
│ ╭─ ❓ Câu hỏi hôm nay ───────────────╮ │  ← ĐẨY LÊN (trigger hằng ngày)
│ ╭─ 💌 Lời nhắn của người ấy ─────────╮ │
│                                        │
│ Kỷ niệm                     Xem tất cả │  ← section title (nhóm 2, gộp 2 section cũ)
│ ╭─ 📷 Thêm kỷ niệm  (CTA rose) ──────╮ │
│ [ảnh][ảnh][ảnh][ảnh]  → scroll ngang   │
│ ╭─ 🗓 Ngày này năm xưa (nếu có) ─────╮ │
│                                        │
│ Cột mốc tiếp theo                      │  ← section title (nhóm 3)
│ ╭─ 🏆 1 năm · còn 23 ngày ▓▓▓░░ 87% ─╮ │  ← XUỐNG CUỐI (tĩnh)
└────────────────────────────────────────┘
            (floating nav — giữ nguyên)
```

### 2.5 Spec chi tiết

**Header hợp nhất (thay header cũ + hero glass):**
- Row 1: badge eyebrow giữ nguyên (pill trắng .12, viền .18, icon sparkles 14, `pageEyebrowStyle`) — trái; bell giữ nguyên — phải, **bọc `Semantics(label: l10n.notificationBellLabel(unread), button: true)` + đổi GestureDetector → `InkWell` bo 18**.
- Row 2 (cách row 1: 14): greeting theo buổi — `pageTitleStyle()` nhưng **size 26** (giảm từ 32 vì giờ có 2 dòng): `homeGreetingMorning/Afternoon/Evening`.
- Row 3 (cách row 2: 6): `AnimatedCoupleName` (heart pulse giữ), textStyle trắng w700 **size 20** — chuyển từ hero cũ sang, heartSize 18.
- XOÁ: title "Trang chủ", subtitle `homeSubtitle`, toàn bộ `_buildHeroSection`.
- Tiết kiệm ước tính ~150px → CounterCard lọt fold iPhone SE.

**Thứ tự block + section (chunking):**
| Nhóm | Block | Spacing |
|------|-------|---------|
| — | Header → CounterCard | 20 |
| — | (banner chờ partner nếu waiting) | 16 trên |
| **1. Hôm nay của hai đứa** (`homeTodaySectionTitle`) | Daily question card → Love note card | section title cách trên **28**, cách card 12; giữa 2 card **12** |
| **2. Kỷ niệm** (tái dùng `recentMemoriesTitle`, action `seeAll` → tab Gallery) | CTA Thêm kỷ niệm → recent photos ngang → on-this-day (nếu có) | trên 28, trong nhóm 12 |
| **3. Cột mốc** (tái dùng `milestoneProgressTitle`) | Milestone progress card | trên 28, trong 12 |

- Quy tắc spacing mới ghi vào design system: **trong nhóm 12 · giữa nhóm 28** (thay 20 đều).
- Section title: dùng `sectionTitleStyle` hiện có; subtitle dưới title **BỎ** ở nhóm 1 và 3 (card tự giải thích) — chỉ nhóm 2 giữ subtitle khi rỗng ảnh (`addPhotosPrompt`).
- `_entrance` order đánh lại theo thứ tự mới: header 0 · counter 1 · banner 2 · section1 3 · dailyQ 3 · loveNote 4 · section2 5 · CTA 5 · recent 6 · onThisDay 6 · section3 7 · milestone 7. Anchor `_dailyQuestionKey` đi theo card (deep-link giữ nguyên).

**Consistency pass:**
- On-this-day card: đổi TOÀN BỘ chữ trắng → chữ tối (title `textPrimary` 15 w700, body `textSecondary` 12.5, icon `accentRose`, chevron `textTertiary`) — khớp love note/daily question cùng loại GlassCard.
- GestureDetector → `Material`+`InkWell` (ripple `accentRose` alpha .08, borderRadius theo card): CTA Thêm kỷ niệm (20), recent card (22), on-this-day (24), bell (18). CounterCard giữ GestureDetector (onTap hiện null — ngoài scope).
- RefreshIndicator: thêm `backgroundColor: AppColors.white`.
- Nav label 10 → **11px**; badge bell giữ 10 (chật chỗ, chấp nhận) nhưng thêm Semantics như trên.

**Skeleton mới (khớp layout v2):** header line 160×22 → 24 → counter 220 r28 → 24 → **2 card dọc** 140 r24 + 12 + 96 r24 (thay row 2 ô ngang cũ) → 24 → block 120 r24.

**Recent photo → mở đúng ảnh:**
- `GalleryScreen.openPreview(context, photos: recentPhotos, heroTags: recentPhotos.map((p)=>'recent-photo-${p.id}'), initialIndex: index, couple: couple)`; bọc thumbnail trong `Hero(tag: 'recent-photo-${photo.id}')` (pattern y hệt on-this-day, `MaterialRectCenterArcTween`).

### 2.6 States

- **Loading couple:** skeleton mới (trên). **Uploading ảnh:** CTA disable + opacity .6 (giữ hành vi hiện tại).
- **Waiting partner:** banner giữ nguyên vị trí sau CounterCard; daily question/love note card đã tự xử lý trạng thái waiting (giữ); journal/history entry tự ẩn (giữ).
- **Rỗng ảnh:** empty card + nút "Đăng ảnh đầu tiên" giữ nguyên, nằm trong nhóm Kỷ niệm dưới CTA. **On-this-day không có:** ẩn block (giữ).
- **Error đăng ảnh:** snackbar lỗi (giữ).

### 2.7 Interaction / motion

- Giữ nguyên: entrance fadeIn+slideY 8px stagger 50ms easeOutCubic (đánh lại order), heart pulse 820ms, nav pill 320ms, confetti/Lottie daily question one-shot, haptics hiện có.
- MỚI: ripple InkWell các tile (mặc định Material, splash `accentRose` .08). Hero transition recent→preview dùng pipeline sẵn có. KHÔNG thêm animation mới.

### 2.8 Localization (vi + en) — key MỚI

| Key | vi | en |
|-----|----|----|
| `homeGreetingMorning` | Chào buổi sáng, | Good morning, |
| `homeGreetingAfternoon` | Chào buổi chiều, | Good afternoon, |
| `homeGreetingEvening` | Chào buổi tối, | Good evening, |
| `homeTodaySectionTitle` | Hôm nay của hai đứa | Today, together |
| `notificationBellLabel` (placeholder `{count}`, plural) | Thông báo, {count} chưa đọc | Notifications, {count} unread |

- Buổi: sáng 5:00–11:59 · chiều 12:00–17:59 · tối 18:00–4:59 (local time).
- Key BỎ dùng tại Home (không xoá khỏi ARB nếu nơi khác dùng): `helloGreeting`, `homeSubtitle`, `navHome` (vẫn dùng cho nav label), `quickMomentsTitle`, `latestMomentsSubtitle` (gộp section). ⚠️ Sửa CẢ 2 ARB rồi `gen-l10n` qua toolchain đúng của máy; tránh ICU `{...}` ngoài placeholder.

### 2.9 Assets

Không cần asset mới. (Bell Lottie `assets/lottie/notification_bell.json` vẫn optional như hiện tại.)

### 2.10 Dev notes / handoff

1. Thuần `home_screen.dart` + 2 ARB — không model/provider/backend mới; `flutter analyze` sạch.
2. `_entrance` GIỮ quy tắc params hằng (comment dòng 96–106 — đã có 2 lần crash vì branch theo cờ "played"); chỉ đổi `order`.
3. Recent preview: couple lấy từ `Consumer2` sẵn có ở build — truyền xuống `_buildRecentPhotosSection` (thêm param `couple`).
4. Đừng quên skeleton (`_buildHomeLoadingSkeleton`) — đổi cùng commit kẻo drift tiếp.
5. Khi xoá `_buildHeroSection`: kiểm tra `helloGreeting`/`homeSubtitle` còn nơi nào dùng trước khi xoá key.
6. Cập nhật `project/design-system.md` (mục layout home + quy tắc mới: chữ-trên-glass, spacing 12/28, nút-trong-card r16) + CLAUDE.md mục 2 (bỏ "quote card", layout mới) cùng PR.
7. S3 (`displaySerif` rename) + thu gọn daily question sau reveal = NỢ P3, KHÔNG làm lượt này.

### 2.11 Acceptance criteria

- [ ] iPhone SE (568–667pt): CounterCard hiện TRỌN trong first viewport, không cuộn.
- [ ] Header chỉ còn 1 khối: badge + bell + greeting theo buổi + tên couple (heart pulse giữ); KHÔNG còn title "Trang chủ" + hero glass riêng.
- [ ] Thứ tự: counter → (banner) → Hôm nay (daily Q, love note) → Kỷ niệm (CTA, recent, on-this-day) → Cột mốc; 3 section title; spacing trong nhóm 12 / giữa nhóm 28.
- [ ] Tap recent thumbnail → fullscreen preview đúng ảnh (hero mượt, swipe giữa recent); "Xem tất cả" → tab Gallery.
- [ ] On-this-day: chữ tối, đạt contrast trên glass (không còn trắng).
- [ ] Mọi tile bấm được ở Home tab có ripple (bell/CTA/recent/on-this-day/journal/history rows).
- [ ] Bell có Semantics đọc số chưa đọc; nav label 11px.
- [ ] Skeleton khớp layout mới (không nhảy hình khi load xong).
- [ ] Deep-link `daily_question` vẫn scroll đúng card; entrance không replay khi mở bàn phím love-note; confetti/Lottie reveal không regression.
- [ ] vi + en đủ (5 key mới, cả 2 ARB + gen-l10n); greeting đổi đúng theo giờ máy.
- [ ] `flutter analyze` sạch; KHÔNG đổi backend/nav/Gallery/Profile.

---

## Changelog

- [2026-06-10] [Designer] **Review "Kỷ niệm gần đây" (user hỏi xoá-hay-thay):** khuyến cáo KHÔNG xoá trắng — section gánh trigger đăng ảnh = metric Bắc Đẩu; vấn đề là dải polaroid trình bày kiểu "danh sách thumbnail" không tạo cảm xúc. Đề xuất 3 hướng: (1) **Memory cinema** — 1 card lớn auto-trình-chiếu Ken Burns + crossfade kiểu Apple Photos Memories, CTA tách thành pill riêng (recommend); (2) bento mosaic — sang nhưng bội thực ảnh khi Home đã có CounterCard nền ảnh; (3) xoá section dồn vào CounterCard swipe — mất on-this-day + ảnh bị scrim đè, không khuyên. **User chốt Hướng 1** → Dev implement cùng ngày (`memory_cinema_card.dart`).
- [2026-06-10] [Designer] **Review eyebrow chip header (theo screenshot user):** chẩn đoán chip "TRANG CHỦ" là chữ chết (trùng bottom nav, tông hành chính lệch brand) nhưng KHUNG chip nên giữ (nhịp nhất quán với Gallery "THƯ VIỆN RIÊNG TƯ" / Profile; bỏ hẳn thì bell lẻ loi lệch header). Đề xuất 2 hướng: (1) eyebrow = ngày hôm nay theo locale — pattern Apple News/Fitness, cộng hưởng habit loop daily question/streak, mạch kể "hôm nay ↔ số ngày bên nhau"; (2) câu định danh cảm xúc tĩnh. **User chốt Hướng 1** → Dev implement cùng ngày.
- [2026-06-10] [Designer] Review design system + Trang chủ (persona PD 10 năm). Phát hiện 5 vấn đề hệ thống (S1 chữ-trên-glass 2 chế độ/contrast fail on-this-day, S2 GestureDetector vs InkWell, S3-S5 nhẹ) + 8 vấn đề IA/UX Home (H1 header trùng đốt fold, H2 thứ tự ngược habit loop, H3 nhịp section loạn, H4 recent tap không mở ảnh, H5 skeleton drift, H6 a11y, H7-H8 nhẹ). Xuất spec Home v2: gộp header + greeting theo buổi, reorder theo habit loop (daily Q lên nhóm "Hôm nay"), chunking 12/28, consistency pass (chữ tối trên glass, InkWell, skeleton), recent→openPreview, 5 key l10n mới. Scope thuần UI, không backend. → chờ Dev.

---

## Đợt 2 — ghép 5 lối vào (poke · caro-game · weather · arrival · expenses)

> ⚠️ **[2026-10-20] Bản chọn là bản C (mục 14).** User bỏ hẳn poke ("xoá cái chạm, không phù hợp") và chốt mỗi thứ một thẻ riêng ("để riêng, tôi không muốn gộp chung"). Mục 1–13 dưới đây (bản A gộp có tim, bản B) giữ làm lịch sử; chỗ nào lệch mục 14 thì mục 14 thắng.

> Designer, 2026-10-20. Nhánh `feature/daily-open-2`. Mock bấm thử: `docs/design/home-daily-open-2/` — `home.html` (cặp đã ghép, 20/10 19:05), `home-waiting.html` (cặp đang chờ), `home-states.html` (00:05 ngày mới + mất mạng). Dữ liệu `data.js` (22 `console.assert`, 0 lỗi). Style: sheet chung đợt 2 `docs/design/daily-open-2/sheet.raw.md` (editorial-greeting, seed 1822703143, `--keep palette,type`), không draw lại. Màu, phông, bo góc, bóng lấy từ app như user chốt; thẻ đếm giữ đồng hồ chạy giây.

### 1. Câu hỏi của Home, phát hiện, việc chính

- **Câu hỏi một dòng:** "Hôm nay người ấy thế nào, và có gì đang chờ mình làm?"
- **Phát hiện (mock 19:05):** Thảo về đến nhà lúc 18:42, pin còn 12%, và đã trả lời câu hỏi từ 12:31 mà Tuấn chưa trả lời.
- **Việc hay làm nhất:** trả lời câu hỏi hôm nay (một chạm vào nút navy trong thẻ câu hỏi). Việc thứ hai: liếc xem người ấy ra sao rồi bấm "Hỏi thăm" hoặc "Về nhà rồi".
- **Face (chọn từ sheet):** "cặp đôi là ba làn". Bảng mới chia ba làn dọc: **Bạn (trái) · nhãn chung (giữa) · người ấy (phải)**, đúng luật Lead và đúng thẻ Đêm qua đang chạy. Hai nút ở chân bảng cũng đứng dưới đúng làn của chúng: "Về nhà rồi" dưới làn Bạn, "Hỏi thăm" dưới làn Thảo.

### 2. Thứ tự khối cuối cùng (cặp đã ghép)

Đã kiểm thứ tự hiện tại bằng code (`_buildHomeScrollBody`): header ghim → CounterCard (tên, số ngày, đồng hồ, cột mốc, chuỗi) → banner chờ (nếu chờ) → "Hôm nay của chúng mình" + pill chòm sao → TodayRitualCard → MoodCard → DecisionCard → SleepCard → RpsInviteCard → "Kỷ niệm gần đây" + MemoryCinema. (Danh sách trong brief có "ngày này năm xưa" riêng: code đã gộp vào slide đầu MemoryCinema.)

| # | Khối | Thay đổi | Cao (px, 390) | Lý do vị trí |
|---|---|---|---|---|
| 0 | Header ghim (chip lời chào + 💌 + chuông) | giữ | 64, không cuộn | |
| 1 | CounterCard + **`PokeCoupleRow`** | `AnimatedCoupleName` → hàng tên + tim + câu đếm | 362 → **404** | Tim nằm ở chỗ được nhìn nhiều nhất; câu "Hôm nay nhớ nhau 12 lần" là tín hiệu "người ấy hôm nay" đầu tiên, ngay màn đầu. |
| 2 | "Hôm nay của chúng mình" + `ConstellationPill` | giữ | 26 (+28 trên, 12 dưới) | |
| 3 | TodayRitualCard (câu hỏi) | giữ nguyên | 140–287 | Việc hằng ngày số 1, giữ chuỗi. Vẫn lộ câu hỏi ở màn đầu sau khi thẻ đếm cao thêm. |
| 4 | **`TodayBoard` "Thảo hôm nay thế nào?"** (MỚI) | gộp **MoodCard + SleepCard** đang có với lối vào **weather + arrival** | **455** | Trả lời thẳng câu hỏi của Home trong một lần liếc. Đứng ngay sau câu hỏi. |
| 5 | **`PlayTogetherCard`** (caro + oẳn tù tì) | thay `RpsInviteCard` | 76 → **209** | Khi tới lượt mình là việc người ấy đang chờ: xếp trên các việc làm một mình. |
| 6 | **`MoneyHomeEntry`** "Sổ chung tháng 10" | mới | **76** | Ghi khoản là thói quen hằng ngày nhưng làm một mình, thẻ chỉ 76 nên rẻ. |
| 7 | DecisionCard "Phân vân gì không?" | giữ, dời xuống dưới Sổ tiền | 278 | Dùng theo bữa ăn, không phải mỗi lần mở app. |
| 8 | "Kỷ niệm gần đây" + MemoryCinema | giữ | 26 + 240 | Xem lại, không có việc phải làm. |

Khoảng cách: trong nhóm "Hôm nay" giữa các thẻ **16** (giữ như code); giữa nhóm 28. Thứ tự cố định mọi lúc trong ngày để tay quen chỗ; nội dung trong từng khối mới đổi theo giờ.

**Cặp đang chờ người ấy** (cùng thứ tự, ẩn thứ cần hai người): CounterCard không tim, không chuỗi → banner chờ (giữ) → "Hôm nay của chúng mình" (không pill) → thẻ câu hỏi (trạng thái chờ) → **bảng một làn "Hôm nay của bạn"** (Thời tiết · Đêm qua) → **"Sổ tiền của mình · Hôm nay đã ghi 3 khoản"** → "Phân vân gì không?" → Kỷ niệm. Ẩn: tim poke (poke D-chờ), Chơi cùng nhau (caro D14), hàng Đến nơi (arrival D9), hàng Tâm trạng (như MoodCard hiện nay).

### 3. Tổng chiều dài trước/sau

Tính cùng một cách cho cả hai: số px từ đỉnh vùng cuộn tới hết MemoryCinema ở 390×844, trạng thái 19:05 (Thảo đã trả lời, Tuấn chưa). Thẻ có sẵn lấy số đo trên máy thật (`docs/screenshots/home-*.jpg`: CounterCard 362, MoodCard 265) hoặc cộng từ hằng số trong code (SleepCard ≈209, RpsInviteCard 76); thẻ mới lấy số đo DOM của mock (`home.html?measure=1`).

| | Cặp đã ghép | Cặp đang chờ |
|---|---|---|
| Home hiện tại | **1.933 px** (≈2,8 màn cuộn) | 1.873 px |
| Nếu mỗi feature một thẻ riêng (cách cộng thẳng spec 5 feature) | 2.778 px (+845, +44%) | ≈2.120 px |
| **Bản ghép này** | **2.165 px** (+232, +12%, ≈3,1 màn) | **2.045 px** (+172) |

Bảng hai làn tiết kiệm ≈613 px so với cộng thẳng: MoodCard 265 + SleepCard 209 + thẻ thời tiết 246 + thẻ "Về đến nhà chưa?" 300 + 3 khe 16 = 1.068 px, còn 455 px.

Màn đầu (vùng thấy được 111 → 710): thẻ đếm hết ở 424, câu hỏi bắt đầu ở 490 và lộ ≈109 px (đủ 2 dòng câu hỏi). Trước đây lộ ≈151 px. Bảng "Thảo hôm nay thế nào?" nằm đầu màn thứ hai.

### 4. Quyết định 42 px của poke: **nhận**

- Lý do: bảng hai làn đã trả lại ≈613 px, nên 42 px cho tim là rẻ. Tim + câu "Hôm nay nhớ nhau 12 lần: mình 7, Thảo 5" là thứ duy nhất trả lời "người ấy hôm nay" ngay trên màn đầu, khi bảng còn ở màn hai. Câu hỏi hằng ngày vẫn lộ 2 dòng ở màn đầu trên 390×844.
- Giữ câu dưới tên **luôn hiện**, cả lúc 0 lần ("Chạm tim để Thảo biết mình đang nhớ"): đó là chỗ duy nhất dạy người dùng rằng tim bấm được. Không tiết kiệm 26 px buổi sáng như phương án Q1 của poke.
- ⚠️ **Sửa spec poke:** `AnimatedCoupleName` hiện nay **luôn đặt tên người xem bên trái** (đổi chỗ khi người xem không phải người tạo couple, `animated_couple_name.dart:128–141`). Spec poke §6.1 ghi "người tạo couple bên trái để cả hai máy thấy giống nhau": trái với code và trái luật Lead. `PokeCoupleRow` giữ **người xem bên trái** ⇒ câu luôn là "… mình {m}, {name} {p}", bỏ biến thể "viewer bên phải".

### 5. Bảng "Thảo hôm nay thế nào?" — `TodayBoard` (widget mới)

**Vì sao gộp thay vì xếp 4 thẻ:** mood, sleep, weather, arrival đều là "hai người, mỗi người một số" (đã cùng khuôn hai làn + `PersonLabel` + vạch α.10 của SleepCard). Xếp 4 thẻ thì cùng một câu hỏi bị cắt làm 4 chỗ, Home dài thêm ≈1.000 px. Ý gộp mượn từ brand-v2 (đã huỷ) nhưng vẽ bằng `ContentCard` + `IconBadge` + `PersonLabel` hiện có.

```
┌ ContentCard r24 pad 16 ─────────────────────────────────────┐
│ [IconBadge profile_2user 44] Thảo hôm nay thế nào?  16 w800  │
│                              (Mất mạng · số lúc 18:58)  12   │ ← chỉ khi offline / số cũ
│ ● BẠN                                           THẢO ●       │ PersonLabel 11 w700 ls1.0, căn hai mép
│ ─────────────────────────────────────────────────────────── │ vạch textSecondary α.10
│ 😄 Vui            (☺) Tâm trạng            Nhớ 🥹           │ MoodGlyph 24 + 15 w700
│                                         “mai gặp nha”        │ 12 w500 textSecondary, 1 dòng
│ ─────────────────────────────────────────────────────────── │
│ Đã đến chỗ làm    (⌂) Đến nơi         Đã về đến nhà         │ 15 w700
│ 08:05                                          18:42         │ 12, số tabular
│ Tự báo đang bật                         [▭ Pin còn 12%]      │ pill warning α.18 / warningInk
│ ─────────────────────────────────────────────────────────── │
│ 23° ☁            (☁) Thời tiết                  ☁ 27°       │ 18 w800 + icon 18
│ Hà Nội                                        TP.HCM         │
│ Nhiều mây                                  Nhiều mây         │ tình trạng đáng nhắc in đậm navy
│ ─────────────────────────────────────────────────────────── │
│ 6g 50p            (☾) Đêm qua                   7g 20p      │ DurationText numberSize 18
│ 00:15–07:05                               23:40–07:00        │
│ [⌂ Về nhà rồi]                         [💬 Hỏi thăm]         │ 2 cột bằng nhau, khe 8, h44 viền
└──────────────────────────────────────────────────────────────┘
```

**Hình học:** lưới `[1fr | 64 | 1fr]`, khe 8. 390: lòng thẻ 326 = 2×123 + 64 + 2×8. 360: 296 = 2×108 + 64 + 16. Làn Bạn căn trái, làn người ấy căn phải (soi gương quanh cột nhãn). Hàng `minHeight 60`, đệm dọc 10, chữ được xuống dòng (không cắt) trừ dòng ghi chú tâm trạng và tên thành phố (1 dòng, `ellipsis`). Cột giữa: icon 18 `textSecondary` + nhãn 12 w600 `textSecondary`, căn giữa. Không có vạch dọc (cột nhãn đã tách hai làn).

**Thứ tự hàng (cố định):** Tâm trạng · Đến nơi · Thời tiết · Đêm qua. Hiện tại trước (cảm xúc, chỗ ở), rồi bối cảnh (thời tiết), cuối là chuyện đã qua (đêm qua). Hai hàng ẩn được (Thời tiết, Đêm qua) nằm dưới nên ẩn đi không làm hàng khác nhảy chỗ.

**Chạm:** cả hàng là `InkWell` r16 (ripple rose .08): Tâm trạng → sheet chọn tâm trạng có sẵn · Đến nơi → `ArrivalManageScreen` (hoặc luồng bật nếu chưa bật) · Thời tiết → `showWeatherDetailSheet` · Đêm qua → `openSleepScreen`. Nút trong ô ("Chọn", link "Bật…") tự xử lý, không kích hàng.

**Chân bảng (tối đa 2 nút, cùng khuôn `OutlinedButton` pill h44 viền navy α.18, 15 w600, icon 18):**
- Trái, dưới làn Bạn: **"Về nhà rồi"** (arrival D7, luôn có khi couple active). Bấm: ghi sự kiện bấm tay, ô "Đến nơi" của Bạn đổi ngay, nút thành nền navy α.06 + `tick_circle` + live region "Đã báo Thảo: Về nhà rồi · 19:05" 4 giây (arrival S1). Mất mạng: icon `cloud_cross` + dải `surfaceLight` "Sẽ báo khi có mạng. Quá 30 phút thì Thảo chỉ thấy trên thẻ, không nhận thông báo." (S2). Lỗi: dải + "Thử lại" (S3).
- Phải, dưới làn người ấy, **một** việc theo thứ tự ưu tiên: (1) người ấy vừa ĐẾN nơi trong ≤120 phút cùng ngày → **"Hỏi thăm"** (`openCareMessageScreen(prefill: arrivalCareSuggestion)`); (2) chỗ người ấy mưa / nắng gắt / lạnh và trước 21:00 → **"Nhắc mang ô" / "Nhắc uống nước" / "Nhắc mặc ấm"** (màn Quan tâm điền sẵn của weather); (3) không có → ô phải để trống, "Về nhà rồi" giữ nửa trái.
- Cả hai nút **viền**, không đặc: luật caro C6 "đặc navy = người ấy đang chờ bạn" — ở đây không ai chờ. Home đã có 2 nút đặc navy đúng luật (thẻ câu hỏi, "Đi tiếp" caro).

**Trạng thái từng hàng** (ghép từ spec feature; ô = một làn, "trải" = nội dung chiếm cả hai làn):

| Hàng | Trạng thái | Làn Bạn | Làn người ấy |
|---|---|---|---|
| Tâm trạng | đã chọn | glyph 24 + chữ (+ ghi chú) | như bên trái, soi gương |
| | chưa chọn | pill "Chọn" (h36 nền rose α.10 như pill "Quay" của DecisionCard; vùng chạm 44) | "Chưa chọn" 14 w600 xám |
| | trùng tâm trạng | nhãn giữa đổi thành tim đặc `accentLove` + "Giống nhau" (thay khoảnh khắc `_MoodMatched` của MoodCard) | |
| Đến nơi | có tin hôm nay | câu arrival (`arrivalEnter*`/`arrivalExit*`) · giờ · dòng 2 "Tự báo đang bật" / "Báo bằng tay" (D11: người chia sẻ luôn thấy mình đang chia sẻ) | câu · giờ (· pin x% khi > 20) · dòng 2 pill "Pin còn x%" khi ≤ 20 |
| | tin 1–3 ngày trước | giờ thành "hôm qua 19:20" / "18/10 22:58" | như trái |
| | người ấy bật, không tin ≥3 ngày (B4) | | "Đang bật" + "chưa có tin" |
| | chưa bật | "Chưa bật" + link "Bật báo về nhà" | "Chưa bật" (không giục, D11) |
| | cả hai chưa bật (A) | trải: "Về đến nhà là máy tự báo cho Thảo." + nút chữ "Bật" | |
| | thiếu quyền Luôn luôn (M3) / chưa lưu Nhà (M5) / tắt từ xa (M4) | "Chưa tự báo được" + link "Mở Cài đặt" / "Chưa lưu Nhà" + link "Lưu Nhà" / dòng 2 "Tạm chỉ báo bằng tay" | |
| | vừa bấm, mất mạng | "Đã về đến nhà" · giờ bấm · dòng 2 `cloud_cross` "chờ mạng" | |
| Thời tiết | bình thường | nhiệt độ 18 w800 + icon · thành phố · tình trạng (đậm navy khi mưa/nắng gắt/lạnh) | soi gương |
| | người ấy chưa có thành phố | | link "Chọn giúp" |
| | mình chưa có thành phố | link "Chọn chỗ" | |
| | chưa ai chọn (E) | trải: "Chọn chỗ hai bên, sáng nào mở app cũng thấy." + "Chọn" + "Ẩn" | |
| | cùng thành phố | trải: "Cả hai cùng ở Hà Nội · 23° · Nhiều mây" | |
| | số cũ 6–24 giờ | số xám + dòng "số lúc 21:40" | như trái |
| | lỗi / > 24 giờ | trải: "Chưa tải được thời tiết" + "Thử lại" | |
| Đêm qua | có dữ liệu | `DurationText(18)` · giờ ngủ–dậy | soi gương; "Giờ bên ấy" pill nếu khác múi giờ |
| | chưa bật theo dõi (A1) | trải: "Bật để sáng nào cũng biết đêm qua Thảo ngủ ra sao." + "Bật" + "Ẩn" (ẩn 30 ngày như nay) | |
| | không có đêm / mất quyền | "Chưa ghi nhận" + link "Ghi tay" / "Cần cấp lại quyền" | "Chưa chia sẻ" + icon khoá |
| Cả bảng | đang tải | mọi ô là thanh phẳng đúng cỡ dòng (`ShimmerSkeleton`, Reduce Motion đứng yên), nhãn giữa + tên làn hiện ngay | |
| | mất mạng / số cũ | dưới tiêu đề: `cloud_cross` "Mất mạng · số lúc 18:58" 12 w600; mọi ô giữ số đã lưu | |

**Lệch spec feature có chủ ý (PO/Lead duyệt):**
1. arrival: bỏ thẻ 300 dp; chỉ "Về nhà rồi" ở chân bảng, "Đến chỗ làm rồi"/"Đến trường rồi" vào màn Quản lý (đúng phương án gọn arrival Q3 đề xuất). "Hỏi thăm" rời khỏi làn người ấy xuống chân bảng.
2. weather: câu chênh lệch ≥5° (D11) chỉ còn ở sheet chi tiết; nút gợi ý chuyển xuống chân bảng và thành nút viền.
3. sleep: dòng chung "Ngủ cùng lúc 6g 45p" rời Home, chỉ còn ở `SleepScreen`.
4. mood: thẻ 265 px với mặt to 56 + nút "Đổi tâm trạng" thành một hàng; khoảnh khắc trùng tâm trạng thu thành tim ở cột giữa.

### 6. Hai lối vào còn lại

- **`PlayTogetherCard`**: dựng đúng spec caro §3.1 (tiêu đề 16 w700, hai dòng 68, huy hiệu 44 r16, CTA h40 đặc navy chỉ khi tới lượt mình). Không thêm `IconBadge` ở tiêu đề: mỗi dòng đã có huy hiệu 44, thêm cái thứ ba thành ba ô màu chồng nhau trong 200 px. Vẫn đúng luật Lead "lối vào dùng `IconBadge`" ở cấp dòng.
- **`MoneyHomeEntry`**: spec expenses §3.1, đổi icon trần thành `IconBadge(IconsaxPlusLinear.wallet_2)` 44 tint rose (Lead chốt). Mất mạng: "3.574.000 ₫ · số lúc 18:58", **cùng một biến giờ** với dòng "số lúc" của bảng.

### 7. Chỗ Dev sửa

| File | Việc |
|---|---|
| `lib/screens/home_screen.dart` `_buildHomeScrollBody` | (1) `headerExtra`: `AnimatedCoupleName` → `PokeCoupleRow` khi `!couple.isWaitingForPartner`. (2) Bỏ `MoodCard(key: _moodCardKey…)` và khối `Selector<SleepProvider…> SleepCard`; chèn `TodayBoard(key: _todayBoardKey, couple)` ngay sau `_buildTodayRitualCard`, cách 16, `_entrance(4, …)`; hiện cả khi đang chờ (bản một làn), tự ẩn khi mọi hàng bị ẩn. (3) `RpsInviteCard` → `PlayTogetherCard`, đặt ngay sau bảng (`_entrance(5)`), chỉ khi active. (4) Chèn `MoneyHomeEntry` sau đó (`_entrance(6)`), hiện cả khi chờ. (5) Dời `KeyedSubtree(key: _decisionKey, DecisionCard)` xuống sau Sổ tiền (`_entrance(7)`). (6) Skeleton `_buildHomeLoadingSkeleton`: counter 404 → 2 thẻ 140/455 → 209 → 76. |
| `lib/widgets/today_board.dart` (mới) | `TodayBoard` + 4 hàng `_MoodRow` `_ArrivalRow` `_WeatherRow` `_SleepRow`, đọc `MoodProvider`, `ArrivalProvider`, `WeatherProvider`, `SleepProvider`; bọc `MidnightBuilder` để qua 0:00 tâm trạng về trống. |
| `lib/widgets/person_label.dart` (mới, tách từ `sleep_card.dart`) | arrival design đã đề xuất; board dùng chung. |
| `lib/widgets/mood_card.dart` | dùng `showMoodPicker(context)` có sẵn (đã public) cho pill "Chọn" và chạm hàng. `MoodCard` để lại trong code, Home bản A không dùng. |
| `lib/widgets/sleep/sleep_card.dart` | Home không dùng; `SleepCard` còn dùng được nơi khác. Dời `PersonLabel` ra file chung. |
| Điều hướng tới khối | `_moodCardKey` → `_todayBoardKey`; `pendingHomeFocus` `'weather'` / `'arrival'` / thông báo tâm trạng → cuộn tới bảng (280 ms easeOutCubic, Reduce Motion nhảy thẳng) rồi nhấp sáng hàng tương ứng 600 ms (nền rose α.06). `'caro'` → `PlayTogetherCard`. |
| Semantics | Mỗi hàng: `Semantics(button, label: "<nhãn>. Bạn: <ô trái>. <tên>: <ô phải>")`, như `aria-label` trong mock. Tim poke giữ spec poke §8. |

Không đổi: TodayRitualCard, DecisionCard (chỉ đổi vị trí), MemoryCinema, header, nav, `ConstellationPill`.

### 8. Copy mới (vi / en)

| Key | vi | en |
|---|---|---|
| `todayBoardTitle` | {name} hôm nay thế nào? | How's {name} today? |
| `todayBoardTitleSolo` | Hôm nay của bạn | Your day |
| `todayBoardRowMood` | Tâm trạng | Mood |
| `todayBoardRowMoodSame` | Giống nhau | Same mood |
| `todayBoardRowArrival` | Đến nơi | Arrivals |
| `todayBoardRowWeather` | Thời tiết | Weather |
| `todayBoardRowSleep` | (dùng `sleepCardTitle`) Đêm qua | Last night |
| `todayBoardMoodPick` | Chọn | Pick |
| `todayBoardMoodNone` | Chưa chọn | Not yet |
| `todayBoardArrivalAuto` | Tự báo đang bật | Auto alerts on |
| `todayBoardArrivalManual` | Báo bằng tay | Sent by hand |
| `todayBoardArrivalPending` | chờ mạng | waiting for signal |
| `todayBoardArrivalOff` | Chưa bật | Off |
| `todayBoardArrivalPitch` | Về đến nhà là máy tự báo cho {name}. | Your phone tells {name} when you get home. |
| `todayBoardWeatherPitch` | Chọn chỗ hai bên, sáng nào mở app cũng thấy. | Pick both cities to see them every morning. |
| `todayBoardWeatherSame` | Cả hai cùng ở {city} | You're both in {city} |
| `todayBoardSleepPitch` | Bật để sáng nào cũng biết đêm qua {name} ngủ ra sao. | Turn it on to see how {name} slept, every morning. |
| `todayBoardStale` | Mất mạng · số lúc {time} | Offline · as of {time} |

Dùng lại key sẵn có: `sleepYou`, `arrivalEnter*`/`arrivalExit*`, `arrivalManualHome`, `arrivalYesterdayAt`, `sleepNotRecorded`, `sleepPartnerNotShared`, `sleepHide`, nút gợi ý của weather, `moodHappy`…, chuỗi của poke/caro/expenses. Đã soát theo luật văn phong (câu ngắn, không sáo rỗng, xưng "bạn"/"chúng mình"); chưa chạy được skill humanizer/avoid-ai-writing trong phiên này, PO chạy trước khi chốt ARB.

### 9. Soát UX (UI UX Pro Max 2.13.0)

| Truy vấn | Kết quả | Áp dụng |
|---|---|---|
| `"touch target spacing adjacent buttons" --domain ux` | Touch Target 44pt/48dp; Touch Spacing ≥ 8px; Text Reflow (không cắt chữ trong hộp cố định) | Nút chân bảng h44 khe 8; pill "Chọn" h36 trong hàng ≥60 nên vùng chạm 44; ô cho chữ xuống dòng thay vì cắt (trừ ghi chú + thành phố). |
| `"color only information" --domain ux` | Color Only + Contrast 4,5:1 | Pin yếu = pill có chữ "Pin còn 12%", không chỉ màu; màu người chỉ ở chấm 8px; chữ phụ `textSecondary` 5,3:1 trên trắng. |
| `"content jumping layout shift loading" --domain ux` | Content Jumping (High): giữ chỗ cho trạng thái async | Skeleton bảng đúng cỡ từng ô; nút chân bảng giữ bề rộng khi đổi nhãn; ô phải trống thì không kéo nút trái ra full. |
| `"empty state first use" --domain ux` | Empty States: câu giúp + hành động | Hàng chưa bật = một câu trải hai làn + một nút chữ. |
| `"loading skeleton placeholder" --domain ux` | Realistic placeholder, giữ bố cục | Như trên. |
| `"comparison table two columns mobile" --domain ux` | Table Handling: dùng bố cục thẻ trên mobile | Bảng là lưới ba làn trong một thẻ, không phải bảng cuộn ngang. |
| `"text scale accessibility overflow" --stack flutter` | `MediaQuery.textScalerOf`, không cỡ cố định | Hàng `minHeight` không `height`; chữ tự xuống dòng ở 130–200%. |
| `"card list layout home screen"`, `"scroll performance long list cards"`, `"touch target button spacing"` `--stack flutter` | Column/Row; CustomScrollView+Slivers cho list dài; Semantics | Home vẫn là `SingleChildScrollView` (≈3 màn, không phải list dài); Semantics mỗi hàng. |
| `"dashboard home card density scroll length"`, `"progressive disclosure collapse cards"`, `"information hierarchy primary action above fold"`, `"offline state indicator cached data"` `--domain ux` | không khớp chủ đề (trả về smooth scroll, heading balance, breadcrumbs…) | Dựa vào app-screens §2.2, §11 của tasteskill: câu hỏi lớn nhất đọc trước, số cũ có giờ, lỗi nằm trong khối. |

Soát chung thành phần đứng cạnh nhau: (1) chân bảng "Về nhà rồi" + "Hỏi thăm": cùng khuôn viền, cùng cao 44, cùng cỡ chữ, icon cùng nét; (2) hai nút đặc navy trên Home (câu hỏi, "Đi tiếp" caro) đều là "người ấy đang chờ bạn"; mọi nút khác viền hoặc nền nhạt; (3) bốn thẻ có `IconBadge` 44 r16 ở tiêu đề (bảng, Sổ tiền, Phân vân) + huy hiệu dòng 40–44 (caro, rps, decision) cùng thang; (4) pill "Chọn" của tâm trạng cùng khuôn pill "Quay" của DecisionCard. Không có nút bên thứ ba.

### 10. Tasteskill: gate và 3 vòng nhìn lại

- `lint.mjs --app docs/design/home-daily-open-2`: **0 FAIL, 0 WARN** (emoji nằm sẵn trong chuỗi ARB và glyph tâm trạng có chú thích `taste-skill-ignore`).
- `inspect.mjs --app <trang> --widths 390 --out .taste-skill/home-daily-open-2/<trang>`: **0 FAIL** cả 3 trang, với `--allow micro-label,emoji,gradient,text-shadow,button-fx,heavy-shadow,icon-chips,tiny-text`. Lý do từng rule: chip lời chào, `PersonLabel`, eyebrow thẻ đếm in hoa (micro-label) · glyph tâm trạng + emoji trong ARB đang chạy (emoji) · `dawnBlush`, `sunsetRomance`, aurora, pill nav (gradient, button-fx) · chữ trắng trên thẻ hồng dùng bóng tối theo luật app (text-shadow) · bóng `ContentCard`/CounterCard chuẩn (heavy-shadow) · `IconBadge` Lead chốt cho mọi lối vào (icon-chips) · nhãn GIỜ/PHÚT/GIÂY 10 của đồng hồ giữ nguyên (tiny-text).
- WARN còn lại, có lý do: `colour-sprawl` 46–59% (thẻ đếm hồng là hero của app) · `kpi-size` 76px (số ngày, user giữ) · `heavy-borders` (inspector đọc viền nút `navy α.18` và khung khoá lavender α.18 như màu đặc; thực tế ≈1,3:1) · `contrast` 3,2:1 ở nút "Gửi cho người ấy 💌" của banner chờ (**nợ cũ của code**: `accentLove` + chữ trắng, không thuộc đợt này).
- Thêm: chụp tay khổ **360** (`home.html?w=360`, Chrome headless) để soi bảng ở máy Android nhỏ.

```
ROUND 1
Seen in one second: thẻ đếm hồng với tim giữa hai tên, dưới là câu hỏi.
Idea: cặp đôi là ba làn — bảng "Thảo hôm nay thế nào?" bạn trái, nhãn giữa, người ấy phải.
Live thing: tim poke + nút "Về nhà rồi" / "Hỏi thăm".
Scores: design 7 · usability 6,5 · creativity 7,5 · content 7 → overall 7,0.
Top three: 1. Bản mất mạng: bấm "Về nhà rồi" mà ô Đến nơi của Bạn vẫn "Đã đến chỗ làm 08:05" (sai sự thật) → ô đổi ngay, dòng 2 "chờ mạng".
2. Ô Đến nơi của Bạn xuống dòng xấu "hôm qua 19:20 · bấm / tay" → tách dòng 2 riêng cho trạng thái chia sẻ.
3. "Phân vân khác" có chữ phụ rớt dòng "gì…" (code thật `maxLines: 1`) → mock khớp code.

ROUND 2
Scores: design 7 · usability 7,5 · creativity 7,5 · content 7,5 → overall 7,3.
Top three: 1. Bản chờ người ấy hiện "Thảo quay · 11:42" và ảnh "Thảo · 3 ngày trước" khi Thảo chưa vào → đổi thành Tuấn (sai dữ liệu).
2. Khổ 360: dòng phụ thời tiết "Hà Nội · Nhiều mây" chạy dính vào nhãn giữa "Thời tiết" và ô bên kia, đọc thành một dòng → tách thành phố / tình trạng 2 dòng.
3. Khổ 360: "Đã đến chỗ làm" sát nhãn "Đến nơi" → khe 8 giữa làn và cột nhãn.

ROUND 3
Scores: design 7,5 · usability 7,5 · creativity 7,5 · content 8 → overall 7,6.
Caps: nếu áp nguyên luật trang (gradient, bóng trên thẻ đứng yên) thì trần 6,5; không áp vì đó là design system user đã khoá.
Còn yếu (chưa sửa, nói thẳng): bảng chỉ thấy ở màn thứ hai; khổ 360 hàng Đến nơi/Thời tiết cao 3 dòng, bảng 465 px; lúc không có việc phía người ấy, "Về nhà rồi" đứng nửa trái một mình; glyph tâm trạng trong mock là emoji Apple, app là Noto động.
```

### 11. Acceptance criteria

- [ ] Thứ tự đúng bảng §2 cho cặp active và cặp chờ; khoảng cách thẻ 16, giữa nhóm 28.
- [ ] Mọi thẻ hai người: Bạn trái (nhãn `sleepYou`), người ấy phải, kể cả `PokeCoupleRow` (người xem trái).
- [ ] 390×844: câu hỏi hôm nay lộ ít nhất 2 dòng ở màn đầu với thẻ đếm có tim.
- [ ] Bảng: 4 hàng đúng thứ tự, mỗi hàng chạm mở đúng màn; ẩn hàng Thời tiết/Đêm qua không làm hàng khác đổi chỗ; cặp chờ thấy bản một làn 2 hàng.
- [ ] Chân bảng: "Về nhà rồi" luôn có khi active; nút phải theo ưu tiên arrival ≤120' > thời tiết trước 21:00 > trống; cả hai nút viền.
- [ ] Mất mạng: số đã lưu vẫn hiện, dòng "Mất mạng · số lúc …" ở bảng và Sổ tiền cùng một giờ; bấm "Về nhà rồi" đổi ô Bạn ngay + dải S2.
- [ ] 0:00: tâm trạng về trống, số chạm về 0, chòm sao 0/6, "Đến nơi" hiện tin hôm qua có chữ "hôm qua".
- [ ] Khổ 360 và chữ to 130%: không cắt chữ ngoài ghi chú tâm trạng/thành phố; không tràn ngang.
- [ ] Semantics từng hàng đọc đủ "nhãn. Bạn: … Thảo: …"; deep-link weather/arrival/mood cuộn tới bảng.
- [ ] vi + en đủ key §8; `flutter analyze` sạch.

### 12. Câu hỏi cho PO / user

1. **Gộp MoodCard + SleepCard vào bảng** là đổi giao diện của hai feature đang chạy (mất mặt tâm trạng to và nút "Đổi tâm trạng", mất dòng "Ngủ cùng lúc"). Đồng ý không? Nếu không, phương án dự phòng: giữ hai thẻ cũ, chỉ gộp weather + arrival thành bảng 2 hàng; Home khi đó ≈2.650 px (+37%).
2. arrival D7 ghi "Đến chỗ làm rồi"/"Đến trường rồi" cũng nằm trên thẻ Home. Bảng chỉ để "Về nhà rồi", hai nút kia vào màn Quản lý (phương án gọn arrival Q3). PO duyệt?
3. Màu người trong mock thống nhất Tuấn hồng · Thảo ngọc (theo mock arrival + caro); mock weather để Thảo tím, mock expenses để Tuấn xanh dương. Màu thật đọc từ `sleep/{uid}.color`, nhưng người chưa chọn ở Giấc ngủ thì mặc định (`PersonPalette.resolve`) là hồng/tím: PO xác nhận mặc định đó áp chung cho cả 5 feature.

### Changelog đợt 2

- [2026-10-20] [Designer] Ghép lối vào 5 feature đợt 2 vào Home theo tasteskill (sheet chung editorial-greeting, không draw lại) + UI UX Pro Max. Chốt thứ tự: thẻ đếm có tim poke (nhận +42 px) → câu hỏi → bảng mới "Thảo hôm nay thế nào?" (gộp tâm trạng, đến nơi, thời tiết, đêm qua; bạn trái, người ấy phải; chân bảng "Về nhà rồi" + một việc cho người ấy) → Chơi cùng nhau → Sổ tiền → Phân vân gì không? → Kỷ niệm. Home 1.933 → 2.165 px (+12%) thay vì 2.778 px nếu mỗi feature một thẻ. Mock 3 trang + `data.js` 22 assert ở `docs/design/home-daily-open-2/`; lint 0/0, inspect 390 0 FAIL cả 3 trang; 3 vòng nhìn lại 7,0 → 7,3 → 7,6. Phát hiện spec poke đặt người tạo couple bên trái, trái với code `AnimatedCoupleName` và luật Lead. 3 câu hỏi PO/user.
- [2026-10-20] [Lead] Chốt câu hỏi Designer ghép Home: (2) trên Home chỉ để nút "Về nhà rồi", "Đến chỗ làm rồi"/"Đến trường rồi" vào màn Quản lý (biến thể gọn của arrival); (3) màu mỗi người = màu đã chọn ở Giấc ngủ, chưa chọn thì `PersonPalette.resolve` mặc định — áp chung cả 5 feature, màu trong mock chỉ là mẫu. Câu (1) gộp MoodCard + SleepCard vào bảng: hỏi user. Copy vi/en mới phải qua humanizer + avoid-ai-writing trước khi vào ARB. Link duyệt: https://claude.ai/artifact/9eFpE9nuR3tbEBWdWHGrbJ

### 13. So sánh A/B: gộp hay không gộp tâm trạng + đêm qua (user muốn xem tận mắt)

Mock: `docs/design/home-daily-open-2/home.html` (**A · Gộp**, giữ nguyên) · `home-b.html` (**B · Không gộp**) · `compare.html` (hai khung 390 cạnh nhau cùng 19:05, nhãn + chiều dài đo thật; điện thoại thì xếp dọc). Bản B dùng chung `data.js`/`ui.js`/`home.css`: thêm `UI.homeB`, `UI.moodCard`, `UI.sleepCard`, tham số `rows` cho `board()` (mặc định 4 hàng nên bản A không đổi).

**Bản B:** MoodCard và SleepCard dựng theo khuôn thật `mood_card.dart` (ô 36 r12, tiêu đề `sectionTitleStyle`, hai cột mặt 56, nút pill h48 "Đổi tâm trạng") và `sleep_card.dart` (`IconBadge` trăng tím, `PersonLabel`, trăng 30 + `DurationText` 22, dòng "Ngủ cùng lúc 6g 45p · Thảo ngủ trước 35p"). Bảng còn 2 hàng Đến nơi + Thời tiết, chân bảng y bản A.

**Vị trí trong B:** câu hỏi → **Tâm trạng** → bảng (Đến nơi + Thời tiết) → **Đêm qua** → Chơi cùng nhau → Sổ tiền → Phân vân → Kỷ niệm.
- Tâm trạng đứng ngay sau câu hỏi như app đang chạy: là việc hằng ngày thứ hai (một sao trong chòm sao), người dùng đã quen chỗ, đổi chỗ thì mất phản xạ.
- Đêm qua đứng ngay sau bảng để ba khối về người ấy liền nhau, và để cuối cụm vì là chuyện đã qua + ẩn được 30 ngày (ẩn đi không làm khối khác nhảy chỗ). Cùng logic thứ tự hàng của bản A.

**Chiều dài (từ đỉnh vùng cuộn tới hết Kỷ niệm, 390):**

| | Đo DOM trên mock (`compare.html`) | Ước tính theo kích thước app thật |
|---|---|---|
| Home hiện tại | — | 1.933 px |
| **A · Gộp** | **2.251 px** | 2.165 px (+12%) |
| **B · Không gộp** | **2.658 px** (+407 so với A) | ≈2.546 px (+32%) |

(Mock cao hơn app ≈80 px vì thẻ đếm mock 444 so với 404 thật, MoodCard mock 298 so với 265 đo trên máy.)

| | A · Gộp | B · Không gộp |
|---|---|---|
| Được | Ngắn hơn ≈400 px. Một lần liếc trả lời cả 4 câu về người ấy, cùng một khuôn ba làn. Tâm trạng nằm cạnh "Đến nơi" nên đọc thành một câu chuyện ("Nhớ, về nhà 18:42, pin 12%"). | Giữ nguyên hai thẻ người dùng đã quen: mặt tâm trạng to 56 dễ thương, nút "Đổi tâm trạng" rõ, dòng "Ngủ cùng lúc", khoảnh khắc trùng tâm trạng giữ hình to. Dev ít việc hơn (không đụng mood, sleep). |
| Mất | Mặt tâm trạng thu còn 24, mất nút "Đổi tâm trạng" (chạm hàng để đổi), dòng "Ngủ cùng lúc" chỉ còn trong màn Giấc ngủ, khoảnh khắc trùng tâm trạng thành tim nhỏ ở cột giữa. | Dài thêm ≈400 px (thêm gần nửa màn cuộn). Ba khối liền nhau hỏi cùng một câu "người ấy hôm nay" bằng ba kiểu vẽ khác nhau (mặt to · ba làn · trăng). Tiêu đề bảng "Thảo hôm nay thế nào?" đứng ngay dưới thẻ Tâm trạng nên hơi lặp; nếu chọn B nên đổi tiêu đề bảng thành "Hai bên đang ở đâu?". |

Gate bản B: `lint.mjs --app` 0 FAIL / 0 WARN; `inspect.mjs --app --widths 390` `home-b.html` 0 FAIL (cùng `--allow` brand như A; WARN `heavy-borders`, `colour-sprawl`, `kpi-size` như A), `compare.html` 0 FAIL (thêm WARN `radius-mix` vì khung tài liệu bo 24). Nhìn ảnh: thẻ Tâm trạng/Đêm qua khớp ảnh chụp app (`docs/screenshots/home-today.jpg`); vòng sửa: trang so sánh có chữ dính mép trái ở khổ điện thoại (inspect FAIL `edge-text`) → đưa vào khung lề 16. Còn lại: nhãn "BẠN/THẢO" của MoodCard trong mock dùng `textSecondary` thay `textTertiary` của app (app đang thiếu tương phản, ngoài phạm vi).

- [2026-10-20] [Designer] Thêm bản B (không gộp) + trang so sánh theo yêu cầu user "mock 2 bản để tôi xem". A 2.251 px, B 2.658 px (đo mock). Chờ user chọn.

### 14. Bản C — bản chọn (user chốt 2026-10-20)

Mock: `docs/design/home-daily-open-2/home-c.html` (cặp đã ghép, 19:05) · `home-c-waiting.html` (cặp đang chờ) · `compare.html` (C · A · B cạnh nhau, C đầu, nhãn "C · Bản chọn", chiều dài đo thật). A/B giữ nguyên làm lịch sử. Hàm mới trong `ui.js`: `homeC`, `arrivalCardC`, `weatherCardC` (dùng lại `moodCard`/`sleepCard` của B); `data.js` thêm `PLACE_NAMES` + `placeLine`.

**Hai quyết định của user:** (1) **bỏ poke**: không tim ở thẻ đếm, widget, thông báo; thẻ đếm trả về đúng app đang chạy (`AnimatedCoupleName`, đồng hồ chạy giây, chuỗi). Mục 4 (nhận 42 px) và ghi chú sửa spec poke hết hiệu lực. (2) **không bảng chung**: không có `TodayBoard`; Tâm trạng, Về đến nhà, Thời tiết, Đêm qua mỗi thứ một thẻ.

**Thứ tự (cặp đã ghép):**

| # | Khối | Cao mock (px) | Lý do |
|---|---|---|---|
| 1 | CounterCard như app (không tim) | 400 | giữ nguyên |
| 2 | "Hôm nay của chúng mình" + pill chòm sao | 26 | |
| 3 | Câu hỏi hôm nay | 287 | việc hằng ngày số 1, giữ chuỗi |
| 4 | **Tâm trạng hôm nay** (MoodCard như app) | 298 | việc hằng ngày số 2, một sao trong chòm sao; đúng chỗ đang chạy nên không mất phản xạ |
| 5 | **Về đến nhà chưa?** (gọn) | 253 | tin "bây giờ" của người ấy, đọc nhiều nhất buổi chiều tối |
| 6 | **Thời tiết hai nơi** (gọn) | 167 | bối cảnh trong ngày; hàng chung chỉ hiện khi có nút gợi ý hoặc chênh ≥ 5° |
| 7 | **Đêm qua** (SleepCard như app) | 202 | chuyện đã qua, ẩn được 30 ngày; để cuối cụm nên ẩn đi không làm thẻ khác nhảy chỗ |
| 8 | Chơi cùng nhau (thay RpsInviteCard) | 209 | việc người ấy đang chờ (tới lượt mình) |
| 9 | Sổ chung tháng 10 | 76 | ghi khoản một mình, thẻ rẻ |
| 10 | Phân vân gì không? | 278 | theo bữa ăn |
| 11 | Kỷ niệm gần đây | 26 + 240 | xem lại |

Khoảng cách giữa thẻ 16, giữa nhóm 28 như code. **Cặp đang chờ:** thẻ đếm (không chuỗi) → banner chờ → câu hỏi (trạng thái chờ) → Thời tiết (một làn của bạn) → Đêm qua (một làn) → Sổ tiền của mình → Phân vân → Kỷ niệm; ẩn Tâm trạng, Về đến nhà, Chơi cùng nhau.

**Thẻ "Về đến nhà chưa?" bản gọn** (từ `arrival/home-card.html`, đảo làn): `ContentCard` pad 16 · hàng tiêu đề `IconBadge(home_2)` + "Về đến nhà chưa?" 16 w800 + chevron (→ màn Quản lý) · 14 · hai làn như SleepCard, vạch dọc α.10: **Bạn trái** (`PersonLabel` · câu 16 w700 · "08:05 · tự báo" 13 w600 xám · nút chính viền h40 **"Về nhà rồi"** · dưới nó nút phụ chữ h40 **"Đến nơi rồi"** (icon `location`, 14 w700 navy) mở sheet chọn nơi đã đặt tên) | **người ấy phải** (`PersonLabel` · câu · giờ (· pin x%) · pill "Pin còn x%" khi ≤ 20). Theo spec arrival D7 mới (PO chốt 2026-10-20): nút chính "Về nhà rồi" + nút phụ "Đến nơi rồi", cả hai nằm trong làn Bạn, xếp dọc (làn chỉ ≈133 px ở khổ 360 nên không đặt cạnh nhau). "Hỏi thăm" và bật/tắt tự báo ở màn Quản lý. Dòng "· tự báo" / "· bấm tay" giữ yêu cầu D11 (người chia sẻ thấy mình đang chia sẻ). **Tên nơi tự đặt** (mặc định "Nhà"): câu là "Đã về đến nhà" / "Đã rời nhà" cho nơi mặc định, "Đã đến {tên}" / "Đã rời {tên}" cho nơi tự đặt (push kiểu "Thảo đã đến Phòng gym") (mẫu: Thảo có "Công ty", Tuấn có "Văn phòng"; assert trong `data.js`). Trạng thái chưa bật / thiếu quyền / chờ mạng / lỗi lấy theo bảng §3.3 của arrival, đặt vào làn tương ứng.

**Thẻ "Thời tiết hai nơi"** (từ `weather/home.html`, đảo làn): Bạn trái · người ấy phải, nhãn làn "Bạn" (`sleepYou`) thay "Mình"; còn lại giữ spec weather §3.1 (30/600 + icon 24, câu tình trạng 14 w700, "Cập nhật hh:mm"). Lúc 19:05 không có nút gợi ý và chênh 4° nên thẻ thu còn 167 px (không hàng chung).

**Chiều dài (từ đỉnh vùng cuộn tới hết Kỷ niệm, 390, 19:05):**

| | Đo DOM mock (`compare.html`) | Theo kích thước app thật |
|---|---|---|
| Home hiện tại | — | 1.933 px |
| **C · bản chọn** | **2.720 px** | ≈2.610 px (+677, +35%) |
| A · gộp (có tim) | 2.251 px (−469 so với C) | 2.165 px |
| B · không gộp | 2.658 px (−62 so với C) | ≈2.546 px |
| C · cặp đang chờ | — | ≈2.148 px (hiện tại 1.873) |

C dài hơn B 62 px (bỏ tim −42, tách hai hàng bảng thành hai thẻ +28, nút phụ "Đến nơi rồi" +48). Muốn ngắn hơn mà vẫn giữ "mỗi thứ một thẻ" thì còn hai cách: thẻ Thời tiết tự thu thành một dòng khi không có gì đáng nhắc, hoặc MoodCard bỏ nút "Đổi tâm trạng" (chạm mặt để đổi) — đều chưa làm, chờ user.

**Chỗ Dev sửa (thay §7):** `headerExtra` giữ `AnimatedCoupleName` (không `PokeCoupleRow`) · giữ `MoodCard` + `SleepCard` ở chỗ cũ · chèn `ArrivalCard` (bản gọn hai làn) và `WeatherCard` (đảo làn) giữa MoodCard và SleepCard, cách 16 · `RpsInviteCard` → `PlayTogetherCard` ngay sau SleepCard · `MoneyHomeEntry` sau đó · dời `DecisionCard` xuống sau Sổ tiền · skeleton cập nhật cùng thứ tự. Không có `TodayBoard`. Deep-link `pendingHomeFocus` `'arrival'` / `'weather'` cuộn tới đúng thẻ. Copy §8 của bảng không dùng nữa, trừ chuỗi trạng thái nơi tự đặt (PO viết theo spec arrival mới).

**Gate:** `lint.mjs --app` 0 FAIL / 0 WARN. `inspect.mjs --app --widths 390`: `home-c.html` 0 FAIL, `home-c-waiting.html` 0 FAIL, `compare.html` 0 FAIL (cùng `--allow` brand). WARN có lý do: `mixed-font-headline` (inspector coi "27° ☁" là tiêu đề trộn phông vì icon thời tiết là glyph Iconsax, đúng như app) · `colour-sprawl` · `kpi-size` · `contrast` nút banner chờ (nợ cũ) · `radius-mix`/`edge-text` ở trang so sánh (khung tài liệu). Vòng sửa: tim giữa hai tên ở thẻ đếm bị tính là phông icon trong tiêu đề → vẽ bằng SVG.

**Nhìn lại (1 vòng, theo ảnh 390):** design 7,5 · usability 7,5 · creativity 7 · content 8 → 7,45. Còn yếu: bốn thẻ người ấy liền nhau, mỗi thẻ một kiểu hai làn hơi khác (mặt to, câu, nhiệt độ, trăng) nên mắt phải đọc lại nhãn Bạn/Thảo bốn lần; Home dài nhất trong ba bản; lúc 19:05 thẻ Thời tiết ít thông tin mà vẫn chiếm 167 px.

- [2026-10-20] [Designer] Bản C (bản chọn): bỏ poke, mỗi thứ một thẻ. Thêm `home-c.html`, `home-c-waiting.html`, cập nhật `compare.html` (C đầu, "Bản chọn"). Thêm nút phụ "Đến nơi rồi" vào làn Bạn theo D7 mới. C 2.720 px mock (A 2.251, B 2.658; ≈2.610 so với 1.933 hiện tại theo kích thước app). Lint 0/0, inspect 390 0 FAIL.

### 15. Soát dễ dùng (UI UX Pro Max) — bản C sau soát

> User 2026-10-20: "dùng UI-UX promax thiết kế, tôi yêu cầu thiết kế phù hợp với người dùng và UI tiện lợi dễ sử dụng". Giữ design system, mỗi thứ một thẻ, không poke, đồng hồ chạy giây. Mục này thắng mục 14 ở chỗ lệch. Đã sửa thẳng `home-c.html` / `home-c-waiting.html` (qua `ui.js`: `ritualC`, `moodCardC`, `arrivalCardC`, `weatherCardC`). Người dùng mẫu: cặp đôi trẻ, mở app lướt 5–10 giây, một tay.

**Truy vấn (search.py 2.13.0, không `-I`):** `"touch target size"`, `"touch target spacing adjacent buttons"`, `"color only information"`, `"fixed bottom navigation content overlap"`, `"gesture alternative visible control"` `--domain ux` → *Touch Target Size* 44pt/48dp (High), *Touch Spacing* ≥ 8, *Color Only* (High), *Fixed Positioning*: chừa chỗ cho phần tử cố định. Các truy vấn `"thumb zone reachability mobile"`, `"cognitive load too many choices"`, `"content priority mobile above fold"`, `"consistent component pattern repeated cards"`, `"affordance hidden tap gesture discoverability"`, `"primary action one per card"`, `"glanceable summary collapse empty"` (ux) và `"long scroll home many cards"`, `"inkwell tap target size"`, `"expandable card collapse"`, `"touch target"`, `"gesture"` (flutter) không khớp chủ đề (trả về keyboard, motion, slivers…) ⇒ đối chiếu thẳng `references/quick-reference.md` của skill: **`content-priority`** (nội dung chính trước, gập phần phụ), **`gesture-alternative`** (không để hành động chỉ có cử chỉ, luôn có nút thấy được), **`primary-action`** (một CTA chính, phần phụ lùi xuống), **`consistency`**, **`progressive-disclosure`**, **`safe-area-awareness`**.

| Câu soát | Trước (mục 14) | Sửa |
|---|---|---|
| Việc hằng ngày số 1 có trong màn đầu, mấy chạm? | Câu hỏi lộ ở màn đầu nhưng nút trả lời nằm dưới 3 thanh mờ khoá (114 px) ⇒ rơi dưới thanh nav nổi: cuộn + chạm. | **Nút "Trả lời để mở khoá…" đưa lên ngay dưới câu hỏi**, dòng khoá thành 1 dòng dưới nút: "🔒 Thảo đã trả lời lúc 12:31, đang chờ bạn" (giữ lý do, thêm giờ). Theo kích thước app: nút ở y≈645–697, trên nav (≈710) ⇒ **1 chạm từ màn đầu** (`content-priority`, `safe-area-awareness`). Đổi `TodayRitualCard` trạng thái B (người ấy trả lời trước); A/C/D giữ nguyên. Thẻ cao 285 → ≈190. |
| 4 thẻ người ấy liền nhau có rối không? | Mỗi thẻ một kiểu nhãn: Tâm trạng chữ xám in hoa giữa cột, Thời tiết "● Bạn · Hà Nội" 13, Về nhà và Đêm qua `PersonLabel`. | **Một mẫu nhãn cho cả 4:** `PersonLabel` (chấm màu người 8 + tên IN HOA 11 w700) ở đầu mỗi làn, **Bạn luôn trái, người ấy luôn phải**, khe tiêu đề → làn 14. Màu chấm không đổi giữa các thẻ nên sau thẻ đầu mắt đọc theo màu + vị trí (`consistency`); vẫn có chữ nên không chỉ dựa vào màu (`Color Only`). Không gộp thẻ (user chốt). |
| Thẻ không có gì đáng nói có tự gọn? | Thời tiết luôn 167–190 px kể cả lúc chỉ "Nhiều mây". | **Chọn: Thời tiết tự thu thành 1 hàng 76 px** khi chỗ người ấy không mưa / nắng gắt / lạnh, chỗ mình cũng chỉ "trời", và chênh < 5°: `IconBadge` + "Thời tiết hai nơi" + "● Hà Nội 23° ● TP.HCM 27° · Nhiều mây" (thứ tự Bạn · người ấy, chạm mở sheet chi tiết). Có chuyện đáng nhắc thì tự mở đủ hai làn + nút gợi ý (`progressive-disclosure`). Cặp chờ: "● Hà Nội 23° · Nhiều mây". |
| | MoodCard có nút to 48 "Đổi tâm trạng" chiếm 64 px mỗi ngày sau khi đã chọn. | **Không chọn "chạm mặt để đổi" làm đường duy nhất** (cử chỉ ẩn, vi phạm `gesture-alternative`). **Chọn: đã chia sẻ thì nút to thu thành nút chữ "✎ Đổi" ở hàng tiêu đề** (vùng chạm 44, góc phải, gần ngón cái); mặt của bạn vẫn chạm được như đường tắt. Chưa chia sẻ thì giữ nút to "Chia sẻ tâm trạng" vì đó là việc chính của thẻ. Tiêu đề đổi sang khuôn chung `IconBadge` 44 + 16 w800 (trước là ô 36 r12 + `sectionTitleStyle`) cho cùng hàng với 3 thẻ kia. 265 → ≈200 px. |
| Mỗi thẻ một hành động chính, vùng chạm ≥ 44? | "Về nhà rồi" h40; hai nút xuống 2 hàng ở khổ 360. | Về đến nhà: **đồng bộ mock arrival bản 2** (19:30): hai làn nền màu người α.10, "Hỏi thăm" (nút chữ 44) trong làn Thảo, chân thẻ **nút chính "Về nhà rồi" + nút phụ viền "Đến nơi rồi ⌄"**, lưới 2 cột bằng nhau (2×144 ở khổ 360) nên luôn một hàng, cao 44. Các nút khác đã ≥ 44: pill "Quay" 36 nằm trong hàng 64 bấm cả hàng, CTA caro h40 trong hàng 68 bấm cả hàng, nút "+" Sổ tiền 44, "Đổi" 44. |
| Nhất quán với thẻ đang chạy? | | Đêm qua giữ nguyên (đã là mẫu gốc). Tâm trạng chỉ đổi hàng tiêu đề, nhãn làn và nút đổi; mặt 56, chữ, ghi chú giữ. Chơi cùng nhau, Sổ tiền, Phân vân, Kỷ niệm giữ khuôn. |

**Thứ tự không đổi:** thẻ đếm → câu hỏi → Tâm trạng → Về đến nhà chưa? → Thời tiết → Đêm qua → Chơi cùng nhau → Sổ tiền → Phân vân gì không? → Kỷ niệm. (Mock thẻ đếm bản C chỉnh đệm cho sát số đo app: 380 so với 362 thật.)

**Chiều dài mới (đỉnh vùng cuộn → hết Kỷ niệm, 390, 19:05):**

| | Đo mock (`compare.html`) | Theo kích thước app |
|---|---|---|
| Home hiện tại | — | 1.933 px |
| **C sau soát** | **2.507 px** (trước soát 2.720, −213) | ≈2.430 px (+26%) |
| A · gộp | 2.251 px | 2.165 px |
| B · không gộp | 2.658 px | ≈2.546 px |
| C · cặp đang chờ | — | ≈2.060 px (hiện tại 1.873) |

Đo từng thẻ C (mock 390): câu hỏi 188 · Tâm trạng 224 · Về đến nhà 309 · Thời tiết 92 (gọn) · Đêm qua 202 · Chơi 209 · Sổ tiền 76 · Phân vân 278 · Kỷ niệm 240.

**Gate:** lint 0/0; inspect 390 `home-c.html` 0 FAIL (WARN colour-sprawl, kpi-size), `home-c-waiting.html` 0 FAIL (+ contrast nút banner chờ, nợ cũ), `compare.html` 0 FAIL. Soát thêm khổ 360 (`?w=360`): sửa mặt tâm trạng hai cột lệch dọc khi một bên có ghi chú (căn đầu cột), sửa hai nút thẻ Về nhà rớt 2 hàng.

**Cho Dev:** icon "⌄" của "Đến nơi rồi" là `IconsaxPlusLinear.arrow_down` (chevron); `arrow_down_1` là mũi tên có thân (mock arrival ghi chú `chevDown = arrow_down_1` là nhầm). Mood picker gọi `showMoodPicker(context)` có sẵn.

**Còn cần user / PO quyết:**
1. Thẻ Về đến nhà bản 2 dùng nút **đặc navy** cho "Về nhà rồi". Home khi đó có 3 nút đặc navy cùng lúc (trả lời câu hỏi, "Đi tiếp" caro, "Về nhà rồi") — lệch quy tắc `primary-action` và quy ước caro C6 "đặc = người ấy đang chờ bạn". Đề xuất: trên Home để "Về nhà rồi" dạng viền, chỉ đặc trong màn Quản lý. Cần Designer arrival + PO chốt.
2. Thẻ Về đến nhà là thẻ cao nhất trong cụm (309) vì làn có nền màu + nút trong làn + hai nút chân. Nếu muốn ngắn: bỏ nền màu làn (dùng vạch giữa như Đêm qua) hoặc dời dòng "Tự báo: Nhà và 2 nơi khác" vào màn Quản lý (nhưng D11 cần người chia sẻ thấy mình đang chia sẻ).
3. Đổi thứ tự trạng thái B của thẻ câu hỏi (nút lên trên, bỏ 3 thanh mờ) là đổi một feature đang chạy: user duyệt?

- [2026-10-20] [Designer] Soát dễ dùng bản C theo UI UX Pro Max: nút trả lời lên màn đầu (1 chạm), một mẫu nhãn làn cho 4 thẻ người ấy, Thời tiết tự thu 1 hàng khi không có gì đáng nhắc, Tâm trạng thu nút "Đổi" lên tiêu đề, đồng bộ thẻ Về đến nhà bản 2 của Designer arrival. C 2.720 → 2.507 px mock (≈2.430 theo app, hiện tại 1.933). Lint 0/0, inspect 390 0 FAIL.
- [2026-10-20] [Lead] Trên Home, nút "Về nhà rồi" của thẻ Về đến nhà dùng dạng viền (đã sửa `ui.js` bản C) để Home chỉ còn nút đặc cho trả lời câu hỏi và lượt caro.
- [2026-10-20] [Lead] User chọn **giữ nguyên thẻ Câu hỏi đang chạy** (không đưa nút "Trả lời" lên trên, không thay ba thanh mờ). Bản C đã đổi lại dùng `ritual()` như app; `ritualC()` để lại trong mock chỉ làm tham khảo, Dev KHÔNG làm. User chưa duyệt đợt thiết kế, đang xem kỹ.

### 16. Bản D — sắp xếp lại theo nhóm việc (2026-10-29)

> User 2026-10-29: "sắp xếp lại layout của trang home, dùng skill ui ux promax". Giữ design system và giữ từng thẻ đúng như đang chạy (user từng chốt "mỗi thứ một thẻ riêng"). Chỉ đổi cách xếp.

**Ảnh trước** (máy ảo Pixel 10, tài khoản Thảo, 16:03): một tiêu đề "Hôm nay của chúng mình" ôm 7 thẻ liền nhau (câu hỏi, tâm trạng, về nhà, thời tiết, đêm qua, chơi, phân vân). Mọi khe đều 16 nên mắt không thấy chỗ nào hết nhóm. Muốn tìm ván caro phải cuộn qua 5 thẻ và đọc từng tiêu đề.

**UI UX Pro Max 2.13.0** (`search.py`, không `-I`): `"content priority above fold"`, `"progressive disclosure"`, `"visual hierarchy grouping"`, `"card layout spacing consistency"`, `"infinite scroll long page"` `--domain ux` trả về Truncation, Heading line balance, Breadcrumbs, Touch spacing: lệch chủ đề, như lần soát bản C. Nên đối chiếu thẳng `references/quick-reference.md` + `pro-rules.md`: **`whitespace-balance`** (dùng khoảng trắng gom nhóm, tách phần), **Section spacing hierarchy** (mỗi cấp một bậc khoảng cách), **`content-priority`**, **`visual-hierarchy`**, **`consistency`**, a11y thứ tự đọc + heading. `"bento grid"`, `"dashboard widgets cards mobile"` `--domain style` ra Bento Box Grid (để dành, xem cuối mục). `"list scroll sliver"` `--stack flutter` khuyên `CustomScrollView` cho list dài; Home ≈3,5 màn nên giữ `SingleChildScrollView`.

**Tasteskill** (app run, sheet chung đợt 2 editorial-greeting seed 1822703143, `--keep palette,type`, không draw lại). Câu hỏi của màn giữ nguyên: "Hôm nay người ấy thế nào, và có gì đang chờ mình làm?". Bản D tách nó thành 3 câu con, mỗi câu một nhóm. Face giữ "cặp đôi là ba làn"; tiêu đề nhóm 2 gọi tên người ấy.

| Nhóm | Câu hỏi của nhóm | Thẻ |
|---|---|---|
| Hôm nay của chúng mình (+ pill n/6) | Hôm nay mình cần làm gì? | Câu hỏi · Tâm trạng |
| **{tên người ấy} thế nào rồi?** (mới) | Người ấy đang ra sao? | Về đến nhà chưa? · Thời tiết hai nơi · Đêm qua |
| **Lúc rảnh** (mới) | Rảnh thì làm gì cùng nhau? | Chơi cùng nhau · Phân vân gì không? |
| Kỷ niệm gần đây | Có gì để nhìn lại? | MemoryCinema |

Khe theo token Home v2: thẻ 16 · nhóm 28 · tiêu đề → thẻ 12. Thứ tự thẻ y như bản C, chỉ chen 2 tiêu đề, nên chỗ quen tay không đổi.

- **Cặp đang chờ:** chưa có người ấy để hỏi nên không có tiêu đề nhóm 2. Thời tiết + Đêm qua (một làn) nối tiếp nhóm Hôm nay với khe 16. Nhóm Lúc rảnh chỉ còn Phân vân. Tâm trạng, Về đến nhà, Chơi cùng nhau vẫn ẩn như cũ.
- **Tiêu đề nhóm 2 tự ẩn** khi cả ba thẻ đều ẩn.
- **Sổ tiền** (cờ `kMoneyFeatureEnabled` đang tắt): dời xuống cuối nhóm Lúc rảnh để khe đúng ở cả hai trạng thái cặp. Bật lại thì PO chốt nó thuộc nhóm nào.
- **a11y:** `SectionHeader` bọc tiêu đề trong `Semantics(header: true)`, TalkBack/VoiceOver nhảy được từ nhóm này sang nhóm kia. Áp cho mọi màn dùng `SectionHeader`.

**Copy** (humanizer cho VI, avoid-ai-writing detect cho EN: 0 sửa):

| key | vi | en |
|---|---|---|
| `homePartnerSectionTitle` | {name} thế nào rồi? | How's {name} doing? |
| `homePartnerSectionTitleFallback` | Người ấy thế nào rồi? | How's your partner doing? |
| `homeFreeTimeSectionTitle` | Lúc rảnh | Free time |

**Mock:** `docs/design/home-daily-open-2/home-d.html`, `home-d-waiting.html`, `compare-d.html` (C và D cạnh nhau, cả hai bỏ Sổ tiền như app). `ui.js` thêm `homeD`; `homeC` nhận `noMoney`.

**Gate:** `lint.mjs --app` 0 FAIL / 0 WARN. `inspect.mjs --app --widths 390` cả 3 trang 0 FAIL, cùng `--allow` của bản C (§10). WARN có lý do như cũ: colour-sprawl (thẻ đếm hồng), kpi-size (số ngày 76), contrast nút "Gửi cho người ấy 💌" ở banner chờ (nợ cũ).

**Chiều dài** (mock 390, 19:05, đỉnh vùng cuộn → hết Kỷ niệm): C 2.515 px → D 2.615 px (+100, +4%). Đó là giá của 2 tiêu đề.

```
ROUND 1 (mock 390)
Seen in one second: thẻ đếm, rồi "Hôm nay của chúng mình" với câu hỏi.
Scores: design 7,5 · usability 8 · creativity 7 · content 8 → 7,6.
Top three: 1. compare-d chưa công bằng (C còn Sổ tiền, app đã tắt) → bỏ ở cả hai.
2. Sổ tiền nằm giữa Chơi và Phân vân thì lệch khe khi cặp đang chờ (tiêu đề → Sổ tiền thành 28) → dời cuối nhóm.
3. Tiêu đề nhóm chưa phải heading với trình đọc màn hình → Semantics(header: true).

ROUND 2 (app thật, Pixel 10, Thảo 16:12)
Ba nhóm tách rõ; "Tuấn thế nào rồi?" ló ở đáy màn khi vừa cuộn qua thẻ tâm trạng; khe 28/12/16 đúng token.
Scores: design 8 · usability 8 · creativity 7 · content 8 → 7,8.
Còn yếu (ngoài phạm vi sắp xếp, chưa sửa): nhóm "Tuấn thế nào rồi?" có 3 nút đặc navy liền nhau
("Bật báo về nhà", "Nhắc Tuấn mang ô", "Bật theo dõi") — lệch primary-action và quy ước
"đặc = người ấy đang chờ bạn"; thẻ "Chơi cùng nhau" là thẻ duy nhất không có IconBadge ở tiêu đề,
giờ đứng ngay trên "Phân vân gì không?" trong cùng một nhóm.
```

**Để dành nếu muốn Home ngắn hơn:** Thời tiết + Đêm qua thành hai ô nửa bề ngang đứng cạnh nhau (Bento, dòng chấm màu người + số), tiết kiệm khoảng 200 px. Phải vẽ lại trạng thái chưa bật / thiếu quyền / lỗi của cả hai thẻ, nên chưa làm.

- [2026-10-29] [Designer] Bản D: chia Home thành 3 nhóm có tiêu đề (Hôm nay của chúng mình · {người ấy} thế nào rồi? · Lúc rảnh) + Kỷ niệm, thẻ giữ nguyên. UI UX Pro Max (whitespace-balance, section spacing hierarchy, content-priority) + tasteskill (sheet đợt 2, không draw lại). Mock `home-d*.html` + `compare-d.html`; lint 0/0, inspect 390 0 FAIL. +100 px so với C.

### 17. Bản E và F — bảng ô (2026-10-29, chờ user chọn)

> User 2026-10-29, sau bản D: "design lại layout cho trang homepage". D chỉ chen tiêu đề nên Home vẫn dài gần 4 màn; user muốn đổi bố cục thật. Giữ design system, giữ thẻ câu hỏi, giữ "mỗi thứ một thẻ riêng" (mỗi ô là một thẻ, không gộp bảng).

- **E · Bảng ô:** thẻ đếm giữ nguyên. "Hôm nay của chúng mình" = câu hỏi + lưới 2×2 ô (Tâm trạng · Về nhà / Thời tiết · Đêm qua). "Lúc rảnh" = 2 ô (Cờ caro · Oẳn tù tì) + Phân vân gọn (kết quả hôm nay + 3 nút Ăn gì? · Đi đâu? · Khác). Kỷ niệm giữ.
- **F · Bảng ô + thẻ đếm gọn:** như E, thẻ đếm canh trái (tên + ★chuỗi cùng hàng, số ngày 56 + "NGÀY BÊN NHAU", đồng hồ chạy giây giữ khuôn viên thuốc, thanh cột mốc), thấp hơn khoảng 120 px ⇒ trọn thẻ câu hỏi và nút "Trả lời để mở khoá…" nằm ở màn đầu, trên thanh nav (1 chạm, `content-priority`).
- **Khuôn ô:** ContentCard r24 đệm 14 · tiêu đề IconBadge 36 r12 + 15 w800 · Bạn trên, người ấy dưới (PersonLabel + giá trị 15 w700 + dòng phụ 12) · chân ô ghim đáy: một nút (pill 40, vùng chạm 44) hoặc một dòng sự thật. Lưới khe 12, ô cùng hàng cao bằng nhau nên chân ô thẳng hàng. Chạm thân ô mở màn/sheet chi tiết đang có (`progressive-disclosure`). Pin yếu nằm cùng dòng giờ để ô Về nhà không cao hơn ô bên cạnh.
- **Dời vào chi tiết:** "Đến nơi rồi"/"Hỏi thăm" của Về nhà (ô chỉ còn "Về nhà rồi", hoặc "Đến nơi rồi" khi đã ở nhà), mặt tâm trạng to, giờ cập nhật thời tiết khi có nút nhắc.
- **Cặp đang chờ:** lưới còn 2 ô của mình (Thời tiết, Đêm qua); Lúc rảnh còn Phân vân.
- **Độ dài (mock 390, 19:05):** D 2.615 · E 2.116 (−19%) · F 1.979 (−24%).
- **Gate:** lint `--app` 0/0; inspect `--app --widths 390` `home-e`, `home-f`, `home-e-waiting`, `compare-def` 0 FAIL (cùng `--allow` §10). WARN: colour-sprawl, kpi-size (F: 56 px), contrast nút banner chờ (nợ cũ), heavy-borders/radius-mix ở trang so sánh.
- **Nhìn lại vòng 1:** E 7,9 · F 8,0. Đã sửa: icon đồng hồ ở chân ô Thời tiết đang tô hồng (hồng chỉ cho tim) → xám; ô Tâm trạng hở ~40 px vì ô Về nhà cao hơn → đưa pill pin yếu lên cùng dòng giờ.
- **Mock:** `home-e.html`, `home-f.html`, `home-e-waiting.html`, `compare-def.html`; `ui.js` thêm `homeE`/`homeF` + hàm ô. Trang duyệt: https://claude.ai/artifact/EnmpGxDv6adHbC31crZ7Qk
- **Câu chờ user:** chọn D/E/F · ô Về nhà một nút · Bạn trên/người ấy dưới trong ô · Phân vân bản gọn.

- [2026-10-29] [Designer] Bản E (bảng ô) + F (bảng ô + thẻ đếm gọn) sau yêu cầu "design lại layout". Mock + gate 0 FAIL + artifact duyệt; đề xuất F. Chưa code.

### 18. Chốt (2026-10-29): bản D + "Lúc rảnh" của bản E

> User xem trang duyệt E/F rồi chốt bằng ảnh nhóm "Lúc rảnh" của mock: "chỉ sửa lại layout của lúc rảnh, còn lại giữ nguyên". ⇒ Home = bản D (§16) ở mọi chỗ khác; thẻ đếm, câu hỏi, tâm trạng, nhóm "{người ấy} thế nào rồi?" giữ nguyên. Lưới 2×2 và thẻ đếm gọn của E/F (§17) KHÔNG làm.

**Lúc rảnh (đã code):**
- **Hai ô cùng hàng** (khe 12, cao bằng nhau): Cờ caro trái · Oẳn tù tì phải. Mỗi ô: ContentCard r24 đệm 14 · huy hiệu 36 r12 + tên 15 w800 (tối đa 2 dòng, EN "Rock Paper Scissors") · câu đầu của dòng trạng thái in đậm 15 w700, phần sau xám 12 · nút ghim đáy, rộng hết ô, cao 40. Cả ô là vùng chạm; nút chỉ để nhìn (như hàng cũ). Nút đặc navy + chấm hồng khi người ấy đang chờ mình (C6), còn lại viền navy .18 dày 1.5 (cùng kiểu nút "Về nhà rồi"). Không còn tiêu đề "Chơi cùng nhau" trong thẻ vì tiêu đề nhóm "Lúc rảnh" đã nói điều đó.
- **Chữ trong ô dùng lại copy đang chạy**, không thêm key: `splitEntryLine` tách câu đầu ("Đến lượt bạn") khỏi phần sau ("Thảo vừa đi nước 14."). Copy caro viết theo dạng "trạng thái. chi tiết." nên tách được cả 11 trạng thái vi/en (test `caro_tile_split_test.dart`).
- **Phân vân gì không? bản gọn:** tiêu đề + "Đã quay" giữ · mỗi kết quả hôm nay (ăn, đi đâu, phân vân khác đầu tiên + "+N") là một hàng nền `surfaceLight` r16 (nhãn · kết quả · ai quay lúc nào · chevron → sheet kết quả) · ba nút cùng hàng nền hồng .10 cao ≥ 44: Ăn gì? · Đi đâu? · Khác (key mới `decisionChipCustom`). Ăn gì?/Đi đâu? mở kết quả hôm nay nếu đã có, chưa có thì mở vòng quay và quay luôn (không quay khi đang tải ngày); Khác luôn mở vòng quay để nhập (D20).
- **Cặp đang chờ:** chỉ còn thẻ Phân vân (hai ô chơi cần người ấy, như cũ).

- [2026-10-29] [Lead] User chốt: giữ bản D, chỉ đổi nhóm "Lúc rảnh" theo bản E (ảnh). Đã code + chạy máy ảo Android.
