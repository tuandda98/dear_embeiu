// Act 2's in-between timings (global frames). The beats live in the cue sheet (A2); these are the durations around
// them. Plain .ts so events.ts (and Node) can read the same numbers the picture animates from.
import { A2 } from "../../timeline/cues.ts";
import { even } from "../../timeline/typing.ts";
import { T } from "../../copy/strings.ts";

export const STEP = [242, 272] as const; // the number recoils back to CORNER, 2 f after contact
export const CAM = [240, 300] as const; // the camera eases 104 → 100 %
export const OLD_OUT = [250, 262] as const; // A1's caption drops out of its mask
export const GROW = [282, 296] as const; // the dot swells into the notification's avatar as it arrives
/** your answer, letter by letter at an even, quick pace across A2.type (32 px into your card) */
export const TYPED = even(T.a2.answerYou.text, A2.type[0], A2.type[1]);
export const UNLOCK_WIPE = 18; // his text is unmasked left → right in 18 f
export const GLOW = 30; // both edges glow once: up and gone in 30 f
export const CAP_IN = 16; // the caption wipes in
export const CAP_OUT = [690, 700] as const; // …and out as the compress starts
export const CELL_AT = A2.compress[1] - 1; // 719: the picture IS the one navy cell (H720), held for A3's first frame
