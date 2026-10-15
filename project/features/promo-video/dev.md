# promo-video — Dev

## Pipeline (2026-10-15)

1. **Dữ liệu mock (DEV):** `node scripts/dev-seed-widget-accounts.js` (cặp test3/test4 = Tuấn ♥ Thảo) rồi `node scripts/dev-seed-promo.js --photos <thư mục ảnh đã grade>` — thay 12 ảnh gallery + ảnh couple, Tuấn chọn tâm trạng "Nhớ", 30 đêm ngủ cả hai (share on), câu hỏi hôm nay Tuấn đã trả lời. Chạy lại (không `--photos`) để đặt lại trạng thái Thảo trước mỗi lần quay.
2. **Robot quay:** `integration_test/promo_robot_test.dart` + `scripts/promo-record.sh <udid> <out.mp4>` (thu hình bằng `xcrun simctl io recordVideo`, không cần cửa sổ Simulator — Xcode 27 không còn app Simulator). Robot tự bỏ intro, đăng nhập test4, bật giấc ngủ (ghi tay + chia sẻ), rồi quay 3 luồng: câu hỏi → tâm trạng → giấc ngủ; in mốc `[robot] <nhãn> <epoch ms>` để cắt. Mốc video = (epoch − `[rec] start`)/1000 − (stopΔ − duration của file) — hiệu chỉnh theo thời điểm dừng, không tin số cố định.
   - Chạm/kéo gửi qua nguồn `TestBindingEventSource.device` để LiveTestWidgetsFlutterBinding không vẽ chữ thập con trỏ; `PointerMoveEvent` PHẢI có `delta` (recognizer cộng dồn delta, delta 0 = không cuộn).
   - `app.main()` bọc trong `runZonedGuarded` — lỗi async của app lọt vào zone test sẽ làm binding assert và treo tới timeout.
   - `--dart-define=PROMO_ROBOT=true` → `PushNotificationService._requestPermissionStatus` không mở hộp xin quyền iOS (test không bấm được UI hệ thống). Build thường: hằng false.
   - `flutter test` GỠ app sau mỗi lần chạy (`integration_test_device.dart:144`) → mỗi lần quay là cài mới; reveal/confetti vì thế luôn chạy lại.
3. **Cắt clip:** `scripts/promo-cut.sh <in> <start> <dur> <out> [island.png]` — 30 fps, +4% contrast, phủ Dynamic Island (378×112 ở y 33, tạo bằng ffmpeg geq). Clip câu hỏi và giấc ngủ dùng time-remap (concat 3 đoạn, đoạn giữa tăng tốc) để vừa 5.3 s.
4. **Dựng:** HyperFrames (`videos/dear-embeiu-threads-promo/`, CLI 0.8.160, workflow product-launch-video). 7 cảnh `compositions/frames/0N-*.html`, mỗi cảnh một worker. Khung điện thoại dựng tay theo toạ độ cố định (màn hình x 240 y 652 600×1304); video màn hình khai báo `data-frame-video="approved"` và được assembler hoist lên root.
   - `scripts-assemble-all.sh` = khôi phục thẻ video (`scripts-restore-videos.sh`) → assemble → transitions → `scripts-postfix-index.sh` (bo góc 88px cho video hoist) → lint. ⚠️ assemble ghi đè thẻ video trong file cảnh bằng comment; KHÔNG trả thẻ video lại file cảnh sau khi ghép (runtime sẽ render video lần 2 full khung và video hoist đứng hình).
   - Nhạc/SFX: `audio_meta.json` (bgm host + 12 SFX tự tổng hợp bằng ffmpeg ở `assets/sfx/`). Mốc cắt cảnh nằm trên phách mạnh 91 BPM: 3.40 · 7.04 · 12.31 · 17.58 · 22.86 · 26.81.
5. **Kiểm & render:** `npx hyperframes check` (0 lỗi, contrast 43/43 AA), `snapshot --at …` soát contact sheet, `preview --background` (Studio http://127.0.0.1:3002), `render --quality high --output renders/video.mp4`.

## Thay đổi trong repo app

- `pubspec.yaml`: thêm dev dep `integration_test` (SDK).
- `lib/services/push_notification_service.dart`: hằng `_promoRobot` từ dart-define, chỉ ảnh hưởng khi build robot.
- `scripts/dev-seed-promo.js`, `scripts/promo-record.sh`, `scripts/promo-cut.sh`, `integration_test/promo_robot_test.dart`.
- `videos/dear-embeiu-threads-promo/` (nguồn video; `renders/`, `.hyperframes/artifacts/`, `bgm-source.mp3` đã gitignore).

## Nợ / ý sau

- Bản 15 s (cắt câu 2 hoặc 3) và bản EN chưa làm.
- Hộp xin quyền thông báo chỉ tránh được qua dart-define; `xcrun simctl privacy` không có dịch vụ `notifications`.

## Phim ra mắt 50 s — Remotion (2026-10-15 chiều)

Thư mục `videos/dear-embeiu-launch-50s/` (có `.gitignore` riêng: `node_modules/`, `out/`, `ref/ios/`, `ref/android/`).

1. **Tư liệu:** `integration_test/film_shots_test.dart` + `scripts/film-shots.sh <ios|android> <device> <dir>` — robot đi
   qua từng màn, in mốc `[shot] <tên>`, script chụp bằng `simctl io screenshot` / `adb exec-out screencap` (37 màn iOS,
   34 màn Android). Chạy SAU `node scripts/dev-seed-promo.js`. Bẫy: emulator Android đăng nhập sẵn tài khoản khác →
   `adb uninstall com.tony.dearembeiu.dev` trước; máy đặt tiếng Anh → robot tự bấm Skip, mở nút đổi ngôn ngữ ở
   landing, chọn "Tiếng Việt"; Firebase trên Android khởi động chậm → chờ tới 40 s cho màn đầu.
2. **Seed:** màu ngủ của Tuấn đổi `blue` → `purple` (= `accentLavenderDeep`) để khớp vai màu "người ấy" của phim.
3. **Pipeline Remotion 4.0.532** chép từ `ea-studio/videos/forexailab-mot-cau-50s` (audio core/instruments/sfx kit,
   `scripts/stills.ts`) + `forexailab-launch-50s` (`render.sh`, `check-delivery.ts`, `srt.ts`). Build book `DESIGN.md`
   (engine, chủ sở hữu file, linh kiện chung, hand-off từng act, hợp đồng âm thanh, chỉ mục ảnh chụp); cue sheet
   `src/timeline/cues.ts`; chuỗi `src/copy/strings.ts`; `Film.tsx` mount đúng một act mỗi khung, act đọc khung toàn cục.
4. **Dựng:** 4 builder act + 1 nhạc + 1 SFX chạy song song (subagent), tích hợp soát still 2 vòng (vòng 1 mọi act dựng
   cỡ điện thoại, phải phóng lên cỡ 1920×1080). Nhạc: motif D5 A5 G5 F#5 E5 gõ ra theo từng từ ở Act 1, chơi trọn ở
   46,0 s; SFX 54 id, tick đồng hồ bằng gỗ. Master −14 LUFS / −1,2 dBTP, im lặng tuyệt đối 32,0–32,5 s và 49,8–50 s.
5. **Lệnh:** `npm run typecheck` · `node scripts/stills.ts <tên> <khung…> --scale=0.5` (contact sheet) ·
   `node audio/build.ts` · `bash scripts/loud.sh` · `bash scripts/render.sh` (ProRes + H.264 CBR 24 Mbps + stems +
   poster + SRT + `check-delivery.ts`).
6. **Kết quả render 2026-10-15 17:28:** `out/deliver/dear-embeiu-launch-50s_prores422hq.mov` 734 MB · `_h264.mp4` 152 MB
   (24 Mbps CBR; đường AAC qua `alimiter` −1,8 dBTP vì AAC vượt đỉnh PCM ~0,8 dB) · `_preview.mp4` 6,9 MB (bản xem nhanh,
   không phải deliverable) · `stems/` 2×14,4 MB · `_poster.png` · `.vi.srt` 40 cue. `check-delivery.ts`: tất cả đạt
   (3000 khung, 50,000 s, bt709, −14 LUFS / −1,2 dBTP). Soát: 17 still theo brief §9 + contact sheet mỗi 0,5 s.
7. **Bản demo 45 s + lời đọc (2026-10-15 tối):** `scripts/film-record.sh <udid> <out.mp4>` quay simulator trong lúc robot
   chạy (mốc `[shot] <tên> <epoch>`), `ref/rec/shots.json` → cắt clip 30 fps 1206×2622 vào `public/clips/` (index.json
   có mốc trong clip). Giọng đọc: `scripts/vo.sh film|demo` (edge-tts `vi-VN-HoaiMyNeural`, venv ở scratchpad; dịch vụ
   hay rớt → retry, mp3 hỏng < 1 KB tự xoá); `audio/vo.ts` trộn + duck −7 dB; mặc định `VO_SET=none` vì user bỏ lồng
   tiếng. Demo: `src/demo/`, `audio/demo/build.ts`, `scripts/render-demo.sh`, `scripts/check-demo.ts`. Emoji trên
   simulator vẽ thành ô "[?]" trong bản quay — builder đã che bằng chữ đúng của `app_vi.arb`; muốn sạch thì quay trên máy
   thật.

8. **Vòng sửa bản 1 theo góp ý user (2026-10-15 tối, 7 điểm):** (a) câu Act 1 → "Mọi app đếm ngày yêu chỉ biết đếm."
   (app truyền thống chỉ có mỗi việc đếm); (b) Act 3: bầu trời đêm thành thẻ trọn vẹn trong khung (x 96–1824,
   y 600–1000, bo 28) có cành cây chéo, trăng, 3 check — hết cảm giác "mất phần dưới"; tiêu đề act kết thúc ở 1050 để
   không chìm khi bầu trời phủ kín; (c) câu Act 4 → "Con số vẫn thế. Chỉ là có thêm người ấy." (bỏ "trơ trọi");
   (d) tấm navy trồi từ dưới phủ widget trong 1896–1920 (`A4.cover`) nối vào cú cắt 32 s, nhạc vẫn cắt đứt;
   (e) Act 5: lưới fact trượt xuống thành dải chữ nhỏ ở đáy tại `A5.dim` 2085 trước khi headline hiện — hết chữ đè chữ;
   (f) Act 6: chat thành panel trắng giữa khung (x 560–1360, y 280–960, header "THẢO ♥ TUẤN", 4 bubble lịch sử,
   chips 1 hàng trên panel); (g) lưới tính năng thành 8 thẻ 400×220 tint hồng/tím, vòng tròn 64 px glyph trắng, tên
   28 + lợi ích 20 (`T.a6.benefits`). SFX thêm `cover`, `scroll`, `sheet` (không còn event câm). Render lại không VO,
   gửi Telegram bản `_preview.mp4`.
9. **v3 — dựng lại theo nhận xét đạo diễn (2026-10-15 khuya):** chỉ thị chung viết ở `V3.md` (đã gộp vào BRIEF §5 +
   DESIGN §4–§7 rồi xoá). Số đếm sau Act 1 nằm ở `CORNER` (`src/story/Counter.tsx`: x 120, y 92, scale 0.32, chữ phụ tự
   mờ dưới scale 0.4). Act 2: sheet tâm trạng bỏ; câu hỏi + 2 câu trả lời to bên trái, `A2.unlock` 540. Act 3: tối đa
   2 chuyển động mỗi khung (cue A3 dời hết), chip 32 px, nhãn 28 px. Act 4: `hourAt`/`hourToFrame` qua nút (frame, giờ),
   `A4.eventFrames` 6 khoảnh khắc, `A4.photo` (ảnh 11.jpg), widget Android ngoài điện thoại. Act 5: không lưới, 3 câu +
   hai chấm + 1 dòng chữ nhỏ (`A5.dots`, `A5.fine`). Act 6: chỉ 8 thẻ 402×290. Act 7: chữ to hơn. Key cue/chuỗi cũ giữ
   lại có chú thích "v3: dead" cho audio/scripts. Nhạc Act 4 = marimba + piano + kick 1/3 + side-stick 2/4, low-pass theo
   giờ; swell Act 2 về chủ âm đúng `unlock`. SFX thêm swoop/leave/lift/sendIn/unlock/collapse/shrink/playhead/eventOut/
   photoPop/photoFly/photoLand/dotsIn. `scripts/srt.ts` viết lại theo cue mới; `audio/build.ts` đặt file đo tạm theo pid.
   Tiêu đề act 30 px.
