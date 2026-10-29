# Flow Maestro: Thời tiết hai nơi

Bộ case đầy đủ: `project/features/weather/test-cases.md`. Flow chưa được chạy thử (viết khi 2 máy ảo đang bận); selector lấy từ `lib/l10n/app_vi.arb` và semantics trong `lib/widgets/weather/`. Selector nào trượt thì sửa theo `maestro studio`/`maestro hierarchy`.

## Máy và tài khoản

| Máy | Id | Tài khoản | appId |
|---|---|---|---|
| Android emulator | `emulator-5554` | `test3@gmail.com` (Tuấn) | `com.tony.dearembeiu.dev` |
| iOS simulator | `23B763A6-DF45-4E75-9112-F9636CCB983B` | `test4@gmail.com` (Thảo) | `com.tony.dearembeiu.dev` |

App tiếng Việt, backend DEV, đã ghép đôi (`widget_couple_dev`). Chạy một flow: `maestro --device <id> test maestro/weather/<file>`. Android cần `export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"`.

## Thứ tự chạy (các flow nối tiếp nhau qua dữ liệu Firestore)

| # | File | Máy | Việc |
|---|---|---|---|
| 1 | `01_invite_hide_android.yaml` | Android | Thẻ mời, bảng chọn không xin vị trí, tìm không ra, bấm "Ẩn" |
| 2 | `02_pick_self_settings_android.yaml` | Android | Cài đặt, chọn Hà Nội bằng "hanoi", thẻ hiện lại |
| 3 | `03_pick_for_partner_android.yaml` | Android | "Chọn giúp" TP.HCM bằng "hcm" |
| 4 | `04_see_both_ios.yaml` | iOS | Thảo thấy 2 thành phố realtime, mở chi tiết, dòng MET |
| 5 | `05_pick_own_ios.yaml` | iOS | Thảo tự đổi sang Đà Nẵng |
| 6 | `06_sees_self_set_android.yaml` | Android | Tuấn thấy Đà Nẵng, "Thảo tự chọn", hết "Đổi giúp" |
| 7 | `07_settings_android.yaml` | Android | Mục Cài đặt, công tắc, xem trước |
| 8 | `08_offline_cache_android.yaml` | Android | Máy bay, khởi động lại, số từ cache vẫn hiện |
| 9 | `09_gps_ignored_android.yaml` | Android | Vị trí giả ở Seoul, thẻ vẫn theo Hà Nội |
| 10 | `10_cta_prefill_android.yaml` | Android | Nút nhắc (chỉ khi thời tiết thật đủ điều kiện), màn Quan tâm điền sẵn, không bấm Gửi |

Flow 1 đến 3 cần trạng thái sạch (xem dưới). Flow 4 đến 6 phải chạy ngay sau flow trước (đúng thứ tự, không xen). Flow 7 đến 10 chạy lại được nhiều lần.

## Đặt lại về trạng thái sạch (trước flow 1)

1. Seed lại cặp test: `NODE_OPTIONS=--dns-result-order=ipv4first node scripts/dev-seed-widget-accounts.js`. Script này không xoá `couples/widget_couple_dev/weather/*`; nếu còn doc cũ thì xoá tay hai doc `weather/{uid test3}` và `weather/{uid test4}` (Firebase Console DEV hoặc firebase-admin).
2. Cờ ẩn thẻ và cache nằm trong Hive của app: gỡ app khỏi máy ảo hoặc xoá dữ liệu app, rồi đăng nhập lại (Android: `adb -s emulator-5554 shell pm clear com.tony.dearembeiu.dev`; iOS: gỡ và cài lại). Flow cố ý không `clearState`.

## Lệnh tiền xử lý

| Flow | Lệnh |
|---|---|
| 09 (Android) | `adb -s emulator-5554 emu geo fix 126.98 37.57` (Seoul, tham số là kinh độ rồi vĩ độ) |
| 09 (iOS, chạy tay, không có flow) | `xcrun simctl location 23B763A6-DF45-4E75-9112-F9636CCB983B set 37.57,126.98` (vĩ độ rồi kinh độ) |
| Trả vị trí về Hà Nội sau flow 09 | Android: `adb -s emulator-5554 emu geo fix 105.85 21.03` · iOS: `xcrun simctl location 23B763A6-DF45-4E75-9112-F9636CCB983B set 21.03,105.85` |
| 08 | Không cần. Flow tự bật/tắt máy bay (`setAirplaneMode`), kể cả khi lỗi giữa chừng. Nếu emulator kẹt máy bay: `adb -s emulator-5554 shell cmd connectivity airplane-mode disable` |

Feature chọn thành phố bằng tay, không đọc GPS. Vì thế lệnh vị trí giả chỉ để chứng minh app bỏ qua nó (case LOC-02). Muốn thử "tự lấy vị trí" thì chưa có tính năng này.

## Ghi chú

- Số độ, câu "đang mưa" và việc có nút "Nhắc … mang ô" phụ thuộc thời tiết thật của MET lúc chạy, nên flow chỉ assert tên thành phố và chữ cố định. Flow 10 dùng `runFlow when: visible` nên ngày đẹp trời vẫn pass mà không thử được nút.
- Flow 7 chạm vào dòng "Thời tiết chỗ người ấy" để gạt công tắc; nếu Switch không nhận chạm trên nhãn thì đổi sang chạm toạ độ công tắc.
- iOS không có lệnh `back`: sheet đóng bằng chạm vùng mờ phía trên (`point: 50%,4%`).
- Simulator iOS vẽ emoji thành "?", flow không assert emoji.
- Case cần chờ giờ thật (07:30 nổ), TalkBack/VoiceOver, APNs trên DEV, bản app cũ chạy song song: nằm ở nhóm "thủ công" trong `test-cases.md`.
