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
- [2026-06-14] [lead+dev] **CounterBgScreen: auto-save → NÚT LƯU rõ ràng** (user "phải có nút lưu chứ? sửa cho phù hợp toàn app + ui ux friendly"). Bỏ auto-save-mỗi-toggle. `_selected` = draft, `_initial` = bản gốc → `_dirty`. Nút **"Lưu"** sticky đáy = `bottomNavigationBar` (FilledButton.icon pill r999 h52 accentLove + disabled .40 — ĐÚNG recipe `create_post._buildBottomPostBar`, "primary action at thumb reach"), chỉ bật khi `_dirty`; bấm → ghi Hive+`setCounterBgIds` + SnackBar "Đã lưu" + pop. **PopScope** (`onPopInvokedWithResult`, như create_post): back khi `_dirty` → `AlertDialog` "Bỏ thay đổi?" (Hủy=`l10n.cancel` / Thoát). +5 l10n key (`counterBgSave/SavedMsg/DiscardTitle/Body/DiscardLeave`) vi/en. analyze 0. **Vá bug ngay sau (user gửi ảnh): bấm Lưu vẫn bật dialog "Bỏ thay đổi?"** — `_onSave` gọi `pop()` lúc `_dirty` còn true ⇒ `canPop:false` chặn ⇒ `onPopInvoked` chạy discard. Fix: `_onSave` `setState(_initial = {..._selected})` (→ hết dirty → canPop true) rồi `addPostFrameCallback` mới `maybePop()` (pop ở frame sau khi canPop đã cập nhật).
- [2026-06-14] [lead+dev] **Chọn ảnh nền CounterCard (whitelist)** — user "thêm cài đặt chọn hình nào hiện làm nền card, hiện đang show hết". Trước: Home lấy couple-photo + `photos.take(12)` làm ứng viên, swipe cycle hết. Giờ thêm whitelist couple-shared. **Backend:** `prefs/home.counterBgPhotoIds` (list ≤60, rule additive vào `hasOnly`, +3 rules-test → 163 pass); `HomePrefsService.watchCounterBgIds`/`setCounterBgIds` (merge fail-soft). **Home** (`home_screen.dart`): state `_counterBgIds` + Hive cache `counter_bg_ids_<coupleId>` + watch sub (dispose); `_counterBgCandidates` lọc theo whitelist (quét TẤT CẢ photos, không chỉ 12; rỗng hoặc lọc-ra-rỗng → fallback hành vi cũ couple+take12 → card không bao giờ trống). **Settings** (General): tile "Ảnh nền thẻ đếm" → `CounterBgScreen` (lưới 3 cột multi-select, couple-photo gắn nhãn "Ảnh đại diện", tap toggle auto-save Hive+prefs, viền rose+check khi chọn, empty-state khi chưa có ảnh). 8 l10n key vi/en + gen-l10n. `flutter analyze lib` 0 issue. Client+rules; **`counterBgPhotoIds` rules CHƯA deploy + chưa runtime-verify (chờ user)**.
- [2026-06-02] [Dev] Implement #4 Love Note full-stack (model/service/provider/UI/rules/CF/l10n). Analyze + node-check sạch.
