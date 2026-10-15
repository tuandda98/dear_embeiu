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
