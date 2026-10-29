# Dear Embeiu — 50-second launch film

Make a 50-second motion-design launch film for **Dear Embeiu** (https://dearembeiu.com). It is a free app for two paired people: a love-day counter that lives on a shared photo, and a private space the two of them fill every day — a question only revealed when both have answered, today's mood, last night's sleep, a shared album, chat, care notes, reminders and a love tree that blooms with their milestones. This is the FINAL film shown to customers on the homepage and in ads. It is not a demo, prototype, storyboard or animatic. Every frame is finished and every sound is placed. It should look like the work of a top motion designer at a big product company, using a visual idea built only for this product rather than a reused template.

> This brief reuses, section for section, the brief that produced the Forex AI Lab launch film (`~/WebstormProjects/ea-studio/videos/forexailab-launch-50s/BRIEF.md`). Only the product, the concept, the brand system and the shot list changed. Every product fact below was read from the app's source code (`lib/`, `functions/index.js`, `lib/l10n/app_vi.arb`) and from the app itself running on the iPhone 17 simulator and the Pixel 10 emulator with the mock couple seeded by `scripts/dev-seed-widget-accounts.js` + `scripts/dev-seed-promo.js` (captures in `ref/ios/` and `ref/android/`, 15/10/2026).

## 1. Product facts (use only these; invent nothing)
- Two people pair with a 6-character invite code (also as a QR code or the link `https://dearembeiu.com/get?code=XXXXXX`). Only the two paired members can see the space: no friends, no feed, no one else. Free. No ads. iOS 14+ and Android 6+. App Store (id6775165592) and Google Play (`com.tony.dearembeiu`). Vietnamese and English. Current version 1.10.1.
- Home opens on the counter card: the couple's names ("Thảo ♥ Tuấn"), the eyebrow "HAI BẠN ĐÃ BÊN NHAU", the day total ("1250" / "NGÀY"), a live clock of hours : minutes : seconds since the anniversary ("30.009 : 41 : 07" · "GIỜ · PHÚT · GIÂY", the seconds tick), the next-milestone bar ("Cột mốc 1500 ngày" · "còn 250 ngày"), the streak chip, and a couple photo from the shared album behind it all. The eyebrow chip above greets by time of day: "CHÀO BUỔI SÁNG, THẢO".
- "Hôm nay của chúng mình" — today's rituals. Each one needs both people. A heart-constellation pill counts "n/6": each person lights 3 stars — Câu hỏi · Tâm trạng · Nhắn tin.
  - Daily question ("Câu hỏi hôm nay"): one question a day for both. Your answer unlocks your partner's ("Trả lời để mở khoá câu trả lời của người ấy"; teaser "Tuấn đã trả lời rồi đó 👀"). When both have answered, the card reveals both answers — "Câu trả lời của bạn" / "Câu trả lời của Tuấn" — under "Hôm nay cả hai đã trả lời", with confetti. Reactions ❤️ 😍 😂 🥹 🔥 👍 on the partner's answer. Every revealed day goes into the journal ("NHẬT KÝ CÂU HỎI") and extends the streak ("{n} ngày kết nối · hôm nay xong rồi"; milestones 3 · 7 · 30 · 100 · 365 — "Tròn một tuần! ✨ 7 ngày liền chúng mình không lỡ nhịp nào."). Push: "{name} đã trả lời câu hỏi hôm nay 💞 / Tới lượt bạn. Trả lời xong là xem được người ấy viết gì nhé."
  - Mood ("Tâm trạng hôm nay"): a once-a-day check-in. Sheet title "Hôm nay bạn thế nào?", 8 moods — 😄 Vui · 🥰 Hạnh phúc · 🥹 Nhớ · 😌 Bình yên · 😐 Bình thường · 😪 Mệt · 😢 Buồn · 😣 Căng thẳng — an optional note (≤100, "Thêm đôi lời (không bắt buộc)"), the navy pill "Lưu tâm trạng". Both moods sit side by side (BẠN · TUẤN). Same mood → "Chúng mình cùng một tâm trạng 💞". Push: "Tâm trạng hôm nay 💗 / Tuấn đang thấy Nhớ".
  - Sleep ("Đêm qua" → "GIẤC NGỦ"): one night = bed time → wake time, read from the phone (iOS Health, Android screen events, motion) or logged by hand ("(ghi tay)"); shared only while "Chia sẻ với người ấy" is on. Two lanes (Bạn / Tuấn) on an 18h → 14h ruler, "Ngủ cùng lúc 6g 15p", "Đêm 14 → sáng 15/10", a moon calendar where the fuller the moon the longer the night (dưới 5g Trăng lưỡi liềm · 5–6g Trăng non · 6–7g Trăng bán nguyệt · 7–8g Trăng gần tròn · từ 8g Trăng tròn — "Trăng càng tròn, ngủ càng tròn giấc"), a heart on nights both slept at the same time for 7 hours or more ("Ngủ cùng lúc từ 7 tiếng"), "Giờ bên ấy" across time zones.
- Shared album ("Kỷ niệm"): both post photos with captions, masonry grid, "{name} đăng", reactions, realtime sync. Any photo can be the counter card's background ("Ảnh nền thẻ đếm") and the home-screen widget's photo. Push: "Tuấn vừa đăng ảnh mới 💞".
- Chat ("Trò chuyện", badge "CHUYỆN CỦA CHÚNG MÌNH"): private, two people, typing indicator ("đang soạn…"), sent / delivered / read. Composer placeholder "Nhắn gì đó cho người ấy…". Push: "Tin nhắn mới 💬 / Tuấn vừa nhắn cho bạn 💌".
- Care notes ("Gửi quan tâm", badge "QUAN TÂM"): a title (≤60) + a few words (≤200), six quick picks — "Nhớ quá 💕", "Uống nước nha 💧", "Ăn cơm chưa? 🍚", "Ngủ sớm nha 🌙", "Yêu nhiều lắm ❤️", "Cố lên nha 💪" (e.g. "Ăn cơm chưa? 🍚 / Nhớ ăn cơm đúng bữa, đừng bỏ bữa nha.") — delivered as a push whose text IS the note, kept in a timeline ("LỜI QUAN TÂM").
- Reminders ("Lời nhắc"): milestones every 100 days, 520, 1000, 1314, half a year ("Nửa năm yêu nhau"), yearly ("Kỷ niệm hằng năm"); your own reminders (once / daily / weekly / monthly / yearly) with the switch "Cũng nhắc người ấy" — the partner gets it in their own time zone; push "Lời nhắc từ người ấy ⏰ / Tuấn đặt lời nhắc cho bạn lúc 21:00: Uống nước nha"; lunar-calendar reminders ("Lịch âm": Mồng 1, Ngày rằm).
- Love tree ("CÂY TÌNH YÊU"): grows under a night sky with the heart constellation of today; each flower is a milestone crossed — days together, longest streak, photos ("{count} ngày bên nhau" · "Chuỗi {count} ngày" · "{count} ảnh kỷ niệm"; "{count} bông hoa đã nở"); stages from "Hạt mầm" to full bloom; "BÔNG TIẾP THEO" with progress ("{current}/{target} ngày bên nhau"), "Việc nhỏ hôm nay".
- Oẳn tù tì: a real-time rock-paper-scissors round with the partner ("Rủ người ấy một ván nhé"), both hands revealed together, history and score.
- Home-screen widget (iOS small + medium, Android 2×2 + 4×2): the counter with the couple photo, or the love tree's night sky with the heart constellation when there is no photo yet.
- The brand openly says: private (only the two paired members; delete the account inside the app), free, no ads, and "Cần cả hai" — the space only comes alive when both people are in.
- Real product-screen data (the seeded mock couple, as captured): Thảo ♥ Tuấn · anniversary 14/05/2023 → 1250 ngày on 15/10/2026 · next milestone "Cột mốc 1500 ngày · còn 250 ngày" · streak before today 30 ("Chuỗi 100 ngày · còn 70 ngày chuỗi"), after today's reveal "31 ngày kết nối · hôm nay xong rồi" · today's question "Điều nhỏ nhặt nào người ấy làm khiến bạn thấy được yêu thương?" · Tuấn's answer "Em hay để lại mẩu giấy nhỏ trong túi áo anh, mỗi lần lấy ra là cười một mình." · Thảo's answer "Anh luôn nhắn "về chưa" dù biết em về rồi" · Tuấn's mood 🥹 Nhớ with the note "Nhớ em quá, tối gọi nha" · last night: Tuấn 23:10 → 06:00 (6g 50p · Trăng bán nguyệt, his colour purple #7C5CD6), Thảo 23:45 → 07:08 (7g 23p · Trăng gần tròn, rose), "Ngủ cùng lúc 6g 15p · Tuấn ngủ trước 35p" · constellation 2/6 before Thảo's answer, 3/6 after · 12 album photos ("12 khoảnh khắc"), captions such as "Ghế quen ở hồ Gươm", "Chở em đi vòng vòng", "Đà Lạt lạnh, mà ấm", "Vũng Tàu, 5 giờ chiều" · love tree: "12 bông hoa đã nở" (day milestones 30 · 100 · 200 · 365 · 520 · 730 · 1000; streak 3 · 7 · 30; photos 1 · 10), stage full bloom, "BÔNG TIẾP THEO · 1314 ngày bên nhau · còn 64 ngày · 1250/1314", "25 ảnh kỷ niệm · còn 13 ảnh", "Chuỗi 100 ngày · còn 70 ngày chuỗi" · the chat: "Em ăn cơm chưa? 🍚" / "Em ăn rồi nè, anh thì sao?" / "Anh vừa xong, tối nay xem phim nha" / "Okii, em chọn phim nhé 😚" · Oẳn tù tì card: "Rủ người ấy một ván nhé" · "Chơi".
- Visual references: `ref/ios/*.png` (iPhone 17 simulator, app 1.10.1, mock data) and `ref/android/*.png` (Pixel 10 emulator) — references for the vector rebuild, never pixels in the film · logo = `ref/app_icon.svg` (a white heart on the Sunset Romance tile, corner radius 22.5%).
- Voice (the app's own copy rules): "chúng mình" and "người ấy", never "hai đứa"; short, warm, everyday Vietnamese; no AI clichés ("hành trình", "đột phá", "trải nghiệm tuyệt vời"…); nothing about AI (the AI-question feature is switched off).

## 2. Concept: ONE NUMBER, TWO PEOPLE
A counter app shows one number. Dear Embeiu shows the two people behind it. The film follows the number as the day fills in around it, and ends when the two people meet inside the heart.
The film uses only three materials:
- INK = the number. Navy Quicksand 700 digits and the live clock. It opens the film, it is always on screen, and its seconds tick is the film's metronome.
- THE TWO = the people. Two soft dots: rose is YOU (Thảo), lavender is THE OTHER (Tuấn) — the app's own colour roles (lavender = the partner's label). Everything that comes from the partner arrives lavender; everything you do is rose. They start apart and end inside one heart.
- PAPER = the product. The app's white cards (radius 28, soft rose shadow) on the pale ground, rebuilt as vectors; the blush and sunset gradients only where the app uses them (counter card, sheet headers, the one CTA).
Through-line: the clock tick. It opens the film (seconds ticking at f0), becomes the playhead of Act 4 (a whole day streaming past), and its last tick closes the heart around the two dots at the end.

## 3. Format & tech
- 1920×1080, 60 fps, exactly 50.00 s (3000 frames).
- Tempo locked at 120 BPM: 1 beat = 30 frames, 1 bar = 120 frames, 25 bars in total. Every act boundary lands on a downbeat, and every key motion lands on a beat or an 8th note. The clock's second = 2 beats.
- Build in code (Remotion) so animation is frame-accurate to the audio.
- Rebuild all UI as vectors from the `ref/` captures and the source code. No screenshots and no screen recordings in the film. Photos inside the rebuilt UI are the mock couple's album (Unsplash License, `ref/photos/`), nothing else.
- Audio: 48 kHz/24-bit stereo, −14 LUFS integrated, −1 dBTP.
- Deliver: H.264 MP4 (≥ 20 Mbps), ProRes 422 HQ master, music and SFX stems, a poster PNG (last frame), and an SRT of the on-screen text.
- On-screen language: Vietnamese. Keep all strings in one file so an English version can be rendered from the app's `app_en.arb`.

## 4. Brand system (taken from `lib/theme/app_colors.dart` + `app_theme.dart`; use these exact values)
- Ground #FAFAFC · section tint #F5F0F5 · card #FFFFFF.
- Gradients: Sunset Romance #FF6B9D → #FF8FA3 → #FFB6C1 (the counter card, the icon tile) · Dawn Blush #FFC1CC → #E8B4D8 → #C8A8E9 (the Home/Auth background, sheet headers) · Dreamy Mint #FFD6E0 → #E0D4F7 → #C6E5D9 (gallery, milestones).
- Ink #1A1A2E (this is also the app's "black") · secondary #6B6B7B · tertiary #A0A0B0 · on a gradient or photo: #FFFFFF with a soft dark shadow, never a halo.
- Rose #FF4D6D = love actions, YOU, the one CTA · deep #E63956 · lavender #A78BFA = THE OTHER · deep #7C5CD6. Success #66BB6A and error #EF5350 only for status.
- Type: Quicksand (the bundled static TTFs, 300–700; weight 800 = the Bold file). Headlines 700 sentence case, tracking −0.01em; chips 600 UPPERCASE +0.1em; UI 500/600; numbers 700. Quicksand has no tabular figures: every rolling number sits in fixed digit boxes.
- Shapes: card radius 28 · input 20 · pill 999 · the primary button is a navy #1A1A2E pill with white 15/600 text · shadows soft rose rgba(255,107,157,.12) blur 24 y 8 · no outlines, no hard shadows.
- House easing: cubic-bezier(.215,.61,.355,1) (Curves.easeOutCubic — the app's `AppMotion.curve`, 200–320 ms). Physical objects use critically damped springs with at most one small overshoot.
- Grid: 12 columns, 120px outer margins, left-aligned text. Only the end card is centered.
- The phone: an iPhone-shaped vector frame (screen 402×874 pt, Dynamic Island, radius 55 pt) drawn at 1.1× when it is the hero and 0.72× when it stands beside text.

## 5. Shot-by-shot script (s = seconds, f = frames)

v3 (15/10/2026, after a viewer / critic / director review of the first cut): every line the story needs reads full-screen on a phone (story captions 64 px, anything the viewer must read ≥ 40 px), the daily question is the hero beat, the couple's own photo appears, nothing is said twice, at most two things move at once, and nothing is ever half-covered.

### ACT 1 · "Một con số" (0.0–4.0 s · bars 1–2 · f 0–239)
- f0: no fade from black. On the #FAFAFC ground, the counter is already alive at the left third: "1250" (Quicksand 700, 320px, navy) with "NGÀY" under it and the live clock "30.009 : 41 : 07" (GIỜ · PHÚT · GIÂY); the seconds tick on beats 1 and 3 of every bar. Above it the eyebrow "HAI BẠN ĐÃ BÊN NHAU" (28px). The clock is this film's caret.
- 0.3–1.75 s: the hook types in under the clock, fast (2–3 f between letters, one word every 12 f): **"Mọi app đếm ngày yêu chỉ biết đếm."** (Quicksand 700, 64px, y 860). It is complete by 1.75 s and holds — the line reads before anything moves.
- Camera: almost invisible push-in, 100% → 104%.
- 3.5 s: the clock waits one beat. 4.0 s: a lavender dot drops in from the top edge and lands beside the number — the partner arrives (the "Enter").
- Sound:
  - Room tone; the clock's tick is a soft wood tick, nothing electronic.
  - Each finished word plays one note of the film's motif (felt piano + soft marimba), so the theme is literally typed; the last note hangs until the landing.
  - The landing = a deep soft "thock" + a D1 sub pulse + the first kick.

### ACT 2 · "Người ấy" (4.0–12.0 s · bars 3–6 · f 240–719) — the hero beat
- 4.0–5.0: the number steps back into the top-left corner (scale 0.32, 70%; its small labels fade out) and stays there, small, through Act 4. The lavender dot swoops into the avatar of a large notification card: "Tâm trạng hôm nay 💗" / "Tuấn đang thấy Nhớ" / "bây giờ" (40 / 36 / 28px). The phone (the real Home, ≈ 840px tall) rises at the right: the counter card over the couple's photo, then the page scrolls down to today's question.
- 6.5–7.4: the notification leaves; the question card lifts out of the phone into the left column at hero scale: **"Điều nhỏ nhặt nào người ấy làm khiến bạn thấy được yêu thương?"** (56px). Under it two answer cards: Tuấn's (lavender edge) locked — his words redacted under "🔒 Tuấn đã trả lời rồi đó 👀"; yours (rose edge) empty with a caret.
- 7.5–8.7: your answer types in (40px): "Anh luôn nhắn "về chưa" dù biết em về rồi"; the navy "Gửi" pill unfolds and is pressed.
- 9.0: UNLOCK — both answers open at the same instant; his line unmasks: "Em hay để lại mẩu giấy nhỏ trong túi áo anh, mỗi lần lấy ra là cười một mình." Both edges glow once.
- 9.25: caption (64px): **"Cần cả hai."** The phone's card shows both answers too. Everything holds until 11.5, then compresses into Act 3's first streak cell.
- Sound (bed "Paper"):
  - Muted plucked ostinato in 8ths, D major; brushed side-stick on beats 2 and 4.
  - A suspended swell (no third) rises from 8.0 and resolves on the unlock, where the major third lands.
  - The unlock itself: a paper wipe and a breathing glass D5 — intimate, no ping, no "win".
  - Tiny digit clicks for the typing; "Gửi" = rubber dome + an air-pop.

### ACT 3 · "Chuỗi" (12.0–20.0 s · bars 7–10 · f 720–1199)
- 12.0–13.8: the two revealed answers compress into one filled cell on a calendar strip; the strip extends to the right, cells arriving every 3 frames while the count rolls in digit boxes to the real streak, and a thin navy flame glyph draws above it. Cells + flame = the streak chip ("31 ngày kết nối · hôm nay xong rồi", 32px). The streak is earned here, not stamped on.
- 13.2–16.3: the love tree's night sky rises as a complete card inside the frame (x 96–1824, y 600–1000, radius 28). Its branch climbs in ruled STEPS, one node per 8th; three ruled rows tick in, each check drawing itself (the last milestone of each flower kind the couple has crossed): ✓ 1000 ngày bên nhau · ✓ Chuỗi 30 ngày · ✓ 10 ảnh kỷ niệm. Three flowers open on the top nodes.
- 16.75–20.0: the chip collapses into a point where the two dots are born; the card grows into the whole night; the dots rise to the top; today's heart constellation (6 stars, 3 rose, 3 lavender, labelled Câu hỏi · Tâm trạng · Nhắn tin at 28px) draws between them and resolves into the app's white heart; the sunset tile fills behind it with one light sweep. The label types in (28px): "CÂY TÌNH YÊU · 12 bông hoa đã nở". Never more than two things move at once.
- Sound (bed "Garden"):
  - A glass tone per day cell, tuned to D; a soft wood tick per stem node.
  - Three rising chimes, D–F#–A, one per check; a filtered riser into the night.
  - Granular shimmer in key during the bloom.
  - 20.0: one glass "ting" + a low boom as the heart sets.

### ACT 4 · "Một ngày" (20.0–32.0 s · bars 11–16 · f 1200–1919)
- 20.0–21.6: the heart tile and its label hold while the phone rises at the left (hero scale) showing the real Home rebuilt as vectors; then the tile shrinks away in place. The two dots descend into the playhead — a short rose-over-lavender needle standing on a 24-hour ruler that streams in from the right. Label: "HÔM NAY · 15/10/2026".
- 21.6–28.0: the day runs 06:00 → 24:00 — fast between moments, slow at them. Six moments, ONE large card at a time (title 40px, body 30px; a lavender edge when it comes from Tuấn, rose when it is you), each readable for at least 0.9 s; the previous card leaves completely into its dot on the ruler:
  06:00 ☾ "Tuấn dậy · 6g 50p / 23:10 → 6:00" · 10:40 📷 "Tuấn vừa đăng ảnh mới 💞 / Ghế quen ở hồ Gươm" — the photo itself (the couple on a bench by the lake) pops out as a print and flies into the phone · 12:30 💌 "Ăn cơm chưa? 🍚 / Nhớ ăn cơm đúng bữa, đừng bỏ bữa nha." · 15:30 (rose) "Hôm nay cả hai đã trả lời 💞 / 31 ngày kết nối" · 22:45 (rose) "Chúng mình cùng một tâm trạng 💞 / Bạn và Tuấn đều thấy Nhớ 🥹" · 23:10 ☾ "Tuấn đi ngủ / 23:10".
  - Counters roll in digit boxes under the ruler: Ảnh 11 → 12 (as the print lands) · Sao hôm nay 2 → 6 · Chuỗi 30 → 31. Never a chart, never money.
- 28.0: the playhead stops with a 4 f overshoot and the counters lock. Caption (Quicksand 700, 64px): **"Con số vẫn thế. Chỉ là có thêm người ấy."**
- 29.0–31.6: delivery, on its own beat. The counter card lifts off the phone while its screen wipes to a rebuilt iOS home screen; the medium widget lands (couple photo, "1250 ngày bên nhau", the lavender milestone bar), then the small one; then the Android 2×2 widget lands beside the phone, large (night sky + the heart constellation, "1250 ngày bên nhau").
- 31.6–32.0: a navy sheet rises from the bottom over everything. 32.0: HARD CUT.
- Sound (bed "Day"):
  - Warm, not a tech groove: marimba 8ths, a felt-piano chord per bar, a muted bass in half notes, a soft kick on 1 and 3, side-stick on 2 and 4. A low-pass opens with the hour.
  - SONIFICATION: each moment = one short pluck; pitch follows the hour (D-major pentatonic); lavender moments sit a fifth below rose ones.
  - The print: a pop, a short flutter, a soft set-down. Counters = very quiet mechanical micro-ticks.
  - 28.0: tape-stop + stamp. Widgets land with a soft thunk + a short ping.
  - The music cuts dead at 32.0 with no reverb tail.

### ACT 5 · "Nói trước" (32.0–38.0 s · bars 17–19 · f 1920–2279)
- 32.0–32.5: 30 frames of pure #1A1A2E (the app's black) and true digital silence. This is the most confident moment of the film.
- Three headlines, white, 96px, each said once, left-aligned:
  - 32.6: **"Không bảng tin. Không người lạ."**
  - 34.0: **"Chỉ hai người."** — the two dots (rose, lavender) glide in from the frame edges and come to rest just after it.
  - 35.5: **"Miễn phí. Không quảng cáo."**, with "Không quảng cáo." in rose.
- 36.2: one fine-print line, 26px, white at 60%: "Ghép đôi bằng mã mời · Xoá tài khoản ngay trong app · Tiếng Việt · English".
- Sound:
  - A felt-piano D2 enters with the first line over a soft D–A drone; the D-major pad swell starts on "Chỉ hai người." (the first full major colour since the bloom, signalling trust); D2 is struck again on the third line.
  - Each line lands with the same soft typeset click; the dots = two converging breaths and two small ticks. Plainness is the message.

### ACT 6 · "Mở rộng" (38.0–44.0 s · bars 20–22 · f 2280–2639)
- 38.0–38.5: a light sheet rises from the bottom edge over the navy (radius 28 on its top corners).
- 38.5–40.25: the 8 things the two of you do here land one per 8th note, as a 4×2 grid of tinted cards (402×290, rose #FFF1F4 / lavender #F3EFFD alternating): a 72px rose/lavender circle carrying a white glyph that animates once (1 s), the name (40px) and a two-line benefit (28px):
  - Đếm ngày yêu — "tới từng giây, trên ảnh chúng mình" · digits ticking in a box
  - Ảnh chung — "cả hai cùng đăng, chỉ hai người thấy" · two frames overlapping
  - Câu hỏi mỗi ngày — "trả lời xong mới mở câu của người ấy" · two bubbles with a lock that opens
  - Tâm trạng — "cùng một tâm trạng là app báo ngay" · a face that smiles
  - Giấc ngủ — "đêm qua người ấy ngủ lúc mấy giờ" · a moon filling
  - Trò chuyện — "chỉ hai người nhắn, thấy cả lúc đang soạn" · a bubble with three dots
  - Lời nhắc — "nhắc cả người ấy, đúng giờ bên ấy" · a bell swinging once
  - Oẳn tù tì — "một ván với người ấy, hai tay mở cùng lúc" · three strokes ✌️ ✊ ✋
- 40.25–42.7: the cards hold — long enough to read them.
- 42.7–44.0: the two dots enter from the frame edges; everything recedes into them while they travel to the center.
- Sound (bed "Range"):
  - Lighter and wider: claps on 2 and 4, a plucked arp an octave up, the bass returns.
  - Each card = a paper set-down, then its own micro-sound from ONE coherent kit (wood, glass, paper, rubber, metal tick…), and one climbing marimba note.
  - IV – ii – V into the touch at 44.0.

### ACT 7 · "Ký tên" (44.0–50.0 s · bars 23–25 · f 2640–2999)
- 44.0–46.0: the two dots touch. The heart path (the app icon's heart) draws around them (stroke draw, 45 f) and fills white; the sunset tile fills behind it; the wordmark "Dear Embeiu" (Quicksand 700) slides out from behind the mark under a mask. Lock-up on the downbeat at 46.0.
- 46.0–48.0: **"Đếm ngày yêu."** (navy) / **"Và mọi thứ sau con số."** (rose) — 56px.
- 48.0–49.5: **"Miễn phí · App Store & Google Play"** (34px) + a navy pill "dearembeiu.com".
- Legal line, 22px #6B6B7B, on screen from 46.0 to the end: "Chỉ hai người đã ghép đôi xem được dữ liệu của nhau. iOS 14 trở lên · Android 6 trở lên."
- 49.5–50.0: everything holds. The last frame is a clean poster.
- Sound (bed "Resolve"):
  - The full arrangement for one bar, then the Act 1 motif played COMPLETE for the first time, harmonized in D major.
  - Logo lock = one glass "ting" + a soft sub boom.
  - The final chord fades out by 49.8; 0.2 s of silence.

## 6. Music rules
- ONE original score, not five stitched tracks: D with a minor shadow in Act 1 (the lonely number) → D major from the moment the partner arrives, 120 BPM. The 5-note motif is typed in Act 1.
- The instrumentation changes per act (Clock → Paper → Garden → Day → Silence → Range → Resolve), and every change lands on a downbeat with no mushy crossfades.
- Music sits about 6 dB under the hero SFX moments.
- Source: compose and synthesize it in code (the previous film's `audio/` kit), or use music licensed for commercial ads. Never leave silent placeholders.
- No "inspiring corporate" ukulele/piano, no trailer braams, no generic riser-then-impact, no lo-fi loop under everything.

## 7. Motion craft rules
1. Nothing appears by opacity fade alone. Every element enters for a reason: typed, stroke-drawn, pulled by a leader line, dropped, parsed, unfolded or masked.
2. One continuous virtual camera. EXACTLY ONE hard cut in the whole film, at 32.0. Everything else is a match transition.
3. Overlap actions: the next one starts 4–8 f before the previous one settles. No dead pauses except the planned silence.
4. Motion blur by sub-frame sampling (180° shutter) on anything moving faster than 20 px/frame. Static text stays perfectly crisp and pixel-snapped.
5. Captions are at most two short sentences (≤ 10 words), 64px, and hold still for at least max(1.5 s, 0.3 s per word). Never bounce or scale letters.
6. Hairlines are exactly 1px. Strict colour roles: rose = you / love actions, lavender = the other, navy = the number and the product's words, gradients only where the app has them.
7. 2.5D parallax with at most 3 layers. No fake 3D tilting of UI cards.
8. Every SFX lands within ±1 frame of its visual event.
9. At most two elements move at once; nothing travels across text that is being read; a card that is replaced leaves completely (never half-covered, never clipped words peeking out).
10. Type floor: story lines ≥ 56px, anything the viewer must read ≥ 40px, secondary ≥ 28px, fine print ≥ 22px; contrast ≥ 4.5:1 under 40px. Product UI inside the phone may be small only while the same content is also shown large outside it.

## 8. Banned
- AI-slop clichés:
  - floating glass cards tilted in 3D with glow
  - purple/blue gradient mesh blobs, bokeh, lens flares, particle bursts
  - neon grids, synthwave, globes with arcs, robots, brains, circuit boards
  - stock couples smiling at the camera, heart confetti rain (the product's own confetti burst in the reveal is the one exception)
  - glitch/RGB-split transitions, word-by-word scale-in kinetic type, a whoosh on every transition
  - "Introducing…", "Meet…", "Hành trình…", "Trong kỷ nguyên số…"
- Compliance:
  - no invented numbers, no user counts, no star ratings, no fake testimonials
  - no competitor names (say "app đếm ngày yêu")
  - no Apple or Google logos (write "App Store" / "Google Play" as text only)
  - nothing about AI
  - "hai đứa" is forbidden; the voice is "chúng mình" / "người ấy"

## 9. Definition of done
- Exactly 3000 frames at 1920×1080 / 60 fps. Every Vietnamese diacritic renders correctly (check ỗ ợ ả ữ ẫ, and the stacked ấ ề ộ of "Chúng mình cùng một tâm trạng").
- All copy matches section 1 and 5 exactly, with no lorem or placeholders.
- Export stills at f 0, 120, 240, 420, 540, 600, 720, 900, 1020, 1100, 1200, 1294, 1380, 1560, 1700, 1880, 1920, 1960, 2050, 2150, 2280, 2420, 2560, 2640, 2880 and 2999. Critique each one like a design review: alignment to the grid, spacing, contrast (≥ 4.5:1 for small text), no orphaned words. Fix, then re-render.
- Watch the full film with sound twice. Check sync, loudness, and that no section reads like a template.
