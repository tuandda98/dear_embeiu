# 🗺️ Roadmap riêng — Về đến nhà chưa? (arrival)

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu.

- **Trạng thái feature:** 📋 Spec (2026-10-20; user đã trả lời §11, thêm yêu cầu nơi tự đặt + nhập địa chỉ sau khi xem mockup)

## Phân phase (Now / Next / Later)

### 🟢 Phase 0 — Spike kỹ thuật (P1) — chưa bắt đầu
- [ ] `native_geofence` build được với toolchain hiện tại, không license trả phí
- [ ] iOS: app bị hệ thống tắt được đánh thức, ghi Firestore từ nền xong trong ~10 giây; đo độ trễ
- [ ] iOS 18 + iOS 26: app bị vuốt tắt có được đánh thức không
- [ ] Android: callback nền có Firebase + đọc pin; merged manifest không kéo `FOREGROUND_SERVICE_LOCATION`
- [ ] Geocoder hệ điều hành với 20 địa chỉ VN mẫu (tên cũ + mới): ≥70% trong 250 m mỗi nền tảng
- [ ] `MKLocalSearchCompleter` không bị giới hạn tần suất khi gõ nhanh
- *Xong khi:* 9 câu ở `overview.md` §6 có số đo trong `dev.md`; giả định sai thì PO sửa spec trước khi Dev viết plan.

### 🟢 Phase 1 — Bản đợt 2, phát hành chung cả 2 nền tảng (P1, D13) — 📋 Spec
- [ ] Rules `arrival/{uid}` (slot `home`/`p1..p4`, `last.name` 1–24) + test ≥18 case; CF `notifyArrival` + dọn trong `notifyPartnerLeft`/teardown; `pushArrival`
- [ ] Nơi tự đặt: Nhà cố định + tối đa 4 nơi, tên + 7 biểu tượng (D19)
- [ ] Tìm địa chỉ bằng geocoder hệ điều hành (D20), xác nhận bằng chữ + bán kính (D21), dự phòng vị trí hiện tại
- [ ] Thẻ Home 6 trạng thái ("Về nhà rồi" + "Đến nơi rồi"), màn thiết lập, màn thêm/sửa nơi, 2 màn giải thích quyền, mục Cài đặt
- [ ] Geofence iOS + Android (≤5 nơi, 150/250 m, bộ lọc rìa vùng D6), cờ `config/app.arrivalAutoEnabled`
- [ ] Widget-today 2 loại `arrival_home` / `arrival_place`, chạm push → thẻ
- [ ] Privacy policy (`phase3`, có câu tìm địa chỉ D22) + Data safety + App Privacy + form Play + video ≤30 giây
- [ ] Kế hoạch B sẵn sàng: hằng `kArrivalAutoAndroid`, bản manifest không quyền nền
- *Xong khi:* acceptance §10 PASS; cả 2 store duyệt bản đợt 2 (hoặc Android lên bằng kế hoạch B).

### 🟡 Phase 2 — Sau khi đo 30 ngày
- [ ] Bản đồ xác nhận vị trí / kéo ghim nếu >15% nơi bị đặt lại (iOS MapKit miễn phí; Android Maps SDK miễn phí nhưng cần key trong app)
- [ ] Goong qua CF proxy nếu geocoder hệ điều hành dưới ngưỡng (trả phí, cần user duyệt)
- [ ] Hướng dẫn "Tự khởi động" cho Xiaomi/Oppo/Vivo (nếu spike cho thấy cần)
- [ ] Play từ chối ở đợt 2 → viết lại khai báo, thử lại tối đa 1 lần

### ⚪ Phase 3 (Later)
- [ ] "Tạm ẩn 1 giờ / tới mai" (ghost mode)
- [ ] "Nhà chúng mình" dùng chung của cặp
- [ ] "Đang trên đường về" (rời Công ty → báo nhẹ kèm giờ dự kiến)
- [ ] Push "pin sắp hết" nếu có cách làm không cần chạy nền liên tục
- [ ] Nhắc "về nhà rồi mà chưa báo" cho người chỉ dùng bấm tay

## Mốc đã đạt
- [2026-10-20] Spec PO v1.
- [2026-10-20] Spec v2: nơi tự đặt + nhập địa chỉ (geocoder hệ điều hành), phát hành chung (D13).

## Ghi chú phụ thuộc
- `widget-today` (đã gộp `feature/daily-open`): thêm `statusKind` + map push nền.
- `weather` (đợt 2): nếu cũng xin vị trí thì gộp MỘT luồng xin quyền; có thể dùng toạ độ Nhà lưu local (hoặc chính ô tìm địa chỉ `PlaceSearch`) làm nguồn thành phố, không gửi lên máy chủ.
- `poke` (đợt 2): chung ngân sách push đánh thức nền iOS.
- `care-message`: nút "Hỏi thăm" trên thẻ mở màn có sẵn.
- `functions/index.js`: `notifyPartnerLeft` + teardown bị nhiều feature đợt 2 cùng sửa → Lead gộp tuần tự.
