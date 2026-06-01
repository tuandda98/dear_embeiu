# 🗺️ Roadmap riêng — Guest mode

> Kế hoạch chi tiết NỘI BỘ feature này (chia phase/version, thứ tự làm). Khác với `../../ROADMAP.md` (toàn cảnh mọi feature). PO sở hữu; cập nhật khi phạm vi feature đổi.

- **Trạng thái feature:** 🧪 Test PASS (code-level) — chờ user smoke-test thiết bị

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — Guest counter local (fix Apple 5.1.1) (P0) — 🧪 Test PASS, chờ smoke-test
- [x] Nút "Dùng thử không cần đăng nhập" ở login (+ divider "hoặc")
- [x] `GuestCounterScreen` (route `/guest`, KHÔNG qua authGate): empty card chọn ngày + CounterCard hero + milestone + CTA đăng nhập/đăng ký
- [x] Lưu Hive `guest_settings`/`anniversary` (millis), thuần local — 0 backend
- [x] 13 key `guest*` vi+en + gen-l10n; `fvm flutter analyze` sạch
- *Xong khi:* user smoke-test 5 case runtime OK → ✅ Done (rồi build/submit lại App Store)

### ⚪ Phase 2 (Later, tùy chọn) — Chuyển đổi guest→account
- [ ] Khi guest đăng ký, prefill/di trú ngày kỷ niệm đã chọn sang couple (hiện CTA chỉ điều hướng, chưa mang dữ liệu)

## Mốc đã đạt
- [2026-06-01] Spec → Design → Dev → Test PASS code-level (PO orchestrate). Build sạch, thuần local.

## Ghi chú phụ thuộc
- Không phụ thuộc backend (thuần local). Tái dùng feature counter (CounterData/CounterCard) + helper home_screen.
- **Chặn release App Store:** đây là fix cho reject 5.1.1(v) — phải qua smoke-test rồi mới build/submit lại.
