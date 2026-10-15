// Act 5 sound events, frame-exact with the picture (src/acts/a5/Scene.tsx). Ids: DESIGN §7 (A5 `fact dim headline`).
import { A5 } from "../../timeline/cues.ts";

export const A5_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  ...A5.facts.map((f, n) => ({ f, id: "fact", data: { n } })), // each fact is set (the 102 % thump frame)
  { f: A5.footer, id: "fact", data: { n: 6 } }, // the footer is set the same way
  { f: A5.dim, id: "dim" },
  { f: A5.h1, id: "headline", data: { n: 0 } },
  { f: A5.h2, id: "headline", data: { n: 1 } },
  { f: A5.h3, id: "headline", data: { n: 2 } },
];
