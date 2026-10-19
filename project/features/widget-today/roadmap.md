# 🗺️ Roadmap riêng — Widget "Hôm nay"

> Kế hoạch chi tiết NỘI BỘ feature này. PO sở hữu.

- **Trạng thái feature:** 📋 Spec (2026-10-19) — chờ user duyệt

## Phân phase

### 🟢 Phase 1 — Dòng trạng thái 7 loại + cập nhật nền (P0)
- [ ] Designer: vị trí/kiểu chữ trên 4 bố cục, tinted, AX, chuỗi dài nhất
- [ ] Dev: `HomeWidgetStatus` + bridge + handler nền + native 2 nền tảng + chạm đúng tab + CF `wakeClients` + `data.lang`
- [ ] Tester: 11 tiêu chí `overview.md` §5, đo thời gian push → widget
- *Xong khi:* 11 tiêu chí PASS, CF DEV deployed, ship trong 1.11.0 cùng what-to-eat.

### 🟡 Phase 2 — Sau khi có số liệu 30 ngày
- [ ] Ngưỡng đánh thức cho chat nếu log `messaging` cho thấy iOS bỏ push nền
- [ ] Màn khoá iPhone hiện cùng câu trạng thái (gộp với Phase 2 home-widget)
- [ ] Trạng thái `care_message` (chỉ "có lời quan tâm mới", không nội dung) nếu user muốn

## Ghi chú phụ thuộc
- Loại `meal` cần [what-to-eat](../what-to-eat/overview.md) ship cùng bản; nếu what-to-eat trễ thì bỏ loại này khỏi bản đầu, không chặn.
- PROD deploy 4–6 CF đích danh khi phát hành (lệnh ở `overview.md` D11), chờ lệnh user.
