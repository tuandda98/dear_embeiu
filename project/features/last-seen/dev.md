# last-seen — Dev

## Đã code (2026-10-15)

- `lib/services/user_service.dart`
  - Constructor nhận thêm `clock` (mặc định `DateTime.now`) để test bơm đồng hồ giả.
  - `touchLastSeen(uid)`: `update({'lastSeenAt': FieldValue.serverTimestamp()})`, bọc `try/catch` nuốt lỗi. Dùng `update` chứ không `set merge`: doc chưa tồn tại thì lỗi rồi bỏ qua, không tạo nửa hồ sơ.
  - `takeLastSeenSlot()` (`@visibleForTesting`): giữ mốc lần ghi cuối trong bộ nhớ, chặn theo `lastSeenInterval = 1 giờ`. Giữ chỗ TRƯỚC khi ghi, ghi lỗi cũng không thử lại trong giờ đó.
- `lib/providers/auth_provider.dart`: `touchLastSeen()` — chưa đăng nhập thì thôi, có thì `unawaited(_userService.touchLastSeen(_currentUser!.id))`. AuthProvider có `UserService` riêng (tham số `userService` tuỳ chọn), sống suốt vòng đời app nên mốc 1 giờ giữ được.
- `lib/main.dart` `didChangeAppLifecycleState`: nhánh `resumed` gọi thêm `_authProvider.touchLastSeen()` cạnh `refreshPushRegistration()`.
- `test/last_seen_throttle_test.dart`: đồng hồ giả, soát mốc 5 phút / 59p59s / tròn 1 giờ.

## Ghi chú

- Lần mở app từ đầu vẫn ghi `lastSeenAt` + `updatedAt` qua nhánh cold start cũ trong `auth_service.dart` — không đổi trong đợt này. Mốc 1 giờ không tính lần ghi đó, nên lần resume đầu tiên sau cold start sẽ ghi thêm 1 lần.
- Offline: Firestore SDK xếp hàng lệnh ghi và đẩy khi có mạng lại; `serverTimestamp` lấy giờ server lúc ghi tới. Không chặn gì, không báo lỗi.
- Rules không đổi → không cần chạy `scripts/test-firebase-rules.sh`.

## Kiểm

- `flutter analyze`: sạch. `flutter test`: 593 pass, 3 skip.
- App thật: xem [test.md](test.md).
