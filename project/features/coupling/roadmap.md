# 🗺️ Roadmap riêng — Coupling

> Kế hoạch nội bộ feature. Toàn cảnh: [`../../ROADMAP.md`](../../ROADMAP.md). Spec: [overview.md](overview.md).

- **Trạng thái feature:** ✅ Shipped (v1.0.0) — còn lỗ hổng bảo mật P0

## Phân phase

### 🟢 Phase 1 — Vá bảo mật rules (P0) — chưa bắt đầu — ⚠️ trước release
- [ ] Siết rules `invite_codes`: chặn liệt kê toàn bộ (enumeration) 🔴
- [ ] Khoá sửa `invite_codes.coupleId` (chống hijack) 🔴
- [ ] Chặn non-member đọc couple `waiting_partner` (rules `couples` ~349-351)
- *Xong khi:* Tester pass case security 6/7/8.

### 🟡 Phase 2 — Bền state machine (P1) — chưa bắt đầu
- [ ] Xử lý leave-khi-partner-join / cả 2 cùng leave (không state lạ, không ảnh orphan)
- [ ] Validate person1 != person2; check độ dài invite trước lookup
- *Xong khi:* Tester pass case edge 3/5/9.

### ⚪ Phase 3 — Giảm ma sát mời (P2, gắn phễu) — chưa bắt đầu
- [ ] Share sheet / sao chép nhanh / **QR code** cho mã mời
- [ ] (Liên kết feature onboarding khi tạo)

## Mốc đã đạt
- [v1.0.0] Tạo/join (transaction)/leave couple qua mã mời 6 ký tự.

## Ghi chú phụ thuộc
- Phase 1 **bắt buộc trước release** (lỗ hổng P0).
- Phase 3 liên quan feature **onboarding** (backlog).
