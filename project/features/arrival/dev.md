# 💻 Dev — Về đến nhà chưa? (arrival)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Chia 3 stage, mỗi stage một agent nối tiếp trên nhánh `feature/arrival` (worktree `dear_embeiu-arrival`).

- **Trạng thái dev:** stage 1/3 xong (backend + lớp dữ liệu). Stage 3 (UI) xong trên nhánh `feature/arrival-ui` (mục "Stage 3 — UI"). Stage 2 (native) làm song song.
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

## Nhật ký implement
- [2026-10-20] [Dev] Stage 1: lớp dữ liệu Dart (model, Hive `arrival_nobackup`, `ArrivalService`, `ArrivalProvider`, bộ lọc rìa vùng, interface geofence/tìm địa chỉ/pin + bản no-op, cờ D13), wire `main.dart` + `session_resolver.dart`, xoá dữ liệu máy khi xoá tài khoản, `pushArrival` đọc giá trị thật. Commit `632a24a`. `flutter analyze` 0, `flutter test` 661 pass (+23 trong `test/arrival_test.dart`).
- [2026-10-20] [Dev] Stage 1: rules `arrival/{uid}` + `pushArrival` trên doc thiết bị, CF `notifyArrival`, dọn arrival trong `notifyPartnerLeft` / `handleCoupleOnAccountDeletion` / `deleteCoupleCompletely`. Commit `1f7434c`. Rules-test 423 passing (+29 trong `firestore.arrival.test.js`), functions `npm test` 32 pass (+11). Chưa deploy.
- [2026-10-20] [Dev] Stage 3 (UI): thẻ Home, thêm/sửa nơi, bật tự báo, quản lý, Cài đặt, push tap + widget, analytics, feature tour; 184 key ARB. `flutter analyze` 0, `flutter test` 679 pass (+16 `test/arrival_ui_test.dart`). Nhánh `feature/arrival-ui`.
