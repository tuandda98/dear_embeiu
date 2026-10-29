# Bộ test case: Thời tiết hai nơi (weather)

> Soạn 2026-10-23 từ `overview/design/dev/test.md` + code trên `feature/daily-open-2`. Cột "Cách kiểm" đã đối chiếu bằng grep với tên test thật. Flow Maestro ở `maestro/weather/` (thứ tự + lệnh tiền xử lý: `maestro/weather/README.md`). Flow chưa chạy thử trên máy ảo, selector lấy từ `app_vi.arb` + semantics trong code.

**Lưu ý phạm vi.** Feature KHÔNG xin quyền vị trí và không có "tự lấy vị trí": mỗi người chọn tay 1 thành phố trong danh sách 116 điểm (overview D-phạm vi, "Không xin quyền vị trí"; GPS và "Nhà" của `arrival` nằm ngoài phạm vi). Vì vậy nhóm LOC kiểm phủ định (app không hỏi quyền, vị trí giả không ảnh hưởng). Không có inbox hay push từ server cho thời tiết; thông báo duy nhất là local 07:30 (id 1160). "Nhật ký thông báo" ở đây là Hive `weather_notice_log` (trần 3 lần/7 ngày), không phải Notification center.

Quy ước: A = Android `emulator-5554` (test3 Tuấn), I = iOS sim (test4 Thảo).

## 1. Chọn thành phố

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| CH-01 | Chưa đặt | Đã ghép, cả hai chưa chọn | Mở Home, cuộn tới thẻ | Thẻ mời: "Chọn thành phố" + "Ẩn" | unit: test/weather_card_test.dart::nobody picked: the invite with "Chọn thành phố" + "Ẩn" + maestro: maestro/weather/01_invite_hide_android.yaml |
| CH-02 | Chưa đặt | Chưa ghép (chờ người ấy), chưa chọn | Mở Home | Thẻ mời bản solo ("Chọn thành phố của bạn…"), không nhắc chọn cho người ấy | unit: test/weather_gap_widget_test.dart::CH-02: waiting couple, nothing picked → the solo invite |
| CH-03 | Chọn | Đã ghép, chưa ai chọn | "Chọn thành phố" → chọn của mình | Hỏi tiếp "Còn Thảo đang ở đâu?" (chuỗi 3 chạm) | unit: test/weather_card_test.dart::first time: my city, then "Còn Thảo đang ở đâu?" (3 taps) |
| CH-04 | Chọn | Sau CH-03 | Bấm "Để sau" | Đóng, thẻ hiện lời mời chọn giúp | unit: test/weather_gap_widget_test.dart::CH-04: "Để sau" closes the sheet; the card then offers "Chọn giúp" |
| CH-05 | Chọn | Mình đã chọn, người ấy chưa | Xem thẻ | "Thảo đang ở đâu?" + "Chọn giúp" | unit: test/weather_card_test.dart::partner not picked: "Thảo đang ở đâu?" + "Chọn giúp" + maestro: maestro/weather/02_pick_self_settings_android.yaml |
| CH-06 | Chọn | Người ấy chưa tự chọn | "Chọn giúp" → TP.HCM | Ghi doc `setBy` = mình; hai máy thấy ngay | unit: test/weather_provider_test.dart::pick for the partner only until they pick themselves (D6) + maestro: maestro/weather/03_pick_for_partner_android.yaml, maestro/weather/04_see_both_ios.yaml |
| CH-07 | Chọn | Thành phố của I do A chọn giúp | I tự chọn Đà Nẵng | Ghi đè được; A thấy "Thảo tự chọn", hết nút "Đổi giúp" | unit: firebase_rules_test/test/firestore.weather.test.js::lets the owner override a city the partner picked for them + maestro: maestro/weather/05_pick_own_ios.yaml, maestro/weather/06_sees_self_set_android.yaml |
| CH-08 | Chọn | I vừa tự chọn, A chưa kịp thấy | A bấm chọn giúp | Rules chặn, rollback, SnackBar "Thảo vừa tự chọn chỗ của mình rồi." | unit: test/weather_provider_test.dart::a refused write rolls back; unknown ids are never written (SnackBar phía partner chưa có widget test → đề xuất unit). Tranh chấp thật giữa 2 máy: thủ công: cần hai thao tác trong cùng vài trăm ms, Maestro không đồng bộ được |
| CH-09 | Chọn | Đã chọn | Đổi thành phố từ Cài đặt "Chỗ của bạn" | Cập nhật thẻ | maestro: maestro/weather/02_pick_self_settings_android.yaml |
| CH-10 | Tìm | Mở bảng chọn | Gõ không dấu / viết liền / viết tắt (hanoi, hcm, sg) | Ra đúng thành phố | unit: test/weather_card_test.dart::unaccented, no spaces, old province, nothing found + test/weather_logic_test.dart::no-space and short forms find their city + maestro: maestro/weather/02_pick_self_settings_android.yaml, maestro/weather/03_pick_for_partner_android.yaml |
| CH-11 | Tìm | Mở bảng chọn | Gõ tên tỉnh cũ (binh thuan) | Ra Phan Thiết kèm dòng "Tỉnh cũ: …" | unit: test/weather_logic_test.dart::"binh thuan" → Phan Thiết via the old province |
| CH-12 | Tìm | Mở bảng chọn | Gõ chuỗi không có | "Chưa có thành phố này. Chọn nơi gần nhất nhé." | unit: test/weather_card_test.dart::unaccented, no spaces, old province, nothing found + maestro: maestro/weather/01_invite_hide_android.yaml |
| CH-13 | Tìm | Mở bảng chọn | Gõ tên nước ngoài tiếng Anh | Ra đúng thành phố, nhóm "Nước ngoài" | unit: test/weather_logic_test.dart::abroad, English names, nothing found |
| CH-14 | Tìm | Ô tìm trống | Mở bảng chọn | Liệt kê đủ 116, nhóm Đang chọn / Việt Nam / Nước ngoài, không tự bật bàn phím | unit: test/weather_logic_test.dart::a name match has no "via"; empty query lists every city |
| CH-15 | Dữ liệu | — | So danh sách Dart với JSON của CF | Cùng id + toạ độ; id duy nhất, slug, ≤40 ký tự; tz hợp lệ | unit: test/weather_logic_test.dart::Dart list == functions/weather_cities.json (id + coordinates) |
| CH-16 | Tương thích | Doc có id mà bản này không biết | Mở app | Coi như chưa chọn, không gọi CF với id lạ | unit: test/weather_provider_test.dart::a city id this build does not know reads as "not picked" |
| CH-17 | Mạng | Mất mạng | Chọn thành phố | Sheet đóng sau tối đa 4 giây, Firestore xếp hàng, lên mạng thì đồng bộ | unit: test/weather_gap_provider_test.dart::CH-17: offline write — returns true after 4 s, not before (đồng hồ giả của testWidgets; hàng đợi Firestore thật: không dựng được) |
| CH-18 | Ẩn thẻ | Chưa ai chọn | "Ẩn" rồi chọn thành phố từ Cài đặt | Thẻ biến mất, chọn xong thì hiện lại | unit: test/weather_provider_test.dart::hide the card; picking a city brings it back + maestro: maestro/weather/01_invite_hide_android.yaml, maestro/weather/02_pick_self_settings_android.yaml |
| CH-19 | Ẩn thẻ | Đã bấm Ẩn, mở lại app | Cold start | Không nháy thẻ trước khi đọc xong prefs | unit: test/weather_provider_test.dart::cardVisible waits for the Hive prefs (no flash of a hidden card) |
| CH-20 | Ẩn thẻ | Mình đã ẩn thẻ | Người ấy chọn giúp mình | Cờ ẩn của máy mình không đổi | unit: test/weather_gap_provider_test.dart::CH-20: my hidden flag survives my partner picking for me |
| CH-21 | Lỗi ghi | Rules từ chối ghi thành phố của mình | Chọn | SnackBar "Chưa lưu được, thử lại nhé." | unit: test/weather_card_test.dart::my own city refused → "Chưa lưu được" SnackBar |
| CH-22 | Analytics | Chọn thành phố ghi lỗi | Chọn | Không log `weather_city_set` | unit: test/weather_gap_provider_test.dart::CH-22: a refused write returns false (the picker then logs nothing) + test/weather_gap_source_test.dart::AN-02 / CH-22: the event sits inside `if (ok)`, the failure branch logs nothing (kiểm nguồn) |

## 2. Vị trí (phủ định)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| LOC-01 | Quyền vị trí | Chưa cấp quyền vị trí | Mở bảng chọn, Cài đặt, thẻ | Không có nút "dùng vị trí hiện tại", không hộp xin quyền; câu "app không xin vị trí" hiện | maestro: maestro/weather/01_invite_hide_android.yaml |
| LOC-02 | Vị trí giả | `geo fix` đặt máy ở Seoul | Mở Home | Thẻ vẫn theo thành phố đã chọn (Hà Nội) | maestro: maestro/weather/09_gps_ignored_android.yaml (iOS: `simctl location` tương tự, chạy tay: thủ công: Maestro cho iOS không đổi được vị trí) |
| LOC-03 | Từ chối quyền | Máy đã từ chối vị trí | Dùng feature | Không ảnh hưởng gì | maestro: maestro/weather/01_invite_hide_android.yaml (vì app không đụng tới quyền) |
| LOC-04 | Nhập tay | — | Thành phố ngoài danh sách | Không nhập tự do được (geocoding ngoài phạm vi); chọn điểm gần nhất | unit: test/weather_card_test.dart::unaccented, no spaces, old province, nothing found |

## 3. Tải dữ liệu phía app (WeatherProvider / Hive)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| FE-01 | Gọi API | Hai thành phố khác nhau | Vào Home | 1 callable cho cả hai; 30 phút sau mới gọi lại | unit: test/weather_provider_test.dart::both cities fetched in ONE call, then not again for 30 minutes |
| FE-02 | Gọi API | Cùng thành phố | Vào Home | Chỉ 1 id trong lượt gọi | unit: test/weather_provider_test.dart::same city for both → one id in the call |
| FE-03 | Lỗi một phần | CF chỉ trả 1/2 thành phố | Tải | `lastRefreshFailed`; làn lỗi hiện "Chưa tải được", làn kia vẫn có số | unit: test/weather_provider_test.dart::only one of two cities answered → lastRefreshFailed + test/weather_card_test.dart::one city without numbers fails in its own lane only |
| FE-04 | Lỗi toàn bộ | CF lỗi/timeout | Tải | Không gọi lại trong 3 phút trừ khi "Thử lại" | unit: test/weather_provider_test.dart::after an error: no new call for 3 minutes unless forced |
| FE-05 | Thử lại | Đang có lượt gọi chạy | Bấm "Thử lại" | Chạy thêm đúng 1 lượt sau khi lượt hiện tại xong | unit: test/weather_provider_test.dart::"Thử lại" while a call is running runs once more afterwards |
| FE-06 | Timeout | Callable treo | Chờ | Client dừng ở 15 s, vào trạng thái lỗi | unit (một phần): test/weather_gap_provider_test.dart::FE-06: a callable that fails (timeout included) ends in the error state + test/weather_gap_source_test.dart::FE-06: the callable has a 15 s client timeout (kiểm nguồn; callable treo thật không dựng được vì `WeatherService` đòi Firebase) |
| FE-07 | Race | Đổi couple / đăng xuất khi đang chờ callable | Kết quả về muộn | Bị bỏ (`_session`), không ghi đè state mới | unit: test/weather_gap_provider_test.dart::FE-07: an answer that arrives after clear() is dropped + test/weather_gap_provider_test.dart::FE-07: an answer for couple 1 never lands in couple 2 |
| FE-08 | Resume | App ở nền >30 phút | Quay lại | `onResume` làm mới | unit: test/weather_gap_provider_test.dart::FE-08: onResume refreshes only once the copy is 30 minutes old |
| FE-09 | Độ tươi | Số liệu 10 giờ tuổi | Xem thẻ | Chữ xám, "Số liệu lúc hh:mm" + Thử lại, không nút nhắc | unit: test/weather_card_test.dart::old numbers (10 h): grey, "Số liệu lúc" + Thử lại, no nudge |
| FE-10 | Offline | Máy bay, có cache Hive | Khởi động | Thẻ hiện số từ cache, xếp hạng theo tuổi (D16) | unit: test/weather_provider_test.dart::offline start: the Hive copy shows, graded by its age (D16) + maestro: maestro/weather/08_offline_cache_android.yaml |
| FE-11 | Offline | Máy bay, KHÔNG có cache (cài mới) | Khởi động | Tên thành phố + "Chưa tải được thời tiết · Thử lại" | unit: test/weather_card_test.dart::never loaded: city names + "Chưa tải được thời tiết" |
| FE-12 | Độ tươi | Mốc 6 giờ / 24 giờ | Tính | ≤6 h tươi; 6–24 h cũ; >24 h hỏng | unit: test/weather_logic_test.dart::freshness: ≤ 6 h / 6–24 h / > 24 h (D16) |
| FE-13 | Hive | Forecast lưu rồi nạp lại | Round-trip JSON | Không mất trường | unit: test/weather_logic_test.dart::forecast JSON round-trips (Hive cache) |
| FE-14 | Đăng xuất | Đã có cache | Đăng xuất | Xoá state + Hive `weather_cache` + `weather_notice_log` | unit: test/weather_provider_test.dart::sign-out clears state and the Hive cache |
| FE-15 | Chờ người ấy | Couple `waiting_partner`, có doc người cũ | Mở app | Chỉ đọc doc của mình | unit: test/weather_provider_test.dart::waiting couple: the other member doc is ignored |
| FE-16 | Chờ tải lần đầu | Chưa có snapshot | Mở app | Khung xương (shimmer), đứng yên khi Reduce Motion | unit: test/weather_gap_widget_test.dart::FE-16: before the first answer → skeleton, then the numbers |
| FE-17 | Thật | DEV, mạng bình thường | Mở Home sau khi chọn | Thẻ có số độ thật từ MET qua CF DEV | maestro: maestro/weather/04_see_both_ios.yaml (assert tên thành phố; số độ thay đổi nên không assert giá trị) |

## 4. Cloud Function `getCityWeather` + cache MET

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| CF-01 | Bảo mật | Chưa đăng nhập / id sai | Gọi | `unauthenticated` / `invalid-argument` | unit: functions/test/weather.test.js::getCityWeather: sign-in required, bad ids refused |
| CF-02 | Đầu vào | 0, 3 id, `__proto__`, id trùng | Gọi | Chỉ 1–2 id trong danh sách, trùng gộp, `__proto__` bị chặn | unit: functions/test/weather.test.js::cityIds: 1–2 ids from the bundled list only (D9) |
| CF-03 | Cache | Cache còn hạn | Gọi | Không gọi MET | unit: functions/test/weather.test.js::cache still valid → no MET call |
| CF-04 | Cache | Hết hạn | Gọi | MET với User-Agent + `If-Modified-Since`, ghi cache | unit: functions/test/weather.test.js::expired → MET with User-Agent + If-Modified-Since → cache rewritten |
| CF-05 | Cache | Chưa có cache | Gọi lần đầu | Không gửi `If-Modified-Since` | unit: functions/test/weather.test.js::first fetch sends no If-Modified-Since |
| CF-06 | MET 304 | Hết hạn, MET trả 304 | Gọi | Chỉ dời `expiresAt` | unit: functions/test/weather.test.js::304 → only expiresAt moves, the cached hours are served |
| CF-07 | MET lỗi | MET sập | Gọi | Trả cache cũ `stale: true`, 10 phút không gọi lại | unit: functions/test/weather.test.js::MET down → old cache marked stale, no new call for 10 minutes |
| CF-08 | MET lỗi | 5xx / body rỗng | Gọi | Stale, không bao giờ ghi forecast rỗng | unit: functions/test/weather.test.js::MET 5xx / empty body → stale, never an empty forecast in cache |
| CF-09 | MET lỗi | 403 / 429 | Gọi | Stale + backoff 10 phút | unit: functions/test/weather.test.js::MET 403 / 429 → stale old copy + 10-minute backoff |
| CF-10 | MET lỗi | Không cache + MET lỗi | Gọi | Bỏ thành phố đó, backoff vẫn giữ | unit: functions/test/weather.test.js::no cache and MET fails → null, and the backoff holds without a cache |
| CF-11 | Backoff | Sau 1 lần lấy thành công | Gọi | `retryAt` hết tác dụng | unit: functions/test/weather.test.js::retryAt stops mattering after one good fetch |
| CF-12 | Đồng thời | Hai người gọi cùng lúc khi hết hạn | Gọi | Người sau nhận bản cũ, MET chỉ bị gọi 1 lần | unit: functions/test/weather.test.js::soft lock: a second caller during a refresh gets the old copy, no MET call |
| CF-13 | Đồng thời | Lần đầu đang chạy ở nơi khác | Gọi | Chờ lượt đó, không trả rỗng; lượt kia lỗi thì thôi chờ | unit: functions/test/weather.test.js::first fetch running elsewhere (no cache yet): wait for it, never empty + functions/test/weather.test.js::first fetch elsewhere failed (retryAt set): stop waiting, null |
| CF-14 | Kết quả | 1 thành phố có số, 1 không | Gọi | Trả riêng thành phố có số; cả hai không thì `unavailable` | unit: functions/test/weather.test.js::getCityWeather: one city with data + one without → only the one |
| CF-15 | Chuẩn hoá | Phản hồi MET 1 giờ/bước | Chuẩn hoá | 36 giờ từ giờ hiện tại | unit: functions/test/weather.test.js::MET → 36 hours from the current hour, raw numbers only |
| CF-16 | Chuẩn hoá | MET sang bước 6 giờ | Chuẩn hoá | Giữ mã 6 giờ, chia đều mưa; cắt sau 36 giờ; bước hỏng không ném lỗi | unit: functions/test/weather.test.js::MET 6-hour steps: keep the symbol, spread the rain per hour + functions/test/weather.test.js::MET: steps past 36 hours are dropped even when sparse + functions/test/weather.test.js::MET: broken steps and bodies don't throw |
| CF-17 | Chuẩn hoá | Chỉ có dữ liệu bước 6 giờ | Gọi | Vẫn thành forecast | unit: functions/test/weather.test.js::6-hour data only still makes a forecast |
| CF-18 | Hạn cache | `Expires` của MET | Tính | `expiresAt` ≥ 30 phút | unit: functions/test/weather.test.js::expiresAt follows MET's Expires, never sooner than 30 minutes |
| CF-19 | Toạ độ | 116 thành phố | Kiểm JSON | ≤4 chữ số thập phân, trong khoảng hợp lệ | unit: functions/test/weather.test.js::every city in the JSON is a valid MET point (≤ 4 decimals, in range) |
| CF-20 | Ngôn ngữ | `lang` vi/en/thiếu | Gây lỗi | Câu lỗi đúng ngôn ngữ người gọi | unit: functions/test/weather.test.js::weather errors speak the caller's language |
| CF-21 | Riêng tư | — | Gọi | Gửi MET chỉ toạ độ thành phố, không uid/email; không ghi inbox, không push | unit: functions/test/weather_gap.test.js::CF-21: MET gets coordinates only — no uid, email or couple in URL or headers + functions/test/weather_gap.test.js::CF-21 / NT-19: the weather feature writes no inbox item and sends no push |
| CF-22 | Lạm dụng | User gọi dồn dập | Gọi nhiều | Có giới hạn / App Check | unit (đang skip, BUG): functions/test/weather_gap.test.js::CF-22: getCityWeather limits callers per user or requires App Check — nợ đã ghi, test đỏ khi bỏ skip |

## 5. Logic tình trạng, độ chênh, hàng chung

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| CD-01 | Mưa | Mưa từ 14:00 (TP.HCM) | Tính | "Chiều nay mưa" + nút mang ô | unit: test/weather_logic_test.dart::TP.HCM: rain from 14:00 → "Chiều nay mưa", umbrella |
| CD-02 | Mưa | Giờ hiện tại đang mưa | Tính | "Đang mưa" thắng mọi thứ | unit: test/weather_logic_test.dart::raining in the current hour wins over everything |
| CD-03 | Mưa | Mưa trước trưa / sau 18:00 | Tính | "Sáng nay" / "Tối nay" | unit: test/weather_logic_test.dart::rain before noon → this morning; after 18:00 → tonight |
| CD-04 | Mưa | 0,4 mm vs 0,5 mm | Tính | 0,4 mm mã khô không phải mưa; 0,5 mm là mưa | unit: test/weather_logic_test.dart::0.4 mm with a dry code is not rain; 0.5 mm is |
| CD-05 | Mưa | Mã dông / mưa tuyết, 0 mm | Tính | Vẫn tính là mưa | unit: test/weather_logic_test.dart::thunder / sleet codes count as rain even at 0 mm |
| CD-06 | Trời | Khô, nhiều mây | Tính | Câu mô tả trời, không nút | unit: test/weather_logic_test.dart::Hà Nội dry and cloudy → sky text, no button |
| CD-07 | Nóng | 35°+ (Biên Hoà 36°) | Tính | "Nắng gắt, lên 36°" + nút uống nước | unit: test/weather_logic_test.dart::hot at 35° (Biên Hoà 36°) → water |
| CD-08 | Lạnh | ≤15° (Sa Pa 13°), Đà Lạt 16° | Tính | 13° lạnh; 16° không | unit: test/weather_logic_test.dart::cold at ≤ 15° (Sa Pa 13°) → warm; Đà Lạt 16° is not cold |
| CD-09 | Lạnh | Có tuyết ở nhiệt độ >15° | Tính | Tính là lạnh | unit: test/weather_logic_test.dart::snow makes it cold even above 15° |
| CD-10 | Ưu tiên | Mưa + nóng + lạnh cùng lúc | Tính | Mưa > nóng > lạnh | unit: test/weather_logic_test.dart::rain beats hot beats cold |
| CD-11 | Cửa sổ | Còn <3 giờ trong ngày | Tính | Nới sang 09:59 sáng mai | unit: test/weather_logic_test.dart::under 3 hours left, the window stretches to 09:59 tomorrow |
| CD-12 | Min/Max | Hết ngày | Tính | Chỉ tính phần còn lại của ngày | unit: test/weather_logic_test.dart::min / max cover only the rest of today |
| CD-13 | Mã lạ | symbol_code MET mới | Tính | Chỉ ẩn câu mô tả trời | unit: test/weather_logic_test.dart::an unknown MET code hides the sky text only |
| CD-14 | Múi giờ | Máy ở VN, thành phố London/Seoul | Tính | Dùng giờ thành phố, kể cả đổi giờ mùa hè | unit: test/weather_logic_test.dart::the city clock is used, not the phone clock + test/weather_logic_test.dart::DST switch inside the window: each hour on its own offset (London) |
| CD-15 | Hết dữ liệu | Dự báo không phủ tới hôm nay | Tính | Trả null, thẻ không bịa câu | unit: test/weather_logic_test.dart::a forecast that no longer covers today → null |
| CD-16 | Nhóm trời | 9 nhóm mô tả trời | Map | Đúng nhóm | unit: test/weather_logic_test.dart::sky groups (§6.3) |
| SR-01 | Chênh | ≥5° | Tính | Câu "Chỗ Thảo lạnh hơn 6°" | unit: test/weather_logic_test.dart::gap: ≥ 5° only (D11) + test/weather_card_test.dart::≥ 5° apart, plain sky: the gap line, no nudge |
| SR-02 | Hàng chung | Người ấy mưa, chênh 6° | Tính | Nút nhắc thắng câu chênh | unit: test/weather_logic_test.dart::partner rain → nudge, even over a 6° gap |
| SR-03 | Hàng chung | Trời thường, chênh 1° | Tính | Thu thành 1 hàng gọn | unit: test/weather_logic_test.dart::plain weather, 6° apart → gap row; 1° apart → compact + test/weather_card_test.dart::nothing worth a nudge: folds into one row |
| SR-04 | Hàng chung | Mưa chỉ ở chỗ mình | Tính | Không nhắc, nhưng không thu gọn | unit: test/weather_logic_test.dart::rain on MY side only: no nudge, but not compact either |
| SR-05 | Hàng chung | Số mình cũ, của người ấy tươi | Tính | Nút nhắc còn, câu chênh mất | unit: test/weather_logic_test.dart::my numbers old: partner nudge stays, gap goes |
| SR-06 | Hàng chung | Số người ấy cũ | Tính | Không nhắc | unit: test/weather_logic_test.dart::partner stale: no nudge; mine stale: nudge stays, no compact row |
| SR-07 | Hàng chung | Mình chưa chọn thành phố | Tính | Nút nhắc người ấy vẫn hiện | unit: test/weather_logic_test.dart::I have no city yet: the partner nudge still shows |
| SR-08 | Hàng chung | Người ấy chưa chọn | Tính | Thẻ đủ ("Chọn giúp") | unit: test/weather_logic_test.dart::partner city not picked yet → full card ("Chọn giúp") |
| SR-09 | Cùng nơi | Hai người cùng thành phố | Xem thẻ | 1 làn "Cả hai cùng ở {city}" (2 chấm chồng) | unit: test/weather_gap_widget_test.dart::SR-09: same city → one lane "Cả hai cùng ở Hà Nội" |
| SR-10 | Tên ngắn | Ngôn ngữ en, TP.HCM | Xem thẻ | Hiện "HCMC" | unit: test/weather_logic_test.dart::short EN name only where set (tên ngắn); hiển thị trên thẻ: unit: test/weather_gap_widget_test.dart::SR-10: English card shows the short name "HCMC" |

## 6. Thẻ Home và màn chi tiết

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| CARD-01 | Thẻ | Chưa ai chọn | Xem | Thẻ mời | maestro: maestro/weather/01_invite_hide_android.yaml |
| CARD-02 | Thẻ | Mưa ở chỗ người ấy | Xem | 2 làn (mình trái, người ấy phải) + nút nhắc có tên | unit: test/weather_card_test.dart::rain at their place: two lanes (you left) + named nudge |
| CARD-03 | Thẻ | Couple chờ người ấy | Xem | Chỉ làn của mình, không nút nhắc, vẫn hiện thẻ | unit: test/weather_card_test.dart::waiting for the partner: your lane only, no nudge |
| CARD-04 | Thẻ | Cả hai đã chọn, thời tiết thật | Xem trên 2 máy | Hai máy cùng thấy đủ 2 thành phố (realtime) | maestro: maestro/weather/04_see_both_ios.yaml, maestro/weather/06_sees_self_set_android.yaml |
| CARD-05 | Thẻ | Chữ 200% màn 320 dp | Xem | Không tràn | unit: test/weather_card_test.dart::320 dp at 200% text: no overflow (state 21) |
| CARD-06 | Thẻ | Bất kỳ | Chạm thẻ | Mở sheet chi tiết | unit: test/weather_card_test.dart::tap the card → detail sheet opens |
| CARD-07 | Thẻ | Qua 0:00 giờ máy | Chờ | Câu tình trạng tự tính lại | unit: test/weather_gap_widget_test.dart::CARD-07: past 0:00 the card reads the condition again (nợ giờ máy vs giờ thành phố vẫn còn) |
| CARD-08 | Thẻ | Reduce Motion bật | Xem | Khung xương đứng yên, chuyển cảnh 0 ms | unit: test/weather_gap_widget_test.dart::CARD-08: Reduce Motion — skeleton stands still + test/weather_gap_widget_test.dart::CARD-08: Reduce Motion — the number switcher has 0 ms |
| CARD-09 | Thẻ | Tab Home, nhiều thẻ | Cuộn | Thẻ nằm ở dòng đánh dấu, không bị floating nav che | maestro: maestro/weather/01_invite_hide_android.yaml (scrollUntilVisible) |
| CARD-10 | Thẻ | Mở từ "Có gì mới" (build 33) | Chạm mục | Chưa chọn → mở bảng chọn; đã chọn → sheet chi tiết | unit: test/weather_morning_test.dart::feature tour: one weather row for build 33 that opens the feature |
| SH-01 | Sheet | Đã chọn hai nơi | Mở chi tiết | Khối Bạn trước, thước nhiệt chung, 5 mốc 3 giờ | maestro: maestro/weather/04_see_both_ios.yaml (có sheet; thước/mốc không assert). Chi tiết thước/mốc: unit: test/weather_gap_widget_test.dart::SH-01: me first, one shared scale, five 3-hour marks each |
| SH-02 | Sheet | Múi giờ thành phố khác máy | Mở chi tiết | "bên đó đang hh:mm" | unit: test/weather_gap_widget_test.dart::SH-02: "bên đó đang hh:mm" only where the city clock differs |
| SH-03 | Sheet | Số người ấy cũ | Mở chi tiết | Không nút gợi ý dưới thước | unit: test/weather_gap_widget_test.dart::SH-03: old numbers (10 h) → no nudge under the scale |
| SH-04 | Sheet | Người ấy đã tự chọn | Mở chi tiết | "Thảo tự chọn", không "Đổi giúp" | maestro: maestro/weather/06_sees_self_set_android.yaml |
| SH-05 | Sheet | — | Cuối sheet | Dòng "Dữ liệu thời tiết: MET Norway" mở license | maestro: maestro/weather/04_see_both_ios.yaml (hiện dòng); mở link ra trình duyệt: thủ công: Maestro không kiểm được trang ngoài app |
| SH-06 | Sheet | Số cũ >24 h hoặc không có | Mở chi tiết | Không bịa số; thông báo lỗi | unit: test/weather_gap_widget_test.dart::SH-06: numbers older than 24 h or none → error row, no invented figures + test/weather_gap_widget_test.dart::SH-06: a place the server has no data for → the same error row |

## 7. Nhắc người ấy (nút gợi ý → Quan tâm)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| CT-01 | Nhắc | Thời tiết thật ở chỗ người ấy đang mưa/nóng/lạnh | Bấm nút "Nhắc Thảo …" | Mở Quan tâm, tiêu đề + nội dung điền sẵn | maestro: maestro/weather/10_cta_prefill_android.yaml (chạy nhánh nhắc có điều kiện) |
| CT-02 | Lời điền sẵn | 3 loại | Dựng | Chữ đúng, kèm thành phố + số | unit: test/weather_morning_test.dart::rain / hot / cold wording with the city and numbers |
| CT-03 | Giới hạn | Tên thành phố dài nhất | Dựng | Tiêu đề ≤60, nội dung ≤200 | unit: test/weather_morning_test.dart::the longest city still fits care-message limits (60 / 200) |
| CT-04 | Nhãn | Tên người ấy | Dựng | Nút "Nhắc {tên} …" đúng | unit: test/weather_morning_test.dart::nudge labels name the person |
| CT-05 | Gửi | Bấm Gửi | Gửi | Người ấy nhận inbox care_message (Firestore); push iOS DEV không tới vì thiếu APNs | thủ công: DEV không có APNs cho iOS và Android emulator không đăng ký FCM; inbox Firestore xem được ở màn Thông báo bên nhận |
| CT-06 | Analytics | Gửi từ thời tiết | Gửi | `care_message_sent{source: weather}`, `weather_cta_tap{entry: card}` | unit (kiểm nguồn): test/weather_gap_source_test.dart::CT-06: the care screen is opened with source "weather" + test/weather_gap_source_test.dart::AN-03 / CT-06: weather_cta_tap {condition, entry}; card for card+sheet (sự kiện thật không bắt được: handle Firebase Analytics là private) |
| CT-07 | Ngày đẹp | Thời tiết thật đẹp | Xem | Không có nút nhắc | maestro: maestro/weather/10_cta_prefill_android.yaml (nhánh không chạm) |

## 8. Thông báo local 07:30 (id 1160)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| NT-01 | Lịch | Trước/sau 07:30 | Tính | 07:30 kế tiếp: hôm nay nếu chưa tới, mai nếu đã qua | unit: test/weather_morning_test.dart::next 07:30: today before it, tomorrow after it |
| NT-02 | Loại | Mưa/nóng/lạnh sắp tới; trời thường | Tính | Đúng loại; trời thường → không báo | unit: test/weather_morning_test.dart::rain / heat / cold ahead → the matching kind; plain sky → none |
| NT-03 | Cửa sổ | Sự kiện ngoài 14 giờ sau 07:30 | Tính | Không tính | unit: test/weather_morning_test.dart::only the 14 hours after 07:30 count |
| NT-04 | Tươi | Dự báo >18 giờ tuổi lúc nổ | Tính | Không báo | unit: test/weather_morning_test.dart::forecast older than 18 h at 07:30 → no notice |
| NT-05 | Trần | 3 lần trong 7 ngày | Tính | Lần thứ 4 bị chặn | unit: test/weather_morning_test.dart::at most 3 in 7 days |
| NT-06 | Trùng loại | Hôm qua đã báo cùng loại | Tính | Không báo lại | unit: test/weather_morning_test.dart::never the same kind two days running |
| NT-07 | Nhật ký | Arm rồi bỏ | Ghi | Ghi mục sáng sắp tới khi arm, xoá khi bỏ; mục cũ >14 ngày dọn | unit: test/weather_morning_test.dart::the log: record the coming morning, forget it when dropped |
| NT-08 | Provider | Mưa ở chỗ người ấy | Tải | Đặt đúng 1 thông báo; tắt công tắc thì huỷ + xoá nhật ký sáng mai | unit: test/weather_provider_test.dart::rain ahead at the partner's place → one notice armed |
| NT-09 | Provider | Couple chờ / người ấy chưa có thành phố | Tải | Không đặt gì | unit: test/weather_provider_test.dart::waiting couple or no partner city → nothing armed |
| NT-10 | Tuần tự | Đặt lịch chậm, huỷ mới hơn | Chạy | Lệnh huỷ không bị lệnh đặt cũ đè | unit: test/weather_provider_test.dart::notice syncs run in order: a slow arm never lands after a cancel |
| NT-11 | Định dạng | Locale vi/en | Xem Cài đặt | Giờ "07:30" / "7:30 AM" theo locale | unit: test/weather_morning_test.dart::notice time follows the locale format |
| NT-12 | Chạm | App tắt/nền/đang mở | Chạm thông báo | Mở Home rồi màn Quan tâm điền sẵn | unit: test/local_notification_tap_test.dart::the weather morning notice routes to its own handler + test/local_notification_tap_test.dart::a reminder with a plain payload is ignored; luồng thật 3 trạng thái app: thủ công: thông báo local theo giờ thật 07:30, không giả được giờ máy ảo trong khuôn khổ này |
| NT-13 | Chạm | Payload hỏng / thành phố lạ | Chạm | Cuộn tới thẻ, không mở Quan tâm | unit: test/weather_gap_provider_test.dart::NT-13: a damaged payload is still routed to Home, others are not + test/weather_gap_source_test.dart::NT-13: a payload with an unknown city / cta only scrolls to the card (kiểm nguồn; `_onWeatherNoticeTap` là private trong HomeScreen) |
| NT-14 | Nổ thật | Đã arm | Chờ 07:30 | Thông báo hiện đúng chữ | thủ công: cần chờ giờ thật (hoặc đổi giờ máy ảo, không làm trong đợt này) |
| NT-15 | Quyền | Chưa cấp quyền thông báo | Gạt công tắc | Xin quyền; từ chối thì SnackBar, trần vẫn đếm (chấp nhận) | thủ công: hộp quyền hệ thống; Maestro chỉ bấm optional (07_settings_android.yaml) |
| NT-16 | Rời couple | 1160 đã arm | Người ấy rời | Huỷ 1160 ngay khi nhận push `partner_left` (nền + tiền cảnh) | unit (kiểm nguồn): test/weather_gap_source_test.dart::NT-16: partner_left cancels 1160 in the background AND the foreground handler — hàm vẫn private, hành vi chưa chạy thật; test chỉ khoá cấu trúc + CF có `wakeClients` |
| NT-17 | Rời couple | App tắt lúc partner_left | Mở lại | `clear()` huỷ 1160 | unit: test/weather_provider_test.dart::sign-out clears state and the Hive cache (phần clear); nhánh "rời couple" riêng: unit: test/weather_gap_provider_test.dart::NT-17: clear() (no couple any more) cancels 1160 without wiping the cache |
| NT-18 | Giới hạn iOS | Đã có ~64 pending khác | Đặt 1160 | Không đẩy mất thông báo khác | chưa phủ: không dựng được hàng đợi 64 thông báo của iOS bằng unit; chỉ khoá được phần mình kiểm soát: unit (kiểm nguồn): test/weather_gap_source_test.dart::NT-18: 1160 is one fixed id and replaces itself (never two pending) |
| NT-19 | Inbox | — | Mở Notification center | Không có mục thời tiết (không inbox, không push server) | unit: functions/test/weather_gap.test.js::CF-21 / NT-19: the weather feature writes no inbox item and sends no push |

## 9. Cài đặt

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| ST-01 | Mục | Đã ghép | Cài đặt, cuộn | Mục "Thời tiết hai nơi" ngay sau nhóm Thông báo, đủ: Chỗ của bạn, Chỗ {tên}, công tắc, xem trước, dòng MET | maestro: maestro/weather/07_settings_android.yaml |
| ST-02 | Chọn | Đã ghép | Bấm "Chỗ của bạn" | Mở bảng chọn, chọn xong cập nhật | maestro: maestro/weather/02_pick_self_settings_android.yaml |
| ST-03 | Chọn giúp | Người ấy chưa tự chọn | Bấm "Chỗ {tên}" | Mở bảng chọn giúp | unit: test/weather_gap_widget_test.dart::ST-03: "Chỗ Thảo" opens the picker while she has not picked + test/weather_gap_widget_test.dart::ST-03: once Thảo picked herself the row is not tappable; đường bấm-được: maestro: maestro/weather/03_pick_for_partner_android.yaml (đường thẻ) |
| ST-04 | Chọn giúp | Người ấy đã tự chọn | Bấm "Chỗ {tên}" | Không mở được (D6) | maestro: maestro/weather/07_settings_android.yaml |
| ST-05 | Công tắc | Đã ghép | Tắt/bật | Tắt thì huỷ 1160 + xoá mục sáng mai; bật thì arm lại | unit: test/weather_provider_test.dart::rain ahead at the partner's place → one notice armed + maestro: maestro/weather/07_settings_android.yaml |
| ST-06 | Công tắc | Couple chờ người ấy | Xem | Công tắc khoá, "Ghép đôi xong mới báo được." | unit: test/weather_gap_widget_test.dart::ST-06: waiting couple → the switch is locked with its reason |
| ST-07 | Mục | Chưa có couple | Mở Cài đặt (bản rút gọn) | Không có mục thời tiết | unit (kiểm nguồn): test/weather_gap_source_test.dart::ST-07: the weather section of Settings only exists inside `if (hasCouple)` (không dựng cả SettingsScreen) |
| ST-08 | Xem trước | — | Xem | Mẫu thông báo mưa đúng chữ | maestro: maestro/weather/07_settings_android.yaml |

## 10. Analytics

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| AN-01 | Event | Opt-out analytics bật | Dùng feature | Không event nào | unit (kiểm nguồn + chạy một phần): test/weather_gap_source_test.dart::AN-01: every weather event goes through AnalyticsService.logEvent + test/weather_gap_source_test.dart::AN-01: logEvent is a no-op without a bound SDK or after opt-out |
| AN-02 | `weather_city_set` | Chọn thành công | Chọn | `{who, region, entry}`; chỉ log khi ghi thành công | unit (kiểm nguồn): test/weather_gap_source_test.dart::AN-02: weather_city_set carries who / region / entry only + test/weather_gap_source_test.dart::AN-02 / CH-22: the event sits inside `if (ok)`, the failure branch logs nothing |
| AN-03 | `weather_card_tap` / `weather_cta_tap` | Chạm thẻ / nút | Chạm | `{state}` / `{condition, entry}` | unit (kiểm nguồn): test/weather_gap_source_test.dart::AN-03: weather_card_tap {state} — fixed vocabulary, no city + test/weather_gap_source_test.dart::AN-03 / CT-06: weather_cta_tap {condition, entry}; card for card+sheet |
| AN-04 | `weather_notif_toggle` | Gạt công tắc | Gạt | `{enabled}` | unit (kiểm nguồn): test/weather_gap_source_test.dart::AN-04: weather_notif_toggle {enabled} is logged after the permission, before the write |
| AN-05 | Thực tế | DEBUG build | Mở DebugView | Event xuất hiện | thủ công: cần Firebase DebugView, không thuộc máy ảo/Maestro |

## 11. Rules Firestore `couples/{id}/weather/{uid}`

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| RL-01 | Ghi | Thành viên | Chọn chỗ của mình | Cho | unit: firebase_rules_test/test/firestore.weather.test.js::lets a member pick their own city |
| RL-02 | Đọc | Thành viên | Đọc chỗ người ấy | Cho | unit: firebase_rules_test/test/firestore.weather.test.js::lets a member read the partner city |
| RL-03 | Chọn giúp | Người ấy chưa có doc | Ghi doc của họ | Cho | unit: firebase_rules_test/test/firestore.weather.test.js::lets a member pick for the partner when the partner has none yet |
| RL-04 | Chọn giúp | Doc do mình chọn giúp | Đổi tiếp | Cho | unit: firebase_rules_test/test/firestore.weather.test.js::lets a member change a city they picked for the partner |
| RL-05 | Chọn giúp | Người ấy tự chọn | Ghi đè | Chặn | unit: firebase_rules_test/test/firestore.weather.test.js::forbids overwriting a city the partner picked themselves |
| RL-06 | Ngoài couple | uid không thuộc couple | Ghi doc | Chặn | unit: firebase_rules_test/test/firestore.weather.test.js::forbids writing a doc for a uid outside the couple |
| RL-07 | Ngoài couple | Người ngoài | Đọc/ghi | Chặn | unit: firebase_rules_test/test/firestore.weather.test.js::forbids outsiders reading or writing |
| RL-08 | Giả mạo | `setBy` ≠ auth.uid | Ghi | Chặn | unit: firebase_rules_test/test/firestore.weather.test.js::forbids spoofing setBy |
| RL-09 | Thời gian | `updatedAt` ≠ request.time | Ghi | Chặn | unit: firebase_rules_test/test/firestore.weather.test.js::requires updatedAt == request.time |
| RL-10 | Riêng tư | Thêm key (tên, toạ độ) | Ghi | Chặn (`hasOnly`) | unit: firebase_rules_test/test/firestore.weather.test.js::forbids extra keys (no name / coordinates stored) |
| RL-11 | Định dạng | cityId rỗng, quá dài, lạ dạng | Ghi | Chặn | unit: firebase_rules_test/test/firestore.weather.test.js::forbids an empty, over-long or odd-shaped cityId |
| RL-12 | Xoá | Xoá doc của mình / của người ấy | Xoá | Mình được, người ấy không | unit: firebase_rules_test/test/firestore.weather.test.js::lets the owner delete their city, never the partner one |
| RL-13 | Chờ | Couple chờ người ấy | Ghi | Chỉ doc của mình | unit: firebase_rules_test/test/firestore.weather.test.js::while waiting for a partner: own city only |
| RL-14 | Đã rời | Thành viên đã rời | Đọc/ghi | Mất quyền | unit: firebase_rules_test/test/firestore.weather.test.js::a member who left loses access; the doc they left behind is not theirs to keep |
| RL-15 | Cache | Client | Đọc/ghi `weatherCache` | Chặn hết | unit: firebase_rules_test/test/firestore.weather.test.js::keeps weatherCache closed to every client |
| RL-16 | Tương thích | App cũ ghi mood | Ghi | Không vỡ | unit: firebase_rules_test/test/firestore.weather.test.js::older apps are unaffected: moods keep working next to weather docs |
| RL-17 | App 1.11.0 song song | Một máy bản cũ, một máy bản mới | Dùng chung couple | Không lỗi permission | thủ công: cần build bản cũ trên 1 máy ảo, 2 máy hiện đang bận |

## 12. Rời couple, xoá tài khoản

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| LV-01 | Dọn | Hai người, người A rời | `notifyPartnerLeft` | Xoá `weather/{A}`; người ghép sau không thấy thành phố cũ | unit: functions/test/weather_gap.test.js::LV-01: notifyPartnerLeft deletes weather/{leaverUid} of that couple, nothing else + functions/test/weather_gap.test.js::LV-01: a failed delete is logged and does not stop the rest of the cleanup |
| LV-02 | Dọn | Người cuối rời / xoá couple | `deleteCoupleCompletely` | `recursiveDelete(couples/{id}/weather)` | unit: functions/test/index.test.js::teardown also removes every member's weather city (feature weather) |
| LV-03 | UI | Người ấy rời | Mở Home | Thẻ về trạng thái chờ, bỏ làn người ấy | unit: test/weather_gap_provider_test.dart::LV-03: after the partner left the card is the waiting one (my lane only); luồng thật phá cặp test3/test4: thủ công |

## 13. Ngôn ngữ, đơn vị, a11y

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| LG-01 | Ngôn ngữ | Đổi app sang English | Xem thẻ, sheet, Cài đặt | Chữ en đủ, "HCMC", "Rain this afternoon"; không lẫn tiếng Việt | unit: test/weather_gap_widget_test.dart::LG-01: English — invite, lanes, stale, error, sheet, settings + test/weather_gap_widget_test.dart::LG-01: English picker and detail sheet + test/weather_gap_source_test.dart::LG-03 / LG-01: no Vietnamese letters in the English strings |
| LG-02 | Ngôn ngữ | Đổi ngôn ngữ lúc app mở | Đổi | Thẻ + thông báo 07:30 arm lại theo ngôn ngữ mới | unit: test/weather_gap_provider_test.dart::LG-02: the 07:30 notice is armed again in the new language (thẻ tự vẽ lại theo locale của MaterialApp) |
| LG-03 | Chữ | 86 key `weather*` | Rà | Mỗi key có ở cả `app_en.arb` và `app_vi.arb` | unit: test/weather_gap_source_test.dart::LG-03: every weather* key exists in both files + test/weather_gap_source_test.dart::LG-03: same {placeholders} in en and vi, none empty |
| UN-01 | Đơn vị | Feature | Xem | Chỉ °C; không có tuỳ chọn °F (ngoài phạm vi) | maestro: maestro/weather/07_settings_android.yaml (không có hàng đơn vị) |
| A11-01 | A11y | TalkBack/VoiceOver | Đọc thẻ | Nhãn "Thời tiết hai nơi. Bạn: Hà Nội 31 độ…"; lỗi là `liveRegion` | thủ công: cần TalkBack/VoiceOver thật, Maestro chỉ đọc cây semantics |
| A11-02 | A11y | Chữ 200% | Xem | Không tràn | unit: test/weather_card_test.dart::320 dp at 200% text: no overflow (state 21) |
| A11-03 | A11y | Mục tiêu chạm | Đo | ≥44 dp (nút, hàng bảng chọn ≥52) | unit: test/weather_gap_widget_test.dart::A11-03: invite buttons are ≥ 44 dp + test/weather_gap_widget_test.dart::A11-03: nudge, "Chọn giúp" and retry are ≥ 44 dp + test/weather_gap_widget_test.dart::A11-03: city rows in the picker are ≥ 52 dp |

## 14. Bảo mật, riêng tư (ngoài code)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| SEC-01 | Privacy policy | Trang `phase3` | Đọc | Có nhắc thành phố + MET Norway | thủ công: tài liệu web, chưa cập nhật (Tester Med) |
| SEC-02 | Khai báo store | ASC / Play | Kiểm | Coarse Location / "Vị trí gần đúng" đã khai | thủ công: console store |
| SEC-03 | Sao lưu | Hive `weather_cache` | Kiểm thư mục | Nằm trong thư mục không sao lưu | unit (đang skip, BUG): test/weather_gap_source_test.dart::SEC-03: the forecast cache lives in a folder that is not backed up — nợ đã ghi, test đỏ khi bỏ skip |
| SEC-04 | MET | `User-Agent` | Gọi | Có website, không email | unit: functions/test/weather.test.js::expired → MET with User-Agent + If-Modified-Since → cache rewritten |

## Tổng số case theo cách kiểm

Đếm theo từ khoá đầu tiên của cột "Cách kiểm" (case có nhiều cách thì tính theo cách đầu, flow Maestro đi kèm được liệt kê trong dòng). Cập nhật sau đợt test bổ sung `weather_gap_*` (2026-10-23).

| Cách kiểm | Số case |
|---|---|
| unit (đã có test phủ) | 150 |
| maestro (chỉ chạy được trên máy ảo) | 18 |
| chưa phủ | 1 |
| thủ công | 8 |
| **Tổng** | **177** |

Trong số 150 case unit: 2 case có test đang `skip` vì lộ nợ thật (CF-22 không giới hạn/App Check cho `getCityWeather`; SEC-03 `weather_cache` nằm trong thư mục được sao lưu) và ~10 case là kiểm nguồn (đọc file `.dart`/`index.js` bằng regex, ghi "kiểm nguồn" trong dòng) vì code đích private hoặc nằm sau singleton nền tảng (Analytics, plugin thông báo, HomeScreen). Các dòng này khoá cấu trúc, không chứng minh hành vi chạy thật.

Trong đó 28 case có kèm flow Maestro (kể cả case đã có unit; cột này đếm cả dòng ghi `+ maestro:`).

Theo nhóm:

| Nhóm | unit | maestro | chưa phủ | thủ công |
|---|---|---|---|---|
| 1. Chọn thành phố | 21 | 1 | 0 | 0 |
| 2. Vị trí (phủ định) | 1 | 3 | 0 | 0 |
| 3. Tải dữ liệu phía app (WeatherProvider / Hive) | 16 | 1 | 0 | 0 |
| 4. Cloud Function `getCityWeather` + cache MET | 22 | 0 | 0 | 0 |
| 5. Logic tình trạng, độ chênh, hàng chung | 26 | 0 | 0 | 0 |
| 6. Thẻ Home và màn chi tiết | 10 | 6 | 0 | 0 |
| 7. Nhắc người ấy (nút gợi ý → Quan tâm) | 4 | 2 | 0 | 1 |
| 8. Thông báo local 07:30 (id 1160) | 16 | 0 | 1 | 2 |
| 9. Cài đặt | 4 | 4 | 0 | 0 |
| 10. Analytics | 4 | 0 | 0 | 1 |
| 11. Rules Firestore `couples/{id}/weather/{uid}` | 16 | 0 | 0 | 1 |
| 12. Rời couple, xoá tài khoản | 3 | 0 | 0 | 0 |
| 13. Ngôn ngữ, đơn vị, a11y | 5 | 1 | 0 | 1 |
| 14. Bảo mật, riêng tư (ngoài code) | 2 | 0 | 0 | 2 |
