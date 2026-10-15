// THE CUE SHEET: every key frame of the film, global frames (60 fps, 120 BPM: beat 30, eighth 15, bar 120; the
// counter's second = 60 f). Acts animate FROM these constants and the sound is built FROM them, so picture and sound
// cannot drift. An act builder may edit ONLY its own block (with a precise Edit). Move a visual = move its constant here.
import { even, schedule } from "./typing.ts";
import { T } from "../copy/strings.ts";

// ── A1 · Một con số · 0–240 ───────────────────────────────────────────────────────────────────────────────────────
export const A1 = {
  /** the clock's seconds tick: every 60 f from 0 (beats 1 and 3 of every bar). The tick is the film's metronome. */
  tick: (f: number) => Math.floor(f / 60) * 60,
  /** caption "Mỗi app đếm ngày yêu đều có con số này." — 10 words, one per 8th from 45 to 180 (each unit's last letter
   *  lands on its 8th: a 9-unit "số này." could not fit after 165 and was shifted to 189); typing starts at 39 */
  caption: schedule(["Mỗi", "app", "đếm", "ngày", "yêu", "đều", "có", "con", "số", "này."], [45, 60, 75, 90, 105, 120, 135, 150, 165, 180], { seed: 11 }),
  push: [0, 240], // camera 100 → 104 %
  wait: 210, // the clock waits one beat (no caption motion 180–240)
  dropStart: 222, // the lavender dot falls from the top edge…
  land: 240, // …and lands beside the number on the downbeat (= A2's first frame)
} as const;

// ── A2 · Người ấy · 240–720 ───────────────────────────────────────────────────────────────────────────────────────
export const A2 = {
  land: 240,
  fly: [261, 285], // the number has stepped back (scale 1 → 0.55, 242–278); the dot swoops under it into the card's icon slot
  card: [283, 300], // the dot unfolds into the notification card (its body opens rightward from the dot)
  rows: [300, 360, 420], // leader line draws from the card (8 f), then the row unrolls from its tip and lands on the 8th
  rowLand: [330, 390, 450], // (was 324/384/444: off the 8th grid)
  carets: 450, // rose carets blink in the empty "Bạn" slots
  moodJump: 480, // the caret jumps into the mood row (8.0 s)
  moods: [480, 484, 488, 492, 496, 500, 504, 508], // the 8 moods fan in, 4 f apart
  pick: 540, // "Nhớ" is picked: rose ring draws (9.0 s)
  matched: 555, // the row flashes one rose hairline, reads "Chúng mình cùng một tâm trạng 💞" (was 552: off-grid)
  caption: 570, // "Cần cả hai." (bottom left)
  press: 600, // the navy "Gửi" pill is pressed (10.0 s): 1 → 0.96 in 6 f, back in 10 f
  answerYou: 615, // "Câu trả lời của bạn" unfolds (was 612; 615/645/675 sit on 8ths)
  answerOther: 645, // "Câu trả lời của Tuấn" unfolds
  check: 675, // the check stroke draws under "Hôm nay cả hai đã trả lời"
  compress: [690, 720], // the sheet compresses into the first streak cell (lands at 720 = A3's first frame)
} as const;

// ── A3 · Chuỗi · 720–1200 ─────────────────────────────────────────────────────────────────────────────────────────
export const A3 = {
  cell0: 720, // the compressed answers land as the first cell
  cells: [720, 810], // 31 cells, one every 3 f (720 + 3k), each sliding out from under the last; the count rolls 1 → 31
  flame: [765, 810], // the navy flame glyph draws above the last cell's slot: outer stroke, then inner (45 f)
  sky: [772, 810], // the love tree's night sky rises from the bottom edge to y 600, a sheet (motion-blurred)
  chip: 810, // the flame tucks in beside the strip and the pill draws around it: "31 ngày kết nối · hôm nay xong rồi"
  nodes: [810, 840, 870, 900, 930, 960], // the stem rises one ruled step per beat (8 f each)
  checks: [870, 930, 990], // ✓ 1000 ngày bên nhau · ✓ Chuỗi 30 ngày · ✓ 10 ảnh kỷ niệm (each check draws itself)
  riser: [960, 1020],
  flowers: [1020, 1035, 1050], // three flowers open on the top three nodes, beside their checks (17.0 s)
  night: [1050, 1095], // the sky grows to the whole frame; the chip goes under it (its edge passes the strip ~1062)
  dotsRise: [1050, 1100], // the two dots rise out of the strip to (820, 150) and (1100, 150)
  constellation: [1080, 1140], // six stars light and join by dashed lines, the two halves meeting at the tip
  stars: [1080, 1088, 1095, 1103, 1110, 1118], // one per 16th: you, other × Câu hỏi, Tâm trạng, Nhắn tin
  heart: [1140, 1170], // the stars settle onto the heart outline while one white stroke draws through them
  fill: [1162, 1174], // the heart fills white from the tip up…
  tile: [1171, 1185], // …the sunset tile grows out from behind it…
  sweep: [1180, 1196], // …and one light sweep crosses the tile
  recede: [1155, 1194], // the night sky drops away downward (translate, not a fade), motion-blurred
  label: schedule(["CÂY TÌNH YÊU", "· 12 bông hoa đã nở"], [1167, 1199], { seed: 31, minGap: 1, maxGap: 2 }), // types 1150 → 1199
  set: 1200, // the heart sets (ting + boom) = A4's first frame
} as const;

// ── A4 · Một ngày · 1200–1920 ─────────────────────────────────────────────────────────────────────────────────────
export const A4 = {
  heartShrink: [1200, 1260], // the heart shrinks to the top-left corner
  phone: [1200, 1290], // the phone rises at the left (hero scale), settles by 1290
  ruler: [1260, 1320], // the 24-hour ruler streams in from the right; the playhead stands at the right third
  /** types 1262 → 1320 while the ruler streams in (ends [1300, 1310, 1320] could not hold 13–14 letters per unit and
   *  spilled to 1335); every unit now lands where it says, the last letter on the downbeat the day starts */
  label: schedule(["HÔM NAY ·", "15/10/2026 ·", "00:00 → 24:00"], [1275, 1297, 1320], { seed: 41, minGap: 1, maxGap: 2 }),
  /** the speed ramp: hour 0 at 1320, ease-in over one bar, hold, ease-out into the stop at 1680 (28.0 s) */
  ramp: { from: 1320, easeIn: 1440, easeOut: 1620, to: 1680 },
  /** the day's events, in hours; the frame each one crosses the playhead comes from hourToFrame() below */
  events: [6.0, 7.133, 8.2, 12.5, 15.083, 15.5, 19.667, 21.0, 22.683, 22.75, 23.167],
  stop: 1680, // the playhead stops with a 4 f overshoot; the counters lock
  caption: 1690, // "Con số vẫn có. Chỉ là không còn trơ trọi."
  lift: [1800, 1850], // the counter card lifts off the phone…
  widgetMedium: 1860, // …and lands on the home screen as the medium widget (31.0 s)
  widgetSmall: 1875, // the small widget snaps in
  widgetAndroid: 1890, // the Android 2×2 widget beside it
  cut: 1920, // HARD CUT. Nothing rings across it.
} as const;

/** the day's progress (hours 0–24) at frame f under A4.ramp: smooth-step ease in, constant speed, smooth-step ease out */
export function hourAt(f: number): number {
  const { from, easeIn, easeOut, to } = A4.ramp;
  const a = easeIn - from; // ease-in length
  const c = to - easeOut; // ease-out length
  const b = easeOut - easeIn; // constant length
  // distance covered: ease-in = a/2 (average half speed), constant = b, ease-out = c/2 → total maps to 24 h
  const total = a / 2 + b + c / 2;
  let d: number;
  if (f <= from) d = 0;
  else if (f < easeIn) {
    const t = (f - from) / a;
    d = a * (t * t) / 2; // speed ramps linearly 0 → 1
  } else if (f < easeOut) d = a / 2 + (f - easeIn);
  else if (f < to) {
    const t = (f - easeOut) / c;
    d = a / 2 + b + c * (t - (t * t) / 2); // speed ramps linearly 1 → 0
  } else d = total;
  return (24 * d) / total;
}
/** the frame at which hour h crosses the playhead (inverse of hourAt, bisection on the monotone ramp) */
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
  facts: [1950, 1965, 1980, 1995, 2010, 2025], // six facts typeset in place, one per 8th
  footer: 2040, // "dearembeiu.com"
  dim: 2100, // the grid dims to 25 %
  h1: 2100, // "Không bạn bè. Không mạng xã hội."
  h2: 2130, // "Chỉ hai người."
  h3: 2190, // "Miễn phí. Không quảng cáo." — "Không quảng cáo" in rose
  hold: 2280,
} as const;

// ── A6 · Mở rộng · 2280–2640 ──────────────────────────────────────────────────────────────────────────────────────
export const A6 = {
  composer: [2280, 2310], // the chat composer slides up
  typed: even(T.a6.typed, 2296, 2336), // "Tối nay xem phim nha" — the last letter on 2336, before the send
  send: 2340, // sends on beat 3 of bar 20: the bubble lands navy on the right
  typing: [2370, 2400], // "đang soạn…" answers on the left, three dots
  chips: [2340, 2348, 2356, 2364, 2372, 2380], // the six quick picks fan in (a row above the thread)
  chipsOut: [2388, 2404], // the quick picks lift out of the top edge before the first glyph cell lands under them
  chatOut: [2400, 2430], // the thread and the composer sink out under the frame as the grid lands
  glyphs: [2400, 2415, 2430, 2445, 2460, 2475, 2490, 2505], // the 4×2 grid, one per 8th; each glyph animates 60 f
  dots: [2506, 2526], // the two dots slide in from the frame edges to the ticker's two ends (rose left, lavender right)
  ticker: [2520, 2610], // the masked one-line ticker: flicks in from behind the lavender dot, then drifts
  caption: 2535, // "Miễn phí trên App Store & Google Play"
  recede: [2600, 2640], // everything recedes into the two dots, which travel to the centre
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
