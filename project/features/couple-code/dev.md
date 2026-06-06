# Dev — couple-code

- **Trạng thái dev:** xong (chờ test)
- **Người/role:** Dev

## Kế hoạch kỹ thuật

- **Cách tiếp cận:** Tách mã định danh cá nhân (`user.inviteCode`) khỏi mã entry vào couple (`couple.coupleCode`). Thêm collection `couple_codes/{code}` → `{coupleId, createdAt, updatedAt}`. `joinCoupleByCode` lookup `couple_codes` trước, fallback `invite_codes` (backward compat). Fix `leaveCouple` update remaining member status. Setup screen hiện `coupleCode` thay vì personal `inviteCode`.

- **File/hàm đụng tới:**
  - `lib/models/couple.dart`: thêm field `coupleCode: String?`, update constructor/toJson/toFirestore/toFirestoreUpdate/fromJson/copyWith
  - `lib/services/user_service.dart`: thêm `_coupleCodesCollection`, `fetchCoupleCodeEntry`, `createCoupleCodeEntry`, `deleteCoupleCodeEntry`
  - `lib/services/couple_service.dart`: thêm `import 'dart:math'`, `import '../models/account_invite.dart'`, `_generateCoupleCode()`, sửa `createCouple` (gen + write coupleCode), sửa `joinCoupleByCode` (double-lookup), sửa `leaveCouple` (update remaining member status), sửa `_cleanupCoupleSharedData` (xóa coupleCode entry)
  - `lib/screens/setup_screen.dart`: `_buildInviteCard` thêm param `coupleCode`, đổi `displayCode`, đổi title/desc khi `isWaitingForPartner`, thêm rejoin hint block
  - `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`: thêm 3 key mới (`setupWaitingCoupleCodeTitle`, `setupCoupleCodeDesc`, `setupCoupleCodeRejoinHint`)
  - `firestore.rules`: thêm `couple_codes` collection match; update `isValidCoupleDocument`, `isStrictCoupleDocument`, `onlyAllowedCoupleFieldsChanged` để accept optional `coupleCode` field

- **Thay đổi model / Firestore / Cloud Function / native config:**
  - **Firestore model mới:** `couple_codes/{code}` → `{coupleId: String, createdAt: Timestamp, updatedAt: Timestamp}`
  - **Firestore model thay đổi:** `couples/{id}` thêm optional field `coupleCode: String?`
  - **Rules:** thêm `couple_codes` collection; update couple rules
  - **Cloud Function:** không thay đổi (CF `deleteAccount` gọi `deleteCoupleCompletely` admin-side; không cần biết về `coupleCode`)

- **Cần deploy?** firestore:rules — ĐÃ DEPLOY dev + prod (2026-06-05)

## Bug fixes đi kèm

1. **Bug #1 — `leaveCouple` không update remaining member status:** Sau khi A rời, couple doc được update `memberIds=[B], status=waiting_partner` nhưng `users/B.status` vẫn là `in_couple`. Fix: thêm `_db.collection('users').doc(remainingUid).set({status: waiting_partner, updatedAt}, merge:true)` sau khi update couple doc. Best-effort (bọc try/catch).

2. **Bug #2 — `invite_codes/{A_code}.coupleId` bị reset null khi A rời:** Không còn liên quan với flow mới (joinCoupleByCode dùng `couple_codes` thay vì `invite_codes`). Old `invite_codes` vẫn còn nhưng chỉ dùng như fallback cho legacy couples.

3. **Bug #3 — Setup screen hiện personal `inviteCode` thay vì couple entry code:** Fix bằng cách `_buildInviteCard` nhận `coupleCode?` và hiện `coupleCode ?? inviteCode` khi `isWaitingForPartner`.

## Edge case kỹ thuật đã xử lý

- **Backward compat:** Old couples (không có `coupleCode` field) → `couple.coupleCode == null` → setup screen fallback về `inviteCode` → join vẫn dùng `invite_codes` path.
- **couple_codes cleanup thứ tự đúng:** `deleteCoupleCodeEntry` gọi TRƯỚC `docRef.delete()` vì rule check couple doc phải còn tồn tại.
- **createCoupleCodeEntry best-effort:** Bọc try/catch riêng — couple đã tạo không bị rollback nếu code entry write fail.
- **`_generateCoupleCode` uniqueness:** Kiểm tra collision trong `couple_codes` (không phải `invite_codes`) với 10 attempt; local fallback bỏ qua kiểm tra.
- **join flow mới không có "owner" check:** Khi `isNewCoupleCodeFlow = true`, bỏ `accountInvite.userId in memberIds` check (không có owner duy nhất nữa). Vẫn giữ check `memberCount == 1 && status == waiting_partner`.
- **remaining member status update:** Best-effort — nếu fail thì couple update đã thành công, user B sẽ correct về `waiting_partner` lần sau login (CoupleProvider/SessionResolver re-read trạng thái từ server).

## Checklist implement

- [x] `lib/models/couple.dart` — thêm `coupleCode` field
- [x] `lib/services/user_service.dart` — thêm couple_codes helpers
- [x] `lib/services/couple_service.dart` — `_generateCoupleCode`, `createCouple` gen coupleCode, `joinCoupleByCode` double-lookup, `leaveCouple` fix remaining member status, `_cleanupCoupleSharedData` delete coupleCode entry
- [x] `lib/l10n/app_vi.arb` + `app_en.arb` — 3 key mới
- [x] `flutter gen-l10n` — đã chạy
- [x] `lib/screens/setup_screen.dart` — hiện coupleCode, rejoin hint
- [x] `firestore.rules` — couple_codes collection + update couple rules
- [x] `flutter analyze` sạch (0 issues)
- [x] Deploy firestore:rules dev + prod

## Nhật ký implement

- [2026-06-05] [Dev] Implement feature couple-code: tách mã entry couple khỏi mã cá nhân, fix leaveCouple remaining member status, fix setup screen hiện đúng mã, deploy rules dev+prod.
