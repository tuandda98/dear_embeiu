// Every sound event of the film, read from the picture: the cue sheet (src/timeline/cues.ts) and the event lists the
// acts export (src/acts/aN/events.ts → `AN_EVENTS`, optional). A moved visual moves its sound on the next build. Where
// an act has not exported its list, its events come from the cue sheet (FALLBACK). Ids are the vocabulary the music
// and SFX builds share — keep them stable; add new ids with a comment.
import { A1, A2, A3, A4, A5, A6, A7, hourToFrame } from "../src/timeline/cues.ts";
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

const FALLBACK = {
  a1: (): Ev[] => [
    ...[0, 60, 120, 180].map((f) => ({ f, id: "tick" })), // the clock's seconds
    ...A1.caption.frames.map((f) => ({ f, id: "key" })), // every typed letter
    ...wordEnds(A1.caption).map((f, n) => ({ f, id: "word", data: { n } })), // the motif, one note per word
    { f: A1.dropStart, id: "drop" },
    { f: A1.land, id: "land" },
  ],
  a2: (): Ev[] => [
    { f: A2.card[0], id: "unfold" },
    ...A2.rows.map((f, n) => ({ f, id: "leader", data: { n } })),
    ...A2.rowLand.map((f, n) => ({ f, id: "row", data: { n } })),
    { f: A2.moodJump, id: "jump" },
    ...A2.moods.map((f, n) => ({ f, id: "mood", data: { n } })),
    { f: A2.pick, id: "pick" },
    { f: A2.matched, id: "matched" },
    { f: A2.caption, id: "caption" },
    { f: A2.press, id: "press" },
    { f: A2.answerYou, id: "unfoldRow", data: { n: 0 } },
    { f: A2.answerOther, id: "unfoldRow", data: { n: 1 } },
    { f: A2.check, id: "check" },
    { f: A2.compress[0], id: "compress" },
  ],
  a3: (): Ev[] => [
    ...Array.from({ length: T.a3.streak }, (_, k) => ({ f: A3.cells[0] + k * 3, id: "cell", data: { n: k } })),
    { f: A3.flame[0], id: "flame" },
    { f: A3.chip, id: "chip" },
    ...A3.nodes.map((f, n) => ({ f, id: "node", data: { n } })),
    ...A3.checks.map((f, n) => ({ f, id: "treeCheck", data: { n } })),
    { f: A3.riser[0], id: "riser" },
    ...A3.flowers.map((f, n) => ({ f, id: "flower", data: { n } })),
    { f: A3.dotsRise[0], id: "rise" },
    ...Array.from({ length: 6 }, (_, k) => ({ f: A3.constellation[0] + k * 10, id: "star", data: { n: k } })),
    { f: A3.heart[0], id: "heartResolve" },
    { f: A3.tile[0], id: "sweep" },
    ...A3.label.frames.map((f) => ({ f, id: "key" })),
    { f: A3.set, id: "ting" },
  ],
  a4: (): Ev[] => [
    { f: A4.phone[0], id: "phoneRise" },
    { f: A4.ruler[0], id: "rulerIn" },
    ...A4.label.frames.map((f) => ({ f, id: "key" })),
    ...T.a4.events.map((e, n) => ({ f: hourToFrame(e.hour), id: "event", data: { n, who: e.who, icon: e.icon, hour: e.hour } })),
    { f: A4.stop, id: "stop" },
    { f: A4.caption, id: "caption" },
    { f: A4.lift[0], id: "lift" },
    { f: A4.widgetMedium, id: "widget", data: { n: 0 } },
    { f: A4.widgetSmall, id: "widget", data: { n: 1 } },
    { f: A4.widgetAndroid, id: "widget", data: { n: 2 } },
    { f: A4.cut, id: "cut" },
  ],
  a5: (): Ev[] => [
    ...A5.facts.map((f, n) => ({ f, id: "fact", data: { n } })),
    { f: A5.footer, id: "fact", data: { n: 6 } },
    { f: A5.dim, id: "dim" },
    { f: A5.h1, id: "headline", data: { n: 0 } },
    { f: A5.h2, id: "headline", data: { n: 1 } },
    { f: A5.h3, id: "headline", data: { n: 2 } },
  ],
  a6: (): Ev[] => [
    { f: A6.composer[0], id: "composerIn" },
    ...A6.typed.frames.map((f) => ({ f, id: "key" })),
    { f: A6.send, id: "send" },
    ...[0, 1, 2].map((k) => ({ f: A6.typing[0] + k * 8, id: "typingDot", data: { n: k } })),
    ...A6.chips.map((f, n) => ({ f, id: "chip", data: { n } })),
    ...A6.glyphs.map((f, n) => ({ f, id: "glyph", data: { n } })),
    { f: A6.ticker[0], id: "ticker" },
    { f: A6.caption, id: "caption" },
    { f: A6.recede[0], id: "recede" },
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
export { A1, A2, A3, A4, A5, A6, A7, hourToFrame };
