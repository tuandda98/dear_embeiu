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

## Bug fix — realtime sync sau create/join (2026-06-05)
> **Triệu chứng (user báo):** A tạo couple xong, B nhập mã join → **A không tự re-load/sync**: Home vẫn hiện mã mời (couple kẹt `waiting_partner`), và **không nhắn tin được** (love-note). Restart app mới hết.
- **Root cause:** `setup_screen.dart` sau `createCouple`/`joinCoupleByCode` điều hướng `pushReplacementNamed(home)` **THẲNG**, bỏ qua `authGate→SessionResolver`. Mà realtime `watchCouple` (start trong `CoupleProvider.loadCoupleForUser`) + wiring watch love-note/daily-question/reaction/streak **CHỈ chạy trong `SessionResolver._resolve`**. ⇒ creator vào Home không có watcher nào → couple doc đổi (B join: memberIds 1→2, status→active) không bao giờ tới A. Vi phạm chính nguyên tắc "mọi luồng qua authGate→resolver".
- **Fix:** `setup_screen.dart` — create (non-editing) + join giờ `pushNamedAndRemoveUntil(AppRoutes.authGate, false)` thay vì `home`. Resolver wire đủ TẤT CẢ watcher (1 nguồn duy nhất). Home đã reactive sẵn (`Consumer2<CoupleProvider,…>` + đọc `couple.isWaitingForPartner` live) nên couple stream fire → mã mời ẩn + messaging bật ngay. Editing GIỮ NGUYÊN (pop về settings — membership-neutral, watcher đã sống từ cold-start).
- **Phạm vi:** chỉ `lib/screens/setup_screen.dart` (2 chỗ điều hướng). KHÔNG đụng provider/service/rules. `flutter analyze` sạch.
- **Hạn chế còn lại (minor, không phải bug báo):** `StreakProvider.watchForCouple(coupleActive:)` set 1 lần lúc resolver → streak của creator có thể chưa "active" live tới lần mở app kế (fail-soft, shame-free). Cần 2-thiết-bị smoke-test xác nhận end-to-end.

## Leave couple — dọn sạch dữ liệu (không để rác mồ côi) + xác nhận xoá vĩnh viễn (2026-06-06)
> **Yêu cầu user:** (1) khi người **cuối cùng** rời couple thì dữ liệu chung xử lý thế nào cho đúng; (2) hỏi xác nhận "xoá vĩnh viễn, không khôi phục được" trước khi xoá.
- **🐛 Bug gốc:** nhánh người-cuối-rời ở `couple_service.leaveCouple` gọi `_cleanupCoupleSharedData` + `docRef.delete()` — nhưng client cleanup **chỉ xoá `photos` + `couple_codes`**, KHÔNG xoá `notes`/`noteHistory`/`dailyAnswers`(+responses)/`photos/*/reactions`. Firestore **không cascade subcollection** khi xoá doc cha → rác mồ côi nằm lại DB vĩnh viễn (tốn dung lượng + nợ privacy). Client SDK không có `recursiveDelete` (chỉ admin có).
- **Fix server-side (admin recursiveDelete = sạch tuyệt đối):**
  - **CF mới `leaveCoupleCleanup`** (onCall, us-central1): auth-guard + **membership-guard** (caller PHẢI ∈ `memberIds`, chống user khác phá/demote couple lạ) → gọi lại `handleCoupleOnAccountDeletion(coupleId, uid)` (cùng semantics account-delete: remove uid → rỗng thì `deleteCoupleCompletely`, còn người thì demote `waiting_partner`).
  - **`deleteCoupleCompletely` vá thêm 2 lỗ rác** (lợi cả luồng xoá tài khoản): `recursiveDelete(noteHistory)` + xoá top-level `couple_codes/{code}` (recursiveDelete couple KHÔNG đụng tới vì là doc top-level, không phải subcollection). Trước đó cả 2 bị mồ côi cả khi xoá tài khoản.
  - **Client `couple_service.leaveCouple`** nhánh sole-member: gọi `_functions.httpsCallable('leaveCoupleCleanup')`; **fallback** về client cleanup cũ nếu callable lỗi (transient) để user vẫn rời được. Nhánh demote (còn partner) GIỮ NGUYÊN — không đụng, không orphan.
- **Xác nhận xoá vĩnh viễn (UI):** `settings_screen._showLeaveCoupleDialog` đọc `CoupleProvider.couple.memberCount` — `<=1` (sole member) → đổi sang copy cảnh báo mạnh: tiêu đề "Xoá vĩnh viễn không gian của hai người?", nội dung liệt kê ảnh/lời nhắn/nhật ký + "KHÔNG THỂ khôi phục", nút đỏ "Xoá tất cả". Còn partner (`memberCount==2`) → giữ copy nhẹ cũ (người kia vẫn giữ data). **+3 key l10n** vi/en (`leaveCoupleDeleteAllTitle/Content/Btn`) + gen-l10n.
- **Đổi máy ≠ rời couple:** xác nhận với user — couple gắn Auth UID (lưu `users/{uid}.coupleId` + couple `memberIds`=UID trên Firestore), đổi điện thoại đăng nhập lại cùng account thì couple+data còn nguyên (nguồn thật là Firestore, local chỉ là cache). `leaveCouple` chỉ chạy khi bấm nút Rời hoặc xoá tài khoản. (single-session chỉ đăng xuất *thiết bị* cũ, không rời couple.)
- **Deploy:** functions `leaveCoupleCleanup`(create)+`deleteAccount`(update) lên **dev** (2026-06-06). ⚠️ **Prod CHƯA deploy** — chờ user cho phép (luật no-prod-deploy). `flutter analyze` sạch.

## Nhật ký implement
- [2026-06-06] [Dev/Lead] **Fix UX leave couple "đứng màn settings rồi đá ra ngoài" (2 vòng).**
  - **Vòng 1 — root cause:** `settings_screen` có `BlockingLoadingOverlay` CHỈ nghe `authProvider.isLoading` (nên delete-account mượt vì set auth loading), nhưng leave couple chạy qua `coupleProvider.leaveCouple` (set `coupleProvider.isLoading`) + `authProvider.updateCurrentUser` (await push-sync mạng, KHÔNG set loading nào) → **cả 2 đoạn await không có overlay** → màn settings đứng im 2–5s (callable `leaveCoupleCleanup` recursiveDelete + cold-start CF) rồi `pushNamedAndRemoveUntil` đột ngột. Thêm: lỗi bị nuốt im (`catch(_){return;}`). Tách handler `_performLeaveCouple` + thêm phản hồi loading + snackbar lỗi (key mới `leaveCoupleError` vi/en).
  - **Vòng 2 — user phản hồi:** loader "không đồng bộ toàn app" + "vẫn lộ màn settings phía sau". Bỏ progress-dialog tự chế (CircularProgressIndicator nhỏ nổi trên settings) → chuyển `SettingsScreen` thành **StatefulWidget** với cờ `_leaving`; khi `_leaving` build **short-circuit** trả về **đúng loader chuyển màn chuẩn của app** = `SessionRouteScreen._buildMinimal` (full-screen `secondaryGradient` đục + `CircularProgressIndicator` trắng + label "Đang rời cặp đôi…"), bọc `PopScope(canPop:false)` khoá back. Vì `secondaryGradient == dawnBlush` (nền settings) và authGate→`SessionRouteScreen` cũng dùng gradient này → **che kín settings + bàn giao liền mạch không nháy** sang màn kế tiếp. `BlockingLoadingOverlay` cho sign-out/delete GIỮ NGUYÊN (không đụng). Lỗi → `setState(_leaving=false)` + snackbar.
  - Không đụng service/provider/rules/functions. analyze sạch. Chỉ sửa `lib/screens/settings_screen.dart` + 1 key l10n.
- [2026-06-12] [Dev/Lead] **Màn Chỉnh sửa hồ sơ cặp đôi (`setup_screen.dart`, chế độ editing):** (1) thêm **nút back squircle chuẩn** (`HeaderIconButton` arrowLeft, `Navigator.maybePop`) ở góc trên-trái — CHỈ khi `isEditing` (create mode là setup landing qua authGate, không có gì để pop → giữ nút sign-out). (2) **Disable nút "Lưu thay đổi" khi chưa có thay đổi**, enable khi có: tận dụng `_hasPendingChanges` sẵn có → tính `canSaveEdit` trong build (cần đủ field + có thay đổi thật), `onPressed=null` khi `!canSave`, thêm `disabledBackgroundColor` rose .35. Reactive bằng `addListener(_onFormChanged→setState)` gắn vào 2 text controller SAU prefill (tránh setState mid-build); `_pickDate`/`_pickPhoto` đã setState sẵn. Create mode `canSave` mặc định true (không đổi hành vi). analyze sạch, không đụng service/provider/rules.
- [2026-06-06] [Dev/Lead] Leave couple dọn sạch + xác nhận xoá vĩnh viễn (xem mục trên). CF mới `leaveCoupleCleanup` (membership-guard, recursiveDelete) + vá `deleteCoupleCompletely` (noteHistory + couple_codes). Client `leaveCouple` sole-branch → callable (fallback client cleanup). Dialog điều kiện theo `memberCount` (+3 key l10n vi/en). Deploy **dev** thôi. analyze sạch.
- [2026-06-05] [Dev/Lead] Fix realtime sync sau create/join: route qua `authGate` để resolver wire watcher (couple stream + love-note/daily-question/reaction/streak). Sửa `setup_screen.dart` (2 navigation). analyze sạch, không deploy. Chờ 2-device smoke-test.
- [2026-06-05] [Dev/Lead] **Fix "This account already belongs to a couple" sau khi leave rồi join lại.** Root cause: leave handler `settings_screen._showLeaveCoupleDialog` gọi `coupleProvider.leaveCouple()` nhận `updatedUser` (single) nhưng **KHÔNG `authProvider.updateCurrentUser(updatedUser)`** (create/join đều có gọi). ⇒ `authProvider.currentUser` stale (coupleId cũ + `in_couple`) → join pre-check `currentUser.hasCouple && status=='in_couple'` ném `alreadyHasCouple` + resolver misroute. Firestore đã đúng (coupleId=null qua `toCoupleMembershipPayload`) nên restart hết — đúng dấu hiệu in-memory stale. Fix: thêm `await authProvider.updateCurrentUser(updatedUser)` + đổi điều hướng `setup`→`authGate` (resolver clear watcher couple/love-note/dq/reaction/streak cho trạng thái single). analyze sạch, 18/18 test. Chỉ `setup_screen` lần trước + `settings_screen` lần này; không đụng service/rules.
- [2026-06-05] [Dev/Lead] **Leave couple — notify + dev parity.** (1) MỚI CF `notifyPartnerLeft` (`functions/index.js`, onDocumentUpdated couples): guard transition `memberIds` 2→1 & status→`waiting_partner` → push member còn lại (`{name} đã rời khỏi không gian của hai người`, `type:partner_left`); cũng fire khi A xoá tài khoản (deleteAccount demote admin-side). **Deploy dev+prod.** (2) "Partner vẫn in couple" = cùng gốc bug realtime watch (đã fix bằng setup→authGate ở trên — sau rebuild B thấy A rời realtime vì couple stream fire → home đọc `couple.isWaitingForPartner` live). (3) **DB dev thiếu function:** dev mới tạo chỉ có `sendCustomVerificationEmail` → deploy ĐỦ 9 function lên dev (parity prod): `deleteAccount`/`pruneDeadDevices` OK ngay; 6 function Firestore-trigger FAIL lần đầu (Eventarc service-agent chưa propagate) → retry sau ~2 phút OK 6/6. `node -c` OK. Lưu ý: B's user.status giữ `in_couple` (client không ghi được user doc của B) nhưng home key theo couple.status nên UI vẫn đúng.
- [2026-06-04] [Dev] Chống triệt để `coupleSavePermissionDenied` client-side (Fix A/B/C/D, xem trên). analyze sạch, payload unit-test PASS. Chưa deploy (không cần — rules giữ nguyên).
- [2026-05-30] [PO] Khởi tạo doc; liệt kê việc cần Dev xử lý.
