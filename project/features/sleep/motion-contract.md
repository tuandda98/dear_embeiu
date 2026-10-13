# Hợp đồng kênh — nguồn dự phòng "chuyển động" (2026-10-13, nhánh `feature/sleep-motion`)

User chốt 2026-10-13: (1) chỉ dẫn bật đo giấc ngủ có sẵn của iPhone (Lịch ngủ + "Theo dõi thời gian trên giường bằng iPhone" — có máy iOS 18+ không còn ghi nữa, nên chỉ là gợi ý "tuỳ máy"); (2) nguồn **chuyển động** làm dự phòng MẶC ĐỊNH cho cả iOS lẫn Android khi nguồn chính không có đêm đó.

## Quyết định
- Đêm tính từ chuyển động lưu `source: SleepSource.auto` ("tự động từ điện thoại"). KHÔNG thêm giá trị source mới ⇒ không sửa `firestore.rules`, không deploy, app cũ đọc được.
- Nguồn chính giữ nguyên: iOS = Health (`SleepMode.health`), Android = màn hình (`SleepMode.auto`, cần Usage access). Chuyển động chỉ LẤP những đêm nguồn chính trả `null`/không có. Android chưa cấp Usage access thì chuyển động là nguồn duy nhất.
- iOS: Core Motion `CMMotionActivityManager` (iOS tự lưu 7 ngày lịch sử, đọc lại được khi mở app). Android: Activity Recognition **Transition API** (`STILL` ENTER/EXIT) qua `PendingIntent` → `BroadcastReceiver` ghi vào SharedPreferences; không có lịch sử trước lúc đăng ký. KHÔNG dùng Sleep API (Google đã ngừng phát triển).

## Kênh `dear_embeiu/sleep` — method mới (cả 2 nền tảng)
| Method | Args | Trả về |
|---|---|---|
| `motionSupported` | – | `bool` — iOS `CMMotionActivityManager.isActivityAvailable()`; Android: Play services khả dụng (GoogleApiAvailability SUCCESS). |
| `motionPermission` | – | `String` `'granted'` \| `'denied'` \| `'notDetermined'` — iOS `CMMotionActivityManager.authorizationStatus()` (restricted → denied); Android API ≥ 29 `checkSelfPermission(ACTIVITY_RECOGNITION)` (chưa hỏi lần nào → `notDetermined`, dùng SharedPreferences ghi cờ đã hỏi), API < 29 → `granted`. |
| `requestMotionPermission` | – | `bool` granted — iOS: chạy 1 `queryActivityStarting` ngắn để hiện hộp xin quyền rồi đọc lại status; Android: `ActivityCompat.requestPermissions` + chờ `onRequestPermissionsResult`. Trả `true` nếu đã granted. |
| `startMotionTracking` | – | `bool` — Android: đăng ký `requestActivityTransitionUpdates` (STILL ENTER + EXIT) idempotent, PendingIntent `FLAG_MUTABLE` (API 31+) tới receiver explicit; gọi mỗi lần app refresh. iOS: no-op `true`. |
| `motionStillSpans` | `{from: ms, to: ms}` | flat `Int64` `[startMs, endMs, startMs, endMs, …]` — các quãng máy ĐỨNG YÊN giao với [from,to], sắp tăng dần, đã cắt vào [from,to]. iOS: từ `queryActivityStarting(from,to)`: activity `stationary == true` và `confidence != .low` mở quãng, activity kế tiếp không stationary đóng quãng (quãng cuối còn mở thì đóng ở `min(to, now)`). Android: ghép ENTER/EXIT đã lưu; ENTER cuối chưa có EXIT thì đóng ở `min(to, now)`. |

Kênh lỗi / không hỗ trợ → trả rỗng / false, KHÔNG ném lỗi (Dart đã best-effort).

## Android lưu trữ
- SharedPreferences `dear_embeiu_motion`, key `events` = chuỗi `"<ms>:<1|0>,…"` (1 = ENTER STILL, 0 = EXIT), chỉ giữ 14 ngày gần nhất. Thư mục prefs này phải loại khỏi backup (thêm vào `res/xml` backup rules giống dữ liệu ngủ — audit D6).
- Receiver `.sleep.MotionTransitionReceiver` (exported=false). Thêm `RECEIVE_BOOT_COMPLETED` + receiver `.sleep.MotionBootReceiver` (BOOT_COMPLETED, MY_PACKAGE_REPLACED) đăng ký lại khi quyền còn.
- Quyền manifest: `android.permission.ACTIVITY_RECOGNITION` (API 29+) + `com.google.android.gms.permission.ACTIVITY_RECOGNITION` (maxSdkVersion 28). Dependency `com.google.android.gms:play-services-location`.

## iOS
- `NSMotionUsageDescription` trong `Info.plist` + `ios/Runner/{en,vi}.lproj/InfoPlist.strings`.

## Dart
- `SleepPlatform`: `motionSupported()`, `motionPermission()`, `requestMotionPermission()`, `startMotionTracking()`, `motionStillSpans(from,to)` → `List<RestSpan>`.
- `sleep_calculator.dart`: `computeMotionNights(List<RestSpan> still, {wakeDates, now})` dùng `computeNight` + `SleepRules.motion`, `source: SleepSource.auto`.
- Provider `refresh()`: tính nguồn chính như cũ, rồi với mỗi ngày nguồn chính không có đêm → lấy từ chuyển động (khi `motionPermission == granted`).

## Vòng vá 1 (sau Tester FAIL 2026-10-13)
- Method mới `stopMotionTracking` → `bool`: Android `removeActivityTransitionUpdates` + xoá prefs `dear_embeiu_motion` (cả `events` lẫn mốc) + đặt cờ `enabled=false`; iOS no-op `true`. Dart gọi khi tắt Giấc ngủ, chuyển sang thủ công, đăng xuất, xoá tài khoản.
- Android chỉ ghi/đăng ký khi cờ prefs `enabled == true` (đặt bởi `startMotionTracking`). `MotionBootReceiver` + receiver transition bỏ qua khi cờ false (API 24–28 quyền cấp sẵn KHÔNG còn tự bật).
- Method mới `motionCoverageStart` → `Int64` ms: Android = lúc `startMotionTracking` đăng ký lần đầu (lưu prefs, reset khi stop), 0 nếu chưa; iOS = `now − 7 ngày`. Dart bỏ mọi khung đêm có `window.start` < mốc này (như `coverageStart` của nguồn màn hình).
- Android: `startMotionTracking` và boot ghi 1 EXIT tổng hợp ở thời điểm đăng ký nếu sự kiện cuối là ENTER (chống quãng mở kéo dài). `startMotionTracking` trả kết quả thật của Task.
- iOS: activity `stationary` với `confidence == .low` hoặc `unknown == true` (không automotive/walking/running/cycling) là TRUNG TÍNH — không mở, không đóng quãng.
- Dart: đêm từ chuyển động chỉ hợp lệ khi khối ngủ phủ ≥ 60 phút trong 00:00–06:00 của ngày thức (chặn máy nằm trên bàn buổi sáng/chiều). `ponytail:` chỉnh sau smoke-test.
