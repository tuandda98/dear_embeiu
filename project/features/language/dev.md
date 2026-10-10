# 💻 Dev — Language v2

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md) trước. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** ✅ Xong + functions đã deploy (2026-05-31)
- **Người/role:** Dev

> [2026-05-31] [PO] Deploy `firebase deploy --only functions --project tonyembeiu` thành công (sendPartnerPhotoNotification + pruneDeadDevices + deleteAccount updated). Gap B push đa ngôn ngữ đã live. flutter analyze sạch.

## Kế hoạch kỹ thuật theo từng gap

### A (P0) — Ngày tháng theo locale
- Trong `localeResolutionCallback` (`main.dart:124`, cạnh `AppL10n.setLocale`): set `Intl.defaultLocale = resolved.languageCode` + gọi `initializeDateFormatting(resolved.languageCode)` (import `package:intl/date_symbol_data_local.dart`).
- Thay `DateFormat` hardcode: `gallery_screen.dart:275,1652` (bỏ "thg" → dùng `l10n.feedDateFormat`), `home_screen.dart:1068` + `profile_screen.dart:1294` → `DateFormat.yMMMd(localeCode)`.
- *Lưu ý:* `DateFormat.yMMMd('vi')` ném lỗi nếu chưa `initializeDateFormatting` → phải làm bước init trước.

### B (P0) — Push đa ngôn ngữ
- Client (`push_notification_service.dart`): lưu `languageCode` (locale đang dùng, hoặc device locale nếu System) vào `users/{uid}/devices/{id}` khi register/refresh token.
- Cloud Function (`functions/index.js:140-143`): đọc `languageCode` của **device người nhận**, chọn title/body theo map `{vi, en}`, fallback `vi`. Gửi theo từng token (mỗi device có thể khác ngôn ngữ).
- **Deploy lại functions.**

### C (P1) — iOS Info.plist
- Thêm `CFBundleLocalizations = [en, vi]` + `CFBundleAllowMixedLocalizations = true`.

### D (P1) — Chống nhấp nháy cold start
- Trong `main()`: mở box `app_settings`, đọc `locale` **trước `runApp`**, truyền vào `LocaleProvider(initialLocale:)` thay vì load async sau build (`locale_provider.dart:11-22`).

### D2/D3 (UI + format) — theo design.md + decision log
- `kAppLanguages` (`language_toggle_button.dart:18-22`): bỏ field `flag`, thêm `englishName` (tên phụ); render chip chữ từ `code`. Pill System default → `🌐 {resolvedCode}`.
- Áp bảng format ngày D3.

### E/F/G (P2)
- E: dùng lại `languageSystemDesc` làm dòng phụ mục System (hoặc xoá nếu không dùng); `languageEnglish`/`languageVietnamese` xoá (picker hardcode endonym).
- F: pill System default (gộp trong D2).
- G: (khi có analytics) log event `language_changed {from, to}`.

## Thay đổi dữ liệu
- `users/{uid}/devices/{id}`: **thêm field `languageCode`** (string, vd "vi"/"en").

## Checklist implement
- [x] A: init date formatting + thay DateFormat
- [~] B: lưu languageCode + sửa function (đã code) · ⏳ **chưa deploy** (cần user/PO)
- [x] C: Info.plist
- [x] D: preload locale
- [x] D2/D3: chip chữ + format ngày
- [x] E/F: dọn dẹp (E: bỏ languageEnglish/languageVietnamese, dùng languageSystemDesc; F: pill System → "🌐 {mã}")
- [ ] G: analytics (ngoài phạm vi lượt này — chưa có analytics)
- [x] `flutter analyze` sạch (0 issues) · không hardcode chuỗi/ngôn ngữ

## Nhật ký implement
- [2026-05-30] [PO→Dev] Bàn giao kế hoạch kỹ thuật; chờ Dev bắt đầu (ưu tiên A + B).
- [2026-05-30] [Dev] Fix BUG-1: thêm key fullDateFormat (vi 'd thg M, y' / en 'MMM d, y'), áp vào home/profile thay yMMMd.
- [2026-05-30] [Dev] Code xong gap A/C/D/D2/D3/E/F; gap B đã viết code (client + function) **chờ deploy**; gap G để lại (chưa có analytics).
  - **A (ngày theo locale):** `main.dart` thêm `initializeDateFormatting()` ở `main()` (trước runApp) + set `Intl.defaultLocale = resolved.languageCode` trong `localeResolutionCallback`. `gallery_screen.dart` (2 chỗ `_formatFeedDate`) dùng `l10n.feedDateFormat` + locale code (bỏ "thg" hardcode). Home/Profile `_formatDate` dùng `DateFormat(context.l10n.fullDateFormat)` (key fullDateFormat đã có ở BUG-1) — đã **thêm getter `fullDateFormat`** vào 3 file generated (`app_localizations.dart/_en/_vi`) vì project tắt flutter:generate nên gen-l10n không chạy được; đồng thời dọn 2 getter `feedDateFormat` bị trùng trong abstract class.
  - **D (chống nhấp nháy):** `main.dart` đọc Hive box `app_settings` key `locale` qua `_readSavedLocale()` TRƯỚC runApp, truyền `initialLocale` vào `LocaleProvider(initialLocale:)`; `LocaleProvider` đổi constructor nhận `initialLocale` (bỏ `_loadLocale()` async).
  - **C (iOS):** `ios/Runner/Info.plist` thêm `CFBundleLocalizations [en, vi]` + `CFBundleAllowMixedLocalizations = true`.
  - **D2/D3 (UI):** `language_toggle_button.dart` bỏ field `flag` khỏi `AppLanguage`/`kAppLanguages`; thêm `_LanguageChip` (44×44, radius 14, nền accentRose 0.10, chữ accentLove w800; System dùng 🌐); picker row có dòng phụ `languageSystemDesc` cho mục System; pill auth System hiện "🌐 {mã resolve}" thay "—". `profile_screen.dart` card ngôn ngữ render chip chữ/🌐 thay `current.flag`.
  - **E/F (dọn):** bỏ key `languageEnglish`/`languageVietnamese` trong 2 ARB + 3 file generated; giữ + dùng `languageSystemDesc`.
  - **B (push — CODE, KHÔNG DEPLOY):** client `push_notification_service.dart` thêm `_currentLanguageCode` (từ `Intl.defaultLocale`, fallback device→'vi') truyền `languageCode` xuống `user_service.saveDeviceRegistration` → ghi field `languageCode` vào `users/{uid}/devices/{id}`. Function `functions/index.js`: đọc `languageCode` từng device người nhận, `buildPhotoNotificationText()` chọn copy theo map `{vi, en}` fallback `vi`, gửi `sendEach` (per-device) thay `sendEachForMulticast`. ⚠️ Có comment `// TODO deploy: cần firebase deploy --only functions` — **CHƯA chạy deploy**.
  - **Kiểm tra:** `flutter analyze` → **0 issues**; `node --check functions/index.js` → OK.
- [2026-10-11] [Dev] **Rà văn phong toàn app theo luật 7** (user: "rà soát lại ngôn ngữ toàn bộ app trong source code sau đó chỉnh sửa lại văn phong"). 9 agent biên tập chạy song song theo một bộ quy tắc chung (xưng hô bạn/người ấy/chúng mình, cấm cụm sáo AI, bỏ chữ kỹ thuật lộ ra người dùng, giữ placeholder, nhãn ngắn không dài quá +15%, giữ tên tính năng). Agent ARB chỉ xuất bản vá JSON; main session soát từng chuỗi rồi mới áp (script kiểm placeholder trước khi ghi).
  - **ARB:** 206 chuỗi VI + 4 chuỗi EN sai rõ (vd "Today is the {day}th day" → "lunar day {day}", camera nhắc "Simulator" cho người dùng thật). Nhiều nhất là lỗi đăng nhập/ghép đôi/đăng ảnh lộ "Firebase", "local fallback", "deploy `storage.rules`" → lời thường. EN `remindersV2MilestoneYearsLabel` thêm số nhiều (hết "Next: 1 years").
  - **Dấu thanh:** chốt kiểu mới (Xoá, Huỷ, tuỳ, hoà, khoẻ) — sau bản vá kiểu mới đã chiếm 61 chỗ, đổi nốt 14 chỗ kiểu cũ trong ARB + 2 câu hỏi.
  - **Xoá 225 key không còn code nào gọi** (lời chào xoay vòng, love note cũ, màn hồ sơ cũ…) khỏi cả 2 ARB → còn 1.003 key. Kiểm bằng grep `.<key>` toàn `lib/` + `test/` và `flutter analyze` 0. Muốn lấy lại key nào thì xem git history trước commit này.
  - **Ngân hàng câu hỏi:** 69/229 câu `daily_questions.dart`, 63/150 câu `daily_questions_extra.dart`, 51/88 mẫu `question_templates.dart`, 14 chuỗi "nhìn lại" `revisit_templates.dart`. Thứ tự/số câu/EN giữ nguyên (id câu = vị trí, đã lưu `askedBankIds`). Map `kMoodWordVi`: `meh` "là lạ, không rõ ràng" → "bình thường", `loved` → "hạnh phúc" (khớp nhãn mood người dùng chọn). Mẫu `gratitude_partner:1` trùng y câu #2 của ngân hàng → đổi cách hỏi. EN "Women Day" → "Women's Day".
  - **Chữ viết cứng:** `reminder_provider.dart` 20 chuỗi lời nhắc riêng (giữ giọng "Anh By"/"embe", giữ độ dài pool vì code xoay vòng theo độ dài). `app_time_picker.dart` trước đây viết cứng "Chọn giờ nhắc / Huỷ / Xác nhận" → máy tiếng Anh vẫn thấy tiếng Việt; nay qua l10n (`timePicker*`).
  - **Cloud Functions:** 24 chuỗi (push + lỗi `HttpsError` hiện thẳng lên màn) + 3 chuỗi email; push tâm trạng giờ đọc "Anh Tuấn đang thấy nhớ bạn"; prompt `generateDailyQuestion` thêm 3 dòng luật văn phong cho câu hỏi AI. ✅ Deploy DEV (kèm xoá function mồ côi `notifyPartnerNudge` trên DEV). **PROD chờ lệnh.**
  - **Kiểm:** `flutter analyze` 0 · `flutter test` 163/163 · gen-l10n sạch.
  - **Phát hiện chưa sửa (cần quyết):**
    1. 🔴 Nhiều chỗ `exception.message ?? l10n.X` → khi Firebase trả message, người dùng thấy câu tiếng Anh thô, chuỗi tiếng Việt gần như không bao giờ hiện (luồng đăng nhập/ghép đôi). `setupErrorSaveCouple`/`setupErrorJoinCouple` còn nhét nguyên `{error}` kỹ thuật vào câu. Cần Dev sửa code.
    2. 🔴 Lỗi `HttpsError` của Cloud Functions chỉ có tiếng Việt → máy tiếng Anh thấy tiếng Việt.
    3. 🟡 Mẫu câu hỏi nhóm tâm trạng lấy mood của "người ấy" theo máy tạo câu hỏi rồi lưu chung → người đặt mood đọc "người ấy thấy mệt" về chính mình (lỗi engine).
    4. 🟡 Mẫu "nhìn lại" nói "Đúng một năm trước" nhưng `pickRevisitDate` chọn lệch tới ±2 ngày (không ưu tiên ngày khớp đúng).
    5. 🟡 Tiêu đề "Thắp ngọn lửa đầu tiên" dùng lại cho cặp đôi bắt đầu chuỗi mới ("đầu tiên" sai) → cần key riêng.
    6. 🟡 Chữ nói sai cơ chế Cây Tình Yêu: "Mỗi tấm ảnh là một bông hoa mới" (hoa chỉ nở ở mốc 1/10/25/50/100 ảnh), ô "Cùng trò chuyện" ngầm nói chat làm cây lớn. PO quyết.
    7. 🟢 Tên gọi lệch: tab "Kỷ niệm" ↔ chip "THƯ VIỆN ẢNH" ↔ "Xem trong Thư viện"; EN gọi người yêu 4 kiểu (partner/love/person/they); "Cũng nhắc người ấy" → đề xuất "Nhắc cả người ấy" (đã nằm trong release notes 1.4.0 nên chưa đổi). User chốt.
