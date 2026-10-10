# 🗺️ Roadmap riêng — Giấc ngủ của chúng mình (sleep)

> Kế hoạch chi tiết NỘI BỘ feature này (chia phase/version, thứ tự làm). Khác với `../../ROADMAP.md` (toàn cảnh mọi feature). PO sở hữu; cập nhật khi phạm vi feature đổi.

- **Trạng thái feature:** 🧪 **Tester vòng 4: 0 chặn · 0 nên sửa · 5 nhỏ → Dev đã vá 2026-10-11 → chờ Tester vòng 5 (kiểm nhanh)** (analyze 0 · test 167/167 · rules-test 330 · rules + CF `deleteAccount`/`leaveCoupleCleanup` DEV deployed · smoke Android DEV). Còn thiếu: thử tay luồng iOS/Apple Health trên máy thật hoặc simulator. Chi tiết: `dev.md`. Mockup: https://claude.ai/artifact/9Gmj2jJViF5DPeBCNSmsvF · spec: `design.md`.

## ▶️ BẮT ĐẦU PHIÊN DEV TỪ ĐÂY (handoff 2026-10-10)
1. Đọc `design.md` (nguồn sự thật — mockup lệch thì spec thắng). `overview.md` PO chưa viết: phạm vi Phase 1 dưới đây là bản chốt tạm của Lead theo các quyết định user đã đưa trong `design.md` (Đầu vào · R1–R4 · màu riêng · lịch trăng).
2. Branch `feature/sleep` (tách từ `feature/app-check` — mang theo 3 commit App Check đang chờ merge release kế tiếp, cố ý để khỏi xung đột tài liệu).
3. Toolchain + rules-test + deploy: theo CLAUDE.md §0/§13 (`scripts/test-firebase-rules.sh` khi đụng rules; DEV được deploy, **PROD chờ lệnh**).

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — MVP lịch trăng (P1) — sẵn sàng Dev
- [x] **Model + thuật toán** `SleepNight` (đêm gắn ngày thức dậy; bedAt/wakeAt/awakenings/source `auto|health|manual|edited`) + hàm tính từ dòng sự kiện màn hình: cửa sổ 18:00→14:00, gộp lần bật ≤ 5 phút (đếm *thức giấc*), lấy đoạn tắt dài nhất ≥ 3 giờ. **Unit test** thuật toán (qua nửa đêm, AOD, không có đoạn ≥ 3h, nhiều lần thức).
- [x] **Android**: MethodChannel Kotlin đọc `UsageStatsManager.queryEvents` (`SCREEN_INTERACTIVE`/`SCREEN_NON_INTERACTIVE`, API 28+) 14 ngày gần nhất; kiểm & mở `Settings.ACTION_USAGE_ACCESS_SETTINGS`; kiểm lại quyền ở `resumed`. Android < 9 → chỉ ghi tay.
- [x] **iOS**: HealthKit chỉ đọc `sleepAnalysis` (capability + `NSHealthShareUsageDescription` VI); không có dữ liệu → ghi tay + gợi ý bật Lịch ngủ.
- [x] **Lưu**: Hive (luôn) · Firestore CHỈ khi bật chia sẻ (tắt → xoá bản trên Firestore). Doc đêm chỉ giờ cuối + `source` (R2, không lưu giờ gốc). Dấu `deleted` local để quét không tạo lại đêm đã xoá. Bản sửa tay không bị quét ghi đè.
- [x] **Rules** (additive, backward-compat): người ấy chỉ đọc khi cờ chia sẻ bật; chủ sở hữu ghi; create/update/delete chỉ khi `wakeAt ≥ request.time − 8 ngày` (R3); `hasOnly` field; prefs `sleepShare` + `sleepColor` (id `personPalette`). Chạy `scripts/test-firebase-rules.sh`, deploy **DEV**.
- [x] **UI**: `SleepCard` Home (dưới `MoodCard`, trăng 30px, footer ngủ cùng lúc) · `SleepScreen` (segmented · **card bầu trời đêm lịch trăng** · chi tiết đêm 2 làn · Tháng này · cài đặt chia sẻ + **"Màu trăng của bạn"** + nguồn + giải thích) · `SleepSetupSheet` 2 bước · `SleepEditSheet` (R1–R4, khoá 7 ngày) · `SleepHowItWorksSheet`. `lib/theme/person_palette.dart` (8 màu + 6 cặp khoá + luật C1).
- [x] **i18n**: toàn bộ key trong bảng Copy của `design.md` (sửa CẢ `app_en.arb` + `app_vi.arb` → `gen-l10n`).
- [x] **A11y + motion**: `Semantics` mỗi ô lịch (`sleepDaySemantics` có tên pha trăng + "(đã sửa)") · Reduce Motion tắt twinkle/crossfade.
- *Xong khi:* `flutter analyze` 0 · `flutter test` pass (gồm test thuật toán) · rules-test pass · smoke 2 máy DEV (Android có Usage Access + iOS ghi tay/Health): bật chia sẻ → máy kia thấy đúng màu, đúng nhãn "Đã sửa", đêm > 7 ngày khoá sửa.
  - *Đạt 2026-10-11:* analyze 0 · test 163/163 · rules 330 · smoke Android DEV (người ấy giả lập bằng script admin, đọc qua rules thật). **Còn:** smoke iOS (popup Sức khoẻ + dữ liệu thật) và 2 máy thật cùng couple.

### 🟡 Phase 2 — Gắn kết — sau Phase 1
- [ ] Push "<tên> vừa dậy" (opt-in) · nút "Rủ người ấy chia sẻ" · đọc Health Connect trên Android · widget màn hình chính.

### ⚪ Phase 3 (Later)
- [ ] Lịch ngủ mục tiêu chung · nối với Cây Tình Yêu (v3 chòm sao đã làm 2026-10-11 — có thể thêm sao "ngủ" sau).

## Việc của PO / user (song song, không chặn code DEV)
- Kiểm chính sách Google Play cho `PACKAGE_USAGE_STATS` + cập nhật khai báo An toàn dữ liệu & privacy policy; App Store: App Privacy (Health). Bắt buộc TRƯỚC khi phát hành, không cần trước khi code.

## Mốc đã đạt
- [2026-10-11] 🧪 Tester vòng 2 FAIL → 💻 Dev vá; user chốt thuật toán (dài nhất, bỏ khoảng xong trước 1h) + người ở lại tự tắt chia sẻ khi người ấy rời đi
- [2026-10-11] 🧪 Tester vòng 1 FAIL → 💻 Dev vá S1–S6 + phần lớn lỗi nhỏ — chờ Tester vòng 2
- [2026-10-11] 💻 Dev Phase 1 xong (chi tiết `dev.md`) — chờ Tester
- [2026-10-10] 🎨 Design spec v1 (`design.md`)
- [2026-10-10] User chốt luật "cho sửa nhưng minh bạch" (R1–R4 trong `design.md`) + mockup tương tác 5 artboard
- [2026-10-10] User chốt "cho user chọn màu" → `personPalette` 8 màu + 6 cặp khoá
- [2026-10-10] 🎨 Design v3 "lịch trăng" (thay cột đôi + số giờ) — sẵn sàng Dev

## Ghi chú phụ thuộc
- Dùng lại: `MoodCard` (lấy tên người ấy), `_MonthCalendarCard` của `lunar_calendar_screen.dart`, `SubScreenHeader`, `ContentCard`, `IconBadge`, `showAppTimePicker`, bảng màu đêm của `SkyBackdropPainter` (`love_tree_screen.dart`).
- Cây Tình Yêu v3 (chòm sao) đã chốt + code 2026-10-11 (xem `../love-tree/dev.md`); chưa nối với giấc ngủ.
