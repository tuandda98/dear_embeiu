# 🧪 Test — Daily question (câu hỏi hằng ngày)

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** 🧪 **PASS code-level (2026-08-09, sau 3 vòng)** — 10/10 bug + 2 vấn đề copy đã fix (BUG-1…BUG-10, V3, V4). 3 hạng mục CỐ Ý không sửa vì rủi ro > lợi (D4 múi giờ LDR · D16 channel Android · C12 exact alarm) + 2 hạng mục by design (B7, D2) — lý do ở `dev.md` vòng 3. analyze 0 · test **24/24** · rules-test 197. **⚠️ Chờ deploy `functions:notifyDailyAnswer` prod + build app mới + smoke-test runtime 2 máy.**
- **Người/role:** Master Tester

## Phạm vi test
Audit **nội dung + thông báo** của câu hỏi hằng ngày, code-level (đọc đĩa, không chạy máy thật). Bao trùm: bank 229 câu + thuật toán chọn câu · copy 5 trạng thái card · 6 nguồn thông báo (giờ user đặt 1040–1049 · cuối ngày 1050–1052 · nhắc riêng account-gated 1110–1139 · push CF `notifyDailyAnswer` · banner foreground · inbox Notification Center) · deep-link tap · i18n · rules `dailyAnswers`.

## Test case

### A. Nội dung
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| A1 | happy | Bank 229 câu, mỗi câu có vi+en | Không trùng, không thiếu dịch, không ICU `{}` | ✅ 0 trùng / 0 thiếu / 0 ICU |
| A2 | đa ngôn ngữ | Giọng copy | Dùng "chúng mình", không "hai đứa" | ⚠️ 0 câu "hai đứa" nhưng **6 câu dùng "hai bạn"** (idx 6/17/21/22/32/44) → BUG-9 (✅ fix: 6 câu → "chúng mình") |
| A3 | happy | Cùng couple, cùng ngày, 2 máy | Cả hai thấy CÙNG 1 câu | ✅ deterministic (FNV-1a + permutation + daysSinceEpoch) |
| A4 | edge | Thêm câu vào bank | Không đảo thứ tự, giữ no-repeat | ❌ **đảo toàn bộ + phá no-repeat** → BUG-4 (✅ comment đã sửa + khuyến nghị sửa-câu-thay-vì-thêm; nợ thiết kế giữ) |
| A5 | edge | 2 máy lệch phiên bản app (bank khác độ dài) | Cùng câu hỏi | ❌ **2 câu KHÁC NHAU** → BUG-4 (✅ sửa comment sai; nợ thiết kế giữ, có khuyến nghị) |
| A6 | negative | Bank rỗng / coupleId rỗng | Không throw | ✅ trả chuỗi rỗng / seed 0 |
| A7 | happy | Copy 5 trạng thái card (A/B/C/D + chưa-ghép-đôi) | Mạch lạc, đúng trạng thái | ✅ (redaction bars thay blur — fix 1.4.1 có trên đĩa) |
| A8 | negative | Text > 280 ký tự / rỗng | Clamp / không ghi | ✅ client clamp + rule `size() <= 280` |

### B. Thông báo — theo trạng thái trả lời
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| B1 | happy | A trả lời trước | A: không push (là author). B: 1 push "A đã trả lời…" + body giục trả lời + 1 inbox | ✅ |
| B2 | happy | B trả lời sau (hoàn thành cặp) | A nhận body **"Cả hai đã trả lời rồi"** (`count() >= 2`) | ✅ (fix 1.4.1) |
| B3 | happy | Người trả lời thứ 2 | Không nhận thông báo nào (đã thấy reveal tại chỗ) | ✅ |
| B4 | edge | **A trả lời sớm rồi KHÔNG mở lại app; B trả lời sau** | Lịch local của A phải huỷ | ❌ **4 noti SAI/ngày** ("người ấy chưa trả lời" + hù mất chuỗi ×2) → **BUG-1 (đã fix)** |
| B5 | edge | Hai người bấm gửi gần đồng thời | Cả hai nhận copy "cả hai đã trả lời" | ⚠️ race: CF đọc `count` sớm → 1 người bị giục trả lời dù vừa trả lời → BUG-7 (✅ fix: CF tự stamp marker + đọc doc người nhận) |
| B6 | edge | Hai người gửi đồng thời, cả 2 client đọc thấy 1 doc | `bothAnswered` phải được set | ❌ **không ai set** → card reveal nhưng **streak + journal MẤT ngày** → BUG-7 (✅ fix: CF tự stamp marker + đọc doc người nhận) |
| B7 | negative | Sửa câu trả lời đã gửi | (không bắt buộc push) | ⚠️ không push (CF chỉ `onDocumentCreated`) — chấp nhận, ghi nhận |
| B8 | edge | Couple `waiting_partner` (chưa ghép xong) | Không nhắc (chưa có gì để cùng làm) | ❌ **vẫn arm đủ 4 nhắc** → BUG-5 (✅ fix: gate `coupleActive`) |

### C. Thông báo — lịch local
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| C1 | edge | **Cả ngày không mở app** | Vẫn nhắc đúng giờ user đặt | ❌ **KHÔNG có nhắc nào** (one-shot, chỉ arm khi app mở) → BUG-2 (✅ fix: dải backstop 1020–1033, rolling 7 ngày từ MAI) |
| C2 | edge | User đặt giờ trùng 21/22/23h | 1 thông báo | ❌ **2 thông báo cùng phút** (2 dải không dedupe) → BUG-6 (✅ fix: loại giờ trùng `_activeEodHours`) |
| C3 | happy | Copy 22h vs 23h | Leo thang, khác nhau | ❌ **y hệt nhau** → **BUG-3 (đã fix)** |
| C4 | happy | Đặt tối đa 10 giờ | — | ⚠️ nhiều noti/ngày — **✅ giảm nhẹ: hint ở Settings + xoay vòng 3 biến thể copy + bỏ giờ trùng EOD** |
| C5 | happy | UI có nói về 21/22/23h? | Có hint | ❌ key `dailyQuestionReminderEndOfDayHint` **KHÔNG TỒN TẠI** trong cả 2 ARB (dev.md 2026-06-19 ghi là đã thêm — doc drift) → BUG-8 (✅ fix: thêm key hint + render ở Settings) |
| C6 | edge | Đặt giờ đã qua trong ngày | Skip, không dồn sang mai | ✅ |
| C7 | happy | Cả hai đã trả lời rồi mới mở app | Huỷ sạch 2 dải | ✅ (`_eodHasRevealed`) |
| C8 | edge | Stream DQ đang re-subscribe (`isLoading`) | Không re-arm nhắc vừa huỷ | ✅ (fix race 2026-06-20 còn nguyên) |
| C9 | negative | Chưa cho quyền notification | Tự tắt, trả false | ✅ |
| C10 | edge | Chuỗi = 0 | Copy "mở chuỗi mới", không "mất chuỗi" | ✅ |
| C11 | edge | Máy reboot | Lịch còn | ✅ có `RECEIVE_BOOT_COMPLETED` + boot receiver |
| C12 | edge | Android Doze | Nổ đúng giờ | ⚠️ `inexactAllowWhileIdle` → 23h có thể trễ qua nửa đêm |
| C13 | edge | Account gated `thaohathao14@` | UI khớp thực tế | ⚠️ toggle hiện ON + hiện giờ nhưng **không schedule gì** (suppress) → BUG-10 (✅ fix: ẩn tile khi suppressed) |

### D. Đồng bộ couple / môi trường / deep-link
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| D1 | offline / 2 thiết bị | A đổi giờ → B theo | Sync qua `prefs/home` | ✅ |
| D2 | offline / 2 thiết bị | A **tắt** nhắc | (couple-shared) | ⚠️ B cũng tắt — đúng design, dễ gây bất ngờ |
| D3 | offline | Đổi giờ khi offline | Không chặn UI | ✅ Hive cache + `unawaited` publish |
| D4 | edge | 2 người lệch múi giờ (LDR) | Cùng bucket ngày | ❌ 2 bucket khác → **không bao giờ reveal**, streak/journal trống (đã ghi "accepted v1") |
| D5 | edge | Marker doc ghi fail rồi merge `bothAnswered` | Set được | ❌ rules đòi `questionVi/En` → DENY im lặng (`catch {}`) → mất ngày khỏi streak/journal — **✅ fix: CF stamp marker bằng Admin SDK (bypass rules)** |
| D6 | edge | Card reveal nhưng marker thiếu flag | Trạng thái nhất quán | ❌ card "cả hai đã trả lời" vs chip chuỗi "tới lượt hôm nay" — **✅ fix cùng BUG-7** |
| D7 | edge | Đúng nửa đêm khi app đang mở | Ghi vào ngày mới | ⚠️ rơi vào bucket **hôm qua** — **✅ fix: `submit()` tự re-align `_dateKey` + resubscribe** |
| D8 | offline | Không có Firebase (local fallback) | Không crash | ✅ Hive lưu câu của mình; journal/streak rỗng (accepted) |
| D9 | cold start | Tap push (cold + warm) | Home tab 0 + scroll card | ✅ |
| D10 | cold start | Tap banner foreground | Cùng route (payload JSON) | ✅ |
| D11 | happy | Tap inbox noti hôm nay + đã reveal | Journal focus đúng ngày | ✅ |
| D12 | edge | Tap inbox noti **ngày cũ** | Mở ngày đó trong journal | ❌ về Home xem câu HÔM NAY — **✅ fix: pushReplacement JournalScreen(focusDate)** |
| D13 | đa ngôn ngữ | Người ấy chưa đặt displayName, máy EN | Fallback theo ngôn ngữ máy | ❌ `normalizeActorName` trả **"Người ấy"** tiếng Việt — **✅ fix: `partnerFallback` theo lang + inbox drop tên rỗng** |
| D14 | đa ngôn ngữ | Copy inbox khi cả hai đã trả lời | Khớp push | ⚠️ chỉ 1 biến thể — **✅ fix: inbox field `bothAnswered` + `notifDailyQuestionBoth`** |
| D15 | đa ngôn ngữ | Key l10n DQ/streak/journal | Đủ ở cả 2 ARB | ✅ 0 thiếu / 0 thiếu |
| D16 | edge | Channel Android của push | Channel riêng cho câu hỏi | ⚠️ dùng chung `partner_photo_updates`, tên hiển thị "Ảnh mới từ người ấy" |

## Bug report

### BUG-1: Người trả lời TRƯỚC bị nhắc sai tới 4 lần/ngày — ✅ ĐÃ FIX 2026-08-09
- **Severity:** critical
- **File:** `lib/providers/reminder_provider.dart:_scheduleEndOfDay` · `lib/services/push_notification_service.dart:21`
- **Expected:** B trả lời xong → lịch nhắc của A huỷ ngay.
- **Actual:** lịch local là one-shot arm sẵn, chỉ re-evaluate khi app A chạy (`HomeScreen._refreshDqSafetyNet`). `firebaseMessagingBackgroundHandler` chỉ init Firebase. ⇒ A nhận 20/21/22/23h "Người ấy chưa trả lời câu hỏi hôm nay" + "Sắp lỡ mất chuỗi rồi!" dù B đã trả lời và chuỗi đã an toàn.
- **Steps:** 08:00 A trả lời → đóng app cả ngày · 10:00 B trả lời · 20:00–23:00 A nhận 4 noti sai.
- **Fix:** 2 lớp — (1) CF gửi `data.bothAnswered` + `aps.contentAvailable` → client huỷ dải ngay ở background/foreground isolate (`ReminderService.cancelDailyQuestionBands`); (2) khi `iAnswered` thì bỏ hẳn 22h+23h. Còn hở: iOS bị force-quit không có background wake ⇒ 4 → 2 noti sai.

### BUG-2: Không mở app trong ngày ⇒ không có nhắc nào — ❌ CÒN MỞ
- **Severity:** critical (mất phần lớn giá trị retention)
- **File:** `lib/services/reminder_service.dart:347` (`scheduleDailyQuestionTimes`, one-shot, không `matchDateTimeComponents`)
- **Expected:** đặt 20:00 → mỗi ngày 20:00 đều được nhắc.
- **Actual:** chỉ những ngày user mở app mới có lịch. Đúng nhóm user cần nhắc nhất (đã lười mở app) thì không bao giờ được nhắc.
- **Hướng fix:** quay lại repeat thật (`DateTimeComponents.time`) + huỷ khi reveal, hoặc cron CF push backstop.

### BUG-3: Copy 22h và 23h y hệt nhau — ✅ ĐÃ FIX 2026-08-09
- **Severity:** major · **File:** `reminder_provider.dart` (cũ: `isWarning = hour >= 22` dùng cùng title+body)
- **Fix:** thêm `dqStreakWarningFinalTitle/Body/StartBody` cho 23h (last call).

### BUG-4: Đổi độ dài bank ⇒ đảo toàn bộ thứ tự + phá no-repeat + lệch câu giữa 2 phiên bản — ❌ CÒN MỞ
- **Severity:** major · **File:** `lib/data/daily_questions.dart:1046`
- ⚠️ **Chỉnh cho công bằng (verify vòng 2):** đây KHÔNG phải phát hiện mới — `dev.md` §"Trade-off / giả định (vá nền 2026-06-04)" đã ghi rõ CẢ HAI hệ quả ("append câu → lịch DỊCH" + "hai partner khác bank length → khác câu cùng ngày") và **chấp nhận có ý thức**. Cái thực sự sai là **doc comment trong code** (`:1040`) khẳng định ngược: *"appending questions does not reshuffle the bank"*. ⇒ hạ ưu tiên: nợ đã biết, chỉ cần sửa comment cho khỏi dẫn người đọc sau đi sai.
- **Actual:** mô phỏng cùng `coupleId`, ngày 2026-08-09: n=58→idx 27 · n=214→188 · n=229→140 · n=230→126 · n=235→98. Mở bank 229→235 làm câu idx 51 vừa ra trong 30 ngày TRƯỚC lại quay lại trong 30 ngày SAU. Lệch phiên bản 2 máy ⇒ 2 người trả lời 2 câu khác nhau, marker `questionVi` bị người trả lời thứ 2 ghi đè. *(Hiện được che bởi force-update `minBuildNumber=15`.)*

### BUG-5: Couple chưa ghép xong vẫn bị nhắc 4 lần/ngày — ❌ CÒN MỞ
- **Severity:** major · **File:** `lib/screens/home_screen.dart:811` (`_syncReminders` không gate `couple.isWaitingForPartner`)

### BUG-6: Giờ user đặt trùng 21/22/23h ⇒ 2 noti cùng phút — ❌ CÒN MỞ
- **Severity:** minor · dải 1040–1049 và 1050–1052 độc lập, không dedupe.

### BUG-7: `bothAnswered` set client-side ⇒ race làm mất ngày khỏi streak/journal — ❌ CÒN MỞ
- **Severity:** major · **File:** `lib/services/daily_question_service.dart:149-161` (bọc `catch {}`)
- **Hướng fix:** chuyển sang CF `onWrite` (server tự count, idempotent) — đồng thời đóng luôn race copy push (B5).

### BUG-8: UI không hề nói về 3 nhắc cuối ngày — ❌ CÒN MỞ
- **Severity:** minor · key `dailyQuestionReminderEndOfDayHint` không tồn tại trong `app_vi.arb`/`app_en.arb` dù `dev.md` (2026-06-19) và `CLAUDE.md` §6 ghi là đã có.

### BUG-9: 6 câu trong bank dùng "hai bạn" thay vì "chúng mình" — ❌ CÒN MỞ
- **Severity:** minor · idx 6/17/21/22/32/44.

### BUG-10: Account gated — toggle Settings hiện ON nhưng không schedule gì — ❌ CÒN MỞ
- **Severity:** minor · `reminder_provider.dart:843` (`_suppressSharedDqReminders`).

## Nhật ký test
- [2026-08-09] [Tester] Audit code-level **nội dung + thông báo** câu hỏi hằng ngày theo yêu cầu user. Kết quả **FAIL**: 39 case, 10 bug (3 critical/major thuộc P0). Nội dung bank sạch (229 câu, 0 trùng/0 thiếu dịch/0 ICU, l10n đủ 2 chiều) nhưng thuật toán chọn câu không ổn định khi đổi độ dài bank (BUG-4, đã mô phỏng số cụ thể). Thông báo: phát hiện BUG-1 (người trả lời trước bị nhắc sai 4 lần/ngày — nặng hơn hạn chế "app kill đúng lúc" đã ghi trong CLAUDE.md) + BUG-2 (không mở app ⇒ mất hẳn nhắc) + BUG-3 (22h/23h trùng copy). Dev đã fix BUG-1 + BUG-3 cùng ngày (xem `dev.md`); **BUG-2 và 7 bug còn lại CHƯA fix**. Chưa smoke-test runtime — cần 2 máy thật để nghiệm thu BUG-1 (đặc biệt nhánh iOS background wake) sau khi deploy CF.
- [2026-08-09 vòng 2] [Tester] **Verify lại nội dung thông báo sau fix** (dump chuỗi từ `app_localizations_vi.dart`/`_en.dart` — bản generated, không đọc ARB). Chuỗi mới sinh đúng, đủ dấu TV, không ICU. **Bắt được 2 lỗi trong copy 23h của vòng 1** (nay đã sửa): "chuỗi đầu tiên" sai với couple từng có chuỗi rồi đứt (`currentStreak == 0` không đồng nghĩa chưa từng có — `StreakProvider.everHadStreak` mới phân biệt được, mà `_scheduleEndOfDay` không nhận field này); title 23h nhẹ hơn title 22h → tụt cường độ leo thang. **Bug mới ghi nhận: V3** title dải giờ user đặt lệch body khi tôi đã trả lời · **V4** đặt nhiều giờ nhận đúng 1 nội dung y hệt lặp lại (1 title/body dùng chung cho cả dải 1040–1049). Cả hai CHỜ user chốt copy.
- [2026-08-09 vòng 3] [Tester] **Re-verify sau khi Dev sửa hết.** Đọc lại đĩa: 12/12 hạng mục đã đóng có mặt trong code (backstop 1020–1033 · gate `coupleActive` · loại giờ trùng · CF stamp marker + đọc doc người nhận · hint Settings · 6 câu bank · ẩn tile gated · title/bodies mới · rollover guard trong `submit` · journal cho noti ngày cũ · fallback tên theo lang · inbox `bothAnswered`). Bắt được 1 lỗi Dev tự sửa giữa đường: bản backstop đầu dùng repeat `DateTimeComponents.time` → trên iOS là trigger chỉ-giờ-phút nên có thể nổ NGAY HÔM NAY, trùng dải one-shot; đã đổi sang cửa sổ one-shot nhiều ngày. **Nợ mới ghi nhận: iOS chỉ cho 64 pending notification/app** mà tổng các dải (lunar 40 + personal 40 + partner 50 + DQ 27) đã vượt xa ⇒ notification xa có thể bị hệ thống bỏ; cần rà lại tổng ngân sách khi thêm dải mới. Vẫn CHƯA smoke-test runtime.
- [2026-08-09 vòng 4] [Tester] **Re-verify toàn đợt sửa theo yêu cầu user.** Soi lại như code người khác: CF `notifyDailyAnswer` đọc-một-lần/stamp-marker/inbox đúng; l10n 5 key mới dump từ generated đủ dấu; id bands không đụng nhau; thứ tự cancel-trước-banner đúng. **Bắt được 1 lỗ hổng THẬT trong fix BUG-1 lớp push:** Android background/terminated KHÔNG chạy `onBackgroundMessage` cho message có notification block (chỉ data-only mới chạy — verify Java source plugin) ⇒ kịch bản chính của BUG-1 trên Android chưa được vá ở vòng 3. Dev vá cùng vòng: option `wakeClients` + data-only companion cho riêng device Android + refactor mapping `outgoing[{device,message}]` (tránh crash lệch index khi attribute failure). Sau vá: iOS background = content-available; Android background/terminated = companion; foreground 2 nền = onMessage; hở còn lại chỉ iOS force-quit + Android Force-stop (lớp 2 đỡ). analyze 0 · test 24/24 · rules 197. Vẫn CHƯA smoke-test runtime 2 máy.
