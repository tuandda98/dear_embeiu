# 🗺️ Roadmap riêng — Quỹ chung (expenses)

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu; cập nhật khi phạm vi đổi. Quyết định và lý do ở [overview.md](overview.md) §4.

- **Trạng thái feature:** 📋 Spec

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — Sổ chung dùng hằng ngày (P1) — 📋 Spec
Đi cùng đợt "mở app mỗi ngày" lần 2. Đủ để "ăn xong mở app ghi" và cuối tháng biết tiêu gì, ai ứng nhiều hơn.
- [ ] Ghi khoản chi: ô số + chip 50k/100k/200k/500k + gõ tắt ("50k", "1tr2", "1 củ"), 8 danh mục + tự thêm (≤20), ghi chú, ngày, ai trả (mình / người ấy / quỹ), 4 cách chia, "Chỉ mình thấy" (D5, D7–D9)
- [ ] Sổ tháng: danh sách theo ngày, tổng, theo danh mục, theo người trả, so tháng trước
- [ ] Ngân sách tháng (một con số tổng) + cảnh báo 80%/100% trong app + push người kia (D10)
- [ ] Cân bằng "ai đang ứng nhiều hơn" + đánh dấu đã thanh toán (kể cả trả một phần)
- [ ] Quỹ mục tiêu ≤5 quỹ mở: góp, chi từ quỹ, tiến độ, đạt 100%, đóng quỹ
- [ ] Sổ một người cho cặp đang chờ (D3)
- [ ] Sửa/xoá cả hai, "ai sửa", hoàn tác xoá 5 giây (D4)
- [ ] Nút "Ghi chi" ở sheet decision-wheel (D14)
- [ ] Nhắc tối opt-in band 1210–1211 (D12)
- [ ] Rules additive + index + CF `notifyExpense` + dọn khi rời/xoá (D6, D13)
- [ ] Analytics không lộ số tiền (D18) · vi + en
- [ ] Khai báo store "Thông tin tài chính khác" + privacy policy (D21, chờ user)
- *Xong khi:* 18 tiêu chí `overview.md` §6 PASS trên 2 máy DEV; rules test PASS; PO verify.

### 🟡 Phase 2 — Cho cặp sống chung & dùng lâu — chờ số liệu Phase 1
Làm khi ≥10 cặp dùng sổ ≥3 ngày/tuần, hoặc có phàn nàn cụ thể.
- [ ] Khoản định kỳ (tiền nhà, điện nước, Netflix): tự tạo khoản mỗi tháng + nhắc trước hạn
- [ ] Ngân sách theo danh mục
- [ ] Chuyển khoản ghi lúc đang chờ sang sổ chung (hỏi 1 lần khi người ấy vào)
- [ ] "Sổ cũ": xem khoản với người ấy cũ sau khi rời couple
- [ ] Lịch sử sửa từng lần (ai đổi gì, lúc nào) nếu có tranh cãi do sửa
- [ ] Xuất CSV (chia sẻ qua share sheet)
- [ ] CF giữ số tổng cân bằng trong `expenseMeta` khi sổ dài (nợ §8)
- [ ] Pref tắt push ngân sách/quỹ riêng (`PUSH_TYPE_PREF_FIELD`)
- [ ] Tag quỹ vào dịp: chi trong chuyến đi tự gắn quỹ (kiểu "Sự kiện" của Money Lover)

### ⚪ Phase 3 (Later) — Mở rộng — ý tưởng
- [ ] Thu nhập (tuỳ chọn, mặc định ẩn — nhạy cảm với cặp chưa cưới)
- [ ] Đa tiền tệ cho cặp yêu xa (field `currency` đã chừa sẵn)
- [ ] Ảnh hoá đơn đính kèm khoản
- [ ] Recap tháng dạng thẻ chia sẻ ("Tháng 10 chúng mình ăn 23 bữa ngoài")
- [ ] Ứng viên premium khi có monetization: báo cáo năm, xuất file, quỹ không giới hạn (KHÔNG gate ghi chép cơ bản hay dữ liệu cũ — CLAUDE.md §10)
- Không làm: liên kết ngân hàng, quét hoá đơn, vay nợ, nhiều ví, đầu tư (D20)

## Mốc đã đạt
- [2026-10-20] Spec PO Phase 1 xong, chờ user duyệt 3 câu hỏi (`overview.md` §11).

## Ghi chú phụ thuộc
- decision-wheel (1.11.0) phải có trên nhánh trước khi làm D14.
- Cùng đợt với poke, caro-game, weather, arrival: chung `functions/index.js`, `firestore.rules`, `firestore.indexes.json`, ARB, `session_resolver`, `NotificationTapRouter` → Lead xếp thứ tự merge; band thông báo local đối chiếu cả đợt.
- Khai báo store + privacy policy (D21) phải xong trước khi gửi duyệt.
