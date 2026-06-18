# 💻 Dev — Chat status

> Đọc [overview.md](overview.md) trước.

- **Trạng thái dev:** code-level xong, analyze sạch, DEV deployed — chờ smoke-test + PROD.
- **Người/role:** Dev

## Kế hoạch kỹ thuật (đã làm)
- *Mô hình:* subcollection `couples/{id}/receipts/{uid}` (`deliveredAt`/`readAt` serverTimestamp). Mình ghi doc của mình; đối phương đọc để biết tin của mình đã nhận/đọc.
- *Suy ra trạng thái cho tin CỦA MÌNH* (`ChatProvider.statusOf`):
  - `isPending`/`createdAt==null` → **sending**
  - `partner.readAt ≥ msg.createdAt` → **read**
  - `partner.deliveredAt ≥ msg.createdAt` → **delivered**
  - còn lại → **sent**
- *File đụng tới:*
  - `firestore.rules` — match `/receipts/{receiptId}`: read=member, write=member & id==uid & hasOnly([deliveredAt,readAt]) & is timestamp, no delete. **Additive.**
  - `firebase_rules_test/.../firestore.couples-sub.test.js` — +6 ca (write own/merge/partner-read/forbid-partner-write/extra-field/outsider). Emulator **178 pass**.
  - `lib/services/chat_service.dart` — `ChatReceipt` typedef + `_receiptsCollection` + `watchPartnerReceipt(coupleId, myUid)` (lấy doc id != myUid) + `markReceipt(coupleId, uid, {delivered, read})` (serverTimestamp, merge, fail-soft).
  - `lib/models/chat_message.dart` — public `parseTimestamp` (dùng cho receipt).
  - `lib/providers/chat_provider.dart` — enum `ChatMessageStatus`; watch partner receipt (`_partnerDeliveredAt/_partnerReadAt`); `_maybeMarkDelivered()` ghi deliveredAt khi có tin partner mới (throttle `_deliveredUpToMillis`); `markSeen` ghi thêm delivered+read; `statusOf`; reset/cancel ở watchForCouple/clear/dispose.
  - `lib/screens/chat_screen.dart` — tính status tin mình mới nhất → `_MessageList.latestMineStatus`; render `_StatusLabel` (icon clock→tick→tick-bold→tick-hồng + text) dưới tin cuối cùng mình gửi.
  - `lib/l10n/app_en/vi.arb` — +`chatStatusSent`/`Delivered`/`Read` (tái dùng `chatSending` cho "Đang gửi").
- *Deploy:* rules additive → **DEV deployed 2026-06-18**; **PROD chờ lệnh**.

## Edge case đã xử lý
- Local fallback (no Firebase) → `statusOf` trả `none` (không có partner). Label ẩn.
- deliveredAt chỉ ghi khi có tin partner MỚI hơn `_deliveredUpToMillis` → tránh spam write mỗi snapshot.
- readAt persist ở Firestore → đổi máy vẫn giữ "đã đọc" (Hive seen-marker chỉ là cache local cho unread-dot, độc lập).
- Receipt watch lấy doc id != myUid (collection ≤2 doc) → không cần biết partnerUid.
- "đã nhận" xấp xỉ: máy kia online & stream nhận được tin (giống mọi app); offline thì write queue, cập nhật khi online.

## Nhật ký implement
- [2026-06-18] [Dev] Code xong toàn bộ feature: rules+test (178 pass), service receipt, provider statusOf + watch/mark, UI `_StatusLabel`, l10n. analyze sạch. DEV deployed. Chờ smoke 2 thiết bị + PROD.
