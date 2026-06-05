# 🎨 Design — Auth (Đợt 1: Quên mật khẩu + Xác thực email)

> Designer sở hữu. Đọc [overview.md](overview.md) (mục 2, 2b, 4b). Bám design system (`../../../design-system.md`, mục 8). CHỈ thiết kế — không sửa `lib/`.

- **Trạng thái design:** ✅ Đã spec đầy đủ Đợt 1 (Quên mật khẩu + Xác thực email). Baseline cũ giữ ở cuối file.
- **Pattern tái dùng:** y nguyên `login_screen.dart` / `register_screen.dart` — Scaffold + `Container(gradient: AppColors.secondaryGradient)` + `SafeArea` + `Stack`; nội dung trong `Center → SingleChildScrollView(pad 20) → ConstrainedBox(maxWidth: 460) → Column` (chèn `SizedBox(height: 52)` đầu để né top-bar) gồm header (eyebrow pill + title + subtitle + optional status banner) rồi `GlassCard(borderRadius: 28)` chứa form. Top-left `IconButton(LucideIcons.arrowLeft, white)`; top-right `LanguageToggleButton`. Style helper `AppTheme.pageEyebrowStyle/pageTitleStyle/pageSubtitleStyle(alpha: 0.84)`. Input qua `_buildInputDecoration` + `_buildFieldBlock` (label rose w700 13px). Nút chính `FilledButton` nền `AppColors.accentRose`, bo 20, pad-V 16, spinner trắng khi loading.

---

## 1. Mục tiêu
- **Quên mật khẩu:** cho user tự lấy lại quyền truy cập qua email reset (Firebase `sendPasswordResetEmail`), không khoá cứng ai. Chống lộ "email nào đã đăng ký" (D-auth4).
- **Xác thực email:** gate người dùng mới (post-cutoff) phải xác thực sở hữu hộp mail trước khi vào setup/home, nhưng KHÔNG để họ kẹt (escape hatch = đăng xuất), KHÔNG chặn user cũ/Google/Apple (D-auth2).
- Cả hai phải "đồng phục" với login/register hiện có — user không cảm thấy lạc sang app khác.

## 2. Phạm vi / màn hình
| # | Màn | Route | Vai trò |
|---|-----|-------|---------|
| A | Quên mật khẩu | `/forgot-password` | Nhập email → gửi link reset. Push từ link trên Login. Có nút back (pop về Login). |
| B | Xác thực email | `/verify-email` | GATE sau đăng ký. KHÔNG có back-pop; escape hatch = Đăng xuất. |
| — | Login (sửa nhỏ) | `/login` | Thêm link "Quên mật khẩu?" dưới ô mật khẩu, canh phải. |

Ngoài phạm vi thiết kế: thay đổi logic provider/route guard (Dev lo). Designer chỉ mô tả hành vi UI mong muốn để Dev wire.

---

## 3. User flow

### Flow A — Quên mật khẩu
```
Login ──(tap "Quên mật khẩu?")──► /forgot-password (prefill email đang gõ ở login nếu có)
   nhập email → tap "Gửi email đặt lại"
        │
        ├─ isUsingFirebase = false ──► state: local-fallback (báo cần kết nối, nút disabled)
        │
        └─ isUsingFirebase = true
               ├─ email rỗng / sai định dạng ──► validator inline (không gọi mạng)
               ├─ đang gửi ──► nút loading
               ├─ lỗi mạng ──► SnackBar lỗi, giữ nguyên form (cho thử lại)
               └─ thành công (kể cả email không tồn tại — D-auth4)
                        ──► state "đã gửi": card đổi sang xác nhận (icon mail) + nút "Quay lại đăng nhập"
```

### Flow B — Xác thực email (gate)
```
Register thành công (post-cutoff, isUsingFirebase) ──► auto sendEmailVerification ──► /verify-email
   (thay vì vào thẳng setup/home)
        │
        ├─ auto-poll mỗi ~4s (reload user) + re-check khi App resumed
        ├─ tap "Tôi đã xác thực" ──► state đang kiểm tra
        │       ├─ đã verified ──► chuyển tiếp authGate (setup/home)
        │       └─ chưa ──► state "chưa thấy xác thực" (thông báo nhẹ, ở lại)
        ├─ tap "Gửi lại email" ──► gửi lại + bật cooldown 60s (đếm ngược "Gửi lại sau 0:45")
        └─ tap "Đăng xuất" (escape hatch) ──► signOut → guest/login
   User cũ (pre-cutoff) / Google / Apple ──► KHÔNG vào màn này (grandfather, D-auth2)
```

---

## 4. Wireframe ASCII

### 4.0 Login — chèn link "Quên mật khẩu?"
Đặt **ngay dưới ô mật khẩu, canh phải, TRƯỚC nút "Đăng nhập"** (chèn vào giữa `passwordField` và `SizedBox(height: 20)` của nút submit hiện tại). `TextButton` text-only, không icon, dày w700 màu `accentRose` 13px, padding gọn (visualDensity compact) để không phá nhịp khoảng cách form.
```
┌─ GlassCard (login) ───────────────────┐
│  Mật khẩu                              │
│  ┌──────────────────────────────────┐ │
│  │ 🔒  ••••••••                  👁  │ │
│  └──────────────────────────────────┘ │
│                      Quên mật khẩu? ►  │  ← TextButton align-right, rose w700
│  ┌──────────────────────────────────┐ │
│  │           Đăng nhập              │ │
│  └──────────────────────────────────┘ │
│            Mới ở đây? Tạo tài khoản    │
└────────────────────────────────────────┘
```

### 4.A Màn Quên mật khẩu — state idle
```
[←]                                  [🌐 VI]
        ┌───────────────────────────┐
        │ 🔑  KHÔI PHỤC TRUY CẬP    │  ← eyebrow pill (white .12), icon keyRound
        └───────────────────────────┘
        Quên mật khẩu?                   ← pageTitleStyle (Fraunces)
        Nhập email của bạn, mình sẽ
        gửi liên kết để đặt lại mật khẩu.← pageSubtitleStyle .84

        ┌─ GlassCard r28 ────────────────┐
        │ Email                          │ ← card heading textPrimary w800 16
        │                                │
        │ Email                          │ ← field label rose w700 13
        │ ┌────────────────────────────┐ │
        │ │ ✉  ban@email.com           │ │ ← prefix mail rose
        │ └────────────────────────────┘ │
        │                                │
        │ ┌────────────────────────────┐ │
        │ │     Gửi email đặt lại       │ │ ← FilledButton rose, bo20
        │ └────────────────────────────┘ │
        │      ‹ Quay lại đăng nhập      │ ← TextButton center
        └────────────────────────────────┘
```

### 4.A Màn Quên mật khẩu — state SENT (đã gửi)
Card thay nội dung form bằng khối xác nhận (không còn ô email + nút gửi). Hero icon trong vòng tròn tint success.
```
        ┌─ GlassCard r28 ────────────────┐
        │            ╭────╮               │
        │            │ ✉✓ │               │ ← vòng tròn 64px, tint success .14,
        │            ╰────╯               │   icon mailCheck success
        │      Kiểm tra hộp thư           │ ← title-trong-card 18 w800 textPrimary
        │                                │
        │ Đã gửi liên kết đặt lại mật     │
        │ khẩu tới ban@email.com. Mở mail,│ ← center, textSecondary 13 h1.5,
        │ bấm liên kết để đặt lại. Nhớ    │   email in đậm textPrimary w700
        │ kiểm tra cả mục spam nhé.       │
        │                                │
        │ ┌────────────────────────────┐ │
        │ │     Quay lại đăng nhập      │ │ ← FilledButton rose (về Login)
        │ └────────────────────────────┘ │
        │   Không nhận được? Gửi lại     │ ← TextButton rose, gửi lại lần nữa
        └────────────────────────────────┘
```

### 4.B Màn Xác thực email — state chờ (mặc định)
KHÔNG có nút back arrow (đây là gate). Top-left trống; top-right vẫn `LanguageToggleButton`.
```
                                     [🌐 VI]
        ┌───────────────────────────┐
        │ ✉  XÁC THỰC EMAIL         │  ← eyebrow pill, icon mailCheck
        └───────────────────────────┘
        Xác thực email của bạn           ← pageTitle
        Mình đã gửi liên kết xác thực
        tới ban@email.com.               ← subtitle, email đậm

        ┌─ GlassCard r28 ────────────────┐
        │            ╭────╮               │
        │            │ 📬 │               │ ← vòng tròn 64px tint accentRose .12,
        │            ╰────╯               │   icon mailOpen rose
        │                                │
        │ Mở email, bấm vào liên kết xác  │
        │ thực, rồi quay lại đây và bấm   │ ← center textSecondary 13 h1.5
        │ "Tôi đã xác thực".              │
        │                                │
        │ ┌────────────────────────────┐ │
        │ │     Tôi đã xác thực         │ │ ← FilledButton rose (primary)
        │ └────────────────────────────┘ │
        │ ┌────────────────────────────┐ │
        │ │  ↻  Gửi lại email          │ │ ← OutlinedButton rose, bo20
        │ └────────────────────────────┘ │   (→ "Gửi lại sau 0:45" khi cooldown)
        │                                │
        │ ────────────────────────────── │
        │          Đăng xuất             │ ← TextButton textSecondary (escape)
        └────────────────────────────────┘
```

### 4.B Màn Xác thực email — state "chưa thấy xác thực"
Sau khi bấm "Tôi đã xác thực" mà chưa verified: chèn banner cảnh báo nhẹ phía trên 2 nút (warning tint), nội dung `verifyEmailNotYet`. Hero icon + copy giữ nguyên. Banner tự ẩn khi user thao tác lại hoặc khi poll thành công.
```
        │ ┌────────────────────────────┐ │
        │ │ ⚠ Chưa thấy xác thực — bạn │ │ ← banner warning .14, icon alertCircle
        │ │   kiểm tra lại hộp thư rồi │ │   text warning-deep 12.5 h1.45
        │ │   thử lại nhé.             │ │
        │ └────────────────────────────┘ │
```

---

## 5. Spec chi tiết (token tái dùng — không token mới)

**Nền & layout:** `AppColors.secondaryGradient` (dawnBlush #FFC1CC→#E8B4D8→#C8A8E9). Pad ngoài 20, maxWidth 460, `SizedBox(height: 52)` đầu Column.

**Eyebrow pill:** `Container` pad H12/V8, fill `white .12`, viền `white .18`, radius 999, `Row(icon 14 white .92 + SizedBox 8 + Text pageEyebrowStyle)`.

**Title:** `AppTheme.pageTitleStyle()` (Fraunces serif, trắng). **Subtitle:** `pageSubtitleStyle(alpha: 0.84)`. Email nhúng trong subtitle: cùng style nhưng `fontWeight w800` + `alpha 1.0` (làm nổi địa chỉ).

**GlassCard:** `GlassCard(borderRadius: 28)` (blur 18, fill .16, viền highlight — đã có). Card heading (chỉ màn A idle): textPrimary #1A1A2E, 16, w800.

**Input:** dùng `_buildInputDecoration` + `_buildFieldBlock` y nguyên login (fill white .92, bo 20, prefix `LucideIcons.mail` rose, focus viền rose .45 w1.2, errorMaxLines 2).

**Nút chính (FilledButton):** `backgroundColor: AppColors.accentRose` (#FF4D6D), foreground white, pad-V 16, `RoundedRectangleBorder(20)`, text 15 w700. Loading → `CircularProgressIndicator(strokeWidth 2.2, white, 20×20)`.

**Nút phụ (Gửi lại — màn B):** `OutlinedButton.icon`, icon `LucideIcons.refreshCw` 18, viền `accentRose .55` w1.4, foreground accentRose, pad-V 14, bo 20, text 14 w700. Khi cooldown: disabled (`onPressed: null`), foreground `textTertiary`, label đổi sang đếm ngược.

**Hero icon tròn (state SENT / verify):** vòng 64×64, radius 999. Màn A-sent: fill `success .14` (#66BB6A), icon `mailCheck` success 30. Màn B: fill `accentRose .12`, icon `mailOpen` rose 30.

**Banner trạng thái (local-fallback / warning):** tái dùng cấu trúc `_buildStatusBanner` của login (fill white .16, viền white .18, bo 20, ô icon 38×38 tint màu .16). local-fallback → màu `warning` #FFA726 + icon `cloudOff`. "chưa thấy xác thực" → màu `warning` + icon `alertCircle`.

**Divider trước "Đăng xuất" (màn B):** `Divider` mảnh `white .0` không phù hợp trên glass → dùng `Container(height: 1, color: textTertiary .18)` margin-V 4, hoặc `SizedBox(12)` + text. (Dev chọn cách hợp GlassCard; mục tiêu: tách "Đăng xuất" khỏi 2 nút chính.)

**Link "Quên mật khẩu?" (login):** `Align(alignment: Alignment.centerRight)` → `TextButton(style: padding EdgeInsets.zero, minimumSize Size.zero, tapTargetSize shrinkWrap)` text rose w700 13. Đặt giữa password field và nút submit; `SizedBox(height: 4)` trên, `SizedBox(height: 12)` dưới (tổng nhịp ~ giữ 20 cũ).

**Spacing trong card:** heading→18→field; field→20→nút; nút→14→link phụ. Màn B: hero→16→copy→20→nút chính→12→nút gửi lại→16→divider→12→đăng xuất.

---

## 6. States

### Màn A — Quên mật khẩu
| State | UI | Copy key (chính) |
|-------|----|------------------|
| idle | Form email + nút "Gửi email đặt lại" enabled | `forgotPasswordTitle`, `forgotPasswordSubtitle`, `forgotPasswordSendBtn` |
| validating | Validator inline ô email (rỗng / sai định dạng), chưa gọi mạng | `emailRequired`, `emailInvalid` (tái dùng) |
| sending (loading) | Nút "Gửi email đặt lại" → spinner, disabled | — |
| sent (success) | Card đổi sang khối xác nhận (hero mailCheck) + nút "Quay lại đăng nhập" + link "Gửi lại" | `forgotPasswordSentTitle`, `forgotPasswordSentBody`, `forgotPasswordBackToLogin`, `forgotPasswordResendLink` |
| error (mạng) | Giữ form, SnackBar lỗi navy floating, nút enable lại | `forgotPasswordNetworkError` |
| local-fallback (disabled) | Banner warning "cần kết nối"; ô email + nút disabled | `forgotPasswordLocalFallback` |

> D-auth4: email không tồn tại vẫn rơi vào state **sent** (thông báo trung lập, không phân biệt).

### Màn B — Xác thực email
| State | UI | Copy key (chính) |
|-------|----|------------------|
| waiting (mặc định) | Hero mailOpen + copy hướng dẫn; auto-poll ngầm ~4s + re-check on resume (không spinner toàn màn) | `verifyEmailTitle`, `verifyEmailSubtitle`, `verifyEmailBody` |
| checking | Nút "Tôi đã xác thực" → spinner, disabled tạm | `verifyEmailCheckBtn` |
| not-verified-yet | Banner warning chèn trên 2 nút; ở lại màn | `verifyEmailNotYet` |
| verified (success) | (Chuyển tiếp ngay → authGate; không cần màn riêng) toast nhẹ tuỳ chọn | `verifyEmailSuccess` |
| resending | Nút "Gửi lại email" → spinner ngắn rồi vào cooldown | `verifyEmailResend` |
| cooldown | Nút "Gửi lại" disabled, label "Gửi lại sau {time}" đếm ngược 60→0 | `verifyEmailResendCountdown` |
| resend-error (mạng) | SnackBar lỗi, không vào cooldown (cho thử lại) | `verifyEmailResendError` |
| signing-out | Nút "Đăng xuất" → disabled; dùng overlay sẵn có | `signOutBtn` (tái dùng) |

> Disabled chung: nút primary/secondary `onPressed: null` khi đang có thao tác mạng (tránh double-tap).

---

## 7. Interaction / animation
- **Entrance:** KHÔNG thêm staggered animate (đồng bộ login/register hiện tại — 2 màn đó không animate vào). Giữ tĩnh, mượt.
- **Chuyển idle → sent (màn A):** `AnimatedSwitcher(duration: AppMotion.base 280ms, switchInCurve: easeOutCubic)` đổi nội dung trong GlassCard (form ⇄ khối xác nhận) — fade + slide nhẹ 8px. Card khung không nhảy size đột ngột → ưu tiên `AnimatedSize` bọc hoặc layout 2 khối chiều cao gần nhau.
- **Banner "chưa thấy xác thực":** xuất hiện bằng `AnimatedSize` + fade `AppMotion.fast 200ms`; tự ẩn khi user bấm lại hoặc poll OK.
- **Cooldown countdown:** cập nhật mỗi 1s (`Timer.periodic`), label nội suy số; khi về 0 → nút bật lại (đổi label, `AnimatedDefaultTextStyle` không cần — chỉ swap text).
- **Haptic:** `HapticFeedback.lightImpact()` khi bấm nút gửi/kiểm tra (đồng bộ login `_submit`); `heavyImpact` khi validator fail.
- **SnackBar:** navy floating bo 20 (theme sẵn).
- **Auto-poll (màn B):** `Timer.periodic ~4s` reload user + `WidgetsBindingObserver.didChangeAppLifecycleState == resumed` → check ngay (bắt case user vừa bấm link trên mail rồi quay lại app). Dừng timer khi dispose/verified. (Dev wire — Designer chỉ mô tả nhịp.)

---

## 8. Localization (vi + en) — chuỗi MỚI

> Convention: key camelCase, prefix `forgotPassword*` / `verifyEmail*`. **Tái dùng** (KHÔNG tạo mới): `emailLabel`, `emailHint`, `emailRequired`, `emailInvalid`, `signOutBtn`. Eyebrow viết HOA theo `pageEyebrowStyle` (style tự uppercase nếu có; nếu không, viết hoa trong copy như dưới).

### Màn A — Quên mật khẩu
| key | vi | en |
|-----|----|----|
| `forgotPasswordLink` | Quên mật khẩu? | Forgot password? |
| `forgotPasswordBadge` | KHÔI PHỤC TRUY CẬP | RECOVER ACCESS |
| `forgotPasswordTitle` | Quên mật khẩu? | Forgot your password? |
| `forgotPasswordSubtitle` | Nhập email của bạn, mình sẽ gửi liên kết để đặt lại mật khẩu. | Enter your email and we'll send you a link to reset your password. |
| `forgotPasswordEmailHeading` | Email | Email |
| `forgotPasswordSendBtn` | Gửi email đặt lại | Send reset email |
| `forgotPasswordBackToLogin` | Quay lại đăng nhập | Back to sign in |
| `forgotPasswordSentTitle` | Kiểm tra hộp thư | Check your inbox |
| `forgotPasswordSentBody` | Đã gửi liên kết đặt lại mật khẩu tới {email}. Mở mail và bấm vào liên kết để đặt lại. Nhớ kiểm tra cả mục spam nhé. | We've sent a password reset link to {email}. Open the email and tap the link to reset it. Don't forget to check your spam folder. |
| `forgotPasswordResendLink` | Không nhận được? Gửi lại | Didn't get it? Resend |
| `forgotPasswordNetworkError` | Không gửi được email. Kiểm tra kết nối mạng rồi thử lại nhé. | Couldn't send the email. Check your connection and try again. |
| `forgotPasswordLocalFallback` | Tính năng này cần kết nối mạng. Bạn kết nối internet rồi thử lại nhé. | This feature needs an internet connection. Please connect and try again. |

> `forgotPasswordSentBody` dùng placeholder ICU `{email}` (type String). `forgotPasswordSentTitle` cũng có thể tái dùng làm tiêu đề khối xác nhận.

### Màn B — Xác thực email
| key | vi | en |
|-----|----|----|
| `verifyEmailBadge` | XÁC THỰC EMAIL | VERIFY EMAIL |
| `verifyEmailTitle` | Xác thực email của bạn | Verify your email |
| `verifyEmailSubtitle` | Mình đã gửi liên kết xác thực tới {email}. | We've sent a verification link to {email}. |
| `verifyEmailBody` | Mở email, bấm vào liên kết xác thực, rồi quay lại đây và bấm "Tôi đã xác thực". | Open the email, tap the verification link, then come back here and tap "I've verified". |
| `verifyEmailCheckBtn` | Tôi đã xác thực | I've verified |
| `verifyEmailResend` | Gửi lại email | Resend email |
| `verifyEmailResendCountdown` | Gửi lại sau {time} | Resend in {time} |
| `verifyEmailNotYet` | Chưa thấy xác thực — bạn kiểm tra lại hộp thư rồi thử lại nhé. | Not verified yet — please check your inbox and try again. |
| `verifyEmailSuccess` | Đã xác thực! Đang đưa bạn vào... | Verified! Taking you in... |
| `verifyEmailResendError` | Không gửi lại được email. Kiểm tra kết nối rồi thử lại nhé. | Couldn't resend the email. Check your connection and try again. |
| `verifyEmailSignOut` | Đăng xuất | Sign out |

> `verifyEmailSubtitle` & `verifyEmailResendCountdown` dùng placeholder ICU (`{email}` String, `{time}` String — Dev format "0:45" trước khi truyền). `verifyEmailSignOut` có thể bỏ và tái dùng `signOutBtn` (cùng nghĩa "Đăng xuất") — đề xuất **tái dùng `signOutBtn`**, không thêm key, trừ khi Dev muốn copy riêng. Nếu tái dùng → tổng key mới giảm 1.

**Tổng chuỗi l10n MỚI: 22 key** (12 màn A + 10 màn B; mỗi key có cả vi & en). Nếu tái dùng `signOutBtn` thay `verifyEmailSignOut` → **21 key**.

---

## 9. Assets
- Không cần asset ảnh/SVG mới. Tất cả icon lấy từ `LucideIcons` (đã có package). Không cần font mới (Fraunces + Plus Jakarta Sans qua google_fonts đã wired).

### Icon đề xuất (Lucide)
| Vị trí | Icon |
|--------|------|
| Login — link Quên mật khẩu | (không icon, text-only) |
| Màn A eyebrow | `LucideIcons.keyRound` |
| Màn A input email | `LucideIcons.mail` (như login) |
| Màn A hero sent | `LucideIcons.mailCheck` |
| Màn A nút back | `LucideIcons.arrowLeft` (top-left, white) |
| Màn B eyebrow | `LucideIcons.mailCheck` |
| Màn B hero waiting | `LucideIcons.mailOpen` |
| Màn B nút gửi lại | `LucideIcons.refreshCw` |
| Banner "chưa xác thực" | `LucideIcons.alertCircle` |
| Banner local-fallback | `LucideIcons.cloudOff` (như login) |

---

## 10. Dev notes
- **Route mới:** đăng ký `/forgot-password` + `/verify-email` ở `app_routes.dart`. Màn B là gate → đưa vào nhánh `SessionResolver` (authed + email chưa verify + post-cutoff + isUsingFirebase → `/verify-email`).
- **Màn B KHÔNG có back-pop:** không đặt `IconButton(arrowLeft)` top-left; chặn system-back nuốt gate (Dev cân nhắc `PopScope(canPop: false)` để user không lọt vào setup/home khi chưa verify). Escape hatch DUY NHẤT = nút "Đăng xuất".
- **Prefill email màn A:** push từ Login truyền email đang gõ (arg route hoặc `pushNamed(..., arguments: email)`); nếu rỗng để trống. Màn B lấy email từ `currentUser.email`.
- **Cooldown 60s màn B:** bật ngay khi vào màn (vì register đã auto-gửi 1 lần) HOẶC chỉ bật sau lần "Gửi lại" đầu — đề xuất **bật cooldown ngay khi vào màn** (tránh spam gửi lại liên tục ngay sau register auto-send). State cooldown nên giữ qua resume (lưu mốc thời gian, tính lại còn bao lâu).
- **D-auth4 (anti-enumeration):** Dev KHÔNG hiện lỗi "email không tồn tại" ở màn A — mọi trường hợp gửi-không-lỗi-mạng đều vào state `sent`. Chỉ lỗi mạng/định dạng mới báo.
- **D-auth2 grandfather:** logic gate ở resolver (không phải UI). UI màn B chỉ render khi resolver đẩy tới — Designer không quyết cutoff.
- **AnimatedSwitcher form⇄sent:** tránh layout jump — bọc `AnimatedSize` hoặc giữ chiều cao 2 khối tương đương.
- **Tái dùng helper:** copy `_buildInputDecoration`, `_buildFieldBlock`, `_buildStatusBanner` từ login (cân nhắc trích ra widget chung — tuỳ Dev, không bắt buộc trong Đợt 1).
- **l10n:** thêm key vào CẢ `app_en.arb` + `app_vi.arb` rồi `fvm flutter gen-l10n`. Placeholder ICU: khai báo `placeholders` cho `forgotPasswordSentBody`/`verifyEmailSubtitle` ({email}) + `verifyEmailResendCountdown` ({time}).

---

## 11. Acceptance criteria (design)
- [ ] Login có link "Quên mật khẩu?" canh phải dưới ô mật khẩu, style rose w700, push `/forgot-password` prefill email đang gõ.
- [ ] Màn A: layout đúng pattern (gradient + glass card), nút back pop về Login, LanguageToggle góc phải, ô email tái dùng decoration login.
- [ ] Màn A state `sent`: card đổi sang khối xác nhận hero `mailCheck`, hiện email trong copy, có nút "Quay lại đăng nhập" + link "Gửi lại"; transition mượt (AnimatedSwitcher 280ms).
- [ ] Màn A: lỗi mạng → SnackBar, giữ form; local-fallback → banner warning + disabled.
- [ ] Màn B: KHÔNG có nút back-pop; có hero `mailOpen`, copy hướng dẫn, hiện email; nút "Tôi đã xác thực" + "Gửi lại email" (OutlinedButton) + link "Đăng xuất".
- [ ] Màn B cooldown: "Gửi lại" disabled + label "Gửi lại sau {time}" đếm ngược 60→0, bật lại khi hết.
- [ ] Màn B state "chưa xác thực": banner warning chèn trên nút, tự ẩn khi thao tác lại.
- [ ] Mọi chuỗi mới có đủ vi + en (21–22 key), không hardcode; placeholder ICU đúng.
- [ ] Không token màu/radius mới ngoài design system.

---

## Nhật ký design
- [2026-06-05] [Designer] Spec email giao dịch "Xác thực email" (Cách B — custom HTML qua Resend, gửi từ `noreply@dearembeiu.com`). Bám brand Sunset Romance nhưng email-safe: inline CSS + layout `<table>`, web-safe font stack (KHÔNG Fraunces/Plus Jakarta), max-width 600 card trắng trên nền `#F4F4F7`, header gradient sunset `#FF6B9D→#FFB6C1` + solid fallback Outlook, bulletproof button table nền `#FF4D6D`. Đủ ASCII mockup, bảng màu/spec, bảng copy vi+en (subject + preheader + greeting + body + button + fallback + security note + footer), ghi chú Gmail/Outlook/Apple Mail + dark-mode, placeholder `{name}`/`{verifyUrl}`. Không token mới (chọn biến thể email-safe của token có sẵn).
- [2026-06-05] [Designer] Spec Đợt 1: màn `/forgot-password` (idle/sent/error/local-fallback) + màn gate `/verify-email` (waiting/checking/not-yet/cooldown/success) + link "Quên mật khẩu?" trên Login. Tái dùng pattern login/register (gradient dawnBlush + GlassCard + helper input/banner), không token mới. Bảng 21–22 chuỗi l10n vi+en + icon Lucide từng màn. Theo D-auth2 (gate grandfather), D-auth3 (local skip), D-auth4 (anti-enumeration).

---

## Email xác thực (Cách B — custom HTML qua Resend)

> Designer sở hữu. Email **giao dịch** (transactional, không phải marketing → KHÔNG cần unsubscribe). Gửi qua **Resend** từ `noreply@dearembeiu.com`, chứa nút dẫn tới link xác thực Firebase. Khác app: KHÔNG dùng Fraunces/Plus Jakarta (mail client không load), KHÔNG flexbox/grid/external CSS. Tất cả **inline CSS + layout `<table>`**, web-safe font stack. Bám màu brand "Sunset Romance" nhưng chọn biến thể email-safe.

### E0. Mục tiêu
- Email "đồng phục" với app: dải gradient sunset, trái tim 💞, navy text — user nhận ra ngay đây là Dear Embeiu.
- **Bulletproof** trên Gmail / Outlook (desktop Word-engine) / Apple Mail / mobile. Không phụ thuộc CSS hiện đại.
- Luôn có **link fallback text** + dòng giải thích phòng nút không render.
- Một bước rõ ràng: bấm nút → xác thực. Không gây nhiễu.

### E1. Wireframe ASCII (bố cục email)

```
┌──────────────────────────────────────────────────────────┐  ← nền ngoài #F4F4F7 (full-bleed)
│                                                            │     padding-top 32px
│   [preheader ẩn: "Xác nhận email để bắt đầu lưu giữ..."]   │     (mã preview, ẩn khỏi body)
│                                                            │
│   ┌────────────────────────────────────────────────────┐  │  ← CARD trắng #FFFFFF, maxWidth 600
│   │██████████ HEADER — dải gradient sunset ███████████│  │     bo góc 16px, shadow nhẹ
│   │█                                                  █│  │
│   │█                    💞                            █│  │  ← trái tim trắng 40px (emoji/img)
│   │█              Dear Embeiu                         █│  │  ← brand 26px bold trắng, ls .5
│   │█                                                  █│  │     header padding 36px V
│   │████████████████████████████████████████████████████│  │     gradient #FF6B9D→#FFB6C1
│   ├────────────────────────────────────────────────────┤  │
│   │                                                    │  │  ← BODY pad 40px (mobile 28)
│   │   Chào Minh,                                       │  │  ← greeting 20px bold navy
│   │                                                    │  │
│   │   Chỉ còn một bước nữa để bắt đầu lưu giữ           │  │  ← body 16px navy-soft,
│   │   kỷ niệm cùng người ấy. Xác nhận email của        │  │     line-height 1.6
│   │   bạn để mở khóa không gian riêng của hai người    │  │
│   │   nhé. 💞                                          │  │
│   │                                                    │  │
│   │        ┌────────────────────────────┐              │  │  ← BULLETPROOF BUTTON (table)
│   │        │     Xác thực email          │              │  │     nền #FF4D6D, chữ trắng 16px bold
│   │        └────────────────────────────┘              │  │     bo 999/28px, pad 16×40, center
│   │                                                    │  │
│   │   ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  │  │  ← divider #EFEFF4 1px
│   │                                                    │  │
│   │   Nút không bấm được? Sao chép và mở link này       │  │  ← fallback caption 13px tertiary
│   │   trên trình duyệt:                                │  │
│   │   https://...verify...{verifyUrl}                  │  │  ← link rose 13px, word-break
│   │                                                    │  │
│   │   ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  │  │
│   │                                                    │  │
│   │   🔒 Nếu bạn không tạo tài khoản Dear Embeiu,       │  │  ← security note 13px tertiary,
│   │   cứ bỏ qua email này.                             │  │     trên nền tint hồng #FFF5F8 bo 12
│   │                                                    │  │
│   ├────────────────────────────────────────────────────┤  │
│   │              Dear Embeiu  ·  dearembeiu.com         │  │  ← FOOTER center, 13px tertiary
│   │            Lưu giữ kỷ niệm & đếm ngày yêu 💞         │  │  ← tagline 12px
│   │                © Dear Embeiu                        │  │
│   └────────────────────────────────────────────────────┘  │
│                                                            │     padding-bottom 32px
└──────────────────────────────────────────────────────────┘
```

### E2. Bảng màu + spec (email-safe)

| Vùng | Token | Hex | Ghi chú |
|------|-------|-----|---------|
| Nền ngoài (body wrapper) | bg-outer | `#F4F4F7` | xám rất nhạt, an toàn dark-mode |
| Card | card-bg | `#FFFFFF` | bo `16px`, shadow `0 6px 24px rgba(255,107,157,0.10)` |
| Header gradient | sunset | `linear-gradient(135deg,#FF6B9D 0%,#FFB6C1 100%)` | **kèm `bgcolor="#FF6B9D"` solid fallback** (Outlook bỏ gradient) |
| Brand chữ header | on-gradient | `#FFFFFF` | 26px, weight 700, letter-spacing .5px |
| Greeting | text-primary | `#1A1A2E` | 20px bold (navy brand) |
| Body text | text-body | `#3A3A4E` | 16px, line-height 1.6 (navy làm mềm cho dễ đọc dài) |
| Nút (button) | accent-love | `#FF4D6D` | nền nút; chữ `#FFFFFF` 16px bold; **kèm `bgcolor` solid** |
| Nút bo góc | — | `28px` | (tròn pill cảm giác app; dùng số cố định, không 999 để Outlook đỡ vỡ) |
| Nút padding | — | `16px 40px` | vùng chạm rộng, an toàn mobile |
| Link fallback / URL | rose | `#E63956` | 13px (accentLoveDeep — đậm hơn để contrast trên trắng), `word-break:break-all` |
| Caption / footer | text-tertiary | `#8A8A9A` | 13px (hơi đậm hơn #A0A0B0 để pass contrast) |
| Security note nền | tint-pink | `#FFF5F8` | bo `12px`, pad `14px 18px` |
| Divider | hairline | `#EFEFF4` | 1px solid |
| Tagline footer | — | `#A0A0B0` | 12px |

**Layout tokens:** max-width card `600px` (căn giữa `margin:0 auto`); header padding-V `36px`; body padding `40px` (≤480px viewport → `28px` qua media query, có fallback); footer padding `28px 40px`.

**Font stack (web-safe, KHÔNG Google Font bắt buộc):**
```
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
```
(Có thể `<link>` thử Plus Jakarta Sans cho client hỗ trợ, NHƯNG stack trên phải đứng đầu để fallback đẹp khi font không load — không bao giờ để Times New Roman lộ ra.)

### E3. Bảng copy song ngữ (mọi chuỗi)

| Phần | vi | en |
|------|-----|-----|
| **Subject** | Xác thực email cho Dear Embeiu 💞 | Verify your email for Dear Embeiu 💞 |
| **Preheader** (preview, ẩn) | Chỉ một bước nữa để bắt đầu lưu giữ kỷ niệm cùng người ấy. | Just one step left to start keeping memories with your love. |
| **Brand (header)** | Dear Embeiu | Dear Embeiu |
| **Greeting** | Chào {name}, | Hi {name}, |
| **Body** | Chỉ còn một bước nữa để bắt đầu lưu giữ kỷ niệm cùng người ấy. Xác nhận email của bạn để mở khóa không gian riêng của hai người nhé. 💞 | You're just one step away from keeping memories with your love. Confirm your email to unlock your private space for two. 💞 |
| **Button** | Xác thực email | Verify email |
| **Fallback intro** | Nút không bấm được? Sao chép và mở link này trên trình duyệt: | Button not working? Copy and open this link in your browser: |
| **Fallback URL** | {verifyUrl} | {verifyUrl} |
| **Security note** | 🔒 Nếu bạn không tạo tài khoản Dear Embeiu, cứ bỏ qua email này. | 🔒 If you didn't create a Dear Embeiu account, you can safely ignore this email. |
| **Footer line 1** | Dear Embeiu · dearembeiu.com | Dear Embeiu · dearembeiu.com |
| **Footer tagline** | Lưu giữ kỷ niệm & đếm ngày yêu 💞 | Keep your memories & count the days in love 💞 |
| **Footer copyright** | © Dear Embeiu | © Dear Embeiu |

**Placeholder Dev thay:**
- `{name}` — `displayName` của user (greeting). Nếu rỗng → bỏ tên, dùng "Chào bạn," / "Hi there,".
- `{verifyUrl}` — link xác thực Firebase (`href` của nút + hiện nguyên text ở fallback). Dùng cùng 1 URL cho cả nút và text.

### E4. Bulletproof button (mẫu cấu trúc cho Dev)

Dùng `<table>` lồng, KHÔNG `<a>` bo góc trần (Outlook bỏ border-radius CSS → thêm VML hoặc chấp nhận góc vuông trên Outlook desktop). Cấu trúc tối thiểu:

```
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center">
  <tr>
    <td align="center" bgcolor="#FF4D6D"
        style="border-radius:28px; background:#FF4D6D;">
      <a href="{verifyUrl}" target="_blank"
         style="display:inline-block; padding:16px 40px;
                font-family:-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
                font-size:16px; font-weight:700; color:#FFFFFF;
                text-decoration:none; border-radius:28px;">
        Xác thực email
      </a>
    </td>
  </tr>
</table>
```
- `bgcolor` trên `<td>` = fallback solid cho client bỏ `background`.
- Outlook desktop: góc nút sẽ vuông (chấp nhận được) — nếu cần bo góc Outlook, Dev có thể thêm VML `<v:roundrect>` (tùy chọn, không bắt buộc).

### E5. Ghi chú email-client (Dev tuân thủ khi code HTML)
- **Gmail (web/app):** cắt CSS trong `<style>` ở `<head>` đôi khi không ổn định → **inline tất cả style trọng yếu** (gradient header, màu nút, font). Gmail clip email >102KB ("[Message clipped]") → giữ HTML gọn, không nhồi.
- **Outlook desktop (Windows, Word engine):** KHÔNG hiểu `linear-gradient` → header phải có `bgcolor="#FF6B9D"` solid. KHÔNG hiểu `border-radius` → nút/card góc vuông (chấp nhận). KHÔNG `padding` trên `<a>`/`<div>` đáng tin → padding đặt trên `<td>`. Dùng `<table>` cho MỌI khối, kể cả spacing (dùng `<td height="...">` hoặc table rỗng thay `margin`).
- **Apple Mail / iOS Mail:** render tốt nhất, hỗ trợ gradient + bo góc → đây là "best case". `-apple-system` cho font đẹp native.
- **Dark mode:** một số client tự đảo màu. Tránh chữ trắng trên nền *trong suốt*; nút chữ trắng LUÔN trên nền `#FF4D6D` đặc (an toàn). Card trắng + nền ngoài `#F4F4F7` có thể bị invert nhẹ — chấp nhận, vẫn đọc được. KHÔNG dùng PNG trong suốt cho logo chữ (dùng emoji 💞 hoặc text, đỡ vỡ dark-mode).
- **Trái tim 💞:** ưu tiên emoji unicode (render mọi nơi, theo dark-mode). Nếu muốn hình → PNG nền đặc/bo sẵn, có `alt="💞"`.
- **Width:** card `width="600"` cố định trên `<table>` + `style="max-width:600px;"`; media query `@media(max-width:480px)` hạ body padding xuống 28px — NHƯNG đặt trong `<style>` head và chấp nhận client bỏ qua (layout 600px vẫn co được do table fluid `width="100%"` ở wrapper).
- **Preheader:** đặt `<div style="display:none;max-height:0;overflow:hidden;opacity:0;">` ngay sau `<body>`, theo sau bằng chuỗi khoảng-trắng zero-width (`&zwnj;&nbsp;`×N) để đẩy nội dung rác khỏi preview.

### E6. Assets
- Logo: dùng **emoji 💞 + text "Dear Embeiu"** (không cần asset ảnh — an toàn nhất). Tùy chọn nâng cấp sau: PNG heart 80×80 nền hồng đặc host trên `dearembeiu.com/email/heart.png` với `alt`.
- Không cần font file (web-safe stack).
- Link footer: `https://dearembeiu.com`.

### E7. Dev notes
- 2 bản HTML riêng theo locale (vi/en) — chọn theo `languageCode` của user (giống pattern CF push copy vi/en). Fallback **vi** nếu thiếu (đồng nhất với functions hiện tại).
- Subject + preheader cũng phải đổi theo locale.
- `{name}` HTML-escape trước khi chèn (chống injection nếu displayName chứa `<>&`).
- `{verifyUrl}` đặt nguyên vào `href` (đã là URL Firebase hợp lệ) VÀ hiện text ở fallback — cùng 1 giá trị.
- Giữ tổng HTML < 102KB (tránh Gmail clip).
- Test trước khi gửi thật: Litmus/Email-on-Acid hoặc gửi thử tới Gmail + Outlook + Apple Mail.

### E8. Acceptance criteria (email)
- [ ] Render đúng trên Gmail (web + mobile), Apple Mail, Outlook desktop (góc vuông chấp nhận, KHÔNG vỡ layout, KHÔNG mất nút).
- [ ] Header có gradient sunset trên client hỗ trợ + solid `#FF6B9D` fallback Outlook.
- [ ] Nút là table-based bulletproof, nền `#FF4D6D` chữ trắng, vùng chạm ≥ 44px cao, bấm được trên mobile, `href={verifyUrl}`.
- [ ] Có link fallback text `{verifyUrl}` + dòng "nút không bấm được, copy link" hiển thị đầy đủ.
- [ ] Có security note "nếu không tạo tài khoản... bỏ qua".
- [ ] Footer: tên app + `dearembeiu.com` + © Dear Embeiu, KHÔNG có unsubscribe.
- [ ] 2 bản vi + en đầy đủ (subject + preheader + body), chọn theo languageCode, fallback vi.
- [ ] `{name}` rỗng → fallback "Chào bạn," / "Hi there,"; `{name}` được HTML-escape.
- [ ] Dark-mode: nút chữ trắng luôn trên nền đặc, không có chữ trắng trên nền trong suốt.
- [ ] HTML < 102KB, inline CSS, table layout, web-safe font đứng đầu stack.

---

## Baseline cũ (đã ship — giữ tham chiếu)
- **splash / auth_gate:** nền `secondaryGradient` (dawnBlush), tim trắng 80px, spinner trắng; chỉ resolve route, không animation.
- **login / register:** nền gradient, header badge eyebrow + pageTitle, **form card glass** (white .22, bo 28). Field label rose w700, input bo 20 prefix icon rose, nút submit rose. LanguageToggle góc phải. Register thêm: policy disclosure clickable, checkbox điều khoản (bắt buộc tick), link privacy.
- Copy auth cũ (login/register/password/email/displayName validation) đã có vi+en trong `lib/l10n/app_*.arb`.
