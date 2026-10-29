---
format: 1080x1920
duration: 30s
message: "Con số vẫn có. Chỉ là không còn trơ trọi — Dear Embeiu nhớ người ấy giúp bạn, không chỉ đếm ngày."
arc: Hook (notification) → Pain (the lonely number) → 3× question the old app can't answer / Dear Embeiu answers → Payoff (the number, not alone) → CTA
audience: Cặp đôi trẻ Việt Nam (Gen Z / đầu Millennials) đang dùng hoặc từng dùng app đếm ngày yêu
mode: autonomous
music: none
---

<!-- No narration (Threads autoplays muted). The "voiceover" field below is the ON-SCREEN TEXT CUE RAIL:
     every reveal in a frame is paced to these text cues exactly as a VO would pace it. Music is host-provided
     (audio_meta.json → bgm source: host). All on-screen copy is Vietnamese and VERBATIM — never translate,
     never paraphrase, keep diacritics. Voice rule: "chúng mình" / "người ấy", never "hai đứa". -->

## Video direction

- **Canvas** = `frame.md` atmosphere: the app's own `dawnBlush` gradient (135deg #FFC1CC → #E8B4D8 → #C8A8E9) + 1–2 soft radial glows (white 18% / rose 12%) + 3% grain, on a full-duration background clip. Frame 1 is the lone exception (a dark lock screen: a photo under a 55% navy scrim). Frame 7 may use the `sunsetRomance` hero gradient (#FF6B9D → #FF8FA3 → #FFB6C1) once.
- **Palette roles** (`frame.md`): ink #1A1A2E for every headline and body on blush; white text only on photo/dark scrims, always with a dark shadow; rose #FF4D6D = love actions + the ONE CTA button; lavender #A78BFA = "người ấy" accents; pastel candy keys = chip tints only. No ink outlines anywhere; containers are white (or white 72% + 1px white 65% hairline) with blurred soft shadows (`0 10px 16px rgba(26,26,46,0.06)`; `rgba(0,0,0,0.12)` under the phone).
- **Type**: Quicksand only (`assets/fonts/`, @font-face per `frame.md`). Headlines 700–800 sentence case; chips uppercase 600 tracked. Vietnamese diacritics must render (Quicksand covers them). Headline measure ≤ 86% of canvas width; `cqw` units.
- **Recurring device — the PHONE RIG (exact, shared by frames 3–6; every worker builds the identical rig, hand-authored, NOT the registry component):** canvas 1080×1920. Screen rect = **x 240, y 652, w 600, h 1304** (the recording is 1206×2622, same ratio) — the recording is an approved `[video]` candidate declared as `<video data-frame-video="approved" data-start="0" data-duration="<frame duration>" data-track-index="5" data-frame-video-x="240" data-frame-video-y="652" data-frame-video-width="600" data-frame-video-height="1304" data-frame-video-fit="cover" muted playsinline>`; the assembler hoists it to the host root, so the frame itself draws only the hardware around an EMPTY screen hole (no placeholder fill — leave the screen area transparent so the hoisted video shows through). Bezel 12px → phone outer rect **x 228, y 640, w 624, h 1328**, outer radius 100px, screen-corner radius 88px, body #1B1D22 with a 1px inner highlight #343740, a soft blurred shadow `0 30px 60px rgba(0,0,0,0.18)` under it. Do NOT draw a Dynamic Island in the frame — the hoisted video renders above the frame, so it would be hidden; the island is baked into the recordings themselves. The phone is **static for the whole frame** — it never rises, scales, or drifts (the hoisted video would not follow it) — every bit of life inside the screen comes from the recording. The phone bottom bleeds 48px past the canvas; that is intended.
- **Text zones around the rig (frames 3–5):** gutter 72px. Chip `CÂU n` at y 176 (height 44, left). Headline block y 236–500, left-aligned, max width 640px (it wraps to 2–3 lines; the old-card ghost sits to its right). Old-card ghost: **x 744, y 176, w 264** (height ≈ 150), 45% opacity, with `…` typed beneath it inside the card. Caption / callout pill: y 548–612 (height 64), left-aligned at x 72, max width 936 — it never overlaps the phone (phone top is 640). Frame 6: headline cue 1 centered at y ≈ 300, cue 2 centered at y ≈ 430, both within 72px gutters.
- **Recurring motif — the "app thường" card**: a deliberately bland white card (radius 24, no outline) showing `1250 ngày` (ink, 800) and one red heart `❤️` — nothing else. Full size in Frame 2; in Frames 3–5 it sits as a small dim ghost (≈ 26% canvas width, 45% opacity) top-right under the chip, and shows only `…` where an answer would be. It never animates beyond its one entrance and the `…` pulse.
- **Motion grammar**: `power3` long-tail settles everywhere (no bounce, no elastic). Reveal model = text-cue paced: at t=0 only the first cue is on screen; each later piece lands exactly on its cue in the rail; back ~50% of every frame carries at least one reveal. Holds are still — at most subtle jitter on a held hero; the phone recordings supply all the "life" in frames 3–6, so NOTHING else moves while they play.
- **Rhythm / held frames**: Frame 2 is the deliberate held beat (the bland card just sits — its stillness IS the joke). Frame 7 holds the lockup for its last 1.5s.
- **Beat grid**: music 91 BPM (0.659s/beat, 2.637s/bar); the beat enters at 4.40s of the video. Frame starts sit on downbeats: 3.40 · 7.04 · 12.31 · 17.58 · 22.86 · 26.81. Inside Frame 2 the headline slam lands exactly at 4.40s (1.0s into the frame).
- **Cuts**: hard `cut` on the downbeat for every frame boundary from 2→3 onward (3→4→5→6→7). Reason: the phone-screen recordings are hoisted to the host root and the transition injector does not carry them, so any slide/zoom/fade across those boundaries would move the hardware without its screen. The one dissolve is 1→2 (`zoom-through`, dark lock screen → blush); frames 1 and 2 carry no video. A hard cut on a 91 BPM downbeat reads as deliberate beat-cutting, not as a missing transition. Inside a frame, the chip/headline/caption reveals give each cut its motion.
- **Negative list**: no competitor UI or names; no outlines / hard-offset shadows / neobrutalist chrome; no purple-blue "AI" gradients, bokeh, stock-smiling couples; no emoji except the ones written in copy (❤️ on the bland card, 🥹 in the notification, 💞 as the app itself renders it); no English on screen; no "hai đứa"; no slideshow (front-load then freeze) and no screensaver (floating independent motion); no CSS transitions/keyframes, no repeat:-1.
- **Safe zones**: Threads chrome overlaps the bottom ~17% and the top ~6% — keep every headline/chip/CTA inside the middle band (top 8% → bottom 83%).

## Frame 1 — Một thông báo

- scene: Dark iPhone lock screen at 22:41; one Dear Embeiu notification drops in — "Tuấn đang thấy Nhớ 🥹"
- voiceover: "22:41" · "Dear Embeiu — Tuấn đang thấy Nhớ 🥹"
- duration: 3.4s
- poster: 2.4s
- transition_in: cut
- status: animated
- src: compositions/frames/01-notification.html
- type: hook
- persuasion: Curiosity gap (a private, specific signal from the partner before any product is named)
- beat: intrigue + tenderness
- blueprint: compose
- registry: notification-cascade (installed at compositions/notification-cascade.html — use its banner CSS as reference only; hand-build ONE banner)
- asset_candidates: assets/bg-lock.jpg — portrait Unsplash couple photo, used as the lock-screen wallpaper under a dark scrim; assets/app_icon.png — the app icon inside the notification banner
- focal: assets/app_icon.png
- roles: bg-lock = background (dim ~55% navy scrim, slight blur) · app_icon = cutout (inside the banner)

narrativeRole: The hook. A real-looking lock screen and a single, oddly intimate notification make the feed stop scrolling before anything is sold.
keyMessage: Someone's phone just told them how their person feels tonight.

Scene 1 (0.0–0.6s): Full-bleed lock screen — `bg-lock.jpg` under a 55% navy scrim with a faint blur, iOS-style lock clock `22:41` (white, thin, ≈ 14cqw) with the date line `Thứ Tư, 15 tháng 10` above it, upper-third; the small lock glyph above the date. Nothing else. Layered-depth: photo → scrim → clock. The clock fades in over the first 0.4s (`spring-pop-entrance`, smooth settle, from 96% scale); then still.
Scene 2 (0.6–1.6s): The notification banner (`notification-cascade` adapted to ONE card: white 85% frosted pill-card, radius 28, app icon left, title `Dear Embeiu` + grey `bây giờ` right-aligned, body `Tuấn đang thấy Nhớ 🥹`) drops in from above the clock to just under it — centered, ≈ 88% canvas width, 3 depth layers (wallpaper, scrim, card). Entrance via `spring-pop-entrance` on a long-tail settle (no overshoot); at the moment it lands the scrim darkens 10% more and the wallpaper nudges 1% scale (the "phone lit up" feel — one tiny scale tween, then locked).
Scene 3 (1.6–3.5s): Hold. The card reads still; the only life is a soft rose radial glow (8%) behind the card that fades up once over 0.6s (one opacity tween) and stays. No breathing, no drift. (The harness `zoom-through` into Frame 2 is this frame's exit.)

## Frame 2 — Rồi sao nữa?

- scene: On blush, the bland "app thường" card shows only `1250 ngày ❤️` — then the question lands: "Rồi sao nữa?"
- voiceover: "APP ĐẾM NGÀY YÊU CỦA BẠN" · "1250 ngày ❤️" · "Rồi sao nữa?" · "3 câu nó không trả lời được:"
- duration: 3.64s
- poster: 2.6s
- transition_in: zoom-through
- status: animated
- src: compositions/frames/02-roi-sao-nua.html
- type: pain_point
- persuasion: Negative contrast (the viewer's current app, reduced to the one thing it does)
- beat: mild frustration → curiosity
- blueprint: compose
- asset_candidates:
- focal: the bland card (hand-built, typographic)
- roles: none — typography + one hand-built card

narrativeRole: Sets up the whole structure: here is what a day-counter gives you — a number — and here are the three questions it will never answer.
keyMessage: A number alone is not a relationship.

Compose: the words are the motion (hard landings on beats); the "surface" is one bland card that stays dead-still on purpose.
Scene 1 (0.0–0.8s): Blush canvas + atmosphere. A tiny uppercase chip `APP ĐẾM NGÀY YÊU CỦA BẠN` (white 72% pill, ink text, tracked) fades in at the upper-third center (`spring-pop-entrance`, smooth). Below it the bland card slides UP into the center-upper area (≈ 70% canvas width, ≈ 20% height): `1250 ngày` in ink 800 ≈ 9cqw with a single `❤️` beneath — slide-up via `spring-pop-entrance` on `power3`, lands and goes STILL. Centered, 3 depth layers (canvas glow, card shadow, type).
Scene 2 (0.8–2.0s): Nothing moves for a beat (the joke: it just sits there). At exactly 1.0s (the music's first downbeat) the headline `Rồi sao nữa?` lands beneath the card — ink 800, ≈ 11cqw, `kinetic-beat-slam` single slam on a smooth settle (no overshoot); a slim rose accent-line pill scales in from its center under it (a short width tween, no rule).
Scene 3 (2.0–3.64s): The sub-line `3 câu nó không trả lời được:` (ink 600, ≈ 4.2cqw, 70% opacity) reveals via `per-word staggered reveal` (`dynamic-content-sequencing`) under the headline. Hold on the stack: chip · card · headline · sub-line, all still. Keep everything above the 83% line.

## Frame 3 — Câu 1: Người ấy hôm nay thấy sao?

- scene: Question 1 on top; the phone rises with the real Mood flow — Thảo picks "Nhớ", the card lights up "Chúng mình cùng một tâm trạng 💞"; the old card ghost shows only "…"
- voiceover: "CÂU 1" · "Người ấy hôm nay thấy sao?" · "…" · "Chúng mình cùng một tâm trạng 💞"
- duration: 5.27s
- poster: 4.2s
- transition_in: cut
- status: animated
- src: compositions/frames/03-cau-1-tam-trang.html
- type: feature_showcase
- persuasion: Show-don't-tell proof (the real screen answers the question the old app can't)
- beat: recognition → warmth
- blueprint: device-surface-showcase (Reproduce — static hold, real recording; phone rig per Video direction)
- asset_candidates: assets/screen-mood.mp4 — simulator recording: Home mood card → mood sheet → tap "Nhớ" → save → matched-mood glow (9:16 phone screen, ~5–6s)
- focal: assets/screen-mood.mp4
- roles: screen-mood = cutout (inside the phone screen slot, plays from t=0 of the frame)
- handoff_out: phone rig — outer rect x 228, y 640, w 624, h 1328, scale 1, opacity 1, static (no motion at the cut). Chip at y 176; headline block y 236–500 (left, max width 640); ghost at x 744, y 176, w 264, opacity 0.45; caption zone y 548–612.

narrativeRole: First of three proofs. Establishes the deck layout (question on top, phone below, the dead old card in the corner) that frames 4 and 5 repeat.
keyMessage: Dear Embeiu tells you how your person feels today — and when you feel the same.

Scene 1 (0.0–0.7s): Blush canvas. The chip `CÂU 1` (rose-tinted pill, white text) pops in at the top-left of the safe band (`spring-pop-entrance`); the headline `Người ấy hôm nay thấy sao?` (ink 800, ≈ 7.2cqw, 2 lines max, left-aligned, upper-third) assembles via `per-word staggered reveal` (`dynamic-content-sequencing`). Asymmetric 70/30 header, 3 depth layers.
Scene 2 (0.7–1.4s): The phone rig is ALREADY in place from t=0 (static; the hard cut brought it in) with the recording playing on its screen. In this window the old-card ghost (`1250 ngày ❤️`, 26% width, 45% opacity, radius 24) fades in top-right beside the headline, and a `…` (ink, 60%) types under it via `type-on with caret` — the old app's "answer".
Scene 3 (1.4–4.6s): Hold the stage completely still; the recording carries the beat (sheet opens, "Nhớ" tapped, card lights up). No camera move. The `…` keeps a barely visible opacity flicker (hand-tweened, finite) — the only non-video motion.
Scene 4 (4.6–5.5s): As the app's own "Chúng mình cùng một tâm trạng 💞" appears on screen, a small white caption pill `Tâm trạng hôm nay — cả hai cùng thấy` (ink 600, ≈ 3.4cqw) slides up into the caption zone (y 548–612, left, never over the screen) via `spring-pop-entrance`; a static rose radial glow (10%, plain CSS, no motion) sits behind the phone. Hold.

## Frame 4 — Câu 2: Đêm qua người ấy ngủ lúc mấy giờ?

- scene: Question 2; the same phone now shows the Sleep screen — moon calendar, then last night in two lanes; a callout pill lands: "23:10 → 06:00 · ngủ 6 giờ 50"
- voiceover: "CÂU 2" · "Đêm qua người ấy ngủ lúc mấy giờ?" · "…" · "23:10 → 06:00 · ngủ 6 giờ 50"
- duration: 5.27s
- poster: 4.9s
- transition_in: cut
- status: animated
- src: compositions/frames/04-cau-2-giac-ngu.html
- type: feature_showcase
- persuasion: Show-don't-tell proof + specificity (an exact bedtime beats any adjective)
- beat: surprise → care
- blueprint: device-surface-showcase (Reproduce — static hold, real recording; phone rig per Video direction)
- asset_candidates: assets/screen-sleep.mp4 — simulator recording: Home "Đêm qua" card → Sleep screen (moon calendar on night sky) → last-night detail in two lanes (Thảo / Tuấn), ~5–6s
- focal: assets/screen-sleep.mp4
- roles: screen-sleep = cutout (inside the phone screen slot)
- handoff_in: phone rig — outer rect x 228, y 640, w 624, h 1328, scale 1, opacity 1, static. Chip/headline/ghost/caption zones identical to Frame 3.
- handoff_out: identical to handoff_in (nothing moved).

narrativeRole: Second proof — the most unexpected one. A day counter cannot know this; Dear Embeiu does, from the phone resting by the bed.
keyMessage: You know when your person slept and woke — without asking.

Scene 1 (0.0–0.7s): Chip `CÂU 2` pops in (`spring-pop-entrance`), headline `Đêm qua người ấy ngủ lúc mấy giờ?` assembles (`per-word staggered reveal`, ≈ 7.2cqw, ≤ 2 lines). The phone rig is static from t=0 with the recording playing; the old-card ghost fades in at its fixed spot and `…` fades in beneath it.
Scene 2 (0.7–4.0s): Hold still; the recording carries (calendar → last night two lanes). Nothing else moves.
Scene 3 (4.0–5.5s): The callout pill `23:10 → 06:00 · ngủ 6 giờ 50` (white card, ink 700 ≈ 3.8cqw, a tiny lavender moon dot at left) slides in from the left into the caption zone (y 548–612), left-aligned with the headline (`spring-pop-entrance`); its `6 giờ 50` figure arrives via `value-scaled counter` (`counting-dynamic-scale`) from 0 → 6:50 in the pill. Hold.

## Frame 5 — Câu 3: Hôm nay chúng mình đã nói gì với nhau?

- scene: Question 3; the phone shows today's question — Thảo answers, both answers reveal with the app's own confetti
- voiceover: "CÂU 3" · "Hôm nay chúng mình đã nói gì với nhau?" · "…" · "Một câu hỏi mỗi ngày · mở khi cả hai đã trả lời"
- duration: 5.28s
- poster: 3.8s
- transition_in: cut
- status: animated
- src: compositions/frames/05-cau-3-cau-hoi.html
- type: feature_showcase
- persuasion: Show-don't-tell proof + reciprocity (the answer only opens when both have written)
- beat: anticipation → delight
- blueprint: device-surface-showcase (Reproduce — static hold, real recording; phone rig per Video direction)
- asset_candidates: assets/screen-dq.mp4 — simulator recording: today's question card → answer sheet → Thảo types and sends → reveal of both answers + confetti, ~5s
- focal: assets/screen-dq.mp4
- roles: screen-dq = cutout (inside the phone screen slot)
- handoff_in: identical to Frame 4 handoff_out.
- handoff_out: phone identical; chip/headline/ghost will NOT carry into Frame 6 (clean zoom-through).

narrativeRole: Third proof — the daily ritual. Also the emotional peak of the three (two answers side by side), so it sits last.
keyMessage: Every day there is one small thing you both said to each other — kept.

Scene 1 (0.0–0.7s): Chip `CÂU 3` + headline `Hôm nay chúng mình đã nói gì với nhau?` (`per-word staggered reveal`, ≈ 6.8cqw, ≤ 3 lines). Phone rig static from t=0, recording playing; the ghost fades in and `…` fades in under it.
Scene 2 (0.7–3.6s): Hold; the recording carries (type → send → reveal + confetti). Nothing else moves.
Scene 3 (3.6–5.0s): The caption pill `Một câu hỏi mỗi ngày · mở khi cả hai đã trả lời` (white, ink 600 ≈ 3.2cqw, two short lines allowed) slides up into the caption zone (`spring-pop-entrance`); the old-card ghost fades to 25% — it has given up. Hold.

## Frame 6 — Con số vẫn có

- scene: The phone shows the real Home — 1250 ngày with the hours:minutes:seconds ticking over the couple photo — and the line lands: "Con số vẫn có." … "Chỉ là không còn trơ trọi."
- voiceover: "Con số vẫn có." · "Chỉ là không còn trơ trọi."
- duration: 3.95s
- poster: 2.8s
- transition_in: cut
- status: animated
- src: compositions/frames/06-con-so-van-co.html
- type: benefit_highlight
- persuasion: Reframe (the same number, now surrounded by a living day)
- beat: relief + warmth
- blueprint: compose
- asset_candidates: assets/screen-home.mp4 — simulator recording: Home at rest, counter `1250 ngày` + GIỜ/PHÚT/GIÂY pill ticking, photo cinema behind, ~4s
- focal: assets/screen-home.mp4
- roles: screen-home = cutout (inside the phone screen slot)
- handoff_in: phone rig — outer rect x 228, y 640, w 624, h 1328, scale 1, opacity 1, static (identical to Frames 3–5); no chip, no ghost.

narrativeRole: The payoff that closes the loop opened in Frame 2: the number is still there — Dear Embeiu just gives it company.
keyMessage: Con số vẫn có. Chỉ là không còn trơ trọi.

Compose: a held hero phone (the rig) + a headline that lands in two cues, nothing else.
Scene 1 (0.0–0.8s): Blush canvas; the phone rig is static from t=0 (the hard cut brought it in) with the Home recording playing (counter ticking). No chip, no ghost. A static rose radial glow (10%, plain CSS) sits behind the phone.
Scene 2 (0.8–1.9s): Cue 1 — `Con số vẫn có.` (ink 800, ≈ 8.4cqw, centered above the phone) lands via `kinetic-beat-slam` on a smooth settle.
Scene 3 (1.9–3.5s): Cue 2 — `Chỉ là không còn trơ trọi.` (ink 700, ≈ 5.6cqw, lavender `trơ trọi` via `keyword glow`, `asr-keyword-glow` once) reveals `per-word` beneath cue 1. Hold; only the recording moves.

## Frame 7 — Dear Embeiu

- scene: Icon + wordmark lockup, "Miễn phí · App Store & Google Play", then the URL
- voiceover: "Dear Embeiu" · "Miễn phí · App Store & Google Play" · "dearembeiu.com"
- duration: 3.19s
- poster: 2.4s
- transition_in: cut
- status: animated
- src: compositions/frames/07-cta.html
- type: cta
- persuasion: Friction reduction (free, both stores, one URL)
- beat: motivation → ease
- blueprint: compose
- asset_candidates: assets/app_icon.png — the app icon, centered, ≈ 22% canvas width, radius ≈ 22% of its own width (iOS squircle)
- focal: assets/app_icon.png
- roles: app_icon = cutout (hero)

narrativeRole: The ask, as calm as the app. Free, both stores, one address to remember.
keyMessage: Tải Dear Embeiu — miễn phí.

Compose: the mark comes to exist on a cleared stage and resolves into a centered lockup + URL; no camera push-through, no letter scatter — smooth, warm.
Scene 1 (0.0–0.9s): Blush canvas with one static `sunsetRomance` radial glow behind center (14%, plain CSS). The icon spring-blooms from 0 at center-upper (`spring-pop-entrance`, smooth settle), soft blurred shadow beneath.
Scene 2 (0.9–1.8s): Wordmark `Dear Embeiu` (ink 800, ≈ 9cqw) assembles beneath the icon via `per-word staggered reveal`; a slim rose accent-line pill scales in from its center under it (short width tween, no rule).
Scene 3 (1.8–2.6s): Line `Miễn phí · App Store & Google Play` (ink 600, ≈ 3.6cqw, 75% opacity) reveals per-word.
Scene 4 (2.6–3.5s): The URL pill `dearembeiu.com` — the ONE navy #1A1A2E pill (height ≈ 52px-equivalent, white Quicksand 600 ≈ 3.4cqw) — slides up and settles (`spring-pop-entrance`); everything holds still to the end. Final frame: exit = fade the whole stack 10% over the last 0.3s is allowed (this is the last frame). Keep the pill above the 83% line.
