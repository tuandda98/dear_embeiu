# 💻 Dev — Giấc ngủ của chúng mình (sleep)

> Dev sở hữu. Đọc `design.md` (nguồn sự thật — `overview.md` PO chưa viết) + `roadmap.md` Phase 1. Kiến trúc Provider + service như `MoodCard`/`MoodProvider`.

- **Trạng thái dev:** Phase 1 đã implement xong 2026-10-11, sẵn sàng test
- **Người/role:** Dev

## Kế hoạch kỹ thuật (đã làm)
- **Tính đêm ngủ** — `lib/utils/sleep_calculator.dart` (thuần Dart, không Flutter): đêm gắn **ngày thức dậy**, cửa sổ `[D-1 18:00, D 14:00)`, gộp lần ngắt ≤ 5 phút (đếm là thức giấc), lấy khối dài nhất ≥ 3 giờ, không có thì không ghi (không bịa).
  - Android (`computeScreenNights`): dựng khoảng tắt màn hình từ sự kiện `SCREEN_NON_INTERACTIVE/INTERACTIVE`. Đêm nào bắt đầu trước sự kiện cũ nhất Android còn giữ thì **bỏ qua** (không biết màn hình đang bật hay tắt lúc đầu cửa sổ). Lần sáng màn < 20 giây (thông báo) gộp im, không tính thức giấc (`ponytail:` ngưỡng chỉnh sau smoke test).
  - iOS (`computeHealthNights`): mẫu `sleepAnalysis` — dùng mẫu "ngủ" (1/3/4/5); đêm nào chỉ có "nằm trên giường" (iPhone không đeo Watch) thì dùng mẫu đó. Gộp mẫu chồng nhau (nhiều nguồn), khoảng thức ≤ 30 phút vẫn tính trong giấc, thức ≥ 2 phút mới đếm.
  - Thống kê: trung bình giờ ngủ/dậy theo **vòng tròn** (`circularMeanMinute`: 23:50 + 00:10 → 00:00), đêm tròn giấc ≥ 8 tiếng, tim khi ngủ cùng lúc ≥ 7 tiếng.
- **Model** — `lib/models/sleep_night.dart`: `SleepNight {date, bedAt, wakeAt, wakeUps (phút sau bedAt), source auto|health|manual|edited}`, pha trăng 5 bậc (<5 · 5–6 · 6–7 · 7–8 · ≥8 tiếng), `sleepNightEditable` (R3: hôm nay + 6 ngày trước).
- **Màu riêng** — `lib/theme/person_palette.dart`: 8 màu + 6 cặp khoá, `resolve()` = luật C1 (trùng màu thì người có uid xếp sau tạm hiện màu hợp lệ đầu tiên, không ghi đè lựa chọn đã lưu). Mặc định: người bật trước Hồng, người sau màu đầu tiên không trùng (Tím).
- **Native** — một kênh `dear_embeiu/sleep` cho cả hai nền tảng, trả mảng Int64 phẳng:
  - Android `MainActivity.kt`: `isSupported` (API 28+), `hasPermission` (AppOps `GET_USAGE_STATS`), `requestPermission`/`openSettings` (mở thẳng trang quyền của app, lỗi thì mở danh sách chung), `screenEvents(from,to)` chạy trên thread riêng. Manifest thêm `PACKAGE_USAGE_STATS` (`tools:ignore="ProtectedPermissions"`).
  - iOS `AppDelegate.swift` → class `SleepHealthChannel`: chỉ đọc `sleepAnalysis`, `requestAuthorization(toShare: nil)`, `openSettings` mở app Sức khoẻ. Entitlement `com.apple.developer.healthkit` + `NSHealthShareUsageDescription` (VI). **Kênh đăng ký qua `self.registrar(forPlugin:)`** như plugin sinh tự động — với UIScene lifecycle, `window` còn nil lúc `didFinishLaunching` (đọc `FlutterAppDelegate.mm` 3.41: registrar rơi về *launch engine*). **Vá kèm:** kênh `app/badge` cũ đăng ký qua `window?.rootViewController` nên **chưa từng chạy** dưới scene lifecycle → chuyển sang cùng registrar.
  - Dart wrapper `lib/services/sleep_platform.dart`: mọi lỗi kênh → "không hỗ trợ / không có dữ liệu", không ném lỗi.
- **Lưu trữ** — `lib/services/sleep_service.dart` + `lib/providers/sleep_provider.dart`:
  - Hive box `sleep_local` (theo uid): `settings:<uid>` (bật/chế độ/ẩn card tới/ẩn gợi ý Health/màu local), `nights:<uid>` (đêm + **dấu xoá** để lần quét sau không tạo lại), `fp:<uid>:<coupleId>` (dấu vân tay bản đã đẩy → không ghi lại đêm không đổi).
  - Firestore `couples/{c}/sleep/{uid}` = hồ sơ `{share, color, updatedAt}`; `couples/{c}/sleep/{uid}/nights/{YYYY-MM-DD}` = `{date, bedAt, wakeAt, wakeUps, source, updatedAt}` — **chỉ giờ cuối + nguồn (R2)**.
  - Bật chia sẻ: ghi cờ trước (commit riêng — rules đọc cờ bằng `get()` trước batch), rồi đẩy **toàn bộ** lịch sử. Tắt: ghi cờ trước rồi xoá hết đêm trên Firestore. Đang chia sẻ: chỉ đẩy đêm đổi trong 7 ngày gần nhất.
  - Quét: mỗi lần `watchForCouple` + mỗi lần app **resume** (HomeScreen gọi `onResume`), 14 đêm gần nhất. Không chạy nền (design note 4). Đêm sửa/ghi tay/đã xoá không bao giờ bị quét ghi đè; không thay dữ liệu cũ bằng "không có".
  - Người ấy: nghe hồ sơ → chỉ khi `share == true` mới nghe đêm (400 ngày gần nhất); `permission-denied` lúc người ấy vừa tắt chia sẻ = "không chia sẻ", không báo lỗi.
  - Cài lại app khi đang chia sẻ: kéo đêm của mình trên Firestore về Hive một lần (`_hydrateFromRemote`).
- **Rules** (`firestore.rules`, additive): hồ sơ — thành viên đọc, chủ ghi `hasOnly([share,color,updatedAt])`, màu thuộc 8 id. Đêm — người ấy đọc khi `share == true` **và chủ còn là thành viên couple**; tạo khi đang chia sẻ (không giới hạn tuổi để bật lại không mất lịch sử); sửa chỉ khi `wakeAt` cũ + mới ≥ `request.time − 8 ngày`; xoá khi trong 8 ngày **hoặc** đã tắt chia sẻ; `wakeAt > bedAt`, ≤ 16 giờ, ≤ now + 1 ngày, `wakeUps` ≤ 60.
- **UI** — `lib/widgets/sleep/`: `sleep_card.dart` (card Home, state A0–A5 + L + R), `moon_glyph.dart` (trăng CustomPaint đúng hình học mockup: nửa phải ± elip terminator, đĩa mờ, quầng trên nền trời, vòng nét đứt khi trống), `sleep_sheets.dart` (C setup 2 bước — Android tự sang bước 2 khi quay lại từ Cài đặt; D sửa/ghi tay — giờ dậy neo theo ngày, giờ ngủ trừ ngược nên qua nửa đêm không cần báo lỗi; E giải thích, khác nhau theo nền tảng), `sleep_format.dart`. `lib/screens/sleep_screen.dart`: segmented (chỉ khi người ấy chia sẻ), lịch trăng nền trời đêm (16 sao tĩnh, vuốt ngang đổi tháng, không sang tháng tương lai), chi tiết đêm 2 làn + dải ngủ cùng lúc trung tính, thống kê tháng, cài đặt (chia sẻ · màu trăng · nguồn · giải thích), banner A2 (Android mất quyền) + M (iOS chưa có dữ liệu Health).
- **Wiring**: `main.dart` provider · `session_resolver.dart` watch/clear (3 nhánh) · `home_screen.dart` card sau `MoodCard` (vẫn hiện khi đang chờ người ấy — A0) bọc `Selector<cardHidden>`, re-arm watch với partner uid sống, `onResume`.
- **i18n**: 123 key `sleep*` + 3 key `timePicker*` (VI + EN). `app_time_picker.dart` trước đây viết cứng "Chọn giờ nhắc / Huỷ / Xác nhận" → máy tiếng Anh vẫn thấy tiếng Việt; nay đi qua l10n.
- **A11y + motion**: mỗi ô lịch có `Semantics` ("Ngày 10: Bạn ngủ 7 giờ 15 phút, trăng gần tròn (đã sửa); …"); mũi tên tháng, nút sửa, ô màu đều có nhãn. Reduce Motion: tắt crossfade tháng, AnimatedContainer, vẽ làn từ trái; sao vốn tĩnh.

## Cần deploy?
- **Rules**: ✅ DEV deployed 2026-10-10. **PROD chờ lệnh**: `npx firebase-tools deploy --only firestore:rules --project prod` (additive — app cũ không đụng `sleep/`).
- **iOS release**: App ID `com.tony.dearembeiu` (+ `.dev`) cần capability **HealthKit**. Xcode tự bật khi build có đăng nhập Apple ID (signing Automatic); nếu `flutter build ipa` báo profile thiếu `com.apple.developer.healthkit` thì bật tay ở developer.apple.com → Identifiers. Chưa thử build IPA.
- **Store (PO/user)**: Play — khai báo An toàn dữ liệu + privacy policy cho `PACKAGE_USAGE_STATS`; App Store — App Privacy (Health). Bắt buộc trước khi phát hành.

## Edge case kỹ thuật đã xử lý
- Qua nửa đêm, màn hình chờ (AOD → `NON_INTERACTIVE` lặp), không có khối ≥ 3 giờ, nhiều lần thức giấc, đêm đang diễn ra (khối cuối mở tới "bây giờ") — có unit test.
- Android chỉ giữ sự kiện ~1–2 tuần → cửa sổ thiếu đầu bị bỏ qua, không ghi đè đêm đã có.
- "Đêm qua" trước 4 giờ sáng = đêm kết thúc sáng hôm qua (đêm nay chưa xong).
- Hai người đổi màu trùng cùng lúc → C1 cho cả hai máy cùng kết quả, không cần ghi.
- Người rời couple: rules chặn người mới đọc đêm cũ của họ.
- Không batch "cờ + đêm" (rules `get()` thấy trạng thái trước batch).

## Checklist implement
- [x] Model + thuật toán + 22 unit test (`test/sleep_calculator_test.dart`)
- [x] Android UsageStats channel + quyền + kiểm lại khi resume
- [x] iOS HealthKit channel (chỉ đọc) + entitlement + usage description
- [x] Hive luôn · Firestore khi chia sẻ · tắt thì xoá · dấu xoá · bản sửa tay không bị ghi đè
- [x] Rules + 35 test (`firebase_rules_test/test/firestore.sleep.test.js`) — tổng 330 pass
- [x] UI: card Home, màn Giấc ngủ (lịch trăng), 3 sheet, `person_palette.dart`
- [x] i18n đủ key VI + EN, `gen-l10n`
- [x] A11y + Reduce Motion
- [x] `flutter analyze` sạch · `flutter test` 163/163

## Nhật ký implement
- [2026-10-11] [Dev] Implement Phase 1 (toàn bộ mục trên). Kiểm: `flutter analyze` 0 · `flutter test` 163/163 (22 test mới) · `scripts/test-firebase-rules.sh` 330 pass (35 test sleep mới) · `flutter gen-l10n` sạch. **Rules deploy DEV** (2026-10-10). **Smoke test DEV trên Android emulator API 37** (tài khoản "anh tuan" của couple `KcjIKh8VBxNYxjaFlKwY`): card A1 → sheet bật theo dõi → mở thẳng trang Quyền truy cập dữ liệu sử dụng → bật xong quay lại app thì tự sang bước 2 → chia sẻ → ghi tay một đêm (bộ chọn giờ, tổng tự cập nhật) → card hiện trăng tròn + nhãn "Ghi tay" → màn Giấc ngủ (lịch trăng, chi tiết, thống kê, bộ màu). Dùng script admin đóng vai người ấy chia sẻ 9 đêm: card + lịch hiện 2 trăng/ô, tim ở đêm ngủ cùng lúc ≥ 7 tiếng, 2 làn + dải chung, màu Tím của người ấy bị khoá + Xanh dương gạch chéo; đổi màu → áp ngay mọi chỗ; tắt chia sẻ → Firestore còn `share:false` và 0 đêm; bật lại → đêm được tải lên lại; đêm 9 ngày trước khoá sửa. Đã xoá dữ liệu giả của người ấy. **iOS**: build simulator thành công (Xcode 27), kênh `dear_embeiu/sleep` trả `isSupported/hasPermission = true` và `sleepSamples` trả mảng Int64 rỗng (log tạm, đã gỡ) — **chưa đi được luồng UI trên iPhone** (app Simulator đổi thành Device Hub, kéo/cuộn giả lập không ăn) ⇒ Tester cần thử tay: popup quyền Sức khoẻ, có/không có dữ liệu, banner M.
  - Lỗi bắt được khi chạy thật và đã sửa: `context.select` gọi ngoài build ở Home (đổi sang `Selector`); nút "Bật theo dõi" vỡ layout vì theme đặt `minimumSize` rộng vô hạn; "9g 0p" → "9g"; tiêu đề tháng viết hoa.
  - Tự soát sau smoke test, vá 3 chỗ: card không còn nháy "Cần cấp lại quyền" lúc mở app (kiểm quyền trước khi báo đã tải); người ấy vừa tắt chia sẻ không còn hiện nhầm SnackBar lỗi; lần bật theo dõi đầu chỉ ghi màu, không bao giờ ghi đè cờ chia sẻ đang bật (cài lại app).
- [2026-10-11] [Dev] **Vá theo Tester vòng 1** (`test.md`):
  - **S1** (offline kẹt nút): mọi lệnh ghi Firestore trong luồng UI không còn được await — `setShare` cập nhật UI ngay rồi đẩy việc xuống hàng đợi `_shareOps` (cờ trước, đêm sau, tuần tự ⇒ bật/tắt liên tiếp không để lệnh xoá đến sau lệnh đẩy lại); `enableTracking`/`setColor` ghi hồ sơ kiểu fire-and-forget.
  - **S2** (dữ liệu sót khi rời couple/xoá tài khoản): CF `handleCoupleOnAccountDeletion` (dùng chung cho `deleteAccount` + `leaveCoupleCleanup`) `recursiveDelete(couples/{c}/sleep/{uid})`; `deleteCoupleCompletely` xoá cả `sleep/`. ✅ Deploy DEV 2 function. **PROD chờ lệnh** (`deploy --only functions:deleteAccount,functions:leaveCoupleCleanup --project prod`).
  - **S3** (máy để yên 20 tiếng): khối > 16 tiếng không còn là đêm (`SleepRules.maxSleep`, khớp sheet sửa + rules). Fingerprint chỉ ghi khi lệnh đẩy/xoá thành công ⇒ lỗi được thử lại ở lần đồng bộ sau.
  - **S4**: nút Lưu tắt khi đêm có sẵn mà giờ ngủ/giờ dậy chưa đổi (không còn gắn nhầm "Đã sửa").
  - **S5**: listener hồ sơ của mình đồng bộ lại khi `share == true` (mở app lạnh mà hồ sơ về sau lần quét).
  - **S6** (Dev tự chốt theo đề xuất Tester, PO có thể lật lại): (a) khối phủ 00:00–05:00 thắng khối buổi tối; không khối nào phủ (làm ca đêm) thì vẫn lấy khối dài nhất; (b) Health: mẫu "ngủ" không ra đêm thì quay về mẫu "nằm trên giường". +4 unit test (tổng 26).
  - Lỗi nhỏ đã vá: không lẫn dữ liệu khi đổi tài khoản giữa lúc nạp; chỉ kéo lịch sử của mình về khi máy chưa biết gì (fingerprint rỗng) thay vì mỗi lần mở app; lần bật đầu chỉ ghi màu khi stream đã xác nhận chưa có hồ sơ; giờ dậy ≥ 18:00 khi sửa được neo vào tối hôm trước; link "Ghi tay"/"Mở cài đặt" cao 44; lưới màu cao cố định theo cỡ chữ; tiêu đề đêm dùng `DateFormat.Md` theo ngôn ngữ; ô trống thay nút sửa rộng 44.
  - Chưa làm (ghi nợ): test cho provider; mô tả quyền Health bản tiếng Anh (Info.plist app vốn chỉ tiếng Việt); cài lại app khi đang chia sẻ thì card về A1 tới khi bật lại; người mới vào couple cũ thấy đêm của người đang chia sẻ (PO quyết).
  - Kiểm: analyze 0 · test 167/167 · rules-test 330.
