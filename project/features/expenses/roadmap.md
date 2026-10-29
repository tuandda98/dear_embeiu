# 🗺️ Roadmap riêng — Sổ tiền (expenses)

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu; cập nhật khi phạm vi đổi. Quyết định và lý do ở [overview.md](overview.md) §4.

- **Trạng thái feature:** 📋 Spec — chờ user chọn tên (overview §11)

Mỗi mốc là một bản phát hành MINOR riêng. Mốc A tự đứng được: dùng thay Money Lover cho tiền của mình, cộng sổ chung cho cặp đã ghép.

## Phân phase (Now / Next / Later)

### 🟢 Mốc A — Dùng thay Money Lover được (P1) — 📋 Spec
- [ ] Hai sổ: "Của mình" (`users/{uid}`) + "Chung" (`couples/{id}`, chỉ khi active); cặp đang chờ dùng trọn sổ riêng (D1–D5)
- [ ] Ví 5 loại (tiền mặt, ngân hàng, ví điện tử, thẻ tín dụng, mục tiêu), số dư đầu kỳ, số dư tính từ giao dịch, lưu trữ, "không tính vào tổng"; onboarding ví 1 màn (D6, D8)
- [ ] Giao dịch Chi / Thu / Chuyển / Điều chỉnh; ô số nhanh + gõ tắt "50k", "1 củ" (D10)
- [ ] Danh mục 2 cấp thu–chi, thêm/sửa/ẩn mỗi sổ (D9)
- [ ] Ngân sách tháng tổng + theo danh mục, cảnh báo 80/100% trong app
- [ ] Báo cáo: thu–chi–còn lại, cơ cấu, xu hướng 6/12 tháng, theo ví, theo người (D19)
- [ ] Tìm kiếm + lọc (ngày, danh mục, ví, người, khoảng tiền, ghi chú không dấu)
- [ ] Mục tiêu tiết kiệm = ví Mục tiêu ("Quỹ Đà Lạt")
- [ ] Sổ chung: ai trả, 4 cách chia, cân bằng, thanh toán, góp từ ví riêng, "trừ vào ví của mình" (D11–D13)
- [ ] Nút "Ghi chi" ở decision-wheel (D20) · nhắc tối opt-in 1210–1211 (D18)
- [ ] Rules additive + index + CF `notifyMoney` (chỉ %, không số tiền) + dọn trong `deleteAccount`/`deleteCoupleCompletely` (D4, §5)
- [ ] Analytics không lộ tiền (D27) · vi + en
- [ ] Khai báo store "Thông tin tài chính khác" + privacy policy (D30, user đã duyệt)
- *Xong khi:* acceptance overview §6 PASS trên 2 máy DEV + máy cặp đang chờ; rules test PASS; PO verify.

### 🟡 Mốc B — Tiền chạy đều mỗi tháng — sau khi mốc A live
- [ ] Khoản định kỳ: Tự ghi / Chỉ nhắc, sinh ở client id `rec_<id>_<date>`, nhắc hoá đơn 1212–1219 (D15)
- [ ] Sổ nợ (cho vay / đi vay với người ngoài), chỉ sổ riêng (D14)
- [ ] Xuất CSV UTF-8 BOM qua `share_plus` (D22)
- [ ] Khoá Face ID / vân tay riêng Sổ tiền — spike `FlutterFragmentActivity` trước (D16)
- [ ] Pref tắt push sổ chung (`PUSH_TYPE_PREF_FIELD`) nếu có phàn nàn
- *Xong khi:* PO viết acceptance mốc B lúc mở mốc.

### ⚪ Mốc C — Bằng chứng & tiện ích
- [ ] Ảnh hoá đơn 1 ảnh/khoản (D23)
- [ ] Lịch sử sửa từng lần ở sổ chung
- [ ] "Sổ cũ": xem khoản chung với người ấy cũ sau khi rời
- [ ] Chuyển khoản riêng sang sổ chung
- [ ] Cân bằng bằng aggregate theo `payer` khi sổ dài (nợ §8)

### ⚪ Later
- [x] Tiền tệ theo sổ, không quy đổi (D31, 2026-10-25)
- [ ] Mỗi ví một loại tiền + tỷ giá quy đổi ở báo cáo (phần còn lại của D24)
- [ ] Nhập CSV từ Money Lover / MISA
- [ ] Recap tháng dạng thẻ chia sẻ ("Tháng 10 chúng mình ăn ngoài 23 bữa")
- [ ] Ứng viên premium khi có monetization: khoá cả app, báo cáo năm — KHÔNG gate ghi chép cơ bản hay dữ liệu cũ (CLAUDE.md §10)
- Không làm: liên kết ngân hàng, đọc SMS/thông báo ngân hàng, đầu tư, AI trả phí (D29)

## Mốc đã đạt
- [2026-10-20] Spec "Quỹ chung" (sổ chi chung) → cùng ngày mở rộng thành app quản lý tiền 2 sổ, chia 3 mốc.

## Ghi chú phụ thuộc
- decision-wheel (1.11.0) phải có trên nhánh trước khi làm D20.
- Chung file với poke, caro-game, weather, arrival (`functions/index.js`, `firestore.rules`, indexes, ARB, `session_resolver`, `NotificationTapRouter`) → Lead xếp thứ tự merge; band thông báo đối chiếu cả đợt.
- Đề xuất Lead: 4 feature nhỏ phát hành trước, mốc A đi bản riêng nếu không kịp.
- Khai báo store + privacy policy phải xong trước khi gửi duyệt mốc A.
