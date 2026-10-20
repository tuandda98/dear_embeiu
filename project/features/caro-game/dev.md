# 💻 Dev — Cờ caro theo lượt (caro-game)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** stage 2/2 xong (UI + push tap + widget + analytics + tour + vá review backend). Chờ Lead deploy DEV + Tester. Chưa deploy gì.
- **Người/role:** Dev
- **Nhánh:** `feature/caro-game` (worktree `dear_embeiu-caro`)

## Kế hoạch kỹ thuật

- *Cách tiếp cận:* cả ván trong 1 doc `couples/{c}/games/{id}` `type:'caro'` (D1), mọi thay đổi qua callable `caroAction` (D5), con trỏ ván mở + tỉ số ở `caroState/main` (D6). Client chỉ ghi `presence.{uid}` của mình.
- *Cần deploy?* Có, **chưa deploy gì**. Lead deploy DEV từ nhánh gộp: `firestore:rules,functions:caroAction,functions:resolveRpsGame,functions:nudgeRpsPlayer,functions:notifyPartnerLeft` (+ `functions:leaveCoupleCleanup,functions:deleteAccount` vì `deleteCoupleCompletely` đổi). PROD chờ lệnh user, rules lên trước app.

### Backend — `functions/index.js` (khối `// ── caro-game (đợt 2) ──` đặt ngay trước `sendToRecipientDevices`)

| Hàm | Việc |
|---|---|
| `caroWinner(cells, size, rule)` | Thuần. Chỉ xét 4 đường qua nước cuối. `vn`: ≥5 liền thắng trừ khi 2 đầu đều là quân đối phương (mép không tính chặn); `free`: ≥5 là thắng. Kín bàn → `full`. Trả `{winner, line, full}` |
| `caroMoveError(game, memberIds, uid, cell, moveNo)` | Thuần. `not_playing` (không phải caro/không `playing`/có người không còn trong couple) · `not_player` · `not_your_turn` · `stale` (`moveNo != cells.length`) · `out_of_range` · `occupied` |
| `caroCell`, `caroNudgeWaitMs`, `caroShouldWake`, `caroPresenceFresh`, `buildCaroText` | Thuần, có test |
| `caroRunOp(op, ctx)` | 1 transaction đọc `caroState/main` + ván (start đọc thêm ván mở và ván `rematchOf`) |
| `exports.caroAction` | Callable. auth → `isDocId` → member → đúng 2 thành viên (không thì `{ok:false, reason:'no_partner'}`). Lỗi nghiệp vụ trả `{ok:false, reason, gameId?, retryAfterMs?}`; lỗi hệ thống `HttpsError` vi/en theo `lang` (`CARO_ERROR_COPY`) |
| `sendCaroPush` | Push + inbox (`caro_invite` mới có inbox). Data `{type, coupleId, gameId, moveNo(string), actorName}`, `collapseId: caro_{gameId}`, `wakeClients` theo cờ |
| `caroCleanupOnLeave` | Gọi từ `notifyPartnerLeft`: ván đang mở → `expired`, xoá `caroState/main` (D20) |

Chi tiết từng op:
- `start {cell, rule, rematchOf?}`: ván mở còn `playing` + đủ 2 player là thành viên → `already_open` + `gameId`; ván mở có player đã rời → đánh `expired` rồi tạo ván mới. Tạo `{type, rule, size:15, createdBy, createdAt, players{x:caller,o:partner}, status:'playing', cells:[cell], turnUid:partner, lastMoveAt, lastMoveBy, lastWakeAt{partner}, rematchOf?, updatedAt}`; `caroState.openGameId` = ván mới (lần đầu ghi luôn `wins:{}`, `draws:0`). Push `caro_invite` + inbox, wake. Bỏ push khi partner còn presence <45 s ở ván `rematchOf`, hoặc đã có presence trên ván mới (đọc lại sau commit).
- `move {gameId, cell, moveNo}`: thắng → `finished` + `result{winnerUid, reason:'five', line}` + `wins[caller]++`; kín bàn → `result{winnerUid:null, reason:'full', line:[]}` + `draws++`; cả hai xoá `openGameId` nếu đang trỏ ván này. Còn lại → `turnUid = partner`. Partner presence <45 s → không push; không thì `caro_turn` (wake nếu `lastWakeAt[partner]` ≥30', ghi `lastWakeAt` trong transaction) hoặc `caro_result` (won/draw, không wake).
- `resign`: `finished`, `result{winnerUid: người kia, reason:'resign', line:[]}`, `endedBy`, `wins[người kia]++`. Push `caro_result` (resigned) nếu người kia rời màn.
- `cancel`: chỉ khi `cells.length <= 1` → `cancelled`, `endedBy`; không push.
- `expire`: `lastMoveAt` ≥7 ngày → `expired`, `endedBy`; không thì `too_early` + `retryAfterMs`.
- `nudge`: caller phải là người đang chờ; `now − max(lastMoveAt, lastNudgeAt) ≥ 30'` → ghi `lastNudgeAt`, push `caro_nudge` bất kể presence, không wake; không thì `cooldown` + `retryAfterMs`.
- Tỉ số cộng bằng `set(..., {wins: {[uid]: increment(1)}}, {merge:true})` (không dùng đường dẫn có dấu chấm).

Đụng code có sẵn (chỉ thêm):
- `rpsRecordMoveInTransaction` + transaction của `nudgeRpsPlayer`: doc có `type` khác `rps` → `not_playing`.
- `notifyPartnerLeft`: gọi `caroCleanupOnLeave` sau phần dọn sleep.
- `deleteCoupleCompletely`: thêm `recursiveDelete` cho `games` và `caroState`. **Lưu ý:** việc này xoá luôn các ván oẳn tù tì của couple bị xoá hẳn (trước đây chúng bị bỏ lại thành rác mồ côi). Spec §2.1 ghi teardown đã `recursiveDelete` cả couple, nhưng code thật chỉ xoá từng subcollection có tên ⇒ phải thêm.

### Rules — `firestore.rules`
- Nhánh update rps: thêm guard đầu `resource.data.get('type', 'rps') == 'rps'`.
- Thêm `allow update` cho caro: thành viên, `type == 'caro'`, `diff().affectedKeys().hasOnly(['presence'])`, `rpsPresenceTouchesOnlyOwnKey()`.
- Create `moves`: thêm `rpsGame().get('type', 'rps') == 'rps'`.
- `match /caroState/{docId}`: read = thành viên, write = false.
- Create `games` giữ nguyên (chỉ `rps`) ⇒ client không tạo được ván caro. Không thêm index.

### Client
- `lib/models/caro_game.dart`: `CaroTiming` (20 s / 45 s / 30' / 7 ngày / 24 h gợi ý app cũ), `CaroRule` (`vn`|`free`), `CaroGameStatus`, `CaroSide`, `CaroResult` (+`outcomeFor`), `CaroState` (`winsOf`, `totalFor`), `CaroGame` (`isMyTurn`, `sideOf`, `opponentOf`, `playersAreMembers`, `canCancel`, `isPresenceFresh`, `isStale`, `nudgeWait`, `spanHours`), `CaroBoard` (`pieceAt`, `moveNumberAt`, `nextSide`, `winningLine(rule)` — cùng thuật toán với CF, dùng tô đường thắng ở xem lại), `caroParseCells`.
- `lib/services/caro_game_service.dart`: `watchState`, `watchGame` (lọc `type == 'caro'`), `fetchGame`, `heartbeat`/`clearPresence` (`presence.{uid}`), `action(op, …)` gửi kèm `lang` → `CaroActionResult` (`status` enum, `gameId`, `gameStatus`, `cellsLength`, `retryAfter`, `isStaleBoard`; `unavailable`/`deadline-exceeded` → `network`), `fetchHistoryPage` (index rps `type,status,finishedAt↓`; `failed` khi lỗi).
- `lib/providers/caro_game_provider.dart` (`CaroGameProvider`):
  - Toàn couple: `watchForCouple(coupleId, myUid, partnerUid)` nghe `caroState/main` → theo dõi ván mở. Getter: `hasPartner`, `state`, `myWins`/`partnerWins`/`draws`, `openGame` (chỉ ván `playing` của đúng cặp hiện tại), `isMyTurn`, `lastFinished` (tải 1 ván khi tổng ván đếm được thay đổi), `recentGame`.
  - Màn ván: `enter(gameId)` (heartbeat 20 s ngay), `leave()` (xoá presence), `pauseHeartbeat()` / `resumeHeartbeat()` (pause xoá presence luôn). Getter `currentGame`, `isCurrentLoaded`, `pendingCell`, `isBusy`.
  - Thao tác: `start({rule, cell = centerCell (7,7), rematchOf})`, `move(cell)` (moveNo = `cells.length`, `pendingCell` giữ tới khi doc có quân, lỗi thì bỏ), `resign()`, `cancel()`, `expire()`, `nudge()`. Đều trả `CaroActionResult`, không tự điều hướng.
  - Lịch sử: `loadHistory()`, `loadMoreHistory()` 30/trang, lọc ván có cả hai player là cặp hiện tại (D20); `historyFailed`.
- Wire: `main.dart` thêm `ChangeNotifierProvider(create: (_) => CaroGameProvider())`; `session_resolver.dart` thêm named-param `caroGameProvider` (signature + call site), `clear()` ở 3 nhánh, `watchForCouple(..., rpsPartnerUid)` ở nhánh có couple.

## Edge case kỹ thuật đã xử lý
- Hai máy cùng `start`: transaction trên `caroState/main` ⇒ máy sau nhận `already_open` + `gameId` để mở ván đó.
- Bấm 2 lần / màn cũ: `moveNo` lệch → `stale`; ô đã có quân → `occupied`; không phải lượt → `not_your_turn`.
- Ván của cặp cũ (một người đã rời): server coi là chết (`not_playing`, `start` tự `expired`), client ẩn khỏi Home + lịch sử.
- `cancel` khi đã có quân thứ 2 → `stale` (spec không định reason cho ca này; "bàn vừa đổi" đúng nghĩa nhất). `nudge` khi đã tới lượt mình → `stale`.
- Rules: update rỗng (vd `deleteField` một field không có) lọt qua nhánh caro vì không đổi gì — vô hại.

## Checklist stage 1
- [x] `caroWinner` + 18 test node (`functions/test/caro.test.js`; 13 case luật + moveError/cell/nudge/wake/copy)
- [x] `caroAction` 6 op + push vi/en + collapseId + lọc presence + wake ≤1/30'
- [x] Guard `type` cho `resolveRpsGame` / `nudgeRpsPlayer` (`notifyRpsInvite` đã có sẵn)
- [x] `notifyPartnerLeft` + teardown couple
- [x] Rules + 19 test (`firebase_rules_test/test/firestore.caroGame.test.js`), suite rps cũ PASS
- [x] Model / service / provider + wire `main.dart` + `session_resolver.dart`
- [x] 20 test Dart (`test/caro_game_test.dart`)
- [x] `flutter analyze` sạch

## Kế hoạch stage 2 (người sau làm tiếp)
1. **Home C thẻ "Chơi cùng nhau"** (`PlayTogetherCard` thay `RpsInviteCard`, design §3.1, 10 trạng thái): đọc `CaroGameProvider.openGame` / `recentGame` / `isMyTurn` / `myWins`… Nhớ HomeScreen re-arm `caroGameProvider.watchForCouple(...)` với couple sống (như rps) để partner vừa ghép giữa phiên thấy thẻ. Ẩn khi `!hasPartner`.
2. **`showCaroNewGameSheet`** (§3.2): nút chính gọi `start(rule:, cell: centerCell)`; "Tự chọn ô đầu tiên" mở màn trống rồi `start(cell:)`. Nhớ luật lần trước ở Hive `app_settings` key `caro_last_rule` (box `Box<String>`, chưa làm). `alreadyOpen` → mở `result.gameId`.
3. **`CaroGameScreen(gameId?)`** (§3.3–3.4, 13 trạng thái): `enter` ở initState, `leave` ở dispose, `pauseHeartbeat`/`resumeHeartbeat` theo lifecycle + RouteAware (cùng observer với rps ở `main.dart`). Bàn vẽ từ `currentGame.board` + `pendingCell`; đường thắng = `result.line`. Lỗi: `isStaleBoard` → `caroStaleBoard`, `network` → `caroOffline`, còn lại `caroSendError`. Nhắc: `nudgeWait(me)`; treo 7 ngày: `isStale()`; gợi ý app cũ: ván `isFreshInvite` và `createdAt` > `CaroTiming.oldAppHintAfter`.
4. **`CaroHistoryScreen`** + xem lại bàn cuối (§3.5): `loadHistory`/`loadMoreHistory`, `historyFailed`; xem lại dùng `fetchGame` + `CaroBoard`.
5. **Profile**: ô "Chơi cùng nhau" (Lead chốt gộp với oẳn tù tì), chấm khi `isMyTurn` hoặc được rủ.
6. **Push tap + Notification Center** (2 chỗ): `caro_invite`/`caro_turn`/`caro_nudge`/`caro_result` → mở ván (`NotificationTapRouter.focusCaroGame` + `pendingCaroGameId`); `AppNotification` thêm type `caro_invite` (`notifCaroInvite`, dòng phụ dùng lại thân push). Push đang mở đúng ván → không banner trong app.
7. **Widget-today `caro_turn`** (overview §7.1): bridge nghe `CaroGameProvider` (`statusAt = lastMoveAt`), handler nền map push `caro_turn`/`caro_invite` khi có `wakeClients` (data có `gameId`, `moveNo`, `actorName`, `lang`).
8. **Analytics** 6 event §8 (không gửi ô/tên/uid/gameId); `caro_game_started` có `rule`.
9. **Feature tour** 1 mục `sinceBuild` bản phát hành; **i18n** toàn bộ copy deck design §6 (prefix `caro`, khối liền cuối ARB).
10. Deploy DEV (Lead) rồi Tester theo overview §10.

## Stage 2 — đã làm (2026-10-20)

**File mới**
- `lib/widgets/caro/caro_board.dart`: `CaroTapSelector` (chạm 2 bước, chặn 400 ms, thuần), `caroZoomMatrix` (1,6× canh nước cuối, kẹp biên), `CaroBoardPainter` (ô ly, quân 2 màu, nước cuối, ô chọn mờ .45/.60, dải thắng vẽ dần, quân rơi; `semanticsBuilder` 225 ô có nhãn + `onTap`), `CaroGlyph`, `CaroThumb`, `CaroRuleExample`.
- `lib/widgets/caro/caro_common.dart`: `CaroPrefs` (Hive `app_settings`: `caro_last_rule`, `caro_hint_count`; box chưa mở thì no-op), `CaroPeople` (tên + màu từ `SleepProvider`, như sleep), `CaroLanes`/`CaroLane` (ba làn), `showCaroRuleSheet`, `caroTime`, `caroRuleName`.
- `lib/widgets/caro/caro_new_game_sheet.dart`: `showCaroNewGameSheet` (§3.2 + U1: nút chính "Rủ X chơi" = quân giữa bàn, nút chữ "Tự chọn ô đầu tiên" → `openCaroDraft`).
- `lib/screens/caro_game_screen.dart`: `openCaroGame` (không chồng 2 màn, như rps), `openCaroDraft`, `openCaroReplay`, `CaroGameScreen` (13 trạng thái + kết quả + xem lại; `caroScreenModeFor`, `caroEndedResult` thuần).
- `lib/screens/caro_history_screen.dart`: `openCaroHistory`, `CaroHistoryScreen` (tỉ số + thẻ theo tháng + phân trang 30 + rỗng/lỗi).
- `lib/widgets/play_together_card.dart`: `PlayTogetherCard` (dòng caro `caroEntryKindFor`/`caroEntryView` thuần + dòng rps 6 trạng thái cũ, nút navy/viền theo C6).

**File dùng chung (chỉ thêm, khối `// ── caro-game (đợt 2) ──`)**
- `home_screen.dart`: `PlayTogetherCard` thay `RpsInviteCard` tại chỗ (đổi import `rps_invite_card.dart`); re-arm `CaroGameProvider.watchForCouple`; `_applyPendingFocus` case `focusCaroGame`; `_caroProvider` vào danh sách nghe widget + `caroTurnAt`.
- `push_notification_service.dart`: `NotificationTapRouter.focusCaroGame='caro'` + `pendingCaroGameId` + `pendingCaroSource` + `caroGameOnScreen`; `_applyRoute` 4 type `caro_*`; không banner trong app khi push nói về ván đang mở (`isCaroPushForVisibleGame`); hook test `routeTapForTest`.
- `app_notification.dart` + `notification_center_screen.dart`: type `caroInvite` (tiêu đề `caroNotifInvite`, dòng phụ `caroNotifInviteBody`, icon `grid_5`, tap → focus caro + gameId, source `inbox`).
- `home_widget_status.dart`: kind `caro_turn`, focus `caro`, `caroTurnAt(open, myUid)`, `build(caroTurnAt:)`; `fromPush` map `caro_turn`/`caro_invite` (push caro không có `date` ⇒ coi là hôm nay; có `sentAt` khác ngày thì bỏ).
- `analytics_service.dart`: 6 event §8 + param `rule`/`move_no`/`partner_watching`/`moves`/`span_hours`.
- `profile_screen.dart`: ô rps thành "Chơi cùng nhau" (giá trị tỉ số caro "12 – 9", chấm khi caro tới lượt/được rủ hoặc rps đang chờ; chạm: caro → rps → lịch sử caro). Bỏ lượt tải `rps.totalScore` ở Profile.
- `feature_tour_entries.dart`: mục `sinceBuild: 33`.
- ARB: 138 key prefix `caro` một khối cuối file. Đổi tên so với copy deck để giữ prefix: `playTogetherTitle`→`caroPlayTogetherTitle`, `notifCaroInvite`→`caroNotifInvite`, `featureTourCaro*`→`caroTour*`; thêm `caroCtaRetry`, `caroScorePair`, `caroHistorySubDraw`, `caroWhen*`, `caroDate*`, `caroReplayBadge`, `caroNotifInviteBody`, `caroWidgetTurn(Short)`.

**Vá theo review backend (Lead chuyển 2026-10-20)**
- #1 Phục thù khi người kia còn ở màn kết quả: CF vẫn ghi inbox, chỉ bỏ push (`inboxOnly`, cả nhánh đọc lại presence sau commit). Provider: đang xem ván đã xong mà ván mở mới có `rematchOf` = ván đó → tự `enter` ván mới (bắt cả 2 thứ tự sự kiện).
- #2 Test transaction thật: `caroFakeDb` (transaction xếp hàng, `increment`, `serverTimestamp` = đồng hồ giả) — 2 `start` đồng thời → 1 `already_open`; ván của cặp cũ → `expired`; thắng cộng `wins`, kín bàn cộng `draws`; `cancel` 2 quân → `stale`; `nudge` bởi `turnUid` → `stale`; `expire` sớm → `too_early` (+ fallback `createdAt`); `sendCaroPush` có `collapseId`.
- #3 Mọi op trên ván có sẵn kiểm 2 player còn là thành viên → `not_playing`. #4 `expire` lùi về `createdAt`. #5 `memberIds` đọc trong transaction (`no_partner` nếu không đủ 2). #6 `caroCleanupOnLeave` bọc phần expire, vẫn xoá state. #7 `clear()` reset `_heartbeatPaused`.

**Tự quyết khi spec chưa vẽ (tra UI UX Pro Max `"layout shift content jump"`, `"inline error toast position"` --domain ux → "Reserve space / stable container", severity High)**
- Khối lỗi / mất mạng / gợi ý app cũ **nổi đè mép dưới bàn** thay vì chen trên dock; dòng gợi ý "chạm lại" giữ chỗ (`Visibility maintainSize`) suốt lượt. Lý do: bàn co lại giữa 2 lần chạm làm cú chạm 2 rơi vào ô khác (bắt được bằng widget test).
- Làn giữa giới hạn 84–96, tên luật xuống dòng: ở 360dp chữ ×1,3 làn tên bị ép còn 4,6px.
- Dòng lịch sử không thêm quân màu cạnh tên người thắng (bàn thu nhỏ đã mang màu).

## Nhật ký implement
- [2026-10-20] [Dev] Stage 1: backend `caroWinner` + `caroAction` + guard rps + dọn khi rời/xoá couple; rules additive; client model/service/provider + wire. Test: node 39 pass (18 caro mới), rules 413 passing (19 caro mới), Flutter 658 pass (20 caro mới), analyze 0. Chưa deploy. Commit `283bc13` (backend).
- [2026-10-20] [Dev] Stage 2: UI caro (thẻ Home, sheet, màn ván, kết quả, lịch sử, xem lại) + push tap/inbox + widget `caro_turn` + 6 event + tour build 33 + Profile gộp; vá 7 finding review backend. Test: Flutter 683 pass (+25 ở `test/caro_ui_test.dart`), node 49 pass (+10 `caroRunOp`/`sendCaroPush`), rules 413 passing, analyze 0. Chưa deploy.
