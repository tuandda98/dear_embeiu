# 🗺️ Roadmap riêng — Chọc 1 chạm (poke)

> Kế hoạch chi tiết NỘI BỘ feature này. Khác với `../../ROADMAP.md` (toàn cảnh). PO sở hữu; cập nhật khi phạm vi đổi. Spec: [overview.md](overview.md).

- **Trạng thái feature:** 📋 Spec (chờ user duyệt + trả lời Q1, Q2)

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — Chạm tim từ Home và widget (P0) — 📋 Spec
- [ ] Spike Dev: iOS 17 `Button(intent:)` gọi mạng trong extension và vẽ lại kịp ≤1 giây · Android `PokeReceiver` gọi mạng khi app đã bị vuốt tắt.
- [ ] Rules additive (`pokes` đọc-only, `pokeTokens` khoá hết, `pushPoke` ở device doc) + test.
- [ ] CF `managePokeToken` (callable) + `pokePartner` (HTTPS) + push gộp (`collapseId`/`channelId`) + inbox 1 mục/ngày + đánh thức ≤1/15 phút + dọn token khi xoá tài khoản; test emulator; deploy DEV.
- [ ] Flutter: `PokeService` + `PokeProvider`, tim + số trên Home, nhận khi đang mở app (rung + tim bay, không banner), công tắc Cài đặt, loại trạng thái widget `poke`, analytics, ARB vi/en.
- [ ] iOS widget: `SendPokeIntent`, `PokeStore`, tim trên 2 cỡ (chỉ iOS 17+), 4 method kênh mới.
- [ ] Android widget: `PokeReceiver`, tim trên 2 provider, `WidgetStore` + plugin kênh thêm method, loại khỏi backup.
- [ ] Designer: vị trí tim chung cả đợt (Home đã dày), 4 bố cục widget × 2 nền × có/không dòng trạng thái.
- *Xong khi:* 19 tiêu chí §6 overview PASS trên 2 máy DEV; PROD deploy theo lệnh user khi phát hành.

### 🟡 Phase 2 — "Chạm tay cùng lúc" (P1) — chưa bắt đầu
- [ ] Cả hai đang mở app, cùng đặt ngón tay lên một vùng → hai máy cùng rung lúc ngón tay chồng lên nhau (kiểu Thumbkiss của Between). Cần kênh gần-realtime (presence + vị trí chạm qua Firestore, độ trễ mục tiêu <500ms) — spike trước khi spec.
- [ ] Dọn `pokeTokens` không dùng 60 ngày (CF lịch hằng tuần).
- [ ] `nonce` chống đếm trùng nếu số liệu lệch.
- [ ] Xem lại ưu tiên dòng trạng thái `poke` trên widget nếu tỉ lệ trả lời câu hỏi giảm (rủi ro §8).

### ⚪ Phase 3 (Later) — ý tưởng
- [ ] Nhiều kiểu chạm (ôm, hôn, vỗ vai), mỗi kiểu rung một nhịp khác.
- [ ] "Tuần này nhớ nhau 52 lần" — thống kê tuần/tháng từ doc `pokes` (dữ liệu đã có sẵn từ Phase 1).
- [ ] Nút tim trên widget màn khoá iPhone, Apple Watch, ô Cài đặt nhanh Android.
- [ ] App Check cho endpoint khi có cách lấy token trong extension.
- [ ] Gate premium cho kiểu chạm/hiệu ứng đặc biệt (KHÔNG gate tim cơ bản).

## Mốc đã đạt
- [2026-10-20] Spec PO v1.

## Ghi chú phụ thuộc
- Cần [widget-today](../widget-today/overview.md) (bản 1.11.0): kênh `updateStatus`, handler push nền, plugin chạy trong engine nền Android, `wakeClients`.
- Dùng chung ngân sách đánh thức iOS với widget-today và mọi feature cùng đợt có push nền (`arrival`, `caro-game`… nếu có) — Lead cần tổng hợp tần suất cả đợt.
- Vị trí trên Home + widget: Designer chốt chung với 4 feature cùng đợt (`caro-game`, `weather`, `arrival`, `expenses`).
