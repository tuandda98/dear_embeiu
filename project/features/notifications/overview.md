# Notification center (Trung tâm thông báo)

> File PO sở hữu. Nguồn sự thật chung cho cả feature.

- **Feature:** notifications
- **Ưu tiên:** P1
- **Trạng thái:** 🚧 Dev xong (code-level) — chờ smoke-test 2 thiết bị + GA prod
- **Tạo ngày:** 2026-06-06
- **Liên quan:** [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị
- *Vấn đề:* Push hiện tại là **ephemeral** — user bỏ lỡ/đã tắt thông báo thì mất luôn, không có chỗ xem lại. Tap push chỉ đổi tab, không có lịch sử.
- *Giá trị:* Một nơi xem lại mọi hoạt động của cặp đôi (ảnh, reaction, lời nhắn, câu hỏi ngày, ghép đôi/rời đi), tap → điều hướng tới đúng phần. Tăng quay lại app (North Star: cặp active đăng ảnh/tuần).
- *Đo bằng:* số lần mở notification center, tỉ lệ tap→điều hướng.

## 2. Bối cảnh
- SumOne/Paired đều có inbox thông báo bền vững (Firestore-backed), không phụ thuộc push delivery.

## 3. Phạm vi
- **Trong phạm vi (v1):** 6 loại sự kiện cặp đôi (photo_posted, photo_reaction, partner_joined, partner_left, love_note, daily_question). Bell + badge ở header Home. Màn list: xem lại, tap→điều hướng tab, vuốt xoá, đánh dấu đã đọc, xoá tất cả.
- **Ngoài phạm vi (v1):** nhắc nhở local (love reminders/cột mốc/custom) — thuần local, kém tin khi app kill; deep-link tới đúng ảnh cụ thể (chỉ tới tab); cài đặt bật/tắt từng loại.

## 4. Quyết định đã chốt (decision log)
- **D1 — Firestore-backed (KHÔNG local-only).** *Lý do:* push ephemeral; local-only mất thông báo khi app bị kill (iOS không chạy background handler đáng tin). CF ghi 1 doc `users/{uid}/notifications` mỗi lần gửi push; client nghe stream → bền vững qua kill/reinstall, sync đã-đọc.
- **D2 — Lưu structured data, render text theo locale hiện tại.** *Lý do:* push localize theo ngôn ngữ thiết bị lúc gửi; inbox phải khớp ngôn ngữ app hiện tại → lưu `type`+`actorName`+ids, render bằng AppLocalizations.
- **D3 — Scope stream theo `coupleId == current`.** *Lý do:* tự ẩn thông báo của couple cũ sau khi rời/đổi couple, không cần cleanup server.
- **D4 — Rules ADDITIVE, client KHÔNG create.** *Lý do:* backend prod dùng chung mọi version app; subcollection mới → app cũ bỏ qua. Chỉ CF (admin) create; client chỉ read/mark-read/delete của mình.
- **D5 — Cap 50 + index (coupleId asc, createdAt desc).** Giới hạn growth, phân trang ngầm.

## 5. Acceptance criteria (xong khi…)
- [ ] Mỗi push (6 loại) tạo 1 doc inbox cho đúng recipient (không tự-thông-báo-mình).
- [ ] Bell ở header Home hiện badge số chưa đọc; cập nhật live khi push tới lúc app mở.
- [ ] Mở center thấy list newest-first, render đúng ngôn ngữ hiện tại; tap → đổi đúng tab (ảnh→Gallery, còn lại→Home), đánh dấu đã đọc.
- [ ] Vuốt xoá 1 item; "xoá tất cả" có xác nhận; "đánh dấu đã đọc" cho tất cả.
- [ ] App cũ 1.0/1.1 KHÔNG vỡ (rules additive — đã có rules unit test).
- [ ] Xoá tài khoản → xoá luôn `users/{uid}/notifications` (Apple 5.1.1(v)).
- [ ] Tap vào nội dung đã xoá (ảnh) → về Gallery, không crash.

## 6. Nợ kỹ thuật / rủi ro
- `partner_left` trước đây thiếu nhánh tap trong push handler → đã vá.
- Notifications couple cũ còn nằm Firestore sau khi rời (ẩn bởi filter coupleId, dọn khi xoá tài khoản) — v2 có thể dọn server-side khi leave.
- Local reminders chưa vào inbox (v2).

## 7. Review flow A/B (2026-06-08) + lộ trình cải thiện
Đóng vai A/B đi hết vòng đời → finding (đã chốt với user). Decision log:
- **D-notif-1 (auto-read):** mở tab Gallery → mark read `photo_posted`+`photo_reaction`; tab Home → `love_note`+`daily_question`+`partner_joined/left`. Mở tab = "đã thấy đồ ở đó" → badge chỉ đếm cái thực sự chưa xem.
- **D-notif-2 (badge):** server set `aps.badge` = số chưa-đọc thật của recipient (CF query); client set app-badge = `unreadCount`, clear=0 khi đọc. (Thay `badge:1` hardcode.)
- **D-notif-3 (deep-link item):** tap photo_posted/photo_reaction → mở ĐÚNG ảnh (Gallery preview by photoId); **daily_question → cuộn Home tới đúng card câu hỏi** (`pendingHomeFocus` + `GlobalKey` + `Scrollable.ensureVisible`, 2026-06-08); love_note vẫn tab Home (card sẵn ngay đầu).
- **D-notif-4 (per-type settings):** toggle `photo`/`reaction`/`daily_question` ở Settings; `love_note`+`partner_joined/left` LUÔN bật. Lưu prefs vào device doc → CF tôn trọng. ⚠️ cần mở rộng `hasOnly` của rules `users/{uid}/devices` (thiếu field = push hỏng âm thầm) → rules-test + deploy.
- **D-notif-5 (polish):** đăng ≥2 ảnh/60s không spam; sửa note nhỏ không re-push; dịu tone `partner_left`.

**Lộ trình cột mốc (đang làm — Lead solo):**
- ✅ **M1 — Auto-read (D-notif-1)** [2026-06-08]: `NotificationInboxProvider.markReadForTab` + getter `unreadForTab`; hook trong `home_screen.dart build` (gated, post-frame, idempotent). Client-only, KHÔNG cần deploy. `analyze` sạch.
- ✅ **M2 — Deep-link ảnh (D-notif-3)** [2026-06-08]: `NotificationTapRouter.pendingPhotoId` + `consumePhotoRequest`; push handler (`_handleNotificationTap`) + inbox tile set photoId; `GalleryScreen` (initState/listener + build post-frame) → `GalleryScreen.openPreview` đúng ảnh, gone→về grid. Client-only. analyze sạch.
- ✅ **M3 — Per-type settings (D-notif-4)** [2026-06-08]: `NotificationSettingsService` (Hive `notification_settings`) + mirror device doc qua `saveDeviceRegistration(pushTypePrefs)` + `PushNotificationService.refreshDeviceRegistration`; **rules** `isValidDeviceDocument` thêm `pushPhoto/pushReaction/pushDailyQuestion` (đọc `.get(.,true)` additive); CF `PUSH_TYPE_PREF_FIELD` lọc device trong `sendToRecipientDevices` (mute = chỉ tắt PUSH, inbox vẫn ghi). UI Settings section "Loại thông báo" (3 switch, love_note/partner luôn bật). l10n 8 key. rules-test 140 pass.
- ✅ **M4 — Badge thật + dịu tone (D-notif-2 + tone)** [2026-06-08]: CF `sendToRecipientDevices` set `aps.badge` = count chưa-đọc thật của recipient (Firestore `count()`), thay `badge:1`; client clear badge qua MethodChannel `app/badge` (AppDelegate.swift + `AppBadge.set`, gọi từ inbox provider stream + clear). Dịu copy `partner_left` ("đã ngắt kết nối" → "có thể kết nối lại 💛", VI title "không gian chung").
- ⏸️ **HOÃN (fast-follow, có chủ đích):** *throttle ảnh-loạt* (cần index `(type,createdAt)` mới + query/photo, rủi ro chặn nhầm) + *no-repush khi sửa note nhỏ* (heuristic mờ — Levenshtein/length dễ nuốt nhầm love-note thật). Để lại làm riêng khi cần, không ship heuristic janky.
- 🚀 **Deploy:** **DEV** rules+functions (user duyệt DEV-only, **KHÔNG prod**). PROD chờ lệnh sau.
