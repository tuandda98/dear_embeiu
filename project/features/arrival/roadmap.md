# 🗺️ Roadmap riêng — Về đến nhà chưa? (arrival)

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu.

- **Trạng thái feature:** 📋 Spec (2026-10-20, chờ user duyệt + trả lời 2 câu ở `overview.md` §11)

## Phân phase (Now / Next / Later)

### 🟢 Phase 0 — Spike kỹ thuật (P1) — chưa bắt đầu
- [ ] `native_geofence` build được với toolchain hiện tại, không license trả phí
- [ ] iOS: app bị hệ thống tắt được đánh thức, ghi Firestore từ nền xong trong ~10 giây; đo độ trễ
- [ ] iOS 18 + iOS 26: app bị vuốt tắt có được đánh thức không
- [ ] Android: callback nền có Firebase + đọc pin; merged manifest chặn được quyền nền cho bản đợt 2
- *Xong khi:* 7 câu ở `overview.md` §6 có số đo trong `dev.md`; giả định sai thì PO sửa spec trước khi Dev viết plan.

### 🟢 Phase 1 — Bản đợt 2: bấm tay 2 nền tảng + tự động iOS (P1) — 📋 Spec
- [ ] Rules `arrival/{uid}` + test ≥18 case; CF `notifyArrival` + dọn trong `notifyPartnerLeft`/teardown; `pushArrival`
- [ ] Thẻ Home 6 trạng thái, màn thiết lập, 2 màn giải thích quyền, mục Cài đặt
- [ ] Geofence iOS (3 địa điểm, 150 m, bộ lọc rìa vùng D6), cờ `config/app.arrivalAutoEnabled`
- [ ] Widget-today 3 loại `arrival_*`, chạm push → thẻ
- [ ] Android: KHÔNG có quyền vị trí nền trong manifest (kiểm `aapt2`)
- [ ] Privacy policy (`phase3`) + App Privacy iOS
- *Xong khi:* acceptance §10 PASS (trừ dòng Android tự động); cả 2 store duyệt bản đợt 2.

### 🟡 Phase 2 — Android tự động (bản patch ngay sau) — chờ Phase 1 live
- [ ] Thêm `ACCESS_BACKGROUND_LOCATION`, màn giải thích Android, mở trang quyền "Cho phép mọi lúc"
- [ ] Form khai báo Play + video ≤30 giây + Data safety (Vị trí gần đúng)
- [ ] Hướng dẫn "Tự khởi động" cho Xiaomi/Oppo/Vivo (nếu spike cho thấy cần)
- [ ] Play từ chối → gỡ quyền, nộp lại; thử khai lần 2 tối đa 1 lần
- *Xong khi:* Play duyệt, tiêu chí Android tự động ở §10 PASS.

### ⚪ Phase 3 (Later) — sau khi đo 30 ngày
- [ ] "Tạm ẩn 1 giờ / tới mai" (ghost mode)
- [ ] Địa điểm tự đặt tên, "Nhà chúng mình" dùng chung
- [ ] "Đang trên đường về" (rời Chỗ làm → báo nhẹ kèm giờ dự kiến)
- [ ] Push "pin sắp hết" nếu có cách làm không cần chạy nền liên tục
- [ ] Nhắc "về nhà rồi mà chưa báo" cho người chỉ dùng bấm tay

## Mốc đã đạt
- [2026-10-20] Spec PO v1.

## Ghi chú phụ thuộc
- `widget-today` (đã gộp `feature/daily-open`): thêm `statusKind` + map push nền.
- `weather` (đợt 2): nếu cũng xin vị trí thì gộp MỘT luồng xin quyền; có thể dùng toạ độ Nhà lưu local làm nguồn thành phố, không gửi lên máy chủ.
- `poke` (đợt 2): chung ngân sách push đánh thức nền iOS.
- `care-message`: nút "Hỏi thăm" trên thẻ mở màn có sẵn.
- `functions/index.js`: `notifyPartnerLeft` + teardown bị nhiều feature đợt 2 cùng sửa → Lead gộp tuần tự.
