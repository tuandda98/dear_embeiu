# Couple Code (Mã ghép đôi riêng)

- **Feature:** couple-code
- **Ưu tiên:** P0
- **Trạng thái:** ✅ Done (2026-06-05)
- **Tạo ngày:** 2026-06-05
- **Liên quan:** [dev.md](dev.md) · [design.md](design.md) · [test.md](test.md) · [CLAUDE.md](../../../CLAUDE.md)

## 1. Vấn đề & giá trị

- **Vấn đề:** `users/{uid}.inviteCode` đóng hai vai trò — định danh cá nhân + entry point vào couple. Khi A rời couple (B ở lại), `invite_codes/{A_code}.coupleId` bị reset → A không rejoin được; B kẹt `in_couple` status; không có UX rejoin.
- **Giá trị:** Couple có thể rời rồi quay lại mà không cần tạo couple mới, không mất flow.
- **Đối tượng:** Cặp đôi đã ghép, 1 hoặc 2 người rời và muốn quay lại.
- **Đo bằng:** Zero báo cáo "kẹt, không ghép lại được" sau release.

## 2. Bối cảnh

Phân tích root cause từ code (2026-06-05):
- `leaveCouple` chỉ update người rời, không update `users/B.status` → B kẹt `in_couple`.
- `_syncInviteCode` set `coupleId: null` khi rời → mã bị mất liên kết couple.
- `joinCoupleByCode` block "cannot use own code" → A không thể dùng code cá nhân để rejoin dù couple của B đang chờ.

## 3. Phạm vi

**Trong phạm vi:**
- Tách `couple.coupleCode` (mã riêng của couple) khỏi `user.inviteCode` (mã cá nhân/identity)
- Collection mới `couple_codes/{code}` → `{ coupleId, createdAt, updatedAt }`
- Fix Bug: `leaveCouple` update remaining member status → `waiting_partner`
- UI: hiện `coupleCode` trên setup screen khi waiting, không hiện personal inviteCode
- Backward compat: old couples join vẫn hoạt động qua `invite_codes` fallback
- Deploy Firestore rules (dev + prod)

**Ngoài phạm vi:**
- Regenerate couple code (đổi mã couple) — v2
- Warning dialog trước khi xóa couple data — feature riêng
- Hiển thị coupleCode trên Home screen banner — v2

## 4. Quyết định đã chốt

- **D1 — Tách mã:** `couple.coupleCode` được gen fresh khi tạo couple (≠ `user.inviteCode`). `user.inviteCode` trở thành thuần identity. *Lý do:* dual-role là root cause; tách là fix sạch nhất.
- **D2 — Backward compat:** Join lookup `couple_codes` trước; fallback `invite_codes` (old couples). *Lý do:* không break production user nào.
- **D3 — Immutable coupleCode:** Sau khi set, `coupleCode` không đổi (v1). *Lý do:* đơn giản, không cần regeneration UI chưa làm.

## 5. Acceptance criteria

- [ ] **AC1** — A rời (B ở lại): A nhập `coupleCode` → rejoin thành công
- [ ] **AC2** — B rời (A ở lại): B nhập `coupleCode` → rejoin thành công
- [ ] **AC3** — Cả 2 rời: couple bị xóa + `couple_codes` entry bị xóa; 1 người tạo couple mới → code mới → người kia join
- [ ] **AC4** — Status fix: sau khi A rời, `users/B.status == 'waiting_partner'` (không còn `in_couple`)
- [ ] **AC5** — Setup screen `isWaitingForPartner`: hiện `couple.coupleCode`, không phải `user.inviteCode`
- [ ] **AC6** — Old couples: join bằng code cũ (`invite_codes`) vẫn hoạt động
- [ ] **AC7** — `flutter analyze` 0 error sau khi implement
- [ ] **AC8** — Firestore rules deploy thành công cả dev + prod

## 6. Giao việc 3 vai

- 🎨 **Designer:** Spec UI cho setup screen invite card khi `isWaitingForPartner` (hiện coupleCode + copy hint). Không cần màn mới.
- 💻 **Dev:** Implement toàn bộ (model, service, rules, UI, deploy). Xem [dev.md](dev.md).
- 🧪 **Tester:** Verify 8 AC trên thiết bị thực / analyze. Xem [test.md](test.md).

## 7. Changelog

- [2026-06-05] [PO] Khởi tạo spec. Root cause = dual-role inviteCode. Chọn giải pháp couple-code riêng.
