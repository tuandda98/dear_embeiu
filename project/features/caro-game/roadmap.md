# 🗺️ Roadmap riêng — Cờ caro theo lượt (caro-game)

> Kế hoạch chi tiết NỘI BỘ feature này (chia phase/version, thứ tự làm). Khác với `../../ROADMAP.md` (toàn cảnh mọi feature). PO sở hữu; cập nhật khi phạm vi feature đổi.

- **Trạng thái feature:** 📋 Spec (chờ user duyệt, 2026-10-20)

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — Chơi được theo lượt trên 2 máy (P1) — Now
- [ ] Backend: hàm thuần `caroWinner` + test node 10 case · callable `caroAction` (6 op) · option `collapseId` cho `sendToRecipientDevices` · guard `type` cho `resolveRpsGame`/`nudgeRpsPlayer` · `notifyPartnerLeft` xoá `caroState/main` · rules additive + ≥15 case rules-test · deploy DEV
- [ ] Design: điểm vào chung đợt 2 (thẻ "Chơi cùng nhau"), màn ván 7 trạng thái, bàn 15×15 (chạm 2 bước, phóng to), lịch sử + bàn cuối, huy hiệu Profile
- [ ] Client: model/service/provider + wire `session_resolver` · màn ván + lịch sử + điểm vào · push tap + Notification Center (2 chỗ) · feature tour · i18n vi/en
- [ ] Widget-today: `caro_turn` (bridge khi app mở + handler nền)
- [ ] Analytics 6 event (overview §8)
- [ ] Tester: 18 tiêu chí overview §10 trên `test3`/`test4` + app 1.11.0 song song
- *Xong khi:* acceptance overview §10 PASS; PROD deploy + phát hành chờ lệnh user (bản MINOR kế sau 1.11.0, Lead chốt số).

### 🟡 Phase 2 — Next
- [ ] Tua lại từng nước của ván cũ (dữ liệu `cells` đã đủ)
- [ ] Công tắc tắt push caro riêng (map vào `PUSH_TYPE_PREF_FIELD`)
- [ ] Luân phiên người đi trước nếu số liệu cho thấy người rủ thắng >65%
- [ ] Luật tự do (field `rule` đã có sẵn) nếu user muốn
- [ ] Đếm ván caro trong `scripts/prod-retention-stats.js`

### ⚪ Phase 3 (Later)
- [ ] Trò theo lượt khác trên cùng khung (`games` + callable): cờ ca rô bàn lớn, nối chữ, đoán hình
- [ ] Huy hiệu chuỗi thắng / "ván dài nhất"

## Mốc đã đạt
- [2026-10-20] Spec PO (D1–D20) + kiểm tương thích app 1.10.x/1.11.0.

## Ghi chú phụ thuộc
- **widget-today** (1.11.0, đang chờ duyệt): cần có bridge `updateStatus` + handler nền trước khi thêm `caro_turn`.
- **rps-game:** dùng chung collection `games`, 2 index, hàm `rpsPresenceTouchesOnlyOwnKey()`; sửa guard ở 2 CF rps ⇒ deploy lại `resolveRpsGame`, `nudgeRpsPlayer`.
- **Cả đợt 2** (poke, weather, arrival, expenses): cùng sửa `sendToRecipientDevices` (option `collapseId`) và cùng tiêu hạn mức đánh thức nền iOS ⇒ Lead gộp và cộng tổng.
- Push iOS trên DEV thiếu APNs key (CLAUDE.md §5) ⇒ kiểm push bằng Android thật hoặc log CF.
