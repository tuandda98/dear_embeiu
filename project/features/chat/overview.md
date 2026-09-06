# Chat — trò chuyện riêng của 2 người (tab thứ 4 bottom nav)

> File PO sở hữu. Nguồn sự thật chung cho cả feature.

- **Feature:** chat
- **Ưu tiên:** P0 (user yêu cầu trực tiếp 2026-06-11; table-stakes đối thủ — strategy.md từng xếp LATER, user kéo lên NOW)
- **Trạng thái:** 🧪 Test PASS-có-điều-kiện code-level (8/8 AC; Tester 7 minor → fix 4, nợ 3) — DEV đã deploy rules+CF; **PROD chờ lệnh user**; chờ smoke-test 2 thiết bị (6 mục test.md, nặng nhất: regression deep-link)
- **Tạo ngày:** 2026-06-11
- **Liên quan:** [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · liên đới: love-note (Home ritual GIỮ), love-note-history (tile bị thay), pagination (tái dùng pattern)

## 1. Vấn đề & giá trị
- User: "thay vì làm nhật ký lời nhắn, tôi muốn làm hẳn riêng 1 cái chat trên bottom button bar" (kèm screenshot tile cũ + bottom nav).
- Chat = lý do mở app hằng ngày (habit loop mạnh nhất), giữ chân cả 2 phía — phục vụ North Star gián tiếp (mở app → thấy ảnh → đăng ảnh).

## 2. Quyết định đã chốt (PO, 2026-06-11 — user đã uỷ quyền "tự quyết tự làm")
- **D1 — Tab thứ 4:** bottom nav `[Trang chủ ♥ · Trò chuyện 💬 (messageCircle) · Thư viện 🖼 · Hồ sơ 👤]` — chat đứng thứ 2 (cạnh Home, vị trí ngón cái). IndexedStack + TickerMode như 3 tab cũ.
- **D2 — Data model:** `couples/{coupleId}/messages/{messageId}`: `authorUserId` (uid, immutable) + `text` (≤1000) + `createdAt` (serverTimestamp). Collection MỚI hoàn toàn → additive, app cũ không ảnh hưởng (backward-compat OK).
- **D3 — Rules:** member read/create; create phải `authorUserId == auth.uid` + `hasOnly([authorUserId,text,createdAt])` + text string ≤1000 + `createdAt == request.time`; **update/delete = false** (v1 không sửa/xoá — tin nhắn là kỷ niệm). Chạy `scripts/test-firebase-rules.sh` trước khi xong; deploy DEV ngay, **prod chờ lệnh user**.
- **D4 — Push:** CF mới `notifyChatMessage` (onCreate messages) theo đúng pattern `notifyLoveNote`: skip self, localize vi/en theo `languageCode`, `sendToRecipientDevices` + `writeInboxNotifications` (type `chat_message`). Deep-link tap → tab Trò chuyện (NotificationTapRouter + notif center). Deploy functions DEV; prod chờ lệnh.
- **D5 — Realtime + phân trang:** tái dùng pattern pagination vừa làm cho history: window realtime 50 mới nhất + load older 50 (cursor createdAt, guard couple sau await, map tích lũy theo id, dedup, teardown reset). List `reverse: true` neo đáy.
- **D6 — Love note ritual trên Home GIỮ NGUYÊN** (nghi thức 1-lời-nhắn ≠ chat). **Tile "Nhật ký lời nhắn" bị GỠ** (chat thay thế lối vào); màn `LoveNoteHistoryScreen` GIỮ code + route, lối vào mới = icon lịch sử (history) trên header tab Chat — không phí pagination vừa làm.
- **D7 — Unread dot trên icon tab chat:** marker Hive `chat_seen_<coupleId>` (pattern `love_note_seen_`) — tin partner mới hơn marker → dot đỏ nhỏ trên icon tab; vào tab = seen. KHÔNG đếm số (v1).
- **D8 — Composer:** input pill surfaceLight + nút gửi tròn rose; gửi optimistic (hiện ngay, pending state nhẹ); Enter/submit gửi; trim, chặn rỗng; giữ bàn phím sau gửi. Nav ẩn khi bàn phím mở (hành vi sẵn có extendBody).
- **D9 — KHÔNG trong v1:** ảnh/sticker/emoji-react trong chat, typing indicator, sửa/xoá/thu hồi, migrate noteHistory cũ vào chat (2 dòng dữ liệu độc lập).

## 3. Acceptance criteria
1. Bottom nav 4 tab, pill active đúng, TickerMode từng tab, deep-link push `chat_message` mở đúng tab (cold+warm), các deep-link cũ không vỡ.
2. Gửi tin 2 máy realtime ≤ ~1s; offline gửi → queue Firestore tự sync; optimistic không duplicate.
3. Rules: non-member bị DENY read/create; create sai author/thừa field/quá 1000 ký tự bị DENY (`test-firebase-rules.sh` pass).
4. Push đến máy partner khi app background (DEV); tap mở đúng tab chat; inbox notif center có entry; KHÔNG push cho chính mình.
5. Phân trang: 50 đầu + load older khi cuộn lên; teardown sạch khi sign-out/leave.
6. Unread dot hiện/tắt đúng theo marker seen.
7. Home ritual love-note + journal không đổi hành vi; tile "Nhật ký lời nhắn" gỡ, lịch sử truy cập được từ header Chat.
8. l10n đủ vi+en; analyze 0 issue; test pass.

## 4. Nhật ký
- [2026-06-11] [po] Tạo feature, chốt D1–D9, bật pipeline Designer→Dev→Tester.
