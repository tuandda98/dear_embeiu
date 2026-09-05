# Care message — Test (Tester sở hữu)

## [2026-09-05] [code-review max] commit 01971bc (care-message + catch-up) — 15 finding CONFIRMED → [Dev] vá cùng ngày
| # | Finding | Vá |
|---|---|---|
| 1 | Gate trả bài ngày cũ kích `notifyDailyAnswer` → push/inbox "hôm nay" + wake huỷ nhắc hôm nay của người ấy | ✅ response ghi `backfill:true`; CF vẫn stamp `bothAnswered` nhưng bỏ push/inbox/wake. Script restore cũng ghi `backfill:true`. |
| 2 | Ngày KHÔNG AI trả lời cũng bị ép trả bài (vô ích cho chuỗi) | ✅ chỉ tính ngày người ấy ĐÃ trả lời mà mình chưa. |
| 3 | Gate submit offline treo trong dialog không đóng được | ✅ timeout 12s → coi như đã xếp hàng, đi tiếp + toast. |
| 4 | `_isShowing` kẹt true khi route bị remove (session revoked) | ✅ reset trong `dispose` của dialog. |
| 5 | `_personalCatchupSignature` không reset ở nhánh non-target | ✅ reset. |
| 6 | Scan lỗi bị coi là "hết nợ" → huỷ dải nhắc | ✅ `findMissedDays` trả `null` khi lỗi; caller giữ nguyên + bỏ throttle. |
| 7 | `submitAnswer` derive lại questionVi (đã được Q1 sửa) | ✅ |
| 8 | Clamp UTF-16 cắt đôi emoji → "�" trong push | ✅ không kết thúc bằng high-surrogate. |
| 9 | Gửi quan tâm offline treo + gửi trùng | ✅ timeout 10s → toast "đã xếp hàng" + pop. |
| 10 | Inbox `care_message` bị auto-read ngay khi ở Home | ✅ loại khỏi `unreadForTab/markReadForTab`. |
| 11 | Off-Firebase báo "Đã gửi" giả | ✅ `send` trả bool; false → toast lỗi. |
| 12 | Gate TextField `enabled:!_sending` rớt focus | ✅ bỏ `enabled`. |
| 13 | Màn quan tâm tạo lại stream mỗi phím gõ | ✅ `_RecentCareMessages` stateful giữ stream. |
| 14 | Body quan tâm bị cắt 2 dòng, không màn chi tiết | ✅ Notification center + danh sách gần đây hiện trọn body. |
| 15 | Email gated trùng 3 nơi | ✅ `ReminderProvider` dùng `CatchupService.gatedEmail`. |

Chưa smoke-test 2 máy thật (push nguyên văn có dấu, badge, gate trả bài).

## Vòng 2 — [2026-09-05] [Tester] Xác minh bản vá care-message + catch-up (commit `fe53eaa`) — ✅ PASS
analyze 0 · test 81/81 · rules-test 241. 15/15 finding vá đạt; điểm rủi ro nhất (rule `responses` không `hasOnly` ⇒ `backfill` được phép; rule `questionVi/En` bất biến không DENY luồng thường vì rules đọc doc SAU merge; CF stamp `bothAnswered` TRƯỚC early-return backfill) đều verified.
- BUG mới P2 (đã vá cùng ngày): `dispose` gate có thể xoá nhầm guard của gate mới (→ token `_token`); `_clamp` cắt giữa cụm emoji ghép (→ duyệt grapheme trong ngân sách UTF-16).
- Còn [CẦN TEST runtime, 2 máy]: backfill không bắn push ngày cũ / không huỷ nhắc hôm nay; gate rollover nửa đêm; care note offline gửi đúng 1 lần. ⚠️ PROD chưa deploy rules + `notifyDailyAnswer` + `notifyCareMessage` + `generateDailyQuestion`.

## [2026-09-05] [Tester-runtime] Smoke-test 2 máy — ✅ PASS + 1 bug UI đã vá
- Android (test1): nút 💌 header → màn Quan tâm (6 chip, form, "Đã gửi gần đây" có tin seed) → chip "Uống nước nha 💧" → Gửi → về Home. Firestore: doc `careMessages` mới + CF `notifyCareMessage` ghi inbox cho test2 với **title/body nguyên văn**.
- iOS (test2): chuông báo 7 chưa đọc; Trung tâm thông báo hiện "Uống nước nha 💧" + "Nhớ em 💕" với chấm chưa đọc (không bị auto-read ở Home ✓).
- 🐛 **Body vẫn bị cắt 1 dòng "…"** dù đã bỏ `maxLines`: gotcha Flutter — `overflow: TextOverflow.ellipsis` không kèm `maxLines` ép layout 1 dòng. **Đã vá** (`TextOverflow.visible` cho care ở Notification center + danh sách "Đã gửi gần đây"); chưa re-verify trên máy (cần rebuild).
- Chưa cover: push banner thật (không kiểm được token FCM trên emulator/simulator), catch-up gate (chỉ tài khoản gated).

## [2026-09-05] [Tester-runtime] Timeline quan tâm — smoke-test 2 máy (Android emulator = test1 · iPhone 16 simulator = test2, DEV) — ✅ PASS
- Profile: 2 tile "Gửi quan tâm" + "Dòng thời gian quan tâm · 3 lời quan tâm" (đếm đúng), đều nằm trên "Huy hiệu".
- Timeline Android (vi) và iOS (en): gom "HÔM NAY/TODAY", avatar Mình/Em Test (rose/lavender), title + body TRỌN, giờ HH:mm; thứ tự mới → cũ.
- Màn gửi: "Đã gửi gần đây/Recently sent" + "Xem tất cả/See all" → mở timeline.
- iOS gửi "Have you eaten? 🍚" → Android: Trung tâm thông báo hiện item với body đầy đủ 2 dòng (fix overflow đã có hiệu lực), chấm chưa đọc; **tap → mở timeline và highlight đúng tin**.
- Chưa cover: phân trang >30 tin, empty state (couple test đã có tin), tin cũ không có `careMessageId` trong inbox.
