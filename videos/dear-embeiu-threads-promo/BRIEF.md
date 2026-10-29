---
workflow: product-launch-video
flow: automation
storyboard: no
message: "Con số vẫn có. Chỉ là không còn trơ trọi — Dear Embeiu nhớ người ấy giúp bạn, không chỉ đếm ngày."
destination: threads
aspect: 1080x1920
language: vi
audience: "Cặp đôi trẻ Việt Nam (Gen Z / đầu Millennials) đang dùng hoặc từng dùng app đếm ngày yêu"
length: 30s
angle: "3 câu app đếm ngày thường không trả lời được"
style_preset: ""
---

## Intent

Video quảng cáo 30 giây cho Threads, mục tiêu gây chú ý rồi kéo người dùng tải Dear Embeiu — app đếm ngày yêu kiêm không gian riêng của hai người (ảnh chung, câu hỏi mỗi ngày, tâm trạng, giấc ngủ, cây tình yêu).

Ý tưởng đã chốt (2026-10-15): **"3 câu app đếm ngày thường không trả lời được"**, mở màn mượn cảnh **màn hình khoá tối với một thông báo** rơi xuống ("Tuấn đang thấy Nhớ"). Không chia đôi màn hình ✗/✓. Ba câu hỏi lần lượt hiện trên nền blush: "Người ấy hôm nay thấy sao?" · "Đêm qua người ấy ngủ lúc mấy giờ?" · "Hôm nay chúng mình đã nói gì với nhau?". App thường chỉ trả lời bằng một thẻ "1250 ngày ❤️" đứng im; Dear Embeiu trả lời bằng màn hình thật (tâm trạng, giấc ngủ, câu hỏi hôm nay). Kết: "Con số vẫn có. Chỉ là không còn trơ trọi." rồi CTA.

Giọng: ấm, đời thường, hơi trêu nhẹ app cũ nhưng không chê ai đích danh. Xem không tiếng vẫn hiểu trọn (Threads tự phát tắt tiếng): chữ trên màn hình gánh thông điệp, nhạc chỉ làm nền.

## Assets

- capture/assets/ — màn hình quay thật từ simulator iPhone 17 (bản debug nối Firebase dev `tonyembeiu-dev`, tài khoản mock Thảo ❤ Tuấn, 1250 ngày): Home (đồng hồ đếm + ảnh), Tâm trạng, Giấc ngủ, Câu hỏi hôm nay (reveal cả hai), Thư viện ảnh. Dữ liệu mock seed bằng `scripts/dev-seed-promo.js` của repo app.
- capture/assets/unsplash/ — ảnh cặp đôi Unsplash (Unsplash License) làm nền màn hình khoá, nền 9:16 và ảnh trong thư viện app; manifest kèm tên nhiếp ảnh gia.
- capture/assets/icon/ — icon app (từ `assets/` của repo) cho thông báo mở màn và CTA.
- audio/bgm.mp3 — nhạc nền CC0 / royalty-free tìm trên web (manifest kèm license).

## Customizations

- Mở màn: màn hình khoá dựng bằng HTML (ảnh Unsplash làm hình nền, giờ 22:41, một thông báo kiểu iOS với icon app thật) — không quay từ simulator để chủ động nhịp.
- Không lời đọc (VO). Nhạc nền do host cung cấp (`music: none` trong storyboard, bgm `source: host`).
- Thẻ "app thường" là thẻ tĩnh tự dựng: nền trắng nhạt, số "1250 ngày" + một trái tim, cố tình nhàm — không mô phỏng giao diện app đối thủ nào.
- Điện thoại thật đặt trong khung iPhone dựng bằng CSS (viền + Dynamic Island), chiếm ~70% chiều cao để chừa chỗ cho câu hỏi phía trên.
- Đồng hồ đếm ở cảnh kết: số nhảy từng giây (count-up thật trên timeline).
- CTA cuối: logo + "Dear Embeiu" + "Miễn phí · App Store & Google Play" + "dearembeiu.com".

## Notes

- Không nêu tên app đối thủ; gọi chung "app đếm ngày thường".
- Copy tiếng Việt, xưng "chúng mình" / "người ấy" (luật copy của Dear Embeiu — không dùng "hai đứa"); cấm cụm sáo rỗng kiểu AI.
- Màu/chữ lấy từ design system của app: Quicksand (bundled `assets/fonts/` của repo), nền `dawnBlush` #FFC1CC→#E8B4D8→#C8A8E9, hero `sunsetRomance` #FF6B9D→#FF8FA3→#FFB6C1, accent #FF4D6D, navy chữ #1A1A2E. Mọi chỉnh UI đối chiếu skill UI UX Pro Max theo luật của user.
- 9:16 1080×1920, 30 fps. Chữ quan trọng giữ trong vùng giữa (chừa ~200px trên/dưới cho UI Threads).
- Dùng lại được cho Reels/TikTok không cần dựng lại.
- Remotion hay repo khác chỉ kéo vào khi thiếu linh kiện; không dựng song song hai framework.
