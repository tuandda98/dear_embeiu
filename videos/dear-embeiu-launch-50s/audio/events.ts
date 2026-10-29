// Every sound event of the film, read from the picture: the cue sheet (src/timeline/cues.ts) and the event lists the
// acts export (src/acts/aN/events.ts → `AN_EVENTS`, optional). A moved visual moves its sound on the next build. Where
// an act has not exported its list (or its file fails to load), its events come from the cue sheet (FALLBACK, v3: it
// mirrors the acts' lists from live cue keys only — none of the keys the acts keep "dead, for audio/scripts"). Ids are
// the vocabulary the music and SFX builds share — keep them stable; add new ids with a comment.
import { A1, A2, A3, A4, A5, A6, A7 } from "../src/timeline/cues.ts";
import { even } from "../src/timeline/typing.ts";
import { T } from "../src/copy/strings.ts";

export type Ev = { f: number; id: string; data?: Record<string, number | string> };

async function load(path: string, name: string): Promise<Ev[] | null> {
  try {
    const m = await import(path);
    const v = m[name];
    if (Array.isArray(v)) return v as Ev[];
    console.warn(`events: ${path} has no ${name}, using the cue sheet`);
  } catch {
    // the act has not exported its events yet: the cue sheet stands in
  }
  return null;
}
const a1 = await load("../src/acts/a1/events.ts", "A1_EVENTS");
const a2 = await load("../src/acts/a2/events.ts", "A2_EVENTS");
const a3 = await load("../src/acts/a3/events.ts", "A3_EVENTS");
const a4 = await load("../src/acts/a4/events.ts", "A4_EVENTS");
const a5 = await load("../src/acts/a5/events.ts", "A5_EVENTS");
const a6 = await load("../src/acts/a6/events.ts", "A6_EVENTS");
const a7 = await load("../src/acts/a7/events.ts", "A7_EVENTS");

const wordEnds = (keys: { frames: number[]; text: string }) =>
  // the frame of each unit's last letter = the frames followed by a space, plus the final one
  keys.frames.filter((_, i) => i === keys.frames.length - 1 || keys.text[i + 1] === " ");
/** the clock's seconds (clockAt changes every 60 f) in [from, to) */
const ticks = (from: number, to: number) => Array.from({ length: Math.ceil((to - from) / 60) }, (_, k) => ({ f: from + 60 * k, id: "tick" }));

const FALLBACK = {
  a1: (): Ev[] => [
    ...ticks(0, A1.land),
    ...A1.caption.frames.map((f) => ({ f, id: "key" })), // every typed letter
    ...wordEnds(A1.caption).map((f, n) => ({ f, id: "word", data: { n } })), // the motif, one note per word
    { f: A1.dropStart, id: "drop" },
    { f: A1.land, id: "land" },
  ],
  a2: (): Ev[] => [
    ...ticks(A2.land, A2.compress[1]), // the small counter keeps ticking
    { f: A2.fly[0], id: "swoop" },
    { f: A2.card[0], id: "unfold" },
    { f: A2.phone[0], id: "phoneRise" },
    { f: A2.scroll[0], id: "scroll" },
    { f: A2.leave[0], id: "leave" },
    { f: A2.lift[0], id: "lift" },
    ...even(T.a2.answerYou.text, A2.type[0], A2.type[1]).frames.map((f) => ({ f, id: "key" })), // your answer
    { f: A2.sendIn[0], id: "sendIn" },
    { f: A2.press, id: "press" },
    { f: A2.unlock, id: "unlock" },
    { f: A2.caption, id: "caption" },
    { f: A2.mirror, id: "unfoldRow" },
    { f: A2.compress[0], id: "compress" },
  ],
  a3: (): Ev[] => [
    ...Array.from({ length: T.a3.streak }, (_, n) => ({ f: A3.cells[0] + (n * (A3.cells[1] - A3.cells[0])) / (T.a3.streak - 1), id: "cell", data: { n } })),
    { f: A3.flame[0], id: "flame" },
    { f: A3.sky[0], id: "skyRise", data: { to: A3.sky[1] } },
    { f: A3.chip, id: "chip" },
    ...A3.nodes.map((f, n) => ({ f, id: "node", data: { n } })),
    ...A3.checks.map((f, n) => ({ f, id: "treeCheck", data: { n } })),
    { f: A3.riser[0], id: "riser", data: { to: A3.riser[1] } },
    ...A3.flowers.map((f, n) => ({ f, id: "flower", data: { n } })),
    { f: A3.collapse[0], id: "collapse", data: { to: A3.collapse[1] } },
    { f: A3.night[0], id: "night", data: { to: A3.night[1] } },
    { f: A3.dotsRise[0], id: "rise", data: { to: A3.dotsRise[1] } },
    ...A3.stars.map((f, n) => ({ f, id: "star", data: { n, who: n % 2 ? "other" : "you" } })),
    { f: A3.heart[0], id: "heartResolve", data: { to: A3.heart[1] } },
    { f: A3.recede[0], id: "recede", data: { to: A3.recede[1] } },
    { f: A3.fill[0], id: "fill", data: { to: A3.fill[1] } },
    { f: A3.sweep[0], id: "sweep", data: { to: A3.sweep[1] } },
    ...A3.label.frames.map((f) => ({ f, id: "key" })),
    { f: A3.set, id: "ting" },
  ],
  a4: (): Ev[] => [
    { f: A4.heartShrink[0], id: "shrink", data: { to: A4.heartShrink[1] } },
    { f: A4.phone[0], id: "phoneRise", data: { to: A4.phone[1] } },
    { f: A4.dots[0], id: "playhead", data: { to: A4.dots[1] } },
    { f: A4.ruler[0], id: "rulerIn", data: { to: A4.ruler[1] } },
    ...A4.label.frames.map((f) => ({ f, id: "key" })),
    ...A4.eventFrames.map((f, n) => ({ f, id: "event", data: { n, who: T.a4.events[n]?.who ?? "other", icon: T.a4.events[n]?.icon ?? "", hour: A4.events[n] } })),
    ...A4.eventFrames.map((f, n, all) => ({ f: n + 1 < all.length ? all[n + 1] - 10 : A4.caption - 12, id: "eventOut", data: { n } })),
    { f: A4.photo.pop, id: "photoPop" },
    { f: A4.photo.fly, id: "photoFly", data: { to: A4.photo.land } },
    { f: A4.photo.land, id: "photoLand" },
    { f: A4.photo.land + 10, id: "count", data: { n: 0 } }, // Ảnh 11 → 12 (the other counters' steps live in the act's own table)
    { f: A4.stop, id: "stop" },
    { f: A4.caption, id: "caption" },
    { f: A4.lift[0], id: "lift" },
    { f: A4.widgetMedium, id: "widget", data: { n: 0 } },
    { f: A4.widgetSmall, id: "widget", data: { n: 1 } },
    { f: A4.widgetAndroid, id: "widget", data: { n: 2 } },
    { f: A4.cover[0], id: "cover", data: { to: A4.cover[1] } },
    { f: A4.cut, id: "cut" },
  ],
  a5: (): Ev[] => [
    { f: A5.h1, id: "headline", data: { n: 0 } },
    { f: A5.h2, id: "headline", data: { n: 1 } },
    { f: A5.dots[0], id: "dotsIn", data: { to: A5.dots[1] } },
    { f: A5.h3, id: "headline", data: { n: 2 } },
    { f: A5.fine, id: "fact", data: { n: 0 } },
  ],
  a6: (): Ev[] => [
    { f: A6.composer[0], id: "composerIn", data: { to: A6.composer[1] } },
    ...A6.glyphs.map((f, n) => ({ f, id: "glyph", data: { n } })),
    { f: A6.dots[0], id: "dotsIn", data: { to: A6.dots[1] } },
    { f: A6.recede[0], id: "recede", data: { to: A6.recede[1] } },
  ],
  a7: (): Ev[] => [
    { f: A7.touch, id: "touch" },
    { f: A7.heart[0], id: "heartDraw" },
    { f: A7.fill[0], id: "heartFill" },
    { f: A7.wordmark[0], id: "wordmark" },
    { f: A7.lock, id: "lock" },
    { f: A7.l1, id: "line", data: { n: 0 } },
    { f: A7.l2, id: "line", data: { n: 1 } },
    { f: A7.offer, id: "line", data: { n: 2 } },
    { f: A7.url, id: "url" },
  ],
};

export const EVENTS: Ev[] = [
  ...(a1 ?? FALLBACK.a1()),
  ...(a2 ?? FALLBACK.a2()),
  ...(a3 ?? FALLBACK.a3()),
  ...(a4 ?? FALLBACK.a4()),
  ...(a5 ?? FALLBACK.a5()),
  ...(a6 ?? FALLBACK.a6()),
  ...(a7 ?? FALLBACK.a7()),
]
  .filter((e) => Number.isFinite(e.f))
  .sort((a, b) => a.f - b.f);

/** events with this id inside [from, to) */
export const evs = (id: string, from = 0, to = 3000) => EVENTS.filter((e) => e.id === id && e.f >= from && e.f < to);
export const num = (e: Ev, k: string, d = 0) => (typeof e.data?.[k] === "number" ? (e.data[k] as number) : d);
export const str = (e: Ev, k: string, d = "") => (typeof e.data?.[k] === "string" ? (e.data[k] as string) : d);
export { A1, A2, A3, A4, A5, A6, A7 };
