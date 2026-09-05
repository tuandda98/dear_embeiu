# 💻 Dev — Quan tâm (care message)

> Dev sở hữu. Đọc `overview.md` trước. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** client xong — chờ test (backend do agent khác làm song song)
- **Người/role:** Dev

## Kế hoạch kỹ thuật (phần CLIENT)
- *Cách tiếp cận:* service thuần (không cần Provider riêng — màn hình chỉ ghi 1 lần + 1 `StreamBuilder` cho lịch sử, không có state chia sẻ toàn app).
- *Cần deploy?* Client KHÔNG. Rules + CF `careMessages` do agent backend lo — **chưa deploy ⇒ gửi sẽ `permission-denied` và không có push**.

## Edge case đã xử lý
- Chưa ghép đôi / couple còn `waiting_partner` → banner "Cần ghép đôi trước", nút gửi disable.
- Không có Firebase (local fallback) → `send` no-op, `watchRecent` trả stream rỗng (care note vô nghĩa nếu không push được ⇒ KHÔNG làm Hive fallback).
- Trim + clamp 60/200 phía client để không bị rules từ chối vì paste dài; rỗng sau trim → bỏ qua.
- `createdAt` BẮT BUỘC `FieldValue.serverTimestamp()` (rule `createdAt == request.time`); map create đúng 4 key, không thừa field.
- Lỗi ghi → SnackBar đỏ + mở lại nút (không pop màn), thành công → SnackBar + pop.
- Notification center: nếu doc thiếu `title` (backend cũ) → fallback template `notifCareMessage(name)`.

## Nhật ký implement
- [2026-09-05] [Dev] **CLIENT feature "Quan tâm" — xong.**
  - **Mới:** `lib/models/care_message.dart` (`CareMessage`, hằng `maxTitleLength=60`/`maxBodyLength=200`, `fromDoc`, `isMine`, `parseTimestamp` duck-typed) · `lib/services/care_message_service.dart` (`send({coupleId, uid, title, body})` + `watchRecent(coupleId, {limit:20})` orderBy `createdAt` desc, `isUsingFirebase` theo `FirebaseBootstrapService`) · `lib/screens/care_message_screen.dart` (`openCareMessageScreen(BuildContext)` + `CareMessageScreen`: `SubScreenHeader` chip-only "QUAN TÂM", `_QuickPicks` 6 chip điền cả title+body, 2 `TextField` (maxLength 60/200) trong `ContentCard`, nút pill h52 r999 navy disable/loading, `_RecentCareMessages` StreamBuilder ẩn khi rỗng, `_CareMessageTile` nhãn Mình/Người ấy + relative time dùng lại `loveNote*Ago`).
  - **Sửa:** `lib/screens/profile_screen.dart` — thêm `_buildCareTile(context)` (InkTile r22 + IconBadge `message_favorite`) đặt sau `_AchievementsGrid` trong nhánh đã ghép đôi; import `ink_tile.dart` + `care_message_screen.dart`. · `lib/models/app_notification.dart` — enum `careMessage`, parse `'care_message'`, 2 field nullable `title`/`body` (đọc + `copyWith`), `targetHomeTab` → 0. · `lib/screens/notification_center_screen.dart` — `_titleFor` trả `n.title` NGUYÊN VĂN (fallback `notifCareMessage`), `_subtitleFor` trả `n.body`, `_Avatar` icon `message_favorite` accentLoveDeep. · `lib/services/push_notification_service.dart` — `_applyRoute` thêm `case 'care_message'` → Home tab 0.
  - **Foreground push:** `_handleForegroundMessage` đã generic (đọc `message.notification?.title/body`, không switch theo type) ⇒ care note tự hiện đúng nguyên văn khi app đang mở, tap deep-link qua payload JSON. Không phải sửa gì.
  - **l10n (CẢ en + vi, đã `flutter gen-l10n`):** `careMessageBadge`, `careMessageEntryTitle`, `careMessageEntrySubtitle`, `careMessageQuickPicksTitle`, `careMessageTitleLabel`, `careMessageTitleHint`, `careMessageBodyLabel`, `careMessageBodyHint`, `careMessageSendCta`, `careMessageSentToast`, `careMessageErrorToast`, `careMessageNeedCouple`, `careMessageRecentTitle`, `careMessageFromMe`, `careMessageFromPartner`, `careQuick1..6Title`, `careQuick1..6Body`, `notifCareMessage(name)`.
  - **KHÔNG đụng:** `home_screen.dart`, `reminder_provider.dart`, `reminder_service.dart`, `firestore.rules`, `functions/`, `pubspec.yaml`.
  - **Verify:** `flutter analyze` → **No issues found** · `flutter test` → **24/24 pass**. Chưa commit.
- [2026-09-05] [Dev] **Vá 15 finding code-review (xem test.md):** `send` trả bool + clamp không cắt đôi emoji; màn gửi timeout 10s → toast "đã xếp hàng" (key `careMessageQueuedToast`) + pop, `ok==false` → toast lỗi; `_RecentCareMessages` stateful giữ 1 stream/couple, bỏ giới hạn dòng body; inbox `care_message` KHÔNG auto-read theo tab Home (`NotificationInboxProvider._autoReadsOn`); Notification center hiện trọn body. ⏳ Nợ: pref tắt riêng push quan tâm; `design.md`/`roadmap.md` còn template.
