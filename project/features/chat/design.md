# Chat — Design spec (tab Trò chuyện, tab thứ 2/4)

> Designer sở hữu file này. Spec đủ để Dev dựng không phải đoán. Tuân thủ D1–D9 (overview.md) + design-system mục ⭐ 2026-06-11 (mực navy, EyebrowChip, type scale, ripple, 🔒 RULE header).

## 0. Mục tiêu

- Chat realtime 2 người = lý do mở app hằng ngày; tab đứng cạnh Home (vị trí ngón cái).
- **Nguyên tắc số 1: tab Chat phải nói CÙNG ngôn ngữ với `LoveNoteHistoryScreen`** (messenger-style user vừa duyệt 2026-06-11) — 2 màn hội thoại không được lệch nhau. Bubble/divider/composer tái dùng tối đa, Dev nên EXTRACT widget chung (xem Dev notes).
- Chat cần tối đa diện tích đọc tin → header gọn hơn rule thường (quyết định + lý do ở §B1).

## 1. Phạm vi / màn hình

| # | Hạng mục | Loại |
|---|---|---|
| A | Bottom nav 3 → 4 tab + unread dot (D1, D7) | Sửa `home_screen.dart` nav |
| B | `ChatTab` — tab thứ 2 IndexedStack (KHÔNG phải route push, không nút back) | Màn mới |
| C | Lối vào lịch sử lời nhắn: icon `history` trên header tab Chat (D6) | Push `LoveNoteHistoryScreen` sẵn có |
| D | Copy vi+en + push/notif-center cho CF `notifyChatMessage` (D4) | l10n |

Ngoài phạm vi (D9): ảnh/sticker/emoji-react, typing indicator, sửa/xoá, migrate noteHistory. Nợ ghi sẵn: nút "cuộn xuống tin mới" khi đang đọc tin cũ (v1 bỏ — Flutter reverse-list tự giữ vị trí, không giật).

## 2. User flow

```
Bottom nav tab 💬 (dot đỏ nếu có tin partner chưa xem)
  └─ ChatTab
       ├─ couple waiting_partner → state Mời ghép đôi (CTA → tab Hồ sơ) — KHÔNG composer
       ├─ couple active, 0 tin   → Empty state + composer sẵn sàng
       └─ couple active, có tin  → list reverse:true neo đáy
            ├─ cuộn lên hết → "Xem thêm" load older 50 (D5)
            ├─ icon history (header) → push LoveNoteHistoryScreen
            └─ composer: gõ → đĩa gửi sáng → gửi optimistic → bubble hiện ngay (pending mờ) → server confirm → rõ nét
Push chat_message (tap) / notif-center entry → mở tab Chat (index 1) qua NotificationTapRouter
Vào tab / tin mới đến khi tab đang mở → ghi marker seen → dot tắt
```

## 3. Wireframe ASCII

```
┌──────────────────────────────────────────┐
│ (SafeArea top)                            │
│ [💬 CHUYỆN CỦA CHÚNG MÌNH]      (🕘)      │ ← hàng GHIM: EyebrowChip + HeaderIconButton history
│ ──────────── vùng list cuộn ───────────── │
│  Trò chuyện                       (32 w800)│ ← title+subtitle = ITEM ĐẦU list, CUỘN khuất
│  Nơi hai đứa nói đủ thứ chuyện trên đời.  │
│                                           │
│            ( Xem thêm ↑ )                 │ ← load-more pill (chỉ khi hasMore)
│            ─ HÔM QUA 21:14 ─              │ ← time divider micro-caps
│  (T)┌────────────────┐                    │ ← partner: trắng đặc, trái, avatar 24 cuối cụm
│     │ Em ăn cơm chưa │                    │
│     └────────────────┘                    │
│                 ┌───────────────────────┐ │ ← mine: NAVY đặc chữ trắng, phải
│                 │ Anh vừa về tới nhà nè │ │
│                 └───────────────────────┘ │
│                 ┌──────────┐ (cụm 3px,    │
│                 │ Nhớ em 💞 │  góc dẹt 10) │
│                 └──────────┘ ◷            │ ← pending: mờ .65 + clock 11
│ ┌───────────────────────────────────────┐ │
│ │ (Nhắn gì đó cho người ấy…      ) (➤) │ │ ← composer CARD NỔI trắng r24, margin 16
│ └───────────────────────────────────────┘ │
│   ╭───────────────────────────────────╮   │
│   │  ♥Trang chủ  💬  🖼  👤          │   │ ← floating nav 84, pill active trượt
│   ╰───────────────────────────────────╯   │
└──────────────────────────────────────────┘
```

## A. Bottom nav 4 tab (D1)

**Thứ tự + icon + label (key l10n):**

| Index | Tab | Icon (unselected = selected trừ Home) | Label |
|---|---|---|---|
| 0 | Trang chủ | `Icons.favorite_border_rounded` / `favorite_rounded` (giữ — Lucide không có heart filled) | `navHome` |
| 1 | **Trò chuyện** | `LucideIcons.messageCircle` | `navChat` (MỚI) |
| 2 | Thư viện | `LucideIcons.image` | `navMemories` (giữ key, không đổi text) |
| 3 | Hồ sơ | `LucideIcons.user` | `navProfile` |

**Cơ chế pill GIỮ NGUYÊN code hiện tại** (`_buildFloatingNavigationBar`): `itemWidth = maxWidth / 4` tự co — nav 84/margin 16/inner padding 6/pill inset 5, pill gradient `sunset1→accentLoveDeep` r20 trượt 320ms easeOutCubic, icon 22 (selected trắng scale 1.12, unselected trắng .75), label 11 w700 chỉ hiện khi selected, `maxLines:1 ellipsis`. Số đo tham chiếu: iPhone 390pt → itemWidth 86.5, pill ~76.5 (3 tab cũ là ~104); iPhone SE 375pt → pill ~71 — label dài nhất "Trò chuyện" @11px w700 ≈ 62–66px vẫn vừa, không cần đổi cỡ chữ. KHÔNG thêm logic mới cho pill.

**Unread dot (D7):**
- Stack quanh icon tab Chat, `clipBehavior: Clip.none`, `Positioned(top: -3, right: -4)`.
- Chấm tròn tổng **10×10**: lõi `accentLoveDeep` (#E63956) 7px + **viền trắng đặc 1.5** (tách khỏi icon + nền glass; trên nền pill gradient không bao giờ xuất hiện — xem dòng dưới).
- **Tab Chat đang active → KHÔNG dot** (vào tab = seen, ghi marker ngay khi `_selectedIndex` thành 1 và khi tin mới đến lúc tab đang mở). Dot chỉ render khi `index == 1 && !isSelected && hasUnread`.
- Xuất hiện/biến mất: `AnimatedScale` 200ms easeOutCubic (0→1) — Reduce Motion: hiện/ẩn tức thì.
- Semantics: khi có dot, label tab = `navChat` + `chatUnreadDotSemantics`.

**Logic hasUnread (D7):** marker Hive `chat_seen_<coupleId>` (box `app_settings`, value = epoch-millis tin partner mới nhất đã thấy). `hasUnread = createdAt(tin partner mới nhất trong window realtime) > marker`. Tin của chính mình KHÔNG bật dot.

## B. Layout tab Chat

### B1. Header — quyết định + lý do

🔒 RULE yêu cầu header lớn landing-style; chat cần tối đa diện tích. **Chốt: tách 2 tầng** — vẫn 100% token chuẩn, không chế kiểu mới:

1. **Hàng GHIM** (luôn hiển thị, list KHÔNG trượt xuống dưới nó — `Column[pinnedRow, Expanded(list), composer]`): `Padding fromLTRB(20, 8, 12, 4)` → `Row[ EyebrowChip(label: chatBadge, icon: LucideIcons.messageCircle) · Spacer · HeaderIconButton(LucideIcons.history) ]`. EyebrowChip y nguyên widget chuẩn (white .72, viền .65, shadow rose .14, icon 13 `accentLoveDeep`, label 11 w700 navy .70). HeaderIconButton = icon trần navy 24, vùng chạm 44, ripple r16 (ngôn ngữ header-action hiện hành) → push `LoveNoteHistoryScreen` (D6); tooltip + Semantics = `loveNoteHistoryTitle`.
2. **Title block = ITEM ĐẦU (trên cùng) của list reverse** — cuộn khuất khi đọc tin (pattern `_HistoryHeader` của history screen): `pageTitleStyle` 32 "Trò chuyện" (`navChat`) → 8 → `pageSubtitleStyle` (`chatHeaderSubtitle`) → 12.

*Lý do:* chip ghim giữ brand + neo cố định cho action history (nếu cuộn cả cụm thì lối vào lịch sử biến mất khi đọc tin); title 32 vẫn có mặt đúng rule nhưng nhường diện tích khi hội thoại dài — rule cho phép header cuộn theo nội dung (Settings/history đã thế). Không bar nền/blur ghim đè list → không vấn đề contrast.

### B2. List tin nhắn

- `ListView.builder(reverse: true)` neo đáy, mở ở tin mới nhất; items dựng oldest→newest rồi feed back-to-front (copy nguyên thuật toán `_ChatList` của history). Padding list `fromLTRB(16, 0, 16, 12)`.
- **Cụm (burst):** tin liền nhau cùng người, không divider chen giữa → cách **3px**, góc phía người gửi giữa cụm dẹt **10** (đã chốt ở history — bản "đuôi 6" bị loại vì răng cưa); khác cụm cách **10px**.
- **Time divider:** căn giữa, micro-caps 11 w700 `textSecondary` ls0.5 UPPERCASE, padding top 20/bottom 8 (tái dùng `_TimeDivider`). **Quy tắc hiện divider cho chat (dày tin hơn love-note):** ngày mới **HOẶC** cách tin liền trước **≥ 60 phút**. Format giữ nguyên `_TimeDivider` (hôm nay → `HH:mm`; cùng năm → `MMMd + HH:mm`; cũ hơn → `yMMMd + HH:mm`; `DateFormat(locale)` — D3). KHÔNG time meta dưới từng bubble (divider + pending icon là đủ; per-bubble time là nợ v1.1 nếu user cần).
- **Load older (D5):** pill "Xem thêm" (`journalLoadMore`) outlined `accentLove` 1.4, r999, h44, chevronUp 16, label 14 w700 `accentLove`, spinner 16 inline khi loading — tái dùng nguyên `_LoadMoreButton`; nằm giữa title block và tin cũ nhất, chỉ render khi `hasMore`.

### B3. Bubble spec (CHỐT = theo history đã duyệt 2026-06-11, KHÔNG theo two-tone ritual-card)

| Thuộc tính | Mine (phải) | Partner (trái) |
|---|---|---|
| Nền | **NAVY `textPrimary` #1A1A2E đặc** | **`cardSurface` #FFFFFF đặc** + shadow black .05 blur 8 offset(0,3) |
| Chữ | trắng 15 h1.4 (~15:1) | `textPrimary` 15 h1.4 (~15.6:1) |
| Radius | 18; góc PHẢI giữa cụm dẹt 10 | 18; góc TRÁI giữa cụm dẹt 10 |
| Padding | 14 ngang × 10 dọc | 14 × 10 |
| maxWidth | 72% bề rộng màn | 72% |
| Avatar | KHÔNG | chữ cái đầu tên partner, đĩa 24 `primaryGradient`, chữ trắng 11 w800 — CHỈ ở bubble CUỐI cụm, bubble khác chừa slot 24+8 |

*Lý do chốt khác gợi ý "mine rose .10 / partner lavender .10":* two-tone rose/lavender là ngôn ngữ Q&A trong CARD nội dung (ritual/journal — 2 khối tĩnh cạnh nhau); còn bubble HỘI THOẠI đã được chốt navy/trắng ở history CÙNG NGÀY sau khi loại gradient đỏ (vibrate trên nền hồng + trùng palette destructive, trắng-trên-rose chỉ ~3.2:1). Navy = màu primary-action toàn app = "hành động của mình". 2 màn chat lệch màu bubble = lỗi đồng nhất.

### B4. Composer (D8)

**Dạng: CARD NỔI trắng đặc** (khác strip full-width của history — lý do: tab này có floating nav 84 bên dưới; strip trắng chạm đáy sẽ chui dưới nav glass → bẩn; card nổi margin 16 cùng ngôn ngữ "vật thể nổi" với nav). KHÔNG glass (luật: glass chỉ nav/overlay/form auth).

- Container: margin ngang 16, **r24, `cardSurface` trắng đặc, shadow chuẩn black .06 blur 16 offset(0,10)** (ContentCard token), padding trong `fromLTRB(10, 8, 8, 8)`.
- Input: `TextField` pill **`surfaceLight` r22 KHÔNG viền** (override `border/enabledBorder/focusedBorder = none` — viền rose theme trong chat đọc như lỗi validation, đã chốt ở history), `minLines:1 maxLines:5`, **`maxLength: 1000`** (khớp rules D2) `counterText: ''` (ẩn), `textCapitalization.sentences`, chữ 15 h1.4 `textPrimary`, hint 15 `textTertiary` = `chatComposerHint`, contentPadding 16×11.
- Cách input→nút: 10.
- **Đĩa gửi 44 tròn, ghost-state** (AnimatedContainer 180ms easeOutCubic): rỗng/chỉ-space → nền `surfaceLight` + icon `LucideIcons.send` 19 `textTertiary`, **không bấm được**; có draft → nền **NAVY `textPrimary`** + icon trắng; đang gửi → giữ navy + spinner trắng 18/2.2. Ripple trắng .15 CircleBorder. Semantics `chatSendSemantics`, button:true.
  - *Lưu ý cho PO:* D8 ghi "nút gửi tròn rose" — Designer chốt **NAVY** để đồng bộ tuyệt đối với composer history (chốt navy cùng ngày 2026-06-11, "đĩa gửi sáng màu bubble gửi đi") và với bubble mine navy. 2 composer chat 2 màu = lỗi đồng nhất. PO muốn rose thì đổi cả 2 nơi cùng lúc.
- Hành vi gửi: trim, chặn rỗng; `TextInputAction.send`/submit cũng gửi; **giữ bàn phím sau gửi** (clear controller, KHÔNG unfocus); optimistic (tin hiện ngay — §5 pending); lỗi → giữ draft + SnackBar `chatSendFailed`.
- **Vị trí & bàn phím (extendBody):** composer trong flow `Column` (không overlay) → list không bao giờ bị che. Padding đáy composer animate (`AnimatedPadding` 260ms easeOutCubic — ĐỒNG NHỊP AnimatedSlide của nav):
  - Bàn phím ĐÓNG: `bottom = safeAreaBottom + 16 (navMargin) + 84 (navHeight) + 10` — composer nổi ngay TRÊN nav, hở 10.
  - Bàn phím MỞ (nav tự ẩn — hành vi sẵn có): `bottom = 10` (+ viewInsets do Scaffold resize lo) — composer sát trên bàn phím.
  - Điều kiện = `MediaQuery.viewInsets.bottom > 0` (cùng check với nav).

## 4. States

| State | Render |
|---|---|
| **Loading lần đầu** (stream chưa về, 0 tin) | `_ChatSkeleton` pattern history: title block + 5–6 ShimmerSkeleton bubble h40 r18 xen kẽ trái/phải (trái chừa slot avatar 32). KHÔNG spinner giữa màn. Composer vẫn hiện (disabled gửi vì rỗng). |
| **Empty** (active, 0 tin) | Giữa vùng list: đĩa 72 `cardSurface` .7 tròn + `LucideIcons.messageCircle` 30 `accentRose` → 16 → `chatEmptyHint` 14 h1.5 `textSecondary` căn giữa, padding ngang 40. Title block vẫn ghim trên cùng (pattern empty của history). Composer hoạt động bình thường — empty mời gõ ngay. |
| **Waiting partner** (couple chưa active) | KHÔNG composer. Giữa màn: đĩa 72 + `LucideIcons.userPlus` 30 `accentRose` → 16 → `chatWaitingPartnerTitle` 16 w700 `textPrimary` → 8 → `chatWaitingPartnerBody` 14 h1.5 `textSecondary` → 20 → nút pill h52 r999 navy theme label `chatWaitingPartnerCta` → **switch tab Hồ sơ (index 3)** nơi có tile mã mời (không push màn mới). |
| **Pending (optimistic)** | Bubble mine render NGAY, `hasPendingWrites` (snapshot metadata) → bọc `AnimatedOpacity` **.65**, kèm `LucideIcons.clock3` 11 `textTertiary` đặt cạnh đáy-phải ngoài bubble; server confirm → opacity 1.0 (220ms) + icon biến mất. KHÔNG duplicate (latency compensation của Firestore, không tự chèn local item). Semantics bubble pending thêm `chatSending`. |
| **Send fail** | Giữ draft trong input, SnackBar floating navy chuẩn `chatSendFailed`. (Tin offline đã vào queue Firestore thì giữ pending mờ — tự sync khi online lại, AC2.) |
| **Disabled gửi** | Draft rỗng/toàn space → đĩa ghost không bấm; đang `_sending` → chặn double-send. |

## 5. Interaction / Animation (token AppMotion, easeOutCubic)

| Sự kiện | Spec |
|---|---|
| Tin MỚI xuất hiện (mine + partner, chỉ tin đến sau khi mở tab) | fadeIn + slideY 8px **200ms** easeOutCubic, chạy 1 lần theo message id (pattern `EntranceReveal`/_OnceEntrance). **Reduce Motion → hiện tĩnh.** Tin load từ lịch sử/trang older: KHÔNG animate. |
| Pending → confirmed | AnimatedOpacity .65→1.0, 220ms. |
| Đĩa gửi ghost↔armed | AnimatedContainer 180ms (đã có pattern history). |
| Composer đổi vị trí theo nav/bàn phím | AnimatedPadding 260ms easeOutCubic (đồng nhịp nav slide 260/220). |
| Unread dot in/out | AnimatedScale 200ms; Reduce Motion → tức thì. |
| Haptic | `selectionClick` khi tap gửi + đổi tab (sẵn có); `mediumImpact` khi gửi thành công. |
| TickerMode | Tab 4 đều bọc `TickerMode(enabled: selected)` như cũ; ChatTab không có Timer riêng. |
| Bàn phím | Nav ẩn (sẵn có AnimatedSlide/Opacity); giữ bàn phím sau gửi. |

**A11y:** Semantics — đĩa gửi (`chatSendSemantics`, button); input (hint tự đọc); tab chat khi có dot (`chatUnreadDotSemantics`); avatar partner `excludeSemantics` (trang trí, tên đã rõ từ ngữ cảnh); bubble đọc mặc định text + thêm `chatSending` khi pending. Contrast: trắng/navy ~15:1 ✓, navy/trắng ~15.6:1 ✓, divider `textSecondary` trên blush ✓ (đã pass ở history), hint `textTertiary` trên `surfaceLight` = placeholder (không phải nội dung). Touch target ≥44: đĩa gửi 44, HeaderIconButton 44, load-more h44, nav item ≥48.

## 6. Localization (key MỚI — thêm CẢ `app_en.arb` + `app_vi.arb`, KHÔNG ICU; chạy gen-l10n)

| Key | vi | en |
|---|---|---|
| `navChat` | Trò chuyện | Chat |
| `chatBadge` | CHUYỆN CỦA CHÚNG MÌNH | JUST THE TWO OF US |
| `chatHeaderSubtitle` | Nơi hai đứa nói đủ thứ chuyện trên đời. | Where the two of you talk about everything. |
| `chatEmptyHint` | Chưa có tin nhắn nào — gửi lời đầu tiên cho người ấy nhé 💬 | No messages yet — send your love the first one 💬 |
| `chatComposerHint` | Nhắn gì đó cho người ấy… | Message your love… |
| `chatSendFailed` | Chưa gửi được tin nhắn. Thử lại nhé. | Couldn't send your message. Please try again. |
| `chatSendSemantics` | Gửi tin nhắn | Send message |
| `chatSending` | Đang gửi… | Sending… |
| `chatUnreadDotSemantics` | Có tin nhắn mới | New message waiting |
| `chatWaitingPartnerTitle` | Còn thiếu một người nè | One seat is still empty |
| `chatWaitingPartnerBody` | Mời người ấy ghép đôi để bắt đầu cuộc trò chuyện riêng của hai đứa. | Invite your partner to pair up and start your private chat. |
| `chatWaitingPartnerCta` | Mời ghép đôi | Invite to pair |

**Tái dùng (KHÔNG tạo mới):** title tab = `navChat` dùng luôn cho pageTitle · "Xem thêm" = `journalLoadMore` · tooltip/Semantics icon history = `loveNoteHistoryTitle` · label tab khác giữ `navHome`/`navMemories`/`navProfile`.

**Badge KHÔNG lặp title** ✓ ("CHUYỆN CỦA CHÚNG MÌNH" ≠ "Trò chuyện"; en "JUST THE TWO OF US" ≠ "Chat").

**Push CF `notifyChatMessage` (D4 — copy hardcode vi/en trong `functions/index.js` theo `languageCode`, KHÔNG preview nội dung tin trên lock screen — riêng tư, đồng hướng posture no-tracking):**

| | vi | en |
|---|---|---|
| title | Tin nhắn mới 💬 | New message 💬 |
| body | `<tên>` vừa gửi cho bạn một tin nhắn 💌 | `<name>` just sent you a message 💌 |

Notif-center entry (type `chat_message`): cùng title/body trên; icon hàng = `LucideIcons.messageCircle`; tap → NotificationTapRouter → **tab index 1**.

## 7. Assets

KHÔNG asset mới. Tất cả từ Lucide (`messageCircle`, `history`, `send`, `clock3`, `chevronUp`, `userPlus`) + token màu/gradient sẵn có. Đề xuất bổ sung design-system (ghi nhận, không token mới tự bịa): "chat input pill r22 borderless" = biến thể hợp lệ của input (r22 = nửa chiều cao 44 → stadium; đã ship ở history composer) — Dev/PO ghi vào token sheet khi tiện.

## 8. Dev notes (đọc kỹ — bẫy thật)

1. **⚠️ Deep-link map ĐỔI INDEX:** Gallery 1→2, Profile 2→3. `NotificationTapRouter` phải cập nhật: `photo_posted`/`photo_reaction` → **2**; `chat_message` (MỚI) → **1**; `partner_joined`/`partner_left`/`love_note`/`daily_question` → 0 giữ nguyên. Notif-center tap dùng chung router — sửa 1 chỗ. Test cold + warm (AC1).
2. **Tái dùng tối đa history screen:** `_ChatBubble`/`_TimeDivider`/`_LoadMoreButton`/`_ChatSkeleton`/composer → đề xuất extract ra `lib/widgets/` dùng chung 2 màn (tham số khác nhau: maxLength 140 vs 1000, divider rule thêm "≥60 phút", composer dạng strip vs card nổi, send qua `setMyNote` vs `ChatProvider.send`). Nếu extract đụng history thì giữ hành vi history y nguyên (D6).
3. **Provider mới `ChatProvider`** theo pattern pagination D5 (window realtime 50 + loadMore 50, cursor createdAt, map tích lũy theo id, dedup, guard couple sau await, teardown reset khi sign-out/leave). Wire watch ở `session_resolver` khi couple active (như love_note) — KHÔNG push thẳng `/home`.
4. **Optimistic = Firestore latency compensation** (`includeMetadataChanges` / `hasPendingWrites`) — KHÔNG tự chèn item local (nguồn duplicate, AC2).
5. **Marker seen:** ghi `chat_seen_<coupleId>` (epoch millis) khi: chuyển sang tab 1, và khi tin partner mới đến lúc `_selectedIndex == 1` (app foreground). Pattern `love_note_seen_`.
6. ChatTab nằm trong Scaffold của Home (extendBody:true) — composer theo §B4, KHÔNG SafeArea bottom riêng đè lên tính toán (safe-area đã cộng vào clearance khi bàn phím đóng).
7. Title 32 nằm trong list reverse = item logic ĐẦU (visual TRÊN CÙNG) — copy thuật toán items + `items.length - 1 - index` của history.
8. Label nav: chỉ THÊM `navChat`, không đổi `navMemories` ("Kỷ niệm"/"Memories" giữ nguyên — đừng đổi thành "Thư viện" nếu PO không yêu cầu).
9. Rules/CF theo D2–D4 (PO đã chốt); chạy `scripts/test-firebase-rules.sh`; deploy DEV, prod chờ lệnh.

## 9. Acceptance criteria (UI — bổ sung cho AC overview)

1. Nav 4 tab đúng thứ tự/icon/label; pill trượt đúng 4 vị trí; "Trò chuyện" không ellipsis trên ≥375pt.
2. Dot 10px (lõi 7 `accentLoveDeep` + viền trắng 1.5) tại top-right icon chat khi có tin partner chưa xem VÀ tab không active; vào tab → tắt; tin của mình không bật dot.
3. Header: chip + icon history ghim; title/subtitle cuộn khuất khi đọc tin; icon history mở LoveNoteHistoryScreen.
4. Bubble mine navy phải / partner trắng trái + avatar 24 cuối cụm; cụm 3px góc dẹt 10; maxWidth 72%; divider micro-caps theo ngày-mới-hoặc-gap-60-phút, format theo locale.
5. Composer card nổi: đứng trên nav (hở 10) khi bàn phím đóng, sát bàn phím khi mở (nav ẩn), chuyển 260ms mượt; đĩa gửi ghost↔navy đúng state; gửi xong giữ bàn phím + clear input; tin pending mờ .65 + clock, rõ lại khi confirm.
6. 4 state (skeleton/empty/waiting-partner/fail) đúng spec §4; waiting-partner KHÔNG composer, CTA nhảy tab Hồ sơ.
7. Reduce Motion: entrance tin + dot không animate; TickerMode không lỗi khi rời tab.
8. l10n đủ 12 key vi+en + push vi/en; không ICU; gen-l10n sạch; `flutter analyze` 0 issue.

## ✅ Re-check checklist cho Tester (đo được)

- [ ] Pill nav: đo width pill ≈ (mànW − 32 − 12)/4 − 10; trượt 320ms; label 11 w700 chỉ ở tab active.
- [ ] Dot: tổng 10px, lõi `#E63956`, viền trắng 1.5; KHÔNG hiện khi tab chat active; Semantics tab đọc "Có tin nhắn mới".
- [ ] Hai máy: gửi từ A → B thấy bubble ≤ ~1s, dot bật ở B khi B đang ở tab khác; B vào tab → dot tắt, kill app mở lại vẫn tắt (Hive marker).
- [ ] Bubble mine = `#1A1A2E` đặc chữ trắng (contrast ~15:1); partner = `#FFFFFF` chữ `#1A1A2E`; cụm 3 tin cùng người: khoảng 3px, góc giữa 10.
- [ ] Gửi 2 tin cách >60 phút (đổi giờ máy) → divider mới xuất hiện; đổi locale vi↔en → format divider đổi theo.
- [ ] Tắt mạng → gửi → bubble pending mờ + clock; bật mạng → tự rõ nét, KHÔNG duplicate.
- [ ] Nhập 1000 ký tự → gửi được; 1001 → input tự chặn; chỉ space → đĩa gửi ghost không bấm được.
- [ ] Bàn phím mở: nav ẩn + composer sát bàn phím; đóng: composer cách nav 10, không hở gradient/không che tin cuối.
- [ ] Couple waiting: không composer, CTA → tab Hồ sơ (index 3). Sau partner join (realtime) → tab chat chuyển sang trạng thái active không cần restart.
- [ ] Tap push `chat_message` cold + warm → đứng ở tab Trò chuyện; tap push `photo_posted` → tab Thư viện (index MỚI = 2 — regression quan trọng nhất).
- [ ] Bật Reduce Motion (iOS Settings) → tin mới hiện tĩnh, dot không scale.
- [ ] VoiceOver: đĩa gửi đọc "Gửi tin nhắn", tab chat có dot đọc kèm "Có tin nhắn mới".

## Nhật ký

- [2026-06-11] [Designer] Ra spec tab Trò chuyện: nav 4 tab + unread dot 10px; header 2 tầng (chip+history ghim, title cuộn); bubble tái dùng ngôn ngữ navy/trắng của history (từ chối two-tone rose/lavender — đó là ngôn ngữ card Q&A, không phải hội thoại); composer card nổi trắng r24 đứng trên floating nav, input pill r22 borderless maxLength 1000, đĩa gửi NAVY (điều chỉnh so với chữ "rose" trong D8 — đồng bộ composer history, đã flag PO); divider ngày-mới-hoặc-gap-60'; pending = opacity .65 + clock3; 12 key l10n vi/en + copy push không-preview; checklist Tester 12 mục.
