# Bộ test case feature `arrival` (báo "đã tới nơi")

> Nhánh `feature/daily-open-2`. Nguồn: `overview.md` (D1–D23), `design.md`, `dev.md`, `test.md`, `spike.md`; code `lib/`, `android/.../arrival/ArrivalChannel.kt`, `ios/Runner/AppDelegate.swift`, `functions/index.js`, `firestore.rules`.
> Vị trí đặt máy ảo, thứ tự chạy flow, lệnh đổi vị trí: `maestro/arrival/README.md`.

## Quy ước

- **Cách kiểm** là một trong:
  - `unit: <file>::<tên test>` — đã có test phủ, tên test khớp nguyên văn trong file (đã grep).
  - `maestro: maestro/arrival/<flow>` — chạy trên 2 máy ảo (Android = Tuấn `test3`, iOS = Thảo `test4`, Firebase DEV).
  - `chưa phủ → đề xuất unit: …` — chưa test nào; ghi sẵn test nên viết.
  - `thủ công: <lý do>` — máy ảo không làm được.
- File test: `arrival_test.dart` (provider/service/model), `arrival_ui_test.dart` (widget), `arrival_native_test.dart` (callback nền, cầu isolate), `arrival_place_query_test.dart` (rút gọn địa chỉ) đều ở `test/`; `functions/test/index.test.js` (CF `notifyArrival` và dọn dẹp); `firestore.arrival.test.js` ở `firebase_rules_test/test/` (rules).
- Case có nhiều cách kiểm thì ghi hết, cách đầu tiên quyết định cột phân loại ở bảng tổng cuối file.
- Giới hạn máy ảo đã biết (Lead 2026-10-22): push iOS DEV không có APNs key; Android emulator không đăng ký được FCM (inbox Firestore thì test được, nhưng arrival cố ý không có inbox, D15); GPS emulator Android không đổi theo `adb emu geo fix` nên "Dùng vị trí hiện tại" và geofence Android không tin được trên emulator — các case gửi từ Android dùng bấm tay, các case tự động dùng iOS simulator làm người gửi.


## Bật/tắt

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| BT-01 | Bật/tắt | Couple active, không ai bật | Mở Home, cuộn tới thẻ "Về đến nhà chưa?" | Thẻ lời mời: nút đặc "Bật báo về nhà" + nút viền "Về nhà rồi" | unit: arrival_ui_test.dart::nobody on yet: pitch + "Bật báo về nhà" + "Về nhà rồi"; maestro: maestro/arrival/00_reset_android.yaml |
| BT-02 | Bật/tắt | Chưa bật, chưa cấp quyền vị trí | Bấm "Về nhà rồi" | Gửi sự kiện Home bấm tay (kèm pin), bật chia sẻ, không xin quyền; hiện "Đã báo {tên}" 4 s | unit: arrival_test.dart::"Về nhà rồi" sends Home + battery, no permission needed; maestro: maestro/arrival/02_manual_home_android.yaml |
| BT-03 | Bật/tắt | Đang chia sẻ | Manage → công tắc "Báo cho {tên}" → hộp "Tắt báo về nhà?" → Tắt | Doc `arrival/{uid}` bị xoá (1 lệnh ghi), geofence dừng, tự báo tắt | unit: arrival_test.dart::sharing off: one write, geofences stop, locations optional (D11); unit: arrival_ui_test.dart::turn off → dialog with "xoá luôn địa chỉ" → off + wiped; maestro: maestro/arrival/11_turn_off_ios.yaml |
| BT-04 | Bật/tắt | Đang chia sẻ, có ≥1 nơi lưu | Hộp tắt: tick "Xoá luôn địa chỉ đã lưu của N nơi" → Tắt | Địa chỉ/toạ độ trên máy bị xoá, Nhà vẫn còn trên thẻ | unit: arrival_ui_test.dart::turn off → dialog with "xoá luôn địa chỉ" → off + wiped |
| BT-05 | Bật/tắt | Đã tắt chia sẻ | Bật lại bằng "Về nhà rồi" | Chia sẻ bật lại nhưng KHÔNG tự dùng vị trí nền (wantsAuto=false) tới khi đồng ý lại | unit: arrival_test.dart::sharing off: one write, geofences stop, locations optional (D11) |
| BT-06 | Bật/tắt | `config/app.arrivalAutoEnabled=false` (D13) | Mở Manage, mở app | Công tắc "Tự báo" khoá, dòng "Tạm thời chỉ báo bằng tay"; geofence nền dừng ở sự kiện đầu | unit: arrival_test.dart::auto runs only with share + Always + a located place + remote on; unit: arrival_native_test.dart::remote switch off (D13) → stop, nothing sent |
| BT-07 | Bật/tắt | Pitch, chưa có vị trí Nhà | Bật báo về nhà → "Để sau" | Đóng luồng, không bật gì, thẻ vẫn là lời mời | maestro: maestro/arrival/01_decline_android.yaml |
| BT-08 | Bật/tắt | Build Android với `kArrivalAutoAndroid=false` (kế hoạch B Play) | Mở Manage | Ẩn hẳn chế độ tự báo; bấm tay + "Dùng vị trí hiện tại" vẫn chạy | unit: test/arrival_gap_test.dart::provider BT-08: auto build not allowed → auto never available/running (ẩn công tắc trong Manage do hằng build `const`: thủ công) |
| BT-09 | Bật/tắt | Chưa bật, Nhà chưa có vị trí | Bật báo về nhà | Màn "Trước hết, nhà bạn ở đâu?" trước màn giải thích quyền (không xin quyền khi chưa cần) | unit: arrival_ui_test.dart::no place with a location → "Trước hết, nhà bạn ở đâu?"; maestro: maestro/arrival/01_decline_android.yaml |

## Quyền vị trí

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| QV-01 | Quyền vị trí | Chưa cấp quyền | Lưu địa chỉ Nhà bằng gõ địa chỉ | Không có hộp quyền nào (toạ độ lấy từ geocoder) | unit: arrival_ui_test.dart::name + chip → search → confirm (no house no.) → save |
| QV-02 | Quyền vị trí | Đã có Nhà, chưa cấp quyền | Giải thích (D12) → "Đồng ý, tiếp tục" | Mới xin "Khi dùng ứng dụng" (iOS WhenInUse / Android FINE+COARSE), chưa xin Luôn luôn (D8) | unit: arrival_ui_test.dart::Android: disclosure → OS label step → back from the page → done; maestro: maestro/arrival/08_auto_setup_ios.yaml |
| QV-03 | Quyền vị trí | Hộp quyền hiện | Từ chối | "Dừng giữa chừng": báo bằng tay, nơi đã lưu giữ nguyên, không hỏi lại ngay | unit: arrival_ui_test.dart::a plugin error never leaves the button spinning; unit: test/arrival_gap_ui_test.dart::permissions QV-03: Setup, system dialog refused → "Tạm thời bạn báo bằng tay" |
| QV-04 | Quyền vị trí | Chỉ có "Khi dùng ứng dụng" | Bật tự báo / mở app | "Chưa tự báo được: cần quyền vị trí Luôn luôn" + "Mở Cài đặt"; không đăng ký geofence | unit: arrival_test.dart::auto runs only with share + Always + a located place + remote on; maestro: maestro/arrival/09_perm_downgrade_ios.yaml |
| QV-05 | Quyền vị trí | Đã có WhenInUse | Bước 2 "Chọn “Luôn luôn”" / "Cho phép mọi lúc" → cấp | Màn "Đã bật báo về nhà", geofence đăng ký đúng các nơi có vị trí | unit: arrival_ui_test.dart::Android: disclosure → OS label step → back from the page → done; maestro: maestro/arrival/08_auto_setup_ios.yaml |
| QV-06 | Quyền vị trí | iOS: đang WhenInUse; Android: dùng quyền gần đúng | "Dùng vị trí hiện tại" với Vị trí chính xác TẮT | Khung "Cần bật Vị trí chính xác", không lưu toạ độ lệch | unit: test/arrival_gap_ui_test.dart::permissions QV-06: Precise Location off → "Cần bật Vị trí chính xác", no fix read |
| QV-07 | Quyền vị trí | Đang tự báo, Luôn luôn | Hạ quyền trong Cài đặt máy, quay lại app | onResume đọc lại quyền → `needsAlways`, dừng geofence, cờ `auto:false` đồng bộ lên doc | unit: arrival_test.dart::auto runs only with share + Always + a located place + remote on; maestro: maestro/arrival/09_perm_downgrade_ios.yaml |
| QV-08 | Quyền vị trí | Android 11+: đã từ chối "mọi lúc" 2 lần | Bước 2 → "Mở trang quyền" | Hệ thống không hiện gì (< 400 ms) → app mở trang chi tiết app; màn đứng ở bước 2 đến khi quay lại | thủ công: ngưỡng 400 ms cần máy thật; emulator trả về khác nhau theo image |
| QV-09 | Quyền vị trí | Android API 29 / 30 / 31+ | Cấp quyền nền | API 29 cấp cùng hộp; 30+ qua trang Cài đặt; nhãn "Cho phép mọi lúc" lấy từ máy | unit: arrival_ui_test.dart::Android: disclosure → OS label step → back from the page → done; thủ công: cần 3 image emulator API khác nhau, người khác đang dùng máy ảo |
| QV-10 | Quyền vị trí | Dịch vụ vị trí hệ thống TẮT | "Dùng vị trí hiện tại" → Đọc vị trí | Trả null ngay → "Chưa đọc được vị trí", thử lại được, không treo spinner | unit: arrival_ui_test.dart::no fix in time → "Chưa đọc được vị trí", can retry |
| QV-11 | Quyền vị trí | iOS notDetermined | Gọi xin Luôn luôn khi chưa có WhenInUse | Native chỉ xin Luôn luôn khi đang WhenInUse; trạng thái khác trả nguyên (giữ thứ tự D8) | thủ công: logic Swift `ArrivalChannel`, không có test Dart; kiểm bằng 08 sau `simctl privacy reset location` |
| QV-12 | Quyền vị trí | Hộp xin quyền từ chối khi "Dùng vị trí hiện tại" | Từ chối | Quay về ô tìm địa chỉ, KHÔNG hỏi lại lần 2 | unit: arrival_ui_test.dart::permission refused → back to search, asked once |
| QV-13 | Quyền vị trí | Manifest Android | `aapt2 dump permissions` APK release | Có COARSE+FINE+BACKGROUND; KHÔNG có `FOREGROUND_SERVICE_LOCATION` | thủ công: lệnh aapt2 trên APK, không cần máy ảo |

## Đặt địa điểm

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| DD-01 | Đặt địa điểm | Đã chia sẻ, còn chỗ | Thêm nơi: chip "Công ty" → Tiếp tục → tìm địa chỉ → Xác nhận → Lưu | Nơi lưu, snackbar "Đã lưu {nơi}", biểu tượng tự theo chip | unit: arrival_ui_test.dart::name + chip → search → confirm (no house no.) → save; maestro: maestro/arrival/04_add_place_ios.yaml |
| DD-02 | Đặt địa điểm | Màn đặt tên | Gõ tên có khoảng trắng đầu/cuối, 24/25 ký tự, emoji, xuống dòng | Trim; 1..24 đơn vị UTF-16 (emoji = 2); 1 dòng | unit: arrival_test.dart::trims, 1..24 UTF-16 units, one line; unit: firestore.arrival.test.js::name: 24 units pass, 25 do not (UTF-16, emoji = 2); unit: firestore.arrival.test.js::forbids a line break in the name |
| DD-03 | Đặt địa điểm | Màn đặt tên | Để trống rồi bấm Tiếp tục | Hiện "Gõ tên để tiếp tục. Tối đa 24 ký tự.", không sang bước sau | unit: test/arrival_gap_ui_test.dart::name screen DD-03: empty / blank name → hint shown, Continue locked |
| DD-04 | Đặt địa điểm | Kết quả tìm có số nhà | Chọn kết quả | Màn xác nhận không có hộp cảnh báo; bán kính 250 m | unit: arrival_ui_test.dart::confirm: with a house number → no warning |
| DD-05 | Đặt địa điểm | Kết quả thiếu số nhà | Chọn kết quả | Hộp "Địa chỉ này chưa có số nhà…" | unit: arrival_ui_test.dart::name + chip → search → confirm (no house no.) → save |
| DD-06 | Đặt địa điểm | Địa chỉ trong hẻm (x/y) | Chọn kết quả | Truy vấn gửi đầu hẻm, hộp cảnh báo hẻm | unit: arrival_ui_test.dart::confirm: alley number → alley warning; unit: arrival_place_query_test.dart::alley probes send the alley mouth, flagged approximate |
| DD-07 | Đặt địa điểm | Android: Geocoder | Gõ địa chỉ | Chờ 800 ms rồi mới tìm, hiện gợi ý "bấm Tìm" | unit: arrival_ui_test.dart::Android: waits 800 ms, then results + "bấm Tìm" tip |
| DD-08 | Đặt địa điểm | Gõ địa chỉ không có kết quả / mất mạng / lỗi tạm | Tìm | Hiện đúng thông báo + lối "Dùng vị trí hiện tại", không văng | unit: arrival_ui_test.dart::not found / offline → message + "Dùng vị trí hiện tại" |
| DD-09 | Đặt địa điểm | Máy không có geocoder (`isPresent()==false`) | Tìm | "Máy này không tra được địa chỉ"; có "Lưu tên, chỉ bấm tay" | unit: arrival_ui_test.dart::no geocoder → "Lưu tên, chỉ bấm tay" saves without address |
| DD-10 | Đặt địa điểm | Rút gọn truy vấn/lọc tỉnh | Gõ 20 địa chỉ mẫu spike (phường/quận/Việt Nam, tên tỉnh cũ) | Rút gọn đúng, kết quả sai tỉnh bị loại, tối đa 5 | unit: arrival_place_query_test.dart::shortenArrivalPlaceQuery — spike table; unit: arrival_place_query_test.dart::wrong province dropped, merged / unnamed / street-named kept; unit: arrival_native_test.dart::search results: other province dropped, alley flag, ≤ 5 |
| DD-11 | Đặt địa điểm | Gõ nhanh trên iOS (MKLocalSearch) | Gõ liên tục 12 Nguyễn Tr… | Throttle `loadingThrottled` → UI rơi về "Dùng vị trí hiện tại"; không văng | thủ công: MapKit trên simulator không đại diện cho throttle thật |
| DD-12 | Đặt địa điểm | Đang đứng tại nơi cần lưu | "Dùng vị trí hiện tại" → Đọc vị trí → Lưu (150 m) | Lưu với bán kính 150 m, "lệch khoảng N m" | unit: arrival_ui_test.dart::no fix in time → "Chưa đọc được vị trí", can retry; maestro: maestro/arrival/04_add_place_ios.yaml |
| DD-13 | Đặt địa điểm | Không có vị trí trong 15 s | Đọc vị trí | Hộp vàng `liveRegion`, nút Đọc vị trí bấm lại được | unit: arrival_ui_test.dart::no fix in time → "Chưa đọc được vị trí", can retry |
| DD-14 | Đặt địa điểm | Đã có nơi | Sửa tên nơi → Lưu | Lưu bị khoá tới khi có thay đổi; đổi tên chỉ áp cho lần đến sau | unit: arrival_ui_test.dart::rename a place → saved, Save locked until a change |
| DD-15 | Đặt địa điểm | Sửa Nhà | Mở Nhà | Không đổi tên được; "Xoá địa chỉ" chỉ hiện khi đã có địa chỉ | unit: arrival_ui_test.dart::Home: no rename, "Xoá địa chỉ" only once it has one |
| DD-16 | Đặt địa điểm | Có nơi | Xoá nơi → hộp hỏi lại → Xoá → "Hoàn tác" trong 5 s | Nơi trở lại đúng slot cũ | unit: arrival_ui_test.dart::delete a place → "Hoàn tác" brings it back |
| DD-17 | Đặt địa điểm | Vừa xoá nơi, slot còn giữ 6 s | Thêm nơi khác rồi bấm Hoàn tác | Không ghi đè nơi mới; báo "Chưa hoàn tác được" | unit: arrival_ui_test.dart::undo: slot held 5 s; taken anyway → says it can't |
| DD-18 | Đặt địa điểm | Nhà + 4 nơi | Mở Manage | Không còn dòng "Thêm nơi"; 3 nơi thì "Còn 1 chỗ" | unit: arrival_ui_test.dart::4 custom places → no "Thêm nơi"; 3 → "Còn 1 chỗ"; unit: arrival_test.dart::Home + at most 4 custom places; Home is never removed |
| DD-19 | Đặt địa điểm | Lưu thất bại (đủ chỗ / lỗi Hive) | Bấm Lưu ở Xác nhận | Ở lại màn, SnackBar `arrivalPlacesFull`/`arrivalSaveFailed`; bấm đúp bị khoá | unit: arrival_ui_test.dart::confirm: save fails → stays + says so |
| DD-20 | Đặt địa điểm | Nhà là slot 0 | Xoá địa chỉ Nhà | Nhà vẫn nằm đầu thẻ, chỉ mất vị trí; xoá nơi cuối khi đang tự báo → tắt Tự báo | unit: arrival_test.dart::Home + at most 4 custom places; Home is never removed |
| DD-21 | Đặt địa điểm | Hai nơi trùng toạ độ, hoặc nơi nằm trong 250 m quanh Nhà | Lưu cả hai | Hai vùng chồng nhau vẫn hợp lệ; sự kiện vào/ra từng slot không lẫn | unit: test/arrival_gap_test.dart::provider DD-21: two overlapping places keep separate in/out state |
| DD-22 | Đặt địa điểm | Đổi tên nơi sau khi đã gửi sự kiện | Đổi tên, xem thẻ cũ | Thẻ/push cũ giữ tên lúc xảy ra (D23) | unit: arrival_test.dart::"Đến nơi rồi" snapshots the name; a rename later does not |
| DD-23 | Đặt địa điểm | Địa chỉ ngoài Việt Nam / ngoài khung VN | Gõ địa chỉ nước ngoài | Bị lọc ra (khung VN) → "không tìm thấy" | unit: test/arrival_gap_test.dart::address filter DD-23: a result in another province / abroad is dropped (khung VN nằm ở Geocoder native: thủ công) |

## Vào/ra vùng

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| SK-01 | Vào/ra vùng | Đang tự báo, ở ngoài Nhà | Vào Nhà (iOS `enter`; Android `dwell` 2 phút) | Ghi `last` = enter Home source auto → thẻ người ấy cập nhật, CF push 1 lần | unit: arrival_native_test.dart::reports through the edge filter, battery clamped, at = OS time; unit: functions/test/index.test.js::arrival: Home enter → one wake push to the partner, slot stamped, no inbox; maestro: maestro/arrival/10_auto_view_android.yaml |
| SK-02 | Vào/ra vùng | Đang ở Nhà | Rời Nhà (`exit`) | Thẻ đổi "Đã rời nhà"; KHÔNG push, KHÔNG widget (D4) | unit: functions/test/index.test.js::arrival: exit, bounce, stale, not shared, unchanged → no push; unit: arrival_ui_test.dart::app path: partner arrival of today wins; departures never |
| SK-03 | Vào/ra vùng | Vừa rời Nhà | Vào lại trong < 10 phút | `bounce`: ghi nhận nhưng không push | unit: arrival_test.dart::back within 10 minutes of leaving = bounce, later = real arrival; unit: functions/test/index.test.js::arrival: exit, bounce, stale, not shared, unchanged → no push |
| SK-04 | Vào/ra vùng | iOS vừa khởi động lại | Hệ thống bắn `enter` hai lần cùng trạng thái | Lần 2 bị bỏ (trùng trạng thái) | unit: arrival_test.dart::same state twice (iOS reboot double fire) is dropped |
| SK-05 | Vào/ra vùng | Bật tự báo khi đang đứng trong Nhà | Chờ | Không có initial trigger: không báo nhầm; sự kiện đầu là "rời Nhà" | unit: arrival_native_test.dart::fence: id = slot, radius from the place, no initial trigger; thủ công: hành vi hệ điều hành; simulator vùng nhận enter khi đổi vị trí vào trong |
| SK-06 | Vào/ra vùng | Android, đi ngang rìa vùng | Ở trong vùng < 2 phút rồi ra | Không báo (DWELL 2 phút, chủ ý D6) | thủ công: cần chạy thời gian thật; `adb emu geo fix` + dumpsys location không đổi theo Lead 2026-10-22 |
| SK-07 | Vào/ra vùng | Callback nền trễ | Sự kiện tới server muộn hơn 30 phút | Cập nhật thẻ nhưng không push (cũ) | unit: functions/test/index.test.js::arrival: exit, bounce, stale, not shared, unchanged → no push |
| SK-08 | Vào/ra vùng | Pin ≤ 20% | Sự kiện đến nơi | Thẻ pill vàng "Pin còn N%"; push thêm dòng pin | unit: arrival_ui_test.dart::both on: lanes Bạn · Thảo, low battery pill, Hỏi thăm; unit: functions/test/index.test.js::arrival: custom place uses its name verbatim + low battery line |
| SK-09 | Vào/ra vùng | iOS simulator (pin −1) | Gửi sự kiện | Không kèm pin (null), không lỗi | unit: arrival_native_test.dart::reports through the edge filter, battery clamped, at = OS time |
| SK-10 | Vào/ra vùng | Có ≥1 nơi tự đặt | "Đến nơi rồi" → sheet "Bạn vừa đến đâu?" → chọn nơi | Gửi tên nơi nguyên văn; người ấy thấy "Đã đến {nơi}" | unit: arrival_ui_test.dart::"Đến nơi rồi" sheet sends the picked place; maestro: maestro/arrival/05_manual_place_ios.yaml; maestro: maestro/arrival/06_view_place_android.yaml |
| SK-11 | Vào/ra vùng | Bấm tay "Về nhà rồi" rồi geofence bắn "đến Nhà" ngay | Hai sự kiện liên tiếp | Ghi 2 lần, CF cooldown 30 phút chặn push lần 2 | unit: functions/test/index.test.js::arrival: same place within 30' → cooldown; another place still pushes |
| SK-12 | Vào/ra vùng | Đã push Nhà < 30 phút trước | Đến nơi khác | Nơi khác vẫn push (cooldown theo slot) | unit: functions/test/index.test.js::arrival: same place within 30' → cooldown; another place still pushes |
| SK-13 | Vào/ra vùng | Spam: 7+ sự kiện/ngày | Gửi liên tiếp | Tối đa 6 push/ngày (ngày theo giờ VN), qua ngày reset | unit: functions/test/index.test.js::arrival: at most 6 pushes a day; the count resets on a new day; unit: functions/test/index.test.js::arrival: day bucket is Vietnam time |
| SK-14 | Vào/ra vùng | Bấm "Về nhà rồi" 5 lần liên tiếp | Chạm nhanh | Nút khoá khi đang gửi; không gửi chồng; CF cooldown chặn push thừa | unit: test/arrival_gap_test.dart::provider SK-14: 5 fast taps on "Về nhà rồi" write once |
| SK-15 | Vào/ra vùng | Hai sự kiện cách nhau ~1 s | Về Nhà rồi rời ngay | Push về Nhà bị bỏ (`superseded`), thẻ đúng sự kiện mới nhất | unit: functions/test/index.test.js::arrival: switched off or superseded before the claim → no push, no stamp |
| SK-16 | Vào/ra vùng | Sự kiện bấm tay | Đọc thẻ người ấy | Có nhãn "bấm tay"; sự kiện tự động không có | unit: arrival_ui_test.dart::both on: lanes Bạn · Thảo, low battery pill, Hỏi thăm; maestro: maestro/arrival/03_view_home_ios.yaml; maestro: maestro/arrival/10_auto_view_android.yaml |
| SK-17 | Vào/ra vùng | Giờ trên thẻ | Sự kiện hôm nay / hôm qua / 2–3 ngày / >3 ngày | "HH:mm" / "hôm qua" / "d/M HH:mm" / "Đang bật báo về nhà"; đổi lúc 0:00 | unit: arrival_ui_test.dart::both on: lanes Bạn · Thảo, low battery pill, Hỏi thăm; unit: arrival_ui_test.dart::partner off → neutral; partner on but quiet → "Đang bật" |

## Nền / kill / khởi động lại

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| NK-01 | Nền / kill / khởi động lại | Tự báo, app đang chạy nền (isolate chính sống) | Geofence bắn | Isolate chính xử lý đúng 1 lần (qua cầu IsolateNameServer), callback nền thả | unit: arrival_native_test.dart::live app isolate takes it, exactly once |
| NK-02 | Nền / kill / khởi động lại | Tự báo, app bị kill (Android) | Geofence bắn | Callback nền tự làm: Hive + Firebase + battery + `reportEvent` | unit: arrival_native_test.dart::no app isolate → the background isolate handles it; thủ công: phải máy thật, emulator không giữ geofence khi app chết ổn định |
| NK-03 | Nền / kill / khởi động lại | iOS, người dùng vuốt tắt app | Vào/ra vùng | Có thể KHÔNG báo (giới hạn iOS) — màn có gợi ý "Đừng vuốt tắt" | thủ công: hành vi iOS thật, simulator không mô phỏng việc app bị relaunch bởi region |
| NK-04 | Nền / kill / khởi động lại | Android khởi động lại / Force stop / tắt-bật vị trí | Khởi động máy rồi mở lại app | Vùng đăng ký lại ở lần mở app kế (`reCreateAfterReboot`), 1 lần mỗi tiến trình | thủ công: cần reboot máy; cờ `_reCreated` chưa có test riêng; không unit hoá được mà không sửa lib: `NativeArrivalGeofence.sync` chặn bằng `Platform.isAndroid` + singleton plugin, host test là macOS |
| NK-05 | Nền / kill / khởi động lại | Đang tự báo | Mở app (snapshot cache tới trước khi đọc quyền) | Không `stopAll()`, không `auto:false` khi chưa đọc xong quyền (BUG-1) | unit: arrival_test.dart::opening the app while "Tự báo" runs: no stop, no auto:false (BUG-1) |
| NK-06 | Nền / kill / khởi động lại | Doc `arrival/{me}` đã bị xoá (người ấy mới) | Geofence bắn | Dừng geofence + quên Tự báo + không lưu trạng thái trong/ngoài (D10) | unit: arrival_native_test.dart::doc gone (partner changed, D10) → stop + "Tự báo" forgotten |
| NK-07 | Nền / kill / khởi động lại | Không có session / tự báo tắt / `permission-denied` | Callback nền chạy | Mọi vùng dừng | unit: arrival_native_test.dart::no session / auto off / permission-denied → every region stops; unit: arrival_test.dart::a background write denied → every geofence stops |
| NK-08 | Nền / kill / khởi động lại | Isolate chính chết, tên cổng còn | Sự kiện tới | Sau 2 s tự xử lý, giữ tên; resume giành lại tên | unit: arrival_native_test.dart::stale name: falls back after 2 s, keeps the name; resume re-claims it |
| NK-09 | Nền / kill / khởi động lại | Tin trễ >1,5 s tới isolate chính | Nhận | Bị bỏ để khỏi ghi đôi | unit: arrival_native_test.dart::a late message is dropped by the app isolate |
| NK-10 | Nền / kill / khởi động lại | Bật Enforce App Check Firestore (sau này) | Callback nền, token chưa có | Ghi bị denied → hiểu nhầm "đã rời couple" → tắt Tự báo; cần kiểm trước khi Enforce | thủ công: App Check đang Unenforced; kiểm khi chuẩn bị Enforce |
| NK-11 | Nền / kill / khởi động lại | Xiaomi/Oppo/Vivo, Battery saver | Chờ geofence | Tin báo có thể bị chặn nếu chưa bật Tự khởi động (có gợi ý trong app) | thủ công: ROM nhà sản xuất, không có trên emulator |
| NK-12 | Nền / kill / khởi động lại | Android 14, app không chạy foreground | Nhận `GeofenceBroadcastReceiver` | Chạy qua WorkManager (quyền thường FOREGROUND_SERVICE), không dịch vụ vị trí | thủ công: kiểm manifest + logcat trên máy thật |

## Người ấy / couple

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| NA-01 | Người ấy / couple | Người ấy tắt chia sẻ | Mở Home | Làn người ấy: "Chưa bật báo về nhà", nền trung tính, không có nút Hỏi thăm | unit: arrival_ui_test.dart::partner off → neutral; partner on but quiet → "Đang bật"; maestro: maestro/arrival/12_view_off_android.yaml |
| NA-02 | Người ấy / couple | Người ấy bật nhưng im > 3 ngày | Mở Home | "Đang bật báo về nhà" + "Khi {tên} đến nơi, tin sẽ hiện ở đây." | unit: arrival_ui_test.dart::partner off → neutral; partner on but quiet → "Đang bật" |
| NA-03 | Người ấy / couple | A bật, B không (D10) | B mở Home | B thấy A về nhà, A không thấy gì của B; không ép qua lại | unit: arrival_ui_test.dart::both on: lanes Bạn · Thảo, low battery pill, Hỏi thăm; maestro: maestro/arrival/03_view_home_ios.yaml |
| NA-04 | Người ấy / couple | Provider: người ấy tắt | Đọc `partnerLast` | Chỉ trả khi người ấy đang chia sẻ | unit: arrival_test.dart::partner event shows only while they share |
| NA-05 | Người ấy / couple | Couple còn `waiting_partner` | Mở Home, Cài đặt | Ẩn thẻ và mục Cài đặt (D9); rules từ chối bật chia sẻ | unit: arrival_test.dart::hidden while the couple waits for a partner (D9); unit: firestore.arrival.test.js::sharing ON is refused while the couple waits for a partner |
| NA-06 | Người ấy / couple | Couple vừa chuyển active giữa phiên | Người ấy ghép xong | Thẻ xuất hiện với lời mời, `watchForCouple` re-arm | unit: test/arrival_gap_test.dart::provider NA-06: couple turns active mid-session → visible + watch armed |
| NA-07 | Người ấy / couple | Người ấy rời couple | CF `notifyPartnerLeft` | Xoá `arrival` + `arrivalPush` của cả 2; người ở lại như chưa bật; sổ push reset | unit: functions/test/index.test.js::arrival: partner left → arrival doc + push bookkeeping of leaver AND stayer go; unit: firestore.arrival.test.js::a member who left can no longer write |
| NA-08 | Người ấy / couple | Người ở lại ghép với người mới | Mở app | Doc của mình bị xoá (BUG-4); Tự báo phải đồng ý lại (D10) | unit: arrival_test.dart::a new partner: my doc is dropped once (BUG-4); unit: arrival_test.dart::a new partner must opt in to "Tự báo" again (D10) |
| NA-09 | Người ấy / couple | Hai lệnh `watchForCouple` chồng nhau lúc Hive đang tải | Mở app | D10 vẫn giữ (BUG-3) | unit: arrival_test.dart::two overlapping watches while Hive loads keep D10 (BUG-3) |
| NA-10 | Người ấy / couple | Xoá tài khoản (thành viên couple) | `deleteAccount` | Xoá `arrival/{uid}` + `arrivalPush/{uid}`, không đụng của người kia; xoá dữ liệu local | unit: functions/test/index.test.js::deleteAccount: a couple member's arrival doc + push bookkeeping go (arrival); unit: arrival_test.dart::account deletion wipes only that user |
| NA-11 | Người ấy / couple | Đăng xuất | Đăng nhập tài khoản khác trên máy | Geofence dừng; nơi của người trước KHÔNG hiện (Hive khoá theo uid) | unit: test/arrival_gap_test.dart::provider NA-11: sign-out stops geofences; places are per uid |
| NA-12 | Người ấy / couple | Tắt chia sẻ khi push đang trên đường | CF chạy transaction | `superseded`: không push, không ghi sổ | unit: functions/test/index.test.js::arrival: switched off or superseded before the claim → no push, no stamp |
| NA-13 | Người ấy / couple | Cùng tài khoản trên 2 máy | Máy mở sau xoá doc chia sẻ khi thấy người ấy mới | Hở đã biết (dev.md BUG-4): máy kia mất chia sẻ | thủ công: cần 2 máy cùng tài khoản + đổi couple |
| NA-14 | Người ấy / couple | Hỏi thăm | Chạm "Hỏi thăm {tên}" | Mở màn Quan tâm, tiêu đề điền sẵn "Về tới nơi rồi thì nghỉ ngơi nhé", thân trống | unit: arrival_ui_test.dart::both on: lanes Bạn · Thảo, low battery pill, Hỏi thăm; maestro: maestro/arrival/03_view_home_ios.yaml |

## Offline / lỗi mạng

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| OF-01 | Offline / lỗi mạng | Mất mạng | Bấm "Về nhà rồi" | Chờ ack 5 s → `queued`: dải "Sẽ báo khi có mạng" | unit: arrival_ui_test.dart::offline → "Sẽ báo khi có mạng"; unit: arrival_test.dart::offline: reported as queued, failure → retry same place; maestro: maestro/arrival/07_offline_manual_android.yaml |
| OF-02 | Offline / lỗi mạng | Có mạng lại | Doc đồng bộ | Dải chờ mạng biến mất khi snapshot hết `hasPendingWrites` (M1) | unit: arrival_ui_test.dart::queued strip goes once the server acks the event; maestro: maestro/arrival/07_offline_manual_android.yaml |
| OF-03 | Offline / lỗi mạng | Offline quá 30 phút | Đồng bộ lên | Người ấy chỉ thấy trên thẻ, không push (cũ) | unit: functions/test/index.test.js::arrival: exit, bounce, stale, not shared, unchanged → no push |
| OF-04 | Offline / lỗi mạng | Offline > 12 giờ | Đồng bộ lên | Rules từ chối (`at` quá cũ), SDK bỏ lặng lẽ | unit: firestore.arrival.test.js::at: ≤ 5 minutes ahead, ≤ 12 hours old |
| OF-05 | Offline / lỗi mạng | Gửi thất bại | Bấm "Thử lại" | Gửi lại đúng nơi, "Đã báo {tên}" | unit: arrival_ui_test.dart::failed → "Thử lại" sends again → "Đã báo Thảo" |
| OF-06 | Offline / lỗi mạng | `permission-denied` | Gửi | Dải lỗi + "Thử lại" như failed | unit: arrival_ui_test.dart::permission-denied → error strip + "Thử lại" |
| OF-07 | Offline / lỗi mạng | Nơi vừa bị xoá / couple hết active khi đang gửi | Gửi | `dropped`: SnackBar "Chưa gửi được tin …", không im lặng | unit: arrival_ui_test.dart::dropped (place gone) → SnackBar, never silent |
| OF-08 | Offline / lỗi mạng | Firebase chưa sẵn sàng / khách (guest) | Mở Home | Thẻ không hiện, không crash | unit: test/arrival_gap_test.dart::provider OF-08: guest / no couple → card hidden, nothing sent |
| OF-09 | Offline / lỗi mạng | Lỗi kết quả ghi khác | Ghi | Phân biệt acked / chưa ack / denied / lỗi khác; chỉ lưu trạng thái rìa khi sent/queued | unit: arrival_test.dart::write outcomes: acked / not acked / denied / other error; unit: arrival_test.dart::a failed / denied auto event leaves the in/out state alone |

## Thông báo / widget

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| TB-01 | Thông báo / widget | Người ấy bật `pushArrival`, thiết bị có token | Đến nơi (tự động hoặc bấm tay) | Push trả `type:arrival`, `wakeClients`, `collapseId arrival_<uid>`, KHÔNG inbox | unit: functions/test/index.test.js::arrival: Home enter → one wake push to the partner, slot stamped, no inbox; thủ công: iOS DEV chưa có APNs key; Android emulator không đăng ký được FCM → chỉ kiểm CF bằng unit |
| TB-02 | Thông báo / widget | Không inbox (D15) | Mở Trung tâm thông báo sau khi nhận | Không có item arrival nào | unit: functions/test/index.test.js::arrival: Home enter → one wake push to the partner, slot stamped, no inbox |
| TB-03 | Thông báo / widget | Chạm push `arrival` | Từ khay thông báo | Home tab 0 + cuộn tới thẻ (`focusArrival`) | unit: arrival_ui_test.dart::push tap "arrival" → Home tab, focus the card; thủ công: tap push thật chưa làm được trên máy ảo |
| TB-04 | Thông báo / widget | App bản cũ (1.11.0 trở xuống) nhận push arrival | Chạm | Rơi về Home mặc định, không inbox, không lỗi (D18) | thủ công: cần cài bản cũ cạnh bản mới |
| TB-05 | Thông báo / widget | Người nhận tắt "Khi người ấy đến nơi" | Người ấy đến nơi | Không banner; thẻ + widget vẫn cập nhật (silent wake); các loại push khác không bị tắt | unit: functions/test/index.test.js::arrival: pushArrival mutes only arrival pushes on that device; unit: arrival_ui_test.dart::"Khi người ấy đến nơi" reads + saves pushArrival |
| TB-06 | Thông báo / widget | Thiết bị cũ không có field `pushArrival` | Đến nơi | Mặc định bật | unit: arrival_test.dart::reads the stored value; legacy keys stay forced ON; unit: firestore.arrival.test.js::device doc: pushArrival bool passes, a string does not; old docs unaffected |
| TB-07 | Thông báo / widget | Push tên mặc định thiếu `displayName` | Đến nơi | Dùng tên fallback theo ngôn ngữ người nhận | unit: functions/test/index.test.js::arrival: no display name → fallback in the recipient's language |
| TB-08 | Thông báo / widget | Hai tin liên tiếp cùng người | Nhận | Tin mới thay tin cũ (collapse id), không chồng khay | unit: functions/test/index.test.js::collapseId: alert replaces the previous one (Android tag, iOS apns-collapse-id) |
| TB-09 | Thông báo / widget | Widget nhận push nền / app | Đến nơi hôm nay | Dòng `arrival_home`/`arrival_place`; sự kiện hôm qua và sự kiện RỜI không lên widget | unit: arrival_ui_test.dart::background push → arrival_home / arrival_place, today only; unit: arrival_ui_test.dart::app path: partner arrival of today wins; departures never |
| TB-10 | Thông báo / widget | Chạm widget có focus arrival | Mở app | Chấp nhận kind/focus `arrival` | unit: arrival_ui_test.dart::a widget tap with the arrival focus / kind is accepted |
| TB-11 | Thông báo / widget | Widget trên màn hình chính thật | Thêm widget, nhận sự kiện | Dòng trạng thái đổi | thủ công: SpringBoard thêm widget tự động không ổn định; kiểm App Group plist bằng `simctl get_app_container` |
| TB-12 | Thông báo / widget | Cài đặt → Thông báo | Mở hàng "Về đến nhà" và công tắc push | Phụ đề: "Đang tắt" / "Đang báo cho {tên}: Nhà và N nơi khác"; chỉ hiện khi `visible` | unit: arrival_ui_test.dart::"Về đến nhà" subtitle: off / sharing places |

## Ngôn ngữ

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| NN-01 | Ngôn ngữ | Máy tiếng Việt | Đi hết luồng | Mọi chữ khớp `app_vi.arb`; Nhà dịch theo l10n (không lưu) | maestro: maestro/arrival/02_manual_home_android.yaml; maestro: maestro/arrival/08_auto_setup_ios.yaml |
| NN-02 | Ngôn ngữ | Máy tiếng Anh | Đi hết luồng | Mọi chữ khớp `app_en.arb` ("I'm home"…), push theo `languageCode` thiết bị | unit: test/arrival_gap_test.dart::ARB + plist NN-02: every arrival* key exists in vi and en with the same placeholders |
| NN-03 | Ngôn ngữ | Push tới người nhận tiếng Anh/Việt | Đến nơi | Tiêu đề/nội dung theo ngôn ngữ người nhận; tên nơi tự đặt giữ nguyên văn | unit: functions/test/index.test.js::arrival: custom place uses its name verbatim + low battery line; unit: functions/test/index.test.js::arrival: no display name → fallback in the recipient's language |
| NN-04 | Ngôn ngữ | Đổi locale | Xem ngày trên thẻ và "Lưu từ địa chỉ · …" | vi 13/10, en 10/13 | unit: arrival_ui_test.dart::dates follow the locale (D3 i18n) |
| NN-05 | Ngôn ngữ | Chữ hệ thống bước 2 | Android 30+ | Dùng nhãn thật của máy; null → `arrivalAlwaysLabelAndroid` | unit: arrival_ui_test.dart::Android: disclosure → OS label step → back from the page → done |
| NN-06 | Ngôn ngữ | Câu xin quyền iOS | Mở hộp quyền | Chữ từ `{vi,en}.lproj/InfoPlist.strings`, nói rõ có gửi sự kiện RỜI (BUG-2) | unit: test/arrival_gap_test.dart::ARB + plist NN-06: iOS location prompts exist in vi + en and say they send "leave" |

## Riêng tư / bảo mật

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| RT-01 | Riêng tư / bảo mật | Máy chủ | Ghi doc chứa địa chỉ, toạ độ, danh sách nơi | Rules từ chối (chỉ `share/auto/last/updatedAt`) | unit: firestore.arrival.test.js::forbids addresses, coordinates or a place list — top level or in the event |
| RT-02 | Riêng tư / bảo mật | Người ngoài couple | Đọc/ghi `arrival` | Từ chối | unit: firestore.arrival.test.js::both members read; an outsider cannot; unit: firestore.arrival.test.js::forbids an outsider writing into the couple |
| RT-03 | Riêng tư / bảo mật | Người ấy | Ghi doc của mình / xoá doc | Từ chối (uid giả, update, xoá) | unit: firestore.arrival.test.js::forbids writing the partner's doc (fake uid); unit: firestore.arrival.test.js::the partner cannot touch it |
| RT-04 | Riêng tư / bảo mật | Sổ push `arrivalPush/{uid}` | Chủ, người ấy, người ngoài đọc/ghi | Mọi người đều bị từ chối; chỉ Admin SDK | unit: firestore.arrival.test.js::arrivalPush: nobody reads or writes it — not the partner, not the owner; unit: firestore.arrival.test.js::forbids a client writing the CF's push bookkeeping |
| RT-05 | Riêng tư / bảo mật | Tắt chia sẻ | Chủ xoá doc | Người ấy đọc không thấy gì; không `share:false`/dấu vết; `last` không còn khi share≠true | unit: firestore.arrival.test.js::sharing off = the owner deletes the doc; the partner then reads nothing; unit: firestore.arrival.test.js::forbids `last` while sharing is off (D11); unit: firestore.arrival.test.js::sharing off while keeping `last` is refused |
| RT-06 | Riêng tư / bảo mật | Không lịch sử | Gửi nhiều sự kiện | Server chỉ giữ 1 `last`, ghi đè; không subcollection | unit: arrival_test.dart::auto events go through the edge filter, manual ones never; unit: firestore.arrival.test.js::a new event passes |
| RT-07 | Riêng tư / bảo mật | Sự kiện tự động | Doc đã xoá / chưa chia sẻ | Không tạo doc, không chuyển share false→true (D10) | unit: firestore.arrival.test.js::an auto event cannot create the doc (partner changed, doc deleted); unit: firestore.arrival.test.js::an auto event cannot flip sharing from off / absent to on; unit: firestore.arrival.test.js::an auto event updates a doc that already shares |
| RT-08 | Riêng tư / bảo mật | Chia sẻ phải đủ 2 người | Bật khi couple chờ | Rules chặn | unit: firestore.arrival.test.js::sharing ON is refused while the couple waits for a partner |
| RT-09 | Riêng tư / bảo mật | Dữ liệu local | Xem Hive box | Toạ độ chỉ trong `arrival_nobackup`; prefs plugin loại khỏi Google backup; nhà cùng user | unit: arrival_native_test.dart::Android backups skip the plugin's region cache (lat/lng, D2); unit: arrival_test.dart::account deletion wipes only that user |
| RT-10 | Riêng tư / bảo mật | iOS backup | Kiểm cờ `isExcludedFromBackup` của thư mục box | Đã loại iCloud | thủ công: cần máy/simulator đọc resource value của thư mục, không có test Dart |
| RT-11 | Riêng tư / bảo mật | Analytics | Dùng mọi luồng | 8 event `arrival_*` không chứa tên, địa chỉ, chuỗi gõ, % pin | unit: test/arrival_gap_test.dart::analytics privacy RT-11: logArrival* take only enum / bool / count-like params, and call sites pass no PII |
| RT-12 | Riêng tư / bảo mật | Chuỗi địa chỉ đã gõ | Tìm | Chỉ tới Apple/Google; app không lưu và không gửi server riêng | thủ công: đọc code + Network inspector; không có test tự động |
| RT-13 | Riêng tư / bảo mật | Store/policy | Rà trước phát hành | Privacy policy `phase3` có mục vị trí; Data safety / App Privacy / form vị trí nền Play khớp thực tế | thủ công: việc khai báo web ngoài app |
| RT-14 | Riêng tư / bảo mật | Rules trường bắt buộc | Event sai `type`/`source`/`bounce`, pin ngoài 0..100, slot lạ, biểu tượng lạ | Từ chối | unit: firestore.arrival.test.js::forbids an unknown type / source and a non-bool bounce; unit: firestore.arrival.test.js::battery: int 0..100 or absent; unit: firestore.arrival.test.js::forbids a slot outside home/p1..p4; unit: firestore.arrival.test.js::forbids an unknown icon; unit: firestore.arrival.test.js::forbids a name or icon on Home |
| RT-15 | Riêng tư / bảo mật | Rules cờ | `share`/`auto` không phải bool | Từ chối | unit: firestore.arrival.test.js::forbids non-bool share / auto |

## Truy cập (a11y)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| AY-01 | Truy cập (a11y) | Thẻ có dữ liệu | Đọc header bằng trình đọc màn hình | Nhãn "Mở cài đặt Về đến nhà", vùng chạm ≥ 44 | maestro: maestro/arrival/02_manual_home_android.yaml |
| AY-02 | Truy cập (a11y) | Có tin người ấy | Đọc nút Hỏi thăm | "Hỏi thăm {tên}", tách khỏi chữ thường | maestro: maestro/arrival/03_view_home_ios.yaml |
| AY-03 | Truy cập (a11y) | Manage | Đọc/chạm hàng công tắc | Cả hàng bấm được và đọc 1 lần (tiêu đề, phụ đề, công tắc); nút phụ nằm ngoài vùng gộp | maestro: maestro/arrival/11_turn_off_ios.yaml; unit: test/arrival_gap_ui_test.dart::a11y AY-03: share row is one merged control (title + subtitle + switch) |
| AY-04 | Truy cập (a11y) | Dải lỗi / chờ mạng / ok | Xuất hiện | `liveRegion` được đọc | unit: arrival_ui_test.dart::permission-denied → error strip + "Thử lại" |
| AY-05 | Truy cập (a11y) | Bật Reduce Motion | Dải đổi trạng thái | Không có animation size (Duration.zero) | unit: arrival_ui_test.dart::Reduce Motion: no size animation on the strip |
| AY-06 | Truy cập (a11y) | Chữ ×1.3 | Mở thẻ | Làn và nút xếp dọc, không tràn | unit: arrival_ui_test.dart::text ×1.3: lanes and buttons stack |
| AY-07 | Truy cập (a11y) | Chữ ×2.0, khổ 360dp | Mở thẻ, màn thêm nơi, nút neo đáy khi có bàn phím | Không tràn ngang, nút neo đáy không bị bàn phím che | unit: test/arrival_gap_ui_test.dart::a11y AY-07: text ×2.0 on 360×640 → no overflow (card, name, manage) |
| AY-08 | Truy cập (a11y) | VoiceOver / TalkBack | Đọc làn Bạn/người ấy | Mỗi làn đọc 1 câu gộp (tên, tin, giờ, pin) | thủ công: trình đọc màn hình không chạy qua Maestro |
| AY-09 | Truy cập (a11y) | Tương phản | Pill pin vàng, chữ phụ 12px | ≥ 4.5:1 | thủ công: đo bằng mắt/Accessibility Inspector |

## Tổng số case theo cách kiểm

Phân loại theo cách kiểm ĐẦU TIÊN của mỗi case (case có nhiều cách kiểm được tính 1 lần).

| Cách kiểm | Số case |
|---|---|
| unit | 116 |
| maestro | 5 |
| chưa phủ | 0 |
| thủ công | 18 |
| **Tổng** | **139** |

Ghi chú: 18 case `unit` còn có thêm flow Maestro chạy cùng; tổng số case có flow Maestro (đứng đầu hoặc đi kèm) = 23.

### Theo nhóm

| Nhóm | unit | maestro | chưa phủ | thủ công |
|---|---|---|---|---|
| Bật/tắt | 8 | 1 | 0 | 0 |
| Quyền vị trí | 10 | 0 | 0 | 3 |
| Đặt địa điểm | 22 | 0 | 0 | 1 |
| Vào/ra vùng | 16 | 0 | 0 | 1 |
| Nền / kill / khởi động lại | 7 | 0 | 0 | 5 |
| Người ấy / couple | 13 | 0 | 0 | 1 |
| Offline / lỗi mạng | 9 | 0 | 0 | 0 |
| Thông báo / widget | 10 | 0 | 0 | 2 |
| Ngôn ngữ | 5 | 1 | 0 | 0 |
| Riêng tư / bảo mật | 12 | 0 | 0 | 3 |
| Truy cập (a11y) | 4 | 3 | 0 | 2 |
