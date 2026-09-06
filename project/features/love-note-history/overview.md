# Feature: Love-note history (Nhật ký lời nhắn)

> ⚠️ **RETIRED 2026-06-14** — feature Love Note (lời nhắn 2 chiều + nhật ký) đã **huỷ khỏi client**, thay hoàn toàn bằng tab **Chat**. User chốt: "gộp lịch sử love note cũ vào Chat rồi huỷ luôn, giờ chỉ xài Chat". Đã xoá `love_note_history_screen` + `LoveNoteProvider`/`LoveNoteService` + model `love_note` + wiring. **Auto-migrate** lịch sử cũ → Chat (CF `mirrorNoteHistoryToChat` trigger realtime + `migrateLoveNotesToChat` callable backfill, idempotent). **Backend GIỮ NGUYÊN** (rules `notes`/`noteHistory` + CF `notifyLoveNote`) để app 1.1.0 đang live không vỡ (backward-compat). Chi tiết migration ở [`../chat/dev.md`](../chat/dev.md). Phần dưới giữ làm lịch sử thiết kế.

> Tạo 2026-06-04 (autonomous "caffeine mode"). Xuất phát từ câu hỏi PO của user:
> "phần lời nhắn — có nên lưu lịch sử tin nhắn 2 người không? có nên re-UI cho nổi bật?"

## 1. PO analysis & quyết định
**Kết luận (Lead/PO, phân tích hành vi người dùng):**
- ❌ **KHÔNG** biến lời nhắn thành chat/tin nhắn realtime 2 chiều — không thắng nổi Zalo/Messenger (cặp đôi VN nhắn hằng ngày ở đó), đẻ kỳ vọng nặng (read receipt/typing/moderation), làm loãng "phép màu" của lời nhắn (món quà chủ đích, không phải hội thoại).
- ✅ **CÓ** lưu **lịch sử dạng kho lưu niệm (archive)** — đúng value prop "lưu giữ kỷ niệm"; gỡ nỗi sợ ghi đè (model cũ mỗi người 1 note bị overwrite → ngại cập nhật/hụt hẫng); khuyến khích viết nhiều hơn → tăng vòng tương tác 2 chiều (North Star = cặp active).
- ✅ **Re-UI nổi bật** = đẹp/cảm xúc hơn + dễ đọc, KHÔNG phình to trên Home. (Đã làm: fix tương phản chữ navy + CTA rose; xem feature `home-cocreate` changelog 2026-06-04.)

User chốt (AskUserQuestion): **"fix tương phản giờ + spec history sau"**, sau đó nâng lên **"tự làm luôn"** (caffeine mode).

## 2. Thiết kế — ADDITIVE, không migration, không phá data cũ
- Giữ NGUYÊN `couples/{id}/notes/{uid}` (1 doc/người, overwrite = lời nhắn MỚI NHẤT). Home không đổi cách đọc.
- THÊM `couples/{id}/noteHistory/{autoId}` — **append-only**, fields `{authorUserId, text ≤140, createdAt}`. Ghi mỗi lần lưu note (dedup: chỉ ghi khi text **đổi** và **non-empty**).
- Archive đọc `noteHistory` orderBy createdAt desc (cap 200). Tái dùng model `LoveNote` (map `createdAt`→`updatedAt`).
- Local fallback (no Firebase): Hive box `love_note_history_local` (best-effort).

## 3. Code (Dev) — 2026-06-04
- **Rules** (`firestore.rules`): thêm block `match /noteHistory/{entryId}` — read if member; create if member && authorUserId==uid && 0<text≤140; update/delete=false. ADDITIVE. ⚠️ **CHƯA DEPLOY.**
- **Service** (`love_note_service.dart`): `appendHistory()` + `watchHistory()` + local history helpers.
- **Provider** (`love_note_provider.dart`): `setMyNote` append history (dedup theo text đổi) **best-effort try/catch** (fail history KHÔNG phá save note); `watchHistory()` cho màn archive.
- **Screen** (`love_note_history_screen.dart` MỚI): "Nhật ký lời nhắn", nền dawnBlush, StreamBuilder → card trắng (tên tác giả + ngày + lời, chữ navy), empty state, loading.
- **Card Home** (`home_screen.dart`): `_buildLoveNoteHistoryEntry` — link "Xem lại lời nhắn cũ" (divider + row, push archive). Chỉ hiện khi không waiting-partner.
- **l10n**: +4 key (`loveNoteHistoryTitle/Subtitle/Empty/Cta`) vi+en, đã gen-l10n.

## 4. Trạng thái & verify
- `flutter analyze`: **No issues found** (mọi file đụng tới).
- Runtime Pixel 10 (autonomous): link "Xem lại lời nhắn cũ" hiện trên card ✓; mở → màn "Nhật ký lời nhắn" render đúng + empty state graceful (rules chưa deploy → read denied → empty, KHÔNG crash) ✓; **lưu note vẫn chạy bình thường** (snackbar + cập nhật + history best-effort fail im lặng) ✓.
- ⚠️ **CHƯA verify được**: history thực sự populate + hiện trong archive — **cần deploy rules** trước.

## 5. ⛔ Việc CÒN LẠI cho user (gated — không tự làm khi user ngủ)
1. **Deploy rules** (bắt buộc để history hoạt động):
   `npx firebase-tools deploy --only firestore:rules --project tonyembeiu`
2. **Push branch** `phase2` (sau khi review).
3. **E2E verify**: 2 người viết/sửa lời nhắn → mở "Nhật ký lời nhắn" thấy timeline tích luỹ đúng tên + thời gian.

## 6. Ý sau (chưa làm)
- Cloud Function append history (thay client-write) nếu muốn chống client ghi sai.
- Motif phong bì/mở thư + badge "lời nhắn mới" (re-UI sâu hơn).
- Premium: export "tập thư tình" (hợp hướng monetization export photobook).
