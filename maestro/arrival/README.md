# Flow Maestro cho feature `arrival` (báo "đã tới nơi")

Bộ case đầy đủ: `project/features/arrival/test-cases.md`. Flow chỉ phủ phần máy ảo làm được.

## Máy và tài khoản

| | Android | iOS |
|---|---|---|
| Máy | emulator `emulator-5554` | simulator `23B763A6-DF45-4E75-9112-F9636CCB983B` |
| Tài khoản | `test3@gmail.com` (Tuấn) | `test4@gmail.com` (Thảo) |
| appId | `com.tony.dearembeiu.dev` | `com.tony.dearembeiu.dev` |

Backend Firebase DEV, đã ghép đôi (`widget_couple_dev`), app tiếng Việt. Flow giả định tên hiển thị là "Tuấn" và "Thảo" (thẻ in tên người ấy). Flow không `clearState`, luôn `launchApp` rồi đi từ Home.

```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools:/opt/homebrew/bin"
AND=emulator-5554
IOS=23B763A6-DF45-4E75-9112-F9636CCB983B
maestro --device $AND test maestro/arrival/00_reset_android.yaml
maestro --device $IOS test maestro/arrival/00_reset_ios.yaml
```

Kiểm cú pháp không cần máy: `maestro check-syntax maestro/arrival/<flow>.yaml`.

## Thứ tự chạy

Chạy lần lượt, mỗi dòng là một flow. Tên file cho biết máy nào chạy.

| # | Flow | Máy | Đặt vị trí trước | Làm gì |
|---|---|---|---|---|
| 1 | `00_reset_android` | Android | không | tắt chia sẻ nếu đang bật |
| 2 | `00_reset_ios` | iOS | không | như trên |
| 3 | `01_decline_android` | Android | không | Bật báo về nhà → Để sau |
| 4 | `02_manual_home_android` | Android | không | bấm tay "Về nhà rồi" |
| 5 | `03_view_home_ios` | iOS | không | thấy tin của Tuấn, "Hỏi thăm" |
| 6 | `04_add_place_ios` | iOS | **Công ty** (xem dưới) | thêm "Công ty" bằng vị trí hiện tại |
| 7 | `05_manual_place_ios` | iOS | không | "Đến nơi rồi" → Công ty |
| 8 | `06_view_place_android` | Android | không | thấy "Thảo đã đến Công ty" |
| 9 | `07_offline_manual_android` | Android | không | mất mạng, tin xếp hàng, có mạng lại |
| 10 | `08_auto_setup_ios` | iOS | **Nhà** | bật Tự báo, cấp "Luôn luôn" |
| 11 | `09_perm_downgrade_ios` | iOS | không | sau lệnh hạ quyền, thẻ báo thiếu quyền |
| 12 | `10_auto_view_android` | Android | **kịch bản geofence** | chờ tin tự động của Thảo |
| 13 | `11_turn_off_ios` | iOS | không | tắt chia sẻ |
| 14 | `12_view_off_android` | Android | không | thấy "Chưa bật báo về nhà", không còn tin |

`_sub/` là các bước dùng chung, không chạy riêng.

## Đổi vị trí máy ảo

Toạ độ gợi ý (Hà Nội): Nhà `21.0285,105.8542` · Công ty `21.0031,105.8201` · Ngoài vùng `21.0600,105.8900` (cách Nhà ~5 km).

```bash
# Android: lưu ý tham số là KINH ĐỘ trước, VĨ ĐỘ sau
adb -s $AND emu geo fix 105.8542 21.0285
# iOS: VĨ ĐỘ trước, KINH ĐỘ sau
xcrun simctl location $IOS set 21.0285,105.8542
# iOS: chạy tuyến (từ Ngoài vùng vào Nhà), bấm Ctrl+C để dừng
xcrun simctl location $IOS start --speed=20 21.0600,105.8900 21.0285,105.8542
xcrun simctl location $IOS clear
```

Android emulator cần có "fix" thật: mở Google Maps một lần sau khi đặt vị trí (README plugin `native_geofence`). Lead ghi 2026-10-22: `adb emu geo fix` trả OK nhưng `dumpsys location` không đổi, nên mọi bước đọc vị trí và geofence ưu tiên chạy trên iOS simulator, Android chỉ dùng bấm tay.

Trước thứ tự #6 (`04_add_place_ios`): `xcrun simctl location $IOS set 21.0031,105.8201`.
Trước thứ tự #10 (`08_auto_setup_ios`): `xcrun simctl location $IOS set 21.0285,105.8542` (Nhà).

## Quyền vị trí iOS (không phải bấm hộp hệ thống)

```bash
B=com.tony.dearembeiu.dev
xcrun simctl privacy $IOS grant location $B           # Khi dùng ứng dụng
xcrun simctl privacy $IOS grant location-always $B    # Luôn luôn
xcrun simctl privacy $IOS revoke location-always $B   # hạ về Khi dùng (trước thứ tự #11)
xcrun simctl privacy $IOS reset location $B           # về chưa hỏi
```

Android tương ứng:

```bash
P=com.tony.dearembeiu.dev
adb -s $AND shell pm grant $P android.permission.ACCESS_FINE_LOCATION
adb -s $AND shell pm grant $P android.permission.ACCESS_BACKGROUND_LOCATION
adb -s $AND shell pm revoke $P android.permission.ACCESS_BACKGROUND_LOCATION
```

## Thứ tự #12 (`10_auto_view_android`): tạo sự kiện geofence

Cần `08_auto_setup_ios` xong ở trạng thái "Đã bật báo về nhà".

1. `xcrun simctl location $IOS set 21.0600,105.8900` (ngoài vùng), mở app iOS vài giây.
2. Đưa app iOS ra nền: `xcrun simctl launch $IOS com.apple.Preferences` (hoặc mở app khác). Không vuốt tắt app.
3. Chờ ~30 giây (để hệ thống ghi nhận "ngoài vùng", sự kiện RỜI Nhà không push).
4. Chạy flow Android: `maestro --device $AND test maestro/arrival/10_auto_view_android.yaml`.
5. Ngay sau khi flow bắt đầu chờ: `xcrun simctl location $IOS set 21.0285,105.8542`. Hoặc dùng `start` để chạy tuyến vào Nhà.
6. Flow chờ tối đa 5 phút. Thấy "Đã về đến nhà" ở làn Thảo, không có "bấm tay" là đạt.

Region monitoring trên simulator không ổn định: không ra tin thì ghi vào test-cases ở case SK-01 là "thủ công trên máy thật", không coi là lỗi của app.

## Mất mạng (thứ tự #9)

Flow `07` dùng `toggleAirplaneMode`. Emulator hay không cắt mạng thật khi bật máy bay. Nếu dải "Sẽ báo khi có mạng" không hiện, tắt mạng bằng lệnh rồi bỏ hai dòng `toggleAirplaneMode`:

```bash
adb -s $AND shell svc wifi disable; adb -s $AND shell svc data disable
adb -s $AND shell svc wifi enable;  adb -s $AND shell svc data enable
```

## Không làm được trên máy ảo

Push thật (iOS DEV chưa có APNs, Android emulator không có FCM), tap push, widget trên màn hình chính, geofence khi app bị kill, khởi động lại máy, quyền "Cho phép mọi lúc" nhiều bản Android. Liệt kê và lý do ở cột "Cách kiểm" của `test-cases.md`.

## Mẹo selector đã dùng

Selector là regex khớp nguyên chuỗi semantics. Hàng gộp nhãn dùng `(?s).*…*.` (nháy đơn khi có `\?`). Thẻ bị thanh điều hướng nổi che thì `scrollUntilVisible` + `centerElement: true` + `waitForAnimationToEnd`. iOS simulator vẽ emoji thành "?" nên flow không assert emoji. Hộp quyền hệ thống bấm `optional: true`.
