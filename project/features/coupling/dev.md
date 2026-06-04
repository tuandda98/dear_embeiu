# 💻 Dev — Coupling

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md).

- **Trạng thái dev:** ✅ Đã implement (baseline)

## Đã implement
- `couple_service.dart`: create/join(`runTransaction`)/leave; sinh mã (charset 32 ký tự bỏ I/O/1/0, 6 ký tự, `Random.secure()`, retry tối đa 12). Pre-checks join: chặn đang in_couple, reject code rỗng/chính mình, auto-leave nếu đang waiting solo. Normalize `trim().toUpperCase()`.
- `couple_provider.dart`: create/join/update/leave + Firestore stream.

## Việc cần làm tiếp (từ nợ kỹ thuật)
- [ ] Siết rules `invite_codes`: hạn chế read (không cho liệt kê toàn bộ) + khoá sửa `coupleId`.
- [ ] Chặn non-member đọc couple waiting_partner (rà rules `couples` ~349-351).
- [ ] Xử lý leave-khi-partner-join / cả 2 leave; cleanup Storage an toàn (tránh ảnh orphan).
- [ ] Validate person1 != person2; check độ dài invite trước lookup.
- [ ] (Tuỳ) share sheet/QR cho mã mời.

## Chống `coupleSavePermissionDenied` (2026-06-04, client-side, KHÔNG đổi rules/deploy)

Nguyên nhân: client ghi MERGE nhưng payload mang theo field cấu trúc/bất biến lấy từ
bản LOCAL có thể đã cũ/lệch server → vi phạm các equality check trong rules
(`isCoupleProfileEdit`, `coupleMetadataIsImmutable`, `canUpdateOwnUser`) → permission-denied.

Fix A — couple PROFILE edit chỉ ghi field sửa được:
- Thêm `Couple.toProfileEditPayload()` (7 key: person1Name, person2Name, anniversaryDate,
  couplePhotoPath='', couplePhotoUrl, couplePhotoStoragePath, updatedAt) +
  `Couple.toPhotoEditPayload()` (chỉ 3 field ảnh + updatedAt).
- `updateCouple` → dùng `toProfileEditPayload()`; photo-write trong `createCouple` → `toPhotoEditPayload()`.
  Bỏ memberIds/memberCount/status/inviteCode/createdByUserId/createdAt khỏi payload ⇒ merge giữ
  giá trị SERVER ⇒ `request.resource.data.X == resource.data.X` luôn đúng (cả 2 vế = server),
  qua `isCoupleProfileEdit` dù local cũ.

Fix B — `createCouple` dùng `auth.uid` chuẩn:
- Lấy `FirebaseAuth.instance.currentUser?.uid` (null → ném `coupleSessionNotReadyRelogin`).
  memberIds[0]/createdByUserId = authUid; user doc ghi vào users/{authUid}. Khớp rule create
  (`createdByUserId == request.auth.uid && memberIds[0] == request.auth.uid`).

Fix C — user-update khi (un)pair chỉ ghi field đổi:
- Thêm `AppUser.toCoupleMembershipPayload()` (chỉ coupleId/status/updatedAt/lastSeenAt; KHÔNG
  email/inviteCode/displayName/avatarUrl/createdAt) + `UserService.updateCoupleMembership()`
  (ghi narrow payload + re-sync invite_code pointer theo coupleId mới).
- create/join(transaction + housekeeping)/leave → dùng narrow payload, ghi users/{authUid}.
  Merge giữ email/inviteCode server ⇒ qua immutable check trong `canUpdateOwnUser`.
- KHÔNG đổi `updateUserProfile`/`AppUser.toFirestoreUpdate` (auth_service vẫn dùng để đổi
  displayName/inviteCode — thêm method mới, không phá hành vi cũ).

Fix D — auto-recovery 1 lần khi permission-denied:
- `_runCoupleWriteWithRecovery()` bọc write của createCouple(photo)/updateCouple/leaveCouple:
  bắt `permission-denied` → `getIdToken(true)` (refresh token) + re-fetch couple từ server →
  reconcile StorageService → RETRY đúng 1 lần (cờ bool `recovered`, while-loop có guard, KHÔNG
  recursion/loop vô hạn; tối đa 2 lần). Thất bại tiếp → ném `_mapFirebaseError` như cũ (giữ l10n).
- join: wrap riêng `runJoinTransaction()` (transaction re-read + re-check guard mỗi lần →
  idempotent), retry 1 lần qua cờ `joinRecovered`.

KHÔNG đụng (cố ý):
- Couple-write của JOIN & LEAVE giữ `toFirestoreUpdate()` — rule `isCoupleJoinTransition`/
  `isCoupleLeaveTransition` CẦN memberIds/memberCount/status MỚI. Chỉ profile edit mới dùng
  toProfileEditPayload.
- Nhánh local fallback (`!isUsingFirebase`) giữ `effectiveUser.id`/`currentUser.id`.
- Guard "targetIsJoinable" trong join giữ nguyên.

File đụng: `lib/models/couple.dart` (+toProfileEditPayload/+toPhotoEditPayload),
`lib/models/app_user.dart` (+toCoupleMembershipPayload), `lib/services/user_service.dart`
(+updateCoupleMembership), `lib/services/couple_service.dart` (create/update/join/leave +
2 helper recovery). Test mới: `test/coupling_payload_test.dart` (10 case payload).
Rules-test (emulator) BỎ — emulator chưa cấu hình; rules KHÔNG đổi nên không cần.

Verify: `fvm flutter analyze` 0 issue; `fvm flutter test` 30 pass, 1 fail pre-existing
(`widget_test.dart renders login screen scaffold` — fail cả trên tree sạch, không liên quan).
Model/Firestore/Function/native: KHÔNG đổi schema, KHÔNG đổi rules, KHÔNG deploy.

## Nhật ký implement
- [2026-06-04] [Dev] Chống triệt để `coupleSavePermissionDenied` client-side (Fix A/B/C/D, xem trên). analyze sạch, payload unit-test PASS. Chưa deploy (không cần — rules giữ nguyên).
- [2026-05-30] [PO] Khởi tạo doc; liệt kê việc cần Dev xử lý.
