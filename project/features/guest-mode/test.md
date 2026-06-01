# 🧪 Test — Guest mode

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** PASS (static/code-level) — còn 5 case CẦN TEST RUNTIME để user smoke-test trên thiết bị
- **Người/role:** Master Tester

## Phạm vi test
Feature guest-mode (fix Apple 5.1.1): nút "Dùng thử không cần đăng nhập" ở login → `GuestCounterScreen` thuần local (Hive `guest_settings`/`anniversary`), counter ngày/tháng/năm + đếm ngược kỷ niệm + milestone, CTA chuyển đổi về login/register. 3 trục: logic/state, edge/race, security/no-backend + acceptance overview.md mục 4.

## Test case
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Login có nút "Dùng thử…" (TextButton.icon + divider "hoặc") → tap push `/guest` | Vào GuestCounterScreen, không cần login | ✅ [VERIFIED] login_screen.dart:339-365 → `pushNamed(AppRoutes.guest)`; route main.dart:229 |
| 2 | happy | Chọn ngày kỷ niệm → counter years/months/days + đếm ngược + milestone | Hiển thị đúng, tính local | ✅ [VERIFIED] CounterData.calculateFromAnniversary + 5 helper copy nguyên từ home (giống byte-for-byte) |
| 3 | empty | Chưa chọn ngày (`_anniversaryDate==null`) | Empty card + CTA card, không CounterCard/milestone, không crash | ✅ [VERIFIED] build() AnimatedSwitcher → `_buildEmptyCard` khi null (dòng 174-176) |
| 4 | edge | Ngày tương lai | Picker chặn `lastDate: now` → không tạo được số âm | ✅ [VERIFIED code] guest:54 `lastDate: now`. ⚠️ [CẦN TEST RUNTIME] xác nhận picker thực sự không cho chọn > hôm nay |
| 5 | edge | Chọn đúng hôm nay (totalDays=0) | nextMilestone=30, progress=0, daysLeft=30, breakdown "0 ngày", footer đếm ngược ~365, không crash | ✅ [VERIFIED] logic: 0<30→30; CounterCard items.isEmpty→show days=0 |
| 6 | cold start | Lần đầu mở: box `guest_settings` chưa tồn tại | `openBox` tạo mới, `get` trả null → `millis is int` false → giữ empty, không crash | ✅ [VERIFIED] guest:37-49 `_loadAnniversary` mở box + guard `millis is int` |
| 7 | cold start | Chọn ngày → kill app → mở lại | Ngày vẫn còn (Hive persist) | ✅ [VERIFIED code] ghi `box.put(millis)` guest:69. ⚠️ [CẦN TEST RUNTIME] persist thực tế qua kill/relaunch |
| 8 | edge | Đổi ngày nhiều lần | Mỗi lần ghi đè key `anniversary`, UI cập nhật qua setState | ✅ [VERIFIED] `_pickDate` dùng chung empty+content; put + setState |
| 9 | race | mounted guard sau await | Không setState/dùng context khi đã dispose | ✅ [VERIFIED] guard `mounted` sau openBox (43), sau showDatePicker (61), sau put (71) |
| 10 | security | Guest KHÔNG đụng Firestore/Auth/Provider/Firebase | Thuần local — lý do tồn tại feature (5.1.1) | ✅ [VERIFIED] grep import: chỉ material/hive/intl/l10n/models/theme/widgets; 0 ref backend (chỉ doc-comment) |
| 11 | nav | CTA "Đăng nhập" + AppBar back → pop về login; "Đăng ký" → push register | Stack gọn, về login được | ✅ [VERIFIED code] pop() (148, 507), pushNamed(register) (522). ⚠️ [CẦN TEST RUNTIME] back/CTA điều hướng thực tế |
| 12 | regression | Đăng nhập/đăng ký/ghép đôi/home sau khi dùng guest | Không regression — guest là route riêng, không qua SessionResolver | ✅ [VERIFIED] guest không sửa auth/couple state; main.dart:226-229 ghi rõ không qua authGate. ⚠️ [CẦN TEST RUNTIME] smoke đăng nhập sau guest vẫn vào home/setup |
| 13 | đa ngôn ngữ | 14 key guest* vi+en + key tái dùng; không hardcode | Đủ chuỗi, đổi VI/EN qua LanguageToggle đúng | ✅ [VERIFIED] 14/14 key guest* có ở app_en.arb + app_vi.arb + generated dart (base/en/vi); 0 chuỗi hardcode trong màn |
| 14 | i18n date | Format ngày locale-aware (subtitle CounterCard) | `DateFormat(fullDateFormat)` theo locale | ✅ [VERIFIED] guest:77-79 giống `_formatDate` home; Intl.defaultLocale sync ở main.dart:215 |
| 15 | build | `fvm flutter analyze` | No issues | ✅ [VERIFIED] No issues found! (ran in 5.8s) |
| 16 | design | Bám design system: dawnBlush, CounterCard hero bo28, glass bo28, milestone bo24, accentRose, không token mới | Khớp design.md | ✅ [VERIFIED] secondaryGradient, cardRadius, accentRose/accentGold, helper AppTheme có sẵn — không token mới |

*(Kết quả: ✅ pass · ❌ fail · ⬜ chưa chạy)*

## Bug report (nếu FAIL)
Không có lỗi. Không tìm thấy bug nào ở mức code/static.

## Ghi chú quan sát (không phải bug)
- **Nợ kế thừa (KHÔNG phải lỗi guest):** `CounterData.calculateFromAnniversary` dùng năm=365 ngày / tháng≈30 ngày (xấp xỉ, không xét năm nhuận) → years/months breakdown có sai số nhỏ. Đây là logic feature `counter` tái dùng nguyên, guest bê đúng. Tương tự `_getTotalDays`/milestone dùng cùng giả định. Nếu muốn chính xác hơn là việc của feature counter.
- **Nhất quán với home:** 5 helper (`_getTotalDays`/`_getNextAnniversary`/`_daysUntil`/`_getNextMilestone`/`_milestoneLabel`) copy giống hệt home_screen → guest counter hiển thị y như home, đúng chủ đích G5. (`_formatDate` khác chữ ký: guest dùng `context.l10n` member thay vì truyền context — cùng kết quả.)
- **Đề xuất tương lai (không chặn release):** 5 helper bị copy-paste giữa home & guest; cân nhắc trích ra util dùng chung để tránh lệch khi sửa 1 nơi. Không phải bug.

## Nhật ký test
- [2026-06-01] [Tester] Test guest-mode ở mức code/static. Đọc overview/design/dev + guest_counter_screen.dart (541d) + wiring (login_screen 339-365, app_routes:8, main.dart 226-229) + tham chiếu home_screen helper + counter_data + counter_card. Chạy `fvm flutter analyze` = No issues found!. Verify: (1) 14/14 key guest* vi+en + generated dart đủ, 0 hardcode; (2) 5 helper copy giống byte-for-byte home; (3) 0 ref Firebase/Auth/Provider/Firestore — thuần local đúng yêu cầu 5.1.1; (4) empty/cold-start/future-date/same-day/mounted-guard đều an toàn trong code; (5) CounterCard reuse đúng (totalDays null → breakdown). **VERDICT: PASS (code-level).** Còn 5 case cần smoke-test runtime trên thiết bị: #4 picker chặn ngày tương lai, #7 persist qua cold start, #11 điều hướng CTA/back, #12 không regression đăng nhập sau guest, + đổi VI/EN runtime (#13 phần toggle). Nợ năm-365/tháng-30 là kế thừa từ feature counter, KHÔNG phải bug guest.
