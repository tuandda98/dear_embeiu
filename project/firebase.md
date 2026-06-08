# Firebase backend — Dear Embeiu

> Chi tiết tách từ `CLAUDE.md §5`. Đọc khi làm việc với Firestore rules/functions/deploy/Dev-Prod.

## Dev/Prod split

2 project — **PROD `tonyembeiu`** (app live) + **DEV `tonyembeiu-dev`** (sandbox). Switch theo **build-config ở tầng native, KHÔNG flavor, KHÔNG sửa `lib/`**: **chỉ `--release` → PROD; debug + `--profile` → DEV** (prod = FALLBACK an toàn, release/config lạ không bao giờ ship config dev; profiling không đụng data prod).

**Bundle id tách theo môi trường (2026-06-05, để cài cạnh nhau KHÔNG đè):** release=`com.tony.dearembeiu` ("Dear Embeiu") · debug/profile=`com.tony.dearembeiu.dev` ("Dear Embeiu Dev") — bản dev là app riêng trên device, không đè bản App Store.

- iOS: Podfile post_install gán `PRODUCT_BUNDLE_IDENTIFIER`+`APP_DISPLAY_NAME` theo config; Info.plist dùng `$(APP_DISPLAY_NAME)`.
- Android: `applicationIdSuffix=".dev"` + label `${appName}` (`build.gradle.kts` `configureEach`).
- ⚠️ Config dev phải đăng ký theo id `.dev` trong project dev (3 file: `src/{debug,profile}/google-services.json` + `ios/config/dev` plist) — thiếu thì build dev FAIL "No matching client" (release/prod KHÔNG ảnh hưởng).
- Android: Gradle plugin tự chọn `app/src/{debug,profile}/google-services.json` (dev) vs `app/google-services.json` (prod).
- iOS: build-phase `Select GoogleService-Info (env)` (Podfile post_install, chạy đầu tiên) copy `ios/config/{dev|prod}/GoogleService-Info.plist` theo `$CONFIGURATION` (Debug/Profile→dev, else→prod); file động `ios/Runner/GoogleService-Info.plist` đã untrack+gitignore (nguồn thật `ios/config/`).
- `.firebaserc` alias: **`default`=`tonyembeiu-dev` (an toàn, bare deploy không trúng prod)**, `prod`, `dev`. Deploy prod PHẢI `--project prod`.
- ⚠️ Dev project cần bật console 1 lần (Firestore DB + Email/Password Auth + Storage bucket; Functions cần Blaze).
- **✅ Functions parity (2026-06-05):** dev đã deploy ĐỦ 9 function = prod (trước đó chỉ có `sendCustomVerificationEmail` → dev không có push + `deleteAccount` hỏng).
- ⚠️ Lần ĐẦU deploy 2nd-gen functions lên project mới: trigger-Firestore (Eventarc) có thể FAIL *"Permission denied while using the Eventarc Service Agent"* — **retry sau ~2-3 phút là OK** (chờ service-agent propagate).
- Chi tiết đầy đủ: [`DEV_PROD_SETUP.md`](../DEV_PROD_SETUP.md).

## Backward-compat

⚠️ Backend prod DÙNG CHUNG cho mọi version app đang cài (1.0 cũ + 1.1 mới). Field optional thêm sau (`coupleCode`/`languageCode`/`sessionToken`) PHẢI đọc bằng `data.get('field', null)` trong rules — KHÔNG `data.field` trực tiếp (key vắng mặt do app cũ không gửi → engine báo "undefined" → DENY → app 1.0 vỡ `permission-denied`). Đã vá 3 field này + có test `firestore.backward-compat.test.js` khoá. Sửa rules = **chỉ ADDITIVE**, không siết cái app cũ đang dùng.

## Firestore data model

### `users/{uid}`
Profile, `inviteCode`, `coupleId`, status. Rules: tạo own (schema chặt), email immutable, inviteCode immutable khi đã set; `allow delete: if false`.

### `invite_codes/{code}`
Map mã mời → account (userId, displayName, coupleId). `createdAt`/`userId` immutable; `allow delete: if false`.

### `couples/{coupleId}`
Không gian chung; tạo solo (memberIds=1, `waiting_partner`); join → memberIds=2, `active`; leave → demote về `waiting_partner`; xoá chỉ khi còn 1 member. inviteCode + creator immutable.

### `couples/{coupleId}/photos/{photoId}`
Feed ảnh; members CRUD; tạo phải đúng author; authorUserId + uploadDate immutable.

### `couples/{coupleId}/photos/{photoId}/reactions/{uid}`
Reactions ❤️ (feature reactions b1, 2026-06-04). 1 doc/người/ảnh (id=uid), `{emoji, reactedAt, authorUserId, coupleId}`; 6 emoji hợp lệ `❤️😍😂🥹🔥👍`. Watch qua **collectionGroup('reactions').where(coupleId)** (cần collection-group index `reactions.coupleId` — đã ở `firestore.indexes.json`, đã deploy). Rules ADDITIVE (write: uid==auth.uid && authorUserId==auth.uid && emoji∈6 && coupleId khớp). CF `notifyPhotoReaction` push tác giả ảnh (skip khi tự react). 3 surface: feed bar / fullscreen on-dark / Home badge read-only.

### `couples/{coupleId}/notes/{uid}`
Love Note (feature #4, 2026-06-02). 1 doc/người (doc id = author uid), `{authorUserId, text ≤140, updatedAt}`, ghi đè (chưa lịch sử). Rules ADDITIVE: read if member; write if member && noteId==auth.uid && authorUserId==auth.uid && text ≤140. Hiện trên Home đối phương (thay card tĩnh `_buildQuoteCard`); CF `notifyLoveNote` push khi đổi.

### `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}`
Daily Question (feature #5, 2026-06-02). Bank `lib/data/daily_questions.dart` **229** câu vi/en — a1 2026-06-04: chọn no-repeat theo couple `questionForCouple` (FNV-1a hash coupleId + permutation Fisher–Yates, index theo `daysSinceEpoch` → cùng couple+ngày cùng câu, không lặp trong 229 ngày; bỏ day-of-year cũ); ngày=giờ máy local. 1 doc/người/ngày (doc id=author uid), `{authorUserId, text ≤280, answeredAt}`. Reveal câu partner chỉ sau khi BẠN trả lời — enforce ở provider `hasRevealed`; rules cho cả 2 member đọc (reveal là UI affordance v1).

**Marker doc cha `dailyAnswers/{date}`** = `{date, questionVi, questionEn, updatedAt, bothAnswered?, revealedAt?}` — a2: lưu thẳng text câu hỏi để Nhật ký chính xác vĩnh viễn; b3: cờ `bothAnswered` set client-side khi đủ 2 response → streak.

Rules ADDITIVE (write responses: uid==auth.uid && authorUserId==auth.uid && text ≤280; marker: member ghi date/questionVi/questionEn string ≤300 — đã DEPLOY). CF `notifyDailyAnswer` push partner; `deleteCoupleCompletely` dùng `recursiveDelete(dailyAnswers)`.

### `users/{uid}/devices/{...}`
FCM tokens: token, platform, notificationsEnabled, **languageCode**, updatedAt.

⚠️ Rule `isValidDeviceDocument` dùng `hasOnly` → **PHẢI liệt kê đủ field client ghi** (client ghi `languageCode` cho CF localize; thiếu nó trong rule → device write `permission-denied` → "Push token sync failed", push hỏng âm thầm). Đã vá + deploy 2026-06-04.

**Bài học:** deploy `firestore:rules` GHI ĐÈ production bằng file repo — repo rules phải luôn khớp field client ghi, nếu không sẽ regression.

### `users/{uid}/notifications/{autoId}`
Notification center (feature notifications, 2026-06-06). Inbox bền vững cho 6 loại push (ảnh/reaction/lời nhắn/câu hỏi ngày/ghép đôi/rời đi). **CHỈ CF (admin) ghi** (`writeInboxNotifications` gọi trong cả 6 sender, độc lập push delivery); client read/mark-read(chỉ field `read`)/delete của mình, **`create: if false`**.

Field structured: `{type, coupleId, actorUserId, actorName, createdAt, read, +photoId/emoji/noteExcerpt/caption/date}` → client render text theo LOCALE HIỆN TẠI (không freeze ngôn ngữ lúc gửi). Stream `where coupleId==current orderBy createdAt desc limit 50` (composite index `notifications`: coupleId asc + createdAt desc — `firestore.indexes.json`). Rules ADDITIVE (app cũ 1.0/1.1 bỏ qua). `deleteAccount` + teardown `recursiveDelete(notifications)`. Bell+badge header Home → `NotificationCenterScreen` (tap item → đổi tab qua `NotificationTapRouter`, đánh dấu đã đọc, vuốt xoá). 13 rules unit test.

✅ Deploy DEV; **prod chờ lệnh user.**

### `reports/{autoId}`
UGC moderation reports (Apple Guideline 1.2). Field: reporterUid, coupleId, photoId, authorUserId, reason (mã ổn định inappropriate/spam/other), createdAt. Rules create-only: `allow create: if request.auth != null; allow read, update, delete: if false`. Admin xem qua Console; client không đọc/sửa/xoá.

## Storage

`storage.rules`: `couple_photos/{coupleId}/{file}` — chỉ members; create/update yêu cầu ảnh < 10MB; không public.

## Cloud Functions (`functions/index.js`, firebase-functions v2)

**Helpers dùng chung:**
- `sendToRecipientDevices` — localize push copy vi/en theo `languageCode` từng device, fallback vi; xoá token invalid sau gửi.
- `writeInboxNotifications` (2026-06-06) — mỗi push cũng ghi 1 doc inbox `users/{uid}/notifications` cho từng recipient; gọi trong cả 6 sender TRƯỚC khi gửi, độc lập deviceCount/push delivery; resilient nuốt lỗi để không vỡ push.

### Functions list

- **`pruneDeadDevices`** — onSchedule mỗi 24h (TZ Asia/Ho_Chi_Minh). Dry-run send dò token chết, xoá `registration-token-not-registered`/`invalid-registration-token`.
- **`sendPartnerPhotoNotification`** — onDocumentCreated `couples/{coupleId}/photos/{photoId}`. Đăng ảnh → FCM cho partner (member khác author). VI `{authorName} vừa đăng ảnh mới 💞`; body = caption hoặc fallback. Android channel `partner_photo_updates`; apns iOS (sound default, badge 1, priority 10).
- **`notifyPartnerJoined`** (2026-06-01) — onDocumentUpdated `couples/{coupleId}`. B ghép cặp vào couple của A (transition `memberIds` 1→2 & status→`active`, guard chặt gửi đúng 1 lần) → FCM cho member cũ (A). `{name} đã ghép đôi cùng bạn 💞`, data `type:partner_joined`.
- **`notifyPartnerLeft`** (2026-06-05) — onDocumentUpdated `couples/{coupleId}`. Inverse của joined: guard transition `memberIds` 2→1 & status→`waiting_partner`. Push cho member còn lại. `{name} đã rời khỏi không gian của hai người`, data `type:partner_left`, `leaverUserId`. Cũng fire khi A xoá tài khoản (CF `deleteAccount` demote couple admin-side).
- **`notifyLoveNote`** (2026-06-02) — onDocumentWritten `couples/{coupleId}/notes/{noteId}`. 1 người viết/sửa lời nhắn (noteId = author uid; bỏ qua delete/text rỗng/không đổi) → FCM cho member kia. `LOVE_NOTE_COPY`: `{tên} vừa để lại lời nhắn 💞`, body = text truncate 120, data `type:love_note`. Tap → Home tab.
- **`notifyDailyAnswer`** (2026-06-02) — onDocumentCreated `couples/{coupleId}/dailyAnswers/{date}/responses/{uid}`. 1 người trả lời câu hỏi ngày → FCM cho partner (gợi mở khoá). `DAILY_QUESTION_COPY`: `{tên} đã trả lời câu hỏi hôm nay 💞`, data `type:daily_question`. Tap → Home tab 0. `deleteCoupleCompletely` thêm `db.recursiveDelete(coupleRef.collection('dailyAnswers'))`.
- **`notifyPhotoReaction`** (2026-06-04) — onDocumentCreated `couples/{coupleId}/photos/{photoId}/reactions/{uid}`. 1 người thả reaction → FCM cho TÁC GIẢ ảnh (skip nếu reactor==author; chỉ onCreate, không spam khi đổi emoji). Copy `{tên} đã thả {emoji} vào ảnh của bạn`, data `type:photo_reaction`. Tap → Home tab Gallery(1). `deleteCoupleCompletely` thêm `recursiveDelete(reactions)` mỗi photo. Đã DEPLOY.
- **`deleteAccount`** — onCall callable. Xoá account đầy đủ với admin quyền (client bị rules cấm xoá users/invite_codes). Trình tự: tear down couple (xoá hẳn nếu sole member, gồm photos + notes + Storage; còn partner thì demote) → xoá devices → `recursiveDelete(users/{uid}/notifications)` (2026-06-06) → xoá invite_code (chỉ nếu vẫn trỏ về uid) → xoá user doc → `admin.auth().deleteUser`. Bắt buộc App Store 5.1.1(v) & Google Play.
- **`leaveCoupleCleanup`** (2026-06-06) — onCall callable. Dọn couple khi **người cuối RỜI** (không phải xoá tài khoản). Auth + **membership-guard** (caller PHẢI ∈ memberIds → chống phá/demote couple lạ) → gọi `handleCoupleOnAccountDeletion(coupleId, uid)` (rỗng → `deleteCoupleCompletely`; còn người → demote). Lý do: client SDK không có `recursiveDelete`, client cleanup cũ chỉ xoá được photos+couple_codes → bỏ sót notes/noteHistory/dailyAnswers/reactions thành **rác mồ côi**. Client `leaveCouple` nhánh sole-member gọi callable này (fallback client cleanup nếu lỗi). `deleteCoupleCompletely` vá thêm: `recursiveDelete(noteHistory)` + xoá top-level `couple_codes/{code}`. ⚠️ **Deploy dev rồi — prod chờ user.**

## Coupling flow

A tạo couple → mã 6 ký tự alphanumeric ở `invite_codes/{code}`. B nhập mã → app validate mã trỏ đúng A & couple đang `waiting_partner` còn chỗ → join bằng Firestore **transaction**: memberIds [A]→[A,B], couple `active`, cả 2 user `in_couple`. A rời trước khi B join → couple bị xoá, A về `single`.
