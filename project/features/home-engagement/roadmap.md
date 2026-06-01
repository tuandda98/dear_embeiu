# 🗺️ Roadmap riêng — Home engagement

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu.

- **Trạng thái feature:** 🧪 Test PASS (code-level, Phase 1) — chờ user smoke-test thiết bị

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — Đẩy đăng ảnh từ Home (P0) — 🧪 Test PASS, chờ smoke-test
- [x] CTA chính rose "Thêm kỷ niệm" thay cụm 2 quick-action (bỏ card "Cập nhật thông tin→Profile" trùng nav)
- [x] Nút "Đăng ảnh đầu tiên" ở empty-state recent photos
- [x] Tái dùng luồng add photo (`_pickAndAddPhoto` + `PhotoProvider.addPhoto`); ở lại Home (HE4); loading disable
- [x] Giữ lối vào Gallery (link "Xem tất cả ảnh"); +2 key l10n; analyze sạch
- *Xong khi:* user smoke-test runtime (đăng ảnh CTA & empty-state, loading, waiting_partner, recent cập nhật) OK → ✅ Done
- *Nợ:* code trùng `_pickAndAddPhoto` Home vs Gallery (chấp nhận Phase 1 — có thể trích helper chung sau)

### 🟡 Phase 2 — Tín hiệu partner + retention hooks (P0/P1)
- [ ] Card "💞 [Tên] vừa thêm ảnh mới" + badge chưa-xem trên recent (cần lưu last-seen timestamp)
- [ ] Day streak (l10n `dayStreakLabel/Value` đã stub) — đếm chuỗi ngày mở app/đăng ảnh
- [ ] Chạm ảnh recent → mở đúng ảnh đó trong Gallery fullscreen (cross-tab coordination)

### ⚪ Phase 3 (Later) — Nội dung tạo lý do quay lại
- [ ] Daily question / "ngày này năm xưa" / xoay quote
- [ ] Reactions ❤️ trên ảnh (tận dụng push)
- [ ] Đổi icon tim góc phải Home cho đúng nghĩa

## Mốc đã đạt
- [2026-06-01] Phase 1 review PO → Spec → Design → Dev → Test PASS code-level (PO orchestrate).

## Ghi chú phụ thuộc
- Tái dùng feature [gallery](../gallery/overview.md) (luồng add photo, PhotoProvider) — không đổi backend.
- Phase 2 partner-signal + streak cần thêm state (last-seen / streak count) — iteration riêng.
- Đo hiệu quả cần feature analytics (chưa có) — hiện đánh giá định tính.
