# Home engagement — Đẩy đăng ảnh từ Home (Phase 1)

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** home-engagement
- **Ưu tiên:** P0 (đòn bẩy trực tiếp Metric Bắc Đẩu: "cặp active đăng ảnh hằng tuần" — CLAUDE.md mục 11)
- **Trạng thái:** 🧪 Test PASS (code-level) — chờ user smoke-test thiết bị (Phase 1)
- **Tạo ngày:** 2026-06-01
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · feature [gallery](../gallery/overview.md) (tái dùng luồng add photo) · [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 8,10,11

## 1. Vấn đề & giá trị
- *Vấn đề:* Home hiện là **bảng trạng thái để ngắm**, không có cú hích kéo user **đăng ảnh** — trong khi đăng ảnh chính là Metric Bắc Đẩu. 2 quick-action ("Xem ảnh"→Gallery, "Cập nhật thông tin"→Profile, `home_screen.dart:519–536`) **trùng bottom nav**, giá trị thấp. Empty-state ảnh (`:996–1031`) thụ động, **không có nút đăng**.
- *Giả thuyết giá trị:* Thêm **CTA "Thêm kỷ niệm" nổi bật ở Home** + **nút đăng ảnh ở empty-state** → tăng tỉ lệ đăng ảnh (đặc biệt ảnh đầu = mốc kích hoạt) → tăng "cặp active đăng ảnh hằng tuần".
- *Đối tượng:* couple đã ghép (Home luôn có couple).
- *Đo bằng:* tỉ lệ couple đăng ≥1 ảnh; thời gian tới ảnh đầu (chờ feature analytics — hiện chỉ định tính).

## 2. Bối cảnh
- Đối thủ (Between, SumOne…) đặt hành động tạo nội dung ngay trên màn chính. Home của ta thiếu điểm này (review PO 2026-06-01).
- Luồng add photo đã có: `gallery_screen._pickAndAddPhoto()` → `ImagePicker().pickImage()` → `context.read<PhotoProvider>().addPhoto(...)`. `PhotoProvider` là top-level provider → **Home gọi trực tiếp được**, không cần qua Gallery.

## 3. Phạm vi (scope) — Phase 1
- **Trong:**
  - **CTA chính "Thêm kỷ niệm"** ở Home (thay quick-action "Cập nhật thông tin→Profile" trùng nav) → mở thẳng luồng đăng ảnh (picker + `PhotoProvider.addPhoto`), KHÔNG chỉ nhảy tab.
  - **Empty-state ảnh** (`_buildRecentPhotosSection` khi rỗng): thêm **nút "Đăng ảnh đầu tiên"** → cùng luồng đăng ảnh.
  - Tái dùng tối đa l10n có sẵn (`postNewPhotoBtn`, `postFirstPhotoBtn`); chỉ thêm key mới nếu cần.
- **Ngoài (Phase 2 — ghi roadmap):**
  - Tín hiệu "partner vừa đăng ảnh" + badge chưa-xem.
  - Day streak (l10n đã stub `dayStreakLabel/Value`).
  - Chạm ảnh recent → mở đúng ảnh đó (cross-tab — `:1042` hiện chỉ nhảy tab).
  - Daily question / on-this-day / xoay quote.
  - KHÔNG đổi backend/model/rules/Cloud Function.

## 4. Quyết định đã chốt (decision log)
- **HE1 — Scope hẹp, ship sạch:** chỉ làm "đẩy đăng ảnh" (CTA + empty-state) Phase 1. Hoãn partner-signal/streak/tap-fix/daily-q sang Phase 2. *Lý do:* tránh grab-bag, verify được, đòn bẩy North-Star rõ nhất.
- **HE2 — Tái dùng luồng add photo sẵn có** (`ImagePicker` + `PhotoProvider.addPhoto`), KHÔNG dựng luồng mới, KHÔNG đổi backend. CTA gọi trực tiếp provider (không bắt buộc nhảy sang Gallery).
- **HE3 — Giữ lối vào Gallery** (đừng bỏ hẳn khả năng xem ảnh từ Home); Designer chọn layout gọn (vd 1 CTA chính "Thêm kỷ niệm" + 1 link phụ "Xem tất cả").
- **HE4 — Sau đăng ảnh: ở lại Home** + xác nhận (snackbar) + recent photos tự cập nhật qua stream (không ép nhảy tab).

## 5. Acceptance criteria (Phase 1)
- [ ] Home có **CTA "Thêm kỷ niệm" nổi bật** (không còn quick-action "Cập nhật thông tin→Profile" trùng nav).
- [ ] Tap CTA → mở picker → chọn ảnh → đăng qua `PhotoProvider.addPhoto` → ảnh xuất hiện ở recent photos (stream), có xác nhận.
- [ ] **Empty-state ảnh có nút đăng** → cùng luồng, đăng được ảnh đầu.
- [ ] Vẫn vào được Gallery từ Home (link/nút phụ).
- [ ] i18n vi+en đủ (tái dùng key sẵn có ưu tiên); không hardcode.
- [ ] `flutter analyze` sạch; bám design system (CTA rose, token sẵn có, không bịa token mới).
- [ ] KHÔNG regression: counter/milestone/quote/hero/banner chờ partner/nav vẫn nguyên; luồng add photo ở Gallery không đổi.

## 6. Nợ kỹ thuật / rủi ro (Tester soi)
- 🟡 `addPhoto` cần coupleId hợp lệ — Home luôn có couple, nhưng verify khi couple `waiting_partner` (1 người) vẫn đăng được (chính chủ).
- 🟡 Trạng thái loading khi đang upload (CTA disable lúc `PhotoProvider.isLoading` như Gallery) — tránh double-pick.
- 🟡 Hủy picker (không chọn ảnh) → không crash, không toast lỗi.
- 🟡 Nhánh Firebase vs local fallback — addPhoto chạy đúng cả 2 (tái dùng nên kế thừa hành vi Gallery).

## 7. Giao việc 3 vai
- 🎨 **Designer:** layout CTA "Thêm kỷ niệm" ở Home (thay/sắp lại cụm quick-action, giữ lối vào Gallery) + nút đăng ở empty-state; token bám design system (rose primary); copy (ưu tiên key sẵn có); states (idle/loading/empty). → `design.md`.
- 💻 **Dev:** gắn CTA + empty-state button, gọi luồng add photo sẵn có (`ImagePicker`+`PhotoProvider.addPhoto`, tái dùng pattern `_pickAndAddPhoto`); disable khi loading; l10n; analyze sạch; không đổi backend; không regression. → `dev.md`.
- 🧪 **Tester:** verify CTA + empty-state đăng được ảnh (cả waiting_partner & active), loading/hủy/lỗi, recent cập nhật, vào Gallery vẫn được, không regression Home/Gallery. → `test.md`.

## 8. Changelog
- [2026-06-01] [PO] Tạo từ review PO Home Screen. Chốt scope hẹp (HE1): Phase 1 = đẩy đăng ảnh (CTA "Thêm kỷ niệm" + empty-state button), tái dùng luồng add photo (HE2). Hoãn partner-signal/streak/tap-fix/daily-q sang Phase 2. Khởi động pipeline.
- [2026-06-01] [PO] Pipeline Phase 1 xong: Designer (CTA rose full-width thay 2 quick-action + nút empty-state) → Dev (`_buildAddMemoryCta` + copy `_pickAndAddPhoto` vào Home, xoá `_buildQuickActionCard`, +2 key `addMemoryCta`/`addMemoryCtaSubtitle` qua ARB+gen-l10n, loading=disable+Opacity) → Tester PASS code-level 17/17, 0 bug. **PO sửa note l10n stale trong design.md** (hand-maintained → ARB+gen-l10n). PO verify: `fvm flutter analyze`="No issues found!"; gallery diff TRỐNG (không regression); scope chỉ home_screen+l10n. Giữ 🧪 Test PASS, **chờ user smoke-test runtime** (đăng ảnh từ CTA & empty-state, loading disable, hủy picker, waiting_partner, recent cập nhật, vào Gallery, toggle vi/en). Nợ kỹ thuật chấp nhận: code trùng `_pickAndAddPhoto` Home vs Gallery (tránh refactor Phase 1). Chưa commit/deploy.
