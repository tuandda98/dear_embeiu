# App Check (chống lạm dụng backend)

> File PO sở hữu. Nguồn sự thật chung cho cả feature.

- **Feature:** app-check
- **Ưu tiên:** P1
- **Trạng thái:** 🛠 Dev xong (client) · ⏳ chờ ship + chờ đủ độ phủ mới enforce
- **Tạo ngày:** 2026-09-26
- **Liên quan:** [dev.md](dev.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md) §5

> Không có `design.md` / `test.md`: feature KHÔNG có UI và không có luồng người dùng để nghiệm thu thủ công — nghiệm thu bằng metrics ở Firebase Console (tab App Check → APIs).

## 1. Vấn đề & giá trị
- *Vấn đề:* Firestore rules chỉ trả lời "user này được đọc gì", KHÔNG trả lời "cái đang gọi có phải app mình không". Bất kỳ ai có token đăng nhập hợp lệ đều có thể gọi thẳng REST API bằng script.
- *Rủi ro cụ thể, xếp theo mức thiệt hại:*
  1. **CF `generateDailyQuestion` tốn tiền thật** — mỗi lần gọi là 1 request Anthropic `claude-opus-5` (~0,02 USD/cặp/ngày ở mức bình thường). Script gọi lặp = hoá đơn tăng không trần.
  2. **Storage `couple_photos/`** — dung lượng ghi <10MB/file, không giới hạn số file ⇒ có thể bị dùng làm chỗ lưu trữ miễn phí.
  3. **Firestore** — scrape/ghi rác từ client giả mạo.
- *Bối cảnh:* PROD từng chết billing 2,5 ngày (09-09→09-11). Chi phí backend đang là điểm yếu thật, không phải lo xa.
- *Đo bằng gì:* tỉ lệ request **Verified** ở Firebase Console → App Check → tab APIs (mỗi API có biểu đồ verified / unverified).

## 2. App Check hoạt động thế nào
App gọi provider chứng thực của NỀN TẢNG → lấy token → đính vào mọi request Firebase. Backend Google kiểm token trước khi tới rules.
- **iOS** = App Attest (Apple, cần iOS 14+; app min 15.0 ⇒ luôn dùng được).
- **Android** = Play Integrity (Google Play, cần app cài từ Play và SHA-256 khớp).
- **Debug/profile** = debug provider (token do máy dev sinh, phải dán tay vào console).

Hai chế độ mỗi API:
- **Unenforced** — vẫn nhận request thiếu token, chỉ ghi nhận metrics. **Đây là trạng thái hiện tại.**
- **Enforced** — request thiếu/sai token bị CHẶN ở tầng Google, rules không chạy tới.

## 3. Phạm vi
- **Trong phạm vi:** client gửi token (Firestore/Storage/Functions/Auth), đăng ký app ở Firebase Console PROD, giữ Unenforced.
- **Ngoài phạm vi (làm sau):** bật Enforce; App Check cho Cloud Functions (phải tự kiểm `request.app` trong `functions/index.js`); project DEV; entitlement App Attest cho iOS.

## 4. Quyết định đã chốt (decision log)
- **D1 — KHÔNG enforce trong đợt này.** *Lý do:* 100% user đang chạy ≤1.7.0 (chưa có SDK App Check). Bật Enforce = chặn sạch toàn bộ người dùng đang live. Chỉ enforce sau khi bản có App Check đã phủ gần hết user (theo dõi biểu đồ verified ở tab APIs).
- **D2 — Client fail-open tuyệt đối.** *Lý do:* lỗi App Check không được phép làm hỏng cold start. `_activateAppCheck()` có try/catch riêng, KHÔNG làm `isFirebaseReady` thành false.
- **D3 — Đăng ký CẢ 2 fingerprint Android** (app signing key của Play + upload key). *Lý do:* bản cài từ Play ký bằng app signing key; bản `flutter build apk --release` cài tay ký bằng upload key — có cả hai thì test local cũng ra token hợp lệ.
- **D4 — KHÔNG thêm entitlement `com.apple.developer.devicecheck.appattest-environment`.** *Lý do:* App Attest mặc định đã dùng môi trường production cho bản phát hành qua App Store/TestFlight; thêm entitlement là thêm rủi ro hỏng ký IPA (máy này vốn đã hay kẹt signing). Chỉ thêm nếu metrics iOS cho thấy token fail.
- **D5 — KHÔNG động vào project DEV.** *Lý do:* DEV cũng Unenforced, debug build thiếu token không ảnh hưởng gì. Cấu hình debug token khi nào thật sự cần test App Check.
- **D6 — Bỏ qua 2 app `com.tony.ninhvoiu`** (dự án Nịnh Vợ Iu đã chết — user chốt 2026-09-26).

## 5. Acceptance criteria
- [x] `firebase_app_check` có trong pubspec, `flutter analyze` sạch, test Dart pass.
- [x] Client activate App Check ngay sau `Firebase.initializeApp()`, fail-open.
- [x] Firebase Console PROD: app iOS `com.tony.dearembeiu` = App Attest · Registered.
- [x] Firebase Console PROD: app Android `com.tony.dearembeiu` = Play Integrity · Registered (2 fingerprint SHA-256).
- [x] Tất cả API vẫn **Unenforced** — không một user nào bị chặn.
- [ ] Sau khi bản có App Check live: biểu đồ verified ở tab APIs tăng dần (mốc kiểm: sau 2 tuần).
- [ ] (Sau, riêng) Enforce từng API khi tỉ lệ verified đủ cao.

## 6. Nợ kỹ thuật / rủi ro
- **Chưa enforce ⇒ chưa bảo vệ gì.** Hiện tại chỉ là thu thập số liệu. Giá trị thật chỉ có ở bước enforce.
- **Cloud Functions không nằm trong danh sách enforce của Firebase Console** — muốn bảo vệ `generateDailyQuestion` phải tự kiểm `request.app == null → throw` trong `functions/index.js`. Đây mới là chỗ tốn tiền nhất ⇒ nên là bước enforce ĐẦU TIÊN (và nó độc lập, không cần chờ độ phủ vì có thể fail-open bằng code).
- **Android sideload** (APK ngoài Play) sẽ không có token Play Integrity hợp lệ. Không ảnh hưởng khi Unenforced.
- **Play Integrity có quota miễn phí** (mặc định 10.000 request/ngày cho standard API). Quy mô hiện tại thừa sức, nhưng nếu tăng trưởng thì phải xin nâng quota TRƯỚC khi enforce.
