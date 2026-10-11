# 🎨 Design — pairing-funnel (Apple · Mã QR · gợi ý mã · nhắc mời)

> Designer sở hữu. Đọc [`overview.md`](overview.md) trước (PF1–PF10). Bám [`project/design-system.md`](../../design-system.md), mục Design Unify 2026-06-11. CHỈ thiết kế, không code.

- **Trạng thái design:** xong (2026-10-11)
- **Người/role:** Designer
- **Phạm vi:** đúng 7 hạng mục PO giao, theo PF1–PF10. Chỗ nào vượt overview đều ghi **[đề xuất]** và nằm trong "Câu hỏi cho PO". Dev chưa có trả lời thì làm theo mặc định ghi ở từng câu.

## Mục tiêu thiết kế

Ba con số trong overview quyết định gần hết lựa chọn bên dưới:

- **36% người đăng ký kẹt ở bước xác thực email.** Trên iPhone (95% người dùng), nút Apple phải là đường ngắn nhất: 1 chạm, Face ID, vào thẳng Setup.
- **7/13 cặp ghép ngay trong giờ đầu.** Hai người thường đang ngồi cạnh nhau. Mã QR và gợi ý dán mã phải dùng được tại chỗ, khỏi gõ tay 6 ký tự.
- **19/31 cặp đang chờ đã nguội sau 30 ngày.** Lời nhắc dồn vào ngày đầu và nói rõ việc cần làm: quét QR hoặc gửi tin.

Nguyên tắc:
- Tái dùng thứ đã có: `GlassCard` (form auth), `ContentCard`, khung sheet của `FeatureTourSheet`/`MemoriesSheet`, `InviteActionButtons`, `BlockingLoadingOverlay`, SnackBar theme, nút rose h52.
- Đường email/mật khẩu giữ nguyên hành vi và bố cục. Trên iOS chỉ chèn thêm khối Apple.
- Chỉ thêm 1 token màu: màu đen của Apple (xem "Đề xuất bổ sung design system").

## Câu hỏi cho PO

1. **Dòng đồng ý chỉ nêu "Chính sách bảo mật".** App chưa có trang Điều khoản (đã rà `docs/`, không có), trong khi PF2 ghi "Điều khoản và Chính sách quyền riêng tư". Mặc định: chỉ link Chính sách bảo mật, dùng đúng chữ app đang dùng ở checkbox màn Đăng ký. Muốn có "Điều khoản" thì cần URL: EULA chuẩn của Apple hay một trang riêng?
2. **[đề xuất] Người đã cài app sẵn.** 48/111 người chưa từng vào couple, nhiều người có app và đang đứng ở Setup. Họ mở link mời, bấm "Mở Dear Embeiu". Theo PF8 nút này không chép link, theo PF9 app chỉ đọc bộ nhớ tạm lúc mở Setup, nên họ không được hỏi gì. Đề xuất: (a) nút "Mở Dear Embeiu" trên trang get cũng chép link; (b) app kiểm tra lại khi người dùng quay về app mà đang ở Setup. Mặc định: làm đúng PF8/PF9.
3. **Hộp "Cho phép dán" của iOS hiện với mọi link.** `detectPatterns(.probableWebURL)` chỉ biết "có link", không biết link gì. Người tạo couple vừa chép link Shopee cũng sẽ gặp hộp hệ thống "Dear Embeiu muốn dán từ Safari" khi tới Setup. Thiết kế đã chặn lặp lại: mỗi nội dung bộ nhớ tạm chỉ đọc một lần. PO có chấp nhận phần rủi ro còn lại không? Phương án thay: app hiện sheet riêng trước ("Bạn có link mời?") rồi mới đọc, đổi lại người được mời mất thêm 1 chạm. Mặc định: giữ PF9.

## User flow

**F1 — Người mới trên iPhone (PF1–PF4)**
```
Landing ──[Tiếp tục với Apple]──► sheet Apple (Face ID) ──► authGate ──► Setup
                                       │                    (không qua màn xác thực email)
                                       ├─ huỷ sheet ──► ở lại màn cũ, im lặng
                                       └─ email đã có tài khoản mật khẩu ──► SnackBar PF6 [Đăng nhập]
```

**F2 — Ghép tại chỗ bằng QR (PF7 → PF8 → PF9)**
```
A: thẻ chờ Home / Setup / Profile ──[Mã QR]──► sheet QR
B: mở Camera, quét ──► dearembeiu.com/get?code=A7K9Q2
B: bấm "Tải trên App Store" ──► link mời vào bộ nhớ tạm ──► App Store ──► cài, mở app
B: (intro) ──► landing ──► Apple ──► Setup
   +500ms ──► iOS hỏi "Cho phép dán" (chỉ khi bộ nhớ tạm có URL) ──► Cho phép
          ──► sheet "Nhập mã từ lời mời?" ──[Ghép đôi ngay]
          ──► tab "Tham gia bằng mã", ô mã = A7K9Q2 ──► overlay "Đang ghép đôi..." ──► Lottie ──► Home
```

**F3 — Ghép qua tin nhắn:** như F2, bắt đầu từ lúc B mở link trong tin nhắn.

**F4 — Xoá tài khoản Apple (PF5)**
```
Cài đặt ──[Xoá tài khoản]──► dialog (có dòng báo trước sheet Apple) ──[Xoá vĩnh viễn]
   ──► overlay chặn màn + sheet Apple ──► xác nhận ──► thu hồi token (lỗi thì bỏ qua) ──► xoá ──► landing
                                      └─ huỷ sheet ──► overlay tắt, ở lại Cài đặt, không báo gì
```

**F5 — Lời nhắc mời (PF10):** tạo couple 14:00 thứ Hai → nhắc 16:00 thứ Hai (chỉ khi chưa bấm Gửi/Sao chép/QR) → 10:00 thứ Ba → 14:00 thứ Năm → thôi.

## Wireframe

### W1. Landing — thẻ CTA (`guest_counter_screen._buildCtaCard`), iOS
```
┌─ GlassCard r28, padding 20 ──────────────────────────────┐
│ ♥ Muốn lưu kỷ niệm cùng người ấy?                        │ 16 w700 navy (giữ)
│ Đăng nhập để ghép đôi & lưu ảnh chung.                   │ 13 textSecondary (giữ)
│                                                          │ 16
│ ┌──────────────────────────────────────────────────────┐ │
│ │                 Tiếp tục với Apple                  │ │ #000 h52 r999   ← MỚI
│ └──────────────────────────────────────────────────────┘ │
│                                                          │ 10
│          Khi tiếp tục với Apple, bạn đồng ý với          │ 12 navy .80     ← MỚI
│                  Chính sách bảo mật.                     │ link navy w700, gạch chân
│                                                          │ 14
│ ┌───────────────────────────────────┐                    │
│ │       Đăng nhập bằng email        │        Đăng ký     │ rose h52 + TextButton (đổi nhãn)
│ └───────────────────────────────────┘                    │
└──────────────────────────────────────────────────────────┘
Android: không có khối Apple + dòng đồng ý. Chỉ đổi nhãn nút hồng.
```

### W2. Đăng nhập (`login_screen._buildFormCard`), iOS — Apple nằm DƯỚI form
```
 ←             [🔒 CHÀO MỪNG TRỞ LẠI]                 [VI]
┌─ GlassCard r28 ──────────────────────────────────────────┐
│ Email                                                    │
│ Email                                                    │
│ [✉  Nhập email                                        ]  │
│ Mật khẩu                                                 │
│ [🔒 ••••••                                         👁 ]  │
│                                          Quên mật khẩu?  │
│ [                    Đăng nhập (rose)                 ]  │
│                                                          │ 18
│ ─────────────────────── hoặc ───────────────────────     │ MỚI
│                                                          │ 18
│ [                Tiếp tục với Apple (#000)            ]  │ MỚI
│          Khi tiếp tục với Apple, bạn đồng ý với          │
│                  Chính sách bảo mật.                     │
│                                                          │ 14
│            Chưa có tài khoản?  Tạo tài khoản             │ (giữ)
└──────────────────────────────────────────────────────────┘
```

### W3. Đăng ký (`register_screen._buildFormCard`), iOS — Apple nằm TRÊN form
```
 ←                [👤 TẠO TÀI KHOẢN]                  [VI]
┌─ GlassCard r28 ──────────────────────────────────────────┐
│ [                Tiếp tục với Apple (#000)            ]  │ MỚI
│          Khi tiếp tục với Apple, bạn đồng ý với          │ MỚI
│                  Chính sách bảo mật.                     │
│                                                          │ 18
│ ─────────────────────── hoặc ───────────────────────     │ MỚI
│                                                          │ 18
│ Tên hiển thị                                             │
│ … 4 ô nhập · ô disclosure · checkbox · nút Tạo tài khoản │ (giữ nguyên)
│ · "Đã có tài khoản? Đăng nhập"                           │
└──────────────────────────────────────────────────────────┘
```

### W4. Giải phẫu nút Apple
```
◄──────────── rộng = cột cha (≈ 295pt ở máy 375pt) ────────────►
┌──────────────────────────────────────────────────────────────┐ ▲
│                    ‹6›Tiếp tục với Apple                   │ 52
└──────────────────────────────────────────────────────────────┘ ▼
  nền #000000 · r999 · Icons.apple 24 trắng · cách 10 · SF Display 22 w500 trắng (chung kiểu chữ với nút Google)
  cụm logo + chữ căn giữa

Đang chạy:  [                    ◌  spinner trắng 20                    ]
Bị khoá:    cả nút Opacity .5 (khi nút email trên cùng màn đang chạy)
```

### W5. Dialog xoá tài khoản (chỉ tài khoản Apple mới có đoạn 2)
```
┌─ AlertDialog (theme) ───────────────────────────┐
│ Xoá tài khoản?                      (error w800)│ giữ
│                                                 │
│ Việc này không thể hoàn tác. Toàn bộ dữ liệu    │ giữ
│ của bạn, gồm ảnh và thông tin cặp đôi, sẽ bị    │
│ xoá vĩnh viễn.                                  │
│                                                 │ 12
│ Sau đó Apple sẽ hiện hộp đăng nhập để xác nhận  │ 13 textSecondary ← MỚI
│ đó là bạn.                                      │
│                                                 │
│                        Huỷ     Xoá vĩnh viễn    │ giữ
└─────────────────────────────────────────────────┘

Biến thể Apple của dialog xác minh lại (khi gặp requires-recent-login):
┌─────────────────────────────────────────────────┐
│ Xác minh đó là bạn                  (error w800)│ giữ title
│                                                 │
│ Vì lý do bảo mật, bạn xác nhận lại với Apple    │ MỚI, không có ô mật khẩu
│ để xoá tài khoản vĩnh viễn.                     │
│                                                 │
│                        Huỷ     Xoá vĩnh viễn    │
└─────────────────────────────────────────────────┘
```

### W6. `InviteActionButtons` thêm "Mã QR"
```
Setup (máy ≥ 375) và Profile (máy ≥ 390): 1 hàng
  [⧉ Sao chép]  [⇱ Chia sẻ]  [⌗ Mã QR]

Profile ở máy 375 (cột chỉ còn ≈ 253pt): Wrap tự xuống dòng
  [⧉ Sao chép]  [⇱ Chia sẻ]
  [⌗ Mã QR]

iconOnly (hiện chưa nơi nào dùng):  [⧉] [⇱] [⌗]   tooltip = nhãn

Mỗi pill: hình cao 36, vùng chạm 48 (đệm vô hình 6pt trên/dưới) · chữ navy · icon rose
```

### W7. Thẻ chờ Home — bước 1 (`home_screen._buildWaitingForPartnerBanner`)
```
 ①  Gửi lời mời
 │  Gửi mã qua tin nhắn, hoặc cho người ấy quét mã QR nếu đang ở cạnh nhau.   ← đổi chữ
 │  ┌──────────┐
 │  │  A7K9Q2  │                                                 (giữ)
 │  └──────────┘
 │  [               Gửi cho người ấy 💌               ]          (giữ, vẫn là nút chính)
 │  (⧉ Sao chép mã)  (⌗ Mã QR)                                   ← thêm pill QR, Wrap spacing 8, chữ navy, cao 36 / chạm 48
 ②  Người ấy tải app và đăng ký
```

### W8. Sheet Mã QR
```
┌───────────────── sheet trắng, bo trên r28 ─────────────────┐
│                           ────                             │ handle 40×4
│                                                            │ 18
│                 Cho người ấy quét mã này                   │ 20 w700
│     Người ấy mở Camera, hướng vào mã là tới trang tải      │ 14 textSecondary
│          Dear Embeiu, có sẵn mã mời của bạn.               │
│                                                            │ 20
│              ┌──────────────────────────┐                  │
│              │  ▛▀▀▀▜  ▄▀▄ ▀  ▛▀▀▀▜      │                  │ ContentCard r24, padding 20
│              │  ▌   ▐  ▀▄▀▄▀  ▌   ▐      │                  │ QR 220×220, navy trên trắng
│              │  ▙▄▄▄▟  ▄ ▀▄   ▙▄▄▄▟      │                  │
│              └──────────────────────────┘                  │
│                                                            │ 16
│                         A7K9Q2                             │ 30 w900 ls4 accentLoveDeep
│      Không quét được? Đọc mã này cho người ấy nhập.        │ 12 textSecondary
│                                                            │ 20
│ [                          Xong                         ]  │ ElevatedButton theme (navy h52)
└────────────────────────────────────────────────────────────┘
```

### W9. Sheet gợi ý mã ở Setup + trạng thái sau khi đồng ý
```
┌───────────────── sheet trắng, bo trên r28 ─────────────────┐
│                           ────                             │
│                          ( ♥ )                             │ đĩa 64 accentLove .14, heart 30
│                   Nhập mã từ lời mời?                      │ 20 w700
│      Link mời bạn mở có mã này. Ghép đôi là vào chung      │ 14 textSecondary
│               không gian với người ấy.                     │
│                    ┌──────────────┐                        │
│                    │    A7K9Q2    │                        │ accentLove .10 r16 · 30 w900 ls4
│                    └──────────────┘                        │
│ [                Ghép đôi ngay (navy)                   ]  │ ElevatedButton theme h52
│                         Bỏ qua                             │ TextButton textSecondary
└────────────────────────────────────────────────────────────┘

Sau "Ghép đôi ngay":
  Setup   [  Tạo mới  | ● Tham gia bằng mã ]   ← pill trượt 260ms (có sẵn)
          Mã mời của người ấy  [ A7K9Q2 ]      ← đã điền
          ░░░░ overlay "Đang ghép đôi..." ░░░░  ← sau 300ms
```

### W10. Trang `dearembeiu.com/get` — điện thoại, có mã
```
                 (💞)
         Bạn được mời rồi! 💞
  Người ấy mời bạn cùng lưu giữ kỷ niệm trên
  Dear Embeiu 💞 Tải app và đăng ký, mã bên
  dưới sẽ ghép đôi hai bạn.                              ← đổi chữ
  ┌─ MÃ MỜI ──────────────────────────┐
  │              A7K9Q2               │
  │         ( Sao chép mã )           │                  (giữ)
  └───────────────────────────────────┘
  [        Tải trên App Store        ]                   ← iPhone chỉ thấy nút này [nên]
  Bấm tải là mã được chép sẵn. Cài xong mở app là có.    ← #redirectNote, MỚI
  [   Mở Dear Embeiu (nếu đã cài)   ]                    (giữ)
  App không hỏi mã? Chọn “Tham gia bằng mã” rồi nhập mã ở trên.   ← #subNote, đổi chữ

Quay lại Safari sau khi bấm tải:
  Mã đã được chép sẵn ✓ Cài xong mở app là có.
```

## Spec chi tiết (token chính xác)

### 1. Nút "Tiếp tục với Apple" — component dùng chung (PF1, PF2)

Đề xuất 1 widget `AppleSignInButton` (`lib/widgets/apple_sign_in_button.dart`) gồm nút + dòng đồng ý. Ba màn dùng chung, không vẽ lại.

**Hiện khi:** `Platform.isIOS && authProvider.isUsingFirebase` (PF1). Android và chế độ local fallback: không render gì, không chừa khoảng trống.

**Vì sao nền `#000000`, không phải navy `textPrimary`:** HIG chỉ cho 3 kiểu nút Apple: Đen, Trắng, Trắng có viền, và không cho đổi màu nút. Navy #1A1A2E là "gần đen", reviewer có quyền coi là tự đổi màu. Form nằm trên kính dawnBlush (nền sáng), đúng chỗ HIG khuyên kiểu Đen. ⚠️ `AppColors.black` trong code là #1A1A2E (navy) — KHÔNG dùng cho nút này.

| Thuộc tính | Giá trị |
|---|---|
| Kích thước | cao 52, rộng full theo cột cha (HIG tối thiểu 140×30 — đạt) |
| Hình | pill r999 (HIG cho chỉnh bo góc cho khớp nút khác trong app) |
| Nền | `#000000` → token mới `AppColors.appleBlack` |
| Logo | `Icons.apple` (Material) size 24, trắng. So với nút Apple hệ thống trên simulator; logo trông thấp thì dịch lên 1pt |
| Khoảng logo → chữ | 10 (chung với nút Google, 2026-10-12) |
| Chữ | `continueWithApple`, trắng, **22 w500** (w600 → w500 ngày 2026-10-12 để khớp nút Google), font hệ thống iOS `fontFamily: 'CupertinoSystemDisplay'` (SF Pro Display). 22/52 ≈ 42%, khớp tỉ lệ ~43% của HIG ("Regardless of the font you choose, the title and button height … need to use the same proportions"). 22 có sẵn trong type scale |
| Căn | Row logo + chữ căn giữa, bọc `FittedBox(fit: BoxFit.scaleDown)` để chữ phóng to (Dynamic Type) không tràn |
| Ripple | InkWell splash trắng .12, highlight trong suốt (luật ripple nền đậm) |
| Viền / bóng | không |
| Khoảng trống quanh nút | ≥ 6pt (HIG: ≥ 1/10 chiều cao). Các khoảng 10–18 bên dưới đều thoả |
| Semantics | `button: true`, label = `continueWithApple`; đang chạy thì `enabled: false`, spinner bọc `ExcludeSemantics`; logo là trang trí (không label) |

**Dòng đồng ý** (ngay dưới nút, cách 10):
- `Text.rich`, căn giữa: `appleConsentPrefix` + " " + `privacyPolicyLabel` (phần link) + ".".
- Phần thường: 12 w500, `textPrimary` α .80, height 1.45. Phần link: 12 w700 `textPrimary`, gạch chân màu `textPrimary` α .40.
- Vì sao navy α .80: đo ở điểm tối nhất của nền (kính trắng .16 trên dawn3 #C8A8E9, đúng chỗ thẻ CTA landing nằm): `textSecondary` 2,9:1, rose 1,8:1, navy .62 cũng chỉ 3,8:1 — đều dưới 4,5:1. Navy .80 đạt 6,0:1, phần link navy đặc đạt 9,4:1.
- Cả dòng là một vùng chạm: InkWell r8, cao tối thiểu 44 (`ConstrainedBox(minHeight: 44)`, chữ căn giữa dọc), splash rose .08 → `launchUrl(AppUrls.privacyPolicy, mode: LaunchMode.externalApplication)`, y ô disclosure ở Đăng ký. Semantics: link, label = cả câu.

**Divider "hoặc"** (chỉ ở Đăng nhập + Đăng ký, KHÔNG ở landing):
- Row: `Expanded(Divider(thickness 0.5, textPrimary .10))` · 12 · Text `authOrDivider` 12 w600 `textPrimary` α .80 (α .55 chỉ 3,2:1) · 12 · `Expanded(Divider(...))`. Cùng nét divider với thẻ chờ Home.
- Trên 18, dưới 18.

#### 1a. Landing (W1)
- Chèn giữa body và hàng nút cũ: `guestCtaBody` → 16 → `AppleSignInButton` → 14 → Row [Đăng nhập | Đăng ký].
- Không divider: dòng đồng ý đã tách hai nhóm, thẻ giữ gọn.
- **Đổi nhãn nút hồng** `guestCtaSignIn`: "Đăng nhập" → "Đăng nhập bằng email" (cả Android, chỉ đổi chữ ARB). Lý do: trước bản này 100% tài khoản là email. Người cũ cài lại app sẽ gặp nút đen nổi nhất; nhãn mới chỉ đúng đường cho họ, bớt ca tạo nhầm tài khoản Apple trống. Bề rộng: chữ 15 w600 ≈ 150pt + padding nút 48, pill còn ≈ 209pt ở máy 375 → vừa 1 dòng.

#### 1b. Đăng nhập (W2) — Apple dưới form
- Thứ tự: form email (giữ) → nút Đăng nhập → 18 → divider → 18 → `AppleSignInButton` → 14 → "Chưa có tài khoản? Tạo tài khoản".
- Lý do: ai mở màn Đăng nhập là người cũ, và tới giờ ai cũng dùng email. Apple đứng đầu thì người có Apple ID khác email (hoặc chọn "Ẩn email của tôi") sẽ tạo ra tài khoản mới trống và tưởng mất hết kỷ niệm. Người mới vẫn thấy Apple ngay ở landing và Đăng ký.

#### 1c. Đăng ký (W3) — Apple trên form
- Thứ tự: `AppleSignInButton` → 18 → divider → 18 → form cũ bắt đầu từ "Tên hiển thị" (giữ checkbox, ô disclosure, nút Tạo tài khoản).
- Nút Apple không phụ thuộc checkbox. Đồng ý ngầm qua dòng chữ (PF2).

#### Trạng thái nút Apple
| State | Nút Apple | Các nút khác trên cùng màn |
|---|---|---|
| Thường | như spec | bình thường |
| Nhấn | ripple trắng .12 | — |
| Đang chạy (từ lúc bấm tới khi điều hướng hoặc báo lỗi) | thay logo + chữ bằng spinner trắng 20×20, stroke 2.2 (y nút Đăng nhập); `onPressed: null` | disabled: nút hồng, link Đăng ký / Tạo tài khoản / Quên mật khẩu. **KHÔNG** hiện spinner ở nút khác |
| Bị khoá (nút email đang chạy) | `Opacity(0.5)`, không ripple, nền vẫn đen | — |
| Ẩn | Android, `!isUsingFirebase` | — |

⚠️ `AuthProvider.isLoading` đang dùng chung. Nếu luồng Apple bật cờ này, nút Đăng nhập cũng sẽ hiện spinner. Cần biết nút nào đang chạy (vd cờ `isAppleSigningIn`, hoặc state cục bộ của màn).

### 2. Kết quả và lỗi của luồng Apple

| Tình huống | Hiển thị | Haptic |
|---|---|---|
| Bấm nút | `FocusScope.unfocus()` (đóng bàn phím ở Đăng nhập / Đăng ký) | `lightImpact` |
| Thành công | `pushNamedAndRemoveUntil(authGate)`, y đăng nhập email | — |
| Huỷ sheet Apple | không gì cả, nút về trạng thái thường | không |
| `account-exists-with-different-credential` (PF6) | SnackBar `appleEmailHasPasswordAccount`, 5 giây. Landing và Đăng ký: kèm `SnackBarAction(label: signIn)` → màn Đăng nhập (Đăng ký dùng `pushReplacementNamed`, giữ luật hoán đổi login↔register). Đăng nhập: không action; nếu lỗi trả về email thì điền sẵn ô email và focus ô mật khẩu | `heavyImpact` |
| Mất mạng | SnackBar `authNetworkError` (có sẵn) | `heavyImpact` |
| Lỗi khác | SnackBar `appleSignInFailed` | `heavyImpact` |

SnackBar dùng theme sẵn có (floating, navy, r20). Các màn auth đang báo lỗi bằng SnackBar, nên không thêm banner.

### 3. Xoá tài khoản Apple (PF5)

- **Nhận biết:** tài khoản có provider `apple.com` và không có `password`.
- **Dialog xác nhận** (`_showDeleteAccountDialog`): giữ title, content, actions. Riêng tài khoản Apple, content đổi từ `Text` sang `Column(mainAxisSize.min, crossAxisAlignment.start)` = đoạn cũ → 12 → `deleteAccountAppleNote` (13, `textSecondary`, height 1.4).
- **Có cần câu báo trước không:** cần. Sheet Apple khi xác minh lại trông như hộp đăng nhập ("Dùng ID Apple của bạn để đăng nhập vào Dear Embeiu"). Không báo trước thì người đang xoá tài khoản dễ tưởng nhầm rồi bấm huỷ. Câu mới nói đúng thứ họ sắp thấy.
- **Bấm "Xoá vĩnh viễn":** dialog đóng → overlay sẵn có (`BlockingLoadingOverlay` theo `authProvider.isLoading`) → sheet Apple đè lên.

| Kết quả | Hiển thị |
|---|---|
| Xác nhận → thu hồi → xoá xong | `authGate` → landing (như cũ) |
| Huỷ sheet Apple | overlay tắt, ở lại Cài đặt, không SnackBar |
| Thu hồi token lỗi | không hiện gì (ghi log), vẫn xoá |
| Xoá lỗi (mạng, callable) | SnackBar như hiện tại (`authNetworkError` / `deleteAccountFailed`) |
| `requires-recent-login` | dialog xác minh **biến thể Apple** (W5 dưới): title `deleteAccountReauthTitle`, body `deleteAccountReauthBodyApple`, **không có ô mật khẩu**; actions `cancel` + `deleteAccountConfirmBtn` (error w700); đang chạy thì nút đổi thành spinner 18 như bản mật khẩu. Bấm → sheet Apple → thử xoá lại 1 lần. Lỗi lần hai → `deleteAccountSessionExpiredMsg` + authGate, y nhánh mật khẩu |

### 4. Mã QR (PF7)

#### 4a. Nút "Mã QR" trong `InviteActionButtons` (Setup + Profile)
- `Row` → `Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center)`. Lý do: thêm pill thứ 3, cụm rộng ≈ 260–270pt (ước lượng Quicksand 12). Tile Profile ở máy 375 chỉ còn ≈ 253pt (375 − 32 gutter − 32 padding − 44 IconBadge − 14) → Row sẽ tràn vạch vàng-đen.
- Pill thứ 3, đặt sau "Chia sẻ": icon `IconsaxPlusLinear.scan_barcode` 14, nhãn `inviteQrBtn`.
- **Cả 3 pill đổi cách dựng (theo Soát UX):** `_Pill` từ Material + InkWell sang `TextButton.icon` (bản iconOnly: `IconButton` có `tooltip`), giữ `tapTargetSize: MaterialTapTargetSize.padded` (mặc định trên mobile). Hình pill cao 36, vùng chạm tối thiểu 48×48 (≥ 44pt iOS, đúng 48dp Android), ripple vẫn bó trong hình pill, có sẵn vai trò "button" cho VoiceOver/TalkBack.

| | `onDark: true` (chưa nơi nào dùng) | `onDark: false` (Setup, Profile) |
|---|---|---|
| Nền pill | trắng .18 | `accentRose` .12 |
| Icon | trắng .90, 14 | `accentRose`, 14 — trang trí vì đứng cạnh nhãn |
| Chữ | trắng .90, 12 w600 | **`textPrimary`**, 12 w700 (bản cũ chữ rose chỉ 2,8:1) |
| Hình | r12 · cao 36 · padding ngang 12 (iconOnly: 36×36) | như trái |
| Ripple | trắng .12 | rose .08 |

- Mỗi pill có 6pt đệm vô hình trên/dưới nên cụm chiếm 48 thay vì ~32. Bớt khoảng cách quanh cụm cho mắt thấy như cũ: Setup mã → cụm 10 → 4, cụm → mô tả 8 → 2; Profile value → cụm 10 → 4.
- `iconOnly`: `IconButton(tooltip: inviteQrBtn)` — tooltip cũng là nhãn đọc màn hình.
- Tap → mở sheet QR (4c). Analytics `invite_shared` với method `qr` (không log mã). Huỷ mốc nhắc 2 giờ (PF10).
- Vì sao Iconsax `scan_barcode` chứ không `Icons.qr_code_2_rounded`: giữ đúng bộ icon chính (Iconsax Linear) cạnh copy/share; nhãn "Mã QR" đã nói rõ nghĩa. Iconsax không có glyph QR riêng.
- Hiện khi nào: theo guard sẵn có của cụm (Setup `showInviteActions`, Profile khi `isWaitingForPartner`). Không thêm điều kiện.

#### 4b. Thẻ chờ Home
- Thay khối `Align(… Sao chép mã)` bằng `Wrap(spacing: 8, runSpacing: 8)` gồm 2 pill tonal giống hệt nhau: [Sao chép mã] [Mã QR]. Nên tách 1 hàm dựng pill dùng chung cho 2 nút.
- Pill tonal giữ dáng pill "Sao chép mã" đang có (nền `accentRose` .12, r999, padding ngang 14, icon 14 `accentRose`, cách 6, chữ 13 w700) nhưng dựng bằng `TextButton.icon` cao 36, `tapTargetSize: padded` (vùng chạm 48), **chữ đổi sang `textPrimary`** (rose trên nền rose .12 chỉ 2,8:1). Pill QR: icon `IconsaxPlusLinear.scan_barcode`, nhãn `inviteQrBtn`.
- Khoảng từ nút "Gửi cho người ấy 💌" xuống hàng pill: 8 → 2, vì pill đã có 6pt đệm vô hình phía trên.
- Bề rộng: 2 pill ≈ 214pt trong cột ≈ 269pt (máy 375) → 1 hàng, thẻ không cao thêm. Nút "Gửi cho người ấy 💌" giữ vị trí nút chính.
- Đổi chữ `homeWaitingStep1Desc` cho người ta biết có QR (key này dùng chung ở Setup, nơi cụm nút cũng có QR → vẫn đúng).
- QR encode đúng mã đang hiện ở thẻ (`coupleCode`, thiếu thì `inviteCode`).

#### 4c. Sheet QR (W8)
- **Khung sheet chuẩn**, chép từ `FeatureTourSheet`: `showModalBottomSheet(isScrollControlled: true, backgroundColor: Colors.transparent)`; Container nền `cardSurface` #FFFFFF, bo trên r28, padding (20, 12, 20, 20) + `SafeArea(top: false)`. Không cần `BackdropFilter`: nền đặc nên blur không thấy được (StreakSheet có blur nhưng nhìn y hệt).
- Thứ tự: handle 40×4 `textTertiary` α .4 r999 → 18 → title `inviteQrTitle` (`AppTheme.displaySerif(size: 20, weight: w700, letterSpacing: -0.2)`, căn giữa) → 6 → body `inviteQrBody` (14 w500 `textSecondary`, height 1.45, căn giữa) → 20 → khối QR → 16 → mã chữ (30 w900 ls4 `accentLoveDeep`, căn giữa — y mã ở Setup) → 6 → `inviteQrFallback` (12 `textSecondary`, căn giữa) → 20 → `ElevatedButton(inviteQrDone)` theo theme (navy, h52, pill), `pop`.
- Nội dung bọc `SingleChildScrollView`, sheet cao tối đa 90% màn hình: chữ cỡ lớn nhất trên máy cao 667pt không bị tràn. Handle bọc `ExcludeSemantics`.
- **Khối QR:** `ContentCard(radius: 24, padding: EdgeInsets.all(20))` bọc QR 220×220, căn giữa (thẻ rộng 260).
- **QR:**
  - Dữ liệu: `https://dearembeiu.com/get?code=<MÃ>`, đúng link trong `inviteShareMessage`, mã in hoa, không thêm `lang` hay tham số khác (trang tự chọn ngôn ngữ theo máy người quét).
  - Mức sửa lỗi M; module vuông, không hở (gapless); không logo ở giữa.
  - Màu module + 3 ô mắt: `textPrimary` #1A1A2E. Nền trắng.
  - Link 37 ký tự → QR phiên bản 3 (29×29) → mỗi ô ≈ 7,6pt, camera đọc dễ ở 20–40cm. Không viền quanh thẻ, padding 20 nối liền nền trắng của sheet nên vùng trắng quanh mã đủ rộng.
  - Semantics: image, label `inviteQrSemantics(code)`.
- Không làm: tăng độ sáng màn hình, nút chia sẻ trong sheet (cụm nút đã có), đếm ngược.

### 5. Gợi ý mã từ bộ nhớ tạm ở Setup (PF9)

- **Khi nào kiểm tra:** Setup chế độ tạo (không phải sửa), đã đăng nhập, chưa có couple. Sau frame đầu + 500ms, để màn đứng yên rồi mới có hộp hệ thống.
- **Điều kiện hiện sheet:** bộ nhớ tạm có link khớp `dearembeiu.com/get?…code=XXXXXX`; mã khác mã của chính mình; mã chưa từng được hỏi (Hive).
- **Không hỏi lại hộp "Cho phép dán":** iOS chỉ đọc khi `detectPatterns` báo có URL **và** `UIPasteboard.changeCount` khác lần đọc trước (lưu Hive). Một nội dung bộ nhớ tạm không bao giờ làm hiện hộp hệ thống lần hai, kể cả khi nó không phải link mời.
- **Sheet (W9):** khung như 4c. Handle → 20 → đĩa 64 nền `accentLove` α .14 + `IconsaxPlusBold.heart` 30 `accentLove` (y đĩa icon của `MemoriesSheet`) → 14 → title `clipboardInviteTitle` (20 w700 `displaySerif`, căn giữa) → 6 → body `clipboardInviteBody` (14 w500 `textSecondary`, căn giữa) → 18 → hộp mã (padding ngang 20 dọc 10, nền `accentLove` α .10, r16; chữ 30 w900 ls4 `accentLoveDeep`) → 20 → nút chính `clipboardInviteJoin` (`ElevatedButton` theo theme: navy, h52, pill — chữ trắng trên rose chỉ 3,2:1, xem Soát UX; navy cũng là nút chính của các sheet khác như "Đã hiểu" ở feature tour) → 8 → `TextButton(clipboardInviteSkip)` (14 w600 `textSecondary`).
- **Ghép đôi ngay:** đóng sheet → `setState(_mode = join; ô mã = code)` (pill trượt 260ms có sẵn) → chờ 300ms để người dùng thấy mã đã vào ô → gọi `_submitJoin()` có sẵn → overlay `connectingCouple` ("Đang ghép đôi...") → Lottie → Home. Không vẽ trạng thái chờ riêng trong sheet.
- **Lỗi khi ghép** (`CoupleException`: mã sai, hết hạn, người ấy chưa tạo không gian): SnackBar như hiện tại. Người dùng ở lại tab "Tham gia bằng mã", ô mã còn nguyên để sửa hoặc thử lại.
- **Bỏ qua / vuốt xuống / chạm ra ngoài:** đóng, ghi mã vào Hive, không SnackBar. Vẫn điền sẵn mã vào ô ở tab "Tham gia bằng mã" (không chuyển tab, không ghép): ai lỡ tay vuốt mất sheet thì chỉ cần bấm tab là thấy mã. Nhãn là "Bỏ qua" chứ không "Để sau", vì từ chối thì mã đó không được hỏi lại (PF9) — "Để sau" hứa điều app không làm.

### 6. Trang `docs/get.html` (PF8)

Giữ nguyên toàn bộ CSS. Chỉ đổi chữ và thêm hành vi:

- **Chép link:** khi có mã, bấm `#iosBtn` / `#androidBtn` → chép `https://dearembeiu.com/get?code=<MÃ>` ngay trong sự kiện click. Dùng link dựng từ mã đã kiểm tra, không dùng `location.href` (có thể dính `lang` hay tham số theo dõi). Không `preventDefault`, điều hướng sang store chạy như cũ.
- **Câu hướng dẫn:** có mã + điện thoại → hiện `#redirectNote` với chữ `copyHint`. Thẻ này đang rảnh khi có mã, vì nhánh tự chuyển store chỉ chạy khi không có mã; cùng vị trí, cùng style nên không cần thẻ mới.
  - Chép xong → đổi chữ thành `copyHintDone`; chép lỗi → `copyHintFail`.
  - Chữ giữ nguyên, không tự ẩn. **Không dùng toast:** trang chuyển sang store gần như tức thì, toast không ai kịp đọc. Chữ nằm yên trên trang thì người quay lại Safari vẫn thấy.
- **`#subNote`:** có mã + điện thoại → `subNoteAuto`; còn lại → `subNote`. Bản cũ ghi "Nhập mã mời", trong app không có nút tên đó; bản mới dùng đúng nhãn tab "Tham gia bằng mã" / "Join with code".
- **`subNoteAuto` bảo "nhập mã", không bảo "dán mã":** sau khi bấm tải, bộ nhớ tạm đang chứa cả link chứ không chỉ 6 ký tự.
- **[nên] Một nút store:** có mã + điện thoại → chỉ hiện nút đúng nền tảng (iPhone ẩn Google Play, Android ẩn App Store). Desktop giữ 2 nút. Bớt một nút bấm nhầm, trang ngắn lại.
- Không có mã: giữ nguyên luồng tự chuyển store sau 1,2 giây.

### 7. Lời nhắc mời (PF10)

| Mốc | Điều kiện | Title | Body |
|---|---|---|---|
| +2 giờ | chưa bấm Gửi / Sao chép / QR | `inviteFollowUpTitle2h` (mới) | `inviteFollowUpBody2h` (mới) |
| +20 giờ | còn chờ | `inviteFollowUpTitle` (giữ) | `inviteFollowUpBody24h` (giữ) |
| +72 giờ | còn chờ | `inviteFollowUpTitle` (giữ) | `inviteFollowUpBody72h` (giữ) |

- Mốc 2 giờ cần title riêng. Lúc đó người dùng có thể chưa gửi gì, mà câu cũ "Người ấy chưa vào nè" ngụ ý người ấy đã nhận lời mời. Title mới nói việc cần làm; body chỉ đúng 2 cách theo dữ liệu "ngồi cạnh nhau hoặc đang nhắn tin".
- Mốc 20 giờ dùng lại `inviteFollowUpBody24h`: chữ "Gửi lại lời mời cho người ấy nha, chỉ mất 10 giây" không nhắc số giờ nên vẫn đúng. Giữ tên key cho khỏi đổi 2 ARB + code; thêm `description` ghi rõ nay chạy ở mốc 20 giờ.
- Không câu nào nhắc giờ trong ngày, nên dời mốc đêm sang 08:30 không làm sai chữ.

### Đề xuất bổ sung design system

Designer không sửa `project/design-system.md` trong phiên này. PO ghi bổ sung khi merge:

1. **Token `AppColors.appleBlack = Color(0xFF000000)`**, chỉ dùng cho nút Apple. Ghi rõ `AppColors.black` là navy #1A1A2E để khỏi nhầm.
2. **Ngoại lệ icon:** `Icons.apple` (Material) cho logo Apple, vì Iconsax không có logo thương hiệu. Thêm vào danh sách ngoại lệ ở CLAUDE.md §3, cạnh `Icons.favorite` và `Icons.check_rounded`.
3. **Ngoại lệ phông:** chữ trong nút Apple dùng font hệ thống iOS (`CupertinoSystemDisplay`) cho giống nút Apple chuẩn. Toàn app vẫn Quicksand.
4. **Khung sheet chuẩn** (đang có ngầm ở 6 sheet): nền `cardSurface` bo trên r28, padding 20/12/20/20 + SafeArea, handle 40×4 `textTertiary` α .4, title `displaySerif` 20 w700. Sheet nền đặc thì bỏ BackdropFilter.
5. **Pill hành động nhỏ** (cụm mời, thẻ chờ Home): hình cao 36, vùng chạm 48 nhờ `tapTargetSize: padded` của nút Material, chữ `textPrimary`, nền + icon giữ tông hồng. Áp cho pill mới về sau.
6. **Nợ tương phản toàn app:** chữ trắng 15 w600–700 trên nút `accentLove` chỉ 3,2:1 (chưa đủ 4,5:1 cho chữ thường). Feature này không sửa các nút rose có sẵn; chỉ chọn navy cho nút chính của sheet mới.

## States

| Khu vực | Empty / ẩn | Loading | Error | Success | Disabled |
|---|---|---|---|---|---|
| Nút Apple | Android, Firebase chưa sẵn sàng → không render | spinner trắng 20 trong nút | SnackBar (mục 2); huỷ = im lặng | authGate → Setup / Home | Opacity .5 khi nút email đang chạy |
| Xoá tài khoản Apple | — | overlay toàn màn + sheet Apple | SnackBar như cũ; recent-login → dialog biến thể Apple | landing | nút dialog → spinner 18 khi đang chạy |
| Pill "Mã QR" | ẩn theo guard của mã mời | không có | không có | mở sheet | không có |
| Sheet QR | không mở khi mã rỗng (guard) | không có | không có | — | — |
| Gợi ý mã (Setup) | không URL / không khớp / mã của mình / đã hỏi → không hiện gì | overlay "Đang ghép đôi..." | SnackBar, ở lại tab Tham gia, ô mã còn nguyên | Lottie → Home | — |
| Trang get | không mã → luồng cũ | — | `copyHintFail` | `copyHintDone` | — |
| Nhắc mời | đã bấm Gửi/Sao chép/QR → mất mốc 2 giờ; quá 7 ngày hoặc người ấy vào → không còn nhắc | — | — | — | — |

## Interaction & animation

- **Không thêm animation mới.** Reduce Motion không bị ảnh hưởng.
- Ripple: InkWell theo luật chung (trắng .12 trên nút đen, rose .08 trên nền sáng).
- Spinner trong nút: đổi tức thì, y nút Đăng nhập / Tạo tài khoản hiện tại.
- Sheet QR và sheet gợi ý mã: chuyển động mặc định của `showModalBottomSheet`.
- Setup sau khi đồng ý ghép: pill tab trượt 260ms `easeInOutCubic` (có sẵn) → chờ 300ms → `_submitJoin()`.
- Sheet gợi ý mã xuất hiện sau frame đầu của Setup + 500ms.
- Haptic: `lightImpact` khi bấm Apple và "Ghép đôi ngay"; `heavyImpact` khi lỗi (y Đăng nhập); không haptic khi huỷ.

## Copy (song ngữ)

### Key MỚI

| Key | VI | EN |
|-----|----|----|
| `continueWithApple` | Tiếp tục với Apple | Continue with Apple |
| `appleConsentPrefix` | Khi tiếp tục với Apple, bạn đồng ý với | By continuing with Apple, you agree to our |
| `authOrDivider` | hoặc | or |
| `appleSignInFailed` | Chưa đăng nhập được với Apple. Bạn thử lại nhé. | Couldn't sign in with Apple. Please try again. |
| `appleEmailHasPasswordAccount` | Email này đã có tài khoản. Đăng nhập bằng mật khẩu nhé. | This email already has an account. Sign in with your password instead. |
| `deleteAccountAppleNote` | Sau đó Apple sẽ hiện hộp đăng nhập để xác nhận đó là bạn. | Apple will then show a sign-in sheet to confirm it's you. |
| `deleteAccountReauthBodyApple` | Vì lý do bảo mật, bạn xác nhận lại với Apple để xoá tài khoản vĩnh viễn. | For your security, confirm with Apple again to permanently delete your account. |
| `inviteQrBtn` | Mã QR | QR code |
| `inviteQrTitle` | Cho người ấy quét mã này | Let them scan this code |
| `inviteQrBody` | Người ấy mở Camera, hướng vào mã là tới trang tải Dear Embeiu, có sẵn mã mời của bạn. | They open their Camera and point it here to get Dear Embeiu, with your invite code ready. |
| `inviteQrFallback` | Không quét được? Đọc mã này cho người ấy nhập. | Can't scan? Read this code out for them to type in. |
| `inviteQrDone` | Xong | Done |
| `inviteQrSemantics` (placeholder `{code}`) | Mã QR mời ghép đôi, mã {code} | Invite QR code, code {code} |
| `clipboardInviteTitle` | Nhập mã từ lời mời? | Use the code from your invite? |
| `clipboardInviteBody` | Link mời bạn mở có mã này. Ghép đôi là vào chung không gian với người ấy. | The invite link you opened has this code. Pair up to join your partner's space. |
| `clipboardInviteJoin` | Ghép đôi ngay | Pair up now |
| `clipboardInviteSkip` | Bỏ qua | Skip |
| `inviteFollowUpTitle2h` | Gửi lời mời cho người ấy nhé 💌 | Send your partner the invite 💌 |
| `inviteFollowUpBody2h` | Đang ở cạnh nhau thì cho người ấy quét mã QR, ở xa thì gửi qua tin nhắn. Mất chừng 10 giây thôi. | Together right now? Let them scan the QR code. Apart? Send it in a message. It takes about 10 seconds. |

Ghép dòng đồng ý: `appleConsentPrefix` + " " + `privacyPolicyLabel` + "." → VI "Khi tiếp tục với Apple, bạn đồng ý với Chính sách bảo mật." · EN "By continuing with Apple, you agree to our Privacy Policy." (Không để dấu cách cuối trong ARB.)

### Key ĐỔI nội dung

| Key | VI (mới) | EN (mới) |
|-----|----|----|
| `guestCtaSignIn` | Đăng nhập bằng email *(cũ: Đăng nhập)* | Sign in with email *(cũ: Sign in)* |
| `homeWaitingStep1Desc` | Gửi mã qua tin nhắn, hoặc cho người ấy quét mã QR nếu đang ở cạnh nhau. *(cũ: Gửi mã mời này cho người ấy qua tin nhắn.)* | Send the code in a message, or let them scan the QR code if you're together. *(cũ: Send this invite code to your partner in a message.)* |
| `inviteFollowUpBody24h` | giữ chữ — chỉ thêm `description`: chạy ở mốc 20 giờ (PF10) | giữ chữ — như trái |

### Key DÙNG LẠI (không tạo mới)

| Key | VI | EN |
|-----|----|----|
| `privacyPolicyLabel` (phần link) | Chính sách bảo mật | Privacy Policy |
| `signIn` (SnackBarAction PF6) | Đăng nhập | Sign in |
| `authNetworkError` | Mạng đang chập chờn. Bạn kiểm tra kết nối rồi thử lại nhé. | (giữ bản EN hiện có) |
| `connectingCouple` (overlay ghép) | Đang ghép đôi... | Connecting couple... |
| `deleteAccountDialogTitle` / `deleteAccountDialogContent` / `deleteAccountConfirmBtn` / `cancel` | giữ | giữ |
| `deleteAccountReauthTitle` / `deleteAccountSessionExpiredMsg` / `deleteAccountFailed` | giữ | giữ |
| `inviteFollowUpTitle` / `inviteFollowUpBody72h` | giữ | giữ |

### Trang `docs/get.html` — object `COPY` (không phải ARB)

| Key | VI | EN |
|-----|----|----|
| `msgWithCode` (đổi) | Người ấy mời bạn cùng lưu giữ kỷ niệm trên Dear Embeiu 💞 Tải app và đăng ký, mã bên dưới sẽ ghép đôi hai bạn. | Your partner invited you to keep memories together on Dear Embeiu 💞 Get the app and sign up, and the code below pairs you two. |
| `copyHint` (mới) | Bấm tải là mã được chép sẵn. Cài xong mở app là có. | Tap download and your code is copied. Open the app after installing and it's there. |
| `copyHintDone` (mới) | Mã đã được chép sẵn ✓ Cài xong mở app là có. | Code copied ✓ Open the app after installing and it's there. |
| `copyHintFail` (mới) | Chưa chép được mã. Nhớ mã ở trên để nhập trong app nhé. | Couldn't copy the code. Keep the code above handy to type in the app. |
| `subNoteAuto` (mới) | App không hỏi mã? Chọn “Tham gia bằng mã” rồi nhập mã ở trên. | App didn't ask? Pick “Join with code” and type the code above. |
| `subNote` (đổi) | Cài xong, mở app, đăng ký rồi chọn “Tham gia bằng mã” để ghép đôi nhé. | After installing, open the app, sign up, then pick “Join with code” to pair. |

Các key còn lại của `COPY` giữ nguyên.

## Handoff / Dev notes

1. **`lib/widgets/apple_sign_in_button.dart` (mới):** `AppleSignInButton({VoidCallback? onPressed, bool busy = false})`, vẽ nút + dòng đồng ý theo mục 1. Màn gọi tự kiểm tra iOS + `isUsingFirebase` trước khi đặt vào cây.
2. **`lib/theme/app_colors.dart`:** thêm `appleBlack` (#000000).
3. **`guest_counter_screen.dart` `_buildCtaCard` (~dòng 429):** sau `SizedBox(height: 16)` dưới `guestCtaBody`, chèn `AppleSignInButton` + `SizedBox(height: 14)` trước Row nút. ⚠️ Đầu file ghi màn này "No Provider, no Auth". Nút Apple cần `context.read<AuthProvider>()` (lúc bấm) và `isUsingFirebase` (để ẩn/hiện) — cập nhật comment cho khớp.
4. **`login_screen.dart` `_buildFormCard`:** giữa nút Đăng nhập (SizedBox h52) và `SizedBox(height: 14)` trước Wrap "Chưa có tài khoản?", chèn: 18 · divider · 18 · `AppleSignInButton`.
5. **`register_screen.dart` `_buildFormCard`:** đầu Column, trước `Text(l10n.displayNameLabel)`: `AppleSignInButton` · 18 · divider · 18.
6. **Divider "hoặc":** dùng ở 2 màn (4, 5). Có thể để trong `apple_sign_in_button.dart` cho gọn file.
7. **Cờ "nút nào đang chạy":** xem cảnh báo cuối mục 1. Nút email và nút Apple không được cùng hiện spinner.
8. **`settings_screen.dart`:** `_showDeleteAccountDialog` (~dòng 1011) thêm đoạn `deleteAccountAppleNote` cho tài khoản Apple và rẽ sang luồng Apple khi bấm xác nhận; nhánh `requires-recent-login` (~dòng 1040) của tài khoản Apple mở biến thể Apple của `_showReauthToDeleteDialog` (không `TextFormField`, body `deleteAccountReauthBodyApple`).
9. **`invite_action_buttons.dart`:** `Row` → `Wrap(spacing 8, runSpacing 8)`; `_Pill` dựng lại bằng `TextButton.icon` / `IconButton` (`tapTargetSize: padded`, hình cao 36, chữ `textPrimary`); thêm pill thứ 3 (mục 4a); bớt khoảng cách quanh cụm ở `setup_screen._buildInviteCard` và `profile_screen._buildDetailTile` như mục 4a; cập nhật comment đầu class (hiện ghi "Copy | Share").
10. **`lib/widgets/invite_qr_sheet.dart` (mới):** `InviteQrSheet.show(context, code:)` theo mục 4c. Chưa có package QR trong `pubspec` — Dev chọn (`qr_flutter` phổ biến nhất, thuần Dart); spec màu/kích thước áp được cho thư viện nào cũng vậy. Nên gom base URL `https://dearembeiu.com/get` vào `AppUrls` để QR và regex PF9 dùng chung (link trong ARB `inviteShareMessage` vẫn hard-code, đừng để 2 nơi lệch nhau).
11. **`home_screen.dart` `_buildWaitingForPartnerBanner` (~dòng 2210–2246):** thay `Align(… Sao chép mã)` bằng `Wrap` 2 pill `TextButton.icon` cao 36, chữ `textPrimary` (mục 4b); `SizedBox(height: 8)` phía trên đổi thành 2. Bấm QR cũng log analytics + huỷ mốc 2 giờ như Sao chép.
12. **`setup_screen.dart`:** kiểm tra bộ nhớ tạm sau frame đầu + 500ms khi `!isEditing`; sheet gợi ý (inline hoặc file riêng, tuỳ Dev); đồng ý → `setState(_mode = _SetupMode.join; _inviteCodeController.text = code)` → `Future.delayed(300ms)` → `_submitJoin()` (~dòng 261). Bỏ qua / vuốt mất sheet: vẫn gán `_inviteCodeController.text = code`, không đổi `_mode`. **Nên có:** người dùng tự dán cả link vào ô mã thì tách lấy 6 ký tự bằng chính regex PF9 — trang get giờ chép link chứ không chép mã.
13. **`docs/get.html`:** đổi `COPY` (vi + en), gắn click cho 2 nút store, dùng `#redirectNote` cho câu hướng dẫn, đổi `#subNote` theo mục 6. Muốn ẩn nút store sai nền tảng thì đưa phần nhận diện iOS/Android ra ngoài hàm `routeByPlatform`. Nhớ đẩy lên nhánh `phase3` (overview §5).
14. **`reminder_provider.dart` `refreshInviteFollowUps` (~dòng 1348) + `reminder_service.dart` `scheduleInviteFollowUps`:** mốc 2 giờ dùng `inviteFollowUpTitle2h` / `inviteFollowUpBody2h`; mốc 20 và 72 giờ dùng title + body cũ.
15. **ARB:** thêm 19 key mới + đổi 2 key ở cả `app_en.arb` và `app_vi.arb`, `inviteQrSemantics` khai báo placeholder `code` (String) trong `@inviteQrSemantics`; chạy gen-l10n bằng toolchain đúng của máy.
16. **[nên] `AppUrls.privacyPolicy`:** đang trỏ `tuandda98.github.io/...` (301 sang dearembeiu.com). Bản 1.8.0 đã đổi link chính sách trên 2 store sang `https://dearembeiu.com/privacy-policy.html`; đổi hằng cho khớp, dòng đồng ý mới cũng dùng hằng này.

## Rủi ro đã biết / để sau

- **Người dùng email cũ bấm Apple** bằng Apple ID khác email, hoặc chọn "Ẩn email", sẽ có tài khoản mới trống. Đã giảm bằng: Apple nằm dưới form ở màn Đăng nhập, landing đổi nhãn "Đăng nhập bằng email", PF6 bắt ca trùng email. Phần còn lại cần theo dõi bằng analytics sau khi phát hành.
- **Android 12+** hiện toast "đã dán từ bộ nhớ tạm" mỗi lần vào Setup khi bộ nhớ tạm có chữ (Android không có `changeCount`). Android chỉ 5% người dùng và ít người vào Setup nhiều lần — chấp nhận.
- **Logo Apple** dùng `Icons.apple` thay vì file logo của Apple Design Resources. Nếu App Review góp ý thì thay bằng asset chính thức, khung nút giữ nguyên.
- **Email ẩn `…@privaterelay.appleid.com`** sẽ hiện nguyên ở Cài đặt → Tài khoản. Để sau.

## Soát UX (UI UX Pro Max)

Chỉ dùng phần checklist, không dùng để đổi phong cách, màu hay phông. Nguồn: `search.py --domain ux` (touch target, accessible label, loading feedback, contrast small text, confirmation dialog destructive, modal close, error recovery, disabled state) + `pro-rules.md` (Pre-Delivery Checklist) + `quick-reference.md` §1, §2, §8. Ba truy vấn "bottom sheet dismiss", "clipboard paste permission", "sign in with apple button" không khớp dữ liệu nào → dùng `modal-escape` (§9) và HIG đã ghi ở mục 1.

Tương phản đo ở điểm tối nhất của nền form: kính trắng .16 trên dawn3 #C8A8E9 (≈ #D1B6EC).

| Quy tắc | Hiện trạng | Quyết định |
|---|---|---|
| **Nút Apple** · touch-target-size ≥ 44pt / 48dp | cao 52, rộng full | Đạt |
| color-contrast · chữ trên nút | trắng trên #000 = 21:1 | Đạt |
| color-contrast · dòng đồng ý chữ 12 | bản nháp navy .62 = 3,8:1 (`textSecondary` 2,9:1, rose 1,8:1) | Đổi navy .80 = 6,0:1; link navy đặc 9,4:1 (mục 1) |
| color-contrast · nhãn "hoặc" chữ 12 | navy .55 = 3,2:1 | Đổi navy .80 |
| touch-target-size · link trong dòng đồng ý | 1–2 dòng chữ 12 ≈ 25–43pt | Vùng chạm cao tối thiểu 44 |
| loading-buttons · accessible busy status | spinner trong nút, nút khác khoá | Đạt; thêm `enabled: false` + spinner ẩn khỏi cây trợ năng; khung 52 giữ nguyên nên bố cục không nhảy |
| correct brand logos | `Icons.apple` (Material, vector, đúng hình) | Giữ theo yêu cầu lead; App Review góp ý thì thay file logo chính thức của Apple, khung nút không đổi. ⚠️ 2026-10-12: HIG ghi rõ "Use only the logo artwork downloaded from Apple Design Resources; never create a custom Apple logo" → thay trước release (checklist CLAUDE.md §13) |
| **Cặp nút Apple + Google** (soát 2026-10-12, Lead) · `font-scale` + `text-styles-system` | Apple 22 w600 · Google 17 w500 (17 nằm ngoài type scale), 2 nút đứng sát nhau nhìn lệch rõ | Một kiểu chữ chung trong `_SocialButton`: iOS SF Pro Display **22 w500**, logo Apple 24 / G 22, cách 10. Không hạ Apple xuống: HIG đòi chữ = 43% chiều cao và nút Apple không nhỏ hơn nút đăng nhập khác (nút email cao 52). Google cho "scale the button as needed". Android chỉ có Google: Roboto **18** w500 (tỉ lệ 14/40 của Google, có trong type scale) |
| **Pill "Mã QR" + cụm mời + 2 pill thẻ chờ Home** · touch-target-size | pill cao ≈ 30–35pt (padding 8–9 + icon 14), bản iconOnly ≈ 30 | `TextButton.icon` / `IconButton` với `tapTargetSize: padded`: hình cao 36, vùng chạm 48×48, ripple bó trong hình; bớt khoảng cách quanh cụm 6pt để cụm không phình (mục 4a, 4b) |
| touch-spacing ≥ 8 | ngang 8 | Đạt; khi Wrap xuống dòng, `runSpacing` 8 giữa hai hàng vùng chạm |
| color-contrast · chữ pill 12–13 | chữ rose trên nền rose .12 = 2,8:1 (lỗi có từ Copy/Share) | Chữ navy `textPrimary` (≈ 14,8:1), nền và icon giữ hồng. Áp luật sẵn có của design system "chữ nhỏ dùng textPrimary" |
| chip-collection-reflow | 3 pill tràn tile Profile ở máy 375 | Wrap trước khi thu chữ (mục 4a) |
| aria-labels · icon-only | `Tooltip` bọc InkWell trần, không có vai trò button | `IconButton(tooltip:)` / `TextButton` có sẵn nhãn và vai trò button |
| **Sheet QR** · modal-escape | handle, vuốt xuống, chạm ngoài, nút "Xong" | Đạt |
| alt-text · ảnh có nghĩa | QR có label `inviteQrSemantics(code)` | Đạt; handle ẩn khỏi cây trợ năng |
| dynamic-type | Column cố định, chữ cỡ lớn có thể tràn ở máy cao 667pt | Bọc `SingleChildScrollView`, sheet tối đa 90% chiều cao màn |
| color-contrast · chữ phụ / mã | `textSecondary` trên trắng 5,2:1; mã `accentLoveDeep` 30 w900 = 4,1:1 (chữ lớn chỉ cần 3:1) | Đạt |
| **Sheet gợi ý mã** · color-contrast nút chính | chữ trắng trên rose 15 w600 = 3,2:1 | `ElevatedButton` navy theo theme = 17:1 (mục 5) |
| error-recovery · lỡ tay vuốt mất sheet | mã đó không bao giờ được hỏi lại | Vẫn điền sẵn mã vào ô ở tab "Tham gia bằng mã", không tự ghép |
| submit-feedback · error-clarity | overlay "Đang ghép đôi..."; lỗi qua SnackBar `CoupleException`, ô mã còn nguyên | Đạt |
| **Chung** · reduced-motion / dark mode | không thêm animation; app chỉ light mode | Đạt / không áp dụng |
| confirmation-dialogs · destructive-emphasis | dialog xoá giữ màu error; sheet Apple là lớp xác nhận thứ hai | Đạt |
| Ngoài 4 thành phần | chữ trắng trên các nút rose có sẵn = 3,2:1 | Không sửa trong feature này; ghi nợ ở "Đề xuất bổ sung design system" |

## Acceptance (design)

- [x] Mọi state có hình hoặc mô tả (bảng States + bảng trạng thái nút Apple + bảng kết quả xoá tài khoản)
- [x] Soát UX 4 thành phần mới bằng checklist UI UX Pro Max, đã sửa spec theo kết quả
- [x] Copy đủ VI + EN: 19 key mới, 2 key đổi, key dùng lại, chữ trang get
- [x] Token lấy từ design system; token mới duy nhất (`appleBlack`) và 2 ngoại lệ icon/phông ghi rõ lý do
- [x] Wireframe đủ 7 hạng mục (W1–W10)
- [x] Dev dựng được không cần hỏi lại: chỗ chèn theo file/hàm/dòng, thứ tự spacing, kích thước QR, luồng sau khi đồng ý ghép

## Nhật ký design
- [2026-10-11] [Designer] Thiết kế pairing-funnel theo PF1–PF10. (1) Nút "Tiếp tục với Apple" dùng chung: nền #000000 theo HIG (navy không phải kiểu Đen), pill h52, logo `Icons.apple` 24, chữ SF Display 22 w600 (~43% chiều cao), dòng đồng ý navy .62 chỉ link Chính sách bảo mật. Vị trí: landing trên hàng nút cũ (đổi nhãn "Đăng nhập bằng email"), Đăng ký trên form, Đăng nhập DƯỚI form để người dùng email cũ không tạo nhầm tài khoản Apple trống. (2) Bảng kết quả/lỗi: huỷ im lặng, PF6 SnackBar kèm action Đăng nhập. (3) Xoá tài khoản Apple: thêm câu báo trước sheet Apple, biến thể dialog xác minh không ô mật khẩu. (4) Pill "Mã QR" (Iconsax `scan_barcode`) trong `InviteActionButtons` (Row → Wrap vì tile Profile tràn ở máy 375) và cạnh "Sao chép mã" ở thẻ chờ Home; sheet QR khung chuẩn, QR 220 navy trên trắng, ECC M, mã chữ 30 w900. (5) Sheet gợi ý mã ở Setup, nút phụ "Bỏ qua", đồng ý → tab Tham gia + điền mã + 300ms → ghép; chặn hộp "Cho phép dán" lặp lại bằng `changeCount`. (6) Chữ mới cho trang get (sửa nhãn "Tham gia bằng mã", câu chép sẵn đổi trạng thái thay cho toast). (7) Lời nhắc mốc 2 giờ có title + body riêng, mốc 20 giờ giữ `inviteFollowUpBody24h`. Nêu 3 câu hỏi cho PO và 4 đề xuất bổ sung design system.
- [2026-10-11] [Designer] Soát UX 4 thành phần mới (nút Apple, pill "Mã QR", sheet QR, sheet gợi ý mã) bằng checklist UI UX Pro Max, chỉ phần UX. Sửa spec: dòng đồng ý + nhãn "hoặc" navy .62/.55 → .80 (đo 3,8:1 → 6,0:1 trên kính dawn3); link đồng ý vùng chạm 44; pill dựng bằng `TextButton.icon`/`IconButton` `tapTargetSize: padded` (hình 36, chạm 48) và chữ pill rose → navy (2,8:1 → 14,8:1); sheet QR cuộn được khi chữ to; nút chính sheet gợi ý rose → navy (3,2:1 → 17:1); vuốt mất sheet vẫn điền sẵn mã. Thêm mục "Soát UX" và 2 đề xuất design system (pill nhỏ, nợ chữ trắng trên nút rose).
- [2026-10-12] [Lead] User hỏi vì sao chữ "Continue with Apple" to hơn "Continue with Google". Nguyên nhân: nút Google thêm ở đợt 2 không qua Designer, không tra UI UX Pro Max, đặt 17 w500 (ngoài type scale) cạnh nút Apple 22 w600. Tra lại skill (`font-scale`, `text-styles-system`) + HIG + Google branding → một kiểu chữ chung: iOS SF Display 22 w500, logo Apple 24 / G 22, cách 10; Android Roboto 18 w500. Chụp so sánh trước/sau trên simulator. User chốt luật: mọi việc UI luôn tra UI UX Pro Max (luật 8 CLAUDE.md).
