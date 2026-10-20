# 🗺️ Roadmap riêng — Chọn giúp chúng mình (decision-wheel)

> Kế hoạch chi tiết NỘI BỘ feature này. PO sở hữu.

- **Trạng thái feature:** 📋 Spec (2026-10-19) — chờ user duyệt

## Phân phase

### 🟢 Phase 1 — Ăn gì · Đi đâu · Tự nhập · lịch sử · nhắc (P0)
- [ ] Designer: thẻ Home 3 dòng, màn quay 3 chế độ, sheet kết quả, màn lịch sử, tile nhắc
- [ ] Dev: 2 ngân hàng + `DecisionSuggester`, service/provider, UI, rules + CF `notifyDecision`, nhắc band 1200, analytics, l10n
- [ ] Tester: 14 tiêu chí `overview.md` §5
- *Xong khi:* 14 tiêu chí PASS, DEV deployed, ship trong 1.11.0 cùng widget-today.

### 🟡 Phase 2 — Sau 30 ngày số liệu
- [ ] "Lâu rồi chưa ăn / chưa đi" trong pool (mục từng chốt ≥14 ngày trước)
- [ ] Tag mùa/thời tiết thô cho ngân hàng đi đâu (mùa đông miền Bắc bỏ biển)
- [ ] Pref tắt push `decision` riêng (map `PUSH_TYPE_PREF_FIELD`)
- [ ] Veto 1 lần: người ấy bấm "Quay lại" tối đa 1 lần rồi khoá (nếu thấy cặp quay qua quay lại)
- [ ] Gắn ảnh với quyết định (tag trên photo) → lịch sử có ảnh

### ⚪ Later
- [ ] Quán cụ thể gần đây (bản đồ) · AI gợi ý theo lịch sử/thời tiết · kế hoạch tuần · ngân sách · tách trưa/tối

## Ghi chú phụ thuộc
- Widget hiện kết quả eat/go/custom: [widget-today](../widget-today/overview.md) D2 (loại `decision_*`); push `notifyDecision` phải có `wakeClients`.
- PROD: rules trước khi 1.11.0 live; CF deploy đích danh (lệnh ở `overview.md` D14), chờ lệnh user.
