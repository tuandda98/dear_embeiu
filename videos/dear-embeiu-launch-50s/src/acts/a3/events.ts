// Act 3's sound events, frame-exact, from the same cues the picture animates from (DESIGN §7). Plain .ts for Node.
// New ids (not in DESIGN §7): skyRise (the night sheet rises, A3.sky), night (it grows to the whole frame, A3.night),
// recede (it slides away downward, A3.recede), fill (the heart fills white, A3.fill), collapse (v3: the chip scales
// into the point where the two dots are born, A3.collapse).
import { A3 } from "../../timeline/cues.ts";
import { T } from "../../copy/strings.ts";

type Ev = { f: number; id: string; data?: Record<string, number | string> };
const N = T.a3.streak;
const STEP = (A3.cells[1] - A3.cells[0]) / (N - 1);
const WHO = ["you", "other"] as const;

export const A3_EVENTS: Ev[] = [
  ...Array.from({ length: N }, (_, n) => ({ f: A3.cells[0] + n * STEP, id: "cell", data: { n } })), // each day cell slides out (n 0 = H720's cell)
  { f: A3.flame[0], id: "flame" }, // the flame's outer stroke starts drawing (inner at +21)
  { f: A3.sky[0], id: "skyRise" },
  { f: A3.chip, id: "chip" }, // the flame tucks in, the pill draws around the strip (28 f)
  ...A3.nodes.map((f, n) => ({ f, id: "node", data: { n } })), // the stem steps up one node
  ...A3.checks.map((f, n) => ({ f, id: "treeCheck", data: { n } })), // the check mark draws (12 f)
  { f: A3.riser[0], id: "riser", data: { to: A3.riser[1] } },
  ...A3.flowers.map((f, n) => ({ f, id: "flower", data: { n } })),
  { f: A3.collapse[0], id: "collapse", data: { to: A3.collapse[1] } },
  { f: A3.night[0], id: "night", data: { to: A3.night[1] } },
  { f: A3.dotsRise[0], id: "rise" }, // the dots are born on the strip, rise from +4
  ...A3.stars.map((f, n) => ({ f, id: "star", data: { n, who: WHO[n % 2] } })),
  { f: A3.heart[0], id: "heartResolve" }, // the white stroke starts at the tip
  { f: A3.recede[0], id: "recede", data: { to: A3.recede[1] } },
  { f: A3.fill[0], id: "fill" },
  { f: A3.sweep[0], id: "sweep" },
  ...A3.label.frames.map((f) => ({ f, id: "key" })),
  { f: A3.set, id: "ting" }, // the heart sets on A4's first frame (20.0 s)
].sort((a, b) => a.f - b.f);
