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

## Nhật ký
- [2026-06-19] [lead solo: PO+designer+dev+tester] Build full-stack feature Mood v1 (research→spec→design→code→test). Mirror daily-question. Push-only daily-hook. analyze 0, rules-test 187, DEV deploy. Prod chờ lệnh.
