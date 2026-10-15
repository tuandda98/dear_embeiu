// THE CUE SHEET: every key frame of the film, global frames (60 fps, 120 BPM: beat 30, eighth 15, bar 120; the
// counter's second = 60 f). Acts animate FROM these constants and the sound is built FROM them, so picture and sound
// cannot drift. An act builder may edit ONLY its own block (with a precise Edit). Move a visual = move its constant here.
import { even, schedule } from "./typing.ts";
import { T } from "../copy/strings.ts";

// ── A1 · Một con số · 0–240 ───────────────────────────────────────────────────────────────────────────────────────
export const A1 = {
  /** the clock's seconds tick: every 60 f from 0 (beats 1 and 3 of every bar). The tick is the film's metronome. */
  tick: (f: number) => Math.floor(f / 60) * 60,
  /** v3 caption "Mọi app đếm ngày yêu chỉ biết đếm." (64 px): 8 words, one every 12 f from 21, complete on 105, then it
   *  holds 135 f; letters 2–3 f apart */
  caption: schedule(["Mọi", "app", "đếm", "ngày", "yêu", "chỉ", "biết", "đếm."], [21, 33, 45, 57, 69, 81, 93, 105], { seed: 1, minGap: 2, maxGap: 3 }),
  push: [0, 240], // camera 100 → 104 %
  wait: 210, // the clock waits one beat (no caption motion 180–240)
  dropStart: 222, // the lavender dot falls from the top edge…
  land: 240, // …and lands beside the number on the downbeat (= A2's first frame)
} as const;

// ── A2 · Người ấy · 240–720 ───────────────────────────────────────────────────────────────────────────────────────
// v3: the daily question is the hero. One or two motions at a time (V3 G2), in this order.
export const A2 = {
  land: 240,
  fly: [266, 290], // the number has stepped back to CORNER (242–272); the dot swoops into the notification's avatar slot
  card: [288, 305], // the dot opens into the notification (x 120, y 330, w 780); the phone starts rising meanwhile
  phone: [296, 336], // the phone (the real Home, ≈ 840 px tall) rises at the right, counter card on photo 03
  scroll: [340, 385], // inside the phone the Home scrolls down to today's question card
  leave: [392, 406], // the notification slides out to the left, completely
  lift: [406, 446], // the question card lifts out of the phone into the left column at hero scale
  type: [452, 512], // your answer types into your card (32 px)
  sendIn: [512, 520], // the "Gửi" pill unfolds in your card
  press: 524, // "Gửi" is pressed: 1 → 0.96 in 6 f, back in 10 f
  unlock: 540, // UNLOCK — both answers open at the same instant (his text unmasks, both edges glow once)
  caption: 555, // "Cần cả hai." 64 px at (120, 880)
  mirror: 575, // the phone's question card shows both answers too
  compress: [690, 720], // hero + phone compress into the first streak cell (lands at 720 = A3's first frame)
  // v3: dead, kept for audio/scripts (srt.ts needs land < rows[0] < moodJump < matched < press < answerOther < compress[0])
  rows: [392, 398, 404], // the notification leaves
  rowLand: [400, 406, 412],
  carets: 446,
  moodJump: 406, // the lift
  moods: [452, 460, 468, 476, 484, 492, 500, 508], // the typing
  pick: 540,
  matched: 446, // the lift lands
  answerYou: 540,
  answerOther: 540, // = unlock
  check: 555,
} as const;

// ── A3 · Chuỗi · 720–1200 ─────────────────────────────────────────────────────────────────────────────────────────
// v3: re-staged so at most two elements move at once (V3 G2); the chip leaves by scaling into the dots (G3).
export const A3 = {
  cell0: 720, // the compressed answers land as the first cell
  cells: [720, 810], // 31 cells, one every 3 f (720 + 3k), each sliding out from under the last; the count rolls 1 → 31
  flame: [762, 790], // the navy flame draws above the newest cell while the strip grows: outer stroke, then inner
  sky: [790, 828], // the love tree's night sky rises from below into place: a card x 96–1824, y 600–1000 (settle)
  chip: 828, // the strip steps back, the flame tucks in, the pill draws around it: "31 ngày kết nối · hôm nay xong rồi"
  nodes: [855, 870, 885, 900, 915, 930], // the branch grows one ruled step per 8th (8 f each)
  checks: [870, 900, 930], // ✓ 1000 ngày bên nhau · ✓ Chuỗi 30 ngày · ✓ 10 ảnh kỷ niệm (each check draws itself)
  riser: [960, 1020],
  flowers: [945, 960, 975], // three flowers open along the branch, petal by petal (≈ 30 f each, two at most at once)
  collapse: [1005, 1020], // the chip scales into a point between its cells 22 and 30, the two dots are born there
  dotsRise: [1013, 1060], // the two dots rise to (820, 150) and (1100, 150)
  night: [1020, 1060], // the card grows to the whole frame (the constellation's sky)
  constellation: [1060, 1126], // six stars light and join by dashed lines, the two halves meeting at the tip
  stars: [1060, 1066, 1072, 1078, 1084, 1090], // you, other × Câu hỏi, Tâm trạng, Nhắn tin; labels close at 1122+
  heart: [1140, 1160], // the stars (settled on the outline 1126–1140) fold into one white stroke drawn through them
  fill: [1160, 1168], // the heart fills white from the tip up…
  tile: [1172, 1188], // …the sunset tile grows out from behind it, with one light sweep (A3.sweep)
  sweep: [1176, 1194],
  recede: [1170, 1194], // the night sky drops away downward (translate, not a fade), motion-blurred
  label: schedule(["CÂY TÌNH YÊU", "· 12 bông hoa đã nở"], [1151, 1171], { seed: 31, minGap: 1, maxGap: 1 }), // types 1140 → 1171
  set: 1200, // the heart sets (ting + boom) = A4's first frame
} as const;

// ── A4 · Một ngày · 1200–1920 ─────────────────────────────────────────────────────────────────────────────────────
// v3 (V3.md § A4): one day 06:00 → 24:00, seven moments, one card at a time; never more than two things move at once.
export const A4 = {
  /** the heart tile and its label hold still (Act 3 finished typing the label at 1171) while the phone starts up at the
   *  left, then shrink away in place, about the tile's centre */
  heartShrink: [1226, 1246],
  phone: [1215, 1290], // the phone rises at the left (hero scale), settles by 1290
  dots: [1246, 1270], // then the two dots descend to the playhead and stretch into it (rose above lavender, on the ruler)
  ruler: [1270, 1294], // the ruler streams in from the right and lands with 06:00 under the playhead on the first event
  label: schedule(["HÔM NAY ·", "15/10/2026"], [1277, 1294], { seed: 41, minGap: 1, maxGap: 2 }), // types 1264 → 1294
  /** the six events: their hours (= T.a4.events[n].hour) and the frames they cross the playhead (the day's knots); each
   *  card stands fully readable ≥ 0.9 s (54 f) between its drop and its exit (V3 review: the 21:00 reminder dropped) */
  events: [6.0, 10.667, 12.5, 15.5, 22.75, 23.167],
  eventFrames: [1294, 1359, 1429, 1494, 1559, 1624],
  /** event 2's photo: it pops out of the card, holds 0.7 s, then flies into the phone (as its card leaves); Ảnh rolls
   *  11 → 12 as it lands */
  photo: { pop: 1365, hold: 1379, fly: 1421, land: 1443 },
  /** v3: dead (the day runs through the eventFrames knots, see hourAt), kept for audio/scripts */
  ramp: { from: 1270, easeIn: 1526, easeOut: 1624, to: 1680 },
  stop: 1680, // 24:00: the tape stops with a 4 f overshoot; the counters lock; the last card leaves into its dot
  caption: 1690, // "Con số vẫn thế." / "Chỉ là có thêm người ấy." where the last card was
  lift: [1740, 1790], // the counter card lifts off the phone while its screen wipes to the home screen…
  widgetMedium: 1790, // …and lands as the medium widget
  widgetSmall: 1810, // the small widget snaps in
  widgetAndroid: 1830, // the Android 2×2 lands outside the phone, at its right (on screen ≥ 1.0 s)
  cover: [1896, 1920], // a navy (C.ink) sheet rises from the bottom edge over the resting widgets; its top is at y ≈ 20 on 1919
  cut: 1920, // HARD CUT. Nothing rings across it.
} as const;

/** the day's (frame, hour) knots: 05:30 as the ruler starts in (it lands with 06:00, the first event, under the
 *  playhead; the ruler itself starts at 06:00), each event's hour on its frame, 24:00 on the stop */
const DAY: [number, number][] = [[A4.ruler[0], 5.5], ...A4.eventFrames.map((f, n): [number, number] => [f, A4.events[n]]), [A4.stop, 24]];
/** the hour under the playhead at frame f: a smooth-step between consecutive knots, so the day runs fast between the
 *  events and comes to rest on each one (monotone, smooth) */
export function hourAt(f: number): number {
  if (f <= DAY[0][0]) return DAY[0][1];
  for (let i = 1; i < DAY.length; i++) {
    const [f1, h1] = DAY[i];
    if (f < f1) {
      const [f0, h0] = DAY[i - 1];
      const t = (f - f0) / (f1 - f0);
      return h0 + (h1 - h0) * t * t * (3 - 2 * t);
    }
  }
  return DAY[DAY.length - 1][1];
}
/** the frame at which hour h crosses the playhead (inverse of hourAt, bisection; an event's hour gives its frame) */
export function hourToFrame(h: number): number {
  let lo: number = A4.ramp.from;
  let hi: number = A4.ramp.to;
  for (let i = 0; i < 40; i++) {
    const mid = (lo + hi) / 2;
    if (hourAt(mid) < h) lo = mid;
    else hi = mid;
  }
  return Math.round(hi);
}

// ── A5 · Nói trước · 1920–2280 ────────────────────────────────────────────────────────────────────────────────────
export const A5 = {
  silence: [1920, 1950], // pure #1A1A2E, digital zero
  facts: [1950, 1950, 1951, 1951, 1952, 1952], // v3: dead (no fact grid), kept for audio/scripts — before h1 so srt.ts stays ordered
  footer: 2170, // v3: dead (no footer), kept for audio/scripts → the fine-print line
  dim: 2170, // v3: dead (nothing dims), kept for audio/scripts → the fine-print line
  h1: 1955, // "Không bảng tin. Không người lạ."
  h2: 2040, // "Chỉ hai người."
  dots: [2052, 2086], // the two dots glide in from the left and right frame edges and rest just after "người."
  h3: 2130, // "Miễn phí. Không quảng cáo." — "Không quảng cáo" in rose
  fine: 2170, // the fine-print line at y 980 wipes in
  hold: 2280,
} as const;

// ── A6 · Mở rộng · 2280–2640 ──────────────────────────────────────────────────────────────────────────────────────
export const A6 = {
  composer: [2280, 2310], // the light sheet rises from the bottom edge and covers the navy (there is no composer in v3)
  typed: even(T.a6.typed, 2282, 2300), // v3: dead (no chat), kept for audio/scripts
  send: 2305, // v3: dead, kept for audio/scripts
  typing: [2305, 2310], // v3: dead, kept for audio/scripts
  chips: [2310, 2325, 2340, 2355, 2370, 2385], // v3: dead (no chips), kept for audio/scripts → the first six card landings
  chatOut: [2280, 2310], // v3: dead, kept for audio/scripts → the sheet rise
  chipsOut: [2280, 2310], // v3: dead, kept for audio/scripts → the sheet rise
  glyphs: [2310, 2325, 2340, 2355, 2370, 2385, 2400, 2415], // the eight feature cards land, one per 8th; each glyph animates 60 f
  dots: [2560, 2590], // the two dots enter from the left and right frame edges at y 960
  ticker: [2565, 2590], // v3: dead (no ticker, G6), kept for audio/scripts → inside the dots' entry
  caption: 2565, // v3: dead (no caption), kept for audio/scripts
  recede: [2590, 2640], // everything recedes into the two dots while they travel to the centre (H2640)
} as const;

// ── A7 · Ký tên · 2640–3000 ───────────────────────────────────────────────────────────────────────────────────────
export const A7 = {
  touch: 2640, // the two dots touch
  rise: [2644, 2676], // …and rise together into the heart through its open tip
  heart: [2640, 2685], // the heart path draws around them (45 f)…
  fill: [2685, 2700], // …and fills white
  tile: [2690, 2720], // the sunset tile fills behind
  wordmark: [2705, 2760], // "Dear Embeiu" slides out from behind the mark under a mask
  lock: 2760, // lock-up on the downbeat (46.0 s): ting + sub boom
  l1: 2760, // "Đếm ngày yêu."
  l2: 2790, // "Và mọi thứ sau con số."
  legal: 2760, // the legal line, on screen to the end
  offer: 2880, // "Miễn phí · App Store & Google Play"
  url: 2895, // the navy pill "dearembeiu.com"
  hold: 2970, // everything holds; the last frame is the poster
  end: 2988, // audio reaches digital zero by here; picture holds to 2999
} as const;
