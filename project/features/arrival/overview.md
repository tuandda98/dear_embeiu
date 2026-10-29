# Về đến nhà chưa? — báo người ấy khi mình đến nơi

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Đợt "mở app mỗi ngày" lần 2 (user chọn 2026-10-20, làm cùng `poke`, `caro-game`, `weather`, `expenses`). Widget hiện trạng thái qua [widget-today](../widget-today/overview.md). Mô hình chia sẻ học theo [sleep](../sleep/dev.md) (cờ `share`, rules chặn đọc khi tắt, dọn khi rời couple).

- **Feature:** arrival
- **Ưu tiên:** P1 (đợt 2; rủi ro duyệt store cao nhất đợt — phát hành chung một bản theo lựa chọn của user, kế hoạch B ở D13)
- **Trạng thái:** 📋 Spec — chờ user duyệt + trả lời §11
- **Tạo ngày:** 2026-10-20
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · [`../widget-today/`](../widget-today/overview.md) · [`../sleep/`](../sleep/dev.md) · [`../care-message/`](../care-message/overview.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:* 22:40, Thảo tan ca, chạy xe 25 phút về nhà. Tuấn nhắn "về tới nhà chưa?" rồi ngồi chờ. Thảo đang lái, không trả lời được. Về tới nơi thì quên nhắn. Tuấn gọi lần hai, hơi bực. Chuyện này lặp lại vài lần một tuần ở mọi cặp đi làm, đi học xa nhau. Thứ cả hai cần chỉ là một dòng "về rồi", không phải bản đồ.
- *Giả thuyết giá trị:* máy Thảo tự nhận ra đã về Nhà và báo Tuấn: "Thảo đã về đến nhà". Tuấn yên tâm, mở app thấy thêm "pin còn 12%" thì biết vì sao Thảo chưa nhắn. Khác với câu hỏi hằng ngày (phải viết) hay chọc (phải nhớ bấm), báo về nhà **không cần ai làm gì**: chỉ cần đi về là người kia nhận được tin. Mỗi ngày có 1–3 sự kiện tự nhiên, mỗi sự kiện là một lý do mở app và gửi lại một câu.
- *Số liệu nền (PROD 2026-10-19, `scripts/prod-retention-stats.js`):* 80 cặp, 28 đã ghép, 52 còn chờ người ấy. Mỗi ngày 7–16 cặp mở app, 3–5 cặp cả hai trả lời câu hỏi, 8 cặp cả hai mở app mà không ai trả lời. Nghĩa là nhiều cặp vẫn mở app nhưng ngại viết. Báo về nhà là tín hiệu không cần viết gì.
- *Đối tượng:* cặp **đã ghép đôi** (D9). Cặp còn chờ người ấy không thấy feature.
- *Đo bằng gì:* §9.

## 2. Bối cảnh / nghiên cứu

### Đối thủ và tiền lệ
- Zenly (đóng cửa 3/2/2023) từng tự hiện bạn bè "đang ở nhà / ở trường / ở chỗ làm", hiện pin trên bản đồ và báo khi bạn sắp hết pin. Người dùng VN Gen Z dùng Zenly rất nhiều, nên "báo về nhà" là hành vi quen. Nguồn: [PhoneArena](https://www.phonearena.com/news/Zenly-is-a-live-location-tracking-app-with-a-lovely-interface-and-lots-of-features_id81546), [Malay Mail 2019](https://www.malaymail.com/news/world/2019/03/04/app-popular-among-singapore-school-children-raises-parents-concern-over-loc/1728722), [AlternativeTo](https://alternativeto.net/software/zenly/about).
- Penlo, MixerBox BFF (đang trên App Store) quảng cáo đúng tính năng "báo khi bạn bè đến / rời địa điểm". Nguồn: [Penlo](https://apps.apple.com/app/id6443518385), [MixerBox BFF](https://apps.apple.com/app/id6443790994).
- Chỗ khác của mình: **không bản đồ, không toạ độ trên máy chủ, không lịch sử đường đi**. Chỉ một dòng "đã về đến nhà". Chọn hẹp có chủ đích để không biến app cặp đôi thành công cụ theo dõi nhau (D3, D10, D11).

### Chính sách store (kiểm 2026-10-20)
- **Google Play, quyền vị trí nền** ([Play Console Help 9799150](https://support.google.com/googleplay/android-developer/answer/9799150?hl=en), [Prominent disclosure 10144311](https://support.google.com/googleplay/android-developer/answer/10144311)):
  - Chỉ được xin khi là **chức năng cốt lõi** (app hỏng hoặc vô dụng nếu thiếu). Lợi ích "đáng kể" gồm an toàn thân thể và *cảm giác an toàn*; "tối thiểu" gồm tiện lợi, giải trí. Ví dụ duy nhất về geofence trong trang là cảnh báo khi trẻ rời vùng an toàn, được xếp vào nhóm *cảm giác an toàn*.
  - Phải có: form khai báo (App content → Sensitive app permissions → Location permissions), **chỉ khai MỘT tính năng** dùng vị trí nền (khai nhiều sẽ bị từ chối), video ≤30 giây quay app Android cho thấy hộp giải thích → hộp xin quyền → tính năng chạy khi app đóng, hộp giải thích nổi bật (prominent disclosure) hiện **trước** hộp xin quyền với chữ "vị trí" + cụm "kể cả khi app đã đóng hoặc không dùng", privacy policy (URL web, không PDF) có mục vị trí riêng.
  - Không được duyệt thì bản cập nhật bị chặn, có thể bị gỡ app.
  - Từ Android 11, hệ thống bỏ qua yêu cầu gộp quyền trước + nền; phải xin "khi dùng app" trước, sau đó đưa người dùng vào Cài đặt chọn "Cho phép mọi lúc" ([developer.android.com](https://developer.android.com/develop/sensors-and-location/location/permissions/background)).
  - **Đánh giá rủi ro:** app cặp đôi không có vị trí là chức năng chính. Trung bình–cao. Cách khai có cơ hội nhất: "báo người thân rằng bạn đã về đến nơi an toàn", đưa vào mô tả store như tính năng cốt lõi. Kế hoạch khi bị từ chối: D13.
- **App Store** ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)):
  - 5.1.5: chỉ dùng vị trí khi liên quan trực tiếp tới tính năng, phải báo và xin đồng ý trước khi thu thập, truyền đi.
  - 5.1.1(ii): câu xin quyền (purpose string) phải nói rõ và đủ cách dùng dữ liệu; có cách rút lại đồng ý dễ tìm.
  - 5.1.1(iv): tôn trọng lựa chọn quyền, có phương án khác khi người dùng từ chối. Nút "Về nhà rồi" bấm tay (D7) chính là phương án này.
  - 5.1.2(i): không được bắt bật dịch vụ vị trí để dùng app.
  - 2.5.14: ghi lại hoạt động người dùng phải có đồng ý rõ ràng và có dấu hiệu nhìn thấy được.
  - Kinh nghiệm từ dev khác: xin "Luôn luôn" bị soi kỹ hơn "Khi dùng app", app không chạy được khi tắt vị trí thì bị từ chối theo 5.1.5 ([forum 704032](https://developer.apple.com/forums/thread/704032), [forum 112545](https://developer.apple.com/forums/thread/112545)). Đánh giá rủi ro iOS: thấp–trung bình (Find My, Life360, Penlo đều đang có).
- **Khai báo dữ liệu:**
  - Play Data safety: dữ liệu gửi cho người khác do chính người dùng chủ động bật thì không tính là "chia sẻ" ([Help 10787469](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en), [Help 11416267](https://support.google.com/googleplay/answer/11416267?hl=en)). Mình vẫn phải khai **Vị trí → Vị trí gần đúng: có thu thập, tuỳ chọn, mục đích chức năng app** (sự kiện "đã về Nhà" là vị trí suy ra). Toạ độ chính xác chỉ xử lý trên máy, không rời máy, nên không tính là thu thập. Tuy vậy Android bắt `ACCESS_FINE_LOCATION` cho geofence, nên PO chọn khai thận trọng: khai cả "Vị trí chính xác: không thu thập" giữ nguyên, thêm "Vị trí gần đúng: có".
  - App Store Connect App Privacy: thêm **Location → Coarse Location**, liên kết với người dùng, mục đích App Functionality, không dùng để theo dõi (tracking).
  - `docs/privacy-policy.html` hiện ghi "Vị trí chính xác: Không" ở bảng dữ liệu (dòng ~294). Phải sửa bảng + thêm mục riêng về vị trí trước khi nộp. Trang host trên GitHub Pages, nhánh `phase3` (CLAUDE.md §5), nên commit sửa phải lên `phase3`.

### Tìm địa chỉ cho dữ liệu Việt Nam (nghiên cứu 2026-10-20, theo yêu cầu user "cho nhập địa chỉ")

| Cách | Gợi ý khi đang gõ | Dữ liệu VN, 34 tỉnh mới | Chi phí 165 user | Chi phí 10.000 user | Key |
|---|---|---|---|---|---|
| **Geocoder của hệ điều hành** — iOS `MKLocalSearchCompleter` + `MKLocalSearch`; Android `android.location.Geocoder` | iOS: có. Android: không (chỉ trả ≤5 kết quả cho một chuỗi) | Apple Maps tìm được cả tên cũ lẫn tên mới từ 5/2026 ([Tuổi Trẻ](https://tuoitre.vn/apple-maps-ho-tro-tim-kiem-bang-ca-ten-dia-phuong-cu-va-moi-tai-viet-nam-20260514105840129.htm)); Android dùng dữ liệu Google, Google Maps cập nhật ranh giới mới từ 3/2026, TP.HCM/Đà Nẵng/Hải Phòng còn chỗ hiện tên cũ ([Dân trí](https://dtinews.dantri.com.vn/vietnam-today/google-maps-updates-vietnams-administrative-boundaries-after-mergers-20260318154256239.htm), [Phong Vũ](https://phongvu.vn/cong-nghe/google-maps-cap-nhat-ban-do-cap-xa-phuong/)) | 0 USD | 0 USD | Không cần |
| Google Places Autocomplete (New) | Có | Tốt nhất | ~0 (10.000 lượt gợi ý/tháng miễn phí) | ~100 USD tháng đầu nếu 30% bật (45.000 lượt, sau ngưỡng 2,83 USD/1.000; Place Details 5 USD/1.000 sau 10.000) ([Google](https://developers.google.com/places/web-service/usage?hl=en), [Woosmap 2026](https://www.woosmap.com/blog/google-maps-api-pricing-breakdown)) | Có, phải giấu sau CF proxy + bật billing Maps |
| Goong.io | Có | Dữ liệu VN | ~1 USD | ~65 USD tháng đầu (1,40 USD/1.000 lượt gợi ý, **không có credit miễn phí**) ([Goong pricing](https://goong.io/pricing-plans/)) | Có, phải giấu sau CF proxy |
| OSM Nominatim (máy chủ công cộng) | **Cấm** gợi ý khi gõ | Dữ liệu VN mỏng | 0 USD | Không dùng được: tối đa 1 lượt/giây cho cả app | Không ([chính sách](https://operations.osmfoundation.org/policies/nominatim/)) |

Ước lượng lượt gọi: mỗi người bật lưu ~1,5 nơi × ~10 lượt gợi ý = ~15 lượt, chỉ tốn lúc thiết lập. 30% của 165 user ≈ 750 lượt; 30% của 10.000 ≈ 45.000 lượt.

**Chọn: geocoder của hệ điều hành (D20).** Miễn phí ở mọi quy mô, không key, không thêm tài khoản thanh toán (bài học sự cố billing 09-2026). Android không gợi ý theo từng chữ được: tìm khi ngừng gõ 800 ms hoặc bấm Tìm, hiện ≤5 kết quả. Apple có giới hạn tần suất không công bố (`MKError.loadingThrottled`), nên debounce 300 ms. Goong là dự phòng ở Phase 2 nếu spike đo thấy geocoder hệ điều hành sai nhiều (§6 mục 8).

**Bản đồ xác nhận:** v1 không có bản đồ (D21). Nếu làm ở Phase 2: iOS dùng MapKit (ảnh chụp bản đồ `MKMapSnapshotter`, miễn phí, không key); Android dùng Maps SDK for Android (tải bản đồ trên điện thoại miễn phí, không giới hạn, [Google](https://developers.google.com/maps/documentation/android-sdk/usage-and-billing)) nhưng cần API key nằm trong app (giới hạn theo package + SHA-1) và thêm `google_maps_flutter`.

### Kỹ thuật (GIẢ ĐỊNH, Dev spike trước khi làm, §6)
- Plugin: [`native_geofence`](https://pub.dev/packages/native_geofence) 1.3.1, MIT, iOS 14+/Android API 23+, dùng `CLLocationManager` (iOS) và `GeofencingClient` (Android), tự đăng ký lại sau khi khởi động lại máy, callback top-level chạy cả khi app đã tắt. Cảnh báo của chính plugin: iOS sau reboot có thể bắn sự kiện đầu 2 lần; Android emulator không bắn nếu không có app khác đang dùng vị trí; gọi mạng trong callback có thể cần tắt tối ưu pin. Dự phòng: [`flutter_background_geofencing`](https://pub-web-s1.flutter-io.cn/packages/flutter_background_geofencing/changelog) (MIT, ít người dùng). **Không** dùng `flutter_background_geolocation` (Transistor, license trả phí cho Android release).
- iOS giới hạn 20 vùng/app ([sjitech](https://github.com/sjitech/ios_monitor_location_region_in_background)); mình dùng tối đa 5. App bị hệ thống tắt vẫn được đánh thức khi vào/ra vùng; **app bị người dùng vuốt tắt thì không chắc**. Có báo cáo iOS 26.4 không còn đánh thức app đã bị vuốt tắt cả với significant-location, người hỏi nghi ngờ áp cho cả region ([forum 826964](https://developer.apple.com/forums/thread/826964)). Sự kiện có thể trễ tới ~4 phút ([capgo](https://capgo.app/blog/capacitor-geofences-not-triggering-ios/)).
- Android: geofence do Google Play services theo dõi, phát hiện ổn. Rủi ro nằm ở bước giao sự kiện cho app trên Xiaomi/Oppo/Vivo (chặn tự khởi động) và máy không có Google Play services (Huawei đời mới) → chỉ còn chế độ tay.

## 3. Phạm vi (scope)

- **Trong phạm vi (v1):**
  - Tối đa **5 nơi** mỗi người. **Nhà** luôn có sẵn (không xoá, không đổi tên, có thể chưa có vị trí); thêm tới 4 nơi tự đặt tên ("Nhà mẹ", "Công ty", "Phòng gym"…) và chọn biểu tượng.
  - Đặt nơi bằng **địa chỉ** (ô tìm, gợi ý, chọn) qua geocoder của hệ điều hành. Không tìm thấy thì **dùng vị trí hiện tại** lúc đang đứng ở đó. Không bản đồ.
  - **Tự động:** geofence do hệ điều hành theo dõi, bán kính theo nguồn (150 m với vị trí hiện tại, 250 m với địa chỉ). Sự kiện đến / rời + giờ + % pin lúc đó.
  - **Bấm tay:** nút "Về nhà rồi" trên thẻ Home + "Đến nơi rồi" chọn trong các nơi đã tạo. Không cần quyền vị trí.
  - **Chia sẻ opt-in từng người**, tắt là xoá trạng thái trên máy chủ.
  - Push "đã đến nơi" cho người ấy (chỉ sự kiện ĐẾN), loại trạng thái widget-today mới, thẻ trên Home.
  - Rules additive, 1 CF mới, sửa CF dọn dữ liệu, `config/app` thêm cờ tắt từ xa.
- **Ngoài phạm vi (ghi roadmap):** bản đồ trực tiếp · toạ độ/đường đi trên máy chủ · lịch sử sự kiện · push "pin sắp hết" riêng (D5) · quá 5 nơi · bản đồ xác nhận vị trí / kéo ghim (Phase 2) · đổi bán kính bằng tay · dịch vụ tìm địa chỉ trả phí (Goong/Google, chỉ khi spike cho thấy cần) · "đang trên đường về" + ước lượng giờ đến · tạm ẩn 1 giờ (ghost mode) · địa điểm dùng chung của cặp ("Nhà chúng mình") · nhắc "về nhà rồi mà chưa báo" · Apple Watch / Wear OS.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý. Mục *(PO tự chốt)* user lật được trước khi Dev bắt đầu.

- **D1 — Geofence của hệ điều hành, tối đa 5 nơi, bán kính theo nguồn: 150 m (vị trí hiện tại) · 250 m (địa chỉ).** Không theo dõi vị trí liên tục, không foreground service. ⟪Cập nhật 2026-10-20 theo user: bỏ 3 loại cố định Nhà/Chỗ làm/Trường và bán kính 150 m chung (từng chốt ở log Lead cùng ngày).⟫ *Lý do:* geofence gần như không tốn pin; 5 vùng còn xa trần 20 của iOS và chừa chỗ nếu feature khác cần region. 5 nơi đủ cho Nhà, nhà bố mẹ, công ty, trường, phòng gym; nhiều hơn thì push dày và giống lộ trình hơn là "về đến nơi". Toạ độ từ địa chỉ VN hay lệch về giữa đường hoặc giữa phường, nên rộng hơn (250 m) để vẫn bắt được; vị trí hiện tại chuẩn hơn nên giữ 150 m. Không cho chỉnh bán kính tay ở v1 (thêm một lựa chọn khó hiểu). Không foreground service vì Android 14 bắt khai thêm loại `location`, thêm một vòng duyệt. Dev chỉnh 2 con số trong 100–400 m sau spike, ghi số đo vào `dev.md`.

- **D2 — Địa chỉ và toạ độ CHỈ nằm trên máy**, trong Hive box `arrival_nobackup` (thư mục loại khỏi iCloud/Google backup, như `sleep_nobackup`). Firestore chỉ biết **tên nơi + biểu tượng của sự kiện mới nhất** (D3), không danh sách nơi, không địa chỉ. Đổi máy → đặt lại. Chuỗi địa chỉ người dùng gõ được gửi tới dịch vụ bản đồ của Apple (iPhone) hoặc Google (Android) để tìm toạ độ, không qua máy chủ của mình; ghi rõ trong privacy policy (D22). *Lý do:* người ấy không cần biết địa chỉ nhà mình để biết mình đã về; máy chủ không giữ thì không lộ khi rò rỉ, khi chia tay, khi bị ép đưa máy. Không đẩy danh sách nơi lên máy chủ vì người ấy không cần biết mình đặt báo cho những chỗ nào, chỉ cần biết khi mình đến.

- **D3 — Không lịch sử: máy chủ chỉ giữ MỘT sự kiện mới nhất mỗi người** (ghi đè). *Lý do:* lịch sử đến/rời theo ngày là lộ trình đi lại, chính là thứ biến tính năng an tâm thành công cụ kiểm soát. Một dòng "đã về nhà 22:58" là đủ cho đúng nhu cầu ở §1. Bớt luôn một subcollection, bớt TTL, bớt màn lịch sử.

- **D4 — Push chỉ khi ĐẾN nơi** (Nhà và mọi nơi tự đặt; tự động lẫn bấm tay). Sự kiện RỜI chỉ hiện trên thẻ Home khi người ấy mở app, không push, không lên widget. *(PO tự chốt.)* *Lý do:* "đã về đến nhà" là tin làm yên tâm; "đã rời nhà" lúc 7:40 sáng thì vô ích và dễ thành canh chừng. Trung bình 1–3 push/ngày/người, trong ngân sách đánh thức nền của iOS.

- **D5 — Pin: chỉ kèm theo sự kiện, KHÔNG có push "pin sắp hết" riêng ở v1.** Push đến nơi có thêm dòng "Pin còn 8%" khi pin ≤ 20%; thẻ Home luôn hiện % pin của sự kiện. *Lý do:* (1) iOS không cho app tự chạy khi pin xuống thấp; Android từ 8.0 không cho đăng ký nhận `ACTION_BATTERY_LOW` trong manifest, muốn bắt phải có dịch vụ chạy nền liên tục; (2) Zenly làm được nhờ theo dõi vị trí liên tục, mình đã chọn không làm vậy (D1); (3) "pin Thảo còn 8%" bắn bất chợt dễ thành lý do gọi dồn. Kèm theo sự kiện đến nơi là lúc thông tin pin có ích nhất ("về rồi, pin yếu nên chưa nhắn").

- **D6 — Chống báo sai ở rìa vùng**, làm ở 2 tầng:
  - *Máy người gửi:* lưu trạng thái cuối của từng địa điểm trong Hive. Bỏ qua sự kiện trùng trạng thái (đang "trong Nhà" mà nhận thêm "đến Nhà" — gặp khi iOS reboot bắn 2 lần). Sự kiện "đến" xảy ra trong vòng 10 phút sau "rời" cùng địa điểm thì chỉ cập nhật trạng thái, đánh dấu `bounce: true`, CF không push. Android dùng thêm `loiteringDelay` 2 phút (chuyển trạng thái DWELL) nếu plugin hỗ trợ.
  - *CF:* cùng người, cùng địa điểm, đã push trong 30 phút → không push nữa. Tối đa 6 push arrival/người gửi/ngày. Sự kiện cũ hơn 30 phút (ghi từ hàng đợi offline) → chỉ cập nhật thẻ, không push.
  *Lý do:* đi đổ rác, xuống sảnh lấy đồ là ra vào rìa vùng, không ai muốn người ấy nhận "đã về đến nhà" 3 lần một tối.

- **D7 — Nút bấm tay luôn có, kể cả khi đã bật tự động.** Trên thẻ Home: nút chính **"Về nhà rồi"** + nút phụ **"Đến nơi rồi"** mở danh sách các nơi đã tạo (chỉ hiện khi có ≥1 nơi ngoài Nhà). Bấm = ghi sự kiện `source: manual`, push y như tự động. Không cần quyền vị trí, không cần nơi đó có vị trí (chưa đặt địa chỉ Nhà vẫn bấm "Về nhà rồi" được; nơi tự đặt tên có thể tạo chỉ để bấm tay). *Lý do:* phương án thay thế mà Apple 5.1.1(iv) yêu cầu; chạy được cả khi Play từ chối (kế hoạch B D13), trên máy Huawei không có Google Play services, hoặc khi người dùng không muốn cấp "Luôn luôn". Một nút chính "Về nhà rồi" đúng lời user: "mặc định để về nhà".

- **D8 — Quy trình xin quyền theo bậc, dừng ở bậc nào cũng dùng được.** ⟪Viết lại 2026-10-20: lưu nơi bằng địa chỉ thì không cần quyền.⟫
  0. **Không cần quyền:** tạo nơi, đặt tên, tìm địa chỉ, lưu; bấm tay.
  1. **Dự phòng khi không tìm thấy địa chỉ:** nút "Không thấy địa chỉ? Dùng vị trí hiện tại" (kèm câu "Hãy bấm khi bạn đang đứng ở đó") → câu giải thích ngắn → xin vị trí **khi dùng app** + **chính xác** → đọc 1 lần → màn xác nhận (D21) → lưu. Từ chối → quay lại ô địa chỉ, không hỏi lại tự động.
  2. **Bật "Tự báo khi mình đến nơi"** (cần ≥1 nơi có vị trí; chưa có thì mở luồng thêm Nhà) → màn giải thích nổi bật (prominent disclosure, D12) → xin vị trí **khi dùng app** + **chính xác** nếu chưa có.
  3. Màn giải thích thứ hai → iOS `requestAlwaysAuthorization`; Android mở trang quyền của app, chỉ chữ lấy từ `getBackgroundPermissionOptionLabel()` ("Cho phép mọi lúc").
  4. Không cấp "Luôn luôn" / chỉ cấp gần đúng → giữ các nơi đã lưu, thẻ ghi "Chưa tự báo được: cần quyền vị trí Luôn luôn", nút "Mở Cài đặt". Nút bấm tay vẫn chạy.
  App kiểm lại quyền mỗi lần resume; người dùng hạ quyền trong Cài đặt → huỷ geofence, cập nhật thẻ. *Lý do:* người chỉ muốn bấm tay hoặc chỉ muốn lưu Nhà bằng địa chỉ không bị hỏi quyền nào; quyền "Luôn luôn" chỉ hỏi đúng lúc người dùng bật tự báo, khớp hướng dẫn Android 11+ và 5.1.1(iv).

- **D9 — Cặp đang chờ người ấy: ẨN hoàn toàn** (không thẻ, không mục Cài đặt). Khi couple chuyển `active`, thẻ xuất hiện với lời mời bật. *Lý do:* không có ai nhận tin; xin "Luôn luôn" khi chưa thấy giá trị sẽ tăng tỉ lệ từ chối quyền, mà từ chối rồi thì hệ điều hành không cho hỏi lại.

- **D10 — Chia sẻ opt-in từng người, độc lập.** Mặc định TẮT. A bật, B không bật vẫn được (B thấy A về nhà, A không thấy gì của B). Không bắt "có qua có lại". *(PO tự chốt.)* *Lý do:* bắt có qua có lại là ép người ngại phải bật. Mỗi người tự quyết phần của mình, giống chia sẻ giấc ngủ.

- **D11 — An toàn, chống thành công cụ kiểm soát:**
  - **Tắt chia sẻ = xoá ngay** sự kiện trên máy chủ (cùng một lần ghi), huỷ mọi geofence trên máy, xoá toạ độ trong Hive nếu người dùng chọn "Xoá luôn địa điểm".
  - **Không push "đã tắt chia sẻ".** Người ấy chỉ thấy thẻ về trạng thái trung tính "Thảo chưa bật báo về nhà", y hệt người chưa bao giờ bật. Không lộ thời điểm tắt.
  - **Người chia sẻ luôn thấy mình đang chia sẻ gì:** thẻ Home có dòng "Mình đang tự báo khi đến: Nhà · Công ty" + chạm để tắt (2.5.14). iOS còn hiện mũi tên vị trí và định kỳ hỏi lại quyền "Luôn luôn"; Android hiện thông báo hệ thống về vị trí nền. Mình không tắt những lời nhắc đó.
  - **Không có nút "Thảo đang ở đâu?"**, không yêu cầu vị trí từ xa, không hiện "lần cuối thấy". Chỉ có sự kiện do máy Thảo tự gửi.
  - Copy thẻ người nhận không dùng từ "theo dõi", "kiểm tra".
  *Lý do:* app cặp đôi dễ thành chỗ ghen tuông; mọi lựa chọn ở đây nghiêng về người chia sẻ.

- **D12 — Copy xin quyền (chốt lời, Designer chỉ chốt bố cục).**
  - Màn giải thích 1 (prominent disclosure, bắt buộc có "vị trí" + "kể cả khi app đã đóng"):
    - vi: *"Dear Embeiu dùng vị trí để báo người ấy khi bạn về Nhà hoặc đến những nơi bạn đã lưu, kể cả khi app đã đóng hoặc không dùng. Địa chỉ và toạ độ chỉ lưu trên máy bạn. Người ấy chỉ thấy tên nơi đến, giờ và mức pin lúc đó. Bạn tắt lúc nào cũng được."*
    - en: *"Dear Embeiu uses your location to let your partner know when you get Home or reach a place you saved, even when the app is closed or not in use. Addresses and coordinates stay on your phone. Your partner only sees the place name, the time and your battery level. You can turn this off anytime."*
  - `NSLocationWhenInUseUsageDescription` (`ios/Runner/{vi,en}.lproj/InfoPlist.strings`):
    - vi: *"Dear Embeiu đọc vị trí khi bạn chọn \"Dùng vị trí hiện tại\" để lưu một nơi, và để nhận ra khi bạn đến nơi đó. Toạ độ chỉ nằm trên máy bạn."*
    - en: *"Dear Embeiu reads your location when you tap \"Use current location\" to save a place, and to notice when you arrive there. Coordinates stay on your phone."*
  - `NSLocationAlwaysAndWhenInUseUsageDescription`:
    - vi: *"Để báo người ấy khi bạn đến nơi, kể cả lúc app đang đóng. App chỉ gửi tên nơi đến, giờ và mức pin, không gửi toạ độ."*
    - en: *"So your partner knows when you arrive, even when the app is closed. Only the place name, time and battery level are sent, never coordinates."*
  - Màn giải thích 2 (trước "Luôn luôn"): vi *"Để tự báo cả lúc app đang đóng, chọn \"{label}\" ở trang tiếp theo."* · en *"To send it even when the app is closed, choose \"{label}\" on the next screen."* (`{label}` = "Luôn luôn"/"Always" trên iOS, chữ hệ thống trả về trên Android).
  *Lý do:* Play bắt nội dung tối thiểu; Apple bắt câu xin quyền nói đủ cách dùng. Viết một lần để store, privacy policy và app nói cùng một câu.

- **D13 — Phát hành CHUNG một bản, cả 2 nền tảng tự động** (user chốt 2026-10-20: "Dồn chung một bản"; thay đề xuất tách đôi của PO).
  - **Bản đợt 2 (cả 2 store, cùng version theo luật parity):** chế độ tự động bật trên **cả iOS lẫn Android**. Android có `ACCESS_BACKGROUND_LOCATION` ⇒ nộp form khai báo vị trí nền + video ≤30 giây + Data safety ngay trong lần gửi duyệt này. Nút bấm tay chạy cả 2 nền tảng.
  - **Rủi ro chấp nhận:** Play từ chối quyền vị trí nền thì **cả bản đợt 2 trên Android bị chặn** (user đã biết khi chọn).
  - **Kế hoạch B khi Play từ chối:** build lại cùng version, build +1: gỡ quyền khỏi manifest (`tools:node="remove"`, kiểm `aapt2 dump permissions`), hằng `kArrivalAutoAndroid = false` ẩn chế độ tự động trên Android, nộp lại để 4 feature kia lên store. Theo luật parity, iOS cũng nhận build mới cùng số (không đổi tính năng). PO viết lại khai báo, thử lại tối đa 1 lần ở bản sau.
  - **Apple từ chối vì arrival:** hằng `kArrivalAutoEnabled = false` (như `kAiQuestionsFeatureEnabled`) ẩn chế độ tự động, bỏ `NSLocationAlways…`/`UIBackgroundModes location` (nếu có) rồi nộp lại. Mất 1 vòng duyệt, 4 feature kia đi tiếp.
  - **Cờ tắt từ xa:** `config/app.arrivalAutoEnabled` (bool, không bắt buộc; **thiếu = bật**). Đặt `false` → lần mở app kế, app huỷ mọi geofence và ẩn chế độ tự động; bấm tay vẫn chạy. Dùng khi có khiếu nại pin, cảnh báo chính sách, hoặc bug báo sai hàng loạt. Rules `config` đã public read, không sửa rules.
  - **Video khai báo Play:** Claude quay trên emulator Android (giả lập vị trí) trước; nếu Play đòi máy thật thì user quay. Nội dung khai báo Claude soạn, user bấm gửi trên Console. Privacy policy + Data safety + App Privacy: user đồng ý sửa trước khi gửi duyệt (2026-10-20).
  *Lý do:* user muốn tính năng đủ trên cả 2 nền tảng ngay đợt này; rủi ro chặn cả đợt Android được chặn bởi kế hoạch B (nộp lại không có quyền nền trong 1 vòng).

- **D14 — Mô hình dữ liệu, một doc mỗi người** (chi tiết §5). Không subcollection, không toạ độ, không lịch sử. *Lý do:* D2 + D3.

- **D15 — CF `notifyArrival` chỉ push, KHÔNG ghi inbox.** *Lý do:* inbox lưu mãi, thành nhật ký đi lại (trái D3). Push là tin nhất thời; thẻ Home và widget hiện sự kiện mới nhất.

- **D16 — Người nhận tắt được push arrival** bằng khoá mới `pushArrival` trong `PUSH_TYPE_PREF_FIELD` (lưu trên doc thiết bị như `pushPhoto`), mục Cài đặt → Thông báo. Tắt push không tắt thẻ/widget. *Lý do:* người chia sẻ quyết định gửi, người nhận quyết định có bị làm phiền hay không.

- **D17 — Thẻ, push, widget đều dùng tên người ấy + tên địa điểm, không bao giờ hiện giờ trong push.** Giờ chỉ hiện trên thẻ và widget theo đồng hồ máy người nhận. *Lý do:* CF không biết múi giờ người nhận; thông báo đã có giờ của hệ thống.

- **D18 — Tương thích bản cũ.** Collection mới, rules additive, app 1.10.x/1.11.0 không đọc. Push `type: 'arrival'` tới app cũ → `NotificationTapRouter` rơi về Home (mặc định), không inbox nên không có dòng lạ. Khoá `arrivalAutoEnabled` trong `config/app` bị app cũ bỏ qua.

- **D19 — Nơi do người dùng tự đặt** (user yêu cầu 2026-10-20 sau khi xem mockup: "không cố định chỗ làm hay nhà, nhưng mặc định để về nhà").
  - **Nhà** là slot `home`, luôn có, không xoá, không đổi tên (hiện "Nhà"/"Home" theo ngôn ngữ app), biểu tượng nhà cố định. Có thể chưa có vị trí.
  - Thêm tối đa **4 nơi** (slot `p1`…`p4`). Tên **1–24 ký tự** sau khi cắt khoảng trắng, một dòng; gợi ý nhanh bằng chip: "Công ty", "Trường", "Nhà bố mẹ", "Phòng gym", "Quán quen". Ô tên có dòng nhắc: *"Người ấy sẽ thấy tên này khi bạn đến."*
  - **Biểu tượng**: chọn 1 trong 7 (`work`, `school`, `family`, `gym`, `cafe`, `shop`, `pin`), mặc định `pin`. Lưu dạng khoá, không lưu emoji. Hiện trên thẻ người ấy để đọc nhanh hơn chữ.
  - Đổi tên / xoá nơi: chỉ ảnh hưởng sự kiện sau. Sự kiện đang hiện giữ tên lúc xảy ra (`last.name`, D23).
  *Lý do:* user muốn tự đặt; giữ Nhà cố định vì nút chính và câu "đã về đến nhà" xoay quanh nó. 24 ký tự vừa "Nhà ngoại ở Thanh Xuân", vẫn không tràn widget bản vừa. Tên do người dùng gõ là dữ liệu người ấy thấy, nên có dòng nhắc ngay ô nhập.

- **D20 — Tìm địa chỉ bằng geocoder của hệ điều hành** (so sánh §2). iOS: `MKLocalSearchCompleter` gợi ý khi gõ (giới hạn vùng quanh Việt Nam, debounce 300 ms) → chọn → `MKLocalSearch` lấy toạ độ + địa chỉ đầy đủ. Android: `Geocoder.getFromLocationName(query, 5, listener)` (API 33+, bản cũ hơn gọi trên isolate/thread phụ) giới hạn khung Việt Nam (vĩ độ 8,18–23,39; kinh độ 102,14–109,46), gọi khi ngừng gõ 800 ms hoặc bấm Tìm. `Geocoder.isPresent() == false` (máy không có Google Play services) hoặc lỗi mạng → ẩn ô tìm, chỉ còn "Dùng vị trí hiện tại". Dev chọn package `geocoding` hay kênh native nhỏ, miễn có cả gợi ý iOS. Chi phí 0 USD ở 165 lẫn 10.000 user, không key. *Lý do:* miễn phí, không key, không thêm tài khoản thanh toán; Apple và Google đều đã cập nhật tên tỉnh/phường mới năm 2026. Đánh đổi: Android không gợi ý theo từng chữ.

- **D21 — Xác nhận trước khi lưu bằng chữ, không bản đồ.** Màn xác nhận hiện: tên nơi + biểu tượng · địa chỉ đầy đủ hệ điều hành trả về (tối đa 2 dòng) · câu *"App báo khi bạn vào trong khoảng 250 m quanh đây"* (150 m nếu dùng vị trí hiện tại) · nút **Lưu** · link *"Không đúng chỗ? Dùng vị trí hiện tại khi bạn đang ở đó"*. Kết quả chỉ tới mức đường/phường (không có số nhà) → thêm dòng cảnh báo *"Địa chỉ này chưa có số nhà, app có thể báo hơi sớm hoặc hơi muộn"*. Sau khi lưu, làn của mình trên thẻ hiện sự kiện đến đầu tiên ("Mình đã đến Phòng gym · 18:05") để người dùng tự thấy app nhận ra đúng chỗ. *Lý do:* bản đồ cần 2 thư viện khác nhau trên 2 nền tảng, Android cần API key trong app, Designer thêm một khối lớn; bán kính 250 m đã bù phần lớn sai số địa chỉ. Phase 2 thêm bản đồ nếu số người "Đặt lại" nhiều (§13).

- **D22 — Khai báo riêng tư cho phần tìm địa chỉ.** Privacy policy thêm câu: *"Khi bạn tìm địa chỉ, chữ bạn gõ được gửi tới dịch vụ bản đồ của Apple (iPhone) hoặc Google (Android) để tìm toạ độ. Dear Embeiu không gửi chuỗi này lên máy chủ của mình và không lưu nó ngoài máy bạn."* (en tương ứng). Data safety / App Privacy giữ mục Vị trí gần đúng đã khai ở §2; geocoder là dịch vụ của hệ điều hành, không phải SDK bên thứ ba trong app. *Lý do:* user yêu cầu ghi rõ; nói thật cách dữ liệu đi đâu là cách an toàn nhất với cả 2 store.

- **D23 — `last` mang tên + biểu tượng chụp lúc xảy ra** (`name`, `icon`; Nhà thì không có `name`). CF lấy tên từ đây, không đọc danh sách nơi (vì danh sách không lên máy chủ, D2). *Lý do:* đổi tên hay xoá nơi sau đó không làm push/thẻ cũ sai hoặc trống.

## 5. Dữ liệu Firestore + phác rules (CHỈ ADDITIVE)

```
couples/{coupleId}/arrival/{uid}          // doc id == uid người chia sẻ
  share:     bool                         // đang chia sẻ? (thiếu = false)
  auto:      bool                         // đang bật tự động trên máy (thẻ người nhận ghi "tự báo" hay "chỉ bấm tay")
  last: {                                 // sự kiện mới nhất; KHÔNG được có khi share != true
    place:   'home' | 'p1' | 'p2' | 'p3' | 'p4'   // slot, ổn định để CF tính cooldown
    name:    string 1..24                 // CHỈ khi place != 'home' (D23); Nhà thì client tự dịch "Nhà"/"Home"
    icon:    'work'|'school'|'family'|'gym'|'cafe'|'shop'|'pin'   // optional, CHỈ khi place != 'home'
    type:    'enter' | 'exit'
    at:      timestamp                    // giờ xảy ra trên máy người gửi
    battery: int 0..100                   // optional (đọc pin lỗi thì bỏ)
    source:  'auto' | 'manual'
    bounce:  bool                         // optional, D6
  }
  updatedAt: timestamp
  // CHỈ CF ghi (Admin SDK): lastPushAt: map<slot, timestamp>, pushDay: 'YYYY-MM-DD', pushCount: int
  // KHÔNG có: địa chỉ, toạ độ, danh sách nơi, bán kính (D2)
```

Local (Hive `arrival_nobackup`, không lên máy chủ): mỗi slot `{name?, icon?, lat, lng, radius, address, source: 'address'|'current', savedAt}` + trạng thái trong/ngoài cuối cùng cho D6.

Phác rules (Dev viết thật + test; tham khảo khối `sleep/{uid}` ở `firestore.rules` ~dòng 594):

```
match /arrival/{uid} {
  // Đọc được cả khi share=false: lúc đó doc không có `last` (ràng buộc ghi bên dưới),
  // người ấy chỉ thấy "chưa bật". Tránh permission-denied làm thẻ hiện lỗi.
  allow read: if isCoupleMember(coupleId);
  allow create, update: if isCoupleMember(coupleId)
    && uid == request.auth.uid
    && (resource == null
        ? request.resource.data.keys().hasOnly(['share','auto','last','updatedAt'])
        : request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['share','auto','last','updatedAt']))     // giữ nguyên khoá CF
    && request.resource.data.get('share', false) is bool
    && (!('auto' in request.resource.data) || request.resource.data.auto is bool)
    // Tắt chia sẻ thì không được còn `last` (D11: tắt = xoá cùng lần ghi)
    && (request.resource.data.get('share', false) == true || !('last' in request.resource.data))
    && (!('last' in request.resource.data) || isValidArrivalEvent(request.resource.data.last))
    // Bật chia sẻ chỉ khi couple đủ 2 người (bài học sleep: lệnh bật xếp hàng offline)
    && (request.resource.data.get('share', false) != true
        || (resource != null && resource.data.get('share', false) == true)
        || get(/databases/$(database)/documents/couples/$(coupleId)).data.memberIds.size() == 2);
  allow delete: if false;   // tắt = ghi share:false + bỏ `last`; dọn hẳn do CF
}

function isValidArrivalEvent(e) {
  return e is map
    && e.keys().hasOnly(['place','name','icon','type','at','battery','source','bounce'])
    && e.keys().hasAll(['place','type','at','source'])
    && e.place in ['home','p1','p2','p3','p4']
    // Nhà: không tên, không biểu tượng. Nơi tự đặt: bắt buộc tên 1..24, biểu tượng tuỳ chọn.
    && (e.place == 'home'
        ? !('name' in e) && !('icon' in e)
        : (e.name is string && e.name.size() >= 1 && e.name.size() <= 24
           && !hasLineBreak(e.name)   // Dev viết bằng RE2 (cần (?s)), có test
           && (!('icon' in e) || e.icon in ['work','school','family','gym','cafe','shop','pin'])))
    && e.type in ['enter','exit']
    && e.at is timestamp
    && e.at <= request.time + duration.value(5, 'm')     // lệch đồng hồ máy
    && e.at >= request.time - duration.value(12, 'h')    // hàng đợi offline lâu quá thì bỏ
    && (!('battery' in e) || (e.battery is int && e.battery >= 0 && e.battery <= 100))
    && e.source in ['auto','manual']
    && (!('bounce' in e) || e.bounce is bool);
}
```

Ghi chú cho Dev:
- `last.at` là giờ máy (không `request.time`) vì ghi từ nền có thể vào hàng đợi offline; CF dùng D6 để không push sự kiện cũ.
- Tắt chia sẻ: một lần `set(..., merge:false)` hoặc `update` với `last: FieldValue.delete()` + `share:false`. Kiểm rules cho trường hợp xoá field bằng `FieldValue.delete()` qua `affectedKeys`.
- `name.size()` của rules đếm theo ký tự Unicode; client cắt ở 24 ký tự hiển thị (grapheme) nên emoji ghép có thể bị rules chặn sớm hơn — chấp nhận, client đếm theo rune cho khớp.
- Máy nhận lỗi `permission-denied` khi ghi từ nền (đã rời couple, đăng xuất) → huỷ hết geofence trên máy đó.

## 6. Kỹ thuật: điều Dev phải SPIKE trước (≤1 ngày, Haiku/Sonnet theo §9 CLAUDE.md)

Mọi dòng dưới là **giả định**. Spike trả lời bằng số đo, ghi vào `dev.md`. Giả định sai → báo PO trước khi viết plan.

1. `native_geofence` 1.3.1 build được với Flutter 3.41.6, `firebase_messaging` 16.x, target SDK 36, Xcode 27; không kéo license trả phí.
2. **iOS, app bị hệ thống tắt** (không vuốt tắt): vào/ra vùng trên máy thật (giả lập GPX trên simulator chỉ để thử luồng) → callback chạy, `Firebase.initializeApp` + `FirebaseAuth.currentUser` khôi phục được, ghi Firestore xong trong ~10 giây nền. Đo độ trễ.
3. **iOS, app bị vuốt tắt** trên iOS 18 và iOS 26: có được đánh thức không. Không → ghi vào hạn chế (giống widget-today 🔴), không chặn release.
4. **Android, app đã tắt:** callback chạy trên engine nền của plugin; Firebase khởi tạo được; plugin pin (`battery_plus` hoặc kênh native nhỏ) có mặt trong engine nền (bài học widget-today D13: kênh đăng ký ở `MainActivity` sẽ `MissingPluginException`).
5. Android: plugin có thêm `FOREGROUND_SERVICE`/`FOREGROUND_SERVICE_LOCATION` hay `ACCESS_BACKGROUND_LOCATION` vào merged manifest không; chặn được bằng `tools:node="remove"` cho bản đợt 2 (D13) không.
6. iOS cần `UIBackgroundModes location` không (region monitoring thường KHÔNG cần). Không cần thì đừng thêm: Apple soi khoá này rất kỹ.
7. Ngân sách: số geofence (≤5) + band notification local không đổi (feature này không thêm lịch local).
8. **Độ đúng của geocoder hệ điều hành với địa chỉ VN:** 20 địa chỉ mẫu (8 Hà Nội, 8 TP.HCM, 4 tỉnh; nửa gõ tên phường/tỉnh cũ, nửa gõ tên mới sau sáp nhập; có số nhà và hẻm kiểu "45/12 Lê Văn Sỹ") → đo khoảng cách tới toạ độ thật trên Google Maps, cả iOS lẫn Android. **Ngưỡng giữ D20:** ≥70% kết quả nằm trong 250 m ở mỗi nền tảng. Dưới ngưỡng → báo PO; phương án là Goong qua CF proxy (key trên server, ~1,40 USD/1.000 lượt) ở Phase 2, cần user duyệt chi phí.
9. iOS: `MKLocalSearchCompleter` có bị `loadingThrottled` khi gõ nhanh với debounce 300 ms không.

## 7. Cloud Functions

- **`notifyArrival`** — mới, `onDocumentWritten("couples/{coupleId}/arrival/{uid}")`.
  - Bỏ qua khi: doc bị xoá · `share != true` · `last` không đổi (so `place`+`type`+`at`) · `last.type != 'enter'` · `last.bounce == true` · `last.at` cũ hơn 30 phút so với giờ server · couple không `active` · đã push cùng `place` trong 30 phút (`lastPushAt[place]`) · đã đủ 6 push trong ngày (`pushDay`/`pushCount`, ngày theo UTC+7 cho đơn giản, ghi rõ trong code).
  - Gửi cho **thành viên còn lại** (không phải `uid`) qua `sendToRecipientDevices(recipients, buildText, {type:'arrival', place (slot), placeName?, icon?, name, date, battery?}, {wakeClients: true})`. `data.date` = ngày của `last.at` theo giờ VN, để handler nền bỏ qua ngày cũ (widget-today D9).
  - Sau khi gửi: Admin ghi `lastPushAt.{place}`, `pushDay`, `pushCount` (merge). Ghi này lại kích chính trigger → nhánh "`last` không đổi" chặn vòng lặp.
  - **Không ghi inbox** (D15). Có mute `pushArrival` (D16).
  - Copy (localize theo `languageCode` thiết bị; `{name}` lấy `displayName` người gửi, thiếu thì fallback `partnerFallback` như `DAILY_QUESTION_COPY`):

| place | title vi | title en |
|---|---|---|
| `home` | `{name} đã về đến nhà` | `{name} got home` |
| nơi tự đặt | `{name} đã đến {place}` (vd "Thảo đã đến Phòng gym") | `{name} arrived at {place}` |

  `{place}` = `last.name` nguyên văn (người dùng tự gõ, không dịch). CF cắt `{place}` ở 24 ký tự lần nữa cho chắc.
  Body: pin ≤ 20% → vi `Pin còn {battery}%` · en `Battery at {battery}%`. Còn lại → vi `Nhắn một câu hỏi thăm nhé` · en `Send a quick hello`.
  - **Tần suất `wakeClients`:** mỗi người nhận ≤ 6/ngày từ arrival, thực tế 1–3. Cộng các nguồn đánh thức hiện có (câu hỏi, mood, ảnh, chat, decision, poke của đợt 2) vẫn trong mức "vài lần/giờ" của iOS, trừ khi chat dày. Lead cân chung ngân sách với `poke` (§12).
- **`notifyPartnerLeft`** — sửa: như khối `sleep` (~dòng 435 `functions/index.js`): `recursiveDelete(arrival/{leaver})`; người ở lại → `set({share:false, updatedAt}, merge)` rồi xoá field `last`. Người mới ghép vào không thấy gì cũ.
- **Dọn couple** (`deleteAccount` / `leaveCoupleCleanup`, hàm teardown ~dòng 3240): thêm `recursiveDelete(coupleRef.collection("arrival"))`. `leaveCoupleCleanup` nhánh 1 người rời (~dòng 3143): xoá `arrival/{uid}` như `sleep`.
- **`PUSH_TYPE_PREF_FIELD`**: thêm `arrival: "pushArrival"`; rules `users/{uid}/devices` `hasOnly` phải liệt kê thêm `pushArrival` (CLAUDE.md §5 cảnh báo push hỏng âm thầm nếu thiếu).
- Deploy PROD đích danh `functions:notifyArrival,functions:notifyPartnerLeft,functions:deleteAccount,functions:leaveCoupleCleanup` + `firestore:rules`, **chờ lệnh user**. Rules PROD phải lên trước khi bản có arrival live.

## 8. UI (đề xuất; Designer chốt chung cả đợt vì Home đã dày)

- **Điểm vào chính: thẻ "Về đến nhà chưa?" trên Home** (chỉ cặp active). Đề xuất đặt cạnh/gộp với `SleepCard` thành cụm "người ấy hôm nay" để Home không dài thêm một thẻ; Designer quyết. Các trạng thái thẻ:
  1. *Chưa ai bật:* 1 dòng giải thích + nút "Bật báo về nhà" + nút "Về nhà rồi" (bấm tay vẫn dùng được ngay).
  2. *Người ấy có sự kiện:* "Thảo đã về đến nhà · 22:58 · pin 12%" (pin ≤20% đổi màu cảnh báo nhẹ, không đỏ chói). Nơi tự đặt: "Thảo đã đến Phòng gym · 18:05" kèm biểu tượng. Sự kiện rời: "Thảo đã rời Công ty · 17:32" / "Thảo đã rời nhà · 7:40". Sự kiện hôm qua trở về trước: thêm ngày ("hôm qua 22:58"); cũ hơn 3 ngày thì ẩn, chỉ còn "Thảo đang bật báo về nhà".
  3. *Người ấy chưa bật / đã tắt:* "Thảo chưa bật báo về nhà" (trung tính, D11). Không có nút giục.
  4. *Phần của mình:* "Mình đang tự báo khi đến: Nhà · Công ty" (quá 3 nơi thì "Nhà và 3 nơi khác") hoặc "Chưa tự báo được: cần quyền vị trí Luôn luôn" + nút "Mở Cài đặt", hoặc "Đã tắt từ xa" khi cờ D13 = false (chữ: "Tạm thời chỉ báo bằng tay"). Nút chính "Về nhà rồi" + nút phụ "Đến nơi rồi" (mở danh sách nơi đã tạo, D7).
  5. *Offline:* bấm tay vẫn nhận, hiện "Sẽ báo khi có mạng" (Firestore xếp hàng); nếu tới lúc gửi đã quá 30 phút thì người ấy chỉ thấy trên thẻ, không push (D6). Ghi rõ câu này dưới nút khi offline.
  6. *Lỗi ghi:* dải lỗi + "Thử lại".
  - Nút phụ trên thẻ người nhận: "Hỏi thăm" → mở `CareMessageScreen` (có sẵn) với chip gợi ý "Về tới nơi rồi thì nghỉ ngơi nhé". Không thêm model mới.
- **Màn thiết lập "Báo về nhà"** (màn con, `SubScreenHeader`, chip "VỀ ĐẾN NHÀ" / "ARRIVALS"): công tắc chia sẻ · công tắc "Tự báo khi mình đến nơi" + trạng thái quyền · **danh sách nơi**: Nhà luôn ở đầu (dòng phụ = địa chỉ rút gọn hoặc "Chưa đặt địa chỉ"), rồi các nơi tự đặt, nút "Thêm nơi" (ẩn khi đủ 5) · câu "Đừng vuốt tắt app để báo về nhà chạy đều" (§12). Vào từ thẻ Home + Cài đặt → mục "Về đến nhà".
- **Màn thêm / sửa nơi** (màn con):
  1. *Tên + biểu tượng* (Nhà: bỏ bước này) — ô tên 24 ký tự, chip gợi ý tên, hàng 7 biểu tượng, dòng nhắc "Người ấy sẽ thấy tên này khi bạn đến".
  2. *Địa chỉ* — ô tìm, placeholder *"Vd: 12 Nguyễn Trãi, Thanh Xuân, Hà Nội"* / *"e.g. 12 Nguyen Trai, Thanh Xuan, Ha Noi"*. Trạng thái: đang gõ (iOS gợi ý ngay; Android hiện "Đang tìm…" sau 800 ms) · có kết quả (≤5 dòng, dòng đậm = tên/số nhà, dòng nhạt = phường, tỉnh) · **không thấy** → *"Không tìm thấy địa chỉ này. Thử thêm tên phường hoặc tỉnh, hoặc dùng vị trí hiện tại khi bạn đang ở đó."* + nút "Dùng vị trí hiện tại" · **mất mạng** → *"Cần mạng để tìm địa chỉ"* + vẫn có nút "Dùng vị trí hiện tại" · máy không có geocoder → chỉ nút "Dùng vị trí hiện tại". Link "Dùng vị trí hiện tại" luôn có ở cuối danh sách.
  3. *Xác nhận* (D21) → Lưu.
  - Sửa nơi: đổi tên/biểu tượng/địa chỉ, "Xoá nơi này" (trừ Nhà; Nhà có "Xoá địa chỉ").
- **Cài đặt → Thông báo:** công tắc "Khi người ấy đến nơi" (`pushArrival`, D16).
- **Chạm push** → Home (tab 0), `pendingHomeFocus = 'arrival'` cuộn tới thẻ. Thêm nhánh `arrival` ở `push_notification_service.dart._handleNotificationTap`. Không inbox nên không đụng `AppNotification.targetHomeTab`.
- Copy chốt ở §4 D12 + §7 + bảng widget dưới. Designer tra UI UX Pro Max (luật 8); thẻ và nút đứng cạnh nhau soát chung một lượt.

### Widget-today: loại trạng thái mới

| `statusKind` | Khi nào | vi (`statusText`) | en | vi rút gọn (`statusTextShort`) | en rút gọn | Chạm mở |
|---|---|---|---|---|---|---|
| `arrival_home` | người ấy vừa đến Nhà hôm nay | `{name} đã về đến nhà` | `{name} got home` | `{name} về nhà rồi` | `{name} is home` | Home, cuộn thẻ arrival |
| `arrival_place` | … đến một nơi tự đặt | `{name} đã đến {place}` | `{name} arrived at {place}` | `{name} tới {place}` | `{name} at {place}` | như trên |

- Cập nhật từ push nền (`data.type == 'arrival'`) và từ provider khi app mở; theo D3 "mới nhất thắng" của widget-today. Không hiện pin, không hiện sự kiện rời (D4). `statusFocus = 'arrival'`. Thêm hằng vào `lib/services/home_widget_status.dart`.

## 9. Analytics (không gửi toạ độ, địa chỉ, chuỗi tìm, tên người/tên nơi, % pin cụ thể)

| Event | Params | Khi nào |
|---|---|---|
| `arrival_setup_open` | `from`: `home_card`·`settings` | mở màn thiết lập |
| `arrival_permission` | `step`: `when_in_use`·`always`, `result`: `granted`·`denied`·`approximate` | sau mỗi hộp xin quyền |
| `arrival_place_saved` | `slot`: `home`·`custom`, `source`: `address`·`current`, `icon`, `has_house_number`: bool | lưu nơi (không gửi tên, địa chỉ) |
| `arrival_address_search` | `result`: `picked`·`not_found`·`offline`·`unavailable`·`error`, `platform` | kết thúc một lượt tìm (không gửi chuỗi gõ) |
| `arrival_place_deleted` | `slot`: `custom`·`home_address` | xoá nơi / xoá địa chỉ Nhà |
| `arrival_share_toggled` | `on`: bool, `auto`: bool | bật/tắt chia sẻ |
| `arrival_manual` | `slot`: `home`·`custom` | bấm "Về nhà rồi" / "Đến nơi rồi" |
| `arrival_card_action` | `action`: `care_message`·`open_settings` | bấm nút trên thẻ |

Sự kiện tự động xảy ra ở nền, không log analytics (engine nền không chắc có Analytics). Đếm sự kiện tự động bằng log CF `notifyArrival` (số push gửi / bỏ qua theo lý do).

## 10. Acceptance criteria (kiểm trên 2 máy, cặp DEV `test3`/`test4`)

- [ ] Cặp `waiting_partner` (`test1`): không có thẻ, không có mục Cài đặt arrival.
- [ ] **Bấm tay, không cấp quyền vị trí nào:** B bấm "Về nhà rồi" → A nhận push "Tuấn đã về đến nhà" ≤10 giây (máy có push), thẻ A đổi realtime ≤3 giây, widget A hiện "Tuấn đã về đến nhà"; không có dòng mới trong inbox A.
- [ ] **Tự động, iOS máy thật:** B lưu Nhà bằng địa chỉ, cấp "Luôn luôn", đưa app về nền rồi rời nhà >300 m và quay lại → A nhận push ≤5 phút sau khi B vào vùng (ghi số đo thật vào `test.md`). Lần rời: thẻ A ghi "đã rời nhà", không push.
- [ ] **Tự động, Android** (D13): như trên, app B đã bị tắt khỏi đa nhiệm.
- [ ] **Rìa vùng:** đi ra rồi vào lại trong 5 phút → A chỉ nhận đúng 1 push. Đến Nhà 7 lần trong ngày → tối đa 6 push.
- [ ] **Pin:** pin B 15% khi đến → push có "Pin còn 15%"; pin 60% → body "Nhắn một câu hỏi thăm nhé"; thẻ luôn hiện %.
- [ ] **Từ chối quyền:** chỉ cấp "Khi dùng app" hoặc vị trí gần đúng → thẻ B ghi "Chưa tự báo được…", nút "Mở Cài đặt" mở đúng trang; bấm tay vẫn chạy. Hạ quyền trong Cài đặt rồi mở lại app → geofence bị huỷ (kiểm log).
- [ ] **Tắt chia sẻ:** B tắt → doc `arrival/{B}` không còn `last` (Firestore console), thẻ A về "chưa bật" ≤3 giây, A **không** nhận push nào về việc tắt; geofence trên máy B bị huỷ.
- [ ] **Rời couple:** B rời → `arrival/{B}` bị xoá, `arrival/{A}` có `share:false` và không còn `last`. Ghép đôi lại với người mới → người mới không thấy gì cũ. Máy B ghi từ nền sau khi rời → `permission-denied` → máy B tự huỷ geofence.
- [ ] **Xoá tài khoản / người cuối rời:** collection `arrival` của couple bị xoá.
- [ ] **Cờ từ xa:** đặt `config/app.arrivalAutoEnabled=false` trên DEV → mở lại app: chế độ tự động ẩn, geofence bị huỷ, bấm tay vẫn chạy. Xoá khoá → bật lại được.
- [ ] **Mute:** A tắt "Khi người ấy đến nơi" → không push, thẻ + widget vẫn đổi.
- [ ] **Bản cũ:** app 1.11.0 trên máy A nhận push arrival → không crash, chạm mở Home.
- [ ] **Bản đợt 2 Android** (D13 phát hành chung): `aapt2 dump permissions` CÓ `ACCESS_BACKGROUND_LOCATION`, KHÔNG có `FOREGROUND_SERVICE_LOCATION`. Bản kế hoạch B: không có cả hai.
- [ ] **Lưu nơi bằng địa chỉ, chưa cấp quyền vị trí nào:** gõ "12 Nguyễn Trãi, Thanh Xuân, Hà Nội" → có kết quả (iOS gợi ý khi đang gõ; Android ≤5 kết quả sau khi ngừng gõ) → chọn → màn xác nhận có địa chỉ đầy đủ + "250 m" → Lưu. Không hộp xin quyền nào hiện ra trong cả luồng.
- [ ] **Không tìm thấy:** gõ "zzzz" → câu không tìm thấy + nút "Dùng vị trí hiện tại" → chỉ lúc đó mới hiện hộp xin quyền "khi dùng app"; từ chối → quay về ô địa chỉ, không crash. Tắt mạng → câu "Cần mạng để tìm địa chỉ".
- [ ] **Nơi tự đặt:** B tạo "Phòng gym" (biểu tượng gym) → B bấm "Đến nơi rồi" → chọn Phòng gym → A nhận push "Tuấn đã đến Phòng gym", thẻ A có biểu tượng, widget A "Tuấn đã đến Phòng gym" (bản nhỏ "Tuấn tới Phòng gym"). B đổi tên thành "Gym" → sự kiện đang hiện vẫn "Phòng gym". Tên 25 ký tự không gõ được; tạo nơi thứ 5 ngoài Nhà bị ẩn nút. Nhà không xoá/đổi tên được.
- [ ] **Firestore không có địa chỉ:** sau khi lưu 3 nơi và đến 1 nơi, doc `arrival/{B}` chỉ có `share`, `auto`, `last`, `updatedAt` (+ khoá CF); không có chuỗi địa chỉ, toạ độ, danh sách nơi.
- [ ] iOS: hộp xin quyền hiện đúng câu D12 theo ngôn ngữ máy (vi và en).
- [ ] Rules: `scripts/test-firebase-rules.sh` PASS với ≥18 case mới: người ngoài couple đọc/ghi bị chặn · ghi doc người khác bị chặn · `share:false` kèm `last` bị chặn · `place` ngoài 5 slot bị chặn · Nhà kèm `name` bị chặn · nơi tự đặt thiếu `name` / `name` rỗng / 25 ký tự / có xuống dòng bị chặn · `icon` lạ bị chặn · client ghi khoá `places`/`address`/`lat` bị chặn · `last.at` tương lai >5 phút / cũ >12 giờ bị chặn · `battery` 101 hoặc chuỗi bị chặn · `type` lạ bị chặn · bật share khi couple 1 người bị chặn · client ghi `lastPushAt`/`pushCount` bị chặn · update giữ nguyên khoá CF có sẵn vẫn qua · delete bị chặn · doc chỉ có `share:false` (bản tối thiểu) qua · khoá thiết bị `pushArrival` qua.
- [ ] CF test emulator: push chỉ khi `enter` · bỏ `bounce` · cooldown 30 phút · trần 6/ngày · bỏ sự kiện cũ >30 phút · không gửi cho chính người gửi · không inbox · `wakeClients` có mặt · mute `pushArrival` · `notifyPartnerLeft` dọn đúng.
- [ ] `flutter analyze` 0; test Dart cho bộ lọc rìa vùng (D6) + map push → widget status 2 loại arrival + kiểm tên nơi (cắt khoảng trắng, 1–24, một dòng); i18n vi + en đủ; `gen-l10n`.
- [ ] Privacy policy (`docs/privacy-policy.html`, nhánh `phase3`) có mục vị trí + câu tìm địa chỉ D22; bảng dữ liệu đổi dòng vị trí. Nháp Data safety + App Privacy + form Play + kịch bản video nằm trong `dev.md`.
- [ ] Deploy DEV có vết; PROD chưa deploy cho tới lệnh.

## 11. Câu hỏi cho user

- ✅ [2026-10-20] Phát hành: user chọn **dồn chung một bản** (D13).
- ✅ [2026-10-20] Privacy policy + Data safety + App Privacy: user **đồng ý** sửa trước khi gửi duyệt.
- ✅ [2026-10-20] Video khai báo Play: Lead chốt Claude quay trên emulator (giả lập vị trí) trước, Play đòi máy thật thì user quay.

Các điểm còn lại PO tự chốt (user lật được): chỉ push khi ĐẾN (D4) · không push pin riêng (D5) · không có qua có lại (D10) · không lịch sử (D3) · ẩn với cặp đang chờ (D9).

## 12. Rủi ro / nợ (Tester soi)

- 🔴 **Play từ chối vị trí nền** (app cặp đôi, vị trí không phải chức năng chính). User chọn phát hành chung nên KHÔNG cô lập; kế hoạch B (nộp lại không có quyền nền) ở D13.
- 🔴 **iOS vuốt tắt app → có thể không được đánh thức** (nặng hơn trên iOS 26 theo báo cáo dev). Người dùng hay vuốt tắt sẽ thấy "lúc báo lúc không". Viết câu giải thích trong màn thiết lập: "Đừng vuốt tắt app để báo về nhà chạy đều".
- 🟡 Xiaomi/Oppo/Vivo chặn tự khởi động, Huawei không có Google Play services → chỉ bấm tay. Màn thiết lập Android hiện link hướng dẫn bật "Tự khởi động" khi phát hiện hãng (Dev quyết có làm ở v1 không).
- 🟡 iOS định kỳ hỏi lại "tiếp tục cho phép Luôn luôn?" → một phần người dùng sẽ hạ quyền. Đo bằng `arrival_permission` + tỉ lệ người `auto:true`.
- 🟡 Sự kiện trễ tới vài phút (iOS gộp vị trí); chung cư cao tầng GPS nhiễu. Bán kính 150 m là điểm cân bằng ban đầu.
- 🟡 Ngân sách đánh thức nền iOS dùng chung với chat, poke, decision, mood… Arrival thêm tối đa 6/ngày.
- 🟡 Đổi máy → mất địa điểm (D2). Màn thiết lập nói rõ.
- 🟡 **Geocoder hệ điều hành sai với địa chỉ VN** (hẻm, số nhà kiểu "45/12", tên phường mới chưa đồng bộ ở TP.HCM/Đà Nẵng/Hải Phòng). Đỡ bằng bán kính 250 m, cảnh báo "chưa có số nhà", lối "Dùng vị trí hiện tại". Đo ở spike §6 mục 8; dưới ngưỡng thì Goong (trả phí) ở Phase 2.
- 🟡 Android không gợi ý theo từng chữ → người dùng gõ cả câu rồi mới thấy kết quả. Chấp nhận ở v1.
- 🟡 **Tên nơi là chữ tự do người ấy đọc được** (vd đặt "Nhà Minh"). Không kiểm duyệt; chỉ có dòng nhắc ở ô tên. Tên chỉ lên máy chủ khi có sự kiện ở nơi đó, và mất khi tắt chia sẻ.
- 🟡 Mối quan hệ không lành mạnh: một người ép người kia bật. App không chặn được; giảm tác hại bằng D3, D11 và chỉ hiện sự kiện đến nơi trên push.
- 🟢 Riêng tư: không địa chỉ, không toạ độ, không danh sách nơi, không lịch sử, không inbox trên máy chủ; analytics không mang vị trí, chuỗi tìm, tên nơi hay % pin.

## 13. Metric đo thành công (30 ngày sau khi bản có arrival live)

- **Kích hoạt:** ≥30% cặp active có ít nhất 1 người bật chia sẻ (doc `arrival` có `share:true`). Script đọc-only thêm vào `scripts/prod-retention-stats.js`.
- **Dùng thật:** trung bình ≥1 sự kiện ĐẾN/ngày ở cặp đã bật (log CF `notifyArrival` sent + skipped).
- **Kéo người kia vào:** ≥35% push arrival dẫn tới người nhận mở app trong 30 phút; ≥15% dẫn tới một tin chat hoặc lời quan tâm trong 30 phút.
- **Mục tiêu đợt:** số cặp có người mở app mỗi ngày (nền 7–16/28) tăng; so riêng nhóm cặp bật arrival với nhóm không bật.
- **Tìm địa chỉ:** ≥70% lượt `arrival_address_search` kết thúc `picked`; <15% nơi bị "Đặt lại" địa chỉ trong 7 ngày đầu (nhiều hơn → làm bản đồ xác nhận Phase 2).
- **Báo động:** >20% người bật rồi tắt trong 7 ngày, hoặc ≥3 phản hồi "tốn pin" / "báo sai" → xem lại D1, D6, cân nhắc cờ D13.

## 14. Giao việc 3 vai (tóm tắt)

- 🎨 **Designer:** thẻ Home 6 trạng thái (đặt chung cụm với các thẻ đợt 2, quyết vị trí cùng Lead; nút "Về nhà rồi" + "Đến nơi rồi", biểu tượng nơi), màn thiết lập với danh sách nơi, màn thêm/sửa nơi 3 bước (tên + 7 biểu tượng · tìm địa chỉ với 5 trạng thái · xác nhận), 2 màn giải thích quyền, mục Cài đặt, dòng widget 2 loại (bản nhỏ/vừa, nền trời đêm + nền ảnh). Tra UI UX Pro Max. → *expect:* `design.md` + mock bấm thử.
- 💻 **Dev:** spike §6 trước; rồi `ArrivalService` (Firestore) + `ArrivalProvider` (wire `session_resolver`, nhớ named-param `_resolve`, clear khi sign-out/no-couple) + `ArrivalGeofence` (plugin, Hive `arrival_nobackup`, bộ lọc D6 thuần có test, callback nền) + `PlaceSearch` (geocoder hệ điều hành D20, có thể là kênh native nhỏ) + thẻ/màn/Cài đặt + cờ `config/app` + mute + widget kinds + `NotificationTapRouter` + rules/test + CF + analytics + ARB + InfoPlist.strings; deploy DEV. Soạn nháp privacy policy, Data safety, App Privacy, form Play, kịch bản video vào `dev.md`. → *expect:* nhánh feature, analyze 0, rules-test PASS, smoke 2 máy.
- 🧪 **Tester:** 25 tiêu chí §10 + 20 địa chỉ mẫu của spike §6 mục 8 + soi rules (giả `uid`, `last` khi tắt, đẩy `at` tương lai), đi bộ thật ra/vào vùng, máy Android bị tắt, iOS vuốt tắt (ghi hạn chế), mixed version 1.11.0. → *expect:* bảng PASS/FAIL + số đo trong `test.md`.

## 15. Nhật ký
- [2026-10-20] [PO] Tạo feature từ lựa chọn của user (đợt "mở app mỗi ngày" lần 2: poke · caro-game · weather · arrival · expenses). User chọn bản TỰ ĐỘNG kiểu Zenly. Nghiên cứu chính sách Play (vị trí nền, prominent disclosure, Data safety), App Store (5.1.1, 5.1.2, 5.1.5, 2.5.14), plugin `native_geofence` (MIT). Chốt D1–D18: geofence 3 địa điểm, toạ độ chỉ trên máy, không lịch sử, push chỉ khi đến, pin kèm sự kiện, không inbox, chia sẻ độc lập, tắt = xoá + không báo người kia, ẩn với cặp chờ, phát hành tách đôi (Android-auto sau) + cờ `config/app.arrivalAutoEnabled`. 2 câu hỏi cho user ở §11.
- [2026-10-20] [Lead] User trả lời: dồn chung một bản (D13 viết lại + kế hoạch B), đồng ý sửa privacy policy/khai báo store; Lead chốt video Play quay trên emulator trước.
- [2026-10-20] [Lead] Chốt câu hỏi Designer: giữ tên địa điểm cố định theo loại + bán kính 150 m như D1 (bỏ "đổi tên, bán kính" trong brief); nhãn làn của mình là "BẠN" cho khớp thẻ Đêm qua; cho phép biến thể gọn (làn người ấy + nút "Về nhà rồi") để Designer ghép Home dùng nếu Home quá dài; người chưa bật giấc ngủ dùng màu mặc định như sleep; nhận việc gộp nút "Tắt và xoá dữ liệu" vào công tắc "Báo cho …" (xoá dữ liệu máy chủ khi tắt, ô tick xoá luôn địa điểm). Ghi cho Dev: công tắc `pushArrival` phải đọc giá trị thật (từ 2026-06-14 `currentOrDefault()` luôn trả true); token mới `warningInk #8A4B00`.
- [2026-10-20] [Lead] Bổ sung: thứ tự làn trên Home thống nhất bạn bên trái, người ấy bên phải (theo thẻ Đêm qua) — đảo lại so với mock hiện tại; Designer ghép Home xử lý.
- [2026-10-20] [PO] User yêu cầu sau khi xem mockup: nơi tự đặt (mặc định Nhà, nút "Về nhà rồi"), nhập địa chỉ để app tự báo, không tìm thấy thì xin dùng vị trí hiện tại. Thay quyết định "tên cố định + 150 m" của log Lead. Nghiên cứu 4 nguồn tìm địa chỉ (geocoder hệ điều hành · Google Places · Goong · Nominatim) → chọn geocoder hệ điều hành (0 USD, không key). Sửa D1 (5 nơi, 150/250 m), D2 (địa chỉ chỉ trên máy, không đẩy danh sách nơi), D7, D8 (bậc 0 không cần quyền), D12 copy; thêm D19–D23 (nơi tự đặt + 7 biểu tượng, D20 geocoder, D21 xác nhận bằng chữ không bản đồ, D22 khai báo tìm địa chỉ, D23 `last.name`). Viết lại §5 rules (slot `home`/`p1..p4`, bỏ `places`), §7 copy, §8 màn thêm nơi, widget 2 loại, analytics, acceptance (+5), rủi ro, spike mục 8–9. Sửa luôn dòng acceptance `aapt2` cũ cho khớp D13 phát hành chung.
- [2026-10-20] [Lead] Chốt câu hỏi Designer (bản nơi tự đặt): từ 3 nơi trở lên làn Bạn ghi "Nhà và N nơi khác"; nhận gợi ý tên EN "Mom and Dad's", "Usual spot" (PO soát lại bằng avoid-ai-writing khi chốt ARB); xoá nơi có hoàn tác 5 giây (Dev làm, không cần mock lại).
- [2026-10-20] [Lead] Spike §6 xong (`spike.md`): `native_geofence` 1.3.1 + `battery_plus` 7.1.2 build qua cả 2 nền tảng, MIT/BSD; engine nền Android tự đăng ký plugin, iOS cần `NativeGeofencePlugin.setPluginRegistrantCallback` ở AppDelegate; KHÔNG cần `UIBackgroundModes location`; kế hoạch B (bỏ `ACCESS_BACKGROUND_LOCATION`) làm plugin từ chối geofence trên API ≥29 ⇒ cờ `kArrivalAutoAndroid=false` ẩn hẳn chế độ tự động. **D20 chốt lại:** gõ nguyên chuỗi chỉ đạt 60% trong 250 m (dưới ngưỡng 70%); app tự rút gọn truy vấn (bỏ phường/quận/xã/huyện, giữ số nhà + đường + tỉnh/thành) thì MKLocalSearch đạt 75% ⇒ iOS dùng **MKLocalSearch** (không CLGeocoder) + rút gọn, kết quả khác tỉnh/thành với chuỗi người gõ thì loại, số nhà kiểu hẻm "x/y" thì cảnh báo như "chưa có số nhà", D21 xác nhận bằng chữ luôn chạy, vị trí hiện tại là đường dự phòng. Android `Geocoder` đo khi smoke. Goong (trả phí) để Phase 2, chỉ làm khi user duyệt chi phí.
- [2026-10-29] [Lead] Phát hành 1.12.0 với tự báo cả 2 nền tảng (D13). Play: form "Quyền vị trí" đã nộp (video emulator ≤30 s, https://www.youtube.com/watch?v=um2C_5zkxyQ, kênh Zoey Tech Lab không công khai) + Data safety "Vị trí ước chừng" (thu thập, không chia sẻ, tuỳ chọn, chức năng app). Privacy policy (nhánh `phase3`) đã có mục vị trí + câu D22. ⏳ App Privacy iOS: chưa thêm Coarse Location (web, cần đăng nhập). Bị từ chối thì kế hoạch B (D13).
