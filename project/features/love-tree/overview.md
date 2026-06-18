# Cây tình yêu (Love Tree) — overview (PO)

> Feature mới 2026-06-14 (user chốt autonomous, đi ngủ — "PO tự quyết tự chốt tự làm"). Mode 1: Designer → Dev → Tester.

## 1. Ý tưởng (user)
Một màn hình mới có **1 cái cây** biểu tượng cho tình cảm 2 người. Khi có **sự kiện** (streak 7 ngày, 100 tin, kỷ niệm 100 ngày…) cây **nở hoa**, **nhuỵ hoa là 1 icon tròn**. Cây phát triển + nở hoa cần **xúc tác của CẢ 2 người**. Khi có sự kiện, user vào app **thấy cây đang nở hoa luôn**.

## 2. PO chốt (v1)

### Mô hình "hoa = cột mốc" — DERIVE từ data sẵn có, KHÔNG backend mới
Chỉ dùng tín hiệu **monotonic** (chỉ tăng) ⇒ hoa đã nở KHÔNG bao giờ rụng (đúng cảm xúc: cột mốc tình yêu tích luỹ, không mất):
- **Ngày bên nhau** (`couple.anniversaryDate` → daysTogether): mốc 30 · 100 · 200 · 365(1 năm) · 520 · 730(2 năm) · 1000 · 1314. Nhuỵ = icon 💞 (heart) màu rose.
- **Streak DÀI NHẤT** (`StreakProvider.longestStreak` — KHÔNG dùng currentStreak vì reset): mốc 3 · 7 · 30 · 100 · 365. Nhuỵ = icon 🔥 (flame) màu cam-hồng.
- **Số ảnh kỷ niệm** (`PhotoProvider.photoCount`): mốc 1 · 10 · 25 · 50 · 100. Nhuỵ = icon 📷 (image) màu tím-lavender.
- (Tin nhắn / daily question: HOÃN v1 — chưa có bộ đếm tích luỹ; ghi backlog.)

→ **Số hoa = số mốc đã vượt** (đếm qua 3 nguồn). Càng nhiều mốc → càng nhiều hoa.

### Cây phát triển theo SỐ HOA (stage)
0 hoa → Hạt mầm · 1–2 → Mầm non · 3–5 → Cây non · 6–9 → Cây xanh · 10+ → Cây nở rộ. (Designer chốt visual từng stage — dựng bằng shape/path, KHÔNG cần asset art ngoài.)

### "Xúc tác của 2 người"
Cả 3 tín hiệu vốn cần 2 người (streak = cả 2 kết nối; ngày = mối quan hệ; ảnh = cùng đăng). Màn cây có khối **"Cùng vun đắp"**: gợi 2–3 hành động làm cây lớn (giữ chuỗi · đăng ảnh · trả lời câu hỏi) → CTA về tab tương ứng. Copy nhấn "cả hai".

### "Vào app thấy cây nở hoa" (cảm giác sự kiện)
- Lưu `lastSeenFlowerCount` (Hive `app_settings`, key `love_tree_seen_<coupleId>`).
- Mở màn cây: nếu `flowerCount > lastSeen` → **animation NỞ HOA** cho (các) bông mới + banner "Cây vừa nở X bông mới 🌸" → rồi cập nhật lastSeen.
- **Badge chấm/glow** trên StreakChip (entry) khi có hoa chưa xem ⇒ dụ user vào xem.

### Navigation
Tap **StreakChip** (chỗ "Cùng bắt đầu chuỗi mới nhé 🌱", `streak_chip.dart`) → **push `LoveTreeScreen`** (màn con chuẩn: `SubScreenHeader` back + chip). (Streak sheet auto-celebration giữ nguyên cho khoảnh khắc đạt mốc streak.)

## 3. North Star
Đẩy **retention + xúc tác 2 người** (mở app, giữ chuỗi, đăng ảnh) → phục vụ "cặp active đăng ảnh/tuần". Cây = mục tiêu cảm xúc chung, gamify nhẹ shame-free.

## 4. Ngoài phạm vi v1 (backlog)
- Hoa từ tin nhắn / daily-question (cần counter tích luỹ).
- Tree state share realtime qua Firestore (v1 derive local từ data đã sync sẵn → đủ).
- Tương tác chạm cây / tỉa / đặt tên cây.

---

# v2 — "Cây sống & kể chuyện" (PO spec, 2026-06-18)

> User chốt v2 = **#1 Bấm hoa xem ký ức + #2 Cây sống động + #3 Thẻ khoe cây**. Mục tiêu: biến màn "xem 1 lần" thành VÒNG LẶP *mở lại (cây đổi theo thời gian) → ngắm sâu (bấm hoa nhớ kỷ niệm) → khoe (kéo user mới)*. Phục vụ 2 mục tiêu: **engaging hơn** (variable reward + investment) + **thu hút user mới** (growth loop). Tất cả DERIVE từ data đã sync — KHÔNG backend mới. Mode 1: Designer → Dev → Tester.

## #1 — Bấm hoa = bản đồ ký ức *(investment + nostalgia)*

Mỗi bông đã nở (trên cây `_LoveFlower` + dòng đã-nở trong `_MilestonesCard`) **bấm được** → mở **bottom sheet "Khoảnh khắc này"**:
- Nhuỵ to (icon + màu theo `kind`) + tiêu đề ý nghĩa cột mốc.
- **Dòng ngày — theo `kind` (vì dữ liệu khác nhau):**
  - `days`: "Nở ngày {anniversary + value ngày}" (format theo locale `intl`). Ngày luôn là quá khứ (chỉ bông đã nở mới hiện).
  - `photos`: "Kỷ niệm thứ {value}" + **thumbnail ẢNH thứ value** = `photoProvider.sortedPhotos[len - value]` (list mới→cũ ⇒ ảnh cũ thứ `value`), kèm ngày ảnh; CTA **"Xem trong Thư viện"** → chuyển tab Gallery (deep-link photoId nếu khả thi). ⚠️ `photoCount` dùng server-aggregate ⇒ có thể > số ảnh đã load: nếu `len < value` → ẩn thumbnail, chỉ hiện ý nghĩa (KHÔNG crash).
  - `streak`: "Kỷ lục chuỗi {value} ngày" — **KHÔNG có ngày** (StreakProvider chỉ lưu số `longestStreak`, không lưu ngày đạt). Chỉ hiện ý nghĩa + 1 câu khích lệ.
- 1 câu copy ấm áp theo kind.
- **Bông CHƯA nở** (dòng locked trong card): bấm → hint dịu "Còn {N} {ngày/ảnh/ngày chuỗi} nữa để nở 🌱" + CTA về tab tương ứng. KHÔNG báo lỗi, KHÔNG ép.

## #2 — Cây sống động *(variable reward — lý do mở lại)*

Vẽ thêm LỚP NỀN + hạt động trên `LoveTreePainter` (vẫn 100% CustomPaint, không asset ngoài). **Reduce Motion** (`MediaQuery.disableAnimations`) PHẢI vá đủ: tắt mọi chuyển động, GIỮ trạng thái tĩnh đẹp (sao tĩnh, không lay/đom đóm).
- **Trời theo GIỜ** (`DateTime.now().hour`): bình minh 5–9 (hồng cam nhạt) · ngày 9–16 (xanh sáng/blush) · hoàng hôn 16–19 (cam-hồng đậm — sunsetRomance) · đêm 19–5 (tím-navy + **sao tĩnh** + **đom đóm** lập loè). 4 mốc, gradient mượt.
- **Mùa theo THÁNG**: xuân 2–4 (thêm cánh hoa rơi nhẹ) · hè 5–7 (lá xanh đậm) · thu 8–10 (vài lá vàng) · đông 11–1 (tông mát). (Tết/Valentine accent: backlog, đừng làm v2.)
- **Vi-động idle**: hoa/lá đung đưa nhẹ (biên độ nhỏ, chu kỳ ~3–4s, lệch pha), thi thoảng 1 bướm/đom đóm bay ngang. Nhẹ — không gây rối, không hại pin (giới hạn số hạt).

## #3 — Thẻ "Khoe cây" *(growth loop — acquisition)*

Nút **"Khoe cây"** (header trailing của `SubScreenHeader` + 1 action trong `_BloomBanner` khi vừa nở) → dựng **thẻ branded off-screen** (RepaintBoundary → `ui.Image` → PNG temp → `XFile`) → `SharePlus.instance.share(ShareParams(files:[xfile], text: <l10n>))`.
- Nội dung thẻ: minh hoạ cây (stage + số hoa hiện tại) trên nền gradient brand · **tên cặp đôi** (`AnimatedCoupleName` tĩnh, `pulseHeart:false`) · "{days} ngày bên nhau · {flowerCount} bông hoa" · 1 tagline ấm · **watermark mờ "Dear Embeiu"** góc dưới (acquisition).
- Tỉ lệ cố định hợp story: **4:5** (1080×1350 logic). Tự chứa, không phụ thuộc layout màn.
- share_plus ^11 sẵn (pattern: `invite_action_buttons.dart:66`). Truyền `sharePositionOrigin` (iPad popover).

## Acceptance criteria (PO nghiệm thu)
1. Bấm 1 bông đã nở (trên cây HOẶC trong card) → sheet hiện đúng ý nghĩa + đúng dòng-ngày theo kind; bông `photos` có ảnh thì hiện thumbnail + ngày, không có thì ẩn gọn (không crash).
2. CTA "Xem trong Thư viện" ở sheet `photos` chuyển sang tab Gallery.
3. Bấm bông chưa nở → hint "còn N…" + CTA, không lỗi.
4. Nền trời đổi theo 4 khung giờ (test bằng đổi giờ máy); đêm có sao + đom đóm.
5. Lá/mùa đổi theo tháng (ít nhất phân biệt được 4 mùa).
6. Reduce Motion ON → không còn chuyển động nào, vẫn đẹp tĩnh.
7. "Khoe cây" → mở share sheet OS với 1 ảnh PNG thẻ đẹp (tên cặp + ngày + số hoa + watermark).
8. `fvm flutter analyze` sạch; i18n đủ vi+en (sửa CẢ 2 ARB rồi gen-l10n).

## Copy cần (vi / en) — Dev thêm key, gen-l10n
- Sheet title: "Khoảnh khắc này" / "This moment".
- days: "Nở ngày {date}" / "Bloomed on {date}".
- photos: "Kỷ niệm thứ {n}" / "Memory #{n}"; CTA "Xem trong Thư viện" / "View in Gallery".
- streak: "Kỷ lục chuỗi {n} ngày" / "{n}-day streak record".
- locked: "Còn {n} nữa để nở 🌱" / "{n} to go before this blooms 🌱".
- share button: "Khoe cây" / "Share our tree"; tagline thẻ + text share: Designer/Dev chốt, nhấn "của chúng mình".

## Ngoài phạm vi v2 (giữ backlog)
Tưới cây hằng ngày (#4) · nguồn hoa mới daily-Q/chat/tuần (#5, cần counter) · vật trang trí mốc lớn (#6) · home-widget (#7, roadmap NEXT) · theme cây trả phí (#8, monetization).

---

# v2.1 — Vẽ lại cây/hoa đẹp hơn + hướng dẫn bấm hoa (PO spec, 2026-06-18)

> User chốt: **(A) Nâng cấp CustomPaint** (vẽ cây/hoa tinh tế hơn, KHÔNG dùng asset internet ngay — rủi ro bản quyền; tách layer để v3 drop SVG/Lottie vào thay được) + **(B) Coach mark 1 lần + caption** hướng dẫn bấm hoa. Mode 1: Designer → Dev → Tester.

## (A) Nâng cấp visual cây + hoa — code, GIỮ toàn bộ logic v1/v2
- **Cây**: thân/cành cong tự nhiên hơn (bézier, độ dày thuôn dần), tán lá **nhiều lớp** mềm (≥2–3 lớp xanh khác sắc độ), bóng đổ nhẹ. Đẹp hơn rõ rệt từng stage seed→bloom.
- **Hoa**: 5–6 cánh **nhiều lớp** (lớp sau hơi xoay/đậm hơn) + gradient cánh tinh tế; nhuỵ disc đẹp hơn (viền/ánh sáng nhẹ) — vẫn dùng `nucleusIcon/nucleusColor/petalEdge` per kind hiện có.
- **GIỮ NGUYÊN**: milestone math, `_bloomPositions`/index ổn định, stage thresholds, `lastSeen`/bloom-once, lớp trời theo giờ + mùa (#2), thẻ Khoe cây (#3), bấm hoa (#1), Reduce-Motion matrix.
- **Tách layer render** (yêu cầu user): tách phần VẼ cây/hoa sau 1 ranh giới rõ (vd painter/strategy riêng) để v3 có thể thay bằng asset SVG/Lottie mà KHÔNG đập lại logic mốc/stage/tap. KHÔNG thêm dependency/asset ở v2.1.
- ⚠️ KHÔNG nhúng ảnh internet (bản quyền). Asset thật = v3, user tự nguồn license-safe.

## (B) Hướng dẫn bấm hoa
- **Coach mark 1 LẦN/cặp đôi** (Hive flag, vd `love_tree_coach_<coupleId>`): lần đầu mở `LoveTreeScreen` mà có ≥1 hoa đã nở → overlay hint **gợn sóng/ngón tay chạm 1 bông nổi bật nhất** + tooltip "Chạm để xem khoảnh khắc 🌸". Tự ẩn khi user chạm bất kỳ / sau ~4s. Set flag → không hiện lại.
- **Caption cố định** dưới cây (luôn có khi có ≥1 hoa): "Chạm vào mỗi bông để xem kỷ niệm" — affordance thường trực.
- **Reduce Motion**: coach mark bỏ gợn sóng động → hiện tĩnh (tooltip + chấm), vẫn auto-ẩn.

## Acceptance (PO)
1. Cây + hoa trông đẹp/tinh tế hơn rõ ở mọi stage (xem mắt). Không vỡ layout, không tụt FPS.
2. Bấm hoa / đổi giờ-mùa / thẻ Khoe cây / bloom animation — vẫn chạy đúng như v2 (không regression).
3. Coach mark hiện ĐÚNG 1 lần (mở lại không hiện); caption luôn có khi có hoa.
4. Reduce Motion ON: coach mark tĩnh, không động.
5. `fvm flutter analyze` sạch; copy coach mark + caption đủ vi+en.
6. Render layer cây/hoa tách rõ để sau thay asset (Dev ghi chú ranh giới trong dev.md).

## Copy (vi/en)
- Coach tooltip: "Chạm để xem khoảnh khắc 🌸" / "Tap to see this moment 🌸".
- Caption: "Chạm vào mỗi bông để xem kỷ niệm" / "Tap a flower to relive a memory".

---

# v2.2 — Pivot visual: CÀNH HOA ANH ĐÀO (PO spec, 2026-06-18)

> User: "cái cây xấu quá" (tán blob xanh lá mạ = clip-art, lệch tông hồng). Chốt đổi metaphor sang **cành hoa anh đào** (sakura branch): 1 cành nghiêng cong, **blossom = mốc**, thanh thoát + hợp tông hồng romantic + dễ đẹp hơn cả cây lá đầy. Tận dụng tầng `LoveTreeRenderer` (v2.1 đã tách) → THAY renderer = `SakuraBranchRenderer`, GIỮ toàn bộ logic. Mode 1: Designer → Dev → Tester.

## Đổi gì
- **Bỏ** tán blob xanh + lá dán viền + thân Y chunky + xanh lá mạ.
- **Cành sakura**: cành chính cong (bézier) + 1–2 nhánh phụ, thân nâu ấm thuôn; vài lá sakura nhỏ (xanh-ngả-hồng, RẤT ít, chỉ điểm xuyết — KHÔNG khối lá to).
- **Blossom = mốc**, đính DỌC theo cành (anchor parametric trên đường cong, lệch 2 bên), thay "scatter trong canopy". Hoa 5 cánh sakura (khía đầu cánh), gradient hồng mềm tâm trắng→`petalEdge(kind)`, nhuỵ nhỏ + nhuỵ-vàng chấm, icon kind nhỏ ở tâm, **bỏ viền chip cứng** → glow mềm. Vẫn tap ≥44px, vẫn `nucleusIcon/nucleusColor` per kind.
- **Stage theo flowerCount (GIỮ thresholds)**: seed=cành trơ + 1–2 nụ kín · sprout=cành ngắn + vài blossom · young=thêm nhánh + nhiều blossom · green=cành đầy + lá điểm · bloom=nở rộ, cánh rơi nhiều.
- **GIỮ NGUYÊN**: milestone math, stage thresholds, tap hoa (#1) + MomentSheet, sky theo giờ + mùa (#2, mùa sakura nghiêng hồng/xuân), thẻ Khoe cây (#3, vẽ cành), coach mark + caption, deep-link, Reduce-Motion matrix. `_bloomPositions`/`canopyGeometry` được THAY bằng anchor-dọc-cành nhưng phải **deterministic per-index** (không nhảy mỗi vẽ).
- ⚠️ Vẫn 100% CustomPaint (không asset/dependency mới); tầng renderer giữ để v3 thay illustration/Lottie thật.

## Acceptance (PO)
1. Nhìn ra ngay là **cành hoa anh đào đẹp/thanh thoát**, hợp tông hồng — KHÔNG còn blob xanh clip-art.
2. Blossom đính gọn dọc cành, không lơ lửng/clip ra ngoài; số blossom = số mốc.
3. Bấm blossom → MomentSheet đúng (no-regression #1); sky/mùa/Khoe cây/coach/deep-link vẫn chạy (#2/#3).
4. 5 stage phân biệt được (cành trơ → nở rộ).
5. Reduce Motion ON: tĩnh đẹp. `fvm flutter analyze` sạch. Copy đủ vi+en (tái dùng key cũ; thêm nếu cần).

## Trạng thái
- [2026-06-14] v1 DONE (code-level, analyze 0 issue, Tester 12/12 PASS). Chờ user smoke-test runtime (animation/visual R1-R6).
- [2026-06-18] v2 PO spec chốt (#1+#2+#3) → Designer→Dev→Tester PASS code-level (8 AC + 8 rủi ro). Chờ smoke-test runtime.
- [2026-06-18] v2.1 PO spec chốt (A nâng cấp CustomPaint + B coach mark) → Designer DONE → Dev DONE (analyze 0, service additive-only milestone math intact, `LoveTreeRenderer` tách layer, `_lighten`, coach mark 1-lần + caption, l10n 54=54). **PO gate PASS code-level (Lead tự verify).** ⚠️ Dev refactor `_bloomPositions`→`bloomPositions(stage,…)` neo theo `canopyGeometry` (đúng hướng nhưng đổi layout) → **smoke-test runtime BẮT BUỘC: hoa nằm gọn trong tán mọi stage**. Chưa có Tester subagent độc lập (session limit) — cần smoke-test thiết bị (visual cây/hoa mới + coach 1-lần + Reduce Motion + no-regression #1/#2/#3).
- [2026-06-18] v2 Designer DONE — design spec đầy đủ ở `design.md` §"Design Spec v2" (sheet "Khoảnh khắc này" 4 biến thể + cây sống động 4 trời/4 mùa/hạt động + Reduce Motion matrix + thẻ "Khoe cây" 4:5 + ~20 key l10n vi/en + AC). → Dev. 1 câu hỏi mở cho Dev: router có field `pendingPhotoId` cho deep-link ảnh không (không có vẫn đạt AC — chỉ mở tab Gallery).
- [2026-06-18] v2.1 Designer DONE — design spec đầy đủ ở `design.md` §"Design Spec v2.1". (A) Nâng cấp CustomPaint: thân/cành bézier cong thuôn + gradient khối, tán 3 lớp back/mid/front (mid GIỮ `canopyGeometry` → hoa KHÔNG lệch), lá 3-stop, seed/sprout đẹp hơn; hoa 6 cánh 2 lớp + tâm sáng + nhuỵ highlight/viền-trong/bóng (GIỮ nucleusD + icon kind). Đề xuất ranh giới `LoveTreeRenderer` (paintTree + flowerWidget, contract neo canopy/hộp diameter) cho v3 drop SVG/Lottie. (B) Coach mark 1-lần/cặp (Hive `love_tree_coach_<coupleId>`): ripple + tap-dot + tooltip navy trỏ bông gần đỉnh tán, ẩn khi chạm/4s, Reduce-Motion → tĩnh; caption thường trực "Chạm vào mỗi bông…" khi ≥1 hoa. 2 key l10n mới (`loveTreeCoachTooltip`/`loveTreeTapHint`) + 10 AC + Dev notes giữ-logic. → Dev. Câu hỏi nhỏ cho Dev (không blocker): `iconsax_plus` có icon ngón tay đẹp không — không có thì dùng "tap-dot" (đã có phương án).
