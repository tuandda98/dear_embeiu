# 💻 Dev — Endless questions

> Dev sở hữu. Đọc `overview.md` trước. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** đang làm (Q1 — engine lõi + nguồn bank + nguồn template xong; 'revisit'/'ai'/backend do agent khác)
- **Người/role:** Dev

## Kế hoạch kỹ thuật (Q1)
- *Cách tiếp cận:* **marker `couples/{id}/dailyAnswers/{dateKey}` = nguồn sự thật câu hỏi hôm nay.** Máy nào resolve trước ghi marker bằng `runTransaction` (chỉ ghi khi marker chưa có `questionVi`), máy kia đọc lại của họ ⇒ câu hỏi được phép phụ thuộc dữ liệu động (mood/streak/ảnh/lịch sử) mà 2 máy vẫn thấy y hệt.
- *File mới:*
  - `lib/services/question_engine.dart` — `QuestionEngine` + `ResolvedQuestion`.
  - `lib/services/question_state_service.dart` — `QuestionState` + đọc/ghi `couples/{id}/questionState/main`.
  - `lib/services/bank_question_source.dart` — `BankQuestionSource` (key `'bank'`).
  - `lib/services/template_question_source.dart` — `TemplateQuestionSource` (key `'template'`).
  - `lib/data/question_templates.dart` — 88 template vi+en (14 nhóm).
  - `test/question_engine_test.dart` — 22 test thuần (không cần Firebase).
- *File sửa:*
  - `lib/data/daily_questions.dart` — CHỈ APPEND 3 helper public: `stableQuestionHash`, `deterministicPermutation`, `daysSinceQuestionEpoch`. `questionForCouple`/`questionTextForCouple` giữ nguyên cho fallback/legacy.
  - `lib/services/daily_question_service.dart` — `submitAnswer` thêm 3 optional param `questionVi/questionEn/source`; marker **đọc trước** rồi chỉ ghi câu hỏi khi marker CHƯA có (không derive lại từ bank), thêm field `source`.
  - `lib/providers/daily_question_provider.dart` — inject `QuestionEngine`, resolve async 1 lần/(couple, ngày), getter mới.
- *Thay đổi Firestore:* đọc/ghi `couples/{id}/questionState/main` (`askedBankIds`, `recentTemplateKeys`, `recentRevisitDates`, `updatedAt`) + đọc `prefs/home.aiQuestionsEnabled` + ghi thêm field `source`/`questionId`/`templateKey`/`refDate` lên marker `dailyAnswers/{date}`. **Rules do agent backend làm** — client fail-soft: `permission-denied`/thiếu doc ⇒ state rỗng, vẫn chạy.
- *Cần deploy?* rules (agent khác). Client không chặn nếu chưa deploy.

## API public (cho người điều phối)
```dart
// question_engine.dart
QuestionEngine({List<QuestionSource> sources = const [], FirebaseFirestore? firestore, QuestionStateService? stateService});
factory QuestionEngine.withDefaults({FirebaseFirestore? firestore, QuestionStateService? stateService}); // đã có [template, bank]
void registerSource(QuestionSource s, {int priority = 0});
bool hasSource(String key);
List<String> planFor(QuestionContext ctx); // debug/test
Future<ResolvedQuestion> resolveToday({
  required String coupleId, required String myUid, required String partnerUid,
  required DateTime date, required String languageCode, required DateTime anniversaryDate,
  required int currentStreak, int photosThisWeek = 0,
  String? myMoodToday, String? partnerMoodToday,
});

// DailyQuestionProvider
DailyQuestionProvider({DailyQuestionService? service, QuestionEngine? engine});
QuestionEngine get engine;          // để registerSource('revisit'/'ai')
String todayQuestion(String lang);  // GIỮ chữ ký cũ (home_screen/today_ritual_card)
String get questionText;            // theo lang đã set qua updateContext
String? get questionSource;         // 'bank'|'template'|'revisit'|'ai'|null
String? get hintText;               // hint theo lang hiện tại, null nếu không có
String? hintFor(String lang);
bool get isResolvingQuestion;
void updateContext({int? currentStreak, String? myMood, String? partnerMood, int? photosThisWeek,
                    String? partnerUid, String? languageCode, DateTime? anniversaryDate});
```

## Thứ tự nguồn 1 ngày (engine)
1. `'ai'` nếu `prefs/home.aiQuestionsEnabled == true`
2. source đăng ký `priority > 0` (cao trước)
3. ghi đè theo lịch: 1/1 · 14/2 · 8/3 · 20/10 · 24–25/12 → mốc ngày yêu ±3 ngày (100/365/520/1000/1314 + tròn năm) → ngày 1 / ngày cuối tháng → mốc streak (7/30/50/100/200/365) → cuối tuần mà `photosThisWeek == 0` → mood người ấy
4. lịch tuần: T2 `template:week_start` · T3 bank · T4 `template:feeling` · T5 bank · **T6 `revisit`** · T7 bank · CN `template:week_recap`
5. fallback cuối: `template` (tự chọn nhóm) → `bank`
Bước trùng bị dedupe; source chưa đăng ký / trả null / ném exception ⇒ bỏ qua.

## Edge case đã xử lý
- Không Firebase / `coupleId` rỗng ⇒ fallback `questionTextForCouple` cũ, source `'bank'`, KHÔNG ghi gì.
- Marker đã có câu ⇒ dùng nguyên văn (kể cả `source`/`questionId`/`templateKey`/`refDate`).
- Transaction thua (máy kia ghi trước) ⇒ dùng câu của họ, KHÔNG ghi `questionState`.
- Ghi marker/`questionState` lỗi ⇒ vẫn hiện câu đã chọn (không chặn card).
- Bank hết câu (`askedBankIds` phủ hết) ⇒ coi như rỗng, mở vòng mới.
- Cap client-side: `askedBankIds` ≤ 2000, `recentTemplateKeys` ≤ 60, `recentRevisitDates` ≤ 60 (vượt thì ghi đè list đã cắt đầu thay vì `arrayUnion`).
- Template có placeholder không điền được (mood lạ, chưa tới mốc) ⇒ loại khỏi tập chọn; còn sót `%` ⇒ trả null (không bao giờ render token).
- Rollover nửa đêm: `submit()` re-align `dateKey` rồi resolve lại; kết quả await về trễ mà đã đổi ngày/couple thì bị bỏ (`_resolvedKey` guard).

## Giới hạn / còn nợ
- Provider CHƯA được wire từ `home_screen.dart` (ngoài phạm vi Q1): `updateContext` hiện chưa ai gọi ⇒ `currentStreak`/mood/photos = mặc định 0/null, `anniversaryDate` = hôm nay ⇒ hook mốc/mood/ảnh chưa kích hoạt tới khi điều phối wire.
- Chưa migrate `askedBankIds` cho các ngày ĐÃ hỏi trước đây (backfill nêu ở overview) ⇒ vài tuần đầu có thể trùng câu cũ.
- Không có chuỗi ARB mới. Nếu card muốn nhãn "Câu hỏi theo tuần/AI…" thì đọc `questionSource` + tự thêm key ARB ở phía UI (Q1 không đụng ARB).
- Đường ghi marker/`questionState` chỉ test được bằng emulator/2 máy thật — test Dart chỉ phủ phần thuần (lịch, deterministic, copy).

## Nhật ký implement
- [2026-09-05] [Dev] Q1: thêm `QuestionEngine` (marker = nguồn sự thật, transaction first-writer-wins) + `QuestionStateService` + `BankQuestionSource` (bỏ `% n`, chọn theo `askedBankIds`, bank gộp `dailyQuestions + dailyQuestionsExtra`, chỉ APPEND) + `TemplateQuestionSource` & 88 template vi/en 14 nhóm + `test/question_engine_test.dart` (22 test). Sửa `daily_question_service.submitAnswer` (không derive lại câu từ bank khi marker đã có) và `DailyQuestionProvider` (resolve async, `questionSource`/`hintText`/`isResolvingQuestion`/`updateContext`/`engine`). `flutter analyze` 0 issue · `flutter test` 81/81 pass. KHÔNG commit, KHÔNG deploy.
- [2026-09-05] [Dev] Q4: mở rộng ngân hàng câu hỏi — điền `lib/data/daily_questions_extra.dart` đúng **150 câu mới** vi+en (APPEND-ONLY, giữ nguyên doc comment/`library;`, không đụng `daily_questions.dart` nên index gốc bất biến). Phân bổ có comment nhóm: tuổi thơ & gia đình 15 · ước mơ & tương lai 15 · thói quen & đời thường 15 · du lịch & trải nghiệm 12 · ẩm thực & sở thích 12 · vui nhộn/nếu-như 15 · cảm xúc & lắng nghe 15 · biết ơn & điều nhỏ 12 · giao tiếp & cách yêu 12 · nhìn lại & trưởng thành 12 · sáng tạo/giả tưởng 10 · lời hứa & mong muốn nhỏ 5. Copy giữ giọng bank gốc (xưng "chúng mình"/"người ấy"/"bạn", không "hai đứa"), ≤160 ký tự, không `{}`/`<>`, không dấu nháy đơn trong chuỗi EN (tránh escape), không tên riêng. Thêm `test/daily_questions_extra_test.dart` (7 test): đếm đúng 150 · vi+en không rỗng · không có `{`/`}` · độ dài ≤200 · không trùng nội bộ · không trùng bank gốc (chuẩn hoá lowercase + bỏ dấu câu + gộp khoảng trắng, kiểm cả vi lẫn en) · merged bank giữ nguyên index gốc. Ngoài test tự động còn quét fuzzy (Jaccard token ≥0.58) đối chiếu 231 câu gốc: 0 cặp vi, 5 cặp en chỉ trùng khung câu — đã đổi 1 câu ("đặt tên loài hoa mới" → "nuôi một loài vật lạ đời") vì gần nghĩa với "đặt tên một vì sao" có sẵn; 4 cặp còn lại khác nghĩa rõ, giữ nguyên. `flutter analyze` **0 issue** · `flutter test` **81/81 pass** (lần chạy đầu có 1 fail ở `question_engine_test.dart` của agent khác đang sửa dở, chạy lại sau 75s thì sạch). KHÔNG commit, KHÔNG deploy. ⚠️ Bank gộp nay 231+150 = 381 câu — engine mới địa chỉ theo index nên an toàn, nhưng đường LEGACY `questionForCouple` (`% dailyQuestions.length`) không thấy 150 câu này; máy chạy bản cũ vẫn chỉ bốc trong 231 câu gốc.
- [2026-09-05] [Dev] **Vá theo Tester vòng 1 (test.md):** `DailyQuestionProvider._contextReady` — không resolve cho tới khi Home `updateContext` (fix P0 resolve rỗng do `session_resolver` gọi `watchForCouple` trước Home); `photosThisWeek` -1 = unknown (Home truyền -1 khi list rỗng) ⇒ hook "chưa có ảnh" không đoán; rules `questionVi/En` bất biến (mixed-version 1.5.0), +3 test → **241**; CF `generateDailyQuestion`: `date` chỉ hôm nay ±1 UTC + `aiAttempts` cap 3/cặp/ngày (`rate_limited`); `submitAnswer` marker qua `runTransaction`; engine `_withRevisitHint` dựng lại hint từ `refDate` (máy kia/sau restart); EN "1 days"→"1 day"; Settings toggle: stream hoist, revert + toast `aiQuestionsSaveFailed` khi ghi fail, dialog ghi rõ "bắt đầu từ câu hỏi ngày mai"; card chặn trả lời khi đang resolve (`dailyQuestionPreparing`). ✅ DEV deploy trace `20260905T120412Z`. ⏳ Nợ: App Check (app chưa tích hợp), ghi `questionState` khi publish fail, copy `look_back` sau mốc, nâng `minBuildNumber`=20 sau khi 1.6.0 live 2 store.
- [2026-09-05] [Dev] **Vá theo Tester vòng 2 (test.md):** CF `notifyDailyAnswer` stamp kèm `date` (P1 — marker CF tạo mới không còn bị `orderBy('date')` loại khỏi chuỗi/journal); `submitAnswer` fallback `set(merge)` khi transaction fail offline; `clear()` reset context; `photosThisWeek` theo `PhotoProvider.isLoading`; card caption khi resolving + AI timeout 8s; rules coi `questionVi==''` là chưa có (+2 test → **243**); hint rebuild dùng `truncateForQuote`; `_toggleSeq` cho toggle AI; engine bỏ record state khi publish fail; lọc template `look_back` khi mốc không còn ở phía trước. ✅ DEV deploy rules + `notifyDailyAnswer` trace `20260905T122337Z`.
