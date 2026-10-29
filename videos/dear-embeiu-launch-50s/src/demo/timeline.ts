// The 45 s product demo (composition "Demo": 2700 f, 60 fps, 120 BPM → beat 30 f, bar 120 f). Plain TS: the picture
// (src/demo/*.tsx) and the soundtrack (audio/demo/build.ts) read the same frames. No voice-over: the titles and the
// callouts carry the message, the sound is a music bed + light foley placed on these cues.

export const DEMO = { fps: 60, total: 2700, beat: 30, bar: 120 } as const;

/** segment starts */
export const SEG = { hook: 0, counter: 240, question: 600, mood: 1020, sleep: 1380, more: 1740, tree: 2100, end: 2400 } as const;

export type ClipName = "home-scroll" | "question" | "mood" | "sleep" | "gallery" | "chat" | "care" | "love-tree";
/** frame counts of public/clips/<name>.mp4 (1206×2622, 30 fps) */
export const CLIP_FRAMES: Record<ClipName, number> = { "home-scroll": 278, question: 447, mood: 287, sleep: 275, gallery: 164, chat: 116, care: 214, "love-tree": 256 };

/**
 * How a shot comes in: a cut, a vertical push (the new screen pushes the old one up — the demo's one screen change),
 * or a scroll (the recording JUMPS between two scroll positions of the same Home; the demo rebuilds the scroll:
 * `delta` = points the content moves, measured by matching the two frames).
 */
export type Join = { kind: "push"; dur: number } | { kind: "scroll"; dur: number; delta: number }; // both glide (sine in-out)
/** clip time t = t0 + (f − from − join.dur) · rate / 60 seconds; a shot runs until the next one starts */
export type Shot = { from: number; clip: ClipName; t0: number; rate: number; join?: Join };

/**
 * The edit, read off the recordings (motion analysis of every clip; times in clip seconds):
 * home-scroll: counter card at rest 2.05–5.567 (clock ticks 2.867 · 3.867 · 4.867), jump to "Hôm nay…" at 5.6 ·
 * question: Home "Hôm nay…" 0.767–1.867, answer sheet up 1.867–2.133, typing 4.53–8.3, "Gửi" 10.167, sending until
 * 12.6, sheet down 12.6–12.833, both answers + toast from 13.167 · mood: = question's end until 0.333, mood card on
 * top 0.833–1.8, sheet up 1.8–2.0, "Nhớ" picked 4.567, saved + sheet down 7.067–7.267, matched card to 9.57 ·
 * sleep: moon calendar to 4.45, scroll 4.45–5.467 to the two lanes (the moon line stays on top) · love-tree: coach
 * tooltip until 3.43, scroll 4.5–5.133 to "12 bông hoa đã nở" · gallery / chat / care: still screens.
 * Every cut inside a feature joins two identical still frames (an idle caret, a sending state), so it reads as one take.
 */
export const SHOTS: Shot[] = [
  // Hook + Đếm ngày yêu: the counter card. The recording holds 3.3 s of it for 8.75 s of film → 0.38× (the clock
  // still ticks: 2.867 · 3.867 · 4.867 → f101 · 259 · 417).
  { from: 0, clip: "home-scroll", t0: 2.225, rate: 0.38 },
  // → "Hôm nay của chúng mình": a 474 pt scroll into the question clip's identical Home
  { from: 524, clip: "question", t0: 0.8, rate: 0.667, join: { kind: "scroll", dur: 20, delta: 474 } },
  // Câu hỏi mỗi ngày
  { from: 640, clip: "question", t0: 1.867, rate: 1 }, // the answer sheet slides up
  { from: 680, clip: "question", t0: 4.45, rate: 1.8 }, // cut on the idle caret · typing at 1.8×
  { from: 810, clip: "question", t0: 9.9, rate: 1 }, // cut on the typed answer · "Gửi" (10.167 → f826)
  { from: 830, clip: "question", t0: 12.5, rate: 1 }, // cut on the sending state · the sheet goes (f836–850)
  { from: 851, clip: "question", t0: 12.85, rate: 0.71 }, // both answers
  // Tâm trạng hôm nay
  { from: 1020, clip: "mood", t0: 0.9, rate: 0.73, join: { kind: "scroll", dur: 16, delta: 431 } },
  { from: 1110, clip: "mood", t0: 1.8, rate: 1 }, // the mood sheet
  { from: 1150, clip: "mood", t0: 4.3, rate: 1 }, // cut on the open sheet · "Nhớ" (4.567 → f1166)
  { from: 1180, clip: "mood", t0: 6.8, rate: 1 }, // cut on the picked sheet · saved, the sheet goes (f1196–1208)
  { from: 1210, clip: "mood", t0: 7.3, rate: 0.776 }, // "Chúng mình cùng một tâm trạng 💞"
  // Giấc ngủ
  { from: 1380, clip: "sleep", t0: 0.6, rate: 2.139, join: { kind: "push", dur: 12 } }, // the moon calendar (a still)
  { from: 1500, clip: "sleep", t0: 4.45, rate: 1 }, // the recording's own scroll to the two lanes
  { from: 1560, clip: "sleep", t0: 5.45, rate: 0.74 }, // the two lanes, the moon tagline on top (ends 7.67, before its next scroll)
  // Ảnh chung · Trò chuyện riêng · Lời quan tâm: a 6 f push on every bar
  { from: 1740, clip: "gallery", t0: 0.6, rate: 1, join: { kind: "push", dur: 6 } },
  { from: 1860, clip: "chat", t0: 0.6, rate: 1, join: { kind: "push", dur: 6 } },
  { from: 1980, clip: "care", t0: 1.0, rate: 1, join: { kind: "push", dur: 6 } },
  // Cây tình yêu: the constellation after its coach tooltip, the scroll to the flowers at 1×
  { from: 2100, clip: "love-tree", t0: 3.45, rate: 1, join: { kind: "push", dur: 12 } },
  { from: 2213, clip: "love-tree", t0: 5.133, rate: 0.679 },
  // End card: the Home top again, the clock ticking at 1×, still for the last 1.6 s
  { from: 2400, clip: "home-scroll", t0: 2.3, rate: 1, join: { kind: "push", dur: 12 } },
  { from: 2602, clip: "home-scroll", t0: 5.467, rate: 0 },
];

export const shotIndex = (f: number) => {
  let i = 0;
  while (i + 1 < SHOTS.length && SHOTS[i + 1].from <= f) i++;
  return i;
};
/** clip seconds of shot s at frame f (held at t0 while its join runs) */
export const shotTime = (s: Shot, f: number) => s.t0 + (Math.max(0, f - s.from - (s.join?.dur ?? 0)) * s.rate) / 60;
/** the centre of the 30 fps source frame that shows at clip time t (so a frame request never lands on a boundary) */
export const snap = (clip: ClipName, t: number) => Math.min(CLIP_FRAMES[clip] - 0.5, Math.max(0.5, Math.floor(t * 30 + 1e-6) + 0.5)) / 30;

/** the phone's slow move per segment: [from, dx, dy, rotation°] — one eased move over 150 f, never a shake */
export const POSES: Array<[number, number, number, number]> = [
  [SEG.hook, 0, 0, 0],
  [SEG.counter, -8, 4, -0.8],
  [SEG.question, 8, -4, 0.7],
  [SEG.mood, -6, 6, -0.9],
  [SEG.sleep, 8, 2, 0.8],
  [SEG.more, -4, -6, -0.6],
  [SEG.tree, 6, 4, 0.9],
];

/** titles at colX(0), y 120: [key, wipe-in start, wipe-out start] (in 16 f, out 10 f) */
export const TITLE_CUES = [
  ["counter", 246, 588],
  ["question", 606, 1008],
  ["mood", 1026, 1368],
  ["sleep", 1386, 1728],
  ["photos", 1743, 1850],
  ["chat", 1863, 1970],
  ["care", 1983, 2088],
  ["tree", 2106, 2388],
] as const;
/** the hook: the wordmark once the phone has risen, its line two beats later (it is the hook's statement) */
export const HOOK = { wordmark: 34, sub: 118, out: 222 } as const;

/**
 * One callout per segment, alternating sides, each stating the segment's fact in words. `y` = the screen point (pt)
 * the leader line meets: the clock pill · Tuấn's answer · the matched line · the moon tagline · the screen's middle
 * (the montage list) · the blossoms. The hook's statement is its own line; the end card has its lines.
 */
export const CALLOUT_CUES = [
  { id: "counter", side: "right", in: 318, out: 503, y: 398 },
  { id: "question", side: "left", in: 852, out: 1004, y: 382 },
  { id: "mood", side: "right", in: 1222, out: 1362, y: 401 },
  { id: "sleep", side: "left", in: 1560, out: 1716, y: 220 },
  { id: "more", side: "right", in: 1770, out: 2076, y: 437 },
  { id: "tree", side: "left", in: 2220, out: 2382, y: 250 },
] as const;
/** the montage callout's three rows light up with their screens */
export const MORE_ROWS = [1740, 1860, 1980] as const;

/** in-phone taps read off the clips (clip mark → film frame), for the sound: the question card (sheet up at 1.867 →
 *  f640) · "Gửi" (10.167 → f826) · the mood card (sheet up 1.8 → f1110) · "Nhớ" (4.567 → f1166) · "Lưu tâm trạng"
 *  (the sheet goes at 7.067 → f1196) · the "Đêm qua" card (the push into Giấc ngủ at f1380) */
export const TAPS = [638, 826, 1108, 1166, 1194, 1378] as const;

/** the end card: the phone slides to x 300 at 0.8×, the lock-up builds on the right, everything holds from 2610 */
export const END = { move: [2400, 2460], heart: 2414, ting: 2446, wordmark: 2452, line: 2474, offer: 2488, url: 2500, legal: 2508, hold: 2610 } as const;
