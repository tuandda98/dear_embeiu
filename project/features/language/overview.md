# Language — Đa ngôn ngữ

> File PO sở hữu. Nguồn sự thật chung. Designer/Dev/Tester đọc file này trước.

- **Feature:** language
- **Ưu tiên:** P0 (gap A, B) + P1/P2 (còn lại)
- **Trạng thái:** ✅ Done (2026-05-31)
- **Tạo ngày:** 2026-05-30
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 7

## 1. Vấn đề & giá trị
- *Vấn đề:* App cho chọn ngôn ngữ (VI/EN/System) nhưng **ngôn ngữ "rò rỉ"** ngoài lựa chọn người dùng: ngày tháng và push notification vẫn hiển thị tiếng Việt kể cả khi user chọn English.
- *Giả thuyết giá trị:* sửa các chỗ rò rỉ → trải nghiệm đa ngôn ngữ nhất quán → tăng tin cậy & sẵn sàng cho thị trường ngoài VN.
- *Đối tượng:* user chọn English (và mở rộng ngôn ngữ sau này).
- *Đo bằng:* (khi có analytics) tỉ lệ giữ English sau khi đổi; không còn bug report về chữ lẫn ngôn ngữ.

## 2. Bối cảnh / nghiên cứu (PO, 2026-05-30)
- Best-practice: dùng **endonym** (tên ngôn ngữ viết bằng chính nó), luôn có "System default", **áp dụng tức thì** — app đã làm đúng. **Khuyến cáo tránh dùng cờ** đại diện ngôn ngữ (cờ = quốc gia ≠ ngôn ngữ).
- Đối thủ VN (Been Love Memory, inlove, Lovedays): đa số chỉ EN/VI, switch tức thì, không trang riêng → picker bottom sheet hiện tại ngang/hơn mặt bằng.
- Nguồn: simplelocalize.io, smashingmagazine.com (language selector), linguise.com, phrase.com.

## 3. Phạm vi
- **Trong phạm vi:** ngày tháng theo locale; push partner-photo đa ngôn ngữ; iOS Info.plist; chống nhấp nháy cold start; bỏ cờ → letter chip; dọn ARB key chết; pill System default.
- **Ngoài phạm vi:** thêm ngôn ngữ mới (ngoài VI/EN); dịch nội dung do user nhập (caption); RTL.

## 4. Quyết định đã chốt (decision log — đừng lật lại trừ khi user đổi ý)
- **D2 — Bỏ cờ quốc gia**, dùng "letter chip" (EN/VI nền hồng brand) + endonym (Tiếng Việt/English) + tên phụ tiếng Anh + ✓. "System default" dùng globe 🌐 + mã ngôn ngữ đang resolve. *Lý do:* cờ = quốc gia ≠ ngôn ngữ; chip chữ scale tốt khi thêm ngôn ngữ.
- **D3 — Format ngày theo locale, bỏ mọi hardcode:** ngày đầy đủ (Home/Profile/anniversary) dùng `DateFormat.yMMMd(localeCode)` (VI "30 thg 5, 2026" / EN "May 30, 2026"); feed/gallery dùng key `feedDateFormat` (VI "30 thg 05 • 14:30" / EN "30 May • 14:30"). Giờ giữ 24h (`HH:mm`) cho cả 2 ngôn ngữ.

## 5. Acceptance criteria (xong khi…) — ✅ tất cả đạt (runtime test 2026-05-31)
- [x] Đổi EN → mọi ngày tháng (Home/Gallery/Profile) hiển thị format EN, không còn chữ "thg".
- [x] Push "partner đăng ảnh": người nhận EN nhận tiếng Anh, VI nhận tiếng Việt; 2 thiết bị couple khác ngôn ngữ → mỗi máy đúng. *(functions đã deploy 2026-05-31)*
- [x] Cold start: chọn EN → kill → mở lại vào thẳng EN, không nháy VI.
- [x] iOS Settings → app hiện đủ EN/VI.
- [x] Picker không còn cờ; hiện letter chip + System default đúng 3 state.
- [x] Không còn chuỗi/ngày/notification cố định 1 ngôn ngữ khi user đã chọn ngôn ngữ khác.

## 6. Gap đã kiểm chứng (file:line)
- 🔴 **A (P0):** ngày tháng không đổi theo ngôn ngữ — `DateFormat` hardcode, không set `Intl.defaultLocale`, không `initializeDateFormatting`; gallery hardcode "thg"; key `feedDateFormat` có mà không dùng. `gallery_screen.dart:275,1652`, `home_screen.dart:1068`, `profile_screen.dart:1294`.
- 🔴 **B (P0):** push partner-photo hardcode VI, không theo locale người nhận. `functions/index.js:140-143`. (Reminder local đã localize qua `AppL10n` — ok.)
- 🟡 **C (P1):** iOS Info.plist thiếu `CFBundleLocalizations`/`CFBundleAllowMixedLocalizations`.
- 🟡 **D (P1):** nhấp nháy sai ngôn ngữ cold start. `locale_provider.dart:11-22`.
- ⚪ **E (P2):** 3 ARB key chết: `languageEnglish`, `languageVietnamese`, `languageSystemDesc` (`app_en.arb:384-386`).
- ⚪ **F (P2):** pill auth hiện "—" khi System default (`language_toggle_button.dart:109`).
- ⚪ **G (P2):** chưa log analytics khi đổi ngôn ngữ.

## 7. Giao việc 3 vai (chi tiết ở file mỗi role)
- 🎨 **Designer:** chip chữ EN/VI + System (🌐), 3 state cho picker row + pill auth; bảng copy VI-EN → *expect:* handoff để dev dựng không hỏi lại. Xem [design.md](design.md).
- 💻 **Dev:** fix A + B (+deploy functions) + C + D + D2/D3; dọn E/F/G → *expect:* không còn rò rỉ ngôn ngữ; functions đã deploy. Xem [dev.md](dev.md).
- 🧪 **Tester:** happy + ngày tháng + push 2 thiết bị + cold start + fallback locale không hỗ trợ + offline + layout VI dài → *expect:* mọi case verdict, 0 P0/P1 fail. Xem [test.md](test.md).

## 8. Hiện trạng (đã tốt, KHÔNG đập đi xây lại)
Picker = bottom sheet single-select, có "System default", auto search khi >6 ngôn ngữ; dùng chung cho pill auth + card Profile. Code: `lib/widgets/language_toggle_button.dart`. `LocaleProvider` (`lib/providers/locale_provider.dart`): Hive box `app_settings` key `locale`, null=system. `main.dart`: supportedLocales [en,vi], 4 delegates, `localeResolutionCallback` sync `AppL10n`.

## 9. Changelog feature
- [2026-05-30] [PO] Tạo feature, viết spec, chốt D2 + D3, xác định 7 gap A–G, ưu tiên A+B trước.
- [2026-05-30] [Designer] Handoff chip chữ 3 state.
- [2026-05-30] [Dev] Code gap A/C/D/D2/D3/E/F + gap B (push đa ngôn ngữ); flutter analyze sạch. Fix BUG-1 (key fullDateFormat).
- [2026-05-30] [Tester] Verify static + 20 case; ground-truth flutter analyze sạch.
- [2026-05-31] [User] Test runtime (A) pass; duyệt deploy (B).
- [2026-05-31] [PO] Deploy Cloud Functions (gap B) lên production tonyembeiu thành công. PO FINAL VERIFY: acceptance đủ + analyze sạch + runtime pass + deploy xong → **✅ Done**.
