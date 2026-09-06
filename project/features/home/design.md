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
