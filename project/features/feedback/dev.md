# 💻 Dev — <Tên feature>

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** <chưa bắt đầu | đang làm | xong | chờ test>
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* <…>
- *File/hàm đụng tới (file:line nếu sửa code cũ):* <…>
- *Thay đổi model / Firestore / Cloud Function / native config:* <…>
- *Cần deploy?* <rules / functions / không>

## Edge case kỹ thuật cần xử lý
- <…>

## Checklist implement
- [ ] <task 1>
- [ ] <task 2>
- [ ] `flutter analyze` sạch
- [ ] Không hardcode chuỗi/ngôn ngữ (qua l10n)

## Nhật ký implement
- [<YYYY-MM-DD>] [Dev] <đã code gì / commit / deploy>

## Backend (2026-10-29)

- `firestore.rules` ~1590–1620: hàm `feedbackOk(uid)` + `match /feedback/{feedbackId}` (create-only, read/update/delete=false). Additive.
- `storage.rules` ~29–35: `match /feedback/{uid}/{fileName}` (create khi `auth.uid == uid` + `isValidImageUpload()`; còn lại false).
- `functions/index.js` cuối file: `notifyFeedback` (onDocumentCreated `feedback/{feedbackId}`, us-central1, secret `RESEND_API_KEY`) gửi email Resend (from `VERIFICATION_EMAIL_FROM`) tới `thesavior9820@gmail.com`; subject `[Dear Embeiu] <Góp ý|Báo lỗi|Đánh giá N★> · <ver (build)> · <platform>`; nội dung user được escape HTML; `reply_to` = email user nếu có; ảnh -> signed URL 7 ngày (lỗi -> ghi đường dẫn); email thiếu thì lấy từ Admin Auth; mọi lỗi chỉ log.
- Test: `firebase_rules_test/test/firestore.feedback.test.js` (20 case Firestore + Storage). `scripts/test-firebase-rules.sh`: 537 pass, CF unit 127 pass.
- Schema doc `feedback/{id}` (hasOnly): `userId` (== uid), `type` ('idea'|'bug'|'rating'), `message` (string 0..2000; >=1 khi type != 'rating'), `stars`? (int 1..5), `screenshotPath`? (<=300, bắt đầu `feedback/<uid>/`), `appVersion` (<=20), `buildNumber` (int), `platform` ('ios'|'android'), `osVersion`? (<=60), `deviceModel`? (<=80), `locale`? (<=10), `email`? (<=200), `createdAt` (serverTimestamp). Bắt buộc: userId, type, message, appVersion, buildNumber, platform, createdAt. Không được gửi giá trị null cho field optional (omit key thay vì null).
- Storage: upload ảnh vào `feedback/<uid>/<tên>` trước, rồi mới ghi doc kèm `screenshotPath`.
- DEV: ✅ deployed 2026-10-29 (rules, storage, notifyFeedback; trace `project/.firebase-deploy-log/20261029T075017Z`). PROD: CHƯA — lệnh khi release 1.12.0 (rules + storage phải lên TRƯỚC khi phát hành app):
  `NODE_OPTIONS=--dns-result-order=ipv4first npx firebase-tools deploy --only firestore:rules,storage,functions:notifyFeedback --project prod` (cần secret `RESEND_API_KEY` ở PROD; đã dùng bởi hàm email xác thực nên có sẵn).
- Chưa kiểm: signed URL cần quyền `iam.serviceAccounts.signBlob` cho service account chạy hàm; thiếu thì email vẫn gửi, ảnh chỉ hiện đường dẫn. Email thật chưa thử trên DEV.

## Nhật ký backend
- [2026-10-29] [dev] Thêm rules feedback + storage feedback/{uid} + CF notifyFeedback; test 537 pass; deploy DEV xong.
