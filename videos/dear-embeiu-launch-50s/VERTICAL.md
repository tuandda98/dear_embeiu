# The 9:16 cut — 20 s for social feeds (composition `Vertical`)

Why: Threads, TikTok, Instagram/Facebook Reels and YouTube Shorts play video full-height on a phone held upright; the
16:9 film shows there as a thin strip with its type ~5× too small. This cut is built for that phone, sound off: the
film's hook, its hero beat (the daily question opening for both at once), its trust line, its sign-off. 20 s.

## Fixed

- 1080×1920, 60 fps, 1200 frames (20.0 s), 120 BPM (beat 30 f, bar 120 f). `src/vertical/timeline.ts`: `VERT`, `VS`,
  `VSILENCE`, `SAFE`.
- Sections: **V1 hook** 0–120 · **V2 the question** 120–600 · **HARD CUT at 600** (music dead, 600–615 digital
  silence) · **V3 said up front** 600–900 · **V4 sign-off** 900–1200. The last 10 frames are digital zero.
- Same brand, materials and motion language as the film (BRIEF §4, §7; DESIGN §4): ink = the number and the product's
  words, rose = you, lavender = Tuấn, house ease, `settle`, `<Blur>` only while > 20 px/frame, no opacity-only
  entrances, at most two things moving at once, nothing ever half-covered, a line holds still max(1 s, 0.3 s/word).
- Strings: the film's `T` (reuse by reference: `T.a1`, `T.a2`, `T.a5`, `T.a7`, `T.couple`); new ones only in your
  sub-block `T.vertical.v12` / `T.vertical.v34`. Never inline a Vietnamese literal.
- Owners: V1–V2 → `src/vertical/v12/*` (export the `V12` component and `V12_EVENTS`); V3–V4 → `src/vertical/v34/*`
  (`V34`, `V34_EVENTS`). Main thread: `src/vertical/{Vertical.tsx,timeline.ts}`, `src/Root.tsx`, `scripts/*`, this file.
  Audio agent: `audio/vertical/*`. Do not edit the film's acts (`src/acts/*`): import what takes props; copy into your
  folder (with a comment naming the source) only what hardcodes 1920×1080 geometry.
- Events: `{ f, id, data? }`, frame-exact, every sound-worthy moment (the audio is built from them).

## Safe area and type (the frame shows at ≈ 0.36× on a 393 pt wide phone)

- Everything that must be read inside x 80–940, y 200–1500 (`SAFE`): TikTok/Reels put buttons on the right edge and
  captions at the bottom. Decoration may bleed outside.
- Story lines ≥ 84 px (≈ 30 pt) · anything the viewer must read ≥ 52 px · secondary ≥ 40 px · fine print ≥ 32 px ·
  contrast ≥ 4.5:1 (large bold rose on white is fine at ≥ 3:1).

## V1 · hook · 0–120

- f0, no fade: the counter alive at the left (x 80): the eyebrow "HAI BẠN ĐÃ BÊN NHAU" (36 px), "1250" (≈ 300 px), "NGÀY",
  the clock (≈ 60 px, the film's `clockAt` — it ticks on beats 1 and 3).
- ≈ 10–75: the hook types under it on two lines, 84 px, 700: "Mọi app đếm ngày yêu" / "chỉ biết đếm." (rose caret as
  the film). Complete by 75; it holds.
- 102–120: the lavender dot drops in from the top edge and lands beside the number on 120 (the film's settle drop).

## V2 · the question · 120–600 — the hero

- 120–170: the number steps back into a small top-left corner block while the hook drops out of its mask; the dot swoops
  into the avatar of a large notification card at the top: "Tâm trạng hôm nay 💗" / "Tuấn đang thấy Nhớ" / "bây giờ"
  (title 52, body 46, time 36).
- Meanwhile the real Home phone (the film's Act 2 rebuild) rises from the bottom, centred, ≈ 1100 px tall: the counter
  card on photo 03, then it scrolls to today's question card.
- ≈ 230: the notification leaves completely; the question card lifts out of the phone into the upper half: the question
  at 64 px (≤ 3 lines) "Điều nhỏ nhặt nào người ấy làm khiến bạn thấy được yêu thương?"; under it two answer cards,
  x 80–1000 — Tuấn's (lavender edge) locked: his words redacted under "🔒 Tuấn đã trả lời rồi đó 👀" (44 px); yours
  (rose edge) empty with a caret. The phone sinks to the bottom (only its top visible under the cards) or leaves —
  never overlapping the cards.
- ≈ 270–330: your answer types into your card at 52 px: "Anh luôn nhắn "về chưa" dù biết em về rồi"; the "Gửi" pill
  ≈ 340 (pressed).
- **360 UNLOCK (6.0 s):** both answers open at the same instant; his line (52 px) unmasks: "Em hay để lại mẩu giấy nhỏ
  trong túi áo anh, mỗi lần lấy ra là cười một mình." Both edges glow once. Event `unlock`.
- ≈ 375: the caption "Cần cả hai." at 96 px under the cards.
- Hold to 599 (≈ 4 s to read). 600 is a hard cut to pure navy (V3's first frame): no transition.

## V3 · said up front · 600–900

- 600–615 pure `C.ink`, digital silence.
- Five short lines, white, 104 px, weight 700, at x 80, stacked from y ≈ 560 (pitch ≈ 132), typeset in place like the
  film's Act 5: "Không bảng tin." (≈ 620) · "Không người lạ." (≈ 650) · "Chỉ hai người." (≈ 700) — then the two dots
  (rose, lavender, r ≈ 18) glide in from the left/right frame edges and rest just after it · "Miễn phí." (≈ 770) ·
  "Không quảng cáo." (≈ 800, rose). Hold to 900.

## V4 · sign-off · 900–1200

- 900–930: the light `C.bg` sheet rises from the bottom edge (radius 28 top corners) and covers the navy; the two dots
  ride it and travel to the centre (x 540, y ≈ 760), touching by ≈ 960.
- ≈ 960–1020: the heart draws around them, fills white, the sunset tile (≈ 380 px) fills behind; 1020 lock: the
  wordmark "Dear Embeiu" (96 px) slides out from behind the tile under a mask.
- ≈ 1050 "Đếm ngày yêu." (64 px, navy) · ≈ 1080 "Và mọi thứ sau con số." (64 px, rose).
- ≈ 1110 "Miễn phí · App Store & Google Play" (44 px, `C.ink2`) · ≈ 1125 the navy pill `T.vertical.v34.url`
  "dearembeiu.com/get" (40 px text).
- Hold to 1199; the last frame is the poster. Everything inside `SAFE`.

## Audio (after the picture lands)

`audio/vertical/build.ts` → `out/audio/vertical-master.wav` (+ stems `vertical-music.wav`, `vertical-sfx.wav`): one short
score in the film's language — Clock (D pedal, the motif typed by the hook's words) → Paper (plucked 8ths, side-stick
2 and 4, a suspended swell resolving on `unlock`) → dead cut at 600, 600–615 digital zero → a felt-piano D2 + a soft D–A
drone, the D-major swell on "Chỉ hai người." → Resolve (the motif complete at the lock, ting + sub boom) → the final
chord gone by 1190, 1190–1200 digital zero. SFX from the film's kit on `V12_EVENTS` / `V34_EVENTS`. Master −14 LUFS,
true peak ≤ −1 dBTP.

## Deliverables

`bash scripts/render-vertical.sh` → `out/deliver/dear-embeiu-vertical-20s.mp4` (H.264 CRF 16, AAC 256k) ·
`_threads.mp4` (≤ 9.5 MB, for upload through the browser) · `_poster.png`; `node scripts/check-vertical.ts` checks
1200 frames · 20.000 s · 1080×1920 · 60 fps · −14 LUFS ± 0.1 · ≤ −1 dBTP.
