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

## Client (2026-10-29)

- **Trạng thái:** xong, chờ test. `flutter analyze` sạch; `flutter test test/rating_prompt_test.dart` 7/7.
- **Package mới:** `in_app_review ^2.0.12`, `device_info_plus ^12.4.0` (pubspec + lock). `pod install` iOS chạy cho 2 plugin mới.
- **File mới:** `lib/services/feedback_service.dart` (submit: upload `feedback/<uid>/<uuid>.jpg` trước → `add` doc; timeout 20s; bỏ key tuỳ chọn thay vì null; thu OS/đời máy qua device_info, `utsname.machine` trên iOS) · `lib/services/rating_prompt_service.dart` (Hive `app_settings`: `rating_first_open`, `rating_open_count`, `rating_last_prompt`, `rating_rated_high`; hàm thuần `shouldPrompt`; `maybePrompt` chờ 1s, chỉ hiện khi `ModalRoute.isCurrent` và không có `CatchupGate`) · `lib/widgets/rating_sheet.dart` · `lib/screens/feedback_screen.dart` · `test/rating_prompt_test.dart`.
- **Sửa:** `settings_screen.dart` (2 tile cuối nhóm "Chung"; bản rút gọn chưa có couple: 1 `ContentCard` tile Góp ý trên khối danger) · `home_screen.dart` (`recordOpen` + listener `_onDqForRating` + hook sau đăng ảnh) · `gallery_screen.dart` (hook sau `addPhotosBatch` thành công) · `analytics_service.dart` (`rate_prompt_shown{source}`, `rate_stars{stars}`, `feedback_sent{type}`) · ARB en+vi (+37 key; file ARB bị json.dump định dạng lại vài dòng `placeholders`, không đổi nghĩa).
- **Hook 2 khoảnh khắc:** (a) reveal: `_onDqForRating` nghe `DailyQuestionProvider`; chỉ gọi khi đã THẤY trạng thái chưa mở khoá trong phiên rồi chuyển sang `hasRevealed` (mở app lúc đã xong sẵn thì không mời). (b) đăng ảnh: cuối đường `addPhotosBatch` (successCount>0) và `addPhoto` camera ở Home.
- **Chấm 4–5:** `markRatedHigh` → `isAvailable()`/`requestReview()`, không được thì `openStoreListing(appStoreId: 6775165592)`. 1–3: đóng sheet, push `FeedbackScreen(lowRating)`.
- **Soát UX:** theo `design.md` (đã tra UI UX Pro Max); không thêm thành phần ngoài spec.
- **Ngỏ / Tester soi:** (1) "ngày cài" = lần đầu chạy bản này (user cũ phải đợi 7 ngày kể từ lúc cập nhật; marker cài đặt của InstallState là file private nên không dùng). (2) Hộp `requestReview` chỉ test được trên bản store/TestFlight; iOS giới hạn 3 lần/năm. (3) Android: `openStoreListing` không cần id. (4) Rules `feedback` cần PROD lên trước app. (5) Chưa smoke runtime sheet/form trên máy; ảnh quá >10MB đã nén 1600px khó xảy ra. (6) Back khi đang gửi thoát và mất nội dung (theo design).

- [2026-10-29] [dev] Client feedback: RatingSheet + FeedbackScreen + FeedbackService + RatingPromptService + 2 tile Settings + ARB vi/en + analytics; analyze sạch, test 7/7.
- [2026-10-29] [dev] Smoke Android emulator (test4, DEV) PASS: gửi báo lỗi → doc `feedback` + CF log "Feedback email sent."; 2★ → form có "Bạn chấm 2/5 sao"; 5★ → gọi in_app_review (bản sideload không hiện hộp — đúng hành vi Play). Sổ tiền + giờ nhắc câu hỏi đã ẩn. Sửa: icon sao Iconsax là "sao băng" → `Icons.star_rounded`/`star_outline_rounded`; soát copy (humanizer/avoid-ai-writing): bỏ "đọc hết/đọc kỹ từng chữ", "giúp app đến được thêm nhiều cặp đôi", EN "Send to us" → "Send".
