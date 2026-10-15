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
