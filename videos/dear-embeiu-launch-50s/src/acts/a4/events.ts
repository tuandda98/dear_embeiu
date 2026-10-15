// Act 4's sound events, frame-exact, from the same cues the picture animates from (DESIGN §7). Plain .ts for Node.
// Also the day's state the picture reads (which event has landed by frame f), so picture and sound share one table.
// New id (not in DESIGN §7): count (a counter under the ruler finishes rolling one step: the new digit lands in its
// box, BRIEF §5 "very quiet mechanical micro-ticks"; data n = 0 Ảnh · 1 Sao hôm nay · 2 Chuỗi) · cover (the navy sheet
// starts rising over the widgets, A4.cover; it bridges the hard cut into Act 5's navy silence).
import { A4, hourToFrame } from "../../timeline/cues.ts";
import { T } from "../../copy/strings.ts";

type Ev = { f: number; id: string; data?: Record<string, number | string> };

/** the frame each of T.a4.events crosses the playhead (its card drops, its dot lands on the ruler) */
export const EVENT_F = T.a4.events.map((e) => hourToFrame(e.hour));
const at = (k: number) => EVENT_F[k];

/** the counters' steps: one +1 per listed event (indices into T.a4.events), in T.a4.counters order */
export const COUNT_STEPS: number[][] = [
  [2], // Ảnh 11 → 12: Tuấn's photo (08:12)
  [5, 6, 8, 9], // Sao hôm nay 2 → 6: your answer, his message, his mood, your mood (BRIEF §1: 2/6 before your answer, 3/6 after)
  [5], // Chuỗi 30 → 31: both answered (15:30)
];
export const STEP_LEN = 10; // a digit rolls over 10 f

/** the delivery: the counter card lifts (A4.lift[0]), flies from FLY, the home screen wipes in over WIPE */
export const FLY = A4.lift[0] + 15;
export const WIPE = [A4.lift[0], A4.lift[0] + 30] as const;

export const A4_EVENTS: Ev[] = [
  { f: A4.phone[0], id: "phoneRise" },
  { f: A4.ruler[0], id: "rulerIn" },
  ...A4.label.frames.map((f) => ({ f, id: "key" })),
  ...T.a4.events.map((e, n) => ({ f: at(n), id: "event", data: { n, who: e.who, icon: e.icon, hour: e.hour } })),
  ...COUNT_STEPS.flatMap((steps, n) => steps.map((k) => ({ f: at(k) + STEP_LEN, id: "count", data: { n } }))),
  { f: A4.stop, id: "stop" }, // the tape overshoots 24:00 and settles (peak on this frame); the counters lock
  { f: A4.caption, id: "caption" },
  { f: A4.lift[0], id: "lift" },
  { f: A4.widgetMedium, id: "widget", data: { n: 0 } }, // the counter card lands as the iOS medium widget
  { f: A4.widgetSmall, id: "widget", data: { n: 1 } },
  { f: A4.widgetAndroid, id: "widget", data: { n: 2 } },
  { f: A4.cover[0], id: "cover", data: { to: A4.cover[1] } },
  { f: A4.cut, id: "cut" },
].sort((a, b) => a.f - b.f);
