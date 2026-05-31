# Reminders — Love reminders (local notifications)

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** reminders
- **Ưu tiên:** P1 (retention)
- **Trạng thái:** ✅ Shipped (v1.0.0) · 🎨 **v2 đang làm** (milestone customization — bỏ nudge hằng ngày)
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 6,13

## 1. Mô tả
Nhắc nhở yêu thương **local-only** (không network), dùng flutter_local_notifications + timezone. 4 loại khi bật: **daily nudge** (giờ mặc định 20:00), **yearly anniversary**, **day-count milestone** (mỗi 100 ngày + nudge trước 3 ngày), **inactivity** (sau 7 ngày không đăng ảnh). Text lấy từ `AppL10n.strings` (đã localize đúng).

> Phân biệt với **push partner-photo** (FCM qua Cloud Function — thuộc feature [gallery]).

## 2. Phạm vi
- **Trong:** bật/tắt reminders (xin quyền OS), chọn giờ, 4 loại reminder, reschedule khi đổi anniversary/đăng ảnh.
- **Ngoài:** reminder tuỳ chỉnh do user tạo, reminder theo sự kiện lịch (→ shared-calendar tương lai).

## 3. Code liên quan
- `lib/providers/reminder_provider.dart` (what — Hive box `reminder_settings`), `lib/services/reminder_service.dart` (how — channel `love_reminders`, id 1001-1005)
- Toggle + time picker ở `lib/screens/profile_screen.dart`

## 4. Acceptance (đã đạt)
- [x] Bật/tắt + chọn giờ; xin quyền OS trước khi bật
- [x] 4 loại reminder schedule đúng; id cố định để reschedule thay thế (không chồng)
- [x] `initialize()` không throw (không chặn launch); text đa ngôn ngữ qua AppL10n

## 5. Nợ kỹ thuật / rủi ro
- 🟡 **Permission denied → enabled=false im lặng**, không có nút "Grant Permission" dẫn ra OS settings. Android `requestNotificationsPermission()` trả null bị coerce true → silent fail.
- 🟡 **Anniversary tương lai → bỏ schedule milestone im lặng** (`reminder_provider` ~213).
- 🟡 [CẦN TEST] DST/timezone: giờ static hour:minute, qua DST có thể lệch 1h tới khi restart; daily fallback UTC nếu lấy tz lỗi.
- 🟡 `setTime` không bound-check hour/minute.
- 🟡 Android dùng `inexactAllowWhileIdle` → reminder có thể không đúng phút tuyệt đối (chấp nhận được, nhưng cần biết).

## 5b. Reminders v2 — Milestone customization (2026-05-31)
> Redesign reminder tự động: bỏ nudge hằng ngày generic, cho user **tự bật/tắt từng mốc**. Liên quan chặt feature [custom-reminders](../custom-reminders/overview.md) (đổi gate D7 → force-open).

### Vấn đề
Nudge "nhắc nhở hằng ngày" chung chung → nhạt + dễ nhầm với "Lời nhắc của chúng mình" (custom). Milestone bị ép cứng mỗi 100 ngày, user không chọn được mốc.

### Decision log v2 (đã chốt với user 2026-05-31)
- **Dv1 — Bỏ nudge hằng ngày generic** (id 1001, `scheduleDaily`). *User quyết.*
- **Dv2 — Giữ ĐÚNG 1 master toggle, đổi tên** → **"Nhắc cột mốc & kỷ niệm"** + thêm **phần details/giải thích** nút làm gì. Toggle vẫn kiêm: xin quyền OS + cho user tắt + gate custom reminders.
- **Dv3 — Milestone do user tự bật/tắt từng mốc** (danh sách curated), persist Hive. Có màn "Tuỳ chỉnh mốc".
- **Dv4 — Danh sách mốc + mặc định (LOCKED):**
  | Mốc | Loại | Mặc định |
  |---|---|---|
  | Mỗi 100 ngày (100, 200, 300…) | đếm ngày (cadence) | ✅ ON |
  | 520 ngày ("anh yêu em") | đếm ngày (one-shot) | ⬜ OFF |
  | 1000 ngày | đếm ngày (one-shot) | ✅ ON |
  | 1314 ngày ("yêu trọn đời") | đếm ngày (one-shot) | ⬜ OFF |
  | Nửa năm (6 tháng) | mốc tháng (one-shot) | ✅ ON |
  | Kỷ niệm hằng năm (1, 2, 3 năm…) | hằng năm (recurring) | ✅ ON |
  | Lâu (7 ngày) không đăng ảnh | nhắc nhẹ | ✅ ON |
- **Dv5 — Mốc chỉ nhắc ĐÚNG NGÀY** (bỏ "nhắc trước 3 ngày"/approaching cho gọn — thêm lại sau nếu cần).
- **Dv6 — Force-open gate cho custom reminders:** vào "Lời nhắc của chúng mình" khi master OFF → hộp thoại mời bật (xin quyền OS) → cho phép thì vào màn; từ chối thì báo + ở lại. **Thay** state "disabled" thụ động (D7 cũ của custom-reminders).
- **Dv7 — "Giờ nhắc" giữ nguyên**, áp dụng cho mọi mốc tự động. ~~(v2.0)~~ **⚠️ NÂNG CẤP ở Dv8.**
- **Dv8 — Giờ theo từng mốc (2026-05-31, đi cùng feature [settings](../settings/overview.md)):** "Giờ nhắc" trở thành **GIỜ MẶC ĐỊNH**; **mỗi mốc có giờ riêng tuỳ chọn** (lưu Hive, null = dùng mặc định). Schedule dùng giờ riêng nếu có, không thì mặc định. Đổi giờ mặc định → reschedule các mốc CHƯA đặt giờ riêng. Custom reminders đã có giờ riêng — không đổi. UI đặt giờ mỗi mốc nằm trong sub "Cột mốc & kỷ niệm" (xem settings). *Lý do:* user muốn giờ tuỳ ý từng mốc thay vì 1 giờ chung.

### Notification ID (dải auto 1001–1099; custom dùng 2000–2999 — không đụng)
- Giữ 1002 (yearly), 1005 (inactivity). Bỏ 1001 (daily). Cấp id riêng cho từng mốc đếm-ngày + halfYear trong 1001–1099. Dev tự chốt mapping cụ thể.

### Acceptance v2 (xong khi…)
> [x] = VERIFIED qua code + Tester (2026-05-31, PASS 30/30). ⏳ = cần smoke-test thiết bị (bản chất local notification).
- [x] Không còn nudge hằng ngày generic (grep sạch `scheduleDaily`; id 1001 chỉ còn trong `cancelAll` dọn legacy).
- [x] Master toggle đổi tên "Nhắc cột mốc & kỷ niệm" + details (gồm: cần bật để dùng Lời nhắc của chúng mình).
- [x] Màn "Cột mốc & kỷ niệm" liệt kê đủ 7 mốc, bật/tắt từng cái (persist Hive `milestone_<name>`), đúng mặc định Dv4 lần đầu.
- [x] Mỗi mốc BẬT → schedule đúng: every100 = mốc 100 kế; 520/1000/1314 = nhắc nếu chưa tới; halfYear = nếu chưa tới 6 tháng (clamp); yearly = kỷ niệm năm kế (clamp Feb29); inactivity = 7 ngày. **Mốc rơi ĐÚNG hôm nay vẫn bắn nếu giờ nhắc chưa qua** (fix biên: so datetime thay vì ngày).
- [x] Mốc TẮT → cancel id tương ứng (không schedule).
- [x] anniversary tương lai (daysTogether<0) → không crash, không nhắc, UI "pending".
- [x] Force-open (Dv6): master off + tap custom → dialog mời bật → granted vào / denied snackbar / Để sau đóng. ⏳ *quyền OS thật cần thiết bị.*
- [x] Custom reminders v1 vẫn chạy (dải 2000–2999 nguyên vẹn), gate đổi sang force-open.
- [x] `flutter analyze` sạch; i18n vi+en parity (33 key v2); không hardcode.
- ⏳ Cần thiết bị: notification thật bắn đúng ngày/giờ; yearly recurrence qua nhiều năm; DST; quyền OS trong force-open.

### Giao việc 3 vai (v2)
- 🎨 **Designer:** thiết kế lại mục Reminders trong profile (toggle đổi tên + details + entry "Tuỳ chỉnh mốc"); **màn "Tuỳ chỉnh mốc"** (list 7 mốc, mỗi mốc icon+tên+mô tả ngắn+toggle, hiện "Sắp tới" nếu tính được); **hộp thoại force-open**. States + copy vi+en + token. → `design.md`.
- 💻 **Dev:** bỏ daily nudge; model/persist milestone settings (Hive); restructure `reminder_service`/`reminder_provider` (schedule theo từng mốc bật, id 1001–1099); màn tuỳ chỉnh mốc; rename + details ở profile; đổi gate custom-reminders sang force-open; ARB + gen-l10n; analyze sạch. → `dev.md`.
- 🧪 **Tester:** verify từng mốc schedule đúng (đếm ngày/tháng/năm, mốc đã-qua bỏ), bật/tắt persist, không còn daily nudge, force-open, không regression custom v1. → `test.md`.

## 6. Changelog
- [2026-05-30] [PO] Tài liệu hoá feature đã ship + rủi ro từ catalog logic.
- [2026-05-31] [PO] Spec **Reminders v2** (Dv1–Dv7): bỏ nudge hằng ngày, milestone tự bật/tắt (7 mốc, danh sách chốt với user), đổi tên toggle + details, force-open gate cho custom-reminders. Khởi động pipeline orchestrator.
- [2026-05-31] [Designer→Dev→Tester→PO] Pipeline xong: Designer (3 vùng + 7 mốc + force-open), Dev (model `MilestoneType`, provider milestone settings + schedule per-mốc id 1001–1099, màn `milestone_reminders_screen`, profile rename + tile mốc + force-open dialog, đổi gate custom). Tester PASS 30/30. PO fix biên (mốc đúng-hôm-nay vẫn bắn). analyze sạch, không regression. **Trạng thái: 🧪 PASS — chờ user smoke-test thiết bị để đóng ✅ Done.**
