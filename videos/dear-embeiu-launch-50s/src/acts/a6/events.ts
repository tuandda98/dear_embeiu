// Act 6 sound events, frame-exact with the picture (Chat.tsx, Range.tsx). Ids: DESIGN §7 (A6 `composerIn key send
// typingDot chip glyph ticker caption recede`).
import { A6 } from "../../timeline/cues.ts";

export const A6_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  { f: A6.composer[0], id: "composerIn" }, // the sheet starts to rise with the composer
  ...A6.typed.frames.map((f) => ({ f, id: "key" })), // every typed letter
  { f: A6.send, id: "send" }, // the send disc is pressed; the bubble lifts off
  ...[0, 1, 2].map((n) => ({ f: A6.typing[0] + 8 * n, id: "typingDot", data: { n } })), // the three dots start to rise
  ...A6.chips.map((f, n) => ({ f, id: "chip", data: { n } })), // each quick pick is dealt
  { f: A6.chipsOut[0], id: "chipsOut" }, // the chip row and the chat panel slide up and out
  ...A6.glyphs.map((f, n) => ({ f, id: "glyph", data: { n } })), // each feature card lands
  { f: A6.dots[0], id: "dotsIn" }, // NEW id: the two dots slide in from the frame edges to the ticker's ends
  { f: A6.ticker[0], id: "ticker" }, // the flick (the dots have just landed at its ends)
  { f: A6.caption, id: "caption" },
  { f: A6.recede[0], id: "recede" }, // everything scales into the centre; the dots travel to the touch
];
