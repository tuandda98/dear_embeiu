# Spike arrival (geofence + geocoder) — 2026-10-20

Worktree: `/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu-arrspike` (nhánh `spike/arrival-geofence`, không commit). Số liệu thô và script: `spike-data/` (cùng thư mục file này).

## Tóm tắt

| Câu | Kết quả |
|--|--|
| 6.1 build | `native_geofence 1.3.1` + `battery_plus 7.1.2`: `flutter build apk --debug` PASS (59,4 s), `flutter build ios --debug --no-codesign` PASS (185,8 s, kể cả `pod install`). 0 vòng sửa. Chưa có `setPluginRegistrantCallback` trong AppDelegate vẫn build qua, nhưng chạy sẽ `fatalError` (xem 6.4). License: native_geofence MIT (Chunky Tofu Studios LLC), battery_plus BSD-3 (Flutter Community, file LICENSE kiểu Chromium). Không có phần trả phí. |
| 6.4 engine nền | Android: `FlutterEngine(applicationContext)` mới, tự đăng ký `GeneratedPluginRegistrant`. iOS: headless engine, phải gọi `NativeGeofencePlugin.setPluginRegistrantCallback` ở AppDelegate. Chi tiết dưới. |
| 6.5 manifest | Plugin KHÔNG đưa permission nào (manifest plugin rỗng); permission/receiver phải tự khai. Thứ plugin kéo vào qua `work-runtime 2.10.2`: `FOREGROUND_SERVICE` + WorkManager services/receivers. `tools:node="remove"` chạy được (có aapt2). |
| 6.6 iOS UIBackgroundModes | KHÔNG cần `location`. |
| 6.8 geocoder | Đề bài đầy đủ (gõ cả phường/quận): 60% trong 250 m ở cả 2 API → DƯỚI ngưỡng 70%. Gõ rút gọn "số + đường, thành phố": MK 75%, CL 65%. Xem bảng. |
| 6.9 completer | Không thấy `loadingThrottled` (macOS CLI, 15 lần/4,5 s). Cần đo lại trên iPhone. |
| 6.2/6.3 | Chỉ đọc tài liệu: có relaunch khi bị hệ thống tắt; vuốt tắt chưa có tài liệu Apple chính thức. |

## 6.1 Lệnh

```
flutter pub add native_geofence battery_plus      # ^1.3.1, ^7.1.2
flutter build apk --debug                          # exit 0
flutter build ios --debug --no-codesign            # exit 0, Built build/ios/iphoneos/Runner.app
```
`FOREGROUND_SERVICE` + `SystemForegroundService` + 8 receiver WorkManager chưa hề có trong merged manifest bản chính (`dear_embeiu/build/app/outputs/logs/manifest-merger-debug-report.txt`: 0 lần `work-runtime`) ⇒ do `native_geofence/android/build.gradle:98` (`androidx.work:work-runtime-ktx:2.10.2`). Cũng kéo `play-services-location 21.3.0` và `play-services-maps 19.2.0` (build.gradle:95-96); maps không thêm permission nào vào merged manifest.

## 6.4 Engine nền

Android
- `NativeGeofenceBroadcastReceiver.kt:35-47` nhận sự kiện từ Play services, xếp `OneTimeWorkRequest<NativeGeofenceBackgroundWorker>` (expedited, `RUN_AS_NON_EXPEDITED_WORK_REQUEST`, hàng đợi tuần tự `ExistingWorkPolicy.APPEND`).
- `NativeGeofenceBackgroundWorker.kt:64` `flutterEngine = FlutterEngine(applicationContext)`, chạy dispatcher bằng `executeDartCallback` (dòng 101). Đây là engine RIÊNG của plugin, không phải engine của MainActivity.
- Constructor `FlutterEngine(Context)` tự đăng ký plugin: `javap -c` trên `flutter_embedding_debug` thấy `FlutterLoader.automaticallyRegisterPlugins()` rồi `GeneratedPluginRegister.registerGeneratedPlugins(engine)` (offset 614-621). ⇒ firebase_core/auth/firestore/battery_plus có trong isolate nền, KHÔNG cần code thêm. (Kênh tự viết ở `MainActivity` thì không có — đúng bài học widget-today D13; kênh native riêng phải là plugin hoặc đăng ký trong `FlutterPlugin`.)
- Dart: `lib/src/callback_dispatcher.dart:6-12` có `@pragma('vm:entry-point')`, `WidgetsFlutterBinding.ensureInitialized()`. Callback của app phải là hàm top-level `@pragma('vm:entry-point')`; trong đó vẫn phải gọi `Firebase.initializeApp()` (isolate mới).
- Chưa đo chạy thật (cấm cài app) ⇒ độ trễ, Firebase init trong worker: đo khi smoke.

iOS
- `LocationManagerDelegate.swift:29-71` dùng `didDetermineState` (không phải didEnter/didExit) rồi `createFlutterEngine()` (dòng 77-106): `FlutterEngine(name:..., allowHeadlessExecution: true)` → `run(withEntrypoint:libraryURI:)` (dòng 93) → gọi `flutterPluginRegistrantCallback?(headlessFlutterEngine!)` (dòng 98) → engine bị huỷ khi callback xong (`cleanup`, dòng 62-67).
- Cần ở `ios/Runner/AppDelegate.swift`, TRƯỚC `GeneratedPluginRegistrant.register(with: self)` (hiện dòng 19):
```swift
import native_geofence
NativeGeofencePlugin.setPluginRegistrantCallback { registry in
    GeneratedPluginRegistrant.register(with: registry)
}
```
  Thiếu thì `NativeGeofencePlugin.swift:31-33` `fatalError("Please ensure you have updated your ios/Runner/AppDelegate…")` ngay khi app khởi động. Registrant này đăng ký MỌI plugin (kể cả plugin UI) lên engine headless — giống cách firebase_messaging làm; nếu plugin nào crash ở headless thì phải lọc.
- Plugin dùng `startMonitoring(for:)` + `requestState(for:)` (`NativeGeofenceApiImpl.swift:30-32`): gọi `requestState` ngay khi tạo ⇒ nếu đang ở trong vùng sẽ bắn "enter" ngay (cần D6 bộ lọc trùng).

## 6.5 Merged manifest và `tools:node="remove"`

- `native_geofence/android/src/main/AndroidManifest.xml` rỗng ⇒ plugin KHÔNG thêm `ACCESS_*_LOCATION`, `RECEIVE_BOOT_COMPLETED`, receiver hay service. Phải tự khai (README mục Android 3-4). App đã có sẵn `RECEIVE_BOOT_COMPLETED`.
- Plugin kéo gián tiếp: `FOREGROUND_SERVICE` (từ work-runtime, manifest-merger-report dòng 1377), `SystemForegroundService` (không `foregroundServiceType`), `RescheduleReceiver`, `ConstraintProxy*`, `DiagnosticsReceiver`… Không có `FOREGROUND_SERVICE_LOCATION`, không `ACCESS_BACKGROUND_LOCATION`. `WAKE_LOCK` vốn đã có từ trước (Firebase…). `NativeGeofenceForegroundService` chỉ có nếu app tự khai ⇒ KHÔNG khai (khớp D1).
- Khối thêm vào `android/app/src/main/AndroidManifest.xml` của spike (trước `<application>`):
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```
  và trong `<application>`:
```xml
<receiver android:name="com.chunkytofustudios.native_geofence.receivers.NativeGeofenceBroadcastReceiver" android:exported="false"/>
<receiver android:name="com.chunkytofustudios.native_geofence.receivers.NativeGeofenceRebootBroadcastReceiver" android:exported="true">
    <intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/></intent-filter>
</receiver>
```
  (bản spike chép tay; README còn `android:permission` cho service — bỏ vì không khai service).
- Chứng minh remove: thêm `<uses-permission android:name="android.permission.FOREGROUND_SERVICE" tools:node="remove"/>`, `FOREGROUND_SERVICE_LOCATION`, `WAKE_LOCK` → build lại → `aapt2 dump permissions app-debug.apk` KHÔNG còn `FOREGROUND_SERVICE`/`WAKE_LOCK` (trước đó merged manifest có cả hai). Thêm `tools:node="remove"` cho `ACCESS_BACKGROUND_LOCATION` → build → aapt2 chỉ còn COARSE + FINE (kế hoạch B D13 chạy được).
- CẢNH BÁO: (1) `NativeGeofenceApiImpl.kt:178-187` từ chối tạo geofence nếu API ≥ 29 mà thiếu `ACCESS_BACKGROUND_LOCATION` (`MISSING_BACKGROUND_LOCATION_PERMISSION`) ⇒ kế hoạch B = Android mất hẳn chế độ tự động, đúng như D13. (2) KHÔNG nên remove `FOREGROUND_SERVICE`/`WAKE_LOCK`: WorkManager expedited trên Android < 12 chạy qua foreground service (`NativeGeofenceBackgroundWorker.kt:52-58`), và WAKE_LOCK do Firebase/WorkManager cần; bản dev chỉ remove để chứng minh cơ chế. Khuyến nghị: để `FOREGROUND_SERVICE` (quyền thường, không cần khai loại, không phải `_LOCATION`), chỉ `remove` `FOREGROUND_SERVICE_LOCATION` phòng khi lib khác kéo về.

## 6.6 iOS UIBackgroundModes

- Mã plugin: không chỗ nào đặt `allowsBackgroundLocationUpdates`; chỉ `startMonitoring(for:)` + `requestState` (`NativeGeofenceApiImpl.swift:25-32`). README iOS chỉ yêu cầu 2 khoá `NSLocationWhenInUseUsageDescription` + `NSLocationAlwaysAndWhenInUseUsageDescription`, không nhắc UIBackgroundModes.
- Apple (archive, Location and Maps Programming Guide, Region Monitoring): "regions associated with your app are tracked at all times, including when the app isn't running. If a region boundary is crossed while an app isn't running, that app is relaunched into the background" và app đang suspended được đánh thức "around 10 seconds". Khoá `location` trong UIBackgroundModes dành cho "standard location service" chạy liên tục (guide Core Location: "If your iOS app must keep monitoring location even while it's in the background, use the standard location service and specify the location value…").
- ⇒ KHÔNG thêm `location`. Cần: 2 khoá Info.plist trên (+ `InfoPlist.strings` vi/en theo quy ước repo), quyền "Luôn luôn". Giữ `remote-notification` hiện có. Lưu ý Apple: tắt Background App Refresh thì không có sự kiện region.
- Nguồn: https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html và .../CoreLocation/CoreLocation.html. Trang developer.apple.com mới render bằng JS nên WebFetch không đọc được; dùng bản archive.

## 6.2 / 6.3 (chỉ tài liệu)

- Bị hệ thống tắt: Apple nói trên — relaunch vào nền. Giới hạn 20 vùng/app; phải vượt ngưỡng (rời biên + ≥ 20 giây) mới báo, nên trễ là bình thường.
- Bị người dùng vuốt tắt: tài liệu Apple chính thức tôi đọc không nêu; kinh nghiệm cộng đồng là bị tạm dừng đến lần mở sau, iOS 26.4 có báo cáo khác (overview §2, forum 826964). Cần máy thật iOS 18 + 26.

## 6.8 Geocoder Apple, địa chỉ Việt Nam (macOS, 2026-10-20)

Script: `arrival-spike/geo.swift` (build `swiftc -O geo.swift -o geo`; chạy `./geo <thư mục> geo`). CL = `CLGeocoder().geocodeAddressString`, MK = `MKLocalSearch` `naturalLanguageQuery` (+ vùng Việt Nam, kết quả đầu tiên). Dữ liệu: `addrs.tsv`, `geo_out.tsv` (đầy đủ), `s2/addrs.tsv` + `geo2_out.tsv` (rút gọn), `table.md`.
Toạ độ đúng lấy từ Wikipedia (API `prop=coordinates`) của toà nhà/địa danh; là tâm công trình, độ chính xác ~50-150 m (nhiều bài chỉ 3-4 chữ số thập phân) ⇒ sai số ≤ 400 m ở các toà lớn (#6 ĐHQG, #7 Lotte) có phần do mốc đúng, không hẳn do geocoder. Tên mới (sau 1/7/2025) tôi tự gõ theo hiểu biết; mapping phường mới chưa đối chiếu nghị quyết. Không đo được hẻm có toạ độ công bố: 4 dòng P1-P4 chỉ xem định dạng, không chấm.
Android `Geocoder`: đo khi smoke trên emulator.

Cột "đầy đủ" = gõ như người dùng (số nhà, đường, phường, quận/tên cũ, thành phố). "Rút gọn" = chỉ số nhà + đường + thành phố.

| # | Nhóm/tên | Chuỗi gõ (đầy đủ) | Toạ độ đúng + nguồn | CL | MK | CL rút gọn | MK rút gọn |
|--|--|--|--|--|--|--|--|
| 1 | HN cũ | 78 Giải Phóng, Phương Mai, Đống Đa, Hà Nội | 21.001,105.8407 (en.wikipedia "Bạch Mai Hospital") | 71759 m | 71759 m | 293 m | 293 m |
| 2 | HN mới | 1 Đại Cồ Việt, Phường Bạch Mai, Hà Nội | 21.0064,105.8431 (en.wikipedia "Hanoi University of Science and Technology") | 128 m | 128 m | 128 m | 128 m |
| 3 | HN cũ | 1 Tràng Tiền, Phường Tràng Tiền, Quận Hoàn Kiếm, Hà Nội | 21.02416667,105.85777778 (en.wikipedia "Hanoi Opera House") | 199 m | 199 m | 199 m | 199 m |
| 4 | HN mới | 58 Quốc Tử Giám, Phường Văn Miếu - Quốc Tử Giám, Hà Nội | 21.02861111,105.83555556 (en.wikipedia "Temple of Literature, Hanoi") | 192 m | 192 m | 192 m | 192 m |
| 5 | HN cũ | 40 Tràng Thi, Phường Hàng Bông, Quận Hoàn Kiếm, Hà Nội | 21.0284,105.847 (en.wikipedia "Vietnam – Germany Hospital" (Việt Đức)) | 119 m | 119 m | 119 m | 119 m |
| 6 | HN mới | 144 Xuân Thủy, Phường Cầu Giấy, Hà Nội | 21.04027778,105.78166667 (en.wikipedia "Vietnam National University, Hanoi") | 395 m | 395 m | 395 m | 395 m |
| 7 | HN cũ | 54 Liễu Giai, Phường Cống Vị, Quận Ba Đình, Hà Nội | 21.03235,105.8126 (en.wikipedia "Lotte Center Hanoi") | 318 m | 318 m | 7482 m | 318 m |
| 8 | HN mới | 120 Lê Duẩn, Phường Cửa Nam, Hà Nội | 21.02441667,105.84108333 (en.wikipedia "Hanoi railway station") | 28 m | 28 m | 28 m | 28 m |
| 9 | HCM cũ | 135 Nam Kỳ Khởi Nghĩa, Phường Bến Thành, Quận 1, TP.HCM | 10.77694444,106.69527778 (en.wikipedia "Independence Palace") | 63977 m | 63977 m | 188 m | 188 m |
| 10 | HCM cũ | 1 Công xã Paris, Phường Bến Nghé, Quận 1, TP.HCM | 10.77972222,106.69916667 (en.wikipedia "Notre-Dame Cathedral Basilica of Saigon") | không có KQ | 2510 m | 63 m | 63 m |
| 11 | HCM mới | 2 Công xã Paris, Phường Sài Gòn, TP.HCM | 10.779884,106.699943 (vi.wikipedia "Bưu điện Sài Gòn") | 35 m | 35 m | 35 m | 35 m |
| 12 | HCM mới | Chợ Bến Thành, Lê Lợi, Phường Bến Thành, TP.HCM | 10.77252069,106.69801918 (en.wikipedia "Bến Thành Market") | không có KQ | 465 m | 9897 m | 5 m |
| 13 | HCM cũ | 201B Nguyễn Chí Thanh, Phường 12, Quận 5, TP.HCM | 10.757318,106.659096 (vi.wikipedia "Bệnh viện Chợ Rẫy") | 88 m | 88 m | 88 m | 88 m |
| 14 | HCM cũ | 268 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM | 10.77277778,106.65972222 (en.wikipedia "Ho Chi Minh City University of Technology") | 230 m | 230 m | 230 m | 230 m |
| 15 | HCM mới | 720A Điện Biên Phủ, Phường Thạnh Mỹ Tây, TP.HCM | 10.795,106.7219 (en.wikipedia "Landmark 81") | không có KQ | 948 m | 5855 m | 5855 m |
| 16 | HCM mới | 7 Công trường Lam Sơn, Phường Sài Gòn, TP.HCM | 10.7767,106.70321944 (en.wikipedia "Ho Chi Minh City Opera House") | 89 m | 89 m | 7882 m | 89 m |
| 17 | DN mới | 124 Hải Phòng, Phường Hải Châu, Đà Nẵng | 16.072717,108.215678 (en.wikipedia "Da Nang Hospital") | 72 m | 72 m | 72 m | 72 m |
| 18 | Huế cũ | 16 Lê Lợi, Phường Vĩnh Ninh, Thành phố Huế | 16.4625,107.58611111 (en.wikipedia "Huế Central Hospital") | 130 m | 130 m | 130 m | 130 m |
| 19 | CT mới | Khu II, đường 3/2, Phường Ninh Kiều, Cần Thơ | 10.0323,105.7682 (en.wikipedia "Can Tho University") | 1937 m | 1937 m | 19361 m | 1572 m |
| 20 | HP cũ | 75 Lương Khánh Thiện, Phường Cầu Đất, Quận Ngô Quyền, Hải Phòng | 20.856,106.6875 (en.wikipedia "Haiphong station") | 79 m | 79 m | 79 m | 79 m |

(Ô "NNN m" là khoảng cách haversine tới toạ độ đúng. 'không có KQ' = `kCLErrorDomain 8` hoặc rỗng.)

### % trong 250 m (n = 20)

| API | Đầy đủ | cũ (n=10) | mới (n=10) | Rút gọn | cũ | mới | Đầy đủ ≤400 m |
|--|--|--|--|--|--|--|--|
| CLGeocoder | 12/20 = 60% | 6 | 6 | 13/20 = 65% | 8 | 5 | 14/20 = 70% |
| MKLocalSearch | 12/20 = 60% | 6 | 6 | 15/20 = 75% | 8 | 7 | 14/20 = 70% |

Quan sát:
- Hai API trả cùng điểm ở phần lớn trường hợp (cùng backend); MK hơn CL khi tìm tên địa danh không số nhà (#12 Chợ Bến Thành: MK 5 m, CL cầu Bến Phân cách 9,9 km).
- Lỗi nặng, tin tưởng sai: gõ phường/quận CŨ làm lệch tỉnh: #1 "Phương Mai, Đống Đa" → Ninh Bình (71,8 km); #9 "Phường Bến Thành, Quận 1" → Vũng Tàu (64 km); #10 → không kết quả (CL) / Ngã Sáu Cộng Hòa lệch 2,5 km (MK). #15 ("Thạnh Mỹ Tây") → số nhà 527 thay vì 720A (948 m). Bỏ phường/quận, chỉ giữ số + đường + thành phố thì #1, #9, #10 hết lỗi lớn (293 m, 188 m, 63 m).
- Địa danh không có số nhà (#19 "Khu II, đường 3/2…") chỉ ra tới mức phường (1,9 km) ⇒ D21 cảnh báo "chưa có số nhà" phải bật.
- Tên phường MỚI (Bạch Mai, Sài Gòn, Văn Miếu - Quốc Tử Giám, Thuận Hóa…) có trong dữ liệu Apple ⇒ kết quả trả về dùng tên mới; gõ tên mới không tệ hơn gõ tên cũ khi có số nhà.
- Hẻm (P1-P4): `45/12 Lê Văn Sỹ` không ra số nhà: CL báo không kết quả, MK trả cả con đường hoặc "222 Lê Văn Sỹ"; `25/8 Tạ Quang Bửu` → CL trả "Hẻm 40/2/5 Tạ Quang Bửu" (hẻm khác); `102/15 Nguyễn Chí Thanh` → CL "Hẻm 102/44/49 Pháo Đài Láng". Số kiểu x/y không đáng tin, cần cảnh báo và bán kính 250 m.

### Kết luận ngưỡng D20

Theo đúng ngưỡng (250 m, gõ đầy đủ): KHÔNG đạt ở cả 2 (60%). Đạt 75% với MK nếu app tự rút gọn chuỗi gửi đi (bỏ phường/quận/xã, chỉ giữ số + đường + tỉnh/thành); CL 65%. Phần hụt còn lại là toà nhà lớn, nơi mốc đúng cũng lệch. Báo PO: (a) giữ D20 nhưng iOS dùng MK (không phải CL), bỏ phần phường/quận khỏi truy vấn, luôn chạy D21 (xác nhận bằng chữ, chặn kết quả khác tỉnh với chuỗi người gõ); (b) hoặc Goong. Android chưa có số.

## 6.9 MKLocalSearchCompleter

Script `arrival-spike/comp3.swift`: 15 lần đổi `queryFragment` cách 300 ms ("45" → "45 Lê Văn Sỹ, Phường 13"), nhận 14 callback, 0 lỗi (không `loadingThrottled`), kết quả mỗi lần 13-15 (0 ở "…Phường 1", 6 ở "…Phường 13" và 6 kết quả đó vô nghĩa — tên phường CŨ làm gợi ý hỏng, trong khi "45 Lê Văn Sỹ" trả "P. Phú Nhuận" tên mới). Có/không đặt `region` Việt Nam cho kết quả gần như giống nhau. Hạn chế: chạy trong tiến trình macOS CLI, chưa phải iPhone/app; throttle thật nên đo lại trên máy. Lưu ý: set `queryFragment` từ `Task` nền (không phải main queue) khiến delegate KHÔNG nhận gì (script `geo.swift` mode `comp`) — phải gọi trên main thread.

## Đề xuất

1. Giữ `native_geofence` 1.3.1: build 2 nền tảng qua, MIT, tự đăng ký plugin ở engine nền Android, iOS cần 1 callback AppDelegate, không kéo permission nhạy cảm ngoài `FOREGROUND_SERVICE` (thường). Dự phòng cũ vẫn là `flutter_background_geofencing`. Cần smoke máy thật cho độ trễ.
2. AndroidManifest: 3 permission vị trí + 2 receiver (khối trên); KHÔNG khai `NativeGeofenceForegroundService`; `tools:node="remove"` cho `FOREGROUND_SERVICE_LOCATION`; kế hoạch B: `tools:node="remove"` cho `ACCESS_BACKGROUND_LOCATION` (đã chứng minh qua aapt2, nhưng plugin sẽ từ chối tạo geofence trên API ≥ 29 nên phải ẩn chế độ tự động bằng cờ). Đừng remove `FOREGROUND_SERVICE`/`WAKE_LOCK`.
3. iOS Info.plist: thêm `NSLocationWhenInUseUsageDescription` + `NSLocationAlwaysAndWhenInUseUsageDescription` (+ InfoPlist.strings vi/en); KHÔNG thêm `UIBackgroundModes: location`. AppDelegate: `NativeGeofencePlugin.setPluginRegistrantCallback` trước `GeneratedPluginRegistrant.register`.
4. Geocoder: xem kết luận D20 ở trên (chưa đạt 70% nếu gõ nguyên chuỗi; đạt 75% với MK + rút gọn). Android chưa đo.
