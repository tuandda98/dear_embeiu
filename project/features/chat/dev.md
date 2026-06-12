# Chat — Dev log

> Dev sở hữu file này. Ghi lại file/hàm đã đụng, thay đổi backend, trạng thái deploy.

## [2026-06-11] [dev] Implement trọn gói D1–D9 theo design.md — DEV deployed, chờ Tester

### Trạng thái: 💻 Dev xong full-stack · analyze 0 issue · 18 test pass · rules test 154 passing (10 case messages mới) · **ĐÃ DEPLOY DEV (rules + CF `notifyChatMessage`); PROD CHƯA deploy (chờ lệnh user)** · CHƯA commit

### File MỚI

| File | Nội dung |
|---|---|
| `lib/models/chat_message.dart` | `ChatMessage` (id, authorUserId, text, createdAt nullable khi pending, `isPending` từ `hasPendingWrites`, fromDoc/fromJson, parse Timestamp microsecond cho cursor) |
| `lib/services/chat_service.dart` | `watchMessages(coupleId, {limit:50})` orderBy createdAt desc + `snapshots(includeMetadataChanges:true)` (pending state); `fetchOlder` (cursor `Timestamp.fromDate`); `send` (trim ≤1000, `FieldValue.serverTimestamp()`, **fire-and-forget có chủ đích** — await sẽ treo composer khi offline, latency-compensation tự echo bubble pending). **Local fallback (quyết định Dev): Hive box `chat_messages_local` append-only, gửi/đọc local-only** — copy pattern `_appendLocalHistory` của LoveNoteService, rẻ nhất mà composer vẫn sống; KHÔNG sync partner (ghi rõ ở doc-comment) |
| `lib/providers/chat_provider.dart` | Pattern pagination SAU fix (map `_byId` tích lũy theo id + dedup, window 50, `hasMore`/`loadingMore`/`loadMore` + **guard `coupleId == _coupleId` sau MỌI await** — loadMore, markSeen, _loadSeenMarker, local re-load), `watchForCouple(coupleId, myUid)`/`clear()`. Sort desc với tiebreaker `_arrival` seq (pending createdAt null → đầu list; List.sort không stable). **Unread D7:** Hive `app_settings` key `chat_seen_<coupleId>` = epoch-millis tin partner mới nhất đã thấy; `hasUnread` (false khi marker chưa load — không nháy dot), `markSeen()` idempotent |
| `lib/screens/chat_screen.dart` | `ChatScreen(keyboardVisible, onRequestTab)` — header 2 tầng (hàng GHIM EyebrowChip `chatBadge` + HeaderIconButton history → push `LoveNoteHistoryScreen`; title block = item đầu list reverse, cuộn khuất); `_MessageList` divider ngày-mới-HOẶC-gap≥60ph, burst 3px góc dẹt 10, maxWidth 72%; `_ChatBubble` mine navy/partner trắng + avatar 24 cuối cụm + **pending = AnimatedOpacity .65 + clock3 11 ngoài bubble + Semantics `chatSending`**; `_MessageEntrance` (AnimationController thuần, KHÔNG flutter_animate — tránh crash element-tree như comment `_entrance` Home; chỉ animate tin đến SAU lần load đầu, set `_revealedIds` chống replay khi scroll-recycle; Reduce Motion → tĩnh); `_LoadMoreButton` (`journalLoadMore` — copy history); `_ChatSkeleton`; `_EmptyState`; `_WaitingPartnerState` (KHÔNG composer, CTA pill navy h52 → `onRequestTab(3)` tab Hồ sơ); composer card trắng r24 margin 16 + input pill surfaceLight r22 borderless maxLength 1000 counter ẩn + đĩa gửi 44 ghost↔NAVY (spec Designer, PO duyệt) + AnimatedPadding 260ms (đóng: `safeBottom+16+84+10`; mở: 10); haptic selectionClick/mediumImpact; giữ bàn phím sau gửi |

### File SỬA

| File | Thay đổi |
|---|---|
| `lib/screens/home_screen.dart` | Nav **4 tab** `[Home ♥ · Chat 💬(messageCircle) · Gallery 🖼 · Profile 👤]` (`_chatTabIndex=1`), IndexedStack chèn `TickerMode(ChatScreen)` index 1 (truyền `keyboardVisible` — **Scaffold strip viewInsets khỏi MediaQuery của body, đã verify source SDK** — và `onRequestTab`); TickerMode Gallery/Profile → 2/3; `_navLabel` + `_logTabScreenView` ['Home','Chat','Gallery','Profile']; "Xem tất cả" recent → index **2**; auto-`markSeen()` postFrame khi `_selectedIndex==1 && hasUnread` (cover cả tin đến lúc đang mở tab); **unread dot** Stack quanh icon (10px = lõi 7 accentLoveDeep + viền trắng 1.5, Positioned top-3/right-4, AnimatedScale 200ms, Reduce Motion = Duration.zero, chỉ render khi tab≠active) + Tooltip/Semantics kèm `chatUnreadDotSemantics`; re-arm `ChatProvider.watchForCouple` trong postFrame `_buildHomeTab`. **KHÔNG đụng `_entrance`** |
| `lib/main.dart` | Đăng ký `ChangeNotifierProvider(create: (_) => ChatProvider())` |
| `lib/app/session_resolver.dart` | Wire `chatProvider.watchForCouple` khi couple active; `chatProvider.clear()` ở cả 3 nhánh (guest / verify-email / no-couple) |
| `lib/services/push_notification_service.dart` | **Deep-link index ĐỔI:** `_homeTabIndex=0, _chatTabIndex=1, _galleryTabIndex=2`; case `chat_message` MỚI → 1; `photo_posted`/`photo_reaction` → 2 (qua hằng); 4 type cũ → 0 giữ. Comment cảnh báo sync 3 nơi |
| `lib/models/app_notification.dart` | Enum + parse `chatMessage`; `targetHomeTab`: photo → **2**, chatMessage → **1**, còn lại 0 (notif-center + auto-read theo tab dùng chung getter này → tự đúng) |
| `lib/screens/notification_center_screen.dart` | `_titleFor` case `chatMessage` → `notifChatMessage(name)`; icon hàng messageCircle/accentLove |
| `lib/screens/profile_screen.dart` | **Gỡ tile "Nhật ký lời nhắn"** khỏi "Tủ kỷ niệm" (D6) + divider + import; còn 2 hàng Journal/Streak, layout nguyên; screen+route GIỮ (lối vào mới = header chat) |
| `lib/l10n/app_en.arb` + `app_vi.arb` | +13 key: `navChat`, `chatBadge`, `chatHeaderSubtitle`, `chatEmptyHint`, `chatComposerHint`, `chatSendFailed`, `chatSendSemantics`, `chatSending`, `chatUnreadDotSemantics`, `chatWaitingPartnerTitle/Body/Cta`, `notifChatMessage(name)` — đúng copy design.md §C, no-ICU; `fvm flutter gen-l10n` sạch |
| `firestore.rules` | Block ADDITIVE `couples/{coupleId}/messages/{messageId}`: member read; create = author==auth.uid + `hasOnly([authorUserId,text,createdAt])` + text string 1..1000 + `createdAt == request.time` (chỉ serverTimestamp pass); **update/delete = false** (D3) |
| `firebase_rules_test/test/firestore.couples-sub.test.js` | +10 case messages: member create OK / 1000 OK / 1001 DENY / rỗng DENY / sai author DENY / thừa field DENY / createdAt cố định DENY / non-member read+create DENY / partner read OK / update+delete DENY (cả author). Suite **154 passing** |
| `functions/index.js` | CF v2 `notifyChatMessage` onDocumentCreated messages — pattern y `notifyLoveNote`: skip-self qua memberIds filter, authorName từ users (fallback "Người ấy"), `writeInboxNotifications` type `chat_message` **KHÔNG kèm nội dung tin** (privacy lock-screen, design §C), `sendToRecipientDevices` + `buildChatMessageText` vi/en ("Tin nhắn mới 💬 / <tên> vừa gửi cho bạn một tin nhắn 💌"). Không thêm mute-pref field (chat = always-on v1, như love_note) |

### Backend / Deploy

- ✅ `scripts/test-firebase-rules.sh` PASS (154 test, emulator).
- ✅ `node -c functions/index.js` (= `npm run lint`) OK.
- ✅ **DEV deployed (tonyembeiu-dev, 2026-06-11):** `npx firebase-tools deploy --only firestore:rules` + `--only functions:notifyChatMessage` (create thành công, Node 20 2nd-gen, us-central1).
- ⛔ **PROD: CHƯA — chờ lệnh user** (`--project prod`).
- Hive: KHÔNG adapter mới (box dynamic/String thuần) → không cần build_runner.

### Quyết định Dev (trade-off đã chốt)

1. **Local fallback = Hive local-only** (không disable composer): rẻ, đồng nhất pattern LoveNoteService; giới hạn = không sync partner, không pagination, stream one-shot (re-load sau send).
2. **KHÔNG extract bubble/divider chung với history** (design.md khuyên NÊN): copy-có-kỷ-luật vào `chat_screen.dart` để không đụng `love_note_history_screen.dart` vừa fix race. **NỢ:** hợp nhất `_ChatBubble`/`_TimeDivider`/`_LoadMoreButton`/`_ChatSkeleton` ra `lib/widgets/` khi cả 2 màn ổn định (param khác: maxLength 140/1000, divider per-day vs +gap60', composer strip vs card, pending chỉ chat có).
3. **`send()` fire-and-forget ở service:** await `.add()` khi offline sẽ treo spinner vô hạn; rules-DENY bất ngờ → tin biến mất im lặng (chấp nhận v1 — member hợp lệ không thể vi phạm rule vì client đã trim/clamp).
4. **`keyboardVisible` truyền từ HomeScreen:** đã verify Flutter SDK — Scaffold `resizeToAvoidBottomInset` xoá `viewInsets.bottom` khỏi MediaQuery của body → tab không tự đọc được; HomeScreen (context trên Scaffold) thấy đủ.
5. **Đĩa gửi NAVY** (không rose như chữ D8) — theo design.md đã được PO duyệt, đồng bộ composer history.
6. **markSeen đặt ở HomeScreen build (watch + postFrame)** thay vì onTap tab: cover đủ 3 đường vào (tap, deep-link cold/warm, tin mới đến khi đang mở tab), idempotent.

### Verify đã chạy

- `fvm flutter analyze` → **No issues found**.
- `fvm flutter test` → **18/18 pass**.
- `fvm flutter gen-l10n` → sạch.
- `./scripts/test-firebase-rules.sh` → **154 passing**.

### Điểm cần Tester soi (chưa verify runtime)

1. **Regression deep-link QUAN TRỌNG NHẤT:** tap push `photo_posted`/`photo_reaction` cold + warm phải mở **tab 2** (Gallery) + đúng ảnh; `chat_message` → tab 1; 4 type cũ → tab 0; tap từ notification-center cũng vậy (dùng `targetHomeTab`).
2. 2 máy realtime ≤1s; offline gửi → bubble pending mờ + clock → online tự rõ, KHÔNG duplicate (AC2).
3. Unread dot: bật khi tin partner đến lúc ở tab khác; vào tab → tắt; kill app mở lại vẫn tắt (Hive); tin của MÌNH không bật; Reduce Motion dot không scale.
4. Composer vs bàn phím trên máy thật (iOS home-indicator + Android): đóng = nổi trên nav hở 10, mở = sát bàn phím, chuyển 260ms; nav tự ẩn.
5. Phân trang: couple >50 tin → "Xem thêm" load 50 cũ; cuộn không giật (reverse list).
6. Waiting partner: không composer, CTA nhảy tab Hồ sơ (3); partner join realtime → tab chat sống lại không cần restart.
7. Auto-read inbox theo tab (`markReadForTab`) với index mới — vào Gallery (2) phải mark read notif photo, vào Chat (1) mark read notif chat.
8. Push nội dung: lock screen KHÔNG hiện text tin nhắn; vi/en theo `languageCode` device.
9. Local fallback (máy không Firebase/guest-coupled local): composer gửi được, tin chỉ ở máy đó, không crash.
10. `_logTabScreenView`/analytics screen_view tên tab mới ('Chat') — confirm GA4 DebugView khi smoke.
- [2026-06-12] [dev/lead] Vòng fix sau Tester (4 bug): #1 send-reject muộn nổi SnackBar (`onServerReject` → `sendRejections` counter → listener ChatScreen, offline thuần không báo lỗi); #2 `ChatWindow.isFromCache` — cursor/hasMore chỉ chốt từ server snapshot; #3 bỏ clamp substring UTF-16 (UI maxLength + rules là chốt); #6 Semantics `enabled: canSend`. Analyze 0, test 18/18. Nợ: #4 entrance seed sớm, #5 rules-test unauthenticated, #7 local Hive cap, perf-note watch ở HomeScreen.
- [2026-06-12] [dev/lead] Gỡ `_ChatTitleBlock` (title 32 "Trò chuyện" + subtitle) khỏi list + empty + skeleton theo user ("nhắn nhiều nó trôi lên trên"): trong reverse-list title nằm ở ĐẦU lịch sử (phía tin cũ nhất) — chìm sau vài tin, đứng cạnh "Xem thêm" lạc lõng; chip ghim + icon lịch sử gánh định danh màn. Key `chatHeaderSubtitle` hết dùng, GIỮ ARB. Chat = ngoại lệ chính thức của 🔒 RULE header lớn. Analyze 0 issue.
- [2026-06-12] [dev/lead] Chip ghim tab Chat thành DYNAMIC (user yêu cầu): `EyebrowChip` thêm slot `child` (giữ vỏ pill, label/icon thành optional + assert); chat render `AnimatedCoupleName` (TÊN1 ♥ TÊN2 uppercase, tim đập 12px `accentLoveDeep`, style `pageEyebrowStyle(.70)`) trong chip, Flexible chống tràn khi tên dài; fallback chip tĩnh `chatBadge` khi chưa có couple/tên. Analyze 0 issue.
