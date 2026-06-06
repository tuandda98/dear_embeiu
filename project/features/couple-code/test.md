# Test — couple-code (Mã ghép đôi riêng)

- **Trạng thái test:** PASS (code-level) · 2 minor issue đã fix
- **Người/role:** Master Tester
- **Ngày:** 2026-06-05

## Kết quả nghiệm thu

| AC | Mô tả | Kết quả | Ghi chú |
|----|-------|---------|---------|
| AC1 | A rời (B ở lại): A nhập `coupleCode` → rejoin | ✅ PASS | coupleCode ≠ personal inviteCode → không bị "own code" chặn. `isNewCoupleCodeFlow=true` bỏ owner check. |
| AC2 | B rời (A ở lại): B nhập `coupleCode` → rejoin | ✅ PASS | B đã rời (`status=single`) → không bị `alreadyInThisCouple`. isNewCoupleCodeFlow path. |
| AC3 | Cả 2 rời: couple + `couple_codes` entry bị xóa | ✅ PASS | `_cleanupCoupleSharedData` delete `couple_codes` entry trước `docRef.delete()` — đúng thứ tự. |
| AC4 | Sau A rời, `users/B.status == 'waiting_partner'` | ✅ PASS | best-effort write sau update couple doc. `couple_service.dart:641-650`. |
| AC5 | Setup screen hiện `couple.coupleCode` khi waiting | ✅ PASS | `displayCode = isWaitingForPartner ? (coupleCode ?? inviteCode) : inviteCode`. |
| AC6 | Old couples: join bằng `invite_codes` vẫn hoạt động | ✅ PASS | Double-lookup: `couple_codes` trước → fallback `invite_codes`. |
| AC7 | `flutter analyze` 0 error | ✅ PASS | Flutter 3.41.6: `No issues found!` |
| AC8 | Firestore rules deploy dev + prod | ✅ PASS | Đã deploy 2026-06-05 (cả 2 project). |

## Tổng: 8 PASS / 0 FAIL

## Issues đã fix (post-test)

### Issue 1 — Post-create dialog hiện personal inviteCode (đã fix)
- **Mô tả:** Dialog sau khi tạo couple hiện personal `inviteCode` thay vì `coupleCode`.
- **Fix:** `setup_screen.dart:197` → `result.couple.coupleCode ?? result.updatedUser.inviteCode`
- **Trạng thái:** ✅ Fixed 2026-06-05

### Issue 2 — `couple_codes` CREATE rule thiếu membership check (đã fix)
- **Mô tả:** Rule create không verify caller là member của couple → bất kỳ signed-in user tạo được entry.
- **Fix:** Thêm `&& isCoupleMember(request.resource.data.coupleId)` vào CREATE rule; re-deploy dev+prod.
- **Trạng thái:** ✅ Fixed + deployed 2026-06-05

## VERDICT: PASS ✅

## Nhật ký test

- [2026-06-05] [Tester] Nghiệm thu couple-code. 8/8 AC PASS. Ghi nhận 2 minor issue.
- [2026-06-05] [Dev/Lead] Fix Issue 1 (dialog) + Issue 2 (rules security). Re-deploy rules dev+prod.
