# Design — Couple Code (Mã ghép đôi riêng)

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`project/design-system.md`). CHỈ thiết kế, không code.

- **Trạng thái design:** xong
- **Người/role:** Designer

---

## Mục tiêu thiết kế

Thay đổi **duy nhất một vùng nhỏ** trên `SetupScreen`: widget `_buildInviteCard` phải:
1. Khi `isWaitingForPartner = true` sau khi couple đã được tạo — hiển thị `couple.coupleCode` (mã couple) thay vì `user.inviteCode`, kèm copy hint mới giải thích đây là mã chung có thể dùng để rejoin.
2. Khi chưa có couple (chỉ có personal invite code) — giữ nguyên copy cũ.
3. Khi couple đã `active` — giữ nguyên hành vi ẩn nút copy/share.

Không thay đổi layout GlassCard, spacing, màu sắc cấu trúc, hay bất kỳ màn hình nào khác.

---

## Phạm vi màn hình

**1 widget trên 1 màn hình:** `_buildInviteCard` trong `lib/screens/setup_screen.dart`.

---

## User flow

```
[SetupScreen load]
        │
        ├─ hasInviteCode == false → _buildInviteCard không render (giữ nguyên)
        │
        └─ hasInviteCode == true
                │
                ├─ hasCreatedCoupleSpace == false
                │       → State A: Personal invite card (không thay đổi)
                │
                ├─ hasCreatedCoupleSpace == true && isWaitingForPartner == true
                │       → State B: Couple code card (THAY ĐỔI — hiện coupleCode + hint mới)
                │
                └─ hasCreatedCoupleSpace == true && isWaitingForPartner == false
                        → State C: Active couple card (không thay đổi, ẩn copy/share)
```

---

## Wireframe ASCII

### State B — Couple code card (isWaitingForPartner = true) — TRẠNG THÁI ĐỔI

```
┌──────────────────────────────────────────────────┐  ← GlassCard bo 24
│ ⏳  Gửi mã này cho người ấy để ghép đôi          │  ← title row (icon + text)
│                                                  │
│  A3K9WX                                          │  ← coupleCode 30px w900 ls4 white
│                                                  │
│  [  Sao chép  ]  [  Chia sẻ  ]                   │  ← InviteActionButtons (onDark: true)
│                                                  │
│  Đây là mã ghép đôi của hai bạn. Cả hai đều      │  ← description (12px white .65)
│  dùng mã này để kết nối lại nếu cần.             │
│                                                  │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │  ← Divider (white .15), chỉ State B
│                                                  │
│  💡 Lưu mã lại — bạn có thể dùng nó để quay      │  ← rejoin hint (12px white .50, italic)
│     lại không gian này bất cứ lúc nào.           │
└──────────────────────────────────────────────────┘
```

### State A — Personal invite card (chưa tạo couple) — KHÔNG ĐỔI

```
┌──────────────────────────────────────────────────┐
│ 🔑  Mã mời của bạn                               │
│                                                  │
│  XXXXXXX                                         │  ← user.inviteCode
│                                                  │
│  [  Sao chép  ]  [  Chia sẻ  ]                   │
│                                                  │
│  Mã mời này gắn trực tiếp với tài khoản...       │
└──────────────────────────────────────────────────┘
```

### State C — Active couple (đã ghép đôi) — KHÔNG ĐỔI

```
┌──────────────────────────────────────────────────┐
│ ❤  Mã gắn với tài khoản bạn                     │
│                                                  │
│  XXXXXXX                                         │
│                                                  │  ← Không có InviteActionButtons
│  Mã gắn với tài khoản bạn                        │
└──────────────────────────────────────────────────┘
```

---

## Spec chi tiết (token chính xác)

### Toàn bộ card — tái dùng 100% token cũ

| Thuộc tính | Giá trị |
|---|---|
| Container | `GlassCard(borderRadius: 24, padding: EdgeInsets.all(18))` |
| Nền card | Glass thật — ClipRRect + BackdropFilter blur 18 + fill white .16 + viền white highlight (GlassCard widget có sẵn) |

### Title row (dòng trên cùng)

| Thuộc tính | State A | State B (đổi) | State C |
|---|---|---|---|
| Icon | `LucideIcons.keyRound` | `LucideIcons.hourglass` | `Icons.favorite_rounded` |
| Icon color | `AppColors.white` (#FFFFFF) | `AppColors.warning` (#FFA726) | `AppColors.accentRose` (#FF4D6D) |
| Icon size | 14 | 14 | 14 |
| Title text | `yourInviteCodeTitle` | **`setupWaitingCoupleCodeTitle`** (key mới) | `inviteCodeTiedToAccount` |
| Title style | color white .80, fontSize 12.5, fontWeight w600 | idem | idem |

### Code display

| Thuộc tính | Giá trị |
|---|---|
| Text | `inviteCode` param (State A/C: `user.inviteCode`; **State B: `couple.coupleCode`**) |
| Color | `AppColors.white` (#FFFFFF) |
| fontSize | 30 |
| fontWeight | w900 |
| letterSpacing | 4 |
| Font | Plus Jakarta Sans (theme mặc định, không override) |

### InviteActionButtons

- Chỉ hiện khi `showInviteActions == true` (giữ nguyên logic: `!hasCreatedCoupleSpace || isWaitingForPartner`).
- `onDark: true` — nút Copy/Share nền navy bo pill, icon + label trắng (component `InviteActionButtons` tái dùng).
- Spacing trên: `SizedBox(height: 10)`.

### Description text (dưới InviteActionButtons)

| Thuộc tính | State A | State B (đổi) | State C |
|---|---|---|---|
| Key | `inviteCodeDialogContent` (cũ) | **`setupCoupleCodeDesc`** (key mới) | `inviteCodeTiedToAccount` |
| color | white .65 | white .65 | white .65 |
| fontSize | 12 | 12 | 12 |
| height | 1.45 | 1.45 | 1.45 |

### Rejoin hint (chỉ State B — PHẦN MỚI)

Divider + hint row nằm sau description, chỉ render khi `isWaitingForPartner == true`.

| Thuộc tính | Giá trị |
|---|---|
| Divider spacing trên | `SizedBox(height: 10)` |
| Divider | `Divider(thickness: 0.5, color: AppColors.white.withValues(alpha: 0.15))` |
| Divider spacing dưới | `SizedBox(height: 8)` |
| Row icon | `LucideIcons.info` size 12, color white .45 |
| Row spacing | `SizedBox(width: 6)` |
| Hint text key | **`setupCoupleCodeRejoinHint`** (key mới) |
| Hint color | `AppColors.white.withValues(alpha: 0.50)` |
| Hint fontSize | 11.5 |
| Hint fontStyle | `FontStyle.italic` |
| Hint height | 1.4 |

---

## States

### State A — Chưa có couple (personal invite code)
- Icon: `LucideIcons.keyRound`, color white.
- Code: `user.inviteCode`.
- Title: "Mã mời của bạn" / "Your invite code".
- Description: copy cũ giải thích mã gắn tài khoản.
- InviteActionButtons: hiện.
- Rejoin hint: **ẩn**.
- Không thay đổi gì so với code hiện tại.

### State B — Đã tạo couple, đang chờ partner (waiting_partner) — PHẦN THAY ĐỔI
- Icon: `LucideIcons.hourglass`, color `AppColors.warning` (#FFA726).
- Code: **`couple.coupleCode`** (mã couple, khác user.inviteCode).
- Title: "Gửi mã này cho người ấy để ghép đôi" / "Share this code to connect".
- Description: "Đây là mã ghép đôi của hai bạn. Cả hai đều dùng mã này để kết nối lại nếu cần." / "This is your couple's pairing code. Either of you can use it to reconnect."
- InviteActionButtons: hiện (code truyền vào là `couple.coupleCode`).
- Rejoin hint: **hiện** — "Lưu mã lại — bạn có thể dùng nó để quay lại không gian này bất cứ lúc nào." / "Save this code — you can use it to rejoin your space at any time."

### State C — Couple đã active (cả 2 đã ghép)
- Icon: `Icons.favorite_rounded`, color `AppColors.accentRose`.
- Code: `user.inviteCode` (không hiển thị nút copy/share vì mã không còn dùng để join).
- Title + Description: copy cũ "Mã gắn với tài khoản bạn".
- InviteActionButtons: **ẩn** (giữ nguyên logic cũ `showInviteActions = false`).
- Rejoin hint: **ẩn**.

### Loading state
- Không có loading riêng cho card này; nằm trong `BlockingLoadingOverlay` của toàn màn hình.

### Error state
- Nếu `couple.coupleCode` null/rỗng khi `isWaitingForPartner == true`: hiện dấu "—" ở vị trí code (giữ layout không vỡ). Dev xử lý fallback.

---

## Interaction & animation

Tất cả interaction đã có sẵn trong component, không thêm animation mới:
- **InviteActionButtons** — tap Copy → `HapticFeedback.selectionClick()` + SnackBar "Đã sao chép mã mời" (200ms easeOutCubic, token `AppMotion.fast`).
- **InviteActionButtons** — tap Share → `share_plus` native sheet.
- Card không có tap riêng; chỉ là display.
- Transition khi state thay đổi (A→B hoặc B→C): widget rebuild tự nhiên từ `setState` / `context.watch`, không cần AnimatedSwitcher (card nằm trong `SingleChildScrollView`, flash rebuild là chấp nhận được).

---

## Copy (song ngữ — bắt buộc)

Các key **mới** cần thêm vào ARB:

| Key | VI | EN |
|-----|----|----|
| `setupWaitingCoupleCodeTitle` | Gửi mã này cho người ấy để ghép đôi | Share this code to connect |
| `setupCoupleCodeDesc` | Đây là mã ghép đôi của hai bạn. Cả hai đều dùng mã này để kết nối lại nếu cần. | This is your couple's pairing code. Either of you can use it to reconnect. |
| `setupCoupleCodeRejoinHint` | Lưu mã lại — bạn có thể dùng nó để quay lại không gian này bất cứ lúc nào. | Save this code — you can use it to rejoin your space at any time. |

Các key **cũ giữ nguyên** (không đổi):

| Key | VI | EN |
|-----|----|----|
| `yourInviteCodeTitle` | Mã mời của bạn | Your invite code |
| `inviteCodeDialogContent` | Mã mời này gắn trực tiếp với tài khoản của bạn... | This code is tied to your account... |
| `inviteCodeTiedToAccount` | Mã gắn với tài khoản bạn | Code tied to your account |
| `sendToPartnerHint` | Gửi mã này cho người ấy | Send this to them |

---

## ARB entries cần thêm (sẵn sàng để Dev copy vào)

Thêm vào `app_vi.arb` và `app_en.arb` (chạy `flutter gen-l10n` sau khi thêm):

**app_vi.arb**
```json
"setupWaitingCoupleCodeTitle": "Gửi mã này cho người ấy để ghép đôi",
"setupCoupleCodeDesc": "Đây là mã ghép đôi của hai bạn. Cả hai đều dùng mã này để kết nối lại nếu cần.",
"setupCoupleCodeRejoinHint": "Lưu mã lại — bạn có thể dùng nó để quay lại không gian này bất cứ lúc nào.",
```

**app_en.arb**
```json
"setupWaitingCoupleCodeTitle": "Share this code to connect",
"setupCoupleCodeDesc": "This is your couple's pairing code. Either of you can use it to reconnect.",
"setupCoupleCodeRejoinHint": "Save this code — you can use it to rejoin your space at any time.",
```

---

## Handoff / Dev notes

1. **Signature thay đổi:** `_buildInviteCard` cần thêm param `String? coupleCode`. Khi `isWaitingForPartner == true`, dùng `coupleCode ?? inviteCode` làm giá trị hiển thị và truyền vào `InviteActionButtons`. Khi `coupleCode` null (edge case), fallback về `inviteCode` và log warning.

2. **Nguồn data:** `coupleCode` lấy từ `coupleProvider.couple?.coupleCode` (field mới sau khi Dev implement model). Tại call-site trong `build()`:
   ```
   _buildInviteCard(
     inviteCode: currentUser!.inviteCode,
     coupleCode: editingCouple?.coupleCode,        // <-- thêm mới
     hasCreatedCoupleSpace: currentUser.hasCouple,
     isWaitingForPartner: editingCouple?.isWaitingForPartner ?? false,
   )
   ```

3. **Rejoin hint block** chỉ render khi `isWaitingForPartner == true`. Cấu trúc Flutter:
   ```
   if (isWaitingForPartner) ...[
     const SizedBox(height: 10),
     Divider(thickness: 0.5, color: AppColors.white.withValues(alpha: 0.15)),
     const SizedBox(height: 8),
     Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Icon(LucideIcons.info, size: 12, color: AppColors.white.withValues(alpha: 0.45)),
         const SizedBox(width: 6),
         Expanded(
           child: Text(
             l10n.setupCoupleCodeRejoinHint,
             style: TextStyle(
               color: AppColors.white.withValues(alpha: 0.50),
               fontSize: 11.5,
               fontStyle: FontStyle.italic,
               height: 1.4,
             ),
           ),
         ),
       ],
     ),
   ],
   ```

4. **Không thay đổi:** GlassCard wrapper, padding, spacing giữa các phần tử trong card (giữ `SizedBox(height: 10)` trước `InviteActionButtons`, `SizedBox(height: 8)` trước description), `showInviteActions` logic.

5. **flutter analyze** phải sạch sau khi thêm param mới vào `_buildInviteCard`. Dev kiểm tra toàn bộ call-site (hiện chỉ có 1 chỗ trong `build()`).

6. **l10n:** Sau khi thêm 3 key vào cả hai ARB, chạy `flutter gen-l10n` (hoặc `fvm flutter gen-l10n` tuỳ toolchain máy) để regenerate `app_localizations_vi.dart` và `app_localizations_en.dart`.

---

## Acceptance criteria (design)

- [x] Cả 3 state (A/B/C) có wireframe + spec token đầy đủ
- [x] Copy đủ VI + EN cho cả key mới lẫn key cũ giữ nguyên
- [x] ARB entries sẵn sàng copy-paste
- [x] Dev dựng được không cần hỏi lại (param mới + render condition + token rõ ràng)
- [x] Không bịa token mới — tái dùng: `AppColors.warning`, `AppColors.white`, `AppColors.accentRose`, `LucideIcons.*`, `GlassCard`, `InviteActionButtons`

---

## Nhật ký design

- [2026-06-05] [Designer] Khởi tạo spec. Spec 3 state cho `_buildInviteCard`: State A (personal, không đổi), State B (waiting — hiện `couple.coupleCode` + title mới + desc mới + rejoin hint), State C (active, không đổi). Thêm 3 ARB key mới (setupWaitingCoupleCodeTitle / setupCoupleCodeDesc / setupCoupleCodeRejoinHint). Không thay đổi layout, token, hay màn hình nào khác.
