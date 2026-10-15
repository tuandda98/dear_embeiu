// Act 6 geometry (film px). Plain .ts: Act 7 shares TOUCH (the H2640 hand-off).
import { colW, colX } from "../../lib/tokens.ts";

/** H2640: the two dots touching on C.bg — Act 6's last frame and Act 7's first */
export const TOUCH = { r: 14, you: { x: 946, y: 540 }, other: { x: 974, y: 540 } } as const;

/** the chat panel (ref/ios/chat.png as a white card): printed on the rising sheet */
export const PANEL = { x: 560, y: 280, w: 800, h: 680, r: 28, pad: 24 } as const;
/** the app's header chip "THẢO ♥ TUẤN", centred at the panel's top */
export const HEADER = { y: PANEL.y + 24, h: 40, size: 18 } as const;
/** the composer row at the panel's bottom (lib/screens/chat_screen.dart): tinted field + 48 px send disc */
export const COMPOSER = { x: PANEL.x + PANEL.pad, y: PANEL.y + PANEL.h - PANEL.pad - 48, w: PANEL.w - 2 * PANEL.pad, h: 48, disc: 48, gap: 12, padX: 22, size: 22, line: 28 } as const;
export const FIELD_W = COMPOSER.w - COMPOSER.disc - COMPOSER.gap;
/** the conversation: 24 px bubbles (Tuấn left grey, Thảo right navy), newest at the bottom; new ones rise out from
 * behind the line just above the composer (`mask`) */
export const THREAD = { size: 24, line: 32, padX: 20, h: 56, gap: 12, bottom: COMPOSER.y - 20, maxW: 560, r: 20, left: COMPOSER.x, right: COMPOSER.x + COMPOSER.w, mask: COMPOSER.y - 8 } as const;
export const STEP = THREAD.h + THREAD.gap; // one message: how far the thread moves up when a new one lands
/** the care sheet's six quick picks: one centred row above the panel */
export const CHIPS = { y: 208, h: 48, size: 22, padX: 20, gap: 12 } as const;
export const SPAN = { left: colX(0), right: colX(11) + colW(1) } as const; // the 12-column width: 120 → 1800

/** the 4 × 2 feature cards: 400 × 220 at colX(0), colX(3), colX(6), colX(9); rows y 240 / 480 (bottom 700) */
export const CARDS = { rows: [240, 480], cols: [0, 3, 6, 9].map((i) => colX(i)), w: 400, h: 220, r: 24, padX: 24, padY: 28, circle: 64, icon: 40, titleTop: 114, benefitTop: 155 } as const;

/** the ticker line and its mask; the dots stand at its two ends, on the line's x-height centre */
export const TICKER = { y: 780, size: 28, line: 35, maskL: 160, maskR: 1760, fade: 72 } as const;
export const DOTS = { y: TICKER.y + 21, you: SPAN.left + TOUCH.r, other: SPAN.right - TOUCH.r } as const;
export const CAPTION = { x: colX(0), y: 880 } as const;
