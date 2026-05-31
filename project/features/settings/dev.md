# 💻 Dev — Settings

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** chờ test (2026-05-31)
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* DI CHUYỂN (cut/paste) các mục cài đặt từ `profile_screen.dart` sang màn mới `settings_screen.dart`, **giữ nguyên logic/callback/dialog**; chỉ đổi vị trí + đổi title module sang key `settings*`. Per-milestone time (Dv8) thêm vào provider + màn mốc.
- *File tạo:* `lib/screens/settings_screen.dart`.
- *File sửa:*
  - `lib/screens/profile_screen.dart` — gỡ các section đã chuyển, thêm tile "⚙️ Cài đặt", dọn import.
  - `lib/screens/milestone_reminders_screen.dart` — thêm tile "Giờ mặc định" + chip-giờ mỗi mốc (Dv8).
  - `lib/providers/reminder_provider.dart` — per-milestone time model/persist/schedule (Dv8); `setTime` nhận couple inputs optional (fallback cached).
  - `lib/l10n/app_en.arb` + `app_vi.arb` — thêm 11 key `settings*` + cập nhật value `remindersV2MilestoneScreenCaption`.
- *Thay đổi model / Firestore / Cloud Function / native config:* KHÔNG. Chỉ Hive (key mới `milestone_<name>_hour`/`_minute`). Không đụng backend/rules/functions.
- *Cần deploy?* Không.

## Mục đã DI CHUYỂN (profile → settings) — giữ nguyên hành vi
| Mục | Từ profile | Vào settings | Ghi chú |
|-----|-----------|--------------|---------|
| Reminders section (master toggle + tile Cột mốc + tile custom + force-open Dv6) | `_buildRemindersSection` + `_showForceOpenDialog` | `_buildRemindersSection` + `_showForceOpenDialog` | **Bỏ tile "Giờ nhắc" độc lập** (giờ → "Giờ mặc định" trong sub mốc). Title đổi sang `settingsRemindersModuleTitle/Subtitle`. |
| Language | `_buildLanguageSection` | `_buildLanguageSection` | y nguyên (`showLanguagePicker`). |
| Chỉnh sửa câu chuyện | `_buildActionsSection` (FilledButton) | `_buildAccountSection` (đổi nút→tile) | logic `loadCoupleForUser` y nguyên; copy `editOurStoryBtn` + subtitle mới. |
| Danger zone (cache/leave/delete) | `_buildDangerZone` + 3 dialog | `_buildDangerZone` + 3 dialog | bê NGUYÊN; card riêng viền đỏ cuối module Tài khoản. |
| Đăng xuất | `_buildSignOutButton` + `_showSignOutDialog` | y nguyên | |
| Privacy link | `_buildPrivacyPolicyLink` | y nguyên | |

Profile sau refactor: GIỮ `_buildPageHeader`/`_buildHeroCard`/`_buildStatsSection`/`_buildCoupleInfoSection` + **thêm `_buildSettingsTile`** (tile đơn full-width → push `SettingsScreen`).

## Per-milestone time (Dv8) — cách lưu + schedule
- **Lưu (Hive box `reminder_settings`):** giờ riêng mỗi mốc ở `milestone_<name>_hour` + `milestone_<name>_minute`. **Absent = theo giờ mặc định.** Set/clear cả 2 key cùng lúc (`_persistMilestoneTime`: null → `box.delete` cả 2; có → `box.put`). Load trong `ReminderProvider.load` vào `Map<MilestoneType,TimeOfDay> _milestoneTimes`.
- **API provider mới:**
  - `milestoneTimeOf(type) → TimeOfDay?` (giờ riêng hoặc null).
  - `effectiveTimeOf(type) → TimeOfDay` (giờ riêng nếu có, không thì default `settings.hour/minute`).
  - `setMilestoneTime(type, TimeOfDay?)` — null = xoá giờ riêng về mặc định; persist + (nếu enabled & mốc đang bật) reschedule riêng mốc đó qua `_scheduleMilestone`.
- **Schedule:** `_scheduleMilestone(type, anniversary, l10n)` (bỏ tham số hour/minute) — tự lấy `effectiveTimeOf(type)`. `nextFireForMilestone` cũng dùng `effectiveTimeOf` cho `fireAt`. → đổi giờ mặc định (`setTime`) gọi `_reschedule` (full reschedule, mỗi mốc dùng effective time) ⇒ **chỉ mốc theo-mặc-định đổi giờ; mốc có giờ riêng giữ nguyên.**
- **`setTime` nới lỏng:** couple inputs (`anniversaryDate`/`lastPhotoDate`/`l10n`) thành optional, fallback `_lastAnniversary`/`_lastPhotoDate`/`_lastL10n` (cached bởi sync). ⇒ màn mốc đổi "Giờ mặc định" không cần truyền couple data. Profile/Settings vẫn truyền đủ như cũ qua reminders section (qua `setEnabled`).
- Notification id giữ nguyên (1 id/mốc) — đổi giờ chỉ thay nội dung schedule, không đụng dải id.

## Màn mốc UI (Dv8)
- Tile "Giờ mặc định" (`_DefaultTimeTile`): accentGold tile, giờ `time.format(context)`, tap → `showTimePicker` → `setTime` (không tham số couple).
- Chip-giờ mỗi mốc (`_TimeChip`, chỉ hiện khi mốc BẬT):
  - `customTime == null`: chip mờ "Theo mặc định · {giờ}" (textTertiary) → tap mở picker (seed = effective) → `setMilestoneTime(type, picked)`.
  - `customTime != null`: chip đậm rose "{giờ}" + ✕ → tap giờ đổi; tap ✕ → `setMilestoneTime(type, null)`. ✕ có Semantics (`settingsMilestoneCustomTimeReset`).
- Format giờ locale-aware (`TimeOfDay.format(context)`). `AnimatedContainer` 200ms easeOutCubic đổi state chip.

## i18n
- Thêm 11 key `settings*` (en+vi): `settingsTitle`, `settingsProfileTileSubtitle`, `settingsRemindersModuleTitle/Subtitle`, `settingsAccountModuleTitle/Subtitle`, `settingsEditStorySubtitle`, `settingsDefaultTimeLabel/Subtitle`, `settingsMilestoneUsesDefault({time})`, `settingsMilestoneCustomTimeReset`.
- Cập nhật value `remindersV2MilestoneScreenCaption` (thêm ý "giờ nhắc").
- Tái dùng key cũ cho mục di chuyển (không tạo trùng). `remindersTitle/Subtitle/remindersTimeLabel` + `customizeProfile*` còn trong ARB nhưng **không còn dùng** ở vị trí cũ (giữ lại, không xoá để tránh churn).
- `flutter gen-l10n` chạy sạch.

## Edge case kỹ thuật đã xử lý
- Đổi giờ mặc định KHÔNG đụng mốc đã đặt giờ riêng (vì reschedule dùng effective time per-mốc).
- `setMilestoneTime` chỉ reschedule khi master bật & mốc đang bật; nếu mốc tắt thì chỉ persist (sẽ áp dụng khi bật lại).
- Mốc tắt → chip-giờ ẩn (giờ vô nghĩa khi không nhắc).
- `setTime` không có couple data vẫn an toàn (fallback cached; nếu chưa cache thì chỉ persist, không reschedule — không crash).
- `context.mounted` check sau `showTimePicker` (async gap) ở cả default-time tile và chip.

## Checklist implement
- [x] Màn `SettingsScreen` 3 module + danger + signout + privacy
- [x] Profile gọn + tile "Cài đặt"
- [x] Per-milestone time model/persist/schedule (Dv8)
- [x] Màn mốc: Giờ mặc định + chip-giờ mỗi mốc
- [x] ARB en+vi + gen-l10n
- [x] `flutter analyze` sạch — **No issues found! (ran in 4.6s)**
- [x] Không hardcode chuỗi/ngôn ngữ (qua l10n)
- [x] `flutter test`: 8 pass, 1 fail PRE-EXISTING (`widget_test.dart` LoginScreen TypeError — fail cả trên clean tree, không liên quan settings)

## Điểm Tester cần chú ý (dễ regression khi di chuyển)
1. **Danger zone (leave/delete/clear cache)** — verify dialog + luồng pushNamedAndRemoveUntil y như cũ (App Store/Play compliance). Chú ý nhánh Firebase vs local (`isUsingFirebase` → có/không nút clear cache).
2. **Force-open Dv6** — master OFF + tap "Lời nhắc của chúng mình" → dialog mời bật → granted vào màn custom / denied snackbar / Later đóng.
3. **Reminders toggle + permission** — lock-step custom reminders (reschedule/cancel) khi bật/tắt master.
4. **Per-milestone time:** schedule dùng đúng giờ (riêng vs mặc định); đổi giờ mặc định reschedule mốc chưa-đặt-riêng nhưng KHÔNG đụng mốc đã đặt riêng; chip ✕ về mặc định; persist qua restart (load đọc đủ hour+minute).
5. **`setTime` không-couple-data:** đổi giờ mặc định từ màn mốc dùng cached inputs — cần thiết bị để xác nhận notification reschedule đúng giờ mới (bản chất local notification).

## Nhật ký implement
- [2026-05-31] [Dev] Implement feature **settings**: tạo `settings_screen.dart` (3 module 🔔/🌐/👤 + danger + đăng xuất + privacy), refactor `profile_screen.dart` (gọn còn hero+stats+couple-info + tile "⚙️ Cài đặt", di chuyển nguyên hành vi reminders/language/edit-story/danger/signout/privacy sang settings, dọn import). Per-milestone time (Dv8): provider `_milestoneTimes` + `milestoneTimeOf`/`effectiveTimeOf`/`setMilestoneTime` + persist Hive `milestone_<name>_hour/_minute` (null=mặc định) + schedule dùng `effectiveTimeOf`; `setTime` fallback cached couple inputs. Màn mốc: tile "Giờ mặc định" + chip-giờ mỗi mốc (mờ "Theo mặc định"/đậm "{giờ} ✕"). ARB 11 key `settings*` en+vi + caption cập nhật, gen-l10n. `flutter analyze` sạch. Trạng thái → chờ test.
