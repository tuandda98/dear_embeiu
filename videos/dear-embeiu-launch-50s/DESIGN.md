# Dear Embeiu — launch film · build book

`BRIEF.md` is the law. This file adds the decisions, contracts and tools every builder shares.
When this file and the brief disagree, this file records a decision that was made deliberately (reason given).

## 1. Engine

- Remotion 4.0.532, composition `Film` 1920×1080, 60 fps, 3000 frames (`src/Root.tsx`).
- `src/Film.tsx` mounts exactly ONE act per frame: the act whose `[from, to)` (`ACTS` in `src/timeline/grid.ts`) contains
  it. Acts read the GLOBAL frame with `useCurrentFrame()` (no `<Sequence>` offsets anywhere).
- Every pixel is a pure function of the frame. No `Math.random()`, no `Date`, no state carried between frames (Remotion
  renders frames out of order in several tabs). Randomness: `rng(seed)` in `src/lib/rand.ts`.
- Node 25 runs the `.ts` timeline modules directly (type stripping): import with the `.ts`/`.tsx` extension, no `enum`,
  no `namespace`, no parameter properties. Anything a Node script imports (`audio/`, `scripts/`) must be plain `.ts`
  (never `.tsx`): put shared helpers in `src/lib/*.ts` and re-export them from the component.
- `npm run typecheck` must stay clean. No new npm packages. Available: `remotion`, `@remotion/fonts`,
  `@remotion/layout-utils` (`measureText` — the fonts are loaded before any act mounts).
- Fonts: Quicksand 300–700 (+ 800 = Bold) from `public/fonts/`, loaded by `src/lib/fonts.ts`; `Film` mounts an act only
  once they resolve. Emoji in copy (💞 🥹 💗 …) render with the system colour emoji font — keep them, they are the
  product's own copy; never draw an emoji as a vector.

## 2. Files and owners

| Owner | Files (create anything else you need under your own folder) |
|---|---|
| Integrator | `BRIEF.md`, `DESIGN.md`, `src/{Film,Root,index}.tsx`, `src/lib/*`, `src/components/*`, `src/story/*`, `src/copy/strings.ts`*, `src/timeline/*`, `audio/{core,build,events}.ts`, `scripts/*` |
| Acts 1–2 | `src/acts/Act1.tsx`, `src/acts/Act2.tsx`, `src/acts/a1/*`, `src/acts/a2/*` (events: `src/acts/a1/events.ts` → `A1_EVENTS`, `a2/events.ts` → `A2_EVENTS`) |
| Act 3 | `src/acts/Act3.tsx`, `src/acts/a3/*` (`A3_EVENTS`) |
| Act 4 | `src/acts/Act4.tsx`, `src/acts/a4/*` (`A4_EVENTS`) |
| Acts 5–7 | `src/acts/Act5.tsx`, `Act6.tsx`, `Act7.tsx`, `src/acts/a5/*`, `a6/*`, `a7/*` (`A5_EVENTS`, `A6_EVENTS`, `A7_EVENTS`) |
| Music | `audio/music/score.ts` (+ anything under `audio/music/`) → `out/audio/music.wav` |
| SFX | `audio/sfx/build.ts` (+ anything under `audio/sfx/`) → `out/audio/sfx.wav` |

\* `src/copy/strings.ts`: an act builder may edit ONLY its own `aN` block, with a precise Edit (never rewrite the file).
Every string must come from BRIEF §1/§5 or the product (`lib/l10n/app_vi.arb`, `functions/index.js`, the captures in
`ref/`). Invent nothing; never type a Vietnamese string literal inside an act — read it from `T`.

Never edit another owner's file. If you need something from one, say so in your final report. The cue sheet
(`src/timeline/cues.ts`) is shared: you may edit ONLY your act's block, with a precise Edit, and say what moved.

## 3. Shared tools

- `src/timeline/grid.ts` — `FPS 60, BEAT 30, BAR 120, EIGHTH 15, TOTAL 3000`, `ACTS`, `sec(s)`, `bar(n)`.
- `src/timeline/cues.ts` — THE CUE SHEET: `A1…A7`, plus `hourAt(f)` / `hourToFrame(h)` for Act 4's speed ramp. Animate
  from these constants; the sound is built from the same ones.
- `src/timeline/typing.ts` — `schedule(units, ends, {seed, minGap, maxGap})` (each unit's last letter lands on its end
  frame; 2–4 f between letters), `typed(keys, f)`, `typedCount`, `even(text, from, to)`.
- `src/copy/strings.ts` — `T` (every string) and `LANG`.
- `src/lib/tokens.ts` — colours `C` (by role), `gradient(stops)`, `GRID`, `colX(i)` (left edge of column i, 0-based),
  `colW(n)`, `HEAD`, `CHIP`, `RADIUS`, `PHONE`, `DIGIT_EM`, `FONT`.
- `src/lib/ease.ts` — `HOUSE` (the app's easeOutCubic), `ease(f, from, to)`, `lerp`, `settle(f, from, {zeta})`
  (damped spring; zeta 1 = critically damped, 0.7–0.8 = the one small overshoot allowed), `press(f, at)`
  (1 → 0.96 → 1, 6 f / 10 f), `blink(f)` (30 f on / 30 f off, beat-locked).
- `src/lib/num.ts` — `roll(from, to, f, f0, f1)`, `group(30009) → "30.009"`, `pad2`.
- `src/components/Digits.tsx` — `<Digits value size weight color />`: numbers in fixed boxes (Quicksand has no tabular
  figures); `digitsWidth(value, size)`.
- `src/components/Phone.tsx` — `<Phone x y scale>` (the iPhone-shaped vector frame; children = screen content in a
  402×874 box), `<StatusBar dark />`.
- `src/components/Card.tsx` — `<Card>` (white, radius 28, soft rose shadow), `<Chip text>` (the app's EyebrowChip),
  `<Pill text scale bg color>` (the navy primary button; pass `scale={press(f, at)}` for the press).
- `src/components/Dot.tsx` — `<Dot x y r who="you"|"other" />`: THE TWO. `x, y` is the dot's centre.
- `src/components/Heart.tsx` — `<Heart x y size draw fill tile />`: the app icon's heart (`HEART_PATH`, viewBox 1024)
  with stroke-draw, white fill and the sunset tile (`TILE`). `x, y` is the tile's centre.
- `src/components/Text.tsx` — `<Caption text x y size wipe />` (film captions enter by a left→right mask wipe),
  `<Head>` (display type), `<Caret x y h f color />` (blinking, beat-locked).
- `src/components/Sky.tsx` — the love tree's night sky with a seeded star field.
- `src/components/Blur.tsx` — 180° shutter motion blur by sub-frame sampling, centred on the frame. Children must call
  `useCurrentFrame()` themselves. Wrap ONLY what moves faster than 20 px/frame, only while it does.
- `src/story/Counter.tsx` — THE NUMBER: `<Counter x y scale f />` (eyebrow, "1250", "NGÀY", the ticking clock),
  `COUNTER` (geometry, hero placement), `COUNTER_DOT` (where the dot lands), `clockAt(f)`.
- `public/photos/01–12.jpg` — the mock couple's album (Unsplash License; `manifest.json` has the photographers,
  `captions.json` the captions as the app shows them; `cover` = `03.jpg` is the couple photo behind the counter card).
  Use `<Img src={staticFile("photos/03.jpg")} />`. 01–07 are portrait, 08–12 landscape.
- `ref/` — the captures (see §8) and `ref/app_icon.svg`.

## 4. Look

Materials (BRIEF §2) — never mix their roles:

- INK — the number and the product's words: `C.ink` #1A1A2E. Secondary `C.ink2`, tertiary `C.ink3`.
- THE TWO — `C.rose` = YOU (Thảo), `C.lavender` = THE OTHER (Tuấn). Everything from the partner arrives lavender
  (his notification, his rows, his sleep lane, his answer label), everything you do is rose. In the REBUILT PRODUCT UI
  keep the app's own colours: the partner's answer label and tints are lavender (`ref/ios/dq-revealed-2.png`), his
  sleep lane is his chosen person colour purple #7C5CD6 (`C.lavenderDeep`), yours rose; the constellation's left half is
  rose, the right half purple.
- PAPER — white cards (radius 28, `C.shadow`), the ground `C.bg` #FAFAFC. The app's own backgrounds (Dawn Blush on
  Home, Sunset Romance on the counter card and the answer-sheet header, the navy night sky of the love tree and the
  sleep calendar) appear only INSIDE rebuilt product UI, never as the film's ground. Exception: Act 5's ground is
  `C.ink` (the app's black), and Act 3 shows the love tree's night sky as a panel.
- Gradients are the app's (`C.sunset`, `C.dawn`, `C.mint`) at 135°; nothing else may be a gradient.
- Hairlines are exactly 1 px (`C.ink3` at 50 % on light, white at 25 % on dark). No outlines on cards, no hard shadows,
  no glow filters (a Dot's glow is one bounded radial gradient).

Type ramp (film px, v3 floor — the film must read full-screen on a phone, where the frame shows at ≈ 0.44×):
display 320 (the number) · 96 (Act 5 headlines) · 64 (story captions: A1, A2, A4) · 56 (the Act 2 question, end-card
lines) · 40 (anything the viewer must read: answers, event titles, card titles) · 28–36 (secondary: labels, benefits,
chips) · 22–26 (fine print, unit labels). Contrast ≥ 4.5:1 for everything under 40 px. Quicksand 700 for display and
numbers, 600 for chips and captions, 500 for UI body. Product UI inside the phone keeps the app's sizes in screen
points (the phone scales them); it may be small only while the same content is also shown large outside the phone.

Grid: `colX(i)` / `colW(n)`. Text left-aligned on column edges; only the end card is centred. Captions sit at
`colX(0)`: y 860 (A1), y 900 (A2), under the ruler (A4). Two rules from the v3 review hold everywhere: at most two
elements move at once, and nothing is ever half-covered by another card (an outgoing card leaves completely).

Camera: one continuous virtual camera. Push-ins are a `transform: scale()` around the frame centre; the one hard cut
is at 1920. Every act boundary is a MATCH: the element that crosses it is drawn by both acts at identical geometry on
the boundary frame (§5). Motion blur (`Blur`) on anything faster than 20 px/frame.

The phone rig: `<Phone>` at `PHONE.hero` (1.1) when it is the hero (Act 4: outer top-left (120, 90)), `PHONE.side`
(0.72) beside text. Screen content is rebuilt from the captures in screen points (402×874): the status bar
(`StatusBar`), the greeting chip "CHÀO BUỔI SÁNG, THẢO" + the two header icons, the counter card (Sunset Romance over
the cover photo `03.jpg` with a dark scrim, "Thảo ♥ Tuấn", "HAI BẠN ĐÃ BÊN NHAU", 1250 / NGÀY, the clock pill
"30.009 : 41 : 07 · GIỜ PHÚT GIÂY", the milestone bar "Cột mốc 1500 ngày · còn 250 ngày", the streak chip), the
"Hôm nay của chúng mình" header with the n/6 pill, the question card, the mood card, the sleep card, the floating
nav (Trang chủ · Trò chuyện · Kỷ niệm · Hồ sơ). Rebuild = vectors + the typed strings; icons are simple 1.5 px line
glyphs (never an icon font image). Match the captures' proportions by eye; they are references, not pixels.

## 5. Hand-offs (the boundary frame is drawn by BOTH acts, identically)

- H240 (A1 → A2): the counter at `COUNTER.hero` (120, 250), scale 1, clock showing `clockAt(240)`; the caption fully
  typed at `A1_CAPTION` (x 120, y 860, 64 px, weight 700); the lavender dot (r 14) landed at `COUNTER_DOT`; camera at
  104 % (A2 eases back to 100 % over its first 60 f while the number steps back).
- H720 (A2 → A3): everything has compressed into ONE navy cell, 28×28, radius 6, at (120, 540) (its top-left); the
  counter at `CORNER` (x 120, y 92, scale 0.32, opacity 0.7 — its eyebrow, "NGÀY" and clock labels fade out by
  themselves below scale 0.4), still ticking; the ground `C.bg`; nothing else.
- H1200 (A3 → A4): the heart tile centred at (960, 460), size 300, filled; the label "CÂY TÌNH YÊU · 12 bông hoa đã nở"
  (28 px, weight 600, line-height 36, box top 642, centred on x 960; "CÂY TÌNH YÊU" `C.ink2` +0.1em, the rest `C.ink`)
  fully typed; the night sky gone; the two dots at (820, 150) rose and (1100, 150) lavender; the counter at `CORNER`.
- A4 → A5: HARD CUT at 1920. Over A4's last 24 f (`A4.cover`, 1896–1920) a navy `C.ink` sheet rises from the bottom
  edge over the resting widgets (rounded top corners 28, motion-blurred while fast); on 1919 its top is at y ≈ 20, so
  A5's first frame of pure `C.ink` carries straight on. The music still cuts dead; nothing else crosses.
- H2280 (A5 → A6): `C.ink` ground; the three headlines at rest at x 120, y 300 / 420 / 540, 96 px white: "Không bảng
  tin. Không người lạ." · "Chỉ hai người." with the two dots resting just after it (28 px apart) · "Miễn phí. Không
  quảng cáo." ("Không quảng cáo." rose); the fine-print line at y 980 (26 px, white 60 %). A6's first 30 f: the light
  `C.bg` sheet rises from the bottom edge (radius 28 on its top corners) and covers the frame by 2310. The navy never
  fades; it is covered.
- H2640 (A6 → A7): only the two dots on `C.bg`, touching: rose centre (946, 540), lavender centre (974, 540), r 14.
  A7 draws the heart around that point, so the dots end inside the heart.

## 6. Per-act notes (what is fixed; everything else is the builder's craft)

- A1: the number is already alive at f0 — no entrance. Camera push 100 → 104 % over 0–240. The caption types with
  `A1.caption` (letters 2–3 f apart, word ends every 12 f on 21…105), a rose caret after the last letter, blinking
  from `A1.wait` to `A1.land`; complete at 105 and holding. The dot falls from y −40 to `COUNTER_DOT.y` between
  `dropStart` and `land` with `settle` (zeta 0.75: the one overshoot), motion-blurred.
- A2 (the daily question is the film's hero beat): the number steps back to `CORNER`; the dot swoops into the avatar
  slot of a large notification card (x 120, y 330, w 780; title 40, body 36, "bây giờ" 28). The real Home phone rises at
  x 1398, y 180, ≈ 840 px tall (counter card on photo 03), then scrolls to the question card. `A2.leave` the
  notification leaves completely; `A2.lift` the question card lifts out of the phone into the left column: question
  56 px on two lines (y 330–462), Tuấn's card (lavender edge, label 28 px; locked = his words redacted under "🔒 Tuấn đã
  trả lời rồi đó 👀" 36 px) at y 494–690, your card (rose edge) at y 710–854, both x 120–1120. `A2.type` your answer
  types at 40 px; the "Gửi" pill (112×56) unfolds and is pressed (`A2.press`); `A2.unlock` (540) both answers open at
  the same instant (his line unmasks, both edges glow once); `A2.caption` "Cần cả hai." 64 px at y 900; the phone's
  card mirrors both answers (`A2.mirror`). The compress (690–720) scales everything into the cell at (120, 540):
  translate + scale, not a fade.
- A3: the strip at y 540 from x 120, cells 28 px with 8 px gaps (31 cells end at x 1236); the count rolls in `Digits`
  (48 px) right of the strip; the flame glyph draws above the last cell; the pill "31 ngày kết nối · hôm nay xong rồi"
  at 32 px (row y 524, pill 482–566). The sky is a complete card inside the frame (x 96–1824, y 600–1000, radius 28,
  the app's shadow) that rises into place at `A3.sky`; inside it the branch (tapered 14 → 6 px, rose-brown) climbs in
  ruled steps (one node per 8th) to its tip at (1300, 700), the 80 px moon sits top-right, the three checks (36 px)
  stack at x 1380, rows y 724 / 794 / 864. At `A3.collapse` the chip shrinks into the point where the dots are born; at
  `A3.night` the card grows to the whole frame; the act title ends before it. Bloom: three 5-petal flowers. The
  constellation: 6 four-point stars (3 rose left, 3 lavender right, labels 28 px) joined by 1 px dashed white lines,
  resolving into `<Heart draw>` at (960, 460) 300. The sky recedes downward (not a fade) as the tile fills. Never more
  than two elements move at once in this act (the cues were re-timed for it).
- A4 (one day, 06:00 → 24:00): the heart tile and label hold while the phone rises at the left (hero scale), then
  shrink away in place; the dots descend into the playhead — a short rose-over-lavender needle (y 232–290) standing on
  the ruler, so it never crosses text; the ruler streams in with its label "HÔM NAY · 15/10/2026". The ruler's hour is
  a monotone smooth curve through (frame, hour) knots (`hourAt`, `hourToFrame`): fast between moments, slow at them.
  Six moments (`A4.events` hours, `A4.eventFrames` 1294 / 1359 / 1429 / 1494 / 1559 / 1624): one large card at a time
  (≈ 640×170, title 40 px, body 30 px, 6 px rose/lavender edge, 36 px icon), dropped with `settle`, each readable
  ≥ 0.9 s; the previous card leaves completely (slides up and scales into its dot on the ruler). The photo moment pops
  `photos/11.jpg` as a print (≈ 440×540, 16 px white border, caption 30 px) that flies into the phone as Ảnh rolls
  11 → 12 (`A4.photo`). Counters (Ảnh · Sao hôm nay · Chuỗi) in `Digits` 58 px, labels 26 px. The playhead stops with a
  4 f overshoot at `A4.stop`; the caption (64 px, two lines) lands where the last card was. Delivery is its own beat:
  the counter card lifts (`A4.lift`) while the phone's screen wipes to a rebuilt iOS home screen; the medium widget
  (1790) and the small one (1810) land inside the phone; the Android 2×2 widget (1830) lands outside it, large
  (300 px at (688, 560): night sky, the constellation tucked top-right clear of the "THẢO ♥ TUẤN" chip, "1250 ngày bên
  nhau"). Then the navy cover (§5).
- A5: `C.ink` ground; no grid, no footer. h1 1955, h2 2040, h3 2130, each typeset in place (96 px white at x 120,
  y 300 / 420 / 540); `A5.dots` (2052–2086) the two dots arc in from the left and right frame edges under "Chỉ hai
  người." without crossing a word and rest just after it, 28 px apart edge to edge; `A5.fine` (2170) the fine-print
  line wipes in. "Không quảng cáo." in `C.rose`.
- A6: cards only (no chat, chips, ticker or caption). The sheet rises 2280–2310 (`A6.composer`). The eight cards land
  one per 8th from 2310 (`A6.glyphs`): 402×290, radius 28, x 120 / 546 / 972 / 1398, rows y 238 / 552, rose #FFF1F4 /
  lavender #F3EFFD alternating; a 72 px rose/lavender circle with the white glyph (60 f animation), the title 40 px 700
  at +124, the benefit 28 px 500 at +184 on two lines (`T.a6.benefits`). They hold to 2560; `A6.dots` the two dots
  enter from the frame edges at y 960; `A6.recede` everything scales toward the dots (not a fade) while they travel to
  H2640.
- A7: the end card is centred: tile centre (960, 300) → wordmark 72 px 700 at y 483 → l1 56 px at y 602 → l2 56 px rose
  at y 672 → offer 34 px `C.ink2` at y 778 → url `<Pill>` (68 px tall, text 26 px) at y 836 → legal 22 px `C.ink2` at
  y 943 (the stack ends at y 970). The wordmark slides out from behind the tile under a mask (clip-path), the lines
  wipe in, the pill rises with `settle`.

## 7. Audio contract

- `audio/events.ts` → `EVENTS` (sorted) built from the cue sheet or from each act's `AN_EVENTS` export. Ids (keep
  stable; add new ones with a comment in your act's `events.ts`): A1 `tick key word drop land` · A2 `swoop unfold
  phoneRise scroll leave lift key sendIn press unlock caption unfoldRow compress` · A3 `cell flame chip node treeCheck
  riser flower collapse rise star heartResolve fill sweep key ting` · A4 `phoneRise shrink playhead rulerIn key event(n,
  who, icon, hour) eventOut(n) photoPop photoFly photoLand count(n) stop caption lift widget(n) cover cut` · A5
  `headline(n) dotsIn fact` · A6 `composerIn glyph(n) dotsIn recede` · A7 `touch heartDraw heartFill wordmark lock line
  url`.
- `audio/core.ts` — `SR 48000`, `SPF 800`, `LEN`, `smp(f)`, `SILENCE` (1920–1950 and 2988–3000 must be digital zero:
  `enforceSilence` last), `place`, `placeStereo`, `writeWav24`, `readWav24`.
- Music (`audio/music/score.ts` → `compose(): Stereo`): the instruments in `audio/music/instruments.ts` (feltPiano,
  marimba, pluck, kick, hat, clap, sideStick, bassNote, padChord, glassPad, chime, glassTone, subPulse, subHold,
  grainCloud) and `dsp.ts` (notes, hz, db, ms, sec, reverb, tapeStop…). Key D (minor shadow in A1 → major from `A1.land`),
  120 BPM, one score; beds per BRIEF §6; the motif = the `word` events of A1 (one note per word), complete and
  harmonised at `A7.lock`; drums drop at `A4.stop` (tape-stop), cut dead at `A4.cut`; a D2 felt piano under A5; the
  pad swell at `A5.h2`; Act 2's suspended swell resolves on `A2.unlock`; Act 4 is a warm bed (marimba 8ths,
  felt-piano chords, soft kick on 1 and 3, side-stick on 2 and 4 — never four-on-the-floor, 16th hats or a broadband
  air layer) under a low-pass that follows the hour; the final chord gone by `A7.end`. Peak ≤ −1 dBFS before mastering.
- SFX (`audio/sfx/build.ts` → `out/audio/sfx.wav`): the kit in `audio/sfx/kit.ts` (key, thock, scrape, paperSlide,
  paperClick, typeset, penStrike, stamp, hairTick, dome, glassDraw, ting, pour, clunk, swivel, sheen, microTick,
  settleAir, ping, paperZip, exhale, uiSlide, airPop, cardFlutter, gather, glyph, roomTone) + `synth.ts`. One sound
  world: close, dry, tactile, quiet. Every sound sits on an `EVENTS` frame (±1 f). Few whooshes. The clock tick is a
  soft wood tick (design it: a short filtered knock, D-ish body). Room tone under everything but the silences.
- `node audio/build.ts` sums both, normalises to −14 LUFS, true-peak limits under −1 dBTP, writes `out/audio/master.wav`
  and the stems. `node audio/build.ts --mix-only` skips rebuilding the stems.

## 8. Capture index (`ref/`)

iPhone 17 simulator, app 1.10.1, mock couple Thảo ♥ Tuấn (`ref/ios/`): `intro-1/2/3` (the three intro slides) ·
`landing` (guest counter + sign-in buttons) · `login` · `home-top` — NOTE: this one is scrolled to the sleep/Oẳn tù tì
cards; for the top of Home use `home-today` (greeting chip, bell, "Hôm nay của chúng mình", question card locked,
mood card) and the website's layout of the counter card described in §4 · `home-mood` · `home-sleep` · `home-rps` ·
`home-memories` · `streak-sheet` (mis-fired: shows Home) · `love-tree-top` (night sky, constellation 2/6, labels) ·
`love-tree-flowers` (12 flowers, "BÔNG TIẾP THEO") · `love-tree-tasks` · `dq-sheet` / `dq-sheet-typed` (the answer
sheet: sunset header, field, "Gửi") · `dq-revealed-1/2` (both answers, labels rose/lavender, "Thu gọn", 3/6) ·
`mood-sheet` / `mood-sheet-picked` (8 moods) · `mood-matched` ("Chúng mình cùng một tâm trạng 💞") · `home-sleep-card`
· `sleep-top` (moon calendar on navy) · `sleep-detail` (two lanes 18h→14h, "Ngủ cùng lúc 6g 15p") · `sleep-month` ·
`rps-screen` · `care-screen` (quick picks, fields) · `notifications` · `gallery-top` / `gallery-scroll` /
`gallery-photo` · `chat` (bubbles, composer) · `profile-*` (mis-fired: gallery).
Pixel 10 emulator, same mock couple (`ref/android/`, 34 screens with the same names as above, plus `profile-top`
(HỒ SƠ TÌNH YÊU, the milestone trail "Cột mốc của chúng mình"), `profile-trail`, `profile-badges` (Huy hiệu: ngày
chuỗi · kỷ lục · kỷ niệm · nhật ký · lời quan tâm · Oẳn tù tì) and `streak-sheet`). The Android app is the same
Flutter UI; only the status bar and the home-screen widget differ by platform. Everything in §1 of the brief and in
`T` is the truth.

## 9. Definition of done for a builder

1. `npm run typecheck` clean; no string literal in Vietnamese outside `strings.ts`; no `Math.random`/`Date`.
2. `node scripts/stills.ts <act> <frames…> --scale=0.5` for your act's review frames (BRIEF §9 list + your key beats),
   then LOOK at `out/stills/<act>/sheet.jpg` and fix: grid alignment, spacing, contrast ≥ 4.5:1 for small text, no
   orphaned words, no element entering by opacity alone, no bounce, captions ≤ 7 words.
3. Your boundary frames match §5 exactly (render them: the first and last frame of your act).
4. Export `AN_EVENTS` with every sound-worthy moment (frame-exact) and keep the cue sheet in sync.
5. Report: what you built, what moved in the cue sheet, anything you need from another owner.
