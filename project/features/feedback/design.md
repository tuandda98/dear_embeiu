# 🎨 Design — Đánh giá app · Góp ý · Báo lỗi

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`../../design-system.md`). CHỈ thiết kế, không code.

- **Trạng thái design:** xong
- **Người/role:** Designer
- **Ngày:** 2026-10-29

## Mục tiêu thiết kế
Hỏi sao nhẹ, 1 chạm, không làm phiền. Form góp ý ngắn như màn "Gửi quan tâm" (cùng khung, cùng nút) để dev tái dùng tối đa. Không thêm token mới, không đề xuất bổ sung design system.

## Soát UX (UI UX Pro Max)
Tra `search.py --domain ux` (rating/star, feedback form, error recovery, bottom sheet) + `--stack flutter` (0 kết quả cho "star rating", dùng mặc định theo design system).
- **Forms · Submit Feedback (High):** gửi phải có loading → success/error. → nút có spinner, màn thành công riêng, lỗi inline.
- **Feedback · Error Recovery (Medium):** lỗi phải có đường thoát. → nhãn nút đổi "Thử lại", nội dung + ảnh giữ nguyên.
- **Interaction · Error Feedback (High):** lỗi hiện gần chỗ gây lỗi. → banner lỗi ngay trên nút Gửi, không chỉ SnackBar.
- **Interaction · Focus States (High, modal):** mọi điều khiển trong sheet có focus rõ. → mỗi sao là 1 nút 48x48 có `Semantics`/focus ring mặc định của `InkResponse`.
- **Touch · Haptic (Low):** chỉ 1 `selectionClick` mỗi lần đổi sao và 1 `lightImpact` khi gửi xong, không rung thêm.
- Soát chung thành phần đứng cạnh nhau: nút chính (navy pill h52) + "Để sau" (chữ, h44) trong sheet; chip loại + ô nhập + nút ảnh + nút Gửi trong form. Cùng radius/chiều cao với `care_message_screen.dart`. Không có nút bên thứ ba.

## User flow
```
Settings → "Đánh giá Dear Embeiu" ─┐
Tự mời (mở khoá câu hỏi/đăng ảnh) ─┴→ RatingSheet
   chọn 4–5 sao → [Đánh giá trên App Store/Google Play] → in_app_review (lỗi → mở trang store) → đóng sheet
   chọn 1–3 sao → [Kể chúng mình nghe] → đóng sheet → FeedbackScreen(lowRating: n)
   [Để sau] / vuốt xuống / chạm nền → đóng (tự mời: tính đã mời)
Settings → "Góp ý & báo lỗi" (cả bản rút gọn) → FeedbackScreen(type chọn tay)
FeedbackScreen: nhập → (tuỳ chọn) đính ảnh → Gửi → đang gửi → Cảm ơn → [Xong] pop
                                                         └ lỗi mạng → banner + [Thử lại], giữ nguyên nội dung
```

## 1. RatingSheet (bottom sheet)
Mở bằng `showModalBottomSheet(isScrollControlled: true, backgroundColor: transparent, routeSettings: 'RatingSheet')`, dựng trong **`InviteSheetFrame`** (đã có: nền `cardSurface`, r28 trên, tay nắm 40x4, SafeArea đáy, padding 20/12/20/20). Không tạo khung mới.

```
        ───            (tay nắm)
   Bạn thấy Dear Embeiu thế nào?      <- displaySerif 20 w700, giữa
   Chấm vài giây thôi. Chúng mình đọc hết.   <- 14 w500 textSecondary, giữa
   
     ☆   ☆   ☆   ☆   ☆               <- 5 nút 48x48, gap 8, giữa
          Khá thích                    <- nhãn theo sao, 14 w600 textPrimary (chưa chọn: ẩn, giữ chỗ cao 20)

   [ Đánh giá trên App Store ]         <- pill navy h52 (disabled khi chưa chọn)
          Để sau                       <- TextButton h44, 14 w600 textSecondary
```
Spacing: tay nắm → title 18 · title → body 6 · body → hàng sao 20 · sao → nhãn 8 · nhãn → nút 20 · nút → "Để sau" 4.
- **Sao:** icon 36. Chưa chọn: `IconsaxPlusLinear.star_1`, màu `textTertiary`. Đã chọn (từ sao 1 đến n): `IconsaxPlusBold.star_1`, màu `accentLove`. Vùng chạm 48x48 (`InkResponse`, splash rose .08, radius 24). Chạm sao k = chọn k; chạm lại không bỏ chọn.
- **Nhãn:** 1 Chưa ổn lắm · 2 Còn thiếu nhiều · 3 Tạm được · 4 Khá thích · 5 Rất thích.
- **Nút chính:** y hệt `_buildSendButton` của care_message (navy `textPrimary`, r999, h52, chữ 16 w700, disabled = navy .28 / chữ trắng .7). Nhãn đổi theo sao: chưa chọn → `rateAppCtaDefault` (disabled); 4–5 → `rateAppCtaIos`/`rateAppCtaAndroid` (theo `Platform.isIOS`); 1–3 → `rateAppCtaLow`. Đổi nhãn bằng `AnimatedSwitcher` 200ms.
- **Để sau:** `TextButton`, luôn bật.
- **A11y:** hàng sao bọc `Semantics(container, label: rateAppStarsSemantics)`; mỗi sao `Semantics(button, selected, label: rateAppStarSemantics(n))`. Chữ nhãn đổi → `liveRegion: true`.

## 2. FeedbackScreen — "Góp ý & báo lỗi"
Nền `dawnBlush`, `Scaffold` trong suốt, `SafeArea(bottom:false)`, `SubScreenHeader(badge: feedbackBadge, badgeIcon: IconsaxPlusBold.message_question)` (chip-only, như care_message). Thân `ListView` padding `fromLTRB(16,20,16,24+bottomInset)`, `resizeToAvoidBottomInset: true`. Cùng cấu trúc `CareMessageScreen`.

```
 ←        [ ? GÓP Ý & BÁO LỖI ]
 ┌ ContentCard ──────────────────────────────┐
 │ (từ đánh giá thấp:  ★★☆☆☆  Bạn chấm 2/5 sao) │  <- thay hàng chip loại
 │ (mặc định:  [ Góp ý ]  [ Báo lỗi ])          │
 │ Nội dung                                     │  <- _FieldLabel
 │ ┌──────────────────────────────────────────┐│
 │ │ placeholder theo loại…                   ││  <- minLines 5, maxLines 8, maxLength 2000
 │ └──────────────────────────────────────────┘│
 │                                   123/2000  │  <- 12 w600 textSecondary, phải
 │ [ 🖼 Đính kèm ảnh chụp màn hình ]            │  <- hoặc thumbnail 72 + ✕
 │ ⓘ Gửi kèm phiên bản app, hệ điều hành…       │  <- 12 textSecondary
 └──────────────────────────────────────────────┘
 [ Gửi cho chúng mình ]                         <- pill navy h52, cách card 18
 (banner lỗi nằm GIỮA card và nút khi có lỗi)
```
**Chip loại (segmented 2 ô):** `Row` 2 `Expanded` gap 8, mỗi ô h44, r999. Chọn: nền `textPrimary`, chữ trắng 14 w700. Chưa chọn: nền `white .72`, viền `white .60` (1px), chữ `textPrimary` 14 w600. Icon trái 18: `IconsaxPlusLinear.message_text_1` (Góp ý), `IconsaxPlusLinear.danger` (Báo lỗi), màu theo chữ. Đổi 200ms easeOutCubic (`AnimatedContainer`). Mặc định chọn Góp ý. `Semantics(button, selected)`; hết ô chỉ có màu → ô chọn còn đổi nền + chữ đậm hơn, không chỉ dựa màu.
**Từ đánh giá thấp:** KHÔNG hiện chip loại (loại cố định = đánh giá thấp). Thay bằng hàng: 5 sao 18 (n sao `IconsaxPlusBold.star_1` `accentLove`, còn lại `Linear` `textTertiary`) + `feedbackRatedLabel` 14 w700 `textPrimary`, nền `accentRose .10` r16, padding 12x10. Có thể bỏ sao chỉ giữ chữ nếu dev thấy chật; mặc định giữ.
**Ô nhập:** `TextField` theme sẵn (filled `surfaceLight`, r20, focus `accentLove` 1.4), `maxLength: 2000`, `counterText: ''`, tự vẽ bộ đếm bên dưới (phải, `padding top 6`). Bộ đếm `textSecondary`; từ ≥1900 đổi `accentLoveDeep`. Không autofocus. Placeholder (14, theme hint):
- Góp ý → `feedbackHintSuggestion` · Báo lỗi → `feedbackHintBug` · Đánh giá thấp → `feedbackHintLowRating`.
**Nút đính ảnh (chưa có ảnh):** `OutlinedButton.icon` h48, r16, viền `textTertiary .35`, nền `white .72`, icon `IconsaxPlusLinear.gallery_add` 20, chữ 14 w600 `textPrimary`, full width. Chọn ảnh qua `ImagePicker` (gallery, `imageQuality: 85`, `maxWidth: 1600`). Ảnh >10MB sau nén → báo `feedbackPhotoTooLarge` (SnackBar), không đính.
**Đã có ảnh:** hàng `Row`: thumbnail 72x72 r16 (`Image.file`, `BoxFit.cover`, viền `white .8`) + cạnh phải tên ngắn "Ảnh đính kèm" 14 w600 + nút `✕` 44x44 vùng chạm (`IconsaxPlusLinear.close_circle` 24 `textSecondary`, `Semantics label feedbackPhotoRemove`). Bỏ ảnh → quay lại nút đính. Chỉ 1 ảnh.
**Dòng thông tin máy:** `Row` icon `IconsaxPlusLinear.info_circle` 16 `textTertiary` + `feedbackDeviceNote` 12 w500 `textSecondary` height 1.4. Cách trên 14.
**Nút Gửi:** copy y `_buildSendButton` của care_message. Bật khi `text.trim().isNotEmpty && !sending`. Nhãn `feedbackSendCta`; spinner trắng 20 khi đang gửi (nhãn ẩn); sau lỗi nhãn = `feedbackRetryCta`.

## States
- **Rỗng:** nút Gửi disabled, bộ đếm `0/2000`, ảnh chưa có.
- **Đang gửi:** nút spinner, `FocusScope.unfocus()`, chip/ô nhập/nút ảnh `IgnorePointer` + opacity .6; nút Back vẫn thoát được (hộp xác nhận không cần — nội dung chưa gửi sẽ mất; chấp nhận, xem Dev notes).
- **Lỗi mạng / lỗi gửi:** banner ngay trên nút Gửi: nền `error .10`, viền `error .30`, r16, padding 12, icon `IconsaxPlusLinear.danger` 18 màu `error`, chữ `feedbackErrorBanner` 14 w600 `textPrimary`. Nút đổi "Thử lại". Nội dung + ảnh + loại giữ nguyên. Banner tắt khi user sửa nội dung hoặc bấm Thử lại.
- **Thành công:** thay toàn bộ nội dung card bằng khối giữa màn (`AnimatedSwitcher` 280ms fade+slide-y 8): vòng tròn 72 nền `accentLove .12` chứa `IconsaxPlusBold.tick_circle` 40 `accentLove` · cách 18 · `feedbackSuccessTitle` displaySerif 22 w700 giữa · cách 8 · `feedbackSuccessBody` 14 w500 `textSecondary` giữa, height 1.45 · cách 24 · nút navy pill h52 `feedbackDoneCta` → `Navigator.pop`. Haptic `lightImpact`. Ẩn nút Gửi cũ.
- **Chưa đăng nhập:** không xảy ra từ Settings; nếu auth null thì dùng banner lỗi chung.
- **Ảnh lỗi chọn:** SnackBar floating mặc định, `feedbackPhotoError`.

## 3. Tile trong Settings
Dùng đúng `_navRow(icon, title, subtitle, onTap)` đã có (IconBadge 44 r16 + tiêu đề 15 w700 + phụ đề 12 + mũi tên `arrow_right_3`), **thêm vào cuối card của nhóm "Chung"** (sau hàng chính sách bảo mật), cách nhau bằng `_rowDivider()`:
| Thứ tự | Icon (`IconsaxPlusLinear`) | Title | Subtitle | onTap |
|---|---|---|---|---|
| 1 | `star_1` | `settingsRateAppTitle` | `settingsRateAppSubtitle` | `RatingSheet.show(context, source: 'settings')` |
| 2 | `message_question` | `settingsFeedbackTitle` | `settingsFeedbackSubtitle` | push `FeedbackScreen` |
Bản Cài đặt rút gọn (chưa ghép đôi): chỉ tile 2, đặt trong 1 `ContentCard` cùng kiểu, ngay trên khối Xoá tài khoản/Đăng xuất (không đổi thứ tự danh sách danger). `trailingIcon` mặc định. Không badge.

## Interaction & animation
- Chọn sao: icon `scale 1 → 1.18 → 1` 160ms easeOutCubic, các sao ≤ n tô lần lượt lệch 30ms; `HapticFeedback.selectionClick()`.
- Đổi nhãn nút/nhãn sao: `AnimatedSwitcher` 200ms.
- Chip loại: 200ms easeOutCubic. Thành công: 280ms (token `AppMotion.base`).
- Sheet: animation mặc định của Flutter.
- **Reduce Motion** (`AppMotion.reduceMotion(context)`): bỏ scale sao + stagger, đổi tức thì; switcher giữ fade ngắn.

## Copy (song ngữ, xưng "chúng mình")
Key ARB (thêm CẢ `app_en.arb` + `app_vi.arb`, rồi `gen-l10n`). Placeholder: `{count}` kiểu int.

| Key | VI | EN |
|-----|----|----|
| rateAppTitle | Bạn thấy Dear Embeiu thế nào? | How's Dear Embeiu treating you? |
| rateAppSubtitle | Chấm vài giây thôi. Chúng mình đọc hết. | Takes a few seconds. We read every one. |
| rateAppStar1 | Chưa ổn lắm | Not great |
| rateAppStar2 | Còn thiếu nhiều | Needs work |
| rateAppStar3 | Tạm được | It's okay |
| rateAppStar4 | Khá thích | Pretty good |
| rateAppStar5 | Rất thích | Love it |
| rateAppCtaDefault | Chọn số sao | Pick a rating |
| rateAppCtaIos | Đánh giá trên App Store | Rate on the App Store |
| rateAppCtaAndroid | Đánh giá trên Google Play | Rate on Google Play |
| rateAppCtaLow | Kể chúng mình nghe | Tell us what happened |
| rateAppLater | Để sau | Not now |
| rateAppStarSemantics (`{count}`) | {count} sao | {count} stars |
| rateAppStarsGroupSemantics | Chấm sao cho Dear Embeiu | Rate Dear Embeiu |
| settingsRateAppTitle | Đánh giá Dear Embeiu | Rate Dear Embeiu |
| settingsRateAppSubtitle | Mỗi lượt chấm giúp app đến được thêm nhiều cặp đôi | Every rating helps more couples find the app |
| settingsFeedbackTitle | Góp ý & báo lỗi | Feedback & bug reports |
| settingsFeedbackSubtitle | Điều gì chưa ổn, hay bạn muốn có thêm gì? | What's off, or what would you like to see? |
| feedbackBadge | GÓP Ý & BÁO LỖI | FEEDBACK |
| feedbackTypeSuggestion | Góp ý | Suggestion |
| feedbackTypeBug | Báo lỗi | Bug report |
| feedbackFieldLabel | Nội dung | Message |
| feedbackHintSuggestion | Bạn muốn app có thêm gì, hay sửa chỗ nào cho dễ dùng hơn? | What should we add, or make easier to use? |
| feedbackHintBug | Chuyện gì đã xảy ra? Bạn bấm gì, ở màn hình nào, và lẽ ra phải thế nào? | What happened? What did you tap, on which screen, and what did you expect? |
| feedbackHintLowRating | Điều gì khiến bạn chưa hài lòng? Một dòng cũng được. | What let you down? A single line is fine. |
| feedbackRatedLabel (`{count}`) | Bạn chấm {count}/5 sao | You rated us {count}/5 |
| feedbackCounter (`{count}`) | {count}/2000 | {count}/2000 |
| feedbackAttachCta | Đính kèm ảnh chụp màn hình | Attach a screenshot |
| feedbackPhotoLabel | Ảnh đính kèm | Attached screenshot |
| feedbackPhotoRemove | Bỏ ảnh đính kèm | Remove screenshot |
| feedbackPhotoError | Không mở được ảnh này. Thử ảnh khác nhé. | Couldn't open that image. Try another. |
| feedbackPhotoTooLarge | Ảnh lớn quá, tối đa 10 MB. | That image is too large (10 MB max). |
| feedbackDeviceNote | Chúng mình gửi kèm phiên bản app, hệ điều hành và đời máy để tìm lỗi nhanh hơn. | We include your app version, OS and device model so we can track issues down faster. |
| feedbackSendCta | Gửi cho chúng mình | Send to us |
| feedbackRetryCta | Thử lại | Try again |
| feedbackErrorBanner | Chưa gửi được. Kiểm tra mạng rồi thử lại, nội dung của bạn vẫn còn đây. | Couldn't send. Check your connection and try again. Your message is still here. |
| feedbackSuccessTitle | Cảm ơn bạn | Thank you |
| feedbackSuccessBody | Chúng mình đã nhận được và sẽ đọc kỹ từng chữ. | We got it and we'll read every word. |
| feedbackDoneCta | Xong | Done |

Đã soát giọng (humanizer + avoid-ai-writing): câu ngắn, không sáo rỗng. `rateAppSubtitle` "Chúng mình" ở đây là đội làm app, không phải cặp đôi trong app (không đụng luật "chúng mình"/"hai đứa").

## Assets
Không asset mới. Icon `iconsax_plus` đã xác nhận tồn tại: `star_1`, `message_question`, `message_text_1`, `danger`, `gallery_add`, `close_circle`, `tick_circle`, `info_circle`, `arrow_right_3`.

## Handoff / Dev notes
- Tái dùng: `InviteSheetFrame` (nên đổi tên/di chuyển sang file chung nếu muốn, không bắt buộc), `ContentCard`, `SubScreenHeader`, `SectionHeader`, `_FieldLabel` + `_buildSendButton` (copy từ care_message, hoặc tách chung), `_navRow`/`_rowDivider` ở settings.
- Cỡ chữ chỉ dùng 12/14/15/16/20/22 (đúng type scale). Màu chỉ token `AppColors` (`textPrimary`, `textSecondary`, `textTertiary`, `accentLove`, `accentLoveDeep`, `accentRose`, `error`, `white` + alpha).
- Tên nút cửa hàng chọn theo `Platform.isIOS` (không đoán qua locale).
- "Đang gửi": nên timeout ~20s (ảnh cần upload, khác care_message vốn queue offline được) → coi như lỗi mạng, KHÔNG báo thành công giả. Back khi đang gửi: cho thoát, nội dung mất (không dialog xác nhận, form ngắn).
- Tự mời chỉ dựng sheet; `source` truyền vào để analytics. Sheet đóng bằng vuốt/chạm nền/"Để sau" đều coi là "Để sau".
- Màn Feedback nhận `lowRating` (int?, 1–3) và `source`. Khi có `lowRating` thì loại = đánh giá thấp, ẩn chip.
- Chưa chốt: dòng `feedbackDeviceNote` cố ý KHÔNG hứa "không gửi danh tính" vì doc `feedback` có `uid` (rules cần). PO xác nhận nếu muốn thêm câu đó.

## Acceptance (design)
- [x] Mọi state có mô tả (rỗng, đang gửi, lỗi, thành công, ảnh lỗi)
- [x] Copy đủ VI+EN
- [x] Dev dựng được không cần hỏi lại

## Nhật ký design
- [2026-10-29] [Designer] Thiết kế RatingSheet 5 sao, FeedbackScreen (chip loại, ảnh, trạng thái), 2 tile Settings, copy vi+en; đã tra UI UX Pro Max.
