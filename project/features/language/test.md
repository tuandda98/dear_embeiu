# 🧪 Test — Language v2

> Tester sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md) + [dev.md](dev.md). CHỈ test, KHÔNG sửa code. Output: PASS/FAIL + bug report.

- **Trạng thái test:** 🧪 Rà văn phong 2026-10-11 (commit `f62e907`): Tester vòng 1 FAIL (0 chặn · 3 nhỏ) → Dev đã vá, chờ vòng 2 (xem cuối file). Language v2: ✅ PASS (2026-05-31). Static: flutter analyze sạch (4 blocker cũ đã fix). Runtime (user test): switch ngôn ngữ / ngày tháng / cold start / iOS Settings / push 2 máy — pass. Functions đã deploy. → PO FINAL VERIFY OK → ✅ Done.
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

## Nghiệm thu vòng 1 — commit `f62e907` "fix(copy)", mục 1–5 · 2026-10-11 · Master Tester

**Kết luận: FAIL — 0 chặn · 0 lớn · 3 nhỏ.** Cả năm mục chạy đúng như `dev.md` mô tả, analyze, test và rules đều xanh. #1 và #2 nằm trong phạm vi mục 1 và mục 4, nên trả Dev sửa (mỗi lỗi 1–3 dòng). #3 có từ trước, ngoài diff, PO có thể ghi nợ.

### Lỗi

| # | Mức | Chỗ | Kịch bản → hậu quả | Gợi ý sửa |
|---|---|---|---|---|
| 1 | Nhỏ | `lib/services/auth_service.dart:726-740` (`_mapCallableError`, heuristic ở dòng 735) | ID token bị server từ chối → framework `firebase-functions` 6.6.0 tự trả `unauthenticated` + "Unauthenticated" (`functions/node_modules/firebase-functions/lib/common/providers/https.js:461`), không đi qua `CALLABLE_ERROR_COPY`. Chuỗi chỉ viết hoa chữ đầu nên không bị heuristic chặn → màn Xác thực email (`verify_email_screen.dart:175`) hiện chữ tiếng Anh "Unauthenticated" trên máy tiếng Việt. Cùng kiểu với "Bad Request", "Internal Error", "Permission Denied" nếu sau này bật `enforceAppCheck`/`authPolicy`. | Thêm `case 'unauthenticated': return AppL10n.strings.authSessionNotReady;` vào switch đầu hàm (CF của mình cũng chỉ dùng mã này với nghĩa "cần đăng nhập"). Thêm 1 unit test cho hàm này, hiện chưa có test nào. |
| 2 | Nhỏ | `lib/services/revisit_question_source.dart:223` (mốc năm = `base − 365 ngày`), `:328` (`exact`); mẫu `lib/data/revisit_templates.dart:56,74` | Từ 01/03/2028 đến 28/02/2029 (365 ngày), "365 ngày trước" lệch 1 ngày so với "cùng ngày năm ngoái". Hôm nay 24/12/2028: marker 25/12/2027 → `exact=true` → "Ngày này năm ngoái, chúng mình đã trả lời…" (thật ra là ngày 25/12). Marker 24/12/2027 → `exact=false` → "Khoảng một năm trước". Mục 4 chỉ đúng ngoài giai đoạn năm nhuận. | Mốc năm dùng `monthsAgo(base, 12)` (đã xử lý 29/02) thay cho trừ 365 ngày. Thêm test cho ngày 2028-12-24. Hàm vẫn thuần nên 2 máy vẫn ra cùng kết quả. |
| 3 | Nhỏ (có từ trước, ngoài diff) | `lib/screens/settings_screen.dart:1128` + `:1157`; `lib/providers/auth_provider.dart:362-364` | Xoá tài khoản → callable trả `unauthenticated` → hiện hộp thoại nhập lại mật khẩu → nhập đúng → lần gọi lại vẫn `unauthenticated` (token vẫn bị từ chối, hoặc sau này bật enforce App Check). Provider trả sentinel `'requires-recent-login'`, dialog gán thẳng vào `errorText` → dưới ô mật khẩu hiện chữ `requires-recent-login`. | Trong dialog, khi `result == 'requires-recent-login'` thì xử lý như nhánh `session-gone`: đóng dialog, hiện `deleteAccountSessionExpiredMsg`, đưa về auth gate. |

**Tái hiện**
- #1 (nhánh Firebase, DEV):
  1. Gửi `POST https://us-central1-tonyembeiu-dev.cloudfunctions.net/sendCustomVerificationEmail` với header `Authorization: Bearer not-a-real-token` và body `{"data":{"languageCode":"vi"}}`.
  2. Server trả `{"error":{"message":"Unauthenticated","status":"UNAUTHENTICATED"}}`. [VERIFIED runtime DEV]
  3. Phía client: "Unauthenticated" khác bản viết hoa "UNAUTHENTICATED" → `_mapCallableError` trả nguyên văn → `AuthProvider.errorMessage` → SnackBar màn Xác thực email. [VERIFIED code]
  4. Trên máy thật: dùng tài khoản chưa xác thực, chỉnh lùi đồng hồ máy hơn 1 giờ rồi bấm "Gửi lại". [CẦN TEST runtime]
- #2 (thuần client, cả hai nhánh):
  1. `pickRevisitDate(today: DateTime(2028,12,24), availableDateKeys: ['2027-12-25'])` → `exact == true`. Với `['2027-12-24']` → `exact == false`.
  2. `renderRevisitQuestion(bucket: d365, exact: true, seedKey: 'couple-1|2028-12-24')` → "Ngày này năm ngoái, chúng mình đã trả lời…". [VERIFIED bằng test tạm ngoài repo]
- #3 (nhánh Firebase): mới kiểm ở mức code. Cần ép callable trả `unauthenticated` lần thứ hai (emulator, hoặc tạm bật `enforceAppCheck` trên DEV). [CẦN TEST runtime]

### Câu nên viết lại

| Key / chỗ | Hiện tại | Đề xuất | Lý do |
|---|---|---|---|
| `authFirebaseAuthGeneric` (EN) | Something went wrong with your account. Please try again. | Couldn't verify your account. Please try again. | Câu hiện tại nghe như tài khoản bị hỏng. Bản VI nói "Có lỗi khi xác thực tài khoản". Đây là câu mặc định cho mọi mã lạ khi đăng nhập, đăng ký và nhập lại mật khẩu. |
| `authFirestoreUnavailable`, `coupleFirebaseUnavailable`, `photoFirebaseUnavailable` (EN) | Can't reach the server right now, maybe a network hiccup. Please try again in a few minutes. | Can't reach the server right now. It might be a network hiccup, so try again in a few minutes. | Vế "maybe a network hiccup" đứng lửng sau dấu phẩy, chưa thành câu. |
| `authUserDisabled` (VI) | Tài khoản này đang bị khoá nên chưa đăng nhập được. | Tài khoản này đã bị khoá nên không đăng nhập được. | "đang… chưa…" ngầm hứa là tạm thời, trong khi tài khoản bị vô hiệu hoá chỉ mở lại được từ phía quản trị. |
| `photoStorageUnauthorized` (VI / EN) | Máy chủ đang từ chối thao tác với ảnh này. / The server won't allow this action on the photo. | Chưa làm được việc này với ảnh. Bạn thử đăng xuất rồi đăng nhập lại nhé. / You can't do that with this photo right now. Try signing out and back in. | "thao tác", "máy chủ từ chối" là chữ kỹ thuật, và câu không chỉ bước tiếp theo. Gallery đã nén ảnh xuống 1920px nên lỗi này gần như chỉ do quyền hoặc phiên đăng nhập (giống `photoSyncPermissionDenied`). |
| `sleepHowBody1` (VI) | …Khoảng nào xong trước 1 giờ sáng, như lúc để sạc buổi tối, chỉ được tính khi không còn khoảng nào khác. | …Khoảng nằm yên kết thúc trước 1 giờ sáng (như lúc cắm sạc buổi tối) chỉ được tính khi đêm đó không có khoảng nào muộn hơn. | Chữ "xong" dùng cho một khoảng thời gian nghe lạ. "không còn khoảng nào khác" cũng hơi sai so với code và bản EN ("nothing later"): có 2 khoảng buổi tối thì app vẫn lấy khoảng dài hơn. |
| `sleepHowBody1Ios` (VI) | Giấc chợp mắt xong trước 1 giờ sáng chỉ được tính khi cả đêm không có giấc nào khác. | Giấc chợp mắt kết thúc trước 1 giờ sáng chỉ được tính khi đêm đó không có giấc nào muộn hơn. | Cùng lý do với dòng trên. |
| `sleepHowBody1` (EN) | (6 pm to 2 pm, 3 to 16 hours) | between 6 pm and 2 pm the next day, lasting 3 to 16 hours | Hai khoảng số trong cùng một ngoặc dễ đọc nhầm. |
| `mood_partner` topic `understand` (tuỳ chọn) | …Những ngày như vậy, bạn thường cần gì nhất? / On days like that, what do you need most? | …Những ngày như vậy, điều gì làm bạn thấy dễ chịu nhất? / On days like that, what makes you feel most at ease? | Mẫu áp cho cả 8 mood. Với "vui", "hạnh phúc", "bình yên", hỏi "những ngày vui bạn cần gì nhất" nghe lạ. |
| 4 mẫu `mood_partner` (tuỳ chọn) | Cả 4 mẫu đều mở bằng "một người trong chúng mình" | Giữ 2 mẫu, đổi 2 mẫu còn lại sang "Hôm nay có người đang thấy %mood% đó." | Lặp một cụm ở mọi biến thể nên đọc hơi cứng. "Có người…" là cách nói trêu nhau rất đời thường, và đọc từ máy nào cũng đúng. |

### Đã kiểm, đạt
- **Mục 1, các mapper:** `auth_service.dart:671-719`, `couple_service.dart:547-558` + `:947-975`, `photo_service.dart:406-423`. Nhánh mặc định chỉ `debugPrint` và trả câu l10n. `user-disabled` → `authUserDisabled`. [VERIFIED]
- **Grep toàn `lib/`:** không còn `$e`, `e.toString()` hay `snapshot.error` nào hiện lên UI. Mọi `e.message` ở provider/screen đều thuộc `AuthException`/`CoupleException`/`PhotoSyncException`, và mọi chỗ `throw` mấy exception này đều dùng `AppL10n.strings`. Không còn chuỗi lỗi viết cứng gán cho `_errorMessage` hay đưa vào SnackBar. Ngoại lệ duy nhất là lỗi #3. [VERIFIED]
- **FirebaseAuth:** app chỉ đăng nhập bằng email + mật khẩu. Các mã đã map đủ cho mọi lệnh app gọi: email-already-in-use, operation-not-allowed, configuration-not-found, invalid-email, weak-password, user-not-found, wrong-password, invalid-credential, too-many-requests, network-request-failed, user-disabled. `user-token-expired` và `requires-recent-login` rơi về câu chung, chấp nhận được. [VERIFIED]
- **Mã lỗi SDK khớp mô tả của Dev:** Android IOException → `unavailable` (`cloud_functions-6.3.3/android/.../FlutterFirebaseFunctionsPlugin.kt:132-135`); iOS lỗi ngoài domain functions → `unknown` + câu của hệ điều hành (`FirebaseFunctionsPlugin.swift:156-176`). [VERIFIED]
- **Heuristic "viết hoa toàn bộ" không nuốt nhầm câu của server:** 22/22 câu đều có chữ thường nên khác bản viết hoa, kể cả câu VI viết hoa chữ đầu. [VERIFIED, chạy bằng Dart]
- **Bản app cũ:** 1.7.1 gọi `deleteAccount` không kèm data → CF rơi về tiếng Việt như trước (không hồi quy). 2 callable email ở bản cũ vốn đã gửi `languageCode` → máy EN nhận lỗi tiếng Anh ngay sau khi deploy PROD. `callableErrorCopy` không crash khi data là null, chuỗi, mảng hay số. [VERIFIED]
- **Bảng CF:** đủ vi + en cho cả 11 nhánh `HttpsError` của 3 callable. Lỗi không được bắt ra "INTERNAL" → client dùng câu dự phòng. Các callable còn message cứng (`leaveCoupleCleanup`, `migrateLoveNotesToChat`, `generateDailyQuestion`, `nudgeRpsPlayer`) đều bị client nuốt lỗi, kể cả ở v1.4.0+15 và release/1.7.1. [VERIFIED]
- **"Nhìn lại":** lệch ±1/±2 → `exact=false`, lệch ±3 bị loại, đúng cho cả mốc 365, 100 và 30. Ngày tháng trước gắn nhóm `month` + `exact=true`. Hoà ±1 thì chọn theo seed, 2 máy ra cùng một ngày. Mẫu "khoảng" không quá 280 ký tự. Riêng giai đoạn năm nhuận thì sai, xem lỗi #2. [VERIFIED bằng test tạm]
- **Tâm trạng:** 4 mẫu không còn "người ấy"/"your partner". `kMoodWordVi` không còn chữ "bạn". Từ EN cho `missing` là "a little lonely". [VERIFIED]
- **`everHadStreak`** (`streak_provider.dart:273-279`): true khi có ít nhất một ngày `bothAnswered` trong 180 marker mới nhất; đặt lại khi `clear()` hoặc khi cặp đang chờ, nên cờ không dính từ cặp cũ sang cặp mới. Sheet chọn đúng `streakSheetRestartTitle` + `streakSheetRestartBody`. [VERIFIED]
- **i18n:** 2 ARB cùng 1.036 key, 0 lệch placeholder, file generated khớp ARB. [VERIFIED]
- **Văn phong các dòng mới:** không có "hai đứa", không có cụm sáo rỗng. [VERIFIED]
- **Bảo mật:** CF chỉ chọn câu từ bảng tĩnh, không phản chiếu input. Quên mật khẩu vẫn chống dò email. [VERIFIED]

### Rủi ro (không phải lỗi chặn)
- **R1, marker khi 2 máy chạy 2 bản khác nhau:** máy chạy bản ≤1.7.1 chọn câu trước thì cả hai thấy câu cũ. Marker không đổi được nữa. Hết khi cả hai lên bản mới (`autoStoreForce`).
- **R2:** bản đã phát hành vẫn hiện `e.message` thô (Dev đã ghi nhận).
- **R3, thứ tự deploy:** client mới chạy với CF PROD cũ thì máy EN vẫn thấy lỗi tiếng Việt từ CF. Cần deploy `functions:deleteAccount,functions:sendCustomVerificationEmail,functions:sendCustomPasswordResetEmail --project prod` trước hoặc cùng lúc phát hành.
- **R4:** `everHadStreak` chỉ nhìn 180 marker mới nhất (nợ cũ D-PO-1). Rất hiếm.

### Số liệu thật
- `flutter analyze` (Flutter 3.41.6): No issues found.
- `flutter test`: 205/205 pass. Riêng `revisit_question_source_test` + `question_engine_test`: 58/58.
- `scripts/test-firebase-rules.sh`: 330 passing, `functions/index.js` cú pháp OK.
- ARB: 1.036 key mỗi file, 0 key lệch, 0 placeholder lệch.
- Gọi DEV 5 request không tác dụng phụ: `{email:'', lang:'en'}` → "That email isn't valid."; `{email:'', languageCode:'en'}` → tiếng Anh; `{email:''}` → "Email không hợp lệ."; `deleteAccount` không đăng nhập + `lang:'en'` → "Please sign in to delete your account."; token hỏng → "Unauthenticated".

### Cần test tay
1. Máy VI và máy EN trên DEV: đăng nhập sai mật khẩu, email chưa đăng ký, tắt mạng, tài khoản bị Disable ở Console → câu l10n đúng ngôn ngữ.
2. Quên mật khẩu trên máy EN: email có thật, email không tồn tại (vẫn báo đã gửi), tắt mạng → câu báo lỗi mạng.
3. Xác thực email → "Gửi lại" khi tắt mạng, cả Android lẫn iOS.
4. Xoá tài khoản trên máy EN: tắt mạng → câu báo lỗi mạng. Đi hết luồng nhập lại mật khẩu.
5. Setup: tạo cặp, nhập mã sai, tắt mạng giữa chừng, đổi ảnh đôi bị lỗi → câu l10n.
6. Sheet chuỗi: cặp từng có chuỗi nhưng đã nghỉ 3 ngày → "Thắp lại ngọn lửa"; cặp mới → "Thắp ngọn lửa đầu tiên".
7. Câu hỏi tâm trạng trên 2 máy cùng bản mới → cùng một câu; với một máy 1.7.1 mở trước → câu cũ (R1).
8. "Nhìn lại khoảng": seed DEV một marker lệch 1–2 ngày so với mốc → câu "Khoảng…".
9. Câu giải thích giấc ngủ trên màn nhỏ (Android) và iOS.
10. Sau khi deploy PROD 3 function: chạy lại mục 2–4 trên bản release.

- [2026-10-11] [Dev → Tester] Đã vá #1 (`unauthenticated` → `authSessionNotReady`, hàm thành `AuthService.mapCallableError` + 2 test), #2 (mốc năm = `monthsAgo(base, 12)` + test 24/12/2028 và 29/02/2028), #3 (dialog coi `requires-recent-login` lần hai như `session-gone`) và viết lại các câu ở bảng trên (riêng mẫu tâm trạng: đổi 2/4 mẫu sang "Hôm nay có người đang thấy … đó"; EN giữ "One of us"). Chờ Tester vòng 2.
