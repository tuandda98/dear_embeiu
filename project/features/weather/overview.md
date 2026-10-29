# Thời tiết hai nơi — sáng mở app biết chỗ người ấy có mưa không

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
> Đợt "mở app mỗi ngày" lần 2 (user chọn 2026-10-20, làm cùng `poke` · `caro-game` · `arrival` · `expenses`).

- **Feature:** weather
- **Ưu tiên:** P1 (đợt "mở app mỗi ngày" 2)
- **Trạng thái:** 📋 Spec — chờ user duyệt
- **Tạo ngày:** 2026-10-20
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · gửi lời nhắc qua [`../care-message/`](../care-message/overview.md) · widget [`../widget-today/`](../widget-today/overview.md) (v1 không đụng) · vị trí "Nhà" [`../arrival/`](../arrival/overview.md) (phụ thuộc mềm, Phase 2) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị

- *Vấn đề người dùng:* Thảo ở Sài Gòn, Tuấn ở Hà Nội. 6 giờ chiều Tuấn mới đọc tin "em bị mắc mưa ở Quận 3, ướt hết rồi". Muốn quan tâm thì đã muộn. Muốn biết sớm thì phải mở app thời tiết, đổi sang thành phố của người ấy, đọc biểu đồ. Không ai làm việc đó mỗi sáng.
- *Số liệu PROD 2026-10-19* (`scripts/prod-retention-stats.js`): 80 cặp, 28 cặp đã ghép, 52 cặp còn chờ người ấy. Mỗi ngày 7–16 cặp có người mở app, 3–5 cặp cả hai trả lời câu hỏi, 8 cặp cả hai mở app mà không ai trả lời. Người ta mở app nhưng không có gì nhẹ nhàng để làm.
- *Giả thuyết giá trị:* sáng mở app thấy ngay một dòng "Chỗ Thảo · 31° · chiều nay mưa", bên cạnh nút "Nhắc mang ô". Chạm một lần là màn Quan tâm mở ra với lời soạn sẵn, bấm Gửi là xong. Thời tiết đổi mỗi ngày nên thẻ có lý do để nhìn mỗi ngày; nút gửi biến cái nhìn đó thành một hành động hướng về người ấy, và người ấy nhận push nguyên văn (care-message) nên cũng có lý do mở app.
- *Đối tượng:*
  - **Cặp đã ghép (28):** đủ giá trị, thấy cả hai nơi, có nút nhắc.
  - **Cặp đang chờ (52):** chỉ thấy thời tiết chỗ mình. Giá trị một người, nhỏ nhưng có, đủ để thẻ Home không trống.
  - **Cặp yêu xa (LDR):** nhóm hưởng lợi nhất. Danh sách có sẵn thành phố nước ngoài nơi người Việt hay học và làm việc (Seoul, Tokyo, Đài Bắc, Sydney…).
- *Đo bằng gì (metric):* xem §10.

## 2. Bối cảnh / nghiên cứu

### 2.1 Chọn nguồn dữ liệu (tra cứu điều khoản ngày 2026-10-20)

| Nguồn | Dùng thương mại | Giá | Ràng buộc chính | Kết luận |
|---|---|---|---|---|
| **MET Norway Locationforecast 2.0** | Được: dữ liệu theo NLOD 2.0 + CC BY 4.0, "Data produced by us is free to use" | 0 đ | Bắt buộc User-Agent định danh (thiếu → 403). App di động **không được gọi thẳng**, phải qua proxy có cache. Tôn trọng header `Expires`, dùng `If-Modified-Since`. Toạ độ tối đa 4 chữ số thập phân. ≤20 request/giây/ứng dụng. Ghi nguồn "Data from MET Norway". Không được dùng tên/logo Yr. | **CHỌN** |
| Open-Meteo | Gói miễn phí chỉ cho phi thương mại; app có quảng cáo hoặc thu phí là thương mại | Gói Standard khoảng 29/tháng (USD hoặc EUR tuỳ nguồn), 1 triệu lượt | CC BY 4.0 | Loại: freemium sắp tới sẽ phạm điều khoản gói miễn phí |
| Apple WeatherKit REST | Được | 500.000 lượt/tháng miễn phí theo tài khoản Apple Developer, sau đó từ 49,99 USD/tháng | REST dùng được từ máy chủ nên Android vẫn hưởng (qua CF). Bắt buộc hiện thương hiệu Apple Weather + link nguồn. Cần khoá ký JWT do chủ tài khoản tạo. | **Dự phòng** nếu spike chất lượng MET ở VN không đạt (D3) |
| OpenWeatherMap One Call 3.0 | Giấy phép API CC BY-SA (share-alike), khách doanh nghiệp đi theo hợp đồng riêng | 1.000 lượt/ngày miễn phí, vượt thì tính theo lượt | Phải gắn thẻ thanh toán | Loại: điều khoản thương mại không rõ, có rủi ro hoá đơn |

Nguồn: [MET Terms of Service](https://api.met.no/doc/TermsOfService) · [MET License](https://api.met.no/doc/License) · [MET Licensing and crediting](https://www.met.no/en/free-meteorological-data/Licensing-and-crediting) · [Locationforecast docs](https://api.met.no/weatherapi/locationforecast/2.0/documentation) · [Open-Meteo Terms](https://open-meteo.com/en/terms) · [Open-Meteo Pricing](https://open-meteo.com/en/pricing) · [Open-Meteo: API subscriptions for commercial use](https://openmeteo.substack.com/p/api-subscriptions-for-commercial) · [WeatherKit get started](https://developer.apple.com/weatherkit/get-started/) · [OpenWeather pricing](https://openweathermap.org/price).

### 2.2 Chi phí ước tính (MET qua Cloud Function, cache theo thành phố)

Số lần gọi MET **không tăng theo số user**, chỉ theo số thành phố đang được dùng: tối đa ~110 thành phố × làm mới ~1 lần/giờ ≈ 2.600 lượt/ngày, rất xa giới hạn 20 lượt/giây.

| Quy mô | Lượt gọi CF/tháng (giả định) | Firestore | Tiền |
|---|---|---|---|
| 165 user (~40 người mở app/ngày × 4 lần) | ~5.000 | ~10.000 đọc + ~70.000 ghi cache | 0 USD (trong hạn mức miễn phí Blaze) |
| 10.000 user (~3.000 người mở/ngày × 4 lần) | ~360.000 (hạn mức miễn phí 2 triệu) | ~720.000 đọc (miễn phí 1,5 triệu) + ~80.000 ghi | dưới 1 USD/tháng (chủ yếu băng thông CF tải ~100 KB/lượt từ MET) |

So sánh: Open-Meteo thương mại khoảng 29/tháng ngay từ ngày đầu; WeatherKit 0 USD tới 500.000 lượt.

### 2.3 Danh sách thành phố Việt Nam sau sáp nhập

Từ 1/7/2025 cả nước còn **34 tỉnh, thành** (28 tỉnh + 6 thành phố trực thuộc trung ương, Nghị quyết 202/2025/QH15; 11 địa phương giữ nguyên). Tỉnh mới rất rộng: Lâm Đồng nay gồm cả Đà Lạt (mát quanh năm) và Phan Thiết (nắng nóng). Chọn theo tỉnh thì thời tiết sai. ⇒ chọn theo **điểm thành phố**, hiển thị kèm tên tỉnh mới, tìm được bằng tên tỉnh cũ. Nguồn: [Luật Việt An, danh sách 34 tỉnh thành](https://luatvietan.vn/da-co-danh-sach-34-tinh-thanh-sau-khi-sap-nhap-hop-nhat.html) · [Thư viện Pháp luật](https://thuvienphapluat.vn/hoi-dap-phap-luat/danh-sach-34-tinh-thanh-cua-viet-nam-nam-2025-gom-nhung-tinh-nao-138053361.html).

### 2.4 Tái dùng trong app

- `care_message_screen.dart` + CF `notifyCareMessage`: gửi push nguyên văn + inbox. Chỉ cần thêm tham số điền sẵn.
- `cloud_functions` (đã có) cho callable; Node 22 có `fetch` sẵn nên CF không thêm package.
- `timezone` + `flutter_timezone` (đã có) để đổi giờ UTC của MET sang giờ thành phố.
- `NotificationTapRouter.pendingHomeFocus` để chạm thông báo cuộn tới thẻ.
- Khuôn rules "mỗi thành viên một doc" của `sleep/{uid}`.

## 3. Phạm vi (scope)

- **Trong phạm vi (v1):**
  - Mỗi người có **một thành phố** chọn tay từ danh sách có sẵn (~70 điểm VN + ~40 thành phố nước ngoài). **Không xin quyền vị trí.**
  - Mình chọn được thành phố cho người ấy nếu họ chưa tự chọn (D6).
  - **Thẻ Home "Thời tiết hai nơi"**: nhiệt độ hiện tại + một câu tình trạng còn lại trong ngày cho từng nơi, câu chênh lệch, nút gợi ý hành động khi chỗ người ấy mưa / nắng gắt / lạnh.
  - **Sheet chi tiết** khi chạm thẻ: 12 giờ tới mỗi nơi (3 giờ một mốc), cao/thấp hôm nay, giờ cập nhật, đổi thành phố, dòng ghi nguồn MET Norway.
  - **Nút gợi ý → màn Quan tâm điền sẵn** tiêu đề + nội dung, người dùng sửa được rồi gửi.
  - **Một thông báo local buổi sáng 07:30**, chỉ khi chỗ người ấy có mưa / nắng gắt / lạnh, tối đa 3 lần/tuần, tắt được.
  - 1 Cloud Function callable + cache Firestore, rules additive cho 1 subcollection, vi + en, °C.
- **Ngoài phạm vi (ghi roadmap):** widget hiện thời tiết · tìm thành phố tự do (geocoding) · lấy vị trí GPS / dùng "Nhà" của `arrival` · °F · cảnh báo thiên tai chính thức · chất lượng không khí (AQI) · dự báo nhiều ngày · lịch sử thời tiết · gợi ý decision-wheel theo thời tiết · push từ server.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý. Mục ghi *(PO tự chốt — user lật được)* user đổi được trước khi Dev bắt đầu.

- **D1 — Nguồn = MET Norway Locationforecast 2.0 `/compact`, gọi qua Cloud Function.** *Lý do:* dùng thương mại miễn phí (NLOD/CC BY), không cần API key, phủ toàn cầu; điều khoản của chính MET bắt app di động đi qua proxy có cache, trùng với yêu cầu "không để key ở client" và giúp số lượt gọi chỉ theo số thành phố. Open-Meteo loại vì gói miễn phí cấm thương mại.

- **D2 — Ghi nguồn bắt buộc:** dòng chữ nhỏ "Dữ liệu thời tiết: MET Norway" / "Weather data: MET Norway" có link `https://api.met.no/doc/License`, đặt ở sheet chi tiết và sheet chọn thành phố. Không dùng tên/logo "Yr". Icon do Designer chọn từ Iconsax (không bắt buộc dùng bộ icon MET). *Lý do:* CC BY yêu cầu ghi nguồn "ở chỗ hợp lý"; thẻ Home đã dày nên đặt ở lớp chạm vào là đủ.

- **D3 — Spike chất lượng trước khi làm UI** (Dev, ≤1 giờ): gọi MET cho Hà Nội, TP.HCM, Đà Nẵng 5 ngày liên tiếp, so "chiều nay mưa?" với thực tế/bản tin. Đúng ≥4/5 ngày ở mỗi nơi → làm tiếp. Không đạt → chuyển sang WeatherKit REST (cùng hợp đồng callable, chỉ đổi phần fetch trong CF; cần user tạo khoá WeatherKit, xem §11). *Lý do:* MET mạnh nhất ở Bắc Âu, ở VN chủ yếu dựa mô hình toàn cầu; mưa rào chiều nhiệt đới là thứ dễ sai nhất, mà nó lại là lý do chính của feature.

- **D4 — Chọn theo điểm thành phố, danh sách đóng gói sẵn trong app.** Mỗi mục: `id` (slug cố định, vd `vn-da-lat`, `kr-seoul`), `nameVi`, `nameEn`, `regionVi`/`regionEn` (tỉnh mới hoặc quốc gia), `lat`/`lon` (2 chữ số thập phân), `tz` (IANA), `aliases` (tên tỉnh cũ, tên không dấu, tên tiếng Anh). Ô tìm kiếm khớp không phân biệt dấu/hoa thường trên tên + aliases ("binh thuan" ra Phan Thiết · Lâm Đồng). Danh sách ở **Phụ lục A**. *Lý do:* tỉnh mới quá rộng (§2.3); danh sách đóng gói thì không cần API tìm kiếm, CF chỉ nhận id hợp lệ (chặn lạm dụng, D9). Thiếu thành phố → Phase 2 thêm tìm tự do.

- **D5 — Lưu ở `couples/{coupleId}/weather/{uid}`, chỉ lưu `cityId`.** Không lưu ở `users/{uid}` vì rules hiện chỉ cho chủ đọc (người ấy không đọc được). Không lưu tên/toạ độ (suy ra từ danh sách). *Lý do:* cùng khuôn `sleep/{uid}`; một doc một người, đọc 2 doc là đủ cho thẻ.

- **D6 — Mình chọn giúp được thành phố người ấy, nhưng không đè lựa chọn của chính họ.** Ai cũng ghi được doc của thành viên khác **khi** doc chưa có hoặc `setBy != uid` (người ấy chưa tự chọn). Người chủ luôn ghi đè được. *Lý do:* cặp yêu xa thường một người nhiệt tình, người kia ít vào app; bắt cả hai tự chọn thì thẻ nửa trống rất lâu. Chặn đè để tránh "anh đổi chỗ em sai rồi".

- **D7 — Dữ liệu cache theo thành phố, không theo user.** CF lưu `weatherCache/{cityId}` (chỉ Admin SDK đọc ghi). Làm mới khi quá `expiresAt` (= header `Expires` của MET, tối thiểu 30 phút), gửi kèm `If-Modified-Since`. Client giữ bản cuối ở Hive, gọi lại khi bản cũ hơn 30 phút lúc vào Home hoặc app quay lại nền trước. *Lý do:* điều khoản MET + chi phí §2.2.

- **D8 — CF trả số thô, client tự tính câu chữ.** CF trả nhiệt độ + mã thời tiết + lượng mưa theo giờ (UTC) cho 36 giờ tới; client đổi sang giờ thành phố và tính tình trạng theo §6.2, dịch qua ARB. *Lý do:* copy chỉ nằm ở ARB (cùng nguyên tắc widget-today D5), đổi ngưỡng không cần deploy CF.

- **D9 — CF chỉ nhận `cityId` có trong danh sách.** CF giữ bản JSON danh sách (`functions/weather_cities.json`), client giữ bản Dart sinh ra từ cùng nguồn; 1 test so 2 bản trùng id + toạ độ. Tối đa 2 id/lượt gọi. *Lý do:* user bất kỳ không thể bắt CF gọi MET cho toạ độ tuỳ ý (nguy cơ MET chặn User-Agent của mình).

- **D10 — Ngưỡng tình trạng** *(PO tự chốt, chỉnh được ở client, không cần deploy)*: **mưa** = có giờ nào `precipitation_amount` ≥ 0,5 mm/giờ hoặc `symbol_code` thuộc nhóm mưa/mưa rào/dông; **nắng gắt** = nhiệt độ cao nhất phần còn lại trong ngày ≥ 35°C; **lạnh** = thấp nhất ≤ 15°C hoặc có tuyết. Ưu tiên khi trùng: đang mưa > sắp mưa > nắng gắt > lạnh > (không có gì, chỉ hiện mô tả trời). *Lý do:* 35°C và 15°C là mốc bản tin VN vẫn gọi "nắng nóng", "rét đậm"; người dùng hiểu ngay.

- **D11 — Câu chênh lệch chỉ hiện khi lệch ≥ 5°C** (nhiệt độ hiện tại hai nơi). Cùng thành phố → "Cả hai cùng ở {city}" và chỉ hiện một cột. *Lý do:* lệch 2–3° không đáng nói; ít chữ trên Home.

- **D12 — Nút gợi ý chỉ hiện khi chỗ người ấy có mưa / nắng gắt / lạnh.** Ba nút: "Nhắc mang ô" · "Nhắc uống nước" · "Nhắc mặc ấm". Chạm → `openCareMessageScreen(context, initialTitle:, initialBody:)` (Dev thêm 2 tham số tuỳ chọn; mặc định giữ hành vi cũ). Không có tình trạng đáng nói → không có nút. *Lý do:* nút luôn hiện sẽ thành nhiễu; lời quan tâm có lý do cụ thể mới tự nhiên. Đi qua care-message nên không cần CF/rules/push mới.

- **D13 — Thông báo sáng: local, một id 1160, 07:30 giờ máy mình** *(PO tự chốt — user lật được: mặc định tắt?)*. Mặc định **BẬT** với cặp active đã có thành phố người ấy. Arm one-shot khi app mở, dùng dự báo đã có; chỉ arm nếu dự báo lấy ≤ 18 giờ trước giờ nổ và cửa sổ 07:30 → +14 giờ ở chỗ người ấy có mưa / nắng gắt / lạnh. Chặn spam: **tối đa 3 lần trong 7 ngày**, **không nổ cùng một tình trạng hai ngày liền** (đếm ở Hive). Tắt ở Cài đặt → Lời nhắc ("Thời tiết chỗ người ấy"). Chạm → Home, cuộn tới thẻ thời tiết (`pendingHomeFocus = 'weather'`). Cặp đang chờ: không nhắc. *Lý do:* mùa mưa Sài Gòn chiều nào cũng mưa; không có trần thì thành thông báo rác mỗi ngày. Local + dữ liệu đã có = 0 push nền, không đụng hạn mức đánh thức iOS. Không mở app từ hôm trước thì không có thông báo, chấp nhận (tự giới hạn, không bao giờ báo bằng dự báo cũ).

- **D14 — Không có push server, không `wakeClients`.** *Lý do:* thời tiết không phải việc người ấy làm; đánh thức nền tốn hạn mức iOS mà widget-today đang cần cho câu hỏi/tâm trạng/tin nhắn.

- **D15 — Widget v1 không hiện thời tiết, không thêm loại trạng thái cho widget-today.** *Lý do:* widget không tự gọi mạng được (WidgetKit/RemoteViews không có Firebase) nên số trên widget sẽ cũ; câu "người ấy vừa làm gì" của widget-today quan trọng hơn. Ghi roadmap Phase 3.

- **D16 — Offline / lỗi:** có bản cache ≤ 6 giờ → hiện bình thường kèm "Cập nhật 07:12". 6–24 giờ → hiện số mờ + "Số liệu lúc 07:12" và ẩn nút gợi ý (không nhắc mang ô bằng dự báo cũ). > 24 giờ hoặc chưa từng tải → thẻ hiện tên thành phố + "Chưa tải được thời tiết" + chạm để thử lại. CF trả `stale: true` khi MET lỗi mà còn cache cũ → client coi như bản theo `fetchedAt`. *Lý do:* thẻ không nhảy mất khi mạng chập chờn, nhưng cũng không nói sai.

- **D17 — Đơn vị °C cố định, số làm tròn số nguyên.** Mô tả trời vi/en theo ngôn ngữ app, map từ `symbol_code` của MET (bỏ hậu tố `_day`/`_night`/`_polartwilight`) về ~10 nhóm (§6.3). *Lý do:* user VN dùng °C; °F để Phase 3 nếu có người dùng ở Mỹ đòi.

- **D18 — Rời couple:** CF `notifyPartnerLeft` xoá `weather/{người rời}` (cạnh chỗ dọn `sleep`); couple bị xoá hẳn thì `recursiveDelete` hiện có lo. *Lý do:* người mới ghép vào không thấy thành phố của người cũ.

- **D19 — Lối vào UI là đề xuất, Designer chốt chung cả đợt.** Home đã dày (câu hỏi, tâm trạng, "Phân vân gì không?", giấc ngủ, chòm sao). Đề xuất của PO ở §6.1; Designer được phép gộp/thu gọn miễn giữ hành vi §6.

## 5. Mô hình dữ liệu, rules, Cloud Functions

### 5.1 Firestore

```
couples/{coupleId}/weather/{uid}          // MỚI — thành phố của từng thành viên
  cityId:    string 1..40                 // id trong danh sách (D4)
  setBy:     uid                          // ai chọn (chủ hoặc người ấy — D6)
  updatedAt: timestamp == request.time

weatherCache/{cityId}                     // MỚI — CHỈ Admin SDK (không có rule nào ⇒ client bị chặn mặc định)
  cityId, fetchedAt, expiresAt, lastModified (chuỗi header MET),
  hours: [{ t: epoch ms UTC, temp: number, symbol: string, rain: number (mm/giờ) }]   // 36 giờ tới
```

### 5.2 Phác rules (ADDITIVE — chỉ thêm khối mới trong `match /couples/{coupleId}`)

```
match /weather/{uid} {
  allow read: if isCoupleMember(coupleId);
  allow create, update: if isCoupleMember(coupleId)
    && request.resource.data.keys().hasOnly(['cityId', 'setBy', 'updatedAt'])
    && request.resource.data.cityId is string
    && request.resource.data.cityId.size() >= 1 && request.resource.data.cityId.size() <= 40
    && request.resource.data.setBy == request.auth.uid
    && request.resource.data.updatedAt == request.time
    && (uid == request.auth.uid
        || (uid in get(/databases/$(database)/documents/couples/$(coupleId)).data.memberIds
            && (resource == null || resource.data.get('setBy', '') != uid)));
  allow delete: if isCoupleMember(coupleId) && uid == request.auth.uid;
}
```
- Không đụng rule cũ nào; app 1.10.x/1.11.0 không biết subcollection này nên không bị ảnh hưởng.
- `weatherCache` không khai báo match ⇒ client mặc định bị chặn; CF dùng Admin SDK.
- Rules-test cần (≥12 case): người ngoài couple đọc/ghi bị chặn · thành viên đọc được doc người kia · ghi doc mình OK · ghi doc người ấy khi chưa có OK · ghi đè doc người ấy đã tự chọn (`setBy == uid`) bị chặn · ghi doc của uid không phải thành viên bị chặn · `setBy` giả bị chặn · `updatedAt != request.time` bị chặn · khoá thừa bị chặn · `cityId` rỗng / 41 ký tự bị chặn · xoá doc người ấy bị chặn · đọc/ghi `weatherCache` từ client bị chặn.

### 5.3 Cloud Functions

- **`getCityWeather`** (callable v2, us-central1, cần đăng nhập, không cần là thành viên couple vì chỉ trả dữ liệu công khai theo thành phố).
  - Vào: `{ cityIds: string[] }` (1–2 id, phải có trong `weather_cities.json`, sai → `invalid-argument` có message vi/en theo cơ chế `HttpsError` hiện có).
  - Mỗi id: đọc `weatherCache/{id}`; còn hạn → trả luôn; hết hạn → `fetch` `https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=..&lon=..` với `User-Agent: DearEmbeiu/<version> (https://dearembeiu.com)` + `If-Modified-Since`; 200 → rút gọn 36 giờ, ghi cache; 304 → chỉ dời `expiresAt`; lỗi/timeout 8 giây → trả cache cũ với `stale: true`, không có cache → `unavailable`.
  - Ra: `{ ok: true, cities: { [id]: { fetchedAt, stale, hours: [...] } } }`.
  - Không ghi inbox, không push, không `wakeClients`.
  - Tần suất: client tự chặn 30 phút/lần → ~4 lượt/người mở app/ngày (§2.2). Lượt gọi MET ≤ số thành phố × ~24/ngày.
- **`notifyPartnerLeft`** (đã có): thêm xoá `weather/{leaverUid}` (D18).
- Deploy: DEV khi Dev xong (Dev tự làm, có vết). **PROD chờ lệnh user**, gọi đích danh `functions:getCityWeather,functions:notifyPartnerLeft` + `firestore:rules`; rules PROD phải lên trước khi bản có feature live.

## 6. Hành vi UI (nội dung + trạng thái; Designer chốt hình)

### 6.1 Điểm vào (đề xuất)

1. **Thẻ Home "Thời tiết hai nơi"**: đề xuất đặt sát dưới thẻ đếm ngày / lời chào (đọc lướt buổi sáng), Designer chốt vị trí chung với 4 feature cùng đợt. Thẻ nhỏ, cao cỡ một `InkTile` đôi.
2. **Cài đặt → mục mới "Thời tiết"**: thành phố của mình · của người ấy · công tắc thông báo sáng (đặt ở nhóm Lời nhắc).
3. Chưa ai chọn thành phố: thẻ thu thành một dòng mời "Xem thời tiết chỗ người ấy" (chờ người ấy: "Xem thời tiết chỗ mình"), có nút ẩn. Ẩn rồi thì chỉ còn đường vào ở Cài đặt (cờ Hive, không đồng bộ).

### 6.2 Thẻ Home — các trạng thái

| Trạng thái | Nội dung |
|---|---|
| Đã ghép, cả hai có thành phố | Hai cột: "Mình · Hà Nội · 24° · Nhiều mây" và "Thảo · TP.HCM · 31° · Chiều nay mưa". Dòng dưới: câu chênh lệch (D11) hoặc nút gợi ý (D12), nút gợi ý ưu tiên hơn. |
| Cùng thành phố | Một cột: "Cả hai cùng ở Hà Nội · 24° · Chiều nay mưa" + nút "Nhắc mang ô" vẫn hiện (nhắc nhau vẫn có nghĩa). |
| Đã ghép, người ấy chưa có thành phố | Cột mình + ô "Thảo đang ở đâu? Chọn giúp" → sheet chọn thành phố cho người ấy. |
| Đã ghép, mình chưa có thành phố | Ô "Mình đang ở đâu?" + cột người ấy nếu có. |
| Cặp đang chờ người ấy | Chỉ cột mình. Không có câu chênh lệch, không có nút gợi ý. |
| Đang tải lần đầu | Khung xương (`ShimmerSkeleton`) cùng kích thước. |
| Offline / lỗi | Theo D16. |
| Qua 0:00 | Câu tình trạng tính lại theo giờ thành phố (dùng `MidnightBuilder` hoặc tính lúc build; không cần gọi mạng). |

**Câu tình trạng** (cửa sổ = từ bây giờ tới 23:59 giờ thành phố; nếu còn < 3 giờ thì nới tới 09:00 sáng mai):

| Tình trạng | vi | en |
|---|---|---|
| Đang mưa (giờ hiện tại) | Đang mưa | Raining now |
| Mưa trong 12:00–17:59 | Chiều nay mưa | Rain this afternoon |
| Mưa trong 18:00–23:59 | Tối nay mưa | Rain tonight |
| Mưa trước 12:00 | Sáng nay mưa | Rain this morning |
| Mưa sáng mai (cửa sổ nới) | Sáng mai mưa | Rain tomorrow morning |
| Nắng gắt | Nắng gắt, lên {max}° | Hot, up to {max}° |
| Lạnh | Lạnh, xuống {min}° | Cold, down to {min}° |
| Không có gì đặc biệt | mô tả trời §6.3 | sky text §6.3 |

**Câu chênh lệch:** "Chỗ {name} lạnh hơn {n}°" / "Chỗ {name} nóng hơn {n}°" · en "{n}° colder where {name} is" / "{n}° warmer where {name} is".

### 6.3 Mô tả trời (map `symbol_code` MET, bỏ hậu tố ngày/đêm)

| Nhóm | Mã MET | vi | en |
|---|---|---|---|
| quang | `clearsky`, `fair` | Trời quang | Clear |
| ít mây | `partlycloudy` | Ít mây | Partly cloudy |
| nhiều mây | `cloudy` | Nhiều mây | Cloudy |
| sương mù | `fog` | Có sương mù | Foggy |
| mưa nhỏ | `lightrain*`, `lightrainshowers*` | Mưa nhỏ | Light rain |
| mưa | `rain*`, `rainshowers*` | Có mưa | Rain |
| mưa to | `heavyrain*`, `heavyrainshowers*` | Mưa to | Heavy rain |
| dông | `*thunder*` | Có dông | Thunderstorms |
| tuyết / mưa tuyết | `*snow*`, `*sleet*` | Có tuyết | Snow |
| không rõ mã | (khác) | (ẩn mô tả, chỉ hiện nhiệt độ) | — |

### 6.4 Sheet chi tiết (chạm thẻ)

Mỗi nơi: tên + tỉnh/quốc gia · nhiệt độ hiện tại · cao/thấp hôm nay · 5 mốc 3 giờ một (giờ + icon + nhiệt độ) · "Cập nhật 07:12" · nút "Đổi thành phố". Cuối sheet: dòng ghi nguồn D2.

### 6.5 Sheet chọn thành phố

Ô tìm kiếm (không dấu, cả tên tỉnh cũ) · nhóm "Việt Nam" rồi "Nước ngoài" · mỗi dòng "Đà Lạt · Lâm Đồng" / "Seoul · Hàn Quốc" · tiêu đề đổi theo đối tượng: "Mình đang ở đâu?" / "{name} đang ở đâu?". Người ấy đã tự chọn → mình không mở được sheet cho họ (nút "Đổi" chỉ hiện ở cột của mình). Không tìm thấy → "Chưa có thành phố này. Chọn nơi gần nhất nhé." Dòng ghi nguồn D2.

### 6.6 Lời quan tâm điền sẵn (gửi đi nguyên văn — người dùng sửa được)

`{city}` = tên thành phố người ấy theo ngôn ngữ app của người gửi.

| Nút | Tiêu đề vi | Nội dung vi | Title en | Body en |
|---|---|---|---|---|
| Nhắc mang ô / Remind: umbrella | Nhớ mang ô nhé | {city} sắp mưa đó. Ra ngoài nhớ mang ô theo nha. | Take an umbrella | Looks like rain in {city}. Grab an umbrella if you head out. |
| Nhắc uống nước / Remind: water | Uống nước nhiều nha | {city} hôm nay lên tới {max}°. Ra đường nhớ che nắng, uống đủ nước nhé. | Stay hydrated | {city} is hitting {max}° today. Cover up in the sun and keep drinking water. |
| Nhắc mặc ấm / Remind: dress warm | Mặc ấm vào nhé | {city} xuống còn {min}° đó. Ra ngoài nhớ mặc thêm áo. | Dress warm | {city} is dropping to {min}°. Bring an extra layer when you go out. |

Tiêu đề ≤ 60, nội dung ≤ 200 (giới hạn care-message); tên thành phố dài nhất trong danh sách vẫn lọt.

### 6.7 Thông báo sáng (D13)

| Tình trạng | Tiêu đề vi | Nội dung vi | Title en | Body en |
|---|---|---|---|---|
| mưa | Hôm nay {city} có mưa | Nhắc {name} mang ô nhé? | Rain in {city} today | Remind {name} to take an umbrella? |
| nắng gắt | Hôm nay {city} lên {max}° | Nhắc {name} uống đủ nước nhé? | {city} hits {max}° today | Remind {name} to drink enough water? |
| lạnh | {city} xuống {min}° hôm nay | Nhắc {name} mặc ấm nhé? | {city} drops to {min}° today | Remind {name} to dress warm? |

Id **1160** (dải trống 1160–1179 giữa catch-up 1140–1159 và nhắc mời 1180–1189; ⚠️ Lead đối chiếu với các feature cùng đợt nếu họ cũng xin dải local). iOS 64 thông báo chờ: +1 slot. Huỷ khi: tắt công tắc · đăng xuất / rời couple / xoá tài khoản (thêm vào `cancelDailyQuestionSchedule()` hoặc chỗ huỷ chung) · người ấy bỏ thành phố.

## 7. Widget-today

Không thêm loại trạng thái ở v1 (D15). Không đụng kênh `dear_embeiu/widget`.

## 8. Analytics (không gửi tên thành phố, toạ độ, nhiệt độ, nội dung lời nhắc)

| Event | Params | Khi nào |
|---|---|---|
| `weather_city_set` | `who`: `self`\|`partner` · `region`: `vn`\|`intl` · `entry`: `card`\|`settings`\|`sheet` | Lưu thành phố |
| `weather_card_tap` | `state`: `both`\|`mine_only`\|`partner_only`\|`empty`\|`error` | Chạm thẻ |
| `weather_cta_tap` | `condition`: `rain`\|`hot`\|`cold` · `entry`: `card`\|`notification` | Chạm nút gợi ý (từ thông báo: khi mở app qua thông báo rồi chạm nút) |
| `weather_notif_toggle` | `enabled`: bool | Bật/tắt thông báo sáng |
| `care_message_sent` (đã có) | thêm `source`: `weather`\|`manual` | Gửi lời quan tâm (biết được bao nhiêu lời quan tâm sinh ra từ thời tiết) |

## 9. Acceptance criteria (kiểm trên 2 máy DEV `test3` / `test4`, cặp Tuấn ♥ Thảo)

- [ ] **Spike D3** có kết quả ghi trong `dev.md` (bảng 3 thành phố × 5 ngày), PO duyệt trước khi làm UI.
- [ ] Máy A chọn "Hà Nội" cho mình, "TP.HCM" cho B (B chưa chọn) → máy B mở app thấy thẻ có cả hai cột, cột B là TP.HCM, không cần làm gì.
- [ ] B tự đổi sang "Đà Lạt" → A thấy đổi trong ≤ 3 giây (realtime). A thử đổi thành phố của B lần nữa → không có nút "Đổi" ở cột B; ghi thẳng bằng rules-test thì bị chặn.
- [ ] Tìm "binh thuan" ra "Phan Thiết · Lâm Đồng"; "seoul" ra "Seoul · Hàn Quốc"; "xyz" ra câu không tìm thấy.
- [ ] Nhiệt độ hiện tại trên thẻ lệch ≤ 1°C so với gọi tay MET `/compact` cùng toạ độ cùng giờ; câu tình trạng đúng bảng §6.2 với dữ liệu giả (test Dart cho hàm tính tình trạng: 8 nhánh + cửa sổ nới sau 21:00 + ngưỡng 35/15 + mã lạ).
- [ ] Giả dữ liệu "chiều nay mưa" ở chỗ B → thẻ A hiện "Nhắc mang ô" → chạm → màn Quan tâm đã điền "Nhớ mang ô nhé" + nội dung có tên thành phố → sửa được → Gửi → B nhận push nguyên văn ≤ 10 giây + inbox; `care_message_sent{source: weather}` log.
- [ ] Trời bình thường ở chỗ B → không có nút gợi ý; lệch ≥ 5° → có câu chênh lệch; cùng thành phố → một cột.
- [ ] Cặp đang chờ (`test1`) → chỉ cột mình, không nút gợi ý, không thông báo sáng.
- [ ] Bật chế độ máy bay: cache 1 giờ → hiện số + "Cập nhật …"; chỉnh cache 10 giờ → số mờ, không nút gợi ý; xoá cache → "Chưa tải được thời tiết", chạm thử lại khi có mạng thì hiện số.
- [ ] Mở Home 10 lần trong 5 phút → chỉ 1 lượt gọi `getCityWeather` (log CF). Hai user cùng TP.HCM trong 30 phút → 1 lượt gọi MET (log CF).
- [ ] Gọi callable với `cityIds: ["fake"]` hoặc 3 id → `invalid-argument`; không đăng nhập → `unauthenticated`.
- [ ] Thông báo sáng: giả dữ liệu mưa, mở app tối hôm trước → `pendingNotificationRequests` có id 1160 lúc 07:30; tắt công tắc → mất; đã nổ 3 lần trong 7 ngày → không arm lần 4; hôm qua đã báo mưa → hôm nay mưa tiếp không arm; dự báo cũ hơn 18 giờ → không arm. Chạm thông báo → Home cuộn tới thẻ thời tiết.
- [ ] Rời couple → doc `weather/{người rời}` bị xoá (log CF `notifyPartnerLeft`); người ở lại thấy ô "đang ở đâu?" khi người mới ghép vào.
- [ ] Dòng ghi nguồn MET Norway có ở sheet chi tiết + sheet chọn thành phố, link mở được.
- [ ] vi + en đủ (thẻ, 2 sheet, Cài đặt, thông báo, lời điền sẵn, mô tả trời, tên thành phố); tên thành phố dài nhất + cỡ chữ lớn không tràn.
- [ ] `flutter analyze` 0; test Dart (tính tình trạng, map `symbol_code`, tìm không dấu, trần 3/tuần) PASS; test so 2 bản danh sách thành phố PASS; `scripts/test-firebase-rules.sh` PASS với ≥ 12 case §5.2; CF deploy DEV có vết; PROD chưa deploy.
- [ ] App 1.11.0 cùng couple với app mới → không lỗi, không thấy gì lạ (subcollection mới bị bỏ qua).
- [ ] Không regression Home (thứ tự thẻ, entrance, kéo làm mới), màn Quan tâm mở từ chỗ cũ (không tham số) vẫn trống như trước.
- [ ] `project/features/weather/` + `ROADMAP.md` + CLAUDE.md (§5 collections + CF, §6 dải 1160) cập nhật.

## 10. Metric đo thành công (30 ngày sau phát hành)

- **Kích hoạt:** ≥ 50% cặp đã ghép có cả hai thành phố (`weather/{uid}` × 2). Cặp đang chờ: ≥ 30% có thành phố của mình.
- **Hành động:** `care_message_sent{source: weather}` ≥ 1 lần/tuần ở ≥ 25% cặp đã kích hoạt; tỉ lệ `weather_cta_tap` → gửi thật ≥ 50%.
- **Thông báo sáng:** tỉ lệ tắt `weather_notif_toggle{enabled:false}` ≤ 15%; nếu cao hơn → hạ trần còn 2 lần/tuần hoặc chuyển mặc định tắt.
- **Mục tiêu đợt:** số cặp có người mở app mỗi ngày (`scripts/prod-retention-stats.js`, nền 7–16/28) — đo chung cả đợt, không tách riêng feature này được.

## 11. Rủi ro / nợ (Tester soi)

- 🔴 **Độ chính xác mưa ở VN** (D3). Báo "chiều nay mưa" mà nắng chang chang 3 lần là user mất tin. Spike trước; không đạt thì WeatherKit.
- 🟡 **Riêng tư:** thành phố là vị trí gần đúng gắn với tài khoản. Cần cập nhật privacy policy + App Store "App Privacy" (Location → Coarse Location, App Functionality, linked) + Play "An toàn dữ liệu" (Vị trí gần đúng). CF gửi MET chỉ toạ độ thành phố, không gửi uid/email.
- 🟡 Cặp yêu xa lệch múi giờ lớn (Mỹ): "hôm nay" trong thông báo sáng là 14 giờ tới ở chỗ người ấy, có thể rơi vào đêm của họ. Chấp nhận v1.
- 🟡 Danh sách đóng gói thiếu thành phố người dùng ở → chọn nơi gần nhất; đếm phản hồi để quyết Phase 2 tìm tự do.
- 🟡 Hai bản danh sách (Dart + JSON CF) lệch nhau → test D9 chặn.
- 🟡 MET đổi điều khoản/chặn User-Agent → CF trả cache cũ (`stale`), thẻ theo D16; đổi sang WeatherKit mất ~nửa ngày Dev.
- 🟡 Dải id local 1160 có thể trùng feature cùng đợt → Lead gộp.
- 🟢 Không push nền, không `wakeClients`, không tốn hạn mức iOS.

## 12. Giao việc 3 vai

- 🎨 **Designer:** vị trí thẻ (chốt chung cả đợt với poke/caro/arrival/expenses), thẻ đủ 8 trạng thái §6.2, sheet chi tiết, sheet chọn thành phố, nút gợi ý, mục Cài đặt, bộ icon mô tả trời (Iconsax); tra UI UX Pro Max, đối chiếu `project/design-system.md`. → *expect:* `design.md` + mock bấm thử.
- 💻 **Dev:** (0) spike D3; (1) `lib/data/weather_cities.dart` + `functions/weather_cities.json` từ Phụ lục A (toạ độ trung tâm thành phố, 2 chữ số thập phân) + test so khớp; (2) CF `getCityWeather` + cache + xoá trong `notifyPartnerLeft`; (3) rules + test; (4) `WeatherService` (callable + Hive) + `WeatherProvider` (watch `weather/{uid}` của 2 thành viên — wire ở `session_resolver`, nhớ named-param `_resolve`, clear khi sign-out) + hàm thuần tính tình trạng + test; (5) thẻ, 2 sheet, Cài đặt; (6) `openCareMessageScreen` thêm `initialTitle`/`initialBody`; (7) thông báo 1160 + trần + `focusWeather`; (8) analytics; (9) ARB + `gen-l10n`; (10) deploy DEV. → *expect:* analyze 0, test PASS, rules-test PASS, smoke 2 máy.
- 🧪 **Tester:** chạy §9; soi rules (đè lựa chọn người ấy, uid ngoài couple, `weatherCache`), lạm dụng callable, offline/cache 3 mức, qua 0:00, trần thông báo, mixed version 1.11.0. → *expect:* bảng PASS/FAIL trong `test.md`.

## 13. Câu hỏi cho user

1. ✅ [2026-10-20] **Riêng tư / store:** user **đồng ý** cập nhật privacy policy + khai "Coarse Location" (App Store Connect) + "Vị trí gần đúng" (Play) trước khi phát hành.
2. **Chỉ khi spike D3 thất bại:** chuyển sang Apple WeatherKit (miễn phí tới 500.000 lượt/tháng, phải hiện thương hiệu Apple Weather). Cần chủ tài khoản Apple Developer tạo khoá WeatherKit; Claude không tự tạo khoá được.

Còn lại PO tự chốt (đổi được trước khi Dev bắt đầu): D10 ngưỡng 35°/15°, D13 thông báo sáng mặc định bật + trần 3 lần/tuần.

## Phụ lục A — Danh sách thành phố v1

**Việt Nam** (63 thủ phủ tỉnh cũ, gắn tên tỉnh mới, + vài điểm du lịch). Mỗi dòng: Tên · Tỉnh mới (aliases tên tỉnh cũ nếu khác).
- Hà Nội · Hà Nội · TP.HCM · TP. Hồ Chí Minh (aliases: Sài Gòn, Saigon) · Thủ Dầu Một · TP. Hồ Chí Minh (Bình Dương) · Vũng Tàu · TP. Hồ Chí Minh (Bà Rịa–Vũng Tàu)
- Hải Phòng · Hải Phòng · Hải Dương · Hải Phòng (Hải Dương)
- Đà Nẵng · Đà Nẵng · Tam Kỳ · Đà Nẵng (Quảng Nam) · Hội An · Đà Nẵng (Quảng Nam)
- Huế · Huế · Cần Thơ · Cần Thơ · Sóc Trăng · Cần Thơ (Sóc Trăng) · Vị Thanh · Cần Thơ (Hậu Giang)
- Tuyên Quang · Tuyên Quang · Hà Giang · Tuyên Quang (Hà Giang)
- Lào Cai · Lào Cai · Yên Bái · Lào Cai (Yên Bái) · Sa Pa · Lào Cai
- Thái Nguyên · Thái Nguyên · Bắc Kạn · Thái Nguyên (Bắc Kạn)
- Việt Trì · Phú Thọ · Vĩnh Yên · Phú Thọ (Vĩnh Phúc) · Hoà Bình · Phú Thọ (Hoà Bình)
- Bắc Ninh · Bắc Ninh · Bắc Giang · Bắc Ninh (Bắc Giang)
- Hưng Yên · Hưng Yên · Thái Bình · Hưng Yên (Thái Bình)
- Ninh Bình · Ninh Bình · Phủ Lý · Ninh Bình (Hà Nam) · Nam Định · Ninh Bình (Nam Định)
- Đông Hà · Quảng Trị · Đồng Hới · Quảng Trị (Quảng Bình)
- Quảng Ngãi · Quảng Ngãi · Kon Tum · Quảng Ngãi (Kon Tum)
- Pleiku · Gia Lai · Quy Nhơn · Gia Lai (Bình Định)
- Nha Trang · Khánh Hoà · Phan Rang · Khánh Hoà (Ninh Thuận)
- Đà Lạt · Lâm Đồng · Gia Nghĩa · Lâm Đồng (Đắk Nông) · Phan Thiết · Lâm Đồng (Bình Thuận)
- Buôn Ma Thuột · Đắk Lắk · Tuy Hoà · Đắk Lắk (Phú Yên)
- Biên Hoà · Đồng Nai · Đồng Xoài · Đồng Nai (Bình Phước)
- Tây Ninh · Tây Ninh · Tân An · Tây Ninh (Long An)
- Vĩnh Long · Vĩnh Long · Bến Tre · Vĩnh Long (Bến Tre) · Trà Vinh · Vĩnh Long (Trà Vinh)
- Cao Lãnh · Đồng Tháp · Mỹ Tho · Đồng Tháp (Tiền Giang)
- Cà Mau · Cà Mau · Bạc Liêu · Cà Mau (Bạc Liêu)
- Long Xuyên · An Giang · Rạch Giá · An Giang (Kiên Giang) · Phú Quốc · An Giang (Kiên Giang)
- Giữ nguyên tỉnh: Lai Châu · Điện Biên Phủ (Điện Biên) · Sơn La · Lạng Sơn · Cao Bằng · Hạ Long (Quảng Ninh) · Thanh Hoá · Vinh (Nghệ An) · Hà Tĩnh

**Nước ngoài** (nơi người Việt hay học, làm việc; tên vi theo cách gọi quen):
- Hàn Quốc: Seoul · Busan · Incheon · Daegu
- Nhật Bản: Tokyo · Osaka · Nagoya · Fukuoka · Saitama
- Đài Loan: Đài Bắc · Đài Trung · Cao Hùng · Đào Viên
- Đông Nam Á: Singapore · Kuala Lumpur · Bangkok · Phnom Penh · Viêng Chăn
- Trung Quốc: Bắc Kinh · Thượng Hải · Quảng Châu · Hồng Kông
- Úc / NZ: Sydney · Melbourne · Brisbane · Adelaide · Perth · Auckland
- Châu Âu: London · Manchester · Paris · Berlin · Frankfurt · München · Praha · Warszawa · Moskva · Amsterdam · Helsinki
- Bắc Mỹ: Toronto · Vancouver · Montréal · Los Angeles · San Jose · Houston · Seattle · New York · Boston · Chicago
- Trung Đông: Dubai

Thêm/bớt thành phố = sửa 2 file danh sách + test khớp; `id` đã phát hành **không được đổi**.

## 14. Changelog feature
- [2026-10-20] [PO] Tạo feature trong đợt "mở app mỗi ngày" lần 2 (user chọn cùng poke · caro-game · arrival · expenses). Tra điều khoản 4 nguồn: chọn MET Norway qua CF (thương mại miễn phí, app phải đi qua proxy), Open-Meteo loại vì gói miễn phí cấm thương mại, WeatherKit làm dự phòng. Kiểm 34 tỉnh thành sau sáp nhập → chọn theo điểm thành phố (63 thủ phủ cũ + điểm du lịch + ~45 thành phố nước ngoài). Chốt D1–D19: lưu `couples/{id}/weather/{uid}`, chọn giúp người ấy nhưng không đè, cache theo thành phố, client tính câu chữ, nút gợi ý đi qua care-message, thông báo sáng local id 1160 trần 3 lần/tuần, không push nền, widget để sau. Chờ user duyệt + 2 câu hỏi §13.
- [2026-10-20] [Lead] User đồng ý sửa privacy policy + khai báo vị trí gần đúng. Câu 2 (WeatherKit) chỉ hỏi lại nếu spike MET thất bại.
- [2026-10-20] [Lead] Chốt câu hỏi Designer: giờ báo sáng giữ cố định 07:30 như D13 (bỏ hàng "Giờ báo" trong Cài đặt); thẻ hai người trên Home thống nhất **bạn bên trái, người ấy bên phải** (theo thẻ Đêm qua đang chạy) và nhãn làn của mình là "Bạn" (`sleepYou`) — Designer ghép Home áp cho cả weather + arrival; nhận các lệch spec có chủ ý ở design.md §13 (nút gợi ý trong sheet chi tiết, "Từ giờ tới khuya", dòng "Tỉnh cũ", công tắc trong mục Thời tiết).
- [2026-10-20] [Lead] Chốt câu hỏi sau vòng soát dễ dùng: (1) nhãn nút gọi tên người ấy "Nhắc Thảo mang ô / uống nước / mặc ấm" (thay D12 "Nhắc mang ô") — rõ là nhắc cho ai; (2) chạm thông báo sáng mở thẳng màn Quan tâm đã điền sẵn (1 chạm, thay D13 "về Home cuộn tới thẻ") — đúng việc thông báo đang mời làm; (3) bản EN trên thẻ dùng tên ngắn (vd "HCMC"), sheet chi tiết hiện đủ tên — thêm field tên ngắn EN cho thành phố dài.
- [2026-10-20] [Lead] User-Agent gửi MET chỉ ghi website `https://dearembeiu.com`, bỏ email (MET chấp nhận website; không gửi email ra dịch vụ ngoài khi không cần). Spike D3 không chặn UI: nguồn dữ liệu nằm sau CF, MET không đạt thì đổi sang WeatherKit mà thẻ không đổi; spike chạy song song khi có bản DEV.
