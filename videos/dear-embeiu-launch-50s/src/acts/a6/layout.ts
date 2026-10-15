// Act 6 geometry (film px). Plain .ts: Act 7 shares TOUCH (the H2640 hand-off).
import { colW, colX } from "../../lib/tokens.ts";

/** H2640: the two dots touching on C.bg — Act 6's last frame and Act 7's first */
export const TOUCH = { r: 14, you: { x: 946, y: 540 }, other: { x: 974, y: 540 } } as const;

/** the product's chat composer (lib/screens/chat_screen.dart): white card, tinted field, 40 px send disc */
export const COMPOSER = { x: colX(2), y: 940, w: colW(8), h: 56, pad: 8, r: 20, disc: 40, size: 22, line: 28 } as const; // x 404 → 1516
export const FIELD = { x: COMPOSER.x + COMPOSER.pad, y: COMPOSER.y + COMPOSER.pad, w: COMPOSER.w - 2 * COMPOSER.pad - 10 - COMPOSER.disc, h: 40, padX: 22 } as const;
export const DISC = { x: COMPOSER.x + COMPOSER.w - COMPOSER.pad - COMPOSER.disc, y: COMPOSER.y + COMPOSER.pad } as const;

/** the conversation (ref/ios/chat.png): 26 px bubbles, Tuấn left grey, Thảo right navy, newest at the bottom */
export const THREAD = { size: 26, line: 34, padX: 22, h: 62, gap: 16, bottom: 860, maxW: colW(5), r: 20, left: COMPOSER.x, right: COMPOSER.x + COMPOSER.w } as const;
export const STEP = THREAD.h + THREAD.gap; // one message: how far the thread moves up when a new one lands
/** the care sheet's six quick picks, a row above the thread */
export const CHIPS = { y: 250, h: 56, size: 24, padX: 24 } as const;
export const SPAN = { left: colX(0), right: colX(11) + colW(1) } as const; // the 12-column width: 120 → 1800

/** the 4 × 2 glyph grid: cells 400 × 220 at colX(0), colX(3), colX(6), colX(9); a 1 px rule under each cell spans its
 * 3-column group; glyphs are drawn at 1.5 × their 64-unit box (96 px), strokes 2 px */
export const CELLS = { rows: [260, 520], cols: [0, 3, 6, 9].map((i) => colX(i)), w: 400, h: 220, rule: colW(3), glyphTop: 20, labelTop: 144, k: 1.5 } as const;

/** the ticker line and its mask; the dots stand at its two ends, on the line's x-height centre */
export const TICKER = { y: 780, size: 28, line: 35, maskL: 160, maskR: 1760, fade: 72 } as const;
export const DOTS = { y: TICKER.y + 21, you: SPAN.left + TOUCH.r, other: SPAN.right - TOUCH.r } as const;
export const CAPTION = { x: colX(0), y: 880 } as const;
