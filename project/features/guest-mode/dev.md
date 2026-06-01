# 💻 Dev — Guest mode

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** xong / chờ test
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* Tạo mới `lib/screens/guest_counter_screen.dart` (StatefulWidget thuần local). Đọc/ghi Hive box `guest_settings` key `anniversary` lưu `millisecondsSinceEpoch` (int) — đọc trong `initState` (`_loadAnniversary`), ghi khi chọn ngày (`_pickDate`). Mở box nếu chưa mở: `if (!Hive.isBoxOpen('guest_settings')) await Hive.openBox('guest_settings')`. KHÔNG Provider/Firestore/Auth — không gọi backend. State `_anniversaryDate` (nullable) quyết định empty ↔ có-ngày qua `AnimatedSwitcher(260ms, easeOutCubic)`.
- *Tái dùng widget/logic:* `CounterCard(years/months/days, subtitle, footer)` (không truyền `totalDays` ⇒ render breakdown); `CounterData.calculateFromAnniversary`; copy nguyên 5 helper từ home (`_getTotalDays`/`_getNextAnniversary`/`_daysUntil`/`_getNextMilestone`/`_milestoneLabel`) + tái hiện layout `_buildMilestoneSection` (white bo24, icon workspace_premium accentGold, LinearProgress accentRose, footer daysCountLabel/percentThere). Header eyebrow/title/subtitle theo pattern login (`pageEyebrowStyle/pageTitleStyle/pageSubtitleStyle`). AppBar phẳng trong suốt + back trắng + `LanguageToggleButton` ở actions.
- *File/hàm đụng tới:* CHỈ tạo mới `lib/screens/guest_counter_screen.dart`. Không sửa `main.dart`/`app_routes.dart`/`login_screen.dart` (đã wiring sẵn — verify khớp: route `/guest`, `GuestCounterScreen()` const ctor OK; import main.dart:21 thoả).
- *Thay đổi model / Firestore / Cloud Function / native config:* Không.
- *Cần deploy?* Không (thuần local).
- *l10n:* dùng 13 key `guest*` đã có sẵn + key tái dùng (footer/milestone/fullDateFormat) — KHÔNG thêm key mới, KHÔNG hand-edit Dart generated.

## Edge case kỹ thuật cần xử lý
- **Ngày tương lai:** chặn ở picker (`lastDate: DateTime.now()`) ⇒ không tạo được số âm. (`progressToMilestone` thêm `.clamp(0.0, 1.0)` phòng hờ.)
- **Empty state (chưa chọn ngày):** chỉ hiện empty card + CTA card; ẩn CounterCard/milestone/đổi-ngày. Không crash.
- **Cold start đọc Hive:** `initState` mở box async rồi `setState` — UI render empty trước, nhảy sang có-ngày khi load xong (mượt qua AnimatedSwitcher); persist qua reinstall-session vì là Hive local.
- **mounted guard:** sau `await openBox` / `showDatePicker` / `box.put` đều check `mounted` trước `setState`/dùng context.
- **DatePicker locale-aware:** `locale: Localizations.localeOf(context)`, `initialDate` = ngày đã lưu hoặc now, `firstDate: DateTime(1990)`.
- **Navigation:** "Đăng nhập" + AppBar back → `Navigator.pop` (login dưới stack); "Đăng ký" → `pushNamed(AppRoutes.register)`.

## Checklist implement
- [x] Tạo `GuestCounterScreen` (empty + có-ngày + CTA + đổi-ngày) bám design.md
- [x] Hive `guest_settings`/`anniversary` (millis int): đọc initState, ghi khi pick
- [x] Tái dùng CounterCard + CounterData + helper/milestone từ home
- [x] DatePicker chặn ngày tương lai + locale-aware
- [x] CTA điều hướng pop(login)/push(register)
- [x] `flutter analyze` sạch (No issues found!)
- [x] Không hardcode chuỗi/ngôn ngữ (qua l10n) — 13 key guest* + key tái dùng
- [x] KHÔNG đụng Firestore/Auth/Provider/native; không sửa main/routes/login

## Nhật ký implement
- [2026-06-01] [Dev] Tạo `lib/screens/guest_counter_screen.dart` (GuestCounterScreen thuần local Hive `guest_settings`). Build vỡ trước đó (thiếu file màn guest, main.dart:21/229) → fix bằng đúng file này. Tái dùng CounterCard/CounterData + bê 5 helper + layout milestone từ home; empty/có-ngày qua AnimatedSwitcher 260ms; DatePicker chặn ngày tương lai (lastDate=now) locale-aware; CTA pop→login / push→register. `fvm flutter analyze` = No issues found!. Trạng thái dev → xong / chờ test.
