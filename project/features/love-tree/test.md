# Cây tình yêu (Love Tree) — test log (Tester)

## [2026-06-14] [Tester] Nghiệm thu v1 ở mức CODE (read-only) — VERDICT: PASS (SHIP code-level)

`flutter analyze lib/` = **No issues found**. Phạm vi: `love_tree_service.dart`, `love_tree_screen.dart`, `streak_chip.dart`, `app_vi/en.arb`. KHÔNG đụng backend/native.

### Acceptance criteria (design.md §10) — 12/12 PASS [VERIFIED code]
1. Vào màn từ StreakChip + header/back — PASS (streak_chip.dart:79; sub_screen_header.dart:70).
2. Số hoa = mốc vượt 3 nguồn, monotonic, dùng `longestStreak` — PASS (love_tree_service.dart:91-108). Mốc: ngày 30/100/200/365/520/730/1000/1314; streak 3/7/30/100/365; ảnh 1/10/25/50/100.
3. Stage 0/1-2/3-5/6-9/≥10 — PASS (service.dart:112-118).
4. Vị trí hoa ổn định (golden-angle 137.5° + sqrt + jitter Knuth-hash theo index, KHÔNG Random/DateTime.now) — PASS (screen.dart:393-423).
5. Nhuỵ đúng loại (ngày=heart/rose, streak=flash/cam-hồng, ảnh=gallery/lavender) — PASS (service.dart:145-180).
6. Animation nở + banner + lastSeen postFrame, chống re-fire — PASS logic (screen.dart:62-92, 182-188).
7. reduceMotion tắt sạch (animate/confetti gate, banner tĩnh, lastSeen vẫn ghi) — PASS (screen.dart:188, 960).
8. Badge entry mất sau khi xem — PASS (streak_chip.dart:167-183 + _commitSeen).
9. States biên (0 hoa/waiting/no-couple/loading/fail-soft) — PASS (screen.dart:143-170).
10. Cùng vun đắp (3 InkTile, v1 pop về Home) + Cột mốc (đã nở + mốc kế "còn N" clamp≥1) — PASS.
11. Token brand (dawnBlush, ContentCard r24, Quicksand, cây/hoa 100% CustomPaint, KHÔNG asset) — PASS.
12. i18n vi=en 31 key, không hardcode, `{count}` int đúng — PASS.

### Bug — KHÔNG có critical/major
An toàn: không chia-0, mounted check sau await, dispose đủ (confetti/controller/timer), box app_settings <String> mở trước runApp → readLastSeen không ném.

### Minor (không chặn ship)
- [minor] `Future.delayed` _LoveFlower không cancel-able nhưng có mounted guard → không leak.
- [minor] 2 ARB key thừa: `loveTreeFlowerCountZero`, `loveTreeMilestoneAllDone` (dead copy, giữ cho v-sau).

### Lệch spec — chấp nhận
- Icon IconsaxPlus thay Lucide (nhất quán app); heart=IconsaxPlusBold.heart.
- Canopy anchor hoa theo stage thật (cải tiến).

### [CẦN TEST runtime — 1 thiết bị]
R1 animation nở mượt + đúng tập bông mới · R2 confetti emit canopy không bị clip · R3 stage đông hoa (6-18) nhuỵ không chồng che · R4 thoát trước postFrame → animate lại (hiếm) · R5 badge StreakChip mất sau pop về Home · R6 thẩm mỹ 5 stage + glow/gradient trên GPU thật.

### Kết luận: PASS code-level — SHIP được. Smoke-test runtime R1-R6 trước khi gộp release.

## [2026-06-18] [Tester] Nghiệm thu Love Tree v2 (code-level, read-only) — PASS-with-runtime-caveats

**Verdict: PASS-with-runtime-caveats.** `fvm flutter analyze` 0 issue (Lead tự chạy lại: 0). i18n 19/19 key v2 đủ en+vi (52=52 loveTree keys). `love_tree_service.dart` unchanged vs HEAD → milestone math v1 INTACT.

### AC #1–#8: TẤT CẢ PASS (4/5/7 = PASS code-level, cần smoke-test runtime cho visual/animation/share)
1 Bấm bông nở→sheet đúng kind+dòng-ngày — PASS (`love_tree_screen.dart:79-108`, `moment_sheet.dart:278-304`)
2 CTA→Gallery deep-link đúng ảnh — PASS (`moment_sheet.dart:372-422` + router fields)
3 Bông chưa nở→hint+CTA không lỗi — PASS (`:1148-1153`)
4 Trời 4 khung giờ + đêm sao/đom-đóm — PASS code-level (`SkyBackdropPainter:2208`, `_paintFireflies:2392`) [CẦN runtime]
5 Mùa 4 mùa + cánh/lá rơi — PASS code-level (`_paintSeasonTint:1971`, `_paintFalling:2430`) [CẦN runtime]
6 Reduce Motion→0 động, đẹp tĩnh — PASS (`:405,1478,1534,390`; `_AmbientParticles:2346`)
7 Khoe cây→PNG 4:5 share — PASS code-level (`_shareTree:478`, `_LoveTreeShareCard:2508`) [CẦN runtime]
8 analyze sạch + i18n vi+en — PASS

### 8 rủi ro bắt buộc — TẤT CẢ PASS [VERIFIED]
1 Guard photo `len<value`→null, không OOR (`:68-75`,`moment_sheet.dart:293,372`) · 2 Index `[len-value]` off-by-one OK (sort mới→cũ) · 3 Deep-link pop sheet+LoveTree, không pushNamed('/home') (`moment_sheet.dart:438-442`) · 4 Reduce Motion tắt đủ động giữ tĩnh, không sót controller · 5 Share im lặng+double-tap guard+sharePositionOrigin (`:479-552`) · 6 Milestone math KHÔNG đổi (git diff rỗng) · 7 i18n đủ en+vi không hardcode VN · 8 streak không đọc ngày (`:94-95`)

### Minor (không chặn release)
- `_ambient` controller vẫn repeat() ngầm nếu bật Reduce Motion OS GIỮA lúc đang xem màn (1 controller, AnimatedBuilder đã unsubscribe → CPU không đáng kể). Edge hiếm.
- Bướm (design B.4) không implement — đúng spec "tuỳ chọn", AC không bắt buộc.

### CẦN smoke-test thiết bị (runtime)
1 Trời 4 khung giờ (đổi giờ máy)+đêm sao/đom-đóm · 2 Mùa 4 mùa (đổi tháng) · 3 OS Reduce Motion: 0 động thực tế · 4 Khoe cây (header+banner): share OS thật, PNG 4:5 nét, iPad popover · 5 Deep-link CTA Gallery: pop về Home đúng tab+đúng ảnh, watcher không vỡ · 6 Bloom animation lần đầu + không lặp (lastSeen) · 7 photoCount>ảnh-đã-load: ẩn gọn không crash

## [2026-10-11] [Tester] Nghiệm thu v3 "Chòm sao hôm nay" vòng 1 (code-level, commit 7768dd4) — VERDICT: FAIL

`flutter analyze` (Flutter 3.41.6): No issues found · `flutter test`: 167/167. Repo chưa có test cho `TodayConstellation`. Tester chạy thêm probe nháp ngoài repo (font Quicksand thật, 320–414dp, chữ 100%/130%, vi/en): bảng chân trị `segments` 64/64, `watch()`, Semantics, layout.
Tổng: 0 Chặn · 5 Nên sửa · 7 Nhỏ.

### Lỗi
| # | Mức | Chỗ (file:line) | Kịch bản → hậu quả | Gợi ý sửa |
|---|---|---|---|---|
| 1 | Nên sửa | `lib/screens/love_tree_screen.dart:1803-1817` (`status()` trong `_TodayTasksCard`) | Dòng "<tên> · chưa" là Text trong Row không co giãn, nên không xuống dòng. Probe (việc của mình chưa làm, còn nút "Làm ngay"): 360dp tràn từ tên 14 ký tự ("Phương Anh Thư" +11px); 375pt từ 16 ký tự; 393pt từ 17 ký tự; 412dp với 23 ký tự +26px; 320dp với "Minh Anh" +8px; 360dp chữ 130% với "Minh Anh" +14px. Bản debug hiện sọc vàng-đen, bản release chữ đè lên nút. Tên người ấy không giới hạn độ dài (rules chỉ đòi khác rỗng). | Bọc Text bằng `Flexible` + `maxLines: 1`, `overflow: TextOverflow.ellipsis`. |
| 2 | Nên sửa | `lib/widgets/today_constellation.dart:284-308` (`label()`); sao Tâm trạng ở `:149`, `:154` | Nhãn 2 sao Tâm trạng nằm lòi ra ngoài khung 260px tới 58px mỗi bên, kèm `softWrap:false` + `overflow: visible`. Probe: 360dp (cỡ Android phổ biến) cắt khoảng 7px ở cả hai mép (chữ vẽ từ −6,7 tới 367); 320dp cắt 27px; 375pt chỉ cách mép 0,5px. Chữ 130%: 360dp vừa bị cắt vừa đè lên sao trái (chữ kéo tới x=73, sao sáng chiếm 67–93); 390pt cắt 10px. Tiếng Anh không bị. | Đặt nhãn 2 sao Tâm trạng ngay dưới sao, căn giữa, nằm trong khung 260; bỏ `overflow: visible`. |
| 3 | Nên sửa | `lib/widgets/today_constellation.dart:243-251` (sao), `:559-563` (nút ×), `:757-760` (`ConstellationPill`) | `Semantics(excludeSemantics: true)` không có `onTap`, nên node mất luôn thao tác tap của GestureDetector/InkWell bên trong. Probe: cả 3 node `hasAction(tap) == false`. Gửi `SemanticsAction.tap` vào sao thì panel không mở; chạm tay thì mở. Người dùng TalkBack/VoiceOver khó mở panel và không tới được "Gửi lời quan tâm". Pill Home cũng vậy (còn StreakChip làm lối vào phụ). Repo đã có cách làm đúng ở `home_screen.dart:2050-2057`. | Thêm `onTap:` vào 3 node Semantics, gọi cùng hàm với widget con. |
| 4 | Nên sửa | `lib/main.dart:61-67`; `lib/screens/love_tree_screen.dart:311-315` | Toàn app đặt icon thanh trạng thái màu tối. Màn Cây không có `AnnotatedRegion`, dù từ v3 đỉnh màn LUÔN là navy `#2E2A52`. Giờ, pin, sóng màu tối trên nền tối cho tương phản khoảng 1,6:1 (tính với icon đen). v2 chỉ bị từ 19h đến 5h, v3 bị cả ngày. [Suy luận từ code + tính tương phản] | Bọc màn bằng `AnnotatedRegion<SystemUiOverlayStyle>`: `light` khi chưa cuộn qua trời, `dark` khi `_pastSky`. Màn Giấc ngủ cũng dùng `#2E2A52` (`sleep_screen.dart:411`), nên soát luôn. |
| 5 | Nên sửa | `lib/widgets/today_constellation.dart:110-128`; `lib/providers/daily_question_provider.dart:158-183, 197-214`; `lib/screens/home_screen.dart:1646-1661` | Sao Câu hỏi đọc câu trả lời của `_dateKey` chốt lúc `watchForCouple`. Ngày chỉ đổi khi Home rebuild, mà Home chỉ watch Chat + Inbox. Kịch bản: để màn Cây mở qua 0:00, hoặc để app chạy nền qua đêm không ai nhắn rồi mở lại buổi sáng. Lần rebuild đầu (vd `SleepProvider.onResume`) đưa sao Tâm trạng và Nhắn tin về 0. Riêng 2 sao Câu hỏi, cạnh đỉnh tim và dòng "Bạn ✓" ở "Trả lời câu hỏi hôm nay" vẫn theo hôm qua, nên dễ tưởng đã trả lời. Không có hẹn giờ 0:00, nên trước lần rebuild đó cả trái tim đứng yên. Gốc lỗi kế thừa từ provider (thẻ câu hỏi ở Home cũng không so ngày), nhưng v3 hứa "0:00 làm lại" (D-v3-1). | Trong `watch()`, sao Câu hỏi chỉ sáng khi `dq.dateKey == DailyQuestionService.dateKey(now)`. Thêm Timer tới 0:00 cho section và pill. |
| 6 | Nhỏ | `lib/screens/home_screen.dart:1860-1871`; ghi chú `today_constellation.dart:744-746` | Tiêu đề "Hôm nay của chúng mình" (22px w700) rộng 264px. Đứng cạnh pill 105px, nó chỉ vừa 1 dòng khi màn từ 409dp trở lên. Probe: ở 360/375/390 chữ "mình" rớt xuống dòng 2; tới 411 mới gọn 1 dòng. Kết quả này ngược với ghi chú "vừa ở 390–411pt". iPhone 12–16 (390–402pt) đều bị rớt. | Rút pill còn hình tim + "n/6", hoặc đặt pill xuống dưới tiêu đề. |
| 7 | Nhỏ | `today_constellation.dart:95-108`; `chat_provider.dart:30, 232-233` | Sao Nhắn tin chỉ thấy cửa sổ 50 tin mới nhất. Nếu mở app nguội sau khi người kia nhắn từ 50 tin trở lên kể từ tin cuối hôm nay của mình, sao của mình tắt dù mình đã nhắn. [Suy luận từ code] | Khi tin cũ nhất trong cửa sổ vẫn thuộc hôm nay và còn `hasMore`, truy vấn riêng 1 tin của mình tính từ đầu ngày. |
| 8 | Nhỏ | `love_tree_screen.dart:2005-2006`; `today_constellation.dart:566-568` | Chip "Cột mốc đã nở" cao 36px, nút × của panel rộng 40px. Cả hai dưới mức 44. | Đặt minHeight/width 44. |
| 9 | Nhỏ | `lib/l10n/app_vi.arb:1264`, dùng ở `love_tree_screen.dart:1508` | Khi chưa có hoa, tiêu đề là key cũ "Hai bạn vừa gieo hạt mầm đầu tiên…", nằm ngay trên các câu xưng "chúng mình". | Đổi thành "Chúng mình vừa gieo hạt mầm đầu tiên…". |
| 10 | Nhỏ | `love_tree_screen.dart:3327-3334`, `:283` | Bầu trời vẽ lại mỗi khung hình mà không có `RepaintBoundary`. Vì vậy cả nội dung cuộn (cành hoa, các thẻ, sao có blur) cũng vẽ lại 60 lần/giây. Đồng hồ vẫn chạy cả khi trời đã cuộn khỏi màn. Cách vẽ này có từ v2, không phải hồi quy. | Thêm `RepaintBoundary` quanh CustomPaint trời; tắt ticker khi `_pastSky`. |
| 11 | Nhỏ | `today_constellation.dart:485-487`; `mood_card.dart:38-39` | Gặp khoá tâm trạng lạ (bản app mới hơn thêm mood), `moodLabel` trả chuỗi rỗng, nên panel hiện " · 08:12". | Nếu nhãn rỗng thì chỉ hiện giờ, hoặc dùng `loveTreeStarDone`. |
| 12 | Nhỏ | `today_constellation.dart:61-139`; thư mục `test/` | `segments` và `watch()` là lõi của v3 nhưng repo chưa có test nào. | Đưa bảng chân trị 64 tổ hợp (probe của Tester) vào `test/`. |

### Đã kiểm, đạt
- **Logic "hôm nay"** [code + probe]:
  - Câu hỏi: câu trả lời phải có chữ, chỉ khoảng trắng thì không tính.
  - Tâm trạng: chỉ tính doc có `date` là hôm nay; mood hôm qua thì tắt.
  - Nhắn tin: tính tin có `createdAt` hôm nay theo giờ máy; tin đang gửi tính là vừa xong.
  - Tin chuyển từ love note giữ giờ gốc, nên chỉ love note gửi trong hôm nay mới được tính.
  - Probe cho đúng kỳ vọng: sao Câu hỏi của mình tắt khi chỉ có khoảng trắng, của người ấy sáng. Tâm trạng của mình tắt (của hôm qua), của người ấy sáng. Nhắn tin của mình sáng (tin đang gửi), của người ấy tắt (tin lúc 23:59 hôm qua).
- **`segments`**: 64/64 tổ hợp khớp mô tả. Đỉnh sáng khi cả hai trả lời, đáy sáng khi cả hai nhắn, cạnh sáng khi 2 sao kề nhau của cùng một người cùng sáng. Không có đoạn nào sáng sớm. Cả 8 đoạn chỉ cùng sáng khi đủ 6/6 sao.
- **Điều hướng**:
  - Không có `pushNamed('/home')`. Câu hỏi và Nhắn tin đi qua `NotificationTapRouter` + `maybePop()`; Home consume ngay nên lần sau gán lại cùng giá trị vẫn chạy.
  - Đi trả lời câu hỏi thì về Home tab 0 và cuộn tới thẻ câu hỏi. Đi Chat rồi bấm back thì về Home (`_previousIndex`).
  - Tâm trạng mở sheet ngay trên màn Cây; đóng sheet vẫn ở Cây.
  - "Gửi lời quan tâm" mở CareMessageScreen; back về Cây.
  - Các provider nằm ở `MultiProvider` gốc (`main.dart:278-311`), nên route con đọc được.
- **Vòng đời và hiệu năng rebuild**:
  - `build()` của màn chỉ watch Couple/Streak/Photo. DQ/Mood/Chat/Sleep chỉ được watch trong section, thẻ Việc nhỏ và pill, nên tin nhắn mới không rebuild cả màn.
  - `context.watch` chỉ nằm trong build. `shouldRepaint` của tim và sao đúng.
  - `_ambient` và `_confetti` được dispose. Listener cuộn chỉ `setState` khi vượt ngưỡng.
- **Reduce Motion**: trời tĩnh, đom đóm tĩnh, hoa không lắc, confetti tắt. AnimatedSwitcher và dải mờ thanh trạng thái có thời lượng 0. EntranceReveal bỏ hiệu ứng.
- **Tương phản và vùng chạm**:
  - Chữ trắng (α .72–1) trên nền #2E2A52–#4A3D6B đều đọc rõ. Viền sao chưa thắp đạt khoảng 5,6:1.
  - Mỗi sao là nút 44×44, các vùng chạm không chồng nhau.
  - Nhãn Semantics có dạng "<ai> · <việc> · <trạng thái>", kèm `selected`.
- **UI biên đạt**:
  - Panel "Gửi lời quan tâm" không tràn ở 320dp chữ 130%, kể cả với tên 31 ký tự. Chú thích "Nửa phải: <tên>" cũng không tràn.
  - Tiếng Anh không cắt nhãn và không tràn thẻ (đo ở 375/390).
  - Chưa ghép đôi: màn hiện trạng thái chờ, pill Home ẩn.
  - Chưa có hoa: không coach, không chip, vẫn có "Bông tiếp theo".
  - Đủ 6 sao: tim được tô, có sparkle ở mũi tim, hiện "Trái tim hôm nay đã sáng trọn" (mới kiểm ở code).
- **i18n**:
  - 2 ARB cùng 1035 key. Placeholder của các key `loveTree*`/`homeConstellation*` khớp metadata. File sinh có đủ 1035 getter.
  - 11 key đã xoá không còn chỗ gọi trong `lib/`, `test/`, `functions/`.
  - Không có chữ viết cứng. Copy v3 tự nhiên, xưng "chúng mình", không có "hai đứa".
- **Bảo mật**:
  - Không đụng rules, functions hay collection nào; chỉ đọc các stream có sẵn.
  - Sao Câu hỏi của người ấy sáng trước khi mình trả lời cũng không lộ gì mới, vì thẻ câu hỏi vốn đã có teaser. Thứ duy nhất lộ thêm là giờ người ấy trả lời.
- **Firebase vs local**: nhánh local không có người ấy, couple luôn ở trạng thái chờ. Màn Cây hiện trạng thái chờ, pill ẩn, không lỗi.

### Biết trước, không tính lỗi v3
- Hai máy khác múi giờ: mỗi sao tính "hôm nay" theo một mốc khác nhau.
  - Câu hỏi theo `dateKey` của máy người xem.
  - Tâm trạng theo `date` do máy người ấy ghi.
  - Nhắn tin theo ngày của máy người xem.
  - Vì vậy quanh nửa đêm, nửa phải có thể lệch. Lỗi kế thừa từ DQ/Mood.

### [CẦN TEST runtime]
1. Android 360dp, tiếng Việt: nhãn "Tâm trạng" hai bên có bị cắt không; thử lại với chữ 130%.
2. Tên người ấy 15–23 ký tự: xem thẻ "Việc nhỏ hôm nay" trên iPhone 390pt và Android 360dp (bản release: chữ có đè nút "Làm ngay" không).
3. Đỉnh màn Cây trên iOS và Android: giờ/pin có đọc được trên nền navy không, và sau khi cuộn qua trời thì sao.
4. TalkBack và VoiceOver: nhấn đúp vào một ngôi sao, vào nút ×, vào pill "n/6 sao" ở Home.
5. Qua nửa đêm: để màn Cây mở từ 23:58 tới 00:02. Rồi để app chạy nền qua đêm (không ai nhắn), mở lại buổi sáng và xem sao Câu hỏi cùng thẻ Việc nhỏ.
6. Home trên iPhone 390–402pt: tiêu đề "Hôm nay của chúng mình" có rớt chữ "mình" không.
7. Đủ 6 sao trên máy thật; iOS; bật Reduce Motion trong cài đặt hệ thống.
8. Android tầm trung: bật performance overlay, đo khi đứng yên trên Cây và khi đã cuộn xuống dưới.
9. Hai máy thật: B nhắn tin, đổi tâm trạng, trả lời câu hỏi → nửa phải trên máy A sáng tức thì; thử thêm tin đang gửi lúc offline.

- [2026-10-11] [Dev → Tester] Dev đã vá 11/12 lỗi vòng 1 (#7 ghi nợ; #9 sửa ở ARB), thêm `test/today_constellation_test.dart` (22 test, font Quicksand thật). Chờ Tester vòng 2. Chi tiết: `dev.md` 2026-10-11.

## [2026-10-11] [Tester] Nghiệm thu v3 "Chòm sao hôm nay" vòng 2 (code-level, bản vá 1f70ce3, kiểm trên HEAD 77c2cd9) — VERDICT: PASS

5/5 lỗi Nên sửa của vòng 1 đã vá; riêng #4 mới vá một phần, phần còn hở xếp Nhỏ (#13, #17). Tổng: 0 Chặn · 0 Nên sửa · 7 Nhỏ mới (#13–#19). #7 vẫn là nợ có chủ đích.
`flutter analyze` (3.41.6): No issues found · `flutter test`: 208/208 · `test/today_constellation_test.dart`: 22/22.
Probe nháp ngoài repo, dùng font Quicksand thật: layout 320/360/375/390/412dp × chữ 100/130% (thêm 150/200%), vi/en; Semantics; thanh trạng thái (sheet, pop, vuốt lùi iOS); ticker; cô lập repaint; render PNG.

### Kiểm lỗi vòng 1
| # | Kết luận | Chỗ (HEAD) | Bằng chứng |
|---|---|---|---|
| 1 | Đã vá | `love_tree_screen.dart:1840-1859` | 50 cấu hình: 0 exception. Đuôi "· chưa" luôn còn. Ở chữ lớn còn hở: #15. |
| 2 | Đã vá | `today_constellation.dart:369-408` | Nhãn Tâm trạng luôn nằm trong khung 260, mọi bề rộng, vi/en. Không đè sao sáng. Còn hở: #14. |
| 3 | Đã vá | `today_constellation.dart:339, 666, 875` | Sao, nút × và pill đều có `SemanticsAction.tap`; chạm tay và tap qua trình đọc màn hình đều gọi 1 lần. |
| 4 | Vá một phần | `love_tree_screen.dart:63-69, 256-262, 324-327` | Đỉnh trời sáng, cuộn qua tối, trang che tối, pop về sáng, đóng Cây tối. Còn hở: #13 (sheet), #17 (lúc pop). |
| 5 | Đã vá | `today_constellation.dart:103-163`, `:166-220` | Provider giữ câu trả lời hôm qua → pill và section hiện 0/6. MidnightBuilder hẹn lại, rebuild khi resume, huỷ khi dispose; DST Asia/Beirut đúng. Phần kế thừa: provider chỉ sang ngày khi Home rebuild. |
| 6 | Đã vá | `home_screen.dart:1857-1877` | Pill 72,3×44 căn phải dưới tiêu đề; tiêu đề 1 dòng ở 320–412dp chữ 100%. |
| 7 | Nợ có chủ đích | `today_constellation.dart:118-135` | Cửa sổ 50 tin. |
| 8 | Đã vá | `love_tree_screen.dart:2044`; `today_constellation.dart:670-672` | Chip cao 44; nút × 44×44. |
| 9 | Đã vá | `app_vi.arb:1252` | "Chúng mình vừa gieo hạt mầm đầu tiên…". |
| 10 | Đã vá | `love_tree_screen.dart:546, 3377, 343-347` | Trái tim không vẽ lại theo trời; ticker dừng khi cuộn qua trời. Còn hở (hiếm): #19. |
| 11 | Đã vá | `today_constellation.dart:584-589` | Mood lạ chỉ hiện giờ. |
| 12 | Đã vá | `test/today_constellation_test.dart` | 22/22 pass. |

### Lỗi mới
| # | Mức | Chỗ | Kịch bản → hậu quả | Gợi ý sửa |
|---|---|---|---|---|
| 13 | Nhỏ | `love_tree_screen.dart:324` | Mở sheet (bông hoa, bộ chọn tâm trạng) ở đỉnh Cây: Cây mất `isCurrent` → icon thanh trạng thái chuyển tối trên nền trời navy đã bị phủ đen. | Chỉ coi là "bị che" khi phía trên là trang: `isCurrent \|\| secondaryAnimation?.status == dismissed`. |
| 14 | Nhỏ | `today_constellation.dart:395-407` | Nét viền tim nối sao Tâm trạng xuống sao Nhắn tin cắt ngang nhãn "Tâm trạng" (chữ "g" bên trái, "Tâ" bên phải), rõ khi tim sáng. | Viền chữ bằng màu trời, hoặc dời nhãn. |
| 15 | Nhỏ | `love_tree_screen.dart:1840-1859`, `:1864-1940` | Cột trạng thái chung hàng với nút "Làm ngay": 320dp chữ 130% tên "Bạn" bị ép còn trống; chữ 200% tràn 4–34px. | Đưa trạng thái xuống dưới hoặc cho xuống dòng. |
| 16 | Nhỏ | `love_tree_screen.dart:1840-1859` | Tên và đuôi là 2 Text riêng → trình đọc màn hình dừng 2 lần mỗi người. | Gộp semantics. |
| 17 | Nhỏ | `love_tree_screen.dart:256-262`, `:324` | Lúc pop, icon sáng còn ~464ms trên Home (Android); vuốt lùi iOS giữ nửa chừng: icon sáng trên Home. | Chọn style theo `animation.value`, hoặc chấp nhận. |
| 18 | Nhỏ | `love_tree_screen.dart:1726-1775` | Dòng phụ "Bông tiếp theo": 320dp chữ 130% vỡ chữ giữa từ; en chữ 200% tràn 21px. | Cho chữ "còn N…" co lại hoặc ẩn thanh khi hẹp. |
| 19 | Nhỏ (hiếm) | `love_tree_screen.dart:248-253`, `:293`, `:343-347` | Đổi Reduce Motion lúc đang xem: tắt RM khi đã cuộn qua trời → controller mới `repeat()` dù trời khuất; bật RM ở đỉnh → `_ambient` vẫn chạy. | Chỉ `repeat()` khi `!_pastSky`; dừng khi RM bật. |

### [CẦN TEST runtime]
1. Máy thật tiếng Việt khi tim sáng: nét viền qua chữ "Tâm trạng" (#14).
2. Đỉnh Cây mở bông hoa / bộ chọn tâm trạng: giờ và pin có đọc được không (#13); back, vuốt lùi iOS nửa chừng (#17).
3. 320dp chữ 130%, Android 14 cỡ chữ lớn nhất: thẻ Việc nhỏ (#15), Bông tiếp theo (#18).
4. TalkBack/VoiceOver: sao, nút ×, pill, thẻ Việc nhỏ (#16).
5. Để Cây mở qua 0:00; app chạy nền qua đêm; máy ngủ lâu rồi mở.
6. Bật/tắt Reduce Motion khi đang ở Cây (#19).
7. Android tầm trung, performance overlay.
8. Android 360×640: thanh điều hướng trên nền trời tím.
9. Hai máy thật: B nhắn/đổi tâm trạng/trả lời → nửa phải máy A sáng ngay; sau 0:00 sao Câu hỏi của B.
10. Đủ 6 sao, iOS.

- [2026-10-11] [Dev → Tester] Đã vá #13 (sheet giữ icon sáng), #14 (quầng màu trời quanh nhãn che nét viền), #15 + #16 (dòng trạng thái thành 1 Text tự xuống dòng: không cắt tên, không mất "· chưa", trình đọc đọc 1 câu), #18 ("còn N…" xuống dưới tên), #19 (đồng hồ trời không chạy khi đã cuộn qua hoặc khi bật Reduce Motion). Không làm #17 (lệch dưới nửa giây lúc pop). Probe của Tester chạy lại: S2 "Bạn · chưa" = 1 node/người · S3 sheet → icon sáng · chữ 150%/200% vi/en 360/390dp: 0 lỗi tràn · bật RM ở đỉnh → màn hình đứng yên. analyze 0 · test 216/216.
