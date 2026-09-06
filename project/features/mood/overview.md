# 🧭 PO — Tâm trạng hôm nay (Mood)

- **Trạng thái:** v1 built + DEV deployed (2026-06-19). Prod chờ lệnh.
- **Mục tiêu (user):** kéo user **mở app mỗi ngày** (daily hook).

## Vì sao (North Star)
North Star = cặp active đăng ảnh/tuần. Daily-engagement feature như mood nuôi thói quen mở app → tăng cơ hội đăng ảnh/nhắn/trả lời câu hỏi. Mood là **vòng lặp cảm xúc** mạnh cho cặp đôi: "người ấy hôm nay thế nào?" là câu hỏi tự nhiên cả 2 muốn biết mỗi ngày.

## Research (2026-06-19, web)
- Mood check-in hiệu quả khi **nhanh (1–2 chạm)** kiểu Daylio (emoji scale) — không bắt gõ nhiều.
- Engagement: streak/achievement, **variable reward** (mở ra mới biết mood người kia), reminder/push.
- Couple app: "app tốt nhất là app **cả 2 đều mở**" → tối ưu cho việc cả 2 cùng dùng + reciprocity.
- Nguồn: behance/dribbble couple-app UI · purrweb/fulminous dating UX · thelifeplanner gamification · clustox mood-tracker UX.

## Quyết định spec (PO tự chốt)
- **8 mood ấm áp** (có "Nhớ" rất hợp cặp đôi): Vui/Hạnh phúc/Nhớ/Bình yên/Bình thường/Mệt/Buồn/Căng thẳng.
- **Theo NGÀY**: mood gắn `date`; sang ngày mới reset → phải chia sẻ lại (đó là daily hook).
- **Partner mood LUÔN hiện** (không gate "phải chia sẻ mới xem") — mood là sự QUAN TÂM, không phải game; gate sẽ gây ức chế. Reciprocity đẩy bằng nudge + push, không bằng khoá.
- **Push khi người ấy đổi mood** = driver mở app chính (content-free, không lộ mood/note).
- **KHÔNG đưa vào Notification Center** (mood ephemeral "hôm nay", không phải item cần log) → push-only.
- Note ngắn tuỳ chọn (≤100) để thêm bối cảnh ("vì sao").

## Phạm vi v1 / nợ (v2+)
- v1: card Home + picker + realtime 2 chiều + push. 
- v2 (đề xuất): thả tim/“ôm” phản hồi mood người ấy · mood streak/lịch sử · nhắc "chưa chia sẻ hôm nay" (local reminder) · widget.

## Acceptance (đã verify)
Card hiện đúng mood mình+người ấy theo ngày · picker 1-chạm + note · ghi/đọc Firestore 0 lỗi quyền · rules-test 187 pass · analyze 0. Suppression-free (độc lập feature chat). Verify cross-device (2 máy: A đổi mood → B nhận push + thấy trên card) do user.
