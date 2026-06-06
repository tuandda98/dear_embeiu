# 🎨 Design — Reactions ❤️ trên ảnh

> Designer sở hữu. Đọc `overview.md` trước. Bám design system (`../../design-system.md`). CHỈ thiết kế, không code.

- **Trạng thái design:** xong (v1)
- **Người/role:** Designer
- **Feature:** reactions · **Ưu tiên:** P1 (NOW)

---

## 0. Đính chính bối cảnh (đọc trước — prompt PO giả định sai 1 điểm)

Prompt mô tả Gallery là "masonry grid". **Thực tế trong code, Gallery là FEED DỌC** (`gallery_screen.dart`): mỗi ảnh là 1 card riêng (`_buildPhotoFeedCard`), ảnh `AspectRatio 4:5` bo 26, có header (avatar + tên + giờ + menu `…`) và caption bên dưới. Không có grid item nhỏ. Vậy 3 surface thực tế là:

1. **Feed card (Gallery)** — surface CHÍNH để react. Mỗi card 1 ảnh lớn → đủ chỗ cho 1 thanh reaction gọn dưới caption.
2. **Fullscreen preview** (`_FullscreenPhotoPreview`) — surface phụ để react khi xem to; panel info đen dưới đáy.
3. **Home "Recent memories"** — card ngang 140×176, tap chỉ chuyển sang tab Gallery (KHÔNG mở preview). → quyết định: chỉ hiển thị **badge đếm chỉ-đọc**, không react tại đây.

Spec dưới đây thiết kế theo đúng 3 surface này.

---

## 1. Mục tiêu thiết kế

Siết vòng lặp 2 chiều rẻ & đúng North Star (số cặp đăng ảnh/tuần): **A đăng → B thả tim → push lại A → A mở app → đăng tiếp.** Reaction phải:
- Cực dễ khám phá & 1 chạm (giảm ma sát so với caption hiện tại — caption phải gõ).
- Cảm xúc cao (pop tim + haptic + heart-burst) để tạo "đã làm gì đó dễ thương".
- Hiển thị reaction của CẢ HAI (couple chỉ 2 người → tối đa 2 reaction/ảnh) một cách ấm áp, có danh tính (Bạn / tên partner).

---

## 2. Bộ reaction (CHỐT)

**6 emoji:** `❤️ 😍 😂 🥹 🔥 👍`

| Emoji | Ý nghĩa | Vì sao chọn |
|-------|---------|-------------|
| ❤️ | Yêu / mặc định | Motif brand, default 1-chạm — phủ 80% nhu cầu |
| 😍 | Mê quá / đẹp quá | Khen ảnh đẹp, rất hợp ảnh couple |
| 😂 | Buồn cười | Ảnh hài, meme đôi |
| 🥹 | Xúc động / thương | Khoảnh khắc cảm động (rất "đôi") |
| 🔥 | Cháy / nóng bỏng | Ảnh đẹp/ngầu/du lịch |
| 👍 | Ổn / đồng ý | Phản hồi nhẹ, an toàn |

**Lý do chốt 6 (không 4, không 8):** ❤️ là mặc định 1-chạm; 5 cái còn lại đủ sắc thái cho đời sống cặp đôi mà vẫn vừa 1 hàng pill picker không cuộn trên mọi cỡ máy. Bỏ các emoji "tiêu cực" (😢 😡) — không hợp không gian riêng tư tích cực của 2 người.

**Quy tắc:** mỗi người **1 reaction/ảnh** (doc theo uid). React lần nữa với emoji khác = **đổi** (ghi đè). React lại đúng emoji đang chọn = **gỡ** (toggle off). → tối đa 2 reaction/ảnh (của tôi + partner).

---

## 3. Tương tác (CHỐT)

Dùng **CẢ HAI** lối vào, bổ trợ nhau (Instagram-pattern, ai cũng quen):

1. **Tap nút tim** (icon trên thanh reaction): thả/gỡ ❤️ ngay (default). 1 chạm — đường nhanh nhất.
2. **Long-press nút tim** (giữ ~250ms): bật **emoji picker pill** nổi lên ngay trên nút → trượt/chạm chọn 1 trong 6. Đổi sang emoji khác.
3. **Double-tap lên ẢNH** (cả feed card lẫn fullscreen): thả ❤️ + heart-burst giữa ảnh (Instagram-like, khám phá tự nhiên). Double-tap khi đã có ❤️ của mình = **không gỡ** (double-tap chỉ "thêm tim", không toggle — tránh vô tình gỡ; muốn gỡ thì tap nút tim).

> Lý do dùng cả 3: tap nút = chủ đích & có nhãn rõ; double-tap ảnh = bản năng & vui; long-press = đổi emoji mà không tốn 1 nút riêng cho từng emoji (giữ thanh gọn). Double-tap ảnh KHÔNG xung đột pinch-zoom ở fullscreen (zoom là pinch 2 ngón / InteractiveViewer; double-tap 1 ngón rảnh — Dev note: tránh để double-tap trigger zoom-to-fit).

---

## 4. User flow

```
A đăng ảnh  ──▶  ảnh xuất hiện trong feed của CẢ HAI (Firestore stream)
                          │
            B mở Gallery / Home / preview
                          │
        ┌─────────────────┼─────────────────────┐
   tap nút tim       double-tap ảnh         long-press tim
        │                 │                      │
     thả ❤️           thả ❤️+burst          picker 6 emoji → chọn
        └─────────────────┴──────────┬───────────┘
                                     │  (optimistic: hiện ngay, ghi Firestore nền)
                                     ▼
                 reaction của B lưu vào subcollection
                                     │  Cloud Function onCreate
                                     ▼
              PUSH cho A: "{B} đã thả ❤️ vào ảnh của bạn"
                                     │  tap push → mở tab Gallery
                                     ▼
        A thấy ❤️ của B trên ảnh → cảm xúc → đăng tiếp 🔁
```

---

## 5. Wireframe ASCII

### 5.1 Feed card (Gallery) — thanh reaction MỚI dưới caption

```
┌──────────────────────────────────────────────┐  ← card bo 30, white .94
│ (avatar)  Minh ♥ Lan                      …   │
│           👤 Đăng bởi Minh   🕐 2 Th6           │
│  ┌────────────────────────────────────────┐   │
│  │                                        │   │
│  │            ẢNH 4:5 (bo 26)              │   │  ← double-tap = ❤️ + burst
│  │                                        │   │
│  └────────────────────────────────────────┘   │
│  "Hoàng hôn ở Đà Lạt 🌄"   (caption)            │
│                                                │
│  ┌─ reaction bar ───────────────────────────┐ │  ← MỚI
│  │ [ ❤️ ]   😍 Lan        ·  Bạn: 🔥          │ │
│  │  nút      partner chip      my chip       │ │
│  └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

Thanh reaction (`reaction bar`) = `Padding(18,0,18,16)` ngay dưới caption (hoặc thay chỗ `SizedBox(height:16)` khi không caption). Bố cục `Row`:
- **Trái:** nút tim (heart button) — `IconButton` tròn 40px.
- **Giữa/phải (Wrap, cuộn không cần vì ≤2 chip):** các "reaction chip" của những người ĐÃ react (partner và/hoặc tôi). Chip = emoji + nhãn người (tên partner / "Bạn").

Khi **chưa ai react**: chỉ hiện nút tim outline + hint mờ "Thả tim cho khoảnh khắc này" (ẩn sau lần đầu? → giữ luôn, nhẹ).

### 5.2 Heart button — 3 trạng thái

```
chưa react của mình      đã react ❤️           đã react emoji khác (vd 🔥)
┌─────────┐              ┌─────────┐           ┌─────────┐
│   ♡     │              │   ❤️    │           │   🔥    │
│ outline │              │ filled  │           │ emoji   │
│ rose    │              │ pop+glow│           │ chip nền│
└─────────┘              └─────────┘           └─────────┘
 size 40,                 favorite filled       emoji 20 trên
 LucideIcons.heart        accentLove + scale     nền rose .12
 (viền)                   pop 1→1.25→1            bo 999
```

### 5.3 Reaction chip (hiển thị ai đã react)

```
partner chip (đối phương):        my chip (của tôi):
┌──────────────┐                  ┌────────────┐
│ 😍  Lan       │                  │ 🔥  Bạn     │
└──────────────┘                  └────────────┘
nền surfaceLight bo 999           nền rose .10 bo 999
emoji 16 + tên 11.5 w700          emoji 16 + "Bạn" 11.5 w700
text textSecondary                text accentLoveDeep
```

### 5.4 Long-press emoji picker (pill nổi)

```
        ┌─────────────────────────────────┐
        │  ❤️   😍   😂   🥹   🔥   👍      │  ← pill nổi, blur nền
        └───────────────▲─────────────────┘
                        │ mỏ ra từ nút tim
                   [ ❤️ ] nút tim (đang long-press)
```
- Pill: `BackdropFilter` blur 18 + white .92, bo 999, viền white .6, shadow mềm. Padding `12×8`. 6 emoji size 26, khoảng cách 14, mỗi emoji có hit-target ≥44px.
- Emoji đang chọn (của tôi): có vòng nền rose .14 + viền accentLove.
- Hiện: scale-in từ 0.85→1 + fadeIn 200ms easeOutCubic, anchor đáy-giữa = nút tim. Tap ngoài / chọn xong → đóng 160ms.

### 5.5 Fullscreen preview — reaction trong panel info đáy

```
      ╔══════════════════════════════════╗
      ║                            [✎][✕]║  ← nút sẵn có (edit/report/close)
      ║                                  ║
      ║            ẢNH (contain)          ║  ← double-tap = ❤️+burst (giữa ảnh)
      ║                                  ║
      ║  ┌────────────────────────────┐  ║
      ║  │ Minh ♥ Lan                 │  ║  panel đen .36 bo 24 (SẴN CÓ)
      ║  │ Đăng bởi Minh · 2 Th6      │  ║
      ║  │ "Hoàng hôn ở Đà Lạt"       │  ║
      ║  │ ─────────────────────────  │  ║  ← divider mờ white .12
      ║  │ [ ❤️ ]   😍 Lan   ·  🔥 Bạn │  ║  ← reaction row MỚI (light-on-dark)
      ║  └────────────────────────────┘  ║
      ╚══════════════════════════════════╝
```
Thêm 1 `Row` reaction vào CUỐI panel info đen (sau caption). Heart button + chip dùng biến thể **on-dark** (chữ trắng, nền white .14). Long-press picker vẫn pill sáng nổi lên.

### 5.6 Home "Recent memories" — chỉ badge đếm (read-only)

```
┌───────────┐
│  ẢNH      │
│           │
│        ❤️2│  ← badge góc trên-phải: emoji + số người react (1–2)
│ caption…  │
│ 2 Th6     │
└───────────┘
 140×176
```
- **KHÔNG react tại Home** (tap vẫn chuyển sang tab Gallery như cũ). Lý do: Home là tổng quan, không phải nơi tương tác chi tiết; thêm gesture react ở card 140px nhỏ dễ nhầm với tap-chuyển-tab. Giữ Home sạch.
- Badge chỉ hiện khi ảnh có ≥1 reaction: pill nhỏ góc trên-phải card, nền black .42 bo 999, padding `7×4`: emoji của reaction "nổi bật nhất" (ưu tiên ❤️, nếu không có thì emoji của partner) + số đếm nếu =2. Ẩn khi 0 reaction.

---

## 6. Spec chi tiết (token chính xác — bám design system)

### Heart button (cả feed & fullscreen)
| Thuộc tính | Giá trị |
|---|---|
| Kích thước | 40×40, hit-target 44 |
| Icon chưa react | `LucideIcons.heart` (outline) size 22, màu `accentRose #FF4D6D` alpha .85 |
| Icon đã react ❤️ | Material `Icons.favorite` (filled) size 22, màu `accentLove #FF4D6D` + glow nhẹ (shadow accentLove .35 blur 8) |
| Icon đã react emoji khác | hiện emoji đó size 20 trên nền `accentRose .12` bo 999 |
| Nền nút (feed) | trong suốt; pressed → `accentRose .08` ripple bo 999 |
| Nền nút (fullscreen) | `white .14` bo 999 (on-dark) |

### Reaction chip
| | Partner chip | My chip |
|---|---|---|
| Nền (light) | `surfaceLight #F5F0F5` | `accentLove .10` |
| Nền (on-dark) | `white .14` | `white .20` |
| Radius | 999 | 999 |
| Padding | `10×6` | `10×6` |
| Emoji | size 16 | size 16 |
| Nhãn | tên partner, 11.5 w700, `textSecondary` (light) / white .9 (dark) | "Bạn", 11.5 w700, `accentLoveDeep #E63956` (light) / white (dark) |
| Khoảng emoji↔nhãn | 6 | 6 |

### Picker pill
- Nền: `BackdropFilter` blur 18 + `white .92`; bo 999; viền `white .60` 1px; shadow `black .12` blur 16 y6.
- Padding `12×8`; 6 emoji size 26; gap 14; mỗi emoji `InkResponse` tròn 44.
- Emoji đang chọn: nền `accentRose .14` tròn + viền `accentLove` 1.4.

### Badge Home (read-only)
- Pill `black .42` bo 999, padding `7×4`, emoji 12 + (nếu =2) số "2" trắng 10 w800. Vị trí `top:10 right:10` trong Stack card.

### Heart-burst (double-tap)
- 1 trái tim lớn `Icons.favorite` accentLove size 88, glow trắng, hiện giữa ảnh: scale 0→1.15→1 + fadeOut, tổng 600ms. Kèm 5–7 hạt tim nhỏ (size 14–22) bay tỏa lên + mờ dần (dùng `confetti` package đã có, hoặc tự vẽ — Dev chọn). Burst là one-shot, không chặn tương tác.

---

## 7. States (đầy đủ)

| State | Mô tả hiển thị |
|---|---|
| **Chưa ai react** | Feed: chỉ nút tim outline + hint mờ "Thả tim cho khoảnh khắc này" (`textTertiary` 11.5). Home: không badge. |
| **Chỉ tôi đã react** | Nút tim = filled ❤️ (hoặc emoji tôi chọn). My chip "Bạn". Home badge = emoji tôi (số 1, ẩn số). |
| **Chỉ partner đã react** | Nút tim vẫn outline (tôi chưa thả). Partner chip "{tên} 😍". Home badge = emoji partner. |
| **Cả hai đã react** | Nút tim phản ánh emoji của tôi + 2 chip (partner + Bạn). Home badge = ❤️ ưu tiên + số "2". |
| **Loading (optimistic)** | Vừa thả: UI cập nhật NGAY (nút đổi + chip "Bạn" hiện + burst), ghi Firestore chạy nền. KHÔNG spinner. |
| **Error (ghi thất bại)** | Rollback nhẹ: chip "Bạn" mờ rồi biến mất, SnackBar floating navy "Chưa thả được tim, thử lại". Không phá UI khác. |
| **Offline** | Optimistic giữ hiển thị; Firestore tự sync khi online (giống ảnh/caption hiện tại). Không báo lỗi gay gắt. |
| **Disabled** | Khi `couple == null` (chế độ local chưa ghép, hoặc guest): ẩn toàn bộ reaction bar (không có partner để vòng lặp). Khi đang xoá ảnh: bar mờ .4, không bấm được. |
| **Ảnh của chính tôi** | VẪN react được (xem D3). Nút tim + chip hoạt động y hệt. Partner chip hiện khi partner thả. |

---

## 8. Interaction & animation

| Hành vi | Animation | Duration / Curve |
|---|---|---|
| Tap thả ❤️ | nút scale pop 1→1.25→1 + glow on | 220ms easeOutBack; `HapticFeedback.lightImpact` |
| Gỡ tim (toggle off) | nút scale 1→0.85→1, fade về outline | 200ms easeOutCubic; haptic selectionClick |
| Long-press → picker | pill scale 0.85→1 + fadeIn | 200ms easeOutCubic; haptic mediumImpact khi pill mở |
| Chọn emoji trong picker | emoji chọn nảy nhẹ, pill đóng | đóng 160ms; nút đổi sang emoji mới với pop 220ms |
| Double-tap ảnh | heart-burst giữa ảnh (xem §6) | 600ms; haptic mediumImpact |
| Chip xuất hiện (partner react realtime) | chip slide-in từ phải 6px + fadeIn | `AppMotion.base` 280ms easeOutCubic |
| Badge Home đổi số | crossfade | 200ms |

Tái dùng token `AppMotion` (fast 200 / base 280) + `flutter_animate`. Heart-burst dùng `confetti` package (CLAUDE.md ghi đã import, "dành Đợt 2 invite reveal" — đây là chỗ dùng thật).

---

## 9. Copy (song ngữ — bắt buộc)

### UI strings

| Key (đề xuất) | VI | EN |
|---|---|---|
| `reactionHint` | Thả tim cho khoảnh khắc này | React to this moment |
| `reactionYouLabel` | Bạn | You |
| `reactionAddTooltip` | Thả tim | React |
| `reactionChangeTooltip` | Đổi cảm xúc | Change reaction |
| `reactionRemoveTooltip` | Gỡ cảm xúc | Remove reaction |
| `reactionErrorRetry` | Chưa thả được tim, thử lại nhé | Couldn't react, try again |
| `reactionPartnerReacted` | {name} đã thả {emoji} | {name} reacted {emoji} |
| `reactionBothLabel` | Cả hai đã thả tim 💞 | You both reacted 💞 |

> `reactionPartnerReacted` / `reactionBothLabel` dùng cho a11y label / tooltip; emoji & {name} là placeholder ICU.

### Push copy (Cloud Function — Dev/CF dùng)

| Tình huống | VI | EN |
|---|---|---|
| Partner thả ❤️ vào ảnh của bạn | {name} đã thả ❤️ vào ảnh của bạn | {name} reacted ❤️ to your photo |
| Partner thả emoji khác (vd 😍) | {name} đã thả {emoji} vào ảnh của bạn | {name} reacted {emoji} to your photo |
| (title push, tuỳ chọn) | Dear Embeiu | Dear Embeiu |

> Push CHỈ gửi khi người react ≠ tác giả ảnh (tránh tự push chính mình khi react ảnh của mình — xem D3). Gộp/debounce nếu đổi reaction nhiều lần liên tục (Dev/CF: chỉ push lần CREATE đầu, không push mỗi lần đổi emoji — tránh spam). Tap push → mở tab Gallery (`type: photo_reaction`, reuse `NotificationTapRouter`).

---

## 10. Quyết định đã chốt (decision log)

- **D1 — Bộ 6 emoji `❤️😍😂🥹🔥👍`, ❤️ mặc định.** *Lý do:* phủ sắc thái cặp đôi, vừa 1 hàng pill, bỏ emoji tiêu cực.
- **D2 — 3 lối tương tác (tap nút / double-tap ảnh / long-press picker).** *Lý do:* khám phá tự nhiên (IG-pattern) + đổi emoji không tốn nút riêng.
- **D3 — Cho phép react ảnh của CHÍNH MÌNH.** *Lý do:* đơn giản hoá (PO nghiêng vậy), không phải case xấu; chỉ KHÔNG push khi tự react ảnh mình.
- **D4 — Home "Recent memories" chỉ badge read-only, không react.** *Lý do:* card 140px nhỏ + tap đã dành cho chuyển tab; giữ Home sạch.
- **D5 — Optimistic UI, không spinner.** *Lý do:* phản hồi tức thì là cốt lõi cảm xúc; Firestore sync nền như ảnh/caption hiện tại.
- **D6 — Surface chính = feed card (vì Gallery là feed dọc, không grid).** *Lý do:* khớp code thực tế; prompt PO giả định masonry sai.

---

## 11. Phụ thuộc kỹ thuật (Dev/PO tính chi phí — Designer KHÔNG giải)

> Đây là phần Dev/PO phải làm để feature chạy. Designer chỉ liệt kê để ước lượng.

1. **Data model — subcollection** (pattern giống `dailyAnswers`):
   `couples/{coupleId}/photos/{photoId}/reactions/{uid}` = `{ emoji: string, reactedAt: timestamp, authorUserId: string }`. Doc id = uid → 1 doc/người/ảnh, đổi = ghi đè, gỡ = delete.
2. **Photo model** không cần thêm field (reaction sống ở subcollection). Provider `PhotoProvider` cần watch reactions per-photo (hoặc collectionGroup) — Dev quyết kiến trúc stream.
3. **`firestore.rules` (CẦN DEPLOY):** thêm path `reactions/{uid}`:
   - `read: if` là member của couple.
   - `write (create/update/delete): if` member && `uid == request.auth.uid` && `authorUserId == request.auth.uid` && `emoji in [6 emoji hợp lệ]`.
   - ADDITIVE — không đụng rules ảnh/notes/dailyAnswers hiện có.
4. **Cloud Function (CẦN DEPLOY):** `notifyPhotoReaction` — `onDocumentCreated` (hoặc onWritten lọc) `couples/{coupleId}/photos/{photoId}/reactions/{uid}`:
   - Lấy ảnh → `authorUserId`. Nếu reactor `uid == authorUserId` → **bỏ qua** (không tự push).
   - Gửi push cho member còn lại (tác giả ảnh) qua helper `sendToRecipientDevices` (đã có, localize vi/en theo device `languageCode`).
   - Copy ở §9. `data: { type: 'photo_reaction', coupleId, photoId }`. Chỉ push lần CREATE (không push mỗi lần đổi emoji) để tránh spam.
   - `deleteCoupleCompletely` cần `recursiveDelete` cả subcollection `reactions` (lồng trong photos) — bổ sung như đã làm cho `dailyAnswers`.
5. **Deep-link:** map `type: photo_reaction` → tab Gallery(1) trong `NotificationTapRouter` / `HomeScreen` (giống `photo_posted`).
6. **Localization:** thêm keys §9 vào CẢ `app_en.arb` + `app_vi.arb` rồi `gen-l10n`.

> ⚠️ Thứ tự deploy như các feature trước: **rules + functions deploy TRƯỚC khi ship client**, nếu không client ghi reaction sẽ permission-denied / không có push.

---

## 12. Assets

- Không cần asset ảnh mới. Emoji = ký tự Unicode (render bằng system emoji font).
- Icon: `LucideIcons.heart` (outline) + Material `Icons.favorite` (filled — Lucide thiếu filled heart, design system đã ghi ngoại lệ này).
- Heart-burst: dùng `confetti` package có sẵn (hoặc particle tự vẽ) — không cần file Lottie.

---

## 13. Handoff / Dev notes

- **Surface CHÍNH = `_buildPhotoFeedCard`** trong `gallery_screen.dart`: chèn reaction bar sau caption (thay/đứng cạnh `SizedBox(height:16)` khi no-caption).
- **Surface phụ = `_FullscreenPhotoPreview`**: thêm reaction row vào cuối panel info đen (sau caption), biến thể on-dark.
- **Double-tap ảnh:** thêm `onDoubleTap` cho `GestureDetector` bọc ảnh ở cả 2 surface. Ở fullscreen, cẩn thận double-tap KHÔNG được kích hoạt zoom của `InteractiveViewer` (InteractiveViewer không tự double-tap-zoom mặc định nên OK, nhưng test kỹ).
- **Home badge:** chỉ đọc, thêm vào Stack card 140×176 trong `_buildRecentPhotosSection` (`home_screen.dart`) — KHÔNG đổi onTap (vẫn `setState(_selectedIndex = 1)`).
- **Couple chỉ 2 người** → logic "partner = member khác tôi" như push ảnh hiện có. Tối đa 2 chip.
- **Guest / couple == null** → ẩn hoàn toàn reaction (không có vòng lặp 2 chiều khi solo).
- Heart button & chip nên tách thành widget tái dùng (vd `ReactionBar`, `ReactionChip`, `HeartBurst`) để dùng chung 2 surface.

---

## 14. Acceptance (design)

- [x] Bộ reaction chốt + lý do
- [x] 3 surface (feed card / fullscreen / home) có wireframe + spec riêng
- [x] Mọi state (chưa/tôi/partner/cả hai/loading/error/offline/disabled/ảnh-của-mình) có mô tả
- [x] Token chính xác (màu hex, size, radius, animation ms+curve)
- [x] Copy đủ VI+EN (UI + push)
- [x] Mục Phụ thuộc kỹ thuật (subcollection + rules + CF) cho Dev/PO
- [ ] PO chốt các "quyết định mở" (xem báo cáo) trước khi Dev bắt tay

## Nhật ký design
- [2026-06-04] [Designer] Thiết kế v1 Reactions: bộ 6 emoji, 3 surface (feed card chính / fullscreen / home badge read-only), 3 lối tương tác (tap/double-tap/long-press), full states + animation token + copy vi/en (UI+push) + mục phụ thuộc kỹ thuật. Đính chính: Gallery là feed dọc (không masonry như prompt giả định).
