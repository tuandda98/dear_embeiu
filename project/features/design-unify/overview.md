# Design Unify — đồng bộ toàn app theo ngôn ngữ Home v2

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.

- **Feature:** design-unify
- **Ưu tiên:** P0
- **Trạng thái:** 🧪 Test PASS code-level — chờ user smoke-test thiết bị (7 mục runtime trong test.md)
- **Tạo ngày:** 2026-06-11
- **Liên quan:** [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · [`../../design-system.md`](../../design-system.md) · Home v2 [`../home/design.md`](../home/design.md)

## 1. Vấn đề & giá trị
- *Vấn đề người dùng:* Home v2 (2026-06-10) đã có ngôn ngữ thiết kế mới (calendar leaf header, bell disc, card trắng đặc r24 cho nội dung, aurora counter, pill input, InkWell ripple, bóng tối mềm thay halo trắng…) nhưng các màn còn lại (auth, setup, gallery, profile, settings, reminders, journal, notification center…) vẫn theo ngôn ngữ cũ → app cảm giác chắp vá, thiếu chuyên nghiệp.
- *Giả thuyết giá trị:* đồng nhất 100% ngôn ngữ Home → cảm nhận chất lượng tăng → retention/review tốt hơn.
- *Đối tượng:* toàn bộ user.
- *Đo bằng gì:* định tính — mọi màn soi theo checklist token Home đều khớp; `fvm flutter analyze` sạch.

## 2. Bối cảnh
- User yêu cầu (2026-06-11, kèm screenshot Home): "system design lại cho toàn app, dựa trên màn hình Home, tất cả phải đồng nhất và thống nhất, re-check rồi apply all".
- Màn Home = nguồn chuẩn DUY NHẤT. Mâu thuẫn giữa design-system.md cũ và Home hiện tại → Home thắng.

## 3. Phạm vi (scope)
- **Trong phạm vi:** token sheet chuẩn hoá từ Home; trích primitives dùng chung; apply UI cho TẤT CẢ screens ngoài Home (login/register/forgot/verify/guest/setup/gallery/journal/love-note-history/milestone/custom-reminders×2/notification-center/profile/settings) + widgets liên quan; cập nhật `project/design-system.md`.
- **Ngoài phạm vi:** đổi behavior/logic/navigation/Firebase; dark mode; đổi font/màu brand; đổi copy l10n trừ khi bắt buộc (nếu thêm key → sửa CẢ 2 ARB + gen-l10n).

## 4. Quyết định đã chốt (decision log)
- **D1 — Home là chuẩn:** mọi màn theo Home v2; design-system.md được cập nhật lại theo Home, không ngược lại. *Lý do:* yêu cầu trực tiếp của user.
- **D2 — Không đổi behavior:** chỉ UI (layout/màu/typo/motion). *Lý do:* 1.1.x đang chuẩn bị submit, giảm rủi ro regression.
- **D3 — Tôn trọng decision log cũ:** Quicksand toàn app, Lucide icons, light-mode only, luật Reduce Motion, luật chữ-trắng-bóng-tối, contrast pass S1/C1. Không thêm package mới.

## 5. Acceptance criteria (xong khi…)
1. ✅ `project/features/design-unify/design.md` có token sheet + spec từng màn (Designer, 2026-06-11).
2. ✅ Mọi screen ngoài Home được apply theo spec; 9 primitives trích ra `lib/widgets/` (B1 `ScreenBackground` chưa có consumer — nợ ghi dev.md).
3. ✅ `fvm flutter analyze` 0 issue (+ `fvm flutter test` 18/18).
4. ✅ Tester PASS code-level (test.md) — mục contrast/motion runtime chờ smoke-test thiết bị.
5. ✅ `project/design-system.md` cập nhật bản chuẩn mới (section "Design Unify 2026-06-11" đầu file).

## 6. Nhật ký
- [2026-06-11] [po] Tạo feature, chốt scope D1–D3, bật pipeline Mode 1 (Designer→Dev→Tester).
- [2026-06-11] [po] Phân xử nguồn chuẩn: screenshot user chụp bản Home cũ hơn trong ngày; code trên đĩa (greeting header + bell squircle, "redesign user 2026-06-11") là bản mới nhất user đã đổi → spec theo CODE (luật đĩa-là-sự-thật). PO gate spec PASS (4/4 spot-check khớp đĩa).
- [2026-06-11] [po] **Header-sync vòng 2** (user re-check: "màn còn chip, màn không có, Settings màu khác"): chốt 1 hệ header duy nhất — chữ trắng + bóng tối toàn app, bỏ hộp chip eyebrow 8 màn, title màn con trắng (sửa 1 chỗ subScreenAppBar), NotifCenter về pattern 1 hàng, action app-bar trắng. Analyze 0 issue. Spec ghi đè ở design.md mục "BỔ SUNG vòng 2".
- [2026-06-11] [po] **Type-scale vòng 3** (user hỏi "cỡ chữ/màu chữ/button đồng bộ chưa?"): audit → màu chữ + button đã kỷ luật từ vòng 1-2; cỡ chữ còn 49 chỗ lẻ (9.5/11.5/12.5/13.5/14.5/15.6/16.5/17/20.5/24…) ở 12 file → Dev chuẩn hoá hết về scale 10/11/12/13/14/15/16/18/20/21/22/26/30/32 + display. Scale chính thức ghi vào design-system.md. Analyze 0 issue.
- [2026-06-11] [po] **Vòng 4 — header ink navy** (user gửi 4 screenshot thật, duyệt "tự quyết tự làm"): mực header trắng→navy toàn app (trắng fail ~1.7:1 trên blush — đúng luật chữ-nhỏ có sẵn trong design-system mà vòng 2 đã bỏ qua); phụ kiện gradient về bề-mặt-sáng (language pill, sign-out, month chip, invite card→ContentCard); fix 2 lỗi copy lặp (editCoupleBadge, invite description) + sentence-case galleryTitle. ARB en+vi+gen-l10n. Analyze 0 issue. Chữ trắng chỉ còn trên scrim tối/ảnh.
- [2026-06-11] [po+dev] **Vòng 5 — EyebrowChip trở lại** (user yêu cầu sau khi xem text trần): primitive B12 `eyebrow_chip.dart` (pill white .72 + viền + shadow rose + icon loveDeep + label navy .70) áp 8 màn với icon khôi phục theo bản cũ. Lead tự code (việc khoanh vùng). Analyze 0 issue.
- [2026-06-11] [po+dev] **Vòng 5b+5c — header lớn kiểu landing cho MỌI màn con + chốt RULE screen mới:** Settings (5b) rồi 6 màn còn lại (5c: notif-center/journal/history/milestone/custom×2) — `subScreenAppBar` không title + EyebrowChip + pageTitle + subtitle (form không subtitle); +12 key ARB vi/en; biến thể title-18-giữa còn 0 consumer. Rule ghi vào design-system.md (🔒 RULE MỌI SCREEN) + CLAUDE.md mục 8. Analyze 0 issue.
- [2026-06-11] [po] Pipeline xong: Stage A (primitives+theme+Reduce Motion+Home refactor) → Stage B 4 nhóm dev song song (15 màn) → Tester PASS-có-điều-kiện → Lead-Dev vá finding #5 (cinema timer-reset) + D3 milestone → đóng AC5 (design-system.md). Analyze 0 issue, test 18/18. Chờ user smoke-test 7 mục runtime (test.md).
