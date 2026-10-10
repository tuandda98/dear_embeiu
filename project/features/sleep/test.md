# 🧪 Test — Giấc ngủ của chúng mình (sleep)

> Tester sở hữu. Đọc cả `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).
> Agent Tester chỉ đọc được file, nên main session chép nguyên văn kết quả vào đây.

- **Trạng thái test:** FAIL — vòng 3 code-level (2026-10-11): 0 chặn · 1 nên sửa (N8 riêng tư) · 6 nhỏ (N7, N9–N13). Dev đã vá hết (xem `dev.md` "vòng 3"), chờ Tester vòng 4. Vòng 1, 2: đã vá.
- **Người/role:** Master Tester

## Bug report (vòng 1)
| # | Mức | Chỗ | Kịch bản → hậu quả | Gợi ý sửa |
|---|---|---|---|---|
| S1 | Nên sửa | `lib/providers/sleep_provider.dart:485`, `:429-434`; `lib/widgets/sleep/sleep_sheets.dart:274`, `:294` | [Firebase] 1) Tắt mạng. 2) Lần đầu bấm "Bật theo dõi" → "Cấp quyền" (hoặc "Chia sẻ" ở bước 2). Lệnh `await set()` của Firestore không xong khi offline → nút xám mãi, không quét đêm nào cho tới lần resume sau. | Không await lệnh ghi Firestore trong luồng UI (Firestore tự xếp hàng); quét trước |
| S2 | Nên sửa, bắt buộc trước PROD | `functions/index.js:2825-2851` + `deleteCoupleCompletely`; `lib/services/couple_service.dart:691-703` | [Firebase] 1) A bật chia sẻ. 2) A rời couple hoặc xoá tài khoản → `couples/{c}/sleep/A` và `nights/*` nằm lại mãi, A không còn quyền xoá. Xoá cả couple cũng bỏ sót `sleep/`. Trái lời hứa "tắt thì xoá" và nghĩa vụ xoá dữ liệu khi xoá tài khoản (Apple 5.1.1(v), Play); dữ liệu này lấy từ Apple Health. | CF `recursiveDelete(sleep/{uid})` ở nhánh couple còn người, `recursiveDelete(sleep)` khi xoá couple; client tắt chia sẻ trước khi rời. Chạy rules-test, deploy CF |
| S3 | Nên sửa | `lib/utils/sleep_calculator.dart:164-173`; `firestore.rules:619`; `sleep_provider.dart:380-382` | [Android] Để máy yên từ 18:00 tới 14:00 hôm sau (quên máy, tắt máy) → đêm dài 1200 phút (đã chạy thử). Máy mình hiện "20g" trăng tròn, trung bình tháng bị lệch. Rules chặn đêm > 16 giờ, mà fingerprint lại ghi trước khi put → không bao giờ thử lại → người ấy thấy "Chưa có dữ liệu" mãi. | Khối > 16 giờ coi là không có dữ liệu (khớp D0 và rules), thêm test; chỉ ghi fingerprint khi put thành công |
| S4 | Nên sửa | `lib/widgets/sleep/sleep_sheets.dart:743`; `sleep_provider.dart:557-565` | 1) Mở nút sửa của một đêm tự ghi. 2) Không đổi gì, bấm "Lưu" → đêm thành `edited` (giờ còn bị cắt giây) → nhãn "Đã sửa" hiện cho người ấy, không gỡ được, lần quét sau cũng không cập nhật đêm đó nữa. | Tắt nút Lưu khi giờ ngủ và giờ dậy chưa đổi (so theo phút) |
| S5 | Nên sửa | `sleep_provider.dart:176-183`, `:360`, listener `:213-220` | [Firebase, đang chia sẻ] Mở app lạnh khi cache chưa có doc hồ sơ (cài lại, xoá cache), hoặc HealthKit trả kết quả nhanh. `refresh()` chạy xong trước khi hồ sơ về → `_syncRecent` thấy `myShare=false` nên bỏ qua; listener hồ sơ không gọi sync lại → đêm qua chỉ nằm trên máy mình tới lần resume sau. [CẦN TEST runtime] | Trong listener, khi `share==true` thì gọi `_syncRecent()` |
| S6 | Nên sửa (thuật toán theo spec, PO quyết) | `sleep_calculator.dart:157-163`, `:230-235` | Đã chạy thử 2 ca. (a) Máy để yên 18:00–22:30, đêm 00:30–07:00 có 1 lần cầm máy 6 phút → "đêm" thành 18:00 → 22:30. (b) Health có 1 mẫu "ngủ" 20 phút buổi tối, cộng "nằm trên giường" 23:00–07:00 → kết quả null. | Ưu tiên khối phủ khoảng 0–5h sáng; Health quay về mẫu "nằm trên giường" khi mẫu "ngủ" cho null hoặc quá ngắn |

**Nhỏ**
- `sleep_sheets.dart:290-296`: `_share` không kiểm `mounted`, không try/catch. Đóng sheet khi đang chờ mạng → lát sau `maybePop()` đóng nhầm màn đang mở. Lỗi ghi → spinner kẹt.
- Công tắc chia sẻ (`sleep_screen.dart:1658`) không chặn bấm liên tiếp. Tắt rồi bật trong khoảng 1 giây thì lệnh xoá có thể tới sau lệnh đẩy lại → người ấy mất các đêm gần nhất, ít nhất tới lần mở app sau.
- `sleep_provider.dart:165-169`: gán `_settings`/`_local` trước rồi mới kiểm `_uid`. Đổi tài khoản giữa lúc đang nạp có thể làm lẫn dữ liệu (rất hiếm).
- `_hydrateFromRemote` (`:391`) đọc toàn bộ đêm mỗi lần mở app lạnh, cộng thêm stream 400 ngày của người ấy → số read tăng khoảng 365/năm/người. Chỉ nên hydrate khi Hive trống.
- Cài lại app khi đang chia sẻ: card quay về A1, không đẩy đêm mới cho tới khi bật lại. `enableTracking` có thể ghi đè màu đã chọn nếu hồ sơ chưa tải xong.
- Người mới ghép vào couple cũ thừa hưởng `share:true` và cả lịch sử (PO quyết).
- Sửa một đêm có giờ dậy trước nửa đêm: `_times` (`sleep_sheets.dart:604-614`) neo giờ dậy vào ngày D → cả đêm dời +24 giờ.
- A11y/UI: link "Ghi tay"/"Mở cài đặt" chỉ cao 36 (< 44) (`sleep_card.dart:544`). Lưới màu tràn ở màn 320dp hoặc chữ 130% (`sleep_screen.dart:1843`). Tiêu đề tiếng Anh "Night of 9 → 10/10" viết cứng kiểu d/M (`sleep_format.dart:79`, lệch D3). Chỗ trống 34 so với nút 44 làm lệch cột thời lượng.
- Thiếu test: chưa có test cho provider (merge, sửa, xoá, sync, hydrate). Calculator chưa có ca > 16 giờ, khối buổi tối, Health lẫn mẫu "ngủ" với "nằm trên giường".
- iOS: `NSHealthShareUsageDescription` chỉ có tiếng Việt. PrivacyInfo và App Privacy trên ASC chưa khai Health (việc của PO).

## Đã kiểm, đạt
- Rules: người ấy chỉ đọc được khi `share==true` và chủ đêm còn trong couple. Người ngoài không đọc, không ghi được. Người ấy không ghi được đêm của mình. `hasOnly` chặn mọi field giờ gốc. Sửa/xoá đêm > 8 ngày bị chặn khi đang chia sẻ. Collection mới, không có wildcard rộng → chỉ thêm, app cũ không ảnh hưởng.
- R1: nhãn hiện ở card (`sleep_card.dart:295`) và chi tiết đêm (`sleep_screen.dart:1363`) cho cả hai người; Semantics ô lịch có "(đã sửa)". R2: doc đêm chỉ có giờ cuối và source. R3: ẩn nút sửa và hiện dòng khoá; provider từ chối ghi ngoài 7 ngày. R4: sheet sửa và sheet ghi tay đều có ghi chú.
- C1: hai máy ra cùng kết quả. Mặc định người bật trước Hồng, người sau Tím. Mỗi người còn ít nhất 5 màu.
- Thuật toán (có chạy thử thêm): kẹp biên 18:00 và 14:00; khoảng ngắt đúng 5 phút vẫn gộp và đếm thức giấc; khối đúng 3 giờ vẫn tính; đêm đang diễn ra; Android bỏ cửa sổ thiếu đầu; giờ trung bình tính theo vòng tròn; tim từ 7 giờ; biên 7 ngày.
- Đồng bộ: ghi cờ thành commit riêng rồi mới đẩy đêm; tắt chia sẻ thì xoá hết; dấu xoá không bị lần quét tạo lại; đêm sửa/ghi tay không bị ghi đè; fingerprint; Hive tách theo uid; `clear()` có ở cả 3 nhánh resolver; nhánh không Firebase vẫn chạy (ẩn phần chia sẻ); lỗi `permission-denied` khi người ấy vừa tắt chia sẻ không hiện báo lỗi.
- UI: đủ state A0–A5, L, M, P, F, D0, K, S. Hiện "9g", không còn "9g 0p". Tiêu đề tháng viết hoa. Chữ không dùng màu người. Có Reduce Motion. 2 file ARB đủ key, placeholder khớp. Bộ chọn giờ hết chữ viết cứng.
- Native: Android < 9 chỉ cho ghi tay. `queryEvents` chạy trên thread riêng rồi trả về main thread. iOS trả kết quả về main thread. Kênh đăng ký qua registrar, chạy được dưới UIScene.

## Cần test tay [CẦN TEST runtime]
1. iPhone thật: popup quyền Sức khoẻ. Có dữ liệu Watch hoặc Lịch ngủ → đêm ra đúng. Từ chối hoặc không có dữ liệu → hiện banner M, nguồn "Ghi tay". Nút mở app Sức khoẻ chạy.
2. `flutter build ipa --release`: App ID (cả `.dev`) đã có HealthKit capability.
3. Badge icon iOS: kênh `app/badge` giờ mới thật sự chạy. Kiểm số badge khớp chuông và về 0 khi đọc hết.
4. Hai máy cùng couple (Android + iPhone): bật chia sẻ → máy kia thấy đúng màu, đúng nhãn, ô > 7 ngày bị khoá. Tắt → máy kia chuyển ngay sang "Chưa chia sẻ". Hai người cùng đổi sang màu trùng một lúc.
5. Mở app lạnh buổi sáng khi đang chia sẻ → máy kia thấy "Đêm qua" ngay (S5).
6. Offline: bật theo dõi lần đầu, bật/tắt chia sẻ, sửa đêm → có mạng lại → dữ liệu Firestore đúng (S1).
7. Thu hồi Usage access → card hiện A2 và màn có banner. Cấp lại → app tự quét.
8. Màn 360dp và 320dp, chữ 130%, tiếng Anh, tên người ấy dài.

## Nhật ký test
- [2026-10-11] [Tester] Vòng 1 code-level: analyze 0 · test 163/163 · rules-test 330 · chạy thử 7 ca biên của calculator. FAIL: 0 chặn, 6 nên sửa (S1–S6), 10 nhỏ.

## Vòng 2 — 2026-10-11 (code-level, HEAD 7768dd4; code sleep giống hệt 0e00ae0)

- **Trạng thái test:** FAIL vòng 2: 0 chặn · 2 nên sửa (S2 còn nhánh rời couple · N1 hồi quy) · 5 nhỏ mới (N2–N6).

### Lỗi vòng 1 sau khi vá
| # | Kết luận | Bằng chứng (file:line) | Ghi chú |
|---|---|---|---|
| S1 | Đã vá | `sleep_provider.dart:463-476`, `:521`, `:547-549`; `sleep_sheets.dart:271-296` | Bật theo dõi, chia sẻ, đổi màu, sửa đêm không còn chờ Firestore. [CẦN TEST runtime offline] |
| S2 | Vá một phần | `functions/index.js:2838-2848`, `:2923-2932`; `couple_service.dart:672-689` so với `:690-720` | Xoá tài khoản và trường hợp người cuối rời đi đã xoá `sleep/`. Còn khi A rời couple mà B ở lại thì client tự ghi chuyển trạng thái, KHÔNG gọi `leaveCoupleCleanup`. Kết quả: `sleep/A` và `nights/*` vẫn nằm lại. `dev.md` ghi hàm dùng chung cho `leaveCoupleCleanup`, nhưng client chỉ gọi hàm đó ở nhánh còn một người. Rules vẫn chặn đọc, nên đây là dữ liệu sót lại chứ không lộ ra ngoài. Nên sửa trước PROD, ví dụ thêm `recursiveDelete(sleep/{uid người rời})` vào trigger `notifyPartnerLeft`. |
| S3 | Đã vá | `sleep_calculator.dart:166-171`; test `:142-145`; `firestore.rules:619` | Khối dài hơn 16 giờ bị bỏ. Khối đúng 16g00 vẫn được nhận, khớp rules `<=`. Việc chuyển fingerprint ra sau lúc ghi xong lại gây ra N1. Máy bỏ quên vẫn lọt ở N3. |
| S4 | Đã vá | `sleep_sheets.dart:578-601`, `:754` | So bằng `TimeOfDay` (giờ + phút), giá trị ban đầu đã bỏ giây. Đổi giờ rồi đổi lại thì nút Lưu vẫn xám. |
| S5 | Đã vá | `sleep_provider.dart:227-239` | Mỗi snapshot có `share == true` đều gọi `_syncRecent`, không đọc thêm doc nào. [CẦN TEST 2 máy] |
| S6 | Đã vá 2 ca vòng 1, kèm tác dụng phụ N2 (PO quyết) | `sleep_calculator.dart:172-187`, `:251-264`; test `:147-183` | Ca (a) giờ ra 03:06–07:00, tức 3g54p. Vẫn hụt 2g30p, nhưng đó là do khoảng gộp 5 phút, đúng spec. |
| Nhỏ 1: `_share` thiếu mounted/try | Đã vá (gián tiếp) | `sleep_provider.dart:463-476`; `sleep_sheets.dart:290-296` | `setShare` trả về ngay và không ném lỗi, nên sheet đóng luôn. |
| Nhỏ 2: bấm công tắc liên tiếp | Đã vá | `sleep_provider.dart:52`, `:473-475` | Các lệnh chạy tuần tự, dữ liệu cuối cùng đúng. Công tắc vẫn còn nhảy ngược (N4). |
| Nhỏ 3: đổi tài khoản lúc đang nạp | Đã vá | `sleep_provider.dart:170-183` | Sau `loadFingerprints` (`:188`) chưa kiểm lại. Lỗ này chỉ có trên lý thuyết. |
| Nhỏ 4: đọc nhiều | Vá một phần | `:234`; `:28`, `:274-278` | Hydrate giờ chỉ chạy khi máy chưa có fingerprint. Stream của người ấy vẫn lấy 400 ngày, nên mỗi lần mở app lạnh sau hơn 30 phút có thể đọc lại tới khoảng 365 doc (sau 1 năm). |
| Nhỏ 5: cài lại app | Chưa vá (A1) · Vá một phần (màu) | `:225`, `:547` | Card vẫn về A1 (dev ghi nợ). Phần màu: online đã an toàn. Offline với cache trống thì snapshot "không có doc" vẫn đặt `_myProfileLoaded = true`, nên màu đã chọn bị ghi đè. [suy luận theo SDK, CẦN TEST] |
| Nhỏ 6: người mới thừa hưởng lịch sử | Để PO quyết | — | Chưa đổi. |
| Nhỏ 7: giờ dậy trước nửa đêm | Đã vá | `sleep_sheets.dart:613-625` | Chạy thử: dậy 22:30 được neo về tối hôm trước. Đêm 01/11 dậy 19:00 ra 31/10 19:00. |
| Nhỏ 8: A11y/UI | Đã vá | `sleep_card.dart:544`; `sleep_screen.dart:1845`, `:1347`; `sleep_format.dart:82` | `DateFormat.Md` ra vi "3/11", en "11/3". |
| Nhỏ 9: thiếu test | Vá một phần | `test/sleep_calculator_test.dart:141-183` | Calculator có thêm 4 test. Provider vẫn chưa có test nào. |
| Nhỏ 10: iOS Health | Chưa vá / việc của PO | `ios/Runner/Info.plist:13-14`; `PrivacyInfo.xcprivacy` | Mô tả quyền chỉ có tiếng Việt, không có `InfoPlist.strings`. PrivacyInfo chưa khai báo Health. |

### Lỗi mới
| # | Mức | Chỗ | Kịch bản → hậu quả | Gợi ý sửa |
|---|---|---|---|---|
| N1 | Nên sửa (hồi quy) | `sleep_provider.dart:394-412`, `:638-647` | [Firebase, đang chia sẻ] 1) Mạng yếu hoặc offline. 2) Mở app, app quét ra đêm D, lệnh đẩy D bị treo. 3) Bạn xoá D. `_syncRecent` chỉ gửi lệnh xoá khi `_fingerprints` có D, mà giờ fingerprint chỉ ghi sau khi đẩy xong, nên lệnh xoá không được gửi. 4) App bị tắt trước khi có mạng lại. Lệnh đẩy đã nằm trong hàng đợi của Firestore nên vẫn lên server, còn lệnh xoá thì không bao giờ được gửi. Người ấy thấy đêm bạn đã xoá cho tới khi bạn tắt chia sẻ. Nếu app vẫn sống thì đêm đó hiện tới lần đồng bộ sau. Bản vòng 1 không bị lỗi này. | Trước khi đẩy, ghi dấu "đang đẩy" vào `_fingerprints` (lưu cả Hive). Đẩy xong thì thay bằng fingerprint thật. Nhánh xoá giữ nguyên `containsKey`. Cách này vẫn thử lại được khi lỗi mà không mất lệnh xoá. |
| N2 | Nhỏ (PO quyết) | `sleep_calculator.dart:172-187`, `:263-264` | Chạy thử 3 ca. (1) Làm ca đêm, điện thoại để trong tủ đồ 23:00–03:30, ngủ 07:00–14:00: app ra 23:00–03:30. Trước bản vá app ra đúng 07:00–14:00. (2) Để máy yên 18:30–00:15, cầm máy 25 phút, ngủ 00:40–06:00: app ra 18:30–00:15, vì chỉ cần chạm qua 0h 15 phút là được tính "phủ 0–5h". (3) Health: Watch ghi ngủ 19:00–22:10, ban đêm chỉ có "nằm trên giường" 23:00–07:00: app ra 19:00–22:10. | Cách A: chỉ hạ hạng khối KẾT THÚC trước 0h, phần còn lại vẫn chọn khối dài nhất. Cách này giữ đúng ca vòng 1 và sửa lại ca (1), nhưng ca (2) vẫn sai. Cách B: chọn khối phủ 0–5h nhiều nhất. Cách này sửa được (2) nhưng (1) sai. Health: nếu mẫu "ngủ" không phủ 0–5h mà mẫu "nằm trên giường" có thì lấy "nằm trên giường". |
| N3 | Nhỏ | `sleep_calculator.dart:128-134`, `:166-168` | Trần 16 giờ được đo sau khi đã cắt theo cửa sổ 18:00–14:00. (1) Máy hết pin lúc 16:00, sạc lại lúc 09:30: app ra đêm 18:00–09:30, tức 15g30p, trăng tròn. (2) Máy nằm yên 18:00–10:30, cầm 10 phút, rồi lại nằm yên tới 15:00: khối 16g30p bị bỏ, app lấy 10:40–14:00 (3g20p) làm "đêm" và đẩy cho người ấy. | So trần 16 giờ trên khoảng tắt màn hình gốc, trước khi cắt. Nếu có khoảng dài hơn 16 giờ chạm vào cửa sổ thì coi cả đêm là không có dữ liệu. |
| N4 | Nhỏ | `sleep_provider.dart:223-226`, `:470` | Bấm tắt rồi bật lại trong khoảng 1 giây. Lệnh sau phải chờ server xác nhận lệnh trước. Trong lúc chờ, snapshot của lệnh trước về (`updatedAt` serverTimestamp đổi giá trị) và ghi đè `_myProfile`. Công tắc nhảy về giá trị cũ 1–3 giây rồi mới đúng. Nếu offline thì nó nhảy lúc có mạng lại. Dữ liệu cuối cùng vẫn đúng. [CẦN TEST runtime] | Khi còn lệnh chia sẻ đang chờ thì giữ giá trị `share` lạc quan, không lấy từ snapshot. |
| N5 | Nhỏ | `sleep_provider.dart:478-497`, `:385-391` | Lệnh đẩy toàn bộ lịch sử chỉ chạy sau khi server xác nhận cờ, và chỉ tồn tại trong bộ nhớ. Bấm Chia sẻ (sheet đóng ngay), rồi app bị tắt trước khi có mạng. Lần mở sau chỉ có `_syncRecent` đẩy 7 ngày gần nhất. Các đêm cũ hơn không bao giờ được đẩy lên, nên lịch của người ấy thiếu các tháng trước. | Cho `_syncRecent` đẩy cả các đêm cũ CHƯA có fingerprint (rules cho phép tạo đêm cũ). Chỉ bỏ qua các đêm cũ đã có fingerprint. |
| N6 | Nhỏ | `app_vi.arb:2631`, `:2635`; `app_en.arb:3237`, `:3241` | Sheet "App tính thế nào?" vẫn nói app lấy khoảng "lâu nhất/dài nhất". Thuật toán giờ ưu tiên khối phủ 0–5h và bỏ khối dài hơn 16 giờ. Ví dụ ở ca S6a, khối dài nhất 18:00–22:30 bị bỏ qua. Màn hình minh bạch đang mô tả sai cách tính. | Viết lại cho khớp, ví dụ "…khoảng nằm yên dài nhất quanh nửa đêm (0–5h sáng), tối đa 16 tiếng…". |

### Các điểm hồi quy được hỏi
- Hàng đợi `_shareOps`: lỗi giữa chuỗi không làm kẹt các lệnh sau, vì `catchError` nằm bên trong `then` (`:474`). Một lệnh chưa được xác nhận (offline) sẽ giữ cả chuỗi, đúng ý thiết kế. Riêng `clear()` (`:196-210`) không gán lại `_shareOps`. Lệnh treo của tài khoản cũ có thể chặn lệnh chia sẻ của tài khoản đăng nhập sau trong cùng phiên app. [suy luận, rất hiếm]
- `catchError` có nuốt lỗi: lỗi chia sẻ không hiện thông báo nào. Nếu ghi cờ bị từ chối thì snapshot tự kéo công tắc về, chấp nhận được. Nếu xoá từng doc trong `deleteAllNights` lỗi (`sleep_service.dart:283`) thì im lặng.
- `Future<T>.catchError`: cả 5 chỗ `catchError` (tính cả `_quiet`) đều gọi trên `Future<void>`, nên không có lỗi kiểu lúc chạy.
- Offline: không có vòng lặp vô hạn. Ghi đêm không kích hoạt listener hồ sơ, và `_markSynced` không gọi notify. Có đẩy trùng: mỗi lần resume, snapshot hay lưu đêm lại xếp thêm một lệnh ghi cho các đêm chưa được xác nhận. Số lệnh có giới hạn, chỉ tốn lượt ghi.
- Listener hồ sơ: `_syncRecent` chạy ở mỗi snapshot có `share == true` nhưng không đọc doc nào. Hydrate chạy nhiều nhất một lần cho mỗi couple trong một phiên, và chỉ khi máy chưa có fingerprint.

### Ca biên đã chạy (17 ca, script tạm ngoài repo)
- 16g00 được nhận (khớp rules). 16g01 ra null. 18:00→14:00 ra null.
- Hoà điểm giữa hai khối trong 0–5h: lấy khối sau. Khối buổi tối kết thúc đúng 00:00 không được tính là phủ 0–5h.
- Health: mẫu "ngủ" 2g30p + "nằm trên giường" 8g thì lấy 8g. Mẫu "ngủ" dài 16g30p bị bỏ, lấy "nằm trên giường".
- Sheet sửa: dậy 22:30 → tối hôm trước. 17:59 → cùng ngày. 18:00 → tối hôm trước. 18:00→10:00 = 16g, hợp lệ. 23:00→23:00 = 24g, bị chặn.
- Các ca ra sai: xem N2, N3.

### Số liệu
- `flutter analyze` (Flutter 3.41.6): No issues found.
- `flutter test`: 167/167, trong đó calculator 26.
- `scripts/test-firebase-rules.sh`: 330 passing, exit 0. Script chỉ kiểm cú pháp `functions/index.js`, nên `recursiveDelete` mới thêm chưa có test tự động nào.

### Cần test tay [CẦN TEST runtime]
1. Offline (S1, N1, N5): bật chế độ máy bay → Bật theo dõi → Cấp quyền → Chia sẻ (sheet phải đóng ngay). Bật/tắt chia sẻ 3 lần. Sửa một đêm, xoá đêm vừa quét. Vuốt tắt app. Có mạng rồi mở lại, kiểm Firestore: cờ đúng với lần bấm cuối, đêm đã xoá không còn, có đủ các đêm cũ hơn 7 ngày.
2. Online, bấm tắt rồi bật trong 1 giây: công tắc có nhảy ngược không (N4).
3. Hai máy (S5): A đang chia sẻ, mở app lạnh buổi sáng. B phải thấy "Đêm qua" sau vài giây.
4. Trên DEV (S2): A chia sẻ rồi xoá tài khoản → `couples/{c}/sleep/A` phải mất. A rời couple khi B ở lại → hiện dữ liệu còn nguyên (lỗi đang mở). Người cuối rời → cả `sleep/` phải mất. Vết deploy CF DEV `20261010T182234Z` ghi exit "?", cần xác nhận function đã thật sự lên.
5. Android thật: đêm có lần cầm máy quá 5 phút; để máy yên cả buổi tối; máy hết pin qua đêm; làm ca đêm.
6. iPhone thật: popup quyền Sức khoẻ; có Watch và chỉ có iPhone; không có dữ liệu thì hiện banner M. Build IPA có HealthKit capability. Badge iOS.
7. Sheet sửa: mở đêm tự ghi thì Lưu xám; đổi 1 phút thì Lưu sáng; đổi lại thì xám.
8. Màn 320dp, chữ 130% và 200%: lưới màu không tràn. Tiêu đề đêm bằng tiếng Anh.

### Nhật ký
- [2026-10-11] [Tester] Vòng 2 code-level: analyze 0 · test 167/167 · rules-test 330 · chạy thử 17 ca biên. FAIL: 0 chặn, 2 nên sửa (S2 còn nhánh rời couple, N1 hồi quy), 5 nhỏ mới (N2–N6). S1/S3/S4/S5 đạt.

## Vòng 3 — 2026-10-11 (code-level, HEAD 77c2cd9; code sleep giống 521245b, backend giống f62e907)

- **Trạng thái test:** FAIL vòng 3: 0 chặn · 1 nên sửa (N8, riêng tư) · 6 nhỏ (N7, N9–N13). 9/9 lỗi vòng 2 đã vá ở code, S2 còn chờ test trên DEV.

### Lỗi vòng 2 sau khi vá
| # | Kết luận | Bằng chứng (file:line) | Ghi chú |
|---|---|---|---|
| S2 (A rời, B ở lại) | Đã vá ở code, chờ test DEV | `functions/index.js:411-447` (`notifyPartnerLeft`), `:2915-2922`, `:2997-3006` | Trigger chạy ở mọi lần couple từ 2 người còn 1, kể cả xoá tài khoản và app bản cũ. Luật `firestore.rules:290-303` bắt mọi lần rời phải đi qua chuyển trạng thái này. DEV: source `notifyPartnerLeft` lên lúc 19:02:36Z, `retry:false`. Còn sót: nhánh dự phòng khi callable `leaveCoupleCleanup` lỗi (`couple_service.dart:684-690`, `:752-778`) không xoá `sleep/`, cùng loại với notes/dailyAnswers đã ghi nợ. |
| N1 | Đã vá | `sleep_provider.dart:414-426`, `:446-482`; `test/sleep_sync_test.dart` ca 2 | Harness H3: đêm đang đẩy dở mà xoá thì lệnh xoá vẫn được gửi. Còn một khe vài mili-giây (N12). |
| N2 | Đã vá theo quyết định của user | `sleep_calculator.dart:176-194`, `:267-274`, `:279-281`; test `:185-244` | 3 ca của vòng 2 giờ ra đúng. Ca dev tự ghi nhận vẫn sai như cũ. Thêm một ca cùng họ: N11. |
| N3 | Đã vá, có tác dụng phụ | `sleep_calculator.dart:129-138` | Hết pin 16:00→09:30 và máy bỏ quên 18:00→10:30 đều ra null. Nhưng khoảng > 16 tiếng chỉ cần chạm mép 0–5h là mất luôn đêm thật (N10). |
| N4 | Đã vá | `sleep_provider.dart:539-555`, `:244-247` | Bấm liên tiếp thì công tắc giữ đúng lần bấm cuối. Bị từ chối: lệch một khoảnh khắc rồi tự đúng (H2). |
| N5 | Đã vá | `sleep_provider.dart:456-459` | Ngoại lệ: máy còn giữ fingerprint cũ sau khi CF đã xoá đêm trên server (N9b). |
| N6 | Đã vá | `app_vi.arb:2619`, `:2623`; `app_en.arb:3221`, `:3225` | Khớp thuật toán trên cả 2 nền tảng. |
| `clear()` không reset `_shareOps` | Đã vá | `sleep_provider.dart:225-227` | H5: lệnh treo của tài khoản cũ không chặn tài khoản sau. |
| Cache rỗng ghi đè màu | Đã vá, sinh hồi quy N7 | `sleep_service.dart:208-210` | |

### Lỗi mới
| # | Mức | Chỗ | Kịch bản → hậu quả | Gợi ý sửa |
|---|---|---|---|---|
| N8 | Nên sửa (riêng tư) | `sleep_provider.dart:543-555`, `:558-593` | Bấm bật chia sẻ khi offline (online cũng bị nếu đang đẩy vài trăm đêm), đổi ý bấm tắt. Lệnh tắt chỉ nằm trong chuỗi `_shareOps` ở bộ nhớ, xếp sau lệnh bật (harness: `setProfile(share:false)` chưa hề được gọi). Vuốt tắt app → lệnh bật đã vào hàng đợi lưu trên máy của Firestore nên vẫn lên server → mở lại: chia sẻ bật, đẩy toàn bộ đêm, người ấy thấy hết. | Gọi `setProfile` ngay trong `setShare`, Firestore tự giữ thứ tự ghi. Chỉ xếp tuần tự phần đẩy/xoá đêm. |
| N7 | Nhỏ (hồi quy) | `sleep_service.dart:208-210` | Chưa có hồ sơ: snapshot "không có doc" từ cache bị lọc, server xác nhận chỉ là thay đổi metadata nên SDK không phát lại (đọc mã SDK iOS 12.15.0). `_myProfileLoaded` false cả phiên → `enableTracking` không ghi màu, mất luật "người sau Tím". | `snapshots(includeMetadataChanges: true)` và giữ bộ lọc. |
| N9 | Nhỏ | `sleep_provider.dart:242-263`, `:567-574` | (a) Tắt chia sẻ rồi app bị tắt trước khi xoá xong: đêm nằm lại server, trái lời hứa "tắt thì xoá". (b) Người ấy rời đi, CF xoá đêm nhưng máy người ở lại giữ fingerprint → bật lại offline, app bị tắt, mở lại: không đêm nào được đẩy (H7). | Trong listener: server `share == false`, không có lệnh đang chờ, fingerprint còn → `deleteAllNights` rồi xoá fingerprint. |
| N10 | Nhỏ (PO quyết) | `sleep_calculator.dart:132-136` | Hết pin 08:00, sạc 00:30, ngủ 00:45–07:30 → null. Ngủ 23:00–04:30, để máy ở nhà 04:59→21:01 (16g02p) → null. Hai đêm thật đều mất vì khoảng > 16 tiếng chỉ chạm mép 0–5h. | Chỉ bỏ cả đêm khi khoảng > 16 tiếng chứa mốc lõi (vd 02:30). |
| N11 | Nhỏ (PO quyết) | `sleep_calculator.dart:156-172` | Máy hết pin 15:00, mở lại 23:20, xem 3 phút, ngủ 23:23–07:00 → app ghi 18:00–07:00 = 13 tiếng. | Khoảng tắt màn hình bắt đầu trước 18:00 không gộp vào khối sau qua lần cầm máy ≤ 5 phút. |
| N12 | Nhỏ (lý thuyết) | `sleep_provider.dart:426-438` | Bấm xoá đúng lúc `_markPushing` đang ghi Hive: lệnh xoá đi trước lệnh đẩy (H4), đêm lên lại server. | Sau `await _markPushing`, bỏ các đêm đã thành dấu xoá. |
| N13 | Nhỏ (hiếm) | `sleep_provider.dart:194-203` | Cùng tài khoản chuyển couple không qua `clear()`: `_myProfile`/`_pendingShare` của couple cũ còn nguyên, app đẩy đêm sang couple mới (rules từ chối). | Khi `!sameCouple` thì reset các trường này. |

### Ghi chú khác của Tester
- `planSync`/dấu `pushing` đúng 4 nhánh; khe lý thuyết: app bị tắt giữa lúc ghi `pushing` và lúc `put` vào hàng đợi → đêm cũ đó không bao giờ lên. Đêm gần đây bị đẩy trùng khi listener và `_applyShare` chạy cùng lúc (chỉ tốn lượt ghi).
- `whenComplete` trên lệnh xoá đúng ý; lệch khi lệnh xoá nằm offline hơn 1 ngày (đêm quá 8 ngày bị rules giữ).
- CF `notifyPartnerLeft`: thứ tự đúng, idempotent; nếu `set(share:false)` lỗi thì không ai thử lại (hiếm) — có thể tách sang trigger riêng bật retry.
- Mốc 01:00: khối kết thúc đúng 01:00 coi là buổi tối (lệch 1 thời điểm, gần như không gặp).

### Số liệu
- `flutter analyze` (HEAD 77c2cd9): No issues found · `flutter test`: 208/208 (giấc ngủ 36) · `scripts/test-firebase-rules.sh`: 330 passing.
- DEV `functions:list`: `notifyPartnerLeft` 19:02:36Z, `leaveCoupleCleanup` 18:22:23Z (trả lời câu hỏi "exit ?" của vòng 2), `deleteAccount` 19:20:27Z.

### Cần test tay [CẦN TEST runtime]
1. DEV, 2 máy (S2): A rời → `sleep/A` mất, `sleep/B.share == false`, `nights` rỗng, công tắc B về tắt; lặp lại với xoá tài khoản và người cuối rời.
2. Người mới C ghép vào, B bật lại → đêm của B lên lại đủ.
3. N8: máy bay → bật rồi tắt chia sẻ → vuốt tắt app → có mạng, mở lại: `share == false`.
4. N1/N5: offline xoá đêm vừa quét, bật chia sẻ, vuốt tắt app → mở lại: đêm đã xoá không còn, đêm cũ đủ.
5. N7: chưa có hồ sơ, bật theo dõi không chia sẻ → `sleep/{uid}` có `color`.
6. Android thật: hết pin chiều rồi sạc lúc đi ngủ (N11); hết pin qua đêm; quên máy cả ngày (N10); ca đêm.
7. iPhone thật: popup Sức khoẻ, có/không Watch, banner M; IPA có HealthKit; badge iOS.
8. Online bấm công tắc 3 lần nhanh: không nhảy ngược.
9. Màn 320dp, chữ 130%/200%, tiếng Anh.

- [2026-10-11] [Tester] Vòng 3 code-level (HEAD 77c2cd9): analyze 0 · test 208/208 · rules-test 330 · 24 ca calculator + 8 ca harness provider. FAIL: 0 chặn, 1 nên sửa (N8), 6 nhỏ (N7, N9–N13).
- [2026-10-11] [Dev → Tester] Đã vá N7–N13 (chi tiết `dev.md` "vòng 3"), thêm `test/sleep_provider_test.dart` (5 test, dựng từ harness của Tester) + 3 test calculator. Đã kiểm trên DEV thật: CF `notifyPartnerLeft` dọn đúng trong 3 giây (couple test). Chờ Tester vòng 4.
