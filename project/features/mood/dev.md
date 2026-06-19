# 💻 Dev — Tâm trạng hôm nay (Mood)

> Mirror kiến trúc daily-question (Provider + service, realtime, card Home, wire ở session_resolver).

## Data model
`couples/{coupleId}/moods/{uid}` — 1 doc/member (id == uid): `authorUserId?`, `mood` (key ≤20), `note?` (≤100), `date` ('YYYY-MM-DD' ≤10), `updatedAt` (serverTimestamp). Đọc trực tiếp theo path (≤2 doc) → KHÔNG cần collectionGroup/denormalize.

## File tạo
| File | Vai trò |
|---|---|
| `lib/models/mood.dart` | `Mood` + `MoodOption` + `kMoodOptions` (8 mood key+emoji) + `moodOptionFor` + `kMoodNoteMaxLength=100`. |
| `lib/services/mood_service.dart` | `watchMoods(coupleId)`→`Map<uid,Mood>`; `setMood(...)` set doc merge. Local fallback Hive box `moods_local` (chỉ mood của mình, key `{coupleId}:{uid}`). |
| `lib/providers/mood_provider.dart` | `watchForCouple/clear/dispose` (như daily-question); `myMood`/`partnerMood` **scope TODAY** (`date==todayKey()` mới tính); `setMood(key,note)` optimistic. |
| `lib/widgets/mood_card.dart` | `MoodCard` (card Home) + `_MoodPickerSheet` + `moodLabel(l10n,key)`. |
| `firebase_rules_test/test/firestore.moods.test.js` | 9 test (own write / partner read / spoof / over-long note / unexpected field / outsider / no-delete). |

## File sửa (wiring)
- `firestore.rules`: rule `match /moods/{uid}` (read member; write own, `hasOnly` 5 field + size guard; no delete).
- `functions/index.js`: **CF mới `notifyPartnerMood`** (onDocumentWritten moods) — push khi `mood` HOẶC `date` đổi (bỏ qua note-only/no-op/deletion); **push-only, KHÔNG inbox**; copy `PARTNER_MOOD_COPY`+`buildPartnerMoodText` (content-free).
- `lib/main.dart`: đăng ký `MoodProvider`.
- `lib/app/session_resolver.dart`: thêm param `moodProvider` cho `_resolve` (⚠️ providers TRUYỀN qua named-param từ `resolveStartRoute`→`_resolve`, không phải biến chung — đây là chỗ dễ sót) + watch khi active + clear 3 nhánh.
- `lib/screens/home_screen.dart`: import provider+card; re-arm `MoodProvider.watchForCouple` ở post-frame; đặt `MoodCard` trong nhóm "Hôm nay" (chỉ khi `!isWaitingForPartner`).
- `lib/services/push_notification_service.dart`: tap `partner_mood` → Home tab.
- `lib/l10n/app_{vi,en}.arb`: +18 key (moodCardTitle/Share/Update/NotSharedYou/PartnerEmpty{name}/SheetTitle/NoteHint/SaveCta + 8 nhãn mood) + gen-l10n.

## Verify
- `flutter analyze` **0 issue** (toàn dự án). `node --check functions/index.js` OK. rules-test **187 pass** (+9 mood).
- Runtime Android emulator DEV: vào Home thấy card; ghi/đọc mood **0 permission-denied** (đã verify ở bước deploy). Suppression cross-device (push khi người ấy đổi) → user test 2 máy.
- ✅ **DEV deployed: rules + functions:notifyPartnerMood (2026-06-19).** Prod chờ lệnh.

## Mood icon ĐỘNG (Lottie, 2026-06-19)
Thay emoji tĩnh `Text('😄')` bằng mặt **động** (user: "khóc thì phải có giọt nước mắt, cười thì cười, căng thẳng nheo mắt — đừng tĩnh, nhàm"). Nguồn = **Noto Animated Emoji** (Google, CC BY 4.0), tải trực tiếp 8 file `assets/lottie/mood_<key>.json` (khớp đúng 8 emoji sẵn có → biểu cảm đúng nghĩa). KHÔNG dùng Creator MCP (cần tab kết nối + export thủ công); tải web nhanh + license rõ.
- `lib/models/mood.dart`: `MoodOption` thêm field `lottie` (đường dẫn asset); 8 entry trỏ file.
- `lib/widgets/mood_glyph.dart` (MỚI): `MoodGlyph` — `Lottie.asset` + `errorBuilder`→emoji tĩnh (an toàn key lạ, mirror `LoveLottie`); tôn trọng Reduce Motion (`MediaQuery.disableAnimations`→static frame 0); param `animate`.
- `lib/widgets/mood_card.dart`: dùng `MoodGlyph` ở ô "tôi/người ấy" (size 44, animate) + picker `_MoodChoice` (size 40, **chỉ animate ô đang chọn** cho nhẹ — tránh 8 mặt loop cùng lúc).
- Attribution: ghi ở `assets/lottie/README.md`; **TODO user-visible** dòng ghi công ở màn Về/Giấy phép (app chưa có `showLicensePage`).
- Verify: `flutter analyze` 3 file đổi = 0 issue. Chưa smoke-test runtime (đề xuất chạy app xem 8 mặt động + fallback).

## Nhật ký
- [2026-06-19] [dev] **Push hiện luôn mood** (user): `buildPartnerMoodText(lang, name, moodKey)` + map `MOOD_LABELS` vi/en trong CF → body "Anh Tuấn đang thấy Nhớ" / "… is feeling Missing you"; mood lạ → fallback generic cũ. Re-deploy DEV. rules-test 187 + node-check OK. PROD chờ lệnh.
- [2026-06-19] [dev] **Redesign trạng thái "đồng điệu"** (user "đồng bộ, đồng điệu"): `_MoodMatched` bỏ vòng phẳng → **glow radial mềm** (accentLove .24→0) + đĩa trắng nổi (shadow rose) + glyph 60; thêm dòng **"BẠN ♥ ĐỐI-PHƯƠNG"** (eyebrow caps + `AnimatedHeartIcon` đập — tái dùng motif couple-name app) trên **panel hồng nhạt** r20. analyze 0.
- [2026-06-19] [dev] **Icon TO khi trùng tâm trạng** (user): khi `myMood.mood == partnerMood.mood` → thay layout 2 cột bằng `_MoodMatched` (glyph 66px trong vòng gradient `sunsetRomance` + nhãn mood w800 + caption + ghi chú 2 bên nếu có). +l10n `moodMatched` (VI dùng "Chúng mình…" theo voice) + gen-l10n. analyze 0.
- [2026-06-19] [dev] **Auto nhắc tâm trạng đối phương — xác nhận ĐÃ có & gentle** (user hỏi thêm). CF `notifyPartnerMood` (functions/index.js:649) có sẵn từ v1: chỉ ping khi mood THỰC SỰ đổi / chia sẻ lần đầu trong ngày (bỏ note-only/re-save), chỉ partner, **push-only** (không inbox), copy `PARTNER_MOOD_COPY` không lộ mood. Tap routing `partner_mood` sẵn. KHÔNG cần setting (app tự nhắc). Re-deploy DEV = "updating" (đã live). PROD chờ lệnh.
- [2026-06-19] [dev] Mood icon động bằng Lottie (Noto Animated Emoji, CC BY 4.0): +`MoodOption.lottie`, +`MoodGlyph` (fallback emoji + Reduce-Motion), thay 2 site render trong `mood_card`. Picker chỉ animate ô chọn. analyze 0. Attribution README; TODO ghi công user-visible.
- [2026-06-19] [lead solo: PO+designer+dev+tester] Build full-stack feature Mood v1 (research→spec→design→code→test). Mirror daily-question. Push-only daily-hook. analyze 0, rules-test 187, DEV deploy. Prod chờ lệnh.
