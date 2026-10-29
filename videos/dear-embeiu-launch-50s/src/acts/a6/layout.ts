// Act 6 geometry (film px). Plain .ts: Act 7 shares TOUCH (the H2640 hand-off).
import { colW, colX } from "../../lib/tokens.ts";

/** H2640: the two dots touching on C.bg — Act 6's last frame and Act 7's first */
export const TOUCH = { r: 14, you: { x: 946, y: 540 }, other: { x: 974, y: 540 } } as const;

export const SPAN = { left: colX(0), right: colX(11) + colW(1) } as const; // the 12-column width: 120 → 1800

/** V3: the 4 × 2 feature cards, 402 × 290 at x 120 / 546 / 972 / 1398, rows y 238 / 552; a 72 px circle holding the
 * white glyph; title 40 px 700 at +124; benefit 28 px 500 at +184 (two lines); 32 px inner padding (338 px of text) */
export const CARDS = { rows: [238, 552], cols: [0, 3, 6, 9].map((i) => colX(i)), w: 402, h: 290, r: 28, pad: 32, circle: 72, icon: 44, titleTop: 124, benefitTop: 184 } as const;

/** where the two dots enter (from the frame edges) before they travel to the touch */
export const DOTS = { y: 960, you: SPAN.left + TOUCH.r, other: SPAN.right - TOUCH.r } as const;
