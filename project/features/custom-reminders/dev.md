# 💻 Dev — Custom reminders

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** xong (l10n gen + analyze sạch) — chờ test
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* <…>
- *File/hàm đụng tới (file:line nếu sửa code cũ):* <…>
- *Thay đổi model / Firestore / Cloud Function / native config:* <…>
- *Cần deploy?* <rules / functions / không>

## Edge case kỹ thuật cần xử lý
- <…>

## Checklist implement
- [ ] <task 1>
- [ ] <task 2>
- [ ] `flutter analyze` sạch
- [ ] Không hardcode chuỗi/ngôn ngữ (qua l10n)

## Nhật ký implement
- [<YYYY-MM-DD>] [Dev] <đã code gì / commit / deploy>
- [2026-05-31] [Dev] Fix l10n gen (thêm l10n.yaml) + analyze sạch. Chi tiết:
  - **Nguyên nhân gốc:** `flutter:` section trong `pubspec.yaml` THIẾU cờ `generate: true` (chỉ có ở block `flutter_launcher_icons.web`), nên `flutter gen-l10n` từ chối ghi. Ngoài ra project chưa có `l10n.yaml`.
  - **Đã tạo `l10n.yaml`** ở gốc repo:
    ```yaml
    arb-dir: lib/l10n
    template-arb-file: app_en.arb
    output-localization-file: app_localizations.dart
    output-class: AppLocalizations
    output-dir: lib/l10n
    nullable-getter: false
    ```
    (bỏ `synthetic-package: false` vì Flutter 3.41.6 báo deprecated/no-effect.)
  - **Thêm `generate: true`** vào `flutter:` section của `pubspec.yaml`.
  - **Phát hiện ARB lệch generated:** file `lib/l10n/app_localizations.dart` committed ở HEAD CÓ 106 key (vd `bootstrapWebNotConfigured`, `couplePhotoUploadGeneric`, `galleryEmptyTitle`, `authFirestorePermissionDenied`, các method `counterDuration`/`galleryMonthLabel`/...) nhưng ARB committed KHÔNG có → trước đây build được chỉ vì generated Dart stale (cờ generate tắt nên không ai regen). Khi regen, mất 106 key → 111 lỗi. Đã **khôi phục đủ 106 key vào cả `app_en.arb` + `app_vi.arb`** (giá trị lấy đúng từ generated `_en`/`_vi` ở HEAD, en thêm `@`-metadata).
  - **Sửa nhỏ bắt buộc để compile:**
    - `galleryMonthLabel`: dùng ICU `select` theo tháng (giữ output en = tên tháng, vi = "Tháng MM • year"). ICU select yêu cầu placeholder type `String` → đổi placeholder en thành String và sửa **1 call site** `lib/screens/gallery_screen.dart:1153` `galleryMonthLabel(date.month.toString(), date.year.toString())`.
    - `authFirestorePermissionDenied`: chuỗi chứa `{uid}`/`{code}` bị ICU hiểu nhầm là placeholder. Đổi notation thành `<uid>`/`<code>` (chuỗi lỗi developer-facing, không đổi nghĩa).
    - Lint info `unnecessary_underscores` `lib/screens/custom_reminders_screen.dart:339`: `(_, __)` → `(_, _)`.
  - **Kết quả:** `flutter gen-l10n` chạy sạch (chỉ deprecation warning vô hại); `grep -c customReminders lib/l10n/app_localizations.dart` = **96** (48 getter/method + 48 doc-comment), mỗi locale 48 key; `flutter analyze` = **No issues found!**; không regression (đủ 406 key, en/vi parity).
  - **Lưu ý test:** `test/widget_test.dart` "renders login screen scaffold" FAIL nhưng **đã fail sẵn ở HEAD** (test không wire localization delegate → `AppLocalizations.of` throw) — KHÔNG do thay đổi này, ngoài scope.

- [2026-05-31] [Dev] Fix bug D7 cold-start: chỉ rescheduleAllEnabled khi master reminders enabled.
- [2026-05-31] [Dev] Polish: default ngày/giờ form THÊM = thời điểm tương lai gần (hết cảnh báo quá khứ khi vừa mở), giữ cảnh báo khi user chọn ngày quá khứ.
- [2026-05-31] [Dev] **Reminders v2 — đổi gate D7 → Dv6 force-open.** Tile "Lời nhắc của chúng mình" ở profile khi master OFF không còn push vào màn ở state "disabled" thụ động; thay bằng `AlertDialog` force-open (`profile_screen.dart` `_showForceOpenDialog`): "Bật" → `reminderProvider.setEnabled(true,…)` (xin quyền OS) → granted: `rescheduleAllEnabled()` + push màn custom; denied: snackbar `remindersV2ForceOpenDeniedMsg`; "Để sau" → đóng. **Hệ quả:** `CustomRemindersScreen` chỉ vào được khi master đã bật → state `_DisabledState`/`_buildBody(!remindersEnabled)` + key `customRemindersOff*`/`customRemindersDisabledLabel` GIỮ LẠI làm fallback phòng race (master tắt giữa session), không phải code chết, analyze sạch. Chi tiết v2 ở `../reminders/dev.md`.
- [2026-06-14] [Dev] **Bỏ gate master (Dv6 force-open) — custom reminders luôn dùng được.** Provider bỏ master toggle (`settings.enabled` giờ luôn true). Trong `custom_reminders_screen.dart`: gỡ `Consumer2<...,ReminderProvider>` + check `remindersEnabled` + xoá class `_DisabledState` + import `reminder_provider`. Tách `CustomRemindersBody` (loading shimmer / inline empty / list + nút "Thêm lời nhắc" `_AddReminderButton`) dùng cho màn gộp `RemindersScreen`; `_confirmDelete` đẩy thành top-level `_confirmDeleteReminder` dùng chung (list/row/menu). `onAddPressed` thành static để body gọi. Force-open dialog ở settings đã gỡ bên feature reminders. Key `customRemindersOff*`/`customRemindersDisabledLabel` GIỮ ARB (thôi dùng). l10n mới `customRemindersAddAnother` (vi+en). `flutter analyze` sạch.
