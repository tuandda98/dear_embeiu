// Act 6 sound events (v3), frame-exact with the picture (Act6.tsx, a6/Range.tsx). Ids: DESIGN §7 (A6); the chat ids
// (key send typingDot chip chipsOut ticker caption) are gone with the chat.
import { A6 } from "../../timeline/cues.ts";

export const A6_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  { f: A6.composer[0], id: "composerIn" }, // the light sheet starts to rise (it covers the navy by A6.composer[1])
  ...A6.glyphs.map((f, n) => ({ f, id: "glyph", data: { n } })), // each feature card lands; its glyph plays 6 f later
  { f: A6.dots[0], id: "dotsIn" }, // the two dots slide in from the left and right frame edges at y 960
  { f: A6.recede[0], id: "recede" }, // the cards recede into the centre; the dots travel to the touch
];
