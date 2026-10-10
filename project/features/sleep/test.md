# 🧪 Test — Giấc ngủ của chúng mình (sleep)

> Tester sở hữu. Đọc cả `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).
> Agent Tester chỉ đọc được file, nên main session chép nguyên văn kết quả vào đây.

- **Trạng thái test:** FAIL — vòng 1 code-level (2026-10-11): 0 chặn · 6 nên sửa · 10 nhỏ. Dev đã vá S1–S6 và phần lớn lỗi nhỏ (xem `dev.md` 2026-10-11 "vòng 1"), chờ Tester vòng 2.
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
