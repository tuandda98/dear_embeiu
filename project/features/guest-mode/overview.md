# Guest mode — Dùng thử không cần đăng nhập (fix App Store 5.1.1)

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** guest-mode
- **Ưu tiên:** P0 (CHẶN release — Apple reject 5.1.1, không qua được nếu thiếu)
- **Trạng thái:** 🧪 Test PASS (code-level) — chờ user smoke-test thiết bị (5 case runtime)
- **Tạo ngày:** 2026-06-01
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · feature [counter](../counter/overview.md) (tái dùng) · [auth](../auth/overview.md) · [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị
- *Vấn đề:* **Apple reject Guideline 5.1.1(v)** (2026-05-31): app bắt đăng nhập/đăng ký ngay từ đầu để dùng **tính năng không-cần-tài-khoản**. Apple yêu cầu: *"Revise the app to let users freely access the app's features that are not account based."*
- *Tính năng không-cần-tài-khoản trong app:* **Đếm ngày yêu** (nhập ngày kỷ niệm → xem số ngày/tháng/năm) — chạy hoàn toàn local, không cần couple/account.
- *Giá trị:* Cho dùng counter mà không cần đăng nhập → **qua được 5.1.1**; đồng thời là "single-player value" lôi kéo user trước khi ghép đôi (đúng chiến lược mục 11 CLAUDE.md).

## 2. Phạm vi (scope)
- **Trong:**
  - **Nút "Dùng thử không cần đăng nhập"** ở màn login.
  - **Màn GuestCounterScreen** (mới): chọn ngày kỷ niệm (date picker) → hiển thị đếm ngày yêu (ngày/tháng/năm + đếm ngược kỷ niệm + cột mốc), **tính local** (tái dùng `CounterData` + `CounterCard`).
  - Lưu ngày kỷ niệm guest **local (Hive)** — quay lại vẫn thấy.
  - **CTA rõ** trong màn guest: "Đăng nhập / Đăng ký để ghép đôi & lưu ảnh chung" → về login/register.
- **Ngoài (vẫn yêu cầu đăng nhập — account-based, Apple cho phép):**
  - Ghép đôi qua mã mời, gallery ảnh chung, push partner-photo, lời nhắc/custom reminders đồng bộ.
  - KHÔNG cho guest đụng Firestore/couple data.
  - KHÔNG rework toàn bộ HomeScreen thành account-optional (rủi ro cao) — guest là màn riêng gọn.

## 3. Quyết định đã chốt (decision log)
- **G1 — Guest = màn counter local độc lập** (`GuestCounterScreen`), KHÔNG tái dùng HomeScreen (home phụ thuộc `couple` khắp nơi → rework rủi ro). *Lý do:* tối thiểu, an toàn, đủ thoả 5.1.1.
- **G2 — Điểm vào: nút "Dùng thử không cần đăng nhập" ở login screen** (dưới nút đăng nhập / cạnh link đăng ký).
- **G3 — Ngày kỷ niệm guest lưu Hive local** (vd box `guest_settings` key `anniversary`), không account.
- **G4 — CTA chuyển đổi:** màn guest có nút/đường dẫn rõ "Đăng nhập để ghép đôi & lưu kỷ niệm chung" → login/register. (Khuyến khích nhưng KHÔNG ép.)
- **G5 — Counter guest tái dùng `CounterData.calculateFromAnniversary` + `CounterCard`** + logic next-anniversary/milestone từ home (trích phần không phụ thuộc couple).

## 4. Acceptance criteria
- [ ] Màn login có nút **"Dùng thử không cần đăng nhập"**.
- [ ] Tap → vào **GuestCounterScreen KHÔNG cần đăng nhập**.
- [ ] Chọn/đổi ngày kỷ niệm → hiển thị đúng ngày/tháng/năm (+ đếm ngược kỷ niệm kế + cột mốc), tính local.
- [ ] Ngày kỷ niệm guest **persist qua cold start** (Hive local).
- [ ] CTA "Đăng nhập/Đăng ký" → điều hướng đúng về login/register.
- [ ] Từ guest quay lại login được (back).
- [ ] Luồng đăng nhập/đăng ký/ghép đôi/home hiện có **KHÔNG regression**.
- [ ] i18n vi+en đủ chuỗi mới; không hardcode.
- [ ] `flutter analyze` sạch.
- [ ] Bám design system (gradient, CounterCard hero, token).

## 5. Nợ kỹ thuật / rủi ro (Tester soi)
- 🟡 Đảm bảo guest KHÔNG vô tình gọi Firestore/auth (phải thuần local).
- 🟡 Edge: chưa chọn ngày (empty state) → màn guest hiện CTA chọn ngày, không crash. Ngày tương lai → counter xử lý (days âm) hợp lý.
- 🟡 Quay lại login sau guest không để lại state rác; đăng nhập sau đó vẫn vào home/setup bình thường.

## 6. Giao việc 3 vai
- 🎨 **Designer:** thiết kế nút "Dùng thử" ở login + màn GuestCounterScreen (date picker + CounterCard hero + đếm ngược + cột mốc + CTA đăng nhập), states (chưa chọn ngày/đã chọn). Copy vi+en. Bám design system. → `design.md`.
- 💻 **Dev:** nút ở login → `GuestCounterScreen` mới (local, Hive `guest_settings`); tái dùng CounterData/CounterCard; CTA → login/register; ARB; analyze sạch; KHÔNG đụng Firestore cho guest; không regression auth flow. → `dev.md`.
- 🧪 **Tester:** verify vào guest không cần login, counter tính đúng local, persist, CTA điều hướng, không gọi backend, không regression đăng nhập/home. → `test.md`.

## 7. Changelog
- [2026-06-01] [PO] Tạo feature guest-mode để fix Apple reject 5.1.1: counter chế độ khách (local, không login) + CTA đăng nhập cho tính năng couple. Khởi động pipeline.
- [2026-06-01] [PO] Pipeline xong: Designer (design.md) → Dev (`lib/screens/guest_counter_screen.dart`, thuần local Hive `guest_settings`) → Tester PASS code-level. PO GATE: tự chạy `fvm flutter analyze` = "No issues found!"; verify thuần-local (0 ref Firebase/Auth/Provider); đọc file khớp design. **Sửa build vỡ kế thừa từ phiên Dev trước:** main.dart import file màn guest chưa tồn tại + login_screen gọi getter `guest*` chưa regen → tạo file màn + chạy `fvm flutter gen-l10n` (an toàn, ARB đầy đủ, không xoá getter). Giữ 🧪 Test PASS, **chờ user smoke-test 5 case runtime** (picker chặn ngày tương lai · Hive persist cold start · navigation CTA/back · không regression auth sau guest · toggle VI/EN). Chưa commit/deploy (chờ user duyệt + smoke-test).
- [2026-06-04] [Dev] FIX nền đen ở đáy màn guest (user thấy sau khi đăng xuất). Root cause: Scaffold có `extendBodyBehindAppBar: true` → cấp constraint chiều cao **lỏng** cho body; `body: Container(gradient)` bọc `SingleChildScrollView` co bằng nội dung (header+card+CTA ngắn) → gradient không phủ hết → lộ nền đen Scaffold. (Login không dính vì không bật flag này + có Stack fill.) Fix: thêm `width/height: double.infinity` cho Container gradient (`guest_counter_screen.dart:156`) → ép fill hết chiều cao khả dụng. VERIFY runtime Pixel 10: gradient phủ tới gesture bar, hết đen. analyze sạch.
