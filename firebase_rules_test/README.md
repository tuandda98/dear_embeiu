# Firebase rules unit tests

Unit test cho **Firestore + Storage security rules** (`firestore.rules`, `storage.rules`),
chạy trên Firebase emulator bằng [`@firebase/rules-unit-testing`](https://firebase.google.com/docs/rules/unit-tests) + Mocha.

> Mục tiêu: mỗi lần thêm/sửa/xoá logic rules đều có lưới an toàn tự động phát hiện
> regression (ai được đọc/ghi gì, field nào immutable, IDOR, transition couple…).

## Chạy

Từ thư mục gốc repo:

```bash
scripts/test-firebase-rules.sh
```

Script tự lo mọi thứ: dò JDK 21+ (firebase-tools 15 yêu cầu Java ≥ 21 — script
tự dùng JBR của Android Studio nếu `java` mặc định < 21), cài `node_modules` lần
đầu, bật/tắt emulator, chạy `mocha`, và check cú pháp `functions/index.js`.

Chạy thủ công (khi emulator đã/đang tự quản lý):

```bash
cd firebase_rules_test && npx mocha
# hoặc chỉ 1 file:
cd firebase_rules_test && npx mocha test/firestore.couples.test.js
```

## Tự động (KHÔNG cần nhớ chạy)

Có **Stop hook** (`.claude/hooks/run-firebase-rules-tests.sh`, wire ở
`.claude/settings.json`) băm nội dung `firestore.rules` + `storage.rules` +
`functions/index.js`. Khi 3 file này **đổi so với lần test PASS gần nhất**, hook
tự chạy lại TOÀN BỘ test cuối mỗi lượt; FAIL sẽ **chặn** và báo lỗi để sửa. Không
đổi thì bỏ qua (không tốn thời gian emulator). Hash lần xanh lưu ở
`.firebase_rules_test.cache` (gitignored).

> Máy thiếu JDK 21+ → hook bỏ qua êm (cảnh báo, không chặn) thay vì làm kẹt phiên.

## Cấu trúc

| File | Phủ |
|------|-----|
| `test/helpers.js` | khởi tạo test env, factory document hợp lệ, seed fixtures |
| `test/_hooks.js` | mocha root hooks: 1 emulator dùng chung, clear data giữa mỗi test |
| `test/firestore.users.test.js` | `users/{uid}` + `devices/{id}` |
| `test/firestore.invitecodes.test.js` | `invite_codes/{code}` |
| `test/firestore.couples.test.js` | `couples/{id}` create/read + 3 transition (profile/join/leave) + delete |
| `test/firestore.couples-sub.test.js` | `notes`, `noteHistory`, `dailyAnswers` (+marker), `responses` |
| `test/firestore.photos.test.js` | `photos/{id}` + `reactions/{uid}` |
| `test/firestore.misc.test.js` | `reports/{id}`, `couple_codes/{code}` |
| `test/firestore.backward-compat.test.js` | app 1.0 cũ (thiếu field mới `coupleCode`/`languageCode`/`sessionToken`) vẫn ghi được — chống vỡ flow cũ khi deploy rules |
| `test/storage.test.js` | `couple_photos/{coupleId}/{file}` (cross-service membership từ Firestore) |

## Lưu ý kỹ thuật

- Project id cố ý là `demo-dear-embeiu` → SDK chạy offline, không chạm Firebase thật.
- Rules đọc trực tiếp từ file repo (`../firestore.rules`, `../storage.rules`) nên
  test luôn khớp file production sẽ deploy.
- Storage rules dùng `firestore.exists/get` để check membership → các test storage
  seed sẵn couple vào Firestore emulator (cùng project) trước khi upload.
- **⚠️ Backward-compat (bài học quan trọng):** backend prod DÙNG CHUNG cho mọi
  version app đang cài. Field optional thêm sau (vd `coupleCode`, `languageCode`,
  `sessionToken`) PHẢI đọc bằng `data.get('field', null)` trong rules, KHÔNG
  dùng `data.field` trực tiếp — vì key vắng mặt (app cũ không gửi) khi truy cập
  trực tiếp sẽ bị engine báo `Property ... is undefined` → **deny** → app 1.0
  của user chưa update bị `permission-denied`. File `firestore.backward-compat.test.js`
  khoá guarantee này (mô phỏng app cũ thiếu field → vẫn phải PASS).
