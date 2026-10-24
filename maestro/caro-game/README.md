# Maestro cho caro-game (Maestro 2.11)

Hai máy ảo đã đăng nhập sẵn, đã ghép đôi, backend DEV, appId `com.tony.dearembeiu.dev`, app tiếng Việt:

- `A` = Android `emulator-5554`, `test3@gmail.com` (Tuấn)
- `I` = iOS simulator `23B763A6-DF45-4E75-9112-F9636CCB983B`, `test4@gmail.com` (Thảo)

Cần `export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"` (Maestro gọi adb). Không flow nào dùng `clearState`.

```
cd maestro/caro-game
maestro --device emulator-5554 test 05_move3_android.yaml
maestro --device 23B763A6-DF45-4E75-9112-F9636CCB983B test 06_move4_ios.yaml
```

## Tiền điều kiện

Không có ván caro nào đang mở. Nếu còn ván cũ: mở ván, "Xin thua" (hoặc "Để sau" nếu mới 1 quân). Tỉ số cũ không ảnh hưởng, flow không kiểm số.

## Thứ tự chạy (xen kẽ, một ván hoàn chỉnh rồi huỷ, rồi ván thứ hai kết thúc bằng xin thua)

| # | File | Máy | Việc |
|---|---|---|---|
| 1 | `01_home_card_android.yaml`, `01_home_card_ios.yaml` | A, I | Thẻ "Chơi cùng nhau" có dòng Cờ caro |
| 3 | `03_draft_invite_android.yaml` | A | Bấm "Chơi" ở Home: gửi lời mời luôn, X ở giữa bàn (hàng 8, cột 8). Sheet chọn luật/tự chọn ô đầu giờ chỉ còn ở Ván mới/Phục thù (flow 14, 16) |
| 4 | `04_inbox_invited_ios.yaml` | I | Inbox "rủ bạn chơi cờ caro", chạm mở ván, ô có quân bị bỏ qua, zoom, đi O (hàng 8, cột 9) |
| 5 | `05_move3_android.yaml` | A | Thẻ "Đến lượt bạn", đi X (9,8); chạm lúc chờ không tác dụng; nút Nhắc khoá |
| 6 | `06_move4_ios.yaml` | I | O (9,9) |
| 7 | `07_offline_move5_android.yaml` | A | Bật chế độ máy bay: "Chờ có mạng"; tắt: đi X (10,8) |
| 8 | `08_move6_ios.yaml` | I | O (10,9) |
| 9 | `09_move7_android.yaml` | A | X (11,8) |
| 10 | `10_move8_ios.yaml` | I | O (11,9) |
| 11 | `11_win_android.yaml` | A | X (12,8): 5 quân dọc, màn thắng + đường thắng |
| 12 | `12_lost_live_ios.yaml` | I | `launchApp: stopApp: false` (giữ màn ván): thấy thua, "Phục thù" |
| 13 | `13_history_android.yaml`, `13_history_ios.yaml` | A, I | Hồ sơ → Chơi cùng nhau → Cờ caro → lịch sử → xem lại |
| 14 | `14_rematch_ios.yaml` | I | Bấm "Chơi" ở Home khi vừa thua = phục thù; để nguyên màn ván |
| 15 | `15_invited_cancel_android.yaml` | A | "Để sau" → "Chơi tiếp" → "Để sau" → "Bỏ ván" |
| 16 | `16_cancelled_live_new_free_ios.yaml` | I | (giữ màn ván) thấy "Ván này đã huỷ", rủ ván mới luật Tự do |
| 17 | `17_invited_free_move_android.yaml` | A | Lời mời nói "Luật tự do", đi O (8,9); để nguyên màn ván |
| 18 | `18_resign_ios.yaml` | I | Xin thua (Chơi tiếp giữ nguyên, rồi xác nhận) |
| 19 | `19_resigned_live_android.yaml` | A | (giữ màn ván) thấy "xin thua", "Ván này bạn thắng, ở nước 2." |

Flow 12, 16, 19 phụ thuộc màn ván flow ngay trước của chính máy đó vẫn còn mở (dùng `stopApp: false`). Chạy thiếu bước thì chạy lại từ đầu chuỗi.

`_lib_open_card.yaml` (cuộn tới dòng "Cờ caro" rồi chạm) và `_lib_zoom_out.yaml` (bấm "Xem toàn bàn" nếu đang phóng) là subflow, không chạy riêng.

## Lưu ý selector

- Selector là regex khớp nguyên chuỗi semantics; nhãn gộp dùng `.*`. Tên người (`Tuấn`, `Thảo`) để `.*` vì lấy từ hồ sơ.
- Ô bàn có nhãn `Hàng r, cột c, trống` / `…, quân X của <tên>` (+ `, nước vừa đi`, `, đang chọn`, `, trong đường thắng`). Cột/hàng đếm từ 1; ô giữa bàn = hàng 8, cột 8. Ván mở ở mức phóng 1,6× nên mọi flow chạm ô đều bấm "Xem toàn bàn" trước.
- Nếu `tapOn` theo nhãn ô không ăn trên một nền tảng, đổi sang `point: "x%,y%"` trong vùng bàn (hàng/cột × 6,67% + 3,3%, tính theo hộp bàn sau khi thu nhỏ); đừng assert emoji, simulator iOS vẽ thành "?".
- `assertVisible … enabled: false` (nút Rủ/Nhắc/Chờ có mạng) và `setAirplaneMode` (flow 07, chỉ Android) là chỗ dễ chập chờn nhất; nếu lỗi môi trường, xoá riêng dòng đó, đừng sửa app.
- Không kiểm được bằng Maestro: push thật (DEV thiếu APNs, emulator không đăng ký FCM), widget màn hình chính, hành vi sau 30 phút (nhắc, hết hạn 7 ngày), ngôn ngữ English. Xem `test-cases.md`.
