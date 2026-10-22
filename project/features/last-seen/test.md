# last-seen — Test

## 2026-10-15 — app thật, Firebase dev (`tonyembeiu-dev`)

Simulator iPhone 17, `flutter run` debug, tài khoản Thảo (uid `TZSMpRu5BdYtcE0CiyzTuu7O0672`). Tạm hạ ngưỡng còn 1 phút, thêm log tạm, đã gỡ cả hai sau khi thử. Đọc doc qua Firestore REST.

| Bước | `lastSeenAt` | `updatedAt` | Kết quả |
|------|--------------|-------------|---------|
| Cold start | — | 05:18:05 | (nhánh cũ) |
| Ra nền → mở lại | 05:18:23 | 05:18:05 | ✅ ghi, `updatedAt` không đổi |
| Ra nền → mở lại ngay (< 1 phút) | 05:18:23 | 05:18:05 | ✅ không ghi |
| Đợi > 1 phút, ra nền → mở lại | 05:19:48 | 05:18:05 | ✅ ghi lại |

Unit: `test/last_seen_throttle_test.dart` PASS.
