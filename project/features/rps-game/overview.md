# Oẳn tù tì (rps-game)

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.

- **Feature:** rps-game
- **Ưu tiên:** P1 (user yêu cầu 2026-09-13)
- **Trạng thái:** 📋 Spec → 🎨 Design + 💻 Dev backend song song
- **Tạo ngày:** 2026-09-13
- **Liên quan:** [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Yêu cầu gốc (user, 2026-09-13)
> "thêm tính năng trò chơi, oẳn tù xì, có 3 trạng thái Kéo / Búa / Bao, user sẽ notify user còn lại qua thông báo, sau đó cả 2 cùng online thì sẽ cho chọn kéo búa bao, trong 5s, ghi lại lịch sử trò chơi"

## 2. Mục tiêu
- Trò chơi nhỏ 2 người **đồng bộ realtime**: A rủ → B nhận **push** → khi **cả hai cùng mở màn chơi** thì đếm ngược **5 giây**, mỗi người chọn 1 trong **Kéo ✌️ / Búa ✊ / Bao ✋** → lộ kết quả cùng lúc.
- **Không gian lận:** lựa chọn của người kia KHÔNG đọc được trước khi ván kết thúc (chặn ở rules, không chỉ UI).
- **Lịch sử**: mọi ván đã kết thúc được lưu vĩnh viễn, xem lại theo thời gian + bảng tỉ số tổng (thắng/thua/hoà).
- Hết giờ mà chưa chọn = thua (nếu người kia đã chọn), cả hai không chọn = hoà "bỏ lượt".

## 3. Hợp đồng dữ liệu (CHỐT — Dev backend + client bám theo)
### 3.1 `couples/{coupleId}/games/{gameId}` (autoId)
| field | kiểu | ghi chú |
|---|---|---|
| `type` | `'rps'` | bất biến |
| `createdBy` | uid | pinned = request.auth.uid lúc create, bất biến |
| `status` | `'invited' \| 'playing' \| 'finished' \| 'cancelled' \| 'expired'` | xem máy trạng thái §4 |
| `createdAt` | timestamp | `== request.time` lúc create |
| `presence` | map `{uid: timestamp}` | heartbeat **3s** khi đang ở màn chơi; keys ⊆ memberIds; mỗi người chỉ ghi key của mình |
| `startedAt` | timestamp? | `== request.time` khi invited→playing (client nào thấy cả 2 presence tươi <10s thì set qua transaction; ai tới trước thắng) |
| `rematchOf` | gameId? | ván "Chơi lại" trỏ ván trước (CF dùng để KHÔNG push nếu người kia còn presence tươi ở ván trước) |
| `finishedAt` | timestamp? | CHỈ CF ghi |
| `result` | map? `{winnerUid: uid\|null, choices: {uid: 'rock'\|'paper'\|'scissors'\|'none'}, reason: 'normal'\|'timeout'}` | CHỈ CF ghi |
| `cancelledBy`/`updatedAt` | optional | client |

### 3.2 `couples/{coupleId}/games/{gameId}/moves/{uid}` (doc id == uid)
`{ choice: 'rock'|'paper'|'scissors', createdAt == request.time }` — **create-only**, chỉ chủ; chỉ được tạo khi cha `status == 'playing'` và `request.time < startedAt + 7s` (5s + 2s grace mạng). **Đọc:** của mình luôn; của người kia CHỈ khi cha `status == 'finished'`.

### 3.3 Rules (additive, `hasOnly` chặt)
- games **create**: member; `type=='rps'`, `createdBy==uid`, `status=='invited'`, `createdAt==request.time`, keys hasOnly `[type, createdBy, status, createdAt, presence, rematchOf, updatedAt]`.
- games **update** (member): KHÔNG đổi `type/createdBy/createdAt/result/finishedAt`; `presence` chỉ thêm/sửa key của chính mình; chuyển trạng thái client được phép: `invited→playing` (kèm `startedAt==request.time`), `invited→cancelled` (chỉ createdBy), `invited→expired` (member, khi `createdAt` cũ hơn 10'), `playing→` KHÔNG (CF lo). `finished/result` chỉ Admin SDK.
- games **read**: member. **delete**: false.
- moves: như §3.2. Recursive collectionGroup KHÔNG cần (không query group).
- `firestore.indexes.json`: composite `games` (`type ASC, status ASC, finishedAt DESC`) cho lịch sử; và (`type ASC, status ASC, createdAt DESC`) cho "ván đang mở".

### 3.4 Cloud Functions (`functions/index.js`, v2, us-central1)
- **`notifyRpsInvite`** — onCreate `games/{gameId}` (type rps, status invited): push tới partner `type:'rps_invite'`, data `{type, coupleId, gameId}`, copy localize vi/en ("<Tên> rủ bạn oẳn tù tì! Vào chọn trong 5 giây ⏱️" / "<Name> challenged you to rock-paper-scissors!"), + inbox `type:'rps_invite'` (actorName, gameId). **Skip push+inbox** khi `rematchOf` trỏ ván mà `presence[partner]` tươi < 30s (người kia đang ở màn kết quả, client tự theo ván mới).
- **`resolveRpsGame`** — onCreate `moves/{uid}`: đọc 2 move; nếu đủ 2 → transaction set `status:'finished', finishedAt, result{winnerUid, choices, reason:'normal'}` (idempotent: bỏ qua nếu đã finished).
- **`finishRpsGame`** — callable `{coupleId, gameId}` (auth + member): nếu `status=='playing'` và `now >= startedAt + 5s + 2s` → đọc moves có gì lấy nấy, thiếu = `'none'` → result (1 người chọn → người đó thắng; cả 2 none → hoà, reason `'timeout'`) → set finished. Idempotent. Client gọi khi hết đếm ngược mà chưa thấy finished (cả 2 máy có thể gọi, server chỉ ghi 1 lần).
- **`notifyRpsResult`** — onUpdate games (status → finished): push tới thành viên có `presence` CŨ hơn 20s (đã rời màn) `type:'rps_result'` copy theo kết quả của người nhận ("Bạn thắng ván oẳn tù tì 🎉" / "Người ấy thắng rồi 😝" / "Hoà!"); KHÔNG inbox (lịch sử đã có trong app).
- Luật thắng: rock > scissors > paper > rock. Luôn dùng `sendToRecipientDevices` + `writeInboxNotifications` sẵn có; thêm `rps_invite` vào `PUSH_TYPE_PREF_FIELD` = không (chưa có pref riêng, như care_message).

## 4. Máy trạng thái & luồng UX
1. **Rủ chơi**: A bấm "Oẳn tù tì" (entry: Home + Profile) → màn `RpsGameScreen` tạo game `invited` → A thấy "Đang chờ người ấy…" + presence heartbeat. B nhận push/inbox → tap → mở đúng `RpsGameScreen(gameId)`.
2. **Cả hai online**: mỗi máy heartbeat `presence[me]` 3s; khi thấy `presence[partner]` tươi (<10s) và `status=='invited'` → transaction `invited→playing, startedAt=serverTimestamp`.
3. **Đếm ngược 5s** (tính từ `startedAt` đọc lại từ server, hiển thị 5→0, haptic mỗi giây): 3 nút lớn Kéo/Búa/Bao; chạm = ghi `moves/{me}` NGAY (1 lần, khoá nút, hiện "Đã chọn ✓, chờ người ấy…"). Không được đổi.
4. **Kết thúc**: CF set finished khi đủ 2 move; hoặc client gọi `finishRpsGame` khi đồng hồ về 0 + 2s mà chưa finished. Màn kết quả: lộ 2 lựa chọn cùng lúc (animation "1-2-3 ra!"), "Bạn thắng / Người ấy thắng / Hoà", confetti khi thắng (package `confetti` đã có), nút **Chơi lại** (tạo game mới `rematchOf`) + **Xem lịch sử** + Đóng.
5. **Lời mời hết hạn**: 10' không có cả 2 → client (bên nào mở) set `expired`; A có thể **Huỷ** khi đang chờ. Mở màn khi có ván `invited/playing` đang tồn tại (chưa quá hạn) → vào ván đó thay vì tạo mới (1 ván mở tại 1 thời điểm).
6. **Lịch sử** `RpsHistoryScreen`: bảng tỉ số tổng (Mình – Hoà – Người ấy) + list ván (ngày giờ, 2 icon lựa chọn, ai thắng, `timeout` ghi "bỏ lượt"), phân trang 30, empty state.
7. **Rời giữa chừng**: mất presence → ván vẫn chạy theo đồng hồ server; người rời không chọn = thua khi người kia đã chọn.

## 5. Client (tóm tắt cho Dev)
- Models `RpsGame`, `RpsMove`, `RpsChoice` enum (rock/paper/scissors + emoji + nhãn l10n). Service `rps_game_service.dart` (create/watchGame/watchOpenGame/heartbeat/start/submitMove/cancel/expire/finishViaCallable/history page). Provider `rps_game_provider.dart` (ChangeNotifier; wire watch "ván đang mở" ở `session_resolver` như care/mood — thêm named-param).
- Screens: `rps_game_screen.dart` (4 state: waiting / countdown / chosen-waiting / result), `rps_history_screen.dart`. Widgets dùng primitives design-unify (`SubScreenHeader` chip "OẲN TÙ TÌ", `ContentCard`, pill button).
- Điểm vào: Home (card/quick action) + Profile (tile có tỉ số) — Designer chốt vị trí; badge khi có lời mời đang chờ.
- Push tap: `push_notification_service._handleNotificationTap` + `AppNotification.targetHomeTab`/focus: `rps_invite` → mở `RpsGameScreen(gameId)` (cold-start: qua `NotificationTapRouter.pendingHomeFocus` mở rộng mang gameId); `rps_result` → lịch sử. Notification center tap tương tự.
- i18n: mọi chuỗi vào `app_en.arb` + `app_vi.arb` (xưng "chúng mình", không "hai đứa"), `flutter gen-l10n` (toolchain 3.41.6 worktree).
- Analytics: `rps_invite_sent`, `rps_game_finished{result}` (no content).

## 6. Ngoài phạm vi v1
- Không có chế độ "best of 3", không chơi với AI, không sticker/âm thanh, không leaderboard công khai, không widget.

## 7. Acceptance criteria (PO nghiệm thu)
- [ ] A rủ → B nhận push trong <5s (DEV project, 2 máy) + item inbox; tap push mở đúng ván.
- [ ] Chỉ khi CẢ HAI ở màn chơi mới đếm ngược; 1 người mở thì vẫn "đang chờ".
- [ ] Đếm 5s đồng bộ (lệch <1s giữa 2 máy); chọn xong khoá; hết giờ chưa chọn → thua/hoà đúng luật.
- [ ] Rules-test: người kia KHÔNG đọc được move của mình trước finished; không tạo move khi status≠playing hoặc quá 7s; không sửa result/finishedAt từ client; cancelled chỉ createdBy. Suite cũ 244 vẫn pass.
- [ ] Kết quả lộ cùng lúc 2 máy, đúng luật; Chơi lại không spam push khi cả 2 đang ở màn kết quả.
- [ ] Lịch sử: đúng tỉ số, phân trang, empty state; ván timeout ghi rõ.
- [ ] analyze 0 · test pass · rules-test pass · DEV deployed (rules + indexes + 4 CF). PROD chờ lệnh user.

## Changelog
- [2026-09-13] [PO] Tạo spec từ yêu cầu user; chốt data contract + CF + máy trạng thái. Spawn Designer + Dev backend song song, Dev client sau design, Tester cuối.
