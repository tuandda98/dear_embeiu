# 🗺️ Roadmap riêng — Thời tiết hai nơi

> Kế hoạch chi tiết NỘI BỘ feature này (chia phase/version, thứ tự làm). Khác với `../../ROADMAP.md` (toàn cảnh mọi feature). PO sở hữu; cập nhật khi phạm vi feature đổi.

- **Trạng thái feature:** 📋 Spec (chờ user duyệt, 2026-10-20)

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — Thẻ hai nơi + nhắc mang ô (P1, đợt "mở app mỗi ngày" 2) — 📋 Spec
- [ ] Spike D3: độ đúng "chiều nay mưa" của MET ở Hà Nội / TP.HCM / Đà Nẵng, 5 ngày. Không đạt → đổi sang WeatherKit (cần user tạo khoá).
- [ ] Danh sách thành phố (Phụ lục A overview) bản Dart + JSON cho CF + test khớp.
- [ ] CF `getCityWeather` + cache `weatherCache/{cityId}` + dọn `weather/{uid}` trong `notifyPartnerLeft`.
- [ ] Rules `couples/{id}/weather/{uid}` + ≥12 case rules-test.
- [ ] `WeatherService` / `WeatherProvider` + hàm thuần tính tình trạng + test.
- [ ] Thẻ Home 8 trạng thái, sheet chi tiết, sheet chọn thành phố, mục Cài đặt.
- [ ] Nút gợi ý → màn Quan tâm điền sẵn (`openCareMessageScreen` thêm `initialTitle`/`initialBody`).
- [ ] Thông báo sáng 07:30 id 1160, trần 3 lần/7 ngày, không lặp tình trạng hai ngày liền.
- [ ] Analytics + `care_message_sent.source`.
- [ ] Privacy policy + App Privacy (Coarse Location) + Play An toàn dữ liệu — user duyệt.
- *Xong khi:* toàn bộ acceptance §9 overview PASS trên 2 máy DEV; rules PROD + CF PROD deploy theo lệnh user cùng bản phát hành đợt 2.

### 🟡 Phase 2 — Mở rộng nơi chốn — chưa làm
- [ ] Tìm thành phố tự do (geocoding) khi đếm được user thiếu thành phố; khi đó CF chuyển từ danh sách đóng gói sang lưới toạ độ 2 chữ số + giới hạn theo uid.
- [ ] Gợi ý thành phố gần nhất từ vị trí "Nhà" của `arrival` (nếu user đã đặt), không lưu toạ độ nhà vào doc thời tiết.
- [ ] Tag mùa/thời tiết cho ngân hàng "đi đâu" của `decision-wheel` (mưa → ưu tiên mục ở nhà).
- [ ] Cảnh báo bão/áp thấp ở chỗ người ấy (nguồn chính thức, ghi rõ cơ quan phát).

### ⚪ Phase 3 (Later) — Hiện ở nhiều chỗ hơn — ý tưởng
- [ ] Widget: thêm một dòng nhỏ thời tiết chỗ người ấy (cần đẩy dữ liệu theo push hoặc chấp nhận số trễ tới lần mở app).
- [ ] °F cho người dùng ở Mỹ.
- [ ] Chất lượng không khí (AQI) Hà Nội mùa đông.
- [ ] Freemium: chủ đề thẻ/icon thời tiết đặc biệt (không gate dữ liệu thời tiết cơ bản).

## Mốc đã đạt
- [2026-10-20] Spec PO: chọn nguồn MET Norway, danh sách thành phố, D1–D19.

## Ghi chú phụ thuộc
- Cần `care-message` (đã live) + thêm 2 tham số điền sẵn cho `openCareMessageScreen`.
- Vị trí thẻ trên Home chốt chung với `poke` · `caro-game` · `arrival` · `expenses` (Designer cùng đợt).
- `firestore.rules`, `functions/index.js`, ARB, `session_resolver` cùng bị 4 feature kia sửa → Lead gộp; dải thông báo local 1160 cần đối chiếu.
- Không phụ thuộc `widget-today` ở Phase 1.
