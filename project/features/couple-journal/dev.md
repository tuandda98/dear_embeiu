# 💻 Dev — Nhật ký của chúng mình (Couple Journal)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Bám kiến trúc Provider + service.

- **Trạng thái dev:** xong — sẵn sàng test (chờ PO deploy firestore.rules trước khi test trên Firebase thật)
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* Marker doc lưu thẳng text câu hỏi (PO decision A — KHÔNG suy lại từ bank vì append làm lịch dịch). Journal đọc 1 lần + phân trang "Xem thêm" (KHÔNG realtime). Provider gọn `JournalProvider` tạo per-screen-open. Love Note 2 chiều chỉ thêm UI + AnimatedSize (dữ liệu đã có ở `LoveNoteProvider.myNote`).

- *File tạo:*
  - `lib/models/journal_day.dart` — model `JournalDay` (date, questionVi/En, myAnswer, partnerAnswer, partnerUid; `questionFor(lang)`, `parsedDate`).
  - `lib/providers/journal_provider.dart` — `JournalProvider` (status initial/loading/ready/error, `load()`/`loadMore()`, cursor + hasMore + isLoadingMore + isEmpty).
  - `lib/screens/journal_screen.dart` — màn Nhật ký (gradient dreamyMint, AppBar phẳng, list card-ngày trắng đặc r28, 2 answer block phân màu, nút "Xem thêm" pill outline + spinner, states loading/empty/empty-no-partner/error/success, entrance flutter_animate stagger 6 card đầu).

- *File sửa:*
  - `lib/theme/app_colors.dart:25` — thêm token `accentLavenderDeep = #7C5CD6` (PO decision B).
  - `lib/services/daily_question_service.dart` — import bank + model/JournalPage; thêm `_dailyAnswers()`, `_dateFromKey()`; trong `submitAnswer` ghi marker `set(merge:true)` sau response; thêm `loadJournal({coupleId, myUid, startAfter, limit=30})` trả `JournalPage`; class `JournalPage` (days, lastDoc cursor, hasMore).
  - `lib/screens/home_screen.dart` — `_buildLoveNoteCard`: thêm block "Lời nhắn của bạn" (hiện iff `myNote.hasText`) + wrap thân trong `AnimatedSize` 200ms. `_buildDailyQuestionCard`/`_DailyQuestionCard`: thêm callback `onOpenJournal` + method `_buildJournalEntry` (divider + dòng "Xem lại nhật ký →" ở chân card, ẩn khi `isWaitingPartner`). Import `journal_screen.dart`.
  - `lib/screens/settings_screen.dart` — thêm `_buildMemoriesSection` (section "Kỷ niệm" 1 tile "Nhật ký câu hỏi") đặt TRÊN section "Tài khoản & dữ liệu"; dịch `_OnceEntrance` order +1 cho các section sau. Import `journal_screen.dart`.
  - `lib/l10n/app_en.arb` + `app_vi.arb` — 16 key journal*/loveNoteYourNoteLabel; `journalPartnerAnswerLabel` có placeholder `{name}`. Đã `fvm flutter gen-l10n`.
  - `project/design-system.md` — ghi token accentLavenderDeep vào mục accent.

- *Thay đổi model / Firestore / Cloud Function / native:*
  - Firestore: THÊM marker doc `couples/{coupleId}/dailyAnswers/{dateKey}` = `{ date, questionVi, questionEn, updatedAt }` (merge-write khi trả lời). KHÔNG đổi schema response. KHÔNG đổi Cloud Function (`deleteCoupleCompletely` đã `recursiveDelete(dailyAnswers)` → tự dọn marker).
  - `firestore.rules`: THÊM `match /dailyAnswers/{date}` (read nếu member; write nếu member + validate `date`/`questionVi`/`questionEn` là string ≤300). Giữ nguyên rule `responses`.

- *Cần deploy?* **firestore.rules** (PO review + deploy — Dev KHÔNG tự deploy theo brief). Marker write sẽ bị rules cũ CHẶN cho tới khi deploy → trên Firebase thật, journal rỗng cho ngày trả lời trước khi rules lên (chấp nhận; marker chỉ ghi từ lần trả lời sau khi rules live).

## Diff firestore.rules (PO review)
Thêm khối sau, ngay TRƯỚC `match /dailyAnswers/{date}/responses/{uid}`:
```
match /dailyAnswers/{date} {
  allow read: if isCoupleMember(coupleId);
  allow write: if isCoupleMember(coupleId)
    && request.resource.data.date is string
    && request.resource.data.questionVi is string
    && request.resource.data.questionVi.size() <= 300
    && request.resource.data.questionEn is string
    && request.resource.data.questionEn.size() <= 300;
}
```

## Edge case kỹ thuật đã xử lý
- Marker write best-effort (try/catch) — fail không làm fail việc trả lời.
- `loadJournal` chỉ giữ ngày có ĐỦ 2 response (cả 2 đã reveal); ngày 1 người → ẩn.
- `hasMore` ở mức trang: nếu trang đầy `limit` thì coi như còn (một số marker có thể bị lọc vì chưa đủ 2 response, nhưng vẫn có thể còn trang sau) → tránh cụt danh sách.
- Câu hỏi hiển thị theo locale từ marker (`questionVi`/`questionEn`), KHÔNG suy lại bank. Câu trả lời giữ text gốc.
- Local fallback (không Firebase): `loadJournal` trả rỗng → journal hiện empty-state. Marker không ghi ở local mode.
- Empty-no-partner (couple `waiting_partner`) → empty riêng + CTA mời (push SetupScreen). Từ Home entry đã ẩn khi waiting nên chỉ vào được từ Settings.

## Checklist implement
- [x] Token accentLavenderDeep + cập nhật design-system.md
- [x] Love Note 2 chiều + AnimatedSize
- [x] Marker doc write (merge) trong submitAnswer
- [x] loadJournal + JournalPage + phân trang
- [x] firestore.rules (additive, CHƯA deploy)
- [x] JournalScreen đủ 6 state
- [x] Entry Daily Question card + tile Settings
- [x] 16 key i18n (en+vi) + gen-l10n
- [x] `fvm flutter analyze` sạch (0 issue)
- [x] Không hardcode chuỗi (qua l10n; ngày qua intl DateFormat)

## Ghi chú lệch design (cần Tester soi)
- **Icon `LucideIcons.bookHeart` không tồn tại** trong lucide_icons 0.257.0 → thay bằng `LucideIcons.bookOpen` ở cả 3 chỗ (entry Home, empty Journal, tile Settings). Lệch nhỏ so với design (bookHeart). Cùng họ "book", giữ ý nghĩa nhật ký.
- Route: KHÔNG thêm `/journal` vào `app_routes.dart` — push trực tiếp `MaterialPageRoute` theo pattern hiện có (Milestone/Custom reminders cũng push trực tiếp).

## Nhật ký implement
- [2026-06-04] [Dev] Implement đầy đủ: token + Love Note 2 chiều + marker doc + service loadJournal + JournalProvider + JournalScreen (6 state) + 2 entry point + 16 i18n + rule additive. analyze sạch (0 issue); daily_questions_test PASS (14/14); test suite 22 pass / 1 fail (fail pre-existing `widget_test.dart` — LoginScreen dựng không có l10n delegate, KHÔNG liên quan journal). firestore.rules CHƯA deploy — chờ PO.
