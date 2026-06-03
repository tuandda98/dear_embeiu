# Dev — Home Co-creation Cards

## #4 — Lời nhắn của người ấy (Love Note) — DONE (chờ deploy + runtime test)

### File tạo
- `lib/models/love_note.dart` — model `{authorUserId, text, updatedAt?}` + `fromDoc(id,data)` (id == author uid), `fromJson`/`toJson`/`copyWith`, parse Timestamp microsecond.
- `lib/services/love_note_service.dart` — `watchNotes(coupleId)` stream subcollection `couples/{coupleId}/notes` (≤2 doc); `setMyNote(coupleId, uid, text)` → set doc id=uid `{authorUserId, text, updatedAt: serverTimestamp}` merge, clamp 140. **Local-fallback** (Hive box `love_notes_local`, key `{coupleId}:{uid}`) khi `!isUsingFirebase` — chỉ giữ note của chính máy, không crash.
- `lib/providers/love_note_provider.dart` — `watchForCouple(coupleId, myUid)` (no-op khi không đổi), `partnerNote` (author != myUid, có text), `myNote`, `isLoading`, `setMyNote(text)`, `clear()`.

### File sửa
- `lib/main.dart` — đăng ký `LoveNoteProvider` trong MultiProvider.
- `lib/app/session_resolver.dart` — wire `watchForCouple` khi couple active + có uid; `clear()` khi không có couple/guest.
- `lib/screens/home_screen.dart` — THAY `_buildQuoteCard` (card tĩnh) bằng `_buildLoveNoteCard` (GlassCard): header "Lời nhắn từ {partner}" + text + thời gian tương đối; empty state "Chưa có lời nhắn từ {tên}"; gate `waiting_partner` → prompt mời (ẩn nút viết); nút "Viết/Sửa lời nhắn" → bottom sheet `_LoveNoteSheet` (TextField maxLength 140 + đếm ký tự live, prefill myNote, Save → provider.setMyNote + Haptic.mediumImpact + snackbar). Partner name map: createdByUserId→person1Name, else person2Name (fallback posterNameFallback). `watchForCouple` re-arm defensively trong `_buildHomeTab` (post-frame). Icon: `LucideIcons.mailOpen`/`heart`/`feather` (mailHeart/penLine không có trong lucide_icons 0.257).
- `lib/services/push_notification_service.dart` — `_handleNotificationTap` thêm case `'love_note'` → Home tab (0).
- `firestore.rules` — ADDITIVE: `match /notes/{noteId}` BÊN TRONG `match /couples/{coupleId}` (read if member; write if member && noteId==auth.uid && authorUserId==auth.uid && text is string && size ≤140).
- `functions/index.js` — thêm `exports.notifyLoveNote = onDocumentWritten("couples/{coupleId}/notes/{noteId}")`: bỏ qua delete/text rỗng/text không đổi; recipient = memberIds trừ noteId; tên author từ `users/{noteId}.displayName` (fallback "Người ấy"); `LOVE_NOTE_COPY` vi/en title "{tên} vừa để lại lời nhắn 💞", body = text truncate 120; gửi qua `sendToRecipientDevices` data `{type:'love_note', coupleId}`. **deleteAccount**: `deleteCoupleCompletely` nay xoá luôn subcollection `notes`.
- ARB en+vi — thêm: loveNoteFromPartner, loveNoteEmptyFromPartner, loveNoteWriteCta, loveNoteEditCta, loveNoteWaitingPartner, loveNoteSheetTitle, loveNoteSheetHint, loveNoteCharCount, loveNoteSaved, loveNoteJustNow, loveNoteMinutesAgo/HoursAgo/DaysAgo (plural). `flutter gen-l10n` OK.

### Verify
- `flutter analyze` sạch (No issues found).
- `node --check functions/index.js` OK.
- `flutter gen-l10n` OK.
- KHÔNG deploy/commit/build (PO deploy sau review). Rules + 2 CF cần `firebase deploy --only firestore:rules,functions` trước khi chạy thật.

## Changelog
- [2026-06-02] [Dev] Implement #4 Love Note full-stack (model/service/provider/UI/rules/CF/l10n). Analyze + node-check sạch.
