# Bộ test case — Cờ caro theo lượt (caro-game)

> Nhánh `feature/daily-open-2`, tính đến commit `727a349` (có b7e0e88: trong ván chạm ô trống là đánh luôn; nước đầu của lời mời vẫn chọn ô rồi bấm Mời). Người soạn: Tester. Chỉ liệt kê và đề xuất, không sửa code.
> Tên tắt: `CG` = `test/caro_game_test.dart` · `UI` = `test/caro_ui_test.dart` · `CF` = `functions/test/caro.test.js` · `RU` = `firebase_rules_test/test/firestore.caroGame.test.js` · `IDX` = `functions/test/index.test.js`.
> Cột "Cách kiểm": `unit:` (đã grep thấy test có tên đó) · `maestro:` (flow ở `maestro/caro-game/`, thứ tự chạy trong README) · `chưa phủ → đề xuất unit` · `thủ công:` kèm lý do.
> Quy ước máy: A = Android emulator (Tuấn, test3) · I = iOS simulator (Thảo, test4). Tên người trong câu chữ lấy theo hồ sơ ghép đôi.

## 1. Thẻ "Chơi cùng nhau" ở Home (HOME)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| HOME-01 | Thẻ | Couple còn `waiting_partner` (1 người) | Mở Home | Không thấy dòng caro; gọi `start` bị chặn `no_partner`, không gọi CF | unit: test/caro_game_test.dart::waiting couple: no partner, start refuses without calling |
| HOME-02 | Thẻ | Đã ghép, chưa từng chơi | Mở Home | Dòng "Cờ caro. Rủ X một ván, bạn đi trước." nút "Rủ chơi" | maestro: maestro/caro-game/01_home_card_android.yaml |
| HOME-03 | Thẻ | Mọi trạng thái dòng | Dựng từng trạng thái | Thứ tự ưu tiên: loading/error, invited, myTurn, stale, watching, waiting, justLost, justWon, justDraw, idle, first | unit: test/caro_ui_test.dart::every state in priority order |
| HOME-04 | Thẻ | Được rủ, nước đầu đã đi | Mở Home | Dòng "… rủ bạn một ván và đã đi nước đầu", nút "Vào chơi", chấm hồng | unit: test/caro_ui_test.dart::solid CTA + dot only while the partner waits on me (C6) |
| HOME-05 | Thẻ | Tới lượt mình | Mở Home | "Đến lượt bạn. X vừa đi nước N.", nút "Đi tiếp" đặc | maestro: maestro/caro-game/05_move3_android.yaml |
| HOME-06 | Thẻ | Mình vừa đi, chờ người kia | Mở Home | "Đang chờ X. Bạn đi nước N lúc hh:mm.", nút "Mở" viền, không chấm | unit: test/caro_ui_test.dart::solid CTA + dot only while the partner waits on me (C6) |
| HOME-07 | Thẻ | Người kia đang mở màn ván (presence < 45 s) | Mở Home | "X đang mở ván, chờ chút nhé." | unit: test/caro_ui_test.dart::every state in priority order |
| HOME-08 | Thẻ | Ván không ai đi ≥ 7 ngày | Mở Home | "Ván dừng N ngày rồi. Vào kết thúc để rủ ván mới." | unit: test/caro_ui_test.dart::every state in priority order |
| HOME-09 | Thẻ | Vừa thắng trong 24 giờ | Mở Home | "Bạn thắng ván vừa rồi. 1 – 0", nút "Ván mới"; chạm mở sheet rủ, không mở ván | maestro: maestro/caro-game/19_resigned_live_android.yaml |
| HOME-10 | Thẻ | Vừa thua trong 24 giờ | Mở Home | "X thắng ván vừa rồi", nút "Phục thù" | maestro: maestro/caro-game/14_rematch_ios.yaml |
| HOME-11 | Thẻ | Vừa hoà | Mở Home | "Ván vừa rồi hoà.", nút "Ván mới" | unit: test/caro_ui_test.dart::every state in priority order |
| HOME-12 | Thẻ | Hết 24 giờ sau ván cuối, đã có tỉ số | Mở Home | "{tỉ số}. Rủ X một ván?" (idle) | unit: test/caro_ui_test.dart::every state in priority order |
| HOME-13 | Thẻ | Tỉ số có ván hoà | Mở Home | Tỉ số thêm ", N ván hoà" | unit: test/caro_gap_test.dart::HOME-13 score with draws appends ", N ván hoà" |
| HOME-14 | Thẻ | Stream `caroState` lỗi | Mở Home | Dòng lỗi "Chưa tải được ván. Chạm để thử lại." + "Thử lại"; chạm subscribe lại | unit: test/caro_ui_test.dart::#6 state stream error → Home "Thử lại", retry re-subscribes |
| HOME-15 | Thẻ | Đang tải | Mở Home lần đầu | Khung shimmer, không nháy trạng thái khác | unit: test/caro_gap_test.dart::HOME-15 loading line: shimmer, no copy, no CTA |
| HOME-16 | Thẻ | Cả dòng là một vùng chạm | Chạm giữa tiêu đề / vào nút | Cùng mở một nơi, nhãn semantics "Cờ caro. <phụ đề>" | unit: test/caro_ui_test.dart::a line renders copy + CTA and is one tap target |
| HOME-17 | Thẻ | Ván mở là của cặp cũ (một người đã rời) | Mở Home | Dòng caro ẩn, không hiện ván ma | unit: test/caro_game_test.dart::follows the open game from caroState; my-turn flag; old pair hidden |
| HOME-18 | Thẻ | Partner ghép vào giữa phiên | Giữ Home mở, người ấy nhập mã | Thẻ xuất hiện không cần thoát app (re-arm `watchForCouple`) | unit: test/caro_gap_test.dart::HOME-18 partner joins mid-session: same stream, partner arrives (phần provider; HomeScreen build private, không dựng riêng được) |
| HOME-19 | Thẻ | Dòng Oẳn tù tì bên dưới | Chạm dòng rps | Vẫn mở luồng rps như cũ, không bị caro che | thủ công: cần ván rps 2 máy, ngoài phạm vi caro; đã có `firestore.caroGame.test.js::keeps the rps flow working next to a caro game` cho rules |
| HOME-20 | Thẻ | Điểm vừa đổi sau ván xong | Ván kết thúc khi đang ở Home | `lastFinished` tải lại đúng 1 ván | unit: test/caro_game_test.dart::last finished game refreshes when the score changes |
| HOME-21 | Thẻ | Máy cỡ nhỏ 360×640, chữ ×1,3 | Mở Home | Dòng không tràn | unit: test/caro_gap_test.dart::HOME-21 360×640, text ×1.3: the longest lines do not overflow (CaroEntryRow) |

## 2. Rủ ván mới và nước đầu (NEW)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| NEW-01 | Sheet | Không có ván mở | Chạm dòng caro | Sheet "Rủ X chơi caro" + 2 luật + "Tự chọn ô đầu tiên" | maestro: maestro/caro-game/02_sheet_dismiss_android.yaml |
| NEW-02 | Sheet | Chưa từng chơi | Mở sheet | Mặc định luật "Chặn hai đầu", không nhãn "lần trước" | unit: test/caro_ui_test.dart::null until a game was started, then the last rule |
| NEW-03 | Sheet | Lần trước chơi Tự do | Mở sheet, bấm nút chính | Tự do được chọn sẵn, nhãn "lần trước", `start` gửi `rule=free`, ô giữa bàn (112) | unit: test/caro_ui_test.dart::sheet pre-selects last time’s rule, tagged, and starts with it |
| NEW-04 | Sheet | Sheet mở | Chạm luật còn lại | Đổi lựa chọn, mô tả luật + ví dụ đổi theo | maestro: maestro/caro-game/16_cancelled_live_new_free_ios.yaml |
| NEW-05 | Sheet | Sheet mở | Back hệ thống / kéo xuống | Đóng, không tạo ván | maestro: maestro/caro-game/02_sheet_dismiss_android.yaml |
| NEW-06 | Sheet | `start` trả lỗi | Bấm "Rủ X chơi" | Sheet ở lại, hiện "Chưa đi được nước này…" | unit: test/caro_ui_test.dart::sheet pre-selects last time’s rule, tagged, and starts with it |
| NEW-07 | Sheet | Mất mạng khi bấm Rủ | Bấm "Rủ X chơi" | Sheet hiện "Đang mất mạng…", nút dùng lại được khi có mạng | unit: test/caro_gap_test.dart::NEW-07 offline on "Rủ": says so, the button works again |
| NEW-08 | Sheet | Màn 360×640 chữ ×1,3 | Mở sheet | Cuộn được, không tràn | unit: test/caro_ui_test.dart::#2 new-game sheet scrolls on 360×640 ×1.3 |
| NEW-09 | Sheet | Nút chính | Bấm | Ván tạo với quân X ở giữa (hàng 8, cột 8), người kia nhận lời rủ ngay | maestro: maestro/caro-game/14_rematch_ios.yaml |
| NEW-10 | Nháp | Chọn "Tự chọn ô đầu tiên" | Mở màn | Tiêu đề "Đặt quân đầu tiên", nút "Rủ X chơi" tắt vì chưa chọn ô | maestro: maestro/caro-game/03_draft_invite_android.yaml |
| NEW-11 | Nháp | Màn nháp | Chạm ô, rồi ô khác | Ô chọn mờ chuyển sang ô sau, nhãn ", đang chọn" | maestro: maestro/caro-game/03_draft_invite_android.yaml |
| NEW-12 | Nháp | Đã chọn ô | Chạm lại đúng ô sau ≥ 400 ms | Gửi `start` luôn (chạm 2 bước chỉ còn ở nháp) | unit: test/caro_ui_test.dart::tap 1 selects, tap 2 on the same square plays after 400 ms |
| NEW-13 | Nháp | Đã chọn ô | Chạm lại đúng ô trong < 400 ms | Bỏ qua (chống chạm đúp) | unit: test/caro_ui_test.dart::tap 1 selects, tap 2 on the same square plays after 400 ms |
| NEW-14 | Nháp | Đã chọn ô A | Chạm ô B | Chọn B, đếm lại 400 ms | unit: test/caro_ui_test.dart::another square moves the selection and restarts the delay |
| NEW-15 | Nháp | Chọn ô, bấm Rủ | Chờ | Chuyển sang màn chờ, nước 1 trên bàn, luật nhớ lại cho lần sau | maestro: maestro/caro-game/03_draft_invite_android.yaml |
| NEW-16 | Nháp | 5 nước đầu của máy | Chọn ô trong nháp | Gợi ý "Chạm lại ô đang chọn cũng là đi" hiện, sau 5 nước thì ẩn | unit: test/caro_ui_test.dart::tap-again hint counts only the first 5 moves |
| NEW-17 | Nháp | Hai máy cùng bấm Rủ | Hai `start` gần nhau | Một ván; máy sau nhận `already_open` + gameId và mở ván đó | unit: functions/test/caro.test.js::caroRunOp start: two at once → one game, the other gets already_open |
| NEW-18 | Nháp | `already_open` nhận ở client | Bấm Rủ khi người kia đã rủ | Mở ván của người kia, không báo lỗi | unit: test/caro_game_test.dart::ok + every reason |
| NEW-19 | Nháp | Offline khi bấm Rủ trong nháp | Bấm Rủ | Ghi chú mất mạng, ô giữ chọn, bấm lại được | unit: test/caro_gap_test.dart::NEW-19 offline on "Rủ" in the draft: note, square kept, retry |
| NEW-20 | Phục thù | Vừa thua, ván cũ ở màn kết quả | Bấm "Phục thù" → nút chính | `start` có `rematchOf` = ván cũ | maestro: maestro/caro-game/14_rematch_ios.yaml |
| NEW-21 | Phục thù | Người kia đang xem màn kết quả ván cũ | Mình rủ phục thù | CF chỉ ghi inbox, không push; máy kia tự mở ván mới | unit: functions/test/caro.test.js::caroRunOp rematch while the partner watches the result: inbox only, no wake |
| NEW-22 | Phục thù | Đang ở màn kết quả, ván mới của người kia có `rematchOf` = ván này | Chờ | Provider tự `enter` ván mới (cả hai thứ tự sự kiện) | unit: test/caro_ui_test.dart::on the result of G1, the partner’s rematch opens by itself |
| NEW-23 | Phục thù | Rủ lại < 2 phút sau lần rủ trước (rủ rồi huỷ liên tục) | Start–cancel–start | Ván vẫn tạo; chỉ inbox, không push, không đánh thức | unit: functions/test/caro.test.js::CARO-T3/T7: start → cancel → start within 2' is inbox only, no wake, no lastWakeAt |
| NEW-24 | Phục thù | Người kia mở ván mới trước khi push kịp gửi | Start khi partner đã vào | Hạ xuống inbox, gỡ `lastWakeAt` | unit: functions/test/caro.test.js::CARO-T7: partner opened the new game before the push → inbox only, wake undone |
| NEW-25 | Phục thù | Ván mở có người đã rời couple | `start` | Ván cũ `expired`, ván mới được tạo | unit: functions/test/caro.test.js::caroRunOp start: open game of an earlier pair is expired, new one made |
| NEW-26 | Luật | Hai luật | Ghi nhớ luật qua Hive | `caro_last_rule` lưu khi `start` ok, hộp Hive chưa mở thì no-op | unit: test/caro_ui_test.dart::null until a game was started, then the last rule |
| NEW-27 | Luật | Màn giải thích luật | Chạm chip luật ở màn ván | Sheet luật có ví dụ "Thế này chưa thắng / là thắng" | unit: test/caro_gap_test.dart::NEW-27 rule sheet: name, sentence and the example per rule |

## 3. Các trạng thái màn ván (SCR)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| SCR-01 | Mode | Mọi dữ liệu ván | Tính mode | loading, draft, invited, myTurn, stale, waiting, finished, cancelled, expired suy đúng từ ván | unit: test/caro_ui_test.dart::modes from the game |
| SCR-02 | Loading | Vào ván chưa có snapshot | Mở màn | Khung "Đang tải ván", nút tắt, không nhãn ô | unit: test/caro_gap_test.dart::SCR-02 no snapshot yet: "Đang tải ván", skeleton, no cell labels |
| SCR-03 | Invited | Được rủ, chưa đi | Vào từ thông báo | "X rủ bạn chơi caro", phụ đề nêu luật, nút "Để sau", bàn có quân X ở giữa | maestro: maestro/caro-game/04_inbox_invited_ios.yaml |
| SCR-04 | Invited | Lời mời cũ ≥ 2 ngày | Vào ván | Dòng "Bạn rủ X ngày dd/MM" chứ không "hôm qua" | unit: test/caro_ui_test.dart::#5 an invite 3 days old says its date, not "hôm qua" |
| SCR-05 | MyTurn | Tới lượt | Vào ván | "Đến lượt bạn.", "X vừa đi nước N lúc hh:mm", bàn phóng 1,6× quanh nước cuối | maestro: maestro/caro-game/05_move3_android.yaml |
| SCR-06 | Waiting | Mình vừa đi | Vào ván | "Đang chờ X.", "Bạn đi nước N lúc …. Cứ thoát app, X đi xong là có thông báo." | maestro: maestro/caro-game/03_draft_invite_android.yaml |
| SCR-07 | Waiting | Người kia đang xem | Vào ván | "… X đang xem ván." | unit: test/caro_gap_test.dart::SCR-07 waiting, partner watching: "… đang xem ván." |
| SCR-08 | Waiting | Chờ lâu | Vào ván sau khi đã nhắc | "Đã nhắc X lúc hh:mm." / "Đã M phút rồi." | unit: test/caro_gap_test.dart::SCR-08 waiting long: "Đã nhắc … lúc" after a nudge, else "Đã M phút" |
| SCR-09 | Waiting | Chữ ×1,3, 360×640 | Mở | Không tràn, thẻ trạng thái cuộn riêng trong 40% chiều cao | unit: test/caro_ui_test.dart::360×640, text ×1.3: waiting screen lays out without overflow |
| SCR-10 | Mọi mode | 360×640 chữ ×1,3 | invited, stale tới lượt mình, finished, waiting | Không tràn | unit: test/caro_ui_test.dart::#3 360×640 ×1.3 $name: no overflow |
| SCR-11 | Stale | Ván không ai đi ≥ 7 ngày, tới lượt mình | Vào ván | "Ván dừng N ngày rồi", vẫn đi được, có "Kết thúc ván" | unit: test/caro_ui_test.dart::modes from the game |
| SCR-12 | Stale | Ván treo ≥ 7 ngày, đang chờ người kia | Vào ván | Nút Nhắc + "Kết thúc ván"; "Kết thúc" mở hộp xác nhận → `expire` | unit: test/caro_gap_test.dart::SCR-12 + END-14 stale ≥ 7 days: Nhắc + Kết thúc ván → expire → "để lâu" |
| SCR-13 | Finished | Mình thắng | Màn kết quả | "Bạn thắng ván này", "Năm quân liền nhau ở nước N, lúc …. Ván kéo dài …", nút "Ván mới" | maestro: maestro/caro-game/11_win_android.yaml |
| SCR-14 | Finished | Mình thua | Màn kết quả | "X thắng ván này", nút "Phục thù" | maestro: maestro/caro-game/12_lost_live_ios.yaml |
| SCR-15 | Finished | Kín 225 ô | Màn kết quả | "Ván này hoà", "Kín cả 225 ô mà chưa ai thắng." | unit: test/caro_gap_test.dart::SCR-15 full board: "Ván này hoà" + "Kín cả 225 ô…" |
| SCR-16 | Finished | Đối phương xin thua | Màn kết quả | "X xin thua", "Ván này bạn thắng, ở nước N." | maestro: maestro/caro-game/19_resigned_live_android.yaml |
| SCR-17 | Finished | Mình xin thua | Màn kết quả | "Bạn đã xin thua", "X được tính thắng ván này." | maestro: maestro/caro-game/18_resign_ios.yaml |
| SCR-18 | Finished | Đường thắng | Màn kết quả | Dải thắng vẽ dần; mỗi ô thắng có nhãn ", trong đường thắng"; Reduce Motion thì hiện luôn | maestro: maestro/caro-game/11_win_android.yaml |
| SCR-19 | Finished | Màn kết quả + lịch sử | Mở | Hiện kết quả, "+1 ván này", "Xem lịch sử ván" mở lịch sử rỗng đúng | unit: test/caro_ui_test.dart::result + history screens render (empty history) |
| SCR-20 | Cancelled | Người kia bấm "Để sau" khi mình đang xem | Chờ | "Ván này đã huỷ", "X bấm Để sau lúc …", nút "Rủ X ván mới" | maestro: maestro/caro-game/16_cancelled_live_new_free_ios.yaml |
| SCR-21 | Expired | Ván tự hết hạn | Mở ván | "Ván này đã kết thúc vì để lâu", "7 ngày không ai đi…" | unit: test/caro_gap_test.dart::SCR-21 expired game: title + "7 ngày không ai đi…" |
| SCR-22 | Replay | Mở từ lịch sử | Chạm dòng | Chip "VÁN dd/MM", bàn chỉ đọc, không dock, không Xin thua | maestro: maestro/caro-game/13_history_ios.yaml |
| SCR-23 | Thoát | Mở rồi pop ngay | Back | Không lỗi "widget tree was locked", presence xoá | unit: test/caro_ui_test.dart::#1 open then pop the game screen: no locked-tree notify |
| SCR-24 | Thoát | Khi couple chưa nạp (mở từ push lạnh) | `enter` sớm | Chờ `watchForCouple` rồi vào | unit: test/caro_ui_test.dart::#7 enter() before the couple is wired waits, then enters |
| SCR-25 | Hoãn tour | Đang ở màn caro | Tới lúc hiện "Có gì mới" / catch-up | Hoãn tới khi rời màn | unit: test/caro_gap_test.dart::SCR-25 held "Có gì mới"/catch-up key off CaroGameScreen.isOpen (chỉ phần notifier; `_rpsGameActive` của HomeScreen là private) |
| SCR-26 | Bàn | Ván 15×15 | Xem toàn bàn | Quân X/O đúng màu hai người; nước vừa đi có điểm nhấn; thứ tự X ở nước chẵn | unit: test/caro_game_test.dart::X on even moves, move numbers, next side, out-of-board cells dropped |
| SCR-27 | Zoom | Bàn phóng | Chạm "Xem toàn bàn" rồi "Phóng to quanh nước cuối" | Nhãn nút đổi theo, ma trận phóng kẹp biên | maestro: maestro/caro-game/04_inbox_invited_ios.yaml |
| SCR-28 | Zoom | Ma trận phóng | Nước cuối ở góc | Không trượt ra ngoài bàn | unit: test/caro_ui_test.dart::zoom matrix centres the last move and stays inside the board |
| SCR-29 | Zoom | Đang phóng 1,6× nhưng nước mới xa vùng nhìn | Người kia đi ngoài khung | Khung không tự dịch (chỉ canh một lần mỗi ván) → nước mới có thể nằm ngoài tầm nhìn | thủ công: hành vi cần mắt người đánh giá có chấp nhận hay không (ghi nhận, xem mục "Phát hiện") |
| SCR-30 | Hiệu ứng | Nước mới của người kia | Nhìn bàn | Quân rơi, rung nhẹ; Reduce Motion thì hiện luôn | thủ công: haptics và animation không đo được trên máy ảo |
| SCR-31 | Cuộn | Màn ván | Kéo dọc | Màn không cuộn (C3), chỉ thẻ trạng thái cuộn riêng | unit: test/caro_ui_test.dart::#3 360×640 ×1.3 $name: no overflow |

## 4. Đi nước (MOVE)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| MOVE-01 | Một chạm | Tới lượt, ô trống | Chạm ô | Gửi `move` ngay, không xác nhận, không nút "Đi nước này" | unit: test/caro_ui_test.dart::game screen: one tap on a square sends the move |
| MOVE-02 | Một chạm | Tới lượt | Chạm ô trống trên máy thật | Quân hiện, màn chuyển "Đang chờ X", nhãn ô "quân X/O của …" | maestro: maestro/caro-game/05_move3_android.yaml |
| MOVE-03 | Một chạm | Người kia vừa đi (nước 2) | Chạm ô liền kề trên iOS | Nước đi được ghi O | maestro: maestro/caro-game/04_inbox_invited_ios.yaml |
| MOVE-04 | Chuỗi | Đi lần lượt 9 nước xen kẽ 2 máy | Chạy 05–11 | Mỗi nước đồng bộ ≤ 2 s, quân đúng chủ | maestro: maestro/caro-game/11_win_android.yaml |
| MOVE-05 | Ô có quân | Tới lượt | Chạm ô đã có quân | Không gọi CF, không đổi gì | maestro: maestro/caro-game/05_move3_android.yaml |
| MOVE-06 | Lượt sai | Đang chờ người kia | Chạm ô trống | Không có quân mới, không gọi CF | maestro: maestro/caro-game/05_move3_android.yaml |
| MOVE-07 | Lượt sai | Client không phải lượt | Gọi `move` | Provider không gọi service | unit: test/caro_game_test.dart::move refused: pending dropped, result tells why; not my turn = no call |
| MOVE-08 | Chờ doc | `move` đang bay | Quan sát | `pendingCell` giữ tới khi doc có quân; moveNo = `cells.length` | unit: test/caro_game_test.dart::move: pending until the doc has the stone, moveNo = cells.length |
| MOVE-09 | Bị từ chối | CF trả lý do | Quan sát | `pendingCell` bỏ, kết quả cho biết lý do | unit: test/caro_game_test.dart::move refused: pending dropped, result tells why; not my turn = no call |
| MOVE-10 | Lỗi gửi | CF lỗi chung | Chạm ô | Hiện "Chưa đi được nước này, ô bạn chọn vẫn giữ nguyên", nút đổi thành "Thử lại" | unit: test/caro_ui_test.dart::game screen: one tap on a square sends the move |
| MOVE-11 | Lỗi gửi | Lỗi nhưng nước vẫn vào bàn (CARO-T1) | Doc có thêm quân | Ghi chú lỗi tự tắt | unit: test/caro_ui_test.dart::CARO-T1 a move that landed despite the error clears the note |
| MOVE-12 | Lỗi gửi | Ván kết thúc khi có ghi chú lỗi | Ván hết `playing` | Ghi chú tự tắt | unit: test/caro_ui_test.dart::CARO-T1 the game ending clears an action note |
| MOVE-13 | Mạng | Mất mạng giữa lúc gửi | Chạm ô | "Đang mất mạng. Có mạng lại là đi tiếp được." chứ không phải lỗi gửi | unit: test/caro_ui_test.dart::#13 offline while moving → offline note, not the send error |
| MOVE-14 | Mạng | Mất mạng trước khi chạm | Bật airplane, mở ván | Nút "Chờ có mạng" tắt + ghi chú; chạm ô không gửi; có mạng lại đi được | maestro: maestro/caro-game/07_offline_move5_android.yaml |
| MOVE-15 | Mạng | Bàn vừa đổi (người kia đi trước một nhịp) | Chạm ô theo bàn cũ | `stale` → "Bàn vừa đổi, xem lại rồi đi nhé.", chọn bỏ | unit: test/caro_gap_test.dart::MOVE-15 + RACE-06 a move on a changed board: "Bàn vừa đổi", pick dropped |
| MOVE-16 | Bận | `move` đang bay | Chạm ô thứ hai ngay | Bị chặn bởi `isBusy`, không gửi nước thứ hai | unit: test/caro_gap_test.dart::MOVE-16 a second tap while the move is in flight sends nothing (+ provider test cùng tên) |
| MOVE-17 | Bận | Hai ngón chạm 2 ô cùng lúc | Chạm đồng thời | Chỉ một nước | thủ công: Maestro không tạo được chạm đa điểm |
| MOVE-18 | Chạm nhầm | Ô ~22pt < 44pt | Chạm lệch ô | Nước đi vào ô gần nhất, không hoàn tác được (user chấp nhận 2026-10-23) | thủ công: đánh giá cảm giác chạm cần ngón tay thật |
| MOVE-19 | Semantics | Ô trống | Đọc nhãn | "Hàng r, cột c, trống"; ô có quân "…, quân X của Tên", nước cuối ", nước vừa đi" | maestro: maestro/caro-game/05_move3_android.yaml |
| MOVE-20 | Semantics | Painter rebuild semantics | Đổi ô chọn / số quân | Chỉ dựng lại khi khả năng chạm đổi | unit: test/caro_ui_test.dart::#8 semantics rebuild only when tappability changes |
| MOVE-21 | Phân tích | Nước thành công | Quan sát event | `caro_move` có `move_no`, `partner_watching`; không gửi ô/tên/uid/gameId | unit: test/caro_gap_test.dart::MOVE-21 + SEC-36 caro analytics carry only counts / enums / bools (source-guard: AnalyticsService không có seam bắt tham số lúc chạy) |
| MOVE-22 | Presence | Vào/ra màn, nền | Quan sát `presence.{uid}` | Heartbeat 20 s, rời màn/nền thì xoá | unit: test/caro_game_test.dart::enter beats presence; pause clears; resume beats; leave clears |
| MOVE-23 | Presence | `clear()` giữa lúc tạm dừng | Quan sát | Cờ tạm dừng reset | unit: test/caro_ui_test.dart::clear() resets a paused heartbeat |
| MOVE-24 | Presence | App xuống nền trên iOS | Chuyển nền rồi quay lại | Presence xoá khi nền, đập lại khi mở | thủ công: vòng đời nền iOS cần máy thật/quan sát lâu (CARO smoke còn nợ) |

## 5. Luật thắng, hoà (RULE)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| RULE-01 | CF | Năm quân ngang/dọc/hai chéo | `caroWinner` | Thắng | unit: functions/test/caro.test.js::caro: five in a row wins horizontally, vertically and on both diagonals |
| RULE-02 | CF | Nước thắng nằm giữa dãy | `caroWinner` | Thắng | unit: functions/test/caro.test.js::caro: the winning move may be in the middle of the run |
| RULE-03 | CF | Bốn quân | `caroWinner` | Chưa thắng | unit: functions/test/caro.test.js::caro: four in a row does not win |
| RULE-04 | CF | vn: 5 quân bị chặn 2 đầu | `caroWinner` | Không thắng | unit: functions/test/caro.test.js::caro vn: five blocked at both ends by the opponent does not win |
| RULE-05 | CF | vn: 5 quân chặn 1 đầu | `caroWinner` | Thắng | unit: functions/test/caro.test.js::caro vn: five blocked at one end wins |
| RULE-06 | CF | vn: dãy sát mép | `caroWinner` | Mép không tính là chặn → thắng | unit: functions/test/caro.test.js::caro vn: the board edge is not a block |
| RULE-07 | CF | vn: sáu quân | `caroWinner` | Thắng khi không bị chặn cả hai đầu | unit: functions/test/caro.test.js::caro vn: six in a row wins when not blocked at both ends |
| RULE-08 | CF | vn: sáu quân bị chặn hai đầu | `caroWinner` | Không thắng | unit: functions/test/caro.test.js::caro vn: six in a row blocked at both ends does not win |
| RULE-09 | CF | free: 5 quân bị chặn hai đầu | `caroWinner` | Vẫn thắng | unit: functions/test/caro.test.js::caro free: five blocked at both ends still wins |
| RULE-10 | CF | O thắng ở nước lẻ | `caroWinner` | Thắng O | unit: functions/test/caro.test.js::caro: O wins on an odd move |
| RULE-11 | CF | Dãy không đi qua nước cuối | `caroWinner` | Không tính | unit: functions/test/caro.test.js::caro: only lines through the last move count |
| RULE-12 | CF | Kín bàn, không dãy 5 | `caroWinner` | `full` → hoà, cả hai luật | unit: functions/test/caro.test.js::caro: a full board without five is a draw (both rules) |
| RULE-13 | CF | Bàn trống | `caroWinner` | Không thắng, không lỗi | unit: functions/test/caro.test.js::caro: empty board |
| RULE-14 | Dart | Bản sao thuật toán ở client | `CaroBoard.winningLine` | Cùng luật CF: 4 hướng, ngang dọc chéo | unit: test/caro_game_test.dart::five horizontal, vertical, both diagonals |
| RULE-15 | Dart | 4 quân | `winningLine` | Không thắng | unit: test/caro_game_test.dart::four does not win |
| RULE-16 | Dart | Chặn hai đầu: vn không, free có | `winningLine` | Đúng theo luật | unit: test/caro_game_test.dart::blocked at both ends: vn no, free yes |
| RULE-17 | Dart | Chặn một đầu; mép | `winningLine` | Thắng; mép không là chặn | unit: test/caro_game_test.dart::blocked at one end wins; the edge is not a block |
| RULE-18 | Dart | 6 quân | `winningLine` | Mở một đầu thắng, chặn hai đầu không | unit: test/caro_game_test.dart::six: open end wins, both ends blocked does not |
| RULE-19 | Dart | Dãy khác nước cuối | `winningLine` | Chỉ xét đường qua nước cuối | unit: test/caro_game_test.dart::only lines through the last move |
| RULE-20 | E2E | Thắng bằng 5 dọc | Chạy 05–11 | `finished`, `result.reason=five`, `line` 5 ô, tỉ số +1 cho người thắng | maestro: maestro/caro-game/11_win_android.yaml |
| RULE-21 | CF | Thắng | `caroRunOp move` | `wins[caller]++`, xoá `openGameId` | unit: functions/test/caro.test.js::caroRunOp move: five wins, wins++ and the pointer is cleared |
| RULE-22 | CF | Kín bàn | `caroRunOp move` | `draws++`, xoá `openGameId`, `winnerUid=null` | unit: functions/test/caro.test.js::caroRunOp move: full board counts a draw |
| RULE-23 | Dữ liệu | Doc ván | Parse | Lượt, phe, kết quả đúng | unit: test/caro_game_test.dart::parses the CF doc; turn, sides, result |
| RULE-24 | Dữ liệu | `caroState` | Parse | `wins` theo uid, `draws`, doc rỗng | unit: test/caro_game_test.dart::caroState: wins per uid, draws, empty doc |

## 6. Kết thúc ván: xin thua, huỷ, hết hạn (END)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| END-01 | Xin thua | Ván ≥ 2 quân | Bấm "Xin thua" | Hộp "Xin thua ván này?" kèm tỉ số sau khi thua; không có "Để sau" | maestro: maestro/caro-game/18_resign_ios.yaml |
| END-02 | Xin thua | Hộp xác nhận | Bấm "Chơi tiếp" | Đóng hộp, ván giữ nguyên | maestro: maestro/caro-game/18_resign_ios.yaml |
| END-03 | Xin thua | Hộp xác nhận | Bấm "Xin thua" | `finished`, `reason=resign`, người kia +1 | maestro: maestro/caro-game/18_resign_ios.yaml |
| END-04 | Xin thua | CF | `resign` | Người kia thắng, `endedBy`, push `caro_result` nếu họ rời màn | unit: functions/test/caro.test.js::caroRunOp: ops on a game of an earlier pair → not_playing; resign counts for the other |
| END-05 | Xin thua | Bị CF từ chối (vd ván đã xong) | Bấm xác nhận | Hiện lý do, không đóng im lặng | unit: test/caro_ui_test.dart::#4 a refused resign says why instead of closing silently |
| END-06 | Huỷ | Ván 1 quân (mình là người được rủ) | Bấm "Để sau" → "Chơi tiếp" | Đóng hộp, không huỷ | maestro: maestro/caro-game/15_invited_cancel_android.yaml |
| END-07 | Huỷ | Ván 1 quân | "Để sau" → "Bỏ ván" | `cancelled`, màn "Ván này đã huỷ", không tính tỉ số | maestro: maestro/caro-game/15_invited_cancel_android.yaml |
| END-08 | Huỷ | Người rủ mà đổi ý khi chưa ai đi | Bấm "Để sau" ở màn chờ | Huỷ được (chỉ khi `cells ≤ 1`) | unit: test/caro_game_test.dart::stale after 7 days; cancel only with one stone |
| END-09 | Huỷ | Ván đã 2 quân | `cancel` | `stale` (không phải lỗi hệ thống) | unit: functions/test/caro.test.js::caroRunOp cancel with two stones → stale; nudge by turnUid → stale |
| END-10 | Hết hạn | Chưa đủ 7 ngày | `expire` | `too_early` + `retryAfterMs` | unit: functions/test/caro.test.js::caroRunOp expire: too early with retryAfterMs, then ok after 7 days; createdAt fallback |
| END-11 | Hết hạn | ≥ 7 ngày | `expire` | `expired`, không tính tỉ số | unit: functions/test/caro.test.js::caroRunOp expire: too early with retryAfterMs, then ok after 7 days; createdAt fallback |
| END-12 | Hết hạn | Ván chưa có `lastMoveAt` | `expire` | Lùi về `createdAt` | unit: functions/test/caro.test.js::caroRunOp expire: too early with retryAfterMs, then ok after 7 days; createdAt fallback |
| END-13 | Hết hạn | "Kết thúc ván" ở ván treo | Xác nhận | Lý do khi `too_early` hiện "Nhắc được sau N phút" theo `retryAfter` | unit: test/caro_ui_test.dart::#4 nudge cooldown from the server shows the wait |
| END-14 | Hết hạn | Ván treo đã đủ hạn | Bấm "Kết thúc" → "Kết thúc" | `expired`, màn "Ván này đã kết thúc vì để lâu" | unit: test/caro_gap_test.dart::SCR-12 + END-14 stale ≥ 7 days: Nhắc + Kết thúc ván → expire → "để lâu" |
| END-15 | Sau kết thúc | Một ván xong | Rủ ván mới | Ván mở mới trỏ ở `caroState.openGameId`, ván cũ vào lịch sử | maestro: maestro/caro-game/16_cancelled_live_new_free_ios.yaml |
| END-16 | Sau kết thúc | Người rời couple giữa ván | Người kia rời | Ván `expired`, `caroState` xoá, tỉ số về 0 (D20) | thủ công: cần luồng rời couple trên 2 máy và chờ CF `notifyPartnerLeft`; rủi ro dữ liệu, không đưa vào chuỗi flow |
| END-17 | Sau kết thúc | Dọn khi expire lỗi | `caroCleanupOnLeave` | Vẫn xoá state | unit: functions/test/caro_gap.test.js::END-17 caroCleanupOnLeave: expiring the open game fails → state doc is still deleted |
| END-18 | Analytics | Ván kết thúc | Quan sát `caro_game_ended` | Đúng 1 event/ván, từ máy gây kết thúc | unit: test/caro_ui_test.dart::CARO-T5 caro_game_ended comes from the phone that ended the game |
| END-19 | Analytics | Kết quả suy từ phía mình | `caroEndedResult` | won/lost/draw/resigned/cancelled đúng | unit: test/caro_ui_test.dart::caro_game_ended result from my side |
| END-20 | Xoá couple | Xoá tài khoản / couple | `deleteCoupleCompletely` | Xoá `games` và `caroState` | unit: functions/test/caro_gap.test.js::END-20 / SEC-35 deleteCoupleCompletely sweeps games and caroState |
| END-21 | Ghép lại | Ghép lại đúng couple cũ (CARO-T8) | Quan sát | Tỉ số 0–0 nhưng lịch sử còn ván cũ | thủ công: CARO-T8 đã chấp nhận; cần ghép/rời thật |

## 7. Nhắc người ấy và cooldown (NUDGE)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| NUDGE-01 | UI | Vừa đi xong | Xem nút | "Nhắc được sau N phút" tắt | maestro: maestro/caro-game/05_move3_android.yaml |
| NUDGE-02 | Tính toán | Mình chờ, `lastMoveAt`/`lastNudgeAt` | `nudgeWait` | 30 phút kể từ mốc muộn hơn; chỉ người đang chờ | unit: test/caro_game_test.dart::nudge: only the waiting player, 30 min after the later stamp |
| NUDGE-03 | CF | Cùng quy tắc ở server | `caroNudgeWaitMs` | 30 phút sau mốc muộn hơn | unit: functions/test/caro.test.js::caro nudge: 30' after the later of my last move and the last nudge |
| NUDGE-04 | UI | Đã đủ 30 phút | Bấm "Nhắc X" | Snackbar "Đã nhắc X", nút lại khoá, event `caro_nudge_sent` | thủ công: cần đợi 30 phút hoặc chỉnh đồng hồ máy chủ; máy ảo không đổi được giờ Firestore |
| NUDGE-05 | CF | Nhắc trong cooldown | `nudge` | `cooldown` + `retryAfterMs` → "Nhắc được sau N phút" | unit: test/caro_ui_test.dart::#4 nudge cooldown from the server shows the wait |
| NUDGE-06 | CF | Người đến lượt tự nhắc | `nudge` | `stale` | unit: functions/test/caro.test.js::caroRunOp cancel with two stones → stale; nudge by turnUid → stale |
| NUDGE-07 | CF | Nhắc hợp lệ | `nudge` | Ghi `lastNudgeAt`, push `caro_nudge` bất kể presence, không đánh thức | thủ công: push thật không test được (DEV thiếu APNs, emulator không đăng ký FCM); phần ghi `lastNudgeAt` phủ gián tiếp bởi test cooldown |
| NUDGE-08 | CF | Chống đánh thức dồn | `caroShouldWake` | Tối đa 1 lần / 30 phút / người nhận | unit: functions/test/caro.test.js::caro wake: at most once per 30' per recipient |
| NUDGE-09 | CF | Rủ rồi huỷ liên tục | Spam start/cancel | Không spam push (CARO-T3) | unit: functions/test/caro.test.js::CARO-T3/T7: start → cancel → start within 2' is inbox only, no wake, no lastWakeAt |
| NUDGE-10 | Client | Server trả cooldown | `_report` | Mapping cooldown/tooEarly → số phút làm tròn lên | unit: test/caro_ui_test.dart::#4 nudge cooldown from the server shows the wait |

## 8. Đổi luật (RULESET)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| RS-01 | Luật theo ván | Ván chạy luật vn | Người kia đổi ý trong ván | Không có thao tác đổi luật giữa ván (luật khoá theo ván, đổi ở ván sau) | unit: functions/test/caro_gap.test.js::RS-01 the rule is locked per game (chỉ phần CF; rules chưa viết/chạy) |
| RS-02 | Luật theo ván | Luật Tự do | Lời mời | Phụ đề "Luật tự do: cứ năm quân liền nhau là thắng." | maestro: maestro/caro-game/17_invited_free_move_android.yaml |
| RS-03 | Luật theo ván | Luật Chặn hai đầu | Lời mời | Phụ đề "… Luật chặn hai đầu: năm quân bị chặn cả hai đầu thì chưa thắng." | maestro: maestro/caro-game/04_inbox_invited_ios.yaml |
| RS-04 | Luật theo ván | Giá trị `rule` lạ gửi lên CF | `start {rule:'abc'}` | CF rơi về `vn` | unit: functions/test/caro_gap.test.js::RS-04 caroAction: start with rule 'abc' (or none) falls back to vn |
| RS-05 | Tên luật | Chip luật ở màn ván | Đọc | `caroRuleName` đúng vi/en, nhãn "Luật X, chạm để xem giải thích" | unit: test/caro_gap_test.dart::RS-05 rule chip: vi/en name and "chạm để xem giải thích" label |
| RS-06 | Lịch sử | Dòng luật Tự do | Xem lịch sử | Phụ đề thêm ". Tự do" | unit: test/caro_gap_test.dart::HIST-07/08 + RS-06 rows: resign, full board, Tự do suffix |

## 9. Lịch sử và tỉ số (HIST)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| HIST-01 | Vào | Có ván xong | Hồ sơ → "Chơi cùng nhau" → "Cờ caro" (khi không có ván cần mình) | Màn "LỊCH SỬ CARO" | maestro: maestro/caro-game/13_history_android.yaml |
| HIST-02 | Vào | Có ván chờ mình | Chạm ô "Chơi cùng nhau" ở Hồ sơ | Mở thẳng ván chờ mình (caro trước rps) | chưa phủ → đề xuất unit (profile tile target) |
| HIST-03 | Vào | Có chấm đỏ | Hồ sơ | Chấm khi caro tới lượt / được rủ hoặc rps đang chờ | chưa phủ → đề xuất unit |
| HIST-04 | Rỗng | Chưa ván nào | Mở lịch sử | "Chưa có ván nào xong" + "Tỉ số bắt đầu từ 0 – 0." + nút rủ | unit: test/caro_ui_test.dart::result + history screens render (empty history) |
| HIST-05 | Lọc | Có ván của cặp cũ | Tải lịch sử | Chỉ giữ ván có cả hai người của cặp hiện tại | unit: test/caro_game_test.dart::history keeps only games of the current pair |
| HIST-06 | Dòng | Ván thắng bằng 5 quân | Xem | "X thắng. Năm quân liền, N nước. <ngày>" | maestro: maestro/caro-game/13_history_android.yaml |
| HIST-07 | Dòng | Ván xin thua | Xem | "X thắng. Y xin thua ở nước N" | unit: test/caro_gap_test.dart::HIST-07/08 + RS-06 rows: resign, full board, Tự do suffix |
| HIST-08 | Dòng | Ván hoà (kín bàn) | Xem | "Hoà. Kín bàn, 225 nước" | unit: test/caro_gap_test.dart::HIST-07/08 + RS-06 rows: resign, full board, Tự do suffix |
| HIST-09 | Phân trang | > 30 ván | Cuộn xuống | `loadMoreHistory` 30/trang | unit: test/caro_gap_test.dart::HIST-09 history pages are 30 long and stop when there are no more |
| HIST-10 | Lỗi | Trang đầu lỗi | Mở | Chỉ thẻ lỗi + "Thử lại" | unit: test/caro_ui_test.dart::#11 first page fails → only the error card |
| HIST-11 | Lỗi | Trang sau lỗi | Cuộn | "Chưa tải thêm được ván cũ." giữ phần đã tải | unit: test/caro_gap_test.dart::HIST-11 a failing next page keeps the rows and offers a retry |
| HIST-12 | Tiêu đề | Ván nhiều tháng / năm | Xem | Tiêu đề tháng là header semantics, thêm năm khi khác năm nay | unit: test/caro_gap_test.dart::HIST-12 month headers: header semantics, year only when not this year |
| HIST-13 | Tóm tắt | Chỉ khi đã tải hết trang mới ghi "từ {ngày}" | Xem | Dùng key `…NoSince` khi chưa hết | unit: test/caro_gap_test.dart::HIST-13 "từ {ngày}" only once every page is in |
| HIST-14 | Tỉ số | Hai bên | `caroLeads` / `caroTied` | "X dẫn trước N ván" / "Đang hoà a – a" | unit: test/caro_gap_test.dart::HIST-14 score line: who leads, or "Đang hoà a – a" |
| HIST-15 | Xem lại | Chạm dòng | Mở | Chip "VÁN dd/MM", đường thắng có nhãn, không dock | maestro: maestro/caro-game/13_history_ios.yaml |
| HIST-16 | Thumb | Dòng lịch sử | Xem | Bàn thu nhỏ đúng màu hai người, quân màu cạnh tên người thắng | thủ công: kiểm màu cần mắt người |
| HIST-17 | Tỉ số Hồ sơ | Hồ sơ | Xem ô | Giá trị "a – b" + nhãn semantics nêu tên | unit: test/caro_gap_test.dart::HIST-17 profile value "a – b" and the spoken form names both (chỉ chuỗi l10n; ô Hồ sơ là private) |
| HIST-18 | Sheet Hồ sơ | Không ai chờ mình | Chạm ô | Sheet 2 dòng: Cờ caro · Oẳn tù tì, mỗi dòng mở lịch sử riêng | maestro: maestro/caro-game/13_history_ios.yaml |

## 10. Widget màn hình chính (WGT)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| WGT-01 | Dòng trạng thái | Người kia vừa đi, tới lượt mình, app mở | Dựng trạng thái widget | Kind `caro_turn`, focus `caro` | unit: test/caro_ui_test.dart::app path: the partner just moved → caro_turn line, focus caro |
| WGT-02 | Dòng trạng thái | Lượt người kia / nước cuối của mình | Dựng | Không có dòng | unit: test/caro_ui_test.dart::no line when it is the partner’s turn or my own last move |
| WGT-03 | Push nền | Push `caro_turn`/`caro_invite` không có `date` | `fromPush` | Coi là hôm nay; có `sentAt` khác ngày thì bỏ | unit: test/caro_ui_test.dart::background push: caro_turn / caro_invite with no date = today |
| WGT-04 | Kết thúc | `caro_ended`/`caro_result` | `fromPush` | Gửi lệnh xoá có `onlyIfKind=caro_turn` + `onlyIfNewer` | unit: test/caro_ui_test.dart::background push: caro_turn / caro_invite with no date = today |
| WGT-05 | Đánh thức | Xin thua/huỷ/hết hạn khi tới lượt người kia | CF | Gửi push im lặng `caro_ended` (+ `onlyIfKind`) | unit: functions/test/caro.test.js::CARO-T4: cancel / expire / resign wake the other phone only when it was their turn |
| WGT-06 | Đánh thức | Push im lặng | `sendCaroPush caro_ended` | Không banner, không inbox | unit: functions/test/caro.test.js::sendCaroPush caro_ended: silent wake, no inbox, no banner text |
| WGT-07 | Widget thật | Màn hình chính | Xem widget Android/iOS | Hiện "X đã đi caro, đến lượt mình" | thủ công: thêm widget vào màn hình chính qua SpringBoard/launcher không ổn định trên máy ảo; không lái được bằng Maestro |
| WGT-08 | Native | `onlyIfKind` | Dòng không phải `caro_turn` | Native bỏ qua, không xoá dòng tâm trạng/chat | thủ công: code Java/Swift, chỉ kiểm biên dịch (Lead đã chạy javac + swiftc -parse) |

## 11. Thông báo, inbox, chạm mở đúng chỗ (NOTI)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| NOTI-01 | Inbox | Người kia rủ | Mở Trung tâm thông báo | Mục "X rủ bạn chơi cờ caro" + dòng phụ "Nước đầu đã đi rồi, giờ đến lượt bạn." | maestro: maestro/caro-game/04_inbox_invited_ios.yaml |
| NOTI-02 | Inbox | Chạm mục | Mở | Vào đúng màn ván (gameId), Home tab đúng | maestro: maestro/caro-game/04_inbox_invited_ios.yaml |
| NOTI-03 | Inbox | Loại `caro_invite` | `AppNotification` | Type riêng, tab Home, mang gameId | unit: test/caro_ui_test.dart::inbox caro_invite: own type, Home tab, carries the game id |
| NOTI-04 | Inbox | Vào ván từ thông báo | Mở ván | Mục tự đánh dấu đã đọc | thủ công: kiểm huy hiệu chưa đọc nên xem bằng mắt; ghi nhận trong smoke 2026-10-22 là PASS |
| NOTI-05 | Push tap | Push `caro_invite/turn/nudge/result` | `routeTapForTest` | Mở ván của push | unit: test/caro_ui_test.dart::$type push opens that game on Home |
| NOTI-06 | Push tap | Cold start | Chạm push khi app tắt | Vào Home rồi mở ván | thủ công: push thật không test được (DEV thiếu APNs, emulator không FCM); phần định tuyến phủ bởi `routeTapForTest` |
| NOTI-07 | Banner | Đang mở đúng ván | Push về ván đó tới | Không banner trong app | unit: test/caro_ui_test.dart::no in-app banner for a push about the game on screen |
| NOTI-08 | Banner | Hai push cùng ván | Quan sát | 1 banner/ván (id theo gameId), cái mới thay cái cũ | unit: test/caro_ui_test.dart::CARO-T2 foreground banners: one id per caro game |
| NOTI-09 | Gộp | Push cùng ván | Quan sát | `collapseId caro_{gameId}` / `tag` Android | unit: functions/test/index.test.js::collapseId: alert replaces the previous one (Android tag, iOS apns-collapse-id) |
| NOTI-10 | Copy | Push theo ngôn ngữ người nhận | `buildCaroText` | vi/en đúng, tên fallback theo ngôn ngữ người nhận | unit: functions/test/caro.test.js::caro push copy: vi / en, name fallback per recipient language |
| NOTI-11 | Presence | Người nhận đang xem ván | Đi nước | Không push (chỉ ghi inbox/không gì) khi presence < 45 s | unit: functions/test/caro_gap.test.js::NOTI-11 move while the recipient watches (presence < 45 s) → no push |
| NOTI-12 | Push CF | Gửi push + inbox | `sendCaroPush` | `caro_invite` có inbox, `inboxOnly` bỏ push | unit: functions/test/caro.test.js::sendCaroPush: collapseId per game, inbox for invites, inboxOnly skips the phone |
| NOTI-13 | Push CF | Thắng/hoà bằng nước đi | `move` | Push `caro_result` (won/draw) không đánh thức | thủ công: push thật không test được; logic phủ gián tiếp bởi test `caroRunOp move` |
| NOTI-14 | Push CF | Push thật tới thiết bị | Đi một nước | Máy kia nhận banner | thủ công: DEV thiếu APNs (iOS), Android emulator không đăng ký FCM |
| NOTI-15 | Dedupe | Push `sentAt` | Mọi push caro | Có `data.sentAt` | unit: functions/test/caro.test.js::sendCaroPush caro_ended: silent wake, no inbox, no banner text |

## 12. Hai máy, race, mạng (RACE)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| RACE-01 | Đồng bộ | A mời, I đang ở Home | Chờ | I thấy thẻ đổi sang "rủ bạn" ≤ 2 s | maestro: maestro/caro-game/04_inbox_invited_ios.yaml |
| RACE-02 | Đồng bộ | Hai máy cùng mở ván | Một bên đi | Máy kia thấy quân ≤ 2 s, nhãn nước vừa đi đổi | maestro: maestro/caro-game/11_win_android.yaml |
| RACE-03 | Race | Hai máy đi cùng lúc (hai nước cùng `moveNo`) | Gửi gần như đồng thời | Một nước thắng transaction, nước kia `stale`/`not_your_turn`, không hỏng bàn | unit: functions/test/caro.test.js::caro move: legal move, then every refusal reason |
| RACE-04 | Race | Hai máy cùng `start` | Gần đồng thời | Một ván | unit: functions/test/caro.test.js::caroRunOp start: two at once → one game, the other gets already_open |
| RACE-05 | Race | Một bên huỷ khi bên kia vừa đi nước 2 | Cancel vs move | `cancel` trả `stale` nếu đã 2 quân | unit: functions/test/caro.test.js::caroRunOp cancel with two stones → stale; nudge by turnUid → stale |
| RACE-06 | Race | Người kia đi trước một nhịp khi mình chạm | Chạm theo bàn cũ | `stale`, chọn bỏ, thông báo "Bàn vừa đổi" | unit: test/caro_gap_test.dart::MOVE-15 + RACE-06 a move on a changed board: "Bàn vừa đổi", pick dropped |
| RACE-07 | Mạng | Mất mạng xen giữa ván | Bật airplane rồi tắt | Tự đồng bộ lại, không mất nước | maestro: maestro/caro-game/07_offline_move5_android.yaml |
| RACE-08 | Mạng | Mạng chập chờn khi `start` | Gửi lại | Không tạo ván thứ hai (idempotent qua `already_open`) | unit: functions/test/caro.test.js::caroRunOp start: two at once → one game, the other gets already_open |
| RACE-09 | Mạng | Stream ván báo lỗi | Quan sát | Lỗi nổi lên (không nuốt), Home hiện "Thử lại" | unit: test/caro_ui_test.dart::#6 state stream error → Home "Thử lại", retry re-subscribes |
| RACE-10 | Phiên bản | App 1.11.0 (không có caro) chạy cạnh | Người kia chơi rps | Ván caro không lọt vào luồng rps | unit: firebase_rules_test/test/firestore.caroGame.test.js::never lets the rps update branch edit a caro doc |
| RACE-11 | Phiên bản | Ván caro mà `resolveRpsGame` / `nudgeRpsPlayer` nhận | Gọi với gameId caro | `not_playing` | unit: functions/test/caro_gap.test.js::RACE-11 rpsRecordMoveInTransaction / nudgeRpsPlayer on a caro game → not_playing |
| RACE-12 | Phiên bản | Bản cũ không thấy lời rủ | Rủ khi người kia chưa cập nhật | Sau 24 giờ hiện gợi ý "app của X cần cập nhật" | unit: test/caro_gap_test.dart::RACE-12 my invite unseen for 24 h: "app của X cần cập nhật" |
| RACE-13 | Cặp cũ | Ván của cặp cũ (một người đã rời) | Mọi op | `not_playing` | unit: functions/test/caro.test.js::caroRunOp: ops on a game of an earlier pair → not_playing; resign counts for the other |
| RACE-14 | Cặp thiếu | Couple chỉ còn 1 người | `caroAction` | `no_partner` | unit: functions/test/caro.test.js::caroRunOp: a couple of one → no_partner |

## 13. Ngôn ngữ vi/en và a11y (I18N)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| I18N-01 | Bản vi | App tiếng Việt | Duyệt mọi màn | Chữ khớp `app_vi.arb`, xưng hô "chúng mình" không dính "hai đứa" | maestro: maestro/caro-game/11_win_android.yaml |
| I18N-02 | Bản en | Đổi ngôn ngữ sang English | Duyệt Home, sheet, ván, kết quả, lịch sử | Mọi chuỗi có bản tiếng Anh, không còn chữ Việt | thủ công: Maestro đang cố định theo chuỗi tiếng Việt; cần bộ flow riêng sau khi đổi ngôn ngữ trong Cài đặt, và kiểm chữ ngoài ARB (CF copy đã có test) |
| I18N-03 | Parity | Hai ARB | So khoá `caro*` | Đủ 138+ khoá cả vi và en, cùng placeholder | unit: test/caro_gap_test.dart::I18N-03 ARB parity: every caro* key in vi and en, same placeholders |
| I18N-04 | Số nhiều | Giờ/phút ở bản en | `caroSpanHours`, `caroSpanMinutes`, `caroWaitedMin`, `caroNudgeIn` | ICU plural đúng 1 / nhiều | unit: test/caro_ui_test.dart::#9 English plurals for hours / minutes |
| I18N-05 | Định dạng | Ngày giờ theo locale | `caroWhenOn`, `DateFormat` | dd/MM, giờ theo locale | unit: test/caro_gap_test.dart::I18N-05 dates read dd/MM in both locales; times are 24-hour |
| I18N-06 | CF | Lỗi hệ thống của callable | `caroAction` vi/en theo `lang` | Thiếu `lang` thì theo `languageCode`, thiếu cả hai thì vi | unit: functions/test/caro.test.js::caro push copy: vi / en, name fallback per recipient language |
| I18N-07 | a11y | Màn ván | Đọc bằng TalkBack/VoiceOver | Thẻ trạng thái là header + liveRegion; ô có nhãn hàng/cột; nút có nhãn | maestro: maestro/caro-game/05_move3_android.yaml |
| I18N-08 | a11y | Ô bàn | Kích hoạt bằng semantics `onTap` | Giống chạm ngón tay (một chạm là đánh) | unit: test/caro_gap_test.dart::I18N-08 a board square tapped through semantics plays like a finger |
| I18N-09 | a11y | Màu quân | Người dùng khó phân biệt màu | Ngoài màu còn chữ cái X / O trong nhãn semantics | maestro: maestro/caro-game/05_move3_android.yaml |
| I18N-10 | a11y | Nút phóng to | Nhãn đổi theo trạng thái | "Phóng to quanh nước cuối" ↔ "Xem toàn bàn" | maestro: maestro/caro-game/04_inbox_invited_ios.yaml |
| I18N-11 | a11y | Reduce Motion | Bật | Quân rơi, đường thắng, tạm hiện luôn | thủ công: cần bật cài đặt hệ thống rồi mắt người xác nhận |
| I18N-12 | a11y | Chữ ×1,3 | Mở các màn | Không tràn | unit: test/caro_ui_test.dart::#3 360×640 ×1.3 $name: no overflow |
| I18N-13 | a11y | Vùng chạm | Đo nút | Nút pill cao 52, dòng thẻ ≥ 68, nút phóng to 52 | unit: test/caro_gap_test.dart::I18N-13 touch targets: pill 52, zoom 52, Home line ≥ 68 (dòng Home ≥ 68 đo ở HOME-21) |
| I18N-14 | Tour | Bản có caro | Mở app lần đầu sau cập nhật | Mục "Cờ caro theo lượt" trong "Có gì mới" (`sinceBuild: 33`), mở caro khi chạm | unit: test/caro_gap_test.dart::I18N-14 the tour announces caro since build 33 and opens it |

## 14. Bảo mật: rules và Cloud Function chống gian lận (SEC)

| ID | Nhóm | Tiền điều kiện | Bước | Kỳ vọng | Cách kiểm |
|---|---|---|---|---|---|
| SEC-01 | Rules | Người ngoài couple / khách | Đọc ván | Bị từ chối; thành viên đọc được | unit: firebase_rules_test/test/firestore.caroGame.test.js::lets members read a caro game; outsiders and guests cannot |
| SEC-02 | Rules | Người ngoài | Đọc `caroState` | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::lets members read caroState; outsiders cannot |
| SEC-03 | Rules | Client tự tạo ván caro | `games.create` | Bị từ chối (chỉ callable) | unit: firebase_rules_test/test/firestore.caroGame.test.js::forbids a client creating a caro game (callable only) |
| SEC-04 | Rules | Heartbeat presence của mình | Update | Cho phép | unit: firebase_rules_test/test/firestore.caroGame.test.js::lets each player heartbeat their own presence key |
| SEC-05 | Rules | Xoá presence của mình | Update | Cho phép | unit: firebase_rules_test/test/firestore.caroGame.test.js::lets a player clear their own presence key |
| SEC-06 | Rules | Heartbeat trên ván đã xong | Update | Cho phép (màn kết quả) | unit: firebase_rules_test/test/firestore.caroGame.test.js::allows a heartbeat on a finished game (result screen) |
| SEC-07 | Rules | Ghi presence của người kia | Update | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::rejects writing the partner\'s presence key |
| SEC-08 | Rules | Xoá/ghi đè cả map presence | Update | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::rejects wiping or overwriting the whole presence map |
| SEC-09 | Rules | Presence không phải giờ server | Update | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::rejects a presence value that is not the server clock |
| SEC-10 | Rules | Người ngoài sửa presence | Update | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::forbids an outsider touching presence |
| SEC-11 | Gian lận | Client tự đặt quân (`cells`), một mình hoặc kèm heartbeat | Update | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::rejects a client placing a stone (cells) — alone or with a heartbeat |
| SEC-12 | Gian lận | Sửa `turnUid`, `status`, `players` | Update | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::rejects a client changing turnUid / status / players |
| SEC-13 | Gian lận | Tự tuyên bố kết quả | Update | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::rejects a client declaring a result |
| SEC-14 | Gian lận | Sửa `lastNudgeAt` / `lastWakeAt` để vượt cooldown | Update | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::rejects a client touching the cooldown fields (lastNudgeAt / lastWakeAt) |
| SEC-15 | Gian lận | Xoá ván | Delete | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::forbids deleting a caro game |
| SEC-16 | Gian lận | Tạo `moves` dưới ván caro | Create | Bị từ chối | unit: firebase_rules_test/test/firestore.caroGame.test.js::forbids a moves doc under a caro game (even one with startedAt) |
| SEC-17 | Gian lận | Ghi `caroState` | Write | Bị từ chối (đổi tỉ số, đổi `openGameId`) | unit: firebase_rules_test/test/firestore.caroGame.test.js::forbids any client write to caroState |
| SEC-18 | Tương thích | Luồng rps | Rps vẫn chạy khi có ván caro | Không vỡ | unit: firebase_rules_test/test/firestore.caroGame.test.js::keeps the rps flow working next to a caro game |
| SEC-19 | Tương thích | Nhánh update rps | Sửa doc caro | Không cho phép | unit: firebase_rules_test/test/firestore.caroGame.test.js::never lets the rps update branch edit a caro doc |
| SEC-20 | CF | Người đi không phải lượt | `caroMoveError` | `not_your_turn` | unit: functions/test/caro.test.js::caro move: legal move, then every refusal reason |
| SEC-21 | CF | Không phải người chơi | `caroMoveError` | `not_player` | unit: functions/test/caro.test.js::caro move: legal move, then every refusal reason |
| SEC-22 | CF | Ô có quân | `caroMoveError` | `occupied` | unit: functions/test/caro.test.js::caro move: legal move, then every refusal reason |
| SEC-23 | CF | `moveNo` lệch | `caroMoveError` | `stale` | unit: functions/test/caro.test.js::caro move: legal move, then every refusal reason |
| SEC-24 | CF | Ô ngoài bàn | `caroMoveError` | `out_of_range` | unit: functions/test/caro.test.js::caro move: legal move, then every refusal reason |
| SEC-25 | CF | Ván không `playing` | `caroMoveError` | `not_playing` | unit: functions/test/caro.test.js::caro move: legal move, then every refusal reason |
| SEC-26 | CF | `cell` là số lẻ, âm, chuỗi, NaN | `caroCell` | Chỉ nhận số nguyên trong bàn 15×15 | unit: functions/test/caro.test.js::caro cell: only integers on the 15×15 board |
| SEC-27 | CF | Gọi `caroAction` khi chưa đăng nhập | Callable | `unauthenticated` | unit: functions/test/caro_gap.test.js::SEC-27 caroAction: no auth → unauthenticated |
| SEC-28 | CF | `coupleId` / `gameId` rác (có `/`, quá dài) | Callable | `invalid-argument`, không chạm Firestore | unit: functions/test/caro_gap.test.js::SEC-28 caroAction: junk coupleId / gameId → invalid-argument |
| SEC-29 | CF | Op lạ | Callable | `invalid-argument` | unit: functions/test/caro_gap.test.js::SEC-29 caroAction: unknown / missing op → invalid-argument |
| SEC-30 | CF | Người ngoài couple gọi | Callable | `permission-denied` | unit: functions/test/caro_gap.test.js::SEC-30 caroAction: a stranger → permission-denied |
| SEC-31 | CF | Gọi với gameId của couple khác | Callable | Không thấy ván (đọc theo đường dẫn couple của caller), không rò dữ liệu | unit: functions/test/caro_gap.test.js::SEC-31 a gameId of another couple is not found |
| SEC-32 | CF | `rematchOf` trỏ ván không thuộc couple | `start` | Không đọc ván lạ, không crash | unit: functions/test/caro_gap.test.js::SEC-32 start with a foreign / path-like rematchOf |
| SEC-33 | CF | Tỉ số | Cộng bằng `increment` | Không ghi đè khi hai ván kết thúc gần nhau | unit: functions/test/caro.test.js::caroRunOp move: five wins, wins++ and the pointer is cleared |
| SEC-34 | CF | Ván đã kết thúc | Gửi `move` | `not_playing`, tỉ số không cộng lần hai | unit: functions/test/caro_gap.test.js::SEC-34 move after the game finished → not_playing |
| SEC-35 | CF | Xoá couple | `deleteCoupleCompletely` | Dọn `games` + `caroState` | unit: functions/test/caro_gap.test.js::END-20 / SEC-35 deleteCoupleCompletely sweeps games and caroState |
| SEC-36 | Riêng tư | Analytics | Sự kiện caro | Không chứa ô, tên, uid, gameId | unit: test/caro_gap_test.dart::MOVE-21 + SEC-36 caro analytics carry only counts / enums / bools (source-guard) |

## Tổng số case theo cách kiểm

Bảng này do script đếm từ cột cuối (xem lệnh ở cuối file).

| Cách kiểm | Số case |
|---|---|
| unit (đã có test) | 195 |
| maestro (chạy được trên 2 máy ảo) | 53 |
| chưa phủ → đề xuất unit | 2 (HIST-02, HIST-03: logic nằm trong `_AchievementsGrid` private của ProfileScreen, cần tách hàm thuần mới test được) |
| thủ công | 19 |
| **Tổng** | **269** |

## Phát hiện khi soạn (cần Lead/Dev quyết)

1. **SCR-29 — khung phóng không dịch theo nước mới.** `_applyInitialZoom` chỉ canh một lần mỗi ván (`_zoomAppliedFor`). Vào ván đang phóng 1,6× quanh nước cuối lúc mở; nếu người kia đi xa vùng nhìn khi mình còn ở màn, nước mới nằm ngoài khung và không có dấu hiệu nào ngoài nhãn "Đến lượt bạn". Flow Maestro luôn bấm "Xem toàn bàn" trước khi chạm để né.
2. **Đổi hành vi b7e0e88 còn dấu vết.** Khoá ARB `caroPlayHere` ("Đi nước này") giờ chỉ hiện ở nút thử lại sau lỗi gửi; `caroTapAgainHint` chỉ còn ở màn nháp. `dev.md` stage 2 vẫn mô tả chạm hai bước cho cả ván: nên sửa tài liệu.
3. **MOVE-16 / RACE-06 / MOVE-15** (bận, race, `stale` ở nước đi) là chỗ rủi ro nhất mà test chưa chạm; ưu tiên viết test widget cho ba ca này.
4. **Nhóm CF chưa có test ở lớp callable `caroAction`** (SEC-27…32): `caroRunOp` được test kỹ nhưng lớp xác thực/kiểm tham số/thành viên thì không.

## Cách đếm

```
awk -F'|' '/^\| [A-Z0-9]+-[0-9]+ /{c=$7; gsub(/^ +| +$/,"",c); split(c,a,":"); print a[1]}' project/features/caro-game/test-cases.md | sort | uniq -c
```
