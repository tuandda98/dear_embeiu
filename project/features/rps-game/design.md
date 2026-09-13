# 🎨 Design — Oẳn tù tì (rps-game)

> Designer sở hữu. Đọc `overview.md` trước (máy trạng thái §4, client §5 là NGUỒN SỰ THẬT về hành vi — file này chỉ quyết *trông thế nào*). Bám design system (`../../design-system.md` + rule header/primitives của `../design-unify/`). CHỈ thiết kế, không code.

- **Trạng thái design:** xong (handoff Dev client 2026-09-13)
- **Người/role:** Designer
- **Liên quan:** [overview.md](overview.md) · [dev.md](dev.md) · [test.md](test.md) · ví dụ format gần nhất [`../care-message/design.md`](../care-message/design.md) · pattern lịch sử [`lib/screens/care_timeline_screen.dart`](../../../lib/screens/care_timeline_screen.dart)

---

## 0. Tóm tắt quyết định (đọc nhanh)

| # | Quyết định | Lý do |
|---|---|---|
| D1 | **Điểm vào Home = 1 card nhỏ `RpsInviteCard`** đặt trong nhóm "Hôm nay của chúng mình", **ngay dưới `MoodCard`** (trên section "Kỷ niệm"). KHÔNG thêm icon thứ 3 vào header Home. | Header Home đã có 💌 + 🔔 — thêm icon nữa là rối (3 icon trần sát nhau). Card nhỏ trong nhóm "hôm nay" khớp habit-loop (câu hỏi → mood → chơi 1 ván), và card có chỗ để mang **trạng thái** (đang có lời mời / đang chờ) — icon không mang được. |
| D2 | **Điểm vào Profile = huy hiệu thứ 6 trong `_AchievementsGrid`**, ghép cặp với huy hiệu "Lời quan tâm" thành 1 hàng 2 cột (care hiện đang 1 mình full-width). Value = tỉ số **"3 – 1 – 2"** (Mình – Hoà – Người ấy). | Không tạo section mới; lưới 2 cột cân lại (5 ô lẻ → 6 ô chẵn). |
| D3 | **Badge lời mời đang chờ** = (a) card Home đổi sang state `invitedByPartner` (viền rose + dot + CTA rose "Vào chơi"), (b) dot rose 9px góc medallion Profile, (c) chuông đã đếm inbox `rps_invite` sẵn. KHÔNG badge trên tab bar. | Tab bar 4 tab đã có ngôn ngữ riêng, badge ở đó = nợ design mới. 3 điểm trên đủ "không bỏ lỡ". |
| D4 | **3 nút chọn = `RpsChoiceTile` 108×120 (≥96pt)**, card trắng r24; **chọn xong → fill `sunsetRomance` chữ trắng + check**, 2 nút kia mờ .38. | Emoji lớn + nhãn; state "đã chọn" dùng hero gradient (rose = hành động tình cảm/quyết định), không dùng navy để phân biệt với CTA. |
| D5 | **Vòng đếm ngược ring 168pt** stroke 10, progress `sunsetRomance`, số 56 display w800 navy; haptic `selectionClick` mỗi giây, `heavyImpact` khi về 0. | Số to nhìn được từ xa (2 người thường ngồi cạnh nhau). |
| D6 | **Reveal kết quả = "1 · 2 · 3!"** 3 nhịp 300ms rồi 2 lá bài pop (scale .6→1 + fade, 320ms `easeOutBack` — ngoại lệ curve có chủ đích cho trò chơi), confetti chỉ khi **mình thắng** + KHÔNG Reduce Motion. | Tính "kịch" là giá trị chính của trò; Reduce Motion có fallback tĩnh. |
| D7 | **"Nhắc lại" ở màn chờ = huỷ ván cũ + tạo ván mới** (CF `notifyRpsInvite` tự push lại), **cooldown 60s** hiện đếm ngược trên nút. | Không cần CF mới; chống spam push. |
| D8 | Lịch sử = **bảng tỉ số 3 cột** (Mình / Hoà / Người ấy) + list gom theo ngày **y hệt care_timeline** (day label rose 12 w700 uppercase, card r22, phân trang 30, shimmer, empty state `_TimelineMessage`). | Tái dùng pattern đã có, Dev copy cấu trúc file. |
| D9 | Icon: **`IconsaxPlusBold.game`** cho chip/medallion/entry; `IconsaxPlusLinear.clock` cho lịch sử; `timer_pause` hết hạn; `close_circle` huỷ; `refresh` chơi lại/nhắc lại. Emoji cho 3 lựa chọn: ✌️ ✊ ✋. | Iconsax Plus là bộ icon chính; emoji là ngôn ngữ chung của oẳn tù tì. |
| D10 | Xưng hô: **"bạn"** cho người dùng, **"người ấy"** cho partner, **"chúng mình"** cho cả hai. KHÔNG "hai đứa". | Voice app. |

**Đề xuất bổ sung design system (ghi để PO duyệt, không tự chế token mới ngoài đây):**
- `_MedalPalette.game` cho huy hiệu Profile: gradient `[#FFA46B → #FF6B9D]` (peach → sunset1), accent `#F26D5B`. Lý do: 5 medal hiện có đã dùng rose/lavender/coral-pink/berry/loveDeep — cần 1 sắc **ấm hơn** (peach) để ô thứ 6 đọc là "huy hiệu khác", vẫn trong họ Sunset.
- Component mới `RpsChoiceTile` (mục 5.3) — có thể rút vào `lib/widgets/` nếu sau này có mini-game khác.

---

## 1. Mục tiêu thiết kế
- Ván chơi **nhanh, kịch, rõ**: từ tap "Chơi" tới thấy kết quả < 15 giây khi cả hai online; mọi trạng thái đều có 1 câu nói rõ *đang chờ gì / phải làm gì*.
- **Không lộ lựa chọn** người kia trước khi kết thúc (UI không hiển thị gì ngoài "Đã chọn ✓" kể cả khi rules đã chặn).
- Đồng bộ ngôn ngữ **Sunset Romance / design-unify**: nền `dawnBlush`, `SubScreenHeader` chip-only, `ContentCard`, pill navy h52, InkWell ripple, Quicksand, type scale cố định.
- A11y: nút ≥96pt, Reduce Motion có frame tĩnh, Semantics cho ring + 3 nút + kết quả.

## 2. Phạm vi màn hình
1. **Entry Home** — `RpsInviteCard` (widget mới `lib/widgets/rps_invite_card.dart`), 3 state.
2. **Entry Profile** — huy hiệu trong `_AchievementsGrid` (sửa `profile_screen.dart`).
3. **`RpsGameScreen`** — 4 state chính (waiting / countdown / chosen / result) + 2 state kết thúc sớm (expired / cancelled) + error.
4. **`RpsHistoryScreen`** — scoreboard + list gom ngày + empty/loading/error.
5. **Thông báo** — push invite + push result (3 biến thể) + item Notification center `rps_invite`.

## 3. User flow

```
Home card "Oẳn tù tì" [Chơi]  ──┐
Profile huy hiệu tỉ số ─────────┼──▶ RpsGameScreen(gameId?)  ── không có ván mở ──▶ tạo game 'invited'
Push / inbox rps_invite ────────┘          │                     có ván invited/playing ──▶ vào ván đó
                                           ▼
                        (a) WAITING  "Đang chờ người ấy…"  [Nhắc lại] [Huỷ]
                                           │ cả 2 presence tươi → invited→playing (startedAt)
                                           ▼
                        (b) COUNTDOWN 5→0  ring + 3 nút ✌️✊✋  (tap = ghi move, khoá)
                                           │
                        (c) CHOSEN  nút đã chọn nổi, "Đã chọn ✓ · Chờ người ấy…" (ring vẫn chạy)
                                           │ CF finished  |  hoặc 0s+2s client gọi finishRpsGame
                                           ▼
                        (d) RESULT  "1·2·3!" → 2 lá bài lật → Bạn thắng 🎉 / Người ấy thắng 😝 / Hoà 🤝
                                    [Chơi lại] [Xem lịch sử] [Đóng]
                                           │ Chơi lại → game mới rematchOf → quay (a) (thường nhảy thẳng (b) vì cả 2 còn presence)

Nhánh phụ: (a) 10' không đủ 2 → EXPIRED "Lời mời đã hết hạn" [Rủ lại] [Đóng]
           (a) createdBy bấm Huỷ → CANCELLED; partner mở sau thấy "Người ấy đã huỷ lời mời" [Rủ lại]
           (b)/(c) mất mạng → banner offline; đồng hồ vẫn chạy theo startedAt đã đọc.
```

## 4. Wireframe ASCII

### 4.1 Home — `RpsInviteCard` (trong gutter 16, dưới MoodCard, cách 16)
```
State idle
┌──────────────────────────────────────────────┐  ContentCard r24 pad 16
│ ┌────┐  Oẳn tù tì                  ┌───────┐ │  medallion 48 r16 gradient game, glyph "✌️✊✋" 
│ │✌️✊✋│  Rủ người ấy một ván nhé    │ Chơi  │ │  title 16 w800 navy · sub 13 textSecondary
│ └────┘  Tuần này 3 – 1 – 2         └───────┘ │  CTA pill h40 navy, label 14 w700 trắng
└──────────────────────────────────────────────┘

State invitedByPartner (badge)
┌──────────────────────────────────────────────┐  viền accentLove .45 1.5px + dot rose 9px góc medallion
│ ┌────┐● Người ấy đang rủ!          ┌────────┐│  title accentLoveDeep · sub "Vào chọn trong 5 giây ⏱️"
│ │✌️✊✋│  Vào chọn trong 5 giây ⏱️    │Vào chơi││  CTA pill h40 fill sunsetRomance chữ trắng
│ └────┘                             └────────┘│
└──────────────────────────────────────────────┘

State myInvitePending
┌──────────────────────────────────────────────┐
│ ┌────┐  Đang chờ người ấy…         ┌───────┐ │  sub "Lời mời còn hiệu lực 10 phút" · CTA "Mở" pill outlined navy
│ │✌️✊✋│  Lời mời còn hiệu lực 10'   │  Mở   │ │
│ └────┘                             └───────┘ │
└──────────────────────────────────────────────┘
```

### 4.2 Profile — hàng cuối `_AchievementsGrid` (đổi từ 1 ô care full-width → 2 ô)
```
┌───────────────────┐ ┌───────────────────┐
│ [💌 medal]      › │ │ [🎮 medal]●     › │   ● = dot rose 9px khi có lời mời đang chờ
│ 12                │ │ 3 – 1 – 2         │   value 22 w800 accent (rps ngắn hơn 28 vì 3 số + 2 dấu)
│ Lời quan tâm      │ │ Oẳn tù tì         │   label 13 textSecondary w600 (giữ như ô khác)
└───────────────────┘ └───────────────────┘
```

### 4.3 `RpsGameScreen` — chung: nền `dawnBlush`, `SafeArea`, header pinned
```
←            [🎮 OẲN TÙ TÌ]              🕓      SubScreenHeader(badge, IconsaxPlusBold.game, trailing: clock → lịch sử)
```

**(a) WAITING**
```
                 ┌──────┐   vs   ┌──────┐         2 avatar 72 tròn: initials trên primaryGradient (mình) / lavender (người ấy)
                 │  T   │  ───   │  E   │         pill "vs" 11 w800 navy .70 trên white .72
                 └──────┘        └──────┘         avatar người ấy: viền dashed white .8 + opacity .55 khi presence chưa tươi
                   Mình         Người ấy          12 textSecondary

              Đang chờ người ấy…                  20 w700 navy (title-m) + 3 chấm nhấp nháy
   Người ấy đã nhận thông báo. Khi cả hai          14 textSecondary, center, height 1.5
   cùng ở đây, ván chơi bắt đầu ngay.

   ┌────────────────────────────────────────┐
   │        🔔  Nhắc lại  (đã gửi · 47s)    │      pill h52 navy; cooldown 60s → disabled .28 + đếm ngược
   └────────────────────────────────────────┘
                  Huỷ lời mời                     TextButton 14 w700 textSecondary (chỉ createdBy). Partner thấy "Đóng".
```

**(b) COUNTDOWN**
```
                    ╭─────────╮
                   ╱   ring    ╲                  ring 168, track white .55 stroke 10, progress sunsetRomance sweep ngược chiều kim
                  │     4      │                  số 56 display w800 navy, letterSpacing -1
                   ╲           ╱                  dưới số: "giây" 11 w700 navy .55 uppercase ls1.4
                    ╰─────────╯
                   Chọn ngay!                     16 w700 navy

   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │   ✌️    │   │   ✊    │   │   ✋    │       RpsChoiceTile 108×120, card trắng r24 shadow black .06
   │   Kéo   │   │   Búa   │   │   Bao   │       emoji 44 · label 14 w700 navy · gap 12
   └─────────┘   └─────────┘   └─────────┘

        Kéo cắt Bao · Bao bọc Búa · Búa đập Kéo    12 textTertiary center (nhắc luật, 1 dòng)
```

**(c) CHOSEN-WAITING**
```
   (ring vẫn chạy)         Đã chọn ✓ · Chờ người ấy…      16 w700 navy; "✓" accentLoveDeep

   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │   ✌️    │   │▓▓ ✊ ▓▓│   │   ✋    │       nút chọn: fill sunsetRomance, label trắng, check 18 trắng góc trên phải,
   │   Kéo   │   │▓▓Búa▓▓ │   │   Bao   │       shadow rose .30 blur 16; 2 nút kia opacity .38 + IgnorePointer
   └─────────┘   └─────────┘   └─────────┘
```

**(d) RESULT**
```
                   Bạn thắng 🎉                   26 headline w800 navy (thắng) / "Người ấy thắng 😝" / "Hoà 🤝"
              Búa đập Kéo — ván 12                 14 textSecondary (dòng luật + số thứ tự ván)

   ┌──────────────┐        ┌──────────────┐
   │      ✊      │   vs   │      ✌️      │      2 "lá bài" 140×164 r24 trắng; lá thắng: viền sunsetRomance 2px + shadow rose .30
   │     Búa      │        │     Kéo      │      emoji 64 · label 15 w700
   │  T · Mình    │        │ E · Người ấy │      avatar 24 + tên 12 textSecondary
   └──────────────┘        └──────────────┘

   ┌────────────────────────────────────────┐
   │              🔁 Chơi lại               │      pill h52 navy
   └────────────────────────────────────────┘
   ┌────────────────────────────────────────┐
   │             Xem lịch sử                │      pill h48 outlined navy 1.4px, label navy 15 w600
   └────────────────────────────────────────┘
                    Đóng                            TextButton 14 w700 textSecondary
```
Ván timeout (`reason:'timeout'`): lá bài của người không chọn hiện **"⏳" + "Bỏ lượt"** (emoji 64 opacity .6, label textTertiary); dòng luật đổi thành "Người ấy không kịp chọn" / "Bạn không kịp chọn" / "Cả hai bỏ lượt".

**(e) EXPIRED / CANCELLED** — tái dùng layout `_TimelineMessage` (icon tròn 88 white .5 + title 20 + body 14 + pill CTA):
```
            ( ⏸ )                                 IconsaxPlusLinear.timer_pause (expired) / close_circle (cancelled), accentLove 38
      Lời mời đã hết hạn                          20 w700
  Người ấy không kịp vào trong 10 phút.           14 textSecondary
  Rủ lại khi cả hai rảnh nhé.
        [ Rủ lại ]      Đóng                      pill navy h52 · TextButton
```

### 4.4 `RpsHistoryScreen`
```
←            [🕓 LỊCH SỬ VÁN]                     SubScreenHeader(badge, IconsaxPlusLinear.clock)

┌──────────────────────────────────────────────┐  Scoreboard ContentCard r24 pad 20
│    3          1          2                   │  value 28 w800: mình accentLove · hoà textSecondary · người ấy accentLavenderDeep
│   MÌNH       HOÀ      NGƯỜI ẤY               │  10 micro-caps w700 ls1.4 navy .55
│ ─────────────────────────────────────────────│  hairline surfaceLight
│  6 ván đã chơi · Chuỗi thắng: 2              │  13 textSecondary (chuỗi thắng hiện tại của mình; ẩn "· Chuỗi thắng" khi 0)
└──────────────────────────────────────────────┘

HÔM NAY                                          12 w700 accentLove uppercase ls0.4 (y care_timeline)
┌──────────────────────────────────────────────┐  card r22 pad 14 · gap 10
│ 21:14   ✊  vs  ✌️            [ Bạn thắng ]  │  giờ 12 textTertiary w600 · emoji 22 · pill outcome 11 w700
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ 21:12   ✋  vs  ✋            [   Hoà    ]    │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ 20:58   ⏳  vs  ✊            [ Bỏ lượt ]     │  timeout: emoji ⏳ opacity .6; pill textTertiary tint
└──────────────────────────────────────────────┘
HÔM QUA
…
                  ( shimmer 72 r22 ×2 )           load-more khi còn trang
```
Emoji bên TRÁI luôn là của **mình**, bên PHẢI là **người ấy**; emoji bên thắng có vòng 30px tint (rose .12 mình / lavender .12 người ấy).

## 5. Spec chi tiết (token)

### 5.1 Chung
| Thứ | Token |
|---|---|
| Nền | `AppColors.dawnBlush` (Container ngoài Scaffold transparent — y `care_message_screen`) |
| Header | `SubScreenHeader(badge: l10n.rpsBadge, badgeIcon: IconsaxPlusBold.game, trailing: HeaderIconButton(IconsaxPlusLinear.clock))` — padding `fromLTRB(20,16,20,0)` |
| Gutter body | 20 ngang (màn con) · Home card trong gutter 16 (theo `_gutter`) |
| Card | `ContentCard` r24 pad 20 (scoreboard) · r22 pad 14 (row lịch sử) · nút chọn/lá bài r24 |
| Primary CTA | pill r999 h52 `textPrimary` #1A1A2E, label 16 w700 trắng; disabled alpha .28 (giống `_buildSendButton` care) |
| Secondary | pill r999 h48 outlined `textPrimary` 1.4px, label 15 w600 navy |
| Tertiary | `TextButton` 14 w700 `textSecondary` |
| Ripple | InkWell splash `accentRose .08` / highlight `accentLove .06` (sáng) · trắng .12 trên gradient |
| Font | Quicksand (theme) · cỡ chỉ từ scale 10/11/12/13/14/15/16/18/20/21/22/26/30/32/56 |
| Haptic | tap nút chọn `mediumImpact` · mỗi giây đếm `selectionClick` · 0s `heavyImpact` · kết quả thắng `heavyImpact`, thua/hoà `lightImpact` · mọi nút khác `selectionClick` |

### 5.2 Màu theo vai
| Vai | Màu |
|---|---|
| Mình | `accentLove` #FF4D6D (accent), avatar `primaryGradient` |
| Người ấy | `accentLavenderDeep` #7C5CD6 (accent), avatar gradient `[accentLavender → accentLavenderDeep]` |
| Hoà | `textSecondary` #6B6B7B |
| Bỏ lượt | `textTertiary` #A0A0B0 |
| Đã chọn / lá thắng | `sunsetRomance` [#FF6B9D→#FF8FA3→#FFB6C1] + shadow `accentRose .30 blur 16 offset(0,8)` |
| Ring track | `white .55` · progress `sunsetRomance` (SweepGradient hoặc `ShaderMask` trên CircularProgressIndicator) · ≤1s còn lại → progress `accentLoveDeep` đặc |
| Huy hiệu Profile | `_MedalPalette.game` = `[#FFA46B, #FF6B9D]`, accent `#F26D5B` (đề xuất mới, xem §0) |
| Pill outcome lịch sử | thắng: fill `accentLove .12` chữ `accentLoveDeep` · thua: `accentLavender .12` chữ `accentLavenderDeep` · hoà: `surfaceLight` chữ `textSecondary` · bỏ lượt: `textTertiary .12` chữ `textTertiary` |
| Viền card Home khi được rủ | `accentLove .45` 1.5px (cùng token notif unread) + dot 9px `accentLove` viền trắng 1.5 |

### 5.3 `RpsChoiceTile` (nút chọn)
- Kích thước: **rộng = (W − 40 − 24)/3, tối thiểu 96, cao 120** (iPhone 390 → 108×120; màn ≤360 → 96×112, emoji 40).
- Idle: fill `cardSurface` trắng, r24, shadow `black .06 blur 16 offset(0,10)`; emoji 44 (Text, `height:1`), gap 8, label 14 w700 `textPrimary`.
- Pressed: scale .96 (100ms) → 1 (AppMotion.fast easeOutCubic) — dùng `AnimatedScale`.
- Selected: fill `sunsetRomance`, label trắng, badge check 22 tròn trắng .92 + `IconsaxPlusBold.tick_circle` 18 `accentLoveDeep` neo top-right (−6, −6), shadow rose .30. Chuyển bằng `AnimatedContainer` 280ms.
- Dimmed (2 nút kia sau khi chọn): opacity .38 (`AnimatedOpacity` 280ms) + `IgnorePointer`.
- Disabled (chưa `playing`/hết giờ): opacity .5, không ripple.
- Semantics: `button`, label "Kéo — chọn Kéo", `selected: true` khi đã chọn; sau khi chọn 2 nút kia `enabled:false`.

### 5.4 Ring đếm ngược
- 168×168, stroke 10, `StrokeCap.round`; `value = remainingMs / 5000` tween mượt 16ms tick (dùng `AnimationController` chạy từ `startedAt`, KHÔNG Timer 1s) — Reduce Motion: cập nhật rời rạc theo giây (không tween).
- Số ở tâm: 56 w800 navy `height:1`, `AnimatedSwitcher` 200ms (scale 1.15→1 + fade) mỗi lần đổi số; **≤1s → số đổi `accentLoveDeep`**.
- Nhãn "GIÂY"/"SEC" 11 w700 navy .55 ls1.4 dưới số.
- Semantics live region: "Còn {n} giây".
- Đồng bộ: `remaining = 5000 − (serverNow − startedAt)`; `serverNow` = `DateTime.now()` + offset đo từ `startedAt` server vs lúc client nhận (Dev note §8).

### 5.5 Lá bài kết quả
- 140×164 r24 trắng, shadow `black .06`; lá thắng: `Border` gradient `sunsetRomance` 2px (dùng `Container` gradient ngoài + `Padding(2)` + card trong) + shadow rose .30.
- Emoji 64, label 15 w700 navy, hàng dưới: avatar 24 initials + tên 12 `textSecondary` (tên = `person1Name/person2Name` như `MoodCard._partnerName`, fallback `reactionPartnerFallback`).
- "vs" giữa: 13 w800 navy .55.
- Hoà: cả 2 lá không viền, tiêu đề "Hoà 🤝".
- Timeout: emoji "⏳" opacity .6, label `rpsChoiceNone` `textTertiary`.

### 5.6 Home `RpsInviteCard`
- `ContentCard(radius:24, padding: fromLTRB(16,14,16,14))` bọc `InkTile` (cả card bấm được).
- Medallion 48 r16 gradient game + glyph: Text "✌️✊✋" 14 (3 emoji) — hoặc `IconsaxPlusBold.game` trắng 24 nếu 3 emoji vỡ dòng ở font nhỏ (Dev test 1 lần, giữ 1 trong 2).
- Title 16 w800 navy; sub 13 `textSecondary` 1 dòng ellipsis.
- CTA: pill h40 padding ngang 18, label 14 w700; idle navy · invitedByPartner `sunsetRomance` trắng · pending outlined navy.
- Dòng tỉ số tuần (state idle): "Tuần này 3 – 1 – 2" — lấy từ `RpsGameProvider.weekScore` (đếm ván finished từ thứ 2 tuần này, local calendar); **0 ván → ẩn dòng, sub = "Rủ người ấy một ván nhé"**.
- Ẩn hoàn toàn khi `couple.isWaitingForPartner` (như MoodCard).
- Entrance: `_entrance(5, …)` theo thứ tự đã có (đẩy "Kỷ niệm" xuống 6/7).

### 5.7 Huy hiệu Profile
- Tái dùng `_badgeCard` y nguyên; **value 22 w800** thay vì 28 (Dev thêm param `valueSize` mặc định 28) vì chuỗi "12 – 4 – 9" dài. Format tỉ số: `"$win – $draw – $loss"` dùng **EN DASH U+2013** có khoảng trắng 2 bên, số qua `NumberFormat`.
- Dot lời mời: `Positioned(top:-3,right:-3)` trên medallion, 9px `accentLove`, viền trắng 1.5 — chỉ khi `RpsGameProvider.pendingInviteFromPartner != null`.
- Shimmer khi tỉ số đang load (`value == null` như journal/care).
- Tap → `openRpsHistory(context)`; nếu đang có lời mời từ người ấy → `openRpsGame(context, gameId)` thay vì lịch sử.

### 5.8 Notification center item `rps_invite`
- Avatar icon `IconsaxPlusBold.game` tint `#F26D5B` (accent game) — cùng khung avatar các loại khác.
- Title `notifRpsInviteTitle(name)`, subtitle `notifRpsInviteBody`; tap → `openRpsGame(gameId)` (màn tự hiện expired/cancelled nếu ván đã đóng).
- `targetHomeTab` = Home(0) (fallback khi không có gameId).

## 6. States (bảng)

| Màn | State | Hiển thị | Hành động |
|---|---|---|---|
| Home card | idle / invitedByPartner / myInvitePending / hidden(waiting_partner) | §4.1 | Chơi → `openRpsGame()` · Vào chơi → `openRpsGame(gameId)` · Mở → `openRpsGame(gameId)` |
| Home card | loading provider | card idle không dòng tỉ số (không shimmer — tránh nhấp nháy) | — |
| Game | **connecting** (mở màn, chưa có doc / đang tạo) | skeleton: ring shimmer 168 tròn + 3 shimmer 108×120 | — |
| Game | **waiting** | §4.3a; avatar người ấy mờ+dashed khi presence chưa tươi, sáng dần khi tươi (280ms) rồi auto sang countdown | Nhắc lại (cooldown 60s) · Huỷ (createdBy) / Đóng (partner) |
| Game | **countdown** | §4.3b, ring 5→0 | tap nút → submitMove → chosen |
| Game | **chosen** | §4.3c | không có (khoá) |
| Game | **resolving** (0s → chờ CF/callable, tối đa 2s + timeout 6s) | ring ở 0, số đổi "…" 3 chấm nhấp nháy, caption "Đang mở kết quả…" | — |
| Game | **result** normal/timeout | §4.3d | Chơi lại · Xem lịch sử · Đóng |
| Game | **expired** | §4.3e timer_pause | Rủ lại · Đóng |
| Game | **cancelled** | §4.3e close_circle; createdBy tự huỷ → pop ngay về màn trước + snackbar `rpsCancelledToast`; partner mở sau → màn này | Rủ lại · Đóng |
| Game | **error** (permission/mạng khi tạo) | `_TimelineMessage` icon `cloud_cross`, title `rpsErrorTitle`, CTA `retry` | Thử lại |
| Game | **offline banner** (mất mạng giữa countdown) | strip 40 trên 3 nút: `warning .14` fill, icon `wifi_square` 16, text 12 `rpsOfflineHint` | — (đồng hồ vẫn chạy) |
| Game | **resolving quá 6s** | title "Kết nối chậm…" + nút "Tải lại" (re-read doc) | Tải lại |
| History | loading | shimmer scoreboard 96 + 5 hàng 72 (y `_TimelineLoading`) | — |
| History | empty | `_TimelineMessage` icon `game`, title/body/CTA `rpsHistoryEmpty*` | CTA → `openRpsGame()` |
| History | error | `_TimelineMessage` icon `cloud_cross`, CTA `retry` | Thử lại |
| History | loaded + loadMore | list + shimmer 2 hàng ở đáy khi còn trang; pull-to-refresh | — |
| Profile badge | loading / idle / hasInvite | shimmer / tỉ số / tỉ số + dot | tap |

## 7. Interaction & animation (duration + curve)

| Việc | Spec |
|---|---|
| Vào màn | body `EntranceReveal` (fade + slideY 8, 360ms, stagger 50) — tắt khi Reduce Motion |
| Avatar người ấy "online" | opacity .55→1 + viền dashed→solid, 280ms `easeOutCubic` |
| Waiting → countdown | `AnimatedSwitcher` 280ms fade+scale .96→1; ring xuất hiện với `heavyImpact` 1 lần ("bắt đầu!") |
| Ring | tween liên tục từ `startedAt` (AnimationController); số `AnimatedSwitcher` 200ms scale 1.15→1 |
| Haptic đếm | `selectionClick` ở 4,3,2,1 · `heavyImpact` ở 0 |
| Tap nút chọn | `AnimatedScale` .96 100ms → 1 200ms; `AnimatedContainer` fill 280ms; 2 nút kia `AnimatedOpacity` .38 280ms |
| Reveal "1 · 2 · 3!" | 3 Text 32 w800 navy xuất hiện lần lượt mỗi 300ms (scale 1.3→1 + fade, `easeOutCubic`) ở giữa màn thay chỗ ring; nhịp 3 kèm `mediumImpact`; sau 900ms → 2 lá bài `scale .6→1 + fade` **320ms `Curves.easeOutBack`** (ngoại lệ curve có chủ đích, chỉ dùng cho lá bài); tiêu đề kết quả fade-in 200ms sau lá bài |
| Confetti (chỉ mình thắng) | `ConfettiController(duration: 2500ms)`, `blastDirectionality: explosive`, `emissionFrequency .05`, `numberOfParticles 24`, `gravity .25`, `colors: [sunset1, accentLove, accentLavender, white]`, neo top-center dưới header (y `love_tree_screen`). Haptic `heavyImpact` |
| Thua/hoà | không confetti; emoji tiêu đề (😝/🤝) `AnimatedScale` 1.2→1 200ms; `lightImpact` |
| Chơi lại | pop-in màn mới không cần transition (cùng route, đổi gameId) — `AnimatedSwitcher` 280ms về state waiting/countdown |
| Nút cooldown "Nhắc lại" | label đổi mỗi giây "Nhắc lại (47s)", không animation |
| Lịch sử | day header + card không animation; load-more shimmer; pull-to-refresh mặc định |
| **Reduce Motion** (`AppMotion.reduceMotion`) | ring cập nhật rời rạc/giây; KHÔNG "1·2·3" (hiện thẳng 2 lá bài + tiêu đề, fade 200ms); KHÔNG confetti (thay bằng hàng emoji tĩnh "🎉 🎊 🎉" 22 dưới tiêu đề); không entrance; haptic GIỮ |
| TickerMode | không áp (màn con pushed) — nhưng khi app vào background giữa countdown: pause controller, resume tính lại từ `startedAt` (không drift) |

## 8. Handoff / Dev notes

**Điểm chèn chính xác**
- Home: `lib/screens/home_screen.dart` `_buildHomeScrollBody` — sau khối `if (!couple.isWaitingForPartner) { SizedBox(16), MoodCard }` (dòng ~1697–1700) thêm:
  `if (!couple.isWaitingForPartner) ...[ const SizedBox(height: 16), _gutter(_entrance(5, const RpsInviteCard())) ]` rồi tăng index entrance của "Kỷ niệm" (5→6, 6→7). Card tự đọc `RpsGameProvider` (watch) + `CoupleProvider`.
- Profile: `lib/screens/profile_screen.dart` `_AchievementsGridState.build` — hàng cuối (care full-width, dòng ~738–758) đổi thành `Row[Expanded(care), SizedBox(12), Expanded(rps)]`; thêm `_MedalPalette.game`; `_badgeCard` thêm param `double valueSize = 28` và `Widget? medalOverlay` (dot). Tỉ số lấy từ `RpsGameProvider.totalScore` (đã cache) — KHÔNG gọi service trực tiếp trong build.
- Mở màn: export 2 hàm `openRpsGame(BuildContext, {String? gameId})` + `openRpsHistory(BuildContext)` (đặt ở đầu file screen, `RouteSettings(name:'RpsGame'/'RpsHistory')`) — pattern `openCareMessageScreen`.

**Hành vi UI cần khớp spec PO (§4 overview)**
- `openRpsGame()` không gameId: provider có `openGame` (invited/playing, chưa quá 10') → dùng ván đó; không có → tạo mới. Có gameId nhưng doc `finished` → hiện result của ván đó (cho phép xem lại từ inbox); `expired/cancelled` → state (e).
- **Presence heartbeat 3s** chỉ khi màn đang mounted + app foreground (`WidgetsBindingObserver`); rời màn → dừng (KHÔNG xoá key — CF `notifyRpsResult` dựa vào tuổi presence).
- **Đồng hồ**: khi nhận `startedAt` (Timestamp server) lần đầu, tính `offset = DateTime.now() − snapshot.metadata.hasPendingWrites ? … : startedAt` — đơn giản hơn: đọc `startedAt` từ snapshot server (`includeMetadataChanges`, bỏ qua snapshot `hasPendingWrites`), `remaining = 5s − (now − startedAt)`; nếu `remaining > 5s` (lệch đồng hồ máy) → clamp 5s. Chấp nhận lệch <1s (AC PO).
- Về 0: nút chuyển disabled ngay; đợi `finished` tối đa 2s → gọi `finishRpsGame`; hiện state `resolving` trong lúc đó. Nếu doc `finished` tới trước 0s (cả hai chọn sớm) → **KHÔNG chờ hết 5s**, nhảy reveal luôn (nhưng ring đang ở giữa → snap về 0 200ms rồi reveal).
- "Nhắc lại" = `cancel(oldGame)` + `create(new)` (không `rematchOf`) → CF push lại; cooldown 60s lưu trong state màn (không persist). Partner-side KHÔNG có nút này.
- "Chơi lại" từ result: `create(rematchOf: gameId)` → màn đổi `gameId` tại chỗ (không push route mới). Người kia đang ở result: provider watch `openGame` → màn tự đổi sang ván mới (state waiting → countdown) + snackbar nhẹ `rpsRematchToast`.
- Tên: mình/người ấy lấy từ `Couple.person1Name/person2Name` theo `createdByUserId` (y `MoodCard._partnerName`); fallback `reactionPartnerFallback`.
- Lịch sử: `fetchPage(30)` một-shot + infinite scroll + pull-to-refresh, gom theo ngày local (copy `_buildRows/_dayLabel` của care_timeline — tái dùng key `notifGroupToday`, `careTimelineYesterday`). Tỉ số tổng: aggregation `count()` ×3 (winnerUid==me / ==partner / null) hoặc đọc từ provider cache — Dev chọn, nhưng scoreboard phải hiện trước list (shimmer riêng).
- Emoji render bằng `Text` (font hệ thống fallback) — KHÔNG nhúng font emoji; test iOS+Android cùng 3 emoji ✌️ ✊ ✋ ⏳.
- Analytics: `rps_invite_sent`, `rps_game_finished{result: win|loss|draw|timeout}` (no content).
- Thứ tự tab-map: `rps_invite` push tap → `openRpsGame(gameId)` (cold-start qua `NotificationTapRouter.pendingHomeFocus` mở rộng); `rps_result` → `openRpsHistory`. Cập nhật CẢ 2 chỗ map (push service + `AppNotification.targetHomeTab`).

**Files Dev cần tạo/sửa (thứ tự đề xuất)**
1. `lib/l10n/app_vi.arb` + `app_en.arb` — toàn bộ key §9 → `flutter gen-l10n`.
2. `lib/models/rps_game.dart` (`RpsGame`, `RpsMove`, `RpsChoice` enum + `emoji`/`label(l10n)`/`beats`), `lib/services/rps_game_service.dart`.
3. `lib/providers/rps_game_provider.dart` (openGame watch · pendingInviteFromPartner · totalScore · weekScore) + wire named-param ở `lib/services/session_resolver.dart` + `MultiProvider` `lib/main.dart`.
4. `lib/widgets/rps_choice_tile.dart` (§5.3) — tách riêng để reuse ở result (lá bài dùng tile biến thể `large`).
5. `lib/screens/rps_game_screen.dart` (4+2 state, confetti, `openRpsGame`).
6. `lib/screens/rps_history_screen.dart` (`openRpsHistory`).
7. `lib/widgets/rps_invite_card.dart` + chèn `home_screen.dart` (§8 điểm chèn).
8. `lib/screens/profile_screen.dart` — huy hiệu + palette + dot.
9. `lib/models/app_notification.dart` (`rpsInvite`, `rpsResult`, field `gameId`) + `lib/screens/notification_center_screen.dart` (icon/tap) + `lib/services/push_notification_service.dart` (`_handleNotificationTap` 2 type + `pendingHomeFocus` mang gameId).
10. `lib/services/analytics_service.dart` — 2 event.
11. Feature tour entry `lib/data/feature_tour_entries.dart` (`sinceBuild` = build kế tiếp) — copy §9 `tourRps*`.

## 9. Copy (song ngữ — bắt buộc; xưng "bạn / người ấy / chúng mình")

### 9.1 Entry + header
| Key | VI | EN |
|---|---|---|
| `rpsBadge` | OẲN TÙ TÌ | ROCK · PAPER · SCISSORS |
| `rpsHistoryBadge` | LỊCH SỬ VÁN | MATCH HISTORY |
| `rpsEntryTitle` | Oẳn tù tì | Rock, paper, scissors |
| `rpsEntryIdleSubtitle` | Rủ người ấy một ván nhé | Challenge your person to a round |
| `rpsEntryWeekScore` | Tuần này {win} – {draw} – {loss} | This week {win} – {draw} – {loss} |
| `rpsEntryInvitedTitle` | Người ấy đang rủ! | Your person is challenging you! |
| `rpsEntryInvitedSubtitle` | Vào chọn trong 5 giây ⏱️ | Pick within 5 seconds ⏱️ |
| `rpsEntryPendingTitle` | Đang chờ người ấy… | Waiting for your person… |
| `rpsEntryPendingSubtitle` | Lời mời còn hiệu lực 10 phút | Invite stays open for 10 minutes |
| `rpsEntryCtaPlay` | Chơi | Play |
| `rpsEntryCtaJoin` | Vào chơi | Join |
| `rpsEntryCtaOpen` | Mở | Open |
| `badgeRpsLabel` | Oẳn tù tì | Rock-paper-scissors |
| `rpsScoreFormat` | {win} – {draw} – {loss} | {win} – {draw} – {loss} |
| `rpsScoreSemantics` | Tỉ số: bạn {win}, hoà {draw}, người ấy {loss} | Score: you {win}, draw {draw}, your person {loss} |

### 9.2 Lựa chọn
| Key | VI | EN |
|---|---|---|
| `rpsChoiceScissors` | Kéo | Scissors |
| `rpsChoiceRock` | Búa | Rock |
| `rpsChoicePaper` | Bao | Paper |
| `rpsChoiceNone` | Bỏ lượt | No pick |
| `rpsChoiceSemantics` | Chọn {choice} | Pick {choice} |
| `rpsRulesHint` | Kéo cắt Bao · Bao bọc Búa · Búa đập Kéo | Scissors cut Paper · Paper wraps Rock · Rock breaks Scissors |
| `rpsRuleScissorsPaper` | Kéo cắt Bao | Scissors cut Paper |
| `rpsRulePaperRock` | Bao bọc Búa | Paper wraps Rock |
| `rpsRuleRockScissors` | Búa đập Kéo | Rock breaks Scissors |

### 9.3 Màn chơi — waiting / countdown / chosen
| Key | VI | EN |
|---|---|---|
| `rpsMeLabel` | Mình | Me |
| `rpsPartnerLabel` | Người ấy | Your person |
| `rpsVs` | vs | vs |
| `rpsWaitingTitle` | Đang chờ người ấy… | Waiting for your person… |
| `rpsWaitingBody` | Người ấy đã nhận thông báo. Khi cả hai cùng ở đây, ván chơi bắt đầu ngay. | They've been notified. The round starts the moment you're both here. |
| `rpsWaitingBodyInvitee` | Đang kết nối với người ấy… Ván chơi bắt đầu khi cả hai cùng ở đây. | Connecting to your person… The round starts once you're both here. |
| `rpsPartnerLeftHint` | Người ấy vừa rời màn chơi. Ván sẽ bắt đầu khi người ấy quay lại. | Your person stepped away. The round starts when they're back. |
| `rpsNudgeCta` | Nhắc lại | Nudge again |
| `rpsNudgeCooldown` | Nhắc lại ({seconds}s) | Nudge again ({seconds}s) |
| `rpsNudgeSentToast` | Đã nhắc người ấy lần nữa 🔔 | Nudged your person again 🔔 |
| `rpsCancelCta` | Huỷ lời mời | Cancel invite |
| `rpsCloseCta` | Đóng | Close |
| `rpsCancelledToast` | Đã huỷ lời mời | Invite cancelled |
| `rpsStartToast` | Bắt đầu! | Go! |
| `rpsCountdownPrompt` | Chọn ngay! | Pick now! |
| `rpsCountdownUnit` | GIÂY | SEC |
| `rpsCountdownSemantics` | Còn {seconds} giây | {seconds} seconds left |
| `rpsChosenWaiting` | Đã chọn ✓ · Chờ người ấy… | Locked in ✓ · Waiting for your person… |
| `rpsResolving` | Đang mở kết quả… | Revealing… |
| `rpsResolvingSlow` | Kết nối chậm một chút… | Connection is a bit slow… |
| `rpsReloadCta` | Tải lại | Reload |
| `rpsOfflineHint` | Mất mạng — đồng hồ vẫn chạy, lựa chọn sẽ gửi khi có mạng | Offline — the clock keeps running; your pick sends once you're back online |

### 9.4 Kết quả
| Key | VI | EN |
|---|---|---|
| `rpsRevealOne` | 1 | 1 |
| `rpsRevealTwo` | 2 | 2 |
| `rpsRevealThree` | 3! | 3! |
| `rpsResultWin` | Bạn thắng 🎉 | You win 🎉 |
| `rpsResultLoss` | Người ấy thắng 😝 | Your person wins 😝 |
| `rpsResultDraw` | Hoà 🤝 | It's a draw 🤝 |
| `rpsResultRound` | {rule} — ván {n} | {rule} — round {n} |
| `rpsResultDrawSub` | Cùng ra {choice} — ván {n} | Both picked {choice} — round {n} |
| `rpsResultTimeoutPartner` | Người ấy không kịp chọn | Your person didn't pick in time |
| `rpsResultTimeoutMe` | Bạn không kịp chọn | You didn't pick in time |
| `rpsResultTimeoutBoth` | Cả hai bỏ lượt — ván này hoà | Both skipped — this round is a draw |
| `rpsRematchCta` | Chơi lại | Play again |
| `rpsHistoryCta` | Xem lịch sử | View history |
| `rpsRematchToast` | Người ấy rủ chơi lại! | Your person wants a rematch! |
| `rpsResultSemantics` | {title}. Bạn ra {mine}, người ấy ra {theirs}. | {title}. You picked {mine}, your person picked {theirs}. |

### 9.5 Expired / cancelled / error
| Key | VI | EN |
|---|---|---|
| `rpsExpiredTitle` | Lời mời đã hết hạn | Invite expired |
| `rpsExpiredBody` | Người ấy không kịp vào trong 10 phút. Rủ lại khi cả hai rảnh nhé. | Your person didn't make it within 10 minutes. Try again when you're both free. |
| `rpsCancelledTitle` | Người ấy đã huỷ lời mời | Your person cancelled the invite |
| `rpsCancelledBody` | Không sao, chúng mình có thể chơi ván khác bất cứ lúc nào. | No worries — you two can play another round any time. |
| `rpsInviteAgainCta` | Rủ lại | Challenge again |
| `rpsErrorTitle` | Chưa mở được ván chơi | Couldn't open the round |
| `rpsErrorBody` | Kiểm tra mạng rồi thử lại nhé. | Check your connection and try again. |
| `rpsNeedCouple` | Cần có người ấy trong app để chơi cùng. | You need your person in the app to play. |

### 9.6 Lịch sử
| Key | VI | EN |
|---|---|---|
| `rpsScoreMe` | MÌNH | ME |
| `rpsScoreDraw` | HOÀ | DRAW |
| `rpsScorePartner` | NGƯỜI ẤY | THEM |
| `rpsHistoryTotal` | {count} ván đã chơi | {count} rounds played |
| `rpsHistoryWinStreak` | Chuỗi thắng: {count} | Win streak: {count} |
| `rpsOutcomeWin` | Bạn thắng | You won |
| `rpsOutcomeLoss` | Người ấy thắng | They won |
| `rpsOutcomeDraw` | Hoà | Draw |
| `rpsOutcomeSkipped` | Bỏ lượt | Skipped |
| `rpsHistoryRowSemantics` | {time}: bạn {mine}, người ấy {theirs}, {outcome} | {time}: you {mine}, your person {theirs}, {outcome} |
| `rpsHistoryEmptyTitle` | Chưa có ván nào | No rounds yet |
| `rpsHistoryEmptyBody` | Mọi ván oẳn tù tì của chúng mình sẽ được lưu lại ở đây — kể cả ván hoà. | Every round you two play lands here — draws included. |
| `rpsHistoryEmptyCta` | Rủ người ấy một ván | Challenge your person |
| `rpsHistoryLoadError` | Chưa tải được lịch sử. | Couldn't load the history. |
| (tái dùng) `retry`, `notifGroupToday`, `careTimelineYesterday`, `reactionPartnerFallback`, `back` | — | — |

### 9.7 Push + inbox (CF localize theo `languageCode`; `<name>` = tên người gửi RAW, fallback `partnerFallback` như daily-question)
| Key (CF `RPS_COPY`) | VI | EN |
|---|---|---|
| `invite.title` | Oẳn tù tì! ✌️✊✋ | Rock, paper, scissors! ✌️✊✋ |
| `invite.body` | <name> rủ bạn chơi một ván — vào chọn trong 5 giây ⏱️ | <name> challenged you to a round — pick within 5 seconds ⏱️ |
| `result.win.title` | Bạn thắng rồi 🎉 | You won 🎉 |
| `result.win.body` | Ván oẳn tù tì vừa rồi là của bạn. Xem lại trong lịch sử nhé. | That round was yours. Check the history to relive it. |
| `result.loss.title` | Người ấy thắng rồi 😝 | Your person won 😝 |
| `result.loss.body` | Thua một ván thôi mà — rủ chơi lại cho đỡ tức nào. | Just one round — challenge them to a rematch. |
| `result.draw.title` | Hoà! 🤝 | A draw! 🤝 |
| `result.draw.body` | Chúng mình ra giống nhau. Thêm ván nữa để phân thắng bại? | You both picked the same. One more to settle it? |
| `result.timeout.body` (ghép với title theo winner) | Ván vừa rồi có người không kịp chọn. | Someone didn't pick in time that round. |
| inbox `notifRpsInviteTitle` | {name} rủ bạn oẳn tù tì | {name} challenged you to rock-paper-scissors |
| inbox `notifRpsInviteBody` | Vào chơi ngay — lời mời còn hiệu lực 10 phút | Jump in — the invite is open for 10 minutes |

### 9.8 Feature tour (1 entry, release kế tiếp)
| Key | VI | EN |
|---|---|---|
| `tourRpsTitle` | Oẳn tù tì cùng người ấy | Rock-paper-scissors together |
| `tourRpsBody` | Rủ một ván, cả hai cùng chọn trong 5 giây, kết quả lộ cùng lúc. Lịch sử và tỉ số lưu ở Hồ sơ. | Send a challenge, both pick within 5 seconds, the reveal is simultaneous. History and score live on your Profile. |

## 10. Assets
- Không asset mới: emoji hệ thống (✌️ ✊ ✋ ⏳ 🎉 😝 🤝), Iconsax Plus (`game`, `clock`, `timer_pause`, `close_circle`, `refresh`, `tick_circle`, `cloud_cross`, `wifi_square`, `notification`), `confetti` package đã có.

## 11. Acceptance (design)
- [x] Mọi state có wireframe/mô tả (Home ×3, Profile ×3, Game ×9, History ×4).
- [x] Copy đủ VI+EN (UI + push + inbox + tour), xưng "bạn/người ấy/chúng mình".
- [x] Token hex/radius/spacing/typo/shadow chỉ từ design-system; 1 đề xuất bổ sung (`_MedalPalette.game`) ghi rõ.
- [x] Reduce Motion fallback + Semantics ghi rõ.
- [x] Điểm chèn Home/Profile chỉ đúng dòng trong file hiện tại.
- [ ] Dev dựng xong → Designer soi lại 4 state màn chơi trên simulator (đặc biệt reveal + confetti + ring ≤1s).

## Nhật ký design
- [2026-09-13] [Designer] Thiết kế trọn feature: entry Home (`RpsInviteCard` 3 state dưới MoodCard, không thêm icon header) + huy hiệu Profile tỉ số "W – D – L" ghép cặp với care + badge lời mời (viền/dot, không tab badge); `RpsGameScreen` 6 state (waiting/countdown/chosen/result/expired/cancelled + resolving/error/offline), `RpsChoiceTile` 108×120 chọn = fill sunsetRomance, ring 168 + haptic, reveal "1·2·3!" + confetti chỉ khi thắng + Reduce Motion fallback; `RpsHistoryScreen` scoreboard 3 cột + list gom ngày theo pattern care_timeline; copy VI/EN ~95 key kể cả push 3 biến thể + inbox + tour; danh sách 11 file Dev theo thứ tự. Đề xuất bổ sung design system: `_MedalPalette.game` peach.
