# 🧪 Test — Settings

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** ✅ PASS (2026-05-31)
- **Người/role:** Master Tester

## Phạm vi test
Feature **settings** (màn Cài đặt tổng gom Profile rời rạc) + **Dv8** (giờ theo từng mốc). Bám acceptance ở `overview.md` mục 4 + trục test A–E. Đã đọc code: `settings_screen.dart`, `profile_screen.dart`, `reminder_provider.dart`, `milestone_reminders_screen.dart`, `reminder_service.dart`, `milestone_reminder.dart`, ARB en/vi + generated l10n.

## Công cụ chạy
- `flutter analyze` → **No issues found! (ran in 4.2s)** ✅
- `flutter test` → **8 pass, 1 fail PRE-EXISTING** (`widget_test.dart` "renders login screen scaffold" — fail sẵn ở HEAD do thiếu localization delegate, KHÔNG do feature này → không tính verdict). ✅
- grep ARB: 11 key `settings*` đủ EN+VI; placeholder `{time}` metadata ở EN (template) — đúng chuẩn gen-l10n; generated `app_localizations_en.dart` có `settingsMilestoneUsesDefault(String time)`. ✅
- grep hardcoded `Text('…')` trong 2 màn settings/milestone → **không có** (trừ emoji 🌐 fallback ngôn ngữ — chấp nhận được, không phải chuỗi cần dịch). ✅

## Test case

### A. IA gom đúng (S1–S5)
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| A1 | IA | Profile chỉ còn hero + stats + couple-info + tile "⚙️ Cài đặt" | KHÔNG còn reminders/ngôn ngữ/edit/danger/logout/privacy rải rác | ✅ [VERIFIED] `profile_screen.dart:68-91` build chỉ gồm header→hero→stats→coupleInfo→`_buildSettingsTile`. grep xác nhận KHÔNG còn `_buildRemindersSection/_buildLanguageSection/_buildDangerZone/_buildActionsSection/_showForceOpenDialog/_buildSignOutButton/_buildPrivacyPolicyLink` trong profile. (S3: couple-info GIỮ ở Profile đúng handoff.) |
| A2 | IA | Tile "Cài đặt" → push SettingsScreen | MaterialPageRoute → SettingsScreen | ✅ [VERIFIED] `profile_screen.dart:484-487` |
| A3 | IA | Settings đủ 3 module + danger + logout + privacy | 🔔/🌐/👤 + danger card + đăng xuất + privacy footer | ✅ [VERIFIED] `settings_screen.dart:81-99` đủ 6 thành phần đúng thứ tự (reminders→language→account→danger→signout→privacy) |

### B. KHÔNG regression mục di chuyển (giữ logic, chỉ đổi vị trí)
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| B1 | regression | Danger — xoá cache | Firebase: nút OutlinedButton + dialog gọi `clearLocalCache` 2 provider; local: cảnh báo `localFallbackWarning` (ẩn nút) | ✅ [VERIFIED] `settings_screen.dart:823-854` nhánh `isUsingFirebase` lấy từ `authProvider.isUsingFirebase` (`:93`); dialog `_showClearLocalDialog:1000` y nguyên |
| B2 | regression | Danger — rời couple | dialog → `leaveCouple` + `syncForUser` + `pushNamedAndRemoveUntil(setup)` | ✅ [VERIFIED] `_showLeaveCoupleDialog:1125`, điều hướng `AppRoutes.setup` y như cũ |
| B3 | regression | Danger — xoá tài khoản (khó hoàn tác) | dialog đỏ → `authProvider.deleteAccount()`; null→`pushNamedAndRemoveUntil(authGate)`; `requires-recent-login`→snackbar; lỗi khác→snackbar | ✅ [VERIFIED] `_showDeleteAccountDialog:1043` xử lý đủ 3 nhánh errorCode, điều hướng `AppRoutes.authGate`. Callable `deleteAccount` không đổi (không đụng functions). |
| B4 | regression | Reminders master toggle bật/tắt + permission + lock-step custom | `setEnabled` xin quyền; granted+on→`rescheduleAllEnabled`; off→`cancelAllSchedules`; denied→snackbar | ✅ [VERIFIED] `settings_screen.dart:127-149` `handleToggle` giữ nguyên lock-step custom (D7) + snackbar `remindersPermissionDeniedMsg` |
| B5 | regression | Tile "Cột mốc & kỷ niệm" dim khi off | AnimatedOpacity .45 200ms, onTap null khi off; on→push MilestoneRemindersScreen | ✅ [VERIFIED] `:218-231` |
| B6 | regression | Tile "Lời nhắc của chúng mình" force-open Dv6 | on→push Custom; off→`_showForceOpenDialog` (granted→reschedule+push; denied→snackbar; Để sau→đóng) | ✅ [VERIFIED] `:323-341` gate + `_showForceOpenDialog:438` đủ 3 nhánh y nguyên reminders v2 |
| B7 | regression | Ngôn ngữ đổi vi/en | tile → `showLanguagePicker(context)` qua LocaleProvider | ✅ [VERIFIED] `:560-561` |
| B8 | regression | Chỉnh sửa câu chuyện | tile → push SetupScreen rồi `loadCoupleForUser(currentUser)` | ✅ [VERIFIED] `:639-648` logic `.then(loadCoupleForUser)` giữ nguyên |
| B9 | regression | Đăng xuất | dialog → `signOut` → `pushNamedAndRemoveUntil(authGate)` | ✅ [VERIFIED] `_showSignOutButton:709` + `_showSignOutDialog:1095` |
| B10 | regression | Privacy link | mở `AppUrls.privacyPolicy` external | ✅ [VERIFIED] `_buildPrivacyPolicyLink:965` |

### C. Giờ-theo-mốc (Dv8)
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| C1 | logic | `effectiveTimeOf` | giờ riêng nếu có, else default `settings.hour/minute` | ✅ [VERIFIED] `reminder_provider.dart:132-134` |
| C2 | logic | `_scheduleMilestone` + `nextFireForMilestone` dùng effective | cả 2 lấy `effectiveTimeOf(type)` | ✅ [VERIFIED] `:351` (nextFire `fireAt`) + `:446` (`_scheduleMilestone`) đều dùng `effectiveTimeOf` |
| C3 | logic | `setMilestoneTime(type, time)` | persist `milestone_<name>_hour/_minute` + reschedule mốc đó (nếu master+mốc bật) | ✅ [VERIFIED] `:303-319` set map → `_persistMilestoneTime` (put cả 2 key) → `_scheduleMilestone` khi `enabled && isMilestoneEnabled` |
| C4 | logic | `setMilestoneTime(type, null)` | xoá override (về mặc định) + reschedule | ✅ [VERIFIED] `:304-305` remove map; `_persistMilestoneTime:199-201` delete cả 2 key; reschedule dùng effective=default |
| C5 | logic | `setTime` (đổi giờ mặc định) | reschedule: mốc giờ-riêng GIỮ, mốc theo-mặc-định đổi sang giờ mới | ✅ [VERIFIED] `:256-275` full `_reschedule` dùng `effectiveTimeOf` per-mốc ⇒ mốc có `_milestoneTimes[type]` không đổi; mốc null lấy giờ mới |
| C6 | edge | `setTime` không truyền couple data (gọi từ màn mốc) | fallback cached `_lastAnniversary/_lastL10n`; reminders ON để vào màn ⇒ cache có (sync cache cả khi off) | ✅ [VERIFIED] `:265-273` fallback; `sync:328-333` cache input cả khi disabled. `milestone_reminders_screen.dart:110` gọi `setTime` không couple data — an toàn |
| C7 | UI | Màn mốc: tile "Giờ mặc định" + chip-giờ | tile accentGold đầu list; chip mờ "Theo mặc định {giờ}" khi null / đậm "{giờ} ✕" khi riêng; ✕ về mặc định; ẩn khi mốc tắt | ✅ [VERIFIED] `_DefaultTimeTile:88`, `_TimeChip:424` (hasCustom đổi nền/màu/✕), `_MilestoneTile:260` chỉ render chip `if (enabled)` |
| C8 | UI | ✕ reset có Semantics accessibility | label `settingsMilestoneCustomTimeReset`, hit area ≥ padding | ✅ [VERIFIED] `:482-502` Semantics(button,label) + HitTestBehavior.opaque |
| C9 | persist | Giờ riêng qua cold start (absent key=mặc định) | `load()` đọc `_hour/_minute`, chỉ set khi cả 2 là int | ✅ [VERIFIED] `:152-160` chỉ `if (storedHour is int && storedMinute is int)` ⇒ absent → không vào map → effective=default |
| C10 | runtime | Notification thực sự bắn đúng giờ mới sau reschedule | local notification fire đúng `effectiveTimeOf` | ⏳ [CẦN TEST runtime] — bản chất local notification, cần thiết bị xác nhận (Dev đã ghi). Logic schedule đã verify đúng. |

### D. Không regression custom-reminders / Reminders v2
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| D1 | regression | Dải ID nguyên vẹn | custom 2000–2999 không đụng; auto milestone 1001–1012 nguyên | ✅ [VERIFIED] `reminder_service.dart:34-52` `_autoIds` + comment `:262` band 2000–2999 riêng |
| D2 | edge | Mốc rơi-hôm-nay-vẫn-bắn (fix biên) | so datetime (date@hour:minute) thay vì ngày | ✅ [VERIFIED] `reminder_provider.dart:381,394,401,518` dùng `fireAt(date).isAfter(now)` / `fireDateTime.isAfter(DateTime.now())` — biên giữ đúng, nay theo effective time |
| D3 | edge | Anniversary tương lai (daysTogether<0) | mốc đếm-ngày → pending/skip, không crash; inactivity vẫn chạy | ✅ [VERIFIED] `:370-373` pending; `:490-492` skip schedule |

### E. i18n
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| E1 | i18n | 11 key `settings*` parity EN+VI | đủ cả 2 file | ✅ [VERIFIED] grep: en `:543-560`, vi `:505-515` đủ 11 key |
| E2 | i18n | Placeholder `{time}` đúng | metadata ở template (en); vi có value `{time}` | ✅ [VERIFIED] en `@settingsMilestoneUsesDefault` placeholder time; vi value `"Theo mặc định · {time}"`; gen ra `settingsMilestoneUsesDefault(String time)` |
| E3 | i18n | Caption màn mốc cập nhật ý "giờ nhắc" | `remindersV2MilestoneScreenCaption` đổi value | ✅ [VERIFIED] vi `:483` "…và giờ nhắc.", en `:490` "…and when to be reminded." |
| E4 | i18n | Không hardcode trong 2 màn mới | mọi chuỗi qua l10n | ✅ [VERIFIED] grep Text('…') = rỗng |

*(Kết quả: ✅ pass · ❌ fail · ⏳ cần test runtime · ⬜ chưa chạy)*

## Tổng hợp
- **Tổng:** 30 case → **29 ✅ PASS · 1 ⏳ (C10, cần thiết bị) · 0 ❌**.
- **Regression mục di chuyển (B1–B10):** TẤT CẢ PASS — danh zone (xoá cache/rời couple/xoá tài khoản) giữ nguyên dialog + provider + điều hướng `pushNamedAndRemoveUntil`; phân biệt đúng nhánh Firebase vs local (`isUsingFirebase`); force-open Dv6, lock-step custom, ngôn ngữ, edit-story, đăng xuất, privacy đều giữ logic. **KHÔNG phát hiện regression nào.**
- **Dv8 (C1–C9):** logic giờ riêng/mặc định, persist null=mặc định, đổi giờ mặc định không đụng mốc giờ-riêng — tất cả đúng trong code. Chỉ còn C10 (notification fire đúng giờ) cần xác nhận trên thiết bị thật.
- `flutter analyze` sạch; `flutter test` 8 pass + 1 fail pre-existing (không liên quan).

## Bug report
Không có bug. (0 ❌)

## Verdict
**✅ PASS** — 29/30 case PASS, 1 case (C10) ⏳ chờ xác nhận runtime trên thiết bị (local notification fire đúng giờ riêng/mặc định) — đây là giới hạn không test tĩnh được, không phải lỗi. Acceptance overview mục 4 đạt; IA gom đúng, không regression mục di chuyển, Dv8 đúng logic, i18n đủ parity, analyze sạch.

## Nhật ký test
- [2026-05-31] [Tester] Test feature **settings** + Dv8: đọc 6 file code + ARB + generated l10n. 30 case (IA A1-A3 / regression-moved B1-B10 / Dv8 C1-C10 / no-regression-v2 D1-D3 / i18n E1-E4). Verdict **PASS** (29 ✅, 1 ⏳ C10 cần thiết bị, 0 ❌). Không regression danger zone / force-open / custom / ngôn ngữ / edit-story / logout / privacy. `flutter analyze` sạch; `flutter test` 8 pass + 1 fail pre-existing. Không có bug.
