# 🧪 Test — Language v2

> Tester sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md) + [dev.md](dev.md). CHỈ test, KHÔNG sửa code. Output: PASS/FAIL + bug report.

- **Trạng thái test:** ✅ PASS (2026-05-31). Static: flutter analyze sạch (4 blocker cũ đã fix). Runtime (user test): switch ngôn ngữ / ngày tháng / cold start / iOS Settings / push 2 máy — pass. Functions đã deploy. → PO FINAL VERIFY OK → ✅ Done.
  - *Lịch sử:* [2026-05-30] FAIL — 4 lỗi compile (generated-l10n + call-site lệch pha) → Dev fix xong.
- **Người/role:** Master Tester

## Phạm vi test
Toàn bộ feature Language v2: switch ngôn ngữ, ngày tháng theo locale, push đa ngôn ngữ, cold start, UI chip chữ.

## Test case
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Profile → đổi EN | Toàn app sang EN tức thì, không restart | ⏳ runtime (chặn bởi BLOCKER #0 — chưa build được) |
| 2 | happy | Đổi VI | Toàn app sang VI | ⏳ runtime (chặn bởi #0) |
| 3 | happy | Chọn "System default" | App theo ngôn ngữ máy | ⏳ runtime (chặn bởi #0) |
| 4 | ngày tháng | EN: Home/Gallery/Profile | Format EN, KHÔNG còn "thg" | ⏳ runtime — code ĐÚNG hướng (dùng `l10n.fullDateFormat`/`feedDateFormat`) nhưng chặn bởi #0; verify được khi build |
| 5 | ngày tháng | VI: hiển thị "thg" đúng chỗ | Đúng VI | ⏳ runtime (chặn bởi #0) |
| 6 | ngày tháng | Đổi qua lại EN↔VI nhiều lần | Ngày luôn khớp ngôn ngữ hiện tại | ⏳ runtime (chặn bởi #0) |
| 7 | push | Người nhận EN, partner đăng ảnh | Notification tiếng Anh | ⏳ runtime — function + client đã có logic; cần 2 máy + deploy |
| 8 | push | Người nhận VI | Tiếng Việt | ⏳ runtime |
| 9 | push | System default + máy EN | Tiếng Anh | ⏳ runtime |
| 10 | 2 thiết bị couple | 2 máy đặt 2 ngôn ngữ khác nhau | Mỗi máy nhận đúng ngôn ngữ của mình | ⏳ runtime (cần 2 máy couple) |
| 11 | push | Caption có/không | Body fallback đúng | ⏳ runtime |
| 12 | cold start | Chọn EN → kill → mở lại | Vào thẳng EN, KHÔNG nháy VI frame đầu | ✅ pass (static) — gap D đã fix: `main.dart:37,61` preload `LocaleProvider.loadInitialLocale()` trước `runApp`, `LocaleProvider(initialLocale:)` (`locale_provider.dart:11,15`). Cần xác nhận runtime. |
| 13 | fresh install | Chưa chọn ngôn ngữ | Theo ngôn ngữ máy | ✅ pass (static) — `loadInitialLocale` trả null → `localeResolutionCallback` theo máy |
| 14 | negative | Máy đặt 'fr' + System default | Fallback `en` (supportedLocales.first), không crash | ✅ pass (static) — `localeResolutionCallback` trả `supportedLocales.first`=en (`main.dart`) |
| 15 | offline | Đổi ngôn ngữ khi offline | UI đổi (local); push test khi có mạng lại | ⏳ runtime |
| 16 | iOS | Settings → app → Preferred Language | Hiện đủ EN/VI (sau gap C) | ✅ pass (static) — gap C đã fix ĐÚNG: `Info.plist:13-19` có `CFBundleLocalizations` = `<array>[en, vi]</array>` + `CFBundleAllowMixedLocalizations` = `<true/>`; `plutil -lint` OK. Cần xác nhận trên iOS thật. |
| 17 | layout | Text VI dài hơn | Không vỡ/tràn ở Home, Profile, picker | ⏳ runtime |
| 18 | UI | Picker & pill | Không còn cờ; hiện chip EN/VI/🌐 đúng 3 state | ⏳ runtime — pill/picker đã chuyển sang letter-chip + globe (`language_toggle_button.dart`), NHƯNG Profile card vẫn dùng `.flag` đã xoá → BLOCKER #0 (Bug #0c) |
| 19 | UI | Ngày Home/Profile | EN "May 30, 2026" / VI "30 thg 5, 2026" | ⏳ runtime — arb `fullDateFormat` đúng ("MMM d, y" / "d 'thg' M, y") nhưng chặn bởi #0 (getter chưa generate) |
| 20 | UI | Feed/gallery | Đúng `feedDateFormat` 2 ngôn ngữ | ✅ pass (static) — `gallery_screen.dart:275,1652` dùng `context.l10n.feedDateFormat`; getter `feedDateFormat` CÓ trong generated. Cần xác nhận runtime. |

*(Kết quả: ✅ pass · ❌ fail · ⏳ cần runtime)*

### Tóm tắt verdict: ❌ **FAIL — 1 BLOCKER: app KHÔNG COMPILE** (5 pass-static / 1 fail-static / 14 cần-runtime, runtime bị chặn bởi blocker build)
Dev đã làm phần lớn feature ĐÚNG HƯỚNG (gap A date-format, B push i18n cả client+function, C Info.plist, D preload locale, D2 chip chữ + globe, D3 format ngày, E dùng lại key). Logic push 2 đầu CHÍNH XÁC (client `_currentLanguageCode` fallback "vi"; function `buildPhotoNotificationText` map en/vi fallback vi, gửi per-token bằng `sendEach`); Info.plist gap C đúng cú pháp. **Nhưng project KHÔNG BUILD** vì generated-l10n & vài call-site lệch pha (Bug #0, 4 lỗi `dart analyze`). Sửa Bug #0 → build sạch → mới test runtime được. (1 fail-static = case #18 picker do Bug #0c, sẽ tự hết khi sửa #0c.)

**`dart analyze` (full project) = 4 errors:**
- `lib/screens/home_screen.dart:1070:36` — getter `fullDateFormat` không tồn tại trên `AppLocalizations` (undefined_getter)
- `lib/screens/profile_screen.dart:1296:36` — getter `fullDateFormat` không tồn tại (undefined_getter)
- `lib/screens/profile_screen.dart:764:37` — getter `flag` không tồn tại trên `AppLanguage` (undefined_getter)
- `lib/services/push_notification_service.dart:206:9` — named param `languageCode` chưa được định nghĩa ở `saveDeviceRegistration` (undefined_named_parameter)

(Lưu ý quy trình: `flutter analyze` chạy lần đầu báo "No issues found!" là KẾT QUẢ SAI do cache/sandbox; `dart analyze` mới là nguồn đúng — đã đối chiếu trực tiếp source.)

Có thư mục `test/` (auth_service_test, couple_model_test, photo_model_test, widget_test) nhưng KHÔNG có test cho feature language; `flutter test` sẽ fail vì project không compile.

## Acceptance tổng
Không còn bất kỳ chuỗi/ngày/notification nào cố định 1 ngôn ngữ khi user đã chọn ngôn ngữ khác.

## Bug report (nếu FAIL)

### Bug #0 — BLOCKER: app KHÔNG COMPILE (4 lỗi, generated-l10n & call-site lệch pha) — Critical
Tổng hợp 4 lỗi `dart analyze`; tất cả phải sửa trước khi test runtime.

- **#0a — `fullDateFormat` chưa được generate.** `lib/l10n/app_en.arb:305` & `app_vi.arb:305` đã có key `fullDateFormat` ("MMM d, y" / "d 'thg' M, y"), nhưng các file generated `lib/l10n/app_localizations.dart` / `_en.dart` / `_vi.dart` CHƯA có getter này (grep `fullDateFormat` trong generated = rỗng). Dùng tại `home_screen.dart:1070` và `profile_screen.dart:1296` (`DateFormat(context.l10n.fullDateFormat)`). → Dev quên chạy `flutter gen-l10n` (hoặc repo hand-maintain generated nhưng quên thêm tay). Lưu ý `feedDateFormat` ĐÃ có trong generated nên gallery ok — chỉ `fullDateFormat` bị sót.
- **#0b — named param `languageCode` chưa có ở `saveDeviceRegistration`.** `push_notification_service.dart:205` truyền `languageCode: _currentLanguageCode()`, nhưng `user_service.dart:93-99` signature `saveDeviceRegistration({userId, deviceId, token, platform, notificationsEnabled})` KHÔNG có `languageCode`, và payload ghi Firestore (`:100-104`) cũng KHÔNG ghi field này. → Dev sửa call-site nhưng quên cập nhật service: (1) thêm `String? languageCode` vào signature, (2) ghi `'languageCode': languageCode` vào doc `users/{uid}/devices/{id}`.
- **#0c — getter `flag` đã bị xoá khỏi `AppLanguage` nhưng còn dùng.** `language_toggle_button.dart:18-47` đã refactor `AppLanguage` (bỏ `flag`, thêm `englishName`, có `appLanguageChip`/letter-chip + globe cho System), nhưng `profile_screen.dart:764` còn `Text(currentAppLanguage(localeProvider.locale).flag)`. → Đổi Profile card sang letter-chip/`appLanguageChip` giống pill (đồng bộ D2).
- **Severity:** Critical / Blocker — không build/run được; mọi case runtime bất khả thi tới khi sửa.
- **Steps to reproduce:** `dart analyze` → 4 lỗi; `flutter run` sẽ fail.

### Bug #1 (đã FIX — ghi lại để PO đối chiếu, KHÔNG còn là lỗi) — gap A
- `main.dart:36-37` đã set `Intl.defaultLocale` + gọi `initializeDateFormatting(resolved.languageCode)` trong `localeResolutionCallback` (import `package:intl/date_symbol_data_local.dart` + `package:intl/intl.dart` ở `:10-11`).
- `gallery_screen.dart:275,1652` đã dùng `context.l10n.feedDateFormat` (hết hardcode "thg").
- `home_screen.dart` / `profile_screen.dart` đã có `_formatDate(context, date)` dùng `context.l10n.fullDateFormat`.
- *Còn vướng:* getter `fullDateFormat` chưa generate → Bug #0a.

### Bug #2 (gap B — function) — KHÔNG còn lỗi static; LOGIC ĐÚNG, chỉ cần deploy + test runtime
- `functions/index.js:129` đọc `languageCode` của từng device; `:146-184` build per-device message qua `buildPhotoNotificationText(device.languageCode,...)` rồi gửi `admin.messaging().sendEach(messages)`.
- `functions/index.js:405-408` (`buildPhotoNotificationText`): `code === "en" ? "en" : "vi"` (fallback vi đúng); map `titles`/`bodies` đủ vi+en, caption truncate 120, body mặc định 2 ngôn ngữ. ✅ Logic chính xác theo spec gap B.
- **CHƯA DEPLOY:** trong file có `// TODO deploy: cần firebase deploy --only functions`. Phải deploy lại + test 2 máy (mục runtime).

### Bug #3 (gap B — client) → đã gộp vào Bug #0b
- Client OK: `push_notification_service.dart:268-272` getter `_currentLanguageCode` (Intl.defaultLocale → fallback "vi"), truyền tại `:206`. Chỉ thiếu service nhận & ghi field (Bug #0b).

### Bug #4 (đã FIX) — gap D cold start
- `main.dart:37,61` + `locale_provider.dart:11,15` đã preload locale trước `runApp`. PASS static (case #12); cần xác nhận runtime "không nháy frame đầu".

### Bug #5 (đã FIX) — gap C iOS Info.plist
- `ios/Runner/Info.plist:13-19` đã có `CFBundleLocalizations` = `<array><string>en</string><string>vi</string></array>` + `CFBundleAllowMixedLocalizations` = `<true/>`, cú pháp ĐÚNG, `plutil -lint` = OK. PASS static (case #16); cần xác nhận trên iOS thật.

### Bug #6 (phần lớn FIX, còn #0c) — D2/F UI chip
- `language_toggle_button.dart` đã bỏ cờ → letter-chip + globe; pill System dùng 🌐 + chip thay "—". CÒN `profile_screen.dart:764` dùng `.flag` (Bug #0c).

### Bug #7 (gap E) — ARB key chết
- `languageEnglish`, `languageVietnamese`, `languageSystemDesc` vẫn còn trong arb + generated. Theo design.md, `languageSystemDesc` được DÙNG LẠI (`language_toggle_button.dart:55` `appLanguageSecondary`) → hợp lệ. Còn `languageEnglish`/`languageVietnamese` vẫn là key chết (picker hardcode endonym) → nên xoá (P2, không chặn).

## Cần test runtime (sau khi Dev sửa Bug #0 → build lại)
- #1-6, 15, 17, 19: switch ngôn ngữ tức thì + ngày tháng đổi theo locale (EN không còn "thg", VI đúng "thg"), layout VI dài, đổi qua lại nhiều lần → 1 thiết bị thật.
- #12: cold start chọn EN → kill → mở lại, quan sát KHÔNG nháy VI frame đầu.
- #16: iOS Settings → app → Preferred Language hiện đủ EN/VI → thiết bị iOS thật sau khi build lại (Info.plist đã đúng static, chỉ cần xác nhận runtime).
- #7-11: push đa ngôn ngữ + caption fallback → 2 máy couple (máy A VI / máy B EN), **functions đã deploy lại**. Cách test: máy A đăng ảnh → kiểm tra notification trên B (kỳ vọng EN) và ngược lại; thử cả có/không caption.

## Nhật ký test
- [2026-05-30] [PO→Tester] Bàn giao bộ test case; chờ Dev hoàn thành để chạy.
- [2026-05-30] [Tester] Verify static toàn bộ code. KẾT LUẬN: ❌ FAIL — 1 BLOCKER (app KHÔNG COMPILE). Dev đã implement gần hết & ĐÚNG HƯỚNG (gap A/B/C/D/D2/D3 + dùng lại E; logic push 2 đầu chính xác; Info.plist gap C đúng). NHƯNG `dart analyze` = 4 lỗi compile: Bug #0a `fullDateFormat` chưa generate (quên `flutter gen-l10n`); #0b param `languageCode` chưa có ở `user_service.saveDeviceRegistration` + chưa ghi field Firestore; #0c `.flag` còn dùng ở `profile_screen.dart:764`. 5 case pass static (#12,13,14,16,20), 1 fail static (#18 do #0c — tự hết khi sửa #0c), còn lại cần runtime nhưng bị chặn bởi blocker. Trả lại Dev: (a) `flutter gen-l10n`; (b) thêm `languageCode` vào `saveDeviceRegistration` (signature + ghi Firestore); (c) đổi Profile card (`profile_screen.dart:764`) sang letter-chip thay `.flag`; (d) build sạch → test runtime + `firebase deploy --only functions`.
