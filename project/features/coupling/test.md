# 🧪 Test — Coupling

> Tester sở hữu. CHỈ test, KHÔNG sửa code.

- **Trạng thái test:** ⬜ Chưa test có hệ thống (có couple_model unit mỏng)

## Test case ưu tiên
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | A tạo couple → B nhập mã → ghép | active, cả 2 in_couple | ⬜ |
| 2 | race | 2 người nhập cùng 1 mã đồng thời | Chỉ 1 thắng (transaction) | ⬜ |
| 3 | edge | A leave trước khi B join | Mã invalid, A về single | ⬜ |
| 4 | edge | Nhập mã của chính mình | Bị chặn | ⬜ |
| 5 | edge | Cả 2 cùng leave | Không state lạ, không ảnh orphan | ⬜ |
| 6 | security | User thường đọc toàn bộ `invite_codes` | Nên chặn (hiện đọc được) | ⬜ |
| 7 | security | Owner sửa `invite_codes.coupleId` | Nên chặn (hiện sửa được) | ⬜ |
| 8 | security | Non-member đọc couple waiting_partner (đoán coupleId) | Nên chặn | ⬜ |
| 9 | negative | Invite `"  abc 123  "` / 1000 ký tự | Normalize/reject đúng | ⬜ |
| 10 | edge | Join couple đã đủ 2 người | Reject | ⬜ |

*Rules cần Firebase emulator (chưa cấu hình).*

## Nhật ký test
- [2026-05-30] [PO] Tạo bộ case từ catalog; chờ Tester chạy.

## Audit bảo mật backend · 2026-10-12 (Tester backend, Lead xác nhận) — FAIL 1 P1

| # | Mức | Chỗ | Kịch bản → hậu quả | Expected | Vá |
|---|---|---|---|---|---|
| BE1 | **P1 bảo mật** (có từ 2026-05-30, không phải hồi quy) | `functions/index.js` `deleteAccount` (~2672-2690) lấy `coupleId` từ `users/{uid}` rồi gọi `handleCoupleOnAccountDeletion` (~2905-2944) không kiểm thành viên; `firestore.rules:77-108` (user tự ghi `coupleId` bất kỳ); `invite_codes`/`couple_codes` ai đăng nhập cũng đọc được | 1) Kẻ xấu có một mã mời/mã couple (link, QR của 1.9.0, hoặc người yêu cũ). 2) Đọc mã → `coupleId`. 3) Ghi `users/{mình}.coupleId = C`. 4) Gọi `deleteAccount` → CF ghi couple C `{status:'waiting_partner', memberCount:2}`. App 2 người thấy `isWaitingForPartner` → Home hiện checklist chờ, Chat/Quan tâm/Oẳn tù tì/chuỗi/Cây/nhắc câu hỏi tắt; không tự sửa được (rules join đòi `memberCount == 1`, sửa hồ sơ cấm đổi `status`). `notifyPartnerLeft` không chạy (số thành viên không đổi). | Người không thuộc couple xoá tài khoản thì couple không bị đụng tới | BE1: chốt `memberIds.includes(uid)` trong hàm dùng chung (phủ cả `leaveCoupleCleanup`) + test `node --test` |

- **Soát PROD (chỉ đọc, 2026-10-12):** 47 couple, 31 đang chờ, **0** couple có 2 thành viên mà ở `waiting_partner` → chưa ai khai thác.
- Harness: chạy nguyên văn hàm với db giả (scratchpad phiên `agent-sleep-native/delete_account_nonmember.js`).
- [2026-10-12] [Tester] Audit backend: BE1 P1 (chỉ cần một tài khoản bất kỳ + một mã). Vá ở CF, không cần bản app mới; cần deploy PROD `functions:deleteAccount,functions:leaveCoupleCleanup`.

## Nghiệm thu nhóm BE · 2026-10-12 (Tester, Lead xác nhận) — FAIL → vá vòng 3

- BE1 PASS cho kịch bản đã báo (chốt thành viên trong hàm dùng chung, phủ `deleteAccount` + `leaveCoupleCleanup`; gỡ chốt thì test đỏ). BE2–BE7 PASS (tương thích ngược 1.8.0: `setShare(true)` chỉ gọi khi đã có người ấy; `setShare(false)`/`setColor`/`enableTracking`/`putNight` không `tz` đều được). Số liệu: CF 5/5, rules 349 + 16 probe = 365 xanh; 8 + 6 lần gỡ vá đều đỏ.

| # | Mức | Chỗ | Kịch bản → hậu quả | Vá |
|---|---|---|---|---|
| N1 | **Critical** (có từ trước, cùng gốc BE1) | `functions/index.js` `leaveCoupleCleanup` (~2768) + `deleteAccount` (~2687) → `db.collection("couples").doc(coupleId)`; rules noteHistory (~460-468) cho tự chọn id + field tuỳ ý; ai đăng nhập cũng list được `couple_codes`/`invite_codes` | 1) Tài khoản bất kỳ tạo couple M. 2) List `couple_codes` lấy `coupleId` C của nạn nhân. 3) Tạo `couples/M/noteHistory/C` có `memberIds:[mình]`. 4) Gọi `leaveCoupleCleanup({coupleId:"M/noteHistory/C"})` → Admin SDK hiểu là doc con, `coupleRef.id = C`, chốt thành viên qua → `deleteStoragePrefix("couple_photos/C/")` xoá toàn bộ ảnh couple C. Lead đọc lại code xác nhận. | Dev BE vòng 3: helper kiểm `coupleId` dạng id ở mọi đường nhận |
| N2 | Major (có từ trước) | `deleteCoupleCompletely` (~3034-3044) | Field client ghi bị dùng làm đích xoá: `coupleCode` → xoá `couple_codes/<mã>` của couple khác rồi tạo lại trỏ về mình (người ấy của nạn nhân vào nhầm couple); `couplePhotoStoragePath` → xoá object Storage bất kỳ. | Dev BE vòng 3 |
| N3 | Minor | `scripts/test-firebase-rules.sh` (~104) + hook | Mocha thoát bằng số test hỏng → đúng 3 test hỏng ra mã 3, hook hiểu nhầm "thiếu JDK" nên không chặn. | Dev BE vòng 3 |
| N4 | Major (có từ trước) | `firestore.rules` `isCoupleJoinTransition` (~276-288) | Người duy nhất trong couple tự ghép một uid bất kỳ (lấy từ `invite_codes.userId`) → nạn nhân bị kéo vào couple, nhận push chat/"Quan tâm". | Dev BE vòng 3 |
| PA-N1 | P3 (do bản vá PA3) | `firestore.rules` couples (~386-393) | Đọc couple đã xoá cũng ra `permission-denied` → mã trỏ tới couple đã xoá bị báo "đã đủ 2 người". | Dev BE vòng 3: cho `get` khi `resource == null` |

- [2026-10-12] [Tester] Nghiệm thu BE: FAIL (N1 critical, N2/N4 major, N3 minor — đều có từ trước). Tester cố ý không chạy N1/N2 trên DEV/PROD (phá dữ liệu); probe emulator + harness SDK thật.

## Nghiệm thu vòng 3 BE · 2026-10-12 (Tester, Lead xác nhận) — PASS

| ID | KQ | Chứng cứ |
|---|---|---|
| N1 | PASS | Mọi chuỗi client dùng làm đường dẫn đều qua `isDocId` (5 callable + `coupleId`/`inviteCode` mà `deleteAccount` đọc từ `users/{uid}`); trigger chỉ dùng tham số đường dẫn hoặc field rules đã ghim. Harness SDK thật: 8 payload dạng đường dẫn → `invalid-argument`, couple C nguyên vẹn; gỡ `isDocId` thì tái hiện lại việc quét sạch `couple_photos/C/`. Id thật (auto-id, uuid v4, mã 6 ký tự) vẫn qua. CF 12/12. |
| N2 | PASS | `storage.rules` ở cả 6 bản lịch sử chỉ cho ghi `couple_photos/{coupleId}/{file}`; ảnh, ảnh thay, ảnh bìa của Dear Embeiu + Nịnh Vợ Iu đều nằm trong prefix được quét. `couple_codes` chỉ xoá khi còn trỏ về chính couple. |
| N3 | PASS | Mocha hỏng 1/3/255 test đều ra mã 1; thiếu JDK ra 3; hook chặn khi có test hỏng. |
| N4 | PASS | 358 + 15 probe = 373 xanh; người duy nhất thêm người khác / người ngoài thêm uid thứ ba / join lần 2 bị chặn; join đúng payload app (kể cả app 1.0), người tạo rời rồi quay lại vẫn qua. |
| PA-N1 | PASS | Couple không tồn tại → `exists false`; người có hồ sơ còn trỏ tới vẫn `permission-denied` (giữ `clearStaleCoupleRef` của bản cũ). |
| H1 | PASS | 126 commit `lib/` + Nịnh Vợ Iu chỉ `.doc(id).get/set/delete`; query/`count` bị chặn, get/listener 1 doc vẫn chạy. |

- Lưu ý: commit kèm `functions/test/` (đang untracked — thiếu thì `npm test` xanh giả); hook nay băm cả `functions/test/*.js` + `firebase_rules_test/test/*.js` (Lead sửa). Emulator log "maximum of 1000 expressions" ở 14 ca update couple bị từ chối sau N4 — kết quả vẫn từ chối, biên ca hợp lệ không đổi so với 1.9.0 [CẦN TEST runtime: ghép đôi + rời couple trên DEV với 2 máy].
- **Soát PROD chỉ đọc (Lead, 2026-10-12):** N4 — 47 couple, 63 lượt thành viên, 0 người có `users/{m}.coupleId` không trỏ về couple của mình, 0 thiếu doc user → chưa bị khai thác.
- [2026-10-12] [Tester] Nghiệm thu vòng 3 BE: PASS. Cần deploy PROD `firestore:rules` + 8 function (xem `AUDIT-2026-10-12.md`); deploy xong kiểm `updateTime` từng hàm.
- [2026-10-12] [Tester] Audit luồng ghép đôi (tạo couple → mã → join → rời/xoá), read-only, nhánh `feature/home-widget`@bb73ac1: **FAIL** — **PJ-1 P1** `firestore.rules:394-401` `allow read` cho couple chờ → tài khoản bất kỳ list MỌI couple đang chờ kèm mã mời (PROD ~31, đang mở; vá 1 từ `allow get`) · PJ-2 P2 `couple_codes` create không buộc `code == coupleCode` (trỏ mã cá nhân nạn nhân về couple mình) · PJ-3 P2 mạng chậm lúc mở app → Setup tạo couple thứ hai / rời nhầm couple · 9 P3. Emulator probe 8/8, test ghép đôi 36/36, CF 12/12. Chi tiết: [`project/AUDIT-2026-10-12-account-flows.md`](../../AUDIT-2026-10-12-account-flows.md). Chưa vá (user: chỉ audit).
