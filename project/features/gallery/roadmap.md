# 🗺️ Roadmap riêng — Gallery

> Kế hoạch nội bộ feature. Toàn cảnh: [`../../ROADMAP.md`](../../ROADMAP.md). Spec: [overview.md](overview.md).

- **Trạng thái feature:** ✅ Shipped (v1.0.0) — phụ thuộc fix i18n + có nợ bảo mật

## Phân phase

### 🟢 Phase 1 — i18n + bảo mật ảnh (P0/P1) — chưa bắt đầu
- [ ] Push đa ngôn ngữ (chung **Gap B** của [language](../language/roadmap.md)) 🔴
- [ ] Ngày feed locale-aware (**Gap A**)
- [ ] Rules: chỉ author được xoá ảnh của mình (hoặc cả 2 đồng ý)
- [ ] Re-validate ảnh thực (magic bytes) thay vì tin contentType client
- *Xong khi:* Tester pass case 7/8/11/12.

### 🟡 Phase 2 — Bền sync/offline (P1) — chưa bắt đầu
- [ ] Re-upload ảnh offline khi online lại; check `existsSync` cache path
- [ ] Rollback optimistic khi server fail (delete/caption)
- [ ] Giới hạn size/số ảnh batch + giới hạn ký tự caption
- [ ] Xoá dead code `MasonryGallery`
- *Xong khi:* Tester pass case 4/5/6/10.

### ⚪ Phase 3 — Tăng tương tác (P2, retention) — chưa bắt đầu
- [ ] **Reactions ❤️ trên ảnh** (tận dụng push) — *tách feature riêng nếu lớn*
- [ ] Empty state đẹp; trạng thái "chưa đồng bộ" rõ
- [ ] (Later) comments, albums, filter/edit, photobook/export

## Mốc đã đạt
- [v1.0.0] Feed realtime, đăng đơn/nhiều, caption, xoá, fullscreen viewer, push partner-photo.

## Ghi chú phụ thuộc
- Phase 1 chia sẻ Gap A/B với feature **language**.
- Reactions có thể tách thành feature `photo-reactions` (backlog NOW).
