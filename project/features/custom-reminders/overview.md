# Custom reminders — Reminder tuỳ chỉnh do user tạo (local)

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.

- **Feature:** custom-reminders
- **Ưu tiên:** P1 (retention — bổ sung table-stakes app couple VN)
- **Trạng thái:** 🧪 Test PASS (logic verified) — chờ user smoke-test runtime trên thiết bị để đóng ✅ Done
- **Tạo ngày:** 2026-05-31
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · nền tảng reminders [`../reminders/overview.md`](../reminders/overview.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 6

## 1. Vấn đề & giá trị
- *Vấn đề người dùng:* App hiện chỉ có 4 reminder **tự động, cố định** (daily / yearly anniversary / milestone 100 ngày / inactivity). Couple **không thể tự đặt** các mốc riêng của họ: sinh nhật, kỷ niệm theo tháng ("monthsary"), ngày quen, ngày cưới dự kiến…
- *Giả thuyết giá trị:* Cho couple tự tạo reminder riêng → tăng lý do mở app + cảm giác "không gian của 2 người" → cải thiện retention (metric Bắc Đẩu).
- *Đối tượng:* Cặp đôi trẻ VN (Gen Z/Millennials) đang dùng app.
- *Đo bằng gì (metric):* (sau khi có analytics) số reminder do user tạo / couple; tỉ lệ couple tạo ≥1 reminder. Hiện chưa có analytics → defer đo lường.

## 2. Bối cảnh / nghiên cứu
- **Kỷ niệm theo tháng + ngày kỷ niệm tuỳ chỉnh là table-stakes** của app couple VN (Been Love Memory, Lovedays, Been Together…). App mình hiện chỉ đếm năm → thiếu nhịp tháng. Đây là khoảng trống rõ.
- Reminders hiện tại 100% local (Hive `reminder_settings`, không Firestore) — feature này **kế thừa hướng local-only** để ship nhanh, không đụng backend.

## 3. Phạm vi (scope)
- **Trong phạm vi:**
  - User tạo **nhiều reminder riêng lẻ**; mỗi reminder: **tên (bắt buộc) + ghi chú (tuỳ chọn) + ngày + giờ + kiểu lặp**.
  - Kiểu lặp: **một lần / hằng ngày / hằng tuần / hằng tháng / hằng năm**.
  - **Sửa / xoá / bật-tắt** từng reminder.
  - Màn hình quản lý danh sách reminder (vào từ mục Reminders trong profile).
  - Local-only: lưu Hive trên máy người tạo; mỗi máy tự schedule local notification.
  - i18n vi+en cho toàn bộ UI + nhãn kiểu lặp.
- **Ngoài phạm vi:**
  - **KHÔNG** đồng bộ giữa 2 máy / Firestore / FCM push (user đã chốt: local riêng từng máy).
  - KHÔNG nhắc-trước-X-ngày (lead time) cho reminder tuỳ chỉnh (mỗi reminder bắn đúng 1 thời điểm/chu kỳ).
  - KHÔNG đụng 4 reminder tự động sẵn có (chạy song song, không gộp).
  - KHÔNG sửa các nợ kỹ thuật sẵn có của reminders (permission im lặng, DST) trong feature này.

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý.
- **D1 — Local-only, riêng từng máy.** *Lý do:* user chọn để ship nhanh, không đụng backend/rules/push. Đánh đổi: partner không được nhắc reminder do mình tạo (chấp nhận cho MVP).
- **D2 — User tự tạo nhiều reminder riêng lẻ** (không phải 1 reminder bắn nhiều ngày). *Lý do:* user xác nhận; đơn giản UI + scheduling.
- **D3 — Mỗi reminder có GIỜ riêng** (không dùng chung 1 giờ global như reminder tự động). *Lý do:* sinh nhật/kỷ niệm thường khác giờ; tự nhiên hơn.
- **D4 — Tên bắt buộc + ghi chú tuỳ chọn.** *Lý do:* tên = title notification; ghi chú = body. Đủ giàu, vẫn gọn cho MVP.
- **D5 — Giới hạn 20 reminder tuỳ chỉnh / máy.** *Lý do:* iOS giới hạn tối đa 64 pending notification; cap 20 an toàn (chừa chỗ cho 4 reminder tự động + đệm). Vượt → chặn + báo nhẹ.
- **D6 — Dải notification ID riêng (2000–2999)** tách khỏi 1001–1005 của reminder tự động; mỗi reminder 1 ID ổn định để reschedule không chồng.
- **D7 — Custom reminder phụ thuộc quyền OS chung của reminders.** *Lý do:* dùng chung 1 đường xin quyền. ~~Nếu reminders chưa bật/chưa cấp quyền → màn hình nhắc user bật trước khi tạo có hiệu lực.~~ **⚠️ THAY bằng Dv6 (Reminders v2, 2026-05-31):** gate "màn disabled thụ động" được thay bằng **force-open dialog** — tap "Lời nhắc của chúng mình" khi master OFF mở `AlertDialog` mời bật ngay (xin quyền OS tại chỗ), granted → vào màn; denied → snackbar; "Để sau" → đóng. Không còn vào màn ở state disabled. State `_DisabledState` cũ giữ làm fallback phòng race, không phải code chết. Chi tiết: `../reminders/overview.md` Dv6 + `../reminders/design.md`.
- **D8 — Edge ngày 29–31 (tháng) / 29-02 (năm):** clamp về ngày hợp lệ cuối cùng của chu kỳ (vd 31 → 30/28). *Lý do:* tránh bỏ chu kỳ im lặng; hành vi đoán được. Dev xử lý rõ, Tester verify.
- **D9 — Chốt 3 điểm Designer hỏi (2026-05-31):** (a) Disabled-D7 → nút "Bật lời nhắc" **pop về Profile** để user bật ở toggle gốc (giữ đúng 1 đường xin quyền hiện có, KHÔNG tự bật trong màn mới). (b) **Ẩn FAB ở empty state** — chỉ dùng CTA lớn "Tạo lời nhắc đầu tiên" để tránh trùng nút. (c) **Thêm key `customRemindersNotifBodyFallback`** cho body notification khi ghi chú trống (D4).

## 5. Acceptance criteria (xong khi…)
> [x] = đã VERIFIED qua code + Tester (2026-05-31). ⏳ = cần smoke-test trên thiết bị thật (bản chất local notification, không verify hết bằng đọc code).
- [x] Tạo được reminder mới: nhập tên + (tuỳ chọn) ghi chú + chọn ngày + giờ + kiểu lặp; lưu lại.
- [x] Danh sách hiển thị mọi reminder đã tạo (tên, ngày/giờ kế tiếp, nhãn kiểu lặp, toggle bật/tắt).
- [x] Sửa được reminder đã tạo; xoá được (có xác nhận — swipe + menu + dialog).
- [x] Bật/tắt từng reminder → reschedule/cancel đúng (không chồng, không sót).
- [x] 5 kiểu lặp map đúng matcher + `nextFireFor` đúng. ⏳ *Việc OS thực bắn đúng chu kỳ qua nhiều tháng cần test thiết bị.*
- [x] Edge ngày 31/29-02 xử lý theo D8 (clamp `_clampedDate`/`_daysInMonth`), không crash, không bỏ chu kỳ. *(Giới hạn đã biết: OS chốt day-of-month theo first-fire — xem mục 7.)*
- [x] Reminder "một lần" trong quá khứ → không schedule + form cảnh báo, không crash.
- [x] Đạt giới hạn 20 → chặn tạo thêm + thông báo.
- [x] Notification dựng đúng tên (title) + ghi chú/fallback (body). ⏳ *Hiển thị notification thật cần test thiết bị.*
- [x] Toàn bộ UI + nhãn kiểu lặp có vi+en (48 key parity 100%); không hardcode chuỗi.
- [x] Persist round-trip toMap/fromMap đúng; cold start load + reschedule (gated theo master, D7). ⏳ *Cold start thực tế cần test thiết bị.*
- [x] Phụ thuộc quyền OS (D7): chưa bật/tắt master → state Disabled hướng dẫn bật, không "im lặng fail"; cold start chỉ reschedule khi master enabled.
- [x] `flutter analyze` sạch (No issues found!).
- [x] 4 reminder tự động cũ (id 1001–1005) không bị đụng (dải custom 2000–2999 tách biệt).

> **Còn lại để đóng ✅ Done:** user chạy app trên thiết bị thật, tạo vài reminder (mỗi kiểu lặp + 1 cái once sắp tới) và xác nhận notification bắn đúng + còn sau khi tắt/mở lại app. Toàn bộ logic tĩnh đã verified; chỉ chờ smoke-test runtime này.

## 6. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)
- 🎨 **Designer:** thiết kế màn hình **danh sách reminder** + **form thêm/sửa** (date picker, time picker, chọn kiểu lặp, field tên + ghi chú) + điểm vào từ profile. Đủ states (empty/loading/list/disabled-khi-chưa-cấp-quyền), copy vi+en, token chính xác bám design system. → *expect:* `design.md` đủ để Dev dựng không hỏi lại.
- 💻 **Dev:** model `CustomReminder` (Hive) + mở rộng `ReminderService` (schedule theo 5 recurrence, dải ID 2000+) + `ReminderProvider` hoặc provider mới (CRUD + persist + reschedule) + màn hình mới + ARB vi/en + gen-l10n + `flutter analyze` sạch. → *expect:* code chạy, `dev.md` ghi rõ file/hàm.
- 🧪 **Tester:** verify 5 kiểu lặp, edge ngày 31/29-02, cap 20, sửa/xoá/toggle reschedule đúng, persist cold start, i18n, không regression reminder tự động. → *expect:* `test.md` verdict PASS/FAIL.

## 7. Nợ kỹ thuật / rủi ro (để Tester soi)
- 🟡 Kế thừa **permission denied im lặng** & **DST/timezone** & `inexactAllowWhileIdle` từ reminders nền tảng (không sửa ở feature này).
- 🟡 [CẦN TEST] iOS 64 pending limit — D5 cap 20 giảm rủi ro nhưng cần verify tổng pending (4 auto + custom) không vượt.
- 🟡 [CẦN TEST] Edge clamp ngày 31/29-02 phụ thuộc hành vi `matchDateTimeComponents` của flutter_local_notifications theo nền tảng.

## 8. Changelog feature
- [2026-05-31] [PO] Tạo feature, viết spec + decision log (D1–D8) + acceptance. Khởi động pipeline orchestrator (Designer → Dev → Tester).
- [2026-05-31] [Designer] Xong design.md: 3 màn (điểm vào/danh sách/form), 7 states, token bám design system, copy vi+en đầy đủ.
- [2026-05-31] [PO] Chốt D9 (3 điểm Designer hỏi). GATE Designer PASS.
- [2026-05-31] [Dev] Implement: model `CustomReminder` (Hive map, không codegen), `CustomRemindersProvider` (CRUD/cap20/allocate id 2000–2999), mở rộng `ReminderService` (scheduleCustom/cancelCustom/nextFireFor/clamp D8), 2 screen mới, tile điểm vào profile, wiring D7 master toggle, ARB 48 key vi+en. Fix hạ tầng l10n (thêm `l10n.yaml` + `generate: true` pubspec, backfill ARB lệch generated). Fix bug D7 cold-start. Polish default ngày/giờ form THÊM.
- [2026-05-31] [Tester] PASS — 22/22 case tĩnh VERIFIED, 4 case ⏳ cần runtime thiết bị. analyze sạch, ARB parity 100%, không regression.
- [2026-05-31] [PO] FINAL VERIFY độc lập: analyze sạch; diff l10n chỉ additive (mọi key cũ giữ value, chỉ 1 chuỗi lỗi dev-facing `authFirestorePermissionDenied` đổi `{uid}`→`<uid>` vô hại + `galleryMonthLabel` đổi sang ICU select output y nguyên); test fail `widget_test` là pre-existing (login screen thiếu localization delegate, không liên quan). Acceptance tĩnh đủ. **Chưa đóng ✅ Done — chờ user smoke-test runtime trên thiết bị** (xem mục 5).
