// Act 4's sound events, frame-exact, from the same cues the picture animates from (DESIGN §7, V3.md § A4). Plain .ts
// for Node. Also the day's state the picture reads (when each card lands and leaves, when each counter steps), so
// picture and sound share one table.
// Ids not in DESIGN §7 (v3): shrink (the heart tile and its label shrink away, A4.heartShrink) · playhead (the two dots
// descend and become the playhead, A4.dots) · eventOut (card n leaves: it slides up and scales into its dot on the
// ruler) · photoPop (event 2's print pops out of its card) · photoFly (the print flies into the phone) · photoLand (it
// lands on the phone's Kỷ niệm tab) · count (a counter's new digit lands in its box; n = 0 Ảnh · 1 Sao hôm nay ·
// 2 Chuỗi) · cover (the navy sheet starts rising over the widgets, A4.cover; it bridges the hard cut).
import { A4 } from "../../timeline/cues.ts";
import { T } from "../../copy/strings.ts";

type Ev = { f: number; id: string; data?: Record<string, number | string> };

/** the frame each of T.a4.events crosses the playhead: its card drops, its dot lands on the ruler */
export const EVENT_F = A4.eventFrames;
/** card n leaves (8 f, into its dot) just before the next one drops; the last one ends its exit on the caption. A card
 *  is fully readable from its drop + 4 (opaque, settled) to its exit + 1: ≥ 54 f for every card */
export const OUT_LEN = 8;
export const OUT_F = EVENT_F.map((_, n) => (n + 1 < EVENT_F.length ? EVENT_F[n + 1] - OUT_LEN : A4.caption - OUT_LEN));
/** the counters' steps (frames each +1 starts; a digit rolls over STEP_LEN f): after the card swap, never with it */
export const STEP_LEN = 10;
export const COUNT_STEPS: number[][] = [
  [A4.photo.land], // Ảnh 11 → 12: the print lands in the phone
  // Sao hôm nay 2 → 6: his message (the care note, after the print has landed), your answer, both moods (two steps)
  [A4.photo.land + 12, EVENT_F[3] + 20, EVENT_F[4] + 8, EVENT_F[4] + 18],
  [EVENT_F[3] + 8], // Chuỗi 30 → 31: both answered (event 4)
];

/** the delivery: the counter card lifts (A4.lift[0]), flies from FLY, the home screen wipes in over WIPE */
export const FLY = A4.lift[0] + 15;
export const WIPE = [A4.lift[0], A4.lift[0] + 30] as const;

export const A4_EVENTS: Ev[] = [
  { f: A4.heartShrink[0], id: "shrink" },
  { f: A4.phone[0], id: "phoneRise" },
  { f: A4.dots[0], id: "playhead" },
  { f: A4.ruler[0], id: "rulerIn" },
  ...A4.label.frames.map((f) => ({ f, id: "key" })),
  ...T.a4.events.map((e, n) => ({ f: EVENT_F[n], id: "event", data: { n, who: e.who, icon: e.icon, hour: e.hour } })),
  ...T.a4.events.map((_, n) => ({ f: OUT_F[n], id: "eventOut", data: { n } })),
  { f: A4.photo.pop, id: "photoPop" },
  { f: A4.photo.fly, id: "photoFly" },
  { f: A4.photo.land, id: "photoLand" },
  ...COUNT_STEPS.flatMap((steps, n) => steps.map((f) => ({ f: f + STEP_LEN, id: "count", data: { n } }))),
  { f: A4.stop, id: "stop" }, // the tape overshoots 24:00 and settles (peak on this frame); the counters lock
  { f: A4.caption, id: "caption" },
  { f: A4.lift[0], id: "lift" },
  { f: A4.widgetMedium, id: "widget", data: { n: 0 } }, // the counter card lands as the iOS medium widget
  { f: A4.widgetSmall, id: "widget", data: { n: 1 } },
  { f: A4.widgetAndroid, id: "widget", data: { n: 2 } },
  { f: A4.cover[0], id: "cover", data: { to: A4.cover[1] } },
  { f: A4.cut, id: "cut" },
].sort((a, b) => a.f - b.f);
