// Act 2's in-between timings (global frames). The beats live in the cue sheet (A2); these are the durations around
// them. Plain .ts so events.ts (and Node) can read the same numbers the picture animates from.
import { A2 } from "../../timeline/cues.ts";

export const STEP = [242, 278] as const; // the number recoils back (scale 1 → 0.55 to (120,160), 100 → 60 %) 2 f after contact
export const CAM = [240, 300] as const; // the camera eases 104 → 100 %
export const OLD_OUT = [250, 262] as const; // A1's caption drops out of its mask
export const GROW = [279, 291] as const; // the dot swells into the card's 56 px app-icon slot as it arrives
export const OPEN = A2.card; // 283–300: the card body opens rightward from the dot, done as the first leader starts
export const LEADER = 8; // a leader line draws in 8 f
export const LET_GO = [A2.moodJump, A2.moodJump + 8] as const; // the lines un-draw from the card's end, the pins shrink away
export const JUMP = 7; // carets hop between cards in 7 f
export const SHEET_UP = 16; // the mood sheet rises in 16 f
export const RING = 12; // the rose ring draws in 12 f
export const SHEET_DOWN = 12; // a sheet drops away in 12 f (exits are quicker than entries)
export const MATCH = 18; // the mood card grows into its matched state
export const ANSWER_UP = 8; // the answer sheet snaps up (it is pressed again 10 f after the pill)
export const BACK_SCROLL = [606, 622] as const; // behind the answer sheet the page scrolls back to the whole question card
export const UNFOLD = 22; // an answer unfolds in 22 f
export const CHECK = 12; // the check stroke draws in 12 f
export const CAP_OUT = [690, 702] as const; // the caption wipes out
export const CELL_AT = A2.compress[1] - 1; // 719: the picture IS the one navy cell (H720), held for A3's first frame
