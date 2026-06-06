# Test log — analytics

> File Tester sở hữu (read-only nghiệm thu). Contract ở [overview.md](overview.md), Dev ở [dev.md](dev.md).

## Nghiệm thu — 2026-06-03 [Tester]

**VERDICT: PASS** (code-level). Đọc độc lập service + 17 call site + main + settings + couple_service + 3 privacy file + l10n; `fvm flutter analyze` sạch; `plutil -lint` OK.

### Kết quả theo trục
| Trục | Tiêu chí | Kết quả |
|---|---|---|
| A | 0-PII mọi param (14 event) | PASS — không rò rỉ |
| B | Guard no-op (null + opt-out), setEnabled, default ON, Hive String type-safe | PASS |
| C | Đúng call site/success path; bucket lỗi join; is_first; reveal-1-lần; Gap G; user_id set/clear; user props | PASS |
| D | Không regression CoupleException/transaction join; main init order + observer null-safe | PASS |
| E | xcprivacy (tracking=false, 3 data type linked) + Info.plist ad-perso=false + privacy-policy (disclose + transfer + opt-out) | PASS |
| F | l10n keys en+vi+generated; toggle wired; analyze sạch | PASS |

### 0-PII — điểm verify trọng yếu
- `love_note_set`: chỉ `action` create/update (`love_note_provider.dart:98,103`) — không text.
- `daily_question_answered`: không param (`daily_question_provider.dart:146`) — không nội dung.
- `invite_shared`: chỉ `copy/share_sheet` (`invite_action_buttons.dart:47,64`) — KHÔNG giá trị mã.
- `photo_posted`: chỉ `is_first` bool (`photo_provider.dart:97,118`) — không URL/caption.
- `couple_join_attempt`: chỉ `result` enum (`couple_provider.dart:116,124,133-143`) — không coupleId/uid.
- uid chỉ qua `setUserId`, không vào param. Lớp phòng thủ `logEvent` chỉ giữ String/num/bool (`analytics_service.dart:184-187`).

### Không regression (vùng nhạy)
- `CoupleException.code` là field optional default null; throw chỉ THÊM `code:`, không đổi message/logic. `runTransaction` join nguyên vẹn → concurrent join vẫn an toàn. Analytics bắn NGOÀI transaction.

### Ghi nhận (không tính lỗi feature này)
- `test/widget_test.dart` FAIL **pre-existing** — không import/không liên quan analytics; fail do chuỗi LoginScreen lệch (commit "login feature", trước analytics). [VERIFIED].

### Nợ runtime còn lại (KHÔNG chặn DoD code-level)
- [CẦN TEST runtime] GA4 DebugView trên thiết bị thật xác nhận event/param thực tế gửi đi.
- [CẦN TEST runtime] User điền **Play Data Safety** + **Apple App Privacy** trên console (bảng giá trị có sẵn trong `dev.md`).
