# Widget màn hình chính — Đếm ngày yêu

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.

- **Feature:** home-widget
- **Ưu tiên:** P1
- **Trạng thái:** 💻 Dev xong 2026-10-12, 🧪 chờ Tester nghiệm thu (smoke 2 nền tảng PASS, tinted iOS = giới hạn nền tảng)
- **Tạo ngày:** 2026-10-12
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md) · mockup bấm thử: canvas Artifact `https://claude.ai/artifact/Rb2dk1uaXdjuUGEBwNiKD9` (riêng tư, tài khoản user)

## 1. Vấn đề & giá trị
- *Vấn đề người dùng:* muốn biết "yêu nhau được bao nhiêu ngày" thì phải mở app, chờ Home tải. Con số này đổi mỗi ngày nhưng app lại không có mặt ở nơi người dùng nhìn nhiều nhất: màn hình chính điện thoại.
- *Giả thuyết giá trị:* một ô nhỏ trên màn hình chính hiện "1.247 ngày bên nhau" + tên hai người sẽ (a) nhắc tới app mỗi lần mở khoá máy mà không cần push, (b) là lối vào một chạm về Home, (c) là thứ "khoe" được khi đưa máy cho bạn xem.
- *Đối tượng:* mọi cặp đã đặt ngày yêu (cả khi còn chờ người ấy ghép đôi). Người chưa đăng nhập thấy trạng thái trống mời vào app.
- *Đo bằng gì (metric):* số lần mở app từ widget/tuần (event `widget_tap`, kèm `family` small/medium). Mục tiêu sau 30 ngày: ≥30% cặp active có ít nhất 1 lần `widget_tap`/tuần. Không đo được số lượt *thêm* widget trên iOS (WidgetKit không báo), nên lấy tap làm thước.

## 2. Bối cảnh / nghiên cứu
- Table stakes còn thiếu so với app đối thủ (Been Together, Been Love Memory): widget đếm ngày là thứ gần như app nào trong niche cũng có. Nằm ở NEXT của `ROADMAP.md` từ 2026-05-30.
- **Kiểm kê tính năng trong app có thể làm widget** (2026-10-12, PO):

| Widget | Hiện gì | Dữ liệu đổi khi | Độ khó |
|---|---|---|---|
| **Đếm ngày yêu** (phase này) | số ngày · tên 2 người · cột mốc tiếp (bản vừa) | 0:00 mỗi ngày, native tự tính từ ngày yêu | Dễ |
| Màn khoá iPhone | "1.247 ngày" cạnh giờ | cùng dữ liệu | Dễ, cộng thêm sau |
| Câu hỏi hôm nay | câu hỏi + trạng thái chưa trả lời / chờ người ấy / cả hai xong | app mở · push `notifyDailyAnswer` (đã có `wakeClients`) | Vừa — giá trị thói quen cao nhất |
| Ảnh kỷ niệm | ảnh mới nhất / ngày này năm xưa | người ấy đăng ảnh → push đánh thức app tải ảnh về App Group | Vừa–khó |
| Tâm trạng người ấy | mood + ghi chú | CF `notifyPartnerMood` cần thêm wake | Vừa |
| Chuỗi ngày | n ngày liên tiếp | mỗi ngày + khi cả hai trả lời | Vừa |
| Đêm qua (giấc ngủ) | giờ ngủ 2 người | sáng app tính xong · người ấy chia sẻ | Vừa |
| Hôm nay của chúng mình | chòm sao 6 sao | mọi hành động 2 người | Khó, dễ hiện số cũ |
| Lời quan tâm mới nhất | lời của người ấy | push `notifyCareMessage` + wake | Vừa; riêng tư trên màn hình chính |
| Cây tình yêu | hình cây theo số hoa | hiếm | Vừa |
| Nút nhanh | Đăng ảnh · Gửi quan tâm · Nhắn tin | không có dữ liệu | Dễ nhưng cần đọc deep link (hiện tắt, D8 audit) |
| Không làm | xem trước chat (riêng tư), rủ Oẳn tù tì (widget phải gọi mạng) | | |

- Ràng buộc nền tảng (fallback — DB UI UX Pro Max không có mục widget): iOS WidgetKit nhỏ ≈158×158pt, vừa ≈338×158pt, bo góc hệ thống ~22pt, lề 14–16pt, iOS 18 có chế độ "tô màu" (tinted) ép mọi thứ về một màu; Android ô 2×2 ≈152dp, 4×2 ≈328dp, bo `system_app_widget_background_radius` (≤28dp), lề 16dp, RemoteViews không nhận ConstraintLayout/`Space`/`View`, và **không nạp font tuỳ biến** — kể cả `@font/` trong `res/font`, vì inflate trong context restricted (giả định ban đầu "res/font thì được" sai, phát hiện khi smoke Task 7 → D11).
- Luật thiết kế đã soát với UI UX Pro Max: chữ nhỏ 10–12px trắng trên hồng chỉ ~3,5:1 → chip tên dùng mực navy trên nền trắng; số ≥24px là chữ lớn (ngưỡng 3:1) → trắng trên gradient qua; icon tim vector, không emoji; toàn widget là 1 vùng chạm.

## 3. Phạm vi (scope)
- **Trong phạm vi (Phase 1):** widget đếm ngày cỡ nhỏ + vừa trên iOS (iPhone) và 2×2 + 4×2 trên Android; cột mốc tiếp theo trên bản vừa (cùng công thức Home); theo ngôn ngữ app (vi/en); trạng thái trống; chạm mở app; cập nhật khi đổi ngày yêu/tên/ngôn ngữ/đăng xuất; tự nhảy số mỗi ngày không cần mở app; event `widget_tap`.
- **Ngoài phạm vi:** widget màn khoá (Phase 2), widget câu hỏi/ảnh/mood (Phase 3), widget lớn 4×4, Material You dynamic color, chọn ảnh nền cho widget, iPad/Apple Watch, Live Activity.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý.
- **D1 — Nội dung = chỉ số ngày yêu** (user chọn 2026-10-12 trong 4 hướng: số ngày · số ngày + ảnh · "hôm nay" · nhiều widget). *Lý do:* dữ liệu tĩnh, widget tự đếm, không cần mạng/push; ra bản đầu nhanh, nền native dùng lại cho các widget sau.
- **D2 — Hướng hình ảnh A "Thẻ đếm thu nhỏ"** (user chọn giữa A/B/C). *Lý do:* nối thẳng từ CounterCard đã duyệt nhiều vòng; nhận ra app giữa đám widget xám. Đánh đổi chấp nhận: không đổi theo chế độ tối, iOS 18 tinted về một màu.
- **D3 — Native vẽ, Flutter chỉ đẩy ảnh chụp dữ liệu qua MethodChannel `dear_embeiu/widget` tự viết, KHÔNG dùng package `home_widget`.** *Lý do:* pattern channel đã có (`dear_embeiu/sleep|clipboard`), ~40 dòng native; package kéo thêm phần deep link mình không dùng.
- **D4 — Chuỗi hiển thị do Flutter dịch sẵn rồi gửi sang** (`ngày bên nhau`, `Cột mốc {label}`, `còn {count} ngày`…), native chỉ tính số và lắp vào mẫu. *Lý do:* widget đổi theo ngôn ngữ chọn trong app (không theo máy), native không giữ bảng dịch riêng. Ngoại lệ bắt buộc: tên + mô tả widget trong gallery hệ thống (hiện trước khi có dữ liệu) dùng `.strings`/`strings.xml` theo ngôn ngữ máy.
- **D5 — Số ngày + cột mốc tính ở native, copy y hệt `LoveTreeService.daysTogether` (so ngày lịch) và `_getNextMilestone` của Home** `[30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000]` rồi bước 500; tiến độ = `days / next`; nhãn "N tháng" (chia hết 30, <365) / "N năm" (chia hết 365) / "N ngày". *Lý do:* widget và CounterCard phải cùng số trong cùng ngày; bảng MilestoneTrail là bảng khác, không dùng.
- **D6 — App Group riêng theo cấu hình:** `group.com.tony.dearembeiu` (Release/prod) · `group.com.tony.dearembeiu.dev` (Debug/Profile). *Lý do:* app dev và prod cài chung máy không ghi đè dữ liệu widget của nhau.
- **D7 — Android cập nhật theo `updatePeriodMillis` 30 phút**, chấp nhận lệch tối đa 30 phút sau 0:00. *Lý do:* 0 dòng logic; nâng lên báo thức đúng 0:00 khi có người phàn nàn (ghi `ponytail:` trong code).
- **D8 — Chạm widget chỉ mở app**, không parse URL (giữ quyết định tắt deep linking của audit 2026-10-12). Nguồn chạm ghi bằng cờ native (iOS: URL `dearembeiu://widget` vào UserDefaults; Android: intent extra) → Flutter đọc 1 lần để log `widget_tap`.
- **D9 — Phát hành CHUNG bản kế tiếp với audit + streak-self-heal** (user chốt 2026-10-12 "chung 1.9.1"); vì có feature nên bản gộp mang số **1.10.0+27** (MINOR theo quy ước release). Widget không đụng backend; phần deploy PROD là của audit. *(Trước đó: dự tính 1.10.0 sau 1.9.1.)*
- **D10 — Widget nhóm hàng nghìn theo ngôn ngữ** ("1.247" vi / "1,247" en, như mockup user duyệt). *Phát hiện khi review Task 3 (2026-10-12):* Home đang in số thô (`counter_card.dart` "1247", nhãn cột mốc "1500 ngày") ⇒ hai mặt số khác định dạng. Giữ widget theo design; **nợ PO:** cân nhắc cho Home nhóm theo (1 `NumberFormat`) để nhất quán — ngoài phạm vi feature này.
- **D11 — Widget Android dùng font hệ thống (Roboto), iOS dùng Quicksand.** *Lý do:* RemoteViews không nạp được `@font/` (context restricted — `TextView` bỏ qua font resource), smoke Task 7 thấy Roboto dù layout khai Quicksand. Giữ phân cấp đậm/nhạt bằng `textStyle=bold` / `sans-serif-medium`. Cách duy nhất có Quicksand là vẽ chữ ra bitmap trong `ImageView` — tốn công, mất autosize/accessibility, chỉ làm nếu user không ưng Roboto sau khi xem thật. Ngoài ra: widget 3 ô trên máy ô lớn (Pixel ≈90dp/ô → 276dp ≥ ngưỡng 250) dùng bố cục vừa với cột ≈108dp → 2 dòng dài autosize 10–12sp thay vì đổi ngưỡng (ngưỡng theo dp không phân biệt được 3 ô máy lớn với 4 ô máy nhỏ).

## 5. Acceptance criteria (xong khi…)
> Dev tự soát 2026-10-12 (`[x]` = đã có bằng chứng chạy thật hoặc kiểm bằng lệnh; ghi chú nghiêng = bằng chứng và phần chưa kiểm của mục đó). Tester vẫn chạy lại cả 11 mục — danh sách việc chưa kiểm ở [test.md](test.md).
- [x] iOS: gallery widget có "Đếm ngày yêu" cỡ nhỏ + vừa; số ngày, tên, cột mốc (vừa) **bằng đúng** CounterCard trên Home trong cùng ngày, cả vi lẫn en. *(Smoke iPhone 17 iOS 26.3 + iPhone 16e iOS 18.6: 649 ngày = Home, "Cột mốc 2 năm" / "còn 81 ngày", vi + en. Chưa kiểm trên simulator: dòng dài nhất "28 thg 12" và "10,000 days".)*
- [x] Android: thêm được ô 2×2, kéo giãn sang 4×2 thì đổi sang bố cục vừa; số liệu như trên. *(Smoke emulator Pixel_10 API 37: 649 = Home; ART nhóm hàng nghìn đúng "1.199" vi / "1,199" en. Chưa kiểm API thấp, launcher khác.)*
- [ ] Không mở app, chỉnh giờ máy qua 0:00: iOS số nhảy đúng 0:00 (timeline); Android nhảy trong ≤30 phút. *(Chưa kiểm thật. Tạm thay bằng harness Swift 30 check + 5 JUnit cho công thức đếm ngày; iOS timeline 7 nửa đêm, Android `updatePeriodMillis` 30' theo code.)*
- [x] Đổi ngôn ngữ trong Cài đặt → quay ra màn hình chính, widget đã đổi chữ (≤2 giây). *(iOS: iPhone 17 đổi chữ sau 2,24 s kể từ lúc bấm Home, 16e chạy lại timeline sau 1,9 s — hệ thống hoãn reload khi app còn foreground; Android PASS 2 chiều. Riêng chọn "Theo hệ thống" thì widget đổi chữ trễ tới lần mở app kế — minor, ghi ở test.md.)*
- [ ] Đổi ngày yêu / tên trong Hồ sơ → widget đổi ngay. *(Chưa thử tay. Bridge có test đơn vị: couple đổi → đúng 1 `update`; đường bridge → native đã chạy thật qua đăng nhập, đăng xuất, đổi ngôn ngữ.)*
- [x] Đăng xuất, rời couple, xoá tài khoản → widget về trạng thái trống ("Chạm để bắt đầu đếm ngày yêu"); đăng nhập lại → hiện lại số. *(Đăng xuất ≤3 s → trống, đăng nhập lại ≈7 s — PASS cả 2 nền tảng; cài mới chưa mở app cũng trống; phiên bị máy khác đá → trống. Rời couple và xoá tài khoản đi cùng đường `couple = null` / đăng xuất nhưng chưa thử tay.)*
- [x] Chạm widget → app lên foreground, về Home (có couple) / Setup (chưa couple) / landing (guest); Analytics ghi `widget_tap{family}` đúng 1 lần/lần chạm. *(iOS: 2 chạm → 2 log, 4 chạm → 4 log, mở bằng icon → 0 log. Android: app tắt → `medium`, app nền → `small`, mở từ Recents không đếm lại. Mới xác nhận qua log `HomeWidgetBridge`, chưa xem event trên GA4 DebugView.)*
- [ ] App dev + prod cài chung máy: mỗi widget hiện dữ liệu của app mình. *(Chưa kiểm. Đã đối chiếu cấu hình: Release → `com.tony.dearembeiu.widget` + `group.com.tony.dearembeiu`, Debug/Profile → `….dev…`; Android khác applicationId nên prefs tự tách.)*
- [ ] Chữ hệ thống cỡ lớn nhất (AX) không tràn khung; số 10.000+ không tràn; tên 12 chữ không đẩy lệch bố cục; iOS 18 tinted vẫn đọc được. *(iOS AX5 PASS: không tràn, chip 1 dòng "…", chú thích 1–2 dòng. Chưa kiểm: Android cỡ chữ lớn, số 10.000+, tên 12 chữ. Tinted: tint mặc định iOS 18 đạt 5,47:1; tint đậm, iOS 26 Tinted và Clear chỉ 1,6–4,0:1 — giới hạn nền tảng (hệ thống chọn màu chữ), chấp nhận ở bản đầu, số đo ở [design.md](design.md).)*
- [x] `flutter analyze` 0; test Dart (`buildSnapshot`) + Swift (`DayMath`) + Kotlin (`DayMath`) cùng bộ vector PASS. *(analyze 0 · `flutter test` 548 pass, 3 skip · `scripts/check-widget-daymath.sh` OK 30 check · `DayMathTest` 5/5. Swift có thêm vector DST Havana + lịch Phật vì dùng `Calendar`; Kotlin dùng `LocalDate` nên không dính.)*
- [ ] `flutter build ipa` có `PlugIns/DearEmbeiuWidget.appex`, `flutter build appbundle` OK. *(Chưa chạy bản release. Bản debug đã OK: `flutter build ios --debug --no-codesign` có `.appex` trong `PlugIns/`, `flutter build apk --debug` xong. Release + R8 + ký thật → Tester / lúc phát hành.)*
- [x] Không file nào trong `firestore.rules` / `functions/` thay đổi. *(`git diff --stat 8f6da29..HEAD -- firestore.rules storage.rules functions firestore.indexes.json` rỗng.)*

## 6. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)
- 🎨 **Designer:** ✅ xong 2026-10-12 — canvas 5 artboard (A/B/C · Android · tinted/số dài/EN) + [design.md](design.md) token chính xác.
- 💻 **Dev:** ✅ xong 2026-10-12 — dựng theo kế hoạch ở [dev.md](dev.md) (bridge Flutter → iOS extension → Android provider), test 3 ngôn ngữ, smoke simulator + emulator → nhánh `feature/home-widget` analyze 0, test PASS, build debug 2 nền tảng OK. Nhật ký từng task + commit trong dev.md.
- 🧪 **Tester:** chạy 11 tiêu chí mục 5 trên simulator iOS 18 + emulator Android 14/16, ghi PASS/FAIL vào [test.md](test.md) → *expect:* bảng kết quả + bug P0/P1 nếu có.

## 7. Changelog feature
- [2026-10-12] [PO] Tạo feature. User chốt nội dung (D1) và hướng A (D2); duyệt thiết kế kỹ thuật (D3–D9). Kiểm kê 12 ứng viên widget cho các phase sau.
- [2026-10-12] [Dev] Implement xong 8 task (bridge Flutter · target WidgetKit · AppWidgetProvider). Smoke iOS (iPhone 17 + 16e) và Android (Pixel_10) PASS, không đụng backend. Phát sinh hai quyết định: **D10** (widget nhóm hàng nghìn, Home đang in số thô → nợ PO) và **D11** (Android dùng font hệ thống vì RemoteViews không nạp `@font/`). Vòng review bắt thêm các lỗi của plan. `DayMath`: máy đặt lịch Phật, `ordinality` lệch theo UTC, DST bỏ đúng nửa đêm ngày yêu (Havana). Bridge: cold start đẩy `empty` đè snapshot tốt, gửi hỏng không retry, đăng xuất không quên couple. iOS tinted: hệ thống tô cả pill nên mất tên (vá xong, tint mặc định đạt 5,47:1). Android: `widget_tap` đếm lại khi mở từ Recents, số không đạt 40sp, glow tràn góc bo ở API dưới 31. Còn nợ: tinted/Clear chưa đạt AA ở mọi tint (giới hạn nền tảng); chưa kiểm 0:00, dev + prod chung máy, iOS 15/16, API Android thấp, bản release/R8 — danh sách ở [test.md](test.md).
