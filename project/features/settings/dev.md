# 💻 Dev — Settings

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- [2026-06-19] [dev] **Ẩn thẻ "Quản lý dữ liệu" (`_buildDangerZone`) theo email** (user yêu cầu). Thêm hằng `_hideDataManagementEmails` (Set, hiện có `phuogthao1408@gmail.com`); build so email đăng nhập (`authProvider.currentUser?.email ?? currentEmail`, trim+lowercase) → khớp thì bọc `if (!hideDataManagement)` quanh `SizedBox(24)+EntranceReveal(order:3, danger zone)` ⇒ tài khoản đó KHÔNG thấy xoá-cache-máy/rời-couple/xoá-tài-khoản. Các tài khoản khác giữ nguyên. analyze 0. ⚠️ Email hardcode — muốn thêm/sửa thì sửa Set này. (Lưu ý spelling `phuogthao` — chờ user xác nhận có thiếu chữ 'n' không.)

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
- [2026-06-11] [Dev] **Profile: Cài đặt → 1 icon góc phải trên + Tủ kỷ niệm gom 1 card (user):** (1) header Profile thành Row [EyebrowChip + Spacer + `HeaderIconButton(settings)` 44/r16] — XOÁ tile "⚙️ Cài đặt" full-width cuối trang (`_buildSettingsTile`, key `settingsProfileTileSubtitle` hết dùng giữ ARB), `_openSettings` push SettingsScreen + Semantics `settingsTitle`; (2) Tủ kỷ niệm: 3 tile viền riêng → **1 ContentCard grouped** (padding h20 v6) với 3 `_chestRow` (InkWell r12 ripple rose .08 + IconBadge + title 15 w700 + chevron) ngăn `_chestDivider` hairline indent 58 — cùng ngôn ngữ flat-list Settings v2; xoá `_chestTile`, import ink_tile → header_icon_button; skeleton sync (header thêm squircle 44, chest 3×64 + settings 64 → 1 block 188 r24). analyze sạch + test 18/18.
- [2026-06-11] [Dev] **REVERT vòng 2 — khôi phục NGUYÊN VĂN Stats 2×2 gốc (user làm rõ: "như cũ là như lúc đầu, lúc chưa yêu cầu sửa"):** xoá hẳn `_buildJourneyStrip/_journeyChip`, khôi phục `_buildStatsSection` + `_buildModernStatCard` + `_buildSectionCard` (bản pre-v2 trong working tree, KHÔNG phải git HEAD — HEAD cũ hơn, thiếu icon param section card) + import ContentCard; build tính lại `years/months`, spacing 18; **gỡ `onOpenGallery`** khỏi ProfileScreen + call-site home_screen (chip ảnh tappable không còn); xoá `_getNextAnniversary/_daysUntil` hết dùng (fix `isBefore` thành moot); skeleton 3-chip → block 320 r24. Key `profileChip*` hết dùng (giữ ARB). Phần còn lại Profile v2 GIỮ (hero tap-to-edit, Tủ kỷ niệm, bỏ subtitle, bỏ Info tiles). analyze sạch 2 file.
- [2026-06-11] [Dev] **REVERT strip Hành trình về bản trắng (user "tôi thích như cũ hơn" ngay sau khi xem bản tint):** `_journeyChip` về white .72 r22 viền rose .10, bỏ param `icon`/`color` + icon squircle + tint accent — code y bản trước vòng tint. Chuỗi quyết định: trắng → user chê "quá chán" → tint accent + icon squircle → user xem rồi đòi revert → **CHỐT bản trắng tối giản**. analyze sạch.
- [2026-06-11] [Dev] **Strip Hành trình (Profile v2) làm "đặc sắc" theo user (kèm screenshot "quá chán… giống như cũ"):** 3 chip trắng phẳng → mang lại ngôn ngữ stat card cũ: mỗi chip **tint màu riêng .10 + viền .10** (rose ngày-bên-nhau `Icons.favorite_rounded` · coral kỷ-niệm `partyPopper` · lavender ảnh `image` — lavender thay gold theo C8 contrast) + **icon squircle trắng .78 34/r12** hàng đầu (chevron đối diện icon ở chip ảnh), value 22 w800, label 11. `_journeyChip` thêm param `icon`/`color`. analyze sạch.
- [2026-06-11] [Dev] **Fix vòng 2 Settings v2 (user: "button đăng xuất nên để dưới cuối cùng chứ"):** dời `_buildSignOutButton` từ dưới card Tài khoản → **CUỐI TRANG sau danger zone** (trước footer version) — đúng quy ước settings phổ quát (exit action đóng trang; thứ tự quét dùng-thường→ít-dùng→rời-đi). Nhóm Tài khoản giờ thuần card info (return shrink khi user null). analyze sạch. *Bài học design ghi memory: exit/destructive flow nằm cuối; đừng over-think "tách màu đỏ" mà phá quy ước mạnh hơn.*
- [2026-06-11] [Dev] **Fix Settings v2 theo feedback user (kèm screenshot "đăng xuất là button mà"):** hàng Đăng xuất trong card Tài khoản đọc như info read-only (cùng card tên/email) → tách ra thành **BUTTON pill** trở lại (`_buildSignOutButton` — pill r999 h52 white .72 navy, token C12/B10) đặt NGAY DƯỚI card Tài khoản (vẫn trong nhóm, vẫn tách khỏi danger zone); card Tài khoản giờ thuần info (tên + email). analyze sạch.
- [2026-06-11] [Dev] **Settings v2 (redesign user chốt toàn bộ — spec `design.md` §Redesign Settings v2):** viết lại `settings_screen.dart` (1910→~1500 dòng) thành **grouped list phẳng**: `SectionHeader` ngoài card + 1 `ContentCard`/nhóm (padding h20 v6) + hàng ngăn `_rowDivider` (hairline indent 58) — XOÁ `_buildSectionCard` card-lồng-card. Bố cục: header (BỎ subtitle) → **Tài khoản** (tên/email read-only + **Đăng xuất thành hàng trong card** — xoá pill nổi; helper `_navRow` icon+title+subtitle+trailing+InkWell rose .08) → **Thông báo** (GỘP Nhắc nhở + Loại thông báo: master toggle → `_DailyQuestionReminderTile` flatten bỏ vỏ white .72 → mốc (dim+badge — giữ) → custom (badge+force-open Dv6 — giữ) → sub-label micro-caps `settingsPushGroupLabel` 11 w700 ls1.2 → `_NotificationTypeToggles` contentPadding v2) → **Chung** (Ngôn ngữ row + `_AnalyticsToggleTile` contentPadding v4 + **privacy-policy lên hàng thật** trailingIcon externalLink — xoá footer-link 12px) → **danger zone GIỮ NGUYÊN 100%** → **footer version MỚI** "Dear Embeiu · v{version} ({build})" qua `package_info_plus` (dep MỚI, FutureBuilder). **XOÁ 2 mục thừa sau Profile v2:** section Kỷ niệm/Journal + tile "Chỉnh sửa câu chuyện" (+ import journal/setup_screen; key cũ giữ ARB: `settingsHeaderSubtitle/settingsRemindersModuleTitle+Subtitle/settingsNotifTypesTitle+Subtitle/journalSettingsSection/settingsAccountModuleTitle+Subtitle/settingsEditStorySubtitle/languageSubtitle`). ARB +4 key (`settingsSection*` ×3, `settingsPushGroupLabel`) en+vi, gen-l10n. Mọi logic giữ nguyên verbatim: permission flow, lock-step D7, force-open, 5 dialog, leave-couple teardown `_leaving`. `fvm flutter analyze` sạch + test 18/18. CHƯA commit. ⚠️ Smoke-test: toggle master on/off (dim mốc + lock-step custom), force-open khi off, 3 toggle push (check device doc refresh), đổi ngôn ngữ, sign-out từ hàng mới, leave/delete flows, footer hiện đúng version.
- [2026-06-11] [Dev] **Profile v2 (redesign user chốt toàn bộ — spec `design.md` §Redesign Profile v2):** viết lại `profile_screen.dart`: (1) header BỎ subtitle; (2) hero h220 **tap-to-edit** → push `SetupScreen` + reload couple khi về (y hệt tile Settings cũ), đĩa ✎ 36 white .92/pencil `accentLoveDeep` top-right (IgnorePointer — tap do InkWell full-card xử lý), Semantics `editOurStoryBtn`; BỎ glass pill đếm-ngược + avatar 72 (lặp ảnh nền) + layer trang trí lệch layout cũ; (3) **strip Hành trình** `IntrinsicHeight` 3 chip white .72 r22 (tổng ngày / ngày tới kỷ niệm — =0 → "🎉"+label hôm nay / số ảnh, `NumberFormat.decimalPattern` locale) thay Stats 2×2 + Info tiles — chip ảnh `InkTile` → param mới `ProfileScreen.onOpenGallery` (home_screen truyền `setState _selectedIndex=1`), Semantics `viewAllPhotos`; (4) **Tủ kỷ niệm** (ẨN khi waiting): SectionHeader + 3 tile (bookOpen→`JournalScreen` · history→`LoveNoteHistoryScreen` · flame→`StreakSheet.show`); (5) tile mã mời (chỉ waiting) đứng độc lập; tile ⚙️ giữ, refactor sang `InkTile`; XOÁ `_buildStatsSection/_buildCoupleInfoSection/_buildSectionCard/_buildModernStatCard/_buildGlassPill/_buildAvatarBadge` + import ContentCard; skeleton sync. **FIX bug kế thừa:** `_getNextAnniversary` dùng `!isAfter` → đúng ngày kỷ niệm nhảy năm sau (case "hôm nay" unreachable) → đổi `isBefore`. **Home:** `today_ritual_card.dart` GỠ footer archive links (`_buildArchiveLinks/_archiveLink/_push` + import 2 screen — key `journalLinkShort/loveNoteHistoryLinkShort` giữ ARB). ARB +6 key (`profileChip*` ×4, `profileMemoryChestTitle`, `profileStreakTile`) en+vi, gen-l10n. `fvm flutter analyze` toàn project sạch. CHƯA commit. ⚠️ Smoke-test: tap hero → setup → back reload tên/ảnh; chip ảnh → tab Gallery; 3 tile chest; waiting-couple (ẩn chest, hiện mã mời); ngày kỷ niệm hôm nay → chip 🎉.
- [2026-05-31] [Dev] Implement feature **settings**: tạo `settings_screen.dart` (3 module 🔔/🌐/👤 + danger + đăng xuất + privacy), refactor `profile_screen.dart` (gọn còn hero+stats+couple-info + tile "⚙️ Cài đặt", di chuyển nguyên hành vi reminders/language/edit-story/danger/signout/privacy sang settings, dọn import). Per-milestone time (Dv8): provider `_milestoneTimes` + `milestoneTimeOf`/`effectiveTimeOf`/`setMilestoneTime` + persist Hive `milestone_<name>_hour/_minute` (null=mặc định) + schedule dùng `effectiveTimeOf`; `setTime` fallback cached couple inputs. Màn mốc: tile "Giờ mặc định" + chip-giờ mỗi mốc (mờ "Theo mặc định"/đậm "{giờ} ✕"). ARB 11 key `settings*` en+vi + caption cập nhật, gen-l10n. `flutter analyze` sạch. Trạng thái → chờ test.
