// Act 1 sound events, frame-exact to the picture (DESIGN §7 ids: tick key word drop land). Plain .ts: Node imports it.
import { A1 } from "../../timeline/cues.ts";

const keys = A1.caption;
/** one note per word: the frame of each word's last letter (every unit is one word, each on an 8th) */
const wordEnds = keys.frames.filter((_, i) => i === keys.frames.length - 1 || keys.text[i + 1] === " ");

export const A1_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  ...[0, 60, 120, 180].map((f) => ({ f, id: "tick" })), // the clock's seconds (clockAt changes every 60 f)
  ...keys.frames.map((f) => ({ f, id: "key" })), // every typed letter (spaces included: the thumb still presses)
  ...wordEnds.map((f, n) => ({ f, id: "word", data: { n } })), // the motif, typed: 45 60 … 180
  { f: A1.dropStart, id: "drop" }, // the lavender dot leaves the top edge
  { f: A1.land, id: "land" }, // first contact beside the number (the spring's first crossing is solved onto this frame)
].sort((a, b) => a.f - b.f);
