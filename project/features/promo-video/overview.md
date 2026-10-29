# promo-video — Video quảng cáo Dear Embeiu cho Threads

**Trạng thái:** 🎬 Bản 1 dựng xong 2026-10-15 (30 s, 9:16). Chờ user xem thử và duyệt đăng.

## Mục tiêu

Gây chú ý trên Threads rồi kéo người dùng tải app. Kịch bản "3 câu app đếm ngày thường không trả lời được": mở màn bằng một thông báo lúc 22:41 ("Tuấn đang thấy Nhớ 🥹"), thẻ app thường chỉ có "1250 ngày ❤️" → "Rồi sao nữa?" → 3 câu hỏi, mỗi câu được màn hình thật của app trả lời (tâm trạng, giấc ngủ, câu hỏi hôm nay) → "Con số vẫn có. Chỉ là không còn trơ trọi." → CTA.

## Quyết định đã chốt (user, 2026-10-15)

- Hướng #4 (3 câu hỏi) + mở màn màn hình khoá của hướng #2. 30 giây. Không duyệt storyboard trước, dựng một mạch. Nhạc CC0 tự tìm.
- Làm như studio: có kịch bản (`KICH-BAN.md`), thiết kế, ánh sáng/màu, quay dựng, âm thanh, hậu kỳ.
- Không nêu tên app đối thủ. Xưng "chúng mình"/"người ấy". Không lời đọc (Threads tắt tiếng).
- Mọi cảnh bằng chứng là màn hình thật quay từ simulator với dữ liệu mock (ảnh Unsplash, cặp Thảo ❤ Tuấn 1250 ngày).

## Sản phẩm

- `videos/dear-embeiu-threads-promo/renders/video.mp4` — 1080×1920, 30 fps, 30 s, H.264 + AAC (không commit; render lại bằng `npm run render`).
- Kịch bản: `videos/dear-embeiu-threads-promo/KICH-BAN.md`. Brief/storyboard/thiết kế: `BRIEF.md`, `STORYBOARD.md`, `frame.md` cùng thư mục.
- Nhạc: "3 am West End" (statusq, CC0 1.0 — FreePD qua Wayback). Ảnh: 12 tấm Unsplash License (manifest ở `capture/assets/unsplash/manifest.json`, có tên nhiếp ảnh gia).

Chi tiết kỹ thuật & cách quay lại: [dev.md](dev.md).

## Phim ra mắt 50 s — Remotion (bản 1, 2026-10-15 chiều)

**Yêu cầu user:** lấy đúng prompt video của Forex AI Lab (`~/WebstormProjects/ea-studio/videos/forexailab-launch-50s/BRIEF.md`,
phim 50 s 1920×1080 60 fps, Remotion, âm thanh tổng hợp bằng code) và dùng lại cho Dear Embeiu; không dùng lại ảnh cũ,
dựa vào source code mới nhất + data mock, mở máy ảo iOS/Android để lấy tư liệu.

- Brief: `videos/dear-embeiu-launch-50s/BRIEF.md` — giữ nguyên 9 mục của brief gốc, đổi sản phẩm. Concept **"ONE NUMBER,
  TWO PEOPLE"**: con số đếm là mực navy (xuất hiện từ khung đầu, tích giây là nhịp phim), hai người là hai chấm rose
  (bạn) / lavender (người ấy), sản phẩm là thẻ trắng của app. 7 act: Một con số · Người ấy · Chuỗi · Một ngày · Nói
  trước · Mở rộng · Ký tên; một cú cắt cứng duy nhất ở 32,0 s.
- Mọi UI trong phim dựng lại bằng vector từ app 1.10.1 chạy trên simulator iPhone 17 + emulator Pixel 10 với cặp mock
  Thảo ♥ Tuấn (`scripts/dev-seed-promo.js`); dữ liệu trên màn hình = dữ liệu seed (1250 ngày, chuỗi 30→31, 12 ảnh, cây
  12 bông…). Mọi chuỗi lấy nguyên văn từ `app_vi.arb` / `functions/index.js` (ghi key trong `src/copy/strings.ts`).
- Giao hàng (`videos/dear-embeiu-launch-50s/out/deliver/`): `dear-embeiu-launch-50s_prores422hq.mov` (master),
  `_h264.mp4` (≥ 20 Mbps), `stems/` (nhạc + SFX), `_poster.png` (khung cuối), `.vi.srt`. Chưa commit `out/`.
- Chờ user: xem thử, duyệt. Bản 9:16 cho Threads/TikTok và bản EN chưa làm (brief để sẵn: mọi chuỗi trong một file).

### Hai bản để chọn (2026-10-15 tối, theo đánh giá 2 video tham chiếu Wellio / Spaceti)

User xem phim 50 s rồi đưa 2 video YouTube (Wellio – Pixelblue 43 s; Spaceti 100 s) để đối chiếu. Nhận xét: cả hai cho
xem app chạy liên tục có người kể, người xem hiểu app trong 10 s đầu; phim mình kể concept 20 s đầu mới thấy app. User
chốt làm cả hai bản, **không lồng tiếng, chỉ nhạc + tiếng động** (lời đọc đã sinh sẵn bằng edge-tts, để lại trong
`public/vo/`, bật lại bằng `VO_SET=film node audio/build.ts`).
- **Bản 1** — phim 50 s sửa: Act 2 (giây 4–12) dùng điện thoại app thật (Home, sheet tâm trạng, sheet trả lời, mở cả
  hai) thay cho bảng trừu tượng; tiêu đề 2–3 chữ mỗi act kiểu Spaceti (`src/story/Titles.tsx`). Giao hàng như cũ ở
  `out/deliver/dear-embeiu-launch-50s_*`.
- **Bản 2** — demo sản phẩm 45 s (`Demo` composition, `src/demo/`): điện thoại giữa khung chạy 9 clip quay thật từ
  simulator (`public/clips/`, cắt từ `scripts/film-record.sh` + mốc `[shot]`), 8 phân đoạn: mở đầu · đếm ngày · câu hỏi
  · tâm trạng · giấc ngủ · ảnh/chat/quan tâm · cây tình yêu · thẻ kết; tiêu đề + 1 chú thích mỗi đoạn; nhạc nền −18 LUFS
  + tick/click/riffle; `scripts/render-demo.sh` → `out/deliver/dear-embeiu-demo-45s.mp4` (9,3 MB) + `_preview.mp4`.
- Cả hai đã gửi Telegram (chat 6199499346). Chờ user chọn.


### Bản 1 v3 — dựng lại theo nhận xét người xem / phê bình / đạo diễn (2026-10-15 khuya)

User nhờ nhận xét phim 50 s dưới 3 góc nhìn, rồi chốt: "từ những nhận xét này, hãy sửa lại video, làm 1 video tuyệt
nhất bạn có thể". Giữ khung 7 act, cú cắt 32 s, giao hàng như cũ; dựng lại phần ruột:
- Chữ đọc được khi xem toàn màn hình trên điện thoại: câu kể chuyện 64 px, chữ phải đọc ≥ 40 px (trước đó câu mở
  34 px, lợi ích thẻ 20 px).
- Câu hỏi mỗi ngày thành khoảnh khắc chính (giây 6,5–11,5): câu hỏi 56 px, hai câu trả lời 40 px, mở cùng lúc ở giây 9.
- Thêm ảnh thật của cặp đôi (ảnh "Ghế quen ở hồ Gươm" bung ra khi Tuấn đăng ảnh).
- Một ngày từ 6:00, 6 khoảnh khắc, mỗi thẻ đọc kịp ≥ 0,9 s, không còn thẻ chồng lộ chữ cụt; widget có nhịp riêng.
- Act 5 nói một lần: "Không bảng tin. Không người lạ." thay "Không bạn bè" (dễ hiểu thành "không có bạn"); bỏ lưới
  fact lặp; "Miễn phí" chỉ còn 2 chỗ.
- Act 6 chỉ còn 8 thẻ tính năng to, lợi ích 2 dòng, đứng đủ lâu; bỏ chat, chip, dòng chạy.
- Nhạc Act 4 ấm (marimba, piano, kick nhẹ) thay nhịp bốn phách + hi-hat + lớp tiếng xì; Act 5 không còn chìm.
- Chưa làm: bản 9:16 riêng cho Threads/TikTok (xem dọc, chữ 16:9 vẫn nhỏ).

### Bản dọc 9:16, 20 giây cho Threads / TikTok / Reels (2026-10-15 khuya)

User hỏi feed dọc là cho nền tảng nào, nhận khuyến nghị rồi chốt "okay làm đi" + "làm xong tự đăng thread luôn".
Bản ngang 16:9 hiện trong feed dọc chỉ là một dải hẹp, chữ nhỏ ~5 lần. Bản dọc 1080×1920 dựng lại bố cục, không cắt
khung: câu mở (0–2 s) · câu hỏi mỗi ngày, mở khoá hai câu trả lời ở giây 6 · cắt cứng sang navy: "Không bảng tin. /
Không người lạ. / Chỉ hai người. / Miễn phí. / Không quảng cáo." · thẻ kết có `dearembeiu.com/get` (một link: iPhone mở
App Store, Android mở Google Play). Chữ kể chuyện ≥ 80 px, mọi chữ cần đọc nằm trong vùng x 80–940, y 200–1500 (tránh
nút của TikTok/Reels). Bản ngang 50 s giữ cho trang chủ và YouTube.
