# 💻 Dev — Về đến nhà chưa? (arrival)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Chia 3 stage, mỗi stage một agent nối tiếp trên nhánh `feature/arrival` (worktree `dear_embeiu-arrival`).

- **Trạng thái dev:** stage 1/3 xong (backend + lớp dữ liệu). Stage 2 (native) và stage 3 (UI) chưa bắt đầu.
- **Người/role:** Dev
- **Deploy:** chưa. Lead deploy DEV từ nhánh gộp. PROD: `firestore:rules` + `functions:notifyArrival,functions:notifyPartnerLeft,functions:deleteAccount,functions:leaveCoupleCleanup`, rules phải lên PROD trước khi bản có arrival live.

## Stage 1 — đã làm

### Firestore rules (`firestore.rules`)
- `isValidDeviceDocument`: thêm `pushArrival` (bool, không bắt buộc, `.get('pushArrival', true)`).
- Khối mới trong `match /couples/{coupleId}`: hàm `isValidArrivalEvent(e)`, `isValidArrivalDoc(d)`, `match /arrival/{uid}`:
  - đọc: thành viên couple; ghi: chỉ chủ (`uid == request.auth.uid`), khoá client chỉ `share`/`auto`/`last`/`updatedAt`; khoá CF (`lastPushAt`, `pushDay`, `pushCount`) không client nào ghi được, update để nguyên thì qua.
  - `share` khác `true` thì không được còn `last` (tắt = xoá cùng lần ghi, D11).
  - Bật `share` chỉ khi couple đủ 2 người (create luôn kiểm; update kiểm khi trước đó chưa bật).
  - Update chỉ kiểm lại `last` khi `last` nằm trong `affectedKeys` → đổi `auto` lúc sự kiện cũ hơn 12 giờ vẫn qua.
  - Tên nơi: `size()` 1..24 (đơn vị UTF-16, giống decision-wheel DW-R2-1), `trim().size() >= 1`, không `\r`/`\n` (RE2 `(?s).*[\\r\\n].*`).
  - `delete: false`.

### Cloud Functions (`functions/index.js`)
- `PUSH_TYPE_PREF_FIELD.arrival = "pushArrival"`.
- Khối `// ── arrival (đợt 2) ──` trước phần Love Note: hằng `ARRIVAL_*`, `ARRIVAL_COPY` (vi/en đúng §7), hàm thuần `arrivalVnDateKey`, `arrivalEvent`, `arrivalPushPlan`, `arrivalClaim`, `buildArrivalText`, lõi `processArrivalWrite`, trigger `exports.notifyArrival` (onDocumentWritten `couples/{coupleId}/arrival/{uid}`).
  - Bỏ qua: doc xoá · `share != true` · `last` không đổi (place+type+at) · `exit` · `bounce` · sự kiện cũ hơn 30' · couple không `active` hoặc người gửi không còn trong `memberIds` · cùng nơi đã push trong 30' · đủ 6 push/ngày (ngày theo UTC+7). Cooldown + trần nhận trong transaction, ghi `lastPushAt.{slot}` + `pushDay` + `pushCount`.
  - `sendToRecipientDevices(…, {type:'arrival', coupleId, place, placeName?, icon?, battery? (chuỗi), actorName, date}, {wakeClients:true, collapseId:'arrival_<uid>'})`. Không inbox.
  - Tắt chia sẻ (doc còn `lastPushAt`) → CF xoá `lastPushAt` để người ấy không đọc được giờ đến các nơi gần nhất.
- `notifyPartnerLeft`: `recursiveDelete(arrival/{người rời})`; người ở lại → `share:false, auto:false`, xoá `last` + `lastPushAt`.
- `handleCoupleOnAccountDeletion`: xoá `arrival/{uid}` ngay sau `sleep/{uid}` (cùng vị trí, trước kiểm member). `deleteCoupleCompletely`: `recursiveDelete(arrival)`.

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
- CF xoá `lastPushAt` khi tắt chia sẻ (D11: người ấy đọc được doc). `pushDay`/`pushCount` giữ lại để trần 6/ngày không bị lách bằng tắt/bật.

### Edge case / nợ cho Tester
- Thiết bị tắt `pushArrival`: `sendToRecipientDevices` bỏ hẳn thiết bị đó, nên không có wake nền ⇒ widget máy đó chỉ đổi khi mở app (thẻ Home vẫn đổi realtime). Acceptance §10 "Mute … widget vẫn đổi" chỉ đúng sau khi mở app. Muốn widget đổi ngay cần helper gửi silent cho thiết bị đã mute — đổi helper dùng chung, chưa làm.
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

## Spike (stage 2 điền)
- _(chưa có số đo)_

## Nhật ký implement
- [2026-10-20] [Dev] Stage 1: lớp dữ liệu Dart (model, Hive `arrival_nobackup`, `ArrivalService`, `ArrivalProvider`, bộ lọc rìa vùng, interface geofence/tìm địa chỉ/pin + bản no-op, cờ D13), wire `main.dart` + `session_resolver.dart`, xoá dữ liệu máy khi xoá tài khoản, `pushArrival` đọc giá trị thật. Commit `632a24a`. `flutter analyze` 0, `flutter test` 661 pass (+23 trong `test/arrival_test.dart`).
- [2026-10-20] [Dev] Stage 1: rules `arrival/{uid}` + `pushArrival` trên doc thiết bị, CF `notifyArrival`, dọn arrival trong `notifyPartnerLeft` / `handleCoupleOnAccountDeletion` / `deleteCoupleCompletely`. Commit `1f7434c`. Rules-test 423 passing (+29 trong `firestore.arrival.test.js`), functions `npm test` 32 pass (+11). Chưa deploy.
