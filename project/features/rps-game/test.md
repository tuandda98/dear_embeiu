# Test — Oẳn tù tì (rps-game)

> File Tester sở hữu (Tester read-only nên PO chép báo cáo vào đây).

## [2026-09-14] [Tester] Nghiệm thu code-level (commit c345281) — ❌ FAIL

**Đã chạy:** analyze 0 · flutter test 97/97 · rules-test 278 · probe emulator 8/8 (scratch — xác nhận RPS-5/10/11 + chặn list/collectionGroup moves). Backend thuần additive → app 1.6.x không vỡ.

| ID | Mức | Vị trí | Mô tả | Đề xuất |
|---|---|---|---|---|
| RPS-1 | P1 | provider `rematch()` · game screen follow | Cả hai bấm "Chơi lại" gần như cùng lúc → 2 ván riêng, cả hai kẹt "Đang chờ" (CF skip push vì presence ván trước còn tươi). | Rematch doc id tất định `rematch_<prevGameId>`; create fail → enter. |
| RPS-2 | P1 | service `watchOpenGame` · provider · invite card | Ván mở CŨ (invite >10' chưa expire / playing kẹt) được coi là hiện hành → màn kết quả bị kéo sang ván chết, `hasPendingInvite` giả, "Chơi lại" theo ván cũ. | Lọc stale/pastGrace ở client, `invite()` expire trước khi tạo, follow chỉ khi `rematchOf == current` hoặc mới hơn. |
| RPS-3 | P1 | provider heartbeat · game screen | Heartbeat 3s không gắn lifecycle → Android nền/khoá máy vẫn "present" → partner vào là đếm, người ở nền thua và không nhận push kết quả. | Pause/resume heartbeat theo lifecycle + khi route không top. |
| RPS-4 | P2 | model `countdownRemaining/isPastGrace` | Đồng hồ = clock máy − `startedAt` server, không bù offset → máy lệch giờ thua oan / tap bị rules từ chối. | Ước lượng serverOffset từ snapshot không pending. |
| RPS-5 | P2 gian lận | rules transition `invited→playing` | Không kiểm presence partner → tự start 1 mình, ghi move, gọi finish sau 7s → thắng timeout (farm chuỗi). | Rules: `presence[partner] > request.time - 10s`. |
| RPS-6 | P2 | profile `loadTotalScore` | `countScore` lỗi → vòng lặp retry vô hạn mỗi rebuild (3 count() read/lượt). | Backoff ≥30s / 1 lần/phiên. |
| RPS-7 | P2 | home tour + catch-up | Sheet "Có gì mới"/CatchupGate đè lên màn chơi khi cold-start từ push → thua lúc đếm. | Bỏ qua khi route top là RpsGame / có focus rps. |
| RPS-8 | P2 | service `submitMove` · copy offline | Offline khi đếm: busy treo → "Chơi lại" disabled; copy "gửi khi có mạng" sai. | Timeout submitMove, không giữ busy toàn cục, sửa copy. |
| RPS-9 | P3 | `renewInvite` | Bỏ qua kết quả cancel → bỏ rơi partner vừa vào. | Chỉ tạo mới khi cancel OK. |
| RPS-10 | P3 | rules `cancelledBy` | Ghi `cancelledBy` không kèm transition → griefing chặn heartbeat. | Chỉ cho khi `invited→cancelled`. |
| RPS-11 | P3 | rules presence | Giá trị presence không pin `== request.time`. | Pin (cần cho RPS-5). |
| RPS-12 | P3 | invite khi waiting_partner | Tạo ván trong couple 1 người. | Chặn khi partnerUid rỗng → `rpsNeedCouple`. |
| RPS-13 | P3 | home route guard | 2 RpsGameScreen chồng nhau (qua History + tap push) → màn dưới kẹt skeleton. | Guard theo stack / ref-count enter-leave. |
| RPS-14 | P3 | CF `notifyRpsResult` onUpdate | ~40 invocation/phút/ván do heartbeat; rời <20s trước finish không nhận push. | Gửi push trong transaction finish, bỏ onUpdate. |
| RPS-15 | P3 | a11y tile/card | `Semantics(button)` không có onTap. | Truyền onTap. |
| RPS-16 | P3 | copy CF | "Your partner" vs "Your person"; lệch design §9.7. | Đồng bộ copy. |
| RPS-17 | P3 | mixed-version | App 1.6.x nhận push invite nhưng không có màn. | Chấp nhận + release notes. |
| RPS-18 | P3 | totalScore/badge | Lệch khi ván finish ngoài màn; 3 chữ số bị cắt. | Refresh khi finished qua stream; FittedBox. |

**Điểm mạnh (đừng báo nhầm):** chống lộ lựa chọn ĐẠT (get/list/collectionGroup moves đều DENY khi playing); client không ghi được finished/result; resolve+finish idempotent; CF người nhận = memberIds (không lặp lỗ answerAuthorUid); startIfBothPresent transaction; index khớp; routing push/inbox đồng bộ 2 chỗ; không leak Timer/Subscription; Reduce Motion đủ; l10n khớp, không "hai đứa".

**Chưa verify (cần runtime):** push invite <5s trên Android thật; lệch đếm 2 máy; heartbeat nền Android; tour đè màn; `count()` isNull field lồng; glyph medallion; a11y TalkBack.

## [2026-09-14] [Tester] Nghiệm thu vòng 2 (commit 86ba602) — ✅ PASS (không chặn ship; khuyến nghị vá RPS-19/20 trước PROD)

**Đã chạy:** analyze 0 · test 105/105 · rules-test 289 · probe rules 4/4 (xoá presence của mình OK → partner start DENY; không xoá được key partner) · runtime 2 máy DEV (Android emu test1 VI + iPhone 16 sim test2 EN) · log CF DEV.

| RPS | Vòng 2 | Ghi chú |
|---|---|---|
| 1 | fixed | Rematch song song → 1 ván `rematch_<root>_2`; nhánh thua race chạy thật |
| 2 | fixed | Invite −11' có rematchOf không kéo màn kết quả, tự expired, không badge |
| 3 | partial | Nền >10s / Lịch sử che → không start; còn cửa sổ ≤10s (RPS-20) |
| 4 | fixed | Offset 11s đo được, 2 máy cùng số |
| 5, 10, 11 | fixed | rules-test |
| 6, 12, 15 | fixed (chỉ code) | |
| 7 | fixed (chỉ code) | Chưa runtime (build 22 < entry tour 23) |
| 8 | fixed | Mất mạng giữa lúc đếm → "Bỏ lượt", "Chơi lại" vẫn bấm được |
| 9 | fixed | Nhắc lại → huỷ + tạo mới + inbox |
| 13 | fixed | iOS: push-tap từ Lịch sử → về đúng màn chơi |
| 14 | fixed | Không còn notifyRpsResult; push chỉ từ lời gọi chốt ván |
| 16 | fixed | Lệch nhỏ ngoài feature: `reactionPartnerFallback` EN "Your partner" |
| 17 | chấp nhận | |
| 18 | fixed | Tuần / Profile / Lịch sử khớp |

| ID | Mức | Vị trí | Mô tả | Đề xuất |
|---|---|---|---|---|
| RPS-19 | P2 | functions:1583 + provider detach/pause | B rời màn kết quả, A "Chơi lại" trong 30s → CF bỏ push+inbox, B không biết; màn chờ ghi sai "đã nhận thông báo" | Client xoá `presence.{me}` khi pause/detach |
| RPS-20 | P2 | provider pauseHeartbeat | A rủ rồi xuống nền, B vào ≤10s → ván start, A thua "Bỏ lượt" | Cùng cách vá |
| RPS-21 | P3 | game screen copy màn chờ | "Người ấy đã nhận thông báo" sai khi CF bỏ qua | Copy trung tính |
| RPS-22 | P3 | game screen `_slowTimer` | Đã chọn + offline + hết giờ: kẹt "Đang mở kết quả…" | Timer chậm cho cả chosenWaiting |
| RPS-23 | P3 | provider serverNow | Offset chỉ đo khi đã vào ván | Đo offset sớm |

**Runtime DEV:** ván thường PASS · rematch song song PASS · nền >10s PASS (≤10s = RPS-20) · timeout 1 bên/cả hai + chip Bỏ lượt PASS · invite >10' PASS · push-tap iOS từ Lịch sử PASS · log CF sạch.
**Chưa verify:** banner push thật, tour build 23, catch-up, RPS-12, TalkBack, Reduce Motion, ≤360pt.

## [2026-09-14] [Tester] Nghiệm thu vòng 3 — đổi luật "không bỏ lượt" (commit 48a6479) — ✅ PASS (không P0/P1; khuyến nghị vá RPS-24 + RPS-25 trước PROD/1.7.0)

**Đã chạy:** analyze 0 · test 139/139 · rules-test 295 · DEV còn đúng 3 CF rps · runtime 2 máy DEV + watcher firebase-admin + log CF. Từ ~00:45Z thao tác phía test2 bằng firebase-admin (payload y hệt client); ~00:58Z user tự thao tác → dừng.

**Runtime:** (1) ván thường PASS · (2) không ai ra trong 5s → ván không kết thúc, ra lúc +25s và +7m13s vẫn tính PASS · (3) B đang ở màn thấy dải "đã ra rồi", không push PASS · (4) B rời màn → inbox `rps_moved`, tap mở đúng ván PASS · (5) Nhắc + cooldown đúng giây kể cả vào lại PASS · (6) kill app giữa ván → vào thẳng đúng trạng thái PASS · (7) Home card các state + dot Profile PASS · (8) chơi lại song song 1 ván PASS (mô phỏng) · (9) log CF 0 lỗi, không còn finishRpsGame PASS.

| ID | Mức | Vị trí | Mô tả | Đề xuất |
|---|---|---|---|---|
| RPS-24 | P2 (hồi quy AC §7) | provider `enter → _leaveInternal(clearPresence)` · CF `notifyRpsInvite` | Chơi lại khi cả hai ở màn kết quả vẫn push+inbox mời (3/4 lần): máy kia theo ván mới & xoá presence ván cũ trước khi CF đọc | CF đọc lại chính ván mới: bỏ qua nếu đã `playing` hoặc presence người nhận còn mới; client không xoá presence ván cũ khi đổi ván từ màn kết quả |
| RPS-25 | P2 (bền vững) | CF `resolveRpsGame` nuốt lỗi, không retry · `_reload` | Resolve lỗi ở move thứ 2 → ván kẹt `playing` mãi, 1-ván-mở chặn chơi tiếp | "Tải lại"/nudge gọi resolve idempotent khi đủ 2 move, hoặc trigger retry |
| RPS-26 | P3 | dải "đã ra rồi" · card Home (VI) | Chữ VI bị cắt trên 411dp | Rút gọn copy / 2 dòng |
| RPS-27 | P3 | game screen AnimatedSwitcher | Khối "Nhắc người ấy" hiện/ẩn đẩy ring+3 nút ~48dp | `layoutBuilder` căn trên |
| RPS-28 | P3 | nudge vs trigger | Bấm nhắc trong cửa sổ cold start → 2 `rps_moved` gần nhau | Chấp nhận |

**Hồi quy vòng 1–2:** giữ nguyên, trừ RPS-19 phá check bỏ push khi chơi lại → RPS-24.
**Chưa verify:** banner push thật, haptic, ring "thở"/Reduce Motion/TalkBack, offline thật khi đã chọn, RPS-25 runtime (fault injection), tour build 23.
