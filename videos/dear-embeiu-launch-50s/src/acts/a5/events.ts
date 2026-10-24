// Act 5 sound events (v3), frame-exact with the picture (src/acts/a5/Scene.tsx). Ids: DESIGN §7 (A5 `headline`, `fact`)
// + `dotsIn` (as in A6). `dim` is gone (nothing dims in v3).
import { A5 } from "../../timeline/cues.ts";

export const A5_EVENTS: { f: number; id: string; data?: Record<string, number | string> }[] = [
  { f: A5.h1, id: "headline", data: { n: 0 } }, // "Không bảng tin. Không người lạ."
  { f: A5.h2, id: "headline", data: { n: 1 } }, // "Chỉ hai người."
  { f: A5.dots[0], id: "dotsIn" }, // the two dots glide in from the frame edges, rest after "người." at A5.dots[1]
  { f: A5.h3, id: "headline", data: { n: 2 } }, // "Miễn phí. Không quảng cáo."
  { f: A5.fine, id: "fact", data: { n: 0 } }, // the fine-print line wipes in
];
