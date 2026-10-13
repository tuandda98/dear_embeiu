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
    1. 🔴 Nhiều chỗ `exception.message ?? l10n.X` → khi Firebase trả message, người dùng thấy câu tiếng Anh thô, chuỗi tiếng Việt gần như không bao giờ hiện (luồng đăng nhập/ghép đôi). `setupErrorSaveCouple`/`setupErrorJoinCouple` còn nhét nguyên `{error}` kỹ thuật vào câu. Cần Dev sửa code. → ✅ **Đã sửa 2026-10-11** (mapper luôn trả câu l10n, bỏ `{error}`; xem mục Dev bên dưới).
    2. 🔴 Lỗi `HttpsError` của Cloud Functions chỉ có tiếng Việt → máy tiếng Anh thấy tiếng Việt. → ✅ **Đã sửa 2026-10-11** (bảng `CALLABLE_ERROR_COPY` theo `lang`/`languageCode`; DEV đã deploy, PROD chờ lệnh).
    3. 🟡 Mẫu câu hỏi nhóm tâm trạng lấy mood của "người ấy" theo máy tạo câu hỏi rồi lưu chung → người đặt mood đọc "người ấy thấy mệt" về chính mình (lỗi engine). → ✅ **Đã sửa 2026-10-11** (viết lại 4 mẫu theo góc "Một người trong chúng mình…").
    4. 🟡 Mẫu "nhìn lại" nói "Đúng một năm trước" nhưng `pickRevisitDate` chọn lệch tới ±2 ngày (không ưu tiên ngày khớp đúng). → ✅ **Đã sửa 2026-10-11** (ưu tiên ngày khớp đúng; lệch thì dùng câu "Khoảng…").
    5. 🟡 Tiêu đề "Thắp ngọn lửa đầu tiên" dùng lại cho cặp đôi bắt đầu chuỗi mới ("đầu tiên" sai) → cần key riêng. → ✅ **Đã sửa 2026-10-11** (key `streakSheetRestartTitle` "Thắp lại ngọn lửa").
    6. 🟡 Chữ nói sai cơ chế Cây Tình Yêu: "Mỗi tấm ảnh là một bông hoa mới" (hoa chỉ nở ở mốc 1/10/25/50/100 ảnh), ô "Cùng trò chuyện" ngầm nói chat làm cây lớn. PO quyết.
    7. 🟢 Tên gọi lệch: tab "Kỷ niệm" ↔ chip "THƯ VIỆN ẢNH" ↔ "Xem trong Thư viện"; EN gọi người yêu 4 kiểu (partner/love/person/they); "Cũng nhắc người ấy" → đề xuất "Nhắc cả người ấy" (đã nằm trong release notes 1.4.0 nên chưa đổi). User chốt.

- [2026-10-11] [Dev] **Sửa mục 1–5 của danh sách "Phát hiện chưa sửa" ở trên** (user chốt; mục 6, 7 giữ nguyên chờ PO/user).
  - **Mục 1 — lỗi Firebase tiếng Anh lọt ra màn.** Gốc nằm ở các mapper có nhánh `default: return exception.message ?? l10n.X`: Firebase luôn có `message` nên câu tiếng Việt gần như không bao giờ hiện. Sửa ngay tại mapper (mọi luồng đều đi qua): `auth_service._mapFirebaseAuthError` + `_mapFirestoreError`, `couple_service._mapFirebaseError` + `_mapPhotoSyncError` + nhánh default khi ghép đôi, `photo_service._mapFirebaseError` → luôn trả câu l10n, lỗi gốc chỉ `debugPrint`.
    - Mã `user-disabled` → key mới `authUserDisabled`. Các mã còn lại user nêu (wrong-password, invalid-credential, user-not-found, invalid-email, email-already-in-use, weak-password, too-many-requests, network-request-failed; permission-denied, unavailable) đã có câu riêng từ trước.
    - Callable: helper mới `AuthService._mapCallableError` cho `deleteAccount` + 2 callable email. Message của server được giữ (giờ đã theo ngôn ngữ, xem mục 2). Mã `unavailable`/`deadline-exceeded`/`unknown` (mất mạng: Android trả "UNAVAILABLE", iOS trả `unknown` + câu của hệ điều hành) → `authNetworkError`. Message rỗng hoặc toàn chữ hoa ("INTERNAL", "NOT FOUND" do SDK tự sinh khi function crash/chưa deploy) → câu dự phòng của từng màn.
    - `auth_provider`: 8 nhánh `catch (e)` đang ghép `'Sign in failed: $e'`… → câu l10n sẵn có (`authSessionUnavailable`, `authFirebaseUserCreateFailed`, `deleteAccountFailed`, `forgotPasswordNetworkError`, `verifyEmailResendError`, `signOutFailedMsg`, `authSessionNotReady`, `authFirebaseAuthGeneric`).
    - Bỏ lỗi kỹ thuật khỏi câu: `setup_screen` (`setupErrorSaveCouple`, `setupErrorJoinCouple`), `couple_provider` (`coupleSyncError`, `coupleLoadError`), `photo_provider` (stream lỗi đang gán thẳng `'$error'` → `photoSyncGeneric`). ARB: bỏ placeholder `{error}` ở 4 key này (cả VI + EN, viết lại câu cho trọn).
    - **Làm thêm, ngoài 5 mục:** 22 chuỗi EN của chính các key lỗi mà mapper trả về vẫn lộ chữ kỹ thuật (vd `couplePhotoUploadPermission` bảo người dùng "deploy `storage.rules`", `authFirebaseAuthGeneric` = "A Firebase Auth error occurred.") → viết lại theo nghĩa bản VI. Key `bootstrap*`/`*Local*` (chỉ hiện ở chế độ local fallback khi dev) giữ nguyên.
  - **Mục 2 — lỗi Cloud Functions chỉ có tiếng Việt.** `functions/index.js` thêm bảng `CALLABLE_ERROR_COPY` {vi, en} (cùng kiểu các bảng copy push) + `callableErrorCopy(request)`: đọc `data.lang`, thiếu thì `data.languageCode`, thiếu cả hai → tiếng Việt như cũ. Lý do đọc thêm `languageCode`: 2 callable email đã gửi trường này cho nội dung email từ lâu, nên cả bản app cũ chạy tiếng Anh cũng nhận lỗi tiếng Anh.
    - Áp cho `deleteAccount`, `sendCustomVerificationEmail`, `sendCustomPasswordResetEmail` (11 câu). Client: `deleteAccount` gửi thêm `{'lang': …}`; 2 callable email không cần đổi.
    - Không đụng: `leaveCoupleCleanup` (client nuốt lỗi từ bản đầu `bc07661`, chưa từng hiện lên màn), các callable message tiếng Anh nội bộ (`migrateLoveNotesToChat`, `nudgeRpsPlayer`, `generateDailyQuestion` — client không hiện), trigger `notifyPartnerLeft`.
    - ✅ **DEV deployed** 3 function (trace `20261010T192230Z`). Gọi thử endpoint DEV: `sendCustomPasswordResetEmail {email:'', lang:'en'}` → "That email isn't valid."; `{email:'', languageCode:'en'}` → tiếng Anh; không gửi ngôn ngữ → "Email không hợp lệ."; `deleteAccount` chưa đăng nhập + `lang:'en'` → "Please sign in to delete your account.", `data:null` → tiếng Việt. **PROD chờ lệnh:** `deploy --only functions:deleteAccount,functions:sendCustomVerificationEmail,functions:sendCustomPasswordResetEmail --project prod`.
  - **Mục 3 — câu hỏi tâm trạng.** Máy tạo câu thấy mood của "người ấy" nhưng câu lưu chung trên marker, nên người đặt mood đọc về chính mình. Viết lại 4 mẫu `mood_partner` theo góc "Hôm nay một người trong chúng mình thấy %mood%…" / "One of us feels %mood% today…", giữ nguyên key. `kMoodWordVi['missing']` "nhớ bạn" → "nhớ nửa kia" (chữ "bạn" chỉ đúng với một trong hai người đọc). Không đổi rules, không thêm field marker. Hướng chèn tên người đặt mood bị loại vì phải truyền tên qua `home_screen.dart` → `updateContext` (file đang có phiên khác sửa).
  - **Mục 4 — "Nhìn lại".** `pickRevisitDate`: trong mỗi cửa sổ, ngày khớp đúng thắng; không có thì lấy ngày gần nhất (hoà ±1/±2 thì chia theo seed như cũ); trả thêm `RevisitPick.exact`. `renderRevisitQuestion(exact: false)` lấy bảng mới `revisitTemplatesApprox` (3 mẫu mỗi nhóm 365/100/30: "Khoảng…", "Cách đây khoảng…", "Nhìn lại khoảng…"; EN "About…/Around…/Looking back about…"). Nhóm `month` luôn khớp đúng nên không có bản "khoảng".
  - **Mục 5 — tiêu đề chuỗi.** Key mới `streakSheetRestartTitle` "Thắp lại ngọn lửa" / "Light the spark again", dùng ở `streak_sheet.dart` khi `StreakProvider.everHadStreak` (đã từng có ngày cả hai trả lời).
  - **Test mới:** `question_engine_test` +1 (mẫu tâm trạng không có "người ấy"/"your partner", từ mood không chứa "bạn", đủ 8 mood điền được); `revisit_question_source_test` +5 (ngày khớp đúng thắng với mọi seed, lệch thì lấy ngày gần nhất + `exact=false`, ngày tháng trước clamp vẫn khớp đúng, câu lệch không có "đúng/tròn/ngày này/exactly/on this day", bảng approx đủ nhóm).
  - **Kiểm:** `flutter gen-l10n` sạch · `flutter analyze` 0 issue · `flutter test` toàn bộ pass · `scripts/test-firebase-rules.sh` 330 passing · `node -c functions/index.js` OK.
  - **Còn mở:** bản app đã phát hành vẫn hiện thẳng `e.message` của Firebase Auth/Firestore (chỉ bản mới hết); câu hỏi tâm trạng/nhìn lại đã ghi trên marker các ngày trước giữ chữ cũ (marker bất biến).
- [2026-10-11] [Dev] **Vá theo Tester vòng 1 phần văn phong** (`test.md`): (1) `_mapCallableError` → `AuthService.mapCallableError` (static, `@visibleForTesting`), thêm nhánh `unauthenticated` → `authSessionNotReady` vì firebase-functions tự trả "Unauthenticated" tiếng Anh khi token bị từ chối; `test/auth_callable_error_test.dart` (2 test). (2) Mốc "một năm" của "nhìn lại" = `monthsAgo(base, 12)` thay cho trừ 365 ngày (năm nhuận lệch 1 ngày) + test. (3) Hộp thoại nhập lại mật khẩu khi xoá tài khoản: `requires-recent-login` lần hai xử lý như `session-gone`, không còn hiện chữ kỹ thuật. Viết lại câu theo góp ý Tester: `authFirebaseAuthGeneric`/3 câu "Can't reach the server" (EN), `authUserDisabled` (VI), `photoStorageUnauthorized` (VI+EN), `sleepHowBody1`/`sleepHowBody1Ios` (VI+EN, "kết thúc trước 1 giờ sáng… không có khoảng nào muộn hơn"), mẫu tâm trạng `understand` hỏi "điều gì làm bạn thấy dễ chịu nhất", 2/4 mẫu tâm trạng mở bằng "Hôm nay có người đang thấy … đó". Kiểm: analyze 0 · 61 test liên quan pass.
- [2026-10-12] [Dev] Audit CP1: 23 chuỗi EN chia số ít bằng `{n, plural, =1{…} other{…}}` (VI giữ nguyên chữ). 5 key đổi placeholder String → int (`format: decimalPattern`, VI vẫn "1.234"): profileMemoriesCountLabel, loveTreeShareStats, loveTreeShareMessage, rpsHistoryTotal, rpsCountdownSemantics; chỗ gọi ở memories_sheet, love_tree_screen (bỏ `nf` + import intl), rps_history_screen, rps_game_screen truyền thẳng số. Không đổi các key mà số không bao giờ là 1 hoặc code đã chọn key "One".
- [2026-10-12] [Dev] Audit CP2: mẫu `feeling:gratitude_partner:1` trùng ý câu bank #1 → "Gần đây có chuyện gì người ấy nói đúng mà bạn chưa kịp công nhận không?" / "Was your partner right about something lately that you haven't given them credit for yet?" (giữ key; Jaccard cao nhất với 1.070 chuỗi còn 0,43). CP3 (D4): bỏ mục "Có gì mới" build 26, xoá `featureTourPairingTitle/Body`.
- [2026-10-12] [Dev] Backend BE5/BE6: push tâm trạng EN viết thường, `missing` → "{name} is missing you"; khoá tâm trạng lạ (vd `constructor`) không còn lọt prototype; `callableErrorCopy` nhận 'en-US'/'en_US'. Nợ: `normalizeActorName` cài cứng "Người ấy" (chỉ dính tài khoản cũ có `displayName` rỗng vì rules bắt tên khác rỗng).
- [2026-10-12] [Dev] iOS bản địa hoá chữ xin quyền (audit): thêm `ios/Runner/en.lproj/InfoPlist.strings` + `vi.lproj/InfoPlist.strings` (4 khoá: thư viện ảnh, camera, Sức khoẻ đọc/ghi; VI chép đúng chữ Info.plist, EN dịch mới), gắn vào Xcode thành variant group `InfoPlist.strings` + `vi` vào `knownRegions` (gem `xcodeproj` của CocoaPods, pbxproj +15 dòng). Không đưa `CFBundleDisplayName` vào vì `.strings` không thay `$(APP_DISPLAY_NAME)`. Kiểm: plutil OK · `flutter build ios --debug --no-codesign` OK · `Runner.app` có đủ 2 file. Chờ máy thật: iPhone tiếng Anh thấy hộp quyền tiếng Anh.
- [2026-10-12] [Dev] Lượt vá cuối (audit): T6-1 đầu 2 file `InfoPlist.strings` ghi luật "sửa câu ở đây thì sửa luôn Info.plist"; `pairing_native_config_test` so từng khoá `*UsageDescription` (vi trùng nguyên văn Info.plist, en đủ khoá). T6-2 `sleepShareAskOnly` bỏ "Không có gì khác", nói rõ đêm sửa/ghi tay có nhãn. `deleteAccountAppleIdMismatch` + `setPasswordAppleIdMismatch` VI/EN: "Máy này đang dùng một Apple ID khác. Bạn mở app trên máy dùng Apple ID của tài khoản này để …" (trên máy đó không thể "đăng nhập lại bằng Apple ID khác").
