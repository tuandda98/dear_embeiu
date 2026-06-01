# 🧪 Test — invite-sharing (Phase 1: Copy + Share đồng bộ)

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** PASS (có 1 lưu ý minor cho PO — không chặn)
- **Người/role:** Master Tester
- **Ngày:** 2026-06-01

## Phạm vi test
Cụm nút Copy + Share dùng chung (`InviteActionButtons`) gắn ở 3 nơi hiện mã mời (Setup `_buildInviteCodeCard` / Home banner chờ partner / Profile detail tile), share sheet native song ngữ qua `share_plus`. Trục: logic/state, edge, i18n, regression, cross-platform.

## Test case
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | Cụm Copy+Share hiện ở Setup khi tạo couple solo (`hasInviteCode`) | 2 pill glass có chữ, hàng riêng dưới mã 30px full-width | ✅ [VERIFIED code] |
| 2 | happy | Cụm hiện ở Home banner khi `waiting_partner` (`couple.inviteCode.isNotEmpty`) | 2 pill icon-only + Tooltip, trong Wrap cạnh chip mã | ✅ [VERIFIED code] |
| 3 | happy | Cụm hiện ở Profile tile mã mời khi `isWaitingForPartner` | 2 pill rose sáng, dưới value (`belowValue`) | ✅ [VERIFIED code] |
| 4 | logic | Copy → chép mã + toast `inviteCodeCopiedMsg` (2s) | Clipboard.setData(code) + SnackBar | ✅ [VERIFIED code] |
| 5 | logic | Share → mở sheet với `inviteShareMessage(code)` đúng locale | SharePlus.instance.share(ShareParams(text,...)) | ✅ [VERIFIED code] / sheet thật [CẦN TEST RUNTIME] |
| 6 | state | Home active → mã ẩn (guard `inviteCode.isNotEmpty` + banner chỉ render khi chờ) → cụm tự biến mất | Không nút mồ côi | ✅ [VERIFIED code] |
| 7 | state | Profile active → tile mã ẩn (guard `isWaitingForPartner`) → cụm biến mất | Không nút mồ côi | ✅ [VERIFIED code] |
| 8 | state | Setup active (sửa câu chuyện) → card mã VẪN hiện ("inviteCodeTiedToAccount") kèm Copy+Share | Theo spec lẽ ra ẩn; thực tế hiện (xem LƯU Ý-1) | ⚠️ divergence minor (an toàn) |
| 9 | edge | iPad/macOS share popover cần origin | `sharePositionOrigin` từ RenderBox, null-safe khi chưa hasSize | ✅ [VERIFIED code] / popover thật [CẦN TEST RUNTIME] |
| 10 | edge | Share lỗi (OS-driven, hiếm) | try-catch no-op, không vỡ UI, không toast lỗi | ✅ [VERIFIED code] |
| 11 | edge | Home banner màn hẹp | Wrap(spacing/runSpacing 8) xuống dòng, không overflow | ✅ [VERIFIED code] / màn nhỏ thật [CẦN TEST RUNTIME] |
| 12 | edge | Mã rỗng | Không xảy ra do guard `isNotEmpty`/`trim().isNotEmpty` ở cả 3 nơi | ✅ [VERIFIED code] |
| 13 | i18n | `shareBtn` + `inviteShareMessage` đủ vi+en ở ARB **và** generated Dart | Có ở app_en.arb/app_vi.arb + app_localizations_{en,vi}.dart + abstract | ✅ [VERIFIED] |
| 14 | i18n | Câu mời đúng locale (vi/en), chỉ `{code}` placeholder, emoji 💞 + `\n` không vỡ ICU | gen sinh `$code`, literal emoji/newline | ✅ [VERIFIED đọc generated] |
| 15 | i18n | Đã BỎ dòng "Tải app:"/"Get the app:" (override PO) | Không còn trong ARB + Dart | ✅ [VERIFIED] |
| 16 | i18n | Không hardcode chuỗi | Copy/Share/toast/message đều qua `context.l10n` | ✅ [VERIFIED] |
| 17 | regression | KHÔNG đổi logic join/transaction/rules | Không đụng couple_service/rules | ✅ [VERIFIED] |
| 18 | regression | `_buildDetailTile` thêm `belowValue` optional (default null) → tile ngày/cột mốc không ảnh hưởng | 2 tile kia không truyền → render như cũ | ✅ [VERIFIED code] |
| 19 | regression | Setup card mã 30px full-width vẫn ổn; gỡ nút Copy đơn lẻ cũ + import Clipboard | Không còn Clipboard/copyBtn lẻ + import `flutter/services` trong setup | ✅ [VERIFIED] |
| 20 | cross-platform | Widget thuần Flutter + share_plus, không rẽ nhánh Platform sai | Không `Platform.`/`dart:io` trong widget | ✅ [VERIFIED] |
| 21 | API | Dùng API share_plus KHÔNG deprecated (v11.1.0) | `SharePlus.instance.share(ShareParams)` (line 73), không phải `Share.share` static @Deprecated | ✅ [VERIFIED đọc package] |
| 22 | build | `fvm flutter analyze` sạch | 0 issue | ✅ [VERIFIED] (4 file đụng + full project) |

*(Kết quả: ✅ pass · ❌ fail · ⬜ chưa chạy · ⚠️ lưu ý)*

## Lưu ý cho PO (không phải bug — không chặn release)

### LƯU Ý-1: Setup card vẫn hiện Copy+Share khi couple đã `active` (divergence khỏi design "States")
- **Mức:** minor / UX (KHÔNG phải lỗi bảo mật/logic).
- **File/màn:** `lib/screens/setup_screen.dart:345` (guard `if (hasInviteCode)`) + `:555-565` (`_buildInviteCard`, nhánh `inviteCodeTiedToAccount`) + `:623` (`InviteActionButtons`).
- **Bối cảnh:** design.md mục "States" ghi *active → mã KHÔNG hiện ở cả 3 chỗ → cụm nút không tồn tại*. Đúng với Home (case 6) và Profile (case 7). Nhưng ở **Setup**, card mã render theo `hasInviteCode` (mã gắn-tài-khoản, **vĩnh viễn**), KHÔNG gate theo couple status. Khi vào Setup ở chế độ "Chỉnh sửa câu chuyện" lúc couple đã `active`, card vẫn hiện mã với tiêu đề "inviteCodeTiedToAccount" — và giờ kèm cụm Copy+Share.
- **Đây là hành vi CÓ SẴN của Setup** (card mã luôn hiện ở 3 trạng thái theo mã-tài-khoản); feature chỉ thêm Copy+Share vào card luôn-render đó. Dev gắn `InviteActionButtons` vô điều kiện trong `_buildInviteCard` (không gate `isWaitingForPartner`).
- **An toàn — KHÔNG gây hại:** chia sẻ mã của couple `active` vô hại vì join bị chặn cứng — `couple_service.dart:343` ném `coupleFull`, `:357` yêu cầu `status == 'waiting_partner'`, `:315` `couplePartnerHasNoSpace`. Người thứ 3 nhập mã không join được.
- **PO quyết:** chấp nhận (mã gắn tài khoản, share lại vô hại) HAY siết — chỉ render cụm nút khi `isWaitingForPartner` ở Setup để khớp design. Không chặn Phase 1.

## Cần test runtime (user smoke-test trên thiết bị thật)
1. **Share sheet thật** (iOS + Android): tap Share ở cả 3 nơi → sheet mở, nội dung = câu mời đúng locale đang dùng + mã đúng, emoji 💞 hiển thị, xuống dòng đúng. Đổi app sang EN → câu mời tiếng Anh.
2. **iPad popover:** tap Share trên iPad → sheet bung từ vị trí nút (không crash popover).
3. **Home banner màn nhỏ** (vd iPhone SE): cụm icon-only + chip mã không tràn ngang, Wrap xuống dòng nếu chật.
4. **Toast Copy:** tap Copy ở cả 3 nơi → SnackBar "Đã sao chép mã mời" hiện ~2s; paste ra ngoài đúng mã.
5. **Tooltip icon-only (Home):** long-press/hover pill → tooltip "Sao chép"/"Chia sẻ".

## Nhật ký test
- [2026-06-01] [Tester] Test Phase 1 invite-sharing. Đọc widget `InviteActionButtons` + 3 điểm gắn (Setup/Home/Profile) + l10n ARB & generated Dart + package share_plus v11.1.0. 22 case: 21 ✅ [VERIFIED code/đọc package], 1 ⚠️ minor (Setup card hiện Copy+Share khi active — divergence design nhưng vô hại, đã verify join bị chặn). `fvm flutter analyze` sạch (4 file đụng + full project, 0 issue). API share_plus dùng đúng bản KHÔNG deprecated. i18n đủ vi+en, đã bỏ dòng "Tải app:", chỉ `{code}` placeholder. Không regression join/rules; `belowValue` optional không phá tile khác. **VERDICT: PASS** (gắn 5 case cần smoke-test runtime trên thiết bị thật + 1 lưu ý PO). Nợ kế thừa invite-code enumeration là của coupling, KHÔNG phải bug feature này.
