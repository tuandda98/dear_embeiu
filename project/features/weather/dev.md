# 💻 Dev — Thời tiết hai nơi (weather)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước (mục 14b "Soát dễ dùng" của design thắng các mục cũ khi lệch). Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** stage 1 + stage 2 xong (backend, lớp dữ liệu, thẻ Home, 2 sheet, Cài đặt, thông báo 07:30, analytics) + đã vá 8 finding review backend. Chờ Lead smoke 2 máy + Tester. Spike D3 chưa chạy (không chặn, Lead chốt).
- **Người/role:** Dev
- **Nhánh / worktree:** `feature/weather` ở `/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu-weather`
- **Deploy:** chưa deploy gì (Lead deploy DEV từ nhánh gộp). PROD chờ lệnh user: `firestore:rules,functions:getCityWeather,functions:notifyPartnerLeft` — rules phải lên PROD trước khi bản có feature live.

## Kế hoạch kỹ thuật

### Stage 1 (đã làm)

| Lớp | File | Ghi chú |
|---|---|---|
| Danh sách thành phố | `lib/data/weather_cities.dart` (`kWeatherCities`, 116 = 66 VN + 50 nước ngoài) · `functions/weather_cities.json` (id + lat/lon) | Thứ tự = thứ tự sheet chọn: 6 thành phố trực thuộc TW, phần còn lại VN A→Z theo tên bỏ dấu, nước ngoài theo Phụ lục A. Toạ độ trung tâm 2 chữ số thập phân, `tz` IANA, alias theo `docs/design/weather/data.js` + HCM/HCMC/SG. TP.HCM có `shortEn: 'HCMC'` (quyết định 3 của Lead). Thêm/bớt thành phố = sửa CẢ 2 file; test so khớp. |
| Model | `lib/models/weather.dart` | `WeatherCity` (`name/shortName/region(lang)`, `isVietnam`), `WeatherChoice` (`setBySelf`), `WeatherHour`, `CityForecast` (`fetchedAt` từ server, `checkedAt` của máy này, JSON cho Hive). |
| Logic thuần | `lib/utils/weather_logic.dart` | `weatherSkyOf` (map `symbol_code` §6.3, bỏ hậu tố) · `weatherConditionFor(hours, now, offset)` (§6.2 + D10: đang mưa > sắp mưa sáng/chiều/tối/sáng mai > nắng gắt ≥35 > lạnh ≤15 hoặc tuyết > trời; cửa sổ tới 23:59 giờ thành phố, từ 22:00 nới tới 09:59 sáng mai; trả `temp/min/max/sky/night` + `cta`) · `weatherFreshness` (≤6 giờ / 6–24 giờ / >24 giờ, D16) · `weatherTempGap` (≥5°, D11) · `WeatherPlace` · `weatherSharedRow` (design §9.7) · `weatherCardCompact` (Home C §15) · `weatherFold` + `searchWeatherCities` (không dấu, bỏ khoảng trắng, trả `via` = alias khớp) · `weatherCityById`. Không có chữ: chữ nằm ở ARB (stage 2). |
| Service | `lib/services/weather_service.dart` | `watchChoices(coupleId)` (≤2 doc) · `setCity(coupleId, ownerUid, myUid, cityId)` (set cả doc, `updatedAt` = serverTimestamp; ném lỗi khi rules chặn) · `fetchForecasts(ids, languageCode)` (callable, timeout 15 s, trả các thành phố server có dữ liệu) · Hive box `weather_cache` (`Box<dynamic>`, mỗi thành phố 1 chuỗi JSON): `loadCached` / `saveCached` / `clearCache`. Không Firebase → luồng rỗng, không ghi. |
| Provider | `lib/providers/weather_provider.dart` | `watchForCouple(coupleId, myUid, partnerUid)` (partnerUid '' khi chờ người ấy → bỏ qua doc của uid khác) · `clear({signedOut})` (đăng xuất thì xoá cả Hive) · `refresh({force})` (1 callable cho cả 2 thành phố, bỏ qua thành phố máy này hỏi chưa tới 30 phút trừ khi `force`) · `onResume()` · `setMyCity` / `setPartnerCity` (lạc quan, rollback khi rules chặn; trả `false` để UI hiện SnackBar "Thảo vừa tự chọn…") · getter `myCity/partnerCity` (id lạ → null), `canPickForPartner` (D6), `nothingPicked`, `isLoadingFirst`, `lastRefreshFailed`, `myPlace/partnerPlace`, `sharedRow`, `compact`, `placeFor(city)` · `cityUtcOffset(city, now)` (tz database, có DST). |
| Wire | `lib/main.dart` (MultiProvider) · `lib/app/session_resolver.dart` (param `weatherProvider` ở signature + call site; watch trong nhánh có couple, kể cả đang chờ; clear ở 3 nhánh còn lại) | Khối có chú thích `// ── weather (đợt 2) ──`. |
| CF | `functions/index.js` cuối file: `WEATHER_CITIES`, `WEATHER_CONFIG`, `WEATHER_ERROR_COPY`, `weatherErrorCopy`, `parseWeatherCityIds`, `normalizeMetForecast`, `weatherExpiresAt`, `getWeatherForCity`, `exports.getCityWeather` · `notifyPartnerLeft` thêm xoá `weather/{leaverUid}` (D18) | Xem "Cloud Function" dưới. |
| Rules | `firestore.rules`, khối `match /weather/{uid}` trong `match /couples/{coupleId}` (ngay trên careMessages) | Xem "Rules" dưới. |

### Cloud Function `getCityWeather` (callable v2, us-central1, 30 s, 256 MiB)

- Vào `{cityIds: string[1..2], lang?}`; id phải có trong `weather_cities.json` (Map `.has`, nên `__proto__` / `constructor` bị chặn), trùng thì gộp. Sai → `invalid-argument`; chưa đăng nhập → `unauthenticated`; cả 2 thành phố đều không có dữ liệu → `unavailable`. Câu lỗi vi/en theo đúng luật ngôn ngữ của `CALLABLE_ERROR_COPY` (`weatherErrorCopy` gọi lại `callableErrorCopy`, không sửa bảng dùng chung).
- Mỗi id: đọc `weatherCache/{id}`; còn `expiresAt` → trả luôn. Hết hạn → `fetch` MET `/compact?lat&lon` với `User-Agent: DearEmbeiu/1.0 (https://dearembeiu.com)` + `If-Modified-Since: lastModified`, timeout 8 s (`AbortSignal.timeout`). 200 → `normalizeMetForecast` (36 giờ từ giờ hiện tại, `{t, temp (1 số lẻ), symbol, rain (mm/giờ)}`; khi MET sang bước 6 giờ thì giữ mã 6 giờ, chia đều lượng mưa) → ghi cache `{cityId, fetchedAt, expiresAt, lastModified, hours}`. 304 → chỉ dời `expiresAt`. `expiresAt = max(Expires, now + 30 phút)`.
- Lỗi / timeout / 5xx / body rỗng → trả cache cũ `stale: true` (không có cache → bỏ thành phố đó khỏi kết quả) và ghi `retryAt = now + 10 phút`: trong 10 phút đó không gọi MET lại (MET sập thì mỗi lần mở app không thành một request). **Thêm so với spec**, chống dội MET.
- Ra `{ok: true, cities: {[id]: {fetchedAt, stale, hours}}}`. Không inbox, không push, không `wakeClients`.
- Đo thật 2026-10-20 (1 lượt gọi Hà Nội): 200, `Expires` ≈ 30 phút sau, 36 giờ chuẩn hoá ≈ 2,3 KB/doc cache.

### Rules `couples/{coupleId}/weather/{uid}`

Theo phác §5.2, thêm một điều: `cityId` phải khớp `^[a-z]{2}-[a-z0-9-]{1,37}$` (dạng slug, tối đa 40 ký tự). Rules không giữ danh sách 116 id (ba bản phải đồng bộ thì dễ lệch hơn); id đúng dạng mà không có trong danh sách thì app coi như chưa chọn, CF từ chối. Đọc: thành viên. Ghi: thành viên, `hasOnly(cityId, setBy, updatedAt)`, `setBy == auth.uid`, `updatedAt == request.time`, và (doc của mình) hoặc (uid là thành viên VÀ doc chưa có hoặc `setBy != uid`). Xoá: chỉ doc của mình. `weatherCache` không có match ⇒ client bị chặn.

### Stage 2 (đã làm)

| Lớp | File | Ghi chú |
|---|---|---|
| Copy | `lib/l10n/app_{en,vi}.arb` (khối `weather*` cuối file, 86 key) | Theo design §10 + §14b. Nhãn làn "Bạn" dùng lại `sleepYou`. Tên "MET Norway" không dịch. |
| Thẻ Home | `lib/widgets/weather/weather_card.dart` (`WeatherCard`, `WeatherNudgeButton`, `WeatherStatusRow`, `WeatherPeople`, hàm chữ/icon `weatherConditionText` / `weatherSkyIcon` / `weatherCarePrefill` / `weatherCtaLabel`, `openWeatherCare`, `WeatherEvents`) | Thứ tự nhánh: chưa có snapshot → khung xương · chưa ai chọn → thẻ mời (khuôn Đêm qua, "Chọn thành phố" mở chuỗi 3 chạm khi đã ghép, "Ẩn") · đang tải lần đầu → khung xương · lỗi (>24 giờ / không có số) → nhãn + tên thành phố + "Chưa tải được thời tiết · Thử lại", chạm cả thẻ = thử lại · số cũ → chữ xám, header "Chưa cập nhật được", hàng dưới "⏱ Số liệu lúc hh:mm · Thử lại" · `compact` → 1 hàng (Home C §15) · còn lại hai làn Bạn trái / người ấy phải (`PersonLabel`, màu `PersonPalette` lấy từ `SleepProvider` như Đêm qua), dòng "TP.HCM · Chiều nay mưa", hàng chung nút (căn phải) / câu chênh / không. Cùng thành phố → 1 làn "Cả hai cùng ở …" (2 chấm chồng). `MidnightBuilder` tính lại câu lúc 0:00. `AnimatedSwitcher`/`AnimatedSize` 200 ms, Reduce Motion = 0. EN dùng `shortName` (HCMC). |
| Sheet | `lib/widgets/weather/weather_sheets.dart` (`showWeatherDetailSheet`, `showCityPickerSheet`, `CityPicker`, `MetCredit`, `WeatherSettingsSection`) | Chi tiết: khối Bạn trước, thước nhiệt chung hai nơi, "bây giờ hh:mm" khi múi giờ thành phố khác máy, nút gợi ý dưới thước ở khối người ấy (chỉ khi số tươi), 5 mốc 3 giờ theo giờ thành phố, Đổi thành phố / Đổi giúp / "Thảo tự chọn". Chọn: `DraggableScrollableSheet` 0.92, `ListView.builder`, nhóm Đang chọn / Việt Nam / Nước ngoài, "Tỉnh cũ: …", không tự bật bàn phím, nút xoá chữ chỉ khi đã gõ; chạm = haptic + ghi (không chờ) + đóng; chuỗi lần đầu chọn xong của mình thì hỏi "Còn Thảo đang ở đâu?" + "Để sau"; bị rules chặn → SnackBar "Thảo vừa tự chọn…". |
| Cài đặt | `settings_screen.dart` chèn 1 khối `WeatherSettingsSection` ngay sau nhóm Thông báo | Chỗ của bạn · Chỗ {tên} (bấm được khi còn chọn giúp được) · công tắc "Thời tiết chỗ người ấy" (07:30 cố định, không có hàng Giờ báo; chờ người ấy → khoá + "Ghép đôi xong mới báo được.") · xem trước thông báo mưa · dòng MET. Bật công tắc xin quyền thông báo như thẻ nhắc ăn gì. |
| Thông báo 07:30 | `reminder_service.dart` khối weather: id **1160**, `scheduleWeatherMorning` / `cancelWeatherMorning`, payload JSON; `initialize` thêm `onDidReceiveNotificationResponse` + `getNotificationAppLaunchDetails` (chạm khi app tắt) → `pendingWeatherTap` | Lập lịch ở `WeatherProvider._syncNotice` (sau mỗi lượt tải, snapshot, đổi tên/công tắc); luật thuần `weatherMorningPlan` + `weatherMorningLogAfter` trong `weather_logic.dart`: 07:30 kế tiếp giờ máy, dự báo ≤18 giờ tuổi lúc nổ, cửa sổ 07:30 → +14 giờ ở chỗ người ấy (giờ thành phố, DST từng giờ), trần 3 lần trong 7 ngày (6 ngày trước + hôm đó), không trùng loại hôm trước. Nhật ký ở Hive `app_settings/weather_notice_log` (ghi lúc arm; arm rồi bỏ thì xoá mục sáng sắp tới; mục đã qua giữ = đã nổ; tự dọn >14 ngày). Huỷ khi tắt, khi `clear()` (đăng xuất / không couple / rời), khi người ấy bỏ thành phố. Chạm → Home mở thẳng màn Quan tâm điền sẵn từ payload (quyết định 2 của Lead). |
| Home | `home_screen.dart` | Thẻ ở dòng đánh dấu (Selector `cardVisible`, `KeyedSubtree(_weatherKey)`, hiện cả khi chờ) · re-arm `watchForCouple` + `setPartnerName` + `refresh()` (đã chặn 30 phút) · `onResume()` · `pendingHomeFocus == 'weather'` cuộn tới thẻ · nghe `ReminderService.pendingWeatherTap`. |
| Prefs | `WeatherService.loadPrefs/savePref/saveNoticeLog` (Hive `app_settings`: `weather_card_hidden`, `weather_notice_enabled`, `weather_notice_log`) | Chọn thành phố thành công thì xoá cờ ẩn. |
| Analytics | gọi thẳng `AnalyticsService.logEvent` (không sửa `analytics_service.dart`) | `weather_city_set{who, region, entry}`, `weather_card_tap{state}`, `weather_cta_tap{condition, entry: card|notification}`, `weather_notif_toggle{enabled}`, `care_message_sent{source: weather}` (tham số sẵn có). |
| Phụ | `shimmer_skeleton.dart` | `enabled: !reduceMotion` (design §6 yêu cầu khung xương đứng yên khi Reduce Motion; áp cho mọi chỗ dùng). |

### Vá review backend stage 1 (Lead chuyển, 2026-10-20)

1. `deleteCoupleCompletely` thêm `recursiveDelete(couples/{id}/weather)` + test. **D18 trong spec giả định sai**: `notifyPartnerLeft` thoát sớm khi không còn ai nên thành phố người cuối không bao giờ bị xoá; Lead sửa spec.
2. `setCity` không giữ sheet: chờ tối đa 4 giây rồi coi là đã lưu (offline thì Firestore xếp hàng; rules từ chối sau đó thì snapshot đưa giá trị cũ về). Lỗi trả về trong 4 giây vẫn hoàn tác + `false` (SnackBar). Sheet vốn không `await`.
3. Lỗi callable → không tự gọi lại trong 3 phút (`retryAfterError`); "Thử lại" vẫn ép.
4. `refresh(force: true)` lúc đang chạy → ghi `_pendingForce`, chạy lại khi lượt hiện tại xong.
5. CF khoá mềm: lượt đầu sau hết hạn ghi `lockUntil = now + 60 s` trong transaction rồi mới gọi MET; lượt đến sau trong lúc khoá nhận bản cũ (`stale: false`, vì mới hết hạn chưa tới 1 phút).
6. `weatherConditionFor` nhận `offsetAt` (độ lệch theo từng giờ) — đêm đổi giờ London/Sydney không lệch 1 tiếng; provider truyền `cityUtcOffset(city, t)`; test DST London.
7. Cửa sổ nới sang 09:59 sáng mai khi còn **dưới 3 tiếng tính tới phút** (21:30 nới, 21:00 chưa); sửa test.
8. Test thêm: `getCityWeather` (chưa đăng nhập, id sai, 1 thành phố có số + 1 không, cả hai không → `unavailable`), `retryAt` hết tác dụng sau 1 lần thành công, MET 403/429, khoá mềm, dữ liệu chỉ bước 6 giờ; provider: 1/2 thành phố có số → `lastRefreshFailed`, lùi 3 phút sau lỗi, Thử lại lúc đang chạy.

### Vá review UI (Lead chuyển, 2026-10-20)

1. `cardVisible` chờ `_prefsLoaded` — người đã bấm "Ẩn" không thấy thẻ nháy 1 nhịp.
2. Chọn thành phố của mình mà ghi lỗi → SnackBar `weatherSaveFailed` ("Chưa lưu được, thử lại nhé."), không hoàn tác im lặng.
3. `_syncNotice` chạy tuần tự (chuỗi Future): lệnh đặt lịch chậm không thể tới sau lệnh huỷ mới hơn.
4. Giờ 07:30 ở Cài đặt (câu phụ + xem trước) dựng từ `kWeatherMorningHour/Minute`, định dạng theo locale (`weatherMorningTimeText`; en "7:30 AM").
5. **Chấp nhận (Lead):** thông báo sáng mặc định bật (D13) nhưng chỉ xin quyền khi gạt công tắc; người chưa cấp quyền thông báo không nhận gì mà nhật ký trần 3/7 vẫn đếm. Đa số đã cấp quyền push lúc onboarding.
6. Lỗi theo từng làn (Lead chốt A, xem "Lệch spec").
7. Feature tour build 33 (Lead chốt B): mục "Thời tiết hai nơi" trong `feature_tour_entries.dart`, chạm → `openWeatherFromTour` (chưa chọn gì thì mở sheet chọn — chuỗi 3 chạm nếu đã ghép; đã chọn thì mở sheet chi tiết).
8. Tự phát hiện khi viết test: `WeatherPeople.of` dùng `context.select` nhưng được gọi cả trong tap handler (mở sheet) → assert "select chỉ dùng trong build". Đổi sang `read`, thẻ tự `select` màu trong build. Có test chạm thẻ mở sheet.

## Edge case kỹ thuật đã xử lý

- Chọn giúp người ấy trong lúc người ấy vừa tự chọn: rules chặn → provider rollback, trả `false`.
- Hai người cùng thành phố: 1 id trong lượt gọi.
- Thành phố được chọn lúc đang có lượt gọi khác chạy: gọi tiếp ngay sau.
- Đổi couple / đăng xuất giữa lúc chờ callable: kết quả muộn bị bỏ (`_session`).
- App cũ hơn không biết id mới (bản sau thêm thành phố): `myCity == null`, không gọi CF với id lạ.
- Doc của người cũ còn sót trong couple đang chờ: provider chỉ đọc doc của mình khi `partnerUid` rỗng.
- Giờ theo đồng hồ thành phố (Seoul +9, có DST cho Úc/Âu/Mỹ), không theo máy.
- Ô tìm: chuỗi có dấu dạng tổ hợp (một số bàn phím Android) vẫn bỏ dấu đúng.

## Lệch spec / brief (có chủ ý)

Stage 2 (UI tự quyết khi spec chưa vẽ, có tra UI UX Pro Max `"partial data error state retry" --domain ux`):

- **Lỗi theo từng làn** (Lead chốt 2026-10-20, thay bản "nơi tệ nhất"): làn không có số hiện tên thành phố + "Chưa tải được" + Thử lại, làn kia vẫn hiện số, dòng "Cập nhật" lấy theo làn còn số; chỉ khi mọi nơi đều hỏng mới vào trạng thái lỗi cả thẻ. Có làn lỗi thì không thu 1 hàng. Hợp luật UI UX Pro Max "Error Placement" (báo lỗi ngay chỗ hỏng) + "Error Messages" (câu lỗi `liveRegion`).
- **Nhãn làn**: theo Home C §15 (`PersonLabel` IN HOA 11) thay cho `_LaneLabel` chữ thường của weather §4.1; tên thành phố chuyển xuống dòng câu tình trạng ("TP.HCM · Chiều nay mưa") như mock `weatherCardC`.
- **Thẻ ẩn ("Ẩn") ẩn hẳn** cho tới khi chọn thành phố thành công (kể cả từ Cài đặt). Người ấy chọn giúp mình thì cờ ẩn của máy mình không đổi.
- **Thẻ không hiện khi không có Firebase** (chế độ local không có thành phố / dự báo).
- **`weather_cta_tap.entry`**: nút trong sheet chi tiết ghi `card` (spec chỉ có `card|notification`).
- **Bỏ qua khi chạm thông báo mà payload hỏng / thành phố lạ** → cuộn tới thẻ thay vì mở Quan tâm.

Stage 1:

1. **CF không kiểm thành viên couple** (brief ghi "kiểm auth + thành viên"; overview §5.3 ghi rõ "không cần là thành viên couple vì chỉ trả dữ liệu công khai theo thành phố"). Theo spec; đầu vào cũng không có `coupleId`.
2. **`retryAt` 10 phút** sau khi MET lỗi (spec không có): chống gọi MET liên tục khi MET sập.
3. **Một thành phố lỗi không có cache** → bỏ khỏi `cities` thay vì làm hỏng cả lượt; chỉ khi cả hai đều không có mới `unavailable`.
4. **Rules chặn `cityId` sai dạng** (thêm vào phác §5.2), không chặn id đúng dạng mà không có trong danh sách.
5. **304 không đổi `fetchedAt`** (đúng chữ spec "chỉ dời `expiresAt`"). Hệ quả: dòng "Cập nhật hh:mm" là giờ MET đổi số gần nhất. Thực tế MET đổi `Last-Modified` gần như mỗi giờ nên không chạm mốc 6 giờ.
6. **User-Agent chỉ có website** (Lead 2026-10-20: MET chấp nhận website làm thông tin liên hệ, không gửi email ra ngoài).

## Việc mở

- **Spike D3 (độ đúng MET 5 ngày, Hà Nội / TP.HCM / Đà Nẵng) CHƯA LÀM** — cần 5 ngày liên tiếp so "chiều nay mưa?" với thực tế. Theo overview §9 phải có kết quả và PO duyệt trước khi làm UI. Gợi ý cách chạy: mỗi sáng 08:00 gọi `/compact` cho 3 toạ độ trong `weather_cities.json`, ghi `weatherConditionFor` ra bảng, tối đối chiếu bản tin. Không đạt → đổi phần `fetch` trong `getWeatherForCity` sang WeatherKit REST (giữ nguyên hợp đồng callable).
- Chưa test trên máy: chữ 200% thật, VoiceOver/TalkBack, thông báo 07:30 thật nổ + chạm khi app tắt (iOS/Android), offline chọn thành phố (4 giây).
- Có sẵn từ trước (không thuộc feature): `ReminderService.initialize` chạy SAU `PushNotificationService.initialize` và plugin chỉ giữ callback của lần `initialize` cuối ⇒ chạm banner push hiện lúc app đang mở chưa từng điều hướng. Nay callback là của weather (chỉ xử lý payload `weather_morning`), hành vi push cũ không đổi. Muốn sửa: gộp hai callback.
- Chưa thêm thẻ "Có gì mới" (`feature_tour_entries.dart`) — chờ Lead/PO chốt copy.

## Kế hoạch stage 2 (UI + thông báo + analytics)

1. **ARB** (khối key `weather*` liền nhau trước `}` cuối cả 2 file, rồi `flutter gen-l10n`): copy deck design §10 + bản sửa §14b (nhãn "Bạn", nút "Nhắc {name} mang ô/uống nước/mặc ấm", thẻ mời kiểu Đêm qua, "Chưa cập nhật được"…) + câu tình trạng §6.2 + mô tả trời §6.3 + lời điền sẵn §6.6 + thông báo §6.7 + "Từ giờ tới khuya". Hàm map `WeatherConditionKind`/`WeatherSky`/`WeatherCta` → chuỗi đặt cạnh widget.
2. **`lib/widgets/weather/weather_card.dart`**: `WeatherCard` đọc `WeatherProvider`; nhánh: `!choicesLoaded`/`isLoadingFirst` → skeleton; `nothingPicked` → thẻ mời (khuôn `_SetupPitch` của Đêm qua + nút "Chọn thành phố" + "Ẩn", cờ Hive `app_settings`/`weather_card_hidden`='true'); `compact` → 1 hàng 76 px; còn lại 2 làn (Bạn trái · người ấy phải, `PersonLabel`, màu `PersonPalette` như SleepCard) + `sharedRow` (cta căn phải dưới cột người ấy / câu chênh lệch / không gì). Số cũ (`stale`) → chữ `textSecondary` + "Số liệu lúc" + Thử lại (`refresh(force: true)`); `none` → "Chưa tải được thời tiết · Thử lại". Câu tình trạng tự tính lại lúc 0:00 (`MidnightBuilder`). Tên làn dùng `city.shortName(lang)`.
3. **Home**: chèn `KeyedSubtree(key: _weatherKey, child: WeatherCard())` ở dòng đánh dấu `// ── Đợt 2 (Home C): WeatherCard …` (hiện cả khi đang chờ); re-arm `watchForCouple(couple.id, myUid, partnerUid)` trong khối re-arm; gọi `refresh()` khi vào Home + `onResume()` trong lifecycle; `pendingHomeFocus == 'weather'` cuộn tới thẻ.
4. **`lib/widgets/weather/weather_sheets.dart`**: `showWeatherDetailSheet` (khối Bạn trước, thước nhiệt chung `_TempScale`, 5 mốc 3 giờ `_HourSlots` theo giờ thành phố, "bây giờ hh:mm" khi khác múi giờ, nút "Đổi thành phố"/"Đổi giúp"/"Thảo tự chọn", nút gợi ý trong khối người ấy, `MetCredit` link `https://api.met.no/doc/License`) · `showCityPickerSheet(forPartner:)` (`DraggableScrollableSheet` 0.92, `searchWeatherCities`, nhóm Đang chọn / Việt Nam / Nước ngoài, dòng "Tỉnh cũ: …" khi `via != null`, chọn = haptic + `setMyCity/setPartnerCity` không await để đóng ngay, `false` → SnackBar; lần đầu chọn xong của mình thì hỏi tiếp "Còn {name} đang ở đâu?" + "Để sau" — `picker-chain.html`).
5. **`openCareMessageScreen(context, {initialTitle, initialBody})`** (2 tham số tuỳ chọn, mặc định như cũ) + `care_message_sent{source}`.
6. **Cài đặt**: section "Thời tiết hai nơi" (Chỗ của bạn · Chỗ {name} · công tắc thông báo sáng + xem trước, 07:30 cố định, không có hàng "Giờ báo"); chọn từ Cài đặt thì xoá cờ ẩn.
7. **Thông báo sáng id 1160** (`ReminderService`, dải 1160–1179 — Lead đối chiếu feature khác): arm one-shot 07:30 giờ máy khi app mở, chỉ khi cặp active + có thành phố người ấy + dự báo `fetchedAt` ≤ 18 giờ trước giờ nổ + cửa sổ 07:30 → +14 giờ ở chỗ người ấy có mưa/nắng gắt/lạnh (dùng lại `weatherConditionFor` với `now` = 07:30 hôm đó); trần 3 lần/7 ngày + không trùng tình trạng 2 ngày liền (Hive, hàm thuần + test); huỷ khi tắt / đăng xuất / rời couple (`cancelDailyQuestionSchedule()`) / người ấy bỏ thành phố. Chạm → mở thẳng màn Quan tâm điền sẵn (quyết định 2 của Lead, thay "về Home cuộn tới thẻ").
8. **Analytics** §8 (`weather_city_set`, `weather_card_tap`, `weather_cta_tap`, `weather_notif_toggle`).
9. Test widget cho thẻ (các trạng thái chính) + test trần thông báo; analyze 0.

## Checklist implement

- [x] Danh sách thành phố Dart + JSON + test so khớp
- [x] Tìm không dấu / viết liền / viết tắt + test
- [x] CF `getCityWeather` + cache + 304 + backoff + test node
- [x] `notifyPartnerLeft` xoá `weather/{người rời}`
- [x] Rules + 17 rules-test
- [x] `WeatherService` + `WeatherProvider` + wire `main.dart` / `session_resolver.dart` + test
- [x] Hàm thuần tình trạng / độ tươi / hàng chung / thẻ gọn + test
- [ ] Spike D3
- [x] Stage 2 (mục trên)
- [x] `flutter analyze` sạch
- [x] Không hardcode chuỗi (trừ "MET Norway" — tên riêng — và giờ "07:30" trong xem trước)

## Nhật ký implement

- [2026-10-20] [Dev] Stage 1: danh sách 116 thành phố (`lib/data/weather_cities.dart` + `functions/weather_cities.json`), model `lib/models/weather.dart`, logic thuần `lib/utils/weather_logic.dart`, `WeatherService` (callable + Hive `weather_cache`), `WeatherProvider` (wire `main.dart` + `session_resolver.dart`), CF `getCityWeather` + xoá trong `notifyPartnerLeft`, rules `weather/{uid}`. Test: Dart +46 (`weather_logic_test.dart` 38, `weather_provider_test.dart` 8) → `flutter test` 684 pass; functions `npm test` 36 pass (`weather.test.js` 15 mới); rules-test 411 pass (`firestore.weather.test.js` 17 mới). `flutter analyze` 0. Chưa deploy. Spike D3 chưa làm.
- [2026-10-20] [Dev] Vá 8 finding review backend (xem mục "Vá review backend stage 1"). functions `npm test` 46 pass; rules-test 411 pass.
- [2026-10-20] [Dev] Stage 2: ARB 86 key `weather*`, `weather_card.dart` + `weather_sheets.dart`, thẻ ở Home (+ re-arm, resume, focus `weather`, chạm thông báo → Quan tâm điền sẵn), mục Cài đặt, thông báo 07:30 id 1160 (trần 3/7, không trùng loại 2 ngày liền), analytics 4 event. Test mới: `weather_card_test.dart` 11 (thẻ 8 trạng thái + 320 dp chữ 200% + picker tìm không dấu + chuỗi 3 chạm), `weather_morning_test.dart` 10 (lịch + trần + nhật ký + lời điền sẵn), provider +3 (thông báo, ẩn thẻ). `flutter test` 714 pass, `flutter analyze` 0. Chưa deploy.
- [2026-10-20] [Dev] Vá review UI 1–5 + Lead chốt A (lỗi theo làn) + B (feature tour build 33, key `weatherFeatureTourTitle/Body`), key mới `weatherSaveFailed`, `weatherLaneFailed`; sửa `select` ngoài build. Test +7 (làn lỗi, chạm mở sheet, SnackBar tự chọn lỗi, prefs chưa nạp, thứ tự huỷ/đặt lịch, giờ theo locale, mục tour). `flutter test` 721 pass, analyze 0.
- [2026-10-22] [Dev] Vá 5 lỗi Low của Tester: (1) `weatherSharedRow` — số của mình cũ không còn ẩn nút nhắc, chỉ ẩn gap (+test, sửa test cũ "stale numbers"); (2) `WeatherProvider.clear(signedOut)` xoá `weather_notice_log` (+test); (3) `weather_city_set` chỉ log khi ghi thành công; (4) copy `weatherCareUmbrellaBody` VI/EN dùng được cả "đang mưa" lẫn "sắp mưa" (+sửa expect ở `weather_morning_test`); (5) `push_notification_service.dart` huỷ thông báo 1160 khi nhận push `partner_left` (background + foreground). Hạn chế: background chỉ chạy nếu CF `notifyPartnerLeft` gửi kèm wake (chưa kiểm/đổi); không thì `clear()` huỷ ở lần mở app sau. Nợ giữ nguyên (bỏ qua theo brief): getCityWeather App Check, MidnightBuilder theo giờ, Hive nobackup, spike D3.
