# 💻 Dev — Couple Streak (chuỗi ngày kết nối)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** xong — sẵn sàng test (b3, thuần client, KHÔNG deploy)
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* streak là VIEW phái sinh từ marker `couples/{coupleId}/dailyAnswers/{date}` đã có, gắn cờ `bothAnswered` client-side khi người thứ 2 trả lời (D-PO-2). `StreakService` watch marker (limit 180, lọc `bothAnswered==true` client-side → KHÔNG composite index). `StreakProvider` đếm chuỗi liên tiếp lùi từ hôm nay theo lịch local. Fail-soft tuyệt đối (lỗi → ẩn chip). 3 surface UI: StreakChip (footerExtra của CounterCard), StreakSheet (bottom sheet), dòng summary ở Journal header. Celebration 5 mốc bằng confetti sẵn, one-shot guard Hive per couple.
- *File/hàm đụng tới:*
  - **TẠO** `lib/services/streak_service.dart` — `watchRevealedDates(coupleId)` (stream marker limit 180, filter `bothAnswered==true`, trả list date-key newest-first; local fallback → empty).
  - **TẠO** `lib/providers/streak_provider.dart` — enum `StreakState{hidden,noStreak,activeToday,inProgress,atRisk}`; `_recompute()` (thuật toán streak, ~L208); `_longestRun()` (kỷ lục trong cửa sổ); `_maybeFlagMilestone()` + Hive box `streak_state` (guard one-shot per couple); expose `currentStreak/longestStreak/everHadStreak/nextMilestone/daysToNextMilestone/justReachedMilestone/needsActionToday/isVisible`; `watchForCouple(coupleId, coupleActive:)`/`clear()`.
  - **TẠO** `lib/widgets/streak_chip.dart` — `StreakChip` (consume provider, pill glass token §7, flame màu theo cường độ §4, glow theo state, tap→sheet, ẩn khi hidden/error, shimmer khi loading) + `StreakVisuals` (map streak→màu flame, dùng chung với sheet).
  - **TẠO** `lib/widgets/streak_sheet.dart` — `StreakSheet.show()` (explainer) + `StreakSheet.showMilestone()` (celebration). Số serif 56 ShaderMask sunsetRomance, title/body theo state (§9.2), progress bar tới mốc kế, CTA "Trả lời ngay" (chỉ khi `needsActionToday` → pop), count-up + confetti + mediumImpact ở milestone.
  - `lib/services/daily_question_service.dart` `submitAnswer` (~L106–135) — sau ghi response, đọc count responses; nếu ≥2 → merge `{bothAnswered:true, revealedAt:serverTimestamp()}` vào marker (best-effort try/catch). D-PO-2.
  - `lib/widgets/counter_card.dart` — thêm optional `Widget? footerExtra` (render center dưới footer, default null → không phá call-site khác).
  - `lib/screens/home_screen.dart` — `footerExtra: const StreakChip()` ở CounterCard `_entrance(3)`; listener `_onStreakChanged` (auto-show StreakSheet.showMilestone sau delay 400ms khi `justReachedMilestone`, guard `_celebratingMilestone` + consume); import streak provider/widgets.
  - `lib/screens/journal_screen.dart` — `_JournalStreakSummary` (dòng read-only, `streakJournalSummary`/`streakJournalSummaryNone`, ẩn khi hidden/error).
  - `lib/app/session_resolver.dart` — wire `streakProvider.watchForCouple(coupleId, coupleActive: !isWaitingForPartner)` khi couple active; `clear()` khi sign-out/no-couple.
  - `lib/main.dart` — đăng ký `StreakProvider` trong MultiProvider.
  - `lib/l10n/app_en.arb` + `app_vi.arb` — thêm ~30 key §9 (placeholder n/m kiểu int); **dọn 2 stub cũ** `dayStreakLabel`/`dayStreakValue` (đã grep: không dùng trong Dart).
- *Thay đổi model / Firestore / Cloud Function / native config:* CHỈ thêm field `bothAnswered`/`revealedAt` (additive) vào marker `dailyAnswers/{date}` set client-side. KHÔNG schema response mới, KHÔNG collection mới, KHÔNG CF, KHÔNG đụng couple doc, KHÔNG native.
- *Cần deploy?* **KHÔNG.** Rules marker hiện cho member ghi field thêm (validate vẫn pass vì date/questionVi/questionEn còn mặt qua merge). Không sửa firestore.rules/functions.

## Thuật toán streak (vị trí compute)
`StreakProvider._recompute(List<String> dates)`:
1. Parse date-key → set `DateTime` date-only (local).
2. Anchor: today revealed → `activeToday`; else yesterday revealed → `inProgress`; else day-before revealed → `atRisk` (đệm 1 ngày); else → `noStreak`.
3. `currentStreak` = đếm liên tiếp lùi từ anchor (while revealed.contains(cursor)).
4. `longestStreak` = `_longestRun()` (quét mỗi run đúng 1 lần, chỉ trong cửa sổ 180 ngày tải về — D-PO-1).
5. `everHadStreak` = true nếu current≥1 hoặc có bất kỳ ngày revealed nào trong lịch sử (chọn copy restart vs start).

## Marker bothAnswered (D-PO-2)
- Set tại `daily_question_service.dart` `submitAnswer`, ngay sau khi ghi marker question (best-effort): `_responses(...).get()` → nếu `docs.length >= 2` → `_dailyAnswers(...).doc(dateKey).set({bothAnswered:true, revealedAt:serverTimestamp}, merge:true)`.
- Xác nhận KHÔNG cần rules/CF: field additive, member write rule chỉ validate date/questionVi/questionEn (vẫn present qua merge trước đó). Thất bại không làm fail trả lời (try/catch nuốt lỗi).

## Celebration one-shot guard
- Hive box `streak_state`, key = coupleId, value = `List<int>` các mốc đã mừng. `_celebrateIfNew()` thêm mốc + persist + set `justReachedMilestone`.
- Reset chuỗi (currentStreak về 0) → `_clearCelebrated(coupleId)` xoá key → cho mừng lại mốc cũ ở chuỗi mới (đúng ý đồ design §6).
- Chỉ flag khi `todayRevealed && newStreak > previousStreak && milestones.contains(newStreak)` → không bật khi mở Home với chuỗi-dài-sẵn.
- Home `_celebratingMilestone` (session flag) + delay 400ms tách khỏi confetti reveal của Daily card (KHÔNG double-confetti chồng).

## Edge case kỹ thuật đã xử lý
- Fail-soft: lỗi đọc stream → `hasError`, state `hidden`, ẩn chip, KHÔNG toast/throw.
- Couple `waiting_partner` → `coupleActive=false` → state `hidden` (chip không render).
- Day rollover khi app mở: `_recompute` dùng `DateTime.now()` mỗi lần stream push; chip cập nhật realtime khi marker hôm nay flip revealed.
- Local fallback (no Firebase): service trả empty → state noStreak/hidden, không crash.
- Malformed date-key → `_dateOnlyFromKey` trả null, bỏ qua (không corrupt count).

## Giới hạn v1 (lệch/giảm so với design — cần Tester soi)
- **`longestStreak` ≤ 180 ngày** mới chính xác (D-PO-1: suy từ cửa sổ marker đã tải, KHÔNG lưu trên couple doc). Kỷ lục thực >180 ngày sẽ bị cắt còn 180.
- **`bothAnswered` chỉ có từ b3 trở đi.** Các ngày reveal LỊCH SỬ (trước khi ship cờ này) KHÔNG có marker `bothAnswered` → streak thực tế tính từ thời điểm ship. Cặp đang có chuỗi cũ sẽ thấy chuỗi "bắt đầu lại" — chấp nhận v1 (không backfill).
- **`bothAnswered` set client-side** (best-effort): nếu device thứ 2 mất mạng đúng lúc set cờ, ngày đó tạm thiếu cờ tới lần ghi sau; reveal UI (Daily card) vẫn đúng vì dựa trên `hasRevealed` của responses, độc lập cờ.
- **CTA "Trả lời ngay"** v1 chỉ `Navigator.maybePop()` (Daily Question card ở ngay dưới hero) — KHÔNG `Scrollable.ensureVisible` (design §6 cho phép v1 chỉ pop).
- **Chip không pulse** khi reveal mới trong phiên (design §5.2 mô tả pulse 420ms) — chip cập nhật state tức thì, KHÔNG animation pulse. Glow theo state vẫn đúng. Có thể bổ sung Đợt sau (không chặn).
- D-PO-3: KHÔNG badge "🔥 30" persistent trên chip (chip 1 dòng). D-PO-4: KHÔNG LoveLottie slot mốc (confetti cho cả 5 mốc).

## Checklist implement
- [x] Marker `bothAnswered` client-side (D-PO-2), không deploy
- [x] StreakService (watch limit 180, filter client) + StreakProvider (thuật toán + fail-soft)
- [x] CounterCard `footerExtra` slot (không phá call-site)
- [x] StreakChip (token §7, màu/glow §4, ẩn hidden/error, shimmer loading)
- [x] StreakSheet (số serif 56 ShaderMask, state copy §9.2, progress, CTA, milestone celebration confetti+count-up+haptic)
- [x] Journal header streak summary
- [x] Celebration one-shot guard Hive `streak_state` per couple + reset xoá guard
- [x] i18n: thêm ~30 key §9 CẢ en+vi, dọn 2 stub cũ, `gen-l10n` OK
- [x] `flutter analyze` sạch (No issues found)
- [x] Không hardcode chuỗi (qua l10n)

## Nhật ký implement
- [2026-06-04] [Dev] Implement Couple Streak shame-free (b3) thuần client: StreakService + StreakProvider (enum 5 state, thuật toán liên tiếp + đệm 1 ngày, longest≤180, milestone one-shot guard Hive `streak_state`). UI 3 surface: StreakChip (footerExtra CounterCard), StreakSheet (explainer + milestone celebration confetti/count-up), Journal summary. Marker `bothAnswered` set client-side trong `daily_question_service.submitAnswer` (D-PO-2, additive, KHÔNG deploy rules/CF). i18n ~30 key vi+en, dọn 2 stub cũ. `flutter gen-l10n` + `flutter analyze` sạch. `flutter test`: 22 pass, 1 fail pre-existing (`widget_test.dart` login copy, không liên quan streak). KHÔNG commit/deploy.
```
fvm flutter gen-l10n   → OK (l10n.yaml)
fvm flutter analyze    → No issues found!
fvm flutter test       → 1 fail pre-existing (widget_test.dart), phần còn lại pass
```
- [2026-08-23] [Dev] **Khôi phục chuỗi PROD cho couple của `dodaoanhtuan@gmail.com` (uid `Hz6rLv3h…`, couple `qlAB4LKZCQV7MwB8SvPy`)** theo lệnh user. Nguyên nhân: ngày **2026-08-20** chỉ "Em Bé Iu" trả lời, "Anh By" thiếu ⇒ marker không có `bothAnswered` ⇒ chuỗi đứt (còn 2: 08-21, 08-22). Cách làm: script **`scripts/prod-daily-answer.js`** (mới — firebase-admin qua refresh-token firebase-tools, ADC `authorized_user` tạm 0600, KHÔNG cần service-account) `restore` tạo `dailyAnswers/2026-08-20/responses/Hz6rLv3h…` = `{authorUserId, text:"đã nói trực tiếp", answeredAt:serverTimestamp}` (user gõ "trực tiêps" — sửa chính tả) + merge marker `{bothAnswered:true, revealedAt}`; `answeredAt`/`revealedAt` = giờ ghi thật (05:01Z), KHÔNG backdate — không UI nào đọc 2 field này. Verify bằng `computeStreak` (y hệt `StreakProvider._recompute`): **79 ngày liên tục 2026-06-05→08-22, gaps=none** (state `inProgress` vì 08-23 chưa ai trả lời). 📌 **Tác dụng phụ không tránh được:** CF `notifyDailyAnswer` (onCreate, **không guard theo ngày**) vẫn chạy — đã xác nhận inbox người ấy có item `daily_question date=2026-08-20 bothAnswered=true` lúc 05:01:17Z + CF tự stamp lại `revealedAt`; push kèm `bothAnswered=true` ⇒ máy người ấy huỷ dải nhắc local hôm nay (1040–1049 + EOD 1050–1052; backstop 1020–1033 GIỮ; `_cancelStaleDailyQuestionNudges` KHÔNG check `date`) tới khi họ mở app. Nợ nhỏ ghi nhận: CF/client nên so `date == hôm nay` trước khi wake/huỷ — chưa sửa (chỉ ảnh hưởng backfill tay, không ảnh hưởng luồng thường).
