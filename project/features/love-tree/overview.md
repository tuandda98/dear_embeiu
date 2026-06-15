# Cây tình yêu (Love Tree) — overview (PO)

> Feature mới 2026-06-14 (user chốt autonomous, đi ngủ — "PO tự quyết tự chốt tự làm"). Mode 1: Designer → Dev → Tester.

## 1. Ý tưởng (user)
Một màn hình mới có **1 cái cây** biểu tượng cho tình cảm 2 người. Khi có **sự kiện** (streak 7 ngày, 100 tin, kỷ niệm 100 ngày…) cây **nở hoa**, **nhuỵ hoa là 1 icon tròn**. Cây phát triển + nở hoa cần **xúc tác của CẢ 2 người**. Khi có sự kiện, user vào app **thấy cây đang nở hoa luôn**.

## 2. PO chốt (v1)

### Mô hình "hoa = cột mốc" — DERIVE từ data sẵn có, KHÔNG backend mới
Chỉ dùng tín hiệu **monotonic** (chỉ tăng) ⇒ hoa đã nở KHÔNG bao giờ rụng (đúng cảm xúc: cột mốc tình yêu tích luỹ, không mất):
- **Ngày bên nhau** (`couple.anniversaryDate` → daysTogether): mốc 30 · 100 · 200 · 365(1 năm) · 520 · 730(2 năm) · 1000 · 1314. Nhuỵ = icon 💞 (heart) màu rose.
- **Streak DÀI NHẤT** (`StreakProvider.longestStreak` — KHÔNG dùng currentStreak vì reset): mốc 3 · 7 · 30 · 100 · 365. Nhuỵ = icon 🔥 (flame) màu cam-hồng.
- **Số ảnh kỷ niệm** (`PhotoProvider.photoCount`): mốc 1 · 10 · 25 · 50 · 100. Nhuỵ = icon 📷 (image) màu tím-lavender.
- (Tin nhắn / daily question: HOÃN v1 — chưa có bộ đếm tích luỹ; ghi backlog.)

→ **Số hoa = số mốc đã vượt** (đếm qua 3 nguồn). Càng nhiều mốc → càng nhiều hoa.

### Cây phát triển theo SỐ HOA (stage)
0 hoa → Hạt mầm · 1–2 → Mầm non · 3–5 → Cây non · 6–9 → Cây xanh · 10+ → Cây nở rộ. (Designer chốt visual từng stage — dựng bằng shape/path, KHÔNG cần asset art ngoài.)

### "Xúc tác của 2 người"
Cả 3 tín hiệu vốn cần 2 người (streak = cả 2 kết nối; ngày = mối quan hệ; ảnh = cùng đăng). Màn cây có khối **"Cùng vun đắp"**: gợi 2–3 hành động làm cây lớn (giữ chuỗi · đăng ảnh · trả lời câu hỏi) → CTA về tab tương ứng. Copy nhấn "cả hai".

### "Vào app thấy cây nở hoa" (cảm giác sự kiện)
- Lưu `lastSeenFlowerCount` (Hive `app_settings`, key `love_tree_seen_<coupleId>`).
- Mở màn cây: nếu `flowerCount > lastSeen` → **animation NỞ HOA** cho (các) bông mới + banner "Cây vừa nở X bông mới 🌸" → rồi cập nhật lastSeen.
- **Badge chấm/glow** trên StreakChip (entry) khi có hoa chưa xem ⇒ dụ user vào xem.

### Navigation
Tap **StreakChip** (chỗ "Cùng bắt đầu chuỗi mới nhé 🌱", `streak_chip.dart`) → **push `LoveTreeScreen`** (màn con chuẩn: `SubScreenHeader` back + chip). (Streak sheet auto-celebration giữ nguyên cho khoảnh khắc đạt mốc streak.)

## 3. North Star
Đẩy **retention + xúc tác 2 người** (mở app, giữ chuỗi, đăng ảnh) → phục vụ "cặp active đăng ảnh/tuần". Cây = mục tiêu cảm xúc chung, gamify nhẹ shame-free.

## 4. Ngoài phạm vi v1 (backlog)
- Hoa từ tin nhắn / daily-question (cần counter tích luỹ).
- Tree state share realtime qua Firestore (v1 derive local từ data đã sync sẵn → đủ).
- Tương tác chạm cây / tỉa / đặt tên cây.

## Trạng thái
- [2026-06-14] v1 DONE (code-level, analyze 0 issue, Tester 12/12 PASS). Chờ user smoke-test runtime (animation/visual R1-R6).
