# 💻 Dev — Về đến nhà chưa? (arrival)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Chia 3 stage, mỗi stage một agent nối tiếp trên nhánh `feature/arrival` (worktree `dear_embeiu-arrival`).

- **Trạng thái dev:** stage 1 (backend + dữ liệu) + vá review backend + stage 2 (native) + stage 3 (UI) xong; Lead gộp `feature/arrival-ui` vào `feature/arrival` 2026-10-20. Chờ review UI/native, deploy DEV, smoke 2 máy.
- **Người/role:** Dev
- **Deploy:** chưa. Lead deploy DEV từ nhánh gộp. PROD: `firestore:rules` (có `arrivalPush`) + `functions:notifyArrival,functions:notifyPartnerLeft,functions:deleteAccount,functions:leaveCoupleCleanup`, rules phải lên PROD trước khi bản có arrival live.

## Stage 1 — đã làm

### Firestore rules (`firestore.rules`)
- `isValidDeviceDocument`: thêm `pushArrival` (bool, không bắt buộc, `.get('pushArrival', true)`).
- Khối mới trong `match /couples/{coupleId}`: hàm `isValidArrivalEvent(e)`, `isValidArrivalDoc(d)`, `match /arrival/{uid}`:
  - đọc: thành viên couple; ghi: chỉ chủ (`uid == request.auth.uid`), khoá client chỉ `share`/`auto`/`last`/`updatedAt`. ⟪Sửa sau review: sổ push của CF sang `arrivalPush/{uid}`, xem mục "Vá review backend".⟫
  - `share` khác `true` thì không được còn `last` (tắt = xoá cùng lần ghi, D11).
  - Bật `share` chỉ khi couple đủ 2 người (create luôn kiểm; update kiểm khi trước đó chưa bật).
  - Update chỉ kiểm lại `last` khi `last` nằm trong `affectedKeys` → đổi `auto` lúc sự kiện cũ hơn 12 giờ vẫn qua.
  - Tên nơi: `size()` 1..24 (đơn vị UTF-16, giống decision-wheel DW-R2-1), `trim().size() >= 1`, không `\r`/`\n` (RE2 `(?s).*[\\r\\n].*`).
  - ⟪Sửa sau review⟫ chủ xoá được doc của mình (tắt chia sẻ = xoá doc); người ấy, người ngoài thì không.

### Cloud Functions (`functions/index.js`)
- `PUSH_TYPE_PREF_FIELD.arrival = "pushArrival"`.
- Khối `// ── arrival (đợt 2) ──` trước phần Love Note: hằng `ARRIVAL_*`, `ARRIVAL_COPY` (vi/en đúng §7), hàm thuần `arrivalVnDateKey`, `arrivalEvent`, `arrivalPushPlan`, `arrivalClaim`, `buildArrivalText`, lõi `processArrivalWrite`, trigger `exports.notifyArrival` (onDocumentWritten `couples/{coupleId}/arrival/{uid}`).
  - Bỏ qua: doc xoá · `share != true` · `last` không đổi (place+type+at) · `exit` · `bounce` · sự kiện cũ hơn 30' · couple không `active` hoặc người gửi không còn trong `memberIds` · cùng nơi đã push trong 30' · đủ 6 push/ngày (ngày theo UTC+7) · ⟪sau review⟫ trong transaction doc đã tắt/xoá hoặc `last` đã là sự kiện khác (`superseded`). Cooldown + trần nhận trong transaction, ghi `lastPushAt.{slot}` + `pushDay` + `pushCount` vào `arrivalPush/{uid}`.
  - `sendToRecipientDevices(…, {type:'arrival', coupleId, place, placeName?, icon?, battery? (chuỗi), actorName, date}, {wakeClients:true, collapseId:'arrival_<uid>'})`. Không inbox.
- `notifyPartnerLeft` → hàm `arrivalCleanupOnLeave(coupleId, [người rời, ...người ở lại])`: xoá `arrival/{uid}` + `arrivalPush/{uid}` của cả hai (người ở lại trông như chưa từng bật).
- `handleCoupleOnAccountDeletion`: xoá `arrival/{uid}` + `arrivalPush/{uid}` ngay sau `sleep/{uid}`. `deleteCoupleCompletely`: `recursiveDelete(arrival)` + `recursiveDelete(arrivalPush)`.

### Dart
| File | Nội dung |
|---|---|
| `lib/models/arrival.dart` (mới) | `kArrivalSlots`, `kArrivalMaxCustom` 4, `kArrivalNameMax` 24, bán kính `kArrivalRadiusAddress` 250 / `kArrivalRadiusCurrent` 150, `ArrivalIcon` (7 khoá), `normalizeArrivalName`, `ArrivalLocation` (chỉ trên máy), `ArrivalPlace` (`.home()`), `ArrivalEvent` (`ArrivalEvent.at(place,…)` chụp tên + biểu tượng, D23; `toMap`/`fromMap`), `ArrivalShare` |
| `lib/utils/arrival_edge_filter.dart` (mới) | `ArrivalEdgeState`, `filterArrivalEdge` (D6 phía máy: trùng trạng thái → bỏ; vào lại < 10' sau khi rời → `bounce`) |
| `lib/services/arrival_platform.dart` (mới) | `kArrivalAutoEnabled`, `kArrivalAutoAndroid` (D13), `arrivalAutoBuildAllowed`; interface `ArrivalGeofence`, `PlaceSearch` (+ `PlaceSearchResult`, `PlaceSearchOffline`, `PlaceSearchUnavailable`), `BatteryReader`; bản `Noop…` |
| `lib/services/arrival_service.dart` (mới) | Hive box `arrival_nobackup` trong thư mục riêng (iOS cờ loại backup qua `SleepPlatform.excludeFromBackup`, Android `res/xml`); `loadPlaces`/`savePlaces` (Nhà luôn đứng đầu), `loadEdge`/`saveEdge`/`clearEdge`, `loadWantsAuto`/`saveWantsAuto`, `saveSession`/`loadSession`/`clearSession` (cho callback nền stage 2), `wipeLocalData`, `readRemoteAutoEnabled` (`config/app.arrivalAutoEnabled`, thiếu/lỗi = bật hoặc giá trị đọc lần trước), `watchShare`, `putEvent` (`mergeFields` để thay nguyên `last`), `turnOn`/`turnOff`/`setAuto`, `reportEvent` (đường chung bấm tay + geofence), `send` (sent/queued/denied/failed; `ackTimeout` 5 s) |
| `lib/providers/arrival_provider.dart` (mới) | `visible` (ẩn khi partner '' — D9), danh sách nơi, `savePlace`/`deletePlace` (Nhà chỉ mất vị trí; trả nơi đã xoá để hoàn tác 5 s), `setShare(on, deletePlaces:)` (tắt → `wantsAuto=false`, dừng geofence), `setWantsAuto`, `sendManual(slot)` + `retry`, `onResume` (đọc quyền Luôn luôn + cờ từ xa → `sync`/`stopAll` geofence + đồng bộ cờ `auto` lên doc), `autoRunning`/`needsAlways`/`autoRemoteOff`, `partnerLast` (chỉ khi người ấy chia sẻ) |
| `lib/main.dart` | `ChangeNotifierProvider(create: (_) => ArrivalProvider())` |
| `lib/app/session_resolver.dart` | named-param `arrivalProvider` (signature + call site), `watchForCouple(coupleId, uid, rpsPartnerUid)`, `clear(signedOut: true)` ở 2 nhánh chưa auth/chưa xác thực, `clear()` khi không có couple |
| `lib/services/auth_service.dart` | `wipeLocalUserData` xoá thêm `ArrivalService.wipeLocalData` |
| `lib/services/notification_settings_service.dart` | `keyArrival = 'pushArrival'` (KHÔNG nằm trong `allKeys`); `currentOrDefault()` giữ 3 khoá cũ ép `true`, thêm `pushArrival` = giá trị Hive thật (mặc định bật); box chưa mở thì bỏ khoá ra để lệnh ghi merge giữ giá trị trên doc thiết bị; `arrivalPushEnabled()` |
| `android/app/src/main/res/xml/backup_rules.xml`, `data_extraction_rules.xml` | loại `app_flutter/arrival_nobackup/` |

### Lệch spec + lý do
- Tên nơi đếm theo **UTF-16** (`String.length`), không theo rune như §5 ghi: rules `size()` đếm UTF-16 (đo ở decision-wheel DW-R2-1). Client và rules khớp nhau.
- Data push dùng **`actorName`** (không phải `name` như §7): `HomeWidgetStatus.fromPush` đọc `actorName` cho mọi loại. Tên nơi ở `placeName`, slot ở `place`.
- Thêm `collapseId: arrival_<uid>`: tin đến nơi mới thay tin cũ của cùng người trên khay thông báo.
- Tắt chia sẻ cũng đặt `wantsAuto=false` (bật lại không tự dùng vị trí nền khi người dùng chưa đồng ý lại).
- Sổ push (`arrivalPush/{uid}`) sống qua lần tắt chia sẻ để trần 6/ngày không bị lách bằng tắt/bật; chỉ mất khi rời couple / xoá tài khoản.

### Edge case / nợ cho Tester
- Thiết bị tắt `pushArrival`: không hiện banner nhưng VẪN nhận silent wake (`notifyArrival` gửi `wakeClients`, `sendToRecipientDevices` chỉ bỏ thiết bị đã mute khi không có `wakeClients` — `functions/index.js:3516`) ⇒ widget máy đó đổi ngay. ⟪Ghi chú cũ "không có wake nền, widget chỉ đổi khi mở app" sai, sửa 2026-10-22 theo Tester.⟫
- Ngày của `data.date` và trần 6/ngày theo UTC+7 cho mọi người.
- Sự kiện nằm trong hàng đợi offline > 12 giờ bị rules từ chối khi đồng bộ (SDK bỏ lặng lẽ).
- `reportEvent` bấm tay không đụng trạng thái rìa vùng: bấm "Về nhà rồi" rồi geofence bắn "đến Nhà" ngay sau → ghi 2 lần, CF chặn push lần 2 bằng cooldown 30'.

## Kế hoạch stage 2 — native (agent sau)
1. Đọc kết quả spike plugin geofence + geocoder (agent khác, worktree riêng) ghi ở §Spike dưới đây trước khi code. Giả định nào sai → báo Lead.
2. Thêm package (`native_geofence` hoặc dự phòng, `battery_plus` hoặc kênh native nhỏ, `geocoding` hoặc kênh native `MKLocalSearchCompleter`/`Geocoder`), `pubspec.yaml` theo luật "chỉ thêm".
3. Cài `ArrivalGeofence` thật: `hasAlwaysPermission` (Luôn luôn + chính xác), `sync(places)` đăng ký đúng các vùng (id = slot, bán kính `location.radius`, Android `loiteringDelay` 2' nếu có), `stopAll`. Callback nền top-level: `DartPluginRegistrant.ensureInitialized()` → `Firebase.initializeApp()` → `ArrivalService().loadSession()` → `BatteryReader.level()` → `ArrivalService().reportEvent(source: auto, auto: true, at: thời điểm hệ thống báo)`; kết quả `denied` → `stopAll()`.
4. Cài `BatteryReader` (phải chạy được trong engine nền — bài học widget-today D13) và `PlaceSearch` (iOS gợi ý khi gõ, khung VN; Android `Geocoder` API 33+ listener, ≤5 kết quả; `isPresent()==false` → `isAvailable` false; mất mạng → `PlaceSearchOffline`). Đọc vị trí hiện tại 1 lần cho "Dùng vị trí hiện tại" (`ArrivalLocationSource.current`, 150 m).
5. Truyền bản thật vào `ArrivalProvider(geofence:, battery:)` ở `main.dart`.
6. Native config: `AndroidManifest.xml` (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`; chặn `FOREGROUND_SERVICE_LOCATION` bằng `tools:node="remove"` nếu plugin kéo vào; kiểm `aapt2 dump permissions`), `Info.plist` + `{vi,en}.lproj/InfoPlist.strings` (2 câu D12). Không thêm `UIBackgroundModes location` trừ khi spike chứng minh cần. `PrivacyInfo.xcprivacy` nếu plugin đòi.
7. Test: fake ở `test/arrival_test.dart` (`FakeGeofence`, `FakeBattery`, `FakeArrivalService`) dùng tiếp được.

## Kế hoạch stage 3 — UI (agent sau)
1. ARB (`arrival*` theo copy deck design §8, một khối liền trước `}` cuối), `flutter gen-l10n`. Tên Nhà = l10n, không lưu.
2. `ArrivalCard` ở chỗ đánh dấu `// ── Đợt 2 (Home C): ArrivalCard …` trong `home_screen.dart`, chỉ khi `ArrivalProvider.visible`; HomeScreen re-arm `watchForCouple` với couple sống (partner vào giữa phiên) + gọi `onResume` khi app resume. Thời gian: hôm nay `HH:mm`, hôm qua, 2–3 ngày `d/M HH:mm`, > 3 ngày → "Đang bật" (`MidnightBuilder`). Nút "Về nhà rồi" → `sendManual()`; "Đến nơi rồi" → sheet chọn nơi → `sendManual(slot)`; `lastResult` queued/failed → dòng "Sẽ báo khi có mạng" / "Thử lại" (`retry`). "Hỏi thăm" → `openCareMessageScreen` thêm tham số gợi ý.
3. Màn thiết lập / quản lý / thêm-sửa nơi / 2 màn giải thích quyền theo `docs/design/arrival/*.html`; xoá nơi có hoàn tác 5 s (`deletePlace` trả nơi cũ → `savePlace`).
4. Cài đặt → Thông báo: công tắc "Khi người ấy đến nơi": `NotificationSettingsService.instance.set(keyArrival, v)` rồi `PushNotificationService.instance.refreshDeviceRegistration()`; đọc bằng `arrivalPushEnabled()`. Cài đặt → mục "Về đến nhà".
5. Widget-today: `statusKind` `arrival_home` / `arrival_place` trong `home_widget_status.dart` (push `type == 'arrival'`, đọc `place`, `placeName`, `actorName`, `date`; bỏ qua khi không phải hôm nay); `statusFocus = 'arrival'`. Push tap: nhánh `arrival` trong `_handleNotificationTap` → Home tab 0 + `pendingHomeFocus = 'arrival'`.
6. Analytics §9, feature tour, nháp privacy policy (nhánh `phase3`) + Data safety + App Privacy + form Play + kịch bản video trong file này.

## Vá review backend (Lead, sau stage 1) — commit `4dd0aa5`
1. **HIGH — sổ push lộ lịch sử nơi đến (D3/D11):** `lastPushAt/pushDay/pushCount` chuyển sang `couples/{c}/arrivalPush/{uid}`; rules `allow read, write: if false` (Admin SDK bỏ qua rules). Doc `arrival` chỉ còn `share/auto/last/updatedAt`. Rules-test mới: người ấy, chủ, người ngoài đều không đọc/ghi/xoá được sổ.
2. **MEDIUM — tắt chia sẻ để lại dấu:** `ArrivalService.turnOff` = `delete()` doc ⇒ người ấy thấy y như người chưa bật (không `share:false`, không `updatedAt`, không `pushCount`). Rules thêm `allow delete` cho chủ (thành viên). CF bỏ nhánh "xoá `lastPushAt` khi tắt".
3. **MEDIUM — push vẫn đi sau khi vừa tắt:** transaction đọc lại doc `arrival`; `share != true`, doc đã xoá, hoặc `last` khác (place/atMs) → `superseded`, không push, không ghi sổ. Test node 4 ca.
4. **LOW (mục 5) — trạng thái trong/ngoài lưu trước khi ghi:** `reportEvent` chỉ `saveEdge` khi kết quả `sent`/`queued`. Test Dart (failed/denied giữ nguyên, sent/queued cập nhật).
5. **LOW (mục 7) — `notifyPartnerLeft` không reset sổ:** hết, vì xoá cả `arrivalPush` của người rời lẫn người ở lại.
6. **Quyết định Lead (mục 6): đăng xuất GIỮ nơi đã lưu.** Đã kiểm: Hive khoá theo uid (`places:<uid>`, `edge:<uid>`, `settings:<uid>`); chỉ `session` dùng chung và bị xoá khi `clear()`; geofence dừng khi `clear()`. Người khác đăng nhập máy này không thấy nơi của người trước. Xoá tài khoản thì `wipeLocalData(uid)` xoá hết.
- Test thêm: `arrivalCleanupOnLeave` chạy thật trên fake (người ở lại không có doc, chạy 2 lần, 1 lệnh xoá lỗi thì phần còn lại vẫn chạy); `handleCoupleOnAccountDeletion` 3 ca giờ kiểm cả `arrivalPush`. Rules-test **424** pass, functions `npm test` **35** pass.
- Dữ liệu cũ trên DEV (nếu Lead đã deploy stage 1): doc `arrival` có thể còn `lastPushAt/pushDay/pushCount` — rules update không đụng tới nên vẫn ghi được; muốn sạch thì xoá tay các doc `couples/*/arrival/*` trên DEV.

## Vá review native (Lead, sau `18206c7`) — nhánh `feature/arrival-native-fix`
1. **HIGH — geofence nền tự bật lại chia sẻ với người ấy mới (D10).** Sự kiện tự động giờ chỉ `update()` doc (`auto`, `last`, `updatedAt`), không đụng `share`; bấm tay vẫn `set` `share:true`. Rules: `last.source == 'auto'` không được tạo doc, update chỉ qua khi doc đang `share == true` (không chuyển false/không có → true). `not-found` xếp chung `denied`; callback nền gặp `denied` → `stopAll` + `saveWantsAuto(false)`. Rules-test +3 (tạo bằng auto bị chặn, update auto trên doc đang chia sẻ qua, auto không bật được chia sẻ — bấm tay thì được); test Dart: doc đã xoá → dừng + quên "Tự báo" + không lưu trạng thái trong/ngoài. Test rules cũ đổi mặc định `source: 'manual'` (tạo doc = bấm tay).
   - **Còn hở (cần Lead/PO chốt):** đường mở app. A mở app với người ấy mới C: doc đã xoá nên tự báo không chạy, nhưng `wantsAuto` trên máy vẫn true ⇒ A bấm "Về nhà rồi" (đồng ý chia sẻ với C) thì `auto` bật luôn theo. Muốn chặn: reset `wantsAuto` khi doc của mình biến mất / partner đổi trong `ArrivalProvider` — chưa làm vì đụng provider mà nhánh UI đang sửa.
2. **HIGH — toạ độ Android lọt Google backup (D2).** Plugin lưu vùng (lat/lng) trong prefs `native_geofence_plugin_cache.xml` ⇒ thêm `<exclude domain="sharedpref" path="native_geofence_plugin_cache.xml" />` vào full-backup (`backup_rules.xml`) + cloud-backup + device-transfer (`data_extraction_rules.xml`). Test đọc XML. Prefs `dear_embeiu_arrival.xml` của kênh mình chỉ có cờ "đã hỏi quyền", không có toạ độ ⇒ giữ.
3. **HIGH — Android không đăng ký lại vùng.** `sync()` trên Android gọi thêm `reCreateAfterReboot()` (thêm lại mọi vùng trong prefs, cùng id thì đè, không initial trigger nên không bắn gì). `sync` chạy mỗi lần `onResume` khi đang tự báo ⇒ Force stop / xoá dữ liệu Play services / tắt-bật vị trí được vá ở lần mở app kế. Giữa lúc đó vẫn mất vùng (giới hạn Android).
4. **MEDIUM — cầu nối isolate.** Hết 2 s không còn xoá tên cổng. Tin mang thêm giờ gửi; isolate chính bỏ tin cũ hơn 1,5 s (bên gửi đã tự xử lý). `hasAlwaysPermission` (gọi mỗi `onResume`) đăng ký lại tên nếu tên đang trỏ cổng khác. Test: không có app, app sống nhận đúng 1 lần, tin muộn bị bỏ, tên chết → tự xử lý + giữ tên + resume giành lại. Cửa sổ còn lại: isolate chính nhận ở ~1,4 s mà "accepted" về muộn hơn 2 s ⇒ cả hai cùng xử lý (`ponytail`: chấp nhận, edge filter + cooldown CF 30' chặn push đôi).
5. **MEDIUM — công tắc từ xa D13 trong callback nền.** `handleArrivalGeofenceEvent` đọc `readRemoteAutoEnabled()` (mạng 4 s, lỗi thì giá trị cache); `false` → `stopAll`, không gửi. Không thêm kiểm ở CF: mỗi sự kiện tốn thêm 1 lần đọc `config/app`, và client đã dừng ngay ở sự kiện đầu tiên sau khi tắt. Test Dart.
6. **LOW — App Check ở isolate nền.** Callback nền gọi `FirebaseBootstrapService.initialize()` (Firebase + App Check như app chính) thay `Firebase.initializeApp()` trơn. Ghi chú cho đợt bật Enforce: nếu token App Check chưa kịp có, ghi bị `permission-denied` ⇒ callback hiểu là "đã rời couple" ⇒ dừng + tắt "Tự báo". Kiểm lại nhánh này trước khi Enforce Firestore.
7. **LOW — iOS `requestAlways` từ `notDetermined`.** Native chỉ xin "Luôn luôn" khi đang `authorizedWhenInUse`; trạng thái khác trả về trạng thái hiện tại (giữ thứ tự D8).
8. **LOW — tìm địa chỉ không timeout phía Dart.** `NativePlaceSearch.search` timeout 12 s → `PlaceSearchUnavailable` (GeocodeListener Android 33+ có thể không gọi lại).
9. **LOW — CF `superseded` (chấp nhận):** về Nhà rồi 1 sự kiện khác ghi đè `last` trước khi transaction chạy (vd rời Nhà ngay) ⇒ push về Nhà bị bỏ. Hiếm (2 sự kiện trong ~1 s), thẻ vẫn đúng sự kiện mới nhất.
- Test thêm: CF `deleteAccount` của thành viên couple xoá `arrival/{uid}` + `arrivalPush/{uid}`, không đụng của người kia.
- Kết quả: `flutter analyze` 0 · `flutter test` 716 pass (~3 skip) · rules-test 427 pass · functions 36 pass · `flutter build apk --debug` PASS · `flutter build ios --debug --no-codesign` PASS.

## Spike (tóm tắt — chi tiết ở [`spike.md`](spike.md))
- `native_geofence 1.3.1` (MIT) + `battery_plus 7.1.2` (BSD-3) build qua 2 nền tảng. Android: plugin tự dựng `FlutterEngine` riêng cho callback nền (tự đăng ký mọi plugin); iOS: engine headless, cần `NativeGeofencePlugin.setPluginRegistrantCallback` trong AppDelegate trước `GeneratedPluginRegistrant`.
- Không cần `UIBackgroundModes location`. Plugin không thêm permission nào; kéo `FOREGROUND_SERVICE` qua WorkManager (giữ). Kế hoạch B bỏ `ACCESS_BACKGROUND_LOCATION` làm plugin từ chối tạo geofence trên API ≥ 29.
- Geocoder Apple: gõ đầy đủ 60% trong 250 m; rút gọn "số + đường, tỉnh" MKLocalSearch 75% ⇒ D20 chốt lại (MK, rút gọn, lọc tỉnh, cảnh báo hẻm). Android `Geocoder` chưa đo.

## Stage 2 — đã làm (native)

### Quyết định plugin
- **Geofence:** `native_geofence ^1.3.1`. **Pin:** `battery_plus ^7.1.2`.
- **Quyền vị trí + đọc vị trí 1 lần + tìm địa chỉ:** KHÔNG thêm plugin; viết kênh `dear_embeiu/arrival` (Swift `ArrivalChannel` cuối `AppDelegate.swift`, Kotlin `android/.../arrival/ArrivalChannel.kt`). Lý do: (1) kênh tìm địa chỉ native đằng nào cũng phải viết (completer iOS); (2) `geolocator` khai sẵn `GeolocatorLocationService` có `foregroundServiceType="location"` trong manifest của nó — trái D1, phải `tools:node="remove"` thêm; (3) `geolocator`/`permission_handler` iOS xin thẳng "Luôn luôn" nếu Info.plist có khoá Always — trái D8 (khi dùng app trước); (4) 0 phụ thuộc mới ngoài 2 plugin spike đã duyệt license. Kênh chỉ ở engine chính; callback nền không gọi tới.

### File
| File | Nội dung |
|---|---|
| `lib/services/arrival_platform_native.dart` (mới) | `NativeArrivalGeofence` (id = slot, bán kính theo nơi, iOS `enter/exit`, Android `dwell/exit` + `loiteringDelay` 2' (D6), KHÔNG initial trigger cả 2 nền tảng ⇒ đăng ký lúc đang ở Nhà không báo nhầm; `sync` so với `getRegisteredGeofences`, chỉ xoá/tạo vùng đổi), `NativePlaceSearch`, `NativeArrivalPermissions`, `NativeCurrentLocationReader`, `PluginBatteryReader` (−1 của simulator → null), callback nền `arrivalGeofenceTriggered` (`@pragma('vm:entry-point')`), `handleArrivalGeofenceEvent`, `ArrivalBackgroundBridge`, `arrivalBackgroundOptionLabel()` (ngoài hợp đồng, xem dưới) |
| `lib/utils/arrival_place_query.dart` (mới) | Hàm thuần: `foldVi`, `kArrivalProvinces` (34 tỉnh mới + tên cũ đã sáp nhập + viết tắt), `arrivalProvinceOf`, `shortenArrivalPlaceQuery` (bỏ phần phường/quận/xã/huyện/thị xã/thị trấn/P./Q./"Việt Nam"; có tỉnh ở cuối thì chỉ giữ phần có số nhà + tỉnh; không có tỉnh thì chỉ bỏ phần có tiền tố hành chính; số kiểu hẻm `x/y[/z]` → gửi `x` + `alley`), `arrivalResultInProvince` |
| `lib/main.dart` | chỉ dòng tạo `ArrivalProvider(...)` với 5 bản thật + import |
| `ios/Runner/AppDelegate.swift` | import `CoreLocation`/`MapKit`/`native_geofence`; `setPluginRegistrantCallback` trước registrant; đăng ký `ArrivalChannel` qua `registrar(forPlugin: "ArrivalChannel")`; class `ArrivalChannel` cuối file |
| `ios/Runner/Info.plist` + `{vi,en}.lproj/InfoPlist.strings` | `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` (câu D12; ngoặc kép kiểu “…” như copy deck). Không thêm `UIBackgroundModes location` |
| `ios/Runner/PrivacyInfo.xcprivacy` | thêm `NSPrivacyCollectedDataTypeCoarseLocation` (linked, không tracking, App Functionality) cho khớp App Privacy §2. Plugin tự mang PrivacyInfo (UserDefaults) |
| `android/.../MainActivity.kt` | tạo `ArrivalChannel` trong `configureFlutterEngine`; `onRequestPermissionsResult` chuyển mã 4712 cho kênh |
| `android/app/src/main/AndroidManifest.xml` | COARSE + FINE + BACKGROUND location; `FOREGROUND_SERVICE_LOCATION` `tools:node="remove"`; 2 receiver của plugin (BroadcastReceiver `exported=false`, Reboot `exported=true`); KHÔNG khai `NativeGeofenceForegroundService` |
| `pubspec.yaml` / `pubspec.lock` / `ios/Podfile.lock` | 2 plugin |

### Hành vi kênh
- **Quyền (D8).** iOS: `requestWhenInUse` chỉ hỏi khi `notDetermined`; `requestAlways` gọi `requestAlwaysAuthorization`, trả lời khi trạng thái đổi, hoặc khi app active lại sau hộp hệ thống (+0,3 s), hoặc sau 1 s nếu không có hộp nào hiện (iOS chỉ hỏi "Luôn luôn" 1 lần mỗi lần cài). `precise` = `accuracyAuthorization == .fullAccuracy`. Android: `denied` = đã hỏi mà chưa cấp (cờ prefs `dear_embeiu_arrival/asked`); `always` = có `ACCESS_BACKGROUND_LOCATION` (API < 29: có vị trí là `always`); `precise` = FINE. `requestAlways` (API 30+) xin `ACCESS_BACKGROUND_LOCATION` ⇒ hệ thống mở trang quyền của app; trả lời trong < 400 ms (đã từ chối hẳn, hệ thống không mở gì) thì app tự mở trang chi tiết app.
- **Vị trí 1 lần.** iOS `requestLocation()` (accuracy best); Android API 30+ `getCurrentLocation` (FUSED API 31+ → GPS nếu FINE → NETWORK), dưới 30 `requestLocationUpdates` lấy bản đầu. Hết `timeout` (mặc định 15 s) → `null`. Dịch vụ vị trí tắt → `null` ngay.
- **Tìm địa chỉ.** Dart rút gọn truy vấn → kênh → lọc tỉnh → `approximate` khi hẻm → ≤ 5. iOS (Lead chốt lại 2026-10-20 để tránh throttle): MỘT `MKLocalSearch` (`naturalLanguageQuery` = chuỗi đã rút gọn, region khung VN, `resultTypes` address + POI) cho mỗi truy vấn → ≤ 5 map item có toạ độ sẵn. Native chờ 500 ms cho ngừng gõ; truy vấn mới tới thì trả `[]` cho truy vấn cũ + `cancel()` lần tìm đang chạy; cache theo chuỗi (tối đa 100). `MKError.loadingThrottled` → `unavailable` ⇒ Dart ném `PlaceSearchUnavailable` (UI có sẵn đường "Dùng vị trí hiện tại"); `placemarkNotFound` → `[]`; `NSURLErrorDomain`/`serverFailure` → `offline`; lỗi khác → `failed`. Title = `mapItem.name`, subtitle = `placemark.title` bỏ phần trùng title + bỏ ", Việt Nam"; `hasNumber` = `placemark.subThoroughfare`. Bỏ hẳn `MKLocalSearchCompleter`: bản trước gọi completer rồi thêm 1 `MKLocalSearch` cho mỗi gợi ý (≤ 5 lần/truy vấn), dễ bị Apple chặn; cách mới cũng chính là cách spike đo được 75 %. `suggestsWhileTyping` vẫn true (kết quả hiện theo từng lần ngừng gõ). Android: `Geocoder(Locale vi_VN).getFromLocationName(q, 5, khung VN)` (API 33+ listener, cũ hơn chạy thread phụ); `isPresent()==false` → `isAvailable` false / lỗi `unavailable`; `IOException`/`onError` → `offline`; `hasNumber` = `subThoroughfare`. Debounce do UI làm (iOS 300 ms, Android 800 ms — design §15).
- **Callback nền.** `arrivalGeofenceTriggered`: `at = DateTime.now()` (plugin không đưa giờ sự kiện) → nếu app đang sống trong cùng tiến trình, chuyển sự kiện cho isolate chính qua `IsolateNameServer` (Hive không an toàn khi 2 isolate cùng ghi một box); không có "accepted" trong 2 s (isolate chính đã chết, tên cũ còn) → tự làm. Tự làm = `DartPluginRegistrant.ensureInitialized()` → `Hive.initFlutter()` → `Firebase.initializeApp()` → `handleArrivalGeofenceEvent`: không có session hoặc đã tắt tự báo → `stopAll`; đọc pin → `reportEvent(source auto, auto true, at)` cho từng slot; `denied` → `stopAll`.
- **Ngoài hợp đồng:** `arrivalBackgroundOptionLabel()` (top-level trong `arrival_platform_native.dart`) trả chữ "Cho phép mọi lúc" của hệ thống (`getBackgroundPermissionOptionLabel`, Android 30+) cho câu D12 màn 2. Hợp đồng `arrival_platform.dart` không có chỗ cho nó ⇒ stage 3 gọi thẳng hàm này (null → dùng chữ trong ARB). Không đổi chữ ký nào trong `arrival_platform.dart`.

### Permission Android (`aapt2 dump permissions` APK debug)
INTERNET · POST_NOTIFICATIONS · RECEIVE_BOOT_COMPLETED · READ_MEDIA_IMAGES · READ_EXTERNAL_STORAGE (max 32) · PACKAGE_USAGE_STATS · ACTIVITY_RECOGNITION · gms ACTIVITY_RECOGNITION (max 28) · **ACCESS_COARSE_LOCATION · ACCESS_FINE_LOCATION · ACCESS_BACKGROUND_LOCATION** · ACCESS_NETWORK_STATE · WAKE_LOCK · VIBRATE · USE_BIOMETRIC · USE_FINGERPRINT · c2dm RECEIVE · AD_ID · ACCESS_ADSERVICES_ATTRIBUTION · ACCESS_ADSERVICES_AD_ID · BIND_GET_INSTALL_REFERRER_SERVICE · READ_GSERVICES · **FOREGROUND_SERVICE** (WorkManager của plugin, quyền thường) · DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION. Không có `FOREGROUND_SERVICE_LOCATION`.

### Kế hoạch B (Play từ chối vị trí nền, D13)
1. `AndroidManifest.xml`: đổi dòng `ACCESS_BACKGROUND_LOCATION` thành `<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" tools:node="remove" />`.
2. `lib/services/arrival_platform.dart`: `kArrivalAutoAndroid = false` (plugin sẽ từ chối tạo geofence trên API ≥ 29, nên phải ẩn hẳn chế độ tự động).
3. Build lại cùng version, build +1; `aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk | grep LOCATION` chỉ còn COARSE + FINE (spike đã chứng minh). Nút bấm tay + "Dùng vị trí hiện tại" vẫn chạy.

### Nháp khai báo (PO/user soát, user bấm gửi)

**Privacy policy — mục mới "Vị trí (Về đến nhà chưa?)"** (nhánh `phase3`, `docs/`):
- vi: "Tính năng *Về đến nhà chưa?* chỉ chạy khi bạn tự bật. Bạn lưu tối đa 5 nơi (Nhà và 4 nơi tự đặt) bằng địa chỉ hoặc vị trí hiện tại. Địa chỉ và toạ độ của các nơi này chỉ lưu trên điện thoại của bạn, không gửi lên máy chủ của Dear Embeiu và không nằm trong bản sao lưu iCloud/Google. Khi bạn bật *Tự báo khi mình đến nơi*, điện thoại dùng vị trí, kể cả khi app đã đóng hoặc không dùng, để nhận ra lúc bạn vào hoặc rời một nơi đã lưu. Lúc đó app chỉ gửi cho người ấy tên nơi, giờ đến hoặc giờ rời và mức pin; máy chủ chỉ giữ một sự kiện mới nhất, không giữ lịch sử đi lại. Khi bạn tìm địa chỉ, chữ bạn gõ được gửi tới dịch vụ bản đồ của Apple (iPhone) hoặc Google (Android) để tìm toạ độ. Dear Embeiu không gửi chuỗi này lên máy chủ của mình và không lưu nó ngoài máy bạn. Tắt chia sẻ thì sự kiện trên máy chủ bị xoá ngay và điện thoại ngừng dùng vị trí; bạn cũng có thể thu hồi quyền vị trí trong Cài đặt của máy."
- en: "*Home yet?* only runs if you turn it on. You can save up to 5 places (Home and 4 of your own) from an address or your current location. Their addresses and coordinates stay on your phone: they are not sent to Dear Embeiu's servers and are left out of iCloud/Google backups. When you turn on *Send automatically*, your phone uses your location, even when the app is closed or not in use, to notice when you reach or leave a saved place. The app then sends your partner only the place name, the arrival or departure time and your battery level; the server keeps just the latest event, with no travel history. When you search for an address, the text you type is sent to Apple's (iPhone) or Google's (Android) map service to find its coordinates. Dear Embeiu does not send that text to its own servers and does not store it anywhere but your phone. Turning sharing off deletes the event from the server right away and the phone stops using your location; you can also revoke location access in your phone's Settings."

**Play Data safety:** Vị trí → *Vị trí gần đúng*: Có thu thập · không chia sẻ với bên thứ ba (gửi cho người ấy do chính người dùng bật — không tính "chia sẻ", Help 10787469) · Tuỳ chọn (người dùng chọn bật) · Mục đích: Chức năng ứng dụng · Có mã hoá khi truyền · Người dùng yêu cầu xoá được (tắt chia sẻ / xoá tài khoản). *Vị trí chính xác*: không thu thập (toạ độ chỉ xử lý trên máy). Giữ nguyên các mục cũ.

**App Store App Privacy:** thêm *Location → Coarse Location*: Linked to the user's identity · Used for App Functionality · Not used for tracking. *Precise Location*: không khai (toạ độ không rời máy). `PrivacyInfo.xcprivacy` đã khai `CoarseLocation` khớp.

**Play — form "Quyền vị trí nền"** (App content → Sensitive app permissions → Location permissions):
- Tính năng dùng vị trí nền (chỉ 1): "Về đến nhà chưa? — báo cho người thân (người yêu đã ghép đôi trong app) rằng bạn đã về đến nhà hoặc đến nơi an toàn."
- Mô tả (en): "Dear Embeiu lets a couple know when the other has arrived safely. When the user turns on 'Send it automatically', the app registers OS geofences (up to 5 places the user saved: Home and their own places). When the user enters or leaves one of them, even with the app closed, the app updates the partner's card with the place name, the arrival or departure time and the battery level (only an arrival sends a notification). Coordinates never leave the device; there is no live tracking, no location history, and no foreground service. The user can always tap 'I'm home' manually instead, and turning the feature off deletes the event and stops the geofences."
- Vì sao cần nền: "Arrival happens when the phone is in a pocket and the app is closed; without background location the safety notice would only work if the user opened the app at the door, which is what the manual button already does."
- Lợi ích: cảm giác an toàn (sense of safety) cho cả hai người.
- Link video + privacy policy URL (web).

**Kịch bản video ≤ 30 s (design §5, quay trên emulator Android 14, giả lập vị trí):**
| Giây | Hình |
|---|---|
| 0–3 | Home, thẻ "Về đến nhà chưa?" (đã đặt địa chỉ Nhà) → chạm "Bật báo về nhà" |
| 3–8 | Màn giải thích 1 (câu D12 có "vị trí" + "kể cả khi app đã đóng hoặc không dùng"), dừng 3 s → "Đồng ý, tiếp tục" |
| 8–11 | Hộp hệ thống "Cho phép khi dùng ứng dụng" + vị trí chính xác |
| 11–15 | Màn "Chọn “Cho phép mọi lúc”" → "Mở trang quyền" |
| 15–19 | Trang quyền hệ thống → chọn "Cho phép mọi lúc" → quay lại app, màn "Đã bật báo về nhà" |
| 19–22 | Vuốt app ra khỏi màn hình (về launcher) |
| 22–27 | Extended controls: đặt vị trí ra ngoài Nhà rồi vào trong (mở Google Maps 1 lần cho emulator có fix — bug emulator README plugin) |
| 27–30 | Máy kia (hoặc ghép màn hình) nhận push "Tuấn đã về đến nhà" |

### Edge case / cần đo trên máy thật (Tester / Lead smoke)
- Android dùng DWELL 2': đến nơi báo trễ ≥ 2'; đi ngang rìa < 2' không báo (chủ ý D6). Nếu thực tế trễ quá → đổi `NativeArrivalGeofence.androidDwell` hoặc dùng `enter`.
- Không có initial trigger: bật tự báo lúc đang ở Nhà thì lần đầu sẽ là "rời Nhà" (không push), lần về sau mới push. Đúng D6, nhưng người thử sẽ tưởng "không chạy" nếu đứng yên ở nhà.
- iOS: registrant đăng ký MỌI plugin lên engine headless (spike §6.4). Plugin nào crash khi không có UI → crash nền. Cần smoke: bật tự báo, kill app, ra/vào vùng.
- iOS: 1 `MKLocalSearch` / truy vấn sau 500 ms; chưa đo trên iPhone gõ nhanh có chạm `loadingThrottled` không (khi chạm, UI hiện "Dùng vị trí hiện tại" như máy không có geocoder). Tìm theo cụm chưa gõ xong ("12 Nguyễn Tr") cho kết quả kém hơn completer — cần soi lúc smoke.
- `at` = giờ isolate nền chạy, không phải giờ hệ thống thấy sự kiện; Android WorkManager có thể trễ vài phút (sự kiện > 30' sẽ thành "cũ", không push — D6).
- Isolate chính sống nhưng bận > 20 s: callback nền thả, isolate chính vẫn làm xong. Isolate chính vừa mở trong lúc callback nền đang ghi Hive: cửa sổ rất nhỏ 2 isolate cùng ghi box (`ponytail`: chấp nhận; nếu thấy hỏng box thì chuyển trạng thái rìa vùng sang file riêng).
- Android Geocoder: chưa đo độ chính xác + thời gian; `Locale vi_VN` cố định (kết quả luôn tiếng Việt, khớp cách lọc tỉnh).
- Android `requestAlways` khi người dùng đã từ chối "mọi lúc" 2 lần: app tự mở trang chi tiết app (ngưỡng 400 ms là ước lượng).

## Stage 3 — UI (nhánh `feature/arrival-ui`, Lead gộp với ghi chú stage 2)

### File mới
| File | Nội dung |
|---|---|
| `lib/widgets/arrival/arrival_card.dart` | `ArrivalCard` (design §3, Home C §15): hai làn tint màu người α .10 (màu lấy `SleepProvider.myColorId/partnerColorId` như SleepCard), Bạn trái · người ấy phải, `PersonLabel`; trạng thái: đang tải (skeleton) · lần đầu chưa ai bật (câu mời + "Bật báo về nhà" đặc + "Về nhà rồi" viền) · bạn chưa bật · người ấy chưa bật (nền `surfaceLight`) · người ấy bật nhưng tin > 3 ngày ("Đang bật báo về nhà") · có tin (câu ≤ 3 dòng, icon nơi, giờ hôm nay/hôm qua/d/M, pin thường hoặc pill vàng ≤ 20 %, "bấm tay") · dòng trạng thái của bạn (tự báo / thiếu Luôn luôn + Mở Cài đặt / tắt từ xa / chưa đặt địa chỉ + Đặt địa chỉ / chỉ bấm tay) · "✓ Đã báo Thảo" 4 s · dải "Sẽ báo khi có mạng" · dải lỗi + "Thử lại". Chân thẻ: "Về nhà rồi" + "Đến nơi rồi ⌄" (`arrow_down`) viền h44 lưới 2 cột; chữ ≥ 1.3× thì làn và nút xếp dọc. `showArrivalPickSheet` = sheet "Bạn vừa đến đâu?". `MidnightBuilder` đổi "hôm qua" lúc 0:00. |
| `lib/widgets/arrival/arrival_format.dart` | khoá icon → Iconsax, câu "Đã về đến nhà/Đã đến {place}", giờ, "Nhà và N nơi khác", tên mình/người ấy theo couple |
| `lib/widgets/arrival/arrival_scaffold.dart` | khung màn con (dawnBlush + `SubScreenHeader` chip VỀ ĐẾN NHÀ + tiêu đề 26 + nút neo đáy đi lên theo bàn phím), nút chính h52, hộp vàng, hộp gợi ý |
| `lib/screens/arrival_place_screen.dart` | `openArrivalNewPlace` / `openArrivalPlaceSearch` / `openArrivalEditPlace`; tên + 5 chip (tự chọn biểu tượng) + 7 biểu tượng radio + xem trước; tìm địa chỉ (debounce 300 ms nếu `suggestsWhileTyping`, không thì 800 ms + nút Tìm; bỏ kết quả của truy vấn cũ bằng token; dòng "Dùng vị trí hiện tại" luôn ở cuối; không thấy / mất mạng / lỗi khác / máy không có geocoder); vị trí hiện tại (giải thích → `requestWhenInUse` nếu chưa có → từ chối thì quay về ô tìm, không hỏi lại → gần đúng thì khung "Cần bật Vị trí chính xác" → `current()` null = "Chưa đọc được vị trí", thử lại được); xác nhận (250/150 m theo nguồn, hộp "chưa có số nhà" khi `!hasHouseNumber`, hộp hẻm `arrivalConfirmAlleyWarn` khi `approximate`); sửa nơi / sửa Nhà; xoá = hộp hỏi lại + SnackBar "Hoàn tác" 5 s (`deletePlace` trả nơi cũ → `savePlace`). Mọi route của luồng tên `ArrivalPlace/…`, Lưu xong `popUntil` ra khỏi luồng + SnackBar "Đã lưu …". |
| `lib/screens/arrival_setup_screen.dart` | `openArrivalSetup(from:)`: tắt từ xa / hằng D13 → chỉ bật chia sẻ rồi mở Quản lý. Bước: chưa có nơi nào có vị trí → "Trước hết, nhà bạn ở đâu?" → giải thích D12 (chấm bước 1, xem trước push, link chính sách) → `setShare(true)` + `setWantsAuto(true)` + `requestWhenInUse` → bước 2 "Chọn “Luôn luôn”"/"Cho phép mọi lúc" (danh sách giả + gợi ý vuốt tắt / Tự khởi động) → `requestAlways` → Xong / Dừng giữa chừng. Android: trả lời trên trang Cài đặt nên kiểm lại lúc resume. "Để sau, mình bấm tay" = `setWantsAuto(false)`. |
| `lib/screens/arrival_manage_screen.dart` | `openArrivalManage(from:)`: "Thảo đang thấy" (làn của bạn) · công tắc "Báo cho Thảo" (tắt → hộp "Tắt báo về nhà?" + ô "Xoá luôn địa chỉ đã lưu của N nơi") · "Tự báo khi mình đến nơi" (bật → luồng bật tự báo; chưa có vị trí → khoá + nút Đặt địa chỉ Nhà; tắt từ xa → khoá) · "Nơi báo" (Nhà + ≤ 4, Thêm nơi / Còn N chỗ) · Quyền vị trí (chỉ khi đang muốn tự báo; đọc lại mỗi lần resume) + gợi ý đừng vuốt tắt (iOS). |
| `test/arrival_ui_test.dart` | 16 test: thẻ (chưa bật, đang bật + pin yếu + thứ tự làn, người ấy tắt / im lặng > 3 ngày, chờ mạng, thất bại → Thử lại, sheet Đến nơi rồi), luồng thêm nơi (chip → tìm → xác nhận không số nhà → lưu), xác nhận có số nhà / hẻm, vị trí hiện tại timeout + thử lại thành công 150 m, từ chối quyền quay về, xoá + hoàn tác, push tap, widget từ push nền + từ app, widget tap. Fake: `_Service` (FakeArrivalService của stage 1 + Hive trong bộ nhớ), `_Search`, `_Perms`, `_Location`. |

### File dùng chung (chỉ thêm, khối `// ── arrival (đợt 2) ──`)
- `lib/l10n/app_{en,vi}.arb`: 184 key `arrival*` một khối trước `}` cuối; `flutter gen-l10n`.
- `lib/screens/home_screen.dart`: `_arrivalKey`; thẻ ở dòng đánh dấu Home C (chỉ khi `!couple.isWaitingForPartner` và `ArrivalProvider.visible`); re-arm `watchForCouple(couple, me, partnerUid)` cạnh Sleep; `onResume()` khi app resume; focus `arrival` → cuộn tới thẻ; `ArrivalProvider` là nguồn của dòng widget (`partnerArrival: partnerLast`).
- `lib/services/push_notification_service.dart`: `NotificationTapRouter.focusArrival = 'arrival'`; nhánh `case 'arrival'` → tab 0 + focus; seam `applyRouteForTest` (`@visibleForTesting`).
- `lib/services/home_widget_status.dart`: `arrivalHome`/`arrivalPlace` (+ `kinds`, `focuses` thêm `arrival`); `build(partnerArrival:)` chỉ nhận sự kiện ĐẾN của hôm nay; `fromPush` `type == 'arrival'` đọc `place`, `placeName`, `actorName`, `date`.
- `lib/services/analytics_service.dart`: 8 event §9 (`arrival_setup_open`, `_permission`, `_place_saved`, `_address_search`, `_place_deleted`, `_share_toggled`, `_manual`, `_card_action`), không gửi tên/địa chỉ/chuỗi gõ/% pin.
- `lib/screens/settings_screen.dart`: Thông báo → `_ArrivalPushTile` "Khi người ấy đến nơi" (`NotificationSettingsService.set(keyArrival)` rồi `refreshDeviceRegistration()`); Chung → hàng "Về đến nhà" trước "Ảnh nền thẻ đếm". Cả hai chỉ khi `ArrivalProvider.visible`.
- `lib/data/feature_tour_entries.dart`: mục `sinceBuild: 33` (`arrivalTourTitle/Body`, mở tab Home).
- Không đụng `AppNotification` / `notification_center_screen.dart`: arrival không có item inbox (D15).

### Tự quyết khi spec chưa vẽ (đã tra UI UX Pro Max 2.13.0, `--domain ux`)
- `"loading timeout retry error"` → *Error Messages* (phải đọc được bằng trình đọc màn hình) + *Error Placement*: hết 15 s không có vị trí → hộp vàng `liveRegion` ngay dưới phần giải thích, nút "Đọc vị trí" vẫn bấm lại được. Copy mới `arrivalReadTimeout`. Lỗi tìm khác (không phải mất mạng / không thấy) → `arrivalSearchError` cùng khuôn với "không thấy".
- `"undo snackbar after delete"`, `"toggle switch"`, `"snackbar" --stack flutter`: không khớp ⇒ theo `references/quick-reference.md` `undo-support`: giữ hộp hỏi lại của design + thêm SnackBar "Hoàn tác" 5 s (Lead chốt). Xoá nơi cuối cùng có vị trí khi đang tự báo → `setWantsAuto(false)`, hoàn tác bật lại.
- Dòng trạng thái của bạn khi đang chia sẻ mà không tự báo (spec chỉ vẽ tự báo / thiếu quyền / tắt từ xa / chưa có địa chỉ): thêm "Chỉ báo khi bạn bấm" (`arrivalMineManual`) để D11 luôn có một dòng nói mình đang chia sẻ gì.
- Chân thẻ chỉ có một nút (chưa có nơi tự đặt): nút trải hết bề ngang thay vì nửa lưới.

### Lệch thiết kế + lý do
- Công tắc "Tự báo" khi thiếu "Luôn luôn": vẫn bấm được (mock khoá). Khoá thì người dùng không tắt được tự báo khi đang thiếu quyền.
- Nhãn Android "Cho phép mọi lúc" lấy từ l10n, KHÔNG từ `getBackgroundPermissionOptionLabel()` (D12): hợp đồng `ArrivalPermissions` không có hàm trả nhãn. Muốn đúng chữ hệ thống thì stage 2/Lead thêm getter, UI đổi một chỗ (`arrival_setup_screen.dart`, `_Step.always`).
- Gạch chân phần khớp chữ đang gõ (iOS) chưa làm: kết quả in đậm dòng 1 như Android.
- "✓ App đã nhận ra {place}" (D21): hiện khi sự kiện tự động đến nơi trong 24 giờ sau lúc lưu địa chỉ nơi đó (không lưu cờ "lần đầu") — có `ponytail:` trong code.
- Chuỗi en `arrivalTurnOffBody` thêm `{me}` cho khớp placeholder bản vi.
- "Hỏi thăm" điền sẵn TIÊU ĐỀ màn Quan tâm = "Về tới nơi rồi thì nghỉ ngơi nhé", thân để trống.

### Cho Tester soi
- Chưa chạy trên máy (luật đợt này): bàn phím che nút neo đáy, cuộn tới thẻ khi chạm push, chữ to 1.3×/2× trên khổ 360, VoiceOver đọc làn.
- Luồng Android "Cho phép mọi lúc": chuyển sang Xong chỉ khi app resume và `status().canAuto`; nếu stage 2 trả `requestAlways` ngay mà trang quyền chưa đóng thì màn đứng ở bước 2 tới khi quay lại.
- Thẻ đọc `SleepProvider` để lấy màu: người chưa bật giấc ngủ = màu mặc định (Lead chốt).

### Stage 3 — vòng sửa theo review UI (2026-10-20, nhánh `feature/arrival`)
- **Câu hỏi native đã khớp:** Android `requestAlways` (`ArrivalChannel.kt`) chỉ trả kết quả trong `onRequestPermissionsResult` = lúc người dùng quay lại app; trả trong < 400 ms (hệ thống không hiện gì) thì mở trang quyền của app và trả trạng thái chưa cấp ⇒ màn đứng ở bước 2, resume kế tiếp đọc lại `status().canAuto` rồi sang Xong. iOS trả sau callback hoặc 1 s ⇒ chưa có Luôn luôn thì "Dừng giữa chừng". Bước 2 dùng chữ thật của máy `arrivalBackgroundOptionLabel()` (null → `arrivalAlwaysLabelAndroid`), seam `ArrivalSetupScreen.backgroundLabel`.
- **M1 dải "Sẽ báo khi có mạng" kẹt:** `ArrivalShare.pending` (= `hasPendingWrites`, `watchShare` nghe cả `includeMetadataChanges`) ; provider lưu `_sentAt` và xoá `lastResult == queued` khi snapshot của mình hết pending và `last.at` ≥ lúc gửi − 1 s (kể cả khi ack tới trước lúc timeout trả `queued`).
- **M2:** `denied` dùng chung dải lỗi + "Thử lại" với `failed`; `dropped` (nơi đã mất, đang gửi, couple hết active) hiện SnackBar "Chưa gửi được tin “…”".
- **M3 Reduce Motion** (`AppMotion.reduceMotion`): `AnimatedSize` dải, icon nút, chấm bước, danh sách kết quả → `Duration.zero`; tin mới của người ấy fade 200 ms.
- **M4:** chip gợi ý cao 44; `_SwitchRow` ở Quản lý: cả hàng bấm được (`InkWell`) + `MergeSemantics` đọc tiêu đề, phụ đề, công tắc; nút phụ (Đặt địa chỉ / Mở Cài đặt) nằm ngoài vùng gộp.
- **L5:** `_agree` / `_askAlways` có try/catch/finally; plugin lỗi ở bước 1 → "Dừng giữa chừng", ở bước 2 → ở lại, nút bấm lại được.
- **L6:** màn Xác nhận khoá bấm đúp (nút quay), `savePlace` false → ở lại + SnackBar (`arrivalPlacesFull` khi đủ 4 nơi, `arrivalSaveFailed` còn lại).
- **L7:** `ArrivalProvider.holdSlot/releaseSlot`: slot vừa xoá giữ 6 s (SnackBar 5 s), `nextFreeSlot`/`canAddPlace` tính cả slot đang giữ; hoàn tác không ghi đè nơi đang chiếm slot (hay địa chỉ Nhà mới) → SnackBar `arrivalUndoFailed`. Timer huỷ ở `clear`/`dispose`.
- **L8:** ngày `DateFormat.Md(locale)` (vi 13/10, en 10/13) cho "d/M HH:mm" của thẻ và "Lưu từ địa chỉ · …".
- **L9:** iOS (`suggestsWhileTyping`) gạch chân phần khớp chữ đang gõ trong dòng kết quả (`arrivalMatchRange`, không phân biệt hoa thường, so nguyên dấu); dòng vẫn w700 nên không dùng đậm để đánh dấu — đúng design §4.3, không cần tự quyết.
- Hai hàng Cài đặt chuyển sang `lib/widgets/arrival/arrival_settings_tiles.dart` (`ArrivalPushTile` có seam `load/save`, `arrivalSettingsSubtitle`) để test được; `settings_screen.dart` chỉ còn gọi tới.
- ARB thêm 3 key: `arrivalSaveFailed`, `arrivalPlacesFull`, `arrivalUndoFailed`.
- Test `test/arrival_ui_test.dart` 16 → 38: ack xoá dải chờ mạng, `denied`, `dropped`, Reduce Motion, chữ ×1,3 xếp dọc, Setup chưa có nơi, Setup Android (nhãn máy, quay lại từ trang quyền → Xong), plugin lỗi, Quản lý + hộp tắt có ô xoá địa chỉ, giới hạn 4 nơi / "Còn 1 chỗ", tìm Android 800 ms + gợi ý nút Tìm, không thấy, mất mạng, máy không có geocoder, gạch chân khớp, sửa nơi, sửa Nhà, giữ slot khi hoàn tác, Xác nhận lưu thất bại, 2 hàng Cài đặt, ngày theo locale.

## Nhật ký implement
- [2026-10-20] [Dev] Stage 1: lớp dữ liệu Dart (model, Hive `arrival_nobackup`, `ArrivalService`, `ArrivalProvider`, bộ lọc rìa vùng, interface geofence/tìm địa chỉ/pin + bản no-op, cờ D13), wire `main.dart` + `session_resolver.dart`, xoá dữ liệu máy khi xoá tài khoản, `pushArrival` đọc giá trị thật. Commit `632a24a`. `flutter analyze` 0, `flutter test` 661 pass (+23 trong `test/arrival_test.dart`).
- [2026-10-20] [Dev] Stage 1: rules `arrival/{uid}` + `pushArrival` trên doc thiết bị, CF `notifyArrival`, dọn arrival trong `notifyPartnerLeft` / `handleCoupleOnAccountDeletion` / `deleteCoupleCompletely`. Commit `1f7434c`. Rules-test 423 passing (+29 trong `firestore.arrival.test.js`), functions `npm test` 32 pass (+11). Chưa deploy.
- [2026-10-20] [Dev] Vá review backend của Lead: sổ push sang `arrivalPush/{uid}` (không ai đọc), tắt = xoá doc, transaction kiểm lại `share`/`last`, xoá sổ khi rời/xoá tài khoản, trạng thái trong/ngoài chỉ lưu khi đã gửi/xếp hàng. Commit `4dd0aa5`. Rules-test 424 pass, functions 35 pass.
- [2026-10-20] [Dev] Stage 2 native: `native_geofence` + `battery_plus`, kênh `dear_embeiu/arrival` (quyền, vị trí 1 lần, tìm địa chỉ iOS completer+MKLocalSearch / Android Geocoder), hàm thuần rút gọn truy vấn + lọc tỉnh (test 20 địa chỉ spike + 4 hẻm), callback nền + cầu sang isolate chính, manifest/Info.plist/InfoPlist.strings/PrivacyInfo, nháp khai báo store. `flutter analyze` 0, `flutter test` 693 pass (~3 skip), `flutter build apk --debug` PASS (Gradle 29 s), `flutter build ios --debug --no-codesign` PASS (Xcode 205 s, pod install 34 s). Chưa chạy trên máy.
- [2026-10-20] [Dev] Theo Lead: tìm địa chỉ iOS đổi sang 1 `MKLocalSearch`/truy vấn (500 ms, cancel lần cũ, cache theo chuỗi, throttle → `PlaceSearchUnavailable`), bỏ `MKLocalSearchCompleter`. `flutter analyze` 0, `flutter test` 693 pass, `flutter build ios --debug --no-codesign` PASS.
- [2026-10-20] [Dev] Stage 3 (UI): thẻ Home, thêm/sửa nơi, bật tự báo, quản lý, Cài đặt, push tap + widget, analytics, feature tour; 184 key ARB. `flutter analyze` 0, `flutter test` 679 pass (+16 `test/arrival_ui_test.dart`). Nhánh `feature/arrival-ui`.
- [2026-10-20] [Dev] Stage 3 vòng review UI: 9 finding (M1–M4, L5–L9) + nhãn Android thật; `flutter analyze` 0, `flutter test` 730 pass (`arrival_ui_test.dart` 38).
- [2026-10-20] [Dev] Vá review native của Lead (nhánh `feature/arrival-native-fix`): sự kiện tự động không bật được chia sẻ (rules + update + quên Tự báo khi doc mất), loại prefs plugin khỏi backup Android, Android đăng ký lại vùng mỗi lần resume, cầu nối isolate không xoá tên + bỏ tin muộn, công tắc D13 + App Check ở callback nền, iOS chỉ xin Luôn luôn sau Khi dùng app, timeout tìm địa chỉ.
- [2026-10-22] [Dev] Vá theo báo cáo Tester 2026-10-22. **BUG-1:** `ArrivalProvider._syncAuto` chỉ chạy khi đã có snapshot đầu của `arrival/{me}` (`_mineKnown`) VÀ `onResume` đã đọc xong quyền + `config/app` (`_permsKnown`) ⇒ mở app khi đang tự báo không còn `stopAll()` + `auto:false` vì "chưa đọc"; `reCreateAfterReboot()` chỉ chạy 1 lần mỗi tiến trình (cờ static `_reCreated` trong `NativeArrivalGeofence.sync`), resume không còn làm lại vùng (làm lại vùng reset DWELL 2'). **BUG-2 (phương án a, vẫn gửi sự kiện rời):** câu xin quyền `Info.plist` + `{vi,en}.lproj/InfoPlist.strings` (cả 2 khoá vị trí), ARB `arrivalDisclosureBody` vi/en, nháp privacy + mô tả form Play ở trên nói rõ gửi tên nơi, giờ đến, giờ rời, mức pin; `flutter gen-l10n`. **BUG-3:** `watchForCouple` lưu future tải Hive (`_loading`) + số thế hệ `_gen`: lệnh sau cùng user chờ đúng lần tải đó, lệnh bị vượt dừng sau khi tải; D10 so với `_partnerUid` hiện tại. **BUG-4:** Hive `sharePartner:{uid}` ghi người ấy lần trước; khác người ấy hiện tại ⇒ xoá `arrival/{me}` (lệnh xoá xếp sau lệnh bấm tay offline nên thắng), lần đầu (chưa có giá trị) chỉ ghi lại; `wipeLocalData` xoá khoá này. Không đụng rules/functions. Hở biết trước: lệnh bấm tay cũ vẫn có thể lên server trước lệnh xoá ⇒ người ấy mới có thể nhận 1 push cũ; cùng tài khoản trên 2 máy thì máy mở sau xoá luôn chia sẻ máy kia vừa bật với người ấy mới. Test +3 trong `test/arrival_test.dart` (fail trước khi vá, pass sau). Sửa ghi chú Edge case `pushArrival` (silent wake vẫn tới).
