# 🗺️ Roadmap riêng — Counter

> Kế hoạch nội bộ feature. Toàn cảnh: [`../../ROADMAP.md`](../../ROADMAP.md). Spec: [overview.md](overview.md).

- **Trạng thái feature:** ✅ Shipped (v1.0.0) — phụ thuộc fix i18n

## Phân phase

### 🟢 Phase 1 — Đúng số & ngôn ngữ (P0) — chưa bắt đầu
- [ ] Ngày hiển thị locale-aware (chung **Gap A** của [language](../language/roadmap.md))
- [ ] Xử lý anniversary = hôm nay / tương lai rõ ràng (không im lặng)
- *Xong khi:* Tester pass case 2/3/6.

### 🟡 Phase 2 — Chính xác lịch (P1) — chưa bắt đầu
- [ ] Rà sai số mốc do months≈30 ngày (cân nhắc tính theo lịch thực)
- [ ] Xử lý múi giờ / năm nhuận
- *Xong khi:* Tester pass case 4/5/8.

### ⚪ Phase 3 (Later)
- [ ] Cho user chọn cách hiển thị (ngày / tuần / "X năm Y tháng")
- [ ] Hiệu ứng ăn mừng khi chạm milestone (confetti)

## Mốc đã đạt
- [v1.0.0] Đếm ngày/tháng/năm + milestone progress + love quote.

## Ghi chú phụ thuộc
- Phase 1 gắn chặt với feature **language** (Gap A).
