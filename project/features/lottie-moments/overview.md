# Lottie moments — animation "khoảnh khắc" cảm xúc

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.

- **Feature:** lottie-moments
- **Ưu tiên:** P2 (polish — KHÔNG phải growth lever)
- **Trạng thái:** 💻 Dev (scaffolding + 3 moment wire xong; cần asset cho 3/4 slot)
- **Tạo ngày:** 2026-06-03
- **Liên quan:** [dev.md](dev.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md) · liên quan [ui-revamp](../ui-revamp/overview.md)

## 1. Vấn đề & giá trị
- *Vấn đề:* app đã có entrance motion (`flutter_animate`) + confetti, nhưng các khoảnh khắc cảm xúc cao (ghép đôi, đăng ảnh đầu, đạt mốc) chưa có điểm nhấn "wow" để tạo cảm giác thân mật & đáng nhớ.
- *Giả thuyết giá trị:* thêm Lottie **đúng chỗ, đúng liều** ở vài khoảnh khắc → tăng cảm xúc tích cực ⇒ nhích nhẹ tỉ lệ ghép đôi + đăng ảnh đầu tiên (2 moment đầu trùng North Star).
- *Đối tượng:* cặp đôi trẻ VN.
- *Đo bằng gì:* (khi có analytics) tỉ lệ hoàn tất ghép đôi; tỉ lệ đăng ảnh đầu sau khi thấy empty-state.

## 2. Bối cảnh / nghiên cứu
- Brand "Sunset Romance" = romantic **minimalism**. ⇒ Lottie phải tiết chế, KHÔNG thay icon tĩnh hàng loạt (rối + nặng máy low-end + phình size).
- License nguồn: **Lottie Simple License** của LottieFiles — free cho thương mại, **không bắt buộc attribution** ([nguồn](https://lottiefiles.com/page/license)). File hiện dùng `daily_reveal.json` lấy từ repo MIT `spemer/lottie-animations-json`.
- Target nhiều máy Android tầm trung ⇒ giới hạn số animation chạy đồng thời (KHÔNG đặt trong list/grid như masonry).

## 3. Phạm vi (scope)
- **Trong phạm vi (4 moment chọn lọc):**
  1. ⭐ Ghép đôi thành công (B join couple) — `setup_screen`
  2. ⭐ Empty state Gallery (chưa có ảnh) — `gallery_screen`
  3. Đạt milestone (520/1000/1314…) — slot sẵn, **trigger in-app TBD**
  4. Daily Question reveal — `home_screen` (accent thêm cạnh confetti)
- **Ngoài phạm vi:** thay icon tĩnh (lucide) bằng icon động hàng loạt; animation trong list/grid; bundle font offline.

## 4. Quyết định đã chốt (decision log)
- **D1 — Dùng Lottie có chọn lọc ở 4 "khoảnh khắc", KHÔNG rải icon động.** *Lý do:* giữ minimalism + perf low-end + size.
- **D2 — Nguồn file: LottieFiles free (Lottie Simple License) / repo MIT.** *Lý do:* thương mại OK, không cần attribution.
- **D3 — KHÔNG dùng cờ bật/tắt (`kLoveLottieEnabled` đã bỏ).** *Lý do:* user **release theo branch** — code này không nằm trên nhánh 1.0 nên không cần ngủ đông bằng cờ. Thay vào đó: feature "ngủ đông theo file" — slot **thiếu file `.json` → tự fallback** (SizedBox 0px / bỏ qua dialog), không crash.
- **D4 — Wire `setup`/`gallery`/`home`; milestone để slot sẵn nhưng KHÔNG bịa trigger giả.** *Lý do:* milestone hiện là notification, chưa có sự kiện in-app tự nhiên; thêm trigger là việc riêng.

## 5. Acceptance criteria (xong khi…)
- [x] Package `lottie` thêm + `assets/lottie/` đăng ký pubspec.
- [x] Widget tái dùng `LoveLottie` (fallback an toàn khi thiếu/hỏng file, không crash).
- [x] Wire 3 moment in-app (couple-joined / empty-gallery / daily-reveal); `flutter analyze` sạch.
- [x] Có file `.json` cho 3/4 slot (couple_joined=pháo hoa, daily_reveal=tim, empty_gallery=camera — đều placeholder, **chờ user preview & duyệt/đổi tông**).
- [ ] `milestone` cần **trigger in-app** trước rồi mới thả file.
- [ ] Smoke-test thiết bị: 3 moment hiện đúng, không giật ở máy tầm trung.
- [ ] (Milestone) chốt trigger in-app hoặc bỏ slot.

## 6. Giao việc 3 vai
- 🎨 **Designer:** chốt tông + chọn 4 file Lottie hợp brand (preview thật); spec kích thước/vị trí mỗi moment.
- 💻 **Dev:** ✅ scaffolding + widget + wire 3 moment (xem [dev.md](dev.md)). Còn: thả 3 file còn lại + (tuỳ) trigger milestone.
- 🧪 **Tester:** smoke 3 moment; kiểm fallback khi thiếu file; perf máy tầm trung; không vỡ layout empty-gallery.

## 7. Nợ kỹ thuật / rủi ro
- 🟡 **3/4 slot chưa có file** → hiện no-op (an toàn nhưng chưa thấy hiệu ứng). Cần preview + thả file.
- 🟡 **Không preview được trong terminal** → file do Claude pick là "mù"; user phải liếc & duyệt/đổi.
- 🟡 `daily_reveal` đang là heart "like-pop" (placeholder MIT) — có thể chưa khớp ý "reveal"; dễ swap.
- 🟢 Size: mỗi file ~5–170KB; `lottie` package nhẹ. Không đáng lo nếu giữ ≤4 file.

## 8. Changelog feature
- [2026-06-03] [PO/Dev] Tạo feature; chốt D1–D4; thêm `lottie ^3.3.3`; viết `LoveLottie`; wire 3 moment; seed `daily_reveal.json` (heart MIT); `analyze` sạch. Chờ 3 file còn lại + smoke-test.
