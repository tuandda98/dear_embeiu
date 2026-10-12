# 🗺️ Roadmap riêng — Widget màn hình chính

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu.

- **Trạng thái feature:** 📋 Spec → 💻 Dev (từ 2026-10-12)

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — Đếm ngày yêu (P1) — đang làm
- [ ] Bridge Flutter → native (`dear_embeiu/widget`, ảnh chụp dữ liệu + chuỗi dịch sẵn)
- [ ] iOS: target `DearEmbeiuWidget` nhỏ + vừa, App Group dev/prod, timeline 0:00, tinted
- [ ] Android: `DayCounterWidget` 2×2 + 4×2, font Quicksand `res/font`, cập nhật 30 phút
- [ ] Trạng thái trống + chạm mở app + event `widget_tap`
- [ ] Test Dart/Swift/Kotlin cùng bộ vector; smoke 2 nền tảng
- *Xong khi:* 11 tiêu chí ở `overview.md` §5 PASS; ship trong 1.10.0.

### 🟡 Phase 2 — Màn khoá iPhone — chưa bắt đầu
- [ ] Accessory inline ("1.247 ngày"), circular (số + tim), rectangular (số + tên) — cùng timeline Phase 1
- [ ] Kiểm StandBy (iOS 17) ban đêm
- *Xong khi:* 3 cỡ màn khoá thêm được, đọc được ở chế độ vibrant.

### ⚪ Phase 3 (Later) — Widget theo "hôm nay"
- [ ] Câu hỏi hôm nay (nối `wakeClients` của `notifyDailyAnswer` sang reload widget; chạm → mở thẳng sheet trả lời cần đọc deep link — xem lại D8 audit)
- [ ] Ảnh kỷ niệm / ngày này năm xưa (copy ảnh thu nhỏ sang App Group khi app chạy hoặc được push đánh thức)
- [ ] Đêm qua (giấc ngủ), chuỗi ngày — cân nhắc theo số liệu `widget_tap` của Phase 1

## Mốc đã đạt
- [2026-10-12] User chốt nội dung + hướng A, duyệt thiết kế kỹ thuật; canvas mockup 5 artboard.

## Ghi chú phụ thuộc
- Không đụng backend. Lần archive iOS đầu cần Xcode đăng nhập Apple ID để tạo App Group cho App ID `com.tony.dearembeiu` (+ `.dev`) và profile cho `.widget`.
- Phát hành sau 1.9.1 (audit + streak-self-heal) → bản MINOR 1.10.0.
