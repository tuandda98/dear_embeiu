# 🗺️ Roadmap riêng — Hôm nay ăn gì?

> Kế hoạch chi tiết NỘI BỘ feature này. PO sở hữu.

- **Trạng thái feature:** 📋 Spec (2026-10-19) — chờ user duyệt

## Phân phase

### 🟢 Phase 1 — Quay · đề xuất · chốt · lịch sử · nhắc (P0)
- [ ] Designer: thẻ Home 3 trạng thái, 2 sheet, màn lịch sử, tile nhắc
- [ ] Dev: dish bank + suggester, service/provider, UI, rules + 2 CF, nhắc band 1200, analytics, l10n
- [ ] Tester: 14 tiêu chí `overview.md` §5
- *Xong khi:* 14 tiêu chí PASS, DEV deployed, ship trong 1.11.0 cùng widget-today.

### 🟡 Phase 2 — Sau 30 ngày số liệu
- [ ] "Lâu rồi chưa ăn" (món từng chốt ≥14 ngày trước) trong vòng quay
- [ ] Tách trưa/tối rõ nếu số liệu cho thấy nhiều cặp chốt 2 lần/ngày
- [ ] Pref tắt push `meal_*` riêng (map `PUSH_TYPE_PREF_FIELD`)
- [ ] Gắn ảnh với bữa (tag `mealDate` trên photo) → lịch sử có ảnh

### ⚪ Later
- [ ] Địa điểm/quán quen, bản đồ · AI gợi ý theo thời tiết/tủ lạnh · kế hoạch tuần · ngân sách

## Ghi chú phụ thuộc
- Loại trạng thái `meal` trên widget ở [widget-today](../widget-today/overview.md); push `notifyMealChosen` phải có `wakeClients`.
- PROD: rules phải deploy trước khi 1.11.0 live; 2 CF deploy đích danh (lệnh ở `overview.md` W13), chờ lệnh user.
